import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';

/// Resolves a display color for a given [Health] value.
Color healthColor(Health health, ColorScheme scheme) {
  switch (health) {
    case Health.ok:
      return scheme.primary;
    case Health.warning:
      return Colors.orange;
    case Health.critical:
      return scheme.error;
    case Health.unknown:
      return scheme.outline;
  }
}

/// A compact badge visualizing a system's [Health].
class HealthBadge extends StatelessWidget {
  /// Creates a [HealthBadge].
  const HealthBadge({required this.health, super.key});

  /// The health value to render.
  final Health health;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = healthColor(health, scheme);
    return Chip(
      avatar: Icon(
        health == Health.ok ? Icons.check_circle_outline : Icons.error_outline,
        size: 16,
        color: color,
      ),
      label: Text(health.label),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

/// A compact badge visualizing a system's [PowerState].
class PowerBadge extends StatelessWidget {
  /// Creates a [PowerBadge].
  const PowerBadge({required this.powerState, super.key});

  /// The power state to render.
  final PowerState powerState;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = switch (powerState) {
      PowerState.on => scheme.primary,
      PowerState.off => scheme.outline,
      PowerState.unknown => scheme.outline,
    };
    final IconData icon = switch (powerState) {
      PowerState.on => Icons.power,
      PowerState.off => Icons.power_off,
      PowerState.unknown => Icons.help_outline,
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(powerState.label),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
