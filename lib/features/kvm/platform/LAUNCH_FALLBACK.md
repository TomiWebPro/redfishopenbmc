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
`test/features/kvm/platform/launch_plan_test.dart` (67 across the platform
suite).

## Decision contract (`planConsoleLaunch`)

| Console + policy | Route | `targetUri` | `acceptSelfSigned` |
|---|---|---|---|
| flag off + HTTPS HTML5 enabled | `externalBrowser` | trimmed HTTPS URI | `false` |
| flag off + plaintext HTTP | `copyOnly` | trimmed URI (for copy) | `false` |
| flag off + no URI | `copyOnly` | `null` | `false` |
| flag off + blank URI / inconsistent "secure" flag | `copyOnly` (fail closed) | `null` | `false` |
| flag off + **disabled** console (even HTTPS) | `copyOnly` (fail closed) | trimmed HTTPS URI | `false` |
| test opt-in + HTTPS HTML5 enabled | `inAppWebView` | trimmed HTTPS URI | `true` (test-only) |
| opt-in but strict TLS | `inAppWebView` | trimmed HTTPS URI | `false` |
| opt-in + plaintext / disabled / non-HTML5 | never launchable | trimmed URI | `false` |

Invariants, enforced by tests:

1. **Fallback keeps working with the flag off.** With `productionDefault` an
   HTTPS console always routes to `externalBrowser` with a usable URI; anything
   unsafe or URI-less routes to `copyOnly`. Nothing about the existing
   launch-URI + status + copy viewer changes.
2. **Self-signed acceptance is gated on the final route being in-app** AND the
   test-only opt-in AND HTTPS. External-browser and copy-only fallbacks can
   never set it — production TLS is never weakened (issue #021).
3. **Fail closed.** A blank/missing URI degrades to `copyOnly` rather than
   handing a launcher a null/whitespace target; URIs are trimmed on **every**
   route (including copy-only, so the clipboard never surfaces a padded
   endpoint). A console the BMC reports disabled is never routed to a
   launchable target — it always degrades to `copyOnly` even when its URI is
   HTTPS, keeping the decision layer in lockstep with
   `KvmConsole.canOpenConsole` and the card/viewer gating.
4. **Scheme + host + control-char re-validation (defense in depth).**
   `hasSecureUri` alone is never trusted for a TLS-sensitive decision: the raw
   URI string must also be an HTTPS URL with a non-empty host and no embedded
   control characters. Three sibling pure classifiers share the same
   raw-space/control-char hardening: `isSecureHttpsConsoleUri` (HTTPS),
   `isPlaintextHttpConsoleUri` (plaintext HTTP) and `isHttpConsoleUri`
   (HTTP or HTTPS). They back the decision layer here AND every model
   transport classifier — `hasSecureLaunchUri` / `usesInsecureHttpLaunchUri` /
   `hasHttpLaunchUri` on both `KvmConsole` and `KvmCapability` — so no surface
   can disagree with the launch plan about a malformed target, whatever its
   scheme. The scheme-agnostic `isControlSafeConsoleUri` exposes the same
   shared gate so the **non-HTTP** external-client classifiers
   (`KvmConsole.requiresExternalConsoleClient` /
   `externalClientProtocolLabel`: VNC/RFB/KVMIP/serial) cannot announce a
   raw-space/C0/DEL/Unicode-separator-bearing URI as a trustworthy external
   client while an equivalent malformed HTTP(S) URI is refused — it fails
   closed to `noUri` instead. It uses `Uri.tryParse` + `scheme == 'https'`
   + non-empty `host` (a hand-rolled authority scan could call a malformed port
   "secure") and rejects C0/DEL controls, which `Uri.tryParse` silently
   percent-encodes. A stale/incorrect secure flag paired with a plaintext
   `http://`, non-HTTPS, host-less (`https:///console`, `https://?q`,
   `https://#f`, `https://user@/`), malformed-authority
   (`https://bmc.example:notaport/`, `https://bmc.example::443/`) or
   CRLF/NUL/TAB/DEL-bearing URI fails closed to `copyOnly` — even under the
   test opt-in — so such targets can never be rendered in-app or receive
   self-signed acceptance. Legitimate userinfo/port URIs still pass. This can
   only tighten classification, so no valid HTTPS endpoint is lost.
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
   Legitimate userinfo/port URIs are unaffected. The same hardening now applies
   to plaintext-HTTP / HTTP-family classification via the sibling classifiers,
   so a raw-space/C0/DEL HTTP URI can no longer drive an "Unencrypted HTTP
   console URI" warning as if it were a real endpoint.

   **Unicode separator/invisible rejection:** the check is now a principled
   Unicode-category rule (`RegExp(r'[\\\p{C}\p{Z}]', unicode: true)`), not just an
   ASCII scan. `Uri.tryParse` also silently percent-encodes Unicode separators
   and format/invisible characters (NBSP `U+00A0`, zero-width space, line
   separator, ideographic space, BOM) into the host/path; an embedded one is not
   removed by `String.trim()`, so under a stale flag + test opt-in it could
   reach in-app rendering and self-signed acceptance on a malformed/spoofed
   host. All Unicode `Separator` (Z) and `Other` (C) code points are rejected
   raw (stricter than, and subsuming, the C0/DEL/ASCII-space scan); non-ASCII
   characters outside those categories (e.g. an emoji in the path) stay
   launchable, so no properly encoded target is lost. It is applied uniformly by
   all three sibling classifiers, so a malformed HTTP URI can no longer drive
   an "Unencrypted HTTP console URI" warning as if it were a real endpoint.
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
   URIs are unaffected, so no valid target is lost. Covered by targeted tests
   (malformed-authority parity + control-character + raw-space +
   Unicode-whitespace/invisible + raw-backslash + RFC-3986 unwise-char
   rejection) in `launch_plan_test.dart`, plus classifier-agreement tests in
   `kvm_model_test.dart` and `kvm_capability_test.dart`.
   **Malformed percent-encoding rejection:** RFC 3986 requires
   `pct-encoded = "%" HEXDIG HEXDIG`, but `Uri.tryParse` silently encodes a bare
   or malformed `%` into the host rather than rejecting it (`...%` ->
   `bmc.example%25`, `...%ZZ` -> `bmc.example%25zz`), so it too passes a purely
   syntactic re-check. A bare `%` is not in the forbidden char class (valid
   `%XX` must stay launchable), so under a stale flag + test opt-in it could
   reach in-app rendering and self-signed acceptance on a malformed host. Every
   `%` not followed by exactly two hex digits (either case) fails closed, while
   valid `%XX` stays launchable — no valid target is lost. This is applied by the
   same shared control-safety gate as the other raw-char rejections, so every
   HTTP(S) classifier and the launch-plan target refuse a malformed escape
   identically. Covered by 3 additional targeted tests (malformed-percent-encoding
   rejection) in `launch_plan_test.dart`.
   **Raw non-ASCII authority rejection:** RFC 3986 URIs are ASCII-only, but
   `Uri.tryParse` silently pct-encodes a raw non-ASCII host/userinfo into a
   non-empty host (e.g. Cyrillic 'a' U+0430 -> `bmc%D0%B0.example`, an IDN
   homograph/confusable), passing a purely syntactic re-check. Under a stale
   secure flag + test opt-in that could reach in-app rendering and self-signed
   acceptance on a malformed/spoofed host. The raw authority is rejected outright
   — scoped so an ASCII punycode/pct-encoded host and non-ASCII path/query text
   stay launchable, no valid target lost; folded into the same shared
   control-safety gate so every HTTP(S) classifier and the launch-plan target
   reject it identically.
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
   target lost. Folded into the same shared gate so every HTTP(S) classifier
   and the launch-plan target reject it identically.
   **Encoded C0/DEL control-octet rejection:** a pct-encoded octet in the
   0x00-0x1F (C0) or 0x7F (DEL) range is a *valid* `%XX` escape (so the
   malformed-percent rule does not catch it) with no raw forbidden character,
   yet `Uri.tryParse` keeps it encoded while still reporting an HTTPS URI with
   a non-empty host. Consumers decode such octets into NUL host truncation
   (`bmc.example%00.evil.com` reads as `bmc.example`), CRLF/header injection,
   or authority confusion. Under a stale secure flag + test opt-in that parser
   differential could grant in-app rendering and self-signed acceptance on a
   spoofed/malformed host. Every pct-encoded C0/DEL octet (either hex case,
   anywhere in the URI) fails closed; non-control escapes (`%20`, `%2F`, UTF-8
   bytes, ...) stay launchable, no valid target lost. Folded into the same
   shared gate so every HTTP(S) classifier and the launch-plan target reject
   it identically.
   Covered by 55 targeted tests (malformed-authority parity +
   control-character + raw-space + Unicode-whitespace/invisible +
   raw-backslash + RFC-3986 unwise-char + malformed-percent-encoding +
   raw non-ASCII authority + encoded authority-delimiter + encoded C0/DEL
   control-octet rejection) in `launch_plan_test.dart`.

## What remains gated (not done here)

A real WebView plugin and kernel requires recorded per-target validation
evidence (render an HTTPS console, reject certs by default, test-only
self-signed acceptance, no plaintext downgrade, flag-off fallback). No such
plugin exists on the available Linux/desktop target (see
`WEBVIEW_TLS_MATRIX.md`), so no `pubspec.yaml` change and no dependency bump is
made. Until evidence exists, the flag stays off and the external-browser + copy
path remains the only rendering route.
