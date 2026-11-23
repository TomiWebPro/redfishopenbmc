// EP-S17 (issue #009/#021): malformed-body / transport-exception skip-vs-propagate
// agreement across both KVM service surfaces.
//
// `fetchConsoles()` (console cards) and `fetchCapabilities()` (capability cards)
// both walk `/redfish/v1/Managers` through the SAME
// `KvmService._fetchManagerBodies()` helper, so they apply the SAME skip /
// propagate decision for a manager whose body fetch fails. RS-2 pins the
// per-manager decision over HTTP STATUS codes (404 / 429 / 5xx / 401 / 501)
// and EP-S13 pins multi-manager skip agreement over that status matrix — but
// NOTHING drives the NON-STATUS failure matrix (malformed JSON, wrong/blank
// Content-Type, empty body, a dropped transport connection) through BOTH
// surfaces at once. A future one-sided catch/filter could throw a raw
// parse/socket error out of one surface while the other skips — or swallow a
// fatal parse failure on one card surface while the other propagates it —
// while every status-only suite stays GREEN.
//
// AUDIT: the decision agreement already holds BY CONSTRUCTION (one shared walk
// with one catch/filter). This is a characterization / regression lock, not a
// live divergence fix — no production behaviour is changed. Note the two
// surfaces are NOT expected to return an identical *manager-id set*: a manager
// with no console block (healthy or degraded) yields no console card but does
// yield a capability card. What MUST agree is the skip-vs-propagate decision,
// the absence of raw parse/socket errors, and the exact-once surfacing of any
// healthy manager that does expose consoles.
//
// The fault injection is test-only (a private localhost HTTP server in this
// file): no WebView/protocol import, no URL opened, no production TLS weakened,
// no dependency change.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Test-only fault mode for one `/Managers/{id}` response.
enum _Fault { none, malformedJson, blankContentType, emptyBody }

/// Minimal in-process HTTP server that serves a manager collection plus a
/// per-manager fault matrix. Test-only; no production code imports it.
class _FaultServer {
  _FaultServer({
    required this.bodies,
    required this.faults,
    this.deadTransportIds = const <String>{},
  });

  /// manager id -> valid JSON manager body
  final Map<String, String> bodies;

  /// manager id -> injected fault
  final Map<String, _Fault> faults;

  /// manager ids whose member URI points at a dead loopback port (transport error)
  final Set<String> deadTransportIds;

  HttpServer? _server;

  Future<_FaultServer> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handle);
    return this;
  }

  void _handle(HttpRequest request) {
    const String prefix = '/redfish/v1/Managers/';
    final String path = request.uri.path;
    if (path == '/redfish/v1/Managers') {
      final List<dynamic> members = <dynamic>[
        for (final String id in bodies.keys)
          <String, dynamic>{
            '@odata.id': deadTransportIds.contains(id)
                // Absolute URI on a closed loopback port: Dio surfaces a
                // transport-level connection error (retryable -> skipped).
                ? 'http://127.0.0.1:1/redfish/v1/Managers/$id'
                : '/redfish/v1/Managers/$id',
          },
      ];
      _send(request, 200, jsonEncode(<String, dynamic>{'Members': members}),
          ContentType.json);
      return;
    }
    if (path.startsWith(prefix)) {
      final String id = path.substring(prefix.length);
      switch (faults[id] ?? _Fault.none) {
        case _Fault.malformedJson:
          _send(request, 200, '{"Id": "$id", ', ContentType.json);
          return;
        case _Fault.blankContentType:
          // Valid JSON text with a non-JSON Content-Type: Dio does not decode,
          // so RedfishClient._asMap wraps the raw string as {'value': ...}.
          _send(request, 200, bodies[id] ?? '{}', ContentType.text);
          return;
        case _Fault.emptyBody:
          _send(request, 200, '', ContentType.json);
          return;
        case _Fault.none:
          _send(request, 200, bodies[id] ?? '{}', ContentType.json);
          return;
      }
    }
    _send(request, 404, '{}', ContentType.json);
  }

  void _send(HttpRequest request, int status, String body, ContentType type) {
    request.response
      ..statusCode = status
      ..headers.contentType = type;
    request.response.write(body);
    request.response.close();
  }

  RedfishClient buildClient() => RedfishClient(
        profile: ConnectionProfile(
          id: 'bmc1',
          host: '127.0.0.1',
          port: _server!.port,
          scheme: 'http',
          allowSelfSigned: true,
        ),
      );

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
  }
}

String _validBody(String id, {String uri = 'https://bmc.example/primary'}) =>
    jsonEncode(<String, dynamic>{
      'Id': id,
      '@odata.id': '/redfish/v1/Managers/$id',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
        'ConnectUri': uri,
        'MaxConcurrentSessions': 4,
      },
    });

void main() {
  late _FaultServer server;
  late KvmService svc;

  Future<void> startWith(
    Map<String, String> bodies,
    Map<String, _Fault> faults, {
    Set<String> deadTransportIds = const <String>{},
  }) async {
    server = _FaultServer(
      bodies: bodies,
      faults: faults,
      deadTransportIds: deadTransportIds,
    );
    await server.start();
    svc = KvmService(client: server.buildClient(), systemId: 'bmc1');
  }

  tearDown(() async {
    await server.close();
  });

  test(
      'malformed JSON body: BOTH surfaces propagate the same normalized '
      'RedfishException (no raw parse error, no one-sided swallow, EP-S17)',
      () async {
    await startWith(<String, String>{
      'MgrBad': _validBody('MgrBad'),
      'MgrGood': _validBody('MgrGood'),
    }, <String, _Fault>{
      'MgrBad': _Fault.malformedJson
    });

    Object? consoleError;
    Object? capabilityError;
    try {
      await svc.fetchConsoles();
    } catch (e) {
      consoleError = e;
    }
    try {
      await svc.fetchCapabilities();
    } catch (e) {
      capabilityError = e;
    }

    // Both surfaces must apply the SAME propagate decision — neither may skip
    // a fatal parse failure nor swallow it into an empty card surface.
    expect(consoleError, isNotNull,
        reason: 'fetchConsoles() must not silently skip a malformed body');
    expect(capabilityError, isNotNull,
        reason: 'fetchCapabilities() must not swallow a malformed body');
    expect(consoleError, isA<RedfishException>(),
        reason: 'no raw FormatException may escape fetchConsoles()');
    expect(capabilityError, isA<RedfishException>(),
        reason: 'no raw FormatException may escape fetchCapabilities()');
    expect(capabilityError.runtimeType, consoleError.runtimeType,
        reason: 'both surfaces must normalize to the SAME exception type');
    final RedfishException consoleR = consoleError! as RedfishException;
    final RedfishException capabilityR = capabilityError! as RedfishException;
    expect(capabilityR.statusCode, consoleR.statusCode);
    expect(capabilityR.errorCode, consoleR.errorCode);
  });

  test(
      'dropped transport connection: BOTH surfaces skip the faulted manager '
      'and surface the SAME survivor exactly once (EP-S17)', () async {
    await startWith(<String, String>{
      'MgrDrop': _validBody('MgrDrop'),
      'MgrGood': _validBody('MgrGood'),
    }, const <String, _Fault>{}, deadTransportIds: <String>{
      'MgrDrop'
    });

    final List<KvmConsole> consoles = await svc.fetchConsoles();
    final List<KvmCapability> capabilities = await svc.fetchCapabilities();

    expect(consoles.map((KvmConsole c) => c.managerId).toSet(),
        <String>{'MgrGood'});
    expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
        <String>{'MgrGood'});
    expect(consoles.where((KvmConsole c) => c.managerId == 'MgrGood'),
        hasLength(1));
    expect(capabilities.where((KvmCapability c) => c.managerId == 'MgrGood'),
        hasLength(1));
    expect(await svc.fetchCapability('MgrDrop'), isNull,
        reason: 'connection-dropped manager never resolves to a phantom card');
    expect(await svc.fetchCapability('MgrGood'), isNotNull);
    final KvmConsole? primary = await svc.fetchPrimaryConsole();
    expect(primary, isNotNull);
    expect(primary!.managerId, 'MgrGood');
    expect(KvmService.pickPrimary(consoles)?.managerId, primary.managerId);
  });

  test(
      'dropped transport: repeated walks are deterministic on both surfaces '
      '(gated screen never blanked on one side, EP-S17)', () async {
    await startWith(<String, String>{
      'MgrDrop': _validBody('MgrDrop'),
      'MgrGood': _validBody('MgrGood'),
    }, const <String, _Fault>{}, deadTransportIds: <String>{
      'MgrDrop'
    });

    for (int i = 0; i < 2; i++) {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(consoles, isNotEmpty);
      expect(capabilities, isNotEmpty);
      expect(consoles.map((KvmConsole c) => c.managerId).toSet(),
          <String>{'MgrGood'});
      expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
          <String>{'MgrGood'});
    }
  });

  Future<void> expectDegradedBodyAgreement(
      _Fault fault, String managerId) async {
    await startWith(<String, String>{
      managerId: _validBody(managerId),
      'MgrGood': _validBody('MgrGood'),
    }, <String, _Fault>{
      managerId: fault
    });

    // A wrong Content-Type / empty body degrades the body to a raw-string map
    // ({'value': ...}) on BOTH surfaces: neither may throw a raw parse error.
    final List<KvmConsole> consoles = await svc.fetchConsoles();
    final List<KvmCapability> capabilities = await svc.fetchCapabilities();

    // The healthy manager is surfaced exactly once on both card surfaces.
    expect(consoles.where((KvmConsole c) => c.managerId == 'MgrGood'),
        hasLength(1));
    expect(capabilities.where((KvmCapability c) => c.managerId == 'MgrGood'),
        hasLength(1));

    // The degraded body exposes no console block, so it produces no console
    // card; both surfaces keep the healthy screen populated (never blanked).
    expect(consoles.map((KvmConsole c) => c.managerId).toSet(),
        <String>{'MgrGood'});
    expect(capabilities.map((KvmCapability c) => c.managerId),
        contains('MgrGood'));

    // No raw body string may leak into any launch URI on either surface.
    for (final KvmConsole c in consoles) {
      expect(c.launchPlan.targetUri, isNot(contains('value')));
      expect(c.launchPlan.targetUri, 'https://bmc.example/primary');
    }
    for (final KvmCapability cap in capabilities) {
      if (cap.managerId == managerId) {
        expect(cap.hasUri, isFalse,
            reason: 'degraded body must not yield a launchable capability');
      }
    }

    // Primary resolution agrees with the same-console pick on both paths.
    final KvmConsole? primary = await svc.fetchPrimaryConsole();
    expect(primary, isNotNull);
    expect(primary!.managerId, 'MgrGood');
    expect(KvmService.pickPrimary(consoles)?.managerId, primary.managerId);
  }

  test(
      'wrong/blank Content-Type: both surfaces keep the gated screen alive '
      'and never leak the raw body (EP-S17)', () async {
    await expectDegradedBodyAgreement(_Fault.blankContentType, 'MgrBlank');
  });

  test(
      'empty body: both surfaces keep the gated screen alive and never leak '
      'the raw body (EP-S17)', () async {
    await expectDegradedBodyAgreement(_Fault.emptyBody, 'MgrEmpty');
  });

  test(
      'mixed non-status matrix: malformed JSON propagation is identical '
      'regardless of sibling manager faults (EP-S17)', () async {
    // Two healthy managers plus one of each non-fatal fault; the malformed
    // JSON manager still makes BOTH surfaces propagate identically.
    final Map<String, String> bodies = <String, String>{
      'MgrGoodA': _validBody('MgrGoodA', uri: 'https://bmc.example/a'),
      'MgrGoodB': _validBody('MgrGoodB', uri: 'https://bmc.example/b'),
      'MgrBlank': _validBody('MgrBlank'),
      'MgrEmpty': _validBody('MgrEmpty'),
      'MgrBad': _validBody('MgrBad'),
      // Transport-faulted: member URI points at a dead port, no server body hit.
      'MgrDrop': _validBody('MgrDrop'),
    };
    await startWith(bodies, <String, _Fault>{
      'MgrBlank': _Fault.blankContentType,
      'MgrEmpty': _Fault.emptyBody,
      'MgrBad': _Fault.malformedJson,
    }, deadTransportIds: <String>{
      'MgrDrop'
    });

    Object? consoleError;
    Object? capabilityError;
    try {
      await svc.fetchConsoles();
    } catch (e) {
      consoleError = e;
    }
    try {
      await svc.fetchCapabilities();
    } catch (e) {
      capabilityError = e;
    }
    expect(consoleError, isA<RedfishException>());
    expect(capabilityError, isA<RedfishException>());
    expect(capabilityError.runtimeType, consoleError.runtimeType);
  });
}
