import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// TLS-first downgrade enforcement (#010): a profile that requires TLS must
/// never accept a response that was delivered over plaintext `http`, even if
/// that plaintext hop was reached via an `https -> http` redirect.
void main() {
  group('assertNoTlsDowngrade (policy)', () {
    const ConnectionProfile tlsProfile = ConnectionProfile(
      id: 'tls-strict',
      host: 'bmc.example',
      scheme: 'https',
    );
    const ConnectionProfile plainProfile = ConnectionProfile(
      id: 'plain-opt-in',
      host: 'bmc.local',
      scheme: 'http',
    );

    test('allows an https response for a TLS profile', () {
      expect(
        () => RedfishClient.assertNoTlsDowngrade(
          tlsProfile,
          Uri.parse('https://bmc.example:443/redfish/v1/'),
        ),
        returnsNormally,
      );
    });

    test('allows a null effective URI (no response to inspect)', () {
      expect(
        () => RedfishClient.assertNoTlsDowngrade(tlsProfile, null),
        returnsNormally,
      );
    });

    test('rejects an http response for a TLS profile', () {
      expect(
        () => RedfishClient.assertNoTlsDowngrade(
          tlsProfile,
          Uri.parse('http://bmc.example/redfish/v1/'),
        ),
        throwsA(
          isA<RedfishException>()
              .having((e) => e.errorCode, 'errorCode', 'TlsDowngradeRejected')
              .having((e) => e.retryable, 'retryable', isFalse)
              .having(
                (e) => e.uri?.scheme,
                'uri scheme',
                'http',
              ),
        ),
      );
    });

    test('normalizes scheme case before deciding', () {
      // Uri.parse lowercases the scheme, so an uppercase HTTP is still caught.
      expect(
        () => RedfishClient.assertNoTlsDowngrade(
          tlsProfile,
          Uri.parse('HTTP://bmc.example/redfish/v1/'),
        ),
        throwsA(isA<RedfishException>()),
      );
    });

    test('does not reject plaintext for a profile that opted out of TLS', () {
      // HTTP profiles are a deliberate user opt-in (warned in the form).
      expect(
        () => RedfishClient.assertNoTlsDowngrade(
          plainProfile,
          Uri.parse('http://bmc.local/redfish/v1/'),
        ),
        returnsNormally,
      );
    });

    test('rejection message does not expose credentials or the password', () {
      final ConnectionProfile withSecret = tlsProfile.copyWith(
        username: 'admin',
        password: 'super-secret-value',
      );
      late RedfishException caught;
      try {
        RedfishClient.assertNoTlsDowngrade(
          withSecret,
          Uri.parse('http://bmc.example/redfish/v1/'),
        );
      } on RedfishException catch (e) {
        caught = e;
      }
      expect(caught.message, isNot(contains('super-secret-value')));
      expect(caught.message, isNot(contains('admin')));
    });
  });

  group('RedfishClient rejects an https -> http redirect (TLS profile)', () {
    late Directory tmp;
    late HttpServer httpsServer;
    late HttpServer httpServer;
    late int httpsPort;
    late int httpPort;

    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('rf_downgrade_test_');
      final String certPath = '${tmp.path}/cert.pem';
      final String keyPath = '${tmp.path}/key.pem';
      final ProcessResult gen = await Process.run('openssl', <String>[
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-nodes',
        '-days',
        '1',
        '-keyout',
        keyPath,
        '-out',
        certPath,
        '-subj',
        '/CN=127.0.0.1',
        '-addext',
        'subjectAltName=IP:127.0.0.1,DNS:localhost',
      ]);
      if (gen.exitCode != 0) {
        throw StateError('openssl failed (${gen.exitCode}): ${gen.stderr}');
      }

      httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      httpPort = httpServer.port;
      httpServer.listen((HttpRequest request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write('{"leaked":true}');
        request.response.close();
      });

      final SecurityContext context = SecurityContext()
        ..useCertificateChain(certPath)
        ..usePrivateKey(keyPath);
      httpsServer = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      httpsPort = httpsServer.port;
      httpsServer.listen((HttpRequest request) {
        // Redirect the TLS session down to plaintext HTTP.
        request.response.redirect(
          Uri.parse('http://127.0.0.1:$httpPort/redfish/v1/'),
        );
        request.response.close();
      });
    });

    tearDownAll(() async {
      await httpsServer.close(force: true);
      await httpServer.close(force: true);
      if (tmp.existsSync()) {
        await tmp.delete(recursive: true);
      }
    });

    test('GET never consumes the downgraded plaintext body', () async {
      final RedfishClient client = RedfishClient(
        profile: ConnectionProfile(
          id: 'tls-redirect',
          host: '127.0.0.1',
          port: httpsPort,
          scheme: 'https',
          allowSelfSigned: true,
        ),
      );

      await expectLater(
        client.getJson('/redfish/v1/'),
        throwsA(
          isA<RedfishException>().having(
            (e) => e.errorCode,
            'errorCode',
            'TlsDowngradeRejected',
          ),
        ),
      );
    });
  });
}
