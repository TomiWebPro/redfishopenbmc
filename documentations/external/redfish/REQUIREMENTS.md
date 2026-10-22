# Redfish Requirement Traceability

Maps audited Redfish / OpenBMC requirements to the client implementation and its
tests. Source citations point at the mirrored corpus in
`documentations/external/redfish/` (see `README.md` manifest for hashes) or the
live DMTF URLs. Status legend: `OK` (implemented + tested), `GAP` (known gap,
tracked in `FUTUREWORK.md`), `N/A` (not applicable to this client).

Last audited: 2026-10-22 (docs mirror refresh run). Sources:

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
| Event subscription: `EventService.Subscriptions` | DSP0266 §14 "Eventing" | **not implemented** | — | GAP: not yet tracked in FUTUREWORK |
| Task service: `TaskService` + `Task` resource polling | DSP0266 §13.4 "Tasks"; `TaskService.json` | not implemented (202 accepted, deferred) | — | GAP: #008/#022 |
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