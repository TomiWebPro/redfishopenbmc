/// Remote KVM / console models (issue #009).
///
/// Mirrors the Redfish `Manager` console services (`GraphicalConsole`,
/// `SerialConsole`, `RemoteConsole`). A BMC may expose several console types
/// at once; [KvmConsole.fromManager] extracts each into its own immutable
/// [KvmConsole] so the UI can list them uniformly.
library;

import 'package:redfishopenbmc/features/kvm/models/kvm_connect_type.dart'
    show kvmConnectTypeEquals;
import 'package:redfishopenbmc/features/kvm/models/kvm_manager_source.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_registry.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart'
    show kvmOemConsoleEnabled, kvmOemConsoleUri;
import 'package:redfishopenbmc/features/kvm/models/kvm_session_limit.dart';
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

  /// Non-HTML5 console whose connect URI is plaintext HTTP (e.g. KVMIP over
  /// `http://`). It is NOT a browser/in-app render target — no unencrypted
  /// browser console is ever suggested — but it still carries a real, copyable
  /// URI, so it must not be collapsed into [noUri] (whose "use the URI if
  /// provided" guidance gives no unencrypted warning). It gets its own explicit
  /// cleartext warning so it agrees with the transport signals on both cards
  /// (issues #009 / #021; never weaken TLS).
  insecureHttp,

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
  ///
  /// Parsed through the shared [kvmSessionLimit] helper, so an integer-valued
  /// JSON number emitted as a double (e.g. `4.0`) is tolerated exactly like an
  /// `int` on both KVM views, and the capability card can never disagree about
  /// the same BMC value.
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
  /// such consoles (issue #021). The fold is ASCII-only, so a Unicode
  /// confusable token never collapses onto the canonical `HTML5` spelling
  /// (RM-22).
  bool get supportsHtml5 => connectTypesSupported.any(
        (String type) => kvmConnectTypeEquals(type, 'HTML5'),
      );

  /// Whether the console card should show the "HTML5 console — open via BMC
  /// web UI" hint (a normal-open suggestion for a browser-managed console).
  ///
  /// An HTML5 console whose direct [launchUri] is plaintext HTTP must NOT get
  /// this hint: the card already renders the unencrypted-transport warning
  /// ([usesInsecureHttpLaunchUri] → `kvmInsecureTransportNotice`, "configure
  /// HTTPS before opening it in a browser"), so also telling the operator the
  /// console can be opened normally via the web UI gives two contradictory
  /// launch messages for the same unsafe endpoint (issues #009 / #021). This
  /// keeps the hint for URI-less HTML5 consoles (opened from the BMC web UI —
  /// no direct insecure endpoint) and for secure HTTPS HTML5 consoles.
  ///
  /// An HTML5 console whose direct [launchUri] needs an **external client**
  /// (VNC/RFB, KVMIP, serial SSH/Telnet/IPMI) must also NOT get this hint: the
  /// card already renders `kvmExternalClientNoticeFor(...)`, "copy the URI and
  /// open it with a compatible client", so also advertising an ordinary "open
  /// via BMC web UI" path gives two contradictory launch messages for the same
  /// endpoint (EP-U3, issues #009 / #021). Both gates delegate to the same
  /// shared fail-closed classifiers, so no surface can disagree about which
  /// guidance applies.
  ///
  /// Pure and widget-free so the rule is unit-testable; display-only, opens no
  /// URL and never changes transport security (production TLS is never
  /// weakened).
  bool get showHtml5WebUiHint =>
      supportsHtml5 &&
      !usesInsecureHttpLaunchUri &&
      !requiresExternalConsoleClient;

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
  ///
  /// Uses the shared, control-char-safe [isHttpConsoleUri] classifier so a
  /// raw-space/C0/DEL-bearing target is not treated as a browser-launchable
  /// URI (matching the fail-closed decision layer and `KvmCapability`).
  bool get hasHttpLaunchUri => isHttpConsoleUri(launchUri);

  /// Whether [launchUri] is a genuine HTTPS (TLS-encrypted) target with a
  /// non-empty host and no embedded control characters.
  ///
  /// In-app console rendering must never downgrade a BMC console to plaintext;
  /// only a TLS-encrypted URI is eligible (issue #021 — never weaken TLS).
  /// Uses the same [isSecureHttpsConsoleUri] classifier as the fail-closed
  /// launch plan, so the card's "Open console" affordance can never disagree
  /// with [launchPlan] about a CRLF/NUL-bearing or otherwise malformed target
  /// (`Uri.tryParse` alone silently percent-encodes control characters and
  /// would call such a URI secure). This can only tighten classification — no
  /// valid HTTPS endpoint is lost.
  bool get hasSecureLaunchUri => isSecureHttpsConsoleUri(launchUri);

  /// Whether [launchUri] uses plaintext HTTP (unencrypted transport).
  ///
  /// The UI uses this to warn that an HTML5 console must be configured for
  /// HTTPS before in-app rendering is permitted — console video and injected
  /// input (potentially credentials) must stay encrypted (issue #021).
  ///
  /// Uses the shared, control-char-safe [isPlaintextHttpConsoleUri] classifier
  /// (the plaintext sibling of [hasSecureLaunchUri]), so a malformed HTTP
  /// target is never presented as a real unencrypted endpoint on the console
  /// card. Strictly tightens classification; never changes transport security.
  bool get usesInsecureHttpLaunchUri => isPlaintextHttpConsoleUri(launchUri);

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
  ///
  /// Applies the same shared [isControlSafeConsoleUri] gate as the HTTP(S)
  /// classifier families before parsing. A raw-space / C0/DEL / Unicode-
  /// separator-bearing URI would otherwise be silently percent-encoded by
  /// `Uri.tryParse` into a spoofed host while still reporting a valid external
  /// scheme, and be presented to the operator as a trustworthy "requires an
  /// external client" endpoint (with a copy affordance) — disagreeing with how
  /// an equivalent malformed HTTPS/HTTP URI is already failed closed. Such a
  /// target now fails closed to `noUri` here too (issues #009 / #021).
  bool get requiresExternalConsoleClient =>
      isExternalClientConsoleUri(launchUri);

  /// Human-readable label for the external client protocol implied by
  /// [launchUri], or `null` when no external client is required.
  ///
  /// Delegates to the same shared classifier as [requiresExternalConsoleClient]
  /// (and as `KvmCapability`), so classification and labelling can never drift
  /// across the two KVM views (EP-M2 cross-surface parity).
  String? get externalClientProtocolLabel =>
      externalClientConsoleProtocol(launchUri);

  /// The single, deterministic launch strategy for this console (issue #021).
  ///
  /// Decision order: no URI → disabled service → insecure (plaintext HTTP)
  /// HTML5 → insecure (plaintext HTTP) non-HTML5 → in-app HTML5 (HTTPS) →
  /// external-protocol client → secure browser (HTTPS, non-HTML5) → no URI
  /// fallback. Plaintext HTTP is never offered as a browser or in-app render
  /// target, so the app cannot weaken BMC TLS; a plain HTTP URI is reported as
  /// [KvmLaunchStrategy.insecureHttp] (with a cleartext warning) instead of the
  /// misleading [KvmLaunchStrategy.noUri], matching both cards' transport signal
  /// (issues #009 / #021).
  KvmLaunchStrategy get launchStrategy {
    final String? uri = launchUri;
    if (uri == null || uri.isEmpty) return KvmLaunchStrategy.noUri;
    if (!serviceEnabled) return KvmLaunchStrategy.disabled;
    if (supportsHtml5 && usesInsecureHttpLaunchUri) {
      return KvmLaunchStrategy.insecureHtml5;
    }
    // A plaintext HTTP endpoint with a real, copyable URI must not be reported
    // as "no URI" — that would skip the unencrypted-transport warning both
    // cards already show. It is still never a browser/in-app render target (no
    // TLS weakening); it just gets honest cleartext guidance. Checked before
    // the external-protocol branch so an `http://` KVMIP endpoint is flagged
    // for its cleartext transport rather than only as an external client.
    if (usesInsecureHttpLaunchUri) return KvmLaunchStrategy.insecureHttp;
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
  /// false). `insecureHtml5` and `insecureHttp` still count: their URIs can be
  /// copied/opened externally (in-app/browser rendering alone is blocked so BMC
  /// TLS is never weakened, issue #021).
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

  /// A control-safe manager URI, suitable as a last-resort clipboard fallback.
  ///
  /// [sourceManagerUri] is a BMC-supplied `@odata.id`: [KvmConsole.fromManager]
  /// only trims it, so a malformed/hostile BMC can still publish a value with
  /// CRLF / NUL / raw space / backslash / Unicode separators or a malformed or
  /// encoded-control `%` escape. Copying that verbatim would reintroduce the
  /// exact header/clipboard-injection risk the launch plan's fail-closed target
  /// gate exists to prevent (issues #009 / #021). Route it through the same
  /// shared [isControlSafeConsoleUri] gate the launch plan uses: a safe source
  /// is kept byte-for-byte (no valid target is lost), and an unsafe one is
  /// replaced by a deterministic path synthesized from [managerId] with every
  /// non-unreserved byte percent-encoded (via [Uri.encodeComponent]), so the
  /// fallback can never carry the hostile code point back onto the clipboard.
  String get safeManagerUri {
    if (isControlSafeConsoleUri(sourceManagerUri)) return sourceManagerUri;
    final String encodedId = Uri.encodeComponent(managerId.trim());
    return '/redfish/v1/Managers/${encodedId.isEmpty ? 'manager' : encodedId}';
  }

  /// The fail-closed URI the "copy connect info" affordance may place on the
  /// clipboard, falling back to [safeManagerUri] when the launch plan has no
  /// usable target (issues #009 / #021).
  ///
  /// This is the single source of truth for the console card's clipboard
  /// target and matches the in-app viewer, which takes its own copy target from
  /// the same [launchPlan]. Under the production policy [launchPlan] hands back
  /// a `null` target for a control-character / spoofed-authority URI (CRLF,
  /// NUL, raw space, raw backslash, malformed `%`, …) that `Uri.tryParse` would
  /// otherwise silently percent-encode into a host — placing such a value on
  /// the clipboard risks header/clipboard injection when pasted. Without this
  /// gate the card copied its raw [launchUri] directly while the viewer
  /// refused the same target, so the two surfaces disagreed about clipboard
  /// safety. The raw endpoint stays visible on the card ("fail closed, not
  /// hidden"); only the explicit copy action degrades to a control-safe
  /// [safeManagerUri]. Valid, control-safe URIs (including properly
  /// percent-encoded ones) are copied byte-for-byte as before, so no operator
  /// capability is lost.
  String get clipboardTargetUri => launchPlan.targetUri ?? safeManagerUri;

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
    // RS-5: resolve the source through the SAME shared normalizer the
    // capability card uses, so a padded @odata.id is trimmed and a blank /
    // non-string one falls back identically on both KVM views.
    final String sourceManagerUri =
        kvmManagerSourceUri(managerBody['@odata.id'], managerId);

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
        // A registered vendor parser produced console details — use them, but
        // normalize through the SAME helpers every other console source uses.
        // A vendor parser is a data source like any BMC block, not a trusted
        // shortcut: storing its raw values verbatim let a padded ConnectUri and
        // duplicate/blank/garbled connection types reach the OEM console card
        // while the capability card / launch plan already trim and dedup the
        // same manager (issue #009 cross-view consistency). Both KVM views now
        // agree for any construction path: a blank URI becomes `null` and an
        // empty type list stays empty, exactly as for standard blocks.
        consoles.add(
          KvmConsole(
            type: KvmConsoleType.oem,
            managerId: managerId,
            connectTypesSupported:
                _normalizedConnectTypes(parsed.connectTypesSupported),
            serviceEnabled: parsed.serviceEnabled,
            connectUri: _uriString(parsed.connectUri),
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
        // The OEM console's own enablement flags are honored just like every
        // standard block: a BMC that explicitly reports `ServiceEnabled: false`
        // (or `Enabled: false`) must not yield a launchable console
        // (`launchStrategy == disabled`, `canOpenConsole == false`), while an
        // OEM block that omits the flag stays enabled. Reuses the shared helper
        // so this agrees with `KvmCapability.fromManager` (issue #009).
        consoles.add(
          KvmConsole(
            type: KvmConsoleType.oem,
            managerId: managerId,
            connectTypesSupported: const <String>[],
            serviceEnabled: kvmOemConsoleEnabled(oem),
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
    final int? maxSessions = kvmSessionLimit(block['MaxConcurrentSessions']);
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
    case KvmLaunchStrategy.insecureHttp:
      return 'This console uses an unencrypted HTTP connection. '
          'In-app rendering is disabled to keep console video and input '
          'encrypted. Configure the BMC console to use HTTPS, or copy the '
          'URI for an external client.';
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
      (String existing) => kvmConnectTypeEquals(existing, type),
    );
    if (!duplicate) result.add(type);
  }
  return List<String>.unmodifiable(result);
}
