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

    test('parses HttpPushUriOptions apply-time modes (DOCS-4 / #008/#020)', () {
      final File file = File(
        'test/fixtures/redfish/dmtf_mockup/UpdateService/index.json',
      );
      final Map<String, dynamic> body =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final UpdateServiceInfo info = UpdateServiceInfo.fromJson(body);

      expect(info.httpPushUri, '/FWUpdate');
      // The DMTF mockup publishes a current mode + the AllowableValues list.
      expect(info.httpPushApplyTime, 'Immediate');
      expect(info.httpPushApplyTimes, <String>[
        'Immediate',
        'OnReset',
        'AtMaintenanceWindowStart',
        'InMaintenanceWindowOnReset',
      ]);
    });

    test('push apply-time fields are empty when HttpPushUriOptions is absent',
        () {
      final UpdateServiceInfo info = UpdateServiceInfo.fromJson(
        <String, dynamic>{
          'Id': 'UpdateService',
          'ServiceEnabled': true,
          'HttpPushUri': '/FWUpdate',
        },
      );
      expect(info.httpPushUri, '/FWUpdate');
      expect(info.httpPushApplyTime, isNull);
      expect(info.httpPushApplyTimes, isEmpty);
    });

    test(
        'parses MultipartHttpPushUri (bmcweb / DMTF v1_17_1, DOCS-4 #008/#020)',
        () {
      final UpdateServiceInfo info = UpdateServiceInfo.fromJson(
        <String, dynamic>{
          'Id': 'UpdateService',
          'ServiceEnabled': true,
          'HttpPushUri': '/FWUpdate',
          'MultipartHttpPushUri': '/upload/image',
        },
      );
      expect(info.httpPushUri, '/FWUpdate');
      expect(info.multipartHttpPushUri, '/upload/image');
    });

    test('multipartHttpPushUri is null when absent', () {
      final File file = File(
        'test/fixtures/redfish/dmtf_mockup/UpdateService/index.json',
      );
      final Map<String, dynamic> body =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      // The DMTF mockup publishes only HttpPushUri, not MultipartHttpPushUri.
      final UpdateServiceInfo info = UpdateServiceInfo.fromJson(body);
      expect(info.httpPushUri, '/FWUpdate');
      expect(info.multipartHttpPushUri, isNull);
    });

    test('copyWithInventory preserves multipartHttpPushUri', () {
      final UpdateServiceInfo info = UpdateServiceInfo.fromJson(
        <String, dynamic>{
          'Id': 'UpdateService',
          'ServiceEnabled': true,
          'HttpPushUri': '/FWUpdate',
          'MultipartHttpPushUri': '/upload/image',
        },
        inventory: const <FirmwareInventoryItem>[
          FirmwareInventoryItem(id: 'BMC'),
        ],
      );
      final UpdateServiceInfo copied = info.copyWithInventory(
        const <FirmwareInventoryItem>[
          FirmwareInventoryItem(id: 'BMC'),
          FirmwareInventoryItem(id: 'SS'),
        ],
      );
      expect(copied.multipartHttpPushUri, '/upload/image');
      expect(copied.httpPushUri, '/FWUpdate');
      expect(copied.inventory.length, 2);
    });

    test('parses an explicitly disabled UpdateService (DOCS-5)', () {
      final UpdateServiceInfo info = UpdateServiceInfo.fromJson(
        <String, dynamic>{
          'Id': 'UpdateService',
          'ServiceEnabled': false,
        },
      );
      expect(info.serviceEnabled, isFalse);
      expect(info.httpPushUri, isNull);
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
