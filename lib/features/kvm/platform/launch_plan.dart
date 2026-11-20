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

/// Returns the numeric value of a single ASCII hex digit, or `null`.
int? _hexDigit(String char) {
  final int code = char.codeUnitAt(0);
  if (code >= 0x30 && code <= 0x39) return code - 0x30; // '0'-'9'
  if (code >= 0x41 && code <= 0x46) return code - 0x41 + 10; // 'A'-'F'
  if (code >= 0x61 && code <= 0x66) return code - 0x61 + 10; // 'a'-'f'
  return null;
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
    // Fullwidth ASCII forms (U+FF01..U+FF5E) all NFKC-normalise to a plain
    // ASCII look-alike, so a decode+IDNA launcher resolves a different ASCII
    // host than Uri.tryParse reports — a host-spoofing parser differential.
    if (rune >= 0xFF01 && rune <= 0xFF5E) return true;
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
  // Reject a percent-encoded multi-byte UTF-8 character that decodes to a
  // Unicode Separator/Other code point (NBSP, zero-width space, NEL, ...): a
  // decode-first launcher could see an invisible/control character in the
  // host, yet Uri.tryParse keeps it encoded and reports a "secure" HTTPS host.
  // ASCII escapes (incl. %20) and non-C/Z escapes stay launchable.
  if (_hasEncodedUnicodeControlOrSeparator(trimmed)) return false;
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
  final Uri? parsed = Uri.tryParse(trimmed);
  if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
    return false;
  }
  // Degenerate, label-less authority: a host made only of dots ('.', '..',
  // '%2E%2E' decoded by Uri to '..') is not a real BMC host. `Uri.tryParse`
  // still reports it as a non-empty HTTPS host, so without this check a stale
  // secure flag + test opt-in would grant in-app rendering and self-signed
  // acceptance on a bogus/traversal target. A real label (incl. an absolute
  // FQDN trailing dot) or an IPv6 literal contains non-dot characters and is
  // unaffected — stricter than the model, never more permissive.
  if (parsed.host.replaceAll('.', '').isEmpty) return false;
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
