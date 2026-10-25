---
id: "022"
title: "Power: task polling, poll/reset race, NMI stabilize, dedupe error, fallback id"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-10-25
closed: null
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

- [ ] 202 task polled; failure surfaces as error.
- [ ] No clobbering between consecutive actions (per-action poll handle).
- [ ] NMI transitions to a terminal/known state within the poll window.
- [ ] Error shown once (inline OR snackbar, not both).
- [ ] Reset URI uses the BMC ComputerSystem id.

## Tasks

- [ ] Fix `power_controller.dart` polling/race.
- [ ] Fix `power_state.dart` NMI optimistic state.
- [ ] Fix `power_view.dart` double error.
- [ ] Fix `power_service.dart:146` id fallback.
- [ ] Tests for poll/race and fallback id.

## Redfish Mapping

| Feature | Endpoint | Method |
|---------|----------|--------|
| Reset | `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset` | `POST` `ResetType` |
| Task | `/redfish/v1/TaskService/Tasks/{id}` | `GET` |

- DMTF Redfish ComputerSystem Reset

## Progress Log

- 2026-10-25 — EMU run: the recurring "crawl the `ResetActionInfo` ActionInfo *resource*" note advanced — the emulator now pins the **ActionInfo resource contract live** via the two `CertificateService` ActionInfo resources the fixture serves (`GenerateCSRActionInfo` + `ReplaceCertificateActionInfo`): the `@Redfish.ActionInfo` link resolves from the action, the resource is `#ActionInfo.v1_4_1.ActionInfo`, every `Parameters[]` entry carries `Name`/`Required`/`DataType`, and per-parameter `AllowableValues` resolve (`KeyPairAlgorithm` [TPM_ALG_RSA, TPM_ALG_ECDSA], `KeyCurveId` [3 curves], `KeyUsage` [14 values], `CertificateType` [PEM]). That is the exact shape a bmcweb `ResetActionInfo` crawl produces on OpenBMC (DOCS-4/13); the `ResetActionInfo` resource itself is still absent on the DMTF mockup, so the actual allow-list-source crawl on OpenBMC remains a code task. EMU 69 → 71; REQUIREMENTS.md ActionInfo row updated.
- 2026-08-30 — Created from triage analysis (feature #15). See also #005.

## References

- `lib/features/power/power_controller.dart:151-177`
- `lib/features/power/power_state.dart:123`
- `lib/features/power/power_view.dart:77-86,144-153`
- `lib/features/power/power_service.dart:146,170`
- Related: #005

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
