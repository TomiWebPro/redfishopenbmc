import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Immutable UI state for the firmware & update screen (issue #008).
///
/// Tracks whether an operation is in flight ([loading]), whether a
/// `SimpleUpdate` is specifically being submitted ([starting]), the latest
/// [UpdateServiceInfo] snapshot, the most recent queued [lastTask] handle,
/// and the most recent [error] message. Kept as a value type so Riverpod
/// rebuilds only dependents when something actually changes.
class FirmwareUiState {
  /// Creates a [FirmwareUiState].
  const FirmwareUiState({
    this.loading = false,
    this.starting = false,
    this.info,
    this.lastTask,
    this.error,
  });

  /// Whether a load / update operation is currently in flight.
  final bool loading;

  /// Whether a `SimpleUpdate` submission is currently in flight.
  ///
  /// Distinct from [loading] so the Start-update button can show its own busy
  /// state (spinner + disabled) only while the POST is pending, without
  /// implying the whole screen is re-loading.
  final bool starting;

  /// The latest [UpdateServiceInfo] snapshot, or `null` before the first load.
  final UpdateServiceInfo? info;

  /// The [UpdateTask] handle returned by the most recent `SimpleUpdate`
  /// (task monitor URI + optional `Retry-After`), or `null`.
  final UpdateTask? lastTask;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Returns a copy with the given fields overridden.
  FirmwareUiState copyWith({
    bool? loading,
    bool? starting,
    UpdateServiceInfo? info,
    UpdateTask? lastTask,
    bool clearLastTask = false,
    String? error,
    bool clearError = false,
  }) =>
      FirmwareUiState(
        loading: loading ?? this.loading,
        starting: starting ?? this.starting,
        info: info ?? this.info,
        lastTask: clearLastTask ? null : (lastTask ?? this.lastTask),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() => 'FirmwareUiState(loading=$loading, starting=$starting, '
      'info=${info != null}, lastTask=$lastTask, error=$error)';
}

/// Riverpod controller driving the firmware & update screen.
///
/// Responsibilities:
///  * [load] the [UpdateServiceInfo] + inventory through [FirmwareService],
///  * [startUpdate] issue a `SimpleUpdate` and surface the returned task URI
///    (or the error) via [FirmwareUiState].
class FirmwareController extends StateNotifier<FirmwareUiState> {
  /// Creates a [FirmwareController].
  FirmwareController({
    required this.service,
    this.features,
    FirmwareUiState initialState = const FirmwareUiState(),
  }) : super(initialState);

  /// The firmware service used to read state / start updates.
  final FirmwareService service;

  /// Discovered capability map (unused for gating; kept for parity with other
  /// controllers and future protocol negotiation).
  final SystemFeatures? features;

  /// Loads the [UpdateServiceInfo] (including inventory) into state.
  ///
  /// On failure the error is recorded and [loading] returns to `false`; on
  /// success the [info] is populated and any prior error is cleared.
  Future<void> load() async {
    state = state.copyWith(loading: true, starting: false, clearError: true);
    try {
      final UpdateServiceInfo info = await service.fetchUpdateService();
      if (!mounted) return;
      state = state.copyWith(loading: false, info: info);
    } on RedfishException catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Starts a firmware update via [FirmwareService.startSimpleUpdate].
  ///
  /// On success the returned [UpdateTask] handle (task URI + optional
  /// `Retry-After`) is stored in [FirmwareUiState.lastTask] and any prior
  /// error is cleared. On failure the error is recorded. [starting] is raised
  /// for the duration of the POST so the Start-update button can show its own
  /// busy state without implying the whole screen is re-loading.
  Future<void> startUpdate(SimpleUpdateRequest req) async {
    state = state.copyWith(
      loading: true,
      starting: true,
      clearError: true,
      clearLastTask: true,
    );
    try {
      final UpdateTask task = await service.startSimpleUpdate(req);
      if (!mounted) return;
      state = state.copyWith(loading: false, starting: false, lastTask: task);
    } on RedfishException catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, starting: false, error: e.message);
    } catch (e) {
      if (!mounted) return;
      state =
          state.copyWith(loading: false, starting: false, error: e.toString());
    }
  }
}
