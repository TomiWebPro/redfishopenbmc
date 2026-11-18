import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';

/// WCAG 2.1 relative luminance (https://www.w3.org/TR/WCAG21/#dfn-relative-luminance).
double _relativeLuminance(Color color) {
  // Color.r/g/b are normalized to 0..1 on current Flutter.
  double channel(double s) {
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio (https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio).
/// Ranges from 1.0 (identical) to 21.0 (black vs white).
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

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

    group('WCAG contrast math', () {
      test('reference values are correct', () {
        expect(_contrastRatio(Colors.white, Colors.black), closeTo(21.0, 0.01));
        expect(_contrastRatio(Colors.black, Colors.black), closeTo(1.0, 0.01));
        expect(_contrastRatio(Colors.white, Colors.white), closeTo(1.0, 0.01));
      });
    });

    // #010 theming/a11y acceptance: "contrast AA on cards/badges". Card body
    // text is onSurface/onSurfaceVariant over the surface/container colors;
    // badges use the container/on-container pairs. WCAG AA needs >= 4.5:1.
    for (final entry in <String, ThemeData>{
      'light': AppTheme.lightTheme,
      'dark': AppTheme.darkTheme,
    }.entries) {
      group('${entry.key} theme semantic color contrast (WCAG AA)', () {
        final scheme = entry.value.colorScheme;
        final pairs = <String, List<Color>>{
          'onPrimary / primary': [scheme.onPrimary, scheme.primary],
          'onSecondary / secondary': [scheme.onSecondary, scheme.secondary],
          'onTertiary / tertiary': [scheme.onTertiary, scheme.tertiary],
          'onSurface / surface': [scheme.onSurface, scheme.surface],
          'onSurfaceVariant / surfaceContainer (card subtitle)': [
            scheme.onSurfaceVariant,
            scheme.surfaceContainer,
          ],
          'onSurfaceVariant / surfaceContainerHighest (badge)': [
            scheme.onSurfaceVariant,
            scheme.surfaceContainerHighest,
          ],
          'onError / error': [scheme.onError, scheme.error],
          'onPrimaryContainer / primaryContainer': [
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
          ],
          'onSecondaryContainer / secondaryContainer': [
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ],
        };

        for (final pair in pairs.entries) {
          test('${pair.key} >= 4.5:1', () {
            expect(
              _contrastRatio(pair.value[0], pair.value[1]),
              greaterThanOrEqualTo(4.5),
              reason: '${pair.key} must meet WCAG AA contrast',
            );
          });
        }
      });
    }

    group('light/dark component-theme parity', () {
      // Both themes come from the shared _themeFor builder, so their component
      // overrides must be identical (only the derived colors differ).
      test('card shape geometry and elevation match', () {
        final light = AppTheme.lightTheme.cardTheme;
        final dark = AppTheme.darkTheme.cardTheme;
        expect(light.elevation, equals(dark.elevation));
        // The outline *color* is brightness-specific (outlineVariant), but the
        // shared builder must give both modes the same corner radius.
        final lightShape = light.shape as RoundedRectangleBorder;
        final darkShape = dark.shape as RoundedRectangleBorder;
        expect(lightShape.borderRadius, equals(darkShape.borderRadius));
        expect(lightShape.borderRadius, equals(BorderRadius.circular(12)));
      });

      test('app bar elevation and title alignment match', () {
        final light = AppTheme.lightTheme.appBarTheme;
        final dark = AppTheme.darkTheme.appBarTheme;
        expect(light.elevation, equals(dark.elevation));
        expect(light.centerTitle, equals(dark.centerTitle));
      });

      test('scaffold background follows the scheme surface in both themes', () {
        for (final theme in <ThemeData>[
          AppTheme.lightTheme,
          AppTheme.darkTheme,
        ]) {
          expect(
              theme.scaffoldBackgroundColor, equals(theme.colorScheme.surface));
          expect(
            theme.navigationBarTheme.backgroundColor,
            equals(theme.colorScheme.surfaceContainer),
          );
          expect(
            theme.navigationBarTheme.indicatorColor,
            equals(theme.colorScheme.secondaryContainer),
          );
        }
      });
    });
  });
}
