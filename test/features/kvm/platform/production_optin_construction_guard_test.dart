// EP-P10 (epic #009/#021): machine-checkable guard for the production opt-in
// seam of the resolved no-embedded-WebView decision. WEBVIEW_TLS_MATRIX.md /
// LAUNCH_FALLBACK.md record that the final console route is external-browser +
// copy with the in-app flag OFF and strict TLS. The only policy that may ever
// reach `planConsoleLaunch` in product code is `KvmWebViewPolicy.productionDefault`
// (flag off, strict TLS, self-signed refused). This guard fails closed if any
// product `lib/features/kvm/**.dart` use-site selects the test-only opt-in
// (`KvmWebViewPolicy.testOptIn`, `KvmWebViewTlsMode.testOptInSelfSigned`) or
// constructs an in-app / self-signed-accepting `KvmWebViewPolicy`, so a future
// edit cannot bypass the human WebView/TLS validation gate from production.
//
// The evaluator is deliberately kept in this TEST-only file so its forbidden
// tokens never appear in product `lib/` (which is exactly what the guard scans).
// Legitimate opt-in construction confined to `test/` stays clean; the policy
// definition file itself (where the constants are declared) is the authority
// and is excluded from the use-site scan. No dependency, no WebView/protocol
// import, no URL opened, no production TLS weakening.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The single product file that DEFINES the opt-in constants. It is the policy
/// authority, excluded from the use-site scan; its own contract is pinned by
/// `webview_policy_test.dart` / `production_route_invariant_test.dart`.
const String policyDefinitionFile =
    'lib/features/kvm/platform/webview_policy.dart';

/// Code tokens that no product use-site outside [policyDefinitionFile] may
/// reference — selecting either one would enable in-app rendering / self-signed
/// acceptance in production.
const List<String> forbiddenOptInTokens = <String>[
  'KvmWebViewPolicy.testOptIn',
  'KvmWebViewTlsMode.testOptInSelfSigned',
];

/// One policy violation, with the offending file and a human-readable reason.
class PolicyViolation {
  final String file;
  final String reason;

  const PolicyViolation(this.file, this.reason);

  @override
  String toString() => '$file: $reason';
}

/// Remove `//` line and `/* */` block comments. Comments are documentation, not
/// code, so a doc line naming the opt-in constants must not flag.
String stripComments(String source) {
  final noBlocks = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return noBlocks.replaceAll(RegExp(r'//[^\n]*'), '');
}

/// Remove quoted / triple-quoted string literals from already comment-stripped
/// source, so opt-in tokens inside prose or string data do not count as a real
/// production use-site.
String stripStringLiterals(String source) {
  var s = source.replaceAll(RegExp(r"'''[\s\S]*?'''"), "''");
  s = s.replaceAll(RegExp(r'"""[\s\S]*?"""'), '""');
  s = s.replaceAll(RegExp(r"'(?:\\.|[^'\\\n])*'"), "''");
  s = s.replaceAll(RegExp(r'"(?:\\.|[^"\\\n])*"'), '""');
  return s;
}

/// Return the argument text between `(` at [openIndex] and its matching `)`,
/// balancing nested parentheses. Used to inspect a `KvmWebViewPolicy(...)` call
/// without a fragile fixed-width window.
String constructorArguments(String code, int openIndex) {
  var depth = 0;
  for (var i = openIndex; i < code.length; i++) {
    final c = code[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) {
        return code.substring(openIndex + 1, i);
      }
    }
  }
  return code.substring(openIndex + 1);
}

/// Scan one Dart source for production opt-in policy use-sites. `file` is only
/// used for reporting; path-based exclusion is done by [policyDartFiles].
List<PolicyViolation> scanPolicySource(String file, String source) {
  final violations = <PolicyViolation>[];
  final code = stripStringLiterals(stripComments(source));

  // (1) A reference to a test-only opt-in constant anywhere in product code.
  for (final token in forbiddenOptInTokens) {
    final tokenRe = RegExp(r'\b' + RegExp.escape(token) + r'\b');
    if (tokenRe.hasMatch(code)) {
      violations.add(
        PolicyViolation(file, 'references opt-in token $token'),
      );
    }
  }

  // (2) A `KvmWebViewPolicy(...)` construction that explicitly turns on the
  // in-app flag or selects the self-signed-accepting TLS mode. A default /
  // productionDefault-style construction (no such args) stays clean.
  final enabledTrue = RegExp(r'\benabled\s*:\s*true\b');
  final testTls = RegExp(
    r'\btlsMode\s*:\s*KvmWebViewTlsMode\s*\.\s*testOptInSelfSigned\b',
  );
  final ctor = RegExp(r'\bKvmWebViewPolicy\s*\(');
  for (final match in ctor.allMatches(code)) {
    final openIndex = code.indexOf('(', match.start);
    if (openIndex < 0) {
      continue;
    }
    final args = constructorArguments(code, openIndex);
    if (enabledTrue.hasMatch(args) || testTls.hasMatch(args)) {
      violations.add(
        PolicyViolation(
          file,
          'constructs KvmWebViewPolicy with in-app/self-signed flags enabled',
        ),
      );
      break;
    }
  }

  return violations;
}

/// Every product Dart source under [root] (recursive), sorted for stability,
/// excluding the policy definition file (the declaration authority).
List<File> policyDartFiles(Directory root) {
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where(
        (f) => !f.path.replaceAll(r'\', '/').endsWith(policyDefinitionFile),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

void main() {
  group('EP-P10 scanPolicySource — opt-in references', () {
    test('flags KvmWebViewPolicy.testOptIn', () {
      final v = scanPolicySource(
        'lib/features/kvm/bad.dart',
        'final p = KvmWebViewPolicy.testOptIn;\n',
      );
      expect(v, isNotEmpty);
      expect(v.first.reason, contains('KvmWebViewPolicy.testOptIn'));
    });

    test('flags KvmWebViewTlsMode.testOptInSelfSigned', () {
      final v = scanPolicySource(
        'lib/features/kvm/bad.dart',
        'final m = KvmWebViewTlsMode.testOptInSelfSigned;\n',
      );
      expect(v, isNotEmpty);
      expect(v.first.reason, contains('KvmWebViewTlsMode.testOptInSelfSigned'));
    });

    test('flags an enabled:true policy construction', () {
      final v = scanPolicySource(
        'lib/features/kvm/bad.dart',
        'const p = KvmWebViewPolicy(enabled: true);\n',
      );
      expect(v, isNotEmpty);
      expect(v.first.reason, contains('constructs'));
    });

    test('flags a testOptInSelfSigned tlsMode policy construction', () {
      final v = scanPolicySource(
        'lib/features/kvm/bad.dart',
        'const p = KvmWebViewPolicy(\n'
            '  tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,\n'
            ');\n',
      );
      expect(v, isNotEmpty);
      expect(v.first.reason, contains('KvmWebViewTlsMode.testOptInSelfSigned'));
    });

    test('a productionDefault construction is clean', () {
      const safe = '''
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';
final p = planConsoleLaunch(policy: KvmWebViewPolicy.productionDefault);
final q = KvmWebViewPolicy();
''';
      expect(scanPolicySource('lib/features/kvm/good.dart', safe), isEmpty);
    });

    test('opt-in tokens in doc/line/block comments are clean', () {
      const documented = '''
/// Never use KvmWebViewPolicy.testOptIn in production.
// KvmWebViewTlsMode.testOptInSelfSigned is test-only.
/* const p = KvmWebViewPolicy(enabled: true); */
import 'dart:async';
''';
      expect(
          scanPolicySource('lib/features/kvm/good.dart', documented), isEmpty);
    });

    test('opt-in tokens inside string literals are clean', () {
      const prose =
          "const String s = 'KvmWebViewPolicy.testOptIn is test-only';\n";
      expect(scanPolicySource('lib/features/kvm/good.dart', prose), isEmpty);
    });
  });

  group('EP-P10 temp-root RED→GREEN proof', () {
    test('an opt-in reference in a product file is a violation', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_p10_guard_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final File f = File('${temp.path}/lib/features/kvm/views/bad.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'final p = KvmWebViewPolicy.testOptIn;\n',
        );
      final violations = <PolicyViolation>[];
      for (final file in policyDartFiles(temp)) {
        violations.addAll(scanPolicySource(file.path, file.readAsStringSync()));
      }
      expect(violations, isNotEmpty,
          reason: 'must fail closed on a planted opt-in reference: $f');
    });

    test('an enabled policy construction in a product file is a violation', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_p10_guard_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File('${temp.path}/lib/features/kvm/models/bad.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'const p = KvmWebViewPolicy(enabled: true,\n'
          '  tlsMode: KvmWebViewTlsMode.testOptInSelfSigned);\n',
        );
      final violations = <PolicyViolation>[];
      for (final file in policyDartFiles(temp)) {
        violations.addAll(scanPolicySource(file.path, file.readAsStringSync()));
      }
      expect(violations, isNotEmpty,
          reason: 'must fail closed on a planted enabled policy construction');
    });

    test('productionDefault-only product files are clean', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_p10_guard_');
      addTearDown(() => temp.deleteSync(recursive: true));
      File('${temp.path}/lib/features/kvm/models/good.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'final p = planConsoleLaunch(policy: KvmWebViewPolicy.productionDefault);\n',
        );
      final violations = <PolicyViolation>[];
      for (final file in policyDartFiles(temp)) {
        violations.addAll(scanPolicySource(file.path, file.readAsStringSync()));
      }
      expect(violations, isEmpty);
    });
  });

  group('EP-P10 real repository invariant', () {
    test('no product use-site selects the opt-in or builds an enabled policy',
        () {
      final Directory root = Directory('lib/features/kvm');
      expect(root.existsSync(), isTrue);
      final files = policyDartFiles(root);
      expect(files, isNotEmpty);

      final violations = <PolicyViolation>[];
      for (final f in files) {
        violations.addAll(scanPolicySource(f.path, f.readAsStringSync()));
      }
      expect(
        violations,
        isEmpty,
        reason: 'product use-sites may only use productionDefault; '
            'offenders: ${violations.join(", ")}',
      );
    });

    test('the production launch-plan call site passes only productionDefault',
        () {
      final f = File('lib/features/kvm/models/kvm_models.dart');
      expect(f.existsSync(), isTrue);
      final code = stripStringLiterals(stripComments(f.readAsStringSync()));
      final callRe = RegExp(r'planConsoleLaunch\s*\(');
      final calls = callRe.allMatches(code).toList();
      expect(calls, isNotEmpty,
          reason: 'the shared production launch decision must exist');
      for (final call in calls) {
        final openIndex = code.indexOf('(', call.start);
        final args = constructorArguments(code, openIndex);
        expect(
          RegExp(r'policy\s*:\s*KvmWebViewPolicy\.productionDefault\b')
              .hasMatch(args),
          isTrue,
          reason: 'every production planConsoleLaunch call must pass '
              'KvmWebViewPolicy.productionDefault',
        );
      }
    });
  });
}
