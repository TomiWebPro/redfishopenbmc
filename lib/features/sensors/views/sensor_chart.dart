/// Reusable `fl_chart` line chart for a sensor's recent reading history
/// (issue #007 — "Charts: fl_chart LineChart per sensor ... lazy-build, no jank
/// on 20 sensors × 60 points").
///
/// The chart is intentionally self-contained and cheap to build: animations are
/// disabled, axes/grid/tooltips are off, and each chart sits behind a
/// [RepaintBoundary] so a poll that only advances *other* series cannot repaint
/// it. The series-to-spots mapping is a pure top-level function so it can be
/// unit-tested without a widget frame.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Maps an oldest-first reading series into [FlSpot]s for a `LineChart`.
///
/// The x axis is the sample index (0, 1, ...), so a series of N readings always
/// spans x ∈ [0, N-1] regardless of the values — identical to the semantics of
/// the dependency-free `SensorSparkline`. An empty series maps to no spots.
List<FlSpot> readingSeriesToSpots(List<double> series) => <FlSpot>[
      for (int i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i]),
    ];

/// Human-readable chart title for a `SensorHistoryStore` series [key].
///
/// Keys are `kind|chassisId|name`; only the trailing sensor name is shown — the
/// chassis card / chart section already supplies the surrounding context. An
/// unknown key falls back to the raw key so no chart is ever silently untitled.
String chartTitleForKey(String key) {
  final List<String> parts = key.split('|');
  return parts.length >= 3 ? parts.sublist(2).join('|') : key;
}

/// Unit suffix for a `SensorHistoryStore` series [key] (`°C` / `RPM` / `V`).
///
/// Generic sensors may report arbitrary Redfish units, so their charts carry no
/// suffix (the value itself is unitless here); the tile still shows the exact
/// `ReadingUnits` reported by the BMC.
String chartUnitForKey(String key) {
  final String kind = key.split('|').first;
  return switch (kind) {
    'thermal' => '°C',
    'fan' => 'RPM',
    'voltage' => 'V',
    _ => '',
  };
}

/// A lazy, non-animated `fl_chart` [LineChart] for one sensor history series.
///
/// Renders nothing until at least two samples exist (a single point cannot form
/// a trend). Touch handling and implicit animation are disabled so 20 charts ×
/// 60 points can be laid out in one frame without per-frame animation work.
class SensorLineChart extends StatelessWidget {
  /// Creates a chart for [series] (oldest first) titled [title].
  const SensorLineChart({
    required this.title,
    required this.series,
    this.unit = '',
    this.color,
    super.key,
  });

  /// Sensor name shown above the chart (merged into its semantics label).
  final String title;

  /// Recent readings, oldest first.
  final List<double> series;

  /// Optional unit suffix appended to the latest value in the label.
  final String unit;

  /// Line colour; falls back to the theme primary colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) return const SizedBox.shrink();

    final Color lineColor = color ?? Theme.of(context).colorScheme.primary;
    final List<FlSpot> spots = readingSeriesToSpots(series);
    final String latest = unit.isEmpty
        ? series.last.toStringAsFixed(1)
        : '${series.last.toStringAsFixed(1)}$unit';
    final String label = '$title trend, last $latest, ${series.length} points';

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            SizedBox(
              height: 140,
              child: RepaintBoundary(
                key: ValueKey<String>('sensor-chart-$title'),
                child: LineChart(
                  LineChartData(
                    lineBarsData: <LineChartBarData>[
                      LineChartBarData(
                        spots: spots,
                        color: lineColor,
                        barWidth: 2,
                        isCurved: false,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                  // No per-frame animation: a poll may rebuild charts, but it
                  // must not schedule 150ms tweens for 20 series at once.
                  duration: Duration.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
