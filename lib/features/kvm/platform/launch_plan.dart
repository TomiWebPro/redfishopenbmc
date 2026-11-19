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
final RegExp _rawUriForbiddenChars = RegExp(r'[\\\p{C}\p{Z}]', unicode: true);

bool _uriHasSecureHttpsTarget(String? uri) {
  if (uri == null) return false;
  final String trimmed = uri.trim();
  if (trimmed.isEmpty) return false;
  // Reject any raw separator, control/format/invisible code point, or raw
  // backslash (delimiter/authority confusion). None are legal unescaped in a
  // URI; `%20`/`%5C`/`%XX` escapes contain none of them and stay launchable.
  if (_rawUriForbiddenChars.hasMatch(trimmed)) return false;
  final Uri? parsed = Uri.tryParse(trimmed);
  return parsed != null &&
      parsed.scheme == 'https' &&
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

  final String? trimmed = (uri == null || uri.trim().isEmpty)
      ? null
      : uri.trim();

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
