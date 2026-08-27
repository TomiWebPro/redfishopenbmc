import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/power/models/power_state.dart';

void main() {
  group('PowerStateX', () {
    test('maps Redfish values case-insensitively', () {
      expect(PowerStateX.fromRedfish('On'), PowerState.on);
      expect(PowerStateX.fromRedfish('ON'), PowerState.on);
      expect(PowerStateX.fromRedfish('off'), PowerState.off);
      expect(PowerStateX.fromRedfish('Off'), PowerState.off);
    });

    test('falls back to unknown for null / junk', () {
      expect(PowerStateX.fromRedfish(null), PowerState.unknown);
      expect(PowerStateX.fromRedfish(''), PowerState.unknown);
      expect(PowerStateX.fromRedfish('Standby'), PowerState.unknown);
    });

    test('labels are human readable', () {
      expect(PowerState.on.label, 'On');
      expect(PowerState.off.label, 'Off');
      expect(PowerState.poweringOn.label, 'Powering on…');
      expect(PowerState.poweringOff.label, 'Powering off…');
      expect(PowerState.unknown.label, 'Unknown');
    });

    test('isTransitioning only for the two transitional states', () {
      expect(PowerState.poweringOn.isTransitioning, isTrue);
      expect(PowerState.poweringOff.isTransitioning, isTrue);
      expect(PowerState.on.isTransitioning, isFalse);
      expect(PowerState.off.isTransitioning, isFalse);
      expect(PowerState.unknown.isTransitioning, isFalse);
    });
  });

  group('ResetType', () {
    test('toRedfish returns the canonical Redfish spelling', () {
      expect(ResetType.on.toRedfish(), 'On');
      expect(ResetType.forceOff.toRedfish(), 'ForceOff');
      expect(ResetType.gracefulShutdown.toRedfish(), 'GracefulShutdown');
      expect(ResetType.gracefulRestart.toRedfish(), 'GracefulRestart');
      expect(ResetType.forceRestart.toRedfish(), 'ForceRestart');
      expect(ResetType.powerCycle.toRedfish(), 'PowerCycle');
      expect(ResetType.nmi.toRedfish(), 'Nmi');
    });

    test('fromRedfish round-trips case-insensitively', () {
      for (final ResetType t in ResetType.values) {
        expect(ResetType.fromRedfish(t.toRedfish()), t);
        expect(ResetType.fromRedfish(t.toRedfish().toLowerCase()), t);
      }
      expect(ResetType.fromRedfish(null), isNull);
      expect(ResetType.fromRedfish('bogus'), isNull);
    });

    test('labels are human readable', () {
      expect(ResetType.on.label, 'Power On');
      expect(ResetType.forceOff.label, 'Force Off');
      expect(ResetType.gracefulShutdown.label, 'Graceful Shutdown');
      expect(ResetType.gracefulRestart.label, 'Graceful Restart');
      expect(ResetType.forceRestart.label, 'Force Restart');
      expect(ResetType.powerCycle.label, 'Power Cycle');
      expect(ResetType.nmi.label, 'NMI');
    });

    test('only On is non-destructive', () {
      expect(ResetType.on.isDestructive, isFalse);
      for (final ResetType t in ResetType.values.where((t) => t != ResetType.on)) {
        expect(t.isDestructive, isTrue);
      }
    });

    test('optimisticState projects the transitional power state', () {
      expect(ResetType.on.optimisticState, PowerState.poweringOn);
      expect(ResetType.forceOff.optimisticState, PowerState.poweringOff);
      expect(ResetType.gracefulShutdown.optimisticState, PowerState.poweringOff);
      expect(ResetType.gracefulRestart.optimisticState, PowerState.poweringOn);
      expect(ResetType.forceRestart.optimisticState, PowerState.poweringOn);
      expect(ResetType.powerCycle.optimisticState, PowerState.poweringOn);
      expect(ResetType.nmi.optimisticState, PowerState.unknown);
    });

    test('primaryActions lists the four headline controls', () {
      expect(
        ResetType.primaryActions,
        <ResetType>[
          ResetType.on,
          ResetType.forceOff,
          ResetType.gracefulRestart,
          ResetType.forceRestart,
        ],
      );
    });
  });
}
