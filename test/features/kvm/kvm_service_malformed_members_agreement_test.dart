import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

/// Malformed `Members` collection tolerance as a CROSS-SURFACE agreement
/// contract for `KvmService.fetchConsoles()` / `fetchCapabilities()` and the
/// `fetchCapability(id)` lookup (EP-S12, issues #009/#021).
///
/// The shared `_fetchManagerBodies()` walk already tolerates the whole hostile
/// matrix end-to-end (non-list `Members` -> no managers; blank / non-string /
/// missing-link / control-bearing refs skipped; padded / duplicate refs
/// deduplicated; dead 404 links skipped) — so agreement holds BY CONSTRUCTION.
/// AUDIT FIRST confirmed no live divergence. What NO existing guard pinned: the
/// matrix driven through BOTH surfaces in ONE walk. RS-7's hostile-members case
/// checks only `fetchConsoles()`; the malformed-Members fixture checks only
/// non-list -> empty. A one-sided refactor (e.g. a `fetchCapabilities()` walk
/// that rethrows a dead link, or forgets to dedup a padded duplicate) could
/// desync the capability card from the console card while every single-surface
/// suite stayed GREEN — the exact #009 divergence class. This guard pins the
/// shared contract: both surfaces fail closed over the same survivor set, every
/// well-formed physical manager surfaces exactly once with RS-6/RS-8 identity,
/// no phantom / duplicate / control-bearing id leaks, and `fetchCapability(id)`
/// agrees field-for-field with the aggregate. Test-only, dependency-free,
/// TLS-safe; no WebView / protocol import, no production TLS weakening.
void main() {
  group('KvmService malformed Members cross-surface agreement (EP-S12)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    const List<String> survivors = <String>['MgrGraph', 'MgrSerial'];

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s12_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);

      // Two healthy, distinct managers: one secure-HTTPS graphical (primary)
      // and one SSH serial. Both must survive every hostile-Members matrix.
      for (final String segment in survivors) {
        final Directory dir = Directory('${managersDir.path}/$segment')
          ..createSync(recursive: true);
        final Map<String, dynamic> consoleBlock = segment == 'MgrGraph'
            ? <String, dynamic>{
                'ServiceEnabled': true,
                'MaxConcurrentSessions': 4,
                'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
                'ConnectUri': 'https://bmc.example/$segment/console',
              }
            : <String, dynamic>{
                'ServiceEnabled': true,
                'MaxConcurrentSessions': 2,
                'ConnectTypesSupported': <String>['SSH'],
                'ConnectUri': 'ssh://bmc.example/$segment/serial',
              };
        File('${dir.path}/index.json').writeAsStringSync(
          jsonEncode(<String, dynamic>{
            'Id': segment,
            '@odata.id': '/redfish/v1/Managers/$segment',
            if (segment == 'MgrGraph')
              'GraphicalConsole': consoleBlock
            else
              'SerialConsole': consoleBlock,
          }),
        );
      }
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

    /// Rewrites the Managers collection so each test drives a fresh matrix
    /// through the same in-process server.
    void writeMembers(dynamic membersValue) {
      File('${fixtureDir.path}/Managers/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{'Members': membersValue}),
      );
    }

    List<String> sortedIds(Iterable<String> ids) => ids.toList()..sort();

    test(
        'non-list Members (string / map / int / null) fails closed on BOTH '
        'surfaces with no phantom lookup', () async {
      final List<dynamic> malformedCollections = <dynamic>[
        'not-a-list',
        <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGraph'},
        42,
        null,
      ];
      for (final dynamic bad in malformedCollections) {
        writeMembers(bad);
        final KvmService svc = newService();
        expect(await svc.fetchConsoles(), isEmpty,
            reason: 'fetchConsoles must tolerate a non-list Members ($bad)');
        expect(await svc.fetchCapabilities(), isEmpty,
            reason:
                'fetchCapabilities must tolerate a non-list Members ($bad)');
        expect(await svc.fetchCapability('MgrGraph'), isNull,
            reason: 'no phantom capability from a non-list Members ($bad)');
      }
    });

    test(
        'hostile Members entries fail closed on BOTH surfaces; survivors '
        'surface exactly once with RS-6/RS-8 identity + lookup agreement',
        () async {
      writeMembers(<dynamic>[
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/MgrGraph'
        }, // survivor (link-map form)
        '/redfish/v1/Managers/MgrSerial', // survivor (bare-string form)
        '', // blank string
        '   ', // whitespace-only
        12345, // non-string scalar
        <dynamic>[1, 2], // non-string list
        <String, dynamic>{'NoOdata': 'not-a-link'}, // map without @odata.id
        <String, dynamic>{'@odata.id': 42}, // non-string link value
        '/redfish/v1/Managers/MGrGHOST', // dead link (404 -> skipped)
        '  /redfish/v1/Managers/MgrGraph  ', // padded duplicate -> deduped
      ]);

      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      final List<String> consoleIds = sortedIds(
        consoles.map((KvmConsole c) => c.managerId),
      );
      final List<String> capIds = sortedIds(
        capabilities.map((KvmCapability c) => c.managerId),
      );

      expect(consoleIds, survivors,
          reason: 'console surface: each well-formed manager exactly once');
      expect(capIds, survivors,
          reason: 'capability surface: each well-formed manager exactly once');
      expect(consoleIds, capIds,
          reason: 'both surfaces agree on the exact survivor set');

      // No duplicate, phantom, raw-whitespace or control-bearing id leaks.
      for (final List<String> ids in <List<String>>[consoleIds, capIds]) {
        expect(ids.length, ids.toSet().length, reason: 'no duplicate id');
        for (final String id in ids) {
          expect(id, id.trim(), reason: 'id "$id" must be trimmed');
          expect(id.contains(RegExp(r'[\r\n\t\x00-\x1f\x7f]')), isFalse,
              reason: 'id "$id" must carry no control code point');
          expect(id, isNot(contains('GHOST')), reason: 'no phantom manager id');
        }
      }

      // fetchCapability(id) agrees field-for-field with the aggregate, and a
      // padded lookup still resolves (RS-9) while a ghost never does.
      for (final String id in survivors) {
        final KvmCapability? resolved = await svc.fetchCapability(id);
        expect(resolved, isNotNull, reason: 'fetchCapability("$id") resolves');
        final KvmCapability aggregate =
            capabilities.firstWhere((KvmCapability c) => c.managerId == id);
        expect(resolved!.managerId, aggregate.managerId);
        expect(resolved.supported, aggregate.supported);
        expect(resolved.serviceEnabled, aggregate.serviceEnabled);
        expect(resolved.hasUri, aggregate.hasUri);
        expect(resolved.uri, aggregate.uri);
        expect(resolved.connectTypes, aggregate.connectTypes);
      }
      expect(await svc.fetchCapability('  MgrGraph  '), isNotNull,
          reason: 'padded lookup resolves the plainly-present manager');
      expect(await svc.fetchCapability('MGrGHOST'), isNull,
          reason: 'a skipped dead link never resolves');
    });

    test(
        'control-bearing / padded member refs normalize identically on BOTH '
        'surfaces with no phantom id', () async {
      writeMembers(<dynamic>[
        '/redfish/v1/Managers/MgrGraph\r\n', // trailing controls -> trimmed
        '/redfish/v1/Managers/MgrSerial',
        '/redfish/v1/Managers/Mgr\r\nGraph', // embedded control -> dead -> skip
        <String, dynamic>{
          '@odata.id': '  /redfish/v1/Managers/MgrSerial  '
        }, // padded link-map duplicate -> dedup
      ]);

      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(sortedIds(consoles.map((KvmConsole c) => c.managerId)), survivors,
          reason: 'console surface normalizes control/padded refs identically');
      expect(sortedIds(capabilities.map((KvmCapability c) => c.managerId)),
          survivors,
          reason:
              'capability surface normalizes control/padded refs identically');

      final List<String> allIds = <String>[
        ...consoles.map((KvmConsole c) => c.managerId),
        ...capabilities.map((KvmCapability c) => c.managerId),
      ];
      for (final String id in allIds) {
        expect(id, id.trim(), reason: 'id "$id" must be trimmed');
        expect(id.contains(RegExp(r'[\r\n\t\x00-\x1f\x7f]')), isFalse,
            reason: 'id "$id" must carry no control code point');
      }
      for (final String id in survivors) {
        expect(await svc.fetchCapability(id), isNotNull,
            reason: 'fetchCapability("$id") resolves after normalization');
      }
    });
  });
}
