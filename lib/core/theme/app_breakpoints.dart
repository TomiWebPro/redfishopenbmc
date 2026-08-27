import 'package:flutter/widgets.dart';

/// Adaptive breakpoints as required by #001:
/// mobile < 600 < tablet < 1200 < desktop
enum AppBreakpoint {
  mobile,
  tablet,
  desktop,
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 600;
  static const double tabletMax = 1200;

  static AppBreakpoint fromWidth(double width) {
    if (width < mobileMax) return AppBreakpoint.mobile;
    if (width < tabletMax) return AppBreakpoint.tablet;
    return AppBreakpoint.desktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;
}

/// Helper widget that exposes the current breakpoint to its builder.
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({
    required this.mobile,
    required this.tablet,
    required this.desktop,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder tablet;
  final WidgetBuilder desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final AppBreakpoint bp =
            AppBreakpoints.fromWidth(constraints.maxWidth);
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
