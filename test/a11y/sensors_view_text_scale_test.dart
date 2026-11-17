// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/features/sensors/views/sensors_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [SensorsService] double that returns no chassis (empty-state tests).
class _EmptySensorsService extends SensorsService {
  _EmptySensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async => const <ChassisSensors>[];
}

SystemHandle _buildHandle() => SystemHandle(
      profile: ConnectionProfile(id: 'x', host: 'h'),
      status: ConnectionStatus.connected,
      features: SystemFeatures(systemId: 'x', sensorMonitoring: true),
    );

void main() {
  testWidgets(
    'SensorsView supports 200% text scaling without overflow at 400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x').overrideWithValue(_buildHandle()),
            sensorsServiceProvider('x')
                .overrideWithValue(_EmptySensorsService()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(
                body: SensorsView(systemId: 'x', autoRefreshInterval: null),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('No sensor data available'),
        findsOneWidget,
      );
      expect(find.text('No sensor data available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
