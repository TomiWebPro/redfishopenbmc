---
id: "007"
title: "Sensor monitoring — temps, fans, voltages with realtime graphs"
status: open
priority: P2
type: feature
created: 2026-08-26
updated: 2026-08-26
closed: null
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

- [ ] `lib/features/sensors/models/sensor.dart` — `id, name, reading, units (°C/RPM/V), health, lowerThreshold{NonCritical,Critical,Fatal}, upperThreshold{...}, sensorType (Temperature/Fan/Voltage/Power), context (CPU/Ambient/Chassis), lastUpdated`
- [ ] `lib/features/sensors/sensors_service.dart` — 
  - Try modern first: `GET /redfish/v1/Chassis/{id}/Sensors` → collection of `Sensor.v1_6_0` (Reading, Thresholds, Status)
  - Fallback: `GET /Chassis/{id}/Thermal` → `Temperatures[]` + `Fans[]` + `Voltages[]` normalized into same `Sensor` list
  - Returns `List<Sensor>`; empty if chassis absent → caller hides tab
  - Polling `FutureProvider` every 5–10s when tab visible, backoff to 30s when background; delta: only rebuild tiles whose `Reading` changed
- [ ] Tab `lib/features/sensors/views/sensors_view.dart` — **only if** `features.sensorMonitoring==true` (else tab hidden, no placeholder):
  - Sections `Temperatures` / `Fans` / `Voltages` (omit empty sections)
  - Tile per sensor: name, reading + units, health dot, threshold range bar, mini sparkline (last 20 polls, ring buffer)
  - Alert banner if any sensor `Health==Critical/Warning` or `Reading` breaches `UpperThresholdCritical`
  - Pull-to-refresh + last-updated timestamp
- [ ] Charts: `fl_chart` `LineChart` per sensor (or single combined chart toggle); lazy-build, no jank on 20 sensors × 60 points
- [ ] Threshold coloring: `OK→green`, `Warning→amber` (breaches `NonCritical`), `Critical→red` (breaches `Critical`), grey if `Reading==null`
- [ ] Error resilience: sensor absent, 404 Sensors → fallback Thermal, both 404 → hide tab gracefully; 401 bubbles to auth manager
- [ ] Tests: `test/features/sensors/sensors_service_test.dart` — Thermal fixture from OpenBMC, Sensors collection fixture, threshold evaluation, empty chassis, polling dedup; widget test verifies hidden when `sensorMonitoring false`
- [ ] Coverage ≥80%

## Tasks

- [ ] Model `Sensor` + `Threshold` + adapter `thermalToSensors()`
- [ ] Service `SensorsService` + `SensorsNotifier` (Riverpod) with polling timer + ring buffer
- [ ] Widgets: `SensorsView`, `SensorTile`, `SensorChart`, `ThresholdBar`, `AlertBanner`
- [ ] Add `fl_chart` dep + chart perf test (ensure <16ms frame)
- [ ] Fixtures: capture OpenBMC `Thermal` + `Sensors` JSON under `test/fixtures/redfish/`
- [ ] Tests: 5 service + 3 widget
- [ ] Document fallback matrix in code comment + `progress/journal.md`

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

## References

- `documentations/project_goal/goal.md:97-106`, `251-255`
- Redfish Thermal: https://redfish.dmtf.org/schemas/Thermal.v1_7_0.json, Sensor: https://redfish.dmtf.org/schemas/Sensor.v1_6_0.json
- OpenBMC Sensors doc: https://github.com/openbmc/docs/blob/master/architecture/sensor-architecture.md
- Related: #003, #004, #006

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
