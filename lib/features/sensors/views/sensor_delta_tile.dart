import 'package:flutter/widgets.dart';

/// Selector-style rebuild gate for one telemetry tile (issue #007).
///
/// A polling parent rebuilds its whole list every tick, but a single tile only
/// needs to rebuild when the data it actually shows changes. [SensorDeltaTile]
/// builds its [builder] subtree once and caches the exact widget instance; on
/// later parent rebuilds it returns that same instance whenever [fingerprint]
/// is unchanged. Flutter's `Element.updateChild` short-circuits on an identical
/// widget instance, so the child subtree is neither rebuilt nor repainted. The
/// surrounding [RepaintBoundary] confines any real repaint to this tile.
///
/// The fingerprint should encode only the fields the tile renders (see the
/// `tile_fingerprint.dart` helpers). The sparkline history deliberately grows
/// every poll even for a flat sensor, so it is excluded; a flat trend keeps the
/// same visual until the reading itself changes, at which point the tile
/// rebuilds with the latest history slice.
class SensorDeltaTile extends StatefulWidget {
  /// Creates a rebuild gate whose child is rebuilt only when [fingerprint]
  /// changes (compared with `==`).
  const SensorDeltaTile({
    required this.fingerprint,
    required this.builder,
    super.key,
  });

  /// Value compared against the previous build to decide whether to rebuild.
  final Object? fingerprint;

  /// Builds the tile subtree. Invoked only when [fingerprint] changes (or on
  /// the first build).
  final Widget Function(BuildContext context) builder;

  @override
  State<SensorDeltaTile> createState() => _SensorDeltaTileState();
}

class _SensorDeltaTileState extends State<SensorDeltaTile> {
  Object? _builtFingerprint;
  Widget? _builtChild;

  @override
  Widget build(BuildContext context) {
    if (_builtChild == null || _builtFingerprint != widget.fingerprint) {
      _builtFingerprint = widget.fingerprint;
      _builtChild = RepaintBoundary(child: widget.builder(context));
    }
    return _builtChild!;
  }
}
