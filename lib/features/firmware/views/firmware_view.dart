import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/firmware/firmware_controller.dart';
import 'package:redfishopenbmc/features/firmware/firmware_providers.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Firmware & update management screen for a single system (issue #008).
///
/// Rendered only when the system advertises `UpdateService`
/// ([SystemFeatures.firmwareUpdate] is `true`); when the capability is absent
/// (or discovery is incomplete) this view renders nothing so there is never a
/// placeholder. Surfaces the firmware inventory cards and a SimpleUpdate form
/// driven by [FirmwareController].
class FirmwareView extends ConsumerStatefulWidget {
  /// Creates a [FirmwareView] for [systemId].
  const FirmwareView({required this.systemId, super.key});

  /// Logical id of the system this view is scoped to.
  final String systemId;

  @override
  ConsumerState<FirmwareView> createState() => _FirmwareViewState();
}

class _FirmwareViewState extends ConsumerState<FirmwareView> {
  final TextEditingController _imageUriController = TextEditingController();
  String _transferProtocol = 'HTTP';

  @override
  void initState() {
    super.initState();
    // Auto-load the inventory on first paint (post-frame so the notifier is
    // mounted and watchers are ready).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(firmwareControllerProvider(widget.systemId).notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _imageUriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SystemHandle? handle =
        ref.watch(systemHandleProvider(widget.systemId));
    final SystemFeatures? features = handle?.features;

    // Discovery not complete yet (or tab shown before capability gate).
    if (handle == null || features == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hard gate: no firmware update capability → render nothing (no placeholder).
    if (!features.firmwareUpdate) {
      return const SizedBox.shrink();
    }

    final FirmwareUiState ui =
        ref.watch(firmwareControllerProvider(widget.systemId));
    final FirmwareController controller =
        ref.read(firmwareControllerProvider(widget.systemId).notifier);
    final List<String> protocols = ui.info?.transferProtocols ??
        const UpdateServiceInfo().transferProtocols;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Firmware & update management',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (ui.loading)
                      const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 4),
                _ServiceSummary(info: ui.info),
                const SizedBox(height: 12),
                if (ui.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                ui.error!,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed:
                                  ui.loading ? null : () => controller.load(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                _InventoryList(info: ui.info),
                if (ui.lastTaskUri != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Update queued: ${ui.lastTaskUri!.isEmpty ? '(no task URI returned)' : ui.lastTaskUri}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Start update',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _imageUriController,
                  decoration: const InputDecoration(
                    labelText: 'Image URI',
                    hintText: 'http://host/path/firmware.bin',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _transferProtocol,
                  isExpanded: true,
                  items: <DropdownMenuItem<String>>[
                    for (final String p in protocols)
                      DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _transferProtocol = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: ui.loading
                      ? null
                      : () {
                          final String uri = _imageUriController.text.trim();
                          if (uri.isEmpty) return;
                          controller.startUpdate(
                            SimpleUpdateRequest(
                              imageUri: uri,
                              transferProtocol: _transferProtocol,
                              targets: const <String>[],
                            ),
                          );
                        },
                  icon: const Icon(Icons.system_update),
                  label: const Text('Start'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders the UpdateService summary line (version + HTTP push URI).
class _ServiceSummary extends StatelessWidget {
  /// Creates a [_ServiceSummary].
  const _ServiceSummary({this.info});

  /// The loaded update-service info, or `null` before first load.
  final UpdateServiceInfo? info;

  @override
  Widget build(BuildContext context) {
    final String? version = info?.version;
    final String? httpPushUri = info?.httpPushUri;
    final String text = 'UpdateService ${version ?? ''}'
        '${httpPushUri != null ? ' · $httpPushUri' : ''}';
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// Renders the firmware inventory cards for a [FirmwareUiState.info].
class _InventoryList extends StatelessWidget {
  /// Creates an [_InventoryList].
  const _InventoryList({this.info});

  /// The loaded update-service info, or `null` before first load.
  final UpdateServiceInfo? info;

  @override
  Widget build(BuildContext context) {
    if (info == null) {
      return const Text('Loading inventory…');
    }
    final UpdateServiceInfo data = info!;
    if (data.inventory.isEmpty) {
      return const Text('No firmware inventory reported.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final FirmwareInventoryItem item in data.inventory)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              container: true,
              label: 'Firmware ${item.name ?? item.id}, '
                  '${item.version ?? 'version unknown'}, '
                  '${item.health ?? 'health unknown'}, '
                  '${item.updateable ? 'updateable' : 'locked'}',
              child: Card(
                child: ListTile(
                  title: Text(item.name ?? item.id),
                  subtitle: Text(
                    '${item.id}${item.version != null ? ' · ${item.version}' : ''}'
                    '${item.health != null ? ' · ${item.health}' : ''}',
                  ),
                  trailing: Chip(
                    label: Text(item.updateable ? 'Updateable' : 'Locked'),
                    backgroundColor: item.updateable
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
