// EP-S18 (issues #009/#021): same-tier secure-console Primary tie-break
// determinism and capability agreement across the full service walk.
//
// EP-S6 pins capability<->primary agreement for a manager whose graphical block
// is DISABLED (the secure remote wins); EP-S7 pins it at the pure-model layer;
// EP-S11 pins first-in-BMC-order for THREE single-block managers; EP-S2 pins
// tier precedence + CRLF at the picker. None of them drives ONE manager that
// exposes a GraphicalConsole + RemoteConsole + SerialConsole all enabled and
// secure-HTTPS with DISTINCT session limits through the real /Managers walk in
// both declaration orders. That is exactly where a one-sided "last secure
// graphical wins" (`firstSecureGraphical = console` with no `break`) or a
// session-limit source swap would move the "Primary" badge / "Max sessions"
// off the operator's first-declared console while every existing suite stayed
// GREEN. This guard locks that seam.
//
// Pure test work over in-temp mockups — no wire/TLS/dependency change, no
// WebView/protocol import, no URL opened, no production TLS weakening.

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

/// A manager body with three enabled console blocks, all with distinct
/// endpoints AND distinct session limits. The secure graphical is the
/// top-tier target; the secure remote is second; the SSH serial is not
/// browser-openable. [graphicalUri] and [graphicalLimit] make each fixture's
/// expected winner unambiguous.
Map<String, dynamic> multiBlockManager(
  String id,
  String graphicalUri,
  int graphicalLimit,
) =>
    <String, dynamic>{
      'Id': id,
      '@odata.id': '/redfish/v1/Managers/$id',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
        'ConnectUri': graphicalUri,
        'MaxConcurrentSessions': graphicalLimit,
      },
      'SerialConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['SSH'],
        'ConnectUri': 'ssh://bmc.example/$id/serial',
        'MaxConcurrentSessions': 1,
      },
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': 'https://bmc.example/$id/remote',
        'MaxConcurrentSessions': 3,
      },
    };

void main() {
  late Directory dirAB;
  late Directory dirBA;
  late MockRedfishServer serverAB;
  late MockRedfishServer serverBA;

  setUpAll(() async {
    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{
      'BMC-A': multiBlockManager(
        'BMC-A',
        'https://bmc.example/a/graphical',
        7,
      ),
      'BMC-B': multiBlockManager(
        'BMC-B',
        'https://bmc.example/b/graphical',
        11,
      ),
    };

    // Two identical body sets; only the MEMBER order differs (A-first vs
    // B-first). The winner must follow declaration order on both surfaces.
    for (final MapEntry<String, List<String>> fixture in <String, List<String>>{
      'ab': <String>['BMC-A', 'BMC-B'],
      'ba': <String>['BMC-B', 'BMC-A'],
    }.entries) {
      final Directory dir =
          await Directory.systemTemp.createTemp('kvm_ep_s18_${fixture.key}_');
      final Directory managersDir = Directory('${dir.path}/Managers')
        ..createSync(recursive: true);
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': fixture.value
              .map((String id) => <String, dynamic>{
                    '@odata.id': '/redfish/v1/Managers/$id',
                  })
              .toList(),
        }),
      );
      for (final MapEntry<String, Map<String, dynamic>> entry
          in bodies.entries) {
        final Directory managerDir =
            Directory('${managersDir.path}/${entry.key}')
              ..createSync(recursive: true);
        File('${managerDir.path}/index.json')
            .writeAsStringSync(jsonEncode(entry.value));
      }
      if (fixture.key == 'ab') {
        dirAB = dir;
      } else {
        dirBA = dir;
      }
    }
    serverAB = await MockRedfishServer(fixturesDir: dirAB.path).start();
    serverBA = await MockRedfishServer(fixturesDir: dirBA.path).start();
  });

  tearDownAll(() async {
    await serverAB.close();
    await serverBA.close();
    dirAB.deleteSync(recursive: true);
    dirBA.deleteSync(recursive: true);
  });

  test(
      'A-first: first-in-BMC-order secure graphical wins with URI + session '
      'limit agreement on every repeated walk (EP-S18)', () async {
    final KvmService svc = KvmService(
      client: serverAB.buildClient(),
      systemId: 'bmc1',
    );

    for (int i = 0; i < 3; i++) {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      expect(consoles, hasLength(6));
      expect(
        consoles.map((KvmConsole c) => c.managerId).toList(),
        <String>['BMC-A', 'BMC-A', 'BMC-A', 'BMC-B', 'BMC-B', 'BMC-B'],
        reason: 'console order stays BMC declaration order, block order '
            'graphical -> serial -> remote, on every walk',
      );

      final KvmConsole? primary = await svc.fetchPrimaryConsole();
      expect(primary, isNotNull);
      expect(primary!.managerId, 'BMC-A');
      expect(primary.launchPlan.targetUri, 'https://bmc.example/a/graphical');
      expect(primary.maxConcurrentSessions, 7);
      expect(primary.hasSecureLaunchUri, isTrue);
      final KvmConsole? viaPicker = KvmService.pickPrimary(consoles);
      expect(viaPicker, isNotNull);
      expect(viaPicker!.managerId, primary.managerId);
      expect(viaPicker.launchPlan.targetUri, primary.launchPlan.targetUri);
      expect(viaPicker.maxConcurrentSessions, primary.maxConcurrentSessions);

      final KvmCapability? capA = await svc.fetchCapability('BMC-A');
      expect(capA, isNotNull);
      expect(capA!.uri, primary.launchPlan.targetUri);
      expect(capA.maxSessions, 7);
      expect(
        capA.maxSessions,
        primary.maxConcurrentSessions,
        reason: 'the summary\'s "Max sessions" must be the limit of the very '
            'console the Primary badge opens, not the remote/serial block',
      );
    }
  });

  test(
      'B-first (reversed member order): winner follows declaration order, '
      'deterministic and agreement-preserving (EP-S18)', () async {
    final KvmService svc = KvmService(
      client: serverBA.buildClient(),
      systemId: 'bmc1',
    );

    for (int i = 0; i < 3; i++) {
      final KvmConsole? primary = await svc.fetchPrimaryConsole();
      expect(primary, isNotNull);
      expect(primary!.managerId, 'BMC-B');
      expect(primary.launchPlan.targetUri, 'https://bmc.example/b/graphical');

      final KvmCapability? capB = await svc.fetchCapability('BMC-B');
      expect(capB, isNotNull);
      expect(capB!.uri, primary.launchPlan.targetUri);
      expect(capB.maxSessions, 11);
      expect(capB.maxSessions, primary.maxConcurrentSessions);
    }
  });

  test(
      'reversed console-BLOCK insertion order cannot change the winner or '
      'the capability agreement (EP-S18)', () {
    // Same body, but Remote / Serial / Graphical inserted in reverse order.
    // fromManager emits a fixed type order and both resolvers use a fixed
    // block-priority order, so the graphical must still win with its own limit.
    final Map<String, dynamic> reversedBody = <String, dynamic>{
      'Id': 'BMC-REV',
      '@odata.id': '/redfish/v1/Managers/BMC-REV',
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': 'https://bmc.example/rev/remote',
        'MaxConcurrentSessions': 3,
      },
      'SerialConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['SSH'],
        'ConnectUri': 'ssh://bmc.example/rev/serial',
        'MaxConcurrentSessions': 1,
      },
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP'],
        'ConnectUri': 'https://bmc.example/rev/graphical',
        'MaxConcurrentSessions': 13,
      },
    };

    final List<KvmConsole> consoles =
        KvmConsole.fromManager(reversedBody, managerId: 'BMC-REV');
    expect(
      consoles.map((KvmConsole c) => c.type).toList(),
      <KvmConsoleType>[
        KvmConsoleType.graphical,
        KvmConsoleType.serial,
        KvmConsoleType.remote,
      ],
      reason: 'fromManager emits a fixed graphical -> serial -> remote order '
          'regardless of JSON key insertion order',
    );
    final KvmConsole? primary = KvmService.pickPrimary(consoles);
    expect(primary, isNotNull);
    expect(primary!.type, KvmConsoleType.graphical);
    expect(primary.launchPlan.targetUri, 'https://bmc.example/rev/graphical');

    final KvmCapability cap =
        KvmCapability.fromManager(reversedBody, managerId: 'BMC-REV');
    expect(cap.uri, primary.launchPlan.targetUri);
    expect(cap.maxSessions, 13);
    expect(cap.maxSessions, primary.maxConcurrentSessions);
  });

  test(
      'pickPrimary is non-mutating: the surfaced console list is byte-for-byte '
      'unchanged after selection (EP-S18)', () async {
    final KvmService svc = KvmService(
      client: serverAB.buildClient(),
      systemId: 'bmc1',
    );
    final List<KvmConsole> consoles = await svc.fetchConsoles();
    final List<String> before = consoles
        .map((KvmConsole c) => '${c.managerId}:${c.launchPlan.targetUri}')
        .toList();

    KvmService.pickPrimary(consoles);
    KvmService.pickPrimary(consoles);

    expect(
      consoles
          .map((KvmConsole c) => '${c.managerId}:${c.launchPlan.targetUri}')
          .toList(),
      before,
      reason: 'selection must not reorder or rewrite the surfaced cards',
    );
  });

  test(
      'a control/CRLF-bearing "secure" graphical never wins the same-tier '
      'tie (EP-S18)', () {
    final Map<String, dynamic> body = <String, dynamic>{
      'Id': 'BMC-CRLF',
      '@odata.id': '/redfish/v1/Managers/BMC-CRLF',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP'],
        'ConnectUri': 'https://bmc.example/crlf\r\nX-Injected: 1',
        'MaxConcurrentSessions': 99,
      },
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': 'https://bmc.example/crlf/remote',
        'MaxConcurrentSessions': 4,
      },
    };
    final List<KvmConsole> consoles =
        KvmConsole.fromManager(body, managerId: 'BMC-CRLF');
    final KvmConsole injected = consoles.firstWhere(
      (KvmConsole c) => c.type == KvmConsoleType.graphical,
    );
    final KvmConsole remote = consoles.firstWhere(
      (KvmConsole c) => c.type == KvmConsoleType.remote,
    );
    expect(injected.hasSecureLaunchUri, isFalse);
    expect(injected.canOpenConsole, isFalse);
    expect(remote.hasSecureLaunchUri, isTrue);

    final KvmConsole? primary = KvmService.pickPrimary(consoles);
    expect(primary, isNotNull);
    expect(primary, same(remote),
        reason: 'a CRLF/spoofed graphical must fail closed and never be the '
            'top-tier Primary over a genuine secure console');
    expect(primary!.launchPlan.targetUri, 'https://bmc.example/crlf/remote');

    // The capability summary's resolved URI agrees with the Primary even when
    // the graphical block carries a hostile endpoint. (Its aggregated session
    // limit is intentionally not constrained here: that aggregation is owned
    // by KvmCapability, outside EP-S18's service-scoped writes.)
    final KvmCapability cap =
        KvmCapability.fromManager(body, managerId: 'BMC-CRLF');
    expect(cap.uri, primary.launchPlan.targetUri);
  });
}
