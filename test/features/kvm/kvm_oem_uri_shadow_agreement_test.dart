/// EP-M6 / #009 / #021: OEM-console URI "shadow" agreement across both KVM
/// views.
///
/// A Redfish `Oem` console block may publish more than one endpoint member: the
/// short vendor `Uri` and the canonical `ConnectUri`. Both KVM views resolve
/// the OEM endpoint through the single shared helper [kvmOemConsoleUri], whose
/// contract is: prefer a USABLE `Uri`, but never let a blank / non-string /
/// malformed `Uri` shadow a valid `ConnectUri` (issue #009/#021).
///
/// That "usable only" qualifier was pinned for a blank `ConnectUri` in
/// `kvm_oem_uri_test.dart`, but NOT for a blank / non-string `Uri`: nothing
/// stopped a refactor from returning the first `Uri`-keyed value verbatim,
/// which would drop a perfectly good `ConnectUri` endpoint on BOTH views and
/// leave the operator with "no console URI" for a BMC that actually published
/// one. A one-sided view edit could also make the per-console card and the
/// capability card disagree about the same manager.
///
/// This suite pins the shared-helper contract AND the cross-view parity at
/// both model factories. Display-only / pure-model: no URL opened, no WebView
/// or protocol import, no production TLS change (issue #021 never weakened).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart';

void main() {
  group('kvmOemConsoleUri — a non-usable Uri never shadows ConnectUri', () {
    const String endpoint = 'https://bmc.example/kvm';

    test('a blank/whitespace Uri does not shadow a valid ConnectUri', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': '   ',
              'ConnectUri': endpoint,
            },
          },
        }),
        endpoint,
      );
    });

    test('a non-string Uri does not shadow a valid ConnectUri', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': 42,
              'ConnectUri': endpoint,
            },
          },
        }),
        endpoint,
      );
    });

    test('an empty-string Uri does not shadow a valid ConnectUri', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': '',
              'ConnectUri': endpoint,
            },
          },
        }),
        endpoint,
      );
    });

    test('member keys are matched case-insensitively and values trimmed', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'URI': '  $endpoint  ',
              'CONNECTURI': 'https://bmc.example/other',
            },
          },
        }),
        endpoint,
      );
    });

    test('the resolved block remains the enablement source when Uri is blank',
        () {
      final Map<String, dynamic> oem = <String, dynamic>{
        'VendorX': <String, dynamic>{
          'KVM': <String, dynamic>{
            'Uri': '   ',
            'ConnectUri': endpoint,
            'ServiceEnabled': false,
          },
        },
      };
      final Map<dynamic, dynamic>? block = kvmOemConsoleBlock(oem);
      expect(block, isNotNull);
      expect(block!['ConnectUri'], endpoint);
      // The URI and its enablement flag come from the SAME block, so a
      // BMC-disabled OEM console cannot be advertised as launchable on either
      // view just because the short Uri member was blank.
      expect(kvmOemConsoleEnabled(oem), isFalse);
    });
  });

  group('both KVM views agree when a blank Uri shadows ConnectUri', () {
    Map<String, dynamic> managerWithBlankUriAndConnectUri() =>
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'VendorX': <String, dynamic>{
              'KVM': <String, dynamic>{
                'Uri': '   ',
                'ConnectUri': 'https://bmc.example/kvm',
              },
            },
          },
        };

    test('per-console card surfaces the valid ConnectUri', () {
      final KvmConsole console = KvmConsole.fromManager(
        managerWithBlankUriAndConnectUri(),
        managerId: 'BMC',
      ).singleWhere((KvmConsole c) => c.type == KvmConsoleType.oem);

      expect(console.connectUri, 'https://bmc.example/kvm');
      expect(console.launchUri, 'https://bmc.example/kvm');
      expect(console.hasSecureLaunchUri, isTrue);
      expect(console.canOpenConsole, isTrue);
    });

    test('capability card resolves the same valid ConnectUri', () {
      final KvmCapability capability = KvmCapability.fromManager(
        managerWithBlankUriAndConnectUri(),
        managerId: 'BMC',
      );

      expect(capability.uri, 'https://bmc.example/kvm');
      expect(capability.launchUri, 'https://bmc.example/kvm');
      expect(capability.hasSecureLaunchUri, isTrue);
    });

    test('both views carry the byte-identical launch target', () {
      final Map<String, dynamic> body = managerWithBlankUriAndConnectUri();
      final KvmConsole console = KvmConsole.fromManager(
        body,
        managerId: 'BMC',
      ).singleWhere((KvmConsole c) => c.type == KvmConsoleType.oem);
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');

      expect(console.launchUri, 'https://bmc.example/kvm');
      expect(console.launchUri, capability.launchUri);
      expect(console.hasSecureLaunchUri, capability.hasSecureLaunchUri);
    });
  });
}
