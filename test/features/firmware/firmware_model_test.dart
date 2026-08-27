import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';

void main() {
  group('FirmwareInventoryItem', () {
    test('parses a SoftwareInventory member from the DMTF SS mockup', () {
      final File file = File(
        'test/fixtures/redfish/dmtf_mockup/UpdateService/FirmwareInventory/SS/index.json',
      );
      final Map<String, dynamic> json =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final FirmwareInventoryItem item = FirmwareInventoryItem.fromJson(json);

      expect(item.id, 'SS');
      expect(item.name, isNotNull);
      expect(item.name, isNotEmpty);
      expect(item.version, isNotNull);
      expect(item.version, isNotEmpty);
      expect(item.updateable, isA<bool>());
      expect(item.health, 'OK');
      expect(item.relatedItems, isNotEmpty);
    });
  });

  group('UpdateServiceInfo', () {
    test('parses UpdateService payload with a hand-built inventory list', () {
      final File file = File(
        'test/fixtures/redfish/dmtf_mockup/UpdateService/index.json',
      );
      final Map<String, dynamic> body =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final List<FirmwareInventoryItem> inventory = <FirmwareInventoryItem>[
        const FirmwareInventoryItem(id: 'BMC', name: 'BMC', version: '1.0'),
      ];
      final UpdateServiceInfo info = UpdateServiceInfo.fromJson(
        body,
        inventory: inventory,
      );

      expect(info.serviceEnabled, isTrue);
      expect(info.httpPushUri, '/FWUpdate');
      expect(info.version, isNotNull);
      expect(info.version, isNotEmpty);
      expect(info.inventory.length, 1);
      expect(info.transferProtocols, isNotEmpty);
    });
  });

  group('SimpleUpdateRequest', () {
    test('serializes to the Redfish body shape', () {
      const SimpleUpdateRequest req = SimpleUpdateRequest(
        imageUri: 'http://host/fw.bin',
        transferProtocol: 'HTTP',
        targets: <String>[],
      );
      expect(req.toJson(), <String, dynamic>{
        'ImageURI': 'http://host/fw.bin',
        'TransferProtocol': 'HTTP',
        'Targets': <String>[],
      });
    });
  });
}
