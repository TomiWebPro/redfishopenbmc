import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/power/models/power_state.dart';
import 'package:redfishopenbmc/features/power/power_service.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Immutable UI state for the power management screen (issue #005).
///
/// Tracks the live [PowerState] (including the optimistic transitional states
/// used while a reset is settling), whether an action is in flight, the last
/// [ResetType] issued, and the most recent error message. Kept as a value type
/// so Riverpod rebuilds only dependents when something actually changes.
class PowerUiState {
  /// Creates a [PowerUiState].
  const PowerUiState({
    this.powerState = PowerState.unknown,
    this.actionInFlight = false,
    this.error,
    this.lastAction,
  });

  /// Current (or optimistically projected) power state.
  final PowerState powerState;

  /// Whether a reset request is currently being sent / settling.
  final bool actionInFlight;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// The most recent [ResetType] the operator requested.
  final ResetType? lastAction;

  /// Returns a copy with the given fields overridden.
  PowerUiState copyWith({
    PowerState? powerState,
    bool? actionInFlight,
    String? error,
    bool clearError = false,
    ResetType? lastAction,
  }) =>
      PowerUiState(
        powerState: powerState ?? this.powerState,
        actionInFlight: actionInFlight ?? this.actionInFlight,
        error: clearError ? null : (error ?? this.error),
        lastAction: lastAction ?? this.lastAction,
      );

  @override
  String toString() =>
      'PowerUiState(state=$powerState, inFlight=$actionInFlight, '
      'error=$error, last=$lastAction)';
}

/// Riverpod controller driving the power management screen.
///
/// Responsibilities:
///  * gate unsupported reset types locally (mirrors [PowerService]),
///  * issue the reset through [PowerService] and project an optimistic
///    [PowerState] immediately,
///  * poll the ComputerSystem resource every [pollInterval] until the state
///    stabilizes (`on` / `off`) or [pollTimeout] elapses — without blocking the
///    UI (the badge animates via [PowerUiState.powerState]).
class PowerController extends StateNotifier<PowerUiState> {
  /// Creates a [PowerController].
  PowerController({
    required this.service,
    this.features,
    this.initialState = const PowerUiState(),
    this.pollInterval = const Duration(seconds: 3),
    this.pollTimeout = const Duration(seconds: 30),
  }) : super(initialState);

  /// The power service used to issue resets / read state.
  final PowerService service;

  /// Discovered capability map (used to gate unsupported reset types).
  final SystemFeatures? features;

  /// Initial UI state (typically projected from the live [SystemSnapshot]).
  final PowerUiState initialState;

  /// Polling cadence while waiting for the power state to settle.
  final Duration pollInterval;

  /// Maximum time to keep polling before giving up (state stays optimistic).
  final Duration pollTimeout;

  /// Guards against overlapping poll loops.
  bool _polling = false;

  /// Issues [type] and begins tracking the transition.
  ///
  /// On an unsupported type the error is recorded and nothing is sent. On a
  /// transport error the error is recorded and the optimistic state reverts to
  /// [PowerState.unknown] so the badge stops pulsing. Success kicks off the
  /// background poll loop; the returned future resolves as soon as the request
  /// completes (the poll loop continues independently and never blocks the UI).
  Future<void> reset(ResetType type) async {
    final List<String> allowed = features?.supportedResetTypes ?? <String>[];
    if (allowed.isNotEmpty && !allowed.contains(type.toRedfish())) {
      state = state.copyWith(
        error:
            'Reset type ${type.toRedfish()} is not supported by this system.',
        lastAction: type,
      );
      return;
    }

    state = state.copyWith(
      actionInFlight: true,
      clearError: true,
      lastAction: type,
      powerState: type.optimisticState,
    );

    try {
      await service.reset(type);
    } on RedfishException catch (e) {
      state = state.copyWith(
        actionInFlight: false,
        error: e.message,
        powerState: PowerState.unknown,
      );
      return;
    } catch (e) {
      state = state.copyWith(
        actionInFlight: false,
        error: e.toString(),
        powerState: PowerState.unknown,
      );
      return;
    }

    state = state.copyWith(actionInFlight: false);
    _startPolling();
  }

  /// Re-reads the current power state once (e.g. on pull-to-refresh).
  Future<void> refresh() async {
    try {
      final PowerState s = await service.fetchPowerState();
      if (mounted) state = state.copyWith(powerState: s, clearError: true);
    } on RedfishException catch (e) {
      if (mounted) state = state.copyWith(error: e.message);
    }
  }

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    () async {
      final DateTime deadline = DateTime.now().add(pollTimeout);
      while (DateTime.now().isBefore(deadline)) {
        // Yield to the event loop / UI between polls.
        await Future<void>.delayed(pollInterval);
        if (!mounted) {
          _polling = false;
          return;
        }
        try {
          final PowerState s = await service.fetchPowerState();
          if (!mounted) {
            _polling = false;
            return;
          }
          state = state.copyWith(powerState: s);
          if (s == PowerState.on || s == PowerState.off) break;
        } on RedfishException {
          // Transient read failure: keep the optimistic state and keep trying.
        }
      }
      _polling = false;
    }();
  }

  @override
  void dispose() {
    _polling = false;
    super.dispose();
  }
}
