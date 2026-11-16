# Overview feature

Schema-driven per-system Overview tab (issue #006). The view renders only what
the connected BMC exposes and never assumes optional Redfish members are
present.

## Rendering rules

- **Always shown:** the Overview tab is available for every system (it is not
  capability-gated like KVM/Firmware/Bios). Individual cards/controls inside it
  are gated on discovered fields or actions.
- **Header:** `HealthBanner` (`Status.Health`, falling back to
  `Status.HealthRollup`, else `Unknown`) and a `PowerBadge` (`PowerState`).
- **Cards (InfoCards):**
  - `Identity` — Manufacturer, Model, Serial, SKU, Part, BIOS. Missing values
    render as "Not exposed by this BMC"; the card is omitted only when no
    identity rows exist.
  - `Processors` — count/model from `ProcessorSummary`, or "Not exposed by this
    BMC" when the summary is absent.
  - `Memory` — total GiB from `MemorySummary.TotalSystemMemoryGiB`, or "Not
    exposed by this BMC".
  - `Temperatures` — leading chassis temperature preview from the first chassis
    `Thermal` reading. **Omitted entirely** when no temperature is discoverable
    (no placeholder/disabled card).
  - `Indicator LED` — shows `LocationIndicatorActive` (On/Inactive) when the
    boolean successor property is served, otherwise the legacy `IndicatorLED`
    enum. A writable setter is rendered only for schema-valid states/actions the
    BMC advertises; unknown/unexposed state shows "Not exposed by this BMC".
  - `Boot override` — capability-gated card rendered when boot-override targets
    are advertised; hidden otherwise.
- **Missing-field policy:** never crash on `null`/missing members. Prefer
  omitting an optional card (temperature) or showing "Not exposed by this BMC"
  for value rows; never show a disabled placeholder for unsupported features.
- **Layout:** adaptive grid via `OverviewGridBreakpoints` — mobile `< 600` = 1
  column (stacked natural-height cards), tablet `600–1023` = 2 columns, desktop
  `≥ 1024` = 3 columns. Views must not overflow at 320 / 800 / 1300 px.
- **Data & refresh:** `overviewProvider` (`FutureProvider.family`) fetches the
  ComputerSystem and (best-effort) first chassis thermal via `OverviewService`.
  The view invalidates/refetches on pull-to-refresh, on a 30s periodic timer
  while mounted, and when the system power state changes. Refresh failures are
  handled without clobbering the current view with uncaught errors.
- **Accessibility:** merged semantics labels on headers/rows/banners and the
  error state; controls (Retry, setters) remain separate semantics nodes.

## Redfish mapping

- Identity/health/power/summaries/LED: `GET /redfish/v1/Systems/{id}`
  (`Manufacturer`, `Model`, `SKU`, `SerialNumber`, `PartNumber`, `BiosVersion`,
  `Status{Health,HealthRollup}`, `PowerState`, `IndicatorLED`,
  `LocationIndicatorActive`, `ProcessorSummary`, `MemorySummary`).
- Temperature preview (optional): `GET /redfish/v1/Chassis/{id}/Thermal`
  `Temperatures[0].ReadingCelsius` (best-effort; full graphs live in Sensors).
