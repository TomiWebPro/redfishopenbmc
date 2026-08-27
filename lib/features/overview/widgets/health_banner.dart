import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/widgets/status_badges.dart';

/// Top-of-overview banner visualizing effective [Health] with a colored,
/// icon-led treatment (green / amber / red / outline for unknown).
class HealthBanner extends StatelessWidget {
  /// Creates a [HealthBanner] for [health].
  const HealthBanner({required this.health, super.key});

  /// Health value rendered by the banner.
  final Health health;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = healthColor(health, scheme);
    final IconData icon = switch (health) {
      Health.ok => Icons.check_circle_outline,
      Health.warning => Icons.warning_amber_outlined,
      Health.critical => Icons.error_outline,
      Health.unknown => Icons.help_outline,
    };
    final String label = switch (health) {
      Health.ok => 'Healthy',
      Health.warning => 'Warning',
      Health.critical => 'Critical',
      Health.unknown => 'Unknown',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
