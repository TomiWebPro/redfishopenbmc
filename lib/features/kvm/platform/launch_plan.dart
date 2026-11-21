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

/// Returns `true` only when [uri] is an HTTPS URI with a non-empty host and no
/// embedded control characters.
///
/// This is the single source of truth for "is this a genuinely secure HTTPS
/// console target", shared by the fail-closed launch decision layer here and
/// the `KvmConsole` / `KvmCapability` model transport classifiers. It is one
/// of three sibling classifiers ([isSecureHttpsConsoleUri],
/// [isPlaintextHttpConsoleUri], [isHttpConsoleUri]) backed by the same
/// raw-space/control-char hardening, so the UI's "is this console secure /
/// openable / unencrypted" decision can never disagree with the launch plan
/// about a malformed target — regardless of the URI scheme.
///
/// Defense in depth: a caller-supplied `hasSecureUri` signal may be stale or
/// inaccurate, so the raw URI string is independently checked before any
/// security-sensitive decision (in-app rendering / self-signed acceptance).
///
/// `Uri.tryParse` is used deliberately rather than a hand-rolled authority scan,
/// which can call a malformed target "secure" (e.g. an invalid/duplicated port
/// such as `https://bmc.example:notaport/console`) that `Uri.tryParse` rejects
/// — under a stale secure flag that could reach in-app self-signed acceptance.
/// Host-less forms such as `https:///console`, `https://?q`, `https://#f` and
/// `https://user@/` also fail closed. Scheme matching is case-insensitive
/// (Dart normalises it), and legitimate userinfo/port URIs remain secure.
///
/// `Uri.tryParse` silently percent-encodes C0/DEL control characters (CR, LF,
/// NUL, TAB, DEL), the ASCII space (0x20) AND Unicode separator / invisible
/// format characters (e.g. NBSP `U+00A0`, zero-width space, line/paragraph
/// separators, ideographic space, BOM) into the host/path rather than rejecting
/// them, so a purely syntactic `scheme == 'https' && host.isNotEmpty` check
/// would call such a target "secure". A CRLF/NUL-bearing URI risks header/URI
/// injection; a raw or Unicode space inside the authority (e.g.
/// `https://bmc.exa mple/console` -> host `bmc.exa%20mple`, or an embedded NBSP
/// `https://bmc<U+00A0>.example/console` -> host `bmc%C2%A0.example`) yields a
/// non-empty but malformed/spoofed host that under a stale secure flag could
/// reach in-app rendering and self-signed acceptance. None of these characters
/// are valid raw in a URI (they must be percent-encoded) and an embedded one is
/// not removed by `String.trim()`; they are therefore all rejected via the
/// Unicode `Separator` (Z) and `Other` (C) general categories — a principled
/// category rule that is stricter than an ASCII-only scan but never more
/// permissive, so no valid (properly encoded) HTTPS endpoint is lost. Non-ASCII
/// characters outside those categories (e.g. an emoji in the path) remain
/// launchable.
bool isSecureHttpsConsoleUri(String? uri) =>
    _isHttpUriWithSchemes(uri, const <String>{'https'});

/// Returns `true` only when [uri] is a control-safe **plaintext HTTP** URI with
/// a non-empty host.
///
/// The plaintext sibling of [isSecureHttpsConsoleUri], backed by the identical
/// Unicode-separator/control-char hardening. The `KvmConsole` / `KvmCapability`
/// `usesInsecureHttpLaunchUri` classifiers delegate here so a malformed HTTP
/// target can never be presented as a genuine unencrypted endpoint on one
/// surface while the fail-closed decision layer refuses it on another (a bare
/// `Uri.tryParse` silently percent-encodes CRLF/NUL/space/Unicode separators
/// into the host/path and would flag such a target). Strictly tightens
/// classification — no valid HTTP endpoint is lost. This is read-only guidance:
/// it never changes transport security (issue #021).
bool isPlaintextHttpConsoleUri(String? uri) =>
    _isHttpUriWithSchemes(uri, const <String>{'http'});

/// Returns `true` only when [uri] is a control-safe HTTP **or** HTTPS URI with
/// a non-empty host — the browser/WebView launch URI family.
///
/// Shares the same hardening as [isSecureHttpsConsoleUri] and
/// [isPlaintextHttpConsoleUri] so the `KvmConsole` / `KvmCapability`
/// `hasHttpLaunchUri` classifiers agree on what counts as a browser-launchable
/// URI, including for malformed targets (issues #009 / #021).
bool isHttpConsoleUri(String? uri) =>
    _isHttpUriWithSchemes(uri, const <String>{'http', 'https'});

/// Returns `true` only when [uri] is a non-blank string with no raw control,
/// separator or invisible code point — the shared hardening every transport
/// classifier family (HTTP(S) and non-HTTP external-client schemes) applies.
///
/// The three HTTP(S) classifiers reject raw-space/C0/DEL/Unicode-separator
/// targets via [_controlSafeTrimmedUri] before checking scheme/host. The
/// external-client families (VNC/RFB/KVMIP/serial) previously used a bare
/// `Uri.tryParse`, which silently percent-encodes those characters into a
/// spoofed host while still reporting a valid scheme — so a CRLF/NUL-bearing
/// `vnc://` URI was announced as a trustworthy external client while an
/// equivalent malformed HTTPS/HTTP URI was correctly refused. Exposing the
/// shared control-safety gate here makes the non-HTTP classifiers apply the
/// identical rule (issue #009/#021). It is scheme-agnostic and read-only: it
/// never opens a URL, adds a dependency or weakens transport security.
bool isControlSafeConsoleUri(String? uri) =>
    _controlSafeTrimmedUri(uri) != null;

/// URI schemes whose console endpoint requires an external/native client
/// (VNC/RFB, KVMIP, or serial SSH/Telnet/IPMI) rather than browser/WebView
/// rendering (issues #009 / #021). Scheme comparison is case-insensitive —
/// Dart's [Uri.scheme] is already lower-cased, and this set is lower-case too.
const Set<String> kExternalClientConsoleSchemes = <String>{
  'vnc',
  'rfb',
  'kvmip',
  'kvm',
  'ssh',
  'telnet',
  'ipmi',
};

/// Returns `true` only when [uri] is a control-safe URI whose scheme requires
/// an external client (VNC/RFB/KVMIP/serial) rather than in-app rendering.
///
/// Shares the single fail-closed [isControlSafeConsoleUri] gate with the HTTP(S)
/// classifier families, so a CRLF/NUL/raw-space/spoofed-authority external URI
/// fails closed just like an equivalent malformed HTTPS/HTTP target. This is
/// the one source of truth both `KvmConsole` and `KvmCapability` delegate to,
/// guaranteeing the per-console and per-manager KVM views classify the same
/// endpoint identically (EP-M2 cross-surface classifier parity). Read-only: it
/// opens no URL, adds no dependency and never weakens transport security.
///
/// A degenerate, label-less authority is also refused: `Uri.tryParse` reports
/// `vnc://./`, `ssh://../` and `ipmi://%2E%2E/` as having a non-empty host (`.` /
/// `..`) with an external-client scheme, so a purely syntactic check would badge
/// such a target as a trustworthy "requires an external VNC/SSH client" endpoint
/// with a copy affordance — exactly the parser-differential host confusion the
/// HTTP(S) classifiers already fail closed on (dot-only authority, no real BMC
/// host to contact). Both classifier families now share [_hasDegenerateAuthorityHost]
/// so they can never disagree about the same malformed endpoint. Opaque external
/// URIs with no authority (e.g. `vnc:host=…`) are unaffected.
bool isExternalClientConsoleUri(String? uri) {
  final String? trimmed = _controlSafeTrimmedUri(uri);
  if (trimmed == null) return false;
  final Uri? parsed = Uri.tryParse(trimmed);
  if (parsed == null || _hasDegenerateAuthorityHost(parsed)) return false;
  return kExternalClientConsoleSchemes.contains(parsed.scheme.toLowerCase());
}

/// Human-readable label for the external-client protocol of [uri], or `null`
/// when [uri] is not an external-client console endpoint (issues #009 / #021).
///
/// Built on [isExternalClientConsoleUri] so classification and labelling can
/// never disagree. Shared by `KvmConsole` / `KvmCapability` to keep both KVM
/// views' external-client guidance identical.
String? externalClientConsoleProtocol(String? uri) {
  if (!isExternalClientConsoleUri(uri)) return null;
  final String scheme = Uri.tryParse(uri!.trim())!.scheme.toLowerCase();
  switch (scheme) {
    case 'vnc':
    case 'rfb':
      return 'VNC/RFB';
    case 'kvmip':
    case 'kvm':
      return 'KVMIP';
    case 'ssh':
      return 'SSH';
    case 'telnet':
      return 'Telnet';
    case 'ipmi':
      return 'IPMI serial-over-LAN';
    default:
      return 'external console';
  }
}

/// Rejects raw characters that are never legal unescaped in a URI: Unicode
/// `Separator` (Z: ASCII space, NBSP, line/paragraph/ideographic spaces) and
/// `Other` (C: C0/C1 controls, DEL, zero-width/invisible format chars).
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
/// `%20`/`%5C`/`%XX` escape sequences contain none of these raw characters, so
/// properly encoded targets pass. Rejecting raw unwise chars loses no valid
/// target (their `%XX` forms stay launchable), and legal gen/sub-delims
/// (`[` `]` `&` `=` ...) are unaffected. Shared by every HTTP(S) transport
/// classifier so HTTPS/HTTP classification and the launch-plan decision layer
/// apply identical hardening.
///
/// A percent-encoded RFC 3986 "unwise" ASCII character (`%22`, `%3C`, `%3E`,
/// `%5E`, `%60`, `%7B`, `%7C`, `%7D`) is rejected for the same reason, closing
/// the encoded-form of the raw-unwise rule: the raw forms are caught above, but
/// a literal unwise char must be pct-encoded, and `Uri.tryParse` silently keeps
/// such an escape encoded in the host while still reporting a non-empty HTTPS
/// host. Several (`<`, `>`, `^`, `|`) are forbidden domain code points in
/// WHATWG URL / IDNA host parsing, and none are valid in a real host, so a
/// decode-first launcher can reject or resolve a *different* authority than
/// [Uri.tryParse] reported — a parser differential that under a stale secure
/// flag + test opt-in could grant in-app rendering and self-signed acceptance
/// on a malformed/spoofed host. A real BMC host never contains these chars, so
/// every encoded form fails closed (either hex case), including in userinfo and
/// leading/trailing positions. The rule is scoped to the authority, so the same
/// escapes in the path/query (where they cannot affect which host is contacted)
/// and valid pct-encoded UTF-8 host bytes stay launchable — no valid target
/// lost.
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
/// The same confusable rule also rejects a non-ASCII code point whose NFKC
/// normalisation *introduces* a delimiter rather than being one: U+013F/U+0140
/// (L/l WITH MIDDLE DOT -> U+00B7 -> '.'), the SQUARE "M OVER S" style units
/// (U+33A7/33A8/33AE/33AF/33C6/33DE/33DF -> U+2215 -> '/'), and U+FE12
/// (vertical ideographic full stop -> U+3002 -> '.'). Each is a valid `%XX`
/// escape that is neither Separator/Other nor a mark and whose NFKC stays
/// non-ASCII, so the NFKC-to-ASCII table misses it too, yet a decode+IDNA
/// launcher resolves a different authority than [Uri.tryParse] reports. This
/// is the delimiter analogue of the NFKC-mark-introducing rule; real BMC hosts
/// are ASCII/punycode, so no valid target is lost.
///
/// A percent-encoded Unicode "Mathematical Alphanumeric Symbols" code point
/// (U+1D400..U+1D7FF) is rejected for the same reason: these are styled Latin
/// letters/digits that NFKC-normalise to plain ASCII (e.g. U+1D400 MATHEMATICAL
/// BOLD CAPITAL A -> 'A', U+1D7CE MATHEMATICAL BOLD DIGIT ZERO -> '0'), yet they
/// are neither Separator/Other nor marks, fold to no delimiter, and lie outside
/// the fullwidth/circled/Roman-numeral sets the confusable rule already knows,
/// so every earlier rule misses them. [Uri.tryParse] keeps the escape encoded
/// and reports a non-empty HTTPS host, so a purely syntactic re-check calls it
/// "secure" while a decode+IDNA launcher resolves a DIFFERENT ASCII authority.
/// Under a stale secure flag + test opt-in that parser differential could grant
/// in-app rendering and self-signed acceptance on a spoofed host. No real BMC
/// host uses a mathematical style, so the whole block fails closed; ordinary
/// pct-encoded UTF-8 host bytes and these escapes in the path/query stay
/// launchable — no valid target lost.
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
/// U+2071 SUPERSCRIPT LATIN SMALL LETTER I -> `i` is included too: it is a
/// modifier letter (category Lm, so the C/Z and combining-mark rules miss it)
/// that sits between the U+2070 digit and the U+2074..U+2079 superscript digits
/// the digit family otherwise covers, so an enumeration that lists only those
/// digits silently leaves it out. `Uri.tryParse` keeps each escape encoded and
/// reports a non-empty HTTPS host,
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
/// A MIXED host whose final label is numeric is rejected for the same reason,
/// generalising the all-digit rule: a WHATWG "ends in a number" check inspects
/// only the LAST label, so `https://bmc.2130706433/console` and
/// `https://bmc.127.1/console` are resolved as IPv4 literals (or rejected
/// outright when an earlier label is non-numeric) by a browser/WebView, while
/// [Uri.tryParse] reports them as opaque, non-empty HTTPS hosts. The all-digit
/// rule misses every such mixed host. Under a stale secure flag + test opt-in
/// that parser differential could grant in-app rendering and self-signed
/// acceptance on a mismatched/internal host. A real BMC host has an
/// alphabetic/punycode final label (a numeric TLD is not a browser-resolvable
/// target), so rejecting a purely numeric last label loses no valid target:
/// canonical dotted-quad IPv4, real trailing-dot FQDNs, IPv6 literals,
/// punycode hosts and final labels that merely end in digits stay launchable.
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
///
/// An IPv4-mapped / IPvFuture IPv6 literal is rejected for the same reason: the
/// non-canonical numeric-host rule above skips hosts containing ':', so
/// [Uri.tryParse] reports these as opaque, non-empty HTTPS hosts and a purely
/// syntactic re-check calls them "secure". A browser / WebView (WHATWG URL)
/// resolves `::ffff:a.b.c.d` to an embedded IPv4 address and rejects IPvFuture
/// (`[v...]`) outright, so the two parsers disagree on the authority. Under a
/// stale secure flag + test opt-in that differential could grant in-app
/// rendering and self-signed acceptance on a malformed/mismatched host. No
/// real remote BMC uses a mapped or IPvFuture literal, so they fail closed;
/// plain IPv6 loopback (`::1`, a real test-profile target) and legitimate IPv6
/// (link-local, unique-local, global unicast), including a canonical
/// port/userinfo, stay launchable — no valid target lost.
///
/// A dotted-quad embedded in an IPv6 literal is rejected for the same reason,
/// generalising the IPv4-mapped rule: the mapped check only catches the
/// `groups[5] == 0xffff` special case, but [Uri.tryParse] reports ANY
/// dotted-quad-embedded IPv6 literal (IPv4-compatible `::a.b.c.d`, translated
/// `::ffff:0:a.b.c.d`, or a global/unique-local prefix followed by an embedded
/// quad) as an opaque, non-empty HTTPS host, while a browser/WebView (WHATWG
/// URL) resolves the embedded IPv4 address or a different IPv6 literal — one
/// raw URI naming two authorities. Under a stale secure flag + test opt-in that
/// parser differential could grant in-app rendering and self-signed acceptance
/// on a mismatched/internal host. A real IPv6 literal is written in pure hex
/// groups (no dots), so every dotted form fails closed while pure-hex loopback,
/// link-local, unique-local, global-unicast and mapped literals (the latter
/// still caught by the groups check) stay launchable — no valid target lost.
///
/// An IDNA-ignored Hangul filler is rejected for the same reason: U+115F,
/// U+1160, U+3164 and U+FFA0 are Unicode category `Lo` (not Separator/Other,
/// not a combining mark) and NFKC-normalise to non-ASCII, so every confusable
/// rule above misses them. UTS-46 IDNA nevertheless maps each to NOTHING, so a
/// decode+IDNA launcher silently DROPS it from the host: `bmc%E3%85%A4.example`
/// resolves as `bmc.example`, a DIFFERENT authority than [Uri.tryParse] reports
/// (`bmc%E3%85%A4.example`). Under a stale secure flag + test opt-in that
/// parser differential could grant in-app rendering and self-signed acceptance
/// on a mismatched/spoofed host. No real BMC host uses a Hangul filler, so the
/// four fail closed; ordinary pct-encoded UTF-8 host bytes (e-acute, euro,
/// emoji), punycode hosts and the same escapes in the path/query stay
/// launchable — no valid target lost.
///
/// A UTS-46 IDNA-disallowed Modifier Letter (Unicode category `Lm`) is rejected
/// for the same reason: code points such as U+0640 TATWEEL, U+06E5/U+06E6,
/// U+07F4/U+07F5/U+07FA, U+081A/U+0824/U+0828 and U+1E94B have a stable,
/// non-ASCII NFKC form (so the C/Z, mark, NFKC-to-ASCII and mark-introducing
/// rules all miss them), yet a browser/WebView (WHATWG URL + IDNA) rejects a
/// host containing them outright while [Uri.tryParse] reports a non-empty
/// HTTPS host. Under a stale secure flag + test opt-in that parser differential
/// could grant in-app rendering and self-signed acceptance on an un-navigable,
/// malformed authority. No real BMC host uses an IDNA-disallowed modifier
/// letter, so the ten fail closed; a browser-punycoded modifier letter (e.g.
/// U+3031) and other valid non-ASCII IDNA hosts stay launchable — no valid
/// target lost.
///
/// The Ideographic Description Characters block (Unicode category `So`) is
/// likewise DISALLOWED by UTS-46 IDNA: a browser / WebView (WHATWG URL + IDNA)
/// rejects such a host outright, while [Uri.tryParse] reports it as an opaque,
/// non-empty HTTPS host. These code points evade every earlier rule — they are
/// not Separator/Other (so the encoded C/Z rule misses them), not combining
/// marks and not NFKC-introducing, and do not NFKC-fold to ASCII (so the
/// compatibility-confusable rules miss them too). Under a stale secure flag +
/// test opt-in that parser differential could grant in-app rendering and
/// self-signed acceptance on a host the browser cannot navigate. The block was
/// U+2FF0..U+2FFB in Unicode 16.0.0 and was extended to U+2FFC..U+2FFF in
/// Unicode 17.0 (SURROUND FROM RIGHT / LOWER RIGHT, HORIZONTAL REFLECTION,
/// ROTATION); all 16 are NFKC-stable, IDNA-disallowed and browser-rejected
/// (verified against Node 24, ICU 78.3). The full block through U+2FFF is
/// rejected so the decision is independent of the Dart runtime's Unicode data
/// version: on a Unicode-16 runtime the four additions were caught only
/// incidentally (unassigned => Cn => encoded C/Z rule), and that cover
/// disappears once the runtime is upgraded to 17.0 (same forward-pin idiom as
/// the U+A7F1 compatibility pin). No real BMC host uses an ideographic
/// description character (hosts are ASCII or punycode), so the whole block
/// fails closed; IDNA-valid non-ASCII hosts (e-acute, euro, emoji, U+3031) and
/// the same escapes in the path/query stay launchable — no valid target lost.
///
/// A percent-encoded UTS-46 IDNA-disallowed "replacement character" — U+FFFD
/// REPLACEMENT CHARACTER or U+FFFC OBJECT REPLACEMENT CHARACTER — is rejected
/// for the same reason: both mark the replacement of invalid or unrepresentable
/// input, so a browser / WebView rejects a host containing either (verified
/// against Node 24: `domainToASCII` returns the empty string for both `%EF%BF%BD`
/// and `%EF%BF%BC`) while [Uri.tryParse] keeps the escape encoded and reports a
/// non-empty HTTPS host. Both evade every other authority rule: stable `So`
/// symbols that are neither Separator/Other nor combining marks, that do not
/// NFKC-fold to ASCII, and — unlike a malformed escape — *valid* `%XX` sequences
/// that decode cleanly, so the malformed-UTF-8 rule misses them too. Under a
/// stale secure flag + test opt-in that parser differential could grant in-app
/// rendering and self-signed acceptance on a host the browser cannot navigate.
/// Both are permanently assigned and NFKC-stable across Unicode versions (no
/// forward pin needed), and no real BMC host uses a replacement character, so
/// both fail closed with no valid target lost; IDNA-valid non-ASCII hosts and
/// the same escapes in the path/query stay launchable.
///
/// A percent-encoded NFKC-stable code point that UTS-46 IDNA disallows in a
/// hostname is rejected for the same reason. These code points evade every
/// other authority rule: they are not Separator/Other (so the encoded C/Z rule
/// misses them), not combining marks (so the mark rules miss them), NFKC-stable
/// (so the NFKC-to-ASCII compatibility rules miss them), and not a modifier
/// letter, ideographic description character (U+2FF0..U+2FFF), replacement
/// character or bidi mixed label, yet a browser / WebView rejects a host
/// containing one outright (verified against Node 24: `new URL(uri).hostname`
/// throws for each), while [Uri.tryParse] keeps the escape encoded and reports
/// a non-empty HTTPS host. The family is the Arabic-Indic digits and their
/// decimal/thousands separators (U+0660..U+066C), the CJK-Strokes ideographic
/// description character U+31EF (outside the U+2FF0..U+2FFF block already
/// rejected), the Hanifi Rohingya digits (U+10D30..U+10D39) and the Rumi
/// numeral signs/fractions (U+10E60..U+10E7E). All are permanently assigned
/// and NFKC-stable, so the decision is independent of the Dart runtime's
/// Unicode data version; a runtime that still reports an older member as
/// unassigned catches it via the encoded C/Z rule instead. No real BMC host
/// uses these scripts (hosts are ASCII or punycode), so the whole set fails
/// closed with no valid target lost; IDNA-valid non-ASCII hosts (e-acute, euro,
/// emoji) and the same escapes in the path/query stay launchable.
///
/// A percent-encoded IDNA bidi (mixed-direction) label is rejected for the same
/// reason: UTS-46 IDNA applies the Bidi rule (RFC 5893), so a label mixing a
/// right-to-left script letter (Hebrew, Arabic, ...) with a left-to-right letter
/// — or with European digits placed *before* the RTL letter — is DISALLOWED,
/// and a browser / WebView rejects the host outright (verified against Node 24:
/// `new URL(uri).hostname` throws for such a host). `Uri.tryParse` instead keeps
/// the escape encoded and reports a non-empty HTTPS host, so a purely syntactic
/// re-check calls it "secure". These are Unicode letters (category L) that are
/// NFKC-stable and neither Separator/Other nor marks, so every earlier authority
/// rule misses them. Under a stale secure flag + test opt-in that parser
/// differential could grant in-app rendering and self-signed acceptance on a
/// host the browser cannot navigate. The RTL-script set
/// ([_rtlLetterRanges]) is derived from Node 24's WHATWG URL / IDNA behaviour —
/// a letter is RTL when IDNA accepts it as a standalone label but rejects it
/// after LTR text — so a pure-RTL label, an RTL label with trailing digits and
/// ordinary LTR non-ASCII text all stay launchable: no valid target is lost.
/// Scoped to the authority; the same escapes in the path/query stay launchable.
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

/// Matches a percent-encoded RFC 3986 "unwise" ASCII character: `"` `<` `>`
/// `^` `` ` `` `{` `|` `}`. Hex digits are case-insensitive.
///
/// These characters are in neither the `unreserved` nor the `reserved` set, so
/// a literal occurrence must be percent-encoded (`%22`, `%3C`, ...) — but
/// `Uri.tryParse` silently keeps such an escape encoded in the host while still
/// reporting a non-empty HTTPS host. Several (`<`, `>`, `^`, `|`) are FORBIDDEN
/// domain code points in WHATWG URL / IDNA host parsing, and none are valid in
/// a real host, so a decode-first launcher can reject or resolve a *different*
/// authority than `Uri.tryParse` reported — a parser differential that under a
/// stale secure flag + test opt-in could grant in-app rendering and self-signed
/// acceptance on a malformed/spoofed host. The raw forms are already rejected
/// by [_rawUriForbiddenChars]; this closes the encoded-form gap. Scoped to the
/// authority so the same escapes in the path/query (where they cannot affect
/// which host is contacted) stay launchable.
final RegExp _encodedUnwiseAscii =
    RegExp(r'%(?:22|3C|3E|5E|60|7B|7C|7D)', caseSensitive: false);

/// Returns `true` when the raw authority contains a percent-encoded RFC 3986
/// "unwise" ASCII character, a parser-differential / forbidden-host vector
/// (see [_encodedUnwiseAscii]). Scoped to the authority, so unwise escapes in
/// the path/query and valid pct-encoded UTF-8 host bytes stay launchable.
bool _authorityHasEncodedUnwiseAscii(String uri) {
  final String? authority = _authorityOf(uri);
  if (authority == null) return false;
  return _encodedUnwiseAscii.hasMatch(authority);
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
/// `Mark` (category M) code point, or a non-mark compatibility code point
/// whose NFKC normalisation introduces a combining mark
/// ([_nfkcMarkIntroducingRanges]) — both recompose with a preceding base into
/// a different host under a decode+IDNA launcher.
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
    // Compatibility/spacing code points that are NOT category M themselves
    // but whose NFKC normalisation INTRODUCES a combining mark (e.g. U+00B4
    // ACUTE ACCENT -> SPACE + U+0301, U+FF9E HALFWIDTH VOICED SOUND MARK ->
    // U+3099). They evade the category-M check above and the "entirely ASCII
    // NFKC" compatibility rule, yet a decode+IDNA launcher recomposes them
    // with a preceding base letter into a DIFFERENT host — the same spoofing
    // vector a directly encoded mark closes. Rejected here so no such form
    // can reach in-app self-signed acceptance on a mismatched authority.
    if (_isNfkcMarkIntroducing(rune)) {
      return true;
    }
  }
  return false;
}

/// Flat `[start, end, ...]` inclusive range pairs of every non-ASCII code
/// point that is NOT itself a Unicode `Mark` (category M) but whose Unicode
/// 16.0.0 NFKC normalisation INTRODUCES at least one combining mark.
///
/// Generated from Unicode 16.0.0 data: 143 code points in 54 ranges. Members
/// include the spacing diacritics (U+00A8/U+00AF/U+00B4/U+00B8, U+02D8..U+02DD,
/// U+0384/U+0385, the Greek tonos/dasia forms U+1FBD..U+1FFE), the double low
/// line / overline punctuation (U+2017/U+203E), the halfwidth voiced sound
/// marks (U+309B/U+309C/U+FF9E/U+FF9F), the Indic/Hebrew base+mark
/// compositions (U+0958..U+095F, U+FB1D..U+FB4E, U+FC5B..U+FD3D) and the
/// musical-symbol compositions (U+1D15E..U+1D164, U+1D1BB..U+1D1C0).
///
/// These are invisible to every other authority rule: they are not category
/// C/Z (so the encoded-separator rule misses them), not category M (so the
/// direct combining-mark rule misses them), and their NFKC includes a
/// non-ASCII mark so it is not "entirely ASCII" (the compatibility rule
/// misses them). A decode+IDNA launcher recomposes the introduced mark with a
/// preceding base letter into a different precomposed character, resolving a
/// DIFFERENT host than [Uri.tryParse] reports, which under a stale secure flag
/// + test opt-in could grant in-app rendering and self-signed acceptance on a
/// spoofed host. No real BMC host uses a spacing diacritic, a halfwidth sound
/// mark, a compatibility base+mark composition or a musical symbol (hosts are
/// ASCII or punycode), so rejecting the whole set loses no valid target —
/// pct-encoded UTF-8 that NFKC-folds to a stable non-ASCII character
/// (e-acute, euro, emoji) is deliberately absent and stays launchable.
const List<int> _nfkcMarkIntroducingRanges = <int>[
  0x00A8, 0x00A8, 0x00AF, 0x00AF, 0x00B4, 0x00B4,
  0x00B8, 0x00B8, 0x02D8, 0x02DD, 0x037A, 0x037A,
  0x0384, 0x0385, 0x0958, 0x095F, 0x09DC, 0x09DD,
  0x09DF, 0x09DF, 0x0A33, 0x0A33, 0x0A36, 0x0A36,
  0x0A59, 0x0A5B, 0x0A5E, 0x0A5E, 0x0B5C, 0x0B5D,
  0x0E33, 0x0E33, 0x0EB3, 0x0EB3, 0x0F43, 0x0F43,
  0x0F4D, 0x0F4D, 0x0F52, 0x0F52, 0x0F57, 0x0F57,
  0x0F5C, 0x0F5C, 0x0F69, 0x0F69, 0x1FBD, 0x1FBD,
  0x1FBF, 0x1FC1, 0x1FCD, 0x1FCF, 0x1FDD, 0x1FDF,
  0x1FED, 0x1FEE, 0x1FFD, 0x1FFE, 0x2017, 0x2017,
  0x203E, 0x203E, 0x2ADC, 0x2ADC, 0x309B, 0x309C,
  0xFB1D, 0xFB1D, 0xFB1F, 0xFB1F, 0xFB2A, 0xFB36,
  0xFB38, 0xFB3C, 0xFB3E, 0xFB3E, 0xFB40, 0xFB41,
  0xFB43, 0xFB44, 0xFB46, 0xFB4E, 0xFC5B, 0xFC63,
  0xFC90, 0xFC90, 0xFCD9, 0xFCD9, 0xFCF2, 0xFCF4,
  0xFD3C, 0xFD3D, 0xFE49, 0xFE4C, 0xFE70, 0xFE72,
  0xFE74, 0xFE74, 0xFE76, 0xFE7F, 0xFF9E, 0xFF9F,
  0xFFE3, 0xFFE3, 0x1D15E, 0x1D164, 0x1D1BB, 0x1D1C0,
];

/// Returns `true` when [rune] is a non-mark code point whose Unicode NFKC
/// normalisation introduces a combining mark (see
/// [_nfkcMarkIntroducingRanges]). Such a code point has the same host-spoofing
/// recomposition effect as a directly encoded mark but evades the category-M
/// rule, so it is rejected alongside real marks.
bool _isNfkcMarkIntroducing(int rune) {
  if (rune < 0xA8) return false;
  for (int i = 0; i < _nfkcMarkIntroducingRanges.length; i += 2) {
    if (rune < _nfkcMarkIntroducingRanges[i]) return false; // sorted
    if (rune <= _nfkcMarkIntroducingRanges[i + 1]) return true;
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

/// Non-ASCII code points whose NFKC normalisation is NOT plain ASCII but
/// *introduces* a code point from [_compatibilityDelimiterCodePoints] — a
/// structural delimiter confusable.
///
/// This is the delimiter analogue of [_nfkcMarkIntroducingRanges]: the decoded
/// code point itself is not a delimiter, is not a Unicode Separator/Other or a
/// mark, and its NFKC stays non-ASCII (so the complete NFKC-to-ASCII table in
/// [_isNfkcAsciiCompatibility] does not match it), yet a launcher applying
/// IDNA/NFKC resolves a DIFFERENT authority than [Uri.tryParse] reports, which
/// keeps the percent-encoded escape verbatim in a non-empty HTTPS host. The
/// complete family (Unicode 16.0.0) is:
///
///  * U+013F / U+0140 LATIN [CAPITAL/SMALL] LETTER L WITH MIDDLE DOT — NFKC
///    introduces U+00B7 MIDDLE DOT, which nameprep/IDNA2003 maps to the
///    domain-label dot '.';
///  * the SQUARE units U+33A7/33A8/33AE/33AF/33C6/33DE/33DF ("M OVER S",
///    "RAD OVER S", "C OVER KG", ...), whose NFKC embeds U+2215 DIVISION
///    SLASH, which IDNA maps to '/';
///  * U+FE12 PRESENTATION FORM FOR VERTICAL IDEOGRAPHIC FULL STOP — NFKC
///    introduces U+3002 IDEOGRAPHIC FULL STOP, which IDNA maps to '.'.
///
/// (Vulgar fractions also introduce U+2044 FRACTION SLASH, but those are
/// already rejected by [_nfkcFractionSlashCodePoints].) No real BMC host uses
/// any of these compatibility characters (hosts are ASCII or punycode), so
/// rejecting them loses no valid target — ordinary pct-encoded UTF-8 that
/// NFKC-folds to a stable non-ASCII character (e-acute, euro, emoji) stays
/// launchable.
const Set<int> _nfkcDelimiterIntroducingCodePoints = <int>{
  0x013F, // LATIN CAPITAL LETTER L WITH MIDDLE DOT  -> 'L' + U+00B7 ('.')
  0x0140, // LATIN SMALL LETTER L WITH MIDDLE DOT    -> 'l' + U+00B7 ('.')
  0x33A7, // SQUARE M OVER S                         -> 'm' + U+2215 + 's'
  0x33A8, // SQUARE M OVER S SQUARED                 -> 'm' + U+2215 + 's2'
  0x33AE, // SQUARE RAD OVER S                       -> 'rad' + U+2215 + 's'
  0x33AF, // SQUARE RAD OVER S SQUARED               -> 'rad' + U+2215 + 's2'
  0x33C6, // SQUARE C OVER KG                        -> 'C' + U+2215 + 'kg'
  0x33DE, // SQUARE V OVER M                         -> 'V' + U+2215 + 'm'
  0x33DF, // SQUARE A OVER M                         -> 'A' + U+2215 + 'm'
  0xFE12, // PRESENTATION FORM FOR VERTICAL IDEOGRAPHIC FULL STOP -> U+3002
};

/// Returns `true` when [rune] NFKC-normalises to a string introducing a
/// structural delimiter confusable (see
/// [_nfkcDelimiterIntroducingCodePoints]).
bool _isNfkcDelimiterIntroducing(int rune) =>
    _nfkcDelimiterIntroducingCodePoints.contains(rune);

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
///  * U+2071 SUPERSCRIPT LATIN SMALL LETTER I -> 'i' (a modifier letter, so the
///    C/Z and mark rules miss it, sitting between the U+2070 digit and the
///    U+2074..U+2079 digits that otherwise cover this superscript block);
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
  if (rune == 0x2071) return true; // SUPERSCRIPT LATIN SMALL LETTER I -> i
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

/// Returns `true` when [rune] lies in the Unicode "Mathematical Alphanumeric
/// Symbols" block (U+1D400..U+1D7FF).
///
/// Every character in this block is a styled (bold, italic, script, fraktur,
/// double-struck, sans-serif, monospace) Latin letter, Greek letter or digit
/// whose Unicode compatibility decomposition is a plain code point. The Latin
/// and digit styles NFKC-fold straight to ASCII (e.g. U+1D400 MATHEMATICAL BOLD
/// CAPITAL A -> 'A', U+1D41A MATHEMATICAL BOLD SMALL A -> 'a', U+1D7CE
/// MATHEMATICAL BOLD DIGIT ZERO -> '0'), so a decode+IDNA launcher resolves a
/// DIFFERENT ASCII authority than [Uri.tryParse] reports, which keeps such an
/// escape percent-encoded in the host. None are Unicode Separator/Other or
/// marks, none NFKC-fold to a structural delimiter, and none fall in the
/// fullwidth / circled / Roman-numeral ranges covered by
/// [_isNfkcAsciiLetterOrDigit] — so every existing confusable rule misses them.
/// Under a stale secure flag + test opt-in that parser differential could grant
/// in-app rendering and self-signed acceptance on a spoofed host. No real BMC
/// host uses a mathematical style, so rejecting the whole block loses no valid
/// target (ordinary pct-encoded UTF-8 host bytes stay launchable).
bool _isMathematicalAlphanumericSymbol(int rune) =>
    rune >= 0x1D400 && rune <= 0x1D7FF;

/// Flat `[start, end, ...]` inclusive range pairs of every non-ASCII code point
/// whose Unicode NFKC normalisation is entirely ASCII but that is not already
/// covered by a dedicated rule above (the gen-delim/`U+2044` confusable set,
/// the fullwidth block, [_isNfkcAsciiLetterOrDigit], the mathematical block or
/// [_nfkcFractionSlashCodePoints]).
///
/// Generated from Unicode 16.0.0 data: 427 code points in 92 ranges, plus a
/// forward pin for U+A7F1 (assigned in Unicode 17.0, where NFKC folds it to
/// ASCII `S`) so fail-closed never depends on the Dart runtime's Unicode data —
/// 428 code points in the same 92 ranges. Each member NFKC-folds to plain
/// ASCII, so a browser/WebView applying IDNA/NFKC resolves a DIFFERENT ASCII
/// authority than [Uri.tryParse] reports (which keeps the percent-encoded
/// escape verbatim in the host). Representative,
/// Node-verified differentials: U+1FBF7 SEGMENTED DIGIT SEVEN ->
/// `bmc7.example`, U+3251 CIRCLED NUMBER TWENTY ONE -> `bmc21.example`,
/// U+FB01 LATIN SMALL LIGATURE FI -> `bmcfi.example`, U+02B0 MODIFIER LETTER
/// SMALL H -> `bmch.example`. No real BMC host uses a compatibility character
/// (hosts are ASCII or punycode), so rejecting the whole set loses no valid
/// target — non-ASCII that NFKC-folds to non-ASCII (e-acute, euro, emoji) is
/// deliberately absent and stays launchable.
const List<int> _nfkcAsciiCompatibilityRanges = <int>[
  0xAA, 0xAA, 0xBA, 0xBA, 0x132, 0x133, 0x1C7, 0x1CC,
  0x1F1, 0x1F3, 0x2B0, 0x2B0, 0x2B2, 0x2B3, 0x2B7, 0x2B8,
  0x2E1, 0x2E3, 0x37E, 0x37E, 0x1D2C, 0x1D2C, 0x1D2E, 0x1D2E,
  0x1D30, 0x1D31, 0x1D33, 0x1D3A, 0x1D3C, 0x1D3C, 0x1D3E, 0x1D43,
  0x1D47, 0x1D49, 0x1D4D, 0x1D4D, 0x1D4F, 0x1D50, 0x1D52, 0x1D52,
  0x1D56, 0x1D58, 0x1D5B, 0x1D5B, 0x1D62, 0x1D65, 0x1D9C, 0x1D9C,
  0x1DA0, 0x1DA0, 0x1DBB, 0x1DBB, 0x1FEF, 0x1FEF, 0x203C, 0x203C,
  0x207A, 0x207A, 0x207C, 0x207F, 0x208A, 0x208A, 0x208C, 0x208E,
  0x2090, 0x2093, 0x2095, 0x209C, 0x20A8, 0x20A8, 0x2102, 0x2102,
  0x210A, 0x210E, 0x2110, 0x2113, 0x2115, 0x2116, 0x2119, 0x211D,
  0x2120, 0x2122, 0x2124, 0x2124, 0x2128, 0x2128, 0x212C, 0x212D,
  0x212F, 0x2131, 0x2133, 0x2134, 0x2139, 0x2139, 0x213B, 0x213B,
  0x2145, 0x2149, 0x2474, 0x2487, 0x249C, 0x24B5, 0x2A75, 0x2A76,
  0x2C7C, 0x2C7D, 0x3250, 0x325F, 0x32B1, 0x32BF, 0x32CC, 0x32CF,
  0x3371, 0x337A, 0x3380, 0x3381, 0x3383, 0x338B, 0x338E, 0x3394,
  0x3396, 0x339A, 0x339C, 0x33A6, 0x33A9, 0x33AD, 0x33B0, 0x33B1,
  0x33B3, 0x33B5, 0x33B7, 0x33BB, 0x33BD, 0x33BF, 0x33C3, 0x33C5,
  0x33C8, 0x33D7, 0x33D9, 0x33DD, 0x33FF, 0x33FF,
  0xA7F1, 0xA7F4, // U+A7F1 (Unicode 17.0 MODIFIER LETTER CAPITAL S) NFKC -> 'S'
  0xFB00, 0xFB06, 0xFB29, 0xFB29, 0xFE10, 0xFE10, 0xFE14, 0xFE15,
  0xFE33, 0xFE38, 0xFE4D, 0xFE50, 0xFE54, 0xFE54, 0xFE57, 0xFE57,
  0xFE59, 0xFE5C, 0xFE60, 0xFE66, 0xFE69, 0xFE6A, 0x107A5, 0x107A5,
  0x1CCD6, 0x1CCF9, 0x1F101, 0x1F10A, 0x1F110, 0x1F129, 0x1F12B, 0x1F12E,
  0x1F14A, 0x1F14F, 0x1F16A, 0x1F16C, 0x1F190, 0x1F190, 0x1FBF0, 0x1FBF9,
];

/// Returns `true` when [rune] is a non-ASCII compatibility character whose
/// NFKC normalisation is plain ASCII but that no dedicated rule above covers.
///
/// This generalises the hand-maintained fullwidth / circled / Roman-numeral /
/// mathematical / fraction families to the complete Unicode compatibility set:
/// ligatures, modifier letters, ordinal indicators, letterlike symbols,
/// circled numbers beyond 20, segmented digits and squared units. A launcher
/// applying IDNA/NFKC resolves such a code point to a different ASCII host
/// than [Uri.tryParse] reports, which under a stale flag + test opt-in could
/// grant in-app rendering and self-signed acceptance on a spoofed host.
bool _isNfkcAsciiCompatibility(int rune) {
  if (rune < 0xAA) return false;
  for (int i = 0; i < _nfkcAsciiCompatibilityRanges.length; i += 2) {
    if (rune < _nfkcAsciiCompatibilityRanges[i]) return false; // sorted
    if (rune <= _nfkcAsciiCompatibilityRanges[i + 1]) return true;
  }
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

/// Non-ASCII code points that UTS-46 IDNA maps to NOTHING (silently drops from
/// a hostname) but that evade every other authority rule: all four are Unicode
/// category `Lo` (so the C/Z and mark rules miss them), NFKC-normalise to
/// non-ASCII (so the NFKC-to-ASCII compatibility rule misses them), and are
/// outside the fullwidth/circled/Roman/mathematical/fraction families.
///
///  * U+115F HANGUL CHOSEONG FILLER
///  * U+1160 HANGUL JUNGSEONG FILLER
///  * U+3164 HANGUL FILLER
///  * U+FFA0 HALFWIDTH HANGUL FILLER (NFKC -> U+1160)
///
/// A browser/WebView applying IDNA to an internationalised host drops these,
/// resolving `bmc<E3 85 A4>.example` as `bmc.example` while [Uri.tryParse]
/// keeps the percent-encoded escape in a non-empty HTTPS host. One raw URI
/// therefore names two authorities; under a stale secure flag + test opt-in
/// that parser differential could grant in-app rendering and self-signed
/// acceptance on a mismatched/spoofed host. No real BMC host uses a Hangul
/// filler, so rejecting them loses no valid target.
const Set<int> _idnaIgnoredHangulFillers = <int>{
  0x115F, // HANGUL CHOSEONG FILLER
  0x1160, // HANGUL JUNGSEONG FILLER
  0x3164, // HANGUL FILLER
  0xFFA0, // HALFWIDTH HANGUL FILLER
};

/// Returns `true` when [rune] is a code point that IDNA silently drops from a
/// hostname while [Uri.tryParse] keeps it percent-encoded (see
/// [_idnaIgnoredHangulFillers]).
bool _isIdnaIgnoredHangulFiller(int rune) =>
    _idnaIgnoredHangulFillers.contains(rune);

/// Modifier-Letter (Unicode category `Lm`) code points that UTS-46 IDNA
/// DISALLOWS in a hostname yet whose Unicode NFKC normalisation is a stable
/// non-ASCII code point — so they evade every earlier authority rule:
///
///  * not Unicode Separator/Other (so the encoded C/Z rule misses them);
///  * not a combining mark and not NFKC-introducing a mark (so the mark and
///    mark-introducing rules miss them);
///  * not a compatibility character that NFKC-folds to ASCII (so the complete
///    NFKC-to-ASCII compatibility table misses them);
///  * not a delimiter/fraction/fullwidth/Hangul-filler confusable.
///
/// A browser / WebView (WHATWG URL, IDNA with UseSTD3ASCIIRules) REJECTS a host
/// containing one of these outright (verified against Node 24: each throws),
/// while [Uri.tryParse] reports it as an opaque, non-empty HTTPS host and a
/// purely syntactic re-check therefore calls it "secure". Under a stale secure
/// flag + test opt-in that parser differential could grant in-app rendering
/// and self-signed acceptance on a host the browser cannot navigate — a
/// malformed/mismatched authority no real BMC console uses. The complete
/// browser-rejected, NFKC-stable `Lm` set (Unicode 16.0.0 data + Node ICU
/// validation) is enumerated here; a legitimate modifier letter that NFKC-folds
/// to ASCII (e.g. U+02B0 -> 'h') is already caught by the compatibility rule,
/// and one that a browser punycodes (e.g. U+3031 VERTICAL KANA REPEAT MARK) is
/// a valid international host and is deliberately NOT in this set. U+037A
/// GREEK YPOGEGRAMMENI is also absent: NFKC introduces a combining mark, so the
/// mark-introducing rule already rejects it. No valid target is lost.
const Set<int> _idnaDisallowedModifierLetters = <int>{
  0x0640, // ARABIC TATWEEL
  0x06E5, // ARABIC SMALL WAW WITH HAMZA ABOVE
  0x06E6, // ARABIC SMALL YEH WITH HAMZA ABOVE
  0x07F4, // NKO HIGH TONE A
  0x07F5, // NKO HIGH TONE AA
  0x07FA, // NKO LAJANYALAN
  0x081A, // SAMARITAN MARK IN
  0x0824, // SAMARITAN MARK DAGESH
  0x0828, // SAMARITAN MARK RAFE
  0x1E94B, // ADLAM NASALIZATION MARK (supplementary-plane modifier letter)
};

/// Returns `true` when [rune] is a UTS-46 IDNA-disallowed modifier letter that
/// [Uri.tryParse] can nevertheless keep percent-encoded in a "secure" host
/// (see [_idnaDisallowedModifierLetters]).
bool _isIdnaDisallowedModifierLetter(int rune) =>
    _idnaDisallowedModifierLetters.contains(rune);

/// Returns `true` when [rune] lies in the Ideographic Description Characters
/// block (U+2FF0..U+2FFF, including the four Unicode 17.0 additions
/// U+2FFC..U+2FFF), a family of Unicode `So` symbols that UTS-46 IDNA disallows
/// in hostnames while [Uri.tryParse] keeps them percent-encoded in a non-empty
/// HTTPS host (see the module docs). The end is pinned to U+2FFF (not the
/// Unicode-16 U+2FFB) so fail-closed never depends on the Dart runtime's
/// Unicode data version.
bool _isIdnaDisallowedIdeographicDescription(int rune) =>
    rune >= 0x2FF0 && rune <= 0x2FFF;

/// Returns `true` when the raw authority carries a percent-encoded ideographic
/// description character (U+2FF0..U+2FFF, including the Unicode 17.0 additions)
/// that a browser / WebView rejects under IDNA while [Uri.tryParse] reports a
/// non-empty HTTPS host.
///
/// The scan decodes percent-encoded host bytes as UTF-8 (in the correct byte
/// context, matching the other authority rules) and is scoped to the authority:
/// the same escape in the path/query, where it cannot affect which host is
/// contacted, stays launchable. IDNA-valid non-ASCII hosts stay launchable.
bool _authorityHasIdnaDisallowedIdeographicDescription(String uri) {
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
    if (_isIdnaDisallowedIdeographicDescription(rune)) return true;
  }
  return false;
}

/// Returns `true` when [rune] is a UTS-46 IDNA-disallowed "replacement
/// character": U+FFFD REPLACEMENT CHARACTER or U+FFFC OBJECT REPLACEMENT
/// CHARACTER.
///
/// UTS-46 IDNA disallows both outright (they mark the replacement of invalid
/// or unrepresentable input): a browser / WebView rejects a host containing
/// either while [Uri.tryParse] reports it as an opaque, non-empty HTTPS host.
/// Both are Unicode category `So` and NFKC-stable, so every other authority
/// rule misses them — including the malformed-UTF-8 rule, where a *valid*
/// `%EF%BF%BD` / `%EF%BF%BC` sequence decodes cleanly. They are permanently
/// assigned and stable across Unicode versions, so no forward pin is needed.
bool _isIdnaDisallowedReplacementCharacter(int rune) =>
    rune == 0xFFFD || // REPLACEMENT CHARACTER
    rune == 0xFFFC; // OBJECT REPLACEMENT CHARACTER

/// Returns `true` when the raw authority carries a percent-encoded IDNA-
/// disallowed replacement character (U+FFFD REPLACEMENT CHARACTER or U+FFFC
/// OBJECT REPLACEMENT CHARACTER) that a browser / WebView rejects under IDNA
/// while [Uri.tryParse] reports a non-empty HTTPS host.
///
/// The scan decodes percent-encoded host bytes as UTF-8 (in the correct byte
/// context, matching the other authority rules) and is scoped to the authority:
/// the same escape in the path/query, where it cannot affect which host is
/// contacted, stays launchable. Malformed UTF-8 bytes are left to
/// [_authorityHasMalformedUtf8]; a raw replacement character is already caught
/// by the raw non-ASCII rule. IDNA-valid non-ASCII hosts stay launchable.
bool _authorityHasIdnaDisallowedReplacementCharacter(String uri) {
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
  final String decoded;
  try {
    decoded = utf8.decode(bytes); // allowMalformed == false: leave bad byte
    // sequences to _authorityHasMalformedUtf8 (both fail closed, this rule
    // targets only a genuinely encoded replacement character).
  } on FormatException {
    return false;
  }
  for (final int rune in decoded.runes) {
    if (_isIdnaDisallowedReplacementCharacter(rune)) return true;
  }
  return false;
}


/// Inclusive `[start, end]` range pairs of NFKC-stable code points that UTS-46
/// IDNA disallows in a hostname while [Uri.tryParse] keeps them percent-encoded
/// in a non-empty HTTPS host (see the module docs). Every member is rejected by
/// a browser / WebView (verified against Node 24's WHATWG URL / IDNA parsing):
///
///  * U+0660..U+0669 ARABIC-INDIC DIGIT ZERO..NINE (bidi class AN) and
///    U+066B/U+066C ARABIC DECIMAL/THOUSANDS SEPARATOR (`Po`);
///  * U+31EF IDEOGRAPHIC DESCRIPTION CHARACTER SUBTRACTION — a CJK Strokes
///    ideographic description character OUTSIDE the U+2FF0..U+2FFF block that
///    [_isIdnaDisallowedIdeographicDescription] already rejects;
///  * U+10D30..U+10D39 HANIFI ROHINGYA DIGIT ZERO..NINE;
///  * U+10E60..U+10E7E RUMI DIGIT ONE..RUMI FRACTION TWO THIRDS.
///
/// The ranges are sorted so lookup is a short linear walk that bails out early.
const List<int> _idnaDisallowedNfkcStableRanges = <int>[
  0x0660, 0x066C, // Arabic-Indic digits + decimal/thousands separators
  0x31EF, 0x31EF, // IDC SUBTRACTION (CJK Strokes, outside U+2FF0..U+2FFF)
  0x10D30, 0x10D39, // Hanifi Rohingya digits
  0x10E60, 0x10E7E, // Rumi numeral signs / fractions
];

/// Returns `true` when [rune] is an NFKC-stable, UTS-46 IDNA-disallowed code
/// point that a browser rejects while [Uri.tryParse] reports a "secure" host
/// (see [_idnaDisallowedNfkcStableRanges]).
bool _isIdnaDisallowedNfkcStable(int rune) {
  for (int i = 0; i < _idnaDisallowedNfkcStableRanges.length; i += 2) {
    if (rune < _idnaDisallowedNfkcStableRanges[i]) return false; // sorted
    if (rune <= _idnaDisallowedNfkcStableRanges[i + 1]) return true;
  }
  return false;
}

/// Returns `true` when the raw authority carries a percent-encoded NFKC-stable
/// IDNA-disallowed code point that a browser / WebView rejects under UTS-46
/// while [Uri.tryParse] reports a non-empty HTTPS host (see the module docs and
/// [_idnaDisallowedNfkcStableRanges]).
///
/// The scan decodes percent-encoded host bytes as UTF-8 (in the correct byte
/// context, matching the other authority rules) and is scoped to the authority:
/// the same escape in the path/query, where it cannot affect which host is
/// contacted, stays launchable. Malformed UTF-8 bytes are left to
/// [_authorityHasMalformedUtf8] (which also fails closed). IDNA-valid non-ASCII
/// hosts stay launchable — no valid target lost.
bool _authorityHasIdnaDisallowedNfkcStable(String uri) {
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
  final String decoded;
  try {
    decoded = utf8.decode(bytes); // allowMalformed == false: bad byte sequences
    // are left to _authorityHasMalformedUtf8 (both fail closed).
  } on FormatException {
    return false;
  }
  for (final int rune in decoded.runes) {
    if (_isIdnaDisallowedNfkcStable(rune)) return true;
  }
  return false;
}

/// Inclusive `[start, end]` range pairs of Unicode letters whose bidi class is
/// R or AL (right-to-left), derived empirically from Node 24's WHATWG URL /
/// IDNA processing: a letter is included when `domainToASCII` accepts it as a
/// standalone label but rejects it when appended to LTR text (`bmc<letter>`).
/// This exact, runtime-independent set (2,464 letters in 119 ranges) lets the
/// bidi rule reject mixed-direction labels without over-rejecting valid IDN
/// hosts — a pure RTL label, RTL + trailing digits, and LTR non-ASCII text all
/// stay launchable. See [_authorityHasBidiMixedLabel].
const List<int> _rtlLetterRanges = <int>[
  0x5d0, 0x5ea, 0x5ef, 0x5f2, 0x620, 0x64a, 0x66e, 0x66f,
  0x671, 0x6d3, 0x6d5, 0x6d5, 0x6e5, 0x6e6, 0x6ee, 0x6ef,
  0x6fa, 0x6fc, 0x6ff, 0x6ff, 0x710, 0x710, 0x712, 0x72f,
  0x74d, 0x7a5, 0x7b1, 0x7b1, 0x7ca, 0x7ea, 0x7f4, 0x7f5,
  0x7fa, 0x7fa, 0x800, 0x815, 0x81a, 0x81a, 0x824, 0x824,
  0x828, 0x828, 0x840, 0x858, 0x860, 0x86a, 0x8a0, 0x8b4,
  0x8b6, 0x8c7, 0x2135, 0x2138, 0xfb1d, 0xfb1d, 0xfb1f, 0xfb28,
  0xfb2a, 0xfb36, 0xfb38, 0xfb3c, 0xfb3e, 0xfb3e, 0xfb40, 0xfb41,
  0xfb43, 0xfb44, 0xfb46, 0xfbb1, 0xfbd3, 0xfc5d, 0xfc64, 0xfd3d,
  0xfd50, 0xfd8f, 0xfd92, 0xfdc7, 0xfdf0, 0xfdf9, 0xfe71, 0xfe71,
  0xfe73, 0xfe73, 0xfe77, 0xfe77, 0xfe79, 0xfe79, 0xfe7b, 0xfe7b,
  0xfe7d, 0xfe7d, 0xfe7f, 0xfefc, 0x10800, 0x10805, 0x10808, 0x10808,
  0x1080a, 0x10835, 0x10837, 0x10838, 0x1083c, 0x1083c, 0x1083f, 0x10855,
  0x10860, 0x10876, 0x10880, 0x1089e, 0x108e0, 0x108f2, 0x108f4, 0x108f5,
  0x10900, 0x10915, 0x10920, 0x10939, 0x10980, 0x109b7, 0x109be, 0x109bf,
  0x10a00, 0x10a00, 0x10a10, 0x10a13, 0x10a15, 0x10a17, 0x10a19, 0x10a35,
  0x10a60, 0x10a7c, 0x10a80, 0x10a9c, 0x10ac0, 0x10ac7, 0x10ac9, 0x10ae4,
  0x10b00, 0x10b35, 0x10b40, 0x10b55, 0x10b60, 0x10b72, 0x10b80, 0x10b91,
  0x10c00, 0x10c48, 0x10c80, 0x10cb2, 0x10cc0, 0x10cf2, 0x10d00, 0x10d23,
  0x10e80, 0x10ea9, 0x10eb0, 0x10eb1, 0x10f00, 0x10f1c, 0x10f27, 0x10f27,
  0x10f30, 0x10f45, 0x10fb0, 0x10fc4, 0x10fe0, 0x10ff6, 0x1e800, 0x1e8c4,
  0x1e900, 0x1e943, 0x1e94b, 0x1e94b, 0x1ee00, 0x1ee03, 0x1ee05, 0x1ee1f,
  0x1ee21, 0x1ee22, 0x1ee24, 0x1ee24, 0x1ee27, 0x1ee27, 0x1ee29, 0x1ee32,
  0x1ee34, 0x1ee37, 0x1ee39, 0x1ee39, 0x1ee3b, 0x1ee3b, 0x1ee42, 0x1ee42,
  0x1ee47, 0x1ee47, 0x1ee49, 0x1ee49, 0x1ee4b, 0x1ee4b, 0x1ee4d, 0x1ee4f,
  0x1ee51, 0x1ee52, 0x1ee54, 0x1ee54, 0x1ee57, 0x1ee57, 0x1ee59, 0x1ee59,
  0x1ee5b, 0x1ee5b, 0x1ee5d, 0x1ee5d, 0x1ee5f, 0x1ee5f, 0x1ee61, 0x1ee62,
  0x1ee64, 0x1ee64, 0x1ee67, 0x1ee6a, 0x1ee6c, 0x1ee72, 0x1ee74, 0x1ee77,
  0x1ee79, 0x1ee7c, 0x1ee7e, 0x1ee7e, 0x1ee80, 0x1ee89, 0x1ee8b, 0x1ee9b,
  0x1eea1, 0x1eea3, 0x1eea5, 0x1eea9, 0x1eeab, 0x1eebb,
];

/// Unicode letter (general category L) matcher, applied to a single decoded
/// rune of the authority.
final RegExp _letterRune = RegExp(r'\p{L}', unicode: true);

/// Unicode decimal-digit (general category Nd) matcher, applied to a single
/// decoded rune of the authority.
final RegExp _decimalDigitRune = RegExp(r'\p{Nd}', unicode: true);

/// Returns `true` when [rune] is a right-to-left script letter
/// ([_rtlLetterRanges]). The range table is sorted, so lookup is a short
/// linear walk that bails out early.
bool _isRtlLetterRune(int rune) {
  if (rune < _rtlLetterRanges[0]) return false;
  for (int i = 0; i < _rtlLetterRanges.length; i += 2) {
    if (rune < _rtlLetterRanges[i]) return false; // sorted
    if (rune <= _rtlLetterRanges[i + 1]) {
      return _letterRune.hasMatch(String.fromCharCode(rune));
    }
  }
  return false;
}

/// Returns `true` when the raw authority carries a percent-encoded IDNA bidi
/// mixed-direction label — a label combining an RTL script letter with an LTR
/// letter, or with European digits placed before the RTL letter — that a
/// browser / WebView rejects under UTS-46 IDNA's Bidi rule while
/// [Uri.tryParse] reports a non-empty HTTPS host (see the module docs).
///
/// The scan decodes percent-encoded host bytes as UTF-8 (in the correct byte
/// context, matching the other authority rules) and inspects each maximal run
/// of letters/digits ("word"): the first strong rune (letter or European digit)
/// fixes the word's direction, and any opposite-direction strong rune in that
/// same word fails closed. Digits after an RTL letter are permitted (matching
/// IDNA), so a pure-RTL label with trailing digits stays launchable. '-' and
/// '_' are bidi neutrals and do not break a word. The check is scoped to the
/// authority; the same escapes in the path/query stay launchable.
bool _authorityHasBidiMixedLabel(String uri) {
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
    bytes.add(char.codeUnitAt(0));
  }
  final String decoded;
  try {
    decoded = utf8.decode(bytes); // allowMalformed == false: malformed UTF-8
    // sequences are left to _authorityHasMalformedUtf8 (both fail closed).
  } on FormatException {
    return false;
  }

  bool mixed = false;
  bool hasStrong = false;
  bool directionRtl = false; // direction fixed by the first strong rune
  bool hasRtl = false;
  bool hasLtr = false;
  void finishWord() {
    if (hasStrong && ((directionRtl && hasLtr) || (!directionRtl && hasRtl))) {
      mixed = true;
    }
    hasStrong = false;
    hasRtl = false;
    hasLtr = false;
  }

  for (final int rune in decoded.runes) {
    final String runeString = String.fromCharCode(rune);
    if (_letterRune.hasMatch(runeString)) {
      final bool rtl = _isRtlLetterRune(rune);
      if (rtl) {
        hasRtl = true;
      } else {
        hasLtr = true;
      }
      if (!hasStrong) {
        hasStrong = true;
        directionRtl = rtl;
      }
      continue;
    }
    if (_decimalDigitRune.hasMatch(runeString)) {
      // European (ASCII) digits fix an LTR direction when they lead the word;
      // non-ASCII digits are bidi neutrals here and do not fix direction.
      if (!hasStrong && rune >= 0x30 && rune <= 0x39) {
        hasStrong = true;
        directionRtl = false;
      }
      continue;
    }
    if (rune == 0x2D || rune == 0x5F) continue; // '-' / '_' bidi neutrals
    finishWord(); // authority/label separators end the word
  }
  finishWord();
  return mixed;
}

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
///
/// This also rejects the four UTS-46 IDNA-ignored Hangul fillers
/// ([_idnaIgnoredHangulFillers]): IDNA drops them from the host entirely, so a
/// decode+IDNA launcher contacts a different authority than [Uri.tryParse]
/// reported — the same parser-differential spoofing class as a delimiter or
/// fullwidth confusable, even though their NFKC is not ASCII.
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
    // UTS-46 IDNA silently drops these Hangul fillers, so a decode+IDNA
    // launcher resolves a DIFFERENT ASCII authority than Uri.tryParse reports.
    if (_isIdnaIgnoredHangulFiller(rune)) return true;
    if (_compatibilityDelimiterCodePoints.contains(rune)) return true;
    // NFKC can also *introduce* a delimiter from a code point that is not
    // itself a delimiter (L WITH MIDDLE DOT -> U+00B7, SQUARE "M OVER S" units
    // -> U+2215, vertical ideographic full stop -> U+3002): the decoded rune
    // is non-ASCII and NFKC-non-ASCII, so every check above misses it, but a
    // decode+IDNA launcher still resolves a DIFFERENT authority. See
    // [_nfkcDelimiterIntroducingCodePoints].
    if (_isNfkcDelimiterIntroducing(rune)) return true;
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
    // Mathematical Alphanumeric Symbols (U+1D400..U+1D7FF) are styled Latin
    // letters/digits that NFKC-fold to plain ASCII — the same differential, in
    // a block none of the ranges above cover (see
    // [_isMathematicalAlphanumericSymbol]).
    if (_isMathematicalAlphanumericSymbol(rune)) return true;
    // Every remaining non-ASCII compatibility character that NFKC-normalises
    // to plain ASCII (ligatures, modifier letters, ordinal indicators,
    // letterlike symbols, circled numbers > 20, segmented digits, squared
    // units, ...) — a decode+IDNA launcher resolves a DIFFERENT ASCII
    // authority than Uri.tryParse reports. Generated from Unicode 16.0.0 data
    // so the hand-maintained ranges above cannot leave a family unchecked.
    if (_isNfkcAsciiCompatibility(rune)) return true;
  }
  return false;
}

/// Returns `true` when the raw authority carries a percent-encoded code point
/// that UTS-46 IDNA disallows in a hostname while [Uri.tryParse] keeps it
/// encoded in a non-empty HTTPS host — a browser/WebView rejects the host
/// outright, a parser differential that under a stale secure flag + test opt-in
/// could grant in-app rendering and self-signed acceptance on an un-navigable
/// authority (see [_idnaDisallowedModifierLetters]).
///
/// The scan decodes percent-encoded host bytes as UTF-8 (in the correct byte
/// context, matching the other authority rules) and is scoped to the authority:
/// the same escape in the path/query, where it cannot affect which host is
/// contacted, stays launchable. Valid non-ASCII IDNA hosts (e-acute, U+3031,
/// euro, emoji) stay launchable — no valid target lost.
bool _authorityHasIdnaDisallowedModifierLetter(String uri) {
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
    if (rune < 0x80) continue; // ASCII has no modifier letters.
    if (_isIdnaDisallowedModifierLetter(rune)) return true;
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
///  * hex forms `0x7f000001` / `0x7f.1` -> 127.0.0.1, including the BARE prefix
///    `0x` / `0X` (empty hex digits) -> 0.0.0.0;
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
  // Include the BARE prefix (`0x` / `0X`, length 2): a WHATWG/browser parser's
  // IPv4 number parser strips the prefix and parses the empty remaining hex
  // digits as 0, so `https://0x/` resolves to 0.0.0.0 while Uri.tryParse reports
  // the opaque host `0x` — an authority differential that under a stale secure
  // flag + test opt-in could grant in-app self-signed acceptance on the
  // unspecified address. A length > 2 check let that bare prefix slip through.
  for (final String label in labels) {
    if (label.length >= 2 &&
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
  // WHATWG URL's "ends in a number" check inspects ONLY the last label: a host
  // whose final label is all decimal digits is resolved as an IPv4 literal (or
  // rejected outright when an earlier label is non-numeric) by a launcher,
  // while Uri.tryParse reports the mixed host as an opaque, non-empty HTTPS
  // host — a parser differential that the all-digit rule above misses. Under a
  // stale secure flag + test opt-in that could grant in-app rendering and
  // self-signed acceptance on a mismatched/internal host. A real BMC host
  // (or any browser-resolvable host) has an alphabetic/punycode final label, so
  // rejecting a purely numeric last label loses no valid target. The core has
  // already had one trailing dot stripped, so `labels.last` is the true final
  // label. Canonical IPv4 returned above; IPv6 (`':'`) and empty labels are
  // handled elsewhere.
  if (_isAllDigits(labels.last)) return true;
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

/// Expands an IPv6 literal [host] (brackets already stripped by
/// [Uri.tryParse]) into eight 16-bit groups, unfolding a `::` run and a
/// trailing dotted-quad IPv4 tail. Returns `null` when [host] is not a
/// well-formed IPv6 literal.
///
/// This is used only to *positively identify* loopback/mapped/unspecified
/// forms; a `null` result is left to the ordinary parser checks (never treated
/// as a spoof), so the rule can never reject more than intended.
List<int>? _expandIpv6Groups(String host) {
  String text = host;
  // A trailing dotted-quad (IPv4-mapped/embedded form) becomes two groups.
  final int lastColon = text.lastIndexOf(':');
  if (lastColon >= 0) {
    final String tail = text.substring(lastColon + 1);
    if (tail.contains('.')) {
      final List<String> octets = tail.split('.');
      if (octets.length != 4) return null;
      final List<int> values = <int>[];
      for (final String octet in octets) {
        // Loose parse (leading zeros allowed) is intentional: a non-canonical
        // embedded quad is not a real BMC target and is rejected as a spoof.
        if (octet.isEmpty || octet.length > 3) return null;
        final int? value = int.tryParse(octet);
        if (value == null || value < 0 || value > 255) return null;
        values.add(value);
      }
      final String hi = ((values[0] << 8) | values[1]).toRadixString(16);
      final String lo = ((values[2] << 8) | values[3]).toRadixString(16);
      text = '${text.substring(0, lastColon + 1)}$hi:$lo';
    }
  }
  final int compressed = text.indexOf('::');
  final List<String> left;
  final List<String> right;
  if (compressed >= 0) {
    left = text.substring(0, compressed).split(':');
    right = text.substring(compressed + 2).split(':');
    if (left.isNotEmpty && left.last.isEmpty) left.removeLast();
    if (right.isNotEmpty && right.first.isEmpty) right.removeAt(0);
  } else {
    left = text.split(':');
    right = <String>[];
  }
  int? parseGroup(String token) {
    if (token.isEmpty) return null;
    final int? value = int.tryParse(token, radix: 16);
    if (value == null || value < 0 || value > 0xFFFF) return null;
    return value;
  }

  final List<int> groups = <int>[];
  for (final String token in left) {
    final int? value = parseGroup(token);
    if (value == null) return null;
    groups.add(value);
  }
  final int missing = 8 - left.length - right.length;
  if (missing < 0) return null;
  for (int i = 0; i < missing; i++) {
    groups.add(0);
  }
  for (final String token in right) {
    final int? value = parseGroup(token);
    if (value == null) return null;
    groups.add(value);
  }
  return groups.length == 8 ? groups : null;
}

/// Returns `true` when [host] (the host reported by [Uri.tryParse]) is an IPv6
/// literal that a browser / WebView (WHATWG URL) treats differently from the
/// opaque host string [Uri.tryParse] reports: any IPv4-embedded dotted-quad
/// literal (`::a.b.c.d` IPv4-compatible, `::ffff:0:a.b.c.d` translated, or a
/// real prefix followed by an embedded quad — all of which a launcher resolves
/// to an embedded IPv4 address / different IPv6 literal while [Uri.tryParse]
/// reports an opaque host), the IPv4-mapped hex form (`::ffff:7f00:1`, detected
/// via its groups), or an IPvFuture (`[v...]`) literal, which WHATWG rejects
/// outright while [Uri.tryParse] accepts it. Under a stale secure flag + test
/// opt-in that parser differential could grant in-app rendering and self-signed
/// acceptance on a malformed/mismatched authority. No real remote BMC uses an
/// embedded-quad, mapped or IPvFuture literal, so they fail closed; a real IPv6
/// literal is written in pure hex groups, so plain IPv6 loopback (`::1`,
/// deliberately kept for the test-only opt-in) and legitimate link-local,
/// unique-local and global-unicast IPv6 stay launchable.
bool _hasSpoofedIpv6Host(String host) {
  // [Uri.tryParse] strips the brackets of a valid IPv6 literal but retains
  // them for an IPvFuture literal, which browsers/WebViews reject outright.
  if (host.startsWith('[')) return true;
  if (!host.contains(':')) return false; // not an IPv6 literal.
  // A dotted-quad embedded anywhere in an IPv6 literal (IPv4-compatible
  // `::a.b.c.d`, translated `::ffff:0:a.b.c.d`, or a global/unique-local
  // prefix followed by an embedded quad) is reported by [Uri.tryParse] as an
  // opaque, non-empty HTTPS host, but a browser/WebView (WHATWG URL) resolves
  // the embedded IPv4 address (or a different IPv6 literal) — one raw URI
  // naming two authorities. This is the same parser differential as the
  // IPv4-mapped form below, which is only a special case (groups[5] == 0xffff)
  // of the broader dotted-quad family; a bare `groups[5]` check misses every
  // non-mapped embedded quad. A real IPv6 literal is written in pure hex
  // groups (no dots), so rejecting every dotted form loses no valid target;
  // pure-hex mapped/loopback/link-local/global literals stay launchable.
  if (host.contains('.')) return true;
  final List<int>? groups = _expandIpv6Groups(host);
  if (groups == null) return false; // leave malformed input to parser checks.
  // IPv4-mapped ::ffff:a.b.c.d: the first five groups are zero and the sixth
  // is 0xffff (the embedded quad has already been expanded to two groups).
  // Plain IPv6 loopback (::1) is deliberately NOT rejected: it is a real
  // target for the test-only opt-in and both parsers agree on the address.
  if (groups[5] != 0xFFFF) return false;
  for (int i = 0; i < 5; i++) {
    if (groups[i] != 0) return false;
  }
  return true;
}

/// Trims [uri] and returns it only when it is non-blank and contains no raw
/// control/separator/invisible code point, or `null` otherwise. Shared by every
/// HTTP(S) transport classifier so HTTPS and HTTP classification apply
/// identical hardening — `Uri.tryParse` alone percent-encodes those characters
/// instead of rejecting them.
String? _controlSafeTrimmedUri(String? uri) {
  if (uri == null) return null;
  final String trimmed = uri.trim();
  if (trimmed.isEmpty) return null;
  // Reject any raw separator, control/format/invisible code point, raw
  // backslash (delimiter/authority confusion), or RFC-3986 "unwise" ASCII char.
  // None are legal unescaped in a URI; `%20`/`%5C`/`%XX` escapes contain none
  // of them and stay launchable, as do legal gen/sub-delims. An embedded raw
  // one is not removed by `String.trim()`.
  if (_rawUriForbiddenChars.hasMatch(trimmed)) return null;
  // Reject a bare/malformed `%` that Uri.tryParse would silently encode rather
  // than reject (RFC 3986 requires "%" HEXDIG HEXDIG). Valid `%XX` escapes (any
  // hex case) contain no bare `%` and stay launchable.
  if (_malformedPercentEncoding.hasMatch(trimmed)) return null;
  // Reject a pct-encoded C0 control / DEL octet: a valid %XX escape that
  // Uri.tryParse keeps encoded while still reporting a secure HTTPS host, but
  // that consumers decode into NUL host truncation / CRLF injection / authority
  // confusion on a malformed/spoofed host. Non-control escapes stay launchable.
  // Folded into this shared control-safety gate (returning `null`, like the
  // other checks) so every HTTP(S) classifier and the launch-plan target refuse
  // a pct-encoded control octet identically.
  if (_encodedControlOctet.hasMatch(trimmed)) return null;
  // Reject a raw non-ASCII authority (IDN homograph / confusable / emoji host
  // or userinfo): Uri.tryParse silently pct-encodes it into a non-empty host,
  // which under a stale secure flag + test opt-in could reach in-app rendering
  // and self-signed acceptance on a malformed/spoofed host. Punycode/pct-encoded
  // ASCII hosts and non-ASCII path/query text stay launchable.
  // Folded into this shared control-safety gate so every HTTP(S) classifier and
  // the launch-plan target refuse a raw non-ASCII authority identically.
  if (_authorityHasNonAscii(trimmed)) return null;
  // Reject a pct-encoded structural delimiter (gen-delim or backslash) in the
  // authority: decode-order differences between Uri.tryParse and a launcher can
  // turn a "secure-looking" authority into a different, spoofed host. Scoped to
  // the authority so encoded delimiters in the path/query and valid pct-encoded
  // non-delimiter bytes in a host stay launchable. Folded into this single shared
  // gate (returns `null`, matching the other checks) so every HTTP(S) classifier
  // AND the launch-plan target refuse such an authority identically.
  if (_authorityHasEncodedDelimiter(trimmed)) return null;
  // Reject a pct-encoded percent sign (`%25`) in the authority: a literal `%`
  // is not valid in a host and enables double-decoding differentials
  // (`%252F` -> `%2F` -> `/`) that bypass the single-encoded-delimiter rule.
  // Scoped to the authority, so `%25` in path/query and valid pct-encoded
  // non-percent host bytes stay launchable. Folded into this single shared gate
  // (returns `null`, like the other checks) so every classifier and the
  // launch-plan target refuse such an authority identically.
  if (_authorityHasEncodedPercent(trimmed)) return null;
  // Reject a percent-encoded ASCII domain-label dot (`%2E`) in the authority:
  // unlike other encoded delimiters, Uri.tryParse DECODES it into a literal '.',
  // silently changing the reported host while a non-decoding launcher resolves
  // a different authority — a parser-differential host-spoofing vector that
  // under a stale flag + test opt-in could grant in-app rendering and
  // self-signed acceptance on a mismatched host. A literal dot written raw
  // stays launchable, so no valid target is lost. Folded into this single
  // shared gate (returns `null`, like the other checks) so every classifier
  // and the launch-plan target refuse such an authority identically.
  if (_authorityHasEncodedDot(trimmed)) return null;
  // Reject a percent-encoded ASCII space (`%20`) in the authority: a decode-first
  // launcher sees a FORBIDDEN domain code point in the host, resolving a different
  // authority than Uri.tryParse reports, which under a stale flag + test opt-in
  // could grant in-app rendering and self-signed acceptance on a spoofed host.
  // Scoped to the authority, so `%20` in the path/query (its correct encoding)
  // and valid pct-encoded UTF-8 host bytes stay launchable. Folded into this
  // single shared gate (returns `null`, like the other checks) so every
  // HTTP(S) classifier and the launch-plan target refuse such an authority
  // identically.
  if (_authorityHasEncodedSpace(trimmed)) return null;
  // Reject a percent-encoded RFC 3986 unreserved ASCII character (ALPHA /
  // DIGIT / `-` / `.` / `_` / `~`) in the authority: unreserved characters
  // never need encoding, and Uri.tryParse DECODES them into a different host
  // string (`%62%6D%63` -> `bmc`) while a non-decoding launcher resolves a
  // different authority — a decode-order host-spoofing differential that under
  // a stale secure flag + test opt-in could grant in-app rendering and
  // self-signed acceptance on a mismatched host. The `%2E` dot case is already
  // rejected above; this closes the rest. Scoped to the authority, so encoded
  // unreserved text in path/query and valid pct-encoded UTF-8 host bytes stay
  // launchable. Folded into this single shared gate (returns `null`, like the
  // other checks) so every classifier and the launch-plan target reject it
  // identically.
  if (_authorityHasEncodedUnreservedAscii(trimmed)) return null;
  // Reject a percent-encoded RFC 3986 sub-delim (`!` `$` `&` `'` `(` `)` `*` `+`
  // `,` `;` `=`) in the authority: these are legal unescaped in a reg-name, so
  // encoding one is non-canonical, and Uri.tryParse keeps it encoded in the host
  // (`bmc.example%21evil.com`) while a launcher that decodes host bytes before
  // DNS/IDNA resolves a DIFFERENT host (`bmc.example!evil.com`) — one raw URI
  // naming two hosts. Under a stale secure flag + test opt-in that differential
  // could grant in-app rendering and self-signed acceptance on a mismatched
  // authority. Scoped to the authority, so encoded sub-delims in the path/query
  // and valid pct-encoded UTF-8 host bytes stay launchable; raw sub-delims are
  // legal and stay launchable. No valid target is lost. Folded into this single
  // shared gate (returns `null`, like the other checks) so every classifier and
  // the launch-plan target reject it identically.
  if (_authorityHasEncodedSubDelimiter(trimmed)) return null;
  // Reject a percent-encoded RFC 3986 "unwise" ASCII character (`"` `<` `>`
  // `^` `` ` `` `{` `|` `}`) in the authority: the raw forms are already
  // rejected, but a pct-encoded one escapes the encoded-delimiter, unreserved,
  // sub-delim, control and C/Z rules. `Uri.tryParse` keeps it encoded while
  // reporting a non-empty HTTPS host, so a purely syntactic re-check calls it
  // "secure" — yet a launcher/browser that decodes the host first sees a
  // forbidden/non-canonical host char and may reject or resolve a different
  // authority. Under a stale secure flag + test opt-in that parser differential
  // could grant in-app rendering and self-signed acceptance on a malformed/
  // spoofed host. A real BMC host never contains these chars, so every encoded
  // form fails closed; scoped to the authority so path/query escapes stay
  // launchable — no valid target lost. Folded into this single shared gate
  // (returns `null`, like the other checks) so every classifier and the
  // launch-plan target reject it identically.
  if (_authorityHasEncodedUnwiseAscii(trimmed)) return null;
  // Reject a percent-encoded multi-byte UTF-8 character that decodes to a
  // Unicode Separator/Other code point (NBSP, zero-width space, NEL, ...): a
  // decode-first launcher could see an invisible/control character in the
  // host, yet Uri.tryParse keeps it encoded and reports a "secure" HTTPS host.
  // ASCII escapes (incl. %20) and non-C/Z escapes stay launchable. Folded into
  // this single shared gate (returning `null`, like the other checks) so every
  // HTTP(S) classifier and the launch-plan target reject it identically.
  if (_hasEncodedUnicodeControlOrSeparator(trimmed)) return null;
  // Reject a percent-encoded Unicode combining mark in the authority: a
  // launcher applying NFC/IDNA recomposes a base letter + mark into a different
  // precomposed character, resolving a different host than Uri.tryParse reports,
  // which under a stale secure flag + test opt-in could reach in-app rendering
  // and self-signed acceptance on a mismatched/spoofed host. Precomposed UTF-8
  // host bytes (e-acute) and marks in the path/query stay launchable. Folded into
  // this single shared gate (returning `null`, like the other checks) so every
  // HTTP(S) classifier and the launch-plan target reject it identically.
  if (_authorityHasEncodedCombiningMark(trimmed)) return null;
  // Reject a percent-encoded non-ASCII code point that IDNA/NFKC folds to an
  // ASCII character: a structural delimiter (fullwidth solidus/colon/dot/@/
  // [ ]/...) or a fullwidth ASCII letter/digit/punctuation look-alike. A launcher
  // applying IDNA/NFKC resolves a different authority than Uri.tryParse
  // reports, which under a stale flag + test opt-in could reach in-app rendering
  // and self-signed acceptance on a spoofed host. This also covers the
  // Mathematical Alphanumeric Symbols block (styled Latin letters/digits that
  // fold to plain ASCII, outside every set above), the four IDNA-ignored Hangul
  // fillers that IDNA drops from the host entirely, and U+2071 SUPERSCRIPT
  // LATIN SMALL LETTER I (a modifier letter that NFKC-folds to ASCII `i`), and
  // the NFKC-delimiter-introducing families (L WITH MIDDLE DOT, SQUARE "M OVER
  // S" units, vertical ideographic full stop) whose NFKC introduces U+00B7 /
  // U+2215 / U+3002. ASCII escapes and encoded non-ASCII that folds to
  // non-ASCII (e-acute, euro, emoji) stay launchable.
  // Folded into this single shared gate (returning `null`, like the other checks)
  // so every HTTP(S) classifier and the launch-plan target reject it identically.
  if (_authorityHasAsciiCompatibilityConfusable(trimmed)) return null;
  // Reject a percent-encoded UTS-46 IDNA-disallowed modifier letter in the
  // authority: a browser/WebView rejects such a host outright while Uri.tryParse
  // reports a non-empty HTTPS host, so a stale secure flag + test opt-in could
  // grant in-app self-signed acceptance on an un-navigable/mismatched authority.
  // Valid non-ASCII IDNA hosts (e-acute, U+3031, euro, emoji) stay launchable.
  // Folded into this shared gate (returning `null`, like the other checks) so
  // every HTTP(S) classifier and the launch-plan target reject it identically.
  if (_authorityHasIdnaDisallowedModifierLetter(trimmed)) return null;
  // Reject a percent-encoded ideographic description character (U+2FF0..U+2FFB)
  // in the authority: UTS-46 IDNA disallows the whole block, so a browser /
  // WebView rejects the host outright while Uri.tryParse reports a non-empty
  // HTTPS host. Under a stale secure flag + test opt-in that differential could
  // grant in-app self-signed acceptance on an un-navigable authority. IDNA-valid
  // symbols (euro, emoji) and path/query escapes stay launchable — no target lost.
  // Folded into this shared gate (returning `null`, like the other checks) so
  // every HTTP(S) classifier and the launch-plan target reject it identically.
  if (_authorityHasIdnaDisallowedIdeographicDescription(trimmed)) return null;
  // Reject a percent-encoded IDNA-disallowed replacement character (U+FFFD
  // REPLACEMENT CHARACTER or U+FFFC OBJECT REPLACEMENT CHARACTER) in the
  // authority: UTS-46 IDNA disallows both, so a browser/WebView rejects the host
  // outright while Uri.tryParse reports a non-empty HTTPS host. A stale secure
  // flag + test opt-in could otherwise grant in-app self-signed acceptance on a
  // host the browser cannot navigate. IDNA-valid non-ASCII hosts and path/query
  // escapes stay launchable — no valid target lost. Folded into this shared
  // gate (returning `null`, like the other checks) so every HTTP(S)
  // classifier and the launch-plan target reject it identically.
  if (_authorityHasIdnaDisallowedReplacementCharacter(trimmed)) return null;
  // Reject a percent-encoded NFKC-stable code point that UTS-46 IDNA disallows
  // (Arabic-Indic digits/separators U+0660..U+066C, the CJK-Strokes IDC U+31EF,
  // Hanifi Rohingya digits U+10D30..U+10D39, Rumi numerals U+10E60..U+10E7E):
  // a browser/WebView rejects such a host outright while Uri.tryParse reports a
  // non-empty HTTPS host, so a stale secure flag + test opt-in could grant
  // in-app self-signed acceptance on a host the browser cannot navigate. All
  // are NFKC-stable and evade the C/Z, mark and compatibility rules. IDNA-valid
  // non-ASCII hosts and path/query escapes stay launchable — no target lost.
  // Folded into this shared gate (returning `null`, like the other checks) so
  // every HTTP(S) classifier and the launch-plan target reject it identically.
  if (_authorityHasIdnaDisallowedNfkcStable(trimmed)) return null;
  // Reject a percent-encoded IDNA bidi mixed-direction label (an RTL script
  // letter mixed with LTR text or with leading European digits): a browser /
  // WebView rejects such a host under UTS-46 IDNA's Bidi rule while
  // Uri.tryParse reports a non-empty HTTPS host. A stale secure flag + test
  // opt-in could otherwise grant in-app self-signed acceptance on a host the
  // browser cannot navigate. Pure-RTL labels, RTL+digit labels and LTR non-
  // ASCII text stay launchable — no valid target lost. Folded into this shared
  // gate (returning `null`, like the other checks) so every HTTP(S) classifier
  // and the launch-plan target reject it identically.
  if (_authorityHasBidiMixedLabel(trimmed)) return null;
  // Reject a percent-encoded octet sequence in the authority that is not
  // well-formed UTF-8 (lone C1 byte, overlong form, truncated sequence): a
  // decode-first launcher could see different/invisible bytes in the host than
  // Uri.tryParse reports, which under a stale flag + test opt-in could reach
  // in-app rendering and self-signed acceptance on a malformed/spoofed host.
  // Valid pct-encoded UTF-8 (e-acute, euro, emoji) stays launchable. Folded
  // into this single shared gate (returning `null`, like the other checks) so
  // every HTTP(S) classifier and the launch-plan target reject it identically.
  if (_authorityHasMalformedUtf8(trimmed)) return null;
  return trimmed;
}

/// True when [parsed] has an authority whose host has no real DNS label — a
/// host made only of dots (`.`, `..`, or a percent-encoded dot such as
/// `https://%2E%2E/` that `Uri.tryParse` decodes to `..`).
///
/// `Uri.tryParse` still reports these as URIs with a NON-EMPTY host, so a bare
/// `scheme && host.isNotEmpty` check calls them "secure"/usable. There is no
/// real BMC host to contact and a launcher may resolve `..` as a relative /
/// traversal path rather than a host. Scoped to URIs that actually have an
/// authority, so scheme-relative/path-only values (e.g. a Redfish `@odata.id`
/// used as a clipboard fallback, which has no authority) are unaffected.
/// Shared by the HTTP(S) classifier family and the external-client classifier
/// so both fail closed on the same malformed authority.
bool _hasDegenerateAuthorityHost(Uri parsed) =>
    parsed.hasAuthority && parsed.host.replaceAll('.', '').isEmpty;

/// Whether [uri] is a control-safe HTTP(S) URI with a host whose (Dart-
/// normalised, here lower-cased) scheme is in [schemes].
bool _isHttpUriWithSchemes(String? uri, Set<String> schemes) {
  final String? trimmed = _controlSafeTrimmedUri(uri);
  if (trimmed == null) return false;
  // Reject a non-canonical port (signed, negative, overflow or > 65535) from
  // the RAW authority BEFORE reading Uri.port: Uri.tryParse accepts a signed
  // port (which a WHATWG parser rejects) and an arbitrarily long port whose
  // Uri.port getter throws FormatException on overflow. A stale secure flag +
  // test opt-in could otherwise grant in-app self-signed acceptance on a
  // malformed/mismatched authority or crash the caller. Valid 0..65535 ports
  // (including leading zeros) stay launchable.
  if (_hasNonCanonicalPort(trimmed)) return false;
  final Uri? parsed = Uri.tryParse(trimmed);
  if (parsed == null ||
      !schemes.contains(parsed.scheme.toLowerCase()) ||
      parsed.host.isEmpty) {
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
  // Reject IPv4-embedded / IPv4-mapped / IPvFuture IPv6 literals: the
  // non-canonical-numeric rule above skips hosts containing ':', so these
  // opaque strings would otherwise pass a purely syntactic re-check, while a
  // browser/WebView resolves a dotted-quad-embedded literal to an embedded IPv4
  // address (::ffff:a.b.c.d, ::a.b.c.d, ...) or rejects IPvFuture [v...]
  // outright. Under a stale secure flag + test opt-in that differential could
  // grant in-app rendering and self-signed acceptance on a malformed/
  // mismatched host. Pure-hex loopback ::1 (a test-profile target) and real BMC
  // IPv6 addresses stay launchable — no valid target lost.
  if (_hasSpoofedIpv6Host(parsed.host)) return false;
  // Degenerate, label-less authority: a host made only of dots ('.', '..',
  // '%2E%2E' decoded by Uri to '..') is not a real BMC host. `Uri.tryParse`
  // still reports it as a non-empty HTTPS host, so without this check a stale
  // secure flag + test opt-in would grant in-app rendering and self-signed
  // acceptance on a bogus/traversal target. A real label (incl. an absolute
  // FQDN trailing dot) or an IPv6 literal contains non-dot characters and is
  // unaffected — stricter than the model, never more permissive.
  if (_hasDegenerateAuthorityHost(parsed)) return false;
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
///  4. A missing/blank **or control-unsafe** URI fails closed to copy-only with
///     a `null` target, so a launcher/clipboard is never handed an empty,
///     whitespace-padded, CRLF/NUL, raw-space, backslash or otherwise malformed
///     endpoint. Every non-null target is the shared control-safe trim of the
///     raw URI — the same rule every transport classifier applies — so the
///     copied value can never disagree with the classifiers about whether the
///     target is usable. Properly encoded targets (%20/%5C) are unchanged.
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
  final bool effectiveSecure = hasSecureUri && isSecureHttpsConsoleUri(uri);

  final KvmConsoleRenderRoute route = resolveRenderRoute(
    policy: policy,
    hasSecureUri: effectiveSecure,
    isHtml5: isHtml5,
    isEnabled: isEnabled,
  );

  // The URI handed to a launcher or the clipboard must itself be control-safe.
  // Re-validating only the *secure signal* above (effectiveSecure) still lets a
  // CRLF/NUL/raw-space/backslash/spoofed-authority target survive on the
  // copy-only route via a plain trim — where a pasted control character risks
  // header/clipboard injection or an authority that differs from the one the
  // classifier trusted. Reuse the single shared hardening core so the target
  // fails closed on exactly the malformed input every transport classifier
  // refuses to call secure (issues #009 / #021). Properly percent-encoded
  // targets (%20/%5C/...) and valid non-HTTP external-client URIs are untouched.
  final String? trimmed = _controlSafeTrimmedUri(uri);

  // Fail closed: a launchable route with no usable URI degrades to copy-only.
  final KvmConsoleRenderRoute safeRoute =
      trimmed == null && route != KvmConsoleRenderRoute.copyOnly
          ? KvmConsoleRenderRoute.copyOnly
          : route;

  // Gate self-signed acceptance on the *final* route being in-app: even the
  // test-only opt-in cannot weaken TLS on an external-browser/copy fallback.
  final bool acceptSelfSigned =
      safeRoute == KvmConsoleRenderRoute.inAppWebView &&
          policy.mayAcceptSelfSigned(
            hasSecureUri: effectiveSecure,
            isHtml5: isHtml5,
            isEnabled: isEnabled,
          );

  return KvmConsoleLaunchPlan._(
    route: safeRoute,
    // Always hand back the trimmed value (never the raw `uri`): even the
    // copy-only fallback is a user-facing clipboard/launcher target, so a
    // whitespace-padded endpoint must not leak through it. A null/blank URI is
    // already normalized to `null` above.
    targetUri: trimmed,
    acceptSelfSigned: acceptSelfSigned,
  );
}
