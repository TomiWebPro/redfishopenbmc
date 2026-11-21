// RM-12 (queue rf-model, epic #009/#021): cross-model external-client
// classifier/label/openability parity through the REAL `fromManager` pipeline.
//
// EP-M2 pinned classifier parity at the model surface and the EP-M2/RM-10
// cross-view tests compare two DIRECTLY constructed models over a small URI
// list. Neither feeds a matrix of external-console URIs through
// `KvmConsole.fromManager` and `KvmCapability.fromManager` — the two factories
// that actually resolve a BMC manager body into what both cards render — nor
// pins `canOpenConsole` / launch-strategy and the protocol-specific external
// guidance agreement. A one-sided edit to a factory's URI resolution could
// badge a console as an external-client target on one card while the capability
// card reports no usable target (the #009 divergence class) with every existing
// single-surface suite GREEN.
//
// Read-only, dependency-free, TLS-safe: pure model classification + pure
// presentation copy, no URL opened, no WebView/protocol import, no production
// TLS weakening. AUDIT: both factories already agree over the full matrix (they
// delegate to the one shared classifier on the same trimmed launch URI), so
// this is a regression guard at a genuinely untested seam, not a behaviour fix.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';

void main() {
  /// A single enabled GraphicalConsole block carrying [uri], i.e. the body both
  /// `fromManager` factories resolve. One block keeps the capability's resolved
  /// URI identical to the console's, so any divergence is a factory/classifier
  /// drift, not a multi-block preference decision (EP-S7/RM-10 territory).
  Map<String, dynamic> bodyFor(String? uri) => <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'ConnectUri': uri,
        },
      };

  KvmConsole consoleOf(String? uri) =>
      KvmConsole.fromManager(bodyFor(uri), managerId: 'BMC').single;

  KvmCapability capabilityOf(String? uri) =>
      KvmCapability.fromManager(bodyFor(uri), managerId: 'BMC');

  group('RM-12 external-client fromManager parity (#009/#021)', () {
    test('full external scheme set agrees through both factories', () {
      const Map<String, String> expectedLabels = <String, String>{
        'vnc://bmc.example:5900': 'VNC/RFB',
        'rfb://bmc.example:5900': 'VNC/RFB',
        'kvmip://bmc.example': 'KVMIP',
        'kvm://bmc.example': 'KVMIP',
        'ssh://bmc.example:22': 'SSH',
        'telnet://bmc.example:23': 'Telnet',
        'ipmi://bmc.example': 'IPMI serial-over-LAN',
      };
      expectedLabels.forEach((String uri, String label) {
        final KvmConsole console = consoleOf(uri);
        final KvmCapability cap = capabilityOf(uri);
        expect(console.requiresExternalConsoleClient, isTrue, reason: uri);
        expect(cap.requiresExternalConsoleClient, isTrue, reason: uri);
        expect(console.externalClientProtocolLabel, label, reason: uri);
        expect(cap.externalClientProtocolLabel, label, reason: uri);
        // Cross-factory agreement, byte-identical resolved target.
        expect(console.externalClientProtocolLabel,
            cap.externalClientProtocolLabel,
            reason: uri);
        expect(console.launchUri, cap.launchUri, reason: uri);
        // An enabled external client is openable (copy/open affordance), and
        // both factories agree on the resolved URI being present.
        expect(console.canOpenConsole, isTrue, reason: uri);
        expect(console.launchStrategy, KvmLaunchStrategy.externalClient,
            reason: uri);
        expect(cap.hasUri, isTrue, reason: uri);
      });
    });

    test('uppercase / mixed-case, padded and opaque external URIs agree', () {
      // Dart lower-cases Uri.scheme, so an uppercase BMC spelling is still a
      // recognised external scheme and both factories must badge it identically.
      for (final String uri in <String>[
        'VNC://bmc.example:5900',
        'Rfb://bmc.example:5900',
        '  vnc://bmc.example:5900  ',
      ]) {
        final KvmConsole console = consoleOf(uri);
        final KvmCapability cap = capabilityOf(uri);
        expect(console.requiresExternalConsoleClient, isTrue, reason: uri);
        expect(cap.requiresExternalConsoleClient, isTrue, reason: uri);
        expect(console.externalClientProtocolLabel,
            cap.externalClientProtocolLabel,
            reason: uri);
        expect(console.launchUri, cap.launchUri, reason: uri);
        expect(console.canOpenConsole, isTrue, reason: uri);
      }
      // An opaque external URI (no authority) is unaffected by the degenerate
      // authority-host gate; both factories still classify it as external.
      const String opaque = 'vnc:host=5900;port=1';
      expect(consoleOf(opaque).requiresExternalConsoleClient, isTrue);
      expect(capabilityOf(opaque).requiresExternalConsoleClient, isTrue);
      expect(consoleOf(opaque).externalClientProtocolLabel,
          capabilityOf(opaque).externalClientProtocolLabel);
      expect(consoleOf(opaque).launchUri, capabilityOf(opaque).launchUri);
      expect(consoleOf(opaque).canOpenConsole, isTrue);
    });

    test('control/CRLF-bearing and degenerate-authority targets fail closed',
        () {
      for (final String uri in <String>[
        'vnc://bmc.exa mple:5900', // raw space
        'ssh://bmc.example/con\rsol', // CR
        'rfb://bmc.example/con\r\nsol', // CRLF
        'vnc://bmc.example/con\u0000sol', // NUL
        'ssh://bmc.example/con\tsol', // TAB
        'telnet://bmc.example/con\u007Fsol', // DEL
        'vnc://bmc\u00A0.example:5900', // NBSP separator
        'vnc://bmc.example/\u200Bx', // zero-width space
        'vnc://./', // degenerate dot-only authority
        'ssh://../', // degenerate dot-dot authority
        'ipmi://%2E%2E/', // pct-encoded dot-dot authority
        'rfb://./console', // degenerate authority with a path
      ]) {
        final KvmConsole console = consoleOf(uri);
        final KvmCapability cap = capabilityOf(uri);
        // Neither view badges a malformed target as a trustworthy external
        // client; neither offers a copy/open affordance.
        expect(console.requiresExternalConsoleClient, isFalse, reason: uri);
        expect(cap.requiresExternalConsoleClient, isFalse, reason: uri);
        expect(console.externalClientProtocolLabel, isNull, reason: uri);
        expect(cap.externalClientProtocolLabel, isNull, reason: uri);
        expect(console.canOpenConsole, isFalse, reason: uri);
        expect(console.launchStrategy, KvmLaunchStrategy.noUri, reason: uri);
        // Both factories agree in the fail-closed direction too.
        expect(console.externalClientProtocolLabel,
            cap.externalClientProtocolLabel,
            reason: uri);
        expect(console.requiresExternalConsoleClient,
            cap.requiresExternalConsoleClient,
            reason: uri);
      }
      // A blank URI resolves to no target on both views.
      expect(consoleOf('   ').canOpenConsole, isFalse);
      expect(capabilityOf('   ').hasUri, isFalse);
      expect(consoleOf('   ').requiresExternalConsoleClient, isFalse);
      expect(capabilityOf('   ').requiresExternalConsoleClient, isFalse);
    });

    test('protocol-specific external-open guidance agrees across both models',
        () {
      const Map<String, String> expectedLabels = <String, String>{
        'vnc://bmc.example:5900': 'VNC/RFB',
        'rfb://bmc.example:5900': 'VNC/RFB',
        'kvmip://bmc.example': 'KVMIP',
        'ssh://bmc.example:22': 'SSH',
        'telnet://bmc.example:23': 'Telnet',
        'ipmi://bmc.example': 'IPMI serial-over-LAN',
      };
      expectedLabels.forEach((String uri, String label) {
        final String consoleGuidance = kvmExternalClientNoticeFor(
            consoleOf(uri).externalClientProtocolLabel);
        final String capGuidance = kvmExternalClientNoticeFor(
            capabilityOf(uri).externalClientProtocolLabel);
        // Both cards hand the SAME label to the SAME helper, so sighted and
        // screen-reader users on either surface hear identical, protocol-
        // specific guidance rather than a generic protocol list.
        expect(consoleGuidance, capGuidance, reason: uri);
        expect(consoleGuidance, isNot(kvmExternalClientNotice), reason: uri);
        expect(consoleGuidance, contains('external $label client'),
            reason: uri);
        expect(consoleGuidance, contains('Copy the URI'), reason: uri);
      });
      // Fail-closed / non-external targets get the identical generic guidance
      // on both surfaces (no misleading per-protocol claim).
      for (final String uri in <String>[
        'vnc://bmc.exa mple:5900',
        'vnc://./',
        'https://bmc.example/kvm',
      ]) {
        expect(
            kvmExternalClientNoticeFor(
                consoleOf(uri).externalClientProtocolLabel),
            kvmExternalClientNoticeFor(
                capabilityOf(uri).externalClientProtocolLabel),
            reason: uri);
      }
    });

    test('unknown scheme fails closed identically on both views', () {
      // A scheme outside the known external-client set is never badged as a
      // trustworthy external endpoint on either surface (fail closed).
      const String uri = 'MiXeD://bmc.example:5900';
      final KvmConsole console = consoleOf(uri);
      final KvmCapability cap = capabilityOf(uri);
      expect(console.requiresExternalConsoleClient, isFalse);
      expect(cap.requiresExternalConsoleClient, isFalse);
      expect(console.externalClientProtocolLabel, isNull);
      expect(cap.externalClientProtocolLabel, isNull);
      expect(console.canOpenConsole, isFalse);
    });
  });
}
