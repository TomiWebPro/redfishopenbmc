# Queue rf-ui (enabled in phase 2)

Owns: `lib/features/kvm/views/**`, `lib/features/systems/**` widgets.
Verify: widget tests (320/800/1300 no-overflow, visible text == announced Semantics).

## Backlog (head first)

<!-- rf-ideate split 2026-11-20 13:04 UTC: re-scopes the still-open fullscreen + input-forwarding
      disclosure portion of the #009 rendering epic (EP-U1 scaffold) as one unblocked, display-only,
      dependency-free, TLS-safe dept slice. EP-U4 wired session lifecycle, EP-U5/U7/U8 pinned launch
      status / notices / affordance; nothing pins that the viewer's "keyboard/mouse forwarded until
      disconnect" + "fullscreen / back = disconnect" guidance is one merged a11y node with visible ==
      announced on every surface. Audit first; fix only a genuine divergence via RED→GREEN; no copy
      churn. The blocked in-app embed / WebView adapter (EP-U2) stays human-gated and is NOT re-split.
      No code touched. -->

- [ ] EP-U9 Fullscreen + input-forwarding disclosure a11y contract for #009/#021: pin that
      `KvmConsoleViewerPage` discloses the keyboard/mouse-forwarding and fullscreen/back = disconnect
      guidance as a single merged `excludeSemantics` node whose visible `Text` equals the announced
      label, consistently on the secure-HTTPS, external-client and no-URI viewer paths, with no
      duplicate/stale copy and no overflow at 320/800/1300 px. Fix the FIRST real divergence via
      RED→GREEN widget tests; do not manufacture copy churn where a surface already announces the
      guidance correctly. No WebView / url_launcher import in the product build, no URL opened, no
      dependency, no TLS change.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart && flutter analyze` (0 issues),
              RED→GREEN widget proof for any fixed divergence; merged a11y + 320/800/1300 no-overflow;
              writes limited to `lib/features/kvm/views/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 09:00 UTC: splits the machine-checkable half of the still-open
     launch-button/fullscreen portion of the #009 rendering epic (externally blocked on WebView).
     EP-U5 pinned launch-status COPY parity, EP-U6 pinned safe-source display, but nothing pins that
     the actionable "Open console" AFFORDANCE itself is gated on the single `canOpenConsole` source
     across all surfaces. Display-only, dependency-free, TLS-safe; distinct from EP-U1/U2 (scaffold/
     embed) and EP-U5 (copy parity). -->

- [x] EP-U8 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-U8 open-affordance gating invariant + 320px primary-header overflow fix + RED→GREEN widget tests`). Open-affordance gating invariant across all KVM surfaces: add merged-a11y widget tests
      asserting the actionable "Open console"/launch affordance is present ONLY for a console with
      `canOpenConsole == true` (control-safe, enabled, launchable target) and is absent/disabled for
      no-URI, disabled, plaintext-HTTP and control-unsafe consoles on the gated list card, the
      capability card and the viewer — with no URL opened and visible text == announced label. Fix
      the FIRST real divergence via RED→GREEN widget tests; do not manufacture churn where a surface
      already gates correctly. 320/800/1300 px no-overflow on every audited surface. No WebView /
      url_launcher import in the product build, no dependency, no TLS change.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
              (0 issues), RED→GREEN widget proof for any fixed divergence; merged a11y + 320/800/1300
              no-overflow; writes limited to `lib/features/kvm/views/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 04:56 UTC: closes out the FUTUREWORK-named "RU-2 full merged-
     Semantics audit" next slice. RU-2's two canonical notices are already mechanically pinned by
     `notice_single_source_guard_test.dart` (constants) and EP-T9's launch-status guard, but the
     RENDERING contract — each notice present exactly where it belongs, once, merged, visible ==
     announced — was never audited across all four KVM surfaces. Display-only, dependency-free,
     TLS-safe; distinct from RU-2 (constant single-source) and EP-U5/U6 (single-surface fixes). -->

- [x] EP-U7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-U7 RU-2 full merged-Semantics surface audit + RED→GREEN widget tests`, analyze 0 / 1603 passed / 1 skipped). RU-2 full merged-Semantics surface audit (closeout of the FUTUREWORK "RU-2 full merged-
      Semantics audit" slice): audit EVERY KVM surface — the gated list `KvmView`, per-console
      `_ConsoleCard`, `KvmCapabilityCard`, and `KvmConsoleViewerPage` — for the two shared notices
      `kvmSessionPersistenceNotice` and `kvmDisabledOnBmcNotice`. Each must appear exactly where it
      belongs as one merged `excludeSemantics` node with visible text == announced label, never
      duplicated or stale. Fix the FIRST real divergence found via RED→GREEN widget tests; do not
      manufacture copy churn where a surface already announces the shared constant correctly.
      320/800/1300 px no-overflow on every audited surface. No WebView import, no dependency, no TLS
      change, no URL opened.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
              (0 issues), RED→GREEN widget proof for any fixed divergence; merged a11y + 320/800/
              1300 no-overflow; writes limited to `lib/features/kvm/views/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the UI half of the remaining cross-surface
     "control-safe manager source" portion of the open #009/#021 epic. Three surfaces still
     interpolate the raw BMC-supplied `sourceManagerUri` directly into visible Text + merged
     Semantics labels — the viewer's "No direct console URI. Manager source: …" and both cards'
     manager-source rows — so a control-unsafe `@odata.id` can reach the screen/a11y tree even
     though CB-1 already gated the CARD clipboard path. Display-only, dependency-free, TLS-safe;
     distinct from EP-U5 (launch-status parity) and CB-1 (clipboard). Soft-depends on RM-4 for the
     capability getter but has a local-gate fallback, so it is never blocked. -->

- [x] EP-U6 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-U6 control-safe manager-source display on all three KVM surfaces + RED→GREEN widget tests`). Control-safe manager-source display on all three KVM surfaces: route the viewer's
      "No direct console URI. Manager source: …" row and the per-console / per-manager capability
      cards' manager-source rows through the shared control-safe source (`KvmConsole.safeManagerUri`,
      and `KvmCapability.safeManagerUri` if RM-4 has landed; otherwise use `isControlSafeConsoleUri`
      locally without editing model paths). A control-unsafe source must not render raw CRLF / NUL /
      separator / malformed-`%` code points in visible Text or the merged `excludeSemantics` label;
      a control-safe source stays byte-for-byte. Keep visible text == announced label on every
      surface, 320/800/1300 px no-overflow, and leave the raw endpoint visible-but-sanitized (fail
      closed, not hidden). No WebView import, no dependency, no TLS change, no URL opened.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
              (0 issues), with RED→GREEN widget proof (a hostile `@odata.id` source renders no raw
              control code point); merged a11y + 320/800/1300 no-overflow; writes limited to
              `lib/features/kvm/views/**`; `git diff --exit-code -- pubspec.yaml`.

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
- 2026-11-20 04:06 — RU-2 single-source guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/notice_single_source_guard_test.dart` (6 tests) that parses the six canonical notices from `kvm_transport_notice.dart` at test time and fails closed if any other product KVM view hardcodes a notice literal (cross-surface screen-reader copy drift) or redefines a canonical constant name. 2 RED + 2 GREEN proofs, real-repo view scan clean; analyze 0 / 1445 passed / 1 skipped. Test-only; no lib/TLS/dependency change. RU-2 stays open: the mechanical single-source invariant is now pinned, the full merged-Semantics surface audit (both notices on both surfaces) remains.


- 2026-11-19 22:49 — EP-U5 LANDED (agent:redfish-automation, FEATURE #009/#021): the first real divergence was the `disabled` strategy — the viewer showed the shared actionable `kvmLaunchStatusText(disabled)` "enable KVM on BMC" message, but the per-console card gave only a bare "Disabled" chip and no next step. `_ConsoleCard` now renders that same shared string as one merged `excludeSemantics` node (visible text == announced label), error-styled, gated only on `disabled`. The `insecureHttp` path was already covered on the card by the distinct, documented `kvmInsecureTransportNotice` ("configure HTTPS first", no in-app render, no TLS weakening), so per "do not manufacture copy churn where the surfaces already agree" it was left as is. +1 RED→GREEN widget test (no overflow at 320/800/1300 px), analyze 0 / 1350 passed / 1 skipped, DMTF emulator 85/85 (lib changed). No dependency, no wire/TLS change.
- 2026-11-19 20:07 — EP-U4 closeout LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsoleViewerPage` no longer caches a local `_sessionActive` flag; it watches `kvmSessionProvider` and derives active/idle disclosure + Disconnect enablement from shared session ownership (`isConnected && activeManagerId == console.managerId.trim()`), re-checking ownership in the button and `PopScope` callbacks so an evicted viewer cannot end a newer console's session. +3 RED→GREEN widget tests (all confirmed RED pre-fix), 320 px no-overflow; analyze 0 / 1316 passed / 1 skipped; DMTF emulator 85/85 (lib changed). No dependency, no wire/transport change, no production TLS weakening.
- 2026-11-19 16:31 — EP-U3 (external-client protocol-guidance portion) LANDED (agent:redfish-automation, FEATURE #009/#021): added pure `kvmExternalClientNoticeFor(protocol)` in `kvm_transport_notice.dart` (blank/unknown → generic fallback) as the single source of truth and wired both the per-console card (`kvm_view.dart`) and capability card (`kvm_capability_card.dart`) external-client rows to it, so all three surfaces (viewer + both cards) name the specific external client from the shared `externalClientProtocolLabel`. +9 RED→GREEN widget tests (VNC/RFB + SSH + IPMI; 320/800/1300 px), analyze 0 / 1257 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 15:35 — EP-U3 (capability-card portion) LANDED (agent:redfish-automation, FEATURE #009/#021): the capability card now renders the shared `kvmExternalClientNotice` for a resolved VNC/RFB/KVMIP/serial endpoint (merged a11y, visible text == announced label, no overflow at 320/800/1300 px); +1 RED→GREEN widget test, analyze 0 / 1248 passed / 1 skipped, emulator 85/85. Full EP-U3 viewer↔capability string unification remains for a future slice.
- 2026-11-19 14:11 — EP-U4 LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsoleViewerPage` now owns the pure-UI session lifecycle — `ConsumerStatefulWidget` connects on enter (with `maxConcurrentSessions` eviction), a merged-a11y active/idle disclosure + "Disconnect console" button end it on demand, and `PopScope.onPopInvokedWithResult` ends it on back/pop. +5 RED→GREEN viewer widget tests, 320 px no-overflow; analyze 0 / 1231 passed / 1 skipped, emulator 85/85. No WebView/protocol dependency, no TLS change.
