import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/power/models/power_state.dart';
import 'package:redfishopenbmc/features/power/power_controller.dart';
import 'package:redfishopenbmc/features/power/power_providers.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/widgets/status_badges.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Power management screen for a single system (issue #005).
///
/// Rendered only when the system advertises power control ([SystemFeatures.
/// powerControl] is `true`); the [SystemShell] already hides the tab otherwise,
/// and this view additionally renders nothing when the capability is absent so
/// there is never a placeholder. Surfaces the live [PowerState] badge, the
/// supported reset actions (with confirmation for destructive ones), and
/// optimistic / polling feedback driven by [PowerController].
class PowerView extends ConsumerWidget {
  /// Creates a [PowerView] for [systemId].
  const PowerView({required this.systemId, super.key});

  /// Logical id of the system this view is scoped to.
  final String systemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
    final SystemFeatures? features = handle?.features;

    // Discovery not complete yet (or tab shown before capability gate).
    // Established UI-2 pattern: one merged, self-describing announcement (no
    // Retry — the system id does not exist, there is nothing to reload).
    if (handle == null) {
      return Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'System not found',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.search_off_outlined, size: 40),
              SizedBox(height: 8),
              Text('System not found'),
            ],
          ),
        ),
      );
    }
    if (features == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hard gate: no power control → render nothing (no placeholder).
    if (!features.powerControl) {
      return const SizedBox.shrink();
    }

    final PowerUiState ui = ref.watch(powerControllerProvider(systemId));
    final PowerController controller =
        ref.read(powerControllerProvider(systemId).notifier);
    final List<String> allowed = features.supportedResetTypes;

    bool isSupported(ResetType t) =>
        allowed.isEmpty || allowed.contains(t.toRedfish());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  // UI-2: the card header (title + PowerBadge + the "Power
                  // control" subtitle) announces as ONE merged node, the same
                  // pattern as the KVM/SystemCard/InfoCard headers. The power
                  // badge otherwise announces as a separate bare node ("Power
                  // Off") right after the system name, and the subtitle would
                  // announce as a third detached text. The visible texts are
                  // preserved for sighted users.
                  container: true,
                  excludeSemantics: true,
                  label: '${handle.displayName}, power ${ui.powerState.label}, '
                      'Power control',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              handle.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          PowerBadge(powerState: ui.powerState),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Power control',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (ui.error != null) ...[
                  // UI-2: the inline error announces as ONE merged node in
                  // context ('Power control failed. <message>') — the
                  // established error-state pattern (OverviewView/SensorsView/
                  // FirmwareView). The visible text is preserved and the
                  // Retry control keeps its own semantics node.
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: 'Power control failed. ${ui.error}',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        ui.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton.icon(
                        onPressed: () => controller.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                  ),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final ResetType action in ResetType.primaryActions)
                      ResetButton(
                        action: action,
                        enabled: isSupported(action),
                        busy: ui.actionInFlight,
                        onPressed: () => _confirmAndRun(
                          context,
                          ref,
                          action,
                          handle.displayName,
                          controller,
                        ),
                      ),
                  ],
                ),
                if (ui.actionInFlight)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // UI-2: the guidance line announces as ONE self-describing node (the
        // established card-row pattern — same class as the KVM console card's
        // "HTML5 console — open via BMC web UI." line) instead of a bare
        // detached sentence below the card. The visible text is preserved.
        Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Destructive actions (force off, restart) require '
              'confirmation. State refreshes automatically after a reset.',
          child: Text(
            'Destructive actions (force off, restart) require confirmation. '
            'State refreshes automatically after a reset.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context,
    WidgetRef ref,
    ResetType action,
    String systemName,
    PowerController controller,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      // The dialog owns the in-flight state (UI-5): the confirm button
      // disables and shows a spinner while the reset request is pending, so
      // it must not be dismissible by tapping the barrier mid-flight.
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => ConfirmResetDialog(
        action: action,
        systemName: systemName,
        onConfirm: () => controller.reset(action),
      ),
    );
    if (confirmed != true) return;

    if (!context.mounted) return;
    final PowerUiState after = ref.read(powerControllerProvider(systemId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          after.error != null ? after.error! : '${action.label} issued',
        ),
        backgroundColor:
            after.error != null ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

/// A single reset action button.
///
/// Non-destructive actions ([ResetType.on]) use the default filled style;
/// destructive ones use a destructive (error) color. Disabled when the system
/// does not advertise the underlying `ResetType` in
/// [SystemFeatures.supportedResetTypes].
class ResetButton extends StatelessWidget {
  /// Creates a [ResetButton].
  const ResetButton({
    required this.action,
    required this.onPressed,
    this.enabled = true,
    this.busy = false,
    super.key,
  });

  /// The reset type this button triggers.
  final ResetType action;

  /// Whether the reset type is advertised by the system.
  final bool enabled;

  /// Whether an action is currently in flight (shows a spinner, disables input).
  final bool busy;

  /// Callback invoked when the button is pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool disabled = !enabled || busy;
    final ButtonStyle style = action.isDestructive
        ? FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          )
        : const ButtonStyle();

    return Semantics(
      // Announce the in-flight state to assistive tech; the visible label
      // already communicates the action, so append the state rather than
      // replacing it (keeps the button's name stable for re-discovery).
      label: busy ? '${action.label}, action in progress' : null,
      button: true,
      child: FilledButton.icon(
        onPressed: disabled ? null : onPressed,
        icon: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(action.isDestructive ? Icons.warning_amber : Icons.power),
        label: Text(action.label),
        style: style,
      ),
    );
  }
}

/// Confirmation dialog shown before a destructive (or any) reset action.
///
/// UI-5: the confirm button owns the in-flight state — while [onConfirm]'s
/// future is pending the confirm button is disabled and shows a spinner, and
/// both buttons stop responding, so the operator gets unambiguous feedback
/// that the request is being sent. The dialog only pops (`true`) once the
/// action completes (or fails) — [PowerController.reset] never throws, it
/// records the error in state, so the caller can read the outcome afterwards.
class ConfirmResetDialog extends StatefulWidget {
  /// Creates a [ConfirmResetDialog].
  const ConfirmResetDialog({
    required this.action,
    required this.systemName,
    required this.onConfirm,
    super.key,
  });

  /// The reset type being confirmed.
  final ResetType action;

  /// Display name of the target system.
  final String systemName;

  /// Invoked when the operator confirms; awaited before the dialog pops.
  final Future<void> Function() onConfirm;

  @override
  State<ConfirmResetDialog> createState() => _ConfirmResetDialogState();
}

class _ConfirmResetDialogState extends State<ConfirmResetDialog> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    await widget.onConfirm();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool destructive = widget.action.isDestructive;
    final String confirmLabel = destructive ? 'Force' : 'Confirm';
    return AlertDialog(
      title: Text('Confirm ${widget.action.label}?'),
      content: Text(
        destructive
            ? 'This will ${widget.action.label} "${widget.systemName}".\n\n'
                'This action may interrupt service; unsaved work on the host '
                'could be lost. Continue?'
            : 'This will ${widget.action.label} "${widget.systemName}". '
                'Continue?',
      ),
      actions: <Widget>[
        TextButton(
          // UI-2: explicit ≥48px touch target for the dialog actions; the
          // Material default visible height is 36dp (tap target padded to
          // 48dp only for gestures, not for the visual affordance).
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        Semantics(
          label: _busy
              ? '${destructive ? 'Force' : 'Confirm'} ${widget.action.label}, '
                  'action in progress'
              : destructive
                  ? 'Confirm ${widget.action.label} (destructive)'
                  : 'Confirm ${widget.action.label}',
          button: true,
          child: FilledButton(
            style: (destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      )
                    : FilledButton.styleFrom())
                .copyWith(
              minimumSize: const WidgetStatePropertyAll<Size>(Size(48, 48)),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: _busy ? null : _confirm,
            child: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
