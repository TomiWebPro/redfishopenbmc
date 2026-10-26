import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Immutable UI state for the firmware & update screen (issue #008).
///
/// Tracks whether an operation is in flight ([loading]), whether a
/// `SimpleUpdate` is specifically being submitted ([starting]), whether the
/// returned task monitor is being polled ([polling]), the latest
/// [UpdateServiceInfo] snapshot, the most recent queued [lastTask] handle,
/// the polled [lastResult] (when the task reached a terminal state), the
/// progress of an in-flight binary push upload ([uploadProgress]), and the
/// most recent [error] message. Kept as a value type so Riverpod rebuilds
/// only dependents when something actually changes.
class FirmwareUiState {
  /// Creates a [FirmwareUiState].
  const FirmwareUiState({
    this.loading = false,
    this.starting = false,
    this.polling = false,
    this.uploading = false,
    this.uploadProgress,
    this.info,
    this.lastTask,
    this.lastResult,
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

  /// Whether a binary push upload ([FirmwareController.pushImage]) is
  /// currently in flight (issue #008/#020 — binary/multipart upload).
  ///
  /// Distinct from [starting] so an upload-in-progress UI (progress bar +
  /// disabled controls) does not imply a `SimpleUpdate` submission.
  final bool uploading;

  /// Upload progress (sent/total bytes) of the in-flight push upload, or
  /// `null` when no upload is in flight / no progress has been reported yet.
  ///
  /// Consumed by a future upload-progress UI (#008/#020); the [pollTask]
  /// path reports task-level progress via [RedfishTask.percentComplete]
  /// instead.
  final ({int sent, int total})? uploadProgress;

  /// Whether the task monitor returned by the last `SimpleUpdate` is being
  /// polled (issue #022 criterion 1 — 202 task-monitor polling).
  ///
  /// Raised while [pollLastTask] runs and the monitor has not yet reached a
  /// terminal state; cleared when it completes or fails.
  final bool polling;

  /// The latest [UpdateServiceInfo] snapshot, or `null` before the first load.
  final UpdateServiceInfo? info;

  /// The [UpdateTask] handle returned by the most recent `SimpleUpdate`
  /// (task monitor URI + optional `Retry-After`), or `null`.
  final UpdateTask? lastTask;

  /// The final [RedfishTask] read from the task monitor once the task
  /// reached a terminal state, or `null` while queued / not yet polled.
  final RedfishTask? lastResult;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Returns a copy with the given fields overridden.
  FirmwareUiState copyWith({
    bool? loading,
    bool? starting,
    bool? polling,
    bool? uploading,
    ({int sent, int total})? uploadProgress,
    bool clearUploadProgress = false,
    UpdateServiceInfo? info,
    UpdateTask? lastTask,
    bool clearLastTask = false,
    RedfishTask? lastResult,
    bool clearLastResult = false,
    String? error,
    bool clearError = false,
  }) =>
      FirmwareUiState(
        loading: loading ?? this.loading,
        starting: starting ?? this.starting,
        polling: polling ?? this.polling,
        uploading: uploading ?? this.uploading,
        uploadProgress:
            clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
        info: info ?? this.info,
        lastTask: clearLastTask ? null : (lastTask ?? this.lastTask),
        lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() => 'FirmwareUiState(loading=$loading, starting=$starting, '
      'polling=$polling, uploading=$uploading, '
      'uploadProgress=$uploadProgress, info=${info != null}, '
      'lastTask=$lastTask, lastResult=$lastResult, error=$error)';
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
      clearLastResult: true,
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

  /// Pushes a local firmware image via [FirmwareService.pushImage]
  /// (issue #008/#020 — binary/multipart upload).
  ///
  /// Raises [FirmwareUiState.uploading] for the duration of the upload,
  /// forwards byte-level progress to [FirmwareUiState.uploadProgress]
  /// (sent/total), and on success stores the returned [UpdateTask] handle in
  /// [FirmwareUiState.lastTask] (exactly like [startUpdate], so the existing
  /// queued/polled banner + poller cover the async task). On failure the
  /// error is recorded.
  ///
  /// [interval]/[maxPolls] are not used here — call [pollLastTask] after a
  /// successful upload when a task monitor URI was returned.
  Future<void> pushImage(
    PushImageRequest req, {
    void Function(int sent, int total)? onProgress,
  }) async {
    state = state.copyWith(
      loading: true,
      uploading: true,
      clearError: true,
      clearUploadProgress: true,
      clearLastTask: true,
      clearLastResult: true,
    );
    try {
      final UpdateTask task = await service.pushImage(
        req,
        onProgress: (int sent, int total) {
          onProgress?.call(sent, total);
          if (mounted) {
            state = state.copyWith(uploadProgress: (sent: sent, total: total));
          }
        },
      );
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        uploading: false,
        clearUploadProgress: true,
        lastTask: task,
      );
    } on RedfishException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        uploading: false,
        clearUploadProgress: true,
        error: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        uploading: false,
        clearUploadProgress: true,
        error: e.toString(),
      );
    }
  }

  /// Polls the task monitor of the last [FirmwareUiState.lastTask] until the
  /// task reaches a terminal state (issue #022 criterion 1).
  ///
  /// Raises [FirmwareUiState.polling] while polling; on success stores the
  /// final [RedfishTask] in [FirmwareUiState.lastResult]; on failure records
  /// the error. A task with no monitor URI (204-no-Location services) is a
  /// no-op: the queued [FirmwareUiState.lastTask] remains meaning "queued,
  /// no monitor returned", and no error is raised — the caller must not treat
  /// a missing monitor as a failure.
  ///
  /// [interval] and [maxPolls] are forwarded to
  /// [FirmwareService.pollTask] (tests inject a zero interval / small bound).
  Future<void> pollLastTask({
    Duration interval = const Duration(seconds: 2),
    int maxPolls = 30,
  }) async {
    final UpdateTask? task = state.lastTask;
    if (task == null || task.taskUri == null || task.taskUri!.isEmpty) {
      // No monitor to poll (the BMC answered 204 without a Location, or no
      // update was ever queued). The queued label already covers this state.
      return;
    }
    state = state.copyWith(polling: true);
    try {
      final RedfishTask result =
          await service.pollTask(task, interval: interval, maxPolls: maxPolls);
      if (!mounted) return;
      state = state.copyWith(polling: false, lastResult: result);
    } on RedfishException catch (e) {
      if (!mounted) return;
      state = state.copyWith(polling: false, error: e.message);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(polling: false, error: e.toString());
    }
  }
}
