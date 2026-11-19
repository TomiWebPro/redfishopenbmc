# Launch fallback contract — external browser + copy path (RP-2)

Owner: rf-platform · Status: **flag OFF in production** · Date: 2026-11-19

## Requirement (queue RP-2)

> Implement the RP-1 opt-in behind the flag with tests; document the fallback
> (external browser + copy path), which must keep working with the flag off.

## What this item adds

`launch_plan.dart` turns RP-1's policy (`webview_policy.dart`) into a concrete,
dependency-free `KvmConsoleLaunchPlan`. It imports no WebView/protocol plugin and
opens no channel — so it adds **no dependency** and **does not touch production
TLS**. It is the flag-gated decision layer a future, validated WebView will
consume; today it locks the fallback behaviour with 9 targeted tests.

## Decision contract (`planConsoleLaunch`)

| Console + policy | Route | `targetUri` | `acceptSelfSigned` |
|---|---|---|---|
| flag off + HTTPS HTML5 enabled | `externalBrowser` | trimmed HTTPS URI | `false` |
| flag off + plaintext HTTP | `copyOnly` | original URI (for copy) | `false` |
| flag off + no URI | `copyOnly` | `null` | `false` |
| flag off + blank URI / inconsistent "secure" flag | `copyOnly` (fail closed) | raw value | `false` |
| test opt-in + HTTPS HTML5 enabled | `inAppWebView` | trimmed HTTPS URI | `true` (test-only) |
| opt-in but strict TLS | `inAppWebView` | trimmed HTTPS URI | `false` |
| opt-in + plaintext / disabled / non-HTML5 | never in-app | original URI | `false` |

Invariants, enforced by tests:

1. **Fallback keeps working with the flag off.** With `productionDefault` an
   HTTPS console always routes to `externalBrowser` with a usable URI; anything
   unsafe or URI-less routes to `copyOnly`. Nothing about the existing
   launch-URI + status + copy viewer changes.
2. **Self-signed acceptance is gated on the final route being in-app** AND the
   test-only opt-in AND HTTPS. External-browser and copy-only fallbacks can
   never set it — production TLS is never weakened (issue #021).
3. **Fail closed.** A blank/missing URI degrades to `copyOnly` rather than
   handing a launcher a null/whitespace target; URIs are trimmed.

## What remains gated (not done here)

A real WebView plugin and kernel requires recorded per-target validation
evidence (render an HTTPS console, reject certs by default, test-only
self-signed acceptance, no plaintext downgrade, flag-off fallback). No such
plugin exists on the available Linux/desktop target (see
`WEBVIEW_TLS_MATRIX.md`), so no `pubspec.yaml` change and no dependency bump is
made. Until evidence exists, the flag stays off and the external-browser + copy
path remains the only rendering route.
