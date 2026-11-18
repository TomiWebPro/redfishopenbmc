import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/systems/views/system_profile_form.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';

void main() {
  testWidgets(
    'SystemProfileForm supports 200% text scaling without overflow at 400px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SystemProfileForm(onSubmit: (_) {}),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SystemProfileForm), findsOneWidget);
      expect(find.text('Host / IP'), findsOneWidget);
      expect(find.text('Use TLS (HTTPS)'), findsOneWidget);
    },
  );

  testWidgets(
    'SystemProfileForm supports 200% text scaling without overflow at 320px',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SystemProfileForm(onSubmit: (_) {}),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SystemProfileForm), findsOneWidget);
      expect(find.text('Host / IP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SystemProfileForm TLS-off warning remains accessible at 200% text scale',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const ConnectionProfile insecure = ConnectionProfile(
        id: '1',
        host: 'bmc.example.com',
        scheme: 'http',
        port: 80,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SystemProfileForm(
                  initial: insecure,
                  onSubmit: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          'Warning: unencrypted HTTP disables transport security. '
          'Use HTTPS unless this BMC requires HTTP on a trusted, '
          'isolated network.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Unencrypted HTTP disables transport security'),
        findsOneWidget,
      );
    },
  );
}
