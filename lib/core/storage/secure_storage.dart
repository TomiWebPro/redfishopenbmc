import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract secure storage interface.
///
/// Keeps tokens/credentials off plaintext; implementations must never log
/// values.
abstract class SecureStorage {
  /// Reads the value stored under [key], or `null` if absent.
  Future<String?> read(String key);

  /// Writes [value] under [key].
  Future<void> write(String key, String value);

  /// Deletes the value stored under [key].
  Future<void> delete(String key);

  /// Deletes all stored key/value pairs.
  Future<void> deleteAll();

  /// Whether a value is stored under [key].
  Future<bool> containsKey(String key);

  /// Returns a copy of all stored key/value pairs.
  Future<Map<String, String>> readAll();
}

/// Production implementation backed by the platform keystore
/// (Keychain / Keystore / credential manager).
class FlutterSecureStorageImpl implements SecureStorage {
  /// Creates a [FlutterSecureStorageImpl].
  FlutterSecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
}

/// In-memory implementation for tests and previews.
///
/// Never used in production; keeps the interface testable without platform
/// channels.
class InMemoryStorage implements SecureStorage {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<Map<String, String>> readAll() async =>
      Map<String, String>.from(_store);
}
