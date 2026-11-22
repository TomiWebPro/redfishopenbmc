// EP-U21 (issues #009 / #021): large-accessibility-font no-overflow + one
// merged a11y node per signal across BOTH KVM operator cards and the viewer.
//
// EP-U20 pins extreme content at a FIXED font and EP-U8/EP-U7 pin narrow-width
// overflow and notice a11y. The existing test/a11y/kvm_view_text_scale_test.dart
// pumps only an EMPTY KvmView ("No consoles found.") at 2.0x, and
// a11y/power_view_text_scale_test.dart covers the PowerView — neither exercises
// a console-card or viewer row under a text scaler. A one-sided view edit
// (splitting a merged `excludeSemantics` node, or announcing screen-reader-only
// wording) could break large-font use of the operator surfaces while every
// fixed-font suite stayed GREEN — the exact #009 divergence class.
//
// This guard pumps ONE manager with a long name, an enabled secure-HTTPS
// console and an enabled external-client (SSH) console through both real cards
// and the viewer at 1.0 / 1.3 / 2.0 text scale on a 320 px viewport, and fails
// closed on any RenderFlex overflow, duplicate notice or visible!=announced
// merged node.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol dependency is imported, and production TLS is untouched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A long but word-breakable rack/chassis/slot id (hyphens are break points).
const String kLargeFontManagerId =
    'BMC-Rack42-ChassisA-Slot07-Node03-Management-Controller';

/// A long, control-safe canonical HTTPS endpoint (no raw control chars).
const String kLargeFontSecureUri =
    'https://bmc-management.example.com/redfish/v1/Managers/BMC/'
    'GraphicalConsole/console?session=abcdef0123456789abcdef0123456789';

/// A non-HTTP endpoint whose transport requires an external client.
const String kLargeFontSshUri = 'ssh://bmc-management.example.com/serial';

class _StubController extends KvmController {
  _StubController()
      : super(service: KvmService(client: null, systemId: 'bmc1'));

  @override
  Future<void> load() async {}
}

SystemHandle _handle() => const SystemHandle(
      profile: ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: true),
    );

/// One manager: an enabled secure-HTTPS Graphical console plus an enabled SSH
/// Serial console, both under [kLargeFontManagerId].
Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': kLargeFontSecureUri,
        'MaxConcurrentSessions': 2,
      },
      'SerialConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectUri': kLargeFontSshUri,
      },
    };

/// Applies the platform accessibility font before the surface under test.
Widget _withTextScale(Widget child, double scale) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: child,
    );

Future<void> _pumpCards(
  WidgetTester tester, {
  required double scale,
}) async {
  tester.view.physicalSize = const Size(320, 12000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _managerBody();
  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: kLargeFontManagerId);
  final KvmCapability capability =
      KvmCapability.fromManager(body, managerId: kLargeFontManagerId);
  final KvmController controller = _StubController()
    ..state = KvmUiState(
      consoles: consoles,
      primaryConsole: KvmService.pickPrimary(consoles),
    );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) =>
              Future<List<KvmCapability>>.value(<KvmCapability>[capability]),
        ),
      ],
      child: MaterialApp(
        home: _withTextScale(const KvmView(systemId: 'bmc1'), scale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required KvmConsole console,
  required double scale,
}) async {
  tester.view.physicalSize = const Size(320, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
      ],
      child: MaterialApp(
        home: _withTextScale(KvmConsoleViewerPage(console: console), scale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _cardOf(Finder signal) =>
    find.ancestor(of: signal, matching: find.byType(Card));

/// One merged node announces [text], the SAME text is visible once inside it,
/// and no second (screen-reader-only or duplicate) copy exists on the surface.
void _expectOneMergedNotice(Finder surface, String text, String where) {
  final Finder node = find.descendant(
    of: surface,
    matching: find.bySemanticsLabel(text),
  );
  expect(node, findsOneWidget,
      reason: '$where: exactly one merged node for "$text"');
  expect(find.descendant(of: node, matching: find.text(text)), findsOneWidget,
      reason: '$where: visible text must equal the announced label');
  expect(
      find.descendant(of: surface, matching: find.text(text)), findsOneWidget,
      reason: '$where: no duplicate or screen-reader-only copy');
}

void main() {
  final Map<String, dynamic> body = _managerBody();
  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: kLargeFontManagerId);
  final KvmConsole graphical = consoles.firstWhere(
    (KvmConsole c) => c.type == KvmConsoleType.graphical,
  );
  final KvmConsole serial = consoles.firstWhere(
    (KvmConsole c) => c.type == KvmConsoleType.serial,
  );
  final String sshNotice = kvmExternalClientNoticeFor(
    serial.externalClientProtocolLabel,
  );

  group('EP-U21 large-font cross-surface a11y (#009/#021)', () {
    for (final double scale in <double>[1.0, 1.3, 2.0]) {
      final String at = '${scale}x/320px';

      testWidgets('both operator cards stay merged and overflow-free at $at',
          (WidgetTester tester) async {
        await _pumpCards(tester, scale: scale);

        final Finder capability = find.byType(KvmCapabilityCard);
        expect(capability, findsOneWidget);
        expect(
          find.bySemanticsLabel('Manager: $kLargeFontManagerId'),
          findsNWidgets(2),
          reason: '$at: one long-name node on each console card',
        );

        // The security-first resolved endpoint is on BOTH cards, byte-identical,
        // at every scale (a font change must not change the launch target).
        expect(
          find.descendant(
            of: capability,
            matching:
                find.bySemanticsLabel('Resolved URI: $kLargeFontSecureUri'),
          ),
          findsOneWidget,
          reason: '$at: capability resolved URI',
        );
        final Finder graphicalCard = _cardOf(
          find.bySemanticsLabel('Connect URI: $kLargeFontSecureUri'),
        );
        expect(graphicalCard, findsOneWidget,
            reason: '$at: secure console card');
        expect(
          find.byWidgetPredicate(
            (Widget w) => w is SelectableText && w.data == kLargeFontSecureUri,
          ),
          findsNWidgets(2),
          reason: '$at: same visible secure URI on both cards only',
        );

        // The SSH console carries exactly one protocol-specific notice: merged,
        // visible == announced, and not duplicated in a screen-reader-only node.
        final Finder serialCard = _cardOf(find.bySemanticsLabel(sshNotice));
        expect(serialCard, findsOneWidget,
            reason: '$at: external-client console card');
        _expectOneMergedNotice(serialCard, sshNotice, '$at serial card');
        expect(
          find.descendant(
            of: serialCard,
            matching: find.bySemanticsLabel('Connect URI: $kLargeFontSshUri'),
          ),
          findsOneWidget,
          reason: '$at: SSH URI stays on its own card',
        );
        expect(
          find.descendant(
            of: capability,
            matching: find.bySemanticsLabel(sshNotice),
          ),
          findsNothing,
          reason: '$at: secure resolved endpoint must not gain an external '
              'notice',
        );

        expect(tester.takeException(), isNull,
            reason: '$at: both cards must render without RenderFlex overflow');
      });

      testWidgets('viewer stays merged and overflow-free at $at',
          (WidgetTester tester) async {
        for (final KvmConsole console in <KvmConsole>[graphical, serial]) {
          await _pumpViewer(tester, console: console, scale: scale);

          final String status = kvmLaunchStatusText(
            console.launchStrategy,
            externalProtocol: console.externalClientProtocolLabel,
          );
          expect(
            find.bySemanticsLabel(
                '${console.type.label}, manager $kLargeFontManagerId'),
            findsOneWidget,
            reason: '$at ${console.type.label}: merged header',
          );
          _expectOneMergedNotice(find.byType(Scaffold), status,
              '$at ${console.type.label} viewer');
          // The viewer auto-connects a pure-UI session on the first frame, so
          // the session notice may be active or idle; either way it is ONE
          // merged node whose visible text equals its announced label.
          final Finder sessionNode = find.descendant(
            of: find.byType(Scaffold),
            matching: find.bySemanticsLabel(RegExp(
              '${RegExp.escape(kvmSessionActiveNotice)}|'
              '${RegExp.escape(kvmSessionIdleNotice)}',
            )),
          );
          expect(sessionNode, findsOneWidget,
              reason: '$at ${console.type.label}: one merged session notice');
          final String sessionLabel = tester.getSemantics(sessionNode).label;
          _expectOneMergedNotice(find.byType(Scaffold), sessionLabel,
              '$at ${console.type.label} viewer');
          expect(
            find.bySemanticsLabel(
                'Console URI: ${console.launchPlan.targetUri}'),
            findsOneWidget,
            reason: '$at ${console.type.label}: one merged console-URI row',
          );
          expect(tester.takeException(), isNull,
              reason: '$at ${console.type.label}: viewer must render without '
                  'RenderFlex overflow');
        }
      });
    }
  });
}
