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

  /// Always `false`: client-certificate (mutual TLS) validation is NEVER
  /// bypassed, not even by the test-only self-signed opt-in.
  ///
  /// When a BMC console requires mutual TLS, the embedded WebView must present
  /// the configured client certificate, validate the connection against it and
  /// keep that certificate's private key protected — never exported or exposed
  /// to page JavaScript / a native bridge. The test-only self-signed opt-in
  /// tolerates ONLY the test BMC's untrusted *server* leaf for the expected
  /// host; it must never disable client-certificate validation, never accept a
  /// missing/invalid/expired client certificate and never expose the client
  /// private key. Otherwise the privileged console session could be opened with
  /// a missing or attacker-chosen client credential.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that skips client
  /// credential validation. It is distinct from every server-side certificate
  /// check — hostname verification ([bypassHostnameVerification]) and pinning
  /// ([bypassCertificatePinning]) bind the BMC's server identity/key,
  /// revocation ([bypassCertificateRevocationCheck]) checks server certificate
  /// status, and platform trust-store integrity
  /// ([bypassPlatformTrustStoreIntegrity]) governs device-wide trust anchors —
  /// and from the TLS floor ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address): those govern the server / transport, whereas this box
  /// governs the client credential. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassClientCertificateValidation => false;

  /// Always `false`: the strict Referrer-Policy is NEVER bypassed, not even by
  /// the test-only self-signed opt-in.
  ///
  /// The console URI is the operator's privileged management-session handle and
  /// may carry a session token, credential or BMC identity in its userinfo,
  /// path or query. The embedded WebView must therefore load the console under
  /// a strict referrer policy (`Referrer-Policy: no-referrer`, or at minimum
  /// `same-origin`), in the response header / `<meta>` and in the WebView's own
  /// referrer-policy setting, so no cross-origin subresource load or navigation
  /// ever receives the console URL in a `Referer` header. A lax policy
  /// (`unsafe-url`, `no-referrer-when-downgrade` to an attacker origin, or an
  /// override that emits the full URL) would hand that token to any third party
  /// the attacker-influenced console page contacts.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that relaxes the
  /// referrer policy. The test-only self-signed opt-in tolerates ONLY the test
  /// BMC's untrusted server leaf for the expected host; it must never weaken the
  /// referrer policy or expose the console handle. It is distinct from every
  /// server-side certificate check — hostname verification
  /// ([bypassHostnameVerification]) and pinning ([bypassCertificatePinning])
  /// bind server identity/key, revocation ([bypassCertificateRevocationCheck])
  /// checks certificate status, and platform trust-store integrity
  /// ([bypassPlatformTrustStoreIntegrity]) governs device-wide anchors — from
  /// the TLS floor ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), and from client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential): those
  /// govern the connection and its credentials, whereas this box governs the
  /// app's own outbound `Referer` header content. See `WEBVIEW_TLS_MATRIX.md`
  /// (RP-1).
  bool get bypassStrictReferrerPolicy => false;

  /// Always `false`: Content-Security-Policy enforcement and mixed-content
  /// blocking are NEVER bypassed, not even by the test-only self-signed opt-in.
  ///
  /// The BMC console is an HTTPS page that may load subresources (scripts,
  /// styles, images, fonts, XHR/fetch, WebSockets). A Content-Security-Policy
  /// that restricts frame/load sources and a strict mixed-content policy (an
  /// `https://` console must never load `http://` subresources) must stay in
  /// force: allowing active or passive mixed content would let an on-path
  /// attacker or an attacker-influenced console page downgrade a subresource to
  /// cleartext, read or tamper with privileged console data, or inject script
  /// into the trusted frame — a TLS-downgrade / content-injection surface. A
  /// console whose CSP or mixed-content policy blocks it must never be silently
  /// downgraded or reloaded under a relaxed policy just to "make it render".
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that disables CSP or
  /// mixed-content blocking. The test-only self-signed opt-in tolerates ONLY the
  /// test BMC's untrusted server leaf for the expected host; it must never relax
  /// CSP or permit mixed content. It is distinct from every server-side
  /// certificate check — hostname verification ([bypassHostnameVerification])
  /// and pinning ([bypassCertificatePinning]) bind server identity/key,
  /// revocation ([bypassCertificateRevocationCheck]) checks certificate status,
  /// and platform trust-store integrity ([bypassPlatformTrustStoreIntegrity])
  /// governs device-wide anchors — from the TLS floor ([bypassTlsProtocolFloor]),
  /// HTTPS-only transport ([bypassHttpsOnlyTransport]) and validated-origin
  /// binding ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets
  /// and resolved address), and from client-certificate validation
  /// ([bypassClientCertificateValidation]) and the strict referrer policy
  /// ([bypassStrictReferrerPolicy]) (the client credential and the app's own
  /// outbound `Referer` header): those govern the connection, its credentials
  /// and the app's own requests, whereas this box governs which subresources
  /// the trusted console page is allowed to load. See `WEBVIEW_TLS_MATRIX.md`
  /// (RP-1).
  bool get bypassMixedContentBlocking => false;

  /// Always `false`: redaction of the privileged console URL / session token from
  /// logs, telemetry and crash reports (CWE-532) is NEVER bypassed, not even by
  /// the test-only self-signed opt-in.
  ///
  /// The console URI is the operator's privileged management-session handle and
  /// may carry a session token, credential or BMC identity in its userinfo, path
  /// or query. The WebView-hosting layer and the app's launch / fallback code
  /// must never emit that URI or any token derived from it to Android `Logcat`,
  /// `NSLog` / `os_log`, Flutter `debugPrint`, analytics events, crash reports /
  /// breadcrumbs or any other telemetry sink: doing so leaves a durable,
  /// exfiltratable copy of the handle on the device or in a third-party sink.
  /// Every console URL and derived token must be redacted on every target, in
  /// strict mode and with the flag both off and on. Tolerating the test BMC's
  /// untrusted server leaf relaxes ONLY leaf trust; it must never relax this
  /// diagnostic redaction just to make a console render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that logs the
  /// privileged console handle. It is distinct from the referrer policy
  /// ([bypassStrictReferrerPolicy]) (which governs the app's own outbound
  /// `Referer` header on subresource loads), from page-level CSP / mixed-content
  /// enforcement ([bypassMixedContentBlocking]) (which governs which
  /// subresources the console page may load), and from every server-side
  /// certificate check — hostname verification ([bypassHostnameVerification]),
  /// pinning ([bypassCertificatePinning]), revocation
  /// ([bypassCertificateRevocationCheck]) and platform trust-store integrity
  /// ([bypassPlatformTrustStoreIntegrity]) — the TLS floor
  /// ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), and client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential): those
  /// govern the connection, its credentials and its requests, whereas this box
  /// governs the app's own local diagnostic / telemetry output. See
  /// `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassLogRedaction => false;

  /// Always `false`: protection of the privileged console session against
  /// sensitive data at rest is NEVER bypassed, not even by the test-only
  /// self-signed opt-in.
  ///
  /// The embedded WebView must not persist the remote BMC console's sensitive
  /// content (operator credentials, session cookies/tokens, KVM screen frames,
  /// managed-host inventory) to disk — no on-device WebView HTTP/disk cache of
  /// console responses, no DOM local/session storage or IndexedDB retention
  /// beyond the session, no `setDatabaseEnabled` / `setDomStorageEnabled`
  /// persistence, no WebView cookie jar shared with the system browser, and no
  /// autofill/password-manager saving of console credentials — and must not
  /// expose the live console to an OS background snapshot / recent-apps
  /// thumbnail (Android `FLAG_SECURE`, or the iOS/macOS equivalent). Any such
  /// on-disk copy or capture is a durable, local data-theft / shoulder-surfing
  /// surface for the operator's privileged management session. Every console
  /// page is rendered with cache/storage persistence disabled and secure,
  /// non-capturable presentation on every target, in strict mode and with the
  /// flag both off and on. Tolerating the test BMC's untrusted server leaf
  /// relaxes ONLY that leaf's trust; it must never disable cache/storage
  /// isolation or clear the secure-presentation flag just to make a console
  /// render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that leaves the
  /// privileged console session persisted to disk or exposed to a background
  /// snapshot. It governs the app's own local persistence / screen-capture
  /// surface, so it is distinct from the server-side certificate checks —
  /// hostname verification ([bypassHostnameVerification]), pinning
  /// ([bypassCertificatePinning]), revocation ([bypassCertificateRevocationCheck])
  /// and platform trust-store integrity ([bypassPlatformTrustStoreIntegrity]) —
  /// the TLS floor ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential), the strict
  /// Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's outbound
  /// `Referer` header), CSP / mixed-content enforcement
  /// ([bypassMixedContentBlocking]) (which subresources the page may load) and
  /// sensitive console URL / session-token log redaction ([bypassLogRedaction])
  /// (the app's diagnostic / telemetry output): those govern the connection,
  /// its credentials, its requests or its other local outputs, not on-disk
  /// persistence or screen capture. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassSensitiveDataAtRestProtection => false;

  /// Always `false`: isolation from an injected native JavaScript bridge /
  /// script-message surface is NEVER bypassed, not even by the test-only
  /// self-signed opt-in.
  ///
  /// The embedded WebView must render the remote BMC console with NO native
  /// bridge or message handler injected into the page — no
  /// `addJavascriptInterface`, `WKScriptMessageHandler`,
  /// `WebMessageListener`/`addWebMessageListener`, `WebMessageChannel`, or any
  /// app-controlled `window.*` object exposed to it. Console content is served
  /// by the BMC and is therefore attacker-influenced (a compromised/spoofed BMC
  /// or script running in the page): any exposed bridge is a direct
  /// remote-code-execution path from that content into the host app. Tolerating
  /// the test BMC's untrusted server leaf relaxes ONLY that leaf's trust; it
  /// must never add a bridge or message handler just to make a console render
  /// or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that injects a
  /// native bridge. It governs the code-execution surface exposed to the remote
  /// page, so it is distinct from every server-side certificate check —
  /// hostname verification ([bypassHostnameVerification]), pinning
  /// ([bypassCertificatePinning]), revocation ([bypassCertificateRevocationCheck])
  /// and platform trust-store integrity ([bypassPlatformTrustStoreIntegrity]) —
  /// the TLS floor ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential), the strict
  /// Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's outbound `Referer`
  /// header), CSP / mixed-content enforcement ([bypassMixedContentBlocking])
  /// (which subresources the page may load), sensitive URL / token log redaction
  /// ([bypassLogRedaction]) (the app's diagnostic output) and sensitive data at
  /// rest ([bypassSensitiveDataAtRestProtection]) (on-disk persistence and
  /// screen capture) — those govern the connection, its credentials, its
  /// requests or its other outputs, not native code injected into the page.
  /// See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassNativeBridgeIsolation => false;

  /// Always `false`: isolation of the console's subresource egress from local /
  /// private networks is NEVER bypassed, not even by the test-only self-signed
  /// opt-in.
  ///
  /// The embedded WebView must let attacker-influenced console content open no
  /// subresource socket (fetch / XHR / `<img>` / `<iframe>` / WebSocket / font)
  /// and emit no WebRTC candidate to loopback (`localhost`, `127.0.0.0/8`,
  /// `::1`), link-local (`169.254.0.0/16`, notably the `169.254.169.254` cloud
  /// metadata endpoint) or any private network (`10/8`, `172.16/12`,
  /// `192.168/16`) other than the approved console origin. Console content is
  /// served by the BMC and is therefore attacker-influenced: a page script could
  /// otherwise scan the BMC management network, read cloud-metadata credentials
  /// or probe loopback-only admin services from inside the trusted app — a
  /// server-side-request-forgery (SSRF) / network-reconnaissance / metadata-theft
  /// pivot. The approved console's own top-level URL is NOT restricted (a BMC on
  /// a private address remains a valid launch target); only subresource
  /// destinations are confined.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that permits local /
  /// private-network subresource egress. Tolerating the test BMC's untrusted
  /// server leaf relaxes ONLY that leaf's trust; it must never add a loopback /
  /// link-local / private-network exception just to make a console render or to
  /// debug it. It governs where the page's subresource requests may be SENT, so
  /// it is distinct from every server-side certificate check — hostname
  /// verification ([bypassHostnameVerification]), pinning
  /// ([bypassCertificatePinning]), revocation ([bypassCertificateRevocationCheck])
  /// and platform trust-store integrity ([bypassPlatformTrustStoreIntegrity]) —
  /// the TLS floor and HTTPS-only transport ([bypassTlsProtocolFloor],
  /// [bypassHttpsOnlyTransport]) (the handshake and cleartext sockets),
  /// validated-origin binding ([bypassValidatedOriginBinding]) (the resolved
  /// address of the validated TOP-LEVEL origin at connect time), client
  /// certificate validation ([bypassClientCertificateValidation]) (the client
  /// credential), the strict Referrer-Policy ([bypassStrictReferrerPolicy]) (the
  /// app's own outbound `Referer` header), CSP / mixed-content enforcement
  /// ([bypassMixedContentBlocking]) (which schemes / resource types the page may
  /// load), sensitive URL / token log redaction ([bypassLogRedaction]) (the app's
  /// diagnostic output), sensitive data at rest
  /// ([bypassSensitiveDataAtRestProtection]) (on-disk persistence / screen
  /// capture) and native bridge isolation ([bypassNativeBridgeIsolation]) (code
  /// injected into the page). See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassPrivateNetworkEgressProtection => false;

  /// Always `false`: cross-site cookie / session-token isolation is NEVER
  /// bypassed, not even by the test-only self-signed opt-in.
  ///
  /// The console URI carries the operator's privileged management-session
  /// handle, and the BMC console typically establishes a session cookie/token
  /// that authorises KVM frames and management actions. The embedded WebView
  /// must keep that session credential bound to the console origin: console
  /// session cookies must be `Secure` + `HttpOnly` + `SameSite`-scoped (never
  /// `SameSite=None`), third-party cookies must be blocked, the console cookie
  /// jar must be isolated from the system browser, and the script-readable
  /// `document.cookie` view must never expose the session token. Console
  /// content is served by the BMC and is therefore attacker-influenced: without
  /// this isolation a scripted cross-origin subresource request could attach
  /// the BMC session cookie (CSRF / session theft), or page script could read
  /// `document.cookie` and exfiltrate the token — an account-takeover surface.
  /// Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
  /// trust; it must never relax cookie scoping, permit third-party cookies,
  /// allow script reads of the session cookie, or share the cookie jar just to
  /// make a console render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that leaks the
  /// privileged session via cookies. It governs cookie-attachment and
  /// script-readability semantics for the console session, so it is distinct
  /// from every server-side certificate check — hostname verification
  /// ([bypassHostnameVerification]), pinning ([bypassCertificatePinning]),
  /// revocation ([bypassCertificateRevocationCheck]) and platform trust-store
  /// integrity ([bypassPlatformTrustStoreIntegrity]) — the TLS floor
  /// ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential), the strict
  /// Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's outbound
  /// `Referer` header), CSP / mixed-content enforcement
  /// ([bypassMixedContentBlocking]) (which subresources the page may load),
  /// sensitive URL / token log redaction ([bypassLogRedaction]) (diagnostic
  /// output), sensitive data at rest ([bypassSensitiveDataAtRestProtection])
  /// (on-disk persistence and screen capture), native bridge isolation
  /// ([bypassNativeBridgeIsolation]) (code injected into the page) and
  /// private-network egress protection ([bypassPrivateNetworkEgressProtection])
  /// (the network destinations of subresource requests): those govern the
  /// connection, its credentials, its requests or its other outputs, not
  /// whether the session cookie is attached cross-site or readable by script.
  /// See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassCookieIsolation => false;

  /// Always `false`: WebView remote debugging / inspectability is NEVER enabled,
  /// not even by the test-only self-signed opt-in.
  ///
  /// The embedded WebView must never be remotely debuggable or inspectable in
  /// production: no Android `WebView.setWebContentsDebuggingEnabled(true)`, no
  /// WKWebView `isInspectable = true` / web-inspector entitlement on iOS/macOS,
  /// and no DevTools / `webkit.Debugger` / remote-debugging endpoint or port
  /// exposed to ADB, another app or a nearby device (CWE-489: active debug code).
  /// A remotely debuggable WebView lets an attacker with local/ADB access, or a
  /// malicious co-resident app, attach a debugger, read the DOM, inject script
  /// and exfiltrate the operator's session tokens, credentials and KVM frames —
  /// a credential/session-theft surface. Web-contents debugging and
  /// inspectability must stay disabled in production on every target; the only
  /// place they may be enabled is a test-only validation spike behind the flag,
  /// never to make a console render or to debug a production profile.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that turns on remote
  /// debugging / inspectability. Tolerating the test BMC's untrusted server leaf
  /// relaxes ONLY that leaf's trust; it must never expose the privileged console
  /// to a debugger or inspector. It governs the debug/inspect surface of the
  /// WebView itself, so it is distinct from every server-side certificate check
  /// — hostname verification ([bypassHostnameVerification]), pinning
  /// ([bypassCertificatePinning]), revocation ([bypassCertificateRevocationCheck])
  /// and platform trust-store integrity ([bypassPlatformTrustStoreIntegrity]) —
  /// the TLS floor ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential), the strict
  /// Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's outbound `Referer`
  /// header), CSP / mixed-content enforcement ([bypassMixedContentBlocking])
  /// (which subresources the page may load), sensitive URL / token log redaction
  /// ([bypassLogRedaction]) (diagnostic output), sensitive data at rest
  /// ([bypassSensitiveDataAtRestProtection]) (on-disk persistence and screen
  /// capture), native bridge isolation ([bypassNativeBridgeIsolation]) (code
  /// injected into the page), private-network egress protection
  /// ([bypassPrivateNetworkEgressProtection]) (the destinations of subresource
  /// requests) and cross-site cookie isolation ([bypassCookieIsolation]) (the
  /// session cookie's attachment / script readability): those govern the
  /// connection, its credentials, its requests or its other outputs, not the
  /// WebView's own remote-debugging / inspectability surface. See
  /// `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassWebViewRemoteDebugging => false;

  /// Always `false`: dangerous device-capability / permission access is NEVER
  /// granted to the remote console page, not even by the test-only self-signed
  /// opt-in.
  ///
  /// The embedded WebView must not grant attacker-influenced console content
  /// access to host device capabilities or native/WebKit permission prompts: no
  /// geolocation (`setGeolocationEnabled(true)`, a WKWebView/WebKit location
  /// entitlement), no camera / microphone capture (`onPermissionRequest`,
  /// `getUserMedia`, camera/mic entitlements), no notifications, vibration,
  /// clipboard read, Bluetooth/NFC or file-download capability, and no
  /// auto-granting of any Android runtime permission or WebKit permission to the
  /// page. Console content is served by the BMC and is therefore
  /// attacker-influenced (a compromised/spoofed BMC or script running in the
  /// page): any granted device capability is a privacy / remote-code-execution-
  /// class escalation from that content into the host device. Every console
  /// page runs with all such capabilities denied by default and every
  /// permission request rejected by default, on every target, in strict mode
  /// and with the flag both off and on. Tolerating the test BMC's untrusted
  /// server leaf relaxes ONLY that leaf's trust; it must never grant a device
  /// capability or auto-answer a permission prompt just to make a console
  /// render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that grants device
  /// capabilities to the console page. It governs host-device capabilities
  /// exposed to page content, so it is distinct from the server-side
  /// certificate checks — hostname verification ([bypassHostnameVerification]),
  /// pinning ([bypassCertificatePinning]), revocation
  /// ([bypassCertificateRevocationCheck]) and platform trust-store integrity
  /// ([bypassPlatformTrustStoreIntegrity]) — the TLS floor
  /// ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential), the strict
  /// Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's outbound `Referer`
  /// header), CSP / mixed-content enforcement ([bypassMixedContentBlocking])
  /// (which subresources the page may load), sensitive URL / token log redaction
  /// ([bypassLogRedaction]) (diagnostic output), sensitive data at rest
  /// ([bypassSensitiveDataAtRestProtection]) (on-disk persistence and screen
  /// capture), native bridge isolation ([bypassNativeBridgeIsolation]) (code
  /// injected into the page), private-network egress protection
  /// ([bypassPrivateNetworkEgressProtection]) (the destinations of subresource
  /// requests), cross-site cookie isolation ([bypassCookieIsolation]) (the
  /// session cookie's attachment / script readability) and WebView remote
  /// debugging ([bypassWebViewRemoteDebugging]) (the debug / inspect surface):
  /// those govern the connection, its credentials, its requests, its other
  /// outputs or the WebView's own debug surface — not the device capabilities
  /// granted to page content. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassDevicePermissionControls => false;

  /// Always `false`: HTTP-auth / login-form credential-prompt spoofing is NEVER
  /// enabled — every native authentication challenge is denied by default and
  /// never auto-answered, not even by the test-only self-signed opt-in.
  ///
  /// The embedded WebView must not let attacker-influenced console content — or
  /// a cross-origin subresource returning 401 — induce the operator to enter BMC
  /// credentials into a spoofed native authentication prompt, nor silently
  /// auto-answer a challenge with stored credentials for an unintended origin:
  /// no `onReceivedHttpAuthRequest` / `onReceivedLoginRequest` `proceed()` or
  /// `useHttpAuthUsernamePassword()`, no `setHttpAuthUsernamePassword`
  /// pre-seeding and no `WebStorage` autocomplete of console credentials, and on
  /// iOS/macOS no `URLSession` / WKWebView authentication-challenge handler may
  /// auto-answer with saved credentials or present an unlabelled dialog. Every
  /// challenge is cancelled by default on every target, in strict mode and with
  /// the flag both off and on. Tolerating the test BMC's untrusted server leaf
  /// relaxes ONLY that leaf's trust; it must never present a spoofed credential
  /// prompt or auto-answer a challenge just to make a console render or to debug
  /// it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that auto-answers an
  /// authentication challenge or shows an unlabelled credential prompt. It
  /// governs the platform's native authentication-challenge path, so it is
  /// distinct from the server-side certificate checks — hostname verification
  /// ([bypassHostnameVerification]), pinning ([bypassCertificatePinning]),
  /// revocation ([bypassCertificateRevocationCheck]) and platform trust-store
  /// integrity ([bypassPlatformTrustStoreIntegrity]) — the TLS floor
  /// ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client TLS credential), the
  /// strict Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's outbound
  /// `Referer` header), CSP / mixed-content enforcement
  /// ([bypassMixedContentBlocking]) (which subresources the page may load),
  /// sensitive URL / token log redaction ([bypassLogRedaction]) (diagnostic
  /// output), sensitive data at rest ([bypassSensitiveDataAtRestProtection])
  /// (on-disk persistence and screen capture), native bridge isolation
  /// ([bypassNativeBridgeIsolation]) (code injected into the page),
  /// private-network egress protection
  /// ([bypassPrivateNetworkEgressProtection]) (the destinations of subresource
  /// requests), cross-site cookie isolation ([bypassCookieIsolation]) (the
  /// session cookie's attachment / script readability), WebView remote debugging
  /// ([bypassWebViewRemoteDebugging]) (the debug / inspect surface) and device
  /// capabilities ([bypassDevicePermissionControls]) (host capabilities granted
  /// to page content): those govern the connection, its credentials, its
  /// requests, its other outputs, the WebView's debug surface or the device
  /// capabilities, not the native authentication-challenge path. See
  /// `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassHttpAuthChallengeDenial => false;

  /// Always `false`: local file / content-provider access is NEVER enabled for
  /// the remote console page, not even by the test-only self-signed opt-in.
  ///
  /// The embedded WebView must render the remote BMC console with local file and
  /// content access disabled: no `setAllowFileAccess(true)`,
  /// `setAllowContentAccess(true)`, `setAllowFileAccessFromFileURLs(true)` or
  /// `setAllowUniversalAccessFromFileURLs(true)` on Android `WebSettings`, no
  /// WKWebView `loadFileURL` / local file loading or file-read entitlement on
  /// iOS/macOS, and no load of or navigation to a `file://` / `content://` URL
  /// (whether by the initial load, a redirect, a link or script). Console
  /// content is served by the BMC and is therefore attacker-influenced (a
  /// compromised/spoofed BMC or script running in the page): with local/content
  /// access a console script could read app-private data or local files and
  /// exfiltrate them — a data-theft / remote-code-execution-class escalation.
  /// Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
  /// trust; it must never enable a local file/content read just to make a
  /// console render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that grants local
  /// file/content access. It governs the host files / content providers the
  /// remote page may read, so it is distinct from every server-side certificate
  /// check — hostname verification ([bypassHostnameVerification]), pinning
  /// ([bypassCertificatePinning]), revocation
  /// ([bypassCertificateRevocationCheck]) and platform trust-store integrity
  /// ([bypassPlatformTrustStoreIntegrity]) — the TLS floor
  /// ([bypassTlsProtocolFloor]), HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) and validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the handshake, cleartext sockets and
  /// resolved address), client-certificate validation
  /// ([bypassClientCertificateValidation]) (the client credential), the strict
  /// Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's outbound
  /// `Referer` header), CSP / mixed-content enforcement
  /// ([bypassMixedContentBlocking]) (which subresources the page may load),
  /// sensitive URL / token log redaction ([bypassLogRedaction]) and data at rest
  /// ([bypassSensitiveDataAtRestProtection]) (the app's diagnostic output and
  /// on-disk persistence), native bridge isolation
  /// ([bypassNativeBridgeIsolation]) (code injected into the page),
  /// private-network egress protection ([bypassPrivateNetworkEgressProtection])
  /// (the destinations of subresource requests), cookie isolation
  /// ([bypassCookieIsolation]) (session-cookie attachment / script
  /// readability), WebView remote debugging ([bypassWebViewRemoteDebugging])
  /// (the debug / inspect surface), device-capability / permission access
  /// ([bypassDevicePermissionControls]) (host capabilities granted to page
  /// content) and HTTP-auth challenge denial ([bypassHttpAuthChallengeDenial])
  /// (the native authentication-challenge path): those govern the connection,
  /// its credentials, its requests, its outputs or host capabilities, not local
  /// file/content reads by the remote page. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassLocalFileAccess => false;

  /// Whether the console WebView may relax its outbound egress allowlist.
  ///
  /// Always `false`: the console page is served by the BMC and is therefore
  /// attacker-influenced, so it must never open a programmatic network
  /// connection (fetch / XHR / WebSocket / WebRTC / `sendBeacon` /
  /// `EventSource` / media) to any origin other than the approved console
  /// origin. A CSP `connect-src 'self'` allowlist plus WebView request
  /// interception confine every such connection; this is a covert-channel /
  /// cross-origin data-exfiltration surface (KVM frames, session tokens,
  /// credentials, managed-host inventory leaking to an attacker-controlled
  /// external host, or a command-and-control channel) wholly independent of
  /// TLS, hostname, navigation and subresource-address-class checks.
  ///
  /// This is a hard, configuration-independent invariant that a future WebView
  /// consumer can consult: the test-only opt-in relaxes ONLY the test BMC's
  /// untrusted server leaf for the expected host and can never let console
  /// content connect to a non-approved origin — not for rendering, not for
  /// debugging. It is distinct from private-network egress protection
  /// ([bypassPrivateNetworkEgressProtection]) (the destination ADDRESS CLASS —
  /// loopback / link-local / private LAN — of subresources), mixed-content
  /// blocking ([bypassMixedContentBlocking]) (framing rules and cleartext
  /// subresources), top-level navigation confinement (where the frame may
  /// go), cross-origin form submission (the `<form>` POST path) and the strict
  /// Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's own outbound
  /// `Referer` header): those govern other connection, request or output
  /// surfaces, not the destinations of the page's programmatic connections.
  /// See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassOutboundEgressAllowlist => false;

  /// Always `false`: cross-origin form submission / data exfiltration is NEVER
  /// bypassed, not even by the test-only self-signed opt-in.
  ///
  /// The console page is served by the BMC and is therefore attacker-influenced,
  /// so the embedded WebView must never let it exfiltrate operator credentials,
  /// session tokens or KVM frame data through an HTML form: no `<form action>`
  /// (GET query or POST body) targeting any origin other than the approved
  /// same-origin HTTPS console, no auto-submit-on-load or scripted
  /// `form.submit()` that silently sends console DOM data to an attacker origin,
  /// and no browser autofill of saved console credentials into an
  /// attacker-controlled form. A form is a distinct navigation and data channel
  /// from a link's top-level navigation, a subresource fetch and a programmatic
  /// connection: a `POST` carries a body that can smuggle session tokens or KVM
  /// frames out of the trusted frame without any visible URL change. Tolerating
  /// the test BMC's untrusted server leaf relaxes ONLY that leaf's trust; it
  /// must never permit a cross-origin form submission just to make a console
  /// render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that permits a form
  /// to send privileged console data to a non-approved origin. It governs the
  /// form-submission / POST-body data channel, so it is distinct from origin /
  /// navigation confinement (where the top-level frame may go), the outbound
  /// egress allowlist ([bypassOutboundEgressAllowlist]) (the destinations of
  /// the page's programmatic fetch / WebSocket / WebRTC connections) and
  /// private-network egress protection ([bypassPrivateNetworkEgressProtection])
  /// (the address class of subresources) — those govern other navigation or
  /// request surfaces, not HTML form submissions or their request bodies. It is
  /// also distinct from the strict Referrer-Policy ([bypassStrictReferrerPolicy])
  /// and log redaction ([bypassLogRedaction]) (the app's own URL header and
  /// diagnostic output) and every server-side certificate / TLS / transport
  /// check: those govern the connection, its credentials and its other outputs,
  /// not the form POST path. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassCrossOriginFormSubmission => false;

  /// Always `false`: the WebView's TLS certificate-error callback is NEVER
  /// turned into a blanket accept, not even by the test-only self-signed opt-in.
  ///
  /// When the platform TLS stack rejects the BMC certificate for ANY reason —
  /// expired, untrusted / self-signed on a production profile, hostname /
  /// identity mismatch, revoked, or a weak signature — the embedded WebView's
  /// certificate-error path must fail closed: Android
  /// `WebViewClient.onReceivedSslError` must `cancel()` (never `proceed()`),
  /// WKWebView / `URLSession` must cancel the challenge / reject the delegate,
  /// and Dart `HttpClient.badCertificateCallback` must remain `false` on a
  /// production profile. Console content is served by the BMC and is therefore
  /// attacker-influenced: a single blanket-accept error handler would silently
  /// defeat hostname verification, pinning, revocation and the TLS floor at
  /// once, so the error-handling path is its own control surface. Tolerating
  /// the test BMC's untrusted server leaf relaxes ONLY that leaf's trust,
  /// through a scoped per-connection verifier bound to the expected console
  /// host; it must never install a blanket `proceed()` /
  /// `badCertificateCallback => true` just to make a console render or to
  /// debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy whose error handler
  /// accepts a rejected certificate. It governs the reaction path when
  /// certificate validation FAILS, so it is distinct from the checks that
  /// decide acceptance: hostname verification ([bypassHostnameVerification])
  /// and pinning ([bypassCertificatePinning]) bind server identity/key,
  /// revocation ([bypassCertificateRevocationCheck]) checks certificate status,
  /// platform trust-store integrity ([bypassPlatformTrustStoreIntegrity])
  /// governs device-wide anchors, client-certificate validation
  /// ([bypassClientCertificateValidation]) governs the client credential, and
  /// the TLS floor ([bypassTlsProtocolFloor]) and HTTPS-only transport
  /// ([bypassHttpsOnlyTransport]) govern the handshake and cleartext sockets.
  /// See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassSslErrorRejection => false;

  /// Always `false`: the console frame's top-level navigation is NEVER allowed
  /// off the approved same-origin HTTPS console, not even by the test-only
  /// self-signed opt-in.
  ///
  /// The embedded WebView must confine the TOP-LEVEL frame to the approved
  /// console origin: no navigation (Android `WebViewClient.
  /// shouldOverrideUrlLoading`, WKWebView `decidePolicyForNavigationAction`)
  /// to a different origin, a plaintext `http://` page, a non-http(s) scheme
  /// (deep link / `javascript:`), or a spoofed/phishing page; and no escape via
  /// a pop-up / secondary window, a scripted `window.location`, a `<meta
  /// refresh>` or an iframe break-out. Console content is served by the BMC and
  /// is therefore attacker-influenced (a compromised/spoofed BMC or script
  /// running in the page): without confinement an attacker could redirect the
  /// privileged console frame to a look-alike login page and harvest the
  /// operator's BMC credentials or session token, downgrade the load to
  /// cleartext, or hand the session to a different origin — a credential /
  /// session-theft and phishing surface. Tolerating the test BMC's untrusted
  /// server leaf relaxes ONLY that leaf's trust, through a scoped per-connection
  /// verifier bound to the expected console host; it must never let the frame
  /// navigate away just to make a console render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that relaxes
  /// navigation confinement. It governs where the top-level frame may go, so
  /// it is distinct from the outbound egress allowlist
  /// ([bypassOutboundEgressAllowlist]) (the destinations of the page's
  /// programmatic fetch / WebSocket / WebRTC connections), private-network
  /// egress protection ([bypassPrivateNetworkEgressProtection]) (the address
  /// class of subresources), cross-origin form submission
  /// ([bypassCrossOriginFormSubmission]) (the form POST body channel), CSP /
  /// mixed-content blocking ([bypassMixedContentBlocking]) (which subresources
  /// the page may load), HTTPS-only transport ([bypassHttpsOnlyTransport])
  /// (cleartext sockets), validated-origin binding
  /// ([bypassValidatedOriginBinding]) (the resolved address at connect time)
  /// and the strict Referrer-Policy ([bypassStrictReferrerPolicy]) (the app's
  /// outbound `Referer` header): those govern connections, requests, outputs
  /// or the initial address, not navigation of the top-level frame. See
  /// `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassTopLevelNavigationConfinement => false;

  /// Always `false`: arbitrary / drive-by file download is NEVER enabled, not
  /// even by the test-only self-signed opt-in.
  ///
  /// The embedded WebView must not let attacker-influenced console content
  /// trigger a file download that escapes the trusted frame or lands a runnable
  /// file on the device: no `<a download>`, scripted `window.location`, redirect
  /// or `Content-Disposition: attachment` download, no auto-open via Android
  /// `DownloadManager` / `setDownloadListener` handing an `.apk` / `.exe` / `.dmg`
  /// / `.sh` to an install / launch intent, no auto-install and no
  /// console-controlled destination or filename. Console content is served by
  /// the BMC and is therefore attacker-influenced (a compromised/spoofed BMC or
  /// script in the page): a drive-by download is a distinct response / intent
  /// channel from top-level navigation, subresource fetch and form POST, so an
  /// attacker-chosen executable delivered through the trusted console frame and
  /// then opened is a code-execution / malware-installation surface. Every
  /// download is blocked at the WebView (a canceling `setDownloadListener` that
  /// at most hands the HTTPS URI to the external secure browser), with no
  /// auto-open, no auto-install and no console-controlled destination, on every
  /// target, in strict mode and with the flag both off and on. Tolerating the
  /// test BMC's untrusted server leaf relaxes ONLY that leaf's trust; it must
  /// never permit a drive-by download just to make a console render or to debug
  /// it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that permits an
  /// arbitrary / drive-by file download. It governs the download / intent
  /// channel, so it is distinct from top-level navigation confinement
  /// ([bypassTopLevelNavigationConfinement]) (where the frame may go), the
  /// outbound egress allowlist ([bypassOutboundEgressAllowlist]) (destinations
  /// of programmatic connections), cross-origin form submission
  /// ([bypassCrossOriginFormSubmission]) (the form POST body channel), CSP /
  /// mixed-content blocking ([bypassMixedContentBlocking]) (which subresources
  /// the page may load) and local file / content access ([bypassLocalFileAccess])
  /// (local file reads): those govern navigation, connections, requests or local
  /// reads, not the download of a file to the device. See `WEBVIEW_TLS_MATRIX.md`
  /// (RP-1).
  bool get bypassArbitraryFileDownload => false;

  /// Always `false`: browser/password-manager autofill capture of BMC console
  /// credentials is NEVER enabled, not even by the test-only self-signed opt-in.
  ///
  /// The embedded WebView must never let attacker-influenced console content or
  /// a platform autofill / password-manager service capture, save, persist or
  /// re-inject the operator's BMC credentials through the console login form:
  /// no password-manager saving of a typed BMC username/password or session
  /// token, no `Android Autofill` / `AutofillManager` /
  /// `setImportantForAutofill` / iOS `AutoFill` / `textContentType` credential
  /// capture or credential export, no pre-seeding of saved credentials into an
  /// attacker-influenced or spoofed login form and no autofill suggestion that
  /// one origin can read from another. Autofill is denied by default on every
  /// target (e.g. `IMPORTANT_FOR_AUTOFILL_NO` / `NO_EXCLUDES_DESCENDANTS`,
  /// `isAutofillEnabled = false`, no autofill `AccessibilityService`, no
  /// credential provider bound to the console). Console content is served by
  /// the BMC and is therefore attacker-influenced (a compromised/spoofed BMC or
  /// script in the page): an open credential-autofill channel can silently
  /// exfiltrate the BMC login on form submit or auto-fill a spoofed form. It is
  /// closed on every target, in strict mode and with the flag both off and on.
  /// Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
  /// trust for the expected host (via a scoped per-connection verifier); it must
  /// never enable autofill to make a console render or to debug it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that enables
  /// autofill / password-manager credential capture. It governs the credential
  /// autofill channel, so it is distinct from HTTP-auth / login-form challenge
  /// denial ([bypassHttpAuthChallengeDenial]) and its stored credentials /
  /// WebStorage autocomplete, cross-site cookie isolation
  /// ([bypassCookieIsolation]) (session-cookie attachment and script
  /// readability), cross-origin form submission ([bypassCrossOriginFormSubmission])
  /// (the form POST body), sensitive data at rest
  /// ([bypassSensitiveDataAtRestProtection]) (on-disk persistence / screen
  /// capture) and outbound egress / private-network egress
  /// ([bypassOutboundEgressAllowlist], [bypassPrivateNetworkEgressProtection])
  /// (request destinations): those govern the challenge dialog, cookies, the
  /// POST body, storage or destinations, not browser autofill of credential
  /// fields. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassAutofillCredentialCapture => false;

  /// Always `false`: the console WebView never opens a native file chooser /
  /// file-input picker, so attacker-influenced console content cannot make the
  /// operator select a local file and upload / exfiltrate it, not even by the
  /// test-only self-signed opt-in.
  ///
  /// The embedded WebView must never let remote BMC console content invoke a
  /// local-file selection surface: no HTML `<input type="file">` picker, no
  /// Android `WebChromeClient.onShowFileChooser` / `showFileChooser` /
  /// `ACTION_OPEN_DOCUMENT` / `ACTION_GET_CONTENT` / camera-capture intent, and
  /// no WKWebView / WebKit file-upload panel or file-read entitlement may be
  /// shown or answered for the page. Console content is served by the BMC and
  /// is therefore attacker-influenced (a compromised/spoofed BMC or script
  /// running in the page): an attacker-chosen file input can socially engineer
  /// the operator into selecting an on-device document, SSH key, token file or
  /// credential store which is then uploaded into the trusted frame and sent
  /// to the BMC or an attacker origin — a local-file-exfiltration surface
  /// wholly independent of direct `file://` reads, downloads and device
  /// permissions. Every file-chooser / file-upload request is denied by default
  /// on every target, in strict mode and with the flag both off and on.
  /// Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
  /// trust for the expected host (via a scoped per-connection verifier); it
  /// must never open a file chooser just to make a console render or to debug
  /// it.
  ///
  /// This is a hard, configuration-independent invariant, so a future WebView
  /// consumer can consult it and can never obtain a policy that enables a file
  /// chooser / file-upload picker. It governs the operator-mediated local-file
  /// SELECTION / upload channel, so it is distinct from local file / content
  /// access ([bypassLocalFileAccess]) (the page's own direct `file://` /
  /// `content://` reads), arbitrary / drive-by file download
  /// ([bypassArbitraryFileDownload]) (a file written TO the device), device
  /// capabilities ([bypassDevicePermissionControls]) (host capabilities such as
  /// camera / clipboard), cross-origin form submission
  /// ([bypassCrossOriginFormSubmission]) (the form POST body channel) and the
  /// outbound egress allowlist ([bypassOutboundEgressAllowlist]) (connection
  /// destinations): those govern other local-read, write, capability or
  /// request surfaces, not a native file picker handing a chosen local file to
  /// the page. See `WEBVIEW_TLS_MATRIX.md` (RP-1).
  bool get bypassFileChooserAccess => false;

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
/// With the flag off this selects [KvmConsoleRenderRoute.externalBrowser] for
/// an enabled HTTPS console and [KvmConsoleRenderRoute.copyOnly] otherwise, so
/// the existing external-browser + copy path keeps working unchanged (RP-2
/// fallback requirement). `hasSecureUri` mirrors `KvmConsole.hasSecureLaunchUri`
/// (HTTPS with a non-empty host).
///
/// A console the BMC reports disabled is **never** given a launchable route —
/// it always fails closed to [KvmConsoleRenderRoute.copyOnly], even when its
/// URI is HTTPS. This keeps the decision layer in lockstep with
/// `KvmConsole.canOpenConsole` (and the console card / viewer gating): a BMC may
/// publish a `ConnectUri` while reporting `ServiceEnabled: false`, and handing
/// that URI to a browser when a WebView/launcher is eventually wired would
/// reintroduce the dead-end launch the UI already refuses (issue #009/#021).
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
  // Fail closed for a console the BMC reports disabled: no browser/in-app
  // launch target, only the copy path. Checked after the in-app branch so the
  // opt-in's own isEnabled gate stays authoritative, but before the transport
  // fallback so an HTTPS URI cannot sneak a disabled console into a launcher.
  if (!isEnabled) return KvmConsoleRenderRoute.copyOnly;
  if (hasSecureUri) return KvmConsoleRenderRoute.externalBrowser;
  return KvmConsoleRenderRoute.copyOnly;
}
