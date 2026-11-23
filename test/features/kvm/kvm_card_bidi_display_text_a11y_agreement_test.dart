// EP-U22 (issues #009 / #021): bidirectional / RTL display-text rendering
// agreement across both KVM operator cards and the console viewer.
//
// AUDIT FIRST: the model deliberately keeps the manager id BYTE-EXACT (no
// Unicode sanitisation anywhere in `lib/features/kvm/models/**` or
// `lib/features/kvm/views/**`), and every surface builds its visible Text AND
// its single merged `excludeSemantics` label from that same raw `${managerId}`
// string — the per-console card's "Manager: <id>" row and the capability
// card's "Manager capability <id>, …" header in kvm_view.dart /
// kvm_capability_card.dart, and the viewer's "<type>, manager <id>" header in
// kvm_console_viewer_page.dart. So a bidi / RTL-control-bearing name reaches
// the widgets verbatim and there is NO live divergence here: this is a
// characterization / regression lock, not a behaviour change.
//
// Genuine unguarded seam: EP-U23/EP-U20/EP-U25 pin long / extreme / badge
// display text, and the model guards pin bidi controls only in `@odata.id`
// URIs — but NOTHING drives a bidi / RTL control-bearing DISPLAY NAME (RLO/LRO,
// isolates, word-joiner) through BOTH real cards AND the viewer at once while
// pinning that (a) the merged node announces the FULL byte-exact name, (b) the
// full name is visible exactly once as a single rendered instance, (c) no
// second screen-reader-only Semantics node carries the name (no mirror-induced
// node split / duplicate), and (d) no RenderFlex overflow occurs at 320 / 800
// / 1300 px. A one-sided edit that sanitises/clips a label, splits the merged
// node, or adds a duplicate copy under bidi text would pass every plain-LTR
// suite but break this guard (the exact #009 divergence class).
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

/// A display name carrying the full bidi control family: RLO (U+202E) + PDF
/// (U+202C), LRI (U+2066) + RLI (U+2067) + PDI (U+2069), and a word-joiner
/// (U+2060). The classic "BMC\u202Eevil.example\u202C" RLO spoof shape makes a
/// byte-exact merged node essential: a screen reader must announce the raw
/// string, never a visually-reordered or stripped form.
const String kBidiName =
    'BMC\u202Eevil.example\u202C-\u2066Rack\u2067Node\u2069\u2069\u2060Console';

/// Classic LRO (U+202D) + PDF override as a second bidi spell, plus a short
/// plain-LTR control name that must not bleed into the bidi cards.
const String kBidiLroName = '\u202DNode42\u202C-BMC';
const String kBidiShortName = 'BMC';

const String kBidiUri = 'https://bmc.example/html5';

Map<String, dynamic> _body() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': kBidiUri,
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
/// per-console card from the same manager bodies used by production. Three
/// managers (two bidi spellings + one plain control) are rendered together.
Future<void> _pumpCards(
  WidgetTester tester, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _body();
  final List<String> ids = <String>[
    kBidiName,
    kBidiLroName,
    kBidiShortName,
  ];
  final List<KvmConsole> consoles = <KvmConsole>[
    for (final String id in ids) ...KvmConsole.fromManager(body, managerId: id),
  ];
  final List<KvmCapability> capabilities = <KvmCapability>[
    for (final String id in ids) KvmCapability.fromManager(body, managerId: id),
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
/// detect a split / duplicate / screen-reader-only copy of the bidi name.
Finder _nameNodes(String needle) => find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics && (w.properties.label?.contains(needle) ?? false),
    );

void main() {
  final Map<String, dynamic> body = _body();
  final KvmConsole bidiConsole = KvmConsole.fromManager(
    body,
    managerId: kBidiName,
  ).first;

  group('EP-U22 bidi display-text a11y agreement (#009/#021)', () {
    // byte-exact augmented 7-bit check: the raw control code points reach the
    // widgets and are never folded away by a display sanitizer.
    test('the bidi fixture really carries RLO/LRO/isolates/word-joiner', () {
      expect(kBidiName.codeUnits, contains(0x202E)); // RLO
      expect(kBidiName.codeUnits, contains(0x202C)); // PDF
      expect(kBidiName.codeUnits, contains(0x2066)); // LRI
      expect(kBidiName.codeUnits, contains(0x2067)); // RLI
      expect(kBidiName.codeUnits, contains(0x2069)); // PDI
      expect(kBidiName.codeUnits, contains(0x2060)); // word joiner
      expect(kBidiLroName.codeUnits, contains(0x202D)); // LRO
      expect(bidiConsole.managerId, kBidiName,
          reason: 'model keeps the display name byte-exact');
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String at = '${width.toStringAsFixed(0)}px';

      testWidgets(
        'both operator cards announce the FULL bidi name byte-for-byte at $at',
        (WidgetTester tester) async {
          await _pumpCards(tester, width: width);

          // Each merged node carries the WHOLE raw name, not a sanitised /
          // reordered / clipped form — on both bidi spellings and the control.
          for (final String id in <String>[
            kBidiName,
            kBidiLroName,
            kBidiShortName,
          ]) {
            expect(find.bySemanticsLabel('Manager: $id'), findsOneWidget,
                reason: '$at: console card full bidi-name merged node ($id)');
            expect(
              find.bySemanticsLabel(
                'Manager capability $id, enabled, KVM supported',
              ),
              findsOneWidget,
              reason: '$at: capability card full bidi-name merged node ($id)',
            );
          }

          // Visible text is the SAME raw name, rendered exactly once per card.
          final Finder capability = find.byType(KvmCapabilityCard);
          expect(capability, findsNWidgets(3),
              reason: '$at: three capability cards');
          for (final String id in <String>[
            kBidiName,
            kBidiLroName,
            kBidiShortName,
          ]) {
            expect(find.text('Manager: $id'), findsOneWidget,
                reason: '$at: one visible console-card name ($id)');
            expect(
              find.descendant(
                of: capability,
                matching: find.text('Manager capability: $id'),
              ),
              findsOneWidget,
              reason: '$at: one visible capability-card name ($id)',
            );
          }

          // No split / duplicate / screen-reader-only node carries the bidi
          // name: exactly one console-card node + one capability-card node.
          expect(_nameNodes(kBidiName).evaluate().length, 2,
              reason: '$at: no duplicate/screen-reader-only bidi name node');
          expect(_nameNodes(kBidiLroName).evaluate().length, 2,
              reason: '$at: no duplicate/screen-reader-only LRO name node');

          expect(tester.takeException(), isNull,
              reason: '$at: both cards render bidi text without overflow');
        },
      );

      testWidgets('viewer announces and displays the FULL bidi name at $at',
          (WidgetTester tester) async {
        await _pumpViewer(tester, console: bidiConsole, width: width);

        final String header = '${bidiConsole.type.label}, manager $kBidiName';
        final String visible = '${bidiConsole.type.label} · Manager $kBidiName';
        expect(find.bySemanticsLabel(header), findsOneWidget,
            reason: '$at: viewer merged full bidi-name header');
        expect(find.text(visible), findsOneWidget,
            reason: '$at: one full visible viewer bidi-name header');
        expect(_nameNodes(kBidiName).evaluate().length, 1,
            reason: '$at: no duplicate/screen-reader-only viewer bidi node');
        expect(tester.takeException(), isNull,
            reason: '$at: viewer renders bidi text without overflow');
      });
    }
  });
}
