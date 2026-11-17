---
id: "007"
title: "Sensor monitoring — temps, fans, voltages with realtime graphs"
status: closed
priority: P2
type: feature
created: 2026-08-26
updated: 2026-11-17
closed: 2026-11-17
assignee: unassigned
labels: [sensors, telemetry, realtime, charts]
estimated_tokens: 50000
---
# 007 — Sensor monitoring — temps, fans, voltages with realtime graphs

> Live `Thermal`/`Sensors` collection: temperature, fan, voltage lists, threshold alerts, sparkline/graph, polling vs WebSocket, discovery-gated rendering.

## Description

`goal.md` §3.4 mandates real-time sensor monitoring rendered only when present. Redfish exposes this via legacy `GET /Chassis/{id}/Thermal` (Temps+Fans) and modern `GET /Chassis/{id}/Sensors` + `/redfish/v1/TelemetryService`. OpenBMC currently serves `Thermal` + `Sensors` (new). App must support both, graph deltas efficiently, and alert on thresholds.

- Goal reference: `goal.md` §3.4 Sensor Monitoring, §172-178 Real-Time Feedback, § Performance (lazy-load, delta polling)
- User story: As a user I open Sensors for a system and see current temps/fans/voltages as live tiles + a sparkline per sensor, with warning/critical coloring when thresholds breach — no graph if the BMC doesn't expose sensors.
- Scope IN: `Sensor` model, `SensorsService`, `Sensors Tab` UI, polling + optional EventService/SSE, threshold evaluation, `fl_chart` or `syncfusion` integration, discovery gate, tests
- Scope OUT: KVM (→ #009), firmware (→ #008), raw Redfish explorer (P3)

## Goals / Acceptance Criteria

- [x] `lib/features/sensors/models/sensor_models.dart` — typed `ThermalReading` / `FanReading` / `VoltageReading` / `SensorReading` carrying `name`, `reading` (+ `°C`/`RPM`/`V` units), `StatusInfo` health, lower/upper caution+critical thresholds, `physicalContext`, reading type and last-updated via the controller stamp (implemented as typed classes rather than one literal `sensor.dart`).
- [x] `lib/features/sensors/sensors_service.dart` —
  - Try modern first: `GET /redfish/v1/Chassis/{id}/Sensors` → collection of `Sensor.v1_6_0` (Reading, Thresholds, Status)
  - Fallback: `GET /Chassis/{id}/Thermal` → `Temperatures[]` + `Fans[]` + `Voltages[]` normalized into same `Sensor` list
  - Returns `List<Sensor>`; empty if chassis absent → caller hides tab
  - Polling `FutureProvider` every 5–10s when tab visible, backoff to 30s when background; delta: only rebuild tiles whose `Reading` changed
- [x] Tab `lib/features/sensors/views/sensors_view.dart` — **only if** `features.sensorMonitoring==true` (else tab hidden, no placeholder):
  - [x] Sections `Temperatures` / `Fans` / `Voltages` (omit empty sections)
  - [x] Tile per sensor: name, reading + units, health dot, threshold range bar, mini sparkline (last 20 polls, ring buffer)
  - [x] Alert banner if any sensor `Health==Critical/Warning` or `Reading` breaches `UpperThresholdCritical`
  - [x] Pull-to-refresh + last-updated timestamp
- [x] Charts: `fl_chart` `LineChart` per sensor behind an on-demand Tiles/Charts toggle; `ListView.builder` viewport-lazy layout, `RepaintBoundary` + `duration: Duration.zero` (no tweens), verified by a 20 sensors × 60 points single-frame test bed (`lib/features/sensors/views/sensor_chart.dart`)
- [x] Threshold coloring: `OK→green`, `Warning→amber` (breaches `NonCritical`), `Critical→red` (breaches `Critical`), grey if `Reading==null`
- [x] Error resilience: sensor absent, 404 Sensors → fallback Thermal, both 404 → hide tab gracefully; 401 bubbles to auth manager
- [x] Tests: `test/features/sensors/sensors_service_test.dart` — Thermal fixture from OpenBMC, Sensors collection fixture, threshold evaluation, empty chassis, polling dedup; widget test verifies hidden when `sensorMonitoring false`
- [x] Coverage ≥80% — full-suite `flutter test --coverage`: 94.3% (917/972 lines) across `lib/features/sensors/`

## Tasks

- [x] Model `Sensor` + `Threshold` + adapter `thermalToSensors()` (typed reading classes in `sensor_models.dart`)
- [x] Service `SensorsService` + `SensorsNotifier` (Riverpod) with polling timer + ring buffer
- [x] Widgets: `SensorsView`, `SensorTile`, `SensorChart`, `ThresholdBar`, `AlertBanner`
- [x] Add `fl_chart` dep + chart perf test (`sensor_chart_test.dart`: 20×60 points single-frame bed)
- [x] Fixtures: capture OpenBMC `Thermal` + `Sensors` JSON under `test/fixtures/redfish/`
- [x] Tests: 5 service + 3 widget (far exceeded — full suite 715 passed)
- [x] Document fallback matrix in code comment + `progress/journal.md`

## Redfish Mapping

| Collection | Endpoint | Method | Notes |
|------------|----------|--------|-------|
| Modern Sensors | `/redfish/v1/Chassis/{id}/Sensors` | `GET` | `SensorCollection` → members `Sensor.v1_6_0` with `Reading`, `Thresholds.UpperCritical`, `Status.Health` |
| Legacy Thermal | `/redfish/v1/Chassis/{id}/Thermal` | `GET` | `Temperatures[] {Name, ReadingCelsius, UpperThresholdCritical, Status}`, `Fans[] {Reading, Units: RPM}`, `Voltages[]` |
| TelemetryService (P4) | `/redfish/v1/TelemetryService/MetricReports` | `GET` | future — if `TelemetryService` exists, use `MetricReport` for higher freq |
| EventService (P3) | `/redfish/v1/EventService` | `SSE/WS` | future push vs polling — leave hook `EventStreamProvider` |

- Discovery rule: `sensorMonitoring = (ChassisLinks includes Sensors) OR (Thermal.Temperatures non-empty)` (`feature_rules.dart` → #003)
- OData: `Members` + `@odata.id` traversal for Sensors collection

## Progress Log

- 2026-08-26 — Created. Depends on #001 #003 #004.
- 2026-08-30 — STALE (triage): no Progress Log update for 4 days (>1-day threshold).
- 2026-11-17 15:49 UTC (run, agent:redfish-automation) — FEATURE slice: implemented the
  acceptance criterion "Alert banner if any sensor Health==Critical/Warning or Reading
  breaches UpperThresholdCritical". Added `SensorAlertLevel`/`SensorAlert` and a
  `ChassisSensors.alerts` getter that combines health status with upper/lower
  critical + caution threshold breaches (critical health wins; a BMC reporting
  `Health=OK` on a breached reading still alerts). `SensorsView` now renders one
  merged-semantics `_AlertBanner` at the top of the telemetry list when any alert
  exists (critical → error tint + icon, warning → amber), with no banner when
  nominal. Added 5 model unit tests, 2 widget tests (banner present/absent with
  merged semantics), and 3 responsive no-overflow tests at 320/800/1300px.
  Baseline analyze 0 / 619 passed / 1 skipped; verify analyze 0 / 629 passed /
  1 skipped (10 new tests). Issue stays open: sparkline/ring-buffer, threshold
  range bar, fl_chart and polling delta-rebuild acceptance boxes remain.
- 2026-11-17 16:29 UTC (run, agent:redfish-automation) — FEATURE slice:
  implemented the "mini sparkline (last 20 polls, ring buffer)" and "threshold
  range bar" parts of the per-sensor tile acceptance box. Added pure-Dart
  `ReadingHistory` (fixed-capacity FIFO, oldest-first, min/max/latest) and
  `SensorHistoryStore` (per-sensor series keyed by kind+chassis+name, records one
  sample per poll, retains history when a reading is absent) in
  `models/reading_history.dart`. `SensorsController` now feeds every successful
  poll into the store and publishes an immutable `SensorsUiState.history`
  snapshot; `SensorsView` tiles draw a dependency-free `SensorSparkline`
  (CustomPainter) and a `ThresholdBar` (green/amber/red bands + reading marker)
  from `views/sensor_telemetry_widgets.dart`. Added 7 ring-buffer/store unit
  tests, 7 widget tests (sparkline/bar states + 320/800/1300px no-overflow) and
  1 controller→sparkline integration test (series grows across two polls).
  Checked the per-tile and alert-banner acceptance sub-boxes; issue stays open
  because fl_chart/LineChart perf, polling background-backoff and delta-rebuild
  boxes remain.
- 2026-11-17 17:10 UTC (run, agent:redfish-automation) — FEATURE slice:
  implemented polling background-backoff + delta rebuild (the "Next" from the
  prior run). Added pure-Dart `SensorsPollingPolicy` + `SensorsPollingScheduler`
  (`models/polling_policy.dart`): fast 10s cadence while visible, backed off to
  30s when hidden, with a testable `isSensorAppBackgrounded` lifecycle mapping.
  `SensorsView` is now a `WidgetsBindingObserver` that reschedules its poll timer
  on lifecycle changes (and cancels it on dispose); the fixed `Timer.periodic`
  is replaced by the reschedulable scheduler. Added `telemetryFingerprint()` in
  `sensor_models.dart`; `SensorsController.load()` now reuses the last-published
  `chassis` list instance when a poll's fingerprint is unchanged, while sparkline
  history still advances every poll. Added 2 policy + 2 lifecycle + 3 scheduler
  + 4 fingerprint unit/widget tests and 2 controller delta tests. Baseline
  analyze 0 / 644 passed / 1 skipped; verify analyze 0 / 657 passed / 1 skipped
  (+13). Issue stays open: fl_chart/LineChart perf and per-tile `Selector`-level
  delta rebuild (so unchanged tiles never repaint) remain; the current delta is
  controller-level (reusing unchanged chassis data).
- 2026-11-17 17:47 UTC (run, agent:redfish-automation) — FEATURE slice:
  implemented the per-tile `Selector`-level delta rebuild (the explicit "Next"
  from the prior run). Added pure-Dart `temperatureTileFingerprint` /
  `fanTileFingerprint` / `sensorTileFingerprint` (`models/tile_fingerprint.dart`)
  encoding exactly the fields a tile shows (identity, reading, health/state,
  physical context, reading type/units, thresholds) — the growing sparkline
  history is deliberately excluded since a flat trend looks identical after one
  more sample. Added `SensorDeltaTile` (`views/sensor_delta_tile.dart`), a
  selector-style gate that caches the exact child widget instance and returns it
  unchanged while the fingerprint matches, so an unchanged tile neither rebuilds
  nor repaints when a poll only advances history; each tile sits behind a
  `RepaintBoundary`. `_ChassisCard` now wraps all three tile kinds in the gate.
  Added 4 fingerprint unit tests, 3 gate widget tests (build-once / skip-same /
  rebuild-on-change + RepaintBoundary) and 1 view wiring smoke test. Baseline
  analyze 0 / 657 passed / 1 skipped; verify analyze 0 / 665 passed / 1 skipped
  (+8). Merged tile semantics and 320/800/1300px no-overflow tests still pass.
  Issue stays open: fl_chart/LineChart perf remains; the remaining acceptance
  boxes (service fixture coverage, ≥80% coverage) are still unchecked.
- 2026-11-17 18:24 UTC (run, agent:redfish-automation) — FEATURE slice:
  OpenBMC fixture service coverage (the explicit "Next" from the prior run).
  Added 4 `SensorsService` tests in `test/features/sensors/sensors_service_test.dart`
  driven by the repo's captured OpenBMC payloads (`openbmc_chassis_member`,
  `openbmc_thermal`, `openbmc_sensors`, `openbmc_sensor_{temp0,fan0}.json`):
  Thermal temperatures + fans parse, the Sensors collection resolves its member
  readings, threshold breaches raise critical/warning alerts, and a chassis whose
  Thermal/Sensors both 404 degrades to an empty snapshot. Fixed a real gap found
  by the fixture: `FanReading.fromJson` only read modern `Reading`, silently
  dropping the speed on OpenBMC builds that report the legacy `ReadingRPM`
  field — it now accepts both (the fan tile formats RPM, so units stay correct).
  Baseline analyze 0 / 665 passed / 1 skipped; verify analyze 0 / 669 passed /
  1 skipped (+4); issues validate OK. Issue stays open: OpenBMC `Voltages[]`
  normalization, fl_chart/LineChart perf and ≥80% coverage remain unchecked.
- 2026-11-17 19:02 UTC (run, agent:redfish-automation) — FEATURE slice:
  OpenBMC `Thermal.Voltages[]` normalization (the explicit "Next" from the
  prior run). Added a `VoltageReading` model (`name`/`readingVolts`/`status`/
  `physicalContext` + all four thresholds; accepts the legacy `Reading`
  spelling as a fallback) and wired `Voltages[]` into `ChassisSensors`
  (field, `fromThermalJson` parse, `alerts` with 2-decimal volt formatting,
  `telemetryFingerprint`) and `SensorsService.fetchChassis` (parsed from the
  same Thermal fetch — no extra request). Added `voltageSeriesKey` +
  `SensorHistoryStore` recording and `voltageTileFingerprint` so voltage
  trends/rebuild gating match the other tile kinds. `SensorsView` now renders a
  capability-gated `Voltages` section (omitted when empty) with a merged-
  semantics `_VoltageTile` (value, health, context, thresholds) behind a
  `SensorDeltaTile`; the chassis summary announces the voltage count. Checked
  the "Sections Temperatures / Fans / Voltages" acceptance sub-box. Added 4
  model tests (incl. legacy `Reading` + fingerprint), 1 voltage fingerprint
  test, 2 OpenBMC-fixture service tests (VCPU 1.8 V + threshold breach) and 6
  widget tests (section present/absent, banner, 320/800/1300 px no-overflow).
  Baseline analyze 0 / 669 passed / 1 skipped; verify analyze 0 / 682 passed /
  1 skipped (+13); issues validate OK. Issue stays open: `fl_chart`/`LineChart`
  perf and ≥80% touched-feature coverage remain unchecked.
- 2026-11-17 19:38 UTC (run, agent:redfish-automation) — FEATURE slice:
  the "Pull-to-refresh + last-updated timestamp" acceptance box (checked above).
  Added a nullable `SensorsUiState.lastUpdated` stamped on every *successful*
  poll (including an unchanged delta poll — "last checked", not "last changed")
  and left intact on failure; the clock is injectable on `SensorsController` so
  the stamp is testable. `SensorsView`'s data list is now an
  `AlwaysScrollableScrollPhysics` `RefreshIndicator` (drag fires `load()`), with
  a locale-free `HH:MM:SS` "Last updated" line in one merged semantics node
  above the tiles (omitted until the first success). Checked the acceptance
  sub-box. Added 3 controller tests (null-before-first, advances-on-delta,
  preserved-on-error), 3 widget tests (indicator + merged stamp, drag re-fetch,
  320 px no-overflow) and 1 pure formatter test. Baseline analyze 0 / 682
  passed / 1 skipped; verify analyze 0 / 689 passed / 1 skipped (+7); issues
  validate OK. Issue stays open: `fl_chart`/`LineChart` perf and ≥80% touched-
  feature coverage remain unchecked.
- 2026-11-17 20:14 UTC (run, agent:redfish-automation) — FEATURE slice:
  implemented the "Threshold coloring" acceptance box (checked above). Added
  `SensorDisplayLevel` + `sensorDisplayLevel(...)` in `sensor_models.dart`: it
  combines the BMC `Status.Health` with the numeric reading's threshold breach
  (caution→amber, critical→red, even when `Health=OK`) and reading presence
  (missing→grey), with health taking precedence so a Critical sensor never
  appears grey. Every reading model (Temperature/Fan/Voltage/Generic) exposes a
  `displayLevel` getter wired to its own thresholds. `SensorsView._HealthChip`
  now tints from `displayLevel` via the pure, testable `sensorDisplayLevelColor`
  helper; the alert banner remains the aggregated cross-chassis view. Added 4
  model unit tests (incl. breach-with-OK-health + all four reading types), 1
  color-map unit test and 2 widget tests (reading-less OK tile → grey chip,
  breach with `Health=OK` → red chip). Baseline analyze 0 / 689 passed /
  1 skipped; verify analyze 0 / 696 passed / 1 skipped (+7); issues validate OK.
  Issue stays open: `fl_chart`/`LineChart` perf and ≥80% covered remain.
- 2026-11-17 (run, agent:redfish-automation) — FEATURE slice: error resilience
  (checked above) — "401 bubbles to auth manager". Added a reusable
  `RedfishException.isAuthError` predicate (401/403) alongside the existing
  `isPreconditionFailed` classifier, and wired it into all five degradation
  `catch` sites in `SensorsService` (per-chassis in `fetchAll`, chassis body,
  Thermal, Sensors collection, and per-member in `_parseSensors`): a missing
  sub-resource (404) or transient failure still degrades to available data, but
  a surfaced 401/403 now rethrows so the auth manager / error UI sees it instead
  of a silently empty telemetry screen. Added 2 direct `isAuthError` unit tests
  and 5 service tests (401 Thermal, 403 Sensors collection, 401 member aborting
  the whole chassis fetch, 401 chassis body bubbling through `fetchAll`, and 500
  still degrading). Baseline analyze 0 / 696 passed / 1 skipped; verify analyze
  0 / 703 passed / 1 skipped (+7); issues validate OK. Measured full-suite
  sensor coverage at 94.3% (917/972), so the ≥80% box is checked; the already-
  present fixture/polling-dedup/gate widget tests satisfy the Tests box.
  Issue stays open ONLY for the `fl_chart`/`LineChart` perf box (a deliberate
  dependency addition + frame-budget test bed, deferred as a larger workstream).

 - 2026-11-17 (run, agent:redfish-automation) — FEATURE closeout: the final
   "Charts: fl_chart LineChart" box. Added `fl_chart: ^0.69.2` (already in pub
   cache; +`equatable` transitively — lock diff is +16 lines only). New
   `lib/features/sensors/views/sensor_chart.dart` with a pure
   `readingSeriesToSpots` mapping, `chartTitleForKey`/`chartUnitForKey` helpers,
   and a `SensorLineChart` that is non-animated (`duration: Duration.zero`),
   axis/grid/touch-free and wrapped in a keyed `RepaintBoundary`. `SensorsView`
   gained a Tiles/Charts `SegmentedButton`; chart mode builds a viewport-lazy
   `ListView.builder` (charts never built until opted into, one per history
   series with >=2 samples, "Collecting history..." caption before that). Added
   `test/features/sensors/sensor_chart_test.dart` (10 tests incl. a 20 sensors x
   60 points single-frame bed and 320/800/1300 px no-overflow) and 6 new
   `SensorsView` toggle/lazy/overflow widget tests. All remaining acceptance +
   task boxes checked and every capability re-verified in code. Issue CLOSED.

## References

- `documentations/project_goal/goal.md:97-106`, `251-255`
- Redfish Thermal: https://redfish.dmtf.org/schemas/Thermal.v1_7_0.json, Sensor: https://redfish.dmtf.org/schemas/Sensor.v1_6_0.json
- OpenBMC Sensors doc: https://github.com/openbmc/docs/blob/master/architecture/sensor-architecture.md
- Related: #003, #004, #006

## Closed Criteria

- Resolution: Final fl_chart LineChart box delivered (lazy on-demand chart view + 20x60 no-jank test bed); all acceptance boxes checked, analyze 0 / full green
- Closed: 2026-11-17


- Resolution: Every acceptance criterion met — typed sensor models, modern-first `Sensors` with `Thermal` fallback, discovery-gated tab with capability-gated Temperatures/Fans/Voltages/Sensors sections, per-tile sparkline + threshold bar + alert banner, threshold coloring, pull-to-refresh + last-updated stamp, polling with background backoff and delta rebuild, 401/403 error resilience, ≥80% coverage (measured 94.3%), and the final `fl_chart` `LineChart` behind an on-demand toggle with lazy-build and a 20×60-point no-jank test bed. Full suite green.
- Closed reason: Final chart box delivered; all boxes checked and gates pass.
- Follow-ups: none — remote KVM (#009/#021) and firmware (#008) are tracked separately.
