// ignore_for_file: prefer_const_constructors
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';

/// Path to the DMTF `public-rackmount1` mockup's Thermal resource for chassis 1U.
const String _thermalFixture =
    'test/fixtures/redfish/dmtf_mockup/Chassis/1U/Thermal/index.json';

/// Path to a single Sensor resource from the same mockup.
const String _sensorFixture =
    'test/fixtures/redfish/dmtf_mockup/Chassis/1U/Sensors/PS1Out12VCurrent/index.json';

void main() {
  group('ChassisSensors model', () {
    late Map<String, dynamic> thermalJson;
    late Map<String, dynamic> sensorJson;

    setUp(() {
      thermalJson = jsonDecode(File(_thermalFixture).readAsStringSync())
          as Map<String, dynamic>;
      sensorJson = jsonDecode(File(_sensorFixture).readAsStringSync())
          as Map<String, dynamic>;
    });

    test('parses temperatures, fans, and a sensor from real mockup shapes', () {
      final ChassisSensors fromThermal =
          ChassisSensors.fromThermalJson('1U', thermalJson);
      final SensorReading sensor = SensorReading.fromJson(sensorJson);

      final ChassisSensors cs = ChassisSensors(
        chassisId: '1U',
        chassisName: 'Computer System Chassis',
        thermal: fromThermal.thermal,
        fans: fromThermal.fans,
        sensors: <SensorReading>[sensor],
      );

      expect(cs.thermal.length, greaterThanOrEqualTo(3));
      final ThermalReading cpu1 =
          cs.thermal.firstWhere((t) => t.name == 'CPU1 Temp');
      expect(cpu1.readingCelsius, 41.0);
      expect(cpu1.physicalContext, 'CPU');
      expect(cpu1.upperCritical, 45.0);

      expect(cs.fans, isNotEmpty);
      expect(cs.fans.first.reading, 2100.0);
      expect(cs.fans.first.reading, isNotNull);

      expect(sensor.reading, 2.79);
      expect(sensor.readingUnits, 'A');
      expect(sensor.readingType, 'Current');
      expect(sensor.thresholds['UpperCritical'], 7.0);
    });

    test('StatusInfo maps Redfish health string to Health enum', () {
      expect(const StatusInfo(health: 'OK').healthEnum, Health.ok);
      expect(const StatusInfo(health: 'Warning').healthEnum, Health.warning);
      expect(const StatusInfo(health: 'Critical').healthEnum, Health.critical);
      expect(const StatusInfo(health: 'Nonsense').healthEnum, Health.unknown);
      expect(const StatusInfo().healthEnum, Health.unknown);
    });

    test('fromThermalJson tolerates missing or non-list Temperatures/Fans', () {
      final ChassisSensors cs = ChassisSensors.fromThermalJson(
        '1U',
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Chassis/1U/Thermal',
          'Temperatures': null,
          'Fans': 'not-a-list',
        },
      );
      expect(cs.thermal, isEmpty);
      expect(cs.fans, isEmpty);
    });
  });

  group('ChassisSensors alerts (#007)', () {
    test('no alerts when readings are healthy and within thresholds', () {
      final ChassisSensors cs = ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(
            name: 'CPU1 Temp',
            readingCelsius: 41,
            upperCaution: 45,
            upperCritical: 55,
            status: const StatusInfo(health: 'OK'),
          ),
        ],
        fans: <FanReading>[
          FanReading(
            name: 'Fan0',
            reading: 5400,
            upperCritical: 7000,
            status: const StatusInfo(health: 'OK'),
          ),
        ],
        sensors: <SensorReading>[
          SensorReading(
            name: 'PSU1',
            reading: 12.5,
            readingUnits: 'V',
            thresholds: const <String, double>{
              'UpperCritical': 13,
              'LowerCritical': 11,
            },
            status: const StatusInfo(health: 'OK'),
          ),
        ],
      );

      expect(cs.alerts, isEmpty);
    });

    test('upper critical breach alerts even when health reports OK', () {
      final ChassisSensors cs = ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(
            name: 'CPU1 Temp',
            readingCelsius: 60,
            upperCritical: 55,
            status: const StatusInfo(health: 'OK'),
          ),
        ],
      );

      expect(cs.alerts, hasLength(1));
      expect(cs.alerts.single.name, 'CPU1 Temp');
      expect(cs.alerts.single.level, SensorAlertLevel.critical);
      expect(cs.alerts.single.description, contains('60.0 °C'));
      expect(cs.alerts.single.description, contains('Critical'));
    });

    test('health warning/critical alert without a reading', () {
      final ChassisSensors cs = ChassisSensors(
        chassisId: '1U',
        fans: <FanReading>[
          FanReading(
            name: 'Fan0',
            status: const StatusInfo(health: 'Warning'),
          ),
        ],
        sensors: <SensorReading>[
          SensorReading(
            name: 'PSU1',
            status: const StatusInfo(health: 'Critical'),
          ),
        ],
      );

      expect(
        cs.alerts.map((SensorAlert a) => a.level).toList(),
        <SensorAlertLevel>[
          SensorAlertLevel.warning,
          SensorAlertLevel.critical,
        ],
      );
      expect(cs.alerts.first.description, contains('no reading'));
    });

    test('caution breach is warning; lower critical breach is critical', () {
      final ChassisSensors cs = ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(
            name: 'CPU1 Temp',
            readingCelsius: 48,
            upperCaution: 45,
            upperCritical: 55,
          ),
        ],
        sensors: <SensorReading>[
          SensorReading(
            name: 'PSU1',
            reading: 10,
            readingUnits: 'V',
            thresholds: const <String, double>{'LowerCritical': 11},
          ),
        ],
      );

      expect(
        cs.alerts.map((SensorAlert a) => a.level).toList(),
        <SensorAlertLevel>[
          SensorAlertLevel.warning,
          SensorAlertLevel.critical,
        ],
      );
    });

    test('critical health wins over a warning-only threshold breach', () {
      final ChassisSensors cs = ChassisSensors(
        chassisId: '1U',
        thermal: <ThermalReading>[
          ThermalReading(
            name: 'CPU1 Temp',
            readingCelsius: 48,
            upperCaution: 45,
            status: const StatusInfo(health: 'Critical'),
          ),
        ],
      );

      expect(cs.alerts, hasLength(1));
      expect(cs.alerts.single.level, SensorAlertLevel.critical);
    });
  });
}
