// EP-M4 (issue #009/#021): RemoteConsole-only + explicit-disable cross-view
// parity between `KvmConsole.fromManager` (the per-console card) and
// `KvmCapability.fromManager` (the per-manager capability card).
//
// AUDIT (2026-11-22): each field in this matrix is pinned somewhere in isolation
// — RM-8/RM-10/RM-16 cover the enabled-block tri-state over the capability
// aggregates, EP-S7/RM-10 pin capability.uri against `KvmService.pickPrimary`,
// and `kvm_capability_test.dart` has a single "disabled RemoteConsole does not
// report KVM support" capability-only case. But NOTHING drives the same
// RemoteConsole-focused bodies through BOTH `fromManager` factories at once and
// pins detection (`supported` / `serviceEnabled`), resolved URI, aggregated
// connect types, session limit AND per-console launch strategy together. A
// one-sided refactor (e.g. dropping `remoteEnabled` from the capability's
// `supported`, or reading an explicit disable on only one view) could leave the
// capability card advertising a manager whose only console card is disabled —
// the exact #009 divergence class — while every single-surface suite stayed
// GREEN. No live divergence was found: this is a regression guard, not churn.
//
// Read-only, pure-model, dependency-free, widget-free: no WebView/protocol
// import, no URL opened, no wire/TLS change, no production TLS weakening. The
// documented "all-disabled fallback still surfaces the best available URI" is
// pinned as-is (RM-8); no behaviour is changed or blessed as authoritative.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

KvmCapability capabilityOf(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC');

List<KvmConsole> consolesOf(Map<String, dynamic> body) =>
    KvmConsole.fromManager(body, managerId: 'BMC');

String? primaryUriOf(Map<String, dynamic> body) =>
    KvmService.pickPrimary(consolesOf(body))?.launchUri;

void main() {
  group('EP-M4 RemoteConsole-only / explicit-disable parity (#009/#021)', () {
    test('an enabled RemoteConsole-only manager agrees on every signal', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 3,
          'ConnectUri': 'https://bmc.example/html5',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final KvmConsole console = consolesOf(body).single;

      expect(cap.supported, isTrue);
      expect(cap.serviceEnabled, isTrue);
      expect(cap.serviceEnabled, console.serviceEnabled);
      expect(cap.connectTypes, console.connectTypesSupported);
      expect(cap.maxSessions, console.maxConcurrentSessions);
      expect(cap.uri, console.launchUri);
      expect(cap.uri, primaryUriOf(body));
      expect(console.type, KvmConsoleType.remote);
      expect(console.launchStrategy, KvmLaunchStrategy.inAppHtml5);
      expect(console.canOpenConsole, isTrue);
    });

    test(
        'a ServiceEnabled:false RemoteConsole-only manager fails closed on '
        'both views while keeping the best-available fallback URI', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 3,
          'ConnectUri': 'https://bmc.example/html5',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final KvmConsole console = consolesOf(body).single;

      // Detection and enablement fail closed on BOTH views.
      expect(cap.supported, isFalse);
      expect(cap.serviceEnabled, isFalse);
      expect(cap.serviceEnabled, console.serviceEnabled);
      expect(console.launchStrategy, KvmLaunchStrategy.disabled);
      expect(console.canOpenConsole, isFalse);
      // The documented all-disabled fallback still surfaces the URI; it is not
      // an openable console on either view (RM-8 invariant, unchanged).
      expect(cap.uri, 'https://bmc.example/html5');
      expect(cap.connectTypes, <String>['HTML5']);
      expect(cap.maxSessions, 3);
    });

    test(
        'a legacy Enabled:false RemoteConsole-only manager fails closed on '
        'both views', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'RemoteConsole': <String, dynamic>{
          'Enabled': false,
          'ConnectUri': 'https://bmc.example/html5',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final KvmConsole console = consolesOf(body).single;

      expect(cap.supported, isFalse);
      expect(cap.serviceEnabled, isFalse);
      expect(cap.serviceEnabled, console.serviceEnabled);
      expect(console.launchStrategy, KvmLaunchStrategy.disabled);
      expect(console.canOpenConsole, isFalse);
      expect(cap.uri, 'https://bmc.example/html5');
    });

    test('contradictory RemoteConsole flags are truthy-wins on both views', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'Enabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/html5',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final KvmConsole console = consolesOf(body).single;

      expect(cap.supported, isTrue);
      expect(cap.serviceEnabled, isTrue);
      expect(cap.serviceEnabled, console.serviceEnabled);
      expect(cap.uri, console.launchUri);
      expect(console.launchStrategy, KvmLaunchStrategy.inAppHtml5);
      expect(console.canOpenConsole, isTrue);
      expect(cap.uri, primaryUriOf(body));
    });

    test(
        'enabled Graphical + disabled Remote: all aggregates and Primary '
        'agree on the graphical console', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'MaxConcurrentSessions': 5,
          'ConnectUri': 'https://bmc.example/kvm',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 9,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final List<KvmConsole> consoles = consolesOf(body);
      final KvmConsole openable =
          consoles.firstWhere((KvmConsole c) => c.canOpenConsole);

      expect(cap.supported, isTrue);
      expect(cap.uri, 'https://bmc.example/kvm');
      expect(cap.uri, openable.launchUri);
      expect(cap.uri, primaryUriOf(body));
      // A type/limit advertised only by the disabled remote never reaches the
      // capability card while an enabled graphical block is available.
      expect(cap.connectTypes, <String>['KVMIP']);
      expect(cap.maxSessions, 5);
      expect(openable.type, KvmConsoleType.graphical);
      expect(
          consoles
              .where((KvmConsole c) => c.type == KvmConsoleType.remote)
              .single
              .launchStrategy,
          KvmLaunchStrategy.disabled);
    });

    test(
        'disabled Graphical + enabled Remote: all aggregates and Primary '
        'agree on the remote console', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'MaxConcurrentSessions': 5,
          'ConnectUri': 'https://bmc.example/kvm',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 2,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final List<KvmConsole> consoles = consolesOf(body);
      final KvmConsole openable =
          consoles.firstWhere((KvmConsole c) => c.canOpenConsole);

      expect(cap.supported, isTrue);
      expect(cap.uri, 'https://bmc.example/remote');
      expect(cap.uri, openable.launchUri);
      expect(cap.uri, primaryUriOf(body));
      expect(cap.connectTypes, <String>['HTML5']);
      expect(cap.maxSessions, 2);
      expect(openable.type, KvmConsoleType.remote);
      expect(
          consoles
              .where((KvmConsole c) => c.type == KvmConsoleType.graphical)
              .single
              .launchStrategy,
          KvmLaunchStrategy.disabled);
    });

    test(
        'disabled Serial + enabled Remote: all aggregates and Primary agree '
        'on the remote console', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['SSH'],
          'MaxConcurrentSessions': 7,
          'ConnectUri': 'ssh://bmc.example/serial',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 3,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final List<KvmConsole> consoles = consolesOf(body);
      final KvmConsole openable =
          consoles.firstWhere((KvmConsole c) => c.canOpenConsole);

      expect(cap.supported, isTrue);
      expect(cap.uri, 'https://bmc.example/remote');
      expect(cap.uri, openable.launchUri);
      expect(cap.uri, primaryUriOf(body));
      expect(cap.connectTypes, <String>['HTML5']);
      expect(cap.maxSessions, 3);
      expect(openable.type, KvmConsoleType.remote);
      expect(
          consoles
              .where((KvmConsole c) => c.type == KvmConsoleType.serial)
              .single
              .launchStrategy,
          KvmLaunchStrategy.disabled);
    });

    test(
        'a BMC-disabled OEM console does not replace an enabled standard '
        'RemoteConsole as the sole openable target', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/remote',
        },
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{
              'ServiceEnabled': false,
              'Uri': 'https://bmc.example/oem',
            },
          },
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final List<KvmConsole> consoles = consolesOf(body);
      final List<KvmConsole> openable =
          consoles.where((KvmConsole c) => c.canOpenConsole).toList();

      expect(cap.supported, isTrue);
      expect(cap.uri, 'https://bmc.example/remote');
      expect(cap.uri, primaryUriOf(body));
      expect(openable, hasLength(1));
      expect(openable.single.type, KvmConsoleType.remote);
      expect(
          consoles
              .where((KvmConsole c) => c.type == KvmConsoleType.oem)
              .single
              .launchStrategy,
          KvmLaunchStrategy.disabled);
    });

    test(
        'an all-disabled Graphical+Remote manager agrees on the '
        'graphical-first fallback and exposes no openable console', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'MaxConcurrentSessions': 5,
          'ConnectUri': 'https://bmc.example/kvm',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 2,
          'ConnectUri': 'https://bmc.example/remote',
        },
      };

      final KvmCapability cap = capabilityOf(body);
      final List<KvmConsole> consoles = consolesOf(body);

      expect(cap.supported, isFalse);
      expect(cap.serviceEnabled, isFalse);
      expect(cap.uri, 'https://bmc.example/kvm');
      expect(cap.connectTypes, <String>['KVMIP', 'HTML5']);
      expect(cap.maxSessions, 5);
      expect(consoles.where((KvmConsole c) => c.canOpenConsole), isEmpty);
      expect(consoles.map((KvmConsole c) => c.launchStrategy),
          everyElement(KvmLaunchStrategy.disabled));
      expect(primaryUriOf(body), cap.uri);
    });
  });
}
