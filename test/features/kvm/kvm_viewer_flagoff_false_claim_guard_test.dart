// EP-U10 / #009 / #021: flag-off "false claim" firewall for the KVM console
// viewer.
//
// The human-gated decision records that the production WebView flag is OFF and
// that keyboard/mouse input forwarding + in-app embedded live rendering do NOT
// exist in the product build. EP-U9 pins the two disclosures the viewer DOES
// show (active session / session persistence), but nothing fails closed if a
// future edit manufactures a *false* operator assurance — "keys are being
// forwarded", "the embedded console is live" — while the flag is off. That copy
// would be a screen-reader-visible lie on an operator decision surface and a
// bypass of the human WebView/TLS validation gate (it asserts a capability that
// has not been validated on any platform).
//
// What this suite adds (genuinely distinct from the exact-string suites):
//   * it harvests EVERY visible Text/SelectableText AND EVERY Semantics label
//     the viewer renders — across secure-HTTPS, external-client VNC/SSH,
//     no-URI, insecure-HTTP and BMC-disabled paths at 320/800/1300 px — and
//     fails closed if ANY string asserts input forwarding or a live/streaming
//     in-app console while the flag is off;
//   * it checks the pure status resolver (`kvmLaunchStatusText`) for the same
//     forbidden claims so a model-side copy regression is caught without a
//     widget pump;
//   * it pins that the viewer renders the resolved status verbatim as one
//     merged `excludeSemantics` node (visible == announced) on every path, so a
//     future hardcoded status cannot silently drift from the resolver;
//   * it asserts the viewer's whole-tree a11y copy contains no claim that the
//     app holds an open *input channel* to the console (session lifecycle copy
//     about "active"/"persists"/"disconnect" is explicitly allowed — it is the
//     truthful, implemented half).
//
// Display-only, dependency-free, TLS-safe: no URL opened, no WebView/protocol
// import, no dependency bump, no production TLS change, no human approval.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_session.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 20, 21);

/// Forbidden false claims for the two human-gated capabilities. Patterns are
/// deliberately concept-based (not exact-string copies of a known-bad line):
/// any copy asserting that keyboard/mouse/input IS forwarded, or that an
/// embedded/in-app console IS live or streaming, must fail closed. The truthful
/// session lifecycle words ("session active", "persists", "disconnect") and the
/// honest "rendering requires a WebView" / "not available in-app" guidance do
/// not match any of these patterns.
final List<RegExp> _forbiddenFalseClaims = <RegExp>[
  // Capability 1 — keyboard/mouse/input forwarding (not implemented).
  RegExp(
      r'\b(?:input|keyboard|mouse|keys?)\b[^.]{0,48}\bforward(?:ed|ing|s)?\b',
      caseSensitive: false),
  RegExp(r'\bforward(?:ed|ing)\b[^.]{0,48}\b(?:input|keyboard|mouse|keys?)\b',
      caseSensitive: false),
  // Capability 2 — a live / streaming in-app embedded console (not implemented).
  RegExp(
      r'\bconsole\b[^.]{0,40}\b(?:is|are)?\s*(?:now\s+)?(?:live|streaming)\b',
      caseSensitive: false),
  RegExp(r'\b(?:live|streaming)\b[^.]{0,40}\bconsole\b', caseSensitive: false),
  RegExp(
      r'\b(?:embedded|in-app)\b[^.]{0,40}\b(?:live|streaming|rendering\s+now)\b',
      caseSensitive: false),
  RegExp(r'\bconnected\s+to\s+(?:the\s+)?console\b', caseSensitive: false),
];

/// Every forbidden claim found in [copy], for actionable failure messages.
List<String> _falseClaimsIn(Iterable<String> copy) {
  final List<String> hits = <String>[];
  for (final String text in copy) {
    for (final RegExp pattern in _forbiddenFalseClaims) {
      if (pattern.hasMatch(text)) hits.add('"$text"');
    }
  }
  return hits.toSet().toList()..sort();
}

/// Console matrix — every viewer path named by EP-U10 plus the two additional
/// fail-closed paths (insecure HTTP, BMC-disabled) that share the same surface.
KvmConsole _console({
  required String id,
  required KvmConsoleType type,
  required List<String> types,
  required String? uri,
  bool enabled = true,
}) =>
    KvmConsole(
      type: type,
      managerId: id,
      connectTypesSupported: types,
      serviceEnabled: enabled,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/$id',
    );

Map<String, KvmConsole> get _paths => <String, KvmConsole>{
      // Secure HTTPS graphical/HTML5 -> inAppHtml5 resolver branch.
      'secure-HTTPS': _console(
        id: 'BMC-HTTPS',
        type: KvmConsoleType.graphical,
        types: const <String>['KVMIP', 'HTML5'],
        uri: 'https://bmc.example/kvm',
      ),
      // Secure HTTPS non-HTML5 -> secureBrowser branch.
      'secure-browser': _console(
        id: 'BMC-BROWSER',
        type: KvmConsoleType.graphical,
        types: const <String>['KVMIP'],
        uri: 'https://bmc.example/kvm',
      ),
      // VNC/RFB external client.
      'external-vnc': _console(
        id: 'BMC-VNC',
        type: KvmConsoleType.remote,
        types: const <String>['KVMIP'],
        uri: 'vnc://bmc.example:5900',
      ),
      // SSH serial external client.
      'external-ssh': _console(
        id: 'BMC-SSH',
        type: KvmConsoleType.serial,
        types: const <String>['SSH', 'Telnet'],
        uri: 'ssh://bmc.example',
      ),
      // No direct URI.
      'no-URI': _console(
        id: 'BMC-NOURI',
        type: KvmConsoleType.graphical,
        types: const <String>['KVMIP'],
        uri: null,
      ),
      // Plaintext HTTP HTML5 (cleartext warning branch).
      'insecure-HTTP': _console(
        id: 'BMC-HTTP',
        type: KvmConsoleType.graphical,
        types: const <String>['HTML5'],
        uri: 'http://bmc.example/kvm',
      ),
      // BMC-disabled but with a URI (fail-closed copy-only branch).
      'disabled': _console(
        id: 'BMC-OFF',
        type: KvmConsoleType.graphical,
        types: const <String>['KVMIP', 'HTML5'],
        uri: 'https://bmc.example/kvm',
        enabled: false,
      ),
    };

const List<double> _widths = <double>[320, 800, 1300];

/// Pumps a fresh, deterministic session scope for one viewer path/width.
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

/// All operator-visible copy the viewer currently renders: visible text nodes
/// AND every Semantics label (including screen-reader-only labels).
List<String> _renderedCopy(WidgetTester tester) {
  final List<String> copy = <String>[];
  for (final Widget widget in tester.allWidgets) {
    if (widget is Text && widget.data != null && widget.data!.isNotEmpty) {
      copy.add(widget.data!);
    } else if (widget is SelectableText &&
        widget.data != null &&
        widget.data!.isNotEmpty) {
      copy.add(widget.data!);
    }
    final String? label = widget is Semantics ? widget.properties.label : null;
    if (label != null && label.isNotEmpty) copy.add(label);
  }
  return copy.toSet().toList()..sort();
}

/// The merged `excludeSemantics` node whose label is exactly [label].
Finder _merged(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == label,
    );

void main() {
  group(
      'KvmConsoleViewerPage — flag-off false-claim firewall '
      '(EP-U10 / #009 / #021)', () {
    testWidgets(
        'no viewer path asserts input forwarding or a live embedded '
        'console at 320 / 800 / 1300 px', (tester) async {
      for (final MapEntry<String, KvmConsole> path in _paths.entries) {
        for (final double width in _widths) {
          await _pumpViewer(tester, path.value, width: width);
          final List<String> hits = _falseClaimsIn(_renderedCopy(tester));
          expect(hits, isEmpty,
              reason: '${path.key} @ ${width.toInt()}px must not claim a '
                  'human-gated capability while the flag is off: $hits');
          expect(tester.takeException(), isNull,
              reason: '${path.key} @ ${width.toInt()}px no overflow');
        }
      }
    });

    testWidgets(
        'the resolved launch status is rendered verbatim as one '
        'merged node (visible == announced) on every path', (tester) async {
      for (final MapEntry<String, KvmConsole> path in _paths.entries) {
        await _pumpViewer(tester, path.value, width: 800);
        final String status = kvmLaunchStatusText(
          path.value.launchStrategy,
          externalProtocol: path.value.externalClientProtocolLabel,
        );
        expect(find.text(status), findsOneWidget,
            reason: '${path.key}: visible status == resolver output');
        expect(_merged(status), findsOneWidget,
            reason: '${path.key}: one merged a11y node for the status');
        expect(
          find.ancestor(
            of: find.text(status),
            matching: _merged(status),
          ),
          findsOneWidget,
          reason: '${path.key}: visible status inside its merged node',
        );
      }
    });

    testWidgets(
        'every merged a11y node carries visible text (no '
        'screen-reader-only false claim)', (tester) async {
      for (final KvmConsole console in _paths.values) {
        await _pumpViewer(tester, console, width: 800);
        for (final Semantics node in tester.widgetList<Semantics>(
            find.byWidgetPredicate((Widget w) =>
                w is Semantics && w.container && w.excludeSemantics))) {
          final String label = node.properties.label ?? '';
          if (label.isEmpty) continue;
          final bool hasVisibleText = tester
              .widgetList<Text>(
                find.descendant(
                  of: find.byWidget(node),
                  matching: find.byType(Text),
                ),
              )
              .any((Text t) => (t.data ?? '').isNotEmpty);
          final bool hasVisibleSelectable = tester
              .widgetList<SelectableText>(
                find.descendant(
                  of: find.byWidget(node),
                  matching: find.byType(SelectableText),
                ),
              )
              .any((SelectableText t) => (t.data ?? '').isNotEmpty);
          expect(hasVisibleText || hasVisibleSelectable, isTrue,
              reason: 'merged label "$label" must have visible text so '
                  'screen-reader copy can never diverge from sighted copy');
        }
      }
    });

    test(
        'kvmLaunchStatusText asserts no human-gated capability for any '
        'strategy', () {
      for (final KvmLaunchStrategy strategy in KvmLaunchStrategy.values) {
        for (final String? protocol in <String?>[null, 'VNC/RFB', 'SSH']) {
          final String status = kvmLaunchStatusText(
            strategy,
            externalProtocol: protocol,
          );
          expect(_falseClaimsIn(<String>[status]), isEmpty,
              reason: 'status for $strategy / $protocol must not claim a '
                  'human-gated capability');
        }
      }
      // Guard the guard: the forbidden patterns must actually fire on the two
      // classes of false claim they exist to catch.
      expect(
        _falseClaimsIn(<String>[
          'Keyboard and mouse input are being forwarded to the console.',
        ]),
        isNotEmpty,
        reason: 'input-forwarding claims must be detected',
      );
      expect(
        _falseClaimsIn(<String>[
          'The embedded console is live and streaming.',
        ]),
        isNotEmpty,
        reason: 'live-embedded-rendering claims must be detected',
      );
    });
  });
}
