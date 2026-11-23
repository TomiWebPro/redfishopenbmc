// EP-S10 (issues #009/#021): primary-selection fail-closed determinism over an
// ALL-UNSAFE candidate set.
//
// `KvmService.pickPrimary` tiers its selection:
//   secure-HTTPS graphical > secure-HTTPS any type > openable graphical >
//   openable any type > graphical > first.
// Every sibling service guard exercises a HEALTHY secure-HTTPS sibling (EP-S14,
// EP-S11, EP-S2) or a pure model list with a genuine secure target (primary
// secure-tier tests). NONE drives the ALL-UNSAFE case: every openable-looking
// console carries a control- (CRLF/NUL) or bidi-bearing "secure-HTTPS"
// `ConnectUri`, so the fail-closed classifier refuses ALL of them as secure and
// none is launchable. In that case the badge must fall through the openable/
// secure tiers to the first graphical console and stay there DETERMINISTICALLY
// across repeated calls — never flipping to a later/disabled console via a
// one-sided iteration-order refactor, and never advertising an unsafe target as
// a secure / browser / in-app / self-signed-accepting one.
//
// AUDIT: the classifier/plan layers already fail closed on control/bidi URIs by
// construction (shared `_controlSafeTrimmedUri`), and the model classifiers
// agree — no live divergence, no behaviour change. Genuine unguarded seam: the
// latest-tier fallback (`firstGraphical ?? consoles.first`) has NO test that
// pins its FIRST-in-BMC-order winner when no console is secure/openable and a
// non-graphical console is listed first. Characterization / regression lock,
// not churn. The fixture is in-temp and the server is test-only: no WebView /
// protocol import, no URL opened, no production TLS weakened, no dependency.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  late Directory fixtureDir;
  late Directory managersDir;

  // The FIRST member emits only a NON-graphical (serial) console; the next two
  // emit graphical consoles. A "first console wins" / "last graphical wins"
  // refactor therefore flips the badge away from the expected first graphical.
  const String serialUnsafe = 'MgrSerialCtrl';
  const String firstGraphicalUnsafe = 'MgrGraphicalCtrl';
  const String secondGraphicalUnsafe = 'MgrGraphicalBidi';
  const String disabled = 'MgrAllDisabled';
  const Set<String> allManagers = <String>{
    serialUnsafe,
    firstGraphicalUnsafe,
    secondGraphicalUnsafe,
    disabled,
  };

  const List<String> bmcOrder = <String>[
    serialUnsafe,
    firstGraphicalUnsafe,
    secondGraphicalUnsafe,
    disabled,
  ];
  // Reversed order + disabled first: invariants must hold regardless of where
  // the unsafe / disabled managers sit in Members.
  const List<String> reversedOrder = <String>[
    disabled,
    secondGraphicalUnsafe,
    firstGraphicalUnsafe,
    serialUnsafe,
  ];

  setUpAll(() async {
    fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s10_fixture_');
    managersDir = Directory('${fixtureDir.path}/Managers')
      ..createSync(recursive: true);

    // Every "secure-looking" ConnectUri is actually control-/bidi-bearing, so
    // isSecureHttpsConsoleUri (and the whole launch plan) fails closed on it.
    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{
      // Non-graphical console FIRST, with a CRLF-injected "HTTPS" target.
      serialUnsafe: <String, dynamic>{
        'Id': serialUnsafe,
        '@odata.id': '/redfish/v1/Managers/$serialUnsafe',
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['SSH'],
          'ConnectUri': 'https://bmc1.example/serial\r\nX-Injected: 1',
        },
      },
      // First graphical console: CRLF-bearing "HTTPS" target.
      firstGraphicalUnsafe: <String, dynamic>{
        'Id': firstGraphicalUnsafe,
        '@odata.id': '/redfish/v1/Managers/$firstGraphicalUnsafe',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'ConnectUri': 'https://bmc2.example/kvm\r\nX-Injected: 1',
        },
      },
      // Second graphical console: bidi-override (RLO) inside the host.
      secondGraphicalUnsafe: <String, dynamic>{
        'Id': secondGraphicalUnsafe,
        '@odata.id': '/redfish/v1/Managers/$secondGraphicalUnsafe',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'ConnectUri': 'https://bmc\u202E3.example/kvm',
        },
      },
      // A manager whose every block is disabled / URI-less.
      disabled: <String, dynamic>{
        'Id': disabled,
        '@odata.id': '/redfish/v1/Managers/$disabled',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': false,
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

  test('all secure-looking targets fail closed (fixture sanity)', () async {
    await withOrder(bmcOrder, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      expect(consoles, isNotEmpty);
      for (final KvmConsole c in consoles) {
        expect(c.hasSecureLaunchUri, isFalse,
            reason: '${c.managerId}/${c.type} must NOT be classified secure');
        expect(c.canOpenConsole, isFalse,
            reason: '${c.managerId}/${c.type} must NOT be launchable');
        expect(c.launchPlan.route, isNot(KvmConsoleRenderRoute.externalBrowser),
            reason: '${c.managerId} must never route to the browser');
        expect(c.launchPlan.isInApp, isFalse,
            reason: '${c.managerId} must never render in-app');
        expect(c.launchPlan.acceptSelfSigned, isFalse,
            reason: '${c.managerId} must never accept self-signed TLS');
        final String? target = c.launchPlan.targetUri;
        expect(target == null || isControlSafeConsoleUri(target), isTrue,
            reason:
                '${c.managerId} must never expose a control-bearing target');
      }
    });
  });

  test(
      'fetchPrimaryConsole() and pickPrimary() agree on the SAME first-in-BMC-'
      'order graphical winner over an all-unsafe set (EP-S10)', () async {
    await withOrder(bmcOrder, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmConsole? fetched = await svc.fetchPrimaryConsole();
      final KvmConsole? picked = KvmService.pickPrimary(consoles);

      expect(fetched, isNotNull);
      expect(picked, isNotNull);
      expect(fetched!.managerId, firstGraphicalUnsafe,
          reason: 'no console is secure/openable, so the badge must fall to '
              'the FIRST graphical console in BMC order (not the serial one '
              'listed first, nor a later/disabled one)');
      expect(fetched.type, KvmConsoleType.graphical);
      expect(picked!.managerId, fetched.managerId,
          reason: 'both primary entry points must agree');
      expect(picked.type, fetched.type);
      expect(fetched.managerId, isNot(serialUnsafe));
      expect(fetched.managerId, isNot(disabled));
    });
  });

  test('primary selection is deterministic across repeated calls (EP-S10)',
      () async {
    await withOrder(bmcOrder, (KvmService svc) async {
      final KvmConsole? first = await svc.fetchPrimaryConsole();
      final KvmConsole? second = await svc.fetchPrimaryConsole();
      final KvmConsole? third = await svc.fetchPrimaryConsole();
      expect(first, isNotNull);
      expect(second!.managerId, first!.managerId);
      expect(second.type, first.type);
      expect(third!.managerId, first.managerId);
      expect(third.type, first.type);
      expect(first.managerId, firstGraphicalUnsafe);
    });
  });

  test(
      'the chosen primary is never badged as a safe browser/secure target '
      '(EP-S10)', () async {
    await withOrder(bmcOrder, (KvmService svc) async {
      final KvmConsole? primary = await svc.fetchPrimaryConsole();
      expect(primary, isNotNull);
      expect(primary!.hasSecureLaunchUri, isFalse);
      expect(primary.hasHttpLaunchUri, isFalse);
      expect(primary.canOpenConsole, isFalse);
      expect(primary.launchStrategy, KvmLaunchStrategy.noUri);
      expect(primary.launchPlan.route,
          isNot(KvmConsoleRenderRoute.externalBrowser));
      expect(primary.launchPlan.isInApp, isFalse);
      expect(primary.launchPlan.acceptSelfSigned, isFalse);
    });
  });

  test(
      'every physical manager stays surfaced identically on both discovery '
      'surfaces (EP-S10)', () async {
    await withOrder(bmcOrder, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(consoles.map((KvmConsole c) => c.managerId).toSet(), allManagers);
      expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
          allManagers);
      expect(capabilities, hasLength(allManagers.length));
      for (final String id in allManagers) {
        expect(capabilities.where((KvmCapability c) => c.managerId == id),
            hasLength(1),
            reason: 'manager $id must yield exactly one capability card');
      }
      // The disabled manager emits non-launchable console cards but no URI.
      for (final KvmConsole c in consoles) {
        if (c.managerId == disabled) {
          expect(c.canOpenConsole, isFalse);
        }
      }
    });
  });

  test(
      'fetchCapability(id) agrees field-for-field with the aggregate over an '
      'all-unsafe set (EP-S10)', () async {
    await withOrder(bmcOrder, (KvmService svc) async {
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      for (final String id in allManagers) {
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
        expect(single.hasSecureLaunchUri, listed.hasSecureLaunchUri,
            reason: '$id secure classification');
        expect(single.connectTypes, listed.connectTypes,
            reason: '$id connectTypes');
        // No capability on any surface may advertise a secure launch target.
        expect(single.hasSecureLaunchUri, isFalse,
            reason: '$id must never badge a secure target');
      }
    });
  });

  test(
      'never-badge-unsafe invariants hold with reversed / disabled-first '
      'Members order (EP-S10)', () async {
    await withOrder(reversedOrder, (KvmService svc) async {
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      final KvmConsole? fetched = await svc.fetchPrimaryConsole();

      expect(consoles.map((KvmConsole c) => c.managerId).toSet(), allManagers);
      expect(capabilities.map((KvmCapability c) => c.managerId).toSet(),
          allManagers);
      expect(fetched, isNotNull);
      // With no secure/openable console anywhere, the documented last-tier
      // fallback is the FIRST graphical card in BMC order (here the disabled
      // manager's graphical block). Pin that deterministic winner — a
      // "last graphical wins" iteration refactor would flip it to a later one.
      expect(fetched!.managerId, disabled);
      expect(fetched.type, KvmConsoleType.graphical);
      expect(KvmService.pickPrimary(consoles)?.managerId, fetched.managerId,
          reason: 'both entry points agree under any member order');
      expect(fetched.hasSecureLaunchUri, isFalse);
      expect(fetched.canOpenConsole, isFalse);
      expect(fetched.launchPlan.route,
          isNot(KvmConsoleRenderRoute.externalBrowser));
      expect(fetched.launchPlan.isInApp, isFalse);
      expect(fetched.launchPlan.acceptSelfSigned, isFalse);
    });
  });
}
