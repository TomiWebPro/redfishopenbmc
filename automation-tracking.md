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
- **Commit:** <PENDING> — `auto: DOCS — reset allow-list annotation fallback (FeatureRules.supportedResetTypes unions SupportedResetTypes + ResetType@Redfish.AllowableValues, manager-list conflation guard), UI-2 dialog 48px touch targets (run 2026-10-23 16:05)`; pushed: see §7.4 outcome (GitHub credential blocker historically: `fatal: could not read Username for 'https://github.com'`).
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
