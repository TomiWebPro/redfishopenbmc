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
