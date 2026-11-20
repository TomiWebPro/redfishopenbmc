# Queue rf-service (enabled in phase 2)

Owns: `lib/features/kvm/kvm_service.dart`, controllers/providers, `lib/redfish/client/**`.
Verify: service tests + emulator 85/85 when `lib/` wire changes.

## Backlog (head first)

<!-- rf-ideate split 2026-11-20 04:56 UTC: splits the still-open service-manager-walk remainder of
     the #009/#021 epic into one unblocked, dependency-free, TLS-safe invariant slice. RS-4 (member
     dedup) and EP-S2 (secure-primary preference) each fixed one divergence; this pins the whole
     manager-set/identity/cardinality contract across BOTH fetch methods so the KVM surfaces cannot
     disagree about how many managers exist or which console is primary. Distinct from RS-5
     (source-identity normalization) and EP-S1 (launch-strategy edge cases). -->

- [ ] RS-6 Manager-set identity + cardinality invariant in the shared manager walk: over a matrix
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

- [ ] RS-5 Console↔capability manager-source agreement in the shared manager walk: make the
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

- 2026-11-19 21:26 — RS-4 LANDED (agent:redfish-automation, FEATURE #009/#021): `_fetchManagerBodies` now dedups `/redfish/v1/Managers` `Members` by normalized member URI (first wins), so repeated/padded/string-form manager links yield one console/capability card per physical manager; blank/non-string links already rejected, RS-2 skip semantics + wire shape unchanged. +2 RED→GREEN in-temp-fixture service tests (no committed fixture), analyze 0 / 1335 passed / 1 skipped, emulator 85/85. No dependency, no wire/TLS change.
