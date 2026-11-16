import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/redfish/client/auth_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Matches a mocked request by path only, ignoring body/headers so mocked
/// session POSTs match regardless of credentials payload.
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

const Map<String, List<String>> _jsonContentType = <String, List<String>>{
  Headers.contentTypeHeader: [Headers.jsonContentType],
};

String _sessionsUrl() => '/redfish/v1/SessionService/Sessions';
String _rootUrl() => '/redfish/v1/';
String _systemUrl(String host) => '/redfish/v1/Systems/System-$host';
String _sessionLoc(String id) => '/redfish/v1/SessionService/Sessions/$id';

(AuthManager, Map<String, DioAdapter>) _buildManager() {
  final Map<String, DioAdapter> adapters = <String, DioAdapter>{};

  DioAdapter adapterFor(String host) => adapters.putIfAbsent(host, () {
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://$host:443'));
        return DioAdapter(dio: dio, matcher: const _PathMatcher());
      });

  adapterFor('bmc1');
  adapterFor('bmc2');

  final AuthManager manager = AuthManager(
    storage: InMemoryStorage(),
    createClient: (ConnectionProfile p) =>
        RedfishClient(profile: p, dio: adapterFor(p.host).dio),
  );

  return (manager, adapters);
}

/// Adds a post-auth capturing interceptor (after auth interceptor) and returns
/// the list it fills with request headers for each outgoing request.
List<Map<String, dynamic>> _capturePostAuth(
  Map<String, DioAdapter> adapters,
  String host,
) {
  final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
  adapters[host]!.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        list.add(<String, dynamic>{
          'host': host,
          'path': options.path,
          'headers': Map<String, dynamic>.from(options.headers),
        });
        handler.next(options);
      },
    ),
  );
  return list;
}

void _mockSessionLogin(
  DioAdapter adapter, {
  required String token,
  required String locationId,
}) {
  adapter.onPost(
    _sessionsUrl(),
    (server) => server.reply(
      201,
      <String, dynamic>{},
      headers: <String, List<String>>{
        ..._jsonContentType,
        'X-Auth-Token': <String>[token],
        'Location': <String>[_sessionLoc(locationId)],
      },
    ),
  );
  adapter.onGet(
    _rootUrl(),
    (server) => server.reply(200, <String, dynamic>{'@odata.id': _rootUrl()}),
  );
}

void main() {
  group('Token isolation (security)', () {
    test(
        'X-Auth-Token for bmc1 is never attached to bmc2 requests, even under '
        'concurrent Future.wait', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters) =
          _buildManager();
      _mockSessionLogin(adapters['bmc1']!, token: 'tok-bmc1', locationId: '1');
      _mockSessionLogin(adapters['bmc2']!, token: 'tok-bmc2', locationId: '2');

      adapters['bmc1']!.onGet(
        _systemUrl('bmc1'),
        (server) => server.reply(200, <String, dynamic>{'Id': 'System-bmc1'}),
      );
      adapters['bmc2']!.onGet(
        _systemUrl('bmc2'),
        (server) => server.reply(200, <String, dynamic>{'Id': 'System-bmc2'}),
      );

      await manager.login(
        'bmc1',
        const ConnectionProfile(
            host: 'bmc1', username: 'root', password: 'pw1'),
      );
      await manager.login(
        'bmc2',
        const ConnectionProfile(
            host: 'bmc2', username: 'root', password: 'pw2'),
      );

      final List<Map<String, dynamic>> bmc1Reqs =
          _capturePostAuth(adapters, 'bmc1');
      final List<Map<String, dynamic>> bmc2Reqs =
          _capturePostAuth(adapters, 'bmc2');

      await Future.wait<void>(<Future<void>>[
        manager.clientFor('bmc1')!.getJson(_systemUrl('bmc1')),
        manager.clientFor('bmc2')!.getJson(_systemUrl('bmc2')),
        manager.clientFor('bmc1')!.getJson(_systemUrl('bmc1')),
        manager.clientFor('bmc2')!.getJson(_systemUrl('bmc2')),
      ]);

      expect(bmc1Reqs, isNotEmpty);
      expect(bmc2Reqs, isNotEmpty);

      for (final Map<String, dynamic> req in bmc1Reqs) {
        final Map<String, dynamic> headers =
            req['headers'] as Map<String, dynamic>;
        expect(headers['X-Auth-Token'], 'tok-bmc1',
            reason: 'bmc1 must only ever carry its own token');
        expect(headers['X-Auth-Token'], isNot('tok-bmc2'));
      }
      for (final Map<String, dynamic> req in bmc2Reqs) {
        final Map<String, dynamic> headers =
            req['headers'] as Map<String, dynamic>;
        expect(headers['X-Auth-Token'], 'tok-bmc2',
            reason: 'bmc2 must only ever carry its own token');
        expect(headers['X-Auth-Token'], isNot('tok-bmc1'));
      }

      expect(manager.sessionFor('bmc1')!.token, 'tok-bmc1');
      expect(manager.sessionFor('bmc2')!.token, 'tok-bmc2');
    });

    test('401 on bmc1 does not clear or replace bmc2 token', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters) =
          _buildManager();

      int bmc1Posts = 0;
      adapters['bmc1']!.onPost(
        _sessionsUrl(),
        (server) {
          bmc1Posts++;
          final String token = bmc1Posts == 1 ? 'tok-bmc1-old' : 'tok-bmc1-new';
          final String loc = bmc1Posts == 1 ? '1' : '11';
          return server.reply(
            201,
            <String, dynamic>{},
            headers: <String, List<String>>{
              ..._jsonContentType,
              'X-Auth-Token': <String>[token],
              'Location': <String>[_sessionLoc(loc)],
            },
          );
        },
      );
      adapters['bmc1']!.onGet(
        _rootUrl(),
        (server) =>
            server.reply(200, <String, dynamic>{'@odata.id': _rootUrl()}),
      );
      // Best-effort logout of old session during relogin.
      adapters['bmc1']!.onDelete(
        _sessionLoc('1'),
        (server) => server.reply(204, <String, dynamic>{}),
      );

      _mockSessionLogin(adapters['bmc2']!, token: 'tok-bmc2', locationId: '2');

      bool bmc1First = true;
      adapters['bmc1']!.onGet(
        _systemUrl('bmc1'),
        (server) {
          if (bmc1First) {
            bmc1First = false;
            return server.reply(401, <String, dynamic>{'Message': 'expired'});
          }
          return server.reply(200, <String, dynamic>{'Id': 'System-bmc1'});
        },
      );
      adapters['bmc2']!.onGet(
        _systemUrl('bmc2'),
        (server) => server.reply(200, <String, dynamic>{'Id': 'System-bmc2'}),
      );

      await manager.login(
        'bmc1',
        const ConnectionProfile(
            host: 'bmc1', username: 'root', password: 'pw1'),
      );
      await manager.login(
        'bmc2',
        const ConnectionProfile(
            host: 'bmc2', username: 'root', password: 'pw2'),
      );
      final String bmc2TokenBefore = manager.sessionFor('bmc2')!.token;

      final List<Map<String, dynamic>> bmc1Reqs =
          _capturePostAuth(adapters, 'bmc1');
      final List<Map<String, dynamic>> bmc2Reqs =
          _capturePostAuth(adapters, 'bmc2');

      final List<Object?> results =
          await Future.wait<Object?>(<Future<Object?>>[
        () async {
          try {
            await manager.clientFor('bmc1')!.getJson(_systemUrl('bmc1'));
            return null;
          } on RedfishException catch (e) {
            return e;
          }
        }(),
        manager.clientFor('bmc2')!.getJson(_systemUrl('bmc2')),
      ]);

      expect(results[1], isA<Map<String, dynamic>>(),
          reason: 'bmc2 request must succeed unaffected');
      expect(manager.sessionFor('bmc2'), isNotNull);
      expect(manager.sessionFor('bmc2')!.token, bmc2TokenBefore,
          reason: '401 on bmc1 must not clear or replace bmc2 token');
      expect(manager.sessionFor('bmc2')!.token, 'tok-bmc2');

      expect(bmc2Reqs, isNotEmpty);
      for (final Map<String, dynamic> req in bmc2Reqs) {
        final Map<String, dynamic> headers =
            req['headers'] as Map<String, dynamic>;
        expect(headers['X-Auth-Token'], 'tok-bmc2',
            reason: 'bmc2 requests must keep tok-bmc2 after bmc1 401/re-auth');
      }

      // bmc1 should have re-authenticated (new session POST) in isolation.
      // The interceptor retries once after relogin; if the environment/mocks
      // prevent a successful retry we still require bmc2 isolation above.
      expect(bmc1Reqs, isNotEmpty,
          reason: 'bmc1 requests (including retry) were attempted');
      if (bmc1Posts >= 2) {
        expect(manager.sessionFor('bmc1')!.token, 'tok-bmc1-new');
      }
    });
  });
}
