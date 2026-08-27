import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:redfishopenbmc/features/discovery/discovery_page.dart';
import 'package:redfishopenbmc/features/firmware/firmware_page.dart';
import 'package:redfishopenbmc/features/kvm/kvm_page.dart';
import 'package:redfishopenbmc/features/power/power_page.dart';
import 'package:redfishopenbmc/features/sensors/sensors_page.dart';
import 'package:redfishopenbmc/features/systems/views/dashboard_view.dart';
import 'package:redfishopenbmc/features/systems/views/system_overview_page.dart';
import 'package:redfishopenbmc/features/systems/views/system_shell.dart';

/// Central [GoRouter] configuration.
///
/// A shell route provides an adaptive scaffold; the dashboard and discovery are
/// top-level, while each system gets its own nested shell (`/:systemId`) that
/// exposes capability-gated tabs (Overview / Power / Sensors / Firmware / KVM).
class AppRouter {
  AppRouter._();

  /// Builds the application [GoRouter] with the shell + feature routes.
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/systems',
      routes: <RouteBase>[
        ShellRoute(
          builder: (
            BuildContext context,
            GoRouterState state,
            Widget child,
          ) =>
              AppShell(child: child),
          routes: <RouteBase>[
            GoRoute(
              path: '/systems',
              name: 'systems',
              builder: (BuildContext context, GoRouterState state) =>
                  const DashboardView(),
            ),
            GoRoute(
              path: '/discovery',
              name: 'discovery',
              builder: (BuildContext context, GoRouterState state) =>
                  const DiscoveryPage(),
            ),
            ShellRoute(
              builder: (
                BuildContext context,
                GoRouterState state,
                Widget child,
              ) =>
                  SystemShell(
                systemId: state.pathParameters['systemId'] ?? '',
                child: child,
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: '/:systemId/overview',
                  builder: (BuildContext context, GoRouterState state) =>
                      SystemOverviewPage(
                    systemId: state.pathParameters['systemId'] ?? '',
                  ),
                ),
                GoRoute(
                  path: '/:systemId/power',
                  builder: (BuildContext context, GoRouterState state) =>
                      PowerPage(
                    systemId: state.pathParameters['systemId'] ?? '',
                  ),
                ),
                GoRoute(
                  path: '/:systemId/sensors',
                  builder: (BuildContext context, GoRouterState state) =>
                      const SensorsPage(),
                ),
                GoRoute(
                  path: '/:systemId/firmware',
                  builder: (BuildContext context, GoRouterState state) =>
                      const FirmwarePage(),
                ),
                GoRoute(
                  path: '/:systemId/kvm',
                  builder: (BuildContext context, GoRouterState state) =>
                      const KvmPage(),
                ),
                GoRoute(
                  path: '/:systemId',
                  redirect: (BuildContext context, GoRouterState state) =>
                      '/${state.pathParameters['systemId']}/overview',
                ),
              ],
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
    _NavItem(
      label: 'Discovery',
      icon: Icons.explore_outlined,
      path: '/discovery',
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final String loc = GoRouterState.of(context).uri.toString();
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
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1200;

        final int selected = _selectedIndex(context);

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
  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final String path;
}
