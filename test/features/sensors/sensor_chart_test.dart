// ignore_for_file: prefer_const_constructors
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/views/sensor_chart.dart';

void main() {
  group('readingSeriesToSpots', () {
    test('maps an empty series to no spots', () {
      expect(readingSeriesToSpots(const <double>[]), isEmpty);
    });

    test('uses sample index as x and reading as y (oldest first)', () {
      final List<FlSpot> spots = readingSeriesToSpots(<double>[41, 42.5, 40]);
      expect(spots, hasLength(3));
      expect(spots.map((FlSpot s) => s.x), <double>[0, 1, 2]);
      expect(spots.map((FlSpot s) => s.y), <double>[41, 42.5, 40]);
    });

    test('produces 60 spots for a 60-point history', () {
      final List<double> series =
          List<double>.generate(60, (int i) => 20 + i * 0.1);
      expect(readingSeriesToSpots(series), hasLength(60));
      expect(readingSeriesToSpots(series).last.x, 59);
    });
  });

  group('chart key helpers', () {
    test('title is the trailing sensor name', () {
      expect(chartTitleForKey('thermal|1U|CPU1 Temp'), 'CPU1 Temp');
      expect(chartTitleForKey('voltage|1U|VCPU'), 'VCPU');
    });

    test('unknown/malformed keys fall back to the raw key', () {
      expect(chartTitleForKey('opaque-key'), 'opaque-key');
    });

    test('unit reflects the reading kind', () {
      expect(chartUnitForKey('thermal|1U|CPU1 Temp'), '°C');
      expect(chartUnitForKey('fan|1U|Fan0'), 'RPM');
      expect(chartUnitForKey('voltage|1U|VCPU'), 'V');
      expect(chartUnitForKey('sensor|1U|PSU1'), '');
    });
  });

  group('SensorLineChart widget', () {
    testWidgets('renders nothing until two samples exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: SensorLineChart(title: 'CPU', series: <double>[41])),
      );
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders a non-animated chart behind a RepaintBoundary',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SensorLineChart(
            title: 'CPU1 Temp',
            unit: '°C',
            series: const <double>[41, 42, 43],
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('CPU1 Temp'), findsOneWidget);
      // Duration.zero: a poll rebuild must not schedule chart tweens.
      final LineChart chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.duration, Duration.zero);
      expect(
        find.byKey(const ValueKey<String>('sensor-chart-CPU1 Temp')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('CPU1 Temp trend, last 43.0°C, 3 points'),
        findsOneWidget,
      );
    });

    testWidgets('builds 20 charts x 60 points in one frame without jank',
        (WidgetTester tester) async {
      // Frame-budget test bed for the #007 "no jank on 20 sensors x 60 points"
      // box. Each chart is non-animated and viewport-lazy in the real view; here
      // we force all 20 into one frame to catch per-chart animation/layout cost.
      final List<Widget> charts = <Widget>[
        for (int s = 0; s < 20; s++)
          SensorLineChart(
            title: 'Sensor $s',
            series: List<double>.generate(60, (int i) => i.toDouble()),
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: Column(children: charts),
          ),
        ),
      );

      expect(find.byType(LineChart), findsNWidgets(20));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 320 / 800 / 1300 px',
        (WidgetTester tester) async {
      for (final double width in <double>[320, 800, 1300]) {
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: SensorLineChart(
              title: 'CPU1 Temp',
              unit: '°C',
              series: const <double>[41, 42, 43],
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'overflow at ${width}px');
      }
    });
  });
}
