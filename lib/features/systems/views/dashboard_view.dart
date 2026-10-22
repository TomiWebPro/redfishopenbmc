import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/add_system_dialog.dart';
import 'package:redfishopenbmc/features/systems/views/edit_system_page.dart';
import 'package:redfishopenbmc/features/systems/widgets/system_card.dart';

/// Aggregated multi-system dashboard.
///
/// Shows a header banner summarizing overall health (`2 OK, 1 Warning`) and a
/// responsive grid of [SystemCard]s (1 / 2 / 3 columns at mobile / tablet /
/// desktop). Tapping a card performs an instant context switch into that
/// system; the card menu supports connect / disconnect / edit / remove.
class DashboardView extends ConsumerWidget {
  /// Creates a [DashboardView].
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SystemState state = ref.watch(systemManagerProvider);
    final SystemManager manager = ref.read(systemManagerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Systems'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add system',
            onPressed: () => showAddSystemDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => manager.connectAll(),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _AggregatedBanner(state: state)),
            if (state.systems.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No systems yet. Tap + to add a BMC.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: _systemGrid(state, manager, context),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddSystemDialog(context),
        tooltip: 'Add system',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _systemGrid(
    SystemState state,
    SystemManager manager,
    BuildContext context,
  ) {
    final List<SystemHandle> handles = state.ordered;
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints constraints) {
        final double width = constraints.crossAxisExtent;
        final int columns = width < 600
            ? 1
            : width < 1200
                ? 2
                : 3;
        // A single-column tile is far narrower than a multi-column tile, so a
        // fixed 1.6 ratio would squeeze the card content at ~320 px (UI-3 found
        // a 28 px vertical overflow). Use a taller tile for the 1-column layout.
        final double aspectRatio = columns == 1 ? 1.25 : 1.6;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final SystemHandle handle = handles[index];
              return SystemCard(
                handle: handle,
                onTap: () => _openSystem(context, manager, handle.profile.id),
                onMenuAction: (String action) => _onMenuAction(
                  context,
                  manager,
                  handle,
                  action,
                ),
              );
            },
            childCount: handles.length,
          ),
        );
      },
    );
  }

  void _openSystem(
    BuildContext context,
    SystemManager manager,
    String id,
  ) {
    manager.select(id);
    context.go('/$id/overview');
  }

  Future<void> _onMenuAction(
    BuildContext context,
    SystemManager manager,
    SystemHandle handle,
    String action,
  ) async {
    final String id = handle.profile.id;
    switch (action) {
      case 'connect':
        await manager.connect(id);
      case 'disconnect':
        await manager.disconnect(id);
      case 'edit':
        showEditSystemDialog(context, handle.profile);
      case 'remove':
        await manager.removeProfile(id);
    }
  }
}

/// Header banner summarizing aggregate health across all systems.
class _AggregatedBanner extends StatelessWidget {
  const _AggregatedBanner({required this.state});

  final SystemState state;

  @override
  Widget build(BuildContext context) {
    final AggregatedStatus agg = state.aggregated;
    final Color color = _bannerColor(context, agg);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.monitor_heart_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              agg.summary,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Color _bannerColor(BuildContext context, AggregatedStatus agg) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (agg.critical > 0) return scheme.error;
    if (agg.warning > 0) return Colors.orange;
    if (agg.total == 0) return scheme.outline;
    return scheme.primary;
  }
}
