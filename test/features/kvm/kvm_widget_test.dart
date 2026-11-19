import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
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
        'OEM/no-URI console shows a clear open externally notice with URI '
        'and primary marker (#021 slice)', (WidgetTester tester) async {
      const KvmConsole console = KvmConsole(
        type: KvmConsoleType.oem,
        managerId: 'BMC',
        serviceEnabled: true,
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[console],
          primaryConsole: console,
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

      expect(find.text('Primary'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'No console connect URI available. Open externally: '
          '/redfish/v1/Managers/BMC',
        ),
        findsOneWidget,
      );
      expect(find.text('/redfish/v1/Managers/BMC'), findsWidgets);
      expect(find.text('Copy connect info'), findsOneWidget);
      expect(find.text('Open console'), findsNothing);
    });

    testWidgets(
        'OEM console card shows the resolved OEM KVM URI instead of the '
        '"no URI" notice (#009)', (WidgetTester tester) async {
      final KvmConsole console = KvmConsole.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://oem.example/kvm'},
          },
        },
        managerId: 'BMC',
      ).firstWhere((KvmConsole c) => c.type == KvmConsoleType.oem);
      final KvmController controller = _StubController()
        ..state = KvmUiState(consoles: <KvmConsole>[console]);
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

      // The OEM KVM endpoint reaches the console card, matching the
      // capability card, instead of the misleading "no URI" fallback.
      expect(
        find.bySemanticsLabel('Connect URI: https://oem.example/kvm'),
        findsOneWidget,
      );
      expect(
        find.text('No console connect URI available. Open externally:'),
        findsNothing,
      );
      expect(find.text('Open console'), findsOneWidget);
    });

    testWidgets(
        'HTML5 console with connect URI shows Open console and navigates to '
        'viewer (#021)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.remote,
              managerId: 'BMC',
              connectTypesSupported: <String>['HTML5'],
              serviceEnabled: true,
              connectUri: 'https://bmc.example.com/kvm',
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

      expect(find.text('Open console'), findsOneWidget);
      await tester.tap(find.text('Open console'));
      await tester.pumpAndSettle();

      expect(find.text('Remote Console viewer'), findsOneWidget);
      expect(
        find.textContaining('Embedded rendering requires a WebView dependency'),
        findsOneWidget,
      );
      expect(find.text('https://bmc.example.com/kvm'), findsWidgets);
      expect(find.text('Copy console URI'), findsOneWidget);
    });

    testWidgets(
        'KVMIP/RFB console URI shows external-client guidance in viewer (#021)',
        (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              connectUri: 'vnc://bmc.example.com:5900',
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

      expect(find.text('Open console'), findsOneWidget);
      await tester.tap(find.text('Open console'));
      await tester.pumpAndSettle();

      expect(find.text('Graphical Console viewer'), findsOneWidget);
      expect(
        find.textContaining(
          'requires an external VNC/RFB client',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'Copy the URI and open it with a compatible client'),
        findsOneWidget,
      );
      expect(find.text('vnc://bmc.example.com:5900'), findsWidgets);
      expect(find.text('Copy console URI'), findsOneWidget);
    });

    testWidgets(
        'SSH serial console URI shows external-client guidance in viewer (#021)',
        (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.serial,
              managerId: 'BMC',
              connectTypesSupported: <String>['SSH'],
              serviceEnabled: true,
              connectUri: 'ssh://bmc.example.com:22',
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

      expect(find.text('Open console'), findsOneWidget);
      await tester.tap(find.text('Open console'));
      await tester.pumpAndSettle();

      expect(find.text('Serial Console viewer'), findsOneWidget);
      expect(
        find.textContaining('requires an external SSH client'),
        findsOneWidget,
      );
      expect(find.text('ssh://bmc.example.com:22'), findsWidgets);
      expect(find.text('Copy console URI'), findsOneWidget);
    });

    testWidgets(
        'plaintext HTTP non-HTML5 console is openable and warns about '
        'cleartext in the viewer (#009)', (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.graphical,
              managerId: 'BMC',
              connectTypesSupported: <String>['KVMIP'],
              serviceEnabled: true,
              connectUri: 'http://bmc.example.com/kvm',
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

      // The card warns about the unencrypted endpoint AND offers the launch
      // action (its URI is copyable externally, like an insecure HTML5 console).
      // Before the fix a plain-HTTP non-HTML5 console was mislabelled `noUri`,
      // so canOpenConsole was false and there was no "Open console" action.
      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
      expect(find.text('Open console'), findsOneWidget,
          reason: 'a plaintext HTTP URI is openable/copyable, not "no URI"');
      await tester.tap(find.text('Open console'));
      await tester.pumpAndSettle();

      expect(find.text('Graphical Console viewer'), findsOneWidget);
      expect(
        find.textContaining('uses an unencrypted HTTP connection'),
        findsOneWidget,
      );
      expect(find.text('http://bmc.example.com/kvm'), findsWidgets);
      // Never suggest a secure/browser render route for plaintext HTTP.
      expect(find.textContaining('secure HTTPS connection'), findsNothing);
    });

    testWidgets(
        'plaintext-HTTP HTML5 console card warns about cleartext without '
        'advertising a normal "open via BMC web UI" path (#009)',
        (WidgetTester tester) async {
      final KvmController controller = _StubController()
        ..state = const KvmUiState(
          consoles: <KvmConsole>[
            KvmConsole(
              type: KvmConsoleType.remote,
              managerId: 'BMC',
              connectTypesSupported: <String>['HTML5'],
              serviceEnabled: true,
              connectUri: 'http://bmc.example.com/kvm',
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

      // The card must still surface the unencrypted-transport warning (the
      // operator has to be told the endpoint is unsafe until HTTPS is set up).
      expect(find.bySemanticsLabel(kvmInsecureTransportNotice), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
      // But it must NOT simultaneously advertise a normal "open via the BMC
      // web UI" path for that same unsafe endpoint — that contradicts the
      // warning ("configure HTTPS before opening it in a browser") and gave a
      // plaintext-HTTP HTML5 console two conflicting launch messages. RED
      // before the fix: the unconditional supportsHtml5 hint was still shown.
      expect(
        find.text('HTML5 console — open via BMC web UI.'),
        findsNothing,
        reason: 'no normal-open hint for an unencrypted HTML5 endpoint',
      );
      expect(
        find.bySemanticsLabel('HTML5 console — open via BMC web UI.'),
        findsNothing,
        reason: 'no announced normal-open hint for a cleartext endpoint',
      );
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
      expect(find.byTooltip('Retry loading KVM consoles'), findsOneWidget);
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

    testWidgets(
        'discovery-pending state announces one merged "Loading KVM" node '
        '(UI-2)', (WidgetTester tester) async {
      // Handle known but capabilities not resolved yet → announce a single
      // merged loading node instead of a bare unlabeled spinner.
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(
              const SystemHandle(
                profile: ConnectionProfile(id: 'bmc1', host: 'localhost'),
                status: ConnectionStatus.connected,
                features: null,
              ),
            ),
          ],
          child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('Loading KVM'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // 320 px no-overflow check.
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the Primary badge follows the launchable console, not a disabled '
        'graphical one (#009)', (WidgetTester tester) async {
      const KvmConsole disabledGraphical = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'disabled',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: false,
        sourceManagerUri: '/redfish/v1/Managers/disabled',
      );
      const KvmConsole enabledGraphical = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'enabled',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: true,
        connectUri: 'https://bmc.example/kvm',
        sourceManagerUri: '/redfish/v1/Managers/enabled',
      );
      final List<KvmConsole> consoles = <KvmConsole>[
        disabledGraphical,
        enabledGraphical,
      ];
      final KvmController controller = _StubController()
        ..state = KvmUiState(
          consoles: consoles,
          primaryConsole: KvmService.pickPrimary(consoles),
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

      expect(find.text('Primary'), findsOneWidget);
      // Only the launchable console card has an "Open console" action, so the
      // Primary badge must sit on that same card, not the disabled one.
      final Finder primaryCard = find.ancestor(
        of: find.text('Primary'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(
          of: primaryCard,
          matching: find.text('Open console'),
        ),
        findsOneWidget,
        reason: 'the Primary badge must sit on the openable console card',
      );
      expect(find.text('Open console'), findsOneWidget);
    });

    testWidgets(
        'the Primary badge prefers a secure-HTTPS console over a plaintext '
        'one (#021)', (WidgetTester tester) async {
      // The final render route is external-browser + copy, so the recommended
      // ("Primary") console must be the control-safe HTTPS target even when a
      // plaintext-HTTP console is listed first — never badge an unsafe target.
      const KvmConsole plaintext = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'plaintext',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: true,
        connectUri: 'http://bmc.example/kvm',
        sourceManagerUri: '/redfish/v1/Managers/plaintext',
      );
      const KvmConsole secure = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'secure',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: true,
        connectUri: 'https://bmc.example/kvm',
        sourceManagerUri: '/redfish/v1/Managers/secure',
      );
      final List<KvmConsole> consoles = <KvmConsole>[plaintext, secure];
      final KvmController controller = _StubController()
        ..state = KvmUiState(
          consoles: consoles,
          primaryConsole: KvmService.pickPrimary(consoles),
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

      expect(find.text('Primary'), findsOneWidget);
      final Finder primaryCard = find.ancestor(
        of: find.text('Primary'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(
          of: primaryCard,
          matching: find.text('Manager: secure'),
        ),
        findsOneWidget,
        reason: 'the Primary badge must sit on the secure-HTTPS console card',
      );
    });

    testWidgets(
        'a disabled console with a connect URI does not offer an actionable '
        '"Open console" (#009/#021)', (WidgetTester tester) async {
      // A BMC can report ServiceEnabled: false yet still publish a ConnectUri.
      // The model already reports canOpenConsole == false for that console (its
      // launchStrategy is `disabled`) and the viewer refuses to launch a
      // disabled service, so the card must not offer an "Open console" action
      // that only leads to a dead-end explanation. The URI stays visible and
      // copyable — only the launch affordance is gated.
      const KvmConsole disabledWithUri = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: false,
        connectUri: 'https://bmc.example/kvm',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(disabledWithUri.canOpenConsole, isFalse);
      final KvmController controller = _StubController()
        ..state = const KvmUiState(consoles: <KvmConsole>[disabledWithUri]);
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

      // The URI is still shown and copyable, but the launch affordance is gated
      // on canOpenConsole so a disabled service cannot be offered as openable.
      expect(
        find.bySemanticsLabel('Connect URI: https://bmc.example/kvm'),
        findsOneWidget,
      );
      expect(find.text('Copy connect info'), findsOneWidget);
      expect(find.text('Open console'), findsNothing);
    });

    testWidgets(
        'an explicitly disabled OEM console is not offered as openable '
        '(#009)', (WidgetTester tester) async {
      // RED proof: the generic OEM path hard-coded serviceEnabled: true, so
      // the console card offered "Open console" for a BMC that explicitly
      // reported ServiceEnabled: false on its OEM KVM block (every other
      // console source already honors enablement).
      final KvmConsole disabledOem = KvmConsole.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': 'https://bmc.example/kvm',
              'ServiceEnabled': false,
            },
          },
        },
        managerId: 'BMC',
      ).firstWhere((KvmConsole c) => c.type == KvmConsoleType.oem);
      expect(disabledOem.canOpenConsole, isFalse);
      final KvmController controller = _StubController()
        ..state = KvmUiState(consoles: <KvmConsole>[disabledOem]);
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

      // A disabled console keeps its URI visible + copyable but no longer
      // offers the dead-end "Open console" action.
      expect(find.text('Open console'), findsNothing);
      expect(find.text('Copy connect info'), findsOneWidget);
    });
  });

  group('KvmView — console-card transport warning (#009/#021)', () {
    KvmConsole console({required String uri}) => KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: const <String>['HTML5'],
          serviceEnabled: true,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    Future<void> pumpCard(
      WidgetTester tester,
      KvmConsole value, {
      double? width,
    }) async {
      if (width != null) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }
      final KvmController controller = _StubController()
        ..state = KvmUiState(consoles: <KvmConsole>[value]);
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

    testWidgets(
        'a plaintext-HTTP console card shows the shared unencrypted-transport '
        'warning with a merged announcement (#021)', (tester) async {
      await pumpCard(tester, console(uri: 'http://bmc.example.com/kvm'));

      // The announcement IS the visible text (single excludeSemantics node),
      // and it is the exact same sentence the capability card uses.
      expect(find.bySemanticsLabel(kvmInsecureTransportNotice), findsOneWidget,
          reason: 'a11y: the insecure-transport warning must be announced');
      expect(find.text(kvmInsecureTransportNotice), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_outlined), findsOneWidget);
      // The warning is guidance, not a hidden action: an insecure HTML5
      // console stays openable so its URI remains usable externally.
      expect(find.text('Open console'), findsOneWidget);
      expect(
        find.textContaining('In-app HTML5 console path available'),
        findsNothing,
      );
    });

    testWidgets('a secure HTTPS console card shows no transport warning (#021)',
        (tester) async {
      await pumpCard(tester, console(uri: 'https://bmc.example.com/kvm'));

      expect(find.bySemanticsLabel(kvmInsecureTransportNotice), findsNothing);
      expect(find.text(kvmInsecureTransportNotice), findsNothing);
      expect(find.byIcon(Icons.lock_open_outlined), findsNothing);
    });

    testWidgets(
        'a control-char-bearing HTTPS URI offers no "Open console" action — '
        'the card agrees with the fail-closed launch plan (#009/#021)',
        (tester) async {
      // Uri.tryParse percent-encodes CRLF/NUL and still reports HTTPS + a host,
      // so a naive classifier would offer "Open console" for a target the
      // decision layer refuses to launch (copy-only) and that risks URI
      // injection. The card gates on canOpenConsole, which now uses the shared
      // secure classifier, so the two surfaces agree.
      await pumpCard(
          tester, console(uri: 'https://bmc.example/kvm\r\nX-Injected: 1'));

      expect(find.text('Open console'), findsNothing);
      // Fail closed, not hidden: the endpoint stays visible and copyable for
      // external use.
      expect(find.text('Copy connect info'), findsOneWidget);
      // Not a plaintext-HTTP console, so no unencrypted-transport warning.
      expect(find.text(kvmInsecureTransportNotice), findsNothing);
    });

    testWidgets(
        'the card copy action fails closed for a control-char URI — the '
        'clipboard gets the manager source, not the injection-bearing target '
        '(#009/#021)', (tester) async {
      // The viewer takes its copy target from the fail-closed launch plan, so a
      // CRLF-bearing HTTPS URI is never placed on the clipboard. The card must
      // agree: its "Copy connect info" action copies the safe manager source
      // rather than the raw control-char endpoint (which risks header/clipboard
      // injection when pasted). Fail closed, not hidden: the raw URI stays
      // visible in the card, only the explicit copy action is hardened.
      final List<Object?> copied = <Object?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(call.arguments['text']);
          }
          return null;
        },
      );
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      // Wrap KvmView in a Scaffold so the copy action's confirmation SnackBar
      // has a descendant Scaffold to present into.
      final KvmController controller = _StubController()
        ..state = KvmUiState(consoles: <KvmConsole>[
          console(uri: 'https://bmc.example/kvm\r\nX-Injected: 1')
        ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: true)),
            kvmControllerProvider.overrideWith((ref, id) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(body: KvmView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The endpoint stays visible/selectable and the copy affordance remains
      // available (fail closed, not hidden).
      expect(find.text('Copy connect info'), findsOneWidget);
      await tester.tap(find.text('Copy connect info'));
      await tester.pumpAndSettle();

      expect(copied, hasLength(1));
      expect(copied.single, '/redfish/v1/Managers/BMC');
      expect(copied.single, isNot(contains('X-Injected')));
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'plaintext-HTTP warning card renders without overflow at '
          '${width.toInt()} px', (tester) async {
        await pumpCard(
          tester,
          console(uri: 'http://bmc.example.com/kvm'),
          width: width,
        );
        expect(tester.takeException(), isNull,
            reason: 'the transport warning must not overflow at $width px');
        expect(find.text(kvmInsecureTransportNotice), findsOneWidget);
      });
    }
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

  group('KvmConsoleViewerPage — status announcement (a11y)', () {
    Future<void> pumpViewer(WidgetTester tester, KvmConsole console) async {
      await tester.pumpWidget(
        MaterialApp(home: KvmConsoleViewerPage(console: console)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'HTML5 status announces the same actionable guidance it shows '
        '(#010)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: <String>['HTML5'],
          serviceEnabled: true,
          connectUri: 'https://bmc.example.com/kvm',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      const String expected =
          'In-app HTML5 console path available for this URI. '
          'Embedded rendering requires a WebView dependency. '
          'You can open this URI in a web browser if your BMC allows it.';
      // Exact-match on both trees proves the announced label IS the visible
      // text — screen-reader users get the browser-open step and no internal
      // issue-referencing jargon that sighted users never see.
      expect(find.bySemanticsLabel(expected), findsOneWidget,
          reason:
              'a11y: announcement must include the actionable browser step');
      expect(find.text(expected), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'#021')), findsNothing,
          reason: 'internal issue references must not appear in UI copy');
    });

    testWidgets(
        'plaintext-HTTP HTML5 console shows a secure-transport warning '
        'and is not offered as an in-app render path (#021)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: <String>['HTML5'],
          serviceEnabled: true,
          connectUri: 'http://bmc.example.com/kvm',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      const String expected =
          'This HTML5 console uses an unencrypted HTTP connection. '
          'In-app rendering is disabled to keep console video and input '
          'encrypted. Configure the BMC console to use HTTPS before '
          'opening it in a browser.';
      // Exact-match on both trees: the announced guidance equals the visible
      // warning, and it explicitly tells the operator to enable HTTPS.
      expect(find.bySemanticsLabel(expected), findsOneWidget,
          reason: 'a11y: the insecure-transport warning must be announced');
      expect(find.text(expected), findsOneWidget);
      expect(
          find.textContaining('unencrypted HTTP connection'), findsOneWidget);
      expect(find.textContaining('Configure the BMC console to use HTTPS'),
          findsOneWidget);
      // The generic "path available" copy must NOT appear for plaintext HTTP.
      expect(
        find.textContaining('In-app HTML5 console path available'),
        findsNothing,
      );
    });

    testWidgets(
        'external-client status announces the copy-and-open step '
        '(#010)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: <String>['KVMIP'],
          serviceEnabled: true,
          connectUri: 'vnc://bmc.example.com:5900',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      const String expected =
          'This console URI uses a protocol that requires an external '
          'VNC/RFB client. Embedded rendering is not available in-app. '
          'Copy the URI and open it with a compatible client.';
      expect(find.bySemanticsLabel(expected), findsOneWidget,
          reason: 'a11y: announcement must include the copy-and-open step');
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets(
        'non-HTML5 plaintext HTTP status announces the cleartext warning '
        'with error styling (#009)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: <String>['KVMIP'],
          serviceEnabled: true,
          connectUri: 'http://bmc.example.com/kvm',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      const String expected =
          'This console uses an unencrypted HTTP connection. '
          'In-app rendering is disabled to keep console video and input '
          'encrypted. Configure the BMC console to use HTTPS, or copy the '
          'URI for an external client.';
      expect(find.bySemanticsLabel(expected), findsOneWidget,
          reason: 'a11y: the cleartext warning must be announced');
      expect(find.text(expected), findsOneWidget);
      expect(
        find.textContaining('In-app embedded rendering is not available'),
        findsNothing,
        reason: 'must not show the generic no-URI guidance for a real HTTP URI',
      );
      // The warning is error-styled on every surface that flags plaintext HTTP.
      final Text status = tester.widget<Text>(find.text(expected));
      expect(
        status.style?.color,
        Theme.of(tester.element(find.text(expected))).colorScheme.error,
        reason: 'plaintext HTTP status carries the security error colour',
      );
    });

    testWidgets('fallback status announces exactly its visible text (#010)',
        (tester) async {
      // No connect URI and no HTML5/external protocol → the fallback message.
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: <String>['KVMIP'],
          serviceEnabled: true,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      const String expected =
          'In-app embedded rendering is not available for this console. '
          'Use the URI externally if provided.';
      expect(find.bySemanticsLabel(expected), findsOneWidget);
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets(
        'disabled console shows an actionable enable-on-BMC status '
        '(#021)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: <String>['HTML5'],
          serviceEnabled: false,
          connectUri: 'https://bmc.example.com/kvm',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      const String expected =
          'This console service is disabled on the BMC. Enable it in the '
          'BMC settings before launching a console session.';
      expect(find.bySemanticsLabel(expected), findsOneWidget,
          reason: 'a11y: the disabled blocker must be announced');
      expect(find.text(expected), findsOneWidget);
      expect(find.textContaining('In-app HTML5 console path available'),
          findsNothing);
    });

    testWidgets(
        'HTTPS non-HTML5 console suggests a secure browser, never '
        'an in-app or unencrypted path (#021)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: <String>['KVMIP'],
          serviceEnabled: true,
          connectUri: 'https://bmc.example.com/kvm',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      const String expected =
          'This console uses a secure HTTPS connection. Embedded rendering '
          'is not available for this console type. Open the URI in a secure '
          'web browser, or copy it for an external client.';
      expect(find.bySemanticsLabel(expected), findsOneWidget);
      expect(find.text(expected), findsOneWidget);
      expect(find.textContaining('In-app HTML5 console path available'),
          findsNothing);
      expect(find.textContaining('unencrypted HTTP connection'), findsNothing);
    });

    testWidgets(
        'a control-char external URI does not present a trusted external-client '
        'path (#009/#021)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: <String>['KVMIP'],
          serviceEnabled: true,
          connectUri: 'vnc://bmc.example/con\r\nsol',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      // Bare Uri.tryParse percent-encodes CRLF into a spoofed host but still
      // reports the `vnc` scheme, so pre-fix the viewer announced a trustworthy
      // "requires an external VNC/RFB client" path for an injection-bearing URI.
      // It must instead fail closed to the generic no-URI guidance.
      expect(find.textContaining('requires an external'), findsNothing);
      expect(find.textContaining('VNC/RFB client'), findsNothing);
      final String noUriText = kvmLaunchStatusText(KvmLaunchStrategy.noUri);
      expect(find.bySemanticsLabel(noUriText), findsOneWidget);
      expect(find.text(noUriText), findsOneWidget);
    });

    testWidgets(
        'a control-char URI is not offered as a clipboard copy target in the '
        'viewer — the launch plan fails closed (#009/#021)', (tester) async {
      // planConsoleLaunch must re-validate the URI it hands to the launcher /
      // clipboard, not just the secure signal. A CRLF-bearing HTTPS URI risks
      // header/clipboard injection when pasted, so the viewer must not offer a
      // "Copy console URI" action carrying it: it falls back to the manager
      // source instead. The card still keeps the endpoint visible/copyable.
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: <String>['HTML5'],
          serviceEnabled: true,
          connectUri: 'https://bmc.example/kvm\r\nX-Injected: 1',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      expect(find.text('Copy console URI'), findsNothing);
      expect(find.textContaining('X-Injected'), findsNothing);
      expect(find.textContaining('No direct console URI'), findsOneWidget);
      expect(find.textContaining('/redfish/v1/Managers/BMC'), findsOneWidget);
    });

    testWidgets(
        'the viewer repeats the session-persistence notice with visible text '
        'equal to the announced label (#009 / RU-2)', (tester) async {
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: <String>['KVMIP'],
          serviceEnabled: true,
          connectUri: 'https://bmc.example.com/kvm',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      // One merged Semantics node whose label is exactly the visible text, so
      // a screen reader drilling into a console hears the same session-persistence
      // guidance the gated list view shows (single shared constant — RU-2).
      expect(
          find.bySemanticsLabel(kvmSessionPersistenceNotice), findsOneWidget);
      expect(find.text(kvmSessionPersistenceNotice), findsOneWidget);
    });

    testWidgets(
        'session-persistence notice does not overflow at 320 px '
        '(#009 / RU-2)', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await pumpViewer(
        tester,
        const KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: <String>['HTML5'],
          serviceEnabled: true,
          connectUri: 'https://bmc.example.com/kvm',
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
          find.bySemanticsLabel(kvmSessionPersistenceNotice), findsOneWidget);
    });
  });
}
