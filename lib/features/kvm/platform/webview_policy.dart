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

  /// Always `false`: hostname / certificate-identity verification is NEVER
  /// bypassed, not even by the test-only self-signed opt-in.
  ///
  /// Tolerating a self-signed leaf means accepting a certificate that is
  /// otherwise valid for the *expected* BMC host but untrusted by the platform
  /// store. It must never relax the hostname check: a blanket trust-all socket
  /// factory or a catch-all host verifier would let ANY host impersonate the
  /// BMC, turning the test-only opt-in into a machine-in-the-middle vector and
  /// weakening TLS. This is a hard, configuration-independent invariant, so a
  /// future WebView consumer can consult it and can never obtain a policy that
  /// disables identity verification. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassHostnameVerification => false;

  /// Always `false`: certificate / public-key pinning is NEVER bypassed, not
  /// even by the test-only self-signed opt-in.
  ///
  /// Hostname verification (see [bypassHostnameVerification]) binds the
  /// certificate's identity to the console hostname. Pinning goes further: it
  /// binds the connection to the *specific* expected BMC certificate / public
  /// key, so a DIFFERENT, otherwise-valid and platform-trusted certificate for
  /// the same hostname cannot impersonate the BMC. Tolerating a self-signed leaf
  /// on the expected test host must therefore not degrade to a trust-all /
  /// accept-any-certificate verifier (a blanket `TrustManager` accepting every
  /// chain, a catch-all socket factory, or a disabled identity check) — that
  /// would let any host takeover the privileged console session and would
  /// weaken TLS. This is a hard, configuration-independent invariant, so a
  /// future WebView consumer can consult it and can never obtain a policy that
  /// disables pinning. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassCertificatePinning => false;

  /// Always `false`: the TLS protocol-version / cipher-suite floor is NEVER
  /// bypassed, not even by the test-only self-signed opt-in.
  ///
  /// Hostname verification ([bypassHostnameVerification]) binds the certificate
  /// identity to the console host, and pinning ([bypassCertificatePinning])
  /// binds the connection to the expected BMC key. This invariant is distinct
  /// from both: it governs the *handshake itself*. The embedded WebView must
  /// negotiate only a modern TLS version (1.2+ floor) with strong cipher suites
  /// and downgrade protection, never TLS 1.0/1.1, SSLv3, weak/export/NULL
  /// suites or a silent downgrade. Tolerating a self-signed leaf on the
  /// expected test host relaxes ONLY leaf trust: it must never lower the
  /// protocol/cipher floor, otherwise the privileged console session is exposed
  /// to a downgrade/decryption attack. This is a hard, configuration-independent
  /// invariant, so a future WebView consumer can consult it and can never
  /// obtain a policy that bypasses the TLS floor. See `WEBVIEW_TLS_MATRIX.md`
  /// (RP-1).
  bool get bypassTlsProtocolFloor => false;

  /// Always `false`: HTTPS-only transport is NEVER bypassed — the embedded
  /// WebView may never open a cleartext (`http://`) socket, not even by the
  /// test-only self-signed opt-in.
  ///
  /// This invariant is distinct from the TLS floor ([bypassTlsProtocolFloor]),
  /// hostname verification ([bypassHostnameVerification]) and pinning
  /// ([bypassCertificatePinning]): those govern a TLS handshake that actually
  /// occurs (its protocol/cipher strength) and the certificate's identity/key.
  /// HTTPS-only transport instead governs whether ANY cleartext socket may be
  /// opened at the WebView platform layer at all — Android
  /// `cleartextTrafficPermitted` / `usesCleartextTraffic` must stay false and
  /// Apple ATS must forbid arbitrary/insecure loads. A redirect, subresource or
  /// fallback path must never silently downgrade to a plaintext socket outside
  /// the decision layer. Tolerating a self-signed leaf on the expected test host
  /// relaxes ONLY leaf trust: it must never add a cleartext exception, even for
  /// the test profile. This is a hard, configuration-independent invariant, so
  /// a future WebView consumer can consult it and can never obtain a policy
  /// that permits cleartext transport. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassHttpsOnlyTransport => false;

  /// Always `false`: certificate revocation checking (CRL / OCSP) is NEVER
  /// bypassed, not even by the test-only self-signed opt-in.
  ///
  /// The three certificate-related invariants are independent: hostname
  /// verification ([bypassHostnameVerification]) binds the certificate's
  /// identity to the console host, pinning ([bypassCertificatePinning]) binds
  /// the connection to the expected BMC key, and revocation checking rejects a
  /// certificate that has been revoked (e.g. because the BMC's private key was
  /// compromised) even when it still chains to a trusted CA, carries the
  /// expected hostname and matches the pin. Tolerating a self-signed leaf on the
  /// expected test host relaxes ONLY leaf trust in the platform store: it must
  /// never disable revocation checking for otherwise-trusted certificates, or a
  /// revoked BMC certificate could silently resume the privileged console
  /// session. This is a hard, configuration-independent invariant, so a future
  /// WebView consumer can consult it and can never obtain a policy that skips
  /// revocation. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassCertificateRevocationCheck => false;

  /// Always `false`: binding to the validated console origin is NEVER bypassed,
  /// not even by the test-only self-signed opt-in.
  ///
  /// The embedded WebView must connect only to the address that passed the
  /// fail-closed origin check: no DNS rebinding (a name that resolves to the
  /// approved BMC address at validation time and to loopback / link-local /
  /// cloud-metadata / an internal management address at connect time), no
  /// time-of-check / time-of-use gap and no host-vs-address mismatch. This is
  /// distinct from hostname verification ([bypassHostnameVerification]) and
  /// pinning ([bypassCertificatePinning]) (which bind certificate identity and
  /// key), the TLS floor ([bypassTlsProtocolFloor]) and HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) (which govern a handshake that actually
  /// occurs and whether a cleartext socket may be opened), and revocation
  /// ([bypassCertificateRevocationCheck]) (which checks certificate status):
  /// this box governs which resolved address the validated top-level origin
  /// may connect to. Tolerating a self-signed leaf relaxes ONLY leaf trust; it
  /// must never let the console pivot to a different, re-resolved address.
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that skips binding
  /// to the validated origin. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassValidatedOriginBinding => false;

  /// Always `false`: the platform trust store's integrity is NEVER compromised
  /// by the test-only self-signed opt-in — no CA / trust anchor is ever added.
  ///
  /// A naive way to accept a self-signed BMC certificate would be to install the
  /// BMC's CA (or the leaf itself) into the OS/platform trust store (e.g. an
  /// Android `NetworkSecurityConfig` `<certificates src="user"/>` trust-anchor
  /// addition or `KeyStore` mutation, an iOS/macOS custom CA / `SecTrust`
  /// anchor, or an ATS/network-security exception that adds a trust anchor).
  /// That would make the CA trusted for EVERY app and EVERY host on the device —
  /// a global weakening of production TLS, exactly what this spike forbids — and
  /// would let any certificate signed by that CA impersonate any host. The
  /// opt-in must instead tolerate the test BMC's untrusted leaf ONLY through a
  /// scoped, per-connection certificate verifier bound to the expected console
  /// host; the platform trust store itself is never mutated.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that mutates the
  /// trust store to accept a certificate. It is distinct from hostname
  /// verification ([bypassHostnameVerification]) and pinning
  /// ([bypassCertificatePinning]) (which bind certificate identity/key), the
  /// TLS floor ([bypassTlsProtocolFloor]) and HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) (which govern the handshake and cleartext
  /// sockets), revocation ([bypassCertificateRevocationCheck]) (which checks
  /// certificate status) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (which binds the resolved address): those
  /// govern the connection, whereas this box governs the device-wide trust
  /// anchors themselves. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassPlatformTrustStoreIntegrity => false;

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
  /// console may actually be rendered in-app: an enabled, HTML5 console with
  /// a TLS-encrypted (HTTPS) URI. Strict mode, the default, plaintext HTTP,
  /// a disabled console and a non-HTML5 console always return false —
  /// production TLS is never weakened.
  ///
  /// Requiring the full [permitsInAppRendering] preconditions here (rather than
  /// just `hasSecureUri`) keeps this public boolean safe to call directly: a
  /// future WebView consumer that checks `mayAcceptSelfSigned` without first
  /// routing through [resolveRenderRoute] can never grant self-signed
  /// acceptance for a console that is not actually going to be rendered
  /// in-app. This is defense in depth on top of `planConsoleLaunch`, which
  /// already gates acceptance on the final route being the in-app WebView.
  bool mayAcceptSelfSigned({
    required bool hasSecureUri,
    required bool isHtml5,
    required bool isEnabled,
  }) =>
      acceptsSelfSigned &&
      permitsInAppRendering(
        hasSecureUri: hasSecureUri,
        isHtml5: isHtml5,
        isEnabled: isEnabled,
      );
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
