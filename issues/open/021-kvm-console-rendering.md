---
id: "021"
title: "KVM: implement remote console rendering (VNC/RFB/WebView)"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-11-18
closed: null
assignee: unassigned
labels: [kvm, console, unimplemented]
estimated_tokens: 18000
---

# 021 — KVM: implement remote console rendering

> `kvm_view.dart` lists discovered consoles and offers copy/open actions. Embedded VNC/RFB/HTML5 rendering is not yet implemented (no WebView/remote-desktop dependency); HTML5 HTTP(S) consoles open an in-app viewer scaffold with explicit rendering/dependency status and browser-open guidance, while KVMIP/RFB/VNC and serial (SSH/Telnet/IPMI) URI consoles are identified as requiring an external client with protocol-specific tested guidance. `fetchPrimaryConsole`/primary selection is wired. OEM consoles with no `connectUri` show a clear external-open notice.

## Description

- Core KVM functionality (viewing the remote console) is missing.
- Dead `fetchPrimaryConsole`.
- OEM console placeholder with no URI yields a non-actionable card.

- Goal reference: `goal.md` §3.5 Remote KVM
- User story: As a user I can open and interact with the BMC's remote console in-app.
- Scope IN: choose a rendering strategy (WebView for HTML5 KVM, or an RFB/VNC lib) and wire `KvmView` to it; use `fetchPrimaryConsole`; handle OEM/no-URI gracefully.
- Scope OUT: full input injection beyond what the chosen lib provides.

## Goals / Acceptance Criteria

- [ ] A discovered HTML5/RFB console renders in-app. (in-app HTML5 viewer path/scaffold added for HTTP(S) connect URIs with explicit status/browser-open guidance; KVMIP/RFB/VNC and serial SSH/Telnet/IPMI URIs open in-app viewer with protocol-specific external-client guidance/copy — embedded WebView/protocol rendering still pending dependency/platform-TLS validation)
- [x] `fetchPrimaryConsole` used to pick the primary console.
- [x] OEM/no-URI console shows a clear "open externally" notice with the URI.
- [ ] Dependency added & documented; tests for service selection logic. (selection + HTML5/external-protocol launchability/label logic and viewer UI tested; WebView/protocol dependency not added — blocked/deferred pending platform WebView support and BMC TLS/self-signed cert validation; strategy documented in-code/issue)

## Tasks

- [~] Decide rendering approach (WebView vs RFB package). Strategy: prefer `webview_flutter` (or platform WebView) for HTML5 HTTP(S) `ConnectUri` once platform support and BMC TLS/self-signed cert handling are validated (deferred — no dependency added in unattended run); VNC/RFB/KVMIP and serial SSH/Telnet/IPMI require an external/native client or protocol package.
- [~] Wire `KvmView` + `kvm_controller.dart`. Added `KvmConsoleViewerPage` in-app launch path and "Open console" action for consoles with `ConnectUri`; external VNC/KVMIP/RFB and serial URIs show protocol-specific client guidance and browser-open hint for HTML5; embedded rendering still pending.
- [x] Add tests for `kvm_service.dart` console selection.

## Rendering strategy (2026-11-16)

- **HTML5 (HTTP/HTTPS `ConnectUri`, `ConnectTypesSupported` includes `HTML5`)**: minimal in-app path is a `KvmConsoleViewerPage` reached from the KVM card. Full embedded rendering should use a platform WebView dependency (candidate: `webview_flutter`) once Linux/desktop/mobile support and self-signed/TLS/auth constraints for BMC endpoints are validated; do not weaken production TLS. Blocked/deferred this run (no platform validation available unattended); viewer provides browser-open guidance and copy path.
- **VNC/RFB/KVMIP or serial SSH/Telnet/IPMI URIs**: identified as requiring an external client with protocol-specific guidance and copy/open path. No in-app renderer in Flutter without a protocol client.
- **No `ConnectUri` (OEM)**: show manager/source URI and external-open guidance (implemented).

## Redfish Mapping

| Feature | Endpoint | Notes |
|---------|----------|-------|
| Graphical console | `/redfish/v1/Managers/{id}/GraphicalConsole` | `ConnectTypesSupported` (KVMIP/HTML5/OEM) |
| Virtual media | `/redfish/v1/Managers/{id}/VirtualMedia` | related |

- OEM: OpenBMC often exposes HTML5 KVM via Oem; handle gracefully.

## Progress Log

- 2026-11-18 (run, agent:redfish-automation) — Partial progress (non-dependency, TLS-safe slice): hardened in-app KVM HTML5 rendering to be **HTTPS-only**. `KvmConsole` gained `hasSecureLaunchUri` (TLS-encrypted HTTP(S) URI), `usesInsecureHttpLaunchUri` (plaintext HTTP), and `canLaunchInAppHtml5` now requires HTTPS (previously accepted plaintext HTTP) — the app never downgrades a BMC console to unencrypted transport. `KvmConsoleViewerPage` now shows an explicit, error-styled secure-transport warning for plaintext-HTTP HTML5 consoles (visible text == announced Semantics label, no internal issue refs) instead of the generic fallback; HTTPS/external-client/fallback guidance unchanged. Added model tests (RED proof: plaintext HTTP was previously `canLaunchInAppHtml5 == true`, now false; HTTPS still eligible; precise scheme classification) and a viewer widget test (warning shown + "path available" copy absent). No WebView/protocol dependency added; no production TLS weakened. Full "renders in-app" and "dependency added" acceptance boxes remain open (platform WebView + BMC TLS/self-signed validation still needed).
- 2026-11-16 (run, agent:redfish-automation) — Partial progress: refined #021 external-client handling by classifying serial SSH/Telnet/IPMI URI schemes and adding protocol-specific labels/guidance in `KvmConsole` and `KvmConsoleViewerPage` (HTML5 viewer now includes browser-open hint; VNC/RFB/SSH guidance clarified). Added model and widget coverage in `test/features/kvm/kvm_model_test.dart` and `test/features/kvm/kvm_widget_test.dart`. WebView dependency remains intentionally deferred/blocked (platform + BMC TLS/self-signed validation needed; no production TLS weakening); full "renders in-app" acceptance remains open.
- 2026-11-16 (run, agent:redfish-automation) — Partial progress: added `KvmConsole.requiresExternalConsoleClient` for VNC/RFB/KVMIP URI schemes and updated `KvmConsoleViewerPage` to show explicit external-client guidance for those protocols (copy URI preserved). Added model and widget coverage for KVMIP/RFB external-client handling in `test/features/kvm/kvm_model_test.dart` and `test/features/kvm/kvm_widget_test.dart`. Remaining: add/validate embedded WebView dependency for HTML5 HTTP(S) rendering (platform/TLS constraints) and/or a protocol client strategy for in-app VNC/RFB/KVMIP rendering; full "renders in-app" acceptance remains open.
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
