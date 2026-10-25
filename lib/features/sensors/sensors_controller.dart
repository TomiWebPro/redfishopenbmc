import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Immutable UI state for the sensor monitoring screen (issue #007).
///
/// Tracks the per-chassis [ChassisSensors] lists, an in-flight [loading] flag,
/// and the most recent [error] message. Kept as a value type so Riverpod
/// rebuilds only dependents when something actually changes.
class SensorsUiState {
  /// Creates a [SensorsUiState].
  const SensorsUiState({
    this.loading = false,
    this.chassis = const <ChassisSensors>[],
    this.error,
  });

  /// Whether a sensor fetch is currently in flight.
  final bool loading;

  /// Per-chassis sensor telemetry, in `Chassis` collection order.
  final List<ChassisSensors> chassis;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Returns a copy with the given fields overridden.
  SensorsUiState copyWith({
    bool? loading,
    List<ChassisSensors>? chassis,
    String? error,
    bool clearError = false,
  }) =>
      SensorsUiState(
        loading: loading ?? this.loading,
        chassis: chassis ?? this.chassis,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() =>
      'SensorsUiState(loading=$loading, chassis=${chassis.length}, error=$error)';
}

/// Riverpod controller driving the sensor monitoring screen (issue #007).
///
/// Responsibilities:
///  * call [SensorsService.fetchAll] to populate [SensorsUiState.chassis],
///  * expose a `loading` flag and a friendly [error] string,
///  * guard against overlapping loads and writes after dispose (mirrors
///    [PowerController]).
class SensorsController extends StateNotifier<SensorsUiState> {
  /// Creates a [SensorsController].
  SensorsController(
      {required this.service, this.initialState = const SensorsUiState()})
      : super(initialState);

  /// The sensor service used to read chassis telemetry.
  final SensorsService service;

  /// Initial UI state (typically empty until the first [load]).
  final SensorsUiState initialState;

  /// Pulls fresh sensor telemetry, updating [state] as loading → data / error.
  ///
  /// On a [RedfishException] the message is recorded; other exceptions are
  /// stringified. All state writes are guarded by `mounted` so an in-flight
  /// fetch that outlives the widget does not touch a disposed notifier.
  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<ChassisSensors> all = await service.fetchAll();
      if (mounted) state = state.copyWith(loading: false, chassis: all);
    } on RedfishException catch (e) {
      if (mounted) state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      if (mounted) state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
