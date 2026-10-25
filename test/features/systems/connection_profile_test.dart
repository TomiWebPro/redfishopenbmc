import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';

void main() {
  group('ConnectionProfile', () {
    test('baseUrl combines scheme/host/port and useTls derives from scheme',
        () {
      const ConnectionProfile p =
          ConnectionProfile(host: '10.0.0.5', port: 8443);
      expect(p.baseUrl, 'https://10.0.0.5:8443');
      expect(p.useTls, isTrue);
      expect(p.scheme, 'https');

      final ConnectionProfile insecure = p.copyWith(scheme: 'http');
      expect(insecure.useTls, isFalse);
      expect(insecure.baseUrl, 'http://10.0.0.5:8443');
    });

    test('authMethod defaults to session and mirrors preferSessionAuth', () {
      const ConnectionProfile p = ConnectionProfile(host: 'h');
      expect(p.authMethod, AuthMethod.session);
      expect(p.preferSessionAuth, isTrue);

      final ConnectionProfile basic = p.copyWith(
        authMethod: AuthMethod.basic,
        preferSessionAuth: false,
      );
      expect(basic.authMethod, AuthMethod.basic);
      expect(basic.preferSessionAuth, isFalse);
    });

    test('toJson/fromJson round-trips all fields', () {
      final ConnectionProfile p = ConnectionProfile(
        id: 'abc',
        name: 'Lab BMC',
        host: 'bmc.local',
        port: 8443,
        scheme: 'https',
        allowSelfSigned: true,
        authMethod: AuthMethod.basic,
        username: 'root',
        password: 's3cret',
        rememberPassword: true,
        createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      final Map<String, dynamic> json = p.toJson();
      final ConnectionProfile back = ConnectionProfile.fromJson(json);

      expect(back.id, 'abc');
      expect(back.name, 'Lab BMC');
      expect(back.host, 'bmc.local');
      expect(back.port, 8443);
      expect(back.allowSelfSigned, isTrue);
      expect(back.authMethod, AuthMethod.basic);
      expect(back.username, 'root');
      expect(back.password, 's3cret');
      expect(back.rememberPassword, isTrue);
      expect(back.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });

    test('fromJson tolerates missing fields', () {
      final ConnectionProfile p =
          ConnectionProfile.fromJson(<String, dynamic>{});
      expect(p.id, '');
      expect(p.host, '');
      expect(p.port, 443);
      expect(p.authMethod, AuthMethod.session);
      expect(p.createdAt, isNull);
    });

    test('generateId returns a UUID v4 string', () {
      final String id = ConnectionProfile.generateId();
      expect(
          id,
          matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
              r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });
  });
}
