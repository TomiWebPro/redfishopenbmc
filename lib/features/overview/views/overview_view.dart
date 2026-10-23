import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/core/theme/breakpoints.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/overview/widgets/health_banner.dart';
import 'package:redfishopenbmc/features/overview/widgets/info_card.dart';
import 'package:redfishopenbmc/features/overview/widgets/skeleton_card.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/widgets/status_badges.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Per-system overview tab content (issue #006).
///
/// Renders a schema-driven, adaptive card layout: a [HealthBanner] + [PowerBadge]
/// header followed by [InfoCard]s for identity, processors, memory, (optional)
/// temperatures and the indicator LED. Missing fields are either omitted (the
/// temperature card) or show "Not exposed by this BMC" — the view never crashes
/// on `null`/missing Redfish members.
///
/// Data is sourced from [overviewProvider]; the view adds pull-to-refresh, a
/// 30s auto-poll, and a refresh whenever the system's power state changes.
class OverviewView extends ConsumerStatefulWidget {
  /// Creates an [OverviewView] for [systemId].
  const OverviewView({required this.systemId, super.key});

  /// System id whose overview is displayed.
  final String systemId;

  @override
  ConsumerState<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends ConsumerState<OverviewView> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30s while the view is mounted and visible.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refresh();
    });

    // Refresh the overview when the system's power state changes (e.g. after a
    // reset in the Power tab) so the badge + health stay in sync without a
    // manual pull. Tracked against the last known state to avoid refresh loops.
    PowerState? lastPower =
        ref.read(systemHandleProvider(widget.systemId))?.snapshot?.powerState;
    ref.listenManual(systemHandleProvider(widget.systemId),
        (_, SystemHandle? next) {
      final PowerState? p = next?.snapshot?.powerState;
      if (p != null && p != lastPower) {
        lastPower = p;
        _refresh();
      }
    });
  }

  Future<void> _refresh() async {
    // Drop the cached overview so the provider re-fetches on next read.
    ref.invalidate(overviewProvider(widget.systemId));
    // Keep the aggregate SystemHandle snapshot fresh (dashboard health, etc.).
    await ref
        .read(systemManagerProvider.notifier)
        .refreshSnapshot(widget.systemId);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SystemOverview> state =
        ref.watch(overviewProvider(widget.systemId));
    return _buildBody(context, state);
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<SystemOverview> state,
  ) {
    return state.when(
      loading: () => _scrollable(context, <Widget>[
        SliverToBoxAdapter(child: _header(context, null)),
        SliverToBoxAdapter(child: _loadingGrid(context)),
      ]),
      error: (Object e, _) => _scrollable(context, <Widget>[
        SliverToBoxAdapter(child: _header(context, null)),
        SliverToBoxAdapter(child: _errorState(context, e)),
      ]),
      data: (SystemOverview o) => _scrollable(context, <Widget>[
        SliverToBoxAdapter(child: _header(context, o)),
        SliverToBoxAdapter(child: _dataGrid(context, o)),
      ]),
    );
  }

  Widget _scrollable(BuildContext context, List<Widget> slivers) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  Widget _header(BuildContext context, SystemOverview? o) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              HealthBanner(health: o?.health ?? Health.unknown),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PowerBadge(powerState: o?.powerState ?? PowerState.unknown),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final int cols =
            OverviewGridBreakpoints.columnsForWidth(constraints.maxWidth);
        if (cols == 1) {
          // Single column: stack natural-height skeletons (same rationale as
          // _dataGrid — a fixed-ratio grid cell squeezes the content).
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(
                5,
                (int i) => Padding(
                  padding: EdgeInsets.only(bottom: i == 4 ? 0 : 12),
                  child: const SkeletonCard(),
                ),
              ),
            ),
          );
        }
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: List<Widget>.generate(5, (_) => const SkeletonCard()),
        );
      },
    );
  }

  Widget _dataGrid(BuildContext context, SystemOverview o) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final int cols =
            OverviewGridBreakpoints.columnsForWidth(constraints.maxWidth);
        if (cols == 1) {
          // Single column: stack natural-height cards. A fixed `childAspectRatio`
          // grid cell would force a ~288 px square at 320 px viewports and
          // overflow for taller cards such as Identity (UI-3 found 48 px).
          final List<Widget> cards = _cards(context, o);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < cards.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 12),
                  cards[i],
                ],
              ],
            ),
          );
        }
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: _cards(context, o),
        );
      },
    );
  }

  List<Widget> _cards(BuildContext context, SystemOverview o) {
    return <Widget>[
      InfoCard(
        title: 'Identity',
        icon: Icons.badge_outlined,
        child: _identity(context, o),
      ),
      InfoCard(
        title: 'Processors',
        icon: Icons.memory_outlined,
        child: _processors(context, o),
      ),
      InfoCard(
        title: 'Memory',
        icon: Icons.storage_outlined,
        child: _memory(context, o),
      ),
      if (o.hasTemperature)
        InfoCard(
          title: 'Temperatures',
          icon: Icons.thermostat_outlined,
          child: _temperature(context, o),
        ),
      InfoCard(
        title: 'Indicator LED',
        icon: Icons.lightbulb_outline,
        child: _led(context, o),
      ),
    ];
  }

  Widget _identity(BuildContext context, SystemOverview o) {
    final List<Widget> rows = <Widget>[];
    void add(String label, String? value) =>
        rows.add(_kv(context, label, value));
    add('Manufacturer', o.manufacturer);
    add('Model', o.model);
    add('Serial', o.serialNumber);
    add('SKU', o.sku);
    add('Part', o.partNumber);
    add('BIOS', o.biosVersion);
    if (rows.isEmpty) return const NotExposed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _kv(BuildContext context, String label, String? value) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 2),
          value == null
              ? const NotExposed()
              : Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _processors(BuildContext context, SystemOverview o) {
    if (!o.hasProcessors) return const NotExposed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (o.processorSummary.count != null)
          Text(
            '${o.processorSummary.count} processor(s)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (o.processorSummary.model != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            o.processorSummary.model!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _memory(BuildContext context, SystemOverview o) {
    if (!o.hasMemory) return const NotExposed();
    final double gib = o.memorySummary.totalGiB!;
    final String text = gib == gib.roundToDouble()
        ? gib.round().toString()
        : gib.toStringAsFixed(1);
    return Text(
      '$text GiB',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _temperature(BuildContext context, SystemOverview o) {
    return Text(
      '${o.leadingTemperatureCelsius!.toStringAsFixed(1)} °C',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _led(BuildContext context, SystemOverview o) {
    if (o.indicatorLed == IndicatorLed.unknown) return const NotExposed();
    return Text(
      o.indicatorLed.label,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _errorState(BuildContext context, Object e) {
    final String message = e is RedfishException ? e.message : e.toString();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // UI-2: the icon + title + detail announce as ONE node, so a
            // screen reader gets the error in context instead of a bare icon
            // plus detached sentences (the established error-state pattern).
            // The Retry button keeps its own node (it is a control).
            Semantics(
              container: true,
              excludeSemantics: true,
              label: 'Unable to load overview. $message',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.cloud_off_outlined,
                      size: 40, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
