/// EP-P22 (issue #009/#021) — userinfo-edge authority cross-layer fail-closed
/// agreement.
///
/// A BMC-supplied HTTPS console URI may legally carry `userinfo`
/// (`https://user:pass@host/console`) for the *initial* load — that documented
/// exception is navigation-only (EP-P11/EP-P17): an in-session navigation must
/// never inject attacker-chosen Basic-auth credentials into the trusted console
/// frame, while `planConsoleLaunch` still accepts such a URI as an
/// in-app-eligible load under the test-only opt-in.
///
/// AUDIT FIRST: all four decision layers already delegate to the single
/// fail-closed core, so the encoded / control / raw-separator / multiple-`@`
/// userinfo family is uniformly classified by construction (EP-P17). The
/// genuinely unguarded edges are the *degenerate credential* shapes that no
/// existing guard drives:
///
///  * an empty credential pair — `https://:@host` (`Uri.userInfo == ':'`), and
///    an empty password — `https://user:@host` (`Uri.userInfo == 'user:'`).
///    Both are NON-empty `userInfo` strings, so the navigation gate's
///    `userInfo.isNotEmpty` check must fail closed; a "only block when a real
///    username is present" refactor would silently let the empty pair navigate.
///  * uppercase-hex percent escapes in the credentials (`%4A` vs `%4a`) must
///    classify/route identically to their lowercase spellings (either hex case).
///  * a clean bare-HTTPS-host control must stay secure and same-origin-navigable.
///
/// This guard pins that family across the shared classifier, `planConsoleLaunch`,
/// `allowsInAppNavigation` and the model `KvmConsole.hasSecureLaunchUri` /
/// `launchPlan`, with production-default never navigating in-app or accepting a
/// self-signed certificate. Pure Dart + flutter_test: no WebView import, no live
/// BMC, no dependency, no production TLS behaviour change.
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
  // Same origin as every matrix target, so the navigation gate's origin
  // comparison passes and ONLY the userinfo / host checks decide the verdict.
  const String console = 'https://bmc.example:8443/console';
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  // Degenerate credentials: `Uri.tryParse` reports a NON-empty `userInfo`
  // (':' / 'user:'), so the navigation gate must fail closed on them.
  const List<String> emptyCredentialUris = <String>[
    'https://:@bmc.example:8443/console', // empty user + password pair
    'https://user:@bmc.example:8443/console', // empty password
  ];

  // Uppercase-hex escapes in credentials must agree with lowercase spellings.
  const List<(String, String)> escapedCasePairs = <(String, String)>[
    (
      'https://%4Aser:pass@bmc.example:8443/console',
      'https://%4aser:pass@bmc.example:8443/console'
    ),
    (
      'https://user:%4Ass@bmc.example:8443/console',
      'https://user:%4ass@bmc.example:8443/console'
    ),
  ];

  // Clean bare HTTPS host: no userinfo, secure and same-origin-navigable.
  const String bareHostControl = 'https://bmc.example:8443/console';

  KvmConsoleLaunchPlan planFor(String? uri, KvmWebViewPolicy policy) =>
      planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: isSecureHttpsConsoleUri(uri),
        isHtml5: true,
        isEnabled: true,
      );

  group('EP-P22 userinfo-edge authority fail-closed agreement', () {
    test('matrix is non-trivial and each edge shape is as characterized', () {
      expect(emptyCredentialUris.length, 2);
      expect(escapedCasePairs.length, 2);
      for (final String uri in emptyCredentialUris) {
        final Uri? parsed = Uri.tryParse(uri);
        expect(parsed, isNotNull, reason: uri);
        // The whole point of the edge: userInfo is non-empty despite holding
        // no real credential (':' or 'user:').
        expect(parsed!.userInfo, isNotEmpty, reason: uri);
        expect(parsed.host, 'bmc.example', reason: uri);
        expect(parsed.port, 8443, reason: uri);
      }
      for (final (String upper, String lower) in escapedCasePairs) {
        expect(Uri.tryParse(upper)!.userInfo, Uri.tryParse(lower)!.userInfo,
            reason: 'hex case must decode identically: $upper / $lower');
      }
    });

    test('empty credential pair (:@) is never navigable in-session', () {
      for (final String uri in emptyCredentialUris) {
        final String reason = 'uri=${uri.codeUnits}';
        // Clean userinfo stays a secure HTTPS target and control-safe; the
        // initial load may legitimately carry it under the opt-in.
        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: reason);
        expect(isControlSafeConsoleUri(uri), isTrue, reason: reason);
        final KvmConsoleLaunchPlan load = planFor(uri, optIn);
        expect(load.isInApp, isTrue, reason: reason);
        expect(load.targetUri, isNotNull, reason: reason);
        expect(load.targetUri, contains('@'), reason: reason);

        // But an in-session navigation to the SAME origin carrying the empty
        // credential pair must fail closed (Basic-auth injection / user@host
        // display confusion). This is the EP-P22 edge no prior guard drives.
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: uri),
          isFalse,
          reason: 'empty credential pair navigated in-app — $reason',
        );

        // Production default never weakens TLS or navigates in-app.
        final KvmConsoleLaunchPlan prod = planFor(uri, production);
        expect(prod.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: reason);
        expect(prod.acceptSelfSigned, isFalse, reason: reason);
      }
    });

    test(
        'empty credentials cannot reach in-app even behind a stale secure flag',
        () {
      for (final String uri in emptyCredentialUris) {
        final String reason = 'uri=${uri.codeUnits}';
        final KvmConsoleLaunchPlan stale = planConsoleLaunch(
          policy: optIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );
        expect(stale.acceptSelfSigned, isTrue, reason: reason);
        // The navigation gate is policy-independent: a stale/lying secure flag
        // can never make the empty-credential target navigable.
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: uri),
          isFalse,
          reason: reason,
        );
      }
    });

    test('uppercase-hex credentials agree with lowercase across all layers',
        () {
      for (final (String upper, String lower) in escapedCasePairs) {
        final String reason = 'upper=$upper lower=$lower';
        expect(isSecureHttpsConsoleUri(upper), isSecureHttpsConsoleUri(lower),
            reason: 'classifier hex-case drift — $reason');
        expect(isControlSafeConsoleUri(upper), isControlSafeConsoleUri(lower),
            reason: 'control-safe hex-case drift — $reason');
        for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
          production,
          optIn
        ]) {
          final KvmConsoleLaunchPlan a = planFor(upper, policy);
          final KvmConsoleLaunchPlan b = planFor(lower, policy);
          expect(a.route, b.route, reason: reason);
          expect(a.targetUri, b.targetUri, reason: reason);
          expect(a.acceptSelfSigned, b.acceptSelfSigned, reason: reason);
        }
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: upper),
          allowsInAppNavigation(consoleUri: console, targetUri: lower),
          reason: 'navigation hex-case drift — $reason',
        );
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: upper),
          isFalse,
          reason: 'credential-bearing escaped target navigated — $reason',
        );
      }
    });

    test('clean bare-HTTPS host stays secure and same-origin-navigable', () {
      final String reason = 'control=$bareHostControl';
      expect(isSecureHttpsConsoleUri(bareHostControl), isTrue, reason: reason);
      expect(isControlSafeConsoleUri(bareHostControl), isTrue, reason: reason);
      expect(planFor(bareHostControl, optIn).isInApp, isTrue, reason: reason);
      // No userinfo: a same-origin navigation is allowed by the documented
      // exception, but cross-origin / cross-port never is.
      expect(
        allowsInAppNavigation(consoleUri: console, targetUri: bareHostControl),
        isTrue,
        reason: reason,
      );
      expect(
        allowsInAppNavigation(
            consoleUri: console, targetUri: 'https://bmc.example:9443/console'),
        isFalse,
        reason: reason,
      );
      final KvmConsoleLaunchPlan prod = planFor(bareHostControl, production);
      expect(prod.route, isNot(KvmConsoleRenderRoute.inAppWebView),
          reason: reason);
      expect(prod.acceptSelfSigned, isFalse, reason: reason);
    });

    test('model layer agrees field-for-field with the decision layer', () {
      final List<String> all = <String>[
        ...emptyCredentialUris,
        ...escapedCasePairs.map((r) => r.$1),
        ...escapedCasePairs.map((r) => r.$2),
        bareHostControl,
      ];
      for (final String uri in all) {
        final String reason = 'uri=$uri';
        final KvmConsole model = _console(uri);
        final bool secure = isSecureHttpsConsoleUri(uri);
        expect(model.hasSecureLaunchUri, secure,
            reason: 'classifier/model disagreement — $reason');
        final KvmConsoleLaunchPlan modelPlan = model.launchPlan;
        final KvmConsoleLaunchPlan direct = planFor(uri, production);
        expect(modelPlan.route, direct.route, reason: reason);
        expect(modelPlan.targetUri, direct.targetUri, reason: reason);
        expect(modelPlan.acceptSelfSigned, direct.acceptSelfSigned,
            reason: reason);
      }
    });
  });
}
