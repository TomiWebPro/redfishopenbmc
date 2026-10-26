import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/firmware/firmware_controller.dart';
import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';

/// A [FirmwareService] double whose `startSimpleUpdate` blocks until the test
/// completes [startGate] — the in-flight Start-update shape.
class _GateService extends FirmwareService {
  _GateService() : super(client: null, systemId: 'bmc1');

  final Completer<UpdateTask> startGate = Completer<UpdateTask>();

  @override
  Future<UpdateTask> startSimpleUpdate(SimpleUpdateRequest req) =>
      startGate.future;
}

void main() {
  group('FirmwareController.startUpdate — starting state (UI-5)', () {
    test('raises starting while the POST is in flight and clears on success',
        () async {
      final _GateService service = _GateService();
      final FirmwareController controller =
          FirmwareController(service: service);

      final Future<void> done = controller.startUpdate(
        const SimpleUpdateRequest(imageUri: 'https://host/fw.bin'),
      );
      expect(controller.state.starting, isTrue,
          reason: 'the button must know the SimpleUpdate POST is in flight');
      expect(controller.state.loading, isTrue);
      expect(controller.state.lastTask, isNull);

      service.startGate.complete(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/1'),
      );
      await done;

      expect(controller.state.starting, isFalse);
      expect(controller.state.loading, isFalse);
      expect(controller.state.lastTask?.taskUri,
          '/redfish/v1/TaskService/TaskMonitors/1');
      expect(controller.state.error, isNull);
    });

    test('clears starting and records the error on failure', () async {
      final _GateService service = _GateService();
      final FirmwareController controller =
          FirmwareController(service: service);

      final Future<void> done = controller.startUpdate(
        const SimpleUpdateRequest(imageUri: 'https://host/fw.bin'),
      );
      expect(controller.state.starting, isTrue);

      service.startGate.completeError(
        const RedfishException(
          message: 'Update service is busy; please retry the update shortly.',
          statusCode: 409,
          errorCode: 'Base.1.0.ResourceInUse',
        ),
      );
      await done;

      expect(controller.state.starting, isFalse,
          reason: 'a failed POST must not leave the button busy');
      expect(controller.state.loading, isFalse);
      expect(controller.state.lastTask, isNull);
      expect(controller.state.error,
          'Update service is busy; please retry the update shortly.');
    });

    test('load does not set starting (only screen-level loading)', () async {
      final FirmwareController controller =
          FirmwareController(service: _GateService());
      await controller.load();
      expect(controller.state.starting, isFalse);
      expect(controller.state.loading, isFalse);
    });
  });

  group('FirmwareController.pollLastTask — task-monitor polling (#022 c1)', () {
    test('polls the queued task and stores the terminal result', () async {
      final _PollService service = _PollService(
        results: <RedfishTask>[
          const RedfishTask(id: '42', state: 'Completed', status: 'OK'),
        ],
      );
      final FirmwareController controller = FirmwareController(
        service: service,
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(taskUri: '/redfish/v1/TaskService/Tasks/42'),
        ),
      );

      // While in flight the polling flag is raised so the UI can show the
      // spinner.
      final Future<void> done = controller.pollLastTask(
        interval: Duration.zero,
        maxPolls: 1,
      );
      expect(controller.state.polling, isTrue);
      await done;

      expect(controller.state.polling, isFalse);
      expect(controller.state.lastResult?.id, '42');
      expect(controller.state.lastResult?.isSuccess, isTrue);
      expect(controller.state.error, isNull);
    });

    test('records the failure reason when the task failed terminally',
        () async {
      final _PollService service = _PollService(
        results: <RedfishTask>[
          const RedfishTask(
            id: '7',
            state: 'Exception',
            messages: <TaskMessage>[
              TaskMessage(
                messageId: 'Update.1.0.UpdateFailed',
                message: 'The update image was rejected.',
              ),
            ],
          ),
        ],
      );
      final FirmwareController controller = FirmwareController(
        service: service,
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(taskUri: '/redfish/v1/TaskService/Tasks/7'),
        ),
      );

      await controller.pollLastTask(interval: Duration.zero, maxPolls: 1);

      expect(controller.state.polling, isFalse);
      expect(controller.state.lastResult, isNull);
      expect(
          controller.state.error, contains('The update image was rejected.'));
    });

    test('is a no-op when the queued task has no monitor URI', () async {
      final _PollService service = _PollService(
        results: <RedfishTask>[
          const RedfishTask(id: 'x', state: 'Completed'),
        ],
      );
      final FirmwareController controller = FirmwareController(
        service: service,
        initialState: const FirmwareUiState(lastTask: UpdateTask()),
      );

      await controller.pollLastTask(interval: Duration.zero, maxPolls: 1);

      // No monitor → no polling attempted, no error, queued label remains.
      expect(service.pollCalls, 0);
      expect(controller.state.polling, isFalse);
      expect(controller.state.lastResult, isNull);
      expect(controller.state.error, isNull);
    });

    test('is a no-op when nothing was ever queued', () async {
      final _PollService service = _PollService(results: const <RedfishTask>[]);
      final FirmwareController controller =
          FirmwareController(service: service);

      await controller.pollLastTask(interval: Duration.zero, maxPolls: 1);

      expect(service.pollCalls, 0);
      expect(controller.state.polling, isFalse);
    });
  });
}

/// A [FirmwareService] double whose [pollTask] pops the next canned
/// [RedfishTask] (or throws the matching exception) and records the calls.
class _PollService extends FirmwareService {
  _PollService({required this.results}) : super(client: null, systemId: 'bmc1');

  /// Canned results returned by [pollTask], in order.
  final List<RedfishTask> results;

  /// Number of [pollTask] invocations.
  int pollCalls = 0;

  @override
  Future<RedfishTask> pollTask(
    UpdateTask task, {
    Duration interval = const Duration(seconds: 2),
    int maxPolls = 30,
  }) async {
    pollCalls++;
    if (results.isEmpty) {
      throw const RedfishException(
        message: 'no canned result',
        errorCode: 'Update.1.0.TaskMonitorTimeout',
      );
    }
    final RedfishTask result = results.removeAt(0);
    if (result.isFailed) {
      throw RedfishException(
        message: 'Firmware update task ${result.id} failed: '
            '${result.failureReason ?? result.state}',
        errorCode: 'Update.1.0.UpdateFailed',
      );
    }
    return result;
  }
}
