// EP-U40 (issue #009/#021) — RTL x 2.0x COMPOUND a11y agreement for the
// NON-POPULATED states of `KvmView`.
//
// AUDIT FIRST (queues/ui.md EP-U40): the five early-return / gate states of
// KvmView.build each emit ONE merged `excludeSemantics` node with the visible
// payload inside it (UI-2 pattern):
//   * handle == null            -> 'System not found'
//   * features == null          -> 'Loading KVM'           (discovery pending)
//   * hard load failure         -> 'Unable to load KVM consoles. <error>'
//   * initial load in flight    -> 'Loading KVM consoles'
//   * successful load, 0 consoles-> 'No consoles found.'
// The LTR / 1.0x state truth table is pinned by `kvm_view_state_agreement_test.dart`
// (populated ListView half) and `kvm_widget_test.dart`, and the compound RTL
// x 2.0x family (EP-U31..U39) drove display names, chips, notices, the raw URI,
// the session-limit row and the Primary badge — but NEVER the non-populated
// states. Nothing pumped these five states under `Directionality.rtl` with a
// 2.0x `TextScaler` at 320 / 800 / 1300 px, the compound setting where a
// plausible one-sided "RTL needs shorter wording" or "a 2.0x spinner needs its
// own announcement" edit could split a merged node or duplicate an
// announcement on ONE state while every LTR / 1.0x / single-axis suite stayed
// GREEN. This guard closes that seam.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol dependency imported, production TLS untouched, no behaviour
// decision folded in.

library;

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

/// The five non-populated states of `KvmView.build`, each with a single merged
/// announcement and a visible payload that must sit inside that same node.
enum _State {
  systemNotFound('System not found'),
  discoveryPending('Loading KVM'),
  hardError('Unable to load KVM consoles. HTTP 503: backend unavailable'),
  initialLoading('Loading KVM consoles'),
  empty('No consoles found.');

  const _State(this.label);

  /// The exact merged `excludeSemantics` announcement for this state.
  final String label;
}

const String _kError = 'HTTP 503: backend unavailable';
const String _kHeaderLabel =
    'Remote KVM / Consoles, consoles exposed by the system managers';

SystemHandle _handle() => const SystemHandle(
      profile: ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: true),
    );

/// A handle known to the manager but whose capabilities are not resolved yet.
SystemHandle _pendingHandle() => const SystemHandle(
      profile: ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: null,
    );

KvmConsole _console(String managerId) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: managerId,
      connectTypesSupported: const <String>['KVMIP'],
      serviceEnabled: true,
      connectUri: 'https://bmc.example/kvm',
      sourceManagerUri: '/redfish/v1/Managers/$managerId',
    );

/// The single merged `excludeSemantics` node with the given [label].
Finder _mergedNode(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == label,
    );

/// Applies the compound direction + font scale to the surface under test.
/// Placed INSIDE `MaterialApp.home` so the scale reaches [child] (a MediaQuery
/// above MaterialApp would be replaced by the app's own view-derived one).
Widget _directionScale(
  WidgetTester tester,
  Widget child, {
  required bool rtl,
  required double scale,
}) =>
    Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromView(tester.view)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    );

/// Pumps one non-populated [state] (or the populated control) with the compound
/// direction/scale applied at [width]. Only the upstream providers are
/// overridden; the real `KvmView.build` decides which state to render.
Future<void> _pumpView(
  WidgetTester tester, {
  required _State? state,
  required double width,
  required bool rtl,
  required double scale,
}) async {
  // A 2.0x scaler makes the error state (icon + two text lines + Retry button)
  // materially taller; give ample height so the check is about node structure
  // and horizontal overflow, not a viewport-height constraint at 320 px.
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final KvmUiState uiState;
  SystemHandle? handle;
  List<KvmConsole> consoles = <KvmConsole>[];
  switch (state) {
    case _State.systemNotFound:
      handle = null;
      uiState = const KvmUiState(consoles: <KvmConsole>[]);
      break;
    case _State.discoveryPending:
      handle = _pendingHandle();
      uiState = const KvmUiState(consoles: <KvmConsole>[]);
      break;
    case _State.hardError:
      handle = _handle();
      uiState = const KvmUiState(consoles: <KvmConsole>[], error: _kError);
      break;
    case _State.initialLoading:
      handle = _handle();
      uiState = const KvmUiState(consoles: <KvmConsole>[], loading: true);
      break;
    case _State.empty:
      handle = _handle();
      uiState = const KvmUiState(consoles: <KvmConsole>[]);
      break;
    case null: // populated control
      handle = _handle();
      consoles = <KvmConsole>[_console('BMC')];
      uiState = KvmUiState(consoles: consoles);
      break;
  }

  final KvmController controller = _StubController()..state = uiState;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(handle),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(
            <KvmCapability>[],
          ),
        ),
      ],
      child: MaterialApp(
        home: _directionScale(
          tester,
          const KvmView(systemId: 'bmc1'),
          rtl: rtl,
          scale: scale,
        ),
      ),
    ),
  );
  // `pump` (not `pumpAndSettle`): the loading states animate a spinner forever.
  await tester.pump();
}

/// Asserts the state renders exactly ONE merged node announcing [label], with
/// its visible payload inside that same node, no duplicate screen-reader-only
/// node, no populated-view header (no false "console ready" claim), no other
/// state's announcement and no overflow.
void _expectOneMergedState(
  WidgetTester tester,
  _State state, {
  required Finder visiblePayload,
}) {
  expect(_mergedNode(state.label), findsOneWidget,
      reason: 'exactly one merged a11y node for "${state.label}"');
  expect(
    find.ancestor(
      of: visiblePayload,
      matching: _mergedNode(state.label),
    ),
    findsOneWidget,
    reason: 'visible payload must sit inside the merged node for ${state.name}',
  );
  // The merged announcement appears once in the semantics tree: no second,
  // screen-reader-only node duplicating the same state.
  expect(
    tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((Semantics node) =>
            node.container &&
            node.excludeSemantics &&
            node.properties.label == state.label)
        .length,
    1,
    reason: 'no duplicate / screen-reader-only node for ${state.name}',
  );
  // A non-populated state must never claim the populated view is ready.
  expect(find.bySemanticsLabel(_kHeaderLabel), findsNothing,
      reason: 'no populated-view header in ${state.name}');
  for (final _State other in _State.values) {
    if (other == state) continue;
    expect(find.bySemanticsLabel(other.label), findsNothing,
        reason: 'no ${other.name} announcement leaking into ${state.name}');
  }
  expect(tester.takeException(), isNull,
      reason: 'no overflow in ${state.name}');
}

/// The visible payload finder for a state's merged node.
Finder _payloadFor(_State state) => switch (state) {
      // Text-bearing states: the visible Text is byte-exact with the label's
      // human wording (the error label carries the message as a suffix).
      _State.systemNotFound => find.text('System not found'),
      _State.hardError => find.text('Unable to load KVM consoles'),
      _State.empty => find.text('No consoles found.'),
      // Spinner states: the visible CircularProgressIndicator is the payload.
      _State.discoveryPending ||
      _State.initialLoading =>
        find.byType(CircularProgressIndicator),
    };

void main() {
  for (final double width in <double>[320, 800, 1300]) {
    final String px = '${width.round()}px';

    for (final _State state in _State.values) {
      testWidgets(
          'RTL x 2.0x ${state.name} ($px): one merged node, '
          'visible==announced, no duplicate/overflow',
          (WidgetTester tester) async {
        await _pumpView(
          tester,
          state: state,
          width: width,
          rtl: true,
          scale: 2.0,
        );
        _expectOneMergedState(tester, state,
            visiblePayload: _payloadFor(state));

        // The hard error keeps its Retry as a SEPARATE node, outside the merged
        // announcement (established UI-2 pattern, unchanged at RTL/2.0x).
        if (state == _State.hardError) {
          expect(find.bySemanticsLabel('Retry'), findsOneWidget);
          expect(
            find.ancestor(
              of: find.bySemanticsLabel('Retry'),
              matching: _mergedNode(state.label),
            ),
            findsNothing,
            reason: 'Retry stays a separate node, not inside the error node',
          );
        }
      });
    }
  }

  // LTR / 1.0x control: the same five states still render one merged node in
  // the baseline direction/scale (guards against an RTL-only implementation).
  for (final _State state in _State.values) {
    testWidgets('LTR x 1.0x control ${state.name}: one merged node',
        (WidgetTester tester) async {
      await _pumpView(
        tester,
        state: state,
        width: 800,
        rtl: false,
        scale: 1.0,
      );
      _expectOneMergedState(tester, state, visiblePayload: _payloadFor(state));
    });
  }

  // Populated control: at RTL/2.0x the populated view STILL shows its header
  // and cards, and none of the non-populated announcements leak in — proving
  // the guard distinguishes a ready console list from every non-ready state.
  testWidgets('RTL x 2.0x populated control: header + cards, no state node',
      (WidgetTester tester) async {
    await _pumpView(
      tester,
      state: null,
      width: 320,
      rtl: true,
      scale: 2.0,
    );
    expect(find.bySemanticsLabel(_kHeaderLabel), findsOneWidget);
    expect(find.bySemanticsLabel('Manager: BMC'), findsOneWidget);
    for (final _State state in _State.values) {
      expect(find.bySemanticsLabel(state.label), findsNothing,
          reason: 'no ${state.name} announcement in the populated control');
    }
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });
}
