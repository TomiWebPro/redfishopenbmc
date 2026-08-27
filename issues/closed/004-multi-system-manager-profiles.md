---
id: "004"
title: "Multi-system manager — profiles, dashboard & context switching"
status: closed
priority: P1
type: feature
created: 2026-08-26
updated: 2026-08-27
closed: 2026-08-27
assignee: unassigned
labels: [systems, profiles, dashboard, state]
estimated_tokens: 50000
---
# 004 — Multi-system manager — profiles, dashboard & context switching

> Persist connection profiles (IP+port+creds+auth method), orchestrate per-system sessions/caches, and present a unified aggregated dashboard with instant context switching.

## Description

`goal.md` §1 demands multi-BMC: users add many targets, switch instantly, and see aggregated health. Each system is an independent node with its own `RedfishClient`, `Session`, `SystemFeatures`, and live snapshot. Profiles must survive restarts securely.

- Goal reference: `goal.md` §1 Multi-System Management, § Multi-System Support Model, § UI/UX → System-Centric Navigation
- User story: As an operator I add `bmc-lab-01:443` and `prod-03:8443`, see both cards on a dashboard (power+health at a glance), tap one to manage it, and the other stays connected in background.
- Scope IN: `ConnectionProfile` model, `SystemManager`/`SystemStore` (Riverpod), CRUD UI slice (add/edit/remove), secure persistence, dashboard aggregation, context `systemId` routing, live snapshot polling hook (no sensor graphs yet)
- Scope OUT: Discovery internals (→ #003), power execution (→ #005), sensor details (→ #007), firmware/KVM tabs (→ #008/#009)

## Goals / Acceptance Criteria

- [x] `lib/features/systems/models/connection_profile.dart` — `id (uuid), name, host, port, useTls(bool), authMethod (basic|session), username, rememberPassword(bool), allowSelfSigned(bool), createdAt` — never stores plaintext password; `flutter_secure_storage` holds `{profileId: {token}}` and optionally encrypted password if `rememberPassword`
- [x] `lib/features/systems/providers/system_manager.dart` — Riverpod `StateNotifier<SystemState>` or `AsyncNotifier`:
  - `systems: Map<String, SystemHandle>` where `SystemHandle {profile, client, session, features, snapshot, lastSeen}`
  - `addProfile()`, `removeProfile()`, `updateProfile()`, `connect(id)`, `disconnect(id)`, `selectedId`
  - Persists profile list to `SecureStorage`/`shared_preferences` (non-sensitive) + tokens to `SecureStorage`
  - On app start, rehydrates profiles and lazily reconnects
- [x] Routing: `go_router` with `/:systemId/overview|power|sensors|firmware|kvm` — `SystemShell` reads `selectedId` and scopes all downstream providers via `family`
- [x] Dashboard `lib/features/systems/views/dashboard_view.dart` — grid/list of `SystemCard` (adaptive: mobile 1 col → tablet 2 → desktop 3), each card shows: name, `host:port`, power badge, health badge (`OK/Warning/Critical`), mfr/model if discovered, tap → `/:systemId/overview`
- [x] Aggregated status: header banner "2 OK, 1 Warning" computed from `snapshot.health`
- [x] Instant switch: changing `selectedId` does not re-discover; cached `SystemFeatures` reused until TTL
- [x] Validation: host regex/IP, port 1-65535, TLS toggle, `allowSelfSigned` warning banner; form tests
- [x] Tests: `test/features/systems/system_manager_test.dart` — add/remove, persistence round-trip with `InMemoryStorage`, isolation (token for bmc1 not used for bmc2), dashboard aggregation
- [x] Widget tests: `dashboard_view_test.dart` renders 2 mocked systems with different health

## Tasks

- [x] Model `ConnectionProfile` + `SystemSnapshot` + `Health` enum
- [x] Implement `SystemManager` provider with persistence abstraction (`ProfileRepository`)
- [x] Implement `AddSystemDialog` / `EditSystemPage` + form validation
- [x] Implement `DashboardView` + `SystemCard` + aggregated header
- [x] Wire `go_router` `/:systemId` family + `SystemShell` scaffold with tabs (Overview/Power/Sensors/Firmware/KVM — hide unavailable via `features`)
- [x] Tests: 6+ unit + 2 widget
- [x] Update `progress/journal.md`

## Redfish Mapping

Profile itself is local. Live snapshot reuses:

| Data | Endpoint | Notes |
|------|----------|-------|
| Health/State | `GET /redfish/v1/Systems/{id}` → `Status.Health`, `PowerState` | polled every 30s or on pull-to-refresh |
| Mfr/Model | same | `Manufacturer`, `Model`, `SerialNumber` |
| Feature map | via `DiscoveryEngine` (→ #003) | determines visible tabs/cards |

No new Redfish writes in this issue.

## Progress Log

- 2026-08-26 — Created. Depends on #001 #002 #003; blocks #005–#010.
- 2026-08-27 — Implementation complete (carried over from prior agent session, finalized this run): `ConnectionProfile`/`SystemSnapshot`/`Health`/`PowerState` models; `SystemManager` (`StateNotifier<SystemState>`) with `Map<id,SystemHandle>`, add/remove/update/connect/disconnect/select, `ProfileRepository` persistence (password never in blob; keystore only), rehydrate, per-system token isolation via injected `AuthManager`, instant context switch (no re-discover); `go_router` `/:systemId/{overview,power,sensors,firmware,kvm}` + `SystemShell` capability-gated tabs; `DashboardView` adaptive grid + `AggregatedStatus` banner; `SystemCard`/`HealthBadge`/`PowerBadge`; `AddSystemDialog`/`EditSystemPage`/`SystemProfileForm` with `validateHost`/`validatePort`. Tests: 13 files under `test/features/systems/` (manager CRUD + persistence + isolation + aggregation; form validation; dashboard/shell/card/badge widgets; dialog+page submit). `flutter analyze` 0 issues; `flutter test` 145 passed / 1 skipped (live-BMC integration stub); `features/systems` coverage **88.1%** (target 80). Fixed 2 pre-existing widget-test harness bugs (off-viewport `Save` tap; `SN1` exact-match vs rendered `Serial: SN1`) and added 2 dialog/page submit tests.

## References

- `documentations/project_goal/goal.md:23-34`, `230-240`, `157-168`
- `lib/redfish/discovery/` (→ #003), `lib/core/storage/` (→ #001/#002)
- Related: #003, #005, #006

## Closed Criteria

- Resolution: multi-system manager implemented: profiles, secure persistence, per-system sessions, capability-gated routing, dashboard aggregation, instant context switch; flutter analyze 0, 145 tests green, 88.1% feature coverage
- Closed: 2026-08-27


- Resolution: Implemented per acceptance criteria + tasks; all checkboxes checked; 145 unit/widget tests green, 88.1% feature coverage, analyze 0.
- Closed reason: Multi-system manager fully implemented — profiles, secure persistence, per-system sessions, capability-gated routing, dashboard aggregation, instant context switching; tests green.
- Follow-ups: #005 power execution, #006 adaptive overview cards, #007 realtime sensors depend on this; #010 hardening will add token-isolation/secure-storage proof tests across the manager.
