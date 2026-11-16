import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery_cache.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery_engine.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

class NoEtagBmc {
  NoEtagBmc(this.routes);

  final Map<String, dynamic> routes;
  final List<String> requests = <String>[];

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
          handler.resolve(
            Response<dynamic>(
              data: jsonDecode(jsonEncode(body)),
              statusCode: 200,
              requestOptions: options,
              headers: Headers.fromMap(
                <String, List<String>>{
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

class ConditionalBmc {
  ConditionalBmc(this.routes, {this.failPaths = const <String>{}});

  final Map<String, dynamic> routes;
  final Set<String> failPaths;
  final String etag = 'W/"v1"';
  final List<String> requests = <String>[];

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
          if (failPaths.contains(options.path)) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  data: <String, dynamic>{'error': 'boom'},
                  statusCode: 500,
                  requestOptions: options,
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          final dynamic body = routes[options.path];
          if (body == null) {
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
                  <String, List<String>>{
                    'etag': <String>[etag],
                  },
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              data: jsonDecode(jsonEncode(body)),
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

void main() {
  group('DiscoveryEngine — cache correctness (#018)', () {
    test('forceRefresh re-fetches unconditionally even without ETags',
        () async {
      final Map<String, dynamic> root = <String, dynamic>{
        '@odata.id': '/redfish/v1/',
        'Systems': <String, dynamic>{'@odata.id': '/redfish/v1/Systems'},
      };
      final Map<String, dynamic> systemsV1 = <String, dynamic>{
        '@odata.id': '/redfish/v1/Systems',
        'Members': <dynamic>[
          <String, dynamic>{'@odata.id': '/redfish/v1/Systems/system'},
        ],
      };
      final Map<String, dynamic> systemV1 = <String, dynamic>{
        '@odata.id': '/redfish/v1/Systems/system',
        '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{
            'target': '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
            'ResetType@Redfish.AllowableValues': <String>['On'],
          },
        },
      };
      final NoEtagBmc bmc = NoEtagBmc(<String, dynamic>{
        '/redfish/v1/': root,
        '/redfish/v1/Systems': systemsV1,
        '/redfish/v1/Systems/system': systemV1,
      });
      final DiscoveryEngine engine = DiscoveryEngine();

      final SystemFeatures first =
          await engine.discover(bmc.buildClient(), 'bmc1');
      expect(first.supportedResetTypes, <String>['On']);
      final int afterFirst = bmc.requests.length;

      bmc.routes['/redfish/v1/Systems/system'] = <String, dynamic>{
        '@odata.id': '/redfish/v1/Systems/system',
        '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{
            'target': '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
            'ResetType@Redfish.AllowableValues': <String>['ForceOff', 'On'],
          },
        },
      };

      final SystemFeatures refreshed = await engine.discover(
        bmc.buildClient(),
        'bmc1',
        forceRefresh: true,
      );

      expect(bmc.requests.length, greaterThan(afterFirst));
      expect(refreshed.supportedResetTypes, <String>['ForceOff', 'On']);
      final DiscoveryCacheEntry? entry = engine.cache.peek('bmc1');
      expect(entry, isNotNull);
      expect(entry!.etags, isEmpty);
    });

    test('error placeholders are not replayed as bodies on 304 re-crawl',
        () async {
      final Map<String, dynamic> routes = <String, dynamic>{
        '/redfish/v1/': <String, dynamic>{
          '@odata.id': '/redfish/v1/',
          'Systems': <String, dynamic>{'@odata.id': '/redfish/v1/Systems'},
          'Chassis': <String, dynamic>{'@odata.id': '/redfish/v1/Chassis'},
        },
        '/redfish/v1/Systems': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems',
          'Members': <dynamic>[],
        },
        '/redfish/v1/Chassis': <String, dynamic>{
          '@odata.id': '/redfish/v1/Chassis',
          'Members': <dynamic>[],
        },
      };
      final ConditionalBmc bmc = ConditionalBmc(
        routes,
        failPaths: <String>{'/redfish/v1/Chassis'},
      );
      final DiscoveryEngine engine = DiscoveryEngine();

      await engine.discover(bmc.buildClient(), 'bmc1');
      final DiscoveryCacheEntry? firstEntry = engine.cache.peek('bmc1');
      expect(firstEntry, isNotNull);
      final Map<String, dynamic> firstChassis =
          firstEntry!.rawTree['/redfish/v1/Chassis'] as Map<String, dynamic>;
      expect(firstChassis['_error'], isA<String>());

      bmc.failPaths.clear();
      await engine.discover(
        bmc.buildClient(),
        'bmc1',
        forceRefresh: true,
      );

      final DiscoveryCacheEntry? refreshed = engine.cache.peek('bmc1');
      expect(refreshed, isNotNull);
      final dynamic chassisRaw = refreshed!.rawTree['/redfish/v1/Chassis'];
      expect(chassisRaw, isA<Map<String, dynamic>>());
      final Map<String, dynamic> chassis = chassisRaw as Map<String, dynamic>;
      expect(chassis.containsKey('_error'), isFalse);
      expect(chassis['@odata.id'], '/redfish/v1/Chassis');
      expect(chassis['Members'], isA<List<dynamic>>());
    });
  });
}
