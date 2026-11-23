// EP-U26-residual (issues #009 / #021): the console card's copy-confirmation
// SnackBar is the visible operator feedback for the fail-closed clipboard
// action, yet NO existing test asserts its text.
//
// AUDIT FIRST (why this is a genuine, unguarded seam, not churn):
//   * `kvm_clipboard_cross_surface_agreement_test.dart` (EP-U12) taps the card's
//     "Copy connect info" but inspects ONLY the `Clipboard.setData` channel; it
//     never looks at the card's `Copied: …` SnackBar.
//   * `kvm_widget_test.dart` likewise asserts `copied.single`, not the SnackBar.
//   * `kvm_viewer_uri_surface_agreement_test.dart` (EP-U14) pins the VIEWER's
//     `Copied: $target` SnackBar (`kvm_console_viewer_page.dart`), a different
//     view with a different SnackBar site.
//   * `notice_single_source_guard_test.dart` guards the canonical notice
//     constants; the `'Copied: '` confirmation string is not among them.
//   * repo-wide `grep 'Copied:' test/` returns only the viewer assertion above.
// So the card site `lib/features/kvm/views/kvm_view.dart`:
//     SnackBar(content: Text('Copied: $targetUri'))
// is unasserted. A plausible one-sided refactor — showing the operator the raw
// `console.launchUri` ("copied exactly what you asked for") — would keep the
// clipboard channel fail-closed and every existing suite GREEN while the card's
// confirmation re-surfaces the CRLF/NUL/injection-bearing endpoint to the
// operator. This guard closes that seam.
//
// It pins, over ONE hostile-authority matrix derived from a single console:
//   * the card SnackBar carries EXACTLY the fail-closed `clipboardTargetUri`;
//   * it never carries a raw control / injected marker;
//   * it is byte-identical to the clipboard payload and to the viewer SnackBar
//     when both surfaces offer copy;
//   * the merged copy affordance's visible text == announced label, with no
//     RenderFlex overflow at 320 / 800 / 1300 px.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView or
// protocol dependency is imported and production TLS is untouched.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
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

const List<_Case> _cases = <_Case>[
  _Case(
    name: 'CRLF ConnectUri',
    connectUri: 'https://bmc.example/kvm\r\nX-Injected: 1',
    sourceManagerUri: '/redfish/v1/Managers/BMC',
    marker: 'X-Injected',
  ),
  _Case(
    name: 'NUL ConnectUri',
    connectUri: 'https://bmc.example/kvm\x00evil',
    sourceManagerUri: '/redfish/v1/Managers/BMC',
    marker: 'evil',
  ),
  _Case(
    name: 'raw-space ConnectUri',
    connectUri: 'https://bmc.example/kvm with space',
    sourceManagerUri: '/redfish/v1/Managers/BMC',
    marker: 'with space',
  ),
  _Case(
    name: 'malformed-percent ConnectUri',
    connectUri: 'https://bmc.example/kvm%zz',
    sourceManagerUri: '/redfish/v1/Managers/BMC',
    marker: '%zz',
  ),
  _Case(
    name: 'hostile manager source',
    connectUri: null,
    sourceManagerUri: '/redfish/v1/Managers/BMC\r\nX-Injected: 1',
    marker: 'X-Injected',
  ),
  _Case(
    name: 'valid padded URI with hostile source',
    connectUri: '  https://bmc.example/console  ',
    sourceManagerUri: '/redfish/v1/Managers/BMC\r\nX-Injected: 1',
    marker: 'X-Injected',
  ),
];

class _Case {
  const _Case({
    required this.name,
    required this.connectUri,
    required this.sourceManagerUri,
    required this.marker,
  });

  final String name;
  final String? connectUri;
  final String sourceManagerUri;
  final String marker;

  KvmConsole console() => KvmConsole(
        type: KvmConsoleType.remote,
        managerId: 'BMC',
        connectTypesSupported: const <String>['HTML5'],
        serviceEnabled: true,
        connectUri: connectUri,
        sourceManagerUri: sourceManagerUri,
      );
}

bool _hasControl(String value) =>
    value.codeUnits.any((int c) => c < 0x20 || c == 0x7f);

List<Object?> _captureClipboard() {
  final List<Object?> copied = <Object?>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform,
          (MethodCall call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add(call.arguments['text']);
    }
    return null;
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return copied;
}

/// Only the copy-confirmation SnackBar texts, never the card's visible raw
/// `Connect URI:` row (which intentionally shows the raw endpoint, fail open
/// on display, fail closed on copy).
List<String> _snackTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.byWidgetPredicate(
        (Widget w) => w is Text && (w.data ?? '').startsWith('Copied: ')))
    .map((Text w) => w.data!)
    .toList();

ProviderScope _scopeFor(KvmConsole console, {required Widget home}) {
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  return ProviderScope(
    overrides: <Override>[
      systemHandleProvider('bmc1').overrideWithValue(_handle()),
      kvmControllerProvider.overrideWith((ref, id) => controller),
    ],
    child: MaterialApp(home: home),
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  KvmConsole console, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_scopeFor(
    console,
    home: const Scaffold(body: KvmView(systemId: 'bmc1')),
  ));
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
  await tester.pumpWidget(_scopeFor(
    console,
    home: KvmConsoleViewerPage(console: console),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('card copy-confirmation SnackBar fail-closed (#009/#021)', () {
    for (final _Case item in _cases) {
      testWidgets(
          '${item.name}: card SnackBar shows exactly the '
          'fail-closed target', (WidgetTester tester) async {
        final KvmConsole console = item.console();
        final List<Object?> copied = _captureClipboard();

        await _pumpCard(tester, console, width: 800);
        expect(find.text('Copy connect info'), findsOneWidget);

        // Visible text == announced label of the merged copy affordance.
        expect(find.bySemanticsLabel('Copy connect info'), findsOneWidget);

        await tester.tap(find.text('Copy connect info'));
        await tester.pumpAndSettle();

        expect(copied, hasLength(1));
        final String payload = copied.single! as String;
        expect(payload, console.clipboardTargetUri,
            reason: 'clipboard stays the model single source: ${item.name}');

        // THE NEW INVARIANT: the card's confirmation mirrors the fail-closed
        // clipboard target exactly — never the raw ConnectUri / manager source.
        final List<String> snacks = _snackTexts(tester);
        expect(snacks, hasLength(1),
            reason: 'exactly one card copy confirmation: ${item.name}');
        expect(snacks.single, 'Copied: $payload',
            reason: 'card SnackBar == clipboard payload: ${item.name}');
        expect(snacks.single, 'Copied: ${console.clipboardTargetUri}',
            reason: 'card SnackBar == model single source: ${item.name}');
        for (final String snack in snacks) {
          expect(_hasControl(snack), isFalse,
              reason: 'SnackBar carries no raw control: ${item.name}');
          expect(snack, isNot(contains(item.marker)),
              reason: 'SnackBar never re-surfaces the injected endpoint: '
                  '${item.name}');
        }
        expect(tester.takeException(), isNull,
            reason: 'card renders without overflow: ${item.name}');
      });
    }

    testWidgets(
        'clean secure HTTPS: SnackBar == clipboard == '
        'launchPlan target byte-exact', (WidgetTester tester) async {
      const String uri = 'https://bmc.example/console';
      const KvmConsole console = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: const <String>['HTML5'],
        serviceEnabled: true,
        connectUri: uri,
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      final List<Object?> copied = _captureClipboard();

      await _pumpCard(tester, console, width: 800);
      await tester.tap(find.text('Copy connect info'));
      await tester.pumpAndSettle();

      expect(console.launchPlan.targetUri, uri);
      expect(copied.single, uri);
      expect(_snackTexts(tester), <String>['Copied: $uri']);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'card SnackBar == viewer SnackBar byte-identical for the '
        'same console', (WidgetTester tester) async {
      // A padded-but-valid secure URI with a hostile manager source: the
      // launch plan keeps the trimmed secure target, so BOTH surfaces offer
      // copy and their confirmations must be byte-identical.
      final _Case item = _cases.firstWhere(
          (_Case c) => c.name == 'valid padded URI with hostile source');
      final KvmConsole console = item.console();
      expect(console.launchPlan.targetUri, isNotNull);

      final List<Object?> copied = _captureClipboard();

      await _pumpCard(tester, console, width: 800);
      await tester.tap(find.text('Copy connect info'));
      await tester.pumpAndSettle();
      final List<String> cardSnacks = _snackTexts(tester);
      expect(cardSnacks, hasLength(1));
      final String cardConfirmation = cardSnacks.single;
      expect(cardConfirmation, 'Copied: ${console.launchPlan.targetUri}');

      copied.clear();
      await _pumpViewer(tester, console, width: 800);
      await tester.tap(find.text('Copy console URI'));
      await tester.pumpAndSettle();
      final List<String> viewerSnacks = _snackTexts(tester);
      expect(viewerSnacks, hasLength(1));
      expect(viewerSnacks.single, cardConfirmation,
          reason: 'card and viewer confirm the identical fail-closed target');
    });

    for (final String name in <String>[
      'CRLF ConnectUri',
      'valid padded URI with hostile source',
    ]) {
      final _Case item = _cases.firstWhere((_Case c) => c.name == name);
      for (final double width in <double>[320, 1300]) {
        testWidgets(
            '${item.name}: copy confirmation present, no overflow '
            'at ${width.toStringAsFixed(0)} px', (WidgetTester tester) async {
          final KvmConsole console = item.console();
          _captureClipboard();

          await _pumpCard(tester, console, width: width);
          await tester.tap(find.text('Copy connect info'));
          await tester.pumpAndSettle();

          expect(_snackTexts(tester),
              <String>['Copied: ${console.clipboardTargetUri}']);
          expect(tester.takeException(), isNull,
              reason: 'card no-overflow at $width px');
        });
      }
    }
  });
}
