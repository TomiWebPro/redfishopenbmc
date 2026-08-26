---
id: "004"
title: "Multi-system manager — profiles, dashboard & context switching"
status: open
priority: P1
type: feature
created: 2026-08-26
updated: 2026-08-26
closed: null
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

- [ ] `lib/features/systems/models/connection_profile.dart` — `id (uuid), name, host, port, useTls(bool), authMethod (basic|session), username, rememberPassword(bool), allowSelfSigned(bool), createdAt` — never stores plaintext password; `flutter_secure_storage` holds `{profileId: {token}}` and optionally encrypted password if `rememberPassword`
- [ ] `lib/features/systems/providers/system_manager.dart` — Riverpod `StateNotifier<SystemState>` or `AsyncNotifier`:
  - `systems: Map<String, SystemHandle>` where `SystemHandle {profile, client, session, features, snapshot, lastSeen}`
  - `addProfile()`, `removeProfile()`, `updateProfile()`, `connect(id)`, `disconnect(id)`, `selectedId`
  - Persists profile list to `SecureStorage`/`shared_preferences` (non-sensitive) + tokens to `SecureStorage`
  - On app start, rehydrates profiles and lazily reconnects
- [ ] Routing: `go_router` with `/:systemId/overview|power|sensors|firmware|kvm` — `SystemShell` reads `selectedId` and scopes all downstream providers via `family`
- [ ] Dashboard `lib/features/systems/views/dashboard_view.dart` — grid/list of `SystemCard` (adaptive: mobile 1 col → tablet 2 → desktop 3), each card shows: name, `host:port`, power badge, health badge (`OK/Warning/Critical`), mfr/model if discovered, tap → `/:systemId/overview`
- [ ] Aggregated status: header banner "2 OK, 1 Warning" computed from `snapshot.health`
- [ ] Instant switch: changing `selectedId` does not re-discover; cached `SystemFeatures` reused until TTL
- [ ] Validation: host regex/IP, port 1-65535, TLS toggle, `allowSelfSigned` warning banner; form tests
- [ ] Tests: `test/features/systems/system_manager_test.dart` — add/remove, persistence round-trip with `InMemoryStorage`, isolation (token for bmc1 not used for bmc2), dashboard aggregation
- [ ] Widget tests: `dashboard_view_test.dart` renders 2 mocked systems with different health

## Tasks

- [ ] Model `ConnectionProfile` + `SystemSnapshot` + `Health` enum
- [ ] Implement `SystemManager` provider with persistence abstraction (`ProfileRepository`)
- [ ] Implement `AddSystemDialog` / `EditSystemPage` + form validation
- [ ] Implement `DashboardView` + `SystemCard` + aggregated header
- [ ] Wire `go_router` `/:systemId` family + `SystemShell` scaffold with tabs (Overview/Power/Sensors/Firmware/KVM — hide unavailable via `features`)
- [ ] Tests: 6+ unit + 2 widget
- [ ] Update `progress/journal.md`

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

## References

- `documentations/project_goal/goal.md:23-34`, `230-240`, `157-168`
- `lib/redfish/discovery/` (→ #003), `lib/core/storage/` (→ #001/#002)
- Related: #003, #005, #006

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
