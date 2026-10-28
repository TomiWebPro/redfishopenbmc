import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';

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

    test('pollTask GETs the monitor and returns a terminal success task',
        () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc-task.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/TaskService/TaskMonitors/42',
        (server) => server.reply(
          200,
          <String, dynamic>{
            '@odata.type': '#Task.v1_7_3.Task',
            '@odata.id': '/redfish/v1/TaskService/TaskMonitors/42',
            'Id': '42',
            'Name': 'Task 42',
            'TaskState': 'Completed',
            'TaskStatus': 'OK',
          },
        ),
      );
      final RedfishClient taskClient = RedfishClient(
        profile:
            const ConnectionProfile(host: 'bmc-task.local', name: 'bmc-task'),
        dio: adapter.dio,
      );
      final FirmwareService svc =
          FirmwareService(client: taskClient, systemId: 'bmc-task');

      final RedfishTask result = await svc.pollTask(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/42'),
        interval: Duration.zero,
        maxPolls: 1,
      );
      expect(result.id, '42');
      expect(result.state, 'Completed');
      expect(result.status, 'OK');
      expect(result.isSuccess, isTrue);
    });

    test('pollTask round-trips the served fixture task (mock 545 shape)',
        () async {
      // The real DMTF mockup fixture task (545) is Completed/OK with no
      // PercentComplete — the poller must resolve it without a percent value.
      final FirmwareService svc =
          FirmwareService(client: client, systemId: 'bmc1');
      final RedfishTask result = await svc.pollTask(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/Tasks/545'),
        interval: Duration.zero,
        maxPolls: 1,
      );
      expect(result.id, '545');
      expect(result.state, 'Completed');
      expect(result.status, 'OK');
      expect(result.percentComplete, isNull);
      expect(result.isSuccess, isTrue);
    });

    test('pollTask throws the failure reason for a terminal failure task',
        () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc-fail.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/TaskService/TaskMonitors/7',
        (server) => server.reply(
          200,
          <String, dynamic>{
            '@odata.id': '/redfish/v1/TaskService/TaskMonitors/7',
            'Id': '7',
            'TaskState': 'Exception',
            'Messages': <dynamic>[
              <String, dynamic>{
                'MessageId': 'Update.1.0.UpdateFailed',
                'Message': 'The update image was rejected.',
                'Severity': 'Critical',
              },
            ],
          },
        ),
      );
      final RedfishClient failClient = RedfishClient(
        profile:
            const ConnectionProfile(host: 'bmc-fail.local', name: 'bmc-fail'),
        dio: adapter.dio,
      );
      final FirmwareService svc =
          FirmwareService(client: failClient, systemId: 'bmc-fail');

      await expectLater(
        svc.pollTask(
          const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/7'),
          interval: Duration.zero,
          maxPolls: 1,
        ),
        throwsA(
          isA<RedfishException>()
              .having((RedfishException e) => e.message, 'message',
                  contains('The update image was rejected.'))
              .having((RedfishException e) => e.errorCode, 'errorCode',
                  'Update.1.0.UpdateFailed'),
        ),
      );
    });

    test('pollTask times out when the task never reaches a terminal state',
        () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc-slow.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/TaskService/TaskMonitors/9',
        (server) => server.reply(
          200,
          <String, dynamic>{
            '@odata.id': '/redfish/v1/TaskService/TaskMonitors/9',
            'Id': '9',
            'TaskState': 'Running',
            'PercentComplete': 10,
          },
        ),
      );
      final RedfishClient slowClient = RedfishClient(
        profile:
            const ConnectionProfile(host: 'bmc-slow.local', name: 'bmc-slow'),
        dio: adapter.dio,
      );
      final FirmwareService svc =
          FirmwareService(client: slowClient, systemId: 'bmc-slow');

      await expectLater(
        svc.pollTask(
          const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/9'),
          interval: Duration.zero,
          maxPolls: 2,
        ),
        throwsA(
          isA<RedfishException>()
              .having((RedfishException e) => e.errorCode, 'errorCode',
                  'Update.1.0.TaskMonitorTimeout')
              .having((RedfishException e) => e.retryable, 'retryable', isTrue),
        ),
      );
    });

    test('pollTask throws NoTaskMonitor when no task URI was returned',
        () async {
      final FirmwareService svc =
          FirmwareService(client: client, systemId: 'bmc1');
      await expectLater(
        svc.pollTask(const UpdateTask()),
        throwsA(
          isA<RedfishException>().having((RedfishException e) => e.errorCode,
              'errorCode', 'Base.1.0.NoTaskMonitor'),
        ),
      );
    });

    test('pollTask throws NotConnected when there is no client', () async {
      final FirmwareService svc =
          FirmwareService(client: null, systemId: 'bmc1');
      await expectLater(
        svc.pollTask(
          const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/1'),
        ),
        throwsA(
          isA<RedfishException>().having((RedfishException e) => e.errorCode,
              'errorCode', 'Base.1.0.NotConnected'),
        ),
      );
    });

    test('pollTask wraps a monitor GET failure with context', () async {
      final DioAdapter adapter = DioAdapter(
        dio: Dio(BaseOptions(baseUrl: 'https://bmc-404.local:443')),
        matcher: const _PathMatcher(),
      );
      adapter.onGet(
        '/redfish/v1/TaskService/TaskMonitors/404',
        (server) => server.reply(
          404,
          <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'Base.1.0.ResourceNotFound',
              'message': 'Not Found',
            },
          },
        ),
      );
      final RedfishClient missingClient = RedfishClient(
        profile:
            const ConnectionProfile(host: 'bmc-404.local', name: 'bmc-404'),
        dio: adapter.dio,
      );
      final FirmwareService svc =
          FirmwareService(client: missingClient, systemId: 'bmc-404');

      await expectLater(
        svc.pollTask(
          const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/404'),
          interval: Duration.zero,
          maxPolls: 1,
        ),
        throwsA(
          isA<RedfishException>()
              .having((RedfishException e) => e.message, 'message',
                  contains('Failed to read the task monitor'))
              .having((RedfishException e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    group('FirmwareService.pushImage (#008/#020 binary upload)', () {
      test(
          'single-push path POSTs raw bytes to HttpPushUri and returns the '
          'Location task URI (DMTF mockup /FWUpdate shape)', () async {
        final FirmwareService svc =
            FirmwareService(client: client, systemId: 'bmc1');
        // The fixture UpdateService advertises HttpPushUri=/FWUpdate (no
        // MultipartHttpPushUri), so the upload must choose the single-push
        // vendor-specific shape.
        final UpdateTask task = await svc.pushImage(
          const PushImageRequest(
            bytes: <int>[1, 2, 3, 4, 5],
            filename: 'fw.bin',
          ),
        );
        // The in-process mock server 202s with Location "$path/Tasks/1".
        expect(task.taskUri, isNotEmpty);
        expect(task.taskUri, endsWith('FWUpdate/Tasks/1'));
        expect(task.retryAfterSeconds, isNull);
      });

      test(
          'multipart path prefers MultipartHttpPushUri and posts a FormData '
          'UpdateFile part (#008/#020)', () async {
        final DioAdapter adapter = DioAdapter(
          dio: Dio(BaseOptions(baseUrl: 'https://bmc-multi.local:443')),
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
              'HttpPushUri': '/FWUpdate',
              'MultipartHttpPushUri': '/upload/image',
            },
          ),
        );
        adapter.onPost(
          '/upload/image',
          (server) => server.reply(
            202,
            <String, dynamic>{},
            headers: <String, List<String>>{
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'Location': <String>['/redfish/v1/TaskService/TaskMonitors/77'],
            },
          ),
        );
        final RedfishClient multiClient = RedfishClient(
          profile: const ConnectionProfile(
              host: 'bmc-multi.local', name: 'bmc-multi'),
          dio: adapter.dio,
        );
        final FirmwareService svc =
            FirmwareService(client: multiClient, systemId: 'bmc-multi');

        final UpdateTask task = await svc.pushImage(
          const PushImageRequest(
            bytes: <int>[1, 2, 3, 4, 5],
            filename: 'fw.bin',
            targets: <String>[
              '/redfish/v1/UpdateService/FirmwareInventory/BMC',
            ],
            applyTime: 'OnReset',
          ),
        );
        expect(task.taskUri, '/redfish/v1/TaskService/TaskMonitors/77');
        expect(task.retryAfterSeconds, isNull);
      });

      test(
          'multipart upload carries UpdateParameters (targets + apply-time) '
          'and returns the task handle', () async {
        final DioAdapter adapter = DioAdapter(
          dio: Dio(BaseOptions(baseUrl: 'https://bmc-multi2.local:443')),
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
              'MultipartHttpPushUri': '/upload/image',
            },
          ),
        );
        adapter.onPost(
          '/upload/image',
          (server) => server.reply(
            202,
            <String, dynamic>{},
            headers: <String, List<String>>{
              Headers.contentTypeHeader: [Headers.jsonContentType],
              'Location': <String>['/redfish/v1/TaskService/TaskMonitors/9'],
              'Retry-After': <String>['15'],
            },
          ),
        );
        final RedfishClient multiClient = RedfishClient(
          profile: const ConnectionProfile(
              host: 'bmc-multi2.local', name: 'bmc-multi2'),
          dio: adapter.dio,
        );
        final FirmwareService svc =
            FirmwareService(client: multiClient, systemId: 'bmc-multi2');

        final UpdateTask task = await svc.pushImage(
          PushImageRequest(
            bytes: List<int>.filled(2048, 7),
            filename: 'fw.bin',
            applyTime: 'Immediate',
          ),
        );
        expect(task.taskUri, '/redfish/v1/TaskService/TaskMonitors/9');
        expect(task.retryAfterSeconds, 15);
      });

      test(
          'single-push reports byte progress over the real in-process server '
          '(progress callback wiring)', () async {
        // DioAdapter never fires onSendProgress (it replies without
        // streaming), so the progress-seam assertion uses the real in-process
        // MockRedfishServer (a real localhost socket — dio streams the upload
        // body and invokes the callback).
        final FirmwareService svc =
            FirmwareService(client: client, systemId: 'bmc1');
        final List<(int, int)> progress = <(int, int)>[];
        final UpdateTask task = await svc.pushImage(
          PushImageRequest(
            bytes: List<int>.filled(65536, 3),
            filename: 'fw.bin',
          ),
          onProgress: (int sent, int total) {
            progress.add((sent, total));
          },
        );
        expect(task.taskUri, isNotEmpty);
        expect(progress, isNotEmpty,
            reason: 'dio must report byte progress while streaming the upload '
                'body to the real server');
        expect(progress.last.$2, 65536,
            reason: 'the final progress event carries the full upload size');
      });

      test('throws NoPushUri when the service advertises no push URI',
          () async {
        final DioAdapter adapter = DioAdapter(
          dio: Dio(BaseOptions(baseUrl: 'https://bmc-nopush.local:443')),
          matcher: const _PathMatcher(),
        );
        adapter.onGet(
          '/redfish/v1/UpdateService',
          (server) => server.reply(
            200,
            <String, dynamic>{
              '@odata.id': '/redfish/v1/UpdateService',
              '@odata.type': '#UpdateService.v1_13_0.UpdateService',
              'Id': 'UpdateService',
              'ServiceEnabled': true,
            },
          ),
        );
        final RedfishClient noPushClient = RedfishClient(
          profile: const ConnectionProfile(
              host: 'bmc-nopush.local', name: 'bmc-nopush'),
          dio: adapter.dio,
        );
        final FirmwareService svc =
            FirmwareService(client: noPushClient, systemId: 'bmc-nopush');

        await expectLater(
          svc.pushImage(
            const PushImageRequest(bytes: <int>[1], filename: 'fw.bin'),
          ),
          throwsA(
            isA<RedfishException>().having((RedfishException e) => e.errorCode,
                'errorCode', 'Update.1.0.NoPushUri'),
          ),
        );
      });

      test('throws NotConnected when there is no client', () async {
        final FirmwareService svc =
            FirmwareService(client: null, systemId: 'bmc1');
        await expectLater(
          svc.pushImage(
            const PushImageRequest(bytes: <int>[1], filename: 'fw.bin'),
          ),
          throwsA(
            isA<RedfishException>().having((RedfishException e) => e.errorCode,
                'errorCode', 'Base.1.0.NotConnected'),
          ),
        );
      });

      test(
          'normalizes a 400 from the push seam without an error envelope '
          '(the #020 no-masking rule)', () async {
        final DioAdapter adapter = DioAdapter(
          dio: Dio(BaseOptions(baseUrl: 'https://bmc-400.local:443')),
          matcher: const _PathMatcher(),
        );
        adapter.onGet(
          '/redfish/v1/UpdateService',
          (server) => server.reply(
            200,
            <String, dynamic>{
              '@odata.id': '/redfish/v1/UpdateService',
              '@odata.type': '#UpdateService.v1_13_0.UpdateService',
              'Id': 'UpdateService',
              'ServiceEnabled': true,
              'HttpPushUri': '/FWUpdate',
            },
          ),
        );
        adapter.onPost(
          '/FWUpdate',
          (server) => server.reply(
            400,
            '',
            headers: <String, List<String>>{
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );
        final RedfishClient badClient = RedfishClient(
          profile:
              const ConnectionProfile(host: 'bmc-400.local', name: 'bmc-400'),
          dio: adapter.dio,
        );
        final FirmwareService svc =
            FirmwareService(client: badClient, systemId: 'bmc-400');

        await expectLater(
          svc.pushImage(
            const PushImageRequest(bytes: <int>[1], filename: 'fw.bin'),
          ),
          throwsA(
            isA<RedfishException>()
                .having((RedfishException e) => e.statusCode, 'statusCode', 400)
                .having((RedfishException e) => e.message, 'message',
                    contains('Invalid update request')),
          ),
        );
      });
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
