import 'package:flutter/material.dart';

/// Minimal per-sensor trend line over the last N polls, drawn with a
/// [CustomPainter] so no charting dependency is required (issue #007).
///
/// Renders nothing until at least two samples exist. Values are normalised to
/// their own min/max: a flat series draws a centred horizontal line.
class SensorSparkline extends StatelessWidget {
  /// Creates a sparkline for [values] (oldest first).
  const SensorSparkline({
    required this.values,
    this.color,
    this.width = 96,
    this.height = 28,
    super.key,
  });

  /// Recent readings to plot, oldest first.
  final List<double> values;

  /// Line colour; falls back to the theme primary colour.
  final Color? color;

  /// Rendered width in logical pixels.
  final double width;

  /// Rendered height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    final Color lineColor = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Trend of last ${values.length} readings',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparklinePainter(values: values, color: lineColor),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 2.0;
    final double drawableWidth = size.width - 2 * inset;
    final double drawableHeight = size.height - 2 * inset;
    if (drawableWidth <= 0 || drawableHeight <= 0) return;

    double low = values.first;
    double high = values.first;
    for (final double value in values) {
      if (value < low) low = value;
      if (value > high) high = value;
    }
    final double range = high - low;
    double yFor(double value) {
      if (range == 0) return inset + drawableHeight / 2;
      return inset + drawableHeight - ((value - low) / range) * drawableHeight;
    }

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = values.length == 1
          ? inset
          : inset + (i / (values.length - 1)) * drawableWidth;
      final double y = yFor(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

/// A horizontal threshold range bar with a marker for the current reading
/// (issue #007 — "threshold range bar"). Draws green between caution bounds,
/// amber between caution and critical, and red beyond critical.
///
/// Renders nothing unless at least one threshold is supplied; a reading with
/// no numeric value still draws the band without a marker (grey semantics).
class ThresholdBar extends StatelessWidget {
  /// Creates a range bar for [value] against the supplied thresholds.
  const ThresholdBar({
    required this.value,
    this.lowerCritical,
    this.lowerCaution,
    this.upperCaution,
    this.upperCritical,
    this.color,
    this.height = 10,
    super.key,
  });

  /// Current reading, or `null` when the sensor reports no reading.
  final double? value;

  /// Lower critical trip point (red beyond it).
  final double? lowerCritical;

  /// Lower caution trip point (amber beyond it, green inside).
  final double? lowerCaution;

  /// Upper caution trip point (amber beyond it, green inside).
  final double? upperCaution;

  /// Upper critical trip point (red beyond it).
  final double? upperCritical;

  /// Marker colour; falls back to the theme primary colour.
  final Color? color;

  /// Bar height in logical pixels.
  final double height;

  bool get _hasBounds =>
      lowerCritical != null ||
      lowerCaution != null ||
      upperCaution != null ||
      upperCritical != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasBounds) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final Color markerColor = color ?? theme.colorScheme.primary;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: value == null
          ? 'Threshold range, no reading'
          : 'Threshold range, reading ${value}',
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _ThresholdBarPainter(
            value: value,
            lowerCritical: lowerCritical,
            lowerCaution: lowerCaution,
            upperCaution: upperCaution,
            upperCritical: upperCritical,
            markerColor: markerColor,
            okColor: Colors.green.withValues(alpha: 0.55),
            warnColor: Colors.orange.withValues(alpha: 0.65),
            criticalColor: theme.colorScheme.error.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _ThresholdBarPainter extends CustomPainter {
  _ThresholdBarPainter({
    required this.value,
    required this.lowerCritical,
    required this.lowerCaution,
    required this.upperCaution,
    required this.upperCritical,
    required this.markerColor,
    required this.okColor,
    required this.warnColor,
    required this.criticalColor,
  });

  final double? value;
  final double? lowerCritical;
  final double? lowerCaution;
  final double? upperCaution;
  final double? upperCritical;
  final Color markerColor;
  final Color okColor;
  final Color warnColor;
  final Color criticalColor;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> marks = <double>[
      if (lowerCritical != null) lowerCritical!,
      if (lowerCaution != null) lowerCaution!,
      if (upperCaution != null) upperCaution!,
      if (upperCritical != null) upperCritical!,
      if (value != null) value!,
    ];
    if (marks.isEmpty || size.width <= 0) return;

    double low = marks.first;
    double high = marks.first;
    for (final double mark in marks) {
      if (mark < low) low = mark;
      if (mark > high) high = mark;
    }
    final double span = high - low;
    final double pad = span == 0 ? 1 : span * 0.10;
    low -= pad;
    high += pad;

    double xFor(double mark) => ((mark - low) / (high - low)) * size.width;

    void band(double? from, double? to, Color color) {
      if (from == null || to == null || to <= from) return;
      final double left = xFor(from).clamp(0.0, size.width);
      final double right = xFor(to).clamp(0.0, size.width);
      canvas.drawRect(
        Rect.fromLTWH(left, 0, right - left, size.height),
        Paint()..color = color,
      );
    }

    // Green safe band first, then the amber and red danger bands on top.
    band(lowerCaution, upperCaution, okColor);
    band(lowerCritical, lowerCaution, warnColor);
    band(upperCaution, upperCritical, warnColor);
    band(low, lowerCritical, criticalColor);
    band(upperCritical, high, criticalColor);

    final double? current = value;
    if (current != null) {
      final double x = xFor(current).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = markerColor
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ThresholdBarPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.lowerCritical != lowerCritical ||
      oldDelegate.lowerCaution != lowerCaution ||
      oldDelegate.upperCaution != upperCaution ||
      oldDelegate.upperCritical != upperCritical ||
      oldDelegate.markerColor != markerColor;
}
