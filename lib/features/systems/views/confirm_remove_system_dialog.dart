import 'package:flutter/material.dart';

/// Confirmation dialog for the destructive "Remove system" dashboard action.
///
/// Mirrors the power-view [ConfirmResetDialog] pattern:
/// - keyboard focus moves INSIDE the dialog when it opens and lands on the
///   least-destructive action (Cancel) — WAI-ARIA dialog pattern, so an
///   Enter/Tab user cannot accidentally trigger a destructive removal;
/// - Tab walks Cancel → Remove and wraps;
/// - both actions expose explicit ≥48 px touch targets;
/// - the confirm button is styled in the error color and announces the
///   destructive semantics.
///
/// The copy makes the permanence explicit: removing a profile also discards
/// its saved credentials.
class ConfirmRemoveSystemDialog extends StatefulWidget {
  /// Creates a [ConfirmRemoveSystemDialog] for [systemName].
  const ConfirmRemoveSystemDialog({
    required this.systemName,
    required this.onConfirm,
    super.key,
  });

  /// Display name of the system being removed.
  final String systemName;

  /// Invoked when the operator confirms; awaited before the dialog pops.
  final Future<void> Function() onConfirm;

  @override
  State<ConfirmRemoveSystemDialog> createState() =>
      _ConfirmRemoveSystemDialogState();
}

class _ConfirmRemoveSystemDialogState extends State<ConfirmRemoveSystemDialog> {
  bool _busy = false;

  /// UI-2: owns keyboard focus for the least-destructive action (Cancel) so
  /// the dialog opens with focus INSIDE it (WAI-ARIA dialog pattern — the
  /// ConfirmResetDialog / Add-system dialog precedent). An Enter/Tab user
  /// cannot accidentally remove a system.
  final FocusNode _cancelFocus = FocusNode(
    debugLabel: 'ConfirmRemoveSystemDialog.cancel',
  );

  @override
  void initState() {
    super.initState();
    // Requested after the first frame so the dialog route's FocusScope is
    // already active (requesting during initState would target the page's
    // scope).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cancelFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _cancelFocus.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    await widget.onConfirm();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Remove system?'),
      content: Text(
        'This removes "${widget.systemName}" from the dashboard.\n\n'
        'The stored connection profile and its saved credentials will be '
        'deleted permanently. This cannot be undone. Continue?',
      ),
      actions: <Widget>[
        // UI-2: the Cancel button owns the dialog's initial keyboard focus
        // (see `_cancelFocus` — focus moves into the dialog and lands on the
        // least-destructive action; Tab then walks Cancel → Remove).
        TextButton(
          focusNode: _cancelFocus,
          // UI-2: explicit ≥48px touch target for the dialog actions (the
          // ConfirmResetDialog precedent).
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        Semantics(
          label: _busy
              ? 'Remove system, action in progress'
              : 'Remove system (destructive)',
          button: true,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ).copyWith(
              minimumSize: const WidgetStatePropertyAll<Size>(Size(48, 48)),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: _busy ? null : _confirm,
            child: _busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Remove'),
          ),
        ),
      ],
    );
  }
}

/// Shows the confirm-remove dialog and returns true when the operator
/// confirms (after [onConfirm] completes); false on cancel/dismiss.
Future<bool> showConfirmRemoveSystemDialog(
  BuildContext context, {
  required String systemName,
  required Future<void> Function() onConfirm,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => ConfirmRemoveSystemDialog(
      systemName: systemName,
      onConfirm: onConfirm,
    ),
  );
  return confirmed ?? false;
}
