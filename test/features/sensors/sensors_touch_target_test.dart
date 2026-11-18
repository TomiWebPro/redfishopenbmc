// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/features/sensors/views/sensors_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Populated telemetry double so the Tiles/Charts view-mode switch renders.
class _PopulatedSensorsService extends SensorsService {
  _PopulatedSensorsService() : super(client: null, systemId: 'x');

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

SystemHandle _buildHandle() => SystemHandle(
      profile: ConnectionProfile(id: 'x', host: 'h'),
      status: ConnectionStatus.connected,
      features: SystemFeatures(systemId: 'x', sensorMonitoring: true),
    );

/// Pumps a populated [SensorsView] under a desktop `shrinkWrap` theme — the
/// exact condition where Material buttons collapse to a 40dp hit area (issue
/// #010, a11y / touch targets).
Future<void> pumpPopulatedSensors(WidgetTester tester,
    {double width = 800}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('x').overrideWithValue(_buildHandle()),
        sensorsServiceProvider('x')
            .overrideWithValue(_PopulatedSensorsService()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        home: const Scaffold(
            body: SensorsView(systemId: 'x', autoRefreshInterval: null)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Sensors view-mode SegmentedButton keeps a >=48dp touch target on desktop',
    (WidgetTester tester) async {
      await pumpPopulatedSensors(tester);

      final Finder toggle = find.byType(SegmentedButton<bool>);
      expect(toggle, findsOneWidget,
          reason: 'populated view shows the Tiles/Charts switch');

      final Size size = tester.getSize(toggle);
      expect(size.height, greaterThanOrEqualTo(48),
          reason: 'segment height must be >= 48dp (WCAG 2.5.5) on desktop; '
              'without an explicit minimum Material collapses it to 40dp');
    },
  );

  testWidgets(
    'both Sensors view-mode segments are single, enabled button nodes',
    (WidgetTester tester) async {
      await pumpPopulatedSensors(tester);

      for (final String label in <String>['Tiles', 'Charts']) {
        final Finder byLabel = find.bySemanticsLabel(label);
        expect(byLabel, findsOneWidget,
            reason: 'exactly one node announced as "$label"');
        final SemanticsNode node = tester.getSemantics(byLabel);
        expect(node.getSemanticsData().flagsCollection.isButton, isTrue,
            reason: '"$label" segment is announced as a button');
        expect(
          node.getSemanticsData().flagsCollection.isEnabled.toBoolOrNull(),
          isTrue,
          reason: '"$label" segment is enabled',
        );
      }
      expect(tester.takeException(), isNull, reason: 'no render overflow');
    },
  );
}
