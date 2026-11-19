// Unit tests for the large/binary asset policy guard (tool/asset_guard.dart).
//
// Pure-Dart tests over inline candidate lists and manifests — no real repo scan
// or file I/O is needed for the policy logic, so `flutter test` never depends on
// the working tree contents. One integration test scans the real repo to prove
// the committed manifest actually covers the checked-in large binary assets.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/asset_guard.dart';

const String _sha =
    '385ee6d0039a2dbc610c7af9fa9bba304fc2a461ceb5a8eda0adb33630c82149';

AssetManifest manifestWith(
  Map<String, dynamic> asset, {
  int threshold = kDefaultLargeAssetThresholdBytes,
}) =>
    AssetManifest.fromJson(<String, dynamic>{
      'thresholdBytes': threshold,
      'assets': <dynamic>[asset],
    });

Map<String, dynamic> pdfEntry({
  String path = 'documentations/external/redfish/spec/DSP0266_1.25.0.pdf',
  String sha256 = _sha,
  int bytes = 1243359,
}) =>
    <String, dynamic>{
      'path': path,
      'sha256': sha256,
      'bytes': bytes,
      'sourceUrl': 'https://www.dmtf.org/standards/DSP0266.pdf',
    };

void main() {
  group('normalizeAssetPath / isBinaryAssetPath', () {
    test('normalizes backslashes, leading ./ and /', () {
      expect(normalizeAssetPath(r'.\docs\a.pdf'), 'docs/a.pdf');
      expect(normalizeAssetPath('./documentations/external/a.pdf'),
          'documentations/external/a.pdf');
      expect(normalizeAssetPath('/repo/docs/a.pdf'), 'repo/docs/a.pdf');
    });

    test('recognises binary extensions case-insensitively, not text', () {
      expect(isBinaryAssetPath('a/b/SPEC.PDF'), isTrue);
      expect(isBinaryAssetPath('a/b/image.webp'), isTrue);
      expect(isBinaryAssetPath('a/b/tool.dart'), isFalse);
      expect(isBinaryAssetPath('a/b/index.html'), isFalse);
      expect(isBinaryAssetPath('a/b/README.md'), isFalse);
      expect(isBinaryAssetPath('a/b/noext'), isFalse);
    });

    test('isLargeBinaryAsset requires both size and binary extension', () {
      expect(isLargeBinaryAsset('a.pdf', 1024 * 1024 + 1), isTrue);
      expect(isLargeBinaryAsset('a.pdf', 1024 * 1024), isFalse);
      expect(isLargeBinaryAsset('a.md', 50 * 1024 * 1024), isFalse);
      expect(
          isLargeBinaryAsset('a.pdf', 2 * 1024 * 1024,
              threshold: 3 * 1024 * 1024),
          isFalse);
    });
  });

  group('AssetManifest.fromJson', () {
    test('parses a valid manifest and looks up by normalized path', () {
      final AssetManifest manifest =
          manifestWith(pdfEntry(path: r'docs\spec.PDF'));
      expect(manifest.thresholdBytes, kDefaultLargeAssetThresholdBytes);
      expect(manifest.entries, hasLength(1));
      expect(manifest.entryFor('docs/spec.PDF')?.sha256, _sha);
      expect(manifest.entryFor('./docs/spec.PDF')?.bytes, 1243359);
      expect(manifest.entryFor('docs/missing.pdf'), isNull);
    });

    test('round-trips through toJson', () {
      final AssetManifest manifest = manifestWith(pdfEntry());
      final AssetManifest reparsed = AssetManifest.fromJson(manifest.toJson());
      expect(
          reparsed.entries.single.toJson(), manifest.entries.single.toJson());
    });

    test('rejects malformed entries (bad sha, bad bytes, missing URL)', () {
      expect(() => manifestWith(pdfEntry(sha256: 'abc')), throwsArgumentError);
      expect(() => manifestWith(pdfEntry(bytes: 0)), throwsArgumentError);
      expect(
        () => manifestWith(<String, dynamic>{
          'path': 'a.pdf',
          'sha256': _sha,
          'bytes': 100,
          'sourceUrl': 'not a url',
        }),
        throwsArgumentError,
      );
    });

    test('rejects duplicate paths and non-positive thresholds', () {
      expect(
        () => AssetManifest.fromJson(<String, dynamic>{
          'thresholdBytes': 1024,
          'assets': <dynamic>[pdfEntry(), pdfEntry()],
        }),
        throwsArgumentError,
      );
      expect(
        () => AssetManifest.fromJson(<String, dynamic>{
          'thresholdBytes': 0,
          'assets': <dynamic>[pdfEntry()],
        }),
        throwsArgumentError,
      );
    });
  });

  group('evaluateAssetGuard', () {
    test('a large binary with no manifest entry is a violation (RED)', () {
      final AssetManifest manifest =
          manifestWith(pdfEntry(path: 'documentations/other.pdf'));
      final List<AssetGuardViolation> violations = evaluateAssetGuard(
        <AssetCandidate>[
          const AssetCandidate(
              path: 'docs/new_spec.pdf', bytes: 2 * 1024 * 1024),
        ],
        manifest,
      );
      expect(violations, hasLength(1));
      expect(violations.first.path, 'docs/new_spec.pdf');
      expect(violations.first.reason, contains('not listed'));
      expect(violations.first.toString(), contains('asset guard:'));
    });

    test('a listed large binary with matching size/hash passes (GREEN)', () {
      final AssetManifest manifest = manifestWith(pdfEntry());
      final List<AssetGuardViolation> violations = evaluateAssetGuard(
        <AssetCandidate>[
          AssetCandidate(
            path: r'documentations\external\redfish\spec\DSP0266_1.25.0.pdf',
            bytes: 1243359,
            sha256: _sha.toUpperCase(),
          ),
        ],
        manifest,
      );
      expect(violations, isEmpty);
    });

    test('byte-size and SHA-256 drift are violations', () {
      final AssetManifest manifest = manifestWith(pdfEntry());
      final List<AssetGuardViolation> violations = evaluateAssetGuard(
        <AssetCandidate>[
          const AssetCandidate(
            path: 'documentations/external/redfish/spec/DSP0266_1.25.0.pdf',
            bytes: 2097152,
            sha256:
                'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
          ),
        ],
        manifest,
      );
      expect(violations, hasLength(2));
      expect(violations.map((AssetGuardViolation v) => v.reason),
          everyElement(isA<String>()));
      expect(violations[0].reason, contains('byte size'));
      expect(violations[1].reason, contains('SHA-256'));
    });

    test('small files, text files and unlisted sub-threshold binaries pass',
        () {
      final AssetManifest manifest = manifestWith(pdfEntry());
      final List<AssetGuardViolation> violations = evaluateAssetGuard(
        const <AssetCandidate>[
          AssetCandidate(path: 'docs/readme.md', bytes: 50 * 1024 * 1024),
          AssetCandidate(path: 'docs/index.html', bytes: 50 * 1024 * 1024),
          AssetCandidate(path: 'docs/small.png', bytes: 1024),
        ],
        manifest,
      );
      expect(violations, isEmpty);
    });

    test('threshold override is honoured', () {
      final AssetManifest manifest = manifestWith(pdfEntry());
      final List<AssetGuardViolation> violations = evaluateAssetGuard(
        const <AssetCandidate>[
          AssetCandidate(path: 'docs/medium.pdf', bytes: 2 * 1024 * 1024),
        ],
        manifest,
        thresholdBytes: 3 * 1024 * 1024,
      );
      expect(violations, isEmpty);
    });
  });

  group('parseAssetGuardCliArgs', () {
    test('defaults to the committed manifest and accepts one override', () {
      expect(parseAssetGuardCliArgs(const <String>[]), kDefaultManifestPath);
      expect(
          parseAssetGuardCliArgs(const <String>['custom.json']), 'custom.json');
    });

    test('rejects flags and extra arguments', () {
      expect(() => parseAssetGuardCliArgs(const <String>['--json']),
          throwsArgumentError);
      expect(() => parseAssetGuardCliArgs(const <String>['a.json', 'b.json']),
          throwsArgumentError);
    });
  });

  group('committed manifest integration', () {
    test('the checked-in manifest covers the real large binary assets', () {
      final File manifestFile = File(kDefaultManifestPath);
      expect(manifestFile.existsSync(), isTrue,
          reason: 'run from the repository root');
      final AssetManifest manifest = AssetManifest.fromJson(
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(
          manifest.entryFor(
              'documentations/external/redfish/spec/DSP0266_1.25.0.pdf'),
          isNotNull);
      expect(
          manifest
              .entryFor(
                  'documentations/external/redfish/spec/DSP0266_1.25.0.pdf')!
              .sha256,
          _sha);
    });
  });
}
