# Development Journal — redfishopenbmc

> Daily log. Append a `## YYYY-MM-DD — author` section every working day. See `DEVELOPMENT.md` and `issues/README.md`.

---

## 2026-08-26 — agent:opencode — bootstrap

**Done:**
- Created localized issue system: `issues/open/`, `issues/closed/`, `issues/README.md`, `issues/TEMPLATE.md`, `issues/issues.py` (helper CLI: list/show/close/reopen/new/stats/validate)
- Created skill `.opencode/skills/redfish-issues/SKILL.md` so agents auto-load the workflow
- Created `DEVELOPMENT.md` (daily push contract — code+tests+tracking daily, what is/isn't pushed, DoD)
- Seeded 10 starter issues from `documentations/project_goal/goal.md`:
  - #001 P1 chore — Flutter scaffold, tooling, state & CI (blocks all)
  - #002 P1 feature — Redfish client core HTTP/auth/session (blocks #003–#010)
  - #003 P1 feature — Discovery engine (schema-driven capability map)
  - #004 P1 feature — Multi-system manager & dashboard
  - #005 P1 feature — Power management
  - #006 P2 feature — System overview adaptive cards
  - #007 P2 feature — Sensor monitoring realtime
  - #008 P2 feature — Firmware & update management
  - #009 P3 feature — Remote KVM
  - #010 P2 chore — Hardening (secure storage, TLS, theming, a11y, coverage gate)
- Verified helper: `python3 issues/issues.py list/stats/validate` green; `ls -R issues` clean

**Decisions:**
- Issues are git-tracked (not `.gitignore`'d) — history is the audit trail; GitHub mirror gets code+tests+issues+progress daily
- Naming `NNN-kebab.md`, YAML frontmatter contract (`id`, `status`, `priority`, `type`, `created`, `updated`, `closed`, `estimated_tokens`, `labels`), task checkboxes, Redfish Mapping table, Progress Log
- Helper is stdlib-only (yaml optional, regex fallback) so it works without `pip install`
- Estimated tokens per issue to help agent planning; P1→P4 SLA in `issues/README.md`
- Next physical step is #001 `flutter create` + `analysis_options.yaml` + deps + CI; must run before any Redfish code

**Next:**
- [ ] Human/agent picks #001 and runs `flutter create .` (record Flutter version in DEVELOPMENT.md)
- [ ] Fill `.gitignore` for Flutter (done this commit)
- [ ] Daily push: this bootstrap is the first `chore: daily sync`

**Issues touched:**
- #001 opened — ready to start
- #002–#010 opened — blocked on #001 (and #002 for #003)
- Meta: localized system itself — no issue number, bootstrapped here

**Notes:**
- Symlink verified: `/home/tomi/projects/redfishbmc → /home/tomi/projects/redfishopenbmc` (same inode)
- Progress summary initialized (see `progress_summary.md`); next rollup after #001 closes

## 2026-08-26 — agent:daily-push — verified push 7b45582 to origin/main — issues synced

- push verified: ls-remote SHA equals HEAD (7b455820e9a20d53bc45d2ce98863ba591c02e54)
- staged: .opencode/agents/development-agent.md (code+tracking only, secrets excluded)
- issues: Total: 10  Open: 10  Closed: 0 By priority: {'P1': 5, 'P2': 4, 'P3': 1} By type:     {'chore': 2, 'feature': 8} By status:   {'open': 10} Open IDs:   001, 002, 003, 004, 005, 006, 007, 008, 009, 010 Closed IDs: — 
- validate: validate: OK — all issues pass naming + frontmatter checks

## 2026-08-27 — agent:opencode — #001 (close)

**Done:**
- Installed Flutter 3.47.1 / Dart 3.13.1 (`git clone ~/flutter --depth 1 --branch stable`; `~/flutter/bin` on PATH).
- Verified existing `flutter create .` scaffold (all 6 platforms) + `lib/` layout per acceptance criteria.
- `flutter pub get` → `pubspec.lock` generated & tracked. `flutter analyze` → **0 issues**. `flutter test` → **13/13 green**. `flutter test --coverage` → lcov generated.
- Fixed `analysis_options.yaml` (removed 6 Dart-3.x-removed lints) and 2 test bugs (`colorScheme.seed` getter; `find.textContaining` matching 2 widgets).
- Added `.github/workflows/flutter-ci.yml` (analyze+test+coverage+issues validate) — already present, confirmed correct.
- Documented Riverpod-over-Bloc rationale + toolchain table in `DEVELOPMENT.md`.

**Decisions:**
- Riverpod chosen for state (#001): async-native (`FutureProvider`/`StreamProvider`), `family` providers give per-`systemId` isolation matching the multi-host model, less ceremony than Bloc for the many small slices #002–#010.
- Kept `json_serializable`/`build_runner` as dev deps for #002+ models; #001 uses hand-written `fromJson`/`toJson` stubs.

**Next:**
- #002 Redfish client core (HTTP/TLS/auth/session) — unblocks #003–#010.

**Issues touched:**
- #001 — COMPLETE, all criteria checked, analyze 0 / tests 13 green → closing.
