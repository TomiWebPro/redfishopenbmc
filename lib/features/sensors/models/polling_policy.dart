/// Cadence policy and reschedulable timer for sensor polling (issue #007).
///
/// The policy and scheduler are pure Dart (only `dart:async`) so the "poll fast
/// while visible, back off when backgrounded" rule can be verified without a
/// widget tree or a live binding. A small helper maps Flutter lifecycle states
/// to the visibility flag.
library;

import 'dart:async';
import 'dart:ui' show AppLifecycleState;

/// Whether [state] should use the backed-off polling interval.
///
/// `paused`, `hidden` and `detached` are treated as backgrounded; `resumed`
/// and `inactive` keep the fast visible cadence.
bool isSensorAppBackgrounded(AppLifecycleState state) =>
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.hidden ||
    state == AppLifecycleState.detached;

/// Effective polling cadence for the sensors screen (issue #007).
///
/// While the app/tab is visible sensors are polled at [visibleInterval]
/// (5–10s in the acceptance criteria); once the app is backgrounded the cadence
/// backs off to the slower [hiddenInterval] (30s) to bound load. No production
/// behaviour depends on this beyond timer scheduling — it never changes which
/// endpoint is fetched or how TLS is handled.
class SensorsPollingPolicy {
  /// Creates a policy with a fast visible interval and a slower hidden one.
  const SensorsPollingPolicy({
    required this.visibleInterval,
    this.hiddenInterval = const Duration(seconds: 30),
  });

  /// Polling cadence while the sensors tab is visible.
  final Duration visibleInterval;

  /// Polling cadence while the app is backgrounded / hidden.
  final Duration hiddenInterval;

  /// The interval to use for the given visibility state.
  Duration intervalFor(bool hidden) =>
      hidden ? hiddenInterval : visibleInterval;
}

/// A reschedulable periodic timer that applies a [SensorsPollingPolicy].
///
/// Call [start] to begin ticking at the policy's visible interval, [setHidden]
/// when the app lifecycle changes (restarts the timer at the backed-off
/// interval), and [stop] on dispose. Ticks are deduplicated against the
/// controller's own in-flight guard, so a slow poll can never stack timers.
class SensorsPollingScheduler {
  /// Creates a stopped scheduler that calls [onTick] on every poll tick.
  SensorsPollingScheduler({
    required this.policy,
    required this.onTick,
  });

  /// Cadence policy applied to the timer.
  final SensorsPollingPolicy policy;

  /// Callback invoked on each poll tick.
  final void Function() onTick;

  Timer? _timer;
  bool _running = false;
  bool _hidden = false;

  /// Whether the scheduler is currently ticking.
  bool get isRunning => _running;

  /// Whether the scheduler is currently using the backed-off interval.
  bool get isHidden => _hidden;

  /// Interval currently in effect.
  Duration get currentInterval => policy.intervalFor(_hidden);

  /// Starts ticking (idempotent).
  void start() {
    if (_running) return;
    _running = true;
    _restart();
  }

  /// Stops ticking and cancels any pending timer (idempotent).
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Updates background/foreground visibility, rescheduling if running.
  ///
  /// When the visibility state does not actually change this is a no-op, so
  /// repeated lifecycle notifications never reset the poll phase.
  void setHidden(bool hidden) {
    if (_hidden == hidden) return;
    _hidden = hidden;
    if (_running) _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(currentInterval, (Timer _) => onTick());
  }
}
