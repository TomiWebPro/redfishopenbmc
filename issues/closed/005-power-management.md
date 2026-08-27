---
id: "005"
title: "Power management — Reset actions, state & animated feedback"
status: closed
priority: P1
type: feature
created: 2026-08-26
updated: 2026-08-27
closed: 2026-08-27
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

- [x] `lib/features/power/power_service.dart` — `reset(systemId, ResetType) → Future<void>` 
  - Discovers target URI from `DiscoveryEngine.rawTree[system].Actions.#ComputerSystem.Reset.target` (fallback `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset`)
  - Body `{"ResetType": "<value>"}`, handles `202/204` + `202` with `Location` task monitor (log but don't implement full task polling — that's #008)
  - Allowed values filtered by `SystemFeatures.supportedResetTypes` + Redfish spec (`On`, `ForceOff`, `GracefulShutdown`, `GracefulRestart`, `ForceRestart`, `PowerCycle`, `Nmi`)
- [x] `lib/features/power/models/power_state.dart` — `enum PowerState {on, off, poweringOn, poweringOff, unknown}` + `ResetType` enum + `fromRedfish(String)` where `PowerState` Redfish `On`→`on`, `Off`→`off`
- [x] Power tab `lib/features/power/views/power_view.dart` — rendered **only if** `features.powerControl==true`; otherwise hidden (no placeholder). When gated on:
  - Power badge: `On` green / `Off` grey / transitioning animated pulse
  - Actions: `Power On`, `Force Off`, `Graceful Restart`, `Force Restart` (disable if `!supportedResetTypes.contains`)
  - Each destructive action → `AlertDialog` "This will <action> <system name>. Continue?" + `destructive` styling
  - Toast/snackbar on success/failure with `RedfishException.message`
- [x] Live feedback: after `POST`, poll `GET /Systems/{id}` every 3s for 30s (or until `PowerState` stabilizes), animating badge transition; non-blocking (Riverpod `AsyncValue`, never freeze UI)
- [x] Error handling: 403 → "insufficient privilege", 409 → "system busy", 400 invalid `ResetType` → friendly message from `@Message.ExtendedInfo`
- [x] Tests: `test/features/power/power_service_test.dart` — mocked `Dio`: On/ForceOff/Restart, 403, 404 action missing, unsupported ResetType filtered; widget test: gated hidden when `powerControl false`, dialog appears, poll triggers
- [x] Coverage ≥80% on `features/power/`

## Tasks

- [x] Define enums + `PowerService` + `PowerController` (Riverpod)
- [x] Implement URI resolution from discovery cache + fallback
- [x] Build `PowerView` + `PowerBadge` + `ResetButton` + `ConfirmDialog`
- [x] Implement polling notifier (`pollPowerState(systemId)`)
- [x] Tests: 5 service + 2 widget
- [x] Update `progress/journal.md`

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
- 2026-08-27 — agent:opencode — Completed. `PowerService.reset` issues
  `POST .../Actions/ComputerSystem.Reset` with Redfish `ResetType`, resolving the
  target from the discovery raw tree → known `@odata.id` → live `/redfish/v1/Systems`
  crawl (final fallback `/redfish/v1/Systems/{id}`). Unsupported types rejected
  locally via `SystemFeatures.supportedResetTypes`; 202+Location treated as
  accepted (task polling deferred to #008). `PowerState`/`ResetType` enums +
  `PowerController` (optimistic state + 3s/30s polling, non-blocking) + Riverpod
  `powerServiceProvider`/`powerControllerProvider` families. `PowerView` is gated on
  `features.powerControl` (renders nothing otherwise), shows animated `PowerBadge`
  (pulse only while transitioning), `ResetButton`s (destructive styled, disabled
  when unsupported), and a `ConfirmResetDialog`. Error taxonomy: 403 → insufficient
  privilege, 409 → system busy, 400 → `@Message.ExtendedInfo` message. Tests: 37
  (service + controller + view + providers + model) all green; `flutter analyze`
  0 issues; `features/power/` line coverage 87.4% (gate ≥80%). Fixed latent
  test-harness bugs inherited from the prior session: `PowerBadge` repeating
  animation (blocked `pumpAndSettle`), `RedfishError` extended-info parsing, and
  garbled/duplicate test scaffolding (`power_models_test`, `scratch_debug_test`).
  Whole suite: 182 tests green, ~1 integration skip.

## References

- `documentations/project_goal/goal.md:60-72`, `76-85`, `172-178`
- Redfish ComputerSystem schema: https://redfish.dmtf.org/schemas/ComputerSystem.v1_20_0.json
- `lib/redfish/discovery/feature_rules.dart` (→ #003)
- Related: #003, #004, #006

## Closed Criteria

- Resolution: Power management complete: reset/force-off/state/poll, discovery-gated UI, error taxonomy; analyze 0, 37 power tests green, 87.4% power coverage; full suite 182 passed
- Closed: 2026-08-27


- Resolution: Implemented per Acceptance Criteria + Tasks + Redfish Mapping. All checkboxes complete; `flutter analyze` 0 issues; 37 power tests green; `features/power/` coverage 87.4% ≥ gate 80%.
- Closed reason: Power management delivery complete — reset actions, state visualization, discovery-gated UI, confirmation flows, live polling feedback, and the full error taxonomy are implemented and tested.
- Follow-ups: #008 (task-monitor polling for 202+Location), richer multi-reset sequencing, and an a11y pass (covered by #010).
