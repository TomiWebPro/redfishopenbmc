import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// TLS-first enforcement (#010): a BMC presenting a self-signed / untrusted
/// certificate must be rejected unless the profile explicitly opts in to
/// [ConnectionProfile.allowSelfSigned] (a per-profile security downgrade).
void main() {
  group('TLS enforcement (self-signed)', () {
    late Directory tmp;
    late String certPath;
    late String keyPath;
    late HttpServer server;
    late int port;

    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('rf_tls_test_');
      certPath = '${tmp.path}/cert.pem';
      keyPath = '${tmp.path}/key.pem';

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
        throw StateError(
          'openssl failed (${gen.exitCode}): ${gen.stderr}',
        );
      }

      final SecurityContext context = SecurityContext()
        ..useCertificateChain(certPath)
        ..usePrivateKey(keyPath);
      server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      port = server.port;
      server.listen((HttpRequest request) {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write('{"ok":true}');
        request.response.close();
      });
    });

    tearDownAll(() async {
      await server.close(force: true);
      if (tmp.existsSync()) {
        await tmp.delete(recursive: true);
      }
    });

    test('rejects self-signed certificate when allowSelfSigned is false',
        () async {
      final ConnectionProfile profile = ConnectionProfile(
        id: 'tls-strict',
        host: '127.0.0.1',
        port: port,
        scheme: 'https',
        allowSelfSigned: false,
      );
      final RedfishClient client = RedfishClient(profile: profile);

      await expectLater(
        () => client.getJson('/redfish/v1/'),
        throwsA(isA<RedfishException>()),
      );
    });

    test('accepts self-signed certificate only when explicitly allowed',
        () async {
      final ConnectionProfile profile = ConnectionProfile(
        id: 'tls-relaxed',
        host: '127.0.0.1',
        port: port,
        scheme: 'https',
        allowSelfSigned: true,
      );
      final RedfishClient client = RedfishClient(profile: profile);

      final Map<String, dynamic> body = await client.getJson('/redfish/v1/');
      expect(body['ok'], isTrue);
    });
  });
}
