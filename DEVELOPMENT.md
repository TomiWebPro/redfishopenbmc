# Development Tracking & Daily Push Contract

> Companion to `issues/README.md` + `progress/journal.md`. Every agent and human contributor must follow this.

## Principle

- **Localized tracking** — `issues/open/` + `issues/closed/` is the issue tracker. GitHub Issues are not used for this repo.
- **GitHub is a mirror** — push `code + tests + tracking` daily so history is remote and auditable.
- **Progress is mandatory** — no silent days; even `WIP` gets committed and pushed.

## What is tracked (all git-tracked)

```
issues/            # every issue file, TEMPLATE.md, issues.py, README.md
progress/
  journal.md       # daily — append only
  progress_summary.md  # weekly rollup
DEVELOPMENT.md     # this file
documentations/project_goal/goal.md  # living spec
lib/               # Flutter source
test/              # unit + widget + fixtures
pubspec.yaml / pubspec.lock
analysis_options.yaml
.github/workflows/ # CI if present
README.md / LICENSE
```

## What is NOT pushed (`.gitignore`'d)

```
.dart_tool/  build/  .flutter-plugins*  .packages
*.keystore  *.jks  .env  .env.*  credentials.json
*.log  .DS_Store  .idea/  .vscode/ (except .vscode/recommended)
coverage/lcov.info  (generated)
# never commit: passwords, tokens, private keys, BMC IPs with creds
```

`issues/` and `progress/` are **explicitly not ignored** — `!issues/` is not needed; just don't ignore them.

## Daily push ritual (even if WIP)

```bash
# end of day, every day
git status
git add lib/ test/ pubspec.yaml pubspec.lock analysis_options.yaml .github/ issues/ progress/ DEVELOPMENT.md README.md
git diff --cached --stat
git commit -m "chore: daily sync 2026-08-26 — #001 scaffold wip, #002 auth spike"
git push origin main
```

Rules:
- Push at least once per calendar day when any work occurred.
- If a P1/P2 issue closed, push the same day (don't batch).
- WIP is fine: prefix `WIP: #NNN ...` so history shows momentum.
- Never force-push `main` without explicit human approval.
- Commit messages reference issue IDs: `feat: #003 discovery engine` / `fix: #005 power poll` / `progress: #002 401 retry`.

## Progress tracking contract

### `progress/journal.md` — daily (append, never overwrite)

```markdown
## 2026-08-26 — agent:opencode — #001 #002

**Done:**
- Scaffolded flutter create, added riverpod+go_router

**Decisions:**
- Chose Riverpod over Bloc (simpler async, see DEVELOPMENT.md)

**Next:**
- Wire Dio client (#002) + mock fixtures

**Issues touched:**
- #001 in_progress 60%
- #002 opened
```

Every working session must append one `## YYYY-MM-DD` section. One line per bullet is enough, but Decisions are mandatory.

### `progress/progress_summary.md` — weekly (replace/rollup)

Updated **every time a P1/P2 closes** and at least weekly:

```markdown
# Progress Summary — week 2026-W34

**Shipped:** #001 scaffold CI green, #002 auth core
**In progress:** #003 discovery 40%
**Risks:** OpenBMC Thermal vs Sensors drift
**Metrics:** coverage 78% (target 80), analyze 0 issues
**Next milestone:** #003 #004 → dashboard slice
```

Keeps non-reader (human) in sync without reading 10 issue files.

### Per-issue `Progress Log`

Inside each `issues/open/NNN.md`:

```markdown
## Progress Log
- 2026-08-26 — Implemented Dio client, 3/5 tests green (agent:opencode)
- 2026-08-25 — Created issue
```

Mirrors journal but scoped to the issue.

## Branching

- `main` is the trunk; daily pushes go to `origin/main`.
- Feature branches optional (`feat/#NNN-short`) but must merge/PR or fast-forward to `main` within 1 day — long-lived branches are discouraged.
- Prefer small commits over one big end-of-day commit.

## Definition of Done (for closing an issue)

An issue may move `open/ → closed/` only when:

- [ ] All `## Goals / Acceptance Criteria` checked (unchecked = not done)
- [ ] `flutter analyze` zero warnings (or `dart analyze`)
- [ ] `flutter test` green (or `pytest` if applicable), coverage gate met per issue
- [ ] `Progress Log` + `progress/journal.md` + (if P1/P2) `progress_summary.md` updated
- [ ] `python3 issues/issues.py validate` passes

Close via `python3 issues/issues.py close NNN --reason "..."` then commit.

## Toolchain (record versions here)

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | **3.47.1** (channel stable, revision 6655482ec0, 2026-08-19) | installed via `git clone https://github.com/flutter/flutter.git ~/flutter --depth 1 --branch stable` (per #001 step 2); `~/flutter/bin/flutter` on PATH |
| Dart | **3.13.1** (from Flutter 3.47.1) | DevTools 2.60.0 |
| State | Riverpod 2.6.1 (chosen in #001) | alternative Bloc documented below if switched |
| Router | go_router 14.8.1 |  |
| Storage | flutter_secure_storage 9.2.4 | per-platform matrix in #010 |
| HTTP | dio 5.7.0 |  |
| JSON | json_annotation 4.9.0 + json_serializable 6.8.0 (build_runner 2.4.13) | codegen available for #002+ |
| Intl | intl 0.20.2 |  |
| Charts | fl_chart (to be added in #007) |  |
| Tests | flutter_test + mockito/http_mock_adapter (to be added in #002) |  |

Update this table when a dep is added.

## State management decision — Riverpod (chosen in #001)

`#001` evaluated **Riverpod** vs **Bloc** for app-wide state. Decision: **Riverpod**
(`flutter_riverpod`), recorded here per the issue's "decide and document" requirement.

Rationale:
- **Async-native**: Redfish is I/O heavy (HTTP, session, polling). Riverpod's
  `FutureProvider`/`StreamProvider` map directly onto `GET`/subscription without
  a manual event-sink boilerplate that Bloc requires for every async source.
- **Scoped, testable providers**: per-system state isolation (session tokens,
  cached schema, feature map) is expressed as `family` providers keyed by
  `systemId` — ideal for the multi-host model in `goal.md § Multi-System`.
- **Less ceremony**: no `Event`/`State` class pairs for simple reads; `ref.watch`
  rebuilds only dependents. Lower barrier for the many small feature slices
  (#002–#010).
- **First-class `ConsumerWidget` + `ProviderScope`**: composes cleanly with
  `go_router` shell and `flutter_secure_storage`.
- Bloc remains a documented alternative but was not chosen; if a feature needs
  explicit state-machine semantics (e.g. firmware update job FSM in #008) we can
  embed a `Cubit` inside a provider without re-architecting.

Dependency pins (see `pubspec.yaml`): `flutter_riverpod ^2.6.1`, `go_router ^14.8.1`,
`flutter_secure_storage ^9.2.4`, `dio ^5.7.0`, `json_annotation ^4.9.0`, `intl ^0.20.2`.
Codegen (`json_serializable` + `build_runner`) is available as a dev dependency
for #002+ models; the #001 scaffold uses hand-written `fromJson`/`toJson` stubs.

## Redfish dev notes

- Start at `GET /redfish/v1/`, follow `@odata.id` — never hardcode paths beyond entry points.
- Cache per-system with TTL 5min; lazy-load collections only when tab visited.
- Vendor OEM under `Oem.*` — parse defensively, log unknown.
- Low-bandwidth: stream image uploads, cap `Future.wait` concurrency 4.

## Agent startup prompt (copy-paste)

```
Read issues/README.md, progress/journal.md, progress_summary.md, then python3 issues/issues.py list --all. Pick highest P1 open, read its file, continue work, update Progress Log + journal, close via issues.py when green, push daily.
```

## History

- 2026-08-26 — Initial contract, 10 starter issues (#001–#010) scaffolded. No code yet beyond spec.
