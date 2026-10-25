# Redfish Requirement Traceability

Maps audited Redfish / OpenBMC requirements to the client implementation and its
tests. Source citations point at the mirrored corpus in
`documentations/external/redfish/` (see `README.md` manifest for hashes) or the
live DMTF URLs. Status legend: `OK` (implemented + tested), `GAP` (known gap,
tracked in `FUTUREWORK.md`), `N/A` (not applicable to this client).

Last audited: 2026-10-25 (DOCS run — **anchor freshness re-verification, no
corpus refresh**): re-verified every upstream anchor this run — (1) **bmcweb
`63a18f4`** still HEAD of `master` via `git ls-remote`; (2) **mockup
`23d21f9a`** still HEAD of `main` via `git ls-remote`; (3) **DSP0266 1.25.0**
from `www.dmtf.org` **byte-identical** SHA-256 `385ee6d0…` vs the mirrored
`redfish/spec/DSP0266_1.25.0.pdf`; (4) **schema index** from
`redfish.dmtf.org/schemas/v1/` **byte-identical** SHA-256
`e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86`
(3,448,133 B) vs the mirrored `v1-index.html` → **no corpus refresh needed**
(DOCS-27 ZERO version advances hold; the corpus mirror queue stays EMPTY for
every published type; 0 bytes downloaded). No code gap surfaced by the audit
this run. **UI-2 focus-order pin:** `SystemProfileForm` gained
`autofocusFirstField` — the Add-system dialog autofocuses its first field so
keyboard/screen-reader users land inside the form the moment it opens
(WAI-ARIA dialog pattern: focus moves into the dialog; the edit page leaves
the flag off so it does not scroll on load), and two widget tests pin the
dialog focus entry + the full keyboard Tab order (Name → Host → Port → TLS →
auth dropdown → Username → Password → Remember → self-signed → Add system).

Prior: 2026-10-25 (EMULATOR run — **Control SetPoint pre-validation
rule implemented; Control family became client-mapped**): the #022/#016
client-side rule the pinned Control surface demands is now code —
`ControlResource` (`lib/redfish/models/control.dart`) parses
`#Control.v1_5_0.Control` (Id / ControlType / ControlMode / SetPoint /
SetPointUnits / AllowableMin / AllowableMax / Sensor.DataSourceUri) and
`ControlResource.validateSetPoint` rejects out-of-bounds SetPoints BEFORE any
PATCH is sent (the emulator proves the mockup applies `SetPoint: 9999`
unvalidated — EMU 60→63 pin; `AllowableMax`/`AllowableMin` schema wording:
"Services shall not accept values for SetPoint ... above/below this value");
per-resource bounds never leak across controls (the SecureBoot per-resource
allow-list precedent, #022). Because the client now maps Control, the family
entered the client-mapped set: the served `Control.v1_5_0.json` was copied
into `test/fixtures/redfish/schemas/` (byte-identical to the DOCS-26 mirror,
SHA-256 `de1614b0…`) and added to the emulator corpus-invariant family list
(the DOCS-19/20/21 fixture invariant). +11 unit tests
(`test/redfish/models/control_test.dart`), +1 live emulator test pinning the
rule against the served PowerLimit/CPU1Freq allowable ranges (79 → **80/80**
green on pinned `23d21f9a`). Corpus anchor notes from the 16:50 DOCS run
still hold (bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index
byte-identical — no refresh, mirror queue EMPTY).

Prior: 2026-10-25 (DOCS run — **anchor freshness re-verification + small safe #016 If-Match code gap closed**): re-verified every upstream anchor this run. (1) **bmcweb `63a18f4`** — still HEAD of `master` via `git ls-remote`;
(2) **mockup `23d21f9a`** — still HEAD of `main` via `git ls-remote`;
(3) **DSP0266 1.25.0** — 200 on the working `www.dmtf.org` URL and
**byte-identical** SHA-256 `385ee6d0…` vs the mirrored
`redfish/spec/DSP0266_1.25.0.pdf`; (4) **schema index** — 200 and
**byte-identical** SHA-256 `e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48
f8dc9c0b86` (3,448,133 B) vs the mirrored `v1-index.html` → **no corpus
refresh needed** (DOCS-27 ZERO version advances hold; the corpus mirror queue
stays EMPTY for every published type). **Code gap closed (#016):** the
If-Match/`@odata.etag` wiring the §6.5 row below flagged as Partial is now
landed — `patchJson(..., etag:)` sends a properly-quoted `If-Match`
(RFC7232 entity-tag grammar; unquoted payload-form tokens quoted, `W/"..."`
weak tags preserved), `ODataResource.etag` reads `@odata.etag`, and
`RedfishException.isPreconditionFailed` classifies 412 (non-retryable, so a
stale-token caller re-fetches instead of blind-retrying) — 6 new unit tests
(+1 OData accessor, +5 client/exception). What stays #016: the Boot/
IndicatorLED PATCH *actions in a service + UI* (the transport + precondition
wiring a future flow needs are in place; the settings-object ETag
`9234ac83b9700123cc32` is the only pinable token on the DMTF fixture, and the
mockup IGNORES If-Match — enforcement stays unit-level).
Prior: 2026-10-25 (DOCS run — **anchor freshness re-verification, no
corpus refresh needed**): re-verified every upstream anchor this run.
(1) **bmcweb `63a18f4`** — still HEAD of the `master` branch, verified via
`git ls-remote https://github.com/openbmc/bmcweb.git refs/heads/master`
(bmcweb's default branch is `master`, not `main` — the GitHub REST
`commits/main` endpoint returns 422; the DOCS-27/29 "still HEAD via GitHub
API" notes were checked against the correct branch, this run records it
explicitly); (2) **mockup `23d21f9a`** — still HEAD of `main` via GitHub API;
(3) **DSP0266 1.25.0** — 200 on the working `www.dmtf.org` URL,
**byte-identical** SHA-256 `385ee6d0…`; (4) **schema index** — 200 and
**byte-identical** to the mirrored `v1-index.html` (SHA-256
`e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86`,
3,448,133 bytes) → **no corpus refresh needed** (DOCS-27's ZERO version
advances still hold). **DOCS-31 newest-version spot audit**: all 17
DOCS-31-mirrored families' newest versions re-extracted from the live index
with numeric version comparison and compared to the corpus files — **ALL
MATCH** (AccelerationFunction v1_0_5, Assembly v1_6_1, ExternalAccountProvider
v1_9_0, GraphicsController v1_0_2, HostInterface v1_4_0, Memory v1_24_0,
MessageRegistryFile v1_1_5, OutboundConnection v1_0_3, Port v1_20_0,
Processor v1_24_0, ProcessorMetrics v1_7_1, SecurityPolicy v1_1_0,
SerialInterface v1_3_0, Signature v1_0_3, SimpleStorage v1_3_2,
TrustedComponent v1_5_0, USBController v1_0_1) — the corpus mirror queue
stays **EMPTY for every published type**. No new downloads, no code change.
(The DOCS-31 corpus mirror + extended invariant were recovered this run from
a crashed-run working tree and re-verified: analyze 0, 364 unit tests pass
(1 skipped),
and the extended corpus-invariant crawl passes **78/78 live** against the
pinned mockup — commit `a458ded`.)
Prior: 2026-10-25 (EMULATOR run — **corpus-invariant crawl extended to
ALL published @odata.types + the 17-family corpus gap closed, DOCS-31**): the
live published-types crawl now asserts **every** versioned `@odata.type` the
pinned mockup publishes has a served-version schema in the external corpus
mirror — not only the client-mapped families (the DOCS-19/20/21 fixture
invariant stays). The extension immediately exposed a **real gap**: 17
families the mockup publishes had **no schema at all** in
`documentations/external/redfish/schemas/v1/` (AccelerationFunction, Assembly,
ExternalAccountProvider, GraphicsController, HostInterface, Memory,
MessageRegistryFile, OutboundConnection, Port, Processor, ProcessorMetrics,
SecurityPolicy, SerialInterface, Signature, SimpleStorage, TrustedComponent,
USBController) — DOCS-30's "corpus mirror queue EMPTY" was only true for the
client-mapped + EMU-2-pinned families. Closed with DOCS-31: 65 files
(1,403,838 bytes total, inside DOCS-6) = 17 aggregators + 17 mockup-served +
17 newest + 14 collection types; property-delta audit **additive-only** across
all 17 (Memory +4 / Port +13 / Processor +4 / ProcessorMetrics +1 /
SecurityPolicy +1 / SerialInterface +1 / TrustedComponent +1, eight no-ops) —
**no client code change**, all 17 stay NOT client-mapped (no fixture duty);
anchors re-verified (bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0,
schema index 200); the corpus mirror queue is now **EMPTY for every published
type** and the invariant is runnable.
Prior: 2026-10-25 (DOCS run — **corpus mirror of the EMU 71→75
re-verified every upstream anchor — bmcweb `63a18f4` (still HEAD via GitHub
API), mockup `23d21f9a` (still HEAD of `main` via GitHub API), DSP0266 1.25.0
(200 on the working `www.dmtf.org` URL, byte-identical SHA-256 `385ee6d0…`),
schema index 200 and **byte-identical** to the mirrored `v1-index.html`
(SHA-256 `e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86`,
3,448,133 bytes) → **no corpus refresh needed** (DOCS-27's ZERO version
advances still hold). Housekeeping: the "Test platforms" emulator-suite note
counted 75 tests but described pins only through EMU 59→60; it now also
describes the EMU 60→75 pins — chassis Controls + the second live PATCH pin
(SetPoint), Bios/Settings PATCH round-trip + the settings-object ETag,
ThermalSubsystem Heaters + Manager.Reset round-trip, the generalized
`$expand` pins on Chassis/Managers + the `$levels=2` depth cap, the two
negative facts (bad login mints a session; `MultipartHttpPushUri` absent),
the ActionInfo *resource* contract (CertificateService actions), and the
last three service-root branches (CertificateLocations / KeyService /
ComponentIntegrity incl. the NVMeoFSecrets collection-metadata-only boundary)
— the count is now backed by descriptions of every pin.
Prior: 2026-10-25 (EMULATOR run — **last un-pinned service-root branches
pinned live**): the read surfaces of the final three service-root branches the
corpus crawl visits are now pinned in the emulator suite —
(1) `CertificateService.CertificateLocations`
(`#CertificateLocations.v1_0_3`) links the three certificate stores the
fixture serves (HTTPS server cert / UpdateService client cert / VirtualMedia
cert); (2) `KeyService` (`#KeyService.v1_0_0`) — `NVMeoFKeyPolicies`
(`#KeyPolicy.v1_0_0` NVMeoF allow-lists: SecurityTransportAllowList/
CipherSuiteAllowList/SecurityProtocolAllowList/DHGroupAllowList/
SecureHashAllowList) and `NVMeoFSecrets` (`#KeyCollection.KeyCollection`,
2 members) pinned **collection-metadata only** — the members carry real key
material (`KeyString`), so the suite asserts the surface exists without ever
fetching a member body (the #015/#026 never-read-secrets-back rule);
(3) `ComponentIntegrity` collection (4 members) + `#ComponentIntegrity.
v1_2_2` SPDM/TPM/USB member shapes incl. the **disabled** USB member
(enabled-state read per member, never assumed). All three families remain
**NOT client-mapped** → no fixture schema duty (corpus-invariant unchanged);
EMU 71→75. No corpus refresh (DOCS-27 ZERO advances still hold).
Prior: 2026-10-25 (DOCS run — **anchor re-verification + bmcweb
file-level provenance pinned**): re-verified every upstream anchor — bmcweb
`63a18f4` (still HEAD via GitHub API; `Redfish.md`, `REDFISH_CHECKLIST.md`,
`OEM_SCHEMAS.md`, `CLIENTS.md` all **byte-identical** to the mirror at current
master), mockup `23d21f9a` (still HEAD), DSP0266 1.25.0 (200 on the working
`www.dmtf.org` URL, byte-identical SHA-256 `385ee6d0…`; `DSP0266_1.26.0.pdf`
probe 404s → 1.25.0 still current), schema index 200 and **byte-identical**
to the mirrored `v1-index.html` (SHA-256
`e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86`,
3,448,133 bytes) → **no corpus refresh needed this run** (DOCS-27's ZERO
version advances still hold). Provenance upgrade: the manifest rows for the
four bmcweb docs now record the **file-level last-touch commits** (GitHub path
API) alongside the repo HEAD — `Redfish.md` → `bb6b9ebc` (2026-09-21), the
other three docs → `24e758ab` (2025-06-26 docs-folder creation) — the
DOCS-27 precedent of making every recorded anchor truthful.
Prior: 2026-10-25 (DOCS run — **query-501 gap closed + anchor
re-verification**): closed the row-923 "no query-specific 400/501 unit
fixture yet" gap — the §7.3.1 query-error surface is now pinned with two
`RedfishException` normalization fixtures (`Base.1.0.QueryNotSupported` 501 +
`Base.1.0.QueryNotSupportedOnResource` 400, both carrying the mirrored
registry message texts), and **501 (Not Implemented) is now classified
NON-retryable** in `RedfishException.fromResponse` — a permanent "service does
not implement this query parameter" signal (DSP0266 §7.3.1), so the #018
discovery pass must gate the query instead of re-issuing it (transient 5xx /
429 stay retryable). Re-verified all upstream anchors this run: bmcweb
`63a18f4` (still HEAD via GitHub API), mockup `23d21f9a` (still HEAD via
GitHub API), DSP0266 1.25.0 (200 on the working `www.dmtf.org` URL,
byte-identical SHA-256 `385ee6d0…` vs the mirror), schema index 200 and
**byte-identical** to the mirrored `v1-index.html` (SHA-256
`e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86`,
3,448,133 bytes) → **no corpus refresh needed this run** (DOCS-27's ZERO
version advances still hold).
Prior: 2026-10-25 (DOCS run — **`$levels=2` depth-bound audit row**):
extended the DOCS-15 §7.3.2 query-parameter table with the new EMU pins
(2026-10-25, EMU 66→68): the `$expand=.($levels=1)` shape is now pinned on
**all three** top-level collections the #018 discovery pass walks (Systems +
Chassis + Managers inline full member bodies via the map-form
`getJson(path, query:)`, incl. the manager-level reset allow-list
`[ForceRestart, GracefulRestart]` visible through the expanded Manager
payload — the #022/#016 conflation guard on the inlined shape), and the
**depth bound is pinned**: `$levels=2` does NOT recurse — nested `Links`
stay bare `@odata.id` refs, so the pass must follow cross-resource URIs
explicitly for deeper hops (DSP0266 §7.3.2 depth-cap). Also re-verified all
upstream anchors this run: bmcweb `63a18f4` (still HEAD via GitHub API),
mockup `23d21f9a` (still HEAD via GitHub API), DSP0266 1.25.0 (200 on the
working `www.dmtf.org` URL), schema index 200 — and **the live schema index
is byte-identical** to the mirrored `v1-index.html`
(SHA-256 `e5a2979727a7fc030fce29b8d7d2be2301f4507df03ed76e2aef48f8dc9c0b86`,
3,448,133 bytes) → **no corpus refresh needed this run** (DOCS-27's ZERO
version advances still hold).
Prior: 2026-10-25 (DOCS-28 run — **Heater + HeaterMetrics corpus
mirror**): mirrored the 7-file Heater family pair the EMU-2 Heaters pin
(64→66 tests) reads — `Heater.json` + `HeaterMetrics.json` (aggregators,
`$ref` v1_0_2 newest) + served `Heater.v1_0_1` / `HeaterMetrics.v1_0_1`
(what the pinned mockup publishes) + newest `Heater.v1_0_2` /
`HeaterMetrics.v1_0_2` (v1_0_3 probes 404 — v1_0_2 is current) +
`HeaterCollection.json` — 60,045 bytes total, inside the DOCS-6 budget;
SHA-256s + manifest rows verified (see README.md). Delta audit: **v1_0_1 →
v1_0_2 is a property no-op for both families** (26 diff lines each — `$id`/
copyright/backtick-quoted descriptions/`language`/title), so the
emulator-pinned contract holds — **no client code change**; both families
stay NOT client-mapped (no fixture duty, corpus-invariant list untouched).
The corpus mirror queue is now **EMPTY** — every EMU-2-pinned family has a
schema in the external corpus. Re-verified all anchors same run: bmcweb
`63a18f4` (still HEAD via GitHub API, docs byte-identical), mockup
`23d21f9a`, DSP0266 1.25.0 (200 on the working `www.dmtf.org` URL), schema
index 200.
Prior: 2026-10-25 (DOCS-27 run — **corpus freshness audit + provenance
fix**): re-verified every upstream anchor — bmcweb master `63a18f4` (still
HEAD via GitHub API; all four mirrored docs byte-identical at HEAD), mockup
pin `23d21f9a` (still HEAD of `main`), DSP0266 1.25.0 (200 on the working
`www.dmtf.org` URL), schema index 200 (3.44 MB). **Freshness audit (the
DOCS-22 precedent) across all 38 mirrored families: ZERO version advances** —
every mirrored "newest" file is still the live index's newest (extracted all
7,167 index entries and compared the newest version per family; also
byte-verified all 120 mirrored schema files against re-downloaded live
copies: 120/120 byte-identical). Registries byte-identical (`Base.1.5.0` +
`Base.1.24.0`); index page byte-identical; DSP0266 PDF byte-identical. **One
provenance fix**: the manifest row for the mirrored
`mockup/README-mockup-server.md` recorded the upstream SHA-256
(`b3af2ff3…`, 7,318 B), but the committed blob is the DOCS-1 normalised copy
(trailing whitespace stripped on the `cert = `/`key = ` lines — 2 bytes), so
the manifest claimed a hash the repo did not contain. The manifest now
records the actual committed SHA-256 (`0d79a165…`, 7,316 B) with an explicit
note that the content is byte-identical to upstream apart from that 2-byte
whitespace normalisation (the DOCS-1 commit wrote it that way; restoring
upstream's trailing whitespace would fail `git diff --check`). **No client
code change** from the audit; UI-2 increment (merged Identity key/value
semantics) landed separately.
Prior: 2026-10-24 (EMULATOR run — **chassis Controls surface pinned,
EMU 60→63**): the mockup's `/Chassis/1U/Controls` publishes the modern control
surface (`#ControlCollection.ControlCollection` → `#Control.v1_5_0.Control`):
PowerLimit (ControlType Power, ControlMode Automatic, SetPoint 500 W,
AllowableMax 1000 / AllowableMin 150 — the exact limits a #022 power-capping
flow pre-validates against — plus a `Sensor` excerpt carrying Reading 374 +
`DataSourceUri` → `/Chassis/1U/Sensors/TotalPower`, the same wiring the
EnvironmentMetrics pin documents) and CPU1Freq (ControlType Frequency,
SettingMin/Max 2000/2400 Hz, AllowableMax/Min 1500/3700); the **second live
PATCH pin**: PATCHing `SetPoint: 600` returns 204 AND persists (in-memory only;
on-disk fixture untouched) — the DSP0266 §6.5.2 partial-update shape a
power-capping flow sends — while a bogus `SetPoint: 9999` is ALSO applied
unvalidated (same "advertised contract, not enforced" rule as ResetType/
PATCH-body, #016); the #006/#019/#022 client must pre-validate SetPoints
against AllowableMin/Max. Control is NOT client-mapped — no fixture-schema
duty. **Corpus mirror done (DOCS-26)**: every Control citation in this file
now resolves to a real mirrored file — served `Control.v1_5_0.json` + newest
`Control.v1_8_1.json` (adds only `SetPointError`, additive) + aggregator +
`ControlCollection.json` (4 files / 129,853 bytes, external corpus only —
Control stays NOT client-mapped). **Updated 2026-10-25 (EMULATOR run):**
Control IS now client-mapped — the 16:50→17:50 run implemented
`ControlResource.validateSetPoint` (#022/#016 pre-validation), copied the
served `Control.v1_5_0.json` into `test/fixtures/redfish/schemas/`, added
`Control` to the emulator corpus-invariant family list, and pinned the rule
live (80/80).
Prior: 2026-10-24 (DOCS-25 run — **SecureBoot/SecureBootDatabase corpus
mirror for the EMU-pinned boot-integrity surface, EMU 57→60**): the mockup's
`/Systems/437XR1138R2/SecureBoot` publishes the secure-boot read surface
(`#SecureBoot.v1_1_1.SecureBoot`: SecureBootEnable false /
SecureBootCurrentBoot Disabled / SecureBootMode UserMode) with the
`#SecureBoot.ResetKeys` action + `ResetKeysType@Redfish.AllowableValues`
(ResetAllKeysToDefault/DeleteAllKeys/DeletePK — the same annotation-form
allow-list rule as Reset, #022/#016) and the SecureBootDatabases link; the
`SecureBootDatabaseCollection` enumerates 8 databases (PK/KEK/db/dbx +
defaults) and each database resource carries its OWN
`#SecureBootDatabase.ResetKeys` with a *smaller* per-resource allow-list
(PK omits DeletePK — the per-resource annotation rule, #022); both SecureBoot
action targets POST → 204 and the mockup does NOT validate action bodies
(bogus ResetKeysType also 204s — the 400 path stays unit-level), so the client
must pre-validate against the annotation, never hardcode reset types.
**Corpus mirror done (DOCS-25)**: every citation in this file's SecureBoot
rows now resolves to a real mirrored file — served `SecureBoot.v1_1_1.json`
+ newest `SecureBoot.v1_2_1.json` (adds only `SecureBootDesiredMode`,
additive), served `SecureBootDatabase.v1_0_2.json` + newest
`SecureBootDatabase.v1_0_3.json` (property no-op), aggregators +
`SecureBootDatabaseCollection.json` (7 files / 52,544 bytes, external corpus
only — the families stay NOT client-mapped, no fixture duty). If-Match (#016)
boundary (pinned EMU 59→60): a PATCH sent with a stale
`If-Match: "bogus-stale-etag"` header still answers 204 AND persists — the
mockup ignores preconditions, so 412 enforcement stays unit-level and the
#016 client must send the settings-object ETag itself
(`9234ac83b9700123cc32`, EMU 53) rather than rely on the service.
Prior: 2026-10-24 EMULATOR run — **ComputerSystem Boot override +
live PATCH round-trip + discovery Links graph + VirtualMedia pinned, EMU
53→57**): the mockup's `/Systems/437XR1138R2/Boot` publishes the full boot-
override surface (BootSourceOverrideEnabled/Mode/Target +
`BootSourceOverrideTarget@Redfish.AllowableValues` — 10 values incl.
None/Pxe/Cd/Usb/Hdd/BiosSetup/Utilities/Diags/SDCard/UefiTarget +
UefiTargetBootSourceOverride); the **first live PATCH pin**: PATCHing
`Boot.BootSourceOverrideEnabled` returns 204 AND persists into the served
resource (in-memory only; the on-disk fixture is untouched), while an invalid
body (`IndicatorLED: "Bogus"`) is ALSO applied unvalidated — the same
"advertised contract, not enforced" rule as ResetType; `RedfishClient` gained
`patchJson` (the DSP0266 §6.5.2 transport for #016), which the live pin +
3 unit tests cover. Discovery-graph pin: Systems→Chassis→Manager `Links`
traversal resolves all three hops (System.Links.Chassis/ManagedBy,
Chassis.Links.ComputerSystems/ManagedBy/ManagersInChassis,
Manager.Links.ManagerForServers/ManagerForChassis/ManagerInChassis +
ManagerType/FirmwareVersion/Model). VirtualMedia read surface
(`#VirtualMedia.v1_6_3`, CD1 Applet//CD,DVD, Floppy1 URI/Floppy,USBStick) —
a boot-media UX input; this fixture publishes NO InsertMedia/EjectMedia
action targets. No corpus download this run (EMU stream).)
Prior: DOCS run — **Bios + Settings corpus mirror,
DOCS-23**: mirrored the mockup-served `Bios.v1_2_2.json` +
`Settings.v1_3_5.json` (the two published types the EMU Bios-`@Redfish.Settings`
pin reads) plus the newest `Bios.v1_3_0.json` + `Settings.v1_5_0.json` into the
external corpus; delta audit additive-only — Bios v1_3_0 adds `Passwords`,
Settings v1_5_0 is a property no-op; **client-mapped decision: Bios/Settings
stay NOT client-mapped** (client reads only `ComputerSystem.BiosVersion`; no
BIOS-config editor) so no fixture-schema duty). UI-2: Power/Sensors/KVM
not-found fallbacks now announce one merged `System not found` semantics node
(the SystemShell/SystemOverviewPage pattern), +3 widget tests. Prior runs
below.)
Prior: EMULATOR run — **Bios `@Redfish.Settings` surface pinned live, EMU 52→53**:
the DMTF mockup's `/Bios` resource carries the
DSP0266 §9.9 `@Redfish.Settings` payload annotation with a real settings-object
**ETag** — the only ETag-ish token this fixture serves (no resource-level
`@odata.etag`/HTTP ETag header), refining the older note "etag behaviour cannot
be pinned on this fixture": header-level ETags are absent but the
settings-object ETag IS pinable — the optimistic-concurrency token a #016
PATCH/If-Match flow must send; pending-settings resource compare (EmbeddedSata
Raid→Ahci, ProcTurboMode Enabled→Disabled), failed-apply Messages +
RelatedProperties, `#Bios.ResetBios` POST 204, `#Bios.ChangePassword`
advertised-only). UI-2: SystemShell not-found fallback now announces one merged
semantics node. Prior runs below.)
Prior: DOCS-21 run — mirrored the versioned schemas for the battery family
the EMU run (48→50) pinned live —
`Battery.v1_2_2.json` (mockup-served `#Battery.v1_2_2.Battery`: Module1 detail
Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+
ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent + the
`#Battery.SelfTest`/`#Battery.Calibrate`/`#Battery.Reset` action defs),
`BatteryMetrics.v1_0_3.json` (mockup-served `#BatteryMetrics.v1_0_3.
BatteryMetrics`: InputVoltage/OutputVoltages/InputCurrentAmps/
OutputCurrentAmps/StoredEnergyWattHours/TemperatureCelsius/ChargePercent/
CellVoltages — every excerpt a `Sensor` `Sensor*Excerpt` ref with
`DataSourceUri`), `Battery.json`/`BatteryMetrics.json` aggregators, and
`BatteryCollection.json` — into `documentations/external/redfish/schemas/v1/`
AND `test/fixtures/redfish/schemas/` (the "every published `@odata.type` for a
client-relevant family has a versioned schema in the fixture" invariant,
DOCS-19/20), plus the **newest** `Battery.v1_5_0.json` +
`BatteryMetrics.v1_1_0.json` for the delta note (7 files / 95,718 bytes, inside
DOCS-6); every emulator-pinned field verified present in the served defs
(34 props / 23 props; `SensorExcerpt` refs resolve to the already-mirrored
`Sensor.v1_8_1.json`) — **no code change needed**; the battery family stays
future #007/#019 telemetry work (no client model yet).)
Prior: EMU run 48→50 — pinned the **Battery surface** of the power subsystem
(`#Battery.v1_2_2` Module1 detail + `#BatteryMetrics.v1_0_3` electrical
telemetry with `DataSourceUri` links into the Sensors collection + the
`#Battery.SelfTest`/`#Battery.Calibrate` action targets) and the **action
round-trip contract**: `#Battery.SelfTest`/`#Battery.Calibrate` POST → 204
while the advertised `#PowerSupply.Reset` target POST → 404 (its URI has no
`/Actions/` segment the mockup serves — a documented negative for #022/#006;
the DOCS-21 corpus gap it exposed is now closed by this run).
Prior: DOCS-20 run — closed the **chassis-metrics /
subsystem** corpus gap the EMU-2 chassis-contracts pins (2026-10-24, EMU 45→48)
exposed: mirrored the versioned schemas for the newly pinned families into
`documentations/external/redfish/schemas/v1/` AND
`test/fixtures/redfish/schemas/` — `EnvironmentMetrics.v1_3_1`,
`ThermalSubsystem.v1_3_1`, `ThermalMetrics.v1_3_1`, `PowerSubsystem.v1_1_1`,
`PowerSupply.v1_5_3`, `PowerSupplyMetrics.v1_1_1`, `Fan.v1_5_1` (the
mockup-served Fan member type), `FanCollection`, `PowerSupplyCollection`, plus
the `Redundancy.json` → `Redundancy.v1_7_1` chain the FanRedundancy groups cite
(the "every published `@odata.type` for a client-relevant family has a versioned
schema in the fixture" invariant; 11 files / 160,101 bytes, inside DOCS-6).
Every emulator-pinned field verified present in the mirrored defs:
EnvironmentMetrics Temp/Power/Fan excerpts (`SensorExcerpt` refs →
`Sensor.v1_8_1`), ThermalSubsystem Fans + FanRedundancy (`RedundantGroup`
MinNeededInGroup/MaxSupportedInGroup via Redundancy.v1_7_1), ThermalMetrics
Intake/Exhaust/Internal/Ambient, PowerSupply Model/Manufacturer/
FirmwareVersion/LineInputStatus + `#PowerSupply.Reset` — no code change needed).
Prior: DOCS-19 run — closed the "served-version" corpus gap
for the eight client-mapped families DOCS-2 had refreshed to **newest** only:
mirrored the **mockup-served** `@odata.type` versions the pinned `23d21f9a`
fixture publishes — `Sensor.v1_8_1` (42/42 sensors),
`ComputerSystem.v1_22_0`, `Chassis.v1_25_0`, `AccountService.v1_15_0`,
`SoftwareInventory.v1_10_1`, `LogService.v1_6_0`,
`EthernetInterface.v1_12_0`, `MessageRegistry.v1_0_0` — plus the newest
`MessageRegistry.v1_9_0` (the `@odata.type` behind `Base.1.24.0`, DOCS-18)
into both `documentations/external/redfish/schemas/v1/` and
`test/fixtures/redfish/schemas/` (the "every published `@odata.type` has a
versioned schema in the fixture" invariant, 9 files / 560,665 bytes, inside
DOCS-6); every client-read field verified present in the served versions —
no code change needed).
Prior: DOCS-18 run — mirrored the **message-registry payload** the pinned
mockup serves (`Base.1.5.0.json` from the DMTF registries path),
**byte-identical** (SHA-256 `c1026341…`) to
`test/fixtures/redfish/dmtf_mockup/Registries/Base.1.5.0.json` — proven
authentic — plus the newest published `Base.1.24.0.json` (125 templates; 1.5.0
→ 1.24.0 adds 65 templates + rewords 39 shared Message strings with
`NumberOfArgs` stable, the emulator-pinned contract); the §8.6/§11.4 rows below
now cite a real mirror file; UI-2 Dashboard `_ErrorSummary` card merged
semantics `Unable to reach N systems` + separate Retry control).
Prior: DOCS-17 run — audited the DSP0266 §13.3.4.3
"Session lifetime" contract against the mirrored `SessionService.json` +
`SessionService.v1_2_0.json` (DOCS-12); pinned the timeout contract with the
new `Session.expiryFromService` model helper + 6 unit tests — `SessionTimeout`
(inactivity TTL) is applied, `AbsoluteSessionTimeout` +
`AbsoluteSessionTimeoutEnabled` (added v1_2_0) optionally bound the deadline to
the *earlier* of the two so the client re-authenticates before the service can
kill the session; the session-timeout trace row below is now model-level OK and
the AuthManager wiring stays #015; UI-2 FirmwareView error state merged
semantics `Unable to load firmware. <message>` + separate Retry control).
Prior: DOCS-16 run — corrected the DSP0266 clause
citations that pointed at an older spec layout against the mirrored
`DSP0266_1.25.0.pdf`: `§8.3 Service Root` → `§7.2.3`, `§8.4/§8.10/§8.14`
resource clauses → schema files + `§9.x` data-model clauses, `§12.2 Actions`
→ `§9.6.14`+`§7.11`, `§12.3 Basic auth` → `§13.3.3`, `§12.4 Sessions` →
`§13.3.4`, `§12.7 Error responses` → `§8.6`, `§9.7 Firmware update` →
`§12.7`; pinned the DSP0266 §9.9 payload-annotation contract with unit tests
(`ResetType@Redfish.AllowableValues` list parse + unrecognized-annotation
tolerance §9.9.1); UI-2 OverviewView error-state merged semantics.
Prior: DOCS-15 run — audited DSP0266 §7.3 "Query parameters"
against the client transport + the emulator-pinned query contract; folded the
normative §7.3.1–§7.3.5 clauses (processing order, `$expand` options incl.
`$levels` default 1 / `MaxLevels`, `$select`, `$filter` operators + precedence,
`clientcontext`, 400/501/507 semantics) into the audit table below; the #018
discovery pass must gate `$expand` on `ProtocolFeaturesSupported` and filter/
project client-side because the pinned mockup applies `$expand` but not
`$filter`/`$select`; pinned the `getJson` query-forwarding transport contract
with a unit test. Prior: DOCS-13 run — mirrored the missing versioned
definitions for the emulator-pinned auth/network/ActionInfo resources
(`Session`, `ManagerAccount`, `Role`, `ManagerNetworkProtocol`, `ActionInfo`,
plus versioned `ServiceRoot` and mockup-served `Task.v1_7_3`/
`TaskService.v1_2_0`). Prior: DOCS-12 — mirrored the missing **versioned**
definitions for the six
aggregator-only families — `UpdateService`/`EventService`/
`SessionService`/`Manager`/`Power`/`Thermal` — newest + mockup-served versions,
so the rows below now cite real mirror files; no client code change needed
(property deltas audited in the DOCS-12 section). Prior: EMULATOR run pinned the
Task resource contract end-to-end:
`TaskState`/`TaskStatus`/`Start`-`EndTime`/`Messages[]` on the mockup's Task 545,
incl. the **absent `PercentComplete`** the #008/#020 poller must treat as unknown,
plus `TaskService.CompletedTaskOverWritePolicy`/`LifeCycleEventOnTaskStateChange`;
DOCS-11 was the prior audit — mirrored the missing `LogEntry` corpus +
`LogService.v1_9_0.json` after the emulator pinned `LogEntry.v1_16_0` shapes;
upstream anchors re-verified: bmcweb `27e0930b`, Redfish-Mockup-Server
`23d21f9a`, DSP0266 1.25.0, schema index current. DOCS-10 — task-monitor
contract + `Task` corpus + `UpdateTask.Retry-After`; DOCS-8 — bmcweb pin moved
`0128851e` → `27e0930b`).
Sources:

- DSP0266 1.25.0 — `redfish/spec/DSP0266_1.25.0.pdf`
- DMTF schema index — `redfish/schemas/v1-index.html` + `redfish/schemas/v1/*.json`
- bmcweb — `redfish/openbmc/Redfish.md`, `REDFISH_CHECKLIST.md`, `OEM_SCHEMAS.md`,
  `CLIENTS.md` (bmcweb master `63a18f4`, re-verified 2026-10-24 12:45 UTC —
  byte-identical to `fbb307a`)

## DOCS-10 — task-monitor contract audit (2026-10-23)

Mirrored the official DMTF `Task` schemas (`Task.json` aggregator,
`Task.v1_7_4.json`, `TaskService.v1_2_1.json`) and audited DSP0266 §12.2
"Asynchronous operations" against the client's async handling:

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Async operation → 202 Accepted + `Location` task monitor URI (may also include `Retry-After`) | DSP0266 §12.2; `Task.json` | `FirmwareService.startSimpleUpdate` + `PowerService.reset` read `Location`; `FirmwareService` now also reads `Retry-After` into `UpdateTask.retryAfterSeconds` (DOCS-10) | `firmware_service_test.dart` (+1 Retry-After parse), `firmware_model_test.dart` (+1 UpdateTask), emulator firmware row | Partial: 202 accepted + Location captured; task *polling* still #008/#020 (firmware) + #022 (power) |
| Task monitor URI format `/redfish/v1/TaskService/TaskMonitors/<TaskMonitorId>` | DSP0266 §12.2 (task monitor "should be in the format") | n/a — client treats the `Location` value as opaque | emulator asserts client accepts the mockup's task URI | Note for #008/#020/#022 |
| GET on the task monitor returns 202 while in process, then the final status + headers + body of the initial operation | DSP0266 §12.2 | not implemented — no task poller | — | GAP: #008/#020 (firmware), #022 (power) |
| DELETE task monitor or Task resource cancels; subsequent GET → 410 Gone / 404 Not Found | DSP0266 §12.2 | not implemented | — | GAP: #008/#020 (upload cancel) |
| `Task.TaskState` (13 values incl. `Cancelled`/`Cancelling`/`Exception`); `TaskStatus` (Health) set only at completion; `PercentComplete` 0–100 (0 before start) | `Task.v1_7_4.json` `TaskState`/`TaskStatus`/`PercentComplete`; DSP0266 §12.2 | `UpdateTask` model captures `taskUri` + `retryAfterSeconds` only (no TaskState parsing yet) | `firmware_model_test.dart`; **emulator pins the mockup Task resource end-to-end: `TaskState Completed`, `TaskStatus OK`, RFC3339 Start/EndTime — and PercentComplete is ABSENT on the fixture, so the poller must treat it as unknown** (pinned 2026-10-23) | Partial: state machine comes with the #008/#020 poller |
| `Task.Messages[]` carries task-associated messages (e.g. `ManagerGoingOfflineTemporarily` for service reboot during firmware update) | `Task.v1_7_4.json` `Messages`; DSP0266 §12.2 | not parsed | **emulator pins the mockup Task `Messages[]` shape: `MessageId` (`Base.*`), `Message`, `MessageArgs[]`, `Severity`** (pinned 2026-10-23) | GAP: #008/#020 task timeline |
| `TaskService.CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, `Tasks` collection | `TaskService.v1_2_1.json` | not read (client only uses `SessionService` etc.) | **emulator pins `CompletedTaskOverWritePolicy=Manual`, `LifeCycleEventOnTaskStateChange=true`, and the enumerable `Tasks` collection** (pinned 2026-10-23) | vendor/feature row for #008/#020 task timeline |
| `Retry-After` on the 202 tells the client how long to wait before polling; services may go offline (firmware update) and shall include `ManagerGoingOfflineTemporarily` + `Retry-After` | DSP0266 §12.2 | `FirmwareService.startSimpleUpdate` parses `Retry-After` (seconds or HTTP-date) into `UpdateTask.retryAfterSeconds` | `firmware_service_test.dart` | Partial: captured but not yet used to schedule the poll (that is #008/#020/#022) |

Folded into code this run:

- `UpdateTask` (the currently-dead handle model) now carries the spec's
  optional poll hint: `retryAfterSeconds` (from the 202 `Retry-After` header,
  seconds or HTTP-date form). `FirmwareService.startSimpleUpdate` builds the
  handle instead of returning a bare `String`, so a future task poller has the
  wait hint without guessing.

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Service root at `/redfish/v1/` with `Systems`, `Managers`, `Chassis`, `UpdateService`, `SessionService` links | DSP0266 §7.2.3 "Service root request"; `ServiceRoot.json` | `lib/redfish/discovery/discovery_engine.dart` (`_crawl`, root seed `redfish/v1/`) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| `@odata.id` link traversal is cycle-safe and depth-bounded (≤3) | DSP0266 §9.6.2 "@odata.id property" + §9.1 "Resources"; `odata.4.0.0.json` (mirrored DOCS-14; the bare `Odata.json` 404s upstream) | `lib/redfish/discovery/discovery_engine.dart` (visited `Set<uri>`, maxDepth) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| Feature detection "nothing is assumed": every UI feature gated on discovered capability | OpenBMC `Redfish.md`; DSP0266 §9.1 "Resources" (resource tree traversal) | `lib/redfish/discovery/feature_rules.dart` → `SystemFeatures` | `test/redfish/discovery/feature_rules_test.dart` | OK |
| Conditional GET re-crawl via `If-None-Match` / ETag (304 short-circuit) | DSP0266 §6.5 "ETags" + §7.2 "GET (read requests)"; `ComputerSystem.json` | `lib/redfish/discovery/discovery_engine.dart` (`_fetchUri` etag map) | `test/redfish/discovery/discovery_engine_test.dart` | OK |
| PATCH write support with `If-Match` / `@odata.etag` | DSP0266 §6.5 "ETags" (weak/strong validation, RFC7232); §7.6 "PATCH (update)" | `lib/redfish/client/redfish_client.dart` `patchJson()` (partial update transport, landed 2026-10-24 — 204/200 normalized, non-2xx → `RedfishException`); **`If-Match` wiring landed 2026-10-25 (DOCS run)** — `patchJson(..., etag:)` sends the precondition header (RFC7232 entity-tag quoting: unquoted/payload-form `@odata.etag` values are quoted, `W/"..."` weak tags preserved), `ODataResource.etag` reads `@odata.etag` from any resource, and `RedfishException.isPreconditionFailed` classifies 412 so a stale-token caller can re-fetch instead of blind-retrying; Boot/IndicatorLED PATCH *actions in a service + UI* stay #016 | `test/redfish/client/auth_manager_test.dart` "patchJson with etag sends quoted If-Match header" + "keeps weak/pre-quoted tags verbatim" + "If-Match from etag wins over headers" + "412 throws precondition failure RedfishException (isPreconditionFailed, non-retryable)" + "quoteEntityTag grammar helper" (+ `test/redfish/models/odata_test.dart` "@odata.etag accessor, null when absent"; emulator PATCH round-trip pin below: the DMTF mockup IGNORES If-Match and applies any body, so 412 enforcement stays unit-level — pinned 2026-10-24) | OK — transport + precondition wiring; Boot/IndicatorLED PATCH flow in a service + UI stays #016 |
| Error envelope: `error.code`, `error.message`, `error.@Message.ExtendedInfo[]`; message templates from the published `Base.*` MessageRegistry | DSP0266 §8.6 "Error responses" + §11.4 "Message registries"; `redfish_error.md`; `registries/Base.1.5.0.json` + `registries/Base.1.24.0.json` (mirrored DOCS-18 — the 1.5.0 payload is byte-identical to the pinned mockup's, so the emulator-pinned `Base.*` templates resolve against a real mirror file) | `lib/redfish/models/redfish_error.dart` | `test/redfish/models/models_test.dart`; emulator MessageRegistry group pins the Base.1.5.0 discovery + template surface | OK (see #014: ExtendedInfo parsing hardening) |
| Session auth: `POST SessionService/Sessions` → `X-Auth-Token`, session reuse | DSP0266 §13.3.4 "Redfish session login authentication"; `SessionService.json` + `SessionService.v1_2_0.json` (newest, DOCS-12) | `lib/redfish/client/auth_manager.dart` | `test/redfish/client/auth_manager_test.dart` | OK (see #015: discover session URI instead of hardcoding) |
| Basic auth fallback | DSP0266 §13.3.3 "HTTP Basic authentication" | `lib/redfish/client/auth_manager.dart` | `test/redfish/client/auth_manager_test.dart` | OK |
| No plaintext password at rest; token in secure storage | DSP0266 §13.3.4 + §13.2 "Sensitive data"; OpenBMC `Redfish.md` | `lib/core/storage/secure_storage.dart`, `AuthManager` | `test/redfish/client/auth_manager_test.dart` | OK |
| Power control: `ComputerSystem.Reset` action with `ResetType` body; 202+`Location` accepted | DSP0266 §9.6.14 "Actions property" + §7.11 "POST (action)"; `ComputerSystem.json` `Actions` | `lib/features/power/power_service.dart` | `test/features/power/` | OK |
| Sensor telemetry: `Chassis[*].Thermal` / `Sensors`, reading + units | DSP0266 §9.6.15 `Oem`/§9.1 links; schema contracts in `Sensor.json` + `Sensor.v1_8_1.json` (mockup-served) + `Sensor.v1_14_0.json` (newest) + `Thermal.json` + `Thermal.v1_7_3.json` (newest, DOCS-12); DSP0266 does not enumerate per-resource schemas — the schema files are the normative property source | `lib/features/sensors/sensors_controller.dart` | `test/features/sensors/` | OK |
| System overview: `ComputerSystem` identity (`Manufacturer`/`Model`/`SKU`/`SerialNumber`/`PartNumber`/`BiosVersion`), `PowerState`, `Status.Health`(+Rollup), `ProcessorSummary`/`MemorySummary`, `IndicatorLED`, leading `Chassis` thermal | DSP0266 §9.1 "Resources" + §9.6 "Properties"; schema contracts in `ComputerSystem.v1_22_0.json` (mockup-served) + `ComputerSystem.v1_29_0.json` (newest, DOCS-2) + `Thermal.v1_7_3.json` (DSP0266 does not carry per-resource property lists) | `lib/features/overview/overview_service.dart` (+ `models/system_overview.dart`) hydrates system + best-effort chassis thermal | `test/features/overview/overview_provider_test.dart` + `overview_view_test.dart`; **emulator suite now pins the full hydrate end-to-end** against the DMTF mockup (#006) | OK |
| Firmware inventory: `UpdateService` / `SoftwareInventory` collection | DSP0266 §12.7 "Update service" + §7.2.2 "Resource collection requests"; `SoftwareInventory.json` + `SoftwareInventory.v1_10_1.json` (mockup-served) + `SoftwareInventory.v1_15_0.json` (newest, DOCS-2) (schema contract) | `lib/features/firmware/firmware_models.dart` | `test/features/firmware/` | OK |
| Firmware update: `UpdateService.SimpleUpdate` (entity-upload mode TBD); `UpdateService.ServiceEnabled` gates the capability | DSP0266 §12.7 "Update service" (§12.7.2.1 "Simple updates"); `UpdateService.json` (`ServiceEnabled`) + `UpdateService.v1_17_1.json` (newest, DOCS-12); OpenBMC `Redfish.md` §UpdateService | `lib/features/firmware/firmware_service.dart`; `FeatureRules.firmwareUpdate` honors `ServiceEnabled` (DOCS-5) | `test/features/firmware/`; `feature_rules_test.dart` (ServiceEnabled case) | Partial — task monitoring in #008/#020 |
| KVM capability: `Manager.GraphicalConsole` / OEM console detection | OpenBMC `Redfish.md`; `Manager.json` + `Manager.v1_25_0.json` (newest, DOCS-12) | `lib/redfish/discovery/feature_rules.dart` (`kvm`, `kvmType`) | `test/redfish/discovery/feature_rules_test.dart` | OK (rendering gated in #009/#021) |
| Event subscription: `EventService.Subscriptions` — POST → 201 + `Location`; DELETE to unsubscribe | DSP0266 §12.1.1–§12.1.2 "Eventing"; `EventService.json` + `EventService.v1_12_0.json` (newest, DOCS-12) | **not implemented** | — | GAP: DOCS-7 — decision recorded below (out-of-scope this milestone) |
| SSE event stream: GET `EventService.ServerSentEventUri` | DSP0266 §12.1.3 "Open an SSE connection"; `EventService.v1_6_9+` | **not implemented** (no SSE transport dependency in `pubspec.yaml`) | — | GAP: DOCS-7 — revisit when telemetry/eventing lands (#007/#019) |
| EventType-based eventing deprecated; filter subscriptions by `RegistryPrefixes` / `ResourceTypes` / `MessageIds` | DSP0266 §12.1.4–§12.1.5 | n/a (no subscriber yet) | — | Note for a future implementation |
| Task monitor: 202 + `Location` + optional `Retry-After`; GET monitor → 202 while running, then final status + body; DELETE cancels; 404/410 after completion | DSP0266 §12.2 "Asynchronous operations"; `TaskService.json` | `lib/features/firmware/firmware_service.dart` + `lib/features/power/power_service.dart` read `Location`, store the task URI, do **not** poll | tests cover 202+`Location` acceptance | Partial/GAP: #008/#020 (firmware), #022 (power) |
| bmcweb `EventService`: `SubmitTestEvent`, `DeliveryRetryAttempts` (default 3), `DeliveryRetryIntervalSeconds`, `EventFormatTypes`, `SSEFilterPropertiesSupported` | OpenBMC `Redfish.md` §EventService | not implemented | — | vendor row (bmcweb) |
| bmcweb `TaskService`: `CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, `Tasks` collection | OpenBMC `Redfish.md` §TaskService | not implemented (202 accepted only) | — | vendor row (bmcweb) |
| Session timeout handling (`SessionService.SessionTimeout` + v1_2_0 `AbsoluteSessionTimeout`/`AbsoluteSessionTimeoutEnabled`) | DSP0266 §13.3.4.3 "Session lifetime"; `SessionService.json` + `SessionService.v1_2_0.json` (newest, DOCS-12) | `lib/redfish/models/session.dart` — `Session.expiryFromService` computes the conservative *earlier* deadline (`createdAt + min(SessionTimeout, AbsoluteSessionTimeout)` when the absolute timeout is enabled, else `SessionTimeout`) — DOCS-17 | `test/redfish/models/models_test.dart` (+6 DOCS-17 expiry tests); emulator `SessionService.SessionTimeout == 30` published (#015) | Partial: model-level contract pinned; AuthManager has no SessionService fetch yet — wiring expiry into login is #015 |
| bmcweb firmware update: `HttpPushUri` / `MultipartHttpPushUri` upload (no `SimpleUpdate` action) | OpenBMC `Redfish.md` §UpdateService (bmcweb `27e0930b`); `UpdateService.v1_17_1.json` `MultipartHttpPushUri` | `UpdateServiceInfo` exposes `httpPushUri` **and** `multipartHttpPushUri` (DOCS-9); `startSimpleUpdate` POSTs `#UpdateService.SimpleUpdate` — **will not match bmcweb** | unit: `test/features/firmware/firmware_model_test.dart` (+3 DOCS-9: multipart parse, absent fallback, copyWithInventory); emulator: `emulator_suite_test.dart` asserts `UpdateServiceInfo.httpPushUri == '/FWUpdate'` on the DMTF mockup | Partial: push *upload path* still #008/#020, but both push URIs now surfaced |
| bmcweb reset types: `ResetActionInfo` ActionInfo (`Parameters/AllowableValues`) instead of system-level `SupportedResetTypes` | OpenBMC `Redfish.md` §ComputerSystem (`ResetActionInfo` resource) | `FeatureRules.supportedResetTypes` unions all three sources: `SupportedResetTypes`, the `ResetType@Redfish.AllowableValues` annotation on `#ComputerSystem.Reset` (DOCS-4/13 fix, run 2026-10-23), **and the `@Redfish.ActionInfo` resource the action links to (`Parameters[].AllowableValues` on `ResetType` — the bmcweb `ResetActionInfo` crawl, wired 2026-10-25 EMU run)** | `feature_rules_test.dart` "falls back to the ResetType@Redfish.AllowableValues annotation" + "never reads the manager-level guard" + "unions the ActionInfo resource allow-list" + "resetTypesFromActionInfo follows the action's @Redfish.ActionInfo link"; discovery-engine test "follows @Redfish.ActionInfo links and folds Parameters[].AllowableValues into the reset allow-list"; emulator pin "engine follows @Redfish.ActionInfo links" (live `SimpleUpdateActionInfo`) | OK: empty-`SupportedResetTypes` BMCs surface the true allow-list from the action annotation **and** from a linked `ResetActionInfo` resource; ActionInfo *resource* crawling is no longer a TODO — the engine follows the links and FeatureRules parses them |
| bmcweb serial console lives on the ComputerSystem (`SerialConsole/SSH|IPMI`), not the Manager | OpenBMC `Redfish.md` §ComputerSystem (`SerialConsole` fields) | `FeatureRules._managerConsoleType` only checks `Manager.GraphicalConsole/SerialConsole/Oem` | `feature_rules_test.dart` | Partial: GraphicalConsole detection still correct; System-level SerialConsole not yet mapped (see #009/#021 KVM) |
| bmcweb auth surface: `AccountService.Oem.OpenBMC.AuthMethods.*` (`BasicAuth`, `Cookie`, `SessionToken`, `TLS`, `XToken`) + `HTTPBasicAuth` | OpenBMC `Redfish.md` §AccountService | `AuthManager` prefers session, falls back to basic | `test/redfish/client/auth_manager_test.dart` | Partial: vendor auth-method negotiation is #015/#026 |
| bmcweb telemetry: `TelemetryService` with `MetricReports` / `Triggers` / `MetricReportDefinitions` | OpenBMC `Redfish.md` §TelemetryService | n/a — sensors poll `Thermal`/`Sensors` directly | sensors tests | Note: alternative telemetry source for #007/#019 |
| Log service: `ComputerSystem.LogServices` → `LogService` (`ClearLog` action, `ServiceEnabled`) → `Entries` collection; `LogEntry` (`EntryType` SEL/Event, `Severity`, `Created` RFC3339, `Message`, `Links.OriginOfCondition`); `@odata.nextLink` pagination | `LogService.json` + `LogService.v1_6_0.json` (mockup-served, DOCS-19) + `LogService.v1_9_0.json` (newest, DOCS-11) + `LogEntry.json` + `LogEntry.v1_22_0.json` + `LogEntryCollection.json` (mirrored DOCS-11; `LogEntry.v1_16_0.json` kept for the mockup's pinned shapes); DSP0266 §9.6.12 (`Members@odata.nextLink`) + §9.6.11 (`Members`) define the paginated collection contract; emulator pins LogService.v1_6_0 + LogEntry.v1_16_0 shapes | not implemented — no log reader feature yet (future #010 hardening / diagnostics) | emulator: `emulator_suite_test.dart` "log service" group asserts collection → ClearLog target → Entries fields + nextLink (`\u0024skiptoken`) | Contract pin only; feature work not queued — revisit via FUTUREWORK if a log view is planned |

## DOCS-12 — six-family versioned schema mirror audit (2026-10-23)

Closed the "aggregator-only" corpus gap: `UpdateService`, `EventService`,
`SessionService`, `Manager`, `Power`, and `Thermal` had **no versioned
definitions** in the external mirror (`documentations/external/redfish/
schemas/v1/`), even though the client maps them and the fixture snapshot ships
the newest versions. Mirrored, for each family, the **newest** versioned file
(what the aggregator `$ref`s) **and** the **mockup-served** version (what the
pinned `23d21f9a` fixture publishes as `@odata.type`) — the DOCS-11 LogEntry
precedent. 12 files, 553,772 bytes total (inside DOCS-6 budget); SHA-256s in the
manifest (`documentations/external/README.md`). The six mockup-served versions
were also copied into `test/fixtures/redfish/schemas/` so every `@odata.type`
the mockup publishes has a versioned schema in the fixture.

| Family | Newest (mirrored) | Mockup-served (mirrored) | Newest-vs-served notable deltas | Client impact |
|---|---|---|---|---|
| `UpdateService` | `v1_17_1` | `v1_13_0` | `LocalImageStore*` (local image repo), `Stage`/`Activate` actions, `UpdateServiceCapabilities` | none this run — #008/#020 push flow uses `HttpPushUri`/`MultipartHttpPushUri` (parsed since DOCS-9); `SimpleUpdate` remains the entity-upload path for non-bmcweb |
| `EventService` | `v1_12_0` | `v1_10_1` | `OriginResourcesSupported`, `SSEIncludeOriginOfConditionSupported` | none — events out-of-scope (DOCS-7); note for when #007/#019 lands |
| `SessionService` | `v1_2_0` | `v1_1_8` | `AbsoluteSessionTimeout` + `AbsoluteSessionTimeoutEnabled` | #015 could honor absolute timeout when a service publishes it (in addition to `SessionTimeout`) |
| `Manager` | `v1_25_0` | `v1_19_0` | `SecurityMode`/`OEMSecurityMode`, `ReadyToRemove`, `DateTimeSource`, `#Manager.UpdateSecurityMode`, `ServiceUseNotification` | none — KVM detection (`GraphicalConsole`) unchanged |
| `Power` | `v1_7_3` | `v1_7_2` | no property deltas | none |
| `Thermal` | `v1_7_3` | `v1_7_2` | no property deltas | none |

The table rows above now cite the real mirrored files for the six families
(e.g. `SessionService.v1_2_0.json`, `UpdateService.v1_17_1.json`,
`Manager.v1_25_0.json`, `Thermal.v1_7_3.json`). All upstream anchors
re-verified this run (see `documentations/external/README.md`).

## DOCS-13 — auth/network/ActionInfo corpus mirror audit (2026-10-23)

Closed the corpus gap for the resources the emulator pins but the external
mirror had no versioned definitions for. For each family, mirrored the
aggregator + the **newest** versioned file (what the aggregator `$ref`s) + the
**mockup-served** version (what the pinned `23d21f9a` fixture publishes as
`@odata.type`) — the DOCS-11/12 precedent; plus the mockup-served Task-family
versions (`Task.v1_7_3`, `TaskService.v1_2_0`) that DOCS-10 had not mirrored
(DOCS-10 mirrored only the newest `Task.v1_7_4` / `TaskService.v1_2_1`).

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Session resource: `X-Auth-Token` created on session POST; session carries `UserName`/`Password`/`Oem`; session-lifetime contract | DSP0266 §13.3.4 "Redfish session login authentication" (§13.3.4.3 session lifetime / §13.3.4.4 session termination or logout); `Session.json` + `Session.v1_9_0.json` (newest) + `Session.v1_7_1.json` (mockup-served) | `lib/redfish/models/session.dart`, `lib/redfish/client/auth_manager.dart` | `auth_manager_test.dart`; emulator session-lifecycle group pins `#Session.v1_7_1.Session` | OK (see #015/#017/#026 — URI discovery + expiry hardening) |
| ManagerAccount (user account): `UserName`, `RoleId`, `Enabled`, `Password`, `AccountTypes`; Accounts collection under AccountService | `AccountService.json` + `ManagerAccount.json` + `ManagerAccount.v1_14_2.json` (newest) + `ManagerAccount.v1_12_0.json` (mockup-served) | not parsed yet (auth surface TO-BUILD) | emulator AccountService group pins `#ManagerAccount.v1_12_0.ManagerAccount` detail — `AccountTypes`/`PasswordChangeRequired`/`Locked`/`Enabled`/`Links.Role` + `#ManagerAccount.ChangePassword` target, and `Password` masked on the wire (12:xx run) | Partial — #015/#026 |
| Role: `RoleId`, `AssignedPrivileges`, `OemPrivileges`; Roles collection under AccountService | `Role.json` + `Role.v1_3_3.json` (newest) + `Role.v1_3_1.json` (mockup-served) | not parsed yet | emulator Roles group pins the collection (3 predefined roles) + `#Role.v1_3_1.Role` `IsPredefined`/`AssignedPrivileges`/`OemPrivileges` (12:xx run) | Partial — #015/#026 |
| ManagerNetworkProtocol: service endpoint table (`KVMIP` port, `HTTPS`, `SSH`, …) the #009/#021 console renderer resolves | `ManagerNetworkProtocol.json` + `ManagerNetworkProtocol.v1_14_0.json` (newest) + `ManagerNetworkProtocol.v1_10_0.json` (mockup-served) | not parsed yet (console endpoint TO-BUILD) | emulator "manager network" group pins `#ManagerNetworkProtocol.v1_10_0.ManagerNetworkProtocol` KVMIP 5288 / HTTPS 443 / SSH 22 (11:39 run) | Partial — #009/#021 must resolve the endpoint from the advertised KVMIP port |
| ActionInfo: `Parameters[].AllowableValues` (bmcweb `ResetActionInfo` is the reset-type allow-list source on OpenBMC) | OpenBMC `Redfish.md` §ComputerSystem; `ActionInfo.json` + `ActionInfo.v1_6_0.json` (newest) + `ActionInfo.v1_4_1.json` (mockup-served); DSP0266 §9.9.2 "Allowable values for strings" (annotation form) / §9.6.14 "Actions property" | `FeatureRules.supportedResetTypes` falls back to the `ResetType@Redfish.AllowableValues` annotation on `#ComputerSystem.Reset` (DOCS-4/13 fix, run 2026-10-23) | `feature_rules_test.dart` "falls back to the annotation" + "unions + dedupes" + "never reads manager allow-list"; emulator "ActionInfo resource contract" group pins the **resource form live** — `CertificateService` actions advertise `@Redfish.ActionInfo` links that resolve to `#ActionInfo.v1_4_1.ActionInfo` resources (`GenerateCSRActionInfo` 13 parameters each with `Name`/`Required`/`DataType`, plus per-parameter `AllowableValues` on `KeyPairAlgorithm`/`KeyCurveId`/`KeyUsage`; `ReplaceCertificateActionInfo` with `CertificateType` `AllowableValues ['PEM']`) — the exact `Parameters[].AllowableValues` shape a `ResetActionInfo`-style crawler parses (run 2026-10-25) | OK (annotation form pinned; ActionInfo *resource* contract now pinned live via the served CertificateService resources — the #022/#016 crawler has the shape to build against; `ResetActionInfo` itself is still absent on this fixture) |
| ServiceRoot: service links + `ProtocolFeaturesSupported` (Expand/Excerpt/Filter/Select) the discovery pass must use | DSP0266 §7.2.3 "Service root request" + §7.3.1 "Query parameter overview"; `ServiceRoot.json` + `ServiceRoot.v1_22_0.json` (newest) + `ServiceRoot.v1_16_1.json` (mockup-served) | `lib/redfish/discovery/discovery_engine.dart` + `feature_rules.dart` (root crawl) | `discovery_engine_test.dart`; emulator service-root group pins `#ServiceRoot.v1_16_1.ServiceRoot` | OK (query-capability surface used by #018) |
| Task/TaskService mockup-served versions: `#Task.v1_7_3.Task`, `#TaskService.v1_2_0.TaskService` | `Task.v1_7_3.json` + `TaskService.v1_2_0.json` (mirrored DOCS-13; newest v1_7_4/v1_2_1 from DOCS-10) | `UpdateTask` model (taskUri + retryAfterSeconds) | emulator Task group pins the served shapes (09:14 run) | Partial — #008/#020 poller |

Notable newest-vs-mockup-served deltas (audited, no client code change this
run): `Session.v1_9_0` expands session-type/OEM fields (no field the current
code reads changed); `ManagerAccount.v1_14_2` adds `PasswordExpiration`/
`RemoteRole`/account-types (context for #015/#026); `Role.v1_3_3` no property
deltas; `ManagerNetworkProtocol.v1_14_0` adds `NTPProtocolEnabled`/
`NTPservers[]`/`Kerberos*` (console endpoint resolution unchanged);
`ActionInfo.v1_6_0` adds `ActionCapabilities` + `AllowableValueDescriptions`
(the `Parameters/AllowableValues` contract for #022/#016 is stable);
`ServiceRoot.v1_22_0` adds `Tasks` + link-era changes (`ProtocolFeaturesSupported`
locations stable for #018). The six mockup-served versions + Task/TaskService
served versions were copied into `test/fixtures/redfish/schemas/` so the fixture
has a versioned schema for every `@odata.type` the mockup publishes across these
client-relevant families.

## Trace notes

- The 21 base aggregator schemas under `redfish/schemas/v1/` are the DMTF
  "latest" entry points the app maps; versioned definitions are also mirrored
  under `redfish/schemas/v1/` for every client-mapped family (ComputerSystem,
  Chassis, Sensor, AccountService, EthernetInterface, SoftwareInventory, Task,
  TaskService, LogEntry, LogService + DOCS-12's UpdateService, EventService,
  SessionService, Manager, Power, Thermal + DOCS-13's Session, ManagerAccount,
  Role, ManagerNetworkProtocol, ActionInfo, ServiceRoot + DOCS-19's
  MessageRegistry), with the aggregator-`$ref`ed newest plus the
  mockup-served versions for emulator provenance. DOCS-19 (2026-10-24) closed
  the last served-version gap: `Sensor.v1_8_1`, `ComputerSystem.v1_22_0`,
  `Chassis.v1_25_0`, `AccountService.v1_15_0`, `SoftwareInventory.v1_10_1`,
  `LogService.v1_6_0`, `EthernetInterface.v1_12_0`,
  `MessageRegistry.v1_0_0` (+ newest `MessageRegistry.v1_9_0`) are now in the
  fixture and mirror — every `@odata.type` the pinned mockup publishes for a
  client-mapped family has a versioned schema in the fixture.
- GAP rows are tracked in `FUTUREWORK.md`; do not re-file them in the issue
  tracker unless acceptance criteria are added.
- bmcweb-specific behaviour (OEM schemas, console types) is cited from
  `redfish/openbmc/OEM_SCHEMAS.md` + `Redfish.md` — vendor behaviour, not DMTF.
- **Test platforms:** beyond unit/widget tests, the project has two integration
  layers against authentic DMTF payloads:
  1. `test/integration/discovery_mock_test.dart` — in-process HTTP mock server
     (`test/helpers/mock_redfish_server.dart`), runs in plain `flutter test`.
  2. `test_integration/emulator/emulator_suite_test.dart` — real DMTF
     Redfish-Mockup-Server over HTTPS (self-signed, test-only TLS) via
     `tool/emulator/run_tests.sh` (pin `23d21f9a`); skipped unless
     `REDFISH_EMULATOR_URL` is defined. 80 tests: service root + BFS discovery
     (incl. the engine following `@Redfish.ActionInfo` links and capturing the
     live `SimpleUpdateActionInfo` resource — the bmcweb `ResetActionInfo`-
     style crawl wired into `FeatureRules.supportedResetTypes`, #022/#016) +
     chassis Controls surface (PowerLimit/CPU1Freq read + SetPoint PATCH
     round-trip + the `ControlResource.validateSetPoint` pre-validation rule
     applied live, #022/#016) +
     discoverable `SessionService` URI (#017), sensors (Thermal + 41-member
     Sensors collection #007/#019), firmware inventory + `HttpPushUri` +
     SimpleUpdateActionInfo (#008/#020), KVM console, systems detail
     (ComputerSystem inventory fields + `ResetType@Redfish.AllowableValues`),
     managers detail (console capabilities + manager-level Reset allow-list,
     DOCS-4/#022), chassis detail (inventory + Thermal/Power sub-resource chain
     + system link), session + basic auth, power state/reset, 404/405 error
     mapping, session lifecycle + SessionTimeout (#015/#017), TaskService +
     EventService contracts (DOCS-7), query capabilities (#018) incl. a live
     `$expand=.($levels=1)` round-trip pin — the Systems collection inlines
     full bodies (Model/PowerState/Actions.Reset allow-list +
     Processor/MemorySummary) for a lightweight discovery pass (pinned
     2026-10-23 17:xx), Accounts
     collection (#015/#026), HttpPushUriApplyTime modes (#008/#020),
      **query-behavior contract for #018 (pinned 2026-10-23):** `$expand=*`
      (ExpandAll) also inlines full ComputerSystem bodies in one round trip
      (same fields as `$expand=.($levels=1)`), while `$filter`/`$select` are
      **advertised but NOT applied** (the mockup returns the unfiltered Roles
      collection for `$filter=Id eq 'NOPE'` and the full system body for
      `$select=Model`) — the #018 lightweight discovery pass must filter/
      select client-side and rely only on `$expand` for payload shaping,
      **`getJson(path, query:)` map-form `$expand` round-trip pinned live
      (2026-10-23 22:xx)** — the 19:25 transport unit test (query map forwards
      to the wire) + the URL-string pins above are joined: a #018 pass calling
      `getJson('/redfish/v1/Systems', query: {'\$expand': '.($levels=1)'})`
      receives the same inlined full member bodies as the URL-string form,
      **MessageRegistry contract (pinned 2026-10-24 02:xx)** — the service
      root advertises `Registries` -> `MessageRegistryFileCollection`
      (Base.1.5.0) -> `Location[0].Uri` resolves to the `#MessageRegistry`
      JSON defining the 60 Base.* message templates (Message/Severity/
      NumberOfArgs) behind `RedfishError.code`/`firstMessage` (DSP0266 §8.6
      error responses + §11.4 message registries; #014 model),
      **Sessions collection + Session resource contract (#015/#026, pinned
      2026-10-24 03:5x)** — the Sessions collection is enumerable from the
      discovered SessionService URI (members are session resources, never the
      collection; pre-seeded `#Session.v1_7_1` for Administrator carries
      Id/Name/Description/UserName and NO Password), and a **security-relevant
      negative pin**: a session minted via POST resolves to a body that echoes
      the login `Password` and lacks `@odata.type`/SessionType
      (non-conformant — DSP0266 §13.3.4 Session has no Password property); the
      #015 AuthManager must persist the token/location from the create
      RESPONSE HEADERS and never read session-resource bodies for secrets;
      **ResetType validation negative pin (#014/#022, pinned 2026-10-24)** —
      the pinned mockup accepts ANY ResetType body value (Bogus returns 204
      like a valid one), so the client's 400 `ResetTypeInvalid` path stays
      unit-level and the UI must pre-validate against the advertised
      allow-list,
      **UpdateService action surface (#008/#020, pinned 2026-10-24):** (a)
      `FirmwareService.startSimpleUpdate` live round-trip — the mockup
      accepts ANY SimpleUpdate body and answers 204 with NO task-monitor
      `Location`, so the returned `UpdateTask` carries null
      taskUri/retryAfterSeconds (the 202-with-Location monitor path stays
      unit-level; the UI must not require a monitor URI for a queued
      handle); (b) negative pin — the advertised `HttpPushUri` (`/FWUpdate`)
      is NOT implemented: POSTing a binary upload body fails with 400 and an
      EMPTY body (no `@Message.ExtendedInfo` envelope; connection closed;
      GET /FWUpdate 404s), so the #020 binary-push upload flow stays
      unit-level and the client normalizes it as `RedfishException` HTTP 400
      with no error code,
      **OverviewService end-to-end hydration (#006: identity/health/power/
     processor-memory summaries/indicator-LED/leading-thermal), LogService +
     LogEntry collection incl. ClearLog action + `@odata.nextLink` pagination
     (LogService.v1_6/LogEntry.v1_16 contract, pinned 2026-10-23 06:10), Task
     resource contract (TaskState/TaskStatus/Start-EndTime/Messages;
     PercentComplete absent on the fixture — the #008/#020 poller must treat it
     as unknown) + TaskService CompletedTaskOverWritePolicy/LifeCycle fields
     (pinned 2026-10-23 08:xx), Manager NetworkProtocol + EthernetInterfaces
     surface (KVMIP/SSH/HTTPS service endpoints for the #009/#021 KVM console
     renderer + NIC MAC/IP/VLAN fields — pinned 2026-10-23 11:xx), account-
     service auth surface: AccountService lockout/password-policy fields +
     Roles link (AccountService.v1_15_0), Roles collection (3 predefined roles
     Administrator/Operator/ReadOnly with AssignedPrivileges +
     OemPrivileges — Role.v1_3_1), ManagerAccount detail
     (AccountTypes/PasswordChangeRequired/Locked/Enabled/Links.Role +
     #ManagerAccount.ChangePassword target — ManagerAccount.v1_12_0,
     pinned 2026-10-23 12:xx; the #015/#026 auth surface, DOCS-13 schemas).**
  Both cover the rows above end-to-end against authentic payload shapes.
   **Chassis metrics + subsystem contracts (pinned 2026-10-24):** the
   `#EnvironmentMetrics.v1_3_1` aggregate telemetry surface
   (TemperatureCelsius/PowerWatts/PowerLimitWatts/FanSpeedsPercent with
   `DataSourceUri` links into the Sensors collection — a #019 receiver or the
   #006 power card can poll ONE resource), the `#ThermalSubsystem.v1_3_1`
   surface (Fans collection + FanRedundancy NPlusM groups + `#ThermalMetrics.
   v1_3_1` TemperatureSummaryCelsius Intake/Exhaust/Internal/Ambient), and the
   `#PowerSubsystem.v1_1_1` surface (PowerSupplies collection +
   `#PowerSupply.v1_5_3` detail incl. the `#PowerSupply.Reset` action target +
   Metrics link). Documented negative: the legacy `/Chassis/1U/Power`
   embedded PowerSupplies member reports `Status.Health == 'Warning'` while
   the current OverviewService rollup reads ComputerSystem/Chassis Status —
   a future #006/#019 improvement should surface PSU health from the legacy
   Power surface or the subsystem PowerSupplies. **Corpus closed (DOCS-20,
   2026-10-24):** the newly pinned families now have their versioned schemas
   in the fixture AND mirror (`EnvironmentMetrics.v1_3_1`,
   `ThermalSubsystem.v1_3_1`, `ThermalMetrics.v1_3_1`,
   `PowerSubsystem.v1_1_1`, `PowerSupply.v1_5_3`,
   `PowerSupplyMetrics.v1_1_1`, `Fan.v1_5_1`, `FanCollection`,
   `PowerSupplyCollection`, plus the `Redundancy` chain the FanRedundancy
   groups cite) — the "every published `@odata.type` for a client-relevant
   family has a versioned schema in the fixture" invariant restored.
   **Batters + action round-trips (pinned 2026-10-24, EMU 48→50):** the
   `#BatteryCollection` → `#Battery.v1_2_2` Module1 detail
   (Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+
   ActualWattHours/MaxDischargeRateAmps, StateOfHealthPercent with a
   `DataSourceUri` → Sensors/Battery1StateOfHealth resolving live, and the
   `#Battery.SelfTest`/`#Battery.Calibrate` action targets) + the
   `#BatteryMetrics.v1_0_3` electrical telemetry (InputVoltage/OutputVoltages/
   InputCurrentAmps/OutputCurrentAmps/StoredEnergyWattHours/TemperatureCelsius
   /ChargePercent/CellVoltages[8] with `DataSourceUri` links into the Sensors
   collection — the same wired-surface shape as EnvironmentMetrics/
   ThermalMetrics, so #007/#019 can follow battery telemetry to raw sensors).
   Action round-trip contract: `#Battery.SelfTest`/`#Battery.Calibrate` POST
   → 204 (the mockup's `/Actions/` framework serves them), while the
   **advertised `#PowerSupply.Reset` target is NOT implemented** — its URI has
   no `/Actions/` segment, so POST returns 404 with an empty body (client
   normalizes as `RedfishException` HTTP 404; the same shape as the
   unsupported-action pin). #022/#006 firmware/PSU work must treat an
   advertised action target as a *candidate*, never a contract, on this
   fixture. **Corpus closed (DOCS-21, 2026-10-24):** `#Battery.v1_2_2`,
   `#BatteryMetrics.v1_0_3`, `#BatteryCollection` (and the `Battery.json` /
   `BatteryMetrics.json` aggregators) now have versioned schemas in the
   fixture AND mirror — property-delta audit: every pinned field present in
   the served defs, `Sensor` excerpt refs resolve through the already-mirrored
   `Sensor.v1_8_1.json`; newest `Battery.v1_5_0` / `BatteryMetrics.v1_1_0`
   are additive only (BatteryChemistryType/EnergyStorageType/
   NominalOutputVoltage/ServicedDate; CRate/ERate) — the emulator-pinned
   contract holds; no code change needed.
   **Corpus invariant verified LIVE (EMU 50→52, 2026-10-24):** a new
   integration test crawls the running mockup from the service root
   (following every relative `@odata.id` + `@Redfish.ActionInfo` link,
   excluding `/Actions/` POST targets) and asserts that **every published
   `@odata.type` for a client-mapped family has its served-version schema in
   `test/fixtures/redfish/schemas/`** — the DOCS-19/20/21 invariant as a
   runnable check instead of a docs claim. The crawl reaches >50 published
   types (the fixture's ~100-resource tree) and stays green because the
   DOCS-19/20/21 mirror work closed every served-version gap. **EventDestination
   detail pinned (DOCS-7 bed for #019):** the four `EventService/Subscriptions`
   members carry `#EventDestination.v1_14_0.EventDestination` with protocol
   variants — Redfish (`Protocol` Redfish / `SubscriptionType` RedfishEvent),
   SNMPv3 (`SNMP.AuthenticationProtocol` HMAC_SHA96 + `EncryptionProtocol`
   CFB128_AES128 with key material null on the wire), SMTP/OEM (`Protocol`
   SMTP / `SubscriptionType` OEM, mailto: Destination), and SyslogTCP
   (`SyslogFilters[0]` LowesSeverity/LogFacilities) — the future #019
   receiver's subscription-shape contract.
   **Bios `@Redfish.Settings` surface (pinned 2026-10-24, EMU 52→53):** the
   system's `/Bios` resource carries the DSP0266 §9.9 `@Redfish.Settings`
   payload annotation with a real **ETag** (`9234ac83b9700123cc32`) for its
   pending-settings object — the only ETag-ish token this fixture serves (no
   resource-level `@odata.etag` / HTTP ETag header exists). This refines the
   older tracking note "etag behaviour cannot be pinned on this fixture":
   header-level ETags are absent, but the **settings-object ETag IS pinable**
   and is exactly the optimistic-concurrency token a #016 PATCH/If-Match flow
   must send. The pin also covers the pending-settings resource
   (`Bios/Settings`, `#Bios.v1_2_2.Bios` Id `Settings`) whose attribute set
   differs from the current one (EmbeddedSata Raid→Ahci, ProcTurboMode
   Enabled→Disabled — the "pending vs current" compare a BIOS-config editor
   presents), `@Redfish.Settings.Messages[0]` `Base.1.0.SettingsFailed` +
   RelatedProperties from the last failed apply, and the `#Bios.ResetBios`
   action (POST 204 via the mockup's `/Actions/` framework) with
   `#Bios.ChangePassword` advertised (credential-bearing action — never
   round-tripped with real secrets in this suite). (Schema citations for the
    pinned surface now resolve to the mirrored
    `Bios.v1_2_2.json` + `Settings.v1_3_5.json` — DOCS-23, 2026-10-24.)
    **Boot override surface (pinned 2026-10-24, EMU 53→54):**
    `#ComputerSystem.Boot` publishes `BootSourceOverrideEnabled` (Once),
    `BootSourceOverrideMode` (UEFI), `BootSourceOverrideTarget` (Pxe) and the
    **`BootSourceOverrideTarget@Redfish.AllowableValues` annotation** — 10
    values (None/Pxe/Cd/Usb/Hdd/BiosSetup/Utilities/Diags/SDCard/UefiTarget)
    — the same annotation-form allow-list pattern as `#ComputerSystem.Reset`;
    a boot-control UI must pre-validate against it (#022/#016 rule),
    **Live PATCH round-trip (#016, pinned 2026-10-24, EMU 54):** the FIRST
    PATCH pin on this fixture — `patchJson` on `/Systems/437XR1138R2`
    (`Boot.BootSourceOverrideEnabled: Disabled`) returns 204 with no content
    and the change **persists** into the served resource (GET confirms; the
    mockup keeps PATCHes in memory — the on-disk fixture stays byte-identical;
    header-level `@odata.etag`/HTTP ETags remain absent, so If-Match
    enforcement stays unit-level). Negative pin: the mockup applies ANY PATCH
    body without validation (`IndicatorLED: "Bogus"` 204s AND persists) — the
    client must pre-validate against AllowableValues; the 400-with-
    `@Message.ExtendedInfo` validation-failure path stays unit-level.
    `RedfishClient.patchJson` is the DSP0266 §6.5.2 transport (204/200
    normalized; non-2xx → `RedfishException`) with 3 unit tests
    (`auth_manager_test.dart` "RedfishClient transports").
    **Discovery-graph pin (#018/#006, EMU 55):** Systems→Chassis→Manager
    `Links` traversal (DSP0266 §7.2.3 link traversal) resolves all three hops
    — `System.Links.Chassis`→`/Chassis/1U` + `ManagedBy`→`/Managers/BMC`,
    `Chassis.Links.ComputerSystems`→the system + `ManagedBy` +
    `ManagersInChassis`→the manager, `Manager.Links.ManagerForServers`→the
    system + `ManagerForChassis`/`ManagerInChassis`→the chassis; the Manager
    identity (ManagerType BMC / FirmwareVersion `1.45.455b66-rev4` / Model
    `Joo Janta 200`) is pinned for the overview's BMC card. The #018
    lightweight discovery pass can walk the graph from any seed without
    hardcoded URIs.
    **VirtualMedia read surface (EMU 56, boot-media UX input for #028/#022):**
    `/Systems/437XR1138R2/VirtualMedia` publishes 2 members
    (`#VirtualMediaCollection`); CD1 is `#VirtualMedia.v1_6_3.VirtualMedia`
    (ConnectedVia Applet, Image `redfish.dmtf.org/freeImages/freeOS.1.1.iso`,
    MediaTypes CD/DVD, Inserted, WriteProtected false) and Floppy1 (ConnectedVia
    URI, Image `https://www.dmtf.org/freeImages/Sardine.img`, MediaTypes
    Floppy/USBStick). Negative pin: the fixture publishes NO
    `#VirtualMedia.InsertMedia`/`EjectMedia` action targets (no Actions map) —
    boot-media action round-trips stay unit-level (advertised-as-candidate
    rule). VirtualMedia is NOT client-mapped, so the corpus-invariant family
    list is unchanged (no fixture-schema duty).
    **SecureBoot boot-integrity surface (pinned 2026-10-24, EMU 57→58; corpus
    mirror DOCS-25):** `/Systems/437XR1138R2/SecureBoot` publishes
    `#SecureBoot.v1_1_1.SecureBoot` (mirror:
    `redfish/schemas/v1/SecureBoot.v1_1_1.json`)
    with the secure-boot read state (SecureBootEnable false /
    SecureBootCurrentBoot Disabled / SecureBootMode UserMode) and the
    `#SecureBoot.ResetKeys` action + `ResetKeysType@Redfish.AllowableValues`
    (ResetAllKeysToDefault/DeleteAllKeys/DeletePK — the same annotation-form
    allow-list rule as `#ComputerSystem.Reset` (#022/#016): a security-posture
    UI pre-validates against the annotation, never hardcodes reset types; the
    action target POSTs 204 via the mockup's `/Actions/` framework, and a
    bogus `ResetKeysType` ALSO 204s (the mockup does not validate action
    bodies — the 400 path stays unit-level). Newest `SecureBoot.v1_2_1`
    (mirror: `redfish/schemas/v1/SecureBoot.v1_2_1.json`) adds only
    `SecureBootDesiredMode` — additive, no code change.
    **SecureBootDatabase collection (pinned 2026-10-24, EMU 58→59; corpus
    mirror DOCS-25):** the `SecureBootDatabaseCollection` (mirror:
    `redfish/schemas/v1/SecureBootDatabaseCollection.json`) enumerates 8
    databases (PK/KEK/db/dbx +
    their defaults) and each database resource
    (`#SecureBootDatabase.v1_0_2`, mirror:
    `redfish/schemas/v1/SecureBootDatabase.v1_0_2.json`)
    carries its OWN `#SecureBootDatabase.ResetKeys` action with a *smaller*
    per-resource allow-list (PK: ResetAllKeysToDefault/DeleteAllKeys — no
    DeletePK) plus a Certificates link — a key-reset UI must read the
    database-level list, never reuse the SecureBoot-level one (#022).
    Newest `SecureBootDatabase.v1_0_3` (mirror:
    `redfish/schemas/v1/SecureBootDatabase.v1_0_3.json`) is a property no-op.
    SecureBoot/SecureBootDatabase stay NOT client-mapped — external-corpus
    only (no fixture-schema duty; the corpus-invariant family list is
    unchanged).
    **If-Match boundary (#016, pinned 2026-10-24, EMU 59→60):** a PATCH sent
    with a stale `If-Match: "bogus-stale-etag"` header is ANSWERED 204 and
    persists into the served resource — the mockup never evaluates
    preconditions (no resource-level `@odata.etag`/HTTP ETag; the
    settings-object ETag `9234ac83b9700123cc32` from the Bios pin is the only
    concurrency token it serves). If-Match/412 enforcement therefore stays
    unit-level; the #016 client must send the settings-object ETag itself
    rather than rely on the service enforcing it.
    **Chassis Controls +#006/#019/#022 power-capping surface (pinned
    2026-10-24, EMU 60→63):** `/Chassis/1U/Controls` publishes the modern
    control surface — `#ControlCollection` → `#Control.v1_5_0.Control`
    PowerLimit (ControlType Power, SetPoint 500 W, AllowableMax 1000,
    AllowableMin 150, `Sensor` DataSourceUri → Sensors/TotalPower) + CPU1Freq
    (SettingMin/Max + Allowable ranges) — and the **second live PATCH pin**:
    PATCHing `SetPoint: 600` answers 204 AND persists (in-memory), while a
    bogus `SetPoint: 9999` is ALSO applied unvalidated — the #016/#022 client
    must pre-validate against AllowableMin/Max. **The pre-validation rule is
    now code (2026-10-25, EMULATOR run):** `ControlResource.validateSetPoint`
    rejects out-of-bounds SetPoints before any PATCH (+11 unit tests + 1 live
    emulator pin on the served PowerLimit/CPU1Freq ranges); Control became
    client-mapped — the served `Control.v1_5_0.json` is in the fixture and
    the family is in the corpus-invariant list (see "Last audited").
    **Bios/Settings PATCH round-trip (#016/#028, pinned 2026-10-24, EMU
    63→64):** PATCH `/Bios/Settings` (the `@Redfish.Settings` SettingsObject
    carrying the only ETag the mockup serves — `9234ac83b9700123cc32`) with
    an `Attributes` subset answers 204 AND persists; the mockup IGNORES the
    If-Match precondition on the settings object too (a stale etag still 204s
    + persists), so the #016/#028 client must send the settings-object ETag
    itself; restored in `finally`.
    **ThermalSubsystem Heaters + Manager.Reset (pinned 2026-10-25, EMU
    64→66):** `#HeaterCollection` → `#Heater.v1_0_1` CPU1Heater detail
    (PhysicalContext CPU, Manufacturer/Model/Serial, HotPluggable,
    LocationIndicatorActive, Status + `Links.Processors[0]` resolving to CPU1
    + Metrics link → `#HeaterMetrics.v1_0_1` PrePowerOn/RuntimeHeatingTime-
    Seconds + PowerWatts 200.3 + TemperatureReadingsCelsius) — the
    thermal-UI surface; the **advertised `#HeaterMetrics.ResetMetrics` target
    has NO `/Actions/` segment → POST 404 with an empty body** (the
    PowerSupply.Reset advertised-as-candidate rule); `#Manager.Reset` POST
    GracefulRestart → 204 (no task-monitor Location) AND a bogus `ResetType`
    also 204s — the #022/#016 client must pre-validate against the MANAGER's
    own allow-list (ForceRestart/GracefulRestart), never the system list.
    Heaters stay NOT client-mapped (corpus DOCS-28).
    **Generalized `$expand` pins (#018, pinned 2026-10-25, EMU 66→68):** the
    SAME map-form `$expand=.($levels=1)` on `/redfish/v1/Chassis` AND
    `/redfish/v1/Managers` also inlines FULL member bodies (Chassis
    identity/ChassisType/Status/IndicatorLED/Links, Manager ManagerType/
    FirmwareVersion/Model/Links + the manager-level reset allow-list
    `[ForceRestart, GracefulRestart]` through the expanded payload), and
    **`$levels=2` does NOT recurse** — the member's own `Links.Chassis` stays
    a bare `@odata.id` ref (DSP0266 §7.3.2 depth-cap pinned), so the #018
    discovery pass gets one full inlined hop per collection and must follow
    cross-resource URIs explicitly.
    **Two negative facts pinned (2026-10-25, EMU 69):** (1) **bad login
    still mints a session** — the mockup runs WITHOUT auth enforcement, so
    POST `Sessions` with a wrong password returns 204 + X-Auth-Token +
    Location; the client's 401 mapping is provably unit-level (#015/#026) and
    token presence proves nothing about credential validity on this fixture;
    (2) **`MultipartHttpPushUri` is absent** — the fixture serves only
    `HttpPushUri` (`/FWUpdate`) unlike bmcweb's multipart variant, so
    `UpdateServiceInfo.multipartHttpPushUri` is null and the #008/#020 upload
    flow must pick the single-push URI when that is all the service
    advertises.
    **ActionInfo resource contract (pinned 2026-10-25, EMU 69→71 then
    75→78):** the two `CertificateService` actions each advertise an
    `@Redfish.ActionInfo` link that resolves to a GET-able
    `#ActionInfo.v1_4_1.ActionInfo` resource — `GenerateCSRActionInfo` (13
    `Parameters[]` with Name/Required/DataType + AllowableValues on
    KeyPairAlgorithm/KeyCurveId/KeyUsage), `ReplaceCertificateActionInfo`
    (`CertificateType` AllowableValues `['PEM']`) — the exact
    `Parameters[].AllowableValues` shape a bmcweb `ResetActionInfo`-style
    crawl produces (#022/#016; DOCS-4/13). The EMU 75→78 run closed the
    remaining ActionInfo families on the fixture: `EventService.
    SubmitTestEventActionInfo` (9 `Parameters[]`, `MessageId` the one
    REQUIRED parameter, `EventType` AllowableValues
    [StatusChange/ResourceUpdated/ResourceAdded/ResourceRemoved/Alert/Other],
    `MessageArgs` StringArray, `EventGroupId` Number — the #019 test-event
    surface) and the `#Certificate.Rekey` `RekeyActionInfo` contract on all
    three certificate stores the `CertificateLocations` pin lists
    (`Managers/BMC/NetworkProtocol/HTTPS/Certificates/1`,
    `UpdateService/ClientCertificates/1`,
    `AccountService/OutboundConnections/1/Certificates/1` —
    `KeyPairAlgorithm` REQUIRED with AllowableValues TPM_ALG_RSA/TPM_ALG_ECDSA,
    `KeyBitLength` optional Number, `KeyCurveId` AllowableValues with the three
    NIST curves). `ResetActionInfo` itself is still absent on this fixture.
    **Last service-root branches (#015/#026/#022, pinned 2026-10-25, EMU
    71→75):** `CertificateService.CertificateLocations`
    (`#CertificateLocations.v1_0_3`) links the three certificate stores;
    `KeyService` (`#KeyService.v1_0_0`) — `NVMeoFKeyPolicies/0`
    (`#KeyPolicy.v1_0_0`) NVMeoF allow-lists (SecurityTransport/CipherSuite/
    SecurityProtocol/DHGroup/SecureHash) pinned read-only + `NVMeoFSecrets`
    (`#KeyCollection.KeyCollection`, 2 members) pinned **collection-metadata
    only** (member bodies carry real `KeyString` key material — the suite
    asserts the surface exists without fetching a member body, the #015/#026
    never-read-secrets-back rule as an explicit scope boundary);
    `ComponentIntegrity` collection (4 members) + `#ComponentIntegrity.
    v1_2_2` SPDM/TPM/USB shapes incl. the disabled USB member. All three
    families stay NOT client-mapped (no fixture schema duty).

## EMU-5 decision — richer emulator evaluation (2026-10-22)

**Decision: stay on Redfish-Mockup-Server; do not adopt
`DMTF/Redfish-Interface-Emulator` for error-path testing.** Recorded so the
rationale survives.

- **Evaluated:** `DMTF/Redfish-Interface-Emulator` @ `5f51d8a` (tag `1.2.2`),
  cloned to `/tmp`, venv install, run on port 8444 against its built-in
  dynamic mockup.
- **What it does:** serves a real dynamic Redfish service (ServiceRoot,
  Systems `System-1..7`, Chassis, Managers, TaskService); `POST
  /redfish/v1/Systems/System-1/Actions/ComputerSystem.Reset` executes
  `ResetType` and mutates `PowerState`; an invalid `ResetType` returns
  **400** (dynamic 4xx path the static mockup cannot produce).
- **Why we stay on the mockup server:**
  1. **Error bodies are non-conformant.** The emulator's 400 response is
     `{"error": "Invalid ResetType: Bogus"}` — no DSP0266 `error` envelope
     (`{"error":{"code","message","@Message.ExtendedInfo"}}`), no
     `@Message.ExtendedInfo`, and a `{"Status","Message"}` shape in
     `emulator.py:error_response` instead. Testing error *mapping* against it
     would encode the wrong contract (#014's fixtures must be spec-conformant).
  2. **SessionService is broken/mismatched.** `POST
     /redfish/v1/SessionService/Sessions` returns 404 and the resource
     self-describes as `#Session.0.94.0.SessionCollection` at a
     `/rest/v1/...` context — auth coverage would regress vs. the mockup
     server (which mints tokens and honours logout).
  3. **Overlap + risk.** The static mockup already covers discovery, sensors,
     firmware, KVM, power, and 404 mapping; the only gap is spec-conformant
     extended-info bodies, which are better exercised with unit fixtures
     (spec text pinned in DSP0266 §8.6 "Error responses") than with another
     HTTP layer.
- **Fallback for #014/#015 error paths:** `test/redfish/models/` +
  `test/redfish/client/` unit fixtures with compliant `{"error":{...}}`
  bodies; the emulator suite keeps asserting 404 mapping end-to-end.
- Pin recorded: `DMTF/Redfish-Interface-Emulator` `5f51d8a` (evaluated only;
  no committed harness).

## DOCS-7 decision — event subscriptions / SSE (2026-10-22)

**Decision: implement later, not this milestone.** Recorded here so the rationale
survives and the FUTUREWORK item stays actionable.

- **Spec basis:** DSP0266 §12.1.1–§12.1.5: services *shall* support push eventing
  for all event-capable resources, require an explicit subscription before
  pushing, and subscriptions persist across service restarts. §12.1.2 mandates
  201 + `Location` on subscription POST and DELETE-to-unsubscribe. §12.1.3
  (SSE via `EventService.ServerSentEventUri`) is a *may* for services.
- **Why out-of-scope now:**
  1. No consumer: the capability-gated UI has no event-driven surface; telemetry
     is poll-based (#007/#019) and firmware tasks are 202-accepted but not
     polled (#008/#020). Adding a subscriber with no receiver is dead code.
  2. No transport: `pubspec.yaml` has only `dio`; an SSE client (streaming GET or
     a package) would be a new dependency for a one-off effect — discouraged by
     the UI workstream rules until justified by a consumer.
  3. No verification target: the static mockup fixture cannot push events; an
     SSE/webhook test bed would need the richer emulator (EMU-5) or a live BMC
     (blocked, needs credentials).
- **What we promise instead:** telemetry (#007/#019), firmware task monitoring
  (#008/#020), and power task handling (#022) stay poll-based and are the
  natural place to *revisit* events once a receiver exists; revisit this decision
  when any of those land.

## bmcweb field notes (2026-10-22)

The bmcweb `EventService` implements a superset of the DMTF minimum:
`SubmitTestEvent`, `DeliveryRetryAttempts` (default 3),
`DeliveryRetryIntervalSeconds`, `EventFormatTypes`, `RegistryPrefixes`,
`ResourceTypes`, `SSEFilterPropertiesSupported`, `Subscriptions`
(`EventDestinationCollection` with `Destination` / `EventTypes` / `Context` /
`HeartbeatIntervalMinutes` / `OriginResources` / `Protocol`). Its `TaskService`
exposes `CompletedTaskOverWritePolicy`, `LifeCycleEventOnTaskStateChange`, and
`Tasks`. Any future subscription client should target the bmcweb field set
(audited in `openbmc/Redfish.md` §EventService / §TaskService, commit
`0128851e` → now `27e0930b`).

## DOCS-4 — bmcweb feature-detection diff audit (2026-10-22)

Audited OpenBMC bmcweb's `docs/Redfish.md` (field sets per resource),
`docs/REDFISH_CHECKLIST.md` (contributor process, no client-facing fields), and
`docs/OEM_SCHEMAS.md` (OEM policy) against the client's discovery rules
(`FeatureRules`). Results, cited rows in the table above:

1. **KVM OEM false-positive — fixed this run.** `FeatureRules._managerConsoleType`
   treated *any* `Oem` map as a console (`kvmType='Oem'`). bmcweb Managers
   always carry an `Oem` block for vendor metadata (Redfish.md Manager field
   list), so KVM would have reported available on every real OpenBMC system even
   with no console. The rule now only returns `Oem` when the block contains a
   console-like structure (`*console*` / `*kvm*` key, recursive, depth ≤ 3).
   Tests: `feature_rules_test.dart` (bare-Oem rejected, `Kvm`/`GraphicalConsole`
   markers accepted).
2. **bmcweb firmware update is HTTP-push, not `SimpleUpdate`.** Redfish.md
   §UpdateService lists `HttpPushUri`, `HttpPushUriOptions`, `MaxImageSizeBytes`,
   `MultipartHttpPushUri`, `ServiceEnabled`, `FirmwareInventory` — no
   `SimpleUpdate` action. `FirmwareService.startSimpleUpdate` targets
   `#UpdateService.SimpleUpdate` and would 405 on OpenBMC; #008/#020 must add the
   push path (`HttpPushUri` PUT or `MultipartHttpPushUri` multipart).
3. **bmcweb reset types via `ResetActionInfo`.** The ComputerSystem section
   documents a `ResetActionInfo` ActionInfo resource
   (`Parameters/AllowableValues`); there is no system-level
   `SupportedResetTypes` listed. The reader now falls back to the
   `ResetType@Redfish.AllowableValues` annotation on the
   `#ComputerSystem.Reset` action (the form the DMTF mockup + ActionInfo-style
   BMCs publish), so the true allow-list surfaces even when
   `SupportedResetTypes` is empty — fixed 2026-10-23 (run docs). Crawling the
   `ResetActionInfo` *resource* itself stays folded into #022/#016.
4. **Serial console placement.** bmcweb documents serial console on the
   *ComputerSystem* (`SerialConsole/SSH|IPMI`), not on the Manager. Manager-level
   `GraphicalConsole` detection (the primary KVM signal) remains correct; system
   serial console is not yet mapped (relevant to #009/#021).
5. **Auth + telemetry vendor surface.** `AccountService.Oem.OpenBMC.AuthMethods.*`
   (BasicAuth/Cookie/SessionToken/TLS/XToken) is the bmcweb auth negotiation
   surface (#015/#026); `TelemetryService` is an alternative sensor source
   (#007/#019). Both recorded as vendor rows.

## DOCS-5 — `SystemFeatures` flag → spec citation → test map (2026-10-22)

Every flag the discovery engine emits is traced to the authoritative source and
a test. This is the per-flag table FUTUREWORK DOCS-5 asked for; the flags are
defined in `lib/redfish/models/system_features.dart`, computed by
`lib/redfish/discovery/feature_rules.dart`, and asserted in
`test/redfish/discovery/feature_rules_test.dart` +
`test/redfish/discovery/discovery_engine_test.dart`.

| Flag | Meaning | Source | Rule | Test |
|---|---|---|---|---|
| `powerControl` | `Systems[*].Actions.#ComputerSystem.Reset` present | DSP0266 §9.6.14 "Actions property"; `ComputerSystem.json` (`Actions`) | `FeatureRules.powerControl` | `feature_rules_test.dart` "powerControl true/false" |
| `supportedResetTypes` | union of `SupportedResetTypes` across systems **+ the `ResetType@Redfish.AllowableValues` annotation on each `#ComputerSystem.Reset` action** | DSP0266 `ComputerSystem.json`; OpenBMC `Redfish.md` §ComputerSystem (bmcweb uses `ResetActionInfo` instead — DOCS-4, fixed 2026-10-23: annotation fallback lands the allow-list when `SupportedResetTypes` is absent; ActionInfo *resource* crawling stays #022/#016) | `FeatureRules.supportedResetTypes` / `FeatureRules.resetTypesFromAction` | `feature_rules_test.dart` "unions across systems and sorts" + "falls back to the ResetType@Redfish.AllowableValues annotation" + "unions + dedupes" + "never reads the manager-level allow-list" |
| `kvm` | any Manager exposes enabled console (`GraphicalConsole` / `SerialConsole` / strict OEM console) | DSP0266 `Manager.json` + `Manager.v1_25_0.json`; OpenBMC `Redfish.md` §Manager + OEM_SCHEMAS (DOCS-4: bare `Oem` is vendor metadata, not a console) | `FeatureRules.kvm` / `_managerConsoleType` | `feature_rules_test.dart` "detects GraphicalConsole", "ignores bare Oem", "Oem Kvm marker" |
| `kvmType` | first detected console kind (`GraphicalConsole`/`SerialConsole`/`Oem`) | same as `kvm` | `FeatureRules.kvmType` | same tests |
| `sensorMonitoring` | any `Chassis[*].(Thermal \|\| Sensors \|\| Power)` link | DSP0266 §9.1 "Resources" (link traversal) + §9.5.7 "Reference properties" + §9.6.13 "Links"; `Chassis.json` | `FeatureRules.sensorMonitoring` | `feature_rules_test.dart` "sensorMonitoring true via Thermal link" |
| `sensorCount` | temps + fans + voltages + sensor members | DSP0266 `Thermal.json` (`Thermal.v1_7_3.json`) / `Sensor.json` | `FeatureRules.sensorCount` | `feature_rules_test.dart` "sums temperatures + fans + voltages + sensor members" |
| `firmwareUpdate` | `UpdateService` present **and not explicitly disabled** | DSP0266 `UpdateService.json` (`UpdateService.v1_17_1.json`) `ServiceEnabled` ("This property shall indicate whether this service is enabled"); OpenBMC `Redfish.md` §UpdateService lists `ServiceEnabled` | `FeatureRules.firmwareUpdate` (honors `ServiceEnabled` — **fixed this run**) | `feature_rules_test.dart` "firmware_update presence…" + "firmwareUpdate honors ServiceEnabled (DOCS-5)"; `discovery_engine_test.dart` happy path |
| `updateServiceVersion` | `Version` → `Id` fallback (vendor `FirmwareVersion` in OpenBMC fixture) | DMTF `UpdateService.v1_13_0.json` — **no** `FirmwareVersion` property (vendor field in the OpenBMC fixture only); `Id` is the conformant fallback | `FeatureRules.updateServiceVersion` | `feature_rules_test.dart` "version preference"; `discovery_engine_test.dart` expects `2.14.0` from the OpenBMC fixture |
| `managers` | count of discovered `Manager` resources | DSP0266 §7.2.3 "Service root request" (`Managers` link) | `DiscoveryEngine._crawl` (classify) | `discovery_engine_test.dart` "discovers the full capability map" (`managers == 1`) |
| `chassis` | count of discovered `Chassis` resources | DSP0266 §7.2.3 "Service root request" (`Chassis` link) | `DiscoveryEngine._crawl` (classify) | `discovery_engine_test.dart` ("`chassis == 1`") |

Findings folded into code this run:

1. **`firmwareUpdate` now honors `ServiceEnabled`.** `FeatureRules.firmwareUpdate`
   treated any `UpdateService` resource as capability. The DMTF schema declares
   `ServiceEnabled` "shall indicate whether this service is enabled" and bmcweb
   advertises it on UpdateService (`Redfish.md` §UpdateService), so an explicitly
   disabled service must not surface the Firmware tab or the overview "Firmware
   update" chip. Missing/`null` stays enabled (conformant services may omit it).
   Tests: `feature_rules_test.dart` "firmwareUpdate honors ServiceEnabled
   (DOCS-5)".
2. **`updateServiceVersion` fallback is conformant.** The DMTF `UpdateService`
   schema has no `FirmwareVersion` property — that value in the OpenBMC fixture
   is vendor-only. The model's `Version` → `Id` fallback is correct; no change.

UI-3 increment this run: FirmwareView responsive-layout tests at 320/800/1300 px
(`firmware_widget_test.dart`, same `pumpAtWidth` pattern as PowerView /
SensorsView); no production layout change (view already wraps — regression
protection added).

## DOCS-2 — versioned-schema refresh audit (2026-10-22)

DMTF schema index (`https://redfish.dmtf.org/schemas/v1/`, fetched 2026-10-22
21:45 UTC) showed six versioned definition files advanced upstream since the
2026-10-21 mirror snapshot. Refreshed them in `test/fixtures/redfish/schemas/`
and `documentations/external/redfish/schemas/v1/` (provenance + hashes in
`documentations/external/README.md` "DOCS-2 refresh").

| Schema (new) | Old fixture | Client impact | Trace |
|---|---|---|---|
| `ComputerSystem.v1_29_0` | v1_28_0 | `ProductionDate` + new graphical-console actions `GraphicalConsoleGetOneTimeURL`/`SetOneTimePassword`/`SetPassword` + `ConsoleAccessMode` enum. Client reads neither; KVM detection uses Manager `GraphicalConsole` (unchanged). No code change. | `lib/redfish/discovery/feature_rules.dart` (`kvm` via Manager console); REQ row "kvm" |
| `Chassis.v1_29_0` | v1_28_0 | `ProductionDate`; ChassisType `OpenRack`/`OpenRackWide` added, `OpenU` deprecated. Client maps ChassisType as free string. No code change. | `lib/redfish/...` chassis parse (free-string) |
| `Sensor.v1_14_0` | v1_13_0 | ReadingType `Turbidity`/`LiquidConductivity`/`pH`; `Oem` on Sensor. Client stores `ReadingType` as string and renders units generically. No code change. | `lib/features/sensors/models/sensor_models.dart` (`readingType`, `ReadingUnits` generic) |
| `AccountService.v1_19_0` | v1_18_1 | New read-only `KerberosKeytabSet`/`PasswordSet`/`TokenSet`; LDAP STARTTLS note. #015 AuthManager doesn't parse these (basic-session flow). No code change. | `lib/redfish/...auth*`; REQ "bmcweb AuthMethods" vendor row |
| `EthernetInterface.v1_12_6` | v1_12_5 | SLAAC wording clarified (IPv4 link-local). Client exposes ethernet info read-only. No code change. | `lib/features/...ethernet*` |
| `SoftwareInventory.v1_15_0` | v1_14_0 | New `ImageState` enum + `ActiveTargets`/`StagedTargets`/`ArmedTargets` links — relevant when #008/#020 firmware task timeline lands. No code change. | `lib/features/firmware/...`; REQ "firmware inventory" row |

Superseded versioned files are retained for history (mirror manifest notes
this). No test fixture references the old versioned filenames, so the refresh
is purely additive; full `flutter test` stays green. Remaining DOCS-2 scope:
the 2026-10-21 `dmtf_mockup` payload snapshot itself still matches upstream
(mockup server pinned `23d21f9a`, unchanged), so no mockup refresh was needed
this run.

## DOCS-8 — upstream-freshness audit (2026-10-22)

Full re-verification of every mirrored upstream anchor against live sources
(schema index, DSP0266, bmcweb, mockup server). Used to decide whether any
mirror file or fixture needs a refresh; provenance + hashes in
`documentations/external/README.md` "DOCS-8 upstream-freshness audit".

1. **All 13 schema families current.** Live scan of
   `https://redfish.dmtf.org/schemas/v1/` (14,259 entries, 3.4 MB listing)
   compared against `test/fixtures/redfish/schemas/` +
   `documentations/external/redfish/schemas/v1/`: AccountService 1_19_0,
   Chassis 1_29_0, ComputerSystem 1_29_0, EthernetInterface 1_12_6,
   EventService 1_12_0, LogService 1_9_0, Manager 1_25_0, Power 1_7_3,
   Sensor 1_14_0, SessionService 1_2_0, SoftwareInventory 1_15_0,
   Thermal 1_7_3, UpdateService 1_17_1 — **no version advanced** since the
   DOCS-2 refresh. No fixture change.
2. **DSP0266 still 1.25.0.** The hub-linked PDF fetches 200 with identical
   content-length (1,243,359 bytes); a probe for `DSP0266_1.26.0.pdf` returns
   404. No spec refresh.
3. **Mockup server pinned at HEAD.** `DMTF/Redfish-Mockup-Server` master is
   still `23d21f9a` — the pinned commit. No mockup fixture change.
4. **bmcweb master moved `0128851e` → `27e0930b`** (3 commits: `http/parsing`,
   `redfish-core/lib/update_service.hpp` [+tests], `time_utils`). No `docs/`
   files changed between the two SHAs; the three mirrored docs are
   byte-identical (same SHA-256s). Pin updated in the manifest + this header.
   The `update_service.hpp` change is noted as upstream context for #008/#020
   (firmware update service internals) — no client-facing contract delta.
5. **`docs/CLIENTS.md` mirrored (new).** Official bmcweb client-compatibility
   doc: lists the DMTF Redfish-Service-Validator / Protocol-Validator,
   python-redfish-library, Redfish-Tacklebox, redfishtool, fwupd, and
   Redfish-Event-Listener. Client-facing value: pins which reference tools the
   service must interop with (a future test bed can reuse
   Redfish-Service-Validator against our emulator harness). 2,695 bytes —
   within DOCS-6 budget.
6. **Not mirrored (decision):** `docs/COMMON_ERRORS.md` (bmcweb C++ pointer /
   string-view traps for contributors) and `docs/HEADERS.md` (build-time header
   architecture) are internal contributor docs with no client-facing Redfish
   contract. Skipping avoids junk in the corpus; recorded so the next audit
   does not re-evaluate them.

## DOCS-14 — OData base vocabulary mirror + anchor re-verification (2026-10-23)

Closed the last un-mirrored REQUIREMENTS.md source citation and re-verified
every corpus anchor:

1. **`odata.4.0.0.json` mirrored (new).** Row 65 (`@odata.id` link traversal)
   cited `Odata.json` but the external corpus had no OData schema. The bare
   `Odata.json` 404s on the DMTF schema index (verified live); the canonical
   file is the lowercase `odata.4.0.0.json` (OData 4.0.0 base vocabulary:
   `context`/`id`/`idRef`). Fetched 2026-10-23 16:40 UTC, 1,834 bytes, SHA-256
   `c73cce029ca4cc01a54d341389742f60a4f48e05691ee81934ca9ba513dc6b7c` — **byte-
   identical to `test/fixtures/redfish/schemas/Odata.json`**, which proves the
   fixture copy is current. Manifest row added; row 65 citation updated.
   Within the DOCS-6 budget.
2. **bmcweb master advanced `27e0930b` → `fbb307a`.** Re-fetched all four
   mirrored docs at the new HEAD (`Redfish.md`, `REDFISH_CHECKLIST.md`,
   `OEM_SCHEMAS.md`, `CLIENTS.md`): **byte-identical** (same SHA-256s) — no
   corpus refresh needed, manifest anchors updated to `fbb307a`.
3. **`DMTF/Redfish-Mockup-Server` still `23d21f9a`** (default branch `main`;
   the `master` ref 422s — corrected the API call, pin unchanged).
4. **DMTF schema index 200 OK**; hub still links `DSP0266_1.25.0.pdf`
   (1.26.0 → 404) — no spec refresh.
5. No client code change this run — corpus-only audit + provenance.

## DOCS-15 — DSP0266 §7.3 "Query parameters" audit (2026-10-23)

Audited DSP0266 1.25.0 §7.3.1–§7.3.5 (query-parameter clauses) against the
client's HTTP transport and the emulator-pinned query contract (#018). This is
the normative basis for the #018 lightweight discovery pass (`$expand`
collection fetch) and for how the client must treat `$filter`/`$select` on the
pinned mockup.

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Query parameters apply only to **GET** operations; service shall process them in order `$filter` → `$skip` → `$top` → server-side pagination → `$expand` → `excerpt` → `$select` | DSP0266 §7.3.1 "Query parameter overview" | `RedfishClient.getJson` accepts `query` (Dio `queryParameters`) — GET only; no feature passes a query today | (new, this run) `redfish_client_extra_test.dart` pins `getJson` forwards `query` to the wire | OK — transport ready for #018 |
| Service **shall** advertise query support via `ProtocolFeaturesSupported` in the service root; service **may** support `$expand`/`$filter`/`$select`, **should** support `$top`/`$skip`/`only`/`excerpt` | DSP0266 §7.3.1; `ServiceRoot.v1_22_0.json` `ProtocolFeaturesSupported` (mirrored DOCS-13) | `FeatureRules` reads the service root (discovery crawl) but does not yet gate query usage on the advertised flags | emulator service-root group asserts `ProtocolFeaturesSupported` publishes `ExpandQuery{ExpandAll,Levels}` + `FilterQuery`/`SelectQuery` | GAP: #018 must gate its `$expand` usage on `ExpandQuery` (Levels/ExpandAll) and assume NO `$filter`/`$select` application |
| Service shall return **501 Not Implemented** for unsupported `$`-prefixed query parameters, with an extended error naming the unsupported parameter; **400 Bad Request** for invalid values; **400 QueryNotSupportedOnResource** for implemented-but-unsupported-on-resource params | DSP0266 §7.3.1; `Base` Message Registry `QueryNotSupportedOnResource` / `QueryNotSupported` | `RedfishException.fromDioException` normalizes 400/501 into typed errors; **501 (Not Implemented) is now classified NON-retryable** — a permanent capability signal, so the client gates the query instead of retrying it | `auth_manager_test.dart` (RedfishException normalization: `501 Not Implemented … is non-retryable` + `400 QueryNotSupportedOnResource …` fixtures, +2, 2026-10-25); existing envelope tests in `models_test.dart` | OK — query-501 fixture landed; #018 still must *use* the classification (gate `$expand` on `ProtocolFeaturesSupported`, never retry a 501) |
| `$expand` options: `*` (all hyperlinks incl. payload annotations), `$levels` (default 1), `.` (all but `links` properties), `~` (only `links` properties); when `$levels` advertised, `MaxLevels` caps the depth; combine with `$select` using full property path | DSP0266 §7.3.2 "The $expand query parameter"; `ServiceRoot.v1_22_0.json` `Expand` definition | none (client does not send `$expand` today) | emulator pins: `$expand=.($levels=1)` **and** `$expand=*` both inline full member bodies (17:07 + 18:36 runs); **generalized 2026-10-25 (EMU 66→68)**: the same map-form `$levels=1` on **Chassis + Managers** also inlines full member bodies — Chassis identity/ChassisType/Status/IndicatorLED/Links.ComputerSystems/ManagedBy and Manager ManagerType/FirmwareVersion/Model/Links.ManagerForServers/ManagerInChassis + the **manager-level reset allow-list (`#Manager.Reset` `ResetType@Redfish.AllowableValues` == exactly `[ForceRestart, GracefulRestart]`) visible through the expanded payload** (the #022/#016 conflation guard — the gate never reuses the manager list for the system gate — now pinned on the inlined shape) | OK pinned on the mockup; #018 may use either form (`*` or `$levels=1`) for collection fetch on all three top-level collections |
| `$levels=N` depth cap: `$levels` is transitive up to the advertised `MaxLevels`; the service determines the actual depth from the first `$levels` occurrence in the `$expand` query | DSP0266 §7.3.2 "The $expand query parameter" | none (client does not send `$expand` today) | **depth-bound pinned live 2026-10-25 (EMU 66→68)**: `$levels=2` on Systems does **NOT** recurse beyond one level — the member's own `Links.Chassis` stays a bare `@odata.id` ref (no inlined ChassisType/Status) — so the #018 discovery pass gets exactly one full inlined hop per collection and must follow cross-resource URIs explicitly for deeper hops | OK — depth-cap behaviour pinned; #018 discovery design input (fetch one full hop per collection, walk the graph via bare `@odata.id` refs) |
| Service shall not expand referenced resources the client lacks privileges for (no request failure); **507 Insufficient Storage** when the expanded payload exceeds service limits; partial collection expansion → 200 + `@odata.id` for unexpandable members + extended info | DSP0266 §7.3.2 | none | — | Note for #018 (payload-growth guard + 507 mapping) |
| `$select`: returns a subset of properties per the comma-separated expression; `/` separates nested property paths; array indices not allowed; response keeps `@odata.id`/`@odata.type` (and `@odata.context`/`@odata.etag` when supported) with the same values as an unselected response; unsupported requested properties are omitted | DSP0266 §7.3.3 "The $select query parameter" | none (client sends no `$select`) | emulator pins `$select=Model` is **advertised but NOT applied** by the mockup (full body returned, 18:36) | GAP: #018 must do projection client-side — never rely on server-side `$select` |
| `$filter`: subset of collection members per built-in operators `() and or not eq ne ge gt le lt` with fixed operator precedence; strings in single quotes | DSP0266 §7.3.4 "The $filter query parameter" | none (client sends no `$filter`) | emulator pins `$filter=Id eq 'NOPE'` returns **all** members (advertised but NOT applied, 18:36) | GAP: #018 must filter client-side — never rely on server-side `$filter` |
| `clientcontext`: stateless incremental retrieval of collection entries (currently defined for `LogEntryCollection`); service **shall never silently ignore** it (responds `@Redfish.ClientContextStatus`); unknown key = first-use; NotFound for evicted keys | DSP0266 §7.3.5 "The clientcontext query parameter"; `ServiceRoot.v1_22_0.json` `ClientContextQuery` | not used (no log reader) | emulator log-service group pins `@odata.nextLink` (`$skiptoken`) pagination — different mechanism | Note for future log reader; not #018 |

**Bottom line for #018** (folded into FUTUREWORK): the pinned mockup advertises
`$filter`/`$select`/`$expand` but **applies only `$expand`**. The #018
lightweight discovery pass must (a) gate `$expand` usage on the advertised
`ExpandQuery.Levels`/`ExpandAll`, (b) do all filtering/projection client-side,
and (c) map `501`/`507` from query requests. `RedfishClient.getJson` already
supports a `query` map — the transport contract is now pinned by unit test
(added this run). No production code change this run.
**Updated 2026-10-25 (EMU 66→68)**: the `$expand=.($levels=1)` shape is pinned
on **all three** top-level collections the #018 pass walks (Systems + Chassis +
Managers, full member bodies inlined via the map-form `getJson(path, query:)`),
and the **`$levels=2` depth bound is pinned** — the mockup does NOT recurse, so
nested `Links` stay bare `@odata.id` refs and the pass must follow
cross-resource URIs explicitly for deeper hops (DSP0266 §7.3.2 depth-cap
behaviour). The manager-level reset allow-list is visible through the expanded
Manager payload, closing the #022/#016 conflation guard on the inlined shape.

## DOCS-16 — DSP0266 1.25.0 citation audit + §9.9 payload-annotation pin (2026-10-24)

The requirement rows above (added across DOCS-3/4/5/10/13) cited DSP0266 clause
numbers from an **older spec layout** that does not match the mirrored
`DSP0266_1.25.0.pdf` (the version actually mirrored under `redfish/spec/`).
Verified against the PDF TOC + body text and corrected this run:

| Stale citation (old layout) | Correct clause in DSP0266 1.25.0 | Reason |
|---|---|---|
| §8.3 "Service Root" | §7.2.3 "Service root request" | service root request clause lives in "Service requests" chapter; §8 is "Service responses" |
| §8.4 ComputerSystem / §8.10 Thermal / §8.14 "Software inventory" | no such clauses — property contracts live in the versioned **schemas** (`ComputerSystem.v1_29_0.json`, `Thermal.v1_7_3.json`, `SoftwareInventory.json`) + §9 "Data model" (§9.1 Resources, §9.6 Properties) | DSP0266 does not enumerate per-resource property lists; the schemas are the normative source |
| §9.2 "HTTP and the Redfish protocol" (ETag) | §6.5 "ETags" + §7.2 "GET (read requests)" | ETag/If-None-Match/304 contract is §6.5; HTTP method semantics are §7 |
| §12.2 "Actions" | §9.6.14 "Actions property" + §7.11 "POST (action)" | action-representation contract is a data-model clause |
| §12.3 "Basic authentication" | §13.3.3 "HTTP Basic authentication" | auth is a Security-details clause |
| §12.4 "Sessions" / "Session timeout" | §13.3.4 "Redfish session login authentication" (§13.3.4.3 "Session lifetime") | session auth + lifetime is a Security-details clause |
| §12.7 "Error responses" | §8.6 "Error responses" | error envelope is a Service-responses clause |
| §9.7 "Firmware update" | §12.7 "Update service" (§12.7.2.1 "Simple updates") | update-service clause is in "Service details" |

Clauses that were already correct and stay unchanged: §12.1 "Eventing"
(§12.1.1–12.1.5), §12.2 "Asynchronous operations" (task monitors), §7.3
"Query parameters" (§7.3.1–7.3.5, DOCS-15), §9.6.11/§9.6.12 Members +
`@odata.nextLink`, §9.6.2 `@odata.id`, §9.1 Resources.

Payload-annotation contract now pinned (code was already implementing it; the
tests make the spec link explicit):

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| `@Redfish.AllowableValues` on an action parameter is a JSON array of strings defining the allowable values for that parameter (e.g. `ResetType@Redfish.AllowableValues` on `#ComputerSystem.Reset`) | DSP0266 §9.9.2 "Allowable values for strings"; annotation name format `<PropertyName>@<Namespace>.<TermName>` per §9.9.1, namespace `Redfish` = `RedfishExtensions.v1_0_0` | `FeatureRules.resetTypesFromAction` parses the annotation list | `feature_rules_test.dart` "reads the @Redfish.AllowableValues annotation per DSP0266 §9.9.2 (DOCS-16)" | OK |
| Clients shall not fail reading a resource due to unrecognized annotations (incl. new Redfish-namespace terms); a non-array allow-list value is ignored | DSP0266 §9.9.1 "Payload annotations overview" | `FeatureRules.resetTypesFromAction` returns empty for non-list / unrelated annotations | `feature_rules_test.dart` "ignores unrecognized annotations (DSP0266 §9.9.1 tolerance, DOCS-16)" | OK |

Anchors re-verified this run (2026-10-24): bmcweb master `fbb307a` (unchanged),
Redfish-Mockup-Server `23d21f9a` (unchanged), DSP0266 1.25.0 PDF
(www.dmtf.org URL; content-length 1,243,359 bytes — unchanged; the
`redfish.dmtf.org` path 404s and the hub links the `www.dmtf.org` URL), schema
index 200 OK. No corpus refresh needed.

## DOCS-17 — DSP0266 §13.3.4.3 session-lifetime audit + expiry pin (2026-10-24)

Audited the session-lifetime contract against the mirrored
`SessionService.json` + `SessionService.v1_2_0.json` (DOCS-12 mirrored the
newest + mockup-served versions) and DSP0266 §13.3.4.3 "Session lifetime".
Found that the client's `Session.expiresAt` / `isExpired` machinery existed
but **nothing ever populated the deadline** — the trace row above claimed
"OK" while `AuthManager` never reads the SessionService resource. This run
closed the model-level gap with a small, safe, tested helper (the AuthManager
fetch + wiring stays #015):

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Session expiry derives from `SessionService.SessionTimeout` (seconds of *inactivity* before the service closes the session; schema range 30–86400) | DSP0266 §13.3.4.3; `SessionService.json` (`SessionTimeout`) | `Session.expiryFromService` — `createdAt + SessionTimeout` | `models_test.dart` "expiryFromService uses SessionTimeout only" + "ignores a disabled AbsoluteSessionTimeout" | OK (model-level; AuthManager wiring #015) |
| v1_2_0 adds `AbsoluteSessionTimeout` — maximum seconds a session stays open *regardless of activity* — applied only when `AbsoluteSessionTimeoutEnabled` is `true`; the effective deadline is the earlier of the two so the client re-authenticates before the service can kill the session | `SessionService.v1_2_0.json` (`AbsoluteSessionTimeout`, `AbsoluteSessionTimeoutEnabled`, versionAdded v1_2_0); DSP0266 §13.3.4.3 | `Session.expiryFromService` takes `min(SessionTimeout, AbsoluteSessionTimeout)` when enabled; absolute-only services still get a deadline; malformed values are ignored | `models_test.dart` "takes the earlier of SessionTimeout and an enabled AbsoluteSessionTimeout" + "handles an absolute-only service" + "tolerates malformed timeout values" | OK (model-level; note for #015 — `AbsoluteSessionTimeoutEnabled` defaults absent/false) |
| No usable SessionService body → no known TTL (`expiresAt` null, session treated long-lived until a 401) | DSP0266 §13.3.4.3 (timeout is optional); `Session.json` | `Session.expiryFromService` returns `null` | `models_test.dart` "returns null without a SessionService body" | OK |

Notes for #015 (the open P1): the helper gives the deadline computation, but
`AuthManager` still needs (a) a discovered SessionService fetch during login
(or reuse of `DiscoveryContext.sessionService`), (b) `AbsoluteSessionTimeout*
` handling only when the service publishes it (mockup serves `v1_1_8` which
lacks the fields — `SessionTimeout=30` is the pinned emulator value), and
(c) a re-auth trigger when `Session.isExpired` flips.

UI-2 increment this run: the **FirmwareView error state** (errorContainer card
with icon + message) now announces as ONE merged semantics node
(`Semantics(container: true, excludeSemantics: true, label: 'Unable to load
firmware. <message>')` — the established OverviewView/SensorsView error-state
pattern), with the Retry button keeping its own control node. One new widget
test in `firmware_widget_test.dart` asserts the merged label + visible message
text + separately-announced Retry control.

## DOCS-18 — MessageRegistry payload mirror + Base registry delta audit (2026-10-24)

Closed the last corpus gap the emulator pins but the mirror lacked: the
**message-registry payload** behind the `MessageRegistryFile.Location[0].Uri`
the EMU-2 MessageRegistry contract resolves (service root `Registries` →
`MessageRegistryFileCollection` → `Base.1.5.0` → `#MessageRegistry` JSON).
Registry payloads live on the DMTF registries path
(`https://redfish.dmtf.org/registries/` — the `redfish/schemas/v1/` index
carries only the `MessageRegistry.json` aggregator + schemas).

| Requirement | Source (section/URL) | Code | Test | Status |
|---|---|---|---|---|
| Error responses carry `error.code` (a `Base.*` MessageId) + human `error.message`; `@Message.ExtendedInfo[].MessageId` references a published MessageRegistry entry | DSP0266 §8.6 "Error responses"; `registries/Base.1.5.0.json` (mirrored DOCS-18; byte-identical to the pinned mockup's payload — SHA-256 `c1026341…`) | `lib/redfish/models/redfish_error.dart` (`fromJson` envelope self-descend #014, code/message normalization) | `test/redfish/models/models_test.dart`; emulator MessageRegistry group pins the discovery + `Base.*` template surface (GeneralError Severity Critical / NumberOfArgs 0; ActionNotSupported NumberOfArgs 1) | OK |
| Message registries are versioned resources published per `RegistryPrefix` (the `Base` registry's messages are the standard template set) | DSP0266 §11.4 "Message registries"; `registries/Base.1.24.0.json` (newest published, mirrored DOCS-18) | n/a — model reads templates only for reasoning/tests | emulator: `#MessageRegistry.v1_0_0.MessageRegistry` shape (Id `Base.1.5.0`, RegistryVersion 1.5.0, OwningEntity DMTF, `Messages` map) | OK (contract pin only) |
| The mockup-served registry payload is authentic upstream (not fixture-generated) | DMTF registries index 200; `curl -sSIL` HEAD on `Base.1.5.0.json` | — | byte-compare: `sha256sum` upstream download == fixture (`c10263417a076402a992f099db4e019c9d91f674d256df32a390b86a2c46492c`, 31,984 bytes) | OK (provenance) |

**Newest-vs-served delta audit (`Base.1.5.0` → `Base.1.24.0`):**

- Template count **60 → 125** (+65 additions — e.g. `AccessForbidden`,
  `ActionParameterValueNotInList`, `HeaderInvalid`, `InvalidJSON`,
  `PreconditionFailed`, `PropertyValueNotInList` grew typo/format variants,
  `ResourceExhaustion`; nothing removed).
- **39 shared keys reworded** (e.g. `ActionNotSupported` "The action %1 is not
  supported by the resource." → "The action '%1' is not supported by the
  resource."; `GeneralError` gained an `@Message.ExtendedInfo` pointer) — but
  **`NumberOfArgs` is stable for every shared key (0 changed)**, so the
  argument-count contract the emulator pins (`GeneralError` 0,
  `ActionNotSupported` 1) holds across the newest registry too.
- `@odata.type` advanced `#MessageRegistry.v1_0_0` → `#MessageRegistry.v1_9_0`.
- **Client impact: none.** `RedfishError` treats `code`/`message` opaquely
  (the message resolver / error-reasoning surface is a future feature). The
  `1.5.0` mirror stays authoritative for the mockup-served surface; `1.24.0`
  is the "newest" provenance + a future `MessageId` resolver would read it.
- Anchors re-verified this run: registries path 200; `Base.1.5.0.json` and
  `Base.1.24.0.json` both 200. bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266
  1.25.0, schema index 200 — all unchanged. New bytes this run: 170,279
  (31,984 + 138,295) — inside the DOCS-6 budget.

UI-2 increment this run: the **Dashboard `_ErrorSummary` card** ("N systems
could not be reached") now announces as ONE merged semantics node
(`Semantics(container: true, excludeSemantics: true, label: 'Unable to reach
N systems. Retry available.')` — the established error-state pattern; the
visible text stays for sighted users and the Retry button keeps its own control
node). New dashboard widget tests assert the merged label + separately-
announced Retry control + Retry still reconnects failed systems (UI-1
behaviour unchanged).

## DOCS-19 — served-version corpus mirror for the DOCS-2 families + registry family (2026-10-24)

Closed the "served-version" gap for the eight client-mapped families that
DOCS-2 (2026-10-22) refreshed to their **newest** versioned definitions only:
the pinned `23d21f9a` mockup *serves* older `@odata.type` versions, and the
DOCS-11/12/13 precedent says every `@odata.type` the mockup publishes must
have a versioned schema in the fixture + mirror. Mirrored, per family, the
mockup-served version (and for `MessageRegistry` also the newest
`v1_9_0` — the `@odata.type` behind the newest `Base.1.24.0` registry payload,
DOCS-18) into `documentations/external/redfish/schemas/v1/` **and**
`test/fixtures/redfish/schemas/`.

| Family | Newest (already mirrored) | Mockup-served (this run) | Served-payload evidence | Client impact |
|---|---|---|---|---|
| `Sensor` | `v1_14_0` | **`v1_8_1`** | 42/42 sensors in the fixture publish `#Sensor.v1_8_1.Sensor` | none — every client-read field (`Reading`, `ReadingType`, `ReadingUnits`, `Thresholds`, `Status`, `PhysicalContext`, ranges) exists in `v1_8_1`; the DOCS-2 delta list still holds newest-side only |
| `ComputerSystem` | `v1_29_0` | **`v1_22_0`** | systems publish `#ComputerSystem.v1_22_0.ComputerSystem` | none — identity/PowerState/Status/Processor-MemorySummary/IndicatorLED/Boot/Links all present in `v1_22_0` (69-property main def) |
| `Chassis` | `v1_29_0` | **`v1_25_0`** | chassis publish `#Chassis.v1_25_0.Chassis` | none — ChassisType/PowerState/Status/Thermal/Power/Links present; `v1_29_0`-added `RackUnits`/`ProductionDate`/`LeakDetectors` etc. are newest-side only (client reads none) |
| `AccountService` | `v1_19_0` | **`v1_15_0`** | AccountService publishes `#AccountService.v1_15_0.AccountService` (the lockout surface the auth emulator pins — `AccountLockoutThreshold` 5 / `AccountLockoutDuration` 30 / `AccountLockoutCounterResetAfter` 30 / `MinPasswordLength` 8) | none — all #015-relevant fields present in `v1_15_0`; `v1_19_0` adds `EnforcePasswordHistoryCount`/`PasswordGuidance*` (newest-side only) |
| `SoftwareInventory` | `v1_15_0` | **`v1_10_1`** | firmware inventory publishes `#SoftwareInventory.v1_10_1.SoftwareInventory` | none — Name/Version/Status/Updateable/SoftwareId/Manufacturer/RelatedItem present; `v1_15_0`-added `ImageState`/`ActiveTargets`/etc. stay newest-side notes for #008/#020 |
| `LogService` | `v1_9_0` | **`v1_6_0`** | log-service payloads publish `#LogService.v1_6_0.LogService` | none — ServiceEnabled/OverWritePolicy/Entries/Actions/DateTime/MaxNumberOfRecords present; `ClearLog` is an action (present via `Actions`) |
| `EthernetInterface` | `v1_12_6` | **`v1_12_0`** | NIC payloads publish `#EthernetInterface.v1_12_0.EthernetInterface` | none — MAC/IPv4/IPv6/VLAN/LinkStatus/Status/InterfaceEnabled/Links present |
| `MessageRegistry` | `v1_9_0` (this run, newest) | **`v1_0_0`** | the served `Base.1.5.0` registry payload publishes `@odata.type` `#MessageRegistry.v1_0_0.MessageRegistry` (DOCS-18) | none — RegistryPrefix/Version/OwningEntity/Messages/Language present; `v1_9_0` adds `ClearsAll`/`ClearsIf`/`ClearsMessage` (newest-side only) |

Trace rows updated to cite the served files where the fixture is the contract
source: sensor row → `Sensor.v1_8_1.json` (+ newest `Sensor.v1_14_0.json`),
overview row → `ComputerSystem.v1_22_0.json` (+ `v1_29_0`), firmware row →
`SoftwareInventory.v1_10_1.json` (+ `v1_15_0`), log row → `LogService.v1_6_0`
(+ `v1_9_0`), auth/session rows unchanged (DOCS-13 files already served-version
correct), `MessageRegistry` row → `MessageRegistry.v1_0_0.json` +
`MessageRegistry.v1_9_0.json`.

All upstream anchors re-verified (2026-10-24): bmcweb `fbb307a` (HEAD —
unchanged), mockup pin `23d21f9a` (unchanged), DSP0266 1.25.0 (unchanged),
schema index 200, registries path 200; each of the 9 mirrored files fetched
200 from `https://redfish.dmtf.org/schemas/v1/`. New bytes this run: 560,665
total (102,125+145,755+75,981+89,936+22,621+33,248+52,887+10,151+27,961) —
inside the DOCS-6 budget.

## DOCS-20 — chassis-metrics / subsystem corpus mirror (2026-10-24)

Closed the corpus gap the EMU-2 chassis-contracts pins (2026-10-24, EMU 45→48)
exposed: the newly pinned aggregate-telemetry families had **no versioned
schema** in the fixture/mirror. Mirrored 11 files (160,101 bytes total, inside
DOCS-6) into `documentations/external/redfish/schemas/v1/` **and**
`test/fixtures/redfish/schemas/`:

| Family | File | Served/pinned evidence | Client impact |
|---|---|---|---|
| `EnvironmentMetrics` | `EnvironmentMetrics.v1_3_1.json` | the EMU chassis pin reads `/Chassis/1U/EnvironmentMetrics` (`TemperatureCelsius`/`PowerWatts`/`PowerLimitWatts`/`FanSpeedsPercent`, every excerpt carrying `DataSourceUri`) | none — excerpts are `Sensor` `SensorExcerpt`/`SensorPowerExcerpt`/`SensorFanArrayExcerpt` refs, all present in the already-mirrored `Sensor.v1_8_1.json` (DOCS-19) |
| `ThermalSubsystem` | `ThermalSubsystem.v1_3_1.json` | EMU pin reads Fans collection + FanRedundancy NPlusM groups + ThermalMetrics link | none — `FanRedundancy` items `$ref` `Redundancy.json#/definitions/RedundantGroup` (resolved below); `Fans` `$ref` FanCollection; `ThermalMetrics` `$ref` ThermalMetrics.json |
| `ThermalMetrics` | `ThermalMetrics.v1_3_1.json` | EMU pin reads `TemperatureSummaryCelsius` Intake/Exhaust/Internal/Ambient with DataSourceUri | none — the four summary props are `SensorExcerpt` refs |
| `PowerSubsystem` | `PowerSubsystem.v1_1_1.json` | EMU pin reads PowerSupplies collection | none |
| `PowerSupply` | `PowerSupply.v1_5_3.json` | EMU pin reads Bay1 detail: Model/Manufacturer/FirmwareVersion/LineInputStatus/Metrics + `#PowerSupply.Reset` target | none — all present; `#PowerSupply.Reset` is an action in `definitions/Actions` |
| `PowerSupplyMetrics` | `PowerSupplyMetrics.v1_1_1.json` | the PSU detail's `Metrics` link target (`#PowerSupplyMetrics.v1_1_1.PowerSupplyMetrics`) | none |
| `Fan` | `Fan.v1_5_1.json` | **mockup-served** member type — the Fans collection members publish `#Fan.v1_5_1.Fan` | none |
| `FanCollection` | `FanCollection.json` | `ThermalSubsystem.Fans` link target (`#FanCollection.FanCollection`) | none |
| `PowerSupplyCollection` | `PowerSupplyCollection.json` | `PowerSubsystem.PowerSupplies` link target | none |
| `Redundancy` (chain) | `Redundancy.json` + `Redundancy.v1_7_1.json` | `ThermalSubsystem.FanRedundancy` → `RedundantGroup` (MinNeededInGroup/MaxSupportedInGroup/RedundancyGroup/RedundancyType) | none — DOCS-14 precedent: source citations resolve to real mirror files |

All upstream anchors re-verified (2026-10-24): bmcweb `fbb307a` (unchanged),
mockup pin `23d21f9a` (unchanged), DSP0266 1.25.0 (unchanged), schema index
200; each of the 11 mirrored files fetched 200 from
`https://redfish.dmtf.org/schemas/v1/`. New bytes this run: 160,101 total
(17,008+10,142+19,523+10,756+34,997+17,833+17,544+4,936+5,251+2,890+19,221) —
inside the DOCS-6 budget. Fixture copies byte-identical to the mirror (verified
with `cmp`); SHA-256s recorded in the manifest.

## DOCS-21 — Battery corpus mirror (2026-10-24)

Closed the corpus gap the EMU-2 battery pins (2026-10-24, EMU 48→50) exposed:
the newly pinned battery family had **no versioned schema** in the
fixture/mirror. Mirrored 7 files (95,718 bytes total, inside DOCS-6) into
`documentations/external/redfish/schemas/v1/` **and**
`test/fixtures/redfish/schemas/` (served types + aggregators + collections):

| Family | File | Served/pinned evidence | Client impact |
|---|---|---|---|
| `Battery` | `Battery.json` (aggregator) + `Battery.v1_2_2.json` (**mockup-served** `#Battery.v1_2_2.Battery`) | the EMU battery pin reads `/Chassis/1U/Batteries/Battery1` — Module1 detail: Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent (`SensorExcerpt`, `DataSourceUri` → Sensors/Battery1StateOfHealth) + the `#Battery.SelfTest`/`#Battery.Calibrate`/`#Battery.Reset` action defs | none — all 34 properties present in the served `definitions/Battery`; `StateOfHealthPercent` `$ref`s `Sensor.json#/definitions/SensorExcerpt` (already-mirrored `Sensor.v1_8_1`, DOCS-19) |
| `BatteryMetrics` | `BatteryMetrics.json` (aggregator) + `BatteryMetrics.v1_0_3.json` (**mockup-served** `#BatteryMetrics.v1_0_3.BatteryMetrics`) | EMU pin reads electrical telemetry: DischargeCycles/InputVoltage/OutputVoltages/InputCurrentAmps/OutputCurrentAmps/StoredEnergyWattHours/TemperatureCelsius/ChargePercent/CellVoltages[8], every excerpt carrying `DataSourceUri` | none — all 23 properties present in the served `definitions/BatteryMetrics`; excerpt props are `Sensor` `SensorVoltageExcerpt`/`SensorExcerpt` refs |
| `BatteryCollection` | `BatteryCollection.json` | the `#BatteryCollection.BatteryCollection` the EMU pin enumerates (`Members[]` → `#Battery.v1_2_2.Battery`) | none |
| newest pair (delta note) | `Battery.v1_5_0.json` + `BatteryMetrics.v1_1_0.json` | newest published versions on the schema index | none — additive only: `BatteryChemistryType`/`EnergyStorageType`/`NominalOutputVoltage`/`ServicedDate` (Battery), `CRate`/`ERate` (Metrics); every emulator-pinned field unchanged → the pin contract holds across newest |

All upstream anchors re-verified (2026-10-24): **bmcweb master advanced
`fbb307a` → `63a18f4e6188a77b713a8b22c8a95ab3d6c5a718`** — all four mirrored
bmcweb docs byte-identical at the new HEAD (verified by SHA-256, no refresh
needed), mockup pin `23d21f9a` (unchanged), DSP0266 1.25.0 (unchanged),
schema index
200; each of the 7 mirrored files fetched 200 from
`https://redfish.dmtf.org/schemas/v1/`. New bytes this run: 95,718 total
(2,416+27,215+31,888+4,975+1,448+12,790+14,986) — inside the DOCS-6 budget.
Fixture copies byte-identical to the mirror (verified with `cmp`); SHA-256s
recorded in the manifest. The battery family has **no client model yet** — the
mirrored defs document the wire surface for future #007/#019 telemetry work;
no code change needed this run.

## DOCS-22 — frequent-family newest-version freshness audit (2026-10-24)

Freshness audit against the live DMTF schema index
(`https://redfish.dmtf.org/schemas/v1/`, 200 OK 3.4 MB). Extracted the
**newest published version per client-mapped family** and compared against the
mirrored "newest" file (the DOCS-12/13/19/20/21 precedent: newest + served
pairs). **8 of the 33 families had advanced upstream** since their last mirror:

| Family | Mirrored newest → new newest | Delta (additive-only) | Client impact |
|---|---|---|---|
| `EnvironmentMetrics` | `v1_3_1` → `v1_7_0` | `AmbientTemperatureCelsius`, `BarometricPressureMm`, `CurrentAmps`, `DewPointProximityCelsius`, `Voltage` | none — the emulator-pinned Temp/Power/Fan excerpts unchanged |
| `Fan` | `v1_5_1` → `v1_6_0` | `RatedSpeedRPM`, `RatedSecondarySpeedRPM` | none — served v1_5_1 still the pinned member type |
| `PowerSubsystem` | `v1_1_1` → `v1_2_0` | `Applied`, `Enabled`, `Links`, `LoadPercentThreshold`, `MaxRampRateWattsPerSecond`, `PowerBrake`, `PowerBrakeLoadPercentSensor`, `PowerBrakeTemperatureSensor`, `TemperatureThreshold` | none — served v1_1_1 still the pinned PowerSupplies surface |
| `PowerSupply` | `v1_5_3` → `v1_8_0` | `Certificates`, `VoltageControl` | none — served v1_5_3 still the pinned PSU detail (Model/Manufacturer/FirmwareVersion/LineInputStatus/Metrics) |
| `PowerSupplyMetrics` | `v1_1_1` → `v1_3_0` | `ChargePercent`, single-phase `Line1..3`/`Neutral` + `LineXToLineY`/`LineXToNeutral`, `PolyPhaseCurrentAmps`/`EnergykWh`/`PowerWatts`/`Voltage`, `PowerLoadPercent` | none — served v1_1_1 still pinned |
| `TaskService` | `v1_2_1` → `v1_3_0` | `#TaskService.DeleteAllCompletedTasks` action + `TaskMonitorAutoExpirySeconds` | none for #008/#020 — the new action/TTL are task-lifecycle extras, not yet read by the poller (stays #008/#020) |
| `ThermalMetrics` | `v1_3_1` → `v1_3_3` | **structural no-op** — copyright year + `anyOf[ref,null]` → bare `$ref` normalization (verified by deep diff) | none |
| `ThermalSubsystem` | `v1_3_1` → `v1_5_0` | `FansFullSpeedOverrideEnable`, `Filters` | none — served v1_3_1 still the pinned Fans/FanRedundancy surface |

All 8 files mirror to `documentations/external/redfish/schemas/v1/` only (the
fixture keeps the mockup-served versions — the DOCS-21 precedent; the corpus
invariant test asserts served versions, which are unchanged). New bytes: 189,768
total (22,003+18,934+22,174+37,552+46,503+11,802+19,245+11,555) — inside the
DOCS-6 budget. SHA-256s in the manifest; fetched 200 from
`https://redfish.dmtf.org/schemas/v1/`. The remaining 25 client-mapped families
are unchanged upstream (newest still the mirrored file).

Anchors re-verified this run (2026-10-24 12:45–12:47 UTC): **bmcweb master
`63a18f4e6188a77b713a8b22c8a95ab3d6c5a718`** — all four mirrored docs
byte-identical at HEAD (re-verified live, SHA-256 match), mockup pin
`23d21f9a` (unchanged), DSP0266 1.25.0 (unchanged; 1.26.0 probe → 404), schema
index 200. **No client code change**: every delta is additive, none of the new
fields sit on the current reader surface; the newest-version corpus stays a
reference for future telemetry/task work (#007/#019/#008/#020).

## DOCS-23 — Bios + Settings corpus mirror for the EMU Bios-Settings pin (2026-10-24)

The EMU-2 run (EMU 52→53, 2026-10-24) pinned the **Bios `@Redfish.Settings`
surface** live against the `23d21f9a` mockup. The two published types that pin
reads — `#Bios.v1_2_2.Bios` (`/Systems/437XR1138R2/Bios`) and
`#Settings.v1_3_5.Settings` (the `@Redfish.Settings` payload annotation type) —
were reachable by the corpus-invariant crawl but had **no versioned schema in
the external corpus**. This run mirrored the **mockup-served** versions plus
the **newest** published versions (the DOCS-12/13/19/20/21 "newest + served"
pair precedent):

| File | Served/newest | Bytes | Mirror destination |
|---|---|---|---|
| `Bios.v1_2_2.json` | **served** (`#Bios.v1_2_2.Bios`) | 16,485 | external corpus only |
| `Bios.v1_3_0.json` | newest (live index) | 20,646 | external corpus only |
| `Settings.v1_3_5.json` | **served** (`#Settings.v1_3_5.Settings`) | 15,194 | external corpus only |
| `Settings.v1_5_0.json` | newest (live index) | 15,695 | external corpus only |

67,020 new bytes total — inside the DOCS-6 budget. SHA-256s in the manifest
(`documentations/external/README.md` rows).

**Delta audit (newest vs served, additive-only):**

| Family | Served → newest | Delta | Client impact |
|---|---|---|---|
| `Bios` | `v1_2_2` → `v1_3_0` | adds `Passwords` (the newer password-management resource surface superseding the action-based `ChangePassword` flow) | none — no BIOS-config feature; note for #015/#026 when password management lands |
| `Settings` | `v1_3_5` → `v1_5_0` | **property no-op** (6 → 6 top-level props; structural/description-level only) | none |

**Client-mapped decision:** **Bios/Settings stay NOT client-mapped.** The
client's only BIOS data point is `ComputerSystem.BiosVersion` (overview
firmware line); no BIOS-config editor exists in the app, so the 33-family list
in the emulator corpus-invariant test is untouched and no
fixture-schema duty attaches (the crawl skips non-client-mapped families).
If a BIOS-config feature ever lands, Bios/Settings join the client-mapped
lists AND the served versions must be copied into
`test/fixtures/redfish/schemas/` (the DOCS-19/20/21 "every published
`@odata.type` for a client-mapped family has a served-version schema in the
fixture" invariant). The trace-note Bios `@Redfish.Settings` paragraph (EMU-2
pin record) now cites the real mirror files (`Bios.v1_2_2.json`,
`Settings.v1_3_5.json`) instead of live schema-index URLs.

Anchors re-verified this run (2026-10-24 15:17 UTC): bmcweb master
`63a18f4e6188a77b713a8b22c8a95ab3d6c5a718` (still HEAD; all four mirrored docs
byte-identical), mockup pin `23d21f9a`, DSP0266 1.25.0 (1.26.0 probe → 404),
schema index 200. **No client code change** from the docs audit; UI-2 landed
the not-found fallback unification separately (see tracking).

## DOCS-24 — EventDestination + VirtualMedia corpus mirror (2026-10-24)

The EMU-2 pins (EMU 52→57, 2026-10-24) read two published types outside the
33 client-mapped families: `#EventDestination.v1_14_0.EventDestination` (the
four `Subscriptions` members: Redfish/SNMPv3/SMTP-OEM/SyslogTCP transports —
the DOCS-7 bed for #019) and `#VirtualMedia.v1_6_3.VirtualMedia` (the system
boot-media read surface: CD1 Applet + Floppy1 URI — the #028 boot-media UX
input). Both families had **no schema in the external corpus**. This run
mirrored the **mockup-served** versions plus the **newest** published versions
(the DOCS-12/13/19/20/21/23 "newest + served" pair precedent):

| File | Served/newest | Bytes | Mirror destination |
|---|---|---|---|
| `EventDestination.json` | aggregator | 4,937 | external corpus only |
| `EventDestination.v1_14_0.json` | **served** (`#EventDestination.v1_14_0.EventDestination`) | 60,342 | external corpus only |
| `EventDestination.v1_17_1.json` | newest (live index) | 62,941 | external corpus only |
| `EventDestinationCollection.json` | collection | 5,037 | external corpus only |
| `VirtualMedia.json` | aggregator | 2,937 | external corpus only |
| `VirtualMedia.v1_6_3.json` | **served** (`#VirtualMedia.v1_6_3.VirtualMedia`) | 24,898 | external corpus only |
| `VirtualMedia.v1_7_0.json` | newest (live index) | 27,768 | external corpus only |
| `VirtualMediaCollection.json` | collection | 5,418 | external corpus only |

194,278 new bytes total — inside the DOCS-6 budget. SHA-256s in the manifest
(`documentations/external/README.md` rows).

**Delta audit (newest vs served, additive-only):**

| Family | Served → newest | Delta | Client impact |
|---|---|---|---|
| `EventDestination` | `v1_14_0` → `v1_17_1` | adds `BackupDestinations`, `Certificates`, `ClientCertificates`, `EventFormatType`, `HeartbeatIntervalMinutes`, `HttpHeaders`, `OEMProtocol`, `OEMSubscriptionType`, `OriginResources`, `RegistryPrefixes`, `SendHeartbeat`, `Severities`, `Status`, `SubordinateResources`, `SyslogFilters`, `VerifyCertificate` (+ `Actions`) | none — every EMU-2-pinned field (Destination/EventTypes/Context/Protocol/SubscriptionType/SNMP{HMAC_SHA96,CFB128_AES128,null keys}) is present in the served version; a future #019 receiver tolerates the newest additions |
| `VirtualMedia` | `v1_6_3` → `v1_7_0` | adds `Certificates`, `ClientCertificates`, `EjectPolicy`, `EjectTimeout`, `HTTPHeaders`, `Password`, `Status`, `TransferMethod`, `TransferProtocolType`, `UserName` (+ `Actions`) | none — every EMU-2-pinned field (ConnectedVia/Image/ImageName/Inserted/WriteProtected/MediaTypes/VerifyCertificate) is present in the served version; `Password`/`UserName` are a #028 boot-media security note (never read back) |

**Client-mapped decision:** **EventDestination/VirtualMedia stay NOT
client-mapped.** The 33-family list in the emulator corpus-invariant test is
untouched, and no fixture-schema duty attaches (the crawl skips
non-client-mapped families). REQUIREMENTS.md rows that cited the EMU pins
(EventDestination §11.4/DOCS-7 bed; VirtualMedia boot-media) now resolve to
real mirror files. If a future event receiver (#019) or boot-media editor
(#028) client-maps either family, the served versions must be copied into
`test/fixtures/redfish/schemas/` (the DOCS-19/20/21 invariant).

Anchors re-verified this run (2026-10-24 19:15–19:20 UTC): bmcweb master
`63a18f4e6188a77b713a8b22c8a95ab3d6c5a718` (still HEAD; API-verified), mockup
pin `23d21f9a3610f6b6fbb71ffc941296b159a524d2` (still HEAD of `main` —
API-verified), DSP0266 1.25.0 (hub link unchanged; 1.26.0 probe → 404),
schema index 200. Freshness audit of the two new families: newest on the live
index are `EventDestination.v1_17_1` / `VirtualMedia.v1_7_0` (mirrored);
no other client-mapped family advanced since DOCS-22 (12:45 UTC spot-check).
**No client code change** from the docs audit.

## DOCS-25 — SecureBoot + SecureBootDatabase corpus mirror (2026-10-24)

The EMU-2 pins (EMU 57→60, 2026-10-24) read the **SecureBoot boot-integrity
surface** outside the 33 client-mapped families: `#SecureBoot.v1_1_1.SecureBoot`
(the system secure-boot read state + `#SecureBoot.ResetKeys`
`ResetKeysType@Redfish.AllowableValues` — the annotation-form allow-list rule
#022/#016 applied to a second system action family) and the
`#SecureBootDatabase.v1_0_2.SecureBootDatabase` per-database surface (the
8-member `#SecureBootDatabaseCollection` PK/KEK/db/dbx + defaults, each with a
*smaller* per-resource ResetKeys allow-list — PK omits DeletePK). Both families
had **no schema in the external corpus**. This run mirrored the
**mockup-served** versions plus the **newest** published versions plus the
collection type (the DOCS-12/13/19/20/21/23/24 "newest + served" pair
precedent):

| File | Served/newest | Bytes | Mirror destination |
|---|---|---|---|
| `SecureBoot.json` | aggregator | 1,802 | external corpus only |
| `SecureBoot.v1_1_1.json` | **served** (`#SecureBoot.v1_1_1.SecureBoot`) | 11,629 | external corpus only |
| `SecureBoot.v1_2_1.json` | newest (live index, aggregator `$ref`) | 12,567 | external corpus only |
| `SecureBootDatabase.json` | aggregator | 1,636 | external corpus only |
| `SecureBootDatabase.v1_0_2.json` | **served** (`#SecureBootDatabase.v1_0_2.SecureBootDatabase`) | 9,765 | external corpus only |
| `SecureBootDatabase.v1_0_3.json` | newest (live index, aggregator `$ref`) | 9,795 | external corpus only |
| `SecureBootDatabaseCollection.json` | collection | 5,350 | external corpus only |

52,544 new bytes total — inside the DOCS-6 budget. SHA-256s in the manifest
(`documentations/external/README.md` rows).

**Delta audit (newest vs served, additive-only):**

| Family | Served → newest | Delta | Client impact |
|---|---|---|---|
| `SecureBoot` | `v1_1_1` → `v1_2_1` | adds `SecureBootDesiredMode` only (13 → 14 props; the requested-mode mirror of `SecureBootMode`) | none — every EMU-2-pinned field (SecureBootEnable/SecureBootCurrentBoot/SecureBootMode + ResetKeysType enum) is present in the served version; a future security-posture UI can read the desired mode from the newest |
| `SecureBootDatabase` | `v1_0_2` → `v1_0_3` | **property no-op** (11 → 11 props; copyright/description-level only) | none — the per-resource ResetKeys allow-list is identical |

Also verified the served-version `ResetKeysType` enum values in the mirror
match the EMU pin exactly: SecureBoot carries
`ResetAllKeysToDefault`/`DeleteAllKeys`/`DeletePK`; the PK database resource
carries `ResetAllKeysToDefault`/`DeleteAllKeys` (no DeletePK) — the
per-resource allow-list nuance is a schema fact (property `enum`), not a mockup
quirk, so a key-reset UI must read the database-level list, never reuse the
SecureBoot-level one (#022).

**Client-mapped decision:** **SecureBoot/SecureBootDatabase stay NOT
client-mapped.** The 33-family list in the emulator corpus-invariant test is
untouched, and no fixture-schema duty attaches (the crawl skips
non-client-mapped families). REQUIREMENTS.md rows that cited the EMU pins
(SecureBoot boot-integrity surface; SecureBootDatabase per-resource allow-list)
now resolve to real mirror files. If a future security-posture feature
client-maps either family, the served versions must be copied into
`test/fixtures/redfish/schemas/` (the DOCS-19/20/21 invariant).

Anchors re-verified this run (2026-10-24 18:52 UTC): bmcweb master
`63a18f4` (still HEAD via GitHub API), mockup pin `23d21f9a` (still HEAD of
`main` via GitHub API), DSP0266 1.25.0 (200 on the working `www.dmtf.org`
URL, 1.24 MB), schema index 200. Freshness audit of the two new families:
newest on the live index are `SecureBoot.v1_2_1` / `SecureBootDatabase.v1_0_3`
(mirrored). **No client code change** from the docs audit.

## DOCS-26 — Control corpus mirror for the EMU-2 Controls pin (2026-10-24)

The EMU-2 pins (EMU 60→63, 2026-10-24) read the **Control family** outside
the 33 client-mapped families: `#ControlCollection.ControlCollection` (the
`Chassis.1U.Controls` enumeration with PowerLimit + CPU1Freq members) and
`#Control.v1_5_0.Control` (PowerLimit: ControlType Power / ControlMode
Automatic / SetPoint 500 W / AllowableMax 1000 / AllowableMin 150 / `Sensor`
excerpt carrying Reading 374 + DataSourceUri → Sensors/TotalPower; CPU1Freq:
ControlType Frequency / SettingMin/Max 2000/2400 Hz / AllowableMin/Max
1500/3700). The family had **no schema in the external corpus**. This run
mirrored the **mockup-served** versions plus the **newest** published versions
plus the collection type (the DOCS-12/13/19/20/21/23/24/25 "newest + served"
pair precedent):

| File | Served/newest | Bytes | Mirror destination |
|---|---|---|---|
| `Control.json` | aggregator | 9,694 | external corpus only |
| `Control.v1_5_0.json` | **served** (`#Control.v1_5_0.Control`) | 47,414 | external corpus only |
| `Control.v1_8_1.json` | newest (live index, aggregator `$ref`) | 67,784 | external corpus only |
| `ControlCollection.json` | collection | 4,959 | external corpus only |

129,851 new bytes total — inside the DOCS-6 budget. SHA-256s in the manifest
(`documentations/external/README.md` rows).

**Delta audit (newest vs served, additive-only):**

| Family | Served → newest | Delta | Client impact |
|---|---|---|---|
| `Control` | `v1_5_0` → `v1_8_1` | adds `SetPointError` only (readonly, versionAdded v1_7_0; the error/difference of the related Sensor `Reading` from `SetPoint`, units per `SetPointUnits`) | none — every EMU-2-pinned field (ControlType/ControlMode/SetPoint/AllowableMax/Min/SettingMin/Max/Sensor) is present in the served version; a future power-capping UI (#022/#006) can surface the newest SetPointError from a newer BMC |

Also verified the aggregator `$ref`s v1_8_1 as newest (v1_0_7/v1_1_6/v1_2_6/
v1_3_6/v1_4_6/v1_5_5/v1_6_3/v1_7_2/v1_8_1 — the served v1_5_0 is absent from
the newest list, the same pattern DOCS-25 noted); `SetPointUnits` is defined
in the served `v1_5_0` (readonly, matches the fixture's `W`/`Hz` values); the
`Sensor` property is an `anyOf` SensorExcerpt/null in both versions (the
DataSourceUri link shape the emulator pin reads).

**Client-mapped decision:** **Control became client-mapped 2026-10-25
(EMULATOR run).** The #022/#016 SetPoint pre-validation rule is implemented
(`ControlResource.validateSetPoint`, `test/redfish/models/control_test.dart`,
+11 tests), so the client now maps the served `#Control.v1_5_0.Control`
resources. Per the DOCS-19/20/21 invariant the served `Control.v1_5_0.json`
was copied into `test/fixtures/redfish/schemas/` (byte-identical SHA-256
`de1614b0…` vs the DOCS-26 mirror) and `Control` was added to the
corpus-invariant family list in the emulator suite; the corpus-invariant test
(80/80) now verifies the served Control schema presence live. REQUIREMENTS.md
rows that cite the EMU-pinned Control surface (this header's "Last audited"
paragraph + the powerControl/#022 rows) resolve to real mirror files.

Anchors re-verified this run (2026-10-24 20:14 UTC): bmcweb master
`63a18f4` (still HEAD via GitHub API), mockup pin `23d21f9a` (still HEAD of
`main` via GitHub API), DSP0266 1.25.0 (200 on the working `www.dmtf.org`
URL, 1.24 MB), schema index 200. Freshness audit of the new family: newest
on the live index is `Control.v1_8_1` (mirrored). **No client code change**
from the docs audit.

## DOCS-27 — corpus freshness audit + mockup README provenance fix (2026-10-25)

Full freshness audit (the DOCS-22 precedent) against the live DMTF schema
index (`https://redfish.dmtf.org/schemas/v1/`, 200 OK, 3,448,133 bytes —
byte-identical to the mirrored `v1-index.html`).

**Method:** downloaded the live index, extracted all 7,167 JSON entries, and
compared the **newest published version per family** against the mirrored
"newest" file for every family in the corpus (the DOCS-22 33-family list plus
the families mirrored since: `Battery`, `BatteryMetrics`, `Bios`, `Settings`,
`SecureBoot`, `SecureBootDatabase`, `Control`, `EventDestination`,
`VirtualMedia` — 38 families total). Separately re-downloaded **all 120
mirrored schema files** and byte-compared SHA-256.

**Result: ZERO version advances.** Every mirrored "newest" file is still the
live index's newest:

- 120/120 mirrored schema files byte-identical to live (no drift, no
  re-download needed).
- Registries byte-identical: `Base.1.5.0` (`c10263417a076402…`) +
  `Base.1.24.0` (`abe0b78bba184f4b…`).
- Index page byte-identical (`e5a2979727a7fc03…`); DSP0266 1.25.0 PDF
  byte-identical (`385ee6d0039a2dbc…`); bmcweb docs byte-identical at HEAD
  (`Redfish.md` `9be2748b…`, `REDFISH_CHECKLIST.md` `98ff60be…`,
  `OEM_SCHEMAS.md` `7d651fd1…`, `CLIENTS.md` `cfea5163…`).
- **No new downloads, no corpus refresh, no client code change.**

**Provenance fix (the only diff):** the manifest row for the mirrored
`redfish/mockup/README-mockup-server.md` recorded the **upstream** SHA-256
(`b3af2ff369dcfd78…`, 7,318 B), but the committed blob has been the DOCS-1
normalised copy ever since — trailing whitespace stripped on the `cert = ` /
`key = ` lines (2 bytes), so its on-disk SHA-256 is `0d79a16595033b72…`
(7,316 B). The manifest claimed a hash the repo did not contain. Updated the
manifest row to record the **actual committed SHA** (`0d79a165…`, 7,316 B)
with an explicit note that the content is byte-identical to upstream apart
from that 2-byte whitespace normalisation (DOCS-1 wrote it that way, and
restoring upstream's trailing whitespace would fail `git diff --check` on
every future run). Re-verified live: upstream is `b3af2ff3…` (7,318 B) at
the pinned `23d21f9a`, so the semantic content is current; the manifest is
now truthful about what the repo actually holds.

Anchors re-verified this run (2026-10-25 00:07–00:15 UTC): bmcweb master
`63a18f4e6188a77b713a8b22c8a95ab3d6c5a718` (still HEAD via GitHub API),
mockup pin `23d21f9a3610f6b6fbb71ffc941296b159a524d2` (still HEAD of `main`
via `git ls-remote`), DSP0266 1.25.0 (200 on the working `www.dmtf.org` URL),
schema index 200. The 33-family corpus-invariant emulator list is untouched
(no family became client-mapped). **No client code change** from the docs
audit.

## DOCS-28 — Heater + HeaterMetrics corpus mirror for the EMU-2 Heaters pin (2026-10-25)

Closed the last corpus gap the EMU-2 Heaters pin (2026-10-25, EMU 64→66)
exposed: the newly pinned thermal-heater families had **no schema at all** in
the external corpus. Mirrored 7 files (60,045 bytes total, inside DOCS-6) into
`documentations/external/redfish/schemas/v1/` (external corpus only — both
families stay **NOT client-mapped**, so no fixture duty and no
corpus-invariant list change, the DOCS-24/25/26 precedent):

| Family | Served file | Newest file | EMU pin evidence | Client impact |
|---|---|---|---|---|
| `Heater` | `Heater.v1_0_1.json` | `Heater.v1_0_2.json` (+ `Heater.json` aggregator) | the pin reads `/Chassis/1U/ThermalSubsystem/Heaters/CPU1Heater` (`#Heater.v1_0_1.Heater`): PhysicalContext CPU / Manufacturer Contoso Heaters / Model CPUHeater / SerialNumber SNDHM0123456789 / HotPluggable / LocationIndicatorActive / Status + `Links.Processors[0]` → CPU1 + `Metrics` link | none — every pinned field present in the served def; v1_0_2 delta is a **property no-op** (26 diff lines: `$id`/copyright/backtick-quoted descriptions/`language`/title) |
| `HeaterMetrics` | `HeaterMetrics.v1_0_1.json` | `HeaterMetrics.v1_0_2.json` (+ `HeaterMetrics.json` aggregator) | the pin reads the `Metrics` link target (`#HeaterMetrics.v1_0_1.HeaterMetrics`): PrePowerOnHeatingTimeSeconds 600 / RuntimeHeatingTimeSeconds 3600 / PowerWatts.Reading 200.3 / TemperatureReadingsCelsius[1] (DeviceName 'Heater Average Temperature', Reading 2.5) + advertised `#HeaterMetrics.ResetMetrics` (no `/Actions/` segment → POST 404 candidate, never a contract) | none — every pinned field present in the served def; v1_0_2 delta is a **property no-op** (same class of diff) |
| `HeaterCollection` | `HeaterCollection.json` | — | `ThermalSubsystem.Heaters` link target — the pin enumerates its 1 member (CPU1Heater) | none — collection type |

The **newest** versions are the aggregators' `$ref` targets (verified in the
mirrors: `Heater.json` refs `Heater.v1_0_2.json`, `HeaterMetrics.json` refs
`HeaterMetrics.v1_0_2.json`); `Heater.v1_0_3` / `HeaterMetrics.v1_0_3` probe
404 on the live index (verified 2026-10-25 02:11 UTC) — v1_0_2 is current.
The served-version `ResetMetrics` action def in the mirror matches the EMU pin
(target `HeaterMetrics.ResetMetrics` under `definitions/Actions`, no
`/Actions/`-segment obligation). **No client code change** — both families
stay NOT client-mapped; if a thermal-heater feature ever lands (FUTUREWORK
candidate), Heater/HeaterMetrics join the client-mapped lists and the served
versions must also be copied into `test/fixtures/redfish/schemas/` (the
DOCS-19/20/21 invariant).

All upstream anchors re-verified (2026-10-25 02:11 UTC): bmcweb `63a18f4`
(still HEAD via GitHub API, docs byte-identical), mockup pin `23d21f9a`
(still HEAD of `main` via `git ls-remote`), DSP0266 1.25.0 (200 on the
working `www.dmtf.org` URL — 1.26.0 still 404), schema index 200; each of the
7 mirrored files fetched 200 from `https://redfish.dmtf.org/schemas/v1/`.
New bytes this run: 60,045 total (1,252+16,421+16,449+1,275+9,823+9,859+4,966)
— inside the DOCS-6 budget. **The corpus mirror queue is now EMPTY** — every
EMU-2-pinned family has a schema in the external corpus.

## DOCS-30 — CertificateService/CertificateLocations/Certificate + KeyService/KeyPolicy/Key + ComponentIntegrity corpus mirror for the EMU-2 branch pins (2026-10-25)

Closed the corpus gap the EMU 71→75 branch pins (2026-10-25) exposed: the
certificate / key / component-integrity families pinned live by the
corpus-invariant crawl had **no schema at all** in the external corpus
(previously `grep` for any of these names in `documentations/external/redfish/
schemas/v1/` returned nothing). Mirrored 25 files (446,257 bytes total, inside
DOCS-6) into `documentations/external/redfish/schemas/v1/` (external corpus
only — all seven families stay **NOT client-mapped**, so no fixture duty and
no corpus-invariant list change, the DOCS-24/25/26/28 precedent):

| Family | Served file | Newest file | EMU pin evidence | Client impact |
|---|---|---|---|---|
| `CertificateService` | `CertificateService.v1_0_4.json` | `CertificateService.v1_2_2.json` (+ `CertificateService.json` aggregator) | the pin reads `/redfish/v1/CertificateService` (`#CertificateService.v1_0_4.CertificateService`): the GenerateCSR / ReplaceCertificate action targets + the `CertificateLocations` link | none — v1_2_2 **adds only** `AutomaticCertificateEnrollment`/`CertificateEnrollments`/`EnrollmentCACertificates` (readonly enrollment surface; no client code change) |
| `CertificateLocations` | `CertificateLocations.v1_0_3.json` | `CertificateLocations.v1_0_4.json` (+ `CertificateLocations.json` aggregator) | the pin reads `CertificateService/CertificateLocations` (`#CertificateLocations.v1_0_3.CertificateLocations`): `Links.Certificates` — the three certificate-store pin list (HTTPS server cert / UpdateService client cert / VirtualMedia cert) | none — v1_0_4 is a **property no-op** vs served v1_0_3 (diff: `$id`/copyright/`language`/description backticks only) |
| `Certificate` | `Certificate.v1_8_1.json` | `Certificate.v1_11_0.json` (+ `Certificate.json` aggregator) | the store members the Rekey/GenerateCSR ActionInfo pins read type `#Certificate.v1_8_1.Certificate` | none — v1_11_0 **adds only** `Password`/`Status`; `Password` is a #015/#026 never-read-back note (same class as VirtualMedia `Password`/`UserName`, DOCS-24) |
| `KeyService` | `KeyService.v1_0_0.json` | `KeyService.v1_0_1.json` (+ `KeyService.json` aggregator) | the pin reads `/redfish/v1/KeyService` (`#KeyService.v1_0_0.KeyService`): the NVMeoFSecrets (KeyCollection) + NVMeoFKeyPolicies links | none — v1_0_1 is a **property no-op** vs served v1_0_0 (diff: `$id`/copyright/description backticks only) |
| `KeyPolicy` | `KeyPolicy.v1_0_0.json` | `KeyPolicy.v1_0_1.json` (+ `KeyPolicy.json` aggregator) | the pin reads the NVMeoF allow-list surface (`#KeyPolicy.v1_0_0.KeyPolicy`): SecurityTransportAllowList / CipherSuiteAllowList / SecurityProtocolAllowList / DHGroupAllowList / SecureHashAllowList (the #022-style read-only allow-list shape) | none — v1_0_1 is a **property no-op** vs served v1_0_0 |
| `Key` | `Key.v1_4_0.json` | `Key.v1_4_1.json` (+ `Key.json` aggregator) | the pin reads `NVMeoFSecrets` as **collection-metadata only** (`#KeyCollection.KeyCollection`, 2 members) — the members type `#Key.v1_4_0.Key` and carry real `KeyString` key material, so the suite never fetches a member body (the #015/#026 never-read-secrets-back rule stated as a scope boundary in the test) | none — v1_4_1 is a **property no-op** vs served v1_4_0; the never-read-back boundary is the client contract |
| `ComponentIntegrity` | `ComponentIntegrity.v1_2_2.json` | `ComponentIntegrity.v1_5_0.json` (+ `ComponentIntegrity.json` aggregator) | the pin reads the 4-member collection (SS-SPDM-0/1, USB-Integrity, TPM-0) + member shapes (`#ComponentIntegrity.v1_2_2.ComponentIntegrity` — SPDM enabled + DMTF MeasurementSet, TPM PCR measurement set, the **disabled** USB member — enabled-state read per member, never assumed) | none — v1_5_0 is a **property no-op** for the client-relevant surface (SPDM/TPM/USB member fields; added properties are deeper integrity-verification fields, additive) |

All 25 files fetched 200 from `https://redfish.dmtf.org/schemas/v1/`
(2026-10-25 15:40 UTC); every file validated as JSON; SHA-256s + byte sizes
recorded in the manifest. The served versions are the aggregators' `$ref`
targets for the exact versions the fixture serves (cross-checked against the
fixture `@odata.type` values) — the "newest + served" pair precedent
(DOCS-11/12/13/19/20/21/23/24/25/26/28). All upstream anchors re-verified the
same run (bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index
200). New bytes this run: 446,257 total — inside the DOCS-6 budget. **The
corpus mirror queue is now EMPTY** — every EMU-2-pinned family has a schema in
the external corpus.

## DOCS-31 — corpus-invariant crawl extended to ALL published types + 17-family corpus gap closed (2026-10-25)

The corpus-invariant live crawl (EMU-2 group, `test_integration/emulator/
emulator_suite_test.dart`) previously asserted **only** the DOCS-19/20/21
fixture invariant for **client-mapped** families. This run extended it to also
assert that **every** published versioned `@odata.type` — client-mapped or
not — has a served-version schema in the **external corpus** mirror
(`documentations/external/redfish/schemas/v1/`). The extended crawl (101
published types reached) immediately exposed a real provenance gap: **17
families the pinned mockup publishes had NO schema at all** in the external
corpus, despite DOCS-30's "corpus mirror queue EMPTY" note (that claim was
only true for the client-mapped + EMU-2-pinned families).

Closed with DOCS-31 — the "newest + served" pair precedent
(DOCS-11/12/13/19/20/21/23/24/25/26/28/30), external corpus only (all 17 stay
**NOT client-mapped** → no fixture duty, corpus-invariant family list
unchanged):

| Family | Served (mockup) | Newest | Collection | Client impact |
|---|---|---|---|---|
| `AccelerationFunction` | `v1_0_4` | `v1_0_5` | `AccelerationFunctionCollection.json` | none — v1_0_5 **property no-op** (17→17) |
| `Assembly` | `v1_5_0` | `v1_6_1` | — (no collection type) | none — v1_6_1 **property no-op** (11→11) |
| `ExternalAccountProvider` | `v1_7_1` | `v1_9_0` | `ExternalAccountProviderCollection.json` | none — v1_9_0 **property no-op** (22→22) |
| `GraphicsController` | `v1_0_1` | `v1_0_2` | `GraphicsControllerCollection.json` | none — v1_0_2 **property no-op** (22→22) |
| `HostInterface` | `v1_3_1` | `v1_4_0` | `HostInterfaceCollection.json` | none — v1_4_0 **property no-op** (24→24) |
| `Memory` | `v1_19_0` | `v1_24_0` | `MemoryCollection.json` | none — v1_24_0 **adds only** `CacheLevel`/`PowerManagementICManufacturerID`/`PowerManagementICRevisionID`/`ProductionDate` (78→82) |
| `MessageRegistryFile` | `v1_1_4` | `v1_1_5` | `MessageRegistryFileCollection.json` | none — v1_1_5 **property no-op** (12→12) |
| `OutboundConnection` | `v1_0_1` | `v1_0_3` | `OutboundConnectionCollection.json` | none — v1_0_3 **property no-op** (20→20) |
| `Port` | `v1_11_0` | `v1_20_0` | `PortCollection.json` | none — v1_20_0 **adds only** `AssociatedPhysicalPort`/`ConfiguredSpeedGbps`/`ConfiguredWidth`/`FirstLane`/`HostDevice`/`IsAggregation`/`IsSplit`/`LinkPartnerExpected`/`LinkPartnerReceived`/`LinkPartnerTransmit`/… (43→56) |
| `Processor` | `v1_19_0` | `v1_24_0` | `ProcessorCollection.json` | none — v1_24_0 **adds only** `CacheMemory`/`HardwareSecurityVersion`/`TotalEnabledThreads`/`UALink` (63→67) |
| `ProcessorMetrics` | `v1_6_3` | `v1_7_1` | — (no collection type) | none — v1_7_1 **adds only** `LifetimeStartDateTime` (31→32) |
| `SecurityPolicy` | `v1_0_1` | `v1_1_0` | — (no collection type) | none — v1_1_0 **adds only** `AllowDeny` (13→14) |
| `SerialInterface` | `v1_2_0` | `v1_3_0` | `SerialInterfaceCollection.json` | none — v1_3_0 **adds only** `Modbus` (19→20) |
| `Signature` | `v1_0_2` | `v1_0_3` | `SignatureCollection.json` | none — v1_0_3 **property no-op** (13→13) |
| `SimpleStorage` | `v1_3_1` | `v1_3_2` | `SimpleStorageCollection.json` | none — v1_3_2 **property no-op** (13→13) |
| `TrustedComponent` | `v1_3_0` | `v1_5_0` | `TrustedComponentCollection.json` | none — v1_5_0 **adds only** `Location` (21→22) |
| `USBController` | `v1_0_0` | `v1_0_1` | `USBControllerCollection.json` | none — v1_0_1 **property no-op** (18→18) |

All 65 files fetched 200 from `https://redfish.dmtf.org/schemas/v1/`
(2026-10-25 12:15 UTC); every file validated as JSON; SHA-256s + byte sizes
recorded in the manifest. New bytes this run: 1,403,838 total — inside the
DOCS-6 budget. The served versions are the exact `@odata.type` values the
pinned mockup publishes (cross-checked live by the crawl itself). All upstream
anchors re-verified the same run (bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266
1.25.0, schema index 200). **The corpus mirror queue is now EMPTY for every
published type** — and the invariant is a runnable emulator check, so a future
DOCS run cannot silently overstate it again.
