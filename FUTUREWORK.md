# FUTUREWORK

Living queue for the **`redfish-automation`** job (every 5 hours).

> Read this file first. Pick **one primary workstream** per run, finish it, verify
> it, then update this file. Detailed acceptance criteria live in `issues/open/`;
> reference the issue ID instead of duplicating it. New gaps discovered from
> official docs go here with a source URL.

- **Last updated:** 2026-10-23 18:36 (EMULATOR run — **EMU-2 at 39 tests:
  query-behavior contract pinned for #018** — `$expand=*` (ExpandAll) also
  serves inlined full member bodies, while `$filter`/`$select` are
  **advertised but NOT applied** by the pinned mockup (Roles collection
  unfiltered for `$filter=Id eq 'NOPE'`, full system body for `$select=Model`)
  → the #018 lightweight discovery pass must filter/select client-side and
  rely only on `$expand` for payload shaping; 401 bad-login error mapping
  probed and recorded as unit-only (mockup without `-u` accepts any
  credentials, 204 — consistent with EMU-5); **UI-2 increment: KvmView view
  header (title + subtitle) now one merged semantics node** + 1 widget test;
  suite 300 → 301 tests)
- **Current focus:** EMU-2 suite at **39 tests** — **query-behavior contract
  pinned 18:36: `$expand=*` inlines full bodies, `$filter`/`$select` advertised
  but NOT applied (client-side only)**; DOCS-14 done (OData base vocabulary
  mirror + anchor re-verification); next P1: #015 (AuthManager) — emulator
  pins the full auth
  contract + the Session/ManagerAccount/Role schemas are mirrored
  (#015/#017/#026); #022/#016: Annotation allow-list fallback landed (16:05
  run) — remaining: `ResetActionInfo` ActionInfo resource crawl (bmcweb-style
  BMCs; NOT pinable on the DMTF mockup — it serves only the annotation form);
  #018: query-capability surface + live `$expand` contract pinned (17:07) —
  remaining: build the lightweight discovery pass + the cache fixes
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
- [x] **DOCS-10** Mirror the official DMTF `Task` schemas (`Task.json`
      aggregator, `Task.v1_7_4.json`, `TaskService.v1_2_1.json` — fetched
      2026-10-23, 32,950 bytes total, inside the DOCS-6 budget) and audit
      DSP0266 §12.2 "Asynchronous operations" against the client's async
      handling; fold the optional 202 `Retry-After` into `UpdateTask`.
      (run 2026-10-23 — manifest rows + audit table in REQUIREMENTS.md
      "DOCS-10"; `FirmwareService.startSimpleUpdate` now returns `UpdateTask`
      with `taskUri` + `retryAfterSeconds`; task *polling* stays #008/#020
      (firmware) + #022 (power))
- [x] **DOCS-11** Mirror the missing DMTF `LogEntry` schema corpus
      (`LogEntry.json` aggregator, `LogEntry.v1_22_0.json` newest, plus
      `LogEntry.v1_16_0.json` — the version the pinned mockup serves — and
      `LogEntryCollection.json`), and add the newest `LogService.v1_9_0.json`
      (external corpus only had the aggregator).
      (run 2026-10-23 — 171,095 bytes total, inside the DOCS-6 budget;
      manifest rows + SHA-256s verified; also mirrored LogEntry
      aggregator/v1_16_0/collection into `test/fixtures/redfish/schemas/`;
      REQUIREMENTS.md log row source cites now resolve to real mirror files;
      upstream anchors re-verified: bmcweb `27e0930b`, mockup `23d21f9a`,
      DSP0266 1.25.0, schema index current — no version advanced for the
      other tracked families)
- [x] **DOCS-12** Mirror the missing **versioned** definitions for the six
      aggregator-only families the client maps — `UpdateService`,
      `EventService`, `SessionService`, `Manager`, `Power`, `Thermal` — newest
      versioned file (what each aggregator `$ref`s) **plus** the version the
      pinned DMTF mockup serves (`UpdateService.v1_13_0`,
      `EventService.v1_10_1`, `SessionService.v1_1_8`, `Manager.v1_19_0`,
      `Power.v1_7_2`, `Thermal.v1_7_2`), the DOCS-11 LogEntry precedent.
      (run 2026-10-23 — 12 files, 553,772 bytes total, inside the DOCS-6
      budget; manifest rows + SHA-256s verified; the six mockup-served versions
      also copied into `test/fixtures/redfish/schemas/` so every `@odata.type`
      the mockup publishes has a versioned schema in the fixture; the six
      newest versions were already in the fixture and verified byte-identical
      to upstream; REQUIREMENTS.md rows + trace note now cite the real mirror
      files; audited deltas — `SessionService.v1_2_0` adds
      `AbsoluteSessionTimeout*` (note for #015), `UpdateService.v1_17_1` adds
      `LocalImageStore*`/`Stage`/`Activate` (note for #008/#020), `Manager
      v1_25_0` adds `SecurityMode`/`ReadyToRemove`, Power/Thermal no deltas —
      no client code change this run)
- [x] **DOCS-13** Mirror the versioned definitions for the six remaining
      client-relevant resources the pinned mockup serves / the emulator pins but
      the external corpus had no versioned defs for: `Session`
      (`v1_9_0` newest + `v1_7_1` mockup-served — auth surface #015/#017/#026),
      `ManagerAccount` (`v1_14_2` + `v1_12_0`), `Role` (`v1_3_3` + `v1_3_1`),
      `ManagerNetworkProtocol` (`v1_14_0` + `v1_10_0` — KVMIP/HTTPS/SSH console
      endpoints for #009/#021), `ActionInfo` (`v1_6_0` + `v1_4_1` — bmcweb
      `ResetActionInfo` allow-list source for #022/#016), `ServiceRoot`
      (`v1_22_0` + `v1_16_1` — discovery contract for #018), plus the
      mockup-served `Task.v1_7_3`/`TaskService.v1_2_0` (DOCS-10 had mirrored
      only the newest). (run 2026-10-23 — 19 files, 397,572 bytes total,
      inside the DOCS-6 budget; manifest rows + SHA-256s verified; the eight
      mockup-served versions also copied into `test/fixtures/redfish/schemas/`
      so every `@odata.type` the mockup publishes for these families has a
      versioned schema in the fixture; REQUIREMENTS.md DOCS-13 audit table +
      Trace-notes count 16 → 21; audited newest-vs-served deltas — no client
      code change needed; upstream anchors re-verified: bmcweb `27e0930b`,
      mockup `23d21f9a`, DSP0266 1.25.0, schema index 200 OK)

- [x] **DOCS-14** Mirror the OData base vocabulary (`odata.4.0.0.json` —
      the canonical lowercase file; bare `Odata.json` 404s upstream) so the
      last un-mirrored REQUIREMENTS.md source citation (row 65,
      `@odata.id` link traversal) resolves to a real mirror file; byte-verify
      against `test/fixtures/redfish/schemas/Odata.json`; re-verify all corpus
      anchors (bmcweb HEAD, mockup pin, DSP0266 version, schema index).
      (run 2026-10-23 — 1,834 bytes, inside the DOCS-6 budget; byte-identical
      to the fixture copy (fixture proven current); bmcweb advanced
      `27e0930b` → `fbb307a` with all four mirrored docs byte-identical (no
      refresh needed, anchors updated); mockup still `23d21f9a`; DSP0266 still
      1.25.0; schema index 200 OK; manifest row + REQUIREMENTS.md DOCS-14
      audit section added)

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
      #018, Accounts #015/#026, push apply-time #008/#020 — 2026-10-23) → 27
      tests (Sensors collection #007/#019, system Reset allow-list #022/#016,
      SimpleUpdateActionInfo #008/#020 — 2026-10-23 03:02) → **30 tests
      (OverviewService end-to-end hydration #006 + LogService/LogEntry
      collection contract incl. ClearLog + `@odata.nextLink` pagination —
      2026-10-23 06:10) → 32 tests (Task resource contract: TaskState/
      TaskStatus/Start-EndTime/Messages incl. absent PercentComplete, + TaskService
      CompletedTaskOverWritePolicy/LifeCycle fields — 2026-10-23 09:14) → **34
      tests (Manager NetworkProtocol + EthernetInterfaces surface: KVMIP/SSH/
      HTTPS endpoints for the #009/#021 console renderer + NIC MAC/IP/VLAN —
      2026-10-23 11:39) → **36 tests (account-service auth surface #015/#026:
      AccountService lockout/password-policy + Roles link, Roles collection +
      AssignedPrivileges/OemPrivileges, ManagerAccount detail incl.
      AccountTypes/PasswordChangeRequired/Locked/Links.Role/ChangePassword +
      Password masked on the wire — 2026-10-23 13:58) → **37 tests (live
      `$expand=.($levels=1)` round-trip pin: Systems collection inlines full
      member bodies — Model/PowerState/Actions.Reset allow-list incl. Nmi +
      Processor/MemorySummary — the N+1-avoiding discovery shape #018 can
      rely on — 2026-10-23 17:07** → **39 tests (query-behavior contract
      pinned 2026-10-23 18:36: `$expand=*` (ExpandAll) also serves inlined
      full member bodies — same fields as `$levels=1` — while `$filter`/
      `$select` are advertised but NOT applied (Roles collection unfiltered
      for `$filter=Id eq 'NOPE'`, full system body for `$select=Model`) — the
      #018 discovery pass must filter/select client-side and rely only on
      `$expand` for payload shaping)**)
- [~] **EMU-3** Cover auth and power actions where the emulator supports them.
      If an action is unsupported, assert the client's error mapping instead of
      skipping silently.
      (session + basic auth, reset action, 404 mapping done 2026-10-22;
      systems-detail + HttpPushUri tests added 2026-10-22 → 13 emulator tests;
      session lifecycle + logout-target (DELETE session 204 / collection 405) +
      SessionTimeout added 2026-10-22 → 21 tests;
      system-level Reset allow-list (incl. `Nmi`, distinct from the manager
      list) added 2026-10-23 → 27 tests;
      remaining: 403/409/400 extended info paths need a richer emulator — see
      EMU-5: decision is to keep covering error mapping with spec-conformant
      unit fixtures, so EMU-3 is effectively complete; **probed 2026-10-23
      18:36: the mockup without `-u` accepts ANY credentials — `POST Sessions`
      with a wrong password returns 204, so the 401 bad-login error-mapping
      path also stays unit-level (consistent with EMU-5)**)
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
      published — the auth-surface contract #015/#026 reason about; **full
      account-service auth surface pinned 2026-10-23 13:58**: AccountService
      lockout/password-policy fields + Roles link, Roles collection (3
      predefined roles with AssignedPrivileges/OemPrivileges), ManagerAccount
      detail (AccountTypes/PasswordChangeRequired/Locked/Enabled/Links.Role/
      ChangePassword target + Password masked on the wire))
- [x] **#027** Verify the Flutter toolchain issue is stale; close it with evidence
      if `flutter analyze`/`flutter test` work, otherwise fix it.
      (run 2026-10-22 — closed with evidence: `~/flutter/bin/flutter` on PATH,
      analyze 0 / tests 242 green every run, no orphaned flutter_tester from
      this repo; DEVELOPMENT.md Toolchain documents the setup)
- [ ] **#016** PATCH / `If-Match` / `@odata.etag` support.
      (bmcweb ResetActionInfo → supportedResetTypes fallback also folds here —
      DOCS-4; **annotation-form allow-list fallback landed 2026-10-23 16:05** —
      `supportedResetTypes` now unions `SupportedResetTypes` +
      `ResetType@Redfish.AllowableValues` on `#ComputerSystem.Reset` (the
      bmcweb/mockup shape), conflation-guarded; remaining: crawl the
      `ResetActionInfo` ActionInfo *resource*. Emulator notes: the DMTF mockup
      serves no `@odata.etag` on resources — etag behaviour cannot be pinned on
      this fixture, keep it in unit tests — 2026-10-23; the system-level
      `#ComputerSystem.Reset` `ResetType@Redfish.AllowableValues`
      (On/ForceOff/GracefulShutdown/GracefulRestart/ForceRestart/Nmi/ForceOn/
      PushPowerButton) is pinned — the allow-list fallback must read the system
      list, never the manager list — 2026-10-23 03:02)
- [ ] **#017** Discover the SessionService URI instead of assuming it.
      (emulator test asserts `SessionService.@odata.id` is discoverable from the
      service root and serves a conformant SessionService — run 2026-10-22)
- [ ] **#018** Fix discovery-cache stale replay/leak.
      (emulator test added 2026-10-23: service root `ProtocolFeaturesSupported`
      advertises `ExcerptQuery` + `ExpandQuery{ExpandAll,Levels}` and publishes
      `FilterQuery`/`SelectQuery` — the query-capability surface a lightweight
      discovery pass must use; the client currently ignores it; **live
      `$expand` round-trip pin added 2026-10-23 17:07** —
      `$expand=.($levels=1)` on the Systems collection inlines full member
      bodies (Model/PowerState/Actions.Reset allow-list incl. Nmi +
      Processor/MemorySummary) in one round trip — the N+1-avoiding discovery
      shape the #018 pass can build on; **query-behavior contract pinned
      2026-10-23 18:36**: `$expand=*` (ExpandAll) serves the same inlined
      bodies, but `$filter`/`$select` are **advertised but NOT applied** by
      the pinned mockup (Roles collection unfiltered for `$filter=Id eq
      'NOPE'`, full system body for `$select=Model`) — the pass must filter/
      select client-side and rely only on `$expand` for payload shaping)
- [ ] **#022** Power: task polling, races, and error fixes.
      (bmcweb `ResetActionInfo` ActionInfo `Parameters/AllowableValues` is the
      allow-list source on OpenBMC; add fallback — DOCS-4. **Annotation-form
      fallback landed 2026-10-23 16:05**: `FeatureRules.supportedResetTypes`
      unions `SupportedResetTypes` + the `ResetType@Redfish.AllowableValues`
      annotation on `#ComputerSystem.Reset` (the DMTF mockup / bmcweb-style
      shape), with the manager-list conflation guard — emulator-pinned; the
      remaining piece is crawling the `ResetActionInfo` *resource* itself
      (`Parameters[].AllowableValues`). **Emulator negative finding 2026-10-23
      17:07**: the DMTF mockup fixture ships NO `ResetActionInfo` ActionInfo
      resource for `#ComputerSystem.Reset` — it serves only the annotation
      form (= the 16:05 fallback); the ActionInfo-resource crawl is a
      bmcweb-style (OpenBMC) code task for #022/#016, not pinable on this
      fixture. Emulator asserts the DMTF mockup's
      `#Manager.Reset` carries its own `ResetType@Redfish.AllowableValues` —
      the fallback must not conflate manager- vs system-level Reset actions —
      run 2026-10-22; system-level allow-list pinned incl. `Nmi` (NMI-stabilize)
      + `ForceOn` + `PushPowerButton`, and the mockup does NOT advertise
      `PowerCycle` — the gate must use exactly the advertised values — run
      2026-10-23 03:02)
- [ ] **#024** `profile_repository.clear()` orphaned passwords.
- [ ] **#026** Resolve duplicate auth fields.

## P2 — feature completeness

- [ ] **#006** System overview adaptive cards.
      (emulator now pins the full `OverviewService.fetchOverview()` hydration
      end-to-end — identity, health + rollup, power, processor/memory
      summaries, IndicatorLED, leading chassis thermal 41.0 °C, resourceUri —
      run 2026-10-23 06:10; the remaining work is UI polish: nothing blocks)
- [ ] **#007 / #019** Sensor monitoring, real-time telemetry, retry.
      (emulator pins the 41-member Sensors collection end-to-end — typed
      readings (Cel/V …) + thresholds parse through `SensorsService.fetchAll()`
      — run 2026-10-23 03:02; the real-time poll/EventService receiver still
      needs building)
- [ ] **Events** Event subscription + SSE client — DOCS-7 decided out-of-scope this
      milestone (see P1 docs section); revisit when telemetry (#007/#019) or task
      monitoring (#008/#020/#022) creates a receiver. Spec: DSP0266 §12.1,
      bmcweb field set audited in REQUIREMENTS.md "bmcweb field notes".
- [ ] **#008 / #020** Firmware update management, upload progress, task timeline.
      (bmcweb: update is HTTP-push via `HttpPushUri`/`MultipartHttpPushUri`, no
      `SimpleUpdate` — our `startSimpleUpdate` would 405 on OpenBMC; add push
      path — DOCS-4, REQUIREMENTS.md; emulator asserts `UpdateServiceInfo.
      httpPushUri == '/FWUpdate'` on the DMTF mockup — run 2026-10-22;
      **both push URIs are now surfaced**: `multipartHttpPushUri` added to
      `UpdateServiceInfo` (DOCS-9, run 2026-10-23) — the upload flow must pick
      the right URI (multipart for bmcweb); emulator test added 2026-10-23:
      `HttpPushUriOptions.HttpPushUriApplyTime` publishes
      `ApplyTime == 'Immediate'` + AllowableValues (Immediate/OnReset/
      AtMaintenanceWindowStart/InMaintenanceWindowOnReset) + MaintenanceWindow
      start time; `UpdateServiceInfo` now parses both — the push-upload flow
      must offer apply-time selection instead of assuming Immediate;
      `SimpleUpdateActionInfo` pinned 2026-10-23 03:02: `ImageURI` Required +
      `TransferProtocol` AllowableValues (HTTP/HTTPS/SFTP…) — the parameter
      contract for `startSimpleUpdate` on BMCs that DO expose SimpleUpdate;
      `startSimpleUpdate` now returns an `UpdateTask` handle with the 202
      `Location` task-monitor URI + optional `Retry-After` seconds (DSP0266
      §12.2; `Task.v1_7_4.json` mirrored as DOCS-10); **Task resource contract
      pinned 2026-10-23 09:14**: GET `/TaskService/Tasks/545` returns
      `TaskState Completed`/`TaskStatus OK`/RFC3339 Start-EndTime/`Messages[]`
      and **no `PercentComplete`** (poller must treat it as unknown), and
      TaskService publishes `CompletedTaskOverWritePolicy=Manual` +
      `LifeCycleEventOnTaskStateChange=true` — the poller only lacks
      GET-on-monitor + TaskState parsing)
- [ ] **#009 / #021** Remote KVM capability detection and console rendering.
      (emulator now pins the manager network surface the console renderer
      needs: `Manager.NetworkProtocol.KVMIP` ProtocolEnabled + port 5288, plus
      HTTPS/SSH endpoints, and EthernetInterfaces MAC/IP/VLAN — run
      2026-10-23 11:39; #009 must resolve the console endpoint from the
      advertised KVMIP port, never hardcode ports)
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
      widget test; sensors temperature/fan/generic tiles merged a11y labels
      done 2026-10-23 — Semantics container + excludeSemantics, one concise
      summary per tile (name, value, health) + widget test; chassis card header
      merged summary label (`Chassis 1U, 1 temperatures, 1 fans, 1 sensors`)
      done 2026-10-23 03:02 — Semantics container on the title, tile labels
      preserved + widget test; overview InfoCard header merged semantics label
      (`Identity`/`Processors`/`Memory`/`Temperatures`/`Indicator LED` as one
      node via `Semantics(container: true, excludeSemantics: true, label:
      title)` + widget test) done 2026-10-23 06:10; SystemCard header merged
      semantics label (`<name>, connected|connecting|connection error|
      disconnected`) done 2026-10-23 07:xx — Semantics on the title+status-icon
      row only, PopupMenuButton keeps its own semantics, +widget test across all
      four connection states; KvmConsole card header merged semantics label
      (`<type>, enabled|disabled`) done 2026-10-23 09:14 — Semantics on the
      title+Enabled/Disabled-chip row, widget tests for both states; PowerView
      card header merged semantics label (`<name>, power <state>`) done
      2026-10-23 — Semantics on the title+PowerBadge row, widget test for the
      merged node; OverviewView HealthBanner merged semantics label
      (`Health: <state>`) done 2026-10-23 11:39 — Semantics(container +
      excludeSemantics) wraps the icon+label row, widget test asserts the
      merged node + visible text; FirmwareView header row merged semantics
      label (`Firmware and update management[, loading]`) done 2026-10-23 —
      Semantics wraps the title+in-flight-spinner row, widget tests for both
      the loading and idle states; DashboardView aggregated banner merged
      semantics label (`Health: <summary>`, incl. the "No systems" empty
      state) done 2026-10-23 13:58 — Semantics(container + excludeSemantics)
      wraps the icon+summary row, widget tests assert the merged node +
      visible text; **dialog action buttons explicit 48×48px touch targets done
      2026-10-23 16:05 — `ConfirmResetDialog` Cancel/Confirm get
      `minimumSize: Size(48,48)` + padded tap target, widget test asserts both
      buttons render ≥48px tall; **SystemProfileForm self-signed certificate
      warning banner merged semantics label (`Warning: self-signed
      certificates disable TLS verification. Only enable for trusted, isolated
      management networks.`) done 2026-10-23 17:30 — Semantics(container +
      excludeSemantics) wraps the icon+text row revealed by the "Allow
      self-signed certificate" switch, widget test asserts the merged node +
      visible text — remaining UI-2: focus order, remaining
      non-card labels); extend to
      remaining cards, dialogs, tables)
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
