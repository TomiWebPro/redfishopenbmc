// ignore_for_file: prefer_const_constructors
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/overview/views/overview_view.dart';
import 'package:redfishopenbmc/features/overview/widgets/health_banner.dart';
import 'package:redfishopenbmc/features/overview/widgets/info_card.dart';
import 'package:redfishopenbmc/features/overview/widgets/skeleton_card.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [SystemOverview] with every field populated — exercises all cards.
SystemOverview fullSample() => SystemOverview(
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

/// A [SystemOverview] with nothing exposed — exercises "Not exposed" paths.
SystemOverview emptySample() => const SystemOverview(
      health: Health.unknown,
      powerState: PowerState.unknown,
    );

SystemManager seededManager() {
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

/// Builds a [ProviderScope] that feeds [overviewProvider] a fixed [sample]
/// (or an error when [error] is true) and provides a seeded manager.
ProviderScope scopeWith({
  required SystemOverview sample,
  bool error = false,
}) {
  return ProviderScope(
    overrides: <Override>[
      systemManagerProvider.overrideWith((ref) => seededManager()),
      overviewProvider.overrideWith(
        (ref, id) => error
            ? Future<SystemOverview>.error(
                const RedfishException(message: 'boom', errorCode: 'X'),
              )
            : Future<SystemOverview>.value(sample),
      ),
    ],
    child: MaterialApp(
      home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
    ),
  );
}

void main() {
  group('OverviewView — loading', () {
    testWidgets('shows skeleton cards while the provider loads',
        (tester) async {
      // A never-completed completer keeps the provider in the loading state
      // without scheduling a real Timer (which would leak past the test).
      final Completer<SystemOverview> completer = Completer<SystemOverview>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith((ref, id) => completer.future),
          ],
          child: MaterialApp(
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SkeletonCard), findsWidgets);
      expect(find.byType(HealthBanner), findsOneWidget);
    });
  });

  group('OverviewView — data', () {
    testWidgets('renders all cards with populated values (light mode)',
        (tester) async {
      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('Processors'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Temperatures'), findsOneWidget);
      expect(find.text('Indicator LED'), findsOneWidget);
      expect(find.text('SN1'), findsOneWidget);
      expect(find.text('32 GiB'), findsOneWidget);
      expect(find.text('42.0 °C'), findsOneWidget);
      expect(find.text('Lit'), findsOneWidget);
      expect(find.text('2 processor(s)'), findsOneWidget);
      // Nothing should be flagged "not exposed" when data is present.
      expect(find.text('Not exposed by this BMC'), findsNothing);
    });

    testWidgets('renders without errors in dark mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(fullSample()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.byType(InfoCard), findsWidgets);
    });

    testWidgets(
        'omits the temperature card and shows "not exposed" for missing fields',
        (tester) async {
      await tester.pumpWidget(scopeWith(sample: emptySample()));
      await tester.pumpAndSettle();
      expect(find.text('Temperatures'), findsNothing);
      expect(find.text('Not exposed by this BMC'), findsWidgets);
      // 'Unknown' appears in both the health banner and the power badge.
      expect(find.text('Unknown'), findsWidgets);
    });
  });

  group('OverviewView — adaptive grid', () {
    testWidgets('lays out the card grid at desktop width', (tester) async {
      // Desktop width → 3 columns.
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(InfoCard), findsNWidgets(5));
    });
  });

  group('OverviewView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
    }

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('renders without overflow at ${width.toInt()} px',
          (tester) async {
        await pumpAtWidth(tester, width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'OverviewView must not overflow at $width px',
        );
        // Health banner + every data card render at every breakpoint.
        expect(find.text('Healthy'), findsOneWidget);
        expect(find.byType(InfoCard), findsNWidgets(5));
      });
    }
  });

  group('OverviewView — error', () {
    testWidgets('shows an error state with a retry affordance', (tester) async {
      await tester.pumpWidget(scopeWith(sample: emptySample(), error: true));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load overview'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

      // Tapping retry must not crash (re-runs the failing provider).
      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load overview'), findsOneWidget);
    });
  });
}
