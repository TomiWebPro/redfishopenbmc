/// Regression guard for `KvmCapability.supportsKvmIp` (issue #009 / #021).
///
/// [KvmCapability.supportsKvmIp] is defined as the authoritative graphical-only
/// detection bit (`graphicalKvmIp`) when present — `fromManager` always sets it
/// — and, for directly constructed capabilities (widget-test fixtures, future
/// call sites) where that bit is `null`, falls back to scanning the aggregate
/// [KvmCapability.connectTypes] for a case-insensitive, trimmed `KVMIP`.
///
/// The `fromManager` half is pinned in `kvm_capability_test.dart` (the bit wins
/// over a KVMIP that only appears on a serial block). The `null`-bit fallback
/// half had NO test: every existing `supportsKvmIp` assertion goes through
/// `fromManager`, so the `?? connectTypes.any(...)` branch never executes. A
/// one-line regression to `graphicalKvmIp ?? false` (or dropping the trim/case
/// normalization) would leave the whole suite GREEN while silently breaking
/// every directly constructed capability. This guard closes that seam.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';

/// Directly constructs a capability with `graphicalKvmIp == null`, exercising
/// the fallback scan. [supported]/[serviceEnabled] are irrelevant to
/// [KvmCapability.supportsKvmIp] and set to fixed values only to satisfy the
/// constructor.
KvmCapability _direct(List<String> connectTypes, {bool? graphicalKvmIp}) =>
    KvmCapability(
      managerId: 'BMC',
      supported: true,
      connectTypes: connectTypes,
      serviceEnabled: true,
      graphicalKvmIp: graphicalKvmIp,
    );

void main() {
  group('supportsKvmIp — direct-construction fallback (null bit)', () {
    test('canonical KVMIP in connectTypes reports KVMIP support', () {
      expect(_direct(<String>['KVMIP']).supportsKvmIp, isTrue);
    });

    test('lowercase kvmip matches case-insensitively', () {
      expect(_direct(<String>['kvmip']).supportsKvmIp, isTrue);
    });

    test('padded, mixed-case KVMIP is trimmed then matched', () {
      // A BMC may emit surrounding whitespace and a different case; the
      // documented contract trims and uppercases before comparing.
      expect(_direct(<String>[' \tKvMiP\n ']).supportsKvmIp, isTrue);
    });

    test('KVMIP among other connection types is found', () {
      expect(
        _direct(<String>['HTML5', ' KVMIP ', 'SSH']).supportsKvmIp,
        isTrue,
      );
    });

    test('a non-KVMIP type list reports no KVMIP support', () {
      expect(_direct(<String>['HTML5', 'SSH']).supportsKvmIp, isFalse);
    });

    test('an empty type list reports no KVMIP support', () {
      expect(_direct(<String>[]).supportsKvmIp, isFalse);
    });

    test('only an exact KVMIP token counts — substring near-misses do not', () {
      // Reading the aggregate here must not be fooled by a type that merely
      // contains the KVMIP letters (e.g. an OEM-specific KVMIP variant).
      expect(
        _direct(<String>['KVMIP-X', 'XKVMIP', 'KVM']).supportsKvmIp,
        isFalse,
      );
    });
  });

  group('supportsKvmIp — authoritative graphicalKvmIp bit', () {
    test('a true bit wins even when connectTypes has no KVMIP', () {
      // fromManager reports the graphical console's KVMIP in the bit while the
      // aggregate list may legitimately omit it; the bit is authoritative.
      expect(
        _direct(<String>['HTML5', 'SSH'], graphicalKvmIp: true).supportsKvmIp,
        isTrue,
      );
    });

    test('a false bit wins even when connectTypes advertises KVMIP', () {
      // KVMIP advertised only on a serial/OEM block must not be reported as
      // graphical KVMIP support when the authoritative bit says otherwise.
      expect(
        _direct(<String>['KVMIP', 'SSH'], graphicalKvmIp: false).supportsKvmIp,
        isFalse,
      );
    });
  });
}
