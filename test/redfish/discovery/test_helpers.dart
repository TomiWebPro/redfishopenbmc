import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';

/// Loads a JSON fixture from `test/fixtures/redfish/<name>` and decodes it.
Map<String, dynamic> fixture(String name) {
  final File file = File('test/fixtures/redfish/$name');
  final String raw = file.readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// An in-test BMC simulator backed by a [Dio] interceptor.
///
/// Routes map a request path to its JSON body. Unknown paths return `404`.
/// When a request carries an `If-None-Match` header equal to [etag] the
/// simulator answers `304` (replaying the cached body is done by the engine);
/// otherwise it answers `200` with an `ETag` so the engine can learn it.
///
/// Every request path is appended to [requests], enabling assertions about
/// request counts (cache hits, dedup, ETag re-validation).
class FakeBmc {
  /// Creates a [FakeBmc] from [routes] (path → JSON body).
  FakeBmc(this.routes, {this.etag = 'W/"v1"'});

  /// Route table: relative path → decoded JSON body.
  final Map<String, dynamic> routes;

  /// ETag returned on `200` and expected on a conditional `304`.
  final String etag;

  /// All requested paths, in order, across every crawl.
  final List<String> requests = <String>[];

  /// Builds a [RedfishClient] wired to this simulator.
  RedfishClient buildClient() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'https://bmc1:443',
        validateStatus: (int? s) => s != null && s >= 200 && s < 400,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          requests.add(options.path);
          final dynamic body = routes[options.path];
          if (body == null) {
            // Simulate the real client: a 4xx is a transport failure that
            // surfaces as a DioException (and, in the engine, RedfishException).
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  data: <String, dynamic>{'error': 'not found'},
                  statusCode: 404,
                  requestOptions: options,
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          final dynamic ifNone = options.headers['If-None-Match'];
          if (ifNone == etag) {
            handler.resolve(
              Response<dynamic>(
                statusCode: 304,
                requestOptions: options,
                headers: Headers.fromMap(
                  <String, List<String>>{'etag': <String>[etag]},
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              data: body,
              statusCode: 200,
              requestOptions: options,
              headers: Headers.fromMap(
                <String, List<String>>{
                  'etag': <String>[etag],
                  'content-type': <String>['application/json'],
                },
              ),
            ),
          );
        },
      ),
    );
    return RedfishClient(
      profile: const ConnectionProfile(host: 'bmc1'),
      dio: dio,
    );
  }
}
