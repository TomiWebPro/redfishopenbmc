import 'package:flutter/material.dart';

/// Central theme definitions for redfishopenbmc.
///
/// Dark mode is first-class: [lightTheme] and [darkTheme] are both produced by
/// the single [_themeFor] factory from a seed-derived [ColorScheme]. Routing
/// both brightnesses through that one builder means component overrides (card
/// shape, app bar, navigation bar, ...) can never drift between light and dark
/// — a real regression class when the two are maintained as copy-paste blocks.
class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF0F62FE);

  /// Light [ThemeData] built from the shared seed color.
  static ThemeData get lightTheme => _themeFor(
        ColorScheme.fromSeed(seedColor: _seed),
      );

  /// Dark [ThemeData] built from a shared seed color.
  static ThemeData get darkTheme => _themeFor(
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
      );

  /// Builds a [ThemeData] from [scheme], applying the shared component
  /// overrides. Both [lightTheme] and [darkTheme] go through this one path so
  /// their component theming is guaranteed to stay in sync.
  static ThemeData _themeFor(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
    );
  }
}
