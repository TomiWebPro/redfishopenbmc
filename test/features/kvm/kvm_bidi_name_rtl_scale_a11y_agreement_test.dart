// EP-U32 (issues #009 / #021): COMPOUND a11y agreement across both KVM
// operator cards and the console viewer — a bidi / RTL-control-bearing DISPLAY
// NAME rendered under RTL layout AND a 2.0x accessibility text scaler.
//
// AUDIT FIRST: each axis is covered on its own but never in conjunction —
//   * EP-U22 pins bidi/RTL control marks (RLO/LRO/isolates/word-joiner) in a
//     DISPLAY NAME through both cards + the viewer, but only at LTR / 1.0x;
//   * EP-U28 pins LTR/RTL on both cards + the viewer, but only with short chips
//     and a clean manager id at 1.0x;
//   * EP-U21 pins 1.0 / 1.3 / 2.0x on both cards + the viewer, but only with a
//     clean display name;
//   * EP-U31 pins an unbreakable chip x RTL x 2.0x, but with a clean display
//     name — nothing drives a hostile bidi NAME through RTL x 2.0x.
// A plausible one-sided "a bidi name looks scrambled under RTL at large fonts;
// strip the format marks from the announcement" edit on ONE card would make its
// merged node announce a DIFFERENT (sanitised) string than the byte-exact value
// still visible and still announced on the sibling card/viewer, while every
// single-axis suite stayed GREEN — the exact #009 cross-surface divergence
// class. This guard locks that, under the compound setting, both real cards and
// the viewer announce + display the FULL byte-exact bidi name, keep one merged
// excludeSemantics node (no split / duplicate / screen-reader-only copy), and
// stay overflow-free at 320 / 800 / 1300 px. An LTR/1.0x control proves the
// compound setting changes nothing on an ordinary rendering.
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

/// The classic RLO spoof shape: a right-to-left override makes the visual order
/// differ from the byte order, so a screen reader MUST announce the raw string.
/// A PDF closes the override, an LRI/RLI isolate pair + PDI and a word-joiner
/// (U+2060) add the remaining bidi/format marks from the EP-U22 family.
const String kBidiCompoundName =
    'BMC\u202Eevil.example\u202C-\u2066Rack\u2067Node\u2069\u2060';
const String kPlainCompoundName = 'BMC';
const String kCompoundUri = 'https://bmc.example/html5';

Map<String, dynamic> _managerBody() => <String, dynamic>{
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
  // Tall enough that a 2.0x-scaled header cannot push the second card below the
  // viewport (Flutter only builds visible list children).
  tester.view.physicalSize = Size(width, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _managerBody();
  final List<String> ids = <String>[kBidiCompoundName, kPlainCompoundName];
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
/// detect a split / duplicate / screen-reader-only copy of the bidi name.
Finder _nameNodes(String needle) => find.byWidgetPredicate(
      (Widget w) =>
          w is Semantics && (w.properties.label?.contains(needle) ?? false),
    );

void main() {
  final KvmConsole bidiConsole = KvmConsole.fromManager(
    _managerBody(),
    managerId: kBidiCompoundName,
  ).first;

  group('EP-U32 bidi-name x RTL x 2.0x a11y agreement (#009/#021)', () {
    test(
        'fixture carries bidi marks and both projections keep the name '
        'byte-exact', () {
      expect(kBidiCompoundName.codeUnits, contains(0x202E)); // RLO
      expect(kBidiCompoundName.codeUnits, contains(0x202C)); // PDF
      expect(kBidiCompoundName.codeUnits, contains(0x2066)); // LRI
      expect(kBidiCompoundName.codeUnits, contains(0x2067)); // RLI
      expect(kBidiCompoundName.codeUnits, contains(0x2069)); // PDI
      expect(kBidiCompoundName.codeUnits, contains(0x2060)); // word joiner
      expect(bidiConsole.managerId, kBidiCompoundName,
          reason: 'model keeps the display name byte-exact');
      expect(
        KvmCapability.fromManager(_managerBody(), managerId: kBidiCompoundName)
            .managerId,
        kBidiCompoundName,
        reason: 'capability projection keeps the display name byte-exact',
      );
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards announce + display the FULL bidi name byte-exact under '
        'RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'RTL/2.0x overflow at $px');

          // Each merged node carries the WHOLE raw name, not a sanitised /
          // reordered / stripped form — on the bidi card and the plain control.
          expect(find.bySemanticsLabel('Manager: $kBidiCompoundName'),
              findsOneWidget,
              reason: '$px console card full bidi-name merged node');
          expect(
            find.bySemanticsLabel(
              'Manager capability $kBidiCompoundName, enabled, KVM supported',
            ),
            findsOneWidget,
            reason: '$px capability card full bidi-name merged node',
          );
          expect(find.bySemanticsLabel('Manager: $kPlainCompoundName'),
              findsOneWidget,
              reason: '$px plain console-card control node');
          expect(
            find.bySemanticsLabel(
              'Manager capability $kPlainCompoundName, enabled, KVM supported',
            ),
            findsOneWidget,
            reason: '$px plain capability-card control node',
          );

          // Visible text is the SAME raw name, rendered exactly once per card.
          expect(find.text('Manager: $kBidiCompoundName'), findsOneWidget,
              reason: '$px one visible console-card bidi name');
          expect(
            find.descendant(
              of: find.byType(KvmCapabilityCard),
              matching: find.text('Manager capability: $kBidiCompoundName'),
            ),
            findsOneWidget,
            reason: '$px one visible capability-card bidi name',
          );

          // No split / duplicate / screen-reader-only node carries the name.
          expect(_nameNodes(kBidiCompoundName).evaluate().length, 2,
              reason: '$px no duplicate/screen-reader-only bidi name node');
        },
      );

      testWidgets(
        'viewer announces + displays the FULL bidi name under RTL + 2.0x '
        'at ${px}px',
        (WidgetTester tester) async {
          await _pumpViewer(
            tester,
            console: bidiConsole,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          final String header =
              '${bidiConsole.type.label}, manager $kBidiCompoundName';
          final String visible =
              '${bidiConsole.type.label} · Manager $kBidiCompoundName';
          expect(find.bySemanticsLabel(header), findsOneWidget,
              reason: '$px viewer merged full bidi-name header');
          expect(find.text(visible), findsOneWidget,
              reason: '$px one visible viewer bidi-name header');
          expect(_nameNodes(kBidiCompoundName).evaluate().length, 1,
              reason: '$px no duplicate/screen-reader-only viewer bidi node');
          expect(tester.takeException(), isNull,
              reason: '$px viewer renders bidi text without overflow');
        },
      );

      testWidgets(
        'LTR / 1.0x control keeps both cards and viewer byte-exact at '
        '${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.ltr,
            scale: 1.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'LTR/1.0x overflow at $px');
          expect(find.bySemanticsLabel('Manager: $kBidiCompoundName'),
              findsOneWidget,
              reason: '$px LTR console control node');
          expect(
            find.bySemanticsLabel(
              'Manager capability $kBidiCompoundName, enabled, KVM supported',
            ),
            findsOneWidget,
            reason: '$px LTR capability control node',
          );
        },
      );
    }
  });
}
