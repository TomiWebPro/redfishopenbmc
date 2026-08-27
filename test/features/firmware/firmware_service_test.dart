import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  group('FirmwareService', () {
    late MockRedfishServer server;
    late RedfishClient client;

    setUp(() async {
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/dmtf_mockup',
      ).start();
      client = server.buildClient();
    });

    tearDown(() async {
      await server.close();
    });

    test('fetchUpdateService resolves service + inventory from the mockup', () async {
      final FirmwareService svc = FirmwareService(client: client, systemId: 'bmc1');
      final UpdateServiceInfo info = await svc.fetchUpdateService();

      expect(info.serviceEnabled, isTrue);
      expect(info.httpPushUri, '/FWUpdate');
      expect(info.inventory.length, greaterThanOrEqualTo(3));
      expect(
        info.inventory.any(
          (FirmwareInventoryItem i) => i.id == 'SS' || (i.name?.contains('SS') ?? false),
        ),
        isTrue,
      );
    });

    test('startSimpleUpdate POSTs and returns the Location task URI', () async {
      final FirmwareService svc = FirmwareService(client: client, systemId: 'bmc1');
      final String taskUri = await svc.startSimpleUpdate(
        const SimpleUpdateRequest(
          imageUri: 'http://host/fw.bin',
          transferProtocol: 'HTTP',
          targets: <String>[],
        ),
      );
      expect(taskUri, isNotEmpty);
    });
  });
}
