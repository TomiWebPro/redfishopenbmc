/// Concrete, dependency-free launch plan for the optional in-app KVM console
/// (rf-platform RP-2).
///
/// RP-1 defined the reversible opt-in policy ([KvmWebViewPolicy]) and the route
/// decision ([resolveRenderRoute]). This module turns that decision into a
/// concrete, testable plan: the render route, the exact URI a launcher may use,
/// and the single most dangerous boolean — whether a self-signed certificate
/// may be accepted.
///
/// It intentionally imports **no** WebView/protocol plugin and opens no channel:
/// per the department hard rule, a platform WebView is only permitted with
/// recorded per-target validation evidence (see `WEBVIEW_TLS_MATRIX.md`, RP-2
/// gate). Until then this plan is the flag-gated decision layer a future WebView
/// will consume, and — with the flag off — it proves the external-browser + copy
/// fallback still works unchanged. See `LAUNCH_FALLBACK.md`.
library;

import 'dart:convert';

import 'webview_policy.dart';

/// An immutable, concrete plan for handing a console to a renderer or fallback.
class KvmConsoleLaunchPlan {
  const KvmConsoleLaunchPlan._({
    required this.route,
    required this.targetUri,
    required this.acceptSelfSigned,
  });

  /// The chosen render/fallback route.
  final KvmConsoleRenderRoute route;

  /// The trimmed URI a launcher may open or the user may copy, or `null` when
  /// there is no usable target.
  final String? targetUri;

  /// Whether a self-signed certificate may be accepted for this launch.
  ///
  /// True only for the test-only opt-in, on HTTPS, when actually rendering
  /// in-app. Never true for the external-browser or copy-only fallbacks, and
  /// never true under the production default — production TLS is never weakened.
  final bool acceptSelfSigned;

  /// Whether this plan renders in an embedded WebView (opt-in only).
  bool get isInApp => route == KvmConsoleRenderRoute.inAppWebView;

  /// Whether this plan hands a secure HTTPS URI to an external browser.
  bool get isExternalBrowser => route == KvmConsoleRenderRoute.externalBrowser;

  /// Whether this plan only surfaces the URI/copy path.
  bool get isCopyOnly => route == KvmConsoleRenderRoute.copyOnly;
}

/// Returns `true` only when [uri] is an HTTPS URI with a non-empty host.
///
/// Defense in depth: the caller-supplied `hasSecureUri` signal may be stale or
/// inaccurate, so the raw URI string is independently checked before any
/// security-sensitive decision (in-app rendering / self-signed acceptance).
///
/// This uses the very same parser as the `KvmConsole.hasSecureLaunchUri`
/// contract it mirrors (`Uri.tryParse` + `scheme == 'https'` + non-empty
/// `host`), so the re-validation can never be more permissive than production.
/// A hand-rolled authority scan is deliberately avoided: it can call a
/// malformed target "secure" (e.g. an invalid/duplicated port such as
/// `https://bmc.example:notaport/console`) that `Uri.tryParse` rejects, which
/// under a stale secure flag could reach in-app self-signed acceptance.
/// Host-less forms such as `https:///console`, `https://?q`, `https://#f` and
/// `https://user@/` also fail closed. Scheme matching is case-insensitive
/// (Dart normalises it), and legitimate userinfo/port URIs remain secure.
///
/// Fail-closed hardening beyond parity: `Uri.tryParse` silently
/// percent-encodes control characters, the ASCII space (0x20) AND Unicode
/// separator / invisible format characters (e.g. NBSP `U+00A0`, zero-width
/// space, line/paragraph separators, ideographic space, BOM) into the host or
/// path rather than rejecting them, so a purely syntactic
/// `scheme == 'https' && host.isNotEmpty` check can call such a target
/// "secure". Handing a CRLF/NUL-bearing URI to a launcher risks header/URI
/// injection; a raw or Unicode space inside the authority (e.g.
/// `https://bmc.exa mple/console` -> host `bmc.exa%20mple`, or an embedded NBSP
/// `https://bmc<U+00A0>.example/console` -> host `bmc%C2%A0.example`) yields a
/// non-empty but malformed/spoofed host; under a stale secure flag + test
/// opt-in any of these could reach in-app rendering and self-signed
/// acceptance. None of these characters are valid raw in a URI (they must be
/// percent-encoded), and an embedded one is not removed by `String.trim()`.
/// They are therefore all rejected via the Unicode `Separator` (Z) and
/// `Other` (C) general categories — a principled category rule rather than an
/// ASCII-only scan — which is stricter than the model but never more
/// permissive, so no valid (properly encoded) target is lost. Non-ASCII
/// characters outside those categories (e.g. an emoji in the path) remain
/// launchable.
///
/// Raw backslash (U+005C) is rejected for the same reason: it is not a legal
/// URI character (RFC 3986; a literal backslash must be `%5C`), but
/// `Uri.tryParse` folds `\` into `/`, so e.g.
/// `https://bmc.example\@evil.com/console` parses with the *trusted* host
/// `bmc.example` while a launcher that does not fold backslashes may resolve a
/// different authority. Under a stale secure flag + test opt-in that parser
/// differential could grant in-app rendering and self-signed acceptance on a
/// malformed/spoofed authority. Rejecting raw backslashes loses no valid target
/// (a literal backslash must be `%5C`, which stays launchable).
///
/// The RFC 3986 "unwise" ASCII characters (`"` `<` `>` `^` `` ` `` `{` `|` `}`)
/// are rejected for the same reason: they are not in the `unreserved` /
/// `reserved` sets, so a literal one must be percent-encoded (`%22`, `%3C`,
/// ...), yet `Uri.tryParse` silently percent-encodes a raw occurrence into the
/// authority/path instead of rejecting it — e.g.
/// `https://bmc<example/console` parses with scheme `https` and the non-empty
/// host `bmc%3Cexample`, passing a purely syntactic re-check. Under a stale
/// secure flag + test opt-in that parser differential could reach in-app
/// rendering and self-signed acceptance on a malformed/spoofed authority.
/// Rejecting them raw loses no valid target (their `%XX` forms stay
/// launchable), and legal gen/sub-delims (`[` `]` `&` `=` ...) are unaffected.
///
/// A malformed percent-encoding is rejected for the same reason: RFC 3986
/// requires `pct-encoded = "%" HEXDIG HEXDIG`, but `Uri.tryParse` silently
/// percent-encodes a bare or malformed `%` into the host rather than rejecting
/// it — e.g. `https://bmc.example%/console` yields host `bmc.example%25` and
/// `https://bmc.example%ZZ/console` yields `bmc.example%25zz`, both still
/// passing a purely syntactic re-check (a bare `%` is not in the forbidden
/// char class, because valid `%XX` escapes must remain launchable). Under a
/// stale secure flag + test opt-in that parser differential could grant in-app
/// rendering and self-signed acceptance on a malformed/spoofed host. Every
/// `%` not followed by exactly two hex digits fails closed, while valid `%XX`
/// (either hex case) stays launchable — no valid target is lost.
///
/// A raw non-ASCII authority is rejected for the same reason: RFC 3986 URIs are
/// ASCII-only (a raw non-ASCII character must be pct-encoded, or punycode in a
/// host), but `Uri.tryParse` silently pct-encodes a raw non-ASCII host/userinfo
/// into a non-empty host (e.g. Cyrillic 'a' U+0430 -> `bmc%D0%B0.example`),
/// passing a purely syntactic re-check. A raw Unicode authority is a
/// host-spoofing risk (confusable/homograph labels); under a stale secure flag +
/// test opt-in it could reach in-app rendering and self-signed acceptance on a
/// malformed/spoofed host. The rule is scoped to the authority, so an ASCII
/// punycode/pct-encoded host and non-ASCII path/query text stay launchable — no
/// valid target is lost.
///
/// A percent-encoded structural delimiter in the authority is rejected for the
/// same reason: RFC 3986 gen-delims (`:` `/` `?` `#` `[` `]` `@`) and the
/// backslash decide where the authority ends and which host is contacted, and
/// consumers disagree on whether to percent-decode before or after splitting
/// the authority. `Uri.tryParse` keeps `%40` inside the host
/// (`https://bmc.example%40evil.com/console` -> host `bmc.example%40evil.com`,
/// still non-empty), while a launcher that decodes first reads `@evil.com` as
/// the real userinfo/host. Under a stale secure flag + test opt-in that parser
/// differential could grant in-app rendering and self-signed acceptance on a
/// spoofed authority. Every pct-encoded gen-delim/backslash (either hex case)
/// in the authority fails closed; the rule is scoped so encoded delimiters in
/// the path/query and valid pct-encoded non-delimiter host bytes (e.g.
/// `bmc%C3%A9.example`) stay launchable — no valid target is lost.
///
/// A percent-encoded C0 control or DEL octet is rejected for the same reason:
/// it is a *valid* `%XX` escape (so the malformed-percent rule does not catch
/// it) and contains no raw forbidden character, yet `Uri.tryParse` keeps it
/// encoded and still reports an HTTPS URI with a non-empty host. Such octets
/// are classic parser-differential / injection vectors: a NUL (`%00`)
/// truncates the host in many consumers (`bmc.example%00.evil.com` reads as
/// `bmc.example`), CRLF (`%0D%0A`) enables header/URI injection, and other C0
/// bytes confuse authority splitting. Under a stale secure flag + test opt-in
/// that could grant in-app rendering and self-signed acceptance on a
/// spoofed/malformed host. Every pct-encoded 0x00-0x1F or 0x7F octet fails
/// closed (either hex case), while non-control escapes (`%20`, `%2F`, UTF-8
/// bytes, ...) stay launchable — no valid target is lost.
///
/// A percent-encoded multi-byte UTF-8 character that decodes to a Unicode
/// `Separator` (Z) or `Other` (C) code point is rejected for the same reason:
/// it is a valid `%XX` escape (so the malformed-percent rule misses it), is not
/// a single-byte C0/DEL octet (so the encoded-control rule misses it), and has
/// no raw non-ASCII (so the raw-authority rule misses it), yet `Uri.tryParse`
/// keeps it encoded and reports a "secure" HTTPS host. A decode-first launcher
/// turns e.g. `%C2%A0` (NBSP, Zs) into an invisible separator in the host, or
/// `%E2%80%8B` (zero-width space, Cf) / `%C2%85` (NEL, Cc) into an invisible
/// control — a parser-differential / host-spoofing vector that under a stale
/// flag + test opt-in could reach in-app rendering and self-signed acceptance.
/// Only decoded non-ASCII C/Z code points are rejected (ASCII escapes such as
/// `%20` and non-C/Z escapes such as `%C3%A9` stay launchable), so no valid
/// target is lost.
///
/// A percent-encoded non-ASCII code point that NFKC-normalises to an ASCII
/// structural delimiter (a "compatibility confusable") is rejected for the same
/// reason: it is a valid `%XX` escape that has no raw forbidden character, so
/// every earlier rule misses it, yet `Uri.tryParse` keeps it encoded while a
/// launcher applying IDNA/NFKC to the host (as browsers do) resolves a
/// different authority — `%EF%BC%8F` (fullwidth solidus) becomes `/`,
/// `%EF%BC%8E` (fullwidth full stop) becomes `.`, and so on. Under a stale
/// secure flag + test opt-in that parser differential could reach in-app
/// rendering and self-signed acceptance on a spoofed host. Only decoded code
/// points that normalise to a structural delimiter in the authority are
/// rejected; encoded non-delimiter non-ASCII (e-acute, euro, emoji) and
/// confusables in the path/query stay launchable, so no valid target is lost.
///
/// A degenerate, label-less authority is rejected for the same reason:
/// `Uri.tryParse` reports a host made only of dots (`https://./console`,
/// `https://../console`) as an HTTPS URI with a NON-EMPTY host, so the bare
/// `scheme == 'https' && host.isNotEmpty` check calls it "secure". It also
/// decodes a percent-encoded dot (`%2E`) in the host into a literal '.', so
/// `https://%2E%2E/console` likewise reports host `..`. There is no real BMC
/// host to contact (no DNS label at all), and a launcher may resolve `..` as a
/// relative/traversal path rather than a host. Under a stale secure flag +
/// test opt-in that could reach in-app rendering and self-signed acceptance on
/// a bogus host. A host with no character other than '.' therefore fails
/// closed; hosts with a real label (including an absolute FQDN trailing dot)
/// and IPv6 literals stay launchable — no valid target lost.
///
/// A percent-encoded percent sign (`%25`) in the authority is rejected for the
/// same reason: it bypasses the single-encoded-delimiter rule via
/// double-decoding. A launcher that decodes twice turns `%252F` into `%2F` and
/// then `/` (`%2540` -> `@`, `%252E` -> `.`), while `Uri.tryParse` keeps `%25`
/// encoded and reports a non-empty HTTPS host, so a purely syntactic re-check
/// calls it "secure". A literal `%` is never valid in a host, and the
/// double-decode parser differential could grant in-app rendering and
/// self-signed acceptance on a spoofed authority under a stale flag + test
/// opt-in. Every `%25` (either hex case) in the authority fails closed, while
/// `%25` in the path/query and valid pct-encoded UTF-8 host bytes (`%C3%A9`)
/// stay launchable — no valid target lost.
///
/// A percent-encoded ASCII domain-label dot (`%2E`) in the authority is
/// rejected for the same reason, with a sharper differential: unlike the
/// gen-delims above (which `Uri.tryParse` keeps encoded in the host),
/// `Uri.tryParse` DECODES `%2E` into a literal '.', so
/// `https://bmc.example%2Eevil.com/console` reports the host
/// `bmc.example.evil.com`. A launcher that does not percent-decode the host
/// resolves a different authority, so one raw URI can name two different hosts
/// — a decode-order host-spoofing vector. Under a stale secure flag + test
/// opt-in that could grant in-app rendering and self-signed acceptance on a
/// mismatched/spoofed host. A literal dot is always written as '.', so
/// rejecting `%2E` loses no valid target; scoped to the authority so `%2E` in
/// the path/query and valid pct-encoded UTF-8 host bytes stay launchable.
///
/// A percent-encoded octet sequence in the authority that is not well-formed
/// UTF-8 is rejected for the same reason: the encoded-control rule catches a
/// single C0/DEL octet and the encoded C/Z rule catches well-formed UTF-8
/// controls, but an invalid sequence (a lone C1 byte `%80`/`%9F`, an overlong
/// form `%C0%80`, a truncated multi-byte sequence `%E2%82`) decodes under
/// `utf8.decode(allowMalformed: true)` to U+FFFD (category So), slipping past
/// both. `Uri.tryParse` keeps such escapes encoded and reports a non-empty
/// HTTPS host, so a purely syntactic re-check calls it "secure" while a launcher
/// that decodes host bytes as Latin-1 (or does not validate UTF-8) sees
/// different, invisible/control bytes — a decode-differential / host-spoofing
/// vector. A valid URI percent-encodes well-formed UTF-8 (or ASCII), so
/// rejecting malformed UTF-8 in the authority loses no valid target; properly
/// encoded multi-byte text (e-acute, euro, emoji) stays launchable.
///
/// A pct-encoded ASCII space (`%20`) in the authority is rejected for the same
/// reason: it escapes every earlier rule. The raw-space/control rules see no
/// literal U+0020 (only the characters `%`, `2`, `0`); 0x20 is above the
/// C0/DEL range so [_encodedControlOctet] misses it; and it is ASCII so the
/// non-ASCII encoded-C/Z rule skips it. `Uri.tryParse` keeps `%20` encoded and
/// reports a non-empty HTTPS host, so a purely syntactic re-check calls it
/// "secure" — yet a launcher/browser that decodes the host first sees an
/// embedded space, which is a FORBIDDEN domain code point (WHATWG URL / IDNA):
/// the browser rejects or renormalises the host, resolving a *different*
/// authority than `Uri.tryParse` reported. Under a stale secure flag + test
/// opt-in that parser differential could grant in-app rendering and self-signed
/// acceptance on a malformed/spoofed host. A space is never valid in a host, so
/// every `%20` in the authority fails closed (including in userinfo and in
/// leading/trailing positions); scope is the authority so `%20` in the
/// path/query — the correct encoding of a space and harmless to which host is
/// contacted — stays launchable, losing no valid target.
///
/// A percent-encoded compatibility character that NFKC-normalises to an ASCII
/// letter or digit is rejected for the same reason: the fullwidth-ASCII rule
/// covers only the U+FF01..U+FF5E block, but IDNA/NFKC also folds other
/// compatibility characters to plain ASCII — U+212A KELVIN SIGN -> `K`, U+017F
/// LATIN SMALL LETTER LONG S -> `s`, the circled Latin letters U+24B6..U+24E9
/// -> A-Z/a-z, and the Roman numerals U+2160..U+217F -> ASCII letter sequences.
/// `Uri.tryParse` keeps each escape encoded and reports a non-empty HTTPS host,
/// so a purely syntactic re-check calls it "secure" — yet a launcher applying
/// IDNA/NFKC resolves a *different* ASCII authority. Under a stale secure flag
/// + test opt-in that parser differential could grant in-app rendering and
/// self-signed acceptance on a spoofed host. A real ASCII host is written in
/// ASCII (or punycode), never with compatibility look-alikes, so rejecting them
/// loses no valid target; encoded non-ASCII that NFKC-folds to non-ASCII
/// (e-acute, euro, emoji) stays launchable. Scoped to the authority.
///
/// A percent-encoded RFC 3986 *unreserved* ASCII character (ALPHA / DIGIT /
/// `-` / `.` / `_` / `~`) is rejected for the same reason: these characters
/// are unreserved, so they never need percent-encoding and a literal form
/// always exists. Writing one as `%XX` in the authority is non-canonical and
/// creates a decode-order differential: `Uri.tryParse` DECODES such an escape
/// into a *different* host string (`%62%6D%63` -> `bmc`, `%2D` -> `-`,
/// `%5F` -> `_`, `%7E` -> `~`) while a launcher that does not percent-decode
/// the host resolves a different authority — one raw URI naming two hosts.
/// (`%2E`, the domain-label dot, is already rejected by a dedicated rule;
/// this closes the rest of the unreserved set.) `Uri.tryParse` still reports
/// a non-empty HTTPS host after decoding, so a purely syntactic re-check
/// calls it "secure"; under a stale secure flag + test opt-in that parser
/// differential could grant in-app rendering and self-signed acceptance on a
/// mismatched/spoofed host. A real BMC host writes these characters
/// literally, so rejecting them loses no valid target; the rule is scoped to
/// the authority so encoded unreserved text in the path/query and legitimate
/// percent-encoded non-ASCII UTF-8 host bytes (`%C3%A9`) stay launchable.
///
/// A percent-encoded RFC 3986 sub-delim (`!` `$` `&` `'` `(` `)` `*` `+` `,`
/// `;` `=`) is rejected for the same decode-order reason. Sub-delims are legal
/// unescaped in a `reg-name`, so an encoded one is non-canonical: [Uri.tryParse]
/// keeps it encoded in the host (`bmc.example%21evil.com`) while a launcher
/// that decodes host bytes before DNS/IDNA resolves a DIFFERENT host
/// (`bmc.example!evil.com`) — one raw URI naming two hosts. Under a stale
/// secure flag + test opt-in that differential could grant in-app rendering and
/// self-signed acceptance on a mismatched authority. A real BMC host writes
/// these characters literally, so rejecting the encoded form loses no valid
/// target; the rule is scoped to the authority so encoded sub-delims in the
/// path/query and percent-encoded UTF-8 host bytes stay launchable, and a raw
/// sub-delim (no decode-order differential) stays launchable.
///
/// A percent-encoded "vulgar fraction" (Unicode category `No`) is rejected for
/// the same reason: its NFKC normalisation expands to a decimal digit, U+2044
/// FRACTION SLASH and another digit (e.g. U+00BD `1/2` -> `1` + U+2044 + `2`),
/// and IDNA/UTS-46 maps U+2044 to the ASCII `/` structural delimiter. A raw
/// occurrence is already caught by the raw non-ASCII authority rule, but the
/// percent-encoded form is not: [Uri.tryParse] keeps it verbatim in the host
/// (`https://bmc%C2%BD.example/console` -> host `bmc%C2%BD.example`) and reports
/// a non-empty HTTPS host, so a purely syntactic re-check calls it "secure",
/// while a decode+IDNA launcher resolves a different authority (`bmc1/2...`).
/// Under a stale secure flag + test opt-in that parser differential could grant
/// in-app rendering and self-signed acceptance on a spoofed/mismatched host.
/// These are the fraction code points whose NFKC expansion embeds U+2044; no
/// real BMC host uses a vulgar fraction (hosts are ASCII or punycode), so
/// rejecting them loses no valid target. Scoped to the authority — the same
/// escape in path/query/fragment stays launchable.
///
/// A percent-encoded Unicode *combining mark* (category M) is rejected for the
/// same reason: it is a valid `%XX` escape that every earlier rule misses, yet
/// [Uri.tryParse] keeps it encoded and reports a non-empty HTTPS host. A
/// launcher applying NFC/IDNA to the host (as browsers do) recomposes a base
/// letter + mark into a DIFFERENT precomposed character — `https://bmc%CC%81.example/`
/// decodes to `bmc` + U+0301 COMBINING ACUTE whose NFC form is `bmc` + U+00E9,
/// resolving a different authority than `Uri.tryParse` reported. Under a stale
/// secure flag + test opt-in that parser differential could grant in-app
/// rendering and self-signed acceptance on a mismatched/spoofed host. A real
/// BMC host is ASCII/punycode and never writes a combining mark, so rejecting
/// one loses no valid target; precomposed UTF-8 host bytes (e-acute, a Letter),
/// emoji and marks in the path/query stay launchable. Scoped to the authority.
///
/// A non-canonical numeric host is rejected for the same reason: legacy /
/// WHATWG URL parsers (browsers, WebViews) resolve `0x7f000001`, `2130706433`,
/// `127.1` and `0177.0.0.1` to IP literals (often loopback / internal), while
/// [Uri.tryParse] reports them as opaque DNS names with a non-empty host. A
/// purely syntactic re-check therefore calls such a target "secure", yet the
/// launcher contacts a DIFFERENT address than the authority Uri reported — an
/// SSRF-style parser-differential / host-spoofing vector that under a stale
/// secure flag + test opt-in could grant in-app rendering and self-signed
/// acceptance on a mismatched host. Only canonical dotted-quad IPv4 (four
/// 0-255 octets, no leading zeros), IPv6 literals and ordinary DNS names stay
/// launchable, so no real BMC target is lost (see [_isNonCanonicalNumericHost]).
/// The same numeric spellings with one trailing dot (`2130706433.`,
/// `0x7f000001.`) are rejected too: a WHATWG "ends in a number" check skips a
/// single trailing dot and still resolves them as IP literals, while a real
/// trailing-dot DNS name (`bmc.example.`) and canonical IPv4 stay launchable.
///
/// A host with an empty DNS label is rejected for the same reason: a leading
/// dot (`.bmc.example`), consecutive dots (`bmc..example`) or a double trailing
/// dot (`bmc.example..`) leaves an empty label between/around DNS labels.
/// [Uri.tryParse] reports such a string as a non-empty HTTPS host, so a purely
/// syntactic re-check calls it "secure" — yet a launcher may collapse the empty
/// label, reject the malformed name, or read the leading dot as a relative /
/// traversal reference, contacting a DIFFERENT authority than Uri reported.
/// Under a stale secure flag + test opt-in that parser differential could grant
/// in-app rendering and self-signed acceptance on a mismatched/spoofed host. A
/// real BMC host never has an empty label, so rejecting them loses no valid
/// target: a single-label host, an absolute FQDN with exactly one trailing dot,
/// canonical IPv4/IPv6 literals and punycode hosts stay launchable.
///
/// An out-of-range port (greater than the 16-bit TCP maximum, 65535) is rejected
/// for the same reason: [Uri.tryParse] accepts any non-negative decimal port and
/// reports an HTTPS URI with a non-empty host (e.g.
/// `https://bmc.example:99999/console` -> host `bmc.example`, port `99999`), so a
/// purely syntactic re-check calls it "secure". Browser / WebView (WHATWG URL)
/// parsers reject an out-of-range port outright, and other launchers may wrap it
/// modulo 65536 to a DIFFERENT service — a parser differential that under a
/// stale secure flag + test opt-in could grant in-app rendering and self-signed
/// acceptance on a malformed/mismatched authority. A real BMC console port is
/// always 0..65535, so rejecting larger values loses no valid target; an absent
/// or empty port (default), an in-range port, userinfo and IPv6 hosts stay
/// launchable.
///
/// A non-canonical port token (signed, negative, or so large that reading
/// `Uri.port` overflows) is rejected for the same reason, from the RAW authority
/// before `Uri.port` is ever read: [Uri.tryParse] accepts `:-1` (reporting a
/// negative port), silently ignores the sign in `:+443`, and accepts a
/// 20-digit port whose `Uri.port` getter then THROWS [FormatException], while a
/// WHATWG parser rejects signed/negative ports and ports above the 16-bit
/// maximum. Under a stale secure flag + test opt-in that differential could
/// grant in-app self-signed acceptance on a malformed/mismatched authority or
/// crash the caller. A real BMC console port is canonical ASCII digits in
/// 0..65535, so rejecting anything else loses no valid target; absent/empty
/// ports, leading zeros, userinfo and IPv6 hosts stay launchable. The parsed
/// port is also range-checked with a guarded read as defense in depth.
final RegExp _rawUriForbiddenChars =
    RegExp(r'[\\"<>{|}`^\p{C}\p{Z}]', unicode: true);

/// Matches a `%` that does not begin a valid `%XX` escape (RFC 3986
/// `pct-encoded = "%" HEXDIG HEXDIG`). Valid escapes contain no bare `%`.
final RegExp _malformedPercentEncoding = RegExp(r'%(?![0-9A-Fa-f]{2})');

/// Matches a percent-encoded octet whose value is a C0 control (0x00-0x1F) or
/// DEL (0x7F). Hex digits are case-insensitive. Such an octet is a *valid*
/// `%XX` escape (so the malformed-percent rule does not catch it) and contains
/// no raw forbidden character, yet it is never valid in a launchable URI and
/// is a classic host-truncation / injection vector (see below).
final RegExp _encodedControlOctet =
    RegExp(r'%(?:0[0-9A-Fa-f]|1[0-9A-Fa-f]|7[Ff])');

/// Unicode `Separator` (Z) and `Other` (C) categories — the same principled
/// category rule used for raw characters in [_rawUriForbiddenChars], applied
/// here to the *percent-decoded* content (non-ASCII only; see
/// [_hasEncodedUnicodeControlOrSeparator]).
final RegExp _unicodeOtherOrSeparator = RegExp(r'[\p{C}\p{Z}]', unicode: true);

/// Unicode `Mark` (M) category — combining marks that NFC-normalise together
/// with a preceding base character into a DIFFERENT precomposed character
/// (e.g. `e` + U+0301 COMBINING ACUTE -> U+00E9 `é`). A launcher applying
/// NFC/IDNA to an internationalised host (as browsers do) therefore resolves a
/// different authority than [Uri.tryParse], which keeps the percent-encoded
/// form in the host — a parser-differential / host-spoofing vector.
final RegExp _unicodeMark = RegExp(r'\p{M}', unicode: true);

/// Matches any non-ASCII code unit. RFC 3986 URIs are ASCII-only: a raw
/// non-ASCII character must be pct-encoded (or punycode-encoded in a host).
final RegExp _nonAscii = RegExp(r'[^\x00-\x7F]');

/// Returns the raw authority (userinfo + host + port, i.e. the part between
/// `://` and the first `/`, `?` or `#`), or `null` when there is no `://` marker.
///
/// Security checks must run on the *raw* authority string: `Uri.tryParse`
/// silently rewrites parts of it (pct-encoding non-ASCII, folding backslashes,
/// keeping pct-encoded delimiters in the host), so inspecting the parsed URL
/// cannot detect these parser differentials. Scoping to the authority (the
/// TLS-sensitive part) keeps legitimate path/query text launchable.
String? _authorityOf(String uri) {
  final int marker = uri.indexOf('://');
  if (marker < 0) return null; // no authority; Uri parse fails closed below
  const int authorityStart = 3; // length of '://'
  final int start = marker + authorityStart;
  int end = uri.length;
  for (int i = start; i < uri.length; i++) {
    final String char = uri[i];
    if (char == '/' || char == '?' || char == '#') {
      end = i;
      break;
    }
  }
  return uri.substring(start, end);
}

/// Returns `true` when the raw authority contains a non-ASCII character.
///
/// The check must run on the *raw* string: `Uri.tryParse` silently pct-encodes a
/// raw non-ASCII authority into the host (e.g. Cyrillic 'a' U+0430 ->
/// `bmc%D0%B0.example`), so inspecting the parsed host cannot detect it. This is
/// scoped to the authority (the TLS-sensitive part) so non-ASCII path/query text
/// — which does not affect which host is contacted — stays launchable.
bool _authorityHasNonAscii(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  return _nonAscii.hasMatch(authority);
}

/// Matches a percent-encoded RFC 3986 gen-delim (`:` `/` `?` `#` `[` `]` `@`)
/// or a percent-encoded backslash. Hex digits are case-insensitive.
///
/// These characters are structural: they decide where the authority ends and
/// which host is contacted. Percent-encoding one in the authority is a
/// host-confusion vector because consumers disagree on decode order —
/// `Uri.tryParse` keeps `%40` in the host (`bmc.example%40evil.com`) while a
/// launcher that decodes before splitting the authority reads `@evil.com` as
/// userinfo/host. A purely syntactic re-check would call such a target "secure".
final RegExp _encodedAuthorityDelimiter =
    RegExp(r'%(?:40|2F|5C|3F|23|3A|5B|5D)', caseSensitive: false);

/// Returns `true` when the raw authority contains a percent-encoded structural
/// delimiter (RFC 3986 gen-delims or backslash).
///
/// Scoped to the authority so percent-encoded delimiters in the path/query —
/// which do not affect which host is contacted — stay launchable, and so valid
/// percent-encoded non-delimiter bytes in a host (e.g. `bmc%C3%A9.example`) are
/// not lost. Stricter than the model, never more permissive.
bool _authorityHasEncodedDelimiter(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  return _encodedAuthorityDelimiter.hasMatch(authority);
}

/// Matches a percent-encoded percent sign (`%25`, either hex case).
///
/// A literal `%` is not a legal character in a host, and — more importantly —
/// `%25` enables DOUBLE-decoding parser differentials that bypass
/// [_encodedAuthorityDelimiter]: a launcher that decodes twice turns
/// `bmc.example%252Fevil` into `bmc.example%2Fevil` and then `bmc.example/evil`
/// (`%252F` -> `%2F` -> `/`, `%2540` -> `@`, `%252E` -> `.`). `Uri.tryParse`
/// keeps `%25` encoded and reports a non-empty HTTPS host, so a purely
/// syntactic re-check calls it "secure"; under a stale secure flag + test
/// opt-in that could grant in-app rendering and self-signed acceptance on a
/// spoofed authority. Rejecting `%25` in the authority loses no valid target
/// (a literal `%` is never valid in a host, while pct-encoded UTF-8 host bytes
/// such as `%C3%A9` are unaffected). Scoped to the authority so `%25` in the
/// path/query stays launchable.
final RegExp _encodedPercent = RegExp(r'%25', caseSensitive: false);

/// Returns `true` when the raw authority contains a percent-encoded percent
/// sign (`%25`), a double-decoding host-spoofing vector (see [_encodedPercent]).
bool _authorityHasEncodedPercent(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  return _encodedPercent.hasMatch(authority);
}

/// Matches a percent-encoded ASCII domain-label dot (`%2E`, either hex case).
///
/// The encoded-delimiter rule blocks RFC 3986 gen-delims and backslash, but not
/// the '.' that separates DNS labels. Unlike those delimiters — which
/// [Uri.tryParse] keeps encoded in the host — `Uri.tryParse` DECODES `%2E` into
/// a literal '.', silently changing the reported host (e.g.
/// `https://bmc.example%2Eevil.com/console` reports host
/// `bmc.example.evil.com`). A launcher that does not percent-decode the host
/// resolves a DIFFERENT authority, so the same raw URI can name two different
/// hosts — a parser-differential / host-spoofing vector. Under a stale secure
/// flag + test opt-in that could grant in-app rendering and self-signed
/// acceptance on a mismatched/spoofed host. Rejecting a raw ASCII dot written
/// as `%2E` loses no valid target (a literal dot is always written as '.',
/// which stays launchable). Scoped to the authority so `%2E` in the path/query
/// and valid pct-encoded UTF-8 host bytes (`%C3%A9`) stay launchable.
final RegExp _encodedDot = RegExp(r'%2E', caseSensitive: false);

/// Returns `true` when the raw authority contains a percent-encoded ASCII dot
/// (`%2E`), a decode-order host-spoofing vector (see [_encodedDot]).
bool _authorityHasEncodedDot(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  return _encodedDot.hasMatch(authority);
}

/// Matches a percent-encoded ASCII space (`%20`).
///
/// A space is a FORBIDDEN domain code point in a host, but `Uri.tryParse`
/// keeps `%20` encoded and still reports a non-empty HTTPS host, so a purely
/// syntactic re-check calls it "secure" while a decode-first launcher sees an
/// embedded space in the host and resolves/rejects a different authority. Scope
/// to the authority so `%20` in the path/query (its correct encoding) stays
/// launchable.
final RegExp _encodedAsciiSpace = RegExp(r'%20');

/// Returns `true` when the raw authority contains a percent-encoded ASCII space
/// (`%20`), a forbidden-in-host / parser-differential vector.
bool _authorityHasEncodedSpace(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  return _encodedAsciiSpace.hasMatch(authority);
}

/// Matches a percent-encoded RFC 3986 sub-delim (`!` `$` `&` `'` `(` `)` `*` `+`
/// `,` `;` `=`). Hex digits are case-insensitive.
///
/// Sub-delims are legal unescaped in a `reg-name`, so a literal form always
/// exists and percent-encoding one is non-canonical. `Uri.tryParse` keeps such
/// an escape encoded in the host (`bmc.example%21evil.com`) while a
/// launcher that percent-decodes host bytes before DNS/IDNA resolution sees a
/// DIFFERENT host (`bmc.example!evil.com`) — one raw URI naming two hosts.
final RegExp _encodedSubDelimiter =
    RegExp(r'%(?:21|24|26|27|28|29|2A|2B|2C|3B|3D)', caseSensitive: false);

/// Returns `true` when the raw authority contains a percent-encoded RFC 3986
/// sub-delimiter, a decode-order host-spoofing vector (see
/// [_encodedSubDelimiter]).
///
/// Scoped to the authority so percent-encoded sub-delims in the path/query
/// (their correct encoding) and legitimate percent-encoded UTF-8 host bytes
/// (e-acute, euro, emoji) stay launchable. Stricter than the model, never more
/// permissive; a real BMC host writes these characters literally, so no valid
/// target is lost. Raw (unencoded) sub-delims are legal in a host and create no
/// decode-order differential, so they stay launchable.
bool _authorityHasEncodedSubDelimiter(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  return _encodedSubDelimiter.hasMatch(authority);
}

/// Returns the numeric value of a single ASCII hex digit, or `null`.
int? _hexDigit(String char) {
  final int code = char.codeUnitAt(0);
  if (code >= 0x30 && code <= 0x39) return code - 0x30; // '0'-'9'
  if (code >= 0x41 && code <= 0x46) return code - 0x41 + 10; // 'A'-'F'
  if (code >= 0x61 && code <= 0x66) return code - 0x61 + 10; // 'a'-'f'
  return null;
}

/// Returns `true` when [byte] is an RFC 3986 unreserved ASCII octet:
/// `ALPHA / DIGIT / "-" / "." / "_" / "~"`.
///
/// These are the ASCII bytes that `Uri.tryParse` DECODES from `%XX` in a host
/// (reserved/sub-delim escapes stay encoded), so percent-encoding one in the
/// authority is a non-canonical decode-order host-spoofing vector (see the
/// module header).
bool _isUnreservedAsciiOctet(int byte) {
  if (byte >= 0x30 && byte <= 0x39) return true; // '0'-'9'
  if (byte >= 0x41 && byte <= 0x5A) return true; // 'A'-'Z'
  if (byte >= 0x61 && byte <= 0x7A) return true; // 'a'-'z'
  return byte == 0x2D || // '-'
      byte == 0x2E || // '.'
      byte == 0x5F || // '_'
      byte == 0x7E; // '~'
}

/// Returns `true` when the raw authority contains a percent-encoded RFC 3986
/// unreserved ASCII character (ALPHA / DIGIT / `-` / `.` / `_` / `~`).
///
/// Such an escape is non-canonical (a literal form always exists) and is
/// decoded by `Uri.tryParse` into a different host string than a launcher that
/// does not percent-decode — a decode-order host-spoofing differential. The
/// check runs on the raw authority and is scoped to it, so encoded unreserved
/// text in the path/query and legitimate percent-encoded non-ASCII host bytes
/// (e-acute, euro, emoji) stay launchable. Stricter than the model, never more
/// permissive. The `%2E` (dot) case is also caught here (and by a dedicated
/// rule); the redundant check is harmless.
bool _authorityHasEncodedUnreservedAscii(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  for (int i = 0; i + 2 < authority.length; i++) {
    if (authority[i] != '%') continue;
    final int? hi = _hexDigit(authority[i + 1]);
    final int? lo = _hexDigit(authority[i + 2]);
    if (hi == null || lo == null) continue; // malformed `%` handled elsewhere
    if (_isUnreservedAsciiOctet((hi << 4) | lo)) return true;
  }
  return false;
}

/// Returns `true` when [uri] carries a percent-encoded multi-byte UTF-8
/// character that decodes to a Unicode `Separator` (Z) or `Other` (C) code
/// point.
///
/// Such an escape is a *valid* `%XX` sequence (so the malformed-percent rule
/// does not catch it), is not a single-byte C0/DEL octet (so
/// [_encodedControlOctet] does not catch it), and contains no raw non-ASCII
/// character (so the raw-authority rule does not catch it). `Uri.tryParse`
/// keeps it encoded and still reports an HTTPS URI with a non-empty host, so a
/// purely syntactic re-check calls it "secure" — yet a launcher that
/// percent-decodes first turns e.g. `%C2%A0` (NBSP, Zs) into an invisible
/// separator in the host, or `%E2%80%8B` (zero-width space, Cf) / `%C2%85`
/// (NEL, Cc) into an invisible control: a parser-differential / host-spoofing
/// vector. Under a stale secure flag + test opt-in that could reach in-app
/// rendering and self-signed acceptance on a malformed/spoofed host.
///
/// Only decoded **non-ASCII** code points are inspected: ASCII escapes are
/// handled by earlier rules (C0/DEL by [_encodedControlOctet]; `%20` is the
/// correct encoding of a space and must stay launchable). Encoded non-C/Z
/// characters (e.g. `%C3%A9` e-acute, a Letter; emoji, a Symbol) stay
/// launchable — stricter than the model, never more permissive, no valid
/// target lost.
bool _hasEncodedUnicodeControlOrSeparator(String uri) {
  final List<int> bytes = <int>[];
  for (int i = 0; i < uri.length; i++) {
    final String char = uri[i];
    if (char == '%' && i + 2 < uri.length) {
      final int? hi = _hexDigit(uri[i + 1]);
      final int? lo = _hexDigit(uri[i + 2]);
      if (hi != null && lo != null) {
        bytes.add((hi << 4) | lo);
        i += 2;
        continue;
      }
    }
    // A raw character here is ASCII (raw non-ASCII/forbidden chars were
    // rejected by earlier rules); keep its byte value so a percent-encoded
    // UTF-8 sequence is decoded in the correct byte context.
    bytes.add(char.codeUnitAt(0));
  }
  final String decoded = utf8.decode(bytes, allowMalformed: true);
  for (final int rune in decoded.runes) {
    if (rune < 0x80) continue; // ASCII handled by earlier rules
    if (_unicodeOtherOrSeparator.hasMatch(String.fromCharCodes(<int>[rune]))) {
      return true;
    }
  }
  return false;
}

/// Returns `true` when the raw authority carries a percent-encoded Unicode
/// `Mark` (category M) code point.
///
/// A percent-encoded combining mark is a *valid* `%XX` escape (so the
/// malformed-percent and encoded-control rules miss it), is not a C0/DEL octet
/// (so [_encodedControlOctet] misses it), is not a Separator/Other (so
/// [_hasEncodedUnicodeControlOrSeparator] misses it), and has no raw non-ASCII
/// (so the raw-authority rule misses it), yet [Uri.tryParse] keeps it encoded
/// and reports a non-empty HTTPS host, so a purely syntactic re-check calls it
/// "secure". A launcher applying NFC/IDNA to the host (as browsers do)
/// recomposes a base letter + combining mark into a different precomposed
/// character — e.g. `https://bmc%CC%81.example/` decodes to `bmc\u{0301}.example`
/// whose NFC form is `bmc\u{00E9}.example` — resolving a DIFFERENT authority
/// than [Uri.tryParse] reported. Under a stale secure flag + test opt-in that
/// parser differential could grant in-app rendering and self-signed acceptance
/// on a mismatched/spoofed host.
///
/// Only **non-ASCII** marks are inspected: ASCII has no combining marks, and a
/// raw non-ASCII authority is rejected earlier. Scoped to the authority so
/// marks in the path/query (which cannot forge a host) stay launchable, and
/// precomposed UTF-8 host bytes (e-acute, a Letter) and other non-mark escapes
/// (emoji, a Symbol) stay launchable — stricter than the model, never more
/// permissive, no valid target lost.
bool _authorityHasEncodedCombiningMark(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  final List<int> bytes = <int>[];
  for (int i = 0; i < authority.length; i++) {
    final String char = authority[i];
    if (char == '%' && i + 2 < authority.length) {
      final int? hi = _hexDigit(authority[i + 1]);
      final int? lo = _hexDigit(authority[i + 2]);
      if (hi != null && lo != null) {
        bytes.add((hi << 4) | lo);
        i += 2;
        continue;
      }
    }
    // Raw characters here are ASCII (raw non-ASCII/forbidden chars were
    // rejected by earlier rules); keep the byte so an encoded multi-byte mark
    // is decoded in the correct UTF-8 byte context.
    bytes.add(char.codeUnitAt(0));
  }
  final String decoded = utf8.decode(bytes, allowMalformed: true);
  for (final int rune in decoded.runes) {
    if (rune < 0x80) continue; // ASCII has no combining marks
    if (_unicodeMark.hasMatch(String.fromCharCodes(<int>[rune]))) {
      return true;
    }
  }
  return false;
}

/// Non-ASCII code points whose Unicode NFKC normalisation is an ASCII RFC 3986
/// structural delimiter: gen-delims (`:` `/` `?` `#` `[` `]` `@`), backslash,
/// or the domain-label full stop (`.`). These are "compatibility confusables":
/// a launcher that applies IDNA/NFKC to an internationalised host (as browsers
/// do) turns them into the ASCII delimiter, while [Uri.tryParse] keeps the
/// percent-encoded form in the host — a parser-differential host-spoofing
/// vector. Checked on the percent-decoded code points (see
/// [_authorityHasAsciiCompatibilityConfusable], which also rejects the fullwidth
/// ASCII look-alike block).
///
/// The set is the complete family of non-ASCII code points that a launcher
/// applying IDNA/NFKC to an internationalised host can turn into an ASCII
/// structural delimiter — not just the fullwidth forms. It covers the slash
/// mappings (fraction/division slash, IDNA-mapped to '/'), the fullwidth
/// forms, the "small" forms (U+FE52 '.'/U+FE55 ':'/U+FE68 '\'/U+FE6B '@' ...),
/// the vertical presentation forms (U+FE13 ':'/U+FE47 '[' ...), the dot
/// leaders / ellipses (U+2024 '.'/U+2025 '..'/U+2026 '...'), the CJK/halfwidth
/// IDNA dot confusables (U+3002/U+FF61 -> '.', U+2E3C -> '..'), the IDNA2003
/// nameprep middle-dot family (U+00B7/U+0387 -> '.', category Po so the C/Z
/// rule misses them), the numeric "full stop" forms (U+2488..U+249B, U+1F100)
/// and squared/fractional forms
/// whose NFKC expansion embeds a delimiter (e.g. U+2100 'a/c', U+33C2
/// 'a.m.'). Missing any one of these leaves the same parser-differential hole
/// the fullwidth forms already close, so every member fails closed in the
/// authority.
const Set<int> _compatibilityDelimiterCodePoints = <int>{
  // Slash + fullwidth forms (original set).
  0x2044, // FRACTION SLASH           -> '/' (IDNA mapping)
  0x2215, // DIVISION SLASH           -> '/' (IDNA mapping)
  0xFF03, // FULLWIDTH NUMBER SIGN    -> '#'
  0xFF0E, // FULLWIDTH FULL STOP      -> '.'
  0xFF0F, // FULLWIDTH SOLIDUS        -> '/'
  0xFF1A, // FULLWIDTH COLON          -> ':'
  0xFF1F, // FULLWIDTH QUESTION MARK  -> '?'
  0xFF20, // FULLWIDTH COMMERCIAL AT  -> '@'
  0xFF3B, // FULLWIDTH LEFT SQUARE BRACKET  -> '['
  0xFF3C, // FULLWIDTH REVERSE SOLIDUS      -> '\'
  0xFF3D, // FULLWIDTH RIGHT SQUARE BRACKET -> ']'
  // Dot leaders / ellipses -> '.' / '..' / '...'.
  0x2024, // ONE DOT LEADER                             -> '.'
  0x2025, // TWO DOT LEADER                             -> '..'
  0x2026, // HORIZONTAL ELLIPSIS                        -> '...'
  0xFE19, // VERTICAL HORIZONTAL ELLIPSIS               -> '...'
  0xFE30, // VERTICAL TWO DOT LEADER                    -> '..'
  // IDNA dot confusables (UTS-46) -> the domain-label dot '.'. These are NOT
  // Unicode Separator/Other, so the encoded C/Z rule misses them, and their
  // NFKC mapping may be a no-op or a multi-step IDNA mapping (not a literal
  // ASCII char), so they must be listed explicitly. A decode+IDNA launcher
  // resolves `bmc.example%E3%80%82evil.com` as `bmc.example.evil.com`.
  0x3002, // IDEOGRAPHIC FULL STOP                      -> '.' (IDNA)
  0xFF61, // HALFWIDTH IDEOGRAPHIC FULL STOP            -> '.' (IDNA)
  0x2E3C, // TWO DOT LEADER (NFKC -> two U+2024)        -> '..'
  // IDNA middle-dot confusables (nameprep / IDNA2003) -> the domain-label
  // dot '.'. These are Unicode category Po (punctuation), so neither the
  // Separator/Other (C/Z) rule nor the NFKC-based mappings catch them, yet a
  // decode+IDNA launcher resolves e.g. `bmc.example%C2%B7evil.com` as
  // `bmc.example.evil.com` — a host-spoofing parser differential. GREEK ANO
  // TELEIA NFKC-normalises to U+00B7 MIDDLE DOT, so both map to '.'.
  0x00B7, // MIDDLE DOT                                 -> '.' (nameprep/IDNA2003)
  0x0387, // GREEK ANO TELEIA (NFKC -> U+00B7)          -> '.' (nameprep/IDNA2003)
  // "Small" ASCII look-alikes -> the ASCII delimiter.
  0xFE52, // SMALL FULL STOP                            -> '.'
  0xFE55, // SMALL COLON                                -> ':'
  0xFE56, // SMALL QUESTION MARK                        -> '?'
  0xFE5F, // SMALL NUMBER SIGN                          -> '#'
  0xFE68, // SMALL REVERSE SOLIDUS                      -> '\'
  0xFE6B, // SMALL COMMERCIAL AT                        -> '@'
  // Vertical presentation forms -> the ASCII delimiter.
  0xFE13, // PRESENTATION FORM FOR VERTICAL COLON            -> ':'
  0xFE16, // PRESENTATION FORM FOR VERTICAL QUESTION MARK    -> '?'
  0xFE47, // PRESENTATION FORM FOR VERTICAL LEFT SQUARE BRACKET  -> '['
  0xFE48, // PRESENTATION FORM FOR VERTICAL RIGHT SQUARE BRACKET -> ']'
  // Question/exclamation clusters embedding a delimiter.
  0x2047, // DOUBLE QUESTION MARK        -> '??'
  0x2048, // QUESTION EXCLAMATION MARK   -> '?!'
  0x2049, // EXCLAMATION QUESTION MARK   -> '!?'
  // Numeric "full stop" forms -> digit + '.'.
  0x2488, 0x2489, 0x248A, 0x248B, 0x248C, 0x248D, 0x248E, 0x248F, // 1.-8.
  0x2490, 0x2491, 0x2492, 0x2493, 0x2494, 0x2495, 0x2496, 0x2497, // 9.-16.
  0x2498, 0x2499, 0x249A, 0x249B, // 17.-20.
  0x1F100, // DIGIT ZERO FULL STOP      -> '0.'
  // Squared/fractional forms whose NFKC expansion embeds a delimiter.
  0x2100, // ACCOUNT OF                 -> 'a/c'
  0x2101, // ADDRESSED TO THE SUBJECT   -> 'a/s'
  0x2105, // CARE OF                    -> 'c/o'
  0x2106, // CADA UNA                   -> 'c/u'
  0x2A74, // DOUBLE COLON EQUAL         -> '::='
  0x33C2, // SQUARE AM                  -> 'a.m.'
  0x33C7, // SQUARE CO                  -> 'Co.'
  0x33D8, // SQUARE PM                  -> 'p.m.'
};

/// Returns `true` when [rune] is a non-ASCII compatibility character that
/// NFKC-normalises to an ASCII letter or digit (outside the fullwidth block).
///
/// The fullwidth ASCII block and [_compatibilityDelimiterCodePoints] cover the
/// common IDNA confusables, but IDNA/NFKC also folds these compatibility
/// characters to plain ASCII, so a decode+IDNA launcher resolves a different
/// authority than [Uri.tryParse] reports:
///
///  * U+017F LATIN SMALL LETTER LONG S -> 's' and U+212A KELVIN SIGN -> 'K'
///    (the two IDNA2003 case-folding specials that map to ASCII);
///  * circled digits U+2460..U+2473, U+24EA/U+24FF -> ASCII digit sequences;
///  * superscript/subscript digits (U+00B2/03/09, U+2070/74..79, U+2080..89);
///  * circled Latin letters U+24B6..U+24E9 -> A-Z / a-z;
///  * Roman numerals U+2160..U+217F -> ASCII letter sequences (e.g. 'I','IV');
///  * squared / negative-circled / negative-squared Latin capitals
///    (U+1F130..U+1F149, U+1F150..U+1F169, U+1F170..U+1F189) -> A-Z.
///
/// None of these are Unicode Separator/Other (so the encoded C/Z rule misses
/// them) and none NFKC-fold to a delimiter (so the delimiter set misses them).
/// Range checks avoid a hand-maintained const set and are exact: every member
/// of each listed range NFKC-normalises to ASCII.
bool _isNfkcAsciiLetterOrDigit(int rune) {
  if (rune == 0x017F || rune == 0x212A) return true; // LONG S -> s, KELVIN -> K
  if (rune == 0x00B2 || rune == 0x00B3 || rune == 0x00B9) return true; // 2,3,1
  if (rune == 0x2070 || (rune >= 0x2074 && rune <= 0x2079)) return true;
  if (rune >= 0x2080 && rune <= 0x2089) return true; // subscript 0-9
  if (rune >= 0x2460 && rune <= 0x2473) return true; // circled 1-20
  if (rune == 0x24EA || rune == 0x24FF) return true; // circled/negative 0
  if (rune >= 0x24B6 && rune <= 0x24E9) return true; // circled Latin A-Z/a-z
  if (rune >= 0x2160 && rune <= 0x217F) return true; // Roman numerals
  if (rune >= 0x1F130 && rune <= 0x1F149) return true; // squared Latin A-Z
  if (rune >= 0x1F150 && rune <= 0x1F169) return true; // neg-circled A-Z
  if (rune >= 0x1F170 && rune <= 0x1F189) return true; // neg-squared A-Z
  return false;
}

/// Vulgar fractions (Unicode category `No`) whose NFKC normalisation expands
/// to a digit + U+2044 FRACTION SLASH + digit(s), e.g. U+00BD `1/2` ->
/// `1` U+2044 `2`. IDNA/UTS-46 maps U+2044 to '/', so a decode+IDNA launcher
/// resolves a different authority than [Uri.tryParse] reports (which keeps the
/// percent-encoded form in the host). The single decoded code point is not in
/// [_compatibilityDelimiterCodePoints] (which lists U+2044 directly, not the
/// fractions that expand to it) and is not an NFKC ASCII letter/digit either,
/// so this set closes that expansion gap. These are U+00BC..U+00BE, the Number
/// Forms vulgar-fraction block U+2150..U+215F, and U+2189 (0/3). No real BMC
/// host uses them, so rejecting them loses no valid target.
const Set<int> _nfkcFractionSlashCodePoints = <int>{
  0x00BC, // VULGAR FRACTION ONE QUARTER       -> '1/4'
  0x00BD, // VULGAR FRACTION ONE HALF          -> '1/2'
  0x00BE, // VULGAR FRACTION THREE QUARTERS    -> '3/4'
  0x2150, // VULGAR FRACTION ONE SEVENTH       -> '1/7'
  0x2151, // VULGAR FRACTION ONE NINTH         -> '1/9'
  0x2152, // VULGAR FRACTION ONE TENTH         -> '1/10'
  0x2153, // VULGAR FRACTION ONE THIRD         -> '1/3'
  0x2154, // VULGAR FRACTION TWO THIRDS        -> '2/3'
  0x2155, // VULGAR FRACTION ONE FIFTH         -> '1/5'
  0x2156, // VULGAR FRACTION TWO FIFTHS        -> '2/5'
  0x2157, // VULGAR FRACTION THREE FIFTHS      -> '3/5'
  0x2158, // VULGAR FRACTION FOUR FIFTHS       -> '4/5'
  0x2159, // VULGAR FRACTION ONE SIXTH         -> '1/6'
  0x215A, // VULGAR FRACTION FIVE SIXTHS       -> '5/6'
  0x215B, // VULGAR FRACTION ONE EIGHTH        -> '1/8'
  0x215C, // VULGAR FRACTION THREE EIGHTHS     -> '3/8'
  0x215D, // VULGAR FRACTION FIVE EIGHTHS      -> '5/8'
  0x215E, // VULGAR FRACTION SEVEN EIGHTHS     -> '7/8'
  0x215F, // FRACTION NUMERATOR ONE            -> '1/'
  0x2189, // VULGAR FRACTION ZERO THIRDS       -> '0/3'
};

/// Returns `true` when the raw authority carries a percent-encoded non-ASCII
/// code point that a launcher applying IDNA/NFKC resolves to an ASCII
/// character: either a structural delimiter ([_compatibilityDelimiterCodePoints])
/// or a fullwidth ASCII look-alike (the block U+FF01..U+FF5E).
///
/// `Uri.tryParse` keeps such an escape encoded and reports an HTTPS URI with a
/// non-empty host, so a purely syntactic re-check calls it "secure". A launcher
/// applying IDNA/NFKC to the host (as browsers do) resolves a *different*
/// authority — e.g. `%EF%BC%8F` (fullwidth solidus) becomes `/`, `%EF%BC%8E`
/// (fullwidth full stop) becomes `.`, and `%EF%BD%82%EF%BD%8D%EF%BD%83.example`
/// (fullwidth "bmc") becomes `bmc.example`. Under a stale secure flag + test
/// opt-in that parser differential could grant in-app rendering and self-signed
/// acceptance on a spoofed/mismatched host. Every member of the fullwidth ASCII
/// block NFKC-normalises to a plain ASCII letter, digit or punctuation
/// look-alike, so it can forge any ASCII host; a real host is written in ASCII
/// (or punycode), never with fullwidth look-alikes, so no valid target is lost.
/// This is the percent-encoded analogue of the raw non-ASCII authority rule.
/// Scoped to the authority (the TLS-sensitive part) so encoded confusables in
/// the path/query and encoded non-ASCII that folds to non-ASCII (e-acute, euro,
/// emoji) stay launchable.
bool _authorityHasAsciiCompatibilityConfusable(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  final List<int> bytes = <int>[];
  for (int i = 0; i < authority.length; i++) {
    final String char = authority[i];
    if (char == '%' && i + 2 < authority.length) {
      final int? hi = _hexDigit(authority[i + 1]);
      final int? lo = _hexDigit(authority[i + 2]);
      if (hi != null && lo != null) {
        bytes.add((hi << 4) | lo);
        i += 2;
        continue;
      }
    }
    // Raw characters here are ASCII (raw non-ASCII/forbidden chars were
    // rejected by earlier rules); keep the byte so an encoded UTF-8 sequence
    // is decoded in the correct byte context.
    bytes.add(char.codeUnitAt(0));
  }
  final String decoded = utf8.decode(bytes, allowMalformed: true);
  for (final int rune in decoded.runes) {
    if (_compatibilityDelimiterCodePoints.contains(rune)) return true;
    // Vulgar fractions NFKC-expand to digit + U+2044 FRACTION SLASH + digit;
    // IDNA maps U+2044 to '/', forging a structural delimiter that the single
    // decoded code point does not reveal (see _nfkcFractionSlashCodePoints).
    if (_nfkcFractionSlashCodePoints.contains(rune)) return true;
    // Fullwidth ASCII forms (U+FF01..U+FF5E) all NFKC-normalise to a plain
    // ASCII look-alike, so a decode+IDNA launcher resolves a different ASCII
    // host than Uri.tryParse reports — a host-spoofing parser differential.
    if (rune >= 0xFF01 && rune <= 0xFF5E) return true;
    // Other compatibility characters (Kelvin sign, long s, circled letters,
    // Roman numerals) NFKC-normalise to an ASCII letter/digit too — the same
    // decode+IDNA host-spoofing differential, outside the fullwidth block.
    if (_isNfkcAsciiLetterOrDigit(rune)) return true;
  }
  return false;
}

/// Returns `true` when the raw authority carries a percent-encoded octet
/// sequence that is not well-formed UTF-8.
///
/// The encoded-control-octet rule catches a single pct-encoded C0/DEL octet and
/// [_hasEncodedUnicodeControlOrSeparator] catches *well-formed* multi-byte
/// UTF-8 controls, but an INVALID UTF-8 byte sequence slips past both:
/// `utf8.decode(allowMalformed: true)` turns every bad byte into U+FFFD
/// (category So, not C/Z), so neither rule sees it. `Uri.tryParse` keeps such
/// escapes encoded and reports a non-empty HTTPS host, so a purely syntactic
/// re-check calls it "secure" — yet a launcher that decodes percent-encoded
/// host bytes as Latin-1 (or otherwise does not validate UTF-8) sees different,
/// possibly invisible/control bytes in the host: a lone 0x80/0x9F is a C1
/// control, `%C0%80` is an overlong NUL, `%E2%82` is a truncated sequence.
/// Under a stale secure flag + test opt-in that decode differential could grant
/// in-app rendering and self-signed acceptance on a malformed/spoofed
/// authority. A valid URI percent-encodes well-formed UTF-8 (or ASCII), so
/// rejecting malformed UTF-8 loses no valid target; properly encoded multi-byte
/// text — e-acute, euro, emoji, whose continuation bytes lie in 0x80-0xBF —
/// stays launchable. Scoped to the authority so path/query text is unaffected.
bool _authorityHasMalformedUtf8(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  final List<int> bytes = <int>[];
  for (int i = 0; i < authority.length; i++) {
    final String char = authority[i];
    if (char == '%' && i + 2 < authority.length) {
      final int? hi = _hexDigit(authority[i + 1]);
      final int? lo = _hexDigit(authority[i + 2]);
      if (hi != null && lo != null) {
        bytes.add((hi << 4) | lo);
        i += 2;
        continue;
      }
    }
    // Raw characters here are ASCII (raw non-ASCII/forbidden chars were
    // rejected by earlier rules); keep the byte so an encoded UTF-8 sequence
    // is validated in the correct byte context.
    bytes.add(char.codeUnitAt(0));
  }
  try {
    utf8.decode(bytes); // allowMalformed == false: reject invalid sequences.
    return false;
  } on FormatException {
    return true;
  }
}

/// Returns `true` only when [value] is a non-empty run of ASCII digits.
bool _isAllDigits(String value) {
  if (value.isEmpty) return false;
  for (int i = 0; i < value.length; i++) {
    final int code = value.codeUnitAt(i);
    if (code < 0x30 || code > 0x39) return false; // '0'..'9'
  }
  return true;
}

/// Returns `true` only when [value] is a canonical dotted-quad IPv4 octet:
/// 1-3 ASCII digits, value 0-255, and no leading zero (except "0" itself).
bool _isCanonicalIpv4Octet(String value) {
  if (!_isAllDigits(value) || value.length > 3) return false;
  if (value.length > 1 && value.startsWith('0')) return false;
  final int? octet = int.tryParse(value);
  return octet != null && octet <= 255;
}

/// Returns `true` when [host] (the host reported by [Uri.tryParse]) is a
/// non-canonical numeric IP-literal form that a launcher resolves to a
/// DIFFERENT address than [Uri.tryParse] reports.
///
/// Legacy / WHATWG URL parsers accept several numeric spellings of an IP
/// address that Dart's [Uri] treats as opaque DNS names:
///
///  * hex forms `0x7f000001` / `0x7f.1` -> 127.0.0.1;
///  * a bare decimal integer `2130706433` / `0` -> 127.0.0.1 / 0.0.0.0;
///  * abbreviated dotted forms `127.1` / `127.0.1` -> 127.0.0.1;
///  * leading-zero ("octal") forms `0177.0.0.1` -> 127.0.0.1;
///  * the same forms with a single trailing dot (absolute-FQDN form), e.g.
///    `2130706433.` / `0x7f000001.` — the WHATWG "ends in a number" check
///    skips one trailing dot before classifying the host as an IP literal.
///
/// A launcher (browser / WebView) may therefore contact a loopback or internal
/// address while the syntactic re-check saw a non-empty HTTPS host. Under a
/// stale secure flag + test opt-in that differential could grant in-app
/// rendering and self-signed acceptance on a mismatched/spoofed host.
///
/// Only unambiguous forms are kept: IPv6 literals (contain ':'), ordinary DNS
/// names (letters / punycode), and canonical dotted-quad IPv4 (four 0-255
/// octets, no leading zeros). Percent-encoded digit hosts are already rejected
/// by the encoded-unreserved rule, so the raw [Uri]-reported host is safe to
/// inspect here. Stricter than the model, never more permissive.
bool _isNonCanonicalNumericHost(String host) {
  if (host.isEmpty || host.contains(':')) return false; // IPv6: keep.
  // A browser/WebView (WHATWG URL) "ends in a number" check skips exactly one
  // trailing dot, so a numeric host written in absolute-FQDN form
  // (`https://2130706433./` -> 127.0.0.1) is still resolved as an IP literal
  // while `Uri.tryParse` reports it as an opaque DNS host. Strip one trailing
  // dot (the absolute-FQDN root label) before the numeric checks. A real
  // trailing-dot DNS name (e.g. `bmc.example.`) is unaffected because none of
  // these numeric checks fire for a non-numeric host.
  final String core =
      host.endsWith('.') ? host.substring(0, host.length - 1) : host;
  if (core.isEmpty) {
    return false; // degenerate all-dot host: handled separately.
  }
  final List<String> labels = core.split('.');
  // Hex IP forms: any 0x-prefixed label. A real host never uses 0x labels.
  for (final String label in labels) {
    if (label.length > 2 &&
        label.startsWith('0') &&
        (label[1] == 'x' || label[1] == 'X')) {
      return true;
    }
  }
  // All-digit hosts are read as IP literals by legacy parsers. Only a
  // canonical dotted-quad IPv4 is unambiguous; integers, abbreviated and
  // leading-zero/octal forms all fail closed.
  if (labels.every(_isAllDigits)) {
    if (labels.length == 4 && labels.every(_isCanonicalIpv4Octet)) {
      return false;
    }
    return true;
  }
  return false;
}

/// Returns `true` when [host] (the host reported by [Uri.tryParse]) contains an
/// empty DNS label: a leading dot (`.bmc.example`), consecutive dots
/// (`bmc..example`) or more than one trailing dot (`bmc.example..`).
///
/// Such a host is not a real BMC target, and a launcher may normalise/collapse
/// the empty label (or treat a leading dot as a relative/traversal reference)
/// so it contacts a DIFFERENT authority than [Uri.tryParse] reported — a
/// parser-differential / host-spoofing vector that under a stale secure flag +
/// test opt-in could grant in-app rendering and self-signed acceptance on a
/// mismatched host. Exactly one trailing dot is the legitimate absolute-FQDN
/// form and is kept; IPv6 literals (which contain ':') are unaffected. The
/// degenerate all-dot host is rejected separately; an empty core here is left
/// to that rule. Stricter than the model, never more permissive — a real BMC
/// host never has an empty label, so no valid target is lost.
bool _hasEmptyDnsLabel(String host) {
  if (host.isEmpty || host.contains(':')) return false; // IPv6: keep.
  // Strip exactly one trailing dot (the absolute-FQDN root label).
  final String core =
      host.endsWith('.') ? host.substring(0, host.length - 1) : host;
  if (core.isEmpty) return false; // degenerate all-dot host: handled below.
  for (final String label in core.split('.')) {
    if (label.isEmpty) return true;
  }
  return false;
}

/// Returns `true` when [uri]'s raw authority carries a port token that is not
/// a canonical decimal 0..65535 value.
///
/// [Uri.tryParse] is lax about ports in two ways that create parser
/// differentials with browser / WebView (WHATWG URL) parsers:
///
///  * it accepts a SIGNED port — `https://bmc.example:-1/` reports a negative
///    `Uri.port`, and `https://bmc.example:+443/` silently ignores the sign and
///    reports the default port — while a WHATWG parser rejects a signed port
///    outright;
///  * it accepts an arbitrarily long decimal port whose `Uri.port` getter then
///    THROWS [FormatException] on integer overflow (e.g. a 20-digit port),
///    while a WHATWG parser rejects a port above the 16-bit maximum.
///
/// A purely syntactic re-check that reads `Uri.port` therefore either grants
/// in-app rendering and self-signed acceptance on a malformed/spoofed
/// authority (negative/signed) or CRASHES the caller (overflow) under a stale
/// secure flag + test opt-in. This inspects the *raw* authority so an overflow
/// is rejected before `Uri.port` is ever read. A real BMC console port is
/// canonical ASCII digits in 0..65535, so rejecting anything else loses no
/// valid target: absent/empty ports, leading zeros (which WHATWG also parses
/// to the same in-range value), userinfo and IPv6 literal hosts stay launchable.
bool _hasNonCanonicalPort(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  // A launcher splits authority on the LAST '@'; userinfo may contain ':', so
  // strip it before looking for the host's port separator.
  final int at = authority.lastIndexOf('@');
  final String hostPort = at >= 0 ? authority.substring(at + 1) : authority;
  final String port;
  if (hostPort.startsWith('[')) {
    // IPv6 literal: an explicit port follows the closing bracket and ':'.
    final int close = hostPort.indexOf(']');
    if (close < 0 ||
        close + 1 >= hostPort.length ||
        hostPort[close + 1] != ':') {
      return false; // malformed/no port — Uri parse fails closed below.
    }
    port = hostPort.substring(close + 2);
  } else {
    final int colon = hostPort.lastIndexOf(':');
    if (colon < 0) return false; // no explicit port.
    port = hostPort.substring(colon + 1);
  }
  if (port.isEmpty) return false; // empty port -> default, allowed.
  // Port must be canonical ASCII digits only: reject signs, whitespace, etc.
  if (!_isAllDigits(port)) return true;
  // Leading zeros are harmless (WHATWG parses them to the same value), but
  // more than five significant digits is > 65535 — and checking the digit
  // count avoids an int-overflow exception on arbitrarily long input.
  final String significant = port.replaceFirst(RegExp(r'^0+'), '');
  if (significant.isEmpty) return false; // all zeros -> port 0.
  if (significant.length > 5) return true;
  final int? value = int.tryParse(significant);
  return value == null || value > 65535;
}

bool _uriHasSecureHttpsTarget(String? uri) {
  if (uri == null) return false;
  final String trimmed = uri.trim();
  if (trimmed.isEmpty) return false;
  // Reject any raw separator, control/format/invisible code point, raw
  // backslash (delimiter/authority confusion), or RFC-3986 "unwise" ASCII char.
  // None are legal unescaped in a URI; `%20`/`%5C`/`%XX` escapes contain none
  // of them and stay launchable, as do legal gen/sub-delims.
  if (_rawUriForbiddenChars.hasMatch(trimmed)) return false;
  // Reject a bare/malformed `%` that Uri.tryParse would silently encode rather
  // than reject (RFC 3986 requires "%" HEXDIG HEXDIG).
  if (_malformedPercentEncoding.hasMatch(trimmed)) return false;
  // Reject a pct-encoded C0 control / DEL octet: a valid %XX escape that
  // Uri.tryParse keeps encoded while still reporting a secure HTTPS host, but
  // that consumers decode into NUL host truncation / CRLF injection / authority
  // confusion on a malformed/spoofed host. Non-control escapes stay launchable.
  if (_encodedControlOctet.hasMatch(trimmed)) return false;
  // Reject a raw non-ASCII authority (IDN homograph / confusable / emoji host
  // or userinfo): Uri.tryParse silently pct-encodes it into a non-empty host,
  // which under a stale secure flag + test opt-in could reach in-app rendering
  // and self-signed acceptance on a malformed/spoofed host. Punycode/pct-encoded
  // ASCII hosts and non-ASCII path/query text stay launchable.
  if (_authorityHasNonAscii(trimmed)) return false;
  // Reject a pct-encoded structural delimiter (gen-delim or backslash) in the
  // authority: decode-order differences between Uri.tryParse and a launcher can
  // turn a "secure-looking" authority into a different, spoofed host. The rule
  // is scoped to the authority, so encoded delimiters in the path/query and
  // valid pct-encoded non-delimiter bytes in a host stay launchable.
  if (_authorityHasEncodedDelimiter(trimmed)) return false;
  // Reject a pct-encoded percent sign (`%25`) in the authority: a literal `%`
  // is not valid in a host and enables double-decoding differentials
  // (`%252F` -> `%2F` -> `/`) that bypass the single-encoded-delimiter rule.
  // Scoped to the authority, so `%25` in path/query and valid pct-encoded
  // non-percent host bytes stay launchable.
  if (_authorityHasEncodedPercent(trimmed)) return false;
  // Reject a percent-encoded ASCII domain-label dot (`%2E`) in the authority:
  // unlike other encoded delimiters, Uri.tryParse DECODES it into a literal '.',
  // silently changing the reported host while a non-decoding launcher resolves
  // a different authority — a parser-differential host-spoofing vector that
  // under a stale flag + test opt-in could grant in-app rendering and
  // self-signed acceptance on a mismatched host. A literal dot written raw
  // stays launchable, so no valid target is lost.
  if (_authorityHasEncodedDot(trimmed)) return false;
  // Reject a percent-encoded ASCII space (`%20`) in the authority: a decode-first
  // launcher sees a FORBIDDEN domain code point in the host, resolving a different
  // authority than Uri.tryParse reports, which under a stale flag + test opt-in
  // could grant in-app rendering and self-signed acceptance on a spoofed host.
  // Scoped to the authority, so `%20` in the path/query (its correct encoding)
  // and valid pct-encoded UTF-8 host bytes stay launchable.
  if (_authorityHasEncodedSpace(trimmed)) return false;
  // Reject a percent-encoded RFC 3986 unreserved ASCII character (ALPHA /
  // DIGIT / `-` / `.` / `_` / `~`) in the authority: unreserved characters
  // never need encoding, and Uri.tryParse DECODES them into a different host
  // string (`%62%6D%63` -> `bmc`) while a non-decoding launcher resolves a
  // different authority — a decode-order host-spoofing differential that under
  // a stale secure flag + test opt-in could grant in-app rendering and
  // self-signed acceptance on a mismatched host. The `%2E` dot case is already
  // rejected above; this closes the rest. Scoped to the authority, so encoded
  // unreserved text in path/query and valid pct-encoded UTF-8 host bytes stay
  // launchable.
  if (_authorityHasEncodedUnreservedAscii(trimmed)) return false;
  // Reject a percent-encoded RFC 3986 sub-delim (`!` `$` `&` `'` `(` `)` `*` `+`
  // `,` `;` `=`) in the authority: these are legal unescaped in a reg-name, so
  // encoding one is non-canonical, and Uri.tryParse keeps it encoded in the host
  // (`bmc.example%21evil.com`) while a launcher that decodes host bytes before
  // DNS/IDNA resolves a DIFFERENT host (`bmc.example!evil.com`) — one raw URI
  // naming two hosts. Under a stale secure flag + test opt-in that differential
  // could grant in-app rendering and self-signed acceptance on a mismatched
  // authority. Scoped to the authority, so encoded sub-delims in the path/query
  // and valid pct-encoded UTF-8 host bytes stay launchable; raw sub-delims are
  // legal and stay launchable. No valid target is lost.
  if (_authorityHasEncodedSubDelimiter(trimmed)) return false;
  // Reject a percent-encoded multi-byte UTF-8 character that decodes to a
  // Unicode Separator/Other code point (NBSP, zero-width space, NEL, ...): a
  // decode-first launcher could see an invisible/control character in the
  // host, yet Uri.tryParse keeps it encoded and reports a "secure" HTTPS host.
  // ASCII escapes (incl. %20) and non-C/Z escapes stay launchable.
  if (_hasEncodedUnicodeControlOrSeparator(trimmed)) return false;
  // Reject a percent-encoded Unicode combining mark in the authority: a
  // launcher applying NFC/IDNA recomposes a base letter + mark into a different
  // precomposed character, resolving a different host than Uri.tryParse reports,
  // which under a stale secure flag + test opt-in could reach in-app rendering
  // and self-signed acceptance on a mismatched/spoofed host. Precomposed UTF-8
  // host bytes (e-acute) and marks in the path/query stay launchable.
  if (_authorityHasEncodedCombiningMark(trimmed)) return false;
  // Reject a percent-encoded non-ASCII code point that IDNA/NFKC folds to an
  // ASCII character: a structural delimiter (fullwidth solidus/colon/dot/@/
  // [ ]/...) or a fullwidth ASCII letter/digit/punctuation look-alike. A launcher
  // applying IDNA/NFKC resolves a different authority than Uri.tryParse
  // reports, which under a stale flag + test opt-in could reach in-app rendering
  // and self-signed acceptance on a spoofed host. ASCII escapes and encoded
  // non-ASCII that folds to non-ASCII (e-acute, euro, emoji) stay launchable.
  if (_authorityHasAsciiCompatibilityConfusable(trimmed)) return false;
  // Reject a percent-encoded octet sequence in the authority that is not
  // well-formed UTF-8 (lone C1 byte, overlong form, truncated sequence): a
  // decode-first launcher could see different/invisible bytes in the host than
  // Uri.tryParse reports, which under a stale flag + test opt-in could reach
  // in-app rendering and self-signed acceptance on a malformed/spoofed host.
  // Valid pct-encoded UTF-8 (e-acute, euro, emoji) stays launchable.
  if (_authorityHasMalformedUtf8(trimmed)) return false;
  // Reject a non-canonical port (signed, negative, overflow or > 65535) from
  // the RAW authority BEFORE reading Uri.port: Uri.tryParse accepts a signed
  // port (which a WHATWG parser rejects) and an arbitrarily long port whose
  // Uri.port getter throws FormatException on overflow. A stale secure flag +
  // test opt-in could otherwise grant in-app self-signed acceptance on a
  // malformed/mismatched authority or crash the caller. Valid 0..65535 ports
  // (including leading zeros) stay launchable.
  if (_hasNonCanonicalPort(trimmed)) return false;
  final Uri? parsed = Uri.tryParse(trimmed);
  if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
    return false;
  }
  // Reject an out-of-range port in the parsed URI as well (defense in depth):
  // Uri.tryParse reports any non-negative decimal port as an HTTPS URI with a
  // non-empty host, so a purely syntactic re-check calls it "secure", while
  // browser/WebView (WHATWG URL) parsers reject a port above the 16-bit maximum
  // (or wrap it to a different service). Reading Uri.port is guarded against
  // FormatException so a malformed/overflow port fails closed, never crashes.
  if (parsed.hasPort) {
    int port;
    try {
      port = parsed.port;
    } on FormatException {
      return false;
    }
    if (port < 0 || port > 65535) return false;
  }
  // Reject a non-canonical numeric host (hex / decimal integer / abbreviated
  // / leading-zero IP forms, including their single-trailing-dot absolute-FQDN
  // spellings): a launcher resolves such a host to a different address than
  // Uri.tryParse reports, so under a stale secure flag + test opt-in it could
  // grant in-app rendering and self-signed acceptance on a mismatched (often
  // loopback/internal) host. Canonical IPv4/IPv6/DNS hosts (incl. a real
  // trailing-dot FQDN) stay launchable — no valid target lost.
  if (_isNonCanonicalNumericHost(parsed.host)) return false;
  // Degenerate, label-less authority: a host made only of dots ('.', '..',
  // '%2E%2E' decoded by Uri to '..') is not a real BMC host. `Uri.tryParse`
  // still reports it as a non-empty HTTPS host, so without this check a stale
  // secure flag + test opt-in would grant in-app rendering and self-signed
  // acceptance on a bogus/traversal target. A real label (incl. an absolute
  // FQDN trailing dot) or an IPv6 literal contains non-dot characters and is
  // unaffected — stricter than the model, never more permissive.
  if (parsed.host.replaceAll('.', '').isEmpty) return false;
  // Reject a host with an empty DNS label (leading dot, consecutive dots or a
  // double trailing dot): a launcher may normalise/collapse the empty label and
  // contact a different authority than Uri.tryParse reported, which under a
  // stale secure flag + test opt-in could grant in-app rendering and self-signed
  // acceptance on a mismatched/spoofed host. An absolute FQDN with exactly one
  // trailing dot and IPv6 literals stay launchable — no valid target lost.
  if (_hasEmptyDnsLabel(parsed.host)) return false;
  return true;
}

/// Builds the concrete launch plan from the RP-1 policy and a console's public
/// signals.
///
/// [uri] is the raw `KvmConsole.launchUri`; [hasSecureUri] mirrors
/// `KvmConsole.hasSecureLaunchUri`, [isHtml5] mirrors `supportsHtml5`, and
/// [isEnabled] mirrors `serviceEnabled`. They are passed explicitly to keep this
/// module dependency-free (it does not import the model).
///
/// Decision order:
///  1. Derive the *effective* secure signal: BOTH the caller's [hasSecureUri]
///     flag AND a real `https://` URI with a non-empty host must agree. This
///     closes the stale-flag gap so plaintext/non-HTTPS/host-less URIs can
///     never reach in-app rendering or self-signed acceptance (no TLS
///     weakening).
///  2. Route via RP-1's [resolveRenderRoute] (single source of truth) using the
///     effective signal.
///  3. Self-signed acceptance is granted only for an in-app route under the
///     test-only opt-in on HTTPS — never for a fallback.
///  4. A missing/blank URI fails closed to copy-only so a launcher is never
///     handed a null/whitespace target; the URI is trimmed for every other route.
KvmConsoleLaunchPlan planConsoleLaunch({
  required KvmWebViewPolicy policy,
  required String? uri,
  required bool hasSecureUri,
  required bool isHtml5,
  required bool isEnabled,
}) {
  // Never trust a lone boolean for a TLS-sensitive decision: require the raw
  // URI to actually be an HTTPS URL with a host, so an inaccurate/stale signal
  // fails closed instead of enabling in-app self-signed acceptance on plaintext
  // or a host-less URI.
  final bool effectiveSecure = hasSecureUri && _uriHasSecureHttpsTarget(uri);

  final KvmConsoleRenderRoute route = resolveRenderRoute(
    policy: policy,
    hasSecureUri: effectiveSecure,
    isHtml5: isHtml5,
    isEnabled: isEnabled,
  );

  final String? trimmed =
      (uri == null || uri.trim().isEmpty) ? null : uri.trim();

  // Fail closed: a launchable route with no usable URI degrades to copy-only.
  final KvmConsoleRenderRoute safeRoute =
      trimmed == null && route != KvmConsoleRenderRoute.copyOnly
          ? KvmConsoleRenderRoute.copyOnly
          : route;

  // Gate self-signed acceptance on the *final* route being in-app: even the
  // test-only opt-in cannot weaken TLS on an external-browser/copy fallback.
  final bool acceptSelfSigned =
      safeRoute == KvmConsoleRenderRoute.inAppWebView &&
          policy.mayAcceptSelfSigned(hasSecureUri: effectiveSecure);

  return KvmConsoleLaunchPlan._(
    route: safeRoute,
    targetUri: safeRoute == KvmConsoleRenderRoute.copyOnly ? uri : trimmed,
    acceptSelfSigned: acceptSelfSigned,
  );
}
