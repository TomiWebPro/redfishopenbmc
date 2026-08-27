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
///
/// Renders `On` in the primary (accent) color and `Off` / `Unknown` in the
/// outline color. While a reset action is settling ([PowerState.isTransitioning]
/// is `true`) the badge gently pulses so the operator gets live feedback that
/// the BMC is still applying the requested power transition.
class PowerBadge extends StatefulWidget {
  /// Creates a [PowerBadge].
  const PowerBadge({required this.powerState, super.key});

  /// The power state to render.
  final PowerState powerState;

  @override
  State<PowerBadge> createState() => _PowerBadgeState();
}

class _PowerBadgeState extends State<PowerBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    // Only begin pulsing when the initial state is a transition; an idle badge
    // (On/Off/Unknown) must stay static so it never blocks pumpAndSettle & the
    // badges animate solely while a reset is actually settling.
    if (widget.powerState.isTransitioning) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant PowerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The pulse only runs while a transition is in flight; pausing it when idle
    // avoids needless animation ticks on a static badge.
    if (widget.powerState.isTransitioning) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color _color(ColorScheme scheme) {
    switch (widget.powerState) {
      case PowerState.on:
      case PowerState.poweringOn:
        return scheme.primary;
      case PowerState.off:
      case PowerState.poweringOff:
      case PowerState.unknown:
        return scheme.outline;
    }
  }

  IconData _icon() {
    switch (widget.powerState) {
      case PowerState.on:
      case PowerState.poweringOn:
        return Icons.power;
      case PowerState.off:
      case PowerState.poweringOff:
        return Icons.power_off;
      case PowerState.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = _color(scheme);
    final IconData icon = _icon();
    final bool transitioning = widget.powerState.isTransitioning;

    final Widget avatar = Icon(icon, size: 16, color: color);

    return Chip(
      avatar: transitioning
          ? FadeTransition(opacity: _opacity, child: avatar)
          : avatar,
      label: Text(widget.powerState.label),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
