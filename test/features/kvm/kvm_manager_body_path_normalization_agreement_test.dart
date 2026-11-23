// EP-M7 (epic #009 / #021): the per-console card (`KvmConsole.fromManager`) and
// the per-manager capability card (`KvmCapability.fromManager`) read the SAME
// BMC-supplied manager body. Both route the body `@odata.id` through the shared
// `kvmManagerSourceUri` normalizer and expose a control-safe `safeManagerUri`
// (the single source for the rendered source row and the clipboard fallback).
//
// AUDIT (before adding this guard): RM-15 pins bidi / format / confusable marks
// in the `@odata.id` path, RM-18/RM-19 pin the hostile-managerId DERIVED
// fallback, RS-5 (`kvm_manager_source_precedence_test.dart`) pins the 3-level
// override/fallback precedence, and `kvm_capability_test.dart` pins one
// non-string (int / map) and one blank body id. The `launch_plan_test.dart`
// suite sweeps dot-segments / `%2F` / `%5C` / repeated `//` only on CONNECT-URI
// AUTHORITIES. Nothing, however, drives the structurally hostile BODY
// `@odata.id` RESOURCE-PATH family (`.` / `..`, `%2F` / `%5C`, repeated `//`,
// trailing control/whitespace, non-string) through BOTH `fromManager` factories
// at once and pins that they resolve the SAME trimmed source, the SAME
// control-safe `safeManagerUri` and the SAME manager identity. A one-sided
// normalization edit (e.g. collapsing dot-segments in only the capability
// factory) could make the two cards advertise different manager sources while
// every single-surface suite stayed GREEN.
//
// Regression guard at a genuinely unguarded seam, not churn: today both
// factories agree byte-for-byte and fail closed. Pure-model, display-only,
// dependency-free and TLS-safe: no URL is opened, no WebView/protocol dependency
// is imported, and production TLS is untouched. This is the BODY-path side;
// the DERIVED fallback (RM-18/RM-19) and bidi path (RM-15) stay covered by
// their own guards — no behaviour change folded in.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_manager_source.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';

/// One structurally hostile body `@odata.id` resource path and the source /
/// control-safe source both factories must resolve.
class _PathCase {
  const _PathCase(
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

  // The raw control / separator family the two `safeManagerUri` getters reject
  // (mirrors the shared gate): C0/DEL/Unicode C+Z and backslash.
  final RegExp rawControl = RegExp(r'[\\"<>{|}`^\p{C}\p{Z}]', unicode: true);

  const List<_PathCase> cases = <_PathCase>[
    _PathCase('clean resource path', '${p}BMC', '${p}BMC', '${p}BMC'),
    _PathCase('single dot-segment', '${p}./BMC', '${p}./BMC', '${p}./BMC'),
    _PathCase('parent dot-segment', '${p}BMC/../evil', '${p}BMC/../evil',
        '${p}BMC/../evil'),
    _PathCase('leading traversal', '${p}../../etc/passwd',
        '${p}../../etc/passwd', '${p}../../etc/passwd'),
    _PathCase('percent-encoded separators', '${p}%2F..%5Cevil',
        '${p}%2F..%5Cevil', '${p}%2F..%5Cevil'),
    _PathCase('repeated slashes', '${p}/BMC//', '${p}/BMC//', '${p}/BMC//'),
    _PathCase('space padded', '  ${p}BMC  ', '${p}BMC', '${p}BMC'),
    _PathCase('trailing CRLF (trimmed)', '${p}BMC\r\n', '${p}BMC', '${p}BMC'),
    _PathCase('trailing NUL (gate fails closed)', '${p}BMC\x00', '${p}BMC\x00',
        derived),
    _PathCase('embedded CRLF header injection (gate fails closed)',
        '${p}BMC\r\nX-Injected: 1', '${p}BMC\r\nX-Injected: 1', derived),
    _PathCase('percent-encoded control octet (gate fails closed)', '${p}BMC%00',
        '${p}BMC%00', derived),
    _PathCase('non-string int', 42, derived, derived),
    _PathCase('non-string list', <String>['${p}BMC'], derived, derived),
    _PathCase('non-string map', <String, dynamic>{'@odata.id': '${p}BMC'},
        derived, derived),
    _PathCase('non-string bool', true, derived, derived),
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
      'EP-M7 body @odata.id resource-path — both fromManager factories agree '
      '(#009/#021)', () {
    for (final _PathCase c in cases) {
      test('${c.name}: identical source / safe source / identity on both views',
          () {
        final Map<String, dynamic> body = manager(c.odataId);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: managerId).single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: managerId);

        // Both factories resolve the SAME trimmed source and manager identity.
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
      });
    }
  });

  test(
      'EP-M7 load-bearing classifier agrees with both getters on the body-path '
      'matrix (#009/#021)', () {
    for (final _PathCase c in cases) {
      final bool safe = isControlSafeConsoleUri(c.expectedSource);
      // Where the shared gate rejects the raw source, both getters must have
      // fallen back to the derived path; where it accepts it, both must keep it
      // verbatim (which for the clean/padded cases is the derived string).
      final String gateExpected = safe ? c.expectedSource : derived;
      expect(c.expectedSafe, gateExpected, reason: c.name);
    }
  });
}
