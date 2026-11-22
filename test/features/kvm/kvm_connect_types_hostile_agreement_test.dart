// EP-M5 (issues #009 / #021): the per-console card and the capability card are
// two operator surfaces for the SAME Redfish manager. Each normalizes the
// manager's `ConnectTypesSupported` independently — `KvmConsole.fromManager`
// via `_normalizedConnectTypes` (one block) and `KvmCapability.fromManager`
// via `_aggregateConnectTypes`/`_appendTypes` (all blocks, enabled-preference).
//
// AUDIT: the two single-block normalizers are byte-identical today (drop
// non-strings, trim, drop blanks, case-insensitive dedup keeping first spelling)
// and `kvm_model_test.dart` already pins agreement for a SMALL matrix (one
// GraphicalConsole, mixed-case/whitespace/null/int/bool). Nothing pins that
// they still agree over the FULL hostile matrix this seam allows:
//   * non-string LIST and MAP entries (a one-sided "stringify malformed entry"
//     refactor would render "42"/"[HTML5]"/"{x: 1}" chips on one card only);
//   * control-bearing string values (CRLF / NUL / TAB / ZWSP) — both must keep
//     or reject the SAME bytes, never split the two views;
//   * the multi-block enabled-block preference (RM-8) and the all-disabled
//     fallback for connect types — the capability aggregate must equal the
//     union of the per-console types from exactly the blocks it prefers.
//
// This is a regression guard at a genuinely unguarded seam, not churn: the
// factories already agree, but a one-sided edit could desync the two cards
// while every single-surface suite stayed GREEN (the #009 divergence class).
// Pure-model, display-only, dependency-free and TLS-safe: no URL is opened, no
// WebView/protocol dependency is imported and production TLS is untouched.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

List<String> consoleTypes(Map<String, dynamic> body) =>
    KvmConsole.fromManager(body, managerId: 'BMC').single.connectTypesSupported;

List<String> capabilityTypes(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC').connectTypes;

Map<String, dynamic> oneBlock(List<dynamic> types) => <String, dynamic>{
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': types,
      },
    };

void main() {
  group('EP-M5 hostile ConnectTypesSupported agreement — one block (#009/#021)',
      () {
    test('nested list and map entries are dropped identically by both models',
        () {
      final Map<String, dynamic> body = oneBlock(<dynamic>[
        'KVMIP',
        <dynamic>['HTML5'], // nested list — malformed entry
        <String, dynamic>{'type': 'HTML5'}, // nested map — malformed entry
        42,
        3.5,
        true,
        false,
        null,
        'HTML5',
      ]);
      expect(consoleTypes(body), <String>['KVMIP', 'HTML5']);
      expect(capabilityTypes(body), <String>['KVMIP', 'HTML5']);
      expect(consoleTypes(body), capabilityTypes(body));
    });

    test('padded mixed-case duplicates keep first spelling on both models', () {
      final Map<String, dynamic> body = oneBlock(<dynamic>[
        ' KVMIP ',
        'kvmip',
        'HTML5',
        ' html5 ',
        ' KVMIP ',
      ]);
      expect(consoleTypes(body), <String>['KVMIP', 'HTML5']);
      expect(capabilityTypes(body), <String>['KVMIP', 'HTML5']);
      expect(consoleTypes(body), capabilityTypes(body));
    });

    test('blank and whitespace-only entries are dropped identically', () {
      final Map<String, dynamic> body = oneBlock(<dynamic>[
        'KVMIP',
        '',
        '   ',
        '\t',
        '\n',
        'HTML5',
      ]);
      expect(consoleTypes(body), <String>['KVMIP', 'HTML5']);
      expect(capabilityTypes(body), <String>['KVMIP', 'HTML5']);
      expect(consoleTypes(body), capabilityTypes(body));
    });

    test('control-bearing strings stay byte-identical across both models', () {
      // Both normalizers trim but do not rewrite embedded control points, so
      // the contract is that they keep the SAME bytes — never one clean and
      // one control-bearing rendering of the same BMC payload.
      final Map<String, dynamic> body = oneBlock(<dynamic>[
        'KVM\r\nIP',
        'HT\x00ML5',
        ' SSH\t',
        '\u200bTELNET',
      ]);
      expect(consoleTypes(body), capabilityTypes(body));
      expect(consoleTypes(body), <String>[
        'KVM\r\nIP',
        'HT\x00ML5',
        'SSH',
        '\u200bTELNET',
      ]);
    });

    test('a hostile matrix combining all entry shapes still agrees', () {
      final Map<String, dynamic> body = oneBlock(<dynamic>[
        ' kvmip ',
        'KVMIP',
        null,
        7,
        true,
        <dynamic>['x'],
        <String, dynamic>{'k': 'v'},
        '   ',
        ' HTML5 ',
        'html5',
        'KVM\rIP',
      ]);
      expect(consoleTypes(body), capabilityTypes(body));
      // First-seen spelling is kept: ' kvmip ' trims to lowercase 'kvmip'.
      expect(consoleTypes(body), <String>['kvmip', 'HTML5', 'KVM\rIP']);
    });
  });

  group(
      'EP-M5 hostile ConnectTypesSupported agreement — multi-block (#009/#021)',
      () {
    test('capability types equal the union from enabled blocks only', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false, // explicitly disabled
          'ConnectTypesSupported': <dynamic>[
            'KVM\r\nIP',
            'KVMIP',
            null,
            42,
          ],
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>[
            ' SSH ',
            'ssh',
            ' telnet ',
            '',
            true,
          ],
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>[
            ' HTML5 ',
            'html5',
            <dynamic>['ignored'],
            'HTML5',
          ],
        },
      };
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      expect(consoles, hasLength(3));

      // The capability aggregate prefers non-disabled blocks (RM-8): the
      // disabled graphical block's types must not leak into the capability
      // card, while every enabled block's normalized types are present.
      expect(capabilityTypes(body), <String>['SSH', 'telnet', 'HTML5']);
      final List<String> enabledUnion = consoles
          .where((KvmConsole c) => c.serviceEnabled)
          .expand((KvmConsole c) => c.connectTypesSupported)
          .toList();
      expect(capabilityTypes(body), enabledUnion);
      expect(capabilityTypes(body),
          isNot(contains(consoles.first.connectTypesSupported.first)));
    });

    test('all-disabled fallback keeps every block\'s normalized types', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP', ' kvmip ', null],
        },
        'SerialConsole': <String, dynamic>{
          'Enabled': false,
          'ConnectTypesSupported': <dynamic>[' SSH ', 42, 'ssh'],
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>[
            'HTML5',
            <dynamic>['x'],
            ' html5 '
          ],
        },
      };
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final List<String> allUnion =
          consoles.expand((KvmConsole c) => c.connectTypesSupported).toList();
      expect(allUnion, <String>['KVMIP', 'SSH', 'HTML5']);
      expect(capabilityTypes(body), allUnion);
    });

    test('flag-absent (unknown) blocks keep types on both models', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectTypesSupported': <dynamic>[' KVMIP ', 'kvmip', null],
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5', ' html5 '],
        },
      };
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final List<String> allUnion =
          consoles.expand((KvmConsole c) => c.connectTypesSupported).toList();
      expect(allUnion, <String>['KVMIP', 'HTML5']);
      expect(capabilityTypes(body), allUnion);
    });
  });
}
