// EP-U34 (issues #009 / #021): COMPOUND a11y agreement across both KVM
// operator cards and the console viewer — a LONG, UNBREAKABLE manager DISPLAY
// NAME rendered under RTL layout AND a 2.0x accessibility text scaler.
//
// AUDIT FIRST: each axis is covered on its own but never in conjunction —
//   * EP-U23 pins a long, WORD-BREAKABLE (hyphenated) display name, but only at
//     LTR / 1.0x, on both cards + the viewer;
//   * EP-U21 (`kvm_large_font_cross_surface_a11y_test.dart`) pins a long
//     WORD-BREAKABLE display name at 1.0 / 1.3 / 2.0x, but only under MediaQuery
//     text scale (LTR — no `Directionality.rtl`);
//   * EP-U31 pins ONE long unbreakable CONNECT-TYPE CHIP under RTL x 2.0x, but
//     with a clean short manager name;
//   * EP-U32 pins a short bidi (Cf) display name under RTL x 2.0x and EP-U33
//     pins a short Cc/Zl/Zp/Zs display name under RTL x 2.0x — neither is long
//     or unbreakable.
// A plausible one-sided "a very long name at large fonts overflows the merged
// header on RTL; announce an ellipsised form on that one card" edit would make
// its merged node announce a DIFFERENT (truncated) string than the byte-exact
// value still visible and still announced on the sibling card and viewer,
// while every single-axis suite stayed GREEN — the exact #009 cross-surface
// divergence class. A long name with NO break opportunity is the worst case for
// line layout at 320 px / 2.0x, so this is not a redundant combination. This
// guard locks that, under the compound setting, both real cards and the viewer
// announce + display the FULL byte-exact name, keep one merged `excludeSemantics`
// node (no split / duplicate / screen-reader-only copy), and stay overflow-free
// at 320 / 800 / 1300 px. An LTR/1.0x control proves the compound setting
// changes nothing on an ordinary rendering.
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

/// A 180-character, control-safe token with NO break opportunity (no space,
/// hyphen, underscore or other soft-wrap point). At 2.0x on a 320 px viewport
/// this wraps across many lines purely on grapheme boundaries — the worst case
/// for a one-sided overflow/"fit it in the header" edit. The merged a11y label
/// must still carry the WHOLE string byte-for-byte.
final String kLongUnbreakableName = 'X' * 180;

/// Short plain-LTR control name that must stay byte-exact on every surface.
const String kPlainName = 'BMC';
const String kLongNameUri = 'https://bmc.example/html5';

Map<String, dynamic> _body() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'RemoteConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': kLongNameUri,
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

final List<String> kLongNameIds = <String>[
  kLongUnbreakableName,
  kPlainName,
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
  // Tall enough that 2.0x-scaled headers (an unbreakable 180-char name wraps
  // into many lines) cannot push a later card below the viewport — Flutter only
  // builds visible list children.
  tester.view.physicalSize = Size(width, 14000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _body();
  final List<KvmConsole> consoles = <KvmConsole>[
    for (final String id in kLongNameIds)
      ...KvmConsole.fromManager(body, managerId: id),
  ];
  final List<KvmCapability> capabilities = <KvmCapability>[
    for (final String id in kLongNameIds)
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
  tester.view.physicalSize = Size(width, 5000);
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
  final KvmConsole longNameConsole = KvmConsole.fromManager(
    body,
    managerId: kLongUnbreakableName,
  ).first;

  group(
      'EP-U34 long unbreakable name x RTL x 2.0x a11y agreement '
      '(#009/#021)', () {
    test(
        'fixture is genuinely long + unbreakable and both projections keep '
        'the name byte-exact', () {
      expect(kLongUnbreakableName.length, 180);
      // No soft-wrap opportunity anywhere in the token.
      expect(kLongUnbreakableName.contains(RegExp(r'[\s\-_]')), isFalse);
      expect(
        kLongUnbreakableName.codeUnits.every((int c) => c >= 0x21 && c <= 0x7E),
        isTrue,
        reason: 'fixture must stay control-safe',
      );
      expect(longNameConsole.managerId, kLongUnbreakableName,
          reason: 'console model keeps the display name byte-exact');
      expect(
        KvmCapability.fromManager(body, managerId: kLongUnbreakableName)
            .managerId,
        kLongUnbreakableName,
        reason: 'capability projection keeps the display name byte-exact',
      );
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards announce + display the FULL long unbreakable name '
        'byte-exact under RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'RTL/2.0x overflow at $px');

          // Each merged node carries the WHOLE raw name, not an ellipsised /
          // truncated form — on the long unbreakable name + the control.
          for (final String id in kLongNameIds) {
            expect(find.bySemanticsLabel('Manager: $id'), findsOneWidget,
                reason: '$px console card full long-name merged node');
            expect(
              find.bySemanticsLabel(
                'Manager capability $id, enabled, KVM supported',
              ),
              findsOneWidget,
              reason: '$px capability card full long-name merged node',
            );
            expect(find.text('Manager: $id'), findsOneWidget,
                reason: '$px one visible console-card name');
            expect(
              find.descendant(
                of: find.byType(KvmCapabilityCard),
                matching: find.text('Manager capability: $id'),
              ),
              findsOneWidget,
              reason: '$px one visible capability-card name',
            );
          }

          // No split / duplicate / screen-reader-only node carries the name:
          // exactly one console-card node + one capability-card node.
          expect(_nameNodes(kLongUnbreakableName).evaluate().length, 2,
              reason: '$px no duplicate/screen-reader-only long-name node');
        },
      );

      testWidgets(
        'viewer announces + displays the FULL long unbreakable name under '
        'RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpViewer(
            tester,
            console: longNameConsole,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          final String id = longNameConsole.managerId;
          final String header = '${longNameConsole.type.label}, manager $id';
          final String visible = '${longNameConsole.type.label} · Manager $id';
          expect(find.bySemanticsLabel(header), findsOneWidget,
              reason: '$px viewer merged full long-name header');
          expect(find.text(visible), findsOneWidget,
              reason: '$px one visible viewer long-name header');
          expect(_nameNodes(id).evaluate().length, 1,
              reason: '$px no duplicate/screen-reader-only viewer node');
          expect(tester.takeException(), isNull,
              reason: '$px viewer renders long name without overflow');
        },
      );

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
          for (final String id in kLongNameIds) {
            expect(find.bySemanticsLabel('Manager: $id'), findsOneWidget,
                reason: '$px LTR console control node');
            expect(
              find.bySemanticsLabel(
                'Manager capability $id, enabled, KVM supported',
              ),
              findsOneWidget,
              reason: '$px LTR capability control node',
            );
          }
        },
      );
    }
  });
}
