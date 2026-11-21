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
        KvmWebViewPolicy.productionDefault.mayAcceptSelfSigned(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
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
        KvmWebViewPolicy.testOptIn.mayAcceptSelfSigned(
          hasSecureUri: false,
          isHtml5: true,
          isEnabled: true,
        ),
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
        enabledStrict.mayAcceptSelfSigned(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
        isFalse,
      );
    });

    test('test-only opt-in may accept self-signed on HTTPS only', () {
      expect(
        KvmWebViewPolicy.testOptIn.mayAcceptSelfSigned(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
        isTrue,
      );
    });

    test('opt-in refuses self-signed for a disabled console on HTTPS', () {
      // A future WebView consumer may call mayAcceptSelfSigned directly;
      // self-signed acceptance must never be granted for a console that
      // cannot be rendered in-app (service disabled).
      expect(
        KvmWebViewPolicy.testOptIn.mayAcceptSelfSigned(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: false,
        ),
        isFalse,
      );
    });

    test('opt-in refuses self-signed for a non-HTML5 console on HTTPS', () {
      // Same invariant for a console that the in-app renderer cannot display.
      expect(
        KvmWebViewPolicy.testOptIn.mayAcceptSelfSigned(
          hasSecureUri: true,
          isHtml5: false,
          isEnabled: true,
        ),
        isFalse,
      );
    });
  });

  group('KvmWebViewPolicy — hostname verification is never bypassed', () {
    test('production default always verifies the certificate hostname', () {
      expect(KvmWebViewPolicy.productionDefault.bypassHostnameVerification, isFalse);
    });

    test('test-only self-signed opt-in still verifies the hostname', () {
      // Accepting a self-signed leaf must never disable certificate-identity /
      // hostname verification: otherwise any host could impersonate the BMC and
      // the test-only opt-in becomes a MITM vector. This is a hard invariant,
      // independent of the flag, TLS mode, or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassHostnameVerification, isFalse);
    });

    test('no policy configuration can disable hostname verification', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
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
}
