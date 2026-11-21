# Queue rf-tooling (epic-split support — fixtures + dependency/CI)

Owns: `test/**`, `tool/**`, `test/fixtures/**`, `.github/workflows/**`, `pubspec*`.
Never writes `lib/` product code. Verify: fixture parse tests + `flutter analyze` 0 + CI verify gate.

## Backlog (head first)

<!-- rf-ideate split 2026-11-21 09:53 UTC: closes a confirmed liveness gap in the "who guards the
     guards" suite of the blocked #009/#021 epic. EP-T14 enumerated 7 safety guards, EP-T15 extended
     to 15 with the six behavioral guards that existed at 06:07, but THREE behavioral guard files
     landed AFTER EP-T15 (`kvm_clipboard_cross_surface_agreement_test.dart`,
     `kvm_view_reload_indicator_test.dart`, `kvm_view_stale_error_banner_test.dart`) and are not in
     `canonicalGuardFiles`, so deleting / emptying / test-stripping / CI-de-invoking one of them would
     stay GREEN. Confirmed at split time: each file has live `test(`/`testWidgets(` cases (3/2/3) and
     is reachable from verify.yml's whole-tree `flutter test --coverage`. Pure test/tool,
     dependency-free, never writes `lib/`; distinct from EP-T12/14/15. No code touched. -->

- [ ] EP-T16 Guard-suite liveness extension for the post-EP-T15 regression guards: add the three
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

## Log

- 2026-11-21 01:55 UTC — EP-T14 LANDED (agent:redfish-automation, FEATURE #009/#021): extended `canonicalGuardFiles` in `test/tool/guard_suite_liveness_test.dart` from the 8 EP-T12 guards to 15 by adding the 7 post-EP-T12 safety guards (`queue_item_schema_guard_test.dart`, `production_optin_construction_guard_test.dart`, `cross_layer_authority_agreement_test.dart`, `kvm_viewer_flagoff_false_claim_guard_test.dart`, `kvm_viewer_disclosure_contract_test.dart`, `kvm_providers_test.dart`, `kvm_session_audit_invariants_test.dart`) — each verified present with live `test(...)` cases and reachable from verify.yml's whole-tree `flutter test --coverage`. Confirmed liveness gap: without the extension, deletion/emptying/test-stripping/CI-de-invocation of those guards would stay GREEN. Pinned `epT14AddedGuards ⊆ canonicalGuardFiles` so dropping a guard from the set is detected; temp-root RED→GREEN (missing/emptied/test-less → violation, intact → clean) + real-repo RED proof (stripped all test cases from `kvm_providers_test.dart` → real-repo invariant failed `NO_TEST_CASES`, `+7 -1`; restored byte-clean SHA `9460cc09…` unchanged, 600-perm backup shredded) → 8/8 GREEN. analyze 0; full `flutter test` 1746 passed / 1 skipped (baseline 1744 +2); issues validate OK; diff --check clean; deps unchanged. Test-only — no `lib/`, dependency, wire/fixture/tool-runtime or TLS change; DMTF emulator skipped (<7 days since last green 85/85).

- 2026-11-20 19:13 UTC — EP-T13 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/queue_item_schema_guard_test.dart` (13 tests), a comment-aware, dependency-free pure-Dart guard that parses every unchecked `- [ ]` item in `queues/*.md` and fails closed on a missing/duplicate/out-of-set `Dept:` or a missing/empty `Verify:` command. HTML comments are blanked (prose like "mandatory Dept:/Verify: fields" in the platform.md footer cannot cause a false positive); all 20 real unchecked items are schema-clean. Temp-root RED→GREEN (missing/duplicate/bad Dept + empty Verify → violation, valid → clean) + real-file RED proof (planted a malformed item in `queues/tooling.md` → real-repo invariant failed naming the offender `BAD_DEPT`/`EMPTY_VERIFY`, `+12 -1`; restored byte-clean SHA `342bc595…` unchanged, 0 probe artifacts, empty queues diff → 13/13 GREEN). analyze 0; full `flutter test` 1712 passed / 1 skipped (baseline 1699 +13); issues validate OK; diff --check clean; deps unchanged. Test-only — no `lib/`, wire/fixture/tool-runtime or TLS change; guard runs via `flutter test --coverage` (no second verify.yml invocation); DMTF emulator skipped (<7 days since last green 85/85).

- 2026-11-20 15:17 UTC — EP-T12 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/guard_suite_liveness_test.dart` (6 tests), a pure-Dart "who guards the guards" guard enumerating the 8 established KVM safety guard files and failing closed if any is missing, emptied, stripped of live `test(...)`/`testWidgets(...)` cases (comment/string/raw-string-aware), or unreachable from verify.yml's `flutter test --coverage`. Temp-root RED→GREEN (missing/emptied/test-less/unreachable all violation, intact clean) + real-file RED proof (emptied `notice_single_source_guard_test.dart` → `NO_TEST_CASES`, restored byte-clean SHA `b3c0e0b5…`, backup shredded) → 6/6 GREEN. analyze 0; full `flutter test` 1630 passed / 1 skipped (one transient power_view flake re-isolated 26/26 GREEN, clean rerun); issues validate OK; diff --check clean. Test-only — no `lib/`, dependency, wire/fixture/tool-runtime or TLS change; DMTF emulator skipped (<7 days since last green 85/85).

- 2026-11-20 09:13 UTC — EP-T11 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/uri_parse_single_source_guard_test.dart` (9 tests), a test-only pure-Dart guard that scans every product `lib/features/kvm/**.dart` (comment + string-literal stripping state machine) and fails closed if any file OUTSIDE the five designated shared helper files calls `Uri.parse`/`Uri.tryParse` on a BMC-supplied value or defines a duplicate of the 12 distinctive private shared control-safe/classifier helpers. 7 unit cases (raw parse/tryParse, allowlisted helper, comments/strings, duplicate helper, public-helper call, filename-not-immunity) + temp-root RED→GREEN proof + real-repo invariant. Real-file RED proof: temporarily appending `Uri.parse(...)` to `lib/features/kvm/models/kvm_models.dart` failed the real-repo invariant (`offenders: .../kvm_models.dart: raw Uri.parse/tryParse outside a designated shared helper`); restored byte-clean (SHA `a3308faf…` unchanged) → 9/9 GREEN. Only `launch_plan.dart` (allowlisted) has real `Uri.tryParse` calls. analyze 0; full `flutter test` 1528 passed / 1 skipped. No `lib/`, dependency, wire/fixture or TLS change; guard runs via `flutter test --coverage` (no second verify.yml full-suite invocation). DMTF emulator skipped (test-only, <7 days since last green 85/85).
- 2026-11-20 08:33 UTC — EP-T3 LANDED (agent:redfish-automation, FEATURE #009/#021): added `kKvmPlatformScopePrefixes` (`lib/features/kvm/platform/`) + `evaluateKvmPlatformGate()` (pure-Dart `GateResult` named `'kvm-platform'`, 75% threshold, reuses `CoverageSummary.scope()` normalization) to `tool/coverage_gate.dart`, folded into `evaluateAllGates()` as a 4th enforced gate so the security-critical fail-closed classifier/decision layer cannot be diluted by the wide KVM aggregate. +6 tests in `test/tool/coverage_gate_test.dart` (29/29): platform-only 75% scoping, a fully-covered KVM aggregate cannot mask a 0% platform file, custom threshold/prefix, absolute+Windows paths, empty-scope fails closed, and 4-gate `evaluateAllGates`/CI-JSON shape. RED proof: temporarily scoping the gate to all of `lib/features/kvm/` failed 6 tests (`linesFound Expected: <100> / Actual: <400>`; the masked-adapter test expected `passed:false` but saw the 75% aggregate pass); restored byte-clean (SHA `f93a2e14…` unchanged) → 29/29 GREEN. Gate CLI on real lcov: PASS overall 90.1% / scoped 90.4% / kvm 96.8% / kvm-platform 99.6%, exit 0. Docs updated: DEVELOPMENT.md, MULTI_DEPT.md, verify.yml comment (four gates now). No product `lib/`, dependency, wire/fixture change, no production TLS weakening. DMTF emulator skipped (tool/test-only change; <7 days since last green 85/85).
- 2026-11-20 — EP-T10 LANDED (agent:redfish-automation): added `test/fixtures/redfish/openbmc_console_manager.json` (valid Redfish `Manager.v1_19_0` BMC: HTML5-over-HTTPS GraphicalConsole + disabled serial + HTML5 RemoteConsole + `Oem.OpenBMC.KVM.Uri`) and `test/features/kvm/kvm_openbmc_fixture_test.dart` (10 tests) driving `KvmConsole.fromManager` / `KvmCapability.fromManager` over it — console enumeration, launch-safe graphical plan, disabled/OEM/remote paths, capability aggregation + cross-view agreement, mutation sensitivity. RED proof: corrupting the graphical ConnectUri to plaintext HTTP failed 3 drive tests; restored byte-clean. No `lib/`, dependency, wire or TLS change; analyze 0 / 1492 passed / 1 skipped.
- 2026-11-19 — EP-T6 LANDED (agent:redfish-automation): added `tool/unattended_guard.dart` (pure-Dart unattended-safety policy evaluator + CLI) enforcing three invariants at commit/CI time: (1) every `test_integration/**.dart` gates network on `String.fromEnvironment('REDFISH_EMULATOR_URL')` AND calls `markTestSkipped` when absent; (2) no plain `test/**.dart` references the emulator env var (`test/tool/` guard self-tests exempt); (3) no production `lib/**.dart` hard-enables `allowSelfSigned: true`. `test/tool/unattended_guard_test.dart` adds +15 RED→GREEN tests; CLI RED proof (ungated integration test in a temp dir) produced a violation + exit 1; real-repo CLI scan green (286 Dart sources). Wired into `.github/workflows/verify.yml` + documented the live-BMC human opt-in in `DEVELOPMENT.md`. No `lib/` change, no dependency, production TLS untouched.
- 2026-11-19 — LA-1 LANDED (agent:redfish-automation): added `tool/asset_guard.dart` (pure-Dart large/binary asset policy evaluator + CLI) and `tool/asset_manifest.json` (path + byte size + SHA-256 + source URL for the mirrored DSP0266 PDF and the schema index). Any binary asset over 1 MiB without a manifest entry, or with size/hash drift, fails closed (exit 1); malformed manifests fail closed (exit 2). +15 RED→GREEN pure-Dart tests in `test/tool/asset_guard_test.dart` (synthetic unlisted large binary → violation; size/hash drift; path normalization; manifest validation; real-repo manifest coverage), RED proof via a temp-dir large binary. Wired into `.github/workflows/verify.yml` + documented the "ask a human before committing large assets" gate in `DEVELOPMENT.md`. No `lib/` change, no dependency, production TLS untouched. analyze 0; full suite green.

- 2026-11-20 — EP-T9 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/launch_status_single_source_guard_test.dart` (6 tests), a test-only pure-Dart guard that derives the seven `kvmLaunchStatusText` launch-status a11y messages FROM `kvm_models.dart` at test time and fails closed if any other product `lib/features/kvm/**.dart` hardcodes one of those fragments (card↔viewer visible-text/announced-label copy drift) or redefines the shared function; also pins both launch surfaces call the shared function. Complements the RU-2 notice guard (which covers only the six shorter notice constants). 2 RED + 2 GREEN proofs, real-repo scan clean (RU-2 notice authority excluded as another copy authority); analyze 0 / 1454 passed / 1 skipped. No `lib/`, dependency, wire/fixture change, no production TLS weakening. DMTF emulator skipped (test-only, <7 days since last green 85/85). EP-T9 is a newly discovered tooling closeout slice for the still-open #009/#021 epic (RU-2 single-source invariant extended to the launch-status strings).
