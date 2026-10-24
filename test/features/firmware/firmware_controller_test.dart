import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/firmware/firmware_controller.dart';
import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

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
}
