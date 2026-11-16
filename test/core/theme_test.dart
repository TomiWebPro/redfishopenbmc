import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
