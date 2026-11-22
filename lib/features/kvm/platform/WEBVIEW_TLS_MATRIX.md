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

## Human approval gate (before any flag flip, dependency bump or TLS opt-in)

This document is a **documentation-only** spike. It does **not** grant approval
to embed a WebView, add a rendering dependency, or accept a self-signed BMC
certificate on any production profile. Nothing here flips the flag:
`KvmWebViewPolicy.productionDefault` keeps `enabled == false` and TLS strict,
and the guard test `test/features/kvm/platform/human_gate_doc_guard_test.dart`
fails closed if this recorded gate disappears.

Before **any** `webview_flutter` / `url_launcher` dependency bump or test-only
TLS opt-in, a human maintainer MUST check every applicable evidence box below
for every target being enabled, record the date and target, and update that
target's row in the support matrix from "requires validation" to
"validated (date, reviewer)". Until then the final route remains
external-browser + copy with the flag OFF and production TLS strict.

Required human validation evidence (all applicable boxes, per target):

- [ ] **Linux / desktop** — render an HTTPS BMC console in-app, confirm the OS
      trust store rejects an untrusted cert by default, and confirm the flag-off
      external browser + copy fallback still works.
- [ ] **Mobile (Android / iOS)** — confirm `onReceivedSslError` / ATS rejects a
      self-signed cert by default (never `proceed()`), verify any test-only TLS
      opt-in is gated to a test profile only, and verify no plaintext HTTP
      downgrade.
- [ ] **Other desktop (macOS / Windows)** — confirm the WKWebView / alternative
      implementation rejects invalid certs by default and needs no blanket TLS
      bypass.

The boxes record required evidence only — this run checks none of them and
grants no approval. Sign-off (human, leave blank until actually validated):
_pending — no target validated as of 2026-11-20._

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
      must run with **no injected interfaces**. Verified per target (inspect the
      WebView controller construction) before the flag is flipped.
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
* [ ] **Flag-off fallback** — with the opt-in flag off, the external secure
      browser + copy path still works unchanged and no in-app render occurs.

Sign-off (human; leave blank until actually validated):
_pending — no target validated as of 2026-11-21. No approval is granted by this
document spike._
