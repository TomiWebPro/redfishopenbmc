// ignore_for_file: prefer_const_constructors
import 'dart:async';

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

/// A [PowerService] double whose [fetchPowerState] is gated by completers, so
/// a test can sequence each poll read and prove per-action poll-handle
/// semantics (issue #022): a rapid second action supersedes the first loop.
class GatedPowerService extends PowerService {
  /// Creates a [GatedPowerService].
  GatedPowerService() : super(client: null, systemId: 'bmc1');

  /// Pending poll-read gates in call order.
  final List<Completer<PowerState>> fetchGates = <Completer<PowerState>>[];

  /// Number of [reset] invocations.
  int resetCalls = 0;

  @override
  Future<void> reset(ResetType type) async {
    resetCalls++;
  }

  @override
  Future<PowerState> fetchPowerState() {
    final Completer<PowerState> gate = Completer<PowerState>();
    fetchGates.add(gate);
    return gate.future;
  }
}

PowerController buildController({
  required PowerService service,
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

    test('NMI keeps the current known state instead of flashing unknown',
        () async {
      final FakePowerService svc = FakePowerService(powerState: PowerState.on);
      final PowerController controller = buildController(
        service: svc,
        supported: const <String>['On', 'Nmi'],
      );

      // Initial known state is off (buildController's initialState).
      expect(controller.state.powerState, PowerState.off);

      await controller.reset(ResetType.nmi);

      // NMI is an interrupt, not a power transition: the optimistic state
      // stays at the current known state (off), never flashing `unknown`
      // (issue #022 criterion 3).
      expect(controller.state.powerState, PowerState.off);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(controller.state.powerState, PowerState.on);
      expect(svc.resetCalls, 1);
    });

    test(
        'a rapid second action supersedes the first poll loop '
        '(per-action poll handle)', () async {
      final GatedPowerService svc = GatedPowerService();
      final PowerController controller = buildController(
        service: svc,
        supported: const <String>['On', 'ForceOff', 'GracefulShutdown'],
        pollInterval: const Duration(milliseconds: 5),
        pollTimeout: const Duration(milliseconds: 500),
      );

      // First action starts poll loop A.
      await controller.reset(ResetType.on);
      expect(controller.state.powerState, PowerState.poweringOn);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(svc.fetchGates.length, 1);

      // Second action supersedes loop A before its first read lands.
      await controller.reset(ResetType.gracefulShutdown);
      expect(controller.state.powerState, PowerState.poweringOff);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(svc.fetchGates.length, 2,
          reason: 'each action must own a fresh poll loop');

      // Loop A's stale read (On) must NOT clobber the second action's
      // optimistic PoweringOff.
      svc.fetchGates[0].complete(PowerState.on);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.state.powerState, PowerState.poweringOff,
          reason: 'the first loop is superseded and must not write state');

      // Loop B's read converges to the second action's real target.
      svc.fetchGates[1].complete(PowerState.off);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(controller.state.powerState, PowerState.off);
      expect(svc.resetCalls, 2);
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
