import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
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
}
