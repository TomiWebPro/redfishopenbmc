import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/kvm/kvm_session.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';

/// In-app console viewer scaffold for a [KvmConsole] (issue #021).
///
/// When the console exposes an HTML5 HTTP(S) [KvmConsole.connectUri], this page
/// provides the in-app launch destination. Embedded WebView rendering is not yet
/// wired because it requires a platform WebView dependency; until then the page
/// surfaces the launch URI, renderability status, and copy action so operators
/// can open it externally while the app keeps an in-app navigation path.
///
/// Session lifecycle (EP-U4 / #009): this page is the app's full-screen console
/// surface. Opening it starts a pure-UI [KvmSessionController] session for the
/// console's manager, and leaving it (back / pop / explicit Disconnect) ends
/// that session. It holds no Redfish client, opens no URL and never weakens
/// production TLS.
class KvmConsoleViewerPage extends ConsumerStatefulWidget {
  /// Creates a [KvmConsoleViewerPage] for [console].
  const KvmConsoleViewerPage({required this.console, super.key});

  /// The console to view.
  final KvmConsole console;

  @override
  ConsumerState<KvmConsoleViewerPage> createState() =>
      _KvmConsoleViewerPageState();
}

class _KvmConsoleViewerPageState extends ConsumerState<KvmConsoleViewerPage> {
  late final KvmSessionController _session;

  @override
  void initState() {
    super.initState();
    _session = ref.read(kvmSessionProvider.notifier);
    // Opening the viewer is "entering fullscreen": start tracking a console
    // session for this manager. Deferred to the first post-frame so the notifier
    // update never lands mid-build. The console's own limit is passed through so
    // a single-session BMC can record an eviction when another console is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _session.connect(
        widget.console.managerId,
        maxConcurrentSessions: widget.console.maxConcurrentSessions,
      );
    });
  }

  /// Whether the shared session is still this viewer's console.
  ///
  /// The viewer must not keep a local "connected" flag: the session is owned by
  /// the app-wide [kvmSessionProvider] and can change underneath this widget —
  /// a single-session BMC evicts this console when another viewer connects. A
  /// stale local flag then advertised a session we no longer own and, worse,
  /// left the Disconnect button able to end the *other* console's session on
  /// tap/pop. Always derive ownership from the shared state at use time
  /// (EP-U4 closeout / #009). The trim matches [KvmSessionController.connect]'s
  /// normalization of the manager id.
  bool _ownsActiveSession() {
    final KvmSessionState session = ref.read(kvmSessionProvider);
    return session.isConnected &&
        session.activeManagerId == widget.console.managerId.trim();
  }

  // Back / system pop ends the session (EP-U4): the BMC console itself persists
  // until its own timeout, but the app no longer tracks it. This runs from a
  // PopScope callback (not a widget lifecycle method), so Riverpod's "no
  // provider writes during build/lifecycle" guard is respected. Only end the
  // session when this viewer still owns it — popping an evicted viewer must not
  // disconnect the newer console (EP-U4 closeout).
  void _endSessionOnExit(bool didPop, Object? result) {
    if (didPop && _ownsActiveSession()) _session.disconnect();
  }

  void _disconnectConsole() {
    if (!_ownsActiveSession()) return;
    _session.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KvmConsole console = widget.console;
    // #009/#021: take the copy target from the fail-closed launch decision
    // layer rather than the raw model URI. Under the production policy this is
    // the trimmed endpoint for every route (never a whitespace-padded target),
    // and a plaintext/disabled console is copy-only — its URI stays visible and
    // copyable for external use, but is never handed to a launcher. The viewer
    // cannot disagree with the model's canOpenConsole / launchStrategy about
    // what may be launched. No WebView/protocol plugin, no TLS weakening.
    final String? uri = console.launchPlan.targetUri;
    // UI-2 / a11y: the status card uses `excludeSemantics`, so this ONE message
    // is both the visible text and the announced Semantics label. Keeping a
    // single source of truth guarantees screen-reader users hear exactly the
    // same actionable guidance as sighted users (previously the announced label
    // was shorter and silently dropped the "open in a browser" / "copy the URI"
    // steps). No internal issue references in user-facing copy.
    // #021: the strategy is resolved once in the model (deterministic priority:
    // no URI → disabled → insecure HTML5 → insecure HTTP → in-app HTML5 →
    // external client → secure browser) and the guidance is produced by one
    // pure resolver, so the viewer cannot disagree with the model's launch
    // decision.
    final KvmLaunchStrategy strategy = console.launchStrategy;
    final String statusText = kvmLaunchStatusText(
      strategy,
      externalProtocol: console.externalClientProtocolLabel,
    );
    // Security (#021): a plaintext-HTTP console (HTML5 or not) is never an
    // in-app/browser render candidate — colour its cleartext warning as an
    // error for a visual cue, matching both cards, without ever weakening the
    // app's TLS posture.
    final bool insecureTransport =
        strategy == KvmLaunchStrategy.insecureHtml5 ||
            strategy == KvmLaunchStrategy.insecureHttp;
    final TextStyle? statusStyle = insecureTransport
        ? theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error, fontWeight: FontWeight.w600)
        : theme.textTheme.bodyMedium;
    // Session disclosure is derived from the shared controller (EP-U4 closeout):
    // watching the provider rebuilds this page when the session changes, so an
    // evicted viewer flips to the idle notice and disables Disconnect instead
    // of advertising a session it no longer owns. Visible text == announced
    // label stays true via one merged excludeSemantics node below.
    final KvmSessionState session = ref.watch(kvmSessionProvider);
    final bool sessionActive = session.isConnected &&
        session.activeManagerId == console.managerId.trim();
    final String sessionNotice =
        sessionActive ? kvmSessionActiveNotice : kvmSessionIdleNotice;
    return PopScope<void>(
      onPopInvokedWithResult: _endSessionOnExit,
      child: Scaffold(
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
                            'No direct console URI. Manager source: ${console.safeManagerUri}',
                        child: Text(
                          'No direct console URI. Manager source: '
                          '${console.safeManagerUri}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                    // RU-2 / #009: the deepest console surface carries the same
                    // session-persistence guidance as the gated list view, via
                    // one shared constant so the visible text and the merged
                    // announced label can never drift from the list view. A
                    // screen-reader user who drills into a console still hears
                    // that the session outlives the tab until manager timeout.
                    const SizedBox(height: 12),
                    Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: kvmSessionPersistenceNotice,
                      child: Text(
                        kvmSessionPersistenceNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    // EP-U4 / #009: session lifecycle disclosure + explicit
                    // disconnect affordance. One merged excludeSemantics node
                    // makes the notice's visible text equal its announced label,
                    // while the Disconnect button stays a separately focusable
                    // semantics node so screen-reader users can activate it.
                    const SizedBox(height: 12),
                    Semantics(
                      container: true,
                      excludeSemantics: true,
                      label: sessionNotice,
                      child: Text(
                        sessionNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('kvm-disconnect-console'),
                      onPressed: sessionActive ? _disconnectConsole : null,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect console'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
