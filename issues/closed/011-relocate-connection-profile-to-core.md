---
id: "011"
title: "Move ConnectionProfile model into core layer (fix core→feature dependency)"
status: closed
priority: P2
type: chore
created: 2026-08-30
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [architecture, layering, redfish-core]
estimated_tokens: 12000
---
# 011 — Move ConnectionProfile model into core layer

> `lib/redfish/models/connection_profile.dart` is a re-export shim that pulls the model up from `lib/features/systems/models/connection_profile.dart`, making the low-level `redfish/` client layer depend on the UI/feature layer. Invert it.

## Description

The single canonical `ConnectionProfile` lives in the feature layer, but `RedfishClient` (`redfish_client.dart:4`) and `AuthManager` (`auth_manager.dart:7`) import a shim in `lib/redfish/models/connection_profile.dart:7` that re-exports it. This inverts the intended dependency direction (core should not know about features).

- Goal reference: `goal.md` §2 Modular Architecture / clean layering
- User story: As a maintainer I can import `redfish/` without pulling in `features/` so the client core stays reusable.
- Scope IN: relocate the model to `lib/redfish/models/` (or `lib/core/`), repoint all imports.
- Scope OUT: behavior changes, auth-field cleanup (→ #026).

## Goals / Acceptance Criteria

- [x] `ConnectionProfile` defined in `lib/redfish/models/connection_profile.dart` (canonical).
- [x] `lib/features/systems/models/connection_profile.dart` becomes a re-export of the core model (or references it) — no duplicate class.
- [x] `RedfishClient`, `AuthManager`, `ProfileRepository`, forms import the single canonical model.
- [x] `flutter analyze` clean; existing tests green.

## Tasks

- [x] Move class definition to `lib/redfish/models/connection_profile.dart`.
- [x] Update imports in `redfish_client.dart`, `auth_manager.dart`, `profile_repository.dart`, `system_profile_form.dart`, and other consumers to the canonical model (no `system_snapshot_fetcher.dart` import change required).
- [x] Run `issues.py validate` and `flutter test`.

## Redfish Mapping

- none (pure architecture)

## Progress Log

- 2026-08-30 — Created from triage analysis (arch finding #1).
- 2026-11-16 — Moved `ConnectionProfile`/`AuthMethod` to `lib/redfish/models/connection_profile.dart`, converted `lib/features/systems/models/connection_profile.dart` to a compatibility re-export, and repointed lib/test/test_integration imports to the canonical core path.

## References

- `lib/redfish/models/connection_profile.dart`
- `lib/features/systems/models/connection_profile.dart`
- Related: #026, #012

## Closed Criteria

- Resolution: Relocated `ConnectionProfile` to the core Redfish model layer with a feature-layer compatibility re-export; updated consumers to the canonical import; analyze/tests/issues validation green.
- Closed reason: Acceptance criteria satisfied with no behavior change.
- Closed: 2026-11-16
- Follow-ups: #026, #012
