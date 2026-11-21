// RM-10 (issue #009/#021): security-first secure-URI preference x enabled-block
// tri-state agreement in the capability aggregate.
//
// EP-S7 added a security-first pass to `KvmCapability._standardConnectUri` so
// the capability card's "Resolved URI" agrees with `KvmService.pickPrimary`'s
// "Primary" badge/open target. RM-8 pinned the enabled-block preference
// tri-state (flag-absent "unknown" / explicit disable / contradictory
// `ServiceEnabled` + `Enabled`) for the URI/types/session aggregates, but BEFORE
// the security-first pass existed. Nothing pinned that the EP-S7 pass still
// honours that tri-state contract: a one-sided edit that drops the
// `_explicitlyDisabled` guard in the security-first pass could resurrect a
// disabled secure-HTTPS console as the capability's "Resolved URI" while every
// single-helper / RM-8 / EP-S7 test stayed GREEN — the exact #009 divergence
// class (capability card pointing the operator at a console they cannot open).
//
// This guard pins the currently-correct invariants over one matrix built once
// from each manager body:
//   * the security-first pass never selects an explicitly-disabled block's
//     secure URI (nor its types / session limit) while a launchable block of a
//     different type exists;
//   * the RM-8 all-disabled fallback is preserved byte-for-byte after EP-S7;
//   * contradictory `ServiceEnabled` / `Enabled` truthy-wins consistently on
//     all three aggregates AND with `KvmConsole.fromManager` / `pickPrimary`;
//   * a flag-absent ("unknown") secure console keeps its URI in the all-unknown
//     regime, agreeing with pickPrimary's graphical fallback.
//
// Read-only model guard: pure Dart, no WebView/protocol import, no URL opened,
// no wire/TLS change, no dependency, no production TLS weakening. A genuine
// mixed-regime divergence (unknown secure + explicitly-enabled insecure block)
// is deliberately NOT asserted here — it is recorded in `queues/model.md` as a
// behaviour-change candidate needing a deliberate authoritative-rule decision.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// The capability aggregate the capability card renders for [body].
KvmCapability capability(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC');

/// The launch URI of the console `pickPrimary` badges "Primary" for [body].
String? primaryUri(Map<String, dynamic> body) => KvmService.pickPrimary(
      KvmConsole.fromManager(body, managerId: 'BMC'),
    )?.launchUri;

void main() {
  group('RM-10 security-first x enabled-block tri-state (#009/#021)', () {
    test(
        'security-first pass never selects an explicitly-disabled secure block',
        () {
      // The disabled graphical block advertises a CONTROL-SAFE SECURE HTTPS
      // URI plus a KVMIP type and a 9-session limit. A one-sided edit that
      // drops `_explicitlyDisabled` from the EP-S7 security-first pass would
      // pick this first (graphical order) and leak all three aggregates from a
      // console the operator cannot open.
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'https://bmc.example/disabled-secure',
          'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
          'MaxConcurrentSessions': 9,
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/enabled-secure',
          'ConnectTypesSupported': <String>['HTML5'],
          'MaxConcurrentSessions': 3,
        },
      };

      final KvmCapability cap = capability(body);
      expect(cap.uri, 'https://bmc.example/enabled-secure');
      expect(cap.maxSessions, 3);
      expect(cap.connectTypes, <String>['HTML5']);
      // The capability card and the "Primary" badge agree on ONE launch target.
      expect(primaryUri(body), cap.uri);
    });

    test('all-disabled fallback is byte-for-byte preserved after EP-S7', () {
      // Both blocks explicitly disabled with usable secure URIs / limits /
      // types. The security-first and enabled passes skip both; the fallback
      // re-surfaces the first (graphical) block so an all-disabled mockup still
      // shows a URI rather than a blank "Resolved URI:" row (RM-8 invariant).
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'https://bmc.example/graphical',
          'ConnectTypesSupported': <String>['KVMIP'],
          'MaxConcurrentSessions': 7,
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'https://bmc.example/remote',
          'ConnectTypesSupported': <String>['HTML5'],
          'MaxConcurrentSessions': 4,
        },
      };

      final KvmCapability cap = capability(body);
      expect(cap.uri, 'https://bmc.example/graphical');
      expect(cap.maxSessions, 7);
      expect(cap.connectTypes, <String>['KVMIP', 'HTML5']);
      // An all-disabled manager is not supported, even though its best
      // available URI is still surfaced as the fallback.
      expect(cap.supported, isFalse);
    });

    test(
        'contradictory ServiceEnabled/Enabled truthy-wins agrees across all '
        'aggregates and with pickPrimary', () {
      // The graphical block explicitly says ServiceEnabled:false but also
      // Enabled:true. The shared tri-state rule is truthy-wins, so the block is
      // ENABLED: it must win the security-first pass (first secure graphical)
      // and contribute its limit, and pickPrimary must badge the same console.
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'Enabled': true,
          'ConnectUri': 'https://bmc.example/contradictory',
          'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
          'MaxConcurrentSessions': 5,
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
          'ConnectTypesSupported': <String>['HTML5'],
          'MaxConcurrentSessions': 2,
        },
      };

      final KvmCapability cap = capability(body);
      expect(cap.uri, 'https://bmc.example/contradictory');
      expect(cap.maxSessions, 5);
      expect(cap.connectTypes, contains('KVMIP'));
      expect(cap.supported, isTrue);
      expect(primaryUri(body), cap.uri);
    });

    test('a flag-absent secure console keeps its URI in the all-unknown regime',
        () {
      // With no enablement flags anywhere ("unknown", as most mockups emit),
      // `_explicitlyDisabled` is false for every block so the security-first
      // pass keeps the secure HTTPS graphical URI. All consoles have
      // serviceEnabled=false, so pickPrimary falls back to the first graphical
      // console — the same target. Pins the documented "unknown keeps URI"
      // behaviour in the regime where it is correct; the MIXED regime (unknown
      // secure + explicitly-enabled insecure) is a separate, deferred
      // behaviour-change candidate recorded in queues/model.md.
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/unknown-secure',
          'ConnectTypesSupported': <String>['HTML5', 'KVMIP'],
          'MaxConcurrentSessions': 6,
        },
        'SerialConsole': <String, dynamic>{
          'ConnectUri': 'ssh://bmc.example/serial',
          'ConnectTypesSupported': <String>['SSH'],
        },
      };

      final KvmCapability cap = capability(body);
      expect(cap.uri, 'https://bmc.example/unknown-secure');
      expect(cap.maxSessions, 6);
      expect(cap.connectTypes, contains('KVMIP'));
      expect(primaryUri(body), cap.uri);
    });
  });
}
