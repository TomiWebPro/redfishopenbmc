---
id: "017"
title: "Discover SessionService URI instead of hardcoding it"
status: closed
priority: P2
type: bug
created: 2026-08-30
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [redfish-core, discovery, spec, hardcode]
estimated_tokens: 10000
---
# 017 — Discover SessionService URI instead of hardcoding

> `auth_manager.dart:174` hardcodes `/redfish/v1/SessionService/Sessions` (with fallbacks at `:195` and retry guard `:258`). The SessionService URI should be discovered from the ServiceRoot `@odata.id` links. Hardcoding breaks BMCs that expose SessionService under a different path and violates the project's "Everything is discovered, nothing is assumed" goal.

## Description

The discovery engine already traverses ServiceRoot links (`discovery_engine.dart:182-193`). Auth should obtain the Sessions collection URI from `ServiceRoot.SessionService` → `Sessions` `@odata.id` rather than a constant.

- Goal reference: `goal.md` §1 Everything is discovered, nothing is assumed
- User story: As a user I can authenticate against BMCs whose SessionService lives at a non-default path.
- Scope IN: resolve Sessions URI from discovered ServiceRoot; keep constant only as last-resort fallback.
- Scope OUT: full auth rewrite (→ #015).

## Goals / Acceptance Criteria

- [x] Auth resolves Sessions URI from discovered `SessionService` link.
- [x] Hardcoded constant used only as documented fallback.
- [x] Tests cover both discovered and fallback paths.

## Tasks

- [x] Thread the discovered SessionService URI into `AuthManager.login`.
- [x] Add test fixtures for alternate SessionService paths.

## Redfish Mapping

| Feature | Endpoint | Notes |
|---------|----------|-------|
| ServiceRoot | `/redfish/v1/` | `SessionService` link → `Sessions` `@odata.id` |
| Create session | `{discovered Sessions @odata.id}` | `POST` |

- DMTF Redfish Spec (ServiceRoot)

## Progress Log

- 2026-11-16 — Resolved Sessions collection and SessionService URIs from ServiceRoot discovery in `AuthManager` (best-effort, canonical defaults as fallback), reused discovered URIs for session create/TTL/401 retry guard, and added unit tests for discovered and fallback paths.
- 2026-08-30 — Created from triage analysis (core correctness #10 / arch #6).

## References

- `lib/redfish/client/auth_manager.dart:174,195,258`
- `lib/redfish/discovery/discovery_engine.dart:182-193`
- Related: #015

## Closed Criteria

- Resolution: AuthManager discovers SessionService/Sessions URI from ServiceRoot with canonical fallback; tests added (run 2026-11-16)
- Closed: 2026-11-16


- Resolution: `AuthManager` discovers `ServiceRoot.SessionService` → `Sessions.@odata.id` before session creation and uses discovered URIs for login/TTL with canonical fallbacks.
- Closed reason: `auto: FEATURE #017 discover SessionService URI (run 2026-11-16)` (analyze 0, tests green, issues validate OK).
- Follow-ups: none
