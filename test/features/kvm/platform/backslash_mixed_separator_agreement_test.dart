/// EP-P20 (issue #009/#021) — backslash / mixed-separator authority-confusion
/// fail-closed cross-layer agreement.
///
/// A browser / WebView (WHATWG URL) parser treats a backslash as an authority
/// separator in `http(s)` URLs, while Dart's `Uri.tryParse` treats it as a path
/// character (or percent-encodes it). Shapes that mix `/` and `\` therefore name
/// DIFFERENT authorities to the two parsers:
///   * `https://trusted.example\@evil.example/x` — a browser reads the host as
///     `evil.example` (backslash terminates the userinfo), Dart reads a path;
///   * `https:\/\/evil.example/x` — a browser accepts the backslash slashes,
///     Dart's parser normalises them differently;
///   * `%5C` / `%5c` in the authority — a decode-first launcher sees a host
///     separator where `Uri.tryParse` reports an opaque, non-empty HTTPS host.
///
/// Two independent decision families consume the same raw BMC `ConnectUri`:
///   * the **platform layer** — [isSecureHttpsConsoleUri], [planConsoleLaunch]
///     (render route + control-safe copy target + self-signed flag) and
///     [allowsInAppNavigation] (RP-1 origin confinement); and
///   * the **model layer** — `KvmConsole.hasSecureLaunchUri` /
///     `canOpenConsole` / `launchStrategy` / `launchPlan`, gated by the console
///     card and viewer.
///
/// EP-P13 pins two backslash-vs-`@` spellings on the platform layers only. This
/// guard closes the complementary family: the full mixed-separator matrix (raw
/// `\` before `@`, after the scheme, inside the host, in the path; `%5C` in the
/// authority, both hex cases) driven through ALL layers at once, plus the stale
/// secure-flag TLS boundary and field-for-field model/launch-plan agreement.
/// A one-sided edit that reimplements a bare `Uri.tryParse` scheme/host check on
/// any single layer (the divergence class documented in `launch_plan.dart`) could
/// call a spoofed shape "secure" there while every single-surface suite stays
/// GREEN. This guard pins that the whole matrix fails closed uniformly on every
/// layer while the clean HTTPS control stays external-browser launchable and
/// same-origin navigable.
///
/// Pure Dart + flutter_test: no WebView import, no live BMC, no dependency, no
/// production TLS behaviour change (issues #009 / #021). Complements EP-P13
/// (scheme-relative / encoded-authority) and EP-P18 (canonical-tricky spellings)
/// with the backslash / mixed-separator family.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// One backslash / mixed-separator `ConnectUri` and its expected classification
/// under the shared fail-closed core. All hostile shapes are expected to fail
/// closed; the clean controls are expected to stay secure.
class _Case {
  const _Case(this.family, this.uri, this.secure);

  final String family;
  final String uri;
  final bool secure;
}

// Classifications below are CHARACTERIZATIONS of the current shared core
// (`_controlSafeTrimmedUri` rejects every raw backslash and every pct-encoded
// structural delimiter in the authority), verified across all four layers. The
// hostile shapes carry only the backslash / mixed-separator axis — no raw
// control/format characters — so the matrix isolates that axis from EP-P11's
// control family and EP-P13's scheme-relative family.
const List<_Case> kMatrix = <_Case>[
  _Case('clean-control', 'https://bmc.example:8443/console', true),
  _Case(
      'clean-control-query', 'https://bmc.example:8443/other?tab=2#frag', true),
  // Raw backslash / mixed separator: authority-confusion across the two parsers.
  _Case('backslash-userinfo-right', r'https://trusted.example\@evil.example/x',
      false),
  _Case('backslash-userinfo-left', r'https://evil.example\@trusted.example/x',
      false),
  _Case('backslash-scheme-slashes', r'https:\/\/evil.example/x', false),
  _Case('backslash-host', r'https://bmc.example\evil.example/console', false),
  _Case('backslash-userinfo-port',
      r'https://bmc.example\@evil.example:8443/console', false),
  _Case('backslash-path-at', r'https://bmc.example:8443/console\@evil.example',
      false),
  // Percent-encoded backslash in the authority (both hex cases): a decode-first
  // launcher sees a host separator where Dart reports an opaque HTTPS host.
  _Case('encoded-backslash-upper', 'https://bmc.example%5C@evil.example/x',
      false),
  _Case('encoded-backslash-lower', 'https://bmc.example%5c.evil.example/x',
      false),
  _Case('encoded-backslash-host', 'https://bmc.example%5Cevil.example/console',
      false),
];

KvmConsole _console(String? uri) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

KvmConsoleLaunchPlan _plan(KvmWebViewPolicy policy, String uri) =>
    planConsoleLaunch(
      policy: policy,
      uri: uri,
      hasSecureUri: isSecureHttpsConsoleUri(uri),
      isHtml5: true,
      isEnabled: true,
    );

void main() {
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;
  const String cleanConsole = 'https://bmc.example:8443/console';

  group('EP-P20 backslash / mixed-separator cross-layer agreement', () {
    test('matrix is non-trivial and isolates the separator axis', () {
      expect(kMatrix.length, 11);
      expect(kMatrix.where((_Case c) => c.secure).length, 2);
      expect(kMatrix.where((_Case c) => !c.secure).length, 9);
      expect(kMatrix.map((_Case c) => c.family).toSet().length, kMatrix.length);
      expect(
          kMatrix.singleWhere((_Case c) => c.family == 'clean-control').secure,
          isTrue);
      for (final _Case c in kMatrix.where((_Case c) => !c.secure)) {
        // Every hostile shape carries a raw backslash or an encoded separator.
        expect(c.uri.contains('\\') || c.uri.contains('%5'), isTrue,
            reason: 'family=${c.family}');
      }
      // The premise: a browser and Dart disagree about a mixed-separator URI.
      // A WHATWG parser accepts `\` as an authority separator and reads
      // `evil.example` as the host; Dart's Uri.parse reports no host at all for
      // the backslash-slash form — the two parsers name different authorities.
      final Uri parsed = Uri.parse(r'https:\/\/evil.example/x');
      expect(parsed.scheme, 'https');
      expect(parsed.host, isEmpty);
    });

    test('per-shape classification is pinned and every layer agrees', () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        final bool platformSecure = isSecureHttpsConsoleUri(c.uri);

        expect(platformSecure, c.secure, reason: 'classifier drift — $why');

        final KvmConsole console = _console(c.uri);
        expect(console.hasSecureLaunchUri, c.secure,
            reason: 'model classification drift — $why');
        expect(console.hasSecureLaunchUri, platformSecure,
            reason: 'cross-layer classifier disagreement — $why');
        expect(console.canOpenConsole, c.secure,
            reason: 'model openability disagrees with classification — $why');
        expect(
          console.launchStrategy,
          c.secure ? KvmLaunchStrategy.inAppHtml5 : KvmLaunchStrategy.noUri,
          reason: 'model launch strategy disagrees with classification — $why',
        );
      }
    });

    test(
        'stale-flag production plan fails closed; model plan agrees field-for-field',
        () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // A stale/lying secure flag must never grant an in-app route or
        // self-signed acceptance, even on a hostile mixed-separator shape.
        final KvmConsoleLaunchPlan stale = planConsoleLaunch(
          policy: production,
          uri: c.uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );
        expect(stale.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'in-app route under production — $why');
        expect(stale.acceptSelfSigned, isFalse,
            reason: 'self-signed under production — $why');
        if (stale.targetUri != null) {
          expect(isControlSafeConsoleUri(stale.targetUri), isTrue,
              reason: 'non-control-safe copy target — $why');
        }

        final KvmConsoleLaunchPlan platform = _plan(production, c.uri);
        final KvmConsoleLaunchPlan model = _console(c.uri).launchPlan;
        expect(model.route, platform.route,
            reason: 'cross-layer route disagreement — $why');
        expect(model.targetUri, platform.targetUri,
            reason: 'cross-layer target disagreement — $why');
        expect(model.acceptSelfSigned, platform.acceptSelfSigned,
            reason: 'cross-layer self-signed disagreement — $why');
        expect(model.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'model in-app route under production — $why');
        expect(model.acceptSelfSigned, isFalse,
            reason: 'model self-signed under production — $why');

        expect(
          platform.route,
          c.secure
              ? KvmConsoleRenderRoute.externalBrowser
              : KvmConsoleRenderRoute.copyOnly,
          reason: 'production route classification drift — $why',
        );
      }
    });

    test(
        'opt-in eligibility is uniform: only clean shapes become in-app-eligible',
        () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        final KvmConsoleLaunchPlan plan = _plan(optIn, c.uri);
        if (c.secure) {
          expect(plan.route, KvmConsoleRenderRoute.inAppWebView,
              reason: 'clean shape not opt-in eligible — $why');
          expect(plan.acceptSelfSigned, isTrue,
              reason: 'opt-in self-signed not granted to clean shape — $why');
        } else {
          expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
              reason:
                  'mixed-separator shape reached in-app under opt-in — $why');
          expect(plan.acceptSelfSigned, isFalse,
              reason:
                  'mixed-separator shape accepted self-signed under opt-in — $why');
        }
      }
    });

    test(
        'navigation gate agrees with the classifier on the same-origin instance',
        () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        expect(
          allowsInAppNavigation(consoleUri: c.uri, targetUri: c.uri),
          c.secure,
          reason: 'navigation gate disagrees with classifier — $why',
        );
        expect(
          allowsInAppNavigation(
            consoleUri: c.uri,
            targetUri: 'https://other.example/console',
          ),
          isFalse,
          reason: 'cross-origin target navigable in-app — $why',
        );
      }
    });

    test('hostile targets against a clean console never navigate in-app', () {
      for (final _Case c in kMatrix) {
        final bool navigable = allowsInAppNavigation(
          consoleUri: cleanConsole,
          targetUri: c.uri,
        );
        expect(navigable, c.secure,
            reason: 'family=${c.family} nav=$navigable expected=${c.secure}');
      }
    });
  });
}
