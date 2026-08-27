import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A single cached discovery result for one system.
///
/// Carries the computed [features], the [rawTree] (URI → body) for the raw
/// explorer, and the [etags] learned during the crawl so a subsequent crawl
/// can issue conditional `If-None-Match` requests (HTTP 304 short-circuits).
class DiscoveryCacheEntry {
  /// Creates a [DiscoveryCacheEntry].
  const DiscoveryCacheEntry({
    required this.systemId,
    required this.features,
    required this.rawTree,
    required this.etags,
    required this.fetchedAt,
  });

  /// The owning system id.
  final String systemId;

  /// The computed capability map.
  final SystemFeatures features;

  /// The raw resource tree captured during the crawl.
  final Map<String, dynamic> rawTree;

  /// URI → ETag learned during the crawl (for conditional re-validation).
  final Map<String, String> etags;

  /// When this entry was produced.
  final DateTime fetchedAt;

  /// Whether this entry is older than [ttl].
  bool isExpired(Duration ttl) =>
      DateTime.now().difference(fetchedAt) > ttl;
}

/// In-memory, per-system discovery cache with a sliding TTL.
///
/// This is the authoritative (fast) cache: [discover] operations read it
/// before hitting the network and write back after every successful crawl.
/// An optional [DiscoveryPersister] mirrors entries to slower storage.
class DiscoveryCache {
  /// Creates a [DiscoveryCache] with the given [ttl] (default 5 minutes).
  DiscoveryCache({Duration? ttl})
      : ttl = ttl ?? const Duration(minutes: 5);

  /// How long a cached entry stays fresh before a re-crawl is required.
  final Duration ttl;

  final Map<String, DiscoveryCacheEntry> _store =
      <String, DiscoveryCacheEntry>{};

  /// Returns the cached entry for [systemId] if present *and* fresh.
  DiscoveryCacheEntry? get(String systemId) {
    final DiscoveryCacheEntry? entry = _store[systemId];
    if (entry == null) return null;
    if (entry.isExpired(ttl)) {
      // Drop stale entries lazily so memory stays bounded.
      _store.remove(systemId);
      return null;
    }
    return entry;
  }

  /// Returns the cached entry for [systemId] regardless of TTL (may be stale).
  DiscoveryCacheEntry? peek(String systemId) => _store[systemId];

  /// All system ids currently held, fresh or stale (snapshot copy).
  List<String> peekAllIds() => List<String>.from(_store.keys);

  /// Stores [entry], replacing any previous value for the same system.
  void put(DiscoveryCacheEntry entry) => _store[entry.systemId] = entry;

  /// Removes the entry for [systemId], if any.
  void remove(String systemId) => _store.remove(systemId);

  /// Drops every cached entry.
  void clear() => _store.clear();

  /// Number of systems currently held (fresh or stale).
  int get length => _store.length;
}

/// Optional slower-storage mirror for [DiscoveryCache].
///
/// The engine calls [load] before a crawl (to seed ETags) and [save] after.
/// The default [NoOpDiscoveryPersister] keeps everything in memory only; a
/// `shared_preferences` / `hive` implementation can be plugged in from #010
/// without touching the engine. Implementations must be safe to call
/// concurrently and must never throw.
abstract class DiscoveryPersister {
  /// Loads a previously persisted entry for [systemId], or `null`.
  Future<DiscoveryCacheEntry?> load(String systemId);

  /// Persists [entry] (overwrites any previous value for the system).
  Future<void> save(DiscoveryCacheEntry entry);

  /// Removes any persisted entry for [systemId].
  Future<void> clear(String systemId);
}

/// A [DiscoveryPersister] that does nothing — the default. Keeps the entire
/// stack in-memory, which is correct for a single app session.
class NoOpDiscoveryPersister implements DiscoveryPersister {
  /// Creates a [NoOpDiscoveryPersister].
  const NoOpDiscoveryPersister();

  @override
  Future<DiscoveryCacheEntry?> load(String systemId) async => null;

  @override
  Future<void> save(DiscoveryCacheEntry entry) async {}

  @override
  Future<void> clear(String systemId) async {}
}

/// An in-memory [DiscoveryPersister] used by tests and as a stand-in for a real
/// on-disk persistence layer. Survives only for the lifetime of the process.
class InMemoryDiscoveryPersister implements DiscoveryPersister {
  /// Creates an [InMemoryDiscoveryPersister].
  InMemoryDiscoveryPersister({Map<String, DiscoveryCacheEntry>? seed})
      : _store = Map<String, DiscoveryCacheEntry>.from(
          seed ?? <String, DiscoveryCacheEntry>{},
        );

  final Map<String, DiscoveryCacheEntry> _store;

  @override
  Future<DiscoveryCacheEntry?> load(String systemId) async => _store[systemId];

  @override
  Future<void> save(DiscoveryCacheEntry entry) async {
    _store[entry.systemId] = entry;
  }

  @override
  Future<void> clear(String systemId) async {
    _store.remove(systemId);
  }

  /// All currently persisted entries (test inspection).
  Map<String, DiscoveryCacheEntry> get entries =>
      Map<String, DiscoveryCacheEntry>.from(_store);
}
