import 'dart:async';

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
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
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
  Future<UpdateTask> startSimpleUpdate(SimpleUpdateRequest req) async =>
      const UpdateTask(taskUri: 'http://task/1');
}

/// A [FakeFirmwareService] that fails on the first fetch, then succeeds —
/// the transient-failure shape the error+retry path exists for.
class _FlakyFirmwareService extends FakeFirmwareService {
  _FlakyFirmwareService()
      : super(
          info: const UpdateServiceInfo(
            serviceEnabled: true,
            version: '9.9.9',
            inventory: <FirmwareInventoryItem>[
              FirmwareInventoryItem(id: 'BMC', version: '9.9.9'),
            ],
          ),
        );

  int calls = 0;

  @override
  Future<UpdateServiceInfo> fetchUpdateService() async {
    calls++;
    if (calls == 1) {
      throw const RedfishException(message: 'boom');
    }
    return info ?? const UpdateServiceInfo();
  }
}

/// A [FirmwareService] double that never completes — the in-flight shape the
/// header's loading semantics describe.
class _NeverCompletingFirmwareService extends FakeFirmwareService {
  @override
  Future<UpdateServiceInfo> fetchUpdateService() =>
      Completer<UpdateServiceInfo>().future;
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

    testWidgets(
        'header announces one merged semantics label with the loading state '
        '(UI-2)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: _NeverCompletingFirmwareService(),
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
      // The post-frame auto-load starts; the fetch never completes, so the
      // header stays in the in-flight state with the merged semantics label.
      await tester.pump();
      expect(
        find.bySemanticsLabel('Firmware and update management, loading'),
        findsOneWidget,
      );
      // The visible title text still renders for sighted users.
      expect(find.text('Firmware & update management'), findsOneWidget);
    });

    testWidgets('header announces one merged semantics label when idle (UI-2)',
        (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(
          info: const UpdateServiceInfo(
            serviceEnabled: true,
            version: '9.9.9',
            inventory: <FirmwareInventoryItem>[
              FirmwareInventoryItem(id: 'BMC', version: '9.9.9'),
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
      // Idle header announces as one concise node without a status suffix.
      expect(
        find.bySemanticsLabel('Firmware and update management'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Firmware and update management, loading'),
        findsNothing,
      );
    });

    testWidgets('inventory card exposes a merged accessibility label (UI-2)',
        (tester) async {
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
                updateable: true,
                health: 'OK',
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
      // Screen readers announce the whole card as one concise summary.
      expect(
        find.bySemanticsLabel(
          'Firmware BMC Firmware, 3.2.1, OK, updateable',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'error state shows the message with a Retry button that reloads '
        '(UI-1)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final _FlakyFirmwareService service = _FlakyFirmwareService();
      final FirmwareController controller =
          FirmwareController(service: service);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(handle),
            firmwareControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: FirmwareView(systemId: 'bmc1')),
        ),
      );
      // The post-frame auto-load runs; the first fetch fails.
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      expect(find.text('boom'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Retry re-runs the load; the second fetch succeeds and clears the error.
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(service.calls, 2);
      expect(find.text('boom'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      expect(find.textContaining('9.9.9'), findsWidgets);
    });

    testWidgets(
        'queued update banner announces one merged accessibility label '
        '(UI-2, DOCS-10)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(
            taskUri: '/redfish/v1/TaskService/TaskMonitors/42',
            retryAfterSeconds: 30,
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
      // Screen readers get one concise summary of the queued update including
      // the Retry-After wait hint from the 202 (DSP0266 §12.2).
      expect(
        find.bySemanticsLabel(
          'Update queued, /redfish/v1/TaskService/TaskMonitors/42, '
          'retry after 30 seconds',
        ),
        findsOneWidget,
      );
      // The visible text carries the URI and the wait hint.
      expect(
        find.textContaining('Update queued: '
            '/redfish/v1/TaskService/TaskMonitors/42'),
        findsOneWidget,
      );
      expect(find.textContaining('retry after 30s'), findsOneWidget);
    });

    testWidgets('queued update banner handles an absent task URI (UI-1)',
        (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(),
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
      expect(
        find.bySemanticsLabel('Update queued, no task URI'),
        findsOneWidget,
      );
      expect(find.textContaining('(no task URI returned)'), findsOneWidget);
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
