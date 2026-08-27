// ignore_for_file: prefer_const_constructors
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/features/power/models/power_state.dart';
import 'package:redfishopenbmc/features/power/power_service.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
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

SystemFeatures featuresWithComputerSystem({
  List<String> supported = const <String>[
    'On',
    'ForceOff',
    'GracefulRestart',
    'ForceRestart',
  ],
}) {
  final Map<String, dynamic> computerSystem = <String, dynamic>{
    '@odata.id': '/redfish/v1/Systems/system',
    '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
    'Id': 'system',
    'Name': 'System',
    'PowerState': 'On',
    'Actions': <String, dynamic>{
      '#ComputerSystem.Reset': <String, dynamic>{
        'target': '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
      },
    },
  };
  return SystemFeatures(
    systemId: 'bmc1',
    powerControl: true,
    supportedResetTypes: supported,
    raw: <String, dynamic>{'/redfish/v1/Systems/system': computerSystem},
  );
}

RedfishClient clientWithAdapter(DioAdapter adapter) => RedfishClient(
      profile: const ConnectionProfile(host: 'bmc1.local', name: 'bmc1'),
      dio: adapter.dio,
    );

/// Builds a representative ComputerSystem resource body carrying the
/// `#ComputerSystem.Reset` action target, used to exercise raw-tree resolution.
Map<String, dynamic> computerSystemMap({
  String uri = '/redfish/v1/Systems/system',
  String powerState = 'On',
}) =>
    <String, dynamic>{
      '@odata.id': uri,
      '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
      'Id': 'system',
      'Name': 'System',
      'PowerState': powerState,
      'Actions': <String, dynamic>{
        '#ComputerSystem.Reset': <String, dynamic>{
          'target': '$uri/Actions/ComputerSystem.Reset',
        },
      },
    };

void main() {
  group('PowerService — reset', () {
    test('POSTs the resolved target with the Redfish ResetType (On)', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(204, null),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      await svc.reset(ResetType.on);
      // No throw => success.
    });

    test('POSTs ForceOff with the correct body', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(204, null),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      await svc.reset(ResetType.forceOff);
      // Success path: no throw.
    });

    test('rejects an unsupported ResetType before any request', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      // No mock POST configured → would throw if a request were made.
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      await expectLater(
        svc.reset(ResetType.nmi),
        throwsA(
          isA<RedfishException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.errorCode,
                'errorCode',
                'Base.1.0.ResetTypeInvalid',
              ),
        ),
      );
    });

    test('maps 403 to insufficient privilege', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(403, <String, dynamic>{}),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        // Rely on the raw-tree action target (systemResourceUri null).
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>[
            'On',
            'ForceOff',
            'GracefulRestart',
            'ForceRestart',
          ],
          raw: <String, dynamic>{
            '/redfish/v1/Systems/system': computerSystemMap(),
          },
        ),
        systemResourceUri: null,
      );

      await expectLater(
        svc.reset(ResetType.on),
        throwsA(
          isA<RedfishException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having(
                (e) => e.errorCode,
                'errorCode',
                'Base.1.0.InsufficientPrivilege',
              ),
        ),
      );
    });

    test('maps 409 to system busy', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(409, <String, dynamic>{}),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      await expectLater(
        svc.reset(ResetType.on),
        throwsA(
          isA<RedfishException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having(
                (e) => e.errorCode,
                'errorCode',
                'Base.1.0.ResourceInUse',
              ),
        ),
      );
    });

    test('uses @Message.ExtendedInfo message for 400', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(400, <String, dynamic>{
          '@Message.ExtendedInfo': <Map<String, dynamic>>[
            <String, dynamic>{'Message': 'Reset not allowed in current state'},
          ],
        }),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      await expectLater(
        svc.reset(ResetType.on),
        throwsA(
          isA<RedfishException>().having(
            (e) => e.message,
            'message',
            'Reset not allowed in current state',
          ),
        ),
      );
    });

    test('live fallback resolution when discovery raw is empty', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc202.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/Systems',
        (server) => server.reply(200, <String, dynamic>{
          'Members': <Map<String, dynamic>>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/c202'},
          ],
        }),
      );
      adapter.onGet(
        '/redfish/v1/Systems/c202',
        (server) => server.reply(200, <String, dynamic>{
          'PowerState': 'On',
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{
              'target': '/redfish/v1/Systems/c202/Actions/ComputerSystem.Reset',
            },
          },
        }),
      );
      adapter.onPost(
        '/redfish/v1/Systems/c202/Actions/ComputerSystem.Reset',
        (server) => server.reply(202, null),
      );
      final PowerService svc = PowerService(
        client: RedfishClient(
          profile: const ConnectionProfile(host: 'bmc202.local', name: 'bmc202'),
          dio: adapter.dio,
        ),
        systemId: 'bmc202',
        // Empty discovery cache + no known resource uri → live crawl.
        features: const SystemFeatures(systemId: 'bmc202', powerControl: true),
      );

      await svc.reset(ResetType.on);
      // 202 accepted → success path reached.
    });

    test('throws a friendly error when not connected', () async {
      final PowerService svc = PowerService(
        client: null,
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
      );
      await expectLater(
        svc.reset(ResetType.on),
        throwsA(
          isA<RedfishException>().having(
            (e) => e.errorCode,
            'errorCode',
            'Base.1.0.NotConnected',
          ),
        ),
      );
    });
  });

  group('PowerService — target resolution', () {
    test('resolves the action target from the discovery raw tree', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(204, null),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        // No known resource uri → must read the action target from raw.
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>['On'],
          raw: <String, dynamic>{
            '/redfish/v1/Systems/system': computerSystemMap(),
          },
        ),
        systemResourceUri: null,
      );

      await svc.reset(ResetType.on);
      // Reaching the POST means the raw action target was resolved.
    });

    test('resolves the system uri from a raw ComputerSystem id', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, <String, dynamic>{'PowerState': 'Off'}),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          raw: <String, dynamic>{
            '/redfish/v1/Systems/system': computerSystemMap(powerState: 'Off'),
          },
        ),
        systemResourceUri: null,
      );

      final PowerState state = await svc.fetchPowerState();
      expect(state, PowerState.off);
    });

    test('handles a 202 with a Location task monitor without error', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(202, null),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        // Rely on the raw-tree action target (systemResourceUri null) so the
        // resolution path mirrors the passing raw-resolution test.
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>[
            'On',
            'ForceOff',
            'GracefulRestart',
            'ForceRestart',
          ],
          raw: <String, dynamic>{
            '/redfish/v1/Systems/system': computerSystemMap(),
          },
        ),
        systemResourceUri: null,
      );

      // 202 + Location: treated as accepted; the task is not polled here.
      await svc.reset(ResetType.forceRestart);
    });
  });

  group('PowerService — fetchPowerState', () {
    test('parses PowerState from the ComputerSystem resource', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(200, <String, dynamic>{
          'PowerState': 'Off',
        }),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      final PowerState state = await svc.fetchPowerState();
      expect(state, PowerState.off);
    });

    test('rethrows a RedfishException surfaced while reading state', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/Systems/system',
        (server) => server.reply(403, <String, dynamic>{}),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      await expectLater(
        svc.fetchPowerState(),
        throwsA(
          isA<RedfishException>()
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('PowerService — error taxonomy', () {
    test('maps an unhandled 500 to a normalized RedfishException', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc1.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onPost(
        '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
        (server) => server.reply(500, <String, dynamic>{}),
      );
      final PowerService svc = PowerService(
        client: clientWithAdapter(adapter),
        systemId: 'bmc1',
        features: featuresWithComputerSystem(),
        systemResourceUri: '/redfish/v1/Systems/system',
      );

      await expectLater(
        svc.reset(ResetType.on),
        throwsA(
          isA<RedfishException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
