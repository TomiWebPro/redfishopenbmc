---
id: "014"
title: "Fix RedfishError to parse @Message.ExtendedInfo under the error envelope"
status: closed
priority: P1
type: bug
created: 2026-08-30
updated: 2026-10-22
closed: 2026-10-22
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

- [x] `RedfishError.fromJson` parses `error['@Message.ExtendedInfo']`, `error['code']`, `error['message']`.
- [x] `redfish_exception.dart` passes `data['error']` (or `fromJson` self-descends).
- [x] Unit test with a compliant BMC `{"error":{...}}` body yields non-null `extendedInfo`.
- [x] `flutter analyze` clean; tests green.

## Tasks

- [x] Edit `lib/redfish/models/redfish_error.dart` (read under `error`).
- [x] Edit `lib/redfish/models/redfish_exception.dart:130`.
- [x] Add `test/redfish/models/models_test.dart` + `test/redfish/client/auth_manager_test.dart` (compliant + non-compliant fixtures).

## Redfish Mapping

| Data | Field | Notes |
|------|-------|-------|
| Error envelope | `{"error":{"code","message","@Message.ExtendedInfo"}}` | DSP0266 § Response messages |
| Extended info | `error["@Message.ExtendedInfo"][].Message/MessageId/Severity/Resolution` | per-message diagnostics |

- OEM: none
- References: DMTF Redfish Specification DSP0266

## Progress Log

- 2026-10-22 — Implemented + closed by `redfish-automation` (EMULATOR run + #014):
  `RedfishError.fromJson` now self-descends into the DSP0266 `error` envelope
  (`{"error":{"code","message","@Message.ExtendedInfo"}}`), falling back to
  top-level keys for lenient interop. `RedfishException.fromResponse` normalizes
  any map-shaped body (String- or dynamic-keyed) and lets `RedfishError.tryParse`
  handle the envelope; the dead lowercase-only dynamic-keyed branch was removed.
  Unit tests: `test/redfish/models/models_test.dart` (envelope + noise rows) and
  `test/redfish/client/auth_manager_test.dart` (full-body `fromResponse` with
  `@Message.ExtendedInfo` diagnostics, `firstMessage` prefers `ExtendedInfo[0]`).
  EMU-5 evaluation (see REQUIREMENTS.md) confirmed unit fixtures are the right
  place for spec-conformant error bodies. All gates green (analyze 0, tests 242).
- 2026-08-30 — Created from triage analysis (core correctness #5). Highest-payoff fix.

## References

- `lib/redfish/models/redfish_error.dart:22-24`
- `lib/redfish/models/redfish_exception.dart:118-134`
- Related: #015

## Closed Criteria

- Resolution: RedfishError now parses DSP0266 error envelope; exception layer normalizes map bodies; unit tests green; analyze 0; EMU-5 evaluation confirms fixture approach
- Closed: 2026-10-22
- Follow-ups: none
