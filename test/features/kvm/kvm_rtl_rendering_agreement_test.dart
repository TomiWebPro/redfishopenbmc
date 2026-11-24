// EP-U28 (issues #009 / #021): RTL-locale rendering agreement across the three
// operator-visible KVM surfaces — the per-console card, the per-manager
// capability card and the full-screen viewer.
//
// AUDIT FIRST: all three surfaces build their visible text AND their merged
// `excludeSemantics` labels from the same byte-exact model strings in logical
// order, and the chips/URI rows are laid out with `Wrap` / `Column`, so Flutter
// resolves visual direction itself — there is NO live divergence today and no
// production change is needed. The genuine UNGUARDED seam is that NO existing
// test renders any of these surfaces under `TextDirection.rtl`: every widget
// suite pumps LTR only. A plausible one-sided "handle RTL manually" edit (e.g.
// reversing a chip list under RTL, or splitting a merged node into a
// screen-reader-only copy) would flip logical chip order or duplicate an
// announcement on one surface while every LTR-only suite stayed GREEN — the
// exact #009 cross-surface divergence class. This guard pins that the merged
// label set, the rendered chip sequence and the copied URI stay byte-identical
// between LTR and RTL at 320 / 800 / 1300 px on all three surfaces.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol plugin is imported, and production TLS is untouched (issues #009/#021).
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

/// Distinct connect-type chips plus a secure-HTTPS graphical (the deterministic
/// pickPrimary winner, which carries the "Primary" badge) and an SSH serial peer.
const List<String> kTypes = <String>['KVMIP', 'HTML5', 'SSH'];
const String kUri = 'https://bmc.example/kvm';

Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5', 'SSH'],
        'ConnectUri': kUri,
        'MaxConcurrentSessions': 4,
      },
      'SerialConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectUri': 'ssh://bmc.example/serial',
      },
    };

List<KvmConsole> _consoles() =>
    KvmConsole.fromManager(_managerBody(), managerId: 'BMC');

/// Pumps the real `KvmView` (capability card + every per-console card) under an
/// explicit [direction] and viewport width. Only upstream providers are
/// overridden; the real cards and Primary wiring run.
Future<void> _pumpKvmView(
  WidgetTester tester, {
  required double width,
  required TextDirection direction,
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
      child: MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: const KvmView(systemId: 'bmc1'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required KvmConsole console,
  required TextDirection direction,
}) async {
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
          textDirection: direction,
          child: KvmConsoleViewerPage(console: console),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _capabilityCard() => find.byType(KvmCapabilityCard);

Finder _consoleCard() => find.ancestor(
      of: find.bySemanticsLabel('Graphical Console, enabled'),
      matching: find.byType(Card),
    );

/// The operator-visible connect-type chip values, in render order.
List<String> _chipLabels(WidgetTester tester, Finder card) {
  final Finder node = find.descendant(
    of: card,
    matching:
        find.bySemanticsLabel(RegExp(r'^(Supported )?[Cc]onnection types: ')),
  );
  expect(node, findsOneWidget, reason: 'one merged connect-type node per card');
  final Finder chips = find.descendant(of: node, matching: find.byType(Chip));
  return tester
      .widgetList<Chip>(chips)
      .map((Chip c) => (c.label as Text).data!)
      .toList(growable: false);
}

/// Every merged `excludeSemantics` announcement in the widget tree, sorted.
/// Comparing this set between LTR and RTL pins that no node is split,
/// duplicated or reworded by visual direction (visible text == announced label).
List<String> _mergedLabels(WidgetTester tester) {
  final List<String> labels = tester
      .widgetList<Semantics>(find.byType(Semantics))
      .where((Semantics s) =>
          s.excludeSemantics && (s.properties.label?.isNotEmpty ?? false))
      .map((Semantics s) => s.properties.label!)
      .toList()
    ..sort();
  return labels;
}

void main() {
  group('EP-U28 RTL-locale rendering agreement (#009/#021)', () {
    test('fixture yields deterministic chips, Primary and control-safe URI',
        () {
      final List<KvmConsole> consoles = _consoles();
      expect(consoles, hasLength(2));
      final KvmConsole? primary = KvmService.pickPrimary(consoles);
      expect(primary, isNotNull);
      expect(primary!.type, KvmConsoleType.graphical);
      expect(primary.connectTypesSupported, kTypes);
      expect(primary.launchPlan.targetUri, kUri);
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards keep identical chips, badges and merged labels under '
        'LTR and RTL at ${px}px, no overflow',
        (WidgetTester tester) async {
          // LTR snapshot.
          await _pumpKvmView(tester,
              width: width, direction: TextDirection.ltr);
          final List<String> ltrCapabilityChips =
              _chipLabels(tester, _capabilityCard());
          final List<String> ltrConsoleChips =
              _chipLabels(tester, _consoleCard());
          final List<String> ltrLabels = _mergedLabels(tester);
          expect(tester.takeException(), isNull, reason: 'LTR overflow $px');

          // RTL snapshot of the SAME manager.
          await _pumpKvmView(tester,
              width: width, direction: TextDirection.rtl);
          final List<String> rtlCapabilityChips =
              _chipLabels(tester, _capabilityCard());
          final List<String> rtlConsoleChips =
              _chipLabels(tester, _consoleCard());
          final List<String> rtlLabels = _mergedLabels(tester);
          expect(tester.takeException(), isNull, reason: 'RTL overflow $px');

          // Logical chip order + full set preserved across directions on both
          // cards — no RTL-induced reversal, chip loss or duplicate.
          expect(rtlCapabilityChips, kTypes, reason: 'capability chips $px');
          expect(rtlConsoleChips, kTypes, reason: 'console chips $px');
          expect(rtlCapabilityChips, ltrCapabilityChips,
              reason: 'capability chip order must be direction-independent');
          expect(rtlConsoleChips, ltrConsoleChips,
              reason: 'console chip order must be direction-independent');

          // The merged announcement set (which embeds the chips, the Primary
          // badge and the resolved/copied URI) is byte-identical across LTR and
          // RTL — no split / screen-reader-only node and no reworded label.
          expect(rtlLabels, ltrLabels,
              reason: 'merged label set must be direction-independent at $px');

          // Exactly one visible instance of each chip under RTL (no hidden
          // screen-reader-only duplicate), and one Primary marker.
          for (final String type in kTypes) {
            expect(find.text(type), findsNWidgets(2),
                reason: 'one visible "$type" chip per card under RTL at $px');
          }
          expect(find.text('Primary'), findsOneWidget,
              reason: 'exactly one Primary marker under RTL at $px');
          expect(
            find.bySemanticsLabel('Resolved URI: $kUri'),
            findsOneWidget,
            reason: 'capability copied URI identical under RTL at $px',
          );
          expect(
            find.bySemanticsLabel('Connection types: ${kTypes.join(', ')}'),
            findsOneWidget,
            reason: 'console merged chip label identical under RTL at $px',
          );
        },
      );
    }

    testWidgets(
      'viewer keeps the same URI / copy / status announcement under LTR and RTL',
      (WidgetTester tester) async {
        final KvmConsole primary = KvmService.pickPrimary(_consoles())!;

        await _pumpViewer(tester,
            console: primary, direction: TextDirection.ltr);
        final List<String> ltrLabels = _mergedLabels(tester);
        expect(tester.takeException(), isNull, reason: 'viewer LTR overflow');

        await _pumpViewer(tester,
            console: primary, direction: TextDirection.rtl);
        final List<String> rtlLabels = _mergedLabels(tester);
        expect(tester.takeException(), isNull, reason: 'viewer RTL overflow');

        expect(rtlLabels, ltrLabels,
            reason: 'viewer merged label set must be direction-independent');
        expect(find.bySemanticsLabel('Console URI: $kUri'), findsOneWidget,
            reason: 'viewer copies the same control-safe URI under RTL');
        expect(find.bySemanticsLabel('Copy console URI'), findsOneWidget,
            reason: 'copy affordance survives RTL');
        expect(find.text('Copy console URI'), findsOneWidget,
            reason: 'copy affordance visible exactly once under RTL');
      },
    );
  });
}
