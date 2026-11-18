// Unit tests for the issue #010 coverage gate (tool/coverage_gate.dart).
//
// These are pure-Dart tests over inline lcov strings — no real coverage run or
// file I/O is needed, so `flutter test` never depends on `coverage/lcov.info`.
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
}
