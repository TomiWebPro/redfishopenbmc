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
consume; today it locks the fallback behaviour with 134 targeted tests in
`test/features/kvm/platform/launch_plan_test.dart` (145 across the platform
suite).

## Decision contract (`planConsoleLaunch`)

| Console + policy | Route | `targetUri` | `acceptSelfSigned` |
|---|---|---|---|
| flag off + HTTPS HTML5 enabled | `externalBrowser` | trimmed HTTPS URI | `false` |
| flag off + plaintext HTTP | `copyOnly` | original URI (for copy) | `false` |
| flag off + no URI | `copyOnly` | `null` | `false` |
| flag off + blank URI / inconsistent "secure" flag | `copyOnly` (fail closed) | `null` for blank, raw value otherwise | `false` |
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
3. **Fail closed.** A blank/missing URI degrades to `copyOnly` with a `null`
   target — a whitespace-only string is "no usable target" and is never handed
   to a launcher/copy action, under any policy (including the test-only opt-in).
   A non-blank URI that merely fails the secure check keeps its raw copy target;
   URIs are trimmed for every launchable route.
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
   authority. Every raw unwise char is rejected outright; legal gen/sub-delims
   (`[` `]` `&` `=`) and userinfo/port URIs are unaffected, so no valid target
   is lost.
   **Encoded unwise character rejection:** the same eight unwise chars in their
   percent-encoded form (`%22` `%3C` `%3E` `%5E` `%60` `%7B` `%7C` `%7D`, either
   hex case) escape the raw rule (no literal forbidden char), the encoded-delim
   rule (they are not gen-delims), the unreserved/sub-delim rules, and the
   control/C-Z rules. `Uri.tryParse` keeps them encoded and reports a non-empty
   HTTPS host, so a purely syntactic re-check calls it "secure", while a
   decode-first launcher sees a forbidden/non-canonical host code point and may
   reject or resolve a different authority — under a stale flag + test opt-in
   that parser differential could reach in-app rendering and self-signed
   acceptance on a malformed/spoofed host. Every encoded unwise char in the
   authority fails closed (including userinfo and leading/trailing positions);
   the rule is scoped so the same escapes in the path/query and valid pct-encoded
   UTF-8 host bytes stay launchable, no valid target lost.
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
   **Encoded unreserved-ASCII rejection:** RFC 3986 unreserved characters
   (`ALPHA / DIGIT / "-" / "." / "_" / "~"`) never need percent-encoding, so a
   `%XX` form in the authority is non-canonical and creates a decode-order
   host-spoofing differential: `Uri.tryParse` DECODES these escapes into a
   *different* host string (`%62%6D%63` -> `bmc`, `%2D` -> `-`, `%5F` -> `_`,
   `%7E` -> `~`), while a launcher that does not percent-decode the host
   resolves a different authority — one raw URI naming two hosts. The `%2E`
   (dot) case is already rejected by a dedicated rule; this closes the rest of
   the unreserved set. `Uri.tryParse` still reports a non-empty HTTPS host, so
   a purely syntactic re-check calls it "secure" — under a stale flag + test
   opt-in that differential could grant in-app rendering and self-signed
   acceptance on a mismatched/spoofed host. A real BMC host writes these
   characters literally, so each fails closed in the authority; encoded
   unreserved text in the path/query and legitimate percent-encoded non-ASCII
   UTF-8 host bytes (`%C3%A9`) stay launchable, no valid target lost.
   **Encoded sub-delimiter rejection:** RFC 3986 sub-delims (`!` `$` `&` `'` `(` `)`
   `*` `+` `,` `;` `=`) are legal unescaped in a `reg-name`, so a `%XX` form in
   the authority is non-canonical and creates a decode-order host-spoofing
   differential: `Uri.tryParse` keeps it encoded in the host
   (`bmc.example%21evil.com`) while a launcher that decodes host bytes before
   DNS/IDNA resolves a DIFFERENT host (`bmc.example!evil.com`) — one raw URI
   naming two hosts. `Uri.tryParse` still reports a non-empty HTTPS host, so a
   purely syntactic re-check calls it "secure" — under a stale flag + test opt-in
   that differential could grant in-app rendering and self-signed acceptance on
   a mismatched/spoofed authority. A real BMC host writes these characters
   literally, so each encoded form fails closed in the authority; encoded
   sub-delims in the path/query, percent-encoded UTF-8 host bytes (`%C3%A9`) and
   a raw sub-delim literal (no differential) stay launchable, no valid target lost.
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
   **IDNA middle-dot confusable rejection:** the confusable set also covers the
   classic IDNA2003/nameprep middle-dot family that a decode+IDNA launcher maps
   to the domain-label dot ('.'): U+00B7 MIDDLE DOT (`%C2%B7`) and U+0387 GREEK
   ANO TELEIA (`%CE%87`, NFKC -> U+00B7). Both are Unicode category Po
   (punctuation), so neither the Separator/Other (C/Z) rule nor the NFKC-based
   confusable mappings catch them. `Uri.tryParse` keeps each escape encoded and
   reports a non-empty HTTPS host, yet a decode+IDNA launcher resolves
   `bmc.example%C2%B7evil.com` as `bmc.example.evil.com` — a parser-differential
   host-spoofing vector that under a stale flag + test opt-in could reach in-app
   rendering and self-signed acceptance on a spoofed/mismatched host. Both fail
   closed in the authority; encoded forms in the path/query and punycode ASCII
   hosts stay launchable, no valid target lost.
   **NFKC-to-ASCII compatibility letter/digit rejection:** the fullwidth-ASCII
   rule covers only U+FF01..U+FF5E, but a launcher applying IDNA/NFKC also folds
   other compatibility characters to plain ASCII: U+212A KELVIN SIGN -> `K`,
   U+017F LONG S -> `s`, circled Latin letters U+24B6..U+24E9 -> A-Z/a-z,
   circled digits U+2460..U+2473 -> ASCII digits, superscript/subscript digits,
   Roman numerals U+2160..U+217F -> ASCII letters and the squared/negative
   circled/squared Latin capitals U+1F130..U+1F189 -> A-Z. `Uri.tryParse` keeps
   each escape encoded and reports a non-empty HTTPS host, so a purely syntactic
   re-check calls it "secure" while a decode+IDNA launcher resolves a *different*
   ASCII authority. Under a stale flag + test opt-in that parser differential
   could grant in-app rendering and self-signed acceptance on a spoofed host.
   Each fails closed in the authority; encoded forms in the path/query and
   non-ASCII that NFKC-folds to non-ASCII (e-acute, euro, emoji) stay launchable.
   **Mathematical alphanumeric rejection:** the NFKC-to-ASCII rule above does
   not cover Unicode's Mathematical Alphanumeric Symbols block (U+1D400..U+1D7FF),
   whose characters are styled (bold/italic/script/fraktur/double-struck/
   monospace) Latin letters and digits that NFKC-normalise to plain ASCII —
   e.g. `%F0%9D%90%80` (U+1D400 MATHEMATICAL BOLD CAPITAL A) -> `A`,
   `%F0%9D%90%82` (U+1D402 bold C) -> `C`, `%F0%9D%9F%8E` (U+1D7CE bold 0) ->
   `0`. They are neither Unicode Separator/Other nor marks, fold to no
   delimiter, and lie outside the fullwidth/circled/Roman-numeral ranges, so
   every earlier rule misses them: `Uri.tryParse` keeps the escape encoded and
   reports a non-empty HTTPS host, while a decode+IDNA launcher resolves a
   *different* ASCII authority (`https://bmc%F0%9D%90%82c.example/console`
   -> `bmcCc.example`). Under a stale secure flag + test opt-in that parser
   differential could grant in-app rendering and self-signed acceptance on a
   spoofed host. No real BMC host uses a mathematical style, so the whole block
   fails closed in the authority; ordinary pct-encoded UTF-8 host bytes
   (`%C3%A9`, `%E2%82%AC`), punycode hosts and these escapes in the path/query
   stay launchable — no valid target lost.
   **Complete NFKC-to-ASCII compatibility rejection:** the per-family rules
   above enumerate only the common confusable ranges (fullwidth, circled 1-20,
   Roman numerals, mathematical, vulgar fractions), leaving every *other*
   non-ASCII compatibility character whose Unicode NFKC normalisation is plain
   ASCII unchecked. A launcher applying IDNA/NFKC resolves each to a *different*
   ASCII authority than `Uri.tryParse` reports (which keeps the escape encoded
   in a non-empty HTTPS host): Node-verified examples include
   `%F0%9F%AF%B7` (U+1FBF7 SEGMENTED DIGIT SEVEN) -> `bmc7.example`,
   `%E3%89%91` (U+3251 CIRCLED NUMBER TWENTY ONE) -> `bmc21.example`,
   `%EF%AC%81` (U+FB01 LIGATURE FI) -> `bmcfi.example`, `%CA%B0` (U+02B0
   MODIFIER LETTER SMALL H) -> `bmch.example` and `%C2%AA` (FEMININE ORDINAL) ->
   `bmca.example`. Under a stale secure flag + test opt-in that differential
   could grant in-app rendering and self-signed acceptance on a spoofed host.
   A `const` range table generated from Unicode 16.0.0 data closes the whole
   class (427 code points in 92 ranges): every such escape fails closed in the
   authority, while non-ASCII that NFKC-folds to non-ASCII (e-acute, euro,
   emoji), punycode hosts and the same escapes in the path/query stay launchable
   — no valid target lost.
   **NFKC vulgar-fraction confusable rejection:** a percent-encoded "vulgar
   fraction" (Unicode category `No`) NFKC-normalises to a decimal digit +
   U+2044 FRACTION SLASH + digit(s) (e.g. U+00BD `1/2` -> `1` + U+2044 + `2`),
   and IDNA/UTS-46 maps U+2044 to the ASCII `/` structural delimiter. A raw
   non-ASCII authority is already rejected, but the percent-encoded form is
   not: `Uri.tryParse` keeps it verbatim in the host
   (`https://bmc%C2%BD.example/console` -> host `bmc%C2%BD.example`), so a
   purely syntactic re-check calls it "secure", while a decode+IDNA launcher
   resolves a *different* authority (`bmc1/2.example`). Under a stale flag +
   test opt-in that parser differential could grant in-app rendering and
   self-signed acceptance on a spoofed/mismatched host. The fraction code
   points whose NFKC expansion embeds U+2044 (U+00BC..U+00BE, U+2150..U+215F,
   U+2189) fail closed in the authority; no real BMC host uses them, and the
   same escape in path/query/fragment stays launchable — no valid target lost.
   **Encoded combining-mark rejection:** a percent-encoded Unicode `Mark`
   (category M) is a valid `%XX` escape that every earlier rule misses, yet
   `Uri.tryParse` keeps it encoded and reports a non-empty HTTPS host. A
   launcher applying NFC/IDNA to the host (as browsers do) recomposes a base
   letter + mark into a DIFFERENT precomposed character:
   `https://bmc%CC%81.example/` decodes to `bmc` + U+0301 COMBINING ACUTE,
   whose NFC form is `bmc` + U+00E9 — a DIFFERENT authority than `Uri.tryParse`
   reported. Under a stale flag + test opt-in that parser differential could
   grant in-app rendering and self-signed acceptance on a mismatched/spoofed
   host. A real BMC host is ASCII/punycode and never writes a combining mark,
   so every encoded mark fails closed in the authority; precomposed UTF-8 host
   bytes (e-acute, a Letter), emoji and marks in the path/query stay
   launchable — no valid target lost.
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
   **Double-encoded authority-delimiter rejection:** the encoded-delimiter rule
   blocks a single-encoded structural char (`%2F` -> `/`), but a DOUBLE-encoded
   form bypasses it: a pct-encoded percent (`%25`) decodes once to the literal
   characters `%2F`/`%40`/`%2E`, which a launcher that decodes twice turns into
   `/`/`@`/`.` (`%252F` -> `%2F` -> `/`). `Uri.tryParse` keeps `%25` encoded and
   reports a non-empty HTTPS host, so a purely syntactic re-check calls it
   "secure"; a literal `%` is never valid in a host and double-decoding is a
   parser-differential / host-spoofing vector. Under a stale flag + test opt-in
   any such target could reach in-app rendering and self-signed acceptance on a
   spoofed authority, so every `%25` (either hex case) in the authority fails
   closed; it is scoped so `%25` in the path/query and valid pct-encoded UTF-8
   host bytes (`%C3%A9`) stay launchable, no valid target lost.
   **Encoded authority-dot rejection:** the encoded-delimiter rule blocks gen-delims
   (`%2F`, `%40`, ...) but not the percent-encoded ASCII domain-label dot (`%2E`).
   Unlike those delimiters (which `Uri.tryParse` keeps encoded in the host),
   `Uri.tryParse` DECODES `%2E` into a literal '.', silently changing the
   reported host: `https://bmc.example%2Eevil.com/console` reports host
   `bmc.example.evil.com`, while a launcher that does not percent-decode the
   host resolves a different authority. One raw URI can therefore name two
   different hosts — a decode-order host-spoofing vector that under a stale
   flag + test opt-in could grant in-app rendering and self-signed acceptance
   on a mismatched/spoofed host. Every `%2E` (either hex case) in the authority
   — including in userinfo and leading/trailing positions — fails closed. A
   literal dot is always written as '.', so no valid target is lost; the rule
   is scoped so `%2E` in the path/query and valid pct-encoded UTF-8 host bytes
   (`%C3%A9`) stay launchable.
   **Non-canonical numeric-host rejection:** legacy / WHATWG URL parsers
   (browsers, WebViews) resolve `0x7f000001` (hex), `2130706433` / `0` (decimal
   integer), `127.1` / `127.0.1` (abbreviated dotted) and `0177.0.0.1`
   (leading-zero/octal) hosts to IP literals — often loopback or internal
   addresses — while `Uri.tryParse` reports them as opaque DNS names with a
   non-empty HTTPS host. A launcher can therefore contact a DIFFERENT address
   than the authority Uri reported. Under a stale secure flag + test opt-in
   that SSRF-style parser differential could grant in-app rendering and
   self-signed acceptance on a mismatched/spoofed host. The same numeric
   spellings with a single trailing dot (`2130706433.`, `0x7f000001.`) are
   rejected too: the WHATWG "ends in a number" check skips one trailing dot
   and still resolves them as IP literals, while `Uri.tryParse` reports an
   opaque DNS host. Only canonical dotted-quad IPv4 (four 0-255 octets, no
   leading zeros), IPv6 literals and ordinary DNS/punycode hosts — including
   a real absolute-FQDN trailing dot such as `bmc.example.` — stay launchable,
   no real BMC target lost.
   **Mixed ends-in-number host rejection:** the all-digit numeric-host rule
   misses a mixed host whose final label is numeric, because a WHATWG "ends in
   a number" check inspects only the LAST label: `https://bmc.2130706433/`
   and `https://bmc.127.1/` are resolved as IPv4 literals (or rejected outright
   when an earlier label is non-numeric) by a browser/WebView, while
   `Uri.tryParse` reports them as opaque, non-empty HTTPS hosts. Under a stale
   secure flag + test opt-in that parser differential could grant in-app
   rendering and self-signed acceptance on a mismatched/internal host. A real
   BMC host (or any browser-resolvable host) has an alphabetic/punycode final
   label, so a purely numeric last label fails closed; canonical dotted-quad
   IPv4, real trailing-dot FQDNs, IPv6 literals, punycode hosts and final
   labels that merely end in digits stay launchable — no valid target lost.
   **Empty DNS-label rejection:** a leading dot (`.bmc.example`), consecutive
   dots (`bmc..example`) or a double trailing dot (`bmc.example..`) leaves an
   empty DNS label. `Uri.tryParse` reports such a host as non-empty HTTPS, but
   a launcher may collapse the empty label / treat the leading dot as a
   relative reference and contact a DIFFERENT authority — a parser differential
   that under a stale flag + test opt-in could grant in-app rendering and
   self-signed acceptance on a spoofed host. Exactly one trailing dot (absolute
   FQDN), single-label, IPv4/IPv6 and punycode hosts stay launchable.
   **Out-of-range port rejection:** `Uri.tryParse` accepts any non-negative
   decimal port and still reports an HTTPS URI with a non-empty host
   (`https://bmc.example:99999/console` -> host `bmc.example`, port `99999`),
   so a purely syntactic re-check calls it "secure". Browser/WebView (WHATWG
   URL) parsers reject a port above the 16-bit maximum (0..65535), and other
   launchers may wrap it modulo 65536 to a DIFFERENT service — a parser
   differential that under a stale flag + test opt-in could grant in-app
   rendering and self-signed acceptance on a malformed/mismatched authority.
   An explicit port above 65535 fails closed; absent/empty (default) and
   in-range ports, userinfo and IPv6 hosts stay launchable — no real BMC target
   is lost.
   **Non-canonical / signed / overflow port rejection:** `Uri.tryParse` also
   accepts a signed port (`:-1` reports a negative `Uri.port`; `:+443` silently
   ignores the sign and reports the default port) and an arbitrarily long
   decimal port whose `Uri.port` getter THROWS `FormatException` on integer
   overflow, while all still report an HTTPS URI with a non-empty host — so a
   purely syntactic re-check calls them "secure". Browser/WebView (WHATWG URL)
   parsers reject signed/negative ports and ports above 16 bits. Under a stale
   secure flag + test opt-in that parser differential could grant in-app
   rendering and self-signed acceptance on a malformed/mismatched authority,
   or crash the caller on overflow. The raw authority's port token is therefore
   validated as canonical ASCII digits in 0..65535 BEFORE `Uri.port` is read,
   and the parsed port is range-checked with a guarded read as defense in depth
   (never throwing). A real BMC console port is canonical digits, so rejecting
   signed/negative/overflow values loses no valid target: absent/empty ports,
   leading zeros (WHATWG parses them to the same value), userinfo and IPv6
   hosts stay launchable.
   **IPv4-mapped / IPvFuture IPv6 rejection:** the non-canonical numeric-host
   rule skips hosts containing `:` (IPv6 literals), so `Uri.tryParse` reports
   `::ffff:a.b.c.d` (IPv4-mapped) and `[v...]` (IPvFuture) as opaque, non-empty
   HTTPS hosts that pass a purely syntactic re-check. A browser/WebView
   (WHATWG URL) resolves the mapped form to an embedded IPv4 address and
   rejects IPvFuture outright — one URI naming two authorities. Under a stale
   flag + test opt-in that parser differential could grant in-app rendering
   and self-signed acceptance on a malformed/mismatched host. Both fail closed
   (dotted and hex embedded-IPv4 spellings); no real BMC uses a mapped or
   IPvFuture literal. Plain IPv6 loopback (`::1`) is deliberately kept
   launchable — it is a real target for the test-only opt-in and both parsers
   agree on the address — as are link-local/unique-local/global-unicast IPv6
   with canonical ports/userinfo, so no valid target is lost.
   **IPv4-embedded IPv6 rejection:** the IPv4-mapped rule only catches the
   `groups[5] == 0xffff` special case, but `Uri.tryParse` reports ANY
   dotted-quad-embedded IPv6 literal as an opaque, non-empty HTTPS host:
   `::192.168.1.1` (IPv4-compatible), `::ffff:0:192.168.1.1` (translated) and
   `2001:db8::192.168.1.1` (a real prefix followed by an embedded quad). A
   browser/WebView (WHATWG URL) resolves the embedded IPv4 address (or a
   different IPv6 literal), so one raw URI names two authorities; under a stale
   flag + test opt-in that parser differential could grant in-app rendering and
   self-signed acceptance on a mismatched/internal host. A real IPv6 literal is
   written in pure hex groups, so every dotted form fails closed while pure-hex
   loopback, link-local, unique-local, global-unicast and the pure-hex mapped
   form (still caught by the groups check) stay launchable — no valid target
   lost.
   **NFKC mark-introducing authority rejection:** the encoded-combining-mark
   rule rejects code points in Unicode category M, but a family of
   compatibility/spacing code points are NOT marks themselves while their
   NFKC normalisation introduces one — spacing diacritics (U+00B4 ACUTE
   ACCENT -> SPACE + U+0301, U+02D8..U+02DD, U+0384/U+0385, the Greek tonos/
   dasia forms), the halfwidth voiced sound marks (U+FF9E/U+FF9F, U+309B/
   U+309C), Indic/Hebrew base+mark compositions (U+0958..U+095F, U+FB1D..U+FB4E)
   and musical-symbol compositions (U+1D15E..U+1D164). They are invisible to
   the C/Z rule (not category C/Z), the category-M rule (not a mark), and the
   NFKC-to-ASCII rule (their NFKC is not entirely ASCII), so `Uri.tryParse`
   reports a non-empty HTTPS host that passes a purely syntactic re-check. A
   decode+IDNA launcher recomposes the introduced mark with a preceding base
   letter into a DIFFERENT precomposed character, resolving a different
   authority; under a stale secure flag + test opt-in that differential could
   grant in-app rendering and self-signed acceptance on a spoofed host. All
   143 such code points (Unicode 16.0.0) fail closed. No real BMC host uses a
   spacing diacritic, halfwidth sound mark or compatibility composition, so
   no valid target is lost — pct-encoded UTF-8 that NFKC-folds to a stable
   non-ASCII character (e-acute, euro, emoji) stays launchable.
   **IDNA-ignored Hangul filler rejection:** the four Hangul filler code points
   (U+115F CHOSEONG, U+1160 JUNGSEONG, U+3164 HANGUL, U+FFA0 HALFWIDTH HANGUL
   FILLER) are Unicode category `Lo` — not Separator/Other, not a combining
   mark — and NFKC-normalise to non-ASCII, so they evade every confusable rule
   above. UTS-46 IDNA nevertheless maps each to NOTHING: a decode+IDNA launcher
   resolves `https://bmc%E3%85%A4.example/console` as `bmc.example`, a DIFFERENT
   authority than `Uri.tryParse` reports (`bmc%E3%85%A4.example`). Under a stale
   secure flag + test opt-in that parser differential could grant in-app
   rendering and self-signed acceptance on a mismatched/spoofed host. All four
   fail closed (either hex case, including in userinfo/leading/trailing
   positions); ordinary pct-encoded UTF-8 host bytes (e-acute, euro, emoji),
   punycode hosts and the same escapes in the path/query stay launchable — no
   valid target lost.
   Covered by targeted tests across the defense-in-depth re-validation
   groups (scheme/host/malformed-authority parity + control-character +
   raw-space + Unicode-whitespace/invisible + raw-backslash + RFC-3986
   unwise-char + malformed-percent-encoding + raw non-ASCII authority + encoded
   authority-delimiter + encoded control-octet + encoded unwise-char +
   encoded Unicode separator/invisible + encoded compatibility-confusable
   delimiter + extended
   compatibility-confusable delimiter + IDNA dot-confusable rejection +
   IDNA middle-dot confusable rejection + NFKC-to-ASCII compatibility
   letter/digit rejection + mathematical alphanumeric rejection + NFKC
   vulgar-fraction confusable rejection +
   encoded combining-mark rejection + degenerate dot-host rejection +
   double-encoded authority-delimiter rejection + encoded authority-dot
   rejection + malformed-UTF-8 authority rejection + encoded ASCII space
   rejection + encoded unreserved-ASCII rejection + encoded sub-delimiter
   rejection + non-canonical numeric-host
   rejection (incl. trailing-dot absolute-FQDN numeric spellings) + mixed
   ends-in-number host rejection + empty
   DNS-label rejection + out-of-range port rejection + signed and overflow
   port rejection + IPv4-mapped/IPvFuture IPv6 rejection + IPv4-embedded IPv6
   rejection + NFKC mark-introducing authority rejection (spacing diacritics,
   halfwidth sound marks and base+mark compositions that are not category M
   yet NFKC-decompose to a combining mark, so they recompose with a preceding
   base into a different host under a decode+IDNA launcher) + IDNA-ignored
   Hangul filler authority rejection (U+115F/U+1160/U+3164/U+FFA0 — category
   `Lo`, NFKC non-ASCII, silently dropped by UTS-46 IDNA so a launcher contacts
   a different authority) + NFKC superscript-letter authority rejection (U+2071
   SUPERSCRIPT LATIN SMALL LETTER I — category `Lm`, NFKC-normalises to ASCII
   `i`, sitting between the U+2070 digit and the U+2074..U+2079 superscript
   digits the digit family otherwise covers; a decode+IDNA launcher resolves a
   different ASCII authority, so every escape form fails closed) + NFKC
   delimiter-introducing authority rejection (U+013F/U+0140 L WITH MIDDLE DOT
   -> U+00B7 -> '.', the SQUARE "M OVER S" units U+33A7/33A8/33AE/33AF/33C6/
   33DE/33DF -> U+2215 -> '/', and U+FE12 vertical ideographic full stop ->
   U+3002 -> '.': non-ASCII code points whose NFKC introduces a structural
   delimiter confusable rather than being one, so they evade both the direct
   delimiter set and the complete NFKC-to-ASCII table yet a decode+IDNA launcher
   resolves a different authority; every escape form fails closed, delimiter-
   free UTF-8 such as e-acute/euro/emoji stays launchable)).
   **Blank-URI target normalization:** a whitespace-only URI is "no usable
   target" (`KvmConsoleLaunchPlan.targetUri`) — the copy-only fallback must
   surface `null`, never a whitespace string, under any policy (including the
   test-only opt-in). A non-blank URI that merely fails the secure check keeps
   its raw copy target, so the flag-off external-browser + copy path still
   works unchanged.

## What remains gated (not done here)

A real WebView plugin and kernel requires recorded per-target validation
evidence (render an HTTPS console, reject certs by default, test-only
self-signed acceptance, no plaintext downgrade, flag-off fallback). No such
plugin exists on the available Linux/desktop target (see
`WEBVIEW_TLS_MATRIX.md`), so no `pubspec.yaml` change and no dependency bump is
made. Until evidence exists, the flag stays off and the external-browser + copy
path remains the only rendering route.
