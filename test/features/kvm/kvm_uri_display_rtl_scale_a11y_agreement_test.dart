// EP-U37 / #009 / #021: RTL x 2.0x COMPOUND a11y agreement for the RAW resolved
// / connect URI display surface across both KVM operator cards, with the viewer
// pinned fail-closed as a control.
//
// AUDIT FIRST (see queues/ui.md EP-U37): the resolved/connect URI row is already
// pinned byte-exact under LTR in several suites (`kvm_card_extreme_content...`
// with a control-safe URI, `kvm_three_surface_launch_target...`, `kvm_rtl_...`
// with a clean URI at 1.0x). Every RTL-capable widget suite either uses a CLEAN
// control-safe URI (`kvm_rtl_rendering_agreement_test.dart`: kUri =
// 'https://bmc.example/kvm') or drives a different data family (display name,
// connect-type chip, shared notice) through RTL x 2.0x. NONE drives a BMC-
// supplied URI carrying bidi FORMAT marks (Cf) + a C0 control (Cc TAB) + a
// Unicode LINE SEPARATOR (Zl) through BOTH cards' merged URI announcement nodes
// under RTL AND a 2.0x text scaler — the compound setting where bidi marks
// change visual order and the separator changes line layout, so a plausible
// one-sided "normalise the controls in THIS card's URI announcement so the
// screen reader doesn't read them" edit could desync one card while every
// clean-URI / LTR / 1.0x suite stayed GREEN. This guard closes that seam.
//
// The two cards intentionally show the RAW (trim-only) `launchUri`; the viewer
// intentionally shows the fail-closed `launchPlan.targetUri`. This guard pins
// both facts: cards byte-exact + single-merged under the compound setting, and
// the viewer never surfacing raw control/bidi bytes.
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

/// An HTTPS-looking endpoint carrying bidi LRM/RLM (Cf, U+200E/U+200F), a C0
/// TAB (Cc, U+0009) and a Unicode LINE SEPARATOR (Zl, U+2028) in the middle.
/// `String.trim()` leaves all of them intact, so `launchUri` displays them raw
/// on both cards while the shared fail-closed launcher strips them.
const String kHostileUri =
    'https://bmc.example/kvm\u200E\u200F\u0009\u2028session=1';

/// A clean control-safe HTTPS control.
const String kCleanUri = 'https://bmc.example/kvm';

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

KvmConsole _console(String uri) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['KVMIP'],
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

KvmCapability _capability(String uri) => KvmCapability(
      managerId: 'BMC',
      supported: true,
      connectTypes: const <String>['KVMIP', 'HTML5'],
      serviceEnabled: true,
      uri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

Finder _mergedUriNode(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == label,
    );

Finder _selectableUri(String data) => find.byWidgetPredicate(
      (Widget widget) => widget is SelectableText && widget.data == data,
    );

/// Asserts exactly one merged `excludeSemantics` node announces `$prefix$raw`
/// AND the single visible `SelectableText(raw)` sits inside that same node
/// (visible == announced), byte-exact including every control/bidi code unit.
void _expectMergedUri(WidgetTester tester, String prefix, String raw) {
  final String label = '$prefix$raw';
  final Finder merged = _mergedUriNode(label);
  expect(merged, findsOneWidget,
      reason: 'exactly one merged URI node "$prefix"');
  // Scope to this card's merged node: when a real KvmView is pumped both the
  // console card and the capability card render the same raw URI, so a global
  // SelectableText search would match both. Each merged node must carry exactly
  // one visible SelectableText with the byte-exact raw value (visible==announced).
  expect(
    find.descendant(of: merged, matching: _selectableUri(raw)),
    findsOneWidget,
    reason: 'the visible raw URI must sit inside its merged a11y node',
  );
}

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

void _size(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps a real [KvmView] so the per-console card renders inside the gated list.
Future<void> _pumpConsoleCard(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
  required String uri,
}) async {
  _size(tester, width);
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[_console(uri)]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(
            <KvmCapability>[_capability(uri)],
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
  required String uri,
}) async {
  _size(tester, width);
  await tester.pumpWidget(
    MaterialApp(
      home: _directionScale(
        tester,
        KvmCapabilityCard(capability: _capability(uri)),
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
  required String uri,
}) async {
  _size(tester, width);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: _directionScale(
          tester,
          KvmConsoleViewerPage(console: _console(uri)),
          rtl: rtl,
          scale: scale,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EP-U37 raw-URI display a11y agreement under RTL x 2.0x (#009/#021)',
      () {
    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'console card raw Connect URI stays byte-exact + single-merged '
          'under RTL 2.0x at ${width.toInt()} px', (WidgetTester tester) async {
        await _pumpConsoleCard(
          tester,
          width: width,
          rtl: true,
          scale: 2.0,
          uri: kHostileUri,
        );
        _expectMergedUri(tester, 'Connect URI: ', kHostileUri);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'capability card raw Resolved URI stays byte-exact + single-merged '
          'under RTL 2.0x at ${width.toInt()} px', (WidgetTester tester) async {
        await _pumpCapabilityCard(
          tester,
          width: width,
          rtl: true,
          scale: 2.0,
          uri: kHostileUri,
        );
        _expectMergedUri(tester, 'Resolved URI: ', kHostileUri);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'viewer never surfaces raw control/bidi URI bytes under RTL 2.0x '
          'at ${width.toInt()} px', (WidgetTester tester) async {
        await _pumpViewer(
          tester,
          width: width,
          rtl: true,
          scale: 2.0,
          uri: kHostileUri,
        );
        // The viewer is the launch surface: it uses the fail-closed target,
        // never the raw control/bidi-bearing endpoint the cards display.
        expect(_selectableUri(kHostileUri), findsNothing);
        expect(_mergedUriNode('Console URI: $kHostileUri'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'both cards display byte-identical raw URI bytes under '
        'RTL 2.0x', (WidgetTester tester) async {
      expect(_console(kHostileUri).launchUri!.codeUnits,
          _capability(kHostileUri).launchUri!.codeUnits,
          reason: 'both projections preserve the raw URI byte-for-byte');
      await _pumpConsoleCard(
        tester,
        width: 800,
        rtl: true,
        scale: 2.0,
        uri: kHostileUri,
      );
      _expectMergedUri(tester, 'Connect URI: ', kHostileUri);

      await _pumpCapabilityCard(
        tester,
        width: 800,
        rtl: true,
        scale: 2.0,
        uri: kHostileUri,
      );
      _expectMergedUri(tester, 'Resolved URI: ', kHostileUri);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LTR / 1.0x controls keep the same byte-exact merged URI nodes',
        (WidgetTester tester) async {
      await _pumpConsoleCard(
        tester,
        width: 320,
        rtl: false,
        scale: 1.0,
        uri: kHostileUri,
      );
      _expectMergedUri(tester, 'Connect URI: ', kHostileUri);

      await _pumpCapabilityCard(
        tester,
        width: 320,
        rtl: false,
        scale: 1.0,
        uri: kHostileUri,
      );
      _expectMergedUri(tester, 'Resolved URI: ', kHostileUri);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a clean HTTPS control stays byte-exact + single-merged on '
        'both cards under RTL 2.0x', (WidgetTester tester) async {
      await _pumpConsoleCard(
        tester,
        width: 320,
        rtl: true,
        scale: 2.0,
        uri: kCleanUri,
      );
      _expectMergedUri(tester, 'Connect URI: ', kCleanUri);

      await _pumpCapabilityCard(
        tester,
        width: 320,
        rtl: true,
        scale: 2.0,
        uri: kCleanUri,
      );
      _expectMergedUri(tester, 'Resolved URI: ', kCleanUri);
      expect(tester.takeException(), isNull);
    });
  });
}
