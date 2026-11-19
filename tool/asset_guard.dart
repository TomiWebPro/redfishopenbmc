/// Large/binary asset policy guard (FUTUREWORK "[!] Large spec/binary assets").
///
/// The reference mirror may contain a small number of large *binary* assets
/// (e.g. the DSP0266 specification PDF). Policy: never add a large binary to the
/// repository without an explicit, human-reviewed entry in
/// [kDefaultManifestPath] carrying its source URL, SHA-256 and byte size; if the
/// artifact is over the download budget, store the URL + hash + extracted notes
/// instead of the binary. The human-review gate is documented in
/// `DEVELOPMENT.md`.
///
/// The parsing/evaluation logic is pure Dart with no I/O so it can be
/// unit-tested; [main] is a thin CLI wrapper that scans the working tree and
/// sets the process exit code (0 = no violations, 1 = a violation, 2 = input
/// error). Dependency-free: it uses only `dart:convert` / `dart:io`.
library;

import 'dart:convert';
import 'dart:io';

/// Default manifest location, relative to the repository root.
const String kDefaultManifestPath = 'tool/asset_manifest.json';

/// Assets larger than this (strictly greater, in bytes) require a manifest
/// entry when they are also a recognised binary asset (see
/// [isBinaryAssetPath]). 1 MiB keeps ordinary source/doc text files out of the
/// gate while catching spec PDFs, images, archives and binaries.
const int kDefaultLargeAssetThresholdBytes = 1024 * 1024;

/// File extensions treated as binary/large assets by the guard.
///
/// Text formats (`.md`, `.json`, `.dart`, `.html`, `.yaml`, ...) are intentionally
/// excluded: a large text corpus is reviewed through the DOCS manifest in
/// `documentations/external/README.md`, not this binary-asset gate. Listing a
/// large text file here would flag tracked logs (e.g. `automation-tracking.md`),
/// which are not binary assets at all.
const Set<String> kBinaryAssetExtensions = <String>{
  // Documents / images.
  'pdf', 'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'ico', 'tiff', 'svgz',
  // Archives.
  'zip', 'gz', 'tar', 'bz2', 'xz', '7z', 'tgz', 'rar',
  // Binaries / compiled artifacts.
  'bin', 'dat', 'exe', 'dll', 'so', 'dylib', 'o', 'a', 'jar', 'class', 'wasm',
  // Media.
  'mp3', 'mp4', 'mov', 'avi', 'wav', 'ogg', 'webm',
  // Fonts.
  'ttf', 'otf', 'woff', 'woff2', 'eot',
  // Databases.
  'db', 'sqlite', 'sqlite3', 'realm',
};

/// Directories the CLI scanner never descends into (generated/tooling state).
const Set<String> kSkippedScanDirectories = <String>{
  '.git',
  '.dart_tool',
  'build',
  '.idea',
  '.vscode',
};

final RegExp _sha256Pattern = RegExp(r'^[0-9a-fA-F]{64}$');

/// Normalizes a path for manifest comparison: forward slashes, no leading
/// `./` or `/`. This lets a manifest authored on Windows match a POSIX scan.
String normalizeAssetPath(String path) {
  String result = path.replaceAll(r'\', '/');
  while (result.startsWith('./')) {
    result = result.substring(2);
  }
  while (result.startsWith('/')) {
    result = result.substring(1);
  }
  return result;
}

/// Whether [path] has a recognised binary asset extension (case-insensitive).
bool isBinaryAssetPath(String path) {
  final String normalized = normalizeAssetPath(path);
  final int dot = normalized.lastIndexOf('.');
  if (dot < 0 || dot == normalized.length - 1) return false;
  return kBinaryAssetExtensions.contains(
    normalized.substring(dot + 1).toLowerCase(),
  );
}

/// Whether a file at [path] with [bytes] bytes is a large binary asset that the
/// guard requires to be listed in the manifest.
bool isLargeBinaryAsset(
  String path,
  int bytes, {
  int threshold = kDefaultLargeAssetThresholdBytes,
}) =>
    bytes > threshold && isBinaryAssetPath(path);

/// One human-reviewed manifest entry for a large/binary asset.
class AssetEntry {
  const AssetEntry({
    required this.path,
    required this.sha256,
    required this.bytes,
    required this.sourceUrl,
    this.notes,
  });

  /// Repository-relative path of the committed asset.
  final String path;

  /// SHA-256 (64 hex chars) of the committed bytes.
  final String sha256;

  /// Exact byte size of the committed asset.
  final int bytes;

  /// Authoritative upstream URL the asset was fetched from.
  final String sourceUrl;

  /// Optional provenance / rationale notes.
  final String? notes;

  /// Normalized path used for lookups.
  String get normalizedPath => normalizeAssetPath(path);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'sha256': sha256,
        'bytes': bytes,
        'sourceUrl': sourceUrl,
        if (notes != null) 'notes': notes,
      };

  /// Parses and validates a manifest entry, failing loudly on malformed data so
  /// a broken manifest can never silently disable the gate.
  factory AssetEntry.fromJson(Map<String, dynamic> json) {
    final Object? path = json['path'];
    final Object? sha256 = json['sha256'];
    final Object? bytes = json['bytes'];
    final Object? sourceUrl = json['sourceUrl'];
    if (path is! String || normalizeAssetPath(path).isEmpty) {
      throw ArgumentError('asset entry has a missing/blank "path"');
    }
    if (sha256 is! String || !_sha256Pattern.hasMatch(sha256)) {
      throw ArgumentError('asset entry "${normalizeAssetPath(path)}" has an '
          'invalid "sha256" (expected 64 hex chars)');
    }
    if (bytes is! int || bytes <= 0) {
      throw ArgumentError('asset entry "${normalizeAssetPath(path)}" has an '
          'invalid "bytes" (expected a positive integer)');
    }
    if (sourceUrl is! String || !sourceUrl.trim().startsWith('http')) {
      throw ArgumentError('asset entry "${normalizeAssetPath(path)}" has a '
          'missing/invalid "sourceUrl"');
    }
    return AssetEntry(
      path: normalizeAssetPath(path),
      sha256: sha256.toLowerCase(),
      bytes: bytes,
      sourceUrl: sourceUrl,
      notes: json['notes'] as String?,
    );
  }
}

/// A parsed asset-reference manifest.
class AssetManifest {
  AssetManifest(this.entries,
      {this.thresholdBytes = kDefaultLargeAssetThresholdBytes});

  final List<AssetEntry> entries;
  final int thresholdBytes;

  /// Returns the entry for [path], or `null` when the path is not listed.
  AssetEntry? entryFor(String path) {
    final String normalized = normalizeAssetPath(path);
    for (final AssetEntry entry in entries) {
      if (entry.normalizedPath == normalized) return entry;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'thresholdBytes': thresholdBytes,
        'assets': entries.map((AssetEntry e) => e.toJson()).toList(),
      };

  /// Parses a full manifest, rejecting duplicate paths and non-positive
  /// thresholds so a malformed manifest fails closed (exit 2) instead of
  /// quietly skipping the gate.
  factory AssetManifest.fromJson(Map<String, dynamic> json) {
    final Object? threshold = json['thresholdBytes'];
    final Object? assets = json['assets'];
    if (threshold is! int || threshold <= 0) {
      throw ArgumentError(
          'manifest "thresholdBytes" must be a positive integer');
    }
    if (assets is! List<dynamic>) {
      throw ArgumentError('manifest "assets" must be a list');
    }
    final List<AssetEntry> parsed = <AssetEntry>[];
    for (final Object? raw in assets) {
      if (raw is! Map<String, dynamic>) {
        throw ArgumentError('manifest "assets" entries must be objects');
      }
      final AssetEntry entry = AssetEntry.fromJson(raw);
      if (parsed
          .any((AssetEntry e) => e.normalizedPath == entry.normalizedPath)) {
        throw ArgumentError(
            'duplicate manifest entry for "${entry.normalizedPath}"');
      }
      parsed.add(entry);
    }
    return AssetManifest(parsed, thresholdBytes: threshold);
  }
}

/// A file discovered by the CLI scanner.
class AssetCandidate {
  const AssetCandidate({required this.path, required this.bytes, this.sha256});

  final String path;
  final int bytes;

  /// Optional SHA-256; when supplied it is checked against the manifest.
  final String? sha256;
}

/// A single guard violation.
class AssetGuardViolation {
  const AssetGuardViolation(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => 'asset guard: $path — $reason';
}

/// Evaluates the large/binary asset policy for [candidates] against [manifest].
///
/// Pure and I/O-free: a large binary with no manifest entry, a byte-size
/// mismatch, or a SHA-256 mismatch yields a [AssetGuardViolation]. Small files,
/// text files and files below the threshold are ignored. Callers that cannot
/// cheaply hash a file may omit [AssetCandidate.sha256]; the path + size checks
/// still apply. [thresholdBytes] overrides the manifest threshold when given.
List<AssetGuardViolation> evaluateAssetGuard(
  Iterable<AssetCandidate> candidates,
  AssetManifest manifest, {
  int? thresholdBytes,
}) {
  final int threshold = thresholdBytes ?? manifest.thresholdBytes;
  final List<AssetGuardViolation> violations = <AssetGuardViolation>[];
  for (final AssetCandidate candidate in candidates) {
    if (!isLargeBinaryAsset(candidate.path, candidate.bytes,
        threshold: threshold)) {
      continue;
    }
    final String path = normalizeAssetPath(candidate.path);
    final AssetEntry? entry = manifest.entryFor(path);
    if (entry == null) {
      violations.add(AssetGuardViolation(
        path,
        'large binary asset is not listed in $kDefaultManifestPath '
        '(add source URL + SHA-256; ask a human before committing it)',
      ));
      continue;
    }
    if (candidate.bytes != entry.bytes) {
      violations.add(AssetGuardViolation(
        path,
        'byte size ${candidate.bytes} does not match manifest ${entry.bytes}',
      ));
    }
    final String? sha = candidate.sha256;
    if (sha != null && sha.toLowerCase() != entry.sha256.toLowerCase()) {
      violations.add(AssetGuardViolation(
        path,
        'SHA-256 does not match the manifest entry',
      ));
    }
  }
  return violations;
}

/// Recursively lists files under [root] as [AssetCandidate]s (path + size).
///
/// Generated/tooling directories are skipped so the gate only sees committed
/// project assets. No hashing is done here (kept dependency-free and fast).
Future<List<AssetCandidate>> scanRepoForAssets(
  Directory root, {
  Set<String> skippedDirectories = kSkippedScanDirectories,
}) async {
  final String base = root.path;
  final List<AssetCandidate> result = <AssetCandidate>[];
  await for (final FileSystemEntity entity in root.list(recursive: true)) {
    if (entity is! File) continue;
    String relative = entity.path.replaceFirst(base, '');
    relative = normalizeAssetPath(relative);
    final List<String> segments = relative.split('/');
    if (segments.any(skippedDirectories.contains)) continue;
    final int bytes = entity.lengthSync();
    if (bytes <= 0) continue;
    result.add(AssetCandidate(path: relative, bytes: bytes));
  }
  return result;
}

/// Parses CLI arguments: an optional manifest path, defaulting to
/// [kDefaultManifestPath]. Throws [ArgumentError] on extra arguments.
String parseAssetGuardCliArgs(List<String> args) {
  if (args.length > 1) {
    throw ArgumentError(
        'expected at most one manifest path, got ${args.length}');
  }
  for (final String arg in args) {
    if (arg.startsWith('-')) throw ArgumentError('unknown option: $arg');
  }
  return args.isEmpty ? kDefaultManifestPath : args.first;
}

Future<void> main(List<String> args) async {
  late final String manifestPath;
  try {
    manifestPath = parseAssetGuardCliArgs(args);
  } on ArgumentError catch (error) {
    stderr.writeln('asset guard: $error');
    exitCode = 2;
    return;
  }

  final File file = File(manifestPath);
  if (!file.existsSync()) {
    stderr.writeln('asset guard: missing "$manifestPath"');
    exitCode = 2;
    return;
  }

  late final AssetManifest manifest;
  try {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('manifest root must be an object');
    }
    manifest = AssetManifest.fromJson(decoded);
  } on Object catch (error) {
    stderr.writeln('asset guard: invalid manifest: $error');
    exitCode = 2;
    return;
  }

  final List<AssetCandidate> candidates =
      await scanRepoForAssets(Directory.current);
  final List<AssetGuardViolation> violations =
      evaluateAssetGuard(candidates, manifest);
  for (final AssetGuardViolation violation in violations) {
    stderr.writeln(violation.toString());
  }
  stdout.writeln(violations.isEmpty
      ? 'asset guard: OK (${manifest.entries.length} manifest entries, '
          'threshold ${manifest.thresholdBytes} bytes)'
      : 'asset guard: ${violations.length} violation(s)');
  exitCode = violations.isEmpty ? 0 : 1;
}
