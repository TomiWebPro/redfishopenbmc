// EP-U3 / #009 / #021: launch-guidance consistency for the per-console card.
//
// `KvmConsole.showHtml5WebUiHint` gates the "HTML5 console — open via BMC web
// UI" hint. Its documented purpose is to avoid TWO contradictory launch
// messages for one endpoint: a plaintext-HTTP HTML5 console already carries the
// "configure HTTPS" warning, so it must not also be advertised as normally
// openable. The SAME contradiction exists when the direct endpoint needs an
// external client (VNC/RFB, KVMIP, serial SSH/Telnet/IPMI): the card renders
// `kvmExternalClientNoticeFor(...)`, "copy the URI and open it with a
// compatible client", so also saying "open via BMC web UI" is false, confusing
// guidance on an operator launch-decision surface.
//
// This suite pins the gate contract at the model level (all external-client
// schemes) and at the widget level (the card renders exactly one honest
// guidance notice, visible text == merged announced label, no overflow at
// 320/800/1300 px). Display-only, dependency-free, TLS-safe: no URL opened, no
// WebView/protocol import, no production TLS change.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Mirrors the per-console card's single "open via BMC web UI" hint copy. The
/// positive regression tests below fail if that copy ever changes.
const String _webUiHint = 'HTML5 console — open via BMC web UI.';

KvmConsole _console({
  required String? uri,
  List<String> types = const <String>['HTML5'],
}) =>
    KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: types,
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

/// Every scheme the fail-closed external-client classifier recognizes.
const List<String> _externalSchemes = <String>[
  'vnc',
  'rfb',
  'kvmip',
  'kvm',
  'ssh',
  'telnet',
  'ipmi',
];

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

Future<void> _pumpView(
  WidgetTester tester, {
  required KvmConsole console,
  double? width,
}) async {
  tester.view.physicalSize = Size(width ?? 800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(<KvmCapability>[]),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _mergedNotice(String notice) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == notice,
    );

void main() {
  group('showHtml5WebUiHint suppresses external-client guidance (EP-U3)', () {
    for (final String scheme in _externalSchemes) {
      test('HTML5 console with $scheme:// endpoint shows no web UI hint', () {
        final KvmConsole console = _console(uri: '$scheme://bmc.example:5900');
        expect(console.supportsHtml5, isTrue);
        expect(console.usesInsecureHttpLaunchUri, isFalse,
            reason: 'an external scheme is not plaintext HTTP');
        expect(console.requiresExternalConsoleClient, isTrue,
            reason: '$scheme must be classified as an external client');
        expect(console.showHtml5WebUiHint, isFalse,
            reason: 'external-client notice is the only honest guidance');
      });
    }

    test('HTML5 + multiple advertised types incl. VNC with a vnc:// URI', () {
      final KvmConsole console = _console(
        uri: 'vnc://bmc.example:5900',
        types: const <String>['HTML5', 'VNC'],
      );
      expect(console.requiresExternalConsoleClient, isTrue);
      expect(console.showHtml5WebUiHint, isFalse);
    });

    test('secure HTTPS HTML5 console keeps the web UI hint', () {
      expect(
        _console(uri: 'https://bmc.example/kvm').showHtml5WebUiHint,
        isTrue,
      );
    });

    test('URI-less HTML5 console keeps the web UI hint', () {
      expect(_console(uri: null).showHtml5WebUiHint, isTrue);
    });

    test('plaintext-HTTP HTML5 console still suppresses the web UI hint', () {
      expect(
        _console(uri: 'http://bmc.example/kvm').showHtml5WebUiHint,
        isFalse,
      );
    });

    test('non-HTML5 external-client console never shows the HTML5 hint', () {
      expect(
        _console(
          uri: 'ssh://bmc.example',
          types: const <String>['SSH'],
        ).showHtml5WebUiHint,
        isFalse,
      );
    });
  });

  group('per-console card renders one honest guidance notice (EP-U3)', () {
    final String externalNotice = kvmExternalClientNoticeFor('VNC/RFB');

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('vnc:// HTML5 console: no web UI hint at ${width.widthLabel}',
          (WidgetTester tester) async {
        await _pumpView(
          tester,
          console: _console(uri: 'vnc://bmc.example:5900'),
          width: width,
        );

        // The contradictory "open via BMC web UI" hint must be gone.
        expect(find.text(_webUiHint), findsNothing,
            reason: 'no "open via BMC web UI" hint for an external URI');

        // A single merged a11y node carries the external-client notice, with
        // the visible Text inside that node (visible text == announced label).
        expect(find.text(externalNotice), findsOneWidget);
        expect(_mergedNotice(externalNotice), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text(externalNotice),
            matching: _mergedNotice(externalNotice),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'no overflow');
      });
    }

    testWidgets('secure HTTPS HTML5 console still shows the web UI hint',
        (WidgetTester tester) async {
      await _pumpView(
        tester,
        console: _console(uri: 'https://bmc.example/kvm'),
      );

      expect(find.text(_webUiHint), findsOneWidget);
      expect(_mergedNotice(_webUiHint), findsOneWidget);
      expect(find.text(externalNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Test-only label for width values in test names.
extension _WidthLabel on double {
  String get widthLabel => toStringAsFixed(0);
}
