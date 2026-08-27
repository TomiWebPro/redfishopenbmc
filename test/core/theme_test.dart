import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/theme/app_breakpoints.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme and darkTheme are Material3 and distinct', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;
      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      // Seed-derived schemes must still produce a usable, distinct primary.
      expect(light.colorScheme.primary, isNotNull);
      expect(dark.colorScheme.primary, isNotNull);
      final notEqual = isNot(equals(dark.colorScheme.primary));
      expect(light.colorScheme.primary, notEqual);
    });

    test('both themes have cardTheme and navigationBarTheme', () {
      expect(AppTheme.lightTheme.cardTheme, isNotNull);
      expect(AppTheme.darkTheme.navigationBarTheme, isNotNull);
    });
  });

  group('AppBreakpoints', () {
    test('fromWidth maps correctly', () {
      expect(AppBreakpoints.fromWidth(300), AppBreakpoint.mobile);
      expect(AppBreakpoints.fromWidth(599), AppBreakpoint.mobile);
      expect(AppBreakpoints.fromWidth(600), AppBreakpoint.tablet);
      expect(AppBreakpoints.fromWidth(800), AppBreakpoint.tablet);
      expect(AppBreakpoints.fromWidth(1199), AppBreakpoint.tablet);
      expect(AppBreakpoints.fromWidth(1200), AppBreakpoint.desktop);
      expect(AppBreakpoints.fromWidth(1600), AppBreakpoint.desktop);
    });

    testWidgets('AdaptiveBuilder chooses correct builder',
        (WidgetTester tester) async {
      Future<void> pump(double width, String expected) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveBuilder(
              mobile: (_) => const Text('MOBILE'),
              tablet: (_) => const Text('TABLET'),
              desktop: (_) => const Text('DESKTOP'),
            ),
          ),
        );
        expect(find.text(expected), findsOneWidget);
      }

      await pump(400, 'MOBILE');
      await pump(800, 'TABLET');
      await pump(1300, 'DESKTOP');
    });
  });
}
