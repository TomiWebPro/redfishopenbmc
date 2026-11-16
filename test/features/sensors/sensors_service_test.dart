import 'dart:async';

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
