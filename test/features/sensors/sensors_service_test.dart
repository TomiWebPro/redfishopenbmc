import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  group('SensorsService against the DMTF mockup', () {
    late MockRedfishServer server;

    setUp(() async {
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/dmtf_mockup',
      ).start();
    });

    tearDown(() async {
      await server.close();
    });

    test('fetchAll returns chassis telemetry with CPU1 Temp = 41.0', () async {
      final SensorsService svc = SensorsService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<ChassisSensors> all = await svc.fetchAll();

      expect(all, isNotEmpty);
      expect(all.first.thermal, isNotEmpty);
      expect(
        all.first.thermal
            .any((t) => t.name == 'CPU1 Temp' && t.readingCelsius == 41.0),
        isTrue,
      );
      expect(all.first.fans, isNotEmpty);
      expect(all.first.sensors, isNotEmpty);
    });

    test('fetchChassis works for a full @odata.id', () async {
      final SensorsService svc = SensorsService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final ChassisSensors cs =
          await svc.fetchChassis('/redfish/v1/Chassis/1U');

      expect(cs.chassisId, '1U');
      expect(cs.chassisName, 'Computer System Chassis');
      expect(cs.thermal, isNotEmpty);
      expect(
        cs.thermal
            .any((t) => t.name == 'CPU1 Temp' && t.readingCelsius == 41.0),
        isTrue,
      );
      expect(cs.sensors, isNotEmpty);
    });

    test('throws RedfishException when not connected', () async {
      final SensorsService svc = SensorsService(client: null, systemId: 'bmc1');
      expect(
        () => svc.fetchAll(),
        throwsA(isA<RedfishException>()),
      );
    });
  });

  group('SensorsService — bounded sensor fetch concurrency (#019)', () {
    test('limits concurrent sensor member fetches and preserves results',
        () async {
      final _GatedClient client = _GatedClient();
      final SensorsService svc =
          SensorsService(client: client, systemId: 'bmc1');

      final List<ChassisSensors> result = <ChassisSensors>[];
      final Future<void> done = () async {
        result.add(await svc.fetchChassis('/redfish/v1/Chassis/1U'));
      }();

      // Let fetchChassis issue chassis+thermal+sensors collection requests and
      // start sensor member fetches, which will block on the gate.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(client.maxSensorInFlight, lessThanOrEqualTo(4));
      expect(client.maxSensorInFlight, greaterThan(1));

      client.release();
      await done;

      expect(result.single.sensors, hasLength(6));
      expect(
        result.single.sensors.map((SensorReading s) => s.name),
        containsAll(<String>[
          'CPU1 Temp Sensor',
          'Fan1 Sensor',
          'PSU1 Sensor',
          'PSU2 Sensor',
          'Voltage Sensor',
          'Current Sensor',
        ]),
      );
    });
  });

  // Real OpenBMC payload shapes (captured in test/fixtures/redfish/) drive the
  // service end-to-end, including the legacy `ReadingRPM` fan field and the
  // two-member Sensors collection (issue #007 acceptance: OpenBMC fixtures).
  group('SensorsService — OpenBMC fixture coverage (#007)', () {
    const String chassisBase = '/redfish/v1/Chassis/chassis';

    test('parses OpenBMC Thermal temperatures and ReadingRPM fans', () async {
      final SensorsService svc = SensorsService(
        client: _FixtureClient(),
        systemId: 'bmc1',
      );

      final ChassisSensors cs = await svc.fetchChassis(chassisBase);

      expect(cs.chassisId, 'chassis');
      expect(cs.chassisName, 'Chassis');
      expect(cs.thermal.map((ThermalReading t) => t.name),
          containsAll(<String>['CPU1 Temp', 'Inlet Temp']));
      final ThermalReading cpu =
          cs.thermal.firstWhere((ThermalReading t) => t.name == 'CPU1 Temp');
      expect(cpu.readingCelsius, 42.0);
      expect(cpu.sourceUri, '$chassisBase/Thermal');
      expect(cs.fans, hasLength(1));
      expect(cs.fans.single.name, 'Fan0');
      // OpenBMC exposes fan speed as `ReadingRPM`, not modern `Reading`.
      expect(cs.fans.single.reading, 4000.0);
      expect(cs.fans.single.sourceUri, '$chassisBase/Thermal');
    });

    test('parses OpenBMC Sensors collection into typed readings', () async {
      final SensorsService svc = SensorsService(
        client: _FixtureClient(),
        systemId: 'bmc1',
      );

      final ChassisSensors cs = await svc.fetchChassis(chassisBase);

      expect(cs.sensors, hasLength(2));
      final SensorReading temp =
          cs.sensors.firstWhere((SensorReading s) => s.name == 'Temp 0');
      expect(temp.reading, 38.0);
      expect(temp.readingUnits, 'C');
      expect(temp.sourceUri, '$chassisBase/Sensors/temp0');
      final SensorReading fan =
          cs.sensors.firstWhere((SensorReading s) => s.name == 'Fan 0');
      expect(fan.reading, 4200.0);
      expect(fan.readingUnits, 'RPM');
      expect(fan.sourceUri, '$chassisBase/Sensors/fan0');
    });

    test('evaluates threshold breaches from OpenBMC thermal payload', () async {
      // Inject a critical upper bound on CPU1 Temp (42°C) and a caution bound
      // on Inlet Temp (23°C) into the real fixture to test evaluation.
      final Map<String, dynamic> thermal =
          _FixtureClient.fixture('openbmc_thermal.json');
      final List<dynamic> temps = thermal['Temperatures'] as List<dynamic>;
      (temps.first as Map<String, dynamic>)['UpperThresholdCritical'] = 40.0;
      (temps[1] as Map<String, dynamic>)['UpperThresholdNonCritical'] = 20.0;
      final SensorsService svc = SensorsService(
        client: _FixtureClient(overrides: <String, Map<String, dynamic>>{
          '$chassisBase/Thermal': thermal,
        }),
        systemId: 'bmc1',
      );

      final ChassisSensors cs = await svc.fetchChassis(chassisBase);

      expect(
        cs.alerts.any((SensorAlert a) =>
            a.name == 'CPU1 Temp' && a.level == SensorAlertLevel.critical),
        isTrue,
      );
      expect(
        cs.alerts.any((SensorAlert a) =>
            a.name == 'Inlet Temp' && a.level == SensorAlertLevel.warning),
        isTrue,
      );
    });

    test('a chassis with no Thermal or Sensors yields an empty snapshot',
        () async {
      final SensorsService svc = SensorsService(
        client: _FixtureClient(),
        systemId: 'bmc1',
      );

      // No routes exist for `/Chassis/missing` (or its sub-resources): every
      // request 404s and the service degrades gracefully instead of throwing.
      final ChassisSensors cs =
          await svc.fetchChassis('/redfish/v1/Chassis/missing');

      expect(cs.chassisId, 'missing');
      expect(cs.chassisName, 'missing');
      expect(cs.thermal, isEmpty);
      expect(cs.fans, isEmpty);
      expect(cs.sensors, isEmpty);
      expect(cs.alerts, isEmpty);
    });
  });
}

/// Serves the captured OpenBMC fixtures by request path, so [SensorsService]
/// is exercised against authentic payload shapes without a live BMC.
class _FixtureClient extends RedfishClient {
  _FixtureClient({Map<String, Map<String, dynamic>>? overrides})
      : _overrides = overrides ?? const <String, Map<String, dynamic>>{},
        super(
          profile: const ConnectionProfile(
            id: 't',
            host: 'h',
            allowSelfSigned: true,
          ),
        );

  static const String _chassisBase = '/redfish/v1/Chassis/chassis';

  final Map<String, Map<String, dynamic>> _overrides;

  /// Loads and decodes a JSON fixture from `test/fixtures/redfish/`.
  static Map<String, dynamic> fixture(String name) =>
      jsonDecode(File('test/fixtures/redfish/$name').readAsStringSync())
          as Map<String, dynamic>;

  static Map<String, Map<String, dynamic>> _routes() =>
      <String, Map<String, dynamic>>{
        _chassisBase: fixture('openbmc_chassis_member.json'),
        '$_chassisBase/Thermal': fixture('openbmc_thermal.json'),
        '$_chassisBase/Sensors': fixture('openbmc_sensors.json'),
        '$_chassisBase/Sensors/fan0': fixture('openbmc_sensor_fan0.json'),
        '$_chassisBase/Sensors/temp0': fixture('openbmc_sensor_temp0.json'),
      };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    final Map<String, Map<String, dynamic>> all =
        <String, Map<String, dynamic>>{
      ..._routes(),
      ..._overrides,
    };
    final Map<String, dynamic>? body = all[path];
    if (body == null) {
      throw RedfishException(
        message: 'not found: $path',
        statusCode: 404,
        errorCode: 'Base.1.0.ResourceNotFound',
      );
    }
    return body;
  }
}

class _GatedClient extends RedfishClient {
  _GatedClient()
      : super(
          profile: const ConnectionProfile(
            id: 't',
            host: 'h',
            allowSelfSigned: true,
          ),
        );

  final Completer<void> _gate = Completer<void>();
  int _sensorInFlight = 0;
  int maxSensorInFlight = 0;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  bool _isSensorMember(String path) =>
      path.startsWith('/redfish/v1/Chassis/1U/Sensors/');

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    if (_isSensorMember(path)) {
      _sensorInFlight++;
      if (_sensorInFlight > maxSensorInFlight) {
        maxSensorInFlight = _sensorInFlight;
      }
      await _gate.future;
      _sensorInFlight--;
      final String name = Uri.decodeComponent(path.split('/').last);
      return <String, dynamic>{
        'Name': '$name Sensor',
        'Reading': 1.0,
        'Status': <String, dynamic>{'Health': 'OK'},
      };
    }

    switch (path) {
      case '/redfish/v1/Chassis/1U':
        return <String, dynamic>{'Id': '1U', 'Name': 'Chassis 1U'};
      case '/redfish/v1/Chassis/1U/Thermal':
        return <String, dynamic>{
          'Temperatures': <dynamic>[],
          'Fans': <dynamic>[]
        };
      case '/redfish/v1/Chassis/1U/Sensors':
        return <String, dynamic>{
          'Members': <Map<String, String>>[
            <String, String>{
              '@odata.id': '/redfish/v1/Chassis/1U/Sensors/CPU1%20Temp'
            },
            <String, String>{
              '@odata.id': '/redfish/v1/Chassis/1U/Sensors/Fan1'
            },
            <String, String>{
              '@odata.id': '/redfish/v1/Chassis/1U/Sensors/PSU1'
            },
            <String, String>{
              '@odata.id': '/redfish/v1/Chassis/1U/Sensors/PSU2'
            },
            <String, String>{
              '@odata.id': '/redfish/v1/Chassis/1U/Sensors/Voltage'
            },
            <String, String>{
              '@odata.id': '/redfish/v1/Chassis/1U/Sensors/Current'
            },
          ],
        };
      default:
        return <String, dynamic>{};
    }
  }
}
