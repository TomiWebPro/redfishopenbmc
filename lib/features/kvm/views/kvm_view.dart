import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Remote KVM screen for a single system (issue #009).
///
/// Rendered only when the system advertises a console ([SystemFeatures.kvm] is
/// `true`); the [SystemShell] already hides the tab otherwise, and this view
/// additionally renders nothing when the capability is absent so there is never
/// a placeholder. Lists each discovered [KvmConsole] with its connection types
/// and a copy-to-clipboard action for the connect URI.
class KvmView extends ConsumerStatefulWidget {
  /// Creates a [KvmView] for [systemId].
  const KvmView({required this.systemId, super.key});

  /// Logical id of the system this view is scoped to.
  final String systemId;

  @override
  ConsumerState<KvmView> createState() => _KvmViewState();
}

class _KvmViewState extends ConsumerState<KvmView> {
  @override
  void initState() {
    super.initState();
    // Trigger the first load once the frame is laid out so we don't call
    // ref.read during build (which would throw in some Riverpod versions).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(kvmControllerProvider(widget.systemId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final SystemHandle? handle = ref.watch(systemHandleProvider(widget.systemId));
    final SystemFeatures? features = handle?.features;

    if (handle == null) {
      return const Center(child: Text('System not found'));
    }
    if (features == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hard gate: no KVM → render nothing (no placeholder).
    if (!features.kvm) {
      return const SizedBox.shrink();
    }

    final KvmUiState ui = ref.watch(kvmControllerProvider(widget.systemId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Remote KVM / Consoles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Consoles exposed by the system managers.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (ui.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              ui.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (ui.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (ui.consoles.isEmpty && ui.error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No consoles found.')),
          )
        else
          for (final KvmConsole console in ui.consoles)
            _ConsoleCard(console: console),
      ],
    );
  }
}

/// A single console card showing its type, manager, connect types, and a
/// copy-to-clipboard action.
class _ConsoleCard extends StatelessWidget {
  /// Creates a [_ConsoleCard].
  const _ConsoleCard({required this.console});

  /// The console to render.
  final KvmConsole console;

  @override
  Widget build(BuildContext context) {
    final String targetUri = console.connectUri ?? console.sourceManagerUri;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    console.type.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (console.serviceEnabled)
                  const Chip(
                    label: Text('Enabled'),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  const Chip(
                    label: Text('Disabled'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Manager: ${console.managerId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String type in console.connectTypesSupported)
                  Chip(
                    label: Text(type),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (console.maxConcurrentSessions != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Max concurrent sessions: ${console.maxConcurrentSessions}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (console.supportsHtml5) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'HTML5 console — open via BMC web UI.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
            if (console.connectUri != null) ...<Widget>[
              const SizedBox(height: 8),
              const Text('Connect URI:'),
              SelectableText(
                console.connectUri!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: targetUri));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied: $targetUri')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy connect info'),
            ),
          ],
        ),
      ),
    );
  }
}
