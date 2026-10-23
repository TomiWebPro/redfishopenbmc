// ignore_for_file: prefer_const_constructors
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/power/power_controller.dart';
import 'package:redfishopenbmc/features/power/power_page.dart';
import 'package:redfishopenbmc/features/power/power_providers.dart';
import 'package:redfishopenbmc/features/power/power_service.dart';
import 'package:redfishopenbmc/features/power/views/power_view.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [PowerService] double that records reset calls for widget tests.
class _FakePowerService extends PowerService {
  _FakePowerService() : super(client: null, systemId: 'bmc1');
  int resetCalls = 0;
  @override
  Future<void> reset(ResetType type) async => resetCalls++;
  @override
  Future<PowerState> fetchPowerState() async => PowerState.on;
}

/// A [PowerService] double whose reset request stays pending until the test
/// releases it — lets tests observe the dialog's in-flight (busy) state.
class _DeferredPowerService extends PowerService {
  _DeferredPowerService() : super(client: null, systemId: 'bmc1');
  final Completer<void> gate = Completer<void>();
  int resetCalls = 0;
  @override
  Future<void> reset(ResetType type) {
    resetCalls++;
    return gate.future;
  }

  @override
  Future<PowerState> fetchPowerState() async => PowerState.on;
}

/// A [PowerService] double whose reset fails with a Redfish error.
class _FailingPowerService extends PowerService {
  _FailingPowerService() : super(client: null, systemId: 'bmc1');
  @override
  Future<void> reset(ResetType type) async {
    throw RedfishException(message: 'reset was rejected', statusCode: 400);
  }

  @override
  Future<PowerState> fetchPowerState() async => PowerState.on;
}

SystemManager buildManager({
  required bool powerControl,
  List<String> supportedResetTypes = const <String>[
    'On',
    'ForceOff',
    'GracefulRestart',
    'ForceRestart',
  ],
}) {
  return SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
    loginOverride: (id, p) async => Session(
      systemId: id,
      token: 'tok',
      location: '',
      username: p.username ?? '',
      createdAt: DateTime.now(),
    ),
    discoverOverride: (c, id) async => SystemFeatures(
      systemId: id,
      powerControl: powerControl,
      supportedResetTypes: supportedResetTypes,
    ),
    snapshotOverride: (c, id) async => const SystemSnapshot(
      health: Health.ok,
      powerState: PowerState.off,
      resourceUri: '/redfish/v1/Systems/system',
    ),
  );
}

Widget harness({
  required SystemManager manager,
  required PowerController controller,
}) =>
    ProviderScope(
      overrides: <Override>[
        systemManagerProvider.overrideWith((ref) => manager),
        powerControllerProvider('bmc1').overrideWith((ref) => controller),
      ],
      child: const MaterialApp(
        home: Scaffold(body: PowerView(systemId: 'bmc1')),
      ),
    );

void main() {
  group('PowerView — gating', () {
    testWidgets('PowerPage wires through to PowerView', (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
      );
      await manager.connect('bmc1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => manager),
            powerControllerProvider('bmc1').overrideWith(
              (ref) => _fakeController(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: PowerPage(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Power On'), findsOneWidget);
    });

    testWidgets('renders nothing when power control is disabled',
        (tester) async {
      final SystemManager manager = buildManager(powerControl: false);
      await manager.addProfile(
          const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'));
      await manager.connect('bmc1');

      await tester.pumpWidget(
        harness(
          manager: manager,
          controller: _fakeController(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Power On'), findsNothing);
    });
  });

  group('PowerView — actions', () {
    testWidgets('shows a confirmation dialog on tap', (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
          const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'));
      await manager.connect('bmc1');

      await tester.pumpWidget(
        harness(manager: manager, controller: _fakeController()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Power On'), findsOneWidget);

      await tester.tap(find.text('Power On'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Power On?'), findsOneWidget);
      expect(
        find.text('This will Power On "A". Continue?'),
        findsOneWidget,
      );

      // Cancel dismisses the dialog.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Power On?'), findsNothing);
    });

    testWidgets('confirming a reset calls the controller', (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
          const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'));
      await manager.connect('bmc1');

      final _FakePowerService svc = _FakePowerService();
      final PowerController controller = PowerController(
        service: svc,
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>[
            'On',
            'ForceOff',
            'GracefulRestart',
            'ForceRestart',
          ],
        ),
        initialState: const PowerUiState(powerState: PowerState.off),
        pollInterval: const Duration(seconds: 60),
        pollTimeout: const Duration(milliseconds: 1),
      );

      await tester.pumpWidget(
        harness(manager: manager, controller: controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Power On'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(svc.resetCalls, 1);
    });

    testWidgets('disables an unsupported reset type', (tester) async {
      final SystemManager manager = buildManager(
        powerControl: true,
        supportedResetTypes: const <String>['On'],
      );
      await manager.addProfile(
          const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'));
      await manager.connect('bmc1');

      // Only "On" advertised → Force Off must be disabled.
      final _FakePowerService svc = _FakePowerService();
      final PowerController controller = PowerController(
        service: svc,
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>['On'],
        ),
        initialState: const PowerUiState(powerState: PowerState.off),
      );

      await tester.pumpWidget(
        harness(manager: manager, controller: controller),
      );
      await tester.pumpAndSettle();

      final Finder forceOff = find.widgetWithText(FilledButton, 'Force Off');
      expect(forceOff, findsOneWidget);
      final FilledButton button = tester.widget<FilledButton>(forceOff);
      expect(button.onPressed, isNull);
    });

    testWidgets('destructive dialog shows clearer warning copy + semantics',
        (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
      );
      await manager.connect('bmc1');

      await tester.pumpWidget(
        harness(manager: manager, controller: _fakeController()),
      );
      await tester.pumpAndSettle();

      // Tap a destructive action (Force Off).
      await tester.tap(find.text('Force Off'));
      await tester.pumpAndSettle();

      // Warning copy mentions service interruption + data loss risk.
      expect(
        find.textContaining('may interrupt service'),
        findsOneWidget,
      );
      expect(
        find.textContaining('unsaved work on the host'),
        findsOneWidget,
      );
      // Confirm button carries a destructive semantic label for screen readers.
      final Finder forceButton = find.widgetWithText(FilledButton, 'Force');
      expect(forceButton, findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('destructive')),
        findsOneWidget,
        reason: 'destructive action must be announced as destructive',
      );

      // Cancel still dismisses cleanly.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Force Off?'), findsNothing);
    });
  });

  group('PowerView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'Rack BMC 1'),
      );
      await manager.connect('bmc1');
      await tester.pumpWidget(
        harness(manager: manager, controller: _fakeController()),
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
          reason: 'PowerView must not overflow at $width px',
        );
        expect(find.text('Power On'), findsOneWidget);
      });
    }
  });

  group('PowerView — busy-state semantics (UI-2/UI-5)', () {
    testWidgets('busy reset button announces the in-flight action',
        (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
      );
      await manager.connect('bmc1');

      final PowerController controller = PowerController(
        service: _FakePowerService(),
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>['On'],
        ),
        initialState: const PowerUiState(
          powerState: PowerState.off,
          actionInFlight: true,
        ),
        pollInterval: const Duration(seconds: 60),
        pollTimeout: const Duration(milliseconds: 1),
      );

      await tester.pumpWidget(
        harness(manager: manager, controller: controller),
      );
      // The in-flight spinner animates forever, so bounded pumps, not
      // pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The in-flight button is disabled and announced as busy for AT.
      final Finder powerOn = find.widgetWithText(FilledButton, 'Power On');
      expect(powerOn, findsOneWidget);
      final FilledButton button = tester.widget<FilledButton>(powerOn);
      expect(button.onPressed, isNull, reason: 'busy button must be disabled');
      expect(
        find.bySemanticsLabel(RegExp('^Power On, action in progress')),
        findsOneWidget,
        reason: 'busy state must be announced to assistive tech',
      );
    });

    testWidgets('idle reset button has no busy semantics', (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
      );
      await manager.connect('bmc1');

      await tester.pumpWidget(
        harness(manager: manager, controller: _fakeController()),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('action in progress')), findsNothing);
    });

    testWidgets(
        'dialog confirm button disables + spins while reset is in '
        'flight (UI-5)', (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
      );
      await manager.connect('bmc1');

      final _DeferredPowerService svc = _DeferredPowerService();
      final PowerController controller = PowerController(
        service: svc,
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>['On'],
        ),
        initialState: const PowerUiState(powerState: PowerState.off),
        pollInterval: const Duration(seconds: 60),
        pollTimeout: const Duration(milliseconds: 1),
      );

      await tester.pumpWidget(
        harness(manager: manager, controller: controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Power On'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      // Bounded pumps: the busy spinner animates forever while pending.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog stays open, confirm button disabled + spinner shown, both
      // buttons inert.
      expect(find.text('Confirm Power On?'), findsOneWidget);
      final Finder dialogConfirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      );
      expect(dialogConfirm, findsOneWidget);
      final FilledButton confirmButton =
          tester.widget<FilledButton>(dialogConfirm);
      expect(confirmButton.onPressed, isNull,
          reason: 'busy confirm button must be disabled');
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
        reason: 'busy confirm button must show a spinner',
      );
      final TextButton cancelButton =
          tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'));
      expect(cancelButton.onPressed, isNull,
          reason: 'cancel must be disabled mid-flight');
      expect(
        find.bySemanticsLabel(RegExp('^Confirm Power On, action in progress')),
        findsOneWidget,
        reason: 'busy state must be announced to assistive tech',
      );

      // Releasing the gate pops the dialog (request completed).
      svc.gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Confirm Power On?'), findsNothing);
      expect(svc.resetCalls, 1);
    });

    testWidgets(
        'failed reset closes the dialog and surfaces the error snackbar',
        (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
      );
      await manager.connect('bmc1');

      final _FailingPowerService svc = _FailingPowerService();
      final PowerController controller = PowerController(
        service: svc,
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>['On'],
        ),
        initialState: const PowerUiState(powerState: PowerState.off),
        pollInterval: const Duration(seconds: 60),
        pollTimeout: const Duration(milliseconds: 1),
      );

      await tester.pumpWidget(
        harness(manager: manager, controller: controller),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Power On'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Dialog closed, error reported via the inline error text AND the
      // snackbar (the controller records the error instead of throwing, so
      // the dialog pops after the request resolves).
      expect(find.text('Confirm Power On?'), findsNothing);
      expect(find.text('reset was rejected'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('reset was rejected'),
        ),
        findsOneWidget,
        reason: 'the snackbar must carry the failure message',
      );
    });
  });

  group('PowerView — card header semantics (UI-2)', () {
    testWidgets('announces one merged header node incl. the power state',
        (tester) async {
      final SystemManager manager = buildManager(powerControl: true);
      await manager.addProfile(
        const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
      );
      await manager.connect('bmc1');

      final PowerController controller = PowerController(
        service: _FakePowerService(),
        features: SystemFeatures(
          systemId: 'bmc1',
          powerControl: true,
          supportedResetTypes: const <String>['On'],
        ),
        initialState: const PowerUiState(powerState: PowerState.off),
        pollInterval: const Duration(seconds: 60),
        pollTimeout: const Duration(milliseconds: 1),
      );

      await tester.pumpWidget(
        harness(manager: manager, controller: controller),
      );
      await tester.pumpAndSettle();

      // The header (display name + power badge) is one merged semantics node.
      expect(
        find.bySemanticsLabel(RegExp('^A, power Off')),
        findsOneWidget,
        reason: 'the card header must announce as a single merged node',
      );
    });
  });
}

PowerController _fakeController() => PowerController(
      service: _FakePowerService(),
      features: SystemFeatures(
        systemId: 'bmc1',
        powerControl: true,
        supportedResetTypes: const <String>[
          'On',
          'ForceOff',
          'GracefulRestart',
          'ForceRestart',
        ],
      ),
      initialState: const PowerUiState(powerState: PowerState.off),
      pollInterval: const Duration(seconds: 60),
      pollTimeout: const Duration(milliseconds: 1),
    );
