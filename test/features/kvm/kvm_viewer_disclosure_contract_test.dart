// EP-U9 / #009 / #021: cross-path, cross-width a11y contract for the
// KvmConsoleViewerPage disclosures.
//
// The viewer is the app's full-screen console surface. On entering it starts a
// pure-UI session (EP-U4) and discloses the only machine-checkable half of the
// "fullscreen / back = disconnect" guidance that is truthful without an
// embedded WebView: the active-session notice
// (`kvmSessionActiveNotice`, "go back or tap Disconnect console to end it") and
// the session-persistence notice (`kvmSessionPersistenceNotice`). The actual
// keyboard/mouse input-forwarding half remains externally blocked on platform
// WebView + BMC TLS validation (human-gated); pinning a "keys are forwarded"
// string before any forwarding exists would be a false claim, so it is
// deliberately NOT manufactured here.
//
// What the existing suites do NOT pin: that BOTH disclosures render as one
// merged `excludeSemantics` node whose visible `Text` equals the announced
// label, EXACTLY once each with no duplicate/stale disconnect copy, on every
// viewer path — secure-HTTPS, external-client and no-URI — at 320/800/1300 px.
// The lifecycle group in `kvm_widget_test.dart` checks the active notice for a
// single console at default width; EP-U7 checks the persistence notice but not
// alongside the lifecycle disclosure across the three paths. A future edit that
// drops a disclosure, duplicates it, splits visible text from the a11y label,
// or only renders it on one launch path silently regresses screen-reader parity
// — this suite fails closed on all of those.
//
// Display-only, dependency-free, TLS-safe: no URL opened, no WebView/protocol
// import, no production TLS change, no human approval granted.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_session.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 20, 12);

/// Secure-HTTPS graphical console: `launchPlan.targetUri` is a trimmed HTTPS
/// endpoint, so the viewer takes the "console URI" branch.
const KvmConsole _secureHttps = KvmConsole(
  type: KvmConsoleType.graphical,
  managerId: 'BMC-HTTPS',
  connectTypesSupported: <String>['KVMIP', 'HTML5'],
  serviceEnabled: true,
  connectUri: 'https://bmc.example/kvm',
  sourceManagerUri: '/redfish/v1/Managers/BMC-HTTPS',
);

/// VNC/RFB console: an external-client strategy with a copyable URI, still the
/// "console URI" branch but a different launch status than secure HTTPS.
const KvmConsole _externalClient = KvmConsole(
  type: KvmConsoleType.remote,
  managerId: 'BMC-VNC',
  connectTypesSupported: <String>['KVMIP'],
  serviceEnabled: true,
  connectUri: 'vnc://bmc.example:5900',
  sourceManagerUri: '/redfish/v1/Managers/BMC-VNC',
);

/// URI-less console: `launchPlan.targetUri` is null, so the viewer takes the
/// "No direct console URI. Manager source: …" branch of the same surface.
const KvmConsole _noUri = KvmConsole(
  type: KvmConsoleType.graphical,
  managerId: 'BMC-NOURI',
  connectTypesSupported: <String>['KVMIP'],
  serviceEnabled: true,
  connectUri: null,
  sourceManagerUri: '/redfish/v1/Managers/BMC-NOURI',
);

Map<String, KvmConsole> get _paths => <String, KvmConsole>{
      'secure-HTTPS': _secureHttps,
      'external-client': _externalClient,
      'no-URI': _noUri,
    };

const List<double> _widths = <double>[320, 800, 1300];

/// The single merged `excludeSemantics` node whose label is exactly [notice].
Finder _mergedNotice(String notice) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == notice,
    );

/// One merged node announces exactly [notice] AND the single visible `Text`
/// with that wording sits inside that same node (visible == announced).
void _expectOneMergedNotice(WidgetTester tester, String notice) {
  expect(find.text(notice), findsOneWidget,
      reason: 'exactly one visible "$notice"');
  expect(_mergedNotice(notice), findsOneWidget,
      reason: 'exactly one merged a11y node for "$notice"');
  expect(
    find.ancestor(of: find.text(notice), matching: _mergedNotice(notice)),
    findsOneWidget,
    reason: 'visible "$notice" must be inside its merged a11y node',
  );
}

/// Pumps a fresh, deterministic session scope for one viewer path/width. A
/// fresh [ProviderContainer] per pump keeps the session state isolated; the
/// fixed clock makes the post-frame `connect()` deterministic.
Future<void> _pumpViewer(
  WidgetTester tester,
  KvmConsole console, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      kvmSessionClockProvider.overrideWithValue(() => _t0),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      // A unique key forces a fresh StatefulElement on every pump. Without it,
      // re-pumping the same widget type in one test reuses the element, so
      // `initState` (and the post-frame session connect) never runs again and
      // the active-session disclosure would not appear on subsequent pumps.
      child: MaterialApp(
        home: KvmConsoleViewerPage(
          key: ValueKey<String>('${console.managerId}-${width.toInt()}'),
          console: console,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('KvmConsoleViewerPage — disclosure contract (EP-U9 / #009 / #021)', () {
    for (final MapEntry<String, KvmConsole> path in _paths.entries) {
      testWidgets(
          '${path.key}: fullscreen/back = disconnect disclosure is a '
          'single merged node (visible == announced)', (tester) async {
        await _pumpViewer(tester, path.value, width: 800);

        // The active-session notice IS the implemented, truthful half of the
        // fullscreen/back = disconnect guidance: it must name both "go back"
        // and the Disconnect affordance, once, with visible text == label.
        expect(kvmSessionActiveNotice, contains('go back'));
        expect(kvmSessionActiveNotice, contains('Disconnect console'));
        _expectOneMergedNotice(tester, kvmSessionActiveNotice);
        expect(find.text('Disconnect console'), findsOneWidget);
      });

      testWidgets(
          '${path.key}: session-persistence disclosure is a single '
          'merged node (visible == announced)', (tester) async {
        await _pumpViewer(tester, path.value, width: 800);
        _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
      });

      testWidgets(
          '${path.key}: exactly two disconnect disclosures, no '
          'duplicate/stale copy', (tester) async {
        await _pumpViewer(tester, path.value, width: 800);

        final List<String> disconnectLabels = tester
            .widgetList<Semantics>(
              find.byWidgetPredicate((Widget widget) =>
                  widget is Semantics &&
                  widget.container &&
                  widget.excludeSemantics),
            )
            .map((Semantics s) => s.properties.label ?? '')
            .where((String label) => label.toLowerCase().contains('disconnect'))
            .toList();

        expect(
            disconnectLabels.where((l) => l == kvmSessionActiveNotice).length,
            1,
            reason: 'active-session disclosure exactly once');
        expect(
            disconnectLabels
                .where((l) => l == kvmSessionPersistenceNotice)
                .length,
            1,
            reason: 'session-persistence disclosure exactly once');
        expect(disconnectLabels.length, 2,
            reason: 'no third/duplicate disconnect disclosure');
      });

      testWidgets(
          '${path.key}: disclosures render without overflow at '
          '320 / 800 / 1300 px', (tester) async {
        for (final double width in _widths) {
          await _pumpViewer(tester, path.value, width: width);
          _expectOneMergedNotice(tester, kvmSessionActiveNotice);
          _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
          expect(tester.takeException(), isNull,
              reason: 'no overflow at ${width.toInt()} px');
        }
      });
    }

    testWidgets(
        'all three viewer paths announce the SAME two disclosure '
        'constants (no per-path copy drift)', (tester) async {
      for (final KvmConsole console in _paths.values) {
        await _pumpViewer(tester, console, width: 800);
        _expectOneMergedNotice(tester, kvmSessionActiveNotice);
        _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
      }
    });
  });
}
