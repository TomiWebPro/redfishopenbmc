import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/overview/models/boot_settings.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/settings_controller.dart';
import 'package:redfishopenbmc/features/overview/settings_providers.dart';
import 'package:redfishopenbmc/features/overview/widgets/info_card.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Writable IndicatorLED setter shown inside the overview "Indicator LED" card
/// (issue #016 — the Boot/IndicatorLED PATCH flow).
///
/// Capability-gated: rendered only when [indicatorLed] is a known, writable
/// state (`Lit` / `Blinking` / `Off` — never `Unknown`, which the schema
/// deprecates and the service refuses to PATCH). The three schema-writable
/// states are offered as [ChoiceChip]s; the active chip tracks the last
/// applied / read state. A PATCH failure surfaces as a compact inline error.
class IndicatorLedControl extends ConsumerStatefulWidget {
  /// Creates an [IndicatorLedControl] for [systemId].
  const IndicatorLedControl({
    required this.systemId,
    required this.current,
    super.key,
  });

  /// System whose LED this control mutates.
  final String systemId;

  /// The currently-read LED state (from the overview).
  final IndicatorLed current;

  @override
  ConsumerState<IndicatorLedControl> createState() =>
      _IndicatorLedControlState();
}

class _IndicatorLedControlState extends ConsumerState<IndicatorLedControl> {
  /// Mirrors the last applied value so the chip stays in sync even before the
  /// next overview refresh.
  IndicatorLed? _lastApplied;

  @override
  Widget build(BuildContext context) {
    final SystemSettingsUiState ui =
        ref.watch(systemSettingsControllerProvider(widget.systemId));
    final IndicatorLed active =
        _lastApplied ?? ui.indicatorLed ?? widget.current;

    void select(IndicatorLed value) {
      if (ui.actionInFlight || active == value) return;
      setState(() => _lastApplied = value);
      ref
          .read(systemSettingsControllerProvider(widget.systemId).notifier)
          .setIndicatorLed(value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final IndicatorLed value in const <IndicatorLed>[
              IndicatorLed.lit,
              IndicatorLed.blinking,
              IndicatorLed.off,
            ])
              ChoiceChip(
                label: Text(value.label),
                selected: active == value,
                onSelected: ui.actionInFlight ? null : (_) => select(value),
              ),
          ],
        ),
        if (ui.actionInFlight)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (ui.error != null && !ui.actionInFlight)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              // UI-2: the inline error announces as one merged node (the
              // established inline-error pattern) so a screen reader hears the
              // whole message in context.
              container: true,
              excludeSemantics: true,
              label: 'Setting IndicatorLED failed. ${ui.error}',
              child: Text(
                ui.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Boot-override control card (issue #016 — the Boot/IndicatorLED PATCH flow).
///
/// Capability-gated on the BMC advertising `BootSourceOverrideTarget@
/// Redfish.AllowableValues`: with no annotation the service refuses to guess,
/// so the card is hidden (never a placeholder). Offers the advertised targets
/// in a dropdown + the `BootSourceOverrideEnabled` state (Once / Continuous)
/// + an Apply button; a PATCH failure surfaces as a compact inline error.
class BootOverrideCard extends ConsumerStatefulWidget {
  /// Creates a [BootOverrideCard] for [systemId].
  const BootOverrideCard({required this.systemId, super.key});

  /// System whose boot override this card mutates.
  final String systemId;

  @override
  ConsumerState<BootOverrideCard> createState() => _BootOverrideCardState();
}

class _BootOverrideCardState extends ConsumerState<BootOverrideCard> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (!mounted) return;
      ref
          .read(systemSettingsControllerProvider(widget.systemId).notifier)
          .loadBootSettings()
          .whenComplete(() {
        if (mounted) setState(() => _loading = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final SystemSettingsUiState ui =
        ref.watch(systemSettingsControllerProvider(widget.systemId));
    final BootSettings? settings = ui.bootSettings;

    // Loading: render nothing (the card appears only once we know the BMC
    // actually advertises an allow-list — "nothing is assumed").
    if (_loading && settings == null) return const SizedBox.shrink();

    // No advertised allow-list → no safe mutation → hide the card entirely.
    if (settings == null || !settings.hasAllowableTargets) {
      return const SizedBox.shrink();
    }

    return _BootOverrideForm(
      systemId: widget.systemId,
      settings: settings,
      busy: ui.actionInFlight,
      error: ui.error,
    );
  }
}

class _BootOverrideForm extends ConsumerStatefulWidget {
  const _BootOverrideForm({
    required this.systemId,
    required this.settings,
    required this.busy,
    required this.error,
  });

  final String systemId;
  final BootSettings settings;
  final bool busy;
  final String? error;

  @override
  ConsumerState<_BootOverrideForm> createState() => _BootOverrideFormState();
}

class _BootOverrideFormState extends ConsumerState<_BootOverrideForm> {
  late String _target =
      widget.settings.target ?? widget.settings.allowableTargets.first;
  late String _enabled = 'Once';

  @override
  void didUpdateWidget(covariant _BootOverrideForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the dropdown in sync when the settings refresh after an apply.
    if (!identical(oldWidget.settings, widget.settings) &&
        widget.settings.allowableTargets.isNotEmpty &&
        !widget.settings.allowableTargets.contains(_target)) {
      _target =
          widget.settings.target ?? widget.settings.allowableTargets.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: _target,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Boot source override target',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: <DropdownMenuItem<String>>[
            for (final String t in widget.settings.allowableTargets)
              DropdownMenuItem<String>(value: t, child: Text(t)),
          ],
          onChanged: widget.busy
              ? null
              : (String? value) {
                  if (value != null) setState(() => _target = value);
                },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _enabled,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Override state',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'Once',
              child: Text('Once (next boot)'),
            ),
            DropdownMenuItem<String>(
              value: 'Continuous',
              child: Text('Continuous (until cancelled)'),
            ),
          ],
          onChanged: widget.busy
              ? null
              : (String? value) {
                  if (value != null) setState(() => _enabled = value);
                },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: widget.busy
                ? null
                : () => ref
                    .read(systemSettingsControllerProvider(widget.systemId)
                        .notifier)
                    .setBootOverride(target: _target, enabled: _enabled),
            icon: widget.busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_alt),
            label: Text(widget.busy ? 'Applying…' : 'Apply boot override'),
          ),
        ),
        if (widget.error != null && !widget.busy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              // UI-2: inline error announces as one merged node.
              container: true,
              excludeSemantics: true,
              label: 'Boot override failed. ${widget.error}',
              child: Text(
                widget.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Wraps the current boot override + a hint line for the overview card.
String bootOverrideSummary(BootSettings? settings) {
  if (settings == null) return 'Not exposed by this BMC';
  if (settings.target == null) return 'Not exposed by this BMC';
  final String enabled =
      settings.enabled ?? (settings.target == null ? '' : 'enabled');
  return '${settings.target}, $enabled';
}

/// Convenience card wrapper so the overview grid stays uniform.
class SystemSettingsCard extends StatelessWidget {
  /// Creates a [SystemSettingsCard] with [title] / [icon] / [child].
  const SystemSettingsCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => InfoCard(
        title: title,
        icon: icon,
        child: child,
      );
}

/// Friendly wrapper: renders a [RedfishException] message, else the raw error.
String settingsErrorMessage(Object error) =>
    error is RedfishException ? error.message : error.toString();
