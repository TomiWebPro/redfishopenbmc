// RM-16 (issues #009 / #021): hostile enablement-flag ENCODING agreement
// across the two operator surfaces for one Redfish manager.
//
// `KvmConsole.fromManager` (the per-console card, via `_fromBlock`) and
// `KvmCapability.fromManager` (the capability card, via `_blockEnabled` /
// `_explicitlyDisabled`) each read the BMC-supplied `ServiceEnabled` / legacy
// `Enabled` members. Both route them through the SAME canonical rule —
// `member == true` — so a non-canonical encoding (a string "true", an int 1,
// a padded or control-bearing string, null, a list or a map) is NEVER truthy:
// it fails closed to "not enabled" on BOTH views, while canonical bools keep
// the documented truthy-wins behaviour (RM-8 / RM-13 unchanged). The OEM path
// (`kvmOemConsoleEnabled`) mirrors the same rule through the shared helper.
//
// AUDIT (2026-11-22): the two factories already agree for every encoding the
// seam allows — the only existing coverage is a single `ServiceEnabled: 'true'`
// case on the console view in `kvm_model_test.dart`, and nothing pins that a
// one-sided "coerce string/number enablement to bool" refactor cannot desync
// the capability card from the console card while every single-surface suite
// stays GREEN (the #009 divergence class). This is therefore a regression
// guard at a genuinely unguarded seam, not churn: it records the byte-for-byte
// agreement and fails closed the moment either side stops normalizing an
// encoding the same way.
//
// Pure-model, display-only, dependency-free and TLS-safe: no URL is opened, no
// WebView/protocol dependency is imported and production TLS is untouched.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

const String _kUri = 'https://bmc.example/kvm';
const String _kSource = '/redfish/v1/Managers/BMC/GraphicalConsole';

/// Non-canonical enablement encodings. None is the canonical bool `true`, so
/// each must fail closed to "not enabled" on BOTH KVM views.
const List<MapEntry<String, dynamic>> _hostileEncodings =
    <MapEntry<String, dynamic>>[
  MapEntry<String, dynamic>('string "true"', 'true'),
  MapEntry<String, dynamic>('string "TRUE"', 'TRUE'),
  MapEntry<String, dynamic>('padded " true "', ' true '),
  MapEntry<String, dynamic>('int 1', 1),
  MapEntry<String, dynamic>('int 0', 0),
  MapEntry<String, dynamic>('double 1.0', 1.0),
  MapEntry<String, dynamic>('null', null),
  MapEntry<String, dynamic>('empty list', <dynamic>[]),
  MapEntry<String, dynamic>('map', <String, dynamic>{'enabled': true}),
  MapEntry<String, dynamic>('control-bearing "true\\r\\n"', 'true\r\n'),
];

/// A one-block GraphicalConsole manager body with a canonical secure endpoint,
/// a boundary session limit and the supplied enablement encoding(s).
Map<String, dynamic> _body({
  required dynamic serviceEnabled,
  dynamic enabled,
  bool includeEnabled = false,
}) {
  final Map<String, dynamic> block = <String, dynamic>{
    'ServiceEnabled': serviceEnabled,
    'ConnectUri': _kUri,
    'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
    'MaxConcurrentSessions': 2,
    '@odata.id': _kSource,
  };
  if (includeEnabled) block['Enabled'] = enabled;
  return <String, dynamic>{'GraphicalConsole': block};
}

KvmConsole _console(Map<String, dynamic> body) =>
    KvmConsole.fromManager(body, managerId: 'BMC').single;

KvmCapability _capability(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC');

void main() {
  group('RM-16 hostile ServiceEnabled encoding — both factories fail closed',
      () {
    for (final MapEntry<String, dynamic> encoding in _hostileEncodings) {
      test('${encoding.key} is "not enabled" and agrees across both views', () {
        final Map<String, dynamic> body = _body(serviceEnabled: encoding.value);
        final KvmConsole console = _console(body);
        final KvmCapability cap = _capability(body);

        // Neither view treats a non-canonical encoding as truthy.
        expect(console.serviceEnabled, isFalse,
            reason: 'console view must fail closed for ${encoding.key}');
        expect(cap.serviceEnabled, isFalse,
            reason: 'capability view must fail closed for ${encoding.key}');
        expect(console.canOpenConsole, isFalse);
        expect(cap.supported, isFalse);

        // Byte-for-byte agreement of the fields the two cards render.
        expect(console.serviceEnabled, cap.serviceEnabled);
        expect(console.connectTypesSupported, cap.connectTypes);
        expect(console.maxConcurrentSessions, cap.maxSessions);
      });
    }
  });

  group('RM-16 hostile legacy Enabled encoding — both factories fail closed',
      () {
    for (final MapEntry<String, dynamic> encoding in _hostileEncodings) {
      test('${encoding.key} on Enabled agrees across both views', () {
        final Map<String, dynamic> body = _body(
          serviceEnabled: const <String, dynamic>{}, // present, non-truthy map
          enabled: encoding.value,
          includeEnabled: true,
        );
        final KvmConsole console = _console(body);
        final KvmCapability cap = _capability(body);

        expect(console.serviceEnabled, isFalse);
        expect(cap.serviceEnabled, isFalse);
        expect(console.canOpenConsole, isFalse);
        expect(cap.supported, isFalse);
        expect(console.serviceEnabled, cap.serviceEnabled);
        expect(console.connectTypesSupported, cap.connectTypes);
        expect(console.maxConcurrentSessions, cap.maxSessions);
      });
    }
  });

  group('RM-16 canonical bools and truthy-wins are unchanged on both views',
      () {
    test('canonical true is enabled, openable and URI-agreed on both views',
        () {
      final Map<String, dynamic> body = _body(serviceEnabled: true);
      final KvmConsole console = _console(body);
      final KvmCapability cap = _capability(body);

      expect(console.serviceEnabled, isTrue);
      expect(cap.serviceEnabled, isTrue);
      expect(console.canOpenConsole, isTrue);
      expect(cap.supported, isTrue);
      expect(console.serviceEnabled, cap.serviceEnabled);
      expect(cap.uri, console.launchUri);
      expect(console.connectTypesSupported, cap.connectTypes);
      expect(console.maxConcurrentSessions, cap.maxSessions);
    });

    test('canonical false is disabled and not openable on both views', () {
      final Map<String, dynamic> body = _body(serviceEnabled: false);
      final KvmConsole console = _console(body);
      final KvmCapability cap = _capability(body);

      expect(console.serviceEnabled, isFalse);
      expect(cap.serviceEnabled, isFalse);
      expect(console.canOpenConsole, isFalse);
      expect(cap.supported, isFalse);
      expect(console.serviceEnabled, cap.serviceEnabled);
    });

    test('a canonical true wins over a hostile or false sibling on both views',
        () {
      for (final dynamic sibling in <dynamic>[false, 'false', 0, null]) {
        final Map<String, dynamic> serviceTrue = _body(
          serviceEnabled: true,
          enabled: sibling,
          includeEnabled: true,
        );
        expect(_console(serviceTrue).serviceEnabled, isTrue,
            reason: 'ServiceEnabled:true must win over $sibling');
        expect(_capability(serviceTrue).serviceEnabled, isTrue);
        expect(_console(serviceTrue).canOpenConsole, isTrue);
        expect(_capability(serviceTrue).supported, isTrue);

        final Map<String, dynamic> enabledTrue = _body(
          serviceEnabled: 'true', // hostile, not truthy
          enabled: true,
          includeEnabled: true,
        );
        expect(_console(enabledTrue).serviceEnabled, isTrue,
            reason: 'legacy Enabled:true must win over hostile $sibling');
        expect(_capability(enabledTrue).serviceEnabled, isTrue);
        expect(_console(enabledTrue).canOpenConsole, isTrue);
        expect(_capability(enabledTrue).supported, isTrue);
      }
    });
  });

  group('RM-16 hostile enablement on an OEM console — both factories agree',
      () {
    Map<String, dynamic> oemBody(dynamic flag) => <String, dynamic>{
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{
              'KVM': <String, dynamic>{
                'Uri': _kUri,
                'ServiceEnabled': flag,
              },
            },
          },
        };

    for (final MapEntry<String, dynamic> encoding in _hostileEncodings) {
      test('OEM ${encoding.key} is "not enabled" on both views', () {
        final Map<String, dynamic> body = oemBody(encoding.value);
        final KvmConsole console = _console(body);
        final KvmCapability cap = _capability(body);

        expect(console.serviceEnabled, isFalse);
        expect(cap.serviceEnabled, isFalse);
        expect(cap.supported, isFalse);
        expect(console.serviceEnabled, cap.serviceEnabled);
      });
    }

    test('OEM canonical true and false agree on both views', () {
      final Map<String, dynamic> enabled = oemBody(true);
      expect(_console(enabled).serviceEnabled, isTrue);
      expect(_capability(enabled).serviceEnabled, isTrue);
      expect(_capability(enabled).supported, isTrue);

      final Map<String, dynamic> disabled = oemBody(false);
      expect(_console(disabled).serviceEnabled, isFalse);
      expect(_capability(disabled).serviceEnabled, isFalse);
      expect(_capability(disabled).supported, isFalse);
    });
  });
}
