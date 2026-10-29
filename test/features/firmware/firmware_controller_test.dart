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

/// A [FirmwareService] double whose [FirmwareService.pushImage] blocks until
/// the test completes [pushGate], optionally reporting upload progress first —
/// the in-flight push-upload shape (#008/#020).
class _PushGateService extends FirmwareService {
  _PushGateService() : super(client: null, systemId: 'bmc1');

  /// Completes the pending `pushImage` when the test is ready.
  final Completer<UpdateTask> pushGate = Completer<UpdateTask>();

  /// Bytes reported by the caller via `onProgress`, captured for assertions.
  final List<(int, int)> progress = <(int, int)>[];

  @override
  Future<UpdateTask> pushImage(
    PushImageRequest req, {
    void Function(int sent, int total)? onProgress,
  }) async {
    onProgress?.call(1024, 2048);
    return pushGate.future;
  }
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

    test('surfaces the interim PercentComplete while polling and clears it '
        'at the terminal state (#008/#020 task timeline)', () async {
      // One interim Running@60 then the terminal Completed result; the fake
      // service fires onInterim for every non-terminal snapshot it handed in
      // (mirroring the real FirmwareService.pollTask contract).
      final _InterimPollService service = _InterimPollService(
        interims: <RedfishTask>[
          const RedfishTask(id: '42', state: 'Running', percentComplete: 60),
        ],
        finalResult: const RedfishTask(
            id: '42', state: 'Completed', percentComplete: 100),
      );
      final FirmwareController controller = FirmwareController(
        service: service,
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(taskUri: '/redfish/v1/TaskService/Tasks/42'),
        ),
      );

      // Listen for every state change so the interim PercentComplete cannot
      // be missed between microtasks (listeners fire synchronously on set).
      final List<int?> history = <int?>[];
      controller.addListener((s) => history.add(s.pollProgress));

      final Future<void> done = controller.pollLastTask(
        interval: Duration.zero,
        maxPolls: 2,
      );
      await done;

      expect(service.interimCalls, 1);
      expect(
        history,
        contains(60),
        reason: 'the interim RunningPercentComplete=60 must be surfaced '
            'as FirmwareUiState.pollProgress mid-poll',
      );
      // The controller clears the interim progress once the terminal result
      // lands, so the banner never shows a stale percentage.
      expect(
        history.last,
        isNull,
        reason: 'the terminal state must clear the interim progress',
      );
      expect(controller.state.pollProgress, isNull);
      expect(controller.state.lastResult?.isSuccess, isTrue);
      expect(controller.state.polling, isFalse);
      expect(controller.state.error, isNull);
    });

    test('does not surface an interim percent when the task publishes none',
        () async {
      // The pinned DMTF mockup task (545) never publishes PercentComplete —
      // the state must simply stay null (text-only banner), never throw.
      final _InterimPollService service = _InterimPollService(
        interims: const <RedfishTask>[
          RedfishTask(id: '42', state: 'Running'),
        ],
        finalResult: const RedfishTask(
          id: '42',
          state: 'Completed',
          percentComplete: 100,
        ),
      );
      final FirmwareController controller = FirmwareController(
        service: service,
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(taskUri: '/redfish/v1/TaskService/Tasks/42'),
        ),
      );

      final List<int?> history = <int?>[];
      controller.addListener((s) => history.add(s.pollProgress));

      await controller.pollLastTask(
        interval: Duration.zero,
        maxPolls: 2,
      );

      expect(service.interimCalls, 1);
      // The state changes twice (polling start + terminal) and neither
      // snapshot carries a percent — every history entry must be null.
      expect(history, everyElement(isNull),
          reason: 'no PercentComplete anywhere in the timeline');
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

  group('FirmwareController.pushImage — upload state (#008/#020)', () {
    test(
        'raises uploading, stores uploadProgress and the returned task '
        'on success', () async {
      final _PushGateService service = _PushGateService();
      final FirmwareController controller = FirmwareController(
        service: service,
      );

      final Future<void> done = controller.pushImage(
        const PushImageRequest(bytes: <int>[1, 2], filename: 'fw.bin'),
      );
      expect(controller.state.uploading, isTrue,
          reason: 'the upload surface must know the push is in flight');
      expect(controller.state.loading, isTrue);
      expect(controller.state.uploadProgress, (sent: 1024, total: 2048),
          reason: 'byte progress must land in state for a progress UI');

      service.pushGate.complete(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/3'),
      );
      await done;

      expect(controller.state.uploading, isFalse);
      expect(controller.state.loading, isFalse);
      expect(controller.state.uploadProgress, isNull,
          reason: 'the byte progress is cleared once the upload finishes');
      expect(controller.state.lastTask?.taskUri,
          '/redfish/v1/TaskService/TaskMonitors/3');
      expect(controller.state.error, isNull);
    });

    test('clears uploading and records the error on failure', () async {
      final _PushGateService service = _PushGateService();
      final FirmwareController controller = FirmwareController(
        service: service,
      );

      final Future<void> done = controller.pushImage(
        const PushImageRequest(bytes: <int>[1, 2], filename: 'fw.bin'),
      );
      expect(controller.state.uploading, isTrue);

      service.pushGate.completeError(
        const RedfishException(
          message: 'Insufficient privilege to perform this firmware update.',
          statusCode: 403,
          errorCode: 'Base.1.0.InsufficientPrivilege',
        ),
      );
      await done;

      expect(controller.state.uploading, isFalse,
          reason: 'a failed upload must not leave the surface busy');
      expect(controller.state.loading, isFalse);
      expect(controller.state.uploadProgress, isNull);
      expect(controller.state.lastTask, isNull);
      expect(controller.state.error,
          'Insufficient privilege to perform this firmware update.');
    });

    test('forwards progress to an external callback when provided', () async {
      final _PushGateService service = _PushGateService();
      final FirmwareController controller = FirmwareController(
        service: service,
      );

      final List<(int, int)> external = <(int, int)>[];
      final Future<void> done = controller.pushImage(
        const PushImageRequest(bytes: <int>[1, 2], filename: 'fw.bin'),
        onProgress: (int sent, int total) {
          external.add((sent, total));
        },
      );
      expect(external, <(int, int)>[(1024, 2048)]);

      service.pushGate.complete(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/Tasks/3'),
      );
      await done;
    });
  });
}

/// A [FirmwareService] double whose [pollTask] fires [onInterim] for each
/// canned non-terminal snapshot, then resolves (or throws) with
/// [finalResult] — the 202-task-monitor polling shape with in-flight
/// `PercentComplete` progress (#008/#020).
class _InterimPollService extends FirmwareService {
  _InterimPollService({required this.interims, required this.finalResult})
      : super(client: null, systemId: 'bmc1');

  /// Non-terminal snapshots delivered through `onInterim`, in order.
  final List<RedfishTask> interims;

  /// The terminal snapshot handed back after all interims fired.
  final RedfishTask finalResult;

  /// Number of `onInterim` invocations.
  int interimCalls = 0;

  @override
  Future<RedfishTask> pollTask(
    UpdateTask task, {
    Duration interval = const Duration(seconds: 2),
    int maxPolls = 30,
    void Function(RedfishTask interim)? onInterim,
  }) async {
    for (final RedfishTask interim in interims) {
      interimCalls++;
      onInterim?.call(interim);
      await Future<void>.delayed(interval);
    }
    if (finalResult.isFailed) {
      throw RedfishException(
        message: 'Firmware update task ${finalResult.id} failed: '
            '${finalResult.failureReason ?? finalResult.state}',
        errorCode: 'Update.1.0.UpdateFailed',
      );
    }
    return finalResult;
  }
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
    void Function(RedfishTask interim)? onInterim,
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
