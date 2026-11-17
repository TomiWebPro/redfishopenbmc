// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/dashboard_view.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

SystemManager _emptyManager() => SystemManager(
      repository: InMemoryProfileRepository(),
      storage: InMemoryStorage(),
    );

SystemManager _populatedManager() {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  final SystemHandle h1 = SystemHandle(
    profile: const ConnectionProfile(
      id: 'sys-1',
      name: 'Rack Server 1',
      host: '10.0.0.1',
      port: 443,
    ),
    status: ConnectionStatus.connected,
    session: const Session(
      systemId: 'sys-1',
      token: 't1',
      location: '',
      username: 'admin',
    ),
    features: const SystemFeatures(systemId: 'sys-1'),
    snapshot: const SystemSnapshot(
      health: Health.ok,
      powerState: PowerState.on,
      manufacturer: 'OpenBMC',
      model: 'AST2600 EVB',
      serialNumber: 'SN12345',
    ),
  );
  final SystemHandle h2 = SystemHandle(
    profile: const ConnectionProfile(
      id: 'sys-2',
      name: 'Rack Server 2',
      host: '10.0.0.2',
      port: 443,
    ),
    status: ConnectionStatus.connected,
    session: const Session(
      systemId: 'sys-2',
      token: 't2',
      location: '',
      username: 'admin',
    ),
    features: const SystemFeatures(systemId: 'sys-2'),
    snapshot: const SystemSnapshot(
      health: Health.warning,
      powerState: PowerState.on,
      manufacturer: 'VendorCo',
      model: 'BMC Platform Long Model Name',
    ),
  );
  m.state = SystemState(
    systems: <String, SystemHandle>{'sys-1': h1, 'sys-2': h2},
    selectedId: 'sys-1',
  );
  return m;
}

void main() {
  testWidgets(
    'DashboardView supports 200% text scaling without overflow at 400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _emptyManager()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: DashboardView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('No systems yet. Tap + to add a BMC.'),
        findsOneWidget,
      );
      expect(find.text('No systems yet. Tap + to add a BMC.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DashboardView supports 200% text scaling without overflow at 800px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _emptyManager()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: DashboardView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('No systems yet. Tap + to add a BMC.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DashboardView supports 200% text scaling without overflow at 1400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _emptyManager()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: DashboardView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('No systems yet. Tap + to add a BMC.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DashboardView populated state supports 200% text scaling without overflow at 400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _populatedManager()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: DashboardView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rack Server 1'), findsWidgets);
      expect(find.text('Rack Server 2'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DashboardView populated state supports 200% text scaling without overflow at 800px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _populatedManager()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: DashboardView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rack Server 1'), findsWidgets);
      expect(find.text('Rack Server 2'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DashboardView populated state supports 200% text scaling without overflow at 1400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _populatedManager()),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: DashboardView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rack Server 1'), findsWidgets);
      expect(find.text('Rack Server 2'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
