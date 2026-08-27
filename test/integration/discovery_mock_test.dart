import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery_engine.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

import '../helpers/mock_redfish_server.dart';

/// End-to-end "test platform" suite: spins up the real DMTF `public-rackmount1`
/// mockup over HTTP and drives the discovery engine + every feature service
/// against authentic Redfish payload shapes (no live BMC required).
void main() {
  late MockRedfishServer server;

  setUpAll(() async {
    server = await MockRedfishServer(
      fixturesDir: 'test/fixtures/redfish/dmtf_mockup',
    ).start();
  });

  tearDownAll(() async {
    await server.close();
  });

  test('DiscoveryEngine detects capabilities from the real mockup', () async {
    final client = server.buildClient();
    final SystemFeatures features =
        await DiscoveryEngine().discover(client, 'bmc1');

    // The DMTF rackmount mockup exposes all of these.
    expect(features.powerControl, isTrue,
        reason: 'ComputerSystem.Reset action must be detected');
    // NOTE: the DMTF mockup omits `SupportedResetTypes` on the system, so the
    // list may legitimately be empty; we only require it to be a well-typed list.
    expect(features.supportedResetTypes, isA<List<String>>());
    expect(features.sensorMonitoring, isTrue,
        reason: 'Chassis Thermal/Sensors links must be detected');
    expect(features.sensorCount, greaterThan(0),
        reason: 'At least one readable sensor should be counted');
    expect(features.firmwareUpdate, isTrue,
        reason: 'UpdateService must be detected');
    expect(features.kvm, isTrue,
        reason: 'Manager GraphicalConsole (ServiceEnabled) must be detected');
    expect(features.kvmType, 'GraphicalConsole');
    expect(features.managers, greaterThan(0));
    expect(features.chassis, greaterThan(0));
  });

  test('SensorsService parses the real Thermal / Sensors payloads', () async {
    final client = server.buildClient();
    final List<ChassisSensors> all =
        await SensorsService(client: client, systemId: 'bmc1').fetchAll();
    expect(all, isNotEmpty);
    final ChassisSensors chassis = all.first;
    expect(chassis.thermal, isNotEmpty);
    expect(
      chassis.thermal.any((t) => t.name == 'CPU1 Temp' && t.readingCelsius == 41.0),
      isTrue,
    );
  });

  test('FirmwareService enumerates the real FirmwareInventory', () async {
    final client = server.buildClient();
    final UpdateServiceInfo info = await FirmwareService(
      client: client,
      systemId: 'bmc1',
    ).fetchUpdateService();
    expect(info.serviceEnabled, isTrue);
    expect(info.inventory.length, greaterThanOrEqualTo(3));
    expect(
      info.inventory
          .where((i) => i.version != null && i.version!.isNotEmpty)
          .isNotEmpty,
      isTrue,
    );
  });

  test('KvmService discovers the real manager consoles', () async {
    final client = server.buildClient();
    final List<KvmConsole> consoles =
        await KvmService(client: client, systemId: 'bmc1').fetchConsoles();
    expect(consoles, isNotEmpty);
    expect(
      consoles.any((c) => c.type == KvmConsoleType.graphical),
      isTrue,
    );
  });
}
