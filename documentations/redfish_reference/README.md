# Redfish Reference Documentation

Authoritative DMTF Redfish reference material for the Redfish/OpenBMC Flutter client.
This folder contains **generated documentation only** — it does not modify application
source code. The raw API payloads that back every example here live under
`test/fixtures/redfish/`.

## Sources (exact URLs used)

### 1. DMTF Redfish Mockup (real `/redfish/v1` API responses)
- Repository: <https://github.com/DMTF/Redfish-Mockup-Server>
- Command used:
  ```bash
  git clone --depth 1 https://github.com/DMTF/Redfish-Mockup-Server /tmp/redfish-mockup
  ```
- Mockup profile used: `public-rackmount1` (a rackmount server with BMC).
  - Reported `RedfishVersion`: `1.15.0` (ServiceRoot `@odata.type` `#ServiceRoot.v1_16_1.ServiceRoot`).
- Copied verbatim (preserving the full relative tree) into:
  `test/fixtures/redfish/dmtf_mockup/`

### 2. DMTF JSON Schemas (machine-readable property definitions)
- Base URL pattern: `https://redfish.dmtf.org/schemas/v1/<Name>.json`
  - The bare `<Name>.json` URL resolves (HTTP 302) to the **latest** published
    version and is an *aggregator* document (`anyOf` of every version). The real
    property definitions live in the versioned files, which were also downloaded.
- Downloaded into: `test/fixtures/redfish/schemas/`
  - Bare (aggregator) files: `ComputerSystem.json`, `Chassis.json`, `Manager.json`,
    `Power.json`, `PowerSupply.json`, `PowerSubsystem.json`, `Thermal.json`,
    `Sensor.json`, `SensorCollection.json`, `UpdateService.json`,
    `SoftwareInventory.json`, `SoftwareInventoryCollection.json`, `SimpleUpdate`
    (see gaps), `AccountService.json`, `SessionService.json`, `EthernetInterface.json`,
    `LogService.json`, `EventService.json`, `TaskService.json`, `Resource.json`,
    `RedfishError` (see gaps), `Odata.json`, `AttributeRegistry.json`.
  - Versioned definition files (latest, used for property tables):
    `ComputerSystem.v1_29_0.json`, `Chassis.v1_29_0.json`, `Manager.v1_25_0.json`,
    `Power.v1_7_3.json`, `Thermal.v1_7_3.json`, `Sensor.v1_14_0.json`,
    `UpdateService.v1_17_1.json`, `SoftwareInventory.v1_15_0.json`,
    `AccountService.v1_19_0.json`, `SessionService.v1_2_0.json`,
    `EthernetInterface.v1_12_6.json`, `EventService.v1_12_0.json`,
    `LogService.v1_9_0.json`, plus `odata.4.0.0.json`.
  - LogEntry additions (DOCS-11, 2026-10-23): `LogEntry.json` +
    `LogEntry.v1_16_0.json` (the version the mockup serves) +
    `LogEntryCollection.json` also mirrored into `test/fixtures/redfish/schemas/`
    for fixture/corpus consistency; newest version `LogEntry.v1_22_0.json` lives
    in `documentations/external/redfish/schemas/v1/`.
  - DOCS-12 additions (2026-10-23): the **mockup-served** versioned defs for the
    six families the pinned mockup publishes older `@odata.type` versions for
    were added to `test/fixtures/redfish/schemas/` (and to the external corpus
    with their newest counterparts):
    `UpdateService.v1_13_0.json`, `EventService.v1_10_1.json`,
    `SessionService.v1_1_8.json`, `Manager.v1_19_0.json`,
    `Power.v1_7_2.json`, `Thermal.v1_7_2.json`. The newest versions for these
    families were already present and verified byte-identical to upstream.
  - DOCS-13 additions (2026-10-23): **mockup-served** versioned defs for the
    auth/network/ActionInfo resources the emulator pins + the Task-family served
    versions were added to `test/fixtures/redfish/schemas/` (and to the external
    corpus with their newest counterparts):
    `Session.v1_7_1.json`, `ManagerAccount.v1_12_0.json`, `Role.v1_3_1.json`,
    `ManagerNetworkProtocol.v1_10_0.json`, `ActionInfo.v1_4_1.json`,
    `ServiceRoot.v1_16_1.json`, `Task.v1_7_3.json`, `TaskService.v1_2_0.json`.

## Gaps / notes
- `SimpleUpdate` has **no standalone JSON schema** — it is an Action defined inside
  `UpdateService.json` (`#UpdateService.SimpleUpdate`). Its target URI in the mockup is
  `/redfish/v1/UpdateService/Actions/SimpleUpdate`.
- `RedfishError` has **no JSON schema** at the DMTF schema site (only `RedfishError_v1.xml/.bin/.map`).
  Its shape is defined by the Redfish specification and is documented in `redfish_error.md`.
- `Odata.json` is fetched as `odata.4.0.0.json` (the bare `Odata.json` 404s; lowercase `odata`).
- `SoftwareInventoryCollection` is **not present** in the `public-rackmount1` mockup — only
  `FirmwareInventory` is exposed. Per the DMTF spec, `FirmwareInventory` and `SoftwareInventory`
  are collections of the same `SoftwareInventory` resource; treat them interchangeably in code.

## How to regenerate
1. Re-clone / refresh the mockup (see step 1) and re-copy `public-rackmount1/` into
   `test/fixtures/redfish/dmtf_mockup/`.
2. Re-download schemas from the base URL and re-resolve the latest versioned files.
3. Re-run the doc generator (`/tmp/gen_docs.py` is reproducible) to rebuild the
   per-resource Markdown pages, then hand-maintain `README.md`, `index.md`, and
   `api_formats.md`.

> Snapshot refresh status: this mirror's `test/fixtures/redfish/` snapshot was
> last refreshed at setup (2026-10-21). A live upstream refresh (DMTF schema
> index shows 14,259 JSON/YAML entries as of 2026-10-22) is tracked as
> `DOCS-2` in `FUTUREWORK.md`; the authoritative live docs corpus now lives in
> `documentations/external/redfish/` with per-file hashes.
> **2026-10-22 21:51 UTC:** six versioned DMTF schemas refreshed to the current
> upstream (ComputerSystem/Chassis v1_29_0, Sensor v1_14_0,
> AccountService v1_19_0, EthernetInterface v1_12_6,
> SoftwareInventory v1_15_0); superseded files retained; see
> `documentations/external/README.md` "DOCS-2 refresh".

## Directory layout
```
documentations/redfish_reference/
  README.md              # this file
  index.md               # data-model overview + table of contents
  api_formats.md         # endpoint + field quick reference (coding cheat-sheet)
  computer_system.md
  chassis.md
  manager.md
  power.md
  thermal.md
  sensor.md
  update_service.md
  software_inventory.md
  account_service.md
  session_service.md
  ethernet_interface.md
  event_service.md
  log_service.md
  redfish_error.md

test/fixtures/redfish/
  dmtf_mockup/           # full public-rackmount1 tree (264 real JSON files)
  schemas/               # 34 raw DMTF schema files (aggregator + versioned)
```
