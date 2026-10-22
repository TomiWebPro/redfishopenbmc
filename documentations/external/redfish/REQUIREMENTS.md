# Redfish Requirement Traceability

Maps audited Redfish / OpenBMC requirements to the client implementation and its
tests. Source citations point at the mirrored corpus in
`documentations/external/redfish/` (see `README.md` manifest for hashes) or the
live DMTF URLs. Status legend: `OK` (implemented + tested), `GAP` (known gap,
tracked in `FUTUREWORK.md`), `N/A` (not applicable to this client).

Last audited: 2026-10-22 (DOCS-3: eventing + tasks audit against DSP0266 1.25.0).
Sources:

- DSP0266 1.25.0 — `redfish/spec/DSP0266_1.25.0.pdf`
- DMTF schema index — `redfish/schemas/v1-index.html` + `redfish/schemas/v1/*.json`
- bmcweb — `redfish/openbmc/Redfish.md`, `REDFISH_CHECKLIST.md`, `OEM_SCHEMAS.md`
  (bmcweb master `0128851e`)

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
| Firmware inventory: `UpdateService` / `SoftwareInventory` collection | DSP0266 §8.14 "Software inventory"; `SoftwareInventory.json` | `lib/features/firmware/firmware_models.dart` | `test/features/firmware/` | OK |
| Firmware update: `UpdateService.SimpleUpdate` (entity-upload mode TBD) | DSP0266 §9.7 "Firmware update"; `UpdateService.json` | `lib/features/firmware/firmware_service.dart` | `test/features/firmware/` | Partial — task monitoring in #008/#020 |
| KVM capability: `Manager.GraphicalConsole` / OEM console detection | OpenBMC `Redfish.md`; `Manager.json` | `lib/redfish/discovery/feature_rules.dart` (`kvm`, `kvmType`) | `test/redfish/discovery/feature_rules_test.dart` | OK (rendering gated in #009/#021) |
| Event subscription: `EventService.Subscriptions` — POST → 201 + `Location`; DELETE to unsubscribe | DSP0266 §12.1.1–§12.1.2 "Eventing"; `EventService.json` | **not implemented** | — | GAP: DOCS-7 — decision recorded below (out-of-scope this milestone) |
| SSE event stream: GET `EventService.ServerSentEventUri` | DSP0266 §12.1.3 "Open an SSE connection"; `EventService.v1_6_9+` | **not implemented** (no SSE transport dependency in `pubspec.yaml`) | — | GAP: DOCS-7 — revisit when telemetry/eventing lands (#007/#019) |
| EventType-based eventing deprecated; filter subscriptions by `RegistryPrefixes` / `ResourceTypes` / `MessageIds` | DSP0266 §12.1.4–§12.1.5 | n/a (no subscriber yet) | — | Note for a future implementation |
| Task monitor: 202 + `Location` + optional `Retry-After`; GET monitor → 202 while running, then final status + body; DELETE cancels; 404/410 after completion | DSP0266 §12.2 "Asynchronous operations"; `TaskService.json` | `lib/features/firmware/firmware_service.dart` + `lib/features/power/power_service.dart` read `Location`, store the task URI, do **not** poll | tests cover 202+`Location` acceptance | Partial/GAP: #008/#020 (firmware), #022 (power) |
| bmcweb `EventService`: `SubmitTestEvent`, `DeliveryRetryAttempts` (default 3), `DeliveryRetryIntervalSeconds`, `EventFormatTypes`, `SSEFilterPropertiesSupported` | OpenBMC `Redfish.md` §EventService | not implemented | — | vendor row (bmcweb) |
| bmcweb `TaskService`: `CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, `Tasks` collection | OpenBMC `Redfish.md` §TaskService | not implemented (202 accepted only) | — | vendor row (bmcweb) |
| Session timeout handling (`SessionService.SessionTimeout`) | DSP0266 §12.4; `SessionService.json` | `lib/redfish/models/session.dart` (expiry) | `test/redfish/client/auth_manager_test.dart` | OK |

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
     `REDFISH_EMULATOR_URL` is defined.
  Both cover the rows above end-to-end against authentic payload shapes.

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
`0128851e`).
