/// Line-coverage gate for issue #010's "Testing gate" acceptance criterion
/// and issue #009's "Coverage ≥75%" remote-KVM acceptance criterion.
///
/// Parses an lcov `lcov.info` file, aggregates line coverage overall and for a
/// configurable set of high-value source scopes (`lib/redfish/`,
/// `lib/features/power/`, `lib/features/sensors/`), plus the remote-KVM feature
/// scope (`lib/features/kvm/`) and its security-critical decision-layer
/// sub-scope (`lib/features/kvm/platform/`), and enforces thresholds.
///
/// The parsing/gating logic is pure Dart with no I/O so it can be unit-tested;
/// [main] is a thin CLI wrapper that reads a file and sets the process exit
/// code (0 = all gates pass, 1 = a gate failed, 2 = input error).
///
/// The `--json` flag emits a machine-readable [CoverageGateReport.toJson] payload
/// for CI consumers that need to annotate builds or archive gate results.
library;

import 'dart:convert';
import 'dart:io';

/// Line coverage for one source file from a single lcov record.
class CoverageFile {
  const CoverageFile(this.path, this.linesFound, this.linesHit);

  /// Source path as recorded in the `SF:` line.
  final String path;

  /// Number of instrumented lines (`LF:`).
  final int linesFound;

  /// Number of those lines that were hit (`LH:`).
  final int linesHit;

  /// Fraction of instrumented lines that were hit (1.0 for a file with none).
  double get coverage => linesFound == 0 ? 1.0 : linesHit / linesFound;

  @override
  String toString() =>
      '$path ${(coverage * 100).toStringAsFixed(1)}% ($linesHit/$linesFound)';
}

/// Aggregated coverage across every record in an lcov file.
class CoverageSummary {
  CoverageSummary(this.files);

  /// Records that had an `SF:` line, in file order.
  final List<CoverageFile> files;

  int get totalLinesFound => files.fold<int>(0, (sum, f) => sum + f.linesFound);
  int get totalLinesHit => files.fold<int>(0, (sum, f) => sum + f.linesHit);

  /// Overall line coverage (0.0 when nothing was instrumented).
  double get overallCoverage =>
      totalLinesFound == 0 ? 0.0 : totalLinesHit / totalLinesFound;

  /// A new summary containing only files whose path contains any of [prefixes].
  ///
  /// Prefixes are matched as normalized path substrings, so both relative
  /// (`lib/redfish/...`) and absolute (`/home/me/app/lib/redfish/...`) lcov
  /// source paths are handled. Backslashes are treated as separators so Windows
  /// lcov output matches too.
  CoverageSummary scope(Iterable<String> prefixes) {
    final List<String> needles =
        prefixes.map((p) => p.replaceAll(r'\', '/')).toList(growable: false);
    return CoverageSummary(
      files.where((CoverageFile file) {
        final String path = file.path.replaceAll(r'\', '/');
        return needles.any(path.contains);
      }).toList(growable: false),
    );
  }
}

/// The result of evaluating one threshold against one [CoverageSummary].
class GateResult {
  const GateResult(
    this.name,
    this.linesHit,
    this.linesFound,
    this.threshold,
  );

  final String name;
  final int linesHit;
  final int linesFound;
  final double threshold;

  double get coverage => linesFound == 0 ? 0.0 : linesHit / linesFound;
  bool get passed => coverage >= threshold;

  /// Machine-readable form of this gate result for CI consumers.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'passed': passed,
        'coverage': coverage,
        'threshold': threshold,
        'linesHit': linesHit,
        'linesFound': linesFound,
      };

  @override
  String toString() => '${passed ? 'PASS' : 'FAIL'} $name: '
      '${(coverage * 100).toStringAsFixed(1)}% '
      '(need ${(threshold * 100).toStringAsFixed(0)}%, '
      '$linesHit/$linesFound lines)';
}

/// A collection of [GateResult]s and their aggregate pass state.
class CoverageGateReport {
  const CoverageGateReport(this.results);

  final List<GateResult> results;

  bool get passed => results.every((GateResult r) => r.passed);
  List<GateResult> get failures =>
      results.where((GateResult r) => !r.passed).toList(growable: false);

  /// Machine-readable report for the `--json` CLI mode and CI artifacts.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'passed': passed,
        'results':
            results.map((GateResult r) => r.toJson()).toList(growable: false),
      };
}

/// Default high-value scopes that must clear [scopedThreshold] (#010 gate).
const List<String> kDefaultScopedPrefixes = <String>[
  'lib/redfish/',
  'lib/features/power/',
  'lib/features/sensors/',
];

/// Source prefixes identifying the remote-KVM feature (#009) implementation.
///
/// Kept separate from [kDefaultScopedPrefixes] because #009's acceptance value
/// is ≥75%, whereas the #010 high-value scopes are held to a stricter ≥80%.
const List<String> kKvmScopePrefixes = <String>[
  'lib/features/kvm/',
];

/// Source prefixes identifying the KVM platform decision layer (EP-T3).
///
/// `lib/features/kvm/platform/**` holds the security-critical, dependency-free
/// fail-closed URI/port classifier and the WebView-policy decision. It is the
/// most spoof-sensitive code in the KVM feature, so it gets its OWN gate rather
/// than being allowed to hide behind the wide `kKvmScopePrefixes` aggregate:
/// once new adapter files land there, a whole uncovered file can no longer be
/// diluted by the many already-well-covered model/view files in the KVM scope.
const List<String> kKvmPlatformScopePrefixes = <String>[
  'lib/features/kvm/platform/',
];

/// Minimum line coverage required for the remote-KVM feature (#009).
const double kKvmThreshold = 0.75;

/// Parses lcov text into a [CoverageSummary].
///
/// Only `SF:`, `LF:` and `LH:` records are used; a record is flushed on
/// `end_of_record` and any unfinished trailing record is flushed at EOF.
CoverageSummary parseLcov(String contents) {
  final List<CoverageFile> files = <CoverageFile>[];
  String? path;
  int linesFound = 0;
  int linesHit = 0;

  void flush() {
    if (path != null) {
      files.add(CoverageFile(path!, linesFound, linesHit));
    }
    path = null;
    linesFound = 0;
    linesHit = 0;
  }

  for (final String rawLine in contents.split(RegExp(r'\r?\n'))) {
    final String line = rawLine.trim();
    if (line == 'end_of_record') {
      flush();
    } else if (line.startsWith('SF:')) {
      flush();
      path = line.substring(3).trim();
    } else if (line.startsWith('LF:')) {
      linesFound = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      linesHit = int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }
  flush();
  return CoverageSummary(files);
}

/// Evaluates the overall and scoped thresholds for [summary].
CoverageGateReport evaluateGates(
  CoverageSummary summary, {
  double overallThreshold = 0.75,
  double scopedThreshold = 0.80,
  Iterable<String> scopedPrefixes = kDefaultScopedPrefixes,
}) {
  final CoverageSummary scoped = summary.scope(scopedPrefixes);
  return CoverageGateReport(<GateResult>[
    GateResult(
      'overall',
      summary.totalLinesHit,
      summary.totalLinesFound,
      overallThreshold,
    ),
    GateResult(
      'redfish + power + sensors',
      scoped.totalLinesHit,
      scoped.totalLinesFound,
      scopedThreshold,
    ),
  ]);
}

/// Evaluates the remote-KVM (#009) feature coverage gate.
///
/// Returns a single [GateResult] named `'kvm'` so CI artifacts can identify it.
/// It uses #009's dedicated 75% threshold, independent of the stricter #010
/// scoped gate, and shares [CoverageSummary.scope]'s path normalization so
/// relative, absolute and Windows-separated lcov paths all match.
GateResult evaluateKvmGate(
  CoverageSummary summary, {
  double threshold = kKvmThreshold,
  Iterable<String> prefixes = kKvmScopePrefixes,
}) {
  final CoverageSummary scoped = summary.scope(prefixes);
  return GateResult(
    'kvm',
    scoped.totalLinesHit,
    scoped.totalLinesFound,
    threshold,
  );
}

/// Evaluates the KVM platform decision-layer (#009/#021 / EP-T3) gate.
///
/// Returns a single [GateResult] named `'kvm-platform'` so CI artifacts can
/// identify it separately from the wide `'kvm'` aggregate. It reuses #009's
/// 75% threshold and [CoverageSummary.scope]'s path normalization, but scopes
/// only [kKvmPlatformScopePrefixes] so the fail-closed classifier cannot be
/// masked by unrelated KVM model/view coverage.
GateResult evaluateKvmPlatformGate(
  CoverageSummary summary, {
  double threshold = kKvmThreshold,
  Iterable<String> prefixes = kKvmPlatformScopePrefixes,
}) {
  final CoverageSummary scoped = summary.scope(prefixes);
  return GateResult(
    'kvm-platform',
    scoped.totalLinesHit,
    scoped.totalLinesFound,
    threshold,
  );
}

/// Evaluates every enforced gate: the #010 overall + scoped gates, the #009
/// remote-KVM aggregate gate, and the #009/#021 KVM platform decision-layer
/// gate (EP-T3).
///
/// The CLI/CI use this so all four thresholds are enforced in one report; the
/// narrower [evaluateGates] remains available for callers that only need the
/// #010 gates (and preserves its two-result contract).
CoverageGateReport evaluateAllGates(CoverageSummary summary) {
  return CoverageGateReport(<GateResult>[
    ...evaluateGates(summary).results,
    evaluateKvmGate(summary),
    evaluateKvmPlatformGate(summary),
  ]);
}

/// Default lcov path used when the CLI is called with no positional argument.
const String kDefaultLcovPath = 'coverage/lcov.info';

/// Parsed CLI options for the coverage gate.
class GateCliOptions {
  const GateCliOptions({required this.path, required this.json});

  /// Path to the lcov file to read.
  final String path;

  /// Whether to emit the machine-readable JSON report instead of text lines.
  final bool json;
}

/// Parses [args] into [GateCliOptions].
///
/// Accepts an optional `--json` flag and at most one positional lcov path.
/// Throws [ArgumentError] on an unknown flag or a second positional path so the
/// CLI can fail loudly (exit 2) instead of silently ignoring a typo'd option.
GateCliOptions parseGateCliArgs(List<String> args) {
  bool json = false;
  String? path;
  for (final String arg in args) {
    if (arg == '--json') {
      json = true;
    } else if (arg.startsWith('-')) {
      throw ArgumentError('unknown option: $arg');
    } else if (path == null) {
      path = arg;
    } else {
      throw ArgumentError('unexpected argument: $arg');
    }
  }
  return GateCliOptions(path: path ?? kDefaultLcovPath, json: json);
}

Future<void> main(List<String> args) async {
  late final GateCliOptions options;
  try {
    options = parseGateCliArgs(args);
  } on ArgumentError catch (error) {
    stderr.writeln('coverage gate: $error');
    exitCode = 2;
    return;
  }

  final String path = options.path;
  final File input = File(path);
  if (!input.existsSync()) {
    stderr.writeln('coverage gate: missing "$path" '
        '— run `flutter test --coverage` first.');
    exitCode = 2;
    return;
  }

  final CoverageSummary summary = parseLcov(input.readAsStringSync());
  final CoverageGateReport report = evaluateAllGates(summary);
  if (options.json) {
    stdout.writeln(jsonEncode(report.toJson()));
  } else {
    for (final GateResult result in report.results) {
      stdout.writeln(result.toString());
    }
  }
  exitCode = report.passed ? 0 : 1;
}
