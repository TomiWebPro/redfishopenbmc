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
| _none yet_ | | | | | | |

## Current upstream anchors (verified 2026-10-21)

- Redfish Developer Hub — <https://redfish.dmtf.org/>
- DMTF schema index — <https://redfish.dmtf.org/schemas/v1/>
- Redfish specification DSP0266 — latest PDF linked from the hub
  (at setup time: `DSP0266_1.25.0.pdf`)
- Redfish Mockup Server — <https://github.com/DMTF/Redfish-Mockup-Server>
- OpenBMC bmcweb docs:
  - <https://github.com/openbmc/bmcweb/tree/master/docs>
  - `docs/Redfish.md`, `docs/REDFISH_CHECKLIST.md`, `docs/OEM_SCHEMAS.md`

> DMTF's `www.dmtf.org` pages may return 403 to plain curl. Use a browser
> user-agent, the `webfetch` tool, or the `redfish.dmtf.org` mirror, and record
> the URL that actually returned 200.

## Requirement traceability

`redfish/REQUIREMENTS.md` maps each audited requirement to the implementation and
a test. Keep it short and cite section numbers; unresolved gaps belong in
`FUTUREWORK.md` as `DOCS-*` items.
