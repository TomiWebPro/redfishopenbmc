# Queue rf-service (enabled in phase 2)

Owns: `lib/features/kvm/kvm_service.dart`, controllers/providers, `lib/redfish/client/**`.
Verify: service tests + emulator 85/85 when `lib/` wire changes.

## Backlog (head first)

<!-- rf-ideate split 2026-11-21 01:45 UTC: splits the remaining manager-identity seam of the blocked
     #009/#021 epic into one unblocked, service-level, dependency-free, TLS-safe dept slice.
     RS-4/5/6/7 pinned member dedup, console↔capability source agreement, per-manager cardinality and
     hostile manager BODIES, but none pins the manager-ID precedence itself: `KvmService._managerId`
     keys a manager by body `Id` → `@odata.id` last segment → member-URI last segment (trim/dedup),
     and that key drives `fetchCapability(managerId)`, the card identity and the downstream session /
     eviction key. A padded/blank/numeric/bool `Id`, a CRLF/blank `@odata.id`, a missing-all-sources
     manager or a member URI with a padded/percent-encoded last segment could desync the views under
     an unstable key. Audit first; RED→GREEN only on a genuine divergence; no churn. No code touched. -->

- [x] EP-S5 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-S5 manager-identity hostile-Id resolution guard + RED->GREEN tests`, analyze 0 / 1761 passed / 1 skipped [concurrent rf-gate merge +5 mid-run]) — KvmService manager-identity resolution contract (`_managerId` / `_memberUri`) under hostile
      values: feed one in-temp mockup with a padded / blank / numeric / bool `Id`, a CRLF / whitespace
      `@odata.id`, a member URI with a padded / percent-encoded last segment, and a manager missing all
      three sources, and pin that `fetchConsoles()` / `fetchCapabilities()` / `fetchCapability(id)`
      resolve one stable, trimmed, non-hostile manager id by the documented precedence, agree across
      both surfaces, and never key a manager under a whitespace/control-bearing id. Audit first,
      RED→GREEN only on a genuine divergence, no churn; no wire/TLS change, no dependency.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` +
              `test/features/kvm/kvm_service_test.dart`; no wire/TLS change.

<!-- rf-ideate split 2026-11-20 17:10 UTC: splits the remaining controller/state-machine seam of the
     #009/#021 launch-and-selection epic into one unblocked, dependency-free, TLS-safe dept slice.
     `KvmController.load()` drives the gated view's loading/error/primary state and is stubbed in
     every widget test but never tested directly; EP-S1/S2/S3 pinned selection classification and
     RS-* pinned manager-walk tolerance, not the async load state machine (in-flight guard, error
     capture, primary clearing, re-load recovery). Audit first; fix only a genuine divergence via
     RED→GREEN; no churn. The blocked in-app route (EP-S1) stays human-gated. No code touched. -->

- [x] EP-S4 LANDED 2026-11-20 (run 2026-11-20 18:00 UTC; analyze 0 / 1684 passed / 1 skipped; 8-test gated controller state-machine contract + RED proof, no lib change): KvmController.load async state-machine contract: add a dedicated controller test pinning
      that `load()` sets `loading` while the fetch is in flight, clears a prior error, selects the
      primary via `KvmService.pickPrimary` on success and clears it when the manager walk returns no
      consoles, captures a `RedfishException` message (and a generic exception) into `KvmUiState.error`
      with `loading == false` and primary cleared instead of throwing, and that a second `load()`
      while already loading is a no-op (one fetch per cycle). Audit first; fix the FIRST genuine
      divergence via RED→GREEN service tests; do not manufacture churn where the controller already
      fails closed. No dependency, no wire/transport/TLS change, no URL opened.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_controller_test.dart test/features/kvm/kvm_service_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/kvm_controller.dart` + those named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 13:04 UTC: re-scopes the still-open launch-selection edge portion of
      the #009/#021 epic (FUTUREWORK head-first candidate EP-S1) as one unblocked, dependency-free,
      TLS-safe dept slice. RS-6 pinned manager-set identity/cardinality, EP-S2 the secure-primary
      preference, RS-7 per-member hostile-body tolerance; nothing pins the full SELECTION edge matrix
      (all-disabled / mixed transport / primary tie / no-URI / control-unsafe / flag-off fallback)
      as a single launch-safe invariant agreeing with `KvmConsole.canOpenConsole`. Audit first; fix
      only a genuine divergence via RED→GREEN; no churn. No wire/transport/TLS change, no dependency.
      No code touched. -->

- [x] EP-S3 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-S3 launch-path selection contract + RED→GREEN service tests`, analyze 0 / 1610 passed / 1 skipped) — 4-test group in `test/features/kvm/kvm_service_test.dart` pinning the `KvmService.pickPrimary` selection contract: (1) the Primary badge never lands on an unopenable console while any openable one exists (mixed disabled/URI-less/external matrix); (2) table-driven tier order secure-graphical > secure-any > openable-graphical > openable-any > graphical > first (8 cases incl. secure non-graphical over plaintext graphical, disabled-secure excluded, no-openable fallbacks); (3) a CRLF-bearing HTTPS authority is not treated as a secure primary; (4) determinism + no source-list mutation. No divergence found — selection already fails closed; regression guard with RED proof: temporarily removing `if (!console.canOpenConsole) continue;` failed 3 of 4 tests (`+1 -3`, e.g. `Expected: plain / Actual: disabled-s`), restored byte-clean (SHA `bfbe6546…` unchanged, 0 probe occurrences), backup shredded → 4/4 GREEN. No `lib/`, dependency, wire/payload/fixture/TLS change. Refines EP-S1 (the broader slice stays open for the human-gated in-app-viewer portion). Launch-path selection edge matrix for #009/#021: over a matrix of manager/console shapes
      (all-disabled, mixed secure-HTTPS + plaintext-HTTP + external-client + serial, primary ties,
      no-URI OEM, control-unsafe authority, flag-off fallback) assert `KvmService.pickPrimary` /
      `fetchPrimaryConsole` deterministically pick the single launch-safe secure-HTTPS external-open
      primary — never a disabled, plaintext-HTTP or external-client-only console when a secure one
      exists — and that every primary agrees with `KvmConsole.canOpenConsole`. Consume
      `canOpenConsole` + `kvmLaunchStatusText` as the single source of truth. Fix the FIRST real
      divergence found via RED→GREEN service tests (RS-6 already pins set identity); do not
      manufacture churn where selection already fails closed. No new dependency, no wire/TLS change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              RED→GREEN proof for any fixed divergence; emulator 85/85 only if `lib/` wire changes;
              writes limited to `lib/features/kvm/kvm_service.dart` + service tests under
              `test/features/kvm/`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 09:00 UTC: splits RS-2's still-open manager-walk robustness remainder
     (per-member hostile-body tolerance) into an unblocked service invariant slice. RS-4 (dedup) and
     RS-6 (set identity/cardinality) pin happy-path/dedup behaviour; no test pins that a single hostile
     Manager body or Members entry fails closed PER manager without blanking the whole gated screen.
     In-temp mockup only, no committed fixture, no wire-shape change, dependency-free, TLS-safe;
     distinct from RS-2 (transient HTTP failures) and RS-4/RS-6. -->

- [x] RS-7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RS-7 manager-walk per-member hostile-body tolerance + RED→GREEN tests`, analyze 0 / 1575 passed / 1 skipped) — 5-test group in `test/features/kvm/kvm_service_test.dart` over an in-temp mockup (secure graphical + SSH serial survivors; a non-map LIST body wrapped by `getJson`; an all-malformed-console-block object; hostile/blank/numeric/padded `Members` entries) pinning that both views stay populated from healthy managers, malformed/non-map bodies skip per-manager without blanking the screen, primary stays deterministic + launch-safe, and `fetchCapability` resolves survivors. No divergence found — already tolerant; regression guard against future drift. RED proof: temporarily rejecting wrapped non-map / string console blocks in `_fetchManagerBodies` failed all 5 RS-7 tests (`+0 -5`); restored byte-clean (SHA `bfbe6546…` unchanged, 0 probe occurrences) → 5/5 GREEN. No `lib/`, dependency, wire/fixture/TLS change. Manager-walk per-member hostile-body tolerance invariant: `KvmService.fetchConsoles()` /
      `fetchCapabilities()` must fail CLOSED per manager — a `/redfish/v1/Managers` `Members` array
      containing non-string / blank / hostile links, and a Manager body that decodes to a non-map or
      has a malformed GraphicalConsole / SerialConsole / Oem, must yield a stable result (skip only
      the offending manager) without throwing or blanking the whole gated KVM screen; the RS-2 skip
      semantics and the wire shape stay unchanged. Add RED→GREEN service tests over an in-temp minimal
      mockup (no committed fixture); if a fixture is needed request via rf-tooling. Dependency-free,
      no production TLS behaviour change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; emulator 85/85 only if `lib/` wire changes; writes limited to
              `lib/features/kvm/kvm_service.dart` + service tests under `test/features/kvm/`;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 04:56 UTC: splits the still-open service-manager-walk remainder of
     the #009/#021 epic into one unblocked, dependency-free, TLS-safe invariant slice. RS-4 (member
     dedup) and EP-S2 (secure-primary preference) each fixed one divergence; this pins the whole
     manager-set/identity/cardinality contract across BOTH fetch methods so the KVM surfaces cannot
     disagree about how many managers exist or which console is primary. Distinct from RS-5
     (source-identity normalization) and EP-S1 (launch-strategy edge cases). -->

- [x] RS-6 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RS-6 manager-set identity/cardinality invariant + RED→GREEN tests`, analyze 0 / 1479 passed / 1 skipped) — 3-test group in `test/features/kvm/kvm_service_test.dart` over an in-temp 4-manager mockup (duplicate/padded/plain-string members, blank/non-string members, secure graphical + SSH serial + no-URI OEM + disabled graphical) pinning identical `fetchConsoles()`/`fetchCapabilities()` manager-id sets, exactly one console + one capability per manager, and a deterministic launch-safe primary (`externalBrowser`, no in-app/self-signed, exact target). RED proof: temporarily `pickPrimary → consoles.first` → `Expected: MgrGraph / Actual: MgrDisabled`; lib restored byte-clean. No `lib/`, dependency, wire/TLS change. Manager-set identity + cardinality invariant in the shared manager walk: over a matrix
      of `/redfish/v1/Managers` payloads (0/1/many managers, duplicate + whitespace-padded +
      plain-string member links, blank/non-string members, mixed graphical/serial consoles, a
      no-URI OEM console), assert `KvmService.fetchConsoles()` and `fetchCapabilities()` always
      yield the SAME set of physical managers — exactly one console and one capability card per
      manager, with matching `managerId` — and that `fetchPrimaryConsole()`/`pickPrimary` returns a
      member of that set, deterministically, never a console the fail-closed launch plan would
      refuse. Fix the first real divergence found with RED→GREEN service tests over an in-temp
      minimal mockup (no committed fixture); do not change the wire shape or the RS-2 skip
      semantics. Dependency-free, no production TLS behaviour change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; emulator 85/85 only if `lib/` wire changes; writes limited to
              `lib/features/kvm/kvm_service.dart` + service tests under `test/features/kvm/`;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the service half of the remaining cross-surface
     "control-safe manager source" portion of the open #009/#021 epic. `KvmConsole.fromManager`
     trims/normalizes the `@odata.id` via `_uriString`, but `KvmService.fetchCapability` keys its
     capability's `sourceManagerUri` straight from raw `ODataResource(manager.body).id` — so one
     padded/blank `@odata.id` yields a clean source on the console card and a raw padded one on the
     capability card for the same manager. Dependency-free, no wire-shape/TLS change; distinct from
     EP-S1 / RS-2 (still open) and from RS-4 (duplicate Members, already landed). -->

- [x] RS-5 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RS-5 console↔capability manager-source agreement + RED→GREEN tests`, analyze 0 / 1510 passed / 1 skipped) — extracted shared `kvmManagerSource*` normalizer in new `lib/features/kvm/models/kvm_manager_source.dart` (exported from `kvm.dart` barrel), used by both `KvmConsole.fromManager` and `KvmCapability.fromManager`, replacing duplicated private trim/fallback helpers so both KVM views converge on one source identity; +6 RED→GREEN tests in `test/features/kvm/kvm_service_test.dart` (RED proof: neutering the trim failed 5 tests, restored byte-clean). No lib wire/transport change, no dependency, no production TLS weakening; emulator skipped (<7 days, pure model normalization). Console↔capability manager-source agreement in the shared manager walk: make the
      `sourceManagerUri` set on `KvmService.fetchCapability` follow the same trim / blank-reject /
      fallback contract `KvmConsole.fromManager` already applies to the same `@odata.id`, so the two
      views cannot disagree about a manager's source identity. A whitespace-padded `@odata.id` must
      not leak stray whitespace into the capability card while the console card shows it trimmed;
      a blank/non-string value must use the same `/redfish/v1/Managers/<managerId>` fallback. Add
      RED→GREEN service tests comparing `fetchCapability(id).sourceManagerUri` with the matching
      `fetchConsoles()` console's normalized source over an in-temp mockup (no committed fixture).
      Do not change the Redfish wire shape or the RS-2 skip semantics; model-only normalization,
      no new helper owned by another dept (request via `_lib-requests.md` if unavoidable).
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` + service
              tests under `test/features/kvm/`; emulator 85/85 only if `lib/` wire changes; no
              dependency, no production TLS behaviour change.

<!-- rf-ideate split 2026-11-19 20:47 UTC: carves an unblocked, dependency-free manager-walk
     robustness slice out of the #009/#021 epic (distinct from RS-2's transient-failure skip and
     EP-S2's safe-primary target). No wire/TLS change, no dependency. -->

- [x] RS-4 LANDED 2026-11-19 (run `auto: FEATURE #009/#021 RS-4 manager-member dedup + tests`). Deterministic manager-member dedup in the KVM read path: `KvmService.fetchConsoles` /
      `fetchCapabilities` must tolerate duplicate and blank `@odata.id` entries in the
      `/redfish/v1/Managers` `Members` array — dedup by normalized member URI (first occurrence
      wins), skip blank/malformed ids, and never emit duplicate console/capability cards or
      throw — with RED→GREEN service tests and the existing padded/malformed-member fixtures if
      reusable. If a new fixture is needed, request it via rf-tooling. Do not change the wire
      shape or the 404/retryable/auth skip semantics established by RS-2.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` and
              service tests under `test/features/kvm/`; emulator 85/85 only if `lib/` wire changes.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 RESOLVED (external-browser + copy is the final
     render route; no WebView). New head-first, unblocked, dependency-free, TLS-safe service slice. -->

- [ ] EP-S2 Primary-console selection for the final external-browser route: `KvmService.pickPrimary`
      / `fetchPrimaryConsole` should prefer a secure-HTTPS console as the recommended external-open
      target and never badge a disabled, plaintext-HTTP or external-client-only console as primary
      when a secure one exists; RED→GREEN service tests. No wire/TLS change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` + service
              tests under `test/features/kvm/`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): launch-selection logic.
     Unblocked, no dependency. Every item carries the mandatory Dept:/Verify: fields
     (MULTI_DEPT hard rule #4). Legacy RS-1 is refined by EP-S1. -->

- [ ] EP-S1 Launch-path selection for the in-app viewer: `KvmLaunchStrategy` classification /
      `fetchPrimaryConsole` edge cases (all-disabled, mixed transports, primary ties, flag-off
      fallback). Consume `KvmConsole.canOpenConsole` + `kvmLaunchStatusText` as the single source
      of truth; no new dependency, no wire/TLS change.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; emulator 85/85 (`tool/emulator/run_tests.sh`) only if `lib/` wire changes.

- [ ] RS-2 Manager-walk robustness follow-ups after the stale-404 fix (other non-auth failure modes,
      e.g. 5xx / timeout per member without blanking the whole gated KVM screen), with RED→GREEN
      service tests + fixture requested from rf-tooling.
      Dept: rf-service
      Verify: `flutter test test/features/kvm/kvm_service_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; writes limited to `lib/features/kvm/kvm_service.dart` and service
              test files under `test/features/kvm/`.

## Log

- 2026-11-21 03:08 UTC — EP-S5 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_service_manager_identity_test.dart` (2 tests) over one in-temp 5-manager mockup pinning the full `KvmService._managerId` precedence (`Id` → body `@odata.id` last segment → member-URI last segment, all trimmed) under hostile `Id` shapes the existing suite never covered — numeric/bool `Id` ignored → @odata.id, blank-string `Id` ignored, numeric `Id` + blank @odata.id → member-URI segment, canonical string `Id` wins over a differing @odata.id segment. Both KVM views must key the same stable, trimmed, control-free id set, no raw '42'/'true'/'false'/'   ' may become a key, and `fetchCapability(id)` resolves each. Audit found no live divergence — regression guard at a genuinely untested seam, not churn. RED proof: stringify any non-null `Id` in `_managerId` → both tests failed (`+0 -2`, raw keys leaked); restored byte-clean (SHA `bfbe6546374f…` unchanged, empty lib diff), backup shredded → 2/2 GREEN. Test-only; analyze 0 / 1761 passed / 1 skipped (pre-change baseline 1759 +2; concurrent PASS-verified rf-gate merge +5 mid-run); issues validate OK; diff --check clean; deps unchanged; emulator skipped (<7 days). No lib/TLS/dependency change.

- 2026-11-20 14:33 — RS-2 audited (agent:redfish-automation, FEATURE #009/#021, no change made): `_fetchManagerBodies` already fails closed per member on `statusCode == 404 || e.retryable` (429 / 5xx except 501 / timeout via `RedfishException.fromDioException`), and the existing `KvmService transient manager member resilience (RS-2)` test group in `test/features/kvm/kvm_service_test.dart` already pins 5xx skip on BOTH views + 401/501 propagation. No genuine transient-failure gap found, so no churn; the open RS-2 slice stays open only for a genuinely different seam (e.g. host-skip counts / retry-budget pinning) with RED→GREEN. This run landed EP-P9 instead (cross-layer authority agreement, `queues/platform.md`).
- 2026-11-19 21:26 — RS-4 LANDED (agent:redfish-automation, FEATURE #009/#021): `_fetchManagerBodies` now dedups `/redfish/v1/Managers` `Members` by normalized member URI (first wins), so repeated/padded/string-form manager links yield one console/capability card per physical manager; blank/non-string links already rejected, RS-2 skip semantics + wire shape unchanged. +2 RED→GREEN in-temp-fixture service tests (no committed fixture), analyze 0 / 1335 passed / 1 skipped, emulator 85/85. No dependency, no wire/TLS change.

- 2026-11-20 20:28 — cross-feature lifecycle parity guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): `test/features/kvm/kvm_lifecycle_parity_test.dart` (4 tests) pins that `isKvmAppBackgrounded` (`lib/features/kvm/kvm_session.dart`) agrees with `isSensorAppBackgrounded` (the #007 rule it documents mirroring) on every `AppLifecycleState` — explicit 5-state list + runtime `values` sweep, documented-semantics pin, and a source-level "same lifecycle members" check so a one-sided edit fails closed. Audit found no live divergence (both list paused/hidden/detached) — regression guard, not churn. RED proof: `hidden`→`inactive` in `isKvmAppBackgrounded` → all 4 failed (`+0 -4`); restored byte-clean, backup shredded → 4/4 GREEN. Test-only, no lib/wire/dependency/TLS change, no URL opened. analyze 0; full test green; issues validate OK; emulator skipped (<7 days since last green 85/85).
