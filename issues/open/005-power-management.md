---
id: "005"
title: "Power management — Reset actions, state & animated feedback"
status: open
priority: P1
type: feature
created: 2026-08-26
updated: 2026-08-26
closed: null
assignee: unassigned
labels: [power, redfish, actions, ui]
estimated_tokens: 40000
---

# 005 — Power management — Reset actions, state & animated feedback

> Wire `ComputerSystem.Reset` to power ON/OFF/graceful/force controls, visualize `PowerState`, and enforce discovery-gated UI with confirmation + real-time feedback.

## Description

Power is the most used control. Must map to `POST /redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset` with `ResetType` and reflect `PowerState` transitions without hardcoding.

- Goal reference: `goal.md` §3.1 Power Management, §3.2 System Overview (power state), §172-178 Real-Time Feedback
- User story: As a user I can power on/off, graceful restart, or force reset a selected system, see its current power badge, confirm destructive actions, and watch animated transition while polling.
- Scope IN: `PowerService`, `PowerState` model, `ResetType` mapping, discovery-gated Power tab, confirmation flows, polling + optimistic UI, tests
- Scope OUT: Full System Overview cards (→ #006), sensors (→ #007)

## Goals / Acceptance Criteria

- [ ] `lib/features/power/power_service.dart` — `reset(systemId, ResetType) → Future<void>` 
  - Discovers target URI from `DiscoveryEngine.rawTree[system].Actions.#ComputerSystem.Reset.target` (fallback `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset`)
  - Body `{"ResetType": "<value>"}`, handles `202/204` + `202` with `Location` task monitor (log but don't implement full task polling — that's #008)
  - Allowed values filtered by `SystemFeatures.supportedResetTypes` + Redfish spec (`On`, `ForceOff`, `GracefulShutdown`, `GracefulRestart`, `ForceRestart`, `PowerCycle`, `Nmi`)
- [ ] `lib/features/power/models/power_state.dart` — `enum PowerState {on, off, poweringOn, poweringOff, unknown}` + `ResetType` enum + `fromRedfish(String)` where `PowerState` Redfish `On`→`on`, `Off`→`off`
- [ ] Power tab `lib/features/power/views/power_view.dart` — rendered **only if** `features.powerControl==true`; otherwise hidden (no placeholder). When gated on:
  - Power badge: `On` green / `Off` grey / transitioning animated pulse
  - Actions: `Power On`, `Force Off`, `Graceful Restart`, `Force Restart` (disable if `!supportedResetTypes.contains`)
  - Each destructive action → `AlertDialog` "This will <action> <system name>. Continue?" + `destructive` styling
  - Toast/snackbar on success/failure with `RedfishException.message`
- [ ] Live feedback: after `POST`, poll `GET /Systems/{id}` every 3s for 30s (or until `PowerState` stabilizes), animating badge transition; non-blocking (Riverpod `AsyncValue`, never freeze UI)
- [ ] Error handling: 403 → "insufficient privilege", 409 → "system busy", 400 invalid `ResetType` → friendly message from `@Message.ExtendedInfo`
- [ ] Tests: `test/features/power/power_service_test.dart` — mocked `Dio`: On/ForceOff/Restart, 403, 404 action missing, unsupported ResetType filtered; widget test: gated hidden when `powerControl false`, dialog appears, poll triggers
- [ ] Coverage ≥80% on `features/power/`

## Tasks

- [ ] Define enums + `PowerService` + `PowerController` (Riverpod)
- [ ] Implement URI resolution from discovery cache + fallback
- [ ] Build `PowerView` + `PowerBadge` + `ResetButton` + `ConfirmDialog`
- [ ] Implement polling notifier (`pollPowerState(systemId)`)
- [ ] Tests: 5 service + 2 widget
- [ ] Update `progress/journal.md`

## Redfish Mapping

| Action | Endpoint | Method | Body | Success |
|--------|----------|--------|------|---------|
| Reset | `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset` | `POST` | `{"ResetType":"On"}` etc. | `200/204` or `202`+`Location` |
| State read | `/redfish/v1/Systems/{id}` | `GET` | — | `{"PowerState":"On"/"Off"}` |

- Discovery key: `Systems/{id}.Actions.#ComputerSystem.Reset` + `ActionInfo` if present (allowed values)
- `AllowableValues` vs `SupportedResetTypes` — prefer `ActionInfo` if Redfish returns `@Redfish.ActionInfo`
- OEM: none for core power

## Progress Log

- 2026-08-26 — Created. Depends on #001 #002 #003 #004.

## References

- `documentations/project_goal/goal.md:60-72`, `76-85`, `172-178`
- Redfish ComputerSystem schema: https://redfish.dmtf.org/schemas/ComputerSystem.v1_20_0.json
- `lib/redfish/discovery/feature_rules.dart` (→ #003)
- Related: #003, #004, #006

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
