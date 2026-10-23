import 'package:flutter/material.dart';

/// A titled card grouping related overview fields (issue #006).
///
/// Always rendered with a leading [icon] and [title], wrapping an arbitrary
/// [child] body (e.g. key/value rows or a "not exposed" helper).
class InfoCard extends StatelessWidget {
  /// Creates an [InfoCard] with [title], [icon] and [child] body.
  const InfoCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
  });

  /// Card title shown in the header row.
  final String title;

  /// Leading icon shown before the title.
  final IconData icon;

  /// Body widget rendered beneath the header.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // UI-2: the header (icon + title) announces as one merged node so
            // screen readers get a concise card label — same pattern as the
            // chassis/sensor/firmware card headers.
            Semantics(
              container: true,
              excludeSemantics: true,
              label: title,
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Muted helper shown when the BMC did not expose a field / resource.
///
/// Used across every [InfoCard] so missing Redfish members degrade to a clear
/// "Not exposed by this BMC" note instead of a placeholder or a crash.
class NotExposed extends StatelessWidget {
  /// Creates a [NotExposed] helper.
  const NotExposed({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Text(
      'Not exposed by this BMC',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: scheme.outline,
          ),
    );
  }
}
