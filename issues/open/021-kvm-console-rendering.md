---
id: "021"
title: "KVM: implement remote console rendering (VNC/RFB/WebView)"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-08-30
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

- [ ] A discovered HTML5/RFB console renders in-app.
- [ ] `fetchPrimaryConsole` used to pick the primary console.
- [ ] OEM/no-URI console shows a clear "open externally" notice with the URI.
- [ ] Dependency added & documented; tests for service selection logic.

## Tasks

- [ ] Decide rendering approach (WebView vs RFB package).
- [ ] Wire `KvmView` + `kvm_controller.dart`.
- [ ] Add tests for `kvm_service.dart` console selection.

## Redfish Mapping

| Feature | Endpoint | Notes |
|---------|----------|-------|
| Graphical console | `/redfish/v1/Managers/{id}/GraphicalConsole` | `ConnectTypesSupported` (KVMIP/HTML5/OEM) |
| Virtual media | `/redfish/v1/Managers/{id}/VirtualMedia` | related |

- OEM: OpenBMC often exposes HTML5 KVM via Oem; handle gracefully.

## Progress Log

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
