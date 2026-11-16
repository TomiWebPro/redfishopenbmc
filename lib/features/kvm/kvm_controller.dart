import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Immutable UI state for the remote KVM screen (issue #009).
///
/// Tracks whether consoles are loading, the discovered [KvmConsole] list, the
/// preferred primary console, and the most recent error message. Kept as a
/// value type so Riverpod rebuilds only dependents when something actually
/// changes.
class KvmUiState {
  /// Creates a [KvmUiState].
  const KvmUiState({
    this.loading = false,
    this.consoles = const <KvmConsole>[],
    this.primaryConsole,
    this.error,
  });

  /// Whether consoles are currently being fetched.
  final bool loading;

  /// The consoles discovered on the system's managers.
  final List<KvmConsole> consoles;

  /// The preferred console selected by [KvmService.pickPrimary], or `null`.
  final KvmConsole? primaryConsole;

  /// Last error message, or `null` when the last operation succeeded.
  final String? error;

  /// Returns a copy with the given fields overridden.
  KvmUiState copyWith({
    bool? loading,
    List<KvmConsole>? consoles,
    KvmConsole? primaryConsole,
    String? error,
    bool clearError = false,
    bool clearPrimaryConsole = false,
  }) =>
      KvmUiState(
        loading: loading ?? this.loading,
        consoles: consoles ?? this.consoles,
        primaryConsole: clearPrimaryConsole
            ? null
            : (primaryConsole ?? this.primaryConsole),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  String toString() =>
      'KvmUiState(loading=$loading, consoles=${consoles.length}, '
      'primary=${primaryConsole?.type}, error=$error)';
}

/// Riverpod controller driving the remote KVM screen.
///
/// Fetches the consoles through [KvmService] on [load] and exposes them in
/// [KvmUiState]. Mirrors [PowerController]: a not-connected or transport error
/// is captured into [KvmUiState.error] rather than thrown, and the `mounted`
/// guard avoids touching a disposed notifier after an async gap.
class KvmController extends StateNotifier<KvmUiState> {
  /// Creates a [KvmController].
  KvmController({required this.service}) : super(const KvmUiState());

  /// The KVM service used to fetch consoles.
  final KvmService service;

  /// Loads the consoles for the system, updating [KvmUiState] as it goes.
  ///
  /// Sets [KvmUiState.loading] while in flight and records any [RedfishException]
  /// into [KvmUiState.error]. A successful load clears the error and selects the
  /// primary console via [KvmService.pickPrimary].
  Future<void> load() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<KvmConsole> consoles = await service.fetchConsoles();
      if (mounted) {
        state = state.copyWith(
          loading: false,
          consoles: consoles,
          primaryConsole: KvmService.pickPrimary(consoles),
          clearPrimaryConsole: consoles.isEmpty,
        );
      }
    } on RedfishException catch (e) {
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: e.message,
          clearPrimaryConsole: true,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: e.toString(),
          clearPrimaryConsole: true,
        );
      }
    }
  }
}
