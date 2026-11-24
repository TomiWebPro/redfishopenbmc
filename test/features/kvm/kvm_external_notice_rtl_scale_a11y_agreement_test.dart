// EP-U43 / #009 / #021: RTL x 2.0x COMPOUND a11y agreement for the
// protocol-specific external-client notice across both KVM operator cards
// (per-console card in `KvmView` + per-manager `KvmCapabilityCard`) and the
// per-console viewer's merged launch-status node.
//
// AUDIT FIRST (see queues/ui.md EP-U43): `kvm_external_notice_cross_surface_agreement_test.dart`
// (EP-U16) pins the SAME byte-exact notice on both real cards over the full
// external scheme set — but only at LTR / 1.0x. `kvm_large_font_cross_surface_a11y_test.dart`
// (EP-U21) drives 2.0x with LONG NAMES, LTR only. The RTL x 2.0x compound
// family (EP-U31..U42) drove chips, display names, shared notices, the raw
// URI, the session-limit row, the Primary badge, the manager-source row and
// the copy affordance — but NEVER the external-client notice row. Nothing
// drove an external-client endpoint through BOTH cards' merged notice nodes
// and the viewer under RTL + 2.0x, the compound setting where a plausible
// one-sided "RTL needs its own external-client wording" edit on ONE surface
// (splitting its merged node or announcing a reworded label) could desync a
// screen reader while every single-axis suite stayed GREEN. This guard closes
// that seam.
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

/// A VNC endpoint: the shared classifier must label it `VNC/RFB` and both
/// models must mark it external-client (never secure-browser / in-app).
const String _uri = 'vnc://bmc.example:5900';
const String _protocol = 'VNC/RFB';

/// The single notice both operator cards render (visible == announced).
String get _notice => kvmExternalClientNoticeFor(_protocol);

/// The viewer's distinct, more detailed merged launch-status message.
String get _viewerStatus => kvmLaunchStatusText(
      KvmLaunchStrategy.externalClient,
      externalProtocol: _protocol,
    );

KvmConsole _console() => const KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['KVMIP'],
      serviceEnabled: true,
      connectUri: _uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

KvmCapability _capability() => const KvmCapability(
      managerId: 'BMC',
      supported: true,
      connectTypes: const <String>['KVMIP'],
      serviceEnabled: true,
      uri: _uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

/// ONE manager body driving both real `fromManager` factories, so the model
/// label agreement is exercised on the production derivation path too.
Map<String, dynamic> _managerBody() => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
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
/// The 2.0x `MediaQuery` is placed INSIDE `MaterialApp.home` (the established
/// arrangement for the compound suites) so both `Directionality.of` and
/// `MediaQuery` resolve on the card widgets.
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
  // A 2.0x scaler makes each card materially taller; give ample height so the
  // check is about horizontal / node structure, not a viewport-height clamp.
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
  group('EP-U43 — external-client notice RTL x 2.0x compound agreement', () {
    test(
        'both fromManager factories agree on the external-client label '
        'and byte-exact notice', () {
      final Map<String, dynamic> body = _managerBody();
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.requiresExternalConsoleClient, isTrue);
      expect(capability.requiresExternalConsoleClient, isTrue);
      expect(console.externalClientProtocolLabel, _protocol);
      expect(capability.externalClientProtocolLabel, _protocol);
      expect(kvmExternalClientNoticeFor(console.externalClientProtocolLabel),
          kvmExternalClientNoticeFor(capability.externalClientProtocolLabel));
      expect(kvmExternalClientNoticeFor(console.externalClientProtocolLabel),
          _notice);
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'both operator cards: one merged byte-exact notice each under '
          'RTL + 2.0x at ${width}px', (WidgetTester tester) async {
        await _pumpView(tester, width: width, rtl: true, scale: 2.0);
        // KvmView renders both real cards; each has exactly one merged
        // external-client notice node and one visible Text inside it.
        expect(find.text(_notice), findsNWidgets(2),
            reason: 'one visible external notice on each operator card');
        expect(_mergedNotice(_notice), findsNWidgets(2),
            reason: 'one merged external notice node on each operator card');
        expect(
          find.ancestor(
            of: find.text(_notice),
            matching: _mergedNotice(_notice),
          ),
          findsNWidgets(2),
          reason: 'visible notice must live inside its merged node on both',
        );
        expect(tester.takeException(), isNull, reason: 'no RTL/2.0x overflow');
      });

      testWidgets(
          'capability card alone: visible == announced, no reworded '
          'screen-reader-only external notice at ${width}px',
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
        // external-client string while the visible Text stays correct.
        final int reworded = find
            .byWidgetPredicate((Widget widget) =>
                widget is Semantics &&
                widget.container &&
                widget.excludeSemantics &&
                widget.properties.label != null &&
                widget.properties.label!.contains('external') &&
                widget.properties.label != _notice)
            .evaluate()
            .length;
        expect(reworded, 0,
            reason: 'no reworded screen-reader-only external notice');
        expect(tester.takeException(), isNull, reason: 'no RTL/2.0x overflow');
      });

      testWidgets(
          'viewer merged launch-status node is byte-exact under RTL + 2.0x '
          'at ${width}px', (WidgetTester tester) async {
        await _pumpViewer(tester, width: width, rtl: true, scale: 2.0);
        expect(find.text(_viewerStatus), findsOneWidget);
        expect(_mergedNotice(_viewerStatus), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text(_viewerStatus),
            matching: _mergedNotice(_viewerStatus),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'no RTL/2.0x overflow');
      });
    }

    testWidgets(
        'LTR / 1.0x control: both cards keep one merged byte-exact notice',
        (WidgetTester tester) async {
      await _pumpView(tester, width: 800, rtl: false, scale: 1.0);
      expect(_mergedNotice(_notice), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
