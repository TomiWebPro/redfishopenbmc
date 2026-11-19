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
/// `%20`/`%5C`/`%XX` escape sequences contain none of these, so properly encoded
/// targets pass. Shared by every HTTP(S) transport classifier so HTTPS and HTTP
/// classification and the launch-plan decision layer apply identical hardening.
final RegExp _rawUriForbiddenChars = RegExp(r'[\\\p{C}\p{Z}]', unicode: true);

/// Trims [uri] and returns it only when it is non-blank and contains no raw
/// control/separator/invisible code point, or `null` otherwise. Shared by every
/// HTTP(S) transport classifier so HTTPS and HTTP classification apply
/// identical hardening — `Uri.tryParse` alone percent-encodes those characters
/// instead of rejecting them.
String? _controlSafeTrimmedUri(String? uri) {
  if (uri == null) return null;
  final String trimmed = uri.trim();
  if (trimmed.isEmpty) return null;
  // C0/C1 controls, DEL, ASCII + Unicode spaces, invisible format chars and a
  // raw backslash are never legal raw in a URI; `%20`/`%5C`/`%XX` sequences
  // contain none of them, and an embedded one is not removed by `String.trim()`.
  if (_rawUriForbiddenChars.hasMatch(trimmed)) return null;
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
///  4. A missing/blank URI fails closed to copy-only so a launcher is never
///     handed a null/whitespace target; the URI is trimmed for **every** route
///     (including copy-only) so the clipboard/copy path never surfaces a
///     whitespace-padded endpoint either.
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
    // Always hand back the trimmed value (never the raw `uri`): even the
    // copy-only fallback is a user-facing clipboard/launcher target, so a
    // whitespace-padded endpoint must not leak through it. A null/blank URI is
    // already normalized to `null` above.
    targetUri: trimmed,
    acceptSelfSigned: acceptSelfSigned,
  );
}
