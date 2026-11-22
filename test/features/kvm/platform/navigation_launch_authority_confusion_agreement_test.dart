/// EP-P13 (issue #009/#021) — navigation-gate ↔ launch-route fail-closed
/// agreement over scheme-relative / network-path / encoded-authority tricks.
///
/// Two RP-1 decision functions consume the same BMC-supplied console URI:
///   * [allowsInAppNavigation] — the origin-confinement gate a future embedded
///     WebView consults for in-session redirects / link clicks / JS top-level
///     navigation; and
///   * [planConsoleLaunch] — the render-route decision for the initial load.
///
/// EP-P11 pins their agreement over CRLF/NUL/ZWSP/percent-escape targets in the
/// PATH/FRAGMENT. This guard closes the complementary AUTHORITY-confusion half:
/// scheme-relative network-path references (`//host/path`), an empty authority
/// with a path-shaped host (`https:///host`), percent-encoded slashes in the
/// authority, and backslash-vs-`@` userinfo/host confusion. These are the shapes
/// where Dart's `Uri` and a browser/WHATWG parser chronically disagree:
///   * a scheme-relative target has a host but NO scheme, so `Uri.origin`
///     THROWS (the navigation gate must catch that and fail closed);
///   * `https:///host` has a scheme but NO authority at all;
///   * a backslash before `@` is a path character to Dart but an authority
///     separator to a browser, flipping which host is actually contacted.
///
/// A one-sided edit to either call site could route such a target in-app while
/// the other still refuses it, with every isolated single-gate suite GREEN.
/// This guard pins that BOTH layers fail closed on the whole matrix, that the
/// navigation gate refuses in-app exactly when the launch plan refuses an
/// in-app route (excluding EP-P11's documented userinfo exception), and that
/// `KvmWebViewPolicy.productionDefault` never navigates in-app or accepts a
/// self-signed certificate.
///
/// Pure Dart + flutter_test: no WebView import, no live BMC, no dependency, no
/// production TLS behaviour change (issue #009/#021).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

void main() {
  const String console = 'https://bmc.example:8443/console';
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  // Authority-confusion targets. None is a trustworthy, credential-free,
  // same-origin HTTPS console endpoint; every one must fail closed on both
  // decision layers even under the test-only opt-in.
  const List<String> authorityConfusionTargets = <String>[
    '//bmc.example:8443/console', // scheme-relative network-path (no scheme)
    '//evil.example:8443/console', // scheme-relative, different host
    'https:///bmc.example/console', // scheme present, authority empty
    'https:/bmc.example/console', // single slash after scheme
    'https:%2f%2fbmc.example/console', // percent-encoded slashes
    'https://%2F%2Fbmc.example/console', // encoded slash inside authority
    r'https://evil.example\@bmc.example/console', // backslash-userinfo confusion
    r'https://bmc.example\@evil.example/console', // backslash-host confusion
    'https://bmc.example:8443/a\u202Eevil', // RTL-override in path
    'https://bmc.example:8443/a\u2066b\u2069', // bidi isolate marks in path
  ];

  // Legitimate, credential-free, same-origin targets: navigable AND (under the
  // test-only opt-in) in-app-eligible on the launch side. The fail-closed gate
  // must not over-reject valid endpoints.
  const List<String> legitimateTargets = <String>[
    'https://bmc.example:8443/console',
    'https://bmc.example:8443/other?tab=2#frag',
  ];

  KvmConsoleLaunchPlan planFor(String? uri, KvmWebViewPolicy policy) =>
      planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: isSecureHttpsConsoleUri(uri),
        isHtml5: true,
        isEnabled: true,
      );

  group('EP-P13 authority-confusion navigation ↔ launch agreement', () {
    test('matrix is non-trivial and actually exercises parser confusion', () {
      expect(authorityConfusionTargets.length, 10);
      expect(legitimateTargets.length, 2);
      for (final String target in authorityConfusionTargets) {
        expect(target.trim().isNotEmpty, isTrue, reason: target);
      }
      // The premise: a scheme-relative target has a host but no scheme, and an
      // empty-authority target has a scheme but no host. Neither can be called
      // a secure same-origin endpoint by a purely syntactic check.
      final Uri schemeRelative = Uri.parse('//bmc.example:8443/console');
      expect(schemeRelative.scheme, isEmpty);
      expect(schemeRelative.host, 'bmc.example');
      final Uri emptyAuthority = Uri.parse('https:///bmc.example/console');
      expect(emptyAuthority.scheme, 'https');
      expect(emptyAuthority.host, isEmpty);
    });

    test('every authority-confusion target fails closed on BOTH layers', () {
      for (final String target in authorityConfusionTargets) {
        final String reason = 'target=${target.codeUnits}';
        expect(isSecureHttpsConsoleUri(target), isFalse, reason: reason);
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isFalse,
          reason:
              'navigation gate accepted an authority-confusion target — $reason',
        );
        final KvmConsoleLaunchPlan plan = planFor(target, optIn);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason:
                'opt-in in-app route on an authority-confusion target — $reason');
        expect(plan.acceptSelfSigned, isFalse,
            reason:
                'self-signed accepted on an authority-confusion target — $reason');
        if (plan.targetUri != null) {
          expect(isControlSafeConsoleUri(plan.targetUri), isTrue,
              reason: 'non-control-safe copy target — $reason');
        }
      }
    });

    test('navigation gate refuses in-app exactly when the plan refuses it', () {
      // EP-P11's documented userinfo exception (nav=false while the initial
      // load is still in-app-eligible) is intentionally NOT in this matrix;
      // it is pinned by EP-P11. Over authority-confusion + legitimate targets
      // the two decision layers must agree one-for-one.
      final List<String> matrix = <String>[
        ...authorityConfusionTargets,
        ...legitimateTargets,
      ];
      for (final String target in matrix) {
        final bool navigable =
            allowsInAppNavigation(consoleUri: console, targetUri: target);
        final KvmConsoleLaunchPlan plan = planFor(target, optIn);
        expect(navigable, plan.isInApp,
            reason:
                'nav=$navigable plan=${plan.route} target=${target.codeUnits}');
      }
    });

    test('production default never routes in-app or accepts self-signed', () {
      final List<String> matrix = <String>[
        ...authorityConfusionTargets,
        ...legitimateTargets,
      ];
      for (final String target in matrix) {
        final String reason = 'target=${target.codeUnits}';
        final KvmConsoleLaunchPlan plan = planFor(target, production);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'in-app route under production — $reason');
        expect(plan.acceptSelfSigned, isFalse,
            reason: 'self-signed accepted under production — $reason');
      }
      expect(production.enabled, isFalse);
      expect(production.acceptsSelfSigned, isFalse);
      expect(production.bypassHostnameVerification, isFalse);
    });
  });
}
