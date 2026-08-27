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

SystemManager seededManager() {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = const SystemState(
    systems: <String, SystemHandle>{
      'bmc1': const SystemHandle(
        profile: const ConnectionProfile(id: 'bmc1', name: 'Lab', host: '1.2.3.4'),
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

  testWidgets('tapping a card navigates into the system overview', (tester) async {
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
}
