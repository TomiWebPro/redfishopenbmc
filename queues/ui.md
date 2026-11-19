# Queue rf-ui (enabled in phase 2)

Owns: `lib/features/kvm/views/**`, `lib/features/systems/**` widgets.
Verify: widget tests (320/800/1300 no-overflow, visible text == announced Semantics).

## Backlog (head first)

<!-- rf-ideate split 2026-11-19 20:47 UTC: unblocked cross-surface guidance slice of the #009/#021
     final-route epic (external-browser + copy; EP-P1 resolved). Complements EP-U3 (external-client
     guidance) and EP-U4 (session ownership) without duplicating them. No WebView import, no
     dependency, no TLS change. -->

- [x] EP-U5 LANDED 2026-11-19 (run `auto: FEATURE #009/#021 EP-U5 disabled-console launch-status parity + widget test`). Launch-status parity for the `insecureHttp` and `disabled` strategies across the
      viewer and the per-console card: both surfaces must derive their visible copy from the
      single `kvmLaunchStatusText` source of truth for a plaintext-HTTP console ("configure HTTPS
      first", never an open affordance) and a BMC-disabled console ("enable KVM on BMC", no
      "Open console"), with merged `excludeSemantics` labels where visible text == announced
      label and 320/800/1300 px no-overflow. Fix the first real divergence found via RED→GREEN
      widget tests; do not manufacture copy churn where the surfaces already agree.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof; merged a11y + 320/800/1300 no-overflow; writes limited to
              `lib/features/kvm/views/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-19 12:37 UTC: slices the still-open fullscreen/session portion of the
     #009 rendering epic into an unblocked UI item (EP-U1 is the scaffold/disclosure note; this is
     the session-lifecycle wiring). No WebView, no url_launcher, no Redfish call. -->

- [ ] EP-U4 Final-route fullscreen session lifecycle: wire `KvmConsoleViewerPage`'s fullscreen/back
      flow to the pure-UI `KvmSessionController` so entering fullscreen marks the session active
      (`activeManagerId` / `connectedSince`) and back/exit calls `disconnect()`; add one a11y
      "connected · disconnect" disclosure (visible text == announced Semantics, merged `excludeSemantics`
      node) and 320/800/1300 no-overflow. No WebView/url_launcher import, no TLS change, no Redfish
      call.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_session_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; visible text == announced Semantics + 320/800/1300
              no-overflow; writes limited to `lib/features/kvm/views/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 RESOLVED (no embedded WebView; external-browser +
     copy is final). EP-U2 is DEFERRED pending manual per-target validation evidence — do NOT pick it
     up unattended. New head-first, unblocked, dependency-free, TLS-safe UI slices of #009/#021. -->

- [ ] EP-U3 Launch-guidance consistency for the final external-browser + copy route across the
      viewer and capability card: one shared, tested guidance string so a secure-HTTPS console says
      "open via BMC web UI", a plaintext-HTTP console gets only the "configure HTTPS" warning, and an
      external-client console shows its protocol guidance — identical visible text == announced
      Semantics on both surfaces at 320/800/1300. No WebView import in the product build.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart && flutter analyze` (0 issues);
              merged a11y + 320/800/1300 no-overflow; writes limited to `lib/features/kvm/views/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): in-app console rendering UI.
     Unblocked scaffolds first; embed gated on EP-P1. Every item carries the mandatory
     Dept:/Verify: fields (MULTI_DEPT hard rule #4). Legacy RU-1 is refined by EP-U1. -->

- [ ] EP-U1 Fullscreen scaffold + keyboard/mouse-forwarding disclosure note for the KVM console
      viewer (the fullscreen AppBar toggle + "back = disconnect" guidance from #009), gated on a
      `features.kvm==true` manager. Pure UI + a11y; no WebView import in the product build.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart && flutter analyze` (0 issues);
              320/800/1300 no-overflow and visible text == announced Semantics label.

- [ ] EP-U2 (after EP-P1) Wire `KvmLaunchButton` → `KvmEmbed` placeholder to the platform opt-in
      flag by consuming the EP-P2 adapter: in-app embed only when EP-P1 validated AND flag on;
      otherwise keep the existing external-browser/open + copy fallback unchanged.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart && flutter analyze` (0 issues);
              flagged/unflagged branches + 320/800/1300 a11y; no unconditional WebView import in `lib/`.

- [ ] RU-2 Session-note / disabled-helper copy consistency across both KVM views — make the
      viewer and capability card announce identical visible text for "console persists until
      manager timeout" and "KVM disabled on BMC", with merged-Semantics widget tests.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart && flutter analyze` (0 issues);
              visible text == announced Semantics label at 320/800/1300; writes limited to
              `lib/features/kvm/views/**`.

## Log

- 2026-11-19 22:49 — EP-U5 LANDED (agent:redfish-automation, FEATURE #009/#021): the first real divergence was the `disabled` strategy — the viewer showed the shared actionable `kvmLaunchStatusText(disabled)` "enable KVM on BMC" message, but the per-console card gave only a bare "Disabled" chip and no next step. `_ConsoleCard` now renders that same shared string as one merged `excludeSemantics` node (visible text == announced label), error-styled, gated only on `disabled`. The `insecureHttp` path was already covered on the card by the distinct, documented `kvmInsecureTransportNotice` ("configure HTTPS first", no in-app render, no TLS weakening), so per "do not manufacture copy churn where the surfaces already agree" it was left as is. +1 RED→GREEN widget test (no overflow at 320/800/1300 px), analyze 0 / 1350 passed / 1 skipped, DMTF emulator 85/85 (lib changed). No dependency, no wire/TLS change.
- 2026-11-19 20:07 — EP-U4 closeout LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsoleViewerPage` no longer caches a local `_sessionActive` flag; it watches `kvmSessionProvider` and derives active/idle disclosure + Disconnect enablement from shared session ownership (`isConnected && activeManagerId == console.managerId.trim()`), re-checking ownership in the button and `PopScope` callbacks so an evicted viewer cannot end a newer console's session. +3 RED→GREEN widget tests (all confirmed RED pre-fix), 320 px no-overflow; analyze 0 / 1316 passed / 1 skipped; DMTF emulator 85/85 (lib changed). No dependency, no wire/transport change, no production TLS weakening.
- 2026-11-19 16:31 — EP-U3 (external-client protocol-guidance portion) LANDED (agent:redfish-automation, FEATURE #009/#021): added pure `kvmExternalClientNoticeFor(protocol)` in `kvm_transport_notice.dart` (blank/unknown → generic fallback) as the single source of truth and wired both the per-console card (`kvm_view.dart`) and capability card (`kvm_capability_card.dart`) external-client rows to it, so all three surfaces (viewer + both cards) name the specific external client from the shared `externalClientProtocolLabel`. +9 RED→GREEN widget tests (VNC/RFB + SSH + IPMI; 320/800/1300 px), analyze 0 / 1257 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 15:35 — EP-U3 (capability-card portion) LANDED (agent:redfish-automation, FEATURE #009/#021): the capability card now renders the shared `kvmExternalClientNotice` for a resolved VNC/RFB/KVMIP/serial endpoint (merged a11y, visible text == announced label, no overflow at 320/800/1300 px); +1 RED→GREEN widget test, analyze 0 / 1248 passed / 1 skipped, emulator 85/85. Full EP-U3 viewer↔capability string unification remains for a future slice.
- 2026-11-19 14:11 — EP-U4 LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsoleViewerPage` now owns the pure-UI session lifecycle — `ConsumerStatefulWidget` connects on enter (with `maxConcurrentSessions` eviction), a merged-a11y active/idle disclosure + "Disconnect console" button end it on demand, and `PopScope.onPopInvokedWithResult` ends it on back/pop. +5 RED→GREEN viewer widget tests, 320 px no-overflow; analyze 0 / 1231 passed / 1 skipped, emulator 85/85. No WebView/protocol dependency, no TLS change.
