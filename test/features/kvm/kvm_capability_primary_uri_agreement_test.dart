// EP-S7 (issue #009/#021): capability-summary <-> primary launch-URI agreement.
//
// `KvmCapability.fromManager(...).uri` is the "Resolved URI" the capability card
// renders and offers an Open affordance on. `KvmService.pickPrimary(...)` is the
// console badged "Primary" — the recommended launch target. Both are derived
// from the SAME Redfish manager body, so for one manager exposing SEVERAL
// console blocks they must agree on ONE launch target: the capability card must
// never point the operator at an external-client URI (e.g. serial SSH) while
// the "Primary" badge opens a secure HTTPS console (or vice versa).
//
// Genuine latent divergence (discovered 2026-11-21 during the EP-S6 audit):
// `_standardConnectUri` walked Graphical -> Serial -> Remote and returned the
// first non-disabled block with a ConnectUri, so an ENABLED serial SSH block
// whose URI preceded a secure-HTTPS RemoteConsole made the capability summary
// resolve `ssh://…/serial` while pickPrimary's security-first tier picked the
// remote `https://…/remote`. The authoritative rule is pickPrimary's — the
// external-browser + copy render route prefers a control-safe secure-HTTPS
// console over external-client / plaintext consoles — so the capability
// resolver applies the same security-first preference before its block-order
// fallback. Pure, widget-free, TLS-safe: no WebView/protocol import, no URL
// opened, no production TLS weakening.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

void main() {
  /// The URI the capability card surfaces for [body].
  String? capabilityUri(Map<String, dynamic> body) =>
      KvmCapability.fromManager(body, managerId: 'BMC').uri;

  /// The launch URI of the console `pickPrimary` badges "Primary" for [body].
  String? primaryUri(Map<String, dynamic> body) => KvmService.pickPrimary(
        KvmConsole.fromManager(body, managerId: 'BMC'),
      )?.launchUri;

  group('EP-S7 capability-summary <-> primary launch-URI agreement (#009/#021)',
      () {
    test('enabled serial SSH ConnectUri does not shadow a secure HTTPS remote',
        () {
      final Map<String, dynamic> body = <String, dynamic>{
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'ssh://bmc.example/serial',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      // pickPrimary's security-first tier picks the remote.
      expect(primaryUri(body), 'https://bmc.example/remote');
      // The capability card must agree — regression guard for the divergence
      // where it resolved the serial SSH URI instead.
      expect(capabilityUri(body), primaryUri(body),
          reason: 'capability summary must resolve the same launch target '
              'as the Primary badge');
      expect(capabilityUri(body), 'https://bmc.example/remote');
    });

    test('a padded secure HTTPS remote still wins and agrees when trimmed', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'ssh://bmc.example/serial',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': '  https://bmc.example/remote  ',
        },
      };

      expect(primaryUri(body), 'https://bmc.example/remote');
      expect(capabilityUri(body), primaryUri(body));
    });

    test('a disabled serial SSH block never shadows a secure HTTPS remote', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'ssh://bmc.example/serial',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      expect(primaryUri(body), 'https://bmc.example/remote');
      expect(capabilityUri(body), primaryUri(body));
    });

    test('a malformed false-secure URI never outranks a real secure remote',
        () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example:notaport/kvm',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      // The invalid-port URI is not a control-safe secure HTTPS target, so the
      // real secure remote wins on both surfaces.
      expect(primaryUri(body), 'https://bmc.example/remote');
      expect(capabilityUri(body), primaryUri(body));
    });

    test('all-insecure multi-block managers keep block-order fallback parity',
        () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'http://bmc.example/kvm',
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'ssh://bmc.example/serial',
        },
      };

      // No secure console exists, so pickPrimary falls back to the first
      // openable graphical console and the resolver keeps its block-order
      // preference — the two surfaces still agree.
      expect(primaryUri(body), 'http://bmc.example/kvm');
      expect(capabilityUri(body), primaryUri(body));
    });

    test('a secure graphical console stays ahead of a secure remote', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/graphical',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      expect(primaryUri(body), 'https://bmc.example/graphical');
      expect(capabilityUri(body), primaryUri(body));
    });
  });
}
