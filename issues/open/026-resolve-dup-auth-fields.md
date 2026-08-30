---
id: "026"
title: "Resolve duplicate auth fields (preferSessionAuth vs authMethod)"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-08-30
closed: null
assignee: unassigned
labels: [architecture, auth, model]
estimated_tokens: 10000
---

# 026 — Resolve duplicate auth fields

> `connection_profile.dart` carries two fields encoding the same choice: `preferSessionAuth` (bool, `:76`) and `authMethod` (enum, `:79`). The model docs say they "should be kept in sync by the UI" (`:73-76`), but the UI writes `authMethod` (`system_profile_form.dart:107`) while `AuthManager` reads `preferSessionAuth` (`auth_manager.dart:75`). This is a desync bug waiting to happen and the root cause of #015's mode-selection defect.

## Description

- Two sources of truth for auth mode.
- UI and client read different fields → inconsistent behavior.

- Goal reference: `goal.md` §3.1 Auth
- User story: As a maintainer there is a single authoritative auth-mode field.
- Scope IN: pick `authMethod` as canonical, derive/remove `preferSessionAuth`, update form + client.
- Scope OUT: auth flow fixes (→ #015).

## Goals / Acceptance Criteria

- [ ] Single authoritative auth-mode field (`authMethod`).
- [ ] `preferSessionAuth` removed or derived; no dual writes.
- [ ] Form + client consistent.
- [ ] Tests for profile serialization.

## Tasks

- [ ] Remove/derive `preferSessionAuth`.
- [ ] Update `system_profile_form.dart` + `auth_manager.dart`.
- [ ] Tests in `test/features/systems/` + `test/redfish/client/`.

## Redfish Mapping

- none (model)

## Progress Log

- 2026-08-30 — Created from triage analysis (arch #3). Strongly related to #015/#011.

## References

- `lib/redfish/models/connection_profile.dart:73-79`
- `lib/features/systems/views/system_profile_form.dart:107`
- `lib/redfish/client/auth_manager.dart:75`
- Related: #015, #011

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: #015
