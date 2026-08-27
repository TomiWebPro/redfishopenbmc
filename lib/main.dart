import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/core/router/app_router.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RedfishApp()));
}

/// Root application widget.
///
/// Composes ProviderScope (Riverpod), GoRouter navigation, and the
/// light/dark [AppTheme] using the system theme mode.
class RedfishApp extends ConsumerWidget {
  /// Creates the root [RedfishApp].
  const RedfishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.createRouter();
    return MaterialApp.router(
      title: 'Redfish OpenBMC',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Lightweight adaptive shell preview used by widget_test.
///
/// Exposes breakpoint logic without requiring [AppRouter].
class AdaptiveShellPreview extends StatelessWidget {
  /// Creates the [AdaptiveShellPreview].
  const AdaptiveShellPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final w = constraints.maxWidth;
          final bp = w < 600
              ? 'mobile'
              : w < 1200
                  ? 'tablet'
                  : 'desktop';
          return Scaffold(
            appBar: AppBar(title: Text('Breakpoint: $bp')),
            body: Center(child: Text('Width: $w → $bp')),
          );
        },
      ),
    );
  }
}
