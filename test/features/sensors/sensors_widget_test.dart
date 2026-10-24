// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/features/sensors/views/sensors_view.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
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

/// A [SensorsService] double that always fails (error-state tests).
class _FailingSensorsService extends SensorsService {
  _FailingSensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async =>
      throw const RedfishException(message: 'boom');
}

/// A [SensorsService] double that returns no chassis (empty-state tests).
class _EmptySensorsService extends SensorsService {
  _EmptySensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async => const <ChassisSensors>[];
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

    testWidgets(
        'unknown system id announces one merged "System not found" node '
        '(UI-2)', (WidgetTester tester) async {
      // No handle → the fallback renders the established merged node (icon +
      // text, one self-describing announcement, no Retry).
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x').overrideWithValue(null),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('System not found'), findsOneWidget);
      expect(find.text('System not found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      // 320 px no-overflow check via the addTearDown restore pattern.
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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

    testWidgets('chassis card header exposes a merged summary label (UI-2)',
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

      // The chassis card header announces one concise summary instead of a
      // bare title (UI-2 pattern: container + excludeSemantics + label).
      expect(
        find.bySemanticsLabel('Chassis 1U, 1 temperatures, 1 fans, 1 sensors'),
        findsOneWidget,
      );
    });

    testWidgets(
        'section headers announce one merged node with the count (UI-2)',
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

      // Each non-card section header is now a self-describing node: the
      // visible title + the count the card layout conveys visually.
      expect(
        find.bySemanticsLabel('Temperatures, 1'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Fans, 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Sensors, 1'), findsOneWidget);
      // The visible titles remain for sighted users (no a11y regression).
      expect(find.text('Temperatures'), findsOneWidget);
      expect(find.text('Fans'), findsOneWidget);
      expect(find.text('Sensors'), findsOneWidget);
    });

    testWidgets('shows an error state with a retry affordance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FailingSensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load sensors'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

      // Tapping retry must not crash (re-runs the failing service).
      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load sensors'), findsOneWidget);
    });

    testWidgets('error state announces as one merged semantics node (UI-2)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FailingSensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      // The icon + title + detail merge into one node carrying both strings;
      // the Retry button keeps its own semantics (it is a control).
      final Finder merged = find.bySemanticsLabel(
        'Unable to load sensors. boom',
      );
      expect(merged, findsOneWidget);
      final SemanticsNode? node = tester.getSemantics(merged);
      expect(node?.label, contains('Unable to load sensors'));
      expect(node?.label, contains('boom'));

      // The Retry control is still separately focusable/announced.
      expect(
        find.bySemanticsLabel(RegExp('^Retry')),
        findsWidgets,
      );
    });

    testWidgets('empty state renders an icon + message (UI-2)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_EmptySensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      // The empty state is now a proper state card: icon + visible text (not
      // a bare detached sentence).
      expect(find.text('No sensor data available'), findsOneWidget);
      expect(find.byIcon(Icons.sensors_off_outlined), findsOneWidget);
    });

    testWidgets('empty state announces as one merged semantics node (UI-2)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_EmptySensorsService()),
          ],
          child: const MaterialApp(home: SensorsView(systemId: 'x')),
        ),
      );
      await tester.pumpAndSettle();

      // The icon + text merge into ONE node via the established
      // container + excludeSemantics pattern, so a screen reader hears a
      // single self-describing announcement.
      final Finder merged = find.bySemanticsLabel('No sensor data available');
      expect(merged, findsOneWidget);
      final SemanticsNode? node = tester.getSemantics(merged);
      expect(node?.label, contains('No sensor data available'));
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
