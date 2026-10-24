# Redfish Requirement Traceability

Maps audited Redfish / OpenBMC requirements to the client implementation and its
tests. Source citations point at the mirrored corpus in
`documentations/external/redfish/` (see `README.md` manifest for hashes) or the
live DMTF URLs. Status legend: `OK` (implemented + tested), `GAP` (known gap,
tracked in `FUTUREWORK.md`), `N/A` (not applicable to this client).

Last audited: 2026-10-24 (DOCS-18 run — mirrored the **message-registry payload**
the pinned mockup serves: `Base.1.5.0.json` from the DMTF registries path,
**byte-identical** (SHA-256 `c1026341…`) to
`test/fixtures/redfish/dmtf_mockup/Registries/Base.1.5.0.json` — proven
authentic — plus the newest published `Base.1.24.0.json` (125 templates; 1.5.0
→ 1.24.0 adds 65 templates + rewords 39 shared Message strings with
`NumberOfArgs` stable, the emulator-pinned contract); the §8.6/§11.4 rows below
now cite a real mirror file; UI-2 Dashboard `_ErrorSummary` card merged
semantics `Unable to reach N systems` + separate Retry control).
Prior: DOCS-17 run — audited the DSP0266 §13.3.4.3
"Session lifetime" contract against the mirrored `SessionService.json` +
`SessionService.v1_2_0.json` (DOCS-12); pinned the timeout contract with the
new `Session.expiryFromService` model helper + 6 unit tests — `SessionTimeout`
(inactivity TTL) is applied, `AbsoluteSessionTimeout` +
`AbsoluteSessionTimeoutEnabled` (added v1_2_0) optionally bound the deadline to
the *earlier* of the two so the client re-authenticates before the service can
kill the session; the session-timeout trace row below is now model-level OK and
the AuthManager wiring stays #015; UI-2 FirmwareView error state merged
semantics `Unable to load firmware. <message>` + separate Retry control).
Prior: DOCS-16 run — corrected the DSP0266 clause
citations that pointed at an older spec layout against the mirrored
`DSP0266_1.25.0.pdf`: `§8.3 Service Root` → `§7.2.3`, `§8.4/§8.10/§8.14`
resource clauses → schema files + `§9.x` data-model clauses, `§12.2 Actions`
→ `§9.6.14`+`§7.11`, `§12.3 Basic auth` → `§13.3.3`, `§12.4 Sessions` →
`§13.3.4`, `§12.7 Error responses` → `§8.6`, `§9.7 Firmware update` →
`§12.7`; pinned the DSP0266 §9.9 payload-annotation contract with unit tests
(`ResetType@Redfish.AllowableValues` list parse + unrecognized-annotation
tolerance §9.9.1); UI-2 OverviewView error-state merged semantics.
Prior: DOCS-15 run — audited DSP0266 §7.3 "Query parameters"
against the client transport + the emulator-pinned query contract; folded the
normative §7.3.1–§7.3.5 clauses (processing order, `$expand` options incl.
`$levels` default 1 / `MaxLevels`, `$select`, `$filter` operators + precedence,
`clientcontext`, 400/501/507 semantics) into the audit table below; the #018
discovery pass must gate `$expand` on `ProtocolFeaturesSupported` and filter/
project client-side because the pinned mockup applies `$expand` but not
`$filter`/`$select`; pinned the `getJson` query-forwarding transport contract
with a unit test. Prior: DOCS-13 run — mirrored the missing versioned
definitions for the emulator-pinned auth/network/ActionInfo resources
(`Session`, `ManagerAccount`, `Role`, `ManagerNetworkProtocol`, `ActionInfo`,
plus versioned `ServiceRoot` and mockup-served `Task.v1_7_3`/
`TaskService.v1_2_0`). Prior: DOCS-12 — mirrored the missing **versioned**
definitions for the six
aggregator-only families — `UpdateService`/`EventService`/
`SessionService`/`Manager`/`Power`/`Thermal` — newest + mockup-served versions,
so the rows below now cite real mirror files; no client code change needed
(property deltas audited in the DOCS-12 section). Prior: EMULATOR run pinned the
Task resource contract end-to-end:
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
  `CLIENTS.md` (bmcweb master `fbb307a`, re-verified 2026-10-23 19:20 UTC —
  byte-identical to `27e0930b`)

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
| Service root at `/redfish/v1/` with `Systems`, `Managers`, `Chassis`, `UpdateService`, `SessionService` links | DSP0266 §7.2.3 "Service root request"; `ServiceRoot.json` | `lib/redfish/discovery/discovery_engine.dart` (`_crawl`, root seed `redfish/v1/`) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| `@odata.id` link traversal is cycle-safe and depth-bounded (≤3) | DSP0266 §9.6.2 "@odata.id property" + §9.1 "Resources"; `odata.4.0.0.json` (mirrored DOCS-14; the bare `Odata.json` 404s upstream) | `lib/redfish/discovery/discovery_engine.dart` (visited `Set<uri>`, maxDepth) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| Feature detection "nothing is assumed": every UI feature gated on discovered capability | OpenBMC `Redfish.md`; DSP0266 §9.1 "Resources" (resource tree traversal) | `lib/redfish/discovery/feature_rules.dart` → `SystemFeatures` | `test/redfish/discovery/feature_rules_test.dart` | OK |
| Conditional GET re-crawl via `If-None-Match` / ETag (304 short-circuit) | DSP0266 §6.5 "ETags" + §7.2 "GET (read requests)"; `ComputerSystem.json` | `lib/redfish/discovery/discovery_engine.dart` (`_fetchUri` etag map) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| PATCH write support with `If-Match` / `@odata.etag` | DSP0266 §6.5 "ETags" (weak/strong validation, RFC7232); §7.6 "PATCH (update)" | **not implemented** | — | GAP: #016 |
| Error envelope: `error.code`, `error.message`, `error.@Message.ExtendedInfo[]`; message templates from the published `Base.*` MessageRegistry | DSP0266 §8.6 "Error responses" + §11.4 "Message registries"; `redfish_error.md`; `registries/Base.1.5.0.json` + `registries/Base.1.24.0.json` (mirrored DOCS-18 — the 1.5.0 payload is byte-identical to the pinned mockup's, so the emulator-pinned `Base.*` templates resolve against a real mirror file) | `lib/redfish/models/redfish_error.dart` | `test/redfish/models/models_test.dart`; emulator MessageRegistry group pins the Base.1.5.0 discovery + template surface | OK (see #014: ExtendedInfo parsing hardening) |
| Session auth: `POST SessionService/Sessions` → `X-Auth-Token`, session reuse | DSP0266 §13.3.4 "Redfish session login authentication"; `SessionService.json` + `SessionService.v1_2_0.json` (newest, DOCS-12) | `lib/redfish/client/auth_manager.dart` | `test/redfish/client/auth_manager_test.dart` | OK (see #015: discover session URI instead of hardcoding) |
| Basic auth fallback | DSP0266 §13.3.3 "HTTP Basic authentication" | `lib/redfish/client/auth_manager.dart` | `test/redfish/client/auth_manager_test.dart` | OK |
| No plaintext password at rest; token in secure storage | DSP0266 §13.3.4 + §13.2 "Sensitive data"; OpenBMC `Redfish.md` | `lib/core/storage/secure_storage.dart`, `AuthManager` | `test/redfish/client/auth_manager_test.dart` | OK |
| Power control: `ComputerSystem.Reset` action with `ResetType` body; 202+`Location` accepted | DSP0266 §9.6.14 "Actions property" + §7.11 "POST (action)"; `ComputerSystem.json` `Actions` | `lib/features/power/power_service.dart` | `test/features/power/` | OK |
| Sensor telemetry: `Chassis[*].Thermal` / `Sensors`, reading + units | DSP0266 §9.6.15 `Oem`/§9.1 links; schema contracts in `Sensor.json` + `Thermal.json` + `Thermal.v1_7_3.json` (newest, DOCS-12); DSP0266 does not enumerate per-resource schemas — the schema files are the normative property source | `lib/features/sensors/sensors_controller.dart` | `test/features/sensors/` | OK |
| System overview: `ComputerSystem` identity (`Manufacturer`/`Model`/`SKU`/`SerialNumber`/`PartNumber`/`BiosVersion`), `PowerState`, `Status.Health`(+Rollup), `ProcessorSummary`/`MemorySummary`, `IndicatorLED`, leading `Chassis` thermal | DSP0266 §9.1 "Resources" + §9.6 "Properties"; schema contracts in `ComputerSystem.v1_29_0.json` + `Thermal.v1_7_3.json` (DSP0266 does not carry per-resource property lists) | `lib/features/overview/overview_service.dart` (+ `models/system_overview.dart`) hydrates system + best-effort chassis thermal | `test/features/overview/overview_provider_test.dart` + `overview_view_test.dart`; **emulator suite now pins the full hydrate end-to-end** against the DMTF mockup (#006) | OK |
| Firmware inventory: `UpdateService` / `SoftwareInventory` collection | DSP0266 §12.7 "Update service" + §7.2.2 "Resource collection requests"; `SoftwareInventory.json` (schema contract) | `lib/features/firmware/firmware_models.dart` | `test/features/firmware/` | OK |
| Firmware update: `UpdateService.SimpleUpdate` (entity-upload mode TBD); `UpdateService.ServiceEnabled` gates the capability | DSP0266 §12.7 "Update service" (§12.7.2.1 "Simple updates"); `UpdateService.json` (`ServiceEnabled`) + `UpdateService.v1_17_1.json` (newest, DOCS-12); OpenBMC `Redfish.md` §UpdateService | `lib/features/firmware/firmware_service.dart`; `FeatureRules.firmwareUpdate` honors `ServiceEnabled` (DOCS-5) | `test/features/firmware/`; `feature_rules_test.dart` (ServiceEnabled case) | Partial — task monitoring in #008/#020 |
| KVM capability: `Manager.GraphicalConsole` / OEM console detection | OpenBMC `Redfish.md`; `Manager.json` + `Manager.v1_25_0.json` (newest, DOCS-12) | `lib/redfish/discovery/feature_rules.dart` (`kvm`, `kvmType`) | `test/redfish/discovery/feature_rules_test.dart` | OK (rendering gated in #009/#021) |
| Event subscription: `EventService.Subscriptions` — POST → 201 + `Location`; DELETE to unsubscribe | DSP0266 §12.1.1–§12.1.2 "Eventing"; `EventService.json` + `EventService.v1_12_0.json` (newest, DOCS-12) | **not implemented** | — | GAP: DOCS-7 — decision recorded below (out-of-scope this milestone) |
| SSE event stream: GET `EventService.ServerSentEventUri` | DSP0266 §12.1.3 "Open an SSE connection"; `EventService.v1_6_9+` | **not implemented** (no SSE transport dependency in `pubspec.yaml`) | — | GAP: DOCS-7 — revisit when telemetry/eventing lands (#007/#019) |
| EventType-based eventing deprecated; filter subscriptions by `RegistryPrefixes` / `ResourceTypes` / `MessageIds` | DSP0266 §12.1.4–§12.1.5 | n/a (no subscriber yet) | — | Note for a future implementation |
| Task monitor: 202 + `Location` + optional `Retry-After`; GET monitor → 202 while running, then final status + body; DELETE cancels; 404/410 after completion | DSP0266 §12.2 "Asynchronous operations"; `TaskService.json` | `lib/features/firmware/firmware_service.dart` + `lib/features/power/power_service.dart` read `Location`, store the task URI, do **not** poll | tests cover 202+`Location` acceptance | Partial/GAP: #008/#020 (firmware), #022 (power) |
| bmcweb `EventService`: `SubmitTestEvent`, `DeliveryRetryAttempts` (default 3), `DeliveryRetryIntervalSeconds`, `EventFormatTypes`, `SSEFilterPropertiesSupported` | OpenBMC `Redfish.md` §EventService | not implemented | — | vendor row (bmcweb) |
| bmcweb `TaskService`: `CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, `Tasks` collection | OpenBMC `Redfish.md` §TaskService | not implemented (202 accepted only) | — | vendor row (bmcweb) |
| Session timeout handling (`SessionService.SessionTimeout` + v1_2_0 `AbsoluteSessionTimeout`/`AbsoluteSessionTimeoutEnabled`) | DSP0266 §13.3.4.3 "Session lifetime"; `SessionService.json` + `SessionService.v1_2_0.json` (newest, DOCS-12) | `lib/redfish/models/session.dart` — `Session.expiryFromService` computes the conservative *earlier* deadline (`createdAt + min(SessionTimeout, AbsoluteSessionTimeout)` when the absolute timeout is enabled, else `SessionTimeout`) — DOCS-17 | `test/redfish/models/models_test.dart` (+6 DOCS-17 expiry tests); emulator `SessionService.SessionTimeout == 30` published (#015) | Partial: model-level contract pinned; AuthManager has no SessionService fetch yet — wiring expiry into login is #015 |
| bmcweb firmware update: `HttpPushUri` / `MultipartHttpPushUri` upload (no `SimpleUpdate` action) | OpenBMC `Redfish.md` §UpdateService (bmcweb `27e0930b`); `UpdateService.v1_17_1.json` `MultipartHttpPushUri` | `UpdateServiceInfo` exposes `httpPushUri` **and** `multipartHttpPushUri` (DOCS-9); `startSimpleUpdate` POSTs `#UpdateService.SimpleUpdate` — **will not match bmcweb** | unit: `test/features/firmware/firmware_model_test.dart` (+3 DOCS-9: multipart parse, absent fallback, copyWithInventory); emulator: `emulator_suite_test.dart` asserts `UpdateServiceInfo.httpPushUri == '/FWUpdate'` on the DMTF mockup | Partial: push *upload path* still #008/#020, but both push URIs now surfaced |
| bmcweb reset types: `ResetActionInfo` ActionInfo (`Parameters/AllowableValues`) instead of system-level `SupportedResetTypes` | OpenBMC `Redfish.md` §ComputerSystem (`ResetActionInfo` resource) | `FeatureRules.supportedResetTypes` falls back to the `ResetType@Redfish.AllowableValues` annotation on `#ComputerSystem.Reset` (DOCS-4/13 fix, run 2026-10-23) | `feature_rules_test.dart` "falls back to the ResetType@Redfish.AllowableValues annotation" + "never reads the manager-level guard" | OK: empty-`SupportedResetTypes` BMCs now surface the true allow-list from the action annotation (mockup + ActionInfo-style); ActionInfo *resource* (`ResetActionInfo`) crawling stays #022/#016 |
| bmcweb serial console lives on the ComputerSystem (`SerialConsole/SSH|IPMI`), not the Manager | OpenBMC `Redfish.md` §ComputerSystem (`SerialConsole` fields) | `FeatureRules._managerConsoleType` only checks `Manager.GraphicalConsole/SerialConsole/Oem` | `feature_rules_test.dart` | Partial: GraphicalConsole detection still correct; System-level SerialConsole not yet mapped (see #009/#021 KVM) |
| bmcweb auth surface: `AccountService.Oem.OpenBMC.AuthMethods.*` (`BasicAuth`, `Cookie`, `SessionToken`, `TLS`, `XToken`) + `HTTPBasicAuth` | OpenBMC `Redfish.md` §AccountService | `AuthManager` prefers session, falls back to basic | `test/redfish/client/auth_manager_test.dart` | Partial: vendor auth-method negotiation is #015/#026 |
| bmcweb telemetry: `TelemetryService` with `MetricReports` / `Triggers` / `MetricReportDefinitions` | OpenBMC `Redfish.md` §TelemetryService | n/a — sensors poll `Thermal`/`Sensors` directly | sensors tests | Note: alternative telemetry source for #007/#019 |
| Log service: `ComputerSystem.LogServices` → `LogService` (`ClearLog` action, `ServiceEnabled`) → `Entries` collection; `LogEntry` (`EntryType` SEL/Event, `Severity`, `Created` RFC3339, `Message`, `Links.OriginOfCondition`); `@odata.nextLink` pagination | `LogService.json` + `LogService.v1_9_0.json` + `LogEntry.json` + `LogEntry.v1_22_0.json` + `LogEntryCollection.json` (mirrored DOCS-11; `LogEntry.v1_16_0.json` kept for the mockup's pinned shapes); DSP0266 §9.6.12 (`Members@odata.nextLink`) + §9.6.11 (`Members`) define the paginated collection contract; emulator pins LogService.v1_6_0 + LogEntry.v1_16_0 shapes | not implemented — no log reader feature yet (future #010 hardening / diagnostics) | emulator: `emulator_suite_test.dart` "log service" group asserts collection → ClearLog target → Entries fields + nextLink (`\u0024skiptoken`) | Contract pin only; feature work not queued — revisit via FUTUREWORK if a log view is planned |

## DOCS-12 — six-family versioned schema mirror audit (2026-10-23)

Closed the "aggregator-only" corpus gap: `UpdateService`, `EventService`,
`SessionService`, `Manager`, `Power`, and `Thermal` had **no versioned
definitions** in the external mirror (`documentations/external/redfish/
schemas/v1/`), even though the client maps them and the fixture snapshot ships
the newest versions. Mirrored, for each family, the **newest** versioned file
(what the aggregator `$ref`s) **and** the **mockup-served** version (what the
pinned `23d21f9a` fixture publishes as `@odata.type`) — the DOCS-11 LogEntry
precedent. 12 files, 553,772 bytes total (inside DOCS-6 budget); SHA-256s in the
manifest (`documentations/external/README.md`). The six mockup-served versions
were also copied into `test/fixtures/redfish/schemas/` so every `@odata.type`
the mockup publishes has a versioned schema in the fixture.

| Family | Newest (mirrored) | Mockup-served (mirrored) | Newest-vs-served notable deltas | Client impact |
|---|---|---|---|---|
| `UpdateService` | `v1_17_1` | `v1_13_0` | `LocalImageStore*` (local image repo), `Stage`/`Activate` actions, `UpdateServiceCapabilities` | none this run — #008/#020 push flow uses `HttpPushUri`/`MultipartHttpPushUri` (parsed since DOCS-9); `SimpleUpdate` remains the entity-upload path for non-bmcweb |
| `EventService` | `v1_12_0` | `v1_10_1` | `OriginResourcesSupported`, `SSEIncludeOriginOfConditionSupported` | none — events out-of-scope (DOCS-7); note for when #007/#019 lands |
| `SessionService` | `v1_2_0` | `v1_1_8` | `AbsoluteSessionTimeout` + `AbsoluteSessionTimeoutEnabled` | #015 could honor absolute timeout when a service publishes it (in addition to `SessionTimeout`) |
| `Manager` | `v1_25_0` | `v1_19_0` | `SecurityMode`/`OEMSecurityMode`, `ReadyToRemove`, `DateTimeSource`, `#Manager.UpdateSecurityMode`, `ServiceUseNotification` | none — KVM detection (`GraphicalConsole`) unchanged |
| `Power` | `v1_7_3` | `v1_7_2` | no property deltas | none |
| `Thermal` | `v1_7_3` | `v1_7_2` | no property deltas | none |

The table rows above now cite the real mirrored files for the six families
(e.g. `SessionService.v1_2_0.json`, `UpdateService.v1_17_1.json`,
`Manager.v1_25_0.json`, `Thermal.v1_7_3.json`). All upstream anchors
re-verified this run (see `documentations/external/README.md`).

## DOCS-13 — auth/network/ActionInfo corpus mirror audit (2026-10-23)

Closed the corpus gap for the resources the emulator pins but the external
mirror had no versioned definitions for. For each family, mirrored the
aggregator + the **newest** versioned file (what the aggregator `$ref`s) + the
**mockup-served** version (what the pinned `23d21f9a` fixture publishes as
`@odata.type`) — the DOCS-11/12 precedent; plus the mockup-served Task-family
versions (`Task.v1_7_3`, `TaskService.v1_2_0`) that DOCS-10 had not mirrored
(DOCS-10 mirrored only the newest `Task.v1_7_4` / `TaskService.v1_2_1`).

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Session resource: `X-Auth-Token` created on session POST; session carries `UserName`/`Password`/`Oem`; session-lifetime contract | DSP0266 §13.3.4 "Redfish session login authentication" (§13.3.4.3 session lifetime / §13.3.4.4 session termination or logout); `Session.json` + `Session.v1_9_0.json` (newest) + `Session.v1_7_1.json` (mockup-served) | `lib/redfish/models/session.dart`, `lib/redfish/client/auth_manager.dart` | `auth_manager_test.dart`; emulator session-lifecycle group pins `#Session.v1_7_1.Session` | OK (see #015/#017/#026 — URI discovery + expiry hardening) |
| ManagerAccount (user account): `UserName`, `RoleId`, `Enabled`, `Password`, `AccountTypes`; Accounts collection under AccountService | `AccountService.json` + `ManagerAccount.json` + `ManagerAccount.v1_14_2.json` (newest) + `ManagerAccount.v1_12_0.json` (mockup-served) | not parsed yet (auth surface TO-BUILD) | emulator AccountService group pins `#ManagerAccount.v1_12_0.ManagerAccount` detail — `AccountTypes`/`PasswordChangeRequired`/`Locked`/`Enabled`/`Links.Role` + `#ManagerAccount.ChangePassword` target, and `Password` masked on the wire (12:xx run) | Partial — #015/#026 |
| Role: `RoleId`, `AssignedPrivileges`, `OemPrivileges`; Roles collection under AccountService | `Role.json` + `Role.v1_3_3.json` (newest) + `Role.v1_3_1.json` (mockup-served) | not parsed yet | emulator Roles group pins the collection (3 predefined roles) + `#Role.v1_3_1.Role` `IsPredefined`/`AssignedPrivileges`/`OemPrivileges` (12:xx run) | Partial — #015/#026 |
| ManagerNetworkProtocol: service endpoint table (`KVMIP` port, `HTTPS`, `SSH`, …) the #009/#021 console renderer resolves | `ManagerNetworkProtocol.json` + `ManagerNetworkProtocol.v1_14_0.json` (newest) + `ManagerNetworkProtocol.v1_10_0.json` (mockup-served) | not parsed yet (console endpoint TO-BUILD) | emulator "manager network" group pins `#ManagerNetworkProtocol.v1_10_0.ManagerNetworkProtocol` KVMIP 5288 / HTTPS 443 / SSH 22 (11:39 run) | Partial — #009/#021 must resolve the endpoint from the advertised KVMIP port |
| ActionInfo: `Parameters[].AllowableValues` (bmcweb `ResetActionInfo` is the reset-type allow-list source on OpenBMC) | OpenBMC `Redfish.md` §ComputerSystem; `ActionInfo.json` + `ActionInfo.v1_6_0.json` (newest) + `ActionInfo.v1_4_1.json` (mockup-served); DSP0266 §9.9.2 "Allowable values for strings" (annotation form) / §9.6.14 "Actions property" | `FeatureRules.supportedResetTypes` falls back to the `ResetType@Redfish.AllowableValues` annotation on `#ComputerSystem.Reset` (DOCS-4/13 fix, run 2026-10-23) | `feature_rules_test.dart` "falls back to the annotation" + "unions + dedupes" + "never reads manager allow-list" | OK (annotation form pinned; `ResetActionInfo` *resource* crawling remains #022/#016) |
| ServiceRoot: service links + `ProtocolFeaturesSupported` (Expand/Excerpt/Filter/Select) the discovery pass must use | DSP0266 §7.2.3 "Service root request" + §7.3.1 "Query parameter overview"; `ServiceRoot.json` + `ServiceRoot.v1_22_0.json` (newest) + `ServiceRoot.v1_16_1.json` (mockup-served) | `lib/redfish/discovery/discovery_engine.dart` + `feature_rules.dart` (root crawl) | `discovery_engine_test.dart`; emulator service-root group pins `#ServiceRoot.v1_16_1.ServiceRoot` | OK (query-capability surface used by #018) |
| Task/TaskService mockup-served versions: `#Task.v1_7_3.Task`, `#TaskService.v1_2_0.TaskService` | `Task.v1_7_3.json` + `TaskService.v1_2_0.json` (mirrored DOCS-13; newest v1_7_4/v1_2_1 from DOCS-10) | `UpdateTask` model (taskUri + retryAfterSeconds) | emulator Task group pins the served shapes (09:14 run) | Partial — #008/#020 poller |

Notable newest-vs-mockup-served deltas (audited, no client code change this
run): `Session.v1_9_0` expands session-type/OEM fields (no field the current
code reads changed); `ManagerAccount.v1_14_2` adds `PasswordExpiration`/
`RemoteRole`/account-types (context for #015/#026); `Role.v1_3_3` no property
deltas; `ManagerNetworkProtocol.v1_14_0` adds `NTPProtocolEnabled`/
`NTPservers[]`/`Kerberos*` (console endpoint resolution unchanged);
`ActionInfo.v1_6_0` adds `ActionCapabilities` + `AllowableValueDescriptions`
(the `Parameters/AllowableValues` contract for #022/#016 is stable);
`ServiceRoot.v1_22_0` adds `Tasks` + link-era changes (`ProtocolFeaturesSupported`
locations stable for #018). The six mockup-served versions + Task/TaskService
served versions were copied into `test/fixtures/redfish/schemas/` so the fixture
has a versioned schema for every `@odata.type` the mockup publishes across these
client-relevant families.

## Trace notes

- The 21 base aggregator schemas under `redfish/schemas/v1/` are the DMTF
  "latest" entry points the app maps; versioned definitions are also mirrored
  under `redfish/schemas/v1/` for every client-mapped family (ComputerSystem,
  Chassis, Sensor, AccountService, EthernetInterface, SoftwareInventory, Task,
  TaskService, LogEntry, LogService + DOCS-12's UpdateService, EventService,
  SessionService, Manager, Power, Thermal + DOCS-13's Session, ManagerAccount,
  Role, ManagerNetworkProtocol, ActionInfo, ServiceRoot), with the
  aggregator-`$ref`ed newest plus the mockup-served versions for emulator
  provenance.
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
     `REDFISH_EMULATOR_URL` is defined. 45 tests: service root + BFS discovery
     + discoverable `SessionService` URI (#017), sensors (Thermal + 41-member
     Sensors collection #007/#019), firmware inventory + `HttpPushUri` +
     SimpleUpdateActionInfo (#008/#020), KVM console, systems detail
     (ComputerSystem inventory fields + `ResetType@Redfish.AllowableValues`),
     managers detail (console capabilities + manager-level Reset allow-list,
     DOCS-4/#022), chassis detail (inventory + Thermal/Power sub-resource chain
     + system link), session + basic auth, power state/reset, 404/405 error
     mapping, session lifecycle + SessionTimeout (#015/#017), TaskService +
     EventService contracts (DOCS-7), query capabilities (#018) incl. a live
     `$expand=.($levels=1)` round-trip pin — the Systems collection inlines
     full bodies (Model/PowerState/Actions.Reset allow-list +
     Processor/MemorySummary) for a lightweight discovery pass (pinned
     2026-10-23 17:xx), Accounts
     collection (#015/#026), HttpPushUriApplyTime modes (#008/#020),
      **query-behavior contract for #018 (pinned 2026-10-23):** `$expand=*`
      (ExpandAll) also inlines full ComputerSystem bodies in one round trip
      (same fields as `$expand=.($levels=1)`), while `$filter`/`$select` are
      **advertised but NOT applied** (the mockup returns the unfiltered Roles
      collection for `$filter=Id eq 'NOPE'` and the full system body for
      `$select=Model`) — the #018 lightweight discovery pass must filter/
      select client-side and rely only on `$expand` for payload shaping,
      **`getJson(path, query:)` map-form `$expand` round-trip pinned live
      (2026-10-23 22:xx)** — the 19:25 transport unit test (query map forwards
      to the wire) + the URL-string pins above are joined: a #018 pass calling
      `getJson('/redfish/v1/Systems', query: {'\$expand': '.($levels=1)'})`
      receives the same inlined full member bodies as the URL-string form,
      **MessageRegistry contract (pinned 2026-10-24 02:xx)** — the service
      root advertises `Registries` -> `MessageRegistryFileCollection`
      (Base.1.5.0) -> `Location[0].Uri` resolves to the `#MessageRegistry`
      JSON defining the 60 Base.* message templates (Message/Severity/
      NumberOfArgs) behind `RedfishError.code`/`firstMessage` (DSP0266 §8.6
      error responses + §11.4 message registries; #014 model),
      **Sessions collection + Session resource contract (#015/#026, pinned
      2026-10-24 03:5x)** — the Sessions collection is enumerable from the
      discovered SessionService URI (members are session resources, never the
      collection; pre-seeded `#Session.v1_7_1` for Administrator carries
      Id/Name/Description/UserName and NO Password), and a **security-relevant
      negative pin**: a session minted via POST resolves to a body that echoes
      the login `Password` and lacks `@odata.type`/SessionType
      (non-conformant — DSP0266 §13.3.4 Session has no Password property); the
      #015 AuthManager must persist the token/location from the create
      RESPONSE HEADERS and never read session-resource bodies for secrets;
      **ResetType validation negative pin (#014/#022, pinned 2026-10-24)** —
      the pinned mockup accepts ANY ResetType body value (Bogus returns 204
      like a valid one), so the client's 400 `ResetTypeInvalid` path stays
      unit-level and the UI must pre-validate against the advertised
      allow-list,
      **UpdateService action surface (#008/#020, pinned 2026-10-24):** (a)
      `FirmwareService.startSimpleUpdate` live round-trip — the mockup
      accepts ANY SimpleUpdate body and answers 204 with NO task-monitor
      `Location`, so the returned `UpdateTask` carries null
      taskUri/retryAfterSeconds (the 202-with-Location monitor path stays
      unit-level; the UI must not require a monitor URI for a queued
      handle); (b) negative pin — the advertised `HttpPushUri` (`/FWUpdate`)
      is NOT implemented: POSTing a binary upload body fails with 400 and an
      EMPTY body (no `@Message.ExtendedInfo` envelope; connection closed;
      GET /FWUpdate 404s), so the #020 binary-push upload flow stays
      unit-level and the client normalizes it as `RedfishException` HTTP 400
      with no error code,
      **OverviewService end-to-end hydration (#006: identity/health/power/
     processor-memory summaries/indicator-LED/leading-thermal), LogService +
     LogEntry collection incl. ClearLog action + `@odata.nextLink` pagination
     (LogService.v1_6/LogEntry.v1_16 contract, pinned 2026-10-23 06:10), Task
     resource contract (TaskState/TaskStatus/Start-EndTime/Messages;
     PercentComplete absent on the fixture — the #008/#020 poller must treat it
     as unknown) + TaskService CompletedTaskOverWritePolicy/LifeCycle fields
     (pinned 2026-10-23 08:xx), Manager NetworkProtocol + EthernetInterfaces
     surface (KVMIP/SSH/HTTPS service endpoints for the #009/#021 KVM console
     renderer + NIC MAC/IP/VLAN fields — pinned 2026-10-23 11:xx), account-
     service auth surface: AccountService lockout/password-policy fields +
     Roles link (AccountService.v1_15_0), Roles collection (3 predefined roles
     Administrator/Operator/ReadOnly with AssignedPrivileges +
     OemPrivileges — Role.v1_3_1), ManagerAccount detail
     (AccountTypes/PasswordChangeRequired/Locked/Enabled/Links.Role +
     #ManagerAccount.ChangePassword target — ManagerAccount.v1_12_0,
     pinned 2026-10-23 12:xx; the #015/#026 auth surface, DOCS-13 schemas).**
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
     (spec text pinned in DSP0266 §8.6 "Error responses") than with another
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
   `SupportedResetTypes` listed. The reader now falls back to the
   `ResetType@Redfish.AllowableValues` annotation on the
   `#ComputerSystem.Reset` action (the form the DMTF mockup + ActionInfo-style
   BMCs publish), so the true allow-list surfaces even when
   `SupportedResetTypes` is empty — fixed 2026-10-23 (run docs). Crawling the
   `ResetActionInfo` *resource* itself stays folded into #022/#016.
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
| `powerControl` | `Systems[*].Actions.#ComputerSystem.Reset` present | DSP0266 §9.6.14 "Actions property"; `ComputerSystem.json` (`Actions`) | `FeatureRules.powerControl` | `feature_rules_test.dart` "powerControl true/false" |
| `supportedResetTypes` | union of `SupportedResetTypes` across systems **+ the `ResetType@Redfish.AllowableValues` annotation on each `#ComputerSystem.Reset` action** | DSP0266 `ComputerSystem.json`; OpenBMC `Redfish.md` §ComputerSystem (bmcweb uses `ResetActionInfo` instead — DOCS-4, fixed 2026-10-23: annotation fallback lands the allow-list when `SupportedResetTypes` is absent; ActionInfo *resource* crawling stays #022/#016) | `FeatureRules.supportedResetTypes` / `FeatureRules.resetTypesFromAction` | `feature_rules_test.dart` "unions across systems and sorts" + "falls back to the ResetType@Redfish.AllowableValues annotation" + "unions + dedupes" + "never reads the manager-level allow-list" |
| `kvm` | any Manager exposes enabled console (`GraphicalConsole` / `SerialConsole` / strict OEM console) | DSP0266 `Manager.json` + `Manager.v1_25_0.json`; OpenBMC `Redfish.md` §Manager + OEM_SCHEMAS (DOCS-4: bare `Oem` is vendor metadata, not a console) | `FeatureRules.kvm` / `_managerConsoleType` | `feature_rules_test.dart` "detects GraphicalConsole", "ignores bare Oem", "Oem Kvm marker" |
| `kvmType` | first detected console kind (`GraphicalConsole`/`SerialConsole`/`Oem`) | same as `kvm` | `FeatureRules.kvmType` | same tests |
| `sensorMonitoring` | any `Chassis[*].(Thermal \|\| Sensors \|\| Power)` link | DSP0266 §9.1 "Resources" (link traversal) + §9.5.7 "Reference properties" + §9.6.13 "Links"; `Chassis.json` | `FeatureRules.sensorMonitoring` | `feature_rules_test.dart` "sensorMonitoring true via Thermal link" |
| `sensorCount` | temps + fans + voltages + sensor members | DSP0266 `Thermal.json` (`Thermal.v1_7_3.json`) / `Sensor.json` | `FeatureRules.sensorCount` | `feature_rules_test.dart` "sums temperatures + fans + voltages + sensor members" |
| `firmwareUpdate` | `UpdateService` present **and not explicitly disabled** | DSP0266 `UpdateService.json` (`UpdateService.v1_17_1.json`) `ServiceEnabled` ("This property shall indicate whether this service is enabled"); OpenBMC `Redfish.md` §UpdateService lists `ServiceEnabled` | `FeatureRules.firmwareUpdate` (honors `ServiceEnabled` — **fixed this run**) | `feature_rules_test.dart` "firmware_update presence…" + "firmwareUpdate honors ServiceEnabled (DOCS-5)"; `discovery_engine_test.dart` happy path |
| `updateServiceVersion` | `Version` → `Id` fallback (vendor `FirmwareVersion` in OpenBMC fixture) | DMTF `UpdateService.v1_13_0.json` — **no** `FirmwareVersion` property (vendor field in the OpenBMC fixture only); `Id` is the conformant fallback | `FeatureRules.updateServiceVersion` | `feature_rules_test.dart` "version preference"; `discovery_engine_test.dart` expects `2.14.0` from the OpenBMC fixture |
| `managers` | count of discovered `Manager` resources | DSP0266 §7.2.3 "Service root request" (`Managers` link) | `DiscoveryEngine._crawl` (classify) | `discovery_engine_test.dart` "discovers the full capability map" (`managers == 1`) |
| `chassis` | count of discovered `Chassis` resources | DSP0266 §7.2.3 "Service root request" (`Chassis` link) | `DiscoveryEngine._crawl` (classify) | `discovery_engine_test.dart` ("`chassis == 1`") |

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

## DOCS-14 — OData base vocabulary mirror + anchor re-verification (2026-10-23)

Closed the last un-mirrored REQUIREMENTS.md source citation and re-verified
every corpus anchor:

1. **`odata.4.0.0.json` mirrored (new).** Row 65 (`@odata.id` link traversal)
   cited `Odata.json` but the external corpus had no OData schema. The bare
   `Odata.json` 404s on the DMTF schema index (verified live); the canonical
   file is the lowercase `odata.4.0.0.json` (OData 4.0.0 base vocabulary:
   `context`/`id`/`idRef`). Fetched 2026-10-23 16:40 UTC, 1,834 bytes, SHA-256
   `c73cce029ca4cc01a54d341389742f60a4f48e05691ee81934ca9ba513dc6b7c` — **byte-
   identical to `test/fixtures/redfish/schemas/Odata.json`**, which proves the
   fixture copy is current. Manifest row added; row 65 citation updated.
   Within the DOCS-6 budget.
2. **bmcweb master advanced `27e0930b` → `fbb307a`.** Re-fetched all four
   mirrored docs at the new HEAD (`Redfish.md`, `REDFISH_CHECKLIST.md`,
   `OEM_SCHEMAS.md`, `CLIENTS.md`): **byte-identical** (same SHA-256s) — no
   corpus refresh needed, manifest anchors updated to `fbb307a`.
3. **`DMTF/Redfish-Mockup-Server` still `23d21f9a`** (default branch `main`;
   the `master` ref 422s — corrected the API call, pin unchanged).
4. **DMTF schema index 200 OK**; hub still links `DSP0266_1.25.0.pdf`
   (1.26.0 → 404) — no spec refresh.
5. No client code change this run — corpus-only audit + provenance.

## DOCS-15 — DSP0266 §7.3 "Query parameters" audit (2026-10-23)

Audited DSP0266 1.25.0 §7.3.1–§7.3.5 (query-parameter clauses) against the
client's HTTP transport and the emulator-pinned query contract (#018). This is
the normative basis for the #018 lightweight discovery pass (`$expand`
collection fetch) and for how the client must treat `$filter`/`$select` on the
pinned mockup.

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Query parameters apply only to **GET** operations; service shall process them in order `$filter` → `$skip` → `$top` → server-side pagination → `$expand` → `excerpt` → `$select` | DSP0266 §7.3.1 "Query parameter overview" | `RedfishClient.getJson` accepts `query` (Dio `queryParameters`) — GET only; no feature passes a query today | (new, this run) `redfish_client_extra_test.dart` pins `getJson` forwards `query` to the wire | OK — transport ready for #018 |
| Service **shall** advertise query support via `ProtocolFeaturesSupported` in the service root; service **may** support `$expand`/`$filter`/`$select`, **should** support `$top`/`$skip`/`only`/`excerpt` | DSP0266 §7.3.1; `ServiceRoot.v1_22_0.json` `ProtocolFeaturesSupported` (mirrored DOCS-13) | `FeatureRules` reads the service root (discovery crawl) but does not yet gate query usage on the advertised flags | emulator service-root group asserts `ProtocolFeaturesSupported` publishes `ExpandQuery{ExpandAll,Levels}` + `FilterQuery`/`SelectQuery` | GAP: #018 must gate its `$expand` usage on `ExpandQuery` (Levels/ExpandAll) and assume NO `$filter`/`$select` application |
| Service shall return **501 Not Implemented** for unsupported `$`-prefixed query parameters, with an extended error naming the unsupported parameter; **400 Bad Request** for invalid values; **400 QueryNotSupportedOnResource** for implemented-but-unsupported-on-resource params | DSP0266 §7.3.1; `Base` Message Registry `QueryNotSupportedOnResource` | `RedfishException.fromDioException` normalizes 400/501 into typed errors | `redfish_error_test` / `models_test.dart` cover error envelope; no query-specific 400/501 unit fixture yet | Partial: generic error mapping OK; #018 should add a unit fixture for the query-501 path |
| `$expand` options: `*` (all hyperlinks incl. payload annotations), `$levels` (default 1), `.` (all but `links` properties), `~` (only `links` properties); when `$levels` advertised, `MaxLevels` caps the depth; combine with `$select` using full property path | DSP0266 §7.3.2 "The $expand query parameter"; `ServiceRoot.v1_22_0.json` `Expand` definition | none (client does not send `$expand` today) | emulator pins: `$expand=.($levels=1)` **and** `$expand=*` both inline full member bodies (17:07 + 18:36 runs) | OK pinned on the mockup; #018 may use either form (`*` or `$levels=1`) for collection fetch |
| Service shall not expand referenced resources the client lacks privileges for (no request failure); **507 Insufficient Storage** when the expanded payload exceeds service limits; partial collection expansion → 200 + `@odata.id` for unexpandable members + extended info | DSP0266 §7.3.2 | none | — | Note for #018 (payload-growth guard + 507 mapping) |
| `$select`: returns a subset of properties per the comma-separated expression; `/` separates nested property paths; array indices not allowed; response keeps `@odata.id`/`@odata.type` (and `@odata.context`/`@odata.etag` when supported) with the same values as an unselected response; unsupported requested properties are omitted | DSP0266 §7.3.3 "The $select query parameter" | none (client sends no `$select`) | emulator pins `$select=Model` is **advertised but NOT applied** by the mockup (full body returned, 18:36) | GAP: #018 must do projection client-side — never rely on server-side `$select` |
| `$filter`: subset of collection members per built-in operators `() and or not eq ne ge gt le lt` with fixed operator precedence; strings in single quotes | DSP0266 §7.3.4 "The $filter query parameter" | none (client sends no `$filter`) | emulator pins `$filter=Id eq 'NOPE'` returns **all** members (advertised but NOT applied, 18:36) | GAP: #018 must filter client-side — never rely on server-side `$filter` |
| `clientcontext`: stateless incremental retrieval of collection entries (currently defined for `LogEntryCollection`); service **shall never silently ignore** it (responds `@Redfish.ClientContextStatus`); unknown key = first-use; NotFound for evicted keys | DSP0266 §7.3.5 "The clientcontext query parameter"; `ServiceRoot.v1_22_0.json` `ClientContextQuery` | not used (no log reader) | emulator log-service group pins `@odata.nextLink` (`$skiptoken`) pagination — different mechanism | Note for future log reader; not #018 |

**Bottom line for #018** (folded into FUTUREWORK): the pinned mockup advertises
`$filter`/`$select`/`$expand` but **applies only `$expand`**. The #018
lightweight discovery pass must (a) gate `$expand` usage on the advertised
`ExpandQuery.Levels`/`ExpandAll`, (b) do all filtering/projection client-side,
and (c) map `501`/`507` from query requests. `RedfishClient.getJson` already
supports a `query` map — the transport contract is now pinned by unit test
(added this run). No production code change this run.

## DOCS-16 — DSP0266 1.25.0 citation audit + §9.9 payload-annotation pin (2026-10-24)

The requirement rows above (added across DOCS-3/4/5/10/13) cited DSP0266 clause
numbers from an **older spec layout** that does not match the mirrored
`DSP0266_1.25.0.pdf` (the version actually mirrored under `redfish/spec/`).
Verified against the PDF TOC + body text and corrected this run:

| Stale citation (old layout) | Correct clause in DSP0266 1.25.0 | Reason |
|---|---|---|
| §8.3 "Service Root" | §7.2.3 "Service root request" | service root request clause lives in "Service requests" chapter; §8 is "Service responses" |
| §8.4 ComputerSystem / §8.10 Thermal / §8.14 "Software inventory" | no such clauses — property contracts live in the versioned **schemas** (`ComputerSystem.v1_29_0.json`, `Thermal.v1_7_3.json`, `SoftwareInventory.json`) + §9 "Data model" (§9.1 Resources, §9.6 Properties) | DSP0266 does not enumerate per-resource property lists; the schemas are the normative source |
| §9.2 "HTTP and the Redfish protocol" (ETag) | §6.5 "ETags" + §7.2 "GET (read requests)" | ETag/If-None-Match/304 contract is §6.5; HTTP method semantics are §7 |
| §12.2 "Actions" | §9.6.14 "Actions property" + §7.11 "POST (action)" | action-representation contract is a data-model clause |
| §12.3 "Basic authentication" | §13.3.3 "HTTP Basic authentication" | auth is a Security-details clause |
| §12.4 "Sessions" / "Session timeout" | §13.3.4 "Redfish session login authentication" (§13.3.4.3 "Session lifetime") | session auth + lifetime is a Security-details clause |
| §12.7 "Error responses" | §8.6 "Error responses" | error envelope is a Service-responses clause |
| §9.7 "Firmware update" | §12.7 "Update service" (§12.7.2.1 "Simple updates") | update-service clause is in "Service details" |

Clauses that were already correct and stay unchanged: §12.1 "Eventing"
(§12.1.1–12.1.5), §12.2 "Asynchronous operations" (task monitors), §7.3
"Query parameters" (§7.3.1–7.3.5, DOCS-15), §9.6.11/§9.6.12 Members +
`@odata.nextLink`, §9.6.2 `@odata.id`, §9.1 Resources.

Payload-annotation contract now pinned (code was already implementing it; the
tests make the spec link explicit):

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| `@Redfish.AllowableValues` on an action parameter is a JSON array of strings defining the allowable values for that parameter (e.g. `ResetType@Redfish.AllowableValues` on `#ComputerSystem.Reset`) | DSP0266 §9.9.2 "Allowable values for strings"; annotation name format `<PropertyName>@<Namespace>.<TermName>` per §9.9.1, namespace `Redfish` = `RedfishExtensions.v1_0_0` | `FeatureRules.resetTypesFromAction` parses the annotation list | `feature_rules_test.dart` "reads the @Redfish.AllowableValues annotation per DSP0266 §9.9.2 (DOCS-16)" | OK |
| Clients shall not fail reading a resource due to unrecognized annotations (incl. new Redfish-namespace terms); a non-array allow-list value is ignored | DSP0266 §9.9.1 "Payload annotations overview" | `FeatureRules.resetTypesFromAction` returns empty for non-list / unrelated annotations | `feature_rules_test.dart` "ignores unrecognized annotations (DSP0266 §9.9.1 tolerance, DOCS-16)" | OK |

Anchors re-verified this run (2026-10-24): bmcweb master `fbb307a` (unchanged),
Redfish-Mockup-Server `23d21f9a` (unchanged), DSP0266 1.25.0 PDF
(www.dmtf.org URL; content-length 1,243,359 bytes — unchanged; the
`redfish.dmtf.org` path 404s and the hub links the `www.dmtf.org` URL), schema
index 200 OK. No corpus refresh needed.

## DOCS-17 — DSP0266 §13.3.4.3 session-lifetime audit + expiry pin (2026-10-24)

Audited the session-lifetime contract against the mirrored
`SessionService.json` + `SessionService.v1_2_0.json` (DOCS-12 mirrored the
newest + mockup-served versions) and DSP0266 §13.3.4.3 "Session lifetime".
Found that the client's `Session.expiresAt` / `isExpired` machinery existed
but **nothing ever populated the deadline** — the trace row above claimed
"OK" while `AuthManager` never reads the SessionService resource. This run
closed the model-level gap with a small, safe, tested helper (the AuthManager
fetch + wiring stays #015):

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Session expiry derives from `SessionService.SessionTimeout` (seconds of *inactivity* before the service closes the session; schema range 30–86400) | DSP0266 §13.3.4.3; `SessionService.json` (`SessionTimeout`) | `Session.expiryFromService` — `createdAt + SessionTimeout` | `models_test.dart` "expiryFromService uses SessionTimeout only" + "ignores a disabled AbsoluteSessionTimeout" | OK (model-level; AuthManager wiring #015) |
| v1_2_0 adds `AbsoluteSessionTimeout` — maximum seconds a session stays open *regardless of activity* — applied only when `AbsoluteSessionTimeoutEnabled` is `true`; the effective deadline is the earlier of the two so the client re-authenticates before the service can kill the session | `SessionService.v1_2_0.json` (`AbsoluteSessionTimeout`, `AbsoluteSessionTimeoutEnabled`, versionAdded v1_2_0); DSP0266 §13.3.4.3 | `Session.expiryFromService` takes `min(SessionTimeout, AbsoluteSessionTimeout)` when enabled; absolute-only services still get a deadline; malformed values are ignored | `models_test.dart` "takes the earlier of SessionTimeout and an enabled AbsoluteSessionTimeout" + "handles an absolute-only service" + "tolerates malformed timeout values" | OK (model-level; note for #015 — `AbsoluteSessionTimeoutEnabled` defaults absent/false) |
| No usable SessionService body → no known TTL (`expiresAt` null, session treated long-lived until a 401) | DSP0266 §13.3.4.3 (timeout is optional); `Session.json` | `Session.expiryFromService` returns `null` | `models_test.dart` "returns null without a SessionService body" | OK |

Notes for #015 (the open P1): the helper gives the deadline computation, but
`AuthManager` still needs (a) a discovered SessionService fetch during login
(or reuse of `DiscoveryContext.sessionService`), (b) `AbsoluteSessionTimeout*
` handling only when the service publishes it (mockup serves `v1_1_8` which
lacks the fields — `SessionTimeout=30` is the pinned emulator value), and
(c) a re-auth trigger when `Session.isExpired` flips.

UI-2 increment this run: the **FirmwareView error state** (errorContainer card
with icon + message) now announces as ONE merged semantics node
(`Semantics(container: true, excludeSemantics: true, label: 'Unable to load
firmware. <message>')` — the established OverviewView/SensorsView error-state
pattern), with the Retry button keeping its own control node. One new widget
test in `firmware_widget_test.dart` asserts the merged label + visible message
text + separately-announced Retry control.

## DOCS-18 — MessageRegistry payload mirror + Base registry delta audit (2026-10-24)

Closed the last corpus gap the emulator pins but the mirror lacked: the
**message-registry payload** behind the `MessageRegistryFile.Location[0].Uri`
the EMU-2 MessageRegistry contract resolves (service root `Registries` →
`MessageRegistryFileCollection` → `Base.1.5.0` → `#MessageRegistry` JSON).
Registry payloads live on the DMTF registries path
(`https://redfish.dmtf.org/registries/` — the `redfish/schemas/v1/` index
carries only the `MessageRegistry.json` aggregator + schemas).

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Error responses carry `error.code` (a `Base.*` MessageId) + human `error.message`; `@Message.ExtendedInfo[].MessageId` references a published MessageRegistry entry | DSP0266 §8.6 "Error responses"; `registries/Base.1.5.0.json` (mirrored DOCS-18; byte-identical to the pinned mockup's payload — SHA-256 `c1026341…`) | `lib/redfish/models/redfish_error.dart` (`fromJson` envelope self-descend #014, code/message normalization) | `test/redfish/models/models_test.dart`; emulator MessageRegistry group pins the discovery + `Base.*` template surface (GeneralError Severity Critical / NumberOfArgs 0; ActionNotSupported NumberOfArgs 1) | OK |
| Message registries are versioned resources published per `RegistryPrefix` (the `Base` registry's messages are the standard template set) | DSP0266 §11.4 "Message registries"; `registries/Base.1.24.0.json` (newest published, mirrored DOCS-18) | n/a — model reads templates only for reasoning/tests | emulator: `#MessageRegistry.v1_0_0.MessageRegistry` shape (Id `Base.1.5.0`, RegistryVersion 1.5.0, OwningEntity DMTF, `Messages` map) | OK (contract pin only) |
| The mockup-served registry payload is authentic upstream (not fixture-generated) | DMTF registries index 200; `curl -sSIL` HEAD on `Base.1.5.0.json` | — | byte-compare: `sha256sum` upstream download == fixture (`c10263417a076402a992f099db4e019c9d91f674d256df32a390b86a2c46492c`, 31,984 bytes) | OK (provenance) |

**Newest-vs-served delta audit (`Base.1.5.0` → `Base.1.24.0`):**

- Template count **60 → 125** (+65 additions — e.g. `AccessForbidden`,
  `ActionParameterValueNotInList`, `HeaderInvalid`, `InvalidJSON`,
  `PreconditionFailed`, `PropertyValueNotInList` grew typo/format variants,
  `ResourceExhaustion`; nothing removed).
- **39 shared keys reworded** (e.g. `ActionNotSupported` "The action %1 is not
  supported by the resource." → "The action '%1' is not supported by the
  resource."; `GeneralError` gained an `@Message.ExtendedInfo` pointer) — but
  **`NumberOfArgs` is stable for every shared key (0 changed)**, so the
  argument-count contract the emulator pins (`GeneralError` 0,
  `ActionNotSupported` 1) holds across the newest registry too.
- `@odata.type` advanced `#MessageRegistry.v1_0_0` → `#MessageRegistry.v1_9_0`.
- **Client impact: none.** `RedfishError` treats `code`/`message` opaquely
  (the message resolver / error-reasoning surface is a future feature). The
  `1.5.0` mirror stays authoritative for the mockup-served surface; `1.24.0`
  is the "newest" provenance + a future `MessageId` resolver would read it.
- Anchors re-verified this run: registries path 200; `Base.1.5.0.json` and
  `Base.1.24.0.json` both 200. bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266
  1.25.0, schema index 200 — all unchanged. New bytes this run: 170,279
  (31,984 + 138,295) — inside the DOCS-6 budget.

UI-2 increment this run: the **Dashboard `_ErrorSummary` card** ("N systems
could not be reached") now announces as ONE merged semantics node
(`Semantics(container: true, excludeSemantics: true, label: 'Unable to reach
N systems. Retry available.')` — the established error-state pattern; the
visible text stays for sighted users and the Retry button keeps its own control
node). New dashboard widget tests assert the merged label + separately-
announced Retry control + Retry still reconnects failed systems (UI-1
behaviour unchanged).
