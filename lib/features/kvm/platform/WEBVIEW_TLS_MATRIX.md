# WebView / TLS validation matrix — in-app KVM console (RP-1)

Owner: rf-platform · Status: **design spike, flag OFF** · Date: 2026-11-19

## Question

Can `webview_flutter` (or a platform WebView) render an HTTPS BMC console on the
available Linux/desktop target, and how can self-signed BMC certificates be
handled **without weakening production TLS**?

## Evidence status (be honest about what was actually run)

| Claim | Status |
|---|---|
| `webview_flutter` (or any WebView plugin) in `pubspec.yaml` | **Absent** — verified, unchanged in this item |
| Platform-channel / WebView render executed on this target | **Not run** — no plugin, no engine, no emulator here |
| HTTPS BMC console rendered in-app on Linux/desktop | **Unproven** |
| Production TLS posture | **Unchanged** — this item adds no transport code |

Conclusion: there is no validation evidence that an embedded WebView can render
a BMC console on the available target. Per the hard rule ("no WebView/protocol
dependency without platform validation"), this item **does not bump any
dependency**; it records the matrix and the reversible opt-in design only.

## Platform support matrix

"Package support" is the upstream capability to confirm at bump time; "Validated
here" is what this spike actually exercised (nothing). Treat every row as
**requires validation** before a flag is ever flipped on a real profile.

| Target | In-app WebView via `webview_flutter` (to confirm at bump) | Self-signed BMC cert handling | Validated here | Decision for this item |
|---|---|---|---|---|
| **Linux desktop (available target)** | No first-class stable Linux implementation; would need a new platform impl / alternative (e.g. WebKitGTK binding) — i.e. a new dependency + platform channel | Platform `HttpClient` honors the trust store; any acceptance needs an explicit per-profile opt-in | **No** | Out of scope: no dependency, no embedded rendering. External browser + copy path only. |
| Windows desktop | Not first-class in stable `webview_flutter`; needs an alternative plugin + validation | Same as Linux (OS trust store + explicit opt-in) | **No** | External browser + copy path only. |
| macOS | Via `WKWebView` platform implementation (confirm version at bump) | OS trust store; WebView TLS error callback must reject by default; opt-in per test profile | **No** | Defer to RP-2 behind the flag + validation. |
| Android | Via Android WebView platform implementation (confirm version at bump) | OS trust store; `onReceivedSslError`/`WebViewClient` must `cancel()` by default, never `proceed()` on production | **No** | Defer to RP-2 behind the flag + validation. |
| iOS | Via `WKWebView` platform implementation | ATS + OS trust store; self-signed acceptance is a test-only entitlement, never production | **No** | Defer to RP-2 behind the flag + validation. |
| Web | Package supports an iframe-based WebView (confirm); BMC consoles often block framing via `X-Frame-Options` / CSP | Browser governs certificates; cannot be suppressed programmatically — a self-signed BMC must present a browser-trusted cert (matches `http_client_config_web.dart`) | **No** | Browser-only; self-signed cannot be opt-in here. |

## How self-signed certs are handled today (no TLS weakening)

The app already separates transport TLS policy by platform with conditional
imports under `lib/redfish/client/`:

* `http_client_config_io.dart` — default `IOHttpClientAdapter()` validates
  certificates. Self-signed acceptance is an **explicit per-profile opt-in**
  (`allowSelfSigned`) that sets `badCertificateCallback => true`, acknowledged
  in the profile form with a warning.
* `http_client_config_web.dart` — `allowSelfSigned` is a documented **no-op**;
  the browser trust store governs TLS and cannot be bypassed.

This opt-in, per-profile, default-strict pattern is the model any future WebView
must follow. A WebView controller's certificate-error path must **reject by
default** and only accept on a test-only flag — never a blanket `proceed()` on
production builds.

## Reversible opt-in design (`webview_policy.dart`)

A pure, dependency-free contract encodes the decision (no plugin, no channel, no
transport change):

* `KvmWebViewPolicy.productionDefault` — flag **off**, TLS **strict**. Nothing
  imports this in production yet; in-app rendering is unreachable by default.
* `KvmWebViewPolicy.testOptIn` — flag on, self-signed tolerated **only** on
  HTTPS and **only** for a test profile. Never derived from a normal profile.
* `permitsInAppRendering(...)` requires flag on + enabled + HTML5 + HTTPS
  (`hasSecureUri`). Plaintext HTTP is never an in-app render target.
* `mayAcceptSelfSigned(...)` is true only for the test-only mode, on HTTPS, and
  only for a console that may actually be rendered in-app (enabled + HTML5).
  Strict mode, plaintext, a disabled console and a non-HTML5 console always
  refuse. It reuses `permitsInAppRendering` as the single source of truth, so a
  future WebView consumer that calls this boolean directly can never grant
  self-signed acceptance for a console that will not be rendered in-app.
* `resolveRenderRoute(...)` proves the fallback: with the flag off, HTTPS routes
  to `externalBrowser` and everything else to `copyOnly`.
* 11 targeted tests lock these invariants in (RED→GREEN this run).

## Decision & fallbacks

* **RP-1 outcome:** no `pubspec.yaml` change, no production TLS change, no
  embedded WebView. The existing viewer (launch URI + status + copy action) and
  external secure-browser path remain the only rendering route and keep working
  with the flag off.
* **RP-2 gate:** an implementation may only proceed behind the opt-in flag and
  with recorded per-target validation evidence (render an HTTPS console, verify
  cert rejection by default, verify test-only self-signed acceptance, verify no
  plaintext downgrade, verify the flag-off fallback). No evidence → no flag flip.

## Validation evidence — detailed acceptance criteria

The RP-2 gate above is the *rule*; this section is the concrete, per-target
**acceptance checklist** that must be satisfied and recorded BEFORE any
`webview_flutter` / `url_launcher` dependency, embedded WebView or test-only TLS
opt-in is enabled on a real profile. It complements (does not grant) the human
approval gate: **this run checks none of these boxes and grants no approval.**
Production stays on `KvmWebViewPolicy.productionDefault` (flag OFF, strict TLS)
and the external-browser + copy fallback stays byte-for-byte.

Every applicable box below must be ticked, with a date and reviewer recorded,
for each target being enabled; an unticked box means "not validated" and the
flag stays off for that target.

* [ ] **WebView availability (per target)** — an embedded WebView can actually
      render an HTTPS BMC console on the target, with the plugin/platform impl
      version pinned. No OS/engine target here has this evidence yet.
* [ ] **TLS trust, no production weakening** — an untrusted / self-signed BMC
      cert is rejected by default via the platform trust store; any acceptance
      is a reversible, test-profile-only opt-in that never touches production
      TLS. No blanket `proceed()` / `badCertificateCallback => true` on a
      production profile.
* [ ] **Certificate-error callback rejects by default (never bypassed)** — when
      the platform TLS stack rejects the BMC certificate for ANY reason
      (expired, untrusted/self-signed on a production profile, hostname /
      identity mismatch, revoked, weak signature), the WebView's certificate-
      error callback must fail closed: Android
      `WebViewClient.onReceivedSslError` must `cancel()` (never `proceed()`),
      WKWebView / `URLSession` must cancel the challenge / `URLSession` delegate
      must reject, Dart `HttpClient.badCertificateCallback` must stay `false`
      on a production profile, and no override may resume the load. Console
      content is served by the BMC and is therefore attacker-influenced: a
      single blanket-accept error handler would silently defeat hostname
      verification, pinning, revocation and the TLS floor at once, so the
      error-handling path is a control surface of its own. Verified per target
      (inject an invalid/expired/revoked/hostname-mismatched BMC certificate,
      observe the console fails closed with the flag both off and on) before
      the flag is flipped. This is a hard, configuration-independent invariant
      that a future WebView consumer can consult
      (`KvmWebViewPolicy.bypassSslErrorRejection`, always `false`): the opt-in
      never bypasses SSL certificate-error rejection — every certificate error
      fails closed, in strict mode and with the flag both off and on. The
      test-only self-signed opt-in relaxes ONLY the test BMC's untrusted server
      leaf for the expected host, through a scoped per-connection verifier; it
      must never install a blanket `proceed()` / `badCertificateCallback =>
      true` that would make the privileged console session accept any
      certificate just to make a console render or to debug it. This box
      governs the WebView's reaction path when certificate validation fails,
      so it is distinct from hostname verification (which binds certificate
      identity to the console host), pinning (which binds the expected key),
      revocation (which checks certificate status), platform trust-store
      integrity (device-wide anchors), the TLS floor and HTTPS-only transport
      (the handshake and cleartext sockets) and client-certificate validation
      (the client credential): those decide whether a certificate/connection
      is acceptable, whereas this box governs the fail-closed handler when any
      of them rejects. Verified per target before the flag is flipped.
* [ ] **Top-level navigation confinement (never bypassed)** — the WebView's
      top-level frame must never navigate off the approved same-origin HTTPS
      console: no navigation (Android `WebViewClient.shouldOverrideUrlLoading`,
      WKWebView `decidePolicyForNavigationAction`) to a different origin, a
      plaintext `http://` page, a non-http(s) scheme (deep link / `javascript:`)
      or a spoofed/phishing page, and no escape via a pop-up / secondary window,
      a scripted `window.location`, a `<meta refresh>` or an iframe break-out.
      Console content is served by the BMC and is therefore attacker-influenced:
      without confinement an attacker could redirect the privileged console
      frame to a look-alike login page and harvest the operator's BMC
      credentials or session token, downgrade the load to cleartext, or hand
      the session to another origin. Verified per target (attempt cross-origin,
      plaintext, non-http(s) and scripted/pop-up navigations; observe the frame
      stays on the approved console with the flag both off and on) before the
      flag is flipped. This is a hard, configuration-independent invariant that
      a future WebView consumer can consult
      (`KvmWebViewPolicy.bypassTopLevelNavigationConfinement`, always `false`):
      the opt-in never bypasses top-level navigation confinement — the frame is
      confined to the approved console origin in strict mode and with the flag
      both off and on. The test-only self-signed opt-in relaxes ONLY the test
      BMC's untrusted server leaf for the expected host, through a scoped
      per-connection verifier; it must never permit the frame to navigate away
      just to make a console render or to debug it. This box governs where the
      top-level frame may go, so it is distinct from the outbound egress
      allowlist (destinations of programmatic connections), private-network
      egress (address class of subresources), cross-origin form submission (the
      form POST body channel), CSP / mixed-content blocking (which subresources
      the page may load), HTTPS-only transport (cleartext sockets),
      validated-origin binding (the resolved address at connect time) and the
      strict Referrer-Policy (the app's outbound `Referer` header): those govern
      connections, requests, outputs or the initial address, not navigation of
      the top-level frame. Verified per target before the flag is flipped.
* [ ] **Hostname verification (never bypassed by the opt-in)** — even under the
      test-only self-signed acceptance path, the certificate's identity is still
      matched against the console's hostname. Accepting a self-signed leaf must
      never disable hostname / certificate-identity verification (no blanket
      `SSLSocketFactory` trust-all, no wildcard/catch-all host verifier, no
      `allowSelfSigned`-implies-`verifyHostname:false` shortcut): otherwise any
      host could impersonate the BMC and the opt-in becomes a MITM vector. The
      opt-in tolerates only an otherwise-valid cert for the *expected* BMC host
      that is untrusted by the platform store; it is not a general certificate
      check bypass. Verified per target before the flag is flipped.
* [ ] **Certificate pinning / public-key pinning (no trust-all, no
      accept-any-certificate)** — the embedded WebView must bind the console to
      the expected BMC certificate or public key (a pinned SPKI fingerprint or an
      operator-supplied pin), so that a DIFFERENT, otherwise-valid and
      platform-trusted certificate for the same hostname cannot impersonate the
      BMC and take over the privileged management session. This is a control
      distinct from hostname verification: hostname verification checks that the
      certificate's identity matches the console's hostname, whereas pinning
      additionally binds the connection to the specific expected key, so a valid
      certificate issued to that same name by another trusted CA — or a
      rotated / attacker-supplied leaf — cannot transparently replace the BMC.
      Strict mode keeps the OS trust-store validation AND enforces the pin. The
      test-only self-signed opt-in tolerates only the test BMC's untrusted leaf
      for the expected host and must never relax the pinning or degrade to a
      trust-all / accept-any-certificate verifier — it must never accept any
      certificate presented by an unexpected host: a blanket `TrustManager` that
      accepts every chain, a catch-all `SSLSocketFactory`, or a disabled
      certificate-identity check would hand the operator's privileged session to
      any host and turn the opt-in into a MITM vector. Console content is served
      by the BMC and is therefore attacker-influenced, but the pin belongs to the
      operator-configured identity and is never derived from page content or an
      external actor. Verified per target (inspect the WebView TLS configuration
      and confirm the expected BMC pin is enforced and no trust-all /
      accept-any-certificate path exists, with the flag both off and on) before
      the flag is flipped.
* [ ] **TLS protocol-version / cipher-suite floor (no downgrade)** — the
      embedded WebView must negotiate only a modern TLS protocol version and
      strong cipher suites for the console origin, never a legacy or weakened
      handshake: no TLS 1.0 / TLS 1.1 (or SSLv3), no weak / export / NULL /
      anonymous cipher suites, no 3DES / RC4 / MD5-based suites, and no fallback
      that silently downgrades a TLS 1.2 / TLS 1.3 connection to a weaker
      version (downgrade protection such as TLS_FALLBACK_SCSV /
      `supported_versions` must stay intact). This box is distinct from the
      trust-store and hostname-verification checks: a console can present a
      valid, correctly-named certificate yet still be negotiated over a weak
      protocol or cipher, exposing the operator's privileged management session
      to a downgrade / decryption attack independent of certificate validity.
      The per-target WebView / platform TLS configuration must enforce a TLS 1.2+
      floor with strong cipher suites and no downgrade, in strict mode **and**
      in the test-only self-signed opt-in — the opt-in must never relax the
      protocol / cipher floor even though it tolerates the untrusted leaf.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassTlsProtocolFloor`, always
      `false`): the test-only opt-in never bypasses the TLS floor, in strict
      mode and with the flag both off and on. It is distinct from hostname
      verification and certificate/public-key pinning, which govern certificate
      identity and key binding rather than the handshake's protocol/cipher
      strength. Verified per target (inspect the WebView TLS configuration and
      an observed handshake) before the flag is flipped.
* [ ] **No cleartext / HTTPS-only transport at the WebView platform layer (no
      plaintext fallback)** — independently of the handshake floor above, the
      embedded WebView's *platform network configuration* must forbid cleartext
      HTTP traffic entirely: Android `usesCleartextTraffic=false` / Network
      Security Config `cleartextTrafficPermitted=false`, and Apple ATS enforced
      with no `NSAllowsArbitraryLoads` / `NSExceptionAllowsInsecureHTTPLoads`
      escape hatch (no per-domain exception back down to plain HTTP), on every
      target. The decision layer already refuses plaintext launch targets and
      every in-session plaintext navigation, but a platform config that permits
      cleartext can still let a redirect, a subresource, an upgrade/downgrade
      proxy or a fallback path silently open an `http://` socket for the trusted
      console outside that decision layer. This is a distinct control surface
      from the TLS protocol-version / cipher-suite floor (which governs a TLS
      handshake that actually occurs) and from origin confinement (which governs
      in-session navigations): it governs whether ANY cleartext socket may be
      opened by the WebView at all. Console content is served by the BMC and is
      therefore attacker-influenced (a compromised/spoofed BMC, or script running
      in the page): a cleartext fallback hands the operator's privileged
      management session — session tokens, credentials, KVM frames — to any
      on-path observer, wholly independent of certificate trust, hostname
      verification, protocol version and navigation checks. The test-only
      self-signed opt-in relaxes ONLY leaf trust: it must never add a cleartext
      exception, must never set `cleartextTrafficPermitted=true` or
      `usesCleartextTraffic=true`, and must never enable `NSAllowsArbitraryLoads`
      or an insecure-load exception — not even for the test profile. The console
      WebView opens no plaintext socket on any target. Verified per target
      (inspect the WebView host's network-security config / ATS settings and
      confirm no cleartext request can be made, with the flag both off and on)
      before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassHttpsOnlyTransport`, always
      `false`): the test-only opt-in never bypasses the HTTPS-only floor and can
      never open a cleartext socket, in strict mode and with the flag both off
      and on. It is distinct from the TLS protocol-version / cipher-suite floor
      (which governs a handshake that actually occurs) and from hostname
      verification / certificate-public-key pinning (which govern certificate
      identity and key binding): this box governs whether ANY cleartext socket
      may be opened at all. No policy configuration can permit cleartext
      transport; the opt-in relaxes only leaf trust, never the HTTPS-only floor.
* [ ] **No DNS rebinding / stale-resolution (connect to the validated origin,
      not a re-resolved one)** — the embedded WebView must not let an
      attacker-influenced console hostname pass the same-origin HTTPS validation
      at decision time and then, at connect time, be re-resolved by the platform
      resolver to a DIFFERENT address than the one that was validated: no DNS
      rebinding (a name that resolves first to the approved BMC address during
      validation and then to loopback / link-local / cloud-metadata / an
      internal management-network service when the WebView actually connects),
      no time-of-check / time-of-use (TOCTOU) gap between the fail-closed
      authority check and the WebView's own load, and no host-vs-address
      mismatch where the WebView contacts a resolved address different from the
      validated authority. Console content is served by the BMC and is
      therefore attacker-influenced (a compromised/spoofed BMC, or script
      running in the page): a validated name that is re-resolved to an internal
      address turns the in-app frame into a confused-deputy pivot that can reach
      loopback-only admin services, the `169.254.169.254` metadata endpoint or
      the BMC management network — an SSRF-class surface wholly independent of
      TLS negotiation, hostname-string validation, subresource egress and
      top-level-navigation confinement, which govern the handshake, the literal
      authority text, subresource destinations and in-session navigation, not
      the resolution of the validated top-level origin at connect time. The
      per-target WebView / platform must pin the console to the validated
      host/address (or re-validate the resolved address at connect time) so the
      trusted frame can never be silently redirected to a different address
      after passing the fail-closed check. Verified per target (inspect the
      WebView connection/resolution path and observe the resolved address at
      connect time) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassValidatedOriginBinding`,
      always `false`): the test-only opt-in never bypasses binding to the
      validated origin — the console connects only to the address that passed
      the fail-closed origin check, never a re-resolved one — in strict mode and
      with the flag both off and on. It is distinct from hostname verification
      and certificate/public-key pinning (which bind certificate identity/key),
      the TLS protocol/cipher floor and HTTPS-only transport (which govern the
      handshake and cleartext sockets) and certificate revocation checking
      (which checks certificate status): those govern the certificate and the
      handshake, whereas this box governs which resolved address the validated
      top-level origin is allowed to connect to. Verified per target before the
      flag is flipped.
* [ ] **Origin / navigation confinement (no cross-origin or downgrade nav)** —
      an embedded WebView must never follow a redirect, link click, `window.open`
      or JavaScript-initiated top-level navigation to a different host/port or
      to a plaintext / non-HTTPS scheme; doing so would place an attacker-
      controlled or TLS-downgraded page inside the trusted console frame. The
      decision reuses the fail-closed authority validator and requires both
      URIs to be valid HTTPS targets with the **same origin** (`allowsInAppNavigation`);
      anything that leaves the origin is blocked or handed to the external
      secure browser, never silently downgraded. Verified per target before the
      flag is flipped.
      A same-origin navigation target that carries embedded credentials
      (userinfo, e.g. `https://user:pass@bmc.example/console`) is likewise
      rejected (`allowsInAppNavigation` fails closed): it would otherwise pass
      the same-origin check yet inject attacker-chosen Basic-auth credentials
      into the trusted console frame (login CSRF / credential injection) and
      present a `user@host` URL display-confusion surface. Only in-session
      navigation targets must be credential-free; the initial credentialed
      console load is a separate path and is unaffected. Verified per target
      before the flag is flipped.
* [ ] **No externally-supplied / attacker-controlled initial console URL (trusted
      entry path only)** — the WebView's initial console URL must be derived only
      from the validated user-configured BMC profile; it must never be seeded by
      an external Intent, an exported activity launched via a `DATA_URI` /
      `Intent.parseUri` / custom-scheme deep link, or a payload supplied by
      another app. No route may let an outside actor choose the first load. This
      is a distinct entry-point surface: the origin-confinement and
      arbitrary-scheme gates govern subsequent in-session navigations, and the
      initial credentialed console load is explicitly a separate path (see the
      origin-confinement box) — so an attacker who can seed that initial URL gets
      an unconfined first render and can inject credentials into an
      attacker-chosen origin, bypassing both. Console identity is
      operator-configured, but console content is served by the BMC and is
      attacker-influenced: letting an external actor pick the initial console URL
      is a phishing / credential-injection surface wholly independent of TLS,
      hostname, subresource-egress and in-session navigation checks (which govern
      the handshake, the literal authority, request destinations and subsequent
      navigations, not the trusted entry URL itself). Verified per target
      (inspect the WebView-hosting activity's exported / launch configuration and
      confirm the initial console URL comes only from the validated profile)
      before the flag is flipped.
* [ ] **No arbitrary-scheme / deep-link navigation** — the embedded WebView must
      never follow a top-level navigation to any non-HTTP(S) scheme, including
      `javascript:`, `data:`, `blob:`, `intent:`, `market:`, `tel:`, `mailto:`
      and any custom app deep-link scheme. Console content is served by the BMC
      and is therefore attacker-influenced (a compromised/spoofed BMC, or script
      running in the page): an attacker-chosen link or `window.open` using
      `intent:` / a custom scheme can hand off to and launch another installed
      app (or the OS dialer/mailer), while a `javascript:` or `data:` URL can
      execute or inject script inside the trusted console frame — an app-launch
      / script-injection abuse surface wholly independent of TLS, hostname and
      same-origin checks. The WebView navigation callback must allow only
      same-origin HTTPS navigations in-app (see the origin-confinement box) and
      hand every other scheme to the external secure browser or block it; no
      scheme may be passed through to another app, the OS, or the page's script
      context. The pure decision layer already fails closed here
      (`allowsInAppNavigation` rejects any URI whose scheme is not HTTPS), but
      the per-target WebView navigation callback must still be inspected to
      confirm no scheme is passed through. Verified per target before the flag
      is flipped.
* [ ] **No pop-up / secondary window / iframe navigation bypass** — the embedded
      WebView must not let attacker-influenced console content escape the trusted
      frame through a secondary rendering surface: no pop-ups or multiple windows
      (`window.open`, `target="_blank"`, Android
      `setSupportMultipleWindows(true)` / `onCreateWindow`, WKWebView
      `createWebViewWithConfiguration` / `window.open` handlers), no additional
      WebView/frame instance, and no cross-origin `iframe` navigation — each of
      which creates a frame whose top-level navigations may bypass the single
      navigation delegate that enforces the same-origin HTTPS confinement on the
      primary frame. Every such navigation must be blocked or handed to the
      external secure browser; no secondary frame may render an attacker-chosen
      or TLS-downgraded origin inside the app. Console content is served by the
      BMC and is therefore attacker-influenced (a compromised/spoofed BMC, or
      script running in the page): a `window.open` / `target="_blank"` link or a
      script can open a fresh, unconfined frame to an arbitrary origin — a
      phishing / credential-capture surface wholly independent of TLS, hostname
      and same-origin checks on the primary frame. Verified per target (inspect
      the WebView client / UIDelegate and confirm no secondary WebView is
      created, or that it applies the identical fail-closed navigation gate)
      before the flag is flipped.
* [ ] **CSP / mixed content** — the BMC console's HTTP response headers and
      page content are inspected for `Content-Security-Policy` frame rules and
      mixed-content (HTTPS page loading HTTP subresources); a console that is
      blocked by CSP framing or mixed-content must not be silently downgraded.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassMixedContentBlocking`, always
      `false`): the test-only opt-in never bypasses mixed-content blocking or
      CSP enforcement — an HTTPS console is never reloaded under a relaxed
      Content-Security-Policy and never permitted to load cleartext HTTP
      subresources, in strict mode and with the flag both off and on. The opt-in
      relaxes ONLY the test BMC's untrusted server leaf for the expected host.
      This box governs which subresources the trusted console page may load, so
      it is distinct from the server-side certificate checks (hostname
      verification, pinning, revocation, platform trust-store integrity), the
      TLS floor, HTTPS-only transport and validated-origin binding (the
      handshake, cleartext platform sockets and resolved address), and
      client-certificate validation and the strict Referrer-Policy (the client
      credential and the app's own outbound Referer header), all of which
      govern the connection and its credentials. Verified per target (inspect
      the enforced CSP and observed subresource schemes) before the flag is
      flipped.
* [ ] **No local / private-network subresource egress (SSRF / loopback / link-local
      pivot)** — the embedded WebView must not let attacker-influenced console
      content turn the in-app frame into a confused-deputy network pivot: no
      subresource request (fetch / XHR / `<img>` / `<iframe>` / WebSocket /
      font) and no WebRTC candidate or ICE gathering may reach loopback
      (`localhost`, `127.0.0.0/8`, `::1`), link-local (`169.254.0.0/16`, notably
      the `169.254.169.254` cloud-metadata endpoint) or any private network
      (`10/8`, `172.16/12`, `192.168/16`) other than the console's own approved
      origin. Console content is served by the BMC and is therefore
      attacker-influenced (a compromised/spoofed BMC, or script running in the
      page): a script could otherwise scan the BMC management network, read
      cloud-metadata credentials or probe loopback-only admin services from
      inside the trusted app — a server-side-request-forgery (SSRF) / local
      network-reconnaissance / metadata-theft surface wholly independent of TLS,
      hostname, top-level-navigation origin confinement, file access and
      device-permission checks (which govern navigation and capabilities, not
      subresource egress). This box does NOT restrict the approved console's own
      top-level URL: a BMC on a private address remains a valid launch target.
      On every target the WebView must block or intercept such subresource
      requests (Android `WebViewClient.shouldInterceptRequest` /
      network-security config, WKWebView content-blocking rules / `URLSession`
      configuration, WebRTC local-IP disclosure disabled) and let only the
      approved console origin's own subresources through. Verified per target
      (inspect the WebView request-interception / content-blocking configuration
      and observed subresource destinations) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassPrivateNetworkEgressProtection`,
      always `false`): the test-only opt-in never bypasses private-network egress
      protection — the console WebView never lets a subresource request (fetch /
      XHR / image / iframe / WebSocket / font / WebRTC candidate) reach loopback,
      link-local (including the 169.254.169.254 cloud-metadata endpoint) or any
      private network other than the approved console origin, in strict mode and
      with the flag both off and on. The opt-in relaxes ONLY the test BMC's
      untrusted server leaf for the expected host; it must never add a loopback /
      link-local / private-network exception just to make a console render or to
      debug it. This box governs the NETWORK DESTINATIONS that console subresource
      requests may reach, so it is distinct from CSP / mixed-content enforcement
      (which schemes / resource types the page may load), validated-origin binding
      (the resolved address of the validated TOP-LEVEL origin at connect time),
      the TLS floor and HTTPS-only transport (the handshake and cleartext sockets),
      hostname verification / pinning / revocation / trust-store integrity /
      client-certificate validation (certificate identity, key, status, device
      anchors and the client credential), the strict Referrer-Policy (the app's
      own outbound Referer header), sensitive URL / token log redaction
      (diagnostic output), sensitive data at rest (on-disk persistence / screen
      capture) and native bridge isolation (code injected into the page). Verified
      per target before the flag is flipped.
* [ ] **No referrer / URL-token leakage (strict Referrer-Policy)** — the embedded
      WebView must not leak the console URI — which may embed session tokens,
      credentials or BMC identity in its path, query or userinfo — to any other
      origin: no `Referer` header carrying the console URL may be sent when the
      attacker-influenced console page loads third-party subresources or performs
      a navigation. The console must be loaded under a strict referrer policy
      (`Referrer-Policy: no-referrer`, or at minimum `same-origin`), set through
      the response header / `<meta>` and the WebView's referrer-policy setting
      (Android `WebSettings.setReferrerPolicy`, WKWebView configuration), so no
      cross-origin request receives the console URL. Console content is served
      by the BMC and is therefore attacker-influenced (a compromised/spoofed BMC,
      or script running in the page): a leaked `Referer` can hand a session token
      or BMC endpoint to an attacker-controlled third party — a credential /
      data-leak surface wholly independent of TLS, hostname, origin, native-bridge,
      file-access, device-permission and data-at-rest checks. Verified per target
      (inspect the referrer-policy configuration and observed request headers)
      before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassStrictReferrerPolicy`, always
      `false`): the test-only opt-in never bypasses the strict referrer policy —
      the console's privileged URL / session token is never emitted in a
      cross-origin `Referer` header, in strict mode and with the flag both off and
      on. The opt-in relaxes ONLY the test BMC's untrusted server leaf for the
      expected host; it never weakens the referrer policy. This box governs the
      app's own outbound `Referer` header content, so it is distinct from the
      server-side certificate checks (hostname verification, pinning, revocation,
      platform trust-store integrity), the TLS floor, HTTPS-only transport and
      validated-origin binding (the handshake, cleartext sockets and resolved
      address), and client-certificate validation (the client credential), all of
      which govern the connection and its credentials. Verified per target before
      the flag is flipped.
* [ ] **Fullscreen** — the console can enter/exit fullscreen without leaving the
      app or losing the secure context.
* [ ] **Keyboard / pointer input forwarding** — keyboard and mouse input are
      forwarded to the remote console and cannot leak to the host page or trigger
      navigation to a different origin.
* [ ] **No native bridge / script-injection surface** — the embedded WebView must
      not inject any native JavaScript bridge or message handler
      (`addJavascriptInterface`, `WKScriptMessageHandler`,
      `WebMessageListener`/`addWebMessageListener`, `WebMessageChannel`, ...) into
      the remote BMC console page, and must expose no app-controlled `window.*`
      bridge object to it. Console content is served by the BMC and is therefore
      attacker-influenced (a compromised/spoofed BMC, or script running in the
      page): any exposed native bridge is a remote-code-execution path from that
      content into the host app, independent of TLS/origin checks. The console
      must run with **no injected interfaces**.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassNativeBridgeIsolation`, always
      `false`): the test-only opt-in never bypasses native bridge isolation — the
      console WebView never injects a native JavaScript bridge / message handler
      and never exposes an app-controlled `window.*` object to attacker-influenced
      console content, in strict mode and with the flag both off and on. The opt-in
      relaxes ONLY the test BMC's untrusted server leaf for the expected host; it
      must never add a bridge or message handler just to make a console render or
      to debug it. This box governs the code-execution surface exposed to the
      remote page, so it is distinct from every server-side certificate check
      (hostname verification, pinning, revocation, platform trust-store
      integrity), the TLS floor, HTTPS-only transport and validated-origin
      binding (the handshake, cleartext sockets and resolved address),
      client-certificate validation (the client credential), the strict
      Referrer-Policy (the app's outbound `Referer` header), CSP / mixed-content
      enforcement (which subresources the page may load), sensitive URL / token
      log redaction (the app's diagnostic output) and sensitive data at rest
      (on-disk persistence and screen capture) — those govern the connection,
      its credentials, its requests or its other outputs, not native code
      injected into the page. Verified per target (inspect the WebView controller
      construction) before the flag is flipped.
* [ ] **No local file / content-provider access** — the embedded WebView must not
      enable local file or content access: no
      `setAllowFileAccess(true)` / `setAllowContentAccess(true)` /
      `setAllowFileAccessFromFileURLs(true)` /
      `setAllowUniversalAccessFromFileURLs(true)` on Android `WebSettings`, no
      WKWebView `loadFileURL` / local file loading or file-read entitlement on
      iOS/macOS, and no load of or navigation to a `file://` / `content://` URL
      (whether by the initial load, a redirect, a link or script). Console
      content is served by the BMC and is attacker-influenced (a compromised or
      spoofed BMC, or script running in the page): with local/content access a
      console script could read app-private data or local files and exfiltrate
      them — a data-theft / remote-code-execution-class surface that is wholly
      independent of TLS, hostname and origin checks. The console WebView runs
      with local file and content access **disabled**, and file-scheme
      navigation is blocked, on every target. Verified per target (inspect the
      WebView controller construction and scheme-navigation callback) before the
      flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassLocalFileAccess`, always
      `false`): the test-only opt-in never bypasses local file / content-provider
      access — local/content access stays disabled and every `file://` /
      `content://` load or navigation stays blocked, in strict mode and with the
      flag both off and on. The opt-in relaxes ONLY the test BMC's untrusted
      server leaf for the expected host; it must never flip
      `setAllowFileAccess` / `setAllowContentAccess` /
      `setAllowFileAccessFromFileURLs` / `setAllowUniversalAccessFromFileURLs`
      or load a local/content URL just to make a console render or to debug it.
      This box governs the host files / content providers the remote page may
      READ, so it is distinct from every server-side certificate check
      (hostname verification, pinning, revocation, platform trust-store
      integrity), the TLS floor, HTTPS-only transport and validated-origin
      binding (the handshake, cleartext sockets and resolved address),
      client-certificate validation (the client credential), the strict
      Referrer-Policy (the app's outbound `Referer` header), CSP /
      mixed-content enforcement (which subresources the page may load),
      sensitive URL / token log redaction and sensitive data at rest (the
      app's diagnostic output and on-disk persistence), native bridge
      isolation (code injected into the page), private-network egress
      protection (the destinations of subresource requests), cross-site cookie
      isolation (session-cookie attachment / script readability), WebView
      remote debugging (the debug / inspect surface), device-capability /
      permission access (host capabilities granted to page content) and
      HTTP-auth / login-form challenge denial (the native
      authentication-challenge path): those govern the connection, its
      credentials, its requests, its outputs or host capabilities, not local
      file/content reads by the remote page. Verified per target before the
      flag is flipped.
* [ ] **No dangerous device-capability / permission access** — the embedded
      WebView must not grant the remote BMC console page access to device
      capabilities or native permission prompts: no geolocation
      (`setGeolocationEnabled(true)`, WKWebView/WebKit location entitlement), no
      camera / microphone capture (`onPermissionRequest`, `getUserMedia`,
      camera/mic entitlements), no notifications, vibration, clipboard read,
      Bluetooth/NFC or file-download capability, and no auto-granting of any
      Android runtime permission or WebKit permission to attacker-influenced
      console content. Console content is served by the BMC and is therefore
      attacker-influenced (a compromised/spoofed BMC, or script running in the
      page): any granted device capability is a privacy / remote-code-execution-
      class escalation from that content into the host device, wholly
      independent of TLS, hostname, origin, native-bridge and file-access
      checks. The console WebView runs with all such capabilities **denied by
      default** and permission requests **rejected by default** on every target
      (inspect the WebView configuration and `WebChromeClient` / permission
      callbacks) before the flag is flipped. Verified per target.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassDevicePermissionControls`,
      always `false`): the test-only opt-in never bypasses device-capability /
      permission access — every device capability (geolocation, camera,
      microphone, clipboard, notifications, Bluetooth/NFC, downloads) stays
      denied by default and every permission request is rejected by default, in
      strict mode and with the flag both off and on. The opt-in relaxes ONLY the
      test BMC's untrusted server leaf for the expected host; it must never grant
      a device capability or auto-answer a permission prompt just to make a
      console render or to debug it. This box governs the host-device
      capabilities exposed to page content, so it is distinct from every
      server-side certificate check (hostname verification, pinning, revocation,
      platform trust-store integrity), the TLS floor, HTTPS-only transport and
      validated-origin binding (the handshake, cleartext sockets and resolved
      address), client-certificate validation (the client credential), the strict
      Referrer-Policy (the app's outbound Referer header), CSP / mixed-content
      enforcement (which subresources the page may load), sensitive URL / token
      log redaction (diagnostic output), sensitive data at rest (on-disk
      persistence and screen capture), native bridge isolation (code injected
      into the page), private-network egress protection (the destinations of
      subresource requests), cross-site cookie isolation (the session cookie's
      attachment / script readability) and WebView remote debugging (the debug /
      inspect surface): those govern the connection, its credentials, its
      requests, its other outputs or the WebView's own debug surface, not the
      device capabilities granted to page content. Verified per target before the
      flag is flipped.
* [ ] **No sensitive data at rest (WebView cache / storage / background snapshot)** —
      the embedded WebView must not persist the remote BMC console's sensitive
      content (operator credentials, session cookies/tokens, KVM screen frames,
      managed-host inventory) to disk or expose it to other apps: no on-device
      HTTP/disk **WebView cache** of console responses, no DOM local/session
      storage or IndexedDB retention beyond the session, no `setDatabaseEnabled`
      / `setDomStorageEnabled` persistence, no WebView cookie jar shared with or
      readable by the system browser for the console origin, and no autofill /
      password-manager saving of console credentials. On Android the hosting
      activity/window must set `FLAG_SECURE` so the OS **background snapshot** /
      recent-apps thumbnail cannot capture console frames, and no native or
      third-party overlay may render the secure surface. Console content is
      served by the BMC and is attacker-influenced, but above all it is the
      operator's privileged management session: any on-device **data at rest**
      or snapshot of it is a local data-theft / shoulder-surfing surface wholly
      independent of TLS, hostname, origin, native-bridge, file-access and
      device-permission checks. The console WebView runs with cache/storage
      persistence disabled and secure (non-capturable) presentation on every
      target. Verified per target (inspect the WebView configuration and the
      hosting activity/window flags) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassSensitiveDataAtRestProtection`,
      always `false`): the test-only opt-in never bypasses sensitive data at rest
      protection — it never persists the privileged console's cache/storage to
      disk and never exposes an unprotected background snapshot — in strict mode
      and with the flag both off and on. The opt-in relaxes ONLY the test BMC's
      untrusted server leaf for the expected host; it must never disable cache /
      storage isolation or clear `FLAG_SECURE` (or its iOS/macOS equivalent) just
      to make a console render or to debug it. This box governs the app's own
      local persistence and screen-capture surface, so it is distinct from the
      server-side certificate checks (hostname verification, pinning,
      revocation, platform trust-store integrity), the TLS floor, HTTPS-only
      transport and validated-origin binding (the handshake, cleartext sockets
      and resolved address), client-certificate validation (the client
      credential), the strict Referrer-Policy (the app's own outbound `Referer`
      header), CSP / mixed-content enforcement (which subresources the page may
      load) and sensitive console URL / session-token log redaction (the app's
      diagnostic / telemetry output) — all of which govern the connection, its
      credentials, its requests or its other local outputs, not on-disk
      persistence or screen capture. Verified per target before the flag is
      flipped.
* [ ] **No remote debugging / WebView inspectability (no active debug code in
      production)** — the embedded WebView must not be remotely debuggable or
      inspectable in production: no `WebView.setWebContentsDebuggingEnabled(true)`
      on Android, no WKWebView `isInspectable = true` / web-inspector entitlement
      on iOS/macOS, and no DevTools / `webkit.Debugger` / remote-debugging
      endpoint or port exposed to ADB, another app or a nearby device
      (CWE-489: active debug code). Console content is served by the BMC and is
      attacker-influenced, but above all it is the operator's privileged
      management session: a remotely debuggable WebView lets an attacker with
      ADB/local access, or a malicious app on the same device, attach a debugger,
      read the DOM, inject script and exfiltrate session tokens, credentials and
      KVM frames — a credential/session-theft surface wholly independent of TLS,
      hostname, origin, native-bridge, file-access and data-at-rest checks. Web
      contents debugging and inspectability must be **disabled in production**
      on every target and enabled only for a test-only validation spike behind
      the opt-in flag. Verified per target (inspect the WebView construction and
      platform configuration for any debugging/inspectable flag or debugging
      port) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassWebViewRemoteDebugging`,
      always `false`): the test-only opt-in never bypasses WebView remote
      debugging / inspectability — web-contents debugging stays disabled and no
      DevTools / inspect endpoint is exposed in production, in strict mode and
      with the flag both off and on. The opt-in relaxes ONLY the test BMC's
      untrusted server leaf for the expected host; it must never turn on remote
      debugging or inspectability, nor expose a debugging port, just to make a
      console render or to debug it. This box governs the debug / inspect surface
      of the WebView itself, so it is distinct from every server-side certificate
      check (hostname verification, pinning, revocation, platform trust-store
      integrity), the TLS floor, HTTPS-only transport and validated-origin
      binding (the handshake, cleartext sockets and resolved address),
      client-certificate validation (the client credential), the strict
      Referrer-Policy (the app's outbound Referer header), CSP / mixed-content
      enforcement (which subresources the page may load), sensitive URL / token
      log redaction (diagnostic output), sensitive data at rest (on-disk
      persistence and screen capture), native bridge isolation (code injected
      into the page), private-network egress protection (the destinations of
      subresource requests) and cross-site cookie isolation (the session cookie's
      attachment / script readability): those govern the connection, its
      credentials, its requests or its other outputs, not the WebView's own
      remote-debugging / inspectability surface. Verified per target before the
      flag is flipped.
* [ ] **No service worker / persistent background script (session-scoped
      execution only)** — the embedded WebView must not let attacker-influenced
      console content install a Service Worker or any persistent background
      script that outlives the page or session: no
      `navigator.serviceWorker.register(...)`, no background sync / periodic
      background sync, no push subscription and no persistent `Cache Storage` /
      Cache API entries beyond the session. A Service Worker runs independently
      of the page, survives navigation and restarts, and can intercept/modify
      every request for the console origin — a request-interception /
      background-persistence surface — so a compromised or spoofed BMC page could
      install one that keeps running after the operator closes the console,
      silently intercepting console traffic or exfiltrating KVM frames and
      session tokens in the background. This is wholly independent of TLS,
      hostname, origin-navigation, native-bridge, file-access and
      device-permission checks. The console WebView must disallow Service Worker
      registration, unregister any existing registrations and clear Cache
      Storage at session teardown, and grant no background execution on every
      target. Verified per target (inspect the WebView configuration / settings,
      confirm Service Workers are disabled and cleared at teardown) before the
      flag is flipped.
      Hard configuration-independent invariant: the console WebView never
      bypasses service worker registration — no policy configuration (not even
      the test-only self-signed opt-in) may let attacker-influenced console
      content register a Service Worker or a persistent background script that
      outlives the page or session. The `KvmWebViewPolicy`
      `bypassServiceWorkerRegistration` getter is always `false`, so a future
      WebView consumer can consult it and can never relax this control. This is
      distinct from webview remote debugging and data at rest: those govern the
      debug / inspect surface and on-disk persistence, not persistent background
      script execution inside the page. Tolerating the test BMC's untrusted
      server leaf relaxes ONLY that leaf's trust for the expected host; it must
      never allow a service worker registration just to make a console render or
      to debug it. Verified per target before the flag is flipped.
* [ ] **No JavaScript dialog / modal spoofing (alert / confirm / prompt /
      beforeunload)** — the embedded WebView must not let attacker-influenced
      console content present spoofed or blocking native-style modals: no
      unlabelled `alert()` / `confirm()` / `prompt()` dialogs (Android
      `WebChromeClient.onJsAlert` / `onJsConfirm` / `onJsPrompt`, WKWebView
      `runJavaScriptAlertPanelWithMessage` / `runJavaScriptConfirmPanelWithMessage`
      / `runJavaScriptTextInputPanelWithPrompt`) and no `beforeunload` handler
      that traps the operator or blocks closing/navigating the console. Console
      content is served by the BMC and is therefore attacker-influenced (a
      compromised/spoofed BMC, or script running in the page): an unlabelled JS
      dialog can imitate an OS or app credential/system prompt and trick the
      operator into disclosing credentials, while a `beforeunload` loop can pin
      the console frame and block teardown — a UI-spoofing / denial-of-control
      surface wholly independent of TLS, hostname, origin, native-bridge,
      file-access and device-permission checks. Every JavaScript dialog must be
      suppressed or clearly attributed to the untrusted console origin, and
      `beforeunload` must never block teardown, on every target. Verified per
      target (inspect the WebView client / UIDelegate dialog callbacks and
      confirm dialogs are denied or labelled and `beforeunload` is
      non-blocking) before the flag is flipped.
      Hard configuration-independent invariant: the console WebView never
      bypasses JavaScript dialog denial — no policy configuration (not even the
      test-only self-signed opt-in) may permit an unlabelled JavaScript dialog
      or a blocking `beforeunload`. The `KvmWebViewPolicy`
      `bypassJavaScriptDialogDenial` getter is always `false`, so a future
      WebView consumer can consult it and can never relax this control. This is
      distinct from tapjacking / UI-overlay / clickjacking input hijack
      (obscured-window touches and overlays covering the console) and from
      native bridge, local file and device-capability checks: those govern
      input delivery, injected code, local reads or host capabilities, not a
      modal raised by the untrusted page. Tolerating the test BMC's untrusted
      server leaf relaxes ONLY that leaf's trust for the expected host; it must
      never allow an unlabelled JavaScript dialog just to make a console render
      or to debug it. Verified per target before the flag is flipped.
* [ ] **No cross-origin form submission / data exfiltration** — the embedded
      WebView must not let attacker-influenced console content exfiltrate
      operator credentials, session tokens or KVM frame data through an HTML
      form: no `<form action>` (GET query or POST body) targeting any origin
      other than the approved same-origin HTTPS console, no auto-submit-on-load
      or scripted `form.submit()` that silently sends console DOM data to an
      attacker origin, and no browser autofill of saved console credentials
      into an attacker-controlled form. Console content is served by the BMC
      and is therefore attacker-influenced (a compromised/spoofed BMC, or
      script running in the page): a form is a distinct navigation and data
      channel from a link or scripted top-level navigation — a form submission
      with `POST` carries a body that can smuggle session tokens or KVM frames
      out of the trusted frame without any visible URL change — and the
      origin-confinement and subresource-egress boxes govern navigation and
      subresource fetches, not form submissions or their request bodies. Every
      form submission must be blocked or handed to the external secure browser
      unless its action is the same-origin HTTPS console, and form autofill of
      console credentials must be disabled, on every target. Verified per
      target (inspect the WebView form/navigation callback, confirm cross-origin
      form submissions and their POST bodies are blocked and autofill is off)
      before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassCrossOriginFormSubmission`,
      always `false`): the test-only opt-in never bypasses cross-origin form
      submission — every HTML form submission is confined to the approved
      same-origin HTTPS console, no auto-submit or scripted `form.submit()` may
      send console DOM data to a non-approved origin and form autofill of
      console credentials stays disabled, in strict mode and with the flag both
      off and on. The opt-in relaxes ONLY the test BMC's untrusted server leaf
      for the expected host; it must never allow a `<form action>` POST body to
      smuggle session tokens or KVM frames out of the trusted frame just to make
      a console render or to debug it. This box governs the form-submission /
      POST-body data channel, so it is distinct from origin / navigation
      confinement (where the top-level frame may go), the outbound egress
      allowlist (the destinations of the page's programmatic connections) and
      private-network egress protection (the address class of subresources) —
      those govern other navigation or request surfaces, not HTML form
      submissions or their request bodies. It is also distinct from the strict
      Referrer-Policy and log redaction (the app's own URL header and diagnostic
      output) and every server-side certificate / TLS / transport check: those
      govern the connection, its credentials and its other outputs, not the
      form POST path. Verified per target before the flag is flipped.
* [ ] **No arbitrary / drive-by file download (malicious APK / executable /
      payload-in-a-file install)** — the embedded WebView must not let
      attacker-influenced console content trigger a file download that escapes
      the trusted frame or lands a runnable file on the device: no
      arbitrary file download via an `<a download>` attribute, a scripted
      `window.location` assignment, a redirect, or a
      `Content-Disposition: attachment` response; no auto-open of a downloaded
      file (Android `DownloadManager` / `setDownloadListener` handing a
      `.apk` / `.exe` / `.dmg` / `.sh` to an `ACTION_INSTALL_PACKAGE` intent or
      a launcher) and no auto-install, and no console-controlled download
      destination or filename. Console content is served by the BMC and is
      therefore attacker-influenced (a compromised/spoofed BMC, or script
      running in the page): a drive-by download is a distinct response / intent
      channel from a link's top-level navigation, a subresource fetch and a
      form POST — the origin-confinement, subresource-egress and
      form-submission boxes govern those, not downloads — so an attacker-chosen
      APK or executable delivered through the trusted console frame and then
      opened is a code-execution / malware-installation surface wholly
      independent of TLS, hostname, origin, native-bridge, file-access and
      device-permission checks. Every download must be blocked at the WebView
      (`setDownloadListener` that cancels and, at most, hands the HTTPS URI to
      the external secure browser) with no auto-open, no auto-install and no
      console-controlled destination, on every target. Verified per target
      (inspect the WebView download listener / navigation-response callbacks
      and confirm downloads are blocked and nothing is auto-opened) before the
      flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassArbitraryFileDownload`,
      always `false`): the test-only opt-in never bypasses arbitrary / drive-by
      file download — every download is blocked at the WebView with no auto-open,
      no auto-install and no console-controlled destination or filename, in
      strict mode and with the flag both off and on. The opt-in relaxes ONLY the
      test BMC's untrusted server leaf for the expected host; it must never allow
      an `<a download>`, a `Content-Disposition: attachment` response, a
      scripted download or a drive-by APK / executable install just to make a
      console render or to debug it. This box governs the download / intent
      channel, so it is distinct from top-level navigation confinement (where
      the frame may go), the outbound egress allowlist (destinations of
      programmatic connections), cross-origin form submission (the form POST
      body), CSP / mixed-content enforcement (which subresources the page may
      load) and local file / content access (local file reads): those govern
      navigation, requests or local reads, not a file written to the device.
      Verified per target before the flag is flipped.
* [ ] **No autofill / password-manager credential capture (autofill is denied by
      default)** — the embedded WebView must never let attacker-influenced console content
      or a platform autofill / password-manager service capture, save, persist or re-inject
      the operator's BMC credentials through the console login form: no password-manager
      saving of typed BMC username/password or session token, no `Android Autofill` /
      `AutofillManager` / `setImportantForAutofill` / iOS `AutoFill` / `textContentType`
      credential capture or `Secure/HttpOnly` value export, no pre-seeding of saved
      credentials into an attacker-influenced or spoofed login form, and no autofill
      suggestion that one origin can read from another. Autofill is denied by default on
      every target (e.g. `IMPORTANT_FOR_AUTOFILL_NO` / `NO_EXCLUDES_DESCENDANTS`,
      `isAutofillEnabled = false`, no autofill `AccessibilityService`, no credential
      provider bound to the console): there is no password manager saving of console
      credentials and no pre-seed / injection of saved credentials into the privileged
      form. The console is an operator management session and the page content is
      attacker-influenced (a compromised/spoofed BMC or script in the page): a credential
      autofill channel can silently exfiltrate the BMC login on form submit or auto-fill a
      spoofed form, so it is closed on every target in strict mode and with the flag both
      off and on.
      This is a hard, configuration-independent invariant that a future WebView consumer
      can consult (`KvmWebViewPolicy.bypassAutofillCredentialCapture`, always `false`):
      the opt-in never bypasses autofill / password-manager credential capture — it never
      enables password-manager saving of console credentials, never pre-seeds saved
      credentials into a form and never turns on autofill just to make a console render or
      to debug it: the opt-in never enables autofill for the privileged console. The
      opt-in relaxes ONLY the test BMC's untrusted server leaf for the
      expected host, via a scoped per-connection verifier; it never relaxes this autofill
      control. This box governs the credential autofill / password-manager channel, so it
      is distinct from HTTP-auth / login-form challenge denial (the native
      authentication-challenge dialog and its stored credentials — distinct from
      http-auth stored credentials and WebStorage autocomplete), cross-site cookie /
      session-token isolation (session-cookie attachment and script readability),
      cross-origin form submission (the form POST body channel), sensitive data at rest
      (on-disk persistence and screen capture) and outbound egress / form POST rules
      (request destinations): those govern the challenge dialog, cookies, the POST body,
      storage or destinations, not the browser/password-manager autofill of credential
      fields. Verified per target (inspect the WebView autofill configuration and confirm
      no credential can be saved, suggested or pre-seeded) before the flag is flipped.
* [ ] **No cross-site cookie / session-token leakage (SameSite + third-party-cookie
      blocking + Secure/HttpOnly scoping)** — the embedded WebView must not let
      attacker-influenced console content leak the operator's BMC session cookie/token to
      another origin through cookie attachment or script reads: no `SameSite=None` console
      session cookie that is attached to cross-site subresource requests, no third-party
      cookie sharing with attacker-controlled origins, and no script-readable session cookie
      (no `HttpOnly`) that `document.cookie` exfiltration can steal. Cookies for the console
      origin must be `Secure` + `HttpOnly` + `SameSite`-scoped, third-party cookies must be
      blocked, and the WebView cookie store must be isolated from the system browser.
      Console content is served by the BMC and is therefore attacker-influenced (a
      compromised/spoofed BMC, or script running in the page): a scripted cross-origin
      subresource request would otherwise attach the BMC session cookie, or page script could
      read `document.cookie` and exfiltrate it — a session-theft / account-takeover surface
      wholly independent of TLS, hostname, origin-confinement, referrer, subresource-egress
      and data-at-rest checks (which govern navigation, URL headers, request destinations and
      on-disk persistence, not cookie attachment semantics or script readability). Verified
      per target (inspect the WebView cookie manager / SameSite handling and confirm session
      cookies are Secure/HttpOnly/SameSite-scoped and third-party cookies are blocked) before
      the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassCookieIsolation`, always
      `false`): the test-only opt-in never bypasses cross-site cookie / session-token
      isolation — console session cookies stay `Secure` + `HttpOnly` + `SameSite`-scoped,
      third-party cookies stay blocked and the WebView cookie store stays isolated from the
      system browser, so an attacker-influenced console page can neither attach the BMC
      session cookie to a cross-site request nor read it via `document.cookie`, in strict
      mode and with the flag both off and on. The opt-in relaxes ONLY the test BMC's
      untrusted server leaf for the expected host; it must never relax cookie scoping,
      never permit third-party cookies or script-readable session cookies, and never share
      the console cookie jar with the system browser just to make a console render or to
      debug it. This box governs cookie-attachment and script-readability semantics for
      the console session, so it is distinct from the strict Referrer-Policy (the app's
      own outbound `Referer` header), sensitive URL / token log redaction (diagnostic /
      telemetry output), sensitive data at rest (on-disk persistence / screen capture),
      CSP / mixed-content enforcement (which subresources the page may load),
      private-network egress protection (the network destinations of subresource
      requests), native bridge isolation (code injected into the page), client-certificate
      validation (the client TLS credential), and every server-side certificate / TLS /
      transport check (certificate identity, key, status, device anchors, handshake
      strength, cleartext sockets and the validated resolved address): those govern the
      connection, its credentials, its requests or its other outputs, not cookie
      attachment or script readability. Verified per target before the flag is flipped.
* [ ] **No tapjacking / UI-overlay / clickjacking (obscured-window touch, CWE-1021)** —
      the embedded WebView must not let an attacker-influenced console page or a
      malicious co-resident app hijack the operator's input through a UI-overlay / tapjacking /
      clickjacking layer: no touch delivered through an obscured window may reach the console
      (Android `filterTouchesWhenObscured="true"` / `setFilterTouchesWhenObscured(true)` and
      rejection of touches carrying `MotionEvent.FLAG_WINDOW_IS_OBSCURED`), no transparent or
      `SYSTEM_ALERT_WINDOW` / `TYPE_APPLICATION_OVERLAY` window may be drawn over the secure
      console surface, and on iOS/macOS no overlay view may sit above the WebView. Console
      content is served by the BMC and is attacker-influenced, but above all it is the
      operator's privileged management session: an invisible overlay can capture taps on
      credential fields, confirm destructive KVM actions or approve prompts on the operator's
      behalf — a UI-redressing / input-hijack surface wholly independent of TLS, hostname,
      origin, native-bridge, file-access, JS-dialog and data-at-rest checks (which govern
      transport, navigation, capabilities, modals and storage, not obscured-window input).
      The console WebView rejects obscured-window touches and disallows overlays on every
      target. Verified per target (inspect the WebView / host-activity touch filtering and
      window flags, and confirm no overlay can cover the secure surface) before the flag is
      flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassTapjackingProtection`, always
      `false`): the test-only opt-in never bypasses tapjacking / UI-overlay /
      clickjacking protection — the console WebView rejects obscured-window
      touches and disallows overlays in strict mode and with the flag both off
      and on. The opt-in relaxes ONLY the test BMC's untrusted server leaf for
      the expected host (via a scoped per-connection verifier); it must never
      disable touch filtering, never accept an obscured-window touch, and never
      allow a UI overlay over the secure console surface just to make a console
      render or to debug it. This box governs operator input delivery to the
      privileged console, so it is distinct from JavaScript dialog / modal
      spoofing (which governs untrusted modals raised by the page), native
      bridge isolation, local file access, device capabilities, data at rest
      and log redaction: those govern other page or app surfaces, not
      obscured-window touch / overlay input hijack. Verified per target before
      the flag is flipped.
* [ ] **No sensitive console URL / session token in logs, telemetry or crash
      reports (CWE-532)** — the WebView-hosting layer and the app's launch / fallback
      code must never write the console URI — or any session token, credential or BMC
      identity embedded in its userinfo, path or query — to logs or diagnostics
      (Android `Logcat`, `NSLog` / `os_log`, Flutter `debugPrint`), nor embed it in
      analytics events, crash reports / breadcrumbs or any other telemetry sink. The
      console URI is the operator's privileged management-session handle and may carry a
      token in its query or userinfo; capturing such a URL in a log line or crash report
      leaves a durable, exfiltratable copy of that handle on the device or in a third-party
      sink — a sensitive-information-in-logs / -telemetry surface (CWE-532) wholly
      independent of TLS, hostname, origin-confinement, referrer, cookie, subresource-egress
      and data-at-rest checks (which govern the handshake, the literal authority,
      navigation, URL headers, cookie attachment, request destinations and on-disk
      persistence, not the app's own diagnostic / telemetry output). Every console URI and
      every token derived from it must be redacted from logs, analytics and crash reports on
      every target. Verified per target (inspect the WebView load / error callbacks and the
      app's logging and telemetry configuration, and confirm no console URL or token is
      emitted) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassLogRedaction`, always `false`):
      the test-only opt-in never bypasses sensitive console URL / session-token log
      redaction — it never emits the privileged console URL or any token derived
      from it to logs, telemetry or crash reports (CWE-532), in strict mode and with
      the flag both off and on. The opt-in relaxes ONLY the test BMC's untrusted
      server leaf for the expected host. This box governs the app's own local
      diagnostic / telemetry output, so it is distinct from the strict Referrer-Policy
      (the app's own outbound Referer header), CSP / mixed-content enforcement (which
      subresources the console page may load), every server-side certificate check
      (hostname verification, pinning, revocation, platform trust-store integrity),
      the TLS floor, HTTPS-only transport and validated-origin binding (the handshake,
      cleartext platform sockets and resolved address), and client-certificate
      validation (the client credential), all of which govern the connection, its
      credentials or its requests. Verified per target (inspect the WebView load /
      error callbacks and the app's logging and telemetry configuration) before the
      flag is flipped.
* [ ] **Operator-session auto-lock / session timeout (no unattended privileged
      console)** — the embedded WebView must not leave the operator's privileged
      BMC/KVM session live and visible when the operator walks away: a bounded
      session timeout must auto-lock the console after idle, and the session must
      lock immediately on backgrounding / app minimize (Android `onPause` / `onStop`,
      iOS `applicationDidEnterBackground`), requiring re-authentication before the
      console is shown again, and be torn down at teardown. An unattended, still-live
      console exposes KVM frames, credentials and privileged management actions to
      any shoulder-surfer or co-resident app that resumes the task — a session-
      exposure / local-privilege surface wholly independent of TLS, hostname,
      origin-navigation, native-bridge, file-access and data-at-rest checks (which
      govern the handshake, the authority, navigation, capabilities, files and on-disk
      persistence, not the LIVE session's idle/background lifecycle). Console content
      is served by the BMC and is attacker-influenced, but above all it is the
      operator's privileged management session: it must lock on idle and on
      backgrounding and require re-authentication to resume, on every target.
      Verified per target (inspect the WebView host's lifecycle callbacks and confirm
      the live session auto-locks on idle and on backgrounding and that
      re-authentication is required before the console is shown) before the flag is
      flipped.
* [ ] **No HTTP-auth / login-form credential-prompt spoofing (native
      authentication-challenge dialog, auto-submitted credentials)** — the
      embedded WebView must not let attacker-influenced console content — or a
      cross-origin subresource returning 401 — induce the operator to enter BMC
      credentials into a spoofed native authentication prompt, nor silently
      auto-answer a challenge with stored credentials for an unintended origin:
      Android `WebViewClient.onReceivedHttpAuthRequest` and
      `onReceivedLoginRequest` must `cancel()` by default (never `proceed()` or
      `useHttpAuthUsernamePassword()` on a production profile), no
      `setHttpAuthUsernamePassword` pre-seeding or `WebStorage` auto-complete of
      console credentials, and on iOS/macOS no `URLSession` / WKWebView
      authentication-challenge handler may auto-answer with saved credentials or
      present an unlabelled challenge dialog for the console origin. Console
      content is served by the BMC and is therefore attacker-influenced (a
      compromised/spoofed BMC, or script in the page can make a third-party
      subresource return a 401 targeting a realm whose prompt imitates the app's
      own login): a spoofed or auto-answered challenge hands operator credentials
      to an attacker or an unintended origin — a credential-phishing /
      credential-leak surface wholly independent of TLS, hostname,
      origin-confinement, referrer, cookie, JS-dialog and form-submission checks
      (which govern the handshake, the literal authority, navigation, URL
      headers, cookie attachment, page modals and form POSTs, not the platform's
      native authentication-challenge path). Every HTTP-auth / login-form
      challenge must be denied by default and never auto-answered with stored
      credentials on every target, with the flag both off and on. Verified per
      target (inspect the WebView auth callbacks and confirm challenges are
      cancelled and no credential store is pre-seeded) before the flag is
      flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassHttpAuthChallengeDenial`,
      always `false`): the test-only opt-in never bypasses http-auth / login-form
      challenge denial — every native HTTP-auth / login-form authentication
      challenge is cancelled by default and never auto-answered with stored
      credentials, and no spoofed unlabelled prompt is shown for the console
      origin, in strict mode and with the flag both off and on. The opt-in
      relaxes ONLY the test BMC's untrusted server leaf for the expected host;
      it must never present a credential-prompt spoofing surface or auto-answer
      a challenge just to make a console render or to debug it. This box governs
      the platform's native authentication-challenge path, so it is distinct
      from the JavaScript-dialog / modal-spoofing box (page `alert` / `confirm`
      / `prompt` / `beforeunload`), cross-origin form submission (form POST
      bodies), the strict Referrer-Policy (the app's outbound `Referer` header),
      cross-site cookie isolation (session-cookie attachment / script
      readability), and every server-side certificate / TLS / transport check
      (certificate identity, key, status, device anchors, handshake strength,
      cleartext sockets and the validated resolved address): those govern the
      connection, its credentials, its requests, page modals, URL headers,
      cookies or other outputs, not the native authentication-challenge path.
      Verified per target before the flag is flipped.
* [ ] **Certificate revocation checking (CRL / OCSP) never bypassed** — the
      embedded WebView must reject a certificate that has been revoked (e.g.
      because the BMC's private key was compromised) even when it still chains
      to a trusted CA, carries the expected hostname and matches the pin:
      online OCSP / CRL Distribution Points must be consulted (Android
      `RevocationMode` / `WebViewClient.onReceivedSslError` with
      `SSL_ERROR_REVOKED`, WKWebView / `URLSession` revocation policy), and the
      connection must fail closed on a revoked or unverifiable status. Console
      content is served by the BMC and is therefore attacker-influenced, but the
      revocation state is an operator/PKI trust signal, not page content: this
      is a control distinct from hostname verification (which binds the
      certificate identity to the console host), certificate/public-key pinning
      (which binds the connection to the expected key) and the TLS
      protocol/cipher floor (which governs the handshake). The test-only
      self-signed opt-in tolerates ONLY the test BMC's untrusted leaf for the
      expected host: it must never disable revocation checking for otherwise-
      trusted certificates, so a revoked BMC certificate cannot silently
      resume the privileged management session. This is a hard,
      configuration-independent invariant that a future WebView consumer can
      consult (`KvmWebViewPolicy.bypassCertificateRevocationCheck`, always
      `false`): the opt-in never skips revocation, in strict mode and with the
      flag both off and on. Verified per target (inspect the WebView TLS /
      revocation configuration and observe that a revoked certificate is
      rejected, with the flag both off and on) before the flag is flipped.
* [ ] **Platform trust-store integrity (no CA / trust-anchor addition, no global
      TLS weakening)** — the test-only self-signed opt-in must never add a CA,
      trust anchor or certificate to the platform / OS trust store, and must
      never mutate that store: no Android `NetworkSecurityConfig`
      `<certificates src="user"/>` trust-anchor addition or `KeyStore`
      mutation, no iOS / macOS custom CA installation or `SecTrust` anchor
      override, and no ATS / network-security exception that adds a trust
      anchor. Doing so would make the BMC's CA trusted for EVERY app and EVERY
      host on the device — a global weakening of production TLS, exactly what
      this spike forbids — and would let any certificate signed by that CA
      impersonate any host. The console WebView instead tolerates the test
      BMC's untrusted leaf ONLY through a scoped, per-connection certificate
      verifier bound to the expected console host; the platform trust store
      itself is untouched. This is a control distinct from hostname
      verification (identity binding), certificate/public-key pinning (key
      binding), the TLS protocol/cipher floor and HTTPS-only transport (the
      handshake and cleartext sockets), certificate revocation checking
      (certificate status) and validated-origin binding (the resolved address):
      those govern the connection, whereas this box governs the device-wide
      trust anchors themselves. This is a hard, configuration-independent
      invariant that a future WebView consumer can consult
      (`KvmWebViewPolicy.bypassPlatformTrustStoreIntegrity`, always `false`):
      the opt-in never bypasses trust-store integrity.
      The opt-in never mutates the platform trust store, in strict mode and with
      the flag both off and on. Verified per target (inspect the WebView TLS
      configuration and the host's trust-store / network-security settings, and
      confirm no CA or trust anchor is added, with the flag both off and on)
      before the flag is flipped.
* [ ] **Client-certificate (mutual TLS) validation never bypassed** — when a BMC
      console requires mutual TLS, the embedded WebView must present the
      configured client certificate and validate the connection against it; the
      client certificate's private key must remain protected and never be
      exported or exposed to page JavaScript / a native bridge. The test-only
      self-signed opt-in tolerates ONLY the test BMC's untrusted *server* leaf
      for the expected host: it must never disable client-certificate validation,
      never accept a missing, invalid or expired client certificate, and never
      expose the private key. This is a control distinct from the server-side
      certificate checks — hostname verification and pinning (identity/key of
      the BMC's server certificate), revocation (server certificate status) and
      platform trust-store integrity (device-wide anchors) — and from the TLS
      floor, HTTPS-only transport and validated-origin binding (the handshake,
      cleartext sockets and resolved address): those govern the server side and
      the transport, whereas this box governs the client credential. This is a
      hard, configuration-independent invariant that a future WebView consumer
      can consult (`KvmWebViewPolicy.bypassClientCertificateValidation`, always
      `false`): the opt-in never bypasses client-certificate validation, in
      strict mode and with the flag both off and on. Verified per target
      (inspect the WebView client-certificate / mTLS configuration and observe
      that a missing, invalid or expired client certificate is rejected and the
      private key is not exposed to page content, with the flag both off and on)
      before the flag is flipped.
* [ ] **No covert outbound egress / cross-origin data exfiltration
      (connect-src allowlist)** — the embedded WebView must confine every
      programmatic network connection the console page can initiate (fetch /
      XHR / WebSocket / WebRTC / `sendBeacon` / `EventSource` / media `src`) to
      the approved console origin, via a CSP `connect-src 'self'` allowlist plus
      WebView request interception. Console content is served by the BMC and is
      therefore attacker-influenced (a compromised/spoofed BMC, or script
      running in the page): without this allowlist a script could exfiltrate
      privileged material (KVM frames, session tokens, credentials, managed-host
      inventory) to an attacker-controlled EXTERNAL host, or hold a covert
      command-and-control channel open, wholly independent of TLS, hostname,
      top-level-navigation origin confinement, form-POST and subresource
      address-class checks. This box does NOT restrict the approved console's
      own origin even when it is a private BMC address; it restricts every
      OTHER destination origin, public or private. On every target the WebView
      must enforce `connect-src 'self'` and intercept/block any WebSocket,
      WebRTC, `sendBeacon`, `EventSource` or fetch/XHR connection to a
      non-approved origin. Verified per target (inspect the enforced CSP
      connect directive and the WebView request-interception configuration, and
      observe that a programmatic connection to an external origin is blocked)
      before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassOutboundEgressAllowlist`,
      always `false`): the test-only opt-in never bypasses the outbound egress
      allowlist — console content can never open a programmatic connection to a
      non-approved origin, in strict mode and with the flag both off and on.
      The opt-in relaxes ONLY the test BMC's untrusted server leaf for the
      expected host; it must never widen `connect-src` or add a network
      exception just to make a console render or to debug it. This box governs
      the DESTINATION ORIGIN of the page's programmatic connections, so it is
      distinct from private-network egress protection (the destination address
      class — loopback / link-local / private LAN — of subresources), CSP /
      mixed-content enforcement (framing rules and cleartext subresources),
      origin / navigation confinement (where the top-level frame may go),
      cross-origin form submission (the `<form>` POST path), the strict
      Referrer-Policy (the app's own outbound `Referer` header), sensitive URL /
      token log redaction (diagnostic output) and native bridge isolation (code
      injected into the page): those govern other connection, request or output
      surfaces, not the destinations of the page's programmatic connections.
      Verified per target before the flag is flipped.
* [ ] **No native file chooser / file-input upload exfiltration** — the embedded
      WebView must never let attacker-influenced console content open a native
      file chooser or file-input picker to select a local file for upload: no
      HTML `<input type="file">` file input, no Android
      `WebChromeClient.onShowFileChooser` / `showFileChooser` /
      `ACTION_OPEN_DOCUMENT` / `ACTION_GET_CONTENT` / camera-capture intent,
      and no WKWebView / WebKit file upload panel or file-read entitlement may
      be shown or answered for the page. Console content is served by the BMC
      and is therefore attacker-influenced (a compromised/spoofed BMC or script
      running in the page): an attacker-chosen file input can socially engineer
      the operator into selecting an on-device document, SSH key, token file or
      credential store which is then uploaded into the trusted frame and sent
      to the BMC or an attacker origin — a local-file-exfiltration surface
      wholly independent of direct `file://` reads, downloads and device
      permissions. Every file chooser / file upload request is denied by default
      on every target, in strict mode and with the flag both off and on.
      Verified per target (inspect the WebView client / UIDelegate file-chooser
      callbacks and confirm no file chooser or file upload is ever shown) before
      the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassFileChooserAccess`, always
      `false`): the test-only opt-in never bypasses file chooser / file-upload
      access — every file chooser / file input request is denied and no local
      file can be selected or uploaded, in strict mode and with the flag both
      off and on. The opt-in relaxes ONLY the test BMC's untrusted server leaf
      for the expected host (via a scoped per-connection verifier); it must
      never enable the file chooser just to make a console render or to debug
      it. This box governs the operator-mediated local-file selection / file
      upload channel, so it is distinct from local file access (the page's own
      direct `file://` / `content://` reads), arbitrary / drive-by file download
      (a file written TO the device), device capabilities, cross-origin form
      submission and the outbound egress allowlist: those govern other local
      read, write, capability or request surfaces, not a native file picker
      handing a chosen local file to the page. Verified per target before the
      flag is flipped.
* [ ] **No print / save-to-PDF / print-spooler data exfiltration** — the embedded
      WebView must not let attacker-influenced console content render the
      privileged console DOM (session tokens, credentials, KVM frames, managed
      host inventory) into a durable printed or saved-to-PDF copy: no
      `window.print()` / scripted print request, no Android `PrintManager` /
      `WebView.createPrintDocumentAdapter()` / `ACTION_PRINT` hand-off, no
      WKWebView `UIPrintInteractionController` / print renderer, and no
      auto-print or console-controlled print destination. Console content is
      served by the BMC and is therefore attacker-influenced (a compromised or
      spoofed BMC, or script running in the page): a printed / saved-to-PDF copy
      of the console DOM is a durable, exfiltratable channel that escapes the
      on-screen-only confinement — wholly independent of network downloads,
      form POST bodies and on-disk cache/storage. Every print request must be
      denied at the WebView (no print adapter exposed, print callbacks
      cancelled), with no auto-print and no console-controlled destination, on
      every target, in strict mode and with the flag both off and on. Verified
      per target (inspect the WebView print callbacks / print-adapter exposure
      and confirm a scripted `window.print()` cannot emit a PDF or spool a
      print) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassPrintExfiltration`, always
      `false`): the test-only opt-in never bypasses print / save-to-PDF
      exfiltration — no print adapter is exposed and no print request from
      attacker-influenced console content is honoured, in strict mode and with
      the flag both off and on. The opt-in relaxes ONLY the test BMC's untrusted
      server leaf for the expected host, via a scoped per-connection verifier;
      it must never enable printing just to make a console render or to debug
      it. This box is distinct from arbitrary / drive-by file download (a file
      written to the device via a network response), cross-origin form
      submission (the form POST body), sensitive data at rest (automatic
      on-disk cache/storage and background snapshot) and outbound egress
      (programmatic network connections): those govern other output surfaces,
      not a rendered print / PDF copy of the console DOM. Verified per target
      before the flag is flipped.
* [ ] **No pointer-lock / keyboard-lock / fullscreen input capture (input trap
      / UI spoof)** — the embedded WebView must not let attacker-influenced
      console content seize the operator's local input or hide the privileged
      app UI: no scripted `requestPointerLock()` / `Element.requestFullscreen()`
      / `requestKeyboardLock()` (nor the `webkit` / `moz` prefixed variants), and
      no console-content-initiated fullscreen, pointer-lock or keyboard-lock
      that traps keyboard/mouse focus, conceals the app chrome or presents a
      look-alike credential prompt. Console content is served by the BMC and is
      therefore attacker-influenced (a compromised or spoofed BMC, or script in
      the page): a page that captures the pointer/keyboard and goes fullscreen
      can obscure the trusted frame, trap operator input and spoof a system or
      BMC login dialog to harvest the operator's credentials or session token —
      a UI-spoof / input-trap surface wholly independent of JavaScript modal
      dialogs, overlay/tapjacking and device-capability prompts. Every such
      input-capture request from console content must be denied at the WebView
      (pointer/keyboard lock refused, content-initiated fullscreen refused,
      focus never hijacked), on every target, in strict mode and with the flag
      both off and on. Operator/app-initiated fullscreen of the console view is
      a separate functional path (see the Fullscreen box) and is unaffected.
      Verified per target (inspect the WebView fullscreen / pointer-lock /
      keyboard-lock callbacks and confirm console content cannot trap input or
      hide the app chrome) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassInputCaptureProtection`,
      always `false`): the test-only opt-in never bypasses input-capture
      protection — console content never seizes pointer/keyboard focus and never
      hides the app chrome to spoof a prompt, in strict mode and with the flag
      both off and on. The opt-in relaxes ONLY the test BMC's untrusted server
      leaf for the expected host, via a scoped per-connection verifier; it must
      never grant an input-capture or fullscreen request just to make a console
      render or to debug it. This box is distinct from JavaScript dialog / modal
      spoofing (`alert` / `confirm` / `prompt` / `beforeunload`), tapjacking /
      UI-overlay / clickjacking (a co-resident app drawing an obscuring overlay
      or delivering an obscured touch) and device-capability / permission
      access (host capabilities granted to page content): those govern other
      input and prompt surfaces, not content-initiated pointer/keyboard lock and
      fullscreen input capture. Verified per target before the flag is flipped.
* [ ] **No picture-in-picture / floating secondary-window escape** — the embedded
      WebView must not let attacker-influenced console content escape the secure
      console frame through a browser-native Picture-in-Picture (PiP) window or
      an equivalent floating / secondary rendering surface: no
      `requestPictureInPicture()` / `documentPictureInPicture` (nor the `webkit` /
      `moz` prefixed variants), no scripted or auto-enter PiP on a `<video>` / KVM
      frame and no browser/embedded-widget floating-video overlay. A PiP window
      renders content OUTSIDE the app's secure console surface, can float above
      other apps and outlives the console session, so attacker-influenced content
      shown there is a UI-spoof / session-persistence surface wholly independent
      of JavaScript modal dialogs, fullscreen / pointer-lock input capture,
      overlay / tapjacking and device-capability prompts (which govern in-frame
      modals, input, app overlays and host capabilities, not a browser-native
      floating window). Every such PiP / floating-window request from console
      content must be denied at the WebView (PiP refused, no secondary rendering
      surface created), on every target, in strict mode and with the flag both off
      and on. Operator/app-initiated fullscreen of the console view is a separate
      functional path (see the Fullscreen box) and is unaffected. Verified per
      target (inspect the WebView PiP / fullscreen / secondary-window callbacks
      and confirm console content cannot open a floating window) before the flag
      is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassPictureInPictureEscape`,
      always `false`): the test-only opt-in never bypasses picture-in-picture /
      floating-window escape — no browser-native PiP window is granted to
      attacker-influenced console content, it cannot float above other apps and
      it never outlives the console session, in strict mode and with the flag both
      off and on. The opt-in relaxes ONLY the test BMC's untrusted server leaf for
      the expected host, via a scoped per-connection verifier; it must never grant
      a picture-in-picture request just to make a console render or to debug it.
      This box is distinct from fullscreen input capture (`requestFullscreen` /
      `requestPointerLock` / `requestKeyboardLock`) and from tapjacking /
      UI-overlay / clickjacking (a co-resident app drawing an obscuring overlay or
      delivering an obscured touch): those govern in-frame input and app overlays,
      not a browser-native PiP / floating secondary window. Verified per target
      before the flag is flipped.
* [ ] **No Web Share / remote-cast / external-display exfiltration** — the
      embedded WebView must not let attacker-influenced console content hand
      privileged management-session data (KVM frames, session tokens, operator
      credentials, managed-host inventory) to another app, another device or an
      external display: no Web Share API (`navigator.share` /
      `navigator.canShare`), no Presentation API (`navigator.presentation` /
      `PresentationRequest`), no Remote Playback API (`HTMLMediaElement.remote`
      / `remote.prompt()`), no Google Cast / AirPlay / DLNA / UPnP receiver
      picker (`webkitShowPlaybackTargetPicker`, `cast.framework`,
      `RemotePlayback`), and no page-script-driven screen-cast / mirroring
      control. Console content is served by the BMC and is therefore
      attacker-influenced: such a channel hands the privileged session to a
      recipient outside the secure console frame and the app's network policy —
      a data-exfiltration surface wholly independent of the outbound egress
      allowlist (programmatic fetch / XHR / WebSocket / WebRTC connections),
      print / save-to-PDF (a durable paper/PDF copy) and downloads (a file on
      disk), which govern other output or request surfaces. Every such share /
      cast / external-display request from console content must be denied at the
      WebView (no share sheet, no presentation / cast session, no receiver
      picker), on every target, in strict mode and with the flag both off and
      on. Verified per target (inspect the WebView share / presentation / cast
      / media-routing callbacks and confirm console content cannot open a share
      sheet or cast receiver) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassShareCastExfiltration`,
      always `false`): the test-only opt-in never bypasses Web Share / remote-cast
      exfiltration — no privileged console data is handed to another app, device
      or external display via a share sheet or a cast / AirPlay / Presentation /
      Remote Playback receiver, in strict mode and with the flag both off and
      on. The opt-in relaxes ONLY the test BMC's untrusted server leaf for the
      expected host, via a scoped per-connection verifier; it must never grant
      a share / cast request just to make a console render or to debug it. This
      box is distinct from outbound egress allowlist (programmatic connections
      to non-approved origins), print / save-to-PDF exfiltration (a durable
      copy) and cross-origin form submission (an HTML form POST): those govern
      other request or output surfaces, not a native share sheet or a cast /
      external-display receiver. Verified per target before the flag is flipped.
* [ ] **No clipboard read / write exfiltration (system-clipboard isolation)** —
      the embedded WebView must not let attacker-influenced console content read
      or write the system clipboard: no `navigator.clipboard.writeText()` /
      `navigator.clipboard.readText()` / `ClipboardItem` write, no
      `document.execCommand('copy')` / `paste` and no auto-copy of the privileged
      console DOM (session tokens, credentials, KVM frames, managed-host
      inventory) into a clipboard that any co-resident app or OS clipboard
      history can read, and no reading of a clipboard the operator populated in
      another context. Console content is served by the BMC and is therefore
      attacker-influenced: a clipboard write hands privileged session data to
      any other app on the device, and a clipboard read captures operator
      credentials — a cross-app clipboard data channel wholly independent of
      TLS, hostname, origin/navigation confinement, outbound egress, print /
      save-to-PDF, share / cast and on-disk data-at-rest checks (which govern
      the connection, other output channels or storage, not the system
      clipboard). Every clipboard read and write must be denied by default at
      the WebView on every target, in strict mode and with the flag both off and
      on. Verified per target (inspect the WebView clipboard / paste callbacks
      and confirm console content can neither write to nor read from the
      clipboard) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassClipboardIsolation`, always
      `false`): the test-only opt-in never bypasses clipboard isolation — console
      content can never place privileged session data on a cross-app clipboard
      and never read operator credentials from it, in strict mode and with the
      flag both off and on. The opt-in relaxes ONLY the test BMC's untrusted
      server leaf for the expected host, via a scoped per-connection verifier;
      it must never grant a clipboard read or write just to make a console
      render or to debug it. This box governs the cross-app clipboard data
      channel itself, not the clipboard permission-prompt surface (which is one
      host capability among the device-capability / permission-access box): it
      is distinct from device capabilities (host permission prompts), sensitive
      data at rest (on-disk persistence / background snapshot), Web Share /
      remote-cast exfiltration (a receiver outside the app) and outbound egress
      (programmatic network connections). Verified per target before the flag
      is flipped.
* [ ] **No cross-origin web-messaging exfiltration (`postMessage` /
      `BroadcastChannel` / `MessageChannel`)** — the embedded WebView must not
      let attacker-influenced console content hand privileged session data
      (session tokens, credentials, KVM frames, managed-host inventory) to
      another browsing context or same-device origin through the HTML5 web
      messaging APIs: no `window.postMessage()` to a foreign-origin target,
      no `BroadcastChannel` / `MessageChannel` message to a different origin,
      and no scripted cross-frame message that carries console data to any
      context outside the validated same-origin HTTPS console. Console content
      is served by the BMC and is therefore attacker-influenced: cross-origin
      messaging is an in-process data channel that needs no network request,
      clipboard write or native bridge, so it is invisible to the outbound
      egress allowlist, clipboard isolation and native-bridge checks. Every
      cross-origin message from console content must be denied by default at
      the WebView on every target, in strict mode and with the flag both off and
      on. Verified per target (inspect the WebView message / frame callbacks and
      confirm console content cannot post a message to any foreign-origin
      context) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassCrossOriginMessagingIsolation`,
      always `false`): the test-only opt-in never bypasses cross-origin
      web-messaging isolation — console content can never exfiltrate privileged
      session data through `postMessage` / `BroadcastChannel` / `MessageChannel`
      to a foreign-origin context, in strict mode and with the flag both off
      and on. The opt-in relaxes ONLY the test BMC's untrusted server leaf for
      the expected host, via a scoped per-connection verifier; it must never
      grant a cross-origin messaging channel just to make a console render or
      to debug it. This box governs the in-process cross-origin messaging data
      channel itself, so it is distinct from native bridge isolation (an
      app-injected bridge exposed to the page, not web-standard messaging
      between origins), outbound egress (programmatic network connections),
      cross-origin form submission (an HTML form POST), top-level navigation
      (where the main frame navigates) and clipboard isolation (the cross-app
      system clipboard). Verified per target before the flag is flipped.
* [ ] **No screen / window capture exfiltration (`getDisplayMedia` /
      `MediaRecorder` / canvas `captureStream` / `toDataURL`)** — the embedded
      WebView must not let attacker-influenced console content scrape the
      privileged console's rendered frames — KVM screen frames, session tokens,
      credentials, managed-host inventory — off the display and hand them to a
      foreign origin through a scripted capture API: no
      `navigator.mediaDevices.getDisplayMedia()` / `MediaRecorder` recording of
      a captured surface, no `HTMLCanvasElement.captureStream()` stream capture
      and no `canvas.toDataURL()` / `toBlob()` snapshot of the console DOM
      (e.g. rendered via `html2canvas`) followed by an egress upload. Console
      content is served by the BMC and is therefore attacker-influenced: a
      capture API turns the trusted console frame into a screen-scraping
      channel that reads whatever the operator sees — including KVM frames
      rendered by other trusted UI and credential dialogs — wholly independent
      of TLS, hostname, origin, native-bridge and outbound-egress checks (which
      govern the connection, injected code and network destinations, not an
      active capture of the rendered pixels). This box does not prohibit an
      operator/app-initiated screenshot of the whole app (a separate functional
      path); it forbids console-script-initiated capture of the privileged
      display surface. Verified per target (inspect the WebView capability /
      permission configuration and observe that no console script can start a
      display capture or snapshot the console frame) before the flag is
      flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassScreenCaptureProtection`,
      always `false`): it never bypasses screen/window-capture protection —
      console content can never script a display capture or frame snapshot of
      the privileged console surface, in strict mode and with the flag both off
      and on. The opt-in relaxes ONLY the test BMC's untrusted server leaf for
      the expected host, via a scoped per-connection verifier; it never grants a capture capability
      just to make a console render or to debug it. This box governs active,
      page-script-driven capture of the rendered display, so it is distinct from
      device-capability / permission access ([bypassDevicePermissionControls])
      (camera / microphone / geolocation / clipboard / notification /
      Bluetooth / NFC privilege — a display-capture grant is not a camera/mic grant),
      from the OS background-snapshot surface inside sensitive data at rest
      ([bypassSensitiveDataAtRestProtection]) — a passive OS capture, not an active page-script scrape —
      from picture-in-picture ([bypassPictureInPictureEscape]) (a floating
      window over the app, not a capture of pixels), from clipboard isolation
      ([bypassClipboardIsolation]) (a cross-app data channel, not a screen
      scrape) and from outbound egress ([bypassOutboundEgressAllowlist]) (the
      destination of a connection, not the capture of the pixels it carries).
      Verified per target before the flag is flipped.
* [ ] **No hyperlink auditing / `<a ping>` exfiltration** — the embedded WebView
      must not let attacker-influenced console content exfiltrate privileged
      session data (session tokens, operator credentials, KVM frame handles,
      managed-host inventory) through HTML hyperlink auditing. The HTML ping
      attribute on an anchor (`<a ping=...>`) makes the browser issue a
      background POST (with `Ping-From` / `Ping-To` headers) to each listed URL
      when the link is followed, so a scripted click or auto-followed link can
      smuggle the privileged console handle to an attacker origin in the ping
      URL — no script-opened socket, form submission or visible navigation
      change. Console content is served by the BMC and is therefore
      attacker-influenced: hyperlink auditing is a browser-generated request
      controlled by the CSP ping directive (or `default-src`), NOT `connect-src`,
      so a `connect-src 'self'` egress allowlist alone does not confine it.
      Hyperlink auditing must be disabled at the WebView (ping URLs stripped,
      ping requests denied at request interception, CSP ping 'none') on every
      target, in strict mode and with the flag both off and on. Operator/app-
      initiated navigation of the console is a separate functional path and
      stays unaffected; only the hidden third-party auditing request driven by
      console content is forbidden. Tolerating the test BMC's untrusted server
      leaf relaxes ONLY that leaf's trust for the expected host, via a scoped
      per-connection verifier; it must never allow hyperlink auditing just to
      make a console render or to debug it.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassHyperlinkAuditingExfiltration`,
      always `false`): it never bypasses hyperlink-auditing exfiltration — console
      content can never emit a background auditing POST carrying privileged
      session data to a non-approved origin, in strict mode and with the flag
      both off and on. This box governs the browser-generated
      link-activation request channel, so it is distinct from the outbound
      egress allowlist ([bypassOutboundEgressAllowlist]) (programmatic fetch /
      XHR / WebSocket / WebRTC / sendBeacon connections), cross-origin form
      submission ([bypassCrossOriginFormSubmission]) (an HTML form GET/POST
      body), top-level navigation confinement
      ([bypassTopLevelNavigationConfinement]) (where the main frame navigates),
      private-network egress protection ([bypassPrivateNetworkEgressProtection])
      (the address class of subresources) and CSP / mixed-content blocking
      ([bypassMixedContentBlocking]) (which subresources the page may load):
      those govern other connection, request or output surfaces, not the
      `<a ping>` auditing request. Verified per target before the flag is
      flipped.
* [ ] **No credential-management / WebAuthn credential harvesting** — the
      embedded WebView must not let attacker-influenced console content invoke
      the browser's Credential Management API or WebAuthn to harvest the
      operator's credentials: no `navigator.credentials.get({ password: true })`
      to read saved passwords for the console origin, no
      `navigator.credentials.create()` / `store()` to register or overwrite a
      stored credential, and no WebAuthn `publicKey` `get()` / `create()` flow
      that coerces a platform authenticator into producing an assertion or a
      biometric / PIN prompt. Console content is served by the BMC and is
      therefore attacker-influenced: a scripted credential retrieval or
      authenticator prompt could silently read stored BMC passwords or produce a
      signed assertion for an attacker-chosen challenge — a credential-theft /
      account-takeover surface. No credential API may be called by the remote
      page; the legitimate operator login flow is a separate app-level path and
      stays unaffected. Tolerating the test BMC's untrusted server leaf relaxes
      ONLY that leaf's trust for the expected host, via a scoped per-connection
      verifier; it must never grant credential-management access just to make a
      console render or to debug it.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassCredentialManagementApiAccess`,
      always `false`): it never bypasses credential management api access —
      console content can never read saved credentials or coerce an authenticator
      assertion, in strict mode and with the flag both off and on. This box
      governs the browser's stored-credential / authenticator API surface, so it
      is distinct from autofill credential capture ([bypassAutofillCredentialCapture])
      (the browser auto-filling a form field) and HTTP-auth challenge denial
      ([bypassHttpAuthChallengeDenial]) (the native authentication-challenge
      dialog), as well as every server-side certificate check, the TLS floor,
      HTTPS-only transport, validated-origin binding and the other exfiltration
      channels: those govern the connection, its other credentials and its
      outputs, not the page's access to the credential-management API. Verified
      per target before the flag is flipped.
* [ ] **No speculative prefetch / prerender (Speculation Rules API)
      exfiltration** — the embedded WebView must not let attacker-influenced
      console content trigger a browser-generated speculative request that leaks
      the privileged console handle / session token to a non-approved origin:
      no `<script type="speculationrules">` `prefetch` / `prerender` rule, no
      `<link rel="prefetch">` / `<link rel="prerender">` and no scripted
      `SpeculationRules` insertion making the browser speculatively fetch or
      render a crafted URL. The console URI may carry a session token, so a
      speculative prefetch/prerender can hand it to an attacker origin with no
      user activation, visible navigation or script-opened socket. Console
      content is served by the BMC and is therefore attacker-influenced:
      speculative requests are a browser-generated speculative request channel
      governed by the CSP `prefetch-src` directive (or `default-src`), NOT
      `connect-src`, so a `connect-src 'self'` egress allowlist alone does not
      confine them. Speculative prefetch/prerender must be disabled at the
      WebView (speculation rules ignored, speculative requests denied at request
      interception, CSP `prefetch-src 'none'`) on every target, in strict mode
      and with the flag both off and on. Operator/app-initiated navigation is a
      separate functional path and stays unaffected.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassSpeculationRulesEgress`,
      always `false`): it never bypasses speculative prefetch / prerender
      exfiltration — console content can never leak privileged session data via
      a browser-generated speculative request, in strict mode and with the flag
      both off and on. The opt-in relaxes ONLY the test BMC's untrusted server
      leaf for the expected host, via a scoped per-connection verifier; it must
      never grant a speculative request just to make a console render or to
      debug it. This box governs the browser-generated speculative request
      channel, so it is distinct from hyperlink auditing (`<a ping>`) (a
      background auditing POST fired on link activation), the outbound egress
      allowlist (programmatic fetch / XHR / WebSocket / WebRTC / sendBeacon
      connections), top-level navigation confinement (where the main frame
      navigates) and cross-origin form submission (an HTML form POST body):
      those govern other request, navigation or output surfaces, not a
      browser-initiated speculative fetch/prerender. Verified per target before
      the flag is flipped.
* [ ] **No notification / notification-permission spoofing exfiltration
      (Notifications API)** — the embedded WebView must not let
      attacker-influenced console content render privileged management-session
      data (KVM frames, session tokens, operator credentials, managed-host
      inventory) into an OS notification shown outside the secure console frame,
      nor coerce an OS notification-permission prompt: no
      `Notification.requestPermission()` / `Notification.permission` prompt
      induced by console content, no `new Notification(title, { body })` and no
      `ServiceWorkerRegistration.showNotification()` carrying console DOM
      content. Console content is served by the BMC and is therefore
      attacker-influenced: a notification renders attacker-chosen text in the
      OS notification shade / lock screen — outside the app's secure console
      surface, visible while the console is backgrounded and clickable to
      launch an attacker-controlled destination — a UI-spoof / data-
      exfiltration surface wholly independent of the outbound egress allowlist
      (network destinations), screen / window capture (pixels), print (a durable
      paper/PDF copy) and downloads (a file on disk), which govern other output
      surfaces. Every notification request and notification render from console
      content must be denied at the WebView on every target, in strict mode and
      with the flag both off and on. Operator/app-initiated notifications of the
      app itself are a separate functional path and stay unaffected. Verified
      per target (inspect the WebView notification / permission callbacks and
      confirm console content cannot show a notification or raise a
      notification-permission prompt) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassNotificationApiAccess`,
      always `false`): the test-only opt-in never bypasses notification api
      access — console content can never place privileged data in a
      notification shown outside the secure frame nor coerce a
      notification-permission prompt, in strict mode and with the flag both off
      and on. The opt-in relaxes ONLY the test BMC's untrusted server leaf for
      the expected host, via a scoped per-connection verifier; it must never
      grant a notification request just to make a console render or to debug
      it. This box governs the notification-content output channel, not the
      notification permission-prompt surface (which is one host capability
      among the device-capability / permission-access box): it is distinct from
      device-capability / permission access ([bypassDevicePermissionControls])
      (host permission prompts), JavaScript dialog / modal spoofing
      ([bypassJavaScriptDialogDenial]) (in-page modals), picture-in-picture
      ([bypassPictureInPictureEscape]) (a floating window) and screen / window
      capture ([bypassScreenCaptureProtection]) (an active scrape of rendered
      pixels): those govern other prompt, modal, window or capture surfaces,
      not an OS notification. Verified per target before the flag is flipped.
* [ ] **No WebRTC peer-to-peer / data-channel exfiltration** — the embedded
      WebView must not let attacker-influenced console content open a WebRTC
      peer-to-peer connection or data channel that exfiltrates privileged
      management-session data (KVM frames, session tokens, operator credentials,
      managed-host inventory) to a non-approved peer, nor leak the host's real /
      private IP addresses: no `RTCPeerConnection` / `webkitRTCPeerConnection`
      (prefixed variant), no `RTCDataChannel` / `createDataChannel()`, no
      `createOffer` / `createAnswer` / `setRemoteDescription` signalling, no
      ICE candidate gathering / `onicecandidate` and no STUN / TURN server
      contact induced by console content. Console content is served by the BMC
      and is therefore attacker-influenced: a WebRTC data channel sends data
      peer-to-peer over UDP/ICE with no HTTP request and no visible navigation,
      and ICE candidate gathering discloses the device's private / public IPs —
      a data-exfiltration + IP-leak surface NOT confined by the HTTP(S) egress
      allowlist (fetch / XHR / WebSocket / sendBeacon governed by CSP
      `connect-src`): WebRTC uses its own ICE/STUN/TURN negotiation over UDP and
      is not confined by `connect-src 'self'`, so an egress allowlist alone does
      not stop a data channel to an attacker-controlled peer. Every WebRTC peer
      connection, data channel, ICE gathering and STUN/TURN contact from console
      content must be denied at the WebView on every target, in strict mode and
      with the flag both off and on. Operator/app-initiated connections are a
      separate functional path and stay unaffected. Verified per target before
      the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassWebRtcDataChannelExfiltration`,
      always `false`): the test-only opt-in never bypasses WebRTC peer-to-peer /
      data-channel exfiltration — console content can never open a peer
      connection or data channel to exfiltrate privileged data or leak IPs, in
      strict mode and with the flag both off and on. The opt-in relaxes ONLY the
      test BMC's untrusted server leaf for the expected host, via a scoped
      per-connection verifier; it must never grant a WebRTC peer connection just
      to make a console render or to debug it. This box governs the WebRTC
      peer-to-peer UDP data-channel + ICE surface, so it is distinct from the
      outbound egress allowlist (programmatic HTTP(S) connections governed by
      connect-src), private-network egress protection (loopback / link-local /
      private-address subresource requests), device-capability / permission
      access (camera / microphone capture via getUserMedia) and cross-origin
      web-messaging isolation (in-process postMessage): those govern other
      connection, capture or messaging surfaces, not a peer-to-peer UDP data
      channel. Verified per target before the flag is flipped.
* [ ] **No File System Access API local-file read / write exfiltration** — the
      embedded WebView must not let attacker-influenced console content use the
      browser's File System Access API to read local files into the trusted
      frame or write privileged console data (KVM frames, session tokens,
      operator credentials, managed-host inventory) to a durable,
      console-chosen file path: no `window.showOpenFilePicker()` /
      `showSaveFilePicker()` / `showDirectoryPicker()`, no
      `FileSystemFileHandle.createWritable()` /
      `FileSystemDirectoryHandle` traversal and no Origin Private File System
      (OPFS) `navigator.storage.getDirectory()` write induced by console
      content. Console content is served by the BMC and is therefore
      attacker-influenced: unlike a passive `<input type=file>` upload, this API
      returns live file handles the script can both read (local secrets into the
      console frame) and write (an attacker-chosen durable file readable by any
      co-resident app), a local-file read/write channel independent of the
      outbound network egress allowlist. Every File System Access API call from
      console content must be denied at the WebView on every target, in strict
      mode and with the flag both off and on.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassFileSystemAccessApi`,
      always `false`): the test-only opt-in never bypasses File System Access
      API local-file read/write — console content can never read a local file
      via a file handle nor write a durable file to disk, in strict mode and
      with the flag both off and on. The opt-in relaxes ONLY the test BMC's
      untrusted server leaf for the expected host, via a scoped per-connection
      verifier; it must never grant a file system handle just to make a console
      render or to debug it. This box governs the script-driven File System
      Access API read/write channel, so it is distinct from the file chooser
      (`bypassFileChooserAccess`) (the operator-mediated `<input type=file>` /
      `onShowFileChooser` selection uploaded to the page), local file / content
      access (`bypassLocalFileAccess`) (the page loading `file://` / `content://`
      URLs), distinct from sensitive data at rest
      (`bypassSensitiveDataAtRestProtection`)
      (the WebView's own automatic cache/storage and background snapshot) and
      arbitrary file download (`bypassArbitraryFileDownload`) (a network-
      response file written to a download destination): those govern other
      local-read, automatic-storage or network-response surfaces, not a direct
      script-driven filesystem read/write via a file handle. Verified per target
      before the flag is flipped.
* [ ] **No WebTransport / QUIC datagram exfiltration** — the embedded WebView
      must not let attacker-influenced console content open a WebTransport
      session (`new WebTransport(url)`) and use its QUIC `datagrams` (`send()`
      / `datagrams.readable`) or streams (`createBidirectionalStream()` /
      `createUnidirectionalStream()`) to smuggle privileged KVM frames, session
      tokens, operator credentials or managed-host inventory to a non-approved
      origin, nor leak the device's private/public IPs. Console content is
      served by the BMC and is therefore attacker-influenced: WebTransport is a
      client/server QUIC transport with its own datagram/stream channels at the
      WebView layer and must be denied on every target, in strict mode and with
      the flag both off and on. It is distinct from WebRTC
      (`bypassWebRtcDataChannelExfiltration`), which is a peer-to-peer UDP data
      channel driven by ICE/STUN/TURN offer/answer signalling, and it is
      distinct from programmatic HTTP egress (`bypassOutboundEgressAllowlist`)
      (fetch / XHR / WebSocket / sendBeacon), a different transport surface that
      must be denied independently. Verified per target (inspect the WebView
      network stack and confirm no WebTransport session can be opened by
      console content) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassWebTransportExfiltration`,
      always `false`): the test-only opt-in never bypasses WebTransport / QUIC
      exfiltration — console content can never open a WebTransport session or
      datagram/stream channel, in strict mode and with the flag both off and on.
      The opt-in relaxes ONLY the test BMC's untrusted server leaf for the
      expected host, via a scoped per-connection verifier; it must never grant
      a WebTransport just to make a console render or to debug it. No
      QUIC-exfiltration path. Verified per target before the flag is flipped.
* [ ] **No WebUSB / WebSerial / WebHID peripheral I/O exfiltration** — the
      embedded WebView must not let attacker-influenced console content enumerate
      or open a connection to a locally attached USB device, serial port or HID
      peripheral through WebUSB (`navigator.usb.*`), WebSerial
      (`navigator.serial.*`) or WebHID (`navigator.hid.*`) and use the byte-stream
      / report channel to smuggle privileged KVM frames, session tokens,
      operator credentials or managed-host inventory to a physically attached
      device — a local-hardware data channel that bypasses every network egress
      control — nor relay that data off-host through a connected peripheral.
      Console content is served by the BMC and is therefore attacker-influenced:
      a compromised/spoofed BMC or a script in the page must never obtain a
      peripheral I/O stream, on every target, in strict mode and with the flag
      both off and on. Verified per target (inspect the WebView permission /
      USB-serial-HID callbacks and confirm console content cannot open a
      peripheral I/O stream) before the flag is flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassPeripheralIoExfiltration`,
      always `false`): the test-only opt-in never bypasses peripheral I/O
      exfiltration — console content can never open a peripheral I/O stream, in
      strict mode and with the flag both off and on. The opt-in relaxes ONLY the
      test BMC's untrusted server leaf for the expected host, via a scoped
      per-connection verifier; it must never grant a peripheral I/O stream just
      to make a console render or to debug it. No local-hardware exfiltration
      path. This box governs the script-driven local-hardware byte-stream
      channel, so it is distinct from device-permission controls
      (`bypassDevicePermissionControls`) (generic capability grants / native
      permission prompts such as camera, microphone, geolocation, Bluetooth /
      NFC — not a direct USB/serial/HID byte stream), the File System Access API
      (`bypassFileSystemAccessApi`) (filesystem handles / durable file reads and
      writes, not peripheral I/O) and it is distinct from the outbound egress
      allowlist (`bypassOutboundEgressAllowlist`) (HTTP(S) network destinations,
      not a physically attached device). Verified per target before the flag is
      flipped.
* [ ] **No CSS-driven subresource exfiltration (CSS exfiltration)** — the
      embedded WebView must not let attacker-influenced console content emit a
      stylesheet-driven network request that carries privileged management-session
      data (KVM frame handles, session tokens, operator credentials, managed-host
      inventory) to a non-approved origin. This is the declarative CSS channel:
      `<link rel=stylesheet>` and `@import` rules, CSS `url()` values such as
      `background-image`, `image-set()` and `cursor`, `@font-face { src: url(...) }`
      font loads, and CSS-injection `attribute selector` exfiltration that leaks a
      secret form value character-by-character by choosing a distinct background
      URL per guessed prefix. Each of these issues a real network request from a
      stylesheet, with no script-opened socket, form submission, navigation or
      visible change — so a `connect-src 'self'` outbound egress allowlist alone
      does not confine it. It is governed by the CSP source directives `style-src`,
      `img-src` and `font-src` (or `default-src`), which must pin those loads to
      the approved same-origin HTTPS console and be denied at WebView request
      interception on every target, in strict mode and with the flag both off and
      on. Console content is served by the BMC and is therefore attacker-influenced:
      a compromised/spoofed BMC or injected CSS must never turn the trusted frame
      into a stylesheet-driven exfiltration beacon. Verified per target (inspect
      the WebView's CSS-driven loads and confirm no non-approved-origin stylesheet,
      image or font request carrying console data is issued) before the flag is
      flipped.
      This is a hard, configuration-independent invariant that a future WebView
      consumer can consult (`KvmWebViewPolicy.bypassCssExfiltration`, always
      `false`): the test-only opt-in never bypasses CSS-driven subresource
      exfiltration — console content can never emit a stylesheet-driven request
      to a non-approved origin, in strict mode and with the flag both off and on.
      The opt-in relaxes ONLY the test BMC's untrusted server leaf for the
      expected host, via a scoped per-connection verifier; it must never grant a
      CSS-driven stylesheet request just to make a console render or to debug it.
      No CSS-exfiltration path. This box governs the declarative stylesheet
      request channel, which is confined by `style-src` / `img-src` / `font-src`
      and is therefore **not connect-src** programmatic egress
      (`bypassOutboundEgressAllowlist`) (fetch / XHR / WebSocket / sendBeacon),
      and is also distinct from speculative prefetch / prerender
      (`bypassSpeculationRulesEgress`) (a browser-generated `prefetch-src`
      request) and hyperlink auditing (`bypassHyperlinkAuditingExfiltration`)
      (a `ping`-directive POST fired on link activation): those govern other
      request surfaces, not stylesheet-driven subresource loads. Verified per
      target before the flag is flipped.
* [ ] **Flag-off fallback** — with the opt-in flag off, the external secure
      browser + copy path still works unchanged and no in-app render occurs.

Sign-off (human; leave blank until actually validated):
_pending — no target validated as of 2026-11-21. No approval is granted by this
document spike._
