# FUTUREWORK

Living queue for the **`redfish-automation`** job (every 5 hours).

> Read this file first. Pick **one primary workstream** per run, finish it, verify
> it, then update this file. Detailed acceptance criteria live in `issues/open/`;
> reference the issue ID instead of duplicating it. New gaps discovered from
> official docs go here with a source URL.

- **Last updated:** 2026-10-26 (DOCS run — **anchor re-verify: bmcweb master HEAD advanced `63a18f4` → `c846fb5d` but all four mirrored docs byte-identical, no refresh; mockup `23d21f9a`, DSP0266 1.25.0, schema index byte-identical; mirror queue EMPTY, 0 new downloads**)
- **Current focus:** DOCS anchors current as of 2026-10-26 07:5x UTC. Next per alternation: **EMULATOR** — cheap 85/85 suite re-run, or #008/#020 remaining UI: the **file-picker** integration (desktop/web `file_picker` abstraction + upload wiring into the firmware view), **apply-time selection** widget (the mockup publishes `HttpPushUriOptions.HttpPushUriApplyTime` with Immediate/OnReset/AtMaintenanceWindowStart/InMaintenanceWindowOnReset — `UpdateServiceInfo` already parses both; don't assume Immediate), and the **task-timeline** UI (progress from `PercentComplete` — absent on the fixture, the poller tolerates it). Then P1 #015 (AuthManager) — `expiryFromService` + the Sessions pin are ready, wire the discovered SessionService body into login + re-auth on `isExpired`; then UI-2 — remaining focus audit + any remaining non-card labels
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

- [x] **DOCS-15** Audit DSP0266 §7.3 "Query parameters" (§7.3.1–7.3.5:
      processing order, `$expand` options `*`/`$levels` default 1/`.`/`~` +
      `MaxLevels` + 507 oversized-payload, `$select`, `$filter` built-in
      operators + precedence, `clientcontext` incremental retrieval, 400/501/
      QueryNotSupportedOnResource) against the client's query transport and
      the emulator-pinned query contract; fold the bottom line into #018
      (gate `$expand` on `ProtocolFeaturesSupported`, filter/project
      client-side) and pin the `getJson(path, query:)` forwarding contract
      with a unit test.
      (run 2026-10-23 — REQUIREMENTS.md "DOCS-15" audit table (9 rows) +
      manifest anchors note updated to 19:20 UTC; anchors re-verified:
      bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200;
      +1 transport unit test; no corpus refresh needed — corpus complete for
      all 16 client-mapped families)

- [x] **DOCS-17** Audit the DSP0266 §13.3.4.3 "Session lifetime" clause
      against the client's session expiry handling, using the mirrored
      `SessionService.json` + `SessionService.v1_2_0.json` (DOCS-12); pin the
      timeout contract with unit tests (`SessionTimeout` inactivity TTL;
      `AbsoluteSessionTimeout`/`AbsoluteSessionTimeoutEnabled` added v1_2_0 —
      maximum seconds open regardless of activity, applied only when enabled;
      the effective deadline is the *earlier* of the two so the client
      re-authenticates before the service kills the session).
      (run 2026-10-24 — REQUIREMENTS.md DOCS-17 trace table + the
      session-timeout row corrected from overstated OK to Partial (model-level
      pinned; AuthManager wiring stays #015); `Session.expiryFromService`
      helper + 6 unit tests in `models_test.dart`; no corpus refresh —
      anchors re-verified 01:07 UTC all unchanged: bmcweb `fbb307a`, mockup
      `23d21f9a`, DSP0266 1.25.0, schema index 200; UI-2 increment:
      FirmwareView error state merged semantics label + separate Retry control,
      +1 widget test)

- [x] **DOCS-18** Mirror the DMTF **message-registry payload** the pinned
      mockup serves (`Base.1.5.0.json` — the file behind
      `MessageRegistryFile.Location[0].Uri`, pinned live by the EMU-2
      MessageRegistry contract 2026-10-24: 60 Base.* templates with
      Message/Severity/NumberOfArgs behind `RedfishError.code`/`firstMessage`)
      so the §8.6 error-response / §11.4 message-registry rows in
      REQUIREMENTS.md cite a real mirror file. Registry JSONs live on the DMTF
      registries path (verify with `curl -sSIL`; the `redfish/schemas/v1/`
      index carries only the `MessageRegistry.json` aggregator + versions —
      the payloads are separate). Keep inside the DOCS-6 budget (Base registry
      is ~50 KB). Also consider the newest `Base.*` published version for the
      "newest vs mockup-served" delta note. Source:
      <https://redfish.dmtf.org/registries/> (+ the mockup-served path
      `/redfish/v1/Registries/Base.1.5.0.json` in the fixture).
      (run 2026-10-24 — `redfish/registries/Base.1.5.0.json` mirrored,
      **byte-identical** to `test/fixtures/redfish/dmtf_mockup/Registries/
      Base.1.5.0.json` (SHA-256 `c10263417a076402a992f099db4e019c9d91f674d256d
      f32a390b86a2c46492c`, 31,984 bytes — proven authentic) + newest
      `redfish/registries/Base.1.24.0.json` (138,295 bytes; 125 templates;
      1.5.0 → 1.24.0 adds 65 + rewords 39 shared Message strings with
      **NumberOfArgs stable** — the emulator-pinned contract holds across the
      newest registry too); §8.6 error-envelope row + the trace-note
      MessageRegistry pin now cite the real mirror files; registries path +
      both files 200; 170,279 new bytes total, inside the DOCS-6 budget;
      UI-2 Dashboard `_ErrorSummary` merged semantics + separate Retry control,
      +2 widget tests)

- [x] **DOCS-19** Mirror the **mockup-served** versioned schemas for the eight
      client-mapped families DOCS-2 refreshed to **newest-only**: the pinned
      `23d21f9a` mockup serves older `@odata.type` versions —
      `Sensor.v1_8_1` (42/42 sensors), `ComputerSystem.v1_22_0`,
      `Chassis.v1_25_0`, `AccountService.v1_15_0`,
      `SoftwareInventory.v1_10_1`, `LogService.v1_6_0`,
      `EthernetInterface.v1_12_0`, `MessageRegistry.v1_0_0` — plus the newest
      `MessageRegistry.v1_9_0` (the `@odata.type` behind the newest
      `Base.1.24.0` registry payload, DOCS-18), into
      `documentations/external/redfish/schemas/v1/` **and**
      `test/fixtures/redfish/schemas/` so every `@odata.type` the mockup
      publishes for a client-mapped family has a versioned schema in the
      fixture (the DOCS-11/12/13 invariant). Source:
      `https://redfish.dmtf.org/schemas/v1/<Name>.json`.
      (run 2026-10-24 — 9 files, 560,665 bytes total, inside the DOCS-6
      budget; manifest rows + SHA-256s verified; property-delta audit: every
      client-read field present in the served versions (`Sensor` Reading/
      ReadingType/ReadingUnits/Thresholds, `ComputerSystem` identity/
      PowerState/Summaries, `AccountService` lockout surface, `LogService`
      ServiceEnabled/OverWritePolicy/Entries, `EthernetInterface` MAC/IP/VLAN)
      — **no client code change needed**; trace rows updated to cite served
      files; anchors re-verified: bmcweb `fbb307a`, mockup `23d21f9a`,
      DSP0266 1.25.0, schema index 200)

- [x] **DOCS-20** Mirror the newly pinned chassis-metrics/subsystem families
      (emulator 45 → 48, 2026-10-24) into
      `documentations/external/redfish/schemas/v1/` **and**
      `test/fixtures/redfish/schemas/`: `EnvironmentMetrics.v1_3_1`,
      `ThermalSubsystem.v1_3_1`, `ThermalMetrics.v1_3_1`,
      `PowerSubsystem.v1_1_1`, `PowerSupply.v1_5_3`, `FanCollection`,
      `PowerSupplyCollection`, plus the mockup-served `Fan.v1_5_1`,
      `PowerSupplyMetrics.v1_1_1`, and the `Redundancy.json` →
      `Redundancy.v1_7_1` citation chain. **Done (run 2026-10-24,
      11 files / 160,101 bytes; SHA-256s + manifest rows verified; property
      audit complete; commit 963366e).**

- [x] **DOCS-21** Mirror the versioned schemas for the **Battery surface** the
      emulator pinned live (48 → 50, 2026-10-24): `Battery.v1_2_2.json`
      (mockup-served `#Battery.v1_2_2.Battery` — Module1 detail:
      Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+
      ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent +
      `#Battery.SelfTest`/`#Battery.Calibrate` action targets),
      `BatteryMetrics.v1_0_3.json` (mockup-served `#BatteryMetrics.v1_0_3.
      BatteryMetrics` — InputVoltage/OutputVoltages/InputCurrentAmps/
      OutputCurrentAmps/StoredEnergyWattHours/TemperatureCelsius/ChargePercent/
      CellVoltages with `DataSourceUri` links), plus the aggregator +
      `BatteryCollection.json`, into `documentations/external/redfish/schemas/
      v1/` **and** `test/fixtures/redfish/schemas/` so every `@odata.type` the
      pinned mockup publishes for the battery family has a versioned schema in
      the fixture (the DOCS-19/20 invariant). Source:
      `https://redfish.dmtf.org/schemas/v1/Battery.v1_2_2.json` (+ newest
      version for the delta note, following the DOCS-12/13 precedent). Keep
      inside the DOCS-6 budget.
      **Done (run 2026-10-24, 7 files / 95,718 bytes; SHA-256s + manifest
      rows verified; property-delta audit complete — newest versions
      (Battery.v1_5_0 / BatteryMetrics.v1_1_0) additive only
      (BatteryChemistryType/EnergyStorageType/NominalOutputVoltage/
      ServicedDate; CRate/ERate), emulator-pinned contract holds, no code
      change; bmcweb anchor advanced `fbb307a` → `63a18f4` with all four
      mirrored docs byte-identical).**

- [x] **DOCS-22** Freshness-audit the mirrored **newest** schema versions
      against the live DMTF schema index for every client-mapped family, and
      mirror any that advanced upstream (the "newest + served" pair precedent,
      DOCS-11/12/13/19/20/21) — keep the corpus current so the properties the
      client reads are checkable against the newest definitions, not just the
      mockup-served ones. (run 2026-10-24 — **8 of 33 families had advanced**:
      EnvironmentMetrics v1_3_1→v1_7_0, Fan v1_5_1→v1_6_0, PowerSubsystem
      v1_1_1→v1_2_0, PowerSupply v1_5_3→v1_8_0, PowerSupplyMetrics v1_1_1→
      v1_3_0, TaskService v1_2_1→v1_3_0, ThermalMetrics v1_3_1→v1_3_3
      (structural no-op), ThermalSubsystem v1_3_1→v1_5_0; 8 files / 189,768
      bytes mirrored into the external corpus only (fixture keeps
      mockup-served versions), manifest rows + SHA-256s verified; deltas
      **additive-only** — no client code change; TaskService v1_3_0 adds a
      `#TaskService.DeleteAllCompletedTasks` action + `TaskMonitorAutoExpirySeconds`
      (note for #008/#020 poller); stale bmcweb anchor `fbb307a` →
      `63a18f4` in manifest + REQUIREMENTS.md Sources fixed + re-verified
      live byte-identical; remaining 25 families unchanged; all anchors
      re-verified: bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0,
      schema index 200)

- [x] **DOCS-23** Mirror the two published types the EMU-2 Bios
      `@Redfish.Settings` pin (EMU 52→53) reads — `#Bios.v1_2_2.Bios` and
      `#Settings.v1_3_5.Settings` — into the external corpus (served + newest
      pair, the DOCS-12/13/19/20/21 precedent). Source:
      `https://redfish.dmtf.org/schemas/v1/Bios.v1_2_2.json` (+ `Bios.v1_3_0`
      newest), `Settings.v1_3_5.json` (+ `Settings.v1_5_0` newest).
      **Done (run 2026-10-24, 4 files / 67,020 bytes, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit additive-only — Bios
      v1_3_0 adds `Passwords` (a #015/#026 input: the password-management
      resource superseding action-based ChangePassword), Settings v1_5_0 is a
      property no-op (6→6); client-mapped decision: Bios/Settings stay NOT
      client-mapped — the client reads only `ComputerSystem.BiosVersion` (the
      overview firmware line), no BIOS-config editor exists; if one lands it is
      **#028** and the served versions must move into
      `test/fixtures/redfish/schemas/` + the emulator corpus-invariant family
      list; anchors re-verified: bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266
      1.25.0, schema index 200).**

- [x] **DOCS-24** Mirror the two **EMU-2-pinned non-client-mapped** families
      the 18:40 EMU run reads but the external corpus had no schemas for:
      `EventDestination` (the four `Subscriptions` members —
      `#EventDestination.v1_14_0.EventDestination`, Redfish/SNMPv3/SMTP-OEM/
      SyslogTCP transports — the DOCS-7 bed for #019) and `VirtualMedia` (the
      system boot-media read surface — `#VirtualMedia.v1_6_3.VirtualMedia`,
      CD1 Applet + Floppy1 URI — the #028 boot-media UX input). Mirror the
      **mockup-served** versions plus the **newest** published versions plus
      the collection types (the DOCS-12/13/19/20/21/23 "newest + served" pair
      precedent). Source: `https://redfish.dmtf.org/schemas/v1/<Name>.json`.
      **Done (run 2026-10-24, 8 files / 194,278 bytes total, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit additive-only —
      `EventDestination.v1_14_0`→`v1_17_1` adds BackupDestinations/
      Certificates/ClientCertificates/EventFormatType/HeartbeatIntervalMinutes/
      HttpHeaders/OEM*/OriginResources/SendHeartbeat/Severities/
      SubordinateResources/SyslogFilters/VerifyCertificate (+Actions),
      `VirtualMedia.v1_6_3`→`v1_7_0` adds Certificates/EjectPolicy/
      EjectTimeout/HTTPHeaders/Password/Status/TransferMethod/
      TransferProtocolType/UserName (+Actions) — the `Password`/`UserName`
      additions are a #028 boot-media security note (never read back); every
      EMU-2-pinned field present in the served versions — **no client code
      change**; both families stay NOT client-mapped — no fixture duty,
      corpus-invariant list untouched; REQUIREMENTS.md rows that cited the EMU
      pins now cite real mirror files; anchors re-verified: bmcweb `63a18f4`
      (API HEAD), mockup `23d21f9a` (API HEAD of main), DSP0266 1.25.0,
      schema index 200).**

- [x] **DOCS-25** Mirror the **SecureBoot** family the EMU run pinned live
      (EMU 57→60, 2026-10-24) — the external corpus has no schema for
      `#SecureBoot.v1_1_1.SecureBoot` (the system boot-integrity read surface:
      SecureBootEnable/CurrentBoot/Mode + `#SecureBoot.ResetKeys` with
      `ResetKeysType@Redfish.AllowableValues`) or for the
      `#SecureBootDatabaseCollection` / `#SecureBootDatabase.v1_0_2` types
      (the 8-member PK/KEK/db/dbx + defaults database surface). Mirror the
      **mockup-served** versions plus the **newest** published versions plus
      the collection type (the DOCS-12/13/19/20/21/23/24 "newest + served"
      pair precedent) into `documentations/external/redfish/schemas/v1/`
      only — SecureBoot stays NOT client-mapped (no fixture duty; the
      corpus-invariant family list unchanged; the REQUIREMENTS.md trace rows
      for the EMU pins cite the live pin + DOCS-25 until then). Source:
      `https://redfish.dmtf.org/schemas/v1/SecureBoot.json` (+
      `SecureBootDatabase.json`). Keep inside the DOCS-6 budget.
      **Done (run 2026-10-24, 7 files / 52,544 bytes, inside DOCS-6; SHA-256s
      + manifest rows verified; served `SecureBoot.v1_1_1` + newest
      `SecureBoot.v1_2_1` (adds only `SecureBootDesiredMode`, additive),
      served `SecureBootDatabase.v1_0_2` + newest `SecureBootDatabase.v1_0_3`
      (property no-op), both aggregators + `SecureBootDatabaseCollection`;
      served-version `ResetKeysType` enums verified to match the EMU pin
      exactly (SecureBoot: ResetAllKeysToDefault/DeleteAllKeys/DeletePK; PK
      database: no DeletePK — the per-resource nuance is a schema fact, not a
      mockup quirk); REQUIREMENTS.md SecureBoot rows now cite real mirror
      files; both families stay NOT client-mapped — no fixture duty, the
      corpus-invariant family list unchanged; anchors re-verified: bmcweb
      `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200).**

- [x] **DOCS-26** Mirror the **Control** family the EMU run pinned live
      (EMU 60→63, 2026-10-24) — the external corpus has no schema for
      `#Control.v1_5_0.Control` (the modern chassis control surface:
      PowerLimit SetPoint/AllowableMax/Min + `Sensor` DataSourceUri wiring
      into the Sensors collection + CPU1Freq frequency range — the #006/#019/
      #022 power-capping read + the second live PATCH pin on SetPoint with
      the AllowableMin/Max pre-validation rule). Mirror the **mockup-served**
      `Control.v1_5_0.json` plus the **newest** `Control.v1_8_1.json` plus
      the aggregator + `ControlCollection.json` (the DOCS-12/13/19/20/21/23/24
      "newest + served" pair precedent) into
      `documentations/external/redfish/schemas/v1/` only — Control stays NOT
      client-mapped (no fixture duty; the corpus-invariant family list
      unchanged). Source: `https://redfish.dmtf.org/schemas/v1/Control.json`
      (+ `ControlCollection.json`). Keep inside the DOCS-6 budget.
      **Done (run 2026-10-24, 4 files / 129,851 bytes, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit additive-only —
      `Control.v1_5_0`→`v1_8_1` adds `SetPointError` (readonly, v1_7_0); every
      EMU-2-pinned field present in the served version — **no client code
      change**; Control stays NOT client-mapped — no fixture duty,
      corpus-invariant list untouched; REQUIREMENTS.md Control rows now cite
      real mirror files; anchors re-verified: bmcweb `63a18f4`, mockup
      `23d21f9a`, DSP0266 1.25.0, schema index 200 — the corpus mirror queue
      is now EMPTY)**;
      **UPDATED 2026-10-25 (EMULATOR run): Control became client-mapped** —
      the #022/#016 SetPoint pre-validation rule is now code
      (`ControlResource.validateSetPoint`), so the served `Control.v1_5_0.json`
      was copied into `test/fixtures/redfish/schemas/` (byte-identical SHA-256
      `de1614b0…`, 47,414 B) and `Control` was added to the emulator
      corpus-invariant family list (the DOCS-19/20/21 fixture invariant now
      covers it); the external corpus pair (served + newest) already existed
      from DOCS-26 — no new downloads this run.

- [x] **DOCS-27** Corpus freshness audit (the DOCS-22 precedent, now covering
      **38 families**): extract the newest published version per family from
      the live DMTF schema index and byte-verify every mirrored schema file,
      registry, index page, and PDF; fix any provenance drift so every
      manifest SHA is truthful. (run 2026-10-25 — **ZERO version advances**:
      all 7,167 index entries compared, newest per family unchanged for all 38
      mirrored families; **120/120 mirrored schema files byte-identical** to
      re-downloaded live copies; registries (`Base.1.5.0` +
      `Base.1.24.0`), index page, and the DSP0266 1.25.0 PDF all
      byte-identical; **no new downloads, no corpus refresh, no client code
      change**; anchors re-verified: bmcweb `63a18f4` (still HEAD), mockup
      `23d21f9a` (still HEAD), DSP0266 1.25.0 (200), schema index 200; **one
      provenance fix** — the manifest row for `redfish/mockup/
      README-mockup-server.md` recorded the upstream SHA-256 (`b3af2ff3…`,
      7,318 B) but the committed blob is the DOCS-1 normalised copy
      (trailing whitespace stripped on the `cert = ` / `key = ` lines, 2
      bytes; on-disk `0d79a165…`, 7,316 B) — the manifest claimed a hash the
      repo did not contain; the row now records the actual committed SHA with
      an explicit byte-identical-apart-from-whitespace note (restoring the
      trailing whitespace would fail `git diff --check`); the 33-family
      emulator corpus-invariant list untouched — no family became
      client-mapped)

- [x] **DOCS-28** Mirror the **Heater** family pair the EMU run pinned live
      (EMU 64→66, 2026-10-25) — the external corpus has no schema for
      `#Heater.v1_0_1.Heater` (the modern thermal-heater read surface:
      PhysicalContext/Manufacturer/Model/SerialNumber/HotPluggable/
      LocationIndicatorActive/Status + `Links.Processors` + `Metrics` link)
      or for `#HeaterMetrics.v1_0_1.HeaterMetrics` (pre-power-on/runtime
      heating seconds, PowerWatts.Reading, TemperatureReadingsCelsius +
      the advertised `#HeaterMetrics.ResetMetrics` action — a no-`/Actions/`-
      segment candidate, never a contract). Mirror the **mockup-served**
      versions (`Heater.v1_0_1` + `HeaterMetrics.v1_0_1`) plus the **newest**
      published versions (`Heater.v1_0_2` + `HeaterMetrics.v1_0_2`, verified
      on the live schema index 2026-10-25) plus the aggregators +
      `HeaterCollection.json` (the DOCS-12/13/19/20/21/23/24/25/26 "newest +
      served" pair precedent) into `documentations/external/redfish/schemas/
      v1/` only — Heaters stays NOT client-mapped (no fixture duty; the
      corpus-invariant family list unchanged). Source:
      `https://redfish.dmtf.org/schemas/v1/Heater.json` (+
      `HeaterMetrics.json`, `HeaterCollection.json`). Keep inside the DOCS-6
      budget. (run 2026-10-25, 7 files / 60,045 bytes, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit: **v1_0_1 → v1_0_2 is a
      property no-op for both families** (26 diff lines each — `$id`/
      copyright/backtick-quoted descriptions/`language`/title only), the
      emulator-pinned contract holds — no client code change; both families
      stay NOT client-mapped — no fixture duty, corpus-invariant list
      untouched; `v1_0_3` probes 404 — v1_0_2 is current; REQUIREMENTS.md
      DOCS-28 trace table cites the real mirror files; anchors re-verified:
      bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200;
      **the corpus mirror queue is now EMPTY**)

- [x] **DOCS-29** Fold the EMU 66→68 (2026-10-25) query pins into the
      DOCS-15 §7.3.2 audit table so the #018 design decisions have real trace
      rows: (1) the `$expand=.($levels=1)` shape is now pinned on **all
      three** top-level collections the #018 pass walks (Systems + Chassis +
      Managers inline full member bodies via the map-form
      `getJson(path, query:)`, incl. the manager-level reset allow-list
      `[ForceRestart, GracefulRestart]` visible through the expanded Manager
      payload — the #022/#016 conflation guard on the inlined shape); (2) the
      **`$levels=2` depth bound is pinned** — the mockup does NOT recurse,
      nested `Links` stay bare `@odata.id` refs, so the pass must follow
      cross-resource URIs explicitly for deeper hops (DSP0266 §7.3.2
      depth-cap behaviour). Also re-verified every upstream anchor this run:
      bmcweb `63a18f4` (still HEAD via GitHub API), mockup `23d21f9a` (still
      HEAD via GitHub API), DSP0266 1.25.0 (200 on the working
      `www.dmtf.org` URL), schema index 200 and **byte-identical** to the
      mirrored `v1-index.html` (SHA-256 `e5a2979727a7fc030fce29b8d7d2be2301f4
      507df03ed76e2aef48f8dc9c0b86`, 3,448,133 B) → **no corpus refresh
      needed, DOCS-27's ZERO version advances still hold**. (run
      2026-10-25, REQUIREMENTS.md DOCS-15 table + bottom line + Last-audited
      header updated; UI-2 increment landed separately — firmware
      `_ServiceSummary` merged semantics + no dangling loading label, +2
      widget tests)

- [x] **DOCS-30** Mirror the **EMU 71→75 branch-pinned families** the
      corpus-invariant crawl visits but the external corpus had **no schema
      at all** for: `CertificateService` (`v1_0_4` served + `v1_2_2` newest —
      the GenerateCSR/ReplaceCertificate action targets + the
      CertificateLocations link behind the EMU 71 ActionInfo pins),
      `CertificateLocations` (`v1_0_3` served + `v1_0_4` newest — the
      three-certificate-store `Links.Certificates` pin list),
      `Certificate` (`v1_8_1` served + `v1_11_0` newest — the store members
      the Rekey/GenerateCSR pins type; `v1_11_0` adds `Password`/`Status` —
      a #015/#026 never-read-back note),
      `KeyService` (`v1_0_0` served + `v1_0_1` newest — the NVMeoFSecrets +
      NVMeoFKeyPolicies links), `KeyPolicy` (`v1_0_0` served + `v1_0_1`
      newest — the NVMeoF allow-list surface, the #022-style read-only shape),
      `Key` (`v1_4_0` served + `v1_4_1` newest — the NVMeoFSecrets members;
      the suite pins collection-metadata only, never the `KeyString` body),
      `ComponentIntegrity` (`v1_2_2` served + `v1_5_0` newest — the
      SPDM/TPM/USB member shapes incl. the disabled USB member). Mirror the
      **mockup-served** versions plus the **newest** published versions plus
      the aggregators + collection types where they exist
      (`CertificateCollection`, `KeyPolicyCollection`, `KeyCollection`,
      `ComponentIntegrityCollection`) into
      `documentations/external/redfish/schemas/v1/` only — all seven families
      stay **NOT client-mapped** (no fixture duty; the corpus-invariant family
      list unchanged; the DOCS-24/25/26/28 "newest + served" pair precedent).
      Source: `https://redfish.dmtf.org/schemas/v1/<Name>.json`. Keep inside
      the DOCS-6 budget. (run 2026-10-25, 25 files / 446,257 bytes, inside
      DOCS-6; SHA-256s + manifest rows verified; delta audit **additive-only**
      — CertificateService.v1_2_2 adds readonly certificate-enrollment
      surface, Certificate.v1_11_0 adds `Password`/`Status` (#015/#026 note),
      the other five newest versions are property no-ops — **no client code
      change**; all seven families stay NOT client-mapped — no fixture duty,
      corpus-invariant list untouched; REQUIREMENTS.md DOCS-30 trace table
      cites the real mirror files; every `@odata.type` the pinned mockup
      publishes now has a served-version schema in the external corpus;
      anchors re-verified: bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266
      1.25.0, schema index 200; **the corpus mirror queue is now EMPTY**)

- [x] **DOCS-31** Close the corpus gap the extended invariant exposed: the
      corpus-invariant **live crawl now asserts EVERY published versioned
      `@odata.type` has a served-version schema in the external corpus** — not
      only the client-mapped families (the DOCS-19/20/21 fixture invariant
      stays, and every type now also checks
      `documentations/external/redfish/schemas/v1/`). The extension
      immediately proved DOCS-30's "corpus mirror queue EMPTY" was
      **overstated**: 17 families the pinned mockup publishes had NO schema at
      all in the external corpus — `AccelerationFunction` (served v1_0_4 +
      newest v1_0_5, no-op), `Assembly` (v1_5_0 + v1_6_1, no-op), `Memory`
      (v1_19_0 + v1_24_0, +4 props), `Processor` (v1_19_0 + v1_24_0, +4),
      `Port` (v1_11_0 + v1_20_0, +13), `ExternalAccountProvider`
      (v1_7_1 + v1_9_0, no-op), `GraphicsController` (v1_0_1 + v1_0_2,
      no-op), `HostInterface` (v1_3_1 + v1_4_0, no-op),
      `MessageRegistryFile` (v1_1_4 + v1_1_5, no-op), `OutboundConnection`
      (v1_0_1 + v1_0_3, no-op), `ProcessorMetrics` (v1_6_3 + v1_7_1, +1),
      `SecurityPolicy` (v1_0_1 + v1_1_0, +1), `SerialInterface`
      (v1_2_0 + v1_3_0, +1), `Signature` (v1_0_2 + v1_0_3, no-op),
      `SimpleStorage` (v1_3_1 + v1_3_2, no-op), `TrustedComponent`
      (v1_3_0 + v1_5_0, +1), `USBController` (v1_0_0 + v1_0_1, no-op) —
      mirrored the "newest + served" pair + aggregators + the 14 collection
      types that exist (**65 files / 1,403,838 bytes, inside DOCS-6**) into
      `documentations/external/redfish/schemas/v1/` only; all 17 stay **NOT
      client-mapped** (no fixture duty, corpus-invariant family list
      unchanged); property-delta audit **additive-only** across all 17 — **no
      client code change**; the extended invariant is a runnable emulator
      check (78-test suite green on `23d21f9a`); REQUIREMENTS.md header +
      DOCS-31 trace table cite the real mirror files; anchors re-verified:
      bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200;
      **corpus mirror queue EMPTY for every published type**)

- [x] **DOCS-16** Audit the DSP0266 clause citations in `REQUIREMENTS.md`
      against the **mirrored `DSP0266_1.25.0.pdf`** (the rows added across
      DOCS-3/4/5/10/13 cited an older spec layout) and correct every stale
      clause; pin the §9.9 "Payload annotations" contract with unit tests.
      (run 2026-10-23 23:40 — stale→correct map in REQUIREMENTS.md
      "DOCS-16": `§8.3 Service Root` → `§7.2.3`; `§8.4 ComputerSystem` /
      `§8.10 Thermal` / `§8.14 Software inventory` → versioned schemas +
      `§9` data model (DSP0266 does not enumerate per-resource property
      lists); `§9.2 HTTP protocol` (ETag) → `§6.5`+`§7.2`; `§12.2 Actions`
      → `§9.6.14`+`§7.11`; `§12.3 Basic auth` → `§13.3.3`; `§12.4 Sessions`
      /timeout → `§13.3.4`/`§13.3.4.3`; `§12.7 Error responses` → `§8.6`;
      `§9.7 Firmware update` → `§12.7`; clauses already correct left
      unchanged (`§12.1` Eventing, `§12.2` async ops, `§7.3` queries,
      `§9.6.11/12`, `§9.6.2`, `§9.1`); `feature_rules.dart` doc comment
      fixed (`§9.3` → `§9.9`); +2 unit tests pin the §9.9.2
      `@Redfish.AllowableValues` list parse and the §9.9.1
      unrecognized-annotation tolerance; anchors re-verified 23:32 UTC
      (bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266 1.25.0 — the
      `redfish.dmtf.org` PDF path 404s, hub links `www.dmtf.org`; schema
      index 200); no corpus refresh needed)

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
      `$expand` for payload shaping)** → **40 tests (map-form
      `getJson(path, query:)` `$expand` round-trip pinned 2026-10-23 22:45:
      the 19:25 unit test proved the query map forwards to the wire; the live
      emulator now proves the map-form `$expand=.($levels=1)` on the Systems
      collection returns the SAME inlined full member bodies as the URL-string
      pins — Model/PowerState/Reset allow-list incl. Nmi/ProcessorSummary —
      the exact call shape a #018 discovery pass will make)** → **41 tests
      (MessageRegistry contract pinned 2026-10-24 02:15: service root
      advertises `Registries` -> `MessageRegistryFileCollection`
      (Base.1.5.0) -> `Location[0].Uri` resolves to the `#MessageRegistry`
      JSON defining the 60 Base.* message templates (Message/Severity/
      NumberOfArgs) behind `RedfishError.code`/`firstMessage` — the DSP0266
      §8.6/§11.4 error surface for the #014 model; also re-verified the reset
      action returns 204 No Content with NO task-monitor Location header and
      the 404 path closes the connection without a body — the
      GET-on-monitor/error-envelope seams stay unit-level)** → **43 tests
      (Sessions collection + Session resource contract pinned 2026-10-24 04:01:
      the collection is enumerable from the discovered SessionService URI —
      members are session resources, never the collection; the pre-seeded
      `#Session.v1_7_1` (Administrator) carries Id/Name/Description/UserName
      and NO Password, while a POST-created session body ECHOES the login
      Password and lacks @odata.type/SessionType — the #015/#026 security rule:
      AuthManager persists the token/location from the create RESPONSE HEADERS,
      never reads session-resource bodies for secrets (DSP0266 §13.3.4 Session
      has no Password property); also pinned: POST Reset with an invalid
      `ResetType` returns 204 exactly like a valid one — the mockup does not
      validate the body, so the `ResetTypeInvalid` 400 path stays unit-level
      (#014/#022)**) → **45 tests (UpdateService action surface
      (#008/#020) pinned 2026-10-24: `FirmwareService.startSimpleUpdate`
      live round-trip — the mockup accepts ANY SimpleUpdate body and answers
      204 with NO task-monitor `Location`, so `UpdateTask` carries null
      taskUri/retryAfterSeconds (the 202-with-Location monitor path stays
      unit-level); negative pin — the advertised `HttpPushUri` (`/FWUpdate`)
      is NOT implemented: POSTing a binary upload body fails with 400 and an
      EMPTY body (no `@Message.ExtendedInfo` envelope; connection closed;
      GET /FWUpdate 404s), so the #020 binary-push flow stays unit-level and
      the client normalizes it as `RedfishException` HTTP 400 with no error
      code)** → **48 tests (chassis metrics + subsystem contracts pinned
      2026-10-24: `EnvironmentMetrics.v1_3_1` aggregate telemetry —
      TemperatureCelsius.Reading 39 + PowerWatts.Reading 374 +
      PowerLimitWatts.SetPoint 500 + FanSpeedsPercent[2] all with
      `DataSourceUri` links resolving into the Sensors collection; the
      `ThermalSubsystem.v1_3_1` surface — Fans collection (4 members) +
      FanRedundancy NPlusM (MinNeededInGroup 1 / MaxSupportedInGroup 2) +
      `ThermalMetrics.v1_3_1` TemperatureSummaryCelsius
      (Intake/Exhaust/Internal/Ambient with DataSourceUri → Sensors); the
      `PowerSubsystem.v1_1_1` surface — PowerSupplies collection (2) +
      `PowerSupply.v1_5_3` Bay1 detail (Model RKS-440DC /
      FirmwareVersion 1.00 / LineInputStatus Normal / `#PowerSupply.Reset`
      target / Metrics link) + legacy `/Chassis/1U/Power` embedded PSU
      documenting `Status.Health == 'Warning'` vs the overview rollup
      reading ComputerSystem/Chassis Status (#006/#019))** → **50 tests
      (Batteries + action round-trips pinned 2026-10-24: the
      `#BatteryCollection` → `#Battery.v1_2_2` Module1 detail —
      Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+
      ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent with
      `DataSourceUri` → Sensors/Battery1StateOfHealth resolving live, plus
      the `#Battery.SelfTest`/`#Battery.Calibrate` action targets — and the
      `#BatteryMetrics.v1_0_3` electrical telemetry: InputVoltage/
      OutputVoltages/InputCurrentAmps/OutputCurrentAmps/StoredEnergyWattHours/
      TemperatureCelsius/ChargePercent/CellVoltages[8] with `DataSourceUri`
      links into the Sensors collection (the wired-surface shape #007/#019
      can follow battery telemetry to raw sensors); action round-trip
      contract: `#Battery.SelfTest`/`#Battery.Calibrate` POST → 204 (the
      mockup's `/Actions/` framework serves them) while the **advertised
      `#PowerSupply.Reset` target is NOT implemented** — its URI has no
      `/Actions/` segment, so POST returns 404 with an empty body (the
      #022/#006 rule: treat advertised action targets as candidates, never
      contracts, on this fixture)** → **52 tests
      (corpus invariant + EventDestination detail pinned 2026-10-24: (1) a
      live published-types crawl from the service root follows every relative
      `@odata.id` + `@Redfish.ActionInfo` link (excluding `/Actions/` POST
      targets) and asserts **every published `@odata.type` for a client-mapped
      family has its served-version schema in `test/fixtures/redfish/schemas/`**
      — the DOCS-19/20/21 invariant as a runnable check (33 client-mapped
      families; crawl reaches >50 published types; green because the mirror
      work closed every served-version gap); (2) the four
      `EventService/Subscriptions` members pin the `#EventDestination.v1_14_0`
      detail — Redfish / SNMPv3 (HMAC_SHA96 + CFB128_AES128, key material
      null) / SMTP-OEM / SyslogTCP (SyslogFilters LogFacilities +
      LowestSeverity) — the DOCS-7 bed for #019)** → **53 tests
      (Bios `@Redfish.Settings` ETag surface pinned live 2026-10-24 16:30:
      `/Systems/437XR1138R2/Bios` carries the DSP0266 §9.9 `@Redfish.Settings`
      payload annotation with a real settings-object **ETag**
      (`9234ac83b9700123cc32` — the only ETag-ish token this fixture serves;
      header-level `@odata.etag`/HTTP ETags are absent, so the optimistic-
      concurrency token a #016 PATCH/If-Match flow sends is the settings-
      object ETag); pending-settings resource (`Bios/Settings`,
      `#Bios.v1_2_2.Bios`, attribute diff EmbeddedSata Raid→Ahci +
      ProcTurboMode Enabled→Disabled), `Messages[0]`
      `Base.1.0.SettingsFailed` + RelatedProperties,
      `#Bios.ResetBios` POST → 204 (mockup `/Actions/` framework),
      `#Bios.ChangePassword` advertised-only (never round-tripped with
      secrets))** → **57 tests
      (Boot override + live PATCH round-trip + discovery Links graph +
      VirtualMedia pinned 2026-10-24 18:xx: (1) `#ComputerSystem.Boot`
      publishes `BootSourceOverrideEnabled/Mode/Target` +
      `BootSourceOverrideTarget@Redfish.AllowableValues` (10 values) +
      `UefiTargetBootSourceOverride` — the annotation-form allow-list rule
      (#022/#016) applies to boot control; (2) the **FIRST live PATCH pin** —
      `RedfishClient.patchJson` (new #016 transport, 3 unit tests) PATCHes
      `Boot.BootSourceOverrideEnabled: Disabled` → 204 and the change
      **persists** (GET confirms; in-memory only — on-disk fixture
      byte-identical); negative: the mockup applies ANY PATCH body value
      unvalidated (`IndicatorLED: "Bogus"` 204s AND persists) so the client
      must pre-validate against AllowableValues and the 400 +
      `@Message.ExtendedInfo` validation-failure path stays unit-level;
      (3) discovery graph — Systems→Chassis→Manager `Links` traversal
      resolves all three hops (System.Links.Chassis/ManagedBy,
      Chassis.Links.ComputerSystems/ManagedBy/ManagersInChassis,
      Manager.Links.ManagerForServers/ManagerForChassis/ManagerInChassis +
      ManagerType/FirmwareVersion/Model) for #018/#006; (4) VirtualMedia
      read surface (`#VirtualMedia.v1_6_3`, 2 members, Inserted/
      WriteProtected/MediaTypes/ConnectedVia) — boot-media UX input for
      #028/#022; fixture publishes NO InsertMedia/EjectMedia action targets
      (advertised-as-candidate rule); VirtualMedia stays NOT client-mapped —
      no fixture-schema duty)** → **60 tests
      (SecureBoot boot-integrity surface + database + If-Match boundary
      pinned 2026-10-24 20:xx: (1) `#SecureBoot.v1_1_1.SecureBoot` — the
      system secure-boot read state (SecureBootEnable false /
      SecureBootCurrentBoot Disabled / SecureBootMode UserMode) + the
      `#SecureBoot.ResetKeys` action with `ResetKeysType@Redfish.
      AllowableValues` (ResetAllKeysToDefault/DeleteAllKeys/DeletePK — the
      annotation-form allow-list rule #022/#016 applied to a SECOND system
      action family; POST → 204 via the `/Actions/` framework; a bogus
      ResetKeysType ALSO 204s — the mockup never validates action bodies, so
      the 400 path stays unit-level); (2) the `#SecureBootDatabaseCollection`
      enumerates 8 databases (PK/KEK/db/dbx + defaults) and each
      `#SecureBootDatabase.v1_0_2` resource carries its OWN
      `#SecureBootDatabase.ResetKeys` with a *smaller* per-resource
      allow-list (PK: ResetAllKeysToDefault/DeleteAllKeys — no DeletePK) +
      a Certificates link — a key-reset UI must read the database-level
      list; (3) **If-Match boundary closed (#016)**: a PATCH with a stale
      `If-Match: "bogus-stale-etag"` header is answered 204 AND persists —
      the mockup never evaluates preconditions (no resource-level
      `@odata.etag`/HTTP ETag; only the settings-object ETag
      `9234ac83b9700123cc32` exists), so 412 enforcement stays unit-level and
      the client must send the settings-object ETag itself; SecureBoot /
      SecureBootDatabase stay NOT client-mapped — corpus mirror duty recorded
      as DOCS-25)** → **63 tests
      (chassis Controls surface pinned live 2026-10-24 22:xx:
      `#ControlCollection` enumerates PowerLimit + CPU1Freq; each
      `#Control.v1_5_0.Control` publishes ControlType/ControlMode/
      AllowableMax/Min (PowerLimit: SetPoint 500 W + Allowable 1000/150 +
      `Sensor` excerpt Reading 374 + DataSourceUri → Sensors/TotalPower — the
      wiring a #006/#019 power-capping flow follows; CPU1Freq: Frequency,
      SettingMin/Max 2000/2400 Hz + Allowable 1500/3700); the **second live
      PATCH pin (#016)** — PATCHing `SetPoint: 600` on PowerLimit answers 204
      AND persists (in-memory; on-disk fixture byte-identical), while
      `SetPoint: 9999` is ALSO applied unvalidated — the #022/#016 rule: the
      client must pre-validate Control SetPoints against AllowableMin/Max;
      Control stays NOT client-mapped — no fixture-schema duty, corpus mirror
      duty recorded as DOCS-26)** → **64 tests
      (Bios/Settings PATCH round-trip pinned live 2026-10-24 23:xx — the
      THIRD live PATCH pin (#016) and the first against the pending-settings
      object (#028 input): PATCH `/Bios/Settings` (the `@Redfish.Settings`
      SettingsObject carrying the only ETag the mockup serves —
      `9234ac83b9700123cc32`, EMU 53) with an `Attributes` subset
      (EmbeddedSata Uefi) answers 204 AND persists (in-memory; on-disk
      fixture byte-identical); the mockup IGNORES the If-Match precondition
      on the settings object too — a stale etag still 204s AND persists, so
      412 enforcement stays unit-level and the #016/#028 client must send the
      settings-object ETag itself; restored in `finally`)** → **66 tests
      (ThermalSubsystem Heaters surface + Manager.Reset live round-trip
      pinned 2026-10-25: (1) `#HeaterCollection` → `#Heater.v1_0_1.Heater`
      CPU1Heater detail — PhysicalContext CPU / Manufacturer Contoso Heaters /
      Model CPUHeater / SerialNumber SNDHM0123456789 / HotPluggable /
      LocationIndicatorActive / Status OK + `Links.Processors[0]` resolving
      live to `#Processor.v1_19_0` CPU1 + Metrics link → `#HeaterMetrics.
      v1_0_1.HeaterMetrics` — PrePowerOnHeatingTimeSeconds 600 /
      RuntimeHeatingTimeSeconds 3600 / PowerWatts.Reading 200.3 /
      TemperatureReadingsCelsius[1] (DeviceName 'Heater Average Temperature',
      Reading 2.5) — the thermal-UI surface next to the fan subsystem; the
      advertised `#HeaterMetrics.ResetMetrics` target has NO `/Actions/`
      segment → POST **404 with an empty body** (probed live; the
      PowerSupply.Reset advertised-as-candidate rule, #022/#006 — never a
      contract on this fixture; corpus mirror duty recorded as DOCS-28);
      (2) `#Manager.Reset` **live POST round-trip** — the target IS under
      `/Actions/` so the framework serves it: POST GracefulRestart → 204
      (empty body, no task-monitor Location) AND a bogus `ResetType` also
      204s — the mockup never validates action bodies, so the 400
      `ResetTypeInvalid` path stays unit-level and the #022/#016 client must
      pre-validate against the manager's OWN allow-list
      (ForceRestart/GracefulRestart, never the system list))** → **68 tests
      (generalized `$expand` pins for #018 2026-10-25: (1) the SAME
      `$expand=.($levels=1)` map-form query, applied to `/redfish/v1/Chassis`
      AND `/redfish/v1/Managers`, inlines FULL member bodies — Chassis
      identity/ChassisType/Status/IndicatorLED/Links.ComputerSystems/
      ManagedBy and Manager ManagerType/FirmwareVersion/Model/Links.
      ManagerForServers/ManagerInChassis + the **manager-level reset
      allow-list (`#Manager.Reset` == exactly `[ForceRestart,
      GracefulRestart]`) visible through the expanded payload** — the #022/
      #016 rule that the gate never conflates the manager list with the
      system list now also enforced on the inlined shape; (2) `$levels=2` on
      Systems does NOT recurse beyond one level — the member's own
      `Links.Chassis` stays a bare `@odata.id` ref (no inlined
      ChassisType/Status), so the #018 discovery pass must follow
      cross-resource URIs explicitly for deeper hops (DSP0266 §7.3.2
      depth-cap behaviour pinned live))** → **69 tests
      (two remaining negative facts pinned as live tests 2026-10-25: (1)
      **bad login still mints a session** — the run_tests.sh profile starts
      the mockup WITHOUT `-u` (no auth enforcement, a fact recorded since
      2026-10-23 but never pinned), so POST `Sessions` with a wrong password
      returns 204 + X-Auth-Token + Location naming a session resource (never
      the collection) — the client's 401 bad-login error mapping is provably
      unit-level (#015/#026) and token presence proves nothing about credential
      validity on this fixture; (2) **`MultipartHttpPushUri` is absent** — the
      DMTF fixture serves only `HttpPushUri` (`/FWUpdate`), unlike bmcweb which
      adds the multipart variant (DOCS-4/9), so
      `UpdateServiceInfo.multipartHttpPushUri` is null on this fixture and the
      #008/#020 upload flow must pick the single-push URI when that is all the
      service advertises))** → **71 tests
      (ActionInfo resource contract pinned live 2026-10-25: the two
      `CertificateService` actions (`#CertificateService.GenerateCSR` +
      `#CertificateService.ReplaceCertificate`) each advertise an
      `@Redfish.ActionInfo` link that resolves to a GET-able
      `#ActionInfo.v1_4_1.ActionInfo` resource — `GenerateCSRActionInfo`
      publishes 13 `Parameters[]` entries each with `Name`/`Required`/`DataType`
      and per-parameter `AllowableValues` on `KeyPairAlgorithm`
      (`TPM_ALG_RSA`/`TPM_ALG_ECDSA`), `KeyCurveId` (3 curves), `KeyUsage`
      (14 values); `ReplaceCertificateActionInfo` publishes `CertificateType`
      `AllowableValues ['PEM']` — the exact `Parameters[].AllowableValues`
      shape a bmcweb `ResetActionInfo`-style crawl produces on OpenBMC (#022/
      #016; DOCS-4/13); the `ResetActionInfo` resource itself is still absent
      on this fixture, so the OpenBMC allow-list-source crawl stays a code
      task; REQUIREMENTS.md ActionInfo row updated; EMU 69→71)**
      → **75 tests
      (last un-pinned service-root branches pinned live 2026-10-25: the read
      surfaces of the final three branches the corpus crawl visits —
      `CertificateService.CertificateLocations`
      (`#CertificateLocations.v1_0_3`) links the three certificate stores
      (HTTPS server cert / UpdateService client cert / VirtualMedia cert);
      `KeyService` (`#KeyService.v1_0_0`) — `NVMeoFKeyPolicies/0`
      (`#KeyPolicy.v1_0_0`) NVMeoF allow-lists
      (SecurityTransportAllowList/CipherSuiteAllowList/
      SecurityProtocolAllowList/DHGroupAllowList/SecureHashAllowList, the
      #022-style read-only allow-list shape) and `NVMeoFSecrets`
      (`#KeyCollection.KeyCollection`, 2 members) pinned **collection-
      metadata only** — the members carry real `KeyString` key material, so
      the suite asserts the surface exists + member `@odata.id` list + count
      WITHOUT fetching a member body (the #015/#026 never-read-secrets-back
      rule stated as a scope boundary in the test); `ComponentIntegrity`
      collection (4 members: SS-SPDM-0/1, USB-Integrity, TPM-0) +
      `#ComponentIntegrity.v1_2_2` SPDM (enabled, DMTF MeasurementSet with
      non-empty digest Measurements), TPM (PCR measurement set), and the
      **disabled** USB member (enabled-state read per member, never assumed)).
      All three families remain NOT client-mapped → no fixture schema duty
      (corpus-invariant unchanged); EMU 71→75)** → **78 tests
      (the last un-pinned ActionInfo families on the fixture pinned live
      2026-10-25, EMU 75→78: (1) `EventService.SubmitTestEventActionInfo`
      — the recurring #022/#016 ActionInfo-*resource* crawl contract applied
      to the #019/DOCS-7 test-event action: `@Redfish.ActionInfo` resolves to
      `#ActionInfo.v1_4_1` with 9 `Parameters[]`, `MessageId` the one
      REQUIRED parameter, `EventType` AllowableValues
      [StatusChange/ResourceUpdated/ResourceAdded/ResourceRemoved/Alert/Other],
      `MessageArgs` DataType StringArray, `EventGroupId` DataType Number; (2)
      `#Certificate.Rekey` `RekeyActionInfo` on the manager HTTPS certificate
      — `KeyPairAlgorithm` REQUIRED + AllowableValues (TPM_ALG_RSA/
      TPM_ALG_ECDSA), `KeyBitLength` optional Number, `KeyCurveId`
      AllowableValues (3 NIST curves) — the fourth ActionInfo family; (3) the
      SAME RekeyActionInfo contract verified consistent across the other two
      certificate stores the CertificateLocations pin lists
      (`UpdateService/ClientCertificates/1`,
      `AccountService/OutboundConnections/1/Certificates/1`) — a
      #022/#016-style crawler can rely on the identical
      Parameters/AllowableValues shape on every store; `ResetActionInfo`
      itself is still absent on this fixture, the OpenBMC
      allow-list-source crawl stays a code task)**
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
      path also stays unit-level (consistent with EMU-5)**;
      **probed 2026-10-24 04:01: the mockup accepts ANY `ResetType` body value
      — `ResetType: "Bogus"` returns 204 like a valid one, so the 400
      `ResetTypeInvalid` path stays unit-level too; the UI must pre-validate
      against the advertised allow-list (it does)**)
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
      ChangePassword target + Password masked on the wire);
      **Sessions collection + Session resource contract pinned live 2026-10-24
      04:01** — collection enumerable (members = session resources), pre-seeded
      `#Session.v1_7_1` (Administrator, no Password); **security rule pinned:
      POST-created session bodies echo the login `Password` and lack
      `@odata.type`/SessionType — AuthManager persists token/location from the
      create RESPONSE HEADERS and never reads secrets back from session
      resources**)
- [x] **#027** Verify the Flutter toolchain issue is stale; close it with evidence
      if `flutter analyze`/`flutter test` work, otherwise fix it.
      (run 2026-10-22 — closed with evidence: `~/flutter/bin/flutter` on PATH,
      analyze 0 / tests 242 green every run, no orphaned flutter_tester from
      this repo; DEVELOPMENT.md Toolchain documents the setup)
- [x] **#016** PATCH / `If-Match` / `@odata.etag` support.
      (**COMPLETE 2026-10-25 EMU run — closed.** The full chain landed:
      the DSP0266 §6.5.2 `patchJson` partial-update transport (2026-10-24,
      EMU 57→59 first live pin); the If-Match/`@odata.etag` wiring (2026-10-25
      DOCS run — `patchJson(..., etag:)` quotes per RFC7232, `ODataResource.
      etag`, `RedfishException.isPreconditionFailed` 412 classification); the
      `ResetActionInfo` ActionInfo-*resource* crawl (c) + the Control SetPoint
      pre-validation corollary (d) (2026-10-25 EMU runs; `ControlResource.
      validateSetPoint`, fixture + corpus-invariant list); and finally **(b)
      the Boot/IndicatorLED PATCH flow in a service + UI** — `SystemSettings
      Service.setIndicatorLed` (schema-enum pre-validation `Lit`/`Blinking`/
      `Off`, `Unknown` refused) + `setBootOverride` (annotation allow-list +
      `Once`/`Continuous`/`Disabled` pre-validation, never-guess refusal when no
      allow-list advertised) + `BootSettings` model + Controller/providers +
      Overview-view LED ChoiceChips + Boot-override card (capability-gated,
      320/800/1300 no-overflow). +34 unit/widget tests (392 → 426 passed /
      1 skipped); +2 live emulator pins (80 → 82/82: service-level round-trips
      persist through the mockup, unlisted target rejected before the wire).
      REQUIREMENTS.md PATCH row flipped **OK**. The settings-object ETag
      `9234ac83b9700123cc32` remains the only pinable concurrency token on the
      DMTF fixture, so 412 enforcement stays unit-level (documented).)
      (prior progress preserved below:)
      (**PATCH transport landed 2026-10-24 18:xx + live pin**: `RedfishClient.
      patchJson(path, body:, headers:)` — the DSP0266 §6.5.2 partial-update
      transport (204/200 normalized, non-2xx → `RedfishException`) — 3 unit
      tests in `auth_manager_test.dart`; the emulator proves a PATCH on
      `/Systems/437XR1138R2` (`Boot.BootSourceOverrideEnabled: Disabled`)
      round-trips 204 AND persists (in-memory; on-disk fixture
      byte-identical), while the mockup applies ANY body value unvalidated
      (`IndicatorLED: "Bogus"` persists) — the client must pre-validate
      against advertised `AllowableValues` (Boot-override + Reset list now
      both pinned);
      **the If-Match/`@odata.etag` *wiring* landed 2026-10-25 (DOCS run)** —
      the transport-level acceptance criteria are done: `patchJson(..., etag:)`
      sends a properly-quoted `If-Match` (RFC7232 entity-tag grammar; the
      settings-object ETag `9234ac83b9700123cc32` is the only pinable token on
      the fixture, header-level ETags stay unit-level), `ODataResource.etag`
      reads `@odata.etag`, and `RedfishException.isPreconditionFailed`
      classifies 412 (non-retryable — the caller re-fetches instead of
      blind-retrying); +6 unit tests; the 412 negative pin stays unit-level
      because the DMTF mockup IGNORES If-Match (pinned 2026-10-24); remaining:
      **(b) Boot/IndicatorLED PATCH actions in a service + UI** — the
      transport + precondition wiring are in place, a mutation feature (boot
      override / BIOS editor #028) consumes them;
      **(d) the Control SetPoint pre-validation corollary landed 2026-10-25
      (EMU run)** — `ControlResource.validateSetPoint` rejects out-of-bounds
      SetPoints before any PATCH (the EMU 60→63 negative pin: the mockup
      applies `SetPoint: 9999` unvalidated), boundaries inclusive, per-resource
      bounds never leak across controls; Control became client-mapped (served
      schema in the fixture + corpus-invariant list) — +11 unit tests, +1 live
      emulator pin (79 → 80/80);
      **If-Match boundary pinned live 2026-10-24 20:xx (EMU
      59→60)**: a PATCH with a stale `If-Match: "bogus-stale-etag"` header is
      answered 204 AND persists — the mockup never evaluates preconditions
      (no resource-level `@odata.etag`/HTTP ETag; the settings-object ETag
      `9234ac83b9700123cc32` is the only concurrency token it serves), so 412
      enforcement stays unit-level and the #016 client must send the
      settings-object ETag itself;
      (c) ~~the `ResetActionInfo` ActionInfo *resource* crawl~~ **landed
      2026-10-25 (EMU run)** — the engine follows `@Redfish.ActionInfo` links,
      `FeatureRules.supportedResetTypes` unions `Parameters[].AllowableValues`
      on `ResetType` (third allow-list source; unit + engine tests + live
      emulator pin of a served ActionInfo resource via a normal crawl);
      bmcweb
      ResetActionInfo → supportedResetTypes fallback also folds here —
      DOCS-4; **annotation-form allow-list fallback landed 2026-10-23 16:05** —
      `supportedResetTypes` now unions `SupportedResetTypes` +
      `ResetType@Redfish.AllowableValues` on `#ComputerSystem.Reset` (the
      bmcweb/mockup shape), conflation-guarded. Emulator notes: the DMTF mockup
      serves no `@odata.etag` on resources — etag behaviour cannot be pinned on
      this fixture, keep it in unit tests — 2026-10-23; the system-level
      `#ComputerSystem.Reset` `ResetType@Redfish.AllowableValues`
      (On/ForceOff/GracefulShutdown/GracefulRestart/ForceRestart/Nmi/ForceOn/
      PushPowerButton) is pinned — the allow-list fallback must read the system
      list, never the manager list — 2026-10-23 03:02;
      **third live PATCH pin + first pending-settings round-trip landed
      2026-10-24 (EMU 63→64)**: PATCH `/Bios/Settings` with an `Attributes`
      subset answers 204 + persists, and a stale `If-Match` is IGNORED (the
      settings-object ETag `9234ac83b9700123cc32` is the only concurrency
      token; the #028 BIOS editor must send it itself) — the #016 If-Match
      wiring input for the Boot/IndicatorLED flow + the 412 unit tests)
- [ ] **#017** Discover the SessionService URI instead of assuming it.
      (emulator test asserts `SessionService.@odata.id` is discoverable from the
      service root and serves a conformant SessionService — run 2026-10-22)
- [ ] **#018** Fix discovery-cache stale replay/leak.
      (**discovery-graph Links traversal pinned live 2026-10-24 18:xx**:
      Systems→Chassis→Manager `Links` (System.Links.Chassis/ManagedBy,
      Chassis.Links.ComputerSystems/ManagedBy/ManagersInChassis,
      Manager.Links.ManagerForServers/ManagerForChassis/ManagerInChassis)
      resolves all three hops — the #018 lightweight pass can walk the graph
      from any seed without hardcoded URIs)
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
      select client-side and rely only on `$expand` for payload shaping;
      **DOCS-15 spec audit folded 2026-10-23 19:25** — DSP0266 §7.3.1–7.3.5
      now traced in REQUIREMENTS.md: the pass must (a) gate `$expand` on the
      advertised `ExpandQuery.Levels`/`ExpandAll` (`*`/`$levels` default 1
      are the pinned forms; `MaxLevels` caps depth), (b) filter/project
      client-side (`$select`/`$filter` are GET-only subset semantics the
      mockup ignores), (c) map 501 (unsupported `$`-params) + 507 (oversized
      expanded payload) + `QueryNotSupportedOnResource`; the
      `RedfishClient.getJson(path, query:)` transport contract is now pinned
      by unit test — the pass can fetch collections with
      `query: {'\$expand': '.($levels=1)'}` without touching the ETag/304
      machinery; **map-form round-trip pinned live 2026-10-23 22:45** —
      `getJson('/redfish/v1/Systems', query: {'\$expand': '.($levels=1)'})`
      against the live mockup returns the same inlined full member bodies as
      the URL-string form — the exact call shape the #018 pass will make,
      end-to-end verified; **generalized across all three top-level
      collections 2026-10-25 (EMU 66→68)**: the same map-form `$expand` on
      `/redfish/v1/Chassis` + `/redfish/v1/Managers` inlines FULL member
      bodies (Chassis identity/Status/Links, Manager FirmwareVersion/Model/
      Links + the manager-level reset allow-list), and **`$levels=2` does
      NOT recurse — the member's own `Links.Chassis` stays a bare
      `@odata.id` ref** (DSP0266 §7.3.2 depth-cap pinned), so the pass gets
      one full inlined hop per collection and must follow cross-resource
      URIs explicitly for the graph)
- [x] **#022** Power: task polling, races, and error fixes.
      (**COMPLETE 2026-10-26 — closed.** All five acceptance criteria checked.
      The final one — **202 task-monitor polling** — landed via the shared
      #008/#020 poller: `RedfishTask`/`TaskMessage`
      (`lib/redfish/models/redfish_task.dart`) parse the served
      `#Task.v1_7_3.Task` shape (13 TaskStates per `Task.v1_7_4.json`,
      TaskStatus, optional PercentComplete, RFC3339 Start/EndTime,
      `Messages[]`) and `FirmwareService.pollTask` follows the 202
      `Location` monitor URI (first wait honors `Retry-After`, then polls at
      `interval` up to `maxPolls`; Completed/OK → success, terminal failure →
      `RedfishException` with the task's failure reason, budget exhaustion →
      retryable `TaskMonitorTimeout`, missing monitor → `NoTaskMonitor`).
      `FirmwareController.pollLastTask` + the firmware-view task banner
      (queued → polling spinner → final state) surface it. +25 model / +8
      service / +4 controller / +5 widget tests; unit suite 438 → **478
      passed / 1 skipped**; emulator 82 → **84/84** (2 new live pins: poller
      resolves fixture Task 545 end-to-end; stale monitor → normalized 404).
      Power-side 202 invocation stays unit-level on the DMTF fixture — the
      mockup answers 204 for reset with no monitor (pinned live);
      `PowerService` already captures the Location and reuses the same poller.
      (prior progress preserved below:)
      **the ActionInfo-*resource* crawl is now WIRED (2026-10-25 EMU run)**:
      the discovery engine follows `@Redfish.ActionInfo` links and captures the
      resources (live emulator pin — 79th test captures `SimpleUpdateActionInfo`
      through a normal crawl), and `FeatureRules.supportedResetTypes` unions
      `Parameters[].AllowableValues` on the `ResetType` parameter as the third
      source — bmcweb's `ResetActionInfo` shape parsed from the real resource
      (unit + engine tests; REQUIREMENTS.md row updated; `ResetActionInfo`
      itself is still absent on the DMTF fixture, so the live crawl pin uses
      the fixture's served ActionInfo resources). **Control SetPoint
      pre-validation landed 2026-10-25 (EMU run)**: `ControlResource.
      validateSetPoint` rejects out-of-bounds SetPoints before any PATCH
      (PowerLimit [150,1000], CPU1Freq [1500,3700]; boundaries inclusive;
      per-resource bounds never leak across controls — the SecureBoot
      allow-list precedent applied to numeric bounds); Control became
      client-mapped (served `Control.v1_5_0.json` in the fixture +
      corpus-invariant list) — +11 unit tests, +1 live emulator pin (79 →
      80/80). **The four power-action correctness fixes landed 2026-10-25
      (EMU run)** — per-action poll handle (`_pollGeneration`; a rapid second
      action supersedes the first poll loop — no optimistic-state clobbering),
      NMI keeps the current known state (interrupt, not a transition),
      failure shown once (inline error card only; snackbar success-only), and
      the final reset-URI fallback prefers the BMC ComputerSystem id — 4 of 5
      acceptance criteria checked; the remaining criterion (**202 task-monitor
      polling**) folds into #008/#020. **Emulator negative finding
      2026-10-23 17:07**: the DMTF mockup fixture ships NO `ResetActionInfo`
      ActionInfo resource for `#ComputerSystem.Reset` — it serves only the
      annotation form (= the 16:05 fallback); the ActionInfo-resource crawl is
      bmcweb-style (OpenBMC), now implemented + tested at unit/engine level and
      pinable live only via the served ActionInfo resources. Emulator asserts
      the DMTF mockup's
      `#Manager.Reset` carries its own `ResetType@Redfish.AllowableValues` —
      the fallback must not conflate manager- vs system-level Reset actions —
      run 2026-10-22; system-level allow-list pinned incl. `Nmi` (NMI-stabilize)
      + `ForceOn` + `PushPowerButton`, and the mockup does NOT advertise
      `PowerCycle` — the gate must use exactly the advertised values — run
      2026-10-23 03:02; the annotation-form rule is now also pinned on a
      SECOND system action family — `#SecureBoot.ResetKeys` +
      `ResetKeysType@Redfish.AllowableValues` (EMU 57→60, 2026-10-24), with
      the per-resource nuance that `#SecureBootDatabase.ResetKeys` carries a
      *smaller* allow-list than the SecureBoot-level one (PK omits DeletePK)
      — allow-list sources are per-resource, never shared)
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
      GET-on-monitor + TaskState parsing;
      **TASK-MONITOR POLLING LANDED 2026-10-26 (#022 closed on it)** —
      `RedfishTask`/`TaskMessage` models + `FirmwareService.pollTask`
      (GET-on-monitor, Retry-After first-wait, terminal detection, bounded
      polls) + `FirmwareController.pollLastTask` + the firmware-view task
      banner; unit 478/1 skipped, emulator 84/84 with 2 new live pins;
      **PUSH UPLOAD TRANSPORT LANDED 2026-10-26 (EMU)** —
      `FirmwareService.pushImage(PushImageRequest)` uploads raw bytes
      single-push on `HttpPushUri` or multipart `FormData` (`UpdateFile` +
      optional `UpdateParameters` JSON for targets/apply-time) on
      `MultipartHttpPushUri`, resolves the push URI against the UpdateService
      resource URI (DSP0266 relative-reference rule), normalizes non-2xx to
      friendly `RedfishException`s (400/413/5xx surfaces the served body, no
      masking; missing push URI → `NoPushUri`; disconnected →
      `NotConnected`), reports byte progress via dio `onSendProgress`, and
      hands a 202 + `Location` to `pollTask`; `FirmwareController.pushImage`
      (uploading/uploadProgress) + the firmware-view upload banner (merged
      semantics label + byte-count progress) drive the flow; +16 unit tests,
      +1 live emulator pin — unit 496/1 skipped, emulator 85/85.
      **Remaining #008/#020:** the file-picker UI integration (desktop/web),
      the **apply-time selection** widget (mockup publishes `HttpPushUriOptions.
      HttpPushUriApplyTime` — Immediate/OnReset/AtMaintenanceWindowStart/
      InMaintenanceWindowOnReset; `UpdateServiceInfo` already parses both;
      don't assume Immediate), and the task-timeline UI — a live progress bar
      from `PercentComplete` (absent on the fixture; the poller tolerates it))
- [ ] **#009 / #021** Remote KVM capability detection and console rendering.
      (emulator now pins the manager network surface the console renderer
      needs: `Manager.NetworkProtocol.KVMIP` ProtocolEnabled + port 5288, plus
      HTTPS/SSH endpoints, and EthernetInterfaces MAC/IP/VLAN — run
      2026-10-23 11:39; #009 must resolve the console endpoint from the
      advertised KVMIP port, never hardcode ports)
- [ ] **#028** BIOS configuration editor — Bios/Settings surface (candidate
      feature, DOCS-23 2026-10-24). The EMU-2 Bios `@Redfish.Settings` pin +
      the DOCS-23 corpus mirror give the full served/newest pair; a BIOS-config
      editor makes `Bios`/`Settings` client-mapped, which pulls them into the
      DOCS-19/20/21 fixture invariant (copy served `Bios.v1_2_2.json` +
      `Settings.v1_3_5.json` into `test/fixtures/redfish/schemas/` and add both
      families to the emulator corpus-invariant list). PATCH/If-Match with the
      settings-object ETag folds #016; **the pending-settings PATCH round-trip
      seam is now pinned live (EMU 63→64, 2026-10-24): PATCH `/Bios/Settings`
      with an `Attributes` subset 204s + persists, stale If-Match ignored —
      the exact mutation shape a BIOS editor sends**; `Bios.v1_3_0` `Passwords`
      + the `ChangePassword` action are a #015/#026 password-management input.
      See `issues/open/028-*` for acceptance criteria.
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
      non-card labels); **SystemOverviewPage connection header (name + URL)
      merged semantics label (`<name>, <scheme>://<host>:<port>`) done
      2026-10-23 19:25 — Semantics(container + excludeSemantics) wraps the
      title+URL column, conditional connection-error text keeps its own node,
      widget test asserts the merged label + both visible texts;
      `connectedHandle` helper gained a `port` param; **KVM console card
      connect-URI row merged semantics label (`Connect URI: <uri>`) done
      2026-10-23 22:45 — Semantics(container + excludeSemantics) wraps the
      label + SelectableText in a row, widget test asserts the merged node +
      both visible texts; **OverviewView error state merged semantics label
      (`Unable to load overview. <message>`) done 2026-10-23 23:40 —
      Semantics(container + excludeSemantics) wraps the icon + title +
      detail column, Retry button keeps its own control node, widget test
      asserts the merged label + visible texts + separately-announced Retry;
      **SensorsView error state merged semantics label (`Unable to load
      sensors. <message>`) done 2026-10-24 — Semantics(container +
      excludeSemantics) wraps the icon + title + detail column (the
      established error-state pattern), the new Retry button reloads via the
      controller (re-runs the failing service in tests), widget tests assert
      the merged label + visible texts + separately-announced Retry;
      **PowerView inline error state merged semantics label (`Power control
      failed. <message>`) + separate Retry `TextButton.icon` done 2026-10-24 —
      Semantics(container + excludeSemantics) wraps the visible error text,
      Retry re-reads the power state via the existing
      `PowerController.refresh()` (clears the error on success), widget tests
      assert the merged node + visible text + separately-announced Retry +
      Retry re-runs the failing fetch;
      **KvmView hard-load error state merged semantics label (`Unable to load
      KVM consoles. <message>`) + Retry `FilledButton.icon` done 2026-10-24 —
      the full icon + title + detail error state (the SensorsView pattern),
      Retry reloads via `KvmController.load()`, and an error with zero
      consoles now renders the error state instead of the bare error line
      above 'No consoles found.', widget tests assert the merged node +
      visible texts + separately-announced Retry + Retry re-runs the failing
      service;
      **DashboardView error summary card merged semantics label (`Unable to
      reach N systems. Retry available.`) done 2026-10-24 — Semantics(container
      + excludeSemantics) wraps the icon + visible text row, the Retry
      TextButton keeps its own control node outside the container, widget
      tests assert the merged node + visible text + separately-announced Retry
      + the singular (`Unable to reach 1 system…`) form;
      **FirmwareView Start-update button busy state done 2026-10-24 —
      `FirmwareUiState.starting` distinguishes a SimpleUpdate POST in flight
      from screen-level loading; while starting the FilledButton shows a
      spinner + 'Starting…' and is disabled, re-enabling on success/failure
      (the UI-5 power-dialog busy-state precedent) — +3 controller tests +
      2 widget tests (busy state + failure re-enable);
      **DashboardView empty state ("No systems yet. Tap + to add a BMC.")
      done 2026-10-24 — the last bare-`Text` empty surface on the dashboard
      now renders the established pattern: icon (`Icons.dns_outlined`) +
      visible text inside a `Semantics(container + excludeSemantics)`
      merged node (one self-describing announcement; no Retry — the empty
      list is not an error), +1 widget test asserts the merged label +
      visible text + icon; existing 320/800/1300 no-overflow tests unchanged
      (the empty state is a `Center` + `mainAxisSize.min` column);
      **FirmwareView empty state ("No firmware inventory reported.") done
      2026-10-24 — the last bare-`Text` empty surface on the firmware view
      now renders the established pattern: icon (`Icons.inventory_2_outlined`)
      + visible text inside a `Semantics(container + excludeSemantics)`
      merged node (one self-describing announcement; no Retry — a successful
      load with zero inventory is not an error), +1 widget test asserts the
      merged label + visible text + icon + no overflow at 320/800 px;
      **FirmwareView inventory-loading state merged semantics label
      (`Loading firmware inventory`) done 2026-10-24 — the in-flight
      inventory load previously announced a bare detached `Text('Loading
      inventory…')` next to the header; it now renders inside a
      `Semantics(container + excludeSemantics)` node (one self-describing
      announcement for the specific surface still loading, visible text
      preserved), +1 widget test asserts the merged label + visible text;
      **SystemOverviewPage `System not found` fallback merged semantics node
      (`System not found`) done 2026-10-24 — the last bare `Text` fallback on
      the overview page now renders the established pattern: icon
      (`Icons.search_off_outlined`) + visible text inside a
      `Semantics(container + excludeSemantics)` merged node (one
      self-describing announcement; no Retry — a nonexistent system id is not
      an error), +1 widget test asserts the merged label + visible text +
      icon + no overflow at 320 px (via the `addTearDown` restore pattern);
      **AppRouter route-not-found fallback merged semantics node (`Route not
      found: <uri>`) done 2026-10-24 — the last bare-`Text` fallback surface
      in the app (GoRouter `errorBuilder`) now renders the established
      pattern: icon (`Icons.search_off_outlined`) + visible text inside a
      `Semantics(container + excludeSemantics)` merged node; the URI is
      dynamic so the label mirrors the visible text; no Retry — an unknown
      route is not an error; +2 widget tests in `test/core/router_test.dart`
      (merged `bySemanticsLabel` node + visible text + icon, and no overflow
      at 320 px);
      the FirmwareView no-overflow test's manual `setSurfaceSize` restore was
      also converted to the established `addTearDown` (the 12:30 journal
      noted it for this run);
      **SystemCard header merges name + state + endpoint URL (`<name>,
      <state>, <scheme>://<host>:<port>`) done 2026-10-24 — the URL subtitle
      line (the last remaining non-card label on the dashboard card) is now
      part of the merged header semantics node (the SystemOverviewPage
      connection-header precedent) and the standalone subtitle Text is
      `ExcludeSemantics`'d so it does not double-announce (visible text
      preserved); the existing 4-state header test updated to expect the
      merged name + state + URL label, +1 widget test asserts the merged node
      + the URL appears exactly once in the semantics tree;
      **SystemCard detail line (Manufacturer · Model) merged semantics node
      done 2026-10-24 — the last remaining non-card label on the dashboard
      card body now renders inside a `Semantics(container +
      excludeSemantics)` node (one self-describing announcement, visible
      text preserved — the established card-row pattern), +1 widget test
      asserts the merged label + visible text;
      **OverviewView Identity card key/value rows merged semantics node done
      2026-10-25 — each `_kv` row (label + value) now announces as ONE node
      (`Manufacturer: Acme`, `Model: Server-9`, `Serial: SN1`, `BIOS: 1.0`;
      a missing value merges as `<label>: Not exposed by this BMC`) —
      a screen reader hears the field and its value together instead of a
      detached label next to a detached value text, +2 widget tests assert
      the merged labels + visible texts + the missing-value form;
      **OverviewView Processors card body merged semantics node done
      2026-10-25 — the count + model texts (`2 processor(s)`, `P9`)
      previously announced as two detached nodes under the merged
      "Processors" header; they now render inside ONE
      `Semantics(container + excludeSemantics)` node (`2 processor(s), P9`)
      — one self-describing card-body announcement, visible texts preserved
      (the established card-row pattern), +1 widget test asserts the merged
      label + both visible texts;
      **HealthBadge/PowerBadge merged node fixed (added `excludeSemantics`)
      done 2026-10-25 — both badges wrapped their `Chip` in
      `Semantics(label: ..., container: true)` WITHOUT `excludeSemantics`,
      so the chip's inner Text still announced separately (a screen reader
      heard "Health Warning" then "Warning" / "Power Off" then "Off" — the
      double-announcement pattern merged everywhere else in the app). Both
      badges now add `excludeSemantics: true` so the merged label is the
      ONLY announcement; visible text preserved for sighted users; the a11y
      label test extended to pin the single-node behavior
      (`bySemanticsLabel('Warning')`/`('Off')` now findsNothing while the
      merged labels still find one widget and the visible texts remain);
      **FirmwareView inventory card merged node fixed (added
      `excludeSemantics`) done 2026-10-25 — the per-item firmware card
      wrapped its `ListTile` in `Semantics(container: true, label: ...)`
      WITHOUT `excludeSemantics: true`, so the inner title/subtitle/chip
      `Text`s still announced separately (a screen reader heard the merged
      summary `Firmware BMC Firmware, 3.2.1, OK, updateable` AND then `BMC
      Firmware`, `BMC · 3.2.1 · OK`, `Updateable` — the double-announcement
      pattern merged everywhere else in the app). The card now adds
      `excludeSemantics: true` so the merged label is the ONLY announcement;
      visible text preserved for sighted users; the a11y label test extended
      to pin the single-node behavior (`bySemanticsLabel('BMC Firmware')`/
      `('Updateable')` now findsNothing while the merged label still finds
      one widget and the visible texts remain); audit: no other
      `Semantics(container: true)` node in `lib/` lacks `excludeSemantics`;
      **firmware start-update form transfer-protocol selector labelled done
      2026-10-25 — the bare `DropdownButton<String>` (protocol picker) had NO
      visible label (unlike the Image URI TextField's `labelText`) and no
      a11y context — it now renders a `Transfer protocol` Text above the
      select (the Image URI labelText pattern, labelLarge + outline color);
      the card column merges sibling plain Texts so a screen reader hears
      `Start update, Transfer protocol` in the section node before the
      protocol value while the dropdown keeps its own button node (`HTTP`);
      +1 widget test (visible label + announced label + dropdown control node
      + protocol selection still works), firmware 18→19;
      **KVM console card body rows merged semantics nodes done 2026-10-25 —
      the three remaining bare body labels in `_ConsoleCard` (`Manager: BMC`,
      `Max concurrent sessions: 4`, `HTML5 console — open via BMC web UI.`)
      each announced as detached `Text` rows (the last "non-card label"
      class in the KVM view); each now renders inside a
      `Semantics(container + excludeSemantics)` node (the established
      card-row pattern, one self-describing announcement, visible texts
      preserved), +1 widget test asserts the three merged labels + visible
      texts, KVM 11→12;
      **sensor tile merged labels now carry the visible subtitle context done
      2026-10-25 — the three tiles wrapped their inner title/subtitle/chip in
      `Semantics(container + excludeSemantics)` (the 2026-10-23 merge) but the
      `excludeSemantics` dropped the SUBTITLE: temperature tiles hid the
      threshold hints (`caution 45 / crit 55`), fan tiles hid the physical
      context (`CPU`), generic sensor tiles hid the reading type + thresholds
      (`Voltage · UpperCritical 13.0 / LowerCritical 11.0`) that sighted
      users see; each merged label now appends that visible subtitle context
      (`Temperature CPU1 Temp, 41.0°C, Unknown, caution 45 / crit 55`, `Fan
      Fan0, 5400 RPM, Unknown, CPU`, `Sensor PSU1, 12.50 V, Unknown, Voltage,
      UpperCritical 13.0 / LowerCritical 11.0`) — one self-describing
      announcement that mirrors the visible text, +1 widget test asserts the
      detail-aware labels + visible subtitles stay, sensors 13→14;
      **OverviewView Memory card body merged semantics node done 2026-10-25 —
      the card capacity (`32 GiB`) sat under the merged "Memory" header as a
      bare detached `Text` (a screen reader heard a naked number); it now
      renders inside the established `Semantics(container + excludeSemantics)`
      card-body pattern (the Processors-card precedent): one self-describing
      announcement (`32 GiB`) that mirrors the visible text, visible text
      preserved for sighted users, +1 widget test asserts the merged label +
      visible text, overview 14→15;
      **PowerView card header merges the "Power control" subtitle into the
      header node done 2026-10-25 — the merged header previously announced
      `<name>, power <state>` with the `Power control` subtitle below it as a
      bare detached Text (the same list-header class the KVM header merged
      title+subtitle for); the whole card header (display name + PowerBadge +
      subtitle) now announces as ONE node `<name>, power <state>, Power
      control`; visible texts preserved for sighted users; +1 widget test
      asserts the merged label incl. the subtitle + visible text preserved +
      the bare "Power control" node no longer announces separately;
      **unlabeled loading spinners merge into self-describing nodes done
      2026-10-25 — the last bare `CircularProgressIndicator` announcements in
      the feature views: SensorsView's full-screen spinner (the only node on
      screen) now announces ONE merged `Loading sensors` node, and KvmView's
      first-load spinner now announces ONE merged `Loading KVM consoles` node
      (both via the established `Semantics(container + excludeSemantics)`
      loading pattern, visible spinners preserved; the KVM change also
      reordered the state branches so a first load no longer flashes the
      misleading `No consoles found.` empty state — `loading && consoles.
      isEmpty` renders the merged loading node before the empty branch, while
      refreshes with existing consoles keep the inline spinner under the
      header); +2 widget tests (sensors 14→15, kvm 12→13);
      **Add-system dialog focus entry + keyboard Tab order pinned done
      2026-10-25 — `SystemProfileForm` gained `autofocusFirstField` (the
      Add-system dialog sets it, so keyboard and screen-reader users land
      inside the form the moment it opens — WAI-ARIA dialog pattern: focus
      moves into the dialog; the edit page leaves it off so it does not
      scroll on load); two widget tests pin (1) the dialog opening with
      keyboard focus on the first field and (2) the full Tab traversal order
      Name → Host → Port → Use TLS switch → auth-method dropdown → Username →
      Password → Remember password → Allow self-signed → Add system button —
      a regression (autofocus removed or a field inserted out of visual
      order) now fails loudly, systems 31→32;
      **#016 writable IndicatorLED setter + Boot-override card done 2026-10-25
      — the Overview view's "Indicator LED" card gained the three
      schema-writable ChoiceChips (Lit/Blinking/Off; capability-gated on a
      known state; busy spinner + merged inline error) and a capability-gated
      Boot-override card (dropdown of the advertised
      `BootSourceOverrideTarget@Redfish.AllowableValues` + Once/Continuous +
      Apply; hidden entirely when no allow-list is advertised — never a
      placeholder); the LED state text + chips both announce (the selected
      chip is its own control node); +8 widget tests incl. 320/800/1300
      no-overflow (service-level assertions live in settings_service_test.dart);
      **ConfirmResetDialog focus entry + Tab order pinned done 2026-10-25 —
      the power reset-confirmation dialog now opens with keyboard focus
      INSIDE it on the least-destructive action (Cancel) — WAI-ARIA dialog
      pattern, the Add-system dialog precedent — via an explicit
      `_cancelFocus` FocusNode requested after the first frame (an Enter/Tab
      user cannot accidentally trigger a destructive reset), Tab walks
      Cancel → Force and wraps; +2 widget tests (destructive + non-destructive
      dialog focus entry + the Tab order), power 51→53;
      **remove-system confirmation dialog landed done 2026-10-25 — the
      dashboard `Remove` menu action previously deleted a profile (and its
      stored credentials) on a single tap with NO confirmation; it now opens
      `ConfirmRemoveSystemDialog` (`lib/features/systems/views/
      confirm_remove_system_dialog.dart`): focus lands inside the dialog on
      the least-destructive action (Cancel), Tab walks Cancel → Remove and
      wraps, both actions expose explicit ≥48 px touch targets, the confirm
      button uses the error color + destructive semantics label, and the copy
      makes the permanence explicit ("stored connection profile and its saved
      credentials will be deleted permanently"); +4 dashboard-integration
      widget tests (dialog copy, focus entry + Tab order, cancel keeps the
      system, confirm removes it); the dialog test exposed a small real
      defect — `removeProfile` tried to clear `selectedId` via
      `copyWith(selectedId: null)` but `SystemState.copyWith` treats null as
      "keep current", so the id of a removed system stayed selected; removal
      now builds the state directly and +2 `system_manager_test.dart` unit
      tests pin the clear-on-last-removal + fallback-to-first-remaining
      behaviour; systems 32→36 (widget) + manager CRUD 3→5;
      all dialogs now have focus/tab tests (Add-system, reset-confirm,
      remove-confirm);
      **edit-system dialog focus entry pinned done 2026-10-26 — the last
      dialog without focus entry: `showEditSystemDialog` now sets
      `autofocusFirstField: true` (keyboard/screen-reader users land on the
      first field the moment the dialog opens — WAI-ARIA dialog pattern, the
      Add-system dialog precedent); the full-page `EditSystemPage` keeps the
      flag off so it does not scroll on load (the documented reason for the
      flag); +2 widget tests pin the dialog focus entry + the full Tab order
      to the Save button (Name → Host → Port → TLS → auth-method → Username →
      Password → Remember → self-signed → Save, the edit-mode button label
      asserted so a regression to 'Add system' fails loudly), systems 36→38;
      extend to
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
      (note 2026-10-25 DOCS run: the Flutter 3.47.6 `dart format` reflows 26
      Dart files committed under an older formatter (line-join width drift in
      lib/redfish/{client,discovery,models}/*, lib/features/{kvm,overview,
      power,sensors,systems}/*, test/**) — the DOCS run restored them rather
      than commit unrelated churn; a future run should absorb the drift as a
      dedicated `chore: dart format` commit after verifying analyze+test
      stay green)
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
