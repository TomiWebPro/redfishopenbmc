---
id: "013"
title: "Remove dead app_breakpoints.dart and reconcile breakpoint taxonomy"
status: open
priority: P3
type: chore
created: 2026-08-30
updated: 2026-08-30
closed: null
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

- [ ] `lib/core/theme/app_breakpoints.dart` deleted.
- [ ] No remaining references to `AppBreakpoints`/`AdaptiveBuilder`.
- [ ] `breakpoints.dart` retained as the only breakpoint source (desktop ≥1024, tablet 600–1024).

## Tasks

- [ ] Delete file; grep for usages; update any accidental import.

## Redfish Mapping

- none (UI/theme)

## Progress Log

- 2026-08-30 — Created from triage analysis (arch finding #2).

## References

- `lib/core/theme/app_breakpoints.dart`
- `lib/core/theme/breakpoints.dart`
- `lib/features/overview/views/overview_view.dart` (uses `OverviewGridBreakpoints`)

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
