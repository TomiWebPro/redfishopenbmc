// EP-U16 / #009 / #021: the protocol-specific external-client notice is an
// operator launch-decision message rendered on BOTH the per-console card
// (`KvmView._ConsoleCard`) and the per-manager capability card
// (`KvmCapabilityCard`). Both call the single shared `kvmExternalClientNoticeFor`
// helper, but each card derives its label through its OWN `fromManager` factory
// (`KvmConsole.fromManager` vs `KvmCapability.fromManager`). Nothing previously
// pumped both cards from ONE manager body and asserted that the two rendered
// notices are byte-identical over the FULL external scheme set (vnc/rfb/kvmip/
// kvm/ssh/telnet/ipmi) at 320/800/1300 px.
//
// The single-surface suites (`kvm_widget_test.dart`, `kvm_webui_hint_external_client_test.dart`,
// `kvm_capability_card_test.dart`) each pin one card in isolation (and only for
// vnc/ssh/ipmi); the model suites (EP-M2 / RM-12) pin classification/label
// parity at the MODEL layer. A one-sided VIEW edit — e.g. the console card
// falling back to the generic notice or a hardcoded VNC label — could badge one
// card with "external SSH client" while the other said "external VNC client"
// (or "requires an external client (VNC/RFB, ...)") with every existing suite
// GREEN. That is exactly the #009 cross-view divergence class these guards
// exist to prevent.
//
// Display-only, dependency-free, TLS-safe: no URL opened, no WebView/protocol
// import, no human approval, no production TLS change.

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

/// Every external-client scheme and the fixed protocol label its shared
/// classifier (`externalClientConsoleProtocol`) must produce.
const Map<String, String> _schemeLabels = <String, String>{
  'vnc': 'VNC/RFB',
  'rfb': 'VNC/RFB',
  'kvmip': 'KVMIP',
  'kvm': 'KVMIP',
  'ssh': 'SSH',
  'telnet': 'Telnet',
  'ipmi': 'IPMI serial-over-LAN',
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

/// ONE manager body carrying a single external-client GraphicalConsole, fed to
/// BOTH real `fromManager` factories so the two cards are driven by exactly the
/// same protocol label derivation path.
Map<String, dynamic> _managerBody(String uri) => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
        'ConnectUri': uri,
      },
    };

Future<void> _pumpBothCards(
  WidgetTester tester, {
  required KvmConsole console,
  required KvmCapability capability,
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

Finder _mergedNotice(String notice) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == notice,
    );

void main() {
  group('EP-U16 — both fromManager factories agree on the notice label', () {
    for (final MapEntry<String, String> c in _schemeLabels.entries) {
      test('${c.key}:// resolves the same ${c.value} label on both models', () {
        final Map<String, dynamic> body =
            _managerBody('${c.key}://bmc.example:5900');
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        expect(console.externalClientProtocolLabel, c.value);
        expect(capability.externalClientProtocolLabel, c.value);
        expect(console.requiresExternalConsoleClient, isTrue);
        expect(capability.requiresExternalConsoleClient, isTrue);
        // The wording both views will render is byte-identical because both
        // call the one shared helper with the same label.
        expect(
          kvmExternalClientNoticeFor(console.externalClientProtocolLabel),
          kvmExternalClientNoticeFor(capability.externalClientProtocolLabel),
        );
      });
    }
  });

  group('EP-U16 — rendered notice agreement across both cards', () {
    for (final MapEntry<String, String> c in _schemeLabels.entries) {
      for (final double width in <double>[320, 800, 1300]) {
        testWidgets(
          '${c.key}:// renders one byte-identical "${c.value}" notice on '
          'both cards at ${width.toInt()} px (visible == announced)',
          (WidgetTester tester) async {
            final Map<String, dynamic> body =
                _managerBody('${c.key}://bmc.example:5900');
            final KvmConsole console =
                KvmConsole.fromManager(body, managerId: 'BMC').single;
            final KvmCapability capability =
                KvmCapability.fromManager(body, managerId: 'BMC');
            final String notice = kvmExternalClientNoticeFor(c.value);
            expect(notice, contains('external ${c.value} client'));

            await _pumpBothCards(
              tester,
              console: console,
              capability: capability,
              width: width,
            );

            // The console card and the capability card both render the SAME
            // shared string — one visible Text each, byte-for-byte identical.
            expect(find.text(notice), findsNWidgets(2),
                reason: 'both cards must show the identical protocol notice');
            // Each visible Text sits inside its own single merged
            // `excludeSemantics` node whose label equals the visible text, so
            // a screen reader hears exactly what a sighted operator reads.
            expect(_mergedNotice(notice), findsNWidgets(2));
            for (final Finder textFinder in <Finder>[find.text(notice)]) {
              expect(
                find.ancestor(
                  of: textFinder,
                  matching: _mergedNotice(notice),
                ),
                findsNWidgets(2),
              );
            }
            // No one-sided fallback to the generic notice, no plaintext-HTTP
            // warning leak, no control/injection marker, and no overflow.
            expect(find.text(kvmExternalClientNotice), findsNothing);
            expect(find.text(kvmInsecureTransportNotice), findsNothing);
            expect(find.textContaining('INJECT'), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
