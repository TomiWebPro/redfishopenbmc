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
    final bool insecureHtml5 =
        console.supportsHtml5 && console.usesInsecureHttpLaunchUri;
    final bool html5 = console.canLaunchInAppHtml5;
    final bool externalClient = console.requiresExternalConsoleClient;
    final String externalProtocol =
        console.externalClientProtocolLabel ?? 'external console';
    // UI-2 / a11y: the status card uses `excludeSemantics`, so this ONE message
    // is both the visible text and the announced Semantics label. Keeping a
    // single source of truth guarantees screen-reader users hear exactly the
    // same actionable guidance as sighted users (previously the announced label
    // was shorter and silently dropped the "open in a browser" / "copy the URI"
    // steps). No internal issue references in user-facing copy.
    // Security (#021): a plaintext-HTTP HTML5 console is never an in-app render
    // candidate. Surface that explicitly (rather than the generic fallback) so
    // operators are told to enable HTTPS instead of assuming the app supports
    // an unencrypted console. The message is also styled as an error for a
    // visual cue; it never weakens the app's TLS posture.
    final String statusText = insecureHtml5
        ? 'This HTML5 console uses an unencrypted HTTP connection. '
            'In-app rendering is disabled to keep console video and input '
            'encrypted. Configure the BMC console to use HTTPS before '
            'opening it in a browser.'
        : html5
            ? 'In-app HTML5 console path available for this URI. '
                'Embedded rendering requires a WebView dependency. '
                'You can open this URI in a web browser if your BMC allows it.'
            : externalClient
                ? 'This console URI uses a protocol that requires an external '
                    '$externalProtocol client. Embedded rendering is not '
                    'available in-app. Copy the URI and open it with a '
                    'compatible client.'
                : 'In-app embedded rendering is not available for this console. '
                    'Use the URI externally if provided.';
    final TextStyle? statusStyle = insecureHtml5
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
