# External Reference Mirror

Official upstream documentation pulled down by the `redfish-automation` job for
offline comparison against the app. This is a **reference corpus**, not app code.

## Policy

- **Official sources only:** DMTF Redfish/Redfish Forum and OpenBMC `bmcweb`/docs.
- Record the exact URL, fetch time (UTC), SHA-256, size, and upstream commit or
  spec version in the manifest below.
- Prefer text/schema/JSON over very large PDFs. Budget: **25 MB per file** and
  **50 MB of new downloads per run**.
- If an artifact is larger than the budget, store the URL + hash + extracted
  notes instead of the binary.
- Never mirror credentials, private BMC data, or vendor docs that prohibit
  redistribution.
- Re-fetch only when upstream changed; verify `sha256sum` after download.

## Layout

```
documentations/external/
  README.md                 # this file + manifest
  redfish/
    spec/                   # DSP0266 PDF/HTML and extracted notes
    schemas/                # DMTF schema index / selected schemas
    openbmc/                # bmcweb Redfish.md, checklist, OEM notes
    mockup/                 # mockup provenance or selected fixtures
    REQUIREMENTS.md         # requirement -> code -> test -> status
```

## Manifest

| File | Source URL | Fetched (UTC) | SHA-256 | Bytes | Upstream version/commit | Notes |
|---|---|---|---|---|---|---|
| `redfish/spec/DSP0266_1.25.0.pdf` | https://www.dmtf.org/sites/default/files/standards/documents/DSP0266_1.25.0.pdf | 2026-10-22 12:17 | `385ee6d0039a2dbc610c7af9fa9bba304fc2a461ceb5a8eda0adb33630c82149` | 1,243,359 | DSP0266 1.25.0 | Redfish specification PDF; linked from redfish.dmtf.org hub |
| `redfish/openbmc/Redfish.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/Redfish.md | 2026-10-22 12:31 (re-verified 23:43 UTC @ `27e0930b`) | `9be2748b017c1657631565b747ff38fc3e74afaaeae1f39cdb6b3a519d786105` | 25,689 | bmcweb master `27e0930b` (was `0128851e`) | OpenBMC Redfish overview — byte-identical at new HEAD |
| `redfish/openbmc/REDFISH_CHECKLIST.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/REDFISH_CHECKLIST.md | 2026-10-22 12:31 (re-verified 23:43 UTC @ `27e0930b`) | `98ff60be5d6592dd592b267a36f86224c121aba7ad23c34d8e93ceb2f8cdb5ce` | 1,761 | bmcweb master `27e0930b` | OpenBMC compliance checklist — byte-identical at new HEAD |
| `redfish/openbmc/OEM_SCHEMAS.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/OEM_SCHEMAS.md | 2026-10-22 12:31 (re-verified 23:43 UTC @ `27e0930b`) | `7d651fd19bc715b64497fdd466fae03cf043acd50c9efacbacb4a5def469d726` | 5,687 | bmcweb master `27e0930b` | OpenBMC OEM schema extensions — byte-identical at new HEAD |
| `redfish/openbmc/CLIENTS.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/CLIENTS.md | 2026-10-22 23:40 | `cfea5163ec820bb4edaba449ef837c9906ce3a2b690e22c4ce16132e526a735f` | 2,695 | bmcweb master `27e0930b` | Client-compat map: DMTF validators, python-redfish-library, redfishtool, fwupd |
| `redfish/mockup/README-mockup-server.md` | https://raw.githubusercontent.com/DMTF/Redfish-Mockup-Server/master/README.md | 2026-10-22 12:31 | `b3af2ff369dcfd78c75f156bd1ddedfca46750d185c59eefdffaa2f11c289431` | 7,318 | Redfish-Mockup-Server `23d21f9a` | Mockup server usage + DSP2043 link |
| `redfish/schemas/v1-index.html` | https://redfish.dmtf.org/schemas/v1/ | 2026-10-22 12:17 | `e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86` | 3,448,133 | n/a | Full DMTF schema index listing (14,259 JSON/YAML entries) |
| `redfish/schemas/v1/<16 schemas>.json` | https://redfish.dmtf.org/schemas/v1/<Name>.json | 2026-10-22 12:34 | see `sha256sum` in run notes | 106,322 (total) | latest per aggregator | Base aggregator stubs for the 16 resources the client maps |
| `redfish/schemas/v1/<6 versioned>.json` | https://redfish.dmtf.org/schemas/v1/<Name>.json | 2026-10-22 21:51 | see below | 619,774 (total) | DMTF 2026.2 | DOCS-2 refresh: versioned defs advanced upstream (ComputerSystem/Chassis/Sensor/AccountService/EthernetInterface/SoftwareInventory) |

### Downloaded schema set (16 base aggregator files)

`ServiceRoot`, `ComputerSystem`, `Chassis`, `Sensor`, `Power`, `Thermal`,
`SessionService`, `AccountService`, `UpdateService`, `SoftwareInventory`,
`EventService`, `Manager`, `LogService`, `EthernetInterface`, `TaskService`,
`MessageRegistry`. Each bare `<Name>.json` is the DMTF "latest" aggregator that
`$ref`s the newest versioned definitions; SHA-256 hashes are listed in the
run notes in `automation-tracking.md`.

### DOCS-2 refresh (2026-10-22 21:51 UTC) — versioned schemas now current

DMTF schema index scan (14,259 entries) showed six versioned files advanced
upstream since the 2026-10-21 snapshot. Re-downloaded the newest definitions and
mirrored them (also into `test/fixtures/redfish/schemas/`):

| File | Upstream release | SHA-256 | Bytes | Notable deltas |
|---|---|---|---|---|
| `ComputerSystem.v1_29_0.json` | 2026.2 | `c459c869b32af3b21228f384e4e61cbf7f4b646326692fec02d8be0c667b46d2` | 213,533 | New `GraphicalConsoleGetOneTimeURL`/`SetOneTimePassword`/`SetPassword` actions; `ProductionDate`; `ConsoleAccessMode` |
| `Chassis.v1_29_0.json` | 2026.2 | `bdd9ef9925d743a47882461bb948fff9f942d22572e7d01594908119b2eaeda2` | 84,638 | `ProductionDate`; ChassisType `OpenRack`/`OpenRackWide` (deprecates `OpenU`) |
| `Sensor.v1_14_0.json` | 2026.2 | `643b3fc4374bebda36811e90ff3b2b13eccfd0fc1fc85c9e4482d025800033fe` | 128,628 | ReadingType `Turbidity`/`LiquidConductivity`/`pH`; `Oem` on Sensor |
| `AccountService.v1_19_0.json` | 2026.2 | `423292b3c82ba9862a389392ca84bad9eace62da9cdf8f919a201fca029f7696` | 99,777 | `KerberosKeytabSet`/`PasswordSet`/`TokenSet` read-only flags; LDAP STARTTLS note |
| `EthernetInterface.v1_12_6.json` | 2023.3 → 2026.2 | `6647c8d1018b973c86a2b850322e90b91d8a51d38b3b3a2962c997b213330b66` | 54,136 | SLAAC wording clarified (IPv4 link-local) |
| `SoftwareInventory.v1_15_0.json` | 2026.1 → 2026.2 | `0c06060359fc2e2552b4248a8f04c468043d6699c2dd566b7725bfc6a3dcb61e` | 39,062 | New `ImageState` enum (`Active`/`Staged`/`Armed`/`TargetSpecific`/`OEM`) + `ActiveTargets`/`StagedTargets`/`ArmedTargets` links |

Kept the superseded versioned files (`v1_28_0`, `v1_13_0`, `v1_18_1`,
`v1_12_5`, `v1_14_0`) in both mirrors for history; the aggregator is
self-contained (`$ref` `#/definitions/...` of its own version, no `anyOf`
redirection), so no fixture referencing a specific version is affected.

## Current upstream anchors (verified 2026-10-23 06:05 UTC — DOCS-9 re-check)

- Redfish Developer Hub — <https://redfish.dmtf.org/> (200 OK, curl + UA)
- DMTF schema index — <https://redfish.dmtf.org/schemas/v1/> (200 OK, 3.4 MB listing)
- Redfish specification DSP0266 — <https://www.dmtf.org/sites/default/files/standards/documents/DSP0266_1.25.0.pdf>
  (1.24 MB, linked from the hub at `DSP0266_1.25.0.pdf`; probe of `DSP0266_1.26.0.pdf`
  → 404 — 1.25.0 is still the current release)
- Redfish Mockup Server — <https://github.com/DMTF/Redfish-Mockup-Server>
  (master `23d21f9a` — unchanged; README saved to `redfish/mockup/`)
- OpenBMC bmcweb docs — <https://github.com/openbmc/bmcweb/tree/master/docs>
  (master `27e0930b`, was `0128851e`; Redfish.md, REDFISH_CHECKLIST.md,
  OEM_SCHEMAS.md, CLIENTS.md saved; the three original docs are byte-identical
  at the new HEAD)

### DOCS-9 upstream-freshness re-check (2026-10-23 06:05 UTC)

Re-verified every corpus anchor against live upstream again (about 6h after the
DOCS-8 audit). **No anchor moved**: bmcweb master still `27e0930b`
(`git ls-remote`), Redfish-Mockup-Server still `23d21f9a`, DSP0266 1.25.0 still
the latest published PDF (1.26.0 → 404), and the live DMTF schema index shows no
version advanced for the 13 tracked families (probed the current versions still
present and the next-higher versions all absent). No new downloads — corpus
stays inside the DOCS-6 budget. Docs-driven code fix this run: `UpdateServiceInfo`
now parses bmcweb's `MultipartHttpPushUri` (see REQUIREMENTS.md "bmcweb firmware
update" row — DOCS-9).

### DOCS-8 upstream-freshness audit (2026-10-22 23:43 UTC)

Re-verified every corpus anchor against live upstream. All 13 schema families
under `redfish/schemas/v1/` + `test/fixtures/redfish/schemas/` match the current
DMTF index (no version advanced since the DOCS-2 refresh). DSP0266 1.25.0 still
the latest published PDF (1.26.0 → 404). `DMTF/Redfish-Mockup-Server` HEAD
still `23d21f9a` (pinned). bmcweb master advanced `0128851e` → `27e0930b` (3
commits); the mirrored docs are byte-identical and `docs/CLIENTS.md` was added
to the mirror (client-compatibility reference relevant to future integration
work). New downloads this run: 2,695 bytes (CLIENTS.md only) — inside the
DOCS-6 50 MB budget. Decision: `docs/COMMON_ERRORS.md` and `docs/HEADERS.md`
are bmcweb *C++ contributor* docs (build/header architecture, pointer
dereferencing) with no client-facing Redfish contract — not mirrored; noted
here so the next audit doesn't re-evaluate them.

> DMTF's `www.dmtf.org` pages may return 403 to plain curl. Use a browser
> user-agent, the `webfetch` tool, or the `redfish.dmtf.org` mirror, and record
> the URL that actually returned 200. (PDF download from `www.dmtf.org` worked
> with a browser UA this run.)

## Emulator harness (DMTF Redfish-Mockup-Server)

`tool/emulator/run_tests.sh` runs the real mockup server over HTTPS (self-signed
cert, generated per-run under `/tmp`) against
`test/fixtures/redfish/dmtf_mockup` and executes
`test_integration/emulator/emulator_suite_test.dart` with
`--dart-define=REDFISH_EMULATOR_URL=https://127.0.0.1:8443`.

- **Pinned upstream:** `DMTF/Redfish-Mockup-Server @ 23d21f9a`
  (same commit mirrored in `redfish/mockup/README.md`; verified 2026-10-22).
- **Isolation:** plain `flutter test` never touches the emulator; the suite
  `markTestSkipped`s when the URL define is absent.
- **TLS:** `allowSelfSigned: true` is test-profile only (EMU-6); production
  code keeps TLS validation.

## Requirement traceability

`redfish/REQUIREMENTS.md` maps each audited requirement to the implementation and
a test. Keep it short and cite section numbers; unresolved gaps belong in
`FUTUREWORK.md` as `DOCS-*` items.
