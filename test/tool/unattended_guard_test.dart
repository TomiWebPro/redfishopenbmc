// Unit tests for the unattended-safety policy guard (tool/unattended_guard.dart).
//
// Pure-Dart tests over inline `path -> source` maps — the policy logic needs no
// file I/O, so `flutter test` never depends on the working tree. One test scans
// the real repo to prove the committed tree actually satisfies the gate.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/unattended_guard.dart';

/// A correctly gated integration-test source.
const String _gatedIntegrationSource = '''
const String emulatorUrl = String.fromEnvironment('REDFISH_EMULATOR_URL');
void main() {
  if (emulatorUrl.isEmpty) {
    test('skipped', () => markTestSkipped('set REDFISH_EMULATOR_URL'));
  }
}
''';

void main() {
  group('path classification / normalization', () {
    test('normalizes backslashes, leading ./ and /', () {
      expect(normalizeGuardPath(r'.\test_integration\a.dart'),
          'test_integration/a.dart');
      expect(normalizeGuardPath('/test/foo.dart'), 'test/foo.dart');
      expect(normalizeGuardPath('./lib/x.dart'), 'lib/x.dart');
    });

    test('classifies only .dart files in the three guarded areas', () {
      expect(isIntegrationTestPath('test_integration/emulator/a.dart'), isTrue);
      expect(isIntegrationTestPath('test_integration/a.md'), isFalse);
      expect(isIntegrationTestPath('test/a.dart'), isFalse);
      expect(isPlainTestPath('test/a_test.dart'), isTrue);
      expect(isPlainTestPath('test_integration/a.dart'), isFalse);
      expect(isProductionSourcePath('lib/features/a.dart'), isTrue);
      expect(isProductionSourcePath('tool/a.dart'), isFalse);
    });
  });

  group('gate / signal detection', () {
    test('detects the fromEnvironment gate (single or double quotes)', () {
      expect(
          declaresEmulatorEnvGate(
              "String.fromEnvironment('REDFISH_EMULATOR_URL')"),
          isTrue);
      expect(
          declaresEmulatorEnvGate(
              'String.fromEnvironment("REDFISH_EMULATOR_URL")'),
          isTrue);
      expect(
          declaresEmulatorEnvGate('String.fromEnvironment("OTHER")'), isFalse);
    });

    test('requires BOTH the env gate and a skip guard', () {
      expect(isGatedIntegrationTest(_gatedIntegrationSource), isTrue);
      expect(
        isGatedIntegrationTest(
            "const u = String.fromEnvironment('REDFISH_EMULATOR_URL');"),
        isFalse,
        reason: 'env gate alone cannot skip tests',
      );
      expect(
        isGatedIntegrationTest("main() => markTestSkipped('x');"),
        isFalse,
        reason: 'skip guard alone never reads the env URL',
      );
    });

    test('detects plain-test env references and production self-signed true',
        () {
      expect(referencesEmulatorEnv("fromEnvironment('REDFISH_EMULATOR_URL')"),
          isTrue);
      expect(referencesEmulatorEnv('// unrelated'), isFalse);
      expect(enablesSelfSignedTls('ConnectionProfile(allowSelfSigned: true)'),
          isTrue);
      expect(enablesSelfSignedTls('allowSelfSigned :  true'), isTrue);
      expect(enablesSelfSignedTls('allowSelfSigned: false'), isFalse);
      expect(enablesSelfSignedTls('allowSelfSigned: flag'), isFalse);
    });
  });

  group('evaluateUnattendedGuard', () {
    test('clean tree yields no violations', () {
      expect(
        evaluateUnattendedGuard(<String, String>{
          'test_integration/emulator/emulator_suite_test.dart':
              _gatedIntegrationSource,
          'test/features/kvm/kvm_model_test.dart':
              "main() => group('x', () {});",
          'lib/redfish/client/redfish_client.dart':
              'final p = profile; // allowSelfSigned defaults false',
        }),
        isEmpty,
      );
    });

    test('integration test WITHOUT the gate is a violation (RED contract)', () {
      // Behavioral proof: strip the gate from an otherwise valid integration
      // test and the guard must fail closed.
      final String ungated = _gatedIntegrationSource.replaceFirst(
          "String.fromEnvironment('REDFISH_EMULATOR_URL')", "''");
      final List<UnattendedGuardViolation> violations =
          evaluateUnattendedGuard(<String, String>{
        'test_integration/live_bmc_test.dart': ungated,
      });
      expect(violations, hasLength(1));
      expect(violations.first.path, 'test_integration/live_bmc_test.dart');
      expect(
        violations.first.kind,
        UnattendedViolationKind.ungatedIntegrationTest,
      );
    });

    test('integration test missing ONLY markTestSkipped is a violation', () {
      final List<UnattendedGuardViolation> violations =
          evaluateUnattendedGuard(<String, String>{
        'test_integration/emulator/a.dart':
            "const u = String.fromEnvironment('REDFISH_EMULATOR_URL');",
      });
      expect(violations, hasLength(1));
      expect(
        violations.first.kind,
        UnattendedViolationKind.ungatedIntegrationTest,
      );
    });

    test('plain test referencing the emulator env var is a violation', () {
      final List<UnattendedGuardViolation> violations =
          evaluateUnattendedGuard(<String, String>{
        'test/unit/network_test.dart':
            "const u = String.fromEnvironment('REDFISH_EMULATOR_URL');",
      });
      expect(violations, hasLength(1));
      expect(violations.first.path, 'test/unit/network_test.dart');
      expect(
        violations.first.kind,
        UnattendedViolationKind.networkRefInPlainTest,
      );
    });

    test('tooling self-tests may carry env-key literals as data', () {
      expect(
        evaluateUnattendedGuard(<String, String>{
          'test/tool/unattended_guard_test.dart':
              "const u = String.fromEnvironment('REDFISH_EMULATOR_URL');",
        }),
        isEmpty,
        reason: 'test/tool/ self-tests mention the key as test data only',
      );
    });

    test('production lib/ hard-enabling self-signed TLS is a violation', () {
      final List<UnattendedGuardViolation> violations =
          evaluateUnattendedGuard(<String, String>{
        'lib/redfish/client/bad.dart':
            'RedfishClient(p.copyWith(allowSelfSigned: true));',
      });
      expect(violations, hasLength(1));
      expect(violations.first.path, 'lib/redfish/client/bad.dart');
      expect(
        violations.first.kind,
        UnattendedViolationKind.selfSignedInProduction,
      );
    });

    test('reports multiple independent violations at once', () {
      final List<UnattendedGuardViolation> violations =
          evaluateUnattendedGuard(<String, String>{
        'test_integration/a.dart': 'void main() {}',
        'test/b_test.dart':
            "const u = String.fromEnvironment('REDFISH_EMULATOR_URL');",
        'lib/c.dart': 'c(allowSelfSigned: true)',
        'tool/d.dart': 'allowed: true',
      });
      expect(violations, hasLength(3));
      expect(
        violations.map((UnattendedGuardViolation v) => v.kind).toSet(),
        <UnattendedViolationKind>{
          UnattendedViolationKind.ungatedIntegrationTest,
          UnattendedViolationKind.networkRefInPlainTest,
          UnattendedViolationKind.selfSignedInProduction,
        },
      );
    });
  });

  group('CLI arg parsing', () {
    test('defaults to current directory and accepts one root', () {
      expect(parseUnattendedGuardCliArgs(<String>[]), '.');
      expect(parseUnattendedGuardCliArgs(<String>['../repo']), '../repo');
    });

    test('rejects extra args and options', () {
      expect(
        () => parseUnattendedGuardCliArgs(<String>['a', 'b']),
        throwsArgumentError,
      );
      expect(
        () => parseUnattendedGuardCliArgs(<String>['--weaken-tls']),
        throwsArgumentError,
      );
    });
  });

  group('committed tree', () {
    test('the real repo satisfies the unattended-safety gate', () {
      final Directory root = Directory.current;
      final Map<String, String> sources = scanRepoForDartSources(root);
      expect(
          sources.containsKey(
              'test_integration/emulator/emulator_suite_test.dart'),
          isTrue,
          reason: 'scanner must find the emulator suite');
      expect(evaluateUnattendedGuard(sources), isEmpty);
    });
  });
}
