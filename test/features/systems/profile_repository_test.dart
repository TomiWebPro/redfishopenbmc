import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';

void main() {
  group('InMemoryProfileRepository', () {
    test('save / load / remove round-trips', () async {
      final InMemoryProfileRepository repo = InMemoryProfileRepository();
      await repo.saveProfile(
        const ConnectionProfile(id: 'a', host: 'h1', name: 'One'),
      );
      await repo.saveProfile(
        const ConnectionProfile(id: 'b', host: 'h2', name: 'Two'),
      );
      final List<ConnectionProfile> all = await repo.loadProfiles();
      expect(all.length, 2);

      await repo.removeProfile('a');
      expect(await repo.loadProfiles(), hasLength(1));
      await repo.clear();
      expect(await repo.loadProfiles(), isEmpty);
    });
  });

  group('SecureStorageProfileRepository', () {
    test('persists profiles and never writes password into the blob', () async {
      final InMemoryStorage storage = InMemoryStorage();
      final SecureStorageProfileRepository repo =
          SecureStorageProfileRepository(storage);

      final String id = await _add(repo, storage);
      final String? blob = await storage.read('redfish.profiles');
      expect(blob, isNotNull);
      expect(blob, isNot(contains('secret-pw')));

      // Password re-attached only because rememberPassword is true.
      final List<ConnectionProfile> loaded = await repo.loadProfiles();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, id);
      expect(loaded.first.password, 'secret-pw');
    });

    test('password is not persisted when rememberPassword is false', () async {
      final InMemoryStorage storage = InMemoryStorage();
      final SecureStorageProfileRepository repo =
          SecureStorageProfileRepository(storage);
      await repo.saveProfile(
        const ConnectionProfile(
          id: 'x',
          host: 'h',
          rememberPassword: false,
          password: 'forget-me',
        ),
      );
      expect(await storage.read('redfish.pw.x'), isNull);
      final List<ConnectionProfile> loaded = await repo.loadProfiles();
      expect(loaded.first.password, isNull);
    });

    test('removeProfile deletes blob entry and password key', () async {
      final InMemoryStorage storage = InMemoryStorage();
      final SecureStorageProfileRepository repo =
          SecureStorageProfileRepository(storage);
      final String id = await _add(repo, storage);
      await repo.removeProfile(id);
      expect(await storage.read('redfish.profiles'), '[]');
      expect(await storage.read('redfish.pw.$id'), isNull);
    });
  });
}

Future<String> _add(
  ProfileRepository repo,
  InMemoryStorage storage,
) async {
  final ConnectionProfile p = const ConnectionProfile(
    host: 'bmc.local',
    name: 'Lab',
    username: 'root',
    password: 'secret-pw',
    rememberPassword: true,
  );
  final String id = p.id.isEmpty ? ConnectionProfile.generateId() : p.id;
  await repo.saveProfile(p.copyWith(id: id));
  return id;
}
