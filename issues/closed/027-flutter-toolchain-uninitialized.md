---
id: "027"
title: "Make the project analyzable/testable in this environment (Flutter SDK uninitialized)"
status: closed
priority: P1
type: chore
created: 2026-08-30
updated: 2026-10-22
closed: 2026-10-22
assignee: unassigned
labels: [tooling, ci, environment]
estimated_tokens: 10000
---
# 027 — Flutter SDK uninitialized blocks analyze/test

> In this environment `flutter` is provided by a snap whose first invocation triggers a ~1.5 GB SDK download (`flutter_linux_3.47.2-stable.tar.xz`) at ~900 KB/s, which never completes within session timeouts. Consequently `flutter analyze`, `dart analyze`, and `dart test` cannot run, and every attempt leaves orphaned `flutter_tester` processes. The triage in #011–#026 was therefore performed by code reading + grep heuristics, not analyzer-verified.

## Description

- `which flutter` → `/snap/bin/flutter`; running any `flutter`/`dart` command starts the SDK download.
- The download does not finish inside the 120–300 s tool timeout → no static analysis, no test runs, no coverage numbers.
- Orphaned `flutter_tester` processes from interrupted `flutter test` runs accumulate and must be killed manually.

- Goal reference: `goal.md` § Dev workflow / CI
- User story: As a developer/agent I can run `flutter analyze` and `flutter test` so findings are verified, not inferred.
- Scope IN: get a working Flutter toolchain (pre-cached SDK, `fvm`, or a non-snap install), wire `flutter analyze` + `flutter test` into a repeatable command, document it.
- Scope OUT: fixing the code issues themselves (those are #011–#026).

## Goals / Acceptance Criteria

- [x] `flutter analyze` runs to completion in this environment (or a documented alternative).
- [x] `flutter test` runs to completion; coverage reported.
- [x] No orphaned `flutter_tester` processes left after runs.
- [x] Document the working command in `DEVELOPMENT.md` / `README.md`.

## Tasks

- [x] Decide approach: pre-installed Flutter, `fvm`, or allow the snap download to finish once (background, long timeout).
- [x] Verify `flutter analyze` + `flutter test` green on a clean checkout.
- [x] Update `DEVELOPMENT.md` with the command.
- [x] Kill any orphaned `flutter_tester` processes.

## Redfish Mapping

- none (tooling)

## Progress Log

- 2026-10-22 — Closed with evidence. The environment now resolves `flutter` to
  `~/flutter/bin/flutter` (pre-cached stable git clone per #001; documented in
  DEVELOPMENT.md "Toolchain"), not the never-finishing snap download. Every
  automation run since DOCS-1 (2026-10-22) verifies: `flutter analyze` 0 issues,
  `flutter test` 242 passed / 1 skipped, `python3 issues/issues.py validate` OK.
  No orphaned `flutter_tester` processes from this repo after runs (the running
  ones observed belong to another project). Snap block no longer applies.
- 2026-08-30 — Created. Blocked triage verification of #011–#026.

## References

- `DEVELOPMENT.md`
- `analysis_options.yaml` (uses `package:lints/core.yaml` + strict-casts/inference/raw-types, `avoid_print`)
- Related: #011, #012, #013, #014, #015, #016, #017, #018, #019, #020, #021, #022, #023, #024, #025, #026

## Closed Criteria

- Resolution: Flutter toolchain resolved: environment uses ~/flutter/bin/flutter (git clone per #001, documented in DEVELOPMENT.md Toolchain). Baseline green every run since DOCS-1 (2026-10-22): flutter analyze 0 issues, flutter test 242 passed / 1 skipped, issues validate OK. No orphaned flutter_tester processes from redfishopenbmc. Snap-download blocker no longer applies.
- Closed: 2026-10-22
- Closed reason: Acceptance criteria met with evidence on 2026-10-22 (see Progress Log).
- Follow-ups: none
