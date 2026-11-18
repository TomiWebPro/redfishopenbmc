/// Per-manager remote-KVM capability card (issue #009).
///
/// Renders the aggregated [KvmCapability] detected from a Redfish manager: the
/// manager id, service-enabled state, advertised connection types, the maximum
/// concurrent-session limit and the resolved console URI. Every row follows the
/// established single-merged-Semantics-node pattern (UI-2) so a screen reader
/// hears a self-describing sentence rather than detached label/value fragments.
///
/// Pure presentation: it performs no discovery, opens no URL and never alters
/// transport security — a resolved URI is only displayed to the operator (the
/// caller decides how, if at all, to open it). No WebView/protocol dependency
/// and no production TLS change is involved (issues #009 / #021).
library;

import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';

/// A single per-manager remote-KVM capability summary card (issue #009).
class KvmCapabilityCard extends StatelessWidget {
  /// Creates a [KvmCapabilityCard] for [capability].
  const KvmCapabilityCard({required this.capability, super.key});

  /// The aggregated capability this card renders.
  final KvmCapability capability;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              container: true,
              excludeSemantics: true,
              label: 'Manager capability ${capability.managerId}, '
                  '${capability.serviceEnabled ? 'enabled' : 'disabled'}, '
                  '${capability.supported ? 'KVM supported' : 'KVM not supported'}',
              // A Column + Wrap (not a Row + Expanded): at the 320 px
              // breakpoint two status chips beside the title squeeze the text
              // into a near-zero width and overflow. Flowing the chips keeps
              // every field visible (UI-3).
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Manager capability: ${capability.managerId}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      if (capability.supported)
                        const Chip(
                          label: Text('Supported'),
                          visualDensity: VisualDensity.compact,
                        ),
                      Chip(
                        label: Text(
                            capability.serviceEnabled ? 'Enabled' : 'Disabled'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Service-enabled state announces as one self-describing node.
            Semantics(
              container: true,
              excludeSemantics: true,
              label: 'Service enabled: '
                  '${capability.serviceEnabled ? 'yes' : 'no'}',
              child: Text(
                'Service enabled: ${capability.serviceEnabled ? 'Yes' : 'No'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (capability.connectTypes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              // Connect-type chips announce as ONE node (e.g.
              // 'Connection types: KVMIP, HTML5'), never as detached chips.
              Semantics(
                container: true,
                excludeSemantics: true,
                label:
                    'Connection types: ${capability.connectTypes.join(', ')}',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final String type in capability.connectTypes)
                      Chip(
                        label: Text(type),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ],
            if (capability.maxSessions != null) ...<Widget>[
              const SizedBox(height: 8),
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Max sessions: ${capability.maxSessions}',
                child: Text(
                  'Max sessions: ${capability.maxSessions}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (capability.hasUri)
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'Resolved URI: ${capability.uri}',
                // Two lines (label above, value below) rather than a Row: a
                // long BMC URL has no break points and would overflow beside
                // the label at the 320 px breakpoint (UI-3).
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Resolved URI:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      capability.uri!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'No console URI resolved. Source: '
                    '${capability.sourceManagerUri ?? 'unknown'}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'No console URI resolved. Source:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      capability.sourceManagerUri ?? 'unknown',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (!capability.serviceEnabled) ...<Widget>[
              const SizedBox(height: 12),
              // Acceptance #009: an explicit helper when KVM is disabled.
              Semantics(
                container: true,
                excludeSemantics: true,
                label: 'KVM disabled on BMC. Enable the console service in the '
                    'BMC settings.',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.lock_outline, size: 18, color: scheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'KVM disabled on BMC. Enable the console service in the '
                        'BMC settings.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
