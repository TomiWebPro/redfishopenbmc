---
id: "009"
title: "Remote KVM — detection, HTML5 console & session handling"
status: open
priority: P3
type: feature
created: 2026-08-26
updated: 2026-11-18
closed: null
assignee: unassigned
labels: [kvm, console, managers, webview]
estimated_tokens: 45000
---

# 009 — Remote KVM — detection, HTML5 console & session handling

> Detect KVM capability via `Managers` + OEM, launch HTML5/webview console, handle fullscreen + input forwarding + session persistence.

## Description

`goal.md` §3.3 Remote KVM is conditional: only if Redfish/OEM exposes a console. DMTF defines `Manager.GraphicalConsole` / `SerialConsole` (`ConnectTypesSupported: KVMIP`, `ServiceEnabled`, `MaxConcurrentSessions`), OpenBMC may expose `Oem.OpenBMC.KVM` or vendor `Oem.*`. App must detect, not assume, and embed or launch the console.

- Goal reference: `goal.md` §3.3 Remote KVM
- User story: As a user I open KVM for a manager that supports it, see "Launch Console", get an embedded HTML5 KVM (or external browser fallback), go fullscreen, and have keyboard/mouse forwarded until I disconnect.
- Scope IN: `KvmService` capability detection, `KvmView` gated tab, HTML5 console embed via `webview_flutter` / `url_launcher`, session persistence, input forwarding note, OEM extensibility hook, tests
- Scope OUT: Implementing VNC/RFB ourselves, VirtualMedia (P4), raw Redfish explorer (P3)

## Goals / Acceptance Criteria

- [x] `lib/features/kvm/models/kvm_capability.dart` — `supported: bool, connectTypes: List<String> (KVMIP/Oem), serviceEnabled: bool, maxSessions: int?, uri: String? (GraphicalConsole.@odata.id or Oem link), managerId: String` — landed 2026-11-18: immutable `KvmCapability` with `fromManager` detection factory + `resolveLaunchUri`, exported from `kvm.dart`; 19 tests in `test/features/kvm/kvm_capability_test.dart`.
- [x] `lib/features/kvm/kvm_service.dart` —
  - Detection: `GET /Managers` → each `Manager` → `GraphicalConsole {ServiceEnabled, ConnectTypesSupported, MaxConcurrentSessions}` + `SerialConsole` similarly; also scan `Oem.*` for `KVM`/`WebConsole` keys (case-insensitive) — landed via `KvmService.fetchCapabilities()` (shared manager walk with `fetchConsoles()`), 2026-11-18.
  - `supported = (GraphicalConsole.ServiceEnabled && KVMIP in ConnectTypesSupported) || (Oem.* contains kvm)` — implemented in `KvmCapability.fromManager` (case-insensitive KVMIP, strict shared `FeatureRules.oemHasConsole`).
  - `launchUri(systemId, managerId) → String` resolves console URI: prefer `GraphicalConsole.@odata.id` fallback to `Manager.Oem.*.KVM.Uri` — landed as `KvmCapability.resolveLaunchUri` + `KvmService.fetchCapability(managerId)` (systemId bound in the service); read-only, no IPC.
  - No hard IPC — just expose URI + capability; actual console URL is BMC-hosted (e.g. `https://{host}/kvm` or Redfish `Manager` `GraphicalConsole` `Service` often points to `https://{host}:443/kvm` — document discovery)
- [ ] Tab `lib/features/kvm/views/kvm_view.dart` — **only if** `features.kvm==true`:
  - Capability card: Manager name, `ServiceEnabled`, `ConnectTypes`, `MaxConcurrentSessions`
  - `Launch Console` button → strategy:
    - On **web/desktop**: `url_launcher` external browser (secure) + optional `webview_flutter` embed if `allowInsecure` / CSP permits
    - On **mobile**: `webview_flutter` in-app with `JavascriptMode.unrestricted`, fullscreen `AppBar` toggle, back button = disconnect
  - Session note: "Console persists until manager timeout — close tab to disconnect"
  - Error if `ServiceEnabled false` → "KVM disabled on BMC" helper
- [x] Lifecycle: `KvmSessionProvider` tracks `activeManagerId`, `connectedSince`, handles app background → keep session alive until explicit disconnect or `MaxConcurrentSessions` eviction; `disconnect()` no Redfish call needed (pure UI session) but log — implemented as `KvmSessionController`/`KvmSessionState`/`kvmSessionProvider` in `lib/features/kvm/kvm_session.dart` (run 2026-11-18, commit pending); 17 tests in `test/features/kvm/kvm_session_test.dart`
- [x] Vendor extensibility: `KvmOemRegistry` — pluggable parsers for `Oem.AMI`, `Oem.HPE`, etc. (interface only in v1, no vendor impl yet) — landed 2026-11-18: `lib/features/kvm/models/kvm_oem_registry.dart` (`KvmOemConsoleParser` interface, `KvmOemConsoleInfo`, deterministic `KvmOemRegistry`), wired into `KvmConsole.fromManager(..., oemRegistry:)` as an optional hook; 19 tests in `test/features/kvm/kvm_oem_registry_test.dart`.
- [ ] Tests: `test/features/kvm/kvm_service_test.dart` — mocked Manager with `KVMIP`, without, OEM variant, disabled, maxSessions; widget test gated hidden when `kvm false`, embed fallback
- [ ] Coverage ≥75%

## Tasks

- [x] Model `KvmCapability` (landed 2026-11-18 in `models/kvm_capability.dart`; the per-console `ManagerConsoleInfo` role is served by the existing `KvmConsole`)
- [x] Service `KvmService` detection + URI resolution (`fetchCapabilities()` / `fetchCapability()` + `KvmCapability.resolveLaunchUri`, 2026-11-18)
- [ ] `KvmView` + `KvmLaunchButton` + `KvmEmbed` (webview stub) + fullscreen scaffold
- [ ] Add `webview_flutter` + `url_launcher` deps behind conditional import for web
- [ ] Oem registry interface
- [ ] Fixtures: OpenBMC `Managers/{id}` sample + DMTF mockup Manager with `GraphicalConsole`
- [ ] Tests: 5 service + 2 widget

## Redfish Mapping

| Data | Endpoint | Fields |
|------|----------|--------|
| Managers | `/redfish/v1/Managers` | `Members → /Managers/{id}` |
| ManagerConsole | `/Managers/{id}` | `GraphicalConsole {ServiceEnabled, ConnectTypesSupported [KVMIP], MaxConcurrentSessions}`, `SerialConsole`, `Oem` |
| Console session | BMC-specific URI (often not Redfish) | derived from `GraphicalConsole` or `Oem` — e.g. `https://{bmc}/#kvm/{managerId}` |

- Discovery rule: `kvm = any Manager.GraphicalConsole contains KVMIP && ServiceEnabled` OR `any Oem.* contains "kvm"/"console"` (`feature_rules.dart` → #003)
- No standard Redfish KVM action — detection is read-only; launch is external

## Progress Log

- 2026-11-18 11:30 UTC (run, agent:redfish-automation) — Partial progress (non-dependency, TLS-safe, genuinely-unimplemented #009 slice): landed the **capability-card model + detection/URI-resolution**. New `lib/features/kvm/models/kvm_capability.dart`: immutable `KvmCapability` (`managerId`, `supported`, `connectTypes`, `serviceEnabled`, `maxSessions`, `uri`, `sourceManagerUri`, `hasUri`, `supportsKvmIp`) with a `fromManager` detection factory — `supported = (GraphicalConsole enabled && KVMIP advertised) || OEM console` (case-insensitive KVMIP, strict shared `FeatureRules.oemHasConsole`), deterministic deduped connect types (graphical → serial → `Oem` marker) and serial `maxSessions` fallback — plus `resolveLaunchUri` (prefer `GraphicalConsole.@odata.id`, bounded case-insensitive fallback to OEM `KVM`/`WebConsole` `Uri`; no transport weakened). Exported from `kvm.dart`. `KvmService` gained `fetchCapabilities()` / `fetchCapability(managerId)` over a shared `_fetchManagerBodies()` walk (no IPC, read-only URI exposure); `fetchConsoles()` refactored onto the same walk with unchanged behaviour. Added `test/features/kvm/kvm_capability_test.dart` (19 tests: supported/disabled/non-KVMIP/case-insensitive/legacy-Enabled/OEM detection, bare-OEM rejection, defaults, dedup ordering, maxSessions fallback, non-map tolerance, unmodifiable types, URI preference + bounded OEM search) and 3 service detection tests in `kvm_service_test.dart`. #009 capability-model + detection + URI-resolution acceptance boxes checked; issue stays OPEN (HTML5 embed, fullscreen, input forwarding, coverage-gate remain — embed/fullscreen/input blocked on platform WebView + BMC TLS validation). No WebView/protocol dependency; no production TLS weakened.
- 2026-11-18 11:00 UTC (run, agent:redfish-automation) — Partial progress (non-dependency, TLS-safe, genuinely-unimplemented #009 slice): landed **vendor extensibility** — the `KvmOemRegistry` interface. New `lib/features/kvm/models/kvm_oem_registry.dart` defines the `KvmOemConsoleParser` pluggable interface (declaring a `vendorKey` + `parse`), the immutable `KvmOemConsoleInfo` value object, and a deterministic `KvmOemRegistry` (registration-order resolution, case-insensitive/trimmed vendor-key matching, bounded nested-block search, duplicate rejection, unmodifiable snapshot). No vendor parser ships in v1 — the registry is intentionally empty by default, exactly as the acceptance item specifies ("interface only in v1"). Wired into `KvmConsole.fromManager(..., oemRegistry:)` as an **optional** hook: a registered parser's `KvmOemConsoleInfo` enriches the OEM console with a connect URI / types / enabled flag, which then flows through the existing HTTPS/in-app launch gating; with no registry or no matching parser, the strict `FeatureRules.oemHasConsole` behaviour is byte-for-byte unchanged. Added `test/features/kvm/kvm_oem_registry_test.dart` (19 tests: model defaults, registration/duplicate/unmodifiable rules, case-insensitive + nested + sub-block resolution, RED proof that a vendor KVM URI yields no launch URI without a registry, GREEN integration that enriches it and reaches `KvmLaunchStrategy.inAppHtml5`, fallback + no-regression cases). No WebView/protocol dependency added; no production TLS weakened. This acceptance box is now checked; HTML5 embed + fullscreen / input forwarding remain open (blocked on platform WebView + BMC TLS validation).
- 2026-11-18 10:07 UTC (run, agent:redfish-automation) — Partial progress (non-dependency, TLS-safe slice, highest-value unblocked item): landed the pure-UI **console session lifecycle** — `KvmSessionState` + `KvmSessionController` + `kvmSessionProvider` (+ injectable `kvmSessionClockProvider`) in new `lib/features/kvm/kvm_session.dart`, exported from the `kvm.dart` barrel. Tracks `activeManagerId` + `connectedSince` (injected clock), maps app lifecycle (`paused`/`hidden`/`detached` → `backgrounded`) but deliberately **keeps the session alive on background** (a BMC console persists until its own timeout), ends it only on explicit `disconnect()` or single-session (`MaxConcurrentSessions == 1`) eviction on a newer `connect()`, and keeps a bounded audit log. `disconnect()` is pure UI state — the controller takes no `RedfishClient`, so no Redfish call is possible. Added `test/features/kvm/kvm_session_test.dart` (17 tests: lifecycle mapping, connect/disconnect, no-op safety, background-keeps-alive, resume, eviction vs multi-session vs same-manager, bounded log, clock-override provider) — written before the implementation (RED by absence) then GREEN. No WebView/protocol dependency; no production TLS touched. This acceptance box is now checked; HTML5 embed + input forwarding / fullscreen / OEM registry remain open (blocked on platform WebView + BMC TLS validation).
- 2026-08-26 — Created. Depends on #001 #003 #004. Lower priority (P3) — do after #005–#008.
- 2026-08-30 — STALE (triage): no Progress Log update for 4 days (>1-day threshold).

## References

- `documentations/project_goal/goal.md:87-95`
- Redfish Manager schema: https://redfish.dmtf.org/schemas/Manager.v1_16_0.json
- OpenBMC KVM: https://github.com/openbmc/bmcweb/blob/master/redfish-core/lib/managers.hpp / phosphor-webui kvm
- Related: #003, #004

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups:
