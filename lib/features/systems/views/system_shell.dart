import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A single selectable tab inside [SystemShell].
class _SystemTab {
  const _SystemTab(this.path, this.label, this.icon);

  /// Route segment appended after `/:systemId/`.
  final String path;

  /// Human-readable label.
  final String label;

  /// Icon shown in the tab bar.
  final IconData icon;
}

/// Per-system tabbed shell.
///
/// Renders inside the global [AppShell] (from `app_router.dart`). Read by the
/// inner `ShellRoute`, it shows a [TabBar] for the capability set discovered for
/// the system (Overview is always present; Power / Sensors / Firmware / KVM are
/// shown only when [SystemFeatures] advertises them). Selecting a tab navigates
/// to `/:systemId/<tab>`; entering the shell selects the system (instant
/// context switch) and lazily reconnects if needed.
class SystemShell extends ConsumerStatefulWidget {
  /// Creates a [SystemShell] for [systemId] wrapping [child].
  const SystemShell({required this.systemId, required this.child, super.key});

  /// The selected system id (from the route path parameter).
  final String systemId;

  /// The routed tab page supplied by the enclosing `ShellRoute`.
  final Widget child;

  @override
  ConsumerState<SystemShell> createState() => _SystemShellState();
}

class _SystemShellState extends ConsumerState<SystemShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  Future<void> _enter() async {
    if (!mounted) return;
    final SystemManager manager = ref.read(systemManagerProvider.notifier);
    manager.select(widget.systemId);
    final SystemHandle? handle =
        ref.read(systemManagerProvider).systems[widget.systemId];
    if (handle != null && handle.status != ConnectionStatus.connected) {
      await manager.connect(widget.systemId);
    }
  }

  List<_SystemTab> _tabsFor(SystemHandle? handle) {
    final List<_SystemTab> tabs = <_SystemTab>[
      const _SystemTab('overview', 'Overview', Icons.dashboard_outlined),
    ];
    final SystemFeatures? features = handle?.features;
    if (features?.powerControl ?? false) {
      tabs.add(const _SystemTab('power', 'Power', Icons.power_outlined));
    }
    if (features?.sensorMonitoring ?? false) {
      tabs.add(
        const _SystemTab('sensors', 'Sensors', Icons.thermostat_outlined),
      );
    }
    if (features?.firmwareUpdate ?? false) {
      tabs.add(
        const _SystemTab('firmware', 'Firmware', Icons.system_update_outlined),
      );
    }
    if (features?.kvm ?? false) {
      tabs.add(const _SystemTab('kvm', 'KVM', Icons.computer_outlined));
    }
    return tabs;
  }

  int _currentIndex(List<_SystemTab> tabs) {
    final List<String> segments = GoRouterState.of(context).uri.pathSegments;
    final String? last = segments.isNotEmpty ? segments.last : null;
    final int idx = tabs.indexWhere((t) => t.path == last);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final SystemState state = ref.watch(systemManagerProvider);
    final SystemHandle? handle = state.systems[widget.systemId];

    if (handle == null) {
      // UI-2: the shell-level not-found fallback announces as ONE
      // self-describing merged semantics node (icon + text) instead of a bare
      // detached Text — the established empty/error-state pattern (matches the
      // SystemOverviewPage fallback). No Retry: the system id does not exist in
      // the manager, there is nothing to reload.
      return Scaffold(
        appBar: AppBar(title: const Text('System')),
        body: Center(
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
        ),
      );
    }

    final List<_SystemTab> tabs = _tabsFor(handle);
    final int current = _currentIndex(tabs);

    return DefaultTabController(
      length: tabs.length,
      initialIndex: current,
      child: Scaffold(
        appBar: AppBar(
          title: Text(handle.displayName),
          bottom: TabBar(
            onTap: (int i) => context.go('/${widget.systemId}/${tabs[i].path}'),
            tabs: tabs
                .map(
                  (t) => Tab(text: t.label, icon: Icon(t.icon)),
                )
                .toList(),
          ),
        ),
        body: widget.child,
      ),
    );
  }
}
