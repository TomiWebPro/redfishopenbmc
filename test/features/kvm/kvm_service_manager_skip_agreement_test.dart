// EP-S13 (issue #009/#021): cross-surface manager-SKIP agreement.
//
// `fetchConsoles()` (console cards) and `fetchCapabilities()` (capability
// summaries) both walk `/redfish/v1/Managers` through the SAME
// `KvmService._fetchManagerBodies()` helper, so they skip the SAME manager(s)
// when a sibling `/Managers/{id}` fetch fails transiently (404 / 429 /
// 5xx-except-501 — RS-2). RS-2 pins each surface's skip semantics with ONE
// failing manager at a time; RS-6 pins manager-set identity for WELL-FORMED
// bodies. Nothing pins that BOTH surfaces skip exactly the SAME manager(s) in
// ONE walk over a matrix with SEVERAL failing managers interleaved with healthy
// ones — a future one-sided skip filter could drop a physical manager from one
// card surface and not the other while every single-surface suite stays GREEN.
//
// Audit: the agreement already holds BY CONSTRUCTION (one shared walk with one
// skip filter). This is a characterization / regression lock, not a live
// divergence fix — no production behaviour is changed. The fault injection is
// test-only (MockRedfishServer.statusByPath): no WebView/protocol import, no
// URL opened, no production TLS weakened, no dependency change.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  late Directory fixtureDir;

  // Four managers, deliberately interleaved so the secure primary is NOT the
  // first member and the two failing managers sit between healthy ones. Two
  // survive (MgrPrimary, MgrSerial); two must be skipped (MgrGone 404,
  // MgrFlappy fault-injected retryable). Both surfaces must agree on that
  // exact split.
  const Set<String> survivors = <String>{'MgrPrimary', 'MgrSerial'};
  const Map<String, int> baseFaults = <String, int>{
    '/redfish/v1/Managers/MgrGone': 404,
    '/redfish/v1/Managers/MgrFlappy': 503,
  };

  setUpAll(() async {
    fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s13_fixture_');
    final Directory managersDir = Directory('${fixtureDir.path}/Managers')
      ..createSync(recursive: true);
    File('${managersDir.path}/index.json').writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'Members': <dynamic>[
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrSerial'},
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGone'},
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrPrimary'},
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrFlappy'},
        ],
      }),
    );

    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{
      'MgrPrimary': <String, dynamic>{
        'Id': 'MgrPrimary',
        '@odata.id': '/redfish/v1/Managers/MgrPrimary',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'ConnectUri': 'https://bmc.example/primary',
          'MaxConcurrentSessions': 4,
        },
      },
      'MgrSerial': <String, dynamic>{
        'Id': 'MgrSerial',
        '@odata.id': '/redfish/v1/Managers/MgrSerial',
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['SSH'],
          'ConnectUri': 'ssh://bmc.example/serial',
        },
      },
      // Both failing managers have a perfectly valid body: their exclusion
      // must come ONLY from the injected fetch failure, never from parsing.
      'MgrGone': <String, dynamic>{
        'Id': 'MgrGone',
        '@odata.id': '/redfish/v1/Managers/MgrGone',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/gone',
        },
      },
      'MgrFlappy': <String, dynamic>{
        'Id': 'MgrFlappy',
        '@odata.id': '/redfish/v1/Managers/MgrFlappy',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': 'https://bmc.example/flappy',
        },
      },
    };
    for (final MapEntry<String, Map<String, dynamic>> entry in bodies.entries) {
      final Directory managerDir = Directory('${managersDir.path}/${entry.key}')
        ..createSync(recursive: true);
      File('${managerDir.path}/index.json')
          .writeAsStringSync(jsonEncode(entry.value));
    }
  });

  tearDownAll(() async {
    fixtureDir.deleteSync(recursive: true);
  });

  /// Starts a fresh server over the fixture with [statusByPath] fault injection
  /// and hands a bound service to [body], always closing the server.
  Future<void> withFaults(
    Map<String, int> statusByPath,
    Future<void> Function(KvmService svc) body,
  ) async {
    final MockRedfishServer server = await MockRedfishServer(
      fixturesDir: fixtureDir.path,
      statusByPath: statusByPath,
    ).start();
    try {
      await body(KvmService(client: server.buildClient(), systemId: 'bmc1'));
    } finally {
      await server.close();
    }
  }

  test(
      'both surfaces skip the SAME manager set under a 404 + 5xx matrix '
      '(EP-S13 / #009/#021)', () async {
    await withFaults(baseFaults, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      final Set<String> consoleIds =
          consoles.map((KvmConsole c) => c.managerId).toSet();
      final Set<String> capabilityIds =
          capabilities.map((KvmCapability c) => c.managerId).toSet();
      expect(consoleIds, survivors);
      expect(capabilityIds, survivors);
      expect(consoleIds, equals(capabilityIds),
          reason: 'both surfaces must skip the exact same manager(s)');
      for (final String skipped in <String>['MgrGone', 'MgrFlappy']) {
        expect(consoleIds, isNot(contains(skipped)),
            reason: 'no phantom console card for skipped $skipped');
        expect(capabilityIds, isNot(contains(skipped)),
            reason: 'no phantom capability card for skipped $skipped');
      }
    });
  });

  test(
      'survivors are surfaced exactly once on both surfaces (RS-6 identity '
      'unchanged, EP-S13)', () async {
    await withFaults(baseFaults, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(consoles, hasLength(survivors.length));
      expect(capabilities, hasLength(survivors.length));
      for (final String id in survivors) {
        expect(
            consoles.where((KvmConsole c) => c.managerId == id), hasLength(1));
        expect(capabilities.where((KvmCapability c) => c.managerId == id),
            hasLength(1));
      }
    });
  });

  test(
      'fetchCapability(id) resolves survivors and returns null for skipped '
      'managers on a shared skip matrix (EP-S13)', () async {
    await withFaults(baseFaults, (KvmService svc) async {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      final Set<String> resolved =
          capabilities.map((KvmCapability c) => c.managerId).toSet();
      for (final String id in survivors) {
        final KvmCapability? single = await svc.fetchCapability(id);
        expect(single, isNotNull, reason: 'survivor $id must resolve');
        expect(single!.managerId, id);
        expect(resolved, contains(id));
      }
      for (final String id in <String>['MgrGone', 'MgrFlappy']) {
        expect(await svc.fetchCapability(id), isNull,
            reason: 'skipped $id must never resolve to a phantom capability');
      }
    });
  });

  test(
      'both surfaces resolve the SAME deterministic secure primary on the '
      'survivors (EP-S13)', () async {
    await withFaults(baseFaults, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmConsole? primary = await svc.fetchPrimaryConsole();

      expect(primary, isNotNull);
      expect(primary!.managerId, 'MgrPrimary',
          reason: 'only surviving secure graphical console wins');
      expect(survivors, contains(primary.managerId));
      expect(survivors, isNot(contains('MgrGone')));
      expect(survivors, isNot(contains('MgrFlappy')));
      expect(KvmService.pickPrimary(consoles)?.managerId, primary.managerId);
      expect(primary.canOpenConsole, isTrue);
      expect(primary.hasSecureLaunchUri, isTrue);
      expect(primary.launchPlan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(primary.launchPlan.isInApp, isFalse);
      expect(primary.launchPlan.acceptSelfSigned, isFalse);
      expect(primary.launchPlan.targetUri, 'https://bmc.example/primary');
    });
  });

  test(
      'survivors keep their OWN cards and URIs (gated screen never blanked, '
      'EP-S13)', () async {
    await withFaults(baseFaults, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(consoles, isNotEmpty);
      expect(capabilities, isNotEmpty);
      final KvmConsole primaryCard =
          consoles.singleWhere((KvmConsole c) => c.managerId == 'MgrPrimary');
      final KvmCapability primaryCap = capabilities
          .singleWhere((KvmCapability c) => c.managerId == 'MgrPrimary');
      expect(primaryCard.hasSecureLaunchUri, isTrue);
      expect(primaryCap.hasUri, isTrue);
      expect(primaryCap.supported, isTrue);
      final KvmConsole serialCard =
          consoles.singleWhere((KvmConsole c) => c.managerId == 'MgrSerial');
      expect(serialCard.managerId, 'MgrSerial');
      for (final KvmConsole c in consoles) {
        expect(survivors, contains(c.managerId));
        expect(c.launchPlan.targetUri, isNot(contains('bmc.example/gone')));
        expect(c.launchPlan.targetUri, isNot(contains('bmc.example/flappy')));
      }
    });
  });

  test(
      '429 (rate-limit) is skipped by BOTH surfaces exactly like 5xx '
      '(EP-S13)', () async {
    await withFaults(<String, int>{
      '/redfish/v1/Managers/MgrGone': 404,
      '/redfish/v1/Managers/MgrFlappy': 429,
    }, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(consoles.map((KvmConsole c) => c.managerId).toSet(), survivors);
      expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
          survivors);
      expect(await svc.fetchCapability('MgrFlappy'), isNull);
    });
  });

  test(
      'when all but one manager fail, both surfaces still surface that one '
      'survivor (EP-S13)', () async {
    await withFaults(<String, int>{
      '/redfish/v1/Managers/MgrGone': 404,
      '/redfish/v1/Managers/MgrFlappy': 503,
      '/redfish/v1/Managers/MgrPrimary': 502,
    }, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(consoles.map((KvmConsole c) => c.managerId).toSet(),
          <String>{'MgrSerial'});
      expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
          <String>{'MgrSerial'});
      expect(consoles, hasLength(1));
      expect(capabilities, hasLength(1));
    });
  });

  test(
      '401 auth failure propagates on BOTH surfaces (RS-2 agreement on '
      'propagation, EP-S13)', () async {
    await withFaults(<String, int>{
      '/redfish/v1/Managers/MgrGone': 401,
    }, (KvmService svc) async {
      await expectLater(
        svc.fetchConsoles(),
        throwsA(isA<RedfishException>()
            .having((RedfishException e) => e.statusCode, 'statusCode', 401)),
      );
      await expectLater(
        svc.fetchCapabilities(),
        throwsA(isA<RedfishException>()
            .having((RedfishException e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  test(
      'non-retryable 501 propagates on BOTH surfaces (RS-2 agreement on '
      'propagation, EP-S13)', () async {
    await withFaults(<String, int>{
      '/redfish/v1/Managers/MgrFlappy': 501,
    }, (KvmService svc) async {
      await expectLater(
        svc.fetchConsoles(),
        throwsA(isA<RedfishException>()
            .having((RedfishException e) => e.statusCode, 'statusCode', 501)),
      );
      await expectLater(
        svc.fetchCapabilities(),
        throwsA(isA<RedfishException>()
            .having((RedfishException e) => e.statusCode, 'statusCode', 501)),
      );
    });
  });
}
