// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/power/models/power_state.dart';
import 'package:redfishopenbmc/features/power/power_controller.dart';
import 'package:redfishopenbmc/features/power/power_service.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [PowerService] double that records reset calls and returns a canned power
/// state from [fetchPowerState], optionally failing the reset.
class FakePowerService extends PowerService {
  /// Creates a [FakePowerService].
  FakePowerService({this.powerState = PowerState.on, this.throwOnReset = false})
      : super(client: null, systemId: 'bmc1');

  /// The state returned by [fetchPowerState].
  PowerState powerState;

  /// When `true`, [reset] throws a [RedfishException].
  bool throwOnReset;

  /// Number of [reset] invocations.
  int resetCalls = 0;

  @override
  Future<void> reset(ResetType type) async {
    resetCalls++;
    if (throwOnReset) {
      throw const RedfishException(message: 'boom', errorCode: 'Base.1.0.Boom');
    }
  }

  @override
  Future<PowerState> fetchPowerState() async => powerState;
}

PowerController buildController({
  required FakePowerService service,
  List<String> supported = const <String>['On', 'ForceOff'],
  Duration pollInterval = const Duration(milliseconds: 5),
  Duration pollTimeout = const Duration(milliseconds: 150),
}) =>
    PowerController(
      service: service,
      features: SystemFeatures(
        systemId: 'bmc1',
        powerControl: true,
        supportedResetTypes: supported,
      ),
      initialState: const PowerUiState(powerState: PowerState.off),
      pollInterval: pollInterval,
      pollTimeout: pollTimeout,
    );

void main() {
  group('PowerController — reset', () {
    test('optimistically transitions then converges to real state', () async {
      final FakePowerService svc = FakePowerService(powerState: PowerState.on);
      final PowerController controller = buildController(service: svc);

      await controller.reset(ResetType.on);

      // After the request settles, polling converges to the read state.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(controller.state.powerState, PowerState.on);
      expect(controller.state.actionInFlight, isFalse);
      expect(svc.resetCalls, 1);
    });

    test('ForceOff projects poweringOff then converges to off', () async {
      final FakePowerService svc = FakePowerService(powerState: PowerState.off);
      final PowerController controller = buildController(service: svc);

      await controller.reset(ResetType.forceOff);
      // Optimistic state is set synchronously before the await completes.
      expect(controller.state.powerState, PowerState.poweringOff);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(controller.state.powerState, PowerState.off);
    });

    test('rejects unsupported reset types without calling the service',
        () async {
      final FakePowerService svc = FakePowerService();
      final PowerController controller = buildController(
        service: svc,
        supported: const <String>['On'], // ForceOff not advertised
      );

      await controller.reset(ResetType.forceOff);

      expect(svc.resetCalls, 0);
      expect(controller.state.error, contains('not supported'));
      expect(controller.state.actionInFlight, isFalse);
    });

    test('records the error and reverts to unknown on failure', () async {
      final FakePowerService svc = FakePowerService(throwOnReset: true);
      final PowerController controller = buildController(service: svc);

      await controller.reset(ResetType.on);

      expect(controller.state.error, 'boom');
      expect(controller.state.powerState, PowerState.unknown);
      expect(controller.state.actionInFlight, isFalse);
    });
  });

  group('PowerController — refresh', () {
    test('updates state from the service', () async {
      final FakePowerService svc = FakePowerService(powerState: PowerState.on);
      final PowerController controller = buildController(service: svc);

      await controller.refresh();

      expect(controller.state.powerState, PowerState.on);
      expect(controller.state.error, isNull);
    });
  });
}
