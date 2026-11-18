/// Line-coverage gate for issue #010's "Testing gate" acceptance criterion.
///
/// Parses an lcov `lcov.info` file, aggregates line coverage overall and for a
/// configurable set of high-value source scopes (`lib/redfish/`,
/// `lib/features/power/`, `lib/features/sensors/`), and enforces thresholds.
///
/// The parsing/gating logic is pure Dart with no I/O so it can be unit-tested;
/// [main] is a thin CLI wrapper that reads a file and sets the process exit
/// code (0 = all gates pass, 1 = a gate failed, 2 = input error).
library;

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
}

/// Default high-value scopes that must clear [scopedThreshold] (#010 gate).
const List<String> kDefaultScopedPrefixes = <String>[
  'lib/redfish/',
  'lib/features/power/',
  'lib/features/sensors/',
];

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

Future<void> main(List<String> args) async {
  final String path = args.isEmpty ? 'coverage/lcov.info' : args.first;
  final File input = File(path);
  if (!input.existsSync()) {
    stderr.writeln('coverage gate: missing "$path" '
        '— run `flutter test --coverage` first.');
    exitCode = 2;
    return;
  }

  final CoverageSummary summary = parseLcov(input.readAsStringSync());
  final CoverageGateReport report = evaluateGates(summary);
  for (final GateResult result in report.results) {
    stdout.writeln(result.toString());
  }
  exitCode = report.passed ? 0 : 1;
}
