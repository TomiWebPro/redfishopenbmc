/// Fixed-capacity ring buffer of recent numeric readings and its per-sensor
/// store (issue #007 — "mini sparkline (last 20 polls, ring buffer)").
///
/// Pure Dart (no Flutter dependency) so the eviction/ordering rules can be
/// unit-tested directly. The store is intentionally mutable and lives inside
/// the sensors controller; each successful poll records a new sample and the
/// controller publishes an immutable snapshot into UI state.
library;

import 'sensor_models.dart';

/// Default number of recent polls retained per sensor (issue #007: last 20).
const int kDefaultHistoryCapacity = 20;

/// A fixed-capacity FIFO of readings: adding past [capacity] evicts the oldest
/// sample. Values are returned oldest-first, ready to feed a sparkline painter.
class ReadingHistory {
  /// Creates a history holding at most [capacity] readings.
  ReadingHistory({
    this.capacity = kDefaultHistoryCapacity,
    Iterable<double>? initial,
  })  : assert(capacity > 0, 'capacity must be positive'),
        _values = <double>[...(initial ?? const <double>[])] {
    while (_values.length > capacity) {
      _values.removeAt(0);
    }
  }

  /// Maximum number of retained samples.
  final int capacity;

  final List<double> _values;

  /// The retained samples, oldest first (unmodifiable snapshot).
  List<double> get values => List<double>.unmodifiable(_values);

  /// Number of currently retained samples.
  int get length => _values.length;

  /// Whether no samples have been recorded yet.
  bool get isEmpty => _values.isEmpty;

  /// Most recently recorded reading, or `null` when empty.
  double? get latest => _values.isEmpty ? null : _values.last;

  /// Smallest retained reading, or `null` when empty.
  double? get min =>
      _values.isEmpty ? null : _values.fold<double>(_values.first, _minDouble);

  /// Largest retained reading, or `null` when empty.
  double? get max =>
      _values.isEmpty ? null : _values.fold<double>(_values.first, _maxDouble);

  /// Appends [reading], dropping the oldest sample when at capacity.
  void add(double reading) {
    _values.add(reading);
    if (_values.length > capacity) {
      _values.removeAt(0);
    }
  }

  @override
  String toString() => 'ReadingHistory(${length}/$capacity)';
}

double _minDouble(double a, double b) => a < b ? a : b;
double _maxDouble(double a, double b) => a > b ? a : b;

/// Stable key for a thermal temperature's history series.
String thermalSeriesKey(String chassisId, String name) =>
    'thermal|$chassisId|$name';

/// Stable key for a fan's history series.
String fanSeriesKey(String chassisId, String name) => 'fan|$chassisId|$name';

/// Stable key for a generic sensor's history series.
String sensorSeriesKey(String chassisId, String name) =>
    'sensor|$chassisId|$name';

/// Accumulates per-sensor [ReadingHistory] across successive telemetry polls.
///
/// Series are keyed by reading kind + chassis id + name so two chassis with a
/// similarly named sensor never share a trend. A poll that reports no reading
/// for a sensor simply contributes no sample (its earlier history is retained).
class SensorHistoryStore {
  /// Creates an empty store whose series cap each hold [capacity] samples.
  SensorHistoryStore({this.capacity = kDefaultHistoryCapacity});

  /// Capacity applied to every newly created series.
  final int capacity;

  final Map<String, ReadingHistory> _series = <String, ReadingHistory>{};

  /// Number of distinct sensor series currently tracked.
  int get seriesCount => _series.length;

  /// Records all present readings in [snapshots] as one new sample per sensor.
  void record(Iterable<ChassisSensors> snapshots) {
    for (final ChassisSensors chassis in snapshots) {
      for (final ThermalReading reading in chassis.thermal) {
        final double? value = reading.readingCelsius;
        if (value != null) {
          _record(thermalSeriesKey(chassis.chassisId, reading.name), value);
        }
      }
      for (final FanReading reading in chassis.fans) {
        final double? value = reading.reading;
        if (value != null) {
          _record(fanSeriesKey(chassis.chassisId, reading.name), value);
        }
      }
      for (final SensorReading reading in chassis.sensors) {
        final double? value = reading.reading;
        if (value != null) {
          _record(sensorSeriesKey(chassis.chassisId, reading.name), value);
        }
      }
    }
  }

  void _record(String key, double value) {
    _series
        .putIfAbsent(key, () => ReadingHistory(capacity: capacity))
        .add(value);
  }

  /// Immutable snapshot of every series (key → oldest-first samples), suitable
  /// for storing in Riverpod UI state.
  Map<String, List<double>> snapshot() => <String, List<double>>{
        for (final MapEntry<String, ReadingHistory> entry in _series.entries)
          entry.key: entry.value.values,
      };

  /// Samples for [key], or an empty list when that sensor has no history.
  List<double> valuesFor(String key) =>
      _series[key]?.values ?? const <double>[];

  /// Clears all tracked series (e.g. when switching systems).
  void clear() => _series.clear();
}
