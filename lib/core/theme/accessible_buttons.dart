import 'package:flutter/material.dart';

/// Minimum accessible touch target for tappable controls: 48x48dp
/// (WCAG 2.5.5 AAA / Material touch-target minimum).
///
/// Material buttons otherwise shrink to a 40dp visible height on desktop
/// targets (where [ThemeData.materialTapTargetSize] resolves to
/// `shrinkWrap`), which is below the 48dp minimum. Declaring the size on the
/// button itself keeps the guarantee independent of the resolved platform
/// theme.
const Size kMinimumTouchTarget = Size(48, 48);

/// A [ButtonStyle] that guarantees [kMinimumTouchTarget] for any Material
/// button (TextButton, FilledButton, FilledButton.icon, ...), regardless of
/// the ambient [ThemeData.materialTapTargetSize].
///
/// Used by the error-state Retry controls on every main view so a screen-reader
/// / motor-impaired operator still has a full-size hit area on desktop builds
/// (issue #010, a11y / touch targets). Merge it with a view-specific style via
/// [ButtonStyle.merge] when a control also needs custom colors.
ButtonStyle accessibleTouchTargetStyle() => ButtonStyle(
      minimumSize: WidgetStateProperty.all<Size>(kMinimumTouchTarget),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
