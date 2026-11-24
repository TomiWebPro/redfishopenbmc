// EP-U42 (issues #009 / #021): compound a11y agreement of the three MANAGER
// SOURCE fallback rows under RTL layout AND a 2.0x accessibility text scaler.
//
// AUDIT FIRST: each axis / surface is covered on its own but never in
// conjunction —
//   * EP-U6 pins each source row's visible text + merged `excludeSemantics`
//     label (byte-exact `safeManagerUri`) at LTR / 1.0x on all three surfaces;
//   * RM-15 / the manager-source model guards pin the control-safe fallback
//     derivation (bidi / confusable / hostile `@odata.id`) at the model layer;
//   * the RTL x 2.0x family (EP-U31..U41) pumps display names, chips, notices,
//     the raw URI, the session row, non-populated states, the Primary badge and
//     the copy affordances through both cards + the viewer — but NEVER the
//     no-URI manager-source fallback row.
// A plausible one-sided "a long source looks cramped under RTL at large fonts;
// shorten the announced source" edit on ONE surface could make its merged node
// announce a DIFFERENT source value than the byte-exact one still visible and
// still announced on the sibling surfaces, while every single-surface / single-
// axis suite stayed GREEN — the exact #009 cross-surface divergence class. This
// guard locks that, under the compound setting, all three real surfaces keep one
// merged `excludeSemantics` node per source row with visible text == announced
// label carrying the FULL byte-exact source, no split / duplicate / screen-
// reader-only node, and no overflow at 320 / 800 / 1300 px. An LTR / 1.0x
// control proves the compound setting changes nothing on an ordinary rendering.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol plugin is imported, and production TLS is untouched (#009/#021).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A long, control-free, hyphenated (visually wrapping) control-safe manager
/// source. All bytes are RFC 3986 unreserved or path separators, so both
/// `safeManagerUri` getters keep it byte-for-byte (verified in the fixture test)
/// and the hyphens give `Text`/`SelectableText` real wrap points at 320 px/2.0x.
const String kLongSource =
    '/redfish/v1/Managers/rack-07-node-14-management-controller-primary-'
    'bmc-console-source-channel';

const String kConsolePrefix =
    'No console connect URI available. Open externally: ';
const String kCapabilityPrefix = 'No console URI resolved. Source: ';
const String kViewerPrefix = 'No direct console URI. Manager source: ';

KvmConsole _console() => const KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      // No connectUri -> the console card's source fallback row renders.
      sourceManagerUri: kLongSource,
    );

KvmCapability _capability() => const KvmCapability(
      managerId: 'BMC',
      supported: true,
      connectTypes: const <String>['HTML5'],
      serviceEnabled: true,
      // No uri -> the capability card's source fallback row renders.
      sourceManagerUri: kLongSource,
    );

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

/// Applies both compound axes: RTL direction and the given text scaler.
Widget _withAxes(Widget child, TextDirection direction, double scale) =>
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: direction, child: child),
    );

/// Pumps the two real operator cards (per-console + per-manager capability)
/// together, exactly as the EP-U32/U40 rtl-scale guards do.
Future<void> _pumpCards(
  WidgetTester tester, {
  required double width,
  required TextDirection direction,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final KvmConsole console = _console();
  final List<KvmCapability> capabilities = <KvmCapability>[_capability()];
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(capabilities),
        ),
      ],
      child: MaterialApp(
        home: _withAxes(const KvmView(systemId: 'bmc1'), direction, scale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required double width,
  required TextDirection direction,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 2500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final KvmConsole console = _console();
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
      ],
      child: MaterialApp(
        home:
            _withAxes(KvmConsoleViewerPage(console: console), direction, scale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A visible source value (Text or SelectableText) carrying [needle].
Finder _visibleSource(String needle) => find.byWidgetPredicate((Widget w) {
      if (w is Text) return (w.data ?? '').contains(needle);
      if (w is SelectableText) return w.data?.contains(needle) ?? false;
      return false;
    });

/// Every Semantics widget whose announced label carries the source value.
Finder _sourceNodes(String needle) => find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics && (w.properties.label?.contains(needle) ?? false),
    );

void main() {
  group('EP-U42 manager-source row x RTL x 2.0x a11y agreement (#009/#021)',
      () {
    test('fixture source is control-free and both models keep it byte-exact',
        () {
      expect(kLongSource.contains(RegExp(r'[\u0000-\u001F\u007F]')), isFalse);
      expect(_console().safeManagerUri, kLongSource,
          reason: 'console model keeps the source byte-exact');
      expect(_capability().safeManagerUri, kLongSource,
          reason: 'capability model keeps the source byte-exact');
      expect(_console().launchUri, isNull,
          reason: 'console fixture renders the no-URI source row');
      expect(_capability().launchUri, isNull,
          reason: 'capability fixture renders the no-URI source row');
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards announce + display the FULL byte-exact source under '
        'RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'RTL/2.0x overflow at $px');

          // Each source row is ONE merged node announcing the FULL source.
          expect(find.bySemanticsLabel(kConsolePrefix + kLongSource),
              findsOneWidget,
              reason: '$px console card full-source merged node');
          expect(find.bySemanticsLabel(kCapabilityPrefix + kLongSource),
              findsOneWidget,
              reason: '$px capability card full-source merged node');

          // The full source is visible exactly once per surface (prefix Text +
          // value SelectableText), and no split / duplicate / screen-reader-only
          // Semantics node carries it (exactly the two merged source rows).
          expect(find.text(kConsolePrefix.trimRight()), findsOneWidget,
              reason: '$px one visible console-card source prefix');
          expect(find.text(kCapabilityPrefix.trimRight()), findsOneWidget,
              reason: '$px one visible capability-card source prefix');
          expect(_visibleSource(kLongSource).evaluate().length, 2,
              reason: '$px one visible source value per card');
          expect(_sourceNodes(kLongSource).evaluate().length, 2,
              reason: '$px no duplicate/screen-reader-only source node');
        },
      );

      testWidgets(
        'viewer announces + displays the FULL byte-exact source under '
        'RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpViewer(
            tester,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          expect(find.bySemanticsLabel(kViewerPrefix + kLongSource),
              findsOneWidget,
              reason: '$px viewer merged full-source node');
          expect(find.text(kViewerPrefix + kLongSource), findsOneWidget,
              reason: '$px one visible viewer source row');
          expect(_sourceNodes(kLongSource).evaluate().length, 1,
              reason: '$px no duplicate/screen-reader-only viewer source node');
          expect(tester.takeException(), isNull,
              reason: '$px viewer renders the long source without overflow');
        },
      );

      testWidgets(
        'LTR / 1.0x control keeps all three source rows byte-exact at '
        '${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.ltr,
            scale: 1.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'LTR/1.0x overflow at $px');
          expect(find.bySemanticsLabel(kConsolePrefix + kLongSource),
              findsOneWidget,
              reason: '$px LTR console source node');
          expect(find.bySemanticsLabel(kCapabilityPrefix + kLongSource),
              findsOneWidget,
              reason: '$px LTR capability source node');
        },
      );
    }
  });
}
