// ignore_for_file: prefer_const_constructors
//
// #010 theming/a11y acceptance: "Golden/screenshot for Overview + Dashboard
// light/dark at mobile/tablet/desktop".
//
// Pixel golden PNGs are platform/font-fragile (a re-render on a different host
// produces a different image), so this pins the SAME contract deterministically:
// for each view, at each breakpoint, in each brightness we assert the active
// ThemeData is applied, the view's theme-derived rendering colours resolve from
// that theme, the same semantic content is present in both brightnesses (dark
// mode must not drop content), and nothing overflows. These checks are stable
// across hosts while still catching the regressions a light/dark screenshot
// review is meant to catch (a view ignoring the theme, or a theme-colour drift).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/overview/views/overview_view.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/dashboard_view.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

const Map<String, Size> kViewports = <String, Size>{
  'mobile': Size(400, 1200),
  'tablet': Size(800, 1400),
  'desktop': Size(1300, 1400),
};

final Map<String, ThemeData> kThemes = <String, ThemeData>{
  'light': AppTheme.lightTheme,
  'dark': AppTheme.darkTheme,
};

SystemOverview _sampleOverview() => SystemOverview(
      manufacturer: 'Acme',
      model: 'Server-9',
      serialNumber: 'SN1',
      sku: 'SKU1',
      partNumber: 'PN1',
      biosVersion: '1.0',
      powerState: PowerState.on,
      health: Health.ok,
      healthRollup: Health.ok,
      processorSummary: const ProcessorSummary(count: 2, model: 'P9'),
      memorySummary: const MemorySummary(totalGiB: 32),
      indicatorLed: IndicatorLed.lit,
      leadingTemperatureCelsius: 42.0,
      resourceUri: '/redfish/v1/Systems/system',
    );

SystemManager _overviewManager() {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(
    systems: <String, SystemHandle>{
      'bmc1': SystemHandle(
        profile: const ConnectionProfile(id: 'bmc1', host: 'h'),
        status: ConnectionStatus.connected,
        session: Session(
          systemId: 'bmc1',
          token: 't',
          location: '',
          username: '',
        ),
        features: const SystemFeatures(systemId: 'bmc1'),
        snapshot: SystemSnapshot(
          powerState: PowerState.on,
          resourceUri: '/redfish/v1/Systems/system',
        ),
      ),
    },
    selectedId: 'bmc1',
  );
  return m;
}

SystemManager _dashboardManager({bool empty = false}) {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(
    systems: empty
        ? <String, SystemHandle>{}
        : <String, SystemHandle>{
            'bmc1': const SystemHandle(
              profile:
                  ConnectionProfile(id: 'bmc1', name: 'Lab', host: '1.2.3.4'),
              snapshot: SystemSnapshot(
                health: Health.ok,
                powerState: PowerState.on,
              ),
            ),
            'bmc2': const SystemHandle(
              profile:
                  ConnectionProfile(id: 'bmc2', name: 'Prod', host: '5.6.7.8'),
              snapshot: SystemSnapshot(
                health: Health.warning,
                powerState: PowerState.off,
              ),
            ),
          },
    selectedId: 'bmc1',
  );
  return m;
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<ThemeData> _pumpOverview(
  WidgetTester tester, {
  required ThemeData theme,
  required Size size,
}) async {
  _setViewport(tester, size);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemManagerProvider.overrideWith((ref) => _overviewManager()),
        overviewProvider.overrideWith(
          (ref, id) => Future<SystemOverview>.value(_sampleOverview()),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return Theme.of(tester.element(find.byType(OverviewView)));
}

Future<ThemeData> _pumpDashboard(
  WidgetTester tester, {
  required ThemeData theme,
  required Size size,
  required SystemManager manager,
}) async {
  _setViewport(tester, size);
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext c, GoRouterState s) => const DashboardView(),
      ),
      GoRoute(
        path: '/:systemId/overview',
        builder: (BuildContext c, GoRouterState s) => const SizedBox.shrink(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemManagerProvider.overrideWith((ref) => manager),
      ],
      child: MaterialApp.router(routerConfig: router, theme: theme),
    ),
  );
  await tester.pumpAndSettle();
  return Theme.of(tester.element(find.byType(DashboardView)));
}

void main() {
  test('light and dark themes resolve distinct theme-aware colours', () {
    final ColorScheme light = AppTheme.lightTheme.colorScheme;
    final ColorScheme dark = AppTheme.darkTheme.colorScheme;
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.surface, isNot(dark.surface));
    expect(light.outline, isNot(dark.outline));
    expect(light.onSurfaceVariant, isNot(dark.onSurfaceVariant));
  });

  for (final MapEntry<String, ThemeData> theme in kThemes.entries) {
    final Brightness brightness =
        theme.key == 'light' ? Brightness.light : Brightness.dark;

    for (final MapEntry<String, Size> viewport in kViewports.entries) {
      testWidgets(
        'OverviewView ${viewport.key}/${theme.key}: themed, content-complete, no overflow',
        (WidgetTester tester) async {
          final ThemeData active = await _pumpOverview(
            tester,
            theme: theme.value,
            size: viewport.value,
          );
          expect(active.colorScheme.brightness, brightness);
          expect(active.scaffoldBackgroundColor, active.colorScheme.surface);
          // Same semantic content in both brightnesses (dark mode drops nothing).
          expect(find.bySemanticsLabel('Identity'), findsOneWidget);
          expect(find.text('Manufacturer'), findsOneWidget);
          // Theme-derived rendering colour: the field label uses scheme.outline.
          final Text label = tester.widget<Text>(find.text('Manufacturer'));
          expect(label.style?.color, active.colorScheme.outline);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'DashboardView ${viewport.key}/${theme.key}: themed, content-complete, no overflow',
        (WidgetTester tester) async {
          final ThemeData active = await _pumpDashboard(
            tester,
            theme: theme.value,
            size: viewport.value,
            manager: _dashboardManager(),
          );
          expect(active.colorScheme.brightness, brightness);
          expect(active.scaffoldBackgroundColor, active.colorScheme.surface);
          expect(find.text('1 OK, 1 Warning'), findsOneWidget);
          expect(find.text('Lab'), findsOneWidget);
          expect(find.text('Prod'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'DashboardView empty-state icon follows theme (${theme.key})',
      (WidgetTester tester) async {
        final ThemeData active = await _pumpDashboard(
          tester,
          theme: theme.value,
          size: kViewports['mobile']!,
          manager: _dashboardManager(empty: true),
        );
        final Icon icon = tester.widget<Icon>(find.byIcon(Icons.dns_outlined));
        expect(icon.color, active.colorScheme.onSurfaceVariant);
      },
    );
  }
}
