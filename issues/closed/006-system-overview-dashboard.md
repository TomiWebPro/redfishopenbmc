---
id: "006"
title: "System overview — health, inventory & adaptive card layout"
status: closed
priority: P2
type: feature
created: 2026-08-26
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [ui, dashboard, overview, inventory]
estimated_tokens: 40000
---
# 006 — System overview — health, inventory & adaptive card layout

> Per-system Overview tab: power badge, health, manufacturer/model/serial/CPU/memory, temperatures (when present), card-based adaptive layout, dark-mode polished.

## Description

`goal.md` §3.2 requires an at-a-glance system summary that is fully schema-driven: render only what the BMC exposes. CPU/memory may be missing (e.g. OpenBMC QEMU), temperatures only if `Chassis/Thermal` exists — no disabled placeholders.

- Goal reference: `goal.md` §3.2 System Overview Dashboard, §1. Modern Minimal Interface, §2 Responsive Cross-Platform, §3 System-Centric Navigation
- User story: As a user I open a system and immediately see health, power, who made it, CPU/mem, and a few temps — on phone, tablet, or desktop without layout breakage.
- Scope IN: `SystemOverview` model, `OverviewView` + `InfoCard` widgets, adaptive breakpoints, health computation, data hydration via existing discovery + `Systems`/`Chassis` GETs, polling, widget tests
- Scope OUT: Detailed sensor graphs (→ #007), power buttons (→ #005), firmware/KVM (→ #008/#009)

## Goals / Acceptance Criteria

- [x] `lib/features/overview/models/system_overview.dart` — `manufacturer, model, sku, serialNumber, partNumber, biosVersion, powerState, health (Health enum OK/Warning/Critical/Unknown), healthRollup, processorSummary (count, model), memorySummary (totalGiB), indicatorLed` — all nullable; `fromRedfish(Map)` tolerant
- [x] `lib/features/overview/overview_provider.dart` — Riverpod `FutureProvider.family<SystemOverview, systemId>` that:
  - `GET /redfish/v1/Systems/{id}` → core fields + `ProcessorSummary`, `MemorySummary`
  - If `SystemFeatures` indicates chassis, optionally `GET /redfish/v1/Chassis/{id}` or `Thermal` for leading temp (single value, not full graph)
  - Caches 30s, refresh on pull-to-refresh or after power action (→ #005)
- [x] `lib/features/overview/views/overview_view.dart` — rendered for every system (always allowed) with:
  - Top `HealthBanner` (green/amber/red) + `PowerBadge` (from #005 shared widget)
  - Grid `InfoCard`s: `Identity` (mfr/model/serial), `Processors` (count+model or "not exposed"), `Memory` (GiB or "not exposed"), `Temperatures` (only if thermal sensor exists — else card omitted), `Indicator LED`
  - Adaptive: `mobile → 1 col`, `tablet ≥600 → 2 cols`, `desktop ≥1024 → 3 cols` + `CustomScrollView`/`Wrap`
  - Dark mode contrast AA, card elevation, skeleton loader while `AsyncLoading`
- [x] Health logic: `Status.Health` primary, fallback `HealthRollup`, fallback `Unknown`; mapping `OK→green`, `Warning→amber`, `Critical→red` with icon
- [x] Handles missing fields: card omitted or shows "Not exposed by this BMC" helper text — never crashes on `null`/`missing Link`
- [x] Polling: auto-refresh every 30s when view visible (`ref.listen` + `Timer` or `StreamProvider`), manual pull-to-refresh
- [x] Tests: `test/features/overview/overview_provider_test.dart` (mocked GETs: full payload vs minimal QEMU vs missing Health), widget `overview_view_test.dart` (adaptive, dark mode, missing-field paths)
- [x] Coverage ≥75%

## Tasks

- [x] Model `SystemOverview` + `Health` + `ProcessorSummary`/`MemorySummary`
- [x] Provider `overviewProvider` + `chassisThermal` helper (service-based hydration)
- [x] Widgets: `OverviewView`, `InfoCard`, `HealthBanner`, `SkeletonCard`
- [x] Breakpoint util `lib/core/theme/breakpoints.dart` (`OverviewGridBreakpoints`)
- [x] Tests: 4 provider + 3 widget (1 golden/screenshot if feasible)
- [x] Document rendering rules in `lib/features/overview/README.md`

## Redfish Mapping

| Data | Endpoint | Fields |
|------|----------|--------|
| Identity/Health/Power | `GET /redfish/v1/Systems/{id}` | `Manufacturer`, `Model`, `SKU`, `SerialNumber`, `PartNumber`, `BiosVersion`, `Status {Health,HealthRollup}`, `PowerState`, `IndicatorLED`, `ProcessorSummary`, `MemorySummary` |
| Processors detail | `GET /Systems/{id}/Processors` | if link exists (optional P3) |
| Memory detail | `GET /Systems/{id}/Memory` | if link exists (optional P3) |
| Temperatures (preview) | `GET /redfish/v1/Chassis/{id}/Thermal` | `Temperatures[0].ReadingCelsius` for preview card — full graph is #007 |

- Discovery gate: none — Overview is always shown; individual cards gated on field presence
- OEM: `Oem.*` ignored in v1

## Progress Log

- 2026-08-26 — Created. Depends on #001 #003 #004.
- 2026-08-30 — STALE (triage): no Progress Log update for 4 days (>1-day threshold). Note: WIP commit f083802 (2026-08-27, analyze 0 / 203 tests green) landed without a log entry.
- 2026-11-16 — agent:redfish-automation triage: verified acceptance satisfied by existing implementation (schema-driven `SystemOverview`/`OverviewService`/`overviewProvider`, capability-tolerant `OverviewView` with `HealthBanner`+`PowerBadge`+adaptive 1/2/3-column cards, `Health`/`HealthRollup` fallback, omitted/missing-field handling, skeleton/loading/error states, pull-to-refresh + 30s auto-refresh + power-state refresh, 320/800/1300 and semantics widget coverage). Added `lib/features/overview/README.md` documenting rendering rules and closed issue.

## References

- `documentations/project_goal/goal.md:74-85`, `130-155`
- Redfish ComputerSystem & Chassis schemas
- `lib/redfish/models/system_features.dart` (→ #003)
- Related: #003, #004, #005, #007

## Closed Criteria

- Resolution: Overview implemented and verified (model/provider/service/view, adaptive layout, health/missing-field handling, refresh, 320/800/1300+semantics tests); rendering rules documented in lib/features/overview/README.md
- Closed reason: Acceptance criteria verified; rendering-rules doc added.
- Follow-ups: Detailed per-sensor graphs and richer thermal views remain in #007; overview temperature is a best-effort preview only.
