import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';

/// Credential-leak audit (#010): ensure secrets are not exposed via common
/// stringification/logging surfaces and that persistence call sites do not use
/// insecure shared-preferences storage for credentials.
void main() {
  group('Credential leak audit (#010)', () {
    test('ConnectionProfile.toString does not expose username or password', () {
      const ConnectionProfile profile = ConnectionProfile(
        id: 'bmc-audit',
        name: 'Audit BMC',
        host: '10.0.0.5',
        port: 443,
        username: 'root',
        password: 'super-secret-password',
      );

      final String text = profile.toString();

      expect(text, contains('10.0.0.5'));
      expect(text, isNot(contains('root')));
      expect(text, isNot(contains('super-secret-password')));
      expect(text, isNot(contains('password')));
    });

    test('lib/ contains no SharedPreferences-based credential persistence', () {
      final Directory lib = Directory('lib');
      expect(lib.existsSync(), isTrue, reason: 'lib/ directory must exist');

      final RegExp prefsPattern = RegExp(r'\bSharedPreferences\b');
      final List<String> offenders = <String>[];

      for (final FileSystemEntity entity
          in lib.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final String contents = entity.readAsStringSync();
        if (prefsPattern.hasMatch(contents)) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Credentials/profile secrets must not use SharedPreferences. '
            'Offenders: ${offenders.join(', ')}',
      );
    });

    test('lib/ does not write plaintext password via obvious print/debug sinks',
        () {
      final Directory lib = Directory('lib');
      final RegExp sinkPattern = RegExp(
        r"(print\(|debugPrint\(|log\().*password",
        caseSensitive: false,
      );
      final List<String> offenders = <String>[];

      for (final FileSystemEntity entity
          in lib.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final String contents = entity.readAsStringSync();
        if (sinkPattern.hasMatch(contents)) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Potential password logging sink found. Offenders: '
            '${offenders.join(', ')}',
      );
    });
  });
}
