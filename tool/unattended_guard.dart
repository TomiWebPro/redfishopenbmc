/// Unattended-safety policy guard for live-BMC / emulator integration tests
/// (FUTUREWORK "[!] Live BMC integration" / EP-T6 epic split of #009/#021).
///
/// The scheduler runs this repository unattended with real BMC credentials
/// never available. Three invariants keep it that way:
///
///  1. Every Dart test under `test_integration/` must gate network access on
///     `String.fromEnvironment('REDFISH_EMULATOR_URL')` AND call
///     `markTestSkipped` when that define is absent, so a plain `flutter test`
///     never contacts a BMC / emulator.
///  2. No plain unit/widget test under `test/` may reference the emulator env
///     var — live-BMC/network tests belong under `test_integration/` only.
///  3. Production `lib/` code must never hard-enable self-signed TLS
///     (`allowSelfSigned: true`). Self-signed acceptance is a test-only profile
///     concern; production keeps TLS validation on (an explicit, default-off
///     opt-in exists in `ConnectionProfile`, but no literal `true` in `lib/`).
///
/// The evaluation logic is pure Dart over an in-memory `path -> source` map so
/// it is unit-testable with no file I/O; [main] is a thin CLI that scans the
/// working tree and sets the exit code (0 = clean, 1 = violation, 2 = input
/// error). Dependency-free (`dart:io` only). It never opens a network
/// connection and never weakens production TLS.
library;

import 'dart:io';

/// The env var that opts an integration suite into a live emulator/BMC URL.
const String kEmulatorEnvKey = 'REDFISH_EMULATOR_URL';

/// Prefix for tooling self-tests. These files legitimately carry env-key
/// literals as *test data* (e.g. the guard's own tests), so they are exempt from
/// the "plain test must not reference the emulator env var" rule — merely
/// mentioning the key as a string does not make `flutter test` contact a BMC.
const String kToolingTestPrefix = 'test/tool/';

/// Directories the CLI scanner skips entirely (generated / tooling state).
const Set<String> kSkippedScanDirectories = <String>{
  '.git',
  '.dart_tool',
  'build',
  '.idea',
  '.vscode',
};

final RegExp _fromEnvironmentPattern = RegExp(
  "fromEnvironment\\(\\s*['\"]$kEmulatorEnvKey['\"]",
);
final RegExp _envKeyLiteralPattern = RegExp("['\"]$kEmulatorEnvKey['\"]");
final RegExp _markTestSkippedPattern = RegExp(r'\bmarkTestSkipped\b');
final RegExp _selfSignedTruePattern = RegExp(r'\ballowSelfSigned\s*:\s*true\b');

/// Normalizes a path for classification: forward slashes, no leading `./`
/// or `/`. Mirrors the asset guard so paths from any scanner compare cleanly.
String normalizeGuardPath(String path) {
  String result = path.replaceAll(r'\', '/');
  while (result.startsWith('./')) {
    result = result.substring(2);
  }
  while (result.startsWith('/')) {
    result = result.substring(1);
  }
  return result;
}

/// Whether [path] is a Dart integration test (the network-gated suite).
bool isIntegrationTestPath(String path) {
  final String p = normalizeGuardPath(path);
  return p.startsWith('test_integration/') && p.endsWith('.dart');
}

/// Whether [path] is a plain Dart unit/widget test (no network allowed).
bool isPlainTestPath(String path) {
  final String p = normalizeGuardPath(path);
  return p.startsWith('test/') && p.endsWith('.dart');
}

/// Whether [path] is production Dart source.
bool isProductionSourcePath(String path) {
  final String p = normalizeGuardPath(path);
  return p.startsWith('lib/') && p.endsWith('.dart');
}

/// True when [source] reads the emulator URL via `String.fromEnvironment`.
bool declaresEmulatorEnvGate(String source) =>
    _fromEnvironmentPattern.hasMatch(source);

/// True when [source] explicitly skips tests when the env var is absent.
bool declaresSkipGuard(String source) =>
    _markTestSkippedPattern.hasMatch(source);

/// True when [source] satisfies BOTH halves of the integration-test gate.
bool isGatedIntegrationTest(String source) =>
    declaresEmulatorEnvGate(source) && declaresSkipGuard(source);

/// True when [source] references the emulator env key at all.
bool referencesEmulatorEnv(String source) =>
    _envKeyLiteralPattern.hasMatch(source);

/// True when [source] hard-enables self-signed TLS in production code.
bool enablesSelfSignedTls(String source) =>
    _selfSignedTruePattern.hasMatch(source);

/// The kind of unattended-safety invariant that was broken.
enum UnattendedViolationKind {
  /// A `test_integration/` Dart file lacks the env gate + skip guard.
  ungatedIntegrationTest,

  /// A plain `test/` Dart file references the emulator env var.
  networkRefInPlainTest,

  /// A production `lib/` Dart file hard-enables self-signed TLS.
  selfSignedInProduction,
}

/// A single guard violation.
class UnattendedGuardViolation {
  const UnattendedGuardViolation(this.path, this.kind, this.reason);

  final String path;
  final UnattendedViolationKind kind;
  final String reason;

  @override
  String toString() => 'unattended guard: $path — $reason';
}

/// Evaluates the unattended-safety policy over [sources] (path -> source text).
///
/// Pure and I/O-free. Returns one violation per broken invariant; an empty list
/// means the tree is unattended-safe. Files outside the three classified areas
/// are ignored.
List<UnattendedGuardViolation> evaluateUnattendedGuard(
  Map<String, String> sources,
) {
  final List<UnattendedGuardViolation> violations =
      <UnattendedGuardViolation>[];
  sources.forEach((String path, String source) {
    final String normalized = normalizeGuardPath(path);

    if (isIntegrationTestPath(normalized) && !isGatedIntegrationTest(source)) {
      violations.add(
        UnattendedGuardViolation(
          normalized,
          UnattendedViolationKind.ungatedIntegrationTest,
          'live-BMC/emulator integration test must gate on '
          "String.fromEnvironment('$kEmulatorEnvKey') and call markTestSkipped "
          'when absent, so plain flutter test never hits the network',
        ),
      );
    }
    if (isPlainTestPath(normalized) &&
        !normalized.startsWith(kToolingTestPrefix) &&
        referencesEmulatorEnv(source)) {
      violations.add(
        UnattendedGuardViolation(
          normalized,
          UnattendedViolationKind.networkRefInPlainTest,
          'plain unit/widget test must not reference $kEmulatorEnvKey '
          '(network tests belong under test_integration/)',
        ),
      );
    }
    if (isProductionSourcePath(normalized) && enablesSelfSignedTls(source)) {
      violations.add(
        UnattendedGuardViolation(
          normalized,
          UnattendedViolationKind.selfSignedInProduction,
          'production lib/ code must not hard-enable self-signed TLS '
          '(allowSelfSigned: true) — test-only profiles only',
        ),
      );
    }
  });
  return violations;
}

/// Recursively reads all Dart files under [root] into a path -> source map.
///
/// Generated/tooling directories are skipped so the gate only sees committed
/// project sources. No network access.
Map<String, String> scanRepoForDartSources(
  Directory root, {
  Set<String> skippedDirectories = kSkippedScanDirectories,
}) {
  final String base = root.path;
  final Map<String, String> result = <String, String>{};
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    String relative = entity.path.replaceFirst(base, '');
    relative = normalizeGuardPath(relative);
    final List<String> segments = relative.split('/');
    if (segments.any(skippedDirectories.contains)) continue;
    result[relative] = entity.readAsStringSync();
  }
  return result;
}

/// Parses CLI args: an optional repository root, defaulting to `.`.
/// Throws [ArgumentError] on extra arguments or unknown options.
String parseUnattendedGuardCliArgs(List<String> args) {
  if (args.length > 1) {
    throw ArgumentError('expected at most one repo root, got ${args.length}');
  }
  if (args.isNotEmpty && args.first.startsWith('-')) {
    throw ArgumentError('unknown option: ${args.first}');
  }
  return args.isEmpty ? '.' : args.first;
}

void main(List<String> args) {
  String root;
  try {
    root = parseUnattendedGuardCliArgs(args);
  } on ArgumentError catch (error) {
    stderr.writeln('unattended guard: $error');
    exitCode = 2;
    return;
  }

  final Directory dir = Directory(root);
  if (!dir.existsSync()) {
    stderr.writeln('unattended guard: missing root "$root"');
    exitCode = 2;
    return;
  }

  final Map<String, String> sources = scanRepoForDartSources(dir);
  final List<UnattendedGuardViolation> violations =
      evaluateUnattendedGuard(sources);
  for (final UnattendedGuardViolation violation in violations) {
    stderr.writeln(violation.toString());
  }
  stdout.writeln(violations.isEmpty
      ? 'unattended guard: OK (${sources.length} Dart sources scanned)'
      : 'unattended guard: ${violations.length} violation(s)');
  exitCode = violations.isEmpty ? 0 : 1;
}
