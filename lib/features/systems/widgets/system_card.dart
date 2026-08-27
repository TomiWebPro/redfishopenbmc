import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/widgets/status_badges.dart';

/// A dashboard card summarizing one [SystemHandle].
///
/// Shows the display name, `host:port`, connection health, power state, and
/// discovered manufacturer/model. Tapping the card invokes [onTap] (used to
/// open the system). A trailing menu exposes edit / connect / disconnect /
/// remove, surfaced through [onMenuAction].
class SystemCard extends StatelessWidget {
  /// Creates a [SystemCard].
  const SystemCard({
    required this.handle,
    this.onTap,
    this.onMenuAction,
    super.key,
  });

  /// The system to render.
  final SystemHandle handle;

  /// Invoked when the card body is tapped.
  final VoidCallback? onTap;

  /// Invoked with one of `edit`, `connect`, `disconnect`, `remove`.
  final void Function(String action)? onMenuAction;

  @override
  Widget build(BuildContext context) {
    final ConnectionProfile profile = handle.profile;
    final SystemSnapshot? snapshot = handle.snapshot;
    final String subtitle =
        '${profile.scheme}://${profile.host}:${profile.port}';
    final String? detail = _detailLine(snapshot);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      handle.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (handle.status == ConnectionStatus.connecting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (handle.status == ConnectionStatus.error)
                    const Icon(Icons.cloud_off, size: 16, color: Colors.red)
                  else if (handle.status == ConnectionStatus.connected)
                    const Icon(Icons.cloud_done, size: 16, color: Colors.green)
                  else
                    const Icon(Icons.cloud, size: 16, color: Colors.grey),
                  if (onMenuAction != null) _menu(context),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  HealthBadge(health: snapshot?.health ?? Health.unknown),
                  PowerBadge(
                    powerState: snapshot?.powerState ?? PowerState.unknown,
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) => PopupMenuButton<String>(
        onSelected: onMenuAction,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'connect',
            child: Text('Connect'),
          ),
          const PopupMenuItem<String>(
            value: 'disconnect',
            child: Text('Disconnect'),
          ),
          const PopupMenuItem<String>(
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem<String>(
            value: 'remove',
            child: Text('Remove'),
          ),
        ],
      );

  String? _detailLine(SystemSnapshot? snapshot) {
    if (snapshot == null) return null;
    final List<String> parts = <String>[
      if (snapshot.manufacturer != null) snapshot.manufacturer!,
      if (snapshot.model != null) snapshot.model!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
