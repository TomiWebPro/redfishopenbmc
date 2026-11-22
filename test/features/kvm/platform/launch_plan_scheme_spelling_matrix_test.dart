/// EP-P14 (issue #009/#021) — launch-plan route table over HTTP(S) *scheme
/// spellings*.
///
/// EP-P6 pins the production final-route invariants, EP-P9 pins cross-layer
/// agreement over hostile/legitimate AUTHORITIES, and EP-P13 pins the
/// navigation-gate x launch-route agreement over scheme-relative / encoded
/// authorities. None of them sweeps the SCHEME-SPELLING family through the
/// launch plan: only one isolated uppercase-`HTTPS:` case exists in
/// `launch_plan_test.dart`. A future "canonical-lowercase-only" or
/// "percent-decode the scheme before classifying" edit could silently move a
/// case-folded / encoded / control-bearing scheme from the documented
/// external-browser or copy-only route while every existing suite stayed GREEN.
///
/// This guard pins the `LAUNCH_FALLBACK.md` decision contract over that matrix:
///   * canonical secure-HTTPS spellings (case-folded / Zs-padded) stay secure
///     and route `externalBrowser` under `productionDefault` with a trimmed,
///     control-safe target; and
///   * every non-canonical spelling (percent-encoded scheme colon, scheme-
///     relative network-path, control-bearing scheme, plaintext HTTP, single
///     slash) degrades to `copyOnly` with a control-safe / null target, NEVER
///     `inAppWebView` and NEVER `acceptSelfSigned` — including under the
///     test-only opt-in with a stale/lying `hasSecureUri: true` signal, which
///     catches a future "trust the flag" regression at the TLS boundary.
///
/// It also pins the model layer (`KvmConsole.launchPlan`, which the console
/// card and viewer gate on) to the platform plan field-for-field over the same
/// matrix, so a one-sided scheme edit cannot desync the two call sites.
///
/// Pure Dart + flutter_test: no WebView import, no live BMC, no dependency, no
/// production TLS weakening (issue #009/#021).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// Builds the model-layer console a BMC `ConnectUri` would produce: enabled and
/// HTML5 so a secure spelling exercises the strongest (in-app-eligible) signals.
KvmConsole _console(String? uri) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

void main() {
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  // Secure HTTPS spellings: Dart's Uri.tryParse lower-cases the scheme and
  // String.trim strips Zs whitespace, so every one is a real HTTPS target with
  // a non-empty host. The route table requires them to stay external-browser
  // under production (never over-reject a valid endpoint).
  const List<String> secureSpellings = <String>[
    'https://bmc.example:8443/console', // canonical control
    'HTTPS://bmc.example:8443/console', // fully upper-case scheme
    'hTtPs://bmc.example:8443/console', // mixed-case scheme
    'HtTpS://bmc.example:8443/console', // mixed-case scheme (other fold)
    '  https://bmc.example:8443/console  ', // Zs-padded ConnectUri
  ];

  // Non-canonical scheme spellings: NOT a trustworthy secure-HTTPS target.
  // Every one must degrade to copyOnly with a control-safe / null target and
  // must never reach an in-app WebView or self-signed acceptance.
  const List<String> failClosedSpellings = <String>[
    'https%3A//bmc.example:8443/console', // percent-encoded scheme colon
    'https%3a//bmc.example:8443/console', // percent-encoded colon (lower hex)
    '//bmc.example:8443/console', // scheme-relative network-path (no scheme)
    'https\x00://bmc.example:8443/console', // NUL inside the scheme
    'https\t://bmc.example:8443/console', // TAB inside the scheme
    'http://bmc.example:8443/console', // plaintext HTTP scheme
    'HTTP://bmc.example:8443/console', // upper-case plaintext HTTP scheme
    'https:/bmc.example:8443/console', // single slash after scheme
  ];

  KvmConsoleLaunchPlan planFor(
    String uri,
    KvmWebViewPolicy policy, {
    bool? secure,
  }) =>
      planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: secure ?? isSecureHttpsConsoleUri(uri),
        isHtml5: true,
        isEnabled: true,
      );

  String why(String uri) => 'uri=${uri.codeUnits}';

  group('EP-P14 scheme-spelling matrix classification', () {
    test('matrix is non-trivial and covers distinct spellings', () {
      expect(secureSpellings.length, 5);
      expect(failClosedSpellings.length, 8);
      expect(secureSpellings.toSet().length, 5);
      expect(failClosedSpellings.toSet().length, 8);
      expect(secureSpellings.first, 'https://bmc.example:8443/console');
      expect(secureSpellings.any(failClosedSpellings.contains), isFalse);
    });

    test('canonical HTTPS spellings classify as secure', () {
      for (final String uri in secureSpellings) {
        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: why(uri));
      }
    });

    test('non-canonical scheme spellings are not secure HTTPS', () {
      for (final String uri in failClosedSpellings) {
        expect(isSecureHttpsConsoleUri(uri), isFalse, reason: why(uri));
      }
    });
  });

  group('EP-P14 production route table over scheme spellings', () {
    test('secure spellings stay externalBrowser with a trimmed target', () {
      for (final String uri in secureSpellings) {
        final KvmConsoleLaunchPlan plan = planFor(uri, production);
        expect(plan.route, KvmConsoleRenderRoute.externalBrowser,
            reason: why(uri));
        expect(plan.isInApp, isFalse, reason: why(uri));
        expect(plan.targetUri, uri.trim(), reason: why(uri));
        expect(isControlSafeConsoleUri(plan.targetUri), isTrue,
            reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
      }
    });

    test('non-canonical spellings degrade to copyOnly with a safe target', () {
      for (final String uri in failClosedSpellings) {
        final KvmConsoleLaunchPlan plan = planFor(uri, production);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: why(uri));
        expect(plan.isInApp, isFalse, reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
        final String? target = plan.targetUri;
        if (target != null) {
          expect(isControlSafeConsoleUri(target), isTrue, reason: why(uri));
        }
      }
    });
  });

  group('EP-P14 fail-closed at the TLS boundary', () {
    test('non-canonical spellings never render in-app under the opt-in', () {
      for (final String uri in failClosedSpellings) {
        final KvmConsoleLaunchPlan plan = planFor(uri, optIn);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
      }
    });

    test('stale secure flag cannot launch a non-canonical spelling in-app', () {
      // A lying `hasSecureUri: true` must never defeat the raw-URI re-check:
      // effectiveSecure = flag AND isSecureHttpsConsoleUri(uri), so none of
      // these may reach in-app rendering or self-signed acceptance even under
      // the test-only opt-in (issues #009/#021 — no production TLS weakening).
      for (final String uri in failClosedSpellings) {
        final KvmConsoleLaunchPlan plan = planFor(uri, optIn, secure: true);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
        final String? target = plan.targetUri;
        if (target != null) {
          expect(isControlSafeConsoleUri(target), isTrue, reason: why(uri));
        }
      }
    });

    test('canonical spellings stay in-app-eligible under the opt-in', () {
      // Guard against over-rejection: a case-folded or padded secure-HTTPS URI
      // must not lose its documented test-only in-app eligibility.
      for (final String uri in secureSpellings) {
        final KvmConsoleLaunchPlan plan = planFor(uri, optIn);
        expect(plan.route, KvmConsoleRenderRoute.inAppWebView,
            reason: why(uri));
        expect(plan.targetUri, uri.trim(), reason: why(uri));
      }
    });

    test('production policy never in-app / self-signed over the whole matrix',
        () {
      expect(production.enabled, isFalse);
      expect(production.acceptsSelfSigned, isFalse);
      expect(production.bypassHostnameVerification, isFalse);
      for (final String uri in <String>[
        ...secureSpellings,
        ...failClosedSpellings,
      ]) {
        final KvmConsoleLaunchPlan plan =
            planFor(uri, production, secure: true);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
      }
    });
  });

  group('EP-P14 cross-layer agreement over scheme spellings', () {
    test('model plan agrees with platform plan field-for-field', () {
      for (final String uri in <String>[
        ...secureSpellings,
        ...failClosedSpellings,
      ]) {
        final KvmConsole console = _console(uri);
        final KvmConsoleLaunchPlan platform = planFor(uri, production);
        final KvmConsoleLaunchPlan model = console.launchPlan;
        expect(console.hasSecureLaunchUri, isSecureHttpsConsoleUri(uri),
            reason: why(uri));
        expect(model.route, platform.route, reason: why(uri));
        expect(model.targetUri, platform.targetUri, reason: why(uri));
        expect(model.acceptSelfSigned, platform.acceptSelfSigned,
            reason: why(uri));
        expect(model.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: why(uri));
        expect(model.acceptSelfSigned, isFalse, reason: why(uri));
      }
    });
  });
}
