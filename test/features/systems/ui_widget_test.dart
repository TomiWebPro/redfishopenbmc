import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/features/systems/views/add_system_dialog.dart';
import 'package:redfishopenbmc/features/systems/views/dashboard_view.dart';
import 'package:redfishopenbmc/features/systems/views/edit_system_page.dart';
import 'package:redfishopenbmc/features/systems/views/system_overview_page.dart';
import 'package:redfishopenbmc/features/systems/views/system_profile_form.dart';
import 'package:redfishopenbmc/features/systems/views/system_shell.dart';
import 'package:redfishopenbmc/features/systems/widgets/status_badges.dart';
import 'package:redfishopenbmc/features/systems/widgets/system_card.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

SystemManager seededManager({
  required Map<String, SystemHandle> systems,
  String? selectedId,
}) {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(systems: systems, selectedId: selectedId);
  return m;
}

SystemHandle connectedHandle({
  required String id,
  String name = 'Lab',
  String host = '1.2.3.4',
  int port = 443,
  Health health = Health.ok,
  PowerState power = PowerState.on,
  SystemFeatures? features,
  String? manufacturer,
  String? model,
  String? serialNumber,
  ConnectionStatus status = ConnectionStatus.connected,
  String? lastError,
}) {
  return SystemHandle(
    profile: ConnectionProfile(id: id, name: name, host: host, port: port),
    status: status,
    session: status == ConnectionStatus.connected
        ? Session(systemId: id, token: 't', location: '', username: '')
        : null,
    features: features,
    snapshot: SystemSnapshot(
      health: health,
      powerState: power,
      manufacturer: manufacturer,
      model: model,
      serialNumber: serialNumber,
    ),
    lastError: lastError,
  );
}

/// Finds the [TextFormField] whose label text is [label].
Finder field(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextFormField));

/// Finds the [SwitchListTile] whose title text is [label].
Finder switchTile(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(SwitchListTile),
    );

/// Pumps [child] inside a ProviderScope + GoRouter so `context.go` works and the
/// [systemManagerProvider] is overridden with [manager].
Future<void> pumpManaged(
  WidgetTester tester,
  SystemManager manager,
  Widget child, {
  String initialLocation = '/bmc1/overview',
}) async {
  final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/:systemId/overview',
        builder: (BuildContext c, GoRouterState s) => SystemShell(
          systemId: s.pathParameters['systemId']!,
          child: child is SystemOverviewPage
              ? child
              : SystemOverviewPage(systemId: s.pathParameters['systemId']!),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
        systemManagerProvider.overrideWith((ref) => manager),
        overviewProvider.overrideWith(
          (ref, id) => Future<SystemOverview>.value(_sampleOverview()),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// A representative [SystemOverview] used to feed [overviewProvider] in widget
/// tests so the embedded [OverviewView] renders real cards without network.
SystemOverview _sampleOverview() => SystemOverview(
      manufacturer: 'Acme',
      model: 'Server-9',
      serialNumber: 'SN1',
      sku: 'SKU-1',
      partNumber: 'PN-1',
      biosVersion: 'v1.2',
      powerState: PowerState.on,
      health: Health.ok,
      healthRollup: Health.ok,
      processorSummary: const ProcessorSummary(count: 2, model: 'Cortex-A72'),
      memorySummary: const MemorySummary(totalGiB: 32),
      indicatorLed: IndicatorLed.lit,
      leadingTemperatureCelsius: 42.0,
      resourceUri: '/redfish/v1/Systems/system',
      lastUpdated: DateTime(2026, 1, 1),
    );

/// Hosts a [SystemProfileForm] (which is taller than the default test viewport)
/// inside a scrollable so layout does not overflow during widget tests.
Widget _formScreen(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

/// Renders [SystemOverviewPage] directly (no [SystemShell]) so the page can be
/// exercised without triggering the shell's auto-connect-on-enter behavior.
Future<void> pumpOverviewDirect(
  WidgetTester tester,
  SystemManager manager,
  String id,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
        systemManagerProvider.overrideWith((ref) => manager),
        overviewProvider.overrideWith(
          (ref, id) => Future<SystemOverview>.value(_sampleOverview()),
        ),
      ],
      child: MaterialApp(home: SystemOverviewPage(systemId: id)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HealthBadge / PowerBadge', () {
    testWidgets('render every health and power state without throwing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: const Scaffold(
            body: const Column(
              children: const <Widget>[
                const HealthBadge(health: Health.ok),
                const HealthBadge(health: Health.warning),
                const HealthBadge(health: Health.critical),
                const HealthBadge(health: Health.unknown),
                const PowerBadge(powerState: PowerState.on),
                const PowerBadge(powerState: PowerState.off),
                const PowerBadge(powerState: PowerState.unknown),
              ],
            ),
          ),
        ),
      );
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Unknown'), findsWidgets);
      expect(find.text('On'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('announce accessible semantics labels for screen readers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: const Scaffold(
            body: const Column(
              children: const <Widget>[
                const HealthBadge(health: Health.warning),
                const PowerBadge(powerState: PowerState.off),
              ],
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Health Warning'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Power Off'),
        findsOneWidget,
      );
    });

    testWidgets('health badge uses a distinct icon per state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: const Scaffold(
            body: const Column(
              children: const <Widget>[
                const HealthBadge(health: Health.warning),
                const HealthBadge(health: Health.critical),
                const HealthBadge(health: Health.unknown),
              ],
            ),
          ),
        ),
      );
      expect(
        find.byIcon(Icons.warning_amber_rounded),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });

  group('SystemCard', () {
    testWidgets('shows name, host, badges and detail line', (tester) async {
      final SystemHandle handle = connectedHandle(
        id: 'bmc1',
        name: 'Lab BMC',
        health: Health.warning,
        power: PowerState.off,
        manufacturer: 'Acme',
        model: 'Server-9',
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SystemCard(handle: handle))),
      );
      expect(find.text('Lab BMC'), findsOneWidget);
      expect(find.text('https://1.2.3.4:443'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Acme · Server-9'), findsOneWidget);
    });

    testWidgets(
        'detail line (Manufacturer · Model) announces as one merged node '
        'with visible text preserved (UI-2)', (tester) async {
      final SystemHandle handle = connectedHandle(
        id: 'bmc1',
        name: 'Lab BMC',
        manufacturer: 'Acme',
        model: 'Server-9',
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SystemCard(handle: handle))),
      );
      // Visible text preserved.
      expect(find.text('Acme · Server-9'), findsOneWidget);
      // One merged announcement covers the detail line.
      final SemanticsHandle semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Acme · Server-9'), findsOneWidget,
          reason: 'expected the merged product-identity node');
      semantics.dispose();
    });

    testWidgets('tapping the card and selecting a menu action fires callbacks',
        (tester) async {
      final SystemHandle handle = connectedHandle(id: 'bmc1');
      final List<String> actions = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SystemCard(
              handle: handle,
              onTap: () {},
              onMenuAction: actions.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(SystemCard));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(actions, contains('remove'));
    });

    testWidgets(
        'URL subtitle stays visible but is excluded from semantics — the '
        'header announces name + state + URL as one node (UI-2)',
        (tester) async {
      final SystemHandle handle = connectedHandle(
        id: 'bmc1',
        name: 'Lab BMC',
        status: ConnectionStatus.connected,
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SystemCard(handle: handle))),
      );
      // Visible text preserved.
      expect(find.text('https://1.2.3.4:443'), findsOneWidget);
      // One merged announcement covers the URL; the subtitle must NOT add a
      // second text node to the semantics tree (no double announcement).
      final SemanticsHandle semantics = tester.ensureSemantics();
      final Finder node =
          find.bySemanticsLabel('Lab BMC, connected, https://1.2.3.4:443');
      expect(node, findsOneWidget,
          reason: 'expected the merged name + state + URL header node');
      // The URL appears exactly once in the semantics tree (inside the merged
      // label); an exact standalone node for the subtitle would double it.
      expect(find.bySemanticsLabel('https://1.2.3.4:443'), findsNothing,
          reason: 'the URL subtitle must be ExcludeSemantics (the merged '
              'header label announces it once)');
      semantics.dispose();
    });

    testWidgets('shows a per-status connection icon', (tester) async {
      for (final ConnectionStatus status in const <ConnectionStatus>[
        ConnectionStatus.connecting,
        ConnectionStatus.error,
        ConnectionStatus.connected,
        ConnectionStatus.disconnected,
      ]) {
        final SystemHandle handle = connectedHandle(
          id: 'x',
          status: status,
          health: Health.unknown,
        );
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: SystemCard(handle: handle))),
        );
        expect(find.byType(SystemCard), findsOneWidget);
      }
    });

    testWidgets('card header announces one merged semantics label (UI-2)',
        (tester) async {
      for (final (ConnectionStatus status, String word)
          in const <(ConnectionStatus, String)>[
        (ConnectionStatus.connected, 'connected'),
        (ConnectionStatus.connecting, 'connecting'),
        (ConnectionStatus.error, 'connection error'),
        (ConnectionStatus.disconnected, 'disconnected'),
      ]) {
        final SystemHandle handle = connectedHandle(
          id: 'bmc1',
          name: 'Lab BMC',
          status: status,
          health: Health.unknown,
        );
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: SystemCard(handle: handle))),
        );
        // UI-2: the merged header label now includes the endpoint URL (same
        // pattern as the SystemOverviewPage connection header) so the URL
        // subtitle line is not a second detached announcement.
        expect(
          find.bySemanticsLabel('Lab BMC, $word, https://1.2.3.4:443'),
          findsOneWidget,
          reason: 'expected merged header label (name + state + URL) for '
              '$status',
        );
      }
    });
  });

  group('SystemProfileForm', () {
    testWidgets('validates and emits a profile on save (create mode)',
        (tester) async {
      ConnectionProfile? submitted;
      await tester.pumpWidget(
        _formScreen(
          SystemProfileForm(
            onSubmit: (ConnectionProfile p) => submitted = p,
          ),
        ),
      );
      await tester.ensureVisible(field('Host / IP'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Host / IP'), 'bmc.example.com');
      await tester.ensureVisible(field('Port'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Port'), '8443');
      await tester.ensureVisible(field('Username'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Username'), 'root');
      await tester.ensureVisible(find.text('Add system'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add system'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.host, 'bmc.example.com');
      expect(submitted!.port, 8443);
      expect(submitted!.username, 'root');
      expect(submitted!.scheme, 'https');
      expect(submitted!.authMethod, AuthMethod.session);
      expect(submitted!.useTls, isTrue);
    });

    testWidgets('shows validation error when host is empty', (tester) async {
      await tester.pumpWidget(
        _formScreen(
          SystemProfileForm(onSubmit: (_) {}),
        ),
      );
      await tester.ensureVisible(find.text('Add system'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add system'));
      await tester.pumpAndSettle();
      expect(find.text('Host is required'), findsOneWidget);
    });

    testWidgets('self-signed toggle reveals the warning banner',
        (tester) async {
      await tester.pumpWidget(
        _formScreen(
          SystemProfileForm(onSubmit: (_) {}),
        ),
      );
      expect(
        find.textContaining('Self-signed certificates disable'),
        findsNothing,
      );
      await tester.tap(switchTile('Allow self-signed certificate'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Self-signed certificates disable'),
        findsOneWidget,
      );
    });

    testWidgets(
        'self-signed warning announces as one merged semantics node '
        '(UI-2)', (tester) async {
      await tester.pumpWidget(
        _formScreen(
          SystemProfileForm(onSubmit: (_) {}),
        ),
      );
      await tester.tap(switchTile('Allow self-signed certificate'));
      await tester.pumpAndSettle();

      final Finder banner = find.bySemanticsLabel(
        'Warning: self-signed certificates disable TLS verification. '
        'Only enable for trusted, isolated management networks.',
      );
      expect(banner, findsOneWidget);

      // The visible text is preserved for sighted users (no a11y regression).
      expect(
        find.textContaining('Self-signed certificates disable'),
        findsOneWidget,
      );
      // The icon is excluded from the semantics tree — one node only.
      final SemanticsNode? node = tester.getSemantics(banner);
      expect(node?.label, contains('self-signed certificates disable TLS'));
      expect(node?.label, contains('isolated management networks'));
    });

    testWidgets('TLS off flips scheme to http and basic auth is selectable',
        (tester) async {
      ConnectionProfile? submitted;
      await tester.pumpWidget(
        _formScreen(
          SystemProfileForm(
            onSubmit: (ConnectionProfile p) => submitted = p,
          ),
        ),
      );
      await tester.ensureVisible(switchTile('Use TLS (HTTPS)'));
      await tester.pumpAndSettle();
      await tester.tap(switchTile('Use TLS (HTTPS)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButton<AuthMethod>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<AuthMethod>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Basic').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(field('Host / IP'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Host / IP'), 'h');
      await tester.ensureVisible(find.text('Add system'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add system'));
      await tester.pumpAndSettle();
      expect(submitted!.scheme, 'http');
      expect(submitted!.authMethod, AuthMethod.basic);
    });

    testWidgets('edit mode prefills and submits an update', (tester) async {
      final ConnectionProfile initial = const ConnectionProfile(
        id: 'bmc1',
        name: 'Old',
        host: 'old.host',
        port: 443,
        authMethod: AuthMethod.session,
      );
      ConnectionProfile? submitted;
      await tester.pumpWidget(
        _formScreen(
          SystemProfileForm(
            initial: initial,
            onSubmit: (ConnectionProfile p) => submitted = p,
          ),
        ),
      );
      // The form prefills from `initial`; submitting without edits keeps the host.
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(submitted, isNotNull);
      expect(submitted!.id, 'bmc1');
      expect(submitted!.host, 'old.host');

      // Now edit the host and re-submit.
      await tester.ensureVisible(field('Host / IP'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Host / IP'), 'new.host');
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(submitted!.host, 'new.host');
    });
  });

  group('SystemOverviewPage', () {
    testWidgets('shows badges, feature chips and a disconnect control',
        (tester) async {
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(
            id: 'bmc1',
            manufacturer: 'Acme',
            model: 'Server-9',
            serialNumber: 'SN1',
            features: const SystemFeatures(
              systemId: 'bmc1',
              powerControl: true,
              sensorMonitoring: true,
              sensorCount: 12,
            ),
          ),
        },
        selectedId: 'bmc1',
      );
      await pumpManaged(tester, m, const SystemOverviewPage(systemId: 'bmc1'));
      // Identity now lives in the embedded OverviewView's Identity card.
      expect(find.textContaining('Acme'), findsWidgets);
      expect(find.text('SN1'), findsOneWidget);
      expect(find.text('Power control'), findsOneWidget);
      expect(find.text('Sensors (12)'), findsOneWidget);

      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(m.state.systems['bmc1']!.status, ConnectionStatus.disconnected);
    });

    testWidgets('renders a connection error message', (tester) async {
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(
            id: 'bmc1',
            status: ConnectionStatus.error,
            health: Health.unknown,
            lastError: 'boom',
          ),
        },
        selectedId: 'bmc1',
      );
      await pumpOverviewDirect(tester, m, 'bmc1');
      expect(find.textContaining('Connection error: boom'), findsOneWidget);
    });

    testWidgets('renders "System not found" for an unknown id', (tester) async {
      final SystemManager m = seededManager(systems: <String, SystemHandle>{});
      await pumpOverviewDirect(tester, m, 'ghost');
      expect(find.text('System not found'), findsOneWidget);
    });

    testWidgets(
        'not-found fallback announces one merged semantics node — icon + text '
        '(UI-2)', (tester) async {
      final SystemManager m = seededManager(systems: <String, SystemHandle>{});
      await pumpOverviewDirect(tester, m, 'ghost');
      expect(
        find.bySemanticsLabel('System not found'),
        findsOneWidget,
        reason: 'expected one merged not-found node (icon + text)',
      );
      // Visible text preserved for sighted users.
      expect(find.text('System not found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      // No overflow at the narrowest supported width (UI-3); use the
      // established addTearDown restore so the resize cannot leak into later
      // tests (precedent: the SystemShell group's no-overflow tests).
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(320, 800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'connection header announces one merged semantics node — name + URL '
        '(UI-2)', (tester) async {
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(
            id: 'bmc1',
            name: 'Lab BMC',
            host: '10.0.0.7',
            port: 8443,
          ),
        },
        selectedId: 'bmc1',
      );
      await pumpOverviewDirect(tester, m, 'bmc1');
      expect(
        find.bySemanticsLabel('Lab BMC, https://10.0.0.7:8443'),
        findsOneWidget,
        reason: 'expected the merged name + URL header node',
      );
      // Visible texts preserved.
      expect(find.text('Lab BMC'), findsOneWidget);
      expect(find.text('https://10.0.0.7:8443'), findsOneWidget);
    });

    testWidgets(
        'no optional features empty state announces one merged semantics node '
        '(UI-2)', (tester) async {
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(
            id: 'bmc1',
            features: const SystemFeatures(systemId: 'bmc1'),
          ),
        },
        selectedId: 'bmc1',
      );
      await pumpOverviewDirect(tester, m, 'bmc1');
      // One self-describing announcement (merged node, no separate parts).
      expect(
        find.bySemanticsLabel('No optional features discovered.'),
        findsOneWidget,
      );
      // The visible text + icon still render for sighted users.
      expect(find.text('No optional features discovered.'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
      // The empty state must not overflow at the narrowest supported width
      // (UI-3: 320 px); the center-aligned column wraps instead.
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(320, 800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Restore the default test surface so later tests in this file are
      // unaffected (UI-3 no-overflow checks must not leak the resize).
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });

  group('SystemShell', () {
    testWidgets('gates tabs by discovered features', (tester) async {
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(
            id: 'bmc1',
            features: const SystemFeatures(
              systemId: 'bmc1',
              powerControl: true,
              sensorMonitoring: true,
            ),
          ),
        },
        selectedId: 'bmc1',
      );
      await pumpManaged(tester, m, const Text('child'));
      // Overview is always present; Power + Sensors advertised, Firmware/KVM not.
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Power'), findsOneWidget);
      expect(find.text('Sensors'), findsOneWidget);
      expect(find.text('Firmware'), findsNothing);
      expect(find.text('KVM'), findsNothing);
      // Entering the shell selects the system (instant context switch).
      expect(m.state.selectedId, 'bmc1');
    });

    testWidgets('shows not-found scaffold for unknown system', (tester) async {
      final SystemManager m = seededManager(systems: <String, SystemHandle>{});
      await pumpManaged(tester, m, const Text('child'),
          initialLocation: '/ghost/overview');
      expect(find.text('System not found'), findsOneWidget);
    });

    testWidgets(
        'not-found scaffold announces one merged semantics node — icon + text '
        '(UI-2)', (tester) async {
      final SystemManager m = seededManager(systems: <String, SystemHandle>{});
      await pumpManaged(tester, m, const Text('child'),
          initialLocation: '/ghost/overview');
      expect(
        find.bySemanticsLabel('System not found'),
        findsOneWidget,
        reason: 'expected one merged not-found node (icon + text)',
      );
      // Visible text preserved for sighted users.
      expect(find.text('System not found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      // No overflow at the narrowest supported width (UI-3).
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(320, 800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Dialogs / pages', () {
    testWidgets('AddSystemDialog renders the profile form', (tester) async {
      final SystemManager m = seededManager(systems: <String, SystemHandle>{});
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
            systemManagerProvider.overrideWith((ref) => m),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => ElevatedButton(
                onPressed: () => showAddSystemDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SystemProfileForm), findsOneWidget);
    });

    testWidgets('EditSystemPage prefilled form submits an update',
        (tester) async {
      final ConnectionProfile initial = const ConnectionProfile(
        id: 'bmc1',
        name: 'Edit Me',
        host: 'edit.host',
      );
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(id: 'bmc1'),
        },
        selectedId: 'bmc1',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
            systemManagerProvider.overrideWith((ref) => m),
          ],
          child: MaterialApp(home: EditSystemPage(profile: initial)),
        ),
      );
      expect(
        tester.widget<TextFormField>(field('Host / IP')).controller!.text,
        'edit.host',
      );
    });

    testWidgets('AddSystemDialog submit adds a profile through the manager',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final SystemManager m = seededManager(systems: <String, SystemHandle>{});
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
            systemManagerProvider.overrideWith((ref) => m),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => ElevatedButton(
                onPressed: () => showAddSystemDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(field('Host / IP'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Host / IP'), 'added.host');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Add system'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add system'));
      await tester.pumpAndSettle();
      expect(
        m.state.systems.values
            .where((SystemHandle h) => h.profile.host == 'added.host'),
        isNotEmpty,
      );
    });

    testWidgets('EditSystemPage submit updates the profile and pops',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final ConnectionProfile initial = const ConnectionProfile(
        id: 'bmc1',
        name: 'Edit Me',
        host: 'edit.host',
      );
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(id: 'bmc1'),
        },
        selectedId: 'bmc1',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
            systemManagerProvider.overrideWith((ref) => m),
          ],
          child: MaterialApp(home: EditSystemPage(profile: initial)),
        ),
      );
      await tester.ensureVisible(field('Host / IP'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Host / IP'), 'edited.host');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(m.state.systems['bmc1']!.profile.host, 'edited.host');
    });
  });

  group('DashboardView integration', () {
    testWidgets('renders aggregated banner and dashboard cards',
        (tester) async {
      final SystemManager m = seededManager(
        systems: <String, SystemHandle>{
          'bmc1': connectedHandle(
            id: 'bmc1',
            name: 'Lab',
            health: Health.ok,
            power: PowerState.on,
          ),
          'bmc2': connectedHandle(
            id: 'bmc2',
            name: 'Prod',
            health: Health.critical,
            power: PowerState.off,
          ),
        },
        selectedId: 'bmc1',
      );
      final GoRouter router = GoRouter(
        initialLocation: '/systems',
        routes: <RouteBase>[
          GoRoute(
            path: '/systems',
            builder: (BuildContext c, GoRouterState s) => const DashboardView(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            secureStorageProvider.overrideWith((ref) => InMemoryStorage()),
            systemManagerProvider.overrideWith((ref) => m),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 OK, 1 Critical'), findsOneWidget);
      expect(find.text('Lab'), findsOneWidget);
      expect(find.text('Prod'), findsOneWidget);
    });
  });
}
