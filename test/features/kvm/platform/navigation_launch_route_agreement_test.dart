/// EP-P11 (issue #009/#021) — navigation-gate ↔ launch-route fail-closed
/// agreement over ONE shared authority matrix.
///
/// Two RP-1 decision functions consume the same BMC-supplied console URI:
///   * [allowsInAppNavigation] — the origin-confinement gate a future embedded
///     WebView consults for in-session redirects / link clicks / JS top-level
///     navigation; and
///   * [planConsoleLaunch] — the render-route decision for the initial load.
///
/// They are separate call sites. The navigation gate fails closed only because
/// it independently re-checks the target with the shared fail-closed classifier
/// [isSecureHttpsConsoleUri] BEFORE comparing `Uri.origin`. That extra check is
/// load-bearing: `Uri.tryParse` silently percent-encodes raw control / separator
/// / invisible characters into the host/path/fragment and still reports the
/// SAME origin as the console for several such targets. An origin-only gate (or
/// one that dropped the target classifier check) would navigate the trusted
/// console frame to a CRLF/NUL/ZWSP-bearing URL while the launch plan correctly
/// refused it — the exact #009 divergence class, with every isolated
/// `allowsInAppNavigation` test still GREEN (their hostile targets all parse to
/// a different/null origin, so the origin check alone already rejects them).
///
/// This guard pins the agreement over one shared matrix: any authority-safety-
/// hostile target fails closed on BOTH layers; anything the navigation gate
/// permits is also an in-app-eligible launch plan under the test-only opt-in;
/// and the documented userinfo exception stays scoped to navigation only.
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

  // Control / separator / invisible / malformed-escape characters in the PATH
  // or FRAGMENT. `Uri.tryParse` still reports the SAME origin as the console
  // (verified below), so an origin-only navigation check would wrongly allow
  // them; only the shared fail-closed classifier refuses them. Each one is a
  // header-injection / display-spoof / parser-differential vector.
  const List<String> sameOriginControlBearingTargets = <String>[
    'https://bmc.example:8443/console\u200B', // trailing zero-width space
    'https://bmc.example:8443/a\u00A0b', // NBSP (Unicode separator) in path
    'https://bmc.example:8443/a\tb', // raw TAB in path
    'https://bmc.example:8443/a%zz', // malformed percent escape
    'https://bmc.example:8443/#\x00', // raw NUL in fragment
    'https://bmc.example:8443/a\r\nX: 1', // CRLF header injection
    'https://bmc.example:8443/a\x00b', // raw NUL in path
    'https://bmc.example:8443/a b', // raw space in path
  ];

  // Other hostile targets: plaintext downgrade, a different origin/host/port,
  // and a credential-bearing same-origin target. None may be navigated in-app.
  const List<String> otherUnsafeTargets = <String>[
    'http://bmc.example:8443/console', // plaintext TLS downgrade
    'https://evil.example:8443/console', // different host
    'https://bmc.example:9443/console', // different port
    'https://user:pass@bmc.example:8443/console', // embedded credentials
  ];

  // Legitimate, credential-free, same-origin targets: navigable AND (under the
  // test-only opt-in) in-app-eligible on the launch side. The fail-closed gate
  // must not over-reject valid endpoints.
  const List<String> legitimateTargets = <String>[
    'https://bmc.example:8443/console',
    'https://bmc.example:8443/console?tab=2',
    'https://bmc.example:8443/other#frag',
    'https://bmc.example:8443/',
  ];

  KvmConsoleLaunchPlan planFor(String? uri, KvmWebViewPolicy policy) =>
      planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: isSecureHttpsConsoleUri(uri),
        isHtml5: true,
        isEnabled: true,
      );

  group('EP-P11 navigation ↔ launch-route fail-closed agreement', () {
    test(
        'matrix is non-trivial and the control-bearing targets are same-origin',
        () {
      expect(sameOriginControlBearingTargets.length, 8);
      expect(otherUnsafeTargets.length, 4);
      expect(legitimateTargets.length, 4);

      final String consoleOrigin = Uri.parse(console).origin;
      for (final String target in sameOriginControlBearingTargets) {
        final String reason = 'target=${target.codeUnits}';
        // The whole point of the guard: an origin-only check cannot save us.
        expect(Uri.tryParse(target)?.origin, consoleOrigin,
            reason: 'not same-origin per Uri.tryParse — $reason');
        expect(isSecureHttpsConsoleUri(target), isFalse,
            reason: 'classifier accepted a control-bearing target — $reason');
      }
    });

    test(
        'control-bearing SAME-ORIGIN targets fail closed on the navigation gate',
        () {
      // These are the cases the isolated navigation tests cannot cover (their
      // hostile targets parse to a different/null origin). Dropping the target-
      // side `isSecureHttpsConsoleUri` check in allowsInAppNavigation turns all
      // of these GREEN-to-RED: Uri.origin still matches the console.
      for (final String target in sameOriginControlBearingTargets) {
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isFalse,
          reason: 'navigated to a control-bearing target — ${target.codeUnits}',
        );
      }
    });

    test('authority-safety-hostile targets fail closed on BOTH layers', () {
      // Every target the secure classifier refuses must be rejected by the
      // navigation gate AND refused an in-app route / self-signed acceptance by
      // the launch plan (even under the test-only opt-in with a truthful secure
      // signal). This is the shared-matrix bridge between the two call sites.
      final List<String> hostile = <String>[
        ...sameOriginControlBearingTargets,
        'http://bmc.example:8443/console',
        'https://bmc.example%2Eevil.com/console', // encoded dot in authority
      ];
      for (final String target in hostile) {
        final String reason = 'target=${target.codeUnits}';
        expect(isSecureHttpsConsoleUri(target), isFalse, reason: reason);

        expect(allowsInAppNavigation(consoleUri: console, targetUri: target),
            isFalse,
            reason: 'navigation gate allowed a hostile authority — $reason');

        final KvmConsoleLaunchPlan plan = planFor(target, optIn);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'opt-in in-app route on a hostile authority — $reason');
        expect(plan.acceptSelfSigned, isFalse,
            reason: 'self-signed accepted on a hostile authority — $reason');
        if (plan.targetUri != null) {
          expect(isControlSafeConsoleUri(plan.targetUri), isTrue,
              reason: 'non-control-safe launch target — $reason');
        }
      }
    });

    test('a navigable target is always an in-app-eligible launch plan', () {
      // One-directional bridge: navigation is strictly stronger (secure HTTPS +
      // same-origin + credential-free), so anything it permits must also be a
      // control-safe secure-HTTPS target the opt-in plan renders in-app. A
      // one-sided weakening of either function breaks this implication.
      final List<String> matrix = <String>[
        ...sameOriginControlBearingTargets,
        ...otherUnsafeTargets,
        ...legitimateTargets,
      ];
      for (final String target in matrix) {
        final bool navigable =
            allowsInAppNavigation(consoleUri: console, targetUri: target);
        if (!navigable) continue;

        final KvmConsoleLaunchPlan plan = planFor(target, optIn);
        expect(isSecureHttpsConsoleUri(target), isTrue,
            reason: 'navigated a non-secure target — ${target.codeUnits}');
        expect(plan.isInApp, isTrue,
            reason:
                'navigable target refused an in-app route — ${target.codeUnits}');
        expect(isControlSafeConsoleUri(plan.targetUri), isTrue,
            reason: 'navigable target not control-safe — ${target.codeUnits}');
      }
    });

    test('legitimate same-origin targets navigate in-app on both layers', () {
      for (final String target in legitimateTargets) {
        final String reason = 'target=$target';
        expect(allowsInAppNavigation(consoleUri: console, targetUri: target),
            isTrue,
            reason: 'legitimate same-origin target not navigable — $reason');
        final KvmConsoleLaunchPlan plan = planFor(target, optIn);
        expect(plan.isInApp, isTrue, reason: reason);
        // Test-only opt-in only: never under the production default.
        expect(plan.acceptSelfSigned, isTrue, reason: reason);
        expect(plan.targetUri, target, reason: reason);
      }
    });

    test(
        'userinfo is navigation-only: not navigable, still a valid initial load',
        () {
      const String credentialed = 'https://user:pass@bmc.example:8443/console';
      // In-session navigation must not inject attacker-chosen Basic-auth into
      // the trusted console frame.
      expect(
        allowsInAppNavigation(consoleUri: console, targetUri: credentialed),
        isFalse,
      );
      // The *initial* load may legitimately carry userinfo — the launch plan
      // still treats it as a secure in-app target under the test-only opt-in.
      // Pin this so nobody "fixes" navigation by over-rejecting the load path.
      expect(isSecureHttpsConsoleUri(credentialed), isTrue);
      expect(planFor(credentialed, optIn).isInApp, isTrue);
    });

    test('production default never routes in-app or accepts self-signed', () {
      final List<String> matrix = <String>[
        ...sameOriginControlBearingTargets,
        ...otherUnsafeTargets,
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
    });
  });
}
