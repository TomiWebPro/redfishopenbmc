import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RedfishApp()));
}

class RedfishApp extends ConsumerWidget {
  const RedfishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.createRouter();
    return MaterialApp.router(
      title: 'Redfish OpenBMC',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Lightweight adaptive shell preview used by widget_test.
/// Exposes breakpoint logic without requiring GoRouter.
class AdaptiveShellPreview extends StatelessWidget {
  const AdaptiveShellPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final String bp = w < 600
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
