// EP-S6 (issue #009/#021): service-level capability <-> primary agreement.
//
// `KvmService.fetchCapability(id)` is the per-manager capability SUMMARY the
// capability card renders ("Resolved URI", "Max sessions", supported badge);
// `fetchPrimaryConsole()` / `pickPrimary` is the recommended LAUNCH target the
// "Primary" badge opens. Both walk the SAME manager body through the shared
// model helpers, so for one manager exposing SEVERAL console blocks they must
// agree: the summary must never advertise "supported" / a resolved URI when the
// primary refuses to open, and when it does open the primary's URI must be the
// one the summary resolved (RS-5/RS-6 pin manager-set identity + source, this
// pins the per-manager capability<->primary CONTENT agreement).
//
// Audit: no existing test pins fetchCapability(id) <-> pickPrimary for a single
// multi-block manager (RS-6 uses one block per manager; the ConnectUri
// surfacing test uses a single graphical block). This is a real, unguarded
// cross-method seam. Pure test work over an in-temp mockup — no wire/TLS/dep
// change, no WebView/protocol import, no URL opened, no production TLS weakening.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  late Directory fixtureDir;
  late MockRedfishServer server;

  setUpAll(() async {
    fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s6_fixture_');
    final Directory managersDir = Directory('${fixtureDir.path}/Managers')
      ..createSync(recursive: true);
    File('${managersDir.path}/index.json').writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'Members': <dynamic>[
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC-MULTI'},
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC-OFF'},
        ],
      }),
    );

    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{
      // One manager, three console blocks: an explicitly-disabled graphical
      // (USB/graphical KVM that the BMC reports off), an enabled serial with a
      // copy-only URI (no launch endpoint of its own in the summary path), and
      // the genuinely openable secure-HTTPS remote console. The capability
      // summary and the primary must BOTH land on that secure remote endpoint.
      'BMC-MULTI': <String, dynamic>{
        'Id': 'BMC-MULTI',
        '@odata.id': '/redfish/v1/Managers/BMC-MULTI',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': 'https://bmc.example/graphical-disabled',
          'MaxConcurrentSessions': 2,
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['SSH'],
          // No ConnectUri / MaxConcurrentSessions: a serial block may be
          // enabled without an endpoint the summary path can surface.
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/remote',
          'MaxConcurrentSessions': 5,
        },
      },
      // A manager with no openable block at all (all three explicitly
      // disabled). Both surfaces must agree there is nothing usable, even
      // though the summary's all-disabled fallback still shows a best-effort
      // URI for operator disclosure.
      'BMC-OFF': <String, dynamic>{
        'Id': 'BMC-OFF',
        '@odata.id': '/redfish/v1/Managers/BMC-OFF',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': 'https://bmc.example/off-graphical',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/off-remote',
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['SSH'],
          'ConnectUri': 'ssh://bmc.example/off-serial',
        },
      },
    };
    for (final MapEntry<String, Map<String, dynamic>> entry in bodies.entries) {
      final Directory managerDir = Directory('${managersDir.path}/${entry.key}')
        ..createSync(recursive: true);
      File('${managerDir.path}/index.json')
          .writeAsStringSync(jsonEncode(entry.value));
    }
    server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
  });

  tearDownAll(() async {
    await server.close();
    fixtureDir.deleteSync(recursive: true);
  });

  test(
      'fetchCapability and fetchPrimaryConsole agree for one multi-block '
      'manager (EP-S6 / #009/#021)', () async {
    final KvmService svc = KvmService(
      client: server.buildClient(),
      systemId: 'bmc1',
    );

    final KvmCapability? summary = await svc.fetchCapability('BMC-MULTI');
    final KvmConsole? primary = await svc.fetchPrimaryConsole();

    expect(summary, isNotNull);
    expect(primary, isNotNull);
    // Both entry points must describe the same physical manager.
    expect(summary!.managerId, 'BMC-MULTI');
    expect(primary!.managerId, 'BMC-MULTI');

    // Enablement agreement: a launchable secure remote console exists, so the
    // summary advertises "supported" and the primary is openable.
    expect(summary.supported, isTrue);
    expect(summary.serviceEnabled, isTrue);
    expect(primary.canOpenConsole, isTrue);

    // The headline contract: the summary's resolved URI is byte-for-byte the
    // target the primary actually launches — never the disabled graphical
    // endpoint. A one-sided preference change (e.g. reintroducing the disabled
    // graphical block in _standardConnectUri) would desync the two surfaces
    // while every single-method test stayed GREEN.
    expect(primary.launchPlan.targetUri, 'https://bmc.example/remote');
    expect(summary.uri, primary.launchPlan.targetUri);
    expect(summary.hasUri, isTrue);
    expect(summary.hasSecureLaunchUri, isTrue);
    expect(primary.hasSecureLaunchUri, isTrue);

    // Session-limit agreement: the same openable remote block feeds both the
    // summary's "Max sessions" and the primary console's limit.
    expect(summary.maxSessions, 5);
    expect(primary.maxConcurrentSessions, summary.maxSessions);
  });

  test(
      'padded fetchCapability lookup keeps the same capability<->primary '
      'agreement (EP-S6 / #009/#021)', () async {
    final KvmService svc = KvmService(
      client: server.buildClient(),
      systemId: 'bmc1',
    );

    // RS-9 normalization: a padded lookup resolves the plainly-present manager
    // and therefore must yield the SAME agreement as the exact id.
    final KvmCapability? padded = await svc.fetchCapability('  BMC-MULTI  ');
    final KvmCapability? exact = await svc.fetchCapability('BMC-MULTI');
    final KvmConsole? primary = await svc.fetchPrimaryConsole();

    expect(padded, isNotNull);
    expect(exact, isNotNull);
    expect(primary, isNotNull);
    expect(padded!.uri, exact!.uri);
    expect(padded.uri, primary!.launchPlan.targetUri);
    expect(padded.maxSessions, primary.maxConcurrentSessions);
  });

  test(
      'both surfaces agree a manager with no openable block is unusable '
      '(EP-S6 / #009/#021)', () async {
    final KvmService svc = KvmService(
      client: server.buildClient(),
      systemId: 'bmc1',
    );

    final KvmCapability? summary = await svc.fetchCapability('BMC-OFF');
    final List<KvmConsole> consoles = await svc.fetchConsoles();
    final List<KvmConsole> offConsoles =
        consoles.where((KvmConsole c) => c.managerId == 'BMC-OFF').toList();
    final KvmConsole? primary = KvmService.pickPrimary(offConsoles);

    expect(summary, isNotNull);
    expect(offConsoles, isNotEmpty);
    // No block is openable, so the summary must not advertise "supported" and
    // the picker must not offer a launchable primary. (The all-disabled
    // fallback still surfaces a best-effort URI for disclosure — that is
    // intentional and is NOT what "advertise supported" means here.)
    expect(summary!.supported, isFalse);
    expect(summary.serviceEnabled, isFalse);
    expect(primary, isNotNull);
    expect(primary!.canOpenConsole, isFalse);
    expect(
      offConsoles.any((KvmConsole c) => c.canOpenConsole),
      isFalse,
    );
  });
}
