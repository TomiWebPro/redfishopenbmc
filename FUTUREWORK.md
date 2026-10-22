# FUTUREWORK

Living queue for the **`redfish-automation`** job (every 5 hours).

> Read this file first. Pick **one primary workstream** per run, finish it, verify
> it, then update this file. Detailed acceptance criteria live in `issues/open/`;
> reference the issue ID instead of duplicating it. New gaps discovered from
> official docs go here with a source URL.

- **Last updated:** 2026-10-23 (EMULATOR run — emulator suite 24 tests: pins
  `ProtocolFeaturesSupported` (#018), AccountService/Accounts (#015/#026),
  UpdateService push apply-time modes (#008/#020); `UpdateServiceInfo` now
  parses `HttpPushUriOptions` apply-time; UI-2 firmware card semantics label)
- **Current focus:** DOCS-2 schema refresh done (ComputerSystem/Chassis v1_29_0,
  Sensor v1_14_0, AccountService v1_19_0, EthernetInterface v1_12_6,
  SoftwareInventory v1_15_0); UI-3 fully done (all views covered);
  emulator at 24 tests (session lifecycle #015/#017, SessionTimeout,
  TaskService, EventService, ProtocolFeaturesSupported #018, Accounts #015/#026,
  push apply-time #008/#020); **UI-1 done** (dashboard error summary + Retry;
  firmware error+retry from 20:51 run); next P1: #015 (AuthManager) — emulator
  now pins the full session contract + the AccountService surface; #016/#022
  (ActionInfo/etag) or #008/#020 (HTTP-push firmware, Tasks URI + push
  apply-time modes) both have emulator assertions
- **Run cadence:** `0 */5 * * *`
- **Model:** `opencode/deepseek-v4.1-flash-free`
- **Status keys:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked

## Selection rules

1. **P0 first.** If `flutter analyze` or `flutter test` is red, repair that before
   any new work. Never start a feature on a red baseline.
2. **Then alternate DOCS and EMULATOR** when the baseline is green. Use the most
   recent `automation-tracking.md` entries to pick whichever has gone longest
   without a run.
3. **Then confirmed P1 defects** (`#014`, `#015`, `#027`), then P2/P3 issues.
4. **Every green run should land one small UI/test improvement** when the primary
   workstream leaves time. If not, say why in the tracking entry.
5. One primary workstream per run. Prefer a finished, tested increment over a
   broad half-finished refactor.

## P0 — keep `main` green

- [ ] Keep `flutter analyze` at **0 issues** and the full `flutter test` suite green.
- [ ] Keep `python3 issues/issues.py validate` green whenever `issues/` changes.
- [ ] Never leave the working tree dirty at the end of a run: commit intended work
      or stash it with a clear label; never discard user work.
- [ ] Never force-push, rewrite history, print credentials, or commit secrets.
- [ ] If a change cannot be made green, revert only that change and record why.

## P1 — official docs and compliance

- [x] **DOCS-1** Establish `documentations/external/` as the official-docs mirror:
      DMTF Redfish spec, schema index, mockup, and OpenBMC bmcweb docs. Add a
      manifest with URL, fetch time, SHA-256, size, and license/notes.
      Start at `https://redfish.dmtf.org/`, `https://redfish.dmtf.org/schemas/v1/`,
      `https://github.com/DMTF/Redfish-Mockup-Server`, and
      `https://github.com/openbmc/bmcweb/tree/master/docs`.
      (run 2026-10-22, commit c8dc7e1 — mirror + manifest + REQUIREMENTS.md live;
      re-fetch on upstream change only; DOCS-8 23:55 run re-verified pins, moved
      bmcweb to `27e0930b`, added CLIENTS.md)
- [x] **DOCS-2** Refresh the DMTF schema/mockup snapshot used by
      `documentations/redfish_reference/` and `test/fixtures/redfish/`; verify the
      provenance section in `documentations/redfish_reference/README.md` is current.
      (run 2026-10-22 — 6 versioned DMTF schemas refreshed to current upstream:
      ComputerSystem/Chassis v1_29_0, Sensor v1_14_0, AccountService v1_19_0,
      EthernetInterface v1_12_6, SoftwareInventory v1_15_0; superseded files kept;
      mockup payload still matches pinned upstream `23d21f9a`, no refresh needed;
      provenance updated in both READMEs + REQUIREMENTS.md DOCS-2 section)
- [x] **DOCS-3** Audit the latest Redfish specification (DSP0266, currently linked
      from `https://redfish.dmtf.org/`) against the client's discovery, auth,
      error, PATCH/ETag, task, and subscription behaviour. Record gaps with
      section numbers and source URLs.
      (run 2026-10-22 — audit complete against DSP0266 1.25.0; corrected the
      Eventing citation to §12.1 and Tasks to §12.2 "Asynchronous operations" in
      REQUIREMENTS.md; added task-monitor polling + event-subscription + SSE +
      bmcweb vendor rows; remaining gaps are code issues #016/#008/#020/#022 + the
      DOCS-7 events decision; DOCS-8 23:55 run re-verified 1.25.0 is still the
      latest published PDF)
- [x] **DOCS-4** Audit OpenBMC bmcweb's `docs/Redfish.md`,
      `docs/REDFISH_CHECKLIST.md`, and `docs/OEM_SCHEMAS.md`; document where our
      feature detection differs from bmcweb's actual behaviour.
      (run 2026-10-22 — full feature-detection diff audit complete: KVM Oem
      false-positive fixed in `FeatureRules` + `KvmConsole.fromManager`;
      bmcweb firmware update is HTTP-push not SimpleUpdate (→ #008/#020);
      ResetActionInfo vs SupportedResetTypes (→ #022/#016); SerialConsole lives
      on ComputerSystem not Manager (→ #009/#021); AuthMethods + TelemetryService
      vendor rows recorded. Cited `Redfish.md`/`OEM_SCHEMAS.md` @ `0128851e`.
      REDFISH_CHECKLIST.md is contributor-process only — no client-facing fields)
- [x] **DOCS-5** Map every `SystemFeatures` flag to a spec citation and a test.
      Add a table under `documentations/redfish_reference/` or
      `documentations/external/redfish/REQUIREMENTS.md`.
      (run 2026-10-22 — full per-flag table added under REQUIREMENTS.md
      "DOCS-5 — SystemFeatures flag → spec citation → test map" for all 10
      flags; surfaced + fixed the `firmwareUpdate` `ServiceEnabled` gap)
- [ ] **DOCS-6** Keep the downloaded corpus bounded: max 25 MB per file and 50 MB
      of new downloads per run. For larger artifacts store the URL + hash +
      extracted notes instead of the binary.
- [x] **DOCS-7** Event subscription support: client has no EventService /
      Subscriptions implementation yet; DSP0266 §12.1 "Eventing" +
      `EventService.json` are mirrored. **Decision (2026-10-22): out-of-scope
      this milestone** — no event consumer (telemetry/firmware tasks are
      poll-based), no SSE transport in `pubspec.yaml`, no test bed that can push
      events. Rationale + spec citations recorded in REQUIREMENTS.md
      "DOCS-7 decision". Revisit when telemetry (#007/#019) or task monitoring
      (#008/#020/#022) lands.

## P1 — emulator and integration tests

- [x] **EMU-1** Stand up the official DMTF Redfish-Mockup-Server over HTTPS using
      `test/fixtures/redfish/dmtf_mockup` (public-rackmount1) and a generated
      self-signed cert. Health-check `GET /redfish/v1/` before tests.
      (run 2026-10-22, commit 81dfb8f — pin `23d21f9a`, script
      `tool/emulator/run_tests.sh`, port 8443)
- [x] **EMU-2** Add end-to-end tests under `test_integration/emulator/` (outside
      `test/` so plain `flutter test` never needs the emulator). Cover discovery,
      service-root traversal, systems, sensors, firmware inventory, and KVM
      capability detection.
      (run 2026-10-22, commit 81dfb8f — 11 tests in
      `test_integration/emulator/emulator_suite_test.dart`; skips without
      `REDFISH_EMULATOR_URL`; extended 2026-10-22 → 13 tests (systems detail +
      HttpPushUri) → 16 tests (SessionService URI, Manager detail + allow-list,
      Chassis detail) → 21 tests (session lifecycle #015/#017, SessionTimeout,
      TaskService, EventService contracts) → 24 tests (ProtocolFeaturesSupported
      #018, Accounts #015/#026, push apply-time #008/#020 — 2026-10-23))
- [~] **EMU-3** Cover auth and power actions where the emulator supports them.
      If an action is unsupported, assert the client's error mapping instead of
      skipping silently.
      (session + basic auth, reset action, 404 mapping done 2026-10-22;
      systems-detail + HttpPushUri tests added 2026-10-22 → 13 emulator tests;
      session lifecycle + logout-target (DELETE session 204 / collection 405) +
      SessionTimeout added 2026-10-22 → 21 tests;
      remaining: 403/409/400 extended info paths need a richer emulator — see
      EMU-5: decision is to keep covering error mapping with spec-conformant
      unit fixtures, so EMU-3 is effectively complete)
- [x] **EMU-4** Add `tool/emulator/run_tests.sh` that starts the server, waits for
      health, runs the integration tests, and always stops the server via `trap`.
      Pin the emulator commit and document it.
      (run 2026-10-22, commit 81dfb8f — verified end-to-end; trap cleanup
      confirmed; pin `23d21f9a` in the script + docs README)
- [x] **EMU-5** Evaluate `DMTF/Redfish-Interface-Emulator` only if the mockup
      server cannot exercise the required dynamic actions. Record the decision.
      (run 2026-10-22 — evaluated `5f51d8a`; **decision: stay on
      Redfish-Mockup-Server**. The richer emulator serves dynamic 400s but its
      error bodies are non-conformant — `{"error":"msg"}` with no `error`
      envelope / `@Message.ExtendedInfo`, and its SessionService 404s. Error
      mapping is covered with spec-conformant unit fixtures instead; rationale
      in REQUIREMENTS.md "EMU-5 decision")
- [x] **EMU-6** Do not loosen production TLS. Use `allowSelfSigned: true` only in
      the test profile; never add an HTTP/plaintext production path.
      (run 2026-10-22 — self-signed cert is `/tmp`-generated test-only;
      `allowSelfSigned` used only in `test_integration/emulator/` profile)

## P1 — confirmed code defects

- [x] **#014** Fix `RedfishError` `@Message.ExtendedInfo` parsing.
      (run 2026-10-22 — `fromJson` self-descends into the DSP0266 `error`
      envelope; `fromResponse` normalizes map bodies; compliant-envelope unit
      tests in `models_test.dart` + `auth_manager_test.dart`; closed)
- [ ] **#015** AuthManager: auth method, safe logout URI, session reuse/expiry.
      (bmcweb `AccountService.Oem.OpenBMC.AuthMethods.*` vendor row recorded in
      REQUIREMENTS.md — DOCS-4; emulator asserts the service root advertises a
      discoverable SessionService URI — run 2026-10-22 #017 contract; emulator
      now also pins the full session lifecycle: POST via discovered Sessions
      URI returns X-Auth-Token + Location (session resource, not collection),
      DELETE session 204 vs DELETE collection 405, SessionTimeout=30 published —
      run 2026-10-22; emulator AccountService test added 2026-10-23: Accounts
      collection discoverable + readable with UserName/RoleId, MinPasswordLength
      published — the auth-surface contract #015/#026 reason about)
- [x] **#027** Verify the Flutter toolchain issue is stale; close it with evidence
      if `flutter analyze`/`flutter test` work, otherwise fix it.
      (run 2026-10-22 — closed with evidence: `~/flutter/bin/flutter` on PATH,
      analyze 0 / tests 242 green every run, no orphaned flutter_tester from
      this repo; DEVELOPMENT.md Toolchain documents the setup)
- [ ] **#016** PATCH / `If-Match` / `@odata.etag` support.
      (bmcweb ResetActionInfo → supportedResetTypes fallback also folds here —
      DOCS-4; emulator notes: the DMTF mockup serves no `@odata.etag` on
      resources — etag behaviour cannot be pinned on this fixture, keep it in
      unit tests — 2026-10-23)
- [ ] **#017** Discover the SessionService URI instead of assuming it.
      (emulator test asserts `SessionService.@odata.id` is discoverable from the
      service root and serves a conformant SessionService — run 2026-10-22)
- [ ] **#018** Fix discovery-cache stale replay/leak.
      (emulator test added 2026-10-23: service root `ProtocolFeaturesSupported`
      advertises `ExcerptQuery` + `ExpandQuery{ExpandAll,Levels}` and publishes
      `FilterQuery`/`SelectQuery` — the query-capability surface a lightweight
      discovery pass must use; the client currently ignores it)
- [ ] **#022** Power: task polling, races, and error fixes.
      (bmcweb `ResetActionInfo` ActionInfo `Parameters/AllowableValues` is the
      allow-list source on OpenBMC; add fallback — DOCS-4. Emulator asserts the
      DMTF mockup's `#Manager.Reset` carries its own
      `ResetType@Redfish.AllowableValues` — the fallback must not conflate
      manager- vs system-level Reset actions — run 2026-10-22)
- [ ] **#024** `profile_repository.clear()` orphaned passwords.
- [ ] **#026** Resolve duplicate auth fields.

## P2 — feature completeness

- [ ] **#006** System overview adaptive cards.
- [ ] **#007 / #019** Sensor monitoring, real-time telemetry, retry.
- [ ] **Events** Event subscription + SSE client — DOCS-7 decided out-of-scope this
      milestone (see P1 docs section); revisit when telemetry (#007/#019) or task
      monitoring (#008/#020/#022) creates a receiver. Spec: DSP0266 §12.1,
      bmcweb field set audited in REQUIREMENTS.md "bmcweb field notes".
- [ ] **#008 / #020** Firmware update management, upload progress, task timeline.
      (bmcweb: update is HTTP-push via `HttpPushUri`/`MultipartHttpPushUri`, no
      `SimpleUpdate` — our `startSimpleUpdate` would 405 on OpenBMC; add push
      path — DOCS-4, REQUIREMENTS.md; emulator asserts `UpdateServiceInfo.
      httpPushUri == '/FWUpdate'` on the DMTF mockup — run 2026-10-22; emulator
      test added 2026-10-23: `HttpPushUriOptions.HttpPushUriApplyTime` publishes
      `ApplyTime == 'Immediate'` + AllowableValues (Immediate/OnReset/
      AtMaintenanceWindowStart/InMaintenanceWindowOnReset) + MaintenanceWindow
      start time; `UpdateServiceInfo` now parses both — the push-upload flow
      must offer apply-time selection instead of assuming Immediate)
- [ ] **#009 / #021** Remote KVM capability detection and console rendering.
- [ ] **#010** Hardening: secure storage, theming, accessibility, coverage.

## P2 — UI improvements (one small, tested increment per green run)

- [x] **UI-1** Empty / loading / error states for dashboard, sensors, firmware, KVM.
      (FirmwareView error state upgraded to an errorContainer card with a
      working Retry action — done 2026-10-22; KVM/Sensors/Overview views already
      covered; **dashboard error summary + one-tap Retry via
      `SystemManager.retryFailed()` done 2026-10-22 (DOCS-8 run, commit
      b9dcd31)** — all views covered, **UI-1 done**)
- [ ] **UI-2** Accessibility: semantics labels, contrast, touch targets, focus order.
      (Health/Power badges semantic labels done 2026-10-22 — commit c8dc7e1;
      destructive power dialog label done 2026-10-22 — commit 81dfb8f; firmware
      inventory cards merged a11y label done 2026-10-23 — Semantics container
      with concise summary (component, version, health, updateable/locked) +
      widget test; extend to remaining cards, dialogs, tables)
- [ ] **UI-3** Responsive layout: no overflow at 320 / 800 / 1300 px widths; add
      widget tests for each breakpoint.
      (PowerView no-overflow tests added 2026-10-22; SensorsView no-overflow
      tests added 2026-10-22; FirmwareView no-overflow tests added 2026-10-22;
      KvmView no-overflow tests added 2026-10-22; DashboardView + OverviewView
      no-overflow tests added 2026-10-22 — fixes: DashboardView 1-col grid
      aspect ratio 1.25, OverviewView 1-col natural-height card stack) —
      **all views covered, UI-3 done**
- [ ] **UI-4** Visual consistency for cards, badges, health/power colors, spacing.
- [ ] **UI-5** Power confirmation dialog: clearer destructive-action copy and
      disabled/busy states.
      (destructive copy + a11y label done 2026-10-22 — commit 81dfb8f; reset
      buttons announce the in-flight state + disable while busy — done
      2026-10-22; dialog confirm button busy state (spinner + disabled, Cancel
      disabled, barrier non-dismissible while in flight, busy semantics)
      completed 2026-10-22 — 2 new widget tests) — **UI-5 done**
- [ ] **UI-6** Sensor table: sorting/filtering, threshold highlighting, stale data.
- [ ] **UI-7** Firmware upload: progress, cancel, task status timeline.
- [ ] **UI-8** KVM: launch/placeholder UX when the console is unsupported.
- [ ] **UI-9** Dashboard: multi-system aggregation, offline/error summaries.
- [ ] **UI-10** Consider stable golden/screenshot smoke tests once layouts settle.

## P2 — refactor and quality

- [ ] **#011** Relocate `ConnectionProfile` to `core`.
- [ ] **#012** Consolidate DI providers.
- [ ] **#013** Remove dead `app_breakpoints.dart`.
- [ ] **#023** Overview: `listenManual` leak and async errors.
- [ ] **#025** Harden unsafe `.first` / `as` casts.
- [ ] Keep coverage **≥ 80%** for every feature touched by a run.
- [ ] Run `dart format` on Dart sources; keep `flutter analyze` at zero.
- [ ] Remove generated/build artifacts from git; keep `.gitignore` current.

## Blocked / needs a human

- [!] **Live BMC integration** — requires real credentials/network; never attempt
      in the unattended job. Keep the live-BMC test skipped.
- [!] **KVM webview/native console** — may require a platform plugin and manual
      device validation; document the decision before adding dependencies.
- [!] **Large spec/binary assets** — if over the download budget, ask a human
      before committing; store links and hashes meanwhile.

---

## Run history pointers

- `automation-tracking.md` — one section per automation run.
- `progress/journal.md` — project daily journal (append-only).
- `progress/progress_summary.md` — weekly rollup.
- `issues/issues.py list --all` — detailed issue queue.
