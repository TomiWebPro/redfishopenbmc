import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_error.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';

/// Unit tests for the plain data models backing the Redfish client layer.
void main() {
  group('Session', () {
    test('isExpired is false before expiresAt', () {
      final Session s = Session(
        systemId: 'bmc1',
        token: 't',
        location: '',
        username: 'u',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(s.isExpired, isFalse);
    });

    test('isExpired is true after expiresAt', () {
      final Session s = Session(
        systemId: 'bmc1',
        token: 't',
        location: '',
        username: 'u',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(s.isExpired, isTrue);
    });

    test('expiresAt null means never expires (until 401)', () {
      const Session s = Session(
        systemId: 'bmc1',
        token: 't',
        location: '',
        username: 'u',
      );
      expect(s.isExpired, isFalse);
      expect(s.expiresAt, isNull);
    });

    test('copyWith overrides fields but keeps username', () {
      const Session s = Session(
        systemId: 'bmc1',
        token: 'old',
        location: '/x',
        username: 'u',
      );
      final Session next = s.copyWith(token: 'new', location: '/y');
      expect(next.token, 'new');
      expect(next.location, '/y');
      expect(next.username, 'u');
      expect(next.systemId, 'bmc1');
    });
  });

  group('ConnectionProfile', () {
    test('baseUrl combines scheme/host/port (https default)', () {
      const ConnectionProfile p =
          ConnectionProfile(host: '10.0.0.5', port: 8443);
      expect(p.baseUrl, 'https://10.0.0.5:8443');
      expect(p.scheme, 'https');
      expect(p.allowSelfSigned, isFalse);
      expect(p.preferSessionAuth, isTrue);
    });

    test('copyWith overrides subsets of fields', () {
      const ConnectionProfile p =
          ConnectionProfile(host: 'h', port: 443, username: 'a');
      final ConnectionProfile c = p.copyWith(
        port: 8443,
        allowSelfSigned: true,
        password: 'secret',
      );
      expect(c.host, 'h');
      expect(c.port, 8443);
      expect(c.allowSelfSigned, isTrue);
      expect(c.username, 'a');
      expect(c.password, 'secret');
    });
  });

  group('RedfishError.fromJson', () {
    test('parses capitalized DMTF/OpenBMC keys', () {
      final RedfishError e = RedfishError.fromJson(<String, dynamic>{
        'Code': 'Base.1.8.GeneralError',
        'Message': 'An error occurred',
        '@Message.ExtendedInfo': <dynamic>['detail one', 'detail two'],
      });
      expect(e.code, 'Base.1.8.GeneralError');
      expect(e.message, 'An error occurred');
      expect(e.extendedInfo, <String>['detail one', 'detail two']);
    });

    test('parses lowercase keys for lenient interop', () {
      final RedfishError e = RedfishError.fromJson(<String, dynamic>{
        'code': 'Base.1.0.GeneralError',
        'message': 'boom',
        'extendedInfo': <dynamic>['x'],
      });
      expect(e.code, 'Base.1.0.GeneralError');
      expect(e.message, 'boom');
      expect(e.extendedInfo, <String>['x']);
    });

    test('parses the DSP0266 error envelope ({"error":{...}})', () {
      // Spec-compliant BMC: everything nests under `error`, and
      // `@Message.ExtendedInfo` entries are message objects with `Message`.
      final RedfishError e = RedfishError.fromJson(<String, dynamic>{
        'error': <String, dynamic>{
          'code': 'Base.1.8.GeneralError',
          'message': 'A general error has occurred',
          '@Message.ExtendedInfo': <dynamic>[
            <String, dynamic>{
              '@odata.type': '#Message.v1_1_2.Message',
              'MessageId': 'Base.1.8.PropertyValueTypeError',
              'Message': 'The value 42 for the property AssetTag is of a '
                  'different type than the property can accept.',
              'Severity': 'Warning',
            },
          ],
        },
      });
      expect(e.code, 'Base.1.8.GeneralError');
      expect(e.message, 'A general error has occurred');
      expect(e.extendedInfo, isNotNull);
      expect(e.extendedInfo!.single, contains('different type'));
      expect(e.firstMessage, contains('AssetTag'));
    });

    test('envelope with extra top-level noise still uses the error object', () {
      final RedfishError e = RedfishError.fromJson(<String, dynamic>{
        'ok': true,
        'error': <String, dynamic>{
          'code': 'Base.1.8.PropertyMissing',
          'message': 'A required property is missing.',
        },
      });
      expect(e.code, 'Base.1.8.PropertyMissing');
      expect(e.message, 'A required property is missing.');
      expect(e.extendedInfo, isNull);
    });

    test('falls back to Unknown when keys absent', () {
      final RedfishError e = RedfishError.fromJson(<String, dynamic>{});
      expect(e.code, 'Unknown');
      expect(e.message, 'Unknown error');
      expect(e.extendedInfo, isNull);
    });
  });
}
