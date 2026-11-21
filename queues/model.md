# Queue rf-model (enabled in phase 2, after the epic split has ≥2 unblocked items)

Owns: `lib/features/kvm/models/**`, `lib/redfish/discovery/**`. Verify: scoped `flutter test` + RED→GREEN proof.

## Backlog (head first)

<!-- rf-ideate split 2026-11-21 05:49 UTC: splits the last unguarded internal-consistency seam of the
     blocked #009/#021 capability aggregation into one unblocked, pure-model, dependency-free, TLS-safe
     dept slice. EP-M4/RM-1..RM-7 and the per-helper tests (unknown-enablement limit / types / URI /
     graphical-@odata.id fallback) each pin one aggregation helper in isolation, but nothing pins that
     the THREE enabled-preference helpers (`resolveLaunchUri` via `_standardConnectUri`,
     `_aggregateConnectTypes`, `_aggregateMaxSessions`) all select the SAME winning block for ONE mixed
     payload, nor the exact tri-state resolution (flag-absent "unknown" keeps priority like enabled vs
     an explicit `ServiceEnabled:false` / `Enabled:false` block being deprioritized, with the all-disabled
     fallback) and contradictory-flag (`ServiceEnabled:false` + `Enabled:true`) handling. Audit first;
     RED→GREEN only on a genuine divergence; no churn. Human-gated WebView/TLS rendering stays gated and
     is NOT re-split. No code touched. -->

- [x] RM-8 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 RM-8 enabled-block aggregation agreement guard + RED->GREEN tests`, analyze 0 / 1821 passed / 1 skipped [baseline 1817 +4], test-only) — KvmCapability enabled-block aggregation agreement across URI / connect-types / session-limit:
      feed `KvmCapability.fromManager` one matrix of manager bodies mixing flag-absent ("unknown"),
      explicitly-enabled and explicitly-disabled Graphical / Serial / Remote blocks (plus contradictory
      `ServiceEnabled` / `Enabled` flags) and pin that `resolveLaunchUri`, `connectTypes` and `maxSessions`
      all prefer the same non-disabled winning block with a consistent all-disabled fallback, and that
      `KvmConsole.fromManager` agrees for the same manager. Read-only model work; no transport/TLS
      change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_model_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/models/**` + those two named test files;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change.
      LANDED: audit found no live divergence — regression guard, not churn. The three aggregates
      (`_standardConnectUri` / `_aggregateConnectTypes` / `_aggregateMaxSessions`) each apply the
      `_explicitlyDisabled` predicate in their own preference pass; no single test pinned their AGREEMENT
      over one matrix. Added `KvmCapability enabled-block aggregation agreement (RM-8 / #009/#021)` group
      (4 tests) to `test/features/kvm/kvm_capability_test.dart`: (1) disabled graphical vs enabled remote —
      uri/types/limit all come from the remote block and `KvmConsole.fromManager`'s openable console agrees;
      (2) contradictory `ServiceEnabled`/`Enabled` flags — a truthy flag wins on all three aggregates and in
      `KvmConsole.serviceEnabled`; (3) all-disabled fallback is graphical-first across all three with no
      openable console; (4) a flag-absent (unknown) block is retained identically by all three. RED #1:
      dropped the disable-skip in `_aggregateMaxSessions` first pass → "prefer one enabled block" test failed
      (`+3 -1`, maxSessions `Expected 4 / Actual 1`, i.e. the limit leaked from the disabled graphical block);
      RED #2: `ServiceEnabled:false` forced-disabled even with truthy `Enabled` → contradictory-flag test failed
      (`+3 -1`, uri `Expected .../graph / Actual .../remote`, desyncing the aggregates from the openable console);
      `kvm_capability.dart` restored byte-clean (SHA `652a5038fa8ff0d…` unchanged, empty lib diff), 600-perm
      backup shredded → 4/4 GREEN. Test-only, deps unchanged.

<!-- rf-ideate split 2026-11-21 01:45 UTC: splits the remaining cross-view console-source parity seam
     of the blocked #009/#021 epic (RemoteConsole + explicit-disable parity) into one unblocked,
     pure-model, dependency-free, TLS-safe dept slice. EP-M1/M2 and RM-1..RM-7 pinned OEM enablement,
     session-limit, connect-type, source-identity and parser-fault isolation, but a manager exposing
     only a `RemoteConsole` (no Graphical/Serial/OEM), or one whose standard console block is
     explicitly `ServiceEnabled:false` / legacy `Enabled:false`, has no dedicated cross-view test
     proving that BOTH `KvmConsole.fromManager` and `KvmCapability.fromManager` detect, enable and
     resolve its URI identically (graphical→serial→remote precedence included). Audit first; fix only
     a genuine divergence via RED→GREEN; no churn. The human-gated WebView/TLS rendering stays gated
     and is NOT re-split. No code touched. -->

- [ ] EP-M4 RemoteConsole-only + explicit-disable cross-view detection/enablement/URI parity: feed
      both `KvmConsole.fromManager` and `KvmCapability.fromManager` one matrix of manager bodies
      (RemoteConsole-only enabled/disabled, Graphical+Remote precedence, explicitly disabled
      SerialConsole / RemoteConsole, OEM-vs-standard disable) and pin that `supported` /
      `serviceEnabled`, the resolved launch URI (graphical→serial→remote), aggregated connect types
      and launch strategy agree across the two views; a BMC-disabled standard block must fail closed
      on BOTH. Audit first, RED→GREEN only on a genuine divergence, no churn; read-only model work,
      no transport/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/models/**`;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change.

<!-- rf-ideate split 2026-11-20 17:10 UTC: splits the remaining OEM-extensibility robustness seam
     of the #009 epic (vendor parser hook) into one unblocked, pure-model, dependency-free, TLS-safe
     dept slice. `KvmOemRegistry.parse` calls a registered `KvmOemConsoleParser.parse` with no
     exception isolation, so a throwing/third-party vendor parser propagates into BOTH
     `KvmConsole.fromManager` and `KvmCapability.fromManager` and can blank/crash the KVM screen;
     RM-1..RM-7 and EP-M1/M2 pinned classification/agreement but not parser fault isolation. Audit
     first; fix only a genuine divergence via RED→GREEN; no churn. The blocked rendering/dependency/
     TLS acceptance (EP-U2/EP-P2/EP-T2/EP-P4) stays human-gated and is NOT re-split. No code touched. -->

- [x] EP-M3 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-M3 vendor-parser fault isolation + RED→GREEN tests`, analyze 0 / 1673 passed / 1 skipped, DMTF emulator 85/85) — FIXED a genuine robustness defect: `KvmOemRegistry.parse` invoked a registered third-party `KvmOemConsoleParser.parse` with no exception isolation, so a throwing parser propagated out of both `KvmConsole.fromManager` and `KvmCapability.fromManager` (and `resolveLaunchUri`) and could blank/crash the gated KVM screen. Wrapped the call in a try/catch that treats any exception as "not a console" and tries the next parser, preserving first-match order + healthy-parser enrichment + generic fallback. +5 RED→GREEN tests in `kvm_oem_registry_test.dart` (all 5 failed `+25 -5` against pre-fix code, 30/30 GREEN after). Pure model, no wire/transport/dependency/TLS change. Original item: pin that a
      registered `KvmOemConsoleParser` which throws (or returns a malformed block) is treated as
      "not a console" and skipped, so `KvmConsole.fromManager` / `KvmCapability.fromManager` fall
      back to strict generic OEM detection and never throw; a healthy parser still enriches both
      views byte-for-byte and the first-match registration order is unchanged. Audit first; fix the
      FIRST genuine divergence via RED→GREEN pure-model tests; do not manufacture churn where a
      parser already fails closed. No new helper owned by another dept (request via
      `_lib-requests.md` if unavoidable). Read-only model work; no wire/transport/TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_oem_registry_test.dart test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/models/**` + those three named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 13:04 UTC: re-scopes the still-open model URI-scheme / OEM-registry
      remainder of the #009/#021 epic (FUTUREWORK head-first candidate EP-M1) as one unblocked,
      dependency-free, TLS-safe dept slice. RM-5/RM-6 pinned enablement/session/hostile-source
      agreement and EP-M1/M2 classifier parity already landed; nothing pins that a registered custom
      `KvmOemConsoleParser` and generic vendor `Oem.*.KVM.{Uri,ConnectUri}` scheme classification agree
      across BOTH models and never bypass the shared control-safe gate. Audit first; fix only a genuine
      divergence via RED→GREEN; no churn. The genuinely blocked rendering/dependency/TLS acceptance
      (EP-U2 / EP-P2 / EP-T2 / EP-P4) stays human-gated and is NOT re-split here. No code touched. -->

- [x] RM-7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-7 cross-view OEM-registry agreement fix + RED→GREEN tests`, analyze 0 / 1617 passed / 1 skipped, DMTF emulator 85/85) — FIXED a genuine cross-view divergence: `KvmConsole.fromManager` honored a registered `KvmOemRegistry` parser but `KvmCapability.fromManager` had no registry param, so a vendor-only console (`Oem.AMI.Mgmt.EmbeddedUrl`, non-console-like key) was launchable on the card yet "not supported / no URI" on the capability card. Added optional `oemRegistry` to the capability factory + `resolveLaunchUri` (registry-authoritative OEM detection/enablement/URI, generic fallback, standard ConnectUri precedence intact) and +4 RED→GREEN tests in `kvm_oem_registry_test.dart` (agreement + 6-shape scheme matrix + disabled guard + precedence guard). RED proof: generic-only URI failed the 2 core tests (`+21 -2`), restored byte-clean (SHA `652a5038…`, 0 probes) → 24/24 GREEN. No dependency/wire/transport/fixture change, no TLS weakening. Cross-view URI-scheme + OEM-registry agreement property for #009/#021: over a matrix of
      console URI schemes (secure HTTPS, plaintext HTTP, external-client VNC/RFB/KVMIP + serial, blank,
      control-unsafe) and OEM console shapes (registered `KvmOemConsoleParser` custom vendor, generic
      `Oem.<Vendor>.KVM.Uri` / `ConnectUri`, enabled/disabled, no-URI), assert `KvmConsole.fromManager`
      and `KvmCapability.fromManager` ALWAYS agree on external-vs-HTTPS classification, protocol label
      and launch strategy, and that both route the URI through the shared control-safe gates. Fix the
      FIRST real divergence via RED→GREEN pure-model tests; do not manufacture churn where the two
      models already agree. No new helper owned by another dept (request via `_lib-requests.md` if
      unavoidable). Read-only model work; no transport/wire/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_oem_registry_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/models/**` + those three named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 09:00 UTC: splits the still-open hostile/numeric-payload remainder of
     the #009/#021 model surface. RM-5 pinned enablement + connect-type cross-view agreement; RM-2
     extracted `kvmSessionLimit` with helper-only tests — but no test pins that BOTH models resolve
     `maxConcurrentSessions` identically over a hostile numeric matrix. Pure model, dependency-free,
     TLS-safe; distinct from RM-1..RM-5 (all narrower/different contracts). -->

- [x] RM-6 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-6 session-limit cross-view agreement property + RED→GREEN tests`, analyze 0 / 1570 passed / 1 skipped) — 28-test group in `test/features/kvm/kvm_model_test.dart`: a 26-shape hostile numeric matrix (`MaxConcurrentSessions` int/integral-double/numeric-string/padded/fractional/non-finite/>2^53/negative/blank/bool/list/map/null/absent) parsed through both `KvmConsole.fromManager` and `KvmCapability.fromManager`, asserting identical resolved `maxConcurrentSessions`/`maxSessions` and spec-expected values, plus a single-session-encoding test (1 / 1.0 / '1' / '  1  ' all resolve to exactly 1 — the eviction precondition) and a disable-preference aggregation-agrees-with-openable-console test. No divergence found (both models already share the `kvmSessionLimit` parser); the group is a regression guard against future drift. RED proof: temporarily bypassing the helper in `KvmConsole._fromBlock` (int-only cast) failed 10 RM-6 tests incl. cross-view agreement; restored byte-clean (SHA `a3308faf…` unchanged, 0 probe occurrences) → 28/28 GREEN. Test-only, no `lib/` diff, no dependency/wire/TLS change; emulator skipped (<7 days). Session-limit cross-view agreement property test: over a generated matrix of
      `MaxConcurrentSessions` shapes (integer, integral double `4.0`, numeric string, padded string,
      fractional / non-finite / `>2^53` double, negative, blank, bool/list/map, absent) in both
      GraphicalConsole and capability aggregation, assert `KvmConsole.fromManager` and
      `KvmCapability.fromManager` ALWAYS report the SAME resolved `maxConcurrentSessions`, and that
      the single-session eviction contract still holds. Fix the FIRST real divergence via RED→GREEN
      pure-model tests; do not manufacture churn where the two models already agree. No new helper
      owned by another dept (request via `_lib-requests.md` if unavoidable). Read-only, no wire /
      transport / TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_session_limit_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/models/**` + those three named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 04:56 UTC: splits the still-open cross-view-agreement remainder of
     the #009/#021 epic into one unblocked, dependency-free, TLS-safe pure-model invariant slice.
     Every prior divergence (RM-1 enablement, RM-2/RM-3 non-map payloads, RM-4/CB-1 source identity,
     EP-M1/M2 classifier parity) was fixed one at a time; this pins the WHOLE console↔capability
     agreement contract over the payload matrix so a future edit cannot silently desynchronise the
     three KVM surfaces. Distinct from EP-M1/M2 and RM-1/RM-2 (all narrower single fixes). -->

- [x] RM-5 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-5 cross-view agreement property test + RED→GREEN tests`, analyze 0 / 1476 passed / 1 skipped) — 18-test property group in `test/features/kvm/kvm_model_test.dart` pinning manager identity, identical control-safe `safeManagerUri`, enablement agreement and enabled-console connect-type subset across both models over a 18-shape payload matrix (incl. hostile @odata.id); no divergence found, 5 hostile-source cases RED-proven by temporarily un-sanitizing `KvmCapability.safeManagerUri` (restored byte-clean). No `lib/`, dependency, wire/TLS change.
      Cross-view agreement property test for manager console payload normalization: over a
      generated matrix of Manager payload shapes — standard GraphicalConsole/SerialConsole blocks,
      OEM blocks (Uri / ConnectUri, registered + generic), enabled/disabled flags, padded/blank/
      non-string @odata.id, non-map console values, duplicate/blank ConnectTypes — assert
      `KvmConsole.fromManager` and `KvmCapability.fromManager` ALWAYS agree for the same manager on
      enablement (`supported`/`serviceEnabled`), normalized connect types, control-safe source
      identity, and launch classification (`launchStrategy`/`canOpenConsole`). Fix the FIRST real
      divergence found via RED→GREEN pure-model tests; do not manufacture churn where the surfaces
      already agree. Read-only model work, no wire shape change, no transport/TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof for at least one fixed divergence; writes limited to
              `lib/features/kvm/models/**` + the two named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the remaining cross-surface "control-safe manager
     source" portion of the open #009/#021 epic. CB-1 added `KvmConsole.safeManagerUri` for the CARD
     clipboard path, but `KvmCapability` still has no equivalent, so the capability card has no
     model-side single source of truth for a control-safe source display. Pure model, dependency-free,
     TLS-safe; distinct from EP-M1 / RM-2 (still open) and from CB-1 (already landed on KvmConsole). -->

- [x] RM-4 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-4 capability-side control-safe manager-source getter + RED→GREEN tests`, analyze 0 / 1408 passed / 1 skipped). Control-safe manager-source getter on `KvmCapability` (model half of the cross-surface
      source-display split): mirror `KvmConsole.safeManagerUri` — route the BMC-supplied
      `sourceManagerUri` (a `@odata.id`) through the shared `isControlSafeConsoleUri` gate. A
      control-safe source passes byte-for-byte (no valid source lost); a control-unsafe one
      (CRLF / NUL / raw space / backslash / Unicode separator / malformed-or-encoded control) degrades
      to a deterministic pct-encoded `/redfish/v1/Managers/<managerId>` path, blank/null id → `manager`.
      Keep the raw `sourceManagerUri` field itself unchanged (read-only model, no wire shape change);
      RED→GREEN pure-model tests covering safe/unsafe/null sources + hostile-id encoding + the
      capability↔console agreement for the same manager. No dependency, no transport/TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_capability_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (compile-RED: getter absent pre-fix); writes limited to
              `lib/features/kvm/models/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-19 20:47 UTC: splits the still-open non-map-payload remainder of
     RM-2 (its session-limit portion LANDED 18:01) into a fresh, unblocked, dependency-free
     model slice of #009/#021. No transport/TLS change, no dependency. -->

- [x] RM-3 LANDED 2026-11-19 (run `auto: FEATURE #009/#021 RM-3 non-map OEM console value fail-closed + tests`). Non-map payload tolerance across the KVM model read path (the open remainder of RM-2):
      `Members` entries and `GraphicalConsole` / `SerialConsole` / `RemoteConsole` / `Oem` values
      that decode to a non-map (String / num / bool / List / null) must fail closed — treated as
      absent/disabled — in `KvmConsole.fromManager`, `KvmCapability.fromManager` and any shared
      walk, never throwing a cast/NoSuchMethodError or reporting a bogus enabled/launchable
      console. Keep the already-covered per-block non-map behaviour green; add cross-view
      agreement tests so the console card and capability card never disagree for the same
      malformed manager. If a fixture is needed, request it via rf-tooling (do not write
      `test/fixtures/**`).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/models/**`.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 (platform WebView/TLS matrix) is RESOLVED —
     no embedded WebView on the available target; external-browser + copy is the final render route.
     New head-first, unblocked, dependency-free, TLS-safe dept slices of #009/#021. -->

- [ ] EP-M2 Cross-surface external-client classifier parity: ensure `KvmConsole.requiresExternalConsoleClient`
      / `externalClientProtocolLabel` (VNC/RFB/KVMIP/serial) and all `KvmCapability` transport getters
      route through the shared fail-closed gates (`isControlSafeConsoleUri` + the HTTP(S) classifiers),
      then find and fix the next ad-hoc `Uri.tryParse` with RED→GREEN tests. Read-only model work.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/models/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): dept-sized, unblocked model
     slices, head-first. Every item carries the mandatory Dept:/Verify: fields (MULTI_DEPT
     hard rule #4). Pure-model work only; no transport/TLS change, no dependency. -->

- [ ] EP-M1 Pure-model classification for the launch path: KVMIP/RFB/VNC + serial SSH/Telnet/IPMI
      external-client classification, HTTPS in-app eligibility and URI-scheme edge cases, with
      RED→GREEN tests. Read-only; no transport/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart` (incl. RED→GREEN proof) `&& flutter analyze`
              (0 issues); writes limited to `lib/features/kvm/models/**`.

- [ ] RM-1 Audit the enabled-state contract for the two views not yet audited: per-console
      `maxConcurrentSessions` chips + connection-type chips (cf. FUTUREWORK 2026-11-19 note:
      all four aggregate capability fields now skip disabled blocks; these two per-console
      views are the remainder).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart && flutter analyze` (0 issues);
              writes limited to `lib/features/kvm/models/**`.

- [ ] RM-2 Next malformed-payload tolerance gap in the KVM read path (non-map manager/console
      payloads in the capability card / manager walk), with RED→GREEN tests. If a fixture is
      needed, request it via rf-tooling (do not write `test/fixtures/**`).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart && flutter analyze` (0 issues);
              writes limited to `lib/features/kvm/models/**`.

## Log
- 2026-11-21 07:23 — RM-8 enabled-block aggregation agreement guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `KvmCapability enabled-block aggregation agreement (RM-8 / #009/#021)` group (4 tests) to `test/features/kvm/kvm_capability_test.dart`. The capability summary's three independent enabled-block preference passes (`_standardConnectUri` / `_aggregateConnectTypes` / `_aggregateMaxSessions`) were each pinned in isolation but never for AGREEMENT over one matrix or with `KvmConsole.fromManager`; a refactor with divergent predicates could desync the capability card from the launchable console while every single-aggregate test stayed GREEN. Pins (1) disabled graphical vs enabled remote → uri/types/limit all from remote + openable console agrees, (2) contradictory `ServiceEnabled`/`Enabled` truthy-wins on all three + `KvmConsole.serviceEnabled`, (3) all-disabled fallback graphical-first on all three with no openable console, (4) flag-absent (unknown) block retained identically by all three. Audit found no live divergence — regression guard, not churn. RED #1: dropped disable-skip in `_aggregateMaxSessions` first pass → "prefer one enabled block" failed (`+3 -1`, maxSessions `4`→`1`); RED #2: `ServiceEnabled:false` forced-disabled despite truthy `Enabled` → contradictory test failed (`+3 -1`, uri graph→remote); `kvm_capability.dart` restored byte-clean (SHA `652a5038fa8ff0d…` unchanged, empty lib diff), 600-perm backup shredded → 4/4 GREEN. analyze 0 / full `flutter test` 1821 passed / 1 skipped (baseline 1817 +4); issues validate OK; diff --check clean; deps unchanged; test-only, emulator skipped (<7 days since last green 85/85), no TLS weakening.

- 2026-11-21 05:39 — EP-M1 residual direct-construction `supportsKvmIp` fallback guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_capability_kvmip_fallback_test.dart` (9 tests). The documented `KvmCapability.supportsKvmIp` fallback (graphical-only bit `graphicalKvmIp == null` → scan aggregate `connectTypes` for an exact, trimmed, case-insensitive `KVMIP`) had ZERO coverage — every prior assertion went through `fromManager` where the bit is always non-null — so a `?? false` regression or dropped trim/case would stay GREEN while breaking directly constructed widget fixtures. Pins canonical/lowercase/padded-mixed-case KVMIP, among-other-types, no-KVMIP, empty list, substring near-misses + authoritative-bit precedence. Audit found no live divergence — regression guard, not churn; EP-M1 checkbox stays open (residual fallback seam). RED #1 `?? false` → 4 failed (`+5 -4`); RED #2 removed trim/case → 3 failed (`+6 -3`); restored byte-clean (SHA `652a5038…` unchanged, empty lib diff), backup shredded → 9/9 GREEN. analyze 0 / full `flutter test` 1801 passed / 1 skipped (baseline 1792 +9); issues validate OK; diff --check clean; test-only, deps unchanged, emulator skipped (<7 days since last green 85/85), no TLS weakening.

- 2026-11-21 05:00 — RS-5 residual manager-source 3-level precedence guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_manager_source_precedence_test.dart` (13 tests). The documented `kvmManagerSourceUri` contract — usable override wins, a blank/non-string override must not shadow the body's `@odata.id` fallback, both converge on the derived manager-id path — had no test at the override→fallback hand-off with a body id DISTINCT from the derived path (the lone "non-string override ignored" test used a body id equal to the derived path, so it could not tell "body fallback" from "derived fallback"), and no blank-string-override test at all. Pins all 3 levels through the pure helper and `KvmCapability.fromManager`, plus cross-view agreement. Audit found no live divergence — regression guard, not churn; RS-5 checkbox stays landed (this is a residual precedence seam). RED proof: dropped the `fallback` term in `kvmManagerSourceUri` → 6 tests failed (`+7 -6`, source identity regressed to `/redfish/v1/Managers/BMC` instead of the body id); restored byte-clean (SHA `3ade1b21…` unchanged, empty lib diff), 600-perm backup shredded → 13/13 GREEN. analyze 0 / full `flutter test` 1787 passed / 1 skipped (baseline 1774 +13); issues validate OK; diff --check clean; test-only, deps unchanged, emulator skipped (<7 days since last green 85/85), no TLS weakening.
- 2026-11-21 03:47 — RM-1 residual multi-vendor `Oem` enablement precedence guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_oem_multi_vendor_enablement_test.dart` (5 tests). `_consoleLikeBlock`'s documented rule that a flag-less metadata console-like block must not mask a real console's explicit `ServiceEnabled`/`Enabled` in a multi-vendor `Oem` payload was untested; a "return first console-like block" regression would reopen the #009 "KVM disabled on BMC" break. Pins flag-less nested/direct metadata before an explicit disable → disabled, explicit enable still wins, and both models agree on the same payload. Audit found no live divergence — regression guard, not churn; RM-1 checkbox stays open (this is the residual enablement-precedence seam, not the per-console chips item). RED proof: removed the enablement-member preference from `_consoleLikeBlock` → 3 tests failed (`+2 -3`); restored byte-clean (SHA `0bea1a6f…` unchanged, empty lib diff), 600-perm backup shredded → 5/5 GREEN. analyze 0 / full `flutter test` 1766 passed / 1 skipped (baseline 1761 +5); issues validate OK; diff --check clean; test-only, deps unchanged, emulator skipped (<7 days since last green 85/85), no TLS weakening.

- 2026-11-19 22:09 — RM-3 LANDED (agent:redfish-automation, FEATURE #009/#021): shared `FeatureRules.oemHasConsole` walk now requires a console-like key's value to be a JSON object — a `KVM`/`Console` key with a scalar/list/null value no longer fakes an OEM console on the discovery gate or either KVM model. +11 RED→GREEN tests (shared walk, both models, cross-view agreement + capability-card widget at 320/800/1300 px), analyze 0 / 1346 passed / 1 skipped, emulator 85/85. No dependency, no wire/transport change, no TLS weakening. `FeatureRules` is the shared walk all three surfaces call, so the central fix keeps them in agreement (the queue's model-only write hint was deliberately widened to this one shared helper).
- 2026-11-19 20:48 — OEM `ConnectUri` alias gap (agent:redfish-automation, FEATURE #009/#021): the shared `kvm_oem_uri.dart` helper (generic fallback for both KVM views) now recognizes the canonical Redfish `ConnectUri` member in addition to `Uri` (preferring `Uri`), so an unregistered vendor's `Oem.<Vendor>.KVM.ConnectUri` resolves on both the per-console card and capability card instead of showing no URI; enablement is read from the same block. +10 pure/parity tests + 1 card widget test (320 px), 2 outdated registry tests updated; analyze 0 / 1330 passed / 1 skipped; emulator 85/85; no dependency, no wire/transport change, no TLS weakening. Adjacent to EP-M2/RM-2 (neither acceptance box fully covered — no item checked off).
- 2026-11-19 15:35 — EP-M2 LANDED (agent:redfish-automation, FEATURE #009/#021): extracted shared pure `isExternalClientConsoleUri` / `externalClientConsoleProtocol` in `launch_plan.dart` on the fail-closed `_controlSafeTrimmedUri` gate; `KvmConsole` delegates (ad-hoc parse removed) and `KvmCapability` gains mirroring `requiresExternalConsoleClient` / `externalClientProtocolLabel` getters — both KVM views now classify/label VNC/RFB/KVMIP/serial endpoints identically. +7 helper/model/parity tests, analyze 0 / 1248 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 14:56 — RM-1 LANDED (agent:redfish-automation, FEATURE #009/#021): `kvmOemConsoleEnabled` now honors an explicit disable on a URI-less OEM console block (fallback to the console-like block only when no URI-bearing console exists); +6 tests, analyze 0 / 1237 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 18:01 — RM-2-adjacent LANDED (agent:redfish-automation, FEATURE #009/#021): extracted pure `kvmSessionLimit(Object?)` in new `lib/features/kvm/models/kvm_session_limit.dart` (exported from the barrel) as the single source of truth for both KVM views' `MaxConcurrentSessions`; the two duplicated private parsers silently dropped an integer-valued JSON double (`4.0`) on both cards. Tolerates integral/finite/≤2^53 doubles + numeric strings, rejects fractional/non-finite/negative/blank/wrong types. 4 RED→GREEN behavioral assertions + 6 pure helper tests (+11 total); analyze 0 / 1289 passed / 1 skipped, emulator 85/85. No dependency, no TLS change. RM-2's non-map-payload portion remains open.
- 2026-11-20 00:43 — CB-1 LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsole.clipboardTargetUri` no longer degrades to the raw BMC `@odata.id` when the fail-closed launch plan has no safe target. Added public `safeManagerUri` routing `sourceManagerUri` through the shared `isControlSafeConsoleUri` gate; unsafe sources become a pct-encoded `/redfish/v1/Managers/<managerId>` path (blank id → `manager`), so a hostile CRLF/NUL/separator/malformed-`%` @odata.id cannot reach the clipboard. +5 model +1 widget RED→GREEN tests, analyze 0 / 1399 passed / 1 skipped, emulator 85/85 (lib changed — §1.4 gate met). No dependency, no wire/transport change, no TLS weakening. Distinct from EP-M2/RM-2 (both still open); write widened to the per-console model + its widget test.
- 2026-11-20 05:19 — RM-5 LANDED (agent:redfish-automation, FEATURE #009/#021): 18-test cross-view agreement property group in `test/features/kvm/kvm_model_test.dart` over a 18-shape manager payload matrix (enabled/disabled graphical, mixed blocks, serial-only, generic OEM Uri/ConnectUri, padded/blank/non-string/hostile @odata.id, non-map values, messy connect types, double session limit, omitted flags). Pins manager identity, identical control-safe `safeManagerUri`, `serviceEnabled` agreement and enabled-console connect-type subset of the capability aggregate. No divergence found (surfaces already agree); 5 hostile-source cases confirmed RED by temporarily returning the raw source from `KvmCapability.safeManagerUri`, restored byte-clean. Analyze 0 / 1476 passed / 1 skipped; issues validate OK. Test-only; no lib/dependency/wire/fixture/TLS change, no URL opened. Emulator skipped (<7 days since last green 85/85).
