---
id: "020"
title: "Firmware: binary upload, task progress tracking & fix non-202 masking"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-10-26
closed: null
assignee: unassigned
labels: [firmware, upload, error-handling]
estimated_tokens: 18000
---

# 020 — Firmware: implement real update flow

> Only `SimpleUpdate` with a remote `ImageURI` is implemented (`firmware_service.dart:127-152`). No file picker, no binary/multipart POST, and the advertised `httpPushUri` (`firmware_models.dart:131`) is shown but never used. `startUpdate` stores `lastTaskUri` but never polls the task; `UpdateTask` model is unused; no progress UI. Critically, `firmware_service.dart:147-148` returns `''` for *any* non-202 status (including 400/500), so real failures are masked as success ("no task URI returned").

## Description

- No local binary upload path (core requirement for air-gapped BMCs).
- No task polling → failures invisible; view stuck on "Update queued…" (`firmware_view.dart:105-114`).
- Non-202 responses swallowed as success.

- Goal reference: `goal.md` §3.4 Firmware Update Management
- User story: As a user I can push a local image and watch real progress/errors.
- Scope IN: `MultipartFile`/`FormData` POST to `httpPushUri`; task polling + progress; throw on non-202/non-2xx.
- Scope OUT: staged/dual-image rollback flows (future).

## Goals / Acceptance Criteria

- [ ] Binary upload via `httpPushUri` (file picker + multipart).
- [ ] Task polling drives a progress bar using `UpdateTask`.
- [ ] Non-2xx responses throw (no silent `''` success).
- [ ] Tests cover success, task-failure, and error masking.

## Tasks

- [ ] Add upload path in `firmware_service.dart`.
- [ ] Add task polling in `firmware_controller.dart` + progress UI.
- [ ] Fix `:147-148` to throw on failure.
- [ ] Tests in `test/features/firmware/`.

## Redfish Mapping

| Feature | Endpoint | Method |
|---------|----------|--------|
| SimpleUpdate | `/redfish/v1/UpdateService` `Actions/UpdateService.SimpleUpdate` | `POST` (ImageURI) |
| Push update | `UpdateService.HttpPushUri` | `POST` multipart |
| Task monitor | `/redfish/v1/TaskService/Tasks/{id}` | `GET` |

- DMTF Redfish UpdateService / TaskService

## Progress Log

- 2026-10-26 — EMU run: **the task-polling piece of #020 (and the shared
  #022 criterion) landed**. `RedfishTask`/`TaskMessage`
  (`lib/redfish/models/redfish_task.dart`) parse the served `#Task.v1_7_3.Task`
  resource (TaskState, TaskStatus, optional `PercentComplete`, RFC3339
  Start/EndTime, `Messages[]`) and `FirmwareService.pollTask` follows the 202
  `Location` task-monitor URI the way a real firmware update's async operation
  does (DSP0266 §12.2): first wait honors `Retry-After`, then polls at
  `interval` up to `maxPolls`; terminal Completed/OK → success, terminal
  failure → `RedfishException` with the task's failure reason, budget
  exhaustion → retryable `TaskMonitorTimeout`. `FirmwareController.
  pollLastTask` + the firmware-view task banner (queued → polling spinner →
  final state / success check) consume it, so a BMC-side task failure now
  surfaces as an error instead of leaving the view stuck on "Update queued…".
  +25 model tests, +8 service tests, +4 controller tests, +5 widget tests;
  unit suite 438 → **478 passed / 1 skipped**; emulator 82 → **84/84 green**
  (2 new live pins: poller resolves the fixture Task 545 end-to-end + stale
  monitor → normalized 404). **Remaining #020 items unchanged:** binary/
  multipart upload via `httpPushUri`/`MultipartHttpPushUri` (file picker +
  upload progress), a live progress bar from `PercentComplete` (absent on the
  fixture; the poller already tolerates it), and the non-202 masking fix
  (`startSimpleUpdate` already throws on non-2xx via `_toFriendly` — the
  "returns '' for any non-202" defect from the original description is fixed
  by the 202/204 normalization in `startSimpleUpdate`).
- 2026-08-30 — Created from triage analysis (feature #13). See also #008.

## References

- `lib/features/firmware/firmware_service.dart:127-152,147-148`
- `lib/features/firmware/firmware_models.dart:131,205-218`
- `lib/features/firmware/firmware_controller.dart:108`
- `lib/features/firmware/views/firmware_view.dart:105-114`
- Related: #008

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
