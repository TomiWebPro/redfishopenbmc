import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  group('FirmwareService', () {
    late MockRedfishServer server;
    late RedfishClient client;

    setUp(() async {
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/dmtf_mockup',
      ).start();
      client = server.buildClient();
    });

    tearDown(() async {
      await server.close();
    });

    test('fetchUpdateService resolves service + inventory from the mockup',
        () async {
      final FirmwareService svc =
          FirmwareService(client: client, systemId: 'bmc1');
      final UpdateServiceInfo info = await svc.fetchUpdateService();

      expect(info.serviceEnabled, isTrue);
      expect(info.httpPushUri, '/FWUpdate');
      expect(info.inventory.length, greaterThanOrEqualTo(3));
      expect(
        info.inventory.any(
          (FirmwareInventoryItem i) =>
              i.id == 'SS' || (i.name?.contains('SS') ?? false),
        ),
        isTrue,
      );
    });

    test('startSimpleUpdate POSTs and returns the Location task URI', () async {
      final FirmwareService svc =
          FirmwareService(client: client, systemId: 'bmc1');
      final UpdateTask task = await svc.startSimpleUpdate(
        const SimpleUpdateRequest(
          imageUri: 'http://host/fw.bin',
          transferProtocol: 'HTTP',
          targets: <String>[],
        ),
      );
      expect(task.taskUri, isNotEmpty);
      // The mock does not set Retry-After → the field stays null.
      expect(task.retryAfterSeconds, isNull);
    });

    test('startSimpleUpdate parses the Retry-After header (DSP0266 §12.2)',
        () async {
      // A real BMC may answer 202 with a Location + Retry-After delay; the
      // client must surface the wait hint for the future task poller.
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc-ra.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/UpdateService',
        (server) => server.reply(
          200,
          <String, dynamic>{
            '@odata.id': '/redfish/v1/UpdateService',
            '@odata.type': '#UpdateService.v1_17_1.UpdateService',
            'Id': 'UpdateService',
            'ServiceEnabled': true,
            'Actions': <String, dynamic>{
              '#UpdateService.SimpleUpdate': <String, dynamic>{
                'target':
                    '/redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate',
              },
            },
          },
        ),
      );
      adapter.onPost(
        '/redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate',
        (server) => server.reply(
          202,
          <String, dynamic>{},
          headers: <String, List<String>>{
            Headers.contentTypeHeader: [Headers.jsonContentType],
            'Location': <String>['/redfish/v1/TaskService/TaskMonitors/42'],
            'Retry-After': <String>['30'],
          },
        ),
      );
      final RedfishClient raClient = RedfishClient(
        profile: const ConnectionProfile(host: 'bmc-ra.local', name: 'bmc-ra'),
        dio: adapter.dio,
      );
      final FirmwareService svc =
          FirmwareService(client: raClient, systemId: 'bmc-ra');

      final UpdateTask task = await svc.startSimpleUpdate(
        const SimpleUpdateRequest(
          imageUri: 'http://host/fw.bin',
          transferProtocol: 'HTTP',
          targets: <String>[],
        ),
      );
      expect(task.taskUri, '/redfish/v1/TaskService/TaskMonitors/42');
      expect(task.retryAfterSeconds, 30);
    });

    test('startSimpleUpdate tolerates an absent Location (empty task URI)',
        () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc-noloc.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/UpdateService',
        (server) => server.reply(
          200,
          <String, dynamic>{
            '@odata.id': '/redfish/v1/UpdateService',
            '@odata.type': '#UpdateService.v1_17_1.UpdateService',
            'Id': 'UpdateService',
            'ServiceEnabled': true,
            'Actions': <String, dynamic>{
              '#UpdateService.SimpleUpdate': <String, dynamic>{
                'target':
                    '/redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate',
              },
            },
          },
        ),
      );
      adapter.onPost(
        '/redfish/v1/UpdateService/Actions/UpdateService.SimpleUpdate',
        (server) => server.reply(202, <String, dynamic>{}),
      );
      final RedfishClient noLocClient = RedfishClient(
        profile:
            const ConnectionProfile(host: 'bmc-noloc.local', name: 'bmc-noloc'),
        dio: adapter.dio,
      );
      final FirmwareService svc =
          FirmwareService(client: noLocClient, systemId: 'bmc-noloc');

      final UpdateTask task = await svc.startSimpleUpdate(
        const SimpleUpdateRequest(
          imageUri: 'http://host/fw.bin',
          transferProtocol: 'HTTP',
          targets: <String>[],
        ),
      );
      expect(task.taskUri, isNull);
      expect(task.retryAfterSeconds, isNull);
    });
  });
}

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
