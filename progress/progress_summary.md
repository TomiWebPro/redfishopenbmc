# Progress Summary — redfishopenbmc

> Weekly rollup — update whenever a P1/P2 closes and at least weekly. Companion to `progress/journal.md` (daily) and `issues/` (per-task).

**Project:** Redfish Multi-System Control App (Flutter) — unified Redfish/OpenBMC control plane. Spec: `documentations/project_goal/goal.md`.

## Snapshot — 2026-08-26 (bootstrap)

**Phase:** Planning → Scaffold. Spec complete (`README.md` + `goal.md` + `LICENSE`), no Flutter code yet. Localized issue system just bootstrapped.

**Shipped:**
- 2026-08-26 — Localized tracker (`issues/open|closed`, `README.md`, `TEMPLATE.md`, `issues.py`) + skill (`.opencode/skills/redfish-issues/`) + `DEVELOPMENT.md` + 10 starter issues + `progress/journal.md`. Validated `issues.py list/stats/validate`.

**In Progress (open):**
- #001 P1 chore — Project setup / Flutter scaffold — **ready to start** (blocks all)
- #002 P1 — Redfish client core (blocked by #001)
- #003 P1 — Discovery engine (blocked by #001 #002)
- #004 P1 — Multi-system manager (blocked by #001–#003)
- #005 P1 — Power management (blocked by #001–#004)
- #006 P2 — System overview adaptive cards
- #007 P2 — Sensor monitoring realtime
- #008 P2 — Firmware & update management
- #009 P3 — Remote KVM
- #010 P2 — Hardening (secure storage, theming, a11y, coverage)

**Closed this week:** — (none yet; bootstrap counts as infra)

**Metrics:**
- Coverage: n/a (no code)
- `flutter analyze`: n/a
- Issues: 10 open / 0 closed — `python3 issues/issues.py stats`

**Risks & Decisions:**
- Choice of Riverpod vs Bloc deferred to #001 (document rationale in DEVELOPMENT.md)
- OpenBMC `Thermal` vs modern `Sensors` collection — handled via fallback in #007, fixtures to capture both
- `UpdateService` multipart vs `SimpleUpdate` — both supported in #008, stream for low-bandwidth
- `GraphicalConsole` KVM detection vs OEM — pluggable `KvmOemRegistry` in #009

**Next Milestone — Scaffold → First Redfish call:**
1. #001 — `flutter create`, deps, `analysis_options.yaml`, theme shell, `.gitignore`, CI
2. #002 — `Dio` client + `SessionService` auth + token isolation
3. #003 — Discovery engine + `SystemFeatures` fixture tests
- Target: dashboard slice (#004) after #003

**How to read this repo:**
- `issues/README.md` — workflow (open→closed, frontmatter, daily push)
- `issues/issues.py list` — current work queue
- `progress/journal.md` — daily log (most recent first)
- `DEVELOPMENT.md` — what is pushed daily and Definition of Done

---
*Next update: after #001 closes (or 2026-09-02 weekly).*
