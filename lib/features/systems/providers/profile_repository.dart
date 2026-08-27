import 'dart:convert';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';

/// Persistence contract for [ConnectionProfile] records.
///
/// Implementations store the **non-sensitive** profile metadata. Passwords are
/// never written into the profile blob; when [ConnectionProfile.rememberPassword]
/// is set the password is stored separately in the platform keystore. Tokens
/// are handled by [AuthManager], not here.
abstract class ProfileRepository {
  /// Loads all persisted profiles.
  Future<List<ConnectionProfile>> loadProfiles();

  /// Upserts a single [ConnectionProfile] (insert or replace by [id]).
  Future<void> saveProfile(ConnectionProfile profile);

  /// Removes the profile with [id], if present.
  Future<void> removeProfile(String id);

  /// Deletes every profile.
  Future<void> clear();
}

/// [ProfileRepository] backed by [SecureStorage].
///
/// The profile list is kept as a single JSON blob under [profileKey]; the
/// password field is stripped before serialization. When a profile requests
/// [ConnectionProfile.rememberPassword] its password is written under
/// `redfish.pw.<id>`. On load the password is re-attached from that key.
class SecureStorageProfileRepository implements ProfileRepository {
  /// Creates a [SecureStorageProfileRepository].
  const SecureStorageProfileRepository(this.storage);

  /// Key under which the profile list blob is stored.
  static const String profileKey = 'redfish.profiles';

  /// Prefix for per-profile remembered passwords.
  static const String passwordPrefix = 'redfish.pw.';

  /// Underlying secure storage.
  final SecureStorage storage;

  String _passwordKey(String id) => '$passwordPrefix$id';

  @override
  Future<List<ConnectionProfile>> loadProfiles() async {
    final String? raw = await storage.read(profileKey);
    if (raw == null || raw.isEmpty) return <ConnectionProfile>[];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final List<ConnectionProfile> result = <ConnectionProfile>[];
    for (final dynamic item in decoded) {
      final ConnectionProfile profile = ConnectionProfile.fromJson(
        item as Map<String, dynamic>,
      );
      String? password;
      if (profile.rememberPassword) {
        password = await storage.read(_passwordKey(profile.id));
      }
      result.add(profile.copyWith(password: password));
    }
    return result;
  }

  @override
  Future<void> saveProfile(ConnectionProfile profile) async {
    final List<ConnectionProfile> existing = await loadProfiles();
    final Map<String, ConnectionProfile> byId =
        <String, ConnectionProfile>{
      for (final ConnectionProfile p in existing) p.id: p,
    };
    byId[profile.id] = profile;
    await _persist(byId.values.toList());
    if (profile.rememberPassword && profile.password != null) {
      await storage.write(_passwordKey(profile.id), profile.password!);
    } else {
      await storage.delete(_passwordKey(profile.id));
    }
  }

  @override
  Future<void> removeProfile(String id) async {
    final List<ConnectionProfile> existing = await loadProfiles();
    final List<ConnectionProfile> remaining =
        existing.where((ConnectionProfile p) => p.id != id).toList();
    await _persist(remaining);
    await storage.delete(_passwordKey(id));
  }

  @override
  Future<void> clear() async {
    await storage.delete(profileKey);
  }

  Future<void> _persist(List<ConnectionProfile> profiles) async {
    final List<Map<String, dynamic>> sanitized = profiles.map((ConnectionProfile p) {
      final Map<String, dynamic> json = p.toJson();
      // Never persist the plaintext password in the profile blob; the keystore
      // holds it separately (see [saveProfile]) when rememberPassword is set.
      json['password'] = null;
      return json;
    }).toList();
    await storage.write(profileKey, jsonEncode(sanitized));
  }
}

/// In-memory [ProfileRepository] for tests and previews.
///
/// Keeps the entire profile (including password) in memory; no platform
/// channels involved.
class InMemoryProfileRepository implements ProfileRepository {
  /// Creates an empty [InMemoryProfileRepository].
  InMemoryProfileRepository(
    [Map<String, ConnectionProfile>? initial,
  ]) : _store = Map<String, ConnectionProfile>.from(
          initial ?? <String, ConnectionProfile>{},
        );

  final Map<String, ConnectionProfile> _store;

  @override
  Future<List<ConnectionProfile>> loadProfiles() async => _store.values.toList();

  @override
  Future<void> saveProfile(ConnectionProfile profile) async {
    _store[profile.id] = profile;
  }

  @override
  Future<void> removeProfile(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
