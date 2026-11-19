/// Tests for the shared OEM-console URI resolution helper (issues #009 / #021).
///
/// A Redfish manager may expose its console only under `Oem.*`. The canonical
/// Redfish member for a console endpoint is `ConnectUri`, but some vendors use
/// the shorter `Uri`. Both KVM views (the per-console card via
/// `KvmConsole.fromManager` and the per-manager capability card via
/// `KvmCapability.resolveLaunchUri`) resolve the OEM endpoint through
/// `kvmOemConsoleUri`, so that helper must recognize both spellings or the two
/// views silently disagree with the endpoint the BMC actually published.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart';

void main() {
  group('kvmOemConsoleUri — Redfish ConnectUri alias (#009/#021)', () {
    test('finds the canonical OEM Uri member (guard)', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        }),
        'https://bmc.example/kvm',
      );
    });

    // RED proof: the generic OEM path only recognized a member literally
    // named `Uri`, so a vendor publishing the canonical Redfish `ConnectUri`
    // under Oem.<Vendor>.KVM had no resolvable endpoint on either KVM view.
    test('finds a Redfish ConnectUri member under a vendor OEM block', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'ConnectUri': 'https://bmc.example/kvm',
            },
          },
        }),
        'https://bmc.example/kvm',
      );
    });

    test('trims a padded ConnectUri like every other URI source (#009)', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'ConnectUri': '  https://bmc.example/kvm  ',
            },
          },
        }),
        'https://bmc.example/kvm',
      );
    });

    test('prefers Uri over ConnectUri when both are present', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': 'https://bmc.example/primary',
              'ConnectUri': 'https://bmc.example/secondary',
            },
          },
        }),
        'https://bmc.example/primary',
      );
    });

    test('a blank ConnectUri cannot shadow a later valid Uri (guard)', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{
              'ConnectUri': '   ',
              'Uri': 'https://bmc.example/kvm',
            },
          },
        }),
        'https://bmc.example/kvm',
      );
    });

    test('a non-string ConnectUri is ignored (guard)', () {
      expect(
        kvmOemConsoleUri(<String, dynamic>{
          'VendorX': <String, dynamic>{
            'KVM': <String, dynamic>{'ConnectUri': 42},
          },
        }),
        isNull,
      );
    });

    // RED proof: kvmOemConsoleBlock filters on a resolvable URI. With only a
    // ConnectUri it returned null, so the enablement check could not read the
    // flags from the same console node that carried the endpoint.
    test('the ConnectUri-bearing block is returned for enablement parity', () {
      final Map<String, dynamic> oem = <String, dynamic>{
        'VendorX': <String, dynamic>{
          'KVM': <String, dynamic>{
            'ConnectUri': 'https://bmc.example/kvm',
            'ServiceEnabled': false,
          },
        },
      };
      final Map<dynamic, dynamic>? block = kvmOemConsoleBlock(oem);
      expect(block, isNotNull);
      expect(block!['ServiceEnabled'], isFalse);
      expect(kvmOemConsoleEnabled(oem), isFalse);
    });
  });

  group('OEM ConnectUri cross-surface parity (#009/#021)', () {
    Map<String, dynamic> managerWithVendorConnectUri() => <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'VendorX': <String, dynamic>{
              'KVM': <String, dynamic>{
                'ConnectUri': 'https://bmc.example/kvm',
              },
            },
          },
        };

    // RED proof: KvmConsole.fromManager produced an OEM console with a null
    // connectUri, so the per-console card hid its URI row and the console
    // routed to `noUri` (not openable) despite the BMC publishing an endpoint.
    test('the per-console card surfaces a vendor OEM ConnectUri', () {
      final KvmConsole console = KvmConsole.fromManager(
        managerWithVendorConnectUri(),
        managerId: 'BMC',
      ).singleWhere((KvmConsole c) => c.type == KvmConsoleType.oem);

      expect(console.connectUri, 'https://bmc.example/kvm');
      expect(console.launchUri, 'https://bmc.example/kvm');
      expect(console.canOpenConsole, isTrue);
      expect(console.launchStrategy, KvmLaunchStrategy.secureBrowser);
    });

    // RED proof: KvmCapability.resolveLaunchUri ignored the ConnectUri, so the
    // capability card showed no resolved URI for the same manager.
    test('the capability card resolves the same vendor OEM ConnectUri', () {
      final KvmCapability capability = KvmCapability.fromManager(
        managerWithVendorConnectUri(),
        managerId: 'BMC',
      );

      expect(capability.uri, 'https://bmc.example/kvm');
      expect(capability.hasUri, isTrue);
      expect(capability.hasSecureLaunchUri, isTrue);
    });

    test('both KVM views agree on the vendor OEM ConnectUri', () {
      final Map<String, dynamic> body = managerWithVendorConnectUri();
      final KvmConsole console = KvmConsole.fromManager(
        body,
        managerId: 'BMC',
      ).singleWhere((KvmConsole c) => c.type == KvmConsoleType.oem);
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');

      expect(console.launchUri, capability.launchUri);
      expect(console.hasSecureLaunchUri, capability.hasSecureLaunchUri);
    });
  });
}
