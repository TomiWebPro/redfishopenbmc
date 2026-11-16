import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// In-app console viewer scaffold for a [KvmConsole] (issue #021).
///
/// When the console exposes an HTML5 HTTP(S) [KvmConsole.connectUri], this page
/// provides the in-app launch destination. Embedded WebView rendering is not yet
/// wired because it requires a platform WebView dependency; until then the page
/// surfaces the launch URI, renderability status, and copy action so operators
/// can open it externally while the app keeps an in-app navigation path.
class KvmConsoleViewerPage extends StatelessWidget {
  /// Creates a [KvmConsoleViewerPage] for [console].
  const KvmConsoleViewerPage({required this.console, super.key});

  /// The console to view.
  final KvmConsole console;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? uri = console.launchUri;
    final bool html5 = console.canLaunchInAppHtml5;
    final bool externalClient = console.requiresExternalConsoleClient;
    final String statusLabel = html5
        ? 'In-app HTML5 console path available for this URI. '
            'Embedded rendering requires a WebView dependency.'
        : externalClient
            ? 'This console URI uses a protocol that requires an external '
                'VNC/KVMIP/RFB client. Embedded rendering is not available '
                'in-app.'
            : 'In-app embedded rendering is not available for this console. '
                'Use the URI externally if provided.';
    final String statusText = html5
        ? 'In-app HTML5 console path available for this URI. '
            'Embedded rendering requires a WebView '
            'dependency (see issue #021 strategy).'
        : externalClient
            ? 'This console URI uses a protocol that requires an external '
                'VNC/KVMIP/RFB client. Embedded rendering is not available '
                'in-app.'
            : 'In-app embedded rendering is not available for this console. '
                'Use the URI externally if provided.';
    return Scaffold(
      appBar: AppBar(
        title: Text('${console.type.label} viewer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label:
                        '${console.type.label}, manager ${console.managerId}',
                    child: Text(
                      '${console.type.label} · Manager ${console.managerId}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: statusLabel,
                    child: Text(
                      statusText,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (uri != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: 'Console URI: $uri',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Console URI',
                              style: theme.textTheme.labelLarge),
                          const SizedBox(height: 4),
                          SelectableText(uri),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: uri));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied: $uri')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy console URI'),
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: 12),
                    Semantics(
                      container: true,
                      excludeSemantics: true,
                      label:
                          'No direct console URI. Manager source: ${console.sourceManagerUri}',
                      child: Text(
                        'No direct console URI. Manager source: '
                        '${console.sourceManagerUri}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
