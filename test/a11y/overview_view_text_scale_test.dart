// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/overview/views/overview_view.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

SystemOverview _sample() => SystemOverview(
      manufacturer: 'Acme',
      model: 'Server-9',
      serialNumber: 'SN1',
      sku: 'SKU1',
      partNumber: 'PN1',
      biosVersion: '1.0',
      powerState: PowerState.on,
      health: Health.ok,
      healthRollup: Health.ok,
      processorSummary: const ProcessorSummary(count: 2, model: 'P9'),
      memorySummary: const MemorySummary(totalGiB: 32),
      indicatorLed: IndicatorLed.lit,
      leadingTemperatureCelsius: 42.0,
      resourceUri: '/redfish/v1/Systems/system',
    );

SystemManager _seededManager() {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(
    systems: <String, SystemHandle>{
      'bmc1': SystemHandle(
        profile: const ConnectionProfile(id: 'bmc1', host: 'h'),
        status: ConnectionStatus.connected,
        session: Session(
          systemId: 'bmc1',
          token: 't',
          location: '',
          username: '',
        ),
        features: const SystemFeatures(systemId: 'bmc1'),
        snapshot: SystemSnapshot(
          powerState: PowerState.on,
          resourceUri: '/redfish/v1/Systems/system',
        ),
      ),
    },
    selectedId: 'bmc1',
  );
  return m;
}

void main() {
  testWidgets(
    'OverviewView supports 200% text scaling without overflow at 400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(_sample()),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: OverviewView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Identity'), findsOneWidget);
      expect(find.text('Manufacturer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OverviewView supports 200% text scaling without overflow at 320px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(_sample()),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: OverviewView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Identity'), findsOneWidget);
      expect(find.text('Manufacturer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OverviewView supports 200% text scaling without overflow at 800px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(_sample()),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: OverviewView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Identity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'OverviewView supports 200% text scaling without overflow at 1400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => _seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(_sample()),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: OverviewView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Identity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
