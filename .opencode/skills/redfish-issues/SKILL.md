---
name: redfish-issues
description: Localized filesystem issue tracker for redfishopenbmc — use issues/open and issues/closed instead of GitHub Issues. Mandatory workflow for all agents.
---

# Skill: redfish-issues

> **Source of truth:** `issues/README.md` + `issues/TEMPLATE.md`
> **Helper:** `python3 issues/issues.py`

This skill enforces the project's **localized open/close folder system**. Never use GitHub Issues for this repo.

## When to use

- Starting any session — discover work
- Creating a new task / bug / feature
- Closing or reopening work
- Daily push / progress tracking

## Pre-flight checklist (every session)

```bash
# 1. Where am I?
ls -1 issues/open | sort
python3 issues/issues.py list
python3 issues/issues.py stats

# 2. Read top priority
cat issues/open/001-project-setup-flutter-scaffold.md
cat progress/journal.md
cat progress/progress_summary.md

# 3. Check helper
python3 issues/issues.py validate
```

## How agents create issues

1. Copy template: `cp issues/TEMPLATE.md issues/open/NNN-kebab.md` where `NNN = max(existing)+1`
2. Or use helper: `python3 issues/issues.py new "Title" --priority P1 --type feature --estimate 20000`
3. Edit frontmatter (`id`, `title`, `priority`, `type`, `created`, `updated`) and body sections
4. Validate: `python3 issues/issues.py validate`
5. Commit: `git add issues/open/NNN* && git commit -m "feat: #NNN <title>"`

Rules:
- `NNN` is zero-padded, never reused — `ls issues/open issues/closed | sort`
- One concern per issue; search open+closed first to avoid duplicates
- Link to `documentations/project_goal/goal.md` § that motivates it
- Set `estimated_tokens` realistically

## How agents work an issue

- Update `## Progress Log` in the issue file as you work (timestamped, newest first)
- Append daily entry to `progress/journal.md` (`## YYYY-MM-DD — agent — #NNN`)
- Commit often with `progress: #NNN ...` messages
- Keep `updated` frontmatter current

## How agents close an issue

Close only when **all** acceptance criteria are checked and `flutter test` / `flutter analyze` pass:

```bash
python3 issues/issues.py close 003 --reason "discovery engine + fixtures green"
# patches frontmatter (status: closed, closed: YYYY-MM-DD, updated: YYYY-MM-DD)
# moves file open/ → closed/
```

Manual equivalent:
- Edit frontmatter: `status: closed`, `closed: YYYY-MM-DD`, `updated: YYYY-MM-DD`
- Check all `- [ ]` → `- [x]` that are done
- Fill `## Closed Criteria`
- `git mv issues/open/NNN-*.md issues/closed/`
- Update `progress/journal.md` and `progress_summary.md` (required for P1/P2)
- `git add issues/closed/NNN* progress/ && git commit -m "close: #NNN <reason>"`

Never delete a closed issue.

## How agents reopen

```bash
python3 issues/issues.py reopen 003
```

## Priority discipline

Pick work by `P1 → P2 → P3 → P4`, then oldest `created`. If blocked, mark `status: blocked` in frontmatter + explain in `Progress Log`, pick next.

## Daily push contract (mandatory)

At end of every working day (even WIP):

```bash
git status
git add lib/ test/ pubspec.yaml analysis_options.yaml issues/ progress/ DEVELOPMENT.md README.md .github/
git commit -m "chore: daily sync YYYY-MM-DD — #001 #003 ..."
git push origin main
```

See `DEVELOPMENT.md` for what is pushed (code + tests + tracking) vs ignored (secrets, `.env`, build artifacts).

## Validation & stats

```bash
python3 issues/issues.py list --all
python3 issues/issues.py show 005
python3 issues/issues.py stats
python3 issues/issues.py validate   # run before every commit touching issues/
```

## Anti-patterns (fail the skill check)

- Creating a GitHub Issue
- Editing `issues/closed/` without `reopen`
- Reusing an ID
- Closing with unchecked acceptance criteria
- Pushing without updating `progress/journal.md`
- Leaving `estimated_tokens` empty or `labels: []` when labels clearly apply

## References

- `issues/README.md` — full workflow
- `issues/TEMPLATE.md` — issue scaffold
- `progress/journal.md` — daily log
- `progress/progress_summary.md` — weekly rollup
- `DEVELOPMENT.md` — push policy
- `documentations/project_goal/goal.md` — product spec
