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
    // UI-2 / a11y: the status card uses `excludeSemantics`, so this ONE message
    // is both the visible text and the announced Semantics label. Keeping a
    // single source of truth guarantees screen-reader users hear exactly the
    // same actionable guidance as sighted users (previously the announced label
    // was shorter and silently dropped the "open in a browser" / "copy the URI"
    // steps). No internal issue references in user-facing copy.
    // #021: the strategy is resolved once in the model (deterministic priority:
    // no URI → disabled → insecure HTML5 → in-app HTML5 → external client →
    // secure browser) and the guidance is produced by one pure resolver, so the
    // viewer cannot disagree with the model's launch decision.
    final KvmLaunchStrategy strategy = console.launchStrategy;
    final String statusText = kvmLaunchStatusText(
      strategy,
      externalProtocol: console.externalClientProtocolLabel,
    );
    // Security (#021): a plaintext-HTTP HTML5 console is never an in-app render
    // candidate — colour its warning as an error for a visual cue, without ever
    // weakening the app's TLS posture.
    final TextStyle? statusStyle = strategy == KvmLaunchStrategy.insecureHtml5
        ? theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error, fontWeight: FontWeight.w600)
        : theme.textTheme.bodyMedium;
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
                    label: statusText,
                    child: Text(
                      statusText,
                      style: statusStyle,
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
