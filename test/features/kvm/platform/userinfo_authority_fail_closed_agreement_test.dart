/// EP-P17 (issue #009/#021) — encoded/embedded userinfo fail-closed cross-layer
/// agreement.
///
/// A BMC-supplied HTTPS console URI may legally carry `userinfo`
/// (`https://user:pass@host/console`) for the **initial** load — that documented
/// exception is navigation-only (EP-P11): an in-session navigation must never
/// inject attacker-chosen Basic-auth credentials into the trusted console frame,
/// while `planConsoleLaunch` still accepts such a URI as an in-app-eligible load
/// under the test-only opt-in.
///
/// No prior guard swept the *encoded / control / padded / multiple-`@` userinfo*
/// family across all four RP-1 decision layers at once. EP-P9 pins a hostile
/// AUTHORITY matrix (encoded-delimiter / numeric / control hosts) for the
/// platform↔model agreement; EP-P11 pins a single clean-credential case for the
/// nav↔launch exception; the `navigation_launch_authority_confusion` guard pins
/// a raw backslash-vs-`@` confusion shape. None drives the encoded-userinfo
/// family through the classifier, the launch plan (with a stale/lying secure
/// flag), the navigation gate and the model-layer plan together.
///
/// This guard pins that family: control/CRLF/encoded-delimiter/encoded-control/
/// padded userinfo fails closed everywhere (no in-app route, no self-signed
/// acceptance, no copy target, never navigable), while clean userinfo keeps the
/// documented navigation-only exception. Pure Dart + flutter_test: no WebView
/// import, no live BMC, no dependency, no production TLS behaviour change.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// Builds the model-layer console a BMC `ConnectUri` would produce, enabled and
/// HTML5 so a secure target exercises the strongest (in-app-eligible) signals.
KvmConsole _console(String? uri) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

void main() {
  const String console = 'https://bmc.example:8443/console';
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  // Encoded structural delimiter / percent / C0 control octet in the userinfo.
  // `Uri.tryParse` reports the SAME origin as the console for these, so an
  // origin-only gate or a decode-first launcher could treat them as the
  // trusted console while resolving a different credential/host. Every layer
  // must fail closed (the shared control-safety gate rejects them).
  const List<String> encodedUnsafeUserInfoUris = <String>[
    'https://user%40x:pass@bmc.example:8443/console', // encoded '@' in userinfo
    'https://user%40evil.com@bmc.example:8443/console', // encoded '@' spoof
    'https://user%3Apass@bmc.example:8443/console', // encoded ':' in userinfo
    'https://user:pa%0Ass@bmc.example:8443/console', // encoded LF
    'https://user%00:pass@bmc.example:8443/console', // encoded NUL
    'https://user%25x:pass@bmc.example:8443/console', // '%' double-decode
  ];

  // Raw control / separator code points in userinfo — never legal unescaped.
  const List<String> rawUnsafeUserInfoUris = <String>[
    'https:// us er : pass @bmc.example:8443/console', // raw spaces
    'https://user\t:pass@bmc.example:8443/console', // raw TAB
  ];

  // Multiple raw '@': a launcher splits authority on the LAST '@', so
  // `Uri.tryParse` reports no host / origin and the secure classifier fails
  // closed — yet the raw string is still control-safe as a COPY target. Pin
  // both halves of that contract.
  const List<String> multipleAtUserInfoUris = <String>[
    'https://u@example@bmc.example:8443/console',
  ];

  // Clean userinfo: the documented navigation-only exception stays scoped to
  // in-session navigation; the initial load may legitimately carry userinfo.
  const List<String> cleanUserInfoUris = <String>[
    'https://user:pass@bmc.example:8443/console',
    'https://admin@bmc.example:8443/console',
    'https://u:p@bmc.example/console',
    'https://user:pass@BMC.EXAMPLE:8443/console',
  ];

  KvmConsoleLaunchPlan planFor(String? uri, KvmWebViewPolicy policy) =>
      planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: isSecureHttpsConsoleUri(uri),
        isHtml5: true,
        isEnabled: true,
      );

  group('EP-P17 encoded/embedded userinfo fail-closed agreement', () {
    test('matrix is non-trivial and every shape carries userinfo', () {
      expect(encodedUnsafeUserInfoUris.length, 6);
      expect(rawUnsafeUserInfoUris.length, 2);
      expect(multipleAtUserInfoUris.length, 1);
      expect(cleanUserInfoUris.length, 4);
      final List<String> all = <String>[
        ...encodedUnsafeUserInfoUris,
        ...rawUnsafeUserInfoUris,
        ...multipleAtUserInfoUris,
        ...cleanUserInfoUris,
      ];
      expect(all.every((String u) => u.startsWith('https://')), isTrue);
      expect(all.every((String u) => u.contains('@')), isTrue);
    });

    test('encoded / control userinfo fails closed on all four layers', () {
      final List<String> hostile = <String>[
        ...encodedUnsafeUserInfoUris,
        ...rawUnsafeUserInfoUris,
      ];
      for (final String uri in hostile) {
        final String reason = 'uri=${uri.codeUnits}';
        expect(isSecureHttpsConsoleUri(uri), isFalse,
            reason: 'classifier accepted unsafe userinfo — $reason');
        expect(isControlSafeConsoleUri(uri), isFalse,
            reason: 'control-safe gate accepted unsafe userinfo — $reason');

        // A stale / lying secure signal still cannot reach an in-app route or
        // self-signed acceptance, and no copy target survives.
        final KvmConsoleLaunchPlan stale = planConsoleLaunch(
          policy: optIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );
        expect(stale.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'stale-flag in-app route — $reason');
        expect(stale.acceptSelfSigned, isFalse,
            reason: 'stale-flag self-signed — $reason');
        expect(stale.targetUri, isNull,
            reason: 'unsafe userinfo produced a copy target — $reason');

        // The truthful-signal plan and the navigation gate agree: no in-app
        // route, no self-signed acceptance, never navigable.
        final KvmConsoleLaunchPlan plan = planFor(uri, optIn);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'opt-in in-app route — $reason');
        expect(plan.acceptSelfSigned, isFalse, reason: reason);
        expect(plan.targetUri, isNull, reason: reason);
        expect(
            allowsInAppNavigation(consoleUri: console, targetUri: uri), isFalse,
            reason: 'navigation gate allowed unsafe userinfo — $reason');
      }
    });

    test('multiple-@ fails the secure classifier but stays a copy target', () {
      for (final String uri in multipleAtUserInfoUris) {
        final String reason = 'uri=${uri.codeUnits}';
        expect(isSecureHttpsConsoleUri(uri), isFalse,
            reason: 'classifier accepted multiple-@ authority — $reason');
        final KvmConsoleLaunchPlan plan = planFor(uri, optIn);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'in-app route on multiple-@ — $reason');
        expect(plan.acceptSelfSigned, isFalse, reason: reason);
        expect(plan.targetUri, isNotNull, reason: reason);
        expect(isControlSafeConsoleUri(plan.targetUri), isTrue, reason: reason);
        expect(
            allowsInAppNavigation(consoleUri: console, targetUri: uri), isFalse,
            reason: 'navigation gate allowed multiple-@ — $reason');
      }
    });

    test('model layer agrees field-for-field over the whole userinfo family',
        () {
      final List<String?> all = <String?>[
        ...encodedUnsafeUserInfoUris,
        ...rawUnsafeUserInfoUris,
        ...multipleAtUserInfoUris,
        ...cleanUserInfoUris,
      ];
      for (final String? uri in all) {
        final String reason = 'uri=${uri?.codeUnits}';
        final KvmConsole consoleModel = _console(uri);
        final bool platformSecure = isSecureHttpsConsoleUri(uri);
        expect(consoleModel.hasSecureLaunchUri, platformSecure,
            reason: 'classifier disagreement — $reason');

        final KvmConsoleLaunchPlan modelPlan = consoleModel.launchPlan;
        final KvmConsoleLaunchPlan directPlan = planConsoleLaunch(
          policy: production,
          uri: uri,
          hasSecureUri: platformSecure,
          isHtml5: consoleModel.supportsHtml5,
          isEnabled: consoleModel.serviceEnabled,
        );
        expect(modelPlan.route, directPlan.route,
            reason: 'cross-layer route disagreement — $reason');
        expect(modelPlan.targetUri, directPlan.targetUri,
            reason: 'cross-layer target disagreement — $reason');
        expect(modelPlan.acceptSelfSigned, directPlan.acceptSelfSigned,
            reason: 'cross-layer self-signed disagreement — $reason');
      }
    });

    test('clean userinfo stays a valid initial load but is navigation-only',
        () {
      for (final String uri in cleanUserInfoUris) {
        final String reason = 'uri=$uri';
        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: reason);
        expect(isControlSafeConsoleUri(uri), isTrue, reason: reason);
        expect(planFor(uri, optIn).isInApp, isTrue, reason: reason);
        // Never navigable in-session (Basic-auth injection surface).
        expect(
            allowsInAppNavigation(consoleUri: console, targetUri: uri), isFalse,
            reason: 'clean userinfo navigated in-app — $reason');
        // Test-only opt-in never leaks into production.
        final KvmConsoleLaunchPlan prod = planFor(uri, production);
        expect(prod.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: reason);
        expect(prod.acceptSelfSigned, isFalse, reason: reason);
      }
    });
  });
}
