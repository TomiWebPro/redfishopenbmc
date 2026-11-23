// RM-25 (epic #009 / #021): the per-console card (`KvmConsole.fromManager`),
// the per-manager capability card (`KvmCapability.fromManager`) and the shared
// `kvmSessionLimit` parser all read the SAME BMC-supplied
// `MaxConcurrentSessions` member. A one-sided coercion ("some BMCs send a
// numeric string / double, so just truncate it here") could emit a negative,
// fractional or overflow session limit on one card while the other stays
// GREEN — advertising a bogus "Max sessions: -1" / "2.5" chip.
//
// AUDIT (before adding this guard): `kvmSessionLimit` is the single source of
// truth and is already pinned in isolation (`kvm_session_limit_test.dart`), and
// the two render cards' agreement is pinned for VALID encodings only
// (`kvm_card_chip_session_agreement_test.dart`: 2 / 5.0 / ' 3 '). NO existing
// test drives a hostile NON-INTEGER / out-of-spec session-limit matrix through
// BOTH `fromManager` factories at once, so a one-sided coercion in either
// factory could desync the two cards while every existing suite stayed GREEN.
// This is a pure-model regression guard at a genuinely unguarded cross-factory
// seam, not churn: no behaviour change is folded in. Dependency-free and
// TLS-safe — no URL is opened, no WebView/protocol dependency is imported, no
// production TLS is touched.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_session_limit.dart';

/// A hostile or boundary `MaxConcurrentSessions` scalar and the fail-closed
/// limit every reader must agree on (null == unreported). Only spec-valid
/// non-negative integers (int, integral double within 2^53, or a trimmed
/// numeric string in either form) are reported; everything else fails closed.
class _ScalarCase {
  const _ScalarCase(this.name, this.value, this.expectedLimit);

  final String name;
  final Object? value;
  final int? expectedLimit;
}

const List<_ScalarCase> _scalars = <_ScalarCase>[
  // Spec-valid controls — must stay byte-exact on both cards.
  _ScalarCase('int 2 control', 2, 2),
  _ScalarCase('int 0 control', 0, 0),
  _ScalarCase('integral double 4.0', 4.0, 4),
  _ScalarCase('padded numeric string " 3 "', ' 3 ', 3),
  _ScalarCase('numeric string "5"', '5', 5),
  _ScalarCase('numeric string "5.0"', '5.0', 5),
  _ScalarCase('exponent string "1e3" -> 1000', '1e3', 1000),
  _ScalarCase('padded double string " 4.0 "', ' 4.0 ', 4),
  // Hostile / out-of-spec — must fail closed to unreported on both cards.
  _ScalarCase('fractional double 2.5', 2.5, null),
  _ScalarCase('negative int -1', -1, null),
  _ScalarCase('negative double -1.0', -1.0, null),
  _ScalarCase('nan', double.nan, null),
  _ScalarCase('infinity', double.infinity, null),
  _ScalarCase('negative infinity', double.negativeInfinity, null),
  _ScalarCase('huge integral double beyond 2^53', 9007199254740994.0, null),
  _ScalarCase('huge exponent string "1e300"', '1e300', null),
  _ScalarCase('string "-1"', '-1', null),
  _ScalarCase('string "2.5"', '2.5', null),
  _ScalarCase('string "abc"', 'abc', null),
  _ScalarCase('blank string', '   ', null),
  _ScalarCase('null', null, null),
  _ScalarCase('bool true', true, null),
  _ScalarCase('list scalar', <dynamic>[4], null),
  _ScalarCase('map scalar', <String, dynamic>{'v': 4}, null),
];

const String _managerId = 'BMC';
const String _secureUri = 'https://bmc.example/kvm';

/// A manager body whose [blockName] console carries [value] under
/// `MaxConcurrentSessions`, plus an enabled secure KVMIP endpoint so the
/// session limit is the only value under test.
Map<String, dynamic> _body(Object? value,
    {String blockName = 'GraphicalConsole'}) {
  return <String, dynamic>{
    '@odata.id': '/redfish/v1/Managers/BMC',
    blockName: <String, dynamic>{
      'ServiceEnabled': true,
      'ConnectTypesSupported': <dynamic>['KVMIP'],
      'ConnectUri': _secureUri,
      'MaxConcurrentSessions': value,
    },
  };
}

void main() {
  group('RM-25 session-limit scalar coercion agreement', () {
    for (final _ScalarCase c in _scalars) {
      test('${c.name} -> limit=${c.expectedLimit} agrees across both factories',
          () {
        final Map<String, dynamic> body = _body(c.value);
        final List<KvmConsole> consoles =
            KvmConsole.fromManager(body, managerId: _managerId);
        final KvmCapability cap =
            KvmCapability.fromManager(body, managerId: _managerId);

        expect(consoles, hasLength(1), reason: 'console for ${c.name}');
        final KvmConsole console = consoles.single;

        // The helper, the console card and the capability card resolve the
        // identical fail-closed boundary value — field-for-field agreement.
        expect(kvmSessionLimit(c.value), c.expectedLimit,
            reason: 'shared helper for ${c.name}');
        expect(console.maxConcurrentSessions, c.expectedLimit,
            reason: 'console.maxConcurrentSessions for ${c.name}');
        expect(cap.maxSessions, c.expectedLimit,
            reason: 'capability.maxSessions for ${c.name}');
        expect(console.maxConcurrentSessions, cap.maxSessions,
            reason: 'both cards must never disagree for ${c.name}');

        // Never emit a negative, fractional or overflow limit.
        final int? limit = console.maxConcurrentSessions;
        expect(cap.maxSessions == null || cap.maxSessions! >= 0, isTrue,
            reason: 'no negative capability limit for ${c.name}');
        expect(limit == null || limit >= 0, isTrue,
            reason: 'no negative console limit for ${c.name}');
      });
    }

    for (final String blockName in <String>[
      'GraphicalConsole',
      'SerialConsole',
      'RemoteConsole',
    ]) {
      test('hostile scalars agree across both factories via $blockName', () {
        for (final _ScalarCase c in _scalars) {
          final Map<String, dynamic> body =
              _body(c.value, blockName: blockName);
          final List<KvmConsole> consoles =
              KvmConsole.fromManager(body, managerId: _managerId);
          final KvmCapability cap =
              KvmCapability.fromManager(body, managerId: _managerId);

          expect(consoles, hasLength(1), reason: '$blockName ${c.name}');
          expect(consoles.single.maxConcurrentSessions, c.expectedLimit,
              reason: 'console $blockName ${c.name}');
          expect(cap.maxSessions, c.expectedLimit,
              reason: 'capability $blockName ${c.name}');
        }
      });
    }

    test('all three block types coexist with distinct limits without desync',
        () {
      // One manager with three blocks carrying distinct valid limits: the
      // console cards each keep their own value while the capability card
      // reports the first non-disabled limit in the spec order (graphical).
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.id': '/redfish/v1/Managers/BMC',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': _secureUri,
          'MaxConcurrentSessions': 2,
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['SSH'],
          'ConnectUri': _secureUri,
          'MaxConcurrentSessions': ' 3 ',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': _secureUri,
          'MaxConcurrentSessions': 4.0,
        },
      };
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: _managerId);
      final KvmCapability cap =
          KvmCapability.fromManager(body, managerId: _managerId);

      expect(consoles, hasLength(3));
      expect(
        consoles
            .map((KvmConsole c) => c.maxConcurrentSessions)
            .toList(growable: false),
        <int?>[2, 3, 4],
      );
      expect(cap.maxSessions, 2, reason: 'graphical limit wins in spec order');
    });

    test('no throw on non-map/list limit containers or non-map blocks', () {
      for (final Object? badBlock in <Object?>[
        <dynamic>['not', 'a', 'map'],
        'a string',
        42,
        null,
      ]) {
        final Map<String, dynamic> body = <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'GraphicalConsole': badBlock,
        };
        expect(() => KvmConsole.fromManager(body, managerId: _managerId),
            returnsNormally);
        expect(() => KvmCapability.fromManager(body, managerId: _managerId),
            returnsNormally);
      }
      for (final _ScalarCase c in _scalars) {
        final Map<String, dynamic> body = _body(c.value);
        expect(() => KvmConsole.fromManager(body, managerId: _managerId),
            returnsNormally);
        expect(() => KvmCapability.fromManager(body, managerId: _managerId),
            returnsNormally);
      }
    });

    test('both factories keep delegating to the shared session-limit helper',
        () {
      // Liveness pin: both factories must resolve MaxConcurrentSessions through
      // the single `kvmSessionLimit` helper, not a private one-sided coercion.
      final String models =
          File('lib/features/kvm/models/kvm_models.dart').readAsStringSync();
      final String capability =
          File('lib/features/kvm/models/kvm_capability.dart')
              .readAsStringSync();

      expect(
        models.contains("kvmSessionLimit(block['MaxConcurrentSessions'])"),
        isTrue,
        reason: 'console _fromBlock delegates to the shared helper',
      );
      expect(
        capability.contains("kvmSessionLimit(block['MaxConcurrentSessions'])"),
        isTrue,
        reason:
            'capability _aggregateMaxSessions delegates to the shared helper',
      );
      // No ad-hoc numeric coercion of the raw BMC value may creep into either
      // parser path (the helper is the only place that may convert scalars).
      final RegExp coercion = RegExp(
        r"(MaxConcurrentSessions[^\n]*\.(toInt|round|truncate)\(\))",
      );
      expect(coercion.hasMatch(models), isFalse,
          reason: 'no one-sided raw session-limit coercion in kvm_models.dart');
      expect(coercion.hasMatch(capability), isFalse,
          reason:
              'no one-sided raw session-limit coercion in kvm_capability.dart');
    });
  });
}
