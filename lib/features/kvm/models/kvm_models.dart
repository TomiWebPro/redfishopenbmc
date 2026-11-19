/// Remote KVM / console models (issue #009).
///
/// Mirrors the Redfish `Manager` console services (`GraphicalConsole`,
/// `SerialConsole`, `RemoteConsole`). A BMC may expose several console types
/// at once; [KvmConsole.fromManager] extracts each into its own immutable
/// [KvmConsole] so the UI can list them uniformly.
library;

import 'package:redfishopenbmc/features/kvm/models/kvm_oem_registry.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';
import 'package:redfishopenbmc/redfish/discovery/feature_rules.dart';

/// The kind of Redfish console a [KvmConsole] represents.
enum KvmConsoleType {
  /// A `GraphicalConsole` (KVM-over-IP / remote desktop style console).
  graphical,

  /// A `SerialConsole` (SSH / Telnet / IPMI serial-over-LAN).
  serial,

  /// A `RemoteConsole` (typically an HTML5 web console).
  remote,

  /// An OEM-specific console not covered by the standard Redfish types.
  oem;

  /// Maps a Redfish console block name (e.g. `'GraphicalConsole'`) to a
  /// [KvmConsoleType], or [KvmConsoleType.oem] when [value] is `null` or
  /// unrecognized.
  static KvmConsoleType fromRedfish(String? value) {
    switch (value?.toLowerCase()) {
      case 'graphicalconsole':
        return KvmConsoleType.graphical;
      case 'serialconsole':
        return KvmConsoleType.serial;
      case 'remoteconsole':
        return KvmConsoleType.remote;
      default:
        return KvmConsoleType.oem;
    }
  }

  /// Human-readable label for the console type.
  String get label {
    switch (this) {
      case KvmConsoleType.graphical:
        return 'Graphical Console';
      case KvmConsoleType.serial:
        return 'Serial Console';
      case KvmConsoleType.remote:
        return 'Remote Console';
      case KvmConsoleType.oem:
        return 'OEM Console';
    }
  }

  /// The Redfish property name backing this console type, when standard.
  String? get redfishName {
    switch (this) {
      case KvmConsoleType.graphical:
        return 'GraphicalConsole';
      case KvmConsoleType.serial:
        return 'SerialConsole';
      case KvmConsoleType.remote:
        return 'RemoteConsole';
      case KvmConsoleType.oem:
        return null;
    }
  }
}

/// The deterministic launch strategy for a [KvmConsole].
///
/// A single source of truth for "what can the app do with this console", so the
/// viewer and any future launch flow cannot disagree. Priority order matters:
/// an unopenable console (no URI / disabled) is decided before transport
/// classification, and a plaintext HTTP console is always blocked before any
/// in-app or browser rendering is offered (issue #021 — never weaken TLS).
enum KvmLaunchStrategy {
  /// Enabled HTML5 console with a TLS-encrypted (HTTPS) connect URI — the
  /// in-app rendering path (still pending a platform WebView dependency).
  inAppHtml5,

  /// HTML5 console whose connect URI is plaintext HTTP — in-app rendering is
  /// deliberately blocked with an explicit enable-HTTPS warning.
  insecureHtml5,

  /// A protocol (VNC/RFB/KVMIP/serial) that needs an external client.
  externalClient,

  /// A TLS-encrypted HTTPS URI that is not an HTML5 client — safe to suggest
  /// opening in an external secure browser (never offered for plaintext HTTP).
  secureBrowser,

  /// The console service is disabled on the BMC (`ServiceEnabled == false`).
  disabled,

  /// No direct connect URI and no strategy applies.
  noUri;
}

/// An immutable view of a single Redfish console service found on a [Manager].
///
/// A manager body may carry a `GraphicalConsole`, `SerialConsole` and/or
/// `RemoteConsole` block; [fromManager] produces one [KvmConsole] per detected
/// block. Null-safe: any absent field yields a sensible default so the UI can
/// render a console even when the BMC omits metadata.
class KvmConsole {
  /// Creates a [KvmConsole].
  const KvmConsole({
    required this.type,
    required this.managerId,
    this.connectTypesSupported = const <String>[],
    this.serviceEnabled = false,
    this.maxConcurrentSessions,
    this.connectUri,
    required this.sourceManagerUri,
    this.oem,
  });

  /// The kind of console (graphical / serial / remote / oem).
  final KvmConsoleType type;

  /// The `Id` of the manager that exposes this console (e.g. `'BMC'`).
  final String managerId;

  /// The connection types advertised by `ConnectTypesSupported`, e.g.
  /// `['KVMIP']`, `['VNC','HTML5']`, or `['SSH','Telnet']`.
  ///
  /// Parsed from the Redfish block with trimming, empty-entry removal and
  /// case-insensitive dedup (first-seen spelling kept), matching
  /// `KvmCapability.connectTypes` so the console card and the capability card
  /// never disagree about the same manager's types (issue #009).
  final List<String> connectTypesSupported;

  /// Whether the console service is enabled.
  ///
  /// Reads the canonical `ServiceEnabled` member, or the legacy `Enabled`
  /// member honored by discovery (`FeatureRules`) and `KvmCapability`. A
  /// non-bool value is treated as disabled rather than throwing, keeping the
  /// console card / viewer consistent with the capability card (issue #009).
  final bool serviceEnabled;

  /// The maximum number of concurrent sessions (`MaxConcurrentSessions`),
  /// or `null` when the BMC does not report it or reports an out-of-spec
  /// (negative) value — DMTF `Manager` defines a minimum of 0 (issue #009).
  final int? maxConcurrentSessions;

  /// The connection URI to reach the console (`ConnectUri`), or `null` when the
  /// BMC does not embed one (most mockups omit it; the manager URI is used).
  final String? connectUri;

  /// The `@odata.id` of the manager resource this console was read from.
  final String sourceManagerUri;

  /// OEM-specific console extensions, populated only when the console block
  /// carries an `Oem` member; otherwise `null`.
  final Map<String, dynamic>? oem;

  /// Whether this console advertises an HTML5 web client (`ConnectTypesSupported`
  /// contains `'HTML5'`). HTML5 consoles are typically launched from the BMC
  /// web UI rather than a native client.
  ///
  /// Redfish canonically spells the value `HTML5`, but some BMCs emit a
  /// different case or surrounding whitespace; matching case-insensitively
  /// after trimming keeps the in-app HTML5 launch path from silently skipping
  /// such consoles (issue #021).
  bool get supportsHtml5 => connectTypesSupported.any(
        (String type) => type.trim().toUpperCase() == 'HTML5',
      );

  /// The preferred URI for launching/opening this console.
  ///
  /// Returns a trimmed [connectUri] when it is a non-blank string; a blank
  /// (empty or whitespace-only) value is not a usable endpoint and is surfaced
  /// as `null` so the console card hides its URI row and the viewer falls back
  /// to the manager URI instead of opening an empty target. Trimming is
  /// essential because `Uri.tryParse` rejects leading/trailing whitespace — a
  /// padded-but-valid endpoint stored verbatim would make every launch decision
  /// fall back to "no URI". Mirrors `KvmCapability.launchUri` so both KVM views
  /// agree (issue #009).
  String? get launchUri {
    final String? value = connectUri;
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Whether [launchUri] is an HTTP(S) URL suitable for browser/WebView launch.
  bool get hasHttpLaunchUri {
    final String? uri = launchUri;
    if (uri == null || uri.isEmpty) return false;
    final Uri? parsed = Uri.tryParse(uri);
    return parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https') &&
        parsed.host.isNotEmpty;
  }

  /// Whether [launchUri] uses HTTPS (TLS-encrypted) with a non-empty host.
  ///
  /// In-app console rendering must never downgrade a BMC console to plaintext;
  /// only a TLS-encrypted URI is eligible (issue #021 — never weaken TLS).
  bool get hasSecureLaunchUri {
    final String? uri = launchUri;
    if (uri == null || uri.isEmpty) return false;
    final Uri? parsed = Uri.tryParse(uri);
    return parsed != null && parsed.scheme == 'https' && parsed.host.isNotEmpty;
  }

  /// Whether [launchUri] uses plaintext HTTP (unencrypted transport).
  ///
  /// The UI uses this to warn that an HTML5 console must be configured for
  /// HTTPS before in-app rendering is permitted — console video and injected
  /// input (potentially credentials) must stay encrypted (issue #021).
  bool get usesInsecureHttpLaunchUri {
    final String? uri = launchUri;
    if (uri == null || uri.isEmpty) return false;
    final Uri? parsed = Uri.tryParse(uri);
    return parsed != null && parsed.scheme == 'http' && parsed.host.isNotEmpty;
  }

  /// Whether this console can follow the in-app HTML5 rendering path.
  ///
  /// Minimal client-side criterion: an enabled HTML5 console with a direct
  /// **HTTPS** [connectUri]. Plaintext HTTP is deliberately rejected so the app
  /// never weakens TLS for an embedded console (issue #021). Actual embedded
  /// rendering still depends on a platform WebView dependency (tracked there).
  bool get canLaunchInAppHtml5 =>
      serviceEnabled && supportsHtml5 && hasSecureLaunchUri;

  /// Whether [launchUri] uses a protocol that requires an external client
  /// (e.g. VNC/RFB/KVMIP or serial SSH/Telnet/IPMI) rather than browser/
  /// WebView rendering.
  bool get requiresExternalConsoleClient {
    final String? uri = launchUri;
    if (uri == null || uri.isEmpty) return false;
    final Uri? parsed = Uri.tryParse(uri);
    if (parsed == null) return false;
    final String scheme = parsed.scheme.toLowerCase();
    return scheme == 'vnc' ||
        scheme == 'rfb' ||
        scheme == 'kvmip' ||
        scheme == 'kvm' ||
        scheme == 'ssh' ||
        scheme == 'telnet' ||
        scheme == 'ipmi';
  }

  /// Human-readable label for the external client protocol implied by
  /// [launchUri], or `null` when no external client is required.
  String? get externalClientProtocolLabel {
    if (!requiresExternalConsoleClient) return null;
    final String scheme = Uri.tryParse(launchUri!)?.scheme.toLowerCase() ?? '';
    switch (scheme) {
      case 'vnc':
      case 'rfb':
        return 'VNC/RFB';
      case 'kvmip':
      case 'kvm':
        return 'KVMIP';
      case 'ssh':
        return 'SSH';
      case 'telnet':
        return 'Telnet';
      case 'ipmi':
        return 'IPMI serial-over-LAN';
      default:
        return 'external console';
    }
  }

  /// The single, deterministic launch strategy for this console (issue #021).
  ///
  /// Decision order: no URI → disabled service → insecure (plaintext HTTP)
  /// HTML5 → in-app HTML5 (HTTPS) → external-protocol client → secure browser
  /// (HTTPS, non-HTML5) → no URI fallback. Plaintext HTTP is never offered as a
  /// browser or in-app render target, so the app cannot weaken BMC TLS.
  KvmLaunchStrategy get launchStrategy {
    final String? uri = launchUri;
    if (uri == null || uri.isEmpty) return KvmLaunchStrategy.noUri;
    if (!serviceEnabled) return KvmLaunchStrategy.disabled;
    if (supportsHtml5 && usesInsecureHttpLaunchUri) {
      return KvmLaunchStrategy.insecureHtml5;
    }
    if (canLaunchInAppHtml5) return KvmLaunchStrategy.inAppHtml5;
    if (requiresExternalConsoleClient) return KvmLaunchStrategy.externalClient;
    if (hasSecureLaunchUri) return KvmLaunchStrategy.secureBrowser;
    return KvmLaunchStrategy.noUri;
  }

  /// Whether this console can actually be opened by the user.
  ///
  /// Derived from the single source of truth [launchStrategy]: a console is
  /// openable when it has a usable connect URI and is enabled on the BMC. A
  /// disabled console (`disabled`) or one without a URI (`noUri`) cannot be
  /// opened. Both the card's "Open console" action and `KvmService.pickPrimary`
  /// gate on this getter, so neither offers a console the viewer refuses to
  /// launch (a BMC may publish a ConnectUri while reporting ServiceEnabled:
  /// false). `insecureHtml5` still counts: its URI can be copied/opened
  /// externally (in-app rendering alone is blocked so BMC TLS is never weakened,
  /// issue #021).
  ///
  /// `KvmService.pickPrimary` uses this so the "Primary" badge never lands on a
  /// console the user cannot launch (issue #009).
  bool get canOpenConsole {
    final KvmLaunchStrategy strategy = launchStrategy;
    return strategy != KvmLaunchStrategy.noUri &&
        strategy != KvmLaunchStrategy.disabled;
  }

  /// The fail-closed launch decision for this console under the **production**
  /// policy (embedded WebView flag OFF, strict TLS).
  ///
  /// This is the single, testable decision layer shared by the console card /
  /// viewer and any future, validated renderer: it re-validates the raw URI
  /// (HTTPS + non-empty host) before any TLS-sensitive choice, never accepts a
  /// self-signed certificate in production, and fails closed to a copy-only
  /// plan for a plaintext, malformed or BMC-disabled console. It can never
  /// disagree with [canOpenConsole] about whether a console is launchable — a
  /// disabled console is routed to `copyOnly` even when its URI is HTTPS.
  ///
  /// The raw [connectUri] is passed through so the plan's own re-validation and
  /// trimming are authoritative; [hasSecureLaunchUri] / [supportsHtml5] /
  /// [serviceEnabled] are the same public signals the UI uses. No WebView or
  /// protocol plugin is involved and production TLS is never weakened
  /// (issues #009 / #021).
  KvmConsoleLaunchPlan get launchPlan => planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: connectUri,
        hasSecureUri: hasSecureLaunchUri,
        isHtml5: supportsHtml5,
        isEnabled: serviceEnabled,
      );

  /// Builds the list of [KvmConsole]s detected in a Redfish [managerBody].
  ///
  /// [managerId] is the manager's `Id` (used for display). Each standard
  /// console block present in the body (`GraphicalConsole`, `SerialConsole`,
  /// `RemoteConsole`) yields one [KvmConsole]; an `Oem` console member, when
  /// present, yields an OEM console. Managers without any console block return
  /// an empty list.
  ///
  /// When [oemRegistry] is supplied, vendor parsers are consulted first: a
  /// recognized [KvmOemConsoleInfo] enriches the OEM console with the vendor's
  /// connect URI / types / enabled flag (issue #009 extensibility hook). No
  /// registry or no matching parser keeps the existing strict
  /// `FeatureRules.oemHasConsole` detection unchanged.
  static List<KvmConsole> fromManager(
    Map<String, dynamic> managerBody, {
    required String managerId,
    KvmOemRegistry? oemRegistry,
  }) {
    // A malformed BMC payload can carry a non-string or blank `@odata.id`.
    // A bare cast would throw a TypeError here and blank every console on the
    // KVM screen, so normalize it like every other URI source and fall back to
    // the URI derived from the manager id (issue #009).
    final String sourceManagerUri = _uriString(managerBody['@odata.id']) ??
        '/redfish/v1/Managers/$managerId';

    final List<KvmConsole> consoles = <KvmConsole>[];

    for (final KvmConsoleType type in <KvmConsoleType>[
      KvmConsoleType.graphical,
      KvmConsoleType.serial,
      KvmConsoleType.remote,
    ]) {
      final String? name = type.redfishName;
      if (name == null) continue;
      final dynamic block = managerBody[name];
      if (block is! Map<String, dynamic>) continue;
      consoles.add(
        _fromBlock(
          block,
          type: type,
          managerId: managerId,
          sourceManagerUri: sourceManagerUri,
        ),
      );
    }

    // OEM console, if the manager exposes one under `Oem`. Strict check: a
    // bare vendor-metadata `Oem` block (present on every OpenBMC bmcweb
    // Manager) must not be reported as a console — only blocks that actually
    // contain a console-like structure count (DOCS-4, 2026-10-22).
    final dynamic oem = managerBody['Oem'];
    if (oem is Map<String, dynamic>) {
      final KvmOemConsoleInfo? parsed = oemRegistry?.parse(oem);
      if (parsed != null) {
        // A registered vendor parser produced console details — use them.
        consoles.add(
          KvmConsole(
            type: KvmConsoleType.oem,
            managerId: managerId,
            connectTypesSupported: parsed.connectTypesSupported,
            serviceEnabled: parsed.serviceEnabled,
            connectUri: parsed.connectUri,
            sourceManagerUri: sourceManagerUri,
            oem: oem,
          ),
        );
      } else if (FeatureRules.oemHasConsole(oem)) {
        // Surface the OEM console's own KVM `Uri` (e.g.
        // `Oem.OpenBMC.KVM.Uri`) so the per-console card shows the real
        // browser-launchable endpoint instead of "No console connect URI
        // available" — the same URI the capability card resolves via
        // `KvmCapability.resolveLaunchUri` (issue #009). A registered vendor
        // parser above stays authoritative; this is the generic default path.
        consoles.add(
          KvmConsole(
            type: KvmConsoleType.oem,
            managerId: managerId,
            connectTypesSupported: const <String>[],
            serviceEnabled: true,
            connectUri: kvmOemConsoleUri(oem),
            sourceManagerUri: sourceManagerUri,
            oem: oem,
          ),
        );
      }
    }

    return consoles;
  }

  /// Parses a single console [block] into a [KvmConsole].
  static KvmConsole _fromBlock(
    Map<String, dynamic> block, {
    required KvmConsoleType type,
    required String managerId,
    required String sourceManagerUri,
  }) {
    final List<String> types =
        _normalizedConnectTypes(block['ConnectTypesSupported']);
    final int? maxSessions = _sessionLimit(block['MaxConcurrentSessions']);
    final String? connectUri = _uriString(block['ConnectUri']);
    final bool enabled =
        block['ServiceEnabled'] == true || block['Enabled'] == true;
    final dynamic oem = block['Oem'];
    return KvmConsole(
      type: type,
      managerId: managerId,
      connectTypesSupported: types,
      serviceEnabled: enabled,
      maxConcurrentSessions: maxSessions,
      connectUri: connectUri,
      sourceManagerUri: sourceManagerUri,
      oem: oem is Map<String, dynamic> ? oem : null,
    );
  }

  @override
  String toString() => 'KvmConsole(type=$type, manager=$managerId, '
      'types=$connectTypesSupported, enabled=$serviceEnabled)';
}

/// Single source of truth for the user-facing guidance shown for a launch
/// [strategy] (issue #021).
///
/// Pure and widget-free so every branch is unit-testable. The caller uses this
/// exact string as both visible text and Semantics label, keeping the
/// accessibility tree in lockstep with what sighted users read. Messages are
/// actionable and free of internal issue references / developer jargon.
String kvmLaunchStatusText(
  KvmLaunchStrategy strategy, {
  String? externalProtocol,
}) {
  switch (strategy) {
    case KvmLaunchStrategy.insecureHtml5:
      return 'This HTML5 console uses an unencrypted HTTP connection. '
          'In-app rendering is disabled to keep console video and input '
          'encrypted. Configure the BMC console to use HTTPS before '
          'opening it in a browser.';
    case KvmLaunchStrategy.inAppHtml5:
      return 'In-app HTML5 console path available for this URI. '
          'Embedded rendering requires a WebView dependency. '
          'You can open this URI in a web browser if your BMC allows it.';
    case KvmLaunchStrategy.externalClient:
      final String protocol = externalProtocol ?? 'external console';
      return 'This console URI uses a protocol that requires an external '
          '$protocol client. Embedded rendering is not available in-app. '
          'Copy the URI and open it with a compatible client.';
    case KvmLaunchStrategy.secureBrowser:
      return 'This console uses a secure HTTPS connection. Embedded rendering '
          'is not available for this console type. Open the URI in a secure '
          'web browser, or copy it for an external client.';
    case KvmLaunchStrategy.disabled:
      return 'This console service is disabled on the BMC. Enable it in the '
          'BMC settings before launching a console session.';
    case KvmLaunchStrategy.noUri:
      return 'In-app embedded rendering is not available for this console. '
          'Use the URI externally if provided.';
  }
}

/// Returns [value] as a trimmed, usable URI [String], or `null` when it is not
/// a string or is blank (empty / whitespace-only).
///
/// A Redfish `ConnectUri` must be a real endpoint: a blank value would make the
/// console card render "Connect URI:   " and the viewer target an empty string,
/// while a padded-but-valid value stored verbatim would fail `Uri.tryParse` and
/// make every launch decision fall back to "no URI". Trimming here keeps the
/// stored value launchable. This mirrors `KvmCapability._nonEmptyString` so the
/// per-console and per-manager KVM views treat the same value identically
/// (issue #009).
String? _uriString(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Returns [value] as a spec-valid `MaxConcurrentSessions` limit, or `null`.
///
/// The DMTF `Manager` schema defines `MaxConcurrentSessions` with a minimum of
/// 0 (`Manager.v1_19_0.json`). A negative value is out of spec (and is used by
/// some BMCs as a sentinel for "unlimited"), so it is surfaced as unreported
/// rather than rendering "Max concurrent sessions: -1" on the console card.
/// This mirrors `KvmCapability._maxSessions` so the per-console and per-manager
/// KVM views treat the same malformed value identically (issue #009).
int? _sessionLimit(Object? value) {
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

/// Builds a normalized [List<String>] of `ConnectTypesSupported` values from a
/// Redfish JSON list: non-string entries are ignored, each string entry is
/// trimmed, empty entries are dropped and duplicates are removed
/// case-insensitively while keeping the first (BMC-provided) spelling for
/// deterministic display.
///
/// `ConnectTypesSupported` is an array of Redfish `ConnectType` strings, so a
/// `null` / numeric / boolean entry is malformed data rather than a connection
/// type. Stringifying it would render a literal "null" / "42" chip on the
/// console card; ignoring it keeps the UI honest.
///
/// This mirrors `KvmCapability._appendTypes` so the per-console card and the
/// per-manager capability card — which read the same console blocks — surface
/// the same clean set of connection types instead of duplicate/garbled chips
/// when a BMC mixes casing, whitespace or emits a malformed entry (issue #009).
List<String> _normalizedConnectTypes(dynamic value) {
  if (value is! List<dynamic>) return const <String>[];
  final List<String> result = <String>[];
  for (final dynamic entry in value) {
    if (entry is! String) continue;
    final String type = entry.trim();
    if (type.isEmpty) continue;
    final bool duplicate = result.any(
      (String existing) => existing.toUpperCase() == type.toUpperCase(),
    );
    if (!duplicate) result.add(type);
  }
  return List<String>.unmodifiable(result);
}
