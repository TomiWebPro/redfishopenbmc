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
* [ ] **CSP / mixed content** — the BMC console's HTTP response headers and
      page content are inspected for `Content-Security-Policy` frame rules and
      mixed-content (HTTPS page loading HTTP subresources); a console that is
      blocked by CSP framing or mixed-content must not be silently downgraded.
* [ ] **Fullscreen** — the console can enter/exit fullscreen without leaving the
      app or losing the secure context.
* [ ] **Keyboard / pointer input forwarding** — keyboard and mouse input are
      forwarded to the remote console and cannot leak to the host page or trigger
      navigation to a different origin.
* [ ] **Flag-off fallback** — with the opt-in flag off, the external secure
      browser + copy path still works unchanged and no in-app render occurs.

Sign-off (human; leave blank until actually validated):
_pending — no target validated as of 2026-11-21. No approval is granted by this
document spike._
