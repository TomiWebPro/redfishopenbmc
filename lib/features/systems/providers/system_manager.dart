import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_snapshot_fetcher.dart';
import 'package:redfishopenbmc/redfish/client/auth_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Lifecycle status of a [SystemHandle] connection.
enum ConnectionStatus {
  /// Not connected (profile known, no active session).
  disconnected,

  /// Connection in progress (login / discovery / snapshot).
  connecting,

  /// Connected with a live session, features, and snapshot.
  connected,

  /// Last connection attempt failed.
  error,
}

/// A live, per-system handle aggregating everything the UI needs.
class SystemHandle {
  /// Creates a [SystemHandle].
  const SystemHandle({
    required this.profile,
    this.client,
    this.session,
    this.features,
    this.snapshot,
    this.status = ConnectionStatus.disconnected,
    this.lastError,
    this.lastSeen,
  });

  /// The connection profile for this system.
  final ConnectionProfile profile;

  /// Authenticated Redfish client (null until connected).
  final RedfishClient? client;

  /// Active session (null until connected).
  final Session? session;

  /// Discovered capability map (null until discovery completes).
  final SystemFeatures? features;

  /// Latest polled snapshot (null until first successful fetch).
  final SystemSnapshot? snapshot;

  /// Current connection lifecycle status.
  final ConnectionStatus status;

  /// Last error message when [status] is [ConnectionStatus.error].
  final String? lastError;

  /// When the handle was last successfully refreshed.
  final DateTime? lastSeen;

  /// Convenience accessor for the display name.
  String get displayName => profile.name ?? profile.host;

  /// Whether the system currently reports a healthy status.
  bool get isHealthy => snapshot?.health == Health.ok;

  /// Returns a copy with the provided fields overridden.
  SystemHandle copyWith({
    ConnectionProfile? profile,
    RedfishClient? client,
    bool clearClient = false,
    Session? session,
    bool clearSession = false,
    SystemFeatures? features,
    SystemSnapshot? snapshot,
    ConnectionStatus? status,
    String? lastError,
    DateTime? lastSeen,
  }) =>
      SystemHandle(
        profile: profile ?? this.profile,
        client: clearClient ? null : (client ?? this.client),
        session: clearSession ? null : (session ?? this.session),
        features: features ?? this.features,
        snapshot: snapshot ?? this.snapshot,
        status: status ?? this.status,
        lastError: lastError ?? this.lastError,
        lastSeen: lastSeen ?? this.lastSeen,
      );
}

/// Aggregated dashboard status counts across all systems.
class AggregatedStatus {
  /// Creates an [AggregatedStatus].
  const AggregatedStatus({
    this.ok = 0,
    this.warning = 0,
    this.critical = 0,
    this.unknown = 0,
  });

  /// Count of systems in [Health.ok].
  final int ok;

  /// Count of systems in [Health.warning].
  final int warning;

  /// Count of systems in [Health.critical].
  final int critical;

  /// Count of systems with unknown health.
  final int unknown;

  /// Total number of systems accounted for.
  int get total => ok + warning + critical + unknown;

  /// Builds an [AggregatedStatus] from a set of [SystemHandle]s.
  factory AggregatedStatus.fromHandles(Iterable<SystemHandle> handles) {
    int ok = 0;
    int warning = 0;
    int critical = 0;
    int unknown = 0;
    for (final SystemHandle h in handles) {
      switch (h.snapshot?.health ?? Health.unknown) {
        case Health.ok:
          ok++;
        case Health.warning:
          warning++;
        case Health.critical:
          critical++;
        case Health.unknown:
          unknown++;
      }
    }
    return AggregatedStatus(
      ok: ok,
      warning: warning,
      critical: critical,
      unknown: unknown,
    );
  }

  /// Human-readable summary, e.g. `2 OK, 1 Warning`.
  String get summary {
    if (total == 0) return 'No systems';
    final List<String> parts = <String>[];
    if (ok > 0) parts.add('$ok OK');
    if (warning > 0) parts.add('$warning Warning');
    if (critical > 0) parts.add('$critical Critical');
    if (unknown > 0) parts.add('$unknown Unknown');
    return parts.join(', ');
  }
}

/// Immutable state for the [SystemManager].
class SystemState {
  /// Creates a [SystemState].
  const SystemState({
    this.systems = const <String, SystemHandle>{},
    this.selectedId,
    this.busy = false,
    this.globalError,
  });

  /// All known systems keyed by [ConnectionProfile.id].
  final Map<String, SystemHandle> systems;

  /// Currently selected system id (drives context switching).
  final String? selectedId;

  /// Whether a global operation is in flight.
  final bool busy;

  /// Global error message, if any.
  final String? globalError;

  /// Returns a copy with the provided fields overridden.
  SystemState copyWith({
    Map<String, SystemHandle>? systems,
    String? selectedId,
    bool? busy,
    String? globalError,
  }) =>
      SystemState(
        systems: systems ?? this.systems,
        selectedId: selectedId ?? this.selectedId,
        busy: busy ?? this.busy,
        globalError: globalError ?? this.globalError,
      );

  /// All systems in insertion order.
  List<SystemHandle> get ordered => systems.values.toList();

  /// The currently selected [SystemHandle], or `null`.
  SystemHandle? get selectedHandle =>
      selectedId == null ? null : systems[selectedId];

  /// Aggregated health counts across all systems.
  AggregatedStatus get aggregated => AggregatedStatus.fromHandles(
        systems.values,
      );
}

/// Manages connection profiles, sessions, discovery, and live snapshots for
/// every BMC the operator has added (issue #004).
///
/// Design goals:
///  * One [SystemHandle] per profile; the [SystemManager] is the single source
///    of truth for multi-system state.
///  * Secure persistence: profiles via [ProfileRepository] (non-sensitive),
///    tokens via [AuthManager] (keystore). Passwords are never written to the
///    profile blob.
///  * Per-system isolation: sessions/tokens are keyed by [systemId]; a token
///    for `bmc1` can never reach `bmc2`.
///  * Instant context switching: selecting another [systemId] does not
///    re-discover; cached [SystemFeatures] and [SystemSnapshot] are reused.
class SystemManager extends StateNotifier<SystemState> {
  /// Creates a [SystemManager].
  ///
  /// [repository] and [storage] are required. [authManager] defaults to a
  /// standard [AuthManager] bound to [storage]. The three override callbacks
  /// (`loginOverride`, `discoverOverride`, `snapshotOverride`) inject test
  /// doubles so the manager is fully unit-testable without network.
  SystemManager({
    required this.repository,
    required this.storage,
    AuthManager? authManager,
    this.loginOverride,
    this.discoverOverride,
    this.snapshotOverride,
  })  : _auth = authManager ?? AuthManager(storage: storage),
        super(const SystemState());

  /// Persistence backend for profiles.
  final ProfileRepository repository;

  /// Secure storage for tokens (via [_auth]).
  final SecureStorage storage;

  final AuthManager _auth;

  /// Injects a login result without performing a real network login.
  final Future<Session> Function(String systemId, ConnectionProfile profile)?
      loginOverride;

  /// Injects discovery without a real engine crawl.
  final Future<SystemFeatures> Function(RedfishClient client, String systemId)?
      discoverOverride;

  /// Injects a snapshot fetch without a real HTTP call.
  final Future<SystemSnapshot> Function(RedfishClient client, String systemId)?
      snapshotOverride;

  SystemState _with(String id, SystemHandle handle) => state.copyWith(
        systems: <String, SystemHandle>{
          ...state.systems,
          id: handle,
        },
      );

  /// Loads persisted profiles and populates disconnected handles.
  ///
  /// Called once on startup (and is safe to re-invoke). Does not auto-connect;
  /// selection in the UI triggers [connect] (lazy reconnect).
  Future<void> rehydrate() async {
    final List<ConnectionProfile> profiles = await repository.loadProfiles();
    // The provider may have been disposed while we awaited the repository
    // (e.g. a fast test teardown). Guard the state mutation so we never write
    // to a disposed notifier.
    if (!mounted) return;
    final Map<String, SystemHandle> map = <String, SystemHandle>{};
    for (final ConnectionProfile p in profiles) {
      map[p.id] = SystemHandle(profile: p);
    }
    state = state.copyWith(systems: map);
  }

  /// Adds a profile, assigning a UUID [ConnectionProfile.id] when absent.
  ///
  /// Returns the canonical id. The new system starts disconnected.
  Future<String> addProfile(ConnectionProfile profile) async {
    final String id =
        profile.id.isEmpty ? ConnectionProfile.generateId() : profile.id;
    final ConnectionProfile withId =
        profile.id.isEmpty ? profile.copyWith(id: id) : profile;
    await repository.saveProfile(withId);
    state = state.copyWith(
      systems: <String, SystemHandle>{
        ...state.systems,
        id: SystemHandle(profile: withId),
      },
      selectedId: state.selectedId ?? id,
    );
    return id;
  }

  /// Updates an existing profile in place and persists it.
  Future<void> updateProfile(ConnectionProfile profile) async {
    await repository.saveProfile(profile);
    final SystemHandle? existing = state.systems[profile.id];
    final SystemHandle next = existing != null
        ? existing.copyWith(profile: profile)
        : SystemHandle(profile: profile);
    state = _with(profile.id, next);
  }

  /// Removes a profile, logging it out first if connected.
  Future<void> removeProfile(String id) async {
    final SystemHandle? handle = state.systems[id];
    if (handle != null && handle.status == ConnectionStatus.connected) {
      await _auth.logout(id);
    }
    await repository.removeProfile(id);
    final Map<String, SystemHandle> systems = <String, SystemHandle>{
      ...state.systems
    }..remove(id);
    final String? selectedId = state.selectedId == id
        ? (systems.isNotEmpty ? systems.keys.first : null)
        : state.selectedId;
    state = state.copyWith(systems: systems, selectedId: selectedId);
  }

  /// Connects (login + discover + snapshot) a system.
  ///
  /// On failure the handle transitions to [ConnectionStatus.error] with a
  /// populated [SystemHandle.lastError]; the profile is retained so the user
  /// can retry.
  Future<void> connect(String id) async {
    final SystemHandle? handle = state.systems[id];
    if (handle == null) return;
    state = _with(id, handle.copyWith(status: ConnectionStatus.connecting));

    try {
      final ConnectionProfile profile = handle.profile;
      final Session session;
      final RedfishClient client;
      if (loginOverride != null) {
        session = await loginOverride!(id, profile);
        client = RedfishClient(profile: profile);
      } else {
        session = await _auth.login(id, profile);
        client = _auth.clientFor(id)!;
      }

      final SystemFeatures features = discoverOverride != null
          ? await discoverOverride!(client, id)
          : await DiscoveryEngine().discover(client, id);

      final SystemSnapshot snapshot = snapshotOverride != null
          ? await snapshotOverride!(client, id)
          : await fetchSystemSnapshot(client);

      state = _with(
        id,
        handle.copyWith(
          session: session,
          client: client,
          features: features,
          snapshot: snapshot,
          status: ConnectionStatus.connected,
          lastSeen: DateTime.now(),
        ),
      );
    } on RedfishException catch (e) {
      state = _with(
        id,
        handle.copyWith(
          status: ConnectionStatus.error,
          lastError: e.message,
        ),
      );
    } catch (e) {
      state = _with(
        id,
        handle.copyWith(
          status: ConnectionStatus.error,
          lastError: e.toString(),
        ),
      );
    }
  }

  /// Disconnects a system: logs out (deletes token) and clears live state.
  Future<void> disconnect(String id) async {
    final SystemHandle? handle = state.systems[id];
    if (handle == null) return;
    await _auth.logout(id);
    state = _with(
      id,
      handle.copyWith(
        status: ConnectionStatus.disconnected,
        clearSession: true,
        clearClient: true,
        features: null,
        snapshot: null,
      ),
    );
  }

  /// Selects the active system (context switch). Does not reconnect.
  void select(String id) => state = state.copyWith(selectedId: id);

  /// Re-fetches the live snapshot for a connected system.
  Future<void> refreshSnapshot(String id) async {
    final SystemHandle? handle = state.systems[id];
    if (handle == null || handle.client == null) return;
    try {
      final SystemSnapshot snapshot = snapshotOverride != null
          ? await snapshotOverride!(handle.client!, id)
          : await fetchSystemSnapshot(handle.client!);
      state = _with(
        id,
        handle.copyWith(snapshot: snapshot, lastSeen: DateTime.now()),
      );
    } catch (_) {
      // Keep the previous snapshot on a transient failure.
    }
  }

  /// Reconnects every currently-known profile (used on app resume).
  Future<void> connectAll() async {
    for (final String id in state.systems.keys.toList()) {
      await connect(id);
    }
  }

  /// Re-connects only the systems whose last attempt failed
  /// (dashboard error-summary Retry action).
  Future<void> retryFailed() async {
    final List<String> failed = state.systems.values
        .where((SystemHandle h) => h.status == ConnectionStatus.error)
        .map((SystemHandle h) => h.profile.id)
        .toList();
    for (final String id in failed) {
      await connect(id);
    }
  }
}

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

/// Per-system [SystemHandle] accessor keyed by [systemId].
final ProviderFamily<SystemHandle?, String> systemHandleProvider =
    Provider.family<SystemHandle?, String>((ref, String systemId) {
  return ref.watch(systemManagerProvider).systems[systemId];
});

/// The currently selected [SystemHandle], or `null`.
final Provider<SystemHandle?> selectedSystemProvider =
    Provider<SystemHandle?>((ref) {
  return ref.watch(systemManagerProvider.select((s) => s.selectedHandle));
});
