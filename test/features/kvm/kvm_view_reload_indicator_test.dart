// UI-2 / #009 / #021: in-list reload-indicator guard for `KvmView`.
//
// `KvmView.build` has TWO "Loading KVM consoles" rendering paths:
//   * the early empty-list return (loading && consoles.isEmpty), already pinned
//     by `kvm_widget_test.dart` ("loading state announces one merged ... node");
//   * the IN-LIST branch inside the populated `ListView` (loading with consoles
//     already displayed), which replaces the console cards with one merged
//     `excludeSemantics` node wrapping the spinner so sighted users keep a
//     spinner and screen readers get one self-describing announcement.
//
// Only the first path had any test. The in-list branch was execution-uncovered
// AND assertion-uncovered: a one-token regression (changing its `label:` or
// flipping `excludeSemantics` to false) stayed fully GREEN. This suite pins the
// in-list node, its merged structure (visible spinner inside the announced
// node), its gating on the loading flag, and no-overflow at 320/800/1300 px.
//
// Display-only, dependency-free, TLS-safe: no URL opened, no WebView/protocol
// import, no production TLS change.

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

/// A [KvmController] whose [load] is a no-op so the seeded state stays put
/// (mirrors the established widget-test stub).
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

KvmConsole _console() => const KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['KVMIP'],
      serviceEnabled: true,
      connectUri: 'https://bmc.example/kvm',
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

/// The single merged `excludeSemantics` node announcing the in-list spinner.
Finder _mergedLoadingNode() => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == 'Loading KVM consoles',
    );

Future<void> _pumpView(
  WidgetTester tester, {
  required bool loading,
  double? width,
}) async {
  if (width != null) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final KvmController controller = _StubController()
    ..state = KvmUiState(loading: loading, consoles: <KvmConsole>[_console()]);
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
    testWidgets(
        'in-list reload renders one merged loading node at '
        '${width.round()}px', (WidgetTester tester) async {
      await _pumpView(tester, loading: true, width: width);

      // The populated-ListView branch renders exactly one 'Loading KVM
      // consoles' announcement, structurally merged, wrapping the spinner.
      expect(find.bySemanticsLabel('Loading KVM consoles'), findsOneWidget);
      expect(_mergedLoadingNode(), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: _mergedLoadingNode(),
        ),
        findsOneWidget,
        reason: 'the visible spinner must sit inside its merged a11y node '
            '(visible == announced)',
      );

      // The header is still present — proves we are in the in-list branch and
      // not the early empty-list loading return (which has no header).
      expect(
        find.bySemanticsLabel('Remote KVM / Consoles, consoles exposed by the '
            'system managers'),
        findsOneWidget,
        reason: 'the console list (not the empty early-return) is rendered',
      );

      expect(tester.takeException(), isNull,
          reason: 'no overflow at ${width}px');
    });
  }

  testWidgets('loading=false renders the console card, not a loading node',
      (WidgetTester tester) async {
    await _pumpView(tester, loading: false, width: 800);

    // Same populated console list, idle → the in-list indicator is gone and
    // the console card is shown instead.
    expect(find.bySemanticsLabel('Loading KVM consoles'), findsNothing);
    expect(_mergedLoadingNode(), findsNothing);
    expect(find.bySemanticsLabel('Manager: BMC'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow at 800px');
  });
}
