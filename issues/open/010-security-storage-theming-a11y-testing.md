---
id: "010"
title: "Hardening — secure storage, token isolation, theming & testing strategy"
status: open
priority: P2
type: chore
created: 2026-08-26
updated: 2026-11-17
closed: null
assignee: unassigned
labels: [security, storage, theme, a11y, testing, performance]
estimated_tokens: 40000
---

# 010 — Hardening — secure storage, token isolation, theming & testing strategy

> Cross-cutting hardening: no plaintext at rest, per-system token isolation proofs, dark-mode polished theming, a11y, performance (lazy/cache/delta), and overall testing/coverage gate.

## Description

`goal.md` insists on TLS-first, keystore-backed credentials, token isolation, no plaintext passwords, plus modern dark-first UI, adaptive layouts, and perf rules (lazy-load, cache, delta polling, low-bandwidth). This issue is the quality gate that audits slices #001–#009 and closes gaps.

- Goal reference: `goal.md` § Security Requirements, § UI/UX Design Principles, § Performance Requirements, § Architecture → State + Storage
- User story: As a security reviewer I can run `flutter test` + `flutter analyze` and see proofs that tokens never leak across systems, passwords aren't persisted, TLS is enforced, theming/a11y passes, and polling is minimal.
- Scope IN: Secure storage audit, token isolation tests, TLS enforcement, theme/a11y polish, performance budget, comprehensive test coverage, docs
- Scope OUT: New Redfish features (defer to backlog after this)

## Goals / Acceptance Criteria

- [ ] **Secure storage matrix** documented in `DEVELOPMENT.md`:
  - Android: `flutter_secure_storage` → `EncryptedSharedPreferences` + `KeyStore`
  - iOS: `Keychain`
  - macOS: `Keychain`
  - Linux: `libsecret` (fallback `PlainText` warn if unavailable — document)
  - Windows: `Credential Manager`
  - Web: `Web Storage` **not** secure — warn and keep tokens memory-only with short TTL
  - Verify: audit all `SecureStorage.write` call sites, none writes `password` unless `rememberPassword==true` (and then via `SecureStorage`, never `shared_preferences`)
- [ ] **Token isolation proof** — `test/security/token_isolation_test.dart`:
  - 2 `RedfishClient` with different `systemId`, interceptor asserts `X-Auth-Token` for `bmc1` never attached to request for `bmc2`, even concurrent `Future.wait`
  - 401 on `bmc1` does not clear `bmc2` token
- [ ] **TLS-first enforcement** —
  - `RedfishClient` defaults `useTls=true`, `allowSelfSigned=false`; self-signed toggle requires explicit per-profile `allowSelfSigned:true` + UI warning banner
  - Test: self-signed BMC rejected unless toggled; http:// rejected (or warned) when `useTls` true
- [ ] **Auth regression** — re-run #002 tests in CI; add `test/security/no_plaintext_test.dart` (grep `SecureStorage` vs `SharedPreferences` — fail if password key found in prefs)
- [ ] **Theming / a11y** —
  - `ThemeData` — `light` + `dark` with `ColorScheme.fromSeed`, `useMaterial3:true`, contrast AA on cards/badges, `ThemeMode.system`
  - Text scaling up to 200% without overflow (test with `MediaQuery textScaleFactor 2.0`)
  - Semantics labels on power badge, health banner, sensor tiles, KVM launch
  - Golden/screenshot for `Overview` + `Dashboard` light/dark at `mobile/tablet/desktop`
- [ ] **Adaptive layout verification** — all main views (`Dashboard`, `Overview`, `Sensors`, `Firmware`, `KVM`) wrapped in `BreakpointBuilder`; manual checklist + widget tests for 3 widths (400, 800, 1400)
- [ ] **Performance budget** —
  - Discovery: ≤8 requests for typical OpenBMC (measured, logged debug); cache TTL 5min; delta polling skips unchanged `ETag`/identical payload
  - Sensors poll 5–10s visible / 30s background (configurable)
  - No `Future.wait` storm >4 concurrency
  - Lazy-load: `FirmwareInventory`, `Sensors` collection fetched only when tab visited
- [ ] **Testing gate** —
  - `flutter analyze` zero warnings
  - `flutter test --coverage` ≥75% lines overall, ≥80% on `redfish/` + `features/power|sensors`
  - CI badge in `README.md`
  - Docs: `DEVELOPMENT.md` testing strategy + `progress/journal.md` entry with coverage numbers

## Tasks

- [ ] Audit `lib/` for credential leakage (`grep -r password` etc.)
- [ ] Write `token_isolation_test.dart` + `no_plaintext_test.dart` + TLS tests
- [ ] Polish `lib/core/theme/app_theme.dart` + `breakpoints.dart` + semantics
- [ ] Add `test/theme/theme_test.dart` + `test/a11y/a11y_test.dart` (semantic + textScale)
- [ ] Implement performance budget checks (debug logger + perf test)
- [ ] Run `flutter analyze` + `coverage` + fix; update CI
- [ ] Update `README.md` (status → hardening), `DEVELOPMENT.md`, `progress/progress_summary.md`

## Redfish Mapping

None — quality gate, not an endpoint. Validates behavior of #002–#009.

## Progress Log

- 2026-11-17 15:11 UTC (run, agent:redfish-automation) — FEATURE slice: extended the TLS downgrade guard to raw transports. Added `_TlsDowngradeInterceptor` installed by `RedfishClient.createDioForProfile`/`_buildDio`, so the raw `dio.get/post/delete/fetch` calls the auth manager uses for session creation, logout, and 401 retry now reject a plaintext-`http` final `realUri` for a TLS-required profile (previously only `getJson`/`postJson`/`patchJson`/`delete` were guarded). `RedfishException.fromDioException` now preserves an embedded already-normalized `RedfishException`. Added 4 tests in `test/security/tls_downgrade_test.dart` (raw GET downgrade rejection, credential-bearing POST downgrade rejection via forced-downgrade adapter, plaintext opt-in profile unaffected, fromDioException preservation). Verify: analyze 0, flutter test 619 passed / 1 skipped (615 +4), issues validate OK. Remaining #010 items (perf/coverage budget, deeper credential-leak audit, broader a11y/touch-target/focus/semantics + 320px checks) still open.
- 2026-11-17 14:33 UTC (run, agent:redfish-automation) — FEATURE slice: implemented the TLS-first acceptance slice "http:// rejected when useTls true" as real transport hardening. Added `RedfishClient.assertNoTlsDowngrade(profile, effectiveUri)` (fatal `TlsDowngradeRejected` `RedfishException` when a TLS-required profile's exchange completes over plaintext `http`, e.g. an `https -> http` redirect) and wired it into `getJson`/`postJson`/`patchJson`/`delete` using `Response.realUri`. Added `test/security/tls_downgrade_test.dart` (7 tests: policy allow/reject/null/uppercase-scheme/credential-redaction + end-to-end HTTPS→HTTP redirect rejection with local self-signed HTTPS server + plain HTTP target). Verify: analyze 0, flutter test 615 passed / 1 skipped (608 +7), issues validate OK. Remaining #010 items (extend guard to `createDioForProfile`/auth-manager raw factory, perf/coverage budget, deeper credential-leak audit, broader a11y/touch-target/focus/semantics + 320px checks) still open.
- 2026-11-17 09:05 UTC (run, agent:redfish-automation) — FEATURE slice: fixed populated `DashboardView` 200% text-scale overflow at 400/800/1400px by switching the system-card grid to `SliverGridDelegateWithFixedCrossAxisCount` with `mainAxisExtent: 340`, and added populated-state 400/800/1400px adaptive-width/text-scale coverage in `test/a11y/dashboard_view_text_scale_test.dart` (tested layout/UI a11y increment for #010). Verify: analyze 0, flutter test 608 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics and adaptive-width/text-scale coverage for other main-view populated states/screens including 320px checks, perf/coverage hardening, http-rejected-when-useTls enforcement/test if safely implementable, deeper runtime credential-leak audit) still open.
- 2026-11-17 08:08 UTC (run, agent:redfish-automation) — FEATURE slice: fixed populated `OverviewView` 200% text-scale overflow at 800px/1400px by switching multi-column card grids to `SliverGridDelegateWithFixedCrossAxisCount` with `mainAxisExtent: 620`, and added 800px/1400px adaptive-width coverage in `test/a11y/overview_view_text_scale_test.dart` (tested layout/UI a11y increment for #010). Verify: analyze 0, flutter test 605 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics and adaptive-width/text-scale coverage for other main-view states/screens, perf/coverage hardening, http-rejected-when-useTls enforcement/test if safely implementable, deeper runtime credential-leak audit) still open.
- 2026-11-17 08:10 UTC (run, agent:redfish-automation) — FEATURE slice: extended `test/a11y/dashboard_view_text_scale_test.dart`, `test/a11y/kvm_view_text_scale_test.dart`, and `test/a11y/firmware_view_text_scale_test.dart` with 200% text-scaling no-overflow coverage at 800px and 1400px widths (adaptive layout verification increment for Dashboard empty state, KVM empty state, Firmware discovery-pending state). Attempted 800/1400 for populated `OverviewView` but observed RenderFlex overflow at 200% text scale; reverted those cases (UI/layout fix needed). Verify: analyze 0, flutter test 603 passed / 1 skipped, issues validate OK. Remaining #010 items (fix Overview 200% overflow at wider widths with tested layout change, broader a11y/touch-target/focus/semantics, perf/coverage hardening, http-rejected-when-useTls enforcement/test if safely implementable, deeper runtime credential-leak audit) still open.
- 2026-11-17 07:20 UTC (run, agent:redfish-automation) — FEATURE slice: extended `test/a11y/sensors_view_text_scale_test.dart` with 200% text-scaling no-overflow coverage at 800px and 1400px widths for `SensorsView` empty state (adaptive layout verification increment for #010), preserving merged "No sensor data available" semantics checks. Verify: analyze 0, flutter test 597 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics and adaptive-width/text-scale coverage on other main views/screens, perf/coverage hardening, http-rejected-when-useTls enforcement/test if safely implementable, deeper runtime credential-leak audit) still open.
- 2026-11-17 06:35 UTC (run, agent:redfish-automation) — FEATURE slice: extended `test/a11y/power_view_text_scale_test.dart` with 200% text-scaling no-overflow coverage at 800px and 1400px widths for `PowerView` (adaptive layout verification increment for #010), preserving action/guidance semantics checks. Verify: analyze 0, flutter test 595 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics and adaptive-width/text-scale coverage on other main views, perf/coverage hardening, http-rejected-when-useTls enforcement/test if safely implementable, deeper runtime credential-leak audit) still open.
- 2026-11-17 05:52 UTC (run, agent:redfish-automation) — FEATURE slice: added `test/a11y/overview_view_text_scale_test.dart` and `test/a11y/firmware_view_text_scale_test.dart` covering 200% text scaling (400px) for `OverviewView` populated data state (merged identity/header semantics preserved, no overflow) and `FirmwareView` discovery-pending "Loading firmware" state (test-only #010 a11y/text-scaling increment on main views). Verify: analyze 0, flutter test 593 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics on other main views/screens as applicable, perf/coverage hardening, http-rejected-when-useTls enforcement/test if safely implementable, deeper runtime credential-leak audit) still open.
- 2026-11-17 04:30 UTC (run, agent:redfish-automation) — FEATURE slice: added `test/a11y/kvm_view_text_scale_test.dart` covering 200% text scaling (400px) for `KvmView` "No consoles found." empty state without overflow while preserving merged semantics (test-only #010 a11y/text-scaling increment on a main view). Verify: analyze 0, flutter test 591 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics on other main views such as Overview/Firmware, perf/coverage hardening, http-rejected-when-useTls enforcement/test if applicable, deeper credential-leak/runtime audit) still open.
- 2026-11-17 03:42 UTC (run, agent:redfish-automation) — FEATURE slice: added `test/a11y/dashboard_view_text_scale_test.dart` covering 200% text scaling (400px) for `DashboardView` empty state without overflow while preserving merged "No systems yet. Tap + to add a BMC." semantics (test-only #010 a11y/text-scaling increment on a main view). Verify: analyze 0, flutter test 590 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics on other main views, perf/coverage hardening, http-rejected-when-useTls enforcement/test if applicable, deeper credential-leak/runtime audit) still open.
- 2026-11-17 00:08 UTC (run, agent:redfish-automation) — FEATURE slice: added `test/a11y/sensors_view_text_scale_test.dart` covering 200% text scaling (400px) for `SensorsView` empty state without overflow while preserving merged "No sensor data available" semantics (test-only #010 a11y/text-scaling increment on a main view). Verify: analyze 0, flutter test 589 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics on other main views, perf/coverage hardening, http-rejected-when-useTls enforcement/test if applicable, deeper credential-leak/runtime audit) still open.
- 2026-11-17 (run, agent:redfish-automation) — FEATURE slice: added `test/a11y/power_view_text_scale_test.dart` covering 200% text scaling (400px) for `PowerView` without overflow while preserving action/guidance semantics visibility (test-only #010 a11y/text-scaling increment on a main view). Verify: analyze 0, flutter test 588 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics on other main views, perf/coverage hardening, http-rejected-when-useTls enforcement/test if applicable, deeper credential-leak/runtime audit) still open.
- 2026-11-17 (run, agent:redfish-automation) — FEATURE slice: added `test/a11y/text_scale_test.dart` covering 200% text scaling (400px) for `SystemProfileForm` without overflow and preserving merged TLS-off warning semantics at 200% scale (test-only #010 a11y/text-scaling increment). Verify: analyze 0, flutter test 587 passed / 1 skipped, issues validate OK. Remaining #010 items (broader a11y/touch-target/focus/semantics on main views, perf/coverage hardening, http-rejected-when-useTls enforcement/test if applicable, deeper credential-leak/runtime audit) still open.
- 2026-11-16 (run, agent:redfish-automation) — FEATURE slice: documented the #010 secure storage matrix in `DEVELOPMENT.md` (platform backends, web memory-only/short-TTL note, keystore audit rule) and added `test/security/credential_leak_audit_test.dart` (ConnectionProfile `toString` does not expose username/password, no `SharedPreferences` persistence in `lib/`, no obvious password print/debug/log sinks). Remaining #010 items (http-rejected-when-useTls enforcement/test if applicable, broader a11y/touch-target/focus/perf/coverage gate, deeper credential-leak/runtime audit) still open.
- 2026-11-16 21:51 UTC (run, agent:redfish-automation) — FEATURE slice: added `test/security/tls_enforcement_test.dart` proving TLS-first enforcement for self-signed certificates (local HTTPS server with self-signed cert): connection rejected by default (`allowSelfSigned: false`) and accepted only when explicitly allowed per-profile. Targeted test and analyze green. Remaining #010 items (http-rejected-when-useTls enforcement/test if applicable, secure storage matrix doc in `DEVELOPMENT.md`, broader a11y/touch-target/focus/perf/coverage gate, credential-leak audit) still open.
- 2026-11-16 21:17 UTC (run, agent:redfish-automation) — FEATURE slice: added `test/security/token_isolation_test.dart` proving per-system token isolation (2 clients/systemIds, X-Auth-Token for bmc1 never attached to bmc2 even under concurrent `Future.wait`, and 401 on bmc1 does not clear/replace bmc2 token/session). Targeted+security tests green; full suite/analyze clean. Remaining #010 items (TLS enforcement/self-signed rejection tests, secure storage matrix doc, broader a11y/touch-target/focus/perf/coverage gate, credential-leak audit) still open.
- 2026-11-16 (run, agent:redfish-automation) — FEATURE slice: added `test/security/no_plaintext_test.dart` (security regression) asserting `lib/` does not use `SharedPreferences` for persistence and that remembered passwords are stored only in SecureStorage keystore keys while the persisted profile blob never contains plaintext passwords (`rememberPassword` true/false cases). Targeted: `flutter test test/security/no_plaintext_test.dart` (3 passed). Remaining #010 items (token isolation tests, TLS enforcement tests/rejection, secure storage matrix doc, theming/a11y/perf/coverage gate, broader credential-leak audit) still open.
- 2026-11-16 20:07 UTC (run, agent:redfish-automation) — FEATURE slice: added unencrypted-HTTP warning banner with merged semantics in `lib/features/systems/views/system_profile_form.dart` when TLS is disabled (hardening/TLS-first warning), and widget/a11y coverage in `test/features/systems/ui_widget_test.dart` (`disabling TLS shows an unencrypted-HTTP warning with one merged semantics node`). Adjusted existing TLS-off form submit test for taller layout. Verify: analyze 0, tests 575 passed / 1 skipped. Remaining #010 items (token isolation/no-plaintext audit tests, TLS enforcement tests/rejection, secure storage matrix doc, theming/a11y/perf/coverage gate) still open.
- 2026-08-26 — Created. Depends on #001–#009 (run last, or iterative). P2 to ensure ship criteria before 1.0.
- 2026-08-30 — STALE (triage): no Progress Log update for 4 days (>1-day threshold).

## References

- `documentations/project_goal/goal.md:242-255`, `130-178`
- `flutter_secure_storage` docs: https://pub.dev/packages/flutter_secure_storage
- OWASP MASVS Storage: https://mas.owasp.org/MASVS/
- Related: #001, #002, #003, #004, #005, #006, #007, #008, #009

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
