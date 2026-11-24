// EP-U41 (issues #009 / #021) — RTL x 2.0x COMPOUND a11y agreement for the
// fail-closed "copy connect info" / "copy console URI" affordances across the
// two KVM operator surfaces that offer copy (the per-console card and the
// console viewer).
//
// AUDIT FIRST (why this is a genuine, unguarded seam, not churn):
//   * `kvm_clipboard_cross_surface_agreement_test.dart` (EP-U12) pins that the
//     card ALWAYS offers a fail-closed copy target and that the clipboard
//     payloads agree, and `kvm_copy_only_browser_open_route_agreement_test.dart`
//     (EP-U18) pins the copy-only route on all three surfaces — but both use
//     `find.text('Copy connect info')` / `find.text('Copy console URI')`, i.e.
//     they look only at the VISIBLE Text of the buttons.
//   * `kvm_card_copy_confirmation_snackbar_agreement_test.dart` (EP-U26-residual)
//     pins the card's `Copied: …` SnackBar text, not the buttons' announced
//     Semantics labels.
//   * The compound RTL x 2.0x family (EP-U31..U40) drives chips, display names,
//     notices, the raw URI, the session-limit row, the Primary badge and the
//     non-populated states through the operator cards under RTL AND a 2.0x
//     scaler — but NONE drives the copy-affordance buttons themselves.
// So an otherwise-plausible one-sided "make the copy button announcement more
// descriptive" edit — wrapping ONE surface's copy button in an explicit
// `Semantics(label: 'Copy connection info', excludeSemantics: true)` while the
// visible Text stays byte-identical — would leave EVERY existing suite GREEN
// (they all assert visible Text) yet desynchronise the screen-reader label on
// that surface. This guard closes that seam.
//
// It pins, at 320 / 800 / 1300 px under RTL + a 2.0x TextScaler:
//   * exactly one merged Semantics node per copy affordance, whose announced
//     label equals its visible Text (no screen-reader-only duplicate, no
//     split label), on the console card and on the viewer;
//   * no competing / reworded copy label is announced anywhere on the surface;
//   * no `RenderFlex` overflow at any width; and
//   * LTR / 1.0x controls stay byte-exact.
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
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

const String kCardCopyLabel = 'Copy connect info';
const String kViewerCopyLabel = 'Copy console URI';

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

/// One manager with a single enabled secure-HTTPS HTML5 GraphicalConsole, so
/// both the console card and the viewer offer a real, navigable copy target.
Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': 'https://bmc.example/kvm',
        'MaxConcurrentSessions': 2,
      },
    };

List<KvmConsole> _consoles() =>
    KvmConsole.fromManager(_managerBody(), managerId: 'BMC');

Future<void> _pumpKvmView(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles = _consoles();
  final KvmCapability capability =
      KvmCapability.fromManager(_managerBody(), managerId: 'BMC');
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

Future<void> _pumpViewer(WidgetTester tester, KvmConsole console) async {
  tester.view.physicalSize = const Size(800, 1200);
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
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData.fromView(tester.view)
                .copyWith(textScaler: const TextScaler.linear(2.0)),
            child: KvmConsoleViewerPage(console: console),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The announced label of a copy affordance is a single merged node whose
/// visible Text is byte-exact and lives INSIDE that node; no separate /
/// screen-reader-only node announces a reworded copy label.
void _expectSingleMergedCopyAffordance(
  WidgetTester tester,
  String label,
  String px,
) {
  expect(find.bySemanticsLabel(label), findsOneWidget,
      reason: 'exactly one merged copy affordance "$label" at ${px}px');
  expect(find.text(label), findsOneWidget,
      reason: 'exactly one visible "$label" at ${px}px');
  expect(
    find.descendant(
      of: find.bySemanticsLabel(label),
      matching: find.text(label),
    ),
    findsOneWidget,
    reason: 'visible copy text lives inside the announced node at ${px}px',
  );
  expect(
    find.bySemanticsLabel(RegExp(r'^Copy connection')),
    findsNothing,
    reason: 'no split / reworded screen-reader-only copy label at ${px}px',
  );
}

void main() {
  group(
      'EP-U41 copy-affordance single-merged a11y agreement under RTL x 2.0x '
      '(#009/#021)', () {
    test('the manager yields one openable secure console with a copy target',
        () {
      final List<KvmConsole> consoles = _consoles();
      expect(consoles, hasLength(1));
      expect(consoles.single.canOpenConsole, isTrue);
      expect(consoles.single.launchPlan.targetUri, 'https://bmc.example/kvm');
    });

    for (final double width in <double>[320, 800, 1300]) {
      final String px = width.toStringAsFixed(0);

      testWidgets(
          'console card copy affordance is one merged node at '
          '${px}px RTL 2.0x', (WidgetTester tester) async {
        await _pumpKvmView(tester, width: width, rtl: true, scale: 2.0);
        _expectSingleMergedCopyAffordance(tester, kCardCopyLabel, px);
        expect(tester.takeException(), isNull,
            reason: 'copy affordance must not overflow at ${px}px RTL 2.0x');
      });

      testWidgets(
          'viewer copy affordance is one merged node at '
          '${px}px RTL 2.0x', (WidgetTester tester) async {
        await _pumpViewer(tester, _consoles().single);
        _expectSingleMergedCopyAffordance(tester, kViewerCopyLabel, px);
        expect(tester.takeException(), isNull,
            reason: 'viewer copy affordance must not overflow at RTL 2.0x');
      });
    }

    testWidgets('LTR / 1.0x control keeps both copy labels byte-exact',
        (WidgetTester tester) async {
      await _pumpKvmView(tester, width: 320, rtl: false, scale: 1.0);
      _expectSingleMergedCopyAffordance(tester, kCardCopyLabel, '320 LTR1.0x');
      expect(tester.takeException(), isNull);
    });
  });
}
