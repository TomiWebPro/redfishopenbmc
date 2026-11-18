/// Pure-UI KVM console session lifecycle (issue #009).
///
/// A "console session" is a client-side record of which manager's remote
/// console the operator opened and when. It is deliberately decoupled from the
/// Redfish auth session: it holds no [RedfishClient] and makes no wire calls.
/// The session survives the app being backgrounded and ends only on an
/// explicit [KvmSessionController.disconnect] or when a single-session BMC
/// evicts it by a newer [KvmSessionController.connect].
library;

import 'dart:ui' show AppLifecycleState;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether [state] means the app (and therefore the console view) is
/// backgrounded. Mirrors the sensors polling rule so the two screens agree on
/// what "backgrounded" means.
///
/// Backgrounding never ends a console session — it only flips the
/// [KvmSessionState.backgrounded] flag — because a BMC console persists until
/// its own timeout or an explicit disconnect (issue #009).
bool isKvmAppBackgrounded(AppLifecycleState state) =>
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.hidden ||
    state == AppLifecycleState.detached;

/// Immutable state of the single active console session.
class KvmSessionState {
  /// Creates a session state.
  const KvmSessionState({
    this.activeManagerId,
    this.connectedSince,
    this.backgrounded = false,
    this.log = const <String>[],
  });

  /// The manager whose console is currently open, or `null` when disconnected.
  final String? activeManagerId;

  /// Wall-clock time the active session was opened, or `null` if none.
  final DateTime? connectedSince;

  /// Whether the app was last observed in a backgrounded lifecycle state.
  final bool backgrounded;

  /// Newest-last audit trail of session events (bounded by the controller).
  final List<String> log;

  /// Whether a console session is currently active.
  bool get isConnected => activeManagerId != null && connectedSince != null;

  /// How long the current session has been open at [now], or `null` when
  /// disconnected. Useful for a "connected for …" UI hint without a timer.
  Duration? elapsed(DateTime now) =>
      connectedSince == null ? null : now.difference(connectedSince!);

  /// Returns a copy with the given fields overridden.
  KvmSessionState copyWith({
    String? activeManagerId,
    DateTime? connectedSince,
    bool? backgrounded,
    List<String>? log,
    bool clearSession = false,
  }) =>
      KvmSessionState(
        activeManagerId:
            clearSession ? null : (activeManagerId ?? this.activeManagerId),
        connectedSince:
            clearSession ? null : (connectedSince ?? this.connectedSince),
        backgrounded: backgrounded ?? this.backgrounded,
        log: log ?? this.log,
      );
}

/// Riverpod state notifier for the pure-UI console session (issue #009).
///
/// Injected [clock] keeps `connectedSince` deterministic in tests. No Redfish
/// client is ever passed in: connecting, disconnecting and lifecycle changes
/// are local state transitions only.
class KvmSessionController extends StateNotifier<KvmSessionState> {
  /// Creates a disconnected session controller.
  KvmSessionController({DateTime Function()? clock})
      : now = clock ?? DateTime.now,
        super(const KvmSessionState());

  /// Maximum number of retained log lines (bounds memory over long sessions).
  static const int maxLogEntries = 50;

  /// Wall-clock source, injectable in tests.
  final DateTime Function() now;

  /// Opens a console session for [managerId].
  ///
  /// When a different manager is already active and the new console reports a
  /// single concurrent session ([maxConcurrentSessions] == 1), the previous
  /// session is recorded as evicted. Reconnecting the same manager, or a
  /// console that allows multiple sessions, is not an eviction.
  void connect(String managerId, {int? maxConcurrentSessions}) {
    final String id = managerId.trim();
    if (id.isEmpty) return;

    final String? previous = state.activeManagerId;
    final List<String> log = List<String>.from(state.log);
    if (previous != null && previous != id && maxConcurrentSessions == 1) {
      log.add('Evicted console session for manager "$previous" on connect '
          'to "$id" (single-session console).');
    }
    log.add('Connected console session for manager "$id".');

    state = KvmSessionState(
      activeManagerId: id,
      connectedSince: now(),
      backgrounded: state.backgrounded,
      log: _bounded(log),
    );
  }

  /// Ends the active session. Pure UI state: no Redfish call is made.
  ///
  /// A no-op when no session is active (so repeated taps do not spam the log).
  void disconnect() {
    final String? current = state.activeManagerId;
    if (current == null) return;
    final List<String> log = List<String>.from(state.log)
      ..add('Disconnected console session for manager "$current".');
    state = KvmSessionState(
      backgrounded: state.backgrounded,
      log: _bounded(log),
    );
  }

  /// Records an app lifecycle change.
  ///
  /// The session is intentionally left untouched on background: the BMC
  /// console persists until its timeout or an explicit disconnect (issue
  /// #009). Only the [KvmSessionState.backgrounded] flag follows the lifecycle.
  void onAppLifecycle(AppLifecycleState lifecycle) {
    final bool backgrounded = isKvmAppBackgrounded(lifecycle);
    if (backgrounded == state.backgrounded) return;
    state = state.copyWith(backgrounded: backgrounded);
  }

  List<String> _bounded(List<String> log) => log.length <= maxLogEntries
      ? log
      : log.sublist(log.length - maxLogEntries);
}

/// Injectable wall-clock source for [kvmSessionProvider] (override in tests).
final Provider<DateTime Function()> kvmSessionClockProvider =
    Provider<DateTime Function()>((Ref ref) => DateTime.now);

/// The single active console session for the app (issue #009).
final StateNotifierProvider<KvmSessionController, KvmSessionState>
    kvmSessionProvider =
    StateNotifierProvider<KvmSessionController, KvmSessionState>(
  (Ref ref) => KvmSessionController(clock: ref.watch(kvmSessionClockProvider)),
);
