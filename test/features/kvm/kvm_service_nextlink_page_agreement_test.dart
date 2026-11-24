// EP-S23 (issues #009 / #021): `@odata.nextLink` collection-page agreement
// across the `/Managers` walk.
//
// AUDIT FIRST: `KvmService._fetchManagerBodies()` is the single, stateless walk
// shared by `fetchConsoles()` and `fetchCapabilities()`; `fetchCapability(id)`
// is derived from `fetchCapabilities()`, and the controller / cards consume only
// those surfaces. The walk reads the Redfish-mandated `Members` key and never
// reads `@odata.nextLink` (grep over lib/features/kvm + test/features/kvm: zero
// hits), so BOTH surfaces deterministically adopt the same single page today —
// no live divergence, no behaviour change.
//
// What NO existing guard pins: the root `@odata.nextLink` VALUE FAMILY. Every
// service guard writes a fixed single-page root and only varies `Members` /
// member bodies / document shape. A plausible one-sided edit — e.g. having
// `fetchCapabilities()` follow a root nextLink page while `fetchConsoles()`
// keeps the first page — would badge a ghost manager on the capability card /
// `fetchCapability(id)` lookup while the console list stayed GREEN: exactly the
// #009 cross-surface discovery-desync class these guards exist to prevent. This
// guard pins that whatever page set the shared walk adopts, it is identical on
// both surfaces, with no ghost lookup and no double-count of a repeated member.
//
// Test-only, dependency-free and TLS-safe: no WebView / protocol import, no URL
// opened outside the localhost mock, no dependency and no production change.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  group('KvmService @odata.nextLink page agreement (EP-S23)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    /// Managers on the first (root) page — the set the shared walk adopts.
    const List<String> rootIds = <String>['MgrGraph', 'MgrSerial'];

    /// A manager that exists ONLY on the second page; it must never appear.
    const String pageOnlyId = 'MgrPage';

    Map<String, dynamic> _managerBody(String id) => <String, dynamic>{
          'Id': id,
          '@odata.id': '/redfish/v1/Managers/$id',
          if (id == 'MgrGraph' || id == pageOnlyId)
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'MaxConcurrentSessions': id == 'MgrGraph' ? 4 : 8,
              'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
              'ConnectUri': 'https://bmc.example/$id/console',
            }
          else
            'SerialConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'MaxConcurrentSessions': 2,
              'ConnectTypesSupported': <String>['SSH'],
              'ConnectUri': 'ssh://bmc.example/$id/serial',
            },
        };

    void _writeManager(Directory managersDir, String id) {
      final Directory dir = Directory('${managersDir.path}/$id')
        ..createSync(recursive: true);
      File('${dir.path}/index.json')
          .writeAsStringSync(jsonEncode(_managerBody(id)));
    }

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s23_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);
      for (final String id in <String>[...rootIds, pageOnlyId]) {
        _writeManager(managersDir, id);
      }
      // Second page: one new manager plus a REPEAT of a root-page member id, to
      // pin that an adopted/repeated member is never double-counted.
      final Directory pageDir = Directory('${managersDir.path}/Page2')
        ..createSync(recursive: true);
      File('${pageDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/$pageOnlyId'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGraph'},
          ],
        }),
      );
      server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
    });

    tearDownAll(() async {
      await server.close();
      fixtureDir.deleteSync(recursive: true);
    });

    KvmService newService() =>
        KvmService(client: server.buildClient(), systemId: 'bmc1');

    /// Rewrites the raw `/Managers` root with the given nextLink value.
    void writeRoot(Object? nextLink, {bool includeKey = true}) {
      final Map<String, dynamic> root = <String, dynamic>{
        'Members': <dynamic>[
          for (final String id in rootIds)
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/$id'},
        ],
      };
      if (includeKey) root['@odata.nextLink'] = nextLink;
      File('${fixtureDir.path}/Managers/index.json')
          .writeAsStringSync(jsonEncode(root));
    }

    List<String> capabilityIds(List<KvmCapability> cs) =>
        cs.map((KvmCapability c) => c.managerId).toList();

    List<String> consoleManagerIds(List<KvmConsole> consoles) =>
        consoles.map((KvmConsole c) => c.managerId).toList();

    Future<void> expectSharedPageSet(String label) async {
      final KvmService svc = newService();

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      // Both surfaces adopt exactly the root-page survivor set, once each.
      expect(consoleManagerIds(consoles).toSet(), rootIds.toSet(),
          reason: '$label: console surface must adopt the root page set');
      expect(capabilityIds(capabilities).toSet(), rootIds.toSet(),
          reason: '$label: capability surface must adopt the same page set');
      expect(consoleManagerIds(consoles).length, rootIds.length,
          reason: '$label: no double-count on the console surface');
      expect(capabilityIds(capabilities).length, rootIds.length,
          reason: '$label: no double-count on the capability surface');

      // Ordered identity, not just set identity: the two surfaces must walk in
      // the same member order for the same adopted page.
      final List<String> consoleOrder =
          consoleManagerIds(consoles).toSet().toList();
      expect(capabilityIds(capabilities), consoleOrder,
          reason: '$label: both surfaces must preserve the same walk order');

      // No ghost lookup: a manager that exists only on the (unadopted) nextLink
      // page must not resolve on either the capability list or the single lookup.
      expect(await svc.fetchCapability(pageOnlyId), isNull,
          reason: '$label: page-only manager must not be a ghost capability');

      // Field-for-field agreement for each adopted manager across the console
      // and capability surfaces, and a stable repeated-walk result.
      final List<KvmCapability> again = await svc.fetchCapabilities();
      expect(capabilityIds(again), capabilityIds(capabilities),
          reason: '$label: repeated walk must be deterministic');
      for (final String id in rootIds) {
        final KvmConsole console = consoles.firstWhere(
          (KvmConsole c) => c.managerId == id,
        );
        final KvmCapability cap = capabilities.firstWhere(
          (KvmCapability c) => c.managerId == id,
        );
        expect(cap.managerId, console.managerId, reason: '$label/$id');
        expect(cap.serviceEnabled, console.serviceEnabled,
            reason: '$label/$id enablement');
        expect(cap.maxSessions, console.maxConcurrentSessions,
            reason: '$label/$id session limit');
        expect(cap.hasUri, console.launchUri != null,
            reason: '$label/$id resolved URI presence');
      }

      // The controller surfaces the same adopted set (no page-only Primary).
      final KvmController controller = KvmController(service: svc);
      await controller.load();
      expect(controller.state.error, isNull,
          reason: '$label: load must succeed');
      expect(
          controller.state.consoles.map((KvmConsole c) => c.managerId).toSet(),
          rootIds.toSet(),
          reason: '$label: controller consoles match the walk');
      expect(
        controller.state.primaryConsole == null ||
            rootIds.contains(controller.state.primaryConsole!.managerId),
        isTrue,
        reason: '$label: Primary must come from the adopted page set',
      );
    }

    test('no-link control: single page adopted identically on both surfaces',
        () async {
      writeRoot(null, includeKey: false);
      await expectSharedPageSet('no-link');
    });

    test('absolute page path nextLink is ignored identically on both surfaces',
        () async {
      writeRoot('/redfish/v1/Managers/Page2');
      await expectSharedPageSet('absolute-path');
    });

    test('query-string page nextLink is ignored identically on both surfaces',
        () async {
      writeRoot('/redfish/v1/Managers?page=2');
      await expectSharedPageSet('query-string');
    });

    test('relative page nextLink is ignored identically on both surfaces',
        () async {
      writeRoot('Page2');
      await expectSharedPageSet('relative');
    });

    test(
        'scheme-relative page nextLink is ignored identically on both surfaces',
        () async {
      writeRoot('//127.0.0.1:${server.port}/redfish/v1/Managers/Page2');
      await expectSharedPageSet('scheme-relative');
    });

    test('blank / whitespace nextLink never creates a second page surface',
        () async {
      for (final String blank in <String>['', '   ', '\t\n']) {
        writeRoot(blank);
        await expectSharedPageSet('blank(${blank.codeUnits.length})');
      }
    });

    test('malformed non-string nextLink values fail closed without throwing',
        () async {
      for (final Object? bad in <Object?>[
        42,
        true,
        <String>['page2'],
        <String, dynamic>{'@odata.id': '/redfish/v1/Managers/Page2'},
      ]) {
        writeRoot(bad);
        await expectSharedPageSet('non-string(${bad.runtimeType})');
      }
    });

    test(
        'source liveness: nextLink page handling lives only in the shared walk',
        () {
      final String source =
          File('lib/features/kvm/kvm_service.dart').readAsStringSync();

      String methodBody(String signature) {
        final int start = source.indexOf(signature);
        expect(start, greaterThanOrEqualTo(0),
            reason: '$signature must exist in kvm_service.dart');
        final int open = source.indexOf('{', start);
        int depth = 0;
        for (int i = open; i < source.length; i++) {
          if (source[i] == '{') depth++;
          if (source[i] == '}') {
            depth--;
            if (depth == 0) return source.substring(open, i + 1);
          }
        }
        fail('unbalanced braces for $signature');
      }

      // Neither public surface may adopt a page on its own: page selection is
      // the shared walk's concern. A one-sided `nextLink` read in either surface
      // fails this invariant (and the behavioral matrix above) closed.
      for (final String signature in <String>[
        'Future<List<KvmConsole>> fetchConsoles() async',
        'Future<List<KvmCapability>> fetchCapabilities() async',
      ]) {
        expect(
          methodBody(signature).toLowerCase().contains('nextlink'),
          isFalse,
          reason: '$signature must not adopt an @odata.nextLink page directly; '
              'page handling belongs to the shared _fetchManagerBodies() walk',
        );
      }
    });
  });
}
