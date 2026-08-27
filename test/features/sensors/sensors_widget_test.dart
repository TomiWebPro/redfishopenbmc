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
      fans: const <FanReading>[],
      sensors: const <SensorReading>[],
    ),
  ];
}

SystemHandle buildHandle({required bool sensorMonitoring}) => SystemHandle(
      profile: ConnectionProfile(id: 'x', host: 'h'),
      status: ConnectionStatus.connected,
      features: SystemFeatures(systemId: 'x', sensorMonitoring: sensorMonitoring),
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
            sensorsServiceProvider('x').overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsWidgets);
    });
  });
}
