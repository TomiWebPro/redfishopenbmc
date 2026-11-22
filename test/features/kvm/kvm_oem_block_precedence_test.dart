/// RM-14 (issues #009/#021) — documented `Oem` console-block search order.
///
/// [kvmOemConsoleBlock] documents a strict two-pass order: a *direct*
/// console-like key (`kvm` / `console` / `webconsole`, case-insensitive) whose
/// map carries a usable `Uri` / `ConnectUri` wins BEFORE a recursive walk into
/// nested vendor blocks. Both KVM views resolve the OEM endpoint through this
/// one helper (`KvmConsole.fromManager` for the per-console card and
/// `KvmCapability.fromManager` for the capability card), and the enablement
/// check reads its flags from the very same winning block — so a flipped search
/// order would silently re-point BOTH views' "Connect URI" / "Resolved URI"
/// rows to a different host and could source the enablement flag from a
/// different console node (the #009 two-views-disagree class).
///
/// A real OpenBMC/multi-vendor manager can carry a generic `Oem.Console` block
/// *and* a vendor-specific `Oem.<Vendor>.KVM` block in the same payload; this
/// is the first guard that fixtures both at once. Every pre-existing OEM test
/// carries exactly one console source, so reversing the two passes (a plausible
/// refactor) stays GREEN there while this guard goes RED.
///
/// Pure model-layer regression guard: no network, no widget, no dependency, no
/// URL opened, no WebView/protocol import and no production TLS change.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart';

void main() {
  const String directUri = 'https://bmc.example/direct-console';
  const String nestedUri = 'https://vendor.example/other-console';

  /// An `Oem` payload carrying BOTH a direct console-like block and a nested
  /// vendor `KVM` block with a usable endpoint. The documented order requires
  /// the direct block to win.
  Map<String, dynamic> dualConsoleOem({
    String directKey = 'Console',
    required Map<String, dynamic> directBlock,
    Map<String, dynamic>? nestedBlock,
  }) =>
      <String, dynamic>{
        directKey: directBlock,
        'VendorX': <String, dynamic>{
          'KVM': nestedBlock ?? <String, dynamic>{'Uri': nestedUri},
        },
      };

  group('kvmOemConsoleBlock documented direct-key precedence (RM-14)', () {
    test('a direct Console Uri outranks a nested vendor KVM block', () {
      final Map<String, dynamic> oem = dualConsoleOem(
        directBlock: <String, dynamic>{'Uri': directUri},
      );

      final Map<dynamic, dynamic>? block = kvmOemConsoleBlock(oem);
      expect(block, isNotNull);
      expect(block!['Uri'], directUri);
      expect(kvmOemConsoleUri(oem), directUri);
    });

    test('a case-insensitive WebConsole key also takes precedence', () {
      final Map<String, dynamic> oem = dualConsoleOem(
        directKey: 'WebConsole',
        directBlock: <String, dynamic>{'Uri': directUri},
      );
      expect(kvmOemConsoleUri(oem), directUri);
    });

    test('a direct ConnectUri member takes precedence too', () {
      final Map<String, dynamic> oem = dualConsoleOem(
        directBlock: <String, dynamic>{'ConnectUri': directUri},
      );
      expect(kvmOemConsoleUri(oem), directUri);
    });

    test('a blank direct Uri cannot shadow a valid nested vendor block', () {
      // The same "blank cannot shadow a later valid fallback" rule the helper
      // applies WITHIN one block applies across the two passes: a direct
      // console-like key with no usable URI must not hide a nested console.
      final Map<String, dynamic> oem = dualConsoleOem(
        directBlock: <String, dynamic>{'Uri': '   '},
      );
      expect(kvmOemConsoleUri(oem), nestedUri);
    });

    test('a non-string direct ConnectUri cannot shadow the nested block', () {
      final Map<String, dynamic> oem = dualConsoleOem(
        directBlock: <String, dynamic>{'ConnectUri': 42},
      );
      expect(kvmOemConsoleUri(oem), nestedUri);
    });

    test('enablement is read from the winning direct block, not the nested one',
        () {
      // URI and enablement MUST come from the same console node. A flipped
      // search order would source the flag from the nested (disabled) vendor
      // block while the direct console is explicitly enabled.
      final Map<String, dynamic> oem = dualConsoleOem(
        directBlock: <String, dynamic>{
          'Uri': directUri,
          'ServiceEnabled': true,
        },
        nestedBlock: <String, dynamic>{
          'Uri': nestedUri,
          'ServiceEnabled': false,
        },
      );

      final Map<dynamic, dynamic>? block = kvmOemConsoleBlock(oem);
      expect(block, isNotNull);
      expect(block!['Uri'], directUri);
      expect(block['ServiceEnabled'], isTrue);
      expect(kvmOemConsoleEnabled(oem), isTrue);
    });
  });

  group('RM-14 both KVM views resolve the winning direct endpoint', () {
    Map<String, dynamic> managerWithDualConsoleOem() => <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': dualConsoleOem(
            directBlock: <String, dynamic>{
              'ConnectUri': directUri,
              'ServiceEnabled': true,
            },
            nestedBlock: <String, dynamic>{
              'ConnectUri': nestedUri,
              'ServiceEnabled': false,
            },
          ),
        };

    test('the per-console card surfaces the direct endpoint', () {
      final KvmConsole console = KvmConsole.fromManager(
        managerWithDualConsoleOem(),
        managerId: 'BMC',
      ).singleWhere((KvmConsole c) => c.type == KvmConsoleType.oem);

      expect(console.connectUri, directUri);
      expect(console.launchUri, directUri);
      expect(console.serviceEnabled, isTrue);
      expect(console.hasSecureLaunchUri, isTrue);
    });

    test('the capability card resolves the same direct endpoint', () {
      final KvmCapability capability = KvmCapability.fromManager(
        managerWithDualConsoleOem(),
        managerId: 'BMC',
      );

      expect(capability.uri, directUri);
      expect(capability.launchUri, directUri);
      expect(capability.hasSecureLaunchUri, isTrue);
    });

    test('both views agree byte-for-byte on the winning endpoint', () {
      final Map<String, dynamic> body = managerWithDualConsoleOem();
      final KvmConsole console = KvmConsole.fromManager(
        body,
        managerId: 'BMC',
      ).singleWhere((KvmConsole c) => c.type == KvmConsoleType.oem);
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');

      expect(console.launchUri, capability.launchUri);
      expect(console.hasSecureLaunchUri, capability.hasSecureLaunchUri);
      expect(console.launchUri, directUri);
    });
  });
}
