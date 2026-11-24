// EP-U35 (issues #009 / #021): COMPOUND a11y agreement across both KVM
// operator cards — a CONNECT-TYPE chip set carrying bidi FORMAT marks (Cf), a
// C0 control (Cc) and a Unicode LINE SEPARATOR (Zl), rendered under RTL layout
// AND a 2.0x accessibility text scaler.
//
// AUDIT FIRST: every prior connect-type-chip guard drives a CONTROL-SAFE token.
//   * EP-U19 / EP-U20 (`kvm_card_extreme_content_agreement_test.dart`) pin the
//     chip sequence over a modest / 20+ short ASCII vendor-token matrix;
//   * EP-U24 pins ONE long unbreakable ASCII token at LTR / 1.0x;
//   * EP-U31 pins a long unbreakable ASCII token under RTL x 2.0x;
//   * RM-22 (`kvm_connect_type_confusable_agreement_test.dart`) pins confusable
//     code points, but only at the pure model-helper layer (no widget render).
// The bidi/control display-name guards (EP-U22 / EP-U32 / EP-U33 / EP-U34) all
// target the manager DISPLAY NAME, never the connect-type chip. So NOTHING drove
// a control/bidi-bearing CONNECT-TYPE value through BOTH cards' merged
// "connection types" announcement nodes under RTL x 2.0x — the compound setting
// where bidi marks actually change visual order and a separator changes line
// layout. A plausible one-sided "these marks look garbled under RTL at large
// fonts; strip them from this card's announced connection-types string" edit
// would make one card announce a DIFFERENT value than the byte-exact chips it
// still renders, while the sibling card and every display-name-only suite
// stayed GREEN — the exact #009 cross-surface divergence class.
//
// This guard locks that under the compound setting both real cards render the
// SAME byte-exact chip sequence and each merged `excludeSemantics` node
// announces the FULL joined value, with no split / duplicate / screen-reader-
// only copy and no overflow at 320 / 800 / 1300 px. An LTR/1.0x control proves
// the ordinary rendering keeps the identical chip sequence.
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
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Bidi FORMAT marks (U+200E LRM / U+200F RLM) embedded in an HTML5-like token.
/// Cf is not whitespace, so `_normalizedConnectTypes` keeps it byte-for-byte and
/// the ASCII-only `kvmConnectTypeKey` keeps it distinct from canonical HTML5.
const String kLrmToken = '\u200EHTM\u200FL5';

/// C0 TAB (U+0009, Cc) embedded in a KVMIP-like token. It is not at an edge, so
/// `String.trim()` leaves it and the token never collapses onto canonical KVMIP.
const String kTabToken = 'KV\u0009MIP';

/// Unicode LINE SEPARATOR (U+2028, Zl) embedded in an HTML5-like token: a
/// layout-changing control that still survives trim + ASCII-only folding.
const String kSeparatorToken = 'HT\u2028ML5';

const String kManagerId = 'BMC-Rack42';
const String kSecureUri = 'https://bmc.example/redfish/v1/console';

final List<String> kHostileTypes = <String>[
  kLrmToken,
  kTabToken,
  kSeparatorToken,
];

/// The byte-exact value each card's merged connect-type node must announce.
/// The two cards intentionally use different self-describing prefixes; this
/// guard pins agreement of the operator-visible PAYLOAD plus each card's own
/// visible==announced node, not byte-identical label wording (cf. EP-U20/U31).
String get _consoleAnnouncement =>
    'Supported connection types: ${kHostileTypes.join(', ')}';
String get _capabilityAnnouncement =>
    'Connection types: ${kHostileTypes.join(', ')}';

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

Map<String, dynamic> _body() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>[...kHostileTypes],
        'ConnectUri': kSecureUri,
        'MaxConcurrentSessions': 2,
      },
    };

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
  tester.view.physicalSize = Size(width, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _body();
  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: kManagerId);
  final KvmCapability capability =
      KvmCapability.fromManager(body, managerId: kManagerId);
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
        home: _withAxes(const KvmView(systemId: 'bmc1'), direction, scale),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _capabilityCard() => find.byType(KvmCapabilityCard);

Finder _consoleCard() => find.ancestor(
      of: find.bySemanticsLabel('Graphical Console, enabled'),
      matching: find.byType(Card),
    );

/// The operator-visible connect-type chip values, in render order, for ONE card.
List<String> _chipLabels(WidgetTester tester, Finder card) {
  final Finder node = find.descendant(
    of: card,
    matching:
        find.bySemanticsLabel(RegExp(r'^(Supported )?[Cc]onnection types: ')),
  );
  expect(node, findsOneWidget, reason: 'one merged connect-type node per card');
  final Finder chips = find.descendant(of: node, matching: find.byType(Chip));
  return tester
      .widgetList<Chip>(chips)
      .map((Chip c) => (c.label as Text).data!)
      .toList(growable: false);
}

void main() {
  group(
      'EP-U35 control-bearing connect-type x RTL x 2.0x agreement '
      '(#009/#021)', () {
    test(
        'fixture keeps every control/bidi token byte-exact on both '
        'projections and never collapses onto a canonical type', () {
      final Map<String, dynamic> body = _body();
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: kManagerId);
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: kManagerId);

      expect(consoles, hasLength(1));
      expect(consoles.single.connectTypesSupported, kHostileTypes);
      expect(capability.connectTypes, kHostileTypes);
      expect(capability.connectTypes, consoles.single.connectTypesSupported);

      for (final String canonical in <String>['KVMIP', 'HTML5', 'OEM']) {
        expect(kHostileTypes, isNot(contains(canonical)),
            reason: 'a control/bidi token must not fold onto $canonical');
      }
      // No control token may advertise real KVM support on either view.
      expect(capability.supported, isFalse);
      expect(consoles.single.supportsHtml5, isFalse);
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards announce + display the FULL byte-exact control-bearing '
        'connect-type set under RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(
            tester,
            width: width,
            direction: TextDirection.rtl,
            scale: 2.0,
          );

          expect(tester.takeException(), isNull,
              reason: 'RTL/2.0x overflow at $px');

          final Finder capability = _capabilityCard();
          final Finder console = _consoleCard();
          expect(capability, findsOneWidget, reason: '$px capability card');
          expect(console, findsOneWidget, reason: '$px console card');

          // Both cards render the SAME logical chip sequence under the compound
          // setting — no one-sided strip, reversal, drop or canonical collapse.
          expect(_chipLabels(tester, capability), kHostileTypes,
              reason: '$px capability chip sequence');
          expect(_chipLabels(tester, console), kHostileTypes,
              reason: '$px console chip sequence');

          // Each merged node announces the WHOLE joined value byte-for-byte.
          expect(find.bySemanticsLabel(_consoleAnnouncement), findsOneWidget,
              reason: '$px console card full merged connect-type announcement');
          expect(find.bySemanticsLabel(_capabilityAnnouncement), findsOneWidget,
              reason:
                  '$px capability card full merged connect-type announcement');

          // Exactly one VISIBLE chip instance of each hostile token across both
          // cards (the merged Semantics node carries the announcement; there is
          // no second screen-reader-only copy of any chip).
          for (final String token in kHostileTypes) {
            expect(
              find.byWidgetPredicate(
                (Widget w) => w is Text && w.data == token,
              ),
              findsNWidgets(2),
              reason: '$px one visible chip instance of the token per card',
            );
          }
        },
      );

      testWidgets(
        'LTR / 1.0x control keeps the identical byte-exact chip sequence at '
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
          expect(_chipLabels(tester, _capabilityCard()), kHostileTypes,
              reason: '$px LTR capability chip sequence');
          expect(_chipLabels(tester, _consoleCard()), kHostileTypes,
              reason: '$px LTR console chip sequence');
        },
      );
    }
  });
}
