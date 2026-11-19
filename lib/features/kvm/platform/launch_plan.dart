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
/// the `KvmConsole` / `KvmCapability` model transport classifiers. Because all
/// three call the same pure function, the UI's "is this console secure /
/// openable" decision can never disagree with the launch plan about a
/// malformed target.
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
/// NUL, TAB, DEL) into the host/path rather than rejecting them, so a purely
/// syntactic `scheme == 'https' && host.isNotEmpty` check would call such a
/// target "secure". A CRLF/NUL-bearing URI risks header/URI injection, so it is
/// rejected outright. This can only make classification stricter, so no valid
/// HTTPS endpoint is lost.
bool isSecureHttpsConsoleUri(String? uri) {
  if (uri == null) return false;
  final String trimmed = uri.trim();
  if (trimmed.isEmpty) return false;
  for (final int codeUnit in trimmed.codeUnits) {
    if (codeUnit < 0x20 || codeUnit == 0x7f) return false; // C0 controls / DEL
  }
  final Uri? parsed = Uri.tryParse(trimmed);
  return parsed != null && parsed.scheme == 'https' && parsed.host.isNotEmpty;
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
