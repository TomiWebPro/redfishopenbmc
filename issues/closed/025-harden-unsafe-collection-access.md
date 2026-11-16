---
id: "025"
title: "Harden unsafe .first / as casts against empty or null collections"
status: closed
priority: P3
type: bug
created: 2026-08-30
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [robustness, null-safety, hardening]
estimated_tokens: 12000
---
# 025 — Harden unsafe collection access

> Several spots call `.first` on collections that may be empty (→ `StateError`) or use non-nullable `as List<dynamic>` casts on possibly-null values (→ `CastError`):
> - `kvm_service.dart:95` `consoles.first`
> - `firmware_service.dart:98` `inventoryLinks.first`
> - `power_service.dart:170` `members.first`
> - `overview_service.dart:41,59` `members.first` / `chassisList.first`
> - `system_overview.dart:238` `temps.first`
> - `system_snapshot_fetcher.dart:20` `members.first as Map<String,dynamic>`
> - `sensor_models.dart:262,265` `as List<dynamic>` (not `?`)

## Description

BMC responses are untrusted and frequently omit collections. These accesses can crash where a defensive `firstOrNull` / null-aware cast would degrade gracefully.

- Goal reference: `goal.md` §3 Robustness against heterogeneous BMCs
- User story: As a user the app never crashes on a BMC that omits an expected collection.
- Scope IN: replace unsafe `.first` with `firstOrNull` + guards; use null-safe casts.
- Scope OUT: broader schema tolerance (tracked elsewhere).

## Goals / Acceptance Criteria

- [x] All listed `.first` usages guarded against empty.
- [x] `as List<dynamic>` replaced with safe handling.
- [x] Tests with empty/missing collections don't throw.

## Tasks

- [x] Audit & fix each listed site.
- [x] Add regression tests with empty payloads.

## Redfish Mapping

- none (defensive parsing)

## Progress Log

- 2026-11-16 — Hardened listed access sites: `KvmService.fetchPrimaryConsole` uses `firstOrNull`; `FirmwareService.fetchUpdateService` guards empty/invalid inventory URI before GET; `PowerService._liveSystemUri` and `OverviewService.fetchOverview` use null-safe first-member access; `SystemOverview.fromSystemJson` and `ChassisSensors.fromThermalJson` safely handle missing/non-list Temperatures/Fans; `fetchSystemSnapshot` tolerates non-map/empty member entries without casting/`StateError`. Added regression tests in `test/features/systems/system_snapshot_fetcher_test.dart`, `test/features/sensors/sensors_model_test.dart`, and `test/features/overview/overview_provider_test.dart`. Analyze/tests green.
- 2026-08-30 — Created from triage analysis (safe-access #18).

## References

- `lib/features/kvm/kvm_service.dart:95`
- `lib/features/firmware/firmware_service.dart:98`
- `lib/features/power/power_service.dart:170`
- `lib/features/overview/overview_service.dart:41,59`
- `lib/features/overview/models/system_overview.dart:238`
- `lib/features/systems/providers/system_snapshot_fetcher.dart:20`
- `lib/features/sensors/models/sensor_models.dart:262,265`

## Closed Criteria

- Resolution: harden unsafe first/as collection access with regression tests
- Closed: 2026-11-16


- Resolution: Defensive `firstOrNull`/null-safe parsing and casts applied at listed sites; regression tests added for empty/missing/malformed collections.
- Closed reason: All acceptance criteria met; `flutter analyze` 0 issues, `flutter test` 532 passed / 1 skipped, `python3 issues/issues.py validate` OK.
- Follow-ups: none
