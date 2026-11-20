// EP-T12 (epic #009/#021): machine-checkable closeout of the "who guards the
// guards" remainder. The repo now relies on a family of KVM safety guard tests
// (RU-2/EP-T9 copy, EP-T11 URI-parse, EP-T8 source-display, EP-P5 imports,
// EP-P6/P7/P8 policy/doc, EP-T7 doctor, LA-1 assets, EP-T6 unattended) — but
// nothing failed closed if one of those guard files was later deleted, emptied,
// stripped of its test cases, or silently de-invoked from the standard CI run.
// This pure-Dart guard enumerates the established guard files and fails closed
// on any such drift, so a future edit cannot silently disable a safety net.
//
// The evaluator lives in this TEST-only file so it never scans or touches
// product code. It is dependency-free, opens no network, uses no credentials,
// and never weakens production TLS. The RED→GREEN proof uses a temporary scan
// root; the real-repo invariant pins the checked-in guard suite + CI invocation.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The established KVM safety guard test files, stored as repo-relative,
/// forward-slash paths for cross-platform stability. This is the minimum set
/// named by EP-T12; adding a new guard to this list is cheap and intentional.
const List<String> canonicalGuardFiles = <String>[
  'test/tool/notice_single_source_guard_test.dart',
  'test/tool/launch_status_single_source_guard_test.dart',
  'test/tool/uri_parse_single_source_guard_test.dart',
  'test/tool/manager_source_display_guard_test.dart',
  'test/features/kvm/platform/product_import_policy_test.dart',
  'test/features/kvm/platform/production_route_invariant_test.dart',
  'test/features/kvm/platform/human_gate_doc_guard_test.dart',
  'test/features/kvm/platform/decision_doc_route_guard_test.dart',
];

/// Normalizes a path for comparison (Windows separators + a leading `./`).
String normalizePath(String path) =>
    path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

bool _isWordChar(String c) {
  final int u = c.codeUnitAt(0);
  return (u >= 48 && u <= 57) ||
      (u >= 65 && u <= 90) ||
      (u >= 97 && u <= 122) ||
      c == '_';
}

/// Removes `//` line comments, `/* */` block comments and string-literal
/// contents, keeping newlines. A guard file whose only "test(" appears in a
/// comment or string is NOT a live test case; scanning code tokens only keeps
/// this liveness guard honest (a commented-out guard cannot fake GREEN).
/// Raw strings (`r'...'`) are handled: a backslash is literal there, so `r'\'`
/// closes at the following quote instead of swallowing the rest of the file.
String stripCommentsAndStrings(String source) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  final int n = source.length;
  while (i < n) {
    final String c = source[i];
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      while (i < n && source[i] != '\n') {
        i++;
      }
      out.write(' ');
      continue;
    }
    if (c == '/' && i + 1 < n && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < n && !(source[i] == '*' && source[i + 1] == '/')) {
        i++;
      }
      i = i + 2 < n ? i + 2 : n;
      out.write(' ');
      continue;
    }
    if (c == "'" || c == '"') {
      final bool raw = i >= 1 &&
          (source[i - 1] == 'r' || source[i - 1] == 'R') &&
          (i < 2 || !_isWordChar(source[i - 2]));
      final String quote = c;
      final bool triple =
          i + 2 < n && source[i + 1] == quote && source[i + 2] == quote;
      i += triple ? 3 : 1;
      out.write(' ');
      while (i < n) {
        if (!raw && source[i] == r'\') {
          i += 2;
          continue;
        }
        if (triple) {
          if (i + 2 < n &&
              source[i] == quote &&
              source[i + 1] == quote &&
              source[i + 2] == quote) {
            i += 3;
            break;
          }
        } else if (source[i] == quote) {
          i += 1;
          break;
        }
        if (source[i] == '\n') {
          out.write('\n');
        }
        i++;
      }
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Number of live `test(...)` / `testWidgets(...)` cases in [source].
int countTestCases(String source) => RegExp(r'\btest(?:Widgets)?\s*\(')
    .allMatches(stripCommentsAndStrings(source))
    .length;

/// Evaluates a guard suite given a map of normalized path → file content and
/// the CI workflow source. Returns a list of fail-closed violations (empty means
/// the suite is intact). A missing path in [sources] is reported as MISSING.
List<String> evaluateGuardSuite(
  Map<String, String> sources,
  String verifySource,
) {
  final List<String> violations = <String>[];
  for (final String path in canonicalGuardFiles) {
    final String? source = sources[normalizePath(path)];
    if (source == null) {
      violations.add('MISSING: $path');
      continue;
    }
    if (source.trim().isEmpty) {
      violations.add('EMPTY: $path');
      continue;
    }
    if (countTestCases(source) == 0) {
      violations.add('NO_TEST_CASES: $path');
    }
  }
  // Reachable by the standard CI run: verify.yml must still invoke the
  // whole-tree `flutter test --coverage` (no path filter that could skip a
  // guard directory). Preserve the exact machine-checkable contract.
  final bool standardRun = RegExp(
    r'flutter\s+test\b[^\n]*--coverage',
  ).hasMatch(verifySource.replaceAll('\r', ''));
  if (!standardRun) {
    violations.add(
      'UNREACHABLE: verify.yml no longer runs "flutter test --coverage"',
    );
  }
  return violations;
}

/// Reads the canonical guard files present under [root] into a path → content
/// map. Missing files are omitted so [evaluateGuardSuite] reports MISSING.
Map<String, String> readSuite(Directory root) {
  final Map<String, String> sources = <String, String>{};
  for (final String path in canonicalGuardFiles) {
    final String rel = path.replaceAll('/', Platform.pathSeparator);
    final File file = File(
      '${root.path}${Platform.pathSeparator}$rel',
    );
    if (file.existsSync()) {
      sources[normalizePath(path)] = file.readAsStringSync();
    }
  }
  return sources;
}

/// Minimal but genuine synthetic guard source for the temp-root proof: one live
/// `test(...)` case, so it passes the liveness evaluator when intact.
const String syntheticGuardSource = '''
// synthetic guard
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('liveness', () {});
}
''';

void main() {
  group('EP-T12 guard-suite liveness evaluator (pure)', () {
    test('canonical inventory is non-empty and all files end in _test.dart',
        () {
      expect(canonicalGuardFiles, isNotEmpty);
      for (final String path in canonicalGuardFiles) {
        expect(path, endsWith('_test.dart'), reason: path);
        expect(path.startsWith('test/'), isTrue, reason: path);
      }
      // No duplicate entries that would mask a missing guard.
      expect(canonicalGuardFiles.toSet().length, canonicalGuardFiles.length);
    });

    test('intact synthetic suite + standard CI run is clean', () {
      final Map<String, String> sources = <String, String>{
        for (final String path in canonicalGuardFiles)
          normalizePath(path): syntheticGuardSource,
      };
      expect(
        evaluateGuardSuite(sources, '  run: flutter test --coverage\n'),
        isEmpty,
      );
    });

    test('commented-out test does not count as a live case', () {
      final String commented = stripCommentsAndStrings(
        "// test('fake', () {});\nvoid main() {}\n",
      );
      expect(RegExp(r'\btest\s*\(').hasMatch(commented), isFalse);
    });

    test('string-literal test( does not count as a live case', () {
      final String inString = stripCommentsAndStrings(
        "const String s = 'test( fake';\nvoid main() {}\n",
      );
      expect(RegExp(r'\btest\s*\(').hasMatch(inString), isFalse);
    });
  });

  group('EP-T12 RED→GREEN guard proof (temporary scan root)', () {
    test('missing / emptied / test-less / unreachable all fail closed', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t12_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync('  run: flutter test --coverage\n');

        // GREEN: everything intact.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: a guard file is deleted.
        File(p(canonicalGuardFiles[0])).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('MISSING:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[0])).writeAsStringSync(syntheticGuardSource);

        // RED 2: a guard file is emptied.
        File(p(canonicalGuardFiles[1])).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('EMPTY:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[1])).writeAsStringSync(syntheticGuardSource);

        // RED 3: a guard keeps prose but loses every test case.
        File(p(canonicalGuardFiles[2])).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('NO_TEST_CASES:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[2])).writeAsStringSync(syntheticGuardSource);

        // RED 4: CI no longer runs the whole-tree coverage suite.
        verify.writeAsStringSync('  run: echo nothing-to-see\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('UNREACHABLE:')),
          isTrue,
        );

        // GREEN again once the CI invocation is restored.
        verify.writeAsStringSync('  run: flutter test --coverage\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T12 real repository invariant', () {
    test('every established KVM safety guard is present, live and reachable',
        () {
      final File verify = File('.github/workflows/verify.yml');
      expect(verify.existsSync(), isTrue);
      final List<String> violations = evaluateGuardSuite(
          readSuite(Directory('.')), verify.readAsStringSync());
      expect(
        violations,
        isEmpty,
        reason: 'guard-suite drift: ${violations.join(", ")}',
      );
    });
  });
}
