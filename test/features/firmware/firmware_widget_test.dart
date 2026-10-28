import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
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
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';
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

/// A [FirmwareService] double whose [FirmwareService.pushImage] reports byte
/// progress then blocks until the test completes [gate] — the in-flight upload
/// shape the upload banner renders (#008/#020).
class _UploadingFirmwareService extends FakeFirmwareService {
  /// Completes the pending `pushImage` when the test is ready.
  final Completer<UpdateTask> gate = Completer<UpdateTask>();

  @override
  Future<UpdateTask> pushImage(
    PushImageRequest req, {
    void Function(int sent, int total)? onProgress,
  }) async {
    onProgress?.call(1024, 2048);
    return gate.future;
  }
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

/// A [FirmwareService] double whose `startSimpleUpdate` blocks until the test
/// completes [startGate] — the in-flight Start-update shape (UI-5 busy state).
class _GateFirmwareService extends FakeFirmwareService {
  /// Completes the pending `startSimpleUpdate` when the test is ready.
  final Completer<UpdateTask> startGate = Completer<UpdateTask>();

  @override
  Future<UpdateTask> startSimpleUpdate(SimpleUpdateRequest req) =>
      startGate.future;
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
        'service summary announces one merged semantics label + visible text '
        '(UI-2)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(
          info: const UpdateServiceInfo(
            serviceEnabled: true,
            version: '1.2.3',
            httpPushUri: '/FWUpdate',
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
      // The summary line (version + HTTP push URI) is ONE self-describing
      // node — a screen reader hears the label and value together instead of
      // a bare detached 'UpdateService ' text.
      expect(
        find.bySemanticsLabel('UpdateService 1.2.3, /FWUpdate'),
        findsOneWidget,
      );
      // The visible summary text still renders for sighted users.
      expect(find.text('UpdateService 1.2.3 · /FWUpdate'), findsOneWidget);
    });

    testWidgets('no dangling summary text while the service is loading (UI-2)',
        (tester) async {
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
      // The auto-load never completes, so the service summary must NOT render
      // a half-baked 'UpdateService ' line — the header row + inventory area
      // already announce the in-flight state.
      await tester.pump();
      expect(find.textContaining('UpdateService'), findsNothing,
          reason: 'no dangling summary label while the fetch is in flight');
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

    testWidgets(
        'inventory loading announces one merged semantics label + visible '
        'text (UI-2)', (tester) async {
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
      // The auto-load never completes, so the inventory area is still in its
      // in-flight state: one merged announcement for the loading surface.
      await tester.pump();
      expect(
        find.bySemanticsLabel('Loading firmware inventory'),
        findsOneWidget,
      );
      // The visible loading text still renders for sighted users, and there
      // is no detached bare node leaking extra announcements.
      expect(find.text('Loading inventory…'), findsOneWidget);
    });

    testWidgets(
        'empty inventory announces one merged semantics label + visible '
        'text + icon (UI-2)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        // A successful load that reports zero inventory items — the empty
        // state is not an error, so there is no Retry.
        service: FakeFirmwareService(
          info: const UpdateServiceInfo(
            serviceEnabled: true,
            version: '9.9.9',
            inventory: <FirmwareInventoryItem>[],
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
      // One self-describing announcement (merged node, no separate parts).
      expect(
        find.bySemanticsLabel('No firmware inventory reported.'),
        findsOneWidget,
      );
      // The visible text + icon still render for sighted users.
      expect(find.text('No firmware inventory reported.'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      // The empty state must not overflow at the narrowest supported width
      // (UI-3: 320 px); the center-aligned column wraps instead. Use the
      // established addTearDown restore so the resize cannot leak into later
      // tests (12:30 journal noted this test restored manually).
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(320, 800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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
      // UI-2 single-node pin: the merged card label is the ONLY announcement
      // for that surface — the inner title/subtitle/chip texts must NOT leave
      // detached semantics nodes (the excludeSemantics fix, badge precedent).
      // The visible texts stay for sighted users.
      expect(find.bySemanticsLabel('BMC Firmware'), findsNothing,
          reason: 'the inner title must not double-announce under the merged '
              'card label');
      expect(find.bySemanticsLabel('Updateable'), findsNothing,
          reason: 'the chip text must not double-announce under the merged '
              'card label');
      expect(find.text('BMC Firmware'), findsOneWidget);
      expect(find.text('BMC · 3.2.1 · OK'), findsOneWidget);
      expect(find.text('Updateable'), findsOneWidget);
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
        'error state announces as one merged semantics node with a separate '
        'Retry control (UI-2)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: _FlakyFirmwareService(), // fails with 'boom', error persists
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

      // The icon + message merge into one node carrying the error text; the
      // Retry button keeps its own semantics (it is a control).
      final Finder merged =
          find.bySemanticsLabel('Unable to load firmware. boom');
      expect(merged, findsOneWidget);
      final SemanticsNode? node = tester.getSemantics(merged);
      expect(node?.label, contains('Unable to load firmware'));
      expect(node?.label, contains('boom'));

      // The visible message text is preserved.
      expect(find.text('boom'), findsOneWidget);

      // The Retry control is still separately focusable/announced.
      expect(
        find.bySemanticsLabel(RegExp('^Retry')),
        findsWidgets,
      );
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

    testWidgets(
        'task banner shows the polling state with a spinner while the monitor '
        'is being polled (#022 criterion 1)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(
            taskUri: '/redfish/v1/TaskService/TaskMonitors/42',
          ),
          polling: true,
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
      // Stepped pump, not pumpAndSettle: the banner's spinner animates
      // forever, so pumpAndSettle would time out (the 22:05 journal trap).
      await tester.pump();
      // The banner announces the in-progress poll in one merged node and
      // shows a visible spinner.
      expect(
        find.bySemanticsLabel(
          'Update in progress, polling /redfish/v1/TaskService/'
          'TaskMonitors/42',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Update in progress: polling'),
        findsOneWidget,
      );
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'the polling banner must show a visible spinner',
      );
    });

    testWidgets(
        'task banner shows the final task state once the monitor returns a '
        'terminal result (#022 criterion 1)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(
            taskUri: '/redfish/v1/TaskService/TaskMonitors/42',
          ),
          lastResult: RedfishTask(
            id: '545',
            name: 'Task 545',
            state: 'Completed',
            status: 'OK',
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
      expect(
        find.bySemanticsLabel('Update task 545, Completed'),
        findsOneWidget,
      );
      expect(find.textContaining('Update task 545: Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      // A finished task no longer shows the poll spinner.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'task banner shows a warning note for Completed with non-OK status '
        '(#022 criterion 1)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(
            taskUri: '/redfish/v1/TaskService/TaskMonitors/42',
          ),
          lastResult: RedfishTask(
            id: '545',
            state: 'Completed',
            status: 'Warning',
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
      expect(
        find.bySemanticsLabel('Update task 545, Completed with Warning'),
        findsOneWidget,
      );
      expect(find.textContaining('Completed with Warning'), findsOneWidget);
      // Not a clean success → no success check icon.
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets(
        'Start-update button shows a disabled busy state while the update is '
        'in flight (UI-5)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final _GateFirmwareService service = _GateFirmwareService();
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
      await tester.pumpAndSettle();

      // Enter an image URI and tap Start; the POST is now in flight.
      await tester.enterText(
        find.byType(TextField),
        'https://example.com/firmware.bin',
      );
      await tester.tap(find.text('Start'));
      await tester.pump();

      final FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull,
          reason: 'the Start-update button is disabled while the update POST '
              'is in flight');
      expect(find.text('Starting…'), findsOneWidget);
      // The screen-level loading state also announces in the header (existing
      // merged semantics); the button carries its own busy label + spinner.
      expect(
        find.bySemanticsLabel('Firmware and update management, loading'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Firmware and update management'),
        findsNothing,
      );

      // Releasing the POST clears the busy state and shows the queued banner.
      service.startGate.complete(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/1'),
      );
      await tester.pumpAndSettle();
      final FilledButton after =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(after.onPressed, isNotNull,
          reason: 'the Start-update button re-enables after the POST resolves');
      expect(find.text('Start'), findsOneWidget);
      expect(find.textContaining('Update queued'), findsOneWidget);
    });

    testWidgets(
        'Start-update failure surfaces the error and re-enables the button '
        '(UI-5)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final _GateFirmwareService service = _GateFirmwareService();
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
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'https://example.com/firmware.bin',
      );
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Starting…'), findsOneWidget);

      service.startGate.completeError(
        const RedfishException(
          message: 'Update service is busy; please retry the update shortly.',
          statusCode: 409,
          errorCode: 'Base.1.0.ResourceInUse',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Starting…'), findsNothing);
      expect(find.text('Start'), findsOneWidget);
      final FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(
        find.textContaining('Update service is busy'),
        findsOneWidget,
      );
    });
  });

  group('FirmwareView — push-upload banner (#008/#020)', () {
    testWidgets(
        'upload banner announces one merged semantics label + spinner while '
        'uploading', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
        initialState: const FirmwareUiState(uploading: true),
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
      // Stepped pump, not pumpAndSettle: the banner's spinner animates
      // forever.
      await tester.pump();
      expect(
        find.bySemanticsLabel('Uploading firmware image'),
        findsOneWidget,
      );
      expect(find.textContaining('Uploading firmware image'), findsOneWidget);
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'the upload banner must show a visible spinner',
      );
    });

    testWidgets('upload banner renders byte progress once reported',
        (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final _UploadingFirmwareService service = _UploadingFirmwareService();
      final FirmwareController controller = FirmwareController(
        service: service,
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

      // Start a push upload; the service reports 1024/2048 bytes then stays
      // in flight (gated), so the banner renders the byte progress.
      final Future<void> done = controller.pushImage(
        const PushImageRequest(bytes: <int>[1], filename: 'fw.bin'),
      );
      await tester.pump();
      expect(find.text('1024 / 2048 bytes'), findsOneWidget);
      final LinearProgressIndicator bar =
          tester.widget<LinearProgressIndicator>(find.byType(
        LinearProgressIndicator,
      ));
      expect(bar.value, closeTo(0.5, 0.001));

      // Releasing the upload clears the banner and feeds the queued banner.
      service.gate.complete(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/5'),
      );
      await done;
      await tester.pumpAndSettle();
      expect(find.text('1024 / 2048 bytes'), findsNothing);
      expect(find.textContaining('Update queued'), findsOneWidget);
    });

    testWidgets(
        'upload banner disappears after the upload resolves into a task '
        '(no dangling banner)', (tester) async {
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final _UploadingFirmwareService service = _UploadingFirmwareService();
      final FirmwareController controller = FirmwareController(
        service: service,
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

      final Future<void> done = controller.pushImage(
        const PushImageRequest(bytes: <int>[1], filename: 'fw.bin'),
      );
      await tester.pump();
      expect(
        find.textContaining('Uploading firmware image'),
        findsOneWidget,
      );

      service.gate.complete(
        const UpdateTask(taskUri: '/redfish/v1/TaskService/TaskMonitors/5'),
      );
      await done;
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Uploading firmware image'),
        findsNothing,
        reason: 'uploading=false must remove the upload banner',
      );
      expect(
        find.textContaining('Update queued'),
        findsOneWidget,
        reason: 'the returned task handle feeds the existing queued banner',
      );
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

    testWidgets(
        'completed-task banner does not overflow at the narrowest width '
        '(320 px, UI-3)', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(
          info: const UpdateServiceInfo(serviceEnabled: true),
        ),
        initialState: const FirmwareUiState(
          lastTask: UpdateTask(
            taskUri: '/redfish/v1/TaskService/TaskMonitors/42',
          ),
          lastResult: RedfishTask(
            id: '545',
            state: 'Completed',
            status: 'OK',
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
      expect(
        tester.takeException(),
        isNull,
        reason: 'the completed-task banner must not overflow at 320 px',
      );
      expect(find.textContaining('Update task 545: Completed'), findsOneWidget);
    });

    testWidgets(
        'upload progress banner does not overflow at the narrowest width '
        '(320 px, UI-3)', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(),
        initialState: const FirmwareUiState(
          uploading: true,
          uploadProgress: (sent: 1048576, total: 16777216),
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
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'the upload progress banner must not overflow at 320 px',
      );
      expect(find.text('1048576 / 16777216 bytes'), findsOneWidget);
    });
  });

  group('FirmwareView — start-update form labels (UI-2)', () {
    testWidgets(
        'the transfer-protocol selector carries a visible + semantic '
        'label', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final SystemHandle handle = makeHandle(firmwareUpdate: true);
      final FirmwareController controller = FirmwareController(
        service: FakeFirmwareService(
          info: const UpdateServiceInfo(
            serviceEnabled: true,
            version: '1.2.3',
            httpPushUri: '/FWUpdate',
            transferProtocols: <String>['HTTP', 'HTTPS'],
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

      // The selector is labelled for sighted users (visible Text above the
      // DropdownButton, the Image URI labelText pattern)…
      expect(find.text('Transfer protocol'), findsOneWidget);
      // …and for screen readers the label is announced in context: the Card's
      // merged section node carries both the "Start update" header and the
      // "Transfer protocol" label (Flutter merges sibling plain Texts inside
      // the card column), so assistive tech hears the field's name before the
      // protocol value instead of a bare dropdown.
      expect(
        find.bySemanticsLabel(RegExp('Transfer protocol')),
        findsWidgets,
      );
      // The dropdown control itself keeps its own button node (its label is
      // the current selection), so it remains a discrete interactive control.
      expect(find.bySemanticsLabel('HTTP'), findsOneWidget);

      // The dropdown still renders the current selection and both advertised
      // protocols are selectable.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('HTTPS'), findsOneWidget);
      semantics.dispose();
    });
  });
}
