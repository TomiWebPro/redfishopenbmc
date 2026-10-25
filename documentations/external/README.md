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
| `redfish/openbmc/Redfish.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/Redfish.md | 2026-10-22 12:31 (re-verified 2026-10-25 08:06 UTC @ `63a18f4`) | `9be2748b017c1657631565b747ff38fc3e74afaaeae1f39cdb6b3a519d786105` | 25,689 | bmcweb master `63a18f4`; file last-touch `bb6b9ebc` (2026-09-21) | OpenBMC Redfish overview — byte-identical at current master HEAD; file-level provenance pinned 2026-10-25 via GitHub path API (repo HEAD has moved past the file's last content change) |
| `redfish/openbmc/REDFISH_CHECKLIST.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/REDFISH_CHECKLIST.md | 2026-10-22 12:31 (re-verified 2026-10-25 08:06 UTC @ `63a18f4`) | `98ff60be5d6592dd592b267a36f86224c121aba7ad23c34d8e93ceb2f8cdb5ce` | 1,761 | bmcweb master `63a18f4`; file last-touch `24e758ab` (2025-06-26) | OpenBMC compliance checklist — byte-identical at current master HEAD; untouched since the docs-folder creation commit |
| `redfish/openbmc/OEM_SCHEMAS.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/OEM_SCHEMAS.md | 2026-10-22 12:31 (re-verified 2026-10-25 08:06 UTC @ `63a18f4`) | `7d651fd19bc715b64497fdd466fae03cf043acd50c9efacbacb4a5def469d726` | 5,687 | bmcweb master `63a18f4`; file last-touch `24e758ab` (2025-06-26) | OpenBMC OEM schema extensions — byte-identical at current master HEAD; untouched since the docs-folder creation commit |
| `redfish/openbmc/CLIENTS.md` | https://raw.githubusercontent.com/openbmc/bmcweb/master/docs/CLIENTS.md | 2026-10-22 23:40 (re-verified 2026-10-25 08:06 UTC @ `63a18f4`) | `cfea5163ec820bb4edaba449ef837c9906ce3a2b690e22c4ce16132e526a735f` | 2,695 | bmcweb master `63a18f4`; file last-touch `24e758ab` (2025-06-26) | Client-compat map: DMTF validators, python-redfish-library, redfishtool, fwupd — byte-identical at current master HEAD; untouched since the docs-folder creation commit |
| `redfish/mockup/README-mockup-server.md` | https://raw.githubusercontent.com/DMTF/Redfish-Mockup-Server/master/README.md | 2026-10-22 12:31 (re-verified 2026-10-25 08:06 UTC @ `23d21f9a`) | `0d79a16595033b72b3dea70c14326fa31cfc1e8a2ac4e14bbf4c721222ba15ed` | 7,316 | Redfish-Mockup-Server `23d21f9a` | Mockup server usage + DSP2043 link; committed with trailing whitespace normalized on 2 `cert = `/`key = ` lines (2 bytes) — content identical to upstream `b3af2ff369dcfd78c75f156bd1ddedfca46750d185c59eefdffaa2f11c289431` (7,318 B) — DOCS-27 provenance fix |
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
| `redfish/registries/Base.1.5.0.json` | https://redfish.dmtf.org/registries/Base.1.5.0.json | 2026-10-24 04:38 | `c10263417a076402a992f099db4e019c9d91f674d256df32a390b86a2c46492c` | 31,984 | DMTF Base registry 1.5.0 | Message-registry payload the pinned mockup serves (`/redfish/v1/Registries/Base.1.5.0.json`, EMU-2 MessageRegistry pin 2026-10-24); 60 Base.* templates (Message/Severity/NumberOfArgs). **Byte-identical to `test/fixtures/redfish/dmtf_mockup/Registries/Base.1.5.0.json`** (proven authentic) — DOCS-18 |
| `redfish/registries/Base.1.24.0.json` | https://redfish.dmtf.org/registries/Base.1.24.0.json | 2026-10-24 04:39 | `abe0b78bba184f4b0e061696e4c9c43d76c029edb0ae5cf4902fdf3f979ef92d` | 138,295 | DMTF Base registry 1.24.0 (newest) | Newest published Base registry (125 templates; 1.5.0 → 1.24.0 adds 65 templates + rewords 39 shared Message strings, **NumberOfArgs stable** — the emulator-pinned contract); `@odata.type` `#MessageRegistry.v1_9_0.MessageRegistry` — DOCS-18 |
| `redfish/schemas/v1/Sensor.v1_8_1.json` | https://redfish.dmtf.org/schemas/v1/Sensor.v1_8_1.json | 2026-10-24 06:30 | `6972bd045addd8b4f6c58bb296a095be2d19e2eb450243243967bc71dafa2f80` | 102,125 | DMTF 2021.x | **Mockup-served** version — the 42-member Sensors collection the emulator pins publishes `#Sensor.v1_8_1.Sensor`; DOCS-2 had mirrored only the newest `v1_14_0`. All client-read properties present — DOCS-19 |
| `redfish/schemas/v1/ComputerSystem.v1_22_0.json` | https://redfish.dmtf.org/schemas/v1/ComputerSystem.v1_22_0.json | 2026-10-24 06:30 | `3ba322e18e5d9445c51157fe4b2b3e835bf3992b4a4e60733bf6202342ee615e` | 145,755 | DMTF 2021.x | **Mockup-served** version — the systems the emulator pins publish `#ComputerSystem.v1_22_0.ComputerSystem`; DOCS-2 had mirrored only the newest `v1_29_0` — DOCS-19 |
| `redfish/schemas/v1/Chassis.v1_25_0.json` | https://redfish.dmtf.org/schemas/v1/Chassis.v1_25_0.json | 2026-10-24 06:30 | `1fd75b98b3f6b380bc728090a5bace485d60e4886486c2be1e9b8e4b345b2001` | 75,981 | DMTF 2022.x | **Mockup-served** version — chassis payloads publish `#Chassis.v1_25_0.Chassis`; DOCS-2 had mirrored only the newest `v1_29_0` — DOCS-19 |
| `redfish/schemas/v1/AccountService.v1_15_0.json` | https://redfish.dmtf.org/schemas/v1/AccountService.v1_15_0.json | 2026-10-24 06:30 | `2eda8a3f552500aa3bb1668ee97590eb83af8afa5cf811ae3dc0da35a68f963f` | 89,936 | DMTF 2022.x | **Mockup-served** version — AccountService payload publishes `#AccountService.v1_15_0.AccountService` (lockout fields pinned by the auth-surface emulator tests); DOCS-2 had mirrored only the newest `v1_19_0` — DOCS-19 |
| `redfish/schemas/v1/SoftwareInventory.v1_10_1.json` | https://redfish.dmtf.org/schemas/v1/SoftwareInventory.v1_10_1.json | 2026-10-24 06:30 | `f265714965cbbd7659b2fb5ff86e798ebb9de2c94c5bb6efb253773ce43402e4` | 22,621 | DMTF 2021.x | **Mockup-served** version — firmware inventory payloads publish `#SoftwareInventory.v1_10_1.SoftwareInventory`; DOCS-2 had mirrored only the newest `v1_15_0` — DOCS-19 |
| `redfish/schemas/v1/LogService.v1_6_0.json` | https://redfish.dmtf.org/schemas/v1/LogService.v1_6_0.json | 2026-10-24 06:30 | `21223c8379ea6fa5b9a2e7d074c21db994d2d6d16c7f5ba1c0c769a00278e1c3` | 33,248 | DMTF 2021.x | **Mockup-served** version — log-service payloads publish `#LogService.v1_6_0.LogService` (DOCS-11 had mirrored only the newest `v1_9_0`) — DOCS-19 |
| `redfish/schemas/v1/EthernetInterface.v1_12_0.json` | https://redfish.dmtf.org/schemas/v1/EthernetInterface.v1_12_0.json | 2026-10-24 06:30 | `d30d0540dd75f8e02e7b9534890d43590c500bf56dfe827294518803984f283c` | 52,887 | DMTF 2021.x | **Mockup-served** version — NIC payloads publish `#EthernetInterface.v1_12_0.EthernetInterface`; DOCS-2 had mirrored only the newest `v1_12_6` — DOCS-19 |
| `redfish/schemas/v1/MessageRegistry.v1_0_0.json` | https://redfish.dmtf.org/schemas/v1/MessageRegistry.v1_0_0.json | 2026-10-24 06:30 | `7a2f5eda067db83b8181d34ef3ac7645416b42814d7d0dc104620de9e61d7a7c` | 10,151 | DMTF 2021.x | **Mockup-served** version — the `Base.1.5.0` registry payload the mockup serves (DOCS-18) publishes `@odata.type` `#MessageRegistry.v1_0_0.MessageRegistry` — DOCS-19 |
| `redfish/schemas/v1/MessageRegistry.v1_9_0.json` | https://redfish.dmtf.org/schemas/v1/MessageRegistry.v1_9_0.json | 2026-10-24 06:31 | `96c61a6bc1976dfb661e455948b1b50f964a9f7834d831a2d9bd411aba526aa4` | 27,961 | DMTF 2026.x | Newest versioned MessageRegistry — the `@odata.type` referenced by the newest `Base.1.24.0` registry payload (DOCS-18); closes the newest+served pair for the registry family — DOCS-19 |
| `redfish/schemas/v1/EnvironmentMetrics.v1_3_1.json` | https://redfish.dmtf.org/schemas/v1/EnvironmentMetrics.v1_3_1.json | 2026-10-24 10:20 | `71d136d905ecdf670a1895901d4ad1ccb900107189185374a4754db3f726f751` | 17,008 | DMTF 2025.x | Chassis aggregate telemetry surface pinned by the emulator (2026-10-24, EMU 45→48): TemperatureCelsius/PowerWatts/PowerLimitWatts/FanSpeedsPercent excerpts (`DataSourceUri` → Sensors) — DOCS-20 |
| `redfish/schemas/v1/ThermalSubsystem.v1_3_1.json` | https://redfish.dmtf.org/schemas/v1/ThermalSubsystem.v1_3_1.json | 2026-10-24 10:20 | `edadea10bb6c06baf523ef07e4c831daf2e58847efb37cbf3ee4f6f7bd0b9ec8` | 10,142 | DMTF 2025.x | Fans collection + FanRedundancy (NPlusM groups via Redundancy.json) + ThermalMetrics link — DOCS-20 |
| `redfish/schemas/v1/ThermalMetrics.v1_3_1.json` | https://redfish.dmtf.org/schemas/v1/ThermalMetrics.v1_3_1.json | 2026-10-24 10:20 | `8d74d8020c2edddd7ffb8813bd56813f2077cd2da49e0dd3644ca6d6bdcf6d8c` | 19,523 | DMTF 2025.x | TemperatureSummaryCelsius Intake/Exhaust/Internal/Ambient (`SensorExcerpt`, DataSourceUri → Sensors) — DOCS-20 |
| `redfish/schemas/v1/PowerSubsystem.v1_1_1.json` | https://redfish.dmtf.org/schemas/v1/PowerSubsystem.v1_1_1.json | 2026-10-24 10:20 | `e664c3839f0782059f8ea9dc3a90317df91f1e584f4e3a31b308cce38d4ed5b9` | 10,756 | DMTF 2024.x | PowerSupplies collection + Metrics link — DOCS-20 |
| `redfish/schemas/v1/PowerSupply.v1_5_3.json` | https://redfish.dmtf.org/schemas/v1/PowerSupply.v1_5_3.json | 2026-10-24 10:20 | `2c12d4d29bbe3eb71b483c3f528275e85992dafc6b5ecdb8f031983555cb453d` | 34,997 | DMTF 2025.x | PSU detail pinned by the emulator: Model/Manufacturer/FirmwareVersion/LineInputStatus/Metrics + `#PowerSupply.Reset` action — DOCS-20 |
| `redfish/schemas/v1/PowerSupplyMetrics.v1_1_1.json` | https://redfish.dmtf.org/schemas/v1/PowerSupplyMetrics.v1_1_1.json | 2026-10-24 10:20 | `a27e6e7b7eb6623c054fe36327826da273c3ee029da137b59e97aedf9ae1ad55` | 17,833 | DMTF 2024.x | The Metrics link target on the PSU detail the emulator pins (`#PowerSupplyMetrics.v1_1_1.PowerSupplyMetrics`) — DOCS-20 |
| `redfish/schemas/v1/Fan.v1_5_1.json` | https://redfish.dmtf.org/schemas/v1/Fan.v1_5_1.json | 2026-10-24 10:20 | `470d0b68f5e3a73d94b9be9110082bc4be6700e68d8faa39e5196526981d3c42` | 17,544 | DMTF 2023.x | **Mockup-served** Fan member type — the Fans collection members publish `#Fan.v1_5_1.Fan` (the emulator-pinned FanRedundancy context) — DOCS-20 |
| `redfish/schemas/v1/FanCollection.json` | https://redfish.dmtf.org/schemas/v1/FanCollection.json | 2026-10-24 10:20 | `6ca171f790fda3fac7c62b0a424ee2d6cece2e6ef15ae4f83e13d2a3e7aab0b7` | 4,936 | latest per aggregator | `#FanCollection.FanCollection` — `ThermalSubsystem.Fans` link target — DOCS-20 |
| `redfish/schemas/v1/PowerSupplyCollection.json` | https://redfish.dmtf.org/schemas/v1/PowerSupplyCollection.json | 2026-10-24 10:20 | `105fbec40330ea9f1b6c434bdd2df8063bfa8a4846f7e5f2ab84306ec941851b` | 5,251 | latest per aggregator | `#PowerSupplyCollection.PowerSupplyCollection` — `PowerSubsystem.PowerSupplies` link target — DOCS-20 |
| `redfish/schemas/v1/Redundancy.json` | https://redfish.dmtf.org/schemas/v1/Redundancy.json | 2026-10-24 10:20 | `985705e0e1cf7bd1c059659002637197bf05640d50f72ddaa19312bdbd5ca672` | 2,890 | latest per aggregator | RedundantGroup aggregator — resolves the `ThermalSubsystem.FanRedundancy` citation chain (DOCS-14 precedent) — DOCS-20 |
| `redfish/schemas/v1/Redundancy.v1_7_1.json` | https://redfish.dmtf.org/schemas/v1/Redundancy.v1_7_1.json | 2026-10-24 10:20 | `f670ed0c111d509cb95bb390c5a67d92147bf98f73056529007e15deaea598ef` | 19,221 | DMTF 2026.x | Newest RedundantGroup def (MinNeededInGroup/MaxSupportedInGroup/RedundancyGroup/RedundancyType) — the emulator-pinned NPlusM surfaces — DOCS-20 |
| `redfish/schemas/v1/Battery.json` | https://redfish.dmtf.org/schemas/v1/Battery.json | 2026-10-24 12:14 | `d8803713c62dfd04af68f8b20902b65903b5a327b275a6f4391bd9950bf66b9c` | 2,416 | latest per aggregator | Battery family aggregator — resolves `#Battery.Battery` citations — DOCS-21 |
| `redfish/schemas/v1/Battery.v1_2_2.json` | https://redfish.dmtf.org/schemas/v1/Battery.v1_2_2.json | 2026-10-24 12:14 | `0a498bfe81cfbb41b5c3c23c783aa8c616e9808caae2c8eb84b6a3328304e578` | 27,215 | DMTF 2021.x | **Mockup-served** `#Battery.v1_2_2.Battery` — the Module1 detail the emulator pins (Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent) + `#Battery.SelfTest`/`#Battery.Calibrate`/`#Battery.Reset` action defs — DOCS-21 |
| `redfish/schemas/v1/Battery.v1_5_0.json` | https://redfish.dmtf.org/schemas/v1/Battery.v1_5_0.json | 2026-10-24 12:14 | `02deb6169a716ac0f53eeb7ed35375bb18cc6cd26a1dcccfc906699bb82c14cc` | 31,888 | DMTF 2026.x | Newest Battery def — adds BatteryChemistryType/EnergyStorageType/NominalOutputVoltage/ServicedDate only (delta note vs the served v1_2_2) — DOCS-21 |
| `redfish/schemas/v1/BatteryCollection.json` | https://redfish.dmtf.org/schemas/v1/BatteryCollection.json | 2026-10-24 12:14 | `a5f65f6714692154806876e88241aef6cdd6bf56ce6e01d436caf4259648390d` | 4,975 | latest per aggregator | `#BatteryCollection.BatteryCollection` — the collection the EMU battery pin enumerates — DOCS-21 |
| `redfish/schemas/v1/BatteryMetrics.json` | https://redfish.dmtf.org/schemas/v1/BatteryMetrics.json | 2026-10-24 12:14 | `6db7acd63802fff243596c0a45a44121cf474ff9b11432885c3dfac9bb3f736c` | 1,448 | latest per aggregator | BatteryMetrics family aggregator — resolves `#BatteryMetrics.BatteryMetrics` citations — DOCS-21 |
| `redfish/schemas/v1/BatteryMetrics.v1_0_3.json` | https://redfish.dmtf.org/schemas/v1/BatteryMetrics.v1_0_3.json | 2026-10-24 12:14 | `5e642e47db7c9532eb84d89ef0eb8f8c6e7f28f6344fecad01bd0e4d00d147d9` | 12,790 | DMTF 2021.x | **Mockup-served** `#BatteryMetrics.v1_0_3.BatteryMetrics` — electrical telemetry pinned by the emulator (InputVoltage/OutputVoltages/InputCurrentAmps/OutputCurrentAmps/StoredEnergyWattHours/TemperatureCelsius/ChargePercent/CellVoltages, `Sensor*Excerpt` refs + DataSourceUri) — DOCS-21 |
| `redfish/schemas/v1/BatteryMetrics.v1_1_0.json` | https://redfish.dmtf.org/schemas/v1/BatteryMetrics.v1_1_0.json | 2026-10-24 12:14 | `fc09a3bedbdfe35ee272cebffc9b2779dd977e885d3c8e2e916b93a1dfa0e479` | 14,986 | DMTF 2022.x | Newest BatteryMetrics def — adds CRate/ERate only (delta note vs served v1_0_3) — DOCS-21 |
| `redfish/schemas/v1/EnvironmentMetrics.v1_7_0.json` | https://redfish.dmtf.org/schemas/v1/EnvironmentMetrics.v1_7_0.json | 2026-10-24 12:47 | `fda1312b586088277262b2185366a8b0579988d084b31b22072345ec31f1e54e` | 22,003 | DMTF 2026.x | Newest EnvironmentMetrics — adds AmbientTemperatureCelsius/BarometricPressureMm/CurrentAmps/DewPointProximityCelsius/Voltage (additive vs served v1_3_1) — DOCS-22 |
| `redfish/schemas/v1/Fan.v1_6_0.json` | https://redfish.dmtf.org/schemas/v1/Fan.v1_6_0.json | 2026-10-24 12:47 | `4d1496a5e094d65b1f1ef0103a3822a76dd0bc0c70fb36c9c4c038d669088e4f` | 18,934 | DMTF 2026.x | Newest Fan — adds RatedSpeedRPM/RatedSecondarySpeedRPM (additive vs served v1_5_1) — DOCS-22 |
| `redfish/schemas/v1/PowerSubsystem.v1_2_0.json` | https://redfish.dmtf.org/schemas/v1/PowerSubsystem.v1_2_0.json | 2026-10-24 12:47 | `a88aea554901aa482834e7cc0ebdd4abfbb111f34c1a0bf74b8b84326af66e2c` | 22,174 | DMTF 2026.x | Newest PowerSubsystem — adds Applied/Enabled/Links/LoadPercentThreshold/MaxRampRateWattsPerSecond/PowerBrake(+sensors)/TemperatureThreshold (additive vs served v1_1_1) — DOCS-22 |
| `redfish/schemas/v1/PowerSupply.v1_8_0.json` | https://redfish.dmtf.org/schemas/v1/PowerSupply.v1_8_0.json | 2026-10-24 12:47 | `9816f1e7f47540ec28e9c242eff7c6d3448612bf4b090f9c6e0e1fe4e744f019` | 37,552 | DMTF 2026.x | Newest PowerSupply — adds Certificates/VoltageControl (additive vs served v1_5_3) — DOCS-22 |
| `redfish/schemas/v1/PowerSupplyMetrics.v1_3_0.json` | https://redfish.dmtf.org/schemas/v1/PowerSupplyMetrics.v1_3_0.json | 2026-10-24 12:47 | `ae2e6b0c02c668aee6facbe8a9747dd68d36f5c6c98bf1395aeb42922f45cf3f` | 46,503 | DMTF 2026.x | Newest PowerSupplyMetrics — adds ChargePercent/Line*/PolyPhase*/PowerLoadPercent (additive vs served v1_1_1) — DOCS-22 |
| `redfish/schemas/v1/TaskService.v1_3_0.json` | https://redfish.dmtf.org/schemas/v1/TaskService.v1_3_0.json | 2026-10-24 12:47 | `0ff595276fedaef23cb6840757d93473d6fce3acf6bc7bd9480de269cc2b613d` | 11,802 | DMTF 2026.x | Newest TaskService — adds `#TaskService.DeleteAllCompletedTasks` action + TaskMonitorAutoExpirySeconds (additive vs v1_2_1) — DOCS-22 |
| `redfish/schemas/v1/ThermalMetrics.v1_3_3.json` | https://redfish.dmtf.org/schemas/v1/ThermalMetrics.v1_3_3.json | 2026-10-24 12:47 | `8618fcf00538422383eba106cca40c68767e3e294c2c77f1e13845314b7f704b` | 19,245 | DMTF 2026.x | Newest ThermalMetrics — structural no-op vs v1_3_1 (copyright/anyOf-normalization only) — DOCS-22 |
| `redfish/schemas/v1/ThermalSubsystem.v1_5_0.json` | https://redfish.dmtf.org/schemas/v1/ThermalSubsystem.v1_5_0.json | 2026-10-24 12:47 | `ba191747b75c257efc50e1d3d387c291625d83eb0f7e1a5eca5fc0a390e48e75` | 11,555 | DMTF 2026.x | Newest ThermalSubsystem — adds FansFullSpeedOverrideEnable/Filters (additive vs served v1_3_1) — DOCS-22 |
| `redfish/schemas/v1/Bios.v1_2_2.json` | https://redfish.dmtf.org/schemas/v1/Bios.v1_2_2.json | 2026-10-24 15:17 | `404e8a17d50a6cbf00d5027b63b0c5f23087ba93f16a60d2491577c3f4b65028` | 16,485 | DMTF 2019.x | **Mockup-served** `#Bios.v1_2_2.Bios` — the Bios resource the EMU-2 pin reads (`@Redfish.Settings` ETag, pending-settings compare, ResetBios/ChangePassword) — DOCS-23 |
| `redfish/schemas/v1/Bios.v1_3_0.json` | https://redfish.dmtf.org/schemas/v1/Bios.v1_3_0.json | 2026-10-24 15:17 | `65beebaa0f689693b4175eaaacbbae27eac767c2ed74e9c55fd1c312a01075f8` | 20,646 | DMTF 2026.x | Newest Bios — adds `Passwords` resource (additive vs served v1_2_2) — DOCS-23 |
| `redfish/schemas/v1/Settings.v1_3_5.json` | https://redfish.dmtf.org/schemas/v1/Settings.v1_3_5.json | 2026-10-24 15:17 | `c05bc148013fd9d5270192da71d7c5a0362ab81d8cc54f3f527939f18d791ea9` | 15,194 | DMTF 2020.x | **Mockup-served** `#Settings.v1_3_5.Settings` — the `@Redfish.Settings` annotation type pinned by EMU-2 (SettingsObject/Messages) — DOCS-23 |
| `redfish/schemas/v1/Settings.v1_5_0.json` | https://redfish.dmtf.org/schemas/v1/Settings.v1_5_0.json | 2026-10-24 15:17 | `8d481104a194fbcdf474fb9c068704f28a98de6dffc899f3fc538d2b7351d616` | 15,695 | DMTF 2026.x | Newest Settings — **no property delta** vs served v1_3_5 (structural/description-level only) — DOCS-23 |
| `redfish/schemas/v1/EventDestination.json` | https://redfish.dmtf.org/schemas/v1/EventDestination.json | 2026-10-24 19:18 | `f4aa85812c3300dbc0e4bafdee0f4d024d0a11363cb15a7d2ea39cfe64e70c25` | 4,937 | latest per aggregator | EventDestination family aggregator — resolves `#EventDestination.EventDestination` citations (DOCS-7 bed, #019) — DOCS-24 |
| `redfish/schemas/v1/EventDestination.v1_14_0.json` | https://redfish.dmtf.org/schemas/v1/EventDestination.v1_14_0.json | 2026-10-24 19:18 | `489c765b2f9b9818f2557fe6db56debf1fac65d9026f838e6c1fa0a337816455` | 60,342 | DMTF 2023.x | **Mockup-served** `#EventDestination.v1_14_0.EventDestination` — the 4 Subscriptions members the EMU-2 pin reads (Redfish/SNMPv3/SMTP-OEM/SyslogTCP transports, SNMP key material null) — DOCS-24 |
| `redfish/schemas/v1/EventDestination.v1_17_1.json` | https://redfish.dmtf.org/schemas/v1/EventDestination.v1_17_1.json | 2026-10-24 19:18 | `660a432886273955bc70f9492e529131854657d577c33c8a8f243d045e74fa80` | 62,941 | DMTF 2026.x | Newest EventDestination — adds BackupDestinations/Certificates/ClientCertificates/EventFormatType/HeartbeatIntervalMinutes/HttpHeaders/OEM*/OriginResources/SendHeartbeat/Severities/SubordinateResources/SyslogFilters/VerifyCertificate (+Actions/Status) — DOCS-24 |
| `redfish/schemas/v1/EventDestinationCollection.json` | https://redfish.dmtf.org/schemas/v1/EventDestinationCollection.json | 2026-10-24 19:18 | `561dc4cc7d654f8d64c6ce89e4ce0a9bd2381983ac6818e938508198e7f8b2c8` | 5,037 | latest per aggregator | `#EventDestinationCollection.EventDestinationCollection` — the Subscriptions collection type the EMU-2 pin enumerates — DOCS-24 |
| `redfish/schemas/v1/VirtualMedia.json` | https://redfish.dmtf.org/schemas/v1/VirtualMedia.json | 2026-10-24 19:18 | `b835bffdeb278d856af3d0c3e5c012e54344f75c9d8f1772c0071d61564bd2b8` | 2,937 | latest per aggregator | VirtualMedia family aggregator — resolves `#VirtualMedia.VirtualMedia` citations (#028 boot-media) — DOCS-24 |
| `redfish/schemas/v1/VirtualMedia.v1_6_3.json` | https://redfish.dmtf.org/schemas/v1/VirtualMedia.v1_6_3.json | 2026-10-24 19:18 | `d4c4aa15fd15989243c33c188665f6705f5e2bd1e8424b739178591214190e21` | 24,898 | DMTF 2023.x | **Mockup-served** `#VirtualMedia.v1_6_3.VirtualMedia` — the CD1/Floppy1 detail the EMU-2 pin reads (ConnectedVia/Image/ImageName/Inserted/WriteProtected/MediaTypes; NO InsertMedia/EjectMedia targets) — DOCS-24 |
| `redfish/schemas/v1/VirtualMedia.v1_7_0.json` | https://redfish.dmtf.org/schemas/v1/VirtualMedia.v1_7_0.json | 2026-10-24 19:18 | `08f6e3ca24cc8c3efcbbf87b5f2edec1e8e88499298e85eb23072b806d5b030f` | 27,768 | DMTF 2026.x | Newest VirtualMedia — adds Certificates/ClientCertificates/EjectPolicy/EjectTimeout/HTTPHeaders/Password/Status/TransferMethod/TransferProtocolType/UserName (+Actions) — DOCS-24 |
| `redfish/schemas/v1/VirtualMediaCollection.json` | https://redfish.dmtf.org/schemas/v1/VirtualMediaCollection.json | 2026-10-24 19:18 | `71ec62b65aa41a33ae66ae3ef01e194e61956df2227ce1d4a620ff1f487ba799` | 5,418 | latest per aggregator | `#VirtualMediaCollection.VirtualMediaCollection` — the system VirtualMedia collection the EMU-2 pin enumerates — DOCS-24 |
| `redfish/schemas/v1/SecureBoot.json` | https://redfish.dmtf.org/schemas/v1/SecureBoot.json | 2026-10-24 18:33 | `7473edff14b3be135a862fe9cf2d67f7ece30c0192c8e995ab8ae2b600673896` | 1,802 | latest per aggregator | SecureBoot family aggregator — `$ref`s v1_0_9/v1_1_2/v1_2_1; resolves `#SecureBoot.SecureBoot` citations (boot-integrity surface) — DOCS-25 |
| `redfish/schemas/v1/SecureBoot.v1_1_1.json` | https://redfish.dmtf.org/schemas/v1/SecureBoot.v1_1_1.json | 2026-10-24 18:33 | `c875bf720e40017f077efee3e5527ad238aafe28d812897ec906fe779ae7bc04` | 11,629 | DMTF 2022.x | **Mockup-served** `#SecureBoot.v1_1_1.SecureBoot` — SecureBootEnable/CurrentBoot/Mode + `#SecureBoot.ResetKeys` `ResetKeysType@Redfish.AllowableValues` (ResetAllKeysToDefault/DeleteAllKeys/DeletePK) — DOCS-25 |
| `redfish/schemas/v1/SecureBoot.v1_2_1.json` | https://redfish.dmtf.org/schemas/v1/SecureBoot.v1_2_1.json | 2026-10-24 18:33 | `ade82fcf3f142bbdab2d885361a037d473c1825774d430e4b34f97d1c4d91e10` | 12,567 | DMTF 2026.1 | Newest SecureBoot — adds `SecureBootDesiredMode` (additive vs served v1_1_1) — DOCS-25 |
| `redfish/schemas/v1/SecureBootDatabase.json` | https://redfish.dmtf.org/schemas/v1/SecureBootDatabase.json | 2026-10-24 18:33 | `c21dd794178050db683bb9d1dca1bd2354cb9cd63064d60711673869d90caa1d` | 1,636 | latest per aggregator | SecureBootDatabase family aggregator — `$ref`s v1_0_3; resolves `#SecureBootDatabase.SecureBootDatabase` citations — DOCS-25 |
| `redfish/schemas/v1/SecureBootDatabase.v1_0_2.json` | https://redfish.dmtf.org/schemas/v1/SecureBootDatabase.v1_0_2.json | 2026-10-24 18:33 | `1f908e05df60bc7737c2cc74274e11b95b86cf30e2517c695640d0f9b3c61d4d` | 9,765 | DMTF 2020.x | **Mockup-served** `#SecureBootDatabase.v1_0_2.SecureBootDatabase` — per-database surface (DatabaseId/Certificates/Signatures + per-resource `#SecureBootDatabase.ResetKeys` smaller allow-list, PK omits DeletePK) — DOCS-25 |
| `redfish/schemas/v1/SecureBootDatabase.v1_0_3.json` | https://redfish.dmtf.org/schemas/v1/SecureBootDatabase.v1_0_3.json | 2026-10-24 18:33 | `8133c7200e2302ab3301faf5fb8387c068d7f1f456a7d793b5234777bdf5b1ec` | 9,795 | DMTF 2020.1 | Newest SecureBootDatabase — **no property delta** vs served v1_0_2 (11→11 props) — DOCS-25 |
| `redfish/schemas/v1/SecureBootDatabaseCollection.json` | https://redfish.dmtf.org/schemas/v1/SecureBootDatabaseCollection.json | 2026-10-24 18:33 | `d862817e20a8d6a5cb89e7748b5d940ad1fa64dc08983d298c4dbd42edbb9093` | 5,350 | latest per aggregator | `#SecureBootDatabaseCollection.SecureBootDatabaseCollection` — the 8-member PK/KEK/db/dbx + defaults collection the EMU-2 pin enumerates — DOCS-25 |
| `redfish/schemas/v1/Control.json` | https://redfish.dmtf.org/schemas/v1/Control.json | 2026-10-24 20:14 | `7e3c135752e872e53b71faa23b264f36f3b7bd87279ce3c24785f04eaef85def` | 9,694 | latest per aggregator | Control family aggregator — `$ref`s v1_0_7/v1_1_6/v1_2_6/v1_3_6/v1_4_6/v1_5_5/v1_6_3/v1_7_2/v1_8_1; resolves `#Control.Control` citations (power-limit/frequency control surface) — DOCS-26 |
| `redfish/schemas/v1/Control.v1_5_0.json` | https://redfish.dmtf.org/schemas/v1/Control.v1_5_0.json | 2026-10-24 20:14 | `de1614b0de069eb648ff125053fa90910c1dce882bd39c2f9f882e5264d98bd1` | 47,414 | DMTF 2023.x | **Mockup-served** `#Control.v1_5_0.Control` — ControlType/ControlMode/SetPoint/AllowableMax/Min/SettingMin/Max/Sensor excerpt with DataSourceUri (PowerLimit + CPU1Freq pins) — DOCS-26 |
| `redfish/schemas/v1/Control.v1_8_1.json` | https://redfish.dmtf.org/schemas/v1/Control.v1_8_1.json | 2026-10-24 20:14 | `e6412df9e3bb779edb46f9f0f69bc5f60c9addbaaa58a172ae0c4804015fa88e` | 67,784 | DMTF 2026.2 | Newest Control — adds `SetPointError` (readonly, v1_7_0, additive vs served v1_5_0) — DOCS-26 |
| `redfish/schemas/v1/ControlCollection.json` | https://redfish.dmtf.org/schemas/v1/ControlCollection.json | 2026-10-24 20:14 | `4faca423621f38515fcc9234e444a36019817793e6377d764ad0593330504785` | 4,959 | latest per aggregator | `#ControlCollection.ControlCollection` — the Chassis.1U.Controls enumeration (PowerLimit + CPU1Freq members) the EMU-2 pin reads — DOCS-26 |
| `redfish/schemas/v1/Heater.json` | https://redfish.dmtf.org/schemas/v1/Heater.json | 2026-10-25 02:11 | `6fbceeeae8c1323347cec0df76003b3d04faa6bbe7825c37f5985fc7fd28510c` | 1,252 | latest per aggregator | Heater family aggregator — `$ref`s v1_0_0/v1_0_1/v1_0_2; resolves `#Heater.Heater` citations (thermal-heater surface) — DOCS-28 |
| `redfish/schemas/v1/Heater.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/Heater.v1_0_1.json | 2026-10-25 02:11 | `09002a7f554311bce7c3c9e8d23b477e05674aece530bcc5154527747a983963` | 16,421 | DMTF 2023.x | **Mockup-served** `#Heater.v1_0_1.Heater` — CPU1Heater detail the EMU-2 pin reads (PhysicalContext/Manufacturer/Model/SerialNumber/HotPluggable/LocationIndicatorActive/Status + `Links.Processors` + `Metrics` link) — DOCS-28 |
| `redfish/schemas/v1/Heater.v1_0_2.json` | https://redfish.dmtf.org/schemas/v1/Heater.v1_0_2.json | 2026-10-25 02:11 | `8d04775c9c02201dacfaf52e19ef2b405fbf2af502b912dd738b117e9d4aba20` | 16,449 | DMTF 2024.x | Newest Heater — **property no-op** vs served v1_0_1 (26 diff lines: `$id`/copyright/backtick-quoted descriptions/`language`/title only) — DOCS-28 |
| `redfish/schemas/v1/HeaterMetrics.json` | https://redfish.dmtf.org/schemas/v1/HeaterMetrics.json | 2026-10-25 02:11 | `f88ecdca65cba5aefaaa83d7911ce818178cd44c26580d0f8ce301d310c06712` | 1,275 | latest per aggregator | HeaterMetrics family aggregator — `$ref`s v1_0_0/v1_0_1/v1_0_2; resolves `#HeaterMetrics.HeaterMetrics` citations — DOCS-28 |
| `redfish/schemas/v1/HeaterMetrics.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/HeaterMetrics.v1_0_1.json | 2026-10-25 02:11 | `9060b7665d15ac6871b65fe6e613226a6a6ec745ecbdfc2f41c471e9bb3f0303` | 9,823 | DMTF 2023.x | **Mockup-served** `#HeaterMetrics.v1_0_1.HeaterMetrics` — pre-power-on/runtime heating seconds, PowerWatts.Reading, TemperatureReadingsCelsius + advertised `#HeaterMetrics.ResetMetrics` (no `/Actions/` segment → 404 candidate) — DOCS-28 |
| `redfish/schemas/v1/HeaterMetrics.v1_0_2.json` | https://redfish.dmtf.org/schemas/v1/HeaterMetrics.v1_0_2.json | 2026-10-25 02:11 | `82086f0668d633a3f8c83398a686ee73045699b3a88f62327a15a8b988d65825` | 9,859 | DMTF 2024.x | Newest HeaterMetrics — **property no-op** vs served v1_0_1 (26 diff lines: `$id`/copyright/backtick-quoted descriptions/`language`/title only) — DOCS-28 |
| `redfish/schemas/v1/HeaterCollection.json` | https://redfish.dmtf.org/schemas/v1/HeaterCollection.json | 2026-10-25 02:11 | `574a1e99434ebee6397cedf8801718876246eb1f4b87912e3625458edc65768d` | 4,966 | latest per aggregator | `#HeaterCollection.HeaterCollection` — the `ThermalSubsystem.Heaters` enumeration (CPU1Heater member) the EMU-2 pin reads — DOCS-28 |
| `redfish/schemas/v1/CertificateService.json` | https://redfish.dmtf.org/schemas/v1/CertificateService.json | 2026-10-25 15:40 | `d6f0982ec6c3b027148823524a8a02f1883696d0d1a0a09f2ca5e2f1ca8b54ba` | 1,668 | latest per aggregator | CertificateService family aggregator — `$ref`s v1_0_4/v1_1_3/v1_2_2; resolves `#CertificateService.CertificateService` citations — DOCS-30 |
| `redfish/schemas/v1/CertificateService.v1_0_4.json` | https://redfish.dmtf.org/schemas/v1/CertificateService.v1_0_4.json | 2026-10-25 15:40 | `8aa3f9ada1de7e9f85332ce086ed2f94a3bd00e96dbe0667d5d41b107197d3cd` | 21,182 | DMTF 2022.x | **Mockup-served** `#CertificateService.v1_0_4.CertificateService` — the GenerateCSR/ReplaceCertificate action targets + the `CertificateLocations` link the EMU-2 pin reads — DOCS-30 |
| `redfish/schemas/v1/CertificateService.v1_2_2.json` | https://redfish.dmtf.org/schemas/v1/CertificateService.v1_2_2.json | 2026-10-25 15:40 | `be2abd4d5185b5945ff6095a870fa01abd51753ca434f5f64d378c27be0ea9ac` | 26,915 | DMTF 2026.x | Newest CertificateService — adds `AutomaticCertificateEnrollment`/`CertificateEnrollments`/`EnrollmentCACertificates` (readonly add, no client code change) — DOCS-30 |
| `redfish/schemas/v1/CertificateLocations.json` | https://redfish.dmtf.org/schemas/v1/CertificateLocations.json | 2026-10-25 15:40 | `6b2fcef48d1ef3119ecf17453b0c9e2a80a67b828d6515359d63d149f856ac2a` | 1,370 | latest per aggregator | CertificateLocations family aggregator — `$ref`s v1_0_3 + v1_0_4; resolves `#CertificateLocations.CertificateLocations` citations — DOCS-30 |
| `redfish/schemas/v1/CertificateLocations.v1_0_3.json` | https://redfish.dmtf.org/schemas/v1/CertificateLocations.v1_0_3.json | 2026-10-25 15:40 | `c32fe9021957093674118420a658cacabf89134212254f69538eb960a85c0eef` | 8,271 | DMTF 2021.x | **Mockup-served** `#CertificateLocations.v1_0_3.CertificateLocations` — the `Links.Certificates` three-store pin list (HTTPS server / UpdateService client / VirtualMedia cert) the EMU-2 pin reads — DOCS-30 |
| `redfish/schemas/v1/CertificateLocations.v1_0_4.json` | https://redfish.dmtf.org/schemas/v1/CertificateLocations.v1_0_4.json | 2026-10-25 15:40 | `5548aae603329101d274d30146fe39c838c5ac32c9ce78562fe4201bb8c04ec0` | 8,297 | DMTF 2023.x | Newest CertificateLocations — **property no-op** vs served v1_0_3 (diff: `$id`/copyright/`language`/description backticks only) — DOCS-30 |
| `redfish/schemas/v1/Certificate.json` | https://redfish.dmtf.org/schemas/v1/Certificate.json | 2026-10-25 15:40 | `0c87171aedbda6afce14176de88a5d8d614d1ea22d38614970047838e0e627ec` | 21,163 | latest per aggregator | Certificate family aggregator — `$ref`s v1_0_8 … v1_11_0; resolves `#Certificate.Certificate` citations — DOCS-30 |
| `redfish/schemas/v1/Certificate.v1_8_1.json` | https://redfish.dmtf.org/schemas/v1/Certificate.v1_8_1.json | 2026-10-25 15:40 | `a84952945ef1998e845464b3746fed9a305da9543aa483830eddce5002ff03fd` | 37,722 | DMTF 2023.x | **Mockup-served** `#Certificate.v1_8_1.Certificate` — the certificate-store member the EMU-2 Rekey/GenerateCSR pins read — DOCS-30 |
| `redfish/schemas/v1/Certificate.v1_11_0.json` | https://redfish.dmtf.org/schemas/v1/Certificate.v1_11_0.json | 2026-10-25 15:40 | `7fa29e64e7379f063134bb159a4e7cc74fa965ab7cd2242ffb26ec02a9b65867` | 39,278 | DMTF 2026.x | Newest Certificate — adds `Password`/`Status` (additive; `Password` is a #015/#026 never-read-back note) — DOCS-30 |
| `redfish/schemas/v1/CertificateCollection.json` | https://redfish.dmtf.org/schemas/v1/CertificateCollection.json | 2026-10-25 15:40 | `f54fd6b759dff2744a0270adaa7cc103c6eadd0152adace38d270383b818e0bf` | 15,617 | latest per aggregator | `#CertificateCollection.CertificateCollection` — the enumeration type behind every `/Certificates` collection the fixture serves — DOCS-30 |
| `redfish/schemas/v1/KeyService.json` | https://redfish.dmtf.org/schemas/v1/KeyService.json | 2026-10-25 15:40 | `8e9231d50e1bf52550a7408dc3e00667e27b8dcbac9754be2bb6323a29574196` | 1,213 | latest per aggregator | KeyService family aggregator — `$ref`s v1_0_0 + v1_0_1; resolves `#KeyService.KeyService` citations — DOCS-30 |
| `redfish/schemas/v1/KeyService.v1_0_0.json` | https://redfish.dmtf.org/schemas/v1/KeyService.v1_0_0.json | 2026-10-25 15:40 | `65a8bf31df9606dd558cdeb62a6e14e7677dc40cd6141404d5b7efd7f7f49157` | 6,848 | DMTF 2022.x | **Mockup-served** `#KeyService.v1_0_0.KeyService` — the NVMeoFSecrets (KeyCollection) + NVMeoFKeyPolicies links the EMU-2 pin reads — DOCS-30 |
| `redfish/schemas/v1/KeyService.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/KeyService.v1_0_1.json | 2026-10-25 15:40 | `5e1d3d40d40cbab580d53d6f2633b85adc11d6109dfcb5a46aafeffc6cbd7ab3` | 6,880 | DMTF 2023.x | Newest KeyService — **property no-op** vs served v1_0_0 (diff: `$id`/copyright/description backticks only) — DOCS-30 |
| `redfish/schemas/v1/KeyPolicy.json` | https://redfish.dmtf.org/schemas/v1/KeyPolicy.json | 2026-10-25 15:40 | `b77990d744b468d1ae95130f9dd55b6d9f835bd06da430bea302673788f303fc` | 1,233 | latest per aggregator | KeyPolicy family aggregator — `$ref`s v1_0_0 + v1_0_1; resolves `#KeyPolicy.KeyPolicy` citations — DOCS-30 |
| `redfish/schemas/v1/KeyPolicy.v1_0_0.json` | https://redfish.dmtf.org/schemas/v1/KeyPolicy.v1_0_0.json | 2026-10-25 15:40 | `9bae5ec4cccb57a9f6e9e1e67cb1ff1ec30c43b1a17775368ba4d44790a650d0` | 20,089 | DMTF 2022.x | **Mockup-served** `#KeyPolicy.v1_0_0.KeyPolicy` — the NVMeoF allow-list surface (SecurityTransport/CipherSuite/SecurityProtocol/DHGroup/SecureHash AllowLists) the EMU-2 pin reads — DOCS-30 |
| `redfish/schemas/v1/KeyPolicy.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/KeyPolicy.v1_0_1.json | 2026-10-25 15:40 | `fefedf96690e1e97606da9b4639380ae3650efccf407ea9a274c03aa4fee9102` | 19,914 | DMTF 2023.x | Newest KeyPolicy — **property no-op** vs served v1_0_0 (diff: `$id`/copyright/description backticks only) — DOCS-30 |
| `redfish/schemas/v1/KeyPolicyCollection.json` | https://redfish.dmtf.org/schemas/v1/KeyPolicyCollection.json | 2026-10-25 15:40 | `ad7e377bd545cb681591776c791e6fc376f01b71657968058657a905aad2e3b5` | 4,976 | latest per aggregator | `#KeyPolicyCollection.KeyPolicyCollection` — the NVMeoFKeyPolicies enumeration the EMU-2 pin reads — DOCS-30 |
| `redfish/schemas/v1/Key.json` | https://redfish.dmtf.org/schemas/v1/Key.json | 2026-10-25 15:40 | `11c8bad7db5cc99ae0f9c5201c72919dcd1068870819d6d0db3c6d9eb3cb23ee` | 5,386 | latest per aggregator | Key family aggregator — `$ref`s v1_0_1 … v1_4_1; resolves `#Key.Key` citations — DOCS-30 |
| `redfish/schemas/v1/Key.v1_4_0.json` | https://redfish.dmtf.org/schemas/v1/Key.v1_4_0.json | 2026-10-25 15:40 | `8db5960d77f428612db09733a497f1705286786ef3a5f048847c9f0f9676dc7a` | 17,977 | DMTF 2023.x | **Mockup-served** `#Key.v1_4_0.Key` — the NVMeoFSecrets KEY member surface; the suite pins collection-metadata only, never the `KeyString` body (the #015/#026 never-read-secrets-back rule) — DOCS-30 |
| `redfish/schemas/v1/Key.v1_4_1.json` | https://redfish.dmtf.org/schemas/v1/Key.v1_4_1.json | 2026-10-25 15:40 | `b6898b8dbde468778928402b6ad43c96b935b3f6b6831abfc4d9e02b92ac937c` | 17,601 | DMTF 2024.x | Newest Key — **property no-op** vs served v1_4_0 (diff: `$id`/copyright/description backticks only) — DOCS-30 |
| `redfish/schemas/v1/KeyCollection.json` | https://redfish.dmtf.org/schemas/v1/KeyCollection.json | 2026-10-25 15:40 | `44801a41ff93c0cc54c73c82710f92ddb21ae01d4a8d3f487f4710a6e0a6ecc7` | 5,281 | latest per aggregator | `#KeyCollection.KeyCollection` — the NVMeoFSecrets collection the EMU-2 pin reads as collection-metadata-only — DOCS-30 |
| `redfish/schemas/v1/ComponentIntegrity.json` | https://redfish.dmtf.org/schemas/v1/ComponentIntegrity.json | 2026-10-25 15:40 | `5f263dea6ff0a0368f1ae86091e961e749ec0dbdad0b820afaac74b1fb455c64` | 2,248 | latest per aggregator | ComponentIntegrity family aggregator — `$ref`s v1_0_7 … v1_5_0; resolves `#ComponentIntegrity.ComponentIntegrity` citations — DOCS-30 |
| `redfish/schemas/v1/ComponentIntegrity.v1_2_2.json` | https://redfish.dmtf.org/schemas/v1/ComponentIntegrity.v1_2_2.json | 2026-10-25 15:40 | `a45c13b007675d8e248ceca550228d59394280e530a6ea94df6a1fefb5614ebc` | 71,839 | DMTF 2023.x | **Mockup-served** `#ComponentIntegrity.v1_2_2.ComponentIntegrity` — the SPDM/TPM/USB member shapes (incl. the disabled USB member) the EMU-2 pin reads — DOCS-30 |
| `redfish/schemas/v1/ComponentIntegrity.v1_5_0.json` | https://redfish.dmtf.org/schemas/v1/ComponentIntegrity.v1_5_0.json | 2026-10-25 15:40 | `d44725c9019e6496183758652ad124e197408269b1e37b361b8b7b8a36363ef9` | 78,241 | DMTF 2026.x | Newest ComponentIntegrity — **property no-op** vs served v1_2_2 for the client-relevant surface (SPDM/TPM/USB member fields) — DOCS-30 |
| `redfish/schemas/v1/ComponentIntegrityCollection.json` | https://redfish.dmtf.org/schemas/v1/ComponentIntegrityCollection.json | 2026-10-25 15:40 | `844d284867589391b7d39eb7b3d177c996e61f060fd39cd8fee2024606701160` | 5,048 | latest per aggregator | `#ComponentIntegrityCollection.ComponentIntegrityCollection` — the 4-member enumeration (SS-SPDM-0/1, USB-Integrity, TPM-0) the EMU-2 pin reads — DOCS-30 |

| `redfish/schemas/v1/AccelerationFunction.json` | https://redfish.dmtf.org/schemas/v1/AccelerationFunction.json | 2026-10-25 12:15 | `234abf9b501d16be603ce9ba9bf189e7f2884e516278e1964625b65c39700c7a` | 2,327 | latest per aggregator | AccelerationFunction family aggregator — resolves `#AccelerationFunction.AccelerationFunction` citations — DOCS-31 |
| `redfish/schemas/v1/AccelerationFunction.v1_0_4.json` | https://redfish.dmtf.org/schemas/v1/AccelerationFunction.v1_0_4.json | 2026-10-25 12:15 | `4c51d92c3a35fcb6c87c5522e45be3e1b6bf2f3c9da7fd1ace0fc568c32fd629` | 13,586 | latest per aggregator | **Mockup-served** `#AccelerationFunction.v1_0_4.AccelerationFunction` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/AccelerationFunction.v1_0_5.json` | https://redfish.dmtf.org/schemas/v1/AccelerationFunction.v1_0_5.json | 2026-10-25 12:15 | `35f7ac1a7a086b4fe72803137a74c225f891293e39ccf4c98605dc5d9da5305e` | 13,617 | latest per aggregator | Newest AccelerationFunction — property-delta audit vs served v1_0_4: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/Assembly.json` | https://redfish.dmtf.org/schemas/v1/Assembly.json | 2026-10-25 12:15 | `c13f50f75c042ca9364fc9a3499b77f556aa4536b3223d65c7fc0479a2fdfa43` | 12,375 | latest per aggregator | Assembly family aggregator — resolves `#Assembly.Assembly` citations — DOCS-31 |
| `redfish/schemas/v1/Assembly.v1_5_0.json` | https://redfish.dmtf.org/schemas/v1/Assembly.v1_5_0.json | 2026-10-25 12:15 | `e785c46bf9f541f178273a91f759ff4eb5851d2909cdb51b63124c592f20eb69` | 20,172 | latest per aggregator | **Mockup-served** `#Assembly.v1_5_0.Assembly` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/Assembly.v1_6_1.json` | https://redfish.dmtf.org/schemas/v1/Assembly.v1_6_1.json | 2026-10-25 12:15 | `a7a6c46e3970943e46625a8374bdee2e23b51c52677351bc293bf0e192e936b2` | 20,844 | latest per aggregator | Newest Assembly — property-delta audit vs served v1_5_0: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/ExternalAccountProvider.json` | https://redfish.dmtf.org/schemas/v1/ExternalAccountProvider.json | 2026-10-25 12:15 | `2d5de1baeeeae8848a6db6cec5289cb56252dd555e79ff3491b7514ebf286f19` | 3,097 | latest per aggregator | ExternalAccountProvider family aggregator — resolves `#ExternalAccountProvider.ExternalAccountProvider` citations — DOCS-31 |
| `redfish/schemas/v1/ExternalAccountProvider.v1_7_1.json` | https://redfish.dmtf.org/schemas/v1/ExternalAccountProvider.v1_7_1.json | 2026-10-25 12:15 | `24a40f3081e758b282e824146e7bddf2ea29b33cd1b3372b63970ed89442e606` | 43,337 | latest per aggregator | **Mockup-served** `#ExternalAccountProvider.v1_7_1.ExternalAccountProvider` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/ExternalAccountProvider.v1_9_0.json` | https://redfish.dmtf.org/schemas/v1/ExternalAccountProvider.v1_9_0.json | 2026-10-25 12:15 | `890fbe32f5c09c34ad022178d2093bf36818bc657bfc1078ec9a9b28d25bca60` | 48,089 | latest per aggregator | Newest ExternalAccountProvider — property-delta audit vs served v1_7_1: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/GraphicsController.json` | https://redfish.dmtf.org/schemas/v1/GraphicsController.json | 2026-10-25 12:15 | `2aaa0896c21508b014b3315ef332a6a9a5609dcaad620552364fe88dfec6c16c` | 1,338 | latest per aggregator | GraphicsController family aggregator — resolves `#GraphicsController.GraphicsController` citations — DOCS-31 |
| `redfish/schemas/v1/GraphicsController.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/GraphicsController.v1_0_1.json | 2026-10-25 12:15 | `e3a1f491048223de3055c788f19b926c3b24cad439f88f69770b542895441818` | 14,152 | latest per aggregator | **Mockup-served** `#GraphicsController.v1_0_1.GraphicsController` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/GraphicsController.v1_0_2.json` | https://redfish.dmtf.org/schemas/v1/GraphicsController.v1_0_2.json | 2026-10-25 12:15 | `bcb5690ab382f7cfe057a0298aa6c2c63778ec1ab5b2f51eda4a01f170af1b70` | 13,973 | latest per aggregator | Newest GraphicsController — property-delta audit vs served v1_0_1: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/HostInterface.json` | https://redfish.dmtf.org/schemas/v1/HostInterface.json | 2026-10-25 12:15 | `0384dffcc3c46bf0b6d33b2ae92434aa1c8ec9c2c939091509cf2a09b328abee` | 1,976 | latest per aggregator | HostInterface family aggregator — resolves `#HostInterface.HostInterface` citations — DOCS-31 |
| `redfish/schemas/v1/HostInterface.v1_3_1.json` | https://redfish.dmtf.org/schemas/v1/HostInterface.v1_3_1.json | 2026-10-25 12:15 | `0fb1976eabf6e6b4a279cb17d4654b9d2d77cc4ec5ad37cdfb2584a26dbdfb04` | 22,911 | latest per aggregator | **Mockup-served** `#HostInterface.v1_3_1.HostInterface` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/HostInterface.v1_4_0.json` | https://redfish.dmtf.org/schemas/v1/HostInterface.v1_4_0.json | 2026-10-25 12:15 | `bece9a9147b26502df7d965728c41749ee49eba4022f424792d5bb6c2546906b` | 24,759 | latest per aggregator | Newest HostInterface — property-delta audit vs served v1_3_1: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/Memory.json` | https://redfish.dmtf.org/schemas/v1/Memory.json | 2026-10-25 12:15 | `edbd19d7232c1aba81d1db193b9bf7ac0b576303399fa8e4e294573a3bfc7593` | 5,540 | latest per aggregator | Memory family aggregator — resolves `#Memory.Memory` citations — DOCS-31 |
| `redfish/schemas/v1/Memory.v1_19_0.json` | https://redfish.dmtf.org/schemas/v1/Memory.v1_19_0.json | 2026-10-25 12:15 | `269f83c45dd28a0cc5f2bc96c7d9dc5e5cd86007a3fd3f35fd8877ed85d76aec` | 100,762 | latest per aggregator | **Mockup-served** `#Memory.v1_19_0.Memory` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/Memory.v1_24_0.json` | https://redfish.dmtf.org/schemas/v1/Memory.v1_24_0.json | 2026-10-25 12:15 | `d5605e51993f1bfa829d0dc3b3dc7d62949075706ebd661c35715affa39b43be` | 104,151 | latest per aggregator | Newest Memory — property-delta audit vs served v1_19_0: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/MessageRegistryFile.json` | https://redfish.dmtf.org/schemas/v1/MessageRegistryFile.json | 2026-10-25 12:15 | `bf6499a9252264c20b686a66d9cc270b9b429764398e2234af097e60ec0540ad` | 1,574 | latest per aggregator | MessageRegistryFile family aggregator — resolves `#MessageRegistryFile.MessageRegistryFile` citations — DOCS-31 |
| `redfish/schemas/v1/MessageRegistryFile.v1_1_4.json` | https://redfish.dmtf.org/schemas/v1/MessageRegistryFile.v1_1_4.json | 2026-10-25 12:15 | `3d8fd136f9c91d83d2fbd648358eec7c422d84e46a99ed5583b5acef61c4424b` | 11,068 | latest per aggregator | **Mockup-served** `#MessageRegistryFile.v1_1_4.MessageRegistryFile` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/MessageRegistryFile.v1_1_5.json` | https://redfish.dmtf.org/schemas/v1/MessageRegistryFile.v1_1_5.json | 2026-10-25 12:15 | `4cdc6809d3c426bd6f6930bfde882193c65db229c65b1db219fc79fc5f2a0345` | 11,097 | latest per aggregator | Newest MessageRegistryFile — property-delta audit vs served v1_1_4: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/OutboundConnection.json` | https://redfish.dmtf.org/schemas/v1/OutboundConnection.json | 2026-10-25 12:15 | `87f037471101d6df5273ae21a02eeb216cf310745fe7a3dd587c917c8978c76d` | 1,598 | latest per aggregator | OutboundConnection family aggregator — resolves `#OutboundConnection.OutboundConnection` citations — DOCS-31 |
| `redfish/schemas/v1/OutboundConnection.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/OutboundConnection.v1_0_1.json | 2026-10-25 12:15 | `9e6e18db42aa6b20b2b5ca9d614f50f290bf400d92096ef4299d904937e24743` | 21,366 | latest per aggregator | **Mockup-served** `#OutboundConnection.v1_0_1.OutboundConnection` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/OutboundConnection.v1_0_3.json` | https://redfish.dmtf.org/schemas/v1/OutboundConnection.v1_0_3.json | 2026-10-25 12:15 | `b41d5bdc952613cfcd8da836fe9347e6246304cd0ee3a66832dba5c5381555c8` | 21,422 | latest per aggregator | Newest OutboundConnection — property-delta audit vs served v1_0_1: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/Port.json` | https://redfish.dmtf.org/schemas/v1/Port.json | 2026-10-25 12:15 | `53641e1fc36250c60276f887accf5bdfe47f73c39faacd218e40cf374890cf6e` | 8,194 | latest per aggregator | Port family aggregator — resolves `#Port.Port` citations — DOCS-31 |
| `redfish/schemas/v1/Port.v1_11_0.json` | https://redfish.dmtf.org/schemas/v1/Port.v1_11_0.json | 2026-10-25 12:15 | `ff45816675febe3beb2464274062c339fe5b96762643d639047a26e65bb7121f` | 111,928 | latest per aggregator | **Mockup-served** `#Port.v1_11_0.Port` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/Port.v1_20_0.json` | https://redfish.dmtf.org/schemas/v1/Port.v1_20_0.json | 2026-10-25 12:15 | `9e04f5b1db2b666dd1d4d16d74aee4f14df39e40689a454c7e0892727db876c9` | 179,810 | latest per aggregator | Newest Port — property-delta audit vs served v1_11_0: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/Processor.json` | https://redfish.dmtf.org/schemas/v1/Processor.json | 2026-10-25 12:15 | `943ed26f4b563df6d83b683c7a80c8d69f650071f1e24d28640352f578b3b593` | 8,137 | latest per aggregator | Processor family aggregator — resolves `#Processor.Processor` citations — DOCS-31 |
| `redfish/schemas/v1/Processor.v1_19_0.json` | https://redfish.dmtf.org/schemas/v1/Processor.v1_19_0.json | 2026-10-25 12:15 | `1789f4608e274ab9feb0e891328fe2adb6f2e0fcbe709e0731eb0fee9f151bb0` | 83,260 | latest per aggregator | **Mockup-served** `#Processor.v1_19_0.Processor` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/Processor.v1_24_0.json` | https://redfish.dmtf.org/schemas/v1/Processor.v1_24_0.json | 2026-10-25 12:15 | `2a361cc2eb8de3e0d01584d50170a0712cbe3c58332629f48f4f1356b4c46179` | 88,360 | latest per aggregator | Newest Processor — property-delta audit vs served v1_19_0: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/ProcessorMetrics.json` | https://redfish.dmtf.org/schemas/v1/ProcessorMetrics.json | 2026-10-25 12:15 | `de3a960b6621344c309f8bb4a50ccdd5bd0a4070755736262c0b602d03512b02` | 5,447 | latest per aggregator | ProcessorMetrics family aggregator — resolves `#ProcessorMetrics.ProcessorMetrics` citations — DOCS-31 |
| `redfish/schemas/v1/ProcessorMetrics.v1_6_3.json` | https://redfish.dmtf.org/schemas/v1/ProcessorMetrics.v1_6_3.json | 2026-10-25 12:15 | `55e161bcc99fba6c13b8c7533bc7cd0f6f4ae14b746be6937f527fc34b7c2a69` | 39,660 | latest per aggregator | **Mockup-served** `#ProcessorMetrics.v1_6_3.ProcessorMetrics` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/ProcessorMetrics.v1_7_1.json` | https://redfish.dmtf.org/schemas/v1/ProcessorMetrics.v1_7_1.json | 2026-10-25 12:15 | `3fa9b621af4b01d178fe11076141cbb91d68f78f918a63e0119928ce3314be76` | 40,451 | latest per aggregator | Newest ProcessorMetrics — property-delta audit vs served v1_6_3: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/SecurityPolicy.json` | https://redfish.dmtf.org/schemas/v1/SecurityPolicy.json | 2026-10-25 12:15 | `283e4a050b972a3522c9123b56f5a0c672783cadac353fc345b54e89a1dd871e` | 1,716 | latest per aggregator | SecurityPolicy family aggregator — resolves `#SecurityPolicy.SecurityPolicy` citations — DOCS-31 |
| `redfish/schemas/v1/SecurityPolicy.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/SecurityPolicy.v1_0_1.json | 2026-10-25 12:15 | `662be8280d771a52330ee883447c5a092bfe90c84e1872ee14b20059d703488a` | 31,768 | latest per aggregator | **Mockup-served** `#SecurityPolicy.v1_0_1.SecurityPolicy` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/SecurityPolicy.v1_1_0.json` | https://redfish.dmtf.org/schemas/v1/SecurityPolicy.v1_1_0.json | 2026-10-25 12:15 | `f3b3c853ca1cdba09600a53bc796139bc9991016883ddef4e74ae6d9ba36a93b` | 30,506 | latest per aggregator | Newest SecurityPolicy — property-delta audit vs served v1_0_1: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/SerialInterface.json` | https://redfish.dmtf.org/schemas/v1/SerialInterface.json | 2026-10-25 12:15 | `5231268787d832e437d993652f4cbaa3ff8a57ac0bcd38196c7c30749cca2654` | 1,805 | latest per aggregator | SerialInterface family aggregator — resolves `#SerialInterface.SerialInterface` citations — DOCS-31 |
| `redfish/schemas/v1/SerialInterface.v1_2_0.json` | https://redfish.dmtf.org/schemas/v1/SerialInterface.v1_2_0.json | 2026-10-25 12:15 | `557a20a76ac2a0d2e9baae95da2377860a6b5259b7da03198dc743242aaff33c` | 15,416 | latest per aggregator | **Mockup-served** `#SerialInterface.v1_2_0.SerialInterface` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/SerialInterface.v1_3_0.json` | https://redfish.dmtf.org/schemas/v1/SerialInterface.v1_3_0.json | 2026-10-25 12:15 | `9b59f74affd66eae5a84cef2e968c2f9978da30c707d34bb62fab9e27c951d06` | 19,994 | latest per aggregator | Newest SerialInterface — property-delta audit vs served v1_2_0: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/Signature.json` | https://redfish.dmtf.org/schemas/v1/Signature.json | 2026-10-25 12:15 | `3f448c9e2b64c6999c7ec47229e6da8b6a04f2da9caf810fe6057fc01bf6d351` | 2,305 | latest per aggregator | Signature family aggregator — resolves `#Signature.Signature` citations — DOCS-31 |
| `redfish/schemas/v1/Signature.v1_0_2.json` | https://redfish.dmtf.org/schemas/v1/Signature.v1_0_2.json | 2026-10-25 12:15 | `dcb2f64459661c3f478ea7195cb072eb3cfd9496b0fe16e3e69a5cd75329394b` | 8,245 | latest per aggregator | **Mockup-served** `#Signature.v1_0_2.Signature` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/Signature.v1_0_3.json` | https://redfish.dmtf.org/schemas/v1/Signature.v1_0_3.json | 2026-10-25 12:15 | `f16f8c1f160f041a715db71d0ff5b5028a3645ab96d0f32608793f72a861a0c7` | 8,277 | latest per aggregator | Newest Signature — property-delta audit vs served v1_0_2: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/SimpleStorage.json` | https://redfish.dmtf.org/schemas/v1/SimpleStorage.json | 2026-10-25 12:15 | `215af6e78faf1a75ae94a2f857f096042ca2e66baa0efb0b150d0cecada0e151` | 2,225 | latest per aggregator | SimpleStorage family aggregator — resolves `#SimpleStorage.SimpleStorage` citations — DOCS-31 |
| `redfish/schemas/v1/SimpleStorage.v1_3_1.json` | https://redfish.dmtf.org/schemas/v1/SimpleStorage.v1_3_1.json | 2026-10-25 12:15 | `eacb93e23f34537487a837d63d0532641d8e5364cc0ed0fa35c7668b796c08c4` | 13,395 | latest per aggregator | **Mockup-served** `#SimpleStorage.v1_3_1.SimpleStorage` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/SimpleStorage.v1_3_2.json` | https://redfish.dmtf.org/schemas/v1/SimpleStorage.v1_3_2.json | 2026-10-25 12:15 | `d6886a278349ed390c4eee2105fa684f7f3a4773c902174421ab7ee4b6523294` | 13,450 | latest per aggregator | Newest SimpleStorage — property-delta audit vs served v1_3_1: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/TrustedComponent.json` | https://redfish.dmtf.org/schemas/v1/TrustedComponent.json | 2026-10-25 12:15 | `a9a6c6a057365c3f243ac2f1b735ec1be62ccd82b7573766188861b37d0c3d9a` | 2,073 | latest per aggregator | TrustedComponent family aggregator — resolves `#TrustedComponent.TrustedComponent` citations — DOCS-31 |
| `redfish/schemas/v1/TrustedComponent.v1_3_0.json` | https://redfish.dmtf.org/schemas/v1/TrustedComponent.v1_3_0.json | 2026-10-25 12:15 | `855339d150a0275efd4346242ecaa77b8629ba5549457caf54ba30d8d5774627` | 23,175 | latest per aggregator | **Mockup-served** `#TrustedComponent.v1_3_0.TrustedComponent` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/TrustedComponent.v1_5_0.json` | https://redfish.dmtf.org/schemas/v1/TrustedComponent.v1_5_0.json | 2026-10-25 12:15 | `861e02c65ff4986f759592fbccaf76b00c858f9f06ee5e0eb02dde1d3fdea9fb` | 24,862 | latest per aggregator | Newest TrustedComponent — property-delta audit vs served v1_3_0: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/USBController.json` | https://redfish.dmtf.org/schemas/v1/USBController.json | 2026-10-25 12:15 | `17b3329b4ea48b4d5c7478e5ef562254b8d178987afdbf6b808189f3b028525c` | 1,240 | latest per aggregator | USBController family aggregator — resolves `#USBController.USBController` citations — DOCS-31 |
| `redfish/schemas/v1/USBController.v1_0_0.json` | https://redfish.dmtf.org/schemas/v1/USBController.v1_0_0.json | 2026-10-25 12:15 | `11be27490a622f4b9e80f83326adf151f9ddb5007a532e65e72bce2e48f12ef2` | 12,160 | latest per aggregator | **Mockup-served** `#USBController.v1_0_0.USBController` — the @odata.type the pinned mockup publishes (live-pinned by the EMU-2 corpus crawl 2026-10-25) — DOCS-31 |
| `redfish/schemas/v1/USBController.v1_0_1.json` | https://redfish.dmtf.org/schemas/v1/USBController.v1_0_1.json | 2026-10-25 12:15 | `a0c202083cd4d38793215816ec4fd89b5a656eac3f13488e17cc517eb2dbde58` | 11,981 | latest per aggregator | Newest USBController — property-delta audit vs served v1_0_0: additive-only, no client code change — DOCS-31 |
| `redfish/schemas/v1/AccelerationFunctionCollection.json` | https://redfish.dmtf.org/schemas/v1/AccelerationFunctionCollection.json | 2026-10-25 12:15 | `251159bc223b79b847affdcb74e1d949f59aa649282417059686006490b77597` | 5,657 | latest per aggregator | `#AccelerationFunctionCollection.AccelerationFunctionCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/ExternalAccountProviderCollection.json` | https://redfish.dmtf.org/schemas/v1/ExternalAccountProviderCollection.json | 2026-10-25 12:15 | `7cddcf637d7d19eeca447f3391793c6f68a609a4795d765937b92d6b347db9f4` | 5,211 | latest per aggregator | `#ExternalAccountProviderCollection.ExternalAccountProviderCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/GraphicsControllerCollection.json` | https://redfish.dmtf.org/schemas/v1/GraphicsControllerCollection.json | 2026-10-25 12:15 | `9f0834f578e6ced8c46c9063f477b5f6007aa6246288209836ede7407f44f05b` | 5,076 | latest per aggregator | `#GraphicsControllerCollection.GraphicsControllerCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/HostInterfaceCollection.json` | https://redfish.dmtf.org/schemas/v1/HostInterfaceCollection.json | 2026-10-25 12:15 | `afb29a43c378ba53eac08114aa092faec579af192015c81e465edbe7ab8d6266` | 5,020 | latest per aggregator | `#HostInterfaceCollection.HostInterfaceCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/MemoryCollection.json` | https://redfish.dmtf.org/schemas/v1/MemoryCollection.json | 2026-10-25 12:15 | `632fc9bf3ab88f9438c227478ad317db6299c5ee65f3423dd7cf708a21ed9a5d` | 5,323 | latest per aggregator | `#MemoryCollection.MemoryCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/MessageRegistryFileCollection.json` | https://redfish.dmtf.org/schemas/v1/MessageRegistryFileCollection.json | 2026-10-25 12:15 | `6b0bd92fda5cc11d721a3061ef6d89a6b8c081dad290c691c28f2ddc7a7c7687` | 5,049 | latest per aggregator | `#MessageRegistryFileCollection.MessageRegistryFileCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/OutboundConnectionCollection.json` | https://redfish.dmtf.org/schemas/v1/OutboundConnectionCollection.json | 2026-10-25 12:15 | `fbc2782804e269498b1ed2e764d5d71a54819bd15b48944c19de2f74be0d6394` | 5,063 | latest per aggregator | `#OutboundConnectionCollection.OutboundConnectionCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/PortCollection.json` | https://redfish.dmtf.org/schemas/v1/PortCollection.json | 2026-10-25 12:15 | `302c49b60ce237361ef8039de8015773429dbae7dfe68e9e5ec4da1f00bd3f8c` | 9,556 | latest per aggregator | `#PortCollection.PortCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/ProcessorCollection.json` | https://redfish.dmtf.org/schemas/v1/ProcessorCollection.json | 2026-10-25 12:15 | `794ee402e24e5b4db5b564998955dc53229d6edd018452beaf39cf20eea31356` | 7,203 | latest per aggregator | `#ProcessorCollection.ProcessorCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/SerialInterfaceCollection.json` | https://redfish.dmtf.org/schemas/v1/SerialInterfaceCollection.json | 2026-10-25 12:15 | `153695c0b4cad663d9b0fdd4e6bafac3532aeb1cf845e16aa4aec1e3a80d523a` | 5,040 | latest per aggregator | `#SerialInterfaceCollection.SerialInterfaceCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/SignatureCollection.json` | https://redfish.dmtf.org/schemas/v1/SignatureCollection.json | 2026-10-25 12:15 | `17e1b2e790d98d799d88a3f86fd95bd879bf59e24b8ea6b488e2d2cecbf66898` | 5,340 | latest per aggregator | `#SignatureCollection.SignatureCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/SimpleStorageCollection.json` | https://redfish.dmtf.org/schemas/v1/SimpleStorageCollection.json | 2026-10-25 12:15 | `f4bb116fce17afc6d529cdf408c672f55b42e5be535f82a1d1ae2406ae8e0f52` | 5,254 | latest per aggregator | `#SimpleStorageCollection.SimpleStorageCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/TrustedComponentCollection.json` | https://redfish.dmtf.org/schemas/v1/TrustedComponentCollection.json | 2026-10-25 12:15 | `6276c4bcaba7d372a9e0ca4a0f34490f650133f3d71b2184821e8e5256107a25` | 5,049 | latest per aggregator | `#TrustedComponentCollection.TrustedComponentCollection` — collection type the mockup publishes — DOCS-31 |
| `redfish/schemas/v1/USBControllerCollection.json` | https://redfish.dmtf.org/schemas/v1/USBControllerCollection.json | 2026-10-25 12:15 | `f616f25f6c13f9b28855abedbe42344a311aba9b8a41461fd065e419324d25c5` | 5,026 | latest per aggregator | `#USBControllerCollection.USBControllerCollection` — collection type the mockup publishes — DOCS-31 |

### Downloaded schema set (49 base aggregator files)

`ServiceRoot`, `ComputerSystem`, `Chassis`, `Sensor`, `Power`, `Thermal`,
`SessionService`, `AccountService`, `UpdateService`, `SoftwareInventory`,
`EventService`, `Manager`, `LogService`, `EthernetInterface`, `TaskService`,
`MessageRegistry`, `Battery`, `BatteryMetrics`, `EventDestination`,
`VirtualMedia`, `SecureBoot`, `SecureBootDatabase`, `Control`, `Heater`,
`HeaterMetrics`, `CertificateService`, `CertificateLocations`, `Certificate`,
`KeyService`, `KeyPolicy`, `Key`, `ComponentIntegrity`, `AccelerationFunction`,
`Assembly`, `ExternalAccountProvider`, `GraphicsController`, `HostInterface`,
`Memory`, `MessageRegistryFile`, `OutboundConnection`, `Port`, `Processor`,
`ProcessorMetrics`, `SecurityPolicy`, `SerialInterface`, `Signature`,
`SimpleStorage`, `TrustedComponent`, `USBController`. Each bare `<Name>.json` is the
DMTF "latest" aggregator that
`$ref`s the newest versioned definitions; SHA-256 hashes are listed in the
run notes in `automation-tracking.md`.

DOCS-26 (2026-10-24) closed the last **EMU-2-pinned non-client-mapped** corpus
gap: the **Control family** (the modern chassis power-limit / frequency control
surface the EMU 60→63 pins read — `#ControlCollection` → `#Control.v1_5_0`
PowerLimit + CPU1Freq, plus the second live PATCH pin on SetPoint).
Mirrored as aggregator + **mockup-served** version + **newest** version +
collection type — 4 files / 129,851 bytes total, external corpus only (Control
is NOT client-mapped, so no fixture duty; the corpus-invariant test skips it
by design). Delta audited: Control v1_5_0 → v1_8_1 adds only `SetPointError`
(readonly). REQUIREMENTS.md Control rows now cite the real mirror files.

DOCS-25 (2026-10-24) closed the last **EMU-2-pinned non-client-mapped** corpus
gap: the **SecureBoot boot-integrity family** (SecureBoot + SecureBootDatabase).
Both mirror as aggregator + **mockup-served** version + **newest** version +
collection type — 7 files / 52,544 bytes total, external corpus only (neither
family is client-mapped, so no fixture duty; the corpus-invariant test skips
them by design). Deltas audited: SecureBoot v1_1_1 → v1_2_1 adds only
`SecureBootDesiredMode`; SecureBootDatabase v1_0_2 → v1_0_3 is a property
no-op. REQUIREMENTS.md SecureBoot rows now cite the real mirror files.

DOCS-24 (2026-10-24) closed the last two **EMU-2-pinned non-client-mapped**
corpus gaps: `EventDestination` (the 4 `Subscriptions` members the event
pin reads) and `VirtualMedia` (the CD1/Floppy1 boot-media surface the Boot/
Links pin reads). Both mirror as aggregator + **mockup-served** version +
**newest** version + collection type — 8 files / 194,278 bytes total, external
corpus only (neither family is client-mapped, so no fixture duty; the
corpus-invariant test skips them by design).

DOCS-21 (2026-10-24) closed the **Battery** corpus gap the EMU-2 battery pins
(EMU 48→50) exposed: `Battery.json` + `Battery.v1_2_2.json` (the
**mockup-served** `#Battery.v1_2_2.Battery`) + newest `Battery.v1_5_0.json` +
`BatteryCollection.json` + `BatteryMetrics.json` + `BatteryMetrics.v1_0_3.json`
(the **mockup-served** `#BatteryMetrics.v1_0_3.BatteryMetrics`) + newest
`BatteryMetrics.v1_1_0.json` — 7 files / 95,718 bytes, inside DOCS-6. The five
served/aggregator files also went into `test/fixtures/redfish/schemas/`
(byte-identical, verified with `cmp`) — every `@odata.type` the pinned mockup
publishes for the battery family now has a versioned schema in the fixture.

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

DOCS-19 (2026-10-24) closed the "served-version" gap for the eight
client-mapped families that DOCS-2 had refreshed to their **newest** versioned
definitions only: the pinned `23d21f9a` mockup *serves* older `@odata.type`
versions (`Sensor.v1_8_1` — 42 of 42 sensors, `ComputerSystem.v1_22_0`,
`Chassis.v1_25_0`, `AccountService.v1_15_0`, `SoftwareInventory.v1_10_1`,
`LogService.v1_6_0`, `EthernetInterface.v1_12_0`, `MessageRegistry.v1_0_0`),
and the DOCS-11/12/13 precedent says every `@odata.type` the mockup publishes
must have a versioned schema in the fixture + mirror. Mirrored all eight
**served** versions (plus the newest `MessageRegistry.v1_9_0` to complete the
newest+served pair for the registry family — the `@odata.type` behind the
newest `Base.1.24.0` payload, DOCS-18) into
`documentations/external/redfish/schemas/v1/` **and**
`test/fixtures/redfish/schemas/` (the "every published `@odata.type` has a
versioned schema in the fixture" invariant). 9 files, 560,665 bytes total,
inside the DOCS-6 budget. Property-delta audit: every client-read field exists
in the served versions (no code change needed) — details in
`REQUIREMENTS.md` "DOCS-19".

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

## Current upstream anchors (verified 2026-10-25 20:xx UTC — DOCS run, anchor freshness re-verify + UI-2 dialog focus/order; prior: 2026-10-25 19:3x UTC — DOCS run, anchor freshness re-verify + UI-2 focus-order pin; prior: 2026-10-25 08:06 UTC — DOCS run, Test-platforms description reconciled to 75 tests; prior: 2026-10-25 04:07 UTC DOCS run query-501 gap closed, DOCS-28 02:11 UTC, DOCS-29 02:09 UTC, DOCS-27 00:15 UTC, DOCS-26 20:14 UTC, DOCS-25 18:52 UTC, DOCS-23 15:17 UTC, DOCS-22 12:47 UTC, DOCS-21 12:15 UTC, DOCS-17 01:07 UTC, DOCS-16 23:32 UTC, DOCS-15 19:20 UTC, DOCS-13 12:40 UTC, DOCS-14 16:45 UTC)

- Redfish Developer Hub — <https://redfish.dmtf.org/> (200 OK, curl + UA)
- DMTF schema index — <https://redfish.dmtf.org/schemas/v1/> (200 OK, 3.4 MB listing;
  byte-identical SHA-256 `e5a29797…` re-verified 2026-10-25 20:xx UTC)
- Redfish specification DSP0266 — <https://www.dmtf.org/sites/default/files/standards/documents/DSP0266_1.25.0.pdf>
  (1.24 MB, linked from the hub at `DSP0266_1.25.0.pdf`; probe of `DSP0266_1.26.0.pdf`
  → 404 — 1.25.0 is still the current release. The `redfish.dmtf.org/sites/...`
  path 404s; the hub links the `www.dmtf.org` URL — manifest rows already use
  the working URL; re-verified byte-identical SHA-256 `385ee6d0…` 2026-10-25
  20:xx UTC)
- Redfish Mockup Server — <https://github.com/DMTF/Redfish-Mockup-Server>
  (default branch `main` @ `23d21f9a` — unchanged, re-verified 2026-10-25
  20:xx UTC via `git ls-remote`; README saved to `redfish/mockup/`)
- OpenBMC bmcweb docs — <https://github.com/openbmc/bmcweb/tree/master/docs>
  (master advanced `fbb307a` → `63a18f4e6188a77b713a8b22c8a95ab3d6c5a718` at
  2026-10-24 12:15 UTC; Redfish.md, REDFISH_CHECKLIST.md, OEM_SCHEMAS.md,
  CLIENTS.md all byte-identical at the new HEAD — verified by SHA-256, no
  refresh needed; re-verified 2026-10-25 00:07 UTC at `63a18f4` — still HEAD,
  all four docs byte-identical; re-verified 2026-10-25 08:06 UTC — `63a18f4`
  still HEAD, all four docs byte-identical, and the file-level last-touch
  commits pinned via the GitHub path API: `Redfish.md` → `bb6b9ebc`
  (2026-09-21), the other three docs → `24e758ab` (2025-06-26 docs-folder
  creation) — manifest rows updated to record both anchors; no refresh
  needed; **re-verified 2026-10-25 20:xx UTC — `63a18f4` still HEAD via
  `git ls-remote`, no refresh needed)**

### DOCS-27 — corpus freshness audit + mockup README provenance fix (2026-10-25 00:15 UTC)

Freshness audit against the live schema index (the DOCS-22 precedent, now
covering **38 families** — the DOCS-22 list plus Battery/BatteryMetrics/Bios/
Settings/SecureBoot/SecureBootDatabase/Control/EventDestination/VirtualMedia):
extracted all 7,167 index entries and compared the newest version per family
against the mirrored "newest" files, then byte-verified **all 120 mirrored
schema files** against re-downloaded live copies. **ZERO version advances —
120/120 byte-identical**; registries (`Base.1.5.0`, `Base.1.24.0`), index page,
and the DSP0266 1.25.0 PDF all byte-identical; **no new downloads, no corpus
refresh, no client code change**. One provenance fix: the manifest row for
`redfish/mockup/README-mockup-server.md` recorded the **upstream** SHA-256
(`b3af2ff3…`, 7,318 B) but the committed blob is the DOCS-1 normalised copy
(trailing whitespace stripped on the `cert = ` / `key = ` lines, 2 bytes;
on-disk `0d79a165…`, 7,316 B) — the manifest claimed a hash the repo did not
contain. Updated the row to record the actual committed SHA with an explicit
note that the content is byte-identical to upstream apart from the 2-byte
whitespace normalisation (restoring the trailing whitespace would fail
`git diff --check`). The 33-family emulator corpus-invariant list is
untouched (no family became client-mapped).

### DOCS-28 — Heater + HeaterMetrics corpus mirror for the EMU-2 Heaters pin (2026-10-25 02:11 UTC)

The EMU-2 run (01:34 local, 64→66 tests) pinned the **ThermalSubsystem
Heaters surface** live; the published types it reads — `#Heater.v1_0_1.Heater`
(`/redfish/v1/Chassis/1U/ThermalSubsystem/Heaters/CPU1Heater`:
PhysicalContext CPU / Manufacturer Contoso Heaters / Model CPUHeater /
SerialNumber SNDHM0123456789 / HotPluggable / LocationIndicatorActive /
Status + `Links.Processors[0]` → CPU1 + `Metrics` link) and
`#HeaterMetrics.v1_0_1.HeaterMetrics` (PrePowerOnHeatingTimeSeconds 600 /
RuntimeHeatingTimeSeconds 3600 / PowerWatts.Reading 200.3 /
TemperatureReadingsCelsius[1] DeviceName 'Heater Average Temperature'
Reading 2.5 + the advertised `#HeaterMetrics.ResetMetrics` action — a
no-`/Actions/`-segment candidate) — were reachable by the corpus-invariant
crawl but had **no schema in the external corpus**. Mirrored the
**mockup-served** versions (`Heater.v1_0_1.json`, `HeaterMetrics.v1_0_1.json`)
per the DOCS-12/13/19/20/21/23/24/25/26 "newest + served" pair precedent, plus
the **newest** published versions (`Heater.v1_0_2.json`,
`HeaterMetrics.v1_0_2.json` — both the aggregators' `$ref` targets; v1_0_3
probes 404, verified 2026-10-25) plus both aggregators and the collection type
— 7 files / **60,045 bytes** total, inside the DOCS-6 budget; SHA-256s +
manifest rows above. Deltas audited against the served versions: **Heater
v1_0_1 → v1_0_2 is a property no-op** (26 diff lines — `$id`/copyright year/
backtick-quoted descriptions/`language: "en"`/title only) and **HeaterMetrics
v1_0_1 → v1_0_2 is likewise a property no-op** (26 diff lines, same classes)
— the emulator-pinned contract holds across the newest versions, **no client
code change**. Also verified the served-version `ResetMetrics` action def in
the mirror matches the EMU pin (target under `HeaterMetrics.ResetMetrics`,
no `/Actions/`-segment obligation). **Client-mapped decision:
Heater/HeaterMetrics stay NOT client-mapped** — the client reads only the
fan/thermal subsystem rollups; there is no heater UI, so the corpus-invariant
family list in the emulator test is untouched and no fixture-schema duty
attaches. If a thermal-heater feature ever lands (FUTUREWORK candidate),
Heater/HeaterMetrics join the client-mapped lists and the served versions
must also be copied into `test/fixtures/redfish/schemas/` (DOCS-19/20/21
invariant). The corpus mirror queue is now **EMPTY** — every EMU-2-pinned
family has a schema in the external corpus. Anchors re-verified same run:
bmcweb `63a18f4` (still HEAD via GitHub API, docs byte-identical), mockup
`23d21f9a`, DSP0266 1.25.0 (200 on the working `www.dmtf.org` URL), schema
index 200.

### DOCS-22 — frequent-family newest-version freshness audit (2026-10-24 12:47 UTC)

Freshness audit against the live schema index: extracted the **newest published
version per client-mapped family** from `https://redfish.dmtf.org/schemas/v1/`
and compared against the mirrored "newest" files. **8 of 33 families had
advanced upstream** since their last mirror (all others unchanged). Mirrored the
8 newest files (189,768 bytes total, inside the DOCS-6 budget; SHA-256s + rows
above): `EnvironmentMetrics.v1_7_0` (v1_3_1 → v1_7_0),
`Fan.v1_6_0` (v1_5_1 → v1_6_0), `PowerSubsystem.v1_2_0` (v1_1_1 → v1_2_0),
`PowerSupply.v1_8_0` (v1_5_3 → v1_8_0), `PowerSupplyMetrics.v1_3_0`
(v1_1_1 → v1_3_0), `TaskService.v1_3_0` (v1_2_1 → v1_3_0),
`ThermalMetrics.v1_3_3` (v1_3_1 → v1_3_3), `ThermalSubsystem.v1_5_0`
(v1_3_1 → v1_5_0). Property-delta audit: **every delta is additive-only** (new
properties/actions, no removals): EnvironmentMetrics adds
AmbientTemperatureCelsius/BarometricPressureMm/CurrentAmps/
DewPointProximityCelsius/Voltage; Fan adds RatedSpeedRPM/RatedSecondarySpeedRPM;
PowerSubsystem adds Applied/Enabled/Links/LoadPercentThreshold/
MaxRampRateWattsPerSecond/PowerBrake(+sensors)/TemperatureThreshold;
PowerSupply adds Certificates/VoltageControl; PowerSupplyMetrics adds
ChargePercent/multi-phase Line*/PolyPhase*/PowerLoadPercent; TaskService adds a
`#TaskService.DeleteAllCompletedTasks` action + `TaskMonitorAutoExpirySeconds`;
ThermalMetrics v1_3_3 is a **structural no-op** (copyright + anyOf-normalization
only); ThermalSubsystem adds FansFullSpeedOverrideEnable/Filters. None of the
new fields affect the client's current reader surface — **no client code
change** (newest versions are only mirrored to the external corpus, not the
fixture; the fixture keeps the mockup-served versions per the DOCS-21
precedent). Manifest rows + anchors updated above; the 33-family list in the
emulator corpus-invariant test stays in sync (served versions unchanged).

### DOCS-23 — Bios + Settings corpus mirror for the EMU Bios-Settings pin (2026-10-24 15:17 UTC)

The EMU-2 run (16:30 local, 53 tests) pinned the **Bios `@Redfish.Settings`
surface** live; the two published types it reads — `#Bios.v1_2_2.Bios`
(`/Systems/437XR1138R2/Bios`) and `#Settings.v1_3_5.Settings` (the
`@Redfish.Settings` annotation type) — were reachable by the corpus-invariant
crawl but had **no versioned schema in the external corpus**. Mirrored the
**mockup-served** versions (`Bios.v1_2_2.json`, `Settings.v1_3_5.json`) per the
DOCS-11/12/13/19/20/21 "newest + served" pair precedent, plus the **newest**
published versions (`Bios.v1_3_0.json`, `Settings.v1_5_0.json`) found on the
live schema index — 4 files / **67,020 bytes** total (16,485 + 20,646 + 15,194
+ 15,695), inside the DOCS-6 budget; SHA-256s + manifest rows above. Deltas
audited against the served versions: **Bios v1_2_2 → v1_3_0 adds only the
`Passwords` property** (13 → 14 props; the newer password-management surface
that supersedes the action-based ChangePassword flow — a #015/#026 input, not a
code change); **Settings v1_3_5 → v1_5_0 is a property no-op** (6 → 6).
**Client-mapped decision: Bios/Settings stay NOT client-mapped** — the client
reads only `ComputerSystem.BiosVersion` (the overview firmware line); there is
no BIOS-config editor in the app, so the corpus-invariant family list in the
emulator test is untouched and no fixture-schema duty attaches. If a BIOS-config
feature ever lands (FUTUREWORK candidate), Bios/Settings join the client-mapped
lists and the served versions must also be copied into
`test/fixtures/redfish/schemas/` (DOCS-19/20/21 invariant). Anchors re-verified
same run: bmcweb `63a18f4` (still HEAD, docs byte-identical), mockup
`23d21f9a`, DSP0266 1.25.0, schema index 200.

### DOCS-25 — SecureBoot + SecureBootDatabase corpus mirror for the EMU-2 SecureBoot/pin (2026-10-24 18:52 UTC)

The EMU-2 run (20:12 local, 57→60 tests) pinned the **SecureBoot boot-integrity
surface** live; the published types it reads — `#SecureBoot.v1_1_1.SecureBoot`
(`/Systems/437XR1138R2/SecureBoot`: SecureBootEnable false /
SecureBootCurrentBoot Disabled / SecureBootMode UserMode +
`#SecureBoot.ResetKeys` `ResetKeysType@Redfish.AllowableValues`) and the
`#SecureBootDatabase.v1_0_2.SecureBootDatabase` per-database surface (the
8-member `#SecureBootDatabaseCollection` PK/KEK/db/dbx + defaults, each with a
*smaller* per-resource ResetKeys allow-list) — were reachable by the
corpus-invariant crawl but had **no schema in the external corpus**. Mirrored
the **mockup-served** versions (`SecureBoot.v1_1_1.json`,
`SecureBootDatabase.v1_0_2.json`) per the DOCS-12/13/19/20/21/23/24 "newest +
served" pair precedent, plus the **newest** published versions
(`SecureBoot.v1_2_1.json` — the aggregator's `$ref` target; `v1_1_1` is absent
from the newest aggregator list, which refs v1_0_9/v1_1_2/v1_2_1 —
`SecureBootDatabase.v1_0_3.json`) plus both aggregators and the collection
type — 7 files / **52,544 bytes** total, inside the DOCS-6 budget; SHA-256s +
manifest rows above. Deltas audited against the served versions: **SecureBoot
v1_1_1 → v1_2_1 adds only the `SecureBootDesiredMode` property** (13 → 14
props; the requested-mode surface mirrored from SecureBootMode — no code
change); **SecureBootDatabase v1_0_2 → v1_0_3 is a property no-op** (11 → 11
props; copyright/description-level only). Also verified the served-version
ResetKeysType enums in the mirror match the EMU pin exact values
(`ResetAllKeysToDefault`/`DeleteAllKeys`/`DeletePK` on SecureBoot;
`ResetAllKeysToDefault`/`DeleteAllKeys` — no DeletePK — on the PK database
resource) — the per-resource allow-list nuance is a schema fact, not a mockup
quirk. **Client-mapped decision: SecureBoot/SecureBootDatabase stay NOT
client-mapped** — the client reads only the system overview; there is no
secure-boot UI, so the corpus-invariant family list in the emulator test is
untouched and no fixture-schema duty attaches. If a security-posture feature
ever lands (FUTUREWORK candidate), SecureBoot/SecureBootDatabase join the
client-mapped lists and the served versions must also be copied into
`test/fixtures/redfish/schemas/` (DOCS-19/20/21 invariant). REQUIREMENTS.md
SecureBoot rows now cite these real mirror files. Anchors re-verified same run:
bmcweb `63a18f4` (still HEAD via GitHub API, docs byte-identical), mockup
`23d21f9a`, DSP0266 1.25.0 (200 on the working `www.dmtf.org` URL — 1.24 MB),
schema index 200.

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
