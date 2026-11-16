import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';

void main() {
  group('No plaintext persistence (security regression)', () {
    test('lib/ does not use SharedPreferences for persistence', () {
      final Directory libDir = Directory('lib');
      final List<File> dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .toList();

      final RegExp sharedPrefsType = RegExp(r'\bSharedPreferences\b');
      final List<String> offenders = <String>[];
      for (final File file in dartFiles) {
        final String content = file.readAsStringSync();
        if (content.contains('package:shared_preferences') ||
            sharedPrefsType.hasMatch(content)) {
          offenders.add(file.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Passwords/credentials must never be stored via SharedPreferences; '
            'use SecureStorage/keystore-backed storage instead. Offenders: '
            '${offenders.join(', ')}',
      );
    });

    test(
      'profile blob never contains remembered password; password stored only in keystore key',
      () async {
        final InMemoryStorage storage = InMemoryStorage();
        final SecureStorageProfileRepository repo =
            SecureStorageProfileRepository(storage);

        const ConnectionProfile profile = ConnectionProfile(
          id: 'sec-1',
          host: 'bmc.example.com',
          name: 'Secure',
          username: 'admin',
          password: 'super-secret-password',
          rememberPassword: true,
        );

        await repo.saveProfile(profile);

        final String? blob =
            await storage.read(SecureStorageProfileRepository.profileKey);
        expect(blob, isNotNull);
        expect(blob, isNot(contains('super-secret-password')));

        final String pwKey =
            '${SecureStorageProfileRepository.passwordPrefix}${profile.id}';
        expect(await storage.read(pwKey), 'super-secret-password');

        // Keystore keys are limited to profile list + per-profile password key.
        final Map<String, String> all = await storage.readAll();
        expect(
          all.keys.toSet(),
          {SecureStorageProfileRepository.profileKey, pwKey},
        );
      },
    );

    test('rememberPassword=false leaves no password key in secure storage',
        () async {
      final InMemoryStorage storage = InMemoryStorage();
      final SecureStorageProfileRepository repo =
          SecureStorageProfileRepository(storage);

      const ConnectionProfile profile = ConnectionProfile(
        id: 'sec-2',
        host: 'bmc.example.com',
        name: 'NoRemember',
        username: 'admin',
        password: 'ephemeral-password',
        rememberPassword: false,
      );

      await repo.saveProfile(profile);

      final String pwKey =
          '${SecureStorageProfileRepository.passwordPrefix}${profile.id}';
      expect(await storage.read(pwKey), isNull);
      final String? blob =
          await storage.read(SecureStorageProfileRepository.profileKey);
      expect(blob, isNot(contains('ephemeral-password')));

      final List<ConnectionProfile> loaded = await repo.loadProfiles();
      expect(loaded.single.password, isNull);
    });
  });
}
