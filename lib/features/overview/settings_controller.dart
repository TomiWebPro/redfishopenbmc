import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/overview/models/boot_settings.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/settings_service.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Immutable UI state for the system-settings (Boot/IndicatorLED) controls
/// (issue #016).
///
/// Tracks the current [BootSettings], the last applied [IndicatorLed], whether
/// a PATCH is in flight, and the most recent error message. Kept as a value
/// type so Riverpod rebuilds only dependents when something actually changes.
class SystemSettingsUiState {
  /// Creates a [SystemSettingsUiState].
  const SystemSettingsUiState({
    this.bootSettings,
    this.indicatorLed,
    this.actionInFlight = false,
    this.error,
  });

  /// Current boot settings, or `null` when not loaded / not exposed.
  final BootSettings? bootSettings;

  /// Last indicator LED state read from the system (or optimistically applied).
  final IndicatorLed? indicatorLed;

  /// Whether a PATCH request is currently being sent.
  final bool actionInFlight;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Whether a boot-override PATCH is in flight (distinct from [error] so the
  /// UI can disable only the control being operated).
  bool get bootBusy => actionInFlight;

  /// Returns a copy with the given fields overridden.
  SystemSettingsUiState copyWith({
    BootSettings? bootSettings,
    IndicatorLed? indicatorLed,
    bool? actionInFlight,
    String? error,
    bool clearError = false,
  }) =>
      SystemSettingsUiState(
        bootSettings: bootSettings ?? this.bootSettings,
        indicatorLed: indicatorLed ?? this.indicatorLed,
        actionInFlight: actionInFlight ?? this.actionInFlight,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() =>
      'SystemSettingsUiState(boot=$bootSettings, led=$indicatorLed, '
      'inFlight=$actionInFlight, error=$error)';
}

/// Riverpod controller driving the Boot / IndicatorLED controls (issue #016).
///
/// Responsibilities:
///  * load the [BootSettings] via [SystemSettingsService.fetchBootSettings],
///  * issue IndicatorLED PATCHes ([setIndicatorLed]) and boot-override PATCHes
///    ([setBootOverride]) with optimistic local state on success,
///  * surface a single [error] message on failure (the service already
///    pre-validates, so most errors are transport / permission failures).
class SystemSettingsController extends StateNotifier<SystemSettingsUiState> {
  /// Creates a [SystemSettingsController].
  SystemSettingsController({
    required this.service,
    this.initialState = const SystemSettingsUiState(),
  }) : super(initialState);

  /// The settings service used for reads and PATCH mutations.
  final SystemSettingsService service;

  /// Initial UI state (defaults to an empty, idle state).
  final SystemSettingsUiState initialState;

  /// Loads the boot settings, updating [SystemSettingsUiState.bootSettings].
  ///
  /// On failure the error is recorded (the caller can surface it inline) and
  /// the previous settings are kept.
  Future<void> loadBootSettings() async {
    try {
      final BootSettings settings = await service.fetchBootSettings();
      if (mounted) {
        state = state.copyWith(bootSettings: settings, clearError: true);
      }
    } on RedfishException catch (e) {
      if (mounted) state = state.copyWith(error: e.message);
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
    }
  }

  /// PATCHes [value] as the ComputerSystem `IndicatorLED`.
  ///
  /// Success updates [SystemSettingsUiState.indicatorLed] optimistically; a
  /// validation or transport error is recorded and the state is left unchanged
  /// (the LED shown stays the last known value).
  Future<void> setIndicatorLed(IndicatorLed value) async {
    state = state.copyWith(actionInFlight: true, clearError: true);
    try {
      await service.setIndicatorLed(value);
      if (mounted) {
        state = state.copyWith(
          actionInFlight: false,
          indicatorLed: value,
          clearError: true,
        );
      }
    } on RedfishException catch (e) {
      if (mounted) {
        state = state.copyWith(actionInFlight: false, error: e.message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(actionInFlight: false, error: e.toString());
      }
    }
  }

  /// PATCHes a boot override to [target] with [enabled] state.
  ///
  /// On success the boot settings are refreshed so the shown target/enabled
  /// reflect the BMC (the optimistic update only touches the LED, whose value
  /// the service cannot echo back).
  Future<void> setBootOverride({
    required String target,
    String enabled = 'Once',
  }) async {
    state = state.copyWith(actionInFlight: true, clearError: true);
    try {
      await service.setBootOverride(target: target, enabled: enabled);
      if (!mounted) return;
      state = state.copyWith(actionInFlight: false, clearError: true);
      await loadBootSettings();
    } on RedfishException catch (e) {
      if (mounted) {
        state = state.copyWith(actionInFlight: false, error: e.message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(actionInFlight: false, error: e.toString());
      }
    }
  }
}