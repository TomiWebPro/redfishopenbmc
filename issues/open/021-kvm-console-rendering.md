---
id: "021"
title: "KVM: implement remote console rendering (VNC/RFB/WebView)"
status: open
priority: P2
type: bug
created: 2026-08-30
updated: 2026-11-19
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

- 2026-11-19 06:41 UTC (run, agent:redfish-automation) — Partial progress (genuine, dependency-free, TLS-safe launch-classification fix). `KvmConsole.launchStrategy` collapsed an enabled plaintext-HTTP **non-HTML5** console (e.g. KVMIP over `http://`) into `KvmLaunchStrategy.noUri` despite its real, copyable URI: the viewer's `kvmLaunchStatusText(noUri)` said "Use the URI externally if provided" with no unencrypted warning, and `canOpenConsole == false` withheld "Open console", while both KVM cards already flag `usesInsecureHttpLaunchUri`. Added a dedicated `KvmLaunchStrategy.insecureHttp` (decided after `insecureHtml5`, before external-client), with its own merged-a11y cleartext status text and error styling in the viewer. It is still never an in-app or browser render target — no unencrypted browser console is suggested and production TLS is never weakened — but its URI stays copyable/openable externally, matching `insecureHtml5`. +4 RED→GREEN tests (3 confirmed RED pre-fix: model load against the missing enum, absent "Open console" on the card, absent viewer semantics label); baseline analyze 0 / 1147 passed / 1 skipped → verify analyze 0 / 1151 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; issues validate OK. In-app WebView rendering + dependency acceptance remain open (platform WebView + BMC TLS/self-signed validation). No WebView/protocol dependency added; no production TLS weakened.

- 2026-11-19 06:03 UTC (run, agent:redfish-automation) — Partial progress (dependency-free, TLS-safe transport-classifier parity). The HTTPS classifier was hardened against raw-space/C0/DEL code units, but the three plaintext-HTTP classifiers (`KvmConsole.hasHttpLaunchUri` / `usesInsecureHttpLaunchUri`, `KvmCapability.usesInsecureHttpLaunchUri`) were ad-hoc `Uri.tryParse` copies that silently percent-encode such characters and still report `scheme == 'http'` + a non-empty host — so a malformed HTTP `ConnectUri` was presented as a genuine unencrypted endpoint on the console/capability cards while the equivalent malformed HTTPS target was refused. Added shared hardened siblings `isPlaintextHttpConsoleUri` / `isHttpConsoleUri` in `launch_plan.dart` (same `_controlSafeTrimmedUri` core), delegated all three getters, and added `KvmCapability.hasHttpLaunchUri` for two-view parity. Strictly tightens classification — no valid HTTP(S) endpoint lost, no WebView/protocol dependency, no production TLS weakening (in-app rendering remains HTTPS-only). +9 RED→GREEN tests (2 model + 3 capability RED pre-fix + 4 pure classifier); analyze 0 / 1147 passed / 1 skipped; DMTF emulator 85/85; coverage kvm 94.8%; issues validate OK. In-app WebView rendering + dependency acceptance remain open (platform WebView + BMC TLS/self-signed validation).

- 2026-11-19 05:23 UTC (run, agent:redfish-automation) — Partial progress (dependency-free, TLS-safe secure-URI classification parity). `KvmConsole.hasSecureLaunchUri` / `KvmCapability.hasSecureLaunchUri` used bare `Uri.tryParse` + https + host, which silently percent-encodes C0/DEL controls, so a CRLF/NUL-bearing HTTPS `ConnectUri` was classified "secure" and offered "Open console" while the fail-closed `launch_plan.dart` already failed closed to `copyOnly` — the UI and the decision layer disagreed, and a CRLF/NUL target risks header/URI injection. Both model getters now share the single fail-closed `isSecureHttpsConsoleUri` classifier used by the launch plan, so no surface can call a malformed target secure; the console card withholds the launch affordance for it (URI stays copyable). +5 RED→GREEN tests (2 model confirmed RED pre-fix, 2 capability, 1 widget); analyze 0 / 1136 passed / 1 skipped; emulator 85/85; coverage kvm 94.8%; issues validate OK. Full in-app WebView rendering + dependency acceptance remain open (platform WebView + BMC TLS/self-signed validation). No WebView/protocol dependency added; no production TLS weakened.

- 2026-11-19 04:44 UTC (run, agent:redfish-automation) — Partial progress (dependency-free, TLS-safe: the per-console card now matches the capability card / viewer's plaintext-HTTP warning). `KvmView._ConsoleCard` was the only KVM surface with no transport-safety signal, so an operator could tap "Open console" on a plaintext-HTTP HTML5 console without being told its video and injected input would travel unencrypted. Added an error-styled, merged-a11y "Unencrypted HTTP console URI…" warning for `console.usesInsecureHttpLaunchUri`, sharing the exact sentence with the capability card via one new exported `kvm_transport_notice.dart` constant so the two cards cannot drift. Display-only guidance: no URL opened, no WebView/protocol dependency, production TLS never weakened. +5 RED→GREEN widget tests (1 behavioral confirmed RED pre-fix + 3 no-overflow at 320/800/1300); analyze 0 / 1131 passed / 1 skipped; emulator 85/85; coverage kvm 94.9%; issues validate OK. Full in-app WebView rendering + dependency acceptance remain open (platform WebView + BMC TLS/self-signed validation).

- 2026-11-19 04:00 UTC (run, agent:redfish-automation) — Partial progress (dependency-free, TLS-safe: the fail-closed launch decision layer is now production code and no longer fails open for a disabled console). The merged `webview_policy.dart` / `launch_plan.dart` flag-gated helpers were wired into production via `KvmConsole.launchPlan` (production default: WebView flag off, strict TLS) and `KvmConsoleViewerPage`'s copy target; both helpers were exported from the `kvm.dart` barrel. Fixed a real fail-open gap: `resolveRenderRoute` routed a BMC-disabled console with an HTTPS URI to `externalBrowser`, and `planConsoleLaunch` handed back the raw/padded copy-only URI. A disabled console now always fails closed to `copyOnly` (never a launchable route), and every route returns a trimmed target; self-signed acceptance stays test-only/HTTPS/in-app only, so production TLS is never weakened (+6 RED→GREEN tests across policy/plan/model). Verify analyze 0 / 1123 passed / 1 skipped; emulator 85/85; coverage kvm 94.8%; issues validate OK. Full in-app WebView rendering + dependency acceptance remain open (platform WebView + BMC TLS/self-signed validation).

- 2026-11-19 03:20 UTC (run, agent:redfish-automation) — Partial progress (dependency-free, TLS-safe transport-safety consistency across all three KVM views). `KvmConsoleViewerPage` and the per-console card already flag a plaintext-HTTP console, but the per-manager `KvmCapabilityCard` displayed its resolved console URI with no security signal — so the same unencrypted endpoint looked safe in one view and was warned about in the others. `KvmCapability` gained `hasSecureLaunchUri` / `usesInsecureHttpLaunchUri` (mirroring `KvmConsole`) and the capability card now renders an error-styled, merged-a11y "Unencrypted HTTP console URI…" warning for a plaintext-HTTP resolved URI (HTTPS/no-URI unchanged). Display-only guidance: no URL opened, no WebView/protocol dependency, production TLS never weakened. Added 1 behavioral RED→GREEN widget test + 3 no-overflow widgets + 5 model classification tests; analyze 0 / 1111 passed / 1 skipped; emulator 85/85; coverage kvm 94.4%; issues validate OK. Full in-app WebView rendering + dependency acceptance remain open (platform WebView + BMC TLS/self-signed validation).

- 2026-11-18 09:31 UTC (run, agent:redfish-automation) — Partial progress (non-dependency, TLS-safe slice): centralised KVM launch decisions into a deterministic `KvmLaunchStrategy` model (`KvmConsole.launchStrategy`) plus a single pure `kvmLaunchStatusText()` resolver used as the viewer's one visible/announced status string. Decision priority: no URI → disabled service → plaintext-HTTP HTML5 (blocked) → in-app HTML5 (HTTPS) → external-protocol client → secure HTTPS non-HTML5 browser → fallback. This fills two previously-missing guidance branches: a disabled console now says "This console service is disabled on the BMC…" (the #009 "KVM disabled on BMC" helper), and an HTTPS non-HTML5 console now suggests a **secure** external browser (never offered for plaintext HTTP — TLS is never weakened). Also fixed a real matching bug: `supportsHtml5` previously did an exact `contains('HTML5')`, so a BMC emitting `html5` / ` HTML5 ` silently skipped the in-app HTML5 path; matching is now case-insensitive + trimmed (RED proof confirmed: 1 test failed against the pre-fix getter, GREEN after). No WebView/protocol dependency added; no production TLS weakened. Added 10 model tests (incl. RED→GREEN case-insensitive HTML5, per-strategy classification, preserved-verbatim original guidance) and 2 viewer widget tests (disabled + secure-browser, visible text == announced label). Full "renders in-app" and "dependency added" acceptance boxes remain open pending platform WebView + BMC TLS/self-signed validation.
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
