# Queue rf-tooling (epic-split support — fixtures + dependency/CI)

Owns: `test/**`, `tool/**`, `test/fixtures/**`, `.github/workflows/**`, `pubspec*`.
Never writes `lib/` product code. Verify: fixture parse tests + `flutter analyze` 0 + CI verify gate.

## Backlog (head first)

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the tooling/guard half of the remaining
     cross-surface "control-safe manager source" portion of the open #009/#021 epic, mirroring
     EP-P5 / EP-T6 / LA-1. A machine-checkable invariant so no surface can reintroduce the raw
     `@odata.id` clipboard/UI-injection class CB-1 closed on the card. Pure test-only guard,
     dependency-free, never writes `lib/`. -->

- [x] EP-T8 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T8 control-safe manager-source display guard + RED→GREEN tests`; analyze 0 / 1433 passed / 1 skipped) — Control-safe manager-source display guard (closeout of the CB-1 class across all
      surfaces): added `test/tool/manager_source_display_guard_test.dart` (10 tests), a pure-Dart guard
      that scans every product `lib/**.dart` that scans product `lib/**.dart`
      (comment/string/filename aware, like `product_import_policy_test.dart`) and fails closed if
      a widget/controller interpolates a BMC-supplied `sourceManagerUri` (or an `@odata.id`-derived
      source value) directly into a user-facing `Text` / `SelectableText` / `Semantics` label or a
      `Clipboard.setData` payload without routing through the shared control-safe gate
      (`isControlSafeConsoleUri` / a `safeManagerUri` getter / `clipboardTargetUri`). It must NOT flag
      a value already routed through those gates, nor the test-only fixtures that pass literal safe
      sources. RED→GREEN proof by temporarily planting a raw source interpolation into a temp
      product-style file under a temp scan root. No live-BMC, no dependency, no `lib/` change,
      production TLS untouched; wire into `.github/workflows/verify.yml` only if the repo guard
      convention already covers `test/tool/` (do not add a second full-suite invocation).
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with RED→GREEN guard tests
              (raw interpolation → violation + nonzero exit; gated value → clean); writes limited to
              `tool/**`, `test/tool/**`, `.github/workflows/**`; never `lib/`, no dependency bump.

<!-- rf-ideate split 2026-11-19 20:47 UTC: splits the last un-split FUTUREWORK "[!] Environment
     quota blocking verification (2026-11-08)" blocker — its harness-robustness portion (the
     quota itself was transient; baselines are green). Mirrors EP-T6 / LA-1: pure tooling, no
     lib/, no dependency, no product TLS change. -->

- [x] EP-T7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-T7 emulator prerequisite doctor + RED→GREEN tests`) — Emulator prerequisite doctor (closeout of FUTUREWORK "[!] Environment quota blocking
      verification"): add a pure-Dart `tool/emulator_doctor.dart` (CLI + tests) that fails closed
      with a precise, actionable diagnostic when a required prerequisite is absent — `docker`,
      `curl`, `jq`, `redfishtool` on PATH, and the pinned local DMTF mockup fixture
      `test/fixtures/redfish/dmtf_mockup` (never a hardcoded container-internal DSP2043 path) —
      plus a `--check` mode that validates prerequisites without starting containers or any
      network/credential use. Document that `tool/emulator/run_tests.sh` remains the standard
      suite and `testing/run_emulator_harness.sh` is optional. Do not enable live-BMC, do not
      add a dependency, never weaken production TLS.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with RED→GREEN doctor tests
              (temp-PATH missing prerequisite → violation + nonzero exit; all-present → zero exit);
              `dart run tool/emulator_doctor.dart --check` names each missing prerequisite (exit 0
              only when all present — `redfishtool` is currently absent, so an actionable nonzero
              report is the correct result here); writes limited to `tool/**`, `test/tool/**`,
              `DEVELOPMENT.md`; never `lib/`.

<!-- rf-ideate split 2026-11-19 16:43 UTC (main repo): slices the one remaining un-split
     FUTUREWORK "Blocked / needs a human" item — "[!] Large spec/binary assets — if over the
     download budget, ask a human before committing; store links and hashes meanwhile" —
     into an unblocked, dependency-free tooling guard. Mirrors the earlier Live-BMC → EP-T6
     and WebView → EP-P4 splits. The other blocked items (Live BMC integration, KVM
     webview/native console) are already fully split into existing EP-* items; no code touched. -->

- [x] LA-1 Large/binary asset policy + guard (LANDED 2026-11-19, run `auto: FEATURE — LA-1 asset guard`). (closeout of FUTUREWORK "[!] Large spec/binary
      assets"): add a repo asset-reference manifest listing any large DMTF spec / binary asset by
      source URL + SHA-256 hash (never commit the binary itself), and a pure-Dart guard test that
      fails when a spec/binary asset over an agreed size threshold is added under
      `test/fixtures/**` (or the repo) without a matching manifest entry; document the "ask a
      human before committing large assets / store link + hash meanwhile" gate in `DEVELOPMENT.md`.
      No binary download, no dependency added, no `lib/` change, production TLS untouched.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with a new RED→GREEN guard
              test pinning the manifest-required-for-large-assets contract; writes limited to
              `test/**`, `tool/**`, `.github/workflows/**`, `DEVELOPMENT.md`; never `lib/`.

<!-- rf-ideate split 2026-11-19 12:37 UTC: slices the FUTUREWORK "Blocked / needs a human"
     "[!] Live BMC integration — requires real credentials/network; never attempt in the unattended
     job. Keep the live-BMC test skipped" blocker into a tooling guard. Pure CI/test work, no lib/. -->

- [x] EP-T6 LANDED 2026-11-19 (run `auto: FEATURE — EP-T6 unattended live-BMC safety guard + tests`): CI/pure-Dart guard that the blocked live-BMC epic stays unattended-safe: assert the DMTF
      emulator / live-BMC integration tests remain skipped unless an explicit env var supplies a real
      emulator URL/credentials (the existing `REDFISH_EMULATOR_URL` skip contract), that plain
      `flutter test` needs no BMC network or credentials, and document the human opt-in in
      `DEVELOPMENT.md`. Never enable live-BMC in the scheduler; no product `lib/` code.
      Dept: rf-tooling
      Verify: `flutter test test/tool/ && flutter analyze` (0 issues), with a new guard test pinning
              the skip-without-env contract (RED→GREEN proof); writes limited to `test/**`, `tool/**`,
              `.github/workflows/**`, `DEVELOPMENT.md`; never `lib/`.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 RESOLVED (external-browser + copy is the final
     route). EP-T2 (dependency scaffolding) is DEFERRED pending manual validation evidence — do NOT
     add a WebView/url_launcher dependency unattended. New head-first fixture + guard slices. -->

- [ ] EP-T4 Fixture + CI guard closeout for the final external-browser/copy route: add an OpenBMC
      Manager fixture with a GraphicalConsole (HTML5 over HTTPS) + `Oem.KVM.Uri` and a RemoteConsole
      to drive selection/guidance tests, plus a pure-Dart/CI guard asserting no `webview_flutter` /
      `url_launcher` dependency and the KVM in-app flag stays OFF unless validation evidence exists.
      No product `lib/` code.
      Dept: rf-tooling
      Verify: `flutter test test/features/kvm/ && bash tool/emulator/run_tests.sh` (85/85) `&& flutter analyze`
              (0 issues); writes limited to `test/**`, `tool/**`, `.github/workflows/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): unblocked fixture + dependency
     prep. EP-T2 gated on EP-P1. Every item carries the mandatory Dept:/Verify: fields
     (MULTI_DEPT hard rule #4). -->

- [ ] EP-T1 Fixtures for the in-app-render / selection tests: an OpenBMC `Managers/{id}` sample
      (GraphicalConsole + `Oem.KVM.Uri`) and a DMTF mockup Manager with
      `GraphicalConsole`/`RemoteConsole`, so the launch-path tests have real payloads. No product code.
      Dept: rf-tooling
      Verify: `flutter test test/features/kvm/ && bash tool/emulator/run_tests.sh` (85/85) `&& flutter analyze`
              (0 issues); writes limited to `test/fixtures/**` + `test/**`.

- [ ] EP-T2 (after EP-P1) Dependency decision + conditional-import/pubspec scaffolding, CI verify
      gate and documentation for the opt-in WebView/url_launcher path — feature-flagged, never
      weakening production TLS, with the external-browser/copy fallback kept. No product `lib/` code.
      Dept: rf-tooling
      Verify: `flutter pub get && flutter analyze` (0 issues) and the `.github/workflows/verify.yml`
              gate green; writes limited to `pubspec*`, `tool/**`, `.github/workflows/**`, docs — never `lib/`.

- [ ] EP-T3 Extend the KVM coverage gate (`tool/coverage_gate.dart`) to scope the new
      `lib/features/kvm/platform/**` adapter files once EP-P2 lands, so the ≥75% KVM gate stays
      honest for new code; pure-Dart RED→GREEN gate tests, no product `lib/` change.
      Dept: rf-tooling
      Verify: `flutter test test/tool/coverage_gate_test.dart && flutter analyze` (0 issues);
              writes limited to `tool/**` + `test/tool/**`.

## Log

- 2026-11-19 — EP-T6 LANDED (agent:redfish-automation): added `tool/unattended_guard.dart` (pure-Dart unattended-safety policy evaluator + CLI) enforcing three invariants at commit/CI time: (1) every `test_integration/**.dart` gates network on `String.fromEnvironment('REDFISH_EMULATOR_URL')` AND calls `markTestSkipped` when absent; (2) no plain `test/**.dart` references the emulator env var (`test/tool/` guard self-tests exempt); (3) no production `lib/**.dart` hard-enables `allowSelfSigned: true`. `test/tool/unattended_guard_test.dart` adds +15 RED→GREEN tests; CLI RED proof (ungated integration test in a temp dir) produced a violation + exit 1; real-repo CLI scan green (286 Dart sources). Wired into `.github/workflows/verify.yml` + documented the live-BMC human opt-in in `DEVELOPMENT.md`. No `lib/` change, no dependency, production TLS untouched.
- 2026-11-19 — LA-1 LANDED (agent:redfish-automation): added `tool/asset_guard.dart` (pure-Dart large/binary asset policy evaluator + CLI) and `tool/asset_manifest.json` (path + byte size + SHA-256 + source URL for the mirrored DSP0266 PDF and the schema index). Any binary asset over 1 MiB without a manifest entry, or with size/hash drift, fails closed (exit 1); malformed manifests fail closed (exit 2). +15 RED→GREEN pure-Dart tests in `test/tool/asset_guard_test.dart` (synthetic unlisted large binary → violation; size/hash drift; path normalization; manifest validation; real-repo manifest coverage), RED proof via a temp-dir large binary. Wired into `.github/workflows/verify.yml` + documented the "ask a human before committing large assets" gate in `DEVELOPMENT.md`. No `lib/` change, no dependency, production TLS untouched. analyze 0; full suite green.

- 2026-11-20 — EP-T9 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/launch_status_single_source_guard_test.dart` (6 tests), a test-only pure-Dart guard that derives the seven `kvmLaunchStatusText` launch-status a11y messages FROM `kvm_models.dart` at test time and fails closed if any other product `lib/features/kvm/**.dart` hardcodes one of those fragments (card↔viewer visible-text/announced-label copy drift) or redefines the shared function; also pins both launch surfaces call the shared function. Complements the RU-2 notice guard (which covers only the six shorter notice constants). 2 RED + 2 GREEN proofs, real-repo scan clean (RU-2 notice authority excluded as another copy authority); analyze 0 / 1454 passed / 1 skipped. No `lib/`, dependency, wire/fixture change, no production TLS weakening. DMTF emulator skipped (test-only, <7 days since last green 85/85). EP-T9 is a newly discovered tooling closeout slice for the still-open #009/#021 epic (RU-2 single-source invariant extended to the launch-status strings).
