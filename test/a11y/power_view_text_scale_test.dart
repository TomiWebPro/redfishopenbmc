// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/power/power_controller.dart';
import 'package:redfishopenbmc/features/power/power_providers.dart';
import 'package:redfishopenbmc/features/power/power_service.dart';
import 'package:redfishopenbmc/features/power/views/power_view.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

class _FakePowerService extends PowerService {
  _FakePowerService() : super(client: null, systemId: 'bmc1');

  @override
  Future<void> reset(ResetType type) async {}

  @override
  Future<PowerState> fetchPowerState() async => PowerState.off;
}

SystemManager _buildManager() {
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
      powerControl: true,
      supportedResetTypes: const <String>[
        'On',
        'ForceOff',
        'GracefulRestart',
        'ForceRestart',
      ],
    ),
    snapshotOverride: (c, id) async => const SystemSnapshot(
      health: Health.ok,
      powerState: PowerState.off,
      resourceUri: '/redfish/v1/Systems/system',
    ),
  );
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

void main() {
  Future<void> pumpPowerView(
    WidgetTester tester, {
    required Size size,
    double textScale = 2.0,
  }) async {
    final SystemManager manager = _buildManager();
    await manager.addProfile(
      const ConnectionProfile(id: 'bmc1', host: 'h', name: 'Rack BMC 1'),
    );
    await manager.connect('bmc1');

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          systemManagerProvider.overrideWith((ref) => manager),
          powerControllerProvider(
            'bmc1',
          ).overrideWith((ref) => _fakeController()),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const Scaffold(body: PowerView(systemId: 'bmc1')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'PowerView supports 200% text scaling without overflow at 400px',
    (WidgetTester tester) async {
      await pumpPowerView(tester, size: const Size(400, 1000));

      expect(find.text('Power On'), findsOneWidget);
      expect(find.text('Force Off'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Destructive actions (force off, restart) require confirmation. '
          'State refreshes automatically after a reset.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PowerView supports 200% text scaling without overflow at 800px',
    (WidgetTester tester) async {
      await pumpPowerView(tester, size: const Size(800, 1000));

      expect(find.text('Power On'), findsOneWidget);
      expect(find.text('Graceful Restart'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PowerView supports 200% text scaling without overflow at 1400px',
    (WidgetTester tester) async {
      await pumpPowerView(tester, size: const Size(1400, 1000));

      expect(find.text('Force Restart'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Destructive actions (force off, restart) require confirmation. '
          'State refreshes automatically after a reset.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
