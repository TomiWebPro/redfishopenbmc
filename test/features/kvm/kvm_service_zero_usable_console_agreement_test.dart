// EP-S14 (issue #009/#021): cross-surface ZERO-USABLE-console manager agreement.
//
// Both `fetchConsoles()` (per-console cards) and `fetchCapabilities()` (per-manager
// discovery summaries) walk `/redfish/v1/Managers` through the SAME
// `KvmService._fetchManagerBodies()` helper. A manager that is fetched OK but
// yields ZERO launchable consoles (no blocks at all / every block explicitly
// disabled / URI-less / unsupported ConnectTypes / all-malformed blocks) must
// still be surfaced BY BOTH SURFACES: the capability surface carries exactly one
// discovery-only, non-launchable summary (RS-6/RS-8 identity unchanged), the
// console surface emits no launchable card and no phantom Primary, and a healthy
// sibling keeps its deterministic secure external-browser Primary regardless of
// where the zero-usable managers sit in the Members list.
//
// AUDIT: the agreement already holds BY CONSTRUCTION (one shared walk; the
// capability factory emits one summary per walked manager, the console factory
// emits one card per well-formed block and none for a block-less/malformed body).
// This is a characterization / regression lock, not a live divergence fix — no
// production behaviour is changed. It is DISTINCT from EP-S13 (managers skipped
// because a sibling FETCH fails) and RS-7 (HOSTILE/malformed bodies): here the
// bodies are WELL-FORMED Redfish shapes that simply expose nothing launchable.
// The fixture is in-temp and the server is test-only: no WebView/protocol import,
// no URL opened, no production TLS weakened, no dependency change.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  late Directory fixtureDir;
  late Directory managersDir;

  const String healthy = 'MgrHealthy';
  const Set<String> zeroUsable = <String>{
    'MgrEmpty',
    'MgrDisabled',
    'MgrUnsupported',
    'MgrMalformed',
  };
  const Set<String> allManagers = <String>{...zeroUsable, healthy};

  // Zero-usable managers on BOTH sides of the healthy one, so a "first console
  // wins" / "skip empty manager" regression cannot hide behind member order.
  const List<String> zerosFirst = <String>[
    'MgrEmpty',
    'MgrDisabled',
    'MgrHealthy',
    'MgrUnsupported',
    'MgrMalformed',
  ];
  const List<String> healthyFirst = <String>[
    'MgrHealthy',
    'MgrEmpty',
    'MgrDisabled',
    'MgrUnsupported',
    'MgrMalformed',
  ];

  setUpAll(() async {
    fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s14_fixture_');
    managersDir = Directory('${fixtureDir.path}/Managers')
      ..createSync(recursive: true);

    // All four zero-usable shapes are WELL-FORMED manager bodies (unlike RS-7's
    // non-map bodies): each resolves a stable manager id and a source URI, but
    // exposes nothing an operator can launch.
    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{
      // (1) A valid manager body with no console block at all.
      'MgrEmpty': <String, dynamic>{
        'Id': 'MgrEmpty',
        '@odata.id': '/redfish/v1/Managers/MgrEmpty',
      },
      // (2) A well-formed graphical block that is explicitly DISABLED and has
      //     no ConnectUri/resource link (URI-less) — supported=false + no URI.
      'MgrDisabled': <String, dynamic>{
        'Id': 'MgrDisabled',
        '@odata.id': '/redfish/v1/Managers/MgrDisabled',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
        },
      },
      // (3) An ENABLED graphical block advertising only an unsupported type
      //     (HTML5, no KVMIP) and URI-less — supported=false + no URI.
      'MgrUnsupported': <String, dynamic>{
        'Id': 'MgrUnsupported',
        '@odata.id': '/redfish/v1/Managers/MgrUnsupported',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
        },
      },
      // (4) Every console block is present but malformed (not a JSON object).
      'MgrMalformed': <String, dynamic>{
        'Id': 'MgrMalformed',
        '@odata.id': '/redfish/v1/Managers/MgrMalformed',
        'GraphicalConsole': 'not-a-map',
        'SerialConsole': <dynamic>[1, 2],
        'RemoteConsole': 42,
        'Oem': 'garbage',
      },
      // The healthy sibling: one deterministic secure-HTTPS graphical console.
      'MgrHealthy': <String, dynamic>{
        'Id': 'MgrHealthy',
        '@odata.id': '/redfish/v1/Managers/MgrHealthy',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'ConnectUri': 'https://bmc.example/console',
          'MaxConcurrentSessions': 4,
        },
      },
    };
    for (final MapEntry<String, Map<String, dynamic>> entry in bodies.entries) {
      final Directory dir = Directory('${managersDir.path}/${entry.key}')
        ..createSync(recursive: true);
      File('${dir.path}/index.json').writeAsStringSync(jsonEncode(entry.value));
    }
  });

  tearDownAll(() async {
    fixtureDir.deleteSync(recursive: true);
  });

  /// Rewrites `/Managers` to [order] and runs [body] against a fresh server.
  Future<void> withOrder(
    List<String> order,
    Future<void> Function(KvmService svc) body,
  ) async {
    File('${managersDir.path}/index.json').writeAsStringSync(
      jsonEncode(<String, dynamic>{
        'Members':
            order.map((String id) => '/redfish/v1/Managers/$id').toList(),
      }),
    );
    final MockRedfishServer server =
        await MockRedfishServer(fixturesDir: fixtureDir.path).start();
    try {
      await body(KvmService(client: server.buildClient(), systemId: 'bmc1'));
    } finally {
      await server.close();
    }
  }

  test(
      'capability surface surfaces EVERY walked manager exactly once '
      '(RS-6/RS-8 identity, EP-S14)', () async {
    await withOrder(zerosFirst, (KvmService svc) async {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
          allManagers);
      expect(capabilities, hasLength(allManagers.length));
      for (final String id in allManagers) {
        expect(capabilities.where((KvmCapability c) => c.managerId == id),
            hasLength(1),
            reason: 'manager $id must yield exactly one capability card');
      }
    });
  });

  test(
      'every zero-usable manager is a discovery-only, non-launchable capability '
      '(EP-S14)', () async {
    await withOrder(zerosFirst, (KvmService svc) async {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      for (final String id in zeroUsable) {
        final KvmCapability cap =
            capabilities.singleWhere((KvmCapability c) => c.managerId == id);
        expect(cap.supported, isFalse, reason: '$id must not be KVM-supported');
        expect(cap.uri, isNull, reason: '$id must have no launch URI');
        expect(cap.hasUri, isFalse, reason: '$id must be discovery-only');
        expect(cap.hasSecureLaunchUri, isFalse,
            reason: '$id must not advertise a secure launch target');
        expect(cap.hasHttpLaunchUri, isFalse,
            reason: '$id must not advertise an HTTP launch target');
      }
    });
  });

  test(
      'console surface emits no launchable card for a zero-usable manager '
      '(EP-S14)', () async {
    await withOrder(zerosFirst, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();

      expect(
          consoles
              .map((KvmConsole c) => c.managerId)
              .toSet()
              .difference(allManagers),
          isEmpty,
          reason: 'no foreign console cards');
      final List<KvmConsole> healthyCards =
          consoles.where((KvmConsole c) => c.managerId == healthy).toList();
      expect(healthyCards, hasLength(1));
      expect(healthyCards.single.canOpenConsole, isTrue);
      for (final KvmConsole card in consoles) {
        if (!zeroUsable.contains(card.managerId)) continue;
        expect(card.canOpenConsole, isFalse,
            reason: '${card.managerId} must never be launchable');
        expect(card.hasSecureLaunchUri, isFalse,
            reason: '${card.managerId} must never have a secure launch URI');
        expect(
            card.launchPlan.route, isNot(KvmConsoleRenderRoute.externalBrowser),
            reason: '${card.managerId} must never route to the browser');
        expect(card.launchPlan.acceptSelfSigned, isFalse,
            reason: '${card.managerId} must never accept self-signed TLS');
      }
    });
  });

  test(
      'fetchCapability(id) resolves each zero-usable manager to the SAME '
      'discovery-only summary as fetchCapabilities() (EP-S14)', () async {
    await withOrder(zerosFirst, (KvmService svc) async {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      for (final String id in zeroUsable) {
        final KvmCapability? single = await svc.fetchCapability(id);
        final KvmCapability listed =
            capabilities.singleWhere((KvmCapability c) => c.managerId == id);
        expect(single, isNotNull, reason: '$id must resolve');
        expect(single!.managerId, id);
        expect(single.supported, listed.supported, reason: '$id supported');
        expect(single.serviceEnabled, listed.serviceEnabled,
            reason: '$id serviceEnabled');
        expect(single.uri, listed.uri, reason: '$id uri');
        expect(single.hasUri, listed.hasUri, reason: '$id hasUri');
        expect(single.connectTypes, listed.connectTypes,
            reason: '$id connectTypes');
      }
    });
  });

  test(
      'the healthy sibling keeps its deterministic secure Primary despite '
      'zero-usable managers (EP-S14)', () async {
    await withOrder(zerosFirst, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmConsole? primary = await svc.fetchPrimaryConsole();

      expect(primary, isNotNull);
      expect(primary!.managerId, healthy);
      expect(zeroUsable, isNot(contains(primary.managerId)),
          reason: 'a zero-usable manager must never be Primary');
      expect(KvmService.pickPrimary(consoles)?.managerId, healthy,
          reason: 'both primary entry points must agree');
      expect(primary.canOpenConsole, isTrue);
      expect(primary.hasSecureLaunchUri, isTrue);
      expect(primary.launchPlan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(primary.launchPlan.isInApp, isFalse);
      expect(primary.launchPlan.acceptSelfSigned, isFalse);
      expect(primary.launchPlan.targetUri, 'https://bmc.example/console');
    });
  });

  test(
      'agreement is independent of zero-usable manager position in Members '
      '(EP-S14)', () async {
    await withOrder(healthyFirst, (KvmService svc) async {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmConsole? primary = await svc.fetchPrimaryConsole();

      expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
          allManagers);
      expect(capabilities, hasLength(allManagers.length));
      expect(primary, isNotNull);
      expect(primary!.managerId, healthy);
      for (final String id in zeroUsable) {
        expect(
            capabilities
                .singleWhere((KvmCapability c) => c.managerId == id)
                .supported,
            isFalse,
            reason: '$id stays discovery-only when it follows the healthy one');
        expect(await svc.fetchCapability(id), isNotNull,
            reason: '$id still resolves when it follows the healthy one');
      }
      // Every console-emitting manager still has a capability on the other
      // surface, and no zero-usable manager becomes a launchable console.
      for (final KvmConsole c in consoles) {
        expect(capabilities.map((KvmCapability k) => k.managerId),
            contains(c.managerId));
        if (zeroUsable.contains(c.managerId)) {
          expect(c.canOpenConsole, isFalse);
        }
      }
    });
  });

  test(
      'no phantom launch target on any zero-usable capability or console card '
      '(EP-S14)', () async {
    await withOrder(zerosFirst, (KvmService svc) async {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      final List<KvmConsole> consoles = await svc.fetchConsoles();

      for (final KvmCapability cap in capabilities) {
        if (!zeroUsable.contains(cap.managerId)) continue;
        expect(cap.hasUri, isFalse, reason: '${cap.managerId} capability URI');
        expect(cap.launchUri, isNull, reason: '${cap.managerId} launchUri');
      }
      for (final KvmConsole card in consoles) {
        if (!zeroUsable.contains(card.managerId)) continue;
        expect(card.launchPlan.targetUri, isNull,
            reason: '${card.managerId} console target');
        expect(card.launchPlan.isInApp, isFalse,
            reason: '${card.managerId} in-app route');
      }
    });
  });

  test('unknown / blank ids never resolve to a phantom capability (EP-S14)',
      () async {
    await withOrder(zerosFirst, (KvmService svc) async {
      expect(await svc.fetchCapability('MgrDoesNotExist'), isNull);
      expect(await svc.fetchCapability('   '), isNull);
    });
  });
}
