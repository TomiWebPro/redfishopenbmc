// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/features/sensors/views/sensors_view.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [SensorsService] double that returns canned telemetry (no network).
class _FakeSensorsService extends SensorsService {
  _FakeSensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async => <ChassisSensors>[
        ChassisSensors(
          chassisId: '1U',
          chassisName: 'Chassis 1U',
          thermal: <ThermalReading>[
            ThermalReading(name: 'CPU1 Temp', readingCelsius: 41.0),
          ],
          fans: const <FanReading>[
            FanReading(name: 'Fan0', reading: 5400),
          ],
          sensors: const <SensorReading>[
            SensorReading(name: 'PSU1', reading: 12.5, readingUnits: 'V'),
          ],
        ),
      ];
}

SystemHandle buildHandle({required bool sensorMonitoring}) => SystemHandle(
      profile: ConnectionProfile(id: 'x', host: 'h'),
      status: ConnectionStatus.connected,
      features:
          SystemFeatures(systemId: 'x', sensorMonitoring: sensorMonitoring),
    );

void main() {
  group('SensorsView', () {
    testWidgets('renders nothing when sensorMonitoring is disabled (gate)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: false)),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsNothing);
    });

    testWidgets('renders temperatures when sensorMonitoring is enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsWidgets);
      expect(find.text('Fan0'), findsWidgets);
      expect(find.text('PSU1'), findsWidgets);
    });

    testWidgets('sensor tiles expose merged accessibility labels (UI-2)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Temperature CPU1 Temp, 41.0°C, Unknown'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Fan Fan0, 5400 RPM, Unknown'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Sensor PSU1, 12.50 V, Unknown'),
        findsOneWidget,
      );
    });
  });

  group('SensorsView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('renders without overflow at ${width.toInt()} px',
          (tester) async {
        await pumpAtWidth(tester, width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'SensorsView must not overflow at $width px',
        );
        expect(find.text('CPU1 Temp'), findsWidgets);
      });
    }
  });
}
