// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/firmware/views/firmware_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

void main() {
  testWidgets(
    'FirmwareView discovery-pending state supports 200% text scaling without overflow at 400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: FirmwareView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Loading firmware'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FirmwareView discovery-pending state supports 200% text scaling without overflow at 320px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: FirmwareView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Loading firmware'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FirmwareView discovery-pending state supports 200% text scaling without overflow at 800px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: FirmwareView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Loading firmware'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FirmwareView discovery-pending state supports 200% text scaling without overflow at 1400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(null),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: FirmwareView(systemId: 'bmc1')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Loading firmware'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
