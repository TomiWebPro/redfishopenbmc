---
id: "013"
title: "Remove dead app_breakpoints.dart and reconcile breakpoint taxonomy"
status: closed
priority: P3
type: chore
created: 2026-08-30
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [architecture, ui, dead-code]
estimated_tokens: 8000
---
# 013 — Remove dead app_breakpoints.dart and reconcile breakpoint taxonomy

> `lib/core/theme/app_breakpoints.dart` is never imported and defines a conflicting breakpoint scale (desktop ≥1200 / tablet 600–1200) versus the used `lib/core/theme/breakpoints.dart` (desktop ≥1024 / tablet 600–1024).

## Description

`AppBreakpoints`, `AppBreakpoint`, and `AdaptiveBuilder` in `app_breakpoints.dart` are referenced only by the file itself — dead code. Worse, two divergent breakpoint taxonomies exist, risking future inconsistency if someone imports the wrong one.

- Goal reference: `goal.md` §2 Responsive Cross-Platform
- User story: As a maintainer I have a single source of truth for responsive breakpoints.
- Scope IN: delete `app_breakpoints.dart`; keep `breakpoints.dart` as canonical.
- Scope OUT: layout changes.

## Goals / Acceptance Criteria

- [x] `lib/core/theme/app_breakpoints.dart` deleted.
- [x] No remaining references to `AppBreakpoints`/`AdaptiveBuilder`.
- [x] `breakpoints.dart` retained as the only breakpoint source (desktop ≥1024, tablet 600–1024).

## Tasks

- [x] Delete file; grep for usages; update any accidental import.

## Redfish Mapping

- none (UI/theme)

## Progress Log

- 2026-08-30 — Created from triage analysis (arch finding #2).
- 2026-11-16 (run 2026-11-16, agent:redfish-automation) — Deleted dead `lib/core/theme/app_breakpoints.dart` and removed dead `AppBreakpoints`/`AdaptiveBuilder` tests from `test/core/theme_test.dart` (kept `AppTheme` coverage). Verified no remaining `AppBreakpoints`/`AdaptiveBuilder`/`app_breakpoints` references and `lib/core/theme/breakpoints.dart` remains canonical (desktop ≥1024, tablet 600–1024).

## References

- `lib/core/theme/breakpoints.dart` (canonical)
- `lib/features/overview/views/overview_view.dart` (uses `OverviewGridBreakpoints`)
- `test/core/theme_test.dart`

## Closed Criteria

- Resolution: Removed dead app_breakpoints.dart and dead AppBreakpoints/AdaptiveBuilder references; breakpoints.dart remains the canonical breakpoint source with green analyze/tests
- Closed: 2026-11-16


- Resolution: Removed dead `app_breakpoints.dart` and reconciled to a single breakpoint source (`breakpoints.dart`); updated tests to drop dead API coverage.
- Closed reason: All acceptance criteria satisfied with green analyze/tests.
- Follow-ups: none
