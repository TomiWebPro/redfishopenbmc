---
id: "012"
title: "Consolidate app-wide DI providers into a core/di module"
status: closed
priority: P3
type: chore
created: 2026-08-30
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [architecture, riverpod, di]
estimated_tokens: 10000
---
# 012 — Consolidate app-wide DI providers into a core/di module

> App-wide infrastructure providers are defined inside a feature file. Move them to a dedicated `core/di` module for clear layering.

## Description

`secureStorageProvider`, `profileRepositoryProvider`, `authManagerProvider`, and `systemManagerProvider` are declared in `lib/features/systems/providers/system_manager.dart:436-486` — a feature module — rather than in `core/`. This scatters app-wide DI and couples the systems feature to startup wiring.

- Goal reference: `goal.md` §2 Modular Architecture
- User story: As a maintainer I can find all app-wide provider wiring in one `core/di` place.
- Scope IN: create `lib/core/di/providers.dart`, move the four providers, repoint imports.
- Scope OUT: provider behavior changes.

## Goals / Acceptance Criteria

- [x] New `lib/core/di/providers.dart` holds `secureStorageProvider`, `profileRepositoryProvider`, `authManagerProvider`, `systemManagerProvider`.
- [x] `system_manager.dart` no longer declares app-wide providers (keeps only system-scoped ones).
- [x] `flutter analyze` clean; tests green.

## Tasks

- [x] Create `lib/core/di/providers.dart`.
- [x] Move provider defs and update imports across consumers (system_manager re-exports for compatibility; core/di is the canonical declaration).
- [x] Run `flutter test`.

## Redfish Mapping

- none (architecture)

## Progress Log

- 2026-08-30 — Created from triage analysis (arch finding #4).
- 2026-11-16 10:53 UTC — agent:redfish-automation — moved four app-wide providers to `lib/core/di/providers.dart`, removed declarations from `system_manager.dart` (keeps system-scoped `systemHandleProvider`/`selectedSystemProvider`), added re-export/import wiring; no behavior changes.

## References

- `lib/features/systems/providers/system_manager.dart:436-486`
- Related: #011

## Closed Criteria

- Resolution: Moved `secureStorageProvider`, `profileRepositoryProvider`, `authManagerProvider`, and `systemManagerProvider` into `lib/core/di/providers.dart`; `system_manager.dart` now imports/exports them and keeps only system-scoped providers.
- Closed reason: `auto: FEATURE #012 consolidate DI providers (run 2026-11-16 10:53 UTC)`
- Follow-ups: none
