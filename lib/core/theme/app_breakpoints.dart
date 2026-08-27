import 'package:flutter/widgets.dart';

/// Adaptive breakpoints as required by #001:
/// mobile < 600 < tablet < 1200 < desktop.
enum AppBreakpoint {
  /// Viewport narrower than 600 logical pixels.
  mobile,

  /// Viewport between 600 and 1200 logical pixels.
  tablet,

  /// Viewport at or above 1200 logical pixels.
  desktop,
}

/// Helpers for resolving the active [AppBreakpoint] from a viewport width.
class AppBreakpoints {
  AppBreakpoints._();

  /// Upper bound (exclusive) of the mobile breakpoint.
  static const double mobileMax = 600;

  /// Upper bound (exclusive) of the tablet breakpoint.
  static const double tabletMax = 1200;

  /// Resolves [AppBreakpoint] from a viewport [width].
  static AppBreakpoint fromWidth(double width) {
    if (width < mobileMax) return AppBreakpoint.mobile;
    if (width < tabletMax) return AppBreakpoint.tablet;
    return AppBreakpoint.desktop;
  }

  /// Whether the current context renders in the mobile breakpoint.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  /// Whether the current context renders in the tablet breakpoint.
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileMax && w < tabletMax;
  }

  /// Whether the current context renders in the desktop breakpoint.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;
}

/// Builder that renders a different [WidgetBuilder] per [AppBreakpoint].
class AdaptiveBuilder extends StatelessWidget {
  /// Creates an [AdaptiveBuilder] with per-breakpoint builders.
  const AdaptiveBuilder({
    required this.mobile,
    required this.tablet,
    required this.desktop,
    super.key,
  });

  /// Builder used when the viewport is mobile.
  final WidgetBuilder mobile;

  /// Builder used when the viewport is tablet.
  final WidgetBuilder tablet;

  /// Builder used when the viewport is desktop.
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bp = AppBreakpoints.fromWidth(constraints.maxWidth);
        switch (bp) {
          case AppBreakpoint.mobile:
            return mobile(context);
          case AppBreakpoint.tablet:
            return tablet(context);
          case AppBreakpoint.desktop:
            return desktop(context);
        }
      },
    );
  }
}
