// EP-P5 (epic #009/#021): machine-checkable guard for the RESOLVED platform
// decision recorded in WEBVIEW_TLS_MATRIX.md / LAUNCH_FALLBACK.md — the final
// console route is external-browser + copy with the in-app flag OFF. Product
// `lib/**.dart` must never import a WebView / external-launch / in-app-webview
// plugin or open a raw platform channel for console rendering, and pubspec must
// never carry such a dependency. This is the unattended (human-gate-free) slice
// of EP-P4's guard clause: it pins the invariant without adding a dependency,
// importing a plugin, changing a wire path, or weakening production TLS.
//
// The evaluator is deliberately kept in this TEST-only file so its forbidden
// tokens never appear in product `lib/` (which is exactly what the guard scans).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Forbidden package prefixes (the resolved no-embedded-WebView decision).
const List<String> forbiddenConsolePackages = <String>[
  'webview_flutter',
  'flutter_inappwebview',
  'url_launcher',
];

/// Raw channel constructor tokens that would re-introduce in-app rendering /
/// native console plumbing behind the guard's back.
const List<String> forbiddenChannelTokens = <String>[
  'MethodChannel',
  'EventChannel',
];

/// One policy violation, with the offending file and a human-readable reason.
class ImportPolicyViolation {
  final String file;
  final String reason;

  const ImportPolicyViolation(this.file, this.reason);

  @override
  String toString() => '$file: $reason';
}

/// Remove `//` line and `/* */` block comments. Comments are documentation, not
/// code, so a doc line such as "do not import `webview_flutter`" must not flag.
String stripLineAndBlockComments(String source) {
  final noBlocks = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return noBlocks.replaceAll(RegExp(r'//[^\n]*'), '');
}

/// Remove quoted string / triple-quoted string literals from already
/// comment-stripped source, so channel tokens inside prose or identifiers as
/// string data do not count as a raw channel construction.
String stripStringLiterals(String source) {
  var s = source.replaceAll(RegExp(r"'''[\s\S]*?'''"), "''");
  s = s.replaceAll(RegExp(r'"""[\s\S]*?"""'), '""');
  s = s.replaceAll(RegExp(r"'(?:\\.|[^'\\\n])*'"), "''");
  s = s.replaceAll(RegExp(r'"(?:\\.|[^"\\\n])*"'), '""');
  return s;
}

/// Scan one Dart source for forbidden console-rendering imports and raw
/// platform-channel usage. `file` is only used for reporting.
List<ImportPolicyViolation> scanDartSource(String file, String source) {
  final violations = <ImportPolicyViolation>[];
  final withoutComments = stripLineAndBlockComments(source);

  // (1) Forbidden package import/export directives. Anchoring at the start of
  // a line (after whitespace) means a commented-out `// import 'package:…'`
  // can never match — comments were stripped above anyway.
  // \x27 = "'", \x22 = "\"" in RegExp syntax (keeps this a valid raw string).
  final directive = RegExp(
    r"^\s*(?:import|export)\s+[\x27\x22]([^\x27\x22]+)[\x27\x22]",
    multiLine: true,
  );
  for (final match in directive.allMatches(withoutComments)) {
    final uri = match.group(1)!;
    for (final pkg in forbiddenConsolePackages) {
      if (uri == 'package:$pkg' || uri.startsWith('package:$pkg/')) {
        violations.add(
          ImportPolicyViolation(file, "forbidden console plugin import '$uri'"),
        );
      }
    }
  }

  // (2) Raw platform-channel construction for console rendering (word-boundary
  // + call paren). Strings are stripped first so prose/identifiers-as-data
  // do not trip it.
  final code = stripStringLiterals(withoutComments);
  for (final token in forbiddenChannelTokens) {
    if (RegExp('\\b$token\\s*\\(').hasMatch(code)) {
      violations.add(
        ImportPolicyViolation(file, 'raw $token platform-channel usage'),
      );
    }
  }

  return violations;
}

/// Scan a pubspec (yaml or lock) for a forbidden console plugin declared as a
/// dependency key. Indented `name:` keys are dependency declarations; prose
/// mentioning the name is not.
List<ImportPolicyViolation> scanPubspec(String file, String source) {
  final violations = <ImportPolicyViolation>[];
  final noComments = source.replaceAll(RegExp(r'#[^\n]*'), '');
  final depKey = RegExp(r'^\s+([A-Za-z0-9_]+)\s*:', multiLine: true);
  for (final match in depKey.allMatches(noComments)) {
    final name = match.group(1)!;
    for (final pkg in forbiddenConsolePackages) {
      if (name == pkg || name.startsWith('${pkg}_')) {
        violations.add(
          ImportPolicyViolation(
              file, "forbidden console plugin dependency '$name'"),
        );
      }
    }
  }
  return violations;
}

/// Every product Dart source under [root] (recursive), sorted for stability.
List<File> productDartFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  group('EP-P5 scanDartSource — forbidden console plugin imports', () {
    for (final pkg in forbiddenConsolePackages) {
      test("flags a real 'package:$pkg/...' import", () {
        final v = scanDartSource(
          'lib/bad.dart',
          "import 'package:$pkg/$pkg.dart';\n",
        );
        expect(v, isNotEmpty, reason: 'must fail closed on $pkg import');
        expect(v.first.reason, contains(pkg));
      });
    }

    test('flags export directives too', () {
      final v = scanDartSource(
        'lib/bad.dart',
        "export 'package:url_launcher/url_launcher.dart' show launchUrl;\n",
      );
      expect(v, isNotEmpty);
    });

    test('does not flag safe Flutter/Dart/package imports', () {
      const safe = '''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
''';
      expect(scanDartSource('lib/good.dart', safe), isEmpty);
    });
  });

  group('EP-P5 scanDartSource — raw platform channels', () {
    test('flags MethodChannel and EventChannel construction in code', () {
      expect(
        scanDartSource(
          'lib/bad.dart',
          "const ch = MethodChannel('kvm');\nfinal e = EventChannel('kvm/events');\n",
        ),
        hasLength(2),
      );
    });

    test('does not flag channel tokens in doc/line/block comments', () {
      const documented = '''
/// Never open a MethodChannel('kvm') for console rendering.
// EventChannel('kvm') is likewise forbidden.
/* const ch = MethodChannel('kvm'); */
import 'dart:async';
''';
      expect(scanDartSource('lib/webview_policy.dart', documented), isEmpty);
    });

    test('does not flag channel tokens inside string literals', () {
      const prose = "const String s = 'MethodChannel( is not used here';\n";
      expect(scanDartSource('lib/good.dart', prose), isEmpty);
    });
  });

  group('EP-P5 scanDartSource — filename is not immunity', () {
    test('flags a real forbidden import even in launch_plan.dart', () {
      final v = scanDartSource(
        'lib/features/kvm/platform/launch_plan.dart',
        "import 'package:webview_flutter/webview_flutter.dart';\n",
      );
      expect(v, isNotEmpty,
          reason: 'a policy/policy-named file must not bypass the guard');
    });

    test('the real webview_policy.dart doc comment is clean', () {
      final f = File('lib/features/kvm/platform/webview_policy.dart');
      expect(f.existsSync(), isTrue);
      expect(scanDartSource(f.path, f.readAsStringSync()), isEmpty);
    });
  });

  group('EP-P5 scanPubspec — forbidden dependencies', () {
    for (final pkg in forbiddenConsolePackages) {
      test("flags '$pkg' declared as a dependency", () {
        final yaml = 'dependencies:\n  dio: ^5.0.0\n  $pkg: ^1.0.0\n';
        final v = scanPubspec('pubspec.yaml', yaml);
        expect(v, isNotEmpty);
        expect(v.first.reason, contains(pkg));
      });
    }

    test('flags a transitive plugin entry in pubspec.lock', () {
      final lock = '  url_launcher:\n    dependency: transitive\n';
      expect(scanPubspec('pubspec.lock', lock), isNotEmpty);
    });

    test('ignores prose mentioning a plugin name', () {
      const yaml = '''
# we deliberately avoid url_launcher
description: >-
  No webview_flutter dependency is used; external browser + copy only.
dependencies:
  dio: ^5.0.0
''';
      expect(scanPubspec('pubspec.yaml', yaml), isEmpty);
    });
  });

  group('EP-P5 real repository invariant', () {
    test('no product lib/**.dart imports a forbidden console plugin', () {
      final root = Directory('lib');
      expect(root.existsSync(), isTrue);
      final files = productDartFiles(root);
      expect(files, isNotEmpty);

      final violations = <ImportPolicyViolation>[];
      for (final f in files) {
        violations.addAll(scanDartSource(f.path, f.readAsStringSync()));
      }
      expect(
        violations,
        isEmpty,
        reason: 'product lib must import no WebView/launcher plugin and open '
            'no raw channel; offenders: ${violations.join(", ")}',
      );
    });

    test('no raw platform channel is opened in product lib', () {
      final root = Directory('lib');
      final violations = <ImportPolicyViolation>[];
      for (final f in productDartFiles(root)) {
        for (final v in scanDartSource(f.path, f.readAsStringSync())) {
          if (v.reason.contains('platform-channel')) violations.add(v);
        }
      }
      expect(violations, isEmpty,
          reason: 'offenders: ${violations.join(", ")}');
    });

    for (final pubspec in const <String>['pubspec.yaml', 'pubspec.lock']) {
      test('$pubspec carries no forbidden console plugin dependency', () {
        final f = File(pubspec);
        expect(f.existsSync(), isTrue, reason: '$pubspec must exist');
        expect(scanPubspec(pubspec, f.readAsStringSync()), isEmpty);
      });
    }
  });
}
