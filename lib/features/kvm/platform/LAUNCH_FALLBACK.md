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
consume; today it locks the fallback behaviour with 55 targeted tests in
`test/features/kvm/platform/launch_plan_test.dart` (66 across the platform
suite).

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
   Unicode-category rule (`RegExp(r'[\\\p{C}\p{Z}]', unicode: true)`), not just an
   ASCII scan. `Uri.tryParse` also silently percent-encodes Unicode separators
   and format/invisible characters (NBSP `U+00A0`, zero-width space, line
   separator, ideographic space, BOM) into the host/path; an embedded one is not
   removed by `String.trim()`, so under a stale flag + test opt-in it could
   reach in-app rendering and self-signed acceptance on a malformed/spoofed
   host. All Unicode `Separator` (Z) and `Other` (C) code points are rejected
   raw; non-ASCII characters outside those categories (e.g. an emoji in the
   path) stay launchable, so no properly encoded target is lost.
   **Raw-backslash rejection:** a raw `\` is not a legal URI character
   (RFC 3986; a literal backslash must be `%5C`), but `Uri.tryParse` folds it to
   `/`, so `https://bmc.example\@evil.com/console` parses with the *trusted*
   host `bmc.example` while a launcher that does not fold backslashes may
   resolve a different authority. Under a stale flag + test opt-in that parser
   differential could grant in-app rendering and self-signed acceptance on a
   malformed/spoofed authority. Raw backslashes are rejected outright — a
   properly encoded `%5C` stays launchable, so no valid target is lost.
   **RFC-3986 "unwise" character rejection:** the raw ASCII characters `"`,
   `<`, `>`, `^`, `` ` ``, `{`, `|`, `}` are not in the `unreserved`/`reserved`
   sets, so a literal one must be percent-encoded (`%22`, `%3C`, ...), but
   `Uri.tryParse` silently percent-encodes a raw occurrence into the host/path
   instead of rejecting it — e.g. `https://bmc<example/console` parses with
   scheme `https` and the non-empty host `bmc%3Cexample`, passing a purely
   syntactic re-check. Under a stale flag + test opt-in that parser differential
   could reach in-app rendering and self-signed acceptance on a malformed/spoofed
   authority. Every raw unwise char is rejected outright — its `%XX` form stays
   launchable — while legal gen/sub-delims (`[` `]` `&` `=`) and userinfo/port
   URIs are unaffected, so no valid target is lost.
   **Malformed percent-encoding rejection:** RFC 3986 requires
   `pct-encoded = "%" HEXDIG HEXDIG`, but `Uri.tryParse` silently encodes a bare
   or malformed `%` into the host rather than rejecting it (`...%` ->
   `bmc.example%25`, `...%ZZ` -> `bmc.example%25zz`), so it too passes a purely
   syntactic re-check. A bare `%` is not in the forbidden char class (valid
   `%XX` must stay launchable), so under a stale flag + test opt-in it could
   reach in-app rendering and self-signed acceptance on a malformed host. Every
   `%` not followed by exactly two hex digits (either case) fails closed, while
   valid `%XX` stays launchable — no valid target is lost.
   **Raw non-ASCII authority rejection:** RFC 3986 URIs are ASCII-only, but
   `Uri.tryParse` silently pct-encodes a raw non-ASCII host/userinfo into a
   non-empty host (e.g. Cyrillic 'a' U+0430 -> `bmc%D0%B0.example`, an IDN
   homograph/confusable), passing a purely syntactic re-check. Under a stale
   secure flag + test opt-in that could reach in-app rendering and self-signed
   acceptance on a malformed/spoofed host. The raw authority is rejected outright
   — scoped so an ASCII punycode/pct-encoded host and non-ASCII path/query text
   stay launchable, no valid target lost.
   **Encoded authority-delimiter rejection:** a percent-encoded RFC 3986
   gen-delim (`:` `/` `?` `#` `[` `]` `@`) or backslash in the authority is a
   host-confusion vector: consumers disagree on decode order, so `Uri.tryParse`
   keeps `%40` in the host (`bmc.example%40evil.com`) while a decode-first
   launcher reads `@evil.com` as the real userinfo/host. Under a stale flag +
   test opt-in that parser differential could grant in-app rendering and
   self-signed acceptance on a spoofed authority. Every encoded gen-delim/
   backslash (either hex case) in the authority fails closed; the rule is
   scoped so encoded delimiters in the path/query and valid pct-encoded
   non-delimiter host bytes (`bmc%C3%A9.example`) stay launchable, no valid
   target lost.
   **Encoded control-octet rejection:** a percent-encoded C0 (0x00-0x1F) or DEL
   (0x7F) octet is a *valid* `%XX` escape (so the malformed-percent rule misses
   it) with no raw forbidden char, yet `Uri.tryParse` keeps it encoded and
   reports a "secure" HTTPS host: `%00` truncates the host, `%0D%0A` enables
   header injection. Every encoded C0/DEL octet fails closed; other escapes
   stay launchable.
   **Encoded Unicode separator/invisible rejection:** a percent-encoded
   multi-byte UTF-8 character that decodes to a Unicode `Separator` (Z) or
   `Other` (C) code point is likewise a valid `%XX` escape with no raw
   non-ASCII, kept encoded by `Uri.tryParse` while reporting a "secure" host.
   A decode-first launcher turns `%C2%A0` (NBSP, Zs) into an invisible
   separator in the host, or `%E2%80%8B` (zero-width space, Cf) / `%C2%85`
   (NEL, Cc) into an invisible control — a parser-differential / host-spoofing
   vector. Every encoded non-ASCII C/Z code point fails closed; ASCII escapes
   (`%20`) and non-C/Z escapes (`%C3%A9` e-acute, emoji) stay launchable, no
   valid target lost.
   **Encoded compatibility-confusable delimiter rejection:** a percent-encoded
   non-ASCII code point whose Unicode NFKC normalisation is an ASCII structural
   delimiter (gen-delims `:` `/` `?` `#` `[` `]` `@`, backslash, or the
   domain-label dot) is a valid `%XX` escape with no raw forbidden character,
   so every earlier rule misses it. `Uri.tryParse` keeps it encoded and reports
   a "secure" HTTPS host, but a launcher applying IDNA/NFKC to an
   internationalised host (as browsers do) resolves a *different* authority:
   `%EF%BC%8F` (fullwidth solidus) becomes `/`, `%EF%BC%8E` (fullwidth full
   stop) becomes `.`, `%EF%BC%9A` (fullwidth colon) becomes `:`, and the
   FRACTION/DIVISION SLASH characters become `/`. The confusable set is the
   full IDNA/NFKC family, not just fullwidth forms: it also rejects the "small"
   forms (`%EF%B9%92` U+FE52 SMALL FULL STOP -> `.`, `%EF%B9%95` U+FE55 SMALL
   COLON -> `:`, U+FE68 -> `\`, U+FE6B -> `@`), the vertical presentation forms
   (U+FE13 -> `:`, U+FE47/U+FE48 -> `[`/`]`), dot leaders/ellipses (U+2024 ->
   `.`, U+2025/U+2026 -> `..`/`...`), numeric "full stop" forms (U+2488..U+249B,
   U+1F100) and squared forms whose NFKC expansion embeds a delimiter (U+2100
   -> `a/c`, U+33C2 -> `a.m.`). Under a stale flag + test opt-in any of these
   parser differentials could grant in-app rendering and self-signed
   acceptance on a spoofed/mismatched host. Only decoded code points that
   normalise to a structural delimiter in the authority fail closed; encoded
   non-delimiter non-ASCII (e-acute `%C3%A9`, euro `%E2%82%AC`, emoji), ASCII
   escapes and confusables in the path/query stay launchable, no valid target
   lost. Scoped to the authority (the TLS-sensitive part).
   **IDNA dot-confusable rejection:** the confusable set also covers the
   classic CJK/halfwidth dot confusables that a decode+IDNA launcher resolves
   to the domain-label dot ('.') but that are neither Unicode Separator/Other
   nor NFKC-mapped to a literal ASCII character: `%E3%80%82` (U+3002
   IDEOGRAPHIC FULL STOP), `%EF%BD%A1` (U+FF61 HALFWIDTH IDEOGRAPHIC FULL
   STOP) and `%E2%B8%BC` (U+2E3C TWO DOT LEADER, NFKC -> '..'). `Uri.tryParse`
   keeps each encoded and reports an HTTPS host, yet a launcher applying
   UTS-46 IDNA resolves `bmc.example%E3%80%82evil.com` as
   `bmc.example.evil.com` — a parser-differential host-spoofing vector that
   under a stale flag + test opt-in could reach in-app rendering and
   self-signed acceptance on a spoofed/mismatched host. Each fails closed in
   the authority; encoded forms in the path/query and punycode ASCII hosts
   stay launchable, no valid target lost.
   **Degenerate dot-host rejection:** `Uri.tryParse` reports a label-less host
   made only of dots (`https://./console`, `https://../console`) as an HTTPS
   URI with a non-empty host, so the bare scheme+host re-check calls it
   "secure"; it also decodes a percent-encoded dot (`%2E`) in the host to a
   literal '.', so `https://%2E%2E/console` likewise reports host `..`. There
   is no real BMC host (no DNS label) and a launcher may resolve `..` as a
   relative/traversal path. Under a stale flag + test opt-in such a target
   could reach in-app rendering and self-signed acceptance on a bogus host, so
   a host with no non-dot character fails closed; hosts with a real label
   (including an absolute FQDN trailing dot) and IPv6 literals stay launchable.
   Covered by targeted tests across the defense-in-depth re-validation
   groups (scheme/host/malformed-authority parity + control-character +
   raw-space + Unicode-whitespace/invisible + raw-backslash + RFC-3986
   unwise-char + malformed-percent-encoding + raw non-ASCII authority + encoded
   authority-delimiter + encoded control-octet + encoded Unicode
   separator/invisible + encoded compatibility-confusable delimiter + extended
   compatibility-confusable delimiter + IDNA dot-confusable rejection +
   degenerate dot-host rejection).

## What remains gated (not done here)

A real WebView plugin and kernel requires recorded per-target validation
evidence (render an HTTPS console, reject certs by default, test-only
self-signed acceptance, no plaintext downgrade, flag-off fallback). No such
plugin exists on the available Linux/desktop target (see
`WEBVIEW_TLS_MATRIX.md`), so no `pubspec.yaml` change and no dependency bump is
made. Until evidence exists, the flag stays off and the external-browser + copy
path remains the only rendering route.
