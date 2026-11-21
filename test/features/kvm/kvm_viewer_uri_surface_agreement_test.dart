// #009 / #021 — EP-U14: the in-app viewer renders ONE fail-closed target in
// four places. `KvmConsoleViewerPage.build` reads `console.launchPlan.targetUri`
// into a single `uri` local and uses it for:
//   * the merged `excludeSemantics` "Console URI: …" row label,
//   * the visible `SelectableText(uri)` payload,
//   * the `Clipboard.setData` payload on "Copy console URI",
//   * the "Copied: …" `SnackBar` confirmation text.
//
// EP-U12 pins that the CARD and the VIEWER place the same value on the
// clipboard, but nothing pins the viewer's OWN four renderings as one contract.
// A one-sided edit (e.g. the SnackBar or a11y label falling back to the raw
// `connectUri`, or the row showing a padded value while the clipboard copies a
// trimmed one) could surface a control-bearing / whitespace-padded string to a
// screen-reader or a toast while the clipboard stayed fail-closed, yet every
// existing single-surface test stayed GREEN. This guard fails closed on any
// such divergence across the secure-HTTPS, external-client, plaintext-HTTP and
// control-unsafe URI paths, at 320 / 800 / 1300 px with visible == announced.
//
// Display-only, dependency-free and TLS-safe: no URL is opened, no WebView /
// protocol plugin is imported and production TLS is untouched.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
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

/// One URI path, built from a single console so all four viewer renderings
/// derive from byte-identical model data. [marker] is a control/injection token
/// that must never appear in any rendering (null for well-formed paths).
class _Case {
  const _Case({
    required this.name,
    required this.connectUri,
    this.marker,
  });

  final String name;
  final String connectUri;
  final String? marker;

  KvmConsole console() => KvmConsole(
        type: KvmConsoleType.remote,
        managerId: 'BMC',
        connectTypesSupported: const <String>['HTML5'],
        serviceEnabled: true,
        connectUri: connectUri,
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
}

const List<_Case> _cases = <_Case>[
  _Case(name: 'secure HTTPS', connectUri: 'https://bmc.example/kvm'),
  _Case(name: 'padded HTTPS', connectUri: '  https://bmc.example/console  '),
  _Case(name: 'external VNC', connectUri: 'vnc://bmc.example:5900'),
  _Case(name: 'plaintext HTTP', connectUri: 'http://bmc.example/kvm'),
  _Case(
    name: 'CRLF injection',
    connectUri: 'https://bmc.example/kvm\r\nX-Injected: 1',
    marker: 'X-Injected',
  ),
  _Case(
    name: 'NUL injection',
    connectUri: 'https://bmc.example/kvm\x00evil',
    marker: 'evil',
  ),
];

/// True when [value] carries a C0/DEL control code point.
bool _hasControl(String value) =>
    value.codeUnits.any((int c) => c < 0x20 || c == 0x7f);

/// The single merged `excludeSemantics` node with the given [label].
Finder _mergedNode(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == label,
    );

/// Installs a clipboard capture and returns the recorder; tear-down restores
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

Future<void> _pumpViewer(
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
      child: MaterialApp(home: KvmConsoleViewerPage(console: console)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EP-U14 model single source (#009/#021)', () {
    for (final _Case item in _cases) {
      test(item.name, () {
        final String? target = item.console().launchPlan.targetUri;
        if (target == null) {
          // The hostile cases are the ones that must fail closed to null.
          expect(item.marker, isNotNull,
              reason: 'only control-unsafe paths may have no target');
        } else {
          expect(_hasControl(target), isFalse,
              reason: 'viewer target must be control-safe: ${item.name}');
          if (item.marker != null) {
            expect(target, isNot(contains(item.marker)));
          }
          // Every well-formed path is the trimmed raw URI — the shared gate
          // never rewrites a control-safe target.
          expect(target, item.connectUri.trim());
        }
      });
    }
  });

  group('EP-U14 viewer four-surface agreement (#009/#021)', () {
    for (final _Case item in _cases) {
      testWidgets('${item.name}: row/label/clipboard/snackbar agree at 800 px',
          (WidgetTester tester) async {
        final KvmConsole console = item.console();
        final String? target = console.launchPlan.targetUri;
        final List<Object?> copied = _captureClipboard();
        await _pumpViewer(tester, console, width: 800);

        final Finder copyButton = find.text('Copy console URI');
        if (target == null) {
          // No safe target => no URI row and no copy affordance; the viewer
          // degrades to the fail-closed manager-source notice.
          expect(find.text('Console URI'), findsNothing);
          expect(copyButton, findsNothing);
          expect(find.textContaining('No direct console URI'), findsOneWidget);
        } else {
          final String label = 'Console URI: $target';
          expect(find.text('Console URI'), findsOneWidget);
          expect(_mergedNode(label), findsOneWidget,
              reason: 'merged URI row announced exactly once');
          expect(find.bySemanticsLabel(label), findsOneWidget,
              reason: 'visible row payload equals the announced label');
          expect(
            find.byWidgetPredicate(
                (Widget w) => w is SelectableText && w.data == target),
            findsOneWidget,
            reason: 'the visible SelectableText carries the fail-closed target',
          );
          expect(copyButton, findsOneWidget);

          await tester.tap(copyButton);
          await tester.pumpAndSettle();

          expect(copied, hasLength(1));
          expect(copied.single, target,
              reason: 'clipboard payload is the fail-closed target');
          expect(find.text('Copied: $target'), findsOneWidget,
              reason:
                  'SnackBar carries the same target as the row + clipboard');
          expect(_hasControl(copied.single! as String), isFalse);
          if (item.marker != null) {
            expect(copied.single as String, isNot(contains(item.marker)));
          }
        }
        expect(tester.takeException(), isNull,
            reason: 'viewer must render without overflow');
      });
    }
  });

  group('EP-U14 viewer no-overflow at boundary widths (#009/#021)', () {
    for (final double width in <double>[320, 1300]) {
      final String px = '${width.round()}px';
      final _Case safe =
          _cases.firstWhere((_Case c) => c.name == 'secure HTTPS');
      final _Case unsafe =
          _cases.firstWhere((_Case c) => c.name == 'CRLF injection');

      testWidgets('secure HTTPS ($px): row + copy, no overflow',
          (WidgetTester tester) async {
        final KvmConsole console = safe.console();
        final String target = console.launchPlan.targetUri!;
        await _pumpViewer(tester, console, width: width);
        expect(_mergedNode('Console URI: $target'), findsOneWidget);
        expect(find.text('Copy console URI'), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'secure viewer no-overflow at $px');
      });

      testWidgets('control-unsafe ($px): no row / copy, no overflow',
          (WidgetTester tester) async {
        await _pumpViewer(tester, unsafe.console(), width: width);
        expect(find.text('Console URI'), findsNothing);
        expect(find.text('Copy console URI'), findsNothing);
        expect(tester.takeException(), isNull,
            reason: 'control-unsafe viewer no-overflow at $px');
      });
    }
  });
}
