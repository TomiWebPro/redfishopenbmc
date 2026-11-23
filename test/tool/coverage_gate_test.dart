// Unit tests for the issue #010 coverage gate (tool/coverage_gate.dart).
//
// These are pure-Dart tests over inline lcov strings — no real coverage run or
// file I/O is needed, so `flutter test` never depends on `coverage/lcov.info`.
// (EP-T31 adds a file-based CLI/CI wiring invariant; it reads only checked-in
// source/config files, never a generated coverage artifact.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_gate.dart';

/// Builds one lcov record.
String record(String path, int found, int hit) => [
      'SF:$path',
      'DA:1,$hit',
      'LF:$found',
      'LH:$hit',
      'end_of_record',
    ].join('\n');

/// Builder tokens that [evaluateAllGates] must call so all four enforced gates
/// (overall + redfish/power/sensors from `evaluateGates`, plus `kvm` and
/// `kvm-platform`) stay bound. EP-T31 pins these against a silent drop/rename.
const List<String> kAllGateBuilderTokens = <String>[
  'evaluateGates(',
  'evaluateKvmGate(',
  'evaluateKvmPlatformGate(',
];

/// Documented minimum thresholds for the four enforced coverage gates
/// (EP-T34). These floors mirror issue #010 (overall ≥75%, high-value scoped
/// ≥80%) and issue #009 (kvm ≥75%, kvm-platform ≥75%). A silent lowering below
/// a floor would keep every gate "wired" (EP-T31) and every test file "live"
/// (EP-T12..T33) while erasing the hard invariant.
const Map<String, double> kCoverageThresholdFloors = <String, double>{
  'overall': 0.75,
  'scoped': 0.80,
  'kvm': 0.75,
  'kvm-platform': 0.75,
};

/// Pure evaluator for the coverage-gate CLI/CI wiring invariant (EP-T31).
///
/// [cliSource] is the text of `tool/coverage_gate.dart`; [verifySource] is the
/// text of `.github/workflows/verify.yml`. Returns concrete drift diagnostics;
/// empty means every enforced gate is wired into both the CLI entry point and
/// the CI workflow. No I/O and no Flutter bindings — callers supply the text.
///
/// Guard-suite liveness (EP-T12..T29) pins that TEST files stay in the canonical
/// set and runs `flutter test --coverage`; it does not pin that the coverage
/// gates themselves are still invoked. Without this invariant, a future edit
/// could drop the `dart run tool/coverage_gate.dart` CI step (or make `main`
/// call the two-gate `evaluateGates`) and silently stop enforcing the
/// kvm-platform gate while every test stayed GREEN.
List<String> evaluateCoverageGateWiring(String cliSource, String verifySource) {
  final String cli = cliSource.replaceAll('\r', '');
  final String verify = verifySource.replaceAll('\r', '');
  final List<String> violations = <String>[];

  // (1) evaluateAllGates must still bind all four enforced gates. Slice from
  // its definition up to the next top-level declaration so a token appearing
  // elsewhere (a comment, a test) cannot satisfy the check.
  final int start = cli.indexOf('CoverageGateReport evaluateAllGates(');
  if (start < 0) {
    violations.add('CLI: evaluateAllGates definition missing');
  } else {
    final int end = cli.indexOf('const String kDefaultLcovPath', start);
    final String body =
        end > start ? cli.substring(start, end) : cli.substring(start);
    for (final String token in kAllGateBuilderTokens) {
      if (!body.contains(token)) {
        violations.add('CLI: evaluateAllGates no longer calls $token');
      }
    }
  }

  // (2) main() must call evaluateAllGates — the narrower evaluateGates returns
  // only two results, silently dropping kvm + kvm-platform from the CLI.
  final int mainStart = cli.indexOf('main(List<String> args)');
  if (mainStart < 0) {
    violations.add('CLI: main() definition missing');
  } else if (!RegExp(r'\bevaluateAllGates\s*\(')
      .hasMatch(cli.substring(mainStart))) {
    violations.add('CLI: main() no longer invokes evaluateAllGates');
  }

  // (3) CI must actually run the gate CLI; dropping the step would stop
  // enforcing every coverage gate while all tests stayed GREEN.
  if (!RegExp(r'dart\s+run\s+tool/coverage_gate\.dart').hasMatch(verify)) {
    violations.add('CI: verify.yml no longer runs tool/coverage_gate.dart');
  }

  // (4) CI must produce lcov before that CLI reads it.
  if (!RegExp(r'flutter\s+test\b[^\n]*--coverage').hasMatch(verify)) {
    violations.add('CI: verify.yml no longer runs "flutter test --coverage"');
  }

  return violations;
}

/// First numeric literal captured by [pattern] in [src], or null when absent.
double? _firstNumericMatch(String src, String pattern) {
  final RegExpMatch? match = RegExp(pattern).firstMatch(src);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

/// Resolves the default `threshold` of one KVM gate builder in [src].
///
/// Both KVM builders default to the shared `kKvmThreshold` constant; a
/// hardcoded literal is resolved directly. Absence is reported as a violation.
double? _builderThresholdDefault(
  String src,
  String builder,
  double? kvmConstant,
  String label,
  List<String> violations,
) {
  final int start = src.indexOf('GateResult $builder(');
  if (start < 0) {
    violations.add('$label: $builder definition missing');
    return null;
  }
  // Slice up to the body opener `}) {` — the earlier `{` after `summary,` is
  // just the named-parameters opener and precedes the default we need.
  final int body = src.indexOf('}) {', start);
  final String signature =
      body > start ? src.substring(start, body) : src.substring(start);
  final RegExpMatch? match = RegExp(
    r'\bthreshold\s*=\s*([A-Za-z_][A-Za-z0-9_.]*|[0-9]+(?:\.[0-9]+)?)',
  ).firstMatch(signature);
  if (match == null) {
    violations.add('$label: $builder threshold default not found');
    return null;
  }
  final String expression = match.group(1)!;
  if (expression == 'kKvmThreshold') return kvmConstant;
  return double.tryParse(expression);
}

/// Pure source-text evaluator for the coverage threshold floors (EP-T34).
///
/// [cliSource] is the text of `tool/coverage_gate.dart`. Returns concrete
/// drift diagnostics; empty means all four enforced thresholds honour their
/// documented floors. No I/O and no Flutter bindings — callers supply the text.
List<String> evaluateCoverageThresholdFloors(String cliSource) {
  final String src = cliSource.replaceAll('\r', '');
  final List<String> violations = <String>[];

  final double? overall = _firstNumericMatch(
    src,
    r'\boverallThreshold\s*=\s*([0-9]+(?:\.[0-9]+)?)',
  );
  final double? scoped = _firstNumericMatch(
    src,
    r'\bscopedThreshold\s*=\s*([0-9]+(?:\.[0-9]+)?)',
  );
  final double? kvmConstant = _firstNumericMatch(
    src,
    r'\bconst\s+double\s+kKvmThreshold\s*=\s*([0-9]+(?:\.[0-9]+)?)',
  );
  if (overall == null) violations.add('overall: threshold default not found');
  if (scoped == null) violations.add('scoped: threshold default not found');
  if (kvmConstant == null) {
    violations.add('kvm: kKvmThreshold constant not found');
  }

  final double? kvm = _builderThresholdDefault(
      src, 'evaluateKvmGate', kvmConstant, 'kvm', violations);
  final double? platform = _builderThresholdDefault(
      src, 'evaluateKvmPlatformGate', kvmConstant, 'kvm-platform', violations);

  void checkFloor(String label, double? value) {
    if (value == null) return; // absence already reported above
    final double floor = kCoverageThresholdFloors[label]!;
    if (value < floor) {
      violations.add('$label threshold $value below floor $floor');
    }
  }

  checkFloor('overall', overall);
  checkFloor('scoped', scoped);
  checkFloor('kvm', kvm);
  checkFloor('kvm-platform', platform);
  return violations;
}

/// Reads the string literals of a `const List<String> <name> = <String>[ ... ];`
/// declaration out of [src]. Returns an empty list when the declaration is
/// missing or malformed, so callers can report it as drift (EP-T38).
List<String> _parseScopePrefixes(String src, String name) {
  final int start = src.indexOf('const List<String> $name');
  if (start < 0) return const <String>[];
  final int open = src.indexOf('[', start);
  if (open < 0) return const <String>[];
  final int close = src.indexOf('];', open);
  if (close < 0) return const <String>[];
  return RegExp(r"'([^']*)'")
      .allMatches(src.substring(open + 1, close))
      .map((RegExpMatch m) => m.group(1)!)
      .toList(growable: false);
}

/// Pure evaluator for coverage scope coherence (EP-T38).
///
/// EP-T31 pins that all four gates are WIRED and EP-T34 pins their threshold
/// FLOORS, but neither pins that the dedicated kvm-platform scope stays a real,
/// strictly-narrower sub-scope of the wide kvm scope. If a future edit repointed
/// the kvm-platform prefix at a non-existent directory (empty scope -> 0%) or
/// widened it to the whole kvm tree (identical to the kvm gate -> the dedicated
/// decision-layer gate silently masked), every existing guard stayed GREEN.
///
/// [cliSource] is the text of `tool/coverage_gate.dart`; [directoryExists]
/// resolves a normalized prefix to an on-disk directory. No I/O in the
/// evaluator itself — callers supply both. Empty violations = coherent scopes.
List<String> evaluateCoverageScopeCoherence(
  String cliSource, {
  required bool Function(String normalizedPrefix) directoryExists,
}) {
  final String src = cliSource.replaceAll('\r', '');
  final List<String> violations = <String>[];

  List<String> normalize(Iterable<String> prefixes) => prefixes
      .map((String p) => p.replaceAll(r'\', '/'))
      .toList(growable: false);

  final List<String> kvm =
      normalize(_parseScopePrefixes(src, 'kKvmScopePrefixes'));
  final List<String> platform =
      normalize(_parseScopePrefixes(src, 'kKvmPlatformScopePrefixes'));
  if (kvm.isEmpty) {
    violations.add('kvm: no scope prefixes declared');
  }
  if (platform.isEmpty) {
    violations.add('kvm-platform: no scope prefixes declared');
  }

  // (1) every enforced prefix must resolve to an existing directory, else the
  // gate scopes nothing and silently reports 0%.
  for (final String prefix in kvm) {
    if (!directoryExists(prefix)) {
      violations
          .add('kvm: scope prefix "$prefix" is not an existing directory');
    }
  }
  for (final String prefix in platform) {
    if (!directoryExists(prefix)) {
      violations.add(
          'kvm-platform: scope prefix "$prefix" is not an existing directory');
    }
  }

  // (2) kvm-platform must stay nested inside the kvm tree and strictly narrower
  // than it; an equal/wider scope would let the wide aggregate mask it.
  for (final String prefix in platform) {
    if (!kvm.any((String k) => prefix.startsWith(k))) {
      violations.add(
          'kvm-platform: prefix "$prefix" is not nested under any kvm prefix');
    }
  }
  if (kvm.isNotEmpty && platform.isNotEmpty && kvm.every(platform.contains)) {
    violations.add('kvm-platform: scope is not strictly narrower than kvm');
  }

  return violations;
}

/// Minimal, genuinely coherent synthetic scope declarations for EP-T38 tests.
const String syntheticScopeCliSource = '''
const List<String> kKvmScopePrefixes = <String>[
  'lib/features/kvm/',
];
const List<String> kKvmPlatformScopePrefixes = <String>[
  'lib/features/kvm/platform/',
];
''';

/// Minimal, genuinely threshold-floored synthetic CLI source for EP-T34 tests.
const String syntheticThresholdCliSource = '''
CoverageGateReport evaluateGates(
  CoverageSummary summary, {
  double overallThreshold = 0.75,
  double scopedThreshold = 0.80,
  Iterable<String> scopedPrefixes = kDefaultScopedPrefixes,
}) { ... }

const double kKvmThreshold = 0.75;

GateResult evaluateKvmGate(
  CoverageSummary summary, {
  double threshold = kKvmThreshold,
  Iterable<String> prefixes = kKvmScopePrefixes,
}) { ... }

GateResult evaluateKvmPlatformGate(
  CoverageSummary summary, {
  double threshold = kKvmThreshold,
  Iterable<String> prefixes = kKvmPlatformScopePrefixes,
}) { ... }
''';

/// Minimal, genuinely wired synthetic sources for the pure evaluator tests.
const String syntheticCliSource = '''
CoverageGateReport evaluateAllGates(CoverageSummary summary) {
  return CoverageGateReport(<GateResult>[
    ...evaluateGates(summary).results,
    evaluateKvmGate(summary),
    evaluateKvmPlatformGate(summary),
  ]);
}
const String kDefaultLcovPath = 'coverage/lcov.info';
Future<void> main(List<String> args) async {
  final CoverageGateReport report = evaluateAllGates(summary);
  exitCode = report.passed ? 0 : 1;
}
''';

const String syntheticVerifySource = '''
      - name: Test with coverage
        run: flutter test --coverage
      - name: Enforce coverage gates
        run: dart run tool/coverage_gate.dart coverage/lcov.info
''';

void main() {
  group('parseLcov', () {
    test('parses SF/LF/LH records and handles a trailing record', () {
      final String lcov = [
        record('lib/redfish/a.dart', 10, 8),
        // Final record intentionally has no end_of_record.
        'SF:lib/features/power/b.dart\nLF:4\nLH:1',
      ].join('\n');

      final CoverageSummary summary = parseLcov(lcov);

      expect(summary.files, hasLength(2));
      expect(summary.files.first.path, 'lib/redfish/a.dart');
      expect(summary.files.first.linesFound, 10);
      expect(summary.files.first.linesHit, 8);
      expect(summary.files.last.path, 'lib/features/power/b.dart');
      expect(summary.files.last.linesHit, 1);
    });

    test('empty input yields an empty, zero-coverage summary', () {
      final CoverageSummary summary = parseLcov('');
      expect(summary.files, isEmpty);
      expect(summary.overallCoverage, 0.0);
    });

    test('ignores CRLF and unrelated lcov lines', () {
      final CoverageSummary summary = parseLcov(
        'TN:\r\nSF:lib/x.dart\r\nBRDA:1,0,0,1\r\nLF:2\r\nLH:2\r\n'
        'end_of_record\r\n',
      );
      expect(summary.files, hasLength(1));
      expect(summary.files.single.coverage, 1.0);
    });
  });

  group('CoverageFile / CoverageSummary', () {
    test('file coverage handles hit ratio and zero instrumented lines', () {
      expect(const CoverageFile('a', 10, 8).coverage, closeTo(0.8, 1e-9));
      expect(const CoverageFile('a', 0, 0).coverage, 1.0);
    });

    test('overall coverage aggregates hits and found across files', () {
      final CoverageSummary summary = parseLcov([
        record('lib/a.dart', 10, 8),
        record('lib/b.dart', 10, 6),
      ].join('\n'));
      expect(summary.totalLinesFound, 20);
      expect(summary.totalLinesHit, 14);
      expect(summary.overallCoverage, closeTo(0.7, 1e-9));
    });
  });

  group('CoverageSummary.scope', () {
    final CoverageSummary summary = parseLcov([
      record('/home/me/app/lib/redfish/discovery/engine.dart', 10, 9),
      record('lib/features/power/power_service.dart', 10, 8),
      record(r'lib\features\sensors\sensors_service.dart', 10, 7),
      record('lib/features/firmware/firmware_service.dart', 10, 2),
    ].join('\n'));

    test('matches absolute, relative and Windows-separated source paths', () {
      final CoverageSummary scoped = summary.scope(kDefaultScopedPrefixes);
      expect(scoped.files, hasLength(3));
      expect(
        scoped.files.map((CoverageFile f) => f.path),
        containsAll(<String>[
          '/home/me/app/lib/redfish/discovery/engine.dart',
          'lib/features/power/power_service.dart',
          r'lib\features\sensors\sensors_service.dart',
        ]),
      );
      expect(
        scoped.files.map((CoverageFile f) => f.path),
        isNot(contains('lib/features/firmware/firmware_service.dart')),
      );
    });

    test('an empty scope reports zero coverage', () {
      final CoverageSummary scoped = summary.scope(const <String>[
        'lib/nonexistent/',
      ]);
      expect(scoped.files, isEmpty);
      expect(scoped.overallCoverage, 0.0);
    });
  });

  group('evaluateGates', () {
    test('passes when both overall and scoped thresholds are met', () {
      final CoverageSummary summary = parseLcov([
        record('lib/redfish/a.dart', 100, 82),
        record('lib/features/power/b.dart', 100, 80),
        record('lib/features/sensors/c.dart', 100, 81),
        record('lib/other/d.dart', 100, 60),
      ].join('\n'));

      final CoverageGateReport report = evaluateGates(summary);

      expect(report.results, hasLength(2));
      expect(report.results.first.name, 'overall');
      expect(report.results.last.name, 'redfish + power + sensors');
      expect(report.failures, isEmpty);
      expect(report.passed, isTrue);
    });

    test('fails when the aggregated scoped coverage falls below its threshold',
        () {
      // Overall still clears 75%, but the redfish+power+sensors union is only
      // 74.3% — below the 80% scoped gate — so only that gate fails.
      final CoverageSummary summary = parseLcov([
        record('lib/redfish/a.dart', 100, 75),
        record('lib/features/power/b.dart', 100, 78),
        record('lib/features/sensors/c.dart', 100, 70),
        record('lib/other/d.dart', 100, 90),
      ].join('\n'));

      final CoverageGateReport report = evaluateGates(summary);

      expect(report.passed, isFalse);
      expect(report.failures, hasLength(1));
      expect(report.failures.single.name, 'redfish + power + sensors');
    });

    test('honours custom thresholds and prefix sets', () {
      final CoverageSummary summary = parseLcov([
        record('pkg/a.dart', 10, 7),
        record('pkg/b.dart', 10, 7),
      ].join('\n'));

      final CoverageGateReport tight = evaluateGates(
        summary,
        overallThreshold: 0.8,
        scopedThreshold: 0.9,
        scopedPrefixes: const <String>['pkg/'],
      );
      expect(tight.results.first.passed, isFalse); // 70% < 80%
      expect(tight.results.last.passed, isFalse); // 70% < 90%

      final CoverageGateReport loose = evaluateGates(
        summary,
        overallThreshold: 0.7,
        scopedThreshold: 0.7,
        scopedPrefixes: const <String>['pkg/'],
      );
      expect(loose.passed, isTrue); // exactly at both thresholds
    });
  });

  group('remote-KVM coverage gate (#009)', () {
    test('evaluateKvmGate scopes only features/kvm at the 75% threshold', () {
      final CoverageSummary summary = parseLcov([
        record('lib/features/kvm/kvm_service.dart', 100, 76),
        record('lib/features/kvm/models/kvm_capability.dart', 100, 74),
        record('lib/features/firmware/firmware_service.dart', 100, 10),
      ].join('\n'));

      final GateResult gate = evaluateKvmGate(summary);

      expect(gate.name, 'kvm');
      expect(gate.threshold, kKvmThreshold);
      expect(kKvmThreshold, 0.75);
      // KVM union = (76 + 74) / 200 = 75% — exactly at threshold => pass.
      expect(gate.linesFound, 200);
      expect(gate.linesHit, 150);
      expect(gate.passed, isTrue);
    });

    test('evaluateKvmGate fails below 75% and ignores non-KVM files', () {
      final CoverageSummary summary = parseLcov([
        record('lib/features/kvm/kvm_service.dart', 100, 74),
        record('lib/features/firmware/firmware_service.dart', 100, 100),
      ].join('\n'));

      final GateResult gate = evaluateKvmGate(summary);

      expect(gate.linesFound, 100); // firmware file not counted
      expect(gate.passed, isFalse); // 74% < 75%
    });

    test('evaluateKvmGate honours a custom threshold and prefix set', () {
      final CoverageSummary summary = parseLcov([
        record('pkg/a.dart', 10, 9),
        record('other/b.dart', 10, 0),
      ].join('\n'));

      final GateResult gate = evaluateKvmGate(
        summary,
        threshold: 0.9,
        prefixes: const <String>['pkg/'],
      );

      expect(gate.linesFound, 10);
      expect(gate.threshold, 0.9);
      expect(gate.passed, isTrue); // 90% meets the custom 90% threshold
    });

    test('evaluateKvmGate matches absolute and Windows-separated paths', () {
      final CoverageSummary summary = parseLcov([
        record('/home/me/app/lib/features/kvm/kvm_service.dart', 10, 8),
        record(r'lib\features\kvm\views\kvm_view.dart', 10, 8),
      ].join('\n'));

      final GateResult gate = evaluateKvmGate(summary);

      expect(gate.linesFound, 20);
      expect(gate.linesHit, 16);
      expect(gate.passed, isTrue);
    });

    test(
        'evaluateAllGates enforces #010, the #009 KVM gate and the platform gate',
        () {
      final CoverageSummary summary = parseLcov([
        record('lib/redfish/a.dart', 100, 90),
        record('lib/features/power/b.dart', 100, 90),
        record('lib/features/sensors/c.dart', 100, 90),
        record('lib/features/kvm/kvm_service.dart', 100, 90),
        record('lib/features/kvm/platform/launch_plan.dart', 100, 90),
        record('lib/other/d.dart', 100, 90),
      ].join('\n'));

      final CoverageGateReport report = evaluateAllGates(summary);

      expect(report.results, hasLength(4));
      expect(
        report.results.map((GateResult g) => g.name),
        <String>['overall', 'redfish + power + sensors', 'kvm', 'kvm-platform'],
      );
      expect(report.failures, isEmpty);
      expect(report.passed, isTrue);
    });

    test(
        'evaluateAllGates fails when only the KVM aggregate is below threshold',
        () {
      final CoverageSummary summary = parseLcov([
        record('lib/redfish/a.dart', 100, 90),
        record('lib/features/power/b.dart', 100, 90),
        record('lib/features/sensors/c.dart', 100, 90),
        record('lib/features/kvm/kvm_service.dart', 100, 50),
        record('lib/features/kvm/platform/launch_plan.dart', 100, 90),
        record('lib/other/d.dart', 100, 90),
      ].join('\n'));

      final CoverageGateReport report = evaluateAllGates(summary);

      expect(report.results, hasLength(4));
      expect(report.failures, hasLength(1));
      expect(report.failures.single.name, 'kvm');
      expect(report.passed, isFalse);
    });

    test(
        'evaluateAllGates fails when only the platform gate is below threshold',
        () {
      final CoverageSummary summary = parseLcov([
        record('lib/redfish/a.dart', 100, 90),
        record('lib/features/power/b.dart', 100, 90),
        record('lib/features/sensors/c.dart', 100, 90),
        // Heavy, fully-covered non-platform KVM code keeps the wide aggregate
        // at (300 + 50) / 400 = 87.5% — only the dedicated gate fails closed.
        record('lib/features/kvm/kvm_service.dart', 300, 300),
        record('lib/features/kvm/platform/launch_plan.dart', 100, 50),
        record('lib/other/d.dart', 100, 90),
      ].join('\n'));

      final CoverageGateReport report = evaluateAllGates(summary);

      expect(report.results, hasLength(4));
      expect(report.failures, hasLength(1));
      expect(report.failures.single.name, 'kvm-platform');
      expect(report.passed, isFalse);
    });
  });

  group('KVM platform decision-layer gate (#009/#021 / EP-T3)', () {
    test('evaluateKvmPlatformGate scopes only platform/** at 75%', () {
      final CoverageSummary summary = parseLcov([
        record('lib/features/kvm/platform/launch_plan.dart', 100, 75),
        record('lib/features/kvm/platform/webview_policy.dart', 100, 75),
        record('lib/features/kvm/kvm_service.dart', 100, 0),
        record('lib/features/kvm/models/kvm_models.dart', 100, 0),
      ].join('\n'));

      final GateResult gate = evaluateKvmPlatformGate(summary);

      expect(gate.name, 'kvm-platform');
      expect(gate.threshold, kKvmThreshold);
      expect(gate.threshold, 0.75);
      // Platform union = (75 + 75) / 200 = 75% — exactly at threshold => pass.
      expect(gate.linesFound, 200);
      expect(gate.linesHit, 150);
      expect(gate.passed, isTrue);
    });

    test('a well-covered KVM aggregate cannot mask an uncovered platform file',
        () {
      final CoverageSummary summary = parseLcov([
        // Everything outside platform/** is fully covered.
        record('lib/features/kvm/kvm_service.dart', 100, 100),
        record('lib/features/kvm/models/kvm_models.dart', 100, 100),
        record('lib/features/kvm/views/kvm_view.dart', 100, 100),
        // One brand-new platform adapter is entirely uncovered.
        record('lib/features/kvm/platform/new_adapter.dart', 100, 0),
      ].join('\n'));

      // The wide aggregate passes (300/400 = 75%)...
      expect(evaluateKvmGate(summary).passed, isTrue);
      // ...but the dedicated decision-layer gate fails closed (0/100 = 0%).
      final GateResult platform = evaluateKvmPlatformGate(summary);
      expect(platform.linesFound, 100);
      expect(platform.linesHit, 0);
      expect(platform.passed, isFalse);
    });

    test('evaluateKvmPlatformGate honours a custom threshold and prefix set',
        () {
      final CoverageSummary summary = parseLcov([
        record('pkg/platform/a.dart', 10, 9),
        record('pkg/model/b.dart', 10, 0),
      ].join('\n'));

      final GateResult gate = evaluateKvmPlatformGate(
        summary,
        threshold: 0.9,
        prefixes: const <String>['pkg/platform/'],
      );

      expect(gate.linesFound, 10);
      expect(gate.threshold, 0.9);
      expect(gate.passed, isTrue); // 90% meets the custom 90% threshold
    });

    test('evaluateKvmPlatformGate matches absolute and Windows paths', () {
      final CoverageSummary summary = parseLcov([
        record('/home/me/app/lib/features/kvm/platform/a.dart', 10, 8),
        record(r'lib\features\kvm\platform\sub\b.dart', 10, 8),
      ].join('\n'));

      final GateResult gate = evaluateKvmPlatformGate(summary);

      expect(gate.linesFound, 20);
      expect(gate.linesHit, 16);
      expect(gate.passed, isTrue);
    });

    test(
        'an empty platform scope fails closed (missing/renamed decision layer)',
        () {
      final CoverageSummary summary = parseLcov([
        record('lib/features/kvm/kvm_service.dart', 100, 100),
      ].join('\n'));

      final GateResult gate = evaluateKvmPlatformGate(summary);

      expect(gate.linesFound, 0);
      expect(gate.passed, isFalse);
    });
  });

  group('machine-readable report (CI --json mode)', () {
    test('GateResult.toJson exposes pass state, ratios and raw counts', () {
      final Map<String, dynamic> json =
          const GateResult('overall', 8, 10, 0.75).toJson();

      expect(json['name'], 'overall');
      expect(json['passed'], isTrue);
      expect(json['linesHit'], 8);
      expect(json['linesFound'], 10);
      expect(json['coverage'], closeTo(0.8, 1e-9));
      expect(json['threshold'], 0.75);
    });

    test('CoverageGateReport.toJson encodes every gate result and passed', () {
      final CoverageGateReport report = evaluateGates(parseLcov([
        record('lib/redfish/a.dart', 100, 82),
        record('lib/features/power/b.dart', 100, 80),
        record('lib/features/sensors/c.dart', 100, 81),
        record('lib/other/d.dart', 100, 60),
      ].join('\n')));

      final String encoded = jsonEncode(report.toJson());
      final Map<String, dynamic> decoded =
          jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['passed'], isTrue);
      final List<dynamic> results = decoded['results'] as List<dynamic>;
      expect(results, hasLength(2));
      expect(
        results.map((dynamic r) => r['name'] as String),
        <String>['overall', 'redfish + power + sensors'],
      );
      expect(results.every((dynamic r) => r['passed'] as bool), isTrue);
    });

    test(
        'the CLI report (evaluateAllGates) serializes the platform gate for CI',
        () {
      final CoverageGateReport report = evaluateAllGates(parseLcov([
        record('lib/redfish/a.dart', 100, 90),
        record('lib/features/power/b.dart', 100, 90),
        record('lib/features/sensors/c.dart', 100, 90),
        record('lib/features/kvm/kvm_service.dart', 100, 90),
        record('lib/features/kvm/platform/launch_plan.dart', 100, 90),
      ].join('\n')));

      final Map<String, dynamic> decoded =
          jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>;

      expect(decoded['passed'], isTrue);
      final List<dynamic> results = decoded['results'] as List<dynamic>;
      expect(results, hasLength(4));
      expect(
        results.map((dynamic r) => r['name'] as String),
        <String>['overall', 'redfish + power + sensors', 'kvm', 'kvm-platform'],
      );
      expect(results.last['name'], 'kvm-platform');
      expect(results.last['threshold'], 0.75);
    });

    test('a failing gate serializes passed:false for CI to read', () {
      final CoverageGateReport report = evaluateGates(parseLcov([
        record('lib/redfish/a.dart', 100, 40),
      ].join('\n')));

      final Map<String, dynamic> decoded =
          jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>;

      expect(decoded['passed'], isFalse);
      final List<dynamic> results = decoded['results'] as List<dynamic>;
      expect(results.first['passed'], isFalse);
    });
  });

  group('parseGateCliArgs', () {
    test('defaults to the standard lcov path with text output', () {
      final GateCliOptions options = parseGateCliArgs(const <String>[]);
      expect(options.path, kDefaultLcovPath);
      expect(options.json, isFalse);
    });

    test('accepts a positional path and the --json flag in either order', () {
      final GateCliOptions first =
          parseGateCliArgs(const <String>['out/lcov.info', '--json']);
      expect(first.path, 'out/lcov.info');
      expect(first.json, isTrue);

      final GateCliOptions second =
          parseGateCliArgs(const <String>['--json', 'out/lcov.info']);
      expect(second.path, 'out/lcov.info');
      expect(second.json, isTrue);
    });

    test('rejects unknown flags and a second positional path', () {
      expect(
        () => parseGateCliArgs(const <String>['--nope']),
        throwsArgumentError,
      );
      expect(
        () => parseGateCliArgs(const <String>['a.info', 'b.info']),
        throwsArgumentError,
      );
    });
  });

  group('coverage-gate CLI/CI wiring (EP-T31)', () {
    test('fully wired CLI + CI has no drift', () {
      expect(
        evaluateCoverageGateWiring(
          syntheticCliSource,
          syntheticVerifySource,
        ),
        isEmpty,
      );
    });

    test('dropping the kvm-platform gate builder fails closed', () {
      final String mutated = syntheticCliSource.replaceFirst(
        '    evaluateKvmPlatformGate(summary),\n',
        '',
      );
      expect(
        evaluateCoverageGateWiring(mutated, syntheticVerifySource),
        contains(
            'CLI: evaluateAllGates no longer calls evaluateKvmPlatformGate('),
      );
    });

    test('renaming the kvm gate builder fails closed', () {
      final String mutated = syntheticCliSource.replaceFirst(
        'evaluateKvmGate(summary)',
        'evaluateKvmGateRenamed(summary)',
      );
      expect(
        evaluateCoverageGateWiring(mutated, syntheticVerifySource),
        contains('CLI: evaluateAllGates no longer calls evaluateKvmGate('),
      );
    });

    test('main calling the two-gate evaluateGates fails closed', () {
      final String mutated = syntheticCliSource.replaceFirst(
        'final CoverageGateReport report = evaluateAllGates(summary);',
        'final CoverageGateReport report = evaluateGates(summary);',
      );
      expect(
        evaluateCoverageGateWiring(mutated, syntheticVerifySource),
        contains('CLI: main() no longer invokes evaluateAllGates'),
      );
    });

    test('CI without the coverage-gate CLI step fails closed', () {
      final String mutated = syntheticVerifySource.replaceFirst(
        RegExp(r'.*coverage_gate\.dart.*\n'),
        '',
      );
      expect(
        evaluateCoverageGateWiring(syntheticCliSource, mutated),
        contains('CI: verify.yml no longer runs tool/coverage_gate.dart'),
      );
    });

    test('CI without flutter test --coverage fails closed', () {
      final String mutated = syntheticVerifySource.replaceFirst(
        RegExp(r'.*flutter test --coverage.*\n'),
        '',
      );
      expect(
        evaluateCoverageGateWiring(syntheticCliSource, mutated),
        contains('CI: verify.yml no longer runs "flutter test --coverage"'),
      );
    });

    test('temp-root RED→GREEN proves file-level wiring liveness', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t31_wiring_');
      try {
        final File cli = File('${temp.path}${Platform.pathSeparator}cli.dart');
        final File verify =
            File('${temp.path}${Platform.pathSeparator}verify.yml');
        cli.writeAsStringSync(syntheticCliSource);
        verify.writeAsStringSync(syntheticVerifySource);
        expect(
          evaluateCoverageGateWiring(
            cli.readAsStringSync(),
            verify.readAsStringSync(),
          ),
          isEmpty,
        );

        // Drop the kvm-platform gate from the on-disk CLI source: fails closed.
        cli.writeAsStringSync(
          syntheticCliSource.replaceFirst(
            '    evaluateKvmPlatformGate(summary),\n',
            '',
          ),
        );
        expect(
          evaluateCoverageGateWiring(
            cli.readAsStringSync(),
            verify.readAsStringSync(),
          ),
          contains(
              'CLI: evaluateAllGates no longer calls evaluateKvmPlatformGate('),
        );

        // Restore: clean once more.
        cli.writeAsStringSync(syntheticCliSource);
        expect(
          evaluateCoverageGateWiring(
            cli.readAsStringSync(),
            verify.readAsStringSync(),
          ),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('real repository: all four gates wired into CLI and CI', () {
      final File cli = File('tool/coverage_gate.dart');
      final File verify = File('.github/workflows/verify.yml');
      expect(cli.existsSync(), isTrue);
      expect(verify.existsSync(), isTrue);
      final List<String> violations = evaluateCoverageGateWiring(
        cli.readAsStringSync(),
        verify.readAsStringSync(),
      );
      expect(
        violations,
        isEmpty,
        reason: 'coverage-gate wiring drift: ${violations.join(', ')}',
      );
    });
  });

  group('coverage-gate threshold floors (EP-T34)', () {
    test('a floor-respecting source has no drift', () {
      expect(evaluateCoverageThresholdFloors(syntheticThresholdCliSource),
          isEmpty);
    });

    test('a lowered overall threshold fails closed', () {
      final String lowered = syntheticThresholdCliSource.replaceFirst(
        'double overallThreshold = 0.75',
        'double overallThreshold = 0.40',
      );
      expect(
        evaluateCoverageThresholdFloors(lowered),
        contains('overall threshold 0.4 below floor 0.75'),
      );
    });

    test('a lowered scoped threshold fails closed', () {
      final String lowered = syntheticThresholdCliSource.replaceFirst(
        'double scopedThreshold = 0.80',
        'double scopedThreshold = 0.50',
      );
      expect(
        evaluateCoverageThresholdFloors(lowered),
        contains('scoped threshold 0.5 below floor 0.8'),
      );
    });

    test('a lowered shared KVM constant fails closed for both KVM gates', () {
      final String lowered = syntheticThresholdCliSource.replaceFirst(
        'const double kKvmThreshold = 0.75',
        'const double kKvmThreshold = 0.50',
      );
      expect(
        evaluateCoverageThresholdFloors(lowered),
        contains('kvm threshold 0.5 below floor 0.75'),
      );
      expect(
        evaluateCoverageThresholdFloors(lowered),
        contains('kvm-platform threshold 0.5 below floor 0.75'),
      );
    });

    test('a KVM builder hardcoding a sub-floor literal fails closed', () {
      final String lowered = syntheticThresholdCliSource.replaceFirst(
        'GateResult evaluateKvmPlatformGate(\n'
            '  CoverageSummary summary, {\n'
            '  double threshold = kKvmThreshold,',
        'GateResult evaluateKvmPlatformGate(\n'
            '  CoverageSummary summary, {\n'
            '  double threshold = 0.50,',
      );
      expect(
        evaluateCoverageThresholdFloors(lowered),
        contains('kvm-platform threshold 0.5 below floor 0.75'),
      );
      // The sibling kvm gate still resolves the shared constant.
      expect(
        evaluateCoverageThresholdFloors(lowered),
        isNot(contains('kvm threshold 0.5 below floor 0.75')),
      );
    });

    test('a missing threshold default fails closed', () {
      final String removed = syntheticThresholdCliSource.replaceFirst(
        '  double overallThreshold = 0.75,\n',
        '',
      );
      expect(
        evaluateCoverageThresholdFloors(removed),
        contains('overall: threshold default not found'),
      );
    });

    test('temp-root RED→GREEN proves threshold-floor liveness', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t34_floors_');
      try {
        final File cli =
            File('${temp.path}${Platform.pathSeparator}coverage_gate.dart');
        cli.writeAsStringSync(syntheticThresholdCliSource);
        expect(
            evaluateCoverageThresholdFloors(cli.readAsStringSync()), isEmpty);

        // Lower the overall threshold on disk: fails closed.
        cli.writeAsStringSync(syntheticThresholdCliSource.replaceFirst(
          'double overallThreshold = 0.75',
          'double overallThreshold = 0.40',
        ));
        expect(
          evaluateCoverageThresholdFloors(cli.readAsStringSync()),
          contains('overall threshold 0.4 below floor 0.75'),
        );

        // Restore: clean once more.
        cli.writeAsStringSync(syntheticThresholdCliSource);
        expect(
            evaluateCoverageThresholdFloors(cli.readAsStringSync()), isEmpty);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('real repository: all four thresholds honour their floors', () {
      final File cli = File('tool/coverage_gate.dart');
      expect(cli.existsSync(), isTrue);
      final String source = cli.readAsStringSync();
      final List<String> violations = evaluateCoverageThresholdFloors(source);
      expect(
        violations,
        isEmpty,
        reason: 'threshold-floor drift: ${violations.join(', ')}',
      );
      // Pin the current values explicitly, not just the >= floors.
      expect(source, contains('double overallThreshold = 0.75'));
      expect(source, contains('double scopedThreshold = 0.80'));
      expect(source, contains('const double kKvmThreshold = 0.75'));
    });
  });

  group('coverage-gate scope coherence (EP-T38)', () {
    // Every prefix "exists" for the pure subset/presence drift cases; the
    // directory-existence dimension is exercised by the temp-root test below.
    bool allDirsExist(String _) => true;

    test('coherent synthetic scopes have no drift', () {
      expect(
        evaluateCoverageScopeCoherence(
          syntheticScopeCliSource,
          directoryExists: allDirsExist,
        ),
        isEmpty,
      );
    });

    test('a non-existent kvm prefix fails closed', () {
      expect(
        evaluateCoverageScopeCoherence(
          syntheticScopeCliSource,
          directoryExists: (String p) => !p.contains('features/kvm'),
        ),
        contains('kvm: scope prefix "lib/features/kvm/" is not an existing '
            'directory'),
      );
    });

    test('a non-existent kvm-platform prefix fails closed', () {
      final String mutated = syntheticScopeCliSource.replaceFirst(
        'lib/features/kvm/platform/',
        'lib/features/kvm/missing/',
      );
      expect(
        evaluateCoverageScopeCoherence(
          mutated,
          directoryExists: (String p) => !p.contains('missing'),
        ),
        contains(
            'kvm-platform: scope prefix "lib/features/kvm/missing/" is not '
            'an existing directory'),
      );
    });

    test('a kvm-platform prefix outside the kvm tree fails closed', () {
      final String mutated = syntheticScopeCliSource.replaceFirst(
        'lib/features/kvm/platform/',
        'lib/features/other/',
      );
      expect(
        evaluateCoverageScopeCoherence(
          mutated,
          directoryExists: allDirsExist,
        ),
        contains(
            'kvm-platform: prefix "lib/features/other/" is not nested under '
            'any kvm prefix'),
      );
    });

    test('widening kvm-platform to the whole kvm tree fails closed', () {
      final String mutated = syntheticScopeCliSource.replaceFirst(
        'lib/features/kvm/platform/',
        'lib/features/kvm/',
      );
      expect(
        evaluateCoverageScopeCoherence(
          mutated,
          directoryExists: allDirsExist,
        ),
        contains('kvm-platform: scope is not strictly narrower than kvm'),
      );
    });

    test('a missing scope declaration fails closed', () {
      final String mutated = syntheticScopeCliSource.replaceFirst(
        RegExp(r"const List<String> kKvmPlatformScopePrefixes = "
            r"<String>\[[\s\S]*?\];"),
        '',
      );
      expect(
        evaluateCoverageScopeCoherence(
          mutated,
          directoryExists: allDirsExist,
        ),
        contains('kvm-platform: no scope prefixes declared'),
      );
    });

    test('temp-root RED→GREEN proves scope-coherence liveness', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t38_scopes_');
      try {
        Directory('${temp.path}/lib/features/kvm/platform')
            .createSync(recursive: true);
        final File source =
            File('${temp.path}${Platform.pathSeparator}scopes.txt');
        source.writeAsStringSync(syntheticScopeCliSource);
        bool evaluate() => evaluateCoverageScopeCoherence(
              source.readAsStringSync(),
              directoryExists: (String p) =>
                  Directory('${temp.path}/$p').existsSync(),
            ).isEmpty;

        expect(evaluate(), isTrue);

        // RED: repoint kvm-platform at a non-existent directory on disk.
        source.writeAsStringSync(syntheticScopeCliSource.replaceFirst(
          'lib/features/kvm/platform/',
          'lib/features/kvm/gone/',
        ));
        expect(evaluate(), isFalse);

        // Restore: clean once more.
        source.writeAsStringSync(syntheticScopeCliSource);
        expect(evaluate(), isTrue);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('CoverageSummary.scope attributes files to kvm vs platform vs neither',
        () {
      final CoverageSummary summary = parseLcov([
        record('lib/features/kvm/models/kvm_capability.dart', 10, 8),
        record('lib/features/kvm/platform/launch_plan.dart', 10, 8),
        record('lib/features/power/power_service.dart', 10, 8),
      ].join('\n'));

      final List<String> kvmPaths = summary
          .scope(kKvmScopePrefixes)
          .files
          .map((CoverageFile f) => f.path)
          .toList();
      expect(
        kvmPaths,
        containsAll(<String>[
          'lib/features/kvm/models/kvm_capability.dart',
          'lib/features/kvm/platform/launch_plan.dart',
        ]),
      );
      expect(kvmPaths, hasLength(2)); // power/** is outside the kvm tree

      expect(
        summary
            .scope(kKvmPlatformScopePrefixes)
            .files
            .map((CoverageFile f) => f.path)
            .toList(),
        <String>['lib/features/kvm/platform/launch_plan.dart'],
      );
    });

    test('real repository: enforced KVM scopes exist and stay coherent', () {
      final File cli = File('tool/coverage_gate.dart');
      expect(cli.existsSync(), isTrue);
      final List<String> violations = evaluateCoverageScopeCoherence(
        cli.readAsStringSync(),
        directoryExists: (String p) => Directory(p).existsSync(),
      );
      expect(
        violations,
        isEmpty,
        reason: 'coverage scope drift: ${violations.join(', ')}',
      );
    });
  });
}
