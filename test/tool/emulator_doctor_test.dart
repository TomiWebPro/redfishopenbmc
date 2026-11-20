// Unit tests for the emulator prerequisite doctor (tool/emulator_doctor.dart).
//
// The evaluation logic is pure and I/O-injectable, so most tests need no file
// access. A couple of tests use temp directories to prove PATH scanning and a
// real-repo check proves the committed DMTF mockup fixture is found.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/emulator_doctor.dart';

void main() {
  group('prerequisite contract', () {
    test('requires docker, curl, jq and redfishtool on PATH', () {
      expect(kRequiredExecutables, contains('docker'));
      expect(kRequiredExecutables, contains('curl'));
      expect(kRequiredExecutables, contains('jq'));
      expect(kRequiredExecutables, contains('redfishtool'));
    });

    test('fixture path is repo-relative, never a container-internal path', () {
      expect(kMockupFixturePath.startsWith('test/'), isTrue);
      expect(kMockupFixturePath, endsWith('/dmtf_mockup'));
      expect(kMockupFixturePath.contains('DSP2043'), isFalse);
      expect(kMockupFixturePath.startsWith('/'), isFalse);
    });
  });

  group('splitPathEnv', () {
    test('splits on ":" and drops empty entries', () {
      expect(
        splitPathEnv('/usr/bin::/opt/bin:'),
        <String>['/usr/bin', '/opt/bin'],
      );
    });

    test('single entry and empty PATH', () {
      expect(splitPathEnv('/usr/local/bin'), <String>['/usr/local/bin']);
      expect(splitPathEnv(''), isEmpty);
    });
  });

  group('findAvailableExecutables', () {
    test('resolves required names from any PATH directory (injected exists)',
        () {
      final Set<String> found = findAvailableExecutables(
        <String>['/first', '/second'],
        exists: (String path) => const <String>{
          '/first/docker',
          '/second/curl',
          '/second/jq',
        }.contains(path),
      );
      expect(found, <String>{'docker', 'curl', 'jq'});
      expect(found, isNot(contains('redfishtool')));
    });

    test('respects a narrower required set and ignores unrequired files', () {
      final Set<String> found = findAvailableExecutables(
        <String>['/bin'],
        required: const <String>{'curl'},
        exists: (String path) =>
            const <String>{'/bin/curl', '/bin/python3'}.contains(path),
      );
      expect(found, <String>{'curl'});
    });

    test('finds a real executable file in a temp PATH directory', () {
      final Directory dir = Directory.systemTemp.createTempSync('doctor-path-');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}${Platform.pathSeparator}jq').createSync();

      final Set<String> found = findAvailableExecutables(
        <String>[dir.path],
        required: const <String>{'jq', 'curl'},
      );
      expect(found, <String>{'jq'});
    });
  });

  group('evaluateEmulatorPrerequisites', () {
    test('all present + fixture present yields no issues', () {
      expect(
        evaluateEmulatorPrerequisites(
          availableExecutables: kRequiredExecutables.toSet(),
          fixturePresent: true,
        ),
        isEmpty,
      );
    });

    test('a missing executable yields one actionable issue', () {
      final List<EmulatorDoctorIssue> issues = evaluateEmulatorPrerequisites(
        availableExecutables: const <String>{'docker', 'curl', 'jq'},
        fixturePresent: true,
      );
      expect(issues, hasLength(1));
      expect(issues.single.kind, EmulatorDoctorIssueKind.missingExecutable);
      expect(issues.single.subject, 'redfishtool');
      expect(issues.single.message, contains('redfishtool'));
      expect(issues.single.message, contains('PATH'));
      expect(issues.single.message, contains('run_tests.sh'));
      expect(issues.single.toString(), contains('emulator doctor:'));
    });

    test('multiple missing executables are reported in declaration order', () {
      final List<EmulatorDoctorIssue> issues = evaluateEmulatorPrerequisites(
        availableExecutables: const <String>{'curl'},
        fixturePresent: true,
      );
      expect(
        issues.map((EmulatorDoctorIssue i) => i.subject).toList(),
        <String>['docker', 'jq', 'redfishtool'],
      );
      expect(
        issues.every((EmulatorDoctorIssue i) =>
            i.kind == EmulatorDoctorIssueKind.missingExecutable),
        isTrue,
      );
    });

    test('a missing fixture yields a repo-relative actionable issue', () {
      final List<EmulatorDoctorIssue> issues = evaluateEmulatorPrerequisites(
        availableExecutables: kRequiredExecutables.toSet(),
        fixturePresent: false,
      );
      expect(issues, hasLength(1));
      expect(issues.single.kind, EmulatorDoctorIssueKind.missingFixture);
      expect(issues.single.subject, kMockupFixturePath);
      expect(issues.single.message, contains('repository root'));
      expect(issues.single.message, contains('repo-relative'));
    });

    test('fixture issue is appended after executable issues', () {
      final List<EmulatorDoctorIssue> issues = evaluateEmulatorPrerequisites(
        availableExecutables: const <String>{'docker'},
        fixturePresent: false,
      );
      expect(issues, hasLength(4));
      expect(issues.last.kind, EmulatorDoctorIssueKind.missingFixture);
      expect(
        issues.take(3).every((EmulatorDoctorIssue i) =>
            i.kind == EmulatorDoctorIssueKind.missingExecutable),
        isTrue,
      );
    });

    test('extra available executables never cause an issue', () {
      expect(
        evaluateEmulatorPrerequisites(
          availableExecutables: <String>{
            ...kRequiredExecutables,
            'python3',
            'openssl',
            'git',
          },
          fixturePresent: true,
        ),
        isEmpty,
      );
    });
  });

  group('CLI arg parsing', () {
    test('no args defaults to check mode at the current directory', () {
      final EmulatorDoctorCliArgs args = parseEmulatorDoctorCliArgs(<String>[]);
      expect(args.help, isFalse);
      expect(args.repoRoot, '.');
    });

    test('--check is an accepted no-op; --help sets help', () {
      expect(parseEmulatorDoctorCliArgs(<String>['--check']).repoRoot, '.');
      expect(
          parseEmulatorDoctorCliArgs(<String>['--check-only']).help, isFalse);
      expect(parseEmulatorDoctorCliArgs(<String>['--help']).help, isTrue);
      expect(parseEmulatorDoctorCliArgs(<String>['-h']).help, isTrue);
    });

    test('accepts an explicit repo root', () {
      expect(
        parseEmulatorDoctorCliArgs(<String>['--check', '/repo']).repoRoot,
        '/repo',
      );
    });

    test('rejects unknown options and multiple roots', () {
      expect(
        () => parseEmulatorDoctorCliArgs(<String>['--bogus']),
        throwsArgumentError,
      );
      expect(
        () => parseEmulatorDoctorCliArgs(<String>['/a', '/b']),
        throwsArgumentError,
      );
    });
  });

  group('real repository', () {
    test('the pinned DMTF mockup fixture exists at the repo-relative path', () {
      expect(fixtureExists(Directory.current), isTrue);
    });
  });
}
