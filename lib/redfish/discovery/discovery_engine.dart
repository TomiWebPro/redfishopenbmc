import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery_cache.dart';
import 'package:redfishopenbmc/redfish/discovery/feature_rules.dart';
import 'package:redfishopenbmc/redfish/models/odata.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// The schema-driven Redfish discovery engine (issue #003).
///
/// Starting from `/redfish/v1/`, it performs a **cycle-safe, depth-bounded
/// (≤3) breadth-first traversal** of the `@odata.id` links for
/// `Systems` / `Managers` / `Chassis` / `UpdateService` / `SessionService`,
/// classifies each resource by its `@odata.type`, and feeds the normalized
/// raw material into [FeatureRules] to produce the per-system [SystemFeatures]
/// capability map that drives the UI ("nothing is assumed").
///
/// Design notes:
///  * **Concurrency**: member/thermal fetches run through a worker pool of
///    size [maxConcurrency] (default 4) so a slow BMC can't serialize the
///    crawl, but we never exceed a sane in-flight request count.
///  * **Cycle-safety**: a `Set<uri>` (visited) guarantees each URI is fetched
///    at most once, even when links are circular.
///  * **Minimal calls**: duplicates are deduped via `visited`; conditional
///    `If-None-Match` (ETag) requests let a re-crawl short-circuit with 304s.
///  * **Graceful degradation**: a missing tree (e.g. no `UpdateService`) or a
///    404 on a branch is recorded and skipped — discovery never crashes for a
///    partial BMC.
///  * **Caching**: results live in [DiscoveryCache] (TTL) and are mirrored to
///    an optional [DiscoveryPersister]; [invalidate] forces a lazy reload.
class DiscoveryEngine {
  /// Creates a [DiscoveryEngine].
  ///
  /// [maxConcurrency] bounds in-flight requests during a crawl (clamped to
  /// ≥1). [cacheTtl] controls the in-memory freshness window. [cache] and
  /// [persister] can be injected for testing or to plug in real storage.
  DiscoveryEngine({
    this.maxConcurrency = 4,
    Duration? cacheTtl,
    DiscoveryCache? cache,
    DiscoveryPersister? persister,
  })  : _cache = cache ?? DiscoveryCache(ttl: cacheTtl),
        _persister = persister ?? const NoOpDiscoveryPersister();

  /// Maximum number of concurrent requests issued while crawling.
  final int maxConcurrency;

  final DiscoveryCache _cache;
  final DiscoveryPersister _persister;

  /// The in-memory cache backing this engine (for inspection / testing).
  DiscoveryCache get cache => _cache;

  /// The persister mirroring cache entries (for inspection / testing).
  DiscoveryPersister get persister => _persister;

  /// System ids currently held in the cache (fresh or stale).
  List<String> get cachedSystemIds => _cache.peekAllIds();

  /// Discovers (or returns the cached) [SystemFeatures] for [systemId].
  ///
  /// When [forceRefresh] is `true` the cache is bypassed and a fresh crawl is
  /// performed — but previously learned ETags are still reused for conditional
  /// requests. On success the result is written back to [cache] and
  /// [persister]. A failed ServiceRoot fetch propagates a [RedfishException];
  /// failures on individual branches are tolerated (graceful degradation).
  Future<SystemFeatures> discover(
    RedfishClient client,
    String systemId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final DiscoveryCacheEntry? hit = _cache.get(systemId);
      if (hit != null) return hit.features;
    }

    final DiscoveryCacheEntry? previous = _cache.peek(systemId);
    final Map<String, String> etags = <String, String>{
      if (previous != null) ...previous.etags,
    };
    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{};
    if (previous != null) {
      for (final MapEntry<String, dynamic> e in previous.rawTree.entries) {
        if (e.value is Map<String, dynamic>) {
          bodies[e.key] = e.value as Map<String, dynamic>;
        }
      }
    }

    final DiscoveryContext ctx = await _crawl(client, etags, bodies);
    final SystemFeatures features = FeatureRules.build(systemId, ctx);
    final DiscoveryCacheEntry entry = DiscoveryCacheEntry(
      systemId: systemId,
      features: features,
      rawTree: ctx.rawTree,
      etags: Map<String, String>.from(etags),
      fetchedAt: DateTime.now(),
    );
    _cache.put(entry);
    await _persister.save(entry);
    return features;
  }

  /// Returns the raw resource tree (URI → body) captured for [systemId].
  ///
  /// Convenience hook for a future developer "raw explorer" mode; no UI yet.
  Future<Map<String, dynamic>> rawTree(
    RedfishClient client,
    String systemId, {
    bool forceRefresh = false,
  }) async {
    final SystemFeatures features = await discover(
      client,
      systemId,
      forceRefresh: forceRefresh,
    );
    final DiscoveryCacheEntry? entry = _cache.peek(systemId);
    return entry?.rawTree ?? features.raw;
  }

  /// Drops the cached discovery for [systemId] (and any persisted mirror),
  /// forcing a fresh crawl on next navigation.
  void invalidate(String systemId) {
    _cache.remove(systemId);
    _persister.clear(systemId);
  }

  /// The actual crawl: ServiceRoot → top-level seeds → concurrent BFS.
  Future<DiscoveryContext> _crawl(
    RedfishClient client,
    Map<String, String> etags,
    Map<String, Map<String, dynamic>> bodies,
  ) async {
    final Map<String, dynamic> rawTree = <String, dynamic>{};
    final List<Map<String, dynamic>> systems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> managers = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> chassis = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> thermals = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> sensors = <Map<String, dynamic>>[];
    Map<String, dynamic>? updateService;
    Map<String, dynamic>? sessionService;
    final Map<String, dynamic> actionInfos = <String, dynamic>{};

    void classify(Map<String, dynamic> res) {
      if (res.containsKey('Members')) {
        // Most collections carry no feature signal, but a `Sensors`
        // collection still contributes its member count via FeatureRules.
        final String? t = ODataResource(res).type?.toLowerCase();
        if (t != null && t.contains('sensorcollection')) {
          sensors.add(res);
        }
        return;
      }
      final ODataResource r = ODataResource(res);
      if (r.isType('computersystem')) {
        systems.add(res);
      } else if (r.isType('manager')) {
        managers.add(res);
      } else if (r.isType('chassis')) {
        chassis.add(res);
      } else if (r.isType('thermal')) {
        thermals.add(res);
      } else if (r.isType('sensor')) {
        sensors.add(res);
      } else if (r.isType('updateservice')) {
        updateService = res;
      } else if (r.isType('sessionservice')) {
        sessionService = res;
      } else if (r.isType('actioninfo')) {
        final String? id = r.id;
        if (id != null) actionInfos[id] = res;
      }
    }

    // Step 1 — ServiceRoot.
    const String rootUri = '/redfish/v1/';
    final Map<String, dynamic> root =
        await _fetchUri(client, rootUri, etags, bodies);
    rawTree[rootUri] = root;
    classify(root);

    // Step 2 — top-level seeds (the five known trees).
    const List<String> topLevel = <String>[
      'Systems',
      'Managers',
      'Chassis',
      'UpdateService',
      'SessionService',
    ];
    final List<_Node> seeds = <_Node>[];
    for (final String key in topLevel) {
      final String? uri = _linkOf(root, key);
      if (uri != null) seeds.add(_Node(uri, 1));
    }

    // Step 3 — concurrent, cycle-safe BFS (depth ≤ 3).
    final Set<String> visited = <String>{
      rootUri,
      ...seeds.map((_Node n) => n.uri),
    };
    final Queue<_Node> queue = ListQueue<_Node>.from(seeds);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final _Node node = queue.removeFirst();
        try {
          final Map<String, dynamic> res =
              await _fetchUri(client, node.uri, etags, bodies);
          rawTree[node.uri] = res;
          classify(res);
          if (node.depth < 3) {
            for (final String child in _childLinks(res)) {
              if (visited.add(child)) {
                queue.add(_Node(child, node.depth + 1));
              }
            }
          }
        } on RedfishException catch (e) {
          rawTree[node.uri] = <String, dynamic>{'_error': e.message};
        }
      }
    }

    final int workerCount = maxConcurrency < 1 ? 1 : maxConcurrency;
    await Future.wait<void>(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );

    return DiscoveryContext(
      serviceRoot: root,
      systems: systems,
      managers: managers,
      chassis: chassis,
      thermals: thermals,
      sensors: sensors,
      updateService: updateService,
      sessionService: sessionService,
      actionInfos: actionInfos,
      rawTree: rawTree,
    );
  }

  /// Fetches [uri] through [client], honoring conditional ETag requests.
  ///
  /// Returns the decoded JSON body. On a `304 Not Modified` it replays the
  /// previously cached body (from [bodies]). Updates [etags]/[bodies] for
  /// future conditional requests on success.
  Future<Map<String, dynamic>> _fetchUri(
    RedfishClient client,
    String uri,
    Map<String, String> etags,
    Map<String, Map<String, dynamic>> bodies,
  ) async {
    final String path = _toRelative(client.profile.baseUrl, uri);
    final String? etag = etags[uri];
    final Map<String, String>? headers =
        etag != null ? <String, String>{'If-None-Match': etag} : null;

    final Response<dynamic> response;
    try {
      response = await client.dio.get<dynamic>(
        path,
        options: Options(
          headers: headers,
          // Accept 2xx and 304 (handled below); everything else throws.
          validateStatus: (int? status) =>
              status != null && status >= 200 && status < 400,
        ),
      );
    } on DioException catch (e) {
      throw RedfishException.fromDioException(
        e,
        uri: Uri.tryParse(path),
      );
    }

    if (response.statusCode == 304) {
      final Map<String, dynamic>? cached = bodies[uri];
      return cached ?? <String, dynamic>{};
    }

    final Map<String, dynamic> body = _decode(response.data);
    final String? newEtag = response.headers.value('etag');
    if (newEtag != null) {
      etags[uri] = newEtag;
      bodies[uri] = body;
    }
    return body;
  }

  /// Returns the child URIs to enqueue from a freshly-fetched [res].
  ///
  /// Collections expand to their member `@odata.id`s; chassis expand to their
  /// `Thermal` / `Sensors` / `Power` sub-resources; anything advertising
  /// `@Redfish.ActionInfo` links (ActionInfo *resources* — the bmcweb
  /// `ResetActionInfo` allow-list source, #022/#016) expands to those GET-able
  /// resources. Action *targets* (`Actions.*.target`) are POST-only and never
  /// followed.
  List<String> _childLinks(Map<String, dynamic> res) {
    final ODataResource r = ODataResource(res);
    if (r.isCollection) return r.memberIds();
    if (r.isType('chassis')) {
      return r.linkUris(<String>['Thermal', 'Sensors', 'Power']);
    }
    return _actionInfoLinks(res);
  }

  /// The `@Redfish.ActionInfo` URIs advertised by [res]'s `Actions` map.
  ///
  /// DSP0266 §9.6.14 / `ActionInfo.v1_4_1`: an action may link to an
  /// ActionInfo *resource* that documents its `Parameters[]` (including
  /// `AllowableValues`) — bmcweb publishes the reset allow-list this way
  /// (`ResetActionInfo`, DOCS-4/13). The links appear beside each action's
  /// `target`; only the link is followed (the target is a POST endpoint).
  List<String> _actionInfoLinks(Map<String, dynamic> res) {
    final List<String> uris = <String>[];
    for (final dynamic action in ODataResource(res).actions.values) {
      if (action is Map<dynamic, dynamic>) {
        final dynamic info = action['@Redfish.ActionInfo'];
        if (info is String && info.isNotEmpty) uris.add(info);
      } else if (action is Map<String, dynamic>) {
        final dynamic info = action['@Redfish.ActionInfo'];
        if (info is String && info.isNotEmpty) uris.add(info);
      }
    }
    return uris;
  }

  /// Resolves a top-level link [key] on [res] to its `@odata.id`, tolerating
  /// both the bare-string and `{ "@odata.id": "..." }` shapes.
  String? _linkOf(Map<String, dynamic> res, String key) {
    final dynamic value = res[key];
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<dynamic, dynamic>) {
      final dynamic id = value['@odata.id'];
      return id is String ? id : null;
    }
    return null;
  }

  /// Converts an absolute [uri] under [baseUrl] to a Dio-relative path.
  ///
  /// Redfish `@odata.id`s are sometimes fully-qualified; when the scheme/host/
  /// port match the client's base URL we strip them so the request stays on
  /// the same origin. Cross-origin URIs (unexpected) are left untouched.
  String _toRelative(String baseUrl, String uri) {
    if (!uri.startsWith('http://') && !uri.startsWith('https://')) return uri;
    final Uri? u = Uri.tryParse(uri);
    final Uri? b = Uri.tryParse(baseUrl);
    if (u != null &&
        b != null &&
        u.scheme == b.scheme &&
        u.host == b.host &&
        u.port == b.port) {
      return u.path + (u.hasQuery ? '?${u.query}' : '');
    }
    return uri;
  }

  /// Decodes a response body into a [Map<String, dynamic>], tolerating the
  /// small set of shapes Dio may hand back.
  Map<String, dynamic> _decode(dynamic data) {
    if (data == null) return <String, dynamic>{};
    if (data is Map<String, dynamic>) return data;
    if (data is Map<dynamic, dynamic>) {
      return Map<String, dynamic>.fromEntries(
        data.entries.map(
          (MapEntry<dynamic, dynamic> e) =>
              MapEntry<String, dynamic>(e.key.toString(), e.value),
        ),
      );
    }
    return <String, dynamic>{'value': data};
  }
}

/// A unit of work in the discovery BFS: a URI and its current depth.
class _Node {
  const _Node(this.uri, this.depth);

  final String uri;
  final int depth;
}
