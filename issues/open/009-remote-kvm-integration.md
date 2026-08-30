---
id: "009"
title: "Remote KVM — detection, HTML5 console & session handling"
status: open
priority: P3
type: feature
created: 2026-08-26
updated: 2026-08-30
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

- [ ] `lib/features/kvm/models/kvm_capability.dart` — `supported: bool, connectTypes: List<String> (KVMIP/Oem), serviceEnabled: bool, maxSessions: int?, uri: String? (GraphicalConsole.@odata.id or Oem link), managerId: String`
- [ ] `lib/features/kvm/kvm_service.dart` —
  - Detection: `GET /Managers` → each `Manager` → `GraphicalConsole {ServiceEnabled, ConnectTypesSupported, MaxConcurrentSessions}` + `SerialConsole` similarly; also scan `Oem.*` for `KVM`/`WebConsole` keys (case-insensitive)
  - `supported = (GraphicalConsole.ServiceEnabled && KVMIP in ConnectTypesSupported) || (Oem.* contains kvm)`
  - `launchUri(systemId, managerId) → String` resolves console URI: prefer `GraphicalConsole.@odata.id` fallback to `Manager.Oem.*.KVM.Uri`
  - No hard IPC — just expose URI + capability; actual console URL is BMC-hosted (e.g. `https://{host}/kvm` or Redfish `Manager` `GraphicalConsole` `Service` often points to `https://{host}:443/kvm` — document discovery)
- [ ] Tab `lib/features/kvm/views/kvm_view.dart` — **only if** `features.kvm==true`:
  - Capability card: Manager name, `ServiceEnabled`, `ConnectTypes`, `MaxConcurrentSessions`
  - `Launch Console` button → strategy:
    - On **web/desktop**: `url_launcher` external browser (secure) + optional `webview_flutter` embed if `allowInsecure` / CSP permits
    - On **mobile**: `webview_flutter` in-app with `JavascriptMode.unrestricted`, fullscreen `AppBar` toggle, back button = disconnect
  - Session note: "Console persists until manager timeout — close tab to disconnect"
  - Error if `ServiceEnabled false` → "KVM disabled on BMC" helper
- [ ] Lifecycle: `KvmSessionProvider` tracks `activeManagerId`, `connectedSince`, handles app background → keep session alive until explicit disconnect or `MaxConcurrentSessions` eviction; `disconnect()` no Redfish call needed (pure UI session) but log
- [ ] Vendor extensibility: `KvmOemRegistry` — pluggable parsers for `Oem.AMI`, `Oem.HPE`, etc. (interface only in v1, no vendor impl yet)
- [ ] Tests: `test/features/kvm/kvm_service_test.dart` — mocked Manager with `KVMIP`, without, OEM variant, disabled, maxSessions; widget test gated hidden when `kvm false`, embed fallback
- [ ] Coverage ≥75%

## Tasks

- [ ] Model `KvmCapability` + `ManagerConsoleInfo`
- [ ] Service `KvmService` detection + URI resolution
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
