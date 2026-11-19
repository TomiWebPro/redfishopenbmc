import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
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

/// A capability whose resolved endpoint is plaintext HTTP — never a safe
/// in-app render target (issue #021 — never weaken TLS).
const KvmCapability _insecureCapability = KvmCapability(
  managerId: 'BMC7',
  supported: true,
  connectTypes: <String>['HTML5'],
  serviceEnabled: true,
  uri: 'http://bmc.example.com/kvm',
  sourceManagerUri: '/redfish/v1/Managers/BMC7',
);

// RU-2: derive from the single shared constant so the test and the view can
// never drift apart on the exact session-persistence wording.
const String _sessionNote = kvmSessionPersistenceNotice;

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
      // RU-2: the disabled helper's visible text equals its merged announced
      // label, sourced from one shared constant.
      expect(find.text(kvmDisabledOnBmcNotice), findsOneWidget);
      expect(find.bySemanticsLabel(kvmDisabledOnBmcNotice), findsOneWidget);
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

    testWidgets(
        'a URI-less BMC-disabled OEM console renders the disabled helper '
        '(RM-1 / #009)', (WidgetTester tester) async {
      // A BMC may disable its OEM KVM block without publishing a Uri. The
      // capability must honour that explicit disable (like every standard
      // console block) and show the "KVM disabled on BMC" helper rather than a
      // Supported/Enabled card. RED pre-fix: kvmOemConsoleEnabled only looked
      // at Uri-bearing blocks, so this capability was reported supported.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{
              'KVM': <String, dynamic>{'ServiceEnabled': false},
            },
          },
        },
        managerId: 'BMC',
      );
      expect(capability.supported, isFalse);
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );
      expect(find.text(kvmDisabledOnBmcNotice), findsOneWidget);
      expect(find.bySemanticsLabel(kvmDisabledOnBmcNotice), findsOneWidget);
      expect(find.text('Supported'), findsNothing);
      expect(find.text('No console URI resolved. Source:'), findsOneWidget);
    });

    testWidgets(
        'a non-map OEM console value renders no Supported capability card '
        '(RM-3 / #009)', (WidgetTester tester) async {
      // A malformed BMC can publish a console-like key (KVM) with a scalar
      // instead of a console object ('Oem.OpenBMC.KVM': 'https://…'). RM-3 must
      // fail closed in the shared walk so the capability card cannot advertise
      // a bogus Supported/Enabled console. RED pre-fix: oemHasConsole keyed only
      // on the name, so the model reported supported=true and this card showed
      // the Supported chip / no disabled helper.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{'KVM': 'https://bmc.example/kvm'},
          },
        },
        managerId: 'BMC',
      );
      expect(capability.supported, isFalse);
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );
      expect(find.text('Supported'), findsNothing);
      expect(find.text(kvmDisabledOnBmcNotice), findsOneWidget);
      expect(find.bySemanticsLabel(kvmDisabledOnBmcNotice), findsOneWidget);

      for (final double width in <double>[320, 800, 1300]) {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(home: KvmCapabilityCard(capability: capability)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
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

    testWidgets(
        'a disabled graphical @odata.id does not become the resolved URI '
        'when an OEM console exists (#009)', (WidgetTester tester) async {
      // A disabled graphical console's Redfish API link is not a browser-
      // launchable console endpoint. When a launchable OEM KVM URI exists (the
      // one the per-console card surfaces), the capability card must show that
      // URI instead of the disabled console's resource link.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
          },
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{
              'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
            },
          },
        },
        managerId: 'BMC',
      );
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(capability.uri, 'https://bmc.example/kvm');
      expect(find.text('https://bmc.example/kvm'), findsOneWidget);
      expect(
          find.text('/redfish/v1/Managers/BMC/GraphicalConsole'), findsNothing);
      expect(
        find.bySemanticsLabel('Resolved URI: https://bmc.example/kvm'),
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
        'a plaintext-HTTP resolved URI flags unencrypted transport '
        'with a merged a11y label (#021)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: KvmCapabilityCard(capability: _insecureCapability)),
      );

      // The resolved endpoint stays visible/read-only, but it must carry the
      // same unencrypted-transport warning the console card / viewer show —
      // otherwise an operator could copy/open it without realising console
      // video and injected input would travel in the clear. Display-only: no
      // transport is weakened and no URL is opened (issue #021).
      expect(find.text('http://bmc.example.com/kvm'), findsOneWidget);
      expect(
        find.textContaining('Unencrypted HTTP console URI'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Unencrypted HTTP console URI. Configure the BMC console to use '
          'HTTPS before opening it in a browser.',
        ),
        findsOneWidget,
      );

      // A secure HTTPS capability shows no warning.
      await tester.pumpWidget(
        const MaterialApp(
            home: KvmCapabilityCard(capability: _supportedCapability)),
      );
      expect(
        find.textContaining('Unencrypted HTTP console URI'),
        findsNothing,
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
        'Max sessions shows the enabled console limit, not the disabled '
        'graphical one (#009)', (WidgetTester tester) async {
      // A disabled graphical console carrying MaxConcurrentSessions 1 used to
      // win the aggregate, so the card reported "Max sessions: 1" while the
      // launchable RemoteConsole allowed 4. Pin the enabled-console limit.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'ConnectUri': 'https://bmc.example/disabled-kvm',
            'MaxConcurrentSessions': 1,
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
            'ConnectUri': 'https://bmc.example/html5',
            'MaxConcurrentSessions': 4,
          },
        },
        managerId: 'BMC8',
      );
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(find.text('Max sessions: 4'), findsOneWidget);
      expect(find.text('Max sessions: 1'), findsNothing);
      expect(find.bySemanticsLabel('Max sessions: 4'), findsOneWidget);
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

    testWidgets(
        'connection types show the enabled console types, not a disabled '
        'graphical console\'s (#009)', (WidgetTester tester) async {
      // A disabled graphical console advertising KVMIP must not put a KVMIP
      // chip on the capability card when the only openable console is an
      // HTML5 remote console — mirroring the enabled-preference already
      // applied to the resolved URI and maxSessions rows.
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
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
        managerId: 'BMC6',
      );
      await tester.pumpWidget(
        MaterialApp(home: KvmCapabilityCard(capability: capability)),
      );

      expect(find.text('HTML5'), findsOneWidget);
      expect(find.text('KVMIP'), findsNothing);
      expect(find.bySemanticsLabel('Connection types: HTML5'), findsOneWidget);
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

    testWidgets(
        'capability card does not duplicate a literal OEM type as an Oem '
        'marker chip (#009)', (WidgetTester tester) async {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['OEM'],
          },
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
        managerId: 'BMC',
      );

      await pumpView(
        tester,
        capabilities: <KvmCapability>[capability],
        kvm: true,
      );

      expect(find.text('OEM'), findsOneWidget);
      expect(find.text('Oem'), findsNothing,
          reason: 'the case-insensitive dedup must not render a second chip');
      expect(find.bySemanticsLabel('Connection types: OEM'), findsOneWidget);
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

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'plaintext-HTTP warning row renders without overflow at '
          '${width.toInt()} px (#021)', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
              home: KvmCapabilityCard(capability: _insecureCapability)),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('Unencrypted HTTP console URI'),
          findsOneWidget,
        );
      });
    }
  });

  group('KvmCapabilityCard — OEM console enablement (#009)', () {
    testWidgets(
        'an explicitly disabled OEM console renders a disabled, unsupported '
        'capability card (#009)', (WidgetTester tester) async {
      // RED proof: oemConsole key presence alone produced supported+enabled,
      // so the card showed "Supported / Enabled" and no BMC-disabled helper
      // for a console the BMC explicitly reported ServiceEnabled: false.
      final KvmCapability capability = KvmCapability.fromManager(
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
      );
      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
      await pumpView(
        tester,
        capabilities: <KvmCapability>[capability],
        kvm: true,
      );

      expect(find.text('Service enabled: No'), findsOneWidget);
      expect(find.text('Supported'), findsNothing);
      expect(find.text(kvmDisabledOnBmcNotice), findsOneWidget);
      expect(find.bySemanticsLabel(kvmDisabledOnBmcNotice), findsOneWidget);
    });
  });

  group('KvmCapabilityCard — external-client transport parity (#009/#021)', () {
    // The capability card surfaces the manager's resolved endpoint just like
    // the per-console card and the viewer. A non-HTTP transport (VNC/RFB, KVMIP,
    // serial SSH/Telnet/IPMI) cannot be rendered in-app, so the operator needs
    // the same "requires an external client" guidance on this surface too.
    // EP-U3: the notice names the *specific* protocol the model already knows,
    // matching the viewer's guidance, instead of listing every possibility.
    KvmCapability capabilityFor(String uri) => KvmCapability.fromManager(
          <String, dynamic>{
            '@odata.id': '/redfish/v1/Managers/BMC',
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'ConnectTypesSupported': <dynamic>['KVMIP'],
              'ConnectUri': uri,
            },
          },
          managerId: 'BMC',
        );

    for (final MapEntry<String, String> c in <String, String>{
      'vnc://bmc.example:5900': 'VNC/RFB',
      'ssh://bmc.example:22': 'SSH',
      'ipmi://bmc.example': 'IPMI serial-over-LAN',
    }.entries) {
      testWidgets(
          'a resolved ${c.value} URI names the external client protocol with '
          'merged a11y and no overflow at 320/800/1300 px',
          (WidgetTester tester) async {
        final KvmCapability capability = capabilityFor(c.key);
        expect(capability.hasUri, isTrue);
        expect(capability.externalClientProtocolLabel, c.value);

        // RED proof: before the fix the card rendered the generic list notice,
        // which never contains "requires an external <protocol> client".
        final String expectedNotice = kvmExternalClientNoticeFor(
          capability.externalClientProtocolLabel,
        );
        expect(expectedNotice, contains('external ${c.value} client'));

        for (final double width in <double>[320, 800, 1300]) {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await pumpView(
            tester,
            capabilities: <KvmCapability>[capability],
            kvm: true,
          );

          expect(find.text(expectedNotice), findsOneWidget);
          expect(find.bySemanticsLabel(expectedNotice), findsOneWidget);
          // The plaintext-HTTP notice must not leak onto a non-HTTP transport.
          expect(find.text(kvmInsecureTransportNotice), findsNothing);
          expect(tester.takeException(), isNull);
        }
      });
    }

    test('kvmExternalClientNoticeFor falls back for a blank/unknown label', () {
      expect(kvmExternalClientNoticeFor(null), kvmExternalClientNotice);
      expect(kvmExternalClientNoticeFor('   '), kvmExternalClientNotice);
      expect(kvmExternalClientNoticeFor(' VNC/RFB '),
          contains('external VNC/RFB client'));
    });
  });
}
