import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/client/auth_manager.dart';

/// Provides the app-wide [SecureStorage] implementation.
final Provider<SecureStorage> secureStorageProvider = Provider<SecureStorage>(
  (ref) => FlutterSecureStorageImpl(),
);

/// Provides the [ProfileRepository] backed by [secureStorageProvider].
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
  (ref) => SecureStorageProfileRepository(
    ref.watch(secureStorageProvider),
  ),
);

/// Provides a shared [AuthManager] bound to [secureStorageProvider].
final Provider<AuthManager> authManagerProvider = Provider<AuthManager>(
  (ref) => AuthManager(storage: ref.watch(secureStorageProvider)),
);

/// The single [SystemManager] driving all multi-system state.
final StateNotifierProvider<SystemManager, SystemState> systemManagerProvider =
    StateNotifierProvider<SystemManager, SystemState>((ref) {
  final SystemManager manager = SystemManager(
    repository: ref.watch(profileRepositoryProvider),
    storage: ref.watch(secureStorageProvider),
    authManager: ref.watch(authManagerProvider),
  );
  // NOTE: `StateNotifierProvider` already disposes the notifier on provider
  // teardown, so we must NOT register an extra `ref.onDispose(manager.dispose)`
  // (that would double-dispose and trip the `mounted` assertion).
  // Rehydrate persisted profiles on startup. Guarded by `mounted` so the
  // fire-and-forget microtask can't touch the notifier after it is disposed
  // (e.g. a fast test teardown that overrides the provider).
  Future<void>.microtask(() async {
    if (manager.mounted) {
      await manager.rehydrate();
    }
  });
  return manager;
});
