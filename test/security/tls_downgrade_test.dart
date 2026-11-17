import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
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

    test('fromDioException preserves an embedded RedfishException', () {
      // The raw-transport guard attaches an already-normalized exception to
      // the DioException; error normalization must not reclassify it.
      const RedfishException original = RedfishException(
        errorCode: 'TlsDowngradeRejected',
        message: 'downgraded',
      );
      final DioException wrapper = DioException(
        requestOptions: RequestOptions(path: '/redfish/v1/'),
        error: original,
      );
      expect(RedfishException.fromDioException(wrapper), same(original));
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

    test('raw transport from createDioForProfile rejects a downgraded GET',
        () async {
      // The auth manager issues raw `dio.get/post/delete/fetch` calls that
      // bypass RedfishClient.getJson; the interceptor installed by
      // createDioForProfile must enforce the same policy on those paths.
      final Dio dio = RedfishClient.createDioForProfile(
        ConnectionProfile(
          id: 'tls-redirect-raw',
          host: '127.0.0.1',
          port: httpsPort,
          scheme: 'https',
          allowSelfSigned: true,
        ),
      );
      Object? caught;
      try {
        await dio.get<dynamic>('/redfish/v1/');
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      final RedfishException normalized = caught is DioException
          ? RedfishException.fromDioException(caught)
          : caught as RedfishException;
      expect(normalized.errorCode, 'TlsDowngradeRejected');
      expect(normalized.retryable, isFalse);
    });

    test('raw session-creation POST never consumes a downgraded body',
        () async {
      // dart:io does not follow POST redirects, so simulate a response that
      // actually completed over plaintext `http` (realUri via redirects) to
      // prove the raw-transport interceptor guards credential-bearing calls.
      // The Dio (and its guard interceptor) comes from createDioForProfile;
      // only the adapter is swapped for a deterministic downgrade.
      final Dio dio = RedfishClient.createDioForProfile(
        const ConnectionProfile(
          id: 'tls-redirect-login',
          host: 'bmc.example',
          scheme: 'https',
        ),
      )..httpClientAdapter = _ForcedDowngradeAdapter();

      Object? caught;
      Response<dynamic>? delivered;
      try {
        delivered = await dio.post<dynamic>(
          '/redfish/v1/SessionService/Sessions',
          data: <String, String>{'UserName': 'admin', 'Password': 'pw'},
        );
      } catch (e) {
        caught = e;
      }
      // The downgraded plaintext body must never reach the caller.
      expect(delivered, isNull);
      expect(caught, isNotNull);
      final RedfishException normalized = caught is DioException
          ? RedfishException.fromDioException(caught)
          : caught as RedfishException;
      expect(normalized.errorCode, 'TlsDowngradeRejected');
    });

    test('raw transport for a plaintext opt-in profile is unaffected',
        () async {
      final Dio dio = RedfishClient.createDioForProfile(
        ConnectionProfile(
          id: 'plain-raw',
          host: '127.0.0.1',
          port: httpPort,
          scheme: 'http',
        ),
      );
      final Response<dynamic> response = await dio.get<dynamic>('/redfish/v1/');
      expect(response.statusCode, 200);
      expect((response.data as Map<dynamic, dynamic>)['leaked'], isTrue);
    });
  });
}

/// Simulates a response that completed over plaintext `http` after a redirect
/// (Dio derives [Response.realUri] from the last redirect location). Lets the
/// raw-transport guard be tested deterministically for methods dart:io will
/// not auto-redirect (e.g. POST session creation).
class _ForcedDowngradeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final ResponseBody body = ResponseBody.fromBytes(
      utf8.encode('{"leaked":true}'),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
    body.redirects = <RedirectRecord>[
      RedirectRecord(
        302,
        'GET',
        Uri.parse('http://bmc.example/redfish/v1/SessionService/Sessions'),
      ),
    ];
    return body;
  }

  @override
  void close({bool force = false}) {}
}
