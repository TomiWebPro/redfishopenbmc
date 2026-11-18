import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op so the view can be pre-seeded
/// without touching the network (mirrors the established widget-test stub).
class _StubController extends KvmController {
  _StubController()
      : super(service: KvmService(client: null, systemId: 'bmc1'));

  @override
  Future<void> load() async {}
}

SystemHandle _handle({required bool kvm}) => SystemHandle(
      profile: const ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: kvm),
    );

const KvmConsole _oneConsole = KvmConsole(
  type: KvmConsoleType.graphical,
  managerId: 'BMC',
  connectTypesSupported: <String>['KVMIP'],
  serviceEnabled: true,
  sourceManagerUri: '/redfish/v1/Managers/BMC',
);

const KvmCapability _supportedCapability = KvmCapability(
  managerId: 'BMC',
  supported: true,
  connectTypes: <String>['KVMIP', 'HTML5'],
  serviceEnabled: true,
  maxSessions: 4,
  uri: 'https://bmc.example.com/kvm',
  sourceManagerUri: '/redfish/v1/Managers/BMC',
);

const String _sessionNote =
    'Console persists until manager timeout — close tab to disconnect';

Future<void> pumpView(
  WidgetTester tester, {
  required List<KvmCapability> capabilities,
  required bool kvm,
}) async {
  final KvmController controller = _StubController()
    ..state = const KvmUiState(consoles: <KvmConsole>[_oneConsole]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle(kvm: kvm)),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(capabilities),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('KvmCapabilityCard', () {
    testWidgets(
        'renders every required capability field with merged a11y '
        'labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: KvmCapabilityCard(capability: _supportedCapability)),
      );

      // Visible fields: manager, status, connection types, session limit, URI.
      expect(find.text('Manager capability: BMC'), findsOneWidget);
      expect(find.text('Supported'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Service enabled: Yes'), findsOneWidget);
      expect(find.text('KVMIP'), findsOneWidget);
      expect(find.text('HTML5'), findsOneWidget);
      expect(find.text('Max sessions: 4'), findsOneWidget);
      expect(find.text('Resolved URI:'), findsOneWidget);
      expect(find.text('https://bmc.example.com/kvm'), findsOneWidget);
      // No disabled helper for an enabled capability.
      expect(find.textContaining('KVM disabled on BMC'), findsNothing);

      // Each row announces as one self-describing node (UI-2).
      expect(
        find.bySemanticsLabel('Manager capability BMC, enabled, KVM supported'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Service enabled: yes'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Connection types: KVMIP, HTML5'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Max sessions: 4'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Resolved URI: https://bmc.example.com/kvm'),
        findsOneWidget,
      );
    });

    testWidgets(
        'disabled capability shows the BMC helper and a source URI '
        'notice instead of a resolved URI', (WidgetTester tester) async {
      const KvmCapability capability = KvmCapability(
        managerId: 'BMC2',
        supported: false,
        connectTypes: <String>['SerialOverLAN'],
        serviceEnabled: false,
        sourceManagerUri: '/redfish/v1/Managers/BMC2',
      );
      await tester.pumpWidget(
        const MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(find.text('Service enabled: No'), findsOneWidget);
      expect(find.text('Supported'), findsNothing);
      expect(find.textContaining('KVM disabled on BMC'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'KVM disabled on BMC. Enable the console service in the BMC settings.',
        ),
        findsOneWidget,
      );
      expect(find.text('No console URI resolved. Source:'), findsOneWidget);
      expect(find.text('/redfish/v1/Managers/BMC2'), findsOneWidget);
      expect(find.text('Resolved URI:'), findsNothing);
      expect(
        find.bySemanticsLabel(
          'No console URI resolved. Source: /redfish/v1/Managers/BMC2',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
            'Manager capability BMC2, disabled, KVM not supported'),
        findsOneWidget,
      );
    });

    testWidgets('a blank resolved URI shows the source notice, not a blank row',
        (WidgetTester tester) async {
      // A BMC can emit a whitespace-only ConnectUri. The card must take the
      // "no URI" branch rather than rendering an empty "Resolved URI:" row
      // (a real user-visible defect fixed with the model blank-URI handling).
      const KvmCapability capability = KvmCapability(
        managerId: 'BMC3',
        supported: true,
        connectTypes: <String>['KVMIP'],
        serviceEnabled: true,
        uri: '   ',
        sourceManagerUri: '/redfish/v1/Managers/BMC3',
      );
      await tester.pumpWidget(
        const MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(find.text('Resolved URI:'), findsNothing);
      expect(find.text('No console URI resolved. Source:'), findsOneWidget);
      expect(find.text('/redfish/v1/Managers/BMC3'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'No console URI resolved. Source: /redfish/v1/Managers/BMC3',
        ),
        findsOneWidget,
      );
    });

    testWidgets('card shows the enabled console URI, not a disabled one',
        (WidgetTester tester) async {
      // A manager with a disabled graphical console (first) and an enabled
      // remote console: the resolved URI driving the card must be the
      // launchable one, matching the console the user can actually open.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC9',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'ConnectUri': 'https://bmc.example/disabled-kvm',
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
            'ConnectUri': 'https://bmc.example/html5',
          },
        },
        managerId: 'BMC9',
      );
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(find.text('https://bmc.example/html5'), findsOneWidget);
      expect(find.text('https://bmc.example/disabled-kvm'), findsNothing);
      expect(
        find.bySemanticsLabel('Resolved URI: https://bmc.example/html5'),
        findsOneWidget,
      );
    });

    testWidgets('a whitespace-padded resolved URI is displayed trimmed',
        (WidgetTester tester) async {
      // A BMC can pad an otherwise valid ConnectUri. The card must display the
      // normalized endpoint (matching the per-console card), not the padded
      // literal with stray leading/trailing whitespace.
      const KvmCapability capability = KvmCapability(
        managerId: 'BMC4',
        supported: true,
        connectTypes: <String>['KVMIP'],
        serviceEnabled: true,
        uri: '  https://padded.example/kvm\t',
        sourceManagerUri: '/redfish/v1/Managers/BMC4',
      );
      await tester.pumpWidget(
        const MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(find.text('https://padded.example/kvm'), findsOneWidget);
      expect(find.text('  https://padded.example/kvm\t'), findsNothing);
      expect(
        find.bySemanticsLabel('Resolved URI: https://padded.example/kvm'),
        findsOneWidget,
      );
    });

    testWidgets(
        'malformed ConnectTypesSupported entries render no bogus '
        'chips (#009)', (WidgetTester tester) async {
      // A malformed BMC payload can carry null / numeric entries in the
      // Redfish ConnectTypesSupported string array. The capability card must
      // surface only real string enum values, never literal "null"/"42" chips.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', null, 42, 'HTML5'],
          },
        },
        managerId: 'BMC5',
      );
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(capability.connectTypes, <String>['KVMIP', 'HTML5']);
      expect(find.text('KVMIP'), findsOneWidget);
      expect(find.text('HTML5'), findsOneWidget);
      expect(find.text('null'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(
        find.bySemanticsLabel('Connection types: KVMIP, HTML5'),
        findsOneWidget,
      );
    });

    testWidgets(
        'a RemoteConsole-only manager renders as supported and '
        'enabled, not "KVM disabled on BMC" (#009)',
        (WidgetTester tester) async {
      // A manager exposing only a RemoteConsole produced an enabled per-console
      // card but a "disabled / not supported" capability card before fromManager
      // learned to aggregate RemoteConsole. Pin the corrected card output.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
            'MaxConcurrentSessions': 2,
            'ConnectUri': 'https://bmc.example/html5',
          },
        },
        managerId: 'BMC6',
      );
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(find.text('Supported'), findsOneWidget);
      expect(find.text('Service enabled: Yes'), findsOneWidget);
      expect(find.text('HTML5'), findsOneWidget);
      expect(find.textContaining('KVM disabled on BMC'), findsNothing);
      expect(
        find.bySemanticsLabel(
          'Manager capability BMC6, enabled, KVM supported',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Connection types: HTML5'),
        findsOneWidget,
      );
    });

    testWidgets(
        'a malformed manager @odata.id still renders a usable source '
        'notice (#009)', (WidgetTester tester) async {
      // A non-string @odata.id used to throw a TypeError in fromManager,
      // blanking the whole capability card. The card must render the derived
      // manager URI instead of crashing or showing an empty source row.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          '@odata.id': 42,
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
        },
        managerId: 'BMC7',
      );
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(capability.sourceManagerUri, '/redfish/v1/Managers/BMC7');
      expect(find.text('No console URI resolved. Source:'), findsOneWidget);
      expect(find.text('/redfish/v1/Managers/BMC7'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'No console URI resolved. Source: /redfish/v1/Managers/BMC7',
        ),
        findsOneWidget,
      );
    });
  });

  group('KvmView capability section', () {
    testWidgets(
        'renders capability cards and the session note when '
        'capabilities are discovered', (WidgetTester tester) async {
      await pumpView(
        tester,
        capabilities: <KvmCapability>[_supportedCapability],
        kvm: true,
      );

      expect(find.byType(KvmCapabilityCard), findsOneWidget);
      expect(find.text('Manager capabilities'), findsOneWidget);
      expect(find.bySemanticsLabel('Manager capabilities'), findsOneWidget);
      expect(find.text('Manager capability: BMC'), findsOneWidget);
      // Console cards still render alongside the capability section.
      expect(find.text('Graphical Console'), findsOneWidget);
      // Acceptance #009: session note visible == announced, no issue jargon.
      expect(find.text(_sessionNote), findsOneWidget);
      expect(find.bySemanticsLabel(_sessionNote), findsOneWidget);
      expect(find.textContaining('#009'), findsNothing);
    });

    testWidgets('renders no capability section when the provider yields none',
        (WidgetTester tester) async {
      await pumpView(
        tester,
        capabilities: <KvmCapability>[],
        kvm: true,
      );

      expect(find.byType(KvmCapabilityCard), findsNothing);
      expect(find.text('Manager capabilities'), findsNothing);
      // The session note is still shown alongside the console cards.
      expect(find.text(_sessionNote), findsOneWidget);
    });

    testWidgets(
        'hides capability cards entirely when KVM is disabled for the '
        'system', (WidgetTester tester) async {
      await pumpView(
        tester,
        capabilities: <KvmCapability>[_supportedCapability],
        kvm: false,
      );

      expect(find.byType(KvmCapabilityCard), findsNothing);
      expect(find.text('Manager capability: BMC'), findsNothing);
      expect(find.text(_sessionNote), findsNothing);
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'capability section renders without overflow at '
          '${width.toInt()} px', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpView(
          tester,
          capabilities: <KvmCapability>[_supportedCapability],
          kvm: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(KvmCapabilityCard), findsOneWidget);
        expect(find.text(_sessionNote), findsOneWidget);
      });
    }
  });
}
