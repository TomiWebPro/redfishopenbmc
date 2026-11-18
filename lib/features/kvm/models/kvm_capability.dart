/// Per-manager remote-KVM capability summary (issue #009).
///
/// [KvmConsole] models one Redfish console *block*; a single manager can expose
/// several. [KvmCapability] is the aggregated, immutable view the capability
/// card in `KvmView` renders: whether a manager can actually serve a console,
/// the advertised connection types, the session limit and the URI to open.
///
/// Detection and URI resolution are pure and widget-free so every rule is
/// unit-testable. No WebView/protocol dependency is involved and no transport
/// is ever weakened — a resolved URI is simply exposed to the caller (issue
/// #009 / #021).
library;

import 'package:redfishopenbmc/redfish/discovery/feature_rules.dart';

/// Immutable summary of the remote-console capability of one manager.
class KvmCapability {
  /// Creates a [KvmCapability].
  ///
  /// Prefer [KvmCapability.fromManager] when starting from a Redfish manager
  /// body — it computes [supported], [serviceEnabled] and the resolved [uri]
  /// per the detection rules.
  const KvmCapability({
    required this.managerId,
    required this.supported,
    required this.connectTypes,
    required this.serviceEnabled,
    this.maxSessions,
    this.uri,
    this.sourceManagerUri,
    this.graphicalKvmIp,
  });

  /// The `Id` of the manager that exposes this capability (e.g. `'BMC'`).
  final String managerId;

  /// Whether this manager can serve a usable console.
  ///
  /// True when a graphical console is enabled and advertises `KVMIP`, or when
  /// an `Oem.*` block advertises a console (`kvm` / `WebConsole`).
  final bool supported;

  /// Advertised connection types across the manager's console blocks.
  ///
  /// Canonical Redfish values (`KVMIP`, `HTML5`, `SSH`, …) plus the marker
  /// `'Oem'` when an OEM console is detected. Order is deterministic (graphical
  /// first, then serial, then the OEM marker) and duplicates are removed
  /// case-insensitively (a BMC that mixes casing across console blocks must
  /// not render the same type twice on the capability card).
  final List<String> connectTypes;

  /// Whether any standard console block reports itself enabled, or an OEM
  /// console is present.
  final bool serviceEnabled;

  /// The maximum number of concurrent sessions, or `null` when unreported or
  /// out of spec (negative — DMTF `Manager` defines a minimum of 0).
  final int? maxSessions;

  /// The resolved console URI: the first standard console block's `ConnectUri`
  /// (the actual, launchable console endpoint), then `GraphicalConsole.
  /// @odata.id`, then an OEM `KVM`/`WebConsole` `Uri`; `null` when none is
  /// exposed. See [KvmCapability.resolveLaunchUri].
  final String? uri;

  /// The `@odata.id` of the manager resource this capability was read from.
  final String? sourceManagerUri;

  /// Authoritative `KVMIP` detection from the graphical console — the same
  /// source [supported] keys off — when built via [fromManager].
  ///
  /// `null` for directly constructed capabilities (e.g. widget-test fixtures),
  /// in which case [supportsKvmIp] falls back to scanning [connectTypes].
  final bool? graphicalKvmIp;

  /// The normalized, launchable console [uri].
  ///
  /// Returns [uri] trimmed when it is non-blank, or `null` otherwise. Trimming
  /// is essential because `Uri.tryParse` rejects leading/trailing whitespace —
  /// a padded-but-valid endpoint stored verbatim would be displayed with stray
  /// whitespace and could not be opened. Mirrors `KvmConsole.launchUri` so both
  /// KVM views agree for any construction path (issue #009).
  String? get launchUri {
    final String? value = uri;
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Whether a usable (non-blank) console [uri] was resolved.
  ///
  /// A whitespace-only [uri] is not an endpoint: treating it as one makes the
  /// capability card render an empty "Resolved URI:" row instead of the source
  /// notice. Mirrors `KvmConsole.launchUri` so both KVM views agree (issue #009).
  bool get hasUri => launchUri != null;

  /// True when the graphical console advertises a `KVMIP` connection type.
  ///
  /// Uses the graphical-only detection bit computed by [fromManager], keeping
  /// this getter in lockstep with [supported] (which also keys off the
  /// graphical console). Reading the aggregate [connectTypes] here would
  /// wrongly report KVMIP support for a manager that only lists `KVMIP` on a
  /// serial/OEM block. Matching is case-insensitive and trimmed because some
  /// BMCs emit a different case or surrounding whitespace.
  bool get supportsKvmIp =>
      graphicalKvmIp ??
      connectTypes.any(
        (String type) => type.trim().toUpperCase() == 'KVMIP',
      );

  /// Builds a capability summary from a Redfish manager [body].
  ///
  /// Reads `GraphicalConsole` and `SerialConsole`, scans `Oem.*` for console
  /// keys (via the shared strict `FeatureRules.oemHasConsole` contract), and
  /// resolves the launch URI through [resolveLaunchUri]. Detection rule:
  /// `supported = (graphical enabled && KVMIP advertised) || OEM console`.
  factory KvmCapability.fromManager(
    Map<String, dynamic> body, {
    required String managerId,
    String? sourceManagerUri,
  }) {
    final Map<String, dynamic>? graphical =
        _consoleBlock(body, 'GraphicalConsole');
    final Map<String, dynamic>? serial = _consoleBlock(body, 'SerialConsole');

    final bool oemConsole = FeatureRules.oemHasConsole(body['Oem']);
    final bool graphicalEnabled = _blockEnabled(graphical);
    final bool serialEnabled = _blockEnabled(serial);

    final List<String> types = <String>[];
    _appendTypes(types, graphical);
    _appendTypes(types, serial);
    if (oemConsole && !types.contains('Oem')) types.add('Oem');

    final bool kvmIp = _advertises(graphical, 'KVMIP');
    final bool supported = (graphicalEnabled && kvmIp) || oemConsole;
    final int? maxSessions = _maxSessions(graphical) ?? _maxSessions(serial);

    return KvmCapability(
      managerId: managerId,
      supported: supported,
      connectTypes: List<String>.unmodifiable(types),
      serviceEnabled: graphicalEnabled || serialEnabled || oemConsole,
      maxSessions: maxSessions,
      uri: resolveLaunchUri(body),
      sourceManagerUri: sourceManagerUri ??
          (body['@odata.id'] as String?) ??
          '/redfish/v1/Managers/$managerId',
      graphicalKvmIp: kvmIp,
    );
  }

  /// Resolves the console URI for a Redfish manager [body].
  ///
  /// Preference order:
  ///  1. a standard console block's `ConnectUri` (graphical → serial → remote)
  ///     — the actual, launchable console endpoint already read by
  ///     `KvmConsole.fromManager`; kept in sync so the per-manager capability
  ///     card and the per-console card never disagree about the endpoint;
  ///  2. `GraphicalConsole.@odata.id` (the standard graphical console link,
  ///     retained for managers that expose only a Redfish resource link);
  ///  3. an OEM `KVM` / `WebConsole` block's `Uri` member (bounded recursive
  ///     search, case-insensitive key matching);
  ///  4. `null` when none is exposed.
  ///
  /// Resolution is read-only: it exposes a URI string to the caller and never
  /// opens a connection or changes transport security (issues #009 / #021).
  static String? resolveLaunchUri(Map<String, dynamic> body) {
    // A `ConnectUri` is the endpoint a console client actually connects to,
    // so it outranks a Redfish `@odata.id` resource link (which is a JSON API
    // path, not a browser-launchable console URL).
    final String? connectUri = _standardConnectUri(body);
    if (connectUri != null) return connectUri;

    final Map<String, dynamic>? graphical =
        _consoleBlock(body, 'GraphicalConsole');
    if (graphical != null) {
      final String? odata = _nonEmptyString(graphical['@odata.id']);
      if (odata != null) return odata;
    }
    return _findOemConsoleUri(body['Oem'], 0);
  }

  /// Returns the first non-empty `ConnectUri` across the standard console
  /// blocks (graphical → serial → remote), or `null`.
  static String? _standardConnectUri(Map<String, dynamic> body) {
    for (final String name in <String>[
      'GraphicalConsole',
      'SerialConsole',
      'RemoteConsole',
    ]) {
      final Map<String, dynamic>? block = _consoleBlock(body, name);
      if (block == null) continue;
      final String? uri = _nonEmptyString(block['ConnectUri']);
      if (uri != null) return uri;
    }
    return null;
  }

  /// Returns a console block from [body] only when it is a JSON object.
  static Map<String, dynamic>? _consoleBlock(
    Map<String, dynamic> body,
    String name,
  ) {
    final dynamic value = body[name];
    return value is Map<String, dynamic> ? value : null;
  }

  /// True when a console block reports itself enabled (`ServiceEnabled` or the
  /// legacy `Enabled` field).
  static bool _blockEnabled(Map<String, dynamic>? block) {
    if (block == null) return false;
    return block['ServiceEnabled'] == true || block['Enabled'] == true;
  }

  /// Whether [block] advertises [type] in `ConnectTypesSupported` (case- and
  /// whitespace-insensitive).
  static bool _advertises(Map<String, dynamic>? block, String type) {
    if (block == null) return false;
    final dynamic value = block['ConnectTypesSupported'];
    if (value is! List<dynamic>) return false;
    return value.any(
      (dynamic e) => e.toString().trim().toUpperCase() == type,
    );
  }

  /// Appends a block's `ConnectTypesSupported` entries to [target].
  ///
  /// Dedup is case-insensitive so a BMC that emits the same canonical type in
  /// different casing across console blocks is rendered only once; the first
  /// (graphical-first) spelling is kept for deterministic display.
  static void _appendTypes(List<String> target, Map<String, dynamic>? block) {
    if (block == null) return;
    final dynamic value = block['ConnectTypesSupported'];
    if (value is! List<dynamic>) return;
    for (final dynamic entry in value) {
      final String type = entry.toString().trim();
      if (type.isEmpty) continue;
      final bool duplicate = target.any(
        (String existing) => existing.toUpperCase() == type.toUpperCase(),
      );
      if (!duplicate) target.add(type);
    }
  }

  /// Reads a block's `MaxConcurrentSessions` as a spec-valid limit, or `null`.
  ///
  /// DMTF `Manager` defines `MaxConcurrentSessions` with a minimum of 0
  /// (`Manager.v1_19_0.json`). A negative value is out of spec (and is used by
  /// some BMCs as a sentinel for "unlimited"), so it is treated as unreported —
  /// the capability card must not render "Max sessions: -1". This mirrors
  /// `KvmConsole._sessionLimit` so both KVM views agree (issue #009).
  static int? _maxSessions(Map<String, dynamic>? block) {
    if (block == null) return null;
    final dynamic value = block['MaxConcurrentSessions'];
    final int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is String) {
      parsed = int.tryParse(value.trim());
    } else {
      parsed = null;
    }
    return (parsed == null || parsed < 0) ? null : parsed;
  }

  /// Finds an OEM console URI in [node], recursing to a bounded depth.
  static String? _findOemConsoleUri(dynamic node, int depth) {
    if (depth > 3 || node is! Map<dynamic, dynamic>) return null;

    // Prefer a direct console-like key whose map carries a `Uri` member.
    for (final dynamic entry in node.entries) {
      final String key = entry.key.toString().toLowerCase();
      if ((key.contains('kvm') ||
              key.contains('console') ||
              key.contains('webconsole')) &&
          entry.value is Map<dynamic, dynamic>) {
        final String? uri = _uriFromMap(entry.value as Map<dynamic, dynamic>);
        if (uri != null) return uri;
      }
    }
    // Otherwise search nested vendor blocks.
    for (final dynamic value in node.values) {
      final String? uri = _findOemConsoleUri(value, depth + 1);
      if (uri != null) return uri;
    }
    return null;
  }

  /// Returns the `Uri` member of an OEM console map, if present and non-empty.
  static String? _uriFromMap(Map<dynamic, dynamic> map) {
    for (final dynamic entry in map.entries) {
      if (entry.key.toString().toLowerCase() == 'uri') {
        final String? uri = _nonEmptyString(entry.value);
        if (uri != null) return uri;
      }
    }
    return null;
  }

  /// Returns [value] as a trimmed, non-blank string, or `null`.
  ///
  /// A whitespace-only value is not a usable `ConnectUri`, `@odata.id` or OEM
  /// console `Uri` — treating it as one would shadow a valid fallback (the
  /// graphical link / OEM URI) and render a blank "Resolved URI:" row. A
  /// padded-but-valid value is trimmed so the resolved URI is launchable and
  /// displays cleanly. Mirrors `KvmConsole._uriString` so both KVM views agree
  /// (issue #009).
  static String? _nonEmptyString(dynamic value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  String toString() =>
      'KvmCapability(manager=$managerId, supported=$supported, '
      'types=$connectTypes, enabled=$serviceEnabled, uri=$uri)';
}
