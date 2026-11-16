import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/features/bios/bios_service.dart';
import 'package:redfishopenbmc/features/bios/models/bios_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Immutable UI state for the BIOS / settings screen (issue #028).
class BiosUiState {
  /// Creates a [BiosUiState].
  const BiosUiState({
    this.loading = false,
    this.resetting = false,
    this.applying = false,
    this.current,
    this.pending,
    this.error,
  });

  /// Whether BIOS data is currently being fetched.
  final bool loading;

  /// Whether a Reset BIOS to defaults action is in flight.
  final bool resetting;

  /// Whether a BIOS attribute PATCH/apply operation is in flight.
  final bool applying;

  /// Current BIOS resource, or `null` before the first successful load.
  final BiosResource? current;

  /// Pending settings resource, or `null` when none is advertised/fetched.
  final BiosPendingSettings? pending;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Returns a copy with the given fields overridden.
  BiosUiState copyWith({
    bool? loading,
    bool? resetting,
    bool? applying,
    BiosResource? current,
    BiosPendingSettings? pending,
    bool clearPending = false,
    String? error,
    bool clearError = false,
  }) =>
      BiosUiState(
        loading: loading ?? this.loading,
        resetting: resetting ?? this.resetting,
        applying: applying ?? this.applying,
        current: current ?? this.current,
        pending: clearPending ? null : (pending ?? this.pending),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() =>
      'BiosUiState(loading=$loading, resetting=$resetting, applying=$applying, '
      'hasCurrent=${current != null}, '
      'hasPending=${pending != null}, error=$error)';
}

/// Riverpod controller driving the BIOS screen.
///
/// Fetches current and pending BIOS settings through [BiosService]. Mirrors the
/// read-only pattern of other feature controllers: transport/service errors are
/// captured into [BiosUiState.error] rather than thrown, and the `mounted`
/// guard avoids touching a disposed notifier after an async gap.
class BiosController extends StateNotifier<BiosUiState> {
  /// Creates a [BiosController].
  BiosController({required this.service}) : super(const BiosUiState());

  /// The BIOS service used to fetch data.
  final BiosService service;

  /// Loads the BIOS resource and any pending settings.
  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final ({BiosResource current, BiosPendingSettings? pending}) result =
          await service.fetchBiosWithPending();
      if (mounted) {
        state = BiosUiState(
          loading: false,
          current: result.current,
          pending: result.pending,
        );
      }
    } on RedfishException catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  /// Triggers `#Bios.ResetBios` when advertised on [bios].
  ///
  /// Sets [BiosUiState.resetting] while in flight. On success reloads the BIOS
  /// resource to reflect pending/default state; on failure records the
  /// normalized service error.
  Future<void> resetBios(BiosResource bios) async {
    if (state.resetting || state.applying) return;
    state = state.copyWith(resetting: true, clearError: true);
    try {
      await service.resetBios(bios);
      if (!mounted) return;
      state = state.copyWith(resetting: false);
      await load();
    } on RedfishException catch (e) {
      if (mounted) {
        state = state.copyWith(resetting: false, error: e.message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(resetting: false, error: e.toString());
      }
    }
  }

  /// Applies pending BIOS attribute changes via PATCH to the settings object.
  ///
  /// Sends [attributes] as a partial `Attributes` payload using the
  /// settings-object ETag as `If-Match` when available (service-side). Sets
  /// [BiosUiState.applying] while in flight and reloads on success.
  Future<void> applyPendingAttributes(
    BiosResource bios,
    Map<String, dynamic> attributes,
  ) async {
    if (state.applying || state.resetting) return;
    state = state.copyWith(applying: true, clearError: true);
    try {
      await service.patchPendingAttributes(bios, attributes);
      if (!mounted) return;
      state = state.copyWith(applying: false);
      await load();
    } on RedfishException catch (e) {
      if (mounted) {
        state = state.copyWith(applying: false, error: e.message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(applying: false, error: e.toString());
      }
    }
  }
}
