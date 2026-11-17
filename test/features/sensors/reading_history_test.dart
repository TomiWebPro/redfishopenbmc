// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/reading_history.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';

void main() {
  group('ReadingHistory (ring buffer)', () {
    test('defaults to 20 samples and tracks oldest-first order', () {
      final ReadingHistory history = ReadingHistory();
      expect(history.capacity, kDefaultHistoryCapacity);
      expect(history.isEmpty, isTrue);
      expect(history.latest, isNull);
      expect(history.min, isNull);
      expect(history.max, isNull);

      history.add(41.0);
      history.add(42.5);
      history.add(40.0);
      expect(history.length, 3);
      expect(history.values, <double>[41.0, 42.5, 40.0]);
      expect(history.latest, 40.0);
      expect(history.min, 40.0);
      expect(history.max, 42.5);
    });

    test('evicts the oldest sample once capacity is exceeded', () {
      final ReadingHistory history = ReadingHistory(capacity: 3);
      for (int i = 1; i <= 5; i++) {
        history.add(i.toDouble());
      }
      expect(history.values, <double>[3.0, 4.0, 5.0]);
      expect(history.length, 3);
      expect(history.latest, 5.0);
    });

    test('trims initial values to capacity and exposes an immutable view', () {
      final ReadingHistory history =
          ReadingHistory(capacity: 2, initial: <double>[1, 2, 3, 4]);
      expect(history.values, <double>[3.0, 4.0]);
      expect(
        () => history.values.add(9),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('SensorHistoryStore', () {
    ChassisSensors _snapshot(double temp, double fan, double sensor) =>
        ChassisSensors(
          chassisId: '1U',
          thermal: <ThermalReading>[
            ThermalReading(name: 'CPU', readingCelsius: temp),
          ],
          fans: <FanReading>[FanReading(name: 'FAN0', reading: fan)],
          sensors: <SensorReading>[
            SensorReading(name: 'PSU', reading: sensor),
          ],
        );

    test('key helpers keep kind, chassis and name distinct', () {
      expect(thermalSeriesKey('1U', 'CPU'), isNot(fanSeriesKey('1U', 'CPU')));
      expect(fanSeriesKey('1U', 'FAN'), isNot(fanSeriesKey('2U', 'FAN')));
      expect(
        sensorSeriesKey('1U', 'PSU'),
        isNot(thermalSeriesKey('1U', 'PSU')),
      );
    });

    test('records one sample per present reading across polls', () {
      final SensorHistoryStore store = SensorHistoryStore(capacity: 3);
      store.record(<ChassisSensors>[_snapshot(40, 5000, 12)]);
      store.record(<ChassisSensors>[_snapshot(41, 5100, 12.1)]);

      expect(store.seriesCount, 3);
      expect(store.valuesFor(thermalSeriesKey('1U', 'CPU')), <double>[40, 41]);
      expect(store.valuesFor(fanSeriesKey('1U', 'FAN0')), <double>[5000, 5100]);
      expect(store.valuesFor(sensorSeriesKey('1U', 'PSU')), <double>[12, 12.1]);
      expect(store.valuesFor('missing'), isEmpty);
    });

    test('applies capacity eviction and retains history for absent readings',
        () {
      final SensorHistoryStore store = SensorHistoryStore(capacity: 2);
      store.record(<ChassisSensors>[_snapshot(40, 1, 1)]);
      store.record(<ChassisSensors>[_snapshot(42, 2, 2)]);
      // Third poll reports no temperature reading: its earlier history is
      // retained, while fan/sensor continue to accumulate (and evict).
      store.record(<ChassisSensors>[
        ChassisSensors(
          chassisId: '1U',
          thermal: <ThermalReading>[
            const ThermalReading(name: 'CPU', readingCelsius: null),
          ],
          fans: <FanReading>[const FanReading(name: 'FAN0', reading: 3)],
          sensors: <SensorReading>[
            const SensorReading(name: 'PSU', reading: 3)
          ],
        ),
      ]);

      expect(store.valuesFor(thermalSeriesKey('1U', 'CPU')), <double>[40, 42]);
      expect(store.valuesFor(fanSeriesKey('1U', 'FAN0')), <double>[2, 3]);
      expect(store.valuesFor(sensorSeriesKey('1U', 'PSU')), <double>[2, 3]);
    });

    test('snapshot is a detached immutable map of the current series', () {
      final SensorHistoryStore store = SensorHistoryStore();
      store.record(<ChassisSensors>[_snapshot(40, 1, 1)]);
      final Map<String, List<double>> snapshot = store.snapshot();
      expect(snapshot[thermalSeriesKey('1U', 'CPU')], <double>[40]);

      store.record(<ChassisSensors>[_snapshot(41, 2, 2)]);
      expect(snapshot[thermalSeriesKey('1U', 'CPU')], <double>[40]);
      expect(store.snapshot()[thermalSeriesKey('1U', 'CPU')], <double>[40, 41]);

      store.clear();
      expect(store.seriesCount, 0);
      expect(store.snapshot(), isEmpty);
    });
  });
}
