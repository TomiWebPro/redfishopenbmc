import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

void main() {
  group('KvmWebViewPolicy — production safety (flag OFF by default)', () {
    test('production default keeps the WebView flag off and TLS strict', () {
      expect(KvmWebViewPolicy.productionDefault.enabled, isFalse);
      expect(
        KvmWebViewPolicy.productionDefault.tlsMode,
        KvmWebViewTlsMode.strict,
      );
    });

    test('flag off never renders in-app, even for valid HTTPS HTML5', () {
      const KvmWebViewPolicy policy = KvmWebViewPolicy();
      expect(
        policy.permitsInAppRendering(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
        isFalse,
      );
    });

    test('production never accepts a self-signed certificate', () {
      expect(
        KvmWebViewPolicy.productionDefault
            .mayAcceptSelfSigned(hasSecureUri: true),
        isFalse,
      );
    });
  });

  group('KvmWebViewPolicy — opt-in renders only safe consoles', () {
    test('test opt-in renders an enabled HTTPS HTML5 console', () {
      expect(
        KvmWebViewPolicy.testOptIn.permitsInAppRendering(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
        isTrue,
      );
    });

    test('opt-in still refuses plaintext HTTP (never downgrade TLS)', () {
      expect(
        KvmWebViewPolicy.testOptIn.permitsInAppRendering(
          hasSecureUri: false,
          isHtml5: true,
          isEnabled: true,
        ),
        isFalse,
      );
      expect(
        KvmWebViewPolicy.testOptIn.mayAcceptSelfSigned(hasSecureUri: false),
        isFalse,
      );
    });

    test('disabled or non-HTML5 consoles are never rendered in-app', () {
      expect(
        KvmWebViewPolicy.testOptIn.permitsInAppRendering(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: false,
        ),
        isFalse,
      );
      expect(
        KvmWebViewPolicy.testOptIn.permitsInAppRendering(
          hasSecureUri: true,
          isHtml5: false,
          isEnabled: true,
        ),
        isFalse,
      );
    });

    test('strict mode never accepts self-signed even with flag on', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      expect(enabledStrict.enabled, isTrue);
      expect(
        enabledStrict.mayAcceptSelfSigned(hasSecureUri: true),
        isFalse,
      );
    });

    test('test-only opt-in may accept self-signed on HTTPS only', () {
      expect(
        KvmWebViewPolicy.testOptIn.mayAcceptSelfSigned(hasSecureUri: true),
        isTrue,
      );
    });
  });

  group('resolveRenderRoute — fallback works with the flag off', () {
    test('flag off routes valid HTTPS HTML5 to the external browser', () {
      expect(
        resolveRenderRoute(
          policy: KvmWebViewPolicy.productionDefault,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
        KvmConsoleRenderRoute.externalBrowser,
      );
    });

    test('plaintext consoles fall back to the copy path', () {
      expect(
        resolveRenderRoute(
          policy: KvmWebViewPolicy.productionDefault,
          hasSecureUri: false,
          isHtml5: true,
          isEnabled: true,
        ),
        KvmConsoleRenderRoute.copyOnly,
      );
    });

    test('opt-in with a valid console selects the in-app WebView', () {
      expect(
        resolveRenderRoute(
          policy: KvmWebViewPolicy.testOptIn,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
        KvmConsoleRenderRoute.inAppWebView,
      );
    });
  });

  group('resolveRenderRoute — fail closed for an unopenable console', () {
    test('a disabled HTTPS console is never routed to a launchable target', () {
      // A BMC may publish a ConnectUri while reporting ServiceEnabled: false.
      // The app's card and viewer already refuse to launch such a console
      // (KvmConsole.canOpenConsole == false); the launch decision layer must
      // agree and fail closed to copyOnly instead of offering the URI to an
      // external browser just because it happens to be HTTPS.
      for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
        KvmWebViewPolicy.productionDefault,
        KvmWebViewPolicy.testOptIn,
      ]) {
        expect(
          resolveRenderRoute(
            policy: policy,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: false,
          ),
          KvmConsoleRenderRoute.copyOnly,
          reason: 'flag=${policy.enabled}',
        );
      }
    });
  });
}
