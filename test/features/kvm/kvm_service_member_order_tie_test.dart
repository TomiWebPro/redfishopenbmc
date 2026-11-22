// EP-S11 (issues #009/#021): member-order tie determinism across the service
// surfaces.
//
// `_fetchManagerBodies` walks `/redfish/v1/Managers` in BMC declaration order
// and `KvmService.pickPrimary` breaks at the FIRST openable secure-HTTPS
// graphical console. Together these mean that when a BMC exposes several
// EQUALLY-ranked openable secure consoles, every service surface must resolve
// the SAME first-in-BMC-order winner on every call:
//   * `fetchConsoles()`  -> consoles in BMC member order;
//   * `fetchPrimaryConsole()` / `pickPrimary(fetchConsoles())` -> first winner;
//   * `fetchCapabilities()` / `fetchCapability(id)` -> stable manager order and
//     a resolved URI that is byte-for-byte the winner's launch target.
//
// Audit: EP-S2 pins tier PRECEDENCE (secure > plaintext) and EP-S6 pins
// capability<->primary agreement for ONE multi-block manager plus an all-off
// manager, but NO existing test feeds TWO equally-ranked secure graphical
// consoles in a fixed BMC order. A "last secure graphical wins" refactor
// (`firstSecureGraphical = console` with no `break`) would change `pickPrimary`
// while every existing tier / agreement guard stayed GREEN, silently moving
// the "Primary" badge off the operator's first declared BMC. This is a
// regression guard at a genuinely unguarded seam, not a behaviour change:
// no live divergence found, no wire/transport/TLS/dependency change, no
// WebView/protocol import, no URL opened, no production TLS weakening.

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
    fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s11_fixture_');
    final Directory managersDir = Directory('${fixtureDir.path}/Managers')
      ..createSync(recursive: true);

    // Three managers, each exposing exactly ONE enabled secure-HTTPS
    // graphical console — i.e. three EQUALLY-ranked openable secure targets.
    final Map<String, String> bodies = <String, String>{
      'BMC-A': 'https://bmc.example/a-console',
      'BMC-B': 'https://bmc.example/b-console',
      'BMC-C': 'https://bmc.example/c-console',
    };
    for (final MapEntry<String, String> entry in bodies.entries) {
      final Directory managerDir = Directory('${managersDir.path}/${entry.key}')
        ..createSync(recursive: true);
      File('${managerDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Id': entry.key,
          '@odata.id': '/redfish/v1/Managers/${entry.key}',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
            'ConnectUri': entry.value,
            'MaxConcurrentSessions': 2,
          },
        }),
      );
    }

    // Members deliberately hostile: a padded link-map first, a bare string,
    // a plain link-map, and a padded duplicate of the FIRST manager (dedup,
    // first-occurrence-wins). The physical first-in-BMC-order winner stays
    // BMC-A and every manager is surfaced exactly once.
    File('${managersDir.path}/index.json').writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'Members': <dynamic>[
          <String, dynamic>{'@odata.id': '  /redfish/v1/Managers/BMC-A  '},
          '/redfish/v1/Managers/BMC-B',
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC-C'},
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC-A'},
        ],
      }),
    );
    server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
  });

  tearDownAll(() async {
    await server.close();
    fixtureDir.deleteSync(recursive: true);
  });

  KvmService newService() => KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

  test(
      'fetchConsoles preserves fixed BMC member order (dedup, padded/hostile '
      'members) and is stable across repeated calls (EP-S11)', () async {
    final KvmService svc = newService();

    for (int i = 0; i < 3; i++) {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      expect(
        consoles.map((KvmConsole c) => c.managerId).toList(),
        <String>['BMC-A', 'BMC-B', 'BMC-C'],
        reason: 'member iteration order must be the BMC declaration order on '
            'every call; the padded duplicate of BMC-A must be deduped',
      );
      expect(consoles, hasLength(3));
      expect(
        consoles.every((KvmConsole c) => c.hasSecureLaunchUri),
        isTrue,
        reason: 'each manager exposes one openable secure-HTTPS graphical '
            'console, so all three are equally-ranked secure targets',
      );
      expect(
        consoles.map((KvmConsole c) => c.launchPlan.targetUri).toList(),
        <String>[
          'https://bmc.example/a-console',
          'https://bmc.example/b-console',
          'https://bmc.example/c-console',
        ],
      );
    }
  });

  test(
      'pickPrimary / fetchPrimaryConsole resolve the FIRST equal-rank secure '
      'winner on every repeated call (EP-S11)', () async {
    final KvmService svc = newService();

    for (int i = 0; i < 3; i++) {
      final KvmConsole? primary = await svc.fetchPrimaryConsole();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmConsole? viaPicker = KvmService.pickPrimary(consoles);

      expect(primary, isNotNull);
      expect(primary!.managerId, 'BMC-A');
      expect(primary.launchPlan.targetUri, 'https://bmc.example/a-console');
      expect(primary.canOpenConsole, isTrue);
      expect(primary.hasSecureLaunchUri, isTrue);

      // The picker over the surfaced console list must agree with the
      // fetch-based entry point, byte-for-byte, on every call.
      expect(viaPicker, isNotNull);
      expect(viaPicker!.managerId, primary.managerId);
      expect(viaPicker.launchPlan.targetUri, primary.launchPlan.targetUri);
    }
  });

  test(
      'fetchCapabilities / fetchCapability(id) keep stable manager order and '
      'agree with the primary winner (EP-S11)', () async {
    final KvmService svc = newService();

    for (int i = 0; i < 3; i++) {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(
        capabilities.map((KvmCapability c) => c.managerId).toList(),
        <String>['BMC-A', 'BMC-B', 'BMC-C'],
        reason: 'manager-set iteration order must be stable across calls',
      );
      expect(capabilities, hasLength(3));

      final KvmConsole? primary = await svc.fetchPrimaryConsole();
      final KvmCapability? winner = await svc.fetchCapability('BMC-A');
      expect(winner, isNotNull);
      expect(winner!.managerId, 'BMC-A');
      expect(winner.hasUri, isTrue);
      expect(winner.hasSecureLaunchUri, isTrue);
      // The per-manager summary's resolved URI is byte-for-byte the launch
      // target the "Primary" badge actually opens.
      expect(winner.uri, primary!.launchPlan.targetUri);

      // Every physical manager is still surfaced with its OWN resolved URI —
      // the tie winner never eclipses the other managers (RS-6/RS-8 identity).
      for (final MapEntry<String, String> expected in <String, String>{
        'BMC-A': 'https://bmc.example/a-console',
        'BMC-B': 'https://bmc.example/b-console',
        'BMC-C': 'https://bmc.example/c-console',
      }.entries) {
        final KvmCapability? cap = await svc.fetchCapability(expected.key);
        expect(cap, isNotNull);
        expect(cap!.managerId, expected.key);
        expect(cap.uri, expected.value);
      }
    }
  });
}
