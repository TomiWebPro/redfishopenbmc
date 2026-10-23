import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/redfish/client/auth_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';

/// JSON content-type header required whenever [MockServer.reply] is called
/// with a `headers` override (otherwise the Map body can't be JSON-encoded).
const Map<String, List<String>> _jsonContentType = <String, List<String>>{
  Headers.contentTypeHeader: [Headers.jsonContentType],
};

/// Matches a mocked request by path only (relative to the Dio base URL),
/// ignoring body/headers. Mirrors the helper in `auth_manager_test.dart`.
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

/// Exercises the `createDioForProfile` factory and the [AuthManager.withAuth]
/// convenience wrapper.
void main() {
  group('RedfishClient.createDioForProfile', () {
    test('builds a Dio with TLS-first base url + Redfish headers + timeouts',
        () {
      final Dio dio = RedfishClient.createDioForProfile(
        const ConnectionProfile(host: 'bmc1', port: 8443),
      );
      expect(dio.options.baseUrl, 'https://bmc1:8443');
      expect(dio.options.headers['Accept'], 'application/json');
      expect(dio.options.headers['OData-Version'], '4.0');
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 30));
    });

    test('respects the strict validateStatus (2xx only)', () {
      final Dio dio = RedfishClient.createDioForProfile(
        const ConnectionProfile(host: 'bmc1'),
      );
      final ValidateStatus validate = dio.options.validateStatus;
      expect(validate(200), isTrue);
      expect(validate(204), isTrue);
      expect(validate(401), isFalse);
      expect(validate(500), isFalse);
    });
  });

  group('RedfishClient.getJson query parameters', () {
    test('forwards the query map to the wire as queryParameters (DSP0266 §7.3)',
        () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://bmc1:443'));
      final DioAdapter adapter =
          DioAdapter(dio: dio, matcher: const _PathMatcher());
      final List<RequestOptions> seen = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
            seen.add(options);
            handler.next(options);
          },
        ),
      );
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(
          200,
          <String, dynamic>{'Members': <dynamic>[]},
          headers: _jsonContentType,
        ),
      );
      final RedfishClient client = RedfishClient(
          profile: const ConnectionProfile(host: 'bmc1'), dio: dio);
      final Map<String, dynamic> body = await client.getJson(
        '/redfish/v1/Systems',
        query: <String, dynamic>{r'$expand': r'.($levels=1)'},
      );
      expect(body, <String, dynamic>{'Members': <dynamic>[]});
      expect(seen, hasLength(1));
      expect(seen.single.queryParameters,
          <String, dynamic>{r'$expand': r'.($levels=1)'});
    });
  });

  group('AuthManager.withAuth', () {
    test('throws StateError when the system never logged in', () {
      final AuthManager manager = AuthManager(storage: InMemoryStorage());
      expect(
        () => manager.withAuth<dynamic>('nope', (_) async => null),
        throwsA(isA<StateError>()),
      );
    });

    test('runs the action with the authenticated client (session token)',
        () async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://bmc1:443'));
      final DioAdapter adapter =
          DioAdapter(dio: dio, matcher: const _PathMatcher());
      adapter.onPost(
        '/redfish/v1/SessionService/Sessions',
        (server) => server.reply(
          201,
          <String, dynamic>{},
          headers: <String, List<String>>{
            ..._jsonContentType,
            'X-Auth-Token': ['tok-extra'],
            'Location': ['/redfish/v1/SessionService/Sessions/1'],
          },
        ),
      );
      adapter.onGet(
        '/redfish/v1/',
        (server) => server.reply(
          200,
          <String, dynamic>{'@odata.id': '/x'},
          headers: _jsonContentType,
        ),
      );
      final AuthManager manager = AuthManager(
        storage: InMemoryStorage(),
        createClient: (ConnectionProfile p) =>
            RedfishClient(profile: p, dio: dio),
      );
      await manager.login(
        'bmc1',
        const ConnectionProfile(
          host: 'bmc1',
          username: 'root',
          password: 'calvin',
        ),
      );

      final List<Map<String, dynamic>> seen = <Map<String, dynamic>>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
            seen.add(Map<String, dynamic>.from(options.headers));
            handler.next(options);
          },
        ),
      );

      final String result = await manager.withAuth<String>(
        'bmc1',
        (RedfishClient client) async {
          expect(client, same(manager.clientFor('bmc1')));
          await client.getJson('/redfish/v1/');
          return 'done';
        },
      );
      expect(result, 'done');
      expect(seen, isNotEmpty);
      expect(seen.first['X-Auth-Token'], isNotNull);
    });
  });
}
