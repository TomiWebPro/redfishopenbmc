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
}
