// ignore_for_file: prefer_const_constructors
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
