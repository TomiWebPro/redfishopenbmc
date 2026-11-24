// EP-U39 / #009 / #021: RTL x 2.0x COMPOUND a11y agreement for the "Primary"
// badge across the KVM operator surfaces.
//
// AUDIT FIRST (see queues/ui.md EP-U39): the "Primary" badge is the single most
// consequential operator signal on the KVM console surface — it marks the
// `KvmService.pickPrimary` launch winner. EP-U25 pins that exactly ONE visible
// "Primary" marker exists, sits inside the winner's single merged header
// `excludeSemantics` node, appears on NO peer / capability / viewer surface and
// produces no split / screen-reader-only announcement — but only at the default
// LTR / 1.0x text scale, at fixed widths.
//
// The compound RTL x 2.0x family (EP-U31..U38) drives unbreakable chips, bidi /
// control / separator display names, shared notices, the raw resolved URI and
// the session-limit row through the operator cards under RTL AND a 2.0x scaler
// — but NONE drives the "Primary" badge through that setting. A plausible
// one-sided "make the badge screen-reader friendlier at RTL / large fonts" edit
// (append a separate ', Primary' to ONE card's merged header label, or split the
// badge into its own Semantics node) could desync the announcement on one
// operator surface while every LTR / 1.0x / single-axis suite stayed GREEN.
// This guard closes that seam.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol dependency is imported, and production TLS is untouched.

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

/// Pumps the real `KvmView` (capability card + every per-console card from the
/// same manager projection) under the requested direction / text scale. Only
/// upstream data providers are overridden — the real cards and the real
/// Primary-badge wiring run. A tall viewport keeps both lazy console cards built
/// even at a 2.0x scaler.
Future<void> _pumpKvmView(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 5000);
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
      child: MaterialApp(
        home: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData.fromView(tester.view)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: const KvmView(systemId: 'bmc1'),
          ),
        ),
      ),
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
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData.fromView(tester.view)
                .copyWith(textScaler: const TextScaler.linear(2.0)),
            child: KvmConsoleViewerPage(console: console),
          ),
        ),
      ),
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
  group(
      'EP-U39 Primary-badge single merged a11y agreement under RTL x 2.0x '
      '(#009/#021)', () {
    test('one manager yields one deterministic secure-graphical winner', () {
      final List<KvmConsole> consoles = _consoles();
      final KvmConsole? primary = KvmService.pickPrimary(consoles);

      expect(consoles, hasLength(2));
      expect(primary, isNotNull);
      expect(primary!.type, KvmConsoleType.graphical,
          reason: 'the secure graphical is the deterministic Primary');
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'exactly one Primary badge on the winner, single merged node, '
        'no split announcement or duplicate under RTL 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpKvmView(tester, width: width, rtl: true, scale: 2.0);

          // One merged header node per console — a split / reworded header
          // announces a different label and finds nothing here.
          expect(find.bySemanticsLabel('Graphical Console, enabled'),
              findsOneWidget,
              reason: 'winner header is ONE byte-exact merged node at '
                  '${px}px RTL 2.0x');
          expect(
              find.bySemanticsLabel('Serial Console, enabled'), findsOneWidget,
              reason: 'peer header is ONE byte-exact merged node at '
                  '${px}px RTL 2.0x');

          // Exactly ONE visible "Primary" marker across the whole view.
          expect(find.text('Primary'), findsOneWidget,
              reason: 'exactly one visible Primary marker at ${px}px RTL 2.0x');

          // It sits on the pickPrimary winner's card and NOWHERE on the peer.
          final Finder winnerCard =
              _cardWithHeader('Graphical Console, enabled');
          final Finder peerCard = _cardWithHeader('Serial Console, enabled');
          expect(
              find.descendant(of: winnerCard, matching: find.text('Primary')),
              findsOneWidget,
              reason: 'the secure graphical card carries the badge at ${px}px');
          expect(find.descendant(of: peerCard, matching: find.text('Primary')),
              findsNothing,
              reason: 'the non-Primary card must have no badge at ${px}px');

          // The badge is INSIDE the winner's single merged header node, and no
          // separate / screen-reader-only Semantics node announces "Primary".
          expect(
            find.descendant(
              of: find.bySemanticsLabel('Graphical Console, enabled'),
              matching: find.text('Primary'),
            ),
            findsOneWidget,
            reason: 'badge lives in the single merged header at ${px}px',
          );
          expect(
            find.bySemanticsLabel(RegExp(r'Primary')),
            findsNothing,
            reason: 'no split or screen-reader-only Primary announcement at '
                '${px}px RTL 2.0x',
          );

          // No competing marker on the capability card.
          expect(
            find.descendant(
              of: find.byType(KvmCapabilityCard),
              matching: find.text('Primary'),
            ),
            findsNothing,
            reason: 'capability card must not duplicate the marker at ${px}px',
          );

          expect(tester.takeException(), isNull,
              reason: 'reflowing header must not overflow at ${px}px RTL 2.0x');
        },
      );
    }

    testWidgets('viewer does not duplicate the Primary marker under RTL 2.0x',
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

    testWidgets('LTR / 1.0x control keeps the single merged Primary badge',
        (WidgetTester tester) async {
      await _pumpKvmView(tester, width: 320, rtl: false, scale: 1.0);

      expect(
          find.bySemanticsLabel('Graphical Console, enabled'), findsOneWidget);
      expect(find.bySemanticsLabel('Serial Console, enabled'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(
        find.descendant(
          of: find.bySemanticsLabel('Graphical Console, enabled'),
          matching: find.text('Primary'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'Primary')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
