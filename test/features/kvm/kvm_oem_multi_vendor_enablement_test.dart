/// Regression guard for #009 / #021: multi-vendor `Oem` enablement precedence.
///
/// `kvmOemConsoleEnabled`'s URI-less fallback (`_consoleLikeBlock`) documents
/// that a flag-less metadata console-like block must NOT mask a real console's
/// explicit `ServiceEnabled` / `Enabled` state in a multi-vendor `Oem` payload
/// (an OpenBMC `Oem` map commonly carries vendor metadata alongside a specific
/// vendor's console). No test covered that precedence, so a future "return the
/// first console-like block" simplification would silently reintroduce the
/// #009 "KVM disabled on BMC" break: the capability card would again advertise
/// Supported / Enabled for a console the BMC explicitly disabled.
///
/// Test-only, dependency-free, TLS-safe: reads JSON members only, opens no
/// connection and never weakens transport security.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm.dart';

void main() {
  group('multi-vendor Oem enablement precedence (RM-1 residual, #009)', () {
    test('a flag-less metadata block does not mask a nested explicit disable',
        () {
      final Map<String, dynamic> oem = <String, dynamic>{
        'Metadata': <String, dynamic>{
          'KVM': <String, dynamic>{
            'Description': 'vendor metadata placeholder',
          },
        },
        'AMI': <String, dynamic>{
          'KVM': <String, dynamic>{'ServiceEnabled': false},
        },
      };
      expect(kvmOemConsoleEnabled(oem), isFalse);
    });

    test('a direct flag-less block does not mask a nested explicit disable',
        () {
      final Map<String, dynamic> oem = <String, dynamic>{
        'KVM': <String, dynamic>{'Description': 'flag-less top-level block'},
        'AMI': <String, dynamic>{
          'KVM': <String, dynamic>{'Enabled': false},
        },
      };
      expect(kvmOemConsoleEnabled(oem), isFalse);
    });

    test('a flag-less metadata block does not mask a nested explicit enable',
        () {
      final Map<String, dynamic> oem = <String, dynamic>{
        'Metadata': <String, dynamic>{
          'KVM': <String, dynamic>{
            'Description': 'vendor metadata placeholder',
          },
        },
        'AMI': <String, dynamic>{
          'KVM': <String, dynamic>{'ServiceEnabled': true},
        },
      };
      expect(kvmOemConsoleEnabled(oem), isTrue);
    });

    Map<String, dynamic> multiVendorBody(bool enabled) => <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'Metadata': <String, dynamic>{
              'KVM': <String, dynamic>{
                'Description': 'vendor metadata placeholder',
              },
            },
            'AMI': <String, dynamic>{
              'KVM': <String, dynamic>{'ServiceEnabled': enabled},
            },
          },
        };

    test('both KVM views agree an explicitly-disabled vendor console is off',
        () {
      final Map<String, dynamic> body = multiVendorBody(false);
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.serviceEnabled, isFalse);
      expect(capability.serviceEnabled, isFalse);
      expect(capability.supported, isFalse);
      expect(console.canOpenConsole, isFalse);
      expect(console.serviceEnabled, capability.serviceEnabled);
    });

    test('both KVM views agree an explicitly-enabled vendor console is on', () {
      final Map<String, dynamic> body = multiVendorBody(true);
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.serviceEnabled, isTrue);
      expect(capability.serviceEnabled, isTrue);
      expect(capability.supported, isTrue);
      expect(console.serviceEnabled, capability.serviceEnabled);
    });
  });
}
