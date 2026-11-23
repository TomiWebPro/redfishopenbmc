// EP-U25 (issues #009 / #021): the "Primary" badge is the single most
// consequential operator signal on the KVM console surface — it marks the
// console `KvmService.pickPrimary` recommends as the launch target. Three
// operator-visible surfaces exist for one manager: the per-console card that
// renders the badge, the capability card, and the full-screen viewer.
//
// AUDIT (2026-11-23): the badge is rendered in exactly ONE place — the
// `_ConsoleCard` header in `lib/features/kvm/views/kvm_view.dart` — gated solely
// by `identical(console, ui.primaryConsole)`, where `ui.primaryConsole` is the
// single `KvmService.pickPrimary(consoles)` result. The capability card and the
// viewer do not render any "Primary" marker. The badge sits as a Chip inside the
// header's single merged `excludeSemantics` node, so it produces no separate /
// screen-reader-only announcement. There is no live divergence.
//
// The genuine UNGUARDED seam: `kvm_widget_test.dart` pins that one badge exists
// and sits on the openable card, and EP-U15 pins the badge target agrees with
// the capability/viewer URI — but at a single fixed width and only on the
// winning card. Nothing drives two consoles from one manager through the REAL
// view at 320 / 800 / 1300 px and pins that exactly ONE visible "Primary" marker
// exists, that it is on the pickPrimary winner and NONE on the peer card, that
// it lives inside ONE merged header node with no split / screen-reader-only
// "Primary" announcement, that no other surface duplicates the marker, and that
// the reflowing header does not overflow at narrow widths. A plausible one-sided
// regression (`isPrimary: true`, `isPrimary: console.serviceEnabled`, or a
// separate `Semantics(label: 'Primary')` node) keeps every existing suite GREEN.
//
// This characterization guard fails closed on that divergence. Display-only,
// dependency-free and TLS-safe: no URL is opened, no WebView / protocol plugin
// is imported and production TLS is untouched.
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

/// One manager with an enabled secure-HTTPS GraphicalConsole (the deterministic
/// pickPrimary winner) and an enabled SSH SerialConsole (the non-Primary peer).
Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP'],
        'ConnectUri': 'https://bmc.example/kvm',
        'MaxConcurrentSessions': 2,
      },
      'SerialConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectUri': 'ssh://bmc.example/serial',
      },
    };

List<KvmConsole> _consoles() =>
    KvmConsole.fromManager(_managerBody(), managerId: 'BMC');

/// Pumps the real `KvmView`, which renders the capability card and every
/// per-console card from the SAME manager projection used by production. A tall
/// viewport keeps both lazy console cards built. Only upstream data providers
/// are overridden — the real cards and the real Primary-badge wiring run.
Future<void> _pumpKvmView(
  WidgetTester tester, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles = _consoles();
  final KvmCapability capability =
      KvmCapability.fromManager(_managerBody(), managerId: 'BMC');
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

/// The console card whose merged header announces [label].
Finder _cardWithHeader(String label) => find.ancestor(
      of: find.bySemanticsLabel(label),
      matching: find.byType(Card),
    );

void main() {
  group('EP-U25 Primary-badge single merged a11y agreement (#009/#021)', () {
    test('one manager yields one deterministic secure-graphical winner', () {
      final List<KvmConsole> consoles = _consoles();
      final KvmConsole? primary = KvmService.pickPrimary(consoles);

      expect(consoles, hasLength(2));
      expect(primary, isNotNull);
      expect(primary!.type, KvmConsoleType.graphical,
          reason: 'the secure graphical is the deterministic Primary');
      expect(
        consoles.where((KvmConsole c) => c.type == KvmConsoleType.graphical),
        hasLength(1),
      );
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
        'exactly one Primary badge on the winner, single merged node, '
        'no duplicate at ${width.toStringAsFixed(0)} px',
        (WidgetTester tester) async {
          await _pumpKvmView(tester, width: width);

          // One merged header node per console (a split header would make these
          // find nothing), byte-identical to the visible type + state text.
          expect(find.bySemanticsLabel('Graphical Console, enabled'),
              findsOneWidget,
              reason: 'winner header is ONE merged node at $width px');
          expect(
              find.bySemanticsLabel('Serial Console, enabled'), findsOneWidget,
              reason: 'peer header is ONE merged node at $width px');

          // Exactly ONE visible "Primary" marker across the whole view.
          expect(find.text('Primary'), findsOneWidget,
              reason: 'exactly one visible Primary marker at $width px');

          // It sits on the pickPrimary winner's card and NOWHERE on the peer.
          final Finder winnerCard =
              _cardWithHeader('Graphical Console, enabled');
          final Finder peerCard = _cardWithHeader('Serial Console, enabled');
          expect(
              find.descendant(of: winnerCard, matching: find.text('Primary')),
              findsOneWidget,
              reason:
                  'the secure graphical card carries the badge at $width px');
          expect(find.descendant(of: peerCard, matching: find.text('Primary')),
              findsNothing,
              reason: 'the non-Primary card must have no badge at $width px');

          // The badge is INSIDE the winner's single merged header node, and no
          // separate / screen-reader-only Semantics node announces "Primary".
          expect(
            find.descendant(
              of: find.bySemanticsLabel('Graphical Console, enabled'),
              matching: find.text('Primary'),
            ),
            findsOneWidget,
            reason: 'badge lives in the single merged header at $width px',
          );
          expect(
            find.bySemanticsLabel(RegExp(r'Primary')),
            findsNothing,
            reason: 'no split or screen-reader-only Primary announcement at '
                '$width px',
          );

          // No competing marker on the capability card.
          expect(
            find.descendant(
              of: find.byType(KvmCapabilityCard),
              matching: find.text('Primary'),
            ),
            findsNothing,
            reason:
                'capability card must not duplicate the marker at $width px',
          );

          expect(tester.takeException(), isNull,
              reason: 'reflowing header must not overflow at $width px');
        },
      );
    }

    testWidgets('viewer does not duplicate the Primary marker',
        (WidgetTester tester) async {
      final KvmConsole primary = KvmService.pickPrimary(_consoles())!;
      await _pumpViewer(tester, primary);

      expect(find.text('Primary'), findsNothing,
          reason:
              'the single marker lives on the console card, not the viewer');
      expect(
        find.bySemanticsLabel(RegExp(r'Primary')),
        findsNothing,
        reason: 'the viewer must not announce a split Primary label',
      );
    });
  });
}
