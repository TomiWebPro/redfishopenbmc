import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

/// Manager-identity resolution contract for `KvmService._managerId` (EP-S5,
/// issues #009/#021).
///
/// `_managerId` keys a manager by body `Id` → body `@odata.id` last segment →
/// member-URI last segment, trimming every source. That key drives
/// `fetchCapability(id)`, the card identity and the downstream session/eviction
/// key, so a padded/blank/numeric/bool `Id` must never become a phantom key or
/// desync the two views. The existing suite pins a padded string `Id` and
/// padded/blank `@odata.id`, but NOT a non-string (numeric/bool) `Id`, a fully
/// blank-string `Id`, or a numeric `Id` combined with a blank `@odata.id`. This
/// guard pins that whole hostile-`Id` precedence slice in one in-temp mockup.
void main() {
  group('KvmService manager-identity resolution under hostile Id (EP-S5)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    // member-URI segment -> expected resolved managerId.
    const Map<String, String> expectedIds = <String, String>{
      'NumId': 'NumId', // numeric `Id` ignored -> body @odata.id segment
      'BoolId': 'BoolId', // bool `Id` ignored -> body @odata.id segment
      'BlankStrId': 'BlankStrId', // blank-string `Id` ignored -> @odata.id
      'MemberOnly':
          'MemberOnly', // numeric `Id` + blank @odata.id -> member URI
      'CanonicalId': 'CanonicalId', // canonical string `Id` wins over @odata.id
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
        case 'NumId':
          body['Id'] = 42;
          body['@odata.id'] = '/redfish/v1/Managers/NumId';
        case 'BoolId':
          body['Id'] = true;
          body['@odata.id'] = '/redfish/v1/Managers/BoolId';
        case 'BlankStrId':
          body['Id'] = '   ';
          body['@odata.id'] = '/redfish/v1/Managers/BlankStrId';
        case 'MemberOnly':
          body['Id'] = 42;
          body['@odata.id'] = '   ';
        case 'CanonicalId':
          // A canonical string `Id` that differs from the @odata.id segment:
          // precedence must keep the `Id`, not the URI segment.
          body['Id'] = 'CanonicalId';
          body['@odata.id'] = '/redfish/v1/Managers/SegmentName';
      }
      return body;
    }

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s5_fixture_');
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

    test(
        'non-string / blank Id is ignored; identity follows documented '
        'precedence on both views', () async {
      final KvmService svc = newService();

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      final Set<String> consoleIds =
          consoles.map((KvmConsole c) => c.managerId).toSet();
      final Set<String> capIds =
          capabilities.map((KvmCapability c) => c.managerId).toSet();

      expect(consoleIds, expectedIds.values.toSet(),
          reason: 'console cards keyed by the resolved manager id');
      expect(capIds, expectedIds.values.toSet(),
          reason: 'capability cards keyed by the same manager id');

      // A hostile raw `Id` must never leak through as a manager key.
      for (final String forbidden in <String>['42', 'true', 'false', '   ']) {
        expect(consoleIds, isNot(contains(forbidden)),
            reason: 'console key "$forbidden" is a raw hostile Id');
        expect(capIds, isNot(contains(forbidden)),
            reason: 'capability key "$forbidden" is a raw hostile Id');
      }
    });

    test(
        'resolved ids are trimmed, control-free and lookup-stable '
        '(fetchCapability resolves each on both views)', () async {
      final KvmService svc = newService();

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      for (final String expected in expectedIds.values) {
        final Iterable<KvmConsole> console =
            consoles.where((KvmConsole c) => c.managerId == expected);
        final Iterable<KvmCapability> capability =
            capabilities.where((KvmCapability c) => c.managerId == expected);
        expect(console, hasLength(1), reason: 'one console card for $expected');
        expect(capability, hasLength(1),
            reason: 'one capability card for $expected');

        final KvmCapability? resolved = await svc.fetchCapability(expected);
        expect(resolved, isNotNull,
            reason: 'fetchCapability("$expected") must resolve the manager');
        expect(resolved!.managerId, expected);
        expect(resolved.supported, isTrue);
      }

      // No resolved key may carry stray whitespace or a control code point.
      final List<String> allIds = <String>[
        ...consoles.map((KvmConsole c) => c.managerId),
        ...capabilities.map((KvmCapability c) => c.managerId),
      ];
      for (final String id in allIds) {
        expect(id, id.trim(), reason: 'id "$id" must be trimmed');
        expect(id.contains(RegExp(r'[\r\n\t\x00-\x1f\x7f]')), isFalse,
            reason: 'id "$id" must not carry a control code point');
      }
    });
  });
}
