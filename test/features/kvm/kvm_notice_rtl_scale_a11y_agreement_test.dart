// EP-U36 / #009 / #021: RTL x 2.0x COMPOUND a11y agreement for the two shared
// KVM notices (`kvmSessionPersistenceNotice`, `kvmDisabledOnBmcNotice`) across
// both operator cards and the per-console viewer.
//
// AUDIT FIRST (see queues/ui.md EP-U36): EP-U7 already pins both notices as
// ONE merged `excludeSemantics` node with visible text == announced label on
// the three surfaces, at 320/800/1300 px — but only under LTR at 1.0x. EP-U21
// exercises 2.0x with LONG NAMES but LTR only, and EP-U28/EP-U31/EP-U32..U35
// exercise RTL with connect-type chips / display names, never the two shared
// notices. Nothing drove the shared notices through RTL x 2.0x, the compound
// setting where a plausible one-sided "RTL needs its own notice wording"
// edit on ONE surface (splitting its merged node or announcing a shortened
// label) could desync a screen reader while every single-axis suite stayed
// GREEN. This guard closes that seam.
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
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op so the gated view can be seeded
/// without touching the network (mirrors the established widget-test stub).
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

KvmCapability _capability(String managerId, {required bool enabled}) =>
    KvmCapability(
      managerId: managerId,
      supported: true,
      connectTypes: const <String>['KVMIP', 'HTML5'],
      serviceEnabled: enabled,
      uri: 'https://bmc.example/kvm',
      sourceManagerUri: '/redfish/v1/Managers/$managerId',
    );

/// The single merged `excludeSemantics` node whose label is exactly [notice].
Finder _mergedNotice(String notice) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == notice,
    );

/// Asserts one merged node announces exactly [notice] AND the single visible
/// `Text` with that wording sits inside that same node (visible == announced).
void _expectOneMergedNotice(WidgetTester tester, String notice) {
  expect(find.text(notice), findsOneWidget,
      reason: 'exactly one visible "$notice"');
  expect(_mergedNotice(notice), findsOneWidget,
      reason: 'exactly one merged a11y node for "$notice"');
  expect(
    find.ancestor(
      of: find.text(notice),
      matching: _mergedNotice(notice),
    ),
    findsOneWidget,
    reason: 'visible "$notice" must be inside its merged a11y node',
  );
}

/// Applies the compound direction + font scale above the surface under test.
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

Future<void> _pumpView(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  // A 2.0x text scaler makes each card materially taller; give the view ample
  // height so the compound check is about horizontal / node structure, not a
  // viewport-height constraint at 320 px.
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[_console('A')]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(
            <KvmCapability>[_capability('A', enabled: false)],
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
  await tester.pumpAndSettle();
}

Future<void> _pumpCapabilityCard(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  // A 2.0x text scaler makes each card materially taller; give the view ample
  // height so the compound check is about horizontal / node structure, not a
  // viewport-height constraint at 320 px.
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: _directionScale(
        tester,
        KvmCapabilityCard(capability: _capability('off', enabled: false)),
        rtl: rtl,
        scale: scale,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  // A 2.0x text scaler makes each card materially taller; give the view ample
  // height so the compound check is about horizontal / node structure, not a
  // viewport-height constraint at 320 px.
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: _directionScale(
          tester,
          KvmConsoleViewerPage(console: _console('secure')),
          rtl: rtl,
          scale: scale,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EP-U36 shared-notice a11y agreement under RTL x 2.0x (#009/#021)', () {
    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'gated list keeps session + disabled notices byte-exact and '
          'single-merged under RTL 2.0x at ${width.toInt()} px',
          (WidgetTester tester) async {
        await _pumpView(tester, width: width, rtl: true, scale: 2.0);
        _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
        _expectOneMergedNotice(tester, kvmDisabledOnBmcNotice);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'capability card disabled notice stays byte-exact and single-merged '
          'under RTL 2.0x at ${width.toInt()} px', (WidgetTester tester) async {
        await _pumpCapabilityCard(tester, width: width, rtl: true, scale: 2.0);
        _expectOneMergedNotice(tester, kvmDisabledOnBmcNotice);
        // Session guidance does not belong on the capability card.
        expect(find.text(kvmSessionPersistenceNotice), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'viewer session notices stay byte-exact and single-merged under '
          'RTL 2.0x at ${width.toInt()} px', (WidgetTester tester) async {
        await _pumpViewer(tester, width: width, rtl: true, scale: 2.0);
        _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
        _expectOneMergedNotice(tester, kvmSessionActiveNotice);
        // Disabled guidance does not belong on the viewer.
        expect(find.text(kvmDisabledOnBmcNotice), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('LTR / 1.0x controls keep the same byte-exact merged notices',
        (WidgetTester tester) async {
      await _pumpView(tester, width: 320, rtl: false, scale: 1.0);
      _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
      _expectOneMergedNotice(tester, kvmDisabledOnBmcNotice);

      await _pumpCapabilityCard(tester, width: 320, rtl: false, scale: 1.0);
      _expectOneMergedNotice(tester, kvmDisabledOnBmcNotice);

      await _pumpViewer(tester, width: 320, rtl: false, scale: 1.0);
      _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
      _expectOneMergedNotice(tester, kvmSessionActiveNotice);
      expect(tester.takeException(), isNull);
    });
  });
}
