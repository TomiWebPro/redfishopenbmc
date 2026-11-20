// EP-U8 / #009 / #021: cross-surface "Open console" affordance gating guard.
//
// The actionable "Open console" affordance is the operator's entry point to the
// (still WebView-less) detail viewer. It must be offered by the gated list card
// ONLY for a console the model reports as openable (`canOpenConsole == true`),
// and must never appear as a render/launch affordance on the detail viewer or
// the capability card — those surfaces are copy-only/display-only. Pinning this
// as one matrix across all three surfaces keeps a future edit from reintroducing
// a dead-end "Open console" action for a no-URI, BMC-disabled or fail-closed
// control-unsafe console. Display-only, dependency-free, TLS-safe: no URL is
// opened, no WebView/protocol plugin is imported and production TLS is untouched.

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
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op so KvmView can be pre-seeded
/// without touching the network (mirrors the established widget-test stub).
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

KvmConsole _console({
  required String managerId,
  String? uri,
  bool enabled = true,
  KvmConsoleType type = KvmConsoleType.graphical,
  List<String> types = const <String>['KVMIP'],
}) =>
    KvmConsole(
      type: type,
      managerId: managerId,
      connectTypesSupported: types,
      serviceEnabled: enabled,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/$managerId',
    );

Future<void> _pumpCard(
  WidgetTester tester,
  KvmConsole console, {
  double? width,
}) async {
  if (width != null) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EP-U8 gated-list-card affordance tracks canOpenConsole (#009/#021)',
      () {
    // (label, console, expected canOpenConsole). The plaintext-HTTP and VNC
    // cases are deliberately openable: the button opens the copy-only viewer,
    // never a WebView, so an external-client endpoint stays usable.
    final List<(String, KvmConsole, bool)> shapes =
        <(String, KvmConsole, bool)>[
      (
        'secure HTTPS graphical',
        _console(managerId: 'secure', uri: 'https://bmc.example/kvm'),
        true,
      ),
      (
        'secure HTTPS HTML5',
        _console(
          managerId: 'html5',
          uri: 'https://bmc.example/kvm',
          type: KvmConsoleType.remote,
          types: const <String>['HTML5'],
        ),
        true,
      ),
      (
        'VNC external client',
        _console(managerId: 'vnc', uri: 'vnc://bmc.example:5900'),
        true,
      ),
      (
        'plaintext HTTP (copy-only external use)',
        _console(managerId: 'plaintext', uri: 'http://bmc.example/kvm'),
        true,
      ),
      (
        'no URI',
        _console(managerId: 'nouri'),
        false,
      ),
      (
        'blank URI',
        _console(managerId: 'blank', uri: '   '),
        false,
      ),
      (
        'BMC-disabled with a connect URI',
        _console(
            managerId: 'disabled',
            uri: 'https://bmc.example/kvm',
            enabled: false),
        false,
      ),
      (
        'control-char-bearing HTTPS URI',
        _console(
          managerId: 'crlf',
          uri: 'https://bmc.example/kvm\r\nX-Injected: 1',
        ),
        false,
      ),
    ];

    for (final (String label, KvmConsole console, bool expected) in shapes) {
      testWidgets('"$label": "Open console" present iff canOpenConsole',
          (WidgetTester tester) async {
        expect(console.canOpenConsole, expected,
            reason: 'test matrix must agree with the model for $label');
        await _pumpCard(tester, console);

        final Finder openText = find.text('Open console');
        if (expected) {
          expect(openText, findsOneWidget,
              reason: '$label is openable and must offer the affordance');
          // Merged a11y: the visible label is the announced semantics label,
          // so a screen reader hears exactly what a sighted operator reads.
          expect(find.bySemanticsLabel('Open console'), findsOneWidget,
              reason: '$label affordance must be announced at a11y');
        } else {
          expect(openText, findsNothing,
              reason: '$label is not openable and must not offer a dead-end');
          expect(find.bySemanticsLabel('Open console'), findsNothing);
        }
        // Fail closed, not hidden: the endpoint stays visible and copyable on
        // every shape, including the ones with no launch affordance.
        expect(find.text('Copy connect info'), findsOneWidget,
            reason: '$label keeps its copy affordance');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'one openable + one non-openable console: affordance sits only '
        'on the openable card at 320/800/1300 px (#009/#021)',
        (WidgetTester tester) async {
      const KvmConsole openable = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'openable',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: true,
        connectUri: 'https://bmc.example/kvm',
        sourceManagerUri: '/redfish/v1/Managers/openable',
      );
      const KvmConsole notOpenable = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'notOpenable',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: false,
        connectUri: 'https://bmc.example/kvm',
        sourceManagerUri: '/redfish/v1/Managers/notOpenable',
      );
      expect(openable.canOpenConsole, isTrue);
      expect(notOpenable.canOpenConsole, isFalse);

      for (final double width in <double>[320, 800, 1300]) {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final KvmController controller = _StubController()
          ..state = KvmUiState(
            consoles: <KvmConsole>[openable, notOpenable],
            primaryConsole: KvmService.pickPrimary(<KvmConsole>[
              openable,
              notOpenable,
            ]),
          );
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              systemHandleProvider('bmc1').overrideWithValue(_handle()),
              kvmControllerProvider.overrideWith((ref, id) => controller),
            ],
            child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Open console'), findsOneWidget,
            reason: 'exactly one openable card at $width px');
        final Finder openCard = find.ancestor(
          of: find.text('Open console'),
          matching: find.byType(Card),
        );
        expect(
          find.descendant(
            of: openCard,
            matching: find.text('Manager: openable'),
          ),
          findsOneWidget,
          reason: 'the affordance must sit on the openable card at $width px',
        );
        expect(tester.takeException(), isNull,
            reason: 'no overflow at $width px');
      }
    });
  });

  group('EP-U8 viewer / capability card are never launch surfaces (#009/#021)',
      () {
    testWidgets(
        'the detail viewer offers copy + disconnect, never an '
        '"Open console"/render launch', (WidgetTester tester) async {
      for (final KvmConsole console in <KvmConsole>[
        _console(managerId: 'secure', uri: 'https://bmc.example/kvm'),
        _console(managerId: 'plaintext', uri: 'http://bmc.example/kvm'),
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: KvmConsoleViewerPage(console: console),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The viewer is the destination: it never offers another "Open console"
        // action or an in-app render button — only copy of the fail-closed
        // target plus session disconnect.
        expect(find.text('Open console'), findsNothing,
            reason: 'viewer is not a launcher for ${console.managerId}');
        expect(find.text('Copy console URI'), findsOneWidget);
        expect(find.byKey(const Key('kvm-disconnect-console')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'a control-char target renders no copy affordance on the '
        'viewer (fail-closed target gate)', (WidgetTester tester) async {
      final KvmConsole console = _console(
        managerId: 'crlf',
        uri: 'https://bmc.example/kvm\r\nX-Injected: 1',
      );
      expect(console.launchPlan.targetUri, isNull);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: KvmConsoleViewerPage(console: console)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open console'), findsNothing);
      // No control-safe target → no clipboard affordance carries the injection.
      expect(find.text('Copy console URI'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the capability card is display-only: no "Open console" '
        'button for secure, insecure or disabled capabilities',
        (WidgetTester tester) async {
      const List<KvmCapability> capabilities = <KvmCapability>[
        KvmCapability(
          managerId: 'secure',
          supported: true,
          connectTypes: <String>['KVMIP'],
          serviceEnabled: true,
          uri: 'https://bmc.example/kvm',
          sourceManagerUri: '/redfish/v1/Managers/secure',
        ),
        KvmCapability(
          managerId: 'insecure',
          supported: true,
          connectTypes: <String>['HTML5'],
          serviceEnabled: true,
          uri: 'http://bmc.example/kvm',
          sourceManagerUri: '/redfish/v1/Managers/insecure',
        ),
        KvmCapability(
          managerId: 'disabled',
          supported: true,
          connectTypes: <String>['KVMIP'],
          serviceEnabled: false,
          uri: 'https://bmc.example/kvm',
          sourceManagerUri: '/redfish/v1/Managers/disabled',
        ),
      ];
      for (final KvmCapability capability in capabilities) {
        await tester.pumpWidget(
          MaterialApp(home: KvmCapabilityCard(capability: capability)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Open console'), findsNothing,
            reason:
                'capability card must not launch for ${capability.managerId}');
        expect(find.byType(FilledButton), findsNothing,
            reason: 'capability card is display-only');
        expect(tester.takeException(), isNull);
      }
    });
  });
}
