// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/dashboard_view.dart';

SystemManager _emptyManager() => SystemManager(
      repository: InMemoryProfileRepository(),
      storage: InMemoryStorage(),
    );

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
}
