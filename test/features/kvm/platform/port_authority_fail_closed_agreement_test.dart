/// EP-P16 (issue #009/#021) — nonstandard-port authority fail-closed agreement
/// across the platform decision layer.
///
/// EP-P9 pins cross-layer agreement over hostile/legitimate AUTHORITIES and
/// EP-P14 sweeps the scheme-SPELLING family, but no existing test drives the
/// PORT family (`https://host[:port]`) through all three decision layers at
/// once. Dart's `Uri.tryParse` is surprisingly permissive about the authority
/// port: it folds a *signed* port (`https://host:+443/console`) to port 443 and
/// a whitespace-padded port (`https://host: 443/console`) to 443, and it
/// reports an out-of-range port (`https://host:99999/console`) as a valid URI
/// whose host is non-empty. A future "just trust Uri.tryParse" refactor in one
/// layer could therefore call such a target secure / in-app-eligible while the
/// other layers still fail closed — a parser-differential authority-confusion
/// surface independent of TLS, hostname and navigation-origin checks.
///
/// This guard pins the documented fail-closed contract over the whole matrix:
///   * `isSecureHttpsConsoleUri`, `planConsoleLaunch` and
///     `allowsInAppNavigation` agree on every malformed / signed / non-numeric
///     / out-of-range port (no secure route, no in-app route, no same-origin
///     navigation, no self-signed acceptance under the test-only opt-in); and
///   * legitimate ports (omitted, `:443`, `:8443`, leading-zero `:0443`, `:0`,
///     `:65535`, IPv6-with-port) stay secure and external-browser launchable —
///     no over-rejection of a real BMC endpoint.
///
/// It also pins the model layer (`KvmConsole.launchPlan` / `hasSecureLaunchUri`,
/// which the console card and viewer gate on) field-for-field against the
/// platform plan over the same matrix, so a one-sided port edit cannot desync
/// the two call sites.
///
/// Pure Dart + flutter_test: no WebView import, no live BMC, no dependency, no
/// production TLS weakening (issues #009/#021).
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

  // Legitimate ports: an omitted port, the canonical :443, a common BMC :8443,
  // a leading-zero spelling (WHATWG folds :0443 -> 443), :0 and :65535 (both
  // inside the valid 0..65535 range), and an IPv6 literal with a valid port.
  // None may be over-rejected — these are real, launchable HTTPS endpoints.
  const List<String> legitimatePortUris = <String>[
    'https://bmc.example/console',
    'https://bmc.example:443/console',
    'https://bmc.example:8443/console',
    'https://bmc.example:0443/console',
    'https://bmc.example:0/console',
    'https://bmc.example:65535/console',
    'https://[2001:db8::1]:8443/console',
  ];

  // Malformed ports that a bare Uri.tryParse would mis-classify:
  //   :65536 / :99999  -> out of range, yet Uri reports a valid non-empty host;
  //   :abc             -> non-numeric (Uri.tryParse returns null);
  //   :+443            -> SIGNED, Uri silently folds to port 443 (the parser
  //                       differential this guard is primarily about);
  //   :-1              -> negative;
  //   IPv6 with an out-of-range / non-numeric port.
  // Every one must fail closed on ALL layers.
  const List<String> failClosedPortUris = <String>[
    'https://bmc.example:65536/console',
    'https://bmc.example:99999/console',
    'https://bmc.example:abc/console',
    'https://bmc.example:+443/console',
    'https://bmc.example:-1/console',
    'https://[2001:db8::1]:99999/console',
    'https://[2001:db8::1]:abc/console',
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

  group('EP-P16 port matrix classification', () {
    test('matrix is non-trivial and the two families are disjoint', () {
      expect(legitimatePortUris.length, 7);
      expect(failClosedPortUris.length, 7);
      expect(legitimatePortUris.toSet().length, 7);
      expect(failClosedPortUris.toSet().length, 7);
      expect(legitimatePortUris.first, 'https://bmc.example/console');
      expect(legitimatePortUris.any(failClosedPortUris.contains), isFalse);
      expect(failClosedPortUris.contains('https://bmc.example:+443/console'),
          isTrue);
    });

    test('legitimate ports classify as secure HTTPS', () {
      for (final String uri in legitimatePortUris) {
        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: why(uri));
        expect(isHttpConsoleUri(uri), isTrue, reason: why(uri));
      }
    });

    test('malformed ports are never secure HTTPS', () {
      for (final String uri in failClosedPortUris) {
        expect(isSecureHttpsConsoleUri(uri), isFalse, reason: why(uri));
      }
    });
  });

  group('EP-P16 three-layer fail-closed agreement', () {
    test('legitimate ports: secure + externalBrowser + same-origin nav', () {
      for (final String uri in legitimatePortUris) {
        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: why(uri));
        final KvmConsoleLaunchPlan plan = planFor(uri, production);
        expect(plan.route, KvmConsoleRenderRoute.externalBrowser,
            reason: why(uri));
        expect(plan.isInApp, isFalse, reason: why(uri));
        expect(plan.targetUri, uri, reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
        // A legitimate secure target may navigate to itself: both layers must
        // agree it is a real, same-origin HTTPS endpoint (no over-rejection).
        expect(allowsInAppNavigation(consoleUri: uri, targetUri: uri), isTrue,
            reason: why(uri));
      }
    });

    test('malformed ports: not secure + copyOnly + nav blocked', () {
      for (final String uri in failClosedPortUris) {
        expect(isSecureHttpsConsoleUri(uri), isFalse, reason: why(uri));
        final KvmConsoleLaunchPlan plan = planFor(uri, production);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: why(uri));
        expect(plan.isInApp, isFalse, reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
        expect(allowsInAppNavigation(consoleUri: uri, targetUri: uri), isFalse,
            reason: why(uri));
      }
    });

    test(
        'stale secure flag cannot grant in-app/self-signed for malformed ports',
        () {
      // A lying `hasSecureUri: true` must never defeat the raw-URI re-check:
      // effectiveSecure = flag AND isSecureHttpsConsoleUri(uri). This is the
      // load-bearing TLS-boundary case for the signed-port parser differential
      // (https://bmc.example:+443/console), which a bare Uri.tryParse folds to
      // a valid port 443.
      for (final String uri in failClosedPortUris) {
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

    test('legitimate ports stay in-app-eligible under the opt-in', () {
      // Guard against over-rejection: a legitimate secure-HTTPS port spelling
      // must not lose its documented test-only in-app eligibility (no TLS
      // weakening — this is the existing opt-in contract, not a new one).
      for (final String uri in legitimatePortUris) {
        final KvmConsoleLaunchPlan plan = planFor(uri, optIn);
        expect(plan.route, KvmConsoleRenderRoute.inAppWebView,
            reason: why(uri));
        expect(plan.targetUri, uri, reason: why(uri));
      }
    });

    test('production policy never in-app / self-signed over the whole matrix',
        () {
      expect(production.enabled, isFalse);
      expect(production.acceptsSelfSigned, isFalse);
      expect(production.bypassHostnameVerification, isFalse);
      for (final String uri in <String>[
        ...legitimatePortUris,
        ...failClosedPortUris,
      ]) {
        final KvmConsoleLaunchPlan plan =
            planFor(uri, production, secure: true);
        expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: why(uri));
        expect(plan.acceptSelfSigned, isFalse, reason: why(uri));
      }
    });
  });

  group('EP-P16 model/platform cross-layer agreement', () {
    test('model launchPlan agrees with platform plan field-for-field', () {
      for (final String uri in <String>[
        ...legitimatePortUris,
        ...failClosedPortUris,
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
