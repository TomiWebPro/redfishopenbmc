/// Design-only policy contract for the optional in-app KVM console WebView
/// (rf-platform RP-1 spike).
///
/// This module is intentionally **self-contained and dependency-free**: it does
/// not import `webview_flutter`, open a platform channel, or touch the app's
/// HTTP transport. It encodes the *reversible opt-in* decision so RP-2 can wire
/// an actual WebView without ever weakening production TLS:
///
///  * the in-app flag is OFF by default ([KvmWebViewPolicy.productionDefault]);
///  * self-signed certificates are accepted only in an explicitly test-only
///    opt-in ([KvmWebViewPolicy.testOptIn]) and only for HTTPS targets;
///  * plaintext HTTP is never an in-app render target;
///  * with the flag off the external-browser + copy fallback keeps working
///    ([resolveRenderRoute]).
///
/// Nothing in production imports this yet; it is a spike artifact, not a
/// transport change. See `WEBVIEW_TLS_MATRIX.md` for the platform validation
/// matrix and rationale.
library;

/// TLS posture for an embedded console WebView.
enum KvmWebViewTlsMode {
  /// Validate every certificate with the platform trust store (default and the
  /// only production-safe mode).
  strict,

  /// Accept a self-signed certificate ONLY for an explicitly opted-in test
  /// profile, and only over HTTPS. Never the default, never for plaintext.
  testOptInSelfSigned,
}

/// Reversible, opt-in policy for an embedded console WebView.
class KvmWebViewPolicy {
  /// Creates a policy. Both arguments are deliberately conservative: the flag
  /// defaults to off and TLS defaults to strict.
  const KvmWebViewPolicy({
    this.enabled = false,
    this.tlsMode = KvmWebViewTlsMode.strict,
  });

  /// Production default: no embedded WebView, strict certificate validation.
  static const KvmWebViewPolicy productionDefault = KvmWebViewPolicy();

  /// Test-only opt-in: embedded WebView allowed, self-signed tolerated on HTTPS.
  ///
  /// This must only ever be constructed for a test profile / validation spike;
  /// it is never derived from a normal connection profile.
  static const KvmWebViewPolicy testOptIn = KvmWebViewPolicy(
    enabled: true,
    tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
  );

  /// Whether the opt-in flag is on.
  final bool enabled;

  /// The certificate-validation posture for an embedded WebView.
  final KvmWebViewTlsMode tlsMode;

  /// Whether this policy tolerates a self-signed certificate at all.
  bool get acceptsSelfSigned =>
      tlsMode == KvmWebViewTlsMode.testOptInSelfSigned;

  /// Whether an in-app WebView may render this console.
  ///
  /// In-app rendering requires the opt-in flag AND an enabled, HTML5 console
  /// with a TLS-encrypted (HTTPS) URI. With the flag off this is always false,
  /// which keeps production on the external-browser / copy fallback and never
  /// weakens BMC TLS (issue #021).
  bool permitsInAppRendering({
    required bool hasSecureUri,
    required bool isHtml5,
    required bool isEnabled,
  }) {
    if (!enabled) return false;
    return isEnabled && isHtml5 && hasSecureUri;
  }

  /// Whether a self-signed certificate may be accepted for this launch.
  ///
  /// True only when the flag is on, the mode is the test-only opt-in, AND the
  /// target is HTTPS. Strict mode, the default, and plaintext HTTP always
  /// return false — production TLS is never weakened.
  bool mayAcceptSelfSigned({required bool hasSecureUri}) =>
      enabled && acceptsSelfSigned && hasSecureUri;
}

/// Where a console is routed for rendering, given the active policy.
enum KvmConsoleRenderRoute {
  /// Embedded WebView (only reachable with the opt-in flag and a safe console).
  inAppWebView,

  /// Hand the HTTPS URI to an external, secure browser.
  externalBrowser,

  /// No safe render target — surface the URI/copy path only.
  copyOnly,
}

/// Picks the render route for a console without embedding anything.
///
/// With the flag off this always selects [KvmConsoleRenderRoute.externalBrowser]
/// for an HTTPS console and [KvmConsoleRenderRoute.copyOnly] otherwise, so the
/// existing external-browser + copy path keeps working unchanged (RP-2
/// fallback requirement). `hasSecureUri` mirrors `KvmConsole.hasSecureLaunchUri`
/// (HTTPS with a non-empty host).
KvmConsoleRenderRoute resolveRenderRoute({
  required KvmWebViewPolicy policy,
  required bool hasSecureUri,
  required bool isHtml5,
  required bool isEnabled,
}) {
  if (policy.permitsInAppRendering(
    hasSecureUri: hasSecureUri,
    isHtml5: isHtml5,
    isEnabled: isEnabled,
  )) {
    return KvmConsoleRenderRoute.inAppWebView;
  }
  if (hasSecureUri) return KvmConsoleRenderRoute.externalBrowser;
  return KvmConsoleRenderRoute.copyOnly;
}
