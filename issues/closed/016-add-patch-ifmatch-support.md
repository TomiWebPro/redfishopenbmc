---
id: "016"
title: "Add PATCH / If-Match / @odata.etag support for spec-compliant mutations"
status: closed
priority: P2
type: feature
created: 2026-08-30
updated: 2026-10-25
closed: 2026-10-25
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

- [x] `RedfishClient.patchJson(uri, body, {etag})` sends `PATCH` with optional `If-Match`. (landed 2026-10-25 — `{etag}` quotes per RFC7232, overrides a headers `If-Match`)
- [x] `OData` exposes `etag` (from `@odata.etag`). (landed 2026-10-25 — `ODataResource.etag` accessor)
- [x] Unit tests for PATCH + conditional header. (landed 2026-10-25 — 6 unit tests: quote grammar, If-Match header, weak/pre-quoted passthrough, etag-wins, 412 classification, accessor)
- [x] **A concrete mutation feature consumes the transport** — Boot/IndicatorLED PATCH actions in a service + UI. (landed 2026-10-25 — `SystemSettingsService.setIndicatorLed` + `setBootOverride` with schema-enum / annotation allow-list pre-validation + If-Match; Overview view LED ChoiceChips + Boot-override card; 34 new unit/widget tests + 2 live emulator pins; **#016 acceptance criteria COMPLETE** — close on review)

## Tasks

- [x] Add `patchJson` to `redfish_client.dart`.
- [x] Add etag accessor to `lib/redfish/models/odata.dart`.
- [x] Tests in `test/redfish/client/redfish_client_test.dart` (auth_manager_test.dart patchJson/etag group + odata_test.dart accessor).

## Redfish Mapping

| Feature | Endpoint | Method | Notes |
|---------|----------|--------|-------|
| Property update | `/redfish/v1/Systems/{id}` | `PATCH` | `If-Match: <@odata.etag>` required |
| Boot override | `/redfish/v1/Systems/{id}` `Boot` | `PATCH` | BootSourceOverrideTarget |

- DMTF Redfish Spec (ETag / conditional requests)

## Progress Log

- 2026-10-25 — EMU run: **(b) the Boot/IndicatorLED PATCH flow LANDED in a
  service + UI — the #016 acceptance criteria are now COMPLETE.** The first
  production `patchJson` consumer: `SystemSettingsService`
  (`lib/features/overview/settings_service.dart`) —
  `setIndicatorLed(IndicatorLed)` pre-validates against the
  `ComputerSystem.v1_22_0` `IndicatorLED` schema enum (`Lit`/`Blinking`/`Off`;
  `Unknown` is deprecated → refused locally), `setBootOverride(target,
  {enabled})` pre-validates the target against the advertised
  `BootSourceOverrideTarget@Redfish.AllowableValues` annotation + the
  enabled-state against the schema enum (`Once`/`Continuous`/`Disabled`,
  defaulting `Once`); both carry the resource `@odata.etag` as `If-Match` when
  present, and a BMC that publishes no boot-target allow-list refuses the
  mutation locally (never guess — the mockup applies any body unvalidated).
  `BootSettings` model parses the served Boot block. UI: the Overview view
  "Indicator LED" card gained the writable ChoiceChips and a capability-gated
  "Boot override" card (dropdown of advertised targets + Once/Continuous +
  Apply), driven by `SystemSettingsController` + providers (the Power pattern).
  Tests: `boot_settings_test.dart` (9) + `settings_service_test.dart` (12:
  exact PATCH body + If-Match header via a method-aware mock matcher, enum/
  target/allow-list pre-validation, never-send guards, not-connected) +
  `settings_controller_test.dart` (5) + `system_settings_widget_test.dart` (8
  incl. 320/800/1300 no-overflow) — unit suite 392 → **426 passed / 1
  skipped**; emulator suite 80 → **82/82** (live service-level round-trips:
  PATCH persists into the served ComputerSystem; unlisted target rejected
  before the wire). REQUIREMENTS.md row flipped OK; #016 closed-ready on the
  next review.
- 2026-10-25 — EMU run: **(d) the Control SetPoint pre-validation rule LANDED (the "client must pre-validate" corollary of (b))** — `ControlResource.validateSetPoint` (`lib/redfish/models/control.dart`) rejects out-of-bounds prospective SetPoints before any PATCH (mockup applies ANY body value unvalidated — the EMU 60→63 negative pin), exact AllowableMin/Max boundaries pass (inclusive), per-resource bounds never leak across controls. Control became client-mapped (served `Control.v1_5_0.json` moved into the fixture + family added to the corpus-invariant list). +11 unit tests, +1 live emulator pin against the served PowerLimit/CPU1Freq ranges (79 → 80/80). Remaining for #016: (b) Boot/IndicatorLED PATCH actions in a service + UI (the transport, If-Match wiring (a), and the SetPoint pre-validation corollary (d) are all in place).
- 2026-10-25 — DOCS run: **(a) If-Match/`@odata.etag` wiring LANDED** — the transport-level acceptance criteria are now done: `RedfishClient.patchJson(..., etag:)` sends a properly-quoted `If-Match` precondition header (RFC7232 §2.3.2 entity-tag grammar — unquoted payload-form `@odata.etag` values like the settings-object token are quoted, `W/"..."` weak tags preserved; an explicit `headers` `If-Match` is overridden by `etag`), `ODataResource.etag` reads `@odata.etag` from any resource body, and `RedfishException.isPreconditionFailed` classifies 412 (non-retryable, so a stale-token caller re-fetches instead of blind-retrying). +6 unit tests (`quoteEntityTag` grammar helper; etag → quoted If-Match; weak/pre-quoted passed verbatim; etag wins over headers; 412 precondition failure; `@odata.etag` accessor). DMTF fixture boundary unchanged (pinned 2026-10-24): the mockup IGNORES If-Match and applies any body, so 412 enforcement stays unit-level. Remaining for #016: (b) Boot/IndicatorLED PATCH actions in a service + UI (the transport + precondition wiring a future flow needs are now in place).
- 2026-10-25 — EMU run: **(c) the `ResetActionInfo` ActionInfo-*resource* crawl LANDED** — the discovery engine now follows `@Redfish.ActionInfo` links (`_childLinks` → `_actionInfoLinks`) and captures the resources (`DiscoveryContext.actionInfos`), and `FeatureRules.supportedResetTypes` unions `Parameters[].AllowableValues` on `ResetType` as the third allow-list source (bmcweb `ResetActionInfo` shape). Unit tests (`resetTypesFromActionInfo` follows the link; `allowableValuesFromActionInfo` parses per DSP0266 §9.6.14 / `ActionInfo.v1_4_1`), engine tests (link followed + values folded; dangling 404 link degrades gracefully), live emulator pin (79/79 — crawl captures the fixture's `SimpleUpdateActionInfo`). Remaining for #016: (a) If-Match/`@odata.etag` wiring in a Boot/IndicatorLED PATCH flow + 412 unit tests (the settings-object ETag `9234ac83b9700123cc32` is the only pinable token on this fixture; header-level ETags stay unit-level), (b) Boot/IndicatorLED PATCH actions in a service + UI.
- 2026-10-24 — EMU run (20:xx): third live PATCH pin + first pending-settings round-trip — PATCH `/Bios/Settings` (`@Redfish.Settings` SettingsObject carrying the only ETag the mockup serves, `9234ac83b9700123cc32`) with an `Attributes` subset answers 204 + persists (in-memory; on-disk fixture byte-identical); the mockup IGNORES the If-Match precondition on the settings object too (a stale etag still 204s AND persists), so 412 enforcement stays unit-level and the #016/#028 client must send the settings-object ETag itself; restored in `finally`. EMU 63 → 64.
- 2026-10-24 — EMU run (20:xx): If-Match boundary: a PATCH with a stale `If-Match: "bogus-stale-etag"` header is answered 204 AND persists — the mockup never evaluates preconditions (no resource-level `@odata.etag`/HTTP ETag; only the settings-object ETag `9234ac83b9700123cc32` exists), so 412 enforcement stays unit-level and the #016 client must send the settings-object ETag itself. EMU 59 → 60.
- 2026-10-24 — EMU run (18:xx): **PATCH transport landed** — `RedfishClient.patchJson(path, body:, headers:)` (DSP0266 §6.5.2 partial-update; 204/200 normalized, non-2xx → `RedfishException`), 3 unit tests; first live PATCH pin: `Boot.BootSourceOverrideEnabled: Disabled` → 204 AND persists (in-memory; on-disk fixture byte-identical); negative: the mockup applies ANY body unvalidated (`IndicatorLED: "Bogus"` persists) so the client pre-validates against AllowableValues (400 + `@Message.ExtendedInfo` stays unit-level). EMU 57 → 59.
- 2026-10-23 — annotation-form allow-list fallback landed (16:05): `supportedResetTypes` unions `SupportedResetTypes` + `ResetType@Redfish.AllowableValues` on `#ComputerSystem.Reset`, conflation-guarded.
- 2026-10-22 — PATCH/ETag scoped; transport approach decided (Dio PUT/PATCH + If-Match).
- 2026-08-30 — Created from triage analysis (feature #15).
## Closed

- Resolution: PATCH/If-Match/@odata.etag transport + wiring + the Boot/IndicatorLED service+UI flow are all landed and tested (unit suite 426, emulator 82/82)
- Closed: 2026-10-25
