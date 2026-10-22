import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/features/firmware/firmware_controller.dart';
import 'package:redfishopenbmc/features/firmware/firmware_providers.dart';
import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/features/firmware/views/firmware_view.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [FirmwareService] double returning a canned [UpdateServiceInfo].
class FakeFirmwareService extends FirmwareService {
  /// Creates a [FakeFirmwareService].
  FakeFirmwareService({this.info}) : super(client: null, systemId: 'bmc1');

  /// The info returned by [fetchUpdateService].
  final UpdateServiceInfo? info;

  @override
  Future<UpdateServiceInfo> fetchUpdateService() async =>
      info ?? const UpdateServiceInfo();

  @override
  Future<String> startSimpleUpdate(SimpleUpdateRequest req) async =>
      'http://task/1';
}

SystemHandle makeHandle({required bool firmwareUpdate}) {
  final ConnectionProfile profile = const ConnectionProfile(
    id: 'bmc1',
    host: '127.0.0.1',
    name: 'bmc1',
  );
  return SystemHandle(
    profile: profile,
    features: SystemFeatures(
      systemId: 'bmc1',
      firmwareUpdate: firmwareUpdate,
    ),
  );
}

void main() {
  group('FirmwareView', () {
    testWidgets('renders nothing when firmwareUpdate is disabled',
        (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: false);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(handle),
            firmwareControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: FirmwareView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders inventory version after auto-load', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(
          info: const UpdateServiceInfo(
            serviceEnabled: true,
            version: '9.9.9',
            inventory: <FirmwareInventoryItem>[
              FirmwareInventoryItem(
                id: 'BMC',
                name: 'BMC Firmware',
                version: '3.2.1',
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(handle),
            firmwareControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: FirmwareView(systemId: 'bmc1')),
        ),
      );
      // Allow the post-frame auto-load to settle.
      await tester.pumpAndSettle();
      // The loaded version string should appear in the inventory card.
      expect(find.textContaining('3.2.1'), findsWidgets);
    });
  });

  group('FirmwareView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(
          info: const UpdateServiceInfo(
            serviceEnabled: true,
            version: '1.2.3',
            httpPushUri: '/FWUpdate',
            inventory: <FirmwareInventoryItem>[
              FirmwareInventoryItem(
                id: 'BMC',
                name: 'BMC Firmware',
                version: '3.2.1',
                updateable: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(handle),
            firmwareControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: FirmwareView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('renders without overflow at ${width.toInt()} px',
          (tester) async {
        await pumpAtWidth(tester, width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'FirmwareView must not overflow at $width px',
        );
        // Inventory + update form are visible at every breakpoint.
        expect(find.textContaining('BMC Firmware'), findsOneWidget);
        expect(find.text('Start update'), findsOneWidget);
      });
    }
  });
}
