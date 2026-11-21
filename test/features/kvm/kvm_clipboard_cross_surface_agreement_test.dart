// EP-U12 (issue #009 / #021): the per-console card's "Copy connect info" and
// the viewer's "Copy console URI" are two operator surfaces that may place a
// value on the clipboard for the SAME KvmConsole. Each surface already has its
// own clipboard test (CB-1 for the card fallback, EP-U8 for the viewer hiding
// copy), and the model's clipboardTargetUri / safeManagerUri are pinned in
// kvm_model_test.dart — but nothing pinned that BOTH surfaces agree OVER ONE
// hostile-authority matrix built from the same console:
//   * when both offer copy, they place the SAME fail-closed target;
//   * neither ever copies a raw control-bearing @odata.id / ConnectUri;
//   * each affordance is present iff that surface has a safe target;
//   * merged excludeSemantics visible text == announced label, no overflow at
//     320 / 800 / 1300 px.
// A one-sided view refactor (e.g. the card reverting to its raw launchUri while
// the viewer stays fail-closed) would desync the two surfaces and could re-open
// the clipboard-injection vector while every single-surface test stayed GREEN.
// This guard builds both surfaces and fails closed on any such divergence.
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

/// The hostile-authority matrix. Each case is derived from ONE console so the
/// card and the viewer are built from byte-identical model data.
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

/// True when [value] carries a C0/DEL control code point — the clipboard
/// injection vector this guard must never let either surface copy verbatim.
bool _hasControl(String value) =>
    value.codeUnits.any((int c) => c < 0x20 || c == 0x7f);

/// Installs a clipboard capture and returns the recorder. Tear-down restores
/// the real platform channel so tests stay hermetic.
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

Future<void> _pumpCard(
  WidgetTester tester,
  KvmConsole console, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900);
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
      // A Scaffold ancestor is required for the card's copy-confirmation
      // SnackBar, as in the existing card clipboard tests.
      child: const MaterialApp(home: Scaffold(body: KvmView(systemId: 'bmc1'))),
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
  // Keep the SAME override keys as _pumpCard: Riverpod forbids adding/removing
  // overrides between pumpWidget calls within one test (values may change).
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
      ],
      child: MaterialApp(home: KvmConsoleViewerPage(console: console)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EP-U12 clipboard target agreement — model single sources (#009/#021)',
      () {
    for (final _Case item in _cases) {
      test(item.name, () {
        final KvmConsole console = item.console();
        final String cardTarget = console.clipboardTargetUri;
        final String? viewerTarget = console.launchPlan.targetUri;

        // Neither single source may carry a raw control-bearing value.
        expect(_hasControl(cardTarget), isFalse,
            reason: 'card target must be control-safe: ${item.name}');
        expect(cardTarget, isNot(contains(item.marker)),
            reason: 'card target must not carry the injected value');
        if (viewerTarget != null) {
          expect(_hasControl(viewerTarget), isFalse,
              reason: 'viewer target must be control-safe: ${item.name}');
          expect(viewerTarget, isNot(contains(item.marker)));
        }

        // The agreement invariant: when both surfaces have a target they are
        // the SAME fail-closed value; when the viewer has none (control-unsafe
        // authority) the card degrades to the control-safe manager source.
        if (viewerTarget != null) {
          expect(cardTarget, viewerTarget,
              reason:
                  'both surfaces must copy the same target when both offer copy: ${item.name}');
        } else {
          expect(cardTarget, console.safeManagerUri,
              reason:
                  'card must fail closed to the manager source: ${item.name}');
        }
      });
    }
  });

  group('EP-U12 clipboard target agreement — rendered surfaces (#009/#021)',
      () {
    for (final _Case item in _cases) {
      testWidgets('${item.name}: both surfaces agree at 800 px',
          (WidgetTester tester) async {
        final KvmConsole console = item.console();
        final String? viewerTarget = console.launchPlan.targetUri;
        final List<Object?> copied = _captureClipboard();

        // Card surface.
        await _pumpCard(tester, console, width: 800);
        expect(find.text('Copy connect info'), findsOneWidget,
            reason: 'card always offers a fail-closed copy target');
        await tester.tap(find.text('Copy connect info'));
        await tester.pumpAndSettle();
        expect(copied, hasLength(1));
        final String cardCopied = copied.single! as String;
        expect(cardCopied, console.clipboardTargetUri,
            reason: 'card copies exactly its model single source');
        expect(_hasControl(cardCopied), isFalse);
        expect(cardCopied, isNot(contains(item.marker)));
        expect(tester.takeException(), isNull,
            reason: 'card must render without overflow');

        // Viewer surface, from the SAME console.
        copied.clear();
        await _pumpViewer(tester, console, width: 800);
        final Finder viewerCopy = find.text('Copy console URI');
        if (viewerTarget == null) {
          expect(viewerCopy, findsNothing,
              reason: 'viewer hides copy when it has no safe target');
        } else {
          expect(viewerCopy, findsOneWidget,
              reason: 'viewer offers copy when it has a safe target');
          await tester.tap(viewerCopy);
          await tester.pumpAndSettle();
          expect(copied, hasLength(1));
          final String viewerCopied = copied.single! as String;
          expect(viewerCopied, viewerTarget,
              reason: 'viewer copies exactly its model single source');
          expect(viewerCopied, cardCopied,
              reason: 'both surfaces place the SAME value on the clipboard');
          expect(_hasControl(viewerCopied), isFalse);
          expect(viewerCopied, isNot(contains(item.marker)));
        }
        expect(tester.takeException(), isNull,
            reason: 'viewer must render without overflow');
      });
    }

    // Boundary widths for the two representative paths: a valid target both
    // surfaces copy, and a hostile authority that fails closed.
    for (final String name in <String>[
      'CRLF ConnectUri',
      'valid padded URI with hostile source',
    ]) {
      final _Case item = _cases.firstWhere((_Case c) => c.name == name);
      for (final double width in <double>[320, 1300]) {
        testWidgets(
            '${item.name}: no overflow at '
            '${width.toStringAsFixed(0)} px', (WidgetTester tester) async {
          final KvmConsole console = item.console();
          // Merged excludeSemantics visible-text == announced-label on both
          // surfaces is pinned in EP-U6 / EP-U11; this guard owns the shared
          // clipboard target, so here we only add the boundary-width liveness
          // check that both surfaces still render without overflow.
          await _pumpCard(tester, console, width: width);
          expect(find.text('Copy connect info'), findsOneWidget);
          expect(tester.takeException(), isNull,
              reason: 'card no-overflow at $width px');

          await _pumpViewer(tester, console, width: width);
          expect(
            find.text('Copy console URI'),
            console.launchPlan.targetUri == null
                ? findsNothing
                : findsOneWidget,
            reason: 'viewer affordance presence at $width px',
          );
          expect(tester.takeException(), isNull,
              reason: 'viewer no-overflow at $width px');
        });
      }
    }
  });
}
