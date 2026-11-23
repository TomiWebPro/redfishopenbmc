// EP-U24 (issues #009 / #021): the capability card and the per-console card are
// the two operator decision surfaces for the SAME Redfish manager, built from
// two independent model projections (`KvmCapability.fromManager` /
// `KvmConsole.fromManager`). EP-U19 pins both cards over a MODEST hostile chip
// matrix and EP-U20 pins 20+ SHORT chips, but nothing pinned a single long
// UNBREAKABLE connect-type token (a whitespace-free vendor string): at 320 px a
// one-sided chip-layout edit (flowing chips in a fixed `Row`, or truncating one
// card's label) could overflow the card or desync the merged a11y node while
// every short-chip suite stayed GREEN — the exact #009 divergence class.
//
// AUDIT FIRST: both cards already render chips through `Wrap(children:
// [Chip(label: Text(type))])`. `RenderChip` gives each label a FINITE max width
// (bounded by the Wrap) and the Chip's `DefaultTextStyle` clips with
// `maxLines: 1 / softWrap: false / overflow: fade`, so an unbreakable token is
// clipped to a single visible instance rather than overflowing; both cards read
// the same normalized model list. This guard locks that contract and fails
// closed on any rendered divergence or overflow at 320 / 800 / 1300 px.
//
// NOTE: the two cards intentionally use different self-describing Semantics
// prefixes ('Connection types:' vs 'Supported connection types:'). This guard
// pins agreement of the rendered CHIP VALUE SEQUENCE plus each card's own
// visible==announced node, not byte-identical label wording (cf. EP-U19/EP-U20).
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol dependency is imported and production TLS is untouched.

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
/// (EP-M5) trims but otherwise keeps the first spelling verbatim, so this
/// survives end-to-end and cannot soft-wrap at any width.
final String kUnbreakableToken = 'VENDORPROPRIETARY'.padRight(400, 'X');

/// A short, ordinary control chip rendered alongside the unbreakable token.
const String kControlChip = 'HTML5';

final List<String> kExpectedChips = <String>[
  kUnbreakableToken,
  kControlChip,
];

Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>[
          kUnbreakableToken,
          kControlChip,
        ],
        'MaxConcurrentSessions': 4,
        'ConnectUri': 'https://bmc.example/console',
      },
    };

Future<void> _pumpBothCards(
  WidgetTester tester, {
  required double width,
  bool onlyUnbreakable = false,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _managerBody();
  if (onlyUnbreakable) {
    (body['GraphicalConsole']
        as Map<String, dynamic>)['ConnectTypesSupported'] = <dynamic>[
      kUnbreakableToken
    ];
  }
  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: 'BMC');
  final KvmCapability capability =
      KvmCapability.fromManager(body, managerId: 'BMC');
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: consoles);

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
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _capabilityCard() => find.byType(KvmCapabilityCard);

Finder _consoleCard() => find.ancestor(
      of: find.bySemanticsLabel('Manager: BMC'),
      matching: find.byType(Card),
    );

/// The operator-visible connect-type chip values, in render order.
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
  group('EP-U24 unbreakable connect-type chip agreement (#009/#021)', () {
    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards clip one unbreakable token to a single merged node and '
        'keep byte-identical chip values at ${px}px',
        (WidgetTester tester) async {
          await _pumpBothCards(tester, width: width);

          final Finder capability = _capabilityCard();
          final Finder consoleCard = _consoleCard();
          expect(capability, findsOneWidget);
          expect(consoleCard, findsOneWidget);

          // Both cards carry the FULL unbreakable token as the chip value,
          // in the same order, byte-for-byte — no one-sided truncation/filter.
          final List<String> capabilityChips = _chipLabels(tester, capability);
          final List<String> consoleChips = _chipLabels(tester, consoleCard);
          expect(capabilityChips, kExpectedChips,
              reason: 'capability chips at ${px}px');
          expect(consoleChips, kExpectedChips,
              reason: 'console chips at ${px}px');
          expect(capabilityChips, consoleChips,
              reason: 'both cards must agree on the full token at ${px}px');

          // One merged excludeSemantics node per card, whose announced label
          // carries the FULL token (visible clipped, announcement untruncated).
          expect(
            find.bySemanticsLabel(
                'Connection types: ${kExpectedChips.join(', ')}'),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(
                'Supported connection types: ${kExpectedChips.join(', ')}'),
            findsOneWidget,
          );

          // Exactly one visible token instance per card, no screen-reader-only
          // duplicate: the model string is rendered once per chip label.
          expect(find.text(kUnbreakableToken), findsNWidgets(2),
              reason: 'one visible unbreakable chip per card at ${px}px');
          expect(find.text(kControlChip), findsNWidgets(2),
              reason: 'one visible control chip per card at ${px}px');

          expect(tester.takeException(), isNull,
              reason: 'unbreakable token clipped without overflow at ${px}px');
        },
      );
    }

    testWidgets(
      'an unbreakable token on its own still clips cleanly on both cards at '
      '320px with no duplicate announced node',
      (WidgetTester tester) async {
        await _pumpBothCards(tester, width: 320, onlyUnbreakable: true);

        expect(
          find.bySemanticsLabel('Connection types: $kUnbreakableToken'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
              'Supported connection types: $kUnbreakableToken'),
          findsOneWidget,
        );
        expect(find.text(kUnbreakableToken), findsNWidgets(2));
        expect(_chipLabels(tester, _capabilityCard()),
            <String>[kUnbreakableToken]);
        expect(
            _chipLabels(tester, _consoleCard()), <String>[kUnbreakableToken]);
        expect(tester.takeException(), isNull,
            reason: 'single unbreakable token clips without overflow at 320px');
      },
    );
  });
}
