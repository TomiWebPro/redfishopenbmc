---
id: "028"
title: "BIOS configuration editor (Bios/Settings surface)"
status: open
priority: P2
type: feature
created: 2026-10-24
updated: 2026-10-24
closed: null
assignee: unassigned
labels: [docs,emulator]
estimated_tokens: 30000
---
# 028 — BIOS configuration editor (Bios/Settings surface)

> Candidate feature recorded by the DOCS-23 run (2026-10-24). The EMU-2 Bios
> `@Redfish.Settings` pin (EMU 52→53) + the DOCS-23 mirror give the full
> served/newest schema pair for `Bios`/`Settings`; the only open question was
> whether a BIOS-config feature makes these families **client-mapped**. This
> issue is that feature. Until it lands, `Bios`/`Settings` remain NOT
> client-mapped (the corpus-invariant family list in
> `test_integration/emulator/emulator_suite_test.dart` is untouched).

## Description

The DMTF mockup (`/Systems/437XR1138R2/Bios`) serves a `#Bios.v1_2_2.Bios`
resource with a `@Redfish.Settings` (§9.9) payload annotation carrying a real
**settings-object ETag** (`9234ac83b9700123cc32`) — the fixture's only
ETag-ish token and exactly the optimistic-concurrency token a #016
PATCH/If-Match flow must send. The pending-settings object (`Bios/Settings`)
differs from the current attribute set (EmbeddedSata Raid→Ahci, ProcTurboMode
Enabled→Disabled), `Messages[0]` carries `Base.1.0.SettingsFailed` +
RelatedProperties from the last failed apply, and the actions
`#Bios.ResetBios` (POST 204) / `#Bios.ChangePassword` (advertised) are served.

Implementing a BIOS-config editor means the client reads/patches the Bios +
Settings surface, which pulls both families into the DOCS-19/20/21 fixture
invariant: copy the served versions
(`Bios.v1_2_2.json`, `Settings.v1_3_5.json`) into
`test/fixtures/redfish/schemas/` (byte-identical, `cmp`-verified) and add
`Bios`/`Settings` to the client-mapped family list in the emulator
corpus-invariant test so every published `@odata.type` is covered.

- Goal reference: §2 Dynamic Feature Discovery / §1 Multi-system control (new
  capability surface), `documentations/project_goal/goal.md`
- User story: As an administrator I can view and change BIOS attributes
  (pending vs current) so that I can configure a server without rebooting into
  setup.
- Scope: **in** — Bios resource read (AttributeRegistry, Attributes),
  `@Redfish.Settings` object + ETag surface, pending-vs-current compare,
  PATCH via #016 If-Match with the settings ETag, ResetBios action. **out** —
  `ChangePassword` credential flows (must stay never-round-tripped with real
  secrets); firmware-level flashing.

## Goals / Acceptance Criteria

- [ ] `Bios`/`Settings` become client-mapped families: served schema versions
      copied into `test/fixtures/redfish/schemas/` +
      `documentations/external/redfish/schemas/v1/` and added to the emulator
      corpus-invariant family list (suite stays green)
- [ ] Bios model parses AttributeRegistry + Attributes + `@Redfish.Settings`
      (SettingsObject ETag, Messages, RelatedProperties, pending-vs-current
      attribute diff)
- [ ] PATCH/If-Match flow sends the settings-object ETag (fold #016); unit
      tests for the header + 412/`Precondition Failed` mapping
- [ ] `#Bios.ResetBios` POST surfaces as an action with busy/disabled states
      (UI-5 pattern) and normalizes error envelopes (DSP0266 §8.6, #014)
- [ ] Capability-gated UI: no Bios tab/controls when the resource/feature is
      absent
- [ ] Widget tests: no overflow at 320 / 800 / 1300 px; merged semantics
      labels (UI-2 pattern)
- [ ] Tests pass (`flutter analyze` 0, `flutter test` green)
- [ ] Docs updated (`progress/journal.md`, `progress_summary.md`; REQUIREMENTS.md
      row goes OK/GAP→implemented)

## Tasks

- [ ] Mirror fixture duty: `cp` served `Bios.v1_2_2.json` +
      `Settings.v1_3_5.json` into `test/fixtures/redfish/schemas/`, add the two
      families to the client-mapped list in
      `test_integration/emulator/emulator_suite_test.dart` (the DOCS-23 note
      records the exact files/hashes)
- [ ] Model + service: `lib/features/bios/` (`BiosResource`, settings ETag,
      attributes), follow the `SensorsService`/`OverviewService` feature-folder
      pattern (Riverpod providers, Dio, `RedfishClient`)
- [ ] PATCH/If-Match wiring with the settings ETag (requires #016
      transport); error mapping for 412
- [ ] View: capability-gated card/tab in the system shell
- [ ] Tests: model + service + widget (incl. 320/800/1300) + emulator pin for
      the current-vs-pending compare

## Redfish Mapping

| Feature | Endpoint | Method | Schema / Notes |
|---------|----------|--------|----------------|
| Bios resource | `/redfish/v1/Systems/{id}/Bios` | `GET` | `Bios.v1_2_2.json` (served) / `Bios.v1_3_0.json` (newest: adds `Passwords`) |
| Settings annotation | `Bios.@Redfish.Settings` | `GET` | `Settings.v1_3_5.json` (served) / `Settings.v1_5_0.json` (newest) — DSP0266 §9.9.4 |
| Pending settings | `Bios/Settings` | `GET`/`PATCH` | settings-object ETag; #016 If-Match input |
| Reset BIOS | `Bios/Actions/Bios.ResetBios` | `POST` | mockup returns 204 (no task monitor) |
| Change password | `Bios/Actions/Bios.ChangePassword` | `POST` | **advertised only** — never round-tripped with real secrets |

- OData traversal: service root → Systems → `Bios` link; `SettingsObject`
  link on the annotation
- OEM extensions: `AttributeRegistry` string (`BiosAttributeRegistryP89.v1_0_0`
  on the mockup) — vendor registry, not a schema file
- Polling / caching strategy: none initially (read-on-demand); a pending
  settings compare just needs the two GETs

## Progress Log

<!-- Append timestamped notes as you work. Most recent first. -->

- 2026-10-24 — Created from the DOCS-23 client-mapped decision. The EMU-2
  Bios `@Redfish.Settings` pin (EMU 52→53) + DOCS-23 corpus mirror
  (`Bios.v1_2_2`/`v1_3_0`, `Settings.v1_3_5`/`v1_5_0`) provide the full
  served/newest pair; served versions are in the external corpus but NOT the
  fixture until this feature makes the families client-mapped.
- YYYY-MM-DD — ...

## References

- `documentations/external/redfish/schemas/v1/Bios.v1_2_2.json` /
  `Bios.v1_3_0.json` / `Settings.v1_3_5.json` / `Settings.v1_5_0.json` (DOCS-23)
- `documentations/external/redfish/REQUIREMENTS.md` — DOCS-23 section + trace
  note "Bios `@Redfish.Settings` surface (pinned EMU 52→53)"
- DMTF Redfish spec: DSP0266 §9.9 payload annotations (ETag on the
  settings-object)
- `test_integration/emulator/emulator_suite_test.dart` — Bios Settings pin +
  corpus-invariant family list (33 families, Bios/Settings to add)
- Related issues: #016 (PATCH/If-Match), #026/#015 (password-management note —
  `Bios v1_3_0` adds a `Passwords` resource superseding ChangePassword)

## Closed Criteria

<!-- Filled on close -->

- Resolution:
- Closed reason:
- Follow-ups: #NNN or none