---
id: "024"
title: "profile_repository.clear() must delete per-profile password keys"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-08-30
closed: null
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

- [ ] `clear()` removes all `redfish.pw.<id>` keys.
- [ ] Behavior consistent with `removeProfile`.
- [ ] Test verifies keys gone after clear.

## Tasks

- [ ] Edit `profile_repository.dart:clear()`.
- [ ] Test in `test/features/systems/profile_repository_test.dart`.

## Redfish Mapping

- none (secure storage)

## Progress Log

- 2026-08-30 — Created from triage analysis (feature #17). See also #010.

## References

- `lib/features/systems/providers/profile_repository.dart:88,92-94`
- `lib/core/storage/secure_storage.dart`
- Related: #010, #015

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
