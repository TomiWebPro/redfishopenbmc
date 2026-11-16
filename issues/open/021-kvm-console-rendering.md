---
id: "021"
title: "KVM: implement remote console rendering (VNC/RFB/WebView)"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-11-16
closed: null
assignee: unassigned
labels: [kvm, console, unimplemented]
estimated_tokens: 18000
---

# 021 — KVM: implement remote console rendering

> `kvm_view.dart` only lists discovered consoles and offers "Copy connect info" (`kvm_view.dart:177-188`). There is no VNC/RFB/HTML5/RDP rendering, no WebView, and no dependency on any remote-desktop library — the actual remote console is unimplemented (discovery-only). `fetchPrimaryConsole` (`kvm_service.dart:89-96`) is dead (never called). OEM consoles with no `connectUri` render a card with no actionable info.

## Description

- Core KVM functionality (viewing the remote console) is missing.
- Dead `fetchPrimaryConsole`.
- OEM console placeholder with no URI yields a non-actionable card.

- Goal reference: `goal.md` §3.5 Remote KVM
- User story: As a user I can open and interact with the BMC's remote console in-app.
- Scope IN: choose a rendering strategy (WebView for HTML5 KVM, or an RFB/VNC lib) and wire `KvmView` to it; use `fetchPrimaryConsole`; handle OEM/no-URI gracefully.
- Scope OUT: full input injection beyond what the chosen lib provides.

## Goals / Acceptance Criteria

- [ ] A discovered HTML5/RFB console renders in-app. (in-app HTML5 viewer path/scaffold added for HTTP(S) connect URIs; embedded WebView rendering still pending dependency)
- [x] `fetchPrimaryConsole` used to pick the primary console.
- [x] OEM/no-URI console shows a clear "open externally" notice with the URI.
- [ ] Dependency added & documented; tests for service selection logic. (selection + HTML5 launchability logic and viewer UI tested; WebView dependency not added, strategy documented in-code/issue)

## Tasks

- [~] Decide rendering approach (WebView vs RFB package). Strategy: prefer `webview_flutter` (or platform WebView) for HTML5 HTTP(S) `ConnectUri`; RFB/VNC requires a native client package and protocol handling — defer until dependency/platform constraints are validated.
- [~] Wire `KvmView` + `kvm_controller.dart`. Added `KvmConsoleViewerPage` in-app launch path and "Open console" action for consoles with `ConnectUri`; embedded rendering still pending.
- [x] Add tests for `kvm_service.dart` console selection.

## Rendering strategy (2026-11-16)

- **HTML5 (HTTP/HTTPS `ConnectUri`, `ConnectTypesSupported` includes `HTML5`)**: minimal in-app path is a `KvmConsoleViewerPage` reached from the KVM card. Full embedded rendering should use a platform WebView dependency (candidate: `webview_flutter`) once Linux/desktop/mobile support and self-signed/TLS/auth constraints for BMC endpoints are validated; do not weaken production TLS.
- **KVMIP/VNC/RFB or non-HTTP URIs**: no in-app renderer in Flutter without a protocol client; keep external/open notice and copy URI path.
- **No `ConnectUri` (OEM)**: show manager/source URI and external-open guidance (implemented).

## Redfish Mapping

| Feature | Endpoint | Notes |
|---------|----------|-------|
| Graphical console | `/redfish/v1/Managers/{id}/GraphicalConsole` | `ConnectTypesSupported` (KVMIP/HTML5/OEM) |
| Virtual media | `/redfish/v1/Managers/{id}/VirtualMedia` | related |

- OEM: OpenBMC often exposes HTML5 KVM via Oem; handle gracefully.

## Progress Log

- 2026-11-16 (run, agent:redfish-automation) — Partial progress: added `KvmConsole` HTML5 launch helpers (`launchUri`, `hasHttpLaunchUri`, `canLaunchInAppHtml5`), in-app `KvmConsoleViewerPage` scaffold, and `KvmView` "Open console" action navigating to the viewer for consoles with a direct `ConnectUri` (copy remains available). Documented WebView-vs-external rendering strategy in issue. Added model and widget coverage (`kvm_model_test.dart`, `kvm_widget_test.dart`). Remaining: add/validate WebView dependency for embedded HTML5 rendering (platform/TLS constraints), RFB/KVMIP in-app handling decision, and full acceptance for "renders in-app".
- 2026-11-16 13:18 UTC — Partial progress (run 2026-11-16, agent:redfish-automation): `KvmService.pickPrimary` + `fetchPrimaryConsole` now select the preferred console (graphical first, else first) and `KvmController`/`KvmUiState` expose `primaryConsole`; `KvmView` marks the primary console and shows a clear "open externally" notice with the manager/source URI when no `ConnectUri` is available (OEM/no-URI). Added service selection and widget coverage in `test/features/kvm/kvm_service_test.dart` and `test/features/kvm/kvm_widget_test.dart`. Remaining: in-app HTML5/RFB console rendering, rendering dependency choice/addition/documentation, and wiring a launch/open flow beyond copy/external notice.
- 2026-08-30 — Created from triage analysis (feature #14). See also #009.

## References

- `lib/features/kvm/kvm_view.dart:177-188`
- `lib/features/kvm/kvm_service.dart:89-96`
- `lib/features/kvm/kvm_models.dart:156-168`
- Related: #009

## Closed Criteria

- Resolution:
- Closed reason:
- Follow-ups: none
