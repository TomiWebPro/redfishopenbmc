import 'dart:collection';
import 'dart:developer' as developer;

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
  /// ≥1). [maxRequestsPerCrawl] caps total HTTP GETs per crawl (clamped to ≥1).
  /// [cacheTtl] controls the in-memory freshness window. [cache] and
  /// [persister] can be injected for testing or to plug in real storage.
  /// [onCrawlMetrics] observes per-crawl request metrics; when omitted they are
  /// emitted via [developer.log].
  DiscoveryEngine({
    this.maxConcurrency = 4,
    this.maxRequestsPerCrawl = 64,
    Duration? cacheTtl,
    DiscoveryCache? cache,
    DiscoveryPersister? persister,
    this.onCrawlMetrics,
  })  : _cache = cache ?? DiscoveryCache(ttl: cacheTtl),
        _persister = persister ?? const NoOpDiscoveryPersister();

  /// Maximum number of concurrent requests issued while crawling.
  final int maxConcurrency;

  /// Hard safety ceiling on HTTP GETs a single crawl may issue (clamped to
  /// ≥1). The default is well above a typical OpenBMC tree so normal discovery
  /// is unaffected; a misbehaving/cyclic link graph can never turn a crawl
  /// into an unbounded request storm (#010 performance budget).
  final int maxRequestsPerCrawl;

  /// Soft target for a typical OpenBMC discovery, from the #010 performance
  /// budget ("≤8 requests for typical OpenBMC"). Used for logging/inspection
  /// only — it never short-circuits a crawl.
  static const int typicalRequestBudget = 8;

  /// Optional observer invoked once per completed crawl with its metrics.
  /// When omitted, metrics are emitted through [developer.log] instead.
  final void Function(DiscoveryCrawlMetrics metrics)? onCrawlMetrics;

  /// Metrics for the most recent crawl. A cache hit does not update these.
  DiscoveryCrawlMetrics? get lastCrawlMetrics => _lastCrawlMetrics;
  DiscoveryCrawlMetrics? _lastCrawlMetrics;

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
  /// A fresh cache hit returns directly (no network). When the cached entry is
  /// expired — or the in-memory cache is cold but [persister] holds a mirror —
  /// its learned ETags/rawTree seed a conditional (delta) re-crawl so unchanged
  /// branches short-circuit with HTTP 304. When [forceRefresh] is `true` both
  /// the cache and persister are bypassed for an unconditional crawl. On
  /// success the result is written back to [cache] and [persister]. A failed
  /// ServiceRoot fetch propagates a [RedfishException]; failures on individual
  /// branches are tolerated (graceful degradation).
  Future<SystemFeatures> discover(
    RedfishClient client,
    String systemId, {
    bool forceRefresh = false,
  }) async {
    // Peek *before* any TTL check: a stale entry is still valuable for its
    // learned ETags/rawTree, which let the re-crawl revalidate with 304s
    // (the "delta polling" half of the #010 performance budget). Using
    // DiscoveryCache.get() here would lazily evict the expired entry and lose
    // those ETags. A forceRefresh bypasses both the cache and the persister.
    final DiscoveryCacheEntry? inMemory =
        forceRefresh ? null : _cache.peek(systemId);
    if (inMemory != null && !inMemory.isExpired(_cache.ttl)) {
      return inMemory.features;
    }

    DiscoveryCacheEntry? previous = inMemory;
    if (previous == null && !forceRefresh) {
      // Cold in-memory cache: warm it from the slower-storage mirror so a new
      // session still revalidates conditionally instead of refetching the
      // whole tree. The persister is documented to seed ETags before a crawl.
      final DiscoveryCacheEntry? persisted = await _persister.load(systemId);
      if (persisted != null) {
        _cache.put(persisted);
        previous = persisted;
      }
    }
    final Map<String, String> etags = <String, String>{
      if (previous != null) ...previous.etags,
    };
    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{};
    if (previous != null) {
      for (final MapEntry<String, dynamic> e in previous.rawTree.entries) {
        final dynamic value = e.value;
        if (value is Map<String, dynamic> && !value.containsKey('_error')) {
          bodies[e.key] = value;
        }
      }
    }

    final DiscoveryContext ctx = await _crawl(client, systemId, etags, bodies);
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
    String systemId,
    Map<String, String> etags,
    Map<String, Map<String, dynamic>> bodies,
  ) async {
    final int requestBudget = maxRequestsPerCrawl < 1 ? 1 : maxRequestsPerCrawl;
    final int workerCount = maxConcurrency < 1 ? 1 : maxConcurrency;
    int requestsIssued = 0;
    int budgetSkips = 0;
    int activeRequests = 0;
    int peakConcurrentRequests = 0;

    // Single entry point for every GET in this crawl: counts requests, tracks
    // in-flight concurrency, and enforces the per-crawl budget. Returns null
    // when the budget stopped the crawl so callers skip that node without
    // fetching it. The worker pool bounds activeRequests by [workerCount];
    // recording the peak here proves the #010 "no Future.wait storm >4" rule.
    Future<Map<String, dynamic>?> fetch(String uri) async {
      if (requestsIssued >= requestBudget) {
        budgetSkips++;
        return null;
      }
      requestsIssued++;
      activeRequests++;
      if (activeRequests > peakConcurrentRequests) {
        peakConcurrentRequests = activeRequests;
      }
      try {
        return await _fetchUri(client, uri, etags, bodies);
      } finally {
        activeRequests--;
      }
    }

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

    // Step 1 — ServiceRoot (the first request; always within a ≥1 budget).
    const String rootUri = '/redfish/v1/';
    final Map<String, dynamic> root =
        (await fetch(rootUri)) ?? <String, dynamic>{};
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
          final Map<String, dynamic>? res = await fetch(node.uri);
          if (res == null) continue; // request budget exhausted — skip node.
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

    await Future.wait<void>(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );

    // #010 performance budget: measure + log (or hand to the observer) how
    // many HTTP requests this crawl actually issued.
    final DiscoveryCrawlMetrics metrics = DiscoveryCrawlMetrics(
      systemId: systemId,
      requestCount: requestsIssued,
      maxRequests: requestBudget,
      budgetSkips: budgetSkips,
      peakConcurrentRequests: peakConcurrentRequests,
      maxConcurrency: workerCount,
    );
    _lastCrawlMetrics = metrics;
    final void Function(DiscoveryCrawlMetrics)? observer = onCrawlMetrics;
    if (observer != null) {
      observer(metrics);
    } else {
      developer.log(
        '[discovery] $systemId crawl: $requestsIssued HTTP requests '
        '(soft target ≤$typicalRequestBudget, hard cap $requestBudget, '
        'skipped $budgetSkips, peak concurrency $peakConcurrentRequests/$workerCount)',
        name: 'redfish.discovery',
      );
    }

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

/// Per-crawl request metrics for [DiscoveryEngine].
///
/// This is the measurement half of the #010 performance budget ("Discovery:
/// ≤8 requests for typical OpenBMC — measured, logged debug"): [requestCount]
/// is the exact number of HTTP GETs a crawl issued, [maxRequests] the hard
/// ceiling it ran under, and [budgetSkips] how many discovered URIs were left
/// unfetched because that ceiling was reached. [peakConcurrentRequests] is the
/// most GETs that were ever in flight at once, bounded by [maxConcurrency]
/// (the "no Future.wait storm >4 concurrency" rule).
class DiscoveryCrawlMetrics {
  /// Creates crawl metrics.
  const DiscoveryCrawlMetrics({
    required this.systemId,
    required this.requestCount,
    required this.maxRequests,
    required this.budgetSkips,
    this.peakConcurrentRequests = 0,
    this.maxConcurrency = 0,
  });

  /// The system this crawl was for.
  final String systemId;

  /// Number of HTTP GETs issued during the crawl.
  final int requestCount;

  /// Hard request ceiling the crawl ran under (clamped to ≥1).
  final int maxRequests;

  /// Discovered URIs skipped because the hard ceiling was reached.
  final int budgetSkips;

  /// Most HTTP GETs that were in flight simultaneously during the crawl.
  /// Never exceeds [maxConcurrency] — the bounded worker-pool guarantee.
  final int peakConcurrentRequests;

  /// Effective worker/connection limit the crawl ran under (clamped to ≥1).
  final int maxConcurrency;

  /// Whether the crawl stayed within its hard request budget.
  bool get withinBudget => budgetSkips == 0;

  /// Whether the crawl met the soft "≤8 for a typical OpenBMC" target.
  bool get withinTypicalBudget =>
      requestCount <= DiscoveryEngine.typicalRequestBudget;

  /// Whether the crawl respected its configured concurrency limit.
  bool get withinConcurrencyLimit => peakConcurrentRequests <= maxConcurrency;

  /// JSON form, handy for debug logging / diagnostics.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'systemId': systemId,
        'requestCount': requestCount,
        'maxRequests': maxRequests,
        'budgetSkips': budgetSkips,
        'peakConcurrentRequests': peakConcurrentRequests,
        'maxConcurrency': maxConcurrency,
        'withinBudget': withinBudget,
        'withinTypicalBudget': withinTypicalBudget,
        'withinConcurrencyLimit': withinConcurrencyLimit,
      };

  @override
  String toString() => 'DiscoveryCrawlMetrics('
      'systemId: $systemId, requestCount: $requestCount, '
      'maxRequests: $maxRequests, budgetSkips: $budgetSkips, '
      'peakConcurrentRequests: $peakConcurrentRequests/$maxConcurrency)';
}

/// A unit of work in the discovery BFS: a URI and its current depth.
class _Node {
  const _Node(this.uri, this.depth);

  final String uri;
  final int depth;
}
