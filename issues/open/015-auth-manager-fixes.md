---
id: "015"
title: "AuthManager: honor authMethod, safe logout URI, session reuse & expiry"
status: open
priority: P1
type: bug
created: 2026-08-30
updated: 2026-08-30
closed: null
assignee: unassigned
labels: [redfish-core, auth, security, spec]
estimated_tokens: 16000
---

# 015 — AuthManager correctness & safety fixes

> Several auth defects: auth mode is chosen from `preferSessionAuth` instead of the authoritative `authMethod`; logout/`_relogin` falls back to `DELETE` the Sessions *collection* (risking deletion of all sessions); sessions accumulate because the stored token is never rehydrated on restart; `Session.expiresAt`/`isExpired` is dead code so proactive re-auth never happens.

## Description

`lib/redfish/client/auth_manager.dart` issues:
- `:75-79` dispatches on `preferSessionAuth` only; ignores `authMethod` (the model's own docs say `authMethod` is authoritative). A profile set to `basic` can use the wrong scheme.
- `:195` and `:142` fall back to `DELETE /redfish/v1/SessionService/Sessions` (the collection) when the login response lacks `Location`/`Content-Location`. Should fall back to the session's `@odata.id` from the response body.
- `:73-105` login always creates a new session and orphans the prior one; the token persisted to `SecureStorage` (`:201`) is never rehydrated on app restart → BMCs accumulate dead sessions.
- `session.dart:35-41` `expiresAt`/`isExpired` never become true (SessionTimeout never read) → only reactive 401 re-auth.

- Goal reference: `goal.md` §3.1 Auth & Sessions
- User story: As a user my chosen auth method is used, logout only kills my session, and restarts reuse my session.
- Scope IN: branch on `authMethod`; safe logout URI; token rehydrate; read SessionTimeout for proactive expiry.
- Scope OUT: credential storage (→ #024), field desync (→ #026).

## Goals / Acceptance Criteria

- [ ] Auth mode selected by `profile.authMethod`.
- [ ] Logout/`_relogin` DELETEs the session's `@odata.id` (not the collection), with safe fallback.
- [ ] On startup, rehydrate a stored session token if still valid.
- [ ] `Session.expiresAt` derived from `SessionService.SessionTimeout`; `isExpired` drives proactive re-auth.
- [ ] Unit tests for basic vs session selection and logout-target resolution.

## Tasks

- [ ] Refactor `auth_manager.dart` mode dispatch.
- [ ] Fix logout URI resolution.
- [ ] Add token persistence/rehydrate + expiry.
- [ ] Add tests in `test/redfish/client/auth_manager_test.dart`.

## Redfish Mapping

| Feature | Endpoint | Method |
|---------|----------|--------|
| Create session | `/redfish/v1/SessionService/Sessions` | `POST` → `X-Auth-Token`, `Location` |
| Delete session | `{session @odata.id}` | `DELETE` |
| Session timeout | `/redfish/v1/SessionService` `SessionTimeout` | `GET` |

- OEM: none
- DMTF Redfish Spec DSP0266 / DSP0218 (SessionService)

## Progress Log

- 2026-08-30 — Created from triage analysis (core correctness #6,#7,#8).

## References

- `lib/redfish/client/auth_manager.dart:73-105,142,174-195,251-258`
- `lib/redfish/models/session.dart:35-41`
- `lib/redfish/models/connection_profile.dart:31-39`
- Related: #014, #017, #026

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: #026
