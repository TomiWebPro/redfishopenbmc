// #009 / #021 — EP-U13: populated-ListView four-state agreement for `KvmView`.
//
// The populated-console-list branch of `KvmView.build` has two independent
// signals: an in-list stale-data warning (`ui.error != null`, landed in the
// stale-error run) and an in-list reload spinner (`ui.loading`, landed in the
// reload-indicator run). Each is pinned in isolation by its own suite, but no
// test pinned their AGREEMENT over the four (loading, error) states of that
// one branch — in particular the both-true case (an in-flight reload started
// while a stale failure banner is still honest) where an operator must see
// BOTH merged nodes exactly once, structurally distinct, with each visible
// payload inside its own announced node.
//
// This suite pins the full truth table at 320 / 800 / 1300 px:
//   error-only  -> one warning node + stale cards, no spinner;
//   loading-only-> one spinner node replacing the cards, no warning;
//   both-true   -> one warning node AND one spinner node (distinct widgets),
//                  no cards, no overflow at the narrowest width;
//   neither     -> plain cards, no signal nodes.
// All signal nodes are distinct from the early empty-list error/loading
// returns (the header proves the populated branch). Display-only,
// dependency-free, TLS-safe: no URL opened, no WebView / protocol import, no
// production TLS change.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op so the seeded state stays put.
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

KvmConsole _console(String managerId) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: managerId,
      connectTypesSupported: const <String>['KVMIP'],
      serviceEnabled: true,
      connectUri: 'https://bmc.example/kvm',
      sourceManagerUri: '/redfish/v1/Managers/$managerId',
    );

const String _kError = 'HTTP 503: backend unavailable';
const String _kWarningLabel = 'Unable to refresh KVM consoles. $_kError';
const String _kLoadingLabel = 'Loading KVM consoles';
const String _kEarlyErrorLabel = 'Unable to load KVM consoles. $_kError';
const String _kHeaderLabel =
    'Remote KVM / Consoles, consoles exposed by the system managers';

/// The single merged `excludeSemantics` node with the given [label].
Finder _mergedNode(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == label,
    );

/// Count of merged signal nodes (warning or spinner) currently rendered.
int _mergedSignalCount(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .where((Semantics node) =>
        node.container &&
        node.excludeSemantics &&
        (node.properties.label == _kWarningLabel ||
            node.properties.label == _kLoadingLabel))
    .length;

Future<void> _pumpView(
  WidgetTester tester, {
  required bool loading,
  required bool hasError,
  required double width,
  List<KvmConsole>? consoles,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final KvmController controller = _StubController()
    ..state = KvmUiState(
      loading: loading,
      consoles: consoles ?? <KvmConsole>[_console('BMC')],
      error: hasError ? _kError : null,
    );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(<KvmCapability>[]),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  // `pump` (not `pumpAndSettle`): the spinner animates forever.
  await tester.pump();
}

void main() {
  for (final double width in <double>[320, 800, 1300]) {
    final String px = '${width.round()}px';

    testWidgets('error-only ($px): warning + stale cards, no spinner',
        (WidgetTester tester) async {
      await _pumpView(tester, loading: false, hasError: true, width: width);

      expect(find.bySemanticsLabel(_kHeaderLabel), findsOneWidget,
          reason: 'populated branch, not the early return');
      expect(_mergedNode(_kWarningLabel), findsOneWidget);
      expect(find.bySemanticsLabel(_kWarningLabel), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(_kError),
          matching: _mergedNode(_kWarningLabel),
        ),
        findsOneWidget,
        reason: 'visible error text sits inside its merged a11y node',
      );
      expect(_mergedNode(_kLoadingLabel), findsNothing);
      expect(find.bySemanticsLabel(_kEarlyErrorLabel), findsNothing);
      expect(find.bySemanticsLabel('Manager: BMC'), findsOneWidget);
      expect(_mergedSignalCount(tester), 1);
      expect(tester.takeException(), isNull, reason: 'no overflow at $px');
    });

    testWidgets('loading-only ($px): spinner replaces cards, no warning',
        (WidgetTester tester) async {
      await _pumpView(tester, loading: true, hasError: false, width: width);

      expect(find.bySemanticsLabel(_kHeaderLabel), findsOneWidget);
      expect(_mergedNode(_kLoadingLabel), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: _mergedNode(_kLoadingLabel),
        ),
        findsOneWidget,
        reason: 'visible spinner sits inside its merged a11y node',
      );
      expect(_mergedNode(_kWarningLabel), findsNothing);
      expect(find.bySemanticsLabel('Manager: BMC'), findsNothing);
      expect(_mergedSignalCount(tester), 1);
      expect(tester.takeException(), isNull, reason: 'no overflow at $px');
    });

    testWidgets('both-true ($px): warning AND spinner, distinct, no cards',
        (WidgetTester tester) async {
      await _pumpView(tester, loading: true, hasError: true, width: width);

      expect(find.bySemanticsLabel(_kHeaderLabel), findsOneWidget);
      // Both honest signals survive a failed-reload-while-retrying: exactly
      // one of each, structurally distinct nodes, each payload inside its own
      // announced node.
      expect(_mergedNode(_kWarningLabel), findsOneWidget);
      expect(_mergedNode(_kLoadingLabel), findsOneWidget);
      final Finder warningFinder = _mergedNode(_kWarningLabel);
      final Finder loadingFinder = _mergedNode(_kLoadingLabel);
      expect(
        warningFinder.evaluate().single,
        isNot(loadingFinder.evaluate().single),
        reason: 'the warning and spinner must be distinct a11y nodes',
      );
      expect(
        find.ancestor(
          of: find.text(_kError),
          matching: warningFinder,
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: loadingFinder,
        ),
        findsOneWidget,
      );
      // The stale cards are replaced by the spinner during a reload, and the
      // early empty-list error node must not duplicate the in-list warning.
      expect(find.bySemanticsLabel('Manager: BMC'), findsNothing);
      expect(find.bySemanticsLabel(_kEarlyErrorLabel), findsNothing);
      expect(_mergedSignalCount(tester), 2);
      expect(tester.takeException(), isNull, reason: 'no overflow at $px');
    });

    testWidgets('neither ($px): plain cards, no signal nodes',
        (WidgetTester tester) async {
      await _pumpView(tester, loading: false, hasError: false, width: width);

      expect(find.bySemanticsLabel(_kHeaderLabel), findsOneWidget);
      expect(_mergedNode(_kWarningLabel), findsNothing);
      expect(_mergedNode(_kLoadingLabel), findsNothing);
      expect(find.bySemanticsLabel('Manager: BMC'), findsOneWidget);
      expect(_mergedSignalCount(tester), 0);
      expect(tester.takeException(), isNull, reason: 'no overflow at $px');
    });
  }

  testWidgets('both-true replaces EVERY stale card with one spinner',
      (WidgetTester tester) async {
    await _pumpView(
      tester,
      loading: true,
      hasError: true,
      width: 800,
      consoles: <KvmConsole>[_console('BMC1'), _console('BMC2')],
    );

    expect(_mergedNode(_kWarningLabel), findsOneWidget);
    expect(_mergedNode(_kLoadingLabel), findsOneWidget);
    expect(find.bySemanticsLabel('Manager: BMC1'), findsNothing);
    expect(find.bySemanticsLabel('Manager: BMC2'), findsNothing);
    expect(_mergedSignalCount(tester), 2);
    expect(tester.takeException(), isNull, reason: 'no overflow at 800px');
  });
}
