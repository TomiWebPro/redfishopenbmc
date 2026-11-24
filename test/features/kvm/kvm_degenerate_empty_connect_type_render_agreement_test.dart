// EP-U29 (issues #009 / #021): degenerate-empty connect-type / blank-label
// render agreement across BOTH operator cards and the console viewer.
//
// AUDIT FIRST (2026-11-24): no existing widget test pumps a real operator card
// with ZERO usable `ConnectTypesSupported` tokens. Every card fixture carries
// at least one token (typically `['KVMIP']` / `['HTML5']`), so the two
// `.isNotEmpty` guards in front of the connect-type chip rows (`kvm_view.dart`
// per-console card, `kvm_capability_card.dart` capability card) are unguarded:
// dropping one would render an empty `excludeSemantics` node ('Supported
// connection types: ' / 'Connection types: ' with no payload) and an empty
// `Wrap` on ONE surface while its sibling still correctly collapses the row,
// with every existing suite staying GREEN. That is exactly the #009/#021
// one-sided render divergence class these two cards exist to prevent.
//
// The model normalizers (`KvmConsole._normalizedConnectTypes` /
// `KvmCapability._appendTypes`) already trim and drop blank/non-string tokens,
// so a body whose only tokens are blank/whitespace/malformed yields an EMPTY
// type set on both projections by construction — this guard pins that the two
// RENDER surfaces agree with that empty set (no empty chip, no empty
// screen-reader announcement), that a populated control still renders the full
// chip row identically, and that the viewer adds no empty node or overflow.
//
// Display-only, dependency-free, TLS-safe: no URL is opened, no WebView or
// protocol dependency is imported, no production TLS is weakened.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/kvm_session.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
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

const String kManagerId = 'BMC-DEGENERATE-CONNECT-TYPES';
const String kSafeUri = 'https://bmc-degenerate.example.com/console';
final DateTime _t0 = DateTime.utc(2026, 11, 24, 12);

/// Builds a manager body with a single enabled GraphicalConsole.
///
/// When [degenerate] is true the only `ConnectTypesSupported` tokens are blank,
/// whitespace-only or malformed non-strings: both model normalizers drop them,
/// yielding an empty connect-type set on both projections. Otherwise a small
/// populated control (trim + case-insensitive dedup) is used.
Map<String, dynamic> _body({required bool degenerate}) => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/$kManagerId',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': degenerate
            ? <dynamic>[
                '',
                '   ',
                '\t',
                42,
                null,
                <String>['KVMIP']
              ]
            : <dynamic>[' KVMIP ', 'html5', 'KVMIP', '', 7],
        'MaxConcurrentSessions': 2,
        'ConnectUri': kSafeUri,
      },
    };

class _Models {
  _Models(this.body)
      : consoles = KvmConsole.fromManager(body, managerId: kManagerId),
        capability = KvmCapability.fromManager(body, managerId: kManagerId);

  final Map<String, dynamic> body;
  final List<KvmConsole> consoles;
  final KvmCapability capability;
}

Future<void> _pumpBothCards(
  WidgetTester tester,
  _Models models, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: models.consoles);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(
              <KvmCapability>[models.capability]),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester,
  KvmConsole console, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      kvmSessionClockProvider.overrideWithValue(() => _t0),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: KvmConsoleViewerPage(
          key: ValueKey<String>('ep-u29-${width.toInt()}'),
          console: console,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _capabilityCard() => find.byType(KvmCapabilityCard);

Finder _consoleCard() => find.ancestor(
      of: find.bySemanticsLabel('Manager: $kManagerId'),
      matching: find.byType(Card),
    );

/// The merged connect-type announcement node on either card (absent when the
/// connect-type set is empty). Prefix differs by card, payload is shared.
final RegExp kConnectTypeLabel = RegExp(r'^(Supported )?[Cc]onnection types:');

/// An EMPTY connect-type announcement — the exact node a dropped `.isNotEmpty`
/// guard would render. Kept as a separate, precise matcher so the RED proof
/// names the divergence and never relies on a broad "blank semantics" scan.
final RegExp kEmptyConnectTypeLabel =
    RegExp(r'^(Supported )?[Cc]onnection types:\s*$');

List<String> _chipLabels(WidgetTester tester, Finder node) => tester
    .widgetList<Chip>(find.descendant(of: node, matching: find.byType(Chip)))
    .map((Chip chip) => (chip.label as Text).data!)
    .toList(growable: false);

bool _hasBlankChip(WidgetTester tester) {
  for (final Chip chip in tester.widgetList<Chip>(find.byType(Chip))) {
    if (chip.label is Text && (chip.label as Text).data!.trim().isEmpty) {
      return true;
    }
  }
  return false;
}

void main() {
  group('EP-U29 degenerate-empty connect-type render agreement (#009/#021)',
      () {
    test(
        'both model projections collapse blank/malformed tokens to an empty '
        'set, control stays byte-identical', () {
      final _Models degenerate = _Models(_body(degenerate: true));
      expect(degenerate.consoles, hasLength(1));
      expect(degenerate.consoles.single.connectTypesSupported, isEmpty);
      expect(degenerate.capability.connectTypes, isEmpty);

      final _Models control = _Models(_body(degenerate: false));
      expect(control.consoles, hasLength(1));
      expect(control.consoles.single.connectTypesSupported, isNotEmpty);
      expect(control.capability.connectTypes,
          control.consoles.single.connectTypesSupported);
      expect(
          control.capability.connectTypes
              .every((String type) => type.trim().isNotEmpty),
          isTrue);
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
          'degenerate body: both cards collapse the empty chip row '
          'with no empty announcement or blank chip at ${px}px',
          (WidgetTester tester) async {
        final _Models models = _Models(_body(degenerate: true));
        await _pumpBothCards(tester, models, width: width);

        final Finder capability = _capabilityCard();
        final Finder consoleCard = _consoleCard();
        expect(capability, findsOneWidget);
        expect(consoleCard, findsOneWidget);

        // Both render surfaces agree with the empty model set: NO merged
        // connect-type node on either card, and no empty-tail announcement.
        expect(find.bySemanticsLabel(kConnectTypeLabel), findsNothing,
            reason: 'no connect-type chip node on either card at ${px}px');
        expect(find.bySemanticsLabel(kEmptyConnectTypeLabel), findsNothing,
            reason: 'no empty connect-type announcement at ${px}px');
        expect(_hasBlankChip(tester), isFalse,
            reason: 'no blank chip may be emitted at ${px}px');
        expect(models.capability.connectTypes, isEmpty);
        expect(models.consoles.single.connectTypesSupported, isEmpty);

        expect(tester.takeException(), isNull,
            reason: 'degenerate empty chip set renders without overflow at '
                '${px}px');
      });

      testWidgets(
          'populated control: both cards render the same clean chip '
          'row with no empty announcement at ${px}px',
          (WidgetTester tester) async {
        final _Models models = _Models(_body(degenerate: false));
        await _pumpBothCards(tester, models, width: width);

        final Finder capability = _capabilityCard();
        final Finder consoleCard = _consoleCard();
        expect(capability, findsOneWidget);
        expect(consoleCard, findsOneWidget);

        expect(find.bySemanticsLabel(kConnectTypeLabel), findsNWidgets(2),
            reason: 'one non-empty connect-type node on each card at ${px}px');
        expect(find.bySemanticsLabel(kEmptyConnectTypeLabel), findsNothing);

        final Finder capabilityNode = find.descendant(
            of: capability, matching: find.bySemanticsLabel(kConnectTypeLabel));
        final Finder consoleNode = find.descendant(
            of: consoleCard,
            matching: find.bySemanticsLabel(kConnectTypeLabel));
        final List<String> capabilityChips =
            _chipLabels(tester, capabilityNode);
        final List<String> consoleChips = _chipLabels(tester, consoleNode);
        expect(capabilityChips, models.capability.connectTypes);
        expect(consoleChips, models.consoles.single.connectTypesSupported);
        expect(capabilityChips, consoleChips,
            reason:
                'both cards must agree on the populated chip row at ${px}px');
        expect(_hasBlankChip(tester), isFalse);

        expect(tester.takeException(), isNull,
            reason: 'populated chip row renders without overflow at ${px}px');
      });

      testWidgets(
          'degenerate body: viewer adds no empty node / blank chip '
          'and keeps the fail-closed URI affordance at ${px}px',
          (WidgetTester tester) async {
        final _Models models = _Models(_body(degenerate: true));
        await _pumpViewer(tester, models.consoles.single, width: width);

        expect(find.bySemanticsLabel(kConnectTypeLabel), findsNothing);
        expect(find.bySemanticsLabel(kEmptyConnectTypeLabel), findsNothing);
        expect(_hasBlankChip(tester), isFalse);
        // Fail-closed affordance change: the secure URI row is still rendered
        // with a byte-exact announced label, never a blank one.
        expect(find.bySemanticsLabel('Console URI: $kSafeUri'), findsOneWidget);

        expect(tester.takeException(), isNull,
            reason: 'viewer renders the degenerate console without overflow at '
                '${px}px');
      });
    }
  });
}
