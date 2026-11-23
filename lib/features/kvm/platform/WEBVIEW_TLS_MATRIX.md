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
* [ ] **Flag-off fallback** — with the opt-in flag off, the external secure
      browser + copy path still works unchanged and no in-app render occurs.

Sign-off (human; leave blank until actually validated):
_pending — no target validated as of 2026-11-21. No approval is granted by this
document spike._
