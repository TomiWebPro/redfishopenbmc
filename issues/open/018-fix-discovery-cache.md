---
id: "018"
title: "Fix discovery cache: forceRefresh stale replay & failed-fetch leak"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-08-30
closed: null
assignee: unassigned
labels: [redfish-core, discovery, caching]
estimated_tokens: 12000
---

# 018 — Fix discovery cache correctness

> Two cache defects: (1) `forceRefresh` still takes `previous` from `peek` so conditional 304s replay the old cached bodies — on BMCs that don't emit ETags, `forceRefresh` silently returns stale data (`discovery_engine.dart:79-91`). (2) Failed fetches are stored as `{'_error': msg}` which is a `Map<String,dynamic>` and gets copied into `bodies` on the next 304, replaying an error body as a "real" body (`:217-218`).

## Description

- `discovery_engine.dart:79-91` — `previous` is reused even on `forceRefresh`, defeating a fresh crawl.
- `discovery_engine.dart:217-218` — error placeholders leak into the replay cache and are treated as valid bodies.

- Goal reference: `goal.md` §2 Dynamic Feature Discovery
- User story: As a user a forced refresh always returns fresh data and errors are never presented as discovered features.
- Scope IN: skip stale ETag reuse on forceRefresh; exclude `_error` placeholders from `bodies` replay.
- Scope OUT: TTL policy changes.

## Goals / Acceptance Criteria

- [ ] `forceRefresh=true` does not reuse prior ETags/bodies (re-fetches unconditionally).
- [ ] `_error` entries are excluded from `bodies` replay.
- [ ] Tests cover forceRefresh-without-etag and error-then-304 sequences.

## Tasks

- [ ] Edit `discovery_engine.dart` cache assembly.
- [ ] Add `test/redfish/discovery/discovery_cache_test.dart` cases.

## Redfish Mapping

- Conditional GET `If-None-Match` (already correct at `:254-255`) — keep.
- Cache TTL 5 min (design) — keep.

## Progress Log

- 2026-08-30 — Created from triage analysis (core correctness #11).

## References

- `lib/redfish/discovery/discovery_engine.dart:74-91,217-218,254-255`
- `lib/redfish/discovery/discovery_cache.dart`
- Related: #014

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
