# Localized Issues System — `issues/open` / `issues/closed`

> **No GitHub Issues.** This repo uses a filesystem-based issue tracker under `issues/`.
> GitHub is used only as a code mirror (push code + tests daily). Development history is tracked locally via `issues/` + `progress/`.

---

## Directory Structure

```
/issues/
  README.md          ← you are here — workflow for humans + agents
  TEMPLATE.md        ← issue template (copy for every new issue)
  issues.py          ← helper CLI — list / close / reopen / new / stats
  open/              ← active issues — one markdown file per issue
    001-title.md
    002-title.md
  closed/            ← completed issues — moved here, never deleted
    000-example-closed.md

/progress/
  progress_summary.md  ← weekly rollup (living doc)
  journal.md           ← daily log — what was done, decisions, next steps

/DEVELOPMENT.md        ← daily-push policy + dev conventions
```

All files in `issues/` are **git-tracked**. Do not add them to `.gitignore`.

---

## Naming Convention

```
NNN-kebab-case-title.md
```

- `NNN` — zero-padded sequence, `001`–`999`. Never reuse a number. Check `ls issues/open issues/closed` for max.
- `kebab-case-title` — short, descriptive, stable. Renaming requires `git mv`.
- Examples: `001-project-setup-flutter-scaffold.md`, `005-power-management.md`

IDs are the `NNN` prefix. Reference as `#001`, `#005`.

---

## Frontmatter Contract

Every issue **must** start with YAML frontmatter:

```yaml
---
id: "001"
title: "Project setup — Flutter scaffold"
status: open          # open | closed | blocked
priority: P1          # P1 critical > P2 high > P3 medium > P4 low
type: feature         # feature | bug | chore | docs | test | research
created: 2026-08-26
updated: 2026-08-26
closed: null          # null while open, YYYY-MM-DD when closed
assignee: unassigned  # agent name or human
labels: [setup, flutter]
estimated_tokens: 40000
---
```

Parser is `python -c 'import yaml'` compatible. Keep keys stable.

## Issue Body Sections (from TEMPLATE.md)

1. **Description** — what & why (link to `documentations/project_goal/goal.md` §)
2. **Goals / Acceptance Criteria** — checkboxes, measurable
3. **Tasks** — `- [ ]` breakdown, ideally < 1 day each
4. **Redfish Mapping** — endpoints, schemas, OEM extensions
5. **Progress Log** — timestamped notes while working
6. **References** — docs, spec links, `file_path:line_number`

---

## Workflow

### For Agents (and humans)

#### 1. Start of session — discover work

```bash
python3 issues/issues.py list          # or: ls -1 issues/open
cat issues/open/001-project-setup-flutter-scaffold.md
cat progress/journal.md
```

Pick highest priority `P1` → `P2` → oldest `created`.

#### 2. Create a new issue

```bash
cp issues/TEMPLATE.md issues/open/011-my-new-feature.md
# edit frontmatter + body, set id/title/created/updated
python3 issues/issues.py validate
```

Or via helper:

```bash
python3 issues/issues.py new "my new feature" --type feature --priority P2 --estimate 20000
```

Rules:
- One concern per issue.
- Search `open/` + `closed/` first — no duplicates.
- Link to `goal.md` section that motivates it.

#### 3. Work the issue

- Update `Progress Log` inside the markdown while you work.
- Update `progress/journal.md` daily (see `DEVELOPMENT.md`).
- Commit often: `git add issues/open/NNN* progress/journal.md && git commit -m "progress: #NNN <what>"`

#### 4. Close an issue

When **all** acceptance criteria are checked + tests pass:

```bash
python3 issues/issues.py close 001 --reason "scaffold + CI green"
# equivalent manual:
# 1. edit file: status: closed, closed: YYYY-MM-DD, updated: YYYY-MM-DD, check boxes
# 2. git mv issues/open/001-*.md issues/closed/
```

Add a final `Progress Log` entry + `Closed` note. Never delete closed files — they are the audit trail.

#### 5. Reopen if needed

```bash
python3 issues/issues.py reopen 001
# moves back to open/, sets status: open, closed: null
```

#### 6. End of day — daily push

```bash
git status
git add <code> <tests> issues/ progress/ DEVELOPMENT.md  # code + tests + tracking
git commit -m "chore: daily sync $(date +%Y-%m-%d) — #001 #002 ..."
git push origin main
```

Policy details: `DEVELOPMENT.md`.

---

## Priority & Type

| Priority | Meaning | SLA |
|----------|---------|-----|
| **P1** | critical path / blocks other work | do next |
| **P2** | high — core goal | this week |
| **P3** | medium — important but not blocking | this milestone |
| **P4** | low — polish / nice-to-have | backlog |

| Type | When |
|------|------|
| `feature` | new capability |
| `bug` | fix |
| `chore` | infra / tooling / deps |
| `docs` | documentation only |
| `test` | tests / coverage |
| `research` | spike / investigation, time-boxed |

---

## Helper CLI

```bash
python3 issues/issues.py list                 # table of open issues
python3 issues/issues.py list --all           # open + closed
python3 issues/issues.py list --closed        # only closed
python3 issues/issues.py show 001             # cat + frontmatter parse
python3 issues/issues.py close 001            # mv open→closed, patch frontmatter
python3 issues/issues.py reopen 001           # mv closed→open
python3 issues/issues.py new "title" [opts]   # scaffold from TEMPLATE
python3 issues/issues.py stats                # counts by priority/type/status
python3 issues/issues.py validate             # lint frontmatter + naming
```

No dependencies beyond Python 3.9+ stdlib (`yaml` is optional — parser falls back to regex).

---

## Progress Tracking

- `progress/journal.md` — **append daily**. Format `## YYYY-MM-DD — Author` with `Done / Decisions / Next / Issues touched`.
- `progress/progress_summary.md` — **weekly rollup** — what shipped, metrics, risks, next milestone. Agents must update after closing any P1/P2.
- Each issue's `Progress Log` — in-file scratch log.

See `DEVELOPMENT.md` for the tracking contract.

---

## Git Rules

- Issues are **never** squash-deleted. History is searchable via `git log --follow -- issues/`.
- Commit message convention: `feat: #NNN ...`, `fix: #NNN ...`, `progress: #NNN ...`, `docs: #NNN ...`, `chore: daily sync ...`
- Daily push is mandatory, even if WIP — push a `WIP: #NNN` commit rather than going silent.

---

## Anti-Patterns

- ❌ Creating GitHub Issues — use `issues/open/` only.
- ❌ Editing `closed/` files without reopening.
- ❌ Reusing an ID.
- ❌ Leaving an issue without `Progress Log` updates for >1 day while assigned.
- ❌ Pushing secrets / `.env` / credentials — they are `.gitignore`'d; connection profiles use secure storage only.

---

## Quick Reference

```bash
# find work
ls -1 issues/open | sort
# inspect
cat issues/open/003-system-discovery-engine.md
# close
python3 issues/issues.py close 003
# daily journal
cat progress/journal.md
```
