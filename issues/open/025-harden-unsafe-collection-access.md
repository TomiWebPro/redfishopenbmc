---
id: "025"
title: "Harden unsafe .first / as casts against empty or null collections"
status: open
priority: P3
type: bug
created: 2026-08-30
updated: 2026-08-30
closed: null
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

- [ ] All listed `.first` usages guarded against empty.
- [ ] `as List<dynamic>` replaced with safe handling.
- [ ] Tests with empty/missing collections don't throw.

## Tasks

- [ ] Audit & fix each listed site.
- [ ] Add regression tests with empty payloads.

## Redfish Mapping

- none (defensive parsing)

## Progress Log

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

- Resolution:
- Closed reason:
- Follow-ups: none
