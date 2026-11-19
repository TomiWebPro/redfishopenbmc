# Queue rf-tooling (epic-split support — fixtures + dependency/CI)

Owns: `test/**`, `tool/**`, `test/fixtures/**`, `.github/workflows/**`, `pubspec*`.
Never writes `lib/` product code. Verify: fixture parse tests + `flutter analyze` 0 + CI verify gate.

## Backlog (head first)

<!-- rf-ideate split 2026-11-19 12:37 UTC: slices the FUTUREWORK "Blocked / needs a human"
     "[!] Live BMC integration — requires real credentials/network; never attempt in the unattended
     job. Keep the live-BMC test skipped" blocker into a tooling guard. Pure CI/test work, no lib/. -->

- [ ] EP-T6 CI/pure-Dart guard that the blocked live-BMC epic stays unattended-safe: assert the DMTF
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
