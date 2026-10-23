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
| `redfish/openbmc/Redfish.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/Redfish.md | 2026-10-22 12:31 (re-verified 16:45 UTC @ `fbb307a`) | `9be2748b017c1657631565b747ff38fc3e74afaaeae1f39cdb6b3a519d786105` | 25,689 | bmcweb master `fbb307a` (was `27e0930b`) | OpenBMC Redfish overview — byte-identical at new HEAD |
| `redfish/openbmc/REDFISH_CHECKLIST.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/REDFISH_CHECKLIST.md | 2026-10-22 12:31 (re-verified 16:45 UTC @ `fbb307a`) | `98ff60be5d6592dd592b267a36f86224c121aba7ad23c34d8e93ceb2f8cdb5ce` | 1,761 | bmcweb master `fbb307a` | OpenBMC compliance checklist — byte-identical at new HEAD |
| `redfish/openbmc/OEM_SCHEMAS.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/OEM_SCHEMAS.md | 2026-10-22 12:31 (re-verified 16:45 UTC @ `fbb307a`) | `7d651fd19bc715b64497fdd466fae03cf043acd50c9efacbacb4a5def469d726` | 5,687 | bmcweb master `fbb307a` | OpenBMC OEM schema extensions — byte-identical at new HEAD |
| `redfish/openbmc/CLIENTS.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/CLIENTS.md | 2026-10-22 23:40 (re-verified 16:45 UTC @ `fbb307a`) | `cfea5163ec820bb4edaba449ef837c9906ce3a2b690e22c4ce16132e526a735f` | 2,695 | bmcweb master `fbb307a` | Client-compat map: DMTF validators, python-redfish-library, redfishtool, fwupd |
| `redfish/mockup/README-mockup-server.md` | https://raw.githubusercontent.com/DMTF/Redfish-Mockup-Server/master/README.md | 2026-10-22 12:31 | `b3af2ff369dcfd78c75f156bd1ddedfca46750d185c59eefdffaa2f11c289431` | 7,318 | Redfish-Mockup-Server `23d21f9a` | Mockup server usage + DSP2043 link |
| `redfish/schemas/v1-index.html` | https://redfish.dmtf.org/schemas/v1/ | 2026-10-22 12:17 | `e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86` | 3,448,133 | n/a | Full DMTF schema index listing (14,259 JSON/YAML entries) |
| `redfish/schemas/v1/<16 schemas>.json` | https://redfish.dmtf.org/schemas/v1/<Name>.json | 2026-10-22 12:34 | see `sha256sum` in run notes | 106,322 (total) | latest per aggregator | Base aggregator stubs for the 16 resources the client maps |
| `redfish/schemas/v1/<6 versioned>.json` | https://redfish.dmtf.org/schemas/v1/<Name>.json | 2026-10-22 21:51 | see below | 619,774 (total) | DMTF 2026.2 | DOCS-2 refresh: versioned defs advanced upstream (ComputerSystem/Chassis/Sensor/AccountService/EthernetInterface/SoftwareInventory) |
| `redfish/schemas/v1/Task.json` | https://redfish.dmtf.org/schemas/v1/Task.json | 2026-10-23 04:05 | `e60eb1a6e77614e8fa71c63bfe816ee711f50c80994e75f9599bf1d781559a77` | 2,286 | latest per aggregator | Task resource aggregator (TaskState/PercentComplete/Messages) — DOCS-10 |
| `redfish/schemas/v1/Task.v1_7_4.json` | https://redfish.dmtf.org/schemas/v1/Task.v1_7_4.json | 2026-10-23 04:05 | `9c29cb7f7a11d4aed869ae651d4388c87d637a3a2b322c7d4ffd023bc8fdcc04` | 21,126 | DMTF 2026.2 | Newest versioned Task defs (TaskState enum 13 values, TaskMonitor URI, PercentComplete 0–100) — DOCS-10 |
| `redfish/schemas/v1/TaskService.v1_2_1.json` | https://redfish.dmtf.org/schemas/v1/TaskService.v1_2_1.json | 2026-10-23 04:05 | `1340438e259a9b77be82900a5b4eeb9c88025d75f9269ab1583749bd6064655a` | 9,538 | DMTF 2026.2 | Versioned TaskService defs (CompletedTaskOverWritePolicy, LifeCycleEventOnTaskStateChange, Tasks) — DOCS-10 |
| `redfish/schemas/v1/LogEntry.json` | https://redfish.dmtf.org/schemas/v1/LogEntry.json | 2026-10-23 07:37 | `a7ea43ecc0d07809cc6dbcf576828ea986d69356eb70f97330bf4748776fc80a` | 5,749 | latest per aggregator | LogEntry resource aggregator (EntryType/Severity/Created/Message/Links.OriginOfCondition) — DOCS-11 |
| `redfish/schemas/v1/LogEntry.v1_22_0.json` | https://redfish.dmtf.org/schemas/v1/LogEntry.v1_22_0.json | 2026-10-23 07:37 | `055bee0449e596eabc7ff5820702b9cdbb29728d07b223844b50d0a5db1a220b` | 59,779 | DMTF 2026.2 | Newest versioned LogEntry defs (EntryType 11 values, CPER, ResolutionSteps, OriginAddress...) — DOCS-11 |
| `redfish/schemas/v1/LogEntry.v1_16_0.json` | https://redfish.dmtf.org/schemas/v1/LogEntry.v1_16_0.json | 2026-10-23 07:37 | `33148ba726c2e27198a38d8d580b6ffad3338d348630c8d7e90e1ae569797385` | 54,373 | DMTF 2025.1 | Version served by the pinned DMTF mockup fixture (emulator pins `#LogEntry.v1_16_0.LogEntry` shapes) — DOCS-11 |
| `redfish/schemas/v1/LogEntryCollection.json` | https://redfish.dmtf.org/schemas/v1/LogEntryCollection.json | 2026-10-23 07:37 | `1224d575c747c7ef33c53b2140b585490a754e4d32572e23d985549553d84f54` | 5,842 | latest per aggregator | LogEntry collection (Members + `@odata.nextLink` pagination contract) — DOCS-11 |
| `redfish/schemas/v1/LogService.v1_9_0.json` | https://redfish.dmtf.org/schemas/v1/LogService.v1_9_0.json | 2026-10-23 07:37 | `97dd7bc08b2cb3e974c21a02fcc1ee59696fb106b410a7fb29051b11e376681a` | 45,352 | DMTF 2026.2 | Newest versioned LogService defs (ServiceEnabled, OverWritePolicy, ClearLog action, Entries link) — DOCS-11 |
| `redfish/schemas/v1/UpdateService.v1_17_1.json` | https://redfish.dmtf.org/schemas/v1/UpdateService.v1_17_1.json | 2026-10-23 08:10 | `cfe7b2b5a8de8e61b2c9b439944985add679610cbee9c101f2160ed418be0ac7` | 58,992 | DMTF 2026.2 | Newest versioned UpdateService defs (MultipartHttpPushUri, HttpPushUriOptions, SimpleUpdate ActionInfo...) — DOCS-12 |
| `redfish/schemas/v1/UpdateService.v1_13_0.json` | https://redfish.dmtf.org/schemas/v1/UpdateService.v1_13_0.json | 2026-10-23 08:10 | `42c82718d7f2e2800e6c313e663625783b255de6ec14e8d0bd7eb961bb20898f` | 46,973 | DMTF 2024.x | Version served by the pinned DMTF mockup fixture (emulator pins `#UpdateService.v1_13_0.UpdateService`, `HttpPushUri=/FWUpdate`) — DOCS-12 |
| `redfish/schemas/v1/EventService.v1_12_0.json` | https://redfish.dmtf.org/schemas/v1/EventService.v1_12_0.json | 2026-10-23 08:10 | `edb6ab8a2b2137ae8667958e77aaef531c7ee03d3fa47fd738fab9a4b0f6fd1f` | 39,549 | DMTF 2026.2 | Newest versioned EventService defs (EventTypesForSubscription, Subscriptions, SSE...) — DOCS-12 |
| `redfish/schemas/v1/EventService.v1_10_1.json` | https://redfish.dmtf.org/schemas/v1/EventService.v1_10_1.json | 2026-10-23 08:10 | `695eca5e89d396cfabb17a68b5ffb13303c36358d6e0982126f7caaa2fc50502` | 37,853 | DMTF 2024.x | Version served by the pinned DMTF mockup fixture (emulator pins `#EventService.v1_10_1.EventService`) — DOCS-12 |
| `redfish/schemas/v1/SessionService.v1_2_0.json` | https://redfish.dmtf.org/schemas/v1/SessionService.v1_2_0.json | 2026-10-23 08:10 | `6d8aa4e4459127691785847a583509819f37e8f70b6195ceac42448acdfc8654` | 9,476 | DMTF 2026.2 | Newest versioned SessionService defs (SessionTimeout, Sessions, AbsoluteSessionTimeout...) — DOCS-12 |
| `redfish/schemas/v1/SessionService.v1_1_8.json` | https://redfish.dmtf.org/schemas/v1/SessionService.v1_1_8.json | 2026-10-23 08:10 | `a9b41d137de64a21c3174f21ff6a5f0c4e036ca040b27c27ed9ba4bb890f3768` | 8,106 | DMTF 2022.x | Version served by the pinned DMTF mockup fixture (emulator pins `#SessionService.v1_1_8.SessionService`, SessionTimeout=30) — DOCS-12 |
| `redfish/schemas/v1/Manager.v1_25_0.json` | https://redfish.dmtf.org/schemas/v1/Manager.v1_25_0.json | 2026-10-23 08:10 | `8c25ce19275b23715d32dd8565f377fc8a57ff2e6553b311397c907993e0b002` | 73,719 | DMTF 2026.2 | Newest versioned Manager defs (GraphicalConsole, SerialConsole, DateTimeSource, SecurityMode...) — DOCS-12 |
| `redfish/schemas/v1/Manager.v1_19_0.json` | https://redfish.dmtf.org/schemas/v1/Manager.v1_19_0.json | 2026-10-23 08:10 | `614aa8139d03cdbfe6746ea66bcfa7876bb91ae3cba980f30de067dd3daa15d4` | 62,336 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#Manager.v1_19_0.Manager`) — DOCS-12 |
| `redfish/schemas/v1/Power.v1_7_3.json` | https://redfish.dmtf.org/schemas/v1/Power.v1_7_3.json | 2026-10-23 08:10 | `b952d8d535dc0f7f6ec2a663bf75fc8664e0e861ca2f3b008c19a7029d4416be` | 64,130 | DMTF 2026.2 | Newest versioned Power defs (PowerControl, Redundancy, Voltages...) — DOCS-12 |
| `redfish/schemas/v1/Power.v1_7_2.json` | https://redfish.dmtf.org/schemas/v1/Power.v1_7_2.json | 2026-10-23 08:10 | `58d2873de1ca54fb7bbecb0c7590e4d73e0ba6fdf7df31bd26ab80d9774890a8` | 64,038 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#Power.v1_7_2.Power`) — DOCS-12 |
| `redfish/schemas/v1/Thermal.v1_7_3.json` | https://redfish.dmtf.org/schemas/v1/Thermal.v1_7_3.json | 2026-10-23 08:10 | `4ed660f95f9b69750c46d14e85c7ed55b80a21ea5052cfa57399f9f7ebcecbf9` | 44,362 | DMTF 2026.2 | Newest versioned Thermal defs (Temperatures, Fans, Redundancy...) — DOCS-12 |
| `redfish/schemas/v1/Thermal.v1_7_2.json` | https://redfish.dmtf.org/schemas/v1/Thermal.v1_7_2.json | 2026-10-23 08:10 | `342c69b50ad4ff050771a0f45e13a177e482422814e08a78dc2335911a0eba9e` | 44,238 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#Thermal.v1_7_2.Thermal`) — DOCS-12 |
| `redfish/schemas/v1/Session.json` | https://redfish.dmtf.org/schemas/v1/Session.json | 2026-10-23 12:38 | `7d5351611865cf26955d83a8ea3b653c78e9fbdebdd5cba5ad7b20305e2cd192` | 2,497 | latest per aggregator | Session resource aggregator (X-Auth-Token/UserName/Password, session-lifetime contract) — DOCS-13 |
| `redfish/schemas/v1/Session.v1_9_0.json` | https://redfish.dmtf.org/schemas/v1/Session.v1_9_0.json | 2026-10-23 12:38 | `abf6d08a8e401c3396d8e972e62fdf920e8a06bed9691dd4efc1a8033a95ab40` | 18,500 | DMTF 2026.2 | Newest versioned Session defs — DOCS-13 |
| `redfish/schemas/v1/Session.v1_7_1.json` | https://redfish.dmtf.org/schemas/v1/Session.v1_7_1.json | 2026-10-23 12:38 | `d319694c2852f8df63f02363304808c4fdd671d82a98ccce6725294e0e0c9352` | 17,249 | DMTF 2024.x | Version served by the pinned DMTF mockup fixture (emulator pins `#Session.v1_7_1.Session` session lifecycle) — DOCS-13 |
| `redfish/schemas/v1/ManagerAccount.json` | https://redfish.dmtf.org/schemas/v1/ManagerAccount.json | 2026-10-23 12:38 | `873bf48a4221ac3e3bb86d4cef61b9959f4b1aa6bd5967ed0c81d8fde6e72859` | 7,419 | latest per aggregator | ManagerAccount (user account) aggregator — DOCS-13 |
| `redfish/schemas/v1/ManagerAccount.v1_14_2.json` | https://redfish.dmtf.org/schemas/v1/ManagerAccount.v1_14_2.json | 2026-10-23 12:38 | `c6ccbaf3e4fec96510d74b2eaa6a8c5d1fa02902b8dc0ec8c475a299dd6c92ae` | 40,947 | DMTF 2026.2 | Newest versioned ManagerAccount defs (UserName/RoleId/Enabled/Password/AccountTypes) — DOCS-13 |
| `redfish/schemas/v1/ManagerAccount.v1_12_0.json` | https://redfish.dmtf.org/schemas/v1/ManagerAccount.v1_12_0.json | 2026-10-23 12:38 | `12d1cbc39afe30dc790fc803f985aadafa47c8e39c81221b1dc95fa9eef0cda0` | 33,171 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#ManagerAccount.v1_12_0.ManagerAccount` Accounts surface) — DOCS-13 |
| `redfish/schemas/v1/Role.json` | https://redfish.dmtf.org/schemas/v1/Role.json | 2026-10-23 12:38 | `3242a2b9f7e2c49f489ffade1f7b6a7146d84f4245748d6c90b6f85ec637b658` | 1,656 | latest per aggregator | Role resource aggregator — DOCS-13 |
| `redfish/schemas/v1/Role.v1_3_3.json` | https://redfish.dmtf.org/schemas/v1/Role.v1_3_3.json | 2026-10-23 12:38 | `c22d150cc01664c21234e70f47b7579847f23d6876631c3c7d6952851603eff4` | 8,921 | DMTF 2026.2 | Newest versioned Role defs (RoleId/AssignedPrivileges/OemPrivileges) — DOCS-13 |
| `redfish/schemas/v1/Role.v1_3_1.json` | https://redfish.dmtf.org/schemas/v1/Role.v1_3_1.json | 2026-10-23 12:38 | `d6387251724c4d1c5d3a25385481911f9626ea5a4ac582de472bdba1c079e6ad` | 8,785 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#Role.v1_3_1.Role` Roles surface) — DOCS-13 |
| `redfish/schemas/v1/ManagerNetworkProtocol.json` | https://redfish.dmtf.org/schemas/v1/ManagerNetworkProtocol.json | 2026-10-23 12:38 | `350a49ec74becc5d00cfe2c041624037115d6c158f8c716b89bf51cf11ef91a7` | 3,683 | latest per aggregator | ManagerNetworkProtocol aggregator (KVMIP/SSH/HTTPS endpoints) — DOCS-13 |
| `redfish/schemas/v1/ManagerNetworkProtocol.v1_14_0.json` | https://redfish.dmtf.org/schemas/v1/ManagerNetworkProtocol.v1_14_0.json | 2026-10-23 12:38 | `ece08d46c966f57208a41a41c5878a1a0c472c809a718999f177420a05a65234` | 68,645 | DMTF 2026.2 | Newest versioned ManagerNetworkProtocol defs — DOCS-13 |
| `redfish/schemas/v1/ManagerNetworkProtocol.v1_10_0.json` | https://redfish.dmtf.org/schemas/v1/ManagerNetworkProtocol.v1_10_0.json | 2026-10-23 12:38 | `23388f641fcab3393d1d54e8f449f0a46bda822fb29edc4150bbf64877ffc43a` | 50,900 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#ManagerNetworkProtocol.v1_10_0.ManagerNetworkProtocol` KVMIP/HTTPS/SSH endpoints — 11:39 run) — DOCS-13 |
| `redfish/schemas/v1/ActionInfo.json` | https://redfish.dmtf.org/schemas/v1/ActionInfo.json | 2026-10-23 12:38 | `cbe1ab23c5693ae433dc8e8a69f064cc6debff9f77a5c4e1cac19d4c02f282e3` | 3,796 | latest per aggregator | ActionInfo aggregator (Parameters/AllowableValues — bmcweb `ResetActionInfo`) — DOCS-13 |
| `redfish/schemas/v1/ActionInfo.v1_6_0.json` | https://redfish.dmtf.org/schemas/v1/ActionInfo.v1_6_0.json | 2026-10-23 12:38 | `77fbb308be4d21cfd454c692a11c8545a4d06d90eae6c2203a379f9cb93b9af2` | 15,229 | DMTF 2026.2 | Newest versioned ActionInfo defs (Parameters AllowableValues + Required, ActionCapabilities) — DOCS-13 |
| `redfish/schemas/v1/ActionInfo.v1_4_1.json` | https://redfish.dmtf.org/schemas/v1/ActionInfo.v1_4_1.json | 2026-10-23 12:38 | `ddbd7b4d0e8dd6db226969d867eda42a10ecc889c61c55aa91d20da6fd6eecc3` | 13,340 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#ActionInfo.v1_4_1.ActionInfo`) — DOCS-13 |
| `redfish/schemas/v1/ServiceRoot.v1_22_0.json` | https://redfish.dmtf.org/schemas/v1/ServiceRoot.v1_22_0.json | 2026-10-23 12:38 | `42fbd21cd81839129ae43647a3ec5b52ade95bc8630378e7340d689a55d4f998` | 38,857 | DMTF 2026.2 | Newest versioned ServiceRoot defs (ProtocolFeaturesSupported/Expand/Excerpt/SSE…) — DOCS-13 |
| `redfish/schemas/v1/ServiceRoot.v1_16_1.json` | https://redfish.dmtf.org/schemas/v1/ServiceRoot.v1_16_1.json | 2026-10-23 12:38 | `d8dbb8748ec06e43c03a972e0f7d398286fe95ea908f9b184e8d5a8da391b519` | 33,397 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#ServiceRoot.v1_16_1.ServiceRoot` discovery) — DOCS-13 |
| `redfish/schemas/v1/Task.v1_7_3.json` | https://redfish.dmtf.org/schemas/v1/Task.v1_7_3.json | 2026-10-23 12:38 | `543f48ea207844f06cf1656d81d3b814ba54e2b6bc4b8c5859d316607331ccaf` | 21,070 | DMTF 2023.x | Version served by the pinned DMTF mockup fixture (emulator pins `#Task.v1_7_3.Task` resource — 09:14 run) — DOCS-13 |
| `redfish/schemas/v1/TaskService.v1_2_0.json` | https://redfish.dmtf.org/schemas/v1/TaskService.v1_2_0.json | 2026-10-23 12:38 | `18bc5f213b16e8d5fffc6b045e1d308a6553d865dc8b20a487ceb41ed298f519` | 9,510 | DMTF 2022.x | Version served by the pinned DMTF mockup fixture (emulator pins `#TaskService.v1_2_0.TaskService`) — DOCS-13 |
| `redfish/schemas/v1/odata.4.0.0.json` | https://redfish.dmtf.org/schemas/v1/odata.4.0.0.json | 2026-10-23 16:40 | `c73cce029ca4cc01a54d341389742f60a4f48e05691ee81934ca9ba513dc6b7c` | 1,834 | OData 4.0.0 | OData base vocabulary (context/id/idRef) — closes the REQUIREMENTS.md row-65 source citation (bare `Odata.json` 404s upstream; lowercase `odata` is canonical). Byte-identical to `test/fixtures/redfish/schemas/Odata.json` — DOCS-14 |

### Downloaded schema set (21 base aggregator files)

`ServiceRoot`, `ComputerSystem`, `Chassis`, `Sensor`, `Power`, `Thermal`,
`SessionService`, `AccountService`, `UpdateService`, `SoftwareInventory`,
`EventService`, `Manager`, `LogService`, `EthernetInterface`, `TaskService`,
`MessageRegistry`. Each bare `<Name>.json` is the DMTF "latest" aggregator that
`$ref`s the newest versioned definitions; SHA-256 hashes are listed in the
run notes in `automation-tracking.md`.

DOCS-13 (2026-10-23) extended the corpus with the five remaining client-relevant
resource families: `Session`, `ManagerAccount`, `Role`, `ManagerNetworkProtocol`,
`ActionInfo` (aggregator + newest versioned + mockup-served version each, see
manifest rows), plus versioned `ServiceRoot` (`v1_22_0` newest + `v1_16_1`
mockup-served) and the mockup-served `Task.v1_7_3` / `TaskService.v1_2_0`
(which the pinned fixture publishes — DOCS-10 had mirrored only the newest
`Task.v1_7_4` / `TaskService.v1_2_1`).

DOCS-14 (2026-10-23) closed the last un-mirrored REQUIREMENTS.md source
citation: `Odata.json` (row 65 — `@odata.id` link traversal). The bare
`Odata.json` 404s on the DMTF schema index; the canonical file is the lowercase
`odata.4.0.0.json` (OData 4.0.0 base vocabulary: `context`/`id`/`idRef`), now
mirrored and byte-verified against `test/fixtures/redfish/schemas/Odata.json`.
Upstream anchors re-verified same run: bmcweb moved `27e0930b` → `fbb307a`
(all four mirrored bmcweb docs byte-identical at the new HEAD — no refresh
needed),`Redfish-Mockup-Server` still `23d21f9a`, DMTF schema index 200 OK,
DSP0266 still 1.25.0.

DOCS-10 added the `Task` resource to the corpus: `Task.json` (aggregator) +
`Task.v1_7_4.json` + `TaskService.v1_2_1.json` (see manifest rows above) so the
DSP0266 §12.2 asynchronous-operations contract (`TaskState`,
`PercentComplete`, `TaskMonitor`, `CompletedTaskOverWritePolicy`, …) is
traceable to schema definitions.

DOCS-12 (2026-10-23) added the missing **versioned** definitions for the six
families that were aggregator-only in the external mirror — `UpdateService`
(v1_17_1 newest + v1_13_0 mockup-served), `EventService` (v1_12_0 + v1_10_1),
`SessionService` (v1_2_0 + v1_1_8), `Manager` (v1_25_0 + v1_19_0), `Power`
(v1_7_3 + v1_7_2), `Thermal` (v1_7_3 + v1_7_2). See the DOCS-12 section below
and the manifest rows.

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

## Current upstream anchors (verified 2026-10-23 23:32 UTC — DOCS-16 citation-audit run; prior: DOCS-15 19:20 UTC, DOCS-13 12:40 UTC, DOCS-14 16:45 UTC)

- Redfish Developer Hub — <https://redfish.dmtf.org/> (200 OK, curl + UA)
- DMTF schema index — <https://redfish.dmtf.org/schemas/v1/> (200 OK, 3.4 MB listing)
- Redfish specification DSP0266 — <https://www.dmtf.org/sites/default/files/standards/documents/DSP0266_1.25.0.pdf>
  (1.24 MB, linked from the hub at `DSP0266_1.25.0.pdf`; probe of `DSP0266_1.26.0.pdf`
  → 404 — 1.25.0 is still the current release. The `redfish.dmtf.org/sites/...`
  path 404s; the hub links the `www.dmtf.org` URL — manifest rows already use
  the working URL)
- Redfish Mockup Server — <https://github.com/DMTF/Redfish-Mockup-Server>
  (default branch `main` @ `23d21f9a` — unchanged; README saved to `redfish/mockup/`)
- OpenBMC bmcweb docs — <https://github.com/openbmc/bmcweb/tree/master/docs>
  (master `fbb307a` — unchanged since DOCS-14; Redfish.md, REDFISH_CHECKLIST.md,
  OEM_SCHEMAS.md, CLIENTS.md saved; re-verified 2026-10-23 23:32 UTC)

### DOCS-15 — DSP0266 §7.3 query-parameters audit (2026-10-23 19:20 UTC)

No new files mirrored this run (corpus is complete for all 16 client-mapped
families + OData base vocabulary; anchors all unchanged). The audit instead
extracted the **normative query-parameter clauses** (DSP0266 §7.3.1–§7.3.5:
`$expand` options incl. `$levels` default 1 / `MaxLevels`, `$select`,
`$filter` built-in operators + precedence, `clientcontext` incremental
retrieval, processing order, 400/501/507 semantics) and traced them to the
client's transport + the emulator-pinned query contract in `REQUIREMENTS.md`
"DOCS-15". Bottom line for #018: the pinned mockup applies `$expand`
(`*` and `$levels=1`) but NOT `$filter`/`$select` (advertised-but-ignored), so
the #018 discovery pass must gate `$expand` on `ProtocolFeaturesSupported`
and filter/project client-side. `RedfishClient.getJson` already supports a
`query` map; the forwarding contract is now pinned by unit test.

### DOCS-11 LogEntry corpus mirror (2026-10-23 07:37 UTC)

The DMTF mockup fixture serves `#LogEntry.v1_16_0.LogEntry` SEL entries and the
emulator suite pins their fields (`EntryType`, `Severity`, `Created` RFC3339,
`Message`, `Links.OriginOfCondition`) plus the collection's `@odata.nextLink`
pagination marker — but the reference corpus had **no `LogEntry` schema at all**
(only the `LogService` aggregator). Mirrored the missing files (171,095 bytes
total, inside the DOCS-6 budget):

- `LogEntry.json` (aggregator; `$ref`s newest versioned defs)
- `LogEntry.v1_22_0.json` (newest versioned — `EntryType` 11 values, `CPER`,
  `ResolutionSteps`, `OriginAddress`, `EventGroupId`, `FirstOverflowTimestamp`…)
- `LogEntry.v1_16_0.json` (the version the pinned mockup serves — kept for
  emulator provenance)
- `LogEntryCollection.json` (Members + `@odata.nextLink` pagination contract)
- `LogService.v1_9_0.json` (newest versioned LogService defs — the external
  corpus only had the aggregator)

Also mirrored `LogEntry.json` + `LogEntry.v1_16_0.json` + `LogEntryCollection.json`
into `test/fixtures/redfish/schemas/` so the fixture snapshot and the external
corpus stay consistent (DOCS-2 precedent). SHA-256s verified via `sha256sum`
after download; manifest rows above. All upstream anchors re-verified during
this run: bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266 1.25.0, schema index —

### DOCS-12 six-family versioned mirror (2026-10-23 08:10 UTC)

Closed the remaining "aggregator-only" corpus gap for the six client-mapped
families that still had **no versioned definitions** in the external mirror
(`UpdateService`, `EventService`, `SessionService`, `Manager`, `Power`,
`Thermal`). Mirrored both the **newest** versioned file (what the aggregator
`$ref`s) and the **mockup-served** version (what the pinned `23d21f9a` fixture
actually publishes) for each — the DOCS-11 LogEntry precedent (newest +
mockup-served + fixture provenance).

Downloaded 12 files, 553,772 bytes total (inside the DOCS-6 budget):
`UpdateService.v1_17_1` + `.v1_13_0`, `EventService.v1_12_0` + `.v1_10_1`,
`SessionService.v1_2_0` + `.v1_1_8`, `Manager.v1_25_0` + `.v1_19_0`,
`Power.v1_7_3` + `.v1_7_2`, `Thermal.v1_7_3` + `.v1_7_2`.

The six **mockup-served** versions (`UpdateService.v1_13_0`,
`EventService.v1_10_1`, `SessionService.v1_1_8`, `Manager.v1_19_0`,
`Power.v1_7_2`, `Thermal.v1_7_2`) were also copied into
`test/fixtures/redfish/schemas/` — the fixture snapshot now has a versioned
schema for every `@odata.type` the mockup publishes (the six **newest**
versions already existed in the fixture, byte-identical to upstream — verified
by SHA-256 during this run, e.g. `UpdateService.v1_17_1`,
`Manager.v1_25_0`).

SHA-256s verified via `sha256sum` after download; manifest rows above. Notable
newest-vs-mockup-served property deltas (audited, no client code change needed
this run — recorded in `REQUIREMENTS.md` "DOCS-12"):

| Family | Newest adds vs mockup-served | Client impact |
|---|---|---|
| `UpdateService.v1_17_1` | `LocalImageStore*` (local image repository), `Stage`/`Activate` actions, `UpdateServiceCapabilities` | none now — #008/#020 push flow uses `HttpPushUri`/`MultipartHttpPushUri` (already parsed) |
| `EventService.v1_12_0` | `OriginResourcesSupported`, `SSEIncludeOriginOfConditionSupported` | none — events out-of-scope (DOCS-7) |
| `SessionService.v1_2_0` | `AbsoluteSessionTimeout`, `AbsoluteSessionTimeoutEnabled` | #015 session expiry could honor absolute timeout when published |
| `Manager.v1_25_0` | `SecurityMode`/`OEMSecurityMode`/`ReadyToRemove`/`DateTimeSource`, `#Manager.UpdateSecurityMode` | none — KVM detection unchanged |
| `Power.v1_7_3` / `Thermal.v1_7_3` | no property deltas (2026.2 release notes only) | none |

REQUIREMENTS.md rows now cite the real mirrored versioned files for these six
families (previously they cited fixture files or bare aggregators).
no version advanced for the other tracked families.

### DOCS-13 auth/network/ActionInfo corpus mirror (2026-10-23 12:38 UTC)

Closed the corpus gap for the resources the **emulator pins but the reference
corpus had no versioned definitions for**: the auth surface (`Session`,
`ManagerAccount`, `Role` — exercised by the session-lifecycle + Accounts/Roles
emulator tests and the #015/#017/#026 auth work), the Manager **network
surface** (`ManagerNetworkProtocol` — the 11:39 run pins its KVMIP/HTTPS/SSH
endpoints for the #009/#021 console renderer), **`ActionInfo`** (bmcweb's
`ResetActionInfo` — the allow-list source for #022/#016), and versioned
`ServiceRoot` (the discovery contract for #018). Also completed the Task-family
provenance: the pinned mockup serves `#Task.v1_7_3.Task` and
`#TaskService.v1_2_0.TaskService`, but DOCS-10 had mirrored only the newest
`Task.v1_7_4` / `TaskService.v1_2_1` — the served versions are now mirrored too.

Downloaded 19 files, **397,572 bytes total** (inside the DOCS-6 budget), all
probed 200 from `redfish.dmtf.org/schemas/v1/` with a browser UA; SHA-256s
verified via `sha256sum` and recorded in the manifest. For each of the six
families: aggregator + **newest** versioned (what the aggregator `$ref`s) +
**mockup-served** version (what the fixture publishes) — the DOCS-11/12
precedent.

The six **mockup-served** versions (`Session.v1_7_1`, `ManagerAccount.v1_12_0`,
`Role.v1_3_1`, `ManagerNetworkProtocol.v1_10_0`, `ActionInfo.v1_4_1`,
`ServiceRoot.v1_16_1`) **plus** `Task.v1_7_3` / `TaskService.v1_2_0` were copied
into `test/fixtures/redfish/schemas/` — every `@odata.type` the pinned mockup
publishes for these client-relevant families now has a versioned schema in the
fixture snapshot.

Notable newest-vs-mockup-served property deltas (audited in REQUIREMENTS.md
"DOCS-13"; no client code change needed this run):

| Family | Newest vs mockup-served | Client impact |
|---|---|---|
| `Session.v1_9_0` | adds `OriginOfSession`, `SessionType*, ``OemSessionPolicy*`-ish expansion | #015: token/session model fields; no field the current code reads changed |
| `ManagerAccount.v1_14_2` | `PasswordExpiration`, `RemoteRole`, `StrictAccountTypes`-era account types | #015/#026 auth negotiation context only |
| `Role.v1_3_3` | no property deltas vs v1_3_1 (release-notes only) | none |
| `ManagerNetworkProtocol.v1_14_0` | adds `NTPProtocolEnabled`, `NTPservers[]`, `Kerberos*` | #009/#021 console endpoint resolution unchanged (KVMIP stable) |
| `ActionInfo.v1_6_0` | adds `ActionCapabilities` (Action supported/stateful), `Parameters.AllowableValueDescriptions` + `Required` | #022/#016: bmcweb `ResetActionInfo` `Parameters/AllowableValues` unchanged |
| `ServiceRoot.v1_22_0` | adds `Tasks` link, `SessionService` changes-era links, `ProtocolFeaturesSupported` unchanged locations | #018: discovery query-capability surface (Expand/Excerpt/Filter/Select) stable |

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

### DOCS-10 — Task resource corpus + task-monitor contract audit (2026-10-23 04:05 UTC)

Mirrored the official DMTF **Task** schemas so the asynchronous-operations
contract (DSP0266 §12.2) can be traced to schema definitions:

- `Task.json` (aggregator) + `Task.v1_7_4.json` — `TaskState` enum (13 values:
  `New`, `Starting`, `Running`, `Suspended`, `Interrupted`, `Pending`,
  `Stopping`, `Completed`, `Killed`, `Exception`, `Service`, `Cancelling`,
  `Cancelled`), `TaskStatus` (Resource `Health`), `PercentComplete` (0–100,
  zero before start), `StartTime`/`EndTime`, `Messages[]`, and `TaskMonitor`
  (the monitor URI, added v1_2_0).
- `TaskService.v1_2_1.json` — `ServiceEnabled`, `DateTime`,
  `CompletedTaskOverWritePolicy` (overwrite policy for completed tasks),
  `LifeCycleEventOnTaskStateChange`, and the `Tasks` collection link.

Both versioned files probe 200 from `redfish.dmtf.org/schemas/v1/` (download
time 04:05 UTC). Total new bytes 32,950 — inside the DOCS-6 budget. The audit
table is in `REQUIREMENTS.md` under "DOCS-10"; the client reads the 202
`Location` + optional `Retry-After` and surfaces them via `UpdateTask`.

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
