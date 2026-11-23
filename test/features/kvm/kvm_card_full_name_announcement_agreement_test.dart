// EP-U23 (issues #009 / #021): full-name announcement agreement under visual
// truncation across the KVM operator cards and the console viewer.
//
// AUDIT FIRST: all three surfaces already build their merged `excludeSemantics`
// label AND their visible Text from the same full `${managerId}` model string —
// the per-console card's "Manager: <id>" row and the capability card's
// "Manager capability: <id>" header in kvm_view.dart / kvm_capability_card.dart,
// and the viewer's "<type> · Manager <id>" header in kvm_console_viewer_page.dart.
// A name that visually wraps/clips on a 320 px viewport is never truncated in
// the model, so there is NO live divergence here; this is a characterization /
// regression lock, not a behaviour change.
//
// Genuine unguarded seam: no test drives a long, visually-wrapping name through
// BOTH real cards AND the viewer at once while pinning that (a) each merged node
// announces the FULL name byte-for-byte, (b) the full name is visible exactly
// once as a single rendered instance (no clipped visible copy), (c) no second
// screen-reader-only Semantics node carries the name, and (d) no RenderFlex
// overflow occurs at 320 / 800 / 1300 px. A one-sided edit that feeds clipped
// text into a label, splits the merged node, or adds a duplicate copy would pass
// every short-name suite but break this guard (the exact #009 divergence class).
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
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Long, word-breakable (hyphenated) rack id that visually wraps on a 320 px
/// viewport. The merged a11y label must still carry the WHOLE string.
const String kTruncLongName =
    'BMC-Rack42-ChassisA-Slot07-Node03-Management-Controller-Building5';

/// Short control name: pins that the long-name card and a normal card do not
/// bleed into one another on either surface.
const String kTruncShortName = 'BMC';

const String kTruncUri = 'https://bmc.example/html5';

Map<String, dynamic> _body() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': kTruncUri,
        'MaxConcurrentSessions': 2,
      },
    };

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

/// Pumps the real `KvmView`, which builds BOTH the capability card and every
/// per-console card from the same manager bodies used by production. A long-name
/// manager and a short-name control manager are rendered in the same tree.
Future<void> _pumpCards(
  WidgetTester tester, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _body();
  final List<KvmConsole> consoles = <KvmConsole>[
    ...KvmConsole.fromManager(body, managerId: kTruncLongName),
    ...KvmConsole.fromManager(body, managerId: kTruncShortName),
  ];
  final List<KvmCapability> capabilities = <KvmCapability>[
    KvmCapability.fromManager(body, managerId: kTruncLongName),
    KvmCapability.fromManager(body, managerId: kTruncShortName),
  ];
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
          (ref, id) => Future<List<KvmCapability>>.value(capabilities),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required KvmConsole console,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 1500);
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
      child: MaterialApp(home: KvmConsoleViewerPage(console: console)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every Semantics widget whose announced label contains [needle]. Used to
/// detect a split / duplicate / screen-reader-only copy of the manager name.
Finder _nameNodes(String needle) => find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics && (w.properties.label?.contains(needle) ?? false),
    );

void main() {
  final Map<String, dynamic> body = _body();
  final List<KvmConsole> consoles = KvmConsole.fromManager(
    body,
    managerId: kTruncLongName,
  );
  final KvmConsole longNameConsole = consoles.first;

  group('EP-U23 full-name announcement under visual truncation (#009/#021)',
      () {
    for (final double width in <double>[320, 800, 1300]) {
      final String at = '${width.toStringAsFixed(0)}px';

      testWidgets(
        'both operator cards announce the FULL name byte-for-byte at $at',
        (WidgetTester tester) async {
          await _pumpCards(tester, width: width);

          // Each merged node carries the WHOLE name, not a clipped form.
          expect(
              find.bySemanticsLabel('Manager: $kTruncLongName'), findsOneWidget,
              reason: '$at: console card full-name merged node');
          expect(find.bySemanticsLabel('Manager: $kTruncShortName'),
              findsOneWidget,
              reason: '$at: short control keeps its own merged node');
          expect(
            find.bySemanticsLabel(
              'Manager capability $kTruncLongName, enabled, KVM supported',
            ),
            findsOneWidget,
            reason: '$at: capability card full-name merged node',
          );
          expect(
            find.bySemanticsLabel(
              'Manager capability $kTruncShortName, enabled, KVM supported',
            ),
            findsOneWidget,
            reason: '$at: capability card short control node',
          );

          // Visible text is the SAME full name, rendered exactly once per card.
          final Finder capability = find.byType(KvmCapabilityCard);
          expect(capability, findsNWidgets(2),
              reason: '$at: two capability cards');
          expect(find.text('Manager: $kTruncLongName'), findsOneWidget,
              reason: '$at: one full visible console-card name');
          expect(
            find.descendant(
              of: capability,
              matching: find.text('Manager capability: $kTruncLongName'),
            ),
            findsOneWidget,
            reason: '$at: one full visible capability-card name',
          );

          // No split / duplicate / screen-reader-only node carries the name:
          // exactly one console-card node + one capability-card node.
          expect(_nameNodes(kTruncLongName).evaluate().length, 2,
              reason: '$at: no duplicate or screen-reader-only name node');

          expect(tester.takeException(), isNull,
              reason: '$at: both cards render without RenderFlex overflow');
        },
      );

      testWidgets('viewer announces and displays the FULL name at $at',
          (WidgetTester tester) async {
        await _pumpViewer(tester, console: longNameConsole, width: width);

        final String header = '${longNameConsole.type.label}, manager '
            '$kTruncLongName';
        final String visible = '${longNameConsole.type.label} · Manager '
            '$kTruncLongName';
        expect(find.bySemanticsLabel(header), findsOneWidget,
            reason: '$at: viewer merged full-name header');
        expect(find.text(visible), findsOneWidget,
            reason: '$at: one full visible viewer header name');
        expect(_nameNodes(kTruncLongName).evaluate().length, 1,
            reason: '$at: no duplicate or screen-reader-only viewer name node');
        expect(tester.takeException(), isNull,
            reason: '$at: viewer renders without RenderFlex overflow');
      });
    }
  });
}
