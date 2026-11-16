---
id: "024"
title: "profile_repository.clear() must delete per-profile password keys"
status: closed
priority: P2
type: bug
created: "2026-08-30"
updated: 2026-11-16
closed: 2026-11-16
assignee: unassigned
labels: [security, storage, credentials]
estimated_tokens: 8000
---
# 024 — profile_repository.clear() orphans credentials

> `profile_repository.dart:92-94` `clear()` deletes only the profile blob key (`redfish.profiles`) and does NOT delete per-profile password keys (`redfish.pw.<id>`). Remembered passwords remain in the secure keystore after a clear. `removeProfile` (`:88`) does delete them — inconsistent.

## Description

- `clear()` leaves `redfish.pw.<id>` entries behind.
- Security: orphaned credentials persist after "clear all".

- Goal reference: `goal.md` § Security — secrets only in secure storage
- User story: As a user clearing all profiles also wipes their stored passwords.
- Scope IN: `clear()` iterates and deletes `redfish.pw.<id>` for each profile.
- Scope OUT: storage backend changes.

## Goals / Acceptance Criteria

- [x] `clear()` removes all `redfish.pw.<id>` keys.
- [x] Behavior consistent with `removeProfile`.
- [x] Test verifies keys gone after clear.

## Tasks

- [x] Edit `profile_repository.dart:clear()`.
- [x] Test in `test/features/systems/profile_repository_test.dart`.

## Redfish Mapping

- none (secure storage)

## Progress Log

- 2026-11-16 — `SecureStorageProfileRepository.clear()` now deletes per-profile remembered-password keys for all stored profiles (consistent with `removeProfile`), and added regression test verifying blob + all `redfish.pw.<id>` keys removed.
- 2026-08-30 — Created from triage analysis (feature #17). See also #010.

## References

- `lib/features/systems/providers/profile_repository.dart:88,92-94`
- `lib/core/storage/secure_storage.dart`
- Related: #010, #015

## Closed Criteria

- Resolution: clear() now deletes all per-profile remembered-password keys (consistent with removeProfile) with regression test
- Closed: 2026-11-16


- Resolution: `clear()` loads existing profiles and deletes each remembered-password key before leaving storage cleared; behavior aligned with `removeProfile`.
- Closed reason: Acceptance criteria met with regression test coverage.
- Follow-ups: none
