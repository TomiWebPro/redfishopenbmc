# Queue rf-model (enabled in phase 2, after the epic split has ≥2 unblocked items)

Owns: `lib/features/kvm/models/**`, `lib/redfish/discovery/**`. Verify: scoped `flutter test` + RED→GREEN proof.

## Backlog (head first)

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
