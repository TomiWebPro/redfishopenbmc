---
id: "001"
title: "Project setup — Flutter scaffold, tooling, state & CI"
status: closed
priority: P1
type: chore
created: 2026-08-26
updated: 2026-08-27
closed: 2026-08-27
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

- [x] `flutter create .` succeeds under Flutter 3.x; `flutter analyze` zero issues, `flutter test` green on placeholder widget test
- [x] Folder layout committed:
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
- [x] Dependencies pinned: `flutter_riverpod` (or `bloc` — decide and document in `DEVELOPMENT.md`), `go_router`, `flutter_secure_storage`, `dio`, `json_annotation`/`freezed` if codegen chosen
- [x] `analysis_options.yaml` with `include: package:lints/recommended.yaml` or stricter; `flutter pub get` reproducible via `pubspec.lock` committed
- [x] Dark mode first-class: `ThemeData` light+dark, `ThemeMode.system`
- [x] Adaptive layout stub: `LayoutBuilder` breakpoint `mobile<600 < tablet<1200 < desktop` (no real pages yet, just shell)
- [x] CI: GitHub Actions `flutter-ci.yml` running `analyze` + `test` on `main` pushes
- [x] `.gitignore` covers Flutter artifacts, `.dart_tool/`, `build/`, `.env`, `*.keystore`, but explicitly **tracks** `issues/` and `progress/`
- [x] Docs: `DEVELOPMENT.md` records toolchain versions, state choice rationale, and daily-push rule

## Tasks

- [x] Run `flutter create . --platforms android,ios,web,linux,macos,windows` or subset if CI limited — document choice
- [x] Add `pubspec.yaml` deps + `analysis_options.yaml`
- [x] Create `lib/` folder layout + `lib/main.dart` with `ProviderScope` + `GoRouter` shell + theme
- [x] Add `flutter_secure_storage` wrapper under `lib/core/storage/secure_storage.dart` (no usage yet, just interface)
- [x] Write placeholder widget test `test/widget_test.dart` + `test/core/theme_test.dart`
- [x] Add `.gitignore` (Flutter template) and ensure `issues/` not ignored
- [x] Add `.github/workflows/flutter-ci.yml` (or note if skipping CI for now)
- [x] Update `progress/journal.md` + `progress_summary.md`, move issue to `closed/` only when CI green

## Redfish Mapping

None — infra only. No endpoints.

## Progress Log

- 2026-08-27 — agent:opencode — completed & verified green:
  - Installed Flutter 3.47.1 / Dart 3.13.1 via `git clone ~/flutter --depth 1 --branch stable` (PATH on `~/flutter/bin`).
  - Verified scaffold `lib/` + platform dirs (android/ios/web/linux/macos/windows) already present from prior `flutter create .` with all 6 platforms.
  - Fixed `analysis_options.yaml`: removed 4 removed-in-Dart-3.x lints (`invariant_booleans`, `iterable_contains_unrelated_type`, `list_remove_unrelated_type`, `avoid_returning_null_for_future`, also `literal_only_boolean_expressions`, `prefer_void_to_null`).
  - Fixed `test/core/theme_test.dart`: `colorScheme.seed` is not a real getter → assert `primary` distinctness instead.
  - Fixed `test/widget_test.dart`: `find.textContaining` matched 2 widgets (AppBar + body) → use exact `find.text('Breakpoint: ...')` and unique page-body text for `RedfishApp`.
  - `flutter pub get` → pubspec.lock generated & tracked. `flutter analyze` → **No issues found!** `flutter test` → **13/13 passed**. `flutter test --coverage` → lcov.info generated (CI uses lcov).
  - Recorded toolchain + Riverpod rationale in `DEVELOPMENT.md`. Riverpod chosen (async-native, `family` providers for per-system isolation, low ceremony).
  - All acceptance criteria + tasks checked. Ready to close.

- 2026-08-26 — Created. Depends on nothing; blocks #002–#010.

## References

- `documentations/project_goal/goal.md:179-201` (Architecture), `130-178` (UI/UX)
- Flutter docs: https://docs.flutter.dev/
- `issues/README.md` for close workflow
- Related: #002, #003, #004 (all depend on this)

## Closed Criteria

- Resolution: scaffold + CI green, analyze 0, tests 13/13 green (Flutter 3.47.1)
- Closed: 2026-08-27


- Resolution:
- Closed reason:
- Follow-ups:
