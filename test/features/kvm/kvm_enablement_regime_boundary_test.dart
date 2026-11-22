// RM-13 (issue #009/#021): enablement-regime decision-boundary characterization.
//
// `KvmCapability.fromManager(...)` (the capability card's "Resolved URI" /
// types / session limit) and `KvmService.pickPrimary(KvmConsole.fromManager(...))`
// (the "Primary" badge + launch target) walk the SAME manager body but apply
// subtly different enablement rules:
//   * capability skips only an EXPLICITLY disabled block (`ServiceEnabled:false`
//     / `Enabled:false`), treating a flag-absent block as "unknown" and keeping
//     its URI (RM-8 / RM-10);
//   * pickPrimary only considers OPENABLE consoles, and a flag-absent console
//     has `serviceEnabled == false` -> `launchStrategy == disabled` ->
//     `canOpenConsole == false`, so it is skipped in favour of an
//     explicitly-enabled one (EP-S7 / EP-P11).
//
// In the two AGREEING regimes every pre-existing guard already requires the two
// surfaces to agree byte-for-byte, and this file pins those agreements once more
// over one matrix so a future refactor cannot trade one regime for another:
//   * all-unknown (no flags anywhere) — capability keeps the secure-HTTPS
//     graphical URI, pickPrimary falls back to the first graphical console;
//   * both-flagged (explicit disable vs explicit enable, contradictory
//     `ServiceEnabled`/`Enabled` truthy-wins) — the security-first pass and the
//     openable tiers select the same console.
//
// In the MIXED regime (a flag-absent secure-HTTPS console alongside an
// explicitly-enabled insecure SSH/plaintext console) the two surfaces DIVERGE:
// capability resolves the secure URI while the Primary badge opens the enabled
// insecure console. Which side is authoritative is a deliberate human decision
// (RM-11, deferred — see `queues/model.md`); this guard RECORDS the divergence
// as a stable baseline so it cannot silently disappear, and NEVER blesses either
// side as the expected/correct target.
//
// Read-only model guard: pure Dart, no WebView/protocol import, no URL opened,
// no wire/TLS change, no dependency, no production TLS weakening. This file does
// not change any semantics and does not fold the RM-11 behaviour decision in.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// The capability aggregate the capability card renders for [body].
KvmCapability capability(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC');

/// The console `pickPrimary` badges "Primary" for [body].
KvmConsole? primary(Map<String, dynamic> body) => KvmService.pickPrimary(
      KvmConsole.fromManager(body, managerId: 'BMC'),
    );

/// The launch URI of the console `pickPrimary` badges "Primary" for [body].
String? primaryUri(Map<String, dynamic> body) => primary(body)?.launchUri;

void main() {
  group('RM-13 agreeing regimes — capability <-> Primary byte-for-byte', () {
    test('all-unknown regime keeps the secure graphical URI on both surfaces',
        () {
      // No enablement flags anywhere ("unknown", as most mockups emit). The
      // capability resolver keeps the secure-HTTPS graphical URI (RM-10), and
      // pickPrimary falls back to the first graphical console — the same
      // target. Also pin the URI-bearing winner's limit and type chips.
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/unknown-secure',
          'ConnectTypesSupported': <dynamic>['HTML5', 'KVMIP'],
          'MaxConcurrentSessions': 6,
        },
        'SerialConsole': <String, dynamic>{
          'ConnectUri': 'ssh://bmc.example/serial',
          'ConnectTypesSupported': <dynamic>['SSH'],
          'MaxConcurrentSessions': 9,
        },
      };

      final KvmCapability cap = capability(body);
      final KvmConsole? picked = primary(body);
      expect(picked, isNotNull);
      expect(cap.uri, 'https://bmc.example/unknown-secure');
      expect(cap.launchUri, picked!.launchUri);
      expect(primaryUri(body), cap.launchUri);
      expect(cap.maxSessions, 6);
      expect(cap.maxSessions, picked.maxConcurrentSessions);
      expect(cap.connectTypes, contains('KVMIP'));
      expect(picked.connectTypesSupported, contains('KVMIP'));
    });

    test(
        'both-flagged regime: disabled secure graphical cannot shadow the '
        'enabled secure remote', () {
      // The graphical block is explicitly disabled (with a control-safe secure
      // URI, a KVMIP chip and a 9-session limit); the remote is explicitly
      // enabled. Both the EP-S7 security-first pass and pickPrimary's openable
      // tiers must select the remote, agreeing on URI, limit and chips.
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'https://bmc.example/disabled-secure',
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'MaxConcurrentSessions': 9,
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/enabled-secure',
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 3,
        },
      };

      final KvmCapability cap = capability(body);
      final KvmConsole? picked = primary(body);
      expect(picked, isNotNull);
      expect(cap.uri, 'https://bmc.example/enabled-secure');
      expect(cap.launchUri, picked!.launchUri);
      expect(cap.maxSessions, 3);
      expect(cap.maxSessions, picked.maxConcurrentSessions);
      expect(cap.connectTypes, picked.connectTypesSupported);
      expect(cap.connectTypes, <String>['HTML5']);
    });

    test(
        'contradictory ServiceEnabled/Enabled truthy-wins agrees across all '
        'aggregates and with the Primary badge', () {
      // The graphical block says ServiceEnabled:false but also Enabled:true;
      // both products use truthy-wins, so it is enabled and wins the
      // security-first pass / secure-graphical tier on both surfaces.
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'Enabled': true,
          'ConnectUri': 'https://bmc.example/contradictory',
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'MaxConcurrentSessions': 5,
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 2,
        },
      };

      final KvmCapability cap = capability(body);
      final KvmConsole? picked = primary(body);
      expect(picked, isNotNull);
      expect(cap.uri, 'https://bmc.example/contradictory');
      expect(cap.launchUri, picked!.launchUri);
      expect(cap.maxSessions, 5);
      expect(cap.maxSessions, picked.maxConcurrentSessions);
      expect(cap.connectTypes, picked.connectTypesSupported);
      expect(cap.connectTypes, contains('KVMIP'));
    });

    test('an integral-double session limit on the winning block agrees', () {
      // A BMC may emit `7.0` for MaxConcurrentSessions; the shared
      // `kvmSessionLimit` normalizes it on both products, so the capability
      // aggregate and the Primary console cannot disagree on the limit.
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/graphical',
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'MaxConcurrentSessions': 7.0,
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 3,
        },
      };

      final KvmCapability cap = capability(body);
      final KvmConsole? picked = primary(body);
      expect(picked, isNotNull);
      expect(cap.launchUri, picked!.launchUri);
      expect(cap.maxSessions, 7);
      expect(cap.maxSessions, picked.maxConcurrentSessions);
    });
  });

  group('RM-13 mixed regime — RECORD the deferred RM-11 divergence', () {
    /// Asserts the *fact* of the divergence without blessing either side.
    ///
    /// The capability side stays on a control-safe secure-HTTPS target (the
    /// RM-10 "unknown keeps URI" rule) while the Primary badge lands on an
    /// explicitly-enabled insecure console (pickPrimary's openable tiers).
    /// Which one the operator should be pointed at is the deferred RM-11 human
    /// decision; these assertions only make sure the disagreement cannot
    /// silently vanish behind a refactor.
    void expectRecordedDivergence(
      Map<String, dynamic> body, {
      required String reason,
    }) {
      final KvmCapability cap = capability(body);
      final KvmConsole? picked = primary(body);
      expect(picked, isNotNull, reason: reason);
      expect(cap.launchUri, isNotNull, reason: reason);
      expect(cap.launchUri, isNot(picked!.launchUri), reason: reason);
      // Record the direction today, without claiming it is correct: capability
      // keeps the secure target, Primary is an insecure (external/plaintext)
      // target. A future authoritative-rule decision will update this record.
      expect(cap.hasSecureLaunchUri, isTrue, reason: reason);
      expect(picked.hasSecureLaunchUri, isFalse, reason: reason);
      expect(
        picked.requiresExternalConsoleClient ||
            picked.usesInsecureHttpLaunchUri,
        isTrue,
        reason: reason,
      );
    }

    test('flag-absent secure graphical + enabled SSH serial diverges', () {
      const String reason =
          'mixed-regime divergence (RM-11 deferred decision) — SSH serial';
      expectRecordedDivergence(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/unknown-secure',
          'ConnectTypesSupported': <dynamic>['HTML5', 'KVMIP'],
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'ssh://bmc.example/serial',
          'ConnectTypesSupported': <dynamic>['SSH'],
        },
      }, reason: reason);
    });

    test('flag-absent secure graphical + enabled plaintext HTTP diverges', () {
      const String reason =
          'mixed-regime divergence (RM-11 deferred decision) — plaintext HTTP';
      expectRecordedDivergence(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/unknown-secure',
          'ConnectTypesSupported': <dynamic>['HTML5', 'KVMIP'],
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'http://bmc.example/remote',
          'ConnectTypesSupported': <dynamic>['HTML5'],
        },
      }, reason: reason);
    });

    test('a flag-absent secure remote diverges from an enabled SSH serial', () {
      // The divergence is not tied to the graphical block's position: a
      // flag-absent secure RemoteConsole keeps its URI on the capability side
      // while the enabled SSH serial console wins the Primary badge.
      const String reason =
          'mixed-regime divergence (RM-11 deferred decision) — secure remote';
      expectRecordedDivergence(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'https://bmc.example/disabled-graphical',
          'ConnectTypesSupported': <dynamic>['HTML5'],
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'ssh://bmc.example/serial',
          'ConnectTypesSupported': <dynamic>['SSH'],
        },
        'RemoteConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/unknown-secure-remote',
          'ConnectTypesSupported': <dynamic>['HTML5'],
        },
      }, reason: reason);
    });

    test('legacy Enabled:true also triggers the recorded divergence', () {
      const String reason =
          'mixed-regime divergence (RM-11 deferred decision) — legacy Enabled';
      expectRecordedDivergence(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/unknown-secure',
          'ConnectTypesSupported': <dynamic>['HTML5', 'KVMIP'],
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'Enabled': true,
          'ConnectUri': 'ssh://bmc.example/serial',
          'ConnectTypesSupported': <dynamic>['SSH'],
        },
      }, reason: reason);
    });
  });
}
