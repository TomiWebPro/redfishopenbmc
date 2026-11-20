/// Pluggable OEM console parser registry (issue #009 vendor extensibility).
///
/// Redfish defines `GraphicalConsole` / `SerialConsole` / `RemoteConsole`, but
/// vendors publish HTML5 KVM details under their own `Oem.*` subtree (e.g.
/// `Oem.AMI`, `Oem.HPE`, `Oem.OpenBMC`). This file provides the *interface* and
/// a small deterministic registry so vendor-specific parsing can be added later
/// as isolated [KvmOemConsoleParser] implementations without touching the core
/// console model. No vendor parser ships in v1 — the registry is intentionally
/// empty by default and simply delegates to whatever parsers a caller registers.
///
/// The registry is pure Dart: no network, no RedfishClient, no WebView and no
/// dependency on a platform channel, so every rule is unit-testable. It never
/// weakens TLS: a parser-supplied `connectUri` still flows through the existing
/// `KvmConsole.launchStrategy` HTTPS/in-app gating.
library;

/// Normalized information a vendor parser extracted from an `Oem.*` console
/// block.
///
/// Immutable value object so the registry's output can be handed straight to
/// `KvmConsole.fromManager` without further mutation.
class KvmOemConsoleInfo {
  /// Creates vendor console info.
  const KvmOemConsoleInfo({
    required this.vendor,
    this.connectUri,
    this.connectTypesSupported = const <String>[],
    this.serviceEnabled = true,
    this.displayName,
  });

  /// The vendor key that produced this info (e.g. `'AMI'`, `'HPE'`).
  final String vendor;

  /// The console connect URI discovered in the vendor block, if any.
  final String? connectUri;

  /// Advertised connection types (e.g. `['HTML5', 'KVMIP']`).
  final List<String> connectTypesSupported;

  /// Whether the vendor console reports itself enabled.
  final bool serviceEnabled;

  /// Optional human-readable name for the vendor console.
  final String? displayName;

  @override
  String toString() => 'KvmOemConsoleInfo(vendor=$vendor, uri=$connectUri, '
      'enabled=$serviceEnabled)';
}

/// Interface for a vendor-specific OEM console parser (v1: interface only).
///
/// Implementers declare the single `Oem.*` key they understand and translate
/// that vendor's block into a normalized [KvmOemConsoleInfo]. Returning `null`
/// means "this block is not a console I can parse", letting the registry try the
/// next parser. Implementations must be side-effect free.
abstract class KvmOemConsoleParser {
  /// Creates a parser.
  const KvmOemConsoleParser();

  /// The vendor key handled by this parser, e.g. `'AMI'` or `'HPE'`.
  ///
  /// Matching against the `Oem` map is case-insensitive and trimmed.
  String get vendorKey;

  /// Parses the vendor's sub-block into console info, or `null` when the block
  /// does not describe a console this parser understands.
  KvmOemConsoleInfo? parse(Map<String, dynamic> block);
}

/// A deterministic registry of vendor OEM console parsers.
///
/// Parsers are attempted in registration order; the first one whose vendor key
/// is present in the `Oem` map and whose [KvmOemConsoleParser.parse] returns a
/// non-null result wins. Duplicate vendor keys are rejected so resolution stays
/// unambiguous. With no parsers registered (the v1 default) [parse] always
/// returns `null` and callers fall back to the existing strict OEM detection.
class KvmOemRegistry {
  /// Creates a registry, optionally preloaded with [parsers].
  KvmOemRegistry(
      {Iterable<KvmOemConsoleParser> parsers = const <KvmOemConsoleParser>[]}) {
    for (final KvmOemConsoleParser parser in parsers) {
      register(parser);
    }
  }

  final List<KvmOemConsoleParser> _parsers = <KvmOemConsoleParser>[];

  /// Registered parsers in resolution order (unmodifiable snapshot).
  List<KvmOemConsoleParser> get parsers =>
      List<KvmOemConsoleParser>.unmodifiable(_parsers);

  /// Registers [parser], returning `true` on success or `false` when a parser
  /// for the same (case-insensitive, trimmed) vendor key is already present.
  bool register(KvmOemConsoleParser parser) {
    if (_parsers.any(
      (KvmOemConsoleParser p) =>
          _normalizeKey(p.vendorKey) == _normalizeKey(parser.vendorKey),
    )) {
      return false;
    }
    _parsers.add(parser);
    return true;
  }

  /// Resolves an `Oem` map to normalized console info using the registered
  /// parsers, or `null` when none matches / no parser recognizes a console.
  KvmOemConsoleInfo? parse(Map<String, dynamic> oem) {
    for (final KvmOemConsoleParser parser in _parsers) {
      final Object? block = _findVendorBlock(oem, parser.vendorKey);
      if (block is! Map<String, dynamic>) continue;

      // Fault isolation (issue #009 EP-M3): a registered parser is extensible,
      // third-party code and may throw on a hostile/malformed vendor block
      // (bad cast, index/format error). Treat ANY exception as "this parser
      // does not recognize a console here" and try the next one — it must never
      // propagate into `KvmConsole.fromManager` / `KvmCapability.fromManager`
      // (or `KvmCapability.resolveLaunchUri`) where it would blank/crash the
      // gated KVM screen. No valid console is lost: a healthy parser returns
      // normally and stays authoritative, first-match registration order is
      // unchanged, and both factories still fall back to strict generic OEM
      // detection when a parser throws.
      KvmOemConsoleInfo? info;
      try {
        info = parser.parse(block);
      } catch (_) {
        continue;
      }
      if (info != null) return info;
    }
    return null;
  }

  /// Finds the value under a vendor key in [oem], case-insensitively.
  ///
  /// Vendors sometimes nest their console block (`Oem.AMI.KVM`); the search is
  /// bounded to the same depth used by `FeatureRules.oemHasConsole` so a deeply
  /// nested metadata blob cannot cause unbounded recursion.
  static Object? _findVendorBlock(Map<String, dynamic> oem, String vendorKey) {
    return _findAt(oem, _normalizeKey(vendorKey), 0);
  }

  static Object? _findAt(Map<String, dynamic> map, String key, int depth) {
    if (depth > 3) return null;
    for (final MapEntry<String, dynamic> entry in map.entries) {
      if (_normalizeKey(entry.key) == key) return entry.value;
    }
    for (final dynamic value in map.values) {
      if (value is Map<String, dynamic>) {
        final Object? found = _findAt(value, key, depth + 1);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String _normalizeKey(String key) => key.trim().toLowerCase();
}
