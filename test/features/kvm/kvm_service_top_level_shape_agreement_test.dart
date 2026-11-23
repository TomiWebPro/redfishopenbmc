// EP-S20 (issues #009 / #021): the top-level `/Managers` DOCUMENT SHAPE is an
// unguarded input dimension of KVM discovery. Both operator surfaces
// (`KvmService.fetchConsoles()` / `fetchCapabilities()`) and the read-only
// `fetchCapability(id)` lookup walk the same collection document, so a
// one-sided root-shape assumption could silently blank one (or both) gated
// surfaces while every existing suite stayed GREEN — the exact #009
// discovery-blanking divergence class.
//
// AUDIT FIRST: `RedfishClient.getJson` normalizes EVERY decoded body to a Map
// via `_asMap` (a bare list or scalar is wrapped as `{'value': ...}`, `null`
// becomes `{}`), and both discovery surfaces share the single
// `_fetchManagerBodies()` walk, which reads the Redfish-mandated `Members` key.
// So there is NO live divergence today: every non-`Members` root fails closed
// to empty and the one spec-valid `{'Members': [...]}` root surfaces the
// survivor set on both. What NO existing guard pins: the top-level DOCUMENT
// SHAPE matrix. EP-S12's hostile-Members guard always writes a fixed
// `{'Members': ...}` root and only varies the Members VALUE. A plausible
// root-shape refactor (switching the collection key to OData `value`, or
// assuming a bare list) could break discovery for compliant BMCs undetected.
// This guard pins the shared cross-surface contract over the full root-shape
// matrix. Test-only, dependency-free and TLS-safe: no WebView / protocol
// import, no URL opened, no production TLS weakening.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  group('KvmService top-level /Managers document-shape agreement (EP-S20)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    const List<String> survivors = <String>['MgrGraph', 'MgrSerial'];

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s20_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);

      // Two healthy, distinct managers behind the spec-valid root: a
      // secure-HTTPS graphical (Primary) and an SSH serial. Both must survive
      // the valid Members shape and never surface from any invalid root shape.
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

    /// Writes the RAW top-level JSON document served at `/redfish/v1/Managers`.
    /// Unlike EP-S12 (which always writes `{'Members': ...}` and varies the
    /// value), this varies the ROOT shape itself.
    void writeRootDocument(Object? root) {
      File('${fixtureDir.path}/Managers/index.json').writeAsStringSync(
        jsonEncode(root),
      );
    }

    List<String> sortedIds(Iterable<String> ids) => ids.toList()..sort();

    Future<void> expectEmptyOnBoth(String label) async {
      final KvmService svc = newService();
      expect(await svc.fetchConsoles(), isEmpty,
          reason: '$label: fetchConsoles must fail closed to empty');
      expect(await svc.fetchCapabilities(), isEmpty,
          reason: '$label: fetchCapabilities must fail closed to empty');
      expect(await svc.fetchCapability('MgrGraph'), isNull,
          reason: '$label: no phantom capability lookup');
    }

    test(
        'non-Members top-level roots fail closed on BOTH surfaces, no throw, '
        'no phantom lookup', () async {
      final List<({String label, Object? doc})> badRoots =
          <({String label, Object? doc})>[
        (
          label: 'bare JSON list',
          doc: <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGraph'},
            '/redfish/v1/Managers/MgrSerial',
          ]
        ),
        (
          label: 'value-wrapped list',
          doc: <String, dynamic>{
            'value': <dynamic>[
              <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGraph'},
            ]
          }
        ),
        (
          label: 'value-wrapped non-list',
          doc: <String, dynamic>{'value': 'not-a-list'}
        ),
        (label: 'empty map', doc: <String, dynamic>{}),
        (label: 'non-list scalar', doc: 42),
        (label: 'null root', doc: null),
      ];
      for (final ({String label, Object? doc}) root in badRoots) {
        writeRootDocument(root.doc);
        await expectEmptyOnBoth(root.label);
      }
    });

    test(
        'spec-valid Members root surfaces the same survivor set once on BOTH '
        'surfaces with deterministic Primary and agreeing lookup', () async {
      writeRootDocument(<String, dynamic>{
        'Members': <dynamic>[
          <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGraph'},
          '/redfish/v1/Managers/MgrSerial',
        ]
      });

      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(sortedIds(consoles.map((KvmConsole c) => c.managerId)), survivors,
          reason: 'console surface: each manager from the Members root once');
      expect(sortedIds(capabilities.map((KvmCapability c) => c.managerId)),
          survivors,
          reason: 'capability surface: same survivor set once');

      // Same physical manager yields one card per surface with matching shape.
      expect(consoles.length, survivors.length,
          reason: 'no duplicate console cards');
      expect(capabilities.length, survivors.length,
          reason: 'no duplicate capability cards');

      // Deterministic, launch-safe Primary across repeated walks.
      final String? p1 = KvmService.pickPrimary(consoles)?.managerId;
      final String? p2 =
          KvmService.pickPrimary(await svc.fetchConsoles())?.managerId;
      expect(p1, p2, reason: 'Primary is deterministic across repeated walks');
      expect(survivors, contains(p1),
          reason: 'Primary is one of the surfaced managers');

      // fetchCapability(id) agrees field-for-field with the aggregate; padded
      // lookup resolves, a ghost never does (RS-9).
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
      expect(await svc.fetchCapability('  MgrSerial  '), isNotNull,
          reason: 'padded lookup resolves the plainly-present manager');
      expect(await svc.fetchCapability('MGrGHOST'), isNull,
          reason: 'no phantom lookup');
    });
  });
}
