---
id: "023"
title: "Overview: fix listenManual leak & swallowed async errors"
status: closed
priority: P3
type: bug
created: 2026-08-30
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [overview, riverpod, memory-leak]
estimated_tokens: 10000
---

# 023 — Overview: listener leak & swallowed async errors

> `overview_view.dart:54` uses `ref.listenManual(...)` whose returned dispose function is never called. Per Riverpod, `listenManual` listeners are NOT auto-cancelled on widget dispose, so the closure (capturing `lastPower`) leaks and keeps firing `_refresh` after dispose (guarded only by `mounted`). Separately, the 30s `Timer.periodic` (`:45-47,63-70`) calls `_refresh()` whose `await refreshSnapshot(...)` can throw; the Future is ignored inside the Timer callback → uncaught async error. `refreshSnapshot` itself swallows everything (`system_manager.dart:422` `catch (_)`), so transient failures are silently lost.

## Description

- Leaked `listenManual` listener.
- Uncaught async error in Timer; errors swallowed by `refreshSnapshot`.

- Goal reference: `goal.md` §3.2 System Overview
- User story: As a user the overview auto-refreshes without leaking listeners or hiding failures.
- Scope IN: store & call the `listenManual` dispose; handle Timer async errors; surface refresh failures.
- Scope OUT: layout changes.

## Goals / Acceptance Criteria

- [x] `listenManual` dispose invoked in `dispose()`.
- [x] Timer refresh errors handled (caught/logged, optionally surfaced).
- [x] `refreshSnapshot` does not blanket-swallow (rethrow or report).
- [x] Tests / static check for the leak.

## Tasks

- [x] Fix `overview_view.dart` listener + timer.
- [x] Adjust `system_manager.dart:422` error handling.
- [x] Tests in `test/features/overview/`.

## Redfish Mapping

- none (UI lifecycle)

## Progress Log

- 2026-11-16 — Stored and closed the `listenManual` subscription in `OverviewView`, handled timer/power-change refresh futures so transient refresh failures do not escape, and changed `SystemManager.refreshSnapshot` to preserve the previous snapshot but rethrow failures to callers. Updated the manual refresh button in `SystemOverviewPage` to catch transient failures. Added overview lifecycle tests (listener disposed, periodic refresh failure handled) and a system-manager test asserting refresh failures rethrow while preserving the snapshot.
- 2026-08-30 — Created from triage analysis (feature #16). See also #019, #006.

## References

- `lib/features/overview/views/overview_view.dart:45-70`
- `lib/features/systems/providers/system_manager.dart:411-425`
- Related: #006, #019

## Closed Criteria

- Resolution: `OverviewView` now owns and closes its `ProviderSubscription`, timer/power-triggered refreshes are awaited/handled safely, and `refreshSnapshot` reports transient failures to callers without replacing the previous snapshot.
- Closed reason: Implemented with targeted and full verification (analyze 0, flutter test green, issues validate OK).
- Follow-ups: none
