import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/redfish/client/auth_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';

/// Matches a mocked request by **path only** (relative to the Dio base URL).
/// Unlike the library's [UrlRequestMatcher] this deliberately ignores the
/// request body/headers, which is required because every `SessionService`
/// POST carries a body that would otherwise make the mock not match.
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

/// JSON content-type header required whenever [MockServer.reply] is called
/// with a `headers` override (otherwise the default is dropped and the Map
/// body can't be JSON-encoded -> a cast error).
const Map<String, List<String>> _jsonContentType = <String, List<String>>{
  Headers.contentTypeHeader: [Headers.jsonContentType],
};

String _sessionsUrl(String host) => '/redfish/v1/SessionService/Sessions';
String _rootUrl(String host) => '/redfish/v1/';
String _sessionLocUrl(String host, String id) =>
    '/redfish/v1/SessionService/Sessions/$id';
String _systemUrl(String host) => '/redfish/v1/Systems/437XR1138R2';

/// Builds an [AuthManager] with a **pre-created** per-host [Dio]+[DioAdapter]
/// so mocks can be registered before `login`. The same adapter is reused by
/// the client the auth manager creates, giving real per-system isolation.
(AuthManager, Map<String, DioAdapter>, List<Map<String, dynamic>>)
    buildManager() {
  final Map<String, DioAdapter> adapters = <String, DioAdapter>{};
  final List<Map<String, dynamic>> captured = <Map<String, dynamic>>[];

  DioAdapter adapterFor(String host) => adapters.putIfAbsent(host, () {
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://$host:443'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest:
                (RequestOptions options, RequestInterceptorHandler handler) {
              captured.add(Map<String, dynamic>.from(options.headers));
              handler.next(options);
            },
          ),
        );
        return DioAdapter(
          dio: dio,
          matcher: const _PathMatcher(),
        );
      });

  adapterFor('bmc1');
  adapterFor('bmc2');

  final AuthManager manager = AuthManager(
    storage: InMemoryStorage(),
    createClient: (ConnectionProfile p) =>
        RedfishClient(profile: p, dio: adapterFor(p.host).dio),
  );

  return (manager, adapters, captured);
}

/// Adds a post-auth capturing interceptor to [host]'s dio and returns the
/// list it fills. The pre-auth [captured] list can't see auth headers (the
/// capture interceptor runs before the auth interceptor), so this is how we
/// assert on the actually-sent `X-Auth-Token` / `Authorization`.
List<Map<String, dynamic>> capturePostAuth(
  Map<String, DioAdapter> adapters,
  String host,
) {
  final List<Map<String, dynamic>> list = <Map<String, dynamic>>[];
  adapters[host]!.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        list.add(Map<String, dynamic>.from(options.headers));
        handler.next(options);
      },
    ),
  );
  return list;
}

void mockSessionLogin(
  DioAdapter adapter,
  String host, {
  required String token,
  required String locationId,
}) {
  adapter.onPost(
    _sessionsUrl(host),
    (server) => server.reply(
      201,
      <String, dynamic>{},
      headers: <String, List<String>>{
        ..._jsonContentType,
        'X-Auth-Token': [token],
        'Location': ['/redfish/v1/SessionService/Sessions/$locationId'],
      },
    ),
  );
  adapter.onGet(
    _rootUrl(host),
    (server) => server.reply(
      200,
      <String, dynamic>{'@odata.id': _rootUrl(host)},
    ),
  );
}

void main() {
  group('AuthManager - session auth', () {
    test('login captures X-Auth-Token + Location and stores only token',
        () async {
      final (
        AuthManager manager,
        Map<String, DioAdapter> adapters,
        List<Map<String, dynamic>> captured
      ) = buildManager();
      mockSessionLogin(adapters['bmc1']!, 'bmc1',
          token: 'tok-abc', locationId: '42');

      final Session session = await manager.login(
        'bmc1',
        const ConnectionProfile(
          host: 'bmc1',
          username: 'root',
          password: 'calvin',
        ),
      );

      expect(session.token, 'tok-abc');
      expect(session.location, '/redfish/v1/SessionService/Sessions/42');
      expect(manager.isAuthenticated('bmc1'), isTrue);

      final List<Map<String, dynamic>> postAuth =
          capturePostAuth(adapters, 'bmc1');
      final Map<String, dynamic> root =
          await manager.clientFor('bmc1')!.getJson('/redfish/v1/');
      expect(root['@odata.id'], _rootUrl('bmc1'));
      expect(postAuth.last['X-Auth-Token'], 'tok-abc');
    });

    test(
        '401 triggers exactly one session re-create (no loop) and updates '
        'the session', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();
      int postCount = 0;
      adapters['bmc1']!.onPost(
        _sessionsUrl('bmc1'),
        (server) {
          postCount++;
          return server.reply(
            201,
            <String, dynamic>{},
            headers: <String, List<String>>{
              ..._jsonContentType,
              'X-Auth-Token': ['tok-new'],
              'Location': ['/redfish/v1/SessionService/Sessions/7'],
            },
          );
        },
      );
      adapters['bmc1']!.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(401, <String, dynamic>{}),
      );

      await manager.login(
        'bmc1',
        const ConnectionProfile(
          host: 'bmc1',
          username: 'root',
          password: 'calvin',
        ),
      );

      late RedfishException thrown;
      try {
        await manager.clientFor('bmc1')!.getJson('/redfish/v1/');
      } on RedfishException catch (e) {
        thrown = e;
      }
      expect(thrown, isA<RedfishException>());
      expect(thrown.statusCode, 401);
      expect(postCount, 1, reason: 'exactly one relogin, no retry storm');
      expect(manager.sessionFor('bmc1')!.token, 'tok-new',
          reason: 'session was refreshed with the new token');
    });

    test('concurrent 401s share a single refresh (no storm)', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();
      int postCount = 0;
      adapters['bmc1']!.onPost(
        _sessionsUrl('bmc1'),
        (server) {
          postCount++;
          return server.reply(
            201,
            <String, dynamic>{},
            headers: <String, List<String>>{
              ..._jsonContentType,
              'X-Auth-Token': ['tok-storm'],
              'Location': ['/redfish/v1/SessionService/Sessions/99'],
            },
          );
        },
      );
      adapters['bmc1']!.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(401, <String, dynamic>{}),
      );

      await manager.login(
        'bmc1',
        const ConnectionProfile(
          host: 'bmc1',
          username: 'root',
          password: 'calvin',
        ),
      );

      Future<Object> one() async {
        try {
          await manager.clientFor('bmc1')!.getJson('/redfish/v1/');
          return 'ok';
        } on RedfishException catch (e) {
          return e;
        }
      }

      final List<Object> results = await Future.wait<Object>([one(), one()]);

      expect(results.length, 2);
      expect(postCount, 1, reason: 'refresh lock serialized re-auth');
    });

    test('a failing re-login (401 on POST) does not loop', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();
      adapters['bmc1']!.onPost(
        _sessionsUrl('bmc1'),
        (server) => server.reply(
          401,
          <String, dynamic>{'Message': 'bad credentials'},
        ),
      );

      late RedfishException thrown;
      try {
        await manager.login(
          'bmc1',
          const ConnectionProfile(
            host: 'bmc1',
            username: 'root',
            password: 'wrong',
          ),
        );
      } on RedfishException catch (e) {
        thrown = e;
      }
      expect(thrown, isA<RedfishException>());
      expect(thrown.statusCode, 401);
    });

    test('logout deletes server session and clears storage', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();
      bool deleted = false;
      mockSessionLogin(adapters['bmc1']!, 'bmc1',
          token: 'tok-x', locationId: '9');
      adapters['bmc1']!.onDelete(
        _sessionLocUrl('bmc1', '9'),
        (server) {
          deleted = true;
          return server.reply(204, <String, dynamic>{});
        },
      );

      await manager.login(
        'bmc1',
        const ConnectionProfile(
          host: 'bmc1',
          username: 'root',
          password: 'calvin',
        ),
      );
      await manager.logout('bmc1');

      expect(deleted, isTrue);
      expect(manager.isAuthenticated('bmc1'), isFalse);
      expect(manager.clientFor('bmc1'), isNull);
      expect(manager.sessionFor('bmc1'), isNull);
    });

    test('logoutAll purges every system', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();
      mockSessionLogin(adapters['bmc1']!, 'bmc1',
          token: 'tok-1', locationId: '1');
      mockSessionLogin(adapters['bmc2']!, 'bmc2',
          token: 'tok-2', locationId: '2');
      adapters['bmc1']!.onDelete(
        _sessionLocUrl('bmc1', '1'),
        (server) => server.reply(204, <String, dynamic>{}),
      );
      adapters['bmc2']!.onDelete(
        _sessionLocUrl('bmc2', '2'),
        (server) => server.reply(204, <String, dynamic>{}),
      );

      await manager.login('bmc1',
          const ConnectionProfile(host: 'bmc1', username: 'u', password: 'p'));
      await manager.login('bmc2',
          const ConnectionProfile(host: 'bmc2', username: 'u', password: 'p'));
      await manager.logoutAll();

      expect(manager.isAuthenticated('bmc1'), isFalse);
      expect(manager.isAuthenticated('bmc2'), isFalse);
    });
  });

  group('AuthManager - Basic auth', () {
    test('uses Authorization header, no server session, no stored token',
        () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();
      adapters['bmc1']!.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(
          200,
          <String, dynamic>{'@odata.id': _rootUrl('bmc1')},
        ),
      );

      final Session session = await manager.login(
        'bmc1',
        const ConnectionProfile(
          host: 'bmc1',
          preferSessionAuth: false,
          username: 'root',
          password: 'calvin',
        ),
      );

      expect(session.token, startsWith('Basic '));
      expect(session.location, isEmpty);
      expect(manager.isAuthenticated('bmc1'), isTrue);

      final List<Map<String, dynamic>> postAuth =
          capturePostAuth(adapters, 'bmc1');
      await manager.clientFor('bmc1')!.getJson('/redfish/v1/');
      expect(postAuth.last['Authorization'], startsWith('Basic '));
      expect(postAuth.last['X-Auth-Token'], isNull);
    });

    test('falls back to Basic when credentials are absent', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();
      adapters['bmc1']!.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(
          200,
          <String, dynamic>{'@odata.id': _rootUrl('bmc1')},
        ),
      );
      final Session session = await manager.login(
        'bmc1',
        const ConnectionProfile(host: 'bmc1', preferSessionAuth: true),
      );
      expect(session.token, startsWith('Basic '));
    });
  });

  group('AuthManager - per-system isolation', () {
    test('tokens for bmc1 and bmc2 never cross', () async {
      final (AuthManager manager, Map<String, DioAdapter> adapters, _) =
          buildManager();

      adapters['bmc1']!.onPost(
        _sessionsUrl('bmc1'),
        (server) => server.reply(
          201,
          <String, dynamic>{},
          headers: <String, List<String>>{
            ..._jsonContentType,
            'X-Auth-Token': ['tok-1'],
            'Location': ['/redfish/v1/SessionService/Sessions/1'],
          },
        ),
      );
      adapters['bmc2']!.onPost(
        _sessionsUrl('bmc2'),
        (server) => server.reply(
          201,
          <String, dynamic>{},
          headers: <String, List<String>>{
            ..._jsonContentType,
            'X-Auth-Token': ['tok-2'],
            'Location': ['/redfish/v1/SessionService/Sessions/2'],
          },
        ),
      );
      adapters['bmc1']!.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(
          200,
          <String, dynamic>{'@odata.id': _rootUrl('bmc1')},
        ),
      );
      adapters['bmc2']!.onGet(
        _rootUrl('bmc2'),
        (server) => server.reply(
          200,
          <String, dynamic>{'@odata.id': _rootUrl('bmc2')},
        ),
      );

      await manager.login(
          'bmc1',
          const ConnectionProfile(
              host: 'bmc1', username: 'root', password: 'pw1'));
      await manager.login(
          'bmc2',
          const ConnectionProfile(
              host: 'bmc2', username: 'root', password: 'pw2'));

      final List<Map<String, dynamic>> c1 = capturePostAuth(adapters, 'bmc1');
      final List<Map<String, dynamic>> c2 = capturePostAuth(adapters, 'bmc2');
      await manager.clientFor('bmc1')!.getJson('/redfish/v1/');
      await manager.clientFor('bmc2')!.getJson('/redfish/v1/');

      expect(c1.last['X-Auth-Token'], 'tok-1');
      expect(c2.last['X-Auth-Token'], 'tok-2');
    });

    test('clientFor/sessionFor return null before login', () {
      final (AuthManager manager, _, _) = buildManager();
      expect(manager.clientFor('nope'), isNull);
      expect(manager.sessionFor('nope'), isNull);
      expect(manager.isAuthenticated('nope'), isFalse);
    });
  });

  group('RedfishException normalization', () {
    test('certificate errors are fatal (not retryable)', () {
      final RedfishException e = RedfishException.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.badCertificate,
          message: 'self signed',
        ),
      );
      expect(e.errorCode, 'CertificateError');
      expect(e.retryable, isFalse);
    });

    test('connection errors are retryable', () {
      final RedfishException e = RedfishException.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
          message: 'refused',
        ),
      );
      expect(e.retryable, isTrue);
      expect(e.errorCode, isNull);
    });

    test('timeouts are retryable', () {
      for (final DioExceptionType t in <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final RedfishException e = RedfishException.fromDioException(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: t,
            message: 'slow',
          ),
        );
        expect(e.retryable, isTrue, reason: t.toString());
      }
    });

    test('cancelled requests are non-retryable', () {
      final RedfishException e = RedfishException.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.cancel,
          message: 'stop',
        ),
      );
      expect(e.retryable, isFalse);
    });

    test('unknown transport errors are non-retryable', () {
      final RedfishException e = RedfishException.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.unknown,
          message: 'weird',
        ),
      );
      expect(e.retryable, isFalse);
      expect(e.message, contains('weird'));
    });

    test('structured RedfishError envelope is captured from body', () {
      final Response<dynamic> resp = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 500,
        data: <String, dynamic>{
          'code': 'Base.1.8.GeneralError',
          'Message': 'An error occurred',
          '@Message.ExtendedInfo': <dynamic>[
            'Power limit exceeded',
          ],
        },
      );
      final RedfishException e = RedfishException.fromResponse(resp);
      expect(e.hasDetails, isTrue);
      expect(e.details!.code, 'Base.1.8.GeneralError');
      expect(e.details!.message, 'An error occurred');
      expect(e.details!.extendedInfo, contains('Power limit exceeded'));
    });

    test('DSP0266 error envelope yields real extendedInfo diagnostics', () {
      // Spec-conformant BMC: body nests under `error` and
      // `@Message.ExtendedInfo` carries per-property diagnostics.
      final Response<dynamic> resp = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 400,
        data: <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'Base.1.8.PropertyValueTypeError',
            'message': 'The value 42 for the property AssetTag is of a '
                'different type than the property can accept.',
            '@Message.ExtendedInfo': <dynamic>[
              <String, dynamic>{
                '@odata.type': '#Message.v1_1_2.Message',
                'MessageId': 'Base.1.8.PropertyValueTypeError',
                'Message': 'The value 42 for the property AssetTag is of a '
                    'different type than the property can accept.',
                'Severity': 'Warning',
              },
            ],
          },
        },
      );
      final RedfishException e = RedfishException.fromResponse(resp);
      expect(e.hasDetails, isTrue, reason: 'details must parse under error');
      expect(e.statusCode, 400);
      expect(e.details!.code, 'Base.1.8.PropertyValueTypeError');
      expect(e.details!.extendedInfo, isNotNull);
      expect(e.details!.extendedInfo!.single, contains('AssetTag'));
      expect(
        e.details!.firstMessage,
        contains('different type'),
        reason: 'firstMessage prefers ExtendedInfo[0].Message',
      );
    });

    test('5xx responses are retryable, 4xx are not', () {
      final Response<dynamic> resp500 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 503,
        data: <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'Base.1.8.GeneralError',
            'message': 'busy',
          },
        },
      );
      final RedfishException e500 = RedfishException.fromResponse(resp500);
      expect(e500.statusCode, 503);
      expect(e500.errorCode, 'Base.1.8.GeneralError');
      expect(e500.retryable, isTrue);

      final Response<dynamic> resp403 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 403,
        data: <String, dynamic>{'Message': 'forbidden'},
      );
      final RedfishException e403 = RedfishException.fromResponse(resp403);
      expect(e403.retryable, isFalse);
      expect(e403.message, 'forbidden');
      expect(e403.isPreconditionFailed, isFalse,
          reason: '#016: only 412 identifies a stale optimistic-concurrency '
              'token; ordinary 4xx are not precondition failures');

      final Response<dynamic> respPlain = Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 404,
        data: <dynamic, dynamic>{
          'Message': 'gone',
          'Code': 'Base.1.0.GeneralError'
        },
      );
      final RedfishException ePlain = RedfishException.fromResponse(respPlain);
      expect(ePlain.statusCode, 404);
      expect(ePlain.errorCode, 'Base.1.0.GeneralError');
      expect(ePlain.message, 'gone');
    });

    test(
        '501 Not Implemented for unsupported query params is non-retryable '
        '(DSP0266 §7.3.1, row 923)', () {
      // A spec-conformant service answers an unsupported `$`-prefixed query
      // parameter with 501 + a Redfish error envelope naming the parameter.
      // That is a *permanent* capability signal (the service does not
      // implement the query parameter), so re-issuing the identical request
      // cannot succeed — the #018 discovery pass must gate the query instead
      // of retrying it.
      final Response<dynamic> resp501 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/redfish/v1/Systems?%24weird=1'),
        statusCode: 501,
        data: <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'Base.1.0.QueryNotSupported',
            'message': 'Querying is not supported by the implementation.',
            '@Message.ExtendedInfo': <dynamic>[
              <String, dynamic>{
                '@odata.type': '#Message.v1_1_2.Message',
                'MessageId': 'Base.1.0.QueryNotSupported',
                'Message': 'Querying is not supported by the implementation.',
                'Severity': 'Warning',
              },
            ],
          },
        },
      );
      final RedfishException e = RedfishException.fromResponse(resp501);
      expect(e.statusCode, 501);
      expect(e.errorCode, 'Base.1.0.QueryNotSupported');
      expect(e.hasDetails, isTrue);
      expect(
        e.details!.code,
        'Base.1.0.QueryNotSupported',
        reason: 'the normalized error carries the registry code',
      );
      expect(e.retryable, isFalse,
          reason: '501 = permanent "not implemented", never retryable');
    });

    test(
        '400 QueryNotSupportedOnResource is non-retryable and keeps the '
        'registry code (DSP0266 §7.3.1, row 923)', () {
      // Implemented-but-unsupported-on-resource query parameters are a 400
      // with the QueryNotSupportedOnResource registry message (mirrored
      // `Base.1.24.0.json`): the client must not retry, it must adjust the
      // request shape (e.g. drop the query for that resource).
      final Response<dynamic> resp400 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/redfish/v1/Systems/1'),
        statusCode: 400,
        data: <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'Base.1.0.QueryNotSupportedOnResource',
            'message': 'Querying is not supported on the requested resource.',
            '@Message.ExtendedInfo': <dynamic>[
              <String, dynamic>{
                '@odata.type': '#Message.v1_1_2.Message',
                'MessageId': 'Base.1.0.QueryNotSupportedOnResource',
                'Message':
                    'Querying is not supported on the requested resource.',
                'Severity': 'Warning',
              },
            ],
          },
        },
      );
      final RedfishException e = RedfishException.fromResponse(resp400);
      expect(e.statusCode, 400);
      expect(e.errorCode, 'Base.1.0.QueryNotSupportedOnResource');
      expect(e.retryable, isFalse);
      expect(e.details!.firstMessage,
          contains('not supported on the requested resource'));
    });
  });

  group('RedfishClient transports', () {
    Future<(RedfishClient, DioAdapter)> clientFor(String host) async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://$host:443'));
      final DioAdapter adapter = DioAdapter(
        dio: dio,
        matcher: const _PathMatcher(),
      );
      return (
        RedfishClient(profile: ConnectionProfile(host: host), dio: dio),
        adapter
      );
    }

    test('getJson success returns decoded map', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(200, <String, dynamic>{'a': 1}),
      );
      final Map<String, dynamic> body = await client.getJson('/redfish/v1/');
      expect(body['a'], 1);
    });

    test('getJson with no content returns empty map', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(200, null),
      );
      final Map<String, dynamic> body = await client.getJson('/redfish/v1/');
      expect(body, isEmpty);
    });

    test('getJson with non-map body wraps into {"value"}', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(200, 'plain string'),
      );
      final Map<String, dynamic> body = await client.getJson('/redfish/v1/');
      expect(body['value'], 'plain string');
    });

    test('postJson success returns decoded body', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onPost(
        _sessionsUrl('bmc1'),
        (server) => server.reply(
          201,
          <String, dynamic>{'ok': true},
          headers: <String, List<String>>{
            ..._jsonContentType,
            'X-Auth-Token': ['t'],
            'Location': ['/redfish/v1/SessionService/Sessions/1'],
          },
        ),
      );
      final Map<String, dynamic> body = await client.postJson(
        '/redfish/v1/SessionService/Sessions',
        body: <String, String>{'UserName': 'u', 'Password': 'p'},
      );
      expect(body['ok'], isTrue);
    });

    test('delete success returns true', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onDelete(
        _sessionLocUrl('bmc1', '1'),
        (server) => server.reply(204, <String, dynamic>{}),
      );
      expect(
          await client.delete('/redfish/v1/SessionService/Sessions/1'), isTrue);
    });

    test('delete non-2xx throws RedfishException', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onDelete(
        _sessionLocUrl('bmc1', '1'),
        (server) => server.reply(500, <String, dynamic>{}),
      );
      late RedfishException thrown;
      try {
        await client.delete('/redfish/v1/SessionService/Sessions/1');
      } on RedfishException catch (e) {
        thrown = e;
      }
      expect(thrown.statusCode, 500);
    });

    test('postJson non-2xx throws RedfishException', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onPost(
        _sessionsUrl('bmc1'),
        (server) => server.reply(
          401,
          <String, dynamic>{'Message': 'nope'},
        ),
      );
      late RedfishException thrown;
      try {
        await client.postJson(
          '/redfish/v1/SessionService/Sessions',
          body: <String, String>{'UserName': 'u'},
        );
      } on RedfishException catch (e) {
        thrown = e;
      }
      expect(thrown.statusCode, 401);
    });

    test('patchJson 204 no-content returns empty map (#016)', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onPatch(
        _systemUrl('bmc1'),
        (server) => server.reply(204, <String, dynamic>{}),
      );
      final Map<String, dynamic> body = await client.patchJson(
        _systemUrl('bmc1'),
        body: <String, dynamic>{
          'Boot': <String, dynamic>{'BootSourceOverrideEnabled': 'Disabled'},
        },
      );
      expect(body, isEmpty);
    });

    test('patchJson 200 with body decodes to a map (#016)', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onPatch(
        _systemUrl('bmc1'),
        (server) => server.reply(
          200,
          <String, dynamic>{'IndicatorLED': 'Blinking'},
        ),
      );
      final Map<String, dynamic> body = await client.patchJson(
        _systemUrl('bmc1'),
        body: <String, dynamic>{'IndicatorLED': 'Blinking'},
      );
      expect(body['IndicatorLED'], 'Blinking');
    });

    test('patchJson non-2xx throws RedfishException (#016)', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onPatch(
        _systemUrl('bmc1'),
        (server) => server.reply(
          405,
          <String, dynamic>{'Message': 'method not allowed'},
        ),
      );
      late RedfishException thrown;
      try {
        await client.patchJson(
          _systemUrl('bmc1'),
          body: <String, dynamic>{'IndicatorLED': 'Off'},
        );
      } on RedfishException catch (e) {
        thrown = e;
      }
      expect(thrown.statusCode, 405);
    });

    test('patchJson with etag sends quoted If-Match header (#016)', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      final List<Map<String, dynamic>> captured = <Map<String, dynamic>>[];
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
            captured.add(Map<String, dynamic>.from(options.headers));
            handler.next(options);
          },
        ),
      );
      adapter.onPatch(
        _systemUrl('bmc1'),
        (server) => server.reply(204, <String, dynamic>{}),
      );
      await client.patchJson(
        _systemUrl('bmc1'),
        body: <String, dynamic>{'IndicatorLED': 'Blinking'},
        etag: '9234ac83b9700123cc32',
      );
      expect(captured, hasLength(1));
      expect(captured.single['If-Match'], '"9234ac83b9700123cc32"',
          reason: 'RFC7232 entity-tag: an unquoted @odata.etag must be '
              'quoted before it is sent in If-Match');
    });

    test('patchJson with etag keeps weak/pre-quoted tags verbatim (#016)',
        () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      final List<Map<String, dynamic>> captured = <Map<String, dynamic>>[];
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
            captured.add(Map<String, dynamic>.from(options.headers));
            handler.next(options);
          },
        ),
      );
      adapter.onPatch(
        _systemUrl('bmc1'),
        (server) => server.reply(204, <String, dynamic>{}),
      );
      await client.patchJson(
        _systemUrl('bmc1'),
        etag: 'W/"v1"',
      );
      await client.patchJson(
        _systemUrl('bmc1'),
        etag: '"already-quoted"',
      );
      expect(captured, hasLength(2));
      expect(captured[0]['If-Match'], 'W/"v1"');
      expect(captured[1]['If-Match'], '"already-quoted"');
    });

    test('patchJson If-Match from etag wins over headers (#016)', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      final List<Map<String, dynamic>> captured = <Map<String, dynamic>>[];
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
            captured.add(Map<String, dynamic>.from(options.headers));
            handler.next(options);
          },
        ),
      );
      adapter.onPatch(
        _systemUrl('bmc1'),
        (server) => server.reply(204, <String, dynamic>{}),
      );
      await client.patchJson(
        _systemUrl('bmc1'),
        headers: <String, String>{'If-Match': '"stale"'},
        etag: 'fresh',
      );
      expect(captured.single['If-Match'], '"fresh"');
    });

    test('patchJson 412 throws precondition failure RedfishException (#016)',
        () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onPatch(
        _systemUrl('bmc1'),
        (server) => server.reply(
          412,
          <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'Base.1.0.PreconditionFailed',
              'message': 'The ETag supplied did not match the current ETag.',
            },
          },
        ),
      );
      late RedfishException thrown;
      try {
        await client.patchJson(
          _systemUrl('bmc1'),
          body: <String, dynamic>{'IndicatorLED': 'Blinking'},
          etag: 'stale-tag',
        );
      } on RedfishException catch (e) {
        thrown = e;
      }
      expect(thrown.statusCode, 412);
      expect(thrown.isPreconditionFailed, isTrue,
          reason: '#016: a stale optimistic-concurrency token surfaces as a '
              '412 the caller can distinguish from other 4xx failures');
      expect(thrown.retryable, isFalse,
          reason: 'retrying the identical request with the same stale tag '
              'cannot succeed (#016: re-fetch @odata.etag, then retry)');
    });

    test('quoteEntityTag grammar helper (#016)', () {
      expect(RedfishClient.quoteEntityTag('abc'), '"abc"');
      expect(RedfishClient.quoteEntityTag('"abc"'), '"abc"');
      expect(RedfishClient.quoteEntityTag('W/"v1"'), 'W/"v1"');
      expect(RedfishClient.quoteEntityTag('w/"v1"'), 'W/"v1"');
      expect(RedfishClient.quoteEntityTag('W/ abc'), 'W/"abc"');
      expect(RedfishClient.quoteEntityTag(' a"b '), '"ab"');
      expect(RedfishClient.quoteEntityTag(''), '""');
    });

    test('builds its own Dio from profile (default transport + TLS-first)',
        () async {
      final RedfishClient client =
          RedfishClient(profile: const ConnectionProfile(host: 'bmc1'));
      final DioAdapter adapter =
          DioAdapter(dio: client.dio, matcher: const _PathMatcher());
      adapter.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(200, <String, dynamic>{'a': 1}),
      );
      final Map<String, dynamic> body = await client.getJson('/redfish/v1/');
      expect(body['a'], 1);
    });

    test('non-2xx GET throws RedfishException', () async {
      final (RedfishClient client, DioAdapter adapter) =
          await clientFor('bmc1');
      adapter.onGet(
        _rootUrl('bmc1'),
        (server) => server.reply(
          500,
          <String, dynamic>{'Message': 'internal'},
        ),
      );
      late RedfishException thrown;
      try {
        await client.getJson('/redfish/v1/');
      } on RedfishException catch (e) {
        thrown = e;
      }
      expect(thrown.statusCode, 500);
      expect(thrown.retryable, isTrue);
    });
  });
}
