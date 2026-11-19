# Queue rf-service (enabled in phase 2)

Owns: `lib/features/kvm/kvm_service.dart`, controllers/providers, `lib/redfish/client/**`.
Verify: service tests + emulator 85/85 when `lib/` wire changes.

## Backlog (head first)

- [ ] RS-1 `KvmLaunchStrategy` + primary-selection edge cases (ties, all-disabled, mixed transports).
- [ ] RS-2 Manager-walk robustness follow-ups after the stale-404 fix (other non-auth failure modes).

## Log
