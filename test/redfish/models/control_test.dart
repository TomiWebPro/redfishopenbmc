import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/models/control.dart';

/// Unit tests for the [ControlResource] model and its SetPoint
/// pre-validation rule (issue #006/#016/#019/#022; `Control.v1_5_0.json`).
void main() {
  group('ControlResource.fromJson', () {
    test('parses a full PowerLimit payload (fixture shape)', () {
      final ControlResource c = ControlResource.fromJson(<String, dynamic>{
        '@odata.type': '#Control.v1_5_0.Control',
        'Id': 'PowerLimit',
        'Name': 'System Power Limit',
        'ControlType': 'Power',
        'ControlMode': 'Automatic',
        'SetPoint': 500,
        'SetPointUnits': 'W',
        'AllowableMax': 1000,
        'AllowableMin': 150,
        'Sensor': <String, dynamic>{
          'Reading': 374,
          'DataSourceUri': '/redfish/v1/Chassis/1U/Sensors/TotalPower',
        },
      });

      expect(c.id, 'PowerLimit');
      expect(c.controlType, 'Power');
      expect(c.controlMode, 'Automatic');
      expect(c.setPoint, 500);
      expect(c.setPointUnits, 'W');
      expect(c.allowableMin, 150);
      expect(c.allowableMax, 1000);
      expect(
          c.sensorDataSourceUri, '/redfish/v1/Chassis/1U/Sensors/TotalPower');
      expect(c.hasAllowableBounds, isTrue);
    });

    test('parses a CPU1Freq frequency payload', () {
      final ControlResource c = ControlResource.fromJson(<String, dynamic>{
        '@odata.type': '#Control.v1_5_0.Control',
        'Id': 'CPU1Freq',
        'ControlType': 'Frequency',
        'ControlMode': 'Automatic',
        'SetPoint': 2000,
        'SetPointUnits': 'Hz',
        'AllowableMin': 1500,
        'AllowableMax': 3700,
      });

      expect(c.id, 'CPU1Freq');
      expect(c.controlType, 'Frequency');
      expect(c.setPoint, 2000);
      expect(c.setPointUnits, 'Hz');
      expect(c.allowableMin, 1500);
      expect(c.allowableMax, 3700);
    });

    test('tolerates an empty/minimal payload without throwing', () {
      final ControlResource c = ControlResource.fromJson(<String, dynamic>{});
      expect(c.id, '');
      expect(c.controlType, isNull);
      expect(c.controlMode, isNull);
      expect(c.setPoint, isNull);
      expect(c.allowableMin, isNull);
      expect(c.allowableMax, isNull);
      expect(c.sensorDataSourceUri, isNull);
      expect(c.hasAllowableBounds, isFalse);
    });

    test('tolerates a null SetPoint (schema allows it) and string numbers', () {
      final ControlResource c = ControlResource.fromJson(<String, dynamic>{
        'Id': 'PowerLimit',
        'SetPoint': null,
        'AllowableMin': '150',
        'AllowableMax': '1000',
      });
      expect(c.setPoint, isNull);
      expect(c.allowableMin, 150);
      expect(c.allowableMax, 1000);
    });

    test('ignores a malformed Sensor excerpt', () {
      final ControlResource c = ControlResource.fromJson(<String, dynamic>{
        'Id': 'PowerLimit',
        'Sensor': 'not-a-map',
      });
      expect(c.sensorDataSourceUri, isNull);
    });
  });

  group('ControlResource.validateSetPoint', () {
    ControlResource powerLimit() => ControlResource.fromJson(<String, dynamic>{
          'Id': 'PowerLimit',
          'SetPoint': 500,
          'AllowableMin': 150,
          'AllowableMax': 1000,
        });

    test('accepts in-range values', () {
      expect(powerLimit().validateSetPoint(400).valid, isTrue);
      expect(powerLimit().validateSetPoint(500).valid, isTrue);
      expect(powerLimit().validateSetPoint(999).valid, isTrue);
    });

    test('accepts the exact AllowableMin/Max boundaries (inclusive)', () {
      final SetPointValidation minV = powerLimit().validateSetPoint(150);
      expect(minV.valid, isTrue);
      expect(minV.message, isNull);
      final SetPointValidation maxV = powerLimit().validateSetPoint(1000);
      expect(maxV.valid, isTrue);
      expect(maxV.message, isNull);
    });

    test('rejects out-of-range values with an Allowable-range message', () {
      for (final num value in <num>[149, 1001, 0, -1]) {
        final SetPointValidation v = powerLimit().validateSetPoint(value);
        expect(v.valid, isFalse, reason: '$value must be rejected');
        expect(v.message, contains('Allowable'));
        expect(v.message, contains('[150, 1000]'));
      }
    });

    test('rejects a null prospective value', () {
      final SetPointValidation v = powerLimit().validateSetPoint(null);
      expect(v.valid, isFalse);
      expect(v.message, contains('required'));
    });

    test('valid with an informational message when no bounds are advertised',
        () {
      final ControlResource unbounded = ControlResource.fromJson(
          <String, dynamic>{'Id': 'PowerLimit', 'SetPoint': 500});
      expect(unbounded.hasAllowableBounds, isFalse);
      final SetPointValidation v = unbounded.validateSetPoint(9999);
      expect(v.valid, isTrue,
          reason: 'no bounds to pre-validate against — best-effort PATCH');
      expect(v.message, contains('No AllowableMin/Max'));
    });

    test('per-resource bounds never leak across controls', () {
      // The SecureBoot per-resource allow-list precedent: bound sets are a
      // property of each control resource, never shared.
      final ControlResource cpu = ControlResource.fromJson(<String, dynamic>{
        'Id': 'CPU1Freq',
        'AllowableMin': 1500,
        'AllowableMax': 3700,
      });
      expect(powerLimit().validateSetPoint(1500).valid, isFalse,
          reason: '1500 is inside CPU1Freq bounds but far above PowerLimit '
              'AllowableMax 1000');
      expect(cpu.validateSetPoint(1500).valid, isTrue);
    });
  });
}
