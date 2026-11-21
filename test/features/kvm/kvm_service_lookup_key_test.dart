import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';

import '../../helpers/mock_redfish_server.dart';

/// Lookup-key normalization contract for `KvmService.fetchCapability` (RS-9,
/// issues #009/#021).
///
/// `_managerId` derives every card key with the shared trim-nonblank rule, so
/// `capability.managerId` is always a trimmed id. The public read-only lookup
/// entry point `fetchCapability(managerId)` must apply the SAME normalization to
/// its argument: a padded lookup must resolve a plainly-present manager, and a
/// blank (or blank-after-trim) lookup must return `null` without creating a
/// phantom miss. Prior to this guard the lookup compared the caller argument
/// verbatim, so `fetchCapability('  PaddedBMC  ')` missed the manager keyed
/// `PaddedBMC` even though `fetchCapabilities()` surfaced it.
void main() {
  group('KvmService.fetchCapability lookup-key normalization (RS-9)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    // member-URI segment -> expected resolved (trimmed) manager id.
    const Map<String, String> expectedIds = <String, String>{
      'PaddedId': 'PaddedBMC', // padded string `Id` -> trimmed
      'NumId': 'NumId', // numeric `Id` ignored -> @odata.id segment
      'BlankId': 'BlankId', // blank-string `Id` ignored -> @odata.id segment
      'MemberOnly': 'MemberOnly', // numeric `Id` + blank @odata -> member URI
    };

    Map<String, dynamic> bodyFor(String segment) {
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.type': '#Manager.v1_19_0.Manager',
        'Name': 'manager $segment',
        'ManagerType': 'BMC',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'MaxConcurrentSessions': 4,
          'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
          'ConnectUri': 'https://bmc.example/$segment/console',
        },
      };
      switch (segment) {
        case 'PaddedId':
          body['Id'] = '  PaddedBMC  ';
          body['@odata.id'] = '/redfish/v1/Managers/PaddedId';
        case 'NumId':
          body['Id'] = 42;
          body['@odata.id'] = '/redfish/v1/Managers/NumId';
        case 'BlankId':
          body['Id'] = '   ';
          body['@odata.id'] = '/redfish/v1/Managers/BlankId';
        case 'MemberOnly':
          body['Id'] = 42;
          body['@odata.id'] = '   ';
      }
      return body;
    }

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_rs9_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);

      final List<dynamic> members = <dynamic>[];
      for (final String segment in expectedIds.keys) {
        members.add(<String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/$segment',
        });
      }
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{'Members': members}),
      );

      for (final String segment in expectedIds.keys) {
        final Directory dir = Directory('${managersDir.path}/$segment')
          ..createSync(recursive: true);
        File('${dir.path}/index.json')
            .writeAsStringSync(jsonEncode(bodyFor(segment)));
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

    test('fetchCapabilities surfaces only normalized (trimmed) keys (RS-9)',
        () async {
      final KvmService svc = newService();

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(
        capabilities.map((KvmCapability c) => c.managerId).toSet(),
        expectedIds.values.toSet(),
        reason: 'card keys are trimmed, no padded/blank/numeric raw Id leaks',
      );
      for (final String id
          in capabilities.map((KvmCapability c) => c.managerId)) {
        expect(id, id.trim(), reason: 'key "$id" must be trimmed');
      }
    });

    test(
        'a padded lookup resolves the same capability as the exact key '
        '(RS-9)', () async {
      final KvmService svc = newService();

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      final Set<String> surfacedIds =
          capabilities.map((KvmCapability c) => c.managerId).toSet();

      for (final String expected in expectedIds.values) {
        final KvmCapability? exact = await svc.fetchCapability(expected);
        expect(exact, isNotNull, reason: 'exact lookup "$expected" resolves');
        expect(exact!.managerId, expected);

        // Padded lookup must use the same normalization as key derivation.
        for (final String padded in <String>[
          '  $expected',
          '$expected  ',
          ' \t$expected\n '
        ]) {
          final KvmCapability? resolved = await svc.fetchCapability(padded);
          expect(resolved, isNotNull,
              reason: 'padded lookup ${jsonEncode(padded)} must resolve '
                  '"$expected" (no phantom miss for a present manager)');
          expect(resolved!.managerId, expected);
          expect(
            resolved.sourceManagerUri,
            exact.sourceManagerUri,
            reason: 'padded lookup resolves the SAME physical manager',
          );
          expect(surfacedIds, contains(resolved.managerId),
              reason: 'resolved id is surfaced by fetchCapabilities()');
        }
      }
    });

    test('blank / padded-blank / unknown padded lookups return null (RS-9)',
        () async {
      final KvmService svc = newService();

      for (final String blank in <String>['', '   ', ' \t\n ', '\r\n']) {
        expect(await svc.fetchCapability(blank), isNull,
            reason: 'blank lookup ${jsonEncode(blank)} must not resolve');
      }
      expect(await svc.fetchCapability('  does-not-exist  '), isNull,
          reason: 'an unknown padded id still returns null');

      // Blank lookups must not be mistaken for a real manager key.
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(
        capabilities.any((KvmCapability c) => c.managerId.trim().isEmpty),
        isFalse,
      );
    });
  });
}
