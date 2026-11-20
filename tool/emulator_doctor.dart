/// Emulator prerequisite doctor (EP-T7 epic split of #009/#021).
///
/// The DMTF emulator suite (`tool/emulator/run_tests.sh`) is the standard
/// integration suite, but it can only be trusted when its prerequisites are
/// actually present. This doctor fails closed with a precise, actionable
/// diagnostic when one is missing, before anyone tries to run the suite.
///
/// Design constraints (from the epic split):
///  * dependency-free (`dart:io` only);
///  * check-only — it NEVER starts a container, opens a network connection or
///    touches credentials, so it is safe to run in the unattended scheduler;
///  * the mockup fixture is addressed by its repo-relative path only — never a
///    hardcoded container-internal DSP2043 path;
///  * the pure evaluation logic is I/O-injectable and unit-testable in
///    `test/tool/emulator_doctor_test.dart`.
///
/// Exit codes: 0 = all prerequisites present, 1 = at least one missing,
/// 2 = CLI input error.
library;

import 'dart:io';

/// Executables that must be resolvable on PATH before the emulator suite runs.
const List<String> kRequiredExecutables = <String>[
  'docker',
  'curl',
  'jq',
  'redfishtool',
];

/// Repo-relative path to the pinned DMTF mockup fixture used by `run_tests.sh`.
/// This is deliberately repo-relative: no absolute or container-internal path.
const String kMockupFixturePath = 'test/fixtures/redfish/dmtf_mockup';

/// Separator of a POSIX PATH-style environment variable.
const String kPathEnvSeparator = ':';

/// The kind of emulator prerequisite that is missing.
enum EmulatorDoctorIssueKind {
  /// A required executable is not resolvable on PATH.
  missingExecutable,

  /// The repo-relative DMTF mockup fixture directory is absent.
  missingFixture,
}

/// A single actionable prerequisite diagnostic.
class EmulatorDoctorIssue {
  const EmulatorDoctorIssue(this.kind, this.subject, this.message);

  final EmulatorDoctorIssueKind kind;
  final String subject; // executable name or repo-relative fixture path
  final String message;

  @override
  String toString() => 'emulator doctor: $message';
}

/// Evaluates the prerequisites over injected facts.
///
/// Pure and I/O-free. Returns one issue per missing prerequisite, in a
/// deterministic order (required executables in declaration order, then the
/// fixture); an empty list means every prerequisite is present.
List<EmulatorDoctorIssue> evaluateEmulatorPrerequisites({
  Iterable<String> requiredExecutables = kRequiredExecutables,
  required Set<String> availableExecutables,
  required bool fixturePresent,
  String fixturePath = kMockupFixturePath,
}) {
  final List<EmulatorDoctorIssue> issues = <EmulatorDoctorIssue>[];

  for (final String name in requiredExecutables) {
    if (!availableExecutables.contains(name)) {
      issues.add(
        EmulatorDoctorIssue(
          EmulatorDoctorIssueKind.missingExecutable,
          name,
          "missing prerequisite '$name' on PATH — install it or add its "
          'directory to PATH before running tool/emulator/run_tests.sh; '
          'never fall back to a live BMC in the unattended scheduler',
        ),
      );
    }
  }

  if (!fixturePresent) {
    issues.add(
      EmulatorDoctorIssue(
        EmulatorDoctorIssueKind.missingFixture,
        fixturePath,
        'missing DMTF mockup fixture "$fixturePath" — run this doctor from the '
        'repository root; use the repo-relative fixture only (no absolute or '
        'container-internal path)',
      ),
    );
  }

  return issues;
}

/// Splits a PATH-style value into non-empty directory entries.
List<String> splitPathEnv(
  String pathEnv, {
  String separator = kPathEnvSeparator,
}) =>
    pathEnv
        .split(separator)
        .where((String entry) => entry.isNotEmpty)
        .toList(growable: false);

bool _fileExists(String path) => File(path).existsSync();

/// Returns the subset of [required] names that resolve to a file in any of
/// [pathDirectories].
///
/// [exists] is injectable so tests can evaluate with no real file I/O; the
/// default checks for a file at `<dir>/<name>`.
Set<String> findAvailableExecutables(
  Iterable<String> pathDirectories, {
  Iterable<String> required = kRequiredExecutables,
  bool Function(String path) exists = _fileExists,
}) {
  final Set<String> found = <String>{};
  for (final String name in required) {
    for (final String dir in pathDirectories) {
      if (exists('$dir${Platform.pathSeparator}$name')) {
        found.add(name);
        break;
      }
    }
  }
  return found;
}

/// Whether [repoRoot] contains the pinned mockup fixture at [fixturePath].
bool fixtureExists(
  Directory repoRoot, {
  String fixturePath = kMockupFixturePath,
}) =>
    Directory('${repoRoot.path}${Platform.pathSeparator}$fixturePath')
        .existsSync();

/// Parsed CLI options for the doctor.
class EmulatorDoctorCliArgs {
  const EmulatorDoctorCliArgs({required this.help, required this.repoRoot});

  final bool help;
  final String repoRoot;
}

/// Parses doctor CLI args. Unknown options or multiple roots throw
/// [ArgumentError] (CLI maps this to exit code 2).
EmulatorDoctorCliArgs parseEmulatorDoctorCliArgs(List<String> args) {
  bool help = false;
  String? root;
  for (final String arg in args) {
    if (arg == '--help' || arg == '-h') {
      help = true;
    } else if (arg == '--check' || arg == '--check-only') {
      // Check-only is the doctor's sole mode: never starts containers or
      // network/credential use. Accept the explicit flag as a no-op.
    } else if (arg.startsWith('-')) {
      throw ArgumentError('unknown option: $arg');
    } else {
      if (root != null) {
        throw ArgumentError(
            'expected at most one repo root, got "$root" and "$arg"');
      }
      root = arg;
    }
  }
  return EmulatorDoctorCliArgs(help: help, repoRoot: root ?? '.');
}

final String _kUsage = '''
usage: dart run tool/emulator_doctor.dart [--check] [--help] [repo-root]

Check-only: verifies the prerequisites for the DMTF emulator integration suite
without starting a container, opening a network connection or using credentials.
Checks: ${kRequiredExecutables.join(', ')} on PATH and the repo-relative fixture
"$kMockupFixturePath".

tool/emulator/run_tests.sh remains the standard integration suite; the optional
testing/run_emulator_harness.sh is a convenience wrapper, not a replacement.
Exit codes: 0 = all present, 1 = prerequisite(s) missing, 2 = input error.
''';

void main(List<String> args) {
  EmulatorDoctorCliArgs parsed;
  try {
    parsed = parseEmulatorDoctorCliArgs(args);
  } on ArgumentError catch (error) {
    stderr.writeln('emulator doctor: $error');
    exitCode = 2;
    return;
  }

  if (parsed.help) {
    stdout.write(_kUsage);
    return;
  }

  final Directory root = Directory(parsed.repoRoot);
  if (!root.existsSync()) {
    stderr.writeln('emulator doctor: missing repo root "${parsed.repoRoot}"');
    exitCode = 2;
    return;
  }

  final Set<String> available = findAvailableExecutables(
    splitPathEnv(Platform.environment['PATH'] ?? ''),
  );
  final List<EmulatorDoctorIssue> issues = evaluateEmulatorPrerequisites(
    availableExecutables: available,
    fixturePresent: fixtureExists(root),
  );

  for (final EmulatorDoctorIssue issue in issues) {
    stderr.writeln(issue.toString());
  }
  stdout.writeln(
    issues.isEmpty
        ? 'emulator doctor: OK (${kRequiredExecutables.length} executables + '
            'mockup fixture present)'
        : 'emulator doctor: ${issues.length} prerequisite(s) missing',
  );
  exitCode = issues.isEmpty ? 0 : 1;
}
