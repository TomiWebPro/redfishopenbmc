import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/main.dart';

void main() {
  testWidgets('RedfishApp renders', (WidgetTester tester) async {
    // `main()` wraps the app in a ProviderScope; reproduce that here so the
    // ConsumerWidgets (DashboardView, AppShell) can resolve their providers.
    // The storage-backed providers are overridden with an in-memory store so
    // the test never touches the platform keystore.
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
        ],
        child: const RedfishApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Root MaterialApp.router is present exactly once.
    expect(find.byType(MaterialApp), findsOneWidget);
    // The Systems destination is exposed in navigation.
    expect(find.text('Systems'), findsAtLeastNWidgets(1));
  });

  testWidgets('AdaptiveShellPreview mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const AdaptiveShellPreview());
    expect(find.text('Width: 400.0 → mobile'), findsOneWidget);
  });

  testWidgets('AdaptiveShellPreview tablet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const AdaptiveShellPreview());
    expect(find.text('Width: 800.0 → tablet'), findsOneWidget);
  });

  testWidgets('AdaptiveShellPreview desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1300, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const AdaptiveShellPreview());
    expect(find.text('Width: 1300.0 → desktop'), findsOneWidget);
  });
}
