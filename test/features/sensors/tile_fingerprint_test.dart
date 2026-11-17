// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/models/tile_fingerprint.dart';

void main() {
  group('tile fingerprints (#007 per-tile delta rebuild)', () {
    test('temperature fingerprint is identity-independent and complete', () {
      ThermalReading a() => ThermalReading(
            name: 'CPU1 Temp',
            readingCelsius: 41.0,
            status: const StatusInfo(state: 'Enabled', health: 'OK'),
            physicalContext: 'CPU',
            upperCaution: 45,
            upperCritical: 55,
            lowerCaution: 5,
            lowerCritical: 0,
            sourceUri: '/old',
          );

      // Two separately built but visually identical readings → equal fp.
      expect(temperatureTileFingerprint(a()), temperatureTileFingerprint(a()));

      expect(temperatureTileFingerprint(a()),
          isNot(temperatureTileFingerprint(a().copyWith(readingCelsius: 42))));
      expect(temperatureTileFingerprint(a()),
          isNot(temperatureTileFingerprint(a().copyWith(health: 'Warning'))));
      expect(temperatureTileFingerprint(a()),
          isNot(temperatureTileFingerprint(a().copyWith(upperCritical: 60))));
      expect(
          temperatureTileFingerprint(a()),
          isNot(temperatureTileFingerprint(
              a().copyWith(physicalContext: 'Ambient'))));
      expect(temperatureTileFingerprint(a()),
          isNot(temperatureTileFingerprint(a().copyWith(name: 'CPU2 Temp'))));
    });

    test('fan fingerprint covers reading, health, context and threshold', () {
      FanReading base() => FanReading(
            name: 'Fan0',
            reading: 5400,
            status: const StatusInfo(health: 'OK'),
            physicalContext: 'CPU',
            upperCritical: 7000,
          );

      expect(fanTileFingerprint(base()), fanTileFingerprint(base()));
      expect(fanTileFingerprint(base()),
          isNot(fanTileFingerprint(base().copyWith(reading: 5500))));
      expect(fanTileFingerprint(base()),
          isNot(fanTileFingerprint(base().copyWith(health: 'Critical'))));
      expect(
          fanTileFingerprint(base()),
          isNot(
              fanTileFingerprint(base().copyWith(physicalContext: 'Chassis'))));
      expect(fanTileFingerprint(base()),
          isNot(fanTileFingerprint(base().copyWith(upperCritical: 8000))));
    });

    test('sensor fingerprint covers type, units, reading and thresholds', () {
      SensorReading base() => SensorReading(
            name: 'PSU1',
            readingType: 'Voltage',
            readingUnits: 'V',
            reading: 12.5,
            status: const StatusInfo(health: 'OK'),
            thresholds: const <String, double>{
              'UpperCritical': 13.0,
              'LowerCritical': 11.0,
            },
          );

      expect(sensorTileFingerprint(base()), sensorTileFingerprint(base()));
      expect(sensorTileFingerprint(base()),
          isNot(sensorTileFingerprint(base().copyWith(reading: 12.8))));
      expect(sensorTileFingerprint(base()),
          isNot(sensorTileFingerprint(base().copyWith(readingUnits: 'mV'))));
      expect(
          sensorTileFingerprint(base()),
          isNot(
              sensorTileFingerprint(base().copyWith(readingType: 'Current'))));
      expect(
          sensorTileFingerprint(base()),
          isNot(sensorTileFingerprint(SensorReading(
            name: base().name,
            readingType: base().readingType,
            readingUnits: base().readingUnits,
            reading: base().reading,
            thresholds: const <String, double>{'UpperCritical': 14.0},
          ))));
    });

    test('voltage fingerprint covers reading, health, context and bounds', () {
      VoltageReading base() => VoltageReading(
            name: 'VCPU',
            readingVolts: 1.8,
            status: const StatusInfo(health: 'OK'),
            physicalContext: 'CPU',
            upperCaution: 2.0,
            upperCritical: 2.2,
          );

      expect(voltageTileFingerprint(base()), voltageTileFingerprint(base()));
      expect(voltageTileFingerprint(base()),
          isNot(voltageTileFingerprint(base().copyWith(readingVolts: 2.5))));
      expect(voltageTileFingerprint(base()),
          isNot(voltageTileFingerprint(base().copyWith(health: 'Critical'))));
      expect(
          voltageTileFingerprint(base()),
          isNot(voltageTileFingerprint(
              base().copyWith(physicalContext: 'Chassis'))));
      expect(voltageTileFingerprint(base()),
          isNot(voltageTileFingerprint(base().copyWith(upperCritical: 2.5))));
    });

    test('different reading kinds never collide on the same values', () {
      // Every helper produces a distinct namespace prefix so a temp, fan,
      // voltage and generic sensor with coincidentally equal fields cannot
      // gate each other out.
      expect(temperatureTileFingerprint(ThermalReading(name: 'x')),
          isNot(fanTileFingerprint(FanReading(name: 'x'))));
      expect(fanTileFingerprint(FanReading(name: 'x')),
          isNot(voltageTileFingerprint(VoltageReading(name: 'x'))));
      expect(voltageTileFingerprint(VoltageReading(name: 'x')),
          isNot(sensorTileFingerprint(SensorReading(name: 'x'))));
    });
  });
}

extension _VoltageCopy on VoltageReading {
  VoltageReading copyWith({
    double? readingVolts,
    String? health,
    String? physicalContext,
    double? upperCritical,
  }) =>
      VoltageReading(
        name: name,
        readingVolts: readingVolts ?? this.readingVolts,
        status:
            StatusInfo(state: status.state, health: health ?? status.health),
        physicalContext: physicalContext ?? this.physicalContext,
        upperCritical: upperCritical ?? this.upperCritical,
        upperCaution: upperCaution,
        lowerCritical: lowerCritical,
        lowerCaution: lowerCaution,
        sourceUri: sourceUri,
      );
}

// Small copy helpers keep the fingerprint tests readable without adding
// production-only `copyWith` methods to the immutable model classes.
extension _ThermalCopy on ThermalReading {
  ThermalReading copyWith({
    String? name,
    double? readingCelsius,
    String? health,
    double? upperCritical,
    String? physicalContext,
  }) =>
      ThermalReading(
        name: name ?? this.name,
        readingCelsius: readingCelsius ?? this.readingCelsius,
        status:
            StatusInfo(state: status.state, health: health ?? status.health),
        physicalContext: physicalContext ?? this.physicalContext,
        upperCritical: upperCritical ?? this.upperCritical,
        upperCaution: upperCaution,
        lowerCritical: lowerCritical,
        lowerCaution: lowerCaution,
        sourceUri: sourceUri,
      );
}

extension _FanCopy on FanReading {
  FanReading copyWith({
    double? reading,
    String? health,
    String? physicalContext,
    double? upperCritical,
  }) =>
      FanReading(
        name: name,
        reading: reading ?? this.reading,
        status:
            StatusInfo(state: status.state, health: health ?? status.health),
        physicalContext: physicalContext ?? this.physicalContext,
        upperCritical: upperCritical ?? this.upperCritical,
        sourceUri: sourceUri,
      );
}

extension _SensorCopy on SensorReading {
  SensorReading copyWith({
    double? reading,
    String? readingUnits,
    String? readingType,
  }) =>
      SensorReading(
        name: name,
        readingType: readingType ?? this.readingType,
        readingUnits: readingUnits ?? this.readingUnits,
        reading: reading ?? this.reading,
        status: status,
        thresholds: thresholds,
        sourceUri: sourceUri,
      );
}
