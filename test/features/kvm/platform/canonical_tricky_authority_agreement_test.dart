/// EP-P18 (issue #009/#021) — canonical-tricky authority spellings fail-closed
/// cross-layer agreement.
///
/// BMC-supplied HTTPS `ConnectUri` authorities come in several spellings that a
/// browser/WebView (WHATWG URL) parser may resolve differently from Dart's
/// `Uri.tryParse`: a single-trailing-dot absolute FQDN, IPv4-mapped / IPv4-
/// embedded IPv6 literals, an IPv6 zone id, compressed vs expanded vs uppercase-
/// hex IPv6, and an uppercase-hex integer host. Two independent decision families
/// consume the same raw URI:
///   * the **platform layer** — [isSecureHttpsConsoleUri], [planConsoleLaunch]
///     (render route + control-safe copy target + self-signed flag) and
///     [allowsInAppNavigation] (RP-1 origin confinement), and
///   * the **model layer** — `KvmConsole.hasSecureLaunchUri` / `launchStrategy` /
///     `canOpenConsole` / `launchPlan`, which the console card and viewer gate on.
///
/// They are meant to share one fail-closed core, but they are separate call
/// sites: a future edit that reimplements a bare `Uri.tryParse` scheme/host check
/// in one of them (the exact divergence class documented in `launch_plan.dart`
/// and EP-P9/EP-P11) could call a spoofed or unmappable authority "secure" on one
/// surface while another layer fails closed — with every existing single-surface
/// suite staying GREEN. This guard drives the whole canonical-tricky matrix
/// through ALL layers at once and pins, per shape, both the expected
/// classification (secure vs fail-closed) and cross-layer agreement. Legitimate
/// spellings (trailing-dot FQDN, compressed/expanded/uppercase IPv6, uppercase
/// DNS) must stay in-app-eligible under the test-only opt-in and never under
/// production; the unmappable/spoofed spellings (IPv4-mapped/embedded, zone id,
/// uppercase-hex integer host) must fail closed on every layer.
///
/// Pure Dart + flutter_test: no WebView import, no live BMC, no dependency, no
/// production TLS behaviour change (issues #009 / #021). Complements EP-P9
/// (generic hostile authorities) and EP-P16 (port family) with the canonical-
/// tricky authority-spelling family.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// One canonical-tricky authority spelling and its expected secure classification
/// under the shared fail-closed core.
class _Case {
  const _Case(this.family, this.uri, this.secure);

  final String family;
  final String uri;
  final bool secure;
}

// Classifications below are CHARACTERIZATIONS of the current shared core,
// verified with `isSecureHttpsConsoleUri` across all four layers: a genuine
// trailing-dot FQDN / real IPv6 literal / uppercase DNS stays secure, while an
// IPv4-mapped or zone-id/hex-integer authority a browser cannot map consistently
// fails closed. The `uri` strings are otherwise clean (no control chars), so the
// matrix isolates the AUTHORITY-SPELLING axis from the control/delimiter axis.
const List<_Case> kMatrix = <_Case>[
  _Case('clean-control', 'https://bmc.example/console', true),
  _Case('trailing-dot-fqdn', 'https://bmc.example./console', true),
  _Case('ipv4-mapped-quad', 'https://[::ffff:192.168.1.10]/console', false),
  _Case('ipv4-mapped-hex', 'https://[::ffff:c0a8:10a]/console', false),
  _Case('ipv6-zone-id', 'https://[fe80::1%25eth0]/console', false),
  _Case('ipv6-compressed', 'https://[2001:db8::1]/console', true),
  _Case('ipv6-expanded',
      'https://[2001:0db8:0000:0000:0000:0000:0000:0001]/console', true),
  _Case('ipv6-uppercase-hex', 'https://[2001:DB8::1]/console', true),
  _Case('uppercase-hex-integer', 'https://0X7F000001/console', false),
  _Case('uppercase-dns', 'https://BMC.EXAMPLE/console', true),
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

  group('EP-P18 canonical-tricky authority cross-layer agreement', () {
    test('matrix is non-trivial and spans both classifications', () {
      expect(kMatrix.length, 10);
      expect(kMatrix.where((_Case c) => c.secure).length, 6);
      expect(kMatrix.where((_Case c) => !c.secure).length, 4);
      expect(kMatrix.map((_Case c) => c.family).toSet().length, kMatrix.length);
      expect(
          kMatrix.singleWhere((_Case c) => c.family == 'clean-control').secure,
          isTrue);
      expect(kMatrix.every((_Case c) => c.uri.startsWith('https')), isTrue);
    });

    test(
        'per-shape classification is pinned and classifiers agree on every '
        'layer', () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        final bool platformSecure = isSecureHttpsConsoleUri(c.uri);

        // Platform-side expected classification (the characterization pin).
        expect(platformSecure, c.secure, reason: 'classifier drift — $why');

        // Model side must agree, field for field, with the platform classifier.
        final KvmConsole console = _console(c.uri);
        expect(console.hasSecureLaunchUri, c.secure,
            reason: 'model classification drift — $why');
        expect(console.hasSecureLaunchUri, platformSecure,
            reason: 'cross-layer classifier disagreement — $why');
        expect(console.canOpenConsole, c.secure,
            reason: 'model openability disagrees with classification — $why');
        // An enabled HTML5 secure console selects the in-app strategy on the
        // model side; a fail-closed spelling selects none (no usable target).
        expect(
          console.launchStrategy,
          c.secure ? KvmLaunchStrategy.inAppHtml5 : KvmLaunchStrategy.noUri,
          reason: 'model launch strategy disagrees with classification — $why',
        );
      }
    });

    test(
        'production plan never routes in-app or accepts self-signed; model '
        'plan agrees field-for-field', () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // A stale/lying secure flag must still fail closed on a spoofed shape.
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

        // Secure shapes are handed to the external browser under production;
        // fail-closed shapes degrade to copy-only (never a launchable target).
        expect(
            platform.route,
            c.secure
                ? KvmConsoleRenderRoute.externalBrowser
                : KvmConsoleRenderRoute.copyOnly,
            reason: 'production route classification drift — $why');
      }
    });

    test(
        'opt-in eligibility is uniform per shape: only secure authorities '
        'become in-app-eligible', () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        final KvmConsoleLaunchPlan plan = _plan(optIn, c.uri);
        if (c.secure) {
          expect(plan.route, KvmConsoleRenderRoute.inAppWebView,
              reason: 'genuine secure spelling not opt-in eligible — $why');
          expect(plan.acceptSelfSigned, isTrue,
              reason:
                  'opt-in self-signed not granted to secure spelling — $why');
        } else {
          expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
              reason: 'spoofed spelling reached in-app under opt-in — $why');
          expect(plan.acceptSelfSigned, isFalse,
              reason:
                  'spoofed spelling accepted self-signed under opt-in — $why');
        }
      }
    });

    test(
        'navigation gate agrees with the classifier on the same-origin '
        'instance and fails closed on a cross-origin target', () {
      for (final _Case c in kMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        // Same authority used as both console and navigation target: the
        // navigation gate must classify it exactly as the launch classifier.
        expect(
          allowsInAppNavigation(consoleUri: c.uri, targetUri: c.uri),
          c.secure,
          reason: 'navigation gate disagrees with classifier — $why',
        );
        // A different origin is never navigable in-app, independent of spelling.
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

    test('equivalent IPv6 spellings agree with each other on every layer', () {
      const List<String> sameAddress = <String>[
        'https://[2001:db8::1]/console',
        'https://[2001:0db8:0000:0000:0000:0000:0000:0001]/console',
        'https://[2001:DB8::1]/console',
      ];
      for (final String uri in sameAddress) {
        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: uri);
        expect(_console(uri).hasSecureLaunchUri, isTrue, reason: uri);
        expect(_plan(optIn, uri).route, KvmConsoleRenderRoute.inAppWebView,
            reason: uri);
        expect(
            _plan(production, uri).route, KvmConsoleRenderRoute.externalBrowser,
            reason: uri);
        expect(
          allowsInAppNavigation(consoleUri: uri, targetUri: uri),
          isTrue,
          reason: uri,
        );
      }
    });
  });
}
