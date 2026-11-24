// EP-U31 (issues #009 / #021): COMPOUND-extreme a11y agreement across the two
// real operator cards — a long unbreakable control-bearing connect-type token
// rendered under RTL direction AND a 2.0x accessibility text scaler.
//
// AUDIT FIRST: each axis is covered on its own — EP-U24 pins one 400-char
// unbreakable token (LTR, 1.0x) on both cards; EP-U21 pins 1.0/1.3/2.0x on both
// cards and the viewer but only with word-breakable chips; EP-U28 pins LTR/RTL
// on both cards and the viewer but only at 1.0x with short chips. NO test drives
// the CONJUNCTION (unbreakable x 2.0x x RTL). A plausible one-sided "an
// unbreakable chip fits better in a fixed Row at large fonts" edit on the
// capability card overflows it under the compound setting while every
// single-axis suite stays GREEN — the exact #009 cross-surface divergence
// class. This guard locks that both cards reflow the chip in a Wrap, keep one
// merged excludeSemantics node with visible == announced, keep one visible chip
// instance with the byte-exact model value, and stay overflow-free at
// 320 / 800 / 1300 px; an LTR/1.0x control and a populated-normal control prove
// the compound setting changes nothing on a well-formed card.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol plugin is imported, and production TLS is untouched (issues #009/#021).
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

/// A single 400-char, whitespace-free vendor connect-type token. Normalization
/// (EP-M5) trims but otherwise keeps the first spelling verbatim, so it survives
/// end-to-end and cannot soft-wrap at any width or scale.
final String kCompoundUnbreakableToken = 'VENDORPROPRIETARY'.padRight(400, 'X');

const String kCompoundControlChip = 'HTML5';
const String kCompoundManagerId = 'BMC-Rack42-ChassisA-Slot07-Node03';
const String kCompoundSecureUri = 'https://bmc.example/redfish/v1/console';

final List<String> kExpectedChips = <String>[
  kCompoundUnbreakableToken,
  kCompoundControlChip,
];

Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>[
          kCompoundUnbreakableToken,
          kCompoundControlChip,
        ],
        'ConnectUri': kCompoundSecureUri,
        'MaxConcurrentSessions': 4,
      },
    };

/// Applies BOTH compound axes: RTL direction and a given text scaler.
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
  // Tall enough that the 2.0x-scaled unbreakable chip cannot push the second
  // card below the viewport (Flutter only builds visible list children).
  tester.view.physicalSize = Size(width, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _managerBody();
  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: kCompoundManagerId);
  final KvmCapability capability =
      KvmCapability.fromManager(body, managerId: kCompoundManagerId);
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
  group('EP-U31 compound-extreme a11y agreement (#009/#021)', () {
    test('fixture yields the unbreakable token byte-exact on both projections',
        () {
      final Map<String, dynamic> body = _managerBody();
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: kCompoundManagerId);
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: kCompoundManagerId);
      expect(consoles, hasLength(1));
      expect(consoles.single.connectTypesSupported, kExpectedChips);
      expect(capability.connectTypes, kExpectedChips);
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards stay overflow-free with one merged, visible==announced '
        'unbreakable chip under RTL + 2.0x at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(tester,
              width: width, direction: TextDirection.rtl, scale: 2.0);

          expect(tester.takeException(), isNull,
              reason: 'RTL/2.0x overflow at $px');

          final Finder capability = _capabilityCard();
          final Finder console = _consoleCard();
          expect(capability, findsOneWidget, reason: '$px capability card');
          expect(console, findsOneWidget, reason: '$px console card');

          // Both cards render the SAME logical chip sequence under the compound
          // setting — no one-sided reversal, truncation or canonical collapse.
          expect(_chipLabels(tester, capability), kExpectedChips,
              reason: '$px capability chip sequence');
          expect(_chipLabels(tester, console), kExpectedChips,
              reason: '$px console chip sequence');

          // Exactly one VISIBLE chip instance of the unbreakable token on each
          // card (the merged Semantics node carries the announcement; there is
          // no second screen-reader-only copy of the chip itself).
          expect(
            find.byWidgetPredicate(
              (Widget w) => w is Text && w.data == kCompoundUnbreakableToken,
            ),
            findsNWidgets(2),
            reason: '$px one visible unbreakable chip per card',
          );

          // Each merged node announces exactly the byte-exact model value.
          expect(
            find.bySemanticsLabel(
              'Connection types: ${kExpectedChips.join(', ')}',
            ),
            findsOneWidget,
            reason: '$px capability merged announcement',
          );
          expect(
            find.bySemanticsLabel(
              'Supported connection types: ${kExpectedChips.join(', ')}',
            ),
            findsOneWidget,
            reason: '$px console merged announcement',
          );
        },
      );

      testWidgets(
        'LTR / 1.0x control keeps the identical chip sequence and no overflow '
        'at ${px}px',
        (WidgetTester tester) async {
          await _pumpCards(tester,
              width: width, direction: TextDirection.ltr, scale: 1.0);

          expect(tester.takeException(), isNull,
              reason: 'LTR/1.0x overflow at $px');
          expect(_chipLabels(tester, _capabilityCard()), kExpectedChips,
              reason: '$px capability control chips');
          expect(_chipLabels(tester, _consoleCard()), kExpectedChips,
              reason: '$px console control chips');
        },
      );
    }
  });
}
