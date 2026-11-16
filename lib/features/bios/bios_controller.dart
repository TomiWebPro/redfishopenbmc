import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/features/bios/bios_service.dart';
import 'package:redfishopenbmc/features/bios/models/bios_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Immutable UI state for the BIOS / settings screen (issue #028, read-only
/// slice).
class BiosUiState {
  /// Creates a [BiosUiState].
  const BiosUiState({
    this.loading = false,
    this.current,
    this.pending,
    this.error,
  });

  /// Whether BIOS data is currently being fetched.
  final bool loading;

  /// Current BIOS resource, or `null` before the first successful load.
  final BiosResource? current;

  /// Pending settings resource, or `null` when none is advertised/fetched.
  final BiosPendingSettings? pending;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Returns a copy with the given fields overridden.
  BiosUiState copyWith({
    bool? loading,
    BiosResource? current,
    BiosPendingSettings? pending,
    bool clearPending = false,
    String? error,
    bool clearError = false,
  }) =>
      BiosUiState(
        loading: loading ?? this.loading,
        current: current ?? this.current,
        pending: clearPending ? null : (pending ?? this.pending),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() =>
      'BiosUiState(loading=$loading, hasCurrent=${current != null}, '
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
}
