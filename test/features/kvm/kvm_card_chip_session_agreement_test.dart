// EP-U19 (issues #009 / #021): the capability card and the per-console card are
// two operator decision surfaces for the SAME Redfish manager, built from two
// independent model projections (`KvmCapability.fromManager` /
// `KvmConsole.fromManager`). The model-level hostile connect-type normalization
// (EP-M5) and session-limit agreement (RS-10) are pinned, and EP-U11 pins the
// two RENDERED cards' supported/URI agreement — but nothing pinned that the two
// cards still render the SAME connect-type chips (same bytes, same order) and
// the SAME session-limit number for one manager over a hostile matrix.
//
// A one-sided view edit (sorting/filtering chips on one card, or falling back
// to a raw/stale session value on the other) would desync the two operator
// surfaces while every model-level and single-surface card test stayed GREEN —
// the exact #009 divergence class these cards exist to prevent. This guard
// builds BOTH real cards in one tree straight from the same manager body and
// fails closed on any such rendered divergence, at 320 / 800 / 1300 px.
//
// NOTE: the two cards intentionally use different self-describing Semantics
// prefixes ('Connection types:' vs 'Supported connection types:' and 'Max
// sessions:' vs 'Max concurrent sessions:'). This guard pins agreement of the
// rendered CHIP VALUE SEQUENCE and the SESSION NUMBER — the operator-visible
// payload — plus each card's own visible==announced node, not byte-identical
// label wording (cf. EP-U16's narrowed scope).
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

/// One enabled GraphicalConsole whose hostile ConnectTypesSupported matrix
/// normalizes (per EP-M5) to exactly ['KVMIP', 'HTML5', 'SSH'], plus a boundary
/// MaxConcurrentSessions encoding. Both cards are built from this one body.
Map<String, dynamic> _managerBody(Object? limit) => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>[
          ' KVMIP ',
          'kvmip', // case-insensitive duplicate — first spelling wins
          'HTML5',
          ' html5 ', // padded duplicate — dropped
          'SSH',
          '', // blank — dropped
          '   ', // whitespace-only — dropped
          7, // non-string — dropped
          true, // non-string — dropped
          null, // non-string — dropped
          <dynamic>['x'], // nested list — dropped
        ],
        'MaxConcurrentSessions': limit,
        'ConnectUri': 'https://bmc.example/console',
      },
    };

const List<String> kExpectedChips = <String>['KVMIP', 'HTML5', 'SSH'];

Future<void> _pumpBothCards(
  WidgetTester tester, {
  required Map<String, dynamic> managerBody,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles =
      KvmConsole.fromManager(managerBody, managerId: 'BMC');
  final KvmCapability capability =
      KvmCapability.fromManager(managerBody, managerId: 'BMC');
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

/// Finds the single merged semantics node of [card] whose label matches.
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

/// The operator-visible session-limit number (label prefix intentionally
/// differs between the two cards; only the number is the shared payload).
String _sessionNumber(WidgetTester tester, Finder card) {
  final Finder node =
      _mergedNode(card, RegExp(r'^Max (concurrent )?sessions: '));
  expect(node, findsOneWidget,
      reason: 'one merged session-limit node per card');
  final String label = tester.getSemantics(node).label;
  return label.split(': ').last;
}

void main() {
  group('EP-U19 cross-surface chip + session-limit agreement (#009/#021)', () {
    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
        'both cards render byte-identical connect-type chips over a hostile '
        'matrix at ${px}px',
        (WidgetTester tester) async {
          await _pumpBothCards(
            tester,
            width: width,
            managerBody: _managerBody(6),
          );

          final Finder capability = _capabilityCard();
          final Finder consoleCard = _consoleCard();
          expect(capability, findsOneWidget);
          expect(consoleCard, findsOneWidget);

          final List<String> capabilityChips = _chipLabels(tester, capability);
          final List<String> consoleChips = _chipLabels(tester, consoleCard);

          // Same bytes, same order on both operator surfaces.
          expect(capabilityChips, kExpectedChips,
              reason: 'capability chips normalized at ${px}px');
          expect(consoleChips, kExpectedChips,
              reason: 'console chips normalized at ${px}px');
          expect(capabilityChips, consoleChips,
              reason:
                  'both cards must render the same chip values in the same order at ${px}px');

          // Each card's own merged node announces exactly its visible chips.
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
          for (final String type in kExpectedChips) {
            expect(find.text(type), findsNWidgets(2),
                reason: 'visible chip text on both cards at ${px}px');
          }

          expect(tester.takeException(), isNull,
              reason: 'both cards render without overflow at ${px}px');
        },
      );

      testWidgets(
        'both cards render the same session-limit number at ${px}px',
        (WidgetTester tester) async {
          await _pumpBothCards(
            tester,
            width: width,
            managerBody: _managerBody(6),
          );

          final Finder capability = _capabilityCard();
          final Finder consoleCard = _consoleCard();
          expect(capability, findsOneWidget);
          expect(consoleCard, findsOneWidget);

          expect(_sessionNumber(tester, capability), '6');
          expect(_sessionNumber(tester, consoleCard), '6');
          expect(_sessionNumber(tester, capability),
              _sessionNumber(tester, consoleCard),
              reason:
                  'both cards must render the same session limit at ${px}px');

          // visible == announced on each card's own merged row.
          expect(find.bySemanticsLabel('Max sessions: 6'), findsOneWidget);
          expect(find.text('Max sessions: 6'), findsOneWidget);
          expect(find.bySemanticsLabel('Max concurrent sessions: 6'),
              findsOneWidget);
          expect(find.text('Max concurrent sessions: 6'), findsOneWidget);

          expect(tester.takeException(), isNull,
              reason: 'both cards render without overflow at ${px}px');
        },
      );
    }

    for (final MapEntry<Object?, String> caseData
        in <MapEntry<Object?, String>>[
      const MapEntry<int, String>(2, '2'),
      const MapEntry<double, String>(
          5.0, '5'), // integral double (JSON decimal)
      const MapEntry<String, String>(' 3 ', '3'), // padded numeric string
    ]) {
      testWidgets(
        'boundary MaxConcurrentSessions (${caseData.key}) agrees across cards',
        (WidgetTester tester) async {
          await _pumpBothCards(
            tester,
            width: 800,
            managerBody: _managerBody(caseData.key),
          );

          expect(_sessionNumber(tester, _capabilityCard()), caseData.value);
          expect(_sessionNumber(tester, _consoleCard()), caseData.value);
          expect(tester.takeException(), isNull,
              reason: 'no overflow for boundary encoding ${caseData.key}');
        },
      );
    }
  });
}
