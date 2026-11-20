// EP-T9 / epic #009/#021: machine-checkable closeout of the cross-surface
// "visible text == announced Semantics label" contract for the KVM
// *launch-status* messages. `kvmLaunchStatusText` in `kvm_models.dart` is the
// documented single source of truth for the detailed launch guidance shown on
// the per-console card and the full-screen viewer (the `insecureHtml5`,
// `insecureHttp`, `inAppHtml5`, `externalClient`, `secureBrowser`, `disabled`
// and `noUri` strings). The existing RU-2 notice guard pins the six shorter
// `kvm_transport_notice.dart` constants, but NOT these longer, more drift-prone
// sentences: a future edit could copy one into a `Text(...)` in a view and the
// two launch surfaces would silently drift for a screen reader.
//
// This guard derives the canonical literal fragments FROM the authority file at
// test time (so it can never itself be the stale duplicate), then fails closed
// if any other product `lib/features/kvm/**.dart` hardcodes one of those
// fragments or redefines the `kvmLaunchStatusText` function. It also pins that
// both launch surfaces still route through the shared function by identifier.
//
// Deliberately TEST-only, dependency-free, opens no network, reads only repo
// source, and never touches production TLS.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The single authority for the launch-status guidance copy.
const String authorityRelativePath = 'lib/features/kvm/models/kvm_models.dart';

/// Other copy-authority files that legitimately own shared strings (already
/// pinned by the RU-2 notice guard) and are not launch surfaces. A phrase that
/// is shared between the two authorities is not a hardcoded launch-surface
/// copy, so they are skipped by the drift scan.
const Set<String> otherCopyAuthorityPaths = <String>{
  'lib/features/kvm/views/kvm_transport_notice.dart',
};

/// The shared launch-status function that must live only in the authority.
const String statusFunctionName = 'kvmLaunchStatusText';

/// Minimum decoded length for a literal to count as a distinctive fingerprint
/// (short fragments like `'external console'` are intentionally ignored).
const int minFingerprintLength = 30;

/// One guard violation with the offending file and a human-readable reason.
class LaunchStatusViolation {
  final String file;
  final String reason;

  const LaunchStatusViolation(this.file, this.reason);

  @override
  String toString() => '$file: $reason';
}

/// Removes `//` line and `/* */` block comments while PRESERVING string
/// literals (so a `https://...` inside a string and a doc mention are handled
/// correctly). Tracks single/double and triple quotes; a comment marker inside
/// a string is not a comment. Kept intentionally small and local to this test.
String stripCommentsPreservingStrings(String source) {
  final StringBuffer buffer = StringBuffer();
  int i = 0;
  final int length = source.length;
  String? quote;
  bool triple = false;

  while (i < length) {
    final String char = source[i];
    if (quote != null) {
      if (triple && source.startsWith(quote * 3, i)) {
        buffer.write(quote * 3);
        i += 3;
        quote = null;
        triple = false;
        continue;
      }
      if (char == r'\' && i + 1 < length) {
        buffer.write(source.substring(i, i + 2));
        i += 2;
        continue;
      }
      if (!triple && char == quote) {
        buffer.write(char);
        i++;
        quote = null;
        continue;
      }
      buffer.write(char);
      i++;
      continue;
    }
    if (char == "'" || char == '"') {
      if (source.startsWith(char * 3, i)) {
        quote = char;
        triple = true;
        buffer.write(char * 3);
        i += 3;
      } else {
        quote = char;
        triple = false;
        buffer.write(char);
        i++;
      }
      continue;
    }
    if (char == '/' && i + 1 < length && source[i + 1] == '/') {
      i += 2;
      while (i < length && source[i] != '\n') {
        i++;
      }
      continue;
    }
    if (char == '/' && i + 1 < length && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < length && !(source[i] == '*' && source[i + 1] == '/')) {
        i++;
      }
      i = (i + 1 < length) ? i + 2 : length;
      continue;
    }
    buffer.write(char);
    i++;
  }
  return buffer.toString();
}

/// Decodes the simple escape sequences used by the authority literals.
String _decodeLiteral(String body) => body
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\\', r'\')
    .replaceAll(r'\n', '\n');

/// Extracts distinctive literal fingerprints from the `kvmLaunchStatusText`
/// body in [authoritySource]. Multi-line adjacent literals and the literal
/// pieces around `${externalProtocol}` interpolation are each their own
/// fingerprint. Nothing is hardcoded here: the values come from the file.
List<String> parseLaunchStatusFingerprints(String authoritySource) {
  final String clean = stripCommentsPreservingStrings(authoritySource);
  final int start = clean.indexOf('String $statusFunctionName(');
  if (start < 0) {
    throw StateError('missing $statusFunctionName in $authorityRelativePath');
  }
  // The function is followed by the `_uriString` helper (with its doc comment).
  final int end = clean.indexOf('String? _uriString(', start);
  if (end < 0) {
    throw StateError('missing _uriString marker after $statusFunctionName');
  }
  final String body = clean.substring(start, end);
  final RegExp literal = RegExp(r"'((?:[^'\\]|\\.)*)'", dotAll: true);
  final Set<String> fingerprints = <String>{};
  for (final RegExpMatch match in literal.allMatches(body)) {
    final String decoded = _decodeLiteral(match.group(1) ?? '').trim();
    if (decoded.length >= minFingerprintLength) fingerprints.add(decoded);
  }
  return fingerprints.toList()..sort();
}

/// Number of `case KvmLaunchStrategy.` branches in the authority function —
/// pinned so a future refactor cannot silently drop one of the seven messages.
int countStrategyCases(String authoritySource) {
  final String clean = stripCommentsPreservingStrings(authoritySource);
  final int start = clean.indexOf('String $statusFunctionName(');
  final int end = clean.indexOf('String? _uriString(', start);
  if (start < 0 || end < 0) return 0;
  return RegExp(r'case\s+KvmLaunchStrategy\.')
      .allMatches(
        clean.substring(start, end),
      )
      .length;
}

/// Fails closed when a non-authority product source hardcodes a launch-status
/// fingerprint or redefines the shared function. Returns all violations.
List<LaunchStatusViolation> evaluate({
  required List<({String path, String source})> sources,
  required List<String> fingerprints,
}) {
  final List<LaunchStatusViolation> violations = <LaunchStatusViolation>[];
  final RegExp redefine = RegExp(
    r'(?:String\??|const\s+String)\s+' + statusFunctionName + r'\s*\(',
  );
  for (final ({String path, String source}) item in sources) {
    final String normalized = item.path.replaceAll(r'\', '/');
    if (normalized == authorityRelativePath ||
        otherCopyAuthorityPaths.contains(normalized)) {
      continue;
    }
    final String code = stripCommentsPreservingStrings(item.source);

    for (final String fingerprint in fingerprints) {
      if (code.contains(fingerprint)) {
        violations.add(
          LaunchStatusViolation(
            item.path,
            'hardcodes the shared $statusFunctionName copy ("$fingerprint"); '
            'call the shared function so both launch surfaces cannot drift',
          ),
        );
      }
    }
    for (final RegExpMatch match in redefine.allMatches(code)) {
      violations.add(
        LaunchStatusViolation(
          item.path,
          'redefines $statusFunctionName; it must live only in '
          '$authorityRelativePath (match: "${match.group(0)}")',
        ),
      );
    }
  }
  return violations;
}

/// All product `lib/features/kvm/**.dart` sources, read from the real repo.
List<({String path, String source})> readRealSources() {
  final Directory featureDir = Directory('lib/features/kvm');
  if (!featureDir.existsSync()) {
    throw StateError('missing lib/features/kvm — wrong working directory');
  }
  return featureDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .map(
        (File f) => (
          path: f.path.replaceAll(r'\', '/'),
          source: f.readAsStringSync(),
        ),
      )
      .toList();
}

void main() {
  final String authoritySource = File(authorityRelativePath).readAsStringSync();
  final List<String> fingerprints =
      parseLaunchStatusFingerprints(authoritySource);

  group('EP-T9 launch-status single-source guard', () {
    test('authority defines all seven messages with distinctive fingerprints',
        () {
      expect(countStrategyCases(authoritySource), 7);
      // Each of the seven return messages is built from multiple adjacent
      // single-quoted literals, so there must be well more than seven
      // distinctive fragments.
      expect(fingerprints.length, greaterThanOrEqualTo(12));
      for (final String fingerprint in fingerprints) {
        expect(fingerprint.length, greaterThanOrEqualTo(minFingerprintLength));
      }
    });

    test('real repo product sources contain no hardcoded copy or redefinition',
        () {
      expect(
        evaluate(sources: readRealSources(), fingerprints: fingerprints),
        isEmpty,
      );
    });

    test('both launch surfaces route through the shared function', () {
      for (final String path in <String>[
        'lib/features/kvm/views/kvm_view.dart',
        'lib/features/kvm/views/kvm_console_viewer_page.dart',
      ]) {
        final String source = File(path).readAsStringSync();
        expect(
          source.contains('$statusFunctionName('),
          isTrue,
          reason: '$path must call the shared $statusFunctionName',
        );
      }
    });

    test('RED proof: a source hardcoding canonical copy is flagged', () {
      final Directory temp = Directory.systemTemp.createTempSync(
        'launch-status-guard-red-',
      );
      try {
        final String fingerprint = fingerprints.first;
        final File bad = File('${temp.path}/kvm_view_bad.dart')
          ..writeAsStringSync("Text('$fingerprint')");
        final List<LaunchStatusViolation> violations = evaluate(
          sources: <({String path, String source})>[
            (path: bad.path, source: bad.readAsStringSync()),
          ],
          fingerprints: fingerprints,
        );
        expect(violations, isNotEmpty);
        expect(violations.first.reason, contains('hardcodes'));
        expect(violations.first.reason, contains(statusFunctionName));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'RED proof: redefining the shared function outside authority is '
        'flagged', () {
      final Directory temp = Directory.systemTemp.createTempSync(
        'launch-status-guard-redefine-',
      );
      try {
        final File bad = File('${temp.path}/copy.dart')
          ..writeAsStringSync(
            'String $statusFunctionName(KvmLaunchStrategy s) => \'copy\';',
          );
        final List<LaunchStatusViolation> violations = evaluate(
          sources: <({String path, String source})>[
            (path: bad.path, source: bad.readAsStringSync()),
          ],
          fingerprints: fingerprints,
        );
        expect(violations, isNotEmpty);
        expect(violations.first.reason, contains('redefines'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('GREEN proof: identifier references, comments and URLs stay clean',
        () {
      final Directory temp = Directory.systemTemp.createTempSync(
        'launch-status-guard-green-',
      );
      try {
        final String fingerprint = fingerprints.first;
        final File good = File('${temp.path}/kvm_view_good.dart')
          ..writeAsStringSync(
            "Text($statusFunctionName(strategy)) "
            "// '$fingerprint'\n"
            '/* https://example.test/$statusFunctionName */\n'
            "final uri = 'https://example.test/';",
          );
        expect(
          evaluate(
            sources: <({String path, String source})>[
              (path: good.path, source: good.readAsStringSync()),
            ],
            fingerprints: fingerprints,
          ),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
