# Progress Summary — redfishopenbmc

> Weekly rollup — update whenever a P1/P2 closes and at least weekly. Companion to `progress/journal.md` (daily) and `issues/` (per-task).

**Project:** Redfish Multi-System Control App (Flutter) — unified Redfish/OpenBMC control plane. Spec: `documentations/project_goal/goal.md`.

## Snapshot — 2026-08-27 (scaffold + client + discovery + multi-system manager closed)

**Phase:** Feature build. #001 (Flutter scaffold + CI) CLOSED, #002 (Redfish client core) CLOSED (analyze 0, 55 tests green, 89.8% client coverage), #003 (discovery engine) CLOSED (analyze 0, 93 tests green, **91.0% discovery coverage**), #004 (multi-system manager) CLOSED (analyze 0, 145 tests green, **88.1% systems coverage**). #005 (power) now unblocked. Localized issue system + daily tracking active.

**Shipped:**
- 2026-08-26 — Localized tracker (`issues/open|closed`, `README.md`, `TEMPLATE.md`, `issues.py`) + skill (`.opencode/skills/redfish-issues/`) + `DEVELOPMENT.md` + 10 starter issues + `progress/journal.md`. Validated `issues.py list/stats/validate`.
- 2026-08-27 — **#001 P1 chore — Flutter scaffold + tooling CLOSED.** `flutter create .` (6 platforms), `lib/` layout, `pubspec.lock` pinned (`flutter_riverpod`, `go_router`, `flutter_secure_storage`, `dio`, `json_annotation`, `intl`), `analysis_options.yaml` (stricter lints, 0 issues), dark+light `ThemeData` + `ThemeMode.system`, adaptive `LayoutBuilder`/`NavigationRail`/`NavigationBar` shell, `SecureStorage` interface + `FlutterSecureStorageImpl` + `InMemoryStorage`, placeholder widget + theme tests (13/13 green), `.github/workflows/flutter-ci.yml` (analyze+test+coverage+issues-validate). Flutter 3.47.1 / Dart 3.13.1 installed at `~/flutter`.
- 2026-08-27 — **#002 P1 feature — Redfish client core CLOSED.** `RedfishClient` (TLS-first Dio: `https://{host}:{port}`, `Accept`/`OData-Version: 4.0`, 10s/30s timeouts, opt-in self-signed via platform adapter) + `createDioForProfile` factory; `AuthManager` with Basic (`Authorization: Basic`) + Session (`POST /SessionService/Sessions` → `X-Auth-Token`+`Location`, stored token-only in `SecureStorage`, 401-refresh with per-system `Future` lock, `DELETE` on logout) + `withAuth` wrapper; per-system token isolation (`Map<systemId,_SystemAuth>`); normalized `RedfishException` (+ parsed `RedfishError.details`); `Session`/`ConnectionProfile`/`RedfishError`/`RedfishException` models; `SecureStorage` interface + `InMemoryStorage` + `FlutterSecureStorageImpl`; mocked `http_mock_adapter` unit tests (`auth_manager_test`, `redfish_client_extra_test`, `http_client_config_test`, `models_test`) + `client_integration_test` stub. `flutter analyze` 0 issues, `flutter test` 55 passed / 1 skipped, `redfish/client/` coverage **89.8%**. `DEVELOPMENT.md` carries the `#002` Security notes (TLS matrix, secret-at-rest, storage backend table, error taxonomy).
- 2026-08-27 — **#004 P1 feature — Multi-system manager & dashboard CLOSED.** `ConnectionProfile`/`SystemSnapshot`/`Health`/`PowerState` models (password never in persisted blob; keystore only); `SystemManager` (`StateNotifier<SystemState>`) with `Map<id,SystemHandle>`, add/remove/update/connect/disconnect/select, `ProfileRepository` (SecureStorage, password stripped), `rehydrate()` on startup, per-system token isolation, instant context switch (no re-discover); `go_router` `/:systemId/{overview,power,sensors,firmware,kvm}` + `SystemShell` capability-gated tabs; `DashboardView` adaptive grid (1/2/3 cols) + `AggregatedStatus` banner; `SystemCard`/`HealthBadge`/`PowerBadge`; `AddSystemDialog`/`EditSystemPage`/`SystemProfileForm` with host/port validation + self-signed warning. 13 test files under `test/features/systems/`. `flutter analyze` 0 issues, `flutter test` **145 passed / 1 skipped**, `features/systems/` coverage **88.1%** (target 80).

**In Progress (open):**
- #005 P1 — Power management (NOW UNBLOCKED by #003 + #004)
- #006 P2 — System overview adaptive cards
- #007 P2 — Sensor monitoring realtime
- #008 P2 — Firmware & update management
- #009 P3 — Remote KVM
- #010 P2 — Hardening (secure storage, theming, a11y, coverage)

**Closed this week:** #001 (2026-08-27), #002 (2026-08-27), #003 (2026-08-27), #004 (2026-08-27)

**Metrics:**
- Coverage: `redfish/client/` **89.8%** (target 80), `redfish/discovery/` **91.0%** (target 85), `features/systems/` **88.1%** (target 80)
- `flutter analyze`: **0 issues**
- `flutter test`: **145 passed / 1 skipped** (live-BMC integration stub)
- Issues: 6 open / 4 closed — `python3 issues/issues.py stats`

**Risks & Decisions:**
- Choice of Riverpod vs Bloc deferred to #001 (document rationale in DEVELOPMENT.md)
- OpenBMC `Thermal` vs modern `Sensors` collection — handled via fallback in #007, fixtures to capture both
- `UpdateService` multipart vs `SimpleUpdate` — both supported in #008, stream for low-bandwidth
- `GraphicalConsole` KVM detection vs OEM — pluggable `KvmOemRegistry` in #009

**Next Milestone — Feature build (per-system capabilities):**
1. ~~#001 — `flutter create`, deps, `analysis_options.yaml`, theme shell, `.gitignore`, CI~~ DONE
2. ~~#002 — `Dio` client + `SessionService` auth + token isolation~~ DONE
3. ~~#003 — Discovery engine + `SystemFeatures` fixture tests~~ DONE
4. ~~#004 — Multi-system manager, dashboard, routing, context switch~~ DONE
5. #005 — Power management (reset/force-off/poll) — next P1
6. #006/#007/#008/#009 — overview cards, sensors, firmware, KVM tabs

**How to read this repo:**
- `issues/README.md` — workflow (open→closed, frontmatter, daily push)
- `issues/issues.py list` — current work queue
- `progress/journal.md` — daily log (most recent first)
- `DEVELOPMENT.md` — what is pushed daily and Definition of Done

---
*Next update: after #005 closes (or 2026-09-02 weekly).*
