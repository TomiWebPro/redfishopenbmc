// EP-U4-closeout (issues #009 / #021): the pure-UI console session controller
// (`lib/features/kvm/kvm_session.dart`) owns three operator-visible contracts
// that the existing `kvm_session_test.dart` never pins:
//
//  1. The audit log is BOUNDED, and when it overflows it must retain the NEWEST
//     events (the most recent connect / single-session eviction), not the
//     oldest. A `sublist(0, max)` bug would pass the existing length-only test
//     while silently discarding exactly the lines an operator needs.
//  2. The manager id is the eviction/session key, so it must be TRIMMED on
//     connect: a padded BMC id must not create a phantom distinct session or a
//     spurious single-session eviction, and log lines must carry the clean id.
//  3. The `backgrounded` lifecycle flag must survive a reconnect to a different
//     manager — the app does not leave the background when a console is opened.
//
// These are regression guards at genuinely untested seams of a live path (the
// viewer calls `connect` in `initState`). Pure unit tests: no BMC, no URL opened,
// no WebView / protocol dependency, no TLS change (production TLS untouched).
library;

import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_session.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 11, 21, 1, 0, 0);

  group('KvmSessionController audit/identity invariants (EP-U4, #009/#021)',
      () {
    test('a bounded overflowing log keeps the newest events, drops the oldest',
        () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      final int max = KvmSessionController.maxLogEntries;

      // One more connect than the cap so the oldest lines must be dropped.
      for (int i = 0; i <= max; i++) {
        c.connect('BMC$i');
      }

      expect(c.state.log, hasLength(max));
      // 51 connects (i = 0..max) leave exactly the last 50 (i = 1..max): the
      // newest connect survives, the oldest (BMC0) is dropped. Quoted ids make
      // the match exact so 'BMC1' cannot be confused with 'BMC10' etc.
      expect(c.state.log.last, contains('"BMC$max"'));
      expect(c.state.log.first, contains('"BMC1"'));
      expect(c.state.log[max - 2], contains('"BMC${max - 1}"'));
      expect(
          c.state.log.any((String line) => line.contains('"BMC0"')), isFalse);
      expect(c.state.activeManagerId, 'BMC$max');
    });

    test('a padded manager id is normalized, not a phantom distinct session',
        () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      // A padded spelling of the SAME manager must not be treated as a new
      // manager — even under a single-session limit, no eviction may be logged.
      c.connect('  BMC  ', maxConcurrentSessions: 1);

      expect(c.state.activeManagerId, 'BMC');
      expect(c.state.log, hasLength(2));
      expect(
        c.state.log.any((String line) => line.contains('Evicted')),
        isFalse,
      );
      // The clean id is used in the log line, never the whitespace-bearing one.
      expect(c.state.log.last, contains('"BMC"'));
      expect(c.state.log.last.contains(' BMC'), isFalse);
    });

    test('single-session eviction keys on the trimmed id with clean log ids',
        () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.connect('  BMC2\t', maxConcurrentSessions: 1);

      expect(c.state.activeManagerId, 'BMC2');
      expect(c.state.log, hasLength(3));
      final String eviction = c.state.log[1];
      expect(eviction, contains('Evicted'));
      expect(eviction, contains('"BMC"'));
      expect(eviction, contains('"BMC2"'));
      expect(eviction.contains(' BMC2'), isFalse);
    });

    test('the backgrounded flag survives a reconnect to a new manager', () {
      final KvmSessionController c = KvmSessionController(clock: () => t0);
      c.connect('BMC');
      c.onAppLifecycle(AppLifecycleState.hidden);
      expect(c.state.backgrounded, isTrue);

      c.connect('BMC2', maxConcurrentSessions: 4);

      expect(c.state.activeManagerId, 'BMC2');
      expect(c.state.isConnected, isTrue);
      // Opening a console does not mean the app left the background.
      expect(c.state.backgrounded, isTrue);
    });
  });
}
