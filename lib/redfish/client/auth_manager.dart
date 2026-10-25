import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';

/// Authentication strategy in use for a system.
enum _AuthMode { basic, session }

/// Per-system auth state kept inside [AuthManager].
class _SystemAuth {
  _SystemAuth({
    required this.systemId,
    required this.client,
    required this.profile,
    required this.mode,
  });

  final String systemId;
  final RedfishClient client;
  final ConnectionProfile profile;
  final _AuthMode mode;

  Session? session;
  String? basicCredentials;
  // Serializes 401-driven re-auth so concurrent failures don't each hit
  // the login endpoint (a "refresh storm").
  Future<void>? refreshLock;
}

/// Manages authentication + session lifecycle for one or many BMCs.
///
/// Design goals (issue #002):
///  * Supports **Basic** (`Authorization: Basic <b64>`) and **Session**
///    (`POST /SessionService/Sessions` → `X-Auth-Token`) auth.
///  * **Isolation**: each `systemId` keeps its own [Session]; token for
///    `bmc1` is never sent to `bmc2`.
///  * **No plaintext password at rest**: passwords live only in the
///    in-memory [ConnectionProfile]; [SecureStorage] stores the token
///    (session mode) or nothing (basic mode).
///  * **401 refresh**: on a 401 the session is re-created once, guarded by
///    a per-system refresh lock to avoid retry storms.
class AuthManager {
  AuthManager({
    required this.storage,
    RedfishClient Function(ConnectionProfile) createClient = _defaultClient,
  }) : _createClient = createClient;

  final SecureStorage storage;
  final RedfishClient Function(ConnectionProfile) _createClient;

  static RedfishClient _defaultClient(ConnectionProfile p) =>
      RedfishClient(profile: p);

  final Map<String, _SystemAuth> _systems = <String, _SystemAuth>{};

  // --- SecureStorage key helpers -------------------------------------------

  String _tokenKey(String systemId) => 'redfish.token.$systemId';
  String _locationKey(String systemId) => 'redfish.session_loc.$systemId';

  // --- Public API ----------------------------------------------------------

  /// Authenticate [systemId] using [profile].
  ///
  /// Picks session auth when [ConnectionProfile.preferSessionAuth] is true
  /// and credentials are present, otherwise Basic auth. Returns the active
  /// [Session].
  Future<Session> login(String systemId, ConnectionProfile profile) async {
    final RedfishClient client = _createClient(profile);
    final _AuthMode mode = (profile.preferSessionAuth &&
            profile.username != null &&
            profile.password != null)
        ? _AuthMode.session
        : _AuthMode.basic;

    final _SystemAuth auth = _SystemAuth(
      systemId: systemId,
      client: client,
      profile: profile,
      mode: mode,
    );
    _systems[systemId] = auth;

    late final Session session;
    if (mode == _AuthMode.session) {
      session = await _createSession(systemId, auth);
    } else {
      auth.basicCredentials = _basicValue(profile.username, profile.password);
      session = Session(
        systemId: systemId,
        token: auth.basicCredentials!,
        location: '',
        username: profile.username ?? '',
        createdAt: DateTime.now(),
      );
    }
    auth.session = session;
    _installAuthInterceptor(auth);
    return session;
  }

  /// The authenticated [RedfishClient] for [systemId], or `null` if not
  /// logged in. Feature code uses this to issue requests.
  RedfishClient? clientFor(String systemId) => _systems[systemId]?.client;

  /// Runs [action] with the authenticated [RedfishClient] for [systemId].
  ///
  /// Throws a [StateError] if [systemId] has not logged in. The 401
  /// refresh interceptor installed during [login] still applies to any
  /// request issued inside [action], so callers get transparent
  /// re-authentication for free.
  Future<T> withAuth<T>(
    String systemId,
    Future<T> Function(RedfishClient client) action,
  ) async {
    final RedfishClient? client = clientFor(systemId);
    if (client == null) {
      throw StateError('No active session for "$systemId"; call login first.');
    }
    return action(client);
  }

  /// Active [Session] for [systemId], if any.
  Session? sessionFor(String systemId) => _systems[systemId]?.session;

  /// Whether [systemId] currently has a usable session/token.
  bool isAuthenticated(String systemId) => _systems[systemId]?.session != null;

  /// Log out: delete the server-side session (if any) and purge the stored
  /// token. Best-effort — network errors during `DELETE` are ignored.
  Future<void> logout(String systemId) async {
    final _SystemAuth? auth = _systems[systemId];
    if (auth == null) return;

    if (auth.mode == _AuthMode.session &&
        auth.session != null &&
        auth.session!.location.isNotEmpty) {
      try {
        await auth.client.dio.delete<dynamic>(
          auth.session!.location,
          options: Options(headers: <String, String>{
            'X-Auth-Token': auth.session!.token,
          }),
        );
      } on DioException {
        // best-effort cleanup; ignore
      }
    }
    await storage.delete(_tokenKey(systemId));
    await storage.delete(_locationKey(systemId));
    _systems.remove(systemId);
  }

  /// Drop every session (e.g. app backgrounding). Does not contact servers.
  Future<void> logoutAll() async {
    final List<String> ids = _systems.keys.toList();
    for (final String id in ids) {
      await logout(id);
    }
  }

  // --- Internals -----------------------------------------------------------

  Future<Session> _createSession(String systemId, _SystemAuth auth) async {
    final ConnectionProfile profile = auth.profile;
    try {
      final Response<dynamic> response = await auth.client.dio.post<dynamic>(
        '/redfish/v1/SessionService/Sessions',
        data: <String, String>{
          'UserName': profile.username ?? '',
          'Password': profile.password ?? '',
        },
      );

      final String? token = response.headers.value('X-Auth-Token') ??
          response.headers.value('x-auth-token');
      final String? location = response.headers.value('Location') ??
          response.headers.value('Content-Location');

      if (token == null || token.isEmpty) {
        throw const RedfishException(
          message: 'Session login returned no X-Auth-Token',
        );
      }

      final Session session = Session(
        systemId: systemId,
        token: token,
        location: location ?? '/redfish/v1/SessionService/Sessions',
        username: profile.username ?? '',
        createdAt: DateTime.now(),
      );

      // Persist ONLY the token — never the password.
      await storage.write(_tokenKey(systemId), token);
      if (location != null && location.isNotEmpty) {
        await storage.write(_locationKey(systemId), location);
      }
      return session;
    } on DioException catch (e) {
      throw RedfishException.fromDioException(e);
    }
  }

  /// Re-create the session after a 401. Guarded by the caller's refresh lock
  /// and by the interceptor (the login POST itself never triggers a retry).
  Future<Session> _relogin(String systemId, _SystemAuth auth) async {
    if (auth.mode == _AuthMode.session &&
        auth.session != null &&
        auth.session!.location.isNotEmpty) {
      try {
        await auth.client.dio.delete<dynamic>(
          auth.session!.location,
          options: Options(headers: <String, String>{
            'X-Auth-Token': auth.session!.token,
          }),
        );
      } on DioException {
        // ignore — old session is dead anyway
      }
    }
    auth.session = null;
    final Session newSession = await _createSession(systemId, auth);
    auth.session = newSession;
    return newSession;
  }

  void _installAuthInterceptor(_SystemAuth auth) {
    auth.client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (auth.mode == _AuthMode.basic) {
            final String? basic = auth.basicCredentials;
            if (basic != null) {
              options.headers['Authorization'] = basic;
            }
          } else {
            final Session? session = auth.session;
            if (session != null) {
              options.headers['X-Auth-Token'] = session.token;
            }
          }
          handler.next(options);
        },
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          // Only session auth supports transparent refresh.
          if (auth.mode != _AuthMode.session) return handler.next(err);
          if (err.response?.statusCode != 401) return handler.next(err);

          final RequestOptions opts = err.requestOptions;
          // The login POST itself failed → do not loop.
          if (opts.path.endsWith('/SessionService/Sessions') &&
              opts.method.toUpperCase() == 'POST') {
            return handler.next(err);
          }
          // Already retried once for this request.
          if (opts.extra['_retried'] == true) return handler.next(err);

          // Serialize re-auth across concurrent 401s for this system so we
          // don't hammer the login endpoint (refresh storm).
          if (auth.refreshLock != null) {
            await auth.refreshLock;
            if (auth.session != null) {
              opts.extra['_retried'] = true;
              opts.headers['X-Auth-Token'] = auth.session!.token;
              try {
                final Response<dynamic> result =
                    await auth.client.dio.fetch<dynamic>(opts);
                return handler.resolve(result);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
            return handler.next(err);
          }

          final Completer<void> completer = Completer<void>();
          auth.refreshLock = completer.future;
          try {
            final Session newSession = await _relogin(auth.systemId, auth);
            opts.extra['_retried'] = true;
            opts.headers['X-Auth-Token'] = newSession.token;
            final Response<dynamic> result =
                await auth.client.dio.fetch<dynamic>(opts);
            return handler.resolve(result);
          } on DioException catch (e) {
            return handler.next(e);
          } finally {
            auth.refreshLock = null;
            completer.complete();
          }
        },
      ),
    );
  }

  static String _basicValue(String? username, String? password) {
    final String merged = '${username ?? ''}:${password ?? ''}';
    return 'Basic ${base64Encode(utf8.encode(merged))}';
  }
}
