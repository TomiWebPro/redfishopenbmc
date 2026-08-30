---
id: "010"
title: "Hardening — secure storage, token isolation, theming & testing strategy"
status: open
priority: P2
type: chore
created: 2026-08-26
updated: 2026-08-30
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
