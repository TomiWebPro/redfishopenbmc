// EP-U30 (issues #009 / #021): C0-control / Unicode-separator display-text
// rendering agreement across both KVM operator cards and the console viewer.
//
// AUDIT FIRST: the model deliberately keeps the manager id BYTE-EXACT (no
// Unicode sanitisation anywhere in `lib/features/kvm/models/**` or
// `lib/features/kvm/views/**`), and every surface builds its visible Text AND
// its single merged `excludeSemantics` label from that same raw `${managerId}`
// string — the per-console card's "Manager: <id>" row (kvm_view.dart) and the
// capability card's "Manager capability: <id>" header
// (kvm_capability_card.dart), and the viewer's "<type> · Manager <id>" header
// (kvm_console_viewer_page.dart). So a hostile display name reaches the widgets
// verbatim and there is NO live divergence here: this is a characterization /
// regression lock, not a behaviour change.
//
// Genuine unguarded seam: EP-U22 drives bidi / RTL FORMAT marks (RLO/LRO,
// isolates, word-joiner — Unicode category Cf) through the three surfaces,
// EP-U23 a long wrapping name, EP-U29 a blank / whitespace-only label, and the
// model guards pin C0/separator controls only in `@odata.id` URIs and connect
// tokens — but NOTHING drives the distinct C0 CONTROL (CR / LF / TAB / NUL /
// DEL / ESC — Unicode category Cc) and Unicode LINE/PARAGRAPH SEPARATOR (U+2028
// / U+2029 — categories Zl / Zp) family through a DISPLAY NAME at once. That
// family is special: unlike bidi marks it actually changes `Text` line layout
// (CR/LF/LS/PS force new lines), so a plausible one-sided "normalise the label
// whitespace" / "strip control chars in the announcement" edit could collapse
// the merged node text on ONE surface while every plain-LTR and bidi suite
// stayed GREEN — the exact #009 cross-surface divergence class. This guard
// pins (a) the merged node announces the FULL byte-exact name, (b) the full name
// is visible exactly once as a single rendered instance, (c) no second
// screen-reader-only Semantics node carries the name, and (d) no RenderFlex
// overflow occurs at 320 / 800 / 1300 px.
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

/// A display name carrying the C0 control family: CR (0x0D), LF (0x0A),
/// TAB (0x09), NUL (0x00), DEL (0x7F) and ESC (0x1B) — plus a classic ANSI
/// escape-injection shape ("ESC[31m"). A byte-exact merged node is essential:
/// a screen reader must announce the raw string, never a whitespace-normalised
/// or control-stripped form.
const String kC0Name = 'BMC\r\nRack\x00142\tSlot\x7F7\x1B[31mConsole';

/// The Unicode separator family: LINE SEPARATOR (U+2028, Zl), PARAGRAPH
/// SEPARATOR (U+2029, Zp) and NO-BREAK SPACE (U+00A0, Zs) — all treated as
/// separators by the shared URI control-safety gate, and all line/space
/// significant to `Text` layout.
const String kSeparatorName = 'BMC\u2028Rack\u2029Node\u00A0Console';

/// Short plain-LTR control name that must not bleed into the hostile cards.
const String kC0ShortName = 'BMC';

const String kC0Uri = 'https://bmc.example/html5';

Map<String, dynamic> _body() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': kC0Uri,
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
/// managers (two hostile spellings + one plain control) are rendered together.
Future<void> _pumpCards(
  WidgetTester tester, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _body();
  final List<String> ids = <String>[
    kC0Name,
    kSeparatorName,
    kC0ShortName,
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
/// detect a split / duplicate / screen-reader-only copy of the hostile name.
Finder _nameNodes(String needle) => find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics && (w.properties.label?.contains(needle) ?? false),
    );

void main() {
  final Map<String, dynamic> body = _body();
  final KvmConsole c0Console = KvmConsole.fromManager(
    body,
    managerId: kC0Name,
  ).first;
  final KvmConsole separatorConsole = KvmConsole.fromManager(
    body,
    managerId: kSeparatorName,
  ).first;

  group('EP-U30 C0/separator display-text a11y agreement (#009/#021)', () {
    // byte-exact code-point check: the raw controls reach the widgets and are
    // never folded away by a display sanitizer.
    test('the fixtures really carry C0 controls and line/paragraph separators',
        () {
      for (final int cp in <int>[
        0x0D, // CR
        0x0A, // LF
        0x09, // TAB
        0x00, // NUL
        0x7F, // DEL
        0x1B, // ESC
      ]) {
        expect(kC0Name.codeUnits, contains(cp),
            reason: 'C0 fixture must carry U+${cp.toRadixString(16)}');
      }
      expect(kSeparatorName.codeUnits, contains(0x2028)); // LINE SEPARATOR
      expect(kSeparatorName.codeUnits, contains(0x2029)); // PARA SEPARATOR
      expect(kSeparatorName.codeUnits, contains(0x00A0)); // NO-BREAK SPACE
      expect(c0Console.managerId, kC0Name,
          reason: 'model keeps the display name byte-exact');
      expect(separatorConsole.managerId, kSeparatorName,
          reason: 'model keeps the display name byte-exact');
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String at = '${width.toStringAsFixed(0)}px';

      testWidgets(
        'both operator cards announce the FULL hostile name byte-for-byte at $at',
        (WidgetTester tester) async {
          await _pumpCards(tester, width: width);

          // Each merged node carries the WHOLE raw name, not a sanitised /
          // whitespace-normalised / control-stripped / clipped form — on both
          // hostile spellings and the control.
          for (final String id in <String>[
            kC0Name,
            kSeparatorName,
            kC0ShortName,
          ]) {
            expect(find.bySemanticsLabel('Manager: $id'), findsOneWidget,
                reason:
                    '$at: console card full hostile-name merged node ($id)');
            expect(
              find.bySemanticsLabel(
                'Manager capability $id, enabled, KVM supported',
              ),
              findsOneWidget,
              reason:
                  '$at: capability card full hostile-name merged node ($id)',
            );
          }

          // Visible text is the SAME raw name, rendered exactly once per card.
          final Finder capability = find.byType(KvmCapabilityCard);
          expect(capability, findsNWidgets(3),
              reason: '$at: three capability cards');
          for (final String id in <String>[
            kC0Name,
            kSeparatorName,
            kC0ShortName,
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

          // No split / duplicate / screen-reader-only node carries the hostile
          // name: exactly one console-card node + one capability-card node.
          expect(_nameNodes(kC0Name).evaluate().length, 2,
              reason: '$at: no duplicate/screen-reader-only C0 name node');
          expect(_nameNodes(kSeparatorName).evaluate().length, 2,
              reason:
                  '$at: no duplicate/screen-reader-only separator name node');

          expect(tester.takeException(), isNull,
              reason:
                  '$at: both cards render C0/separator text without overflow');
        },
      );

      for (final MapEntry<String, KvmConsole> caseData in <String, KvmConsole>{
        'C0': c0Console,
        'separator': separatorConsole,
      }.entries) {
        testWidgets(
            'viewer announces and displays the FULL ${caseData.key} '
            'name at $at', (WidgetTester tester) async {
          final KvmConsole console = caseData.value;
          await _pumpViewer(tester, console: console, width: width);

          final String id = console.managerId;
          final String header = '${console.type.label}, manager $id';
          final String visible = '${console.type.label} · Manager $id';
          expect(find.bySemanticsLabel(header), findsOneWidget,
              reason: '$at: viewer merged full hostile-name header');
          expect(find.text(visible), findsOneWidget,
              reason: '$at: one full visible viewer hostile-name header');
          expect(_nameNodes(id).evaluate().length, 1,
              reason: '$at: no duplicate/screen-reader-only viewer node');
          expect(tester.takeException(), isNull,
              reason: '$at: viewer renders C0/separator text without overflow');
        });
      }
    }
  });
}
