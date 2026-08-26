---
id: "000"
title: "Short imperative title — e.g. 'Add power reset action'"
status: open
priority: P2
type: feature
created: 2026-08-26
updated: 2026-08-26
closed: null
assignee: unassigned
labels: []
estimated_tokens: 20000
---

# 000 — Short imperative title

> One-line summary: what this issue delivers and why it matters (link to goal.md §).

## Description

Context and problem statement. Which `documentations/project_goal/goal.md` core goal does this cover?

- Goal reference: e.g. §3.1 Power Management / §2 Dynamic Feature Discovery
- User story: As a <role> I can <capability> so that <value>
- Scope: what is in / out

## Goals / Acceptance Criteria

- [ ] Criterion 1 — measurable, testable
- [ ] Criterion 2 — e.g. "Traverse /redfish/v1/ → /Systems → capability map rendered"
- [ ] Tests pass (`flutter test` / `pytest` green)
- [ ] Docs updated (`progress/journal.md`, `progress_summary.md` if P1/P2)

## Tasks

- [ ] Task 1 — small, <1 day
- [ ] Task 2
- [ ] Task 3 — include test file path

## Redfish Mapping

| Feature | Endpoint | Method | Schema / Notes |
|---------|----------|--------|----------------|
| Example | `/redfish/v1/Systems/{id}` | `GET` | `ComputerSystem.v1_20_0` |
| Reset   | `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset` | `POST` | `ResetType: On/ForceOff/GracefulRestart` |

- OData traversal: `...`
- OEM extensions: `...` or `none`
- Polling / caching strategy: `...`

## Progress Log

<!-- Append timestamped notes as you work. Most recent first. -->

- 2026-08-26 — Created issue from template. (assignee)
- YYYY-MM-DD — ...

## References

- `documentations/project_goal/goal.md:line`
- DMTF Redfish spec: https://www.dmtf.org/standards/redfish
- OpenBMC Redfish: https://github.com/openbmc/bmcweb
- Related issues: #NNN

## Closed Criteria

<!-- Filled on close -->

- Resolution: 
- Closed reason: 
- Follow-ups: #NNN or none
