---
id: "016"
title: "Add PATCH / If-Match / @odata.etag support for spec-compliant mutations"
status: open
priority: P2
type: feature
created: 2026-08-30
updated: 2026-10-25
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

- 2026-10-25 — EMU run: **(c) the `ResetActionInfo` ActionInfo-*resource* crawl LANDED** — the discovery engine now follows `@Redfish.ActionInfo` links (`_childLinks` → `_actionInfoLinks`) and captures the resources (`DiscoveryContext.actionInfos`), and `FeatureRules.supportedResetTypes` unions `Parameters[].AllowableValues` on `ResetType` as the third allow-list source (bmcweb `ResetActionInfo` shape). Unit tests (`resetTypesFromActionInfo` follows the link; `allowableValuesFromActionInfo` parses per DSP0266 §9.6.14 / `ActionInfo.v1_4_1`), engine tests (link followed + values folded; dangling 404 link degrades gracefully), live emulator pin (79/79 — crawl captures the fixture's `SimpleUpdateActionInfo`). Remaining for #016: (a) If-Match/`@odata.etag` wiring in a Boot/IndicatorLED PATCH flow + 412 unit tests (the settings-object ETag `9234ac83b9700123cc32` is the only pinable token on this fixture; header-level ETags stay unit-level), (b) Boot/IndicatorLED PATCH actions in a service + UI.
- 2026-10-24 — EMU run (20:xx): third live PATCH pin + first pending-settings round-trip — PATCH `/Bios/Settings` (`@Redfish.Settings` SettingsObject carrying the only ETag the mockup serves, `9234ac83b9700123cc32`) with an `Attributes` subset answers 204 + persists (in-memory; on-disk fixture byte-identical); the mockup IGNORES the If-Match precondition on the settings object too (a stale etag still 204s AND persists), so 412 enforcement stays unit-level and the #016/#028 client must send the settings-object ETag itself; restored in `finally`. EMU 63 → 64.
- 2026-10-24 — EMU run (20:xx): If-Match boundary: a PATCH with a stale `If-Match: "bogus-stale-etag"` header is answered 204 AND persists — the mockup never evaluates preconditions (no resource-level `@odata.etag`/HTTP ETag; only the settings-object ETag `9234ac83b9700123cc32` exists), so 412 enforcement stays unit-level and the #016 client must send the settings-object ETag itself. EMU 59 → 60.
- 2026-10-24 — EMU run (18:xx): **PATCH transport landed** — `RedfishClient.patchJson(path, body:, headers:)` (DSP0266 §6.5.2 partial-update; 204/200 normalized, non-2xx → `RedfishException`), 3 unit tests; first live PATCH pin: `Boot.BootSourceOverrideEnabled: Disabled` → 204 AND persists (in-memory; on-disk fixture byte-identical); negative: the mockup applies ANY body unvalidated (`IndicatorLED: "Bogus"` persists) so the client pre-validates against AllowableValues (400 + `@Message.ExtendedInfo` stays unit-level). EMU 57 → 59.
- 2026-10-23 — annotation-form allow-list fallback landed (16:05): `supportedResetTypes` unions `SupportedResetTypes` + `ResetType@Redfish.AllowableValues` on `#ComputerSystem.Reset`, conflation-guarded.
- 2026-10-22 — PATCH/ETag scoped; transport approach decided (Dio PUT/PATCH + If-Match).
- 2026-08-30 — Created from triage analysis (feature #15).