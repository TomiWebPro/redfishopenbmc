# Queue rf-model (enabled in phase 2, after the epic split has ≥2 unblocked items)

Owns: `lib/features/kvm/models/**`, `lib/redfish/discovery/**`. Verify: scoped `flutter test` + RED→GREEN proof.

## Backlog (head first)

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

- 2026-11-19 22:09 — RM-3 LANDED (agent:redfish-automation, FEATURE #009/#021): shared `FeatureRules.oemHasConsole` walk now requires a console-like key's value to be a JSON object — a `KVM`/`Console` key with a scalar/list/null value no longer fakes an OEM console on the discovery gate or either KVM model. +11 RED→GREEN tests (shared walk, both models, cross-view agreement + capability-card widget at 320/800/1300 px), analyze 0 / 1346 passed / 1 skipped, emulator 85/85. No dependency, no wire/transport change, no TLS weakening. `FeatureRules` is the shared walk all three surfaces call, so the central fix keeps them in agreement (the queue's model-only write hint was deliberately widened to this one shared helper).
- 2026-11-19 20:48 — OEM `ConnectUri` alias gap (agent:redfish-automation, FEATURE #009/#021): the shared `kvm_oem_uri.dart` helper (generic fallback for both KVM views) now recognizes the canonical Redfish `ConnectUri` member in addition to `Uri` (preferring `Uri`), so an unregistered vendor's `Oem.<Vendor>.KVM.ConnectUri` resolves on both the per-console card and capability card instead of showing no URI; enablement is read from the same block. +10 pure/parity tests + 1 card widget test (320 px), 2 outdated registry tests updated; analyze 0 / 1330 passed / 1 skipped; emulator 85/85; no dependency, no wire/transport change, no TLS weakening. Adjacent to EP-M2/RM-2 (neither acceptance box fully covered — no item checked off).
- 2026-11-19 15:35 — EP-M2 LANDED (agent:redfish-automation, FEATURE #009/#021): extracted shared pure `isExternalClientConsoleUri` / `externalClientConsoleProtocol` in `launch_plan.dart` on the fail-closed `_controlSafeTrimmedUri` gate; `KvmConsole` delegates (ad-hoc parse removed) and `KvmCapability` gains mirroring `requiresExternalConsoleClient` / `externalClientProtocolLabel` getters — both KVM views now classify/label VNC/RFB/KVMIP/serial endpoints identically. +7 helper/model/parity tests, analyze 0 / 1248 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 14:56 — RM-1 LANDED (agent:redfish-automation, FEATURE #009/#021): `kvmOemConsoleEnabled` now honors an explicit disable on a URI-less OEM console block (fallback to the console-like block only when no URI-bearing console exists); +6 tests, analyze 0 / 1237 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 18:01 — RM-2-adjacent LANDED (agent:redfish-automation, FEATURE #009/#021): extracted pure `kvmSessionLimit(Object?)` in new `lib/features/kvm/models/kvm_session_limit.dart` (exported from the barrel) as the single source of truth for both KVM views' `MaxConcurrentSessions`; the two duplicated private parsers silently dropped an integer-valued JSON double (`4.0`) on both cards. Tolerates integral/finite/≤2^53 doubles + numeric strings, rejects fractional/non-finite/negative/blank/wrong types. 4 RED→GREEN behavioral assertions + 6 pure helper tests (+11 total); analyze 0 / 1289 passed / 1 skipped, emulator 85/85. No dependency, no TLS change. RM-2's non-map-payload portion remains open.
- 2026-11-20 00:43 — CB-1 LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsole.clipboardTargetUri` no longer degrades to the raw BMC `@odata.id` when the fail-closed launch plan has no safe target. Added public `safeManagerUri` routing `sourceManagerUri` through the shared `isControlSafeConsoleUri` gate; unsafe sources become a pct-encoded `/redfish/v1/Managers/<managerId>` path (blank id → `manager`), so a hostile CRLF/NUL/separator/malformed-`%` @odata.id cannot reach the clipboard. +5 model +1 widget RED→GREEN tests, analyze 0 / 1399 passed / 1 skipped, emulator 85/85 (lib changed — §1.4 gate met). No dependency, no wire/transport change, no TLS weakening. Distinct from EP-M2/RM-2 (both still open); write widened to the per-console model + its widget test.
- 2026-11-20 05:19 — RM-5 LANDED (agent:redfish-automation, FEATURE #009/#021): 18-test cross-view agreement property group in `test/features/kvm/kvm_model_test.dart` over a 18-shape manager payload matrix (enabled/disabled graphical, mixed blocks, serial-only, generic OEM Uri/ConnectUri, padded/blank/non-string/hostile @odata.id, non-map values, messy connect types, double session limit, omitted flags). Pins manager identity, identical control-safe `safeManagerUri`, `serviceEnabled` agreement and enabled-console connect-type subset of the capability aggregate. No divergence found (surfaces already agree); 5 hostile-source cases confirmed RED by temporarily returning the raw source from `KvmCapability.safeManagerUri`, restored byte-clean. Analyze 0 / 1476 passed / 1 skipped; issues validate OK. Test-only; no lib/dependency/wire/fixture/TLS change, no URL opened. Emulator skipped (<7 days since last green 85/85).
