// EP-U33 (issues #009 / #021): COMPOUND a11y agreement across both KVM
// operator cards and the console viewer — a C0-control / Unicode
// line/paragraph-SEPARATOR DISPLAY NAME rendered under RTL layout AND a 2.0x
// accessibility text scaler.
//
// AUDIT FIRST: each axis is covered on its own but never in conjunction —
//   * EP-U30 pins the C0-control (Cc: CR/LF/TAB/NUL/DEL/ESC) and Unicode
//     line/paragraph-separator (Zl/Zp: U+2028/U+2029, + NBSP Zs) display-name
//     family through both cards + the viewer, but only at LTR / 1.0x;
//   * EP-U28 pins LTR/RTL on both cards + the viewer, but only with short
//     clean chips and a clean manager id at 1.0x;
//   * EP-U21 pins 1.0 / 1.3 / 2.0x on both cards + the viewer, but only with a
//     clean display name;
//   * EP-U31 pins an unbreakable chip x RTL x 2.0x (clean name), and EP-U32
//     pins a BIDI-FORMAT-mark (Cf) name x RTL x 2.0x — neither drives the
//     distinct Cc/Zl/Zp/Zs layout-changing family through RTL x 2.0x.
// A plausible one-sided "a name with embedded line/paragraph separators looks
// scrambled under RTL at large fonts; normalise the whitespace in the merged
// announcement" edit on ONE card would make its merged node announce a
// DIFFERENT (normalised) string than the byte-exact value still visible and
// still announced on the sibling card/viewer, while every single-axis suite
// stayed GREEN — the exact #009 cross-surface divergence class. This guard
// locks that, under the compound setting, both real cards and the viewer
// announce + display the FULL byte-exact control/separator name, keep one
// merged excludeSemantics node (no split / duplicate / screen-reader-only
// copy), and stay overflow-free at 320 / 800 / 1300 px. An LTR/1.0x control
// proves the compound setting changes nothing on an ordinary rendering.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol plugin is imported, and production TLS is untouched (#009/#021).
library;

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

/// The C0 control family: CR (0x0D), LF (0x0A), TAB (0x09), NUL (0x00),
/// DEL (0x7F) and ESC (0x1B) plus the classic ANSI-escape injection shape.
/// Byte-exact announcement matters: a screen reader must never hear a
/// whitespace-normalised / control-stripped form of the operator-visible name.
const String kCompoundC0Name = 'BMC\r\nRack\x00142\tSlot\x7F7\x1B[31mConsole';

/// The Unicode separator family: LINE SEPARATOR (U+2028, Zl), PARAGRAPH
/// SEPARATOR (U+2029, Zp) and NO-BREAK SPACE (U+00A0, Zs) — all line/space
/// significant to `Text` layout, so a normalising edit can desync one surface.
const String kCompoundSeparatorName = 'BMC\u2028Rack\u2029Node\u00A0Console';

/// Short plain-LTR control name that must stay byte-exact on every surface.
const String kCompoundPlainName = 'BMC';
const String kCompoundUri = 'https://bmc.example/html5';

Map<String, dynamic> _body() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': kCompoundUri,
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

const List<String> kCompoundIds = <String>[
  kCompoundC0Name,
  kCompoundSeparatorName,
  kCompoundPlainName,
];

/// Applies both compound axes: RTL direction and the given text scaler.
Widget _withAxes(Widget child, TextDirection direction, double scale) =>
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: direction, child: child),
    );

Future<void> _pumpCards(
  WidgetTester tester, {
  required double width,
  required TextDirection direction,
  required double scale,
}) async {
  // Tall enough that 2.0x-scaled headers (incl. embedded line separators)
  // cannot push a later card below the viewport — Flutter only builds visible
  // list children.
  tester.view.physicalSize = Size(width, 9000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _body();
  final List<KvmConsole> consoles = <KvmConsole>[
    for (final String id in kCompoundIds)
      ...KvmConsole.fromManager(body, managerId: id),
  ];
  final List<KvmCapability> capabilities = <KvmCapability>[
    for (final String id in kCompoundIds)
      KvmCapability.fromManager(body, managerId: id),
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
      child: MaterialApp(
        home: _withAxes(const KvmView(systemId: 'bmc1'), direction, scale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required KvmConsole console,
  required double width,
  required TextDirection direction,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 2500);
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
        home:
            _withAxes(KvmConsoleViewerPage(console: console), direction, scale),
      ),
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
    managerId: kCompoundC0Name,
  ).first;
  final KvmConsole separatorConsole = KvmConsole.fromManager(
    body,
    managerId: kCompoundSeparatorName,
  ).first;

  group('EP-U33 C0/separator name x RTL x 2.0x a11y agreement (#009/#021)', () {
    test(
        'fixtures carry Cc/Zl/Zp/Zs controls and both projections keep the '
        'names byte-exact', () {
      for (final int cp in <int>[
        0x0D, // CR
        0x0A, // LF
        0x09, // TAB
        0x00, // NUL
        0x7F, // DEL
        0x1B, // ESC
      ]) {
        expect(kCompoundC0Name.codeUnits, contains(cp),
            reason: 'C0 fixture must carry U+${cp.toRadixString(16)}');
      }
      expect(kCompoundSeparatorName.codeUnits, contains(0x2028)); // Zl
      expect(kCompoundSeparatorName.codeUnits, contains(0x2029)); // Zp
      expect(kCompoundSeparatorName.codeUnits, contains(0x00A0)); // Zs
      expect(c0Console.managerId, kCompoundC0Name,
          reason: 'console model keeps the display name byte-exact');
      expect(separatorConsole.managerId, kCompoundSeparatorName,
          reason: 'console model keeps the display name byte-exact');
      expect(
        KvmCapability.fromManager(body, managerId: kCompoundC0Name).managerId,
        kCompoundC0Name,
        reason: 'capability projection keeps the C0 name byte-exact',
      );
      expect(
        KvmCapability.fromManager(body, managerId: kCompoundSeparatorName)
            .managerId,
        kCompoundSeparatorName,
        reason: 'capability projection keeps the separator name byte-exact',
      );
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards announce + display the FULL hostile names byte-exact '
        'under RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'RTL/2.0x overflow at $px');

          // Each merged node carries the WHOLE raw name, not a normalised /
          // whitespace-stripped form — on both hostile spellings + the control.
          for (final String id in kCompoundIds) {
            expect(find.bySemanticsLabel('Manager: $id'), findsOneWidget,
                reason: '$px console card full hostile-name merged node ($id)');
            expect(
              find.bySemanticsLabel(
                'Manager capability $id, enabled, KVM supported',
              ),
              findsOneWidget,
              reason: '$px capability card full hostile-name merged node ($id)',
            );
            expect(find.text('Manager: $id'), findsOneWidget,
                reason: '$px one visible console-card name ($id)');
            expect(
              find.descendant(
                of: find.byType(KvmCapabilityCard),
                matching: find.text('Manager capability: $id'),
              ),
              findsOneWidget,
              reason: '$px one visible capability-card name ($id)',
            );
          }

          // No split / duplicate / screen-reader-only node carries the name:
          // exactly one console-card node + one capability-card node each.
          expect(_nameNodes(kCompoundC0Name).evaluate().length, 2,
              reason: '$px no duplicate/screen-reader-only C0 name node');
          expect(_nameNodes(kCompoundSeparatorName).evaluate().length, 2,
              reason: '$px no duplicate/screen-reader-only separator node');
        },
      );

      for (final MapEntry<String, KvmConsole> caseData in <String, KvmConsole>{
        'C0': c0Console,
        'separator': separatorConsole,
      }.entries) {
        testWidgets(
          'viewer announces + displays the FULL ${caseData.key} name under '
          'RTL + 2.0x at ${px}px',
          (WidgetTester tester) async {
            await _pumpViewer(
              tester,
              console: caseData.value,
              width: width,
              direction: TextDirection.rtl,
              scale: 2.0,
            );

            final String id = caseData.value.managerId;
            final String header = '${caseData.value.type.label}, manager $id';
            final String visible = '${caseData.value.type.label} · Manager $id';
            expect(find.bySemanticsLabel(header), findsOneWidget,
                reason: '$px viewer merged full hostile-name header');
            expect(find.text(visible), findsOneWidget,
                reason: '$px one visible viewer hostile-name header');
            expect(_nameNodes(id).evaluate().length, 1,
                reason: '$px no duplicate/screen-reader-only viewer node');
            expect(tester.takeException(), isNull,
                reason: '$px viewer renders hostile name without overflow');
          },
        );
      }

      testWidgets(
        'LTR / 1.0x control keeps both cards byte-exact at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.ltr,
            scale: 1.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'LTR/1.0x overflow at $px');
          for (final String id in kCompoundIds) {
            expect(find.bySemanticsLabel('Manager: $id'), findsOneWidget,
                reason: '$px LTR console control node ($id)');
            expect(
              find.bySemanticsLabel(
                'Manager capability $id, enabled, KVM supported',
              ),
              findsOneWidget,
              reason: '$px LTR capability control node ($id)',
            );
          }
        },
      );
    }
  });
}
