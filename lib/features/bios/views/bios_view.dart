import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/bios/bios_controller.dart';
import 'package:redfishopenbmc/features/bios/bios_providers.dart';
import 'package:redfishopenbmc/features/bios/models/bios_models.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// BIOS configuration view for a single system (issue #028, read-only slice).
///
/// Capability-gated: rendered only when [SystemFeatures.biosConfiguration] is
/// true; when absent or discovery is incomplete this view renders nothing so
/// there is never a placeholder. Shows current BIOS attributes and, when a
/// `@Redfish.Settings` pending resource is advertised, a summary of pending
/// settings/messages. Editing actions are out of scope for this slice.
class BiosView extends ConsumerStatefulWidget {
  /// Creates a [BiosView] for [systemId].
  const BiosView({required this.systemId, super.key});

  /// Logical id of the system this view is scoped to.
  final String systemId;

  @override
  ConsumerState<BiosView> createState() => _BiosViewState();
}

class _BiosViewState extends ConsumerState<BiosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(biosControllerProvider(widget.systemId).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final SystemHandle? handle =
        ref.watch(systemHandleProvider(widget.systemId));
    final SystemFeatures? features = handle?.features;

    // Discovery pending: single merged loading announcement (UI-2 pattern).
    if (handle == null || features == null) {
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Loading BIOS',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    // Hard gate: no BIOS capability → render nothing.
    if (!features.biosConfiguration) {
      return const SizedBox.shrink();
    }

    final BiosUiState ui = ref.watch(biosControllerProvider(widget.systemId));
    final BiosController controller =
        ref.read(biosControllerProvider(widget.systemId).notifier);

    if (ui.loading && ui.current == null) {
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Loading BIOS settings',
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (ui.error != null && ui.current == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            container: true,
            label: 'Failed to load BIOS settings. ${ui.error}.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load BIOS settings',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(ui.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final BiosResource? bios = ui.current;
    if (bios == null) {
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'No BIOS information available',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.settings_input_component_outlined, size: 40),
              SizedBox(height: 12),
              Text('No BIOS information available'),
            ],
          ),
        ),
      );
    }

    final List<MapEntry<String, dynamic>> attrs =
        bios.attributes.values.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final BiosPendingSettings? pending = ui.pending;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _summaryCard(context, bios, pending),
        const SizedBox(height: 12),
        if (pending != null) ...<Widget>[
          _pendingCard(context, bios, pending),
          const SizedBox(height: 12),
        ],
        _attributesCard(context, attrs),
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context,
    BiosResource bios,
    BiosPendingSettings? pending,
  ) {
    final bool hasPending =
        (bios.pendingSettingsUri != null && bios.pendingSettingsUri!.isNotEmpty) ||
            (bios.resetBiosToDefaultsPending ?? false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label:
              'BIOS ${bios.name ?? bios.id ?? "settings"}. ${hasPending ? "Pending changes" : "No pending changes"}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'BIOS settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _kv(context, 'Name', bios.name ?? bios.id ?? 'BIOS'),
              if (bios.attributeRegistry != null)
                _kv(context, 'Attribute registry', bios.attributeRegistry!),
              _kv(
                context,
                'Pending changes',
                hasPending ? 'Yes' : 'No',
              ),
              if (bios.resetBiosToDefaultsPending == true)
                _kv(context, 'Reset to defaults pending', 'Yes'),
              if (pending?.attributes.values.isNotEmpty ?? false)
                _kv(
                  context,
                  'Pending attributes',
                  '${pending!.attributes.values.length}',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingCard(
    BuildContext context,
    BiosResource bios,
    BiosPendingSettings pending,
  ) {
    final Set<String> changed =
        BiosAttributes.diffKeys(bios.attributes, pending.attributes);
    final List<String> changedList = changed.toList()..sort();
    final List<BiosSettingsMessage> messages =
        bios.settings?.messages ?? const <BiosSettingsMessage>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Pending settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              changedList.isEmpty
                  ? 'No attribute differences reported.'
                  : 'Changed attributes: ${changedList.join(", ")}',
            ),
            if (messages.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              ...messages.map(
                (BiosSettingsMessage m) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    m.message ?? m.messageId ?? 'Settings message',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _attributesCard(
    BuildContext context,
    List<MapEntry<String, dynamic>> attrs,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Attributes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (attrs.isEmpty)
              const Text('No attributes exposed by this BMC.')
            else
              ...attrs.map(
                (MapEntry<String, dynamic> e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _kv(context, e.key, '${e.value}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            key,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text(value)),
      ],
    );
  }
}
