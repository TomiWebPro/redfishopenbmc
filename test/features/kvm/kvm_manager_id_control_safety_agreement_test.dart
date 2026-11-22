// RM-18 (epic #009 / #021): manager-ID control-safety in the DERIVED source
// fallback, cross-factory agreement.
//
// Both KVM views resolve a manager's `@odata.id` through the shared
// `kvmManagerSourceUri` normalizer and expose a control-safe `safeManagerUri`.
// When the BMC publishes an absent / blank / non-string `@odata.id`, BOTH
// factories fall through to the stable `/redfish/v1/Managers/<managerId>` path
// synthesized from the *manager id* — and when that id itself carries padding,
// CRLF / NUL / control marks or non-ASCII text, BOTH getters route the derived
// path through the shared `isControlSafeConsoleUri` gate and re-synthesize a
// deterministically percent-encoded fallback from `managerId.trim()`.
//
// AUDIT (before adding this guard): `kvm_model_test.dart` exercises hostile
// manager ids (NUL, blank) through the *direct* `KvmConsole` constructor with an
// explicitly hostile `@odata.id`, and `kvm_manager_source_bidi_agreement_test.dart`
// drives hostile `@odata.id` values through BOTH `fromManager` factories but
// always with a CLEAN `managerId: 'BMC'`. Nothing feeds a hostile `managerId`
// through BOTH `fromManager` factories while `@odata.id` is absent / blank /
// non-string (i.e. through the *derived* fallback), nor pins that the safe
// source identity agrees byte-for-byte and leaks no raw control/whitespace on
// either card. A one-sided edit to one getter (e.g. dropping `.trim()`, or
// encoding on only one view) could desync the two cards while every
// single-surface suite stayed GREEN.
//
// Regression guard at a genuinely unguarded seam, not churn: today both
// factories agree by construction and fail closed. Pure-model, display-only,
// dependency-free and TLS-safe: no URL is opened, no WebView / protocol import,
// and production TLS is untouched. No behaviour decision is folded in.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';

/// Unicode `Other` (C) + `Separator` (Z): exactly the family the shared
/// control-safety gate refuses raw in a URI (control codes, bidi/format marks,
/// raw space, NBSP, line/paragraph separators, …).
final RegExp _controlOrSeparator = RegExp(r'[\p{C}\p{Z}]', unicode: true);

/// Hostile manager ids that drive the DERIVED fallback path. Each carries
/// padding, a control/format code point, a separator, non-ASCII text or is
/// blank — the RM-18 matrix the existing suites never sweep through both
/// factories.
const List<String> kHostileManagerIds = <String>[
  '  BMC  ', // leading/trailing raw spaces (padding)
  'BMC\r\nX: 1', // CRLF (header/clipboard injection vector)
  'BMC\u0000Evil', // NUL
  'BMC\tTab', // horizontal tab (C)
  'BMC\u202ERLO', // right-to-left override format mark (C)
  'BMC\u200BZWSP', // zero-width space (C)
  'BMC\u00A0NBSP', // no-break space (Z)
  'BMC\u0430', // Cyrillic small 'a' (L, non-ASCII, resource path)
  '   ', // blank after trim
];

/// The unusable `@odata.id` values that force the derived fallback on BOTH
/// views: absent, blank / whitespace, and malformed non-string values.
const List<Object?> kBadOdataValues = <Object?>[
  null,
  '',
  '   ',
  42,
  true,
  <String>['/redfish/v1/Managers/ignored'],
  <String, dynamic>{'@odata.id': '/redfish/v1/Managers/ignored'},
];

Map<String, dynamic> _managerBody({Object? odata, bool includeOdata = true}) {
  final Map<String, dynamic> body = <String, dynamic>{
    'GraphicalConsole': <String, dynamic>{
      'ServiceEnabled': true,
      'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
      'ConnectUri': 'https://bmc.example/console',
    },
  };
  if (includeOdata) body['@odata.id'] = odata;
  return body;
}

void main() {
  group(
      'RM-18 derived-fallback manager-id control safety — both fromManager '
      'factories agree (#009/#021)', () {
    for (final Object? odata in kBadOdataValues) {
      for (final String managerId in kHostileManagerIds) {
        test(
            'odata=${odata.runtimeType} / managerId='
            '${managerId.codeUnits.map((int c) => c.toRadixString(16)).join(',')} '
            '— safe source agrees and leaks no control/whitespace', () {
          // The key is always present here — including an explicit `null`
          // value — so this loop covers blank/non-string/@odata.id=null; the
          // truly ABSENT key is covered by the separate loop below.
          final Map<String, dynamic> body =
              _managerBody(odata: odata, includeOdata: true);
          final List<KvmConsole> consoles =
              KvmConsole.fromManager(body, managerId: managerId);
          final KvmCapability capability =
              KvmCapability.fromManager(body, managerId: managerId);
          expect(consoles, isNotEmpty);

          for (final KvmConsole console in consoles) {
            // Both views derive the same raw fallback source identity.
            expect(console.sourceManagerUri, capability.sourceManagerUri,
                reason: 'derived source identity must agree on both views');

            // Both views expose the SAME control-safe source identity.
            expect(console.safeManagerUri, capability.safeManagerUri,
                reason: 'safe source must agree byte-for-byte on both views');

            // No raw control code point or stray whitespace leaks onto either
            // card's disclosed source.
            for (final String rendered in <String>[
              console.safeManagerUri,
              capability.safeManagerUri,
            ]) {
              expect(_controlOrSeparator.hasMatch(rendered), isFalse,
                  reason: 'control/whitespace leaked: $rendered');
            }
          }
        });
      }
    }

    // The truly ABSENT @odata.id case (key not present at all) is not
    // representable by the value loop above, so pin it explicitly.
    for (final String managerId in kHostileManagerIds) {
      test(
          'absent @odata.id / derived fallback agrees for managerId '
          '${managerId.codeUnits.map((int c) => c.toRadixString(16)).join(',')}',
          () {
        final Map<String, dynamic> body = _managerBody(includeOdata: false);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: managerId).single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: managerId);

        expect(console.sourceManagerUri, capability.sourceManagerUri);
        expect(console.safeManagerUri, capability.safeManagerUri);
        expect(_controlOrSeparator.hasMatch(console.safeManagerUri), isFalse);
        expect(
            _controlOrSeparator.hasMatch(capability.safeManagerUri), isFalse);
      });
    }
  });

  group(
      'RM-18 derived fallback is trimmed + percent-encoded byte-exactly '
      '(#009/#021)', () {
    // Representative hostile ids with the exact expected safe fallback. A
    // one-sided `trim()` / encoding edit drifts from these literals.
    const Map<String, String> kExpected = <String, String>{
      '  BMC  ': '/redfish/v1/Managers/BMC',
      'BMC\u0000Evil': '/redfish/v1/Managers/BMC%00Evil',
      'BMC\r\nX: 1': '/redfish/v1/Managers/BMC%0D%0AX%3A%201',
      '   ': '/redfish/v1/Managers/manager',
    };

    for (final MapEntry<String, String> entry in kExpected.entries) {
      test('managerId="${entry.key}" -> ${entry.value} on both views', () {
        final Map<String, dynamic> body = _managerBody(includeOdata: false);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: entry.key).single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: entry.key);

        expect(console.safeManagerUri, entry.value);
        expect(capability.safeManagerUri, entry.value);
        expect(console.safeManagerUri, capability.safeManagerUri);
      });
    }
  });

  test(
      'RM-18 the shared gate is what forces the encoded fallback '
      '(load-bearing invariant, both getters delegate to it) (#009/#021)', () {
    // A raw padded path is rejected, so both getters must re-synthesize from
    // the trimmed, percent-encoded manager id — never carry the raw padding.
    expect(isControlSafeConsoleUri('/redfish/v1/Managers/  BMC  '), isFalse);
    expect(
        isControlSafeConsoleUri('/redfish/v1/Managers/BMC\r\nX: 1'), isFalse);
    // A legitimate, percent-encoded derived path stays usable — no valid
    // manager source is lost by the gate.
    expect(isControlSafeConsoleUri('/redfish/v1/Managers/BMC%20one'), isTrue);
  });
}
