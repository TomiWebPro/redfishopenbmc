/// EP-S9 (issues #009/#021) — credential-bearing secure-HTTPS "Primary" badge
/// ↔ in-app-navigation-gate decision-boundary characterization guard.
///
/// AUDIT finding. `KvmService.pickPrimary` badges the first openable secure-HTTPS
/// graphical console "Primary" and recommends it as the external-open target.
/// The single shared classifier `isSecureHttpsConsoleUri` treats a userinfo-
/// bearing HTTPS URI (`https://user:pass@bmc.example/console`) as a genuine
/// secure target (userinfo is legal in a URI and does not change the origin), so
/// such a console CAN be badged Primary. The separate in-app navigation gate
/// `allowsInAppNavigation`, however, fails closed on a credential-bearing
/// navigation target (login-CSRF / credential-injection / `user@host` display
/// confusion). That is a genuine cross-layer divergence: the badge recommends a
/// URI the gate refuses to navigate in-session. Which side is authoritative is
/// a deliberate human decision (EP-S8, stays BLOCKED) — so this guard never
/// blesses either side. It RECORDS the divergence and its direction as a stable
/// baseline (like RM-13) and pins the agreeing invariants around it:
///
///  * the navigation gate fails closed on userinfo (EP-P11), even when the
///    console itself is credential-free;
///  * `KvmWebViewPolicy.productionDefault` never renders in-app / accepts a
///    self-signed certificate (the final route is external-browser + copy);
///  * `pickPrimary` selection is deterministic (first secure graphical wins)
///    and `KvmConsole.fromManager` surfaces every physical console block;
///  * the documented initial-load credential exception stays navigation-scoped
///    only (test opt-in still renders the credentialed initial load in-app).
///
/// A refactor that silently resolves the divergence (e.g. making `pickPrimary`
/// skip credential-bearing consoles) MUST fail this guard so a human decides
/// EP-S8 deliberately. Pure model/service/platform layer: no Widget, no
/// WebView/protocol import, no URL opened, no dependency, no TLS change.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

void main() {
  const String credentialed = 'https://user:pass@bmc.example:8443/console';
  const String clean = 'https://bmc.example:8443/console';
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  KvmConsole console(
    KvmConsoleType type, {
    required String id,
    required bool enabled,
    String? uri,
  }) =>
      KvmConsole(
        type: type,
        managerId: id,
        serviceEnabled: enabled,
        connectUri: uri,
        sourceManagerUri: '/redfish/v1/Managers/$id',
      );

  KvmConsoleLaunchPlan planFor(String? uri, KvmWebViewPolicy policy) =>
      planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: isSecureHttpsConsoleUri(uri),
        isHtml5: true,
        isEnabled: true,
      );

  group('EP-S9 credential-bearing Primary ↔ navigation-gate boundary', () {
    test(
        'precondition: credentialed URI is a genuine same-origin secure HTTPS '
        'target (userinfo alone is neither malformed nor cross-origin)', () {
      expect(isSecureHttpsConsoleUri(credentialed), isTrue);
      expect(isSecureHttpsConsoleUri(clean), isTrue);
      expect(isControlSafeConsoleUri(credentialed), isTrue);
      final Uri parsed = Uri.parse(credentialed);
      expect(parsed.userInfo, 'user:pass');
      expect(parsed.origin, Uri.parse(clean).origin);
    });

    test(
        'RECORD: pickPrimary badges a credential-bearing secure graphical '
        'Primary while the navigation gate refuses that same URI (deferred '
        'EP-S8 decision — recorded, not blessed as authoritative)', () {
      final KvmConsole primary = console(
        KvmConsoleType.graphical,
        id: 'cred',
        enabled: true,
        uri: credentialed,
      );
      final KvmConsole backup = console(
        KvmConsoleType.graphical,
        id: 'clean',
        enabled: true,
        uri: clean,
      );
      expect(primary.hasSecureLaunchUri, isTrue);
      expect(primary.canOpenConsole, isTrue);

      final KvmConsole? chosen =
          KvmService.pickPrimary(<KvmConsole>[primary, backup]);
      expect(chosen, same(primary),
          reason: 'first secure graphical wins the Primary tier');

      // The divergence: the recommended Primary target carries credentials ...
      expect(chosen!.hasSecureLaunchUri, isTrue);
      expect(chosen.launchUri, credentialed);
      // ... yet an in-session navigation to that very URI fails closed.
      expect(
        allowsInAppNavigation(
          consoleUri: chosen.launchUri,
          targetUri: chosen.launchUri,
        ),
        isFalse,
        reason:
            'EP-S8 divergence — recorded as a stable baseline, not resolved',
      );
    });

    test(
        'RECORD: within-tier selection is first-wins, so the divergence '
        'follows BMC block ordering (characterization, not endorsement)', () {
      final KvmConsole cred = console(
        KvmConsoleType.graphical,
        id: 'cred',
        enabled: true,
        uri: credentialed,
      );
      final KvmConsole cleanConsole = console(
        KvmConsoleType.graphical,
        id: 'clean',
        enabled: true,
        uri: clean,
      );
      final KvmConsole? credentialedFirst =
          KvmService.pickPrimary(<KvmConsole>[cred, cleanConsole]);
      final KvmConsole? cleanFirst =
          KvmService.pickPrimary(<KvmConsole>[cleanConsole, cred]);

      expect(credentialedFirst, same(cred));
      expect(cleanFirst, same(cleanConsole));
      // Only the credentialed-first ordering exhibits the divergence.
      expect(
        allowsInAppNavigation(
          consoleUri: credentialedFirst!.launchUri,
          targetUri: credentialedFirst.launchUri,
        ),
        isFalse,
      );
      expect(
        allowsInAppNavigation(
          consoleUri: cleanFirst!.launchUri,
          targetUri: cleanFirst.launchUri,
        ),
        isTrue,
      );
    });

    test(
        'agreement: the navigation gate refuses a credentialed target even '
        'from a credential-free console', () {
      expect(
        allowsInAppNavigation(consoleUri: clean, targetUri: credentialed),
        isFalse,
        reason: 'userinfo in the target must never be navigated in-app',
      );
    });

    test(
        'agreement: a credential-free secure console stays navigable and '
        'in-app-eligible (the guard does not over-reject)', () {
      expect(
          allowsInAppNavigation(consoleUri: clean, targetUri: clean), isTrue);
      final KvmConsole? chosen = KvmService.pickPrimary(<KvmConsole>[
        console(
          KvmConsoleType.graphical,
          id: 'clean',
          enabled: true,
          uri: clean,
        ),
      ]);
      expect(chosen!.hasSecureLaunchUri, isTrue);
      expect(planFor(chosen.launchUri, optIn).isInApp, isTrue);
    });

    test(
        'agreement: production default never renders the credentialed console '
        'in-app nor accepts a self-signed certificate', () {
      final KvmConsoleLaunchPlan plan = planFor(credentialed, production);
      expect(plan.isInApp, isFalse);
      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.acceptSelfSigned, isFalse);
      expect(plan.targetUri, credentialed);
    });

    test(
        'agreement: test-only opt-in preserves the documented initial-load '
        'credential exception (navigation-scoped only)', () {
      final KvmConsoleLaunchPlan plan = planFor(credentialed, optIn);
      expect(plan.isInApp, isTrue);
      expect(plan.acceptSelfSigned, isTrue);
      expect(plan.targetUri, credentialed);
      // The same URI is still refused as an in-session navigation target.
      expect(
        allowsInAppNavigation(
          consoleUri: credentialed,
          targetUri: credentialed,
        ),
        isFalse,
      );
    });

    test(
        'agreement: fromManager surfaces every console block and preserves '
        'the credentialed URI byte-for-byte through the real pipeline', () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
            'ConnectUri': credentialed,
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP'],
            'ConnectUri': clean,
          },
        },
        managerId: 'BMC',
      );
      expect(consoles.length, 2);
      expect(consoles[0].type, KvmConsoleType.graphical);
      expect(consoles[0].launchUri, credentialed);
      expect(consoles[0].hasSecureLaunchUri, isTrue);
      expect(consoles[1].type, KvmConsoleType.remote);
      expect(consoles[1].launchUri, clean);

      // The real pipeline feeds pickPrimary, which badges the first secure
      // graphical (credentialed) Primary — the recorded divergence holds.
      final KvmConsole? chosen = KvmService.pickPrimary(consoles);
      expect(chosen, same(consoles[0]));
      expect(
        allowsInAppNavigation(
          consoleUri: chosen!.launchUri,
          targetUri: chosen.launchUri,
        ),
        isFalse,
      );
    });
  });
}
