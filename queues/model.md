# Queue rf-model (enabled in phase 2, after the epic split has ≥2 unblocked items)

Owns: `lib/features/kvm/models/**`, `lib/redfish/discovery/**`. Verify: scoped `flutter test` + RED→GREEN proof.

## Backlog (head first)

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 (platform WebView/TLS matrix) is RESOLVED —
     no embedded WebView on the available target; external-browser + copy is the final render route.
     New head-first, unblocked, dependency-free, TLS-safe dept slices of #009/#021. -->

- [ ] EP-M2 Cross-surface external-client classifier parity: ensure `KvmConsole.requiresExternalConsoleClient`
      / `externalClientProtocolLabel` (VNC/RFB/KVMIP/serial) and all `KvmCapability` transport getters
      route through the shared fail-closed gates (`isControlSafeConsoleUri` + the HTTP(S) classifiers),
      then find and fix the next ad-hoc `Uri.tryParse` with RED→GREEN tests. Read-only model work.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/models/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): dept-sized, unblocked model
     slices, head-first. Every item carries the mandatory Dept:/Verify: fields (MULTI_DEPT
     hard rule #4). Pure-model work only; no transport/TLS change, no dependency. -->

- [ ] EP-M1 Pure-model classification for the launch path: KVMIP/RFB/VNC + serial SSH/Telnet/IPMI
      external-client classification, HTTPS in-app eligibility and URI-scheme edge cases, with
      RED→GREEN tests. Read-only; no transport/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart` (incl. RED→GREEN proof) `&& flutter analyze`
              (0 issues); writes limited to `lib/features/kvm/models/**`.

- [ ] RM-1 Audit the enabled-state contract for the two views not yet audited: per-console
      `maxConcurrentSessions` chips + connection-type chips (cf. FUTUREWORK 2026-11-19 note:
      all four aggregate capability fields now skip disabled blocks; these two per-console
      views are the remainder).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart && flutter analyze` (0 issues);
              writes limited to `lib/features/kvm/models/**`.

- [ ] RM-2 Next malformed-payload tolerance gap in the KVM read path (non-map manager/console
      payloads in the capability card / manager walk), with RED→GREEN tests. If a fixture is
      needed, request it via rf-tooling (do not write `test/fixtures/**`).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart && flutter analyze` (0 issues);
              writes limited to `lib/features/kvm/models/**`.

## Log

- 2026-11-19 15:35 — EP-M2 LANDED (agent:redfish-automation, FEATURE #009/#021): extracted shared pure `isExternalClientConsoleUri` / `externalClientConsoleProtocol` in `launch_plan.dart` on the fail-closed `_controlSafeTrimmedUri` gate; `KvmConsole` delegates (ad-hoc parse removed) and `KvmCapability` gains mirroring `requiresExternalConsoleClient` / `externalClientProtocolLabel` getters — both KVM views now classify/label VNC/RFB/KVMIP/serial endpoints identically. +7 helper/model/parity tests, analyze 0 / 1248 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 14:56 — RM-1 LANDED (agent:redfish-automation, FEATURE #009/#021): `kvmOemConsoleEnabled` now honors an explicit disable on a URI-less OEM console block (fallback to the console-like block only when no URI-bearing console exists); +6 tests, analyze 0 / 1237 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 18:01 — RM-2-adjacent LANDED (agent:redfish-automation, FEATURE #009/#021): extracted pure `kvmSessionLimit(Object?)` in new `lib/features/kvm/models/kvm_session_limit.dart` (exported from the barrel) as the single source of truth for both KVM views' `MaxConcurrentSessions`; the two duplicated private parsers silently dropped an integer-valued JSON double (`4.0`) on both cards. Tolerates integral/finite/≤2^53 doubles + numeric strings, rejects fractional/non-finite/negative/blank/wrong types. 4 RED→GREEN behavioral assertions + 6 pure helper tests (+11 total); analyze 0 / 1289 passed / 1 skipped, emulator 85/85. No dependency, no TLS change. RM-2's non-map-payload portion remains open.
