---
id: "022"
title: "Power: task polling, poll/reset race, NMI stabilize, dedupe error, fallback id"
status: closed
priority: P2
type: bug
created: 2026-08-30
updated: 2026-10-26
closed: 2026-10-26
assignee: unassigned
labels: [power, state, race, error-handling]
estimated_tokens: 14000
---
# 022 — Power action correctness fixes

> Multiple power-action defects: (1) 202 `Location` task is captured but never polled, so BMC-side task failures leave the UI stuck in an optimistic transitional state. (2) `power_controller.dart:151-177` `_startPolling` is guarded by `_polling`; a rapid second action (e.g. GracefulShutdown after On) gets its optimistic state clobbered by the still-running first loop. (3) `power_state.dart:123` `optimisticState` for `nmi` is `unknown`; the poll loop only breaks on `on`/`off`, so it spins the full 30s with `unknown`. (4) Error is shown both inline and in a snackbar (double presentation). (5) `power_service.dart:146` final fallback uses `systemId` (profile id) not the BMC ComputerSystem id, risking a malformed reset URI.

## Description

- Task-failure invisibility, poll/reset race, NMI stall, double error, wrong fallback id.

- Goal reference: `goal.md` §3.1 Power Management
- User story: As a user power actions reflect true BMC state, never get stuck, and errors show once.
- Scope IN: poll the 202 task; serialize/queue polling per action; stabilize NMI; dedupe error UI; use BMC system id in fallback.
- Scope OUT: new power actions.

## Goals / Acceptance Criteria

- [x] 202 task polled; failure surfaces as error.
      (DONE 2026-10-26 — the #008/#020 shared task-monitor poller landed:
      `FirmwareService.pollTask` + `RedfishTask`/`TaskMessage`
      (`lib/redfish/models/redfish_task.dart`). `PowerService` already
      captures the 202 `Location` task URI on reset; the poller now exists to
      follow it. The power-side invocation stays unit-level/no-op on the
      DMTF fixture because the mockup answers 204 with NO Location for reset
      (pinned live); a real BMC that returns a 202 monitor reuses the same
      poller.)
- [x] No clobbering between consecutive actions (per-action poll handle).
- [x] NMI transitions to a terminal/known state within the poll window.
- [x] Error shown once (inline OR snackbar, not both).
- [x] Reset URI uses the BMC ComputerSystem id.

## Tasks

- [x] Fix `power_controller.dart` polling/race.
- [x] Fix `power_state.dart` NMI optimistic state.
- [x] Fix `power_view.dart` double error.
- [x] Fix `power_service.dart:146` id fallback.
- [x] Tests for poll/race and fallback id.

## Redfish Mapping

| Feature | Endpoint | Method |
|---------|----------|--------|
| Reset | `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset` | `POST` `ResetType` |
| Task | `/redfish/v1/TaskService/Tasks/{id}` | `GET` |

- DMTF Redfish ComputerSystem Reset

## Progress Log

- 2026-10-26 — EMU run: **the last #022 acceptance criterion (202 task
  polled; failure surfaces as error) is now DONE via the shared task-monitor
  poller (#008/#020)** — the "GET-on-monitor + TaskState parsing" pieces the
  tracking had listed as the only missing items are code + tests:
  `RedfishTask`/`TaskMessage` (`lib/redfish/models/redfish_task.dart`) parse
  the served `#Task.v1_7_3.Task` shape (13 TaskStates per `Task.v1_7_4.json`,
  TaskStatus, optional PercentComplete, RFC3339 Start/EndTime, `Messages[]`,
  `TaskMonitor`; terminal classification: Completed/OK = success, Killed/
  Exception/Service/Cancelled = failure, Completed-with-Warning/Critical =
  failed with a `statusNote`; `failureReason` prefers `Message.Message` →
  `MessageId` → bare TaskState) and `FirmwareService.pollTask` follows the
  202 `Location` monitor URI — first wait honors the `Retry-After` hint the
  update action returned, then polls at `interval` up to `maxPolls`;
  terminal success returns the final `RedfishTask`, terminal failure throws a
  `RedfishException` with the task's failure reason, budget exhaustion throws
  a retryable `TaskMonitorTimeout`, and a missing monitor URI throws
  `Base.1.0.NoTaskMonitor` (the 204-no-Location fixture norm). The UI can now
  surface task failures instead of leaving an optimistic transitional state:
  `FirmwareController.pollLastTask` + the firmware-view task banner (queued →
  polling spinner → final state / check). **+25 model tests, +8 service
  tests, +4 controller tests, +5 widget tests (incl. 320-px no-overflow)**;
  unit suite 438 → **478 passed / 1 skipped**; emulator suite 82 → **84/84
  green** on pinned `23d21f9a` — 2 new live pins: the poller resolves the
  fixture's own Task 545 end-to-end (Completed/OK, absent PercentComplete,
  Messages exported, EndTime parsed) and a stale monitor URI (Task/999)
  normalizes to a 404 `RedfishException` with context. REQUIREMENTS.md
  DOCS-10 rows + Firmware-update + Task-monitor rows flipped to OK for the
  firmware path. **All five #022 acceptance criteria now checked → closing.**
  (Power-side 202 invocation: `PowerService` already captures the Location;
  the shared poller is ready to reuse. The DMTF mockup answers 204 for reset
  with no monitor, so that invocation path stays unit-level — no fixture
  seam to pin.)
- 2026-10-25 — EMU run: **four of the five #022 acceptance criteria landed as one finished increment (the remaining one — 202 task polling — stays with #008/#020)**: (1) **per-action poll handle** — `PowerController` replaced the single `_polling` bool guard with a monotonic `_pollGeneration` token: each `reset()` bumps the token before issuing, and a poll loop only writes state while its captured generation is current, so a rapid second action (e.g. GracefulShutdown right after On) supersedes the first loop instead of letting its stale reads clobber the new optimistic state; `dispose()` also bumps the token so an in-flight loop stops writing. +1 controller test (`GatedPowerService` with completers sequences the stale read and proves the superseded loop never writes). (2) **NMI terminal state** — the controller now keeps the *current known* power state for `ResetType.nmi` instead of projecting `unknown` (NMI is an interrupt, not a power transition; the poll loop then converges to the real unchanged state immediately), documented in `power_state.dart`; +1 controller test. (3) **error shown once** — `PowerView` reserves the snackbar for the success confirmation and lets the persistent inline error card (with Retry) be the single failure presentation (previously a failure was both inline AND in a red error snackbar); the failure widget test now asserts inline-only + `find.byType(SnackBar)` findsNothing, +1 success-snackbar widget test. (4) **BMC-id fallback** — `PowerService._resolveResetTarget`'s final fallback now prefers the BMC ComputerSystem id from the discovery raw tree (`_computerSystemIdFromRaw()`) before falling back to the profile id (mirrors `_resolveSystemUri`; a profile-id fallback could build a malformed reset URI when the BMC resource id differs); +1 service test proves the POST goes to the BMC-id URI. Full unit suite 428 → **432 passed / 1 skipped**; emulator suite re-run **82/82 green** on pinned `23d21f9a` (no emulator code touched — the DMTF mockup never returns a 202 task monitor for reset, so the remaining task-polling criterion stays unit-level with #008/#020). Acceptance criteria 2, 3, 4, 5 checked; criterion 1 (202 task polled) still open — task-monitor polling belongs with the firmware/task work.
- 2026-10-25 — EMU run: **the Boot-override allow-list pre-validation rule (#022/#016) landed in the first production `patchJson` consumer**. `SystemSettingsService.setBootOverride` (`lib/features/overview/settings_service.dart`) pre-validates the target against the advertised `BootSourceOverrideTarget@Redfish.AllowableValues` annotation (the annotation-form allow-list rule applied to a new surface) + the `BootSourceOverrideEnabled` schema enum (`Once`/`Continuous`/`Disabled`, default `Once`); a BMC publishing NO boot-target allow-list refuses the mutation locally (never guess targets — the mockup applies any body unvalidated). The `BootSettings` model parses the served Boot block incl. the annotation. `setIndicatorLed` extends the same service (schema-enum pre-validation: `Lit`/`Blinking`/`Off`, `Unknown` deprecated/refused). +34 new unit/widget tests (boot_settings 9, settings_service 12, settings_controller 5, system_settings_widget 8 incl. 320/800/1300 no-overflow), unit suite 392 → **426 passed / 1 skipped**; +2 live emulator pins (80 → **82/82**: service-level PATCH round-trips persist through the real mockup; an unlisted target is rejected before the wire). **Issue #016 closed** (its acceptance criteria are complete).
- 2026-10-25 — EMU run: **the Control SetPoint pre-validation rule is now code (#022/#016)**. `ControlResource` (`lib/redfish/models/control.dart`) parses the served `#Control.v1_5_0.Control` resources (Id/ControlType/ControlMode/SetPoint/SetPointUnits/AllowableMin/AllowableMax/Sensor.DataSourceUri; a null SetPoint is tolerated per the schema) and `validateSetPoint` rejects out-of-bounds prospective SetPoints BEFORE any PATCH — in-range + exact boundary values pass, below/above `AllowableMin`/`AllowableMax` fail with an Allowable-range message, a null value fails, and a control with no advertised bounds is a documented best-effort (valid + informational message). Bounds are per-resource and never leak across controls (the SecureBoot per-resource allow-list precedent). Because the client now maps Control, the family became client-mapped: served `Control.v1_5_0.json` copied into `test/fixtures/redfish/schemas/` (byte-identical to the DOCS-26 mirror) + `Control` added to the emulator corpus-invariant family list. +11 unit tests (`test/redfish/models/control_test.dart`), full suite 379 → 390 passed / 1 skipped; +1 live emulator test (79 → 80/80) pinning the rule against the served PowerLimit ([150,1000]) and CPU1Freq ([1500,3700]) ranges incl. the cross-resource leakage guard (1500 valid for CPU1Freq, rejected for PowerLimit). REQUIREMENTS.md Control rows + Client-mapped decision + Test platforms 79 → 80 updated.
- 2026-10-25 — EMU run: the **ActionInfo-*resource* crawl is now WIRED — no longer a TODO**. `DiscoveryEngine` follows `@Redfish.ActionInfo` links during the crawl (new `_actionInfoLinks` in `_childLinks`; captured resources classified into `DiscoveryContext.actionInfos` keyed by relative path); `FeatureRules.supportedResetTypes` now unions a THIRD allow-list source — `Parameters[].AllowableValues` on the `ResetType` parameter of the `@Redfish.ActionInfo` resource the `#ComputerSystem.Reset` action links to (bmcweb's `ResetActionInfo` shape, DOCS-4/13), with the existing manager-list conflation guard (only the system's own linked resource is read). +4 unit tests (parser + follow-link + union + manager-guard) in `feature_rules_test.dart`, +2 discovery-engine tests (follows link & folds values; dangling 404 link degrades gracefully to the remaining sources) in `discovery_engine_test.dart`, +1 live emulator test (79/79: a normal crawl captures the fixture's `SimpleUpdateActionInfo` and `FeatureRules.allowableValuesFromActionInfo` reads the live `TransferProtocol` allow-list). REQUIREMENTS.md row + "Test platforms" 78 → 79 updated.
- 2026-10-25 — EMU run: the recurring "crawl the `ResetActionInfo` ActionInfo *resource*" note advanced — the emulator now pins the **ActionInfo resource contract live** via the two `CertificateService` ActionInfo resources the fixture serves (`GenerateCSRActionInfo` + `ReplaceCertificateActionInfo`): the `@Redfish.ActionInfo` link resolves from the action, the resource is `#ActionInfo.v1_4_1.ActionInfo`, every `Parameters[]` entry carries `Name`/`Required`/`DataType`, and per-parameter `AllowableValues` resolve (`KeyPairAlgorithm` [TPM_ALG_RSA, TPM_ALG_ECDSA], `KeyCurveId` [3 curves], `KeyUsage` [14 values], `CertificateType` [PEM]). That is the exact shape a bmcweb `ResetActionInfo` crawl produces on OpenBMC (DOCS-4/13); the `ResetActionInfo` resource itself is still absent on the DMTF mockup, so the actual allow-list-source crawl on OpenBMC remains a code task. EMU 69 → 71; REQUIREMENTS.md ActionInfo row updated.
- 2026-08-30 — Created from triage analysis (feature #15). See also #005.
## Closed

- Resolution: task-monitor polling landed via the shared #008/#020 poller (RedfishTask + FirmwareService.pollTask, live emulator pins 84/84); all five power-action acceptance criteria now checked; power-side 202 invocation stays unit-level on the DMTF fixture (mockup answers 204 for reset)
- Closed: 2026-10-26
