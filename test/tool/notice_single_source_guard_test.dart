// RU-2 / epic #009/#021: machine-checkable closeout of the cross-surface
// "identical visible text == announced Semantics label" contract for the shared
// KVM notices. `kvm_transport_notice.dart` is documented as the single source of
// truth for the plaintext-HTTP, external-client, session-persistence,
// disabled-on-BMC and session-active/idle strings so a screen reader hears
// identical wording on every surface that shows them. Nothing previously pinned
// that invariant: a future edit could copy one of those sentences verbatim into
// a `Text(...)` in a view and the two surfaces would silently drift.
//
// This guard derives the canonical values FROM the authority file at test time
// (so it can never itself be the stale duplicate), then fails closed if any
// other product `lib/features/kvm/views/**.dart` hardcodes one of those values,
// or if a canonical constant is redefined outside the authority file.
//
// Deliberately TEST-only, dependency-free, opens no network, reads only repo
// source, and never touches production TLS.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The single authority for the shared, cross-surface KVM notice copy.
const String authorityRelativePath =
    'lib/features/kvm/views/kvm_transport_notice.dart';

/// Canonical `const String` notice names that must live only in the authority.
const List<String> canonicalNoticeNames = <String>[
  'kvmInsecureTransportNotice',
  'kvmExternalClientNotice',
  'kvmSessionPersistenceNotice',
  'kvmDisabledOnBmcNotice',
  'kvmSessionActiveNotice',
  'kvmSessionIdleNotice',
];

/// One guard violation with the offending file and a human-readable reason.
class NoticeViolation {
  final String file;
  final String reason;

  const NoticeViolation(this.file, this.reason);

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

/// Decodes the simple escape sequences used by the canonical notice literals.
String _decodeLiteral(String body) => body
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\\', r'\')
    .replaceAll(r'\n', '\n');

/// Parses `const String NAME = 'a' 'b';` declarations from the authority into
/// a map of name -> concatenated literal value. Handles the multi-line adjacent
/// string concatenation used by the longer notices. Comments are stripped first
/// so a doc mention of a name cannot be mistaken for a declaration.
Map<String, String> parseNoticeConstants(String authoritySource) {
  final String source = stripCommentsPreservingStrings(authoritySource);
  final Map<String, String> result = <String, String>{};
  final RegExp declaration = RegExp(
    r'const\s+String\s+(\w+)\s*=\s*([^;]*);',
    dotAll: true,
  );
  // Canonical notices are declared with single-quoted literals (possibly
  // adjacent across lines); match those and concatenate their contents.
  final RegExp literal = RegExp(r"'((?:[^'\\]|\\.)*)'", dotAll: true);
  for (final RegExpMatch match in declaration.allMatches(source)) {
    final String name = match.group(1)!;
    final String expression = match.group(2)!;
    final StringBuffer value = StringBuffer();
    for (final RegExpMatch lit in literal.allMatches(expression)) {
      value.write(_decodeLiteral(lit.group(1) ?? ''));
    }
    result[name] = value.toString();
  }
  return result;
}

/// Fails closed when a non-authority view hardcodes a canonical notice value or
/// redefines a canonical constant name. Returns all violations (empty == clean).
List<NoticeViolation> evaluate({
  required List<({String path, String source})> views,
  required Map<String, String> notices,
}) {
  final List<NoticeViolation> violations = <NoticeViolation>[];
  for (final ({String path, String source}) view in views) {
    if (view.path.replaceAll(r'\', '/') == authorityRelativePath) continue;
    final String code = stripCommentsPreservingStrings(view.source);

    for (final MapEntry<String, String> notice in notices.entries) {
      if (notice.value.isEmpty) continue;
      if (code.contains(notice.value)) {
        violations.add(
          NoticeViolation(
            view.path,
            'hardcodes the canonical ${notice.key} copy; reference the shared '
            'constant so both surfaces cannot drift ("${notice.value}")',
          ),
        );
      }
    }

    final RegExp redefine = RegExp(
      r'const\s+String\s+(' + canonicalNoticeNames.join('|') + r')\s*=',
    );
    for (final RegExpMatch match in redefine.allMatches(code)) {
      violations.add(
        NoticeViolation(
          view.path,
          'redefines canonical notice constant ${match.group(1)}; it must live '
          'only in $authorityRelativePath',
        ),
      );
    }
  }
  return violations;
}

/// All product KVM view sources, read from the real repo (used by the live gate).
List<({String path, String source})> readRealViews() {
  final Directory viewsDir = Directory('lib/features/kvm/views');
  if (!viewsDir.existsSync()) {
    throw StateError(
        'missing lib/features/kvm/views — wrong working directory');
  }
  return viewsDir
      .listSync()
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

  group('RU-2 shared-notice single-source guard', () {
    test('authority defines every canonical notice with a non-empty value', () {
      final Map<String, String> notices = parseNoticeConstants(authoritySource);
      for (final String name in canonicalNoticeNames) {
        expect(
          notices.containsKey(name),
          isTrue,
          reason: '$authorityRelativePath must define const String $name',
        );
        expect(
          notices[name]!.trim().isNotEmpty,
          isTrue,
          reason: '$name must not be an empty notice',
        );
      }
      // Prove multi-line adjacent literals were parsed, not just detected.
      expect(
        notices['kvmInsecureTransportNotice'],
        contains('Configure the BMC console to use HTTPS'),
      );
      expect(
        notices['kvmSessionPersistenceNotice'],
        contains('manager timeout'),
      );
    });

    test('real repo views contain no hardcoded or redefined notice copy', () {
      final Map<String, String> notices = parseNoticeConstants(authoritySource);
      expect(evaluate(views: readRealViews(), notices: notices), isEmpty);
    });

    test('RED proof: a view hardcoding canonical copy is flagged', () {
      final Map<String, String> notices = parseNoticeConstants(authoritySource);
      final String persistence = notices['kvmSessionPersistenceNotice']!;
      final Directory temp = Directory.systemTemp.createTempSync(
        'notice-guard-red-',
      );
      try {
        final File bad = File('${temp.path}/kvm_view_bad.dart')
          ..writeAsStringSync("Text('$persistence')");
        final List<NoticeViolation> violations = evaluate(
          views: <({String path, String source})>[
            (path: bad.path, source: bad.readAsStringSync()),
          ],
          notices: notices,
        );
        expect(violations, isNotEmpty);
        expect(
          violations.first.reason,
          contains('kvmSessionPersistenceNotice'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('GREEN proof: referencing the constant by name is clean', () {
      final Map<String, String> notices = parseNoticeConstants(authoritySource);
      final Directory temp = Directory.systemTemp.createTempSync(
        'notice-guard-green-',
      );
      try {
        final File good = File('${temp.path}/kvm_view_good.dart')
          ..writeAsStringSync(
            "Text(kvmSessionPersistenceNotice) // see $authorityRelativePath\n"
            '/* https://example.test/not-a-copy */',
          );
        expect(
          evaluate(
            views: <({String path, String source})>[
              (path: good.path, source: good.readAsStringSync()),
            ],
            notices: notices,
          ),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'RED proof: redefining a canonical constant name outside authority '
        'is flagged', () {
      final Map<String, String> notices = parseNoticeConstants(authoritySource);
      final Directory temp = Directory.systemTemp.createTempSync(
        'notice-guard-redefine-',
      );
      try {
        final File bad = File('${temp.path}/copy.dart')
          ..writeAsStringSync(
            "const String kvmDisabledOnBmcNotice = 'different wording';",
          );
        final List<NoticeViolation> violations = evaluate(
          views: <({String path, String source})>[
            (path: bad.path, source: bad.readAsStringSync()),
          ],
          notices: notices,
        );
        expect(violations, isNotEmpty);
        expect(
          violations.first.reason,
          contains('redefines canonical notice constant'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('comment mentions and URLs never trigger a false violation', () {
      final String commented =
          '// Text(\'${parseNoticeConstants(authoritySource)['kvmSessionIdleNotice']!}\')\n'
          '/* https://bmc.example/${canonicalNoticeNames.first} */\n'
          'final uri = \'https://example.test/\';';
      expect(
        evaluate(
          views: <({String path, String source})>[
            (path: 'lib/features/kvm/views/fake.dart', source: commented),
          ],
          notices: parseNoticeConstants(authoritySource),
        ),
        isEmpty,
      );
    });
  });
}
