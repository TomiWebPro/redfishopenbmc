# Queue rf-model (enabled in phase 2, after the epic split has ≥2 unblocked items)

Owns: `lib/features/kvm/models/**`, `lib/redfish/discovery/**`. Verify: scoped `flutter test` + RED→GREEN proof.

## Backlog (head first)

- [ ] RM-1 Audit the enabled-state contract for the two views not yet audited: per-console
      `maxConcurrentSessions` chips + connection-type chips (cf. FUTUREWORK 2026-11-19 note:
      all four aggregate capability fields now skip disabled blocks; these two per-console
      views are the remainder).
- [ ] RM-2 Next malformed-payload tolerance gap in the KVM read path (non-map manager/console
      payloads in the capability card / manager walk), with RED→GREEN tests + fixture.

## Log
