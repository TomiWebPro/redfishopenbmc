import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/client/auth_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Matches mock routes by path, ignoring host (mirrors the #002 test helper).
class _PathMatcher extends HttpRequestMatcher {
  const _PathMatcher();

  @override
  bool matches(RequestOptions ongoingRequest, Request matcher) {
    final dynamic route = matcher.route;
    final String routeStr = route is String ? route : route.toString();
    final String path = ongoingRequest.path;
    if (path == routeStr) return true;
    final Uri? uri = Uri.tryParse(path);
    if (uri != null && uri.path == routeStr) return true;
    return path.endsWith(routeStr);
  }
}

SystemManager buildStubbedManager({
  required InMemoryStorage storage,
  ProfileRepository? repository,
  Future<Session> Function(String, ConnectionProfile)? loginOverride,
  Future<SystemFeatures> Function(RedfishClient, String)? discoverOverride,
  Future<SystemSnapshot> Function(RedfishClient, String)? snapshotOverride,
}) {
  return SystemManager(
    repository: repository ?? InMemoryProfileRepository(),
    storage: storage,
    loginOverride: loginOverride,
    discoverOverride: discoverOverride,
    snapshotOverride: snapshotOverride,
  );
}

void main() {
  group('SystemManager — CRUD', () {
    test('addProfile assigns a UUID id and starts disconnected', () async {
      final SystemManager m =
          buildStubbedManager(storage: InMemoryStorage());
      final String id = await m.addProfile(
        const ConnectionProfile(host: 'h', name: 'A'),
      );
      expect(id, isNotEmpty);
      expect(m.state.systems.containsKey(id), isTrue);
      expect(m.state.systems[id]!.status, ConnectionStatus.disconnected);
      expect(m.state.selectedId, id);
    });

    test('removeProfile deletes the handle and persists removal', () async {
      final InMemoryStorage storage = InMemoryStorage();
      final InMemoryProfileRepository repo = InMemoryProfileRepository();
      final SystemManager m = buildStubbedManager(
        storage: storage,
        repository: repo,
      );
      final String id = await m.addProfile(
        const ConnectionProfile(host: 'h', name: 'A'),
      );
      expect(await repo.loadProfiles(), hasLength(1));
      await m.removeProfile(id);
      expect(m.state.systems.containsKey(id), isFalse);
      expect(await repo.loadProfiles(), isEmpty);
    });

    test('updateProfile persists and updates the handle', () async {
      final InMemoryProfileRepository repo = InMemoryProfileRepository();
      final SystemManager m = buildStubbedManager(
        storage: InMemoryStorage(),
        repository: repo,
      );
      final String id = await m.addProfile(
        const ConnectionProfile(host: 'h', name: 'A'),
      );
      await m.updateProfile(
        ConnectionProfile(id: id, host: 'h', name: 'Renamed'),
      );
      expect(m.state.systems[id]!.profile.name, 'Renamed');
      final List<ConnectionProfile> persisted = await repo.loadProfiles();
      expect(persisted.first.name, 'Renamed');
    });
  });

  group('SystemManager — persistence round-trip', () {
    test('rehydrate restores profiles across manager instances', () async {
      final InMemoryStorage storage = InMemoryStorage();
      final SecureStorageProfileRepository repo =
          SecureStorageProfileRepository(storage);
      final SystemManager m1 = SystemManager(
        repository: repo,
        storage: storage,
      );
      final String id = await m1.addProfile(
        const ConnectionProfile(
          host: 'h',
          name: 'A',
          rememberPassword: true,
          password: 'pw',
        ),
      );
      expect(id, isNotEmpty);

      // Fresh manager backed by the same storage.
      final SystemManager m2 = SystemManager(
        repository: SecureStorageProfileRepository(storage),
        storage: storage,
      );
      await m2.rehydrate();
      expect(m2.state.systems.containsKey(id), isTrue);
      expect(m2.state.systems[id]!.profile.password, 'pw');
    });
  });

  group('SystemManager — connect / discovery / snapshot', () {
    test('connect populates features, snapshot and marks connected', () async {
      final SystemManager m = buildStubbedManager(
        storage: InMemoryStorage(),
        loginOverride: (id, p) async => Session(
          systemId: id,
          token: 'tok-$id',
          location: '',
          username: p.username ?? '',
          createdAt: DateTime.now(),
        ),
        discoverOverride: (c, id) async => SystemFeatures(
          systemId: id,
          powerControl: true,
          sensorMonitoring: true,
        ),
        snapshotOverride: (c, id) async => const SystemSnapshot(
          health: Health.ok,
          powerState: PowerState.on,
        ),
      );
      final String id = await m.addProfile(
        const ConnectionProfile(host: 'h', name: 'A'),
      );
      await m.connect(id);
      final SystemHandle handle = m.state.systems[id]!;
      expect(handle.status, ConnectionStatus.connected);
      expect(handle.features!.powerControl, isTrue);
      expect(handle.snapshot!.health, Health.ok);
      expect(handle.session!.token, 'tok-$id');
    });

    test('connect failure sets status error and retains the profile', () async {
      final SystemManager m = buildStubbedManager(
        storage: InMemoryStorage(),
        loginOverride: (id, p) async => throw Exception('boom'),
      );
      final String id = await m.addProfile(
        const ConnectionProfile(host: 'h', name: 'A'),
      );
      await m.connect(id);
      expect(m.state.systems[id]!.status, ConnectionStatus.error);
      expect(m.state.systems[id]!.lastError, contains('boom'));
      // profile still present for retry
      expect(m.state.systems.containsKey(id), isTrue);
    });

    test('select performs an instant context switch without reconnect', () async {
      final SystemManager m = buildStubbedManager(
        storage: InMemoryStorage(),
        discoverOverride: (c, id) async => SystemFeatures(systemId: id),
        snapshotOverride: (c, id) async => const SystemSnapshot(health: Health.ok),
        loginOverride: (id, p) async => Session(
          systemId: id,
          token: 't',
          location: '',
          username: '',
        ),
      );
      final String a = await m.addProfile(const ConnectionProfile(host: 'a'));
      final String b = await m.addProfile(const ConnectionProfile(host: 'b'));
      await m.connect(a);
      m.select(b);
      expect(m.state.selectedId, b);
      // a's cached features/snapshot remain; b not force-reconnected
      expect(m.state.systems[a]!.status, ConnectionStatus.connected);
      expect(m.state.systems[b]!.status, ConnectionStatus.disconnected);
    });
  });

  group('SystemManager — token isolation', () {
    test('per-system tokens are stored under distinct keys', () async {
      final InMemoryStorage storage = InMemoryStorage();
      final SystemManager m = buildStubbedManager(
        storage: storage,
        loginOverride: (id, p) async {
          await storage.write('redfish.token.$id', 'tok-$id');
          return Session(
            systemId: id,
            token: 'tok-$id',
            location: '',
            username: p.username ?? '',
          );
        },
        discoverOverride: (c, id) async => SystemFeatures(systemId: id),
        snapshotOverride: (c, id) async => const SystemSnapshot(health: Health.ok),
      );
      final String bmc1 = await m.addProfile(const ConnectionProfile(host: '1'));
      final String bmc2 = await m.addProfile(const ConnectionProfile(host: '2'));
      await m.connect(bmc1);
      await m.connect(bmc2);

      expect(await storage.read('redfish.token.$bmc1'), 'tok-$bmc1');
      expect(await storage.read('redfish.token.$bmc2'), 'tok-$bmc2');
      expect(m.state.systems[bmc1]!.session!.token, 'tok-$bmc1');
      expect(m.state.systems[bmc2]!.session!.token, 'tok-$bmc2');
      expect(
        m.state.systems[bmc1]!.session!.token,
        isNot(m.state.systems[bmc2]!.session!.token),
      );
    });

    test('real auth manager stores per-system tokens (no cross-leak)', () async {
      final InMemoryStorage storage = InMemoryStorage();
      final Map<String, DioAdapter> adapters = <String, DioAdapter>{};
      DioAdapter adapterFor(String host) =>
          adapters.putIfAbsent(host, () {
            final Dio dio = Dio(BaseOptions(baseUrl: 'https://$host:443'));
            final DioAdapter a = DioAdapter(
              dio: dio,
              matcher: const _PathMatcher(),
            );
            a.onPost(
              '/redfish/v1/SessionService/Sessions',
              (server) => server.reply(
                200,
                <String, dynamic>{},
                headers: <String, List<String>>{
                  // http_mock_adapter only JSON-encodes the body when it
                  // recognizes the content-type header (case-sensitive
                  // 'content-type'); otherwise it tries to treat the Map body
                  // as a String and throws a cast error.
                  Headers.contentTypeHeader: <String>[Headers.jsonContentType],
                  'X-Auth-Token': <String>['tok-$host'],
                },
              ),
            );
            return a;
          });

      final AuthManager authManager = AuthManager(
        storage: storage,
        createClient: (ConnectionProfile p) =>
            RedfishClient(profile: p, dio: adapterFor(p.host).dio),
      );

      final SystemManager m = SystemManager(
        repository: InMemoryProfileRepository(),
        storage: storage,
        authManager: authManager,
        discoverOverride: (c, id) async => SystemFeatures(systemId: id),
        snapshotOverride: (c, id) async => const SystemSnapshot(health: Health.ok),
      );
      final String id = await m.addProfile(
        const ConnectionProfile(
          host: 'bmc1',
          username: 'root',
          password: 'pw',
        ),
      );
      await m.connect(id);
      expect(m.state.systems[id]!.status, ConnectionStatus.connected);
      expect(await storage.read('redfish.token.$id'), 'tok-bmc1');
      expect(m.state.systems[id]!.session!.token, 'tok-bmc1');
    });
  });

  group('SystemManager — dashboard aggregation', () {
    test('aggregated summary counts health across systems', () {
      final SystemManager m = buildStubbedManager(storage: InMemoryStorage());
      m.state = const SystemState(
        systems: <String, SystemHandle>{
          'a': const SystemHandle(
            profile: const ConnectionProfile(id: 'a', host: 'a'),
            snapshot: const SystemSnapshot(health: Health.ok),
          ),
          'b': const SystemHandle(
            profile: const ConnectionProfile(id: 'b', host: 'b'),
            snapshot: const SystemSnapshot(health: Health.warning),
          ),
          'c': const SystemHandle(
            profile: const ConnectionProfile(id: 'c', host: 'c'),
            snapshot: const SystemSnapshot(health: Health.critical),
          ),
          'd': const SystemHandle(
            profile: const ConnectionProfile(id: 'd', host: 'd'),
          ),
        },
      );
      expect(m.state.aggregated.total, 4);
      expect(m.state.aggregated.ok, 1);
      expect(m.state.aggregated.warning, 1);
      expect(m.state.aggregated.critical, 1);
      expect(m.state.aggregated.unknown, 1);
      expect(m.state.aggregated.summary, '1 OK, 1 Warning, 1 Critical, 1 Unknown');
    });
  });
}
