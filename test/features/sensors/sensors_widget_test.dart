// ignore_for_file: prefer_const_constructors
import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_providers.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/features/sensors/views/sensor_delta_tile.dart';
import 'package:redfishopenbmc/features/sensors/views/sensors_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
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

/// A [SensorsService] double with threshold + physical-context data so the
/// UI-2 merged labels can be pinned (no network).
class _DetailSensorsService extends SensorsService {
  _DetailSensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async => <ChassisSensors>[
        ChassisSensors(
          chassisId: '1U',
          chassisName: 'Chassis 1U',
          thermal: <ThermalReading>[
            ThermalReading(
              name: 'CPU1 Temp',
              readingCelsius: 41.0,
              upperCaution: 45,
              upperCritical: 55,
            ),
          ],
          fans: const <FanReading>[
            FanReading(
              name: 'Fan0',
              reading: 5400,
              physicalContext: 'CPU',
            ),
          ],
          sensors: const <SensorReading>[
            SensorReading(
              name: 'PSU1',
              reading: 12.5,
              readingUnits: 'V',
              readingType: 'Voltage',
              thresholds: <String, double>{
                'UpperCritical': 13.0,
                'LowerCritical': 11.0,
              },
            ),
          ],
        ),
      ];
}

/// A [SensorsService] double with breaching/unhealthy readings so the #007
/// alert banner can be verified (no network).
class _AlertSensorsService extends SensorsService {
  _AlertSensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async => <ChassisSensors>[
        ChassisSensors(
          chassisId: '1U',
          chassisName: 'Chassis 1U',
          thermal: <ThermalReading>[
            ThermalReading(
              name: 'CPU1 Temp',
              readingCelsius: 60,
              upperCritical: 55,
              // BMC reports OK even though the reading breaches the limit —
              // the threshold evaluation (not just health) must surface it.
              status: const StatusInfo(health: 'OK'),
            ),
          ],
          sensors: <SensorReading>[
            SensorReading(
              name: 'PSU1',
              reading: 12.5,
              readingUnits: 'V',
              status: const StatusInfo(health: 'Warning'),
            ),
          ],
        ),
      ];
}

/// A [SensorsService] double that reports only OpenBMC `Thermal.Voltages[]`
/// readings (issue #007 voltage section tests). [breaching] raises VCPU past its
/// critical bound so the alert banner path can be verified too.
class _VoltageSensorsService extends SensorsService {
  _VoltageSensorsService({this.breaching = false})
      : super(client: null, systemId: 'x');

  final bool breaching;

  @override
  Future<List<ChassisSensors>> fetchAll() async => <ChassisSensors>[
        ChassisSensors(
          chassisId: '1U',
          chassisName: 'Chassis 1U',
          voltages: <VoltageReading>[
            VoltageReading(
              name: 'VCPU',
              readingVolts: breaching ? 2.5 : 1.8,
              physicalContext: 'CPU',
              upperCaution: 2.0,
              upperCritical: 2.2,
            ),
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

/// A [SensorsService] double that behaves as not-yet-connected.
class _NotConnectedSensorsService extends SensorsService {
  _NotConnectedSensorsService() : super(client: null, systemId: 'x');
}

/// A [SensorsService] double that never completes (loading-state tests).
class _PendingSensorsService extends SensorsService {
  _PendingSensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() =>
      Completer<List<ChassisSensors>>().future;
}

/// A [SensorsService] double counting fetch calls for polling tests (#019).
class _CountingSensorsService extends SensorsService {
  _CountingSensorsService() : super(client: null, systemId: 'x');

  int calls = 0;

  @override
  Future<List<ChassisSensors>> fetchAll() async {
    calls++;
    return const <ChassisSensors>[
      ChassisSensors(
        chassisId: '1U',
        chassisName: 'Chassis 1U',
        thermal: <ThermalReading>[],
        fans: <FanReading>[],
        sensors: <SensorReading>[],
      ),
    ];
  }
}

/// A [SensorsService] double with one OK-health temperature that reports no
/// numeric reading — the tile chip must grey out (issue #007 coloring).
class _NoReadingSensorsService extends SensorsService {
  _NoReadingSensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async => <ChassisSensors>[
        ChassisSensors(
          chassisId: '1U',
          thermal: <ThermalReading>[
            ThermalReading(
              name: 'CPU1 Temp',
              status: const StatusInfo(health: 'OK'),
            ),
          ],
        ),
      ];
}

/// A [SensorsService] double whose OK-health reading breaches its critical
/// threshold — the tile chip must turn red from the breach alone (#007).
class _BreachOnlySensorsService extends SensorsService {
  _BreachOnlySensorsService() : super(client: null, systemId: 'x');

  @override
  Future<List<ChassisSensors>> fetchAll() async => <ChassisSensors>[
        ChassisSensors(
          chassisId: '1U',
          thermal: <ThermalReading>[
            ThermalReading(
              name: 'CPU1 Temp',
              readingCelsius: 60,
              upperCritical: 55,
              status: const StatusInfo(health: 'OK'),
            ),
          ],
        ),
      ];
}

/// Border colour of the health chip whose label is [valueText].
Color _chipBorderColor(WidgetTester tester, String valueText) {
  final Chip chip = tester.widget<Chip>(
    find.ancestor(
      of: find.text(valueText),
      matching: find.byType(Chip),
    ),
  );
  return chip.side!.color;
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsNothing);
    });

    testWidgets(
        'loading state announces one merged "Loading sensors" node '
        '(UI-2)', (WidgetTester tester) async {
      // A never-completing service keeps the controller in `loading: true`
      // (the state flag is set synchronously before the await), so the view
      // renders the loading branch. pumpAndSettle would time out — use pump.
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_PendingSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pump();

      // The spinner announces as ONE self-describing merged node instead of a
      // bare unlabeled progress indicator (the established loading-state
      // pattern — FirmwareView header/inventory).
      final Finder merged = find.bySemanticsLabel('Loading sensors');
      expect(merged, findsOneWidget);
      final SemanticsNode? node = tester.getSemantics(merged);
      expect(node?.label, contains('Loading sensors'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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

    testWidgets(
        'discovery-pending state announces one merged "Loading sensors" node '
        '(UI-2)', (WidgetTester tester) async {
      // Handle known but capabilities not resolved yet → announce a single
      // merged loading node (no Retry) instead of a bare unlabeled spinner.
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x').overrideWithValue(
              SystemHandle(
                profile: ConnectionProfile(id: 'x', host: 'h'),
                status: ConnectionStatus.connected,
                features: null,
              ),
            ),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pump();

      final Finder merged = find.bySemanticsLabel('Loading sensors');
      expect(merged, findsOneWidget);
      final SemanticsNode? node = tester.getSemantics(merged);
      expect(node?.label, contains('Loading sensors'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsWidgets);
      expect(find.text('Fan0'), findsWidgets);
      expect(find.text('PSU1'), findsWidgets);
    });

    testWidgets(
        'wraps each telemetry tile in a selector-style delta gate '
        '(#007)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      // One temperature + one fan + one generic sensor = three gates. Each
      // gate rebuilds its tile only when that reading's fingerprint changes.
      expect(find.byType(SensorDeltaTile), findsNWidgets(3));
    });

    testWidgets(
        'shows a single alert banner for breaching/unhealthy readings '
        '(#007)', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_AlertSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Critical sensor alert'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('CPU1 Temp 60.0 °C — Critical'), findsOneWidget);
      expect(find.text('PSU1 12.5 V — Warning'), findsOneWidget);

      // One merged semantics node lists every alert in context.
      final SemanticsNode? node = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Sensor alerts:.*CPU1 Temp')),
      );
      expect(node?.label, contains('CPU1 Temp 60.0 °C — Critical'));
      expect(node?.label, contains('PSU1 12.5 V — Warning'));
    });

    testWidgets('no alert banner when all readings are healthy (#007)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsWidgets);
      expect(find.text('Critical sensor alert'), findsNothing);
      expect(find.text('Sensor warning'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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

    testWidgets(
        'sensor tile merged labels carry the visible subtitle context (UI-2)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_DetailSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      // Each tile announces ONE node whose label mirrors what sighted users
      // see: threshold hints (temperature), physical context (fan), and
      // reading type + thresholds (generic sensor) are part of the merged
      // announcement, not dropped by excludeSemantics.
      expect(
        find.bySemanticsLabel(
            'Temperature CPU1 Temp, 41.0°C, Unknown, caution 45 / crit 55'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Fan Fan0, 5400 RPM, Unknown, CPU'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Sensor PSU1, 12.50 V, Unknown, Voltage, '
            'UpperCritical 13.0 / LowerCritical 11.0'),
        findsOneWidget,
      );
      // Visible subtitle texts stay for sighted users.
      expect(find.text('caution 45 / crit 55'), findsOneWidget);
      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('Voltage · UpperCritical 13.0 / LowerCritical 11.0'),
          findsOneWidget);
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      // The chassis card header announces one concise summary instead of a
      // bare title (UI-2 pattern: container + excludeSemantics + label).
      expect(
        find.bySemanticsLabel(
            'Chassis 1U, 1 temperatures, 1 fans, 0 voltages, 1 sensors'),
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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

    testWidgets('retries load when system handle becomes connected',
        (tester) async {
      final StateProvider<SystemHandle?> handleState =
          StateProvider<SystemHandle?>(
        (_) => SystemHandle(
          profile: ConnectionProfile(id: 'x', host: 'h'),
          status: ConnectionStatus.disconnected,
          features: SystemFeatures(systemId: 'x', sensorMonitoring: true),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWith((ref) => ref.watch(handleState)),
            sensorsServiceProvider('x').overrideWith((ref) {
              final SystemHandle? h = ref.watch(systemHandleProvider('x'));
              if (h?.client == null) return _NotConnectedSensorsService();
              return _FakeSensorsService();
            }),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load sensors'), findsOneWidget);
      expect(find.textContaining('Not connected'), findsOneWidget);

      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(SensorsView)));
      container.read(handleState.notifier).state = SystemHandle(
        profile: ConnectionProfile(id: 'x', host: 'h'),
        status: ConnectionStatus.connected,
        features: SystemFeatures(systemId: 'x', sensorMonitoring: true),
        client: RedfishClient(
          profile: const ConnectionProfile(id: 'x', host: 'h'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsWidgets);
      expect(find.text('Unable to load sensors'), findsNothing);
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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

    testWidgets(
        'auto-refresh polls sensors on interval and stops on dispose (#019)',
        (WidgetTester tester) async {
      final _CountingSensorsService service = _CountingSensorsService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x').overrideWithValue(service),
          ],
          child: const MaterialApp(
            home: SensorsView(
              systemId: 'x',
              autoRefreshInterval: Duration(seconds: 5),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(service.calls, 1);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(service.calls, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final int callsAfterDispose = service.calls;
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(service.calls, callsAfterDispose);
    });

    testWidgets('renders a capability-gated Voltages section (#007)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_VoltageSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Voltages'), findsOneWidget);
      expect(find.bySemanticsLabel('Voltages, 1'), findsOneWidget);
      expect(find.text('VCPU'), findsWidgets);
      // One merged node carries the value, health, context and thresholds.
      expect(
        find.bySemanticsLabel('Voltage VCPU, 1.80 V, Unknown, CPU, '
            'caution 2.0 / crit 2.2'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
            'Chassis 1U, 0 temperatures, 0 fans, 1 voltages, 0 sensors'),
        findsOneWidget,
      );
      // The voltage tile is gated like every other tile.
      expect(find.byType(SensorDeltaTile), findsOneWidget);
    });

    testWidgets('omits the Voltages section when no voltage is reported (#007)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Voltages'), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'^Voltages,')), findsNothing);
    });

    testWidgets('surfaces a breaching voltage in the alert banner (#007)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_VoltageSensorsService(breaching: true)),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Critical sensor alert'), findsOneWidget);
      expect(find.text('VCPU 2.50 V — Critical'), findsOneWidget);
    });

    testWidgets(
        'data view offers pull-to-refresh and a merged last-updated '
        'line (#007)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      // The stamp is shown after a successful poll, announces as ONE merged
      // node (the inner Text is excluded from semantics), and is locale-free
      // HH:MM:SS.
      expect(find.textContaining('Last updated'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Last updated \d{2}:\d{2}:\d{2}$')),
        findsOneWidget,
      );
    });

    testWidgets('pull-to-refresh re-fetches telemetry (#007)', (tester) async {
      final _CountingSensorsService service = _CountingSensorsService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x').overrideWithValue(service),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.calls, 1);

      // Drag down on the always-scrollable list to fire the indicator.
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(service.calls, 2);
    });

    testWidgets('last-updated line does not overflow at 320 px (#007)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Last updated'), findsOneWidget);
    });
  });

  group('threshold coloring on tiles (#007)', () {
    test('sensorDisplayLevelColor maps all four levels', () {
      expect(sensorDisplayLevelColor(SensorDisplayLevel.none), Colors.grey);
      expect(sensorDisplayLevelColor(SensorDisplayLevel.ok), Colors.green);
      expect(
          sensorDisplayLevelColor(SensorDisplayLevel.warning), Colors.orange);
      expect(sensorDisplayLevelColor(SensorDisplayLevel.critical), Colors.red);
    });

    testWidgets('a reading-less OK tile renders a grey chip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_NoReadingSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(_chipBorderColor(tester, '—'), Colors.grey);
    });

    testWidgets('a threshold breach on an OK BMC renders a red chip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_BreachOnlySensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();

      // The banner already flags it; the tile chip must localise the severity
      // too, even though Status.Health == OK.
      expect(_chipBorderColor(tester, '60.0°C'), Colors.red);
    });
  });

  group('formatSensorLastUpdated (#007)', () {
    test('pads hour/minute/second to two digits', () {
      expect(
          formatSensorLastUpdated(DateTime(2026, 11, 17, 9, 2, 3)), '09:02:03');
      expect(formatSensorLastUpdated(DateTime(2026, 11, 17, 23, 59, 58)),
          '23:59:58');
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
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
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

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'alert banner renders without overflow at ${width.toInt()} '
          'px (#007)', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              systemHandleProvider('x')
                  .overrideWithValue(buildHandle(sensorMonitoring: true)),
              sensorsServiceProvider('x')
                  .overrideWithValue(_AlertSensorsService()),
            ],
            child: const MaterialApp(
                home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Alert banner must not overflow at $width px',
        );
        expect(find.text('Critical sensor alert'), findsOneWidget);
      });
    }

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'voltage tile renders without overflow at ${width.toInt()} '
          'px (#007)', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              systemHandleProvider('x')
                  .overrideWithValue(buildHandle(sensorMonitoring: true)),
              sensorsServiceProvider('x')
                  .overrideWithValue(_VoltageSensorsService()),
            ],
            child: const MaterialApp(
                home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Voltage section must not overflow at $width px',
        );
        expect(find.text('VCPU'), findsWidgets);
      });
    }
  });

  group('Tiles/Charts view mode (#007)', () {
    Future<void> pumpView(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('x')
                .overrideWithValue(buildHandle(sensorMonitoring: true)),
            sensorsServiceProvider('x')
                .overrideWithValue(_FakeSensorsService()),
          ],
          child: const MaterialApp(
              home: SensorsView(systemId: 'x', autoRefreshInterval: null)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('charts are lazy — built only after tapping Charts',
        (tester) async {
      await pumpView(tester);
      expect(find.text('Tiles'), findsOneWidget);
      expect(find.text('Charts'), findsOneWidget);
      // Default tile view never pays for a LineChart.
      expect(find.byType(LineChart), findsNothing);

      // Accumulate 3 samples per series (thermal + fan + sensor) so each has a
      // drawable trend (one initial load + two manual reloads).
      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(SensorsView)));
      await container.read(sensorsControllerProvider('x').notifier).load();
      await tester.pumpAndSettle();
      await container.read(sensorsControllerProvider('x').notifier).load();
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsNothing);

      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Collecting history caption before two samples (#007)',
        (tester) async {
      await pumpView(tester);
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();

      // Only one sample so far → no chart, just an honest caption.
      expect(find.text('Collecting history…'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('can switch back from Charts to Tiles (#007)', (tester) async {
      await pumpView(tester);
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiles'));
      await tester.pumpAndSettle();

      expect(find.text('CPU1 Temp'), findsWidgets);
      expect(find.byType(LineChart), findsNothing);
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'chart view renders without overflow at ${width.toInt()} px '
          '(#007)', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await pumpView(tester);
        final ProviderContainer container =
            ProviderScope.containerOf(tester.element(find.byType(SensorsView)));
        await container.read(sensorsControllerProvider('x').notifier).load();
        await tester.pumpAndSettle();
        await container.read(sensorsControllerProvider('x').notifier).load();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Charts'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'chart view must not overflow at $width px');
      });
    }
  });
}
