import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/sensors/models/reading_history.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Immutable UI state for the sensor monitoring screen (issue #007).
///
/// Tracks the per-chassis [ChassisSensors] lists, an in-flight [loading] flag,
/// the most recent [error] message, and an immutable snapshot of per-sensor
/// reading [history] (ring buffers) used to draw sparklines. Kept as a value
/// type so Riverpod rebuilds only dependents when something actually changes.
class SensorsUiState {
  /// Creates a [SensorsUiState].
  const SensorsUiState({
    this.loading = false,
    this.chassis = const <ChassisSensors>[],
    this.error,
    this.history = const <String, List<double>>{},
    this.lastUpdated,
  });

  /// Whether a sensor fetch is currently in flight.
  final bool loading;

  /// Per-chassis sensor telemetry, in `Chassis` collection order.
  final List<ChassisSensors> chassis;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Per-sensor recent-reading series (key → oldest-first samples).
  final Map<String, List<double>> history;

  /// Wall-clock time of the last *successful* poll (issue #007 "last-updated
  /// timestamp"). `null` until the first fetch succeeds, and left untouched by
  /// a failed poll so the stamp never claims stale data is fresh.
  final DateTime? lastUpdated;

  /// Returns a copy with the given fields overridden.
  SensorsUiState copyWith({
    bool? loading,
    List<ChassisSensors>? chassis,
    String? error,
    Map<String, List<double>>? history,
    DateTime? lastUpdated,
    bool clearError = false,
  }) =>
      SensorsUiState(
        loading: loading ?? this.loading,
        chassis: chassis ?? this.chassis,
        error: clearError ? null : (error ?? this.error),
        history: history ?? this.history,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @override
  String toString() =>
      'SensorsUiState(loading=$loading, chassis=${chassis.length}, '
      'series=${history.length}, lastUpdated=$lastUpdated, error=$error)';
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
  ///
  /// [clock] is injectable so the "last updated" stamp can be pinned in tests.
  SensorsController({
    required this.service,
    this.initialState = const SensorsUiState(),
    DateTime Function()? clock,
  })  : now = clock ?? DateTime.now,
        super(initialState);

  /// The sensor service used to read chassis telemetry.
  final SensorsService service;

  /// Initial UI state (typically empty until the first [load]).
  final SensorsUiState initialState;

  /// Wall-clock source for the successful-poll timestamp (injectable in tests).
  final DateTime Function() now;

  /// Accumulates per-sensor reading ring buffers across successful polls.
  final SensorHistoryStore _history = SensorHistoryStore();

  /// Fingerprint of the last published telemetry, for delta rebuilds (#007).
  String? _lastFingerprint;

  /// Pulls fresh sensor telemetry, updating [state] as loading → data / error.
  ///
  /// On a [RedfishException] the message is recorded; other exceptions are
  /// stringified. All state writes are guarded by `mounted` so an in-flight
  /// fetch that outlives the widget does not touch a disposed notifier. Each
  /// successful poll also appends a sample to every sensor's history (issue
  /// #007 — sparkline ring buffer).
  ///
  /// Delta rebuild (issue #007): when a poll's [telemetryFingerprint] matches
  /// the previous one, the already-published `chassis` list instance is reused
  /// so unchanged tiles are not handed new data. The sparkline history still
  /// advances every poll, so a flat sensor's trend keeps growing.
  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<ChassisSensors> all = await service.fetchAll();
      final String fingerprint = telemetryFingerprint(all);
      final bool dataChanged = fingerprint != _lastFingerprint;
      _lastFingerprint = fingerprint;
      _history.record(all);
      if (mounted) {
        state = state.copyWith(
          loading: false,
          chassis: dataChanged ? all : state.chassis,
          history: _history.snapshot(),
          // Stamp *every* successful poll, including a delta poll whose
          // readings did not change — the timestamp means "last checked",
          // not "last changed". Failed polls leave the previous stamp intact.
          lastUpdated: now(),
        );
      }
    } on RedfishException catch (e) {
      if (mounted) state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      if (mounted) state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
