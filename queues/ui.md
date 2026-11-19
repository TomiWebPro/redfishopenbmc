# Queue rf-ui (enabled in phase 2)

Owns: `lib/features/kvm/views/**`, `lib/features/systems/**` widgets.
Verify: widget tests (320/800/1300 no-overflow, visible text == announced Semantics).

## Backlog (head first)

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
