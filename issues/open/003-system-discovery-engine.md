---
id: "003"
title: "Feature discovery engine — schema-driven traversal & capability map"
status: open
priority: P1
type: feature
created: 2026-08-26
updated: 2026-08-26
closed: null
assignee: unassigned
labels: [redfish, discovery, schema, engine]
estimated_tokens: 55000
---

# 003 — Feature discovery engine — schema-driven traversal & capability map

> Implement the app's core differentiator: start at `/redfish/v1/`, traverse `@odata.id` links, inspect schemas/actions, and produce a per-system feature map that drives the UI (nothing assumed).

## Description

`goal.md` mandates **Dynamic Feature Discovery**: query `ServiceRoot`, walk `/Systems`, `/Managers`, `/Chassis`, `/UpdateService`, `/SessionService`, detect `Actions` (`#ComputerSystem.Reset`, `#Manager.Reset`, etc.), properties, OEM extensions, and normalize into:

```json
{"system_id":"bmc1","features":{"power_control":true,"kvm":false,"firmware_update":true,"sensor_monitoring":true}}
```

UI renders only `true` features. This engine is the contract between Redfish and the UI.

- Goal reference: `goal.md` §2 Dynamic Feature Discovery, § Architecture → Feature Discovery Engine, § Key Design Rule
- User story: As a user I connect to any vendor's BMC and see only the controls that BMC actually exposes — no broken buttons.
- Scope IN: `DiscoveryEngine`, `CapabilityMap`/`SystemFeatures` model, traversal + caching per system, `@odata.id` link following, `Actions` detection, OData `metadata`/`$metadata` awareness, lazy + delta polling, exhaustive unit tests with fixture JSON from OpenBMC + DMTF mockup
- Scope OUT: UI rendering (→ #006), power actions execution (→ #005), sensor graphs (→ #007)

## Goals / Acceptance Criteria

- [ ] `lib/redfish/discovery/discovery_engine.dart` — `discover(RedfishClient, systemId) → SystemFeatures` 
  - Step 1: `GET /redfish/v1/` → cache `ServiceRoot`
  - Step 2: breadth-first traverse `@odata.id` links for `Systems`, `Managers`, `Chassis`, `UpdateService`, `SessionService` (depth ≤3, cycle-safe via `Set<uri> visited`)
  - Step 3: inspect each resource's `Actions`, `Oem`, `SupportedResetTypes`, `Links`, `Status`, `Actions.#ComputerSystem.Reset.target`
- [ ] `lib/redfish/models/system_features.dart` — freezed/dataclass:
  ```dart
  SystemFeatures(
    systemId, 
    powerControl: bool, supportedResetTypes: List<String>,
    kvm: bool, kvmType: String?, // e.g. GraphConsole / SerialConsole / OEM
    sensorMonitoring: bool, sensorCount: int?,
    firmwareUpdate: bool, updateServiceVersion: String?,
    managers: int, chassis: int,
    raw: Map<String,dynamic> // debug / raw explorer
  )
  ```
- [ ] Normalization rule documented in `lib/redfish/discovery/feature_rules.dart` — e.g. `power_control = Systems[*].Actions.#ComputerSystem.Reset != null`
- [ ] Caching: per-system `Map<systemId, {features, fetchedAt, ttl: 5min}>` in memory + optional `hive`/`shared_preferences` persistence; `invalidate(systemId)` + lazy reload on next navigation
- [ ] Minimal API calls: deduplicate `@odata.id`, concurrent `Future.wait` with `maxConcurrency=4`, skip links already in cache and `ETag`-aware if header present
- [ ] Handles missing trees gracefully: absent `UpdateService` → `firmwareUpdate:false` (no crash), vendor OEM under `Oem.<Vendor>` parsed but not required
- [ ] Tests: `test/redfish/discovery/discovery_engine_test.dart` — fixtures: `test/fixtures/openbmc_service_root.json`, `.../openbmc_systems.json`, `.../dmtf_mockup_ServiceRoot.json`; asserts traversal, feature map, cycle detection, cache TTL, error path (404 on Chassis)
- [ ] Coverage ≥85% on `discovery/`
- [ ] Raw-explorer hook: `DiscoveryEngine.rawTree(systemId) → Map<String, dynamic>` for future developer mode (no UI yet)

## Tasks

- [ ] Define `SystemFeatures` + `DiscoveryCache` models
- [ ] Implement `DiscoveryEngine` + `FeatureRules` (table-driven)
- [ ] Add `ODataLink` helper (`@odata.id`, `@odata.type`, `@odata.context`) under `lib/redfish/models/odata.dart`
- [ ] Write fixtures by capturing real OpenBMC `bmcweb` responses or DMTF mockup (commit under `test/fixtures/redfish/`)
- [ ] Tests: 8+ cases (happy, missing service, OEM, cycles, TTL, concurrent)
- [ ] Benchmark: log discovery time + request count (debug only)
- [ ] Update `progress/journal.md` + `progress_summary.md`

## Redfish Mapping

| Resource | Endpoint | When fetched | Feature derived |
|----------|----------|--------------|-----------------|
| ServiceRoot | `/redfish/v1/` | always | entry points |
| Systems | `/redfish/v1/Systems` + `/Systems/{id}` | always | `power_control`, `power_state`, model/mfr |
| Managers | `/redfish/v1/Managers` | always | `kvm` via `GraphicalConsole`/`SerialConsole` |
| Chassis | `/redfish/v1/Chassis` | always | `sensor_monitoring` via `Sensors`/`Thermal` |
| UpdateService | `/redfish/v1/UpdateService` | if link exists | `firmware_update` |
| SessionService | `/redfish/v1/SessionService` | if link exists | auth capability |
| Thermal/Sensors | `/Chassis/{id}/Thermal` or `/Sensors` | if Chassis exists | proof of sensors |
| OEM | `*.Oem.*` | opportunistic | plugin hook |

- Actions inspected: `#ComputerSystem.Reset`, `#Manager.Reset`, `#UpdateService.SimpleUpdate`, `#VirtualMedia.InsertMedia` (future)
- Schema: no hard `$metadata` fetch in v1 — use `@odata.type` string + `Actions` presence; full schema validation is P3

## Progress Log

- 2026-08-26 — Created. Depends on #001 #002; blocks #004–#010.

## References

- `documentations/project_goal/goal.md:36-58`, `205-238`
- DMTF Resource & Schema Guide: https://www.dmtf.org/dsp/DSP2046
- DMTF Mockup: https://github.com/DMTF/Redfish-Mockup-Creator
- OpenBMC bmcweb Redfish impl: https://github.com/openbmc/bmcweb/tree/master/redfish-core
- Related: #002, #004, #005, #006, #007, #008, #009

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
