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
      expect(KvmWebViewPolicy.productionDefault.bypassHostnameVerification,
          isFalse);
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

  group('KvmWebViewPolicy — certificate/public-key pinning is never bypassed',
      () {
    test('production default always enforces the certificate pin', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassCertificatePinning, isFalse);
    });

    test('test-only self-signed opt-in still enforces the pin', () {
      // Tolerating the test BMC's untrusted leaf for the expected host must not
      // degrade to a trust-all / accept-any-certificate verifier: that would let
      // any host impersonate the BMC and take over the privileged session. This
      // is a hard invariant, independent of the flag, TLS mode or console
      // signals.
      expect(KvmWebViewPolicy.testOptIn.bypassCertificatePinning, isFalse);
    });

    test('no policy configuration can disable certificate pinning', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Identity verification and pinning are independent invariants: neither
      // can be disabled by the opt-in.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
    });
  });

  group('KvmWebViewPolicy — TLS protocol/cipher floor is never bypassed', () {
    test('production default always enforces the TLS floor', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassTlsProtocolFloor, isFalse);
    });

    test('test-only self-signed opt-in still enforces the TLS floor', () {
      // Tolerating the test BMC's untrusted leaf must not relax the TLS
      // protocol-version / cipher-suite floor (no downgrade to TLS 1.0/1.1,
      // no weak/export/NULL suites, no silent fallback): that would expose the
      // privileged console session to a downgrade/decryption attack. This is a
      // hard invariant, independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassTlsProtocolFloor, isFalse);
    });

    test('no policy configuration can bypass the TLS floor', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Identity, pinning and handshake-floor invariants are independent: the
      // test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
    });
  });

  group('KvmWebViewPolicy — HTTPS-only transport is never bypassed', () {
    test('production default never permits cleartext transport', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassHttpsOnlyTransport, isFalse);
    });

    test('test-only self-signed opt-in still forbids cleartext transport', () {
      // Tolerating the test BMC's untrusted leaf relaxes ONLY leaf trust: it
      // must never add a cleartext exception (no cleartextTrafficPermitted /
      // usesCleartextTraffic=true, no NSAllowsArbitraryLoads), not even for the
      // test profile. This is a hard invariant, independent of the flag, TLS
      // mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassHttpsOnlyTransport, isFalse);
    });

    test('no policy configuration can bypass HTTPS-only transport', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Identity, pinning, handshake-floor and HTTPS-only invariants are
      // independent: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
    });
  });

  group('KvmWebViewPolicy — certificate revocation checking is never bypassed',
      () {
    test('production default always checks certificate revocation', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassCertificateRevocationCheck,
          isFalse);
    });

    test('test-only self-signed opt-in still checks revocation', () {
      // Tolerating the test BMC's untrusted leaf relaxes ONLY leaf trust: it
      // must never disable CRL/OCSP revocation checking for otherwise-trusted
      // certificates, so a revoked BMC certificate cannot silently resume the
      // privileged console session. This is a hard invariant, independent of
      // the flag, TLS mode or console signals.
      expect(
          KvmWebViewPolicy.testOptIn.bypassCertificateRevocationCheck, isFalse);
    });

    test('no policy configuration can skip certificate revocation checking',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Identity, pinning, handshake-floor, HTTPS-only and revocation
      // invariants are independent: the test-only opt-in can disable none of
      // them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
    });
  });

  group('KvmWebViewPolicy — validated-origin binding is never bypassed', () {
    test('production default always binds to the validated origin', () {
      expect(KvmWebViewPolicy.productionDefault.bypassValidatedOriginBinding,
          isFalse);
    });

    test('test-only self-signed opt-in still binds to the validated origin',
        () {
      // Tolerating the test BMC's untrusted leaf relaxes ONLY leaf trust: it
      // must never let the console connect to a re-resolved address (DNS
      // rebinding / time-of-check-time-of-use) different from the one that
      // passed the fail-closed origin check, or the trusted frame becomes an
      // SSRF-style pivot into loopback / link-local / internal services. This
      // is a hard invariant, independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassValidatedOriginBinding, isFalse);
    });

    test('no policy configuration can bypass validated-origin binding', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Identity, pinning, handshake-floor, HTTPS-only, revocation and
      // origin-binding invariants are independent: the opt-in can disable none.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
    });
  });

  group('KvmWebViewPolicy — platform trust-store integrity is never bypassed',
      () {
    test('production default never mutates the platform trust store', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassPlatformTrustStoreIntegrity,
          isFalse);
    });

    test('test-only self-signed opt-in still never mutates the trust store',
        () {
      // Accepting the test BMC's untrusted leaf must NOT be implemented by
      // installing its CA / trust anchor into the platform trust store (Android
      // NetworkSecurityConfig <certificates src="user"/> or KeyStore mutation,
      // iOS/macOS custom CA / SecTrust anchor). That would trust that CA for
      // every app and every host — a global weakening of production TLS. The
      // opt-in tolerates the leaf only in a scoped per-connection verifier.
      // This is a hard invariant, independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassPlatformTrustStoreIntegrity,
          isFalse);
    });

    test('no policy configuration can weaken the platform trust store', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Identity, pinning, handshake-floor, HTTPS-only, revocation,
      // origin-binding and trust-store-integrity invariants are independent:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — client-certificate (mTLS) validation is never '
      'bypassed', () {
    test('production default always validates the client certificate', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassClientCertificateValidation,
          isFalse);
    });

    test('test-only self-signed opt-in still validates the client certificate',
        () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server
      // leaf trust. It must never disable client-certificate (mutual TLS)
      // validation or expose the client private key: doing so would let the
      // privileged console session be opened with a missing/invalid client
      // credential. This is a hard invariant, independent of the flag, TLS
      // mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassClientCertificateValidation,
          isFalse);
    });

    test('no policy configuration can bypass client-certificate validation',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // The server-side identity/key/status/anchor, handshake, cleartext and
      // resolved-address invariants are independent of the client credential:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
    });
  });

  group('KvmWebViewPolicy — strict Referrer-Policy is never bypassed', () {
    test('production default always enforces the strict referrer policy', () {
      expect(KvmWebViewPolicy.productionDefault.bypassStrictReferrerPolicy,
          isFalse);
    });

    test(
        'test-only self-signed opt-in still enforces the strict referrer policy',
        () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never relax the strict referrer policy or the console's
      // privileged URL / session token could leak in a cross-origin Referer
      // header. This is a hard invariant, independent of the flag, TLS mode or
      // console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassStrictReferrerPolicy, isFalse);
    });

    test('no policy configuration can bypass the strict referrer policy', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every server/transport/client-credential invariant is independent of
      // the outbound Referer-header control: the opt-in can disable none.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
    });
  });

  group('KvmWebViewPolicy — CSP / mixed-content blocking is never bypassed',
      () {
    test('production default always enforces CSP and mixed-content blocking',
        () {
      expect(KvmWebViewPolicy.productionDefault.bypassMixedContentBlocking,
          isFalse);
    });

    test(
        'test-only self-signed opt-in still enforces CSP and mixed-content '
        'blocking', () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never relax CSP or permit an HTTPS console to load
      // cleartext HTTP subresources, or an on-path attacker could downgrade a
      // subresource and inject into / read from the privileged console frame.
      // This is a hard invariant, independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassMixedContentBlocking, isFalse);
    });

    test('no policy configuration can bypass CSP / mixed-content blocking', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every server/transport/client-credential/referrer invariant is
      // independent of the page-level CSP / mixed-content control: the opt-in
      // can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — sensitive console URL log redaction is never '
      'bypassed', () {
    test('production default always redacts the console URL from logs', () {
      expect(KvmWebViewPolicy.productionDefault.bypassLogRedaction, isFalse);
    });

    test('test-only self-signed opt-in still redacts the console URL from logs',
        () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never emit the privileged console URL — or any session
      // token derived from it — to logs, telemetry or crash reports (CWE-532),
      // or a durable, exfiltratable copy of the management-session handle is
      // left on the device / in a third-party sink. This is a hard invariant,
      // independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassLogRedaction, isFalse);
    });

    test('no policy configuration can bypass console URL log redaction', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every server/transport/client-credential/referrer/page-content invariant
      // is independent of the app's own log/telemetry redaction: the opt-in can
      // disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — sensitive data-at-rest protection is never '
      'bypassed', () {
    test('production default never bypasses data-at-rest protection', () {
      expect(
          KvmWebViewPolicy
              .productionDefault.bypassSensitiveDataAtRestProtection,
          isFalse);
    });

    test('test-only self-signed opt-in still protects data at rest', () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never persist the privileged console's cache/storage to
      // disk or expose an unprotected background snapshot, or a durable local
      // copy of the management session is left for theft / shoulder-surfing.
      // This is a hard invariant, independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassSensitiveDataAtRestProtection,
          isFalse);
    });

    test('no policy configuration can bypass data-at-rest protection', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every server/transport/client-credential/referrer/page-content/diagnostic
      // invariant is independent of the local persistence / screen-capture
      // control: the opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
    });
  });

  group('KvmWebViewPolicy — native bridge isolation is never bypassed', () {
    test('production default never bypasses native bridge isolation', () {
      expect(KvmWebViewPolicy.productionDefault.bypassNativeBridgeIsolation,
          isFalse);
    });

    test('test-only self-signed opt-in still isolates the native bridge', () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never inject a native JavaScript bridge / message handler
      // or expose an app-controlled window.* object to attacker-influenced
      // console content, or that content gains a remote-code-execution path into
      // the host app. This is a hard invariant, independent of the flag, TLS
      // mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassNativeBridgeIsolation, isFalse);
    });

    test('no policy configuration can bypass native bridge isolation', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every server/transport/client-credential/referrer/page-content/diagnostic
      // invariant is independent of the native-bridge isolation control: the
      // opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — private-network egress protection is never '
      'bypassed', () {
    test('production default never bypasses private-network egress protection',
        () {
      expect(
          KvmWebViewPolicy
              .productionDefault.bypassPrivateNetworkEgressProtection,
          isFalse);
    });

    test('test-only self-signed opt-in still confines subresource egress', () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never let attacker-influenced console subresources reach
      // loopback, link-local (cloud metadata) or private LAN addresses — that
      // would turn the trusted frame into an SSRF / metadata-theft pivot. This is
      // a hard invariant, independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassPrivateNetworkEgressProtection,
          isFalse);
    });

    test('no policy configuration can bypass private-network egress protection',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other server/transport/client-credential/referrer/page-content/
      // diagnostic/persistence/bridge invariant is independent of subresource
      // egress confinement: the opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
    });
  });

  group('KvmWebViewPolicy — cross-site cookie isolation is never bypassed', () {
    test('production default never bypasses cross-site cookie isolation', () {
      expect(KvmWebViewPolicy.productionDefault.bypassCookieIsolation, isFalse);
    });

    test('test-only self-signed opt-in still isolates console cookies', () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never relax Secure/HttpOnly/SameSite scoping, permit
      // third-party cookies, allow script reads of the session cookie via
      // document.cookie, or share the console cookie jar with the system browser
      // — any of which hands the operator's privileged session to an attacker.
      // This is a hard invariant, independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassCookieIsolation, isFalse);
    });

    test('no policy configuration can bypass cross-site cookie isolation', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other server/transport/client-credential/referrer/page-content/
      // diagnostic/persistence/bridge/egress invariant is independent of cookie
      // isolation: the opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
    });
  });

  group('KvmWebViewPolicy — WebView remote debugging is never enabled', () {
    test('production default never enables WebView remote debugging', () {
      expect(KvmWebViewPolicy.productionDefault.bypassWebViewRemoteDebugging,
          isFalse);
    });

    test('test-only self-signed opt-in stays non-inspectable', () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never enable web-contents debugging / inspectability or
      // expose a DevTools / remote-debugging endpoint in production — a CWE-489
      // active-debug-code path to the operator's DOM, session tokens and KVM
      // frames. This is a hard invariant, independent of the flag, TLS mode or
      // signals.
      expect(KvmWebViewPolicy.testOptIn.bypassWebViewRemoteDebugging, isFalse);
    });

    test('no policy configuration can enable WebView remote debugging', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other server/transport/client-credential/referrer/page-content/
      // diagnostic/persistence/bridge/egress/cookie invariant is independent of
      // remote debugging: the opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
    });
  });

  group('KvmWebViewPolicy — device capabilities are never granted', () {
    test('production default never grants device capabilities', () {
      expect(KvmWebViewPolicy.productionDefault.bypassDevicePermissionControls,
          isFalse);
    });

    test('test-only self-signed opt-in grants no device capability', () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never grant geolocation / camera / microphone / clipboard
      // / notification / Bluetooth / NFC / download capability, nor auto-answer
      // a native/WebKit permission prompt, for attacker-influenced console
      // content — a privacy / RCE-class escalation from page content into the
      // host device. This is a hard invariant, independent of the flag, TLS mode
      // or signals.
      expect(
          KvmWebViewPolicy.testOptIn.bypassDevicePermissionControls, isFalse);
    });

    test('no policy configuration can grant device capabilities', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other server/transport/client-credential/referrer/page-content/
      // diagnostic/persistence/bridge/egress/cookie/debug invariant is
      // independent of device permissions: the opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
    });
  });

  group('KvmWebViewPolicy — HTTP-auth challenges are never auto-answered', () {
    test('production default denies every HTTP-auth / login challenge', () {
      expect(KvmWebViewPolicy.productionDefault.bypassHttpAuthChallengeDenial,
          isFalse);
    });

    test('test-only self-signed opt-in never auto-answers a credential prompt',
        () {
      // Tolerating the test BMC's untrusted SERVER leaf relaxes ONLY server leaf
      // trust. It must never present a spoofed native authentication prompt or
      // auto-answer an HTTP-auth / login challenge with stored credentials for
      // attacker-influenced console content — a credential-phishing / leak
      // surface. This is a hard invariant, independent of the flag, TLS mode or
      // signals.
      expect(KvmWebViewPolicy.testOptIn.bypassHttpAuthChallengeDenial, isFalse);
    });

    test('no policy configuration can enable HTTP-auth prompt spoofing', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other server/transport/client-credential/referrer/page-content/
      // diagnostic/persistence/bridge/egress/cookie/debug/device invariant is
      // independent of the native authentication-challenge path: the opt-in can
      // disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — local file / content-provider access is never '
      'bypassed', () {
    test('production default never enables local file/content access', () {
      expect(KvmWebViewPolicy.productionDefault.bypassLocalFileAccess, isFalse);
    });

    test('test-only self-signed opt-in still denies local file/content access',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust:
      // it must never flip setAllowFileAccess/ContentAccess or load a file:// /
      // content:// URL just to make a console render or to debug it. This is a
      // hard invariant, independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassLocalFileAccess, isFalse);
    });

    test('no policy configuration can enable local file/content access', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of local-file access: the
      // test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
    });
  });

  group('KvmWebViewPolicy — outbound egress allowlist is never bypassed', () {
    test('production default never relaxes the outbound egress allowlist', () {
      expect(KvmWebViewPolicy.productionDefault.bypassOutboundEgressAllowlist,
          isFalse);
    });

    test(
        'test-only self-signed opt-in still confines connections to the '
        'approved origin', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust:
      // it must never let attacker-influenced console content open a
      // programmatic connection (fetch/XHR/WebSocket/WebRTC/sendBeacon) to any
      // origin other than the approved console origin. Hard invariant,
      // independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassOutboundEgressAllowlist, isFalse);
    });

    test('no policy configuration can relax the outbound egress allowlist', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of outbound egress: the
      // test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
    });
  });

  group('KvmWebViewPolicy — cross-origin form submission is never bypassed',
      () {
    test('production default never permits cross-origin form submission', () {
      expect(KvmWebViewPolicy.productionDefault.bypassCrossOriginFormSubmission,
          isFalse);
    });

    test(
        'test-only self-signed opt-in still confines forms to the console '
        'origin', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust:
      // it must never let attacker-influenced console content exfiltrate
      // credentials, session tokens or KVM frames through a cross-origin HTML
      // form (a GET query or POST body, auto-submit-on-load or scripted
      // form.submit()). Hard invariant, independent of the flag, TLS mode or
      // console signals.
      expect(
          KvmWebViewPolicy.testOptIn.bypassCrossOriginFormSubmission, isFalse);
    });

    test('no policy configuration can permit cross-origin form submission', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of form submission: the
      // test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
    });
  });

  group('KvmWebViewPolicy — SSL certificate-error rejection is never bypassed',
      () {
    test('production default never blanket-accepts a certificate error', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassSslErrorRejection, isFalse);
    });

    test(
        'test-only self-signed opt-in still fails closed on certificate '
        'errors', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never install a
      // blanket `proceed()` / `badCertificateCallback => true` that would make
      // the privileged console accept any rejected certificate. Hard invariant,
      // independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassSslErrorRejection, isFalse);
    });

    test('no policy configuration can bypass certificate-error rejection', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the error-handler
      // surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — top-level navigation confinement is never '
      'bypassed', () {
    test(
        'production default never lets the top-level frame navigate off the '
        'approved console', () {
      expect(
          KvmWebViewPolicy
              .productionDefault.bypassTopLevelNavigationConfinement,
          isFalse);
    });

    test('test-only self-signed opt-in still confines top-level navigation',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let the
      // privileged console frame navigate to a different origin, a plaintext
      // page, a non-http(s) scheme or a spoofed/phishing page. Hard invariant,
      // independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassTopLevelNavigationConfinement,
          isFalse);
    });

    test('no policy configuration can bypass top-level navigation confinement',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of navigation confinement:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
    });
  });

  group('KvmWebViewPolicy — arbitrary / drive-by download is never allowed',
      () {
    test('production default never permits an arbitrary file download', () {
      expect(KvmWebViewPolicy.productionDefault.bypassArbitraryFileDownload,
          isFalse);
    });

    test('test-only self-signed opt-in still blocks drive-by downloads', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let a
      // console-controlled <a download>, redirect, scripted load or
      // Content-Disposition: attachment drop a runnable file onto the device.
      // Hard invariant, independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassArbitraryFileDownload, isFalse);
    });

    test('no policy configuration can permit an arbitrary file download', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the download channel:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — autofill / password-manager capture is never allowed',
      () {
    test('production default never permits credential autofill capture', () {
      expect(KvmWebViewPolicy.productionDefault.bypassAutofillCredentialCapture,
          isFalse);
    });

    test('test-only self-signed opt-in still denies autofill capture', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never enable
      // password-manager saving, pre-seeding of saved credentials or an autofill
      // suggestion just to make a console render or to debug it. Hard invariant,
      // independent of the flag, TLS mode or console signals.
      expect(
          KvmWebViewPolicy.testOptIn.bypassAutofillCredentialCapture, isFalse);
    });

    test('no policy configuration can enable autofill credential capture', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the autofill channel:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
    });
  });

  group('KvmWebViewPolicy — file chooser / file-upload access is never allowed',
      () {
    test('production default never opens a file chooser', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassFileChooserAccess, isFalse);
    });

    test('test-only self-signed opt-in still denies the file chooser', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never open an
      // <input type="file"> / native file picker that lets attacker-influenced
      // console content make the operator select a local file to upload.
      // Hard invariant, independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassFileChooserAccess, isFalse);
    });

    test('no policy configuration can enable the file chooser', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the file-picker
      // channel: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — tapjacking / UI-overlay input hijack is never allowed',
      () {
    test('production default never permits obscured-window touch / overlays',
        () {
      expect(KvmWebViewPolicy.productionDefault.bypassTapjackingProtection,
          isFalse);
    });

    test('test-only self-signed opt-in still rejects obscured-window touches',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never disable
      // touch filtering (Android filterTouchesWhenObscured /
      // FLAG_WINDOW_IS_OBSCURED rejection) or allow a UI overlay that lets a
      // malicious app hijack operator input into the privileged console.
      // Hard invariant, independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassTapjackingProtection, isFalse);
    });

    test('no policy configuration can permit tapjacking / overlay input hijack',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the obscured-window
      // input channel: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
    });
  });

  group('KvmWebViewPolicy — JavaScript dialog / modal spoofing never allowed',
      () {
    test('production default never permits unlabelled JavaScript dialogs', () {
      expect(KvmWebViewPolicy.productionDefault.bypassJavaScriptDialogDenial,
          isFalse);
    });

    test('test-only self-signed opt-in still denies JavaScript dialogs', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never present an
      // unlabelled alert/confirm/prompt dialog or a blocking beforeunload just
      // to make a console render or to debug it. Hard invariant, independent
      // of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassJavaScriptDialogDenial, isFalse);
    });

    test('no policy configuration can permit JavaScript dialog spoofing', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the untrusted-modal
      // surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — service worker / persistent background script never '
      'allowed', () {
    test('production default never permits service worker registration', () {
      expect(KvmWebViewPolicy.productionDefault.bypassServiceWorkerRegistration,
          isFalse);
    });

    test(
        'test-only self-signed opt-in still denies persistent background '
        'scripts', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let
      // attacker-influenced console content register a Service Worker or a
      // persistent background script that outlives the page/session just to
      // make a console render or to debug it. Hard invariant, independent of
      // the flag, TLS mode or console signals.
      expect(
          KvmWebViewPolicy.testOptIn.bypassServiceWorkerRegistration, isFalse);
    });

    test('no policy configuration can permit a persistent background script',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of background-script
      // execution: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
    });
  });

  group('KvmWebViewPolicy — print / save-to-PDF exfiltration never allowed',
      () {
    test('production default never permits print exfiltration', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassPrintExfiltration, isFalse);
    });

    test('test-only self-signed opt-in still denies printing', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never expose a
      // print adapter or honour a scripted window.print() so the privileged
      // console DOM cannot be rendered to a durable print/PDF copy just to
      // make a console render or to debug it. Hard invariant, independent of
      // the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassPrintExfiltration, isFalse);
    });

    test('no policy configuration can enable printing', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of print exfiltration:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — pointer/keyboard/fullscreen input capture never allowed',
      () {
    test('production default never permits input capture', () {
      expect(KvmWebViewPolicy.productionDefault.bypassInputCaptureProtection,
          isFalse);
    });

    test('test-only self-signed opt-in still denies input capture', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let
      // attacker-influenced console content seize pointer/keyboard focus or
      // hide the app chrome to trap input or spoof a credential prompt just to
      // make a console render or to debug it. Hard invariant, independent of
      // the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassInputCaptureProtection, isFalse);
    });

    test('no policy configuration can enable input capture', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of input capture: the
      // test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
    });
  });

  group('KvmWebViewPolicy — picture-in-picture escape is never allowed', () {
    test('production default never permits picture-in-picture escape', () {
      expect(KvmWebViewPolicy.productionDefault.bypassPictureInPictureEscape,
          isFalse);
    });

    test('test-only self-signed opt-in still denies picture-in-picture', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let
      // attacker-influenced console content open a browser-native PiP window
      // that renders outside the secure console frame, floats above other apps
      // or outlives the console session just to make a console render or to
      // debug it. Hard invariant, independent of the flag, TLS mode or signals.
      expect(KvmWebViewPolicy.testOptIn.bypassPictureInPictureEscape, isFalse);
    });

    test('no policy configuration can permit picture-in-picture escape', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the PiP / secondary-
      // window surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — Web Share / remote-cast exfiltration is never '
      'allowed', () {
    test(
        'production default never permits Web Share / remote-cast exfiltration',
        () {
      expect(KvmWebViewPolicy.productionDefault.bypassShareCastExfiltration,
          isFalse);
    });

    test('test-only self-signed opt-in still denies Web Share / remote-cast',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let
      // attacker-influenced console content push KVM frames, session tokens or
      // credentials out through a native share sheet, a Presentation / Remote
      // Playback session or a cast/AirPlay receiver just to make a console
      // render or to debug it. Hard invariant, independent of flag/TLS/signals.
      expect(KvmWebViewPolicy.testOptIn.bypassShareCastExfiltration, isFalse);
    });

    test(
        'no policy configuration can permit Web Share / remote-cast exfiltration',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the share/cast surface:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
    });
  });

  group('KvmWebViewPolicy — clipboard read/write isolation is never bypassed',
      () {
    test('production default never permits clipboard read/write', () {
      expect(
          KvmWebViewPolicy.productionDefault.bypassClipboardIsolation, isFalse);
    });

    test('test-only self-signed opt-in still denies clipboard access', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let
      // attacker-influenced console content copy session tokens / credentials /
      // KVM frames to a cross-app clipboard or read operator credentials from
      // it just to make a console render or to debug it. Hard invariant,
      // independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassClipboardIsolation, isFalse);
    });

    test('no policy configuration can permit clipboard read/write', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the cross-app clipboard
      // data channel: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
    });
  });

  group('KvmWebViewPolicy — cross-origin web-messaging is never bypassed', () {
    test('production default never permits cross-origin web messaging', () {
      expect(
        KvmWebViewPolicy.productionDefault.bypassCrossOriginMessagingIsolation,
        isFalse,
      );
    });

    test('test-only self-signed opt-in still denies cross-origin messaging',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY leaf trust
      // for the expected host (via a scoped verifier): it must never let
      // attacker-influenced console content postMessage / BroadcastChannel
      // privileged session data to a foreign-origin context just to make a
      // console render or to debug it. Hard invariant, independent of the
      // flag, TLS mode or console signals.
      expect(
        KvmWebViewPolicy.testOptIn.bypassCrossOriginMessagingIsolation,
        isFalse,
      );
    });

    test('no policy configuration can permit cross-origin messaging', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the cross-origin
      // messaging data channel: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
    });
  });

  group('KvmWebViewPolicy — screen / window capture is never permitted', () {
    test('production default never permits scripted screen capture', () {
      expect(KvmWebViewPolicy.productionDefault.bypassScreenCaptureProtection,
          isFalse);
    });

    test('test-only self-signed opt-in still forbids scripted screen capture',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content script a
      // display capture (getDisplayMedia / captureStream / MediaRecorder) or a
      // canvas snapshot (toDataURL / toBlob) of the privileged rendered console,
      // or the operator's KVM frames / session tokens / credentials can be
      // scraped off the screen. Hard invariant, independent of the flag, TLS
      // mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassScreenCaptureProtection, isFalse);
    });

    test('no policy configuration can permit scripted screen capture', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of screen-capture
      // protection: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
    });
  });

  group('KvmWebViewPolicy — hyperlink auditing never permitted', () {
    test('production default never permits hyperlink auditing exfiltration',
        () {
      expect(
          KvmWebViewPolicy
              .productionDefault.bypassHyperlinkAuditingExfiltration,
          isFalse);
    });

    test('test-only self-signed opt-in still forbids hyperlink auditing', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content smuggle
      // privileged session data to a non-approved origin via the HTML ping
      // attribute (a browser-generated background POST on link activation,
      // governed by the CSP ping directive, not connect-src). Hard invariant,
      // independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassHyperlinkAuditingExfiltration,
          isFalse);
    });

    test('no policy configuration can permit hyperlink auditing', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of hyperlink-auditing
      // protection: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
    });
  });

  group('KvmWebViewPolicy — credential-management API is never exposed', () {
    test('production default never exposes credential-management APIs', () {
      expect(
          KvmWebViewPolicy
              .productionDefault.bypassCredentialManagementApiAccess,
          isFalse);
    });

    test('test-only self-signed opt-in still denies credential-management APIs',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content read saved
      // passwords via navigator.credentials or coerce a WebAuthn assertion /
      // biometric prompt — a credential-theft surface distinct from form
      // autofill and the native HTTP-auth challenge. Hard invariant,
      // independent of the flag, TLS mode or console signals.
      expect(KvmWebViewPolicy.testOptIn.bypassCredentialManagementApiAccess,
          isFalse);
    });

    test('no policy configuration can expose credential-management APIs', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassCredentialManagementApiAccess, isFalse);
      expect(enabledSelfSigned.bypassCredentialManagementApiAccess, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the credential-
      // management API surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
    });
  });

  group('KvmWebViewPolicy — speculative prefetch/prerender never enabled', () {
    test('production default never permits speculative prefetch/prerender', () {
      expect(KvmWebViewPolicy.productionDefault.bypassSpeculationRulesEgress,
          isFalse);
    });

    test('test-only self-signed opt-in still denies speculative prefetch', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content trigger a
      // speculative prefetch / prerender (Speculation Rules API) that leaks the
      // privileged console handle / session token to a non-approved origin via
      // a browser-generated request (governed by CSP prefetch-src, not
      // connect-src). Hard invariant, independent of flag / TLS mode / signals.
      expect(KvmWebViewPolicy.testOptIn.bypassSpeculationRulesEgress, isFalse);
    });

    test('no policy configuration can permit speculative prefetch/prerender',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassSpeculationRulesEgress, isFalse);
      expect(enabledSelfSigned.bypassSpeculationRulesEgress, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the speculation-rules
      // surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.bypassCredentialManagementApiAccess, isFalse);
    });
  });

  group('KvmWebViewPolicy — notification API access never granted', () {
    test('production default never permits notification API access', () {
      expect(KvmWebViewPolicy.productionDefault.bypassNotificationApiAccess,
          isFalse);
    });

    test('test-only self-signed opt-in still denies notification API access',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content render
      // privileged session data (KVM frames, tokens, credentials, host inventory)
      // into an OS notification shown in the shade / lock screen outside the
      // secure console frame, nor coerce a notification-permission prompt. Hard
      // invariant, independent of flag / TLS mode / signals.
      expect(KvmWebViewPolicy.testOptIn.bypassNotificationApiAccess, isFalse);
    });

    test('no policy configuration can permit notification API access', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassNotificationApiAccess, isFalse);
      expect(enabledSelfSigned.bypassNotificationApiAccess, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the notification
      // surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.bypassCredentialManagementApiAccess, isFalse);
      expect(enabledSelfSigned.bypassSpeculationRulesEgress, isFalse);
    });
  });

  group('KvmWebViewPolicy — WebRTC peer-to-peer/data-channel never granted',
      () {
    test('production default never permits WebRTC peer connections', () {
      expect(
          KvmWebViewPolicy
              .productionDefault.bypassWebRtcDataChannelExfiltration,
          isFalse);
    });

    test('test-only self-signed opt-in still denies WebRTC data channels', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content open an
      // RTCPeerConnection / RTCDataChannel, gather ICE candidates or contact a
      // STUN/TURN server to exfiltrate privileged session data or leak the
      // device's IPs — surfaces distinct from the HTTP connect-src egress
      // allowlist and from getUserMedia camera/mic capture. Hard invariant,
      // independent of flag / TLS mode / signals.
      expect(KvmWebViewPolicy.testOptIn.bypassWebRtcDataChannelExfiltration,
          isFalse);
    });

    test('no policy configuration can permit WebRTC data-channel exfiltration',
        () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassWebRtcDataChannelExfiltration, isFalse);
      expect(enabledSelfSigned.bypassWebRtcDataChannelExfiltration, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the WebRTC surface:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.bypassCredentialManagementApiAccess, isFalse);
      expect(enabledSelfSigned.bypassSpeculationRulesEgress, isFalse);
      expect(enabledSelfSigned.bypassNotificationApiAccess, isFalse);
    });
  });

  group('KvmWebViewPolicy — File System Access API is never exposed', () {
    test('production default never exposes the File System Access API', () {
      expect(KvmWebViewPolicy.productionDefault.bypassFileSystemAccessApi,
          isFalse);
    });

    test('test-only self-signed opt-in still denies file-system handles', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content obtain a
      // File System Access API handle (showOpenFilePicker / showSaveFilePicker /
      // showDirectoryPicker / createWritable / OPFS) to read local files into
      // the console frame or write privileged session data to a durable file —
      // a local-file read/write surface distinct from the <input type=file>
      // chooser, direct file:// reads, the WebView's own cache/storage and a
      // network-response download. Hard invariant, independent of flag / TLS
      // mode / signals.
      expect(KvmWebViewPolicy.testOptIn.bypassFileSystemAccessApi, isFalse);
    });

    test('no policy configuration can expose the File System Access API', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassFileSystemAccessApi, isFalse);
      expect(enabledSelfSigned.bypassFileSystemAccessApi, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the file-system surface:
      // the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.bypassCredentialManagementApiAccess, isFalse);
      expect(enabledSelfSigned.bypassSpeculationRulesEgress, isFalse);
      expect(enabledSelfSigned.bypassNotificationApiAccess, isFalse);
      expect(enabledSelfSigned.bypassWebRtcDataChannelExfiltration, isFalse);
    });
  });

  group('KvmWebViewPolicy — WebTransport / QUIC is never available', () {
    test('production default never exposes WebTransport / QUIC', () {
      expect(KvmWebViewPolicy.productionDefault.bypassWebTransportExfiltration,
          isFalse);
    });

    test('test-only self-signed opt-in still denies WebTransport sessions', () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content open a
      // WebTransport session (`new WebTransport(url)`) or use its QUIC
      // datagrams / streams to smuggle privileged KVM frames / session tokens /
      // credentials / host inventory to a non-approved origin or leak the
      // device IPs — a distinct client/server QUIC transport surface, not the
      // peer-to-peer WebRTC channel, the programmatic HTTP egress allowlist or
      // a device capability. Hard invariant, independent of flag / TLS mode.
      expect(
          KvmWebViewPolicy.testOptIn.bypassWebTransportExfiltration, isFalse);
    });

    test('no policy configuration can expose WebTransport / QUIC', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassWebTransportExfiltration, isFalse);
      expect(enabledSelfSigned.bypassWebTransportExfiltration, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the WebTransport
      // surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.bypassCredentialManagementApiAccess, isFalse);
      expect(enabledSelfSigned.bypassSpeculationRulesEgress, isFalse);
      expect(enabledSelfSigned.bypassNotificationApiAccess, isFalse);
      expect(enabledSelfSigned.bypassWebRtcDataChannelExfiltration, isFalse);
      expect(enabledSelfSigned.bypassFileSystemAccessApi, isFalse);
    });
  });

  group(
      'KvmWebViewPolicy — WebUSB/WebSerial/WebHID peripheral I/O is never '
      'available', () {
    test('production default never exposes peripheral I/O', () {
      expect(KvmWebViewPolicy.productionDefault.bypassPeripheralIoExfiltration,
          isFalse);
    });

    test('test-only self-signed opt-in still denies peripheral I/O streams',
        () {
      // Tolerating the test BMC's untrusted server leaf relaxes ONLY that leaf's
      // trust. It must never let attacker-influenced console content enumerate
      // or open a WebUSB / WebSerial / WebHID stream to smuggle privileged KVM
      // frames / session tokens / credentials / host inventory to a physically
      // attached device (a local-hardware channel that bypasses network egress)
      // or relay it off-host — a distinct peripheral I/O surface, not a generic
      // device-permission grant, a filesystem handle, a WebTransport / WebRTC
      // transport or a network egress destination. Hard invariant, independent
      // of flag / TLS mode.
      expect(
          KvmWebViewPolicy.testOptIn.bypassPeripheralIoExfiltration, isFalse);
    });

    test('no policy configuration can expose peripheral I/O', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      const KvmWebViewPolicy enabledSelfSigned = KvmWebViewPolicy(
        enabled: true,
        tlsMode: KvmWebViewTlsMode.testOptInSelfSigned,
      );
      expect(enabledStrict.bypassPeripheralIoExfiltration, isFalse);
      expect(enabledSelfSigned.bypassPeripheralIoExfiltration, isFalse);
      expect(enabledSelfSigned.acceptsSelfSigned, isTrue);
      // Every other hard invariant stays independent of the peripheral-I/O
      // surface: the test-only opt-in can disable none of them.
      expect(enabledSelfSigned.bypassHostnameVerification, isFalse);
      expect(enabledSelfSigned.bypassCertificatePinning, isFalse);
      expect(enabledSelfSigned.bypassTlsProtocolFloor, isFalse);
      expect(enabledSelfSigned.bypassHttpsOnlyTransport, isFalse);
      expect(enabledSelfSigned.bypassCertificateRevocationCheck, isFalse);
      expect(enabledSelfSigned.bypassValidatedOriginBinding, isFalse);
      expect(enabledSelfSigned.bypassPlatformTrustStoreIntegrity, isFalse);
      expect(enabledSelfSigned.bypassClientCertificateValidation, isFalse);
      expect(enabledSelfSigned.bypassStrictReferrerPolicy, isFalse);
      expect(enabledSelfSigned.bypassMixedContentBlocking, isFalse);
      expect(enabledSelfSigned.bypassLogRedaction, isFalse);
      expect(enabledSelfSigned.bypassSensitiveDataAtRestProtection, isFalse);
      expect(enabledSelfSigned.bypassNativeBridgeIsolation, isFalse);
      expect(enabledSelfSigned.bypassPrivateNetworkEgressProtection, isFalse);
      expect(enabledSelfSigned.bypassCookieIsolation, isFalse);
      expect(enabledSelfSigned.bypassWebViewRemoteDebugging, isFalse);
      expect(enabledSelfSigned.bypassDevicePermissionControls, isFalse);
      expect(enabledSelfSigned.bypassHttpAuthChallengeDenial, isFalse);
      expect(enabledSelfSigned.bypassLocalFileAccess, isFalse);
      expect(enabledSelfSigned.bypassOutboundEgressAllowlist, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginFormSubmission, isFalse);
      expect(enabledSelfSigned.bypassSslErrorRejection, isFalse);
      expect(enabledSelfSigned.bypassTopLevelNavigationConfinement, isFalse);
      expect(enabledSelfSigned.bypassArbitraryFileDownload, isFalse);
      expect(enabledSelfSigned.bypassAutofillCredentialCapture, isFalse);
      expect(enabledSelfSigned.bypassFileChooserAccess, isFalse);
      expect(enabledSelfSigned.bypassTapjackingProtection, isFalse);
      expect(enabledSelfSigned.bypassJavaScriptDialogDenial, isFalse);
      expect(enabledSelfSigned.bypassServiceWorkerRegistration, isFalse);
      expect(enabledSelfSigned.bypassPrintExfiltration, isFalse);
      expect(enabledSelfSigned.bypassInputCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassPictureInPictureEscape, isFalse);
      expect(enabledSelfSigned.bypassShareCastExfiltration, isFalse);
      expect(enabledSelfSigned.bypassClipboardIsolation, isFalse);
      expect(enabledSelfSigned.bypassCrossOriginMessagingIsolation, isFalse);
      expect(enabledSelfSigned.bypassScreenCaptureProtection, isFalse);
      expect(enabledSelfSigned.bypassHyperlinkAuditingExfiltration, isFalse);
      expect(enabledSelfSigned.bypassCredentialManagementApiAccess, isFalse);
      expect(enabledSelfSigned.bypassSpeculationRulesEgress, isFalse);
      expect(enabledSelfSigned.bypassNotificationApiAccess, isFalse);
      expect(enabledSelfSigned.bypassWebRtcDataChannelExfiltration, isFalse);
      expect(enabledSelfSigned.bypassFileSystemAccessApi, isFalse);
      expect(enabledSelfSigned.bypassWebTransportExfiltration, isFalse);
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
