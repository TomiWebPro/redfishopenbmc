// EP-T8 (epic #009/#021): machine-checkable closeout of the CB-1 class. CB-1
// (clipboard fallback), RM-4 (capability getter) and EP-U6 (three-surface
// display) routed every BMC-supplied manager source through the shared
// control-safe gate. This guard pins that invariant so no future edit can
// reintroduce a raw `@odata.id`-derived `sourceManagerUri` into a user-facing
// `Text` / `SelectableText` / `Semantics` label or a `Clipboard.setData`
// payload without going through `safeManagerUri` / `clipboardTargetUri` /
// `isControlSafeConsoleUri`.
//
// The evaluator is deliberately kept in this TEST-only file so its raw-source
// tokens never appear in product `lib/` (which is exactly what it scans). It is
// dependency-free, opens no network, and never touches production TLS.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The raw, BMC-supplied manager-source member/field token.
const String rawSourceToken = 'sourceManagerUri';

/// Tokens that prove a value has passed the shared control-safety gate.
const List<String> gateTokens = <String>[
  'safeManagerUri',
  'clipboardTargetUri',
  'isControlSafeConsoleUri',
];

/// One guard violation, with the offending file and a human-readable reason.
class ManagerSourceViolation {
  final String file;
  final String reason;

  const ManagerSourceViolation(this.file, this.reason);

  @override
  String toString() => '$file: $reason';
}

/// Removes `//` line and `/* */` block comments while PRESERVING string
/// literals (including URLs such as `https://...` inside strings). A small
/// state machine tracks single/double and triple-quoted strings so a comment
/// marker inside a string is not mistaken for a comment — unlike a naive
/// `replaceAll(r'//...')`, which would mangle the very strings we scan.
String stripCommentsPreservingStrings(String source) {
  final StringBuffer buffer = StringBuffer();
  int i = 0;
  final int length = source.length;
  String? quote;
  bool triple = false;

  while (i < length) {
    final String char = source[i];

    if (quote != null) {
      // Inside a string literal: copy verbatim, honouring escapes and the
      // triple-quote terminator, so `${...}` interpolations survive intact.
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

    // Enter a string literal (triple or single quoted).
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

    // Line comment: drop to (but not including) the newline.
    if (char == '/' && i + 1 < length && source[i + 1] == '/') {
      i += 2;
      while (i < length && source[i] != '\n') {
        i++;
      }
      continue;
    }

    // Block comment: drop through the closing `*/`.
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

/// Whether [expression] already routes the source through a control-safety
/// gate (in which case it is not a violation).
bool _isGated(String expression) =>
    gateTokens.any((String token) => expression.contains(token));

/// Scans one Dart source for a raw manager source reaching a display/clipboard
/// sink. `file` is used only for reporting (filename is never immunity).
List<ManagerSourceViolation> scanDartSource(String file, String source) {
  final String code = stripCommentsPreservingStrings(source);
  final List<ManagerSourceViolation> violations = <ManagerSourceViolation>[];

  // (1) Raw source interpolated into ANY string literal — the direct
  //     text/a11y-label injection vector: Text('${console.sourceManagerUri}').
  final RegExp interpolation = RegExp(r'\$\{([^}]*)\}');
  for (final RegExpMatch match in interpolation.allMatches(code)) {
    final String expression = match.group(1)!;
    if (expression.contains(rawSourceToken) && !_isGated(expression)) {
      violations.add(
        ManagerSourceViolation(
          file,
          'raw manager source interpolated into a string literal',
        ),
      );
    }
  }

  // (2) Raw source handed directly to a user-facing / clipboard constructor
  //     without interpolation, e.g. Text(console.sourceManagerUri) or
  //     Clipboard.setData(ClipboardData(text: console.sourceManagerUri)).
  //     A bounded window after each sink token keeps the check local to the
  //     sink's argument list instead of flagging unrelated code in the file.
  final RegExp sinkArgument = RegExp(
    r'\b(?:Clipboard\.setData|ClipboardData|SelectableText|Text|Semantics)\s*\(([^;]{0,240})',
    dotAll: true,
  );
  for (final RegExpMatch match in sinkArgument.allMatches(code)) {
    final String expression = match.group(1)!;
    if (expression.contains(rawSourceToken) && !_isGated(expression)) {
      violations.add(
        ManagerSourceViolation(
          file,
          'raw manager source passed to a user-facing/clipboard sink',
        ),
      );
    }
  }

  return violations;
}

/// Every product Dart source under [root] (recursive), sorted for stability.
List<File> productDartFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));
}

void main() {
  group('EP-T8 scanDartSource — raw manager-source sinks', () {
    test('flags a raw source interpolated into a widget Text', () {
      final List<ManagerSourceViolation> v = scanDartSource(
        'lib/features/kvm/views/bad.dart',
        "Text('No URI. Manager source: \${console.sourceManagerUri}'),\n",
      );
      expect(v, isNotEmpty, reason: 'must fail closed on raw display source');
      expect(v.first.reason, contains('interpolated'));
    });

    test('flags a raw source passed straight to Clipboard.setData', () {
      final List<ManagerSourceViolation> v = scanDartSource(
        'lib/features/kvm/views/bad.dart',
        'await Clipboard.setData(\n'
            '  ClipboardData(text: console.sourceManagerUri),\n'
            ');\n',
      );
      expect(v, isNotEmpty, reason: 'must fail closed on raw clipboard source');
    });

    test('flags a raw source passed straight to SelectableText', () {
      final List<ManagerSourceViolation> v = scanDartSource(
        'lib/features/kvm/views/bad.dart',
        'SelectableText(console.sourceManagerUri),\n',
      );
      expect(v, isNotEmpty);
    });

    test('does NOT flag a source routed through the safe gate', () {
      const String gated = '''
Text('Source: \${console.safeManagerUri}'),
SelectableText(capability.safeManagerUri),
await Clipboard.setData(ClipboardData(text: console.clipboardTargetUri));
''';
      expect(
          scanDartSource('lib/features/kvm/views/good.dart', gated), isEmpty);
    });

    test('does NOT flag the model gate getters themselves', () {
      const String getters = '''
String get safeManagerUri {
  if (isControlSafeConsoleUri(sourceManagerUri)) return sourceManagerUri;
  return '/redfish/v1/Managers/\$managerId';
}
String get clipboardTargetUri => launchPlan.targetUri ?? safeManagerUri;
''';
      expect(
        scanDartSource('lib/features/kvm/models/kvm_models.dart', getters),
        isEmpty,
      );
    });

    test('does NOT flag raw-source tokens in comments', () {
      const String documented = '''
/// Text('\${console.sourceManagerUri}') is forbidden — use safeManagerUri.
// Clipboard.setData(ClipboardData(text: console.sourceManagerUri)) is forbidden.
/* final s = console.sourceManagerUri; */
''';
      expect(scanDartSource('lib/features/kvm/views/good.dart', documented),
          isEmpty);
    });

    test('does NOT mangle https:// URLs inside preserved string literals', () {
      const String withUrl = '''
const String uri = 'https://bmc.example/redfish/v1/Managers/BMC';
Text('Source: \${console.safeManagerUri}');
''';
      expect(
          scanDartSource('lib/features/kvm/views/good.dart', withUrl), isEmpty);
    });

    test('filename is not immunity — a view-named file is still scanned', () {
      final List<ManagerSourceViolation> v = scanDartSource(
        'lib/features/kvm/views/kvm_view.dart',
        "Text('\${console.sourceManagerUri}'),\n",
      );
      expect(v, isNotEmpty,
          reason: 'a policy-named/product file must not bypass the guard');
    });
  });

  group('EP-T8 RED→GREEN guard proof (temporary scan root)', () {
    test('raw interpolation fails closed, gated value is clean', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t8_guard_');
      try {
        final File raw = File('${temp.path}${Platform.pathSeparator}raw.dart');
        raw.writeAsStringSync(
          "Text('Manager source: \${console.sourceManagerUri}'),\n",
        );
        final File gated =
            File('${temp.path}${Platform.pathSeparator}gated.dart');
        gated.writeAsStringSync(
          "Text('Manager source: \${console.safeManagerUri}'),\n",
        );

        int rawViolations = 0;
        int gatedViolations = 0;
        for (final File file in productDartFiles(temp)) {
          final List<ManagerSourceViolation> v =
              scanDartSource(file.path, file.readAsStringSync());
          if (file.path.endsWith('raw.dart')) rawViolations += v.length;
          if (file.path.endsWith('gated.dart')) gatedViolations += v.length;
        }
        expect(rawViolations, greaterThan(0), reason: 'RED: raw source caught');
        expect(gatedViolations, 0, reason: 'GREEN: gated source is clean');
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T8 real repository invariant', () {
    test('no product lib/**.dart sends a raw manager source to a sink', () {
      final Directory root = Directory('lib');
      expect(root.existsSync(), isTrue);
      final List<File> files = productDartFiles(root);
      expect(files, isNotEmpty);

      final List<ManagerSourceViolation> violations =
          <ManagerSourceViolation>[];
      for (final File file in files) {
        violations.addAll(scanDartSource(file.path, file.readAsStringSync()));
      }
      expect(
        violations,
        isEmpty,
        reason: 'product lib must route every manager source through the '
            'control-safe gate; offenders: ${violations.join(", ")}',
      );
    });
  });
}
