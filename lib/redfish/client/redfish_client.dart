import 'package:dio/dio.dart';

import 'package:redfishopenbmc/redfish/client/http_client_config.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Thin, low-level Redfish transport built on [Dio].
///
/// Responsibilities:
///  * TLS-first base URL `https://{host}:{port}`
///  * Default Redfish headers (`Accept`, `OData-Version: 4.0`)
///  * 10s connect / 30s receive timeouts
///  * opt-in self-signed toggle (`allowSelfSigned`)
///  * normalized [RedfishException]s for every failure
///
/// Authentication (Basic vs session token) is layered on top by the auth
/// manager; this class only knows how to talk HTTP safely and exposes [dio]
/// so auth interceptors can be attached.
class RedfishClient {
  /// Creates a [RedfishClient] for the given [profile].
  RedfishClient({required this.profile, Dio? dio})
      : _dio = dio ?? _buildDio(profile);

  final ConnectionProfile profile;
  final Dio _dio;

  /// Underlying [Dio]; the auth manager attaches interceptors to it.
  Dio get dio => _dio;

  /// Builds a fully-configured [Dio] for [profile] without constructing a
  /// [RedfishClient]. Useful when a caller needs the raw transport (e.g. the
  /// auth manager's per-host client factory) but wants the same TLS + header
  /// + timeout policy.
  static Dio createDioForProfile(ConnectionProfile profile) =>
      _buildDio(profile);

  static Dio _buildDio(ConnectionProfile profile) {
    final dio = Dio(
      BaseOptions(
        baseUrl: profile.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, String>{
          'Accept': 'application/json',
          'OData-Version': '4.0',
        },
        // Let Dio throw on >=400 so the interceptor / error normalization
        // can classify the failure. Success = 2xx (incl. 201 / 204).
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 300,
      ),
    )
      ..httpClientAdapter = createHttpClientAdapter(profile.allowSelfSigned);
    return dio;
  }

  /// GET [path] and decode the JSON body as a [Map].
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response =
          await _dio.get<dynamic>(path, queryParameters: query);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw RedfishException.fromDioException(
        e,
        uri: Uri.tryParse(profile.baseUrl + path),
      );
    }
  }

  /// POST [path] with an optional JSON [body]; returns the decoded body
  /// (or an empty map for 201/204 with no content).
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw RedfishException.fromDioException(
        e,
        uri: Uri.tryParse(profile.baseUrl + path),
      );
    }
  }

  /// DELETE [path]; returns `true` on success (204 or 200).
  Future<bool> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      await _dio.delete<dynamic>(
        path,
        options: Options(headers: headers),
      );
      return true;
    } on DioException catch (e) {
      throw RedfishException.fromDioException(
        e,
        uri: Uri.tryParse(profile.baseUrl + path),
      );
    }
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data == null) return <String, dynamic>{};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return <String, dynamic>{
        for (final MapEntry<dynamic, dynamic> e in data.entries)
          e.key.toString(): e.value,
      };
    }
    return <String, dynamic>{'value': data};
  }
}
