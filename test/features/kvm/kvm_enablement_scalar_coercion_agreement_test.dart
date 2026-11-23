// RM-24 (epic #009 / #021): the per-console card (`KvmConsole.fromManager`), the
// per-manager capability card (`KvmCapability.fromManager`) and the shared OEM
// enablement helper (`kvmOemConsoleEnabled`) all read the SAME BMC-supplied
// enablement member (`ServiceEnabled`, or the legacy `Enabled`). A one-sided
// coercion ("some BMCs send `1` / `"true"` for enabled") could flip
// `serviceEnabled` / `supported` / `canOpenConsole` on one card while the other
// stays GREEN, advertising a console the operator cannot actually open.
//
// AUDIT (before adding this guard): the three readers are independent (there is
// NO shared enablement helper) — `kvm_models.dart` `_fromBlock` reads the
// standard console block with `block['ServiceEnabled'] == true ||
// block['Enabled'] == true`, `kvm_capability.dart` `_blockEnabled` repeats the
// same strict check, and `kvm_oem_uri.dart` `kvmOemConsoleEnabled` gates OEM
// blocks with the same strict boolean test. All three therefore fail closed on
// a non-boolean scalar today, but NO existing test drives a hostile non-boolean
// enablement matrix through both factories + the OEM helper at once. This is a
// regression guard at a genuinely unguarded cross-factory seam, not churn:
// no behaviour change is folded in. Pure-model, dependency-free and TLS-safe —
// no URL is opened, no WebView/protocol dependency is imported, no production
// TLS is touched.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart';

/// A hostile enablement scalar and the verdict every reader must agree on.
/// Only the literal JSON boolean `true` means enabled; every other encoding
/// (including the numeric `1` and the string `"true"`) must fail closed.
class _ScalarCase {
  const _ScalarCase(this.name, this.value, this.expectedEnabled);

  final String name;
  final Object? value;
  final bool expectedEnabled;
}

const List<_ScalarCase> _scalars = <_ScalarCase>[
  _ScalarCase('bool true control', true, true),
  _ScalarCase('bool false control', false, false),
  _ScalarCase('string "true"', 'true', false),
  _ScalarCase('string "false"', 'false', false),
  _ScalarCase('string "1"', '1', false),
  _ScalarCase('string "0"', '0', false),
  _ScalarCase('string "yes"', 'yes', false),
  _ScalarCase('string "no"', 'no', false),
  _ScalarCase('padded string " true "', ' true ', false),
  _ScalarCase('numeric 1', 1, false),
  _ScalarCase('numeric 0', 0, false),
  _ScalarCase('numeric 2', 2, false),
  _ScalarCase('null', null, false),
  _ScalarCase('list scalar', <dynamic>[true], false),
  _ScalarCase('map scalar', <String, dynamic>{'value': true}, false),
];

const String _managerId = 'BMC';
const String _secureUri = 'https://bmc.example/kvm';

/// A manager body whose GraphicalConsole block carries [value] under [key],
/// plus a secure KVMIP endpoint so every launch decision hinges only on the
/// enablement scalar.
Map<String, dynamic> _body(Object? value, {String key = 'ServiceEnabled'}) {
  return <String, dynamic>{
    '@odata.id': '/redfish/v1/Managers/BMC',
    'GraphicalConsole': <String, dynamic>{
      key: value,
      'ConnectTypesSupported': <dynamic>['KVMIP'],
      'ConnectUri': _secureUri,
    },
  };
}

/// An OEM manager body whose console-like block carries [value] under [key],
/// exercising the third enablement reader (`kvmOemConsoleEnabled`).
Map<String, dynamic> _oemBody(Object? value, {String key = 'ServiceEnabled'}) {
  return <String, dynamic>{
    '@odata.id': '/redfish/v1/Managers/BMC',
    'Oem': <String, dynamic>{
      'OpenBMC': <String, dynamic>{
        'KVM': <String, dynamic>{
          'Uri': _secureUri,
          key: value,
        },
      },
    },
  };
}

void main() {
  group('RM-24 enablement-scalar coercion agreement', () {
    for (final String key in <String>['ServiceEnabled', 'Enabled']) {
      group('via $key', () {
        for (final _ScalarCase c in _scalars) {
          test('${c.name} -> enabled=${c.expectedEnabled}', () {
            final Map<String, dynamic> body = _body(c.value, key: key);
            final List<KvmConsole> consoles =
                KvmConsole.fromManager(body, managerId: _managerId);
            final KvmCapability cap =
                KvmCapability.fromManager(body, managerId: _managerId);

            expect(consoles, hasLength(1));
            final KvmConsole console = consoles.single;

            // The three consumer flags must agree across both factories and
            // never report a non-boolean scalar as enabled.
            expect(console.serviceEnabled, c.expectedEnabled,
                reason: 'console.serviceEnabled for ${c.name}');
            expect(cap.serviceEnabled, c.expectedEnabled,
                reason: 'capability.serviceEnabled for ${c.name}');
            expect(cap.supported, c.expectedEnabled,
                reason: 'capability.supported for ${c.name}');

            if (c.expectedEnabled) {
              expect(console.canOpenConsole, isTrue);
              expect(console.launchStrategy, KvmLaunchStrategy.secureBrowser);
            } else {
              expect(console.canOpenConsole, isFalse,
                  reason: 'fail closed: ${c.name} must not be openable');
              expect(console.launchStrategy, KvmLaunchStrategy.disabled,
                  reason: 'fail closed: ${c.name} must be disabled');
            }
          });
        }
      });
    }

    test('both factories agree on OEM enablement scalars (third reader)', () {
      for (final String key in <String>['ServiceEnabled', 'Enabled']) {
        for (final _ScalarCase c in _scalars) {
          final Map<String, dynamic> body = _oemBody(c.value, key: key);
          final List<KvmConsole> consoles =
              KvmConsole.fromManager(body, managerId: _managerId);
          final KvmCapability cap =
              KvmCapability.fromManager(body, managerId: _managerId);

          expect(consoles, hasLength(1), reason: 'OEM ${c.name} via $key');
          expect(consoles.single.serviceEnabled, c.expectedEnabled,
              reason: 'OEM console.serviceEnabled for ${c.name}');
          expect(cap.serviceEnabled, c.expectedEnabled,
              reason: 'OEM capability.serviceEnabled for ${c.name}');
          expect(cap.supported, c.expectedEnabled,
              reason: 'OEM capability.supported for ${c.name}');
        }
      }
    });

    test('kvmOemConsoleEnabled fails closed on a present non-boolean scalar',
        () {
      for (final String key in <String>['ServiceEnabled', 'Enabled']) {
        for (final _ScalarCase c in _scalars) {
          final Map<String, dynamic> node = _oemBody(c.value, key: key);
          expect(kvmOemConsoleEnabled(node), c.expectedEnabled,
              reason: 'OEM helper for ${c.name} via $key');
        }
      }
    });

    test('an enablement member omitted entirely is distinct from a scalar', () {
      // Control distinguishing "absent" from "present non-boolean": both
      // standard readers report serviceEnabled=false when the member is absent
      // (they only count a literal `true`), while the URI still resolves
      // (an absent flag is not an explicit disable). The OEM helper keeps its
      // documented "absent stays enabled" default. This pins that the
      // fail-closed scalar rule does not bleed into absent-payload semantics.
      final Map<String, dynamic> standard = <String, dynamic>{
        '@odata.id': '/redfish/v1/Managers/BMC',
        'GraphicalConsole': <String, dynamic>{
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': _secureUri,
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(standard, managerId: _managerId).single;
      final KvmCapability cap =
          KvmCapability.fromManager(standard, managerId: _managerId);
      expect(console.serviceEnabled, isFalse);
      expect(cap.serviceEnabled, isFalse);
      expect(cap.uri, _secureUri,
          reason: 'absent flag is not an explicit disable');
      final Map<String, dynamic> oemAbsent = <String, dynamic>{
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': _secureUri},
          },
        },
      };
      expect(kvmOemConsoleEnabled(oemAbsent), isTrue);
    });

    test('no throw on non-map/list enablement containers', () {
      // A non-map console block is skipped rather than throwing, and a list /
      // map enablement scalar inside a block is compared, not cast.
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
      for (final Object? value in <Object?>[
        <dynamic>[true],
        <String, dynamic>{'value': true},
        null,
      ]) {
        final Map<String, dynamic> body = _body(value);
        expect(() => kvmOemConsoleEnabled(_oemBody(value)), returnsNormally);
        expect(() => KvmConsole.fromManager(body, managerId: _managerId),
            returnsNormally);
        expect(() => KvmCapability.fromManager(body, managerId: _managerId),
            returnsNormally);
      }
    });

    test('enablement readers keep the strict-boolean rule in source', () {
      // Liveness pin: the three independent readers must keep the strict
      // `== true` test and must not grow a truthy coercion (`== 1`,
      // `== 'true'`, `bool.tryParse`, ...). This catches a coercion introduced
      // in a reader path not exercised by the matrix above.
      final String models =
          File('lib/features/kvm/models/kvm_models.dart').readAsStringSync();
      final String capability =
          File('lib/features/kvm/models/kvm_capability.dart')
              .readAsStringSync();
      final String oem =
          File('lib/features/kvm/models/kvm_oem_uri.dart').readAsStringSync();

      final RegExp coercion = RegExp(
        r"==\s*1\b|==\s*'true'|bool\.tryParse",
      );
      for (final MapEntry<String, String> src in <String, String>{
        'kvm_models.dart': models,
        'kvm_capability.dart': capability,
        'kvm_oem_uri.dart': oem,
      }.entries) {
        expect(coercion.hasMatch(src.value), isFalse,
            reason: '${src.key} must not coerce non-boolean enablement');
      }
      expect(capability.contains("block['ServiceEnabled'] == true ||"), isTrue,
          reason: 'capability _blockEnabled strict test present');
      expect(oem.contains("block['ServiceEnabled'] == true ||"), isTrue,
          reason: 'OEM helper strict test present');
    });
  });
}
