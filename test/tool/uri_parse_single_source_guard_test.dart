// EP-T11 (epic #009/#021): machine-checkable closeout of the cross-surface
// classifier-parity remainder. EP-M1/M2 fixed degenerate hosts once, RM-5 pinned
// console↔capability agreement, but nothing mechanically prevented a future
// product file from reintroducing a raw `Uri.parse` / `Uri.tryParse` on a
// BMC-supplied console/source value (or a private duplicate of a shared
// control-safe/classifier helper), bypassing every fail-closed gate. This
// guard fails closed if any product `lib/features/kvm/**.dart` OUTSIDE the
// designated shared helper files does either.
//
// The evaluator lives in this TEST-only file so its raw tokens never appear in
// product `lib/` (which is exactly what it scans). It is dependency-free,
// opens no network, and never touches production TLS.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Shared helper files that OWN the raw URI parse / classifier helpers. A raw
/// `Uri.parse`/`Uri.tryParse` (or a private shared-helper definition) here is
/// legitimate; anywhere else in the KVM feature it is a fail-closed violation.
/// Stored as repo-relative, forward-slash paths for cross-platform stability.
const List<String> sharedHelperFiles = <String>[
  'lib/features/kvm/platform/launch_plan.dart',
  'lib/features/kvm/models/kvm_oem_uri.dart',
  'lib/features/kvm/models/kvm_manager_source.dart',
  'lib/features/kvm/models/kvm_session_limit.dart',
  'lib/features/kvm/platform/webview_policy.dart',
];

/// Distinctive PRIVATE top-level helpers owned by the shared files above. Dart
/// library privacy means no other library can legitimately reference these
/// names, so any occurrence in a non-shared file is a duplicate definition that
/// would re-implement (and drift from) the single fail-closed source of truth.
const List<String> sharedPrivateHelpers = <String>[
  '_controlSafeTrimmedUri',
  '_isHttpUriWithSchemes',
  '_authorityOf',
  '_hasDegenerateAuthorityHost',
  '_hasEmptyDnsLabel',
  '_hasNonCanonicalPort',
  '_isNonCanonicalNumericHost',
  '_authorityHasEncodedDot',
  '_authorityHasAsciiCompatibilityConfusable',
  '_findBlock',
  '_uriFromMap',
  '_consoleLikeBlock',
];

/// Normalizes a path for allowlist comparison (Windows separators + `./`).
String normalizePath(String path) =>
    path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

/// Whether [file] is one of the designated shared helper files.
bool isSharedHelper(String file) {
  final String path = normalizePath(file);
  return sharedHelperFiles.any(
    (String helper) => path == helper || path.endsWith('/$helper'),
  );
}

/// Removes `//` line comments, `/* */` block comments AND string-literal
/// contents, keeping delimiters and newlines. The guard scans CODE tokens: a
/// raw parse written in a comment or a doc string is not an executable bypass.
/// A small state machine tracks single/double and triple quotes so a comment
/// marker inside a string (e.g. `https://...`) is handled correctly.
String stripCommentsAndStrings(String source) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  final int length = source.length;
  String? quote;
  bool triple = false;

  while (i < length) {
    final String char = source[i];

    if (quote != null) {
      if (triple && source.startsWith(quote * 3, i)) {
        out.write(quote * 3);
        i += 3;
        quote = null;
        triple = false;
        continue;
      }
      if (char == r'\' && i + 1 < length) {
        i += 2; // blank an escaped character (incl. an escaped quote)
        continue;
      }
      if (!triple && char == quote) {
        out.write(char);
        i++;
        quote = null;
        continue;
      }
      if (char == '\n') out.write('\n'); // keep line structure
      i++;
      continue;
    }

    if (char == "'" || char == '"') {
      if (source.startsWith(char * 3, i)) {
        quote = char;
        triple = true;
        out.write(char * 3);
        i += 3;
      } else {
        quote = char;
        triple = false;
        out.write(char);
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
        if (source[i] == '\n') out.write('\n');
        i++;
      }
      i = (i + 1 < length) ? i + 2 : length;
      continue;
    }

    out.write(char);
    i++;
  }

  return out.toString();
}

final RegExp _rawUriParse = RegExp(r'\bUri\.(?:parse|tryParse)\s*\(');
final RegExp _duplicateHelper = RegExp(
  r'\b(?:' + sharedPrivateHelpers.join('|') + r')\s*\(',
);

/// One guard violation, with the offending file and a human-readable reason.
class UriParseViolation {
  final String file;
  final String reason;

  const UriParseViolation(this.file, this.reason);

  @override
  String toString() => '$file: $reason';
}

/// Scans one Dart source for a fail-closed single-source violation. Shared
/// helper files are immune (they own the tokens); every other file is scanned
/// regardless of its name.
List<UriParseViolation> scanDartSource(String file, String source) {
  if (isSharedHelper(file)) return <UriParseViolation>[];
  final String code = stripCommentsAndStrings(source);
  final List<UriParseViolation> violations = <UriParseViolation>[];

  if (_rawUriParse.hasMatch(code)) {
    violations.add(
      UriParseViolation(
        file,
        'raw Uri.parse/tryParse outside a designated shared helper',
      ),
    );
  }
  if (_duplicateHelper.hasMatch(code)) {
    violations.add(
      UriParseViolation(
        file,
        'duplicate private shared control-safe/classifier helper',
      ),
    );
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
  group('EP-T11 scanDartSource — fail-closed URI-parse single source', () {
    test('flags a raw Uri.parse in a product file', () {
      final List<UriParseViolation> v = scanDartSource(
        'lib/features/kvm/views/bad.dart',
        r'final Uri u = Uri.parse(raw);',
      );
      expect(v, isNotEmpty, reason: 'must fail closed on a raw Uri.parse');
      expect(v.first.reason, contains('raw Uri'));
    });

    test('flags a raw Uri.tryParse in a product file', () {
      final List<UriParseViolation> v = scanDartSource(
        'lib/features/kvm/models/bad.dart',
        r'final Uri? u = Uri.tryParse(value?.trim());',
      );
      expect(v, isNotEmpty, reason: 'must fail closed on a raw Uri.tryParse');
    });

    test('does NOT flag the raw parse in a designated shared helper', () {
      expect(
        scanDartSource(
          'lib/features/kvm/platform/launch_plan.dart',
          r'final Uri? parsed = Uri.tryParse(trimmed);',
        ),
        isEmpty,
      );
    });

    test('does NOT flag Uri.parse in comments or string literals', () {
      const String documented = r'''
// Uri.tryParse('x') is used only inside launch_plan.dart.
/// A raw Uri.parse here would bypass the fail-closed gate.
/* final u = Uri.tryParse(raw); */
const String note = 'call Uri.parse(raw) in a plain doc string';
''';
      expect(
        scanDartSource('lib/features/kvm/views/good.dart', documented),
        isEmpty,
      );
    });

    test('flags a duplicate private shared helper definition', () {
      final List<UriParseViolation> v = scanDartSource(
        'lib/features/kvm/models/bad.dart',
        r'String? _controlSafeTrimmedUri(String? s) => s;',
      );
      expect(v, isNotEmpty,
          reason: 'a duplicated private shared helper must fail closed');
      expect(v.first.reason, contains('duplicate'));
    });

    test('does NOT flag a call to a shared public helper', () {
      const String gated = r'''
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart';
final String? u = kvmOemConsoleUri(oem);
final bool safe = isControlSafeConsoleUri(candidate);
final int? limit = kvmSessionLimit(value);
''';
      expect(
        scanDartSource('lib/features/kvm/models/good.dart', gated),
        isEmpty,
      );
    });

    test('filename is not immunity — a stray launch_plan.dart is scanned', () {
      final List<UriParseViolation> v = scanDartSource(
        'lib/features/kvm/views/launch_plan.dart',
        r'final Uri? u = Uri.tryParse(raw);',
      );
      expect(v, isNotEmpty,
          reason: 'only the exact shared path is allowlisted, not the name');
    });
  });

  group('EP-T11 RED→GREEN guard proof (temporary scan root)', () {
    test('raw parse fails closed, shared-helper call is clean', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t11_guard_');
      try {
        File('${temp.path}${Platform.pathSeparator}raw.dart').writeAsStringSync(
          r'final Uri? u = Uri.tryParse(bmcSuppliedValue?.trim());',
        );
        File('${temp.path}${Platform.pathSeparator}gated.dart')
            .writeAsStringSync(
          'final bool safe = isControlSafeConsoleUri(bmcSuppliedValue);\n',
        );

        int rawViolations = 0;
        int gatedViolations = 0;
        for (final File file in productDartFiles(temp)) {
          final List<UriParseViolation> v =
              scanDartSource(file.path, file.readAsStringSync());
          if (file.path.endsWith('raw.dart')) rawViolations += v.length;
          if (file.path.endsWith('gated.dart')) gatedViolations += v.length;
        }
        expect(rawViolations, greaterThan(0), reason: 'RED: raw parse caught');
        expect(gatedViolations, 0, reason: 'GREEN: gated call is clean');
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T11 real repository invariant', () {
    test('no product KVM file bypasses the fail-closed URI-parse gate', () {
      final Directory root = Directory('lib/features/kvm');
      expect(root.existsSync(), isTrue);
      final List<File> files = productDartFiles(root);
      expect(files, isNotEmpty);

      final List<UriParseViolation> violations = <UriParseViolation>[];
      for (final File file in files) {
        violations.addAll(scanDartSource(file.path, file.readAsStringSync()));
      }
      expect(
        violations,
        isEmpty,
        reason: 'every raw URI parse must live in a designated shared helper; '
            'offenders: ${violations.join(", ")}',
      );
    });
  });
}
