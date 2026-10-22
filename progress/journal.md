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

## 2026-08-27 — agent:opencode — #004 (close)

**Done:**
- Finalized #004 Multi-system manager (implementation carried over from prior agent session, completed this run). All acceptance criteria + tasks checked.
- Models: `ConnectionProfile` (uuid id, host/port/scheme, `useTls`, `AuthMethod`, `rememberPassword`, `allowSelfSigned`, `createdAt`; password never in persisted blob), `SystemSnapshot` + `Health`/`PowerState` enums + `fromSystemJson`/`toJson`.
- `SystemManager` (`StateNotifier<SystemState>`): `Map<id,SystemHandle>`, add/remove/update/connect/disconnect/select, `ProfileRepository` (SecureStorage; password stripped from blob, keystore only when remembered), `rehydrate()` on startup, per-system token isolation via injected `AuthManager`, instant context switch (select does NOT re-discover; cached `SystemFeatures`/`SystemSnapshot` reused).
- Routing: `go_router` `/:systemId/{overview,power,sensors,firmware,kvm}` + `SystemShell` capability-gated tabs (Overview always; others only when `features.*` true).
- Dashboard: `DashboardView` adaptive grid (1/2/3 cols) + `AggregatedStatus` header banner (`"2 OK, 1 Critical"`); `SystemCard`/`HealthBadge`/`PowerBadge` widgets.
- CRUD UI: `AddSystemDialog`/`EditSystemPage`/`SystemProfileForm` with `validateHost` (IPv4/IPv6/hostname) + `validatePort` (1–65535) + self-signed warning banner.

**Decisions:**
- `ConnectionProfile` defined in feature layer and re-exported from `redfish/models/connection_profile.dart` (shim) to keep #002 client compiling — documented in both files.
- Fixed 2 pre-existing widget-test harness bugs (off-viewport `Save` tap needed `ensureVisible`; `find.text('SN1')` → `Serial: SN1`) and added 2 dialog/page submit tests to exercise real `SystemManager`.
- Enlarged test viewport (1200×1600) for dialog/page submit tests instead of relying on scroll+ensureVisible.

**Next:**
- #005 power execution (now unblocked by #004 + #003); #006 adaptive overview cards; #007 realtime sensors.

**Issues touched:**
- #004 COMPLETE (analyze 0, 145 tests green / 1 skipped integration stub, 88.1% `features/systems` coverage) → closing.

## 2026-08-27 — agent:opencode — #005 (close)

**Done:**
- Completed issue #005 (Power management). `PowerService.reset(systemId, ResetType)` POSTs `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset` with the Redfish `ResetType` body, resolving the target via discovery raw tree → known `@odata.id` → live `/redfish/v1/Systems` crawl → canonical fallback. Unsupported types rejected locally (`SystemFeatures.supportedResetTypes`); 202+`Location` accepted (task polling deferred to #008). `PowerState`/`ResetType` enums, `PowerController` (optimistic transition + non-blocking 3s/30s polling), and Riverpod `powerServiceProvider`/`powerControllerProvider` families. `PowerView` gated on `features.powerControl` (renders nothing otherwise), animated `PowerBadge` (pulse only while transitioning), destructive-styled `ResetButton`s (disabled when unsupported), and `ConfirmResetDialog`. Error taxonomy: 403 → insufficient privilege, 409 → system busy, 400 → `@Message.ExtendedInfo`.
- Tests: 37 (service + controller + view + providers + model), all green; `flutter analyze` → **0 issues**; `features/power/` line coverage **87.4%** (gate ≥80%). Full suite now **182 passed / 1 skipped**.

**Decisions:**
- `RedfishError.fromJson` now extracts `Message` from `@Message.ExtendedInfo` entries (previously stored the whole map via `toString()`), so 400 extended-info messages surface correctly. `PowerBadge` only starts its pulse animation for transitional states (idle badges stay static, so `pumpAndSettle` in widget tests converges).
- Removed garbled/duplicate scratch scaffolding from the prior interrupted #005 session (`test/features/power/power_models_test.dart`, `test/scratch_debug_test.dart`) and fixed several test-harness bugs (wrong `overrideWith` arity, `expectLater(...) as RedfishException` cast, missing `id:'bmc1'` in `ConnectionProfile`, `find.widgetWithText` for disabled buttons, malformed 403 mock replying 202).

**Next:**
- #006 System overview adaptive cards (next open by priority). Power tab already routed via `app_router.dart` + gated in `SystemShell`.

**Issues touched:**
- #005 — COMPLETE (analyze 0, 37 power tests green, 87.4% power coverage; full suite 182 passed) → closing.

## 2026-08-27 — agent:triage — validator (run 2)

**Done:**
- Re-ran full triage audit per validator contract. `python3 issues/issues.py validate` → OK (all 10 issues pass naming + frontmatter).
- `stats`: 10 total / 5 open (#006,#007,#008,#009,#010) / 5 closed (#001,#002,#003,#004,#005). By priority P1:5 P2:4 P3:1; by type feature:8 chore:2. Open IDs 006–010 contiguous, no gaps/reuse.
- Duplicate NNN across open+closed: clean (no overlaps). Filename↔id prefix match verified for all 5 open (006..010).
- `.gitignore` audit: `git check-ignore` exit=1 (NOT ignored) for `issues/open/006-*` and `progress/journal.md`; exit=0 (ignored) for `.env` and `.dart_tool/build`. Tracking dirs safe, secrets/build outputs correctly excluded.
- Git hygiene: branch ahead of origin/main by 8 commits; working tree clean (nothing to commit). Last verified push 2026-08-26 23:13 (~18h ago, under 24h) — no push WARN. Remote is GitHub mirror only (no GitHub Issues used).
- Stale detection: all 5 open issues last updated 2026-08-26 (1 day stale) — under the 3-day threshold; no Progress Log stale notes appended, `updated` left as-is.
- `progress_summary.md` accuracy fix: the **Shipped** detail bullets omitted #003 (discovery engine) although "Closed this week" and the Snapshot already listed it. Inserted a #003 Shipped bullet with coverage/metrics so Shipped (5 entries) matches Closed-this-week (5) and the In Progress (5 open) + Metrics (5 open/5 closed) sections. Snapshot date 2026-08-27 already current.

**Decisions:**
- No frontmatter/naming repairs needed (validate green, IDs contiguous, status=open, closed=null on all open).
- No stale notes / no journal "today missing" stub needed (today entry present; appended this run 2 entry for audit trail).
- No push WARN: last push <24h and working tree clean.

**Next:**
- dev-worker continues #006 (System overview adaptive cards) — next open by priority; #007/#008/#009/#010 queued.
- triage re-runs in 6h; watch for >24h-without-push after 2026-08-27 23:13.

**Issues touched:**
- `progress/progress_summary.md` (#003 Shipped bullet added) — no issue number.

## 2026-08-27 — agent:triage — validator (run 3)

**Done:**
- Re-ran full triage audit per validator contract. `python3 issues/issues.py validate` → OK (all 10 issues pass naming + frontmatter).
- `stats`: 10 total / 5 open (#006,#007,#008,#009,#010) / 5 closed (#001,#002,#003,#004,#005). By priority P1:5 P2:4 P3:1; by type feature:8 chore:2. Open IDs 006–010 contiguous, no gaps/reuse.
- `list --json` emits valid JSON (5 open objects, id/status/updated fields correct) — no serialization regression vs run-2 fix.
- Duplicate NNN across open+closed: clean (no overlaps). Filename↔id prefix match verified for all 5 open (006..010).
- `.gitignore` audit: `git check-ignore` exit=1 (NOT ignored) for `issues/open/006-*` and `progress/journal.md`; exit=0 (ignored) for `.env` and `.dart_tool/build`. Tracking dirs safe, secrets/build outputs correctly excluded.
- Git hygiene: branch ahead of origin/main by 9 commits; working tree clean (nothing to commit). Last verified push 2026-08-26 23:13 (~18h ago, under 24h) — no push WARN. Remote is GitHub mirror only (no GitHub Issues used).
- Stale detection: all 5 open issues last updated 2026-08-26 (1 day stale) — under the 3-day threshold; no Progress Log stale notes appended, `updated` left as-is.
- `progress_summary.md` re-verified: Shipped=5 (#001–#005), In Progress=5 (#006–#010), Metrics 5 open/5 closed, all coverage/analyze/test numbers match current stats. No edit needed.

**Decisions:**
- No frontmatter/naming repairs, no summary edits, no stale notes, no journal "today missing" stub (today entry present; appended this run-3 entry for audit trail).
- No push WARN: last push <24h and working tree clean. Watch for >24h-without-push after 2026-08-27 23:13.

**Next:**
- dev-worker continues #006 (System overview adaptive cards) — next open by priority; #007/#008/#009/#010 queued.
- triage re-runs in 6h; next push gate 2026-08-27 23:13.

**Issues touched:**
- none (audit only)

## 2026-08-30 — agent:triage — validator (run 2)

**Done:**
- Ran full triage audit per validator contract. `python3 issues/issues.py validate` → OK (all 27 issues pass naming + frontmatter).
- `stats`: 27 total / 22 open / 5 closed (#001–#005). By priority P1:8 P2:14 P3:5; by type feature:9 bug:12 chore:6. Open IDs 006–027, closed 001–005 — contiguous, no gaps/reuse.
- `list --all` cross-checked vs stats: consistent.
- Staleness: all 22 open issues `assignee: unassigned` → "assigned & >1 day stale" rule not triggered; no new stale notes. (Run 1 today already flagged #006–#010 stale — 4 days no Progress Log since 2026-08-26 — and created #011–#027.)
- Frontmatter: no repairs needed (validate green, `updated` = 2026-08-30 on all open, `closed: null` on all open, IDs contiguous).
- `.gitignore` compliance: clean. Tracked non-issue files are config/docs only; `build/`, `coverage/`, `.dart_tool/` ignored AND untracked; no secrets tracked (`.env*`, `*.pem`, `*.keystore`, `*.jks`, `*.p12`, `credentials.json` all absent from `git ls-files`). `pubspec.lock` intentionally tracked (app, not package).
- `closed/` untouched (no edits in working tree; no reopens).
- `progress_summary.md`: already current — Snapshot dated 2026-08-30, Shipped + "Closed this week" cover #001–#005, Metrics 22 open/5 closed matches stats. No edit needed.
- **Git hygiene WARN:** working tree dirty from run-1 triage (modified #006–#010 stale notes + summary; untracked #011–#027) — **not committed, not pushed**. Branch level with origin/main; last push 2026-08-27 20:41 (~>24h ago) → push gate breached.

**Decisions:**
- No frontmatter repairs, no stale-note additions, no summary edits this run.
- Next dev-worker action should start with committing + pushing the run-1 triage output (daily push contract), then pick #027 (Flutter toolchain) or #014 (error parsing) — both P1.

**Next:**
- Commit + push run-1 triage changes (restores push gate).
- #027 (toolchain) gates analyzer-verified work; #014/#015 are the P1 bug fixes.

**Issues touched:**
- none (audit only)

## 2026-08-30 — agent:daily-push — verified push f41f35b to origin/main — daily mirror

- push verified: `git ls-remote origin refs/heads/main` equals HEAD (f41f35bb835b80395b3f719e262d34f977e36b13)
- working tree clean this run — nothing new to stage/commit; f41f35b was already on remote (stale local `origin/main` tracking ref corrected via `git fetch`)
- last mirrored commit: f41f35b `progress: triage 2026-08-30 run-1 — validate OK, 22 open; add #011–#027 carve-outs + stale notes` (issues/ + progress/ only)
- issues: 27 total / 22 open (#006–#027) / 5 closed (#001–#005)
- validate: OK — all 27 issues pass naming + frontmatter (per today's run-2 audit)

## 2026-09-02 — agent:triage — validator

**Done:**
- Ran full triage audit per validator contract. `python3 issues/issues.py validate` → OK (all 27 issues pass naming + frontmatter).
- `stats`: 27 total / 22 open / 5 closed (#001–#005). By priority P1:8 P2:14 P3:5; by type feature:9 bug:12 chore:6. `list --all` cross-checked vs stats: consistent, IDs contiguous (open 006–027, closed 001–005), no gaps/reuse.
- Staleness: all 22 open issues `assignee: unassigned` → "assigned & >1 day stale" rule not triggered; no new stale notes appended. Pre-existing STALE notes on #006–#010 (added 2026-08-30) remain valid — their Progress Logs are now ~7 days old (last entry 2026-08-30) and still unactioned. #011–#027 Progress Logs last touched 2026-08-30 (creation).
- Frontmatter: no repairs needed. `validate` green; all required fields present in every open issue (spot-scanned); `updated: 2026-08-30` on all open, `closed: null` on all open; `closed/` frontmatter intact (`status: closed` + closed date 2026-08-27 on #001–#005).
- `.gitignore` compliance: clean. `build/`, `coverage/`, `.dart_tool/`, `.env`/`*.env`, `credentials.json`, `*.keystore`, `*.jks`, `*.p12`, `*.pem` all ignored; none tracked. Only tracked `*.lock` is `pubspec.lock` (intentional, negated in `.gitignore`). `test/fixtures/redfish/.../NVMeoFSecrets/*.json` are Redfish mock data, not secrets.
- Git hygiene: working tree clean; HEAD = origin/main = 54366e1 — branch in sync, nothing unpushed, no push WARN.
- `closed/` untouched (no edits, no reopens).

**Decisions:**
- No issue-file edits this run (no stale flags to add, no frontmatter to fix).
- `progress_summary.md` NOT updated: no P1/P2 closed since the 2026-08-30 snapshot (closed set unchanged at #001–#005, all already in Shipped/Metrics). Snapshot content remains accurate (22 open / 5 closed). Note: the footer's 2026-09-02 weekly cadence date was reached with nothing new to roll up; next update remains gated on the next P1/P2 close.
- Next dev-worker action: assign + start a P1 — #027 (Flutter toolchain) unblocks analyzer-verified work for #014/#015 (P1 bug fixes) and the 22-issue queue.

**Next:**
- dev-worker: commit assignment + Progress Log entry when starting #027 (or #014/#015 directly).
- triage re-runs per cadence; watch for first P1 close to roll up `progress_summary.md`.

**Issues touched:**
- none (audit only; this journal entry)

## 2026-10-22 — agent:redfish-automation — DOCS run

**Done:**
- DOCS-1: established `documentations/external/redfish/` official-docs mirror —
  DSP0266 1.25.0 PDF, bmcweb Redfish.md / REDFISH_CHECKLIST.md / OEM_SCHEMAS.md
  (upstream `0128851e`), Redfish-Mockup-Server README (upstream `23d21f9a`),
  full DMTF schema index listing, and 16 base aggregator schemas. Manifest with
  URL + fetch time + SHA-256 + bytes in `documentations/external/README.md`
  (~4.8 MB total, within budget). Commit c8dc7e1 (local; push blocked — no
  GitHub credentials in this environment, recorded in tracking).
- Created `documentations/external/redfish/REQUIREMENTS.md`: 14-row
  requirement→code→test→status trace (9 OK, 4 GAP, vendor rows cited).
- UI-2 increment: `HealthBadge`/`PowerBadge` semantic labels + per-state health
  icons; 2 new widget tests.
- DOCS-2 partial: provenance note linking `redfish_reference` to the live corpus.

**Decisions:**
- Fresh queue → DOCS first (no DOCS/EMULATOR run yet in tracking).
- Mirrored base aggregator schemas (small stubs) rather than versioned files
  (keeps corpus bounded; versioned defs resolvable via the index listing).
- Event subscription gap is real (no EventService code); filed as DOCS-7 instead
  of an issue until scope is decided.

**Next:**
- EMULATOR run (EMU-1/EMU-2): stand up mockup-server over HTTPS + integration tests.
- DOCS-2: refresh fixtures snapshot against verified upstream commits.
- DOCS-3: continue DSP0266 audit; decide event-subscription scope (DOCS-7).

**Issues touched:**
- none opened/closed this run (docs + UI only; FUTUREWORK updated).

## 2026-10-22 — agent:redfish-automation — EMULATOR run

**Done:**
- EMU-1: official DMTF Redfish-Mockup-Server (pin `23d21f9a`) running over
  HTTPS on 127.0.0.1:8443 against `test/fixtures/redfish/dmtf_mockup` with a
  generated self-signed cert; health check + `-S` fixture mode verified.
- EMU-2: `test_integration/emulator/emulator_suite_test.dart` — 11 end-to-end
  tests (service root, DiscoveryEngine BFS + feature map, sensors, firmware
  inventory, KVM console, session + basic auth, power state, reset action,
  404 error mapping). Skips via `markTestSkipped` when `REDFISH_EMULATOR_URL`
  is unset, so plain `flutter test` never needs the emulator.
- EMU-4: `tool/emulator/run_tests.sh` (committed pin `23d21f9a`, venv/cert
  under /tmp only, health wait, `trap` cleanup) — verified end-to-end, no
  stray process after run.
- EMU-3 partial: auth (session token mint/reuse/logout + basic) and reset
  action + 404 mapping covered; 403/409/400 extended-info paths deferred to a
  richer emulator (EMU-5).
- UI-5 (+UI-2 tie-in): `ConfirmResetDialog` destructive copy + destructive
  `Semantics` label on confirm button; 1 new widget test.
- Docs: emulator harness section in `documentations/external/README.md`;
  "Test platforms" note in `REQUIREMENTS.md`.

**Decisions:**
- Kept the diff focused: `dart format` on touched files only. A repo-wide
  format run would churn ~54 files and introduces a `curly_braces` lint in
  `kvm_view.dart`; format-cleanliness remains a deliberate FUTUREWORK P2 item.
- `allowSelfSigned: true` is test-profile-only (EMU-6); production TLS is
  untouched.
- Emulator session POST mints a token for any credentials (static mockup) — the
  suite asserts the client's session flow works, not that the mockup validates
  credentials.

**Next:**
- Push 2 queued local commits (c8dc7e1 DOCS, EMULATOR) once a machine with
  GitHub credentials is available.
- DOCS-3: continue DSP0266 audit; decide EventService/Subscriptions scope
  (DOCS-7).
- P1 #014/#015 (RedfishError parsing / session URI discovery) — likely need
  richer fixtures (EMU-5) or unit-level work.

**Issues touched:**
- none opened/closed this run (EMU-1..4, EMU-6, UI-5, UI-2 partial; FUTUREWORK
  updated with run markers).

## 2026-10-22 — agent:redfish-automation — DOCS run (DOCS-3 + DOCS-7)

**Done:**
- DOCS-3: completed the DSP0266 1.25.0 audit of eventing + tasks against the
  client. Corrected two wrong section citations in REQUIREMENTS.md (Eventing is
  §12.1, not §14; Tasks/async ops is §12.2 "Asynchronous operations", not
  §13.4). Added 5 new trace rows: event-subscription lifecycle, SSE
  `ServerSentEventUri`, EventType deprecation note, task-monitor polling
  contract, and 2 bmcweb vendor rows (EventService/TaskService field sets from
  `Redfish.md` @ `0128851e`).
- DOCS-7: recorded the event-subscription scope decision — **out-of-scope this
  milestone** — with rationale (no consumer, no SSE transport in pubspec, no
  push-capable test bed) and spec citations in REQUIREMENTS.md; FUTUREWORK
  updated (DOCS-7 `[x]` + new P2 "Events" item gated on telemetry/task work).
- UI-3 first slice: 3 new widget tests asserting PowerView renders without
  overflow at 320/800/1300 px (no production change needed — layout already
  wraps correctly; regression protection added).

**Decisions:**
- Event subscriptions are poll-free for now; telemetry (#007/#019), firmware
  task monitoring (#008/#020), power task handling (#022) stay poll-based and
  are the revisit point for events.
- Kept the diff focused: repo-wide `dart format` would touch ~50 files and
  reintroduce the known `curly_braces` lint in `kvm_view.dart`; formatted only
  the touched test file (matches EMULATOR-run precedent; format-cleanliness
  remains FUTUREWORK P2).
- No new doc downloads this run (audit used the mirrored DSP0266 PDF + corpus).

**Next:**
- Push queued local commits once GitHub credentials are available (5 total).
- P1 code: #014 (RedfishError ExtendedInfo) or #015 (AuthManager session URI)
  using the in-process mock server.
- EMU-5 evaluation if richer error paths (403/409/400 ExtendedInfo) are needed
  for #014/#015 test coverage.

**Issues touched:**
- none opened/closed this run (docs audit + DOCS-7 decision + UI-3 tests;
  FUTUREWORK updated).

## 2026-10-22 — agent:redfish-automation — EMULATOR run (EMU-5 decision + #014)

**Done:**
- EMU-5: evaluated `DMTF/Redfish-Interface-Emulator` @ `5f51d8a` (dynamic
  service, 400 on invalid ResetType). **Decision: stay on Redfish-Mockup-Server**
  — the richer emulator's error bodies are non-conformant (`{"error":"msg"}`,
  no `error` envelope / `@Message.ExtendedInfo`) and its SessionService 404s;
  decision + pin recorded in REQUIREMENTS.md "EMU-5 decision". Re-ran
  `tool/emulator/run_tests.sh` (11 emulator tests green; trap cleanup ok).
- #014 (P1) **closed**: `RedfishError.fromJson` self-descends into the DSP0266
  `error` envelope; `RedfishException.fromResponse` normalizes any map-shaped
  body via `RedfishError.tryParse`; removed dead lowercase dynamic-keyed branch.
  Spec-conformant unit fixtures (envelope, top-level noise, full-body
  fromResponse with `@Message.ExtendedInfo`) prove the old silent-drop bug
  ("Unknown error") is fixed and `firstMessage` prefers `ExtendedInfo[0]`.
- UI-2/UI-5 increment: reset buttons announce "«action», action in progress"
  to assistive tech while in flight (Semantics label) and stay disabled;
  2 new widget tests (busy announced / idle none), bounded pumps for the
  infinite spinner.
- Tracking: automation-tracking.md section appended; FUTUREWORK updated
  (EMU-5 `[x]`, #014 `[x]` + removed from P1 defects, UI-5 note, #027 note,
  focus line); progress_summary.md updated for the P1 close.

**Decisions:**
- EMU-5: mockup-server + unit fixtures > richer emulator for error mapping
  (non-conformant bodies would encode the wrong contract; no auth coverage).
- #014: self-descend in `fromJson` rather than changing every caller — keeps
  `RedfishError.tryParse` and `fromResponse` correct for both full-body and
  pre-extracted inputs; spec-pinned fixtures stay authoritative.

**Next:**
- Push 7 queued local commits from a machine with GitHub credentials.
- P1 #015 AuthManager (authMethod, safe logout URI, session reuse/expiry) —
  unit-level with the in-process mock server.
- #027: close the stale toolchain issue with evidence (baseline green every
  run since DOCS-1); or UI-5 busy state on the dialog confirm button.

**Issues touched:**
- #014 closed (2026-10-22) — first P1 close since #005; progress_summary.md
  updated.
