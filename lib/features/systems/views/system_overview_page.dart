import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/overview/views/overview_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Per-system overview page (the `overview` tab inside [SystemShell]).
///
/// Surfaces connection controls (connect / refresh / disconnect) plus the
/// discovered [SystemFeatures] as capability chips, and delegates the rich,
/// schema-driven, adaptive card layout to [OverviewView] (issue #006). The
/// baseline identity/health header moved into [OverviewView] so there is a
/// single source of truth for system summary rendering.
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

    final SystemFeatures? features = handle.features;
    final bool connected = handle.status == ConnectionStatus.connected;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: '${handle.displayName}, '
                        '${handle.profile.scheme}://${handle.profile.host}:'
                        '${handle.profile.port}',
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
                      ],
                    ),
                  ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
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
        ),
        if (features != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _featureChips(context, features),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(child: OverviewView(systemId: systemId)),
      ],
    );
  }

  Widget _featureChips(BuildContext context, SystemFeatures features) {
    final List<String> labels = <String>[
      if (features.powerControl) 'Power control',
      if (features.sensorMonitoring) 'Sensors (${features.sensorCount})',
      if (features.firmwareUpdate) 'Firmware update',
      if (features.kvm) 'KVM (${features.kvmType ?? 'console'})',
      if (features.managers > 0) 'Managers: ${features.managers}',
      if (features.chassis > 0) 'Chassis: ${features.chassis}',
    ];
    if (labels.isEmpty) {
      // UI-2: a successful discovery with zero optional features renders the
      // established empty-state pattern — one self-describing merged semantics
      // node (icon + visible text), matching the Dashboard/Firmware/KVM/Sensors
      // empty states. No Retry: the feature discovery succeeded, there is
      // nothing to retry.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label: 'No optional features discovered.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.category_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'No optional features discovered.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
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
