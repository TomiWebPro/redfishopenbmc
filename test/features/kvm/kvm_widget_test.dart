import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op and whose state can be pre-seeded
/// for widget tests (avoids hitting the network from the post-frame callback).
class _StubController extends KvmController {
  _StubController()
      : super(service: KvmService(client: null, systemId: 'bmc1'));

  @override
  Future<void> load() async {}
}

/// A [KvmService] double whose console fetch always fails (error-state tests).
///
/// Records fetch calls so a test can prove the Retry affordance re-runs the
/// load through the controller's failing service instead of doing nothing.
class _FailingKvmService extends KvmService {
  _FailingKvmService() : super(client: null, systemId: 'bmc1');
  int fetchCalls = 0;
  @override
  Future<List<KvmConsole>> fetchConsoles() async {
    fetchCalls++;
    throw const RedfishException(message: 'boom');
  }
}

/// A [KvmService] double whose console fetch succeeds with zero consoles
/// (empty-state tests).
class _EmptyKvmService extends KvmService {
  _EmptyKvmService() : super(client: null, systemId: 'bmc1');
  @override
  Future<List<KvmConsole>> fetchConsoles() async => <KvmConsole>[];
}

SystemHandle _handle({required bool kvm}) => SystemHandle(
      profile: const ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: kvm),
    );

void main() {
  group('KvmView', () {
    testWidgets('renders nothing when the system has no KVM feature',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: false)),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      // The gate returns SizedBox.shrink → no console labels are rendered.
      expect(find.text('Graphical Console'), findsNothing);
    });

    testWidgets(
        'unknown system id announces one merged "System not found" node '
        '(UI-2)', (WidgetTester tester) async {
      // No handle → the fallback renders the established merged node (icon +
      // text, one self-describing announcement, no Retry).
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(null),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('System not found'), findsOneWidget);
      expect(find.text('System not found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      // 320 px no-overflow check via the addTearDown restore pattern.
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders a console card with its connect-type chip',
        (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Graphical Console'), findsOneWidget);
      expect(find.text('KVMIP'), findsOneWidget);
      expect(find.text('Manager: BMC'), findsOneWidget);
      expect(find.text('Copy connect info'), findsOneWidget);
    });

    testWidgets(
        'console card announces the connect URI as one merged semantics '
        'node (UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              connectUri: 'https://bmc.example.com:5288',
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // The label + value announce as ONE node, not two detached texts.
      expect(
        find.bySemanticsLabel('Connect URI: https://bmc.example.com:5288'),
        findsOneWidget,
        reason: 'UI-2: the connect-URI row announces one merged label',
      );
      // Visible texts are preserved for sighted users.
      expect(find.text('Connect URI:'), findsOneWidget);
      expect(find.text('https://bmc.example.com:5288'), findsOneWidget);
    });

    testWidgets(
        'console card body rows announce as one merged semantics node each '
        '(Manager / Max concurrent sessions / HTML5, UI-2)', (tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP', 'HTML5'],
              serviceEnabled: true,
              maxConcurrentSessions: 4,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // Each body row is ONE self-describing node — never a detached label
      // next to a detached value (the established card-row pattern).
      expect(
        find.bySemanticsLabel('Manager: BMC'),
        findsOneWidget,
        reason: 'UI-2: the manager line announces one merged label',
      );
      expect(
        find.bySemanticsLabel('Max concurrent sessions: 4'),
        findsOneWidget,
        reason: 'UI-2: the max-concurrent-sessions line announces one label',
      );
      expect(
        find.bySemanticsLabel('HTML5 console — open via BMC web UI.'),
        findsOneWidget,
        reason: 'UI-2: the HTML5 line announces one merged label',
      );
      // Visible texts stay for sighted users.
      expect(find.text('Manager: BMC'), findsOneWidget);
      expect(find.text('Max concurrent sessions: 4'), findsOneWidget);
      expect(find.text('HTML5 console — open via BMC web UI.'), findsOneWidget);
    });

    testWidgets(
        'console card connect-type chips announce as one merged semantics '
        'node (UI-2)', (tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP', 'HTML5'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // The chips are ONE self-describing announcement — a screen reader
      // hears 'Supported connection types: KVMIP, HTML5' instead of two
      // detached chip nodes next to the merged card rows.
      expect(
        find.bySemanticsLabel('Supported connection types: KVMIP, HTML5'),
        findsOneWidget,
        reason: 'UI-2: the connect-type chips announce one merged label',
      );
      // The bare chip labels no longer announce separately (excluded).
      expect(find.bySemanticsLabel('KVMIP'), findsNothing);
      expect(find.bySemanticsLabel('HTML5'), findsNothing);
      // Visible texts stay for sighted users.
      expect(find.text('KVMIP'), findsOneWidget);
      expect(find.text('HTML5'), findsOneWidget);
    });

    testWidgets(
        'console card header announces one merged semantics node — '
        'enabled (UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
          find.bySemanticsLabel('Graphical Console, enabled'), findsOneWidget,
          reason: 'enabled console header announces one merged label');
    });

    testWidgets(
        'console card header announces one merged semantics node — '
        'disabled (UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.serial,
              managerId: 'BMC',
              connectTypesSupported: <String>['SSH'],
              serviceEnabled: false,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Serial Console, disabled'), findsOneWidget,
          reason: 'disabled console header announces one merged label');
    });

    testWidgets(
        'view header announces one merged semantics node — title + subtitle '
        '(UI-2)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: const KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Remote KVM / Consoles, consoles exposed by '
            'the system managers'),
        findsOneWidget,
        reason: 'the view title + subtitle announce as one merged node, not '
            'two detached text nodes',
      );
      // The visible texts are preserved for sighted users.
      expect(find.text('Remote KVM / Consoles'), findsOneWidget);
      expect(find.text('Consoles exposed by the system managers.'),
          findsOneWidget);
    });

    testWidgets(
        'hard load error announces one merged semantics node + a separate '
        'Retry control (UI-2)', (WidgetTester tester) async {
      final KvmController controller =
          KvmController(service: _FailingKvmService());
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // The visible error text is preserved for sighted users…
      expect(find.text('Unable to load KVM consoles'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      // …and the icon + title + detail announce as ONE merged semantics node.
      expect(
        find.bySemanticsLabel('Unable to load KVM consoles. boom'),
        findsOneWidget,
        reason: 'the hard error must announce in context, not as a bare '
            'detached sentence',
      );
      // The Retry control is still separately announced (it is a control).
      expect(find.bySemanticsLabel(RegExp('^Retry')), findsOneWidget);
    });

    testWidgets(
        'tapping Retry re-runs the failing console load without crashing '
        '(UI-2)', (WidgetTester tester) async {
      final _FailingKvmService svc = _FailingKvmService();
      final KvmController controller = KvmController(service: svc);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // The initState post-frame callback performed the first load.
      expect(svc.fetchCalls, 1);

      await tester.tap(find.bySemanticsLabel(RegExp('^Retry')));
      await tester.pumpAndSettle();

      expect(svc.fetchCalls, 2,
          reason: 'Retry must re-run the failing service through the '
              'controller and must not crash');
      // The load still fails, so the merged error node remains.
      expect(
        find.bySemanticsLabel('Unable to load KVM consoles. boom'),
        findsOneWidget,
      );
    });

    testWidgets(
        'empty state renders icon + visible text when a successful load '
        'finds no consoles (UI-2)', (WidgetTester tester) async {
      final KvmController controller =
          KvmController(service: _EmptyKvmService());
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // Visible empty-state text is preserved for sighted users…
      expect(find.text('No consoles found.'), findsOneWidget);
      // …and the empty state shows the established pattern icon.
      expect(find.byIcon(Icons.videogame_asset_off_outlined), findsOneWidget);
    });

    testWidgets(
        'empty state announces one merged semantics node — no consoles found '
        '(UI-2)', (WidgetTester tester) async {
      final KvmController controller =
          KvmController(service: _EmptyKvmService());
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();

      // The icon + text announce as ONE self-describing node, the
      // SensorsView empty-state pattern ('No sensor data available') — not a
      // bare detached sentence.
      expect(
        find.bySemanticsLabel('No consoles found.'),
        findsOneWidget,
        reason: 'the empty state must announce in context, not as a bare '
            'detached sentence',
      );
    });

    testWidgets(
        'loading state announces one merged "Loading KVM consoles" '
        'node (UI-2)', (WidgetTester tester) async {
      // A pre-seeded loading state (the stub's load() no-ops) keeps the view
      // on the loading branch; pumpAndSettle would hang on the spinner.
      final KvmController controller = _StubController()
        ..state = const KvmUiState(loading: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pump();

      // The spinner announces as ONE self-describing merged node instead of a
      // bare unlabeled progress indicator under the header (the established
      // loading-state pattern — FirmwareView header/inventory).
      expect(
        find.bySemanticsLabel('Loading KVM consoles'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('KvmView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
            KvmConsole(
              type: KvmConsoleType.serial,
              managerId: 'BMC',
              connectTypesSupported: <String>['SSH'],
              serviceEnabled: true,
              sourceManagerUri: '/redfish/v1/Managers/BMC',
            ),
          ],
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('renders without overflow at ${width.toInt()} px',
          (tester) async {
        await pumpAtWidth(tester, width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'KvmView must not overflow at $width px',
        );
        // Both console cards render at every breakpoint.
        expect(find.text('Graphical Console'), findsOneWidget);
        expect(find.text('Serial Console'), findsOneWidget);
      });
    }
  });
}
