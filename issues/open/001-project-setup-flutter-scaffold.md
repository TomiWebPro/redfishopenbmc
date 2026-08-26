---
id: "001"
title: "Project setup — Flutter scaffold, tooling, state & CI"
status: open
priority: P1
type: chore
created: 2026-08-26
updated: 2026-08-26
closed: null
assignee: unassigned
labels: [setup, flutter, tooling, ci]
estimated_tokens: 35000
---

# 001 — Project setup — Flutter scaffold, tooling, state & CI

> Bootstrap the Flutter app so every other issue has a place to land. Covers scaffold, structure, lint, state mgmt, routing, storage, and CI.

## Description

Project is currently spec-only (`README.md` + `documentations/project_goal/goal.md`), no `lib/` or `pubspec.yaml`. This issue creates the runnable Flutter skeleton that enforces the repo's design philosophy: *Everything is discovered, nothing is assumed.*

- Goal reference: `goal.md` § Architecture Overview, § UI/UX Design Principles, § Security Requirements
- User story: As a developer I can `flutter run` a blank but correctly structured app so that Redfish features can be added slice-by-slice.
- Scope IN: `flutter create`, folder layout, `analysis_options.yaml`, `very_good_analysis`/`lints`, `Riverpod`/`flutter_riverpod`, `go_router`, `flutter_secure_storage`, `dio`/`http`, theme (dark first), adaptive scaffolding, `flutter test` + `flutter analyze` CI, `.gitignore`
- Scope OUT: Any Redfish API calls (→ #002, #003), real UI screens beyond placeholders (→ #006)

## Goals / Acceptance Criteria

- [ ] `flutter create .` succeeds under Flutter 3.x; `flutter analyze` zero issues, `flutter test` green on placeholder widget test
- [ ] Folder layout committed:
  ```
  lib/
    main.dart
    core/
      theme/
      router/
      storage/
    features/
      discovery/
      systems/
      power/
      sensors/
      firmware/
      kvm/
    redfish/
      client/
      models/
  test/
  assets/
  ```
- [ ] Dependencies pinned: `flutter_riverpod` (or `bloc` — decide and document in `DEVELOPMENT.md`), `go_router`, `flutter_secure_storage`, `dio`, `json_annotation`/`freezed` if codegen chosen
- [ ] `analysis_options.yaml` with `include: package:lints/recommended.yaml` or stricter; `flutter pub get` reproducible via `pubspec.lock` committed
- [ ] Dark mode first-class: `ThemeData` light+dark, `ThemeMode.system`
- [ ] Adaptive layout stub: `LayoutBuilder` breakpoint `mobile<600 < tablet<1200 < desktop` (no real pages yet, just shell)
- [ ] CI: GitHub Actions `flutter-ci.yml` running `analyze` + `test` on `main` pushes
- [ ] `.gitignore` covers Flutter artifacts, `.dart_tool/`, `build/`, `.env`, `*.keystore`, but explicitly **tracks** `issues/` and `progress/`
- [ ] Docs: `DEVELOPMENT.md` records toolchain versions, state choice rationale, and daily-push rule

## Tasks

- [ ] Run `flutter create . --platforms android,ios,web,linux,macos,windows` or subset if CI limited — document choice
- [ ] Add `pubspec.yaml` deps + `analysis_options.yaml`
- [ ] Create `lib/` folder layout + `lib/main.dart` with `ProviderScope` + `GoRouter` shell + theme
- [ ] Add `flutter_secure_storage` wrapper under `lib/core/storage/secure_storage.dart` (no usage yet, just interface)
- [ ] Write placeholder widget test `test/widget_test.dart` + `test/core/theme_test.dart`
- [ ] Add `.gitignore` (Flutter template) and ensure `issues/` not ignored
- [ ] Add `.github/workflows/flutter-ci.yml` (or note if skipping CI for now)
- [ ] Update `progress/journal.md` + `progress_summary.md`, move issue to `closed/` only when CI green

## Redfish Mapping

None — infra only. No endpoints.

## Progress Log

- 2026-08-26 — Created. Depends on nothing; blocks #002–#010.

## References

- `documentations/project_goal/goal.md:179-201` (Architecture), `130-178` (UI/UX)
- Flutter docs: https://docs.flutter.dev/
- `issues/README.md` for close workflow
- Related: #002, #003, #004 (all depend on this)

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
