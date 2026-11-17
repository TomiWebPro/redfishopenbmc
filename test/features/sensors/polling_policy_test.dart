import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/polling_policy.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';

void main() {
  group('SensorsPollingPolicy', () {
    test('selects the fast visible interval and the backed-off hidden one', () {
      const SensorsPollingPolicy policy = SensorsPollingPolicy(
        visibleInterval: Duration(seconds: 5),
        hiddenInterval: Duration(seconds: 30),
      );
      expect(policy.intervalFor(false), const Duration(seconds: 5));
      expect(policy.intervalFor(true), const Duration(seconds: 30));
    });

    test('defaults the hidden backoff to 30 seconds', () {
      const SensorsPollingPolicy policy = SensorsPollingPolicy(
        visibleInterval: Duration(seconds: 10),
      );
      expect(policy.hiddenInterval, const Duration(seconds: 30));
    });
  });

  group('isSensorAppBackgrounded', () {
    test('treats paused, hidden and detached as backgrounded', () {
      expect(isSensorAppBackgrounded(AppLifecycleState.paused), isTrue);
      expect(isSensorAppBackgrounded(AppLifecycleState.hidden), isTrue);
      expect(isSensorAppBackgrounded(AppLifecycleState.detached), isTrue);
    });

    test('keeps the fast cadence for resumed and inactive states', () {
      expect(isSensorAppBackgrounded(AppLifecycleState.resumed), isFalse);
      expect(isSensorAppBackgrounded(AppLifecycleState.inactive), isFalse);
    });
  });

  group('SensorsPollingScheduler', () {
    testWidgets('ticks at the visible interval while active',
        (WidgetTester tester) async {
      int ticks = 0;
      final SensorsPollingScheduler scheduler = SensorsPollingScheduler(
        policy: const SensorsPollingPolicy(
          visibleInterval: Duration(seconds: 5),
        ),
        onTick: () => ticks++,
      );
      scheduler.start();
      addTearDown(scheduler.stop);

      expect(scheduler.isRunning, isTrue);
      expect(scheduler.isHidden, isFalse);
      expect(scheduler.currentInterval, const Duration(seconds: 5));

      await tester.pump(const Duration(seconds: 4));
      expect(ticks, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(ticks, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(ticks, 2);
      scheduler.stop();
    });

    testWidgets('backs off when hidden and resumes when visible again',
        (WidgetTester tester) async {
      int ticks = 0;
      final SensorsPollingScheduler scheduler = SensorsPollingScheduler(
        policy: const SensorsPollingPolicy(
          visibleInterval: Duration(seconds: 5),
          hiddenInterval: Duration(seconds: 30),
        ),
        onTick: () => ticks++,
      );
      scheduler.start();
      addTearDown(scheduler.stop);

      await tester.pump(const Duration(seconds: 5));
      expect(ticks, 1);

      scheduler.setHidden(true);
      expect(scheduler.isHidden, isTrue);
      expect(scheduler.currentInterval, const Duration(seconds: 30));

      // 25s into the backoff: still no tick; the full 30s elapses next.
      await tester.pump(const Duration(seconds: 25));
      expect(ticks, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(ticks, 2);

      scheduler.setHidden(false);
      expect(scheduler.currentInterval, const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      expect(ticks, 3);
      scheduler.stop();
    });

    testWidgets('stop cancels the timer and setHidden is inert while stopped',
        (WidgetTester tester) async {
      int ticks = 0;
      final SensorsPollingScheduler scheduler = SensorsPollingScheduler(
        policy: const SensorsPollingPolicy(
          visibleInterval: Duration(seconds: 5),
        ),
        onTick: () => ticks++,
      );
      scheduler.start();
      await tester.pump(const Duration(seconds: 5));
      expect(ticks, 1);

      scheduler.stop();
      expect(scheduler.isRunning, isFalse);
      scheduler.setHidden(true);
      await tester.pump(const Duration(seconds: 31));
      expect(ticks, 1);
    });
  });

  group('telemetryFingerprint', () {
    ChassisSensors chassisWith(double reading, {String? sourceUri}) =>
        ChassisSensors(
          chassisId: '1U',
          thermal: <ThermalReading>[
            ThermalReading(
              name: 'CPU',
              readingCelsius: reading,
              upperCritical: 55,
              status: const StatusInfo(health: 'OK'),
              sourceUri: sourceUri,
            ),
          ],
        );

    test('is stable across polls with identical visible data', () {
      expect(
        telemetryFingerprint(<ChassisSensors>[chassisWith(40)]),
        telemetryFingerprint(<ChassisSensors>[chassisWith(40)]),
      );
    });

    test('ignores fields that do not affect the rendered tiles', () {
      expect(
        telemetryFingerprint(<ChassisSensors>[
          chassisWith(40, sourceUri: '/redfish/v1/Chassis/1U/Thermal/0')
        ]),
        telemetryFingerprint(<ChassisSensors>[
          chassisWith(40, sourceUri: '/redfish/v1/Chassis/1U/Thermal/1')
        ]),
      );
    });

    test('changes when a reading changes', () {
      expect(
        telemetryFingerprint(<ChassisSensors>[chassisWith(40)]),
        isNot(telemetryFingerprint(<ChassisSensors>[chassisWith(41)])),
      );
    });

    test('changes when a health status changes', () {
      final ChassisSensors warning = const ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(
            name: 'CPU',
            readingCelsius: 40,
            upperCritical: 55,
            status: StatusInfo(health: 'Warning'),
          ),
        ],
      );
      expect(
        telemetryFingerprint(<ChassisSensors>[chassisWith(40)]),
        isNot(telemetryFingerprint(<ChassisSensors>[warning])),
      );
    });
  });
}
