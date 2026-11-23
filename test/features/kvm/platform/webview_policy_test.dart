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
