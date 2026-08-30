---
id: "016"
title: "Add PATCH / If-Match / @odata.etag support for spec-compliant mutations"
status: open
priority: P2
type: feature
created: 2026-08-30
updated: 2026-08-30
closed: null
assignee: unassigned
labels: [redfish-core, http, spec]
estimated_tokens: 14000
---

# 016 — Add PATCH / If-Match / @odata.etag support

> `redfish_client.dart` only implements GET/POST/DELETE. Redfish mutations such as BootSourceOverride or property updates require `PATCH` with `If-Match: <@odata.etag>` to avoid lost updates. No code reads `@odata.etag` (no accessor in `odata.dart`).

## Description

- `redfish_client.dart` exposes only `getJson`/`postJson`/`delete`; no `patchJson`.
- No `If-Match` header support; no `@odata.etag` accessor in `odata.dart`.
- Power reset (`postJson`) and `SimpleUpdate` (`postJson`) are POSTs (correct), but any PATCH-based mutation is currently impossible.

- Goal reference: `goal.md` §3 Configuration mutations
- User story: As a user I can change BMC properties (e.g. boot override) safely with optimistic-concurrency protection.
- Scope IN: `patchJson` on client; `If-Match` header plumbing; `OData.etag` accessor.
- Scope OUT: actual PATCH callers (future features).

## Goals / Acceptance Criteria

- [ ] `RedfishClient.patchJson(uri, body, {etag})` sends `PATCH` with optional `If-Match`.
- [ ] `OData` exposes `etag` (from `@odata.etag`).
- [ ] Unit tests for PATCH + conditional header.

## Tasks

- [ ] Add `patchJson` to `redfish_client.dart`.
- [ ] Add etag accessor to `lib/redfish/models/odata.dart`.
- [ ] Tests in `test/redfish/client/redfish_client_test.dart`.

## Redfish Mapping

| Feature | Endpoint | Method | Notes |
|---------|----------|--------|-------|
| Property update | `/redfish/v1/Systems/{id}` | `PATCH` | `If-Match: <@odata.etag>` required |
| Boot override | `/redfish/v1/Systems/{id}` `Boot` | `PATCH` | BootSourceOverrideTarget |

- DMTF Redfish Spec (ETag / conditional requests)

## Progress Log

- 2026-08-30 — Created from triage analysis (core correctness #9).

## References

- `lib/redfish/client/redfish_client.dart` (only GET/POST/DELETE)
- `lib/redfish/models/odata.dart`
- Related: #014

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
