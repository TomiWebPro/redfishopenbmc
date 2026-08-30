---
id: "019"
title: "Sensors: implement real-time telemetry (polling/EventService) + retry"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-08-30
closed: null
assignee: unassigned
labels: [sensors, realtime, ux]
estimated_tokens: 16000
---

# 019 — Sensors: implement real-time telemetry

> The feature is advertised as "real-time" but `SensorsController.load()` runs once in `initState` (`sensors_view.dart:32-33`) with no polling loop, no EventService/SSE/WebSocket. Values never refresh. If the `SystemHandle` wasn't connected on first build, `service.fetchAll()` throws `NotConnected` and is never retried (`:42-45`). Error screen has no retry. `_parseSensors` does one GET per sensor member sequentially with no concurrency limit (hundreds of requests on large chassis).

## Description

- No refresh mechanism — single snapshot only.
- No retry after connection becomes available; permanent "Not connected".
- No error-recovery UI (only Overview has Retry).
- Unbounded sequential fetches risk timeouts on large chassis.

- Goal reference: `goal.md` §3.3 Sensor Monitoring (real-time)
- User story: As a user I see live sensor values that update, with retry on transient failures.
- Scope IN: add polling (or EventService subscription) with backoff; retry on connection; concurrency-limited fetches; Retry button.
- Scope OUT: historical graphs (future).

## Goals / Acceptance Criteria

- [ ] Telemetry refreshes on an interval (configurable) or via EventService when available.
- [ ] Retry when `SystemHandle` becomes connected; Retry button on error.
- [ ] Sensor fetches bounded (pooled concurrency).
- [ ] Timer/listener cancelled on dispose (no leak).

## Tasks

- [ ] Add polling/EventService in `sensors_controller.dart`/`sensors_service.dart`.
- [ ] Add retry wiring + Retry UI in `sensors_view.dart`.
- [ ] Add tests for refresh + error/retry.

## Redfish Mapping

| Feature | Endpoint | Notes |
|---------|----------|-------|
| Sensors collection | `/redfish/v1/Chassis/{id}/Sensors` | `Members` |
| Telemetry | `/redfish/v1/TelemetryService` / EventService | SSE/WebSocket (optional) |

- OEM: none

## Progress Log

- 2026-08-30 — Created from triage analysis (feature #12). See also #007.

## References

- `lib/features/sensors/sensors_view.dart:32-45,69-79`
- `lib/features/sensors/sensors_service.dart:152-170`
- `lib/features/sensors/sensors_controller.dart`
- Related: #007, #023

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
