/// Column counts for the overview adaptive card grid (issue #006).
///
/// The overview uses a finer desktop breakpoint (≥ 1024 → 3 columns) than the
/// app shell (≥ 1200). Mobile `< 600` shows 1 column, tablet `600–1023` shows
/// 2, desktop `≥ 1024` shows 3.
class OverviewGridBreakpoints {
  OverviewGridBreakpoints._();

  /// Lower bound (inclusive) of the tablet breakpoint.
  static const double tabletMin = 600;

  /// Lower bound (inclusive) of the desktop breakpoint.
  static const double desktopMin = 1024;

  /// Resolves the column count for a viewport [width].
  static int columnsForWidth(double width) {
    if (width >= desktopMin) return 3;
    if (width >= tabletMin) return 2;
    return 1;
  }

  /// Resolves the active [OverviewBreakpoint] for a viewport [width].
  static OverviewBreakpoint forWidth(double width) {
    if (width >= desktopMin) return OverviewBreakpoint.desktop;
    if (width >= tabletMin) return OverviewBreakpoint.tablet;
    return OverviewBreakpoint.mobile;
  }
}

/// Coarse breakpoint classification for the overview grid.
enum OverviewBreakpoint {
  /// Viewport narrower than 600 logical pixels (1 column).
  mobile,

  /// Viewport between 600 and 1024 logical pixels (2 columns).
  tablet,

  /// Viewport at or above 1024 logical pixels (3 columns).
  desktop,
}
