// EP-U44 / #009 / #021: RTL x 2.0x COMPOUND a11y agreement for the shared
// insecure-transport notice (`kvmInsecureTransportNotice`, the
// "Unencrypted HTTP console URI" warning) across both KVM operator cards
// (per-console card in `KvmView` + per-manager `KvmCapabilityCard`) and the
// per-console viewer's distinct merged launch-status node.
//
// AUDIT FIRST (see queues/ui.md EP-U44): the insecure-transport notice copy is
// already single-sourced by `kvm_transport_notice.dart` and mechanically pinned
// by `test/tool/notice_single_source_guard_test.dart` (constants), and the two
// cards' LTR / 1.0x rendering is spot-checked in `kvm_capability_card_test.dart`
// / `kvm_widget_test.dart` / `kvm_open_affordance_gating_test.dart`. The RTL x
// 2.0x compound family (EP-U31..U43) drove chips, display names, the two shared
// notices, the external-client notice, the raw URI, the session-limit row, the
// Primary badge, the manager-source row and the copy affordance — but NEVER the
// insecure-transport notice row. Nothing drove a plaintext-HTTP endpoint
// through BOTH cards' merged warning nodes and the viewer under RTL + 2.0x,
// the compound setting where a plausible one-sided "RTL needs its own unencrypted
// warning wording" edit on ONE surface (splitting its merged node or announcing
// a reworded label) could desync a screen reader while every single-axis suite
// stayed GREEN. This guard closes that seam.
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
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A plaintext-HTTP endpoint: the shared classifier must mark it insecure on
/// both models (never a secure/in-app render candidate). HTML5 is advertised so
/// the viewer resolves the (distinct) `insecureHtml5` launch-status message.
const String _uri = 'http://bmc.example/kvm';

/// The single warning both operator cards render (visible == announced).
String get _notice => kvmInsecureTransportNotice;

KvmConsole _console() => const KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      connectUri: _uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

KvmCapability _capability() => const KvmCapability(
      managerId: 'BMC',
      supported: true,
      connectTypes: const <String>['HTML5'],
      serviceEnabled: true,
      uri: _uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

/// ONE manager body driving both real `fromManager` factories, so the model
/// agreement is exercised on the production derivation path too.
Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': _uri,
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

/// The single merged `excludeSemantics` node whose label is exactly [label].
Finder _mergedNotice(String label) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == label,
    );

/// Applies the compound direction + font scale above the surface under test.
Widget _directionScale(
  WidgetTester tester,
  Widget child, {
  required bool rtl,
  required double scale,
}) =>
    Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData.fromView(tester.view)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    );

Future<void> _pumpView(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[_console()]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) =>
              Future<List<KvmCapability>>.value(<KvmCapability>[_capability()]),
        ),
      ],
      child: MaterialApp(
        home: _directionScale(
          tester,
          const KvmView(systemId: 'bmc1'),
          rtl: rtl,
          scale: scale,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpCapabilityCard(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: _directionScale(
        tester,
        KvmCapabilityCard(capability: _capability()),
        rtl: rtl,
        scale: scale,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required double width,
  required bool rtl,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: _directionScale(
          tester,
          KvmConsoleViewerPage(console: _console()),
          rtl: rtl,
          scale: scale,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  /// The viewer intentionally uses its own, more detailed status message —
  /// computed by the same pure resolver the viewer uses — not the card warning.
  String viewerStatus(KvmConsole console) => kvmLaunchStatusText(
        console.launchStrategy,
        externalProtocol: console.externalClientProtocolLabel,
      );

  group('EP-U44 — insecure-transport notice RTL x 2.0x compound agreement', () {
    test(
        'both fromManager factories agree on the insecure-transport verdict '
        'and the shared byte-exact notice', () {
      final Map<String, dynamic> body = _managerBody();
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.usesInsecureHttpLaunchUri, isTrue);
      expect(capability.usesInsecureHttpLaunchUri, isTrue);
      // One shared const string backs both cards' visible + announced warning.
      expect(_notice, kvmInsecureTransportNotice);
      // The viewer's status is distinct by design, but deterministic from the
      // same model strategy on both the direct and factory-derived console.
      expect(viewerStatus(console), viewerStatus(_console()));
      expect(viewerStatus(console), isNot(_notice));
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'both operator cards: one merged byte-exact insecure notice each '
          'under RTL + 2.0x at ${width}px', (WidgetTester tester) async {
        await _pumpView(tester, width: width, rtl: true, scale: 2.0);
        expect(find.text(_notice), findsNWidgets(2),
            reason: 'one visible insecure warning on each operator card');
        expect(_mergedNotice(_notice), findsNWidgets(2),
            reason: 'one merged insecure warning node on each operator card');
        expect(
          find.ancestor(
            of: find.text(_notice),
            matching: _mergedNotice(_notice),
          ),
          findsNWidgets(2),
          reason: 'visible warning must live inside its merged node on both',
        );
        expect(tester.takeException(), isNull, reason: 'no RTL/2.0x overflow');
      });

      testWidgets(
          'capability card alone: visible == announced, no reworded '
          'screen-reader-only insecure notice at ${width}px',
          (WidgetTester tester) async {
        await _pumpCapabilityCard(tester, width: width, rtl: true, scale: 2.0);
        expect(find.text(_notice), findsOneWidget);
        expect(_mergedNotice(_notice), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text(_notice),
            matching: _mergedNotice(_notice),
          ),
          findsOneWidget,
        );
        // No second, reworded `excludeSemantics` node announcing a different
        // unencrypted-warning string while the visible Text stays correct.
        final int reworded = find
            .byWidgetPredicate((Widget widget) =>
                widget is Semantics &&
                widget.container &&
                widget.excludeSemantics &&
                widget.properties.label != null &&
                widget.properties.label!
                    .toLowerCase()
                    .contains('unencrypted') &&
                widget.properties.label != _notice)
            .evaluate()
            .length;
        expect(reworded, 0,
            reason: 'no reworded screen-reader-only insecure warning');
        expect(tester.takeException(), isNull, reason: 'no RTL/2.0x overflow');
      });

      testWidgets(
          'viewer merged launch-status node is byte-exact under RTL + 2.0x '
          'at ${width}px', (WidgetTester tester) async {
        await _pumpViewer(tester, width: width, rtl: true, scale: 2.0);
        final String status = viewerStatus(_console());
        expect(find.text(status), findsOneWidget);
        expect(_mergedNotice(status), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text(status),
            matching: _mergedNotice(status),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'no RTL/2.0x overflow');
      });
    }

    testWidgets(
        'LTR / 1.0x control: both cards keep one merged byte-exact warning',
        (WidgetTester tester) async {
      await _pumpView(tester, width: 800, rtl: false, scale: 1.0);
      expect(_mergedNotice(_notice), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
