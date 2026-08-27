import 'package:flutter/material.dart';

/// Grey placeholder card shown while the overview is loading (issue #006).
///
/// Mirrors the height/shape of a real [InfoCard] so the grid doesn't jump when
/// data resolves.
class SkeletonCard extends StatelessWidget {
  /// Creates a [SkeletonCard].
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BoxDecoration block = BoxDecoration(
      color: scheme.outline.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    );
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(width: 90, height: 14, decoration: block),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 12, decoration: block),
            const SizedBox(height: 8),
            Container(width: 140, height: 12, decoration: block),
          ],
        ),
      ),
    );
  }
}
