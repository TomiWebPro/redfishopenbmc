---
id: "014"
title: "Fix RedfishError to parse @Message.ExtendedInfo under the error envelope"
status: open
priority: P1
type: bug
created: 2026-08-30
updated: 2026-08-30
closed: null
assignee: unassigned
labels: [redfish-core, error-handling, spec]
estimated_tokens: 12000
---

# 014 — Fix RedfishError to parse @Message.ExtendedInfo under the error envelope

> Per DMTF DSP0266, Redfish error bodies nest everything under an `error` object: `{"error":{"code":...,"message":...,"@Message.ExtendedInfo":[...]}}`. The parser reads these keys at the top level, so on every spec-conformant BMC `extendedInfo` is `null` and real error details are silently lost.

## Description

`RedfishError.fromJson` reads `json['@Message.ExtendedInfo']` / `json['message']` / `json['code']` at the top level (`redfish_error.dart:22-24`). The caller `redfish_exception.dart:130` also passes the top-level body even though `:121-129` correctly digs into `data['error']` for the message/code. Result: structured BMC errors (the most useful diagnostics) are dropped, and the UI shows a generic "Unknown error". Lowercase fallbacks (`json['extendedInfo']`/`json['message']`) match no real Redfish key.

- Goal reference: `goal.md` §3 Correctness / fail loud on BMC errors
- User story: As a user I see the real Redfish `@Message.ExtendedInfo` (e.g. property names, severity) when an action fails.
- Scope IN: fix parser to read under `error`; pass `data['error']` from the caller; drop dead lowercase branches.
- Scope OUT: non-JSON string bodies (still report HTTP code).

## Goals / Acceptance Criteria

- [ ] `RedfishError.fromJson` parses `error['@Message.ExtendedInfo']`, `error['code']`, `error['message']`.
- [ ] `redfish_exception.dart` passes `data['error']` (or `fromJson` self-descends).
- [ ] Unit test with a compliant BMC `{"error":{...}}` body yields non-null `extendedInfo`.
- [ ] `flutter analyze` clean; tests green.

## Tasks

- [ ] Edit `lib/redfish/models/redfish_error.dart` (read under `error`).
- [ ] Edit `lib/redfish/models/redfish_exception.dart:130`.
- [ ] Add `test/redfish/models/redfish_error_test.dart` (compliant + non-compliant fixtures).

## Redfish Mapping

| Data | Field | Notes |
|------|-------|-------|
| Error envelope | `{"error":{"code","message","@Message.ExtendedInfo"}}` | DSP0266 § Response messages |
| Extended info | `error["@Message.ExtendedInfo"][].Message/MessageId/Severity/Resolution` | per-message diagnostics |

- OEM: none
- References: DMTF Redfish Specification DSP0266

## Progress Log

- 2026-08-30 — Created from triage analysis (core correctness #5). Highest-payoff fix.

## References

- `lib/redfish/models/redfish_error.dart:22-24`
- `lib/redfish/models/redfish_exception.dart:118-134`
- Related: #015

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
