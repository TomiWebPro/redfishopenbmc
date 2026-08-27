import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:redfishopenbmc/features/discovery/discovery_page.dart';
import 'package:redfishopenbmc/features/firmware/firmware_page.dart';
import 'package:redfishopenbmc/features/kvm/kvm_page.dart';
import 'package:redfishopenbmc/features/power/power_page.dart';
import 'package:redfishopenbmc/features/sensors/sensors_page.dart';
import 'package:redfishopenbmc/features/systems/systems_page.dart';

/// Central [GoRouter] configuration.
///
/// A shell route provides an adaptive scaffold; feature tabs are rendered
/// only when discovered (future #003 gating).
class AppRouter {
  AppRouter._();

  /// Builds the application [GoRouter] with the shell + feature routes.
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/systems',
      routes: <RouteBase>[
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return AppShell(child: child);
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/systems',
              name: 'systems',
              builder: (BuildContext context, GoRouterState state) =>
                  const SystemsPage(),
            ),
            GoRoute(
              path: '/discovery',
              name: 'discovery',
              builder: (BuildContext context, GoRouterState state) =>
                  const DiscoveryPage(),
            ),
            GoRoute(
              path: '/power',
              name: 'power',
              builder: (BuildContext context, GoRouterState state) =>
                  const PowerPage(),
            ),
            GoRoute(
              path: '/sensors',
              name: 'sensors',
              builder: (BuildContext context, GoRouterState state) =>
                  const SensorsPage(),
            ),
            GoRoute(
              path: '/firmware',
              name: 'firmware',
              builder: (BuildContext context, GoRouterState state) =>
                  const FirmwarePage(),
            ),
            GoRoute(
              path: '/kvm',
              name: 'kvm',
              builder: (BuildContext context, GoRouterState state) =>
                  const KvmPage(),
            ),
          ],
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(child: Text('Route not found: ${state.uri}')),
      ),
    );
  }
}

/// Adaptive shell that switches navigation affordance by breakpoint:
/// - mobile: bottom NavigationBar
/// - tablet: NavigationRail
/// - desktop: NavigationRail + extended
class AppShell extends StatelessWidget {
  /// Creates the adaptive [AppShell] wrapping [child].
  const AppShell({required this.child, super.key});

  /// The routed feature screen rendered inside the shell.
  final Widget child;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem(label: 'Systems', icon: Icons.dns_outlined, path: '/systems'),
    _NavItem(label: 'Discovery', icon: Icons.explore_outlined, path: '/discovery'),
    _NavItem(label: 'Power', icon: Icons.power_outlined, path: '/power'),
    _NavItem(label: 'Sensors', icon: Icons.thermostat_outlined, path: '/sensors'),
    _NavItem(
      label: 'Firmware',
      icon: Icons.system_update_outlined,
      path: '/firmware',
    ),
    _NavItem(label: 'KVM', icon: Icons.computer_outlined, path: '/kvm'),
  ];

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _items.length; i++) {
      if (loc.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    context.go(_items[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1200;

        final selected = _selectedIndex(context);

        if (isMobile) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (int i) => _onTap(context, i),
              destinations: _items
                  .map(
                    (e) => NavigationDestination(
                      icon: Icon(e.icon),
                      label: e.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: <Widget>[
              NavigationRail(
                extended: !isTablet,
                selectedIndex: selected,
                onDestinationSelected: (int i) => _onTap(context, i),
                labelType: isTablet
                    ? NavigationRailLabelType.selected
                    : NavigationRailLabelType.none,
                destinations: _items
                    .map(
                      (e) => NavigationRailDestination(
                        icon: Icon(e.icon),
                        label: Text(e.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.path});
  final String label;
  final IconData icon;
  final String path;
}
