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
consume; today it locks the fallback behaviour with 22 targeted tests.

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
4. **Scheme + host re-validation (defense in depth).** `hasSecureUri` alone is
   never trusted for a TLS-sensitive decision: the raw URI string must also be
   an HTTPS URL with a non-empty host (mirroring `hasSecureLaunchUri`).
   Re-validation uses the same `Uri.tryParse` + `scheme == 'https'` + non-empty
   `host` check as the model, so it can never be more permissive than
   production. A stale/incorrect secure flag paired with a plaintext `http://`,
   non-HTTPS, host-less (`https:///console`, `https://?q`, `https://#f`,
   `https://user@/`), or malformed-authority (`https://bmc.example:notaport/`,
   `https://bmc.example::443/`) URI fails closed to `copyOnly` — even under the
   test opt-in — so such targets can never be rendered in-app or receive
   self-signed acceptance. Legitimate userinfo/port URIs still pass.
   **Control-character rejection:** `Uri.tryParse` percent-encodes C0/DEL
   controls (CR, LF, NUL, TAB, DEL) rather than rejecting them, so such a URI
   would otherwise pass the syntactic re-check; these now fail closed
   (stricter than the model, never more permissive) to block launcher
   URI/header injection and self-signed acceptance on malformed targets.
   **Raw-space rejection:** `Uri.tryParse` also percent-encodes a raw space
   (0x20) into the authority (`https://bmc.exa mple/console` → host
   `bmc.exa%20mple`, still non-empty), so it too would pass a purely syntactic
   re-check and gain in-app self-signed acceptance on a malformed host under a
   stale flag. Raw spaces are never valid in a URI (they must be `%20`), so
   they are rejected outright alongside C0/DEL controls — stricter than the
   model, never more permissive; legitimate `%20`-encoded URIs stay launchable.
   **Unicode separator/invisible rejection:** the check is now a principled
   Unicode-category rule (`RegExp(r'[\p{C}\p{Z}]', unicode: true)`), not just an
   ASCII scan. `Uri.tryParse` also silently percent-encodes Unicode separators
   and format/invisible characters (NBSP `U+00A0`, zero-width space, line
   separator, ideographic space, BOM) into the host/path; an embedded one is not
   removed by `String.trim()`, so under a stale flag + test opt-in it could
   reach in-app rendering and self-signed acceptance on a malformed/spoofed
   host. All Unicode `Separator` (Z) and `Other` (C) code points are rejected
   raw; non-ASCII characters outside those categories (e.g. an emoji in the
   path) stay launchable, so no properly encoded target is lost.
   Legitimate userinfo/port URIs are unaffected. Covered by 13 targeted tests
   (malformed-authority parity + control-character + raw-space +
   Unicode-whitespace/invisible rejection).

## What remains gated (not done here)

A real WebView plugin and kernel requires recorded per-target validation
evidence (render an HTTPS console, reject certs by default, test-only
self-signed acceptance, no plaintext downgrade, flag-off fallback). No such
plugin exists on the available Linux/desktop target (see
`WEBVIEW_TLS_MATRIX.md`), so no `pubspec.yaml` change and no dependency bump is
made. Until evidence exists, the flag stays off and the external-browser + copy
path remains the only rendering route.
