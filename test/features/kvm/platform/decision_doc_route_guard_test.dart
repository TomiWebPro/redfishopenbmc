// EP-P8 (epic #009/#021) — decision-doc <-> production-route consistency guard.
//
// EP-P5 pins the import surface, EP-P6 pins the runtime route surface and EP-P7
// pins the documented human gate. Nothing, until now, pins that the DECISION
// TABLE recorded in `LAUNCH_FALLBACK.md` still agrees with the code that
// computes the route: a future edit could flip a documented cell (or a code
// branch) and leave the other silently stale, misleading a reviewer into
// believing production routes somewhere it does not.
//
// This guard parses the 8-row `Decision contract` route table in
// `LAUNCH_FALLBACK.md` and, for each documented signal combination, recomputes
// the real plan via `planConsoleLaunch` and fails closed if the documented
// `Route` / `acceptSelfSigned` cells no longer match. It also checks that both
// decision docs still record the same flag-off final route (external-browser +
// copy) and that no flag-off row documents an in-app route.
//
// Deliberately TEST-only, dependency-free, opens no network, grants no human
// approval, imports no plugin and never touches production TLS (issue #009/#021).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

const String matrixDocPath = 'lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md';
const String fallbackDocPath = 'lib/features/kvm/platform/LAUNCH_FALLBACK.md';

/// One documented table row mapped to the exact code inputs it describes.
/// The doc itself supplies the expected route/self-signed cells; the code
/// supplies the actual plan — the test only supplies the scenario inputs.
typedef RouteScenario = ({
  String label,
  KvmWebViewPolicy policy,
  String? uri,
  bool hasSecureUri,
  bool isHtml5,
  bool isEnabled,
});

/// The 8 documented signal combinations, keyed by their exact row label.
/// These are the *inputs* the doc row describes, not its expected output.
List<RouteScenario> get scenarios => <RouteScenario>[
      (
        label: 'flag off + HTTPS HTML5 enabled',
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      ),
      (
        label: 'flag off + plaintext HTTP',
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'http://bmc.example/console',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      ),
      (
        label: 'flag off + no URI',
        policy: KvmWebViewPolicy.productionDefault,
        uri: null,
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      ),
      (
        label: 'flag off + blank URI / inconsistent "secure" flag',
        policy: KvmWebViewPolicy.productionDefault,
        // A blank/whitespace target with a stale "secure" signal must still
        // fail closed to copy-only with a null target.
        uri: '   ',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      ),
      (
        label: 'flag off + **disabled** console (even HTTPS)',
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: false,
      ),
      (
        label: 'test opt-in + HTTPS HTML5 enabled',
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      ),
      (
        label: 'opt-in but strict TLS',
        // Flag on, but the strict (non-test) TLS mode: in-app is permitted,
        // yet self-signed acceptance stays false.
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      ),
      (
        label: 'opt-in + plaintext / disabled / non-HTML5',
        policy: KvmWebViewPolicy.testOptIn,
        // Representative unsafe variant; a dedicated test below covers all
        // three. The doc records these as "never launchable" (in-app).
        uri: 'http://bmc.example/console',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      ),
    ];

/// Lowercase + collapse whitespace. Keeps markdown emphasis (`**`) so the
/// exact row label can be matched; callers that want plain labels strip it.
String normalize(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

String plainLabel(String label) =>
    normalize(label).replaceAll('**', '').replaceAll('"', '"');

/// Parses the 8 scenario rows from the `Decision contract` table. Returns raw
/// cells per row: (label, route, targetUri, acceptSelfSigned).
List<List<String>> parseRouteRows(String fallbackRaw) {
  final List<List<String>> rows = <List<String>>[];
  for (final String line in fallbackRaw.split('\n')) {
    if (!line.startsWith('| flag off') &&
        !line.startsWith('| test opt-in') &&
        !line.startsWith('| opt-in')) {
      continue;
    }
    final List<String> cells = line
        .split('|')
        .map((String c) => c.trim())
        .where((String c) => c.isNotEmpty)
        .toList();
    if (cells.length >= 4) rows.add(cells);
  }
  return rows;
}

/// `externalBrowser` / `copyOnly` / `inAppWebView` / `never launchable` —
/// strips the backticks and any trailing parenthetical (`(fail closed)`,
/// `(test-only)` is on the self-signed cell, not here).
String docRoute(String routeCell) {
  final String bare = routeCell.replaceAll('`', '').trim();
  final int paren = bare.indexOf('(');
  return (paren < 0 ? bare : bare.substring(0, paren)).trim();
}

bool? docSelfSigned(String cell) {
  if (cell.contains('true')) return true;
  if (cell.contains('false')) return false;
  return null;
}

/// Returns the NAMES of every doc<->code route discrepancy. Empty == green.
List<String> routeTableViolations(String fallbackRaw) {
  final List<String> violations = <String>[];
  final List<List<String>> rows = parseRouteRows(fallbackRaw);
  if (rows.length != 8) {
    violations.add('table:expected-8-rows-found-${rows.length}');
  }

  final Set<String> seen = <String>{};
  for (final RouteScenario s in scenarios) {
    final String label = plainLabel(s.label);
    final List<String>? row = rows.cast<List<String>?>().firstWhere(
          (List<String>? r) => r != null && plainLabel(r[0]) == label,
          orElse: () => null,
        );
    if (row == null) {
      violations.add('row:missing:$label');
      continue;
    }
    seen.add(label);

    final KvmConsoleLaunchPlan plan = planConsoleLaunch(
      policy: s.policy,
      uri: s.uri,
      hasSecureUri: s.hasSecureUri,
      isHtml5: s.isHtml5,
      isEnabled: s.isEnabled,
    );
    final String documented = docRoute(row[1]);
    if (documented == 'never launchable') {
      if (plan.route == KvmConsoleRenderRoute.inAppWebView) {
        violations.add('route:$label:doc=never-launchable code=inAppWebView');
      }
    } else if (plan.route.name != documented) {
      violations.add('route:$label:doc=$documented code=${plan.route.name}');
    }

    final bool? documentedSelfSigned = docSelfSigned(row[3]);
    if (documentedSelfSigned == null) {
      violations.add('selfsigned:$label:unparseable-cell=${row[3]}');
    } else if (plan.acceptSelfSigned != documentedSelfSigned) {
      violations.add(
          'selfsigned:$label:doc=$documentedSelfSigned code=${plan.acceptSelfSigned}');
    }

    // A flag-off production row must never document an in-app final route.
    if (label.startsWith('flag off') && documented == 'inAppWebView') {
      violations.add('flagoff:$label:documents-in-app-route');
    }
  }
  for (final List<String> row in rows) {
    final String label = plainLabel(row[0]);
    if (!seen.contains(label)) violations.add('row:unknown:$label');
  }
  return violations;
}

/// Both docs must still record the SAME flag-off final route: external-browser
/// + copy, never an in-app WebView. Returns violation names (empty == green).
List<String> finalRouteViolations(String matrixRaw, String fallbackRaw) {
  final String matrix = normalize(matrixRaw);
  final String fallback = normalize(fallbackRaw);
  final List<String> violations = <String>[];

  const String matrixOnlyRoute =
      'external secure-browser path remain the only rendering route';
  const String fallbackOnlyRoute =
      'external-browser + copy path remains the only rendering route';
  const String matrixFinalRoute = 'final route remains external-browser + copy';

  if (!matrix.contains(matrixOnlyRoute)) {
    violations.add('matrix:only-rendering-route');
  }
  if (!fallback.contains(fallbackOnlyRoute)) {
    violations.add('fallback:only-rendering-route');
  }
  if (!matrix.contains(matrixFinalRoute)) {
    violations.add('matrix:final-route-recorded');
  }
  // The two docs must agree, not merely each contain a marker: if one loses
  // the recorded final route the agreement check fails too.
  final bool matrixRecords = matrix.contains('external browser + copy') ||
      matrix.contains('external-browser + copy');
  final bool fallbackRecords = fallback.contains('external browser + copy') ||
      fallback.contains('external-browser + copy');
  if (matrixRecords != fallbackRecords) {
    violations.add('docs:final-route-disagree');
  }
  return violations;
}

void main() {
  final String realMatrix = File(matrixDocPath).readAsStringSync();
  final String realFallback = File(fallbackDocPath).readAsStringSync();

  group('EP-P8 decision-doc <-> route consistency', () {
    test('scenario table is non-trivial and spans both policies', () {
      expect(scenarios.length, 8);
      expect(
        scenarios.any((RouteScenario s) =>
            s.policy == KvmWebViewPolicy.productionDefault),
        isTrue,
      );
      expect(scenarios.any((RouteScenario s) => s.policy.enabled), isTrue);
      expect(parseRouteRows(realFallback).length, 8);
    });

    test('real decision table matches the code for every documented row', () {
      expect(routeTableViolations(realFallback), isEmpty);
    });

    test('both docs record the same flag-off final route', () {
      expect(finalRouteViolations(realMatrix, realFallback), isEmpty);
    });

    test('RED: flipping a documented flag-off route cell fails closed', () {
      final String mutated = realFallback.replaceFirst(
        '| flag off + HTTPS HTML5 enabled | `externalBrowser`',
        '| flag off + HTTPS HTML5 enabled | `copyOnly`',
      );
      expect(mutated, isNot(realFallback));
      expect(
        routeTableViolations(mutated),
        contains(
            'route:flag off + https html5 enabled:doc=copyOnly code=externalBrowser'),
      );
    });

    test('RED: flipping a documented opt-in self-signed cell fails closed', () {
      final String mutated = realFallback.replaceFirst(
        '| test opt-in + HTTPS HTML5 enabled | `inAppWebView` | trimmed HTTPS URI | `true` (test-only) |',
        '| test opt-in + HTTPS HTML5 enabled | `inAppWebView` | trimmed HTTPS URI | `false` |',
      );
      expect(mutated, isNot(realFallback));
      expect(
        routeTableViolations(mutated),
        contains(
            'selfsigned:test opt-in + https html5 enabled:doc=false code=true'),
      );
    });

    test('RED: deleting a documented route row fails closed', () {
      final String mutated = realFallback.replaceFirst(
        '| flag off + no URI | `copyOnly` | `null` | `false` |\n',
        '',
      );
      expect(mutated, isNot(realFallback));
      final List<String> v = routeTableViolations(mutated);
      expect(v, isNotEmpty);
      expect(
          v.any((String s) => s.startsWith('table:expected-8-rows')), isTrue);
    });

    test('RED: erasing the matrix final-route statement fails closed', () {
      final String mutated = realMatrix.replaceFirst(
        'external secure-browser path remain the only rendering route and keep working',
        'external secure-browser path are deferred and keep working',
      );
      expect(mutated, isNot(realMatrix));
      expect(
        finalRouteViolations(mutated, realFallback),
        contains('matrix:only-rendering-route'),
      );
    });

    test(
        'test opt-in still never routes in-app for plaintext/disabled/non-HTML5',
        () {
      const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;
      for (final ({String? uri, bool secure, bool html5, bool enabled}) c
          in <({String? uri, bool secure, bool html5, bool enabled})>[
        (
          uri: 'http://bmc.example/console',
          secure: false,
          html5: true,
          enabled: true
        ),
        (
          uri: 'https://bmc.example/console',
          secure: true,
          html5: true,
          enabled: false
        ),
        (
          uri: 'https://bmc.example/console',
          secure: true,
          html5: false,
          enabled: true
        ),
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: optIn,
          uri: c.uri,
          hasSecureUri: c.secure,
          isHtml5: c.html5,
          isEnabled: c.enabled,
        );
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'opt-in unsafe combo $c routed in-app');
        expect(plan.acceptSelfSigned, isFalse,
            reason: 'opt-in unsafe combo $c accepted self-signed');
      }
    });
  });
}
