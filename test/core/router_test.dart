import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:redfishopenbmc/core/router/app_router.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

void main() {
  // Rebuilds the RedfishApp composition (ProviderScope + MaterialApp.router
  // with AppRouter.createRouter()) while holding the router instance so the
  // test can navigate it directly — the same harness widget_test.dart uses,
  // with the storage provider overridden in-memory.
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final GoRouter router = AppRouter.createRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
        ],
        child: MaterialApp.router(
          title: 'Redfish OpenBMC',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
      'route-not-found fallback announces one merged semantics node '
      '— icon + text (UI-2)', (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);

    // Navigate to a path no route matches → GoRouter errorBuilder.
    router.go('/does/not/exist');
    await tester.pumpAndSettle();

    // One self-describing merged node carries the full label incl. the URI.
    expect(
      find.bySemanticsLabel('Route not found: /does/not/exist'),
      findsOneWidget,
      reason: 'expected one merged route-not-found node (icon + text)',
    );
    // Visible text preserved for sighted users.
    expect(find.text('Route not found: /does/not/exist'), findsOneWidget);
    expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
    // No overflow exception (UI-3) at the default test surface.
    expect(tester.takeException(), isNull);
  });

  testWidgets('route-not-found fallback has no overflow at 320 px (UI-3)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final GoRouter router = await pumpApp(tester);
    router.go('/does/not/exist');
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Route not found: /does/not/exist'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull,
        reason: 'the 320 px viewport must not overflow');
  });
}
