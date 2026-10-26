import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/firmware/firmware_controller.dart';
import 'package:redfishopenbmc/features/firmware/firmware_providers.dart';
import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';
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
                // UI-2: the header row announces as ONE merged semantics node
                // (title + in-flight spinner), same pattern as the
                // SystemCard/InfoCard/KVM/PowerView/HealthBanner headers. The
                // CircularProgressIndicator otherwise announces a bare
                // progress node next to the title.
                Semantics(
                  container: true,
                  excludeSemantics: true,
                  label: ui.loading
                      ? 'Firmware and update management, loading'
                      : 'Firmware and update management',
                  child: Row(
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
                            // UI-2: the icon + message announce as ONE node,
                            // so a screen reader gets the error in context
                            // instead of a bare detached sentence (the
                            // established OverviewView/SensorsView error-state
                            // pattern). The Retry button keeps its own node
                            // (it is a control).
                            Expanded(
                              child: Semantics(
                                container: true,
                                excludeSemantics: true,
                                label: 'Unable to load firmware. ${ui.error}',
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
                                  ],
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
                if (ui.lastTask != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: _taskLabel(ui),
                      child: Row(
                        children: <Widget>[
                          if (ui.polling) ...<Widget>[
                            const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _taskText(ui),
                              style: TextStyle(
                                color: ui.lastResult != null
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          if (ui.lastResult != null && ui.lastResult!.isSuccess)
                            const SizedBox(width: 8),
                          if (ui.lastResult != null && ui.lastResult!.isSuccess)
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
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
                // UI-2: the protocol selector gets a visible + semantic label
                // ("Transfer protocol") — the bare DropdownButton previously
                // announced only its value with no field context (unlike the
                // Image URI TextField above, which carries a labelText), and
                // sighted users had no cue what the dropdown selected either.
                // The label is plain Text (its own semantics node, like the
                // TextField label), so the control keeps its own node and
                // screen readers hear "Transfer protocol" then the value.
                Text(
                  'Transfer protocol',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
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
                  icon: ui.starting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update),
                  label: Text(ui.starting ? 'Starting…' : 'Start'),
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
    final UpdateServiceInfo? data = info;
    if (data == null) {
      // UI-2: no update-service data yet (in-flight or the fetch failed). Do
      // NOT render a dangling 'UpdateService ' label — the header row already
      // announces the in-flight state and, on failure, the error card is the
      // message.
      return const SizedBox.shrink();
    }
    final String? version = data.version;
    final String? httpPushUri = data.httpPushUri;
    final List<String> parts = <String>[
      if (version != null) version,
      if (httpPushUri != null) httpPushUri,
    ];
    // UI-2: the summary is ONE self-describing announcement (label + value
    // together) instead of a bare detached text node next to the merged
    // header row.
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          parts.isEmpty ? 'UpdateService' : 'UpdateService ${parts.join(', ')}',
      child: Text(
        parts.isEmpty ? 'UpdateService' : 'UpdateService ${parts.join(' · ')}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Human-readable queued/polled update text for the firmware banner.
///
/// Shows the task monitor URI from the 202 `Location` header and, when the
/// service sent a `Retry-After` delay (DSP0266 §12.2), the wait hint. While
/// [FirmwareUiState.polling] the text switches to the in-progress form;
/// once the monitor returns a terminal [FirmwareUiState.lastResult] it shows
/// the final task state instead.
String _taskText(FirmwareUiState ui) {
  final UpdateTask task = ui.lastTask!;
  final RedfishTask? result = ui.lastResult;
  if (result != null) {
    final String status = result.statusNote ?? result.state;
    return 'Update task ${result.id}: $status';
  }
  final String uri = task.taskUri == null || task.taskUri!.isEmpty
      ? '(no task URI returned)'
      : task.taskUri!;
  final String retry = task.retryAfterSeconds != null
      ? ' · retry after ${task.retryAfterSeconds}s'
      : '';
  if (ui.polling) {
    return 'Update in progress: polling $uri$retry';
  }
  return 'Update queued: $uri$retry';
}

/// Concise accessibility label for the queued/polled update banner (UI-2).
String _taskLabel(FirmwareUiState ui) {
  final UpdateTask task = ui.lastTask!;
  final RedfishTask? result = ui.lastResult;
  if (result != null) {
    final String status = result.statusNote ?? result.state;
    return 'Update task ${result.id}, $status';
  }
  final String uri = task.taskUri == null || task.taskUri!.isEmpty
      ? 'no task URI'
      : task.taskUri!;
  final String retry = task.retryAfterSeconds != null
      ? ', retry after ${task.retryAfterSeconds} seconds'
      : '';
  if (ui.polling) {
    return 'Update in progress, polling $uri$retry';
  }
  return 'Update queued, $uri$retry';
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
      // UI-2: the in-flight inventory load announces as ONE merged semantics
      // node ('Loading firmware inventory') instead of a bare detached text
      // node next to the header — the established loading-state pattern
      // (header row merges its own spinner; this announces the specific
      // surface that is still loading).
      return Semantics(
        container: true,
        excludeSemantics: true,
        label: 'Loading firmware inventory',
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('Loading inventory…')),
        ),
      );
    }
    final UpdateServiceInfo data = info!;
    if (data.inventory.isEmpty) {
      // UI-2: a successful load with zero inventory renders the established
      // empty-state pattern — one self-describing merged semantics node (icon
      // + visible text), matching the Dashboard/KVM/Sensors empty states. No
      // Retry: the load succeeded, there is nothing to retry.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            container: true,
            excludeSemantics: true,
            label: 'No firmware inventory reported.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.inventory_2_outlined,
                    size: 40, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'No firmware inventory reported.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final FirmwareInventoryItem item in data.inventory)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              container: true,
              excludeSemantics: true,
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
