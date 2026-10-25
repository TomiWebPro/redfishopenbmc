# Automation Tracking

Append-only run log for the `redfish-automation` scheduler job.

- **Repo:** `/home/tomi/redfishopenbmc`
- **Schedule:** every 5 hours (`0 */5 * * *`) via `~/opencode-scheduler/scheduler.py`
- **Model:** `opencode/deepseek-v4.1-flash-free` (agent: `build`, `--auto`)
- **Timeout:** 7200s per run
- **Runbook:** `.opencode/skills/redfish-automation/SKILL.md`
- **Queue:** `FUTUREWORK.md`
- **Detailed specs:** `issues/open/` (local tracker only — never GitHub Issues)
- **Progress contract:** `DEVELOPMENT.md` + `progress/journal.md`

## Run log conventions

- New entries are appended at the **end** (oldest first), one section per run.
- Use `## YYYY-MM-DD HH:MM — MODE` as the heading, where MODE is one of
  `DOCS`, `EMULATOR`, `REPAIR`, `FEATURE`, `UI`, `REFACTOR`, or `SETUP`.
- Record baseline, work done, files touched, verification, commit hash, push
  status, and the next three actions. If something was reverted, say why.
- Do not rewrite old entries. Corrections go in the newest entry.

---

## 2026-10-21 14:50 — SETUP (assistant)

- **Baseline:** `flutter analyze` 0 issues; `flutter test` 231 passed / 1 skipped;
  `python3 issues/issues.py validate` OK; branch `main` clean at `1b56e14`.
- **Created:** `.opencode/skills/redfish-automation/SKILL.md` (runbook),
  `FUTUREWORK.md` (queue), `documentations/external/README.md` (docs mirror policy),
  and this tracking file.
- **Scheduled:** `redfish-automation` job, model `opencode/deepseek-v4.1-flash-free`,
  agent `build`, `--auto`, timeout 7200s, cron `0 */5 * * *`.
- **Guardrails:** analyze/test must stay green; docs and emulator work alternate;
  every green run should land one small UI/test improvement; push only after checks.
- **Next:** run 1 starts with the official docs scout, then alternates with the
  DMTF mockup-server emulator harness.

<!-- APPEND NEW RUNS BELOW THIS LINE, OLDEST FIRST -->

## 2026-10-21 15:00 — SETUP (assistant)

- **Baseline:** analyze 0; tests 231 passed / 1 skipped; starting commit 1cc0f01.
- **Primary work:** fixed the broken agent chain found during setup review.
- **Chain audit:** the scheduler implements "agent" only by prepending "FIRST read
  and follow `/home/tomi/redfishopenbmc/.opencode/agents/build.md`" to the prompt —
  that file did not exist, so the run's first instruction pointed at nothing.
  `.opencode/agents/development-agent.md` was also stale (wrong path
  `/home/tomi/projects/redfishopenbmc`, phantom jobs, "DO NOT push" contradicting
  the runbook).
- **Changes:** created `.opencode/agents/build.md` (agent protocol; runbook is
  authoritative); fixed `development-agent.md` paths, model, push policy, job
  table, and auth notes (credential store, no embedded PAT).
- **Verification:** analyze 0; tests 231 passed / 1 skipped; issues validate OK.
- **Commit:** pending — pushed as part of the setup series.
- **Next:** first real automation run at next 5h tick; quota on deepseek-free
  should have cleared.

## 2026-10-22 12:44 — DOCS

- **Baseline:** analyze 0; tests 231 passed / 1 skipped; starting commit 9fd38dc;
  issues validate OK; branch `main` clean.
- **Primary work:** DOCS-1 — established the official-docs mirror under
  `documentations/external/redfish/` (fresh queue, first DOCS run).
- **Docs:** pulled and verified (curl `-sSIL` 200 on every source):
  - DSP0266 1.25.0 PDF from `www.dmtf.org` (1,243,359 bytes,
    `385ee6d0...82149`) → `redfish/spec/`.
  - bmcweb `Redfish.md` (25,689 B), `REDFISH_CHECKLIST.md` (1,761 B),
    `OEM_SCHEMAS.md` (5,687 B) at upstream commit `0128851e` → `redfish/openbmc/`.
  - Redfish-Mockup-Server README (7,318 B) at commit `23d21f9a` → `redfish/mockup/`.
  - Full DMTF schema index listing (3,448,133 B, 14,259 JSON/YAML entries)
    → `redfish/schemas/v1-index.html`.
  - 16 base aggregator schemas (ServiceRoot, ComputerSystem, Chassis, Sensor,
    Power, Thermal, SessionService, AccountService, UpdateService,
    SoftwareInventory, EventService, Manager, LogService, EthernetInterface,
    TaskService, MessageRegistry; 106,322 B total) → `redfish/schemas/v1/`.
  - Total new downloads ≈ 4.8 MB (well under the 50 MB run budget; no file over
    25 MB). Manifest table + SHA-256s updated in `documentations/external/README.md`;
    upstream anchors re-verified with commits.
  - Created `documentations/external/redfish/REQUIREMENTS.md` — 14-row
    requirement→code→test→status trace. 9 requirements OK (tested), 4 GAP rows
    already tracked (#016 PATCH/ETag, #008/#020 tasks, event subscription not yet
    filed, session URI #015), vendor rows cited to bmcweb.
- **Emulator:** none this run (DOCS run).
- **Code/tests:** no production code changes from docs; trace table links to
  existing code + tests.
- **UI:** UI-2 accessibility increment — `HealthBadge` / `PowerBadge` now wrap
  the chip in `Semantics(label: 'Health <x>' / 'Power <x>')` so screen readers
  announce state, and `HealthBadge` uses a distinct icon per state
  (`warning_amber_rounded` for warning, `help_outline` for unknown) instead of
  a generic error icon. Added 2 widget tests
  (`test/features/systems/ui_widget_test.dart`): semantics labels + per-state
  icons. Also touched `documentations/redfish_reference/README.md` provenance
  note pointing to the new live corpus (DOCS-2 partial).
- **Verification:** analyze 0; tests 233 passed / 1 skipped; issues validate OK;
  `git diff --check` clean; secret scan clean.
- **Commit:** c8dc7e1 — `auto: DOCS — official docs mirror (DSP0266, bmcweb, schemas, REQUIREMENTS) + badge a11y (run 2026-10-22 12:44)`; pushed: **no** — `git push origin main` failed with `fatal: could not read Username for 'https://github.com': No such device or address`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine. Local commit kept; not retried (runbook failure handling). Verify `git ls-remote origin refs/heads/main` vs `c8dc7e1` next run.
- **Next:** 1) EMULATOR run — stand up Redfish-Mockup-Server over HTTPS and add
  `test_integration/emulator/` tests (EMU-1/EMU-2); 2) DOCS-2 refresh the
  `test/fixtures/redfish/` + `redfish_reference` snapshot against the verified
  upstream commits; 3) DOCS-3 continue DSP0266 audit — file the event
  subscription gap (EventService/Subscriptions) as a new FUTUREWORK item.

## 2026-10-22 14:01 — EMULATOR

- **Baseline:** analyze 0; tests 233 passed / 1 skipped; starting commit 0c526fa;
  issues validate OK; branch `main` clean (ahead 2 of origin: c8dc7e1 + 0c526fa
  still unpushed from the DOCS run — push blocked, no GitHub credentials).
- **Primary work:** EMU-1..EMU-4 — stood up the official DMTF
  Redfish-Mockup-Server over HTTPS and added an end-to-end integration suite
  under `test_integration/emulator/`.
- **Emulator:**
  - Cloned `DMTF/Redfish-Mockup-Server` at pinned commit `23d21f9a` to `/tmp`;
    generated a short-lived self-signed cert (`/CN=127.0.0.1`,
    SAN IP:127.0.0.1/DNS:localhost); served `test/fixtures/redfish/dmtf_mockup`
    on `https://127.0.0.1:8443` with `-S` (short-form fixture, no top-level
    `redfish/` dir — verified `-S` is correct).
  - Health-checked `GET /redfish/v1/` (200). Probed: session POST mints
    `X-Auth-Token` + `Location`; Basic auth 200; `ComputerSystem.Reset` action
    204; unknown resource/action → 404 surfaced to Dio as `badResponse`
    (mockup closes the TLS connection abruptly, but the status line arrives so
    error mapping sees `statusCode: 404`).
  - New `test_integration/emulator/emulator_suite_test.dart` (11 tests):
    service-root discovery, DiscoveryEngine BFS + full feature map, sensors
    (Thermal temps/fans), firmware inventory (3 entries), KVM graphical
    console, session auth (token mint + reuse + logout), basic auth, power
    state read, reset action accepted, and 404 error mapping for unknown
    resource + unknown action. Reads
    `String.fromEnvironment('REDFISH_EMULATOR_URL')` and `markTestSkipped`s
    when absent — plain `flutter test` never requires the emulator.
  - New `tool/emulator/run_tests.sh` (EMU-4): pins upstream commit `23d21f9a`,
    clones/venvs/certs under `/tmp` only, starts the server, waits for health,
    runs the suite, stops the server via `trap`. Verified end-to-end; trap
    cleanup confirmed (no stray process after run).
- **Docs:** added an "Emulator harness" section to
  `documentations/external/README.md` (pin, isolation, TLS note) and a
  "Test platforms" note to `documentations/external/redfish/REQUIREMENTS.md`
  describing the two integration layers (in-process mock + real emulator).
- **Code/tests:** power view `ConfirmResetDialog` (UI-5) — destructive actions
  now show clearer warning copy ("may interrupt service; unsaved work on the
  host could be lost") and the confirm button carries a `Semantics` label
  "Confirm <action> (destructive)" (UI-2 tie-in). Non-destructive dialog copy
  unchanged. New widget test covers the destructive copy + semantics label.
  Files: `lib/features/power/views/power_view.dart`,
  `test/features/power/power_view_test.dart`.
- **UI:** one small tested increment landed (see above); `dart format` on the
  touched files only. Note: a repo-wide `dart format` would touch ~54 files
  (repo not fully format-clean; a reformat of `kvm_view.dart` would introduce
  a `curly_braces` lint) — kept the diff focused and did not commit format
  churn; formats stay a FUTUREWORK P2 item.
- **Verification:** analyze 0; tests 234 passed / 1 skipped; issues validate
  OK; `git diff --check` clean; secret scan clean.
- **Commit:** 81dfb8f — `auto: EMULATOR — DMTF mockup-server HTTPS harness + test_integration suite (EMU-1..4) + power dialog a11y (run 2026-10-22 14:01)`; pushed: **no** — `git push origin main` failed with `fatal: could not read Username for 'https://github.com': No such device or address` (same blocker as the DOCS run; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine). Local commit kept; not retried. 3 commits now queued locally: c8dc7e1 (DOCS), 0c526fa (chore), 81dfb8f (EMULATOR).
- **Next:** 1) Re-attempt `git push origin main` from a machine with GitHub
  credentials (2 commits queued: c8dc7e1 DOCS + this EMULATOR commit); 2)
  DOCS-3 continue DSP0266 audit — decide EventService/Subscriptions scope
  (DOCS-7); 3) P1 repair: #014 RedfishError ExtendedInfo parsing (requires
  emulator fixtures richer than the static mockup), or EMU-3 extension:
  assert client error mapping for 405/501 actions if a richer emulator is
  added (EMU-5 evaluation).


## 2026-10-22 16:10 — DOCS

- **Baseline:** analyze 0; tests 234 passed / 1 skipped; starting commit ed2e943;
  issues validate OK; branch `main` clean but ahead 4 of origin (c8dc7e1 DOCS,
  0c526fa, 81dfb8f EMULATOR, ed2e943 — all unpushed, GitHub push blocked: no
  credentials, see earlier entries).
- **Primary work:** DOCS-3 + DOCS-7 — audited DSP0266 1.25.0 Eventing (§12.1)
  and Asynchronous operations / TaskService (§12.2) against the client's
  task/event behaviour; made and recorded the DOCS-7 event-subscription scope
  decision. Also landed a small tested UI increment (UI-3).
- **Docs:**
  - Corrected stale citations in `REQUIREMENTS.md`: Eventing was cited as §14
    (wrong — it is DSP0266 §12.1 "Eventing", PDF p.157–161) and Tasks as §13.4
    (wrong — §12.2 "Asynchronous operations", p.162–164). Both fixed; grep
    confirms no other wrong §14/§13.4 references remain in the repo.
  - Added 5 REQUIREMENTS rows: event subscription lifecycle (POST → 201 +
    `Location`, DELETE to unsubscribe, §12.1.1–§12.1.2), SSE
    `ServerSentEventUri` (§12.1.3), EventType deprecation + RegistryPrefix/
    ResourceType/MessageIds filtering (§12.1.4–§12.1.5, note for future impl),
    task-monitor polling contract (202 + `Location` + `Retry-After`; GET monitor
    202-while-running then final body; DELETE cancel; 404/410 after completion,
    §12.2 — client reads `Location` but does not poll: Partial/GAP #008/#020/
    #022), plus two bmcweb vendor rows (EventService + TaskService field sets,
    cited `Redfish.md` §EventService/§TaskService @ `0128851e`).
  - DOCS-7 decision recorded in REQUIREMENTS.md "DOCS-7 decision" section:
    **event subscriptions/SSE out-of-scope this milestone** — no event consumer
    (telemetry + firmware/power tasks are poll-based), no SSE transport in
    `pubspec.yaml`, no push-capable test bed (static mockup cannot push; richer
    emulator EMU-5 or live BMC needed). Revisit when #007/#019/#008/#020/#022
    lands. No new downloads this run (0 bytes — corpus budget untouched).
- **Emulator:** none this run (DOCS run).
- **Code/tests:** no production code changes (docs audit only — remaining gaps
  are tracked code issues #016/#008/#020/#022).
- **UI:** UI-3 first slice — added a "responsive layout" widget-test group to
  `test/features/power/power_view_test.dart` asserting PowerView renders without
  overflow at 320 / 800 / 1300 px logical widths (sets `tester.view.physicalSize`
  + `devicePixelRatio` 1.0, asserts `takeException()` null, verifies the power
  UI still renders). +3 tests. Note: repo-wide `dart format` still churns ~50
  files and reintroduces the pre-existing `curly_braces` lint in `kvm_view.dart`
  — kept the diff focused (formatted only the touched test file), consistent
  with the EMULATOR-run precedent; repo-wide format stays a FUTUREWORK P2 item.
- **Verification:** analyze 0; tests 237 passed / 1 skipped; issues validate OK;
  `git diff --check` clean; secret scan clean (no tokens/credentials in diff).
- **Commit:** 980189f — `auto: DOCS — DSP0266 §12.1/§12.2 eventing+tasks audit, DOCS-7 decision, PowerView breakpoint tests (run 2026-10-22 16:10)`; pushed: **no** — `git push origin main` failed with `fatal: could not read Username for 'https://github.com': No such device or address` (same GitHub credential blocker as the previous 4 commits — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key). Local commit kept; not retried. 5 commits now queued locally: c8dc7e1, 0c526fa, 81dfb8f, ed2e943, 980189f.
- **Next:** 1) Push the 4 queued local commits (c8dc7e1, 0c526fa, 81dfb8f,
  ed2e943 + this one) from a machine with GitHub credentials; 2) P1 code:
  #014 (RedfishError ExtendedInfo parsing) or #015 (AuthManager session URI
  discovery) — unit-level work with the in-process mock server; 3) EMU-5
  evaluation if 403/409/400 extended-info paths are needed for #014/#015 tests.

## 2026-10-22 15:56 — EMULATOR + #014

- **Baseline:** analyze 0; tests 237 passed / 1 skipped; starting commit be910ff;
  issues validate OK; branch `main` clean but ahead 6 of origin (6 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** EMU-5 evaluation (richer emulator decision) + P1 #014
  RedfishError envelope parsing fix. Chose EMULATOR over DOCS because the last
  two entries were DOCS/EMULATOR alternating and EMULATOR had gone longest; the
  P1 #014 fix is the code work the error-path story needs.
- **Emulator:**
  - Evaluated `DMTF/Redfish-Interface-Emulator` @ `5f51d8a` (tag 1.2.2):
    cloned, venv-installed, ran on :8444. It serves a dynamic service
    (Systems System-1..7, Chassis, TaskService) and returns **400** for an
    invalid `ResetType` (dynamic 4xx the static mockup cannot produce).
  - **Decision: stay on Redfish-Mockup-Server** (EMU-5 closed, marked `[x]`).
    Reasons recorded in `REQUIREMENTS.md` "EMU-5 decision": (1) the richer
    emulator's error bodies are non-conformant — `{"error":"msg"}` with no
    DSP0266 `error` envelope / `@Message.ExtendedInfo`, and `emulator.py`'s
    `error_response` uses a `{"Status","Message"}` shape; (2) its
    SessionService 404s on `POST /redfish/v1/SessionService/Sessions` and
    self-describes under `/rest/v1/...` — auth coverage would regress; (3)
    error mapping is better tested with spec-conformant unit fixtures than
    with another HTTP layer. Pin recorded; no harness committed.
  - Ran `tool/emulator/run_tests.sh` end-to-end (11 emulator tests) — all
    passed; `trap` cleanup confirmed (no stray mockup-server process).
- **Code/tests:** P1 **#014 closed** — `RedfishError.fromJson` now self-descends
  into the DSP0266 `error` envelope (`{"error":{"code","message",
  "@Message.ExtendedInfo"}}`), falling back to top-level keys for lenient
  interop; `RedfishException.fromResponse` normalizes any map-shaped body
  (String- or dynamic-keyed) and lets `RedfishError.tryParse` handle the
  envelope (removed the dead lowercase dynamic-keyed branch). Files:
  `lib/redfish/models/redfish_error.dart`, `lib/redfish/models/
  redfish_exception.dart`. Tests: `test/redfish/models/models_test.dart`
  (envelope + top-level-noise cases), `test/redfish/client/auth_manager_test.dart`
  (full-body `fromResponse` with `@Message.ExtendedInfo` diagnostics;
  `firstMessage` prefers `ExtendedInfo[0]`).
- **UI:** UI-2/UI-5 increment — reset buttons now carry a `Semantics` label
  "«action», action in progress" while `actionInFlight` (and are already
  disabled); 2 new widget tests in `power_view_test.dart` (busy announced +
  idle has no busy semantics; busy test uses bounded pumps because the spinner
  animates forever). Production: `lib/features/power/views/power_view.dart`.
- **Docs:** `REQUIREMENTS.md` gained the "EMU-5 decision" section (evaluation,
  reasons, fallback, pin `5f51d8a`).
- **Verification:** analyze 0; tests 242 passed / 1 skipped; issues validate
  OK; `git diff --check` clean; secret scan clean.
- **Commit:** 9041bc5 — `auto: EMULATOR + P1 — EMU-5 decision (stay on mockup-server), #014 RedfishError envelope parsing, busy-state button a11y (run 2026-10-22 15:56)`; pushed: **no** (same GitHub credential blocker: `fatal: could not read Username for 'https://github.com': No such device or address`; no credential helper / env token / SSH key on this machine; local commit kept, not retried). 7 commits queued locally (c8dc7e1, 0c526fa, 81dfb8f, ed2e943, 980189f, be910ff, 9041bc5).
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (7 queued); 2) P1 #015 AuthManager (authMethod, safe logout URI,
  session reuse/expiry) — unit-level with in-process mock server; 3) #027:
  close the stale toolchain issue with evidence (baseline green every run);
  or UI-5: busy state on the ConfirmResetDialog confirm button.

## 2026-10-22 18:54 — DOCS

- **Baseline:** analyze 0; tests 242 passed / 1 skipped; starting commit f9dfc25;
  issues validate OK; branch `main` clean but ahead 8 of origin (8 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** DOCS-4 — bmcweb feature-detection diff audit
  (`Redfish.md` / `REDFISH_CHECKLIST.md` / `OEM_SCHEMAS.md`) against
  `FeatureRules`, plus the KVM `Oem` false-positive fix that the audit surfaced,
  plus a small UI-3 increment (SensorsView breakpoint tests) and P1 #027 close
  with evidence.
- **Docs:**
  - Audit findings recorded in REQUIREMENTS.md (new "DOCS-4" section + 5 vendor
    rows): (1) bmcweb firmware update is HTTP-push via `HttpPushUri` /
    `MultipartHttpPushUri` — no `SimpleUpdate`, our `startSimpleUpdate` would
    405 on OpenBMC (→ #008/#020); (2) bmcweb reset types come from
    `ResetActionInfo` ActionInfo `Parameters/AllowableValues`, not system
    `SupportedResetTypes` (→ #022/#016 fallback); (3) bmcweb serial console
    lives on the ComputerSystem, not the Manager (→ #009/#021); (4) vendor rows:
    `AccountService.Oem.OpenBMC.AuthMethods.*` (#015/#026), `TelemetryService`
    (#007/#019). `REDFISH_CHECKLIST.md` is contributor-process only — no
    client-facing fields. No new downloads (corpus already mirrors bmcweb @
    `0128851e`; audit-only, 0 bytes).
- **Emulator:** none this run (DOCS run).
- **Code/tests:**
  - KVM `Oem` false-positive fixed: `FeatureRules.oemHasConsole` (public,
    depth ≤ 3, console-like keys) replaces the "any `Oem` map" rule in
    `_managerConsoleType` and `KvmConsole.fromManager`
    (`lib/redfish/discovery/feature_rules.dart`,
    `lib/features/kvm/models/kvm_models.dart`).
  - Tests: +2 `feature_rules_test.dart` (bare-Oem rejected, `Kvm` marker
    accepted), +2 `kvm_model_test.dart` (bare-Oem rejected, `Kvm` marker
    accepted).
  - **#027 closed** (P1 chore) with evidence — toolchain resolved to
    `~/flutter/bin/flutter`, analyze 0 / tests green every run since DOCS-1, no
    orphaned flutter_tester from this repo; DEVELOPMENT.md Toolchain documented.
- **UI:** UI-3 extended — SensorsView responsive-layout tests at 320/800/1300 px
  (+3 tests in `sensors_widget_test.dart`, same `pumpAtWidth` pattern as
  PowerView); no production change (layout already wraps; regression protection
  added).
- **Verification:** analyze 0; tests 249 passed / 1 skipped; issues validate
  OK; `git diff --check` clean; secret scan clean (only
  `estimated_tokens`/comment false positives).
- **Commit:** 68aefba — `auto: DOCS — DOCS-4 bmcweb diff audit, KVM Oem false-positive fix, #027 close, SensorsView breakpoint tests (run 2026-10-22 18:54)`; pushed: **no** — GitHub push blocked by missing credentials (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine), same as the 8 prior commits; local commit kept, not retried.
- **Next:** 1) Push the queued local commits (8 + this one) from a machine with
  GitHub credentials; 2) P1 #015 AuthManager (authMethod, safe logout URI,
  session reuse/expiry) — unit-level with in-process mock server; 3) #016/#022:
  `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020: bmcweb
  HTTP-push firmware upload path.

## 2026-10-22 17:38 — EMULATOR

- **Baseline:** analyze 0; tests 249 passed / 1 skipped; starting commit c971745;
  issues validate OK; branch `main` clean but ahead 9 of origin (9 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** EMULATOR — re-verified the pinned DMTF Redfish-Mockup-Server
  suite end-to-end (13/13 pass over HTTPS, trap cleanup confirmed) and extended
  the suite with two tests that close the "systems" and firmware-push gaps:
  ComputerSystem inventory-detail + HTTP-push URI exposure.
- **Emulator:** ran `tool/emulator/run_tests.sh` twice (once pre-work to confirm
  an 11-test baseline, once post-change) — all green, no stray server process
  left, port 8443 closed after each run. Added `systems: ComputerSystem exposes
  full inventory fields` (Model `3500`, Manufacturer `Contoso`, SerialNumber
  `437XR1138R2`, PowerState `On`, `Status` OK, and `#ComputerSystem.Reset`
  `target` + `ResetType@Redfish.AllowableValues` present) and `firmware:
  UpdateServiceInfo exposes the HTTP-push URI (DOCS-4)` (asserts
  `httpPushUri == '/FWUpdate'` through the real `FirmwareService`, tying
  DOCS-4's bmcweb HTTP-push finding to an emulator-level assertion for
  #008/#020). Emulator suite now 13 tests.
- **Code/tests:** no production logic change from the emulator work; UI-5 landed
  (below); `REQUIREMENTS.md` trace notes updated (emulator test count 13 +
  inventory/push coverage; the bmcweb HTTP-push row now cites the emulator
  assertion).
- **UI:** UI-5 completed — `ConfirmResetDialog` is now stateful and owns the
  in-flight state: the confirm button disables + shows a spinner while the
  reset request is pending, Cancel disables too, the dialog is
  `barrierDismissible: false` so it cannot vanish mid-flight, and a Semantics
  "«action», action in progress" label is announced (mirrors the reset-button
  busy pattern). `PowerView._confirmAndRun` passes `controller.reset(action)`
  as `onConfirm`; the dialog only pops after the request resolves, so the
  snackbar outcome is unchanged. Tests: +2 in `power_view_test.dart` (deferred
  gate: confirm disabled + spinner + cancel disabled + busy semantics while a
  reset is pending, then dialog closes on release; failing service: dialog
  closes and both inline error + snackbar show the message). +2 tests.
- **Verification:** analyze 0; tests 251 passed / 1 skipped; issues validate
  OK; `git diff --check` clean; secret scan clean (only the pre-existing
  AuthMethods doc table line matched — not a credential). Repo-wide `dart
  format` still churns ~50 files and reintroduces the pre-existing
  `curly_braces` lint in `kvm_view.dart`; reverted the format-only churn to
  keep the diff focused (consistent with prior-run precedent; repo-wide format
  stays FUTUREWORK P2).
- **Commit:** b5840a2 — `auto: EMULATOR — emulator suite +2 (systems detail, HttpPushUri), UI-5 dialog busy confirm, REQUIREMENTS trace (run 2026-10-22 17:38)`; pushed: **no** — same GitHub credential blocker (no credential helper / env token / SSH key on this machine); local commit kept, not retried. 9 commits queued locally before this run, 10 after.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (10 queued); 2) P1 #015 AuthManager (authMethod, safe logout
  URI, session reuse/expiry) — unit-level with in-process mock server;
  3) #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag, or
  #008/#020: bmcweb HTTP-push firmware upload path (the emulator now asserts
  `HttpPushUri` is readable).

## 2026-10-22 20:25 — DOCS

- **Baseline:** analyze 0; tests 251 passed / 1 skipped; starting commit 45adec8;
  issues validate OK; branch `main` clean but ahead 11 of origin (11 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** DOCS-5 — full `SystemFeatures` flag → spec citation → test
  map in `REQUIREMENTS.md` (all 10 flags), plus the `ServiceEnabled` gap the
  audit surfaced, plus a UI-3 increment (FirmwareView breakpoint tests).
- **Docs:** REQUIREMENTS.md gained the "DOCS-5 — SystemFeatures flag → spec
  citation → test map" section: a 10-row table tracing `powerControl`,
  `supportedResetTypes`, `kvm`, `kvmType`, `sensorMonitoring`, `sensorCount`,
  `firmwareUpdate`, `updateServiceVersion`, `managers`, `chassis` to
  DSP0266/`UpdateService.v1_13_0.json`/bmcweb `Redfish.md` citations and to
  their exact tests. Two findings folded into code (below). No new downloads
  (schema citations verified live from `https://redfish.dmtf.org/schemas/v1/
  UpdateService.v1_13_0.json`; corpus unchanged).
- **Emulator:** re-ran `tool/emulator/run_tests.sh` after the rule change —
  all 13 emulator tests pass over HTTPS (confirms `firmwareUpdate` still true
  on the DMTF mockup, whose UpdateService carries `ServiceEnabled: true`).
- **Code/tests:**
  - **`FeatureRules.firmwareUpdate` now honors `ServiceEnabled`.** Previously any
    `UpdateService` resource counted as capability. DMTF `UpdateService.json`
    declares `ServiceEnabled` "shall indicate whether this service is enabled"
    and bmcweb advertises it (`Redfish.md` §UpdateService), so an explicitly
    disabled service must not surface the Firmware tab / overview chip.
    Missing/`null` stays enabled (conformant services may omit it). Files:
    `lib/redfish/discovery/feature_rules.dart`; tests:
    `feature_rules_test.dart` (+1 "firmwareUpdate honors ServiceEnabled
    (DOCS-5)"), `firmware_model_test.dart` (+1 disabled-UpdateService parse),
    discovery + integration suites re-run green (fixtures already carry
    `ServiceEnabled: true`).
  - **`updateServiceVersion` fallback confirmed conformant** — DMTF
    UpdateService schema has no `FirmwareVersion` property; the OpenBMC
    fixture's value is vendor-only, `Id` fallback is correct. No code change.
- **UI:** UI-3 extended to FirmwareView — no-overflow tests at 320/800/1300 px
  in `firmware_widget_test.dart` (+3, same `pumpAtWidth` pattern as
  PowerView/SensorsView); no production layout change (view already wraps;
  regression protection added).
- **Verification:** analyze 0; tests 256 passed / 1 skipped; issues validate
  OK; `git diff --check` clean; secret scan clean (only pre-existing
  `estimated_tokens`/comment false positives); emulator 13/13.
- **Commit:** 96e2b93 — `auto: DOCS — DOCS-5 SystemFeatures flag map, firmwareUpdate honors ServiceEnabled, UI-3 FirmwareView breakpoints (run 2026-10-22 20:25)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine), 12 commits queued locally; local commit kept, not retried.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (12 queued); 2) P1 #015 AuthManager (authMethod, safe logout URI,
  session reuse/expiry) — unit-level with in-process mock server; 3) #016/#022:
  `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020: bmcweb
  HTTP-push firmware upload path (emulator asserts `HttpPushUri`).

## 2026-10-22 21:08 — EMULATOR

- **Baseline:** analyze 0; tests 256 passed / 1 skipped; starting commit 1e0de47;
  issues validate OK; branch `main` clean but ahead 13 of origin (13 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** EMULATOR — re-verified the pinned DMTF Redfish-Mockup-Server
  suite end-to-end (16/16 pass over HTTPS, trap cleanup confirmed) and extended
  the suite with three tests that close remaining discovery/inventory gaps:
  SessionService URI discoverability (#017), Manager detail (console
  capabilities + manager-level Reset allow-list, DOCS-4/#022), and Chassis
  detail (inventory + Thermal/Power sub-resource chain + system link).
- **Emulator:** ran `tool/emulator/run_tests.sh` — 16/16 green, no stray server
  process, port 8443 closed after each run. Added:
  - `service root advertises a discoverable SessionService URI (#017)` —
    asserts `SessionService.@odata.id` is present at the service root and the
    discovered URI serves a conformant SessionService (ServiceEnabled +
    Sessions), the exact contract #017 wants the client to use instead of the
    hardcoded `/redfish/v1/SessionService`.
  - `managers: Manager exposes console capabilities + reset allow-list
    (DOCS-4 / #022)` — asserts the Manager collection enumerates `BMC`, the
    Manager payload carries `GraphicalConsole.ServiceEnabled=true` with
    `ConnectTypesSupported` KVMIP (the KVM console source
    `FeatureRules.oemHasConsole`/`KvmConsole.fromManager`), and
    `#Manager.Reset` advertises its own `ResetType@Redfish.AllowableValues`
    (`ForceRestart`, `GracefulRestart`) — documenting that the #022/#016
    allow-list fallback must not conflate the manager-level Reset action with
    the system Reset action.
  - `chassis: Chassis exposes inventory + thermal/power sub-resources` —
    asserts `Chassis/1U` inventory fields (ChassisType RackMount, SerialNumber,
    PowerState On, Status Enabled/OK), the `Thermal`/`Power` `@odata.id` links
    (the sensor-discovery source chain), and `Links.ComputerSystems[0]` back to
    `/redfish/v1/Systems/437XR1138R2`.
- **Code/tests:** no production logic change; emulator suite 13 → 16 tests.
  REQUIREMENTS.md "Test platforms" note updated to 16 tests and the new
  coverage. No new downloads (corpus unchanged; DOCS-6 budget respected).
- **UI:** UI-3 extended to KvmView — no-overflow tests at 320/800/1300 px in
  `kvm_widget_test.dart` (+3, same `pumpAtWidth` pattern as
  Power/Sensors/Firmware views; two console cards, graphical + serial).
  Dashboard/overview is now the only UI-3 view remaining.
- **Verification:** analyze 0; tests 259 passed / 1 skipped; issues validate
  OK; `git diff --check` clean; secret scan clean; emulator 16/16. Repo-wide
  `dart format` churn (44 files) reverted per prior-run precedent — it
  reintroduces the pre-existing `curly_braces` lint in `kvm_view.dart`;
  formatted only the touched files.
- **Commit:** 5e7c357 — `auto: EMULATOR — suite +3 (SessionService URI #017, Manager reset allow-list, Chassis chain), UI-3 KVM breakpoints (run 2026-10-22 21:08)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (14 queued); 2) P1 #015 AuthManager (authMethod, safe logout URI,
  session reuse/expiry) — unit-level with in-process mock server; 3) #016/#022:
  `ResetActionInfo` allow-list fallback + PATCH/etag (the emulator now documents
  the manager- vs system-level Reset allow-list sources), or #008/#020: bmcweb
  HTTP-push firmware upload path.

## 2026-10-22 19:59 — DOCS

- **Baseline:** analyze 0; tests 259 passed / 1 skipped; starting commit af735cf;
  issues validate OK; branch `main` clean but ahead 15 of origin (15 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** DOCS-2 — refreshed the DMTF versioned-schema fixture to the
  current upstream. A live `https://redfish.dmtf.org/schemas/v1/` index scan
  (14,259 entries, 3.4 MB listing at 21:45 UTC) showed six versioned definition
  files had advanced since the 2026-10-21 snapshot. Re-downloaded and diffed all
  six, then mirrored the new versions into both `test/fixtures/redfish/schemas/`
  and `documentations/external/redfish/schemas/v1/` with hashes + deltas in the
  manifest; no client code change was needed (all deltas are additive fields the
  client doesn't parse).
- **Docs:** new downloads this run 619,774 bytes (6 versioned schemas — inside
  the DOCS-6 50 MB budget). Manifest updated in `documentations/external/README.md`
  ("DOCS-2 refresh" table with SHA-256 + bytes + notable deltas per file);
  `documentations/redfish_reference/README.md` versioned-file list and snapshot
  note updated; REQUIREMENTS.md gained a "DOCS-2 — versioned-schema refresh
  audit" section mapping each refreshed schema to client impact and trace.
  Superseded versioned files retained for history. Mockup payload still matches
  the pinned upstream (`DMTF/Redfish-Mockup-Server @ 23d21f9a`, verified HEAD),
  so no mockup refresh was needed.
- **Emulator:** re-ran `tool/emulator/run_tests.sh` after touching the fixture
  tree — 16/16 pass over HTTPS; no stray process.
- **Code/tests:** no production logic change from the schema refresh. The UI-3
  increment (below) produced two small responsive fixes.
- **UI:** UI-3 **completed** — added no-overflow tests at 320/800/1300 px for the
  two remaining views. `dashboard_view_test.dart` (+3): caught and fixed a real
  28 px vertical overflow at 320 px — `SystemCard` content no longer fits the
  1.6-ratio single-column tile; the dashboard grid now uses a taller 1.25 ratio
  for the 1-column layout (2/3 columns stay 1.6). `overview_view_test.dart` (+3):
  caught and fixed a real 48 px overflow at 320 px — `GridView.count`'s
  fixed-ratio 288 px square cell squeezed the tall Identity card; single-column
  overview now stacks natural-height cards (loading skeleton + data grid both),
  2/3 columns keep the grid. All prior views (Power/Sensors/Firmware/KVM) were
  already covered → **UI-3 done, all views covered**.
- **Verification:** analyze 0; tests 265 passed / 1 skipped; emulator 16/16;
  issues validate OK; `git diff --check` clean; secret scan clean. Repo-wide
  `dart format` churn avoided again — formatted only the touched files.
- **Commit:** 24a2d7f — `auto: DOCS — DOCS-2 versioned schema refresh (6 files), UI-3 dashboard+overview breakpoints & overflow fixes (run 2026-10-22 19:59)`; pushed: **no** — same GitHub credential blocker (`fatal: could not read Username for 'https://github.com'`: no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits queued locally before this run: 15.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (16 queued); 2) P1 #015 AuthManager (authMethod, safe logout URI,
  session reuse/expiry) — unit-level with in-process mock server (emulator
  asserts the SessionService URI is discoverable — #017 contract); 3) #016/#022:
  `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020: bmcweb
  HTTP-push firmware upload path (emulator asserts `HttpPushUri`).

## 2026-10-22 20:51 — EMULATOR

- **Baseline:** analyze 0; tests 265 passed / 1 skipped; starting commit 9ada585;
  issues validate OK; branch `main` clean but ahead 17 of origin (17 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** EMULATOR — re-verified the pinned DMTF Redfish-Mockup-Server
  suite end-to-end over HTTPS and extended it **16 → 21 tests** with contract
  tests that de-risk the queued P1/P2 issues:
  1. Session lifecycle (#015/#017) — create a session via the *discovered*
     Sessions URI (never the hardcoded path): asserts the mockup returns 204 +
     `X-Auth-Token` + `Location` (naming the session resource, not the
     collection) and that the created session is GET-able. Pins the exact
     contract #015's logout-target fix must use.
  2. Logout-target clarity (#015) — DELETE of a session resource succeeds
     (204); DELETE of the Sessions *collection* is rejected with a normalized
     **405** non-retryable `RedfishException`. The #015 bug fell back to
     deleting the collection; this test proves the collection is never a valid
     logout target.
  3. SessionTimeout (#015) — `SessionService.SessionTimeout` (30) is published
     as a positive int: the input `Session.expiresAt` / `isExpired` proactive
     re-auth needs.
  4. Task service (#008/#020/#022) — the discovery root advertises `Tasks`,
     the TaskService is enabled, and its Tasks collection is enumerable: the
     task-URI source for long-running firmware uploads and power operations.
  5. Event service (DOCS-7 bed / #019) — `EventService` is enabled and exposes
     `Subscriptions` + `#EventService.SubmitTestEvent`: a future telemetry /
     event receiver has a conformant contract to test against (documents the
     DOCS-7 out-of-scope decision).
- **Docs:** none this run (no new downloads; DOCS-6 budget respected).
- **Emulator:** `tool/emulator/run_tests.sh` — 21/21 green over HTTPS, trap
  cleanup confirmed, no stray process; suite 16 → 21 tests.
- **Code/tests:** no production logic change from the emulator work
  (`test_integration/emulator/emulator_suite_test.dart` +5). UI-1 increment:
  `lib/features/firmware/views/firmware_view.dart` error state upgraded from a
  plain red `Text` to an `errorContainer` card with icon + message + a working
  **Retry** action (re-runs `FirmwareController.load()`, disabled while
  loading); `test/features/firmware/firmware_widget_test.dart` +1 — a flaky
  service (first fetch throws, second succeeds) drives the retry path: error +
  Retry shown, tap → reload succeeds → error cleared, inventory visible.
- **UI:** UI-1 firmware error+retry (above). No new dependencies, no
  decoration-only changes; the empty/loading/error states for other views were
  already present, so no UI-1 gap elsewhere was touched this run.
- **Verification:** analyze 0; tests 266 passed / 1 skipped; issues validate
  OK; `git diff --check` clean; secret scan clean (only pre-existing comment
  false positives); emulator 21/21.
- **Commit:** 23d0caf — `auto: EMULATOR — suite +5 (session lifecycle #015/#017, SessionTimeout, TaskService, EventService), UI-1 firmware error+retry (run 2026-10-22 20:51)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (17 queued); 2) P1 #015 AuthManager — the emulator now pins the
  full session contract (create → X-Auth-Token+Location, DELETE session
  resource, 405 collection, SessionTimeout); implement authMethod dispatch +
  safe logout URI + token rehydrate + expiry with the in-process mock server;
  3) #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag (emulator
  documents both manager- and system-level Reset allow-lists + TaskService),
  or #008/#020: bmcweb HTTP-push firmware upload (emulator asserts
  `HttpPushUri` + Tasks).

## 2026-10-22 23:55 — DOCS

- **Baseline:** analyze 0; tests 266 passed / 1 skipped; starting commit 8d81937;
  issues validate OK; branch `main` clean but ahead 19 of origin (19 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** DOCS-8 — full upstream-freshness audit of the mirrored
  corpus. Live schema-index scan (`https://redfish.dmtf.org/schemas/v1/`, 14,259
  entries) vs. all 13 tracked schema families: **no version advanced** since the
  DOCS-2 refresh (AccountService 1_19_0 … UpdateService 1_17_1 all current).
  DSP0266 1.25.0 still the latest published PDF (probe of 1.26.0 → 404).
  `DMTF/Redfish-Mockup-Server` HEAD still `23d21f9a` (unchanged, still pinned).
  bmcweb master moved `0128851e` → `27e0930b` (+3 commits: `http/parsing`,
  `update_service.hpp`, `time_utils` — no `docs/` files changed). Re-verified
  the three mirrored bmcweb docs are byte-identical at the new HEAD and updated
  the manifest pins; added `docs/CLIENTS.md` (2,695 B, official
  client-compatibility doc listing DMTF validators / python-redfish-library /
  redfishtool / fwupd / Redfish-Event-Listener) to the mirror. Decision
  recorded: `COMMON_ERRORS.md` + `HEADERS.md` are bmcweb C++ contributor docs
  (no client-facing contract) — not mirrored.
- **Docs:** 1 new file `redfish/openbmc/CLIENTS.md`; manifest updated (bmcweb
  pin → `27e0930b`, re-verified timestamps, new CLIENTS.md row with SHA-256);
  REQUIREMENTS.md gained "DOCS-8 — upstream-freshness audit" section + updated
  source header; README "Current upstream anchors" section rewritten with the
  DOCS-8 results. New downloads this run: 2,695 bytes (well inside DOCS-6
  50 MB budget).
- **Emulator:** none this run (no fixture change; mockup pinned `23d21f9a`
  verified unchanged upstream).
- **Code/tests:** `SystemManager.retryFailed()` added (reconnects only
  error-state systems); unit test `test/features/systems/system_manager_test.dart`
  +1 ("retryFailed reconnects only the failed systems"). DashboardView
  `_ErrorSummary` banner (errorContainer card, count message, one-tap Retry
  → `retryFailed()`) — UI-1 gap *dashboard empty/error summaries* now closes
  the remaining UI-1 item; widget tests
  `test/features/systems/dashboard_view_test.dart` +3 (error summary shown,
  retry clears summary after transient failure, no summary when healthy).
- **UI:** UI-1 dashboard error summary (above). No new dependencies, no
  decoration-only changes; error-card pattern matches FirmwareView's
  (errorContainer + icon + Retry). UI-2/UI-3/UI-4/UI-5 untouched.
- **Verification:** analyze 0; tests 270 passed / 1 skipped (baseline 266 → +4);
  issues validate OK; `git diff --check` clean; secret scan clean (no tokens/
  creds in diff); formatted only the 4 touched files (no repo-wide churn).
- **Commit:** b9dcd31 — `auto: DOCS — DOCS-8 upstream-freshness audit (bmcweb → 27e0930b, +CLIENTS.md), UI-1 dashboard error summary + retryFailed (run 2026-10-22 23:55)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried. Commits queued locally before this run: 19.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (20 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator contract pinned
  last run; implement unit-level with the in-process mock server; 3) #016/#022:
  `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020: bmcweb
  HTTP-push firmware upload (emulator asserts `HttpPushUri` + Tasks).

## 2026-10-23 05:00 — EMULATOR

- **Baseline:** analyze 0; tests 270 passed / 1 skipped; starting commit dbb1aa8;
  issues validate OK; branch `main` clean but ahead 21 of origin (21 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** EMULATOR — extended the pinned DMTF Redfish-Mockup-Server
  suite **21 → 24 tests** with three contract pins that de-risk queued issues,
  plus a small tested firmware model increment the pins document:
  1. `ProtocolFeaturesSupported` (— #018): the service root advertises
     `ExcerptQuery: true` and `ExpandQuery{ExpandAll,Levels}` so a
     lightweight/expand-aware discovery pass is possible; `FilterQuery` /
     `SelectQuery` published as booleans. The client currently ignores query
     capabilities — documented gap for the discovery-cache rework.
  2. AccountService / Accounts (— #015/#026): the Accounts collection is
     discoverable from the service and every member is readable
     (`UserName`, `RoleId`), and `MinPasswordLength` is published — the
     auth-method surface #015/#026 reason about.
  3. UpdateService `HttpPushUriOptions` (— #008/#020): the mockup publishes
     `HttpPushUriApplyTime.ApplyTime == 'Immediate'` plus
     `ApplyTime@Redfish.AllowableValues` (`Immediate`, `OnReset`,
     `AtMaintenanceWindowStart`, `InMaintenanceWindowOnReset`) and
     `MaintenanceWindowStartTime` — the apply-time selection a push-upload
     flow must offer instead of assuming Immediate.
- **Docs:** none this run (no new downloads; DOCS-6 budget respected). The
  ProtocolFeaturesSupported + push-options contracts were probed live
  (`curl -k https://127.0.0.1:8443/...`) before pinning.
- **Emulator:** suite 21 → 24 tests, all green over HTTPS; server stopped via
  exact-PID kill after the run (no stray process); pin `23d21f9a` unchanged.
- **Code/tests:** `UpdateServiceInfo` now parses
  `HttpPushUriOptions.HttpPushUriApplyTime` into `httpPushApplyTime` (current
  mode) + `httpPushApplyTimes` (AllowableValues); `copyWithInventory` preserves
  both. No public behaviour changed (additive fields). Unit tests
  `test/features/firmware/firmware_model_test.dart` +2 (DMTF fixture parse +
  absent-options fallback). No issue status change.
- **UI:** UI-2 increment — each firmware inventory card is now wrapped in a
  `Semantics(container: true, label: ...)` that announces a concise merged
  summary (component, version, health, updateable/locked) as one unit;
  `test/features/firmware/firmware_widget_test.dart` +1 asserts
  `find.bySemanticsLabel('Firmware BMC Firmware, 3.2.1, OK, updateable')`.
  No new dependencies; UI-2 remains open (cards/dialogs/tables partially done).
- **Verification:** analyze 0; tests 273 passed / 1 skipped (baseline 270 →
  +3); emulator 24/24; issues validate OK; `git diff --check` clean; secret
  scan clean (only the spec field name `MinPasswordLength` matched the token
  grep — not a credential). Repo-wide `dart format` churn avoided again:
  formatted only the 5 touched files (prior-run precedent: repo-wide format
  reintroduces the known `curly_braces` lint).
- **Commit:** d76b5eb — `auto: EMULATOR — suite +3 (query capabilities #018, Accounts #015/#026, push apply-time #008/#020), UpdateServiceInfo push-apply-time parse, UI-2 firmware card semantics (run 2026-10-23 05:00)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried. Commits queued locally before this run: 21.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (22 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator now also pins
  the AccountService surface; implement unit-level with the in-process mock
  server; 3) #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag, or
  #008/#020: bmcweb HTTP-push firmware upload (emulator asserts `HttpPushUri`
  + `HttpPushUriOptions` apply-time modes + Tasks).

## 2026-10-23 06:10 — DOCS

- **Baseline:** analyze 0; tests 273 passed / 1 skipped; starting commit 32f36ec;
  issues validate OK; branch `main` clean but ahead 23 of origin (23 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** DOCS-9 — upstream-freshness re-check of the mirrored corpus
  (about 6h after the DOCS-8 audit). **No anchor moved**: bmcweb master still
  `27e0930b` (`git ls-remote`), DMTF Redfish-Mockup-Server still `23d21f9a`,
  DSP0266 1.25.0 still the latest published PDF (probe of 1.26.0 → 404), and the
  live DMTF schema index (`redfish.dmtf.org/schemas/v1/`, 3.4 MB re-fetched to
  /tmp) shows no version advanced for the 13 tracked families — all current
  versions still present, all next-higher versions absent. Corpus stays current
  with zero new downloads (DOCS-6 budget untouched).
- **Docs:** no downloads this run (all anchors unchanged). `external/README.md`
  gained a DOCS-9 section + updated "Current upstream anchors" timestamp;
  `REQUIREMENTS.md` "Last audited" header updated to DOCS-9. Docs-driven code
  fix: bmcweb `Redfish.md` §UpdateService lists `MultipartHttpPushUri` next to
  `HttpPushUri`; `UpdateService.v1_17_1.json` defines it (`versionAdded v1_6_0`)
  — `UpdateServiceInfo` now parses it and the REQUIREMENTS row was upgraded from
  GAP to Partial (push URIs surfaced; upload path still #008/#020).
- **Emulator:** none this run (no emulator code touched; mockup pin `23d21f9a`
  re-verified unchanged upstream). As a safety check the 24-test suite was run
  anyway after the firmware-model change — 24/24 green over HTTPS, server
  stopped via trap.
- **Code/tests:** `UpdateServiceInfo` + `multipartHttpPushUri` (parse in
  `fromJson`, preserved in `copyWithInventory`); unit tests
  `test/features/firmware/firmware_model_test.dart` +3 (multipart parse, absent
  fallback against the DMTF mockup fixture, copyWithInventory preserves). No
  issue status change.
- **UI:** UI-2 increment — sensor tiles (temperature/fan/generic) now each sit
  in a `Semantics(container: true, excludeSemantics: true, label: ...)` that
  announces one concise summary (`Temperature CPU1 Temp, 41.0°C, Unknown`) —
  same pattern as the firmware cards from the 05:00 run; `excludeSemantics`
  needed because ListTile's internal merge otherwise appends the tile text to
  the label. Widget test
  `test/features/sensors/sensors_widget_test.dart` +1 asserts all three merged
  labels; fixture gained a fan + a generic sensor.
- **Verification:** analyze 0; tests 277 passed / 1 skipped (baseline 273 →
  +4); emulator 24/24; issues validate OK; `git diff --check` clean; secret
  scan clean (no tokens/creds in diff). Formatted only the 4 touched Dart files
  (no repo-wide churn — prior-run precedent).
- **Commit:** 37f6e1a — `auto: DOCS — DOCS-9 freshness re-check (no anchors moved), UpdateServiceInfo.MultipartHttpPushUri, UI-2 sensor-tile semantics (run 2026-10-23 06:10)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (24 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator pins the full
  session + AccountService surface; implement unit-level with the in-process
  mock server; 3) #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag,
  or #008/#020: bmcweb HTTP-push firmware upload (both push URIs +
  `HttpPushUriOptions` apply-time modes + Tasks now surfaced).

## 2026-10-23 03:02 — EMULATOR

- **Baseline:** analyze 0; tests 277 passed / 1 skipped; starting commit 9d99c48;
  issues validate OK; branch `main` clean but ahead 25 of origin (25 commits
  unpushed — GitHub push blocked: no credentials, see earlier entries).
- **Primary work:** EMULATOR — extended the pinned DMTF Redfish-Mockup-Server
  suite **24 → 27 tests** with three contract pins that de-risk queued issues,
  plus a small tested UI-2 increment:
  1. Sensors collection end-to-end (— #007/#019): the mockup's 41-member
     `/Chassis/1U/Sensors` collection is enumerated and parsed by the client's
     `SensorReading` model — CPU1Temp (`ReadingUnits Cel`, `Reading 37.0`,
     `UpperCritical` threshold 45.0) and PS1InputVoltage (`ReadingType Voltage`,
     `V`, 119.27) both resolve through `SensorsService.fetchAll()`; thresholds
     parse for the UI highlight (#007).
  2. System-level Reset allow-list (— #022/#016): the `#ComputerSystem.Reset`
     action advertises the full `ResetType@Redfish.AllowableValues` set
     (`On/ForceOff/GracefulShutdown/GracefulRestart/ForceRestart/Nmi/ForceOn/
     PushPowerButton`), which includes `Nmi` (NMI-stabilize #022) and is
     **distinct from the manager-level list** (ForceRestart + GracefulRestart,
     already pinned) — the #022/#016 fallback must read the system list, and it
     does not publish `PowerCycle` (the client enum has it — the gate must use
     exactly the advertised values).
  3. UpdateService `SimpleUpdateActionInfo` (— #008/#020): the mockup publishes
     `#ActionInfo.v1_4_1` with `ImageURI` (Required: true) + `TransferProtocol`
     AllowableValues (`HTTP/HTTPS/SFTP` …) — the parameter contract for the
     client's `startSimpleUpdate` when a BMC does expose SimpleUpdate (bmcweb
     is HTTP-push — DOCS-4).
- **Docs:** none this run (no new downloads; DOCS-6 budget untouched). The three
  contracts were probed live (`curl -k https://127.0.0.1:8443/...`) before
  pinning.
- **Emulator:** suite 24 → 27 tests, all green over HTTPS; server killed by
  exact-PID after the run (no stray process, port 8443 free); pin `23d21f9a`
  unchanged.
- **Code/tests:** no production code change this run (test-only pins — the
  client already parsed the Sensors collection and Reset allow-list surfaces).
  Emulator suite +3 (`emulator_suite_test.dart`). UI-2 increment: the Sensors
  chassis card header now announces one merged summary
  (`Chassis 1U, 1 temperatures, 1 fans, 1 sensors`) via
  `Semantics(container: true, excludeSemantics: true, label: ...)` on the title;
  `test/features/sensors/sensors_widget_test.dart` +1 asserts
  `find.bySemanticsLabel('Chassis 1U, 1 temperatures, 1 fans, 1 sensors')`.
  No new dependencies; no issue status change.
- **Verification:** analyze 0; tests 278 passed / 1 skipped (baseline 277 →
  +1); emulator 27/27; issues validate OK; `git diff --check` clean; secret
  scan clean (only the expected X-Auth-Token/MinPasswordLength references).
  Formatted only the 3 touched Dart files (no repo-wide churn — prior-run
  precedent).
- **Commit:** 0685dd1 — `auto: EMULATOR — suite +3 (Sensors collection #007/#019, system Reset allow-list #022/#016, SimpleUpdateActionInfo #008/#020), UI-2 chassis-card header semantics (run 2026-10-23 03:02)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (26 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator pins the full
  session + AccountService surface; implement unit-level with the in-process
  mock server; 3) #016/#022: `ResetActionInfo` allow-list fallback (emulator
  now pins the system-level `ResetType@Redfish.AllowableValues` incl. `Nmi`) +
  PATCH/etag, or #008/#020: bmcweb HTTP-push firmware upload (both push URIs +
  `HttpPushUriOptions` apply-time modes + `SimpleUpdateActionInfo` contract now
  surfaced).

## 2026-10-23 04:05 — REPAIR/DOCS-10 (recovered crashed WIP)

- **Baseline:** analyze **RED** (4 errors in a scratch probe test + 1 warning in
  `firmware_service.dart`); tests 3 failing (284 would-be / 1 skipped); starting
  commit 2024623; dirty tree from a crashed DOCS-10 run (firmware `UpdateTask`
  work + 3 new Task schemas + docs manifest/audit edits + a leftover debug probe
  `test/features/firmware/sem_probe_test.dart`); branch `main` ahead 27 of
  origin (GitHub push still blocked — no credentials, see earlier entries).
- **Primary work:** REPAIR of the crashed DOCS-10 WIP → finished, tested
  increment. Removed the scratch `sem_probe_test.dart` (no assertions, broken
  `SemanticsNode` import — the real coverage landed in `firmware_widget_test.dart`
  instead); fixed the always-true `date != null` warning after `HttpDate.parse`
  in `_retryAfterSeconds`; fixed the 3 failing tests (missing JSON content-type
  header when the DioAdapter reply overrides `headers` — mirrors the
  `auth_manager_test.dart` `_jsonContentType` pattern — and missing
  `excludeSemantics: true` on the queued-banner `Semantics`, the documented
  UI-2 pattern from the 06:10 run). The WIP itself was sound: DOCS-10 Task
  corpus + `UpdateTask.retryAfterSeconds` + banner semantics.
- **Docs:** DOCS-10 landed — `Task.json` + `Task.v1_7_4.json` +
  `TaskService.v1_2_1.json` mirrored from `https://redfish.dmtf.org/schemas/v1/`
  (32,950 bytes total; manifest rows + SHA-256 verified `sha256sum` match;
  `README.md` DOCS-10 section + `REQUIREMENTS.md` §12.2 audit table added by the
  crashed run, kept). No new downloads this run; DOCS-6 budget untouched.
- **Emulator:** none this run (no emulator code touched; pin `23d21f9a`
  unchanged). Safety re-run of the 27-test suite after the firmware-model change
  — 27/27 green over HTTPS, server stopped via trap.
- **Code/tests:** `UpdateTask` + `retryAfterSeconds` (202 `Retry-After`, seconds
  or HTTP-date, clamped ≥ 0); `FirmwareService.startSimpleUpdate` now returns an
  `UpdateTask` handle (taskUri + retry-after) instead of a bare `String`;
  `FirmwareUiState.lastTask` replaces `lastTaskUri`; queued-update banner shows
  `retry after Ns` and announces one merged semantics label (UI-2). Tests:
  `firmware_model_test.dart` +2 (UpdateTask), `firmware_service_test.dart` +2
  (Retry-After parse via DioAdapter, absent Location), `firmware_widget_test.dart`
  +2 (banner label + absent-URI fallback). No issue status change.
- **UI:** queued-update banner now carries a `Semantics(container: true,
  excludeSemantics: true, label: ...)` with one concise summary
  (`Update queued, <task monitor URI>, retry after N seconds`) — same pattern as
  the firmware cards / sensor tiles; widget tests assert the merged label and
  the absent-URI fallback.
- **Verification:** analyze 0; tests 284 passed / 1 skipped (would-be baseline
  281 → +3 after removing the probe; net +3 real tests this run); emulator
  27/27; issues validate OK; `git diff --check` clean; secret scan clean (no
  tokens/creds in diff). Formatted only the touched Dart files (no repo-wide
  churn — prior-run precedent).
- **Commit:** 29e0f93 — `auto: REPAIR/DOCS-10 — recover crashed WIP (Task corpus mirrored, UpdateTask Retry-After, queued-banner semantics, 3 failing tests fixed) (run 2026-10-23 04:05)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (28 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator pins the full
  session + AccountService surface; implement unit-level with the in-process
  mock server; 3) #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag,
  or #008/#020: bmcweb HTTP-push firmware upload — `UpdateTask` now carries the
  task-monitor URI + `Retry-After`, so the poller needs GET-on-monitor,
  `TaskState` parsing, and push-upload (`HttpPushUri`/`MultipartHttpPushUri`)
  apply-time modes.

## 2026-10-23 06:10 — EMULATOR (#006 overview hydration + LogService/LogEntry contracts) + UI-2 InfoCard

- **Baseline:** analyze 0; tests 284 passed / 1 skipped; starting commit 458966c;
  issues validate OK; working tree clean; branch `main` ahead 29 of origin
  (GitHub push still blocked — no credentials, see earlier entries).
- **Primary work:** EMULATOR — extended the pinned DMTF Redfish-Mockup-Server
  suite **27 → 30 tests** with three contract pins that de-risk queued issues:
  1. **OverviewService end-to-end hydration (— #006)**: the client's own
     `OverviewService.fetchOverview()` against the live mockup resolves the full
     `SystemOverview` — identity (`Manufacturer Contoso`, `Model 3500`,
     `SKU 8675309`, `SerialNumber 437XR1138R2`, `PartNumber 224071-J23`,
     `BiosVersion P79 v1.45 (12/06/2017)`), `PowerState on`, `Health ok` +
     `HealthRollup ok`, `ProcessorSummary` (Count 2, Model contains Xeon),
     `MemorySummary` (96.0 GiB), `IndicatorLed.off`, leading temperature 41.0 °C
     from the chassis Thermal chain (`Links.Chassis[0] → /Thermal`), and
     `resourceUri`. This is the first pin that drives the overview UI's data
     contract through the production hydration path rather than raw JSON.
  2. **LogService + LogEntry contracts (future log reader)**: the mockup's
     `/Systems/437XR1138R2/LogServices` collection is discoverable; `Log1`
     exposes `ServiceEnabled`, `OverWritePolicy WrapsWhenFull`, the
     `#LogService.ClearLog` action target, and an Entries collection whose
     `LogEntry.v1_16_0` members carry `EntryType SEL`, `Severity Critical`,
     `Created` RFC3339, `SensorType Temperature`, `Message`, and
     `Links.OriginOfCondition → /Chassis/1U/Thermal`; the collection also emits
     the `@odata.nextLink` pagination marker (`$skiptoken=2`) — the contract a
     future log feature must follow instead of assuming all entries are in one
     page. Mirrors `LogService.json` (schema corpus present); a REQUIREMENTS.md
     row traces it.
  3. The 30-test suite count is now documented in REQUIREMENTS.md (was stale at
     "16 tests" — it had drifted across the EMU-2/EMU-3 runs).
- **Docs:** none this run (no new downloads; DOCS-6 budget untouched). Updated
  `documentations/external/redfish/REQUIREMENTS.md`: emulator test-platform note
  rewritten (16 → 30 tests, listing every pinned group), +overview requirement
  row (ComputerSystem identity/PowerState/health/summaries/IndicatorLED/leading
  thermal → OverviewService + emulator pin, #006), +LogService/LogEntry row
  (contract pin; feature not queued yet).
- **Emulator:** suite 27 → 30 tests, all green over HTTPS (30/30 re-run against
  the final tree); server killed by exact-PID after each run (no stray process,
  port 8443 free); pin `23d21f9a` unchanged; `tool/emulator/run_tests.sh`
  unchanged.
- **Code/tests:** no production service-code change this run — test-only pins
  via `OverviewService` (existing code) against the live mockup. Emulator suite
  +3 (`emulator_suite_test.dart` "overview hydration (#006) + log-service
  contract" group). UI-2 increment: `InfoCard` header (icon + title) now
  announces as **one merged semantics node** — `Semantics(container: true,
  excludeSemantics: true, label: title)` wrapping the header row, the same
  pattern as the chassis/sensor/firmware card headers; `overview_view_test.dart`
  +5 asserts (`find.bySemanticsLabel('Identity'|'Processors'|'Memory'|
  'Temperatures'|'Indicator LED')`). No new dependencies; no issue status
  change.
- **UI:** InfoCard merged-header semantics label (UI-2). Rationale: this was the
  second-largest a11y gap after the card headers already fixed in prior runs;
  the overview cards now announce `Identity`, `Processors`, `Memory`,
  `Temperatures`, `Indicator LED` each as one node. Widget tests assert the
  merged labels + prior text assertions still pass.
- **Verification:** analyze 0; tests 284 passed / 1 skipped (baseline 284 →
  +0: the +5 semantics assertions extend an existing test; the +3 new cases
  live in the emulator suite which is skipped in plain `flutter test`);
  emulator 30/30; issues validate OK; `git diff --check` clean; secret scan
  clean (no tokens/creds in diff). Formatted only the 3 touched Dart files
  (no repo-wide churn — prior-run precedent: repo-wide `dart format`
  reintroduces the `curly_braces` lint and was reverted this run; the churn it
  caused is fully restored via `git checkout`).
- **Commit:** bea5e7c — `auto: EMULATOR — suite +3 (OverviewService end-to-end hydration #006, LogService/LogEntry contract incl. nextLink), UI-2 InfoCard merged header semantics (run 2026-10-23 06:10)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (30 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator pins the full
  session + AccountService surface, and now the overview hydration too;
  implement unit-level with the in-process mock server; 3) #016/#022:
  `ResetActionInfo` allow-list fallback (system-level, incl. `Nmi`) + PATCH/etag,
  or #008/#020: bmcweb HTTP-push firmware upload — both push URIs +
  `HttpPushUriOptions` apply-time modes + `SimpleUpdateActionInfo` + `LogEntry`
  collection contract for the task timeline.
## 2026-10-23 07:58 — DOCS (DOCS-11 LogEntry corpus mirror) + UI-2 SystemCard

- **Baseline:** analyze 0; tests 284 passed / 1 skipped; starting commit bea5e7c
  (branch `main` ahead 31 of origin); issues validate OK; working tree clean.
- **Primary work:** DOCS-11 — closed a real corpus gap: REQUIREMENTS.md and the
  emulator suite both reference `LogEntry`, but the external mirror had **no
  `LogEntry` schema** (only the `LogService` aggregator). Mirrored 5 official
  DMTF files from `https://redfish.dmtf.org/schemas/v1/` (171,095 bytes total,
  inside the DOCS-6 budget): `LogEntry.json` (aggregator), `LogEntry.v1_22_0.json`
  (newest versioned — EntryType 11 values, CPER, ResolutionSteps,
  OriginAddress...), `LogEntry.v1_16_0.json` (the version the pinned mockup
  serves, kept for emulator provenance), `LogEntryCollection.json` (the
  `@odata.nextLink` pagination contract), and `LogService.v1_9_0.json` (newest
  versioned LogService — the external corpus only had the aggregator). Also
  mirrored the LogEntry aggregator/`v1_16_0`/collection into
  `test/fixtures/redfish/schemas/` (DOCS-2 precedent keeps fixtures + corpus
  consistent). All `sha256sum`s verified and recorded in the manifest.
- **Docs:** new downloads this run (171,095 bytes, DOCS-6 budget untouched —
  annual budget is 50 MB/run; this is 0.17 MB). Manifest rows added to
  `documentations/external/README.md` + DOCS-11 section; `REQUIREMENTS.md`
  log row source now cites the real mirror files and "Last audited" bumped to
  DOCS-11; `documentations/redfish_reference/README.md` + `log_service.md`
  updated. Upstream freshest re-verified during the run: bmcweb `27e0930b`,
  Redfish-Mockup-Server `23d21f9a`, DSP0266 1.25.0 (1.26.0 probe → 404), live
  DMTF schema index — no version advanced for the other tracked families.
  Corrected a speculative DSP0266 §8.19 citation to the real spec references
  (§9.6.11 `Members` / §9.6.12 `Members@odata.nextLink`).
- **Emulator:** none this run (no emulator code touched; pin `23d21f9a`
  re-verified unchanged upstream). The ref'd LogService/LogEntry emulator
  contract tests were not re-run (no code touched); corpus rows updated only.
- **Code/tests:** UI-2 increment only — `SystemCard` header (display name +
  status icon row) now announces as **one merged semantics node**
  (`Semantics(container: true, excludeSemantics: true, label: '<name>,
  connected|connecting|connection error|disconnected')`), the same pattern as
  the chassis/sensor/firmware/InfoCard headers; the `PopupMenuButton` stays a
  sibling outside the merge so its own semantics/tap target are preserved (no
  a11y regression). New widget test
  `test/features/systems/ui_widget_test.dart` +1 asserts the merged label for
  all four connection states. No production logic change; no issue status
  change; no new dependencies.
- **UI:** SystemCard merged-header semantics label (UI-2). Rationale:
  dashboard cards were the last unmerged card header in regular use; the status
  icon (cloud/cloud_done/cloud_off) has no intrinsic text and otherwise
  announced as a bare node. Widget test covers all four connection states; the
  existing SystemCard text/tap/menu tests still pass.
- **Verification:** analyze 0; tests 285 passed / 1 skipped (baseline 284 →
  +1); issues validate OK; `git diff --check` clean; secret scan clean (no
  tokens/creds in diff). Formatted only the 2 touched Dart files (no repo-wide
  churn — prior-run precedent).
- **Commit:** ab39a7c — `auto: DOCS — DOCS-11 LogEntry schema corpus mirrored, UI-2 SystemCard merged header semantics (run 2026-10-23 07:58)`; pushed: **no** — same GitHub credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried. Commits queued locally before this run: 31.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (32 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator pins the full
  session + AccountService surface, and now the overview hydration too;
  implement unit-level with the in-process mock server; 3) #016/#022:
  `ResetActionInfo` allow-list fallback (system-level, incl. `Nmi`) + PATCH/etag,
  or #008/#020: bmcweb HTTP-push firmware upload — both push URIs +
  `HttpPushUriOptions` apply-time modes + `SimpleUpdateActionInfo` + the now
  fully-mirrored LogEntry collection contract for the task timeline.

## 2026-10-23 09:14 — EMULATOR (Task resource contract pin) + UI-2 KvmConsole header

- **Baseline:** analyze 0; tests 285 passed / 1 skipped; starting commit ca57787
  (branch `main` ahead 33 of origin); issues validate OK; working tree clean;
  emulator pin `23d21f9a` re-verified unchanged upstream.
- **Primary work:** EMULATOR — pinned the **Task resource contract** the
  future #008/#020/#022 poller must parse, using the DMTF mockup's only Task
  (545, `Task.v1_7_3`): `TaskState` (`Completed`), `TaskStatus` (`OK`),
  RFC3339 `StartTime`/`EndTime`, and `Messages[]` shape (`MessageId` `Base.*`,
  `Message`, `MessageArgs[]`, `Severity`). Crucially, the fixture publishes
  **no `PercentComplete`** — the poller must treat a missing `PercentComplete`
  as unknown progress, never crash (Task.v1_7_4.json makes it optional).
  Also pinned the `TaskService.v1_2_0` surface a poller/cleanup pass may
  consult: `CompletedTaskOverWritePolicy=Manual`,
  `LifeCycleEventOnTaskStateChange=true`, and the enumerable `Tasks` collection
  (already asserted in the discovery contract).
- **Docs:** no new downloads (DOCS-6 budget untouched). Updated
  `documentations/external/redfish/REQUIREMENTS.md`: emulator test-platform note
  "30 tests" → "32 tests" with the new task-resource group listed; DOCS-10 rows
  for `Task.TaskState`/`Messages[]`/`TaskService` policy fields now cite the
  live-mockup pin (incl. PercentComplete-absent note); "Last audited" bumped.
- **Emulator:** suite 30 → 32 tests, all green over HTTPS (32/32 re-run
  against the final tree); server killed by exact-PID after each run (no stray
  process, port 8443 free); pin `23d21f9a` unchanged;
  `tool/emulator/run_tests.sh` unchanged.
- **Code/tests:** no production service-code change this run — test-only pins
  via raw `getJson` against the live mockup (the Task resource contract is for
  the TO-BUILD poller, not yet read by client code). Emulator suite +2
  (`emulator_suite_test.dart` "task resource: TaskState/TaskStatus/Messages
  shape ... incl. absent PercentComplete" + "task service:
  CompletedTaskOverWritePolicy + LifeCycle event fields"). UI-2 increment:
  `KvmConsole` card header (title + Enabled/Disabled chip) now announces as
  **one merged semantics node** — `Semantics(container: true,
  excludeSemantics: true, label: '<type>, enabled|disabled')` wrapping the
  header row, the same pattern as the SystemCard/InfoCard/chassis/sensor/
  firmware card headers; the copy button and chips below stay interactive/
  sibling semantics (no a11y regression). Fixed a `dart format`-reintroduced
  `curly_braces_in_flow_control_structures` lint in `kvm_view.dart` (known
  prior-run precedent). No new dependencies; no issue status change.
- **UI:** KvmConsole card header merged semantics label (UI-2). Rationale: the
  KVM console cards were the last card header in regular use without the merged
  pattern; the Enabled/Disabled chip previously announced as a separate bare
  node. Widget tests assert the merged label for both states (enabled +
  disabled, split into two testWidgets because a second `ProviderScope` pump at
  the same tree position reuses the first container — the established
  single-pump per test pattern).
- **Verification:** analyze 0; tests 287 passed / 1 skipped (baseline 285 →
  +2: the two KVM semantics tests; the +2 emulator cases live in the emulator
  suite which is skipped in plain `flutter test`); emulator 32/32; issues
  validate OK; `git diff --check` clean; secret scan clean (no tokens/creds in
  diff). Formatted only the 3 touched Dart files (no repo-wide churn —
  prior-run precedent).
- **Commit:** e2c1279 — `auto: EMULATOR — Task resource contract pinned (TaskState/
  TaskStatus/Messages incl. absent PercentComplete for #008/#020 poller), UI-2
  KvmConsole card header merged semantics (run 2026-10-23 09:14)`; pushed:
  **no** — the same GitHub credential blocker (no credential helper, no
  GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local
  commit kept, not retried. Commits queued locally before this run: 33.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (34 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry) — emulator pins the full
  session + AccountService surface; implement unit-level with the in-process
  mock server; 3) #008/#020: build the task poller now that the Task resource
  contract is pinned end-to-end (GET-on-monitor, `TaskState` 13-value parse,
  `PercentComplete` optional/absent handling, `Messages[]` timeline) and the
  bmcweb HTTP-push firmware upload path (both push URIs + `HttpPushUriOptions`
  apply-time modes + `SimpleUpdateActionInfo` already asserted).

## 2026-10-23 10:2x — DOCS (DOCS-12 six-family versioned mirror) + UI-2 PowerView header

- **Baseline:** analyze 0; tests 287 passed / 1 skipped; starting commit e2c1279
  (branch `main` ahead 34 of origin); issues validate OK; working tree clean;
  emulator pin `23d21f9a` re-verified unchanged upstream.
- **Primary work:** DOCS-12 — closed the last "aggregator-only" corpus gap:
  `UpdateService`, `EventService`, `SessionService`, `Manager`, `Power`,
  `Thermal` had **no versioned definitions** in
  `documentations/external/redfish/schemas/v1/` (the client maps all six and
  the fixture snapshot already ships the newest versions). Mirrored, per
  family, the **newest** versioned file (what the aggregator `$ref`s) **plus**
  the version the pinned DMTF mockup serves as `@odata.type` (the DOCS-11
  LogEntry precedent — newest + mockup-served + fixture provenance):
  `UpdateService.v1_17_1` + `v1_13_0`, `EventService.v1_12_0` + `v1_10_1`,
  `SessionService.v1_2_0` + `v1_1_8`, `Manager.v1_25_0` + `v1_19_0`,
  `Power.v1_7_3` + `v1_7_2`, `Thermal.v1_7_3` + `v1_7_2` — 12 files,
  553,772 bytes total, inside the DOCS-6 budget (50 MB/run). SHA-256s verified
  after download; manifest rows added.
- **Docs:** new downloads this run (553,772 bytes — 0.55 MB, DOCS-6 budget
  untouched). Manifest rows + DOCS-12 section in
  `documentations/external/README.md`; REQUIREMENTS.md "Last audited" bumped to
  DOCS-12, six family rows + trace note now cite the real mirrored versioned
  files, and a new "DOCS-12 — six-family versioned schema mirror audit" section
  records the newest-vs-served property deltas; the six mockup-served versions
  were also copied into `test/fixtures/redfish/schemas/` so every `@odata.type`
  the mockup publishes has a versioned schema in the fixture (the six newest
  versions were already there and verified byte-identical to upstream);
  `documentations/redfish_reference/README.md` DOCS-12 note added. Upstream
  anchors re-verified: bmcweb `27e0930b`, mockup `23d21f9a`, DSP0266 1.25.0,
  live schema index (all 12 URLs 200 OK before download).
- **Emulator:** none this run (no emulator code touched; pin `23d21f9a`
  re-verified unchanged upstream; the six mockup-served versions copied into
  fixtures are provenance only — no emulator suite change).
- **Code/tests:** UI-2 increment only — `PowerView` card header (display name +
  PowerBadge) now announces as **one merged semantics node**
  (`Semantics(container: true, excludeSemantics: true, label: '<name>, power
  <state>')`), the same pattern as the SystemCard/InfoCard/chassis/sensor/
  firmware/KVM card headers; the reset buttons stay interactive/sibling
  semantics (no a11y regression). New widget test
  `test/features/power/power_view_test.dart` +1 asserts the merged label
  ("A, power Off"). No production logic change; no issue status change; no new
  dependencies.
- **UI:** PowerView card header merged semantics label (UI-2). Rationale: the
  power screen's header was the last primary card header without the merged
  pattern; the PowerBadge otherwise announced as a separate bare node
  ("Power Off") right after the system name. Widget test covers the merged
  node; all existing PowerView tests still pass.
- **Verification:** analyze 0; tests 288 passed / 1 skipped (baseline 287 →
  +1); issues validate OK; `git diff --check` clean; secret scan clean (no
  tokens/creds in diff). Formatted only the 2 touched Dart files (no repo-wide
  churn — prior-run precedent).
- **Commit:** 7b07a97 — `auto: DOCS — DOCS-12 six-family versioned schema mirror (UpdateService/EventService/SessionService/Manager/Power/Thermal newest + mockup-served), UI-2 PowerView card header merged semantics (run 2026-10-23 10:34)`; pushed: **no** — `fatal: could not read Username for 'https://github.com': No such device or address` (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried. Commits queued locally before this run: 35.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (36 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry — now also
  `AbsoluteSessionTimeout*` per `SessionService.v1_2_0.json` DOCS-12) —
  emulator pins the full session + AccountService surface; implement
  unit-level with the in-process mock server; 3) #008/#020: build the task
  poller now that the Task resource contract is pinned end-to-end
  (GET-on-monitor, `TaskState` 13-value parse, `PercentComplete`
  optional/absent handling, `Messages[]` timeline) and the bmcweb HTTP-push
  firmware upload path (both push URIs + `HttpPushUriOptions` apply-time modes
  + `SimpleUpdateActionInfo` already asserted; `LocalImageStore*`/`Stage`/
  `Activate` per `UpdateService.v1_17_1.json` DOCS-12 are upstream context).

## 2026-10-23 11:39 — EMULATOR (Manager network surface pin) + UI-2 OverviewView HealthBanner

- **Baseline:** analyze 0; tests 288 passed / 1 skipped; starting commit 57110cb
  (branch `main` ahead 38 of origin); issues validate OK; working tree clean;
  emulator pin `23d21f9a` verified unchanged (git rev-parse on the pinned
  checkout).
- **Primary work:** EMULATOR — pinned the **Manager network surface** the
  #009/#021 KVM console renderer and future NIC features consume:
  `GET /redfish/v1/Managers/BMC/NetworkProtocol` exposes
  `#ManagerNetworkProtocol.` with HostName/FQDN and the service endpoint table
  — `KVMIP` (ProtocolEnabled true + port 5288, the KVM-over-IP service the
  GraphicalConsole connect type resolves), `HTTPS` (443) and `SSH` (22);
  `GET /redfish/v1/Managers/BMC/EthernetInterfaces/{eth0}` enumerates the NIC
  surface — InterfaceEnabled, MACAddress, SpeedMbps, MTUSize, IPv4Addresses
  (Address/SubnetMask/AddressOrigin/Gateway) and VLAN (VLANEnable/VLANId).
  Test-only raw-getJson pins (same precedent as the 09:14 Task contract pin);
  no production service-code change. The client must resolve the console
  endpoint from the advertised KVMIP port, never hardcode ports.
- **Docs:** no new downloads (DOCS-6 budget untouched). Updated
  `documentations/external/redfish/REQUIREMENTS.md`: emulator test-platform note
  "32 tests" → "34 tests" with the new network-surface group listed; "Last
  audited" already DOCS-12 (this run is test-only, no REQUIREMENTS row change).
- **Emulator:** suite 32 → 34 tests, all green over HTTPS (34/34 re-run after
  `dart format` against the final tree); server killed by exact-PID after each
  run (port 8443 free, no stray process); pin `23d21f9a` unchanged;
  `tool/emulator/run_tests.sh` unchanged.
- **Code/tests:** no production service-code change this run — test-only pins
  via raw `getJson` against the live mockup (the network surface is for the
  TO-BUILD #009/#021 console renderer). Emulator suite +2
  (`emulator_suite_test.dart` "manager network: NetworkProtocol exposes the
  KVMIP/SSH/HTTPS service endpoints a console renderer resolves (#009/#021)" +
  "manager network: EthernetInterfaces collection enumerates the NIC MAC/IP/
  VLAN surface"). UI-2 increment: `OverviewView` `HealthBanner` (icon + label
  row) now announces as **one merged semantics node** —
  `Semantics(container: true, excludeSemantics: true, label: 'Health: <state>')`
  wrapping the banner row, the same pattern as the InfoCard/SystemCard/KVM/
  PowerView headers; the visible "Healthy" text remains for sighted users (no
  a11y regression). New widget test asserts the merged label
  ("Health: Healthy"). No new dependencies; no issue status change.
- **UI:** OverviewView HealthBanner merged semantics label (UI-2). Rationale:
  the overview banner was the last primary overview header without the merged
  pattern — the icon previously announced as a separate unlabeled node before
  the bare "Healthy" text. Widget test asserts the merged node + that the
  visible label text still renders; all existing OverviewView tests (loading/
  data/dark/adaptive/responsive/error) still pass.
- **Verification:** analyze 0; tests 289 passed / 1 skipped (baseline 288 →
  +1: the HealthBanner semantics test; the +2 emulator cases live in the
  emulator suite which is skipped in plain `flutter test`); emulator 34/34;
  issues validate OK; `git diff --check` clean; secret scan clean (no tokens/
  creds in diff). Formatted only the 3 touched Dart files (no repo-wide churn
  — prior-run precedent).
- **Commit:** 130ae16 — `auto: EMULATOR — Manager NetworkProtocol +
  EthernetInterfaces contract pinned (KVMIP/SSH/HTTPS endpoints for #009/#021
  console renderer + NIC MAC/IP/VLAN), UI-2 OverviewView HealthBanner merged
  semantics (run 2026-10-23 11:39)`; pushed: **no** — the same GitHub
  credential blocker (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key on this machine); local commit kept, not retried (hash
  recorded by the follow-up `chore: record run hash` commit). Commits
  queued locally before this run: 38.
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (39 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout expiry — SessionService
  v1_2_0 AbsoluteSessionTimeout* per DOCS-12) — emulator pins the full session
  + AccountService + Roles surface; implement unit-level with the in-process
  mock server; 3) #009/#021: the NetworkProtocol KVMIP port is now pinned — a
  KVM console launch can resolve the endpoint; or #008/#020: build the task
  poller (GET-on-monitor, TaskState 13-value parse, PercentComplete
  optional/absent, Messages[] timeline) + the bmcweb HTTP-push firmware upload
  path (both push URIs + apply-time modes + SimpleUpdateActionInfo asserted).

## 2026-10-23 11:41 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 11:39 (commit
  130ae16 + hash-record ef9d5be): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commits kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **40** (38 before this run + 2).

## 2026-10-23 12:50 — DOCS (auth/network/ActionInfo corpus mirror) + UI-2 FirmwareView header

- **Baseline:** analyze 0; tests 289 passed / 1 skipped; starting commit c51363b
  (branch `main` ahead 41 of origin); issues validate OK; working tree clean.
- **Primary work:** DOCS — closed the corpus gap for the **emulator-pinned but
  unmirrored** resources: the auth surface (`Session`, `ManagerAccount`, `Role` —
  the session-lifecycle + Accounts/Roles emulator pins and the #015/#017/#026
  work), the Manager **network surface** (`ManagerNetworkProtocol` — the 11:39
  run pins its KVMIP/HTTPS/SSH endpoints for the #009/#021 console renderer),
  **`ActionInfo`** (bmcweb's `ResetActionInfo` — the #022/#016 allow-list
  source), and versioned `ServiceRoot` (the #018 discovery contract). Also
  completed the Task-family provenance: the pinned mockup serves
  `#Task.v1_7_3.Task` + `#TaskService.v1_2_0.TaskService`, which DOCS-10 had
  not mirrored (only the newest v1_7_4/v1_2_1). Mirrored, per family, the
  aggregator + **newest** versioned file (what the aggregator `$ref`s) + the
  **mockup-served** version (what the pinned `23d21f9a` fixture publishes as
  `@odata.type`) — the DOCS-11/12 precedent.
- **Docs:** 19 files, 397,572 bytes total (inside the DOCS-6 50 MB budget), all
  probed 200 from `redfish.dmtf.org/schemas/v1/` with a browser UA; SHA-256s
  verified and recorded in `documentations/external/README.md` manifest rows +
  a new "DOCS-13" section (newest-vs-served deltas audited: Session v1_9_0
  expands session-type/OEM fields, ManagerAccount v1_14_2 adds
  PasswordExpiration/RemoteRole/account-types, Role v1_3_3 no deltas,
  ManagerNetworkProtocol v1_14_0 adds NTP* + Kerberos*, ActionInfo v1_6_0 adds
  ActionCapabilities + AllowableValueDescriptions, ServiceRoot v1_22_0 adds
  Tasks — **no client code change needed**). `REQUIREMENTS.md` got a DOCS-13
  audit table (7 rows traced to code/tests/status) + updated "Last audited" +
  Trace-notes aggregator count 16 → 21; `documentations/redfish_reference/
  README.md` notes the DOCS-13 fixture additions. Upstream anchors re-verified:
  bmcweb `27e0930b` (GitHub API), mockup default-branch `main` @ `23d21f9a`
  (GitHub API), DSP0266 1.25.0 still latest (1.26.0 → 404), live schema index
  200 OK — no anchor moved. The six mockup-served versions +
  `Task.v1_7_3`/`TaskService.v1_2_0` copied into `test/fixtures/redfish/
  schemas/` — every `@odata.type` the mockup publishes for these
  client-relevant families now has a versioned schema in the fixture.
- **Emulator:** none this run — no emulator code touched; the fixture `schemas/`
  additions are provenance JSON only (the emulator suite reads `dmtf_mockup`,
  not `schemas/`); pin `23d21f9a` re-verified unchanged upstream.
- **Code/tests:** UI-2 increment only — `FirmwareView` header row (title +
  in-flight spinner) now announces as **one merged semantics node**
  (`Semantics(container: true, excludeSemantics: true, label: 'Firmware and
  update management[, loading]')`), the same pattern as the
  SystemCard/InfoCard/KVM/PowerView/HealthBanner headers; the visible
  "Firmware & update management" text remains for sighted users (no a11y
  regression). Two new widget tests in `test/features/firmware/
  firmware_widget_test.dart`: loading-state label via a never-completing
  service double, and the idle label (asserting the loading suffix is absent
  once settled). No production logic change; no issue status change; no new
  dependencies.
- **UI:** FirmwareView header row merged semantics label (UI-2). Rationale: the
  firmware screen's header was the last primary card header without the merged
  pattern — the loading spinner otherwise announced as a bare progress node
  next to the title. Remaining UI-2: dialog touch-targets. Widget tests cover
  both header states; all existing FirmwareView tests still pass.
- **Verification:** analyze 0; tests 291 passed / 1 skipped (baseline 289 →
  +2: the two FirmwareView header semantics tests); issues validate OK;
  `git diff --check` clean; secret scan clean (no tokens/creds in diff —
  new files are public DMTF schemas). Formatted only the 2 touched Dart files
  (no repo-wide churn — prior-run precedent).
- **Commit:** 9d55b29 — `auto: DOCS — DOCS-13 auth/network/ActionInfo corpus mirror (Session/ManagerAccount/Role/ManagerNetworkProtocol/ActionInfo/ServiceRoot versioned defs + Task mockup-served), UI-2 FirmwareView header merged semantics (run 2026-10-23 12:50)`; pushed: **no** — `fatal: could not read Username for 'https://github.com': No such device or address` (no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried. Commits queued locally before this run: 40 (now 41 with this commit).
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials; 2) P1 #015 AuthManager (authMethod dispatch, safe logout URI,
  token rehydrate, SessionTimeout expiry — the Session/ManagerAccount/Role
  schemas are now mirrored, incl. `Session.v1_9_0.json` +
  `SessionService.v1_2_0.json` AbsoluteSessionTimeout* per DOCS-12/13);
  implement unit-level with the in-process mock server; 3) #022/#016: add the
  `ResetActionInfo` (ActionInfo `Parameters/AllowableValues`) fallback to
  `FeatureRules.supportedResetTypes` — the contract is now mirrored
  (`ActionInfo.v1_6_0.json` newest + v1_4_1 mockup-served) and emulator-pinned.

## 2026-10-23 13:58 — EMULATOR (account-service auth surface) + UI-2 Dashboard banner

- **Baseline:** analyze 0; tests 291 passed / 1 skipped; starting commit d83835c
  (branch `main` ahead 43 of origin); issues validate OK; working tree clean.
- **Primary work:** EMULATOR — pinned the **account-service auth surface** the
  #015/#026 work reasons about, complementing the DOCS-13 schema mirror
  (`ManagerAccount.v1_12_0`/`Role.v1_3_1` are exactly what the pinned mockup
  serves). The suite previously only walked the Accounts collection
  (UserName/RoleId); it now pins the full surface end-to-end over HTTPS:
  (1) **AccountService** lockout/password policy + both discoverable
  sub-collection links (`AuthFailureLoggingThreshold`,
  `AccountLockoutThreshold/Duration/CounterResetAfter/CounterResetEnabled`,
  `LocalAccountAuth`, `RequireChangePasswordAction`, `Accounts`+`Roles`
  `@odata.id` — `#AccountService.v1_15_0.AccountService`); (2) **Roles**
  collection contract (3 predefined roles Administrator/Operator/ReadOnly, and
  `#Role.v1_3_1.Role` `IsPredefined`/`AssignedPrivileges`
  (Login/ConfigureManager/ConfigureUsers/ConfigureSelf/ConfigureComponents)/
  `OemPrivileges`); (3) **ManagerAccount detail** contract
  (`Enabled`/`Locked`/`PasswordChangeRequired`, `AccountTypes` containing
  `Redfish` for #026 disambiguation, `Links.Role` → the Role resource, and the
  `#ManagerAccount.ChangePassword` action target) — plus the wire contract
  that `Password` must stay masked (`null`) and never be logged/read back.
  Test-only raw-getJson pins, the 09:14/11:39 precedent; no client model
  exists yet (auth surface TO-BUILD), so no production code change.
- **Docs:** none this run (no new downloads). REQUIREMENTS.md updated:
  test-platform note 34 → 36 tests with the auth-surface pin described, and
  the ManagerAccount/Role rows now cite the detail/collection pins.
- **Emulator:** server `23d21f9a` re-pinned by `tool/emulator/run_tests.sh`;
  suite 34 → **36 tests, all passing** (account service lockout/Roles link,
  Roles collection + privileges, ManagerAccount detail + Password-masked).
  Live payloads curl-verified against the fixture before pinning. No emulator
  code change; `allowSelfSigned` remains test-profile only (EMU-6).
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` (+2
  tests, one deepened); `test/features/systems/dashboard_view_test.dart` (+2
  widget tests); `lib/features/systems/views/dashboard_view.dart` (UI-2 label).
  No issue status change; no new dependencies.
- **UI:** UI-2 increment — `DashboardView` `_AggregatedBanner` (icon + health
  summary row) now announces as **one merged semantics node**
  (`Semantics(container: true, excludeSemantics: true, label: 'Health: <summary>')`),
  the same pattern as the SystemCard/HealthBanner/PowerView headers; the
  visible summary text remains for sighted users (no a11y regression). This
  was the last primary dashboard header without the merged pattern. Two new
  widget tests: the merged node ("Health: 1 OK, 1 Warning") + visible text,
  and the "No systems" empty-state label.
- **Verification:** analyze 0; tests 293 passed / 1 skipped (baseline 291 →
  +2: the dashboard banner semantics tests; the +2 emulator cases live in the
  emulator suite, skipped in plain `flutter test`); emulator 36/36 via
  `tool/emulator/run_tests.sh`; issues validate OK; `git diff --check` clean;
  secret scan clean (no tokens/creds in diff). Formatted only the 3 touched
  Dart files (no repo-wide churn — prior-run precedent).
- **Commit:** c577ca8 — `auto: EMULATOR — account-service auth surface pinned
  (AccountService lockout policy + Roles collection/privileges + ManagerAccount
  detail incl. Password masked), UI-2 DashboardView banner merged semantics
  (run 2026-10-23 13:58)`; pushed: **no** — same GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key on this machine); local commit kept, not retried. Commits
  queued locally before this run: 43 (now 44 with this commit).
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (44 queued); 2) P1 #015 AuthManager (authMethod dispatch, safe
  logout URI, token rehydrate, SessionTimeout + AbsoluteSessionTimeout*
  expiry) — the full auth surface is now pinned: session lifecycle +
  SessionService timeout + AccountService lockout policy + Roles/privileges +
  ManagerAccount detail (AccountTypes); implement unit-level with the
  in-process mock server; 3) #022/#016: add the `ResetActionInfo` (ActionInfo
  `Parameters/AllowableValues`) fallback to `FeatureRules.supportedResetTypes`
  — contract mirrored + emulator-pinned; or #008/#020: build the task poller
  (GET-on-monitor, TaskState parse, PercentComplete optional, Messages[]
  timeline) + the bmcweb HTTP-push firmware upload path.

## 2026-10-23 14:02 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 13:58 (commits
  c577ca8 auto + c23550e tracking): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commits kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **45** (43 before this run + 2).

## 2026-10-23 16:05 — DOCS (reset allow-list annotation fallback) + UI-2 dialog touch targets

- **Baseline:** analyze 0; tests 293 passed / 1 skipped; starting commit 9a1d1f6
  (branch `main` ahead 46 of origin); issues validate OK; working tree clean.
- **Primary work:** DOCS — closed the documented reset-allow-list gap
  (REQUIREMENTS.md rows "bmcweb reset types via ResetActionInfo" / DOCS-13
  ActionInfo row / DOCS-5 `supportedResetTypes` map row: "Partial — add
  ActionInfo fallback in #022/#016"). `FeatureRules.supportedResetTypes` now
  unions **both** documented sources: `SupportedResetTypes` (DSP0266
  `ComputerSystem.json`) and the `ResetType@Redfish.AllowableValues` annotation
  on each system's `#ComputerSystem.Reset` action — the form the pinned DMTF
  mockup serves (the emulator pins the 8-value list incl. `Nmi`/`ForceOn`/
  `PushPowerButton`) and bmcweb-style ActionInfo BMCs publish. New public
  helper `FeatureRules.resetTypesFromAction` (pure, unit-testable). The fallback
  reads only ComputerSystem payloads — never the manager-level `#Manager.Reset`
  list (emulator-pinned conflation guard: system list ≠ manager list). Prior to
  this fix the allow-list was empty on mockup/bmcweb shapes, which the power UI
  safely treated as "all allowed"; now the true allow-list is surfaced and the
  gate uses exactly the advertised values.
- **Docs:** none this run (no new downloads). REQUIREMENTS.md updated: the three
  reset-allow-list rows now cite the fallback + its tests and read OK, and the
  DOCS-4 finding #3 paragraph records the annotation fallback while noting the
  `ResetActionInfo` *resource* crawl stays folded into #022/#016. Upstream
  anchors not re-fetched (verified 12:40 UTC this same day — DOCS-13 run);
  no anchor movement expected inside 5h, recorded per DOCS-9 precedent.
- **Emulator:** re-ran `tool/emulator/run_tests.sh` (pin `23d21f9a`) — **36/36
  passing** (the system-level reset allow-list pin + conflation guard are the
  exact contract this fix implements). No emulator code change; `allowSelfSigned`
  remains test-profile only (EMU-6).
- **Code/tests:** `lib/redfish/discovery/feature_rules.dart` (+`resetTypesFromAction`,
  `supportedResetTypes` now unions annotation + property, dedupes + sorts);
  `test/redfish/discovery/feature_rules_test.dart` (+4 tests: annotation fallback
  on the mockup shape, union+dedupe of both sources, manager-list conflation
  guard, empty-action/no-annotation). No issue status change (the gap was tracked
  inline in REQUIREMENTS.md + FUTUREWORK #022/#016); no new dependencies.
- **UI:** UI-2 increment — `ConfirmResetDialog` action buttons now carry explicit
  **48×48px minimum size** (Cancel `TextButton.styleFrom(minimumSize:
  Size(48,48))`, Confirm `FilledButton.styleFrom(...).copyWith(minimumSize:
  WidgetStatePropertyAll(Size(48,48)))` + `tapTargetSize: padded`). Material
  pads the gesture target to 48dp but the visible button is 36dp; the explicit
  min makes the visual affordance meet the WCAG touch-target minimum too. One
  new widget test asserts both dialog action buttons render ≥48px tall
  (`power_view_test.dart` "dialog action buttons meet the 48px touch-target
  minimum (UI-2)").
- **Verification:** analyze 0; tests 298 passed / 1 skipped (baseline 293 →
  +5: 4 feature_rules + 1 power dialog touch-target); emulator 36/36 via
  `tool/emulator/run_tests.sh`; issues validate OK; `git diff --check` clean;
  secret scan clean (no tokens/creds in diff). Formatted only the 4 touched
  Dart files (no repo-wide churn — prior-run precedent).
- **Commit:** 23b2993 — `auto: DOCS — reset allow-list annotation fallback
  (FeatureRules.supportedResetTypes unions SupportedResetTypes +
  ResetType@Redfish.AllowableValues, manager-list conflation guard), UI-2
  dialog 48px touch targets (run 2026-10-23 16:05)`; pushed: **no** — same
  GitHub credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key on this machine); local commit kept, not retried. Commits
  queued locally before this run: 46 (now 47 with this commit).
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (46 queued before this run); 2) P1 #015 AuthManager (authMethod
  dispatch, safe logout URI, token rehydrate, SessionTimeout +
  AbsoluteSessionTimeout* expiry — full auth surface now pinned + schemas
  mirrored); implement unit-level with the in-process mock server; 3) #022/#016:
  the `ResetActionInfo` ActionInfo-*resource* crawl (fetch
  `Parameters[].AllowableValues` from the discovered ActionInfo URI) now that the
  annotation-form fallback lands; or #008/#020: build the task poller
  (GET-on-monitor, TaskState parse, PercentComplete optional, Messages[]
  timeline) + bmcweb HTTP-push firmware upload path.

## 2026-10-23 16:10 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 16:05 (commit
  23b2993 auto + tracking): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commits kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **47** (46 before this run + 1).

## 2026-10-23 17:07 — EMULATOR ($expand round-trip pin) + UI-2 sensors section headers

- **Baseline:** analyze 0; tests 298 passed / 1 skipped; starting commit f99becf
  (branch `main` ahead 48 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR (alternation: last run DOCS 16:05) — pinned the
  **live `$expand` round-trip contract** for #018's lightweight discovery
  pass. The service root advertises `ExpandQuery{ExpandAll,Levels}` (pinned
  13:58 run), but the flag alone doesn't prove the payload shape; this run
  asserts the real server behaviour: `GET /redfish/v1/Systems?$expand=.($levels=1)`
  returns the collection with **full inlined member bodies in one round trip**
  (Manufacturer/Model/SerialNumber/PowerState/Actions incl. the
  `#ComputerSystem.Reset` `ResetType@Redfish.AllowableValues` allow-list
  with `Nmi`, plus ProcessorSummary.Count=2 / MemorySummary.TotalSystemMemoryGiB=96 —
  the exact bodies OverviewService (#006) hydrates). This is the N+1-avoiding
  discovery shape a #018 cache/discovery pass can rely on. Also verified
  (recorded in FUTUREWORK #022/#016): the DMTF mockup fixture ships **no**
  `ResetActionInfo` ActionInfo resource for `#ComputerSystem.Reset` — only the
  annotation form (16:05 run implemented the annotation fallback); the
  ActionInfo-*resource* crawl remains a bmcweb-style code task, not pinable
  on this fixture.
- **Docs:** none this run (no new downloads). REQUIREMENTS.md updated:
  test-platform note 36 → 37 tests with the `$expand` round-trip pin described.
- **Emulator:** server `23d21f9a` re-pinned by `tool/emulator/run_tests.sh`;
  suite 36 → **37 tests, all passing** (+1 `$expand` test in the #018 query-
  capabilities group). Live payloads curl-verified against the fixture before
  pinning; the manually started probe server was stopped after the run
  (no leftover background process; runbook §3 trap precedent). No emulator
  code change; `allowSelfSigned` remains test-profile only (EMU-6).
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` (+1
  test); `lib/features/sensors/views/sensors_view.dart` +
  `test/features/sensors/sensors_widget_test.dart` (+1 widget test, UI-2
  increment below). No issue status change; no new dependencies.
- **UI:** UI-2 increment — SensorsView `_ChassisCard` section headers
  (`Temperatures`/`Fans`/`Sensors`) are the remaining non-card labels that
  announced as bare titles; each is now ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label:
  'Temperatures, <count>')`), the established card-header pattern — a screen
  reader gets the per-section count context a sighted user sees, and the
  visible titles remain for sighted users (no a11y regression). One new
  widget test asserts the three merged labels (`Temperatures, 1`/`Fans, 1`/
  `Sensors, 1`) + the visible texts.
- **Verification:** analyze 0; tests 299 passed / 1 skipped (baseline 298 →
  +1: the sensors section-header semantics test; the +1 emulator case lives
  in the emulator suite, skipped in plain `flutter test`); emulator 37/37 via
  `tool/emulator/run_tests.sh`; issues validate OK; `git diff --check` clean;
  secret scan clean (no tokens/creds in diff). Formatted only the 3 touched
  Dart files — a stray repo-wide `dart format lib/ test/` churn was detected
  and reverted before commit (30 unrelated files restored; only the 3
  intended files remain modified).
- **Commit:** be3d4b9 — `auto: EMULATOR — live $expand round-trip pin for the
  #018 lightweight discovery pass (Systems collection inlines full bodies +
  reset allow-list), UI-2 SensorsView section-header merged labels
  (run 2026-10-23 17:07)`; pushed: **no** — same GitHub credential blocker
  (`fatal: could not read Username for 'https://github.com'`; no credential
  helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this
  machine); local commit kept, not retried. Commits queued locally before
  this run: 48 (now 49 with this commit).
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (48 queued before this run); 2) P1 #015 AuthManager
  (authMethod dispatch, safe logout URI, token rehydrate, SessionTimeout +
  AbsoluteSessionTimeout* expiry — full auth surface pinned + schemas
  mirrored); implement unit-level with the in-process mock server; 3) #018:
  now that the `$expand` contract is pinned, build the lightweight discovery
  pass (collection fetch with `$expand=.($levels=1)` instead of N+1 GETs)
  with the forceRefresh/`_error` cache fixes; or #008/#020: task poller
  (GET-on-monitor, TaskState parse, PercentComplete optional, Messages[]
  timeline) + bmcweb HTTP-push firmware upload path.

## 2026-10-23 17:10 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 17:07 (commits
  be3d4b9 auto + 618dd46 tracking): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commits kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **49** (48 before this run + 1).

## 2026-10-23 17:30 — DOCS (OData base vocabulary mirror + anchor re-verification) + UI-2 self-signed warning semantics

- **Baseline:** analyze 0; tests 299 passed / 1 skipped; starting commit 91ff04f
  (branch `main` ahead 51 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS (alternation: last run EMULATOR 17:07, before that
  DOCS 16:05 — DOCS next). Closed the last un-mirrored REQUIREMENTS.md source
  citation and re-verified every corpus anchor:
  - **`odata.4.0.0.json` mirrored (new).** Row 65 (`@odata.id` link traversal)
    cited `Odata.json` but the external corpus had no OData schema. The bare
    `Odata.json` 404s on the DMTF schema index (verified live); the canonical
    file is the lowercase `odata.4.0.0.json` (OData 4.0.0 base vocabulary:
    `context`/`id`/`idRef`). Fetched 16:40 UTC, 1,834 bytes, SHA-256
    `c73cce02…` — **byte-identical to `test/fixtures/redfish/schemas/Odata.
    json`**, which proves the fixture copy is current. Manifest row added;
    REQUIREMENTS.md row 65 citation updated from `Odata.json` →
    `odata.4.0.0.json` (mirrored DOCS-14). Inside the DOCS-6 budget.
  - **bmcweb master advanced `27e0930b` → `fbb307a`.** Re-fetched all four
    mirrored docs at the new HEAD (`Redfish.md`, `REDFISH_CHECKLIST.md`,
    `OEM_SCHEMAS.md`, `CLIENTS.md`): **all byte-identical** (same SHA-256s) —
    no corpus refresh needed; manifest anchors + standing Sources note updated
    to `fbb307a`.
  - **`DMTF/Redfish-Mockup-Server` still `23d21f9a`** (default branch `main`;
    the `master` ref 422s — corrected the API call, pin unchanged).
  - **DMTF schema index 200 OK**; hub still links `DSP0266_1.25.0.pdf`
    (1.26.0 → 404) — no spec refresh.
- **Docs:** URL fetched: `https://redfish.dmtf.org/schemas/v1/odata.4.0.0.json`
  (1 new file, 1,834 bytes); 4 bmcweb docs re-fetched at the new HEAD for
  byte-identity verification (no content change). Files added:
  `documentations/external/redfish/schemas/v1/odata.4.0.0.json`. Requirements
  touched: row 65 citation fixed (DOCS-14); DOCS-14 audit section appended to
  REQUIREMENTS.md + README.md manifest/DOCS-14 notes.
- **Emulator:** none this run (no fixture/test change; anchors re-verified).
- **Code/tests:** no production behavior change. `lib/features/systems/views/
  system_profile_form.dart` (UI-2, below) + `test/features/systems/
  ui_widget_test.dart` (+1 widget test). No issue status change.
- **UI:** UI-2 increment — the **self-signed certificate warning banner** (the
  conditional orange icon+text row in `SystemProfileForm`, shown when the
  "Allow self-signed certificate" switch is on) announced as separate nodes
  (bare icon + detached sentence). It is now ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: 'Warning:
  self-signed certificates disable TLS verification. Only enable for trusted,
  isolated management networks.')` — the established HealthBanner pattern), so
  a screen reader gets the warning in context. The visible text is preserved
  for sighted users (no a11y regression). One new widget test asserts the
  merged label node + visible text (`ui_widget_test.dart` "self-signed warning
  announces as one merged semantics node (UI-2)").
- **Verification:** analyze 0; tests 300 passed / 1 skipped (baseline 299 →
  +1: the self-signed semantics widget test); issues validate OK; `git diff
  --check` clean; secret scan clean (no tokens/creds in diff). Formatted only
  the 2 touched Dart files — a stray repo-wide `dart format lib/ test/` churn
  (30 files) was detected and reverted before verification (only the 2
  intended Dart files remain modified; 17:07-run precedent).
- **Commit:** 4504e46 — `auto: DOCS — mirror OData base vocabulary
  odata.4.0.0.json (closes REQUIREMENTS row-65 citation, byte-verified vs
  fixture; bmcweb anchor 27e0930b→fbb307a docs byte-identical), UI-2
  self-signed warning merged semantics (run 2026-10-23 17:30)`; pushed:
  **no** — same GitHub credential
  blocker (`fatal: could not read Username for 'https://github.com'`; no
  credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on
  this machine); local commit kept, not retried. Commits queued locally before
  this run: 49 (now 50 with this commit).
- **Next:** 1) Push the queued local commits from a machine with GitHub
  credentials (49 queued before this run); 2) P1 #015 AuthManager (authMethod
  dispatch, safe logout URI, token rehydrate, SessionTimeout +
  AbsoluteSessionTimeout* expiry — full auth surface pinned + schemas
  mirrored); implement unit-level with the in-process mock server; 3) #018:
  build the lightweight discovery pass on the now-pinned `$expand` contract
  (collection fetch instead of N+1 GETs) + the forceRefresh/`_error` cache
  fixes; or #022/#016: the `ResetActionInfo` ActionInfo-*resource* crawl
  (`Parameters[].AllowableValues` — bmcweb-style BMCs; the DMTF mockup serves
  only the annotation form, pinned 17:07).

## 2026-10-23 17:40 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 17:30 (commits
  4504e46 auto + 0d3e360 tracking): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commits kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **50** (49 before this run + 1).

## 2026-10-23 17:45 — CORRECTION (no code change)

- The "queued local commits" counts in recent tracking entries undercounted:
  `git rev-list --count origin/main..HEAD` shows **54** commits ahead of
  origin/main after this run (baseline at run start was 51 ahead, +3 commits
  this run = 54). The "49 queued before this run" figure in the 17:30 entry
  was inherited from stale prior-run prose; the authoritative count is the
  live `git rev-list` number. Root cause of the push blocker unchanged (no
  GitHub credentials on this machine).

## 2026-10-23 18:36 — EMULATOR (query-behavior contract for #018) + UI-2 KVM view header

- **Baseline:** analyze 0; tests 300 passed / 1 skipped; starting commit 8916578
  (branch `main` ahead 54 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers; emulator suite 37/37 on pin `23d21f9a`.
- **Primary work:** EMULATOR (alternation: last run DOCS 17:30, before that
  EMULATOR 17:07 — EMULATOR next). Probed the live mockup and pinned the
  **query-behavior contract** the #018 lightweight discovery pass must build
  on (the 17:07 run pinned the payload shape; this run pins which OData query
  options the server actually applies):
  - **`$filter`/`$select` are advertised but NOT applied.** Live probes: on a
    static-fixture mockup, `$filter=Id eq 'NOPE'` on the Roles collection (3
    members) still returns all 3 members, and `$select=Model` on the system
    resource returns the FULL body — despite `ProtocolFeaturesSupported`
    advertising `FilterQuery`/`SelectQuery` (`emulator_suite_test.dart` line
    942-943 asserts those flags exist). New test pins both behaviours: the
    #018 pass must filter/select **client-side** and never rely on
    server-side query application.
  - **`$expand=*` (ExpandAll) IS applied.** The 17:07 pin used
    `$expand=.($levels=1)`; the mockup ALSO inlines full ComputerSystem bodies
    for `$expand=*` (members carry Model 3500 / PowerState On / Actions.Reset
    allow-list incl. Nmi / ProcessorSummary 2 / MemorySummary 96 — same fields
    as a direct GET). New test pins this second form; the #018 pass can rely
    on either form for payload shaping.
  - Also probed and recorded (not pinned): the mockup run WITHOUT the `-u`
    auth flag accepts any credentials — `POST Sessions` with a wrong password
    returns 204, so the 401 bad-login error-mapping path stays a unit-test
    concern (consistent with the EMU-5 decision); no session-auth change.
  - Suite 37 → **39 tests**, all passing on pin `23d21f9a`. No fixture or
    tooling change; no production code change from the emulator work.
- **Docs:** none fetched this run. `REQUIREMENTS.md` "test platform" note
  updated: 37 → 39 tests + the query-behavior paragraph (expand-* works;
  filter/select advertised-but-ignored for #018).
- **Emulator:** 39 tests green on `23d21f9a` (run via `tool/emulator/run_
  tests.sh` once for the baseline, then the live probe server for the pin
  verification — probe server stopped + port verified closed before tracking).
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` (+2
  tests); `lib/features/kvm/views/kvm_view.dart` + `test/features/kvm/
  kvm_widget_test.dart` (UI-2, below); no issue open/close.
- **UI:** UI-2 increment — the **KvmView view header** ("Remote KVM /
  Consoles" title + "Consoles exposed by the system managers." subtitle) was
  the last unmerged view-level non-card label group (card headers were already
  merged). It now announces as ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: 'Remote KVM /
  Consoles, consoles exposed by the system managers')` — the established
  header pattern), so a screen reader gets the view purpose in one concise
  summary instead of two detached text nodes. Visible texts preserved. One new
  widget test asserts the merged label node + both visible texts
  (`kvm_widget_test.dart` "view header announces one merged semantics node —
  title + subtitle (UI-2)").
- **Verification:** analyze 0; tests 301 passed / 1 skipped (baseline 300 →
  +1: the KVM header semantics widget test; emulator suite separately 39/39);
  issues validate OK; `git diff --check` clean; secret scan clean. `dart
  format` on the 3 touched Dart files: 0 changed (already formatted).
- **Commit:** c412733 — `auto: EMULATOR — pin the #018 query-behavior
  contract ($filter/$select advertised but NOT applied → filter client-side;
  $expand=* also serves inlined bodies), UI-2 KVM view header merged semantics
  (run 2026-10-23 18:36)`; pushed: **no** — same GitHub credential blocker
  (`fatal: could not read Username for 'https://github.com'`; no credential
  helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this
  machine); local commit kept, not retried. Commits ahead of origin/main
  before this run: **55** (preflight `git status --short --branch` showed
  `ahead 55`; +1 auto +1 tracking = **57** after — live
  `git rev-list --count origin/main..HEAD`).
- **Next:** 1) Push the queued local commits (54 before this run) from a
  machine with GitHub credentials; 2) P1 #015 AuthManager (authMethod
  dispatch, safe logout URI, token rehydrate, SessionTimeout +
  AbsoluteSessionTimeout* expiry — full auth surface pinned + schemas
  mirrored; 401 bad-login path stays unit-level per the EMU-5 decision);
  3) #018: build the lightweight discovery pass on the pinned query contract
  — `$expand=*` (or `$levels=1`) collection fetch instead of N+1 GETs,
  filtering/selection done client-side (mockup ignores `$filter`/`$select`);
  or #008/#020: task poller (GET-on-monitor, TaskState parse, PercentComplete
  optional, Messages[] timeline) + bmcweb HTTP-push firmware upload path.

## 2026-10-23 18:40 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 18:36 (commits
  c412733 auto + b366838 tracking): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commits kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **57** (55 before this run + 2;
  live `git rev-list --count origin/main..HEAD`).

## 2026-10-23 19:25 — DOCS (DSP0266 §7.3 query-parameters audit for #018) + UI-2 SystemOverviewPage header

- **Baseline:** analyze 0; tests 301 passed / 1 skipped; starting commit e59f474
  (branch `main` ahead 58 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS (alternation: EMULATOR 18:36, before that DOCS 17:30 —
  DOCS next). Audited DSP0266 1.25.0 §7.3.1–§7.3.5 **"Query parameters"** — the
  last unaudited normative clause set that directly governs the #018
  lightweight discovery pass (`$expand` collection fetch). Extracted and traced
  to the client:
  - **Processing order** `$filter` → `$skip` → `$top` → server-side pagination →
    `$expand` → `excerpt` → `$select`; query parameters are GET-only.
  - **`$expand` options** (`*` all-hyperlinks incl. payload annotations,
    `$levels` default 1, `.` all-but-links, `~` links-only), `MaxLevels` cap,
    privileges-do-not-fail-expansion, **507 Insufficient Storage** on oversized
    payloads, partial collection expansion → 200 + `@odata.id` + extended info.
  - **`$select`** subset semantics (slash paths, no array indices, keep
    `@odata.id`/`@odata.type`, omit unsupported requested props).
  - **`$filter`** built-in operators `() and or not eq ne ge gt le lt` with
    fixed precedence; strings in single quotes.
  - **`clientcontext`** stateless incremental retrieval (LogEntryCollection),
    `@Redfish.ClientContextStatus`, eviction → NotFound.
  - **Status codes** 501 for unsupported `$`-params + extended error, 400 for
    invalid values, `QueryNotSupportedOnResource`.
  - **ProtocolFeaturesSupported** gating (`ExpandQuery{ExpandAll,Levels}`,
    `FilterQuery`, `SelectQuery`, `ExcerptQuery`).
  Bottom line for #018 (folded into FUTUREWORK + REQUIREMENTS.md "DOCS-15"):
  the pinned mockup **applies `$expand` (`*` and `$levels=1`) but NOT
  `$filter`/`$select`** — the pass must gate `$expand` on
  `ProtocolFeaturesSupported` and filter/project **client-side**; map 501/507.
- **Docs:** no new files downloaded (corpus complete; anchors re-verified:
  bmcweb master still `fbb307a`, mockup still `23d21f9a`, DSP0266 still 1.25.0,
  schema index 200 OK — live `curl -sSIL` + `git ls-remote`). Manifest README
  anchors note updated to 19:20 UTC + DOCS-15 section; REQUIREMENTS.md got the
  full DOCS-15 audit table (9 requirement rows) + "Last audited" header bump.
- **Emulator:** none this run (the 18:36 query-behavior pin is the input the
  audit reasons about; no server work needed).
- **Code/tests:** `test/redfish/client/redfish_client_extra_test.dart` +1 test
  pinning the **transport contract**: `RedfishClient.getJson(path,
  query: {...})` forwards the map to the wire as `queryParameters`
  (`$expand=.($levels=1)` round-trips) — the seam #018 will use. No production
  code change (transport already supports query; nothing passes it yet).
- **UI:** UI-2 increment — the **SystemOverviewPage connection header** (system
  name + `scheme://host:port` in the top card) was announced as two detached
  text nodes; it now announces as ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: '<name>,
  <scheme>://<host>:<port>')` — the established header pattern). The
  conditional connection-error text stays its own node. One new widget test
  asserts the merged label + both visible texts preserved; `connectedHandle`
  helper gained a `port` param for the test.
- **Verification:** analyze 0; tests 303 passed / 1 skipped (baseline 301 →
  +2: getJson query-forwarding unit test + SystemOverviewPage merged-header
  widget test); issues validate OK; `git diff --check` clean; secret scan
  clean. `dart format` on the 3 touched Dart files: 1 changed
  (`redfish_client_extra_test.dart`, whitespace only).
- **Commit:** 59bfb28 — `auto: DOCS — DSP0266 §7.3 query-parameters audit for
  #018 ($expand gating on ProtocolFeaturesSupported, client-side filter/
  select, 400/501/507 mapping; $levels default 1), pin getJson query
  forwarding + UI-2 SystemOverviewPage header merged semantics (run
  2026-10-23 19:25)`; pushed: **no** — same GitHub credential blocker
  (`fatal: could not read Username for 'https://github.com'`; no credential
  helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this
  machine); local commit kept, not retried. Commits ahead of origin/main:
  **59** before push attempt (58 + 1 auto), live `git rev-list --count
  origin/main..HEAD`).
- **Next:** 1) Push the queued local commits (59) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager (authMethod dispatch, safe logout URI,
  token rehydrate, SessionTimeout + AbsoluteSessionTimeout* expiry — full
  auth surface pinned + schemas mirrored; 401 bad-login path stays
  unit-level); 3) #018: build the lightweight discovery pass on the now-pinned
  contract — gate `$expand` on `ProtocolFeaturesSupported.ExpandQuery`, use
  `getJson(query: {'\$expand': ...})` (transport pinned this run), filter/
  project client-side, map 501/507; or #008/#020: task poller
  (GET-on-monitor, TaskState parse, PercentComplete optional, Messages[]
  timeline) + bmcweb HTTP-push firmware upload path.

## 2026-10-23 19:30 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 19:25 (commit
  59bfb28): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **59** (58 before this run + 1;
  live `git rev-list --count origin/main..HEAD`).

## 2026-10-23 19:33 — CORRECTION (no code change)

- Queued local commits now **60** ahead of origin/main (59 at the 19:25 push
  attempt + 1 tracking commit bfc5fd3; live `git rev-list --count
  origin/main..HEAD`). Root cause of the push blocker unchanged (no GitHub
  credentials on this machine).

## 2026-10-23 22:45 — EMULATOR (map-form getJson query round-trip for #018) + UI-2 KVM connect-URI row

- **Baseline:** analyze 0; tests 303 passed / 1 skipped; starting commit ceb84c4
  (branch `main` ahead 61 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR (alternation: DOCS 19:25 → EMULATOR next). Pinned
  the **map-form `getJson(path, query:)` `$expand` round-trip** against the
  live DMTF mockup (`23d21f9a`) — the seam between the 19:25 transport unit
  test (query map forwards to the wire as `queryParameters`) and the
  URL-string live pins (17:07 `$levels=1`, 18:36 `$expand=*`). New emulator
  test calls `client.getJson('/redfish/v1/Systems', query: {'\$expand':
  '.($levels=1)'})` — the exact call shape the #018 lightweight discovery
  pass will make — and asserts the SAME inlined full ComputerSystem member
  bodies the URL-string form returns (Model 3500 / Manufacturer Contoso /
  PowerState On / Actions.Reset allow-list incl. Nmi / ProcessorSummary
  Count 2) in one round trip. Emulator suite 39 → **40 tests**, all green on
  the pin via `tool/emulator/run_tests.sh` (server stopped by trap; port
  8443 closed).
- **Docs:** none this run (corpus complete; no new downloads). REQUIREMENTS.md
  "Test platforms" note updated: 39 → 40 tests + the map-form `$expand`
  paragraph (pinned 2026-10-23 22:45).
- **Emulator:** suite green 40/40; pin `23d21f9a` unchanged; self-signed
  cert regenerated under /tmp (test-only TLS, EMU-6 intact).
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` +1
  test (map-form query round-trip). No production code change — the transport
  already forwards `query:`; the new test proves the live server behaviour.
- **UI:** UI-2 increment — the **KVM console card connect-URI row**
  (`Connect URI:` label + the SelectableText URI) announced as two detached
  text nodes; it now announces as ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: 'Connect URI:
  <uri>')` — the established row pattern, with the label + URI kept visible
  in a Row). One new widget test in `kvm_widget_test.dart` asserts the
  merged label + both visible texts preserved.
- **Verification:** analyze 0; tests 304 passed / 1 skipped (baseline 303 →
  +1: KVM connect-URI merged-label widget test; the emulator +1 test only
  runs under `REDFISH_EMULATOR_URL`); emulator suite 40/40 via run_tests.sh;
  issues validate OK; `git diff --check` clean; secret scan clean. `dart
  format` reflowed 29 pre-existing files (formatter drift) — those were
  reverted; only this run's 4 touched files are staged (kvm_view.dart,
  kvm_widget_test.dart, emulator_suite_test.dart, REQUIREMENTS.md).
- **Commit:** 7515efa — `auto: EMULATOR — pin map-form getJson(path, query:)
  $expand round-trip live for #018 (same inlined bodies as the URL-string
  form; 40 emulator tests) + UI-2 KVM connect-URI merged semantics label
  (run 2026-10-23 22:45)`; pushed: **no** — same GitHub credential blocker
  (`fatal: could not read Username for 'https://github.com'`; no credential
  helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this
  machine); local commit kept, not retried. Commits ahead of origin/main:
  **61** before push attempt (+1 auto +1 tracking = 63 after, live
  `git rev-list --count origin/main..HEAD`).
- **Next:** 1) Push the queued local commits (61) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager (authMethod dispatch, safe logout URI,
  token rehydrate, SessionTimeout + AbsoluteSessionTimeout* expiry — full
  auth surface pinned + schemas mirrored; 401 bad-login path stays
  unit-level); 3) #018: build the lightweight discovery pass on the now fully
  pinned contract — `getJson(query: {'\$expand': '.($levels=1)'})` collection
  fetch (transport + live round-trip both pinned this run), gate on
  `ProtocolFeaturesSupported.ExpandQuery`, filter/project client-side, map
  501/507 + the forceRefresh/`_error` cache fixes; or #008/#020: task poller
  + bmcweb HTTP-push firmware upload path.

## 2026-10-23 22:50 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 22:45 (commits
  7515efa auto + 5a8825c tracking): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commits kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **63** (61 before this run + 2;
  live `git rev-list --count origin/main..HEAD`).

## 2026-10-23 23:40 — DOCS (DSP0266 citation audit + §9.9 annotation pin) + UI-2 OverviewView error state

- **Baseline:** analyze 0; tests 304 passed / 1 skipped; starting commit 7764644
  (branch `main` ahead 64 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS (alternation: EMULATOR 22:45 → DOCS next). Audited the
  DSP0266 clause citations in `REQUIREMENTS.md` against the **mirrored
  `DSP0266_1.25.0.pdf`** (pdftotext of the actual PDF, TOC + body) and found
  the requirement rows added across DOCS-3/4/5/10/13 cited an **older spec
  layout**: `§8.3 Service Root` (→ `§7.2.3`), `§8.4 ComputerSystem` /
  `§8.10 Thermal` / `§8.14 Software inventory` (→ schema files + `§9` data
  model — DSP0266 does not enumerate per-resource property lists),
  `§9.2 HTTP and the Redfish protocol` (→ `§6.5 ETags` + `§7.2 GET`),
  `§12.2 Actions` (→ `§9.6.14` + `§7.11`), `§12.3 Basic authentication`
  (→ `§13.3.3`), `§12.4 Sessions`/`Session timeout` (→ `§13.3.4` /
  `§13.3.4.3`), `§12.7 Error responses` (→ `§8.6`), `§9.7 Firmware update`
  (→ `§12.7`). Corrected every stale row inline + added a DOCS-16 section with
  the stale→correct mapping table. Clauses already correct stayed unchanged
  (`§12.1 Eventing`, `§12.2 Asynchronous operations`, `§7.3 Query parameters`,
  `§9.6.11/9.6.12`, `§9.6.2`, `§9.1`). Also fixed the `feature_rules.dart`
  doc comment that cited "DSP0266 §9.3 Annotations" (→ §9.9 Payload
  annotations, §9.9.2 Allowable values for strings) and the EMU-5 decision's
  "Response messages" placeholder (→ §8.6).
- **Docs:** no new downloads (corpus complete; DOCS-6 budget untouched).
  Anchors re-verified live 23:32 UTC: bmcweb `fbb307a` (unchanged), mockup
  `23d21f9a` (unchanged), DSP0266 1.25.0 PDF (www.dmtf.org URL; content-length
  1,243,359 bytes — unchanged; the `redfish.dmtf.org/sites/...` path 404s, the
  hub links `www.dmtf.org`), schema index 200 OK. Manifest anchors note + the
  DSP0266 row note updated.
- **Code/tests:** `feature_rules_test.dart` +2 (pins the §9.9.2
  `@Redfish.AllowableValues` list parse and the §9.9.1 unrecognized-annotation
  tolerance — code already implemented both; the tests make the spec link
  explicit). `feature_rules.dart` doc-comment citation fix only (no behavior
  change). No issue IDs opened/closed.
- **UI:** UI-2 increment — the **OverviewView error state** (cloud-off icon +
  "Unable to load overview" title + detail message) announced as a bare icon
  plus detached sentences; it now announces as ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: 'Unable to load
  overview. <message>')` — the established error-state pattern), with the
  Retry button keeping its own control node. One new widget test in
  `overview_view_test.dart` asserts the merged label + visible texts + a
  separately-announced Retry control.
- **Verification:** analyze 0; tests 307 passed / 1 skipped (baseline 304 →
  +3: two feature_rules annotation-contract tests + one OverviewView
  error-state merged-label widget test); issues validate OK; `git diff
  --check` clean; secret scan clean (only schema-field names `X-Auth-Token`/
  `Password` in the docs diff). `dart format` on the 4 touched Dart files:
  2 changed (overview_view.dart + overview_view_test.dart, wrapping only).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — same GitHub
  credential blocker expected (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
  Commits ahead of origin/main: **64** before push attempt.
- **Next:** 1) Push the queued local commits (64) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager (authMethod dispatch, safe logout URI,
  token rehydrate, SessionTimeout + AbsoluteSessionTimeout* expiry — full
  auth surface pinned + schemas mirrored + session clauses now cited as
  §13.3.4); 3) #018: build the lightweight discovery pass on the fully pinned
  contract — `getJson(query: {'\$expand': '.($levels=1)'})` collection fetch
  (transport + live round-trip pinned), gate on
  `ProtocolFeaturesSupported.ExpandQuery`, filter/project client-side, map
  501/507 + the forceRefresh/`_error` cache fixes; or #008/#020: task poller
  + bmcweb HTTP-push firmware upload path.

## 2026-10-23 23:50 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-23 23:40 (commit
  d081ffa auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **65** (64 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 02:25 — EMULATOR (MessageRegistry contract pin) + UI-2 SensorsView error state

- **Baseline:** analyze 0; tests 307 passed / 1 skipped; starting commit fe1057b
  (branch `main` ahead 66 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR (alternation: DOCS 23:40 → EMULATOR next). Pinned
  the **MessageRegistry discovery/resolution contract** against the live DMTF
  mockup (`23d21f9a`): service root advertises `Registries` →
  `MessageRegistryFileCollection` (exactly one member, `Base.1.5.0`) →
  `MessageRegistryFile.Location[0].Uri` (`/redfish/v1/Registries/
  Base.1.5.0.json`) resolves to a `#MessageRegistry` JSON defining the **60
  Base.\* message templates** (Message/Severity/NumberOfArgs) behind
  `RedfishError.code`/`firstMessage` — the DSP0266 §8.6 error-response /
  §11.4 message-registry surface the #014 model normalizes. Asserts the
  template shapes the client actually surfaces: GeneralError (Severity
  Critical, NumberOfArgs 0 — the `code` fallback), ActionNotSupported
  (NumberOfArgs 1, `%1` template), AccessDenied (Critical), ActionParameterMissing
  (NumberOfArgs 2). Emulator suite 40 → **41 tests**, all green via
  `tool/emulator/run_tests.sh` (server stopped by trap; port 8443 closed —
  verified twice: first run shared the port with a manual server from the same
  pinned checkout, second run was clean end-to-end).
  **Negative re-verifications recorded:** the mockup's reset action returns
  **204 No Content with NO task-monitor `Location` header** (the #008/#020/#022
  GET-on-monitor seam stays unit-level, consistent with the absent
  PercentComplete pin), and the **live 404 closes the connection without an
  error body** (the extended-info error-envelope seam stays unit-level,
  consistent with EMU-5). Both were probed with curl before deciding the pin.
- **Docs:** no new downloads (corpus complete; DOCS-6 budget untouched).
  REQUIREMENTS.md "Test platforms" note updated: 40 → 41 tests + the
  MessageRegistry paragraph (§8.6/§11.4 + #014). Upstream anchor mockup
  `23d21f9a` re-verified via the pinned run script.
- **Emulator:** suite green 41/41; pin `23d21f9a` unchanged; self-signed
  cert regenerated under /tmp (test-only TLS, EMU-6 intact); trap cleanup
  confirmed; port 8443 closed after the run.
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` +1
  test (MessageRegistry contract). No production code change other than the
  UI increment below.
- **UI:** UI-2 increment — the **SensorsView error state** (a bare
  error-colored `Text` with no context) now announces as ONE merged semantics
  node (`Semantics(container: true, excludeSemantics: true, label: 'Unable to
  load sensors. <message>')` — the established OverviewView error-state
  pattern: cloud-off icon + title + detail message, visible text preserved),
  plus a new **Retry** `FilledButton.icon` that reloads via the existing
  `SensorsController.load()` (idempotent, `mounted`-guarded). Two new widget
  tests in `sensors_widget_test.dart`: (1) error state renders title +
  message + Retry and tapping Retry does not crash (re-runs the failing
  service double `_FailingSensorsService` throwing `RedfishException('boom')`);
  (2) the merged semantics node carries both strings while Retry stays a
  separately-announced control (the OverviewView error-test pattern).
- **Verification:** analyze 0; tests 309 passed / 1 skipped (baseline 307 →
  +2: the two SensorsView error-state widget tests; the emulator +1 test only
  runs under `REDFISH_EMULATOR_URL`); emulator suite 41/41 via run_tests.sh;
  issues validate OK; `git diff --check` clean; secret scan clean (`dart
  format` on the 3 touched Dart files: 0 changed).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — same GitHub
  credential blocker expected (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
  Commits ahead of origin/main: **66** before push attempt.
- **Next:** 1) Push the queued local commits (66) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager (authMethod dispatch, safe logout URI,
  token rehydrate, SessionTimeout + AbsoluteSessionTimeout* expiry — full
  auth surface pinned + schemas mirrored + session clauses cited §13.3.4);
  3) #018: build the lightweight discovery pass on the fully pinned contract
  — `getJson(query: {'\$expand': '.($levels=1)'})` collection fetch (transport
  + live round-trip pinned), gate on `ProtocolFeaturesSupported.ExpandQuery`,
  filter/project client-side, map 501/507 + the forceRefresh/`_error` cache
  fixes; or #008/#020: task poller — note the mockup's reset returns 204 with
  no Location, so GET-on-monitor must stay pinned in unit tests.

## 2026-10-24 02:30 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-24 02:25 (commit
  feb480c auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **68** (67 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 03:09 — DOCS (session-lifetime audit §13.3.4.3) + UI-2 FirmwareView error state

- **Baseline:** analyze 0; tests 309 passed / 1 skipped; starting commit f574035
  (branch `main` ahead 68 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS (alternation: EMULATOR 02:25 → DOCS next). **DOCS-17 —
  DSP0266 §13.3.4.3 session-lifetime audit + expiry pin.** Audited the session
  timeout contract against the mirrored `SessionService.json` +
  `SessionService.v1_2_0.json` (DOCS-12) and found the trace row "Session
  timeout handling … OK" was overstated: `Session.expiresAt`/`isExpired`
  existed but **nothing ever populated the deadline** — `AuthManager` never
  reads the SessionService resource. Closed the model-level gap with a small,
  safe, tested helper `Session.expiryFromService(Map<String, dynamic>?
  sessionService, {required DateTime createdAt})`:
  `SessionTimeout` (inactivity TTL) applies; `AbsoluteSessionTimeout` +
  `AbsoluteSessionTimeoutEnabled` (added v1_2_0) optionally bind the deadline
  to the **earlier** of the two (conservative re-auth before the service kills
  the session); absolute-only services still get a deadline; malformed values
  ignored; no body → null TTL. Six new unit tests in
  `test/redfish/models/models_test.dart`. The AuthManager fetch + wiring stays
  #015 (recorded as notes in the DOCS-17 REQUIREMENTS.md section).
- **Docs:** no new downloads (corpus complete; DOCS-6 budget untouched).
  REQUIREMENTS.md DOCS-17 trace table added + the session-timeout row
  corrected to Partial (model-level OK; wiring #015) + Last-audited header
  updated. Manifest anchors note updated. Anchors re-verified live 01:07 UTC:
  bmcweb master `fbb307a` (unchanged — `main` ref 422s, `master` is the
  branch), mockup `23d21f9a` (unchanged), DSP0266 1.25.0 PDF 200 /
  content-length 1,243,359 (unchanged), schema index 200. New FUTUREWORK item
  DOCS-18: mirror the DMTF Base message-registry payload (`Base.1.5.0.json`,
  the mockup-served version) so the §8.6/§11.4 MessageRegistry rows cite a
  real mirror file.
- **Emulator:** none this run (alternation; EMU-2 stays at 41 tests).
- **Code/tests:** `lib/redfish/models/session.dart` +`expiryFromService`
  helper; `test/redfish/models/models_test.dart` +6 expiry tests (309 → 315
  unit suite); no issue opened/closed (support for #015; DOCS-17 recorded in
  FUTUREWORK).
- **UI:** UI-2 increment — the **FirmwareView error state** (errorContainer
  card with icon + message) now announces as ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: 'Unable to load
  firmware. <message>')` — the established OverviewView/SensorsView error-state
  pattern), with the Retry button keeping its own control node. +1 widget test
  in `firmware_widget_test.dart` asserts the merged label + visible message
  text + separately-announced Retry control (315 → 316).
- **Verification:** analyze 0; tests 316 passed / 1 skipped (baseline 309 →
  +7); issues validate OK; `git diff --check` clean; secret scan clean (`dart
  format` on 4 touched Dart files: 2 changed, wrapping only).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — same GitHub
  credential blocker expected (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
  Commits ahead of origin/main: **69** before push attempt.
- **Next:** 1) Push the queued local commits (69) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — `Session.expiryFromService` is ready:
  wire the discovered SessionService body (or `DiscoveryContext.sessionService`)
  into login to set `expiresAt`, re-auth when `isExpired` flips, honor
  `AbsoluteSessionTimeout*` only when published (mockup serves v1_1_8 —
  `SessionTimeout=30` is the pinned emulator value); 3) DOCS-18: mirror
  `Base.1.5.0.json` from the DMTF registries path so the §8.6/§11.4
  MessageRegistry pin cites a real file; or #018 discovery pass on the pinned
  `$expand` contract.

## 2026-10-24 03:10 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-24 03:09 (commit
  410d43d auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **69** (68 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 04:01 — EMULATOR (Sessions/Session-resource contract + ResetType negative pin) + UI-2 PowerView/KVM error states

- **Baseline:** analyze 0; tests 316 passed / 1 skipped; starting commit 401f808
  (branch `main` ahead 70 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR (alternation: DOCS 03:09 → EMULATOR next). **EMU-2
  count 41 → 43** — two new live pins against the pinned mockup `23d21f9a`
  (verified clone at pin; server healthy on 8443; trap cleanup re-verified;
  port closed after the run):
  1. **Sessions collection + Session resource contract (#015/#026):** the
     Sessions collection is enumerable from the discovered SessionService URI
     (`#SessionCollection.SessionCollection`, `Members@odata.count` ≥ 1, every
     member names a session resource — never the collection); the pre-seeded
     session is a conformant `#Session.v1_7_1` (Id/Name/Description/UserName =
     Administrator, **no Password**). **Security-relevant negative pin:** a
     session minted via POST resolves to a body that **echoes the login
     Password** and lacks `@odata.type`/`SessionType` (non-conformant —
     DSP0266 §13.3.4 Session has no Password property). Client rule recorded:
     the #015 AuthManager must persist the token/location from the create
     RESPONSE HEADERS and never read session-resource bodies for secrets.
  2. **ResetType validation negative pin (#014/#022):** POST Reset with
     `ResetType: "Bogus"` returns **204 exactly like a valid value** — the
     pinned mockup does not validate the body; the client's 400
     `ResetTypeInvalid` path stays unit-level and the UI must pre-validate
     against the advertised allow-list (it already does).
  REQUIREMENTS.md "Test platforms" updated: 41 → 43 tests + both negative pins
  in prose (with §13.3.4 citation).
- **Docs:** no new downloads this run (corpus complete; DOCS-6 budget
  untouched). No manifest/anchor changes (upstream pins re-verified implicitly
  by the fresh clone checkout at `23d21f9a`).
- **Emulator:** suite green 43/43 via `tool/emulator/run_tests.sh` (pin
  unchanged); self-signed cert regenerated under /tmp (test-only TLS, EMU-6
  intact); trap cleanup confirmed; port 8443 closed after the run.
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` +2
  tests (Sessions collection/resource contract + ResetType 204 negative pin).
  No other production code change besides the UI increments below.
- **UI:** UI-2 increment — two remaining bare error-`Text` views upgraded to
  the established error-state pattern:
  - **PowerView inline error** now announces as ONE merged semantics node
    (`Power control failed. <message>` via `Semantics(container: true,
    excludeSemantics: true)` — visible text preserved) plus a **Retry**
    `TextButton.icon` that re-reads the power state via the existing
    `PowerController.refresh()` (idempotent, `mounted`-guarded, clears the
    error on success). +2 widget tests: (1) merged node + visible text +
    separately-announced Retry control; (2) tapping Retry re-runs the failing
    `fetchPowerState` double (`_FailingFetchPowerService`, fetchCalls == 1)
    without crashing.
  - **KvmView hard-load error** (error with zero consoles) now renders the
    full error state (cloud-off icon + title + detail) as ONE merged semantics
    node (`Unable to load KVM consoles. <message>`), Retry `FilledButton.icon`
    reloads via `KvmController.load()`; empty-with-error vs empty-clean are now
    distinct (the old code rendered an error-colored line above "No consoles
    found."). +2 widget tests mirroring the SensorsView pattern
    (`_FailingKvmService` double): merged node + visible texts + separate
    Retry control; tapping Retry increments fetchCalls (1 → 2) without
    crashing.
- **Verification:** analyze 0; tests 320 passed / 1 skipped (baseline 316 →
  +4: the two PowerView + two KvmView widget tests; the emulator +2 only runs
  under `REDFISH_EMULATOR_URL`); emulator suite 43/43 via run_tests.sh; issues
  validate OK; `git diff --check` clean; secret scan clean. NOTE: the runbook
  §6 tree-wide `dart format lib test test_integration tool` drifted 28
  untouched files (formatting only); reverted those to HEAD — only the 6
  intended files remain changed (0 formatting changes on the 5 touched Dart
  files after the drift revert).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — same GitHub
  credential blocker expected (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
  Commits ahead of origin/main: **70** before push attempt.
- **Next:** 1) Push the queued local commits (70) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — the Sessions/Session-resource pin
  landed: wire `Session.expiryFromService` into login (set `expiresAt`),
  re-auth on `isExpired`, keep token/location from create headers only (the
  fixture echoes Password in session bodies — never read secrets back);
  3) DOCS-18: mirror `Base.1.5.0.json` (DMTF registries path) so the §8.6/§11.4
  MessageRegistry rows cite a real mirror file; or #018 discovery pass on the
  pinned `$expand` contract.

## 2026-10-24 04:03 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-24 04:01 (commit
  e64624a auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **71** (70 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 05:20 — DOCS (message-registry payload mirror + Base registry delta audit) + UI-2 Dashboard error summary

- **Baseline:** analyze 0; tests 320 passed / 1 skipped; starting commit e64624a
  (branch `main` ahead 72 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS (alternation: EMULATOR 04:01 → DOCS next). **DOCS-18
  done** — mirrored the DMTF message-registry payload the pinned mockup serves
  (`Base.1.5.0.json`, the file behind the EMU-2 MessageRegistry contract's
  `Location[0].Uri`) plus the newest published version:
  1. `documentations/external/redfish/registries/Base.1.5.0.json` — 31,984
     bytes, SHA-256 `c10263417a076402a992f099db4e019c9d91f674d256df32a390b86a2c46492c`,
     **byte-identical** to `test/fixtures/redfish/dmtf_mockup/Registries/
     Base.1.5.0.json` (proven authentic — the fixture payload is the real
     DMTF publication, not fixture-generated). 60 Base.* templates
     (Message/Severity/NumberOfArgs) behind `RedfishError.code`/`firstMessage`.
  2. `documentations/external/redfish/registries/Base.1.24.0.json` — 138,295
     bytes, SHA-256 `abe0b78bba184f4b0e061696e4c9c43d76c029edb0ae5cf4902fdf3f979ef92d`
     (newest published; `@odata.type` `#MessageRegistry.v1_9_0.MessageRegistry`).
     **Delta audit:** 1.5.0 → 1.24.0 adds 65 templates (60 → 125, nothing
     removed), rewords 39 shared Message strings (e.g. `ActionNotSupported`
     gains quote marks around args; `GeneralError` adds an `@Message.ExtendedInfo`
     pointer), but **`NumberOfArgs` is stable for every shared key (0 changed)** —
     the emulator-pinned argument-count contract (`GeneralError` 0,
     `ActionNotSupported` 1) holds across the newest registry.
  REQUIREMENTS.md: §8.6 error-envelope row + the "Test platforms"
  MessageRegistry pin now cite the real mirror files; new DOCS-18 audit section
  (3 trace rows + newest-vs-served delta + anchors note). Manifest: 2 rows
  added (fetched 04:38/04:39 UTC). New bytes this run: 170,279 — inside the
  DOCS-6 budget.
- **Docs:** URLs fetched: `https://redfish.dmtf.org/registries/Base.1.5.0.json`
  and `https://redfish.dmtf.org/registries/Base.1.24.0.json` (both verified
  `curl -sSIL` 200 before download; registries index 200). Files added:
  `redfish/registries/Base.1.5.0.json` + `redfish/registries/Base.1.24.0.json`.
  Requirements found: registry payload provenance + newest-vs-served contract
  stability (recorded in REQUIREMENTS.md DOCS-18). Upstream anchors
  re-verified: bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266 1.25.0, schema
  index 200 — all unchanged.
- **Emulator:** none this run (no server started; DOCS alternation). The
  existing 43/43 suite still green from 04:01; no fixture change.
- **Code/tests:** no production code change besides the UI increment below.
  `documentations/external/README.md` +2 manifest rows; REQUIREMENTS.md §8.6
  row updated + DOCS-18 section appended; FUTUREWORK DOCS-18 checked off.
- **UI:** UI-2 increment — the **Dashboard `_ErrorSummary` card** ("N systems
  could not be reached") was the last bare error-surface in the established
  pattern: the icon + visible text now announce as ONE merged semantics node
  (`Unable to reach N systems. Retry available.` via `Semantics(container:
  true, excludeSemantics: true)`), with the Retry `TextButton` kept OUTSIDE
  the container so it retains its own control node. +2 widget tests in
  `dashboard_view_test.dart` (folded into the existing UI-1 group, reusing its
  harness): (1) merged node + visible text + separately-announced Retry; (2)
  single-system failure asserts the singular merged label (`Unable to reach 1
  system. Retry available.`). UI-1 Retry behaviour unchanged (existing tests
  still pass).
- **Verification:** analyze 0; tests 322 passed / 1 skipped (baseline 320 →
  +2); issues validate OK; `git diff --check` clean; secret scan clean (only
  prose protocol references in the docs diff). `dart format` on the 2 touched
  Dart files only (dashboard_view.dart + dashboard_view_test.dart) — no
  tree-wide drift.
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — same GitHub
  credential blocker expected (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key on this machine); local commit kept, not retried.
  Commits ahead of origin/main: **72** before push attempt.
- **Next:** 1) Push the queued local commits (72) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — `Session.expiryFromService` is ready:
  wire the discovered SessionService body into login to set `expiresAt`,
  re-auth on `isExpired`, keep token/location from create headers only;
  3) #018 discovery pass on the pinned `$expand` contract, or the
  `ResetActionInfo` ActionInfo-resource crawl (#022/#016, bmcweb-style).

## 2026-10-24 05:22 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after run 2026-10-24 05:20 (commit
  656adf9 auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **73** (72 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 05:48 — EMULATOR (UpdateService action surface + firmware seams) + UI-5 FirmwareView busy state

- **Baseline:** analyze 0; tests 322 passed / 1 skipped; starting commit e82b16f
  (branch `main` ahead 74 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR (alternation: DOCS 05:20 → EMULATOR next).
  **EMU-2 43 → 45 tests** — pinned the last un-pinned firmware seam, the
  UpdateService action surface (#008/#020):
  1. `FirmwareService.startSimpleUpdate` **live round-trip**: resolves the
     `#UpdateService.SimpleUpdate` target from the live `UpdateService` body,
     POSTs the `ImageURI`/`TransferProtocol` contract, and the DMTF mockup
     answers **204 with NO task-monitor `Location`** (it accepts any action
     body without validation — the same non-validating behavior as the 04:01
     ResetType negative pin). The returned `UpdateTask` therefore carries null
     taskUri / retryAfterSeconds / statusText: the 202-with-Location
     task-monitor path stays unit-level and the UI must not require a monitor
     URI for a queued handle.
  2. **HttpPushUri negative pin**: the fixture *advertises*
     `HttpPushUri: /FWUpdate` but does NOT *implement* it — POSTing a binary
     upload body fails with **400 and an EMPTY body** (no
     `@Message.ExtendedInfo` envelope; connection closed; GET /FWUpdate 404s).
     The #020 binary-push upload flow therefore stays unit-level, and the
     client normalizes the failure as `RedfishException` HTTP 400 with no
     error code (pinned in the test via `RedfishException.fromDioException`).
  REQUIREMENTS.md "Test platforms" updated 43 → 45 tests + both pins appended
  (with the server-behavior rationale: the mockup's POST handler JSON-decodes
  every non-Action body — source provenance recorded against the pinned
  `23d21f9a` upstream).
- **Docs:** none fetched (no corpus refresh; EMULATOR run). REQUIREMENTS.md
  Test-platforms section updated only.
- **Emulator:** official Redfish-Mockup-Server stood up per runbook §3 over
  HTTPS (self-signed /tmp cert), health-checked, suite run twice (43/45
  baseline → 45/45 with the new pins), server stopped via pkill + port-close
  verified (no background process left).
- **Code/tests:** +2 emulator tests in `emulator_suite_test.dart` (the two
  pins above); no production code change from the emulator work.
- **UI:** UI-5-style increment — **FirmwareView Start-update button busy
  state**: `FirmwareUiState.starting` added (distinct from `loading` so the
  button shows its own busy state only while the SimpleUpdate POST is in
  flight); while starting the `FilledButton` renders a 16px spinner +
  'Starting…' and is disabled, re-enabling on success (queued banner) or
  failure (error card). +3 controller tests (`firmware_controller_test.dart`,
  new file: starting raised/cleared on success + failure + load never sets
  starting) and +2 widget tests (`firmware_widget_test.dart` with a
  `_GateFirmwareService` Completer-gated double: busy state shows disabled +
  spinner + header loading semantics unchanged; failure re-enables + surfaces
  the error). Precedent: the PowerView confirm-dialog busy state (UI-5).
- **Verification:** analyze 0; tests **327 passed / 1 skipped** (baseline 322
  → +5: +3 controller, +2 widget; emulator +2 only runs under
  `REDFISH_EMULATOR_URL`); emulator suite 45/45 via
  `--dart-define=REDFISH_EMULATOR_URL=https://127.0.0.1:8443`; issues
  validate OK; `git diff --check` clean; secret scan clean (test creds are the
  standard mockup root/calvin, already in the repo; no tokens). `dart format`
  on the 5 touched Dart files only — no tree-wide drift.
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — the known GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead of
  origin/main: **74** before push attempt.
- **Next:** 1) Push the queued local commits (74) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture
  echoes Password in session bodies); 3) #018 discovery pass on the pinned
  `$expand` contract, or the `ResetActionInfo` ActionInfo-resource crawl
  (#022/#016, bmcweb-style).

## 2026-10-24 05:50 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above: failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **75** (74 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 06:45 — DOCS (served-version corpus mirror DOCS-19) + UI-2 SensorsView empty state

- **Baseline:** analyze 0; tests 327 passed / 1 skipped; starting commit e1b61dc
  (branch `main` ahead 75 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS (alternation: EMULATOR 05:48 → DOCS next). **DOCS-19
  done** — closed the "served-version" corpus gap: DOCS-2 (2026-10-22) had
  refreshed the six DOCS-2 families + LogService to their **newest** versioned
  definitions only, but the pinned `23d21f9a` mockup *serves* older
  `@odata.type` versions, violating the DOCS-11/12/13 invariant ("every
  `@odata.type` the mockup publishes has a versioned schema in the fixture").
  Mirrored the **mockup-served** versions for eight client-mapped families —
  `Sensor.v1_8_1` (42/42 sensors), `ComputerSystem.v1_22_0`,
  `Chassis.v1_25_0`, `AccountService.v1_15_0`, `SoftwareInventory.v1_10_1`,
  `LogService.v1_6_0`, `EthernetInterface.v1_12_0`,
  `MessageRegistry.v1_0_0` — plus the newest `MessageRegistry.v1_9_0` (the
  `@odata.type` behind the newest `Base.1.24.0` registry payload, DOCS-18) into
  both `documentations/external/redfish/schemas/v1/` and
  `test/fixtures/redfish/schemas/`. 9 files, 560,665 bytes total, inside the
  DOCS-6 budget. Property-delta audit verified every client-read field exists
  in the served versions (Sensor Reading/ReadingType/ReadingUnits/Thresholds;
  ComputerSystem identity/PowerState/Processor-MemorySummary/IndicatorLED/Boot;
  AccountService lockout surface — the #015 fields; SoftwareInventory
  Name/Version/Status/Updateable; LogService ServiceEnabled/OverWritePolicy/
  Entries/ClearLog action; EthernetInterface MAC/IPv4/IPv6/VLAN/LinkStatus;
  MessageRegistry RegistryPrefix/Version/OwningEntity/Messages/Language) — **no
  client code change needed**.
- **Docs:** 9 files fetched from `https://redfish.dmtf.org/schemas/v1/` (all
  200); manifest +9 rows; REQUIREMENTS.md +DOCS-19 audit section (served vs
  newest delta table) + trace rows updated to cite served files + trace-note
  "every published `@odata.type` has a versioned schema in the fixture"
  invariant; `documentations/redfish_reference/README.md` +DOCS-19 provenance
  paragraph. Anchors re-verified: bmcweb `fbb307a` (HEAD unchanged), mockup
  pin `23d21f9a` (unchanged), DSP0266 1.25.0 (unchanged), schema index 200,
  registries path 200.
- **Emulator:** none this run (DOCS alternation; no server started). The
  existing 45-test suite remains green from 05:48; no fixture behavior change
  (payloads untouched — only additive schema files in the fixture schemas dir).
- **Code/tests:** no production code change from the emulator/docs work. The
  fixture schema additions are reference-only (nothing under `test/` globs
  `fixtures/redfish/schemas/` — verified).
- **UI:** UI-2 increment — the **SensorsView empty state** ("No sensor data
  available") was the last bare-`Text` empty surface in the established
  pattern: it now renders an icon (`Icons.sensors_off_outlined`) + visible text
  inside a `Semantics(container: true, excludeSemantics: true, label: 'No
  sensor data available')` merged node — one self-describing announcement for
  screen readers, matching the error-state pattern without a Retry (nothing to
  retry: the load succeeded, the BMC reported no chassis). +2 widget tests in
  `sensors_widget_test.dart` (new `_EmptySensorsService` double): (1) icon +
  visible text render; (2) merged semantics node announces the label. Existing
  responsive no-overflow tests unchanged (empty state renders at 320/800/1300
  via the same Center+Padding layout, no overflow — suite covers the happy
  path; the empty-state column is `mainAxisSize.min`).
- **Verification:** analyze 0; tests **329 passed / 1 skipped** (baseline 327 →
  +2 widget); issues validate OK; `git diff --check` clean; secret scan clean
  (docs prose + schema JSON only, no tokens). `dart format` on the 2 touched
  Dart files only — no tree-wide drift (the gate's tree-wide `dart format` pass
  surfaced 28 files of pre-existing line-wrap churn; those files were restored
  to HEAD to keep this commit scoped — documented here so the next run does not
  re-format them unless editing them).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — the known GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead of
  origin/main: **75** before push attempt.
- **Next:** 1) Push the queued local commits (75) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture
  echoes Password in session bodies); 3) #018 discovery pass on the pinned
  `$expand` contract, or the `ResetActionInfo` ActionInfo-resource crawl
  (#022/#016, bmcweb-style).

## 2026-10-24 06:50 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 0d2771b
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **76** (75 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 08:15 — EMULATOR (chassis metrics + subsystem contracts) + UI-2 KVM empty state

- **Baseline:** analyze 0; tests 329 passed / 1 skipped; starting commit 0d2771b
  (branch `main` ahead 76 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR (alternation: DOCS 06:45 → EMULATOR next). Pinned
  the **chassis metrics + subsystem telemetry surface** the pinned `23d21f9a`
  mockup serves but the suite had never exercised — the exact payload shapes a
  #019 real-time telemetry receiver, the #006 overview power card, and a
  PSU-health display consume:
  1. `#EnvironmentMetrics.v1_3_1` at `/Chassis/1U/EnvironmentMetrics` — the
     ONE-resource aggregate: `TemperatureCelsius.Reading 39` +
     `PowerWatts.Reading 374` + `PowerLimitWatts.SetPoint 500` (with
     AllowableMax/Min + ControlMode) + `FanSpeedsPercent[2]` (DeviceName/
     Reading/SpeedRPM), every reading carrying a `DataSourceUri` that resolves
     into the Sensors collection (the test follows one: the fan DataSourceUri →
     `#Sensor` member with Reading 45 — the #007 surface is wired to the
     aggregate).
  2. `#ThermalSubsystem.v1_3_1` — Fans collection (4 members),
     FanRedundancy NPlusM groups (MinNeededInGroup 1 / MaxSupportedInGroup 2 /
     RedundancyGroup[2]), and `#ThermalMetrics.v1_3_1`
     `TemperatureSummaryCelsius` (Intake/Exhaust/Internal/Ambient with
     DataSourceUri → Sensors).
  3. `#PowerSubsystem.v1_1_1` — PowerSupplies collection (2 members) +
     `#PowerSupply.v1_5_3` Bay1 detail (Model/Manufacturer/FirmwareVersion/
     Status/LineInputStatus, the `#PowerSupply.Reset` action target, Metrics
     link) + the **documented negative**: the legacy `/Chassis/1U/Power`
     embedded PowerSupplies member reports `Status.Health == 'Warning'` while
     the current OverviewService rollup reads ComputerSystem/Chassis Status —
     a future #006/#019 improvement should surface PSU health (recorded as a
     REQUIREMENTS note; not a code change this run).
  Emulator suite 45 → **48** (all via `tool/emulator/run_tests.sh`; run twice —
  once manual-probe, once official script — both green; trap cleanup confirmed).
- **Docs:** none fetched this run (EMULATOR alternation; corpus untouched).
  REQUIREMENTS.md "Test platforms" section updated: 45 → 48 + the three pinned
  contracts + the documented PSU-health negative + a **corpus note (DOCS-20)**:
  the newly pinned families have NO versioned schema in the fixture/mirror yet
  (`EnvironmentMetrics.v1_3_1`, `ThermalSubsystem.v1_3_1`,
  `ThermalMetrics.v1_3_1`, `PowerSubsystem.v1_1_1`, `PowerSupply.v1_5_3`,
  `FanCollection`, `PowerSupplyCollection`) — mirror them next DOCS run to
  restore the "every published `@odata.type` for a client-relevant family has a
  versioned schema in the fixture" invariant (this EMULATOR run provably
  cannot: one primary workstream per run).
- **Emulator:** 48/48 green against pin `23d21f9a` (server + venv + cert
  already materialized in /tmp from the previous EMULATOR run; clock/fetch no
  change). New group `emulator: chassis metrics + subsystem contracts
  (#007/#019/#006)` with 3 tests.
- **Code/tests:** only `test_integration/emulator/emulator_suite_test.dart`
  changed for the primary work (no production code change — the pins document
  the wire contract for future #007/#019/#006 work). New tests: 3 emulator.
- **UI:** UI-2 increment — the **KVM empty state** ("No consoles found.") was
  the last bare-`Text` empty surface after the SensorsView empty-state
  conversion (06:45 run). A successful load with zero consoles now renders the
  established pattern: icon (`Icons.videogame_asset_off_outlined`) + visible
  text inside a `Semantics(container: true, excludeSemantics: true, label:
  'No consoles found.')` merged node — one self-describing announcement. No
  Retry: the load succeeded, there is nothing to retry (the SensorsView
  precedent). +2 widget tests in `kvm_widget_test.dart` via a new
  `_EmptyKvmService` double: (1) icon + visible text render; (2) merged
  semantics node announces the label. Existing responsive no-overflow tests
  unchanged (the empty state is a `Center` + `mainAxisSize.min` column — same
  layout family as the SensorsView empty state; the 320/800/1300 happy-path
  tests still pass).
- **Verification:** analyze 0; tests **331 passed / 1 skipped** (baseline 329 →
  +2 widget); emulator suite 48/48 via `--dart-define=REDFISH_EMULATOR_URL=...`
  and via `tool/emulator/run_tests.sh`; issues validate OK; `git diff --check`
  clean; secret scan clean (test creds are the standard mockup root/calvin,
  already in the repo; no tokens). `dart format` on the 3 touched Dart files
  only — no tree-wide drift.
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — the known GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead of
  origin/main: **76** before push attempt.
- **Next:** 1) Push the queued local commits (77) from a machine with GitHub
  credentials; 2) DOCS-20 — mirror the 7 newly pinned chassis-metrics/
  subsystem schemas (EnvironmentMetrics.v1_3_1, ThermalSubsystem.v1_3_1,
  ThermalMetrics.v1_3_1, PowerSubsystem.v1_1_1, PowerSupply.v1_5_3,
  FanCollection, PowerSupplyCollection) to restore the fixture invariant; 3) P1
  #015 AuthManager — wire `Session.expiryFromService` into login, re-auth on
  `isExpired`, keep token/location from create headers only.

## 2026-10-24 08:20 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit cf9e304
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **78** (77 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 10:40 — DOCS (DOCS-20 corpus mirror) + UI-2 Dashboard empty state

- **Baseline:** analyze 0; tests 331 passed / 1 skipped; starting commit 02436b5
  (branch `main` ahead 78 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS (alternation: EMULATOR 08:15 → DOCS next). Closed the
  **DOCS-20 corpus gap** the 08:15 EMULATOR chassis-contracts pins exposed —
  the newly pinned aggregate-telemetry families had no versioned schema in the
  fixture/mirror. Mirrored **11 files / 160,101 bytes** (inside the DOCS-6
  budget) from `https://redfish.dmtf.org/schemas/v1/` into
  `documentations/external/redfish/schemas/v1/` **and**
  `test/fixtures/redfish/schemas/` (fixture copies byte-identical via `cmp`):
  `EnvironmentMetrics.v1_3_1` (Temp/Power/Fan excerpts with DataSourceUri),
  `ThermalSubsystem.v1_3_1` (Fans + FanRedundancy + ThermalMetrics links),
  `ThermalMetrics.v1_3_1` (TemperatureSummaryCelsius Intake/Exhaust/Internal/
  Ambient), `PowerSubsystem.v1_1_1`, `PowerSupply.v1_5_3` (+
  `#PowerSupply.Reset` action), `PowerSupplyMetrics.v1_1_1` (the Metrics
  target), the **mockup-served** `Fan.v1_5_1` (Fans collection member type),
  `FanCollection`, `PowerSupplyCollection`, plus the `Redundancy.json` →
  `Redundancy.v1_7_1` chain the FanRedundancy groups cite (DOCS-14 precedent —
  REQUIREMENTS.md citations must resolve to real mirror files).
  **Property-delta audit:** every emulator-pinned field verified present in the
  mirrored defs — EnvironmentMetrics excerpts `$ref` the `Sensor` excerpts
  already mirrored in DOCS-19 (`Sensor.v1_8_1.json`), `FanRedundancy` items
  `$ref` `Redundancy.v1_7_1.json#/definitions/RedundantGroup`
  (MinNeededInGroup/MaxSupportedInGroup/RedundancyGroup/RedundancyType),
  thermal summaries are `SensorExcerpt` refs, PSU Model/Manufacturer/
  FirmwareVersion/LineInputStatus/Metrics + `#PowerSupply.Reset` all present —
  **no client code change needed**. Invariant restored: every `@odata.type`
  the pinned mockup publishes for a client-relevant family now has a versioned
  schema in the fixture (the 36 remaining un-mirrored published types —
  Certificate/Key/SecureBoot/USBController/etc. — are mockup-only breadth, not
  client-mapped families; documented in the audit section).
- **Docs:** 11 files fetched (each verified 200 first), SHA-256s recorded;
  manifest +11 rows; REQUIREMENTS.md "Last audited" updated + DOCS-20 audit
  table + corpus-note closed; `documentations/redfish_reference/README.md`
  +DOCS-20 provenance. All upstream anchors re-verified (2026-10-24): bmcweb
  `fbb307a`, mockup pin `23d21f9a`, DSP0266 1.25.0, schema index 200.
- **Emulator:** none this run (DOCS alternation; corpus-only + reference docs).
- **Code/tests:** no production code change for the primary work. UI: see below.
- **UI:** UI-2 increment — the **DashboardView empty state** ("No systems yet.
  Tap + to add a BMC.") was the last bare-`Text` empty surface on the
  dashboard. A state with zero systems now renders the established pattern:
  icon (`Icons.dns_outlined`) + visible text inside a
  `Semantics(container: true, excludeSemantics: true, label: 'No systems yet.
  Tap + to add a BMC.')` merged node — one self-describing announcement. No
  Retry: the empty list is not an error (the KVM/Sensors empty-state
  precedent). +1 widget test in `dashboard_view_test.dart`: merged semantics
  label + visible text + icon render. Existing 320/800/1300 no-overflow tests
  unchanged (the empty state is a `Center` + `mainAxisSize.min` column).
- **Verification:** analyze 0; tests **332 passed / 1 skipped** (baseline 331 →
  +1 widget); issues validate OK; `git diff --check` clean; secret scan clean
  (docs prose + schema JSON only, no tokens). `dart format` on the 2 touched
  Dart files only — no tree-wide drift.
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — the known GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead of
  origin/main: **78** before push attempt.
- **Next:** 1) Push the queued local commits (79) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture
  echoes Password in session bodies); 3) EMULATOR — the alternation queue is
  DOCS → EMULATOR next; candidates: pin the `#PowerSupply.Reset` action
  round-trip, the PowerSubsystem `Batteries` surface, or re-verify the corpus
  invariant against a fresh published-types crawl.

## 2026-10-24 10:45 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 963366e
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **80** (79 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 09:30 — EMULATOR (Batteries + action round-trips) + UI-2 FirmwareView empty state

- **Baseline:** analyze 0; tests 332 passed / 1 skipped; starting commit cec2c64
  (branch `main` ahead 81 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR (alternation: DOCS 10:40 → EMULATOR next). Pinned
  the **Battery surface** the 08:15 chassis-contracts run never touched — the
  last unpinned power-subsystem resource in the fixture. New test 1:
  `#BatteryCollection` → `#Battery.v1_2_2` Module1 detail (Model RKS-440DC /
  Manufacturer Contoso Power / FirmwareVersion 1.00 / Status OK / ChargeState
  Idle / CapacityRatedWattHours 20 / CapacityActualWattHours 19.41 /
  MaxDischargeRateAmps 10 / StateOfHealthPercent Reading 91 with
  `DataSourceUri` → Sensors/Battery1StateOfHealth resolving live to a
  `#Sensor` member) + the `#Battery.SelfTest`/`#Battery.Calibrate` action
  targets; then `#BatteryMetrics.v1_0_3` — the electrical telemetry
  (DischargeCycles 8.67, InputVoltage Reading 12.22 with DataSourceUri →
  Sensors/Battery1InputVoltage, TemperatureCelsius Reading 33 with
  DataSourceUri → Sensors/Battery1Temp resolving live (Reading 33,
  PhysicalContext Battery), StoredEnergyWattHours 19.41, ChargePercent 100,
  CellVoltages[8]) — the same wired-surface shape as the EnvironmentMetrics/
  ThermalMetrics pins, so #007/#019 can follow battery telemetry to raw
  sensors. New test 2: **action round-trip contract** — `#Battery.SelfTest`
  and `#Battery.Calibrate` POST → 204 (the mockup's `/Actions/` framework
  serves them; normalized by the client to `{'value': ''}`), while the
  **advertised `#PowerSupply.Reset` target is NOT implemented** — its URI
  (…/Bay1/PowerSupply.Reset) has no `/Actions/` segment, so POST returns 404
  with an empty body and the client normalizes it as `RedfishException` HTTP
  404. Recorded the #022/#006 rule: treat advertised action targets as
  candidates, never contracts, on this fixture. Emulator 48 → **50**, green
  via `tool/emulator/run_tests.sh` (pin `23d21f9a` unchanged) twice.
- **Docs:** none fetched this run (EMULATOR alternation). REQUIREMENTS.md
  "Last audited" + Test platforms 45 → 50 + the Batteries/round-trip/
  PowerSupply.Reset-404 section written; **new corpus gap DOCS-21 recorded**
  in FUTUREWORK (P1 docs): `#Battery.v1_2_2`/`#BatteryMetrics.v1_0_3`/
  `#BatteryCollection` are now pin-referenced client-relevant types with NO
  versioned schema in the fixture/mirror — queue mirroring
  `Battery.v1_2_2.json`, `BatteryMetrics.v1_0_3.json`, `BatteryCollection.json`
  (mockup-served versions + newest for the delta note, DOCS-12/13 precedent)
  for the next DOCS run to restore the invariant.
- **Emulator:** server + venv + cert re-created under /tmp (run 2026-10-24
  09:xx); `tool/emulator/run_tests.sh` end-to-end green 50/50 twice; trap
  cleanup verified (no leftover process/listener on 8443 after the run; one
  orphan from a `timeout`-killed first script invocation was SIGKILLed and
  confirmed gone).
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` +2
  tests (Battery surface + action round-trips). No production lib change for
  the primary work. UI: see below.
- **UI:** UI-2 increment — the **FirmwareView empty state** ("No firmware
  inventory reported.") was the last bare-`Text` empty surface on the firmware
  view (after the header/inventory-card/error-state conversions). A successful
  load with zero inventory now renders the established pattern: icon
  (`Icons.inventory_2_outlined`) + visible text inside a
  `Semantics(container: true, excludeSemantics: true, label: 'No firmware
  inventory reported.')` merged node — one self-describing announcement. No
  Retry: the load succeeded, there is nothing to retry (the KVM/Sensors/
  Dashboard precedent). +1 widget test in `firmware_widget_test.dart`:
  merged semantics label + visible text + icon render, and no overflow at
  320/800 px (`tester.takeException()` null after `setSurfaceSize`).
  Existing 320/800/1300 responsive tests unchanged (the empty state is a
  `Center` + `mainAxisSize.min` column).
- **Verification:** analyze 0; tests **333 passed / 1 skipped** (baseline 332 →
  +1 widget); emulator suite 50/50 via `--dart-define=REDFISH_EMULATOR_URL=...`
  and via `tool/emulator/run_tests.sh`; issues validate OK; `git diff --check`
  clean; secret scan clean (docs prose + schema/test JSON only; emulator creds
  are the standard mockup root/calvin already in the repo; no tokens).
  `dart format` touched only the 2 changed Dart files — drift in unrelated
  files reverted via `git checkout --` to keep the diff focused.
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — the known GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead of
  origin/main: **81** before push attempt.
- **Next:** 1) Push the queued local commits (82) from a machine with GitHub
  credentials; 2) DOCS-21 — mirror the Battery-family schemas
  (Battery.v1_2_2/BatteryMetrics.v1_0_3/BatteryCollection, mockup-served +
  newest) into the mirror + fixture to restore the published-type invariant;
  3) P1 #015 AuthManager — wire `Session.expiryFromService` into login (set
  `expiresAt` from the discovered SessionService), re-auth on `isExpired`,
  keep token/location from create headers only (the fixture echoes Password
  in session bodies).

## 2026-10-24 09:35 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit c6fe2a8
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **82** (81 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 12:30 — DOCS (DOCS-21 Battery corpus) + UI-2 feature-chips empty state

- **Baseline:** analyze 0; tests 333 passed / 1 skipped; starting commit 0dcd89c
  (branch `main` ahead 83 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last substantive run was EMULATOR
  09:30; FUTUREWORK had DOCS-21 explicitly queued "for the next DOCS run").
  Closed **DOCS-21** — mirrored the **Battery-family schemas** the EMU battery
  pins (48→50) reference: `Battery.v1_2_2.json` (mockup-served
  `#Battery.v1_2_2.Battery` — Module1 detail
  Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+
  ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent + the
  `#Battery.SelfTest`/`#Battery.Calibrate`/`#Battery.Reset` action defs),
  `BatteryMetrics.v1_0_3.json` (mockup-served
  `#BatteryMetrics.v1_0_3.BatteryMetrics` — InputVoltage/OutputVoltages/
  InputCurrentAmps/OutputCurrentAmps/StoredEnergyWattHours/TemperatureCelsius/
  ChargePercent/CellVoltages, `Sensor*Excerpt` refs + DataSourceUri), the
  `Battery.json`/`BatteryMetrics.json` aggregators + `BatteryCollection.json`,
  plus the **newest** `Battery.v1_5_0.json`/`BatteryMetrics.v1_1_0.json` for
  the delta note — 7 files / 95,718 bytes total, inside the DOCS-6 budget.
  The five served/aggregator files also copied into
  `test/fixtures/redfish/schemas/` (byte-identical, verified with `cmp`) —
  the "every published `@odata.type` for a client-relevant family has a
  versioned schema in the fixture" invariant restored for the battery family.
  Property-delta audit (written into REQUIREMENTS.md "DOCS-21"): every
  emulator-pinned field present in the served defs (34 / 23 props),
  `SensorExcerpt` refs resolve through the already-mirrored `Sensor.v1_8_1`
  (DOCS-19); newest versions additive only (BatteryChemistryType/
  EnergyStorageType/NominalOutputVoltage/ServicedDate; CRate/ERate) — the
  emulator-pinned contract holds across newest, **no client code change
  needed** (the battery family has no client model yet — future #007/#019
  telemetry work).
- **Docs:** 7 files from `https://redfish.dmtf.org/schemas/v1/` (fetched
  12:14 UTC, SHA-256s + manifest rows added to `documentations/external/
  README.md`; aggregator-count note 21 → 23; `redfish_reference/README.md`
  +DOCS-21 provenance). REQUIREMENTS.md "Last audited" header + EMU trace row
  (former DOCS-21 gap now "Corpus closed") + new "DOCS-21" audit section.
  **Anchors re-verified 12:15 UTC:** bmcweb master advanced `fbb307a` →
  `63a18f4e6188a77b713a8b22c8a95ab3d6c5a718` — all four mirrored bmcweb docs
  byte-identical at the new HEAD (SHA-256 verified, no refresh needed);
  mockup pin `23d21f9a` unchanged; DSP0266 1.25.0 unchanged (200, 1,243,359 B);
  schema index 200.
- **Emulator:** none this run (DOCS alternation; the mockup pin and fixture
  were not touched — the fixture gained only schema JSON).
- **Code/tests:** no production behaviour change for the primary work.
  UI change below (1 Dart file + 1 test file).
- **UI:** UI-2 increment — the **feature-chips empty state** on
  `SystemOverviewPage` ("No optional features discovered.") was the last
  bare-`Text` empty surface on the system overview; a successful discovery
  with zero optional features now renders the established pattern: icon
  (`Icons.category_outlined`) + visible text inside a
  `Semantics(container: true, excludeSemantics: true, label: 'No optional
  features discovered.')` merged node — one self-describing announcement. No
  Retry: discovery succeeded, nothing to retry (Dashboard/Firmware/KVM/
  Sensors precedent). `_featureChips` gained the `BuildContext` parameter.
  +1 widget test in `ui_widget_test.dart` (SystemOverviewPage group): merged
  semantics label + visible text + icon render, and no overflow at 320 px
  (`setSurfaceSize` + `takeException`, restored via `addTearDown` so the
  resize cannot leak into later tests — the two dialog tests caught the leak
  and now pass again). Suite 333 → **334**.
- **Verification:** analyze 0; tests **334 passed / 1 skipped** (baseline 333
  → +1 widget); issues validate OK; `git diff --check` clean; secret scan
  clean (docs prose + schema JSON + Dart only, no tokens). `dart format`
  touched only the 2 changed Dart files (0 reformatted).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — the known GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead of
  origin/main: **84** before push attempt.
- **Next:** 1) Push the queued local commits (85) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture
  echoes Password in session bodies); 3) EMULATOR per alternation — candidates:
  re-verify the corpus invariant against a fresh published-types crawl (all 18
  client-mapped families now have served+newest pairs), the `ResetActionInfo`
  ActionInfo-resource crawl stays a bmcweb-style code task (#022/#016), or
  pin a remaining un-pinned surface from the fixture.

## 2026-10-24 12:35 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 5cb5811
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **84** (83 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 15:00 — EMULATOR (corpus invariant live crawl + EventDestination detail) + UI-2 inventory-loading semantics

- **Baseline:** analyze 0; tests 334 passed / 1 skipped; starting commit ad0801c
  (branch `main` ahead 85 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last substantive run was DOCS
  12:30; EMULATOR 09:30 — EMULATOR had gone longest). Two integration tests
  added (suite 50 → **52**), both matching the 12:30 tracking's "Next"
  candidates:
  1. **Corpus invariant verified LIVE** — a new group
     `emulator: corpus invariant + event-destination detail` crawls the
     running DMTF mockup from `/redfish/v1/` (BFS following every relative
     `@odata.id` link + `@Redfish.ActionInfo` string, excluding `/Actions/`
     POST-only targets, cycle-safe visited set, graceful degradation on
     404s) and asserts that **every published `@odata.type` for a
     client-mapped family has its served-version schema in
     `test/fixtures/redfish/schemas/`** — the DOCS-19/20/21 invariant as a
     runnable check instead of a docs claim. The 33 client-mapped families
     are enumerated in the test; the crawl reached >50 published types and
     found zero missing served-version schemas (the DOCS-19/20/21 mirror
     work closed every gap — green). This pins the invariant so a future
     fixture/schema drift fails CI.
  2. **EventDestination detail pinned** (DOCS-7 bed for #019) — the four
     `EventService/Subscriptions` members are asserted with their
     `#EventDestination.v1_14_0` contract: Redfish
     (Destination/EventTypes/Context/Protocol/SubscriptionType RedfishEvent),
     SNMPv3 (`SNMP.AuthenticationProtocol` HMAC_SHA96 +
     `EncryptionProtocol` CFB128_AES128 with key material **null** on the
     wire — the secrets-never-populated rule), SMTP/OEM
     (`Protocol` SMTP / `SubscriptionType` OEM, mailto: Destination), and
     SyslogTCP (`SyslogFilters[0]` LogFacilities/LowestSeverity).
- **Docs:** none fetched this run (EMULATOR alternation; corpus unchanged —
  the invariant test proved the existing mirror complete). REQUIREMENTS.md
  "Last audited" header rewritten for the EMU run + a new paragraph under
  the test-platforms block (corpus invariant + EventDestination pins);
  Test platforms count 50 → 52.
- **Emulator:** server pinned `23d21f9a` (unchanged), suite **52/52** via
  `tool/emulator/run_tests.sh` (the corpus crawl itself runs ~2s inside the
  suite); no server/action surprises — the crawl's graceful 404 handling
  tolerated the advertised-but-not-served links exactly as the discovery
  engine contract describes.
- **Code/tests:** `test_integration/emulator/emulator_suite_test.dart` (+2
  tests, +`dart:io` import); `documentations/external/redfish/REQUIREMENTS.md`
  (audit + test-platforms prose); `FUTUREWORK.md` (EMU-2 50 → 52, Last
  updated/Current focus, UI-2 entry). No production code change for the
  primary work.
- **UI:** UI-2 increment — `FirmwareView`'s inventory area previously showed
  a **bare detached `Text('Loading inventory…')`** while the inventory fetch
  was in flight (the last bare loading `Text` on the firmware view). It now
  renders inside a `Semantics(container: true, excludeSemantics: true,
  label: 'Loading firmware inventory')` node — one self-describing
  announcement for the specific surface still loading, visible text
  preserved (header already announces the screen-level loading state).
  +1 widget test in `test/features/firmware/firmware_widget_test.dart`
  asserts the merged label + visible text. Suite 334 → **335**.
- **Verification:** analyze 0; tests **335 passed / 1 skipped** (baseline 334
  → +1 widget); emulator suite 52/52 via `tool/emulator/run_tests.sh`;
  issues validate OK; `git diff --check` clean; secret scan clean (Dart +
  docs prose only; no tokens). `dart format` touched only the 3 changed Dart
  files — drift in unrelated files reverted via `git checkout --` to keep
  the diff focused (the established pattern).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** — the known GitHub
  credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead
  of origin/main: **86** before push attempt.
- **Next:** 1) Push the queued local commits (87) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture
  echoes Password in session bodies); 3) DOCS per alternation — candidates:
  verify the new corpus-invariant test's family list stays in sync with any
  future family additions (it is the executable form of the DOCS-19/20/21
  claim), or fold the EventDestination detail into the DOCS-7 decision
  review (a receiver still out of scope this milestone).

## 2026-10-24 15:05 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit f3f9875
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **86** (85 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 13:05 — DOCS (frequent-family freshness audit DOCS-22) + UI-2 not-found semantics

- **Baseline:** analyze 0; tests 335 passed / 1 skipped; starting commit 4b3e3ac
  (branch `main` ahead 87 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last substantive runs 09:30 EMU →
  12:30 DOCS → 15:00 EMU — DOCS overdue). Ran a **frequent-family newest-version
  freshness audit (DOCS-22)**: extracted the newest published version per
  client-mapped family from the live DMTF schema index
  (`https://redfish.dmtf.org/schemas/v1/`, 200 OK 3.4 MB) and compared against
  the mirrored "newest" files. **8 of 33 families had advanced upstream**:
  `EnvironmentMetrics` v1_3_1→v1_7_0, `Fan` v1_5_1→v1_6_0, `PowerSubsystem`
  v1_1_1→v1_2_0, `PowerSupply` v1_5_3→v1_8_0, `PowerSupplyMetrics` v1_1_1→v1_3_0,
  `TaskService` v1_2_1→v1_3_0, `ThermalMetrics` v1_3_1→v1_3_3, `ThermalSubsystem`
  v1_3_1→v1_5_0. Mirrored the 8 newest files into
  `documentations/external/redfish/schemas/v1/` (189,768 bytes total, inside
  the DOCS-6 budget; manifest rows + SHA-256s verified; fixture untouched —
  keeps mockup-served versions per the DOCS-21 precedent). Property-delta
  audit: **every delta is additive-only** (EnvironmentMetrics adds
  AmbientTemperatureCelsius/BarometricPressureMm/CurrentAmps/
  DewPointProximityCelsius/Voltage; Fan adds RatedSpeedRPM/RatedSecondarySpeedRPM;
  PowerSubsystem adds Applied/Enabled/Links/LoadPercentThreshold/
  MaxRampRateWattsPerSecond/PowerBrake(+sensors)/TemperatureThreshold;
  PowerSupply adds Certificates/VoltageControl; PowerSupplyMetrics adds
  ChargePercent/Line*/PolyPhase*/PowerLoadPercent; TaskService adds a
  `#TaskService.DeleteAllCompletedTasks` action + `TaskMonitorAutoExpirySeconds`
  — a #008/#020 task-lifecycle note; ThermalMetrics v1_3_3 is a **structural
  no-op** (copyright + anyOf-normalization only, verified by deep diff);
  ThermalSubsystem adds FansFullSpeedOverrideEnable/Filters) — **no client code
  change needed** (none of the new fields sit on the current reader surface).
  The other 25 client-mapped families are unchanged upstream.
- **Docs:** fixed **stale-provenance inconsistency** from DOCS-21: manifest rows
  + REQUIREMENTS.md Sources block still cited bmcweb `fbb307a` after DOCS-21
  advanced the pin to `63a18f4…`. Re-verified **live**:
  `curl` fetch of all four bmcweb docs at `63a18f4…` HEAD → SHA-256
  **byte-identical** to the mirrored copies (re-verified 12:45 UTC); manifest
  rows + Sources block + anchors section updated to `63a18f4`. All anchors
  re-verified: bmcweb `63a18f4` (still HEAD), mockup `23d21f9a` (unchanged),
  DSP0266 1.25.0 (unchanged; 1.26.0 probe → 404), schema index 200. New bytes
  this run: 189,768 (inside DOCS-6); no PDF, no large artifact.
- **Emulator:** suite re-run **52/52** via `tool/emulator/run_tests.sh`
  (corpus-invariant + EventDestination + battery groups all green) — the 33
  family list in the crawler stays in sync since served versions are unchanged.
- **Code/tests:** no production code change for the primary work. UI-2:
  `SystemOverviewPage` `System not found` fallback converted from a bare
  detached `Text` to the established merged `Semantics(container +
  excludeSemantics, label: 'System not found')` node with
  `Icons.search_off_outlined` (one self-describing announcement, no Retry — a
  nonexistent system is not an error). +1 widget test (merged label + visible
  text + icon + 320 px no-overflow via the `addTearDown` restore pattern).
  Also fixed the journal-flagged manual `setSurfaceSize` restore in the
  FirmwareView no-overflow test → `addTearDown` (12:30 journal noted it for
  this run). Suite 335 → **336**.
- **Verification:** analyze 0; tests **336 passed / 1 skipped** (baseline 335
  → +1 widget); emulator suite 52/52; issues validate OK; `git diff --check`
  clean; secret scan clean (docs prose + schema JSON + Dart only; no tokens).
  `dart format` touched only the 2 changed Dart files; drift in 28 unrelated
  files reverted via `git checkout --` to keep the diff on 5 files.
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** (expected) — the known
  GitHub credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/
  GIT_TOKEN env, no SSH key); local commit kept, not retried. Commits ahead of
  origin/main: **87** before push attempt.
- **Next:** 1) Push the queued local commits (88) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture
  echoes Password in session bodies); 3) EMULATOR per alternation — the
  DOCS-22 note adds a #008/#020 candidate: surface
  `TaskMonitorAutoExpirySeconds` from TaskService when the poller lands, and
  re-run the corpus crawl on any future family additions.

## 2026-10-24 13:10 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 13d9394
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **88** (87 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 16:30 — EMULATOR (Bios @Redfish.Settings ETag surface) + UI-2 shell not-found semantics

- **Baseline:** analyze 0; tests 336 passed / 1 skipped; starting commit 884428f
  (branch `main` ahead 89 of origin); issues validate OK; working tree clean; no
  stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last substantive runs: EMU 15:00 →
  DOCS 13:05 → EMU overdue again). Added a live pin for the **Bios
  `@Redfish.Settings` surface** (suite 52 → **53**): the DMTF mockup's
  `/Systems/437XR1138R2/Bios` resource carries the DSP0266 §9.9
  `@Redfish.Settings` payload annotation with a real **settings-object ETag**
  (`9234ac83b9700123cc32`) — the ONLY ETag-ish token this fixture serves (no
  resource-level `@odata.etag` / HTTP ETag header). This **refines the long-held
  tracking note** "etag behaviour cannot be pinned on this fixture": header-level
  ETags are absent, but the settings-object ETag IS pinable and is exactly the
  optimistic-concurrency token a #016 PATCH/If-Match flow must send. The pin also
  covers: the pending-settings resource (`Bios/Settings`,
  `#Bios.v1_2_2.Bios` Id `Settings`) whose attribute set differs from the current
  one (EmbeddedSata Raid→Ahci, ProcTurboMode Enabled→Disabled — the
  "pending vs current" compare a BIOS-config editor presents),
  `@Redfish.Settings.Messages[0]` `Base.1.0.SettingsFailed` + RelatedProperties
  from the last failed apply, `#Bios.ResetBios` POST → 204 (served by the
  mockup's `/Actions/` framework), and `#Bios.ChangePassword` advertised
  (credential-bearing action — target pinned only, never round-tripped with real
  secrets). New test lives in the overview/log group of
  `test_integration/emulator/emulator_suite_test.dart`.
- **Docs:** REQUIREMENTS.md "Last audited" rewritten for the EMU run + the
  test-platforms block updated (52 → 53 tests; new Bios `@Redfish.Settings`
  paragraph). No corpus refresh — anchors unchanged (mockup `23d21f9a`,
  bmcweb `63a18f4`, DSP0266 1.25.0).
- **Emulator:** server re-pinned `23d21f9a` (fresh clone, byte-identical
  fixture), HTTPS self-signed test-only cert, suite run via
  `tool/emulator/run_tests.sh` → **53/53 passed**; server stopped after (manual
  start during probing, SIGKILL confirmed).
- **Code/tests:** one emulator test added (53). UI-2 increment: **SystemShell
  `System not found` scaffold fallback** converted from a bare `Text` to the
  established merged `Semantics(container + excludeSemantics,
  label: 'System not found')` node with `Icons.search_off_outlined` (one
  self-describing announcement; no Retry — a nonexistent system id is not an
  error; matches the SystemOverviewPage fallback fixed 13:05). +1 widget test
  asserts the merged `bySemanticsLabel` node + visible text + icon + 320 px
  no-overflow via `addTearDown`. Unit suite 336 → **337**.
- **Verification:** analyze 0; tests **337 passed / 1 skipped** (baseline 336 →
  +1 widget); emulator suite 53/53; issues validate OK; `git diff --check`
  clean; secret scan clean (Dart + docs prose only; the test asserts the Bios
  ChangePassword *target* but sends no credentials). `dart format` touched 29
  files; drift in 25 unrelated files reverted via `git checkout --` to keep the
  diff on 4 files (the established pattern).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** (expected) — the known
  GitHub credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key); local commit kept, not retried. Commits ahead of origin/main:
  **89** before push attempt.
- **Next:** 1) Push the queued local commits (90) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture echoes
  Password in session bodies); 3) DOCS per alternation — the new Bios Settings
  pin adds a candidate: mirror the served `Bios.v1_2_2.json` +
  `Settings.v1_3_5.json` (the mockup publishes `#Bios.v1_2_2.Bios` +
  `#Settings.v1_3_5.Settings`; they are in the corpus crawl but NOT yet in the
  client-mapped family list — decide whether a BIOS-config feature makes them
  client-mapped, which would pull them into the DOCS-19/20/21 fixture invariant).

## 2026-10-24 16:45 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 47108ad
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **90** (89 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 17:38 — DOCS (Bios/Settings corpus) + UI-2 not-found fallbacks

- **Baseline:** analyze 0; tests 337 passed / 1 skipped; starting commit ee05b26
  (branch `main` ahead 91 of origin); issues validate OK; working tree clean; no
  stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last substantive runs: EMU 16:30 →
  DOCS 13:05; DOCS overdue). Closed the corpus gap the EMU Bios-`@Redfish.Settings`
  pin (EMU 52→53) exposed: its two published types (`#Bios.v1_2_2.Bios`,
  `#Settings.v1_3_5.Settings`) were reached by the corpus-invariant crawl but had
  no versioned schema in the external mirror. Mirrored the **mockup-served**
  versions (`Bios.v1_2_2.json`, `Settings.v1_3_5.json`) per the
  DOCS-12/13/19/20/21 "newest + served" pair precedent, plus the **newest**
  published versions (`Bios.v1_3_0.json`, `Settings.v1_5_0.json`) found on the
  live schema index — 4 files / **67,020 bytes**, inside the DOCS-6 budget;
  SHA-256s + manifest rows verified. Delta audit additive-only: **Bios
  v1_2_2→v1_3_0 adds only `Passwords`** (13→14 props; the password-management
  resource superseding the action-based ChangePassword — a #015/#026 input, no
  code change); **Settings v1_3_5→v1_5_0 is a property no-op** (6→6).
  **Client-mapped decision: Bios/Settings stay NOT client-mapped** — the client
  reads only `ComputerSystem.BiosVersion` (overview firmware line); no
  BIOS-config editor exists, so the emulator corpus-invariant family list is
  untouched and no fixture-schema duty attaches. Filled the candidate feature as
  **#028** (BIOS configuration editor) with full acceptance criteria incl. the
  fixture duty that would make the families client-mapped.
- **Docs:** https://redfish.dmtf.org/schemas/v1/ index (+4 rows in the README
  manifest: Bios.v1_2_2/v1_3_0, Settings.v1_3_5/v1_5_0 with SHA-256s + fetched
  15:17 UTC); REQUIREMENTS.md gained a DOCS-23 section (delta table + the
  client-mapped decision) + the trace-note Bios paragraph now cites the real
  mirror files; anchors re-verified: bmcweb `63a18f4` (still HEAD, docs
  byte-identical), mockup `23d21f9a`, DSP0266 1.25.0 (1.26.0 probe → 404),
  schema index 200.
- **Emulator:** suite re-run **53/53** via `tool/emulator/run_tests.sh` —
  includes the corpus-invariant live crawl, which green-lights the
  "Bios/Settings stay not-client-mapped" decision (their published types are
  visited but skipped, so the 33-family list stays in sync).
- **Code/tests:** no production change from the docs audit. Issue #028 created
  (P2 feature, `issues/open/028-*`). UI-2 increment: **PowerView, SensorsView,
  KvmView "System not found" fallbacks** converted from the bare
  `Center(child: Text(...))` to the established merged
  `Semantics(container + excludeSemantics, label: 'System not found')` node with
  `Icons.search_off_outlined` (one self-describing announcement; no Retry — a
  nonexistent system id is not an error; matches SystemShell +
  SystemOverviewPage fixed earlier today). +1 widget test per view (merged
  `bySemanticsLabel` node + visible text + icon + 320 px no-overflow via
  `addTearDown`). Suite 337 → **340**.
- **Verification:** analyze 0; tests **340 passed / 1 skipped** (baseline 337 →
  +3 widget); emulator suite 53/53; issues validate OK; `git diff --check`
  clean; secret scan clean (Dart + docs prose + public DMTF schema JSONs; the
  #028 issue mentions ChangePassword only as never-round-tripped, no
  credentials). `dart format` touched 27 files; drift in 27 unrelated files
  reverted via `git checkout --` to keep the diff on 9 files + 5 new files (the
  established pattern).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** (expected) — the known
  GitHub credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key); local commit kept, not retried. Commits ahead of origin/main:
  **91** before push attempt.
- **Next:** 1) Push the queued local commits (92) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture echoes
  Password in session bodies); 3) EMULATOR per alternation — candidates: re-run
  the corpus-invariant crawl on future family additions, or pin a remaining
  un-pinned surface; #028 (BIOS-config editor) is the new P2 candidate with the
  exact fixture duty recorded in its issue file.

## 2026-10-24 17:40 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit ad744fe
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **92** (91 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 18:40 — EMULATOR (Boot override + live PATCH round-trip + discovery Links graph + VirtualMedia) + #016 PATCH transport

- **Baseline:** analyze 0; tests 340 passed / 1 skipped; starting commit e45157a
  (branch `main` ahead 93 of origin); issues validate OK; working tree clean; no
  stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last substantive runs: DOCS 17:38 →
  EMU 16:30; EMU overdue). Recloned the official Redfish-Mockup-Server (pin still
  `23d21f9a3610f6b6fbb71ffc941296b159a524d2`, byte-identical fixture), regenerated
  the /tmp self-signed test-only cert, ran the suite live → **57/57** (was 53).
  Four new pins: (1) **ComputerSystem Boot override surface** —
  `BootSourceOverrideEnabled (Once)/Mode (UEFI)/Target (Pxe)` +
  `BootSourceOverrideTarget@Redfish.AllowableValues` (10 values:
  None/Pxe/Cd/Usb/Hdd/BiosSetup/Utilities/Diags/SDCard/UefiTarget) +
  `UefiTargetBootSourceOverride` — a boot-control UI must pre-validate against
  the annotation allow-list (#022/#016 rule); (2) **FIRST live PATCH pin** —
  `RedfishClient.patchJson` (new DSP0266 §6.5.2 transport) PATCHes
  `Boot.BootSourceOverrideEnabled: Disabled` → 204 with no content and the
  change **persists** into the served resource (GET confirms; the mockup keeps
  PATCHes in memory — the on-disk fixture stays byte-identical, verified);
  negative pin: the mockup applies ANY PATCH body value unvalidated
  (`IndicatorLED: "Bogus"` 204s AND persists) — same advertised-not-enforced
  rule as ResetType, so the client pre-validates and the 400+
  `@Message.ExtendedInfo` validation path stays unit-level (header-level
  `@odata.etag`/HTTP ETags remain absent → If-Match stays unit-level); (3)
  **discovery Links graph** — Systems→Chassis→Manager traversal resolves all
  three hops (System.Links.Chassis/ManagedBy, Chassis.Links.ComputerSystems/
  ManagedBy/ManagersInChassis, Manager.Links.ManagerForServers/ManagerForChassis/
  ManagerInChassis + ManagerType/FirmwareVersion/Model) for #018/#006; (4)
  **VirtualMedia read surface** — `#VirtualMedia.v1_6_3` CD1 (Applet,
  CD/DVD, Inserted, Image `redfish.dmtf.org/freeImages/freeOS.1.1.iso`) +
  Floppy1 (URI, Floppy/USBStick) for a future boot-media UX; negative: no
  InsertMedia/EjectMedia action targets on this fixture (advertised-as-candidate
  rule); VirtualMedia stays NOT client-mapped (corpus-invariant list unchanged,
  no fixture-schema duty). The PATCH test mutates the in-memory mockup, so both
  mutations are restored in `finally` blocks (Boot → Once, IndicatorLED → Off;
  verified restored after the run).
- **Docs:** no corpus download this run (EMU stream). REQUIREMENTS.md updated:
  PATCH row (185) status `not implemented` → `Partial — transport done;
  If-Match + actions stay #016`; "Last audited" header rewritten for the EMU
  run; test-platforms count 53 → 57 + four new pin paragraphs.
- **Emulator:** suite live **57/57** via the manual server (fresh clone,
  cert, `-S` form — the same command `tool/emulator/run_tests.sh` runs);
  server stopped after (SIGKILL confirmed, no background process left);
  on-disk fixture byte-identical before/after.
- **Code/tests:** `lib/redfish/client/redfish_client.dart` gained
  `patchJson(path, body:, headers:)` (mirrors `postJson` via `_dio.patch` —
  204/200 normalized via `_asMap`, non-2xx → `RedfishException`). +3 unit tests
  in `auth_manager_test.dart` "RedfishClient transports" (patchJson 204
  no-content → empty map / 200 with body decodes / non-2xx throws). Suite 340 →
  **343**.
- **UI:** skipped — the primary workstream (EMU pins + the #016 PATCH transport)
  consumed the budget; the remaining UI-2 candidates (focus order,
  non-card labels) need a deeper hunt and a newly converted firmware empty/
  loading states this cycle already covered every view. Recorded, not rushed.
- **Verification:** analyze 0; tests **343 passed / 1 skipped** (baseline 340 →
  +3 patchJson unit); emulator suite 57/57; issues validate OK; `git diff
  --check` clean; secret scan clean (Dart + docs prose; the VirtualMedia Image
  values are public DMTF fixture data, no credentials). `dart format` applied to
  the 3 code files; drift only in the intended files (5 modified).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** (expected) — the known
  GitHub credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key); local commit kept, not retried. Commits ahead of origin/main:
  **93** before push attempt.
- **Next:** 1) Push the queued local commits (94) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only; 3) #016 next step —
  wire If-Match/`@odata.etag` using the new `patchJson` + the settings-object
  ETag `9234ac83b9700123cc32` (the only pinable concurrency token), then a
  Boot/IndicatorLED PATCH action + UI; DOCS after that per alternation (DOCS-22
  freshness audit is repeatable).

## 2026-10-24 18:42 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 1c06fc6
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **94** (93 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 19:25 — DOCS (EventDestination + VirtualMedia corpus mirror) + UI-2 router fallback

- **Baseline:** analyze 0; tests 343 passed / 1 skipped; starting commit 1108b55
  (branch `main` ahead 95 of origin); issues validate OK; working tree clean; no
  stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last substantive runs: DOCS 17:38 →
  EMU 18:40; DOCS due). The EMU-2 pins read two published types outside the 33
  client-mapped families — `#EventDestination.v1_14_0.EventDestination` (the
  four `Subscriptions` members: Redfish/SNMPv3/SMTP-OEM/SyslogTCP transports,
  DOCS-7 bed for #019) and `#VirtualMedia.v1_6_3.VirtualMedia` (the system
  boot-media read surface: CD1 Applet + Floppy1 URI, #028 input) — but the
  external corpus had **no schemas for either family**. DOCS-24 mirrored both
  as aggregator + **mockup-served** version + **newest** published version +
  collection type (the DOCS-12/13/19/20/21/23 "newest + served" pair
  precedent): 8 files / 194,278 bytes total, inside the DOCS-6 budget, into
  `documentations/external/redfish/schemas/v1/` only (neither family is
  client-mapped → no fixture duty; the corpus-invariant family list untouched).
  Delta audit (additive-only): `EventDestination.v1_14_0`→`v1_17_1` adds
  BackupDestinations/Certificates/ClientCertificates/EventFormatType/
  HeartbeatIntervalMinutes/HttpHeaders/OEM*/OriginResources/SendHeartbeat/
  Severities/SubordinateResources/SyslogFilters/VerifyCertificate (+Actions);
  `VirtualMedia.v1_6_3`→`v1_7_0` adds Certificates/EjectPolicy/EjectTimeout/
  HTTPHeaders/Password/Status/TransferMethod/TransferProtocolType/UserName
  (+Actions) — the `Password`/`UserName` additions are a #028 boot-media
  security note (never read back). Every EMU-2-pinned field is present in the
  served versions → **no client code change**.
- **Docs:** 8 DMTF schema files fetched 19:18 UTC from
  `https://redfish.dmtf.org/schemas/v1/` (SHA-256s + sizes in the manifest);
  manifest README updated (8 rows + aggregator-count note 23 → 25);
  REQUIREMENTS.md DOCS-24 audit table + client-mapped decision (both families
  stay NOT client-mapped); anchors re-verified 19:15–19:20 UTC: bmcweb master
  `63a18f4e6188a77b713a8b22c8a95ab3d6c5a718` (still HEAD via GitHub API),
  mockup pin `23d21f9a3610f6b6fbb71ffc941296b159a524d2` (still HEAD of `main`
  via GitHub API), DSP0266 1.25.0 (hub link unchanged; 1.26.0 probe → 404),
  schema index 200 (live curl). Freshness spot-check of the two new families:
  newest on the live index are exactly the mirrored files.
- **Emulator:** none this run (DOCS stream; no emulator code touched — the
  corpus-invariant test list is unchanged, so the suite result is unaffected).
- **Code/tests:** `lib/core/router/app_router.dart` — the GoRouter
  `errorBuilder` route-not-found fallback converted from a bare
  `Center(child: Text(...))` to the established UI-2 merged
  `Semantics(container + excludeSemantics, label: 'Route not found: <uri>')`
  node with `Icons.search_off_outlined` (one self-describing announcement; no
  Retry — an unknown route is not an error; the URI is dynamic so the label
  mirrors the visible text). New `test/core/router_test.dart` — +2 widget
  tests (merged `bySemanticsLabel` node + visible text + icon, and no overflow
  at 320 px via `addTearDown`). Suite 343 → **345**.
- **UI:** the router not-found fallback was the **last bare-`Text` fallback
  surface in the app** — every error/empty/loading/not-found state across
  Dashboard/Sensors/Firmware/KVM/Power/Overview/SystemShell/SystemOverviewPage
  and now the router layer uses the merged-semantics pattern. Remaining UI-2:
  focus order + remaining non-card labels (recorded).
- **Verification:** analyze 0; tests **345 passed / 1 skipped** (baseline 343 →
  +2 widget); issues validate OK; `git diff --check` clean; secret scan clean
  (Dart + docs prose + public DMTF schema JSONs — no credentials; the
  EventDestination `SNMP` blocks in the schemas are property defs, not key
  material). `dart format` applied to the 2 touched Dart files; drift in 25
  unrelated files reverted via `git checkout --` to keep the diff on 8 new
  schema files + README + REQUIREMENTS + app_router.dart + router_test.dart.
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** (expected) — the known
  GitHub credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key); local commit kept, not retried. Commits ahead of origin/main:
  **95** before push attempt.
- **Next:** 1) Push the queued local commits (96) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture echoes
  Password in session bodies); 3) EMULATOR per alternation — candidates: re-run
  the corpus-invariant crawl on future family additions, or pin a remaining
  un-pinned surface (the EventDestination `SyslogFilters`/`Severities` and
  VirtualMedia `TransferMethod` newest-schema fields are candidates only if a
  family becomes client-mapped); #028 (BIOS-config editor) is the new P2
  candidate with the exact fixture duty recorded in its issue file.

## 2026-10-24 19:26 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 3c60999
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **96** (95 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 20:12 — EMULATOR (SecureBoot boot-integrity surface + SecureBootDatabase + If-Match precondition boundary)

- **Baseline:** analyze 0; tests 345 passed / 1 skipped; starting commit e2b1b0d
  (branch `main` ahead 97 of origin); issues validate OK; working tree clean; no
  stash, no crashed-run leftovers. Emulator suite re-run at start: 57/57.
- **Primary work:** EMULATOR per alternation (last substantive runs: DOCS 19:25
  → EMU 18:40; EMU due). Pinned the **SecureBoot boot-integrity surface** the
  fixture serves but the suite never read: `#SecureBoot.v1_1_1.SecureBoot`
  (SecureBootEnable false / SecureBootCurrentBoot Disabled / SecureBootMode
  UserMode) with the `#SecureBoot.ResetKeys` action +
  `ResetKeysType@Redfish.AllowableValues` (ResetAllKeysToDefault/DeleteAllKeys/
  DeletePK) — the annotation-form allow-list rule (#022/#016) now pinned on a
  SECOND system action family; the action target POST → 204 via the mockup's
  `/Actions/` framework and a bogus `ResetKeysType` ALSO 204s (the mockup never
  validates action bodies — the 400 path stays unit-level). Also pinned the
  **SecureBootDatabase collection** (`#SecureBootDatabaseCollection`, 8 members:
  PK/KEK/db/dbx + defaults) with per-database detail —
  `#SecureBootDatabase.v1_0_2.SecureBootDatabase` carries its OWN
  `#SecureBootDatabase.ResetKeys` with a *smaller* allow-list (PK omits
  DeletePK — per-resource annotation rule) + a Certificates link. Finally
  closed the open **#016 If-Match question**: a PATCH sent with a stale
  `If-Match: "bogus-stale-etag"` header is answered 204 AND persists — the
  mockup never evaluates preconditions (no resource-level `@odata.etag`/HTTP
  ETag; the settings-object ETag `9234ac83b9700123cc32` is the only
  concurrency token it serves), so 412 enforcement stays unit-level and the
  #016 client must send the settings-object ETag itself.
- **Docs:** no corpus download this run (EMU stream). REQUIREMENTS.md: "Last
  audited" rewritten (EMU 57→60 summary + the If-Match boundary), test-platforms
  bullet 57 → 60 tests, trace-note paragraphs added for the three pins;
  **DOCS-25 filed in FUTUREWORK.md** — mirror the SecureBoot family
  (SecureBoot served v1_1_1 + newest + SecureBootDatabase + collection) into
  the external corpus so the new REQUIREMENTS.md citations resolve to mirror
  files (SecureBoot/SecureBootDatabase stay NOT client-mapped → no fixture
  duty). Anchors not re-verified this run (no corpus access; bmcweb `63a18f4`,
  mockup `23d21f9a`, DSP0266 1.25.0 unchanged from the 19:25 re-verification).
- **Emulator:** server prepared from the pinned `23d21f9a`, healthy on 8443,
  suite **57 → 60 tests, 60/60 passed** (+3: SecureBoot read + ResetKeys
  round-trip incl. invalid-type negative; SecureBootDatabase collection + PK
  detail; If-Match stale-etag boundary). On-disk fixture byte-identical
  (`git status` clean apart from the test file); in-memory mockup state
  restored (IndicatorLED Off, Boot Once — the If-Match test restores in
  `finally`). Server will be stopped at run end.
- **Code/tests:** no lib/ production change — emulator-only pins in
  `test_integration/emulator/emulator_suite_test.dart` (3 new tests in the
  existing ComputerSystem Boot/PATCH/Links/VirtualMedia group). Plain `flutter
  test` suite unaffected (emulator tests skip without
  `REDFISH_EMULATOR_URL`): 345 passed / 1 skipped.
- **UI:** skipped — the primary EMU workstream produced the finished increment;
  the remaining UI-2 candidates (focus order, non-card labels) are open-ended
  deep-hunt items the prior EMU run flagged, and rushing them into the last
  minutes of the budget would risk an untested change. Recorded, not rushed.
- **Verification:** (pending full gate after tracking — analyze 0; tests 345
  passed / 1 skipped; emulator 60/60; issues validate OK; `git diff --check`
  clean; secret scan: Dart tests + doc prose only, no credentials — the
  SecureBoot bodies are public DMTF fixture data).
- **Commit:** (after §7.2/§7.3 below) — pushed: expected no (known GitHub
  credential blocker; local commit kept, not retried).
- **Next:** 1) Push the queued local commits (98) from a machine with GitHub
  credentials; 2) DOCS per alternation — DOCS-25 (mirror SecureBoot/
  SecureBootDatabase served+newest+collection into the external corpus, then
  the REQUIREMENTS.md SecureBoot rows cite real files); 3) P1 #015 AuthManager
  — wire `Session.expiryFromService` into login, re-auth on `isExpired`,
  token/location from create RESPONSE HEADERS only.

## 2026-10-24 20:20 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 83ae5af
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **98** (97 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 21:00 — DOCS (DOCS-25: SecureBoot + SecureBootDatabase corpus mirror) + UI-2 Discovery placeholder

- **Baseline:** analyze 0; tests 345 passed / 1 skipped; starting commit 0f76c85
  (branch `main` ahead 99 of origin); issues validate OK; working tree clean; no
  stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last substantive runs: DOCS 19:25 →
  EMU 20:12; DOCS due, and FUTUREWORK named DOCS-25 as the next DOCS duty).
  Closed **DOCS-25** — mirrored the **SecureBoot boot-integrity family** the
  EMU run pinned live (EMU 57→60) into `documentations/external/redfish/schemas/
  v1/`: served `SecureBoot.v1_1_1.json` (`#SecureBoot.v1_1_1.SecureBoot` —
  SecureBootEnable/CurrentBoot/Mode + `#SecureBoot.ResetKeys`
  `ResetKeysType@Redfish.AllowableValues`) + newest `SecureBoot.v1_2_1.json`
  (the aggregator's `$ref` target; adds **only `SecureBootDesiredMode`**,
  additive), served `SecureBootDatabase.v1_0_2.json`
  (`#SecureBootDatabase.v1_0_2.SecureBootDatabase` — DatabaseId/Certificates/
  Signatures + per-resource `#SecureBootDatabase.ResetKeys` *smaller*
  allow-list) + newest `SecureBootDatabase.v1_0_3.json` (**property no-op**,
  11→11), the `SecureBoot.json`/`SecureBootDatabase.json` aggregators and
  `SecureBootDatabaseCollection.json` — 7 files / **52,544 bytes**, inside the
  DOCS-6 budget; SHA-256s verified and recorded in the manifest.
- **Docs:** manifest +8→+7 rows (aggregator-count note 25 → 27), DOCS-25
  section in `documentations/external/README.md`, DOCS-25 audit section in
  `documentations/external/redfish/REQUIREMENTS.md` (delta table + client-
  mapped decision), REQUIREMENTS.md "Last audited" rewritten and the two
  SecureBoot trace notes now cite the real mirror files; verified the
  served-version `ResetKeysType` enums match the EMU pins exactly (SecureBoot:
  ResetAllKeysToDefault/DeleteAllKeys/DeletePK; PK database: no DeletePK) —
  the per-resource allow-list nuance is a schema fact, not a mockup quirk.
  Anchors re-verified 18:52 UTC all unchanged: bmcweb `63a18f4` (API HEAD),
  mockup `23d21f9a` (API HEAD), DSP0266 1.25.0 (200 on working
  `www.dmtf.org` URL), schema index 200. No client code change from the
  corpus audit; both families stay NOT client-mapped (no fixture duty —
  corpus-invariant family list untouched).
- **Emulator:** none this run (DOCS stream). Emulator suite unaffected —
  SecureBoot pins already covered by EMU 57→60.
- **Code/tests:** no lib/ production change for DOCS; UI-2 increment:
  `lib/features/discovery/discovery_page.dart` — the Discovery placeholder
  (last bare-`Text` not-implemented surface in the app) converted to the
  established merged `Semantics(container + excludeSemantics)` node
  (`Discovery engine — schema-driven capability map (#003)`) + icon
  `Icons.map_outlined` (one self-describing announcement; no Retry — the
  discovery engine is a planned feature #003, not an error). New
  `test/features/discovery/discovery_page_test.dart` — +2 widget tests
  (merged `bySemanticsLabel` node + visible text + icon, and no overflow at
  320 px via `addTearDown`). Suite 345 → **347**. `dart format` drift in 26
  unrelated files reverted via `git checkout --` to keep the diff on the 7
  schema files + README + REQUIREMENTS + discovery_page.dart + the new test
  file.
- **UI:** the Discovery placeholder was the last bare-`Text` placeholder
  surface; every empty/error/loading/not-found/placeholder state across the
  app now uses the merged-semantics pattern. Remaining UI-2: focus order +
  remaining non-card labels (recorded).
- **Verification:** analyze 0; tests **347 passed / 1 skipped** (baseline 345
  → +2 widget); issues validate OK; `git diff --check` clean; secret scan
  clean (Dart + docs prose + public DMTF schema JSONs — no credentials).
- **Commit:** (after §7.2/§7.3 below) — pushed: **no** (expected) — the known
  GitHub credential blocker (`fatal: could not read Username for
  'https://github.com'`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN
  env, no SSH key); local commit kept, not retried. Commits ahead of origin/main:
  **99** before this run's commit.
- **Next:** 1) Push the queued local commits (100) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login (set `expiresAt` from the discovered SessionService), re-auth on
  `isExpired`, keep token/location from create headers only (the fixture echoes
  Password in session bodies); 3) EMULATOR per alternation — the corpus mirror
  queue is EMPTY (all EMU-pinned families have mirror files); candidates: re-run
  the corpus-invariant crawl on future family additions, or pin a remaining
  un-pinned surface (#028 BIOS-config editor is the P2 candidate with the exact
  fixture duty recorded; the SecureBoot/SecureBootDatabase served versions must
  move into the fixture only if a security-posture feature lands).

## 2026-10-24 21:02 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 0fa0fec
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **100** (99 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 21:53 — EMULATOR (chassis Controls surface, EMU 60→63) + UI-2 SystemCard URL merge

- **Baseline:** analyze 0; tests 347 passed / 1 skipped; starting commit 4750053
  (branch `main` ahead 101 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last substantive runs: EMU 20:12
  → DOCS 21:00; EMU due). Pinned the **chassis Controls surface** the mockup
  serves under `Chassis.1U.Controls` (`#ControlCollection` →
  `#Control.v1_5_0.Control`) — the modern power-limit / frequency control
  surface a #006/#019/#022 power-capping flow reads before changing anything.
  Three new live tests (suite 60 → **63**):
  1. Collection: Chassis `Controls` link → `#ControlCollection.ControlCollection`
     with 2 members (PowerLimit + CPU1Freq).
  2. Control detail: PowerLimit (ControlType Power, ControlMode Automatic,
     SetPoint 500 W, AllowableMax 1000 / AllowableMin 150, `Sensor` excerpt
     Reading 374 + DataSourceUri → `/Chassis/1U/Sensors/TotalPower` resolving
     to a real Sensor — the wired-surface shape) + CPU1Freq (ControlType
     Frequency, SettingMin/Max 2000/2400 Hz, AllowableMin/Max 1500/3700).
  3. **Second live PATCH pin (#016):** PATCHing `SetPoint: 600` on PowerLimit
     returns 204 AND persists (in-memory; on-disk fixture byte-identical)
     while `SetPoint: 9999` is ALSO applied unvalidated — same
     advertised-contract-not-enforced rule as ResetType/PATCH-body; the
     #022/#016 client must pre-validate SetPoints against AllowableMin/Max
     (the 400 + `@Message.ExtendedInfo` validation path stays unit-level).
- **Docs:** none this run (EMU stream). **DOCS-26 filed** — mirror the Control
  family (served `Control.v1_5_0` + newest `Control.v1_8_1` + aggregator +
  `ControlCollection`) into the external corpus next DOCS run; Control is NOT
  client-mapped so there is no fixture-schema duty (corpus-invariant family
  list untouched). REQUIREMENTS.md "Last audited" rewritten (EMU 60→63,
  DOCS-26 noted; prior DOCS-25 section preserved).
- **Emulator:** server prepared from the pinned `23d21f9a`, healthy on 8443,
  suite **60 → 63 tests, 63/63 passed** (+3 Control tests). On-disk fixture
  byte-identical (`git status` clean apart from the test file); in-memory
  mockup state restored (SetPoint back to 500 in `finally`). Server stopped.
- **Code/tests:** no lib/ production change for the EMU stream — emulator-only
  pins in `test_integration/emulator/emulator_suite_test.dart` (new
  Controls group). Plain `flutter test` suite unaffected (emulator tests skip
  without `REDFISH_EMULATOR_URL`): 348 passed / 1 skipped.
- **UI:** one small tested UI-2 increment — `SystemCard` header now merges
  name + state + endpoint URL (`<name>, <state>, <scheme>://<host>:<port>`,
  the SystemOverviewPage connection-header precedent; the URL subtitle was the
  last remaining non-card label on the dashboard card). The standalone
  subtitle `Text` is wrapped in `ExcludeSemantics` so it does not
  double-announce (visible text preserved). The existing 4-state header test
  updated to expect the merged label; +1 widget test asserts the merged node +
  the URL appears exactly once in the semantics tree. Suite 347 → **348**.
- **Verification:** analyze 0; tests **348 passed / 1 skipped** (baseline 347
  → +1 widget); emulator 63/63; issues validate OK; `git diff --check` clean;
  secret scan: Dart tests + doc prose only, no credentials (the Control bodies
  are public DMTF fixture data, public schema JSONs referenced but not
  downloaded this run).
- **Commit:** (after §7.2/§7.3 below) — pushed: expected no (known GitHub
  credential blocker; local commit kept, not retried).
- **Next:** 1) Push the queued local commits (102) from a machine with GitHub
  credentials; 2) DOCS per alternation — DOCS-26 (mirror Control served +
  newest + aggregator + collection into the external corpus, then the
  REQUIREMENTS.md #006/#019/#022 Control rows cite real files); 3) P1 #015
  AuthManager — wire `Session.expiryFromService` into login, re-auth on
  `isExpired`, token/location from create RESPONSE HEADERS only; #016 remains
  the Boot/IndicatorLED If-Match wiring with the settings-object ETag.

## 2026-10-24 21:56 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 0c893d6
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **102** (101 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 22:33 — DOCS (DOCS-26 Control corpus mirror) — UI skipped with reason

- **Baseline:** analyze 0; tests 348 passed / 1 skipped; starting commit 6242e21
  (branch `main` ahead 103 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last substantive runs: DOCS 21:00 →
  EMU 21:53; DOCS due — and DOCS-26 is the named next DOCS duty from the EMU
  run). Closed **DOCS-26**: mirrored the **Control family** the EMU 60→63 pins
  read — `#ControlCollection.ControlCollection` → `#Control.v1_5_0.Control`
  (PowerLimit: ControlType Power / ControlMode Automatic / SetPoint 500 W /
  AllowableMax 1000 / AllowableMin 150 + `Sensor` excerpt with DataSourceUri →
  Sensors/TotalPower; CPU1Freq: ControlType Frequency / SettingMin/Max
  2000/2400 Hz / AllowableMin/Max 1500/3700) — into
  `documentations/external/redfish/schemas/v1/`. 4 files / **129,851 bytes**
  total (`Control.json` 9,694 + `Control.v1_5_0.json` 47,414 +
  `Control.v1_8_1.json` 67,784 + `ControlCollection.json` 4,959), inside the
  DOCS-6 budget. All 4 sources verified 200 via `curl -sSIL` before download;
  SHA-256s + manifest rows added.
- **Docs:** served `Control.v1_5_0.json` (mockup-served `#Control.v1_5_0.Control`,
  absent from the newest aggregator `$ref` list — the DOCS-25 pattern) + newest
  `Control.v1_8_1.json` (aggregator `$ref`s v1_0_7/v1_1_6/v1_2_6/v1_3_6/v1_4_6/
  v1_5_5/v1_6_3/v1_7_2/v1_8_1) + both aggregators. **Delta audit (additive-
  only):** v1_5_0 → v1_8_1 adds `SetPointError` only (readonly, versionAdded
  v1_7_0 — the error/difference of the related Sensor `Reading` from
  `SetPoint`, units per `SetPointUnits`); every EMU-2-pinned field present in
  the served version — **no client code change**. `SetPointUnits` + the
  `Sensor` SensorExcerpt/null `anyOf` verified in the served schema (matches
  the fixture's `W`/`Hz` values + DataSourceUri shape). Client-mapped decision:
  **Control stays NOT client-mapped** — external corpus only, no fixture duty,
  the 33-family corpus-invariant list untouched. REQUIREMENTS.md: "Last
  audited" updated (DOCS-26 done), new DOCS-26 section (manifest table, delta
  table, decision); README: 4 manifest rows, aggregator count 27 → **28**,
  DOCS-26 note + anchors timestamp.
- **Emulator:** none this run (DOCS stream). Emulator suite unaffected —
  Control pins already covered by EMU 60→63.
- **Code/tests:** no lib/ production change for DOCS-26 (pure corpus +
  provenance + traceability). No fixture copies (Control NOT client-mapped).
- **UI:** skipped with reason — every empty/error/loading/placeholder surface
  across the app already uses the merged-`Semantics` pattern (verified via
  scans: no bare Icon+Text rows remain un-merged, no bare-`Text` fallbacks
  remain); the only open UI-2 items are the open-ended focus-order hunt and
  remaining non-card labels, which are risky to rush unattended on a DOCS run
  and were not attempted (runbook §5 allows this with a reason).
- **Verification:** analyze 0; tests **348 passed / 1 skipped** (unchanged —
  DOCS-only); issues validate OK; `git diff --check` clean; secret scan: 4
  public DMTF schema JSONs + docs prose only, no credentials.
- **Commit:** (after §7.2/§7.3 below) — pushed: expected no (known GitHub
  credential blocker; local commit kept, not retried).
- **Next:** 1) Push the queued local commits (104) from a machine with GitHub
  credentials; 2) EMULATOR per alternation — corpus mirror queue is now EMPTY
  (all EMU-pinned families incl. Control have real mirror files); candidates:
  re-run the corpus-invariant crawl on future family additions, or pin a
  remaining un-pinned surface (#028 BIOS-config editor remains the P2
  candidate with its fixture duty recorded); 3) P1 #015 AuthManager — wire
  `Session.expiryFromService` into login, re-auth on `isExpired`,
  token/location from create RESPONSE HEADERS only.

## 2026-10-24 22:37 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit e1b9b6d
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **104** ($((104 - 1)) before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-24 23:50 — EMULATOR (Bios/Settings PATCH round-trip pin) — UI detail-line merge

- **Baseline:** analyze 0; tests 348 passed / 1 skipped; starting commit 0cfe993
  (branch `main` ahead 105 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last runs: DOCS 22:33 → EMU 21:53;
  EMU due). Added the **THIRD live PATCH pin (#016)** and the **first
  pending-settings PATCH round-trip (#028)** to the emulator suite:
  PATCH `/redfish/v1/Systems/437XR1138R2/Bios/Settings` (the
  `@Redfish.Settings` SettingsObject located by the 16:30 Bios pin, carrying
  the only ETag this mockup serves — `9234ac83b9700123cc32`) with an
  `Attributes` subset answers **204 AND persists** (in-memory; on-disk
  fixture byte-identical). Negative pin: a stale `If-Match: "bogus-stale-etag"`
  is IGNORED — 204 + persists, so 412 enforcement stays unit-level and the
  #016/#028 client must send the settings-object ETag itself. Live-probed the
  shape before writing the test (probe: EmbeddedSata Uefi → 204 + persisted →
  restored Ahci; NicBoot1 PxeBoot with stale If-Match → 204 + persisted →
  restored NetworkBoot). Suite 63 → **64 tests, 64/64 passed** (+1 Bios
  settings PATCH test). Server started from pinned `23d21f9a`, healthy on
  8443, stopped after the run (no background process left). On-disk fixture
  byte-identical (`git status` clean apart from the 3 intended files).
- **Docs:** none this run (EMU stream). No corpus change needed — the Bios/
  Settings served schemas (`Bios.v1_2_2` + `Settings.v1_3_5`) were mirrored by
  DOCS-23 and the newest pairs by DOCS-23; the ETag + SettingsObject shape is
  already pinned (EMU 53) and now round-tripped.
- **Emulator:** server prepared from the pinned `23d21f9a`, healthy on 8443,
  suite **63 → 64 tests, 64/64 passed** (+1 Bios settings PATCH pin — the
  third live PATCH pin on the fixture and the first against the pending-
  settings object). Server stopped; in-memory mockup state restored
  (EmbeddedSata back to Ahci, NicBoot1 back to NetworkBoot in `finally`).
- **Code/tests:** no lib/ production change for the EMU stream (emulator-only
  pin in `test_integration/emulator/emulator_suite_test.dart`). Plain
  `flutter test` suite unaffected (emulator tests skip without
  `REDFISH_EMULATOR_URL`).
- **UI:** one small tested UI-2 increment — the SystemCard **detail line**
  (Manufacturer · Model) was the last remaining non-card label on the
  dashboard card body; it now renders inside a
  `Semantics(container + excludeSemantics)` merged node (one self-describing
  announcement, visible text preserved — the established card-row pattern).
  +1 widget test in `test/features/systems/ui_widget_test.dart` asserts the
  merged label + visible text. Suite 348 → **349** passed / 1 skipped.
- **Verification:** analyze 0; tests **349 passed / 1 skipped** (baseline 348
  → +1 widget); emulator 64/64; issues validate OK; `git diff --check` clean;
  secret scan: Dart tests + fixture prose only, no credentials. `dart format`
  drift in 26 unrelated files reverted to keep the diff on the 3 intended
  files (system_card.dart, ui_widget_test.dart, emulator_suite_test.dart).
- **Commit:** (after §7.2/§7.3 below) — pushed: expected no (known GitHub
  credential blocker; local commit kept, not retried).
- **Next:** 1) Push the queued local commits (105) from a machine with GitHub
  credentials; 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login, re-auth on `isExpired`, token/location from create RESPONSE HEADERS
  only (the next named P1; the EMU-2 chain 63→64 is now the If-Match-on-
  Settings seam and the #028 BIOS editor input); 3) DOCS per alternation —
  the corpus mirror queue is EMPTY, so a freshness audit (DOCS-22 precedent)
  is the natural DOCS duty next.

## 2026-10-24 23:55 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit 09aa981
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **106** (105 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-25 00:20 — DOCS (corpus freshness audit + provenance fix) — UI-2 Identity KV merge

- **Baseline:** analyze 0; tests 349 passed / 1 skipped; starting commit 1cbdda1
  (branch `main` ahead 107 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last runs: EMU 23:50 → DOCS 22:33 →
  EMU 21:53 → DOCS 20:14; DOCS due). Closed **DOCS-27** — the corpus
  freshness audit (the DOCS-22 precedent, now covering 38 families). Re-
  verified all upstream anchors (00:07–00:15 UTC): bmcweb `63a18f4` still
  HEAD (all four mirrored docs byte-identical), mockup `23d21f9a` still HEAD,
  DSP0266 1.25.0 (200), schema index 200. Downloaded the live index,
  extracted all 7,167 entries, compared the newest version per family against
  every mirrored "newest" file → **ZERO version advances**. Separately
  re-downloaded **all 120 mirrored schema files** and byte-compared SHA-256 →
  **120/120 byte-identical**; registries (`Base.1.5.0` + `Base.1.24.0`),
  index page, and the DSP0266 1.25.0 PDF all byte-identical. **0 new bytes
  downloaded** (DOCS-6 budget untouched), no corpus refresh, no client code
  change. **One provenance fix:** the manifest row for
  `redfish/mockup/README-mockup-server.md` recorded the **upstream** SHA-256
  (`b3af2ff3…`, 7,318 B) but the committed blob has been the DOCS-1
  normalised copy ever since (trailing whitespace stripped on the `cert = `/
  `key = ` lines, 2 bytes; on-disk `0d79a165…`, 7,316 B) — the manifest
  claimed a hash the repo did not contain. Updated the row to record the
  actual committed SHA (`0d79a165…`, 7,316 B) with an explicit
  byte-identical-apart-from-whitespace note (restoring the trailing
  whitespace would fail `git diff --check`); upstream re-verified live as
  `b3af2ff3…` (7,318 B) at the pinned `23d21f9a`, so the semantic content
  is current and the manifest is truthful about what the repo holds.
- **Docs:** DOCS-27 audit section + "Last audited" rewritten in
  REQUIREMENTS.md; README DOCS-27 note + anchors timestamp; FUTUREWORK
  DOCS-27 done + Last updated/Current focus rewritten. No new files mirrored
  (audit-only run).
- **Emulator:** none this run (DOCS stream). Emulator suite unaffected; the
  33-family corpus-invariant list untouched (no family became client-mapped).
- **Code/tests:** no lib/ production change for the DOCS stream beyond the
  UI-2 semantics merge below. `overview_view.dart` `_kv` now wraps each
  Identity key/value row in `Semantics(container + excludeSemantics)`.
- **UI:** one small tested UI-2 increment — the OverviewView **Identity card
  key/value rows** were the last remaining non-card label surface on the
  overview page (each label + value announced as two detached nodes); each
  `_kv` row now announces as ONE merged node (`Manufacturer: Acme`,
  `Model: Server-9`, `Serial: SN1`, `BIOS: 1.0`), with a missing value
  merging as `<label>: Not exposed by this BMC`; visible label + value texts
  preserved. +2 widget tests in `test/features/overview/overview_view_test.dart`
  assert the merged labels + visible texts + the missing-value form. Suite
  349 → **351** passed / 1 skipped.
- **Verification:** analyze 0; tests **351 passed / 1 skipped** (baseline 349
  → +2 widget); issues validate OK; `git diff --check` clean; secret scan:
  Dart + docs prose only, no credentials. `dart format` clean on the touched
  files.
- **Commit:** (after §7.2/§7.3 below) — pushed: expected no (known GitHub
  credential blocker; local commit kept, not retried).
- **Next:** 1) Push the queued local commits (107) from a machine with GitHub
  credentials; 2) EMULATOR per alternation — corpus mirror queue is EMPTY and
  now verified fresh; candidates: re-run the corpus-invariant crawl on future
  family additions, or pin a remaining un-pinned surface (#028 BIOS-config
  editor remains the P2 candidate with its fixture duty recorded); 3) P1
  #015 AuthManager — wire `Session.expiryFromService` into login, re-auth on
  `isExpired`, token/location from create RESPONSE HEADERS only.

## 2026-10-25 00:40 — PUSH RECORD (no code change)

- Attempted `git push origin main` once after the run above (commit fff06a5
  auto): failed with
  `fatal: could not read Username for 'https://github.com': No such device or
  address` — no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no
  SSH key on this machine. Local commit kept; not retried (runbook §7.4).
- Queued local commits ahead of origin/main: **108** (107 before this run + 1
  auto; live `git rev-list --count origin/main..HEAD`).

## 2026-10-25 01:34 — EMULATOR (ThermalSubsystem Heaters surface + Manager.Reset live round-trip) — UI-2 Processors merge

- **Baseline:** analyze 0; tests 351 passed / 1 skipped; starting commit 1245931
  (branch `main` ahead 109 of origin); issues validate OK; working tree clean;
  no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last runs: DOCS 00:20 → EMU 23:50
  → DOCS 22:33 → EMU 21:53; EMU due). Suite 64 → **66 tests, 66/66 passed**
  (+2). Pinned live on the official DMTF Redfish-Mockup-Server @ pinned
  `23d21f9a` (HTTPS 8443, self-signed /tmp cert, `-S` short-form fixture):
  1) **ThermalSubsystem Heaters surface** (the thermal subsystem's second
  surface next to the fan pin, EMU 48) — `#HeaterCollection` →
  `#Heater.v1_0_1.Heater` CPU1Heater detail (PhysicalContext CPU /
  Manufacturer Contoso Heaters / Model CPUHeater / SerialNumber
  SNDHM0123456789 / HotPluggable / LocationIndicatorActive / Status Health
  OK) + `Links.Processors[0]` resolving live to `#Processor.v1_19_0` CPU1 +
  Metrics link → `#HeaterMetrics.v1_0_1.HeaterMetrics`
  (PrePowerOnHeatingTimeSeconds 600 / RuntimeHeatingTimeSeconds 3600 /
  PowerWatts.Reading 200.3 / TemperatureReadingsCelsius[1] DeviceName
  'Heater Average Temperature' Reading 2.5). Action-target classification:
  the advertised `#HeaterMetrics.ResetMetrics` target has **no `/Actions/`
  segment** → live POST **404 with an empty body** (probed first, the
  PowerSupply.Reset advertised-as-candidate rule — #022/#006 treats it as a
  candidate, never a contract). 2) **Manager.Reset live POST round-trip** —
  the target IS under `/Actions/` so the framework serves it: POST
  GracefulRestart → **204** (empty body, no task-monitor Location) AND a
  bogus `ResetType` **also 204s** (probed live) — the mockup never validates
  action bodies, so the 400 `ResetTypeInvalid` path stays unit-level and the
  #022/#016 client must pre-validate against the manager's OWN allow-list
  (ForceRestart/GracefulRestart — never the system list). Probed the exact
  shapes first (collection/detail/metrics GETs, ResetMetrics POST 404,
  Manager.Reset POST 204 + bogus 204, CPU1 link 200). Server started from
  pinned `23d21f9a`, healthy on 8443, stopped after the run (no background
  process left). On-disk fixture byte-identical (`git status` clean apart
  from the 4 intended files).
- **Docs:** none this run (EMU stream). New corpus mirror duty recorded as
  **DOCS-28** in FUTUREWORK: mirror `Heater.v1_0_1` + `HeaterMetrics.v1_0_1`
  (mockup-served) + newest `v1_0_2` pair + aggregators + `HeaterCollection.json`
  (7 files) into the external corpus only — neither family is client-mapped,
  so no fixture duty and the corpus-invariant family list stays untouched;
  newest versions verified live on the schema index this run.
- **Emulator:** server prepared from the pinned `23d21f9a`, healthy on 8443,
  suite **64 → 66 tests, 66/66 passed** (+1 Heaters surface +1 Manager.Reset
  round-trip). Server stopped; no in-memory mutations (all probes were GETs
  or 404s; the two 204 POSTs carried no persisted changes on the mockup).
- **Code/tests:** no lib/ production change for the EMU stream (emulator-only
  pins in `test_integration/emulator/emulator_suite_test.dart`). Plain
  `flutter test` suite unaffected (emulator tests skip without
  `REDFISH_EMULATOR_URL`).
- **UI:** one small tested UI-2 increment — the OverviewView **Processors card
  body** (count + model) was the last remaining detached-text surface on the
  overview cards (the Identity `_kv` rows merged 00:20; the Processors body
  still announced `2 processor(s)` and `P9` as two separate nodes). The body
  now renders inside a `Semantics(container + excludeSemantics)` merged node
  (`2 processor(s), P9` — one self-describing announcement, visible texts
  preserved; count-only and model-only forms merge the single fact). +1 widget
  test in `test/features/overview/overview_view_test.dart` asserts the merged
  label + both visible texts. Suite 351 → **352** passed / 1 skipped.
- **Verification:** analyze 0; tests **352 passed / 1 skipped** (baseline 351
  → +1 widget); emulator 66/66; issues validate OK; `git diff --check` clean;
  secret scan: Dart tests + docs prose only, no credentials. `dart format`
  clean on the touched files (no unrelated drift).
- **Commit:** d5fa17c — pushed: **yes** (the GitHub credential blocker cleared
  this run; `1245931..d5fa17c` pushed, origin/main fully synced — all 109
  previously-queued local commits went up with it).
- **Next:** 1) DOCS per alternation — **DOCS-28** (mirror the Heater +
  HeaterMetrics served `v1_0_1` + newest `v1_0_2` + aggregators +
  `HeaterCollection.json`, 7 files / external corpus only, the DOCS-24/25/26
  precedent — the corpus mirror queue is DOCS-28, the only un-mirrored
  EMU-pinned family pair); 2) P1 #015 AuthManager — wire
  `Session.expiryFromService` into login, re-auth on `isExpired`,
  token/location from create RESPONSE HEADERS only; 3) keep pushing every
  run (credentials now work — verify once per run, no more queued commits) (mirror the Heater +
  HeaterMetrics served `v1_0_1` + newest `v1_0_2` + aggregators +
  `HeaterCollection.json`, 7 files / external corpus only, the DOCS-24/25/26
  precedent — the corpus mirror queue is DOCS-28, the only un-mirrored
  EMU-pinned family pair); 3) P1 #015 AuthManager — wire
  `Session.expiryFromService` into login, re-auth on `isExpired`,
  token/location from create RESPONSE HEADERS only.

## 2026-10-25 01:36 — PUSH RECORD (success)

- `git push origin main` after the run above (commit d5fa17c auto) **succeeded**:
  `1245931..d5fa17c  main -> main`. The GitHub credential blocker that forced
  the last nine PUSH RECORDs is gone (credentials/helper now configured on
  this machine) — all **109 previously-queued local commits** were pushed in
  the same operation. `git rev-list --count origin/main..HEAD` = 0 (fully
  synced), working tree clean.
- Queued local commits ahead of origin/main: **0**.

## 2026-10-25 00:34 UTC — DOCS (DOCS-28 Heater + HeaterMetrics corpus mirror) — UI-2 badge merge

- **Baseline:** analyze 0; tests 352 passed / 1 skipped; starting commit 4e7e8f3
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last runs: DOCS 00:20 → EMU 01:34 →
  DOCS 00:30 → EMU 23:50 — EMU ran most recently, so DOCS is due). Chose
  **DOCS-28** — the only un-mirrored EMU-pinned family pair, recorded by the
  01:34 EMU run (Heat surface pin, EMU 64→66). Mirrored the 7-file Heater
  corpus into `documentations/external/redfish/schemas/v1/` (external corpus
  only — both families stay NOT client-mapped, so no fixture duty and the
  33-family corpus-invariant emulator list is untouched):
  `Heater.json` + `HeaterMetrics.json` (aggregators; each `$ref`s the newest
  `v1_0_2`), served `Heater.v1_0_1` + `HeaterMetrics.v1_0_1` (the versions
  the pinned mockup publishes — `#Heater.v1_0_1.Heater` CPU1Heater +
  `#HeaterMetrics.v1_0_1.HeaterMetrics`), newest `Heater.v1_0_2` +
  `HeaterMetrics.v1_0_2`, and `HeaterCollection.json` — 60,045 bytes total,
  inside the DOCS-6 budget. All 7 probed 200 with a browser UA; SHA-256s
  verified after download and recorded in the manifest. **Delta audit:
  v1_0_1 → v1_0_2 is a property no-op for both families** (26 diff lines
  each — `$id`, copyright year, backtick-quoted descriptions, `language:
  "en"`, title only) — the emulator-pinned contract holds across the newest
  versions, **no client code change**. `Heater.v1_0_3` / `HeaterMetrics.v1_0_3`
  probe 404 (verified live) — v1_0_2 is current. Also verified the served
  `ResetMetrics` action def in the mirror matches the EMU pin exactly (the
  no-`/Actions/`-segment advertised-as-candidate rule, never a contract).
  Updated `documentations/external/README.md` (7 manifest rows + DOCS-28
  section + downloaded-set list + anchors line) and
  `documentations/external/redfish/REQUIREMENTS.md` (DOCS-28 trace table +
  "Last audited" header). The corpus mirror queue is now **EMPTY** — every
  EMU-2-pinned family has a schema in the external corpus.
- **Docs:** 7 files mirrored (list above, total 60,045 bytes, inside
  DOCS-6); manifest rows + SHA-256s; DOCS-28 trace table in REQUIREMENTS.md;
  anchors re-verified (bmcweb `63a18f4` still HEAD via GitHub API, mockup
  `23d21f9a`, DSP0266 1.25.0, schema index 200). No `redfish_reference/`
  update needed (external-corpus-only — the DOCS-24/25/26 precedent never
  touched it for NOT-client-mapped families).
- **Emulator:** none this run (DOCS stream). The corpus-invariant crawl the
  next EMU run re-runs now covers the Heater surface with real mirror files.
- **Code/tests:** no lib/ production change from the DOCS stream (external
  corpus only, no fixture changes). UI-2 increment below touched
  `lib/features/systems/widgets/status_badges.dart` + its test only.
- **UI:** one small tested UI-2 increment — **HealthBadge/PowerBadge merged
  node fixed**. Both badges wrapped their `Chip` in `Semantics(label: ...,
  container: true)` WITHOUT `excludeSemantics: true`, so the chip's inner
  `Text` still announced as a separate node — a screen reader heard "Health
  Warning" then "Warning" / "Power Off" then "Off" (the double-announcement
  defect merged everywhere else in the app). Both badges now add
  `excludeSemantics: true` so the merged label is the ONLY announcement;
  visible text preserved for sighted users. The existing a11y label test in
  `test/features/systems/ui_widget_test.dart` extended with
  `bySemanticsLabel('Warning')`/`('Off')` findsNothing pins + visible-text
  assertions (+3 assertions in the one test). Targeted run: 29/29 passed
  before the full gate.
- **Verification:** analyze 0; tests **352 passed / 1 skipped** (unchanged
  count — the badge test was extended, not added); issues validate OK;
  `git diff --check` clean; secret scan: JSON schemas, docs prose, Dart
  widget code only, no credentials. `dart format` clean on the touched files.
- **Commit:** 620f77f — `auto: DOCS — DOCS-28 Heater+HeaterMetrics corpus
  mirror (7 files, queue EMPTY) + UI-2 badge excludeSemantics merge (run
  2026-10-25 00:34)`; pushed: **yes** (`4e7e8f3..620f77f main -> main`,
  origin/main fully synced, 0 queued local commits).
- **Next:** 1) EMULATOR per alternation — corpus mirror queue is EMPTY and
  verified; candidates: re-run the corpus-invariant published-types crawl
  (now covers the Heater surface), or pin a remaining un-pinned surface
  (#028 BIOS-config editor remains the P2 candidate with its fixture duty
  recorded); 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login, re-auth on `isExpired`, token/location from create RESPONSE HEADERS
  only; 3) keep pushing every run (credentials verified; no queued commits).

## 2026-10-25 01:23 UTC — EMULATOR (generalized $expand pins for #018) + UI-2 firmware card fix

- **Baseline:** analyze 0; tests 352 passed / 1 skipped; starting commit 41c1779
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last primary: DOCS 00:34 — EMU is
  due; the corpus mirror queue is EMPTY after DOCS-28, so the natural EMU
  increment is pinning a remaining discovery surface). The Systems `$expand`
  contract was already pinned (17:07 `$levels=1` / 18:36 `$expand=*` / 22:45
  map-form); this run generalized the shape to the OTHER two top-level
  collections the #018 lightweight discovery pass walks (Systems→Chassis→
  Manager) and pinned the depth bound. **+2 emulator tests (EMU 66 → 68):**
  (1) `$expand=.($levels=1)` via the map-form `getJson(path, query:)` on
  `/redfish/v1/Chassis` AND `/redfish/v1/Managers` inlines FULL member bodies
  — Chassis identity/ChassisType/Status/IndicatorLED/Links.ComputerSystems/
  ManagedBy and Manager ManagerType/FirmwareVersion/Model/Links.
  ManagerForServers/ManagerInChassis + the **manager-level reset allow-list
  (`#Manager.Reset` `ResetType@Redfish.AllowableValues` == exactly
  `[ForceRestart, GracefulRestart]`)** visible through the expanded payload —
  the #022/#016 rule that the gate never conflates the manager list with the
  system list (pinned 2026-10-23 03:02), now also enforced on the inlined
  shape; (2) `$levels=2` on Systems does NOT recurse beyond one level —
  the member's own `Links.Chassis` stays a bare `@odata.id` ref (no inlined
  ChassisType/Status), so the discovery pass must follow cross-resource URIs
  explicitly for deeper hops (DSP0266 §7.3.2 default-1 / depth cap behaviour
  pinned against the live mockup). Suite 66 → **68/68 passed** on the pinned
  `23d21f9a`. Server stopped after the run; all probes were GETs (no fixture
  mutations).
- **Docs:** none this run (EMU stream). The corpus-invariant published-types
  crawl (EMU 52) re-ran green inside the 68 — the DOCS-28 Heater mirror left
  the invariant intact.
- **Emulator:** server prepared from the pinned `23d21f9a`, healthy on 8443,
  suite **66 → 68 tests, 68/68 passed** (+2 general-`$expand` pins for #018).
  Server stopped; on-disk fixture byte-identical (all probes were GETs).
- **Code/tests:** no lib/ production change from the EMU stream (emulator-only
  pins in `test_integration/emulator/emulator_suite_test.dart`). UI-2
  increment below touched `lib/features/firmware/views/firmware_view.dart` +
  its test only.
- **UI:** one small tested UI-2 increment — **FirmwareView inventory card
  merged-node fix**. The per-item inventory card wrapped its `ListTile` in
  `Semantics(container: true, label: ...)` WITHOUT `excludeSemantics: true`,
  so the inner title/subtitle/chip `Text`s still announced as separate nodes —
  a screen reader heard the merged summary `Firmware BMC Firmware, 3.2.1, OK,
  updateable` and then `BMC Firmware`, `BMC · 3.2.1 · OK`, `Updateable` again
  (the exact double-announcement defect fixed for HealthBadge/PowerBadge at
  00:34). The card now adds `excludeSemantics: true` so the merged label is the
  ONLY announcement; visible texts preserved for sighted users. The existing
  inventory a11y label test in `test/features/firmware/firmware_widget_test.dart`
  extended with single-node pins: `bySemanticsLabel('BMC Firmware')` /
  `('Updateable')` now findsNothing while the merged label still finds one
  widget and the visible texts remain (+3 assertions in the one test). Targeted
  run: 16/16 passed before the full gate. Audit: no other
  `Semantics(container: true)` node in `lib/` lacks `excludeSemantics` (scanned
  all lib/**/*.dart — the firmware card was the last one).
- **Verification:** analyze 0; tests **352 passed / 1 skipped** (unchanged —
  the firmware test was extended, not added); emulator 68/68; issues validate
  OK; `git diff --check` clean; secret scan: Dart test code + docs prose only,
  no credentials. **Format note:** the Flutter 3.47.6 `dart format` reflowed 26
  unrelated Dart files (the known line-join drift, FUTUREWORK note 2026-10-25)
  — per the recorded plan they are committed as a separate dedicated
  `chore: dart format` commit after analyze+test stayed green (0 issues, 352
  pass), NOT mixed into the auto commit.
- **Commit:** (auto) `auto: EMULATOR — generalized $expand pins for #018
  (Chassis+Managers inlined, $levels=2 depth bound, EMU 66→68) + UI-2 firmware
  card excludeSemantics fix (run 2026-10-25 01:23)` + (chore) `chore: dart
  format` drift absorption; pushed: **yes** (see push record).
- **Next:** 1) DOCS per alternation — corpus mirror queue is EMPTY and
  verified; candidates: DOCS-27-style freshness re-verification of anchors
  (bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0) is cheap, or a
  REQUIREMENTS.md audit of the new `$levels=2` depth-bound row; 2) P1 #015
  AuthManager — wire `Session.expiryFromService` into login, re-auth on
  `isExpired`, token/location from create RESPONSE HEADERS only; 3) keep
  pushing every run (credentials verified; 0 queued commits).

## 2026-10-25 01:25 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `41c1779..c0a5cdc  main -> main` — the EMU auto commit (f41414f) + the
  `chore: dart format` drift absorption (c0a5cdc) both pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 02:09 UTC — DOCS (anchor re-verification + DOCS-29 depth-bound audit row) + UI-2 firmware summary merge

- **Baseline:** analyze 0; tests 352 passed / 1 skipped; starting commit d87519f
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last primary: EMULATOR 01:23 — DOCS
  is due). The corpus mirror queue is EMPTY after DOCS-28 and DOCS-27's full
  freshness audit found ZERO advances ~1.5 h ago, so this run took the
  planned pair: (a) **anchor re-verification** — bmcweb `63a18f4` still HEAD
  via GitHub API, mockup `23d21f9a` still HEAD via GitHub API, DSP0266 1.25.0
  returns 200 on the working `www.dmtf.org` URL, schema index returns 200 and
  is **byte-identical** to the mirrored `v1-index.html` (SHA-256
  `e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86`,
  3,448,133 bytes, verified with `cmp`) → **no corpus refresh needed**;
  (b) **DOCS-29 audit row** — folded the EMU 66→68 (01:23) query pins into
  the REQUIREMENTS.md DOCS-15 §7.3.2 table: the `$expand=.($levels=1)` shape
  is now pinned on **all three** top-level collections the #018 discovery
  pass walks (Systems + Chassis + Managers inline full member bodies via the
  map-form `getJson(path, query:)`, incl. the manager-level reset allow-list
  `[ForceRestart, GracefulRestart]` visible through the expanded Manager
  payload — the #022/#016 conflation guard on the inlined shape), and a new
  row pins the **`$levels=2` depth bound** — the mockup does NOT recurse,
  nested `Links` stay bare `@odata.id` refs, so the pass must follow
  cross-resource URIs explicitly for deeper hops (DSP0266 §7.3.2 depth-cap).
  Updated the DOCS-15 bottom-line paragraph + the REQUIREMENTS.md
  Last-audited header. No schema/PDF downloads this run (all anchors
  unchanged; DOCS-6 budget untouched).
- **Docs:** anchors verified unchanged (bmcweb `63a18f4`, mockup `23d21f9a`,
  DSP0266 1.25.0, schema index 200 byte-identical); DOCS-29 trace rows added
  (see above); no new files mirrored — manifest unchanged.
- **Emulator:** none this run (DOCS stream). The 68-test suite from the
  01:23 EMU run stays green on the pinned `23d21f9a`; the DOCS-29 rows make
  its query pins traceable in REQUIREMENTS.md.
- **Code/tests:** no lib/ production change from the DOCS stream. UI-2
  increment below touched `lib/features/firmware/views/firmware_view.dart` +
  its test only.
- **UI:** one small tested UI-2 increment — **FirmwareView `_ServiceSummary`
  merged semantics + no dangling loading label**. The UpdateService summary
  line rendered a half-baked `'UpdateService '` (trailing space, empty value)
  as a bare detached `Text` while the fetch was in flight — a screen reader
  heard a dangling label with nothing after it (the UI-2 "non-card label"
  class). Now: (1) while `info == null` the summary renders
  `SizedBox.shrink()` — the header row + inventory area already announce the
  in-flight state, so nothing half-baked is announced; (2) once loaded the
  summary is ONE `Semantics(container + excludeSemantics)` node
  (`UpdateService <version>, <http push URI>`) with the visible text
  preserved (`UpdateService 1.2.3 · /FWUpdate`), so the label and value
  announce together. +2 widget tests: merged-label + visible-text assertion,
  and a no-dangling-text-while-loading pin. Targeted run: 18/18 passed
  before the full gate (firmware 16 → 18).
- **Verification:** analyze 0; tests **354 passed / 1 skipped** (+2 — the new
  summary tests); issues validate OK; `git diff --check` clean; secret scan:
  JSON/docs prose + Dart widget code only, no credentials. `dart format`
  clean on the touched files.
- **Commit:** (pending this run) — `auto: DOCS — DOCS-29 $levels=2 depth-bound
  audit row + anchor re-verification (no corpus refresh) + UI-2 firmware
  service-summary merge (run 2026-10-25 02:09)`.
- **Next:** 1) EMULATOR per alternation — corpus mirror queue EMPTY and
  verified; re-run the corpus-invariant published-types crawl (now covers
  the Heater surface), or pin a remaining un-pinned surface (#028
  BIOS-config editor remains the P2 candidate with its fixture duty
  recorded); 2) P1 #015 AuthManager — wire `Session.expiryFromService` into
  login, re-auth on `isExpired`, token/location from create RESPONSE HEADERS
  only; 3) keep pushing every run (credentials verified; 0 queued commits).

## 2026-10-25 02:12 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `d87519f..01ce677  main -> main` — the DOCS auto commit (01ce677) pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 03:12 UTC — EMULATOR (negative pins: bad login + multipart-null, EMU 68→69) + UI-2 firmware form label

- **Baseline:** analyze 0; tests 354 passed / 1 skipped; starting commit 02eb993
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last primary: DOCS 02:09 — EMU is
  due). The corpus mirror queue is EMPTY after DOCS-28/27 (ZERO advances
  verified twice yesterday), so the increment closed two remaining *negative*
  facts that were recorded as probes but never pinned as tests:
  1. **Bad login still mints a session** (`run_tests.sh` starts the mockup
     WITHOUT `-u`, so it never authenticates — a fact recorded 2026-10-23 18:36
     in FUTUREWORK EMU-3 but never asserted in the suite). New test in the
     session-lifecycle group: POST `/redfish/v1/SessionService/Sessions` with
     `Password: definitely-wrong` returns 204 + X-Auth-Token + Location naming
     a session resource (never the collection). Consequences pinned: the
     AuthManager 401 bad-login mapping is provably unit-level on this fixture
     (#015/#026); token presence proves nothing about credential validity; the
     logout-target rule (session resource, not collection) holds even for a
     bad login.
  2. **`MultipartHttpPushUri` is absent on the DMTF fixture** — extended the
     existing UpdateServiceInfo HTTP-push test: `info.multipartHttpPushUri`
     is null while `httpPushUri == '/FWUpdate'` (bmcweb adds the multipart
     variant — DOCS-9 — but this fixture serves only the single-push form).
     The #008/#020 upload flow must tolerate a null multipart URI and pick
     the single-push `HttpPushUri` when that is all the service advertises.
  Suite 68 → **69/69 passed** on pinned `23d21f9a` (all probes GET/POST-204,
  the bad-login POST is auth-surface only, never a real credential; fixture
  byte-identical; server stopped via the script's trap).
- **Docs:** none this run (no corpus refresh; anchors verified unchanged by the
  previous DOCS run ~1 h ago). No new files mirrored — manifest unchanged.
- **Emulator:** 69/69 on the pinned `23d21f9a`; see Primary work. The
  corpus-invariant published-types crawl test re-ran green inside the suite
  (Heater mirror files now covered by the schema fixture check).
- **Code/tests:** no lib/ production change from the EMU stream (two pins in
  `test_integration/emulator/emulator_suite_test.dart` only). UI-2 increment
  below touched `lib/features/firmware/views/firmware_view.dart` + its test.
- **UI:** one small tested UI-2 increment — **firmware start-update form
  transfer-protocol selector now labelled**. The `DropdownButton<String>`
  (transfer protocol picker) had NO visible label — unlike the Image URI
  TextField above it, which carries `labelText: 'Image URI'` — so sighted
  users saw a bare dropdown and screen readers heard only the protocol value
  ("HTTP") with no field context. The select now renders a `Transfer protocol`
  Text above it (labelLarge + outline color, the established form-label
  pattern). Semantics: the card column merges the sibling plain Texts, so a
  screen reader hears `Start update, Transfer protocol` as the section node
  while the dropdown keeps its own button node (`HTTP`) — the field name is
  announced before the value instead of a bare dropdown. +1 widget test
  (visible label findsOneWidget; `bySemanticsLabel(RegExp('Transfer
  protocol'))` findsWidgets; `bySemanticsLabel('HTTP')` findsOneWidget; tapping
  the dropdown still opens the menu with `HTTPS` selectable). Targeted run:
  19/19 passed before the full gate (firmware 18 → 19). No new dependencies;
  no overflow impact (no-overflow tests at 320/800/1300 still green).
- **Verification:** analyze 0; tests **355 passed / 1 skipped** (+1 — the new
  firmware form-label test); emulator 69/69; issues validate OK;
  `git diff --check` clean; secret scan: Dart test/UI code only, no
  credentials — the bad-login fixture password `definitely-wrong` is a test
  literal, never a real BMC secret; `git diff --stat` shows only the three
  intended files (firmware_view.dart, firmware_widget_test.dart,
  emulator_suite_test.dart). `dart format` clean on the touched files.
- **Commit:** (pending this run) —
  `auto: EMULATOR — bad-login + multipart-null negative pins (EMU 68→69) +
  UI-2 firmware protocol-select label (run 2026-10-25 03:12)`.
- **Next:** 1) DOCS per alternation — corpus mirror queue EMPTY and verified;
   cheap candidate: DOCS-27-style anchor freshness re-verification (bmcweb
   `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index byte-compare);
   2) P1 #015 AuthManager — wire `Session.expiryFromService` into login,
   re-auth on `isExpired`, token/location from create RESPONSE HEADERS only
   (the bad-login pin clarifies the fixture never returns 401, so the unit
   fixture carries that path); 3) keep pushing every run (credentials verified;
   0 queued commits).

## 2026-10-25 03:15 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `02eb993..8e28c58  main -> main` — the EMU auto commit (8e28c58) pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 04:10 UTC — DOCS (query-501 gap closed + anchors re-verified) + UI-2 KVM console card body

- **Baseline:** analyze 0; tests 355 passed / 1 skipped; starting commit af26535
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last primary: EMULATOR 03:12 — DOCS is
  due). The corpus mirror queue is EMPTY and DOCS-27's ZERO advances were
  re-proven ~2h ago, so the run had two queued DOCS candidates: anchor
  freshness re-verification (cheap) and closing the last "Partial" audit row in
  REQUIREMENTS.md. Both landed:
  1. **Anchor re-verification — all unchanged, no corpus refresh.** bmcweb
     `63a18f4…` (still HEAD via GitHub API), mockup `23d21f9a…` (still HEAD),
     DSP0266 1.25.0 (200 on the working `www.dmtf.org` URL; re-downloaded
     live PDF **byte-identical** — SHA-256 `385ee6d0…` both sides), schema
     index 200 + **byte-identical** to the mirrored `v1-index.html`
     (`e5a29797…`, 3,448,133 B, `cmp` verified). No downloads added inside the
     DOCS-6 budget (re-downloads were probe copies under /tmp, not corpus).
  2. **Row-923 gap closed (DSP0266 §7.3.1 query-error surface).** The row
     said "generic error mapping OK; #018 should add a unit fixture for the
     query-501 path" — landed: +2 `RedfishException` normalization fixtures in
     `auth_manager_test.dart` (`Base.1.0.QueryNotSupported` on a 501 with the
     mirrored registry message text; `Base.1.0.QueryNotSupportedOnResource`
     on a 400 — `Base.1.24.0.json` `NumberOfArgs` 0, exact message strings),
     AND the one-line spec-driven classification fix the fixtures exposed:
     **501 (Not Implemented) is now NON-retryable** — DSP0266 §7.3.1 returns
     501 for unsupported `$`-prefixed query parameters, a *permanent*
     capability signal, so re-issuing the identical request cannot succeed
     (the #018 discovery pass must gate the query instead); transient 5xx +
     429 stay retryable. No production caller depends on 501 retryability
     (grep-verified); update is test-pinned both ways.
- **Docs:** none new mirrored — anchors verified unchanged + byte-identical
  (see Primary). Manifest README anchors line + REQUIREMENTS.md "Last audited"
  header + row-923 status updated (Partial → OK). `redfish_reference/` snapshot
  untouched (no corpus change).
- **Emulator:** none this run (DOCS stream). The 69-test suite from the 03:12
  EMU run stays green on the pinned `23d21f9a`.
- **Code/tests:** lib change from the DOCS stream: `redfish_exception.dart`
  501 non-retryable classification (one-line + comment, test-pinned). UI-2
  increment below touched `lib/features/kvm/views/kvm_view.dart` + its test.
- **UI:** one small tested UI-2 increment — **KVM console card body rows now
  merged semantics nodes**. `_ConsoleCard` still had three bare detached body
  labels (the "remaining non-card labels" class UI-2 tracks): `Manager: BMC`,
  `Max concurrent sessions: 4` (when present), and `HTML5 console — open via
  BMC web UI.` (when `supportsHtml5`). Each now renders inside the established
  `Semantics(container + excludeSemantics)` card-row node — one self-describing
  announcement (`Manager: BMC` etc.), visible texts preserved for sighted
  users. The header + Connect-URI rows were already merged (prior runs). +1
  widget test asserting all three merged labels + all three visible texts.
  Targeted run: 47/47 passed before the full gate (KVM 11 → 12). No new
  dependencies; no overflow impact (no-overflow tests at 320/800/1300 green).
- **Verification:** analyze 0; tests **358 passed / 1 skipped** (+3 — two
  query fixtures + one KVM card-body test); issues validate OK;
  `git diff --check` clean; secret scan: Dart code + JSON-prose docs only, no
  credentials (the query-501 fixture strings are DMTF registry message texts,
  never credentials); `git diff --stat` 6 files: kvm_view.dart,
  kvm_widget_test.dart, redfish_exception.dart, auth_manager_test.dart,
  REQUIREMENTS.md, README.md. `dart format` reflowed redfish_exception.dart
  only (4 touched files, 1 changed).
- **Commit:** (pending this run) —
  `auto: DOCS — query-501 gap closed (501 non-retryable) + anchors re-verified
  (no corpus refresh) + UI-2 KVM console card body merged nodes (run
  2026-10-25 04:10)`.
- **Next:** 1) EMULATOR per alternation — corpus mirror queue EMPTY and
  verified; candidates: re-run the corpus-invariant published-types crawl on
  the pinned `23d21f9a`, or close any remaining un-pinned surface; 2) P1 #015
  AuthManager — wire `Session.expiryFromService` into login, re-auth on
  `isExpired`, token/location from create RESPONSE HEADERS only; 3) keep
  pushing every run (credentials verified; 0 queued commits).

## 2026-10-25 04:12 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `af26535..5a41fa0  main -> main` — the DOCS auto commit (5a41fa0) pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 06:15 UTC — EMULATOR (ActionInfo resource contract pinned) + UI-2 PowerView footnote

- **Baseline:** analyze 0; tests 358 passed / 1 skipped; starting commit 6f82255
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last primary: DOCS 04:10 — EMU is
  due). The corpus mirror queue is EMPTY and verified, and the suite was already
  at 69/69, so the run closed the last recurring "un-pinned surface" note in
  #022/#016: **the ActionInfo resource contract is now pinned live**. The DMTF
  mockup does NOT serve a `ResetActionInfo` ActionInfo resource (a fact pinned
  2026-10-23), but it DOES serve two real ActionInfo resources —
  `/CertificateService/GenerateCSRActionInfo` and
  `/CertificateService/ReplaceCertificateActionInfo`, advertised via
  `@Redfish.ActionInfo` links on the `#CertificateService.GenerateCSR` and
  `#CertificateService.ReplaceCertificate` actions. New emulator group pins:
  (1) the `@Redfish.ActionInfo` link resolves from the action (never the
  POST-only target), the resource is `#ActionInfo.v1_4_1.ActionInfo` (matches
  the fixture schema), and every `Parameters[]` entry carries
  `Name`/`Required`/`DataType` (13 params on GenerateCSR); (2) per-parameter
  `AllowableValues` resolve (`KeyPairAlgorithm` TPM_ALG_RSA/ECDSA, `KeyCurveId`
  3 curves, `KeyUsage` 14 values, `CertificateType ['PEM']`) — the exact shape
  a bmcweb `ResetActionInfo`-style crawl parses on OpenBMC (DOCS-4/13, DSP0266
  §9.6.14 / ActionInfo.v1_4_1). EMU 69 → **71 tests** (all pass on pinned
  `23d21f9a`; the run_tests.sh trap stopped the server). REQUIREMENTS.md
  ActionInfo row updated (Partial → OK: resource form live; the actual
  `ResetActionInfo` fetch on OpenBMC stays code-task #022/#016).
- **Docs:** none new mirrored (corpus queue EMPTY; anchors unchanged per the
  04:10 verification). Only the REQUIREMENTS.md ActionInfo trace row updated.
- **Emulator:** 71/71 passed on pinned `23d21f9a` (server setup + cert + suite
  via `tool/emulator/run_tests.sh`; trap cleanup verified, no leftover process;
  port 8443 confirmed closed after the run).
- **Code/tests:** no production lib change from the EMU stream (2 new pins in
  `test_integration/emulator/emulator_suite_test.dart` only). UI-2 increment
  below touched `lib/features/power/views/power_view.dart` + its test.
- **UI:** one small tested UI-2 increment — **PowerView destructive-actions
  guidance footnote now a merged semantics node**. The view's last bare
  non-card text — `Destructive actions (force off, restart) require
  confirmation. State refreshes automatically after a reset.` — sat below the
  card as a detached `Text` (screen readers heard a lone sentence with no
  context). It now renders inside the established
  `Semantics(container + excludeSemantics)` card-row pattern (same class as the
  KVM console-card `HTML5 console — open via BMC web UI.` line merged 04:10):
  one self-describing announcement, visible text preserved for sighted users.
  +1 widget test (merged label findsOneWidget + visible text preserved + the
  `Power On` button keeps its own control node). Targeted run: 19/19 passed
  before the full gate (PowerView 18 → 19). No new dependencies; no overflow
  impact (no-overflow tests at 320/800/1300 still green).
- **Verification:** analyze 0; tests **359 passed / 1 skipped** (+1 — the new
  PowerView footnote test); emulator 71/71; issues validate OK;
  `git diff --check` clean; secret scan: Dart code + JSON-prose docs only, no
  credentials (the `Password`/`ChangePassword` hits are schema field names in
  pre-existing REQUIREMENTS.md rows; the bad-login fixture password was already
  tracked); `git diff --stat` 7 files: emulator_suite_test.dart,
  power_view.dart, power_view_test.dart, REQUIREMENTS.md, FUTUREWORK.md,
  issues/open/016, issues/open/022. `dart format` clean on the touched files.
- **Commit:** (pending this run) —
  `auto: EMULATOR — ActionInfo resource contract pinned live (EMU 69→71) +
  UI-2 PowerView guidance footnote merged (run 2026-10-25 06:15)`.
- **Next:** 1) DOCS per alternation — corpus mirror queue EMPTY and verified;
   cheap candidate: anchor freshness re-verification (bmcweb `63a18f4`, mockup
   `23d21f9a`, DSP0266 1.25.0, schema index byte-compare), or pin the last
   un-pinned service-root branches the corpus crawl visits (`CertificateService`,
   `KeyService`/`NVMeoFSecrets`, `ComponentIntegrity` — all NOT client-mapped,
   no fixture duty); 2) P1 #015 AuthManager — wire `Session.expiryFromService`
   into login, re-auth on `isExpired`, token/location from create RESPONSE
   HEADERS only; 3) keep pushing every run (credentials verified; 0 queued
   commits).

## 2026-10-25 06:20 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `6f82255..f270472  main -> main` — the EMU auto commit (f270472) pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 07:10 UTC — DOCS (anchor re-verification + bmcweb file-level provenance) + UI-2 sensor tile context

- **Baseline:** analyze 0; tests 359 passed / 1 skipped; starting commit a6f90f7
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last primary: EMULATOR 06:15 — DOCS
  is due). Corpus mirror queue is EMPTY and verified, so this run did the
  cheap anchor-freshness candidate plus a provenance upgrade:
  1. **Anchor re-verification — no corpus refresh.** bmcweb `63a18f4` still
     HEAD (GitHub API); all four mirrored docs (`Redfish.md`,
     `REDFISH_CHECKLIST.md`, `OEM_SCHEMAS.md`, `CLIENTS.md`) re-downloaded
     from current master and **byte-identical** to the mirror; mockup
     `23d21f9a` still HEAD (default branch is `main`, re-confirmed); DSP0266
     1.25.0 200 on the working `www.dmtf.org` URL, PDF re-downloaded and
     **byte-identical** (SHA-256 `385ee6d0…`), and a `DSP0266_1.26.0.pdf`
     probe 404s → 1.25.0 is still the current release; schema index 200 and
     **byte-identical** to `v1-index.html` (`e5a29797…`, 3,448,133 B) —
     DOCS-27's ZERO version advances re-proven.
  2. **Provenance upgrade — file-level last-touch commits.** The manifest
     recorded only the repo-HEAD anchor `63a18f4` for the bmcweb docs; the
     GitHub path API showed the four files were last changed long before the
     current HEAD: `Redfish.md` → `bb6b9ebc` (2026-09-21), and
     `REDFISH_CHECKLIST.md`/`OEM_SCHEMAS.md`/`CLIENTS.md` → `24e758ab`
     (2025-06-26, the docs-folder creation commit). Manifest rows + anchors
     note now record both anchors (repo HEAD for content verification, file
     last-touch for provenance) — the DOCS-27 precedent of truthful anchors.
- **Docs:** 0 new downloads (verification-only); manifest rows + anchors note
  in `documentations/external/README.md` updated with file-level commits;
  REQUIREMENTS.md "Last audited" header rewritten for this run; FUTUREWORK
  Last-updated + Current-focus lines updated; corpus mirror queue still EMPTY.
- **Emulator:** none this run (DOCS stream). The 71-test suite from the 06:15
  EMU run stays green on the pinned `23d21f9a`.
- **Code/tests:** no production lib change from the DOCS stream (verification +
  provenance only). UI-2 increment below touched
  `lib/features/sensors/views/sensors_view.dart` + its test.
- **UI:** one small tested UI-2 increment — **sensor tile merged labels now
  carry the visible subtitle context**. The three tiles (`_TemperatureTile`,
  `_FanTile`, `_SensorTile`) already wrapped their title/subtitle/chip in a
  `Semantics(container + excludeSemantics)` node (merged 2026-10-23), but the
  `excludeSemantics` dropped the SUBTITLE: temperature tiles hid the threshold
  hints (`caution 45 / crit 55`), fan tiles hid the physical context (`CPU`),
  generic sensor tiles hid the reading type + thresholds (`Voltage ·
  UpperCritical 13.0 / LowerCritical 11.0`) that sighted users see. Each
  merged label now appends that visible subtitle context — `Temperature CPU1
  Temp, 41.0°C, Unknown, caution 45 / crit 55`, `Fan Fan0, 5400 RPM, Unknown,
  CPU`, `Sensor PSU1, 12.50 V, Unknown, Voltage, UpperCritical 13.0 /
  LowerCritical 11.0` — one self-describing announcement that mirrors the
  visible text (a screen reader now hears what sighted users read). +1 widget
  test asserts the detail-aware labels + visible subtitles stay; existing
  no-context fixtures still pass unchanged (13 → 14 sensors tests; targeted
  run 14/14 before the full gate). No new dependencies; no layout change, so
  the 320/800/1300 no-overflow tests are unaffected.
- **Verification:** analyze 0; tests **360 passed / 1 skipped** (+1 — the new
  sensor detail-context test); issues validate OK; `git diff --check` clean;
  secret scan: Dart code + JSON-prose docs only, no credentials; `git diff
  --stat` 5 files: sensors_view.dart, sensors_widget_test.dart, README.md,
  REQUIREMENTS.md, FUTUREWORK.md. `dart format` reflowed the widget test only
  (2 touched files, 1 changed).
- **Commit:** (pending this run) —
  `auto: DOCS — anchors re-verified (no corpus refresh) + bmcweb file-level
  provenance pinned + UI-2 sensor tile subtitle context (run 2026-10-25
  07:10)`.
- **Next:** 1) EMULATOR per alternation — corpus mirror queue EMPTY and
  verified; candidates: re-run the corpus-invariant published-types crawl on
  the pinned `23d21f9a`, or pin the last un-pinned service-root branches
  (`CertificateService`, `KeyService`/`NVMeoFSecrets`, `ComponentIntegrity` —
  NOT client-mapped → no fixture duty; keep NVMeoFSecrets read-only); 2) P1
  #015 AuthManager — wire `Session.expiryFromService` into login, re-auth on
  `isExpired`, token/location from create RESPONSE HEADERS only; 3) keep
  pushing every run (credentials verified; 0 queued commits).

## 2026-10-25 07:15 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `a6f90f7..761bb67  main -> main` — the DOCS auto commit (761bb67) pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 07:13 UTC — EMULATOR (last un-pinned service-root branches) + UI-2 OverviewView Memory card body

- **Baseline:** analyze 0; tests 360 passed / 1 skipped; starting commit ce1745e
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last primary: DOCS 07:10 — EMULATOR
  is due). Corpus mirror queue is EMPTY and verified, so this run took the queued
  "read-surface pin for the last un-pinned service-root branches" candidate —
  `CertificateService`, `KeyService`, `ComponentIntegrity` — closing the last
  "un-pinned branch" note every prior run has carried:
  1. **CertificateService read surface pinned:** `CertificateLocations`
     (`#CertificateLocations.v1_0_3`) `Links.Certificates[]` enumerates the
     three certificate stores the fixture serves (Managers/BMC HTTPS server
     cert, UpdateService ClientCertificates, Systems/VirtualMedia CD1 cert) —
     the location-list a certificate-management flow starts from (the 06:15 run
     had pinned only the actions + ActionInfo resources).
  2. **KeyService pinned read-only:** `#KeyService.v1_0_0` advertises both
     NVMeoF sub-collections; `NVMeoFKeyPolicies/0` (`#KeyPolicy.v1_0_0`)
     pins the NVMeoF allow-lists (SecurityTransportAllowList TLSv2/v3,
     CipherSuiteAllowList, SecurityProtocolAllowList DHHC/TLS_PSK,
     DHGroupAllowList, SecureHashAllowList) — a #022-style allow-list shape
     (read-only); `NVMeoFSecrets` (`#KeyCollection.KeyCollection`, 2 members)
     is pinned **collection-metadata only**: the members carry real key material
     (`KeyString`), so the suite asserts the surface exists + member `@odata.id`
     list + count WITHOUT fetching a member body — the #015/#026
     never-read-secrets-back rule, deliberately stated as a scope boundary in
     the test.
  3. **ComponentIntegrity pinned:** collection (4 members: SS-SPDM-0/1,
     USB-Integrity, TPM-0) + `#ComponentIntegrity.v1_2_2` member shapes —
     SPDM (enabled, MeasurementSet with DMTF spec + non-empty Measurements
     digests, TargetComponentURI → AC-RoT0), TPM (PCR measurement set), and the
     **disabled** USB member (enabled-state read per member, never assumed).
  All three families remain **NOT client-mapped** → no fixture schema duty
  (corpus-invariant unchanged); EMU 71 → **75 tests** (all pass on pinned
  `23d21f9a`; run_tests.sh trap stopped the server; port closed after).
- **Docs:** none new mirrored (corpus queue EMPTY). REQUIREMENTS.md updated:
  emulator-suite test count 60 → 75 in the "Test platforms" note + a new
  "Last audited" entry documenting the three branch pins (with the
  NVMeoFSecrets security boundary).
- **Emulator:** 75/75 passed on pinned `23d21f9a` (server setup + cert + suite
  via `tool/emulator/run_tests.sh`; trap cleanup verified, no leftover process;
  port 8443 confirmed closed after the run).
- **Code/tests:** no production lib change from the EMU stream (4 new read-
  surface pins in `test_integration/emulator/emulator_suite_test.dart` only).
  UI-2 increment below touched `lib/features/overview/views/overview_view.dart`
  + its test.
- **UI:** one small tested UI-2 increment — **OverviewView Memory card body now
  one merged semantics node**. The card's capacity (`32 GiB`) sat under the
  merged "Memory" header as a bare detached `Text` — a screen reader heard a
  naked number with no context (the same class as the Processors card body
  merged earlier today). It now renders inside the established
  `Semantics(container + excludeSemantics)` card-body pattern: one
  self-describing announcement (`32 GiB`) that mirrors the visible text; visible
  text preserved for sighted users. +1 widget test (merged label findsOneWidget
  + visible text preserved). Targeted run: 15/15 passed before the full gate
  (OverviewView 14 → 15). No new dependencies; no layout change (the
  Semantics wrapper does not alter geometry), so the 320/800/1300 no-overflow
  tests are unaffected.
- **Verification:** analyze 0; tests **361 passed / 1 skipped** (+1 — the new
  Memory-card test); emulator 75/75; issues validate OK; `git diff --check`
  clean; secret scan: Dart code + JSON-prose docs only, no credentials (the
  `DHHC` hit is a SecurityProtocolAllowList protocol identifier; the
  `secrets` hit is the NVMeoFSecrets collection local variable — the suite
  never fetches a member body, so no `KeyString` appears anywhere);
  `git diff --stat` 4 files: emulator_suite_test.dart, overview_view.dart,
  overview_view_test.dart, REQUIREMENTS.md. `dart format` reflowed the
  emulator suite only (my new group needed reflow; 114 files scanned).
- **Commit:** f275175 —
  `auto: EMULATOR — last service-root branches pinned (CertificateLocations /
  KeyService read-only / ComponentIntegrity, EMU 71→75) + UI-2 Memory card body
  merged (run 2026-10-25 07:13)`; pushed: yes (see push record below).
- **Next:** 1) DOCS per alternation — corpus mirror queue EMPTY and verified;
   cheap candidate: anchor freshness re-verification (bmcweb `63a18f4`, mockup
   `23d21f9a`, DSP0266 1.25.0, schema index byte-compare), or a REQUIREMENTS.md
   housekeeping pass now that the service-root branch pins are complete
   (e.g. reconcile the "60 tests" wording elsewhere if it lingers); 2) P1 #015
   AuthManager — wire `Session.expiryFromService` into login, re-auth on
   `isExpired`, token/location from create RESPONSE HEADERS only; 3) keep
   pushing every run (credentials verified; 0 queued commits).

## 2026-10-25 07:15 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `ce1745e..f275175  main -> main` — the EMULATOR auto commit (f275175)
  pushed. `git rev-list --count origin/main..HEAD` = 0 (fully synced),
  working tree clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 08:06 UTC — DOCS (anchors re-verified + Test-platforms description reconciled) + UI-2 OverviewView Temperature/LED card bodies

- **Baseline:** analyze 0; tests 361 passed / 1 skipped; starting commit ba97fac
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last primary: EMULATOR 07:13 — DOCS is
  due). The corpus mirror queue is EMPTY and verified (DOCS-27/28/29 all
  confirmed ZERO version advances), so this run took the two queued cheap
  candidates in one pass:
  1. **Anchor freshness re-verification — no corpus refresh.** bmcweb `63a18f4`
     still HEAD (GitHub API); all four mirrored bmcweb docs byte-identical at
     current master; mockup `23d21f9a` still HEAD of `main` (GitHub API,
     full SHA `23d21f9a3610f6b6fbb71ffc941296b159a524d2`); DSP0266 1.25.0 200
     on the working `www.dmtf.org` URL with the PDF byte-identical
     (`385ee6d0…`); schema index **byte-identical** to the mirrored
     `v1-index.html` (SHA-256 `e5a29797…`, 3,448,133 B) → **no new downloads,
     no corpus refresh** (DOCS-27's ZERO advances re-proven).
  2. **REQUIREMENTS.md housekeeping — "Test platforms" description reconciled
     with the 75-test suite.** The emulator-suite note counted **75 tests** but
     the described pins ended at EMU 59→60 (If-Match). Extended the
     description with the EMU 60→75 pins so the count is backed by what the
     tests actually cover: chassis Controls + second live PATCH pin (SetPoint,
     EMU 60→63), Bios/Settings PATCH round-trip + settings-object ETag (EMU
     63→64), ThermalSubsystem Heaters + Manager.Reset round-trip (EMU 64→66),
     generalized `$expand` on Chassis/Managers + `$levels=2` depth cap (EMU
     66→68), the two negative facts (bad login mints a session;
     `MultipartHttpPushUri` absent — EMU 69), the ActionInfo *resource*
     contract (CertificateService actions, EMU 69→71), and the last three
     service-root branches (CertificateLocations / KeyService read-only /
     ComponentIntegrity incl. the NVMeoFSecrets collection-metadata-only
     boundary, EMU 71→75). "Last audited" header + manifest anchors note
     updated (08:06 UTC) with the re-verification.
- **Docs:** anchors verified 08:06 UTC (see above); REQUIREMENTS.md Test
  platforms note extended (+97 lines), "Last audited" header rotated;
  `documentations/external/README.md` manifest re-verified timestamps
  (07:00/00:15 → 08:06 UTC) + anchors header rotated. No new files mirrored,
  no downloads (corpus mirror queue stays EMPTY).
- **Emulator:** none this run (DOCS stream; the 75-test suite was verified
  green on `23d21f9a` at 07:13).
- **Code/tests:** no production lib change from the docs stream. UI-2
  increment below touched `lib/features/overview/views/overview_view.dart` +
  its test.
- **UI:** one small tested UI-2 increment — **OverviewView Temperatures + LED
  card bodies now merged semantics nodes**. The two card bodies were the last
  bare `Text`s in the OverviewView card set: the temperature reading
  (`42.0 °C`) and the indicator-LED state (`Lit`) each announced as a detached
  node under their merged card headers (the same class as the Memory card body
  merged at 07:13). Both now render inside the established
  `Semantics(container + excludeSemantics)` card-body pattern — one
  self-describing announcement that mirrors the visible text; visible text
  preserved for sighted users. +2 widget tests (merged
  `find.bySemanticsLabel('42.0 °C')` / `('Lit')` findsOneWidget + visible
  text preserved). Targeted run: 17/17 passed before the full gate
  (OverviewView 15 → 17). No new dependencies; no layout change (the Semantics
  wrapper does not alter geometry), so the 320/800/1300 no-overflow tests are
  unaffected.
- **Verification:** analyze 0; tests **363 passed / 1 skipped** (+2 — the two
  new card-body tests); issues validate OK; `git diff --check` clean; secret
  scan: Dart code + JSON-prose docs only, no credentials (the `password`/
  `key`/`token` hits are Redfish protocol prose — session-login description,
  KeyService/KeyPolicy resource names, SHA-256 checksums); `git diff --stat`
  4 files: README.md, REQUIREMENTS.md, overview_view.dart,
  overview_view_test.dart. `dart format` reflowed overview_view.dart only
  (114 files scanned, 1 changed).
- **Commit:** (pending this run) —
  `auto: DOCS — anchors re-verified (no corpus refresh) + Test-platforms
  description reconciled to 75 tests + UI-2 Temperature/LED card bodies merged
  (run 2026-10-25 08:06)`.
- **Next:** 1) EMULATOR per alternation — corpus mirror queue EMPTY and
  verified; candidates: re-run the corpus-invariant published-types crawl on
  the pinned `23d21f9a` (cheap re-proof), or pin a remaining un-pinned
  service-root branch (all main branches are pinned — the remaining surface is
  ActionInfo/`ResetActionInfo` crawler work which is a code task #022/#016);
  2) P1 #015 AuthManager — wire `Session.expiryFromService` into login,
  re-auth on `isExpired`, token/location from create RESPONSE HEADERS only;
  3) keep pushing every run (credentials verified; 0 queued commits).

## 2026-10-25 08:07 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `ba97fac..650ef31  main -> main` — the DOCS auto commit (650ef31) pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 13:10 UTC — EMULATOR (last un-pinned ActionInfo families, EMU 75→78) + UI-2 PowerView header subtitle

- **Baseline:** analyze 0; tests 363 passed / 1 skipped; starting commit a846990
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last primary: DOCS 08:06 — EMULATOR
  is due). All service-root branches were already pinned (EMU 71→75) and the
  corpus-invariant crawl *visits* every `@Redfish.ActionInfo` link, but the
  suite's ActionInfo-resource group pinned only the two CertificateService
  resources. This run closed the remaining **ActionInfo families on the
  fixture** (EMU 75→78):
  1. **`EventService.SubmitTestEventActionInfo`** — the recurring #022/#016
     "crawl the ActionInfo *resource*" contract applied to the #019/DOCS-7
     test-event action: the action advertises `@Redfish.ActionInfo` that
     resolves to `#ActionInfo.v1_4_1.ActionInfo` with 9 `Parameters[]`,
     `MessageId` the one REQUIRED parameter, `EventType` AllowableValues
     [StatusChange/ResourceUpdated/ResourceAdded/ResourceRemoved/Alert/Other],
     `MessageArgs` DataType StringArray, `EventGroupId` DataType Number.
  2. **`#Certificate.Rekey` `RekeyActionInfo`** on the manager HTTPS
     certificate — a FOURTH ActionInfo family: `KeyPairAlgorithm` REQUIRED
     + AllowableValues (TPM_ALG_RSA/TPM_ALG_ECDSA), `KeyBitLength` optional
     Number, `KeyCurveId` AllowableValues (3 NIST curves).
  3. **Consistency across the other two certificate stores** the
     `CertificateLocations` pin (EMU 75) lists —
     `UpdateService/ClientCertificates/1` +
     `AccountService/OutboundConnections/1/Certificates/1` — the SAME
     RekeyActionInfo contract (3 Parameters, same shape) is verified on every
     store, so a #022/#016-style crawler can rely on the identical
     Parameters/AllowableValues shape everywhere.
  `ResetActionInfo` itself is still absent on this fixture (the OpenBMC
  allow-list-source crawl stays a code task #022/#016). Suite 75 → **78/78**
  passed live on pinned `23d21f9a`; trap cleanup verified, port closed.
- **Docs:** REQUIREMENTS.md "Test platforms" count 75 → 78 + the ActionInfo
  trace paragraph extended with the EMU 75→78 pins (SubmitTestEvent +
  Certificate.Rekey incl. the three-store consistency). No new corpus
  downloads (corpus mirror queue stays EMPTY).
- **Emulator:** 78/78 green on pinned `23d21f9a` (verified 13:09 UTC);
  server stopped after the run; no leftover process.
- **Code/tests:** no production lib change from the emulator stream.
  `test_integration/emulator/emulator_suite_test.dart` +3 tests (184 lines).
  UI-2 increment below touched `lib/features/power/views/power_view.dart` +
  its test.
- **UI:** one small tested UI-2 increment — **PowerView card header now
  announces as ONE node incl. the "Power control" subtitle**. The merged
  header previously announced `<name>, power <state>` while the
  `Power control` subtitle rendered below it as a bare detached `Text` (the
  same list-header class the KVM header merged earlier); the whole card
  header (display name + PowerBadge + subtitle) now wraps in a Column inside
  the established `Semantics(container + excludeSemantics)` node and
  announces `<name>, power <state>, Power control` — one self-describing
  announcement, visible texts preserved for sighted users. The existing
  header test extended to assert the merged label incl. subtitle + visible
  text preserved + `bySemanticsLabel('Power control')` findsNothing (no
  double-announce). No new dependencies; no layout change (Column wrapper
  keeps the exact dimensions), so the 320/800/1300 no-overflow tests are
  unaffected (PowerView card is a single-column Card stack).
- **Verification:** analyze 0; tests **363 passed / 1 skipped** (header test
  extended in place, count unchanged); emulator 78/78; issues validate OK;
  `git diff --check` clean; secret scan: Dart code + JSON-prose docs only, no
  credentials (the `key`/`certificate`/`token` hits are Redfish protocol
  prose — RekeyActionInfo/KeyPairAlgorithm resource names, SHA-256 checksums);
  `git diff --stat` 5 files: FUTUREWORK.md, REQUIREMENTS.md, power_view.dart,
  power_view_test.dart, emulator_suite_test.dart. `dart format` reflowed the
  emulator suite only (my new tests needed format; 114 files scanned).
- **Commit:** (pending this run) —
  `auto: EMULATOR — last ActionInfo families pinned (SubmitTestEvent +
  Certificate.Rekey x3 stores, EMU 75→78) + UI-2 PowerView header subtitle
  merged (run 2026-10-25 13:10)`.
- **Next:** 1) DOCS per alternation — corpus mirror queue EMPTY and verified;
   cheap candidates: anchor freshness re-verification (bmcweb `63a18f4`,
   mockup `23d21f9a`, DSP0266 1.25.0, schema index byte-compare), or a
   REQUIREMENTS.md housekeeping pass; 2) P1 #015 AuthManager — wire
   `Session.expiryFromService` into login, re-auth on `isExpired`,
   token/location from create RESPONSE HEADERS only; 3) keep pushing every
   run (credentials verified; 0 queued commits).

## 2026-10-25 13:12 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `a846990..3d22264  main -> main` — the EMULATOR auto commit (3d22264)
  pushed. `git rev-list --count origin/main..HEAD` = 0 (fully synced),
  working tree clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 10:27 UTC — DOCS (EMU 71→75 branch-pinned families mirrored, DOCS-30) + UI-2 SystemOverviewPage connection error

- **Baseline:** analyze 0; tests 363 passed / 1 skipped; starting commit 07d1e57
  (origin/main fully synced, 0 queued local commits); issues validate OK;
  working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last primary: EMULATOR 13:10 — DOCS
  is due). The corpus-invariant crawl *visits* the EMU 71→75 branch pins, but
  the external corpus had **no schema at all** for any of the certificate /
  key / component-integrity families (`grep` for CertificateService /
  CertificateLocations / Certificate / KeyService / KeyPolicy / Key /
  ComponentIntegrity in `documentations/external/redfish/schemas/v1/`
  returned nothing). Closed that gap with **DOCS-30** — the "newest + served"
  pair precedent (DOCS-24/25/26/28): mirrored **25 files / 446,257 bytes**
  (inside the DOCS-6 budget) into the external corpus only (all seven
  families stay **NOT client-mapped** → no fixture duty, corpus-invariant
  unchanged):
  1. **`CertificateService`** — served `v1_0_4` (the GenerateCSR /
     ReplaceCertificate action targets + the CertificateLocations link behind
     the EMU 71 ActionInfo pins) + newest `v1_2_2` (adds only
     AutomaticCertificateEnrollment/CertificateEnrollments/
     EnrollmentCACertificates, readonly — additive) + aggregator.
  2. **`CertificateLocations`** — served `v1_0_3` (the three-certificate-store
     `Links.Certificates` pin list) + newest `v1_0_4` (property no-op) +
     aggregator.
  3. **`Certificate`** — served `v1_8_1` (the store members the Rekey /
     GenerateCSR pins type) + newest `v1_11_0` (**adds `Password`/`Status`** —
     `Password` is a #015/#026 never-read-back note, same class as the
     VirtualMedia `Password`/`UserName`, DOCS-24) + aggregator +
     `CertificateCollection`.
  4. **`KeyService`** — served `v1_0_0` (the NVMeoFSecrets + NVMeoFKeyPolicies
     links) + newest `v1_0_1` (property no-op) + aggregator.
  5. **`KeyPolicy`** — served `v1_0_0` (the NVMeoF allow-list surface:
     SecurityTransport/CipherSuite/SecurityProtocol/DHGroup/SecureHash
     AllowLists — the #022-style read-only shape) + newest `v1_0_1` (property
     no-op) + aggregator + `KeyPolicyCollection`.
  6. **`Key`** — served `v1_4_0` (the NVMeoFSecrets members; the suite pins
     collection-metadata only, never the `KeyString` body — the #015/#026
     never-read-secrets-back boundary) + newest `v1_4_1` (property no-op) +
     aggregator + `KeyCollection`.
  7. **`ComponentIntegrity`** — served `v1_2_2` (the SPDM/TPM/USB member
     shapes incl. the disabled USB member) + newest `v1_5_0` (property no-op
     for the client-relevant surface) + aggregator +
     `ComponentIntegrityCollection`.
  Delta audit **additive-only** across all seven families — **no client code
  change**. Every `@odata.type` the pinned mockup publishes now has a
  served-version schema in the external corpus; **corpus mirror queue EMPTY**.
- **Docs:** 25 files fetched 200 from `https://redfish.dmtf.org/schemas/v1/`
  (15:40 UTC), JSON-validated, SHA-256s + byte sizes verified; manifest rows
  added (133 rows total), the "Downloaded schema set" list grew 25 → 32
  aggregator names; REQUIREMENTS.md "Last audited" header rotated + DOCS-30
  trace table added citing the real mirror files; FUTUREWORK.md DOCS-30 entry
  added. Anchors re-verified the same run: bmcweb `63a18f4`, mockup
  `23d21f9a`, DSP0266 1.25.0, schema index 200.
- **Emulator:** none this run (78/78 suite stays green on `23d21f9a` from the
  13:10 run; plain `flutter test` never touches it).
- **Code/tests:** no production lib change from the docs stream. UI-2
  increment below touched `lib/features/systems/views/system_overview_page.dart`
  + `test/features/systems/ui_widget_test.dart` (+1 test).
- **UI:** one small tested UI-2 increment — **SystemOverviewPage connection
  error now announces as ONE merged node (icon + message)**. The inline
  `Connection error: <msg>` was the last bare detached error `Text` in the
  app (the 2026-10-23 note deliberately left it as its own node); every other
  error state (OverviewView/SensorsView/FirmwareView/KVM/PowerView inline
  errors) uses the established `Semantics(container + excludeSemantics)`
  icon+text pattern. It now renders inside that pattern (`Connection error:
  boom` as one self-describing announcement, `Icons.error_outline` +
  visible text preserved, the Connect button below keeps its own control
  node); +1 widget test asserts the merged `bySemanticsLabel` node + visible
  text + icon. No new dependencies; no layout change (Row wrapper keeps
  natural height), so the 320/800/1300 no-overflow tests are unaffected.
- **Verification:** analyze 0; tests **364 passed / 1 skipped** (+1 — the new
  merged-node test); issues validate OK; `git diff --check` clean; secret
  scan: Dart code + JSON-prose docs only, no credentials (the `password`/
  `key`/`KeyString` hits are Redfish protocol prose — session-login
  description, KeyService/KeyPolicy/Key resource names, SHA-256 checksums);
  `git diff --stat` 5 modified + 25 new schema files; `dart format` reflowed
  114 files scanned, 0 changed.
- **Commit:** (pending this run) —
  `auto: DOCS — EMU 71→75 branch-pinned families mirrored (CertificateService/
  CertificateLocations/Certificate/KeyService/KeyPolicy/Key/ComponentIntegrity,
  DOCS-30) + UI-2 SystemOverviewPage connection error merged (run 2026-10-25
  10:27)`.
- **Next:** 1) EMULATOR per alternation — corpus mirror queue EMPTY and
  verified; candidates: re-run the corpus-invariant published-types crawl on
  the pinned `23d21f9a` (cheap re-proof; it now also covers the 7 newly
  mirrored families), or the `ResetActionInfo`-crawler code task #022/#016;
  2) P1 #015 AuthManager — wire `Session.expiryFromService` into login,
  re-auth on `isExpired`, token/location from create RESPONSE HEADERS only;
  3) keep pushing every run (credentials verified; 0 queued commits).

## 2026-10-25 10:29 UTC — PUSH RECORD (success)

- `git push origin main` after the run above **succeeded**:
  `07d1e57..1e6d841  main -> main` — the DOCS auto commit (1e6d841) pushed.
  `git rev-list --count origin/main..HEAD` = 0 (fully synced), working tree
  clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 14:10 UTC — DOCS (crashed-run recovery verified: DOCS-31 corpus + anchors) + UI-2 loading-state semantics

- **Baseline:** analyze 0; tests 364 passed / 1 skipped; starting commit a458ded
  (ahead of origin/main by 1 — the crashed run's DOCS-31 recovery commit, never
  pushed); issues validate OK; working tree carried the crashed run's remaining
  WIP: REQUIREMENTS.md "Last audited" section (anchor freshness re-verification
  + DOCS-31 newest-version spot audit, 28 lines uncommitted); no stash, no
  other leftovers. The crashed run had committed a458ded (65 DOCS-31 schema
  files + manifest + FUTUREWORK + REQUIREMENTS.md header) but crashed before
  committing the Last-audited tail, writing tracking/journal, and pushing.
- **Primary work:** DOCS — finish + verify the crashed run, per alternation
  (last completed primary: EMULATOR 13:10). Per runbook §0 the remaining
  REQUIREMENTS.md WIP was clearly the previous automation's work → committed it
  as recovery (`4753e4f`, after correcting one factual drift: the recovered
  text claimed "365 unit tests pass"; the actual gate is **364 passed / 1
  skipped**, now recorded truthfully). Then **re-verified every DOCS-31 claim
  live this run**: (1) corpus-invariant **78/78 emulator suite re-run** on the
  pinned `23d21f9a` via `tool/emulator/run_tests.sh` — green; (2) anchors —
  bmcweb master HEAD `63a18f4e…` (via `git ls-remote`, still HEAD), mockup main
  HEAD `23d21f9a…` (still HEAD), DSP0266 1.25.0 PDF **byte-identical** SHA-256
  `385ee6d0…` vs the mirrored copy (fetched `www.dmtf.org` live), schema index
  **byte-identical** SHA-256 `e5a29797…` (3,448,133 B) vs the mirrored
  `v1-index.html`; (3) the 17 DOCS-31 families' newest versions matched
  (spot-audit claim in the recovered text) — supported by the byte-identical
  index + the mirror queue stays EMPTY. **No corpus refresh, no new downloads
  (0 bytes this run).**
- **Docs:** no files added; the DOCS-31 corpus mirror (65 files) had been
  committed in a458ded (recovered last run) and is now **verified end-to-end +
  pushed**; manifest rows untouched (a458ded already added them);
  REQUIREMENTS.md Last-audited header now reflects this run's fresh
  re-verification; corrected test-count prose 365 → "364 pass (1 skipped)".
- **Emulator:** 78/78 suite re-run live this run (the DOCS-31 extended
  corpus-invariant crawl included) — all green on the pinned `23d21f9a`;
  server stopped via trap, nothing left in the repo or running.
- **Code/tests:** no production behaviour change beyond the UI-2 increment
  below. `+2` widget tests (sensors 14→15, kvm 12→13). No issues touched.
- **UI:** one small tested UI-2 increment — **the unlabeled loading spinners
  merge into self-describing announcements** (the last bare progress nodes in
  the feature views): SensorsView's full-screen spinner now announces ONE
  merged `Loading sensors` node, and KvmView's first-load spinner announces ONE
  merged `Loading KVM consoles` node (both via the established
  `Semantics(container + excludeSemantics)` loading pattern — FirmwareView
  header/inventory precedent; visible spinners preserved). The KVM fix also
  corrected a small state-ordering bug the merge exposed: the view previously
  checked the empty state BEFORE loading, so a first load flashed the
  misleading `No consoles found.` — the merged loading node now renders before
  the empty branch (`loading && consoles.isEmpty`), while refreshes with
  existing consoles keep the inline spinner under the header. +2 widget tests
  assert the merged labels + spinner presence. No new dependencies; no layout
  change to the responsive tests (320/800/1300 unaffected).
- **Verification:** analyze 0; tests **366 passed / 1 skipped**; emulator
  78/78; issues validate OK; `git diff --check` clean; secret scan: Dart code +
  docs prose only, no credentials; `git diff --stat` 4 files (2 views + 2
  tests). `dart format` on the 4 touched files only (avoiding the documented
  formatter-drift churn).
- **Commit:** 4753e4f — `chore: recover previous automation WIP (REQUIREMENTS.md
  — DOCS anchor re-verification + DOCS-31 newest-version spot audit)` +
  (pending) `auto: DOCS — crashed-run recovery verified (DOCS-31 corpus +
  anchors) + UI-2 loading-state semantics merged (Sensors/KVM) (run
  2026-10-25 14:10)`; pushed: yes after this section (a458ded + 4753e4f +
  this commit were queued ahead of origin/main).
- **Next:** 1) EMULATOR per alternation — corpus mirror queue EMPTY and now
  re-proven 78/78; candidates: the `ResetActionInfo` ActionInfo-*resource*
  crawl as code work (#022/#016), or re-run the invariant suite cheaply;
  2) P1 #015 AuthManager — wire `Session.expiryFromService` into login, re-auth
  on `isExpired`, token/location from create RESPONSE HEADERS only;
  3) keep pushing every run (credentials verified; 2 commits queued before
  this run's).

## 2026-10-25 14:1x UTC — PUSH RECORD (success)

- `git push origin main` **succeeded**: `ed78c28..1673140 main -> main` — three
  commits pushed in one go: `a458ded` (crashed DOCS-31 corpus recovery),
  `4753e4f` (REQUIREMENTS.md Last-audited recovery), and `1673140` (this run's
  auto commit). `git rev-list --count origin/main..HEAD` = 0 (fully synced),
  working tree clean. Queued local commits ahead of origin/main: **0**.

## 2026-10-25 15:47 UTC — EMULATOR (ResetActionInfo ActionInfo-resource crawl wired into FeatureRules, EMU 78→79) — UI skipped (documented)

- **Baseline:** analyze 0; tests 366 passed / 1 skipped; starting commit 5a90c95 (origin/main fully synced, 0 queued local commits); issues validate OK; working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last primary: DOCS 14:10 — EMULATOR is due again). Picked the agreed candidate from the last three tracking entries + FUTUREWORK focus: **the `ResetActionInfo` ActionInfo-*resource* crawl (#022/#016) is now WIRED — no longer a TODO**. Two pieces landed: (1) `DiscoveryEngine` follows `@Redfish.ActionInfo` links during the crawl — `_childLinks` returns `_actionInfoLinks(res)` (the `@Redfish.ActionInfo` URIs beside each action's `target`; POST-only targets are never followed), the fetched ActionInfo resources are classified into a new `DiscoveryContext.actionInfos` map keyed by relative path; (2) `FeatureRules.supportedResetTypes` now unions a **third allow-list source** — `Parameters[].AllowableValues` on the `ResetType` parameter of the ActionInfo resource the `#ComputerSystem.Reset` action links to (bmcweb's `ResetActionInfo` shape, DOCS-4/13), with the existing manager-list conflation guard (only the system's own linked resource is read; a `#Manager.Reset`/`#ComputerSystem.SetPowerState` link or a non-listed ActionInfo never leaks in). `build` passes `ctx.actionInfos`. The ActionInfo resource shape itself had been pinned live EMU 69→78 (CertificateService/EventService/Rekey); this run adds the engine-level crawl + the FeatureRules consumer. `ResetActionInfo` itself is still absent on the DMTF fixture, so the live pin uses the fixture's served ActionInfo resources.
- **Docs:** no corpus downloads (corpus mirror queue stays EMPTY — re-verified anchors unchanged this run: bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200). REQUIREMENTS.md updated: the bmcweb `ResetActionInfo` row now shows the three-source union + real tests (was "ActionInfo *resource* crawling stays #022/#016"); "Test platforms" emulator count 78 → 79 with the new crawl pin described; the #022/#016 ActionInfo trace paragraph folded the "remaining piece" language into landed.
- **Emulator:** 78 → **79/79 green** on pinned `23d21f9a` (two official `tool/emulator/run_tests.sh` runs — the first full-suite run after the code change + a confirmation run grepping the new test name; both passed 79/79; an ad-hoc manual server start raced and showed Connection-refused on one attempt — startup race in the throwaway script, not a test failure; the official script's health-wait passed both times). New live test: "discovery engine follows @Redfish.ActionInfo links and the crawl captures live ActionInfo resources" — runs a normal `DiscoveryEngine().discover()` against the real mockup, asserts `features.raw` contains `/redfish/v1/UpdateService/SimpleUpdateActionInfo` (the fixture's SimpleUpdate action advertises `@Redfish.ActionInfo`, EMU 45) and that `FeatureRules.allowableValuesFromActionInfo(body, 'TransferProtocol')` reads the live allow-list (`HTTP/HTTPS/SFTP`); also asserts the system reset allow-list is still non-empty (annotation form — the documented fixture boundary). Server stopped via trap; no leftover process.
- **Code/tests:** `lib/redfish/discovery/discovery_engine.dart` (+`_actionInfoLinks`, ActionInfo classification, `actionInfos` pass-through), `lib/redfish/discovery/feature_rules.dart` (+`allowableValuesFromActionInfo`, +`resetTypesFromActionInfo`, three-source union, `DiscoveryContext.actionInfos`). +4 unit tests in `feature_rules_test.dart` (DSP0266 §9.6.14 parser; absent/malformed resilience; follow-link + manager-guard; three-source union), +2 discovery-engine tests (link followed + values folded into the feature map + rawTree capture; dangling 404 ActionInfo link degrades gracefully to `_error` + remaining sources). Full unit suite 366 → **372 passed / 1 skipped**. Issues #022/#016 Progress Logs updated.
- **UI:** **skipped this run, documented.** The primary EMULATOR workstream (code + tests + live emulator verification) consumed the budget. Audited the remaining UI-2 backlog: every concrete "last bare text" surface is already merged (this run re-verified System-not-found ×3, sensors section headers, loading spinners, KVM connect-URI, firmware summary/loading, dashboard empty/error/aggregate, profile-form warning banner, add-system dialog), and the remaining UI-2 item is the open-ended "focus order + remaining dialogs/tables" hunt that prior runs deliberately did not rush — per runbook §5, a rushed untested redesign is worse than a documented skip. The Control SetPoint AllowableMin/Max pre-validation (#022) similarly stays FUTUREWORK.
- **Verification:** analyze 0; tests **372 passed / 1 skipped**; emulator **79/79**; issues validate OK; `git diff --check` clean; secret scan: Dart code + docs prose only, no credentials (the `Password`/`KeyString` hits are Redfish protocol prose — ActionInfo parameter names/SHA-256s); `git diff --stat` 9 files, +542/−84.
- **Commit:** (pending) `auto: EMULATOR — ResetActionInfo ActionInfo-resource crawl wired into FeatureRules.supportedResetTypes (engine follows @Redfish.ActionInfo, third allow-list source, #022/#016; EMU 78→79)` (run 2026-10-25 15:47 UTC).
- **Next:** 1) DOCS per alternation (corpus mirror queue EMPTY; cheap anchor re-verify — bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200); 2) the remaining #022/#016 pieces — the Control SetPoint AllowableMin/Max pre-validation rule (#006/#019/#022; AllowableMin/Max pinned EMU 60→63) and the Boot/IndicatorLED PATCH flow + 412 unit tests (settings-object ETag `9234ac83b9700123cc32` is the only pinable token); 3) P1 #015 AuthManager — wire `Session.expiryFromService` into login, re-auth on `isExpired`, token/location from create RESPONSE HEADERS only; keep pushing every run (0 queued).

## 2026-10-25 15:5x UTC — PUSH RECORD (success)

- `git push origin main` **succeeded**: `5a90c95..a2d23a3 main -> main` — the
  EMULATOR auto commit (a2d23a3) pushed. `git rev-list --count origin/main..HEAD`
  = 0 (fully synced), working tree clean. Queued local commits ahead of
  origin/main: **0**.

## 2026-10-25 16:50 UTC — DOCS (anchor re-verify, no corpus refresh) + small safe #016 If-Match wiring + UI-2 KVM chip merge

- **Baseline:** analyze 0; tests 372 passed / 1 skipped; starting commit d1f4b78 (origin/main fully synced, 0 queued local commits); issues validate OK; working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last primary: EMULATOR 15:47 — DOCS is due; the runbook alternation starts with DOCS on a green baseline and the corpus mirror queue is EMPTY). **Re-verified all four upstream anchors live this run — no corpus refresh:** (1) bmcweb `63a18f4` still HEAD of `master` (`git ls-remote`); (2) mockup `23d21f9a` still HEAD of `main` (`git ls-remote`); (3) DSP0266 1.25.0 PDF from `www.dmtf.org` **byte-identical** SHA-256 `385ee6d0…` vs the mirrored `redfish/spec/DSP0266_1.25.0.pdf`; (4) DMTF schema index from `redfish.dmtf.org/schemas/v1/` **byte-identical** SHA-256 `e5a29797…` (3,448,133 B) vs the mirrored `v1-index.html` → DOCS-27's ZERO version advances still hold, the corpus mirror queue stays EMPTY for every published type, 0 bytes downloaded.
- **Docs:** no corpus files added. REQUIREMENTS.md updated: the DSP0266 §6.5/§7.6 PATCH trace row flipped `Partial — transport done; If-Match…` to **OK** — the If-Match/`@odata.etag` wiring is landed (the §6.5 "ETags" contract the row traces); "Last audited" header now records this run's anchor re-verification + the code gap closed. The audit surfaced a small safe gap to fix immediately (runbook §2.3): row 426 flagged If-Match wiring as the remaining #016 piece, and the issue's acceptance criteria were exactly the increment landed below.
- **Emulator:** re-ran the **79/79** integration suite live against the pinned `23d21f9a` via `tool/emulator/run_tests.sh` (the official harness; server stopped via trap) as a guard after changing the `patchJson` transport signature — **all green**, incl. the live Bios/Settings PATCH pins and the If-Match negative pin (the mockup IGNORES If-Match, so 412 enforcement stays unit-level — the documented fixture boundary).
- **Code/tests (small, safe, DOCS-driven — issue #016 acceptance criteria):** (1) `RedfishClient.patchJson(path, body:, headers:, etag:)` — new `etag` parameter sends an `If-Match` precondition header, quoted per RFC7232 §2.3.2 entity-tag grammar via new static `RedfishClient.quoteEntityTag` (unquoted payload-form `@odata.etag` values are quoted, `W/"…"`/pre-quoted tags pass through verbatim; an explicit `headers` `If-Match` is overridden by `etag`); (2) `ODataResource.etag` accessor reads `@odata.etag` from any resource body; (3) `RedfishException.isPreconditionFailed` classifies 412 (non-retryable — the caller must re-fetch the current `@odata.etag` and retry, not blind-retry). +6 unit tests in `auth_manager_test.dart` (etag → quoted If-Match; weak/pre-quoted passthrough; etag-wins-over-headers; 412 precondition failure incl. non-retryable; quoteEntityTag grammar helper) + `odata_test.dart` (`@odata.etag` accessor, null when absent) + negative pinned in the existing 403 row (not a precondition failure). Full unit suite 372 → **379 passed / 1 skipped**. Issue #016 Progress Log updated; acceptance criteria checked (transport-level); the Boot/IndicatorLED PATCH *service/UI flow* stays #016 (documented in issue + FUTUREWORK).
- **UI:** one small tested UI-2 increment — **KVM console card connect-type chips merged into ONE self-describing semantic node** (`Supported connection types: KVMIP, HTML5`): the `connectTypesSupported` chip `Wrap` previously announced each chip as its own detached node next to the already-merged card rows (the same "bare text class" every other row in the card had merged); each chip is now inside `Semantics(container + excludeSemantics)` so a screen reader hears one concise summary, visible chips stay for sighted users, empty `connectTypesSupported` renders nothing (no spurious "none" node). +1 widget test asserts the merged label + the bare chip labels no longer announce + visible texts preserved; KVM 12→13 (13→14 incl. this). No new dependencies, no layout change (responsive 320/800/1300 tests unaffected).
- **Verification:** analyze 0; tests **379 passed / 1 skipped**; emulator **79/79** live; issues validate OK; `git diff --check` clean; secret scan: Dart code + docs prose only, no credentials (`password`/`ETag` hits are Redfish protocol prose + the settings-object token `9234ac83b9700123cc32`, which is a fixture value not a secret); `git diff --stat` 8 files + docs.
- **Commit:** (pending) `auto: DOCS — anchors re-verified (no corpus refresh; mirror queue EMPTY) + #016 If-Match/etag wiring landed (patchJson etag, ODataResource.etag, 412 classification) + UI-2 KVM connect-type chips merged (run 2026-10-25 16:50)`.
- **Next:** 1) EMULATOR per alternation — re-run the 79/79 suite cheaply and/or continue the #022/#016 control-surface work (Control SetPoint AllowableMin/Max pre-validation, #006/#019/#022; boundaries pinned EMU 60→63); 2) P1 #015 AuthManager — wire `Session.expiryFromService` into login, re-auth on `isExpired`, token/location from create RESPONSE HEADERS only; 3) keep pushing every run (credentials verified; 0 queued after this run).

## 2026-10-25 16:55 UTC — PUSH RECORD (success)

- `git push origin main` **succeeded**: `d1f4b78..d856a67 main -> main` — the
  DOCS auto commit (d856a67) pushed. `git rev-list --count origin/main..HEAD`
  = 0 (fully synced), working tree clean. Queued local commits ahead of
  origin/main: **0**.

## 2026-10-25 17:50 UTC — EMULATOR (Control SetPoint pre-validation rule implemented; Control became client-mapped, EMU 79→80) — UI skipped (documented)

- **Baseline:** analyze 0; tests 379 passed / 1 skipped; starting commit 011aac3 (origin/main fully synced, 0 queued local commits); issues validate OK; working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** EMULATOR per alternation (last primary: DOCS 16:50 — EMULATOR is due). Landed the agreed #022/#016 candidate from the last three tracking entries: **the Control SetPoint AllowableMin/Max pre-validation rule is now code** (the "client must pre-validate" rule the pinned Control surface demands — EMU 60→63: the mockup applies `SetPoint: 9999` unvalidated, so a mutation flow MUST reject out-of-bounds SetPoints client-side before sending). Two pieces: (1) **model** — new `ControlResource` (`lib/redfish/models/control.dart`) parses the served `#Control.v1_5_0.Control` resources (Id/ControlType/ControlMode/SetPoint/SetPointUnits/AllowableMin/AllowableMax/Sensor.DataSourceUri; a null SetPoint is tolerated per the schema; string-numbers tolerated); (2) **rule** — `ControlResource.validateSetPoint(value)` returns a `SetPointValidation`: in-range + exact AllowableMin/Max boundary values pass (inclusive), below/above fail with an Allowable-range message, null fails ("A SetPoint value is required."), and a control with no advertised bounds is a documented best-effort (valid + informational "No AllowableMin/Max advertised" message). Bounds are per-resource and never leak across controls (the SecureBoot per-resource allow-list precedent applied to numeric bounds). Because the client now maps Control, the family **became client-mapped**: the served `Control.v1_5_0.json` was copied into `test/fixtures/redfish/schemas/` (byte-identical SHA-256 `de1614b0…`, 47,414 B, to the DOCS-26 mirror) and `Control` was added to the emulator corpus-invariant family list (the DOCS-19/20/21 fixture invariant now covers it — the live crawl asserts the served Control schema presence).
- **Docs:** no corpus downloads (mirror queue still EMPTY; anchors unchanged from the 16:50 run — bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index byte-identical). REQUIREMENTS.md updated: "Last audited" header now records this run; the Control trace rows + the DOCS-26 "Client-mapped decision" block flipped from NOT-client-mapped to client-mapped with the fixture copy + family-list note; "Test platforms" 79 → 80 with the pre-validation pin described; the historical DOCS-26 Prior entry got a dated update note (Control IS now client-mapped).
- **Emulator:** 79 → **80/80 green** on pinned `23d21f9a` via `tool/emulator/run_tests.sh` (official harness, trap cleanup; server stopped). New live test in the chassis-Controls group: "Control SetPoint pre-validation rule applied live" — parses the served PowerLimit + CPU1Freq via `ControlResource.fromJson`, asserts the pinned allowable ranges ([150,1000] / [1500,3700]), runs `validateSetPoint` over in-range/boundary/out-of-range/null values, and pins the cross-resource leakage guard (1500 is valid for CPU1Freq but rejected for PowerLimit). The existing Controls group (read + PATCH round-trip + `9999` negative) still passes unchanged.
- **Code/tests:** `lib/redfish/models/control.dart` (new, +`ControlResource` +`SetPointValidation`), `test/redfish/models/control_test.dart` (new, 11 tests: full PowerLimit/CPU1Freq parse; minimal/malformed/null-SetPoint/string-number tolerance; in-range/boundary/out-of-range/null/no-bounds validation; per-resource leakage guard), `test_integration/emulator/emulator_suite_test.dart` (+1 live test; `Control` added to the clientMappedFamilies set; import added), `test/fixtures/redfish/schemas/Control.v1_5_0.json` (new, byte-identical to the DOCS-26 external mirror). Full unit suite 379 → **390 passed / 1 skipped**. Issues #022 + #016 Progress Logs updated (the pre-validation rule is (d) of #016 — the remaining piece is now only (b) the Boot/IndicatorLED PATCH service/UI flow).
- **UI:** **skipped this run, documented.** The primary EMULATOR workstream (new model + rule + 11 unit tests + live emulator pin + client-mapping doc/fixture work) is a substantial finished increment. Re-audited the remaining UI-2 backlog: every concrete "last bare text" surface is already merged (System-not-found fallbacks ×3, loading spinners, KVM chips/rows, firmware inventory/summary/loading, sensors tiles + headers, dashboard empty/error/aggregate, overview identity/processors/memory/error, power header/error, profile-form warning banner, add-system dialog); the remaining UI-2 item is the open-ended focus-order/dialogs-tables hunt that prior runs deliberately did not rush — per runbook §5, a rushed untested change is worse than a documented skip.
- **Verification:** analyze 0; tests **390 passed / 1 skipped**; emulator **80/80** live; issues validate OK; `git diff --check` clean; secret scan: Dart code + docs prose only, no credentials (`Password`/`KeyString` hits are Redfish protocol prose — schema longDescriptions; SHA-256s are file hashes); `git diff --stat` ~12 files + docs.
- **Commit:** (pending) `auto: EMULATOR — Control SetPoint pre-validation rule implemented (ControlResource.validateSetPoint, AllowableMin/Max bounds, #022/#016) + Control became client-mapped (served schema in fixture, corpus-invariant list) + live emulator pin 79→80 (run 2026-10-25 17:50)`.
- **Next:** 1) DOCS per alternation — cheap anchor re-verify (corpus mirror queue still EMPTY; anchors unchanged this run); 2) the remaining #016 piece — Boot/IndicatorLED PATCH flow in a service + UI (transport, If-Match/etag wiring (a), and the SetPoint pre-validation corollary (d) are all in place; the settings-object ETag `9234ac83b9700123cc32` is the only pinable token), then the #022 opening items (task polling/races/NMI/error-dedupe/BMC-id fallback — untouched so far); 3) P1 #015 AuthManager — wire `Session.expiryFromService` into login, re-auth on `isExpired`, token/location from create RESPONSE HEADERS only; keep pushing every run (0 queued after this run).

## 2026-10-25 18:0x UTC — PUSH RECORD (success)

- `git push origin main` **succeeded**: `011aac3..693ee2b main -> main` — the
  EMULATOR auto commit (693ee2b) pushed. `git rev-list --count origin/main..HEAD`
  = 0 (fully synced), working tree clean. Queued local commits ahead of
  origin/main: **0**.

## 2026-10-25 18:42 UTC — DOCS (anchor re-verify, no corpus refresh) + UI-2 focus-order pin

- **Baseline:** analyze 0; tests 390 passed / 1 skipped; starting commit 693ee2b (origin/main fully synced, 0 queued local commits); issues validate OK; working tree clean; no stash, no crashed-run leftovers.
- **Primary work:** DOCS per alternation (last primary: EMULATOR 17:50 — DOCS is due; the runbook alternation starts with DOCS on a green baseline and the corpus mirror queue is EMPTY). **Re-verified all four upstream anchors live this run — no corpus refresh:** (1) bmcweb `63a18f4` still HEAD of `master` (`git ls-remote`); (2) mockup `23d21f9a` still HEAD of `main` (`git ls-remote`); (3) DSP0266 1.25.0 PDF from `www.dmtf.org` **byte-identical** SHA-256 `385ee6d0…` vs the mirrored `redfish/spec/DSP0266_1.25.0.pdf`; (4) DMTF schema index from `redfish.dmtf.org/schemas/v1/` **byte-identical** SHA-256 `e5a29797…` (3,448,133 B) vs the mirrored `v1-index.html` (the first fetch attempt timed out at 120 s after 2.0 MB; retried with a 280 s timeout on the same URL — completed and verified) → DOCS-27's ZERO version advances still hold, the corpus mirror queue stays EMPTY for every published type, 0 bytes downloaded this run.
- **Docs:** no corpus files added. REQUIREMENTS.md "Last audited" header now records this run (anchor re-verification + the UI-2 focus-order pin; previous EMULATOR entry demoted to Prior); the manifest README "Current upstream anchors" section + the four anchor bullets updated with the 18:42 UTC verification (the section had last been recorded at 08:06 UTC). No REQUIREMENTS.md trace-row change — the audit surfaced no code gap this run (all trace rows cited during previous DOCS runs remain current).
- **Emulator:** none this run (no emulator code touched; the next EMULATOR slot re-runs the 80/80 suite cheaply).
- **Code/tests:** no production behaviour change beyond the UI increment below; no issues touched.
- **UI:** one small tested UI-2 increment — **the Add-system dialog focus entry + keyboard Tab order, pinned**. `SystemProfileForm` gained `autofocusFirstField` (default false; the `AddSystemDialog` sets it): when the dialog opens, keyboard focus lands on the first field so a keyboard/screen-reader user starts typing immediately (WAI-ARIA dialog pattern — focus moves into the dialog). The edit page leaves the flag off so it does not scroll on load (`EditSystemPage` behaviour unchanged; the two direct-form tests that had relied on the button staying put after `ensureVisible` are unaffected). Two widget tests added to `test/features/systems/ui_widget_test.dart` in a new "Focus order (UI-2)" group: (1) opening the real dialog through `showAddSystemDialog` asserts primary focus is on the "Display name (optional)" field and NOT on "Host / IP"; (2) pumping the form with `autofocusFirstField: true` walks Tab through every focusable in visual order — Name → Host → Port → Use TLS switch → auth-method dropdown → Username → Password → Remember password switch → Allow self-signed switch → Add system button — asserting each step via `EditableText.focusNode.hasFocus` (text fields) and an ancestor-walk focus check (`_focusInside`, switches/dropdown/button). New helpers: `_fieldFocused`, `_focusInside`, `_pressTab`. No new dependencies, no layout change (responsive 320/800/1300 tests unaffected); systems widget file 31→32 tests.
- **Verification:** analyze 0; tests **392 passed / 1 skipped**; issues validate OK; `git diff --check` clean; secret scan: Dart code + docs prose only, no credentials (SHA-256s are file hashes); `git diff --stat` 8 files (2 lib views + 1 test + 2 doc files + tracking/queue).
- **Commit:** (pending) `auto: DOCS — anchors re-verified live (no corpus refresh; mirror queue EMPTY; bmcweb 63a18f4, mockup 23d21f9a, DSP0266 1.25.0, schema index byte-identical) + UI-2 focus-order pin (autofocusFirstField + Tab-order tests, systems 31→32) (run 2026-10-25 18:42)`.
- **Next:** 1) EMULATOR per alternation — cheap 80/80 suite re-run and/or continue the #022/#016 control-surface work (Boot/IndicatorLED PATCH flow in a service + UI is the last #016 piece; then the #022 opening items: task polling/races, NMI terminal state, error dedupe, BMC-id fallback); 2) P1 #015 AuthManager — wire `Session.expiryFromService` into login, re-auth on `isExpired`, token/location from create RESPONSE HEADERS only; 3) UI-2 continues with the remaining dialogs/tables focus audit + any remaining non-card labels; keep pushing every run (0 queued after this run).

## 2026-10-25 18:4x UTC — PUSH RECORD (success)

- `git push origin main` **succeeded**: `05e59e8..a3a0878 main -> main` — the
  DOCS auto commit (a3a0878) pushed. `git rev-list --count origin/main..HEAD`
  = 0 (fully synced), working tree clean. Queued local commits ahead of
  origin/main: **0**.
