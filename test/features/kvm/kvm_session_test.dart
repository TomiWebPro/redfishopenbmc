/// Tests for the pure-UI KVM console session lifecycle (issue #009).
///
/// A console session is a client-side concept: it records which manager's
/// console the operator opened and when, survives the app being backgrounded,
/// and ends only on an explicit disconnect (or when a single-session BMC
/// evicts it). No Redfish call is made — the controller holds no client at all.
library;

import 'dart:ui' show AppLifecycleState;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_session.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 11, 18, 9, 0, 0);

  group('isKvmAppBackgrounded', () {
    test('paused, hidden and detached are backgrounded', () {
      expect(isKvmAppBackgrounded(AppLifecycleState.paused), isTrue);
      expect(isKvmAppBackgrounded(AppLifecycleState.hidden), isTrue);
      expect(isKvmAppBackgrounded(AppLifecycleState.detached), isTrue);
    });

    test('resumed and inactive keep the visible/session-alive cadence', () {
      expect(isKvmAppBackgrounded(AppLifecycleState.resumed), isFalse);
      expect(isKvmAppBackgrounded(AppLifecycleState.inactive), isFalse);
    });
  });

  group('KvmSessionState', () {
    test('starts disconnected with an empty log', () {
      const KvmSessionState state = KvmSessionState();
      expect(state.isConnected, isFalse);
      expect(state.activeManagerId, isNull);
      expect(state.connectedSince, isNull);
      expect(state.backgrounded, isFalse);
      expect(state.log, isEmpty);
    });

    test('elapsed returns null when not connected and the span when it is', () {
      const KvmSessionState idle = KvmSessionState();
      expect(idle.elapsed(t0), isNull);

      final KvmSessionState connected = KvmSessionState(
        activeManagerId: 'BMC',
        connectedSince: t0,
      );
      expect(connected.elapsed(t0.add(const Duration(seconds: 37))),
          const Duration(seconds: 37));
    });
  });

  group('KvmSessionController', () {
    test('connect records the manager id and the injected clock time', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');

      expect(c.state.isConnected, isTrue);
      expect(c.state.activeManagerId, 'BMC');
      expect(c.state.connectedSince, t0);
      expect(c.state.log, hasLength(1));
      expect(c.state.log.single, contains('BMC'));
      expect(c.state.log.single, contains('Connected'));
    });

    test('connect rejects an empty manager id without changing state', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.connect('   ');

      expect(c.state.activeManagerId, 'BMC');
      expect(c.state.log, hasLength(1));
    });

    test('disconnect clears the session and logs, with no Redfish call', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.disconnect();

      expect(c.state.isConnected, isFalse);
      expect(c.state.activeManagerId, isNull);
      expect(c.state.connectedSince, isNull);
      expect(c.state.log, hasLength(2));
      expect(c.state.log.last, contains('Disconnected'));
      expect(c.state.log.last, contains('BMC'));
      // The controller takes no RedfishClient and holds no service — a console
      // session is pure UI state, so disconnect cannot reach the wire at all.
    });

    test('disconnect with no active session is a safe no-op', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.disconnect();
      expect(c.state.log, isEmpty);
      expect(c.state.isConnected, isFalse);
    });

    test('backgrounding keeps the session alive and flags backgrounded', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.onAppLifecycle(AppLifecycleState.paused);

      expect(c.state.isConnected, isTrue);
      expect(c.state.activeManagerId, 'BMC');
      expect(c.state.connectedSince, t0);
      expect(c.state.backgrounded, isTrue);
      // Backgrounding is not a session event — no log spam.
      expect(c.state.log, hasLength(1));
    });

    test('hidden and detached also keep the session alive', () {
      for (final AppLifecycleState state in <AppLifecycleState>[
        AppLifecycleState.hidden,
        AppLifecycleState.detached,
      ]) {
        final KvmSessionController c = KvmSessionController(clock: () => t0);
        c.connect('BMC');
        c.onAppLifecycle(state);
        expect(c.state.isConnected, isTrue, reason: 'state=$state');
      }
    });

    test('resuming clears backgrounded but keeps the same session', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.onAppLifecycle(AppLifecycleState.hidden);
      c.onAppLifecycle(AppLifecycleState.resumed);

      expect(c.state.isConnected, isTrue);
      expect(c.state.connectedSince, t0);
      expect(c.state.backgrounded, isFalse);
    });

    test('repeated lifecycle notifications are no-ops', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.onAppLifecycle(AppLifecycleState.paused);
      c.onAppLifecycle(AppLifecycleState.paused);
      c.onAppLifecycle(AppLifecycleState.hidden);

      expect(c.state.backgrounded, isTrue);
      expect(c.state.log, hasLength(1));
    });

    test(
        'connecting a second manager to a single-session console evicts '
        'the first session', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.connect('BMC2', maxConcurrentSessions: 1);

      expect(c.state.activeManagerId, 'BMC2');
      expect(c.state.connectedSince, t0);
      expect(c.state.log, hasLength(3));
      expect(c.state.log[1], contains('Evicted'));
      expect(c.state.log[1], contains('BMC'));
    });

    test('connecting to a multi-session console does not log an eviction', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.connect('BMC2', maxConcurrentSessions: 4);

      expect(c.state.activeManagerId, 'BMC2');
      expect(c.state.log, hasLength(2));
      expect(c.state.log.last, contains('Connected'));
      expect(
          c.state.log.any((String line) => line.contains('Evicted')), isFalse);
    });

    test('reconnecting the same manager is not an eviction', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.connect('BMC', maxConcurrentSessions: 1);

      expect(c.state.log, hasLength(2));
      expect(
          c.state.log.any((String line) => line.contains('Evicted')), isFalse);
    });

    test('the session log is bounded', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      for (int i = 0; i < KvmSessionController.maxLogEntries + 15; i++) {
        c.connect('BMC');
      }
      expect(c.state.log.length, KvmSessionController.maxLogEntries);
    });
  });

  group('kvmSessionProvider', () {
    test('uses the injected clock via the clock provider override', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          kvmSessionClockProvider.overrideWithValue(() => t0),
        ],
      );
      addTearDown(container.dispose);

      final KvmSessionController c =
          container.read(kvmSessionProvider.notifier);
      c.connect('BMC');

      expect(container.read(kvmSessionProvider).connectedSince, t0);
    });
  });
}
