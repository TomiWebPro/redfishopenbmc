# Redfish Requirement Traceability

Maps audited Redfish / OpenBMC requirements to the client implementation and its
tests. Source citations point at the mirrored corpus in
`documentations/external/redfish/` (see `README.md` manifest for hashes) or the
live DMTF URLs. Status legend: `OK` (implemented + tested), `GAP` (known gap,
tracked in `FUTUREWORK.md`), `N/A` (not applicable to this client).

Last audited: 2026-10-23 (EMULATOR run — Task resource contract pinned end-to-end:
`TaskState`/`TaskStatus`/`Start`-`EndTime`/`Messages[]` on the mockup's Task 545,
incl. the **absent `PercentComplete`** the #008/#020 poller must treat as unknown,
plus `TaskService.CompletedTaskOverWritePolicy`/`LifeCycleEventOnTaskStateChange`;
DOCS-11 was the prior audit — mirrored the missing `LogEntry` corpus +
`LogService.v1_9_0.json` after the emulator pinned `LogEntry.v1_16_0` shapes;
upstream anchors re-verified: bmcweb `27e0930b`, Redfish-Mockup-Server
`23d21f9a`, DSP0266 1.25.0, schema index current. DOCS-10 — task-monitor
contract + `Task` corpus + `UpdateTask.Retry-After`; DOCS-8 — bmcweb pin moved
`0128851e` → `27e0930b`).
Sources:

- DSP0266 1.25.0 — `redfish/spec/DSP0266_1.25.0.pdf`
- DMTF schema index — `redfish/schemas/v1-index.html` + `redfish/schemas/v1/*.json`
- bmcweb — `redfish/openbmc/Redfish.md`, `REDFISH_CHECKLIST.md`, `OEM_SCHEMAS.md`,
  `CLIENTS.md` (bmcweb master `27e0930b`)

## DOCS-10 — task-monitor contract audit (2026-10-23)

Mirrored the official DMTF `Task` schemas (`Task.json` aggregator,
`Task.v1_7_4.json`, `TaskService.v1_2_1.json`) and audited DSP0266 §12.2
"Asynchronous operations" against the client's async handling:

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Async operation → 202 Accepted + `Location` task monitor URI (may also include `Retry-After`) | DSP0266 §12.2; `Task.json` | `FirmwareService.startSimpleUpdate` + `PowerService.reset` read `Location`; `FirmwareService` now also reads `Retry-After` into `UpdateTask.retryAfterSeconds` (DOCS-10) | `firmware_service_test.dart` (+1 Retry-After parse), `firmware_model_test.dart` (+1 UpdateTask), emulator firmware row | Partial: 202 accepted + Location captured; task *polling* still #008/#020 (firmware) + #022 (power) |
| Task monitor URI format `/redfish/v1/TaskService/TaskMonitors/<TaskMonitorId>` | DSP0266 §12.2 (task monitor "should be in the format") | n/a — client treats the `Location` value as opaque | emulator asserts client accepts the mockup's task URI | Note for #008/#020/#022 |
| GET on the task monitor returns 202 while in process, then the final status + headers + body of the initial operation | DSP0266 §12.2 | not implemented — no task poller | — | GAP: #008/#020 (firmware), #022 (power) |
| DELETE task monitor or Task resource cancels; subsequent GET → 410 Gone / 404 Not Found | DSP0266 §12.2 | not implemented | — | GAP: #008/#020 (upload cancel) |
| `Task.TaskState` (13 values incl. `Cancelled`/`Cancelling`/`Exception`); `TaskStatus` (Health) set only at completion; `PercentComplete` 0–100 (0 before start) | `Task.v1_7_4.json` `TaskState`/`TaskStatus`/`PercentComplete`; DSP0266 §12.2 | `UpdateTask` model captures `taskUri` + `retryAfterSeconds` only (no TaskState parsing yet) | `firmware_model_test.dart`; **emulator pins the mockup Task resource end-to-end: `TaskState Completed`, `TaskStatus OK`, RFC3339 Start/EndTime — and PercentComplete is ABSENT on the fixture, so the poller must treat it as unknown** (pinned 2026-10-23) | Partial: state machine comes with the #008/#020 poller |
| `Task.Messages[]` carries task-associated messages (e.g. `ManagerGoingOfflineTemporarily` for service reboot during firmware update) | `Task.v1_7_4.json` `Messages`; DSP0266 §12.2 | not parsed | **emulator pins the mockup Task `Messages[]` shape: `MessageId` (`Base.*`), `Message`, `MessageArgs[]`, `Severity`** (pinned 2026-10-23) | GAP: #008/#020 task timeline |
| `TaskService.CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, `Tasks` collection | `TaskService.v1_2_1.json` | not read (client only uses `SessionService` etc.) | **emulator pins `CompletedTaskOverWritePolicy=Manual`, `LifeCycleEventOnTaskStateChange=true`, and the enumerable `Tasks` collection** (pinned 2026-10-23) | vendor/feature row for #008/#020 task timeline |
| `Retry-After` on the 202 tells the client how long to wait before polling; services may go offline (firmware update) and shall include `ManagerGoingOfflineTemporarily` + `Retry-After` | DSP0266 §12.2 | `FirmwareService.startSimpleUpdate` parses `Retry-After` (seconds or HTTP-date) into `UpdateTask.retryAfterSeconds` | `firmware_service_test.dart` | Partial: captured but not yet used to schedule the poll (that is #008/#020/#022) |

Folded into code this run:

- `UpdateTask` (the currently-dead handle model) now carries the spec's
  optional poll hint: `retryAfterSeconds` (from the 202 `Retry-After` header,
  seconds or HTTP-date form). `FirmwareService.startSimpleUpdate` builds the
  handle instead of returning a bare `String`, so a future task poller has the
  wait hint without guessing.

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Service root at `/redfish/v1/` with `Systems`, `Managers`, `Chassis`, `UpdateService`, `SessionService` links | DSP0266 §8.3 "Service Root"; `ServiceRoot.json` | `lib/redfish/discovery/discovery_engine.dart` (`_crawl`, root seed `redfish/v1/`) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| `@odata.id` link traversal is cycle-safe and depth-bounded (≤3) | DSP0266 §8.5 "Redfish object model"; `Odata.json` | `lib/redfish/discovery/discovery_engine.dart` (visited `Set<uri>`, maxDepth) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| Feature detection "nothing is assumed": every UI feature gated on discovered capability | OpenBMC `Redfish.md`; DSP0266 §8.5 | `lib/redfish/discovery/feature_rules.dart` → `SystemFeatures` | `test/redfish/discovery/feature_rules_test.dart` | OK |
| Conditional GET re-crawl via `If-None-Match` / ETag (304 short-circuit) | DSP0266 §9.2 "HTTP and the Redfish protocol"; `ComputerSystem.json` | `lib/redfish/discovery/discovery_engine.dart` (`_fetchUri` etag map) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| PATCH write support with `If-Match` / `@odata.etag` | DSP0266 §9.2 (ETag); §12 "Modifying resources" | **not implemented** | — | GAP: #016 |
| Error envelope: `error.code`, `error.message`, `error.@Message.ExtendedInfo[]` | DSP0266 §12.7 "Error responses"; `redfish_error.md` | `lib/redfish/models/redfish_error.dart` | `test/redfish/models/models_test.dart` | OK (see #014: ExtendedInfo parsing hardening) |
| Session auth: `POST SessionService/Sessions` → `X-Auth-Token`, session reuse | DSP0266 §12.4 "Sessions"; `SessionService.json` | `lib/redfish/client/auth_manager.dart` | `test/redfish/client/auth_manager_test.dart` | OK (see #015: discover session URI instead of hardcoding) |
| Basic auth fallback | DSP0266 §12.3 "Basic authentication" | `lib/redfish/client/auth_manager.dart` | `test/redfish/client/auth_manager_test.dart` | OK |
| No plaintext password at rest; token in secure storage | DSP0266 §12.4; OpenBMC `Redfish.md` | `lib/core/storage/secure_storage.dart`, `AuthManager` | `test/redfish/client/auth_manager_test.dart` | OK |
| Power control: `ComputerSystem.Reset` action with `ResetType` body; 202+`Location` accepted | DSP0266 §12.2 "Actions"; `ComputerSystem.json` `Actions` | `lib/features/power/power_service.dart` | `test/features/power/` | OK |
| Sensor telemetry: `Chassis[*].Thermal` / `Sensors`, reading + units | DSP0266 §8.10; `Sensor.json`, `Thermal.json` | `lib/features/sensors/sensors_controller.dart` | `test/features/sensors/` | OK |
| System overview: `ComputerSystem` identity (`Manufacturer`/`Model`/`SKU`/`SerialNumber`/`PartNumber`/`BiosVersion`), `PowerState`, `Status.Health`(+Rollup), `ProcessorSummary`/`MemorySummary`, `IndicatorLED`, leading `Chassis` thermal | DSP0266 §8.4 ComputerSystem + §8.10 Thermal; `ComputerSystem.v1_29_0.json` | `lib/features/overview/overview_service.dart` (+ `models/system_overview.dart`) hydrates system + best-effort chassis thermal | `test/features/overview/overview_provider_test.dart` + `overview_view_test.dart`; **emulator suite now pins the full hydrate end-to-end** against the DMTF mockup (#006) | OK |
| Firmware inventory: `UpdateService` / `SoftwareInventory` collection | DSP0266 §8.14 "Software inventory"; `SoftwareInventory.json` | `lib/features/firmware/firmware_models.dart` | `test/features/firmware/` | OK |
| Firmware update: `UpdateService.SimpleUpdate` (entity-upload mode TBD); `UpdateService.ServiceEnabled` gates the capability | DSP0266 §9.7 "Firmware update"; `UpdateService.json` (`ServiceEnabled`); OpenBMC `Redfish.md` §UpdateService | `lib/features/firmware/firmware_service.dart`; `FeatureRules.firmwareUpdate` honors `ServiceEnabled` (DOCS-5) | `test/features/firmware/`; `feature_rules_test.dart` (ServiceEnabled case) | Partial — task monitoring in #008/#020 |
| KVM capability: `Manager.GraphicalConsole` / OEM console detection | OpenBMC `Redfish.md`; `Manager.json` | `lib/redfish/discovery/feature_rules.dart` (`kvm`, `kvmType`) | `test/redfish/discovery/feature_rules_test.dart` | OK (rendering gated in #009/#021) |
| Event subscription: `EventService.Subscriptions` — POST → 201 + `Location`; DELETE to unsubscribe | DSP0266 §12.1.1–§12.1.2 "Eventing"; `EventService.json` | **not implemented** | — | GAP: DOCS-7 — decision recorded below (out-of-scope this milestone) |
| SSE event stream: GET `EventService.ServerSentEventUri` | DSP0266 §12.1.3 "Open an SSE connection"; `EventService.v1_6_9+` | **not implemented** (no SSE transport dependency in `pubspec.yaml`) | — | GAP: DOCS-7 — revisit when telemetry/eventing lands (#007/#019) |
| EventType-based eventing deprecated; filter subscriptions by `RegistryPrefixes` / `ResourceTypes` / `MessageIds` | DSP0266 §12.1.4–§12.1.5 | n/a (no subscriber yet) | — | Note for a future implementation |
| Task monitor: 202 + `Location` + optional `Retry-After`; GET monitor → 202 while running, then final status + body; DELETE cancels; 404/410 after completion | DSP0266 §12.2 "Asynchronous operations"; `TaskService.json` | `lib/features/firmware/firmware_service.dart` + `lib/features/power/power_service.dart` read `Location`, store the task URI, do **not** poll | tests cover 202+`Location` acceptance | Partial/GAP: #008/#020 (firmware), #022 (power) |
| bmcweb `EventService`: `SubmitTestEvent`, `DeliveryRetryAttempts` (default 3), `DeliveryRetryIntervalSeconds`, `EventFormatTypes`, `SSEFilterPropertiesSupported` | OpenBMC `Redfish.md` §EventService | not implemented | — | vendor row (bmcweb) |
| bmcweb `TaskService`: `CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, `Tasks` collection | OpenBMC `Redfish.md` §TaskService | not implemented (202 accepted only) | — | vendor row (bmcweb) |
| Session timeout handling (`SessionService.SessionTimeout`) | DSP0266 §12.4; `SessionService.json` | `lib/redfish/models/session.dart` (expiry) | `test/redfish/client/auth_manager_test.dart` | OK |
| bmcweb firmware update: `HttpPushUri` / `MultipartHttpPushUri` upload (no `SimpleUpdate` action) | OpenBMC `Redfish.md` §UpdateService (bmcweb `27e0930b`); `UpdateService.v1_17_1.json` `MultipartHttpPushUri` | `UpdateServiceInfo` exposes `httpPushUri` **and** `multipartHttpPushUri` (DOCS-9); `startSimpleUpdate` POSTs `#UpdateService.SimpleUpdate` — **will not match bmcweb** | unit: `test/features/firmware/firmware_model_test.dart` (+3 DOCS-9: multipart parse, absent fallback, copyWithInventory); emulator: `emulator_suite_test.dart` asserts `UpdateServiceInfo.httpPushUri == '/FWUpdate'` on the DMTF mockup | Partial: push *upload path* still #008/#020, but both push URIs now surfaced |
| bmcweb reset types: `ResetActionInfo` ActionInfo (`Parameters/AllowableValues`) instead of system-level `SupportedResetTypes` | OpenBMC `Redfish.md` §ComputerSystem (`ResetActionInfo` resource) | `FeatureRules.supportedResetTypes` reads `SupportedResetTypes` directly | `feature_rules_test.dart` | Partial: empty list on bmcweb → power UI treats empty as "all allowed" (safe), but the true allow-list is not surfaced; add ActionInfo fallback in #022/#016 |
| bmcweb serial console lives on the ComputerSystem (`SerialConsole/SSH|IPMI`), not the Manager | OpenBMC `Redfish.md` §ComputerSystem (`SerialConsole` fields) | `FeatureRules._managerConsoleType` only checks `Manager.GraphicalConsole/SerialConsole/Oem` | `feature_rules_test.dart` | Partial: GraphicalConsole detection still correct; System-level SerialConsole not yet mapped (see #009/#021 KVM) |
| bmcweb auth surface: `AccountService.Oem.OpenBMC.AuthMethods.*` (`BasicAuth`, `Cookie`, `SessionToken`, `TLS`, `XToken`) + `HTTPBasicAuth` | OpenBMC `Redfish.md` §AccountService | `AuthManager` prefers session, falls back to basic | `test/redfish/client/auth_manager_test.dart` | Partial: vendor auth-method negotiation is #015/#026 |
| bmcweb telemetry: `TelemetryService` with `MetricReports` / `Triggers` / `MetricReportDefinitions` | OpenBMC `Redfish.md` §TelemetryService | n/a — sensors poll `Thermal`/`Sensors` directly | sensors tests | Note: alternative telemetry source for #007/#019 |
| Log service: `ComputerSystem.LogServices` → `LogService` (`ClearLog` action, `ServiceEnabled`) → `Entries` collection; `LogEntry` (`EntryType` SEL/Event, `Severity`, `Created` RFC3339, `Message`, `Links.OriginOfCondition`); `@odata.nextLink` pagination | `LogService.json` + `LogService.v1_9_0.json` + `LogEntry.json` + `LogEntry.v1_22_0.json` + `LogEntryCollection.json` (mirrored DOCS-11; `LogEntry.v1_16_0.json` kept for the mockup's pinned shapes); DSP0266 §9.6.12 (`Members@odata.nextLink`) + §9.6.11 (`Members`) define the paginated collection contract; emulator pins LogService.v1_6_0 + LogEntry.v1_16_0 shapes | not implemented — no log reader feature yet (future #010 hardening / diagnostics) | emulator: `emulator_suite_test.dart` "log service" group asserts collection → ClearLog target → Entries fields + nextLink (`\u0024skiptoken`) | Contract pin only; feature work not queued — revisit via FUTUREWORK if a log view is planned |

## Trace notes

- The 16 base aggregator schemas under `redfish/schemas/v1/` are the DMTF
  "latest" entry points the app maps; versioned definitions live upstream and are
  re-resolvable via the index listing (`v1-index.html`).
- GAP rows are tracked in `FUTUREWORK.md`; do not re-file them in the issue
  tracker unless acceptance criteria are added.
- bmcweb-specific behaviour (OEM schemas, console types) is cited from
  `redfish/openbmc/OEM_SCHEMAS.md` + `Redfish.md` — vendor behaviour, not DMTF.
- **Test platforms:** beyond unit/widget tests, the project has two integration
  layers against authentic DMTF payloads:
  1. `test/integration/discovery_mock_test.dart` — in-process HTTP mock server
     (`test/helpers/mock_redfish_server.dart`), runs in plain `flutter test`.
  2. `test_integration/emulator/emulator_suite_test.dart` — real DMTF
     Redfish-Mockup-Server over HTTPS (self-signed, test-only TLS) via
     `tool/emulator/run_tests.sh` (pin `23d21f9a`); skipped unless
     `REDFISH_EMULATOR_URL` is defined. 32 tests: service root + BFS discovery
     + discoverable `SessionService` URI (#017), sensors (Thermal + 41-member
     Sensors collection #007/#019), firmware inventory + `HttpPushUri` +
     SimpleUpdateActionInfo (#008/#020), KVM console, systems detail
     (ComputerSystem inventory fields + `ResetType@Redfish.AllowableValues`),
     managers detail (console capabilities + manager-level Reset allow-list,
     DOCS-4/#022), chassis detail (inventory + Thermal/Power sub-resource chain
     + system link), session + basic auth, power state/reset, 404/405 error
     mapping, session lifecycle + SessionTimeout (#015/#017), TaskService +
     EventService contracts (DOCS-7), query capabilities (#018), Accounts
     collection (#015/#026), HttpPushUriApplyTime modes (#008/#020),
     **OverviewService end-to-end hydration (#006: identity/health/power/
     processor-memory summaries/indicator-LED/leading-thermal), LogService +
     LogEntry collection incl. ClearLog action + `@odata.nextLink` pagination
     (LogService.v1_6/LogEntry.v1_16 contract, pinned 2026-10-23 06:10), Task
     resource contract (TaskState/TaskStatus/Start-EndTime/Messages;
     PercentComplete absent on the fixture — the #008/#020 poller must treat it
     as unknown) + TaskService CompletedTaskOverWritePolicy/LifeCycle fields
     (pinned 2026-10-23 08:xx).**
  Both cover the rows above end-to-end against authentic payload shapes.

## EMU-5 decision — richer emulator evaluation (2026-10-22)

**Decision: stay on Redfish-Mockup-Server; do not adopt
`DMTF/Redfish-Interface-Emulator` for error-path testing.** Recorded so the
rationale survives.

- **Evaluated:** `DMTF/Redfish-Interface-Emulator` @ `5f51d8a` (tag `1.2.2`),
  cloned to `/tmp`, venv install, run on port 8444 against its built-in
  dynamic mockup.
- **What it does:** serves a real dynamic Redfish service (ServiceRoot,
  Systems `System-1..7`, Chassis, Managers, TaskService); `POST
  /redfish/v1/Systems/System-1/Actions/ComputerSystem.Reset` executes
  `ResetType` and mutates `PowerState`; an invalid `ResetType` returns
  **400** (dynamic 4xx path the static mockup cannot produce).
- **Why we stay on the mockup server:**
  1. **Error bodies are non-conformant.** The emulator's 400 response is
     `{"error": "Invalid ResetType: Bogus"}` — no DSP0266 `error` envelope
     (`{"error":{"code","message","@Message.ExtendedInfo"}}`), no
     `@Message.ExtendedInfo`, and a `{"Status","Message"}` shape in
     `emulator.py:error_response` instead. Testing error *mapping* against it
     would encode the wrong contract (#014's fixtures must be spec-conformant).
  2. **SessionService is broken/mismatched.** `POST
     /redfish/v1/SessionService/Sessions` returns 404 and the resource
     self-describes as `#Session.0.94.0.SessionCollection` at a
     `/rest/v1/...` context — auth coverage would regress vs. the mockup
     server (which mints tokens and honours logout).
  3. **Overlap + risk.** The static mockup already covers discovery, sensors,
     firmware, KVM, power, and 404 mapping; the only gap is spec-conformant
     extended-info bodies, which are better exercised with unit fixtures
     (spec text pinned in DSP0266 § "Response messages") than with another
     HTTP layer.
- **Fallback for #014/#015 error paths:** `test/redfish/models/` +
  `test/redfish/client/` unit fixtures with compliant `{"error":{...}}`
  bodies; the emulator suite keeps asserting 404 mapping end-to-end.
- Pin recorded: `DMTF/Redfish-Interface-Emulator` `5f51d8a` (evaluated only;
  no committed harness).

## DOCS-7 decision — event subscriptions / SSE (2026-10-22)

**Decision: implement later, not this milestone.** Recorded here so the rationale
survives and the FUTUREWORK item stays actionable.

- **Spec basis:** DSP0266 §12.1.1–§12.1.5: services *shall* support push eventing
  for all event-capable resources, require an explicit subscription before
  pushing, and subscriptions persist across service restarts. §12.1.2 mandates
  201 + `Location` on subscription POST and DELETE-to-unsubscribe. §12.1.3
  (SSE via `EventService.ServerSentEventUri`) is a *may* for services.
- **Why out-of-scope now:**
  1. No consumer: the capability-gated UI has no event-driven surface; telemetry
     is poll-based (#007/#019) and firmware tasks are 202-accepted but not
     polled (#008/#020). Adding a subscriber with no receiver is dead code.
  2. No transport: `pubspec.yaml` has only `dio`; an SSE client (streaming GET or
     a package) would be a new dependency for a one-off effect — discouraged by
     the UI workstream rules until justified by a consumer.
  3. No verification target: the static mockup fixture cannot push events; an
     SSE/webhook test bed would need the richer emulator (EMU-5) or a live BMC
     (blocked, needs credentials).
- **What we promise instead:** telemetry (#007/#019), firmware task monitoring
  (#008/#020), and power task handling (#022) stay poll-based and are the
  natural place to *revisit* events once a receiver exists; revisit this decision
  when any of those land.

## bmcweb field notes (2026-10-22)

The bmcweb `EventService` implements a superset of the DMTF minimum:
`SubmitTestEvent`, `DeliveryRetryAttempts` (default 3),
`DeliveryRetryIntervalSeconds`, `EventFormatTypes`, `RegistryPrefixes`,
`ResourceTypes`, `SSEFilterPropertiesSupported`, `Subscriptions`
(`EventDestinationCollection` with `Destination` / `EventTypes` / `Context` /
`HeartbeatIntervalMinutes` / `OriginResources` / `Protocol`). Its `TaskService`
exposes `CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, and
`Tasks`. Any future subscription client should target the bmcweb field set
(audited in `openbmc/Redfish.md` §EventService / §TaskService, commit
`0128851e` → now `27e0930b`).

## DOCS-4 — bmcweb feature-detection diff audit (2026-10-22)

Audited OpenBMC bmcweb's `docs/Redfish.md` (field sets per resource),
`docs/REDFISH_CHECKLIST.md` (contributor process, no client-facing fields), and
`docs/OEM_SCHEMAS.md` (OEM policy) against the client's discovery rules
(`FeatureRules`). Results, cited rows in the table above:

1. **KVM OEM false-positive — fixed this run.** `FeatureRules._managerConsoleType`
   treated *any* `Oem` map as a console (`kvmType='Oem'`). bmcweb Managers
   always carry an `Oem` block for vendor metadata (Redfish.md Manager field
   list), so KVM would have reported available on every real OpenBMC system even
   with no console. The rule now only returns `Oem` when the block contains a
   console-like structure (`*console*` / `*kvm*` key, recursive, depth ≤ 3).
   Tests: `feature_rules_test.dart` (bare-Oem rejected, `Kvm`/`GraphicalConsole`
   markers accepted).
2. **bmcweb firmware update is HTTP-push, not `SimpleUpdate`.** Redfish.md
   §UpdateService lists `HttpPushUri`, `HttpPushUriOptions`, `MaxImageSizeBytes`,
   `MultipartHttpPushUri`, `ServiceEnabled`, `FirmwareInventory` — no
   `SimpleUpdate` action. `FirmwareService.startSimpleUpdate` targets
   `#UpdateService.SimpleUpdate` and would 405 on OpenBMC; #008/#020 must add the
   push path (`HttpPushUri` PUT or `MultipartHttpPushUri` multipart).
3. **bmcweb reset types via `ResetActionInfo`.** The ComputerSystem section
   documents a `ResetActionInfo` ActionInfo resource
   (`Parameters/AllowableValues`); there is no system-level
   `SupportedResetTypes` listed. Our reader only checks `SupportedResetTypes`;
   on bmcweb the list is empty (UI safely treats empty as all-allowed). Add an
   ActionInfo fallback (fold into #022/#016).
4. **Serial console placement.** bmcweb documents serial console on the
   *ComputerSystem* (`SerialConsole/SSH|IPMI`), not on the Manager. Manager-level
   `GraphicalConsole` detection (the primary KVM signal) remains correct; system
   serial console is not yet mapped (relevant to #009/#021).
5. **Auth + telemetry vendor surface.** `AccountService.Oem.OpenBMC.AuthMethods.*`
   (BasicAuth/Cookie/SessionToken/TLS/XToken) is the bmcweb auth negotiation
   surface (#015/#026); `TelemetryService` is an alternative sensor source
   (#007/#019). Both recorded as vendor rows.

## DOCS-5 — `SystemFeatures` flag → spec citation → test map (2026-10-22)

Every flag the discovery engine emits is traced to the authoritative source and
a test. This is the per-flag table FUTUREWORK DOCS-5 asked for; the flags are
defined in `lib/redfish/models/system_features.dart`, computed by
`lib/redfish/discovery/feature_rules.dart`, and asserted in
`test/redfish/discovery/feature_rules_test.dart` +
`test/redfish/discovery/discovery_engine_test.dart`.

| Flag | Meaning | Source | Rule | Test |
|---|---|---|---|---|
| `powerControl` | `Systems[*].Actions.#ComputerSystem.Reset` present | DSP0266 §12.2 "Actions"; `ComputerSystem.json` (`Actions`) | `FeatureRules.powerControl` | `feature_rules_test.dart` "powerControl true/false" |
| `supportedResetTypes` | union of `SupportedResetTypes` across systems | DSP0266 `ComputerSystem.json`; OpenBMC `Redfish.md` §ComputerSystem (bmcweb uses `ResetActionInfo` instead — DOCS-4, gap #022/#016) | `FeatureRules.supportedResetTypes` | `feature_rules_test.dart` "unions across systems and sorts" |
| `kvm` | any Manager exposes enabled console (`GraphicalConsole` / `SerialConsole` / strict OEM console) | DSP0266 `Manager.json`; OpenBMC `Redfish.md` §Manager + OEM_SCHEMAS (DOCS-4: bare `Oem` is vendor metadata, not a console) | `FeatureRules.kvm` / `_managerConsoleType` | `feature_rules_test.dart` "detects GraphicalConsole", "ignores bare Oem", "Oem Kvm marker" |
| `kvmType` | first detected console kind (`GraphicalConsole`/`SerialConsole`/`Oem`) | same as `kvm` | `FeatureRules.kvmType` | same tests |
| `sensorMonitoring` | any `Chassis[*].(Thermal \|\| Sensors \|\| Power)` link | DSP0266 §8.10; `Chassis.json` | `FeatureRules.sensorMonitoring` | `feature_rules_test.dart` "sensorMonitoring true via Thermal link" |
| `sensorCount` | temps + fans + voltages + sensor members | DSP0266 `Thermal.json` / `Sensor.json` | `FeatureRules.sensorCount` | `feature_rules_test.dart` "sums temperatures + fans + voltages + sensor members" |
| `firmwareUpdate` | `UpdateService` present **and not explicitly disabled** | DSP0266 `UpdateService.json` `ServiceEnabled` ("This property shall indicate whether this service is enabled"); OpenBMC `Redfish.md` §UpdateService lists `ServiceEnabled` | `FeatureRules.firmwareUpdate` (honors `ServiceEnabled` — **fixed this run**) | `feature_rules_test.dart` "firmware_update presence…" + "firmwareUpdate honors ServiceEnabled (DOCS-5)"; `discovery_engine_test.dart` happy path |
| `updateServiceVersion` | `Version` → `Id` fallback (vendor `FirmwareVersion` in OpenBMC fixture) | DMTF `UpdateService.v1_13_0.json` — **no** `FirmwareVersion` property (vendor field in the OpenBMC fixture only); `Id` is the conformant fallback | `FeatureRules.updateServiceVersion` | `feature_rules_test.dart` "version preference"; `discovery_engine_test.dart` expects `2.14.0` from the OpenBMC fixture |
| `managers` | count of discovered `Manager` resources | DSP0266 §8.3 ServiceRoot `Managers` link | `DiscoveryEngine._crawl` (classify) | `discovery_engine_test.dart` "discovers the full capability map" (`managers == 1`) |
| `chassis` | count of discovered `Chassis` resources | DSP0266 §8.3 ServiceRoot `Chassis` link | `DiscoveryEngine._crawl` (classify) | `discovery_engine_test.dart` ("`chassis == 1`") |

Findings folded into code this run:

1. **`firmwareUpdate` now honors `ServiceEnabled`.** `FeatureRules.firmwareUpdate`
   treated any `UpdateService` resource as capability. The DMTF schema declares
   `ServiceEnabled` "shall indicate whether this service is enabled" and bmcweb
   advertises it on UpdateService (`Redfish.md` §UpdateService), so an explicitly
   disabled service must not surface the Firmware tab or the overview "Firmware
   update" chip. Missing/`null` stays enabled (conformant services may omit it).
   Tests: `feature_rules_test.dart` "firmwareUpdate honors ServiceEnabled
   (DOCS-5)".
2. **`updateServiceVersion` fallback is conformant.** The DMTF `UpdateService`
   schema has no `FirmwareVersion` property — that value in the OpenBMC fixture
   is vendor-only. The model's `Version` → `Id` fallback is correct; no change.

UI-3 increment this run: FirmwareView responsive-layout tests at 320/800/1300 px
(`firmware_widget_test.dart`, same `pumpAtWidth` pattern as PowerView /
SensorsView); no production layout change (view already wraps — regression
protection added).

## DOCS-2 — versioned-schema refresh audit (2026-10-22)

DMTF schema index (`https://redfish.dmtf.org/schemas/v1/`, fetched 2026-10-22
21:45 UTC) showed six versioned definition files advanced upstream since the
2026-10-21 mirror snapshot. Refreshed them in `test/fixtures/redfish/schemas/`
and `documentations/external/redfish/schemas/v1/` (provenance + hashes in
`documentations/external/README.md` "DOCS-2 refresh").

| Schema (new) | Old fixture | Client impact | Trace |
|---|---|---|---|
| `ComputerSystem.v1_29_0` | v1_28_0 | `ProductionDate` + new graphical-console actions `GraphicalConsoleGetOneTimeURL`/`SetOneTimePassword`/`SetPassword` + `ConsoleAccessMode` enum. Client reads neither; KVM detection uses Manager `GraphicalConsole` (unchanged). No code change. | `lib/redfish/discovery/feature_rules.dart` (`kvm` via Manager console); REQ row "kvm" |
| `Chassis.v1_29_0` | v1_28_0 | `ProductionDate`; ChassisType `OpenRack`/`OpenRackWide` added, `OpenU` deprecated. Client maps ChassisType as free string. No code change. | `lib/redfish/...` chassis parse (free-string) |
| `Sensor.v1_14_0` | v1_13_0 | ReadingType `Turbidity`/`LiquidConductivity`/`pH`; `Oem` on Sensor. Client stores `ReadingType` as string and renders units generically. No code change. | `lib/features/sensors/models/sensor_models.dart` (`readingType`, `ReadingUnits` generic) |
| `AccountService.v1_19_0` | v1_18_1 | New read-only `KerberosKeytabSet`/`PasswordSet`/`TokenSet`; LDAP STARTTLS note. #015 AuthManager doesn't parse these (basic-session flow). No code change. | `lib/redfish/...auth*`; REQ "bmcweb AuthMethods" vendor row |
| `EthernetInterface.v1_12_6` | v1_12_5 | SLAAC wording clarified (IPv4 link-local). Client exposes ethernet info read-only. No code change. | `lib/features/...ethernet*` |
| `SoftwareInventory.v1_15_0` | v1_14_0 | New `ImageState` enum + `ActiveTargets`/`StagedTargets`/`ArmedTargets` links — relevant when #008/#020 firmware task timeline lands. No code change. | `lib/features/firmware/...`; REQ "firmware inventory" row |

Superseded versioned files are retained for history (mirror manifest notes
this). No test fixture references the old versioned filenames, so the refresh
is purely additive; full `flutter test` stays green. Remaining DOCS-2 scope:
the 2026-10-21 `dmtf_mockup` payload snapshot itself still matches upstream
(mockup server pinned `23d21f9a`, unchanged), so no mockup refresh was needed
this run.

## DOCS-8 — upstream-freshness audit (2026-10-22)

Full re-verification of every mirrored upstream anchor against live sources
(schema index, DSP0266, bmcweb, mockup server). Used to decide whether any
mirror file or fixture needs a refresh; provenance + hashes in
`documentations/external/README.md` "DOCS-8 upstream-freshness audit".

1. **All 13 schema families current.** Live scan of
   `https://redfish.dmtf.org/schemas/v1/` (14,259 entries, 3.4 MB listing)
   compared against `test/fixtures/redfish/schemas/` +
   `documentations/external/redfish/schemas/v1/`: AccountService 1_19_0,
   Chassis 1_29_0, ComputerSystem 1_29_0, EthernetInterface 1_12_6,
   EventService 1_12_0, LogService 1_9_0, Manager 1_25_0, Power 1_7_3,
   Sensor 1_14_0, SessionService 1_2_0, SoftwareInventory 1_15_0,
   Thermal 1_7_3, UpdateService 1_17_1 — **no version advanced** since the
   DOCS-2 refresh. No fixture change.
2. **DSP0266 still 1.25.0.** The hub-linked PDF fetches 200 with identical
   content-length (1,243,359 bytes); a probe for `DSP0266_1.26.0.pdf` returns
   404. No spec refresh.
3. **Mockup server pinned at HEAD.** `DMTF/Redfish-Mockup-Server` master is
   still `23d21f9a` — the pinned commit. No mockup fixture change.
4. **bmcweb master moved `0128851e` → `27e0930b`** (3 commits: `http/parsing`,
   `redfish-core/lib/update_service.hpp` [+tests], `time_utils`). No `docs/`
   files changed between the two SHAs; the three mirrored docs are
   byte-identical (same SHA-256s). Pin updated in the manifest + this header.
   The `update_service.hpp` change is noted as upstream context for #008/#020
   (firmware update service internals) — no client-facing contract delta.
5. **`docs/CLIENTS.md` mirrored (new).** Official bmcweb client-compatibility
   doc: lists the DMTF Redfish-Service-Validator / Protocol-Validator,
   python-redfish-library, Redfish-Tacklebox, redfishtool, fwupd, and
   Redfish-Event-Listener. Client-facing value: pins which reference tools the
   service must interop with (a future test bed can reuse
   Redfish-Service-Validator against our emulator harness). 2,695 bytes —
   within DOCS-6 budget.
6. **Not mirrored (decision):** `docs/COMMON_ERRORS.md` (bmcweb C++ pointer /
   string-view traps for contributors) and `docs/HEADERS.md` (build-time header
   architecture) are internal contributor docs with no client-facing Redfish
   contract. Skipping avoids junk in the corpus; recorded so the next audit
   does not re-evaluate them.
