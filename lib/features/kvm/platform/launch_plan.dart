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
final RegExp _rawUriForbiddenChars =
    RegExp(r'[\\"<>{|}`^\p{C}\p{Z}]', unicode: true);

/// Matches a `%` that does not begin a valid `%XX` escape (RFC 3986
/// `pct-encoded = "%" HEXDIG HEXDIG`). Valid escapes contain no bare `%`.
final RegExp _malformedPercentEncoding = RegExp(r'%(?![0-9A-Fa-f]{2})');

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
  return trimmed;
}

/// Whether [uri] is a control-safe HTTP(S) URI with a host whose (Dart-
/// normalised, here lower-cased) scheme is in [schemes].
bool _isHttpUriWithSchemes(String? uri, Set<String> schemes) {
  final String? trimmed = _controlSafeTrimmedUri(uri);
  if (trimmed == null) return false;
  final Uri? parsed = Uri.tryParse(trimmed);
  return parsed != null &&
      schemes.contains(parsed.scheme.toLowerCase()) &&
      parsed.host.isNotEmpty;
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
          policy.mayAcceptSelfSigned(hasSecureUri: effectiveSecure);

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
