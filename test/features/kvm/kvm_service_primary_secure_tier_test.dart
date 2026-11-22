// EP-S2 (issues #009/#021): `KvmService.pickPrimary` documents a strict tier
// order for the "Primary" badge / recommended external-open target:
//   secure-HTTPS graphical > secure-HTTPS any type > openable graphical >
//   openable any type > graphical > first.
// The existing "safe external-browser target" tests pin secure-vs-plaintext
// GRAPHICAL, secure-vs-external-client (non-graphical), and secure-graphical-vs-
// secure-non-graphical — but NONE pins that a secure-HTTPS console of ANY type
// outranks an OPENABLE PLAINTEXT-HTTP GRAPHICAL console. Swapping tiers 2 and 3
// in the return expression would pass every existing test while badging a
// plaintext console "Primary" even though a secure browser-openable console
// exists: the exact invariant issue #021 requires ("never badge a plaintext
// console as Primary while a secure one exists", never weaken TLS).
//
// Pure model-layer regression guard: no network, no widget, no dependency, no
// URL opened, no production TLS weakened. The fail-closed `hasSecureLaunchUri`
// classifier (not raw `Uri.tryParse`) is the sole source of "secure" here.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

void main() {
  KvmConsole console(
    KvmConsoleType type, {
    required String id,
    required bool enabled,
    String? uri,
  }) =>
      KvmConsole(
        type: type,
        managerId: id,
        serviceEnabled: enabled,
        connectUri: uri,
        sourceManagerUri: '/redfish/v1/Managers/$id',
      );

  group('KvmService.pickPrimary secure-HTTPS tier precedence (EP-S2)', () {
    test(
        'a secure-HTTPS RemoteConsole outranks an openable plaintext graphical '
        'listed first (never badge plaintext while secure exists)', () {
      final KvmConsole plaintext = console(
        KvmConsoleType.graphical,
        id: 'plaintext',
        enabled: true,
        uri: 'http://bmc.example/kvm',
      );
      final KvmConsole secure = console(
        KvmConsoleType.remote,
        id: 'secure',
        enabled: true,
        uri: 'https://bmc.example/remote',
      );
      expect(plaintext.canOpenConsole, isTrue);
      expect(plaintext.hasSecureLaunchUri, isFalse);
      expect(secure.hasSecureLaunchUri, isTrue);
      expect(
        KvmService.pickPrimary(<KvmConsole>[plaintext, secure]),
        same(secure),
        reason: 'tier 2 (secure-HTTPS any type) must outrank tier 3 '
            '(openable graphical); a plaintext console must never be the '
            'recommended Primary target while a secure one exists',
      );
    });

    test(
        'a secure-HTTPS RemoteConsole outranks an openable plaintext graphical '
        'listed after it (order-independent tier precedence)', () {
      final KvmConsole secure = console(
        KvmConsoleType.remote,
        id: 'secure',
        enabled: true,
        uri: 'https://bmc.example/remote',
      );
      final KvmConsole plaintext = console(
        KvmConsoleType.graphical,
        id: 'plaintext',
        enabled: true,
        uri: 'http://bmc.example/kvm',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[secure, plaintext]),
        same(secure),
        reason: 'tier precedence is by security class, not by list position',
      );
    });

    test(
        'a padded secure-HTTPS RemoteConsole still outranks a plaintext '
        'graphical (launchUri is trimmed before security classification)', () {
      final KvmConsole plaintext = console(
        KvmConsoleType.graphical,
        id: 'plaintext',
        enabled: true,
        uri: 'http://bmc.example/kvm',
      );
      final KvmConsole secure = console(
        KvmConsoleType.remote,
        id: 'secure-padded',
        enabled: true,
        uri: '  https://bmc.example/remote  ',
      );
      expect(secure.hasSecureLaunchUri, isTrue);
      expect(
        KvmService.pickPrimary(<KvmConsole>[plaintext, secure]),
        same(secure),
        reason: 'a padded-but-valid HTTPS endpoint must still win the secure '
            'tier over a plaintext graphical console',
      );
    });

    test(
        'a control-bearing "HTTPS" graphical does not win the secure tier '
        'and a genuine secure RemoteConsole is preferred', () {
      final KvmConsole injected = console(
        KvmConsoleType.graphical,
        id: 'injected',
        enabled: true,
        uri: 'https://bmc.example/kvm\r\nX-Injected: 1',
      );
      final KvmConsole secure = console(
        KvmConsoleType.remote,
        id: 'secure',
        enabled: true,
        uri: 'https://bmc.example/remote',
      );
      expect(injected.hasSecureLaunchUri, isFalse);
      expect(injected.canOpenConsole, isFalse);
      expect(
        KvmService.pickPrimary(<KvmConsole>[injected, secure]),
        same(secure),
        reason: 'a CRLF/spoofed target must fail closed at the classifier '
            'and never be badged Primary over a genuine secure console',
      );
    });

    test(
        'with no secure console the first openable graphical is still '
        'preferred (tier 3 preserved when tier 2 is absent)', () {
      final KvmConsole plaintext = console(
        KvmConsoleType.graphical,
        id: 'plaintext',
        enabled: true,
        uri: 'http://bmc.example/kvm',
      );
      final KvmConsole external = console(
        KvmConsoleType.serial,
        id: 'external',
        enabled: true,
        uri: 'ssh://bmc.example',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[plaintext, external]),
        same(plaintext),
        reason: 'preserving tier 3 prevents over-correcting the tier swap',
      );
    });
  });
}
