// RM-26 (issue #009/#021): hostile CONTAINER SHAPE for `ConnectTypesSupported`
// cross-factory agreement.
//
// `KvmConsole.fromManager` normalizes one console block's
// `ConnectTypesSupported` through `_normalizedConnectTypes`, while
// `KvmCapability.fromManager` aggregates all blocks through
// `_aggregateConnectTypes` / `_appendTypes` (and `_advertises` for the KVMIP
// detection bit). These are TWO INDEPENDENT normalizers, not one shared helper:
// today both fail closed to an empty type set when the value is not a
// `List<dynamic>` (bare string, number, bool, map, null).
//
// AUDIT: `kvm_connect_types_hostile_agreement_test.dart` (EP-M5) already pins
// the case where `ConnectTypesSupported` IS a list but its MEMBERS are hostile
// (nested list/map, numbers, bools, control strings, multi-block preference).
// Nothing drives the CONTAINER SHAPE itself — a bare `"KVMIP"` / `"HTML5"`
// string, a number, a bool, a map or null — through both factories at once.
// A plausible one-sided "a bare string is a single connection type" coercion
// (e.g. in the console normalizer) would populate the console card's chip row
// while the capability card stayed empty, flipping `supportsHtml5` on one
// surface only — with every EP-M5 / single-factory suite still GREEN.
//
// This is a read-only characterization / regression lock at a genuinely
// unguarded seam: no live divergence, no production behaviour change, no
// dependency, no WebView/protocol import, no URL opened, no production TLS
// weakened. The RED proof is a one-sided mutation of the console normalizer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_connect_type.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// A manager body with a single console [block] whose `ConnectTypesSupported`
/// is exactly [value]. A stable secure URI keeps launch classification fixed.
Map<String, dynamic> bodyWith(
  dynamic value, {
  String block = 'GraphicalConsole',
  bool enabled = true,
}) =>
    <String, dynamic>{
      'Id': 'BMC',
      '@odata.id': '/redfish/v1/Managers/BMC',
      block: <String, dynamic>{
        'ServiceEnabled': enabled,
        'ConnectTypesSupported': value,
        'ConnectUri': 'https://bmc.example/console',
      },
    };

/// The normalized connect-type chip set the console card would render.
List<String> consoleTypes(Map<String, dynamic> body) =>
    KvmConsole.fromManager(body, managerId: 'BMC')
        .expand((KvmConsole c) => c.connectTypesSupported)
        .toList();

/// The normalized chip set the capability card would render.
List<String> capabilityTypes(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC').connectTypes;

/// Whether [types] advertises the canonical HTML5 token.
bool hasHtml5(List<String> types) => types.any(
      (String type) => kvmConnectTypeEquals(type, 'HTML5'),
    );

void main() {
  group('RM-26 non-list ConnectTypesSupported container shapes (#009/#021)',
      () {
    // A bare canonical-looking string is the most tempting "coerce it" value;
    // every other non-list shape must fail closed on BOTH factories too.
    const Map<String, dynamic> hostileContainers = <String, dynamic>{
      'bare-string': 'KVMIP',
      'bare-string-html5': 'HTML5',
      'numeric': 42,
      'boolean': true,
      'map': <String, dynamic>{'type': 'KVMIP'},
      'null': null,
    };

    test(
        'both factories fail closed to an empty chip set on every non-list '
        'container, never throw, and agree field-for-field (RM-26)', () {
      hostileContainers.forEach((String name, dynamic value) {
        final Map<String, dynamic> body = bodyWith(value);
        List<String> consoleChipSet() => consoleTypes(body);
        List<String> capabilityChipSet() => capabilityTypes(body);

        expect(consoleChipSet(), isEmpty,
            reason: '$name: console card must fail closed on a non-list '
                'ConnectTypesSupported');
        expect(capabilityChipSet(), isEmpty,
            reason: '$name: capability card must fail closed too');
        expect(consoleChipSet(), capabilityChipSet(),
            reason: '$name: both cards must surface the SAME chip set');
      });
    });

    test(
        'every standard console block fails closed the same way on a bare '
        'string container (RM-26)', () {
      for (final String block in <String>[
        'GraphicalConsole',
        'SerialConsole',
        'RemoteConsole',
      ]) {
        final Map<String, dynamic> body = bodyWith('KVMIP', block: block);
        expect(consoleTypes(body), isEmpty, reason: '$block console side');
        expect(capabilityTypes(body), isEmpty,
            reason: '$block capability side');
        expect(consoleTypes(body), capabilityTypes(body));
      }
    });

    test(
        'a bare string must NOT flip supportsHtml5 on the console card '
        'while the capability card stays empty (RM-26)', () {
      final Map<String, dynamic> body = bodyWith('HTML5');
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final KvmCapability cap =
          KvmCapability.fromManager(body, managerId: 'BMC');

      expect(consoles, hasLength(1));
      final bool consoleHtml5 = consoles.single.supportsHtml5;
      final bool capabilityHtml5 = hasHtml5(cap.connectTypes);
      expect(consoleHtml5, false,
          reason: 'a bare "HTML5" is not a list of connect types');
      expect(consoleHtml5, capabilityHtml5,
          reason: 'both surfaces must agree on HTML5 support');
    });

    test(
        'a bare-string graphical container cannot make the capability card '
        'report KVMIP support (RM-26)', () {
      final Map<String, dynamic> body = bodyWith('KVMIP');
      final KvmCapability cap =
          KvmCapability.fromManager(body, managerId: 'BMC');

      expect(cap.supportsKvmIp, false,
          reason: '_advertises only accepts a real list of tokens');
      expect(cap.supported, false,
          reason: 'graphical-only manager with no valid KVMIP token');
    });

    test(
        'a valid list control stays byte-exact and agreed on both factories '
        '(RM-26)', () {
      final Map<String, dynamic> body = bodyWith(<dynamic>['KVMIP', 'HTML5']);
      expect(consoleTypes(body), <String>['KVMIP', 'HTML5']);
      expect(capabilityTypes(body), <String>['KVMIP', 'HTML5']);
      expect(consoleTypes(body), capabilityTypes(body));
    });

    test(
        'mixed container shapes across blocks: only the valid list '
        'contributes, and both factories agree (RM-26)', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'Id': 'BMC',
        '@odata.id': '/redfish/v1/Managers/BMC',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': 'KVMIP', // bare string — ignored
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>[' SSH ', 'ssh'], // valid
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': 42, // numeric — ignored
        },
      };
      expect(consoleTypes(body), <String>['SSH']);
      expect(capabilityTypes(body), <String>['SSH']);
      expect(consoleTypes(body), capabilityTypes(body));
    });
  });
}
