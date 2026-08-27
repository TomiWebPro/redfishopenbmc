import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/widgets/status_badges.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Per-system overview page (the `overview` tab inside [SystemShell]).
///
/// Surfaces the live [SystemSnapshot] plus the discovered [SystemFeatures] as
/// capability chips. Offers connect / refresh / disconnect controls. A fuller
/// adaptive card layout is owned by #006; this view is the functional baseline.
class SystemOverviewPage extends ConsumerWidget {
  /// Creates a [SystemOverviewPage] for [systemId].
  const SystemOverviewPage({required this.systemId, super.key});

  /// The system id this page describes.
  final String systemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SystemState state = ref.watch(systemManagerProvider);
    final SystemHandle? handle = state.systems[systemId];

    if (handle == null) {
      return const Center(child: Text('System not found'));
    }

    final SystemSnapshot? snapshot = handle.snapshot;
    final SystemFeatures? features = handle.features;
    final bool connected = handle.status == ConnectionStatus.connected;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  handle.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${handle.profile.scheme}://${handle.profile.host}:'
                  '${handle.profile.port}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    HealthBadge(
                      health: snapshot?.health ?? Health.unknown,
                    ),
                    PowerBadge(
                      powerState: snapshot?.powerState ?? PowerState.unknown,
                    ),
                  ],
                ),
                if (snapshot?.manufacturer != null ||
                    snapshot?.model != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    <String>[
                      if (snapshot?.manufacturer != null)
                        snapshot!.manufacturer!,
                      if (snapshot?.model != null) snapshot!.model!,
                    ].join(' · '),
                  ),
                ],
                if (snapshot?.serialNumber != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text('Serial: ${snapshot!.serialNumber}'),
                ],
                if (handle.status == ConnectionStatus.error &&
                    handle.lastError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Connection error: ${handle.lastError}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (features != null) _featureChips(features),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: <Widget>[
            if (!connected)
              FilledButton.icon(
                onPressed: () => ref
                    .read(systemManagerProvider.notifier)
                    .connect(systemId),
                icon: const Icon(Icons.login),
                label: const Text('Connect'),
              )
            else ...<Widget>[
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(systemManagerProvider.notifier)
                    .refreshSnapshot(systemId),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(systemManagerProvider.notifier)
                    .disconnect(systemId),
                icon: const Icon(Icons.logout),
                label: const Text('Disconnect'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _featureChips(SystemFeatures features) {
    final List<String> labels = <String>[
      if (features.powerControl) 'Power control',
      if (features.sensorMonitoring) 'Sensors (${features.sensorCount})',
      if (features.firmwareUpdate) 'Firmware update',
      if (features.kvm) 'KVM (${features.kvmType ?? 'console'})',
      if (features.managers > 0) 'Managers: ${features.managers}',
      if (features.chassis > 0) 'Chassis: ${features.chassis}',
    ];
    if (labels.isEmpty) {
      return const Text('No optional features discovered.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .map(
            (String l) => Chip(label: Text(l)),
          )
          .toList(),
    );
  }
}
