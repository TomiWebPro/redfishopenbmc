// EP-U15 (issue #009 / #021): three-surface launch-target agreement.
//
// For ONE Redfish manager exposing several console blocks, three operator-
// visible surfaces render the launch target derived from the same manager body:
//   * the per-console card badged "Primary" and its "Connect URI" row
//     (`KvmConsole.launchUri`),
//   * the capability card's "Resolved URI" row (`KvmCapability.launchUri`),
//   * the viewer's "Console URI" / Open target (`KvmConsole.launchPlan.targetUri`).
//
// The model-level capability<->primary agreement is pinned by EP-S7 and the
// viewer's OWN four renderings by EP-U14, but nothing pinned that all THREE
// surfaces for one manager carry the SAME byte-identical, control-safe
// secure-HTTPS target. A one-sided view edit could badge one endpoint while the
// capability card or viewer advertised another — the exact #009 divergence
// class — with every single-surface suite still GREEN. This guard builds all
// three from one manager body and fails closed on any such divergence across
// 320 / 800 / 1300 px, with visible text == announced label.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol plugin is imported, no production TLS change is involved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

const String _target = 'https://bmc.example/remote';

class _StubController extends KvmController {
  _StubController()
      : super(service: KvmService(client: null, systemId: 'bmc1'));

  @override
  Future<void> load() async {}
}

SystemHandle _handle() => const SystemHandle(
      profile: ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: true),
    );

/// One manager with a disabled Graphical, an enabled serial SSH and an enabled
/// secure-HTTPS Remote console. [remoteUri] is the Remote block's ConnectUri so
/// a padded variant can pin the trimmed-agreement contract.
Map<String, dynamic> _managerBody({String remoteUri = _target}) =>
    <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': false,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': 'https://bmc.example/graphical-disabled',
      },
      'SerialConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectUri': 'ssh://bmc.example/serial',
      },
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': remoteUri,
      },
    };

bool _hasControl(String value) =>
    value.codeUnits.any((int c) => c < 0x20 || c == 0x7f);

/// Pumps the real `KvmView`, which renders the capability card and every
/// per-console card from the SAME manager projection used by production. A tall
/// viewport keeps the lazy console list's cards all built (KvmView uses a lazy
/// ListView). Only the upstream data providers are overridden — both card
/// implementations run for real, so a one-sided rendering change is caught.
Future<void> _pumpKvmView(
  WidgetTester tester, {
  required Map<String, dynamic> body,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: 'BMC');
  final KvmCapability capability =
      KvmCapability.fromManager(body, managerId: 'BMC');
  final KvmController controller = _StubController()
    ..state = KvmUiState(
      consoles: consoles,
      primaryConsole: KvmService.pickPrimary(consoles),
    );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) =>
              Future<List<KvmCapability>>.value(<KvmCapability>[capability]),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(WidgetTester tester, KvmConsole console) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
      ],
      child: MaterialApp(home: KvmConsoleViewerPage(console: console)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EP-U15 three-surface launch-target model agreement (#009/#021)', () {
    test('one manager: primary badge, capability and viewer target are one URI',
        () {
      final Map<String, dynamic> body = _managerBody();
      final KvmConsole? primary = KvmService.pickPrimary(
        KvmConsole.fromManager(body, managerId: 'BMC'),
      );
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');

      expect(primary, isNotNull);
      expect(primary!.launchUri, _target);
      expect(capability.launchUri, _target);
      expect(primary.launchPlan.targetUri, _target);
      expect(_hasControl(primary.launchUri!), isFalse);
      expect(_hasControl(capability.launchUri!), isFalse);
      expect(primary.launchPlan.targetUri, primary.launchUri,
          reason: 'viewer/copy target must equal the Primary badge target');
    });

    test('a padded remote URI still agrees on the trimmed value', () {
      final Map<String, dynamic> body =
          _managerBody(remoteUri: '  https://bmc.example/remote  ');
      final KvmConsole? primary = KvmService.pickPrimary(
        KvmConsole.fromManager(body, managerId: 'BMC'),
      );
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');

      expect(primary!.launchUri, _target);
      expect(capability.launchUri, _target);
      expect(primary.launchPlan.targetUri, _target);
    });
  });

  group('EP-U15 three-surface rendered agreement (#009/#021)', () {
    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'Primary badge, capability row and URI rows agree at '
          '${width.toStringAsFixed(0)} px', (WidgetTester tester) async {
        await _pumpKvmView(tester, body: _managerBody(), width: width);

        // Capability card: the "Resolved URI" row (merged a11y node + visible
        // SelectableText) carries the same secure target.
        final Finder capabilityCard = find.byType(KvmCapabilityCard);
        expect(capabilityCard, findsOneWidget);
        expect(
          find.descendant(
            of: capabilityCard,
            matching: find.bySemanticsLabel('Resolved URI: $_target'),
          ),
          findsOneWidget,
          reason: 'capability card must resolve the Primary target at '
              '$width px',
        );
        expect(
          find.descendant(
            of: capabilityCard,
            matching: find.byWidgetPredicate(
              (Widget w) => w is SelectableText && w.data == _target,
            ),
          ),
          findsOneWidget,
          reason: 'visible capability URI must be byte-identical at $width px',
        );

        // Console card: the card whose "Connect URI" row is the secure target
        // is the one badged "Primary", and its visible row matches too.
        final Finder remoteNode =
            find.bySemanticsLabel('Connect URI: $_target');
        expect(remoteNode, findsOneWidget,
            reason: 'the secure console card must show the shared target at '
                '$width px');
        final Finder primaryCard =
            find.ancestor(of: remoteNode, matching: find.byType(Card));
        expect(
          find.descendant(
            of: primaryCard,
            matching: find.text('Primary'),
          ),
          findsOneWidget,
          reason: 'the card carrying the shared target is the Primary badge at '
              '$width px',
        );
        expect(
          find.descendant(
            of: primaryCard,
            matching: find.byWidgetPredicate(
              (Widget w) => w is SelectableText && w.data == _target,
            ),
          ),
          findsOneWidget,
          reason: 'visible console-card URI must be byte-identical at '
              '$width px',
        );

        // No overflow at this width (pumpAndSettle + no pending exception).
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('padded remote: all rendered rows show the trimmed target',
        (WidgetTester tester) async {
      await _pumpKvmView(
        tester,
        body: _managerBody(remoteUri: '  https://bmc.example/remote  '),
        width: 800,
      );

      expect(
        find.bySemanticsLabel('Resolved URI: $_target'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Connect URI: $_target'),
        findsOneWidget,
      );
      expect(find.textContaining('https://bmc.example/remote  '), findsNothing,
          reason: 'no surface may render the padded raw value');
    });

    testWidgets('viewer Open/URI target equals the badge and capability target',
        (WidgetTester tester) async {
      final Map<String, dynamic> body = _managerBody();
      final KvmConsole primary = KvmService.pickPrimary(
        KvmConsole.fromManager(body, managerId: 'BMC'),
      )!;
      await _pumpViewer(tester, primary);

      expect(primary.launchUri, _target);
      expect(primary.launchPlan.targetUri, _target);
      expect(find.bySemanticsLabel('Console URI: $_target'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is SelectableText && w.data == _target,
        ),
        findsOneWidget,
        reason: 'viewer visible URI must be byte-identical to the other two '
            'surfaces',
      );
      expect(find.text('Copy console URI'), findsOneWidget);
    });
  });

  group(
      'EP-U15 hostile target fails closed on interactive surfaces '
      '(#009/#021)', () {
    testWidgets(
        'CRLF-bearing console never offers a viewer Open/copy affordance',
        (WidgetTester tester) async {
      const String hostile = 'https://bmc.example/remote\r\nX-Injected: 1';
      const KvmConsole console = KvmConsole(
        type: KvmConsoleType.remote,
        managerId: 'BMC',
        connectTypesSupported: const <String>['HTML5'],
        serviceEnabled: true,
        connectUri: hostile,
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );

      expect(console.launchPlan.targetUri, isNull,
          reason: 'a control-bearing target must fail closed');
      await _pumpViewer(tester, console);

      expect(find.text('Copy console URI'), findsNothing,
          reason: 'no copy affordance for a control-bearing target');
      expect(find.textContaining('No direct console URI'), findsOneWidget);
      expect(find.textContaining('X-Injected'), findsNothing,
          reason: 'no control/injection marker may reach any surface');
      expect(
        find.bySemanticsLabel(RegExp(r'No direct console URI')),
        findsOneWidget,
      );
    });
  });
}
