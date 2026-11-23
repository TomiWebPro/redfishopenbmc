# Queue rf-service (enabled in phase 2)

Owns: `lib/features/kvm/kvm_service.dart`, controllers/providers, `lib/redfish/client/**`.
Verify: service tests + emulator 85/85 when `lib/` wire changes.

## Backlog (head first)

<!-- rf-ideate split 2026-11-23 06:31 UTC: carves a fresh, machine-checkable, unblocked slice of the still-open
     #009/#021 manager-walk epic. RS-2 pins per-manager skip-vs-propagate over HTTP STATUS codes and EP-S13 pins
     skip agreement when a sibling fetch fails, but nothing pins the NON-STATUS failure matrix — malformed JSON,
     wrong/blank Content-Type, empty/EOF body, and a socket/connection exception — at BOTH service surfaces: a
     one-sided catch/filter could throw from `fetchCapabilities()` while `fetchConsoles()` skips (or vice versa),
     blanking one gated card surface. Pure service characterization; the credentialed-Primary decision (EP-S8)
     stays blocked and is NOT re-split. AUDIT FIRST; RED→GREEN only on a genuine divergence, never churn.
     No code touched. -->

- [ ] EP-S17 Malformed-body / transport-exception skip-vs-propagate agreement across both service surfaces:
       over in-temp `/Managers` payloads where one manager's `/Managers/{id}` fetch returns a malformed JSON body,
       a wrong/blank Content-Type, an empty body, or a transport-level exception (while a healthy sibling stays
       valid), pin that `fetchConsoles()` and `fetchCapabilities()` apply the SAME skip/propagate decision to that
       manager, surface the SAME surviving manager-id set exactly once (RS-6/RS-8 identity unchanged), resolve the
       SAME primary and `fetchCapability(id)` results on the survivors, and never throw a raw parse/socket error
       out of one surface while the other skips, nor blank the whole gated screen. AUDIT FIRST: if both surfaces
       already share one walk result with one catch/filter, record the audit and add nothing; RED→GREEN only on a
       genuine divergence, never churn. No behaviour change folded in (auth/TLS failures must still propagate per
       RS-2); no WebView/protocol import, no production TLS weakening.
       Dept: rf-service
       Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_manager_skip_agreement_test.dart && flutter analyze`
               (0 issues), RED→GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/kvm_service.dart` + `test/features/kvm/**` (+ emulator 85/85 only if `lib/`
               wire changes); `git diff --exit-code -- pubspec.yaml pubspec.lock`; no WebView/protocol import,
               no production TLS weakening.

<!-- rf-ideate split 2026-11-23 02:27 UTC: carves a fresh, machine-checkable, unblocked slice of the
     still-open #009/#021 manager-walk epic. RS-6/RS-8/RS-9 and EP-S5 pin dedup, collision determinism,
     padded lookup and hostile ASCII `Id` resolution, but all over EXACT-case ASCII ids — nothing pins
     that two manager ids differing only by UNICODE NORMALIZATION FORM or CASE (NFC vs NFD, dotted/dotless
     I `İ`/`I`/`ı`, Kelvin sign `K` vs `K`, uppercase/lowercase hex in a derived id) remain DISTINCT
     physical managers: a `toLowerCase()` / Unicode-normalizing key in the walk could silently merge two
     real BMCs into one card while every ASCII identity/collision suite stays GREEN. Pure service
     characterization; the credentialed-Primary decision (EP-S8) stays blocked and is NOT re-split.
     AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-S16 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-S16 Unicode/case-variant manager-id distinctness guard + RED->GREEN tests`, analyze 0 / targeted 3/3 / full suite in tracking, test-only) — AUDIT FIRST: the walk already keys ids byte-exactly (`_managerId` trims only) and `fetchCapability` compares with `==` after the same trim, so NFC/NFD, dotted-vs-dotless-I, Kelvin-sign and case variants stay distinct BY CONSTRUCTION — no live divergence, no behaviour change. Genuine unguarded seam: no existing test drove the Unicode/case-variant id matrix through BOTH service surfaces + the exact-byte lookup (RS-6/RS-8/RS-9/EP-S5 are exact-case ASCII). Added `test/features/kvm/kvm_service_unicode_id_distinctness_test.dart` (3 tests): a 9-variant in-temp `/Managers` (ASCII member segments, variants in body `Id`), pinning one distinct card per variant on both surfaces, exact-byte `fetchCapability` lookup for every variant (no case-fold / NFC bleed), and no normalized-away key. Real-file RED: a one-sided `.toLowerCase()` on both sides of the `fetchCapability` comparison in `lib/features/kvm/kvm_service.dart` under a 600-perm backup → exactly `+2 -1` (the exact-byte-key lookup test failed `Expected: 'bmc' Actual: 'BMC'`), the other 2 new tests GREEN and the 3 sibling service lookup suites 8/8 GREEN; source restored byte-clean (SHA `653e64a6…` unchanged, 0 residue, `git diff --exit-code -- lib/` clean, backup shredded) → 3/3 targeted GREEN. Test-only, empty `lib/` diff, deps unchanged, emulator skipped (test-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. Original item:
       Unicode/case-variant manager-id distinctness across the service surfaces: over an in-temp
       `/Managers` mockup whose `Members`/`Id` values are pairwise NFC/NFD, dotted-vs-dotless-I,
       Kelvin-sign-vs-K and case variants of one base id, pin that `fetchConsoles()` / `fetchCapabilities()`
       surface each as a DISTINCT physical manager (no accidental merge or dedup) with stable RS-6/RS-8
       identity, that `fetchCapability(id)` resolves each by its exact byte key, and that no raw control
       or normalized-away code point becomes a key. AUDIT FIRST: if the walk already keys ids byte-exactly
       with no case folding or normalization, record the audit and add nothing; RED->GREEN only on a
       genuine divergence, never churn. No wire/TLS change, no WebView/protocol import, no dependency.
       Dept: rf-service
       Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_manager_identity_test.dart test/features/kvm/kvm_service_lookup_key_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/kvm_service.dart`, controllers/providers + `test/features/kvm/**`;
               `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change, no WebView/protocol
               import, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 22:24 UTC: carves a fresh, machine-checkable, unblocked slice of the
     still-open #009/#021 manager-walk epic. RS-7 pins hostile-body tolerance when a manager FETCH SUCCEEDS
     but still yields usable consoles, EP-S13 pins SAME-manager skip when a sibling fetch FAILS
     (404/retryable), and RS-6/RS-8 pin identity/cardinality for well-formed bodies — but nothing pins the two
     service surfaces' agreement when a manager is fetched successfully yet yields ZERO USABLE consoles (all
     blocks disabled / URI-less / unsupported ConnectTypes, or an all-malformed console set): does
     `fetchConsoles()` still surface exactly one card and `fetchCapability(id)` one discovery-only summary with
     NO phantom launch target, while a healthy sibling keeps its deterministic secure Primary? Pure service
     characterization; the credentialed-Primary decision (EP-S8) stays blocked and is NOT re-split. AUDIT FIRST;
     RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-S14 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-S14 zero-usable-console surfacing agreement + RED->GREEN tests`, analyze 0 / 2401 passed / 1 skipped) — Zero-usable-console manager surfacing agreement between `fetchConsoles()` and
       `fetchCapabilities()`: over in-temp `/Managers` mockups where one manager is fetched OK but every
       console block is disabled / URI-less / unsupported-type / all-malformed (yielding zero launchable
       consoles), pin that BOTH service surfaces surface that manager exactly once (RS-6/RS-8 identity
       unchanged) with a discovery-only, non-launchable summary and NEVER a phantom Primary or launch target,
       while a healthy sibling keeps its deterministic secure primary and its own cards. AUDIT FIRST: if both
       surfaces already share one walk result and agree end-to-end, record the audit and add nothing;
       RED->GREEN only on a genuine divergence, never churn. Distinct from EP-S13 (fetch FAILURE skip) and
       RS-7 (hostile body that still yields usable consoles); no behaviour change folded in.
       Dept: rf-service
       Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_capability_primary_agreement_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence.

<!-- rf-ideate split 2026-11-22 14:17 UTC: carves a fresh, machine-checkable, unblocked slice of the
      still-open #009/#021 manager-walk epic (never-empty-well malformed-payload tolerance, MULTI_DEPT
      hard rule 10). RS-6/RS-8 pin manager-set identity, dedup and duplicate-Id collision determinism for
      WELL-FORMED member URIs, and RS-7 pins hostile manager BODY tolerance — but nothing pins the
      collection layer when `/Managers` `Members` itself is malformed: a non-list `Members` (string/map/
      int/null) or a list holding blank / non-string / control-bearing / padded / case-variant duplicate
      member references. A one-sided change could throw a cast, or drop/duplicate a physical manager, while
      every identity and body-tolerance suite stays GREEN. Pure service characterization; the credentialed-Primary
      decision (EP-S8) stays blocked and is NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence,
      never churn. No code touched. -->

<!-- rf-ideate split 2026-11-22 18:21 UTC: carves a fresh, machine-checkable, unblocked slice of the
      still-open #009/#021 manager-walk epic. RS-2 pins the per-manager skip-vs-propagate status semantics
      (404 / retryable 429,5xx-except-501 skipped; 401/403/TLS failures propagate) and EP-S6 pins
      capability<->primary agreement for one HEALTHY manager — but nothing pins that `fetchConsoles()` and
      `fetchCapabilities()` skip the SAME manager in ONE walk when a sibling manager's `/Managers/{id}`
      fetch fails transiently: a one-sided skip filter could drop a physical manager from one card surface
      and not the other while every single-surface suite stays GREEN. Pure service characterization; the
      credentialed-Primary decision (EP-S8) stays blocked and is NOT re-split. AUDIT FIRST; RED->GREEN only
      on a genuine divergence, never churn. No code touched. -->

- [x] EP-S13 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-S13 manager-skip agreement guard + RED->GREEN tests`, analyze 0 / 2389 passed / 1 skipped) — AUDIT FIRST: both `fetchConsoles()` and `fetchCapabilities()` already walk `/redfish/v1/Managers` through the SAME `KvmService._fetchManagerBodies()` helper with ONE skip filter, so skip agreement holds BY CONSTRUCTION — no live divergence, no behaviour change. Genuine unguarded seam: RS-2 pins each surface's skip with ONE failing manager at a time, RS-6 pins manager-set identity for WELL-FORMED bodies, but NOTHING pinned BOTH surfaces skipping the exact SAME manager(s) in ONE 4-manager walk with several failing members interleaved. Added `test/features/kvm/kvm_service_manager_skip_agreement_test.dart` (9 tests): a 404+503 matrix over an in-temp `/Managers` (MgrPrimary/MgrSerial survive; MgrGone 404, MgrFlappy 503 skipped) pinning identical survivor id sets (RS-6 identity unchanged), exactly-once cards, `fetchCapability(id)` resolves survivors / null on skipped, the same deterministic secure external-browser primary, no blanked screen, a 429 variant, an all-but-one-fail variant, and 401/501 propagation agreement on BOTH surfaces. Real-file RED: a faithful one-sided skip-filter divergence (temporarily gave `fetchCapabilities()` a strict walk via a `{bool strict}` param) → exactly 6 named failures (`+3 -6`: all cross-surface agreement tests; the primary-only + 401/501 propagation tests correctly stayed GREEN); source restored byte-clean (SHA `653e64a63a52b8d2741a438daf7e77a0291c559393e5328877d41e5e8091ddd0` unchanged, 0 residue, empty `lib/` diff, 600-perm backup shredded) → 9/9 GREEN. Test-only, dependency-free, TLS-safe, no WebView/protocol import, no URL opened, no production TLS weakening. Original item: Manager-skip agreement between `fetchConsoles()` and `fetchCapabilities()` under a
       retryable/404 manager-walk failure matrix: over in-temp `/Managers` payloads where one of two or
       three managers returns 404 or a transient/retryable failure (429 / 5xx-except-501) from its
       `/Managers/{id}` fetch, pin that BOTH service surfaces skip exactly the SAME manager(s), surface the
       SAME surviving manager-id set exactly once (RS-6/RS-8 identity unchanged), resolve the SAME primary
       and `fetchCapability(id)` results on the survivors, and never blank the whole gated screen or emit a
       phantom card for the skipped manager. AUDIT FIRST: if both surfaces already share one walk result
       with an identical skip filter, record the audit and add nothing; RED->GREEN only on a genuine
       divergence, never churn. No behaviour change folded in (401/403/TLS failures must still propagate
       per RS-2); no WebView/protocol import, no production TLS weakening.
       Dept: rf-service
       Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_capability_primary_agreement_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `test/features/kvm/**` (+ `lib/features/kvm/kvm_service.dart` only on a genuine divergence);
               emulator 85/85 only if `lib/` wire changes; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
               no WebView/protocol import, no production TLS weakening.

- [x] EP-S12 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-S12 malformed Members cross-surface agreement guard + RED->GREEN tests`, test-only) — Malformed `Members` collection tolerance at the manager walk: over in-temp `/Managers` payloads
       whose `Members` is a non-list (string / map / int / null) and lists containing blank / non-string /
       control-bearing / padded / case-variant duplicate member references, pin that `KvmService.fetchConsoles()`
       / `fetchCapabilities()` fail closed (skip unusable refs, no throw, no duplicated or phantom manager),
       that every well-formed physical manager is still surfaced exactly once with RS-6/RS-8 identity
       unchanged, and that `fetchCapability(id)` agrees with the aggregate for the surviving managers.
       AUDIT FIRST: if the shared walk already tolerates the whole matrix end-to-end, record the audit and
       add nothing; RED->GREEN only on a genuine divergence, never churn. No behaviour change folded in; no
       WebView/protocol import, no production TLS weakening.
       Dept: rf-service
       Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_manager_identity_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to `test/features/kvm/**`
               (+ `lib/features/kvm/kvm_service.dart` only on a genuine divergence); emulator 85/85 only if
               `lib/` wire changes; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no WebView/protocol
               import, no production TLS weakening.

        **LANDED** 2026-11-23: AUDIT first — the shared `KvmService._fetchManagerBodies()` walk already
        tolerates the whole hostile `Members` matrix end-to-end (non-list -> no managers; blank/non-string/
        missing-link/control-bearing refs skipped; padded/duplicate refs deduplicated; dead 404 links skipped),
        so console/capability agreement holds BY CONSTRUCTION — no live divergence, no behaviour change.
        Genuine unguarded seam: RS-7's hostile-members case checks only `fetchConsoles()`, and the malformed
        fixture checks only non-list -> empty, so NOTHING drove the matrix through BOTH surfaces + the
        `fetchCapability(id)` lookup in ONE walk. Added
        `test/features/kvm/kvm_service_malformed_members_agreement_test.dart` (3 tests): (1) non-list Members
        (string/map/int/null) -> both surfaces empty + no phantom lookup; (2) hostile entries (blank/
        whitespace/non-string/missing-link/non-string-link/404-dead/padded-duplicate) -> both surfaces surface
        exactly the two survivors once with RS-6/RS-8 identity, no duplicate/phantom/control-bearing id,
        `fetchCapability(id)` agrees field-for-field, padded lookup resolves, ghost never does; (3)
        control-bearing/padded refs normalize identically on both surfaces with no phantom id. Real-file RED:
        a one-sided strict walk in `fetchCapabilities()` (rethrow dead links) -> exactly `+1 -2` (the two
        cross-surface agreement tests fail with `RedfishException(404)`, the non-list test stays GREEN),
        proving the guard is live and non-vacuous; source restored byte-clean (SHA `653e64a6...` unchanged,
        0 residue, empty `lib/` diff, 600-perm backup shredded) -> 3/3 targeted GREEN. `dart format` clean;
        analyze 0; full suite 2441 passed / 1 skipped (baseline 2438 +3 mine); issues validate OK;
        diff --check clean; deps unchanged; emulator skipped (test-only, <7 days since last green 85/85);
        no WebView/protocol import, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 10:12 UTC: carves a fresh, machine-checkable, unblocked slice of the
     still-open #009/#021 manager-walk epic. RS-6/RS-8 pin manager-set identity, dedup and duplicate-Id
     collision determinism, EP-S2/S3/EP-S10 pin tier precedence and all-unsafe selection — but nothing pins
     that a genuine tier TIE (two equally-ranked, openable secure-HTTPS consoles declared in a fixed BMC
     order) resolves to the SAME first-in-order winner across pickPrimary / fetchPrimaryConsole /
     fetchCapability / fetchConsoles on every repeated call. A one-sided iteration-order refactor could flip
     the badged/primary target while every identity and tier test stays GREEN (the #009 divergence class).
     No behaviour change folded in; AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. -->

- [x] EP-S11 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-S11 member-order tie determinism guard + RED->GREEN tests`, test-only) — Member-order tie determinism across the primary/capability service surfaces: over an in-temp
       multi-manager mockup with two or more EQUALLY-ranked openable secure-HTTPS consoles (same tier, no
       credentials) declared in a fixed BMC order, plus a padded/hostile-order variant, pin that
       `KvmService.pickPrimary` / `fetchPrimaryConsole`, `fetchCapability(id)` and `fetchConsoles()` resolve the
       SAME first-in-BMC-order winner on every repeated call, that the surfaced manager-set iteration order is
       stable across calls, and that every physical manager is still surfaced (RS-6/RS-8 identity unchanged).
       AUDIT FIRST: if the first-match iteration already pins this end-to-end, record the audit and add nothing;
       RED->GREEN only on a genuine divergence, never churn. No behaviour change folded in; no WebView/protocol
       import, no production TLS weakening.
       Dept: rf-service
       Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_manager_identity_test.dart test/features/kvm/kvm_service_primary_secure_tier_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to `test/features/kvm/**`
               (+ `lib/features/kvm/kvm_service.dart` only on a genuine divergence); emulator 85/85 only if `lib/`
               wire changes; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no WebView/protocol import, no
               production TLS weakening.

<!-- rf-ideate split 2026-11-22 06:09 UTC: carves a fresh, machine-checkable, unblocked slice of the
     blocked #009/#021 manager-walk epic. RS-6/RS-8 pin manager-set identity and collision
     determinism, EP-S2/EP-S3 pin Primary tier precedence and no-unopenable selection, RS-7 pins
     hostile-body tolerance — but nothing ties all of them together for the CONCENTRATED case where
     every healthy manager's only openable target is control/bidi-unsafe and the rest are disabled /
     URI-less. Pure service characterization/regression guard; the credentialed-Primary decision
     (EP-S8) stays blocked and is NOT re-split. AUDIT FIRST; RED→GREEN only on a genuine divergence,
     never churn. No code touched. -->

- [x] EP-S10 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-S10 all-unsafe primary-selection fail-closed
      determinism guard + RED->GREEN tests`, test-only) — Primary-selection fail-closed determinism over an
      all-unsafe candidate set: over in-temp
      multi-manager bodies where every healthy manager's only openable console carries a control- or
      bidi-bearing secure-HTTPS `ConnectUri`, plus one manager whose blocks are all disabled / URI-less,
      pin that `KvmService.fetchPrimaryConsole()` and `pickPrimary()` return the SAME deterministic,
      launch-safe primary (or none) and never badge an unsafe target, while every physical manager
      stays surfaced identically in `fetchConsoles()` / `fetchCapabilities()` and `fetchCapability(id)`
      agrees with the aggregate. AUDIT FIRST: if EP-S2/EP-S3/RS-6/RS-8 already pin this end-to-end,
      record the audit and add nothing; RED→GREEN only on a genuine divergence, never churn. No
      behaviour change folded in; no WebView/protocol import, no production TLS weakening.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_manager_identity_test.dart test/features/kvm/kvm_service_primary_secure_tier_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof only on a genuine divergence; writes limited to
              `test/features/kvm/**` (+ `lib/features/kvm/kvm_service.dart` only on a genuine
              divergence); emulator 85/85 only if `lib/` wire changes; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no WebView/protocol import, no production TLS weakening.
      LANDED: added `test/features/kvm/kvm_service_all_unsafe_primary_agreement_test.dart` (7 tests) over
      a 4-manager in-temp mockup (non-graphical CRLF console FIRST, two control/bidi-bearing graphical
      consoles, one all-disabled manager) in BMC + reversed order. AUDIT — the fail-closed classifier/plan
      layers already refuse every control/bidi URI by construction (shared `_controlSafeTrimmedUri`), so no
      live divergence, no behaviour change; the unguarded seam was the final `firstGraphical ?? consoles.first`
      fallback with NO pin of its first-in-BMC-order winner when nothing is secure/openable. Pins: both
      primary entry points agree on the same first-graphical winner, repeated-call determinism, never-badged
      secure/browser/in-app/self-signed, both discovery surfaces surface every manager once, and
      `fetchCapability(id)` field-for-field agreement. Real-file RED: `firstGraphical ??= console` →
      `= console` (last-wins iteration refactor) under a 600-perm backup → exactly `+4 -3` (the 3
      winner/determinism tests fail, other 4 GREEN); source restored byte-clean (SHA `653e64a6…` unchanged,
      empty `lib/` diff, backup shredded) → 7/7 targeted GREEN. Sibling service suites 90/90 GREEN;
      emulator skipped (test-only, <7 days since last green 85/85). No WebView/protocol import, no URL
      opened, no production TLS weakening, no dependency change. This guard is NOT yet liveness-registered
      in `test/tool/guard_suite_liveness_test.dart` — a future EP-T-style head.

<!-- rf-ideate split 2026-11-22 02:06 UTC: splits the BLOCKED behaviour-change head EP-S8
     (credential-bearing secure-HTTPS Primary badge vs in-app navigability) of the #009/#021 epic
     into its unattended-doable half. EP-P11 pinned that `allowsInAppNavigation` fails closed on
     userinfo/cross-origin/control-bearing targets and that productionDefault never navigates in-app
     or accepts self-signed; RS-6/RS-8 pin determinism and manager identity. But pickPrimary can still
     badge a `https://user:pass@bmc/console` URI "Primary" while the navigation gate refuses it —
     deciding which side is authoritative is a deliberate human decision (EP-S8, stays blocked).
     This slice only pins the currently-agreeing invariants and RECORDS the divergence as a stable
     baseline. AUDIT FIRST: if already pinned, record the audit and add nothing; RED→GREEN only on a
     genuine divergence, never churn. Human-gated WebView/TLS rendering stays gated and is NOT
     re-split. No code touched. -->

- [x] EP-S9 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-S9 credential-bearing Primary ↔ navigation decision-boundary guard + RED->GREEN tests`, analyze 0 / 2082 passed / 1 skipped) — Credential-bearing secure-HTTPS Primary-badge ↔ navigation-gate decision-boundary guard
      (unblocked half of the blocked EP-S8): over one in-temp manager with a userinfo-bearing
      secure-HTTPS console (`https://user:pass@bmc/console`), a credential-free secure-HTTPS console
      and plaintext/external variants, pin the agreeing invariants — `allowsInAppNavigation` fails
      closed on userinfo (EP-P11), `KvmWebViewPolicy.productionDefault` never navigates in-app or
      accepts self-signed, `pickPrimary` selection stays deterministic and every physical manager is
      surfaced (RS-6/RS-8). RECORD the divergence (a credential-bearing URI can be badged Primary
      while the navigation gate refuses it) in the test/progress doc as a deferred human decision
      (EP-S8) without asserting either side as authoritative. AUDIT FIRST; do NOT fold a behaviour
      change in; RED→GREEN only on a genuine divergence. No dependency, no WebView/protocol import,
      no production TLS weakening.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/platform/navigation_launch_route_agreement_test.dart && flutter analyze`
              (0 issues), RED→GREEN only on a genuine divergence; writes limited to
              `test/features/kvm/**` (+ `lib/features/kvm/kvm_service.dart` only on a genuine
              divergence); emulator 85/85 only if `lib/` wire changes; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no WebView/protocol import, no production TLS weakening.
      **LANDED** 2026-11-22: `test/features/kvm/kvm_credential_primary_navigation_boundary_test.dart` (8 tests) — 1 boundary-precondition (userinfo-bearing HTTPS is a genuine same-origin control-safe secure target), 2 RECORD-only divergence cases (`pickPrimary` badges a credentialed secure graphical Primary while `allowsInAppNavigation` refuses the same URI; first-wins makes it follow BMC order) asserting the divergence + direction but never blessing either side (deferred EP-S8), 5 agreement cases (navigation refuses a credentialed target even from a clean console; clean secure console stays navigable/in-app-eligible; production default never in-app/self-signed; test-only opt-in preserves the initial-load credential exception; `fromManager` surfaces every block and preserves the credentialed URI through the real pipeline). AUDIT: EP-P11 pins the navigation gate + EP-S2 pins tier precedence but neither tied the service Primary badge to the navigation refusal for one credentialed URI. Real-file RED #1: mutated `pickPrimary` to skip credential-bearing secure consoles (the EP-S8 "fix") → exactly 3 new tests failed (`+5 -3`), EP-P11/EP-S2 GREEN; reversed byte-clean (SHA `653e64a6…`, empty lib diff), 600-perm backup shredded → 8/8. Registered in `canonicalGuardFiles` (47→48) + pinned `epS9AddedGuards` epoch (length 1, disjoint from all earlier designations) in `test/tool/guard_suite_liveness_test.dart` (+1 pin test, completeness arithmetic, temp-root RED; real-file RED dropped canonical entry → 3 failures, restored byte-clean SHA `21974afe…`, backup shredded → 56/56). Test/tool-only, no lib/, no dependency, no WebView/protocol import, no production TLS weakening; emulator skipped.

<!-- rf-ideate split 2026-11-21 22:03 UTC: splits a residual service-level aggregate-agreement seam of
     the blocked #009/#021 manager walk into one unblocked, dependency-free, TLS-safe dept slice.
     RS-6/RS-8/RS-9 pin manager-set identity, dedup, collision determinism and lookup-key
     normalization; EP-S6 pins capability<->primary URI agreement for one multi-block manager; RM-6
     and the shared `kvmSessionLimit` helper pin session-limit parsing/cross-view agreement at the
     MODEL layer. Nothing at the SERVICE layer pins that `fetchCapabilities()` / `fetchCapability()`
     surface the same session-limit and enablement aggregates as the model cards for ONE manager
     over a boundary matrix (MaxConcurrentSessions encoded as int / integral double / numeric string
     / negative / blank, contradictory `ServiceEnabled`+`Enabled`, all-disabled). A divergent
     aggregation pass could report one limit on the service summary and another on the rendered
     card. AUDIT FIRST: if the shared helper already guarantees agreement end-to-end, record the
     audit and do NOT manufacture a test; RED→GREEN only on a genuine divergence, never churn.
     Human-gated WebView/TLS rendering stays gated and is NOT re-split. No code touched. -->

- [x] RS-10 Service-level session-limit / enablement aggregate agreement over a boundary matrix:
      LANDED run 2026-11-21 22:51 UTC (see Log) — 3-test RS-10 group in `test/features/kvm/kvm_service_test.dart`.
      over one in-temp multi-block manager mockup (contradictory `ServiceEnabled` / `Enabled` flags,
      an all-disabled block set, and `MaxConcurrentSessions` encoded as int, integral JSON double,
      trimmed numeric string, negative and blank), pin that `KvmService.fetchCapabilities()` and
      `fetchCapability(id)` resolve the SAME winning block's `maxSessions` / enablement as the
      model-level `KvmConsole` / `KvmCapability` built from the same body, keep every physical
      manager surfaced, and fail closed (unreported limit, no launchable primary) for out-of-spec
      limits — all without changing set identity/cardinality or lookup semantics. AUDIT FIRST; fix
      only a genuine divergence via RED→GREEN service tests, no churn.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_capability_primary_agreement_test.dart test/features/kvm/kvm_session_limit_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/kvm_service.dart` + service tests under `test/features/kvm/`; emulator
              85/85 only if `lib/` wire changes; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-21 17:59 UTC: splits a fresh cross-feature seam of the blocked #009/#021
     launch-target epic into one unblocked, service-level, dependency-free, TLS-safe dept slice. EP-S2
     made `KvmService.pickPrimary` select security-first (secure-HTTPS graphical → secure-HTTPS any →
     fallbacks) and EP-S7 aligned the capability summary to it; but the shared `isSecureHttpsConsoleUri`
     classifier explicitly treats a userinfo-bearing HTTPS URI as secure, while RP-1's
     `allowsInAppNavigation` (18:34) FAILS CLOSED on embedded credentials. So a manager exposing a
     userinfo-bearing secure-HTTPS console alongside a credential-free secure-HTTPS console can badge
     the credential-bearing one "Primary" and recommend it as the in-app launch target even though the
     in-app navigation gate refuses it — the authoritative rule is a deliberate decision, so AUDIT first
     and do NOT fold a behaviour change into a guard-only run. Audit first; RED→GREEN only on a genuine
     divergence; no churn. Human-gated WebView/TLS rendering stays gated and is NOT re-split. No code
     touched. -->

- [ ] EP-S8 Primary-badge target ↔ in-app-navigability agreement for credential-bearing secure-HTTPS
      consoles: over an in-temp mockup with a userinfo-bearing secure-HTTPS console (`https://user:pass@bmc/console`)
      and a credential-free secure-HTTPS console on the same manager (plus plaintext-HTTP and external-client
      variants), pin that the console badged "Primary" by `pickPrimary` is one that the final in-app route
      will actually navigate to — i.e. decide/record the authoritative rule and make `pickPrimary` and the
      capability summary agree on one launch target that the fail-closed navigation contract accepts.
      Keep every physical manager surfaced and all prior selection/identity/skip semantics unchanged.
      Broader behaviour change candidate — audit first, do NOT auto-fix without a genuine divergence.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_capability_primary_agreement_test.dart test/features/kvm/kvm_capability_primary_uri_agreement_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/kvm_service.dart` + service tests under `test/features/kvm/`; emulator
              85/85 only if `lib/` wire changes; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no
              WebView/protocol import, no production TLS weakening.

<!-- Discovered 2026-11-21 17:11 UTC during the EP-S6 audit. NOT fixed unattended — the authoritative
     preference (block-order vs security-first) is a broader behaviour change touching the shared
     launch-plan decision layer / LAUNCH_FALLBACK.md and needs a deliberate decision. GENUINE latent
     divergence, confirmed by probe: a single manager with an ENABLED serial SSH block whose ConnectUri
     precedes a secure-HTTPS remote block — KvmCapability.resolveLaunchUri / _standardConnectUri walks
     Graphical -> Serial -> Remote (first non-disabled block with a URI) so the capability SUMMARY
     resolves `ssh://…/serial`, while KvmService.pickPrimary's security-first tier picks the remote
     `https://…/remote`. The capability card is an operator launch-decision surface (it exposes an
     Open affordance on its resolved URI), so the two surfaces disagree on the launch target.
     Probe output: `cap.uri=ssh://bmc.example/serial primary.target=https://bmc.example/remote`.
     A future run should decide the authoritative rule and fix BOTH surfaces together with tests. -->
- [x] EP-S7 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-S7 capability↔primary secure-URI agreement FIX + RED→GREEN tests`, lib+test) — authoritative rule = `KvmService.pickPrimary`'s security-first secure-HTTPS preference. Added a security-first pass in `KvmCapability._standardConnectUri` (using the shared `isSecureHttpsConsoleUri` classifier, same as `KvmConsole.hasSecureLaunchUri` + the fail-closed launch plan) so a control-safe secure-HTTPS console URI wins across all non-disabled blocks BEFORE the graphical→serial→remote block-order fallback; the capability card's resolved URI now agrees with the Primary badge for a manager with an enabled serial SSH URI preceding a secure remote. Real-file RED: unmodified code failed exactly 3/6 (serial SSH leaked as the capability URI `ssh://bmc.example/serial` vs primary `https://bmc.example/remote`); after the fix 6/6 GREEN, targeted capability/service/model 270/270; analyze 0, full 1949 passed / 1 skipped, issues validate OK, diff --check clean. No dependency/wire/TLS change, no WebView/protocol import, no URL opened, no production TLS weakening. Originally: Resolve capability-summary vs primary URI divergence when a serial/external-client
      ConnectUri precedes a secure-HTTPS console (discovered, genuine): decide whether
      `KvmCapability.resolveLaunchUri` should apply `pickPrimary`'s security-first/openable
      preference, then make the capability summary and the primary agree on one launch target with
      RED→GREEN tests. Broader behaviour change — do NOT fold into a guard-only run.
      Dept: rf-service
      Verify: targeted service + capability + launch_plan suites, full suite, RED→GREEN; no production
              TLS weakening; emulator only on lib wire change.

<!-- rf-ideate split 2026-11-21 14:10 UTC: splits a residual cross-method agreement seam of the blocked
     #009/#021 manager walk into one unblocked, service-level, dependency-free, TLS-safe dept slice.
     RS-4..RS-9 and EP-S3/S5 pin member dedup, source identity, cardinality, collisions, hostile
     bodies, lookup-key normalization and `pickPrimary` classification, and RM-5/RM-7/RM-8 pin
     console↔capability agreement at the MODEL level — but nothing at the SERVICE level pins that
     `KvmService.fetchCapability(managerId)` (the per-manager capability summary) and
     `fetchPrimaryConsole()` / `pickPrimary` (the recommended launch target) AGREE for the SAME
     manager over one multi-block payload (Graphical disabled + secure Remote + serial): a
     divergent preference could badge the summary "supported / URI X" while the primary opens
     nothing (or a different endpoint) — the exact #009 divergence the shared helpers prevent.
     Audit first; RED→GREEN only on a genuine divergence; no churn. Human-gated WebView/TLS
     rendering stays gated and is NOT re-split. No code touched. -->

- [x] EP-S6 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-S6 service-level capability↔primary agreement guard + RED→GREEN tests`, test-only) — added `test/features/kvm/kvm_service_capability_primary_agreement_test.dart` (3 tests): `fetchCapability(id)` ↔ `fetchPrimaryConsole()`/`pickPrimary` agree for one multi-block manager (disabled Graphical + SSH Serial w/o endpoint + secure-HTTPS Remote → same URI/session limit, both openable+secure), padded lookup keeps the agreement (RS-9), and an all-disabled manager is reported unusable on both. Audit: no existing test pinned this cross-method seam (RS-6 uses one block per manager). Real-file RED proof: `_standardConnectUri` first pass re-included the disabled Graphical → exactly the two URI-agreement tests failed (`+1 -2`, summary resolved the disabled URI while the primary stayed on secure remote); source restored byte-clean (SHA `652a5038…` unchanged, empty lib diff), 600-perm backup shredded → 3/3 GREEN. Test-only, no dependency/wire/TLS change. DISCOVERED during audit → EP-S7 above (not fixed). Originally: Service-level capability↔primary agreement for one manager: over an in-temp mockup with
      one manager exposing several console blocks (explicitly-disabled Graphical + secure-HTTPS
      Remote + serial SSH, then a variant with no openable block), pin that `fetchCapability(id)`
      and `fetchPrimaryConsole()` / `pickPrimary` agree for that manager on enablement, the resolved
      launch target and the session limit — the capability summary never advertises "supported" /
      a URI when the primary refuses to open, and the primary's URI is the one the summary resolves
      when it does open. Keep every physical manager surfaced by `fetchConsoles()` /
      `fetchCapabilities()` and all prior selection/identity/skip semantics unchanged. Audit first;
      RED→GREEN only on a genuine divergence; no wire/TLS change, no dependency.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof on a genuine divergence; writes limited to
              `lib/features/kvm/kvm_service.dart` + service tests under `test/features/kvm/`;
              emulator 85/85 only if `lib/` wire changes; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 09:53 UTC: splits a residual lookup-key seam of the blocked #009/#021
     single-manager resolution path into one unblocked, service-level, dependency-free, TLS-safe dept
     slice. RS-4/5/6/7/8 and EP-S5 pin member dedup, source identity, cardinality, hostile bodies,
     manager-Id collisions and `_managerId` derivation, but `fetchCapability(managerId)` compares the
     caller argument to `capability.managerId` verbatim while `_managerId` TRIMS body ids — a padded
     lookup argument can miss a manager that is plainly present in `fetchCapabilities()`. Nothing pins
     that the public lookup key and the derived card key use the same normalization. Audit first;
     RED→GREEN only on a genuine divergence; no churn. Human-gated WebView/TLS rendering stays gated
     and is NOT re-split. No code touched. -->

- [x] RS-9 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 RS-9 fetchCapability lookup-key normalization fix + RED->GREEN tests`, analyze 0 / 1866 passed / 1 skipped [baseline 1863 +3], lib+test) — FIXED a genuine defect:
      `fetchCapability(managerId)` compared the caller argument VERBATIM to `capability.managerId`, while every key comes from `_managerId` which trims body ids — so `fetchCapability('  PaddedBMC  ')` returned `null` for a manager plainly present via `fetchCapabilities()`. Now the lookup argument is normalized through the shared `_trimmedNonBlank` helper (blank/padded-blank short-circuit to `null`) before comparison, so padded lookups resolve the same physical manager and agree with the surfaced keys.
      `fetchCapability(managerId)` lookup-key normalization agreement with `_managerId`: over an
      in-temp mockup with padded / blank / numeric / non-string body `Id`, a padded lookup argument
      and a manager whose `Id` falls back to its `@odata.id` / member-URI segment, pin that
      `fetchCapability` resolves a manager by the SAME normalized id `_managerId` produces (argument
      trimmed, blank rejected), agrees with the ids surfaced by `fetchCapabilities()`, returns `null`
      only for genuinely unknown or blank ids, and never creates a phantom miss for a padded argument
      while both fetch methods still surface every physical manager. Audit first; RED→GREEN only on a
      genuine divergence; no wire/TLS change, no dependency.
      LANDED: audit found a LIVE divergence (genuine defect, not churn). Added `test/features/kvm/kvm_service_lookup_key_test.dart` (3 tests): (1) `fetchCapabilities()` surfaces only trimmed keys, (2) padded lookup ('  K', 'K  ', ' \tK\n ') resolves the SAME capability as the exact key across 4 derived-id shapes (padded string Id / numeric Id→@odata / blank string Id→@odata / numeric+blank @odata→member URI), (3) blank/padded-blank/unknown-padded lookups return null. Pre-fix RED: padded lookup `+2 -1` (Actual `<null>` for "  PaddedBMC"), fixed GREEN; targeted service suite 64/64. Lib diff = `kvm_service.dart` only (normalize lookup arg via `_trimmedNonBlank`, doc comment), deps unchanged, no wire/transport/fixture/TLS change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart test/features/kvm/kvm_service_manager_identity_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart`
              + service tests under `test/features/kvm/`; emulator 85/85 only if `lib/` wire changes;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 05:49 UTC: splits the remaining manager-ID uniqueness seam of the blocked
     #009/#021 manager walk into one unblocked, service-level, dependency-free, TLS-safe dept slice.
     RS-4/5/6/7 and EP-S5 pin member-URI dedup, source identity, cardinality, hostile bodies and the
     hostile-`Id` precedence, but RS-4 dedups by MEMBER URI — two DISTINCT member URIs whose bodies carry
     the SAME `Id` are not collapsed, and nothing pins that `fetchCapability(id)` deterministically
     resolves one stable capability while `fetchConsoles()` / `fetchCapabilities()` still surface every
     physical manager. A padded or blank `Id` must never become a fetchable key. Audit first; RED→GREEN
     only on a genuine divergence; no churn. No code touched. -->

- [x] RS-8 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 RS-8 manager-Id collision determinism guard + RED->GREEN tests`, analyze 0 / 1812 passed / 1 skipped [baseline 1808 +4], test-only) — Manager-Id collision determinism in `fetchCapability(id)`: over an in-temp mockup with two
      distinct member URIs whose bodies report the same trimmed `Id` (plus a manager with a blank /
      whitespace `Id`), pin that `fetchConsoles()` / `fetchCapabilities()` surface every physical manager
      without throwing or blanking the screen, that `fetchCapability(id)` deterministically returns ONE
      stable capability (first member wins, never a differing manager's), and that a blank `Id` is never a resolvable key.
      Audit first; RED→GREEN only on a genuine divergence; no wire/TLS change, no dependency. Audit found no live divergence — regression guard, not churn. Added `KvmService manager-Id collision determinism (RS-8)` group (4 tests) to `test/features/kvm/kvm_service_test.dart`. RED #1: `fetchCapability` reversed (last-wins) → determinism test failed (`+3 -1`, BMC-B instead of BMC-A); RED #2: `_managerId` returns raw blank `Id` → 3 tests failed (`+1 -3`, blank key resolvable + fallback id lost); `kvm_service.dart` restored byte-clean (SHA `bfbe6546…` unchanged, empty lib diff, 600-perm backup shredded) → 4/4 GREEN.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues), with
              RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` + service tests under
              `test/features/kvm/`; emulator 85/85 only if `lib/` wire changes;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 01:45 UTC: splits the remaining manager-identity seam of the blocked
     #009/#021 epic into one unblocked, service-level, dependency-free, TLS-safe dept slice.
     RS-4/5/6/7 pinned member dedup, console↔capability source agreement, per-manager cardinality and
     hostile manager BODIES, but none pins the manager-ID precedence itself: `KvmService._managerId`
     keys a manager by body `Id` → `@odata.id` last segment → member-URI last segment (trim/dedup),
     and that key drives `fetchCapability(managerId)`, the card identity and the downstream session /
     eviction key. A padded/blank/numeric/bool `Id`, a CRLF/blank `@odata.id`, a missing-all-sources
     manager or a member URI with a padded/percent-encoded last segment could desync the views under
     an unstable key. Audit first; RED→GREEN only on a genuine divergence; no churn. No code touched. -->

- [x] EP-S5 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-S5 manager-identity hostile-Id resolution guard + RED->GREEN tests`, analyze 0 / 1761 passed / 1 skipped [concurrent rf-gate merge +5 mid-run]) — KvmService manager-identity resolution contract (`_managerId` / `_memberUri`) under hostile
      values: feed one in-temp mockup with a padded / blank / numeric / bool `Id`, a CRLF / whitespace
      `@odata.id`, a member URI with a padded / percent-encoded last segment, and a manager missing all
      three sources, and pin that `fetchConsoles()` / `fetchCapabilities()` / `fetchCapability(id)`
      resolve one stable, trimmed, non-hostile manager id by the documented precedence, agree across
      both surfaces, and never key a manager under a whitespace/control-bearing id. Audit first,
      RED→GREEN only on a genuine divergence, no churn; no wire/TLS change, no dependency.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` +
              `test/features/kvm/kvm_service_test.dart`; no wire/TLS change.

<!-- rf-ideate split 2026-11-20 17:10 UTC: splits the remaining controller/state-machine seam of the
     #009/#021 launch-and-selection epic into one unblocked, dependency-free, TLS-safe dept slice.
     `KvmController.load()` drives the gated view's loading/error/primary state and is stubbed in
     every widget test but never tested directly; EP-S1/S2/S3 pinned selection classification and
     RS-* pinned manager-walk tolerance, not the async load state machine (in-flight guard, error
     capture, primary clearing, re-load recovery). Audit first; fix only a genuine divergence via
     RED→GREEN; no churn. The blocked in-app route (EP-S1) stays human-gated. No code touched. -->

- [x] EP-S4 LANDED 2026-11-20 (run 2026-11-20 18:00 UTC; analyze 0 / 1684 passed / 1 skipped; 8-test gated controller state-machine contract + RED proof, no lib change): KvmController.load async state-machine contract: add a dedicated controller test pinning
      that `load()` sets `loading` while the fetch is in flight, clears a prior error, selects the
      primary via `KvmService.pickPrimary` on success and clears it when the manager walk returns no
      consoles, captures a `RedfishException` message (and a generic exception) into `KvmUiState.error`
      with `loading == false` and primary cleared instead of throwing, and that a second `load()`
      while already loading is a no-op (one fetch per cycle). Audit first; fix the FIRST genuine
      divergence via RED→GREEN service tests; do not manufacture churn where the controller already
      fails closed. No dependency, no wire/transport/TLS change, no URL opened.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_controller_test.dart test/features/kvm/kvm_service_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/kvm_controller.dart` + those named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 13:04 UTC: re-scopes the still-open launch-selection edge portion of
      the #009/#021 epic (FUTUREWORK head-first candidate EP-S1) as one unblocked, dependency-free,
      TLS-safe dept slice. RS-6 pinned manager-set identity/cardinality, EP-S2 the secure-primary
      preference, RS-7 per-member hostile-body tolerance; nothing pins the full SELECTION edge matrix
      (all-disabled / mixed transport / primary tie / no-URI / control-unsafe / flag-off fallback)
      as a single launch-safe invariant agreeing with `KvmConsole.canOpenConsole`. Audit first; fix
      only a genuine divergence via RED→GREEN; no churn. No wire/transport/TLS change, no dependency.
      No code touched. -->

- [x] EP-S3 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-S3 launch-path selection contract + RED→GREEN service tests`, analyze 0 / 1610 passed / 1 skipped) — 4-test group in `test/features/kvm/kvm_service_test.dart` pinning the `KvmService.pickPrimary` selection contract: (1) the Primary badge never lands on an unopenable console while any openable one exists (mixed disabled/URI-less/external matrix); (2) table-driven tier order secure-graphical > secure-any > openable-graphical > openable-any > graphical > first (8 cases incl. secure non-graphical over plaintext graphical, disabled-secure excluded, no-openable fallbacks); (3) a CRLF-bearing HTTPS authority is not treated as a secure primary; (4) determinism + no source-list mutation. No divergence found — selection already fails closed; regression guard with RED proof: temporarily removing `if (!console.canOpenConsole) continue;` failed 3 of 4 tests (`+1 -3`, e.g. `Expected: plain / Actual: disabled-s`), restored byte-clean (SHA `bfbe6546…` unchanged, 0 probe occurrences), backup shredded → 4/4 GREEN. No `lib/`, dependency, wire/payload/fixture/TLS change. Refines EP-S1 (the broader slice stays open for the human-gated in-app-viewer portion). Launch-path selection edge matrix for #009/#021: over a matrix of manager/console shapes
      (all-disabled, mixed secure-HTTPS + plaintext-HTTP + external-client + serial, primary ties,
      no-URI OEM, control-unsafe authority, flag-off fallback) assert `KvmService.pickPrimary` /
      `fetchPrimaryConsole` deterministically pick the single launch-safe secure-HTTPS external-open
      primary — never a disabled, plaintext-HTTP or external-client-only console when a secure one
      exists — and that every primary agrees with `KvmConsole.canOpenConsole`. Consume
      `canOpenConsole` + `kvmLaunchStatusText` as the single source of truth. Fix the FIRST real
      divergence found via RED→GREEN service tests (RS-6 already pins set identity); do not
      manufacture churn where selection already fails closed. No new dependency, no wire/TLS change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              RED→GREEN proof for any fixed divergence; emulator 85/85 only if `lib/` wire changes;
              writes limited to `lib/features/kvm/kvm_service.dart` + service tests under
              `test/features/kvm/`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 09:00 UTC: splits RS-2's still-open manager-walk robustness remainder
     (per-member hostile-body tolerance) into an unblocked service invariant slice. RS-4 (dedup) and
     RS-6 (set identity/cardinality) pin happy-path/dedup behaviour; no test pins that a single hostile
     Manager body or Members entry fails closed PER manager without blanking the whole gated screen.
     In-temp mockup only, no committed fixture, no wire-shape change, dependency-free, TLS-safe;
     distinct from RS-2 (transient HTTP failures) and RS-4/RS-6. -->

- [x] RS-7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RS-7 manager-walk per-member hostile-body tolerance + RED→GREEN tests`, analyze 0 / 1575 passed / 1 skipped) — 5-test group in `test/features/kvm/kvm_service_test.dart` over an in-temp mockup (secure graphical + SSH serial survivors; a non-map LIST body wrapped by `getJson`; an all-malformed-console-block object; hostile/blank/numeric/padded `Members` entries) pinning that both views stay populated from healthy managers, malformed/non-map bodies skip per-manager without blanking the screen, primary stays deterministic + launch-safe, and `fetchCapability` resolves survivors. No divergence found — already tolerant; regression guard against future drift. RED proof: temporarily rejecting wrapped non-map / string console blocks in `_fetchManagerBodies` failed all 5 RS-7 tests (`+0 -5`); restored byte-clean (SHA `bfbe6546…` unchanged, 0 probe occurrences) → 5/5 GREEN. No `lib/`, dependency, wire/fixture/TLS change. Manager-walk per-member hostile-body tolerance invariant: `KvmService.fetchConsoles()` /
      `fetchCapabilities()` must fail CLOSED per manager — a `/redfish/v1/Managers` `Members` array
      containing non-string / blank / hostile links, and a Manager body that decodes to a non-map or
      has a malformed GraphicalConsole / SerialConsole / Oem, must yield a stable result (skip only
      the offending manager) without throwing or blanking the whole gated KVM screen; the RS-2 skip
      semantics and the wire shape stay unchanged. Add RED→GREEN service tests over an in-temp minimal
      mockup (no committed fixture); if a fixture is needed request via rf-tooling. Dependency-free,
      no production TLS behaviour change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; emulator 85/85 only if `lib/` wire changes; writes limited to
              `lib/features/kvm/kvm_service.dart` + service tests under `test/features/kvm/`;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 04:56 UTC: splits the still-open service-manager-walk remainder of
     the #009/#021 epic into one unblocked, dependency-free, TLS-safe invariant slice. RS-4 (member
     dedup) and EP-S2 (secure-primary preference) each fixed one divergence; this pins the whole
     manager-set/identity/cardinality contract across BOTH fetch methods so the KVM surfaces cannot
     disagree about how many managers exist or which console is primary. Distinct from RS-5
     (source-identity normalization) and EP-S1 (launch-strategy edge cases). -->

- [x] RS-6 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RS-6 manager-set identity/cardinality invariant + RED→GREEN tests`, analyze 0 / 1479 passed / 1 skipped) — 3-test group in `test/features/kvm/kvm_service_test.dart` over an in-temp 4-manager mockup (duplicate/padded/plain-string members, blank/non-string members, secure graphical + SSH serial + no-URI OEM + disabled graphical) pinning identical `fetchConsoles()`/`fetchCapabilities()` manager-id sets, exactly one console + one capability per manager, and a deterministic launch-safe primary (`externalBrowser`, no in-app/self-signed, exact target). RED proof: temporarily `pickPrimary → consoles.first` → `Expected: MgrGraph / Actual: MgrDisabled`; lib restored byte-clean. No `lib/`, dependency, wire/TLS change. Manager-set identity + cardinality invariant in the shared manager walk: over a matrix
      of `/redfish/v1/Managers` payloads (0/1/many managers, duplicate + whitespace-padded +
      plain-string member links, blank/non-string members, mixed graphical/serial consoles, a
      no-URI OEM console), assert `KvmService.fetchConsoles()` and `fetchCapabilities()` always
      yield the SAME set of physical managers — exactly one console and one capability card per
      manager, with matching `managerId` — and that `fetchPrimaryConsole()`/`pickPrimary` returns a
      member of that set, deterministically, never a console the fail-closed launch plan would
      refuse. Fix the first real divergence found with RED→GREEN service tests over an in-temp
      minimal mockup (no committed fixture); do not change the wire shape or the RS-2 skip
      semantics. Dependency-free, no production TLS behaviour change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; emulator 85/85 only if `lib/` wire changes; writes limited to
              `lib/features/kvm/kvm_service.dart` + service tests under `test/features/kvm/`;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the service half of the remaining cross-surface
     "control-safe manager source" portion of the open #009/#021 epic. `KvmConsole.fromManager`
     trims/normalizes the `@odata.id` via `_uriString`, but `KvmService.fetchCapability` keys its
     capability's `sourceManagerUri` straight from raw `ODataResource(manager.body).id` — so one
     padded/blank `@odata.id` yields a clean source on the console card and a raw padded one on the
     capability card for the same manager. Dependency-free, no wire-shape/TLS change; distinct from
     EP-S1 / RS-2 (still open) and from RS-4 (duplicate Members, already landed). -->

- [x] RS-5 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RS-5 console↔capability manager-source agreement + RED→GREEN tests`, analyze 0 / 1510 passed / 1 skipped) — extracted shared `kvmManagerSource*` normalizer in new `lib/features/kvm/models/kvm_manager_source.dart` (exported from `kvm.dart` barrel), used by both `KvmConsole.fromManager` and `KvmCapability.fromManager`, replacing duplicated private trim/fallback helpers so both KVM views converge on one source identity; +6 RED→GREEN tests in `test/features/kvm/kvm_service_test.dart` (RED proof: neutering the trim failed 5 tests, restored byte-clean). No lib wire/transport change, no dependency, no production TLS weakening; emulator skipped (<7 days, pure model normalization). Console↔capability manager-source agreement in the shared manager walk: make the
      `sourceManagerUri` set on `KvmService.fetchCapability` follow the same trim / blank-reject /
      fallback contract `KvmConsole.fromManager` already applies to the same `@odata.id`, so the two
      views cannot disagree about a manager's source identity. A whitespace-padded `@odata.id` must
      not leak stray whitespace into the capability card while the console card shows it trimmed;
      a blank/non-string value must use the same `/redfish/v1/Managers/<managerId>` fallback. Add
      RED→GREEN service tests comparing `fetchCapability(id).sourceManagerUri` with the matching
      `fetchConsoles()` console's normalized source over an in-temp mockup (no committed fixture).
      Do not change the Redfish wire shape or the RS-2 skip semantics; model-only normalization,
      no new helper owned by another dept (request via `_lib-requests.md` if unavoidable).
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` + service
              tests under `test/features/kvm/`; emulator 85/85 only if `lib/` wire changes; no
              dependency, no production TLS behaviour change.

<!-- rf-ideate split 2026-11-19 20:47 UTC: carves an unblocked, dependency-free manager-walk
     robustness slice out of the #009/#021 epic (distinct from RS-2's transient-failure skip and
     EP-S2's safe-primary target). No wire/TLS change, no dependency. -->

- [x] RS-4 LANDED 2026-11-19 (run `auto: FEATURE #009/#021 RS-4 manager-member dedup + tests`). Deterministic manager-member dedup in the KVM read path: `KvmService.fetchConsoles` /
      `fetchCapabilities` must tolerate duplicate and blank `@odata.id` entries in the
      `/redfish/v1/Managers` `Members` array — dedup by normalized member URI (first occurrence
      wins), skip blank/malformed ids, and never emit duplicate console/capability cards or
      throw — with RED→GREEN service tests and the existing padded/malformed-member fixtures if
      reusable. If a new fixture is needed, request it via rf-tooling. Do not change the wire
      shape or the 404/retryable/auth skip semantics established by RS-2.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` and
              service tests under `test/features/kvm/`; emulator 85/85 only if `lib/` wire changes.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 RESOLVED (external-browser + copy is the final
     render route; no WebView). New head-first, unblocked, dependency-free, TLS-safe service slice. -->

- [x] EP-S2 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-S2 pickPrimary secure-HTTPS tier-precedence guard + RED→GREEN tests`). Primary-console selection for the final external-browser route: `KvmService.pickPrimary`
      / `fetchPrimaryConsole` should prefer a secure-HTTPS console as the recommended external-open
      target and never badge a disabled, plaintext-HTTP or external-client-only console as primary
      when a secure one exists; RED→GREEN service tests. No wire/TLS change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` + service
              tests under `test/features/kvm/`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): launch-selection logic.
     Unblocked, no dependency. Every item carries the mandatory Dept:/Verify: fields
     (MULTI_DEPT hard rule #4). Legacy RS-1 is refined by EP-S1. -->

- [ ] EP-S1 Launch-path selection for the in-app viewer: `KvmLaunchStrategy` classification /
      `fetchPrimaryConsole` edge cases (all-disabled, mixed transports, primary ties, flag-off
      fallback). Consume `KvmConsole.canOpenConsole` + `kvmLaunchStatusText` as the single source
      of truth; no new dependency, no wire/TLS change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; emulator 85/85 (`tool/emulator/run_tests.sh`) only if `lib/` wire changes.

- [ ] RS-2 Manager-walk robustness follow-ups after the stale-404 fix (other non-auth failure modes,
      e.g. 5xx / timeout per member without blanking the whole gated KVM screen), with RED→GREEN
      service tests + fixture requested from rf-tooling.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` and service
              test files under `test/features/kvm/`.

## Log
- 2026-11-22 23:39 UTC — EP-S14 LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_service_zero_usable_console_agreement_test.dart` (8 tests) over an in-temp `/Managers` with four WELL-FORMED zero-usable managers (MgrEmpty no-block, MgrDisabled all-disabled URI-less, MgrUnsupported unsupported-type URI-less, MgrMalformed all-malformed) interleaved with a healthy secure-HTTPS sibling at both member positions. Pins each manager surfaced exactly once on the capability surface (RS-6/RS-8 identity), each zero-usable capability discovery-only / non-launchable (supported=false, uri=null, hasUri=false, no secure/HTTP target), no launchable console card or phantom launch target for a zero-usable manager, `fetchCapability(id)` agreeing field-for-field with `fetchCapabilities()`, a deterministic secure external-browser Primary on the healthy sibling stable across positions, and unknown/blank ids never resolving. AUDIT FIRST: agreement holds BY CONSTRUCTION (one shared walk; one capability per manager, one console per well-formed block) — no live divergence, characterization / regression lock, not churn; distinct from EP-S13 (fetch FAILURE skip) and RS-7 (HOSTILE/malformed bodies). Real-file RED: a one-sided `fetchCapabilities()` filter dropping a URI-less all-disabled manager → exactly 4 named failures (`+4 -4`), 72 sibling service tests GREEN; source restored byte-clean (SHA `653e64a6…` unchanged, 0 residue, empty `lib/` diff, 600-perm backup shredded) → 8/8 GREEN. `dart format` clean (my file); analyze 0; full 2401 passed / 1 skipped (baseline 2389 +8 mine +4 concurrent rf-gate merge 51a61a7); issues validate OK; diff --check clean; deps unchanged; lib diff empty; emulator skipped (test-only, <7 days since last green 85/85 at 21:43); no WebView/protocol import, no URL opened, no production TLS weakening. Both issues stay OPEN.
- 2026-11-22 01:29 UTC — EP-S2 LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_service_primary_secure_tier_test.dart` (5 tests) pinning the documented `KvmService.pickPrimary` tier order at the service layer — a secure-HTTPS console of ANY type (tier 2) outranks an OPENABLE plaintext-HTTP graphical (tier 3), order-independently, including a padded-but-valid HTTPS endpoint (trimmed before classification); a CRLF/spoofed "HTTPS" graphical fails closed and cannot win the secure tier; and tier 3 is preserved when no secure console exists. AUDIT: existing "safe external-browser target" tests pin secure-vs-plaintext graphical, secure-vs-external-client (non-graphical) and secure-graphical-vs-secure-non-graphical, but NONE pins secure-any-type vs openable-plaintext-graphical — swapping tiers 2/3 in the return expression passed all existing tests while badging a plaintext console Primary while a secure one existed (issue #021 invariant). Real-file RED: swapped `firstSecure`/`firstOpenableGraphical` in `pickPrimary` → exactly 3 tier tests failed (`+2 -3`, both orderings + padded), fail-closed + tier-3-preserved tests stayed green; source restored byte-clean (SHA `653e64a6…` unchanged, empty lib diff, 0 residue), 600-perm backup shredded → 5/5 GREEN. Registered in `canonicalGuardFiles` + pinned `epS2AddedGuards` (length 1, disjoint from all earlier epochs) in `test/tool/guard_suite_liveness_test.dart` (+1 pin test, completeness arithmetic updated); liveness 24/24, structural RED `+22 -2` (dropped registry entry → pin + completeness fail), restored byte-clean SHA `922bd05c…`, backup shredded. `dart format` clean (my 2 files); analyze 0; full `flutter test --concurrency=4` 2043 passed / 1 skipped (baseline 2038 +5 new); issues validate OK; diff --check clean; deps unchanged; lib diff empty; emulator skipped (test-only, no lib-wire/fixture/tool-runtime change, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. Both issues stay OPEN.
- 2026-11-21 22:51 UTC — RS-10 LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added 181-line / 3-test group `KvmService session-limit / enablement aggregate agreement (RS-10)` to `test/features/kvm/kvm_service_test.dart` over one in-temp 7-manager mockup (int / integral-double / padded-string / negative / fractional / >2^53 / disabled-vs-enabled mixed limits). Pins `fetchCapabilities()` boundary resolution, `fetchCapability(id)`↔`fetchCapabilities()` agreement, service↔`KvmCapability.fromManager` agreement from the same body, out-of-spec fail-closed, and enabled-block limit winning over a disabled block's. Audit found no live divergence — regression guard (service test had only one `maxSessions` assertion), not churn. TWO real-file RED proofs: dropped `_aggregateMaxSessions` disable-skip → MgrMixed `7` vs `3` (`+1 -2`); neutered `kvmSessionLimit` fail-closed → MgrNeg leaked `-1` (`+1 -2`); both sources restored byte-clean (SHA `533ed545…` / `8dba9db2…`), 0 residue, empty lib diff, backups shredded → 3/3 GREEN. `dart format` clean; analyze 0; full 1992 passed / 1 skipped (baseline 1989 +3); issues validate OK; diff --check clean; deps unchanged; emulator skipped (test-only, <7 days since last green 85/85); no wire/TLS/fixture/tool-runtime change, no WebView/protocol import, no URL opened, no production TLS weakening.
- 2026-11-21 17:51 UTC — EP-S7 LANDED (agent:redfish-automation, FEATURE #009/#021, lib+test): FIXED the confirmed capability-summary↔primary launch-URI divergence — added a security-first pass in `KvmCapability._standardConnectUri` (shared `isSecureHttpsConsoleUri` classifier) so a control-safe secure-HTTPS console URI wins across non-disabled blocks before the original graphical→serial→remote fallback; the capability card now resolves the same launch target as `KvmService.pickPrimary`'s "Primary" badge. New `test/features/kvm/kvm_capability_primary_uri_agreement_test.dart` (6 tests). Real-file RED 3/6 → GREEN 6/6; targeted 270/270; analyze 0, full 1949 passed / 1 skipped. No dependency/wire/TLS change.
- 2026-11-21 10:52 UTC — RS-9 LANDED (agent:redfish-automation, FEATURE #009/#021, lib+test): FIXED a genuine lookup-key normalization defect — `fetchCapability(managerId)` compared the caller argument verbatim to `capability.managerId` (always trimmed by `_managerId`), so `fetchCapability('  PaddedBMC  ')` missed a manager plainly present in `fetchCapabilities()`. Normalized the lookup argument through the shared `_trimmedNonBlank` helper (blank/padded-blank → null short-circuit) before comparison. +3 RED→GREEN tests in new `test/features/kvm/kvm_service_lookup_key_test.dart` (trimmed-key surface, padded lookup agreement over 4 derived-id shapes, blank/unknown rejection). Pre-fix RED `+2 -1` (Actual `<null>`); targeted 64/64; analyze 0 / full 1866 passed / 1 skipped (baseline 1863 +3); issues validate OK; diff --check clean; deps unchanged; lib diff = `kvm_service.dart` only. No wire/transport/fixture/TLS change; emulator skipped (pure lookup normalization, <7 days since last green 85/85). No URL opened, no WebView/protocol import, no production TLS weakening.
- 2026-11-21 06:43 UTC — RS-8 LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `KvmService manager-Id collision determinism (RS-8)` group (4 tests) in `test/features/kvm/kvm_service_test.dart` over one in-temp 3-manager mockup (two distinct member URIs BMC-A/BMC-B both `Id: "Shared"` with distinct source URIs + console endpoints, plus a manager with blank `Id` falling back to its `@odata.id` segment). Pins that both fetch methods surface all three physical managers (no throw/blank), that `fetchCapability('Shared')` deterministically returns one stable capability (first member BMC-A wins, agrees with `fetchCapabilities`), and that blank/whitespace Ids are never resolvable keys while the blank-Id manager stays reachable via its fallback. Audit found no live divergence — regression guard, not churn. RED #1: reversed `fetchCapability` iteration → determinism test failed (`+3 -1`, BMC-B instead of BMC-A); RED #2: `_managerId` returns raw blank `Id` → 3 tests failed (`+1 -3`); `kvm_service.dart` restored byte-clean (SHA `bfbe6546374f1fd896c3ed0b5fb1d4e9d13cfb397e736bc49cd2958ecc7997b7` unchanged, empty lib diff, backup shredded) → 4/4 GREEN. analyze 0 / full `flutter test` 1812 passed / 1 skipped (baseline 1808 +4); issues validate OK; diff --check clean; deps unchanged; test-only, emulator skipped (<7 days since last green 85/85), no TLS weakening.
- 2026-11-21 04:24 UTC — EP-S4-closeout dispose-after-async-gap guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_controller_dispose_guard_test.dart` (3 tests) pinning that `KvmController.load()` honours its `mounted` guard after the fetch's async gap — each test disposes the notifier mid-flight then settles the success / `RedfishException` / generic-error branch, crash-free. The EP-S4 state-machine suite drove all three branches but never disposed mid-flight, so dropping any of the three `if (mounted)` guards would let a post-dispose `state =` throw `StateError` and stay GREEN. Audit found no live divergence — regression guard, not churn. RED proof: removed all 3 guards → all 3 failed (`+0 -3`, post-dispose `StateError` at `kvm_controller.dart:90/98`); restored byte-clean (SHA `8174123e…` unchanged, empty lib diff, backup shredded) → 3/3 GREEN. analyze 0 / full `flutter test` 1774 passed / 1 skipped (baseline 1771 +3); issues validate OK; diff --check clean; test-only, deps unchanged, emulator skipped (<7 days since last green 85/85), no TLS weakening.

- 2026-11-21 03:08 UTC — EP-S5 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_service_manager_identity_test.dart` (2 tests) over one in-temp 5-manager mockup pinning the full `KvmService._managerId` precedence (`Id` → body `@odata.id` last segment → member-URI last segment, all trimmed) under hostile `Id` shapes the existing suite never covered — numeric/bool `Id` ignored → @odata.id, blank-string `Id` ignored, numeric `Id` + blank @odata.id → member-URI segment, canonical string `Id` wins over a differing @odata.id segment. Both KVM views must key the same stable, trimmed, control-free id set, no raw '42'/'true'/'false'/'   ' may become a key, and `fetchCapability(id)` resolves each. Audit found no live divergence — regression guard at a genuinely untested seam, not churn. RED proof: stringify any non-null `Id` in `_managerId` → both tests failed (`+0 -2`, raw keys leaked); restored byte-clean (SHA `bfbe6546374f…` unchanged, empty lib diff), backup shredded → 2/2 GREEN. Test-only; analyze 0 / 1761 passed / 1 skipped (pre-change baseline 1759 +2; concurrent PASS-verified rf-gate merge +5 mid-run); issues validate OK; diff --check clean; deps unchanged; emulator skipped (<7 days). No lib/TLS/dependency change.

- 2026-11-20 14:33 — RS-2 audited (agent:redfish-automation, FEATURE #009/#021, no change made): `_fetchManagerBodies` already fails closed per member on `statusCode == 404 || e.retryable` (429 / 5xx except 501 / timeout via `RedfishException.fromDioException`), and the existing `KvmService transient manager member resilience (RS-2)` test group in `test/features/kvm/kvm_service_test.dart` already pins 5xx skip on BOTH views + 401/501 propagation. No genuine transient-failure gap found, so no churn; the open RS-2 slice stays open only for a genuinely different seam (e.g. host-skip counts / retry-budget pinning) with RED→GREEN. This run landed EP-P9 instead (cross-layer authority agreement, `queues/platform.md`).
- 2026-11-19 21:26 — RS-4 LANDED (agent:redfish-automation, FEATURE #009/#021): `_fetchManagerBodies` now dedups `/redfish/v1/Managers` `Members` by normalized member URI (first wins), so repeated/padded/string-form manager links yield one console/capability card per physical manager; blank/non-string links already rejected, RS-2 skip semantics + wire shape unchanged. +2 RED→GREEN in-temp-fixture service tests (no committed fixture), analyze 0 / 1335 passed / 1 skipped, emulator 85/85. No dependency, no wire/TLS change.

- 2026-11-20 20:28 — cross-feature lifecycle parity guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): `test/features/kvm/kvm_lifecycle_parity_test.dart` (4 tests) pins that `isKvmAppBackgrounded` (`lib/features/kvm/kvm_session.dart`) agrees with `isSensorAppBackgrounded` (the #007 rule it documents mirroring) on every `AppLifecycleState` — explicit 5-state list + runtime `values` sweep, documented-semantics pin, and a source-level "same lifecycle members" check so a one-sided edit fails closed. Audit found no live divergence (both list paused/hidden/detached) — regression guard, not churn. RED proof: `hidden`→`inactive` in `isKvmAppBackgrounded` → all 4 failed (`+0 -4`); restored byte-clean, backup shredded → 4/4 GREEN. Test-only, no lib/wire/dependency/TLS change, no URL opened. analyze 0; full test green; issues validate OK; emulator skipped (<7 days since last green 85/85).

- 2026-11-22 11:16 UTC — EP-S11 LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_service_member_order_tie_test.dart` (3 tests) over one in-temp 3-manager mockup (each manager one ENABLED secure-HTTPS graphical console = three EQUALLY-ranked openable secure targets; Members deliberately hostile: padded link-map first, bare string, plain link-map, padded duplicate of BMC-A for first-occurrence dedup). Pins `fetchConsoles()` BMC member order + per-call stability, `fetchPrimaryConsole()`/`pickPrimary` resolving the FIRST equal-rank secure winner (`BMC-A`) on every repeated call, and `fetchCapabilities()`/`fetchCapability(id)` stable manager order with the winner's resolved URI byte-for-byte the primary's launch target while every physical manager keeps its own URI (RS-6/RS-8 identity). AUDIT first: EP-S2 pins tier PRECEDENCE and EP-S6 pins capability↔primary for ONE multi-block manager, but no existing test fed TWO equally-ranked secure graphical consoles in fixed BMC order — a "last secure graphical wins" refactor would move the Primary badge with every existing guard GREEN. No live divergence — regression guard, not churn. Real-file RED: changed `firstSecureGraphical ??= console; break` to `firstSecureGraphical = console` (no break) → exactly the 2 winner-determination tests failed (`+1 -2`, primary URI `c-console` instead of `a-console`), all 28 related existing guards (EP-S2/S6/security-tristate/enablement-regime/controller) GREEN; source restored byte-clean (SHA `653e64a63a52b8d2741a438daf7e77a0291c559393e5328877d41e5e8091ddd0` unchanged, 0 residue, empty lib diff), 600-perm backup shredded → 3/3 GREEN. `dart format` clean; analyze 0; full `flutter test --concurrency=4` 2155 passed / 1 skipped (baseline 2152 +3); issues validate OK; diff --check clean; deps unchanged; lib diff empty; emulator skipped (test-only, no lib-wire/fixture/tool-runtime change, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. Both issues stay OPEN. Candidate for a future `guard_suite_liveness_test.dart` epoch registration.
