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

## 2026-08-27 — agent:opencode — #001 strictness polish

**Done:**
- Switched `analysis_options.yaml` from `package:lints/recommended.yaml` to `package:very_good_analysis/analysis_options.yaml` (stricter), fulfilling the "or stricter" clause and using the already-declared dev dep.
- Added full `///` documentation to every public member across `lib/` (theme, breakpoints, router/shell, secure storage interface + impls, redfish models, placeholder feature pages, `main.dart`).
- Fixed all 92 resulting `very_good_analysis` lint findings: `public_member_api_docs`, `omit_local_variable_types`, `avoid_redundant_argument_values`, `always_use_package_imports`, `require_trailing_commas`, `sort_pub_dependencies`, `comment_references`, `cascade_invocations`, `directives_ordering`, `lines_longer_than_80_chars`, `always_put_required_named_parameters_first`.
- Reworked conditional HTTP adapter import (`http_client_config*.dart`) to use `export` + public `createHttpClientAdapter`, fixed `dart.library.html` conditional, and replaced the removed `dio` `Lock` with a `Future`-based refresh lock in `AuthManager`.
- `flutter analyze` → **0 issues**, `flutter test` → **13/13 green**.

**Decisions:**
- Adopted very_good_analysis as the project-wide lint baseline; #002+ code inherits it (keeps committed code at 0 issues).
- Left the in-progress #002 Redfish client/session/auth files (auth_manager, session, connection_profile, redfish_exception, http_client_config*) untracked for the active #002 worker.

**Issues touched:**
- #001 — stricter lint + docs committed on top of the closed scaffold.

## 2026-08-27 — agent:triage — validator

**Done:**
- Ran full triage audit per validator contract. `python3 issues/issues.py validate` → OK (all 10 issues pass naming + frontmatter).
- `stats`: 10 total / 9 open (002–010) / 1 closed (001). By priority P1:5 P2:4 P3:1; by type feature:8 chore:2. Open IDs 002–010 contiguous, no gaps/reuse.
- Duplicate NNN check across open+closed: clean (no overlaps).
- `issues.py` helper defect found + fixed: `list --json` and `stats --json` raised `TypeError: date not JSON serializable` (date objects in frontmatter). Patched both `json.dumps` calls with `default=str`. Verified both commands now emit valid JSON.
- `.gitignore` audit: `issues/open/*` and `progress/journal.md` NOT ignored (correct); `.env` and `.dart_tool/build` ARE ignored (correct). Tracking dirs safe.
- Stale detection: all open issues last updated 2026-08-26 (1 day stale) — under the 3-day threshold, so no stale Progress Log notes appended, `updated` left as-is.
- Git hygiene: branch ahead of origin/main by 2 commits (e43be1f, bbf794d); last push 2026-08-26 23:13 (~3.5h ago) — under 24h, no push WARN.
- `progress_summary.md`: refreshed Snapshot date to 2026-08-27 and "Next update" note (was pending #001 close, now pending #002 close). In Progress list (9 open) + Metrics (9 open/1 closed) already matched current stats.

**Decisions:**
- No stale notes / no frontmatter repairs needed (validate green, IDs contiguous, status/closed correct).
- WIP files for #002 (untracked `lib/redfish/client/*`, `lib/redfish/models/*`, `test/redfish/`) intentionally left uncommitted — owned by the active #002 dev-worker, not triage.
- Modified `.opencode/agents/development-agent.md` left uncommitted (agent config, not triage scope).

**Next:**
- dev-worker continues #002 (Redfish client core); triage re-runs in 6h.
- Watch for >24h-without-push after 2026-08-27 23:13 to trigger push WARN.

**Issues touched:**
- Helper: `issues/issues.py` (json serialization fix) — no issue number.
- `progress/progress_summary.md` (snapshot date + next-update note) — no issue number.


## 2026-08-27 — agent:opencode — #002 (close)

**Done:**
- Verified the #002 Redfish client core (implemented by a prior worker) is fully green: `flutter analyze` → 0 issues, `flutter test` → 55 passed / 1 integration skipped.
- Added `RedfishClient.createDioForProfile(profile)` static factory so callers get the shared TLS-first + Redfish-header + 10s/30s-timeout policy without constructing a client.
- Added `AuthManager.withAuth(systemId, action)` convenience wrapper (throws `StateError` when not logged in; runs the action with the authenticated client and inherits the 401-refresh interceptor).
- Added `test/redfish/client/redfish_client_extra_test.dart` (factory config assertions + withAuth happy/error paths) and `test/redfish/models/models_test.dart` (Session `copyWith`/`isExpired`, ConnectionProfile `copyWith`/`baseUrl`, `RedfishError` both-case parsing).
- Measured `redfish/client/` line coverage at **89.8%** (gate 80%). All acceptance criteria checked; `DEVELOPMENT.md` already carries the `#002` Security notes (TLS matrix, secret-at-rest, storage backend table, error taxonomy).

**Decisions:**
- Kept `withAuth` non-async-locking on top of the existing per-system `Future` refresh lock — transparent 401 re-auth works inside it.
- `redfish_error.dart` already tolerant of `Code`/`code` + `Message`/`message`; regression test asserts both.

**Next:**
- #002 closing unblocks #003 (discovery engine). Next worker should start #003 with `DiscoveryEngine` + `feature_rules.dart` + fixtures.

**Issues touched:**
- #002 — COMPLETE (analyze 0, 55 tests green, 89.8% client coverage) → closing.

## 2026-08-27 — agent:opencode — #003 (close)

**Done:**
- Implemented the schema-driven discovery engine (the app's core differentiator). `flutter analyze` → **0 issues**, `flutter test` → **93 passed / 1 skipped**, `discovery/` line coverage → **91.0%** (gate ≥85%).
- `lib/redfish/models/odata.dart` (ODataResource + ODataLink), `lib/redfish/models/system_features.dart` (full feature map + `copyWith`/`toJson`/`fromJson`).
- `lib/redfish/discovery/feature_rules.dart` (table-driven `FeatureRules` + `DiscoveryContext`), `discovery_cache.dart` (`DiscoveryCache` TTL + `DiscoveryPersister` NoOp/InMemory), `discovery_engine.dart` (`DiscoveryEngine`: ServiceRoot → 5 seeds → concurrent cycle-safe BFS depth ≤3, ETag-aware 304 replay, graceful per-branch 404, `invalidate`, `rawTree`).
- Fixtures `test/fixtures/redfish/*.json` (OpenBMC bmcweb-style + DMTF minimal) + `FakeBmc` Dio-interceptor harness; `discovery_engine_test.dart` (30 cases) + `feature_rules_test` + `odata_test`.

**Decisions:**
- Engine consumes `RedfishClient.dio` directly (TLS-first headers/timeout inherited) and converts 4xx/5xx + 304 via `RedfishException.fromDioException`; ServiceRoot failure surfaces as `RedfishException`, branch failures are tolerated.
- `SensorCollection` routed into the sensor count (its `Members` length) since real OpenBMC exposes sensors as a collection.
- Persister is an interface with NoOp default + InMemory test stand-in; `hive`/`shared_preferences` deferred to #010 (no native dep added).

**Next:**
- #003 unblocks #004 (multi-system manager) and #005–#010. Next worker: wire `DiscoveryEngine`/`SystemFeatures` into `DiscoveryPage` UI + a per-system provider (#004), then power (#005).

**Issues touched:**
- #003 — COMPLETE (analyze 0, 93 tests green, 91.0% discovery coverage) → closing.
