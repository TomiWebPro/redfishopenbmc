// EP-U38 / #009 / #021: RTL x 2.0x COMPOUND a11y agreement for the SESSION-LIMIT
// row across both KVM operator cards.
//
// AUDIT FIRST (see queues/ui.md EP-U38): EP-U19 pins the two rendered cards'
// session-limit NUMBER agreement (and each row's visible==announced node) over
// a hostile encoding matrix — but at the default LTR / 1.0x text scale only.
// The compound RTL x 2.0x family (EP-U31..U37) drives unbreakable chips, bidi /
// control / separator display names, shared notices and the raw resolved URI
// through both cards under RTL AND a 2.0x scaler — but NONE drives the
// session-limit row through that compound setting. The two cards intentionally
// use different self-describing labels ('Max sessions:' on the capability card
// vs 'Max concurrent sessions:' on the per-console card), so the shared payload
// is the NUMBER; a plausible one-sided "make the session row screen-reader
// friendlier at RTL / large fonts" edit (reword the announced label on ONE
// card, or reformat/drop the number in its merged node) could desync one
// operator surface while every LTR / 1.0x / single-axis suite stayed GREEN.
// This guard closes that seam.
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

/// One enabled GraphicalConsole whose session limit is a boundary encoding,
/// built through the real `fromManager` factories so both cards use the shared
/// `kvmSessionLimit` normalization. No hostile transport/TLS surface is needed
/// for this display-layer guard.
Map<String, dynamic> _managerBody(Object? limit) => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
        'MaxConcurrentSessions': limit,
        'ConnectUri': 'https://bmc.example/console',
      },
    };

/// Pumps BOTH real operator cards in one tree under the requested direction /
/// text scale, built from the same manager body.
Future<void> _pumpBothCards(
  WidgetTester tester, {
  required Object? limit,
  required double width,
  required bool rtl,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles =
      KvmConsole.fromManager(_managerBody(limit), managerId: 'BMC');
  final KvmCapability capability =
      KvmCapability.fromManager(_managerBody(limit), managerId: 'BMC');
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
      child: MaterialApp(
        home: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData.fromView(tester.view)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: const KvmView(systemId: 'bmc1'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _capabilityCard() => find.byType(KvmCapabilityCard);

Finder _consoleCard() => find.ancestor(
      of: find.bySemanticsLabel('Manager: BMC'),
      matching: find.byType(Card),
    );

/// The merged session-limit node of [card]. Each card uses its own self-
/// describing label prefix; the trailing NUMBER is the shared payload.
Finder _sessionNode(Finder card) => find.descendant(
      of: card,
      matching: find.bySemanticsLabel(RegExp(r'^Max (concurrent )?sessions: ')),
    );

String _announcedNumber(WidgetTester tester, Finder node) =>
    tester.getSemantics(node).label.split(': ').last;

void main() {
  group('EP-U38 session-limit row a11y agreement under RTL x 2.0x (#009/#021)',
      () {
    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
          'both cards announce one byte-exact session row under RTL 2.0x '
          'at ${px}px', (WidgetTester tester) async {
        await _pumpBothCards(
          tester,
          limit: 6,
          width: width,
          rtl: true,
          scale: 2.0,
        );

        final Finder capability = _capabilityCard();
        final Finder consoleCard = _consoleCard();
        expect(capability, findsOneWidget);
        expect(consoleCard, findsOneWidget);

        // Each card: exactly one merged node, with visible text == announced
        // label, byte-exact, in one instance (no duplicate / screen-reader-only
        // node), for its own intentionally different label prefix.
        expect(find.bySemanticsLabel('Max sessions: 6'), findsOneWidget);
        expect(find.text('Max sessions: 6'), findsOneWidget);
        expect(find.bySemanticsLabel('Max concurrent sessions: 6'),
            findsOneWidget);
        expect(find.text('Max concurrent sessions: 6'), findsOneWidget);
        expect(_sessionNode(capability), findsOneWidget);
        expect(_sessionNode(consoleCard), findsOneWidget);

        // The operator-visible NUMBER agrees across both surfaces.
        expect(_announcedNumber(tester, _sessionNode(capability)), '6');
        expect(_announcedNumber(tester, _sessionNode(consoleCard)), '6');
        expect(_announcedNumber(tester, _sessionNode(capability)),
            _announcedNumber(tester, _sessionNode(consoleCard)),
            reason: 'both cards must announce the same session limit at ${px}px'
                ' under RTL 2.0x');

        expect(tester.takeException(), isNull,
            reason: 'session rows render without overflow at ${px}px');
      });
    }

    // Boundary encodings that all normalize to the same number must stay in
    // agreement under the compound setting (a one-sided coercion drift on one
    // card is exactly the divergence class this guard locks).
    for (final MapEntry<Object?, String> caseData
        in <MapEntry<Object?, String>>[
      const MapEntry<int, String>(2, '2'),
      const MapEntry<double, String>(5.0, '5'),
      const MapEntry<String, String>(' 3 ', '3'),
    ]) {
      testWidgets(
          'session limit ${caseData.key} stays byte-exact on both cards under '
          'RTL 2.0x', (WidgetTester tester) async {
        await _pumpBothCards(
          tester,
          limit: caseData.key,
          width: 320,
          rtl: true,
          scale: 2.0,
        );

        expect(find.bySemanticsLabel('Max sessions: ${caseData.value}'),
            findsOneWidget);
        expect(find.text('Max sessions: ${caseData.value}'), findsOneWidget);
        expect(
            find.bySemanticsLabel('Max concurrent sessions: ${caseData.value}'),
            findsOneWidget);
        expect(find.text('Max concurrent sessions: ${caseData.value}'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('LTR / 1.0x control keeps the same byte-exact session rows',
        (WidgetTester tester) async {
      await _pumpBothCards(
        tester,
        limit: 6,
        width: 320,
        rtl: false,
        scale: 1.0,
      );

      expect(find.bySemanticsLabel('Max sessions: 6'), findsOneWidget);
      expect(
          find.bySemanticsLabel('Max concurrent sessions: 6'), findsOneWidget);
      expect(_announcedNumber(tester, _sessionNode(_capabilityCard())), '6');
      expect(_announcedNumber(tester, _sessionNode(_consoleCard())), '6');
      expect(tester.takeException(), isNull);
    });
  });
}
