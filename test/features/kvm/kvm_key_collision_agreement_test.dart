// RM-17 (issues #009 / #021): duplicate / case-variant console-block KEY
// collision agreement across the two operator surfaces for one Redfish manager.
//
// `KvmConsole.fromManager` (the per-console card, via `_fromBlock`) and
// `KvmCapability.fromManager` (the capability card, via `_blockEnabled` /
// `_explicitlyDisabled` / `_aggregateMaxSessions`) read the BMC-supplied
// `ServiceEnabled`, legacy `Enabled` and `MaxConcurrentSessions` members with an
// EXACT-case key lookup. A hostile BMC — or a parser that lowercases keys late —
// may ship the same member under several case variants/duplicates with
// CONFLICTING values (`ServiceEnabled: true` plus `serviceenabled: false`). Both
// factories must ignore the non-canonical spellings and agree byte-for-byte:
// one surface must never resolve enablement / URI / chips / session limit from a
// different key than the other (the #009 cross-view divergence class).
//
// AUDIT (2026-11-22): every prior agreement guard fed hostile *values* through
// canonical keys (RM-16 encoding, RM-15 bidi, EP-M5 connect types) — nothing
// fed duplicate / case-variant / padded *KEYS* with conflicting values through
// BOTH factories, so a one-sided "normalize keys to lower-case in one factory"
// refactor could desync the two cards while every single-surface suite stayed
// GREEN. Both factories already agree for the whole matrix (canonical exact-case
// keys are authoritative, non-canonical spellings fail closed to ignored) — a
// regression guard at a genuinely unguarded seam, not churn or a live drift.
//
// Pure-model, display-only, dependency-free and TLS-safe: no URL is opened, no
// WebView/protocol dependency is imported and production TLS is untouched.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

const String _kUri = 'https://bmc.example/console';
const String _kSource = '/redfish/v1/Managers/BMC/GraphicalConsole';

/// A canonical, single-key graphical console block: enabled, a boundary session
/// limit, a secure HTTPS endpoint and two advertised connect types.
Map<String, dynamic> _canonicalBlock() => <String, dynamic>{
      'ServiceEnabled': true,
      'Enabled': false,
      'MaxConcurrentSessions': 5,
      'ConnectUri': _kUri,
      'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
      '@odata.id': _kSource,
    };

Map<String, dynamic> _graphicalBody(Map<String, dynamic> block) =>
    <String, dynamic>{'GraphicalConsole': block};

KvmConsole _console(Map<String, dynamic> body) =>
    KvmConsole.fromManager(body, managerId: 'BMC').single;

KvmCapability _capability(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC');

/// Every field both operator cards render from a console block, asserted
/// equal across the two factories. Keeps the agreement pin in one place.
void _expectAgree(KvmConsole console, KvmCapability cap) {
  expect(console.serviceEnabled, cap.serviceEnabled, reason: 'serviceEnabled');
  expect(console.connectTypesSupported, cap.connectTypes,
      reason: 'connect types');
  expect(console.maxConcurrentSessions, cap.maxSessions, reason: 'maxSessions');
  expect(console.connectUri, cap.uri, reason: 'resolved URI');
}

void main() {
  group('RM-17 canonical control — exact-case keys win on both views', () {
    test('a single-key enabled graphical console agrees field-for-field', () {
      final Map<String, dynamic> body = _graphicalBody(_canonicalBlock());
      final KvmConsole console = _console(body);
      final KvmCapability cap = _capability(body);

      expect(console.serviceEnabled, isTrue);
      expect(cap.serviceEnabled, isTrue);
      expect(cap.supported, isTrue);
      expect(console.canOpenConsole, isTrue);
      expect(console.maxConcurrentSessions, 5);
      expect(cap.maxSessions, 5);
      expect(console.connectTypesSupported, <String>['KVMIP', 'HTML5']);
      expect(console.connectUri, _kUri);
      _expectAgree(console, cap);
    });
  });

  group('RM-17 colliding / case-variant keys never change either view', () {
    // Each collision supplies a CONFLICTING value under a non-canonical spelling
    // of a key the factories actually read. Canonical exact-case keys must stay
    // authoritative on BOTH views; the colliding spellings are ignored.
    const List<Map<String, dynamic>> collisions = <Map<String, dynamic>>[
      <String, dynamic>{
        'serviceenabled': false,
        'enabled': true,
        'maxconcurrentsessions': 99,
      },
      <String, dynamic>{
        'SERVICEENABLED': false,
        'ENABLED': true,
        'MAXCONCURRENTSESSIONS': 99,
      },
      <String, dynamic>{
        'ServiceEnableD': false,
        'EnableD': true,
        'maxConcurrentSessions': 99,
      },
      <String, dynamic>{
        'ServiceEnabled ': false,
        'Enabled ': true,
        ' MaxConcurrentSessions': 99,
      },
    ];

    for (int i = 0; i < collisions.length; i++) {
      test('collision set $i: canonical output is byte-identical on both views',
          () {
        final Map<String, dynamic> block = _canonicalBlock()
          ..addAll(collisions[i]);
        final Map<String, dynamic> body = _graphicalBody(block);
        final KvmConsole console = _console(body);
        final KvmCapability cap = _capability(body);
        final KvmConsole control = _console(_graphicalBody(_canonicalBlock()));
        final KvmCapability controlCap =
            _capability(_graphicalBody(_canonicalBlock()));

        // Neither view may resolve a different value just because a colliding
        // spelling is present: both must match the canonical single-key control.
        expect(console.serviceEnabled, control.serviceEnabled);
        expect(console.serviceEnabled, isTrue);
        expect(cap.serviceEnabled, controlCap.serviceEnabled);
        expect(cap.serviceEnabled, isTrue);
        expect(cap.supported, isTrue);
        expect(console.canOpenConsole, control.canOpenConsole);
        expect(console.maxConcurrentSessions, 5);
        expect(cap.maxSessions, 5);
        expect(console.connectUri, _kUri);
        expect(console.connectTypesSupported, control.connectTypesSupported);
        expect(cap.connectTypes, controlCap.connectTypes);
        _expectAgree(console, cap);

        // No raw colliding key text leaks into a rendered chip or URI.
        for (final String key in collisions[i].keys) {
          expect(
            console.connectTypesSupported
                .any((String chip) => chip.contains(key.trim())),
            isFalse,
            reason: 'chip must not echo key "$key"',
          );
          expect(console.connectUri, isNot(contains(key.trim())));
          expect(cap.uri, isNot(contains(key.trim())));
        }
      });
    }
  });

  group('RM-17 non-canonical-only keys fail closed on both views', () {
    test('only lower-case enablement/limit keys leave both views disabled', () {
      final Map<String, dynamic> block = <String, dynamic>{
        'serviceenabled': true,
        'enabled': true,
        'maxconcurrentsessions': 7,
        'ConnectUri': _kUri,
        'ConnectTypesSupported': <dynamic>['KVMIP'],
        '@odata.id': _kSource,
      };
      final Map<String, dynamic> body = _graphicalBody(block);
      final KvmConsole console = _console(body);
      final KvmCapability cap = _capability(body);

      expect(console.serviceEnabled, isFalse);
      expect(cap.serviceEnabled, isFalse);
      expect(cap.supported, isFalse);
      expect(console.canOpenConsole, isFalse);
      expect(console.maxConcurrentSessions, isNull);
      expect(cap.maxSessions, isNull);
      _expectAgree(console, cap);
    });
  });

  group('RM-17 colliding keys across blocks keep aggregate agreement', () {
    test('enabled-block preference agrees with colliding keys present', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'serviceenabled': false,
          'MaxConcurrentSessions': 5,
          'maxconcurrentsessions': 99,
          'ConnectUri': _kUri,
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          '@odata.id': _kSource,
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'serviceenabled': true,
          'MaxConcurrentSessions': 2,
          'ConnectUri': 'ssh://bmc.example/serial',
          'ConnectTypesSupported': <dynamic>['SSH'],
        },
      };
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final KvmCapability cap = _capability(body);
      final KvmConsole graphical = consoles
          .firstWhere((KvmConsole c) => c.type == KvmConsoleType.graphical);

      // Both views prefer the enabled graphical block's values over the
      // disabled serial block's and over any colliding key spelling.
      expect(graphical.serviceEnabled, isTrue);
      expect(cap.serviceEnabled, isTrue);
      expect(cap.supported, isTrue);
      expect(graphical.maxConcurrentSessions, 5);
      expect(cap.maxSessions, 5);
      expect(graphical.connectTypesSupported, <String>['KVMIP', 'HTML5']);
      expect(cap.connectTypes, <String>['KVMIP', 'HTML5']);
      expect(graphical.connectUri, _kUri);
      expect(cap.uri, _kUri);
      _expectAgree(graphical, cap);
    });
  });
}
