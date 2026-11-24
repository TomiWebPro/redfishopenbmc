// EP-U27 (issues #009 / #021): the capability card and the per-console card are
// two operator decision surfaces for the SAME Redfish manager, built from two
// independent model projections (`KvmCapability.fromManager` /
// `KvmConsole.fromManager`) with TWO independent connect-type chip rows
// (`kvm_capability_card.dart` / `kvm_view.dart`). No existing test pumps a DENSE
// set of 12+ hostile / fullwidth / confusable `ConnectTypesSupported` tokens
// through both real cards: every cross-surface chip suite uses a small (<=4)
// token set, so a one-sided chip cap (`.take(n)`), a wrap reflow or a split
// merged-`Semantics` node could desync one card / overflow / announce a
// different chip set while every existing suite stayed GREEN.
//
// AUDIT (before adding): both cards already derive their chip rows from the
// model and wrap them in a single merged `excludeSemantics` node, and `Wrap`
// reflows arbitrary token counts without RenderFlex overflow — so there is no
// LIVE divergence. This is a pure display-only regression guard at a genuinely
// untested cross-surface seam (the 12+ token matrix), not churn: no behaviour
// change is folded in. The viewer page has no connect-type chip row, so the
// agreement asserted here is across the two real operator cards + the model.
// Dependency-free and TLS-safe: no URL opened, no WebView/protocol import, no
// production TLS touched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_connect_type.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// 13 tokens that are all DISTINCT under the ASCII-only fold in
/// [kvmConnectTypeKey] (non-ASCII / fullwidth / confusable code points are
/// preserved byte-for-byte), so none is deduped against another. Their raw
/// spelling must survive to the rendered chip — a one-sided canonicalisation
/// to `KVMIP`/`HTML5` is exactly the divergence this guard catches.
const List<String> _denseTokens = <String>[
  'KVMIP',
  'HTML5',
  'SSH',
  'VNC',
  'RFB',
  'IPMI',
  'RDP',
  'SPICE',
  '\uFF2F\uFF25\uFF2D', // fullwidth OEM (ＯＥＭ) — non-ASCII, distinct
  'KVM\u0131P', // dotless-i confusable — preserved, never folds to KVMIP
  'kvmip2',
  'HTML5-V2',
  '\u017FSH', // long-s confusable — preserved, never folds to SSH
];

const String _managerId = 'BMC';
const String _secureUri = 'https://bmc.example/kvm';

/// Raw `ConnectTypesSupported` payload: the 13 distinct tokens plus
/// padded-duplicate / blank / non-string noise that the model must drop or
/// dedup, leaving [_denseTokens] byte-exact.
List<dynamic> _rawTypes() => <dynamic>[
      ..._denseTokens,
      ' KVMIP ', // padded duplicate -> deduped away
      'HTML5', // duplicate -> deduped away
      '', // blank -> dropped
      '   ', // whitespace -> dropped
      42, // non-string -> dropped
      null, // non-string -> dropped
    ];

Map<String, dynamic> _denseBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': _rawTypes(),
        'ConnectUri': _secureUri,
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

/// Builds the real `KvmView` (capability card + every per-console card) from one
/// manager projection. Only upstream data providers are overridden, so both
/// real card implementations render — a one-sided chip edit is caught in one
/// tree.
Future<void> _pumpCards(
  WidgetTester tester, {
  required Map<String, dynamic> managerBody,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles =
      KvmConsole.fromManager(managerBody, managerId: _managerId);
  final KvmCapability capability =
      KvmCapability.fromManager(managerBody, managerId: _managerId);
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

/// The per-console card is the Card ancestor of its merged manager label.
Finder _consoleCard() => find.ancestor(
      of: find.bySemanticsLabel('Manager: $_managerId'),
      matching: find.byType(Card),
    );

/// Byte-exact chip labels rendered inside a given merged chip-row node.
List<String> _chipLabels(WidgetTester tester, Finder node) => tester
    .widgetList<Text>(
      find.descendant(of: node, matching: find.byType(Text)),
    )
    .map((Text t) => t.data ?? '')
    .toList(growable: false);

void main() {
  group('EP-U27 dense connect-type chip-set a11y agreement (#009/#021)', () {
    test('both factories preserve the 13-token hostile set byte-exact', () {
      final Map<String, dynamic> body = _denseBody();
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: _managerId);
      final KvmCapability cap =
          KvmCapability.fromManager(body, managerId: _managerId);

      expect(consoles, hasLength(1));
      expect(consoles.single.connectTypesSupported, _denseTokens,
          reason: 'console token set trimmed + deduped, spelling preserved');
      expect(cap.connectTypes, _denseTokens,
          reason: 'capability token set agrees byte-exact');
      expect(consoles.single.connectTypesSupported, cap.connectTypes,
          reason: 'both model projections agree field-for-field');

      // No confusable silently collapses onto a canonical ASCII token.
      expect(kvmConnectTypeEquals('KVM\u0131P', 'KVMIP'), isFalse);
      expect(_denseTokens.length, 13);
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'both cards: one merged node, byte-exact 13 chips, '
          'no overflow at ${width.toStringAsFixed(0)} px',
          (WidgetTester tester) async {
        await _pumpCards(
          tester,
          width: width,
          managerBody: _denseBody(),
        );

        final String joined = _denseTokens.join(', ');
        final Finder consoleNode =
            find.bySemanticsLabel('Supported connection types: $joined');
        final Finder capNode =
            find.bySemanticsLabel('Connection types: $joined');

        expect(find.byType(KvmCapabilityCard), findsOneWidget);
        expect(_consoleCard(), findsOneWidget);
        expect(consoleNode, findsOneWidget,
            reason: 'console chip row is ONE merged node at $width px');
        expect(capNode, findsOneWidget,
            reason: 'capability chip row is ONE merged node at $width px');

        // Rendered chip content is byte-exact to the model on BOTH cards and
        // agrees across them — a one-sided `.take(n)` cap, reflow-driven chip
        // drop or canonicalisation breaks this and nothing else.
        expect(_chipLabels(tester, consoleNode), _denseTokens,
            reason: 'console chips == model at $width px');
        expect(_chipLabels(tester, capNode), _denseTokens,
            reason: 'capability chips == model at $width px');
        expect(_chipLabels(tester, consoleNode), _chipLabels(tester, capNode),
            reason: 'both cards render the same chip set at $width px');

        // Dense Wrap must not overflow, and no chip announces on its own.
        expect(tester.takeException(), isNull,
            reason: 'no RenderFlex overflow at $width px');
        expect(find.bySemanticsLabel(_denseTokens[9]), findsNothing,
            reason: 'no screen-reader-only split chip at $width px');
      });
    }

    testWidgets('small clean control chip row is unchanged',
        (WidgetTester tester) async {
      await _pumpCards(
        tester,
        width: 320,
        managerBody: <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
            'ConnectUri': _secureUri,
          },
        },
      );
      final List<String> clean = <String>['KVMIP', 'HTML5'];
      expect(
        find.bySemanticsLabel(
            'Supported connection types: ${clean.join(', ')}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Connection types: ${clean.join(', ')}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
