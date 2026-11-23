# Queue rf-tooling (epic-split support — fixtures + dependency/CI)

Owns: `test/**`, `tool/**`, `test/fixtures/**`, `.github/workflows/**`, `pubspec*`.
Never writes `lib/` product code. Verify: fixture parse tests + `flutter analyze` 0 + CI verify gate.

## Backlog (head first)

<!-- rf-ideate split 2026-11-23 10:11 UTC: another concrete "who guards the guards" gap in the still-open
     #009/#021 epic. EP-T36 registered the four then-newest agreement guards, but FOUR more guards have landed
     since and are live + reachable from verify.yml whole-tree `flutter test --coverage` yet absent from BOTH
     `canonicalGuardFiles` and every pinned epoch: EP-P19 `query_fragment_control_fail_closed_agreement_test.dart`,
     RM-21 `kvm_manager_body_query_fragment_userinfo_agreement_test.dart`, EP-S17
     `kvm_service_malformed_body_transport_agreement_test.dart` and EP-U24
     `kvm_card_unbreakable_chip_agreement_test.dart`. Deleting / emptying / test-stripping any of them stays GREEN.
     AUDIT FIRST; skip any already registered and register only the genuinely-unguarded remainder; RED→GREEN only
     on a genuine gap, never churn. Pure test/tool, dependency-free, never writes `lib/`. No code touched. -->

- [x] EP-T37 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-T37 guard-suite liveness registration of the four newest agreement guards + RED->GREEN tests`, test/tool-only) — Guard-suite liveness registration of the four newest agreement guards (EP-P19 query/fragment control fail-closed, RM-21 body-id query/fragment/userinfo agreement, EP-S17 malformed-body / transport skip-vs-propagate, EP-U24 unbreakable chip no-overflow): extend `test/tool/guard_suite_liveness_test.dart` so each unregistered guard is in `canonicalGuardFiles` and a fresh pinned epoch (disjoint from every earlier designation) is included in `allDesignatedGuards` + the completeness arithmetic, with a containment/disjointness pin test and a temp-root RED→GREEN proof (deleted / emptied / test-stripped → violation, intact → clean) for each. AUDIT FIRST: if any guard is already registered in a canonical set or pinned epoch, skip it and register only the genuinely-unguarded remainder; RED→GREEN only on a genuine gap, never churn. Pure test/tool, dependency-free, never writes `lib/`; no WebView/protocol import, no production TLS weakening.
       Dept: rf-tooling
       Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues), RED→GREEN proof only on a genuine gap; test/tool-only, never writes `lib/`; no dependency, no WebView/protocol import, no production TLS weakening.
      LANDED: AUDIT FIRST confirmed all four guards — EP-P19 `query_fragment_control_fail_closed_agreement_test.dart`,
               RM-21 `kvm_manager_body_query_fragment_userinfo_agreement_test.dart`, EP-S17
               `kvm_service_malformed_body_transport_agreement_test.dart` and EP-U24
               `kvm_card_unbreakable_chip_agreement_test.dart` — are live + CI-reachable (verify.yml whole-tree
               `flutter test --coverage`) yet absent from BOTH `canonicalGuardFiles` and every pinned epoch
               (EP-T36 registered only the EP-U23/EP-S10/EP-S16/EP-P18 quartet), so deleting / emptying /
               test-stripping any of them stayed GREEN — a genuine "who guards the guards" gap, no live divergence,
               not churn. Extended `test/tool/guard_suite_liveness_test.dart` (+152 lines): +4 canonical paths,
               pinned `epT37AddedGuards` epoch (length 4, pairwise-disjoint from all 25 earlier designations incl.
               EP-T36) in `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 containment/disjointness pin
               test +1 temp-root RED→GREEN (deleted / emptied / test-stripped → violation, intact → clean) for each.
               Real-file RED: dropped only the EP-U24 canonical path (epoch kept) under a 600-perm backup → exactly
               `+57 -3` (EP-T37 pin, EP-T20 completeness, EP-T37 temp-root liveness), the other 57 GREEN; source
               restored byte-clean (SHA `6b20ba4240f45339ce5a50408e0607309651ae008e36b46487d72b41474185c6`
               unchanged, 0 residue, backup shredded) → 60/60 targeted GREEN. test/tool-only, empty `lib/` diff,
               deps unchanged; analyze 0; issues validate OK; diff --check clean; emulator skipped (test/tool-only,
               <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 06:31 UTC: another concrete "who guards the guards" gap in the still-open
     #009/#021 epic. EP-T35 registered the three then-newest agreement guards, but FOUR guards have landed since
     and are live + reachable from verify.yml whole-tree `flutter test --coverage` yet absent from BOTH
     `canonicalGuardFiles` and every pinned epoch: EP-U23 `kvm_card_full_name_announcement_agreement_test.dart`
     and EP-S10 `kvm_service_all_unsafe_primary_agreement_test.dart` are both explicitly flagged in their own
     queue entries as "NOT yet liveness-registered, a future EP-T-style head", plus EP-S16
     `kvm_service_unicode_id_distinctness_test.dart` and EP-P18 `canonical_tricky_authority_agreement_test.dart`.
     Deleting / emptying / test-stripping any of them stays GREEN. AUDIT FIRST; skip any already registered and
     register only the genuinely-unguarded remainder; RED→GREEN only on a genuine gap, never churn. Pure test/tool,
     dependency-free, never writes `lib/`. No code touched. -->

- [x] EP-T36 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-T36 guard-suite liveness registration of the four newest agreement guards + RED->GREEN tests`, test/tool-only) — Guard-suite liveness registration of the four newest agreement guards (EP-U23 full-name
       announcement, EP-S10 all-unsafe primary, EP-S16 Unicode-id distinctness, EP-P18 canonical-tricky
       authority): extend `test/tool/guard_suite_liveness_test.dart` so each unregistered guard is in
       `canonicalGuardFiles` and a fresh pinned epoch (disjoint from every earlier designation) is included in
       `allDesignatedGuards` + the completeness arithmetic, with a containment/disjointness pin test and a
       temp-root RED→GREEN proof (deleted / emptied / test-stripped → violation, intact → clean) for each.
       AUDIT FIRST: if any guard is already registered in a canonical set or pinned epoch, skip it and register
       only the genuinely-unguarded remainder; RED→GREEN only on a genuine gap, never churn. Pure test/tool,
       dependency-free, never writes `lib/`; no WebView/protocol import, no production TLS weakening.
       Dept: rf-tooling
       Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
               RED→GREEN proof only on a genuine gap; test/tool-only, never writes `lib/`; no dependency,
               no WebView/protocol import, no production TLS weakening.
      LANDED: AUDIT FIRST confirmed all four guards — EP-U23 `kvm_card_full_name_announcement_agreement_test.dart`,
               EP-S10 `kvm_service_all_unsafe_primary_agreement_test.dart`, EP-S16 `kvm_service_unicode_id_distinctness_test.dart`
               and EP-P18 `canonical_tricky_authority_agreement_test.dart` — are live + CI-reachable (verify.yml
               whole-tree `flutter test --coverage`) yet absent from BOTH `canonicalGuardFiles` and every pinned epoch
               (EP-T35 registered only the EP-M7/EP-S12/EP-P17 trio), so deleting / emptying / test-stripping any of
               them stayed GREEN — a genuine "who guards the guards" gap, no live divergence, not churn. Extended
               `test/tool/guard_suite_liveness_test.dart` (+150 lines): +4 canonical paths, pinned `epT36AddedGuards`
               epoch (length 4, pairwise-disjoint from all 24 earlier designations incl. EP-T35) in
               `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 containment/disjointness pin test +1
               temp-root RED→GREEN (deleted / emptied / test-stripped → violation, intact → clean) for each.
               Real-file RED: dropped only the EP-U23 canonical path (epoch kept) under a 600-perm backup → exactly
               `+55 -3` (EP-T36 pin, EP-T20 completeness, EP-T36 temp-root liveness), the other 55 GREEN; source
               restored byte-clean (SHA `6b20ba42...` unchanged, 0 residue, backup shredded) → 58/58 targeted GREEN.
               test/tool-only, empty `lib/` diff, deps unchanged; analyze 0; full suite 2495 passed / 1 skipped
               (baseline 2489 incl. 2 concurrent rf-platform tests, +2 mine); issues validate OK; diff --check clean;
               emulator skipped (test/tool-only, <7 days since last green 85/85); no WebView/protocol import, no URL
               opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 02:27 UTC: another machine-checkable slice of the still-open #009/#021
     epic's tool hygiene. Guard-suite liveness (EP-T12..T34) pins that TEST files stay in
     `canonicalGuardFiles`, but the three newest agreement guards — EP-M7
     `kvm_manager_body_path_normalization_agreement_test.dart`, EP-S12
     `kvm_service_malformed_members_agreement_test.dart` and EP-P17
     `userinfo_authority_fail_closed_agreement_test.dart` — landed after the last registration
     (EP-T33) and are live + reachable from verify.yml whole-tree `flutter test --coverage` yet absent
     from BOTH `canonicalGuardFiles` and every pinned epoch, so deleting / emptying / test-stripping any
     of them stays GREEN. Confirmed "who guards the guards" gap, no live divergence, not churn. Pure
     test/tool, dependency-free, never writes `lib/`. AUDIT FIRST; RED->GREEN only on a genuine gap,
     never churn. No code touched. -->

- [x] EP-T35 LANDED 2026-11-23 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / targeted 56/56 / full suite 2447 passed / 1 skipped, test/tool-only) — AUDIT FIRST: all three newest agreement guards (EP-M7 body-path, EP-S12 malformed-members, EP-P17 encoded-userinfo) were live + CI-reachable but absent from BOTH `canonicalGuardFiles` and every pinned epoch, so deleting / emptying / test-stripping any of them stayed GREEN — CONFIRMED "who guards the guards" gap, no live divergence, not churn. Registered all three under a fresh pinned `epT35AddedGuards` epoch (length 3, pairwise-disjoint from all earlier designations) in `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 pin test +1 temp-root RED→GREEN proof (each of the three: deleted / emptied / test-stripped → violation, intact → clean). Real-file RED: dropped only the malformed-members canonical entry (epoch kept) under a 600-perm backup → exactly 3 named failures (`+53 -3`: EP-T35 pin, EP-T20 completeness, EP-T35 temp-root liveness), other 53 GREEN; source restored byte-clean (SHA `0453ce6a2fc487b42…` unchanged, 0 residue, backup shredded, empty `lib/` diff) → 56/56 GREEN. `dart format --output=none --set-exit-if-changed` clean (my file); deps unchanged; emulator skipped (test/tool-only, no lib-wire/fixture/tool-runtime change, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. Original item:
       Guard-suite liveness registration of the three newest agreement guards (EP-M7 body-path,
       EP-S12 malformed-members, EP-P17 encoded-userinfo): extend `test/tool/guard_suite_liveness_test.dart`
       so all three files are in `canonicalGuardFiles` and a fresh pinned epoch (disjoint from every
       earlier designation) is included in `allDesignatedGuards` + the completeness arithmetic, with a
       containment/disjointness pin test and a temp-root RED->GREEN proof (deleted / emptied / test-stripped
       -> violation, intact -> clean) for each. AUDIT FIRST: if any guard is already registered in a
       canonical set or pinned epoch, skip it and register only the genuinely-unguarded remainder;
       RED->GREEN only on a genuine gap, never churn. Pure test/tool, dependency-free, never writes `lib/`;
       no WebView/protocol import, no production TLS weakening.
       Dept: rf-tooling
       Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
               RED->GREEN proof only on a genuine gap; test/tool-only, never writes `lib/`; no dependency,
               no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 22:24 UTC: another machine-checkable slice of the still-open #009/#021
     epic's tool hygiene. EP-T31 pins that ALL FOUR coverage gates (overall / scoped redfish+power+sensors /
     kvm / kvm-platform) are actually WIRED into the CLI `main` + CI verify, but nothing pins that the four
     numeric THRESHOLDS in `tool/coverage_gate.dart` stay at or above their documented floors — a silent
     lowering (e.g. kvm 75 -> 50, or overall 80 -> 40) would keep every gate 'wired' and every test GREEN while
     erasing the hard invariant. Pure test/tool, dependency-free, never writes `lib/`. Distinct from
     EP-T12..T33 (test-file liveness) and EP-T31 (gate wiring). AUDIT FIRST; RED->GREEN only on a genuine gap,
     never churn. No code touched. -->

- [x] EP-T34 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-T34 coverage-gate threshold-floor liveness guard + RED->GREEN tests`, analyze 0 / 45/45 targeted / full-suite count in tracking) — AUDIT FIRST: EP-T31 pins all four gates are WIRED, `kKvmThreshold == 0.75` is pinned for kvm/kvm-platform, but the `overallThreshold` (0.75) / `scopedThreshold` (0.80) default floors were UNPINNED — a silent lowering kept every guard GREEN. Genuine gap, no live divergence, not churn. Coverage-gate threshold-floor liveness guard: add a pure-Dart test that reads the four threshold
       constants in `tool/coverage_gate.dart` (overall / scoped redfish+power+sensors / kvm / kvm-platform) and
       fails closed if any falls below its documented floor (match the real constant names and current floor
       values), with a temp-root RED->GREEN proof (a lowered threshold -> violation, floor-respecting -> clean)
       and a real-repo invariant pinning the current values. AUDIT FIRST: if the thresholds are already pinned by
       an existing guard, record the audit and add nothing; RED->GREEN only on a genuine gap, never churn. Pure
       test/tool, dependency-free, never writes `lib/`; no WebView/protocol import, no production TLS weakening.
       Dept: rf-tooling
       Verify: `flutter test test/tool/coverage_gate_test.dart && flutter analyze` (0 issues),
               RED->GREEN proof only on a genuine gap.

<!-- rf-ideate split 2026-11-22 14:17 UTC: another machine-checkable slice of the still-open #009/#021
     epic's queue hygiene. EP-T13 pins exactly one valid `Dept:` + non-empty `Verify:`, EP-T24 pins that
     the verify command names repo-existing paths, and EP-T25 pins that any product `lib/**` path named
     falls inside that dept's owned set — but NONE pins that the item's `Dept:` matches the QUEUE FILE it
     is filed in (platform.md -> rf-platform, model.md -> rf-model, ui.md -> rf-ui, service.md ->
     rf-service, tooling.md -> rf-tooling). A mis-filed item (e.g. `Dept: rf-model` inside ui.md) passes
     all three guards yet is handed to the wrong worktree, breaking single-writer routing (MULTI_DEPT
     hard rule 1). Pure test/tool, dependency-free, never writes lib/. Distinct from EP-T13/T24/T25.
     AUDIT FIRST; RED->GREEN only on a genuine gap, never churn. No code touched. -->

<!-- rf-ideate split 2026-11-22 18:21 UTC: another machine-checkable slice of the still-open #009/#021
     epic's queue/tool hygiene. Guard-suite liveness (EP-T12..T29) pins that TEST files stay in
     `canonicalGuardFiles`, but nothing pins that the four COVERAGE gates enforced by `evaluateAllGates()`
     in `tool/coverage_gate.dart` (overall / scoped redfish+power+sensors / kvm / kvm-platform) are still
     invoked by both the CLI `main` and the CI verify workflow — dropping or omitting one gate (e.g. the
     kvm-platform gate) would silently remove a hard invariant while every test stays GREEN. Pure test/tool,
     dependency-free, never writes lib/. Distinct from EP-T12..T29 (test-file liveness). NOTE: EP-T30 is
     the pending liveness-registration follow-up recorded in automation-tracking; this is a separate gate.
     AUDIT FIRST; RED->GREEN only on a genuine gap, never churn. No code touched. -->

- [x] EP-T33 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T33 guard-suite liveness registration of the EP-U21 large-font cross-surface a11y guard + RED->GREEN tests`) — AUDIT FIRST: the EP-U21 guard `test/features/kvm/kvm_large_font_cross_surface_a11y_test.dart` (2 live `testWidgets` cases, 6 runtime assertions at 1.0/1.3/2.0 text scale on 320 px across both real cards + viewer) landed with EP-U21 and is live + reachable from verify.yml's whole-tree `flutter test --coverage`, but was absent from BOTH `canonicalGuardFiles` and every pinned epoch, so deleting / emptying / test-stripping it stayed GREEN — CONFIRMED registry gap, no live divergence, not churn. Registered it in `test/tool/guard_suite_liveness_test.dart`: +1 canonical path, pinned `epT33AddedGuards` epoch (length 1, pairwise-disjoint from all 25 earlier designations), inclusion in `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 containment/disjointness pin test +1 temp-root RED→GREEN proof (deleted / emptied / test-stripped → violation, intact → clean). Real-file RED: dropped only the canonical path (epoch designation kept) → exactly 3 named failures (`+51 -3`: EP-T33 pin, EP-T20 completeness, EP-T33 temp-root liveness), the other 51 GREEN; source restored byte-clean (SHA `a35f372617e803624e4a6f43683aea11d6ff3e93c8b4efecd40892c1c70c95c8` unchanged, 0 residue, 600-perm backup shredded) → 54/54 GREEN. Test/tool-only, dependency-free, empty `lib/` diff, no WebView/protocol import, no URL opened, no production TLS weakening.

- [x] EP-T32 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T32 guard-suite liveness registration of the EP-P16 port-authority agreement guard + RED->GREEN tests`, analyze 0 / 2283 passed / 1 skipped) — AUDIT FIRST: the EP-P16 guard `test/features/kvm/platform/port_authority_fail_closed_agreement_test.dart` (9 live cases) landed with EP-P16 and is live + reachable from verify.yml's whole-tree `flutter test --coverage`, but was absent from BOTH `canonicalGuardFiles` and every pinned epoch, so deleting / emptying / test-stripping it stayed GREEN — CONFIRMED registry gap, no live divergence, not churn. Registered it in `test/tool/guard_suite_liveness_test.dart`: +1 canonical path, pinned `epT32AddedGuards` epoch (length 1, pairwise-disjoint from all 24 earlier designations), inclusion in `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 containment/disjointness pin test +1 temp-root RED→GREEN proof (deleted / emptied / test-stripped → violation, intact → clean). Real-file RED: dropped only the canonical path (epoch designation kept) → exactly 3 named failures (`+49 -3`: EP-T32 pin, EP-T20 completeness, EP-T32 temp-root liveness), other 49 GREEN; restored byte-clean (SHA `a8899757…` unchanged, 0 residue, 600-perm backup shredded) → 52/52 GREEN. Test/tool-only, dependency-free, empty `lib/` diff, no WebView/protocol import, no URL opened, no production TLS weakening.

- [x] EP-T30 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T30 guard-suite liveness registration of the EP-M4 RemoteConsole-disable parity guard + RED->GREEN tests`) — AUDIT FIRST: the EP-M4 guard `test/features/kvm/kvm_remote_console_disable_parity_test.dart` (9 live tests) landed at 17:59 and is reachable from verify.yml's whole-tree `flutter test --coverage`, but was absent from BOTH `canonicalGuardFiles` and every pinned epoch, so deleting / emptying / test-stripping it stayed GREEN — a CONFIRMED "who guards the guards" gap, no live divergence, not churn. Extended `test/tool/guard_suite_liveness_test.dart`: +1 canonical path, a pinned `epT30AddedGuards` epoch (length 1, pairwise-disjoint from all 23 earlier designations) included in `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 containment/disjointness pin test +1 temp-root RED→GREEN proof (deleted / emptied / test-stripped → violation, intact → clean). Real-file RED: dropped only the canonical path while keeping the epoch designation → exactly 3 named failures (`+47 -3`: EP-T30 pin, EP-T20 completeness, EP-T30 temp-root liveness), other 47 GREEN; source restored byte-clean (SHA `4f4a7975dd006f87d50e03b4d5fbe9ec47a723df638c3afbde7508ed6be0ae10` unchanged, 0 residue, 600-perm backup shredded) → 50/50 GREEN. Test/tool-only, dependency-free, empty `lib/` diff, no WebView/protocol import, no production TLS weakening.

- [x] EP-T31 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T31 coverage-gate CLI/CI wiring liveness guard + RED->GREEN tests`, analyze 0 / 2262 passed / 1 skipped) — AUDIT FIRST: `coverage_gate_test.dart` already pinned that `evaluateAllGates()` returns the four named results, and `guard_suite_liveness_test.dart` pinned that verify.yml runs `flutter test --coverage`, but NOTHING pinned that verify.yml actually invokes `dart run tool/coverage_gate.dart` nor that the CLI `main` calls `evaluateAllGates` (it could silently call the two-gate `evaluateGates`) — dropping the CI step or narrowing main would stop enforcing the kvm-platform gate while every test stayed GREEN (CONFIRMED unguarded invariant, no live drift, not churn). Added a pure evaluator `evaluateCoverageGateWiring(cliSource, verifySource)` + 8 tests to `test/tool/coverage_gate_test.dart`: real-repo invariant (all four wired), +5 drift cases (dropped/renamed kvm-platform builder, renamed kvm builder, main→evaluateGates, CI gate step removed, CI `--coverage` removed), +1 temp-root RED→GREEN. Real-file RED: removed the coverage-gate step from the real `.github/workflows/verify.yml` under a 600-perm backup → exactly 1 named failure (`+36 -1`, diagnostic `CI: verify.yml no longer runs tool/coverage_gate.dart`), the other 36 stayed GREEN; restored byte-clean (SHA `7e97e3a3...` unchanged, 0 residue, backup shredded, `git diff --exit-code` clean) → 37/37 GREEN. Test/tool-only, dependency-free, empty `lib/` diff and empty CI-config diff, no WebView/protocol import, no production TLS weakening. Original item: pin that all four coverage gates enforced by
       `evaluateAllGates()` in `tool/coverage_gate.dart` (overall / scoped redfish+power+sensors / kvm /
       kvm-platform) remain invoked by both the CLI `main` and the CI verify workflow, failing closed with a
       concrete diagnostic if any gate is dropped, renamed, or silently omitted from the CI invocation (so
       a future edit could not quietly stop enforcing the kvm-platform gate while every test stays GREEN).
       AUDIT FIRST: guard-suite liveness (EP-T12..T29) covers TEST files, not the coverage-gate CLI/CI wiring
       — if a guard already asserts all four gates are wired into verify.yml and the CLI, record the audit
       and add nothing; RED->GREEN only on a genuine gap, never churn. Pure test/tool, dependency-free,
       never writes lib/.
       Dept: rf-tooling
       Verify: `flutter test test/tool/coverage_gate_test.dart && flutter analyze` (0 issues), with RED->GREEN
               proof (dropped/renamed/omitted gate -> violation; all four wired -> clean); writes limited to
               `test/tool/coverage_gate_test.dart` (+ `.github/workflows/**` only on a genuine gap);
               `git diff --exit-code -- pubspec.yaml pubspec.lock`; no lib/, no WebView/protocol import, no
               production TLS weakening.

- [x] EP-T29 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T29 guard-suite liveness registration of the RM-17 key-collision guard + RED->GREEN tests`, analyze 0 / 2241 passed / 1 skipped) — AUDIT FIRST: the RM-17 duplicate / case-variant console-block key-collision cross-factory agreement guard (`test/features/kvm/kvm_key_collision_agreement_test.dart`, 7 tests) landed with RM-17 and is live + reachable from verify.yml's whole-tree `flutter test --coverage`, but was absent from BOTH `canonicalGuardFiles` and every pinned epoch — deleting / emptying / test-stripping it stayed GREEN, a CONFIRMED "who guards the guards" gap (no live divergence, not churn). Registered it in `test/tool/guard_suite_liveness_test.dart`: +1 canonical path, pinned `epT29AddedGuards` epoch (length 1, pairwise-disjoint from all 22 earlier designations), inclusion in `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 containment/disjointness pin test +1 temp-root RED→GREEN proof (deleted / emptied / test-stripped → violation, intact → clean). Real-file RED: dropped only the canonical path (epoch designation kept) → exactly 3 named failures (`+45 -3`: EP-T29 pin, EP-T20 completeness, EP-T29 liveness), the other 45 GREEN; restored byte-clean (SHA `09fd936f…`, 0 residue, 600-perm backup shredded) → 48/48 GREEN. Test/tool-only, dependency-free, empty `lib/` diff, no WebView/protocol import, no URL opened, no production TLS weakening.
  Dept: rf-tooling
- [x] EP-T28 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T28 guard-suite liveness registration of the EP-U20 extreme-content guard + RED->GREEN tests`, analyze 0 / 2228 passed / 1 skipped) — AUDIT FIRST: the EP-U20 extreme-content cross-card rendered agreement guard (`test/features/kvm/kvm_card_extreme_content_agreement_test.dart`, 3 runtime tests at 320/800/1300 px via a width loop) is live and reachable from verify.yml's whole-tree `flutter test --coverage`, but was absent from BOTH `canonicalGuardFiles` and every pinned epoch — deleting / emptying / test-stripping it stayed GREEN, a CONFIRMED "who guards the guards" gap (no live divergence, not churn). Registered it in `test/tool/guard_suite_liveness_test.dart`: +1 canonical path, pinned `epT28AddedGuards` epoch (length 1, pairwise-disjoint from all 21 earlier designations), inclusion in `allDesignatedGuards` + EP-T20 completeness arithmetic, +1 containment/disjointness pin test +1 temp-root RED→GREEN proof (deleted / emptied / test-stripped → violation, intact → clean). Real-file RED: dropped only the canonical path (epoch designation kept) → exactly 3 named failures (`+42 -3`: EP-T28 pin, EP-T20 completeness, EP-T28 liveness), the other 43 GREEN; restored byte-clean (SHA `380d15ce…`, 0 residue, 600-perm backup shredded) → 46/46 GREEN. Test/tool-only, dependency-free, empty `lib/` diff, no WebView/protocol import, no URL opened, no production TLS weakening.
- [x] EP-T27 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T27 queue-item dept↔queue-filename routing guard + RED->GREEN tests`, analyze 0 / 2222 passed / 1 skipped) — Queue-item dept ↔ queue-filename routing guard: extend `test/tool/queue_item_schema_guard_test.dart`
       so that every unchecked item's `Dept:` value must equal the dept encoded in the queue file it lives
       in (`queues/platform.md`->`rf-platform`, `model.md`->`rf-model`, `ui.md`->`rf-ui`, `service.md`->`rf-service`,
       `tooling.md`->`rf-tooling`), failing closed with a concrete diagnostic naming the file, item ID and
       mismatched dept. Reuse the existing unchecked-item parser (including wrapped `Verify:` continuation
       lines); keep EP-T13's single-valid-dept and EP-T24/T25's target/ownership checks green. Temp-root
       RED->GREEN (mis-filed dept -> violation; matching dept -> clean) plus a real-repo invariant over
       `queues/*.md` (no real queue mutation — dept files are concurrently edited). AUDIT FIRST: if the
       guard already cross-checks dept against filename, record the audit and add nothing; RED->GREEN only
       on a genuine gap, never churn. Pure test/tool; no WebView/protocol import, no dependency, no production
       TLS weakening.
       Dept: rf-tooling
       Verify: `flutter test test/tool/queue_item_schema_guard_test.dart && flutter analyze` (0 issues), with
               RED->GREEN proof (mis-filed dept -> violation; matching dept -> clean); writes limited to
               `test/tool/queue_item_schema_guard_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
               no lib/, no WebView/protocol import, no production TLS weakening.
       LANDED: AUDIT FIRST confirmed a genuine gap — EP-T13 pins one valid `Dept:`, EP-T24 pins verify
       target existence, EP-T25 pins product-path ownership, but none compared `Dept:` to the queue FILE
       (all 28 unchecked items happened to comply, so the invariant is clean yet non-vacuous). Added
       `deptForQueueFile` (five files, injectable as `deptForFile`) + a `DEPT_QUEUE_MISMATCH` violation in
       `evaluateQueueSchema`, 8 new tests (6 pure, 1 temp-root RED→GREEN, 1 real-repo invariant with an
       injected foreign map proving non-vacuity). Corrected the EP-T24 temp-tree filename (`tooling.md`
       → `platform.md`) and the EP-T25 pure `check()` helper's file key so both route to their declared
       dept. Real-file RED: disabled the new check (`if (false && …)`) → exactly 4 EP-T27 liveness tests
       failed (`+35 -4`), all 35 others green; restored byte-clean (SHA `576a984e…`, 0 residue, 600-perm
       backup shredded) → 39/39 GREEN. Test/tool-only, dependency-free, no `lib/`, no WebView/protocol
       import, no URL opened, no production TLS weakening.

- [x] EP-T26 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T26 guard-suite liveness registration of three newly-landed agreement guards + RED->GREEN tests`, analyze 0 / 2213 passed / 1 skipped) — Closes a CONFIRMED "who guards the guards" gap: the three agreement guards that landed after SEC-010 (EP-P14 launch-plan scheme-spelling matrix, EP-U19 cross-surface chip + session-limit agreement, RM-16 hostile enablement-flag encoding agreement) were live + reachable from verify.yml's whole-tree `flutter test --coverage`, but absent from BOTH `canonicalGuardFiles` and every pinned epoch — deleting / emptying / test-stripping one of them stayed GREEN. Extended `test/tool/guard_suite_liveness_test.dart` with the three canonical paths, a pinned `epT26AddedGuards` epoch (length 3, pairwise disjoint from all 20 earlier designations), inclusion in `allDesignatedGuards` + EP-T20 completeness arithmetic, a containment/disjointness pin test and a temp-root RED→GREEN liveness test (each guard fails closed on deleted / emptied / test-stripped). Real-file RED: dropped one canonical path → exactly 3 named failures (`+41 -3`), restored byte-clean (SHA `7b63feb7…`, 0 residue, backup shredded) → 44/44 GREEN. Test/tool-only, dependency-free, no `lib/`, no WebView/protocol import, no URL opened, no production TLS weakening.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues); writes limited to `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no lib/, no WebView/protocol dependency, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 10:12 UTC: a fresh, machine-checkable slice of the still-open #009/#021
     epic's queue hygiene. EP-T13 pins a single valid `Dept:` + non-empty `Verify:`, EP-T24 pins that the
     verify command names repo-existing paths, but NEITHER pins the single-writer dimension (MULTI_DEPT
     hard rule #1): an item whose declared write-scope names a product `lib/**` path owned by a DIFFERENT
     dept still passes both guards, silently breaking path ownership. Pure test/tool, dependency-free,
     never writes lib/. Distinct from EP-T13/T24. AUDIT FIRST; RED->GREEN only on a genuine gap, no churn. -->

- [x] EP-T25 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T25 dept<->product-path ownership guard + RED->GREEN tests`, analyze 0 / full suite 2152 passed / 1 skipped) — Queue-schema guard extension enforcing MULTI_DEPT.md hard rule 1: every unchecked item's product `lib/**` write-scope / verify path must fall inside its `Dept:` owned set (rf-tooling/audit/ideate/check/gate own none; shared test/tool paths exempt). Added `deptOwnedProductPaths`, `pathIsOwned`, injectable `ownedPaths` param + `DEPT_PATH_OWNERSHIP` diagnostic; +10 tests (file 21→31). AUDIT: EP-T13/T24 pin dept shape + path existence only, no ownership check — genuine gap. Real-file RED: removed rf-ui's `lib/features/kvm/views` ownership from the real file -> exactly 5 failures (`+26 -5`), restored byte-clean (SHA `cc1fa9f4...`, 0 residue), 600-perm backup shredded -> 31/31 GREEN. Aligned two pre-existing EP-T24 lib-doc fixtures to the owning dept (rf-platform) so the legitimate EP-P1 shape stays GREEN. Original item:
      `test/tool/queue_item_schema_guard_test.dart` so that, for every unchecked item, any product `lib/**`
      path named in the item's declared write-scope / verify command must fall inside that item's `Dept:`
      owned-path set from MULTI_DEPT.md (rf-model -> `lib/features/kvm/models/**`, `lib/redfish/discovery/**`;
      rf-ui -> `lib/features/kvm/views/**`, `lib/features/systems/**`; rf-service -> `lib/features/kvm/kvm_service.dart`,
      controllers/providers, `lib/redfish/client/**`; rf-platform -> `lib/features/kvm/platform/**`;
      rf-tooling/rf-check/rf-gate/rf-audit/rf-ideate -> no product lib path). Shared test paths (`test/**`,
      `tool/**`) stay exempt. Fail closed with a concrete diagnostic naming the item and the foreign product
      path. Temp-root RED->GREEN (foreign product path -> violation; owned or test-only path -> clean) plus
      a real-repo invariant over `queues/*.md`. AUDIT FIRST: if the guard already enforces dept/product-path
      ownership, record the audit and add nothing; RED->GREEN only on a genuine gap, never churn. Pure
      test/tool, dependency-free, never writes lib/.
      Dept: rf-tooling
      Verify: `flutter test test/tool/queue_item_schema_guard_test.dart && flutter analyze` (0 issues), with
              RED->GREEN proof (foreign product path -> violation; owned/test-only -> clean); writes limited
              to `test/tool/queue_item_schema_guard_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no lib/, no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 06:09 UTC: a fresh, machine-checkable slice of the blocked #009/#021
     epic's queue-hygiene tooling. EP-T13 added `queue_item_schema_guard_test.dart` to fail closed on
     a missing/duplicate/out-of-set single dept field or an empty verify command, but a command that
     names a dangling / placeholder / typo'd test path still passes the schema, so a stale queue item
     can point builders at a non-existent suite. Pure test/tool, dependency-free, never writes lib/.
     Distinct from the still-open EP-T23 liveness-registry item — do NOT register the affordance guard
     here. AUDIT FIRST; RED→GREEN only on a genuine gap, never churn. No code touched. -->

- [x] EP-T24 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T24 queue-schema verify-command target guard + RED->GREEN tests`, analyze 0 / 2098 passed / 1 skipped) — Queue-schema guard extension to validate verify-command targets: extend
      `test/tool/queue_item_schema_guard_test.dart` so that, in addition to the existing single-dept /
      non-empty-command checks, every unchecked item's verify command must name at least one
      repo-existing `test/**` or `tool/**` path (no dangling / placeholder / typo'd suite), with a
      temp-root RED→GREEN (missing / placeholder / valid target) plus a real-repo invariant over the
      current `queues/*.md`. AUDIT FIRST: if the guard already validates command targets, record the
      audit and add nothing; no churn. Pure test/tool, dependency-free, never writes `lib/`.
      Dept: rf-tooling
      Verify: `flutter test test/tool/queue_item_schema_guard_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (placeholder/dangling command → violation; intact → clean);
              writes limited to `test/tool/queue_item_schema_guard_test.dart`;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no lib/, no production TLS weakening.
      **LANDED** 2026-11-22: AUDIT confirmed a genuine gap — the EP-T13 schema guard only proved a
      `Verify:` field was non-empty, so a dangling / placeholder / typo'd suite path passed. Added
      `extractVerifyTargets` (roots `test/`, `tool/`, `test_integration/`, `lib/`; glob-normalising)
      and an injectable `PathExists` predicate; `evaluateQueueSchema` now emits `VERIFY_NO_TARGET`
      / `VERIFY_DANGLING_TARGET`. Also taught the parser to capture wrapped `Verify:` continuation
      lines (EP-T2's `tool/**` lived on line 2) without re-breaking EP-T13's `EMPTY_VERIFY` RED case.
      `lib/` is accepted because human-gated EP-P1 legitimately uses `test -f lib/.../WEBVIEW_TLS_MATRIX.md`.
      Temp-root RED→GREEN (missing / placeholder / dangling lib → violation; valid / glob / one-valid-
      among-dangling → clean) + real-repo invariant with an injected all-paths-gone RED (no real
      queue-file mutation — tooling.md is concurrently edited by dept agents). 21/21 targeted GREEN,
      analyze 0, full 2098 passed / 1 skipped, deps unchanged, empty lib diff, no production TLS weakening.

<!-- rf-automation 2026-11-22 02:09 UTC: closes a CONFIRMED "who guards the guards" liveness gap in the blocked #009/#021 epic (same pattern as EP-T14..T20). EP-T20 pinned canonicalGuardFiles and added a registry-completeness invariant; RM-12 later added `kvm_external_client_from_manager_parity_test.dart` (5 live cases, reachable from verify.yml whole-tree `flutter test --coverage`) WITHOUT adding it to canonicalGuardFiles or any pinned epoch set, so deleting / emptying / test-stripping that safety guard stayed GREEN. Pure test/tool, dependency-free, never writes lib/; distinct from EP-T12/14/15/16/17/18/19/20. No product code touched. -->

- [x] EP-T21 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T21 guard-suite liveness — pin the RM-12 fromManager parity guard + RED->GREEN tests`, analyze 0 / 2046 passed / 1 skipped) — Guard-suite liveness: add the RM-12 `kvm_external_client_from_manager_parity_test.dart` safety guard (cross-factory classifier/label/openability parity through the real `fromManager` pipeline) to `canonicalGuardFiles` (41→42) under a pinned `epT21AddedGuards` set (length 1, disjoint from every earlier designation), include it in `allDesignatedGuards`, a pin test with pairwise-disjointness assertions and a temp-root RED→GREEN proof (missing/emptied/test-less → violation, intact → clean), keeping the EP-T20 registry-completeness invariant green. Confirmed gap, no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues), with RED→GREEN proof (dropped canonical entry → 3 failures; restored → 26/26); writes limited to `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no lib/, no production TLS change, no dependency, no WebView/protocol import.
      **LANDED** 2026-11-22: extended `canonicalGuardFiles` 41→42; added pinned `epT21AddedGuards` (length 1, disjoint from epT12Initial + epT14/15/16/17/18/19/20 + epU16/epM5/epS2), included it in `allDesignatedGuards` and the completeness arithmetic (+1 pin test), added a temp-root RED→GREEN. Real-file RED: dropped the canonical entry → 3 failures (`+23 -3`: EP-T21 pin + EP-T20 designated-guard + length), mutation reversed byte-clean (canonical 42, 0 residue), 600-perm backup shredded → 26/26 GREEN. Test/tool-only (empty lib diff), deps unchanged; emulator skipped.

<!-- rf-ideate split 2026-11-22 02:06 UTC: the tooling half of the #009/#021 split — keeps the
     "who guards the guards" liveness registry and the final-route fixtures in lockstep with the new
     RM-13 / EP-S9 / EP-P12 / EP-U17 guard slices. EP-T20 made the registry-completeness invariant
     fail closed on any canonical guard missing from a pinned epoch set; EP-T21 registered the RM-12
     guard. Any guard added by the new slices must likewise be registered under a fresh pinned epoch
     (disjoint from all earlier designations) or the completeness invariant will reject it. AUDIT
     FIRST: if the invariant already fails closed on an unregistered guard and the final-route
     fixtures still parse, record the audit and add nothing; test/tool-only, never writes lib/, no
     dependency, no TLS change. No code touched. -->

- [x] EP-T22 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T22 guard-suite liveness — register the asset / unattended / credential-leak safety guards + RED→GREEN tests`, analyze 0 / 2049 passed / 1 skipped) — Liveness + registration of cross-cutting safety guards: AUDIT found three live, CI-reachable guards named as part of the family by EP-T12 but never registered — `test/tool/asset_guard_test.dart` (15 cases), `test/tool/unattended_guard_test.dart` (16), `test/security/credential_leak_audit_test.dart` (3) — so deleting/emptying/test-stripping one stayed GREEN (verify.yml runs the TOOLS directly, not their test files). Registered all three in `canonicalGuardFiles` (42→45) under a pinned `epT22AddedGuards` epoch (length 3, disjoint from epT12Initial / epT14..epT21 / epU16 / epM5 / epS2), included in `allDesignatedGuards` + completeness arithmetic, +1 pin test +1 temp-root RED→GREEN covering missing/emptied/test-less for each. Genuine gap, no churn; final-route fixtures unchanged (still parse, still reachable). (Original item:) when the RM-13 / EP-S9 /
      EP-P12 / EP-U17 slices add guard files, register each in `canonicalGuardFiles` under a fresh
      pinned epoch set (disjoint from epT12Initial / epT14..epT21 / epU16 / epM5 / epS2) with length
      and pairwise-disjointness pin assertions, keeping the EP-T20 registry-completeness invariant
      green; and confirm the no-WebView final-route fixtures (EP-T1/EP-T4) still parse and remain
      reachable from verify.yml's whole-tree `flutter test --coverage`. AUDIT FIRST: if the
      completeness invariant already fails closed on an unregistered guard and the fixtures already
      parse, record the audit and add nothing; RED→GREEN by emptying/removing a temp-scan guard.
      Test/tool-only, no lib/, no dependency, no production TLS change.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (unregistered/emptied/test-less/CI-de-invoked → violation; intact →
              clean); writes limited to `test/tool/guard_suite_liveness_test.dart` + `test/fixtures/**`;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no lib/, no WebView/protocol import,
              no production TLS change.
      **LANDED** 2026-11-22: extended `canonicalGuardFiles` 42→45; added pinned `epT22AddedGuards` (length 3, disjoint from all twelve earlier designations), included in `allDesignatedGuards` and the completeness arithmetic (+1 pin test), added a temp-root RED→GREEN covering missing/emptied/test-less for each of the three guards. Real-file RED: dropped `test/security/credential_leak_audit_test.dart` from the canonical set → 3 failures (`+25 -3`: EP-T20 completeness + EP-T22 pin + EP-T22 RED test), named the dropped guard; mutation reversed byte-clean (canonical 45, 0 residue, SHA `a28eaa8e…` unchanged), 600-perm backup shredded → 28/28 GREEN. Test/tool-only (empty lib diff), deps unchanged; emulator skipped.

<!-- rf-ideate split 2026-11-21 22:03 UTC: a FRESH, machine-checkable "who guards the guards"
     liveness gap in the blocked #009/#021 epic, CONFIRMED by direct audit (not speculative).
     EP-T19 pinned canonicalGuardFiles to 34 and added epT19AddedGuards; since then EP-M6 added
     `kvm_oem_uri_shadow_agreement_test.dart` DIRECTLY to canonicalGuardFiles with NO pinned
     `ep*AddedGuards` set, and three genuine safety guards — `kvm_lifecycle_parity_test.dart`
     (KVM<->sensors backgrounded-state parity), `kvm_notice_surface_audit_test.dart` (RU-2 merged-
     Semantics notice-surface audit) and `test/features/kvm/platform/webview_policy_test.dart`
     (WebView policy invariants) — are live and reachable from verify.yml's whole-tree
     `flutter test --coverage` yet absent from the canonical set entirely (the liveness test itself
     is self-referential and stays excluded). So dropping / emptying / test-stripping / CI-de-invoking
     any of these stays GREEN. Pure test/tool, dependency-free, never writes lib/; distinct from
     EP-T12/14/15/16/17/18/19. Human-gated WebView/TLS rendering stays gated and is NOT re-split.
     No code touched. -->

- [x] EP-T20 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-T20 guard-suite liveness registry completeness + RED->GREEN tests`, analyze 0 / 1989 passed / 1 skipped) — Guard-suite liveness: pin the post-EP-T19 safety guards and add a canonical-registry
      completeness invariant so no designated guard can be silently dropped. Concretely: (a) add a
      pinned `epT20AddedGuards ⊆ canonicalGuardFiles` set (disjoint from epT14/15/16/17/18/19) covering
      the guards added/live since EP-T19 — `kvm_oem_uri_shadow_agreement_test.dart` (EP-M6) plus the
      audited safety guards `kvm_lifecycle_parity_test.dart`, `kvm_notice_surface_audit_test.dart` and
      `test/features/kvm/platform/webview_policy_test.dart` if each qualifies as a canonical safety
      guard — with a pinned length, pairwise-disjointness assertions and a pin test; and (b) add a
      registry-level invariant that fails closed if any designated canonical guard is removed from
      `canonicalGuardFiles`, so a guard added directly in a future run cannot sit unpinned. Verify
      each added file has live `test(`/`testWidgets(` cases and is reachable from the whole-tree
      `flutter test --coverage` before adding; RED→GREEN by emptying / removing a temp-scan guard.
      Confirmed gap, no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (missing/emptied/test-less/CI-de-invoked → violation; intact → clean);
              writes limited to `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no lib/, no production TLS change, no dependency, no WebView/protocol import.
      **LANDED** 2026-11-21: extended `canonicalGuardFiles` 34→37 with `kvm_lifecycle_parity_test.dart`, `kvm_notice_surface_audit_test.dart` and `platform/webview_policy_test.dart` (live cases 4/7/17, reachable from verify.yml whole-tree coverage); added pinned `epT20AddedGuards` (length 4, incl. the EP-M6 `kvm_oem_uri_shadow_agreement_test.dart`, disjoint from epT12Initial/epT14/15/16/17/18/19), pinned `epT12InitialGuards` (8), `allDesignatedGuards` union, pairwise-disjointness + pin test, and a NEW registry-completeness invariant (canonical set == union of designated guards in BOTH directions — a guard added directly with no pinned designation now fails closed) + temp-root RED→GREEN. Real-file RED: dropped `webview_policy_test.dart` from canonicalGuardFiles → exactly the 2 EP-T20 tests failed (`+19 -2`, both named the guard); restored byte-clean (SHA `db7bae1a…`, empty lib diff), 600-perm backups shredded → 21/21 GREEN. Test/tool-only (empty lib diff), deps unchanged; emulator skipped.

<!-- rf-automation 2026-11-21 20:57 UTC: closes a CONFIRMED liveness gap in the "who guards the
     guards" suite of the blocked #009/#021 epic (same pattern as EP-T14/T15/T16/T17/T18). EP-T18 pinned
     canonicalGuardFiles to 31 (8 EP-T12 + 7 EP-T14 + 6 EP-T15 + 3 EP-T16 + 4 EP-T17 + 3 EP-T18), but THREE
     guard files landed AFTER EP-T18 and are not in that set, so deleting / emptying / test-stripping /
     CI-de-invoking any one of them would stay GREEN: `kvm_capability_security_tristate_agreement_test.dart`
     (RM-10, 4 cases), `test/features/kvm/platform/navigation_launch_route_agreement_test.dart` (EP-P11, 7 cases)
     and `kvm_three_surface_launch_target_agreement_test.dart` (EP-U15, 8 cases). All three are present with
     live `test(`/`testWidgets(` cases and reachable from verify.yml's whole-tree `flutter test --coverage`.
     Pure test/tool, dependency-free, never writes `lib/`; distinct from EP-T12/14/15/16/17/18. No code touched. -->

- [x] EP-T19 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-T19 guard-suite liveness extension for the post-EP-T18 safety guards`, analyze 0 / 1975 passed / 1 skipped) — add the three guard files
      that landed after EP-T18 — `kvm_capability_security_tristate_agreement_test.dart`,
      `test/features/kvm/platform/navigation_launch_route_agreement_test.dart` and
      `kvm_three_surface_launch_target_agreement_test.dart` — to `canonicalGuardFiles` in
      `test/tool/guard_suite_liveness_test.dart` so each is liveness-checked (missing / emptied /
      stripped-of-tests / unreachable ⇒ violation), keeping the real-repo invariant green. Added a pinned
      `epT19AddedGuards ⊆ canonicalGuardFiles` set (length 3) disjoint from `epT14AddedGuards` /
      `epT15AddedGuards` / `epT16AddedGuards` / `epT17AddedGuards` / `epT18AddedGuards`, plus
      pairwise-disjointness pin assertions, a pin test and a temp-root RED→GREEN. Confirmed gap, no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues), with
              RED→GREEN proof (missing/emptied/test-less → violation; intact → clean); writes limited to
              `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no `lib/`, no production TLS change.
      **LANDED** 2026-11-21: extended `canonicalGuardFiles` 31→34 with the three post-EP-T18 safety guards
      (live cases 4/7/8, reachable from verify.yml whole-tree `flutter test --coverage`); added pinned
      `epT19AddedGuards` (length 3) ⊆ canonicalGuardFiles disjoint from EP-T14/15/16/17/18 + pairwise-disjointness
      pin assertions + temp-root RED→GREEN. Real-file RED: dropped `kvm_three_surface_launch_target_agreement_test.dart`
      from canonicalGuardFiles → EP-T19 pin failed (`+17 -1`, named the dropped guard); restored byte-clean
      (SHA `38e7c477…` unchanged), 600-perm backup shredded → 18/18 GREEN. Test/tool-only (empty lib diff), deps
      unchanged; analyze 0 / 1975 passed / 1 skipped (baseline 1973 +2); issues validate OK; diff --check clean;
      emulator skipped (test/tool-only, <7 days since last green 85/85); no WebView/protocol import, no URL
      opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-21 17:59 UTC: closes a CONFIRMED liveness gap in the "who guards the
     guards" suite of the blocked #009/#021 epic (same pattern as EP-T14/T15/T16/T17). EP-T17 pinned
     canonicalGuardFiles to 28 (24 + 4 post-EP-T16 guards), but THREE guard files landed AFTER EP-T17
     and are not in that set, so deleting / emptying / test-stripping / CI-de-invoking any one of them
     would stay GREEN: `kvm_service_capability_primary_agreement_test.dart` (EP-S6, 3 tests, 18:17),
     `kvm_viewer_uri_surface_agreement_test.dart` (EP-U14, 16 tests, 17:35) and
     `kvm_capability_primary_uri_agreement_test.dart` (EP-S7, 6 tests, 18:52). All three are present with
     live `test(`/`testWidgets(` cases and reachable from verify.yml's whole-tree `flutter test --coverage`.
     Pure test/tool, dependency-free, never writes `lib/`; distinct from EP-T12/14/15/16/17. No code
     touched. -->

- [x] EP-T18 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-T18 guard-suite liveness extension for the post-EP-T17 safety guards`, analyze 0 / 1952 passed / 1 skipped) — add the three guard files
      that landed after EP-T17 — `kvm_service_capability_primary_agreement_test.dart`,
      `kvm_viewer_uri_surface_agreement_test.dart` and `kvm_capability_primary_uri_agreement_test.dart` —
      to `canonicalGuardFiles` in `test/tool/guard_suite_liveness_test.dart` so each is liveness-checked
      (missing / emptied / stripped-of-tests / unreachable ⇒ violation), keeping the real-repo invariant
      green. Add a pinned `epT18AddedGuards ⊆ canonicalGuardFiles` set disjoint from `epT14AddedGuards`
      / `epT15AddedGuards` / `epT16AddedGuards` / `epT17AddedGuards`, plus its pairwise-disjointness pin
      assertions, and update the pinned count. Verify each added file has live `test(` / `testWidgets(`
      cases and is reachable from the whole-tree `flutter test --coverage` before adding; RED→GREEN proof
      by emptying a temp-scan guard. Confirmed gap, no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues), with
              RED→GREEN proof (missing/emptied/test-less → violation; intact → clean); writes limited to
              `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no `lib/`, no production TLS change.

<!-- rf-ideate split 2026-11-21 14:10 UTC: closes a CONFIRMED liveness gap in the "who guards the
     guards" suite of the blocked #009/#021 epic (same pattern as EP-T14/T15/T16). EP-T16 pinned
     canonicalGuardFiles to 24 (8 EP-T12 + 7 EP-T14 + 6 EP-T15 + 3 EP-T16), but FOUR new guard
     files landed AFTER EP-T16 and are not in that set, so deleting / emptying / test-stripping /
     CI-de-invoking any one of them would stay GREEN: `kvm_service_lookup_key_test.dart` (RS-9,
     3 tests, 10:52), `kvm_oem_depth_bound_agreement_test.dart` (RM-9, 21 tests, 12:18),
     `kvm_view_state_agreement_test.dart` (EP-U13, 13 tests, 13:23) and
     `validation_evidence_checklist_guard_test.dart` (EP-P4/RP-1, 6 tests, merged 13:49). All four
     are present with live `test(`/`testWidgets(` cases and reachable from verify.yml's whole-tree
     `flutter test --coverage`. Pure test/tool, dependency-free, never writes `lib/`; distinct from
     EP-T12/14/15/16. No code touched. -->

- [x] EP-T17 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-T17 guard-suite liveness extension for the post-EP-T16 safety guards + RED->GREEN tests`, analyze 0 / 1910 passed / 1 skipped) — add the four
      guard files that landed after EP-T16 — `kvm_service_lookup_key_test.dart`,
      `kvm_oem_depth_bound_agreement_test.dart`, `kvm_view_state_agreement_test.dart` and
      `test/features/kvm/platform/validation_evidence_checklist_guard_test.dart` — to
      `canonicalGuardFiles` in `test/tool/guard_suite_liveness_test.dart` so each is liveness-checked
      (missing / emptied / stripped-of-tests / unreachable ⇒ violation), keeping the real-repo
      invariant green. Add a pinned `epT17AddedGuards ⊆ canonicalGuardFiles` set disjoint from
      `epT14AddedGuards` / `epT15AddedGuards` / `epT16AddedGuards` plus its pairwise-disjointness
      pin assertions, and update any pinned count. Verify each added file has live `test(` /
      `testWidgets(` cases and is reachable from the whole-tree `flutter test --coverage` before
      adding it; RED→GREEN proof by emptying a temp-scan guard. Confirmed gap, no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (missing/emptied/test-less → violation; intact → clean); writes
              limited to `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no `lib/`, no production TLS change.
      **LANDED** 2026-11-21: extended `canonicalGuardFiles` 24→28 with the four post-EP-T16 safety guards (`kvm_service_lookup_key_test.dart`, `kvm_oem_depth_bound_agreement_test.dart`, `kvm_view_state_agreement_test.dart`, `test/features/kvm/platform/validation_evidence_checklist_guard_test.dart`, live cases 3/6/5/6, reachable from verify.yml whole-tree `flutter test --coverage`); added pinned `epT17AddedGuards` (length 4) ⊆ canonicalGuardFiles disjoint from EP-T14/EP-T15/EP-T16 + pairwise-disjointness pin assertions + temp-root RED→GREEN. Genuine confirmed liveness gap, not churn. Real-file RED proof: dropped `validation_evidence_checklist_guard_test.dart` from `canonicalGuardFiles` → the EP-T17 pin test failed (`+12 -1`, named the dropped guard); restored byte-clean (SHA `ba73c965…` unchanged), 600-perm backup shredded → 14/14 GREEN. Test/tool-only (empty lib diff), deps unchanged; analyze 0 / 1910 passed / 1 skipped (baseline 1908 +2); issues validate OK; diff --check clean; emulator skipped (test/tool-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-21 09:53 UTC: closes a confirmed liveness gap in the "who guards the
     guards" suite of the blocked #009/#021 epic. EP-T14 enumerated 7 safety guards, EP-T15 extended
     to 15 with the six behavioral guards that existed at 06:07, but THREE behavioral guard files
     landed AFTER EP-T15 (`kvm_clipboard_cross_surface_agreement_test.dart`,
     `kvm_view_reload_indicator_test.dart`, `kvm_view_stale_error_banner_test.dart`) and are not in
     `canonicalGuardFiles`, so deleting / emptying / test-stripping / CI-de-invoking one of them would
     stay GREEN. Confirmed at split time: each file has live `test(`/`testWidgets(` cases (3/2/3) and
     is reachable from verify.yml's whole-tree `flutter test --coverage`. Pure test/tool,
     dependency-free, never writes `lib/`; distinct from EP-T12/14/15. No code touched. -->

- [x] EP-T16 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-T16 guard-suite liveness extension for the post-EP-T15 regression guards + RED->GREEN tests`) — add the three
      guard files that landed after EP-T15 — `kvm_clipboard_cross_surface_agreement_test.dart`,
      `kvm_view_reload_indicator_test.dart`, `kvm_view_stale_error_banner_test.dart` — to
      `canonicalGuardFiles` in `test/tool/guard_suite_liveness_test.dart` so each is liveness-checked
      (missing / emptied / stripped-of-tests / unreachable ⇒ violation), keeping the real-repo
      invariant green. Add a pinned `epT16AddedGuards ⊆ canonicalGuardFiles` set (disjoint from
      `epT14AddedGuards` and `epT15AddedGuards`) plus its pin assertions, and update any pinned count.
      RED→GREEN proof by emptying a temp-scan guard; no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (missing/emptied/test-less → violation; intact → clean); writes
              limited to `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no `lib/`, no production TLS change.
      **LANDED** 2026-11-21: extended `canonicalGuardFiles` 21→24 with the three post-EP-T15 widget guards (`kvm_clipboard_cross_surface_agreement_test.dart`, `kvm_view_reload_indicator_test.dart`, `kvm_view_stale_error_banner_test.dart`, live cases 3/2/3, reachable from verify.yml whole-tree `flutter test --coverage`); added pinned `epT16AddedGuards ⊆ canonicalGuardFiles` disjoint from EP-T14/EP-T15 + pairwise-disjointness pin assertions + temp-root RED→GREEN. Genuine confirmed liveness gap, not churn. Real-file RED proof: dropped `kvm_view_stale_error_banner_test.dart` from `canonicalGuardFiles` → both new EP-T16 tests failed (`+11 -1`, pin test named the dropped guard); restored byte-clean (SHA `c66f8ebc…`), 600-perm backups shredded → 12/12 GREEN. Test/tool-only (empty lib diff), deps unchanged; analyze 0 / 1863 passed / 1 skipped (baseline 1861 +2); issues validate OK; diff --check clean; emulator skipped (test/tool-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. WIP was swept into `rf-gate-premerge-1795255738` by a concurrent rf-gate merge and recovered via `git stash apply` (stash left untouched).

<!-- rf-ideate split 2026-11-21 05:49 UTC: closes a confirmed liveness gap in the "who guards the
     guards" suite of the blocked #009/#021 epic. EP-T14 extended `canonicalGuardFiles` to the seven
     safety guards that existed at 01:55, but six behavioral regression guards landed AFTER it and are
     not liveness-checked, so a future deletion / emptying / test-stripping / CI-de-invocation of one of
     them would stay GREEN. Pure test/tool, dependency-free, never writes `lib/`; distinct from EP-T12
     (initial set) and EP-T14 (01:55 set). No code touched. -->

- [x] EP-T15 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-T15 guard-suite liveness extension for the post-EP-T14 regression guards + RED→GREEN tests`, analyze 0 / 1808 passed / 1 skipped) — extended `canonicalGuardFiles` in `test/tool/guard_suite_liveness_test.dart` from 15 to 21 with the six post-EP-T14 behavioral regression guards (`kvm_capability_kvmip_fallback_test.dart`, `kvm_manager_source_precedence_test.dart`, `kvm_oem_multi_vendor_enablement_test.dart`, `kvm_controller_dispose_guard_test.dart`, `kvm_service_manager_identity_test.dart`, `kvm_card_cross_surface_agreement_test.dart`) — each verified present with live `test(` / `testWidgets(` cases (9/13/5/3/2/2) and reachable from verify.yml's whole-tree `flutter test --coverage`; added a pinned `epT15AddedGuards ⊆ canonicalGuardFiles` set (disjoint from `epT14AddedGuards`) plus a temp-root RED→GREEN proving a newly-added guard is liveness-checked (missing/emptied/test-less → violation, intact → clean). Genuine confirmed liveness gap, not churn: without the extension, deleting/emptying/test-stripping one of those six guards would stay GREEN. Real-file RED proof: temporarily dropped `kvm_capability_kvmip_fallback_test.dart` from `canonicalGuardFiles` → both new EP-T15 tests failed (`+8 -2`, naming the dropped guard); restored byte-clean (SHA `33176741…` unchanged), 600-perm backup shredded → 10/10 GREEN. Test/tool-only, no `lib/`, dependency, wire/fixture, no WebView/protocol import, no URL opened, no production TLS weakening. Original item: add the established
      guards that landed after EP-T14 — `kvm_capability_kvmip_fallback_test.dart`,
      `kvm_manager_source_precedence_test.dart`, `kvm_oem_multi_vendor_enablement_test.dart`,
      `kvm_controller_dispose_guard_test.dart`, `kvm_service_manager_identity_test.dart`,
      `kvm_card_cross_surface_agreement_test.dart` — to `canonicalGuardFiles` in
      `test/tool/guard_suite_liveness_test.dart` so each is liveness-checked (missing / emptied /
      stripped-of-tests / unreachable ⇒ violation), keeping the real-repo invariant green; update any
      pinned count assertion to match. Verify each added file has live `test(` / `testWidgets(` cases and
      is reachable from the whole-tree `flutter test --coverage` before adding; RED→GREEN proof by
      emptying a temp-scan guard. No churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues), with
              RED→GREEN proof (missing/emptied/test-less → violation; intact → clean); writes limited to
              `test/tool/guard_suite_liveness_test.dart`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no `lib/`, no production TLS change.

<!-- rf-ideate split 2026-11-21 01:45 UTC: closes a confirmed liveness gap in the "who guards the
     guards" suite of the blocked #009/#021 epic. `test/tool/guard_suite_liveness_test.dart` (EP-T12)
     enumerates exactly 8 canonical guard files, but several safety guards landed AFTER EP-T12 and
     are NOT in that set, so a future deletion / emptying / test-stripping / CI-de-invocation of one
     of them would stay GREEN. Pure test/tool, dependency-free, never writes `lib/`; distinct from
     EP-T12 (initial liveness set) and EP-T13 (queue-item schema). No code touched. -->

- [x] EP-T14 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-T14 guard-suite liveness extension + RED→GREEN tests`, analyze 0 / 1746 passed / 1 skipped) — Extend the guard-suite liveness canonical set to the safety guards added after EP-T12:
      add the established new guards — `test/tool/queue_item_schema_guard_test.dart`,
      `test/features/kvm/platform/production_optin_construction_guard_test.dart`,
      `test/features/kvm/platform/cross_layer_authority_agreement_test.dart`,
      `test/features/kvm/kvm_viewer_flagoff_false_claim_guard_test.dart`,
      `test/features/kvm/kvm_viewer_disclosure_contract_test.dart`,
      `test/features/kvm/kvm_providers_test.dart`,
      `test/features/kvm/kvm_session_audit_invariants_test.dart` — to `canonicalGuardFiles` so each is
      liveness-checked (missing / emptied / stripped-of-tests / unreachable ⇒ violation), keeping the
      real-repo invariant green. Verify each added file has live `test(`/`testWidgets(` cases and is
      reachable from the whole-tree `flutter test --coverage` run before adding it; RED→GREEN proof by
      emptying a temp-scan guard, no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (missing/emptied/test-less → violation; intact → clean); writes
              limited to `test/tool/guard_suite_liveness_test.dart`;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no `lib/`, no production TLS change.

<!-- rf-ideate split 2026-11-20 17:10 UTC: makes the dept-split contract itself machine-checkable —
     MULTI_DEPT.md hard rule 4 requires every issue/queue item to carry `Dept:` (single dept) and
     `Verify:` (exact commands), but nothing fails closed when a future `queues/<dept>.md` item drops
     one. Pure test/tool guard, dependency-free, never writes `lib/`; distinct from EP-T11 (URI-parse
     single-source) and EP-T12 (guard-suite liveness). No code touched. -->

- [x] EP-T13 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T13 queue-item Dept/Verify schema guard + RED→GREEN tests`, analyze 0 / 1712 passed / 1 skipped) — Queue-item Dept/Verify schema guard: add a pure-Dart, dependency-free guard under
      `test/tool/` that parses every unchecked `- [ ]` item in `queues/*.md` and fails closed if an
      item is missing a `Dept:` field, has more than one `Dept:`, uses a dept outside the fixed
      MULTI_DEPT set (`rf-model`/`rf-ui`/`rf-service`/`rf-tooling`/`rf-platform`/`rf-audit`/`rf-ideate`/
      `rf-check`/`rf-gate`), or has an empty/missing `Verify:` command. RED→GREEN proof by planting a
      malformed item in a temp queue tree (bad/missing Dept or Verify → violation; valid → clean)
      plus a real-queue invariant. No live-BMC, no dependency, no `lib/` change, production TLS
      untouched; wire into CI only if the repo guard convention already covers `test/tool/` (no
      second full-suite invocation).
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), RED→GREEN guard proof
              (malformed → violation; valid → clean); writes limited to `tool/**`, `test/tool/**`,
              `.github/workflows/**`; never `lib/`, no dependency bump.

<!-- rf-ideate split 2026-11-20 13:04 UTC: splits the guard-liveness remainder of the blocked/epic
      #009/#021 closeout into one unblocked, test-only dept slice. The repo now relies on a family of
      safety guard tests (RU-2/EP-T9 copy, EP-T11 URI-parse, EP-T8 source-display, EP-P5 imports,
      EP-P6/P7/P8 policy/doc, EP-T7 doctor, LA-1 assets, EP-T6 unattended) but nothing fails closed if
      one of those guard files is later deleted, emptied or silently de-invoked from CI. Pure test/tool
      work, dependency-free, never writes `lib/`; distinct from EP-T9/T11/T8/EP-P5. No code touched. -->

- [x] EP-T12 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T12 KVM invariant-guard suite liveness guard + RED→GREEN tests`, analyze 0 / 1630 passed / 1 skipped) — KVM invariant-guard suite liveness/completeness guard for #009/#021: add a pure-Dart
      guard under `test/tool/` that enumerates the established KVM safety guard test files (at least:
      `notice_single_source_guard_test.dart`, `launch_status_single_source_guard_test.dart`,
      `uri_parse_single_source_guard_test.dart`, `manager_source_display_guard_test.dart`,
      `product_import_policy_test.dart`, `production_route_invariant_test.dart`,
      `human_gate_doc_guard_test.dart`, `decision_doc_route_guard_test.dart`) and fails closed if any is
      missing, empty of test cases, or no longer reachable by the standard `flutter test --coverage`
      run / `.github/workflows/verify.yml` — so a future edit cannot silently delete or disable a
      guard. RED→GREEN proof by removing/emptying one guard in a temp scan root (violation + nonzero
      exit; intact suite → clean). No live-BMC, no dependency, no `lib/` change, production TLS
      untouched; do not add a second full-suite CI invocation.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), RED→GREEN guard proof (empty/
              missing guard → violation; intact → clean); writes limited to `tool/**`, `test/tool/**`,
              `.github/workflows/**`; never `lib/`, no dependency bump.

<!-- rf-ideate split 2026-11-20 09:00 UTC: splits the still-open cross-surface classifier-parity
     remainder of #009/#021 into a machine-checkable guard. EP-M1/M2 fixed degenerate hosts once and
     RM-5 pinned agreement, but nothing mechanically prevents a future product file from reintroducing
     a raw `Uri.parse`/`Uri.tryParse` on a BMC-supplied console/source value outside the shared
     fail-closed helpers, bypassing every control-safe gate. Pure test-only guard, dependency-free,
     never writes `lib/`; distinct from EP-P5 (import policy) and the copy-string single-source guards. -->

- [x] EP-T11 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T11 fail-closed URI-parse single-source guard + RED→GREEN tests`, analyze 0 / 1528 passed / 1 skipped) — Fail-closed URI-parse single-source guard: add a pure-Dart, comment/string-aware guard
      under `test/tool/` that scans product `lib/features/kvm/**.dart` and fails closed if any file
      OUTSIDE the designated shared helper files (`platform/launch_plan.dart`, `models/kvm_oem_uri.dart`,
      `models/kvm_manager_source.dart`, `models/kvm_session_limit.dart`, `platform/webview_policy.dart`)
      calls `Uri.parse` / `Uri.tryParse` on a BMC-supplied console/source value, or defines a private
      duplicate of the shared control-safe / classifier helpers — so a future ad-hoc parse cannot
      bypass the fail-closed gates. RED→GREEN proof by planting a raw parse in a temp product-style
      file (raw → violation + nonzero exit; shared-helper call → clean). No live-BMC, no dependency,
      no `lib/` change, production TLS untouched; wire into `.github/workflows/verify.yml` only if the
      repo guard convention already covers `test/tool/` (no second full-suite invocation).
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), RED→GREEN guard proof (raw parse
              → violation; gated call → clean); writes limited to `tool/**`, `test/tool/**`,
              `.github/workflows/**`; never `lib/`, no dependency bump.

<!-- rf-ideate split 2026-11-20 04:56 UTC: closes out the FUTUREWORK-named "EP-T4 fixture/CI guard"
     next slice, re-scoped to be unblocked. EP-T4's webview/url_launcher dependency-guard half is
     already covered by EP-P5 + EP-T6 guards, so this splits only the genuine remaining piece — a
     canonical OpenBMC console fixture + fixture-drive tests — so selection/guidance tests stop
     relying on ad-hoc in-temp mockups. Pure test/fixture work, no lib/, no dependency, no network. -->

- [x] EP-T10 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T10 canonical OpenBMC console fixture + fixture-drive tests`, analyze 0 / 1492 passed / 1 skipped) — Canonical OpenBMC console fixture + fixture-drive tests (closeout of the FUTUREWORK
      "EP-T4 fixture/CI guard" slice): add one repo fixture under `test/fixtures/redfish/` — an
      OpenBMC `Managers/{id}` payload with `GraphicalConsole` (HTML5 over HTTPS, `ServiceEnabled:
      true`, `ConnectTypesSupported: [KVMIP, HTML5]`, `MaxConcurrentSessions`), `Oem.OpenBMC.KVM.Uri`
      and a `RemoteConsole` — plus pure fixture-parse/drive tests asserting it is valid Redfish and
      yields the expected `KvmConsole` / `KvmCapability` selection and launch guidance through the
      shared factories. Do NOT re-add the dependency guard (EP-P5/EP-T6 already cover it). No live
      BMC, no dependency, no `lib/` change, production TLS untouched; keep all existing mockups green.
      Dept: rf-tooling
      Verify: `flutter test test/features/kvm/ && flutter analyze` (0 issues), fixture-parse tests
              green + RED→GREEN proof (temporarily corrupt the fixture shape → parse fails); writes
              limited to `test/fixtures/**`, `test/**`, `.github/workflows/**`; never `lib/`, no
              dependency bump.

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the tooling/guard half of the remaining
     cross-surface "control-safe manager source" portion of the open #009/#021 epic, mirroring
     EP-P5 / EP-T6 / LA-1. A machine-checkable invariant so no surface can reintroduce the raw
     `@odata.id` clipboard/UI-injection class CB-1 closed on the card. Pure test-only guard,
     dependency-free, never writes `lib/`. -->

- [x] EP-T8 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T8 control-safe manager-source display guard + RED→GREEN tests`; analyze 0 / 1433 passed / 1 skipped) — Control-safe manager-source display guard (closeout of the CB-1 class across all
      surfaces): added `test/tool/manager_source_display_guard_test.dart` (10 tests), a pure-Dart guard
      that scans every product `lib/**.dart` that scans product `lib/**.dart`
      (comment/string/filename aware, like `product_import_policy_test.dart`) and fails closed if
      a widget/controller interpolates a BMC-supplied `sourceManagerUri` (or an `@odata.id`-derived
      source value) directly into a user-facing `Text` / `SelectableText` / `Semantics` label or a
      `Clipboard.setData` payload without routing through the shared control-safe gate
      (`isControlSafeConsoleUri` / a `safeManagerUri` getter / `clipboardTargetUri`). It must NOT flag
      a value already routed through those gates, nor the test-only fixtures that pass literal safe
      sources. RED→GREEN proof by temporarily planting a raw source interpolation into a temp
      product-style file under a temp scan root. No live-BMC, no dependency, no `lib/` change,
      production TLS untouched; wire into `.github/workflows/verify.yml` only if the repo guard
      convention already covers `test/tool/` (do not add a second full-suite invocation).
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with RED→GREEN guard tests
              (raw interpolation → violation + nonzero exit; gated value → clean); writes limited to
              `tool/**`, `test/tool/**`, `.github/workflows/**`; never `lib/`, no dependency bump.

<!-- rf-ideate split 2026-11-19 20:47 UTC: splits the last un-split FUTUREWORK "[!] Environment
     quota blocking verification (2026-11-08)" blocker — its harness-robustness portion (the
     quota itself was transient; baselines are green). Mirrors EP-T6 / LA-1: pure tooling, no
     lib/, no dependency, no product TLS change. -->

- [x] EP-T7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T7 emulator prerequisite doctor + RED→GREEN tests`) — Emulator prerequisite doctor (closeout of FUTUREWORK "[!] Environment quota blocking
      verification"): add a pure-Dart `tool/emulator_doctor.dart` (CLI + tests) that fails closed
      with a precise, actionable diagnostic when a required prerequisite is absent — `docker`,
      `curl`, `jq`, `redfishtool` on PATH, and the pinned local DMTF mockup fixture
      `test/fixtures/redfish/dmtf_mockup` (never a hardcoded container-internal DSP2043 path) —
      plus a `--check` mode that validates prerequisites without starting containers or any
      network/credential use. Document that `tool/emulator/run_tests.sh` remains the standard
      suite and `testing/run_emulator_harness.sh` is optional. Do not enable live-BMC, do not
      add a dependency, never weaken production TLS.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with RED→GREEN doctor tests
              (temp-PATH missing prerequisite → violation + nonzero exit; all-present → zero exit);
              `dart run tool/emulator_doctor.dart --check` names each missing prerequisite (exit 0
              only when all present — `redfishtool` is currently absent, so an actionable nonzero
              report is the correct result here); writes limited to `tool/**`, `test/tool/**`,
              `DEVELOPMENT.md`; never `lib/`.

<!-- rf-ideate split 2026-11-19 16:43 UTC (main repo): slices the one remaining un-split
     FUTUREWORK "Blocked / needs a human" item — "[!] Large spec/binary assets — if over the
     download budget, ask a human before committing; store links and hashes meanwhile" —
     into an unblocked, dependency-free tooling guard. Mirrors the earlier Live-BMC → EP-T6
     and WebView → EP-P4 splits. The other blocked items (Live BMC integration, KVM
     webview/native console) are already fully split into existing EP-* items; no code touched. -->

- [x] LA-1 Large/binary asset policy + guard (LANDED 2026-11-19, run `auto: FEATURE — LA-1 asset guard`). (closeout of FUTUREWORK "[!] Large spec/binary
      assets"): add a repo asset-reference manifest listing any large DMTF spec / binary asset by
      source URL + SHA-256 hash (never commit the binary itself), and a pure-Dart guard test that
      fails when a spec/binary asset over an agreed size threshold is added under
      `test/fixtures/**` (or the repo) without a matching manifest entry; document the "ask a
      human before committing large assets / store link + hash meanwhile" gate in `DEVELOPMENT.md`.
      No binary download, no dependency added, no `lib/` change, production TLS untouched.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with a new RED→GREEN guard
              test pinning the manifest-required-for-large-assets contract; writes limited to
              `test/**`, `tool/**`, `.github/workflows/**`, `DEVELOPMENT.md`; never `lib/`.

<!-- rf-ideate split 2026-11-19 12:37 UTC: slices the FUTUREWORK "Blocked / needs a human"
     "[!] Live BMC integration — requires real credentials/network; never attempt in the unattended
     job. Keep the live-BMC test skipped" blocker into a tooling guard. Pure CI/test work, no lib/. -->

- [x] EP-T6 LANDED 2026-11-19 (run `auto: FEATURE — EP-T6 unattended live-BMC safety guard + tests`): CI/pure-Dart guard that the blocked live-BMC epic stays unattended-safe: assert the DMTF
      emulator / live-BMC integration tests remain skipped unless an explicit env var supplies a real
      emulator URL/credentials (the existing `REDFISH_EMULATOR_URL` skip contract), that plain
      `flutter test` needs no BMC network or credentials, and document the human opt-in in
      `DEVELOPMENT.md`. Never enable live-BMC in the scheduler; no product `lib/` code.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with a new guard test pinning
              the skip-without-env contract (RED→GREEN proof); writes limited to `test/**`, `tool/**`,
              `.github/workflows/**`, `DEVELOPMENT.md`; never `lib/`.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 RESOLVED (external-browser + copy is the final
     route). EP-T2 (dependency scaffolding) is DEFERRED pending manual validation evidence — do NOT
     add a WebView/url_launcher dependency unattended. New head-first fixture + guard slices. -->

- [ ] EP-T4 Fixture + CI guard closeout for the final external-browser/copy route: add an OpenBMC
      Manager fixture with a GraphicalConsole (HTML5 over HTTPS) + `Oem.KVM.Uri` and a RemoteConsole
      to drive selection/guidance tests, plus a pure-Dart/CI guard asserting no `webview_flutter` /
      `url_launcher` dependency and the KVM in-app flag stays OFF unless validation evidence exists.
      No product `lib/` code.
      Dept: rf-tooling
      Verify: `flutter test test/features/kvm/ && bash tool/emulator/run_tests.sh` (85/85) `&& flutter analyze`
              (0 issues); writes limited to `test/**`, `tool/**`, `.github/workflows/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): unblocked fixture + dependency
     prep. EP-T2 gated on EP-P1. Every item carries the mandatory Dept:/Verify: fields
     (MULTI_DEPT hard rule #4). -->

- [ ] EP-T1 Fixtures for the in-app-render / selection tests: an OpenBMC `Managers/{id}` sample
      (GraphicalConsole + `Oem.KVM.Uri`) and a DMTF mockup Manager with
      `GraphicalConsole`/`RemoteConsole`, so the launch-path tests have real payloads. No product code.
      Dept: rf-tooling
      Verify: `flutter test test/features/kvm/ && bash tool/emulator/run_tests.sh` (85/85) `&& flutter analyze`
              (0 issues); writes limited to `test/fixtures/**` + `test/**`.

- [ ] EP-T2 (after EP-P1) Dependency decision + conditional-import/pubspec scaffolding, CI verify
      gate and documentation for the opt-in WebView/url_launcher path — feature-flagged, never
      weakening production TLS, with the external-browser/copy fallback kept. No product `lib/` code.
      Dept: rf-tooling
      Verify: `flutter pub get && flutter analyze` (0 issues) and the `.github/workflows/verify.yml`
              gate green; writes limited to `pubspec*`, `tool/**`, `.github/workflows/**`, docs — never `lib/`.

- [x] EP-T3 Extend the KVM coverage gate (`tool/coverage_gate.dart`) to scope the new
      `lib/features/kvm/platform/**` adapter files so the ≥75% KVM gate stays
      honest for new code; pure-Dart RED→GREEN gate tests, no product `lib/` change.
      LANDED run 2026-11-20 08:33 UTC (see Log): added a dedicated `kvm-platform` gate.
      Dept: rf-tooling
      Verify: `flutter test test/tool/coverage_gate_test.dart && flutter analyze` (0 issues);
              writes limited to `tool/**` + `test/tool/**`.


<!-- rf-automation 2026-11-22 06:05 UTC: discovered during the EP-U17 audit — the guard file
     extended by that slice (`test/features/kvm/kvm_open_affordance_gating_test.dart`, EP-U8 + EP-U17,
     live cases, reachable from verify.yml whole-tree `flutter test --coverage`) is NOT in
     `canonicalGuardFiles` or any pinned epoch set, so deleting / emptying / test-stripping it
     stays GREEN. Same "who guards the guards" gap family as EP-T14..T22. Test/tool-only, no lib/. -->

- [x] EP-T23 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-T23 guard-suite liveness — register the no-WebView affordance guard + RED→GREEN tests`, analyze 0 / 2090 passed / 1 skipped) — Guard-suite liveness: register the EP-U8/EP-U17 no-WebView affordance guard
      (`test/features/kvm/kvm_open_affordance_gating_test.dart`) in `canonicalGuardFiles` under a
      fresh pinned `epT23AddedGuards` epoch set (length 1, disjoint from every earlier designation),
      include it in `allDesignatedGuards` + the EP-T20 completeness arithmetic, and add a pin test
      with pairwise-disjointness assertions plus a temp-root RED→GREEN (missing/emptied/test-less →
      violation, intact → clean). AUDIT FIRST: if the guard is already registered and liveness-checked,
      record the audit and add nothing; no churn.
      Dept: rf-tooling
      Verify: `flutter test test/tool/guard_suite_liveness_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (dropped canonical entry → pin + completeness failures; restored →
              green); writes limited to `test/tool/guard_suite_liveness_test.dart`;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no lib/, no production TLS weakening.
      **LANDED** 2026-11-22: registered `test/features/kvm/kvm_open_affordance_gating_test.dart` in `canonicalGuardFiles`; added pinned `epT23AddedGuards` (length 1, disjoint from every earlier designation), included it in `allDesignatedGuards` and the EP-T20 completeness arithmetic (+1 pin test), added a temp-root RED→GREEN. Real-file RED: dropped the canonical entry → 3 failures (`+33 -3`: EP-T23 pin + EP-T20 completeness + EP-T23 liveness temp-root); restored byte-clean (SHA `bc67790c…` unchanged), 600-perm backup shredded → 36/36 GREEN. `dart format` clean; analyze 0; full suite 2090 passed / 1 skipped (baseline 2088 +2); issues validate OK; diff --check clean; deps unchanged; lib diff empty; emulator skipped (test/tool-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening.

## Log

- 2026-11-23 00:55 UTC — EP-T34 LANDED (agent:redfish-automation, FEATURE #009/#021, test/tool-only, dependency-free, TLS-safe): added pure-Dart `evaluateCoverageThresholdFloors(source)` + 8 tests to `test/tool/coverage_gate_test.dart`, reading all four effective coverage thresholds from source text and failing closed if any falls below its documented floor (overall 0.75, scoped 0.80, kvm 0.75, kvm-platform 0.75). Covers a lowered overall/scoped literal, a lowered shared `kKvmThreshold` (both kvm gates), a hardcoded sub-floor builder default, a missing default, temp-root RED->GREEN, and a real-repo invariant pinning current values. AUDIT FIRST: EP-T31 (gate wiring) + existing `kKvmThreshold == 0.75` pins left the overall/scoped floors unguarded — genuine gap, no live divergence. Real-file RED: lowered `overallThreshold` 0.75->0.40 under a 600-perm backup -> exactly the named EP-T34 real-repo failure (`overall threshold 0.4 below floor 0.75`); source restored byte-clean (SHA `f93a2e14…` unchanged, 0 residue, empty `tool/` diff, backup shredded) -> 45/45 GREEN. analyze 0; issues validate OK; diff --check clean; deps unchanged; emulator skipped (test-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. Both issues stay OPEN.

- 2026-11-22 09:57 UTC — SEC-010 LANDED (agent:redfish-automation, FEATURE #009/#021 guard-suite closeout; #010 security hardening; test/tool-only, dependency-free, TLS-safe): AUDIT found a genuine "who guards the guards" gap — the four cross-cutting security guards `test/security/tls_enforcement_test.dart` (self-signed rejection unless per-profile opt-in), `tls_downgrade_test.dart` (`https → http` downgrade rejection), `token_isolation_test.dart` (auth-token isolation) and `no_plaintext_test.dart` (no SharedPreferences persistence) were live + reachable from verify.yml's whole-tree `flutter test --coverage`, but absent from `canonicalGuardFiles` and every pinned epoch, so deleting / emptying / test-stripping them (e.g. `tls_downgrade_test.dart`, which guards production TLS, never weakened) stayed GREEN. The sibling `test/security/credential_leak_audit_test.dart` was registered by EP-T22 — these four were missed. Registered all four in `canonicalGuardFiles` under a pinned `sec010AddedGuards` epoch (length 4, disjoint from every earlier designation), included them in `allDesignatedGuards` + the EP-T20 completeness arithmetic, +1 pin test with pairwise-disjointness assertions, +1 temp-root RED→GREEN (each of the four: missing / emptied / test-less → violation, intact → clean). Real-file RED: dropped the `tls_downgrade_test.dart` canonical entry → exactly 3 failures (`+39 -3`: SEC-010 pin + EP-T20 completeness + SEC-010 liveness temp-root), the other 39 liveness tests GREEN; restored byte-clean (SHA `c02b22ad…` unchanged, 0 residue), 600-perm backup shredded → 42/42 GREEN. `dart format` clean; analyze 0; issues validate OK; diff --check clean; deps unchanged; lib diff empty; emulator skipped (test/tool-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening.

- 2026-11-21 10:17 UTC — EP-T16 LANDED (agent:redfish-automation, FEATURE #009/#021): extended `canonicalGuardFiles` in `test/tool/guard_suite_liveness_test.dart` 21→24 with the three post-EP-T15 widget-level regression guards that were live/reachable but not liveness-checked (`kvm_clipboard_cross_surface_agreement_test.dart`, `kvm_view_reload_indicator_test.dart`, `kvm_view_stale_error_banner_test.dart`; live cases 3/2/3). Confirmed liveness gap: deleting / emptying / test-stripping one would stay GREEN. Added pinned `epT16AddedGuards ⊆ canonicalGuardFiles` set, pairwise-disjointness assertions vs EP-T14/EP-T15, a pin test and a temp-root RED→GREEN (missing/emptied/test-less → violation, intact → clean). Real-file RED proof: dropped `kvm_view_stale_error_banner_test.dart` from the canonical list → both new EP-T16 tests failed (`+11 -1`, pin test named the dropped guard); restored byte-clean (SHA `c66f8ebc…`), 600-perm backups shredded → 12/12 GREEN. analyze 0; full `flutter test` 1863 passed / 1 skipped (baseline 1861 +2); issues validate OK; diff --check clean; deps unchanged. Test/tool-only — no `lib/`, wire/fixture/tool-runtime or TLS change; DMTF emulator skipped (<7 days since last green 85/85). Concurrent rf-gate merge swept WIP into `stash@{0}`; recovered via `git stash apply` (stash left untouched).

- 2026-11-21 01:55 UTC — EP-T14 LANDED (agent:redfish-automation, FEATURE #009/#021): extended `canonicalGuardFiles` in `test/tool/guard_suite_liveness_test.dart` from the 8 EP-T12 guards to 15 by adding the 7 post-EP-T12 safety guards (`queue_item_schema_guard_test.dart`, `production_optin_construction_guard_test.dart`, `cross_layer_authority_agreement_test.dart`, `kvm_viewer_flagoff_false_claim_guard_test.dart`, `kvm_viewer_disclosure_contract_test.dart`, `kvm_providers_test.dart`, `kvm_session_audit_invariants_test.dart`) — each verified present with live `test(...)` cases and reachable from verify.yml's whole-tree `flutter test --coverage`. Confirmed liveness gap: without the extension, deletion/emptying/test-stripping/CI-de-invocation of those guards would stay GREEN. Pinned `epT14AddedGuards ⊆ canonicalGuardFiles` so dropping a guard from the set is detected; temp-root RED→GREEN (missing/emptied/test-less → violation, intact → clean) + real-repo RED proof (stripped all test cases from `kvm_providers_test.dart` → real-repo invariant failed `NO_TEST_CASES`, `+7 -1`; restored byte-clean SHA `9460cc09…` unchanged, 600-perm backup shredded) → 8/8 GREEN. analyze 0; full `flutter test` 1746 passed / 1 skipped (baseline 1744 +2); issues validate OK; diff --check clean; deps unchanged. Test-only — no `lib/`, dependency, wire/fixture/tool-runtime or TLS change; DMTF emulator skipped (<7 days since last green 85/85).

- 2026-11-20 19:13 UTC — EP-T13 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/queue_item_schema_guard_test.dart` (13 tests), a comment-aware, dependency-free pure-Dart guard that parses every unchecked `- [ ]` item in `queues/*.md` and fails closed on a missing/duplicate/out-of-set `Dept:` or a missing/empty `Verify:` command. HTML comments are blanked (prose like "mandatory Dept:/Verify: fields" in the platform.md footer cannot cause a false positive); all 20 real unchecked items are schema-clean. Temp-root RED→GREEN (missing/duplicate/bad Dept + empty Verify → violation, valid → clean) + real-file RED proof (planted a malformed item in `queues/tooling.md` → real-repo invariant failed naming the offender `BAD_DEPT`/`EMPTY_VERIFY`, `+12 -1`; restored byte-clean SHA `342bc595…` unchanged, 0 probe artifacts, empty queues diff → 13/13 GREEN). analyze 0; full `flutter test` 1712 passed / 1 skipped (baseline 1699 +13); issues validate OK; diff --check clean; deps unchanged. Test-only — no `lib/`, wire/fixture/tool-runtime or TLS change; guard runs via `flutter test --coverage` (no second verify.yml invocation); DMTF emulator skipped (<7 days since last green 85/85).

- 2026-11-20 15:17 UTC — EP-T12 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/guard_suite_liveness_test.dart` (6 tests), a pure-Dart "who guards the guards" guard enumerating the 8 established KVM safety guard files and failing closed if any is missing, emptied, stripped of live `test(...)`/`testWidgets(...)` cases (comment/string/raw-string-aware), or unreachable from verify.yml's `flutter test --coverage`. Temp-root RED→GREEN (missing/emptied/test-less/unreachable all violation, intact clean) + real-file RED proof (emptied `notice_single_source_guard_test.dart` → `NO_TEST_CASES`, restored byte-clean SHA `b3c0e0b5…`, backup shredded) → 6/6 GREEN. analyze 0; full `flutter test` 1630 passed / 1 skipped (one transient power_view flake re-isolated 26/26 GREEN, clean rerun); issues validate OK; diff --check clean. Test-only — no `lib/`, dependency, wire/fixture/tool-runtime or TLS change; DMTF emulator skipped (<7 days since last green 85/85).

- 2026-11-20 09:13 UTC — EP-T11 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/uri_parse_single_source_guard_test.dart` (9 tests), a test-only pure-Dart guard that scans every product `lib/features/kvm/**.dart` (comment + string-literal stripping state machine) and fails closed if any file OUTSIDE the five designated shared helper files calls `Uri.parse`/`Uri.tryParse` on a BMC-supplied value or defines a duplicate of the 12 distinctive private shared control-safe/classifier helpers. 7 unit cases (raw parse/tryParse, allowlisted helper, comments/strings, duplicate helper, public-helper call, filename-not-immunity) + temp-root RED→GREEN proof + real-repo invariant. Real-file RED proof: temporarily appending `Uri.parse(...)` to `lib/features/kvm/models/kvm_models.dart` failed the real-repo invariant (`offenders: .../kvm_models.dart: raw Uri.parse/tryParse outside a designated shared helper`); restored byte-clean (SHA `a3308faf…` unchanged) → 9/9 GREEN. Only `launch_plan.dart` (allowlisted) has real `Uri.tryParse` calls. analyze 0; full `flutter test` 1528 passed / 1 skipped. No `lib/`, dependency, wire/fixture or TLS change; guard runs via `flutter test --coverage` (no second verify.yml full-suite invocation). DMTF emulator skipped (test-only, <7 days since last green 85/85).
- 2026-11-20 08:33 UTC — EP-T3 LANDED (agent:redfish-automation, FEATURE #009/#021): added `kKvmPlatformScopePrefixes` (`lib/features/kvm/platform/`) + `evaluateKvmPlatformGate()` (pure-Dart `GateResult` named `'kvm-platform'`, 75% threshold, reuses `CoverageSummary.scope()` normalization) to `tool/coverage_gate.dart`, folded into `evaluateAllGates()` as a 4th enforced gate so the security-critical fail-closed classifier/decision layer cannot be diluted by the wide KVM aggregate. +6 tests in `test/tool/coverage_gate_test.dart` (29/29): platform-only 75% scoping, a fully-covered KVM aggregate cannot mask a 0% platform file, custom threshold/prefix, absolute+Windows paths, empty-scope fails closed, and 4-gate `evaluateAllGates`/CI-JSON shape. RED proof: temporarily scoping the gate to all of `lib/features/kvm/` failed 6 tests (`linesFound Expected: <100> / Actual: <400>`; the masked-adapter test expected `passed:false` but saw the 75% aggregate pass); restored byte-clean (SHA `f93a2e14…` unchanged) → 29/29 GREEN. Gate CLI on real lcov: PASS overall 90.1% / scoped 90.4% / kvm 96.8% / kvm-platform 99.6%, exit 0. Docs updated: DEVELOPMENT.md, MULTI_DEPT.md, verify.yml comment (four gates now). No product `lib/`, dependency, wire/fixture change, no production TLS weakening. DMTF emulator skipped (tool/test-only change; <7 days since last green 85/85).
- 2026-11-20 — EP-T10 LANDED (agent:redfish-automation): added `test/fixtures/redfish/openbmc_console_manager.json` (valid Redfish `Manager.v1_19_0` BMC: HTML5-over-HTTPS GraphicalConsole + disabled serial + HTML5 RemoteConsole + `Oem.OpenBMC.KVM.Uri`) and `test/features/kvm/kvm_openbmc_fixture_test.dart` (10 tests) driving `KvmConsole.fromManager` / `KvmCapability.fromManager` over it — console enumeration, launch-safe graphical plan, disabled/OEM/remote paths, capability aggregation + cross-view agreement, mutation sensitivity. RED proof: corrupting the graphical ConnectUri to plaintext HTTP failed 3 drive tests; restored byte-clean. No `lib/`, dependency, wire or TLS change; analyze 0 / 1492 passed / 1 skipped.
- 2026-11-19 — EP-T6 LANDED (agent:redfish-automation): added `tool/unattended_guard.dart` (pure-Dart unattended-safety policy evaluator + CLI) enforcing three invariants at commit/CI time: (1) every `test_integration/**.dart` gates network on `String.fromEnvironment('REDFISH_EMULATOR_URL')` AND calls `markTestSkipped` when absent; (2) no plain `test/**.dart` references the emulator env var (`test/tool/` guard self-tests exempt); (3) no production `lib/**.dart` hard-enables `allowSelfSigned: true`. `test/tool/unattended_guard_test.dart` adds +15 RED→GREEN tests; CLI RED proof (ungated integration test in a temp dir) produced a violation + exit 1; real-repo CLI scan green (286 Dart sources). Wired into `.github/workflows/verify.yml` + documented the live-BMC human opt-in in `DEVELOPMENT.md`. No `lib/` change, no dependency, production TLS untouched.
- 2026-11-19 — LA-1 LANDED (agent:redfish-automation): added `tool/asset_guard.dart` (pure-Dart large/binary asset policy evaluator + CLI) and `tool/asset_manifest.json` (path + byte size + SHA-256 + source URL for the mirrored DSP0266 PDF and the schema index). Any binary asset over 1 MiB without a manifest entry, or with size/hash drift, fails closed (exit 1); malformed manifests fail closed (exit 2). +15 RED→GREEN pure-Dart tests in `test/tool/asset_guard_test.dart` (synthetic unlisted large binary → violation; size/hash drift; path normalization; manifest validation; real-repo manifest coverage), RED proof via a temp-dir large binary. Wired into `.github/workflows/verify.yml` + documented the "ask a human before committing large assets" gate in `DEVELOPMENT.md`. No `lib/` change, no dependency, production TLS untouched. analyze 0; full suite green.

- 2026-11-20 — EP-T9 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/launch_status_single_source_guard_test.dart` (6 tests), a test-only pure-Dart guard that derives the seven `kvmLaunchStatusText` launch-status a11y messages FROM `kvm_models.dart` at test time and fails closed if any other product `lib/features/kvm/**.dart` hardcodes one of those fragments (card↔viewer visible-text/announced-label copy drift) or redefines the shared function; also pins both launch surfaces call the shared function. Complements the RU-2 notice guard (which covers only the six shorter notice constants). 2 RED + 2 GREEN proofs, real-repo scan clean (RU-2 notice authority excluded as another copy authority); analyze 0 / 1454 passed / 1 skipped. No `lib/`, dependency, wire/fixture change, no production TLS weakening. DMTF emulator skipped (test-only, <7 days since last green 85/85). EP-T9 is a newly discovered tooling closeout slice for the still-open #009/#021 epic (RU-2 single-source invariant extended to the launch-status strings).
