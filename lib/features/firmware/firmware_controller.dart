import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Immutable UI state for the firmware & update screen (issue #008).
///
/// Tracks whether an operation is in flight ([loading]), the latest
/// [UpdateServiceInfo] snapshot, the most recent queued [lastTaskUri], and the
/// most recent [error] message. Kept as a value type so Riverpod rebuilds only
/// dependents when something actually changes.
class FirmwareUiState {
  /// Creates a [FirmwareUiState].
  const FirmwareUiState({
    this.loading = false,
    this.info,
    this.lastTaskUri,
    this.error,
  });

  /// Whether a load / update operation is currently in flight.
  final bool loading;

  /// The latest [UpdateServiceInfo] snapshot, or `null` before the first load.
  final UpdateServiceInfo? info;

  /// The task URI returned by the most recent `SimpleUpdate`, or `null`.
  final String? lastTaskUri;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Returns a copy with the given fields overridden.
  FirmwareUiState copyWith({
    bool? loading,
    UpdateServiceInfo? info,
    String? lastTaskUri,
    bool clearLastTaskUri = false,
    String? error,
    bool clearError = false,
  }) =>
      FirmwareUiState(
        loading: loading ?? this.loading,
        info: info ?? this.info,
        lastTaskUri: clearLastTaskUri
            ? null
            : (lastTaskUri ?? this.lastTaskUri),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() =>
      'FirmwareUiState(loading=$loading, info=${info != null}, '
      'lastTaskUri=$lastTaskUri, error=$error)';
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
    state = state.copyWith(loading: true, clearError: true);
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
  /// On success the returned task URI is stored in [FirmwareUiState.lastTaskUri]
  /// and any prior error is cleared. On failure the error is recorded.
  Future<void> startUpdate(SimpleUpdateRequest req) async {
    state = state.copyWith(loading: true, clearError: true, clearLastTaskUri: true);
    try {
      final String taskUri = await service.startSimpleUpdate(req);
      if (!mounted) return;
      state = state.copyWith(loading: false, lastTaskUri: taskUri);
    } on RedfishException catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
