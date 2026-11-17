// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/features/sensors/views/sensor_telemetry_widgets.dart';
import 'package:redfishopenbmc/features/sensors/views/sensors_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

void main() {
  group('SensorSparkline', () {
    testWidgets('renders nothing with fewer than two samples', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SensorSparkline(values: <double>[41])),
      );
      expect(find.bySemanticsLabel(RegExp('^Trend of last')), findsNothing);
    });

    testWidgets(
        'draws a line and announces a merged trend label with 2+ '
        'samples', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SensorSparkline(values: <double>[40, 42, 41, 45]),
        ),
      );
      expect(
        find.bySemanticsLabel('Trend of last 4 readings'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('flat series paints without overflow at 320/800/1300px',
        (tester) async {
      for (final double width in <double>[320, 800, 1300]) {
        tester.view.physicalSize = Size(width, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: <Widget>[
                SizedBox(
                  width: width,
                  child: SensorSparkline(
                    values: const <double>[42, 42, 42],
                    width: width - 16,
                  ),
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('ThresholdBar', () {
    testWidgets('renders nothing without any threshold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ThresholdBar(value: 42)),
      );
      expect(
        find.bySemanticsLabel(RegExp('^Threshold range')),
        findsNothing,
      );
    });

    testWidgets('draws bands and a reading marker with a merged label',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThresholdBar(
            value: 58,
            lowerCaution: 10,
            upperCaution: 45,
            upperCritical: 55,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Threshold range, reading 58.0'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('announces no-reading state and paints bands only',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThresholdBar(value: null, upperCritical: 55),
        ),
      );
      expect(
        find.bySemanticsLabel('Threshold range, no reading'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders within a tile-width row at 320/800/1300px',
        (tester) async {
      for (final double width in <double>[320, 800, 1300]) {
        tester.view.physicalSize = Size(width, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Row(
              children: <Widget>[
                const SensorSparkline(values: <double>[40, 55, 58]),
                const SizedBox(width: 8),
                Expanded(
                  child: ThresholdBar(
                    value: 58,
                    lowerCritical: 2,
                    lowerCaution: 10,
                    upperCaution: 45,
                    upperCritical: 55,
                  ),
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('sensor history across polls', () {
    testWidgets(
        'controller accumulates a sparkline series after two polls '
        '(#007)', (tester) async {
      await _pumpView(tester);
      await tester.pump();
      await tester.pumpAndSettle();

      // First poll: the tile's sparkline holds one sample (too few to draw).
      expect(find.text('CPU1 Temp'), findsWidgets);
      SensorSparkline sparkline = tester.widget(
        find.byType(SensorSparkline),
      );
      expect(sparkline.values, <double>[41.0]);

      // Second poll (auto-refresh) appends a sample for the same sensor key.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      sparkline = tester.widget(find.byType(SensorSparkline));
      expect(sparkline.values, <double>[41.0, 42.0]);
      expect(tester.takeException(), isNull);
    });
  });
}

/// A service whose temperature reading rises on each poll, so successive
/// refreshes build a multi-sample history for the same sensor key (#007).
class _RisingSensorsService extends SensorsService {
  _RisingSensorsService() : super(client: null, systemId: 'x');

  int _poll = 0;

  @override
  Future<List<ChassisSensors>> fetchAll() async {
    _poll++;
    return <ChassisSensors>[
      ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(
            name: 'CPU1 Temp',
            readingCelsius: 40.0 + _poll,
            upperCritical: 55,
          ),
        ],
      ),
    ];
  }
}

SystemHandle _handle() => SystemHandle(
      profile: ConnectionProfile(id: 'x', host: 'h'),
      status: ConnectionStatus.connected,
      features: SystemFeatures(systemId: 'x', sensorMonitoring: true),
    );

Future<void> _pumpView(WidgetTester tester) => tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          systemHandleProvider('x').overrideWithValue(_handle()),
          sensorsServiceProvider('x')
              .overrideWithValue(_RisingSensorsService()),
        ],
        child: const MaterialApp(
          home: SensorsView(
            systemId: 'x',
            autoRefreshInterval: Duration(seconds: 5),
          ),
        ),
      ),
    );
