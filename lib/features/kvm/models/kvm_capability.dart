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

import 'package:redfishopenbmc/features/kvm/models/kvm_manager_source.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart'
    show kvmOemConsoleEnabled, kvmOemConsoleUri;
import 'package:redfishopenbmc/features/kvm/models/kvm_session_limit.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
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
  /// True when a graphical console is enabled and advertises `KVMIP`, when a
  /// `RemoteConsole` is enabled, or when an `Oem.*` block advertises a console
  /// (`kvm` / `WebConsole`). An enabled `RemoteConsole` is a remote console by
  /// definition, so it counts as supported regardless of its `ConnectType`
  /// spelling (issue #009).
  final bool supported;

  /// Advertised connection types across the manager's console blocks.
  ///
  /// Canonical Redfish values (`KVMIP`, `HTML5`, `SSH`, …) plus the marker
  /// `'Oem'` when an OEM console is detected. Order is deterministic (graphical
  /// first, then serial, then remote, then the OEM marker) and duplicates are removed
  /// case-insensitively (a BMC that mixes casing across console blocks must
  /// not render the same type twice on the capability card). The `'Oem'` marker
  /// is deduped case-insensitively against a literal `'OEM'` ConnectType too, so
  /// a BMC that already advertises that canonical value gets a single chip.
  /// When built via [fromManager], types from an explicitly disabled console
  /// block are skipped while any non-disabled block advertises a type — matching
  /// the enabled-preference of [uri] and [maxSessions] (issue #009).
  final List<String> connectTypes;

  /// Whether any standard console block (graphical, serial or remote) reports
  /// itself enabled, or an OEM console is present.
  final bool serviceEnabled;

  /// The maximum number of concurrent sessions, or `null` when unreported or
  /// out of spec (negative — DMTF `Manager` defines a minimum of 0).
  ///
  /// Parsed through the shared [kvmSessionLimit] helper so an integer-valued
  /// JSON number emitted as a double (e.g. `4.0`) is tolerated on the capability
  /// card exactly as it is on the per-console card (issue #009).
  final int? maxSessions;

  /// The resolved console URI: a standard console block's `ConnectUri`
  /// (preferring a block that is not explicitly disabled — the actual,
  /// launchable console endpoint), then `GraphicalConsole.@odata.id`, then an
  /// OEM `KVM`/`WebConsole` `Uri`; `null` when none is exposed. See
  /// [KvmCapability.resolveLaunchUri].
  final String? uri;

  /// The `@odata.id` of the manager resource this capability was read from.
  final String? sourceManagerUri;

  /// A control-safe manager URI, suitable as a last-resort source disclosure /
  /// clipboard fallback on the capability card (issues #009 / #021, RM-4).
  ///
  /// Mirrors `KvmConsole.safeManagerUri`: [sourceManagerUri] is a BMC-supplied
  /// `@odata.id`, so a hostile BMC can publish CRLF / NUL / raw space / backslash
  /// / Unicode separators or a malformed or encoded-control `%` escape. Rendering
  /// or copying that verbatim would reintroduce the exact header/clipboard-
  /// injection risk the launch plan's fail-closed target gate exists to prevent.
  /// Route it through the same shared [isControlSafeConsoleUri] gate the launch
  /// plan and the per-console card use: a safe source is kept byte-for-byte (no
  /// valid source is lost), an unsafe or absent one is replaced by a
  /// deterministic path synthesized from [managerId] with every non-unreserved
  /// byte percent-encoded (via [Uri.encodeComponent]), so the fallback can never
  /// carry the hostile code point back to the operator. Keeping this getter on
  /// both models means the capability card and the console card can never drift
  /// on what counts as a safe manager source.
  String get safeManagerUri {
    if (isControlSafeConsoleUri(sourceManagerUri)) return sourceManagerUri!;
    final String encodedId = Uri.encodeComponent(managerId.trim());
    return '/redfish/v1/Managers/${encodedId.isEmpty ? 'manager' : encodedId}';
  }

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

  /// Whether [launchUri] is a genuine HTTPS (TLS-encrypted) target with a
  /// non-empty host and no embedded control characters.
  ///
  /// Mirrors `KvmConsole.hasSecureLaunchUri` so the capability card can tell a
  /// TLS-protected resolved endpoint from an unencrypted one. In-app rendering
  /// must never downgrade a BMC console to plaintext (issue #021 — never weaken
  /// TLS), and the capability card surfaces the resolved endpoint to the
  /// operator, so it needs the same transport classification as the console
  /// card / viewer. Both models and the fail-closed launch plan share
  /// [isSecureHttpsConsoleUri], so a CRLF/NUL-bearing (or otherwise malformed)
  /// target can never be called secure on one surface and refused on another.
  /// A Redfish `@odata.id` resource path has no scheme and is therefore neither
  /// secure nor insecure HTTP.
  bool get hasSecureLaunchUri => isSecureHttpsConsoleUri(launchUri);

  /// Whether [launchUri] is an HTTP(S) URL suitable for browser/WebView launch.
  ///
  /// Mirrors `KvmConsole.hasHttpLaunchUri` via the shared, control-char-safe
  /// [isHttpConsoleUri] classifier so both KVM views agree on what counts as a
  /// browser-launchable URI, including for malformed targets (issue #009).
  bool get hasHttpLaunchUri => isHttpConsoleUri(launchUri);

  /// The capability card uses this to flag a resolved endpoint whose console
  /// video and injected input would travel in the clear, matching the
  /// `KvmConsoleViewerPage` warning for an `insecureHtml5` console (issue #021).
  ///
  /// Uses the shared, control-char-safe [isPlaintextHttpConsoleUri] classifier
  /// (the plaintext sibling of [hasSecureLaunchUri]), matching the console
  /// view's classification for malformed targets. This is read-only
  /// classification — it never changes transport security.
  bool get usesInsecureHttpLaunchUri => isPlaintextHttpConsoleUri(launchUri);

  /// Whether [launchUri] uses a protocol that requires an external/native client
  /// (VNC/RFB/KVMIP/serial SSH/Telnet/IPMI) rather than browser/WebView rendering.
  ///
  /// Mirrors `KvmConsole.requiresExternalConsoleClient` through the same shared
  /// fail-closed [isExternalClientConsoleUri] classifier, so the per-manager
  /// capability card and the per-console card/viewer classify the same resolved
  /// endpoint identically (EP-M2 cross-surface classifier parity, #009/#021).
  bool get requiresExternalConsoleClient =>
      isExternalClientConsoleUri(launchUri);

  /// Human-readable label for the external-client protocol of [launchUri], or
  /// `null` when no external client is required.
  ///
  /// Delegates to the same shared classifier as [requiresExternalConsoleClient]
  /// and `KvmConsole`, so both KVM views announce identical guidance.
  String? get externalClientProtocolLabel =>
      externalClientConsoleProtocol(launchUri);

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
  /// Reads `GraphicalConsole`, `SerialConsole` and `RemoteConsole`, scans
  /// `Oem.*` for console keys (via the shared strict
  /// `FeatureRules.oemHasConsole` contract), and resolves the launch URI through
  /// [resolveLaunchUri]. Detection rule: `supported = (graphical enabled &&
  /// KVMIP advertised) || remote enabled || (OEM console && OEM enabled)`.
  /// An OEM console counts only when its own `ServiceEnabled` / `Enabled`
  /// flags do not explicitly disable it (issue #009).
  factory KvmCapability.fromManager(
    Map<String, dynamic> body, {
    required String managerId,
    String? sourceManagerUri,
  }) {
    final Map<String, dynamic>? graphical =
        _consoleBlock(body, 'GraphicalConsole');
    final Map<String, dynamic>? serial = _consoleBlock(body, 'SerialConsole');
    // `RemoteConsole` is a standard console block everywhere else in the KVM
    // feature: KvmConsole.fromManager parses it and resolveLaunchUri reads its
    // ConnectUri. Aggregate it here too, so a manager exposing only a
    // RemoteConsole is not reported as disabled/unsupported on the capability
    // card while its per-console card is enabled and launchable (issue #009).
    final Map<String, dynamic>? remote = _consoleBlock(body, 'RemoteConsole');

    final bool oemConsole = FeatureRules.oemHasConsole(body['Oem']);
    // The OEM path was the one console source that ignored enablement: any
    // console-like Oem key made the capability supported + enabled. Read the
    // OEM console block's own flags with the shared helper (the same block the
    // URI is resolved from) so an explicitly disabled OEM console is not
    // advertised as usable, while an OEM block that omits the flag stays
    // enabled. Mirrors `KvmConsole.fromManager` (issue #009).
    final bool oemEnabled = kvmOemConsoleEnabled(body['Oem']);
    final bool graphicalEnabled = _blockEnabled(graphical);
    final bool serialEnabled = _blockEnabled(serial);
    final bool remoteEnabled = _blockEnabled(remote);

    // Aggregate the advertised connection types across the manager's standard
    // console blocks, preferring one the operator can actually open (issue
    // #009). Mirrors the enabled-preference already applied to the resolved
    // URI and the aggregate session limit, so the capability card never shows
    // a KVMIP chip sourced from a console that is explicitly disabled.
    final List<String> types =
        _aggregateConnectTypes(body, oemConsole: oemConsole);

    final bool kvmIp = _advertises(graphical, 'KVMIP');
    // A graphical console needs the KVMIP connection type to count as KVM
    // (a purely HTML5 graphical console is a web console, not KVM-over-IP). A
    // `RemoteConsole` is a remote console by definition, so an enabled one is
    // supported regardless of the exact `ConnectType` spelling a BMC uses.
    final bool supported = (graphicalEnabled && kvmIp) ||
        remoteEnabled ||
        (oemConsole && oemEnabled);
    // Aggregate the session limit across standard console blocks, preferring an
    // enabled block so the capability card never reports a disabled console's
    // limit over the launchable console's (issue #009). Mirrors the
    // enabled-preference in resolveLaunchUri / _standardConnectUri.
    final int? maxSessions = _aggregateMaxSessions(body);

    return KvmCapability(
      managerId: managerId,
      supported: supported,
      connectTypes: List<String>.unmodifiable(types),
      serviceEnabled: graphicalEnabled ||
          serialEnabled ||
          remoteEnabled ||
          (oemConsole && oemEnabled),
      maxSessions: maxSessions,
      uri: resolveLaunchUri(body),
      // RS-5: resolve the source through the SAME shared normalizer the
      // console card uses — a padded value is trimmed, a blank / non-string
      // override falls through to the body `@odata.id`, and both fall back to
      // the manager-id path. The explicit override still wins when usable, so
      // both KVM views always agree on a manager's source identity (issue
      // #009).
      sourceManagerUri:
          kvmManagerSourceUri(sourceManagerUri, managerId, body['@odata.id']),
      graphicalKvmIp: kvmIp,
    );
  }

  /// Resolves the console URI for a Redfish manager [body].
  ///
  /// Preference order:
  ///  1. a standard console block's `ConnectUri` (graphical → serial → remote),
  ///     preferring a block that is not explicitly disabled — the actual,
  ///     launchable console endpoint already read by `KvmConsole.fromManager`;
  ///     kept in sync so the capability card never recommends a disabled
  ///     console's URI over an enabled one (issue #009);
  ///  2. `GraphicalConsole.@odata.id` (the standard graphical console link,
  ///     retained for managers that expose only a Redfish resource link) — but
  ///     when that graphical console is explicitly disabled and an OEM console
  ///     URI is available, the OEM URI wins (a disabled console cannot be
  ///     opened, issue #009);
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
    final String? odata =
        graphical == null ? null : _nonEmptyString(graphical['@odata.id']);
    // Shared with KvmConsole.fromManager so the per-console and per-manager
    // cards resolve the same OEM endpoint for the same manager (issue #009).
    final String? oemUri = kvmOemConsoleUri(body['Oem']);
    if (odata != null) {
      // A graphical console that explicitly reports itself disabled cannot be
      // opened (its KvmConsole.launchStrategy is `disabled` and canOpenConsole
      // is false), so its Redfish API resource link must not be recommended as
      // the capability card's "Resolved URI" over a genuinely launchable OEM
      // console URI that the per-console card surfaces (issue #009). A block
      // that omits the enablement flag is "unknown" (most mockups do) and keeps
      // its link's priority; when no OEM URI exists the link is still the best
      // available choice — this only changes which URI wins when a launchable
      // one exists, so all prior resolveLaunchUri behaviour is preserved.
      if (_explicitlyDisabled(graphical!) && oemUri != null) return oemUri;
      return odata;
    }
    return oemUri;
  }

  /// Returns the launchable `ConnectUri` across the standard console blocks
  /// (graphical → serial → remote), or `null`.
  ///
  /// A `ConnectUri` on a console that explicitly reports itself disabled
  /// (`ServiceEnabled: false` / `Enabled: false`) cannot be opened — that
  /// console's `KvmConsole.launchStrategy` is `disabled` and `canOpenConsole`
  /// is false, and `KvmService.pickPrimary` now prefers an openable console.
  /// Recommending such a URI as the capability card's "Resolved URI" would
  /// point the operator at a console they cannot launch (issue #009). So an
  /// explicitly disabled block is skipped while any non-disabled block with a
  /// usable URI remains. A block that omits the enablement flag is "unknown"
  /// and keeps its URI (most BMC mockups omit it), and when every URI-bearing
  /// block is disabled the URI is still surfaced as the best available choice
  /// — this only changes which URI wins when a launchable one exists.
  static String? _standardConnectUri(Map<String, dynamic> body) {
    const List<String> names = <String>[
      'GraphicalConsole',
      'SerialConsole',
      'RemoteConsole',
    ];

    // First pass: prefer a block that is not explicitly disabled.
    for (final String name in names) {
      final Map<String, dynamic>? block = _consoleBlock(body, name);
      if (block == null || _explicitlyDisabled(block)) continue;
      final String? uri = _nonEmptyString(block['ConnectUri']);
      if (uri != null) return uri;
    }
    // Fallback: when the only URI source is an explicitly disabled block,
    // still surface it rather than showing no URI at all (preserves the prior
    // behaviour for all-disabled/URI-less fixtures).
    for (final String name in names) {
      final Map<String, dynamic>? block = _consoleBlock(body, name);
      if (block == null) continue;
      final String? uri = _nonEmptyString(block['ConnectUri']);
      if (uri != null) return uri;
    }
    return null;
  }

  /// True when a console block explicitly reports itself disabled.
  ///
  /// A block that omits both enablement members is "unknown" (not disabled)
  /// so a mockup without the flag keeps its URI. A block carrying a truthy
  /// enablement member is enabled even if the other member is false, matching
  /// the shared `_blockEnabled` / `KvmConsole.serviceEnabled` rule.
  static bool _explicitlyDisabled(Map<String, dynamic> block) {
    if (_blockEnabled(block)) return false;
    return block.containsKey('ServiceEnabled') || block.containsKey('Enabled');
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
      (dynamic e) => e is String && e.trim().toUpperCase() == type,
    );
  }

  /// Aggregates `ConnectTypesSupported` across the standard console blocks
  /// (graphical → serial → remote), preferring a block that is not explicitly
  /// disabled, then appends the `'Oem'` marker when an OEM console is present.
  ///
  /// A type advertised only by an explicitly disabled console
  /// (`ServiceEnabled: false` / `Enabled: false`) is not one the operator can
  /// use — that console's `KvmConsole.launchStrategy` is `disabled` and
  /// `KvmService.pickPrimary` will not choose it. Rendering its chips on the
  /// capability card would suggest a connection path the operator cannot open
  /// (issue #009), so an explicitly disabled block is skipped while any
  /// non-disabled block advertises a type. A block that omits the enablement
  /// flag is "unknown" (not disabled) and keeps its types, and when every
  /// type-bearing block is disabled the types are still surfaced as the best
  /// available choice — this only changes which types win when an enabled
  /// console exists. Mirrors `_standardConnectUri` / `_aggregateMaxSessions`.
  static List<String> _aggregateConnectTypes(
    Map<String, dynamic> body, {
    required bool oemConsole,
  }) {
    const List<String> names = <String>[
      'GraphicalConsole',
      'SerialConsole',
      'RemoteConsole',
    ];

    final List<String> types = <String>[];

    // First pass: prefer types from a block that is not explicitly disabled.
    for (final String name in names) {
      final Map<String, dynamic>? block = _consoleBlock(body, name);
      if (block == null || _explicitlyDisabled(block)) continue;
      _appendTypes(types, block);
    }
    // Fallback: when the only advertised types come from explicitly disabled
    // blocks, still surface them rather than showing no types at all
    // (preserves prior behaviour for all-disabled fixtures).
    if (types.isEmpty) {
      for (final String name in names) {
        final Map<String, dynamic>? block = _consoleBlock(body, name);
        if (block == null) continue;
        _appendTypes(types, block);
      }
    }
    // The 'Oem' marker is a display chip, not a distinct Redfish ConnectType:
    // 'OEM' is itself a valid canonical value a BMC may advertise in
    // ConnectTypesSupported. Append the marker only when no block already
    // advertised an OEM type in any casing, so the capability card never
    // renders two case-different OEM chips where the per-console card shows one
    // — keeping the documented case-insensitive dedup contract (issue #009).
    if (oemConsole &&
        !types.any((String type) => type.toUpperCase() == 'OEM')) {
      types.add('Oem');
    }
    return types;
  }

  /// Appends a block's `ConnectTypesSupported` entries to [target].
  ///
  /// `ConnectTypesSupported` is an array of Redfish `ConnectType` strings, so a
  /// `null` / numeric / boolean entry is malformed data and is ignored rather
  /// than stringified into a literal "null"/"42" chip on the capability card.
  /// Dedup is case-insensitive so a BMC that emits the same canonical type in
  /// different casing across console blocks is rendered only once; the first
  /// (graphical-first) spelling is kept for deterministic display. Mirrors
  /// `KvmConsole._normalizedConnectTypes` (issue #009).
  static void _appendTypes(List<String> target, Map<String, dynamic>? block) {
    if (block == null) return;
    final dynamic value = block['ConnectTypesSupported'];
    if (value is! List<dynamic>) return;
    for (final dynamic entry in value) {
      if (entry is! String) continue;
      final String type = entry.trim();
      if (type.isEmpty) continue;
      final bool duplicate = target.any(
        (String existing) => existing.toUpperCase() == type.toUpperCase(),
      );
      if (!duplicate) target.add(type);
    }
  }

  /// Aggregates `MaxConcurrentSessions` across the standard console blocks
  /// (graphical → serial → remote), preferring a block that is not explicitly
  /// disabled.
  ///
  /// A limit on a console that explicitly reports itself disabled
  /// (`ServiceEnabled: false` / `Enabled: false`) is not one the operator can
  /// actually use — that console's `KvmConsole.launchStrategy` is `disabled`
  /// and `KvmService.pickPrimary` now prefers an openable console. Reporting
  /// such a limit as the capability card's "Max sessions" would contradict the
  /// launchable console (issue #009). So an explicitly disabled block is
  /// skipped while any non-disabled block reports a valid limit. A block that
  /// omits the enablement flag is "unknown" (not disabled) and keeps its limit,
  /// and when every limit-bearing block is disabled the limit is still surfaced
  /// as the best available choice — this only changes which limit wins when an
  /// enabled one exists.
  static int? _aggregateMaxSessions(Map<String, dynamic> body) {
    const List<String> names = <String>[
      'GraphicalConsole',
      'SerialConsole',
      'RemoteConsole',
    ];

    // First pass: prefer a limit from a block that is not explicitly disabled.
    for (final String name in names) {
      final Map<String, dynamic>? block = _consoleBlock(body, name);
      if (block == null || _explicitlyDisabled(block)) continue;
      final int? limit = kvmSessionLimit(block['MaxConcurrentSessions']);
      if (limit != null) return limit;
    }
    // Fallback: when the only limit source is an explicitly disabled block,
    // still surface it rather than showing no limit (preserves the prior
    // behaviour for all-disabled fixtures).
    for (final String name in names) {
      final Map<String, dynamic>? block = _consoleBlock(body, name);
      if (block == null) continue;
      final int? limit = kvmSessionLimit(block['MaxConcurrentSessions']);
      if (limit != null) return limit;
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
