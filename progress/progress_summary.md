# Progress Summary — redfishopenbmc

> Weekly rollup — update whenever a P1/P2 closes and at least weekly. Companion to `progress/journal.md` (daily) and `issues/` (per-task).

**Project:** Redfish Multi-System Control App (Flutter) — unified Redfish/OpenBMC control plane. Spec: `documentations/project_goal/goal.md`.

## P1 closed — #014 (2026-10-22)

**#014 P1 — Fix RedfishError @Message.ExtendedInfo parsing — CLOSED** (by
`redfish-automation`, EMULATOR run). `RedfishError.fromJson` now self-descends
into the DSP0266 `error` envelope (`{"error":{"code","message",
"@Message.ExtendedInfo"}}`), falling back to top-level keys for lenient
interop; `RedfishException.fromResponse` normalizes any map-shaped body and
lets `RedfishError.tryParse` handle the envelope (dead lowercase
dynamic-keyed branch removed). Unit fixtures in `models_test.dart` +
`auth_manager_test.dart` prove compliant BMC bodies now yield non-null
`extendedInfo` (were silently dropped → "Unknown error"). EMU-5 evaluation
(REQUIREMENTS.md) kept spec-conformant error-path testing on unit fixtures
rather than the richer emulator. Results: `flutter analyze` 0, `flutter test`
**242 passed / 1 skipped**, issues validate OK. First P1 close since #005.

## Snapshot — 2026-08-30 (#001–#005 closed; 21 open incl. #011–#027 carve-outs)

**Phase:** Feature build. #001 (Flutter scaffold + CI) CLOSED, #002 (Redfish client core) CLOSED (analyze 0, 55 tests green, 89.8% client coverage), #003 (discovery engine) CLOSED (analyze 0, 93 tests green, **91.0% discovery coverage**), #004 (multi-system manager) CLOSED (analyze 0, 145 tests green, **88.1% systems coverage**), #005 (power) CLOSED 2026-08-27 (analyze 0, 37 power tests green, 87.4% coverage). 2026-08-30 triage carve-outs #011–#027 opened (core correctness + layering fixes). Localized issue system + daily tracking active.

**Shipped:**
- 2026-08-26 — Localized tracker (`issues/open|closed`, `README.md`, `TEMPLATE.md`, `issues.py`) + skill (`.opencode/skills/redfish-issues/`) + `DEVELOPMENT.md` + 10 starter issues + `progress/journal.md`. Validated `issues.py list/stats/validate`.
- 2026-08-27 — **#001 P1 chore — Flutter scaffold + tooling CLOSED.** `flutter create .` (6 platforms), `lib/` layout, `pubspec.lock` pinned (`flutter_riverpod`, `go_router`, `flutter_secure_storage`, `dio`, `json_annotation`, `intl`), `analysis_options.yaml` (stricter lints, 0 issues), dark+light `ThemeData` + `ThemeMode.system`, adaptive `LayoutBuilder`/`NavigationRail`/`NavigationBar` shell, `SecureStorage` interface + `FlutterSecureStorageImpl` + `InMemoryStorage`, placeholder widget + theme tests (13/13 green), `.github/workflows/flutter-ci.yml` (analyze+test+coverage+issues-validate). Flutter 3.47.1 / Dart 3.13.1 installed at `~/flutter`.
- 2026-08-27 — **#002 P1 feature — Redfish client core CLOSED.** `RedfishClient` (TLS-first Dio: `https://{host}:{port}`, `Accept`/`OData-Version: 4.0`, 10s/30s timeouts, opt-in self-signed via platform adapter) + `createDioForProfile` factory; `AuthManager` with Basic (`Authorization: Basic`) + Session (`POST /SessionService/Sessions` → `X-Auth-Token`+`Location`, stored token-only in `SecureStorage`, 401-refresh with per-system `Future` lock, `DELETE` on logout) + `withAuth` wrapper; per-system token isolation (`Map<systemId,_SystemAuth>`); normalized `RedfishException` (+ parsed `RedfishError.details`); `Session`/`ConnectionProfile`/`RedfishError`/`RedfishException` models; `SecureStorage` interface + `InMemoryStorage` + `FlutterSecureStorageImpl`; mocked `http_mock_adapter` unit tests (`auth_manager_test`, `redfish_client_extra_test`, `http_client_config_test`, `models_test`) + `client_integration_test` stub. `flutter analyze` 0 issues, `flutter test` 55 passed / 1 skipped, `redfish/client/` coverage **89.8%**. `DEVELOPMENT.md` carries the `#002` Security notes (TLS matrix, secret-at-rest, storage backend table, error taxonomy).
- 2026-08-27 — **#003 P1 feature — Discovery engine CLOSED.** `ODataResource`/`ODataLink` models; `SystemFeatures` full feature map (`copyWith`/`toJson`/`fromJson`); `feature_rules.dart` (`FeatureRules` table-driven + `DiscoveryContext`); `discovery_cache.dart` (`DiscoveryCache` TTL + `DiscoveryPersister` NoOp/InMemory); `discovery_engine.dart` (`DiscoveryEngine`: ServiceRoot → 5 seeds → concurrent cycle-safe BFS depth ≤3, ETag-aware 304 replay, graceful per-branch 404, `invalidate`, `rawTree`). Fixtures `test/fixtures/redfish/*.json` (OpenBMC bmcweb-style + DMTF minimal) + `FakeBmc` Dio-interceptor harness; `discovery_engine_test.dart` (30 cases) + `feature_rules_test` + `odata_test`. `flutter analyze` 0 issues, `flutter test` **93 passed / 1 skipped**, `redfish/discovery/` coverage **91.0%** (target 85).
- 2026-08-27 — **#004 P1 feature — Multi-system manager & dashboard CLOSED.** `ConnectionProfile`/`SystemSnapshot`/`Health`/`PowerState` models (password never in persisted blob; keystore only); `SystemManager` (`StateNotifier<SystemState>`) with `Map<id,SystemHandle>`, add/remove/update/connect/disconnect/select, `ProfileRepository` (SecureStorage, password stripped), `rehydrate()` on startup, per-system token isolation, instant context switch (no re-discover); `go_router` `/:systemId/{overview,power,sensors,firmware,kvm}` + `SystemShell` capability-gated tabs; `DashboardView` adaptive grid (1/2/3 cols) + `AggregatedStatus` banner; `SystemCard`/`HealthBadge`/`PowerBadge`; `AddSystemDialog`/`EditSystemPage`/`SystemProfileForm` with host/port validation + self-signed warning. 13 test files under `test/features/systems/`. `flutter analyze` 0 issues, `flutter test` **145 passed / 1 skipped**, `features/systems/` coverage **88.1%** (target 80).
- 2026-08-27 — **#005 P1 feature — Power management CLOSED.** `PowerService.reset` POSTs `/redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset` (Redfish `ResetType`), target resolved via discovery raw tree → known `@odata.id` → live `/redfish/v1/Systems` crawl → fallback; unsupported types rejected locally (`SystemFeatures.supportedResetTypes`); 202+`Location` accepted (task polling → #008). `PowerState`/`ResetType` enums + `PowerController` (optimistic state + non-blocking 3s/30s polling) + Riverpod `powerServiceProvider`/`powerControllerProvider` families. `PowerView` gated on `features.powerControl` (renders nothing otherwise), animated `PowerBadge` (pulse only while transitioning), destructive-styled `ResetButton`s, `ConfirmResetDialog`; error taxonomy 403/409/400 (`@Message.ExtendedInfo`). `flutter analyze` 0 issues, `flutter test` **37 power tests green**, `features/power/` coverage **87.4%** (target 80%). Full suite **182 passed / 1 skipped**.

**In Progress (open — 21):**
- #015 P1 — AuthManager: authMethod, safe logout URI, session reuse/expiry
- #027 P1 — Make project analyzable/testable (Flutter SDK uninitialized)
- #006 P2 — System overview adaptive cards
- #007 P2 — Sensor monitoring realtime
- #008 P2 — Firmware & update management
- #010 P2 — Hardening (secure storage, theming, a11y, coverage)
- #011 P2 — Relocate ConnectionProfile to core
- #016 P2 — PATCH / If-Match / @odata.etag support
- #017 P2 — Discover SessionService URI
- #018 P2 — Fix discovery cache stale replay/leak
- #019 P2 — Sensors: real-time telemetry + retry
- #020 P2 — Firmware: binary upload + task progress
- #021 P2 — KVM: remote console rendering
- #022 P2 — Power: task polling/race/error fixes (bmcweb ResetActionInfo allow-list fallback — DOCS-4)
- #024 P2 — profile_repository.clear() orphaned passwords
- #026 P2 — Resolve duplicate auth fields
- #009 P3 — Remote KVM
- #012 P3 — Consolidate DI providers
- #013 P3 — Remove dead app_breakpoints.dart
- #023 P3 — Overview: listenManual leak & async errors
- #025 P3 — Harden unsafe .first / as casts

**Closed this week:** #027 (2026-10-22 — toolchain evidence: ~/flutter/bin/flutter, analyze 0 / tests 242 green, no orphans), #014 (2026-10-22), #001 (2026-08-27), #002 (2026-08-27), #003 (2026-08-27), #004 (2026-08-27), #005 (2026-08-27)

**Metrics:**
- Coverage: `redfish/client/` **89.8%** (target 80), `redfish/discovery/` **91.0%** (target 85), `features/systems/` **88.1%** (target 80), `features/power/` **87.4%** (target 80)
- `flutter analyze`: **0 issues**
- `flutter test`: **245 passed / 1 skipped** (live-BMC integration stub; emulator suite skipped without `REDFISH_EMULATOR_URL`)
- Issues: 21 open / 7 closed — `python3 issues/issues.py stats`

**Risks & Decisions:**
- Choice of Riverpod vs Bloc deferred to #001 (document rationale in DEVELOPMENT.md)
- OpenBMC `Thermal` vs modern `Sensors` collection — handled via fallback in #007, fixtures to capture both
- `UpdateService` multipart vs `SimpleUpdate` — DOCS-4 confirmed bmcweb is HTTP-push only (`HttpPushUri`/`MultipartHttpPushUri`, no `SimpleUpdate`); #008 must add the push path
- `GraphicalConsole` KVM detection vs OEM — DOCS-4 fixed the bare-`Oem` false positive; OEM consoles require a console-like marker (`Kvm`/`*console*` key)
- `ResetActionInfo` vs system `SupportedResetTypes` — bmcweb uses ActionInfo; add fallback in #022/#016

**Next Milestone — Feature build (per-system capabilities):**
1. ~~#001 — `flutter create`, deps, `analysis_options.yaml`, theme shell, `.gitignore`, CI~~ DONE
2. ~~#002 — `Dio` client + `SessionService` auth + token isolation~~ DONE
3. ~~#003 — Discovery engine + `SystemFeatures` fixture tests~~ DONE
4. ~~#004 — Multi-system manager, dashboard, routing, context switch~~ DONE
5. ~~#005 — Power management (reset/force-off/poll)~~ DONE
6. #006/#007/#008/#009 — overview cards, sensors, firmware, KVM tabs

**How to read this repo:**
- `issues/README.md` — workflow (open→closed, frontmatter, daily push)
- `issues/issues.py list` — current work queue
- `progress/journal.md` — daily log (most recent first)
- `DEVELOPMENT.md` — what is pushed daily and Definition of Done

---
*Next update: after next P1/P2 closes (or 2026-09-02 weekly).*
