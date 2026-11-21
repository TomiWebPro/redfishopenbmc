// RS-5 / #009 — manager-source 3-level precedence guard.
//
// `kvmManagerSourceTrimmed` / `kvmManagerSourceUri` in
// `lib/features/kvm/models/kvm_manager_source.dart` are the single source of
// truth for a manager's `@odata.id` source identity on BOTH KVM views (the
// per-console card via `KvmConsole.fromManager` and the per-manager capability
// card via `KvmCapability.fromManager`). The documented contract is a 3-level
// precedence:
//
//   1. a usable caller override wins;
//   2. a blank / non-string override must NOT shadow the body's `@odata.id`
//      fallback;
//   3. when both are unusable, both views fall through to the stable
//      `/redfish/v1/Managers/<managerId>` path.
//
// The existing suite pins a valid override honoured, a non-string BODY id
// falling back, and a blank BODY id falling back — but NOT the crucial
// override→fallback hand-off with a body id DISTINCT from the derived path.
// The one "non-string override ignored" test passes `sourceManagerUri: null`
// alongside a body id equal to the derived path, so it cannot distinguish
// "fell through to the body fallback" from "fell through to the derived path",
// and no test covers a blank-string override. A refactor that drops the
// `fallback` parameter, treats a blank override as authoritative, or stops
// trimming would silently change a capability card's source identity and stay
// GREEN. This guard fails closed on every level, both through the pure helper
// and through `KvmCapability.fromManager`.
//
// Pure, widget-free and dependency-free: no URL opened, no WebView / protocol
// import, no production TLS change (issue #009 / #021, RS-5).

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_manager_source.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

void main() {
  const String derived = '/redfish/v1/Managers/BMC';
  // Deliberately different from `derived` so a fallback bug is observable.
  const String bodyId = '/redfish/v1/Managers/BodyProvidedId';

  group('kvmManagerSourceUri — 3-level precedence (RS-5 / #009)', () {
    test('a usable override wins over the body fallback', () {
      expect(kvmManagerSourceUri('/custom/override', 'BMC', bodyId),
          '/custom/override');
    });

    test('a blank override cannot shadow the body fallback', () {
      expect(kvmManagerSourceUri('   ', 'BMC', bodyId), bodyId);
      expect(kvmManagerSourceUri('', 'BMC', bodyId), bodyId);
    });

    test('a non-string override cannot shadow the body fallback', () {
      expect(kvmManagerSourceUri(42, 'BMC', bodyId), bodyId);
      expect(kvmManagerSourceUri(true, 'BMC', bodyId), bodyId);
      expect(kvmManagerSourceUri(<String>[], 'BMC', bodyId), bodyId);
      expect(kvmManagerSourceUri(<String, dynamic>{}, 'BMC', bodyId), bodyId);
    });

    test('a padded override is trimmed and still wins over the fallback', () {
      expect(kvmManagerSourceUri('  /custom/override  ', 'BMC', bodyId),
          '/custom/override');
    });

    test('a padded body fallback is trimmed when the override is unusable', () {
      expect(kvmManagerSourceUri('  ', 'BMC', '  $bodyId  '), bodyId);
    });

    test('unusable override AND fallback converge on the derived path', () {
      expect(kvmManagerSourceUri('   ', 'BMC', '   '), derived);
      expect(kvmManagerSourceUri(42, 'BMC', <String>[]), derived);
      expect(kvmManagerSourceUri(null, 'BMC', null), derived);
    });

    test('kvmManagerSourceTrimmed rejects non-strings and blanks', () {
      expect(kvmManagerSourceTrimmed('  x  '), 'x');
      expect(kvmManagerSourceTrimmed('   '), isNull);
      expect(kvmManagerSourceTrimmed(42), isNull);
      expect(kvmManagerSourceTrimmed(null), isNull);
    });
  });

  group('KvmCapability.fromManager — override/fallback hand-off (RS-5)', () {
    KvmCapability capabilityWith({
      required Object? bodyOdataId,
      required String? override,
    }) =>
        KvmCapability.fromManager(
          <String, dynamic>{
            '@odata.id': bodyOdataId,
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'ConnectTypesSupported': <dynamic>['KVMIP'],
            },
          },
          managerId: 'BMC',
          sourceManagerUri: override,
        );

    test('a valid override wins over a distinct body @odata.id', () {
      expect(
          capabilityWith(bodyOdataId: bodyId, override: '/custom/manager')
              .sourceManagerUri,
          '/custom/manager');
    });

    test('a blank override cannot shadow a distinct body @odata.id', () {
      expect(
          capabilityWith(bodyOdataId: bodyId, override: '   ').sourceManagerUri,
          bodyId);
      expect(capabilityWith(bodyOdataId: bodyId, override: '').sourceManagerUri,
          bodyId);
    });

    test('a null override falls through to a distinct body @odata.id', () {
      // The existing "non-string override ignored" test used a body id equal
      // to the derived path, so it could not detect a dropped fallback.
      expect(
          capabilityWith(bodyOdataId: bodyId, override: null).sourceManagerUri,
          bodyId);
    });

    test('a padded override is trimmed in fromManager', () {
      expect(
          capabilityWith(bodyOdataId: bodyId, override: '  /custom  ')
              .sourceManagerUri,
          '/custom');
    });

    test('a blank override with a blank body falls back to the derived path',
        () {
      expect(
          capabilityWith(bodyOdataId: '  ', override: '   ').sourceManagerUri,
          derived);
    });

    test('both views agree on a distinct body @odata.id (no override)', () {
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.id': bodyId,
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.sourceManagerUri, bodyId);
      expect(capability.sourceManagerUri, console.sourceManagerUri);
    });
  });
}
