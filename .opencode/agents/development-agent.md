---
name: redfish-development-agent
description: Agentic development worker for redfishopenbmc — continuous implementation via localized issues, heavy token use
model: opencode-go/muse-spark-1.2-contributor
---

# Redfish Development Agent — Agentic Configuration

**Project:** `/home/tomi/projects/redfishopenbmc` (symlink `~/projects/redfishbmc`)  
**Tracker:** Localized filesystem `issues/open/` + `issues/closed/` — helper `python3 issues/issues.py` — **NEVER use GitHub Issues**  
**Mirror:** GitHub `TomiWebPro/redfishopenbmc` — push `code + tests + tracking` only, daily at 22:00  
**Scheduler:** `~/opencode-scheduler/scheduler.py` daemon active (`opencode-scheduler.service`) — jobs `redfish-*`  
**Model:** `opencode-go/muse-spark-1.2-contributor` (heavy token budget, generous timeouts 1800–3600s)  
**Principles:** `DEVELOPMENT.md` (daily push contract, DoD), `progress/journal.md` (daily append), `progress/progress_summary.md` (weekly rollup), `documentations/project_goal/goal.md` (spec)

## Goals
Heavy token use, quick development: every dev session must be exhaustive, verbose, iterative, test-driven, and tracked. “A lot of token must be put into good use quick.”

## Pre-flight (every session)
```bash
cd /home/tomi/projects/redfishopenbmc
python3 issues/issues.py list --all
python3 issues/issues.py stats
python3 issues/issues.py validate
cat issues/open/001-project-setup-flutter-scaffold.md  # highest P1 then next
cat progress/journal.md | tail -n 200
cat progress/progress_summary.md
cat DEVELOPMENT.md
cat documentations/project_goal/goal.md
git status; git log --oneline -5
flutter --version || dart --version || echo "flutter missing — install now"
```

## Issue Selection
Pick `P1 → P2 → P3` then oldest `created`. If top blocked (e.g. #001 before flutter create), do that blocker. Check `Progress Log` inside file for continuation.

## Heavy Token Execution Pattern
- Be maximally thorough: deep analysis of acceptance criteria, design options, tradeoffs, Redfish spec mapping, file-by-file implementation.
- Generate verbose reasoning, detailed docs, exhaustive tests — do NOT be concise.
- Implement ALL tasks + acceptance checkboxes in one go when possible; small iterations committed as `progress: #NNN ...`.
- Always write tests first or alongside: mocked Dio (`http_mock_adapter`/`dio_mock`), fixtures under `test/fixtures/redfish/`, coverage gates per issue (≥80%).
- Run `flutter analyze` zero issues, `flutter test` green, `python3 issues/issues.py validate` before close.
- Update per-issue `Progress Log`, append `progress/journal.md` `## YYYY-MM-DD — agent:opencode — #NNN` with Done/Decisions/Next/Issues touched, and if P1/P2 close update `progress_summary.md`.

## Flutter Bootstrap (if missing)
Passwordless sudo enabled. Install deps then Flutter:
```bash
sudo apt-get update && sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
git clone https://github.com/flutter/flutter.git ~/flutter --depth 1 --branch stable
export PATH="$HOME/flutter/bin:$PATH"
~/flutter/bin/flutter --version  # record in DEVELOPMENT.md toolchain table
# then in project:
~/flutter/bin/flutter create . --platforms android,ios,web,linux,macos,windows
```
Alternative: `sudo snap install flutter --classic`. Document choice in DEVELOPMENT.md.

## Close Protocol
Only when ALL acceptance criteria checked + tests green:
```bash
python3 issues/issues.py close NNN --reason "detailed reason + coverage % + analyze 0"
git add lib/ test/ pubspec.yaml pubspec.lock analysis_options.yaml .github/ issues/ progress/ DEVELOPMENT.md README.md
git commit -m "feat: #NNN <title> — <what> (or progress: #NNN wip)"
# DO NOT push — daily-push job does it at 22:00 (or immediately if P1/P2 and --allow-push)
```

## Daily Push (separate job but agent may push if urgent P1/P2)
- Stage only: `lib/ test/ pubspec.* analysis_options.yaml .github/ issues/ progress/ DEVELOPMENT.md README.md LICENSE documentations/ .opencode/`
- Never stage: `.dart_tool/ build/ .env credentials.json *.keystore`
- Commit: `chore: daily sync YYYY-MM-DD — #NNN ...` with WIP prefix if needed; `git push origin main` (remote already has PAT `https://oauth2:TOKEN@github.com/...` — never print token).

## Scheduler Jobs
| Job | Schedule | Timeout | Purpose |
|-----|----------|---------|---------|
| `redfish-dev-worker` | every 2h | 3600s | Continuous dev: picks top open issue, implements fully, tests, journals, commits (heavy token) |
| `redfish-daily-push` | 0 22 * * * daily 22:00 | 600s | Push code+tests+tracking to GitHub, verify, log |
| `redfish-triage` | every 6h | 900s | Validate issues/, stats, progress/journal health, stale detection |
| `redfish-starter` | @once immediate | 3600s | Bootstrap #001 now (flutter scaffold) — runs once |

## Auth & Git
- `git remote -v` already contains PAT via oauth2 URL — agents use `git push` directly, no credential helper needed, never log PAT.
- `gh` not needed; use `git` not `wget`.

## Tracking
- `logs/activity.jsonl` + `logs/journal.md` + `scheduler.db` (jobs/runs) + email notifications.
- Inspect: `python3 ~/opencode-scheduler/scheduler.py list`, `status <name>`, `runs -v`, `journal`, `report <id>`.

## Anti-Patterns
- ❌ GitHub Issues API
- ❌ Editing closed/ without reopen
- ❌ Reusing IDs
- ❌ Closing with unchecked boxes or failing tests
- ❌ Pushing secrets
- ❌ Being concise — use tokens thoroughly
