import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/dashboard_view.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

SystemManager seededManager() {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = const SystemState(
    systems: <String, SystemHandle>{
      'bmc1': const SystemHandle(
        profile:
            const ConnectionProfile(id: 'bmc1', name: 'Lab', host: '1.2.3.4'),
        snapshot: const SystemSnapshot(
          health: Health.ok,
          powerState: PowerState.on,
        ),
      ),
      'bmc2': const SystemHandle(
        profile:
            const ConnectionProfile(id: 'bmc2', name: 'Prod', host: '5.6.7.8'),
        snapshot: const SystemSnapshot(
          health: Health.warning,
          powerState: PowerState.off,
        ),
      ),
    },
    selectedId: 'bmc1',
  );
  return m;
}

void main() {
  testWidgets('dashboard aggregates and shows two systems of differing health',
      (WidgetTester tester) async {
    final SystemManager manager = seededManager();
    final GoRouter router = GoRouter(
      initialLocation: '/systems',
      routes: <RouteBase>[
        GoRoute(
          path: '/systems',
          builder: (BuildContext c, GoRouterState s) => const DashboardView(),
        ),
        GoRoute(
          path: '/:systemId/overview',
          builder: (BuildContext c, GoRouterState s) =>
              Text('overview:${s.pathParameters['systemId']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [systemManagerProvider.overrideWith((ref) => manager)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Aggregated header banner.
    expect(find.text('1 OK, 1 Warning'), findsOneWidget);
    // Each card renders its health badge.
    expect(find.text('OK'), findsWidgets);
    expect(find.text('Warning'), findsWidgets);
    // Both cards render by host.
    expect(find.text('Lab'), findsOneWidget);
    expect(find.text('Prod'), findsOneWidget);
  });

  testWidgets('tapping a card navigates into the system overview',
      (tester) async {
    final SystemManager manager = seededManager();
    final GoRouter router = GoRouter(
      initialLocation: '/systems',
      routes: <RouteBase>[
        GoRoute(
          path: '/systems',
          builder: (BuildContext c, GoRouterState s) => const DashboardView(),
        ),
        GoRoute(
          path: '/:systemId/overview',
          builder: (BuildContext c, GoRouterState s) =>
              Text('overview:${s.pathParameters['systemId']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [systemManagerProvider.overrideWith((ref) => manager)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lab'));
    await tester.pumpAndSettle();

    expect(find.text('overview:bmc1'), findsOneWidget);
    expect(manager.state.selectedId, 'bmc1');
  });

  group('DashboardView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final SystemManager manager = seededManager();
      final GoRouter router = GoRouter(
        initialLocation: '/systems',
        routes: <RouteBase>[
          GoRoute(
            path: '/systems',
            builder: (BuildContext c, GoRouterState s) => const DashboardView(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [systemManagerProvider.overrideWith((ref) => manager)],
          child: MaterialApp.router(routerConfig: router),
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
          reason: 'DashboardView must not overflow at $width px',
        );
        // Banner + both system cards render at every breakpoint.
        expect(find.text('1 OK, 1 Warning'), findsOneWidget);
        expect(find.text('Lab'), findsOneWidget);
        expect(find.text('Prod'), findsOneWidget);
      });
    }
  });

  group('DashboardView — error summary (UI-1)', () {
    Future<DashboardViewHarness> pumpFailed(
      WidgetTester tester, {
      bool transient = true,
    }) async {
      int calls = 0;
      // Fail the first `failFirst` login calls, then succeed. With two systems
      // and `transient: true` that means the initial connect of both fails and
      // a later Retry succeeds. With `transient: false` every attempt fails.
      final int failFirst = transient ? 2 : 1 << 30;
      final SystemManager manager = SystemManager(
        repository: InMemoryProfileRepository(),
        storage: InMemoryStorage(),
        loginOverride: (id, p) async {
          calls++;
          if (calls <= failFirst) throw Exception('boom');
          return Session(
            systemId: id,
            token: 'ok-$id',
            location: '',
            username: p.username ?? '',
            createdAt: DateTime.now(),
          );
        },
        discoverOverride: (c, id) async => SystemFeatures(systemId: id),
        snapshotOverride: (c, id) async =>
            const SystemSnapshot(health: Health.ok),
      );
      await manager.addProfile(const ConnectionProfile(id: 'bmc1', host: '1'));
      await manager.addProfile(const ConnectionProfile(id: 'bmc2', host: '2'));
      await manager.connect('bmc1');
      await manager.connect('bmc2');

      final GoRouter router = GoRouter(
        initialLocation: '/systems',
        routes: <RouteBase>[
          GoRoute(
            path: '/systems',
            builder: (BuildContext c, GoRouterState s) => const DashboardView(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [systemManagerProvider.overrideWith((ref) => manager)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return DashboardViewHarness(manager, router);
    }

    testWidgets('shows an error summary when systems fail to connect',
        (tester) async {
      await pumpFailed(tester, transient: false);

      expect(find.text('2 systems could not be reached'), findsOneWidget);
      // The banner aggregates OK; cards still show their cloud-off icon.
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsNWidgets(2));

      // Retry is offered; a permanent failure keeps the summary visible.
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('2 systems could not be reached'), findsOneWidget);
    });

    testWidgets('retry reconnects failed systems and clears the summary',
        (tester) async {
      final DashboardViewHarness harness = await pumpFailed(tester);
      expect(find.text('2 systems could not be reached'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(harness.manager.state.systems['bmc1']!.status,
          ConnectionStatus.connected);
      expect(harness.manager.state.systems['bmc2']!.status,
          ConnectionStatus.connected);
      expect(find.text('2 systems could not be reached'), findsNothing);
      expect(find.text('2 OK'), findsOneWidget);
    });

    testWidgets('no error summary when all systems are healthy',
        (tester) async {
      final SystemManager manager = seededManager();
      final GoRouter router = GoRouter(
        initialLocation: '/systems',
        routes: <RouteBase>[
          GoRoute(
            path: '/systems',
            builder: (BuildContext c, GoRouterState s) => const DashboardView(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [systemManagerProvider.overrideWith((ref) => manager)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('1 OK, 1 Warning'), findsOneWidget);
    });
  });
}

class DashboardViewHarness {
  DashboardViewHarness(this.manager, this.router);
  final SystemManager manager;
  final GoRouter router;
}
