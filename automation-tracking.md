# Automation Tracking

Append-only run log for the `redfish-automation` scheduler job.

- **Repo:** `/home/tomi/redfishopenbmc`
- **Schedule:** every 5 hours (`0 */5 * * *`) via `~/opencode-scheduler/scheduler.py`
- **Model:** `opencode/deepseek-v4.1-flash-free` (agent: `build`, `--auto`)
- **Timeout:** 7200s per run
- **Runbook:** `.opencode/skills/redfish-automation/SKILL.md`
- **Queue:** `FUTUREWORK.md`
- **Detailed specs:** `issues/open/` (local tracker only — never GitHub Issues)
- **Progress contract:** `DEVELOPMENT.md` + `progress/journal.md`

## Run log conventions

- New entries are appended at the **end** (oldest first), one section per run.
- Use `## YYYY-MM-DD HH:MM — MODE` as the heading, where MODE is one of
  `DOCS`, `EMULATOR`, `REPAIR`, `FEATURE`, `UI`, `REFACTOR`, or `SETUP`.
- Record baseline, work done, files touched, verification, commit hash, push
  status, and the next three actions. If something was reverted, say why.
- Do not rewrite old entries. Corrections go in the newest entry.

---

## 2026-10-21 14:50 — SETUP (assistant)

- **Baseline:** `flutter analyze` 0 issues; `flutter test` 231 passed / 1 skipped;
  `python3 issues/issues.py validate` OK; branch `main` clean at `1b56e14`.
- **Created:** `.opencode/skills/redfish-automation/SKILL.md` (runbook),
  `FUTUREWORK.md` (queue), `documentations/external/README.md` (docs mirror policy),
  and this tracking file.
- **Scheduled:** `redfish-automation` job, model `opencode/deepseek-v4.1-flash-free`,
  agent `build`, `--auto`, timeout 7200s, cron `0 */5 * * *`.
- **Guardrails:** analyze/test must stay green; docs and emulator work alternate;
  every green run should land one small UI/test improvement; push only after checks.
- **Next:** run 1 starts with the official docs scout, then alternates with the
  DMTF mockup-server emulator harness.

<!-- APPEND NEW RUNS BELOW THIS LINE, OLDEST FIRST -->

## 2026-10-21 15:00 — SETUP (assistant)

- **Baseline:** analyze 0; tests 231 passed / 1 skipped; starting commit 1cc0f01.
- **Primary work:** fixed the broken agent chain found during setup review.
- **Chain audit:** the scheduler implements "agent" only by prepending "FIRST read
  and follow `/home/tomi/redfishopenbmc/.opencode/agents/build.md`" to the prompt —
  that file did not exist, so the run's first instruction pointed at nothing.
  `.opencode/agents/development-agent.md` was also stale (wrong path
  `/home/tomi/projects/redfishopenbmc`, phantom jobs, "DO NOT push" contradicting
  the runbook).
- **Changes:** created `.opencode/agents/build.md` (agent protocol; runbook is
  authoritative); fixed `development-agent.md` paths, model, push policy, job
  table, and auth notes (credential store, no embedded PAT).
- **Verification:** analyze 0; tests 231 passed / 1 skipped; issues validate OK.
- **Commit:** pending — pushed as part of the setup series.
- **Next:** first real automation run at next 5h tick; quota on deepseek-free
  should have cleared.

## 2026-10-22 12:44 — DOCS

- **Baseline:** analyze 0; tests 231 passed / 1 skipped; starting commit 9fd38dc;
  issues validate OK; branch `main` clean.
- **Primary work:** DOCS-1 — established the official-docs mirror under
  `documentations/external/redfish/` (fresh queue, first DOCS run).
- **Docs:** pulled and verified (curl `-sSIL` 200 on every source):
  - DSP0266 1.25.0 PDF from `www.dmtf.org` (1,243,359 bytes,
    `385ee6d0...82149`) → `redfish/spec/`.
  - bmcweb `Redfish.md` (25,689 B), `REDFISH_CHECKLIST.md` (1,761 B),
    `OEM_SCHEMAS.md` (5,687 B) at upstream commit `0128851e` → `redfish/openbmc/`.
  - Redfish-Mockup-Server README (7,318 B) at commit `23d21f9a` → `redfish/mockup/`.
  - Full DMTF schema index listing (3,448,133 B, 14,259 JSON/YAML entries)
    → `redfish/schemas/v1-index.html`.
  - 16 base aggregator schemas (ServiceRoot, ComputerSystem, Chassis, Sensor,
    Power, Thermal, SessionService, AccountService, UpdateService,
    SoftwareInventory, EventService, Manager, LogService, EthernetInterface,
    TaskService, MessageRegistry; 106,322 B total) → `redfish/schemas/v1/`.
  - Total new downloads ≈ 4.8 MB (well under the 50 MB run budget; no file over
    25 MB). Manifest table + SHA-256s updated in `documentations/external/README.md`;
    upstream anchors re-verified with commits.
  - Created `documentations/external/redfish/REQUIREMENTS.md` — 14-row
    requirement→code→test→status trace. 9 requirements OK (tested), 4 GAP rows
    already tracked (#016 PATCH/ETag, #008/#020 tasks, event subscription not yet
    filed, session URI #015), vendor rows cited to bmcweb.
- **Emulator:** none this run (DOCS run).
- **Code/tests:** no production code changes from docs; trace table links to
  existing code + tests.
- **UI:** UI-2 accessibility increment — `HealthBadge` / `PowerBadge` now wrap
  the chip in `Semantics(label: 'Health <x>' / 'Power <x>')` so screen readers
  announce state, and `HealthBadge` uses a distinct icon per state
  (`warning_amber_rounded` for warning, `help_outline` for unknown) instead of
  a generic error icon. Added 2 widget tests
  (`test/features/systems/ui_widget_test.dart`): semantics labels + per-state
  icons. Also touched `documentations/redfish_reference/README.md` provenance
  note pointing to the new live corpus (DOCS-2 partial).
- **Verification:** analyze 0; tests 233 passed / 1 skipped; issues validate OK;
  `git diff --check` clean; secret scan clean.
- **Commit:** c8dc7e1 — `auto: DOCS — official docs mirror (DSP0266, bmcweb, schemas, REQUIREMENTS) + badge a11y (run 2026-10-22 12:44)`; pushed: **no** — `git push origin main` failed with `fatal: could not read Username for 'https://github.com': No such device or address`; no credential helper, no GITHUB_TOKEN/GH_TOKEN/GIT_TOKEN env, no SSH key on this machine. Local commit kept; not retried (runbook failure handling). Verify `git ls-remote origin refs/heads/main` vs `c8dc7e1` next run.
- **Next:** 1) EMULATOR run — stand up Redfish-Mockup-Server over HTTPS and add
  `test_integration/emulator/` tests (EMU-1/EMU-2); 2) DOCS-2 refresh the
  `test/fixtures/redfish/` + `redfish_reference` snapshot against the verified
  upstream commits; 3) DOCS-3 continue DSP0266 audit — file the event
  subscription gap (EventService/Subscriptions) as a new FUTUREWORK item.

