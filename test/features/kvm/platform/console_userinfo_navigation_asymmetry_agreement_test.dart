/// EP-P28 (issues #009/#021) — console-side userinfo vs navigation-target
/// userinfo asymmetry agreement guard.
///
/// AUDIT FIRST: `allowsInAppNavigation` (lib/features/kvm/platform/launch_plan.dart)
/// scopes its embedded-credential guard to the navigation TARGET only
/// (`if (target.userInfo.isNotEmpty) return false;`). A credentialed console
/// (`https://user:pass@bmc.example/console`) is a legal *initial* secure-HTTPS
/// load — `planConsoleLaunch` accepts it, and `Uri.origin` deliberately ignores
/// userinfo — so a same-origin, credential-FREE in-session navigation target
/// must stay navigable. The function's own doc comment records this asymmetry:
/// "the initial credentialed console load is a separate path and is
/// unaffected; only in-session navigation targets must be credential-free."
///
/// NO existing test drives a credentialed CONSOLE with a credential-free target:
/// every userinfo case puts the credential in the target (often on both sides,
/// which is already fail-closed). A plausible "userinfo is unsafe anywhere"
/// hardening that adds `if (console.userInfo.isNotEmpty) return false;` would
/// over-reject the documented initial-load exception while every existing suite
/// stayed GREEN (their credentialed-console calls all use a credentialed target,
/// and their true-expectation calls use a clean console). This guard pins the
/// asymmetry so that a one-sided over-rejection fails closed.
///
/// Pure unit tests: no Widget, no WebView / protocol import, no URL opened, no
/// dependency, no production TLS change.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

void main() {
  const String credentialed = 'https://user:pass@bmc.example:8443/console';
  const String credentialedNoPort = 'https://user:pass@bmc.example/console';
  const String clean = 'https://bmc.example:8443/console';
  const String cleanQuery = 'https://bmc.example:8443/console?tab=2';
  const String cleanOtherPath = 'https://bmc.example:8443/other';
  const String cleanDefaultPort = 'https://bmc.example:443/console';
  const String otherOrigin = 'https://other.example:8443/console';
  const String plaintextConsole = 'http://user:pass@bmc.example:8443/console';

  group('EP-P28 console-side userinfo ↔ navigation-target asymmetry', () {
    test(
        'precondition: credentialed console is a secure same-origin HTTPS '
        'target (userinfo is neither malformed nor cross-origin)', () {
      expect(isSecureHttpsConsoleUri(credentialed), isTrue);
      expect(isSecureHttpsConsoleUri(credentialedNoPort), isTrue);
      expect(isSecureHttpsConsoleUri(clean), isTrue);
      expect(isSecureHttpsConsoleUri(cleanQuery), isTrue);
      expect(isSecureHttpsConsoleUri(cleanDefaultPort), isTrue);
      final Uri parsed = Uri.parse(credentialed);
      expect(parsed.userInfo, 'user:pass');
      expect(parsed.origin, Uri.parse(clean).origin);
    });

    test(
        'a credentialed console may navigate to a credential-free '
        'same-origin target (target-scoped credential guard)', () {
      expect(
        allowsInAppNavigation(consoleUri: credentialed, targetUri: clean),
        isTrue,
        reason: 'userinfo on the console is the legal initial-load path; the '
            'navigation guard must not over-reject it',
      );
    });

    test(
        'the exception holds for credential-free path / query variants at '
        'the same origin', () {
      for (final String target in <String>[cleanQuery, cleanOtherPath]) {
        expect(
          allowsInAppNavigation(consoleUri: credentialed, targetUri: target),
          isTrue,
          reason: 'target=$target',
        );
      }
    });

    test(
        'the exception holds when the console omits the default port '
        '(Uri.origin collapses :443, userinfo ignored)', () {
      expect(
        allowsInAppNavigation(
          consoleUri: credentialedNoPort,
          targetUri: cleanDefaultPort,
        ),
        isTrue,
      );
    });

    test(
        'the target-side credential guard still holds from a credentialed '
        'console', () {
      expect(
        allowsInAppNavigation(
            consoleUri: credentialed, targetUri: credentialed),
        isFalse,
        reason: 'userinfo introduced by the navigation target must be refused',
      );
      expect(
        allowsInAppNavigation(
          consoleUri: credentialed,
          targetUri: 'https://user:pw@bmc.example:8443/console?x=1',
        ),
        isFalse,
      );
    });

    test('origin confinement still holds from a credentialed console', () {
      expect(
        allowsInAppNavigation(consoleUri: credentialed, targetUri: otherOrigin),
        isFalse,
      );
    });

    test(
        'a non-HTTPS credentialed console still fails closed (secure-target '
        'validation precedes any userinfo handling)', () {
      expect(isSecureHttpsConsoleUri(plaintextConsole), isFalse);
      expect(
        allowsInAppNavigation(consoleUri: plaintextConsole, targetUri: clean),
        isFalse,
      );
    });

    test(
        'cross-layer: the credentialed initial load is in-app under opt-in '
        'while the asymmetric navigation gate stays target-scoped', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: credentialed,
        hasSecureUri: isSecureHttpsConsoleUri(credentialed),
        isHtml5: true,
        isEnabled: true,
      );
      expect(plan.isInApp, isTrue);
      expect(plan.targetUri, credentialed);
      // Navigation half of the same documented exception:
      expect(
        allowsInAppNavigation(consoleUri: credentialed, targetUri: clean),
        isTrue,
      );
      expect(
        allowsInAppNavigation(
            consoleUri: credentialed, targetUri: credentialed),
        isFalse,
      );
    });
  });
}
