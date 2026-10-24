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

## 2026-10-22 — agent:redfish-automation — DOCS run (DOCS-4 + #027 close)

**Done:**
- DOCS-4: completed the bmcweb feature-detection diff audit against
  `openbmc/Redfish.md` (field sets), `REDFISH_CHECKLIST.md` (contributor-process
  only — no client-facing fields), and `OEM_SCHEMAS.md` (OEM policy). Three real
  diffs recorded in REQUIREMENTS.md: (1) bmcweb firmware update is HTTP-push via
  `HttpPushUri`/`MultipartHttpPushUri` — no `SimpleUpdate` action, our
  `startSimpleUpdate` would 405 on OpenBMC (→ #008/#020); (2) bmcweb reset
  types come from `ResetActionInfo` ActionInfo `Parameters/AllowableValues`, not
  system `SupportedResetTypes` (→ #022/#016 fallback); (3) bmcweb serial console
  lives on the ComputerSystem, not the Manager (→ #009/#021). Plus vendor rows
  for `AccountService.Oem.OpenBMC.AuthMethods.*` (#015/#026) and
  `TelemetryService` (#007/#019).
- KVM `Oem` false-positive **fixed**: `FeatureRules._managerConsoleType` treated
  any `Oem` map as a console; bmcweb Managers always carry an `Oem` vendor block,
  so KVM would report available on every real OpenBMC system. New public
  `FeatureRules.oemHasConsole` requires a console-like key (`*console*`/`*kvm*`,
  depth ≤ 3); `KvmConsole.fromManager` uses the same contract. Tests in
  `feature_rules_test.dart` + `kvm_model_test.dart` (bare-Oem rejected, marker
  accepted).
- UI-3: SensorsView responsive-layout tests at 320/800/1300 px added to
  `sensors_widget_test.dart` (+3 tests; no production change — layout already
  wraps; regression protection added, same pattern as PowerView).
- #027 (P1 chore) **closed** with evidence: toolchain resolved to
  `~/flutter/bin/flutter` (git clone per #001, DEVELOPMENT.md Toolchain), analyze
  0 / tests green every run, no orphaned flutter_tester from this repo; snap
  download blocker no longer applies. Progress Log + Closed Criteria updated.

**Decisions:**
- `FeatureRules.oemHasConsole` is the single OEM-console contract shared by
  discovery rules and KVM parsing — prevents future divergence.
- No new doc downloads this run (corpus already mirrors bmcweb docs @ `0128851e`;
  audit-only).
- Kept the diff focused: `dart format` on touched files only (repo-wide format
  churn remains a deliberate FUTUREWORK P2 item).

**Next:**
- Push 9 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod, safe logout URI, session reuse/expiry) —
  unit-level with in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag; or #008/#020:
  bmcweb HTTP-push firmware upload path.

**Issues touched:**
- #027 closed (2026-10-22) — second P1 close; progress_summary.md updated.

## 2026-10-22 — agent:redfish-automation — EMULATOR run (suite +2, UI-5 dialog busy)

**Done:**
- EMULATOR primary: re-verified the pinned DMTF Redfish-Mockup-Server suite
  end-to-end (13/13 over HTTPS, trap cleanup, no stray process) and extended
  the suite with two tests: `systems: ComputerSystem exposes full inventory
  fields` (Model/Manufacturer/SerialNumber/PowerState/Status + `ResetType@
  Redfish.AllowableValues` on the Reset action) and `firmware: UpdateServiceInfo
  exposes the HTTP-push URI (DOCS-4)` (asserts `httpPushUri == '/FWUpdate'`
  through the real `FirmwareService` — the emulator-level counterpart of
  DOCS-4's bmcweb finding, ready for #008/#020).
- UI-5 **completed**: `ConfirmResetDialog` is now stateful and owns the
  in-flight state — confirm button disables + spins while the reset request is
  pending, Cancel disables too, `barrierDismissible: false` prevents mid-flight
  dismissal, and a "«action», action in progress" Semantics label mirrors the
  reset-button busy pattern. `PowerView._confirmAndRun` passes
  `controller.reset(action)` as `onConfirm`; the dialog pops only after the
  request resolves so snackbar behaviour is unchanged. 2 new widget tests
  (deferred-gate busy assertions + failing-service snackbar assertion).
- REQUIREMENTS.md: emulator trace notes updated (13 tests, inventory/push
  coverage); the bmcweb HTTP-push row now cites the emulator assertion.

**Decisions:**
- Kept the diff focused again: repo-wide `dart format` churns ~50 files and
  reintroduces the known `curly_braces` lint in `kvm_view.dart`; reverted the
  format-only churn and formatted only the touched files (prior-run precedent;
  repo-wide format remains FUTUREWORK P2).
- UI-5 dialog busy state is owned by the dialog (not the controller): the
  controller's `reset` never throws (records error in state), so the dialog
  can await it and pop with the outcome; the snackbar then reads the recorded
  error — no new error plumbing needed.

**Next:**
- Push 10 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod, safe logout URI, session reuse/expiry) —
  unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020:
  bmcweb HTTP-push firmware upload path (emulator now asserts HttpPushUri).

**Issues touched:**
- none opened/closed this run (EMULATOR extension + UI-5 completion; no issue
  status change; EMU-3 note updated in FUTUREWORK).

## 2026-10-22 — agent:redfish-automation — DOCS-5 run

**Done:**
- DOCS-5 **completed**: added the full `SystemFeatures` flag → spec citation →
  test map to `documentations/external/redfish/REQUIREMENTS.md` — a 10-row
  table tracing `powerControl`, `supportedResetTypes`, `kvm`, `kvmType`,
  `sensorMonitoring`, `sensorCount`, `firmwareUpdate`, `updateServiceVersion`,
  `managers`, `chassis` to DSP0266 sections / DMTF schemas / bmcweb `Redfish.md`
  and to their exact test cases in `feature_rules_test.dart` +
  `discovery_engine_test.dart`.
- **`FeatureRules.firmwareUpdate` fixed to honor `UpdateService.ServiceEnabled`**
  (DOCS-5 finding): an explicitly disabled UpdateService no longer counts as
  firmware capability — the Firmware tab and overview chip are gated off.
  Missing/`null` stays enabled. Tests: +1 rule test, +1 model test (disabled
  parse), discovery + integration + emulator suites re-run green.
- Confirmed `updateServiceVersion`'s `Version → Id` fallback is the conformant
  path (DMTF schema has no `FirmwareVersion`; it is vendor-only in the OpenBMC
  fixture) — recorded, no code change.
- UI-3 extended: FirmwareView no-overflow tests at 320/800/1300 px (+3 in
  `firmware_widget_test.dart`); Power/Sensors/Firmware now covered, dashboard
  and KVM remaining.

**Decisions:**
- `ServiceEnabled` semantics: missing/`null` → enabled (conformant services may
  omit the flag; keeps the DMTF mockup + OpenBMC fixtures working), explicit
  `false` → disabled. Conservative "nothing is assumed" direction.
- No new corpus downloads this run — schema citations verified live
  (`UpdateService.v1_13_0.json` 200 OK) and the corpus already mirrors the
  bmcweb field list; DOCS-6 budget respected (0 bytes).

**Next:**
- Push 11+1 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod, safe logout URI, session reuse/expiry) —
  unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag; or #008/#020:
  bmcweb HTTP-push firmware upload path (emulator asserts HttpPushUri).

**Issues touched:**
- none opened/closed this run (DOCS-5 + UI-3 increment; no issue status change).

## 2026-10-22 — agent:redfish-automation — EMULATOR run (suite +3, UI-3 KVM breakpoints)

**Done:**
- EMULATOR primary: re-verified the pinned DMTF Redfish-Mockup-Server suite
  end-to-end (16/16 over HTTPS, trap cleanup, no stray process) and extended
  the suite with three tests:
  1. `service root advertises a discoverable SessionService URI (#017)` —
     asserts `SessionService.@odata.id` at the service root and that the
     discovered URI serves a conformant SessionService (ServiceEnabled +
     Sessions). This is the exact contract #017 needs (the client currently
     hardcodes `/redfish/v1/SessionService/Sessions`).
  2. `managers: Manager exposes console capabilities + reset allow-list
     (DOCS-4 / #022)` — Manager collection enumerates `BMC`;
     `GraphicalConsole.ServiceEnabled=true` + `ConnectTypesSupported` KVMIP
     (the `FeatureRules.oemHasConsole`/`KvmConsole.fromManager` source);
     `#Manager.Reset` carries its own `ResetType@Redfish.AllowableValues`
     (`ForceRestart`, `GracefulRestart`) — the #022/#016 allow-list fallback
     must not conflate manager- vs system-level Reset actions.
  3. `chassis: Chassis exposes inventory + thermal/power sub-resources` —
     `Chassis/1U` ChassisType RackMount, SerialNumber 437XR1138R2, PowerState
     On, Status Enabled/OK, the `Thermal`/`Power` `@odata.id` links (sensor
     discovery source chain), and `Links.ComputerSystems[0]` back to the
     system.
- UI-3: KvmView no-overflow tests at 320/800/1300 px added to
  `kvm_widget_test.dart` (+3; two console cards, graphical + serial; no
  production change — view already wraps; regression protection added).
  Power/Sensors/Firmware/KVM done; dashboard/overview is the only UI-3 view
  remaining.
- REQUIREMENTS.md "Test platforms" note updated: emulator suite 13 → 16 tests,
  new coverage listed.

**Decisions:**
- No production code change this run — the emulator additions are pure
  contract-verification tests (matching the suite's existing style).
- Kept the diff focused again: repo-wide `dart format` churns 44 files and
  reintroduces the known `curly_braces` lint in `kvm_view.dart`; reverted the
  format-only churn and formatted only the touched files (prior-run precedent;
  repo-wide format remains FUTUREWORK P2).

**Next:**
- Push 13+1 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod, safe logout URI, session reuse/expiry) —
  unit-level with the in-process mock server (emulator now asserts the
  SessionService URI is discoverable — #017 contract).
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag (emulator now
  documents manager- vs system-level Reset allow-list sources); or #008/#020:
  bmcweb HTTP-push firmware upload path.

**Issues touched:**
- none opened/closed this run (EMULATOR extension + UI-3 increment; no issue
  status change). #017/#022/#015 got emulator-level contract notes.

## 2026-10-22 — agent:redfish-automation — DOCS-2 schema refresh + UI-3 completion

**Done:**
- DOCS-2 primary: refreshed six versioned DMTF schemas to current upstream after
  a live schema-index audit (`https://redfish.dmtf.org/schemas/v1/`, 14,259
  entries). New versions: `ComputerSystem.v1_29_0` (GraphicalConsole one-time
  password/URL actions, ProductionDate, ConsoleAccessMode),
  `Chassis.v1_29_0` (ProductionDate, OpenRack/OpenRackWide ChassisType),
  `Sensor.v1_14_0` (ReadingType Turbidity/LiquidConductivity/pH, Oem),
  `AccountService.v1_19_0` (KerberosKeytabSet/PasswordSet/TokenSet, LDAP
  STARTTLS note), `EthernetInterface.v1_12_6` (SLAAC wording),
  `SoftwareInventory.v1_15_0` (ImageState enum + target-state links). All six
  mirrored into `test/fixtures/redfish/schemas/` and
  `documentations/external/redfish/schemas/v1/`; hashes + bytes + deltas
  recorded in the external README "DOCS-2 refresh" table. 619,774 bytes of new
  downloads (within DOCS-6 budget).
- Audit result: **no client code change required** — every delta is additive
  (new fields/enums the client doesn't parse; `ReadingType` is stored as a
  generic string; ChassisType as free string). REQUIREMENTS.md gained a
  "DOCS-2 — versioned-schema refresh audit" trace table; the reference README
  versioned-file list was updated; superseded versioned files retained.
- Mockup payload verified current: `DMTF/Redfish-Mockup-Server` HEAD still
  `23d21f9a` (the pinned commit), so no fixture mockup refresh was needed.
- UI-3 **completed**: added 320/800/1300 px no-overflow tests for the last two
  views (DashboardView +3, OverviewView +3). The new tests caught and the fixes
  resolved two genuine responsive bugs:
  1. `DashboardView` overflowed 28 px vertically at 320 px — the single-column
     grid tile (1.6 ratio → 180 px tall) was too short for `SystemCard`;
     now uses ratio 1.25 for the 1-column layout (committed in
     `lib/features/systems/views/dashboard_view.dart`).
  2. `OverviewView` overflowed 48 px at 320 px — `GridView.count`'s fixed-ratio
     288 px square cell squeezed the tall Identity card; single-column now
     stacks natural-height cards with 12 px gaps (loading skeleton + data grid
     both; `lib/features/overview/views/overview_view.dart`).
- Emulator re-run green (16/16) after the fixture change.

**Decisions:**
- Kept superseded versioned schema files (`v1_28_0`, `v1_13_0`, `v1_18_1`,
  `v1_12_5`, `v1_14_0`) in both mirrors so any historical reference/doc
  pointing at a specific version stays valid; the aggregator is self-contained
  so nothing depends on the filename.
- No production schema-related code change: verified each delta against the
  client's parse paths first (grep across `lib/`) before concluding "no change".
- Responsive fixes chosen to preserve existing 2/3-column grid behaviour: only
  the single-column layout diverges (natural-height stack / taller tile).

**Next:**
- Push 15+1 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod, safe logout URI, session reuse/expiry) —
  unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020:
  bmcweb HTTP-push firmware upload path (emulator asserts HttpPushUri).

**Issues touched:**
- none opened/closed this run (DOCS-2 refresh + UI-3 completion; no issue status
  change).

## 2026-10-22 — agent:redfish-automation — EMULATOR run (suite +5 session/task/event contracts, UI-1 firmware retry)

**Done:**
- EMULATOR primary: extended the pinned DMTF Redfish-Mockup-Server suite
  **16 → 21 tests** with contract tests that de-risk the queued issues:
  1. Session lifecycle (#015/#017): create via the *discovered* Sessions URI
     returns 204 + `X-Auth-Token` + `Location`; the `Location` names the
     session resource (never the collection) and the created session is
     readable (200).
  2. Logout target (#015): DELETE the session resource → 204; DELETE the
     Sessions *collection* → normalized **405** non-retryable `RedfishException`
     — the #015 fallback bug would have deleted every session on the BMC.
  3. SessionTimeout (#015): `SessionService.SessionTimeout`=30 published as a
     positive int — the input for `Session.expiresAt` / proactive re-auth.
  4. TaskService (#008/#020/#022): advertised from the discovery root, enabled,
     Tasks collection enumerable — the task-URI source for long-running ops.
  5. EventService (DOCS-7 / #019): enabled, `Subscriptions` +
     `#EventService.SubmitTestEvent` contract documented as the future
     receiver's test bed.
- UI (UI-1): FirmwareView error state upgraded from a plain red `Text` to an
  `errorContainer` card with icon + message + **Retry** button that re-runs
  `FirmwareController.load()` (disabled while loading). New widget test drives
  a transient failure (flaky service: first fetch throws, second succeeds):
  error + Retry shown → tap → reload succeeds → error cleared, inventory
  visible. No new dependencies; capability gate unchanged.

**Decisions:**
- Followed the DOCS/EMULATOR alternation: EMULATOR ran less recently than DOCS
  today (DOCS 5×, EMULATOR 4× with this run). No production logic change in
  the emulator tests — pure contract pins.
- The collection-DELETE assertion also verifies the client normalizes the
  mockup's abrupt-close 405 deterministically (`statusCode: 405`), which the
  raw-curl probe earlier showed can surface as an EOF.
- Kept the diff focused: formatted only the 3 touched files (repo-wide
  `dart format` churns 44 files and reintroduces the known `curly_braces`
  lint — prior-run precedent; repo-wide format remains FUTUREWORK P2).

**Next:**
- Push 17 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, session
  rehydrate, SessionTimeout expiry) — emulator contract now pinned; implement
  unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag; #008/#020:
  bmcweb HTTP-push firmware upload path (emulator asserts HttpPushUri + Tasks).

**Issues touched:**
- none opened/closed this run (EMULATOR extension + UI-1 increment; no issue
  status change). #015/#017/#008/#020/#022/#019 got emulator-level contract
  notes.

## 2026-10-22 — agent:redfish-automation — DOCS-8 upstream-freshness audit + UI-1 dashboard error summary

**Done:**
- DOCS-8 primary: re-verified every mirrored upstream anchor against live
  sources. (1) All 13 tracked schema families match the current DMTF index
  (`https://redfish.dmtf.org/schemas/v1/`, 14,259 entries) — no version advanced
  since the DOCS-2 refresh. (2) DSP0266 1.25.0 remains the latest published PDF
  (1.26.0 probe → 404). (3) `DMTF/Redfish-Mockup-Server` HEAD still `23d21f9a`
  (= the pinned commit). (4) bmcweb master moved `0128851e` → `27e0930b` (+3
  commits: http/parsing, update_service.hpp, time_utils; no `docs/` files
  changed) — the three mirrored docs are byte-identical; manifest pins updated.
  (5) Mirrored new `docs/CLIENTS.md` (2,695 B): official bmcweb
  client-compatibility doc listing DMTF Redfish-Service-Validator /
  Protocol-Validator, python-redfish-library, Redfish-Tacklebox, redfishtool,
  fwupd, Redfish-Event-Listener — a useful reference for future integration
  test beds. (6) Decision recorded (README + REQUIREMENTS): bmcweb
  `COMMON_ERRORS.md` and `HEADERS.md` are C++ contributor docs with no
  client-facing Redfish contract — not mirrored.
- REQUIREMENTS.md gained a "DOCS-8 — upstream-freshness audit" section and the
  source header pin was updated; external README "Current upstream anchors" +
  manifest updated with the new pin and the CLIENTS.md row (SHA-256, bytes).
  New downloads 2,695 bytes — inside the DOCS-6 budget.
- UI-1 completed (last open view): DashboardView now shows an error summary
  card (errorContainer + icon + count message + one-tap Retry) when any system
  is in `ConnectionStatus.error`. Backed by a new `SystemManager.retryFailed()`
  that re-connects only error-state systems (disconnected/connecting untouched).
  New widget tests drive both the persistent-failure and transient-failure
  retry paths (+3 dashboard), plus a manager unit test for `retryFailed`
  isolation (+1). Error-card pattern matches the FirmwareView one from the
  20:51 run.

**Decisions:**
- Labeled the freshness audit **DOCS-8** (not DOCS-6) to avoid a naming
  collision with the existing FUTUREWORK DOCS-6 "keep the corpus bounded"
  policy item, which remains open.
- Kept the mirrored bmcweb files at the new pin without re-downloading content:
  the bytes are identical, so the corpus is current with only provenance
  changes.
- Did not mirror bmcweb C++ contributor docs (COMMON_ERRORS/HEADERS) — they are
  internal, not client-facing; noted so future audits skip them.
- Formatted only the 4 touched Dart files; no repo-wide `dart format` churn
  (prior-run precedent: it reintroduces the known `curly_braces` lint).

**Next:**
- Push 20 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — emulator section contract pinned (create →
  X-Auth-Token+Location, DELETE session resource, 405 collection,
  SessionTimeout=30); implement unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020:
  bmcweb HTTP-push firmware upload path (emulator asserts HttpPushUri + Tasks).

**Issues touched:**
- none opened/closed this run (DOCS-8 audit + UI-1 completion; no issue status
  change). UI-1 FUTUREWORK item checked off; UI-1 fully done.

## 2026-10-23 — agent:redfish-automation — EMULATOR run (suite 21→24, push apply-time parse, UI-2 firmware card semantics)

**Done:**
- EMULATOR primary: extended the pinned DMTF Redfish-Mockup-Server suite
  **21 → 24 tests** with three contract pins that de-risk queued issues:
  1. `ProtocolFeaturesSupported` (#018): the service root advertises
     `ExcerptQuery: true` and `ExpandQuery{ExpandAll:true, Levels:true}` and
     publishes `FilterQuery`/`SelectQuery` booleans — the query-capability
     surface a lightweight discovery pass must use (the client currently
     ignores it; documented gap for the discovery-cache rework).
  2. AccountService / Accounts (#015/#026): the Accounts collection is
     discoverable from the service and every member resolves with
     `UserName`/`RoleId`; `MinPasswordLength` published — the auth-surface
     contract #015/#026 reason about.
  3. UpdateService `HttpPushUriOptions` (#008/#020): the mockup publishes
     `HttpPushUriApplyTime.ApplyTime == 'Immediate'` +
     `ApplyTime@Redfish.AllowableValues` (Immediate/OnReset/
     AtMaintenanceWindowStart/InMaintenanceWindowOnReset) +
     `MaintenanceWindowStartTime` — the apply-time selection a push-upload
     flow must offer instead of assuming Immediate.
- Code increment: `UpdateServiceInfo` now parses
  `HttpPushUriOptions.HttpPushUriApplyTime` into `httpPushApplyTime` (current
  mode) + `httpPushApplyTimes` (AllowableValues); `copyWithInventory`
  preserves both. Additive fields only — no public behaviour change. Unit
  tests +2 (DMTF fixture parse + absent-options fallback).
- UI (UI-2): each firmware inventory card wrapped in
  `Semantics(container: true, label: ...)` announcing a concise merged summary
  (component, version, health, updateable/locked) as one unit. New widget test
  asserts `find.bySemanticsLabel('Firmware BMC Firmware, 3.2.1, OK,
  updateable')`. No new dependencies.

**Decisions:**
- Followed the DOCS/EMULATOR alternation (last run DOCS — EMULATOR next).
- Kept emulator pins to contracts the mockup *actually* serves: probed live
  with `curl -k` before writing assertions. Noted that the mockup serves no
  `@odata.etag` on resources — #016 etag behaviour stays in unit tests, can't
  be pinned on this fixture (recorded in FUTUREWORK #016 note).
- Formatted only the 5 touched files; no repo-wide `dart format` (prior-run
  precedent: it reintroduces the known `curly_braces` lint — this run it
  churned 35 files and surfaced exactly that; all restored via `git checkout`).
- Emulator server stopped via exact-PID kill after the run — no stray process.

**Next:**
- Push 22 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — emulator pins session lifecycle + AccountService
  surface; implement unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020:
  bmcweb HTTP-push firmware upload (emulator asserts HttpPushUri +
  HttpPushUriOptions apply-time modes + Tasks).

**Issues touched:**
- none opened/closed this run (EMULATOR extension + model increment + UI-2
  label; no issue status change). #015/#016/#018/#020/#026 got emulator-level
  contract notes in FUTUREWORK.

## 2026-10-23 — agent:redfish-automation — DOCS-9 freshness re-check + MultipartHttpPushUri + UI-2 sensor-tile semantics

**Done:**
- DOCS-9 primary: re-verified every mirrored upstream anchor against live
  sources (~6h after DOCS-8). bmcweb master still `27e0930b` (git ls-remote),
  DMTF Redfish-Mockup-Server still `23d21f9a`, DSP0266 1.25.0 still the latest
  published PDF (1.26.0 → 404), and a fresh 3.4 MB schema-index fetch shows no
  version advanced for the 13 tracked families (current versions present,
  next-higher versions absent). Zero new downloads — DOCS-6 budget untouched.
- Docs-driven code fix: bmcweb `Redfish.md` §UpdateService lists
  `MultipartHttpPushUri` beside `HttpPushUri`, and `UpdateService.v1_17_1.json`
  defines it (`versionAdded v1_6_0`, URI for the Redfish-defined multipart
  HTTP/S push POST). `UpdateServiceInfo` now parses it into
  `multipartHttpPushUri` (with `fromJson` + `copyWithInventory`), so both push
  URIs a firmware-upload flow needs are surfaced — the #008/#020 upload path
  still needs building, but the bmcweb-specific multipart endpoint is no longer
  invisible. REQUIREMENTS.md row upgraded GAP → Partial; +3 unit tests
  (multipart parse, absent fallback against the DMTF mockup fixture,
  copyWithInventory preserves).
- UI (UI-2): each sensor tile (temperature/fan/generic) now renders inside a
  `Semantics(container: true, excludeSemantics: true, label: ...)` announcing
  one concise summary — `Temperature CPU1 Temp, 41.0°C, Unknown`. Reused the
  firmware-card label pattern; `excludeSemantics: true` is required because the
  ListTile's internal MergeSemantics would otherwise append the raw tile text to
  the label. Widget test asserts all three merged labels; fixture gained a fan
  + generic sensor row. No new dependencies; UI-2 remains open.

**Decisions:**
- DOCS next in the DOCS/EMULATOR alternation (last run EMULATOR).
- No emulator-driven code change this run, but the emulator suite (24 tests)
  was re-run as a safety check after the firmware-model change — all green,
  server trap-stopped.
- Kept the label wording consistent with the dashboard HealthBanner
  (`OK`/`Warning`/`Critical`/`Unknown`) rather than enum `.name` lowercase.
- Formatted only the 4 touched Dart files; no repo-wide `dart format` (prior-run
  precedent: it reintroduces the known `curly_braces` lint).

**Next:**
- Push 23 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — emulator pins session lifecycle + AccountService
  surface; implement unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback + PATCH/etag, or #008/#020:
  bmcweb HTTP-push firmware upload (both push URIs + HttpPushUriOptions
  apply-time modes + Tasks now surfaced).

**Issues touched:**
- none opened/closed this run (DOCS-9 audit + model increment + UI-2 labels; no
  issue status change). #008/#020 got a note that `multipartHttpPushUri` is now
  surfaced; UI-2 noted the sensors-tile labels in FUTUREWORK.

## 2026-10-23 — agent:redfish-automation — EMULATOR run (suite 24→27, three contract pins, UI-2 chassis header semantics)

**Done:**
- EMULATOR primary: extended the pinned DMTF Redfish-Mockup-Server suite
  **24 → 27 tests** with three contract pins that de-risk queued issues:
  1. Sensors collection end-to-end (#007/#019): the 41-member
     `/Chassis/1U/Sensors` collection enumerates through the client's
     `SensorsService.fetchAll()` and `SensorReading` parses typed readings —
     CPU1Temp (`ReadingUnits Cel`, `Reading 37.0`, `UpperCritical` 45.0) and
     PS1InputVoltage (`ReadingType Voltage`, `V`, 119.27) with thresholds.
  2. System-level Reset allow-list (#022/#016): `#ComputerSystem.Reset`
     `ResetType@Redfish.AllowableValues` = On/ForceOff/GracefulShutdown/
     GracefulRestart/ForceRestart/Nmi/ForceOn/PushPowerButton — includes
     `Nmi` (NMI-stabilize) and is distinct from the manager-level list
     (ForceRestart + GracefulRestart); `PowerCycle` is NOT advertised so the
     gate must use exactly the published values.
  3. `SimpleUpdateActionInfo` (#008/#020): `#ActionInfo.v1_4_1` with
     `ImageURI` (Required true) + `TransferProtocol` AllowableValues
     (HTTP/HTTPS/SFTP …) — the parameter contract for `startSimpleUpdate`
     on BMCs that do expose SimpleUpdate.
- UI (UI-2): Sensors chassis card header now announces one merged summary
  (`Chassis 1U, 1 temperatures, 1 fans, 1 sensors`) via
  `Semantics(container: true, excludeSemantics: true, label: ...)` on the
  title; per-tile labels preserved. New widget test asserts the label.

**Decisions:**
- Followed the DOCS/EMULATOR alternation (last run DOCS — EMULATOR next).
- Test-only pins: the client already parsed the Sensors collection and the
  Reset allow-list surfaces, so no production code changed — the pins lock the
  contracts for #007/#019/#022/#016/#008/#020 work to come.
- Probed every contract live with `curl -k` before pinning (sensors, reset
  allow-list, action info); no silent skipping.
- Formatted only the 3 touched Dart files; no repo-wide `dart format`
  (prior-run precedent: it reintroduces the known `curly_braces` lint).
- Emulator server killed via exact-PID after the run — no stray process, port
  8443 free.

**Next:**
- Push 25 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — emulator pins session lifecycle + AccountService
  surface; implement unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback (emulator now pins the
  system-level `ResetType@Redfish.AllowableValues` incl. `Nmi`) + PATCH/etag,
  or #008/#020: bmcweb HTTP-push firmware upload (both push URIs +
  `HttpPushUriOptions` apply-time modes + SimpleUpdateActionInfo contract).

**Issues touched:**
- none opened/closed this run (EMULATOR contract pins + UI-2 label; no issue
  status change). #007/#008/#016/#019/#020/#022 got emulator-level contract
  notes in FUTUREWORK.

## 2026-10-23 — agent:redfish-automation — REPAIR run (recovered crashed DOCS-10 WIP)

**Done:**
- Recovered a crashed DOCS-10 run from the working tree instead of discarding
  it: the WIP (Task schema corpus + `UpdateTask` Retry-After + banner semantics)
  was sound but red — a leftover scratch probe
  (`test/features/firmware/sem_probe_test.dart`, no assertions, broken
  `SemanticsNode` import) caused 4 analyze errors and 3 tests failed.
- Fixed: removed the scratch probe (real coverage already in
  `firmware_widget_test.dart`); `_retryAfterSeconds` no longer checks
  `date != null` after a successful `HttpDate.parse`; added the JSON
  content-type header to the DioAdapter 202 reply (mirrors `auth_manager_test`
  `_jsonContentType` — headers override drops the default encode type, causing
  the transport cast error); added `excludeSemantics: true` to the queued-banner
  `Semantics` (the documented UI-2 pattern — the child Text otherwise merges
  into the label).
- Landed DOCS-10: `Task.json` + `Task.v1_7_4.json` + `TaskService.v1_2_1.json`
  mirrored (SHA-256 verified against the manifest); DSP0266 §12.2 audit table in
  REQUIREMENTS.md; `UpdateTask.retryAfterSeconds` from the 202 `Retry-After`
  header (seconds or HTTP-date, clamped ≥ 0); `startSimpleUpdate` returns an
  `UpdateTask` handle; `FirmwareUiState.lastTask` replaces `lastTaskUri`;
  queued-update banner shows the URI + `retry after Ns` with one merged
  semantics label (UI-2).
- Tests: `firmware_model_test.dart` +2, `firmware_service_test.dart` +2,
  `firmware_widget_test.dart` +2. Full suite green: analyze 0, 284 passed /
  1 skipped; emulator 27/27 (safety re-run after the model change).

**Decisions:**
- Crashed-WIP recovery beats stashing: the WIP was clearly the previous
  automation's DOCS-10 work, ~95% complete; the failures were 2 small code bugs
  + 1 scratch file — cheaper and better to finish than to stash and redo.
- Kept the crashed run's docs provenance (manifest rows + sha256 + DOCS-10
  section) after verifying the hashes match the downloaded files.
- Deleted the untracked scratch probe `sem_probe_test.dart` (automation debris,
  not user work; superseded by the widget tests it was probing for).
- Formatted only the touched Dart files — no repo-wide `dart format` (prior-run
  precedent: reintroduces the `curly_braces` lint).

**Next:**
- Push 28 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — emulator pins session lifecycle + AccountService;
  implement unit-level with the in-process mock server.
- #008/#020: bmcweb HTTP-push firmware upload — `UpdateTask` now carries the
  task-monitor URI + `Retry-After`, so build the poller (GET-on-monitor,
  `TaskState` 13 values, `PercentComplete`) and the push path
  (`HttpPushUri`/`MultipartHttpPushUri` apply-time selection).
- #016/#022: `ResetActionInfo` allow-list fallback (system-level, incl. `Nmi`)
  + PATCH/etag.

**Issues touched:**
- none opened/closed this run (REPAIR of crashed DOCS-10 WIP; no issue status
  change). #008/#020 got a note that `UpdateTask` now carries the task-monitor
  URI + retry-after; DOCS-10 marked done in FUTUREWORK.

## 2026-10-23 — agent:redfish-automation — EMULATOR run (#006 overview hydration + LogService/LogEntry)

**Done:**
- EMULATOR suite 27 → 30 tests against the pinned DMTF Redfish-Mockup-Server
  (`23d21f9a`, HTTPS): (1) **OverviewService end-to-end hydration pin (#006)** —
  the production hydration path now resolves the full SystemOverview from the
  live mockup: Contoso/3500/437XR1138R2 identity, SKU/PartNumber, BiosVersion,
  PowerState on, Health ok + rollup, ProcessorSummary Count 2 (Xeon), 96 GiB
  MemorySummary, IndicatorLed off, leading 41.0 °C from the chassis Thermal
  chain, resourceUri; (2) **LogService + LogEntry contract** — LogServices
  collection → Log1 (ServiceEnabled, WrapsWhenFull, ClearLog action target) →
  Entries with `LogEntry.v1_16_0` fields (EntryType SEL, Severity, Created,
  Message, OriginOfCondition) and the `@odata.nextLink` pagination marker
  (`$skiptoken=2`); (3) REQUESTS.md emulator note rewritten 16 → 30 tests
  (was stale from EMU-2).
- UI-2 increment: `InfoCard` header (icon + title) announces as one merged
  semantics node (`Semantics(container: true, excludeSemantics: true, label:
  title)`), matching the chassis/sensor/firmware card pattern; 5 new widget
  assertions via `find.bySemanticsLabel`.
- Docs: no new downloads (DOCS-6 budget untouched); REQUIREMENTS.md + overview
  requirement row (#006) + LogService/LogEntry contract row.

**Decisions:**
- Kept this run test-only for the service layer (OverviewService already worked;
  the value is pinning its real-world contract, not changing it).
- Reverted repo-wide `dart format` churn (31 files) — it reintroduced the
  `curly_braces_in_flow_control_structures` lint (same precedent as prior
  runs). Only the 3 touched Dart files were formatted.
- LogService is pinned as a contract only; no log feature is queued in
  FUTUREWORK — recorded explicitly so a future run doesn't re-derive the shape.

**Next:**
- Push 30 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — implement unit-level with the in-process mock server.
- #016/#022: system-level `ResetActionInfo` allow-list fallback (incl. `Nmi`)
  + PATCH/etag; or #008/#020 bmcweb HTTP-push firmware upload (both push URIs,
  apply-time modes, UpdateTask poller GET-on-monitor + TaskState parsing).

**Issues touched:**
- none opened/closed this run (emulator contract pins + UI-2 label; no issue
  status change). #006 got an emulator-level contract note in FUTUREWORK;
  #008/#020/#022 have the LogEntry collection contract pinned for the task
  timeline.
## 2026-10-23 — agent:redfish-automation — DOCS-11 (LogEntry corpus) + UI-2 SystemCard

**Done:**
- DOCS-11 — closed a corpus gap: the external mirror had **no `LogEntry` schema**
  despite REQUIREMENTS.md + the emulator suite referencing `LogEntry`
  (`LogEntry.v1_16_0` shapes pinned by the mockup). Mirrored official DMTF files
  (171,095 bytes, DOCS-6 budget untouched): `LogEntry.json` aggregator,
  `LogEntry.v1_22_0.json` (newest — EntryType 11 values, CPER, ResolutionSteps,
  OriginAddress), `LogEntry.v1_16_0.json` (mockup-pinned version),
  `LogEntryCollection.json` (`@odata.nextLink` pagination), `LogService.v1_9_0.json`
  (newest versioned LogService). Mirrored LogEntry aggregator/v1_16_0/collection
  into `test/fixtures/redfish/schemas/` too. SHA-256s verified, manifest rows +
  DOCS-11 section in README.md, REQUIREMENTS.md log row now cites real files,
  `documentations/redfish_reference/` README + log_service.md updated.
- Corrected a speculative DSP0266 §8.19 citation to the real spec references
  (§9.6.11 `Members`, §9.6.12 `Members@odata.nextLink`).
- Re-verified upstream anchors: bmcweb `27e0930b`, mockup `23d21f9a`, DSP0266
  1.25.0 (1.26.0 → 404), schema index current for all other tracked families.
- UI-2 increment: `SystemCard` header now announces as one merged semantics node
  (`<name>, connected|connecting|connection error|disconnected`) using the same
  `Semantics(container: true, excludeSemantics: true, label: ...)` pattern as
  the firmware/sensor/chassis/InfoCard headers; the PopupMenuButton stays
  outside the merge. New widget test covers all four connection states.

**Decisions:**
- DOCS workstream selected per alternation (last run was EMULATOR 06:10).
- Kept the LogEntry mirror in BOTH the external corpus and the fixture schemas
  dir (DOCS-2 precedent — fixture + corpus stay consistent).
- Only the two touched Dart files formatted (no repo-wide `dart format` —
  prior-run precedent: reintroduces the known `curly_braces` lint).

**Next:**
- Push 32 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — implement unit-level with the in-process mock server.
- #016/#022: `ResetActionInfo` allow-list fallback (system-level, incl. `Nmi`)
  + PATCH/etag, or #008/#020: bmcweb HTTP-push firmware upload (both push URIs,
  apply-time modes, UpdateTask poller GET-on-monitor + TaskState parsing; the
  LogEntry collection contract is now fully mirrored for the task timeline).

**Issues touched:**
- none opened/closed this run (DOCS corpus + UI-2 label; no issue status
  change). The LogEntry contract remains a contract pin only — no log feature
  is queued; recorded so a future run doesn't re-derive the shape.
## 2026-10-23 — agent:redfish-automation — EMULATOR (Task resource pin) + UI-2 KvmConsole header

**Done:**
- EMULATOR suite 30 → 32 tests against the pinned DMTF Redfish-Mockup-Server
  (`23d21f9a`, HTTPS): (1) **Task resource contract pin (#008/#020/#022)** —
  the mockup's only Task (545, `Task.v1_7_3`) publishes `TaskState Completed`,
  `TaskStatus OK`, RFC3339 `StartTime`/`EndTime`, and `Messages[]`
  (`MessageId` `Base.*`, `Message`, `MessageArgs[]`, `Severity`) — and
  **no `PercentComplete`**. The future #008/#020 poller's parse surface is now
  pinned end-to-end: TaskState 13-value parse, optional/absent PercentComplete
  must be treated as unknown, Messages timeline. (2) **TaskService surface** —
  `CompletedTaskOverWritePolicy=Manual`, `LifeCycleEventOnTaskStateChange=true`
  pinned. (3) REQUIREMENTS.md emulator note 30 → 32 tests + DOCS-10 rows now
  cite the live-mockup pin.
- UI-2 increment: `KvmConsole` card header (title + Enabled/Disabled chip)
  announces as one merged semantics node (`<type>, enabled|disabled`), the same
  pattern as SystemCard/InfoCard/chassis/sensor/firmware headers; 2 new widget
  tests (enabled + disabled). Fixed the `dart format`-reintroduced
  `curly_braces` lint in `kvm_view.dart` (known prior-run precedent).
- Docs: no new downloads (DOCS-6 budget untouched); REQUIREMENTS.md updated.

**Decisions:**
- Kept this run test-only for the service layer — the Task contract is for the
  TO-BUILD poller (#008/#020); pinning the exact live payload first (incl. the
  absent-PercentComplete edge) is the spec-conformant way to build the parser.
- Split the KVM semantics widget test into two testWidgets (enabled/disabled)
  after learning a second `ProviderScope` pump at the same tree position reuses
  the first container — the established single-pump-per-test pattern.
- Only the 3 touched Dart files formatted (no repo-wide `dart format` —
  prior-run precedent: reintroduces the known `curly_braces` lint).

**Next:**
- Push 34 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry) — implement unit-level with the in-process mock server.
- #008/#020: build the task poller — GET-on-monitor, `TaskState` 13-value
  parse, `PercentComplete` optional/absent handling, `Messages[]` task
  timeline; then the bmcweb HTTP-push firmware upload path (both push URIs,
  apply-time modes; `SimpleUpdateActionInfo` + Task contract already pinned).

**Issues touched:**
- none opened/closed this run (emulator contract pin + UI-2 label; no issue
  status change). #008/#020 got the Task resource contract pin recorded in
  FUTUREWORK — the poller's parse surface is now fully pinned.
## 2026-10-23 — agent:redfish-automation — DOCS-12 (six-family versioned mirror) + UI-2 PowerView header

**Done:**
- DOCS-12 — closed the last "aggregator-only" corpus gap. `UpdateService`,
  `EventService`, `SessionService`, `Manager`, `Power`, `Thermal` had no
  versioned definitions in `documentations/external/redfish/schemas/v1/` even
  though the client maps all six and the fixture snapshot already ships the
  newest versions. Mirrored newest + mockup-served per family (12 files,
  553,772 bytes, DOCS-6 budget OK): `UpdateService.v1_17_1`+`v1_13_0`,
  `EventService.v1_12_0`+`v1_10_1`, `SessionService.v1_2_0`+`v1_1_8`,
  `Manager.v1_25_0`+`v1_19_0`, `Power.v1_7_3`+`v1_7_2`, `Thermal.v1_7_3`+
  `v1_7_2`. Manifest rows + SHA-256s + README DOCS-12 section;
  REQUIREMENTS.md rows/trace-note now cite the real mirrored files, plus a
  DOCS-12 audit table of newest-vs-served property deltas. Copied the six
  mockup-served versions into `test/fixtures/redfish/schemas/` so every
  `@odata.type` the pinned mockup publishes has a versioned schema in the
  fixture; the six newest versions were already there and verified
  byte-identical to upstream. `documentations/redfish_reference/README.md`
  note added.
- Audited deltas (no client code change): `SessionService.v1_2_0` adds
  `AbsoluteSessionTimeout`/`AbsoluteSessionTimeoutEnabled` (note for #015);
  `UpdateService.v1_17_1` adds `LocalImageStore*`, `Stage`/`Activate` actions,
  `UpdateServiceCapabilities` (upstream context for #008/#020); `Manager
  v1_25_0` adds `SecurityMode`/`ReadyToRemove`/`DateTimeSource`; Power/Thermal
  v1_7_3 have no property deltas vs v1_7_2.
- UI-2 increment: `PowerView` card header now announces as ONE merged
  semantics node (`<name>, power <state>`) via
  `Semantics(container: true, excludeSemantics: true, label: ...)` on the
  title+PowerBadge row — the pattern already used by SystemCard/InfoCard/
  chassis/sensor/firmware/KVM headers; reset buttons stay sibling semantics.
  New widget test asserts the merged label ("A, power Off").
- Upstream anchors re-verified this run: bmcweb `27e0930b`, mockup `23d21f9a`,
  DSP0266 1.25.0, live schema index (all 12 URLs 200 OK pre-download).

**Decisions:**
- DOCS workstream selected per alternation (last run EMULATOR 09:14).
- Followed the DOCS-11 LogEntry precedent: mirror BOTH the newest versioned
  file and the mockup-served version — newest for spec citations, mockup-served
  for emulator provenance — and keep fixture + external corpus consistent.
- Copied only the mockup-served (older) versions into fixtures; the newest
  versions were already present and byte-identical, so no overwrite.
- Only the 2 touched Dart files formatted (no repo-wide `dart format` —
  prior-run precedent: reintroduces the known `curly_braces` lint).

**Next:**
- Push 37 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry — now also `AbsoluteSessionTimeout*` per
  `SessionService.v1_2_0.json` DOCS-12) — unit-level with the in-process mock
  server.
- #008/#020: build the task poller — GET-on-monitor, `TaskState` 13-value
  parse, `PercentComplete` optional/absent handling, `Messages[]` timeline;
  plus the bmcweb HTTP-push firmware upload path (both push URIs, apply-time
  modes; `SimpleUpdateActionInfo` + Task contract + `UpdateService.v1_17_1`
  LocalImageStore/Stage/Activate context all available).

**Issues touched:**
- none opened/closed this run (DOCS corpus + UI-2 label; no issue status
  change). #015/#008/#020 got DOCS-12 schema-provenance notes in FUTUREWORK.
## 2026-10-23 — agent:redfish-automation — EMULATOR (Manager network pin) + UI-2 HealthBanner

**Done:**
- EMULATOR suite 32 → 34 tests against the pinned DMTF Redfish-Mockup-Server
  (`23d21f9a`, HTTPS): (1) **Manager NetworkProtocol contract (#009/#021)** —
  `GET /redfish/v1/Managers/BMC/NetworkProtocol` publishes
  `#ManagerNetworkProtocol.` with HostName/FQDN and the endpoint table:
  `KVMIP` (ProtocolEnabled + port 5288 — the KVM-over-IP service a console
  renderer resolves), `HTTPS` (443) and `SSH` (22). (2) **EthernetInterfaces
  contract** — `Managers/BMC/EthernetInterfaces/{eth0}` enumerates
  InterfaceEnabled, MACAddress, SpeedMbps, MTUSize, IPv4Addresses
  (Address/SubnetMask/AddressOrigin/Gateway) and VLAN (VLANEnable/VLANId).
  Test-only raw-getJson pins (09:14 Task-contract precedent); the client must
  resolve the console endpoint from the advertised KVMIP port, never hardcode
  ports. REQUIREMENTS.md test-platform note 32 → 34 tests.
- UI-2 increment: `OverviewView` `HealthBanner` (icon + label row) now
  announces as ONE merged semantics node — `Semantics(container: true,
  excludeSemantics: true, label: 'Health: <state>')` — the same pattern as the
  InfoCard/SystemCard/KVM/PowerView headers; the visible "Healthy" text remains
  for sighted users. New widget test asserts the merged node ("Health:
  Healthy") + visible text; all existing OverviewView tests still green.
- No production service-code change; no new dependencies; no issue status
  change. Formatted only the 3 touched Dart files (prior-run precedent: no
  repo-wide `dart format` — reintroduces the known `curly_braces` lint).

**Decisions:**
- EMULATOR selected per alternation (last run DOCS 10:34).
- Followed the established test-only pin precedent: pin the exact live payload
  shape before building the feature — the NetworkProtocol KVMIP port is the
  endpoint source the TO-BUILD #009/#021 console renderer requires.
- HealthBanner merged label includes context ("Health: ...") so the
  announcement is self-describing, matching the other card-header labels'
  concise-summary style.

**Next:**
- Push 39 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry — now also `AbsoluteSessionTimeout*` per
  `SessionService.v1_2_0.json` DOCS-12) — unit-level with the in-process mock
  server.
- #009/#021: KVM console launch — resolve the endpoint from the now-pinned
  `NetworkProtocol.KVMIP` (port 5288) + EthernetInterfaces; or #008/#020:
  build the task poller (GET-on-monitor, TaskState 13-value parse,
  PercentComplete optional/absent, Messages[] timeline) + the bmcweb HTTP-push
  firmware upload path (both push URIs, apply-time modes, SimpleUpdateActionInfo
  already asserted).

**Issues touched:**
- none opened/closed this run (emulator contract pin + UI-2 label; no issue
  status change). #009/#021 got the NetworkProtocol/EthernetInterfaces pin
  recorded in FUTUREWORK — the console renderer's endpoint surface is now
  pinned.
## 2026-10-23 — agent:redfish-automation — DOCS-13 (auth/network/ActionInfo mirror) + UI-2 FirmwareView header

**Done:**
- DOCS-13 — mirrored the versioned definitions for the six emulator-pinned /
  client-relevant resources the external corpus had no versioned defs for:
  `Session` (v1_9_0 + v1_7_1), `ManagerAccount` (v1_14_2 + v1_12_0), `Role`
  (v1_3_3 + v1_3_1), `ManagerNetworkProtocol` (v1_14_0 + v1_10_0),
  `ActionInfo` (v1_6_0 + v1_4_1), `ServiceRoot` (v1_22_0 + v1_16_1), plus the
  mockup-served `Task.v1_7_3` / `TaskService.v1_2_0` (DOCS-10 mirrored only
  the newest). 19 files, 397,572 bytes (DOCS-6 budget OK), aggregator + newest
  + mockup-served per family (DOCS-11/12 precedent). Manifest rows + SHA-256s
  in `documentations/external/README.md` (+ DOCS-13 section with
  newest-vs-served delta table); REQUIREMENTS.md DOCS-13 audit table (7 rows)
  + Last-audited + Trace-notes count 16 → 21; redfish_reference README note.
  The eight mockup-served versions copied into `test/fixtures/redfish/schemas/`
  — every `@odata.type` the mockup publishes for these families now has a
  versioned schema in the fixture.
- Upstream anchors re-verified (GitHub API + DMTF): bmcweb `27e0930b` and
  mockup `23d21f9a` unchanged; DSP0266 1.25.0 still latest; schema index 200 OK.
- Audited newest-vs-served deltas — no client code change needed this run:
  `Session.v1_9_0` (session-type/OEM expansion), `ManagerAccount.v1_14_2`
  (`PasswordExpiration`/`RemoteRole`/account-types — #015/#026 context),
  `Role.v1_3_3` (no deltas), `ManagerNetworkProtocol.v1_14_0` (NTP* +
  Kerberos*), `ActionInfo.v1_6_0` (`ActionCapabilities` +
  `AllowableValueDescriptions` — `Parameters/AllowableValues` stable for
  #022/#016), `ServiceRoot.v1_22_0` (Tasks link).
- UI-2 increment: `FirmwareView` header row (title + in-flight spinner) now
  announces as ONE merged semantics node —
  `Semantics(container: true, excludeSemantics: true, label: 'Firmware and
  update management[, loading]')` — matching the SystemCard/InfoCard/KVM/
  PowerView/HealthBanner pattern. Two new widget tests: loading-state label
  (never-completing service double) + idle label (loading suffix absent).

**Decisions:**
- DOCS workstream selected per alternation (last run EMULATOR 11:39).
- Followed the DOCS-11/12 precedent: mirror aggregator + newest + mockup-served
  per family, and copy mockup-served versions into the fixture for provenance.
- Included Task.v1_7_3/TaskService.v1_2_0 as a small provenance completion
  within the same workstream (DOCS-10 had mirrored only the newest versions).
- Only the 2 touched Dart files formatted (no repo-wide `dart format` —
  prior-run precedent: reintroduces the known `curly_braces` lint).
- Emulator suite not re-run: no emulator code touched; `schemas/` additions are
  provenance JSON only (the suite reads `dmtf_mockup`).

**Next:**
- Push 42 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout expiry — Session/ManagerAccount/Role schemas now mirrored,
  incl. `Session.v1_9_0` + `SessionService.v1_2_0` AbsoluteSessionTimeout*).
- #022/#016: add the `ResetActionInfo` (ActionInfo `Parameters/AllowableValues`)
  fallback to `FeatureRules.supportedResetTypes` — contract mirrored +
  emulator-pinned; or #008/#020 task poller (Task contract pinned end-to-end).

**Issues touched:**
- none opened/closed this run (DOCS corpus + UI-2 label; no issue status
  change). #015/#017/#026/#009/#021/#022/#016/#018 got DOCS-13 corpus
  provenance notes in FUTUREWORK.
## 2026-10-23 — agent:redfish-automation — EMULATOR (account-service auth surface) + UI-2 Dashboard banner

**Done:**
- EMULATOR suite 34 → 36 tests against the pinned DMTF Redfish-Mockup-Server
  (`23d21f9a`, HTTPS): pinned the **account-service auth surface** the #015/
  #026 work reasons about (DOCS-13 just mirrored the exact schemas the mockup
  serves — `ManagerAccount.v1_12_0`, `Role.v1_3_1`): (1) **AccountService
  contract** — `#AccountService.v1_15_0.AccountService` publishes the lockout/
  password-policy fields (`AuthFailureLoggingThreshold`,
  `AccountLockoutThreshold/Duration/CounterResetAfter/CounterResetEnabled`,
  `MinPasswordLength`, `LocalAccountAuth`, `RequireChangePasswordAction`) and
  both discoverable sub-collection links (Accounts + Roles `@odata.id`). (2)
  **Roles contract** — `AccountService/Roles` enumerates the 3 predefined
  roles (Administrator/Operator/ReadOnly) and
  `Roles/Administrator` (`#Role.v1_3_1.Role`) publishes `IsPredefined=true`,
  `AssignedPrivileges` (Login/ConfigureManager/ConfigureUsers/ConfigureSelf/
  ConfigureComponents) and `OemPrivileges` — the RoleId → privilege surface.
  (3) **ManagerAccount detail contract** —
  `Accounts/1` (`#ManagerAccount.v1_12_0.ManagerAccount`) publishes
  `Enabled`/`Locked`/`PasswordChangeRequired`, `AccountTypes` containing
  `Redfish` (#026 disambiguation), `Links.Role` → the Role resource, the
  `#ManagerAccount.ChangePassword` action target, and keeps `Password`
  masked (`null`) on the wire — the client must never read it back or log it.
  Test-only raw-getJson pins (09:14/11:39 precedent); live payloads curl-
  verified against the fixture before pinning. REQUIREMENTS.md test-platform
  note 34 → 36 tests + ManagerAccount/Role rows cite the new pins.
- UI-2 increment: `DashboardView` `_AggregatedBanner` (icon + health summary
  row) now announces as ONE merged semantics node —
  `Semantics(container: true, excludeSemantics: true, label: 'Health:
  <summary>')` — the same pattern as the SystemCard/HealthBanner/PowerView
  headers; the visible "1 OK, 1 Warning" text remains for sighted users. Two
  new widget tests: the merged node ("Health: 1 OK, 1 Warning") + visible
  text, and the "No systems" empty-state merged label.
- No production service-code change; no new dependencies; no issue status
  change. Formatted only the 3 touched Dart files (prior-run precedent: no
  repo-wide `dart format`).

**Decisions:**
- EMULATOR selected per alternation (last run DOCS 12:50).
- Chose the auth-surface pin because DOCS-13 just completed the schema corpus
  for the exact versions the mockup serves — the emulator now pins the real
  payload shapes for the same families (contract → schema provenance closes).
- Followed the established test-only pin precedent: pin the exact live payload
  shape before building the feature — #015/#026 now have their full reason-
  about surface pinned (session lifecycle + AccountService policy + Roles +
  ManagerAccount detail).
- Dashboard banner merged label includes context ("Health: ...") so the
  announcement is self-describing, matching the other card-header labels'
  concise-summary style; the empty-state label ("Health: No systems") is
  asserted too.

**Next:**
- Push 44 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry) — the full auth surface is
  pinned: session lifecycle + SessionService timeout + AccountService lockout
  policy + Roles/privileges + ManagerAccount detail (AccountTypes); implement
  unit-level with the in-process mock server.
- #022/#016: add the `ResetActionInfo` (ActionInfo `Parameters/AllowableValues`)
  fallback to `FeatureRules.supportedResetTypes` — contract mirrored +
  emulator-pinned; or #008/#020: build the task poller (GET-on-monitor,
  TaskState parse, PercentComplete optional/absent, Messages[] timeline) + the
  bmcweb HTTP-push firmware upload path.

**Issues touched:**
- none opened/closed this run (emulator contract pin + UI-2 label; no issue
  status change). #015/#026 got the full account-service auth-surface pin
  recorded in FUTUREWORK.
## 2026-10-23 — agent:redfish-automation — DOCS (reset allow-list annotation fallback) + UI-2 dialog touch targets

**Done:**
- DOCS primary workstream (alternation: last DOCS run 12:50, last EMULATOR
  13:58 — DOCS next). Closed the documented reset-allow-list gap: the DMTF
  mockup / bmcweb-style BMCs publish the reset allow-list as the
  `ResetType@Redfish.AllowableValues` annotation on `#ComputerSystem.Reset`
  (no system-level `SupportedResetTypes` — REQUIREMENTS.md rows 87/137/330
  were "Partial — add ActionInfo fallback in #022/#016"). `FeatureRules.
  supportedResetTypes` now unions `SupportedResetTypes` + the annotation, with
  a new pure helper `FeatureRules.resetTypesFromAction`; the fallback reads
  only ComputerSystem payloads — never the manager-level `#Manager.Reset` list
  (the emulator-pinned conflation guard: system list = 8 values incl.
  Nmi/ForceOn/PushPowerButton, manager list = ForceRestart/GracefulRestart).
  The power gate (`PowerService.reset`, `PowerController`, `PowerView`) now
  receives the true allow-list on mockup/bmcweb shapes instead of an empty
  list ("all allowed" fallback).
- 4 new unit tests in `test/redfish/discovery/feature_rules_test.dart`:
  annotation fallback on the mockup shape, union+dedupe of both sources,
  manager-list conflation guard, empty-action/no-annotation → empty.
- REQUIREMENTS.md updated (3 rows Partial → OK + DOCS-4 finding #3 paragraph).
- UI-2 increment: `ConfirmResetDialog` action buttons get explicit 48×48px
  minimum size + padded tap target (Material's visible default is 36dp; the
  gesture target is padded but the visual affordance wasn't). New widget test
  asserts both buttons render ≥48px tall.
- Emulator suite re-run: 36/36 passing on pin `23d21f9a` (the system reset
  allow-list + conflation pin is the exact contract implemented).

**Decisions:**
- DOCS selected per alternation. Within DOCS, picked the highest-value small
  safe code gap called out by REQUIREMENTS.md + the tracking "Next" list
  (annotation-form allow-list fallback), rather than a large re-fetch (anchors
  re-verified 12:40 UTC today — DOCS-13; per DOCS-9 precedent no re-fetch
  inside 5h).
- Left the `ResetActionInfo` ActionInfo-*resource* crawl in #022/#016: it needs
  discovery to fetch an extra URI + parse `Parameters[].AllowableValues`; the
  annotation form covers the mockup and the bmcweb-style shape now.
- Kept the manager-list conflation guard because the emulator pins both lists
  and the gate must use exactly the advertised system-level values.
- Formatted only the 4 touched Dart files (prior-run precedent).

**Next:**
- Push 46 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry) — full auth surface pinned +
  schemas mirrored; implement unit-level with the in-process mock server.
- #022/#016: crawl the `ResetActionInfo` ActionInfo resource
  (`Parameters[].AllowableValues`) now that the annotation fallback lands; or
  #008/#020: task poller (GET-on-monitor, TaskState parse, PercentComplete
  optional, Messages[] timeline) + bmcweb HTTP-push upload path.

**Issues touched:**
- none opened/closed this run. #022/#016 got the annotation-fallback progress
  recorded in FUTUREWORK; the gap is still open (ActionInfo resource crawl +
  task polling remain).
## 2026-10-23 — agent:redfish-automation — EMULATOR ($expand round-trip pin) + UI-2 sensors section headers

**Done:**
- EMULATOR primary workstream (alternation: last run DOCS 16:05). Pinned the
  **live `$expand` round-trip contract** for #018: the 13:58 run pinned that
  the service root *advertises* `ExpandQuery{ExpandAll,Levels}`, but the flag
  alone doesn't prove the payload shape. New emulator test:
  `GET /redfish/v1/Systems?$expand=.($levels=1)` returns the collection with
  **full inlined member bodies in one round trip** — Model/PowerState/
  Actions.Reset `ResetType@Redfish.AllowableValues` (incl. Nmi) +
  ProcessorSummary.Count=2 + MemorySummary.TotalSystemMemoryGiB=96 — the
  N+1-avoiding discovery shape a #018 lightweight pass can build on. Suite
  36 → **37 tests, all passing** on pin `23d21f9a`.
- Recorded negative for #022/#016: curl + fixture scan confirm the DMTF
  mockup ships **no** `ResetActionInfo` ActionInfo resource for the system
  Reset action (only the `ResetType@Redfish.AllowableValues` annotation form
  the 16:05 run implemented); the ActionInfo-*resource* crawl stays a
  bmcweb-style (OpenBMC) code task, not pinable on this fixture. Noted in
  FUTUREWORK #022/#016.
- REQUIREMENTS.md test-platform note 36 → 37 tests with the `$expand` pin
  described.
- UI-2 increment: SensorsView `_ChassisCard` section headers
  (`Temperatures`/`Fans`/`Sensors`) — the remaining non-card labels — now
  announce as one merged node each with the count (`Temperatures, 1` etc.),
  the established card-header pattern; visible titles preserved. One new
  widget test asserts the three merged labels + visible texts.
- Process hygiene: the manual probe server was stopped after verification;
  a stray repo-wide `dart format lib/ test/` churn (30 unrelated files) was
  detected and reverted — only the 3 intended files remain modified.

**Decisions:**
- EMULATOR selected per alternation (DOCS 16:05 → EMULATOR next).
- Chose the `$expand` pin over re-pinning other surfaces because #018 is the
  P1 whose "client currently ignores the query-capability surface" gap is
  directly servable by an emulator-verifiable contract — and because the
  mockup server genuinely implements `$expand` (verified live before
  writing the test), unlike filter/select which it only advertises.
- Followed the established raw-getJson pin precedent (task/log/account
  pins): no client model yet, no production code change — pin the exact
  payload shape before building the feature.
- Recorded — rather than code-fixed — the #022/#016 ActionInfo-resource
  gap: on this fixture there is nothing to pin; the crawl is a bmcweb-style
  code task for a #022/#016 implementation run.

**Next:**
- Push 48 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry) — full auth surface pinned
  + schemas mirrored; implement unit-level with the in-process mock server.
- #018: build the lightweight discovery pass on the now-pinned `$expand`
  contract (collection fetch instead of N+1 GETs) + the forceRefresh/`_error`
  cache fixes; or #008/#020: task poller + bmcweb HTTP-push upload path.

**Issues touched:**
- none opened/closed this run. #018 got the live `$expand` contract pin,
  #022/#016 got the ActionInfo-resource negative finding, both recorded in
  FUTUREWORK; issues remain open.
## 2026-10-23 — agent:redfish-automation — DOCS (OData base vocabulary mirror + anchor re-verification) + UI-2 self-signed warning semantics

**Done:**
- DOCS primary workstream (alternation: EMULATOR 17:07 → DOCS next). Closed the
  last un-mirrored REQUIREMENTS.md source citation: row 65 (`@odata.id` link
  traversal) cited `Odata.json`, but the external corpus had no OData schema.
  The bare `Odata.json` 404s on the DMTF schema index (verified live); the
  canonical file is the lowercase `odata.4.0.0.json` (OData 4.0.0 base
  vocabulary: `context`/`id`/`idRef`). Mirrored it (1,834 bytes, SHA-256
  `c73cce02…`, inside DOCS-6) and **byte-verified it is identical to
  `test/fixtures/redfish/schemas/Odata.json`** — proving the fixture copy is
  current. Manifest row added in `documentations/external/README.md`; row 65
  citation updated; DOCS-14 audit section appended to REQUIREMENTS.md.
- Re-verified every corpus anchor: **bmcweb advanced `27e0930b` → `fbb307a`**
  — re-fetched all four mirrored docs at the new HEAD, **all byte-identical**
  (no corpus refresh; manifest + standing Sources note updated);
  **`DMTF/Redfish-Mockup-Server` still `23d21f9a`** (default branch `main`;
  `master` ref 422s — corrected API call); **DSP0266 still 1.25.0**;
  **schema index 200 OK**. No spec refresh needed.
- UI-2 increment: the **self-signed certificate warning banner** in
  `SystemProfileForm` (conditional orange icon+text row revealed by the
  "Allow self-signed certificate" switch) was announced as detached nodes
  (bare icon + sentence). Now ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: 'Warning:
  …')` — the HealthBanner pattern). New widget test asserts the merged label +
  visible text preserved.
- Process hygiene: a stray repo-wide `dart format lib/ test/` churn (30
  unrelated files) was detected and reverted — only the 2 intended Dart files
  + 3 docs files remain modified (17:07-run precedent).

**Decisions:**
- DOCS selected per alternation. Within DOCS, picked the small corpus-
  completeness fix (row-65 citation gap) over a large re-fetch — anchors were
  just re-verified 16:05/17:07 and the corpus is complete for all 16
  client-mapped families; DOCS-14 is the last open citation.
- Kept the `ResetActionInfo` ActionInfo-*resource* crawl in #022/#016: it is
  a code task (bmcweb-style BMCs) and this is a corpus/provenance run.
- Formatted only the 2 touched Dart files (prior-run precedent).

**Next:**
- Push 49 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry) — full auth surface pinned +
  schemas mirrored; implement unit-level with the in-process mock server.
- #018: build the lightweight discovery pass on the now-pinned `$expand`
  contract (collection fetch instead of N+1 GETs) + the forceRefresh/`_error`
  cache fixes; or #022/#016: the `ResetActionInfo` ActionInfo-*resource* crawl.

**Issues touched:**
- none opened/closed this run (corpus mirror + anchor verification + UI-2
  label; no issue status change).
## 2026-10-23 — agent:redfish-automation — EMULATOR (query-behavior contract for #018) + UI-2 KVM view header

**Done:**
- EMULATOR primary workstream (alternation: DOCS 17:30 → EMULATOR next).
  Probed the live pinned mockup (`23d21f9a`) and pinned the **query-behavior
  contract** the #018 lightweight discovery pass must build on:
  - **`$filter`/`$select` are advertised but NOT applied.** Live probes: on a
    static-fixture mockup, `$filter=Id eq 'NOPE'` on the Roles collection (3
    members) still returns all 3 members, and `$select=Model` on the system
    resource returns the FULL body — despite `ProtocolFeaturesSupported`
    advertising `FilterQuery`/`SelectQuery`. New test pins both behaviours:
    the #018 pass must filter/select **client-side**, never rely on
    server-side query application.
  - **`$expand=*` (ExpandAll) IS applied** — inlines full ComputerSystem
    bodies (Model 3500 / PowerState On / Actions.Reset allow-list incl. Nmi /
    ProcessorSummary 2 / MemorySummary 96), same fields as the pinned
    `$expand=.($levels=1)` (17:07). New test pins this second form.
  - Probed + recorded (not pinned): without `-u`, the mockup accepts ANY
    credentials — `POST Sessions` with a wrong password returns 204 — so the
    401 bad-login error-mapping path stays a unit-test concern (consistent
    with the EMU-5 decision). Suite 37 → **39 tests**, all green on the pin.
- REQUIREMENTS.md "test platform" note updated (37 → 39 + query-behavior
  paragraph).
- UI-2 increment: **KvmView view header** (title + subtitle) — the last
  unmerged view-level non-card label group — now announces as ONE merged
  semantics node (`Semantics(container: true, excludeSemantics: true,
  label: 'Remote KVM / Consoles, consoles exposed by the system managers')`),
  the established header pattern; visible texts preserved. One new widget
  test asserts the merged label + both visible texts.
- Process hygiene: emulator baseline run once via `run_tests.sh` (37/37),
  then a live probe server for pin verification — stop verified (port 8443
  closed); `dart format` on the 3 touched Dart files changed nothing.

**Decisions:**
- EMULATOR selected per alternation. Within it, this run's increment = the
  query-application contract, because #018's open gap is "the client
  currently ignores the query-capability surface" and the naive assumption
  (advertised `$filter`/`$select` work server-side) is exactly what would
  silently corrupt a discovery pass.
- Recorded — rather than pinned — the 401 bad-login path: the DMTF mockup
  without `-u` accepts any credentials, so there is no conformant fixture to
  pin it against; keep it unit-level (EMU-5 precedent).
- Kept the UI increment to the established merged-label pattern (no new
  dependencies, no layout change).

**Next:**
- Push 54 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry) — full auth surface pinned
  + schemas mirrored; 401 bad-login path unit-level.
- #018: build the lightweight discovery pass on the pinned query contract
  (`$expand=*`/`$levels=1` collection fetch instead of N+1 GETs; filtering/
  selection client-side) + the forceRefresh/`_error` cache fixes; or
  #008/#020: task poller + bmcweb HTTP-push upload path.

**Issues touched:**
- none opened/closed this run. #018 got the query-behavior contract pin
  ($expand=* works; filter/select advertised-but-ignored), EMU-2/EMU-3 got
  count/scope updates — all recorded in FUTUREWORK; issues remain open.
## 2026-10-23 — agent:redfish-automation — DOCS (DSP0266 §7.3 query-parameters audit for #018) + UI-2 SystemOverviewPage header

**Done:**
- DOCS primary workstream (alternation: EMULATOR 18:36 → DOCS next). Audited
  DSP0266 1.25.0 §7.3.1–§7.3.5 "Query parameters" — the last unaudited
  normative clause set governing the #018 lightweight discovery pass. Extracted
  and traced to the client in REQUIREMENTS.md "DOCS-15" (9-row audit table):
  processing order (`$filter`→`$skip`→`$top`→pagination→`$expand`→`excerpt`→
  `$select`), `$expand` options (`*`, `$levels` default 1, `.`, `~`) +
  `MaxLevels` + 507 oversized-payload + privilege-no-fail + partial-expansion
  200, `$select` subset semantics, `$filter` built-in operators + precedence,
  `clientcontext` incremental retrieval, 400/501/QueryNotSupportedOnResource.
- Folded the bottom line into FUTUREWORK #018: the pinned mockup applies
  `$expand` (`*` and `$levels=1`) but NOT `$filter`/`$select` → the pass must
  gate `$expand` on `ProtocolFeaturesSupported.ExpandQuery` and filter/project
  client-side; map 501/507.
- Pinned the transport contract: `RedfishClient.getJson(path, query:)`
  forwards the map to the wire as `queryParameters` (+1 unit test in
  `redfish_client_extra_test.dart`) — the seam the #018 pass will use without
  touching the ETag/304 machinery.
- Anchors re-verified live (curl + git ls-remote): bmcweb `fbb307a`, mockup
  `23d21f9a`, DSP0266 1.25.0, schema index 200 — all unchanged; manifest
  anchors note bumped to 19:20 UTC + DOCS-15 section added.
- UI-2 increment: **SystemOverviewPage connection header** (system name +
  `scheme://host:port` in the top card) now announces as ONE merged semantics
  node (`Semantics(container: true, excludeSemantics: true, label: '<name>,
  <scheme>://<host>:<port>')`), the established header pattern; the
  conditional connection-error text keeps its own node. One new widget test
  asserts the merged label + both visible texts; `connectedHandle` helper
  gained a `port` param.

**Decisions:**
- DOCS selected per alternation. Within DOCS, picked the §7.3 audit (the last
  unaudited normative clause set) over another corpus fetch — anchors were
  re-verified 16:45/17:30 and the corpus is complete for all 16 client-mapped
  families; DOCS-15 closes the final spec-audit gap.
- Kept the code delta to a test-only transport pin: `getJson` already supports
  `query` (nothing passes it yet); wiring `$expand` into the discovery crawl
  is #018's build, not a docs-run change.
- UI increment kept to the established merged-label pattern (no new deps, no
  layout change).

**Next:**
- Push 59 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry) — full auth surface pinned
  + schemas mirrored; 401 bad-login path unit-level.
- #018: build the lightweight discovery pass on the now-pinned contract —
  gate `$expand` on `ProtocolFeaturesSupported.ExpandQuery`, use
  `getJson(query: {'\$expand': ...})` (transport pinned this run), filter/
  project client-side, map 501/507 + the forceRefresh/`_error` cache fixes;
  or #008/#020: task poller + bmcweb HTTP-push upload path.

**Issues touched:**
- none opened/closed this run. #018 got the DSP0266 §7.3 normative contract
  (DOCS-15), EMU-2/UI-2 got scope updates — all recorded in FUTUREWORK;
  issues remain open.
## 2026-10-23 — agent:redfish-automation — EMULATOR (map-form getJson query round-trip for #018) + UI-2 KVM connect-URI row

**Done:**
- EMULATOR primary workstream (alternation: DOCS 19:25 → EMULATOR next).
  Pinned the **map-form `getJson(path, query:)` `$expand` round-trip** against
  the live pinned mockup (`23d21f9a`), joining the 19:25 transport unit test
  (query map forwards to the wire) with the URL-string live pins (17:07
  `$levels=1`, 18:36 `$expand=*`):
  - New emulator test calls `client.getJson('/redfish/v1/Systems', query:
    {'\$expand': '.($levels=1)'})` — the exact call shape the #018
    lightweight discovery pass will make — and asserts the SAME inlined full
    ComputerSystem member bodies the URL-string form returns (Model 3500 /
    Manufacturer Contoso / PowerState On / Actions.Reset allow-list incl.
    Nmi / ProcessorSummary Count 2) in one round trip. Suite 39 → **40
    tests**, all green on the pin.
- REQUIREMENTS.md "Test platforms" note updated (39 → 40 + map-form
  paragraph).
- UI-2 increment: **KVM console card connect-URI row** (`Connect URI:` label
  + the SelectableText URI) — announced as two detached text nodes; now ONE
  merged semantics node (`Semantics(container: true, excludeSemantics: true,
  label: 'Connect URI: <uri>')`, the established row pattern), with the label
  + URI kept visible in a Row. One new widget test asserts the merged label +
  both visible texts.
- Process hygiene: emulator suite run once via `run_tests.sh` (40/40), server
  stop verified (port 8443 closed); `dart format` reflowed 29 pre-existing
  files (formatter drift) — reverted, only this run's 4 touched files kept.

**Decisions:**
- EMULATOR selected per alternation. Within it, chose the map-form query
  round-trip pin because #018's remaining open gap is "build the lightweight
  discovery pass" — the pass will call `getJson(path, query:)`, and the naive
  assumption that the unit-tested forwarding works identically on the live
  server was the last unpinned seam.
- Reverted the `dart format` reflow of 29 unrelated files: cosmetic formatter
  drift not belonging to this run's workstream; keeping the diff to the 4
  intended files preserves the one-increment rule.
- UI increment kept to the established merged-label pattern (no new deps, no
  layout change).

**Next:**
- Push 61 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry) — full auth surface pinned
  + schemas mirrored; 401 bad-login path unit-level.
- #018: build the lightweight discovery pass on the now fully pinned contract
  (`getJson(query: {'\$expand': '.($levels=1)'})` collection fetch; gate on
  `ProtocolFeaturesSupported.ExpandQuery`; filter/project client-side; map
  501/507) + the forceRefresh/`_error` cache fixes; or #008/#020: task
  poller + bmcweb HTTP-push upload path.

**Issues touched:**
- none opened/closed this run. #018 got the map-form `$expand` live pin (40th
  emulator test); EMU-2/UI-2 got count/scope updates — all recorded in
  FUTUREWORK; issues remain open.
## 2026-10-23 — agent:redfish-automation — DOCS (DSP0266 citation audit + §9.9 annotation pin) + UI-2 OverviewView error state

**Done:**
- DOCS primary workstream (alternation: EMULATOR 22:45 → DOCS next). Audited
  every DSP0266 clause citation in REQUIREMENTS.md against the **mirrored
  `DSP0266_1.25.0.pdf`** (pdftotext of the actual PDF — TOC + body) and found
  the requirement rows added across DOCS-3/4/5/10/13 cited an **older spec
  layout** that does not match the mirrored PDF:
  - `§8.3 "Service Root"` → `§7.2.3 "Service root request"` (service-root
    request clause lives in the Service requests chapter; §8 is Service
    responses).
  - `§8.4 ComputerSystem` / `§8.10 Thermal` / `§8.14 "Software inventory"`
    → DSP0266 does not enumerate per-resource property lists; those are
    versioned schemas (`ComputerSystem.v1_29_0.json`, `Thermal.v1_7_3.json`,
    `SoftwareInventory.json`) + the `§9 Data model` clauses (`§9.1 Resources`,
    `§9.5 Common data types`, `§9.6 Properties`, `§9.6.13 Links`).
  - `§9.2 "HTTP and the Redfish protocol"` (ETag/304) → `§6.5 "ETags"` +
    `§7.2 "GET (read requests)"`.
  - `§12.2 "Actions"` → `§9.6.14 "Actions property"` + `§7.11 "POST (action)"`.
  - `§12.3 "Basic authentication"` → `§13.3.3 "HTTP Basic authentication"`.
  - `§12.4 "Sessions"` / "Session timeout" → `§13.3.4 "Redfish session login
    authentication"` (+ `§13.3.4.3 "Session lifetime"`).
  - `§12.7 "Error responses"` → `§8.6 "Error responses"`.
  - `§9.7 "Firmware update"` → `§12.7 "Update service"` (`§12.7.2.1`).
  - EMU-5 decision's "Response messages" placeholder → `§8.6`.
- Kept the clauses that were already correct unchanged and documented that in
  the audit (`§12.1 Eventing` + `§12.1.1–12.1.5`, `§12.2 Asynchronous
  operations`, `§7.3 Query parameters`, `§9.6.11/§9.6.12`, `§9.6.2`,
  `§9.1 Resources`). Also reverted one over-eager edit (Eventing rows) after
  re-verifying the TOC — good thing the audit verified against the body.
- Pinned the payload-annotation contract in test form: +2 unit tests
  (`feature_rules_test.dart`) asserting the §9.9.2 `@Redfish.AllowableValues`
  list parse on `#ComputerSystem.Reset` and the §9.9.1 tolerance for
  unrecognized annotations (unrelated annotation keys / non-list values do
  not disturb the parse). Code already implemented both; no behavior change.
  `feature_rules.dart` doc comment citation fixed `§9.3` → `§9.9`.
- Anchors re-verified live 23:32 UTC (bmcweb `fbb307a`, mockup `23d21f9a`,
  DSP0266 1.25.0 PDF at the `www.dmtf.org` URL — the `redfish.dmtf.org`
  path 404s and the hub links the `www.dmtf.org` URL, content-length
  1,243,359 bytes unchanged; schema index 200). Manifest anchors note + the
  DSP0266 row note updated.
- UI-2 increment: **OverviewView error state** (cloud-off icon + "Unable to
  load overview" + detail message) now announces as ONE merged semantics node
  (`Semantics(container: true, excludeSemantics: true, label: 'Unable to load
  overview. <message>')`), Retry button keeps its own control node. One new
  widget test (`overview_view_test.dart`) asserts the merged label + both
  visible texts + separately-announced Retry.

**Decisions:**
- DOCS selected per alternation. Within DOCS, chose a citation-correctness
  audit over another corpus fetch: the corpus is complete for all 16
  client-mapped families + OData base vocabulary and all anchors were
  unchanged (verified live), but the traceability document cited the wrong
  DSP0266 clauses — a real correctness gap for anyone using REQUIREMENTS.md
  to implement #015/#016/#018/#022.
- Kept the code delta minimal and test-only: the annotation reader already
  implements §9.9; the run pinned the contract rather than changing
  behaviour (DOCS §2.3 "small, safe fixes with tests"; UI §5 one small
  increment).
- Corrected rather than rewritten: fixed the stale citations in place and
  added the DOCS-16 mapping table so future runs can see what changed and
  why — no requirement dropped, no new requirement invented.

**Next:**
- Push 64 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry — full auth surface pinned
  + schemas mirrored + session clauses now cited correctly as §13.3.4).
- #018: build the lightweight discovery pass on the fully pinned contract
  (`getJson(query: {'\$expand': '.($levels=1)'})` collection fetch; gate on
  `ProtocolFeaturesSupported.ExpandQuery`; filter/project client-side; map
  501/507) + the forceRefresh/`_error` cache fixes; or #008/#020: task
  poller + bmcweb HTTP-push upload path.

**Issues touched:**
- none opened/closed this run. DOCS-16 recorded in FUTUREWORK; UI-2 got the
  OverviewView error-state increment; issues remain open.
## 2026-10-24 — agent:redfish-automation — EMULATOR (MessageRegistry contract) + UI-2 SensorsView error state

**Done:**
- EMULATOR primary workstream (alternation: DOCS 23:40 → EMULATOR next).
  Pinned the **MessageRegistry discovery/resolution contract** live against
  the pinned mockup (`23d21f9a`), joining the existing discovery-contract
  pins (LogService, EventService, TaskService) with the **§8.6 error-response
  surface** the `RedfishError` model normalizes:
  - Service root advertises `Registries` → `MessageRegistryFileCollection`
    (exactly one member, `Base.1.5.0`) → `MessageRegistryFile.Location[0].Uri`
    resolves to the `#MessageRegistry` JSON with **60 Base.\* templates**
    (Message/Severity/NumberOfArgs).
  - Asserts the client-relevant template shapes: GeneralError (Critical /
    NumberOfArgs 0 — the `code` fallback), ActionNotSupported (%1 arg),
    AccessDenied (Critical), ActionParameterMissing (2 args).
  - Suite 40 → **41 tests**, all green via `run_tests.sh` (trap cleanup
    verified, port 8443 closed).
- **Negative findings recorded (curl probes before adding the pin):** the
  mockup's reset action returns **204 with no `Location`** task-monitor header
  (GET-on-monitor seam stays unit-level, complements the absent-PercentComplete
  pin) and the **live 404 closes the connection without an error body**
  (extended-info envelope seam stays unit-level, consistent with EMU-5).
- REQUIREMENTS.md "Test platforms" updated (40 → 41 + MessageRegistry
  paragraph, §8.6/§11.4 + #014).
- UI-2 increment: **SensorsView error state** — bare error-colored `Text` →
  merged semantics node (`Unable to load sensors. <message>` via
  `Semantics(container: true, excludeSemantics: true, ...)`), plus a **Retry**
  `FilledButton.icon` wired to the existing `SensorsController.load()`.
  Two new widget tests: retry-affordance/reload-no-crash +
  merged-node-with-separate-Retry-control (mirroring the OverviewView error
  tests, including the `_FailingSensorsService` double).

**Decisions:**
- EMULATOR per alternation. Within it, chose the MessageRegistry contract
  because (a) it is the last un-pinned, spec-conformant fixture surface that
  a REQUIREMENTS.md requirement row cites for the error-mapping behaviour,
  and (b) the two tempting seams (task-monitor Location on reset, live 404
  extended-info body) were probed first and both negatively confirmed as
  unit-level-only — consistent with the recorded EMU-5/EMU-3 findings.
- No production code change for the emulator pin; the UI increment is the
  only production diff, kept to the established error-state pattern.
- `dart format` on only the 3 touched Dart files (0 changed) — avoiding the
  tree-wide formatter drift that previous runs reverted.

**Next:**
- Push 66 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager (authMethod dispatch, safe logout URI, token rehydrate,
  SessionTimeout + AbsoluteSessionTimeout* expiry — auth surface fully pinned
  + schemas mirrored; session clauses now §13.3.4).
- #018: build the lightweight discovery pass on the fully pinned contract
  (`getJson(query: {'\$expand': '.($levels=1)'})` collection fetch; gate on
  `ProtocolFeaturesSupported.ExpandQuery`; filter/project client-side; map
  501/507) + the forceRefresh/`_error` cache fixes; or #008/#020 task poller
  (GET-on-monitor stays unit-level — mockup reset returns 204 no Location).

**Issues touched:**
- none opened/closed this run. EMU-2 count 40 → 41 recorded in FUTUREWORK;
  UI-2 got the SensorsView error-state increment; issues remain open.
## 2026-10-24 — agent:redfish-automation — DOCS-17 session-lifetime audit + UI-2 FirmwareView error state

**Done:**
- DOCS primary workstream (alternation: EMULATOR 02:25 → DOCS next). **DOCS-17 —
  DSP0266 §13.3.4.3 "Session lifetime" audit + expiry pin.**
  - Audited the timeout contract against the mirrored `SessionService.json` +
    `SessionService.v1_2_0.json` (DOCS-12): `SessionTimeout` (inactivity TTL),
    `AbsoluteSessionTimeout` (v1_2_0 — max seconds open *regardless of
    activity*, applied only when `AbsoluteSessionTimeoutEnabled` is true).
  - **Found a real traceability defect**: the REQUIREMENTS.md row "Session
    timeout handling … OK" was overstated — `Session.expiresAt`/`isExpired`
    existed but **nothing ever populated the deadline** (AuthManager never
    reads the SessionService resource). Corrected the row to Partial and
    pinned the model-level contract.
  - New tested helper `Session.expiryFromService(...)` takes the conservative
    *earlier* deadline (`createdAt + min(SessionTimeout,
    AbsoluteSessionTimeout)` when enabled, else `SessionTimeout`), handles
    absolute-only services and malformed values, `null` without a body.
    +6 unit tests in `models_test.dart` (309 → 315).
  - REQUIREMENTS.md DOCS-17 trace table added; Last-audited header updated.
  - Anchors re-verified live 01:07 UTC: bmcweb `fbb307a` (unchanged — the
    `main` ref 422s, `master` is the branch), mockup `23d21f9a` (unchanged),
    DSP0266 1.25.0 (200, 1,243,359 bytes — unchanged), schema index 200.
- UI-2 increment: FirmwareView error state now announces as ONE merged
  semantics node (`Unable to load firmware. <message>` via
  `Semantics(container: true, excludeSemantics: true, ...)`), Retry keeps its
  own control node. +1 widget test asserting the merged label + visible text +
  separately-announced Retry (315 → 316).

**Decisions:**
- DOCS per alternation. Within DOCS, chose the session-lifetime audit because
  (a) it is the last trace row claiming OK with no tested code behind it, and
  (b) it directly de-risks the top open P1 #015 (AuthManager) by providing the
  expiry primitive `AuthManager` will wire in.
- Small tested code fix per §2.3 (docs audit → safe gap fix with tests), no
  behavior change outside the new helper; no new dependency; no TLS change.
- Kept the AuthManager fetch/wiring out of this run — it belongs to #015's
  acceptances; documented the exact remaining steps in the DOCS-17 section.
- Queued DOCS-18: the MessageRegistry payload (`Base.1.5.0.json`) is the one
  corpus surface the emulator pins but the mirror lacks — quick mirror next
  docs run.

**Next:**
- Push 69 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire the discovered SessionService body into login to
  set `expiresAt` via `Session.expiryFromService`, re-auth when `isExpired`
  flips; honor `AbsoluteSessionTimeout*` only when published (mockup serves
  v1_1_8 — `SessionTimeout=30` pinned).
- DOCS-18: mirror `Base.1.5.0.json` from the DMTF registries path; or #018
  discovery pass on the fully pinned `$expand` contract.

**Issues touched:**
- none opened/closed this run. DOCS-17 done + DOCS-18 queued in FUTUREWORK;
  UI-2 got the FirmwareView error-state increment; issues remain open.
## 2026-10-24 — agent:redfish-automation — EMULATOR (Sessions/Session-resource contract + ResetType negative pins) + UI-2 PowerView/KVM error states

**Done:**
- EMULATOR primary workstream (alternation: DOCS 03:09 → EMULATOR next).
  Pinned two more fixture surfaces live against the pinned mockup
  (`23d21f9a`, fresh clone + checkout verified; suite 41 → **43 tests**,
  green via `run_tests.sh`, trap cleanup verified, port 8443 closed):
  1. **Sessions collection + Session resource contract (#015/#026):** the
     collection is enumerable from the discovered SessionService URI
     (`#SessionCollection.SessionCollection`, `Members@odata.count` ≥ 1,
     members are session resources — never the collection); the pre-seeded
     session is a conformant `#Session.v1_7_1` for Administrator
     (Id/Name/Description/UserName, **no Password**). **Security-relevant
     negative pin:** a POST-created session resolves to a body that ECHOES
     the login `Password` and lacks `@odata.type`/SessionType
     (non-conformant — DSP0266 §13.3.4 Session has no Password property).
     Client rule recorded in REQUIREMENTS.md: the #015 AuthManager must
     persist the token/location from the create RESPONSE HEADERS and never
     read session-resource bodies for secrets.
  2. **ResetType validation negative pin (#014/#022):** POST Reset with
     `ResetType: "Bogus"` returns 204 exactly like a valid value — the
     mockup does not validate the body; the client's 400
     `ResetTypeInvalid` path stays unit-level and the UI must pre-validate
     against the advertised allow-list (it already does).
- REQUIREMENTS.md "Test platforms" updated: 41 → 43 tests + both negative
  pins in prose (§13.3.4 citation for the Session quirk).
- UI-2 increments (the last two bare error-`Text` views -> established merged
  pattern):
  - **PowerView inline error**: `Power control failed. <message>` merged
    semantics node (container + excludeSemantics) + Retry `TextButton.icon`
    wired to the existing `PowerController.refresh()` (clears the error on
    success, mounted-guarded). +2 widget tests (`_FailingFetchPowerService`
    double): merged node + visible text + separate Retry control; Retry
    re-runs the failing fetch (fetchCalls == 1) without crashing.
  - **KvmView hard-load error**: full error state (icon + title + detail) as
    ONE merged node `Unable to load KVM consoles. <message>` + Retry
    `FilledButton.icon` wired to `KvmController.load()`; error-with-zero-
    consoles is now distinct from the clean empty state (the old code showed
    a bare error line above "No consoles found."). +2 widget tests
    (`_FailingKvmService` double, the SensorsView pattern): merged node +
    visible texts + separate Retry control; Retry re-runs the failing load
    (fetchCalls 1 → 2) without crashing.

**Decisions:**
- EMULATOR per alternation. Within it, chose the Sessions/Session-resource
  contract because (a) it is the last un-pinned surface the top P1 #015
  AuthManager must reason about (session reuse/expiry), and (b) the probe
  surfaced a genuinely security-relevant fixture quirk (password echo) that
  needs to be pinned so the client never reads secrets back — the
  #015/#026 auth-surface note. The ResetType negative pin closes the
  invalid-type question for #014/#022 with evidence (the mockup accepts any
  value) — consistent with the recorded 204-no-Location / 404-no-body /
  any-credentials negative findings.
- No production code change besides the two UI increments (kept to the
  established error-state pattern). Pinned the clock convention to local time
  (CEST) as previous entries.
- `dart format` on only the 5 touched Dart files; reverted the runbook §6
  tree-wide formatter drift on 28 untouched files (formatting only) — per the
  established repo practice recorded in prior runs.

**Next:**
- Push 70 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager — expiry + session-shape primitives are now pinned:
  wire `Session.expiryFromService` into login (set `expiresAt` from the
  discovered SessionService), re-auth when `isExpired` flips, persist the
  token/location from create RESPONSE HEADERS only (the fixture echoes the
  password in session bodies).
- DOCS-18: mirror `Base.1.5.0.json` from the DMTF registries path; or #018
  discovery pass on the pinned `$expand` contract; or start the
  `ResetActionInfo` ActionInfo-resource crawl (#022/#016, bmcweb-style).

**Issues touched:**
- none opened/closed this run. EMU-2 41 → 43 recorded; #015/#026/#014/#022
  got new pins; UI-2 got the PowerView + KVM error-state increments; issues
  remain open.
## 2026-10-24 — agent:redfish-automation — DOCS (message-registry payload mirror + Base registry delta audit) + UI-2 Dashboard error summary

**Done:**
- DOCS primary workstream (alternation: EMULATOR 04:01 → DOCS next).
  **DOCS-18 done** — the last corpus surface the emulator pins but the mirror
  lacked is closed:
  1. **`registries/Base.1.5.0.json` mirrored** (31,984 bytes, SHA-256
     `c1026341…`) from the DMTF registries path — **byte-identical** to
     `test/fixtures/redfish/dmtf_mockup/Registries/Base.1.5.0.json`, so the
     EMU-2 MessageRegistry pin (60 Base.* templates) now resolves against a
     real mirror file and the fixture payload is **proven authentic upstream**
     (not fixture-generated).
  2. **`registries/Base.1.24.0.json` mirrored** (newest published, 138,295
     bytes, `@odata.type` `#MessageRegistry.v1_9_0`) + **delta audit**: adds
     65 templates (60→125, none removed), rewords 39 shared Message strings,
     but **`NumberOfArgs` stable for every shared key** — the
     emulator-pinned argument-count contract holds across the newest registry.
  3. REQUIREMENTS.md §8.6 error-envelope row + "Test platforms" MessageRegistry
     pin now cite the mirror files; DOCS-18 audit section added (3 trace rows +
     delta table + anchors note). Manifest +2 rows. New bytes 170,279, inside
     DOCS-6 budget. All upstream anchors unchanged (bmcweb `fbb307a`, mockup
     `23d21f9a`, DSP0266 1.25.0, schema index 200, registries path 200).
- UI-2 increment: the **Dashboard `_ErrorSummary` card** now announces as ONE
  merged semantics node (`Unable to reach N systems. Retry available.` —
  `Semantics(container + excludeSemantics)` wraps only the icon+text row), the
  Retry `TextButton` kept outside the container to retain its own control
  node. +2 widget tests (merged node + visible text + separate Retry control;
  singular form). UI-1 Retry behaviour unchanged.

**Decisions:**
- DOCS per alternation. Within it, chose DOCS-18 because (a) it is the last
  queued DOCS item whose source the emulator already pins live (the
  MessageRegistry contract 04:01 run) but the mirror lacks, and (b) the
  byte-identical provenance check gives the strongest form of traceability —
  the pinned mockup's error surface is now proven to be the authentic DMTF
  publication.
- Mirrored the newest `Base.1.24.0.json` too (138 KB, inside budget) so the
  "newest vs mockup-served" delta is documented against real files, matching
  the DOCS-12/13 newest+served precedent. Recorded that the client impact is
  none (RedfishError treats code/message opaquely; a future MessageId resolver
  would read the mirror).
- UI increment kept to the established merged-semantics pattern with the Retry
  control outside the excluded container (matches SensorsView/PowerView/KvmView
  implementations). No new dependencies, no TLS change, no production behavior
  change beyond accessibility semantics.

**Next:**
- Push 72 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login (set
  `expiresAt` from the discovered SessionService), re-auth when `isExpired`
  flips, persist token/location from create RESPONSE HEADERS only.
- #018 discovery pass on the pinned `$expand` contract; or the
  `ResetActionInfo` ActionInfo-resource crawl (#022/#016, bmcweb-style).

**Issues touched:**
- none opened/closed this run. DOCS-18 done; REQUIREMENTS.md rows updated;
  UI-2 got the Dashboard error-summary increment; issues remain open.

## 2026-10-24 — agent:redfish-automation — EMULATOR (UpdateService action surface + firmware seams) + UI-5 FirmwareView busy state

**Done:**
- EMULATOR primary workstream (alternation: DOCS 05:20 → EMULATOR next).
  **EMU-2 43 → 45 tests** — pinned the last un-pinned firmware seam, the
  UpdateService action surface (#008/#020):
  1. **SimpleUpdate live round-trip**: `FirmwareService.startSimpleUpdate`
     resolves the action target from the live `UpdateService` body, POSTs the
     contract body, and the DMTF mockup answers **204 with NO task-monitor
     `Location`** (accepts any action body without validation — same
     non-validating behavior as the 04:01 ResetType negative pin). The
     returned `UpdateTask` has null taskUri/retryAfterSeconds — the
     202-with-Location monitor path stays unit-level.
  2. **HttpPushUri negative pin**: the fixture advertises
     `HttpPushUri: /FWUpdate` but does NOT implement it — POSTing a binary
     upload body fails with **400 + EMPTY body** (no `@Message.ExtendedInfo`
     envelope; connection closed; GET /FWUpdate 404s). The #020 binary-push
     flow stays unit-level; client normalizes as `RedfishException` HTTP 400
     with no error code (asserted via `fromDioException` in the test).
  REQUIREMENTS.md "Test platforms" 43 → 45 + both pins (with the mockup's
  POST-handler JSON-decoding rationale recorded against the `23d21f9a` pin).
- UI-5-style increment: **FirmwareView Start-update button busy state**.
  Added `FirmwareUiState.starting` (distinct from `loading`); while a
  SimpleUpdate POST is in flight the `FilledButton` shows a 16px spinner +
  'Starting…' and is disabled, re-enabling on success (queued banner) or
  failure (error card). +3 controller tests (new
  `firmware_controller_test.dart`) + 2 widget tests (`_GateFirmwareService`
  Completer-gated double): busy state (disabled + spinner + unchanged header
  semantics) and failure re-enable + error surface.

**Decisions:**
- EMULATOR per alternation. Within it, chose the UpdateService action surface
  because (a) it is the last un-pinned surface the top firmware issue
  #008/#020 must reason about (the 202-with-Location task-monitor path vs the
  mockup's 204-no-Location reality; the advertised-but-unimplemented push
  URI), and (b) the probes produced crisp, reproducible pins: the mockup's
  POST handler JSON-decodes every non-Action body ("Decoding JSON has failed"
  → 400 empty body on binary), and SimpleUpdate answers 204 without
  validation. Both seams are now recorded as unit-level, with the client's
  normalized behavior pinned against the live server.
- UI increment: kept to the UI-5 busy-state precedent (PowerView dialog
  confirm). Added a dedicated `starting` state rather than overloading
  `loading` so the header's merged '…, loading' semantics (screen-level) stays
  accurate while the button carries its own in-flight indicator. No new
  dependencies, no TLS change.
- `dart format` on the 5 touched Dart files only — no tree-wide drift.

**Next:**
- Push 74 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login (set
  `expiresAt` from the discovered SessionService), re-auth when `isExpired`
  flips, persist token/location from create RESPONSE HEADERS only (the
  fixture echoes the password in session bodies).
- #018 discovery pass on the pinned `$expand` contract; or the
  `ResetActionInfo` ActionInfo-resource crawl (#022/#016, bmcweb-style).

**Issues touched:**
- none opened/closed this run. EMU-2 43 → 45 recorded; #008/#020 got the
  UpdateService action-surface pins; UI-5 got the FirmwareView busy-state
  increment; issues remain open.

## 2026-10-24 — agent:redfish-automation — DOCS (served-version corpus mirror DOCS-19) + UI-2 SensorsView empty state

**Done:**
- DOCS primary workstream (alternation: EMULATOR 05:48 → DOCS next).
  **DOCS-19 done** — closed the last "served-version" corpus gap. DOCS-2
  (2026-10-22) refreshed the DOCS-2-era families to their **newest** versioned
  definitions only, but the pinned `23d21f9a` mockup *serves* older
  `@odata.type` versions, breaking the DOCS-11/12/13 invariant that every
  `@odata.type` the mockup publishes has a versioned schema in the fixture.
  1. Mirrored the **mockup-served** versions for eight client-mapped families
     into `documentations/external/redfish/schemas/v1/` **and**
     `test/fixtures/redfish/schemas/`: `Sensor.v1_8_1` (42/42 sensors),
     `ComputerSystem.v1_22_0`, `Chassis.v1_25_0`, `AccountService.v1_15_0`,
     `SoftwareInventory.v1_10_1`, `LogService.v1_6_0`,
     `EthernetInterface.v1_12_0`, `MessageRegistry.v1_0_0` — plus the newest
     `MessageRegistry.v1_9_0` (the `@odata.type` behind `Base.1.24.0`,
     DOCS-18) to complete the newest+served pair for the registry family.
     9 files, 560,665 bytes, inside the DOCS-6 budget.
  2. Property-delta audit: every client-read field verified present in the
     served versions (Sensor Reading/ReadingType/ReadingUnits/Thresholds,
     ComputerSystem identity/PowerState/Summaries/Boot, AccountService lockout
     surface incl. the #015 fields, SoftwareInventory Name/Version/Status/
     Updateable, LogService ServiceEnabled/OverWritePolicy/Entries/ClearLog,
     EthernetInterface MAC/IPv4/IPv6/VLAN, MessageRegistry
     RegistryPrefix/Version/Messages) — **no client code change needed**.
  3. Trace rows updated to cite the served files; manifest +9 rows; reference
     README +DOCS-19 provenance. All anchors re-verified unchanged (bmcweb
     `fbb307a`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200,
     registries path 200).
- UI-2 increment: the **SensorsView empty state** ("No sensor data available")
  is no longer a bare detached `Text` — it renders an icon + visible text
  inside the established `Semantics(container + excludeSemantics)` merged node
  (label `No sensor data available`), the last empty-state surface to follow
  the pattern. +2 widget tests (icon + visible text; merged semantics node)
  via a new `_EmptySensorsService` double.

**Decisions:**
- DOCS per alternation (last was EMULATOR 05:48). Within it, chose DOCS-19
  because (a) the served-version gap is the last corpus hole — every other
  family the mockup publishes already has its served version mirrored
  (DOCS-12/13/11), and (b) the fixture-schema folder should be a complete
  provenance set for the pinned mockup, not just the newest definitions.
- Kept the fixture payloads untouched (additive schema files only) — nothing
  under `test/` globs `fixtures/redfish/schemas/` (verified), so the emulator
  suite is unaffected.
- The verification gate's tree-wide `dart format` surfaced 28 files of
  pre-existing line-wrap churn from prior runs' "format touched files only"
  policy; those files were restored to HEAD to keep this commit scoped (the
  DOCS-19 + UI changes are the only intended edits). Noted in
  `automation-tracking.md` so future runs don't re-format them unless editing.
- UI increment stayed minimal and pattern-consistent (icon + merged node, no
  Retry — the load succeeded and returned no chassis, so there is nothing to
  retry). No new dependencies, no TLS change.

**Next:**
- Push 75 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login (set
  `expiresAt` from the discovered SessionService), re-auth when `isExpired`
  flips, persist token/location from create RESPONSE HEADERS only (the
  fixture echoes the password in session bodies).
- #018 discovery pass on the pinned `$expand` contract; or the
  `ResetActionInfo` ActionInfo-resource crawl (#022/#016, bmcweb-style).

**Issues touched:**
- none opened/closed this run. DOCS-19 done; REQUIREMENTS.md trace rows
  updated; UI-2 got the SensorsView empty-state increment; issues remain open.

## 2026-10-24 — agent:redfish-automation — EMULATOR (chassis metrics + subsystem contracts) + UI-2 KVM empty state

**Done:**
- EMULATOR primary workstream (alternation: DOCS 06:45 → EMULATOR next).
  Pinned three aggregate telemetry surfaces the pinned `23d21f9a` mockup
  serves, all previously unpinned — the exact wire shapes a #019 real-time
  telemetry receiver / #006 power card / PSU-health display consume:
  1. **EnvironmentMetrics.v1_3_1** (`/Chassis/1U/EnvironmentMetrics`): one-
     resource aggregate with TemperatureCelsius.Reading 39,
     PowerWatts.Reading 374, PowerLimitWatts.SetPoint 500 (+ AllowableMax/Min
     + ControlMode), FanSpeedsPercent[2] — every reading carrying a
     `DataSourceUri` that resolves into the Sensors collection (pinned by
     following a fan DataSourceUri → `#Sensor` member with Reading 45).
  2. **ThermalSubsystem.v1_3_1**: Fans collection (4), FanRedundancy NPlusM
     (MinNeededInGroup 1 / MaxSupportedInGroup 2), ThermalMetrics.v1_3_1
     TemperatureSummaryCelsius Intake/Exhaust/Internal/Ambient with
     DataSourceUri → Sensors.
  3. **PowerSubsystem.v1_1_1**: PowerSupplies collection (2) +
     PowerSupply.v1_5_3 Bay1 detail (Model RKS-440DC / FirmwareVersion 1.00 /
     LineInputStatus Normal / `#PowerSupply.Reset` target / Metrics link) —
     plus the **documented negative**: legacy `/Chassis/1U/Power` embedded
     PowerSupplies reports `Status.Health == 'Warning'` while the overview
     rollup reads ComputerSystem/Chassis Status (a future #006/#019
     improvement should surface PSU health).
  Emulator 45 → **48** (3 new tests: `EnvironmentMetrics: aggregate telemetry
  …`, `ThermalSubsystem: FanRedundancy + ThermalMetrics …`, `PowerSubsystem:
  PowerSupplies collection + PowerSupply detail …`), green via
  `tool/emulator/run_tests.sh` twice.
- REQUIREMENTS.md "Test platforms" 45 → 48 + the three contracts + the
  documented negative + the DOCS-20 corpus note (the pinned families have no
  versioned schema in the fixture/mirror yet — next DOCS run should mirror
  them to restore the invariant).
- UI-2 increment: the **KVM empty state** ("No consoles found.") converted to
  the established merged-semantics pattern — icon
  (`Icons.videogame_asset_off_outlined`) + visible text inside a
  `Semantics(container + excludeSemantics, label: 'No consoles found.')`
  node, no Retry (nothing to retry). +2 widget tests via `_EmptyKvmService`
  double: icon + visible text render; merged semantics label. Suite 329 → 331.

**Decisions:**
- EMULATOR per alternation; within it, chose the chassis metrics/subsystem
  surface because (a) it is the last UNPINNED telemetry surface the top
  sensor issue #007/#019 and the overview power work #006 must reason about —
  the suite pinned the Sensors/Thermal/Power collections but never the
  aggregate EnvironmentMetrics/ThermalMetrics/PowerSubsystem resources the
  mockup also serves, and (b) the pins produced a crisp, reproducible
  contract: one resource replaces an N+1 sensor crawl for the aggregate
  values, with DataSourceUri wiring between the surfaces verified live.
- No production code change: the pins document the wire contract for future
  work. The PSU-health `Warning` mismatch is a discovered GAP (documented in
  REQUIREMENTS, queued for #006/#019) — fixing it would have meant an
  OverviewService change, which is a separate workstream.
- New corpus gap DOCS-20 recorded in FUTUREWORK under P1 docs: EMULATOR mode
  stays one workstream, so the schema mirror is queued for the next DOCS run.
- UI increment stayed pattern-consistent (icon + merged node, no Retry — the
  load succeeded, so there is nothing to retry). No new dependencies, no TLS
  change.

**Next:**
- Push 77 queued local commits once GitHub credentials are available.
- DOCS-20: mirror the 7 pinned chassis-metrics/subsystem schemas
  (EnvironmentMetrics.v1_3_1, ThermalSubsystem.v1_3_1, ThermalMetrics.v1_3_1,
  PowerSubsystem.v1_1_1, PowerSupply.v1_5_3, FanCollection,
  PowerSupplyCollection) into the mirror + fixture schemas.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only (the fixture echoes the password in session bodies).

**Issues touched:**
- none opened/closed this run. EMU-2 45 → 48 recorded; #007/#019/#006 got the
  chassis metrics + subsystem contracts pins + the PSU-health gap note; UI-2
  got the KVM empty-state increment; issues remain open.

## 2026-10-24 — agent:redfish-automation — DOCS (DOCS-20) + UI-2 Dashboard empty state

**Done:**
- DOCS primary workstream (alternation: EMULATOR 08:15 → DOCS next). Closed the
  DOCS-20 corpus gap: mirrored **11 files / 160,101 bytes** (inside DOCS-6)
  into `documentations/external/redfish/schemas/v1/` AND
  `test/fixtures/redfish/schemas/` (byte-identical via `cmp`) for the
  chassis-metrics/subsystem families the 08:15 EMULATOR pins reference —
  `EnvironmentMetrics.v1_3_1`, `ThermalSubsystem.v1_3_1`,
  `ThermalMetrics.v1_3_1`, `PowerSubsystem.v1_1_1`, `PowerSupply.v1_5_3` (+
  `#PowerSupply.Reset`), `PowerSupplyMetrics.v1_1_1`, mockup-served
  `Fan.v1_5_1`, `FanCollection`, `PowerSupplyCollection`, and the
  `Redundancy.json` → `Redundancy.v1_7_1` citation chain. Property-delta
  audit: every pinned field present (excerpts resolve through
  `Sensor.v1_8_1.json` DOCS-19; FanRedundancy → `RedundantGroup` in
  `Redundancy.v1_7_1`) — no client code change. Invariant restored.
- Manifest +11 rows (SHA-256s verified); REQUIREMENTS.md "Last audited" +
  DOCS-20 audit table + corpus-note closed; `redfish_reference/README.md`
  +DOCS-20 provenance. Anchors re-verified unchanged (bmcweb `fbb307a`,
  mockup `23d21f9a`, DSP0266 1.25.0, schema index 200).
- UI-2 increment: DashboardView "No systems yet" empty state converted to the
  merged-semantics pattern — `Icons.dns_outlined` + visible text inside
  `Semantics(container + excludeSemantics)` node, no Retry. +1 widget test
  (merged label + visible text + icon). Suite 331 → 332.

**Decisions:**
- DOCS per alternation; within it, DOCS-20 exactly — the last open corpus gap,
  with the emulator pins providing precise served-type + property evidence.
- Included `Fan.v1_5_1` (mockup-served member type), `PowerSupplyMetrics
  .v1_1_1` (PSU Metrics target), and the `Redundancy` chain beyond the
  originally listed 7 — the invariant is "every published `@odata.type` for a
  client-relevant family", and these are published + client-relevant. The 36
  remaining un-mirrored published types (Certificate/Key/SecureBoot/
  USBController/…) are mockup-only breadth — documented as out of scope in the
  DOCS-20 audit table.
- No production code change for the primary work (mirror + audit only, as
  DOCS-19).
- UI increment stayed pattern-consistent (icon + merged node, no Retry — an
  empty list is not an error). No new dependencies, no TLS change.

**Next:**
- Push 79 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only.
- EMULATOR next per alternation: pin the `#PowerSupply.Reset` round-trip, the
  PowerSubsystem `Batteries` surface, or re-verify the corpus invariant against
  a fresh published-types crawl.

**Issues touched:**
- none opened/closed this run. DOCS-20 done; REQUIREMENTS.md audit + trace
  rows updated; UI-2 got the Dashboard empty-state increment; issues remain
  open.

## 2026-10-24 — agent:redfish-automation — EMULATOR (Batteries + action round-trips) + UI-2 FirmwareView empty state

**Done:**
- EMULATOR primary workstream (alternation: DOCS 10:40 → EMULATOR next). Pinned
  the **Battery surface** of the power subsystem — the last unpinned
  power-subsystem resource in the fixture:
  1. `#BatteryCollection` → `#Battery.v1_2_2` Module1 detail: Model RKS-440DC /
     Manufacturer Contoso Power / FirmwareVersion 1.00 / Status OK / ChargeState
     Idle / CapacityRatedWattHours 20 / CapacityActualWattHours 19.41 /
     MaxDischargeRateAmps 10 / StateOfHealthPercent (Reading 91 +
     `DataSourceUri` → Sensors/Battery1StateOfHealth resolving live to a
     `#Sensor` member with Reading 91) + the `#Battery.SelfTest`/
     `#Battery.Calibrate` action targets.
  2. `#BatteryMetrics.v1_0_3`: DischargeCycles 8.67, InputVoltage (Reading
     12.22 + DataSourceUri → Sensors/Battery1InputVoltage), TemperatureCelsius
     (Reading 33 + DataSourceUri → Sensors/Battery1Temp resolving live:
     Reading 33, PhysicalContext Battery), StoredEnergyWattHours 19.41,
     ChargePercent 100, CellVoltages[8] — the wired-surface shape #007/#019
     can follow battery telemetry to raw sensors (EnvironmentMetrics/
     ThermalMetrics precedent).
  3. **Action round-trip contract test**: `#Battery.SelfTest`/`#Battery.
     Calibrate` POST → 204 (mockup `/Actions/` framework serves them; client
     normalizes to `{'value': ''}`), while the **advertised
     `#PowerSupply.Reset` target POST → 404** with an empty body (its URI has
     no `/Actions/` segment the mockup implements) — client normalizes as
     `RedfishException` HTTP 404. Recorded the #022/#006 rule: advertised
     action targets are candidates, never contracts, on this fixture.
- Emulator suite 48 → **50**, green twice via `tool/emulator/run_tests.sh`
  (pin `23d21f9a` unchanged). REQUIREMENTS.md "Last audited" + Test platforms
  45 → 50 + the new pins; **new corpus gap DOCS-21** recorded in FUTUREWORK
  (Battery.v1_2_2 / BatteryMetrics.v1_0_3 / BatteryCollection have no
  versioned schema in the fixture/mirror — queue the mirror for the next DOCS
  run).
- UI-2 increment: **FirmwareView empty state** ("No firmware inventory
  reported.") converted to the established merged-semantics pattern —
  `Icons.inventory_2_outlined` + visible text inside
  `Semantics(container + excludeSemantics)` node, no Retry (a successful load
  with zero inventory is not an error). +1 widget test (merged label + visible
  text + icon + no overflow at 320/800 px). Suite 332 → 333.

**Decisions:**
- EMULATOR per alternation; within it, chose the Battery surface + action
  round-trips because (a) the 08:15 pins covered EnvironmentMetrics/
  ThermalSubsystem/PowerSupplies but never the Batteries collection the mockup
  also serves, and (b) the round-trip test produces a crisp, reproducible
  contract for #022/#006: the mockup implements ONLY action targets whose URI
  contains `/Actions/`, so `#PowerSupply.Reset` (advertised on Bay1) is a real
  404-on-POST — the PSU-reset flow must treat the advertised target as a
  candidate and normalize the 404.
- No production code change for the primary work: the pins document the wire
  contract for future work. The Battery family has no client model yet — that
  stays future #007/#019 telemetry work.
- New corpus gap DOCS-21 recorded in FUTUREWORK under P1 docs: EMULATOR mode
  stays one workstream, so the schema mirror is queued for the next DOCS run.
- UI increment stayed pattern-consistent (icon + merged node, no Retry — an
  empty inventory is not an error). No new dependencies, no TLS change.
  `dart format` drift on unrelated files was reverted to keep the diff focused
  on the 2 changed Dart files.

**Next:**
- Push 81 queued local commits once GitHub credentials are available.
- DOCS-21: mirror the Battery-family schemas (Battery.v1_2_2,
  BatteryMetrics.v1_0_3, BatteryCollection — mockup-served versions + newest
  for the delta note) into the mirror AND fixture schemas.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only (the fixture echoes the password in session bodies).

**Issues touched:**
- none opened/closed this run. EMU-2 48 → 50 recorded; #007/#019 got the
  Battery + BatteryMetrics wired-surface pins; #022/#006 got the
  `#PowerSupply.Reset` advertised-target-404 negative; DOCS-21 queued; UI-2
  got the FirmwareView empty-state increment; issues remain open.

## 2026-10-24 — agent:redfish-automation — DOCS (DOCS-21 Battery corpus) + UI-2 feature-chips empty state

**Done:**
- DOCS primary workstream (alternation: EMULATOR 09:30 → DOCS next; DOCS-21 was
  explicitly queued). Closed **DOCS-21** — the Battery corpus gap the EMU
  battery pins (48→50) exposed:
  1. Mirrored 7 files / 95,718 bytes (inside DOCS-6) into
     `documentations/external/redfish/schemas/v1/`:
     `Battery.json` aggregator, `Battery.v1_2_2.json` (**mockup-served**
     `#Battery.v1_2_2.Battery` — the Module1 detail the emulator pins +
     `#Battery.SelfTest`/`#Battery.Calibrate`/`#Battery.Reset` action defs),
     `Battery.v1_5_0.json` (newest, delta note), `BatteryCollection.json`,
     `BatteryMetrics.json` aggregator, `BatteryMetrics.v1_0_3.json`
     (**mockup-served** `#BatteryMetrics.v1_0_3.BatteryMetrics` — the
     electrical telemetry the emulator pins), `BatteryMetrics.v1_1_0.json`
     (newest, delta note).
  2. Copied the five served/aggregator files into
     `test/fixtures/redfish/schemas/` (byte-identical via `cmp`) — the
     "every published `@odata.type` for a client-relevant family has a
     versioned schema in the fixture" invariant restored for the battery
     family.
  3. Property-delta audit: every emulator-pinned field present in the served
     defs; `StateOfHealthPercent`/`TemperatureCelsius`/... are
     `Sensor*Excerpt` refs resolving through the already-mirrored
     `Sensor.v1_8_1.json` (DOCS-19); newer `Battery.v1_5_0` /
     `BatteryMetrics.v1_1_0` add only `BatteryChemistryType`/
     `EnergyStorageType`/`NominalOutputVoltage`/`ServicedDate` and
     `CRate`/`ERate` — the emulator-pinned contract holds, **no client code
     change** (battery family has no client model yet; future #007/#019).
  4. Manifest +7 rows (SHA-256s verified); REQUIREMENTS.md "Last audited" +
    EMU trace row (gap → closed) + new "DOCS-21" audit section; README
     aggregator-count note 21 → 23; `redfish_reference/README.md` +DOCS-21
     provenance. **Anchors re-verified: bmcweb advanced `fbb307a` →
     `63a18f4`** (all four mirrored docs byte-identical at the new HEAD,
     SHA-256 verified), mockup `23d21f9a` unchanged, DSP0266 1.25.0
     unchanged, schema index 200.
- UI-2 increment: **feature-chips empty state** on `SystemOverviewPage`
  ("No optional features discovered.") converted to the established
  merged-semantics pattern — `Icons.category_outlined` + visible text inside
  `Semantics(container + excludeSemantics)` node, no Retry (a successful
  discovery with zero features is not an error). `_featureChips` gained a
  `BuildContext` param. +1 widget test (merged label + visible text + icon +
  no overflow at 320 px, `addTearDown` resets the surface). Suite 333 → 334.

**Decisions:**
- DOCS per alternation; within it, DOCS-21 exactly — the last open corpus gap,
  with the EMU battery pins providing precise served-type + property evidence.
- Included the newest `Battery.v1_5_0`/`BatteryMetrics.v1_1_0` beyond the
  originally listed 3 files — the DOCS-12/13 precedent: mirror the
  mockup-served version + the newest for the delta note.
- bmcweb anchor advanced but all four mirrored docs are byte-identical — no
  refresh needed, anchors updated in README + DOCS-21 section only (historical
  audit sections keep their recorded hashes).
- UI increment stayed pattern-consistent (icon + merged node, no Retry — an
  empty feature set is not an error). The `setSurfaceSize` leak caught by the
  two dialog tests was fixed with `addTearDown(() =>
  tester.binding.setSurfaceSize(null))` — a good regression check the
  established no-overflow pattern should use going forward (the firmware test
  currently restores 800×600 manually; noted for the next UI run).
- No new dependencies, no TLS change, no production behaviour change.

**Next:**
- Push 84 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only (the fixture echoes the password in session bodies).
- EMULATOR next per alternation: candidates — re-verify the corpus invariant
  against a fresh published-types crawl (all 18 client-mapped families now
  have served+newest pairs), or pin a remaining un-pinned fixture surface;
  the `ResetActionInfo` ActionInfo-resource crawl stays a bmcweb-style code
  task (#022/#016), not pinable on the DMTF mockup.

**Issues touched:**
- none opened/closed this run. DOCS-21 done; REQUIREMENTS.md audit + trace
  rows updated; UI-2 got the feature-chips empty-state increment; issues
  remain open (#015 next P1).

## 2026-10-24 — agent:redfish-automation — EMULATOR (corpus invariant live crawl + EventDestination detail) + UI-2 inventory-loading semantics

**Done:**
- EMULATOR primary workstream (alternation: DOCS 12:30 → EMULATOR next; both
  12:30-tracking candidates executed). Suite 50 → **52** in
  `test_integration/emulator/emulator_suite_test.dart`:
  1. **Corpus invariant, live**: BFS crawl from `/redfish/v1/` following every
     relative `@odata.id` + `@Redfish.ActionInfo` link (excluding `/Actions/`
     POST-only targets; cycle-safe; graceful 404 degradation) collects every
     published `@odata.type`; the test asserts that each published type whose
     family is client-mapped (33 families enumerated) has its served-version
     schema in `test/fixtures/redfish/schemas/`. Crawl reached >50 published
     types; **zero missing** served-version schemas — the DOCS-19/20/21
     mirror work is now protected by a runnable check.
  2. **EventDestination detail** (DOCS-7 bed for #019): the four
     `EventService/Subscriptions` members pin `#EventDestination.v1_14_0`
     protocol variants — Redfish (Destination/EventTypes/Context/Protocol/
     SubscriptionType), SNMPv3 (`SNMP` block with HMAC_SHA96/CFB128_AES128 and
     null key material — secrets never on the wire), SMTP/OEM, SyslogTCP
     (`SyslogFilters[0]` LogFacilities/LowestSeverity).
- REQUIREMENTS.md: "Last audited" rewritten for the EMU run; new paragraph in
  the test-platforms block; Test platforms 50 → 52.
- UI-2 increment: `FirmwareView` inventory-loading state converted from a bare
  `Text('Loading inventory…')` to a merged `Semantics(container +
  excludeSemantics, label: 'Loading firmware inventory')` node — the
  established loading-state pattern (self-describing announcement, visible
  text preserved). +1 widget test (merged label + visible text). Suite
  334 → **335**.

**Decisions:**
- The corpus-invariant crawl import is `dart:io` `File(...).existsSync()` on
  `test/fixtures/redfish/schemas/` — the emulator suite already runs from the
  repo root (the mockup server serves the fixture from the same relative
  path), and the suite skips entirely without `REDFISH_EMULATOR_URL`, so
  plain `flutter test` never touches the filesystem check.
- Seeded `/redfish/v1/Registries/Base.1.5.0.json` explicitly because the
  registry payload is reachable only via `MessageRegistryFile.Location[0].Uri`
  (a plain string, not an `@odata.id` link) — without it the crawl would omit
  the `#MessageRegistry.v1_0_0` published type.
- Followed `@Redfish.ActionInfo` in addition to `@odata.id` so ActionInfo
  resources (SimpleUpdateActionInfo etc.) count as published types.
- No production code change for the primary work: the pins document wire +
  corpus contracts; the family list in the crawler is the executable version
  of the DOCS-19/20/21 invariant and should be kept in sync when a DOCS run
  maps a new family.
- UI increment kept pattern-consistent (merged node, no Retry — loading, not
  error). No new dependencies, no TLS change. `dart format` drift on unrelated
  files reverted to keep the diff on 3 files.

**Next:**
- Push 86 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only (the fixture echoes the password in session bodies).
- DOCS next per alternation: optionally cross-check the crawler's 33-family
  list against any future corpus additions; revisit DOCS-7 with the pinned
  EventDestination shapes (receiver still out of scope).

**Issues touched:**
- none opened/closed this run. EMU-2 50 → 52 recorded (corpus crawl +
  EventDestination); DOCS-7 bed extended; UI-2 got the inventory-loading
  increment; issues remain open (#015 next P1).

## 2026-10-24 — agent:redfish-automation — DOCS-22 freshness audit + UI-2 not-found semantics

**Done:**
- DOCS primary workstream (alternation: EMU 15:00 → DOCS next). **DOCS-22:
  frequent-family newest-version freshness audit** — extracted the newest
  published version per client-mapped family from the live DMTF schema index
  (`https://redfish.dmtf.org/schemas/v1/`, 200 OK, 3.4 MB) and compared
  against the mirrored "newest" files. **8 of 33 families had advanced
  upstream**: EnvironmentMetrics v1_3_1→v1_7_0, Fan v1_5_1→v1_6_0,
  PowerSubsystem v1_1_1→v1_2_0, PowerSupply v1_5_3→v1_8_0, PowerSupplyMetrics
  v1_1_1→v1_3_0, TaskService v1_2_1→v1_3_0, ThermalMetrics v1_3_1→v1_3_3,
  ThermalSubsystem v1_3_1→v1_5_0. Mirrored the 8 newest files into
  `documentations/external/redfish/schemas/v1/` (189,768 B total, inside
  DOCS-6; manifest rows + SHA-256s verified; fixture untouched — keeps
  mockup-served versions, DOCS-21 precedent). Property-delta audit: every
  delta additive-only (EnvironmentMetrics: AmbientTemperatureCelsius/
  BarometricPressureMm/CurrentAmps/DewPointProximityCelsius/Voltage; Fan:
  RatedSpeedRPM/RatedSecondarySpeedRPM; PowerSubsystem: Applied/Enabled/
  Links/LoadPercentThreshold/MaxRampRateWattsPerSecond/PowerBrake(+sensors)/
  TemperatureThreshold; PowerSupply: Certificates/VoltageControl;
  PowerSupplyMetrics: ChargePercent/Line*/PolyPhase*/PowerLoadPercent;
  TaskService: `#TaskService.DeleteAllCompletedTasks` + TaskMonitorAutoExpirySeconds;
  ThermalMetrics: structural no-op; ThermalSubsystem:
  FansFullSpeedOverrideEnable/Filters) — **no client code change**.
- **Provenance fix**: the DOCS-21 run advanced the bmcweb pin to `63a18f4…`
  but the manifest rows + REQUIREMENTS.md Sources block still cited `fbb307a`.
  Re-verified **live**: fetched all four bmcweb docs at `63a18f4…` HEAD, SHA-256
  byte-identical to the mirror; updated manifest rows + Sources block + anchors
  section. All anchors re-verified: bmcweb `63a18f4` (still HEAD), mockup
  `23d21f9a`, DSP0266 1.25.0 (1.26.0 probe → 404), schema index 200.
- Emulator suite re-run **52/52** (corpus invariant + EventDestination +
  battery groups all green) — served versions unchanged so the 33-family list
  stays in sync.
- UI-2 increment: `SystemOverviewPage` `System not found` fallback converted
  from a bare `Text` to the established merged `Semantics(container +
  excludeSemantics, label: 'System not found')` node + `Icons.search_off_outlined`
  (no Retry). +1 widget test (merged label + visible text + icon + 320 px
  no-overflow via `addTearDown`). Also converted the FirmwareView no-overflow
  test's manual `setSurfaceSize(800×600)` restore to `addTearDown` (the 12:30
  journal noted this for the next UI run). Suite 335 → **336**.

**Decisions:**
- DOCS per alternation; within it, DOCS-22 exactly — the corpus's newest
  versions were drifting from upstream, and the freshness audit is the
  repeatable check that keeps the DOCS-12/13/19/20/21 "newest + served" pairs
  honest.
- Newest-version files go to the **external corpus only** (fixture keeps
  mockup-served versions) — the corpus-invariant test asserts served versions,
  which are unchanged, so the crawler family list needs no edit.
- Stale-anchor fix is a pure provenance correction — byte-identical content
  means no refresh, only the citation rows change (historical audit sections
  keep their recorded hashes, per the DOCS-21 pattern).
- UI increment stayed pattern-consistent (merged node, no Retry). The
  `addTearDown` conversion matches the 12:30 run's own recommendation.
- No new dependencies, no TLS change, no production behaviour change.

**Next:**
- Push 88 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only (the fixture echoes the password in session bodies).
- EMULATOR next per alternation: candidates — re-verify the corpus invariant
  against a fresh published-types crawl, or pin a remaining un-pinned surface;
  the DOCS-22 TaskService note (`TaskMonitorAutoExpirySeconds`) is a #008/#020
  input for when the poller lands.

**Issues touched:**
- none opened/closed this run. DOCS-22 done; manifest + REQUIREMENTS.md +
  FUTUREWORK updated; UI-2 got the not-found fallback increment; issues remain
  open (#015 next P1).

## 2026-10-24 — agent:redfish-automation — EMU Bios @Redfish.Settings pin + shell not-found semantics

**Done:**
- EMULATOR primary workstream (alternation: DOCS 13:05 → EMU next). Pinned the
  **Bios `@Redfish.Settings` surface** live against the pinned `23d21f9a` mockup
  (suite 52 → **53**): `/Systems/437XR1138R2/Bios` carries the DSP0266 §9.9
  `@Redfish.Settings` payload annotation with a real settings-object **ETag**
  (`9234ac83b9700123cc32`, the fixture's only ETag-ish token — no resource-level
  `@odata.etag`/HTTP ETag header). This refines the long-held "etag behaviour
  cannot be pinned on this fixture" note: header-level ETags are absent, but the
  settings-object ETag IS pinable and is the optimistic-concurrency token a #016
  PATCH/If-Match flow sends. Also pinned: pending-settings resource
  (`Bios/Settings`, `#Bios.v1_2_2.Bios`, Id `Settings`) with attribute diff vs
  current (EmbeddedSata Raid→Ahci, ProcTurboMode Enabled→Disabled),
  `Messages[0]` `Base.1.0.SettingsFailed` + RelatedProperties from the last
  failed apply, `#Bios.ResetBios` POST → 204 (mockup `/Actions/` framework),
  `#Bios.ChangePassword` advertised-only (never round-tripped with secrets).
- REQUIREMENTS.md: "Last audited" rewritten for the EMU run; test-platforms
  block updated 52 → 53 + new Bios Settings paragraph.
- UI-2 increment: **SystemShell** `System not found` scaffold fallback converted
  from a bare `Text` to the established merged `Semantics(container +
  excludeSemantics, label: 'System not found')` node + `Icons.search_off_outlined`
  (no Retry — nonexistent system id is not an error; matches the
  SystemOverviewPage fallback from the 13:05 run). +1 widget test (merged
  `bySemanticsLabel` node + visible text + icon + 320 px no-overflow via
  `addTearDown`). Unit suite 336 → **337**.

**Decisions:**
- EMULATOR per alternation; within it chose the Bios Settings pin because it
  (a) contradicts-and-refines a long-standing "not pinable" claim with evidence,
  (b) gives #016 its first live optimistic-concurrency token, and (c) is the
  DOCS-16 §9.9 payload-annotations story continued on the wire. It is a pure
  pin; no production code change.
- ChangePassword: pin the advertised target only. The suite never sends real
  credentials; POSTing `{}` to a credential action was considered but rejected
  to keep the "no secrets in tests" rule unambiguous.
- UI increment stayed pattern-consistent (merged node, no Retry). The `addTearDown`
  surface-size restore matches the established pattern.
- Corpus: Bios/Settings published types are reached by the crawl but are NOT in
  the client-mapped family list, so no fixture-schema duty this run. Whether a
  BIOS-config feature makes them client-mapped (→ DOCS mirror + invariant) is a
  decision for the next DOCS run.

**Next:**
- Push 90 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only (the fixture echoes the password in session bodies).
- DOCS next per alternation: mirror served `Bios.v1_2_2.json` +
  `Settings.v1_3_5.json` and decide client-mapped status; otherwise rerun the
  corpus freshness audit (DOCS-22 is repeatable).

**Issues touched:**
- none opened/closed this run. EMU-2 52 → 53 recorded (Bios Settings pin +
  refinements to the etag-pinability note); UI-2 got the shell not-found
  increment; issues remain open (#015 next P1).

## 2026-10-24 — agent:redfish-automation — DOCS-23 Bios/Settings corpus + not-found fallback unification

**Done:**
- DOCS primary workstream (alternation: EMU 16:30 → DOCS next). Closed the
  corpus gap the EMU Bios-`@Redfish.Settings` pin (EMU 52→53) exposed:
  `#Bios.v1_2_2.Bios` + `#Settings.v1_3_5.Settings` were published by the
  mockup and reached by the corpus-invariant crawl, but had no versioned schema
  in the external mirror. Mirrored the served versions + the newest published
  versions (`Bios.v1_3_0.json`, `Settings.v1_5_0.json` — found on the live
  schema index) — 4 files / 67,020 bytes, inside DOCS-6; SHA-256s + manifest
  rows verified. Delta audit: Bios v1_2_2→v1_3_0 adds only `Passwords` (13→14
  props — the password-management resource superseding action-based
  ChangePassword; a #015/#026 input); Settings v1_3_5→v1_5_0 is a property
  no-op (6→6). Anchors re-verified: bmcweb `63a18f4` (still HEAD), mockup
  `23d21f9a`, DSP0266 1.25.0, schema index 200.
- **Client-mapped decision: Bios/Settings stay NOT client-mapped.** The client
  reads only `ComputerSystem.BiosVersion` (overview firmware line); no
  BIOS-config editor exists, so the corpus-invariant family list in the emulator
  test is untouched and no fixture-schema duty attaches. Recorded the candidate
  feature as **issue #028** (BIOS configuration editor, P2) with acceptance
  criteria that spell out the exact fixture duty (copy served versions into
  `test/fixtures/redfish/schemas/` + add the families to the invariant list)
  and the #016 If-Match fold.
- REQUIREMENTS.md: DOCS-23 section added (delta table + decision); the trace
  note "Bios `@Redfish.Settings` surface (pinned EMU 52→53)" now cites the real
  mirror files. README manifest + anchors section updated.
- UI-2 increment: **PowerView, SensorsView, KvmView "System not found"
  fallbacks** converted from the bare `Center(child: Text(...))` to the
  established merged `Semantics(container + excludeSemantics,
  label: 'System not found')` node + `Icons.search_off_outlined` (no Retry).
  +1 widget test per view (merged `bySemanticsLabel` node + visible text + icon
  + 320 px no-overflow via `addTearDown`). Unit suite 337 → **340**.

**Decisions:**
- DOCS per alternation; within it chose the EMU-pinned Bios/Settings gap
  because the FUTUREWORK note (from the 16:30 EMU run) explicitly scheduled it
  as the next DOCS candidate and it is small, self-contained, and closes the
  only corpus gap a 2026-10-24 pin left open.
- Newest+served mirroring, external corpus only (fixture untouched) — the
  DOCS-21 precedent; the corpus-invariant test asserts served versions, and the
  decision that Bios/Settings are NOT client-mapped keeps the 33-family list
  intact.
- Filing #028 instead of just a FUTUREWORK line: the decision needs a home with
  acceptance criteria so a future run can execute the fixture duty mechanically;
  the issue file records it (the "not client-mapped until #028" invariant).
- UI increment stayed pattern-consistent (merged node, no Retry). The three
  views were the last bare `Text('System not found')` fallbacks in the feature
  views, so the not-found pattern is now uniform across the app.
- No new dependencies, no TLS change, no production behaviour change.

**Next:**
- Push 91 queued local commits once GitHub credentials are available.
- P1 #015 AuthManager: wire `Session.expiryFromService` into login, re-auth
  when `isExpired` flips, persist token/location from create RESPONSE HEADERS
  only (the fixture echoes the password in session bodies).
- EMULATOR next per alternation: re-run the corpus-invariant crawl after any
  future family additions, or pin a remaining un-pinned surface; #028 is the
  new P2 candidate (BIOS-config editor with the exact fixture duty recorded).

**Issues touched:**
- opened: #028 (BIOS configuration editor — candidate feature making
  Bios/Settings client-mapped). DOCS-23 done; no issues closed; #015 remains
  the next P1.
