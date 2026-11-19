# Queue rf-platform (enable FIRST — the unblocking dept)

Owns: new `lib/features/kvm/platform/**` only. Verify: `flutter analyze` 0 + targeted tests.
Hard rule: no production TLS weakening, ever. No WebView/protocol dependency without
platform validation evidence.

## Backlog (head first)

<!-- rf-ideate split 2026-11-19 20:47 UTC: unblocks the unattended-doable half of the blocked
     EP-P4 WebView closeout. EP-P4 stays human-gated (per-target validation evidence); this is
     its machine-checkable guard clause, split out so a platform builder can land a genuine
     invariant without the human gate. No dependency, no production TLS change, no WebView import. -->

- [x] EP-P5 LANDED 2026-11-19 (run `auto: FEATURE #009/#021 EP-P5 no-WebView product-import policy guard + RED→GREEN tests`) — Enforce the resolved no-embedded-WebView decision with a pure-Dart product-import
      policy guard (the unattended slice of EP-P4's guard clause): a test under
      `test/features/kvm/platform/` scans every product `lib/**.dart` and fails closed if any
      imports `webview_flutter*`, `flutter_inappwebview*`, `url_launcher*` or opens a raw
      `MethodChannel`/`EventChannel` for console rendering, and pins that `pubspec.yaml` /
      `pubspec.lock` carry no such dependency. Must not flag the existing pure
      `webview_policy.dart` / `launch_plan.dart` filenames or test-only files. The resolved
      route stays external-browser + copy with the flag OFF in production.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml pubspec.lock` (no dependency bump); no
              production TLS behaviour change; writes limited to `lib/features/kvm/platform/**`
              and `test/features/kvm/platform/**`.

<!-- rf-ideate split 2026-11-19 12:37 UTC: slices the remaining blocked/epic work in issues
     #009/#021 and the FUTUREWORK "Blocked / needs a human" section into unblocked dept items.
     EP-P1/EP-P3 are now DONE in-tree (WEBVIEW_TLS_MATRIX.md + LAUNCH_FALLBACK.md exist); this is
     the human-gate / validation-evidence closeout of the "[!] KVM webview/native console" blocker.
     No dependency, no production TLS change, no WebView import. -->

- [ ] EP-P4 Human-gated validation-evidence checklist for revisiting in-app rendering (closeout of
      FUTUREWORK "[!] KVM webview/native console — may require a platform plugin and manual device
      validation; document the decision before adding dependencies"). The no-embedded-WebView
      decision is already recorded in `WEBVIEW_TLS_MATRIX.md` / `LAUNCH_FALLBACK.md`; extend the
      platform docs with a concrete per-target (Linux/desktop/mobile) evidence checklist that must be
      satisfied BEFORE any `webview_flutter` / `url_launcher` dependency or test-only TLS opt-in is
      added (WebView availability, self-signed BMC cert handling without weakening production TLS,
      CSP/mixed-content, fullscreen + input forwarding) plus an explicit human-approval gate. Add a
      pure-Dart guard test asserting product `lib/` imports no WebView/protocol plugin. No dependency,
      no production TLS behaviour change.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml` (no dependency bump); writes limited to
              `lib/features/kvm/platform/**`.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 (this dept's unblocker) is RESOLVED — the
     WEBVIEW_TLS_MATRIX decision is no embedded WebView on the available target; external-browser +
     copy is the final route. EP-P2 is therefore DEFERRED pending manual per-target validation
     evidence — do NOT proceed unattended. New head-first closeout slice. -->

- [ ] EP-P3 Finalize the no-WebView fallback contract (EP-P1 closeout): pin a production-default
      route-table test in the existing pure helpers — disabled → copyOnly, plaintext HTTP → copyOnly
      (never external open), secure HTTPS → externalBrowser, flag-off copy fallback byte-for-byte, no
      plaintext downgrade — and record the resolved decision in `LAUNCH_FALLBACK.md`. No dependency,
      no production TLS change.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml`; writes limited to `lib/features/kvm/platform/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): in-app console rendering.
     EP-P1 is THE unblocker and gates EP-P2 / EP-U2 / EP-T2. Every item carries the mandatory
     Dept:/Verify: fields (MULTI_DEPT hard rule #4). Legacy RP-1/RP-2 are refined by EP-P1/EP-P2. -->

- [ ] EP-P1 (UNBLOCKER) WebView/TLS validation matrix for in-app BMC console rendering — decide
      whether a platform WebView can render an HTTPS BMC console on each available target
      (Linux/desktop/mobile) and how self-signed BMC certs are handled **without weakening
      production TLS** (reversible per-profile / test-only opt-in flag only). Output: the matrix
      doc + the opt-in design; this decision unblocks EP-P2, EP-U2 and EP-T2.
      Dept: rf-platform
      Verify: `test -f lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml` (no dependency bump); no production TLS behaviour change.

- [ ] EP-P2 (after EP-P1) Implement the EP-P1 opt-in platform WebView adapter under
      `lib/features/kvm/platform/**` (conditional import + test-only flag) with tests. The
      external-browser + copy fallback must keep working byte-for-byte with the flag off.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/ && flutter analyze` (0 issues); changed paths limited to
              `lib/features/kvm/platform/`; no `pubspec.yaml` change; no production TLS weakening.

## Log (one line per completed item: date + commit + note)

- 2026-11-19 23:25 — EP-P5 LANDED (agent:redfish-automation, FEATURE #009/#021): new test-only `test/features/kvm/platform/product_import_policy_test.dart` enforces the resolved no-embedded-WebView decision — 19 tests scan every product `lib/**.dart` for `webview_flutter` / `flutter_inappwebview` / `url_launcher` imports and raw `MethodChannel` / `EventChannel` console channels, plus `pubspec.yaml` / `pubspec.lock` for forbidden deps, with comment/string/filename immunity guards. 6 assertions confirmed RED pre-fix by temporarily neutering the scanner (`Expected: non-empty / Actual: []`) → GREEN after. analyze 0 / new full-suite count; no `lib/`, no dependency, no wire/transport change, no production TLS weakening. CI already runs all tests via `flutter test --coverage`.
- 2026-11-19 19:27 — EP-M1/M2 cross-surface classifier parity (agent:redfish-automation, FEATURE #009/#021): `lib/features/kvm/platform/launch_plan.dart` now fails `isExternalClientConsoleUri` closed on a degenerate label-less authority (`vnc://./`, `ssh://../`, `ipmi://%2E%2E/`) via a shared `_hasDegenerateAuthorityHost(Uri)` helper also used by the HTTP(S) classifier family; opaque authority-less URIs and the `@odata.id` clipboard fallback unaffected. +3 RED→GREEN tests (pure classifier + KvmConsole model + KvmCapability parity). analyze 0 / 1313 passed / 1 skipped; DMTF emulator 85/85 (lib changed). No dependency, no wire/transport change, no production TLS weakening.
