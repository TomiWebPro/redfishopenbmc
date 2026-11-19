import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

void main() {
  group('planConsoleLaunch — flag OFF keeps the production fallback', () {
    test('secure HTTPS HTML5 routes to the external browser with its URI', () {
      const KvmWebViewPolicy policy = KvmWebViewPolicy.productionDefault;
      const String uri = 'https://bmc.example/console';

      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.isExternalBrowser, isTrue);
      expect(plan.isInApp, isFalse);
      expect(plan.targetUri, uri);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('plaintext HTTP falls back to copy-only, never self-signed', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'http://bmc.example/console',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isCopyOnly, isTrue);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a missing URI yields a null target and copy-only route', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: null,
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.targetUri, isNull);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a blank URI is never handed to a launcher as a target', () {
      // Inconsistent input (secure flag set but no real URI) must still fail
      // closed: downgrade to copy-only instead of launching whitespace.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: '   ',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.acceptSelfSigned, isFalse);
    });
  });

  group('planConsoleLaunch — opt-in is reversible and TLS-safe', () {
    test('test opt-in on HTTPS selects in-app and allows self-signed', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.inAppWebView);
      expect(plan.isInApp, isTrue);
      expect(plan.targetUri, 'https://bmc.example/console');
      expect(plan.acceptSelfSigned, isTrue);
    });

    test('opt-in with strict TLS never accepts self-signed', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: enabledStrict,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.inAppWebView);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('opt-in still refuses plaintext HTTP entirely', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'http://bmc.example/console',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('opt-in refuses disabled and non-HTML5 consoles in-app', () {
      final KvmConsoleLaunchPlan disabled = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: false,
      );
      final KvmConsoleLaunchPlan nonHtml5 = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: false,
        isEnabled: true,
      );

      expect(disabled.isInApp, isFalse);
      expect(disabled.acceptSelfSigned, isFalse);
      expect(nonHtml5.isInApp, isFalse);
      expect(nonHtml5.acceptSelfSigned, isFalse);
    });

    test('target URI is trimmed for every launchable route', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: '  https://bmc.example/console\t',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example/console');
    });
  });

  group('planConsoleLaunch — defense in depth: URI scheme re-validation', () {
    test('a stale secure flag on a plaintext URI cannot enable in-app TLS weakening', () {
      // The caller-supplied hasSecureUri may be stale or wrong. Defense in
      // depth: the actual URI string must also be HTTPS, otherwise plaintext
      // HTTP could be rendered in-app with a self-signed cert under the opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'http://bmc.example/console',
        hasSecureUri: true, // inconsistent signal
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a non-HTTPS scheme cannot be rendered in-app even with a secure flag', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'file:///etc/passwd',
        hasSecureUri: true, // inconsistent signal
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('uppercase HTTPS scheme is still recognised as secure', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'HTTPS://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'HTTPS://bmc.example/console');
    });

    test('an HTTPS URI with an empty host fails closed', () {
      // `hasSecureLaunchUri` means "HTTPS with a non-empty host". Re-validating
      // only the scheme leaves a gap: a stale secure flag paired with a
      // host-less `https:///` URI would still reach in-app rendering and
      // self-signed acceptance even though there is no BMC to talk to.
      for (final String uri in <String>[
        'https:///console',
        'https://?q=console',
        'https://#console',
        'https://user@/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('a host-bearing HTTPS URI with userinfo or port stays secure', () {
      // Guard: requiring a non-empty host must not reject legitimate targets
      // that carry userinfo or an explicit port.
      for (final String uri in <String>[
        'https://bmc.example:8443/console',
        'https://user@bmc.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.externalBrowser, reason: uri);
        expect(plan.targetUri, uri, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — defense in depth: malformed authority parity', () {
    test('a malformed authority with a stale secure flag fails closed', () {
      // The re-validator mirrors `hasSecureLaunchUri`, which uses Uri.tryParse.
      // A hand-rolled authority check can be fooled into calling a malformed
      // target "secure" (e.g. a non-numeric or duplicated port). With a stale
      // secure flag under the test opt-in that false positive would enable
      // in-app rendering and self-signed acceptance — so it must fail closed.
      for (final String uri in <String>[
        'https://bmc.example:notaport/console',
        'https://bmc.example::443/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — defense in depth: control-character rejection', () {
    test('embedded control characters fail closed even with a stale secure flag', () {
      // `Uri.tryParse` silently percent-encodes C0/DEL control characters into
      // the host/path instead of rejecting them, so a purely syntactic
      // `scheme == 'https' && host.isNotEmpty` re-check calls these "secure".
      // Handing a CRLF/NUL-bearing URI to a launcher risks header/URI injection,
      // and under a stale secure flag + test opt-in it would also grant
      // self-signed acceptance. All control chars must fail closed.
      for (final String uri in <String>[
        'https://bmc.example/con\nsol', // LF
        'https://bmc.example/con\r\nsol', // CRLF
        'https://bmc.example/con\u0000sol', // NUL
        'https://bmc.example/con\tsol', // TAB
        'https://bmc.example/con\u007Fsol', // DEL
        'https://bmc.exa\nmple/console', // control char in host
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('a control-char URI never reaches in-app even with a strict opt-in', () {
      // Even without granting self-signed acceptance, a malformed URI must not
      // be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example/con\u0001sol',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a clean HTTPS URI is still accepted (guard against over-rejection)', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://bmc.example:8443/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example:8443/console');
    });
  });
}
