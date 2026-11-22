// EP-U20 (issues #009 / #021): the capability card and the per-console card are
// the two operator decision surfaces for the SAME Redfish manager, built from
// two independent model projections (`KvmCapability.fromManager` /
// `KvmConsole.fromManager`). EP-U19 pins that the two cards agree on connect-type
// chips and session-limit text over a MODEST hostile matrix (three chips) and
// EP-U16/U15 pin notice/launch agreement — but nothing pinned that BOTH cards
// stay usable and in agreement when one manager carries EXTREME content: a long
// manager name, 20+ connect-type chips, a very large session-limit number and a
// long control-safe resolved URI.
//
// A one-sided layout edit (flowing the chips in a fixed `Row` on one card, or
// splitting a merged a11y node) could overflow at 320 px or desync the operator
// surfaces while every fixed-value suite stayed GREEN — the exact #009
// divergence class these cards exist to prevent. This guard builds BOTH real
// cards in one tree straight from the same extreme manager body and fails closed
// on any rendered divergence or overflow at 320 / 800 / 1300 px.
//
// NOTE: the two cards intentionally use different self-describing Semantics
// prefixes ('Connection types:' vs 'Supported connection types:', 'Max sessions:'
// vs 'Max concurrent sessions:', 'Resolved URI:' vs 'Connect URI:'). This guard
// pins agreement of the operator-visible PAYLOAD (chip value sequence, session
// number, URI) plus each card's own visible==announced node — not byte-identical
// label wording (cf. EP-U16/EP-U19's narrowed scope).
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

/// A deliberately long but word-breakable manager id (rack/chassis/slot tokens).
const String kExtremeManagerId =
    'BMC-Rack42-ChassisA-Slot07-Node03-Management-Controller';

/// 24 distinct normalized connect types — enough that a fixed `Row` cannot fit
/// them on one line at 320 px, so the guard is load-bearing for the chip `Wrap`.
final List<String> kExtremeTypes = List<String>.generate(
  24,
  (int i) => 'TYPE${i.toString().padLeft(2, '0')}',
  growable: false,
);

/// A very large spec-valid session limit, rendered verbatim by both cards.
const Object kExtremeLimit = 1000000000;

/// A long, control-safe, canonical HTTPS endpoint with no raw control chars.
const String kExtremeUri =
    'https://bmc-management.example.com/redfish/v1/Managers/BMC/GraphicalConsole/'
    'console?session=abcdef0123456789abcdef0123456789';

/// One enabled GraphicalConsole carrying the extreme payload. Both real cards
/// are built from this one body so the shared payload is byte-identical.
Map<String, dynamic> _extremeManagerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>[...kExtremeTypes],
        'MaxConcurrentSessions': kExtremeLimit,
        'ConnectUri': kExtremeUri,
      },
    };

Future<void> _pumpBothCards(
  WidgetTester tester, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final Map<String, dynamic> body = _extremeManagerBody();
  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: kExtremeManagerId);
  final KvmCapability capability =
      KvmCapability.fromManager(body, managerId: kExtremeManagerId);
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
      of: find.bySemanticsLabel('Manager: $kExtremeManagerId'),
      matching: find.byType(Card),
    );

Finder _mergedNode(Finder card, RegExp label) => find.descendant(
      of: card,
      matching: find.bySemanticsLabel(label),
    );

/// The operator-visible connect-type chip values, in render order.
List<String> _chipLabels(WidgetTester tester, Finder card) {
  final Finder node =
      _mergedNode(card, RegExp(r'^(Supported )?[Cc]onnection types: '));
  expect(node, findsOneWidget, reason: 'one merged connect-type node per card');
  final Finder chips = find.descendant(of: node, matching: find.byType(Chip));
  return tester
      .widgetList<Chip>(chips)
      .map((Chip c) => (c.label as Text).data!)
      .toList(growable: false);
}

/// The operator-visible session-limit number (label prefix intentionally differs
/// between the two cards; only the number is the shared payload).
String _sessionNumber(WidgetTester tester, Finder card) {
  final Finder node =
      _mergedNode(card, RegExp(r'^Max (concurrent )?sessions: '));
  expect(node, findsOneWidget,
      reason: 'one merged session-limit node per card');
  return tester.getSemantics(node).label.split(': ').last;
}

void main() {
  group('EP-U20 extreme-content cross-surface agreement (#009/#021)', () {
    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards render 20+ chips + huge session + long URI without '
        'overflow and with an agreed payload at ${px}px',
        (WidgetTester tester) async {
          await _pumpBothCards(tester, width: width);

          final Finder capability = _capabilityCard();
          final Finder consoleCard = _consoleCard();
          expect(capability, findsOneWidget);
          expect(consoleCard, findsOneWidget);

          // Both cards carry the long manager name in one merged, visible node.
          expect(
            find.bySemanticsLabel('Manager: $kExtremeManagerId'),
            findsOneWidget,
          );
          expect(find.bySemanticsLabel(RegExp(r'^Manager capability ')),
              findsOneWidget);

          // Same 24 chip values, same order, on both operator surfaces.
          final List<String> capabilityChips = _chipLabels(tester, capability);
          final List<String> consoleChips = _chipLabels(tester, consoleCard);
          expect(capabilityChips, kExtremeTypes,
              reason: 'capability chips at ${px}px');
          expect(consoleChips, kExtremeTypes,
              reason: 'console chips at ${px}px');
          expect(capabilityChips, consoleChips,
              reason: 'both cards must agree on all 24 chips at ${px}px');

          // Same huge session-limit number on both, visible == announced.
          expect(_sessionNumber(tester, capability), '1000000000');
          expect(_sessionNumber(tester, consoleCard), '1000000000');
          expect(_sessionNumber(tester, capability),
              _sessionNumber(tester, consoleCard));
          expect(find.bySemanticsLabel('Max sessions: 1000000000'),
              findsOneWidget);
          expect(find.bySemanticsLabel('Max concurrent sessions: 1000000000'),
              findsOneWidget);

          // Same long control-safe URI on both, visible == announced.
          expect(find.bySemanticsLabel('Resolved URI: $kExtremeUri'),
              findsOneWidget);
          expect(find.bySemanticsLabel('Connect URI: $kExtremeUri'),
              findsOneWidget);
          expect(find.text(kExtremeUri), findsNWidgets(2),
              reason: 'visible URI text on both cards at ${px}px');

          expect(tester.takeException(), isNull,
              reason: 'both cards render extreme content without overflow at '
                  '${px}px');
        },
      );
    }
  });
}
