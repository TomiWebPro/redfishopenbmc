/// Cross-feature lifecycle-parity guard for the KVM console session (#009/#021,
/// shared with the sensors polling rule #007).
///
/// `isKvmAppBackgrounded` (KVM session lifecycle) exists specifically to
/// "mirror the sensors polling rule so the two screens agree on what
/// 'backgrounded' means". Two independent implementations of that rule now
/// exist — `isKvmAppBackgrounded` here and `isSensorAppBackgrounded` in the
/// sensors polling policy — and nothing fails closed if they drift. A drift
/// would silently desync operator-visible behaviour: the sensors screen would
/// back off polling at one lifecycle threshold while the KVM console session
/// considered itself backgrounded (or not) at a different one.
///
/// This is a machine-checkable, dependency-free, TLS-safe invariant guard: it
/// pins that both predicates agree on EVERY `AppLifecycleState` value, that
/// both still implement the documented contract (paused/hidden/detached are
/// backgrounded; resumed/inactive keep the visible/session-alive cadence), and
/// that both source predicates enumerate the same lifecycle-state members (a
/// source-level "who guards the mirror" check so a one-sided edit cannot slip
/// through). No product code, wire, dependency or production TLS is touched.
library;

import 'dart:io';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_session.dart';
import 'package:redfishopenbmc/features/sensors/models/polling_policy.dart';

/// Every lifecycle state this Flutter/Dart SDK can report. Kept explicit (not
/// `AppLifecycleState.values`) so the pinned contract below is reviewable; a
/// future SDK state is additionally swept by the parity assertion at runtime.
const List<AppLifecycleState> allLifecycleStates = <AppLifecycleState>[
  AppLifecycleState.resumed,
  AppLifecycleState.inactive,
  AppLifecycleState.paused,
  AppLifecycleState.hidden,
  AppLifecycleState.detached,
];

/// Lifecycle states the shared "backgrounded" rule must treat as background.
const Set<AppLifecycleState> backgroundedStates = <AppLifecycleState>{
  AppLifecycleState.paused,
  AppLifecycleState.hidden,
  AppLifecycleState.detached,
};

/// Source path of each predicate, for the structural parity check.
const String kvmSessionSourcePath = 'lib/features/kvm/kvm_session.dart';
const String sensorsPolicySourcePath =
    'lib/features/sensors/models/polling_policy.dart';

/// Extract the `AppLifecycleState.<member>` tokens referenced inside the body
/// of a named top-level predicate (`bool <name>(...) => ...;`), so two
/// independently-authored implementations can be compared structurally.
Set<String> referencedLifecycleMembers(String source, String fnName) {
  final RegExp fn = RegExp(
    r'bool\s+' + RegExp.escape(fnName) + r'\s*\([^)]*\)\s*=>\s*(.*?);',
    dotAll: true,
  );
  final Match? match = fn.firstMatch(source);
  if (match == null) {
    throw StateError('predicate $fnName not found in source');
  }
  return RegExp(r'AppLifecycleState\.([A-Za-z_]\w*)')
      .allMatches(match.group(1)!)
      .map((Match m) => m.group(1)!)
      .toSet();
}

void main() {
  group('cross-feature backgrounded parity (#009/#021 <-> #007)', () {
    test('both predicates agree on every AppLifecycleState value', () {
      for (final AppLifecycleState state in allLifecycleStates) {
        expect(
          isKvmAppBackgrounded(state),
          isSensorAppBackgrounded(state),
          reason: 'KVM session and sensors polling must classify $state '
              'identically (the KVM rule exists to mirror the sensors rule)',
        );
      }
    });

    test('the runtime sweep also covers any newer SDK lifecycle value', () {
      for (final AppLifecycleState state in AppLifecycleState.values) {
        expect(isKvmAppBackgrounded(state), isSensorAppBackgrounded(state),
            reason: 'parity must hold for SDK value $state too');
      }
    });

    test('both predicates pin the documented backgrounded semantics', () {
      for (final AppLifecycleState state in allLifecycleStates) {
        final bool expected = backgroundedStates.contains(state);
        expect(isKvmAppBackgrounded(state), expected,
            reason: 'isKvmAppBackgrounded($state)');
        expect(isSensorAppBackgrounded(state), expected,
            reason: 'isSensorAppBackgrounded($state)');
      }
    });

    test('both source predicates enumerate the same lifecycle members', () {
      final String kvm = File(kvmSessionSourcePath).readAsStringSync();
      final String sensors = File(sensorsPolicySourcePath).readAsStringSync();

      final Set<String> kvmMembers =
          referencedLifecycleMembers(kvm, 'isKvmAppBackgrounded');
      final Set<String> sensorsMembers =
          referencedLifecycleMembers(sensors, 'isSensorAppBackgrounded');

      expect(kvmMembers, isNotEmpty);
      expect(kvmMembers, equals(sensorsMembers),
          reason: 'the KVM mirror must enumerate the same lifecycle states as '
              'the sensors rule the source comment claims it mirrors');
      expect(kvmMembers, equals(<String>{'paused', 'hidden', 'detached'}));
    });
  });
}
