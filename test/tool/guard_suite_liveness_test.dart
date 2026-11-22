// EP-T12 (epic #009/#021): machine-checkable closeout of the "who guards the
// guards" remainder. The repo now relies on a family of KVM safety guard tests
// (RU-2/EP-T9 copy, EP-T11 URI-parse, EP-T8 source-display, EP-P5 imports,
// EP-P6/P7/P8 policy/doc, EP-T7 doctor, LA-1 assets, EP-T6 unattended) — but
// nothing failed closed if one of those guard files was later deleted, emptied,
// stripped of its test cases, or silently de-invoked from the standard CI run.
// This pure-Dart guard enumerates the established guard files and fails closed
// on any such drift, so a future edit cannot silently disable a safety net.
//
// EP-T14 (epic #009/#021) extends this canonical set with the safety guards that
// landed AFTER EP-T12 (queue-item schema, production-opt-in construction,
// cross-layer authority agreement, flag-off false-claim, viewer disclosure,
// real-provider wiring and session audit/identity invariants). Without this
// extension, deleting / emptying / test-stripping one of those newer guards (or
// de-invoking it from CI) would stay GREEN. A dedicated test pins the extension
// itself so a future edit cannot quietly drop a guard back out of the set.
//
// EP-T15 (epic #009/#021) extends the set once more with the six behavioral
// regression guards that landed AFTER EP-T14 (direct-construction KVMIP
// fallback, manager-source precedence, multi-vendor enablement, controller
// dispose-after-async-gap, service manager-identity and card cross-surface
// agreement). All six are live, checked-in test files reachable from the
// whole-tree CI run, but none was liveness-checked: deleting / emptying /
// test-stripping one of them would stay GREEN. A dedicated pinned subset makes
// the extension itself fail closed against a future silent drop.
//
// EP-T16 (epic #009/#021) extends the set once more with the three widget-level
// regression guards that landed AFTER EP-T15 (cross-surface clipboard-target
// agreement, in-list reload indicator, in-list stale-data refresh warning).
// Each is a live, checked-in test file reachable from the whole-tree CI run, but
// none was liveness-checked: deleting / emptying / test-stripping one of them
// would stay GREEN. A dedicated pinned subset (disjoint from EP-T14/EP-T15) makes
// the extension itself fail closed against a future silent drop.
//
// EP-T17 (epic #009/#021) extends the set once more with the four safety guards
// that landed AFTER EP-T16 (service lookup-key normalization, OEM depth-bound
// agreement, populated-ListView four-state agreement, validation-evidence
// checklist). Each is a live, checked-in test file reachable from the whole-tree
// CI run, but none was liveness-checked: deleting / emptying / test-stripping
// one of them would stay GREEN. A dedicated pinned subset (disjoint from
// EP-T14/EP-T15/EP-T16) makes the extension itself fail closed against a future
// silent drop.
//
// EP-T18 (epic #009/#021) extends the set once more with the three safety guards
// that landed AFTER EP-T17 (service capability↔primary agreement, viewer
// URI-surface agreement, capability↔primary secure-URI agreement). Each is a
// live, checked-in test file reachable from the whole-tree CI run, but none was
// liveness-checked: deleting / emptying / test-stripping one of them would stay
// GREEN. A dedicated pinned subset (disjoint from EP-T14/EP-T15/EP-T16/EP-T17)
// makes the extension itself fail closed against a future silent drop.
//
// EP-T19 (epic #009/#021) extends the set once more with the three safety guards
// that landed AFTER EP-T18 (security-first × enabled-block tri-state agreement,
// navigation-gate ↔ launch-route fail-closed agreement, three-surface launch
// target agreement). Each is a live, checked-in test file reachable from the
// whole-tree CI run, but none was liveness-checked: deleting / emptying /
// test-stripping one of them would stay GREEN. A dedicated pinned subset
// (disjoint from EP-T14/EP-T15/EP-T16/EP-T17/EP-T18) makes the extension itself
// fail closed against a future silent drop.
//
// EP-T20 (epic #009/#021) closes a CONFIRMED "who guards the guards" registry
// gap: EP-T19 pinned canonicalGuardFiles to 34, but EP-M6 later added
// `kvm_oem_uri_shadow_agreement_test.dart` DIRECTLY to the set with no pinned
// epoch subset, and three genuine safety guards audited live and reachable from
// the whole-tree CI run (`kvm_lifecycle_parity_test.dart`,
// `kvm_notice_surface_audit_test.dart`, `platform/webview_policy_test.dart`)
// were absent from the set entirely — so dropping / emptying / test-stripping
// / CI-de-invoking any of them stayed GREEN. EP-T20 adds a pinned `epT20AddedGuards`
// subset (disjoint from EP-T14/15/16/17/18/19), AND a registry-completeness
// invariant requiring canonicalGuardFiles to equal the union of the EP-T12
// initial set and every pinned epoch subset in BOTH directions, so no guard can
// be silently dropped or sit unpinned in a future run.
//
// EP-M5 (epic #009/#021) extends the set with the hostile `ConnectTypesSupported`
// cross-factory agreement guard. The two model normalizers already agree over a
// small single-block matrix, but nothing pinned agreement over the full hostile
// matrix (nested list/map entries, control-bearing values) or over the
// multi-block enabled-preference / all-disabled fallback — deleting / emptying /
// test-stripping that guard would otherwise stay GREEN. A pinned `epM5AddedGuards`
// subset (disjoint from every earlier epoch) makes the extension fail closed.
//
// The evaluator lives in this TEST-only file so it never scans or touches
// product code. It is dependency-free, opens no network, uses no credentials,
// and never weakens production TLS. The RED→GREEN proof uses a temporary scan
// root; the real-repo invariant pins the checked-in guard suite + CI invocation.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The established KVM safety guard test files, stored as repo-relative,
/// forward-slash paths for cross-platform stability. This is the minimum set
/// named by EP-T12; adding a new guard to this list is cheap and intentional.
const List<String> canonicalGuardFiles = <String>[
  // EP-T12 initial set.
  'test/tool/notice_single_source_guard_test.dart',
  'test/tool/launch_status_single_source_guard_test.dart',
  'test/tool/uri_parse_single_source_guard_test.dart',
  'test/tool/manager_source_display_guard_test.dart',
  'test/features/kvm/platform/product_import_policy_test.dart',
  'test/features/kvm/platform/production_route_invariant_test.dart',
  'test/features/kvm/platform/human_gate_doc_guard_test.dart',
  'test/features/kvm/platform/decision_doc_route_guard_test.dart',
  // EP-T14 extension: safety guards that landed after EP-T12.
  'test/tool/queue_item_schema_guard_test.dart',
  'test/features/kvm/platform/production_optin_construction_guard_test.dart',
  'test/features/kvm/platform/cross_layer_authority_agreement_test.dart',
  'test/features/kvm/kvm_viewer_flagoff_false_claim_guard_test.dart',
  'test/features/kvm/kvm_viewer_disclosure_contract_test.dart',
  'test/features/kvm/kvm_providers_test.dart',
  'test/features/kvm/kvm_session_audit_invariants_test.dart',
  // EP-T15 extension: behavioral regression guards that landed after EP-T14.
  'test/features/kvm/kvm_capability_kvmip_fallback_test.dart',
  'test/features/kvm/kvm_manager_source_precedence_test.dart',
  'test/features/kvm/kvm_oem_multi_vendor_enablement_test.dart',
  'test/features/kvm/kvm_controller_dispose_guard_test.dart',
  'test/features/kvm/kvm_service_manager_identity_test.dart',
  'test/features/kvm/kvm_card_cross_surface_agreement_test.dart',
  // EP-T16 extension: widget-level regression guards that landed after EP-T15.
  'test/features/kvm/kvm_clipboard_cross_surface_agreement_test.dart',
  'test/features/kvm/kvm_view_reload_indicator_test.dart',
  'test/features/kvm/kvm_view_stale_error_banner_test.dart',
  // EP-T17 extension: safety guards that landed after EP-T16.
  'test/features/kvm/kvm_service_lookup_key_test.dart',
  'test/features/kvm/kvm_oem_depth_bound_agreement_test.dart',
  'test/features/kvm/kvm_view_state_agreement_test.dart',
  'test/features/kvm/platform/validation_evidence_checklist_guard_test.dart',
  // EP-T18 extension: safety guards that landed after EP-T17.
  'test/features/kvm/kvm_service_capability_primary_agreement_test.dart',
  'test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart',
  'test/features/kvm/kvm_capability_primary_uri_agreement_test.dart',
  // EP-T19 extension: safety guards that landed after EP-T18.
  'test/features/kvm/kvm_capability_security_tristate_agreement_test.dart',
  'test/features/kvm/platform/navigation_launch_route_agreement_test.dart',
  'test/features/kvm/kvm_three_surface_launch_target_agreement_test.dart',
  // EP-M6 extension: OEM-console URI shadow agreement across both views.
  'test/features/kvm/kvm_oem_uri_shadow_agreement_test.dart',
  // EP-T20 extension: post-EP-T19 safety guards audited live + reachable.
  'test/features/kvm/kvm_lifecycle_parity_test.dart',
  'test/features/kvm/kvm_notice_surface_audit_test.dart',
  'test/features/kvm/platform/webview_policy_test.dart',
  // EP-U16 extension: cross-card protocol-notice rendered agreement.
  'test/features/kvm/kvm_external_notice_cross_surface_agreement_test.dart',
  // EP-M5 extension: hostile ConnectTypesSupported cross-factory agreement.
  'test/features/kvm/kvm_connect_types_hostile_agreement_test.dart',
];

/// The eight guard files named by EP-T12 (the initial canonical set). Pinned so
/// the EP-T20 registry-completeness invariant can account for every entry in
/// [canonicalGuardFiles] without treating the initial set as unpinned churn.
const Set<String> epT12InitialGuards = <String>{
  'test/tool/notice_single_source_guard_test.dart',
  'test/tool/launch_status_single_source_guard_test.dart',
  'test/tool/uri_parse_single_source_guard_test.dart',
  'test/tool/manager_source_display_guard_test.dart',
  'test/features/kvm/platform/product_import_policy_test.dart',
  'test/features/kvm/platform/production_route_invariant_test.dart',
  'test/features/kvm/platform/human_gate_doc_guard_test.dart',
  'test/features/kvm/platform/decision_doc_route_guard_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T14. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping a newer guard
/// back out of the canonical set (issue #009/#021).
const Set<String> epT14AddedGuards = <String>{
  'test/tool/queue_item_schema_guard_test.dart',
  'test/features/kvm/platform/production_optin_construction_guard_test.dart',
  'test/features/kvm/platform/cross_layer_authority_agreement_test.dart',
  'test/features/kvm/kvm_viewer_flagoff_false_claim_guard_test.dart',
  'test/features/kvm/kvm_viewer_disclosure_contract_test.dart',
  'test/features/kvm/kvm_providers_test.dart',
  'test/features/kvm/kvm_session_audit_invariants_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T15. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// behavioral regression guards back out of the canonical set (issue #009/#021).
const Set<String> epT15AddedGuards = <String>{
  'test/features/kvm/kvm_capability_kvmip_fallback_test.dart',
  'test/features/kvm/kvm_manager_source_precedence_test.dart',
  'test/features/kvm/kvm_oem_multi_vendor_enablement_test.dart',
  'test/features/kvm/kvm_controller_dispose_guard_test.dart',
  'test/features/kvm/kvm_service_manager_identity_test.dart',
  'test/features/kvm/kvm_card_cross_surface_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T16. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// widget-level regression guards back out of the canonical set (issue #009/#021).
const Set<String> epT16AddedGuards = <String>{
  'test/features/kvm/kvm_clipboard_cross_surface_agreement_test.dart',
  'test/features/kvm/kvm_view_reload_indicator_test.dart',
  'test/features/kvm/kvm_view_stale_error_banner_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T17. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// post-EP-T16 safety guards back out of the canonical set (issue #009/#021).
const Set<String> epT17AddedGuards = <String>{
  'test/features/kvm/kvm_service_lookup_key_test.dart',
  'test/features/kvm/kvm_oem_depth_bound_agreement_test.dart',
  'test/features/kvm/kvm_view_state_agreement_test.dart',
  'test/features/kvm/platform/validation_evidence_checklist_guard_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T18. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// post-EP-T17 safety guards back out of the canonical set (issue #009/#021).
const Set<String> epT18AddedGuards = <String>{
  'test/features/kvm/kvm_service_capability_primary_agreement_test.dart',
  'test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart',
  'test/features/kvm/kvm_capability_primary_uri_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T19. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// post-EP-T18 safety guards back out of the canonical set (issue #009/#021).
const Set<String> epT19AddedGuards = <String>{
  'test/features/kvm/kvm_capability_security_tristate_agreement_test.dart',
  'test/features/kvm/platform/navigation_launch_route_agreement_test.dart',
  'test/features/kvm/kvm_three_surface_launch_target_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added/audited by EP-T20. Pinned
/// separately so a future edit cannot silence a liveness violation by dropping
/// one of these newer guards back out of the canonical set. Note the EP-M6 OEM
/// shadow guard was added directly to the list earlier; it is designated here
/// so the registry-completeness invariant can account for it.
const Set<String> epT20AddedGuards = <String>{
  'test/features/kvm/kvm_oem_uri_shadow_agreement_test.dart',
  'test/features/kvm/kvm_lifecycle_parity_test.dart',
  'test/features/kvm/kvm_notice_surface_audit_test.dart',
  'test/features/kvm/platform/webview_policy_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-U16: the cross-card
/// protocol-specific external-client notice rendered-agreement guard. Pinned
/// separately so a future edit cannot drop it out of the canonical set
/// (issue #009/#021).
const Set<String> epU16AddedGuards = <String>{
  'test/features/kvm/kvm_external_notice_cross_surface_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-M5: the hostile
/// `ConnectTypesSupported` cross-factory agreement guard. Pinned separately so
/// a future edit cannot drop it out of the canonical set (issue #009/#021).
const Set<String> epM5AddedGuards = <String>{
  'test/features/kvm/kvm_connect_types_hostile_agreement_test.dart',
};

/// Every epoch-designated guard: the EP-T12 initial set plus every pinned
/// epT*AddedGuards extension. EP-T20 requires this to equal
/// [canonicalGuardFiles] in both directions, so a guard added directly to the
/// registry without a pinned designation fails closed (issue #009/#021).
const Set<String> allDesignatedGuards = <String>{
  ...epT12InitialGuards,
  ...epT14AddedGuards,
  ...epT15AddedGuards,
  ...epT16AddedGuards,
  ...epT17AddedGuards,
  ...epT18AddedGuards,
  ...epT19AddedGuards,
  ...epT20AddedGuards,
  ...epU16AddedGuards,
  ...epM5AddedGuards,
};

/// Normalizes a path for comparison (Windows separators + a leading `./`).
String normalizePath(String path) =>
    path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

bool _isWordChar(String c) {
  final int u = c.codeUnitAt(0);
  return (u >= 48 && u <= 57) ||
      (u >= 65 && u <= 90) ||
      (u >= 97 && u <= 122) ||
      c == '_';
}

/// Removes `//` line comments, `/* */` block comments and string-literal
/// contents, keeping newlines. A guard file whose only "test(" appears in a
/// comment or string is NOT a live test case; scanning code tokens only keeps
/// this liveness guard honest (a commented-out guard cannot fake GREEN).
/// Raw strings (`r'...'`) are handled: a backslash is literal there, so `r'\'`
/// closes at the following quote instead of swallowing the rest of the file.
String stripCommentsAndStrings(String source) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  final int n = source.length;
  while (i < n) {
    final String c = source[i];
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      while (i < n && source[i] != '\n') {
        i++;
      }
      out.write(' ');
      continue;
    }
    if (c == '/' && i + 1 < n && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < n && !(source[i] == '*' && source[i + 1] == '/')) {
        i++;
      }
      i = i + 2 < n ? i + 2 : n;
      out.write(' ');
      continue;
    }
    if (c == "'" || c == '"') {
      final bool raw = i >= 1 &&
          (source[i - 1] == 'r' || source[i - 1] == 'R') &&
          (i < 2 || !_isWordChar(source[i - 2]));
      final String quote = c;
      final bool triple =
          i + 2 < n && source[i + 1] == quote && source[i + 2] == quote;
      i += triple ? 3 : 1;
      out.write(' ');
      while (i < n) {
        if (!raw && source[i] == r'\') {
          i += 2;
          continue;
        }
        if (triple) {
          if (i + 2 < n &&
              source[i] == quote &&
              source[i + 1] == quote &&
              source[i + 2] == quote) {
            i += 3;
            break;
          }
        } else if (source[i] == quote) {
          i += 1;
          break;
        }
        if (source[i] == '\n') {
          out.write('\n');
        }
        i++;
      }
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Number of live `test(...)` / `testWidgets(...)` cases in [source].
int countTestCases(String source) => RegExp(r'\btest(?:Widgets)?\s*\(')
    .allMatches(stripCommentsAndStrings(source))
    .length;

/// Evaluates a guard suite given a map of normalized path → file content and
/// the CI workflow source. Returns a list of fail-closed violations (empty means
/// the suite is intact). A missing path in [sources] is reported as MISSING.
List<String> evaluateGuardSuite(
  Map<String, String> sources,
  String verifySource,
) {
  final List<String> violations = <String>[];
  for (final String path in canonicalGuardFiles) {
    final String? source = sources[normalizePath(path)];
    if (source == null) {
      violations.add('MISSING: $path');
      continue;
    }
    if (source.trim().isEmpty) {
      violations.add('EMPTY: $path');
      continue;
    }
    if (countTestCases(source) == 0) {
      violations.add('NO_TEST_CASES: $path');
    }
  }
  // Reachable by the standard CI run: verify.yml must still invoke the
  // whole-tree `flutter test --coverage` (no path filter that could skip a
  // guard directory). Preserve the exact machine-checkable contract.
  final bool standardRun = RegExp(
    r'flutter\s+test\b[^\n]*--coverage',
  ).hasMatch(verifySource.replaceAll('\r', ''));
  if (!standardRun) {
    violations.add(
      'UNREACHABLE: verify.yml no longer runs "flutter test --coverage"',
    );
  }
  return violations;
}

/// Reads the canonical guard files present under [root] into a path → content
/// map. Missing files are omitted so [evaluateGuardSuite] reports MISSING.
Map<String, String> readSuite(Directory root) {
  final Map<String, String> sources = <String, String>{};
  for (final String path in canonicalGuardFiles) {
    final String rel = path.replaceAll('/', Platform.pathSeparator);
    final File file = File(
      '${root.path}${Platform.pathSeparator}$rel',
    );
    if (file.existsSync()) {
      sources[normalizePath(path)] = file.readAsStringSync();
    }
  }
  return sources;
}

/// Minimal but genuine synthetic guard source for the temp-root proof: one live
/// `test(...)` case, so it passes the liveness evaluator when intact.
const String syntheticGuardSource = '''
// synthetic guard
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('liveness', () {});
}
''';

void main() {
  group('EP-T12 guard-suite liveness evaluator (pure)', () {
    test('canonical inventory is non-empty and all files end in _test.dart',
        () {
      expect(canonicalGuardFiles, isNotEmpty);
      for (final String path in canonicalGuardFiles) {
        expect(path, endsWith('_test.dart'), reason: path);
        expect(path.startsWith('test/'), isTrue, reason: path);
      }
      // No duplicate entries that would mask a missing guard.
      expect(canonicalGuardFiles.toSet().length, canonicalGuardFiles.length);
    });

    test('intact synthetic suite + standard CI run is clean', () {
      final Map<String, String> sources = <String, String>{
        for (final String path in canonicalGuardFiles)
          normalizePath(path): syntheticGuardSource,
      };
      expect(
        evaluateGuardSuite(sources, '  run: flutter test --coverage\n'),
        isEmpty,
      );
    });

    test('commented-out test does not count as a live case', () {
      final String commented = stripCommentsAndStrings(
        "// test('fake', () {});\nvoid main() {}\n",
      );
      expect(RegExp(r'\btest\s*\(').hasMatch(commented), isFalse);
    });

    test('string-literal test( does not count as a live case', () {
      final String inString = stripCommentsAndStrings(
        "const String s = 'test( fake';\nvoid main() {}\n",
      );
      expect(RegExp(r'\btest\s*\(').hasMatch(inString), isFalse);
    });

    test('EP-T14: every post-EP-T12 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer guard out of the set to
      // silence an otherwise-failing liveness run is detected here.
      expect(epT14AddedGuards, isNotEmpty);
      for (final String path in epT14AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T14 guard dropped from canonical set: $path',
        );
      }
    });

    test('EP-T15: every post-EP-T14 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer behavioral guard out of the
      // set to silence an otherwise-failing liveness run is detected here.
      expect(epT15AddedGuards, isNotEmpty);
      for (final String path in epT15AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T15 guard dropped from canonical set: $path',
        );
      }
      // The two extension subsets must stay distinct — no guard may be counted
      // toward both EP-T14 and EP-T15 liveness coverage.
      expect(epT15AddedGuards.intersection(epT14AddedGuards), isEmpty);
    });

    test('EP-T16: every post-EP-T15 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer widget guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT16AddedGuards, isNotEmpty);
      for (final String path in epT16AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T16 guard dropped from canonical set: $path',
        );
      }
      // All three extension subsets must stay pairwise distinct — no guard may
      // be counted toward more than one of EP-T14 / EP-T15 / EP-T16 coverage.
      expect(epT16AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT16AddedGuards.intersection(epT15AddedGuards), isEmpty);
    });

    test('EP-T17: every post-EP-T16 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer safety guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT17AddedGuards, isNotEmpty);
      expect(epT17AddedGuards.length, 4);
      for (final String path in epT17AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T17 guard dropped from canonical set: $path',
        );
      }
      // All four extension subsets must stay pairwise distinct — no guard may
      // be counted toward more than one of EP-T14/EP-T15/EP-T16/EP-T17.
      expect(epT17AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT17AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT17AddedGuards.intersection(epT16AddedGuards), isEmpty);
    });

    test('EP-T18: every post-EP-T17 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer safety guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT18AddedGuards, isNotEmpty);
      expect(epT18AddedGuards.length, 3);
      for (final String path in epT18AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T18 guard dropped from canonical set: $path',
        );
      }
      // All five extension subsets must stay pairwise distinct — no guard may
      // be counted toward more than one of EP-T14/15/16/17/18.
      expect(epT18AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT18AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT18AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT18AddedGuards.intersection(epT17AddedGuards), isEmpty);
    });

    test('EP-T19: every post-EP-T18 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer safety guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT19AddedGuards, isNotEmpty);
      expect(epT19AddedGuards.length, 3);
      for (final String path in epT19AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T19 guard dropped from canonical set: $path',
        );
      }
      // All six extension subsets must stay pairwise distinct — no guard may be
      // counted toward more than one of EP-T14/15/16/17/18/19.
      expect(epT19AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT18AddedGuards), isEmpty);
    });

    test('EP-T20: every post-EP-T19 guard is in the canonical liveness set',
        () {
      expect(epT20AddedGuards, isNotEmpty);
      expect(epT20AddedGuards.length, 4);
      for (final String path in epT20AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T20 guard dropped from canonical set: $path',
        );
      }
      // All extension subsets + the initial set must stay pairwise
      // distinct — no guard may be counted toward more than one epoch.
      expect(epT20AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT19AddedGuards), isEmpty);
    });

    test('EP-U16: the cross-card notice guard is in the canonical liveness set',
        () {
      expect(epU16AddedGuards, isNotEmpty);
      expect(epU16AddedGuards.length, 1);
      for (final String path in epU16AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-U16 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epU16AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT20AddedGuards), isEmpty);
    });

    test(
        'EP-M5: the hostile connect-types guard is in the canonical liveness set',
        () {
      expect(epM5AddedGuards, isNotEmpty);
      expect(epM5AddedGuards.length, 1);
      for (final String path in epM5AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-M5 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epM5AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epU16AddedGuards), isEmpty);
    });

    test('EP-T20: canonical registry is exactly the union of designated guards',
        () {
      // (a) Every designated guard must remain in the canonical set — a guard
      // dropped from canonicalGuardFiles fails closed here.
      for (final String path in allDesignatedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'designated guard dropped from canonical set: $path',
        );
      }
      // (b) Every canonical entry must be epoch-designated — a guard added
      // directly to canonicalGuardFiles with no pinned set fails closed here.
      for (final String path in canonicalGuardFiles) {
        expect(
          allDesignatedGuards,
          contains(path),
          reason: 'unpinned guard added to canonical set: $path',
        );
      }
      expect(allDesignatedGuards.length, canonicalGuardFiles.length);
      // The epoch sets themselves must stay pairwise disjoint so a single
      // guard cannot satisfy the completeness invariant twice.
      expect(epT12InitialGuards.length, 8);
      expect(
        allDesignatedGuards.length,
        epT12InitialGuards.length +
            epT14AddedGuards.length +
            epT15AddedGuards.length +
            epT16AddedGuards.length +
            epT17AddedGuards.length +
            epT18AddedGuards.length +
            epT19AddedGuards.length +
            epT20AddedGuards.length +
            epU16AddedGuards.length +
            epM5AddedGuards.length,
      );
    });
  });

  group('EP-T12 RED→GREEN guard proof (temporary scan root)', () {
    test('missing / emptied / test-less / unreachable all fail closed', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t12_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync('  run: flutter test --coverage\n');

        // GREEN: everything intact.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: a guard file is deleted.
        File(p(canonicalGuardFiles[0])).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('MISSING:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[0])).writeAsStringSync(syntheticGuardSource);

        // RED 2: a guard file is emptied.
        File(p(canonicalGuardFiles[1])).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('EMPTY:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[1])).writeAsStringSync(syntheticGuardSource);

        // RED 3: a guard keeps prose but loses every test case.
        File(p(canonicalGuardFiles[2])).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('NO_TEST_CASES:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[2])).writeAsStringSync(syntheticGuardSource);

        // RED 4: CI no longer runs the whole-tree coverage suite.
        verify.writeAsStringSync('  run: echo nothing-to-see\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('UNREACHABLE:')),
          isTrue,
        );

        // GREEN again once the CI invocation is restored.
        verify.writeAsStringSync('  run: flutter test --coverage\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T14: a newly-added guard is liveness-checked (missing/emptied)',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t14_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T14 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12 initial set.
      final String addedGuard = epT14AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the newly-added guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );

        // GREEN again once the guard is restored.
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T15: newly-added behavioral guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t15_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T15 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/EP-T14 sets.
      final String addedGuard = epT15AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added behavioral guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T16: newly-added widget guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t16_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T16 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15 sets.
      final String addedGuard = epT16AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added widget guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T17: newly-added post-EP-T16 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t17_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T17 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16 sets.
      final String addedGuard = epT17AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T18: newly-added post-EP-T17 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t18_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T18 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16/17 sets.
      final String addedGuard = epT18AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T19: newly-added post-EP-T18 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t19_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T19 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16/17/18 sets.
      final String addedGuard = epT19AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T20: newly-added post-EP-T19 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t20_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T20 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16/17/18/19 sets.
      final String addedGuard = epT20AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T12 real repository invariant', () {
    test('every established KVM safety guard is present, live and reachable',
        () {
      final File verify = File('.github/workflows/verify.yml');
      expect(verify.existsSync(), isTrue);
      final List<String> violations = evaluateGuardSuite(
          readSuite(Directory('.')), verify.readAsStringSync());
      expect(
        violations,
        isEmpty,
        reason: 'guard-suite drift: ${violations.join(", ")}',
      );
    });
  });
}
