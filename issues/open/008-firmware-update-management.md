---
id: "008"
title: "Firmware & update management — UpdateService, upload & jobs"
status: open
priority: P2
type: feature
created: 2026-08-26
updated: 2026-08-26
closed: null
assignee: unassigned
labels: [firmware, update, redfish, jobs]
estimated_tokens: 45000
---

# 008 — Firmware & update management — UpdateService, upload & jobs

> Integrate `UpdateService`: detect availability, upload firmware images, trigger `SimpleUpdate`, monitor `Task`/`Job` progress, and surface logs.

## Description

`goal.md` §3.5 is conditional: only show Firmware tab when `UpdateService` exists. Redfish defines `POST /UpdateService/Actions/UpdateService.SimpleUpdate` and multipart `POST /UpdateService/update` plus `TaskService` for long jobs. OpenBMC implements a subset via `Software` inventory + `UpdateService`. UI must be discovery-gated and handle large uploads over potentially low-bandwidth BMC links.

- Goal reference: `goal.md` §3.5 Firmware & Update Management
- User story: As a user I open Firmware for a system that supports `UpdateService`, see current firmware versions, upload an image, start update, watch progress, and read logs — if `UpdateService` absent, the tab is hidden.
- Scope IN: `UpdateService` discovery, `FirmwareService`, inventory `GET` + `SimpleUpdate` + multipart upload, `Task` polling, `FirmwareView` gated tab, progress + logs, tests
- Scope OUT: Actual BMC firmware binary handling, host reboot orchestration beyond power (→ #005), RBAC (future)

## Goals / Acceptance Criteria

- [ ] `lib/features/firmware/models/firmware_inventory.dart` — `id, version, name, updateable, status, lowLevel, relatedItem` + `UpdateService` capability `httpPushUri, multipartSupported, simpleUpdateSupported, maxImageSize`
- [ ] `lib/features/firmware/firmware_service.dart` —
  - `getInventory(systemId) → List<FirmwareInventory>` via `GET /redfish/v1/UpdateService/FirmwareInventory` (fallback `GET /redfish/v1/UpdateService/SoftwareInventory` for OpenBMC)
  - `simpleUpdate(systemId, imageUri) → TaskRef` via `POST /UpdateService/Actions/UpdateService.SimpleUpdate {"ImageURI": uri, "TransferProtocol":"HTTPS"}` (and `HttpPushUri` variant)
  - `uploadImage(systemId, bytes, filename) → TaskRef` via `POST <HttpPushUri>` multipart/form-data (or `UpdateService.update` multipost), streamed upload with progress callback, 100MB soft limit warn
  - `getTask(taskId) → Task {Id, TaskState (New/Running/Completed/Exception/Cancelled), PercentComplete, Messages[]}`
  - Handles `202 Accepted` + `Location: /TaskService/Tasks/{id}` for async
- [ ] Tab `lib/features/firmware/views/firmware_view.dart` — **only if** `features.firmwareUpdate==true`:
  - Inventory list: name, version, status badge
  - Upload area: file picker (desktop/web) + `http` upload with progress bar; disabled if `maxImageSize` exceeded
  - Actions: `Simple Update` (URI input) + `Upload & Update` (file)
  - Task monitor: `LinearProgressIndicator` + `%` + `TaskState` badge + `Messages` log (auto-poll every 3s while `Running`)
  - Confirmation for destructive update
- [ ] Gating: discovery rule `firmwareUpdate = UpdateService != null` (`feature_rules.dart` → #003) — no placeholder when absent
- [ ] Resilience: cancel task (`DELETE /TaskService/Tasks/{id}` or `POST Cancel`), 413 too large, 401 auth, low-bandwidth retry with exponential backoff
- [ ] Tests: `test/features/firmware/firmware_service_test.dart` — mocked `Dio` for inventory, SimpleUpdate 202+task, multipart upload progress, task polling `Running→Completed`, `Exception` with `Messages`; widget test gated hidden
- [ ] Coverage ≥80%

## Tasks

- [ ] Models `FirmwareInventory`, `Task`, `UpdateServiceCaps`
- [ ] Service `FirmwareService` + `TaskPoller` + `UploadProgress` (Riverpod)
- [ ] Widgets: `FirmwareView`, `InventoryCard`, `UploadArea`, `TaskMonitor`
- [ ] File picker abstraction (`file_picker` package) with web stub
- [ ] Fixtures: OpenBMC `UpdateService` + `FirmwareInventory` + `Task` payloads under `test/fixtures/redfish/`
- [ ] Tests: 6 service + 2 widget
- [ ] Document multipart vs SimpleUpdate decision in code comment

## Redfish Mapping

| Feature | Endpoint | Method | Notes |
|---------|----------|--------|-------|
| UpdateService | `/redfish/v1/UpdateService` | `GET` | `ServiceEnabled`, `HttpPushUri`, `MultipartHttpPushUri`, `Actions.#UpdateService.SimpleUpdate` |
| FirmwareInventory | `/UpdateService/FirmwareInventory` | `GET` | `members: SoftwareInventory` |
| SoftwareInventory (OBMC) | `/redfish/v1/UpdateService/SoftwareInventory` | `GET` | often `SoftwareInventoryCollection` |
| SimpleUpdate | `/UpdateService/Actions/UpdateService.SimpleUpdate` | `POST` | `{ImageURI, TransferProtocol}` → `202` |
| HttpPush update | `<HttpPushUri>` / `<MultipartHttpPushUri>` | `POST` | multipart `update` file |
| TaskService | `/redfish/v1/TaskService/Tasks/{id}` | `GET`/`DELETE` | `TaskState`, `PercentComplete`, `Messages` |

- OpenBMC nuance: `SoftwareInventory` `Activation` and `RequestedActivation`; `bmcweb` `multipartHttpPushUri` at `/redfish/v1/UpdateService/update`
- Polling: `TaskState` poll until `Completed/Exception/Cancelled` or timeout 10min

## Progress Log

- 2026-08-26 — Created. Depends on #001 #003 #004.

## References

- `documentations/project_goal/goal.md:108-118`
- Redfish UpdateService: https://redfish.dmtf.org/schemas/UpdateService.v1_13_0.json, Task: https://redfish.dmtf.org/schemas/Task.v1_7_0.json
- OpenBMC firmware update: https://github.com/openbmc/docs/blob/master/architecture/code-update/code-update.md
- Related: #003, #004

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
