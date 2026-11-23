// RM-21 (epic #009 / #021): the per-console card (`KvmConsole.fromManager`) and
// the per-manager capability card (`KvmCapability.fromManager`) read the SAME
// BMC-supplied manager body. Both route the body `@odata.id` through the shared
// `kvmManagerSourceUri` normalizer and expose a control-safe `safeManagerUri`
// (the single source for the rendered source row and the clipboard fallback).
//
// AUDIT (before adding this guard): EP-M7 pins the body `@odata.id` RESOURCE
// PATH family (dot-segments / encoded separators / repeated slashes /
// trailing control / non-string), RM-15 pins bidi / format / confusable marks,
// RM-18/RM-19 pin the hostile-managerId DERIVED fallback, and RS-5
// (`kvm_manager_source_precedence_test.dart`) pins the 3-level override/fallback
// precedence. On the platform side EP-P17 pins encoded userinfo and EP-P19 pins
// query/fragment controls on the CONNECT-URI / navigation layers. Nothing,
// however, drives a body `@odata.id` carrying a QUERY (`?…`), a FRAGMENT (`#…`)
// or embedded USERINFO (`https://u:p@host/…`) — including control / CRLF /
// encoded-delimiter variants of each — through BOTH `fromManager` factories at
// once. A one-sided normalization edit (e.g. an "OData source is just the
// resource path" refactor that strips query/fragment in only the capability
// factory) could make the two cards advertise different manager sources or leak
// a credential / raw control code point to one card while the other fails
// closed, and every single-surface suite stayed GREEN.
//
// Regression guard at a genuinely unguarded seam, not churn: today both
// factories share the normalizer and the control-safety gate and agree
// byte-for-byte. Pure-model, display-only, dependency-free and TLS-safe: no URL
// is opened, no WebView/protocol dependency is imported, and production TLS is
// untouched. This is the BODY query/fragment/userinfo side; the resource-path
// (EP-M7), bidi (RM-15) and DERIVED-fallback (RM-18/RM-19) seams stay covered
// by their own guards — no behaviour change folded in.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_manager_source.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';

/// One hostile body `@odata.id` carrying a query / fragment / userinfo, the
/// source both factories resolve, and the control-safe source both must expose.
class _UriCase {
  const _UriCase(
      this.name, this.odataId, this.expectedSource, this.expectedSafe);

  final String name;
  final Object? odataId;
  final String expectedSource;
  final String expectedSafe;
}

void main() {
  const String managerId = 'BMC';
  const String derived = '/redfish/v1/Managers/BMC';
  const String p = '/redfish/v1/Managers/';
  // Synthetic, non-secret userinfo used only to pin that a credential-shaped
  // substring never reaches a card's safe source on the hostile variants.
  const String authority = 'https://u:p@bmc.example';
  const String userinfoAuthority = 'https://u:p';

  // The raw control / separator family the two `safeManagerUri` getters reject
  // (mirrors the shared gate): C0/DEL/Unicode C+Z and backslash.
  final RegExp rawControl = RegExp(r'[\\"<>{|}`^\p{C}\p{Z}]', unicode: true);

  const List<_UriCase> cases = <_UriCase>[
    // --- path-only query / fragment (no authority) ---
    _UriCase('clean query', '${p}BMC?x=1', '${p}BMC?x=1', '${p}BMC?x=1'),
    _UriCase('clean fragment', '${p}BMC#mgr', '${p}BMC#mgr', '${p}BMC#mgr'),
    _UriCase('clean query + fragment', '${p}BMC?x=1#mgr', '${p}BMC?x=1#mgr',
        '${p}BMC?x=1#mgr'),
    _UriCase('legal encoded space in query', '${p}BMC?x=a%20b',
        '${p}BMC?x=a%20b', '${p}BMC?x=a%20b'),
    _UriCase('legal encoded percent in query', '${p}BMC?x=100%25',
        '${p}BMC?x=100%25', '${p}BMC?x=100%25'),
    _UriCase(
        'padded query source', '  ${p}BMC?x=1  ', '${p}BMC?x=1', '${p}BMC?x=1'),
    _UriCase(
        'raw CRLF in query (gate fails closed)',
        '${p}BMC?x=1\r\nX-Injected: 1',
        '${p}BMC?x=1\r\nX-Injected: 1',
        derived),
    _UriCase('raw NUL in fragment (gate fails closed)', '${p}BMC#mgr\x00',
        '${p}BMC#mgr\x00', derived),
    _UriCase('internal raw space in query (gate fails closed)', '${p}BMC?x=1 2',
        '${p}BMC?x=1 2', derived),
    _UriCase('bare/malformed percent in query (gate fails closed)',
        '${p}BMC?x=%zz', '${p}BMC?x=%zz', derived),
    _UriCase('pct-encoded control octet in query (gate fails closed)',
        '${p}BMC?x=%00', '${p}BMC?x=%00', derived),
    _UriCase('pct-encoded CRLF in fragment (gate fails closed)',
        '${p}BMC#x%0D%0A', '${p}BMC#x%0D%0A', derived),
    // --- embedded userinfo (authority present) ---
    _UriCase(
        'clean userinfo source stays byte-for-byte on both views',
        'https://u:p@bmc.example${p}BMC',
        'https://u:p@bmc.example${p}BMC',
        'https://u:p@bmc.example${p}BMC'),
    _UriCase('clean userinfo + query + fragment', '$authority${p}BMC?x=1#mgr',
        '$authority${p}BMC?x=1#mgr', '$authority${p}BMC?x=1#mgr'),
    _UriCase(
        'CRLF-bearing userinfo (gate fails closed, no credential leak)',
        '$userinfoAuthority\r\nX@bmc.example${p}BMC',
        '$userinfoAuthority\r\nX@bmc.example${p}BMC',
        derived),
    _UriCase(
        'NUL-bearing userinfo (gate fails closed, no credential leak)',
        '$userinfoAuthority\x00@bmc.example${p}BMC',
        '$userinfoAuthority\x00@bmc.example${p}BMC',
        derived),
    _UriCase(
        'pct-encoded @ delimiter in userinfo (gate fails closed)',
        'https://u%40p@bmc.example${p}BMC',
        'https://u%40p@bmc.example${p}BMC',
        derived),
    _UriCase(
        'pct-encoded control octet in userinfo (gate fails closed)',
        'https://u:p%0D%0A@bmc.example${p}BMC',
        'https://u:p%0D%0A@bmc.example${p}BMC',
        derived),
  ];

  Map<String, dynamic> manager(Object? source) => <String, dynamic>{
        '@odata.id': source,
        // A present console block yields one KvmConsole from `.single` and
        // no ConnectUri, so `clipboardTargetUri` degrades to `safeManagerUri`.
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
        },
      };

  group(
      'RM-21 body @odata.id query / fragment / userinfo — both fromManager '
      'factories agree (#009/#021)', () {
    for (final _UriCase c in cases) {
      test('${c.name}: identical source / safe source / identity on both views',
          () {
        final Map<String, dynamic> body = manager(c.odataId);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: managerId).single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: managerId);

        // Both factories resolve the SAME (trimmed) source and manager identity.
        expect(console.sourceManagerUri, c.expectedSource, reason: c.name);
        expect(capability.sourceManagerUri, c.expectedSource, reason: c.name);
        expect(console.sourceManagerUri, capability.sourceManagerUri,
            reason: c.name);
        expect(console.managerId, managerId, reason: c.name);
        expect(capability.managerId, managerId, reason: c.name);

        // ...and agree with the shared normalizer's own result (single source
        // of truth — a one-sided edit anywhere in the chain breaks this).
        final String helper = kvmManagerSourceUri(c.odataId, managerId);
        expect(console.sourceManagerUri, helper, reason: c.name);
        expect(capability.sourceManagerUri, helper, reason: c.name);

        // Both expose the SAME control-safe source: never a raw control code
        // point or backslash on either card's source row / clipboard fallback.
        expect(console.safeManagerUri, c.expectedSafe, reason: c.name);
        expect(capability.safeManagerUri, c.expectedSafe, reason: c.name);
        expect(console.safeManagerUri, capability.safeManagerUri,
            reason: c.name);
        expect(isControlSafeConsoleUri(console.safeManagerUri), isTrue,
            reason: c.name);
        expect(isControlSafeConsoleUri(capability.safeManagerUri), isTrue,
            reason: c.name);
        expect(rawControl.hasMatch(console.safeManagerUri), isFalse,
            reason: c.name);
        expect(rawControl.hasMatch(capability.safeManagerUri), isFalse,
            reason: c.name);

        // The console card's copy fallback (no usable ConnectUri here) agrees
        // with the capability card's sanitized source.
        expect(console.clipboardTargetUri, c.expectedSafe, reason: c.name);
        expect(console.clipboardTargetUri, capability.safeManagerUri,
            reason: c.name);

        // A hostile (control/delimiter-bearing) userinfo variant must never
        // carry the credential-shaped substring onto either card's safe source.
        if (c.expectedSafe == derived && c.expectedSource.contains('@')) {
          expect(console.safeManagerUri.contains('u:p'), isFalse,
              reason: c.name);
          expect(capability.safeManagerUri.contains('@'), isFalse,
              reason: c.name);
        }
      });
    }
  });

  test(
      'RM-21 load-bearing classifier agrees with both getters on the body '
      'query/fragment/userinfo matrix (#009/#021)', () {
    for (final _UriCase c in cases) {
      final bool safe = isControlSafeConsoleUri(c.expectedSource);
      // Where the shared gate rejects the raw source, both getters must have
      // fallen back to the derived path; where it accepts it, both must keep it
      // verbatim (clean query/fragment/userinfo sources included).
      final String gateExpected = safe ? c.expectedSource : derived;
      expect(c.expectedSafe, gateExpected, reason: c.name);
    }
  });
}
