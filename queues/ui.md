# Queue rf-ui (enabled in phase 2)

Owns: `lib/features/kvm/views/**`, `lib/features/systems/**` widgets.
Verify: widget tests (320/800/1300 no-overflow, visible text == announced Semantics).

## Backlog (head first)

<!-- rf-ideate split 2026-11-23 22:45 UTC: another fresh, display-only, unblocked slice of the still-open
     #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U22 pins bidi/RTL control
     CHARACTERS inside display strings, EP-U23/EP-U25 pin long-name/Primary-badge text, but nothing
     renders both real operator cards AND the viewer under a widget RTL `Directionality`
     (`TextDirection.rtl`) locale: a physical-order chip reflow, a mirrored split a11y node or a
     duplicate announcement could slip past every LTR-only surface suite. Display-only; the human-gated
     WebView/TLS rendering stays gated and is NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine
     divergence, never churn. No code touched. -->

- [x] EP-U28 LANDED 2026-11-24 (run `auto: FEATURE #009/#021 EP-U28 RTL-locale rendering agreement across both cards + the viewer + RED->GREEN tests`, test-only) — AUDIT FIRST confirmed all three surfaces build visible text + merged `excludeSemantics` labels from one byte-exact model string in logical order and use `Wrap`/`Column`, so no live divergence; genuine unguarded seam = ZERO RTL coverage (all widget suites LTR-only). Added `test/features/kvm/kvm_rtl_rendering_agreement_test.dart` (5 tests) driving both real cards + the viewer under LTR and RTL at 320/800/1300 px, pinning byte-identical chip sequences + merged announcement sets + one visible chip instance + unchanged Primary/copied-URI/copy affordance + no overflow. REAL RED: reversed the capability-card chip loop under RTL under a 600-perm backup → exactly 3 named failures (the 3 RTL width tests), 2 GREEN; LTR-only sibling EP-U24 stayed 4/4 GREEN; source restored byte-clean (SHA `c6c4b09abeca88169859b85a6dc3999c963c9acd50b3ffd9716a1018d74d9b00` unchanged, 0 residue, backup shredded) → 5/5 targeted GREEN; analyze 0; full suite 2793 passed / 1 skipped; issues validate OK; diff --check clean; deps unchanged; empty `lib/` diff; emulator skipped (test-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. This guard is NOT yet epoch-registered in `guard_suite_liveness_test.dart` — defer to the next EP-T liveness pass. Original item: EP-U28 RTL-locale rendering agreement across both cards and the viewer:
       render one manager (secure graphical console + distinct connect-type chips + a connection URI)
       through both real operator cards and `KvmConsoleViewerPage` under both `Directionality.ltr` and
       RTL `Directionality` (`TextDirection.rtl`), at 320/800/1300 px, pinning that each surface keeps
       exactly one merged `excludeSemantics` node with visible text == announced label, the chip/badge/
       URI set is identical between LTR and RTL (logical order preserved, no chip loss or duplicate /
       screen-reader-only node), the same control-safe URI is copied, and no surface overflows.
       AUDIT FIRST: if the widgets already build labels from one model string in logical order under both
       directions, record the audit and add nothing; RED->GREEN only on a genuine divergence, never
       churn. Display-only; no WebView/protocol import, no URL opened, no production TLS weakening.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/views/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no WebView/protocol import, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 18:43 UTC: another fresh, display-only, unblocked slice of the still-open
     #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U24 pins ONE long unbreakable
     connect-type chip and EP-U11/EP-U23 pin card/viewer agreement for a small console set, but nothing
     pumps a DENSE set of 12+ hostile / fullwidth / confusable `ConnectTypesSupported` tokens through BOTH
     real operator cards AND the viewer at once: a one-sided chip cap, a wrap reflow, or a split a11y
     node could overflow or announce a different chip set while every launch-target suite stays GREEN.
     Display-only; the human-gated WebView/TLS rendering stays gated and is NOT re-split. AUDIT FIRST;
     RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [ ] EP-U27 Dense hostile-connect-type chip-set no-overflow + single-merged a11y agreement across both
       cards and the viewer:
       pump one manager whose console(s) expose 12+ `ConnectTypesSupported` tokens (mixed-case ASCII,
       fullwidth forms, Unicode confusables, padded/duplicate/empty tokens) through both real operator
       cards and the viewer at 320/800/1300 px, pinning that no `RenderFlex` overflow occurs, each card's
       chip row is one merged `excludeSemantics` node whose visible text == announced label (no
       screen-reader-only or split chip), the rendered chip count/content agrees across both cards and
       the model, and no chip silently collapses into a canonical `KVMIP`/`HTML5` token. Include a small
       clean control proving the normal chip row is unchanged. AUDIT FIRST: if all three surfaces render
       the same model-derived chip list with merged semantics and already handle 12+ tokens, record the
       audit and add nothing; RED->GREEN only on a genuine divergence, never churn. Display-only;
       test-only writes.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_cross_surface_agreement_test.dart test/features/kvm/kvm_widget_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/views/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no WebView/protocol import, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 14:39 UTC: another fresh, display-only, unblocked slice of the still-open
     #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U8 pins the copy affordance
     on the card, EP-U14 pins the viewer URI-row/clipboard and EP-U12 pins cross-surface clipboard
     targets, but nothing drives ONE control-unsafe / launch-unsafe `ConnectUri` through BOTH operator
     cards AND the viewer at once: a one-sided edit could hide "Copy connect info" on one surface, or
     split/duplicate its merged a11y node, while every launch-target suite stays GREEN. Display-only;
     the human-gated WebView/TLS rendering stays gated and is NOT re-split. AUDIT FIRST; RED->GREEN only
     on a genuine divergence, never churn. No code touched. -->

- [ ] EP-U26 Copy-affordance fail-closed single-merged a11y agreement across both cards and the viewer:
       pump one manager whose only console carries a control-unsafe `ConnectUri` (CRLF/NUL/bidi) through
       both real operator cards and the viewer at 320/800/1300 px, pinning that the "Copy connect info"
       affordance is present and actionable (fail closed — never hidden because the URI is launch-unsafe)
       on all three surfaces, its visible text == announced label inside ONE merged `excludeSemantics`
       node per surface (no screen-reader-only duplicate or split label), no launch/"Open console"
       affordance is offered for the unsafe target, and no `RenderFlex` overflow. Include a clean
       secure-HTTPS control proving the copy affordance stays present there too. AUDIT FIRST: if all
       three surfaces derive the copy affordance from the same fail-closed source with merged semantics,
       record the audit and add nothing; RED->GREEN only on a genuine divergence, never churn.
       Display-only; test-only writes.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_cross_surface_agreement_test.dart test/features/kvm/kvm_widget_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/views/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no WebView/protocol import, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 10:35 UTC: another fresh, display-only, unblocked slice of the still-open
     #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U15 pins a Primary badge on
     one card and EP-U8 pins the open-affordance gate, but nothing pins the "Primary" badge as a single
     merged, announced signal across BOTH operator cards AND the viewer: a one-sided edit could render
     it twice, on a non-Primary card, or as a screen-reader-only duplicate while every launch-target
     suite stays GREEN. Display-only; the human-gated WebView/TLS rendering stays gated and is NOT
     re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-U25 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-U25 Primary-badge single merged a11y agreement + RED->GREEN tests`, test-only) — Primary-badge single merged a11y agreement across both cards and the viewer:
       pump one manager with a deterministic Primary console (a secure-HTTPS graphical that wins
       `pickPrimary`) plus a non-Primary console through both real operator cards and the viewer at
       320/800/1300 px, pinning that exactly one "Primary" marker is rendered on the Primary console's
       card, NONE on the non-Primary card, visible text == announced label inside a single merged
       `excludeSemantics` node, no screen-reader-only duplicate or split label, and no `RenderFlex`
       overflow. AUDIT FIRST: if all three surfaces already derive the badge from the same model signal
       with merged semantics, record the audit and add nothing; RED->GREEN only on a genuine divergence,
       never churn. Display-only; test-only writes.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_cross_surface_agreement_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/views/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no WebView/protocol import, no URL opened, no production TLS weakening.
       LANDED 2026-11-23: added `test/features/kvm/kvm_card_primary_badge_single_merged_a11y_test.dart`
       (5 tests) driving one manager's secure-HTTPS Graphical (pickPrimary winner) + SSH Serial peer through
       the real `KvmView` at 320/800/1300 px: exactly one visible 'Primary' globally, on the winner card and
       NONE on the peer; one merged `excludeSemantics` header per console; the badge inside the winner's merged
       node; no split/screen-reader-only 'Primary' semantics node; no competing capability-card or viewer marker;
       no overflow. AUDIT: badge lives only in `_ConsoleCard`, gated by `identical(console, ui.primaryConsole)`;
       capability card + viewer render no marker — no live divergence; genuine unguarded cross-surface/three-width
       seam. Real-file RED #1: `isPrimary: true` → 3 width tests fail (count/peer), model+viewer GREEN; RED #2:
       header `excludeSemantics: true`→`false` → 3 width tests fail on the split-announcement assertion, model+viewer
       GREEN; source restored byte-clean (SHA `7359effb5ba6b963e6c2d0584bf507f1093c29ca408352cbd48a85100d7efabf`
       unchanged, 0 residue, empty `lib/` diff, 600-perm backup shredded) → 5/5 GREEN; analyze 0; full suite 2590
       passed / 1 skipped (baseline 2585 +5); issues validate OK; diff --check clean; deps unchanged; emulator
       skipped (test-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no TLS change.

<!-- rf-ideate split 2026-11-23 06:31 UTC: another fresh, display-only, unblocked slice of the still-open
     #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U20 pins an EXTREME NUMBER of
     connect-type chips at a fixed font and EP-U23 pins a long (visually-wrapping) MANAGER NAME, but nothing pins
     a single long UNBREAKABLE connect-type chip token (e.g. a 400-char vendor string with no spaces) at 320 px:
     the chip Wrap/Expanded layout could overflow the Row or split a merged a11y node while every normal-length
     chip suite stays GREEN. Display-only; the human-gated WebView/TLS rendering stays gated and is NOT re-split.
     AUDIT FIRST; RED→GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-U24 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-U24 long unbreakable connect-type chip no-overflow + single merged a11y agreement + RED->GREEN tests`, test-only) — Long unbreakable connect-type chip token
       no-overflow + single merged a11y agreement across both KVM operator cards: added
       `test/features/kvm/kvm_card_unbreakable_chip_agreement_test.dart` (4 tests) pumping one manager whose
       enabled GraphicalConsole carries a single 400-char whitespace-free vendor token plus a short control
       through both real cards at 320/800/1300 px, pinning byte-identical full chip values on both cards,
       one merged `excludeSemantics` node per card announcing the FULL token (visible clipped, announcement
       untruncated), exactly one visible token instance per card (no screen-reader-only duplicate), and no
       overflow. A fourth case drives the unbreakable token alone at 320 px. AUDIT FIRST: both cards already
       render chips through `Wrap(children:[Chip(label:Text(type))])` and `RenderChip._labelConstraintsFrom`
       gives each label a FINITE max width (bounded by the Wrap) while the Chip's `DefaultTextStyle` clips via
       `maxLines:1 / softWrap:false / overflow:fade`, so an unbreakable token is clipped to one visible instance
       rather than overflowing; both cards read the same normalized model list — no live divergence, no
       behaviour change. Genuine unguarded seam: no existing test drove a single long unbreakable token through
       BOTH cards at once (EP-U19 modest matrix, EP-U20 20+ SHORT chips, EP-U23 long MANAGER NAME).
       Characterization / regression lock, not churn. Real-file RED: one-sided truncation of long chip labels
       in `lib/features/kvm/views/kvm_capability_card.dart` only (`Text(type.length > 12 ? substring(0,12)+'…'
       : type)`, the plausible 'cap long vendor labels' refactor) under a 600-perm backup → exactly the 4 new
       EP-U24 tests failed, 12 short-chip sibling tests (EP-U19 + EP-U20) GREEN; source restored byte-clean
       (SHA `c6c4b09abeca88169859b85a6dc3999c963c9acd50b3ffd9716a1018d74d9b00` unchanged, 0 residue, empty
       `lib/` diff, backup shredded) → 4/4 targeted GREEN; analyze 0; full suite 2531 passed / 1 skipped
       (baseline 2527 +4 mine); issues validate OK; diff --check clean; deps unchanged; empty `lib/` diff;
       emulator skipped (test-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened,
       no production TLS weakening. Original item:
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_chip_session_agreement_test.dart test/features/kvm/kvm_card_cross_surface_agreement_test.dart && flutter analyze`
               (0 issues), RED→GREEN proof + 320 px no-overflow + visible==announced only on a genuine
               divergence; writes limited to `lib/features/kvm/views/**` + `test/features/kvm/**`; no WebView/
               protocol import, no URL opened, no dependency, no production TLS weakening;
               `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-23 02:27 UTC: another fresh, display-only, unblocked slice of the still-open
     #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U19/U20/U21/U22 pin
     chip/session, extreme-content, large-font and bidi RENDERED agreement, but none pins that a manager
     name long enough to be visually ELLIPSIZED / clipped at 320 px is still announced in FULL and
     byte-identically inside the single merged `excludeSemantics` node on both operator cards and the
     viewer: a one-sided edit that feeds the clipped/ellipsized text (or a second copy) into the Semantics
     label could give screen-reader users a truncated or duplicated manager identity while every
     short-name suite stays GREEN. Display-only; the human-gated WebView/TLS rendering stays gated and is
     NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-U23 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-U23 full-name announcement under visual truncation agreement + RED->GREEN tests`, test-only) — Full-name announcement agreement under visual truncation across both KVM operator cards and
       the viewer: pump one manager with a long display name (ellipsized/clipped at 320 px) plus a short
       control through both real cards and the viewer at 320/800/1300 px, pinning that the merged
       `excludeSemantics` label carries the FULL untruncated name byte-for-byte on every surface, visible
       text remains a single rendered instance with no duplicate/screen-reader-only node, and no RenderFlex
       overflow occurs. AUDIT FIRST: if every surface already announces the full model string while only
       visually clipping, record the audit and add nothing; RED->GREEN only on a genuine divergence,
       never churn. Display-only; no WebView/protocol import, no URL opened, no production TLS weakening.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_cross_surface_agreement_test.dart test/features/kvm/kvm_widget_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof + 320 px no-overflow + visible==announced only on a genuine
               divergence; writes limited to `lib/features/kvm/views/**` + `test/features/kvm/**`; no WebView/
               protocol import, no URL opened, no dependency, no production TLS weakening;
               `git diff --exit-code -- pubspec.yaml`.
      LANDED: added `test/features/kvm/kvm_card_full_name_announcement_agreement_test.dart` (6 tests) — a long hyphenated rack id + short control pumped through BOTH real cards (KvmView) and the viewer at 320/800/1300 px, pinning each merged `excludeSemantics` node carries the FULL name byte-for-byte (console "Manager: <id>", capability "Manager capability <id>, enabled, KVM supported", viewer "<type>, manager <id>"), the same full name visible exactly once per surface, no second screen-reader-only node, and no RenderFlex overflow. AUDIT — all three surfaces already build label + visible Text from the same full `${managerId}` model string (no live divergence, no behaviour change); the unguarded seam was that no test drove a long, visually-wrapping name through all three surfaces at once pinning full-byte name + single visible instance + no duplicate node + no overflow. Real-file RED: clipped the capability-card merged label to a 16-char ellipsized prefix in `lib/features/kvm/views/kvm_capability_card.dart` under a 600-perm backup → exactly `+3 -3` (the 3 "both operator cards" cases failed on all widths, the 3 viewer cases GREEN); source restored byte-clean (SHA `c6c4b09a…` unchanged, empty `lib/` diff, backup shredded) → 6/6 targeted + 121/121 sibling surface suites (Verify line + EP-U11/EP-U20/EP-U21/notice guards) GREEN. Display-only; no WebView/protocol import, no URL opened, no dependency, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 22:24 UTC: another fresh, display-only, unblocked slice of the still-open
     #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U19/U20/U21 pin chip/session,
     extreme-content and large-font RENDERED agreement, and RM-15 pins bidi/RTL fail-closed at the MODEL
     classifier — but nothing pins how a bidirectional/RTL control-bearing manager DISPLAY NAME and
     external-client notice actually RENDER across both operator cards and the viewer: a name carrying
     RLO/LRO, isolates or a word-joiner plus mixed LTR text, at 320/800/1300 px, could overflow a Row or
     produce a mirrored/split merged Semantics node whose visible text != announced label, while every
     fixed-ASCII suite stays GREEN. Display-only; the human-gated WebView/TLS rendering stays gated and is NOT
     re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-U22 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-U22 bidi/RTL display-text a11y agreement + RED->GREEN tests`, test-only, dependency-free, TLS-safe) — AUDIT FIRST: the model keeps manager ids BYTE-EXACT (no sanitisation in `lib/features/kvm/models/**` or `views/**`), so bidi/RTL control-bearing display names reach both real cards and the viewer verbatim — no live divergence. Genuine unguarded seam: EP-U23/EP-U20/EP-U25 pin long/extreme/badge display text and model guards pin bidi only in `@odata.id` URIs, but nothing drove an RLO/LRO/isolate/word-joiner DISPLAY NAME through both cards + viewer at 320/800/1300 px while pinning byte-exact full-name merged nodes, one visible instance, no mirror-induced split/duplicate node and no overflow. Added `test/features/kvm/kvm_card_bidi_display_text_a11y_agreement_test.dart` (7 tests). Real-file RED: sanitised bidi controls in the capability-card merged label only → exactly the 3 card width tests failed, fixture + 3 viewer tests GREEN (+4 -3); source restored byte-clean (SHA `c6c4b09abeca88169859b85a6dc3999c963c9acd50b3ffd9716a1018d74d9b00` unchanged, empty `lib/` diff, 600-perm backup shredded) → 7/7 targeted + 2601/1 full GREEN. Test-only; writes limited to `test/features/kvm/**`; no WebView/protocol import, no URL opened, no dependency, no production TLS weakening. Originally:
       Bidirectional/RTL display-text rendering agreement across both KVM operator cards and the
       viewer: pump one manager carrying a bidi/RTL-control-bearing (RLO/LRO, isolates, word-joiner) DISPLAY
       NAME plus an external-client (VNC/SSH) notice through both real cards and the viewer at
       320/800/1300 px, pinning no RenderFlex overflow, exactly one merged `excludeSemantics` node per active
       signal with visible text == announced label, and no mirror-induced node split or duplicate. AUDIT FIRST:
       if the model sanitizes all such text before render (so the screens only ever see clean strings), record
       the audit and add nothing; RED->GREEN only on a genuine divergence, never churn. Display-only; no
       WebView/protocol import, no production TLS weakening.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_cross_surface_agreement_test.dart test/features/kvm/kvm_external_notice_cross_surface_agreement_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence.

<!-- rf-ideate split 2026-11-22 14:17 UTC: another fresh, display-only, unblocked slice of the
      still-open #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U19 pins both
      operator cards' chip/session agreement over a MODEST hostile matrix and EP-U16/U15 pin notice/launch
      agreement, but nothing pins that the two cards stay usable when one manager carries EXTREME content:
      a very long manager name, 20+ connect-type chips, very large session-limit digits and a long resolved
      URI. A one-sided layout/wrap edit could overflow at 320 px or split a merged a11y node while every
      fixed-value suite stays GREEN. Display-only; the human-gated WebView/TLS rendering stays gated and is
      NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

<!-- rf-ideate split 2026-11-22 18:21 UTC: another display-only, unblocked slice of the still-open
      #009/#021 closeout (never-empty-well a11y, MULTI_DEPT hard rule 10). EP-U20 pins EXTREME CONTENT at
      a fixed font and EP-U8/EP-U7 pin fixed-width overflow and notice a11y, but nothing pins that the two
      operator cards and the viewer stay usable when the platform accessibility font is large: a long
      manager name, an enabled secure-HTTPS URI and an external-client (VNC/SSH) notice at textScaleFactor
      2.0 on a 320 px viewport could overflow a Row or split a merged a11y node while every fixed-font suite
      stays GREEN. Display-only; the human-gated WebView/TLS rendering stays gated and is NOT re-split.
      AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-U21 LANDED 2026-11-22 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / targeted 6/6 / full suite 2370 passed / 1 skipped / emulator 85/85, lib+test) — Large-accessibility-font no-overflow + single merged a11y node across both KVM operator
       cards and the viewer: pump one manager with a long name, an enabled secure-HTTPS connect URI and an
       external-client (VNC/SSH) console through both real cards and the viewer at textScaleFactor
       1.0 / 1.3 / 2.0 on a 320 px viewport, pinning no RenderFlex overflow, exactly one merged
       `excludeSemantics` node per active signal with visible text == announced label, and no duplicate or
       screen-reader-only copy. AUDIT FIRST: if the surfaces already scale/clip cleanly with byte-identical
       labels at every scale, record the audit and add nothing; RED->GREEN only on a genuine divergence,
       never churn. Display-only; no WebView/protocol import, no URL opened, no dependency, no production
       TLS weakening.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof + 320 px no-overflow + visible==announced only on a genuine
               divergence; writes limited to `lib/features/kvm/views/**` + `test/features/kvm/**`; no WebView/
               protocol import, no URL opened, no dependency, no production TLS weakening;
               `git diff --exit-code -- pubspec.yaml`.
       **LANDED** 2026-11-22: AUDIT first — no KVM test pumped any console/viewer row under a `textScaler`: EP-U20 covers extreme content at a fixed font, and `test/a11y/kvm_view_text_scale_test.dart` pumps only an EMPTY KvmView ("No consoles found.") at 2.0x; `a11y/power_view_text_scale_test.dart` covers PowerView only. Added `test/features/kvm/kvm_large_font_cross_surface_a11y_test.dart` (6 tests): one manager with a long name, an enabled secure-HTTPS Graphical console and an enabled SSH Serial console through both real cards and the viewer at 1.0/1.3/2.0 on a 320 px viewport, pinning one merged `excludeSemantics` node per signal with visible==announced, no duplicate/screen-reader-only notice copy, and no RenderFlex overflow. GENUINE LIVE DEFECT found and fixed: at 2.0x the per-console card's fixed `Text('Connect URI:')` + `Expanded(SelectableText)` `Row` (kvm_view.dart:506) overflowed by 91 px, leaving only one of the two cards built; changed that row to a stacked `Column` matching the capability card's resolved-URI row (merged label and both visible strings byte-identical). Real-file RED: original production code → exactly 1 named failure (`+5 -1`: 2.0x cards, 91 px RenderFlex overflow), other 5 GREEN; fix restored byte-clean (SHA `7359effb…` unchanged, 600-perm backup shredded) → 6/6 GREEN. `lib/` change ⇒ emulator re-run 85/85. Empty `pubspec` diff; no WebView/protocol import, no URL opened, no production TLS weakening. NOT yet registered in the guard-suite liveness canonical set — next run should do that.

- [x] EP-U20 LANDED 2026-11-22 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / full suite 2225 passed / 1 skipped, test-only) — Extreme-content no-overflow + single merged a11y node across both KVM operator cards: over
       one manager built into both real cards with a very long manager name, 20+ normalized connect-type
       chips, a very large `MaxConcurrentSessions` and a long control-safe resolved URI, pin that neither
       card overflows at 320 / 800 / 1300 px, that each card's chips/session/URI keep visible text == announced
       label inside one merged `excludeSemantics` node, and that the two cards agree on the shared payload
       values (chip set, session number, URI) regardless of their intentionally different prefixes. AUDIT
       FIRST: if both cards already wrap/clip extreme content with byte-identical output and no overflow,
       record the audit and add nothing; RED->GREEN only on a genuine divergence, never churn. Display-only;
       no WebView/protocol import, no URL opened, no dependency, no production TLS weakening.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_chip_session_agreement_test.dart test/features/kvm/kvm_capability_card_test.dart test/features/kvm/kvm_widget_test.dart && flutter analyze`
               (0 issues), with RED->GREEN proof + 320 px no-overflow + visible==announced only on a genuine
               divergence; writes limited to `lib/features/kvm/views/**` + those named test files; no WebView/
               protocol import, no URL opened, no dependency, no production TLS weakening;
               `git diff --exit-code -- pubspec.yaml`.
      **LANDED** 2026-11-22: AUDIT first — EP-U19 pins both cards over a modest 3-chip matrix; extreme content (24 chips / 1e9 session / long control-safe URI) on BOTH real cards was unguarded at 800/1300 px. Added test/features/kvm/kvm_card_extreme_content_agreement_test.dart (3 tests) pinning byte-identical chip sequence + session number + URI on both cards, each card's merged excludeSemantics node with visible==announced, and no overflow at 320/800/1300 px. Real-file RED: capability-card chip Wrap→Row -> all 3 new tests failed (+0 -3) while EP-U19's 3-chip matrix stayed GREEN at 800/1300 px; restored byte-clean (SHA c6c4b09a..., 600-perm backup shredded) → 3/3 GREEN. Test-only, empty lib/ diff, no dependency, no WebView/protocol import, no URL opened, no production TLS weakening. NOT yet registered in the guard-suite liveness canonical set — next run should do that.

<!-- rf-ideate split 2026-11-22 10:12 UTC: carves a fresh, display-only, unblocked slice of the
     still-open #009/#021 closeout. The model layer pins connect-type / session-limit aggregate agreement
     (RM-6/RM-8/EP-M5) and EP-U11/U15 pin rendered card agreement for RemoteConsole/disabled and launch
     targets, but nothing pins that the two KVM operator cards RENDER byte-identical connect-type chips and
     session-limit text for one manager over a hostile aggregation matrix. A one-sided view edit could desync
     the chips while every model and single-surface suite stays GREEN. Display-only; the human-gated
     WebView/TLS rendering stays gated and is NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine
     divergence, never churn. No code touched. -->

- [x] EP-U19 LANDED 2026-11-22 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / targeted 9/9 / full suite green (count in automation-tracking), test-only) — Connect-type chip + session-limit text rendered agreement across the two KVM operator cards: added `test/features/kvm/kvm_card_chip_session_agreement_test.dart` (9 tests) building BOTH real cards from ONE hostile manager body (padded/mixed-case/blank/non-string/nested ConnectTypesSupported normalizing to `['KVMIP','HTML5','SSH']` + boundary MaxConcurrentSessions 2 / 5.0 / ' 3 ') and pinning byte-identical rendered chip VALUES in the SAME ORDER on both cards, equal session-limit NUMBER, each card's own merged `excludeSemantics` node with visible==announced, and 320/800/1300 px no-overflow. AUDIT: EP-U11 pins support/URI agreement and EP-M5/RS-10 pin the model-level chip/limit normalization, but both cards' chips/session were only pinned SINGLE-surface with fixed values — no test fed the hostile matrix through BOTH rendered cards at once; genuine unguarded cross-surface seam (the two cards' Semantics prefixes differ intentionally — 'Connection types:' vs 'Supported connection types:', 'Max sessions:' vs 'Max concurrent sessions:' — so only the shared payload is pinned, cf. EP-U16's narrowed scope). TWO real-file RED proofs: (A) capability chip loop `connectTypes` → `connectTypes.reversed` → exactly the 3 chip-agreement tests failed (`+6 -3`); (B) capability session `maxSessions` → `maxSessions! + 1` → exactly the 6 session tests failed (`+3 -6`); source restored byte-clean both times (SHA `c6c4b09abeca88169859b85a6dc3999c963c9acd50b3ffd9716a1018d74d9b00` unchanged, empty lib diff), 600-perm backups shredded → 9/9 GREEN. Test-only, no lib/, no dependency, no WebView/protocol import, no URL opened, no production TLS weakening. Original item:
       over one manager built into both real cards whose enabled console block carries a hostile connect-types
       matrix (padded/mixed-case duplicates, blank/non-string/control-bearing entries) and a boundary
       `MaxConcurrentSessions` (int / integral-double / padded numeric string), pin that the per-console card
       and the capability card render byte-identical connect-type chips and session-limit text — each as one
       merged `excludeSemantics` node with visible text == announced label at 320/800/1300 px, no overflow,
       no raw control marker and no divergent chip order. AUDIT FIRST: if both cards already share one renderer
       with byte-identical output over the whole matrix, record the audit and add nothing; RED->GREEN only on
       a genuine divergence, never churn. Display-only; no WebView/protocol import, no URL opened, no
       dependency, no production TLS weakening.
       Dept: rf-ui
       Verify: `flutter test test/features/kvm/kvm_card_chip_session_agreement_test.dart test/features/kvm/kvm_capability_card_test.dart test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_card_cross_surface_agreement_test.dart && flutter analyze`
               (0 issues), with RED->GREEN proof + 320 px no-overflow + visible==announced only on a genuine
               divergence; writes limited to `lib/features/kvm/views/**` + those named test files; no WebView/
               protocol import, no URL opened, no dependency, no production TLS weakening;
               `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-22 06:09 UTC: carves a fresh, display-only, unblocked slice of the
     blocked #009/#021 final-route closeout. EP-U8/EP-U17 pin the no-WebView affordance contract and
     EP-U14 pins the viewer URI row, but nothing pins the route-dependent COPY-vs-BROWSER affordance
     split (copyOnly vs externalBrowser) as ONE contract across all three surfaces — a one-sided view
     edit could show a browser-open button on a control-unsafe target while every single-surface suite
     stays GREEN. Display-only; the human-gated WebView/TLS rendering stays gated and is NOT re-split.
     AUDIT FIRST; RED→GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-U18 LANDED 2026-11-23 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / 2609 passed / 1 skipped) — Copy-only vs browser-open route agreement across the three KVM surfaces for a
      control-unsafe resolved target: over one manager whose graphical `ConnectUri` is control/bidi-
      bearing so `planConsoleLaunch` degrades to copyOnly, pin that the viewer, the per-console card
      and the capability card all expose copy guidance and NEVER a browser-open / render affordance,
      and that a clean secure-HTTPS target yields browser-open guidance on all three — each as one
      merged `excludeSemantics` node with visible text == announced label at 320/800/1300 px and no
      overflow. AUDIT FIRST: if EP-U8/EP-U17/EP-U14 already pin both routes on all three surfaces,
      record the audit and add nothing; RED→GREEN only on a genuine divergence, never churn.
      Display-only; no WebView/protocol import, no URL opened, no dependency, no production TLS
      weakening.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_open_affordance_gating_test.dart test/features/kvm/kvm_three_surface_launch_target_agreement_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof + 320 px no-overflow + visible==announced only on a
              genuine divergence; writes limited to `lib/features/kvm/views/**` + those named test
              files; no WebView/protocol import, no URL opened, no dependency, no production TLS
              weakening; `git diff --exit-code -- pubspec.yaml`.
       LANDED 2026-11-23: AUDIT FIRST — EP-U8 pins the gated-list card's "Open console" gate on a
       single CRLF console, EP-U17 pins no-render/TLS + generic copy guidance on all three surfaces
       but only for CLEAN targets, and EP-U15 pins the three-surface launch target; nothing drove ONE
       control-bearing graphical manager through the per-console card + capability card + viewer
       together pinning the copy-only route. Genuine unguarded seam, no live divergence, no churn.
       The capability card is display-only and prints no browser guidance for a clean secure target
       by design, so the positive half is honestly narrowed (EP-U16 precedent): the viewer's
       single-source `kvmLaunchStatusText` + the console card's "open via BMC web UI" hint carry the
       browser-open guidance, the capability card keeps its merged resolved-URI copy row. Added
       `test/features/kvm/kvm_copy_only_browser_open_route_agreement_test.dart` (8 tests): 2 model
       route-agreement pins (unsafe→copyOnly/targetUri null on console+capability; safe→browser-open
       + openable) + 3×2 rendered tests at 320/800/1300 px. For the control-unsafe target: no
       browser-open/render affordance on any surface, console card has no "Open console" but keeps
       "Copy connect info", capability card keeps the merged "Resolved URI" row, viewer keeps the
       merged "No direct console URI" + fail-closed status and no copy affordance. For the clean
       target: merged copy + browser guidance preserved on all three. Real-file RED: added a
       "Open in browser" Semantics+Text to the capability card for any resolved URI (a plausible
       one-sided edit no existing guard forbids) under a 600-perm backup → exactly the 3
       control-unsafe rendered tests failed (`+5 -3`: browser-open guidance caught), 2 model + 3
       clean-target tests GREEN, and all 57 sibling guard tests in
       `kvm_open_affordance_gating_test.dart` / `kvm_three_surface_launch_target_agreement_test.dart`
       / `kvm_capability_card_test.dart` stayed GREEN; source restored byte-clean (SHA
       `c6c4b09abeca88169859b85a6dc3999c963c9acd50b3ffd9716a1018d74d9b00` unchanged, empty `lib/`
       diff, backup shredded) → 8/8 targeted GREEN. Test-only, dependency-free, TLS-safe; no
       WebView/protocol import, no URL opened, no production TLS weakening. Needs a future EP-T-style
       liveness registration.

<!-- rf-ideate split 2026-11-22 02:06 UTC: splits the display half of the human-gated WebView/TLS
     rendering closeout (blocked on platform validation) of #009/#021 into one unblocked,
     display-only, dependency-free, TLS-safe dept slice. EP-U2/EP-U4/EP-U8 pin the viewer launch
     affordance and external-client notices and EP-U14 pins the viewer URI row, but nothing pins as
     ONE contract that the no-WebView final route (external-browser + copy under productionDefault)
     never renders an in-app "render"/self-signed-accept affordance on any of the three surfaces.
     A one-sided view edit could reintroduce a launch/render button with every single-surface suite
     green. AUDIT FIRST: if all three surfaces already expose only copy + browser-open guidance,
     record the audit and add nothing; RED→GREEN only on a genuine divergence, never churn. Human-
     gated WebView/TLS rendering stays gated and is NOT re-split. No code touched. -->

- [x] EP-U17 LANDED 2026-11-22 — No-WebView final-route viewer affordance agreement guard (display half of the blocked
      rendering closeout): over a rendered console whose launch plan is external-browser/copy
      (productionDefault, no WebView), pin that the viewer and both operator cards expose copy +
      browser-open guidance and NEVER an in-app render button or a self-signed-accept affordance,
      each as one merged `excludeSemantics` node with visible text == announced label at
      320/800/1300 px and no overflow. AUDIT FIRST: if EP-U2/EP-U4/EP-U8 already pin these
      affordances on all three surfaces, record the audit and add nothing; RED→GREEN only on a
      genuine divergence, never churn. Display-only; no WebView/protocol import, no URL opened, no
      dependency, no production TLS weakening.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_open_affordance_gating_test.dart test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof + 320 px no-overflow + visible==announced only on a
              genuine divergence; writes limited to `lib/features/kvm/views/**` + those named test
              files; no WebView/protocol import, no URL opened, no dependency, no production TLS
              weakening; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 22:03 UTC: splits a residual display-surface agreement seam of the
     blocked #009/#021 external-client epic into one unblocked, display-only, dependency-free,
     TLS-safe dept slice. The protocol-specific `kvmExternalClientNoticeFor` copy is single-sourced
     in `kvm_transport_notice.dart` and pinned at the helper/string level, and EP-U7/EP-U12 pin the
     shared-notice surfaces and card<->viewer clipboard agreement; nothing pins that the
     PROTOCOL-SPECIFIC external-client notice and its control-safe URI row are rendered identically
     (visible == announced, one merged `excludeSemantics` node) across BOTH cards and the viewer
     when the protocol label is hostile (control/CRLF-bearing) and falls back to the generic notice.
     A one-sided view edit could show the protocol-specific wording on one card but the generic on
     another, or split a control-bearing value into a screen-reader label, with each single-surface
     suite green. AUDIT FIRST: if all surfaces already share the helper correctly, record the audit
     and do NOT manufacture a test; RED→GREEN only on a genuine divergence, never churn. Human-gated
     WebView/TLS rendering stays gated and is NOT re-split. No code touched. -->

- [x] EP-U16 LANDED 2026-11-22 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / 2027 passed / 1 skipped) — cross-card protocol-specific external-client notice RENDERED-agreement guard: added `test/features/kvm/kvm_external_notice_cross_surface_agreement_test.dart` (28 tests) pumping ONE manager body per external scheme (vnc/rfb/kvmip/kvm/ssh/telnet/ipmi) through BOTH `KvmConsole.fromManager` + `KvmCapability.fromManager` into one `KvmView`, pinning byte-identical `kvmExternalClientNoticeFor(label)` wording on the per-console card and the capability card (one merged `excludeSemantics` node each, visible==announced, no generic-fallback/plaintext-HTTP/injection leak, no overflow) at 320/800/1300 px + model-label agreement for all 7 schemes. AUDIT: both cards already share the helper with agreeing fromManager labels — genuine unguarded RENDERED cross-card seam (single-surface suites cover one card each, vnc/ssh/ipmi only; EP-M2/RM-12 pin labels at model layer), regression guard not churn. Real-file RED: console card notice → generic constant → 21 rendered-agreement cases failed (`+7 -21`); source restored byte-clean (SHA `60be27a4…` unchanged, empty lib diff), 600-perm backup shredded → 28/28 GREEN. Registered in `canonicalGuardFiles` + pinned `epU16AddedGuards` epoch set (length 1, disjoint) in `test/tool/guard_suite_liveness_test.dart` (+1 pin test). Test/tool-only, no lib/, no dependency, no WebView/protocol import, no production TLS weakening. NOTE: the viewer intentionally uses the distinct `kvmLaunchStatusText` guidance (documented in `kvm_transport_notice.dart`), so "same wording on the viewer" is NOT enforced — the dept-head phrasing is narrowed to the two operator launch cards that share the notice helper. Original item:
      Protocol-specific external-client notice + control-safe URI display agreement across
      both cards and the viewer: over one manager whose resolved console endpoint needs an external
      client, pin that the per-console card, the per-manager capability card and the viewer all
      render the SAME `kvmExternalClientNoticeFor(protocol)` wording and the SAME control-safe URI
      row — one merged `excludeSemantics` node per surface with visible text == announced label at
      320/800/1300 px, no overflow — for a canonical protocol label (`VNC/RFB`, `SSH`, `IPMI
      serial-over-LAN`), a padded/mixed-case label, and a control/CRLF-bearing label that must fall
      back to the generic notice with no launch affordance and no injection marker. AUDIT FIRST; fix
      only a genuine divergence via RED→GREEN widget tests, no churn. Display-only; no WebView/
      protocol import, no URL opened, no dependency, no production TLS weakening.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart test/features/kvm/kvm_webui_hint_external_client_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof + 320 px no-overflow + visible==announced only on a
              genuine divergence; writes limited to `lib/features/kvm/views/**` + those named test
              files; no WebView/protocol import, no production TLS weakening; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 17:59 UTC: splits a residual display-surface agreement seam of the
     blocked #009/#021 launch-target epic into one unblocked, widget-level, dependency-free, TLS-safe
     dept slice. EP-S7 (18:52) made the capability card's resolved secure-HTTPS URI agree with the
     `pickPrimary`-selected "Primary" console, and EP-U14 pins the viewer's OWN four renderings of one
     `launchPlan.targetUri`; but nothing pins that the THREE operator-visible launch surfaces for ONE
     manager — the "Primary" badge's target on the console card, the capability card's resolved URI,
     and the viewer's "Open console" target — all carry the SAME security-first secure-HTTPS target.
     A one-sided card/badge edit could advertise one endpoint while the viewer opens another, with every
     single-surface test GREEN — the exact #009 divergence class. Display-only; audit first, RED→GREEN
     only on a genuine divergence, no churn. Human-gated WebView/TLS rendering stays gated and is NOT
     re-split. No code touched. -->

- [x] EP-U15 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-U15 three-surface launch-target agreement guard + RED->GREEN tests`, analyze 0 / 1973 passed / 1 skipped, test-only) — Three-surface launch-target agreement (Primary badge ↔ capability card ↔ viewer) for one
      manager: over a multi-block manager (disabled Graphical + serial SSH + secure-HTTPS Remote, plus a
      padded/hostile-authority variant) built once into `KvmConsole` / `KvmCapability`, pin that the
      console card's "Primary" badge target, the capability card's resolved URI row and the viewer's
      "Open console" target are all byte-identical, control/injection-free, and the secure-HTTPS endpoint
      — never a raw CRLF/NUL/control-bearing value, and each affordance present iff a safe target exists.
      Every merged a11y node keeps visible text == announced label at 320/800/1300 px with no overflow.
      Display-only; no WebView/protocol import, no URL opened, no dependency, no production TLS weakening.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof + 320 px no-overflow + visible==announced only on a genuine
              divergence; writes limited to `lib/features/kvm/views/**`; no WebView/protocol import, no
              production TLS weakening; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 14:10 UTC: splits a residual viewer copy-surface seam of the blocked
     #009/#021 epic into one unblocked, display-only, dependency-free, TLS-safe dept slice. EP-U8
     pins the open-affordance gate, EP-U12 pins that the CARD's "Copy connect info" and the VIEWER's
     "Copy console URI" place the same fail-closed clipboard target, and EP-T8/EP-U6 pin raw-source
     display — but nothing pins the viewer's OWN three renderings of that target as one contract:
     the merged-a11y "Console URI: …" row's `SelectableText` + `label`, the `Clipboard.setData`
     payload, and the "Copied: …" `SnackBar` text must all carry the SAME fail-closed
     `launchPlan.targetUri` (never a raw CRLF/NUL/control-bearing value), and the row/copy affordance
     must be present iff a safe target exists. A one-sided edit could leak a control-bearing string
     into the SnackBar or a11y label while the clipboard stayed safe. Audit first; RED→GREEN only on
     a genuine divergence; no churn. Human-gated WebView/TLS rendering stays gated and is NOT
     re-split. No code touched. -->

- [x] EP-U14 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-U14 viewer URI-row/clipboard/SnackBar fail-closed agreement guard + RED->GREEN tests`, analyze 0 / 1930 passed / 1 skipped, test-only) — Viewer URI-row / clipboard / copy-SnackBar fail-closed agreement: pin that
      `KvmConsoleViewerPage`'s visible "Console URI: …" `SelectableText`, its merged
      `excludeSemantics` label, the `Clipboard.setData` payload and the "Copied: …" `SnackBar` all
      carry the SAME fail-closed target from `KvmConsole.launchPlan.targetUri` across the secure-
      HTTPS, external-client VNC/RFB, plaintext-HTTP and control-unsafe URI paths — never a raw
      CRLF / NUL / control-bearing value, and the row + copy affordance present iff a safe target
      exists. Every merged a11y node keeps visible text == announced label, with 320/800/1300 px
      no-overflow. Display-only; audit first, RED→GREEN only on a genuine divergence, no churn; no
      WebView/protocol import, no URL opened, no dependency, no production TLS weakening.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_clipboard_cross_surface_agreement_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof + 320 px no-overflow + visible==announced; writes
              limited to `lib/features/kvm/views/**`; no WebView/protocol import, no production TLS
              weakening; `git diff --exit-code -- pubspec.yaml`.
      **LANDED** 2026-11-21: added `test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart` (16 tests). Audit first: EP-U12 pinned CARD↔VIEWER clipboard agreement but nothing pinned the VIEWER's OWN four renderings of `launchPlan.targetUri` (merged a11y row label / visible `SelectableText` / `Clipboard.setData` payload / "Copied: …" `SnackBar`) as one contract — a one-sided edit could leak a padded/control-bearing value to a toast or screen reader while the clipboard stayed fail-closed. Pins all four byte-identical + control/injection-free over secure-HTTPS / padded-HTTPS / external-VNC / plaintext-HTTP, and no URI row / no copy affordance on CRLF / NUL, at 800 px plus 320/1300 px no-overflow with visible==announced. Real-file RED proof: SnackBar `Text('Copied: $uri')` → raw `console.connectUri ?? ''` → exactly the padded-HTTPS SnackBar agreement test failed (`+15 -1`), source restored byte-clean (SHA `f088a86d…` unchanged, empty lib diff), 600-perm backup shredded → 16/16 GREEN. No WebView/protocol import, no URL opened, no dependency, no production TLS weakening.

<!-- rf-ideate split 2026-11-21 09:53 UTC: splits a residual state-agreement seam of the blocked
     #009/#021 populated-console-list UI into one unblocked, widget-level, dependency-free, TLS-safe
     dept slice. The in-list 'Loading KVM consoles' spinner and the in-list 'Unable to refresh KVM
     consoles...' stale-data warning were landed in SEPARATE runs and each is pinned in isolation,
     but nothing pins their AGREEMENT over the four (loading, error) states of the populated
     `ListView` branch — in particular the both-true case (in-flight reload after a failure) where an
     operator must see BOTH nodes exactly once, and neither must collide with the early empty-list
     returns. Audit first; RED→GREEN only on a genuine divergence; no churn. Human-gated WebView/TLS
     rendering stays gated and is NOT re-split. No code touched. -->

- [x] EP-U13 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-U13 four-state populated-ListView agreement guard + REPAIR stale rf-platform decision-doc row + RED->GREEN tests`) — added `test/features/kvm/kvm_view_state_agreement_test.dart` (13 tests): error-only/loading-only/both-true/neither at 320/800/1300 px + multi-console both-true; exactly one merged node per active signal, visible==announced, warning+spinner distinct in both-true, no cards during reload, no early-return collision, no overflow. Audit found the both-true state only pinned at 800 px by the sibling suite — genuine narrow-width/agreement gap, not churn. Real-file RED: in-list gate `if (ui.loading)` -> `if (ui.loading && ui.error == null)` -> exactly 4 both-true tests failed (`+9 -4`); source restored byte-clean (SHA `60be27a4…`, empty lib diff), backup shredded -> 13/13 GREEN. analyze 0 / 1902 passed / 1 skipped; doc-only REPAIR carried (stale 9th LAUNCH_FALLBACK row from rf-platform merge removed, EP-P8 8/8); deps unchanged; emulator skipped. Populated-ListView in-branch state agreement: loading vs stale-error nodes in-branch state agreement: loading vs stale-error nodes: pin the
      four-state truth table of `KvmView.build`'s populated `ListView` branch over (loading, error):
      error-only → one merged 'Unable to refresh KVM consoles...' warning + stale cards still shown /
      copyable, no spinner; loading-only → one merged 'Loading KVM consoles' spinner replacing the
      cards, no warning; both-true (in-flight reload after a failure) → BOTH nodes present, exactly
      one of each, no overflow; neither → plain console cards. All nodes must be distinct from the
      early empty-list error/loading returns, keep visible `Text` == announced label inside each
      merged `excludeSemantics` node, and render at 320/800/1300 px without overflow. Display-only;
      audit first, RED→GREEN on a genuine divergence, no churn; no WebView/protocol import, no
      production TLS weakening, no dependency.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_view_reload_indicator_test.dart test/features/kvm/kvm_view_stale_error_banner_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof + 320 px no-overflow; writes limited to
              `lib/features/kvm/views/**`; no WebView/protocol import, no production TLS weakening;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 05:49 UTC: splits the remaining cross-surface clipboard-safety seam of
     the blocked #009/#021 epic into one unblocked, widget-level, dependency-free, TLS-safe dept slice.
     CB-1 pinned the card's `clipboardTargetUri` fallback and EP-U8 pinned that the viewer hides the copy
     affordance for a control-unsafe target, but nothing pins that BOTH surfaces, when they DO offer copy,
     place the SAME fail-closed target on the clipboard over one hostile-authority matrix (CRLF / NUL /
     raw space / malformed-% `@odata.id` and a control-unsafe `ConnectUri`), with visible text == announced
     label and no overflow. Audit first; fix only a genuine divergence via RED→GREEN; no churn. Human-gated
     WebView/TLS rendering stays gated and is NOT re-split. -->

- [x] EP-U12 LANDED 2026-11-21 — Cross-surface clipboard-target agreement under hostile authorities: pinned
      that the per-console card's "Copy connect info" and the viewer's "Copy console URI", built from the
      SAME KvmConsole over a 6-case hostile-authority matrix (CRLF / NUL / raw-space / malformed-% ConnectUri,
      hostile @odata.id, valid padded URI), derive the SAME fail-closed target from the shared
      `clipboardTargetUri` / `launchPlan.targetUri` single sources — byte-identical when both offer copy,
      never a raw control-bearing value, affordance present iff a safe target, 320/800/1300 px no-overflow.
      `test/features/kvm/kvm_clipboard_cross_surface_agreement_test.dart` (16 tests); two real-file RED proofs
      (card→raw launchUri: 4 hostile cases failed; viewer→raw connectUri: 5 failed), both sources restored
      byte-clean, empty lib diff, 600-perm backups shredded. Audit found no live divergence — regression
      guard, not churn. Display-only; no transport/dependency/TLS change.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_capability_card_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof + 320 px no-overflow; writes limited to
              `lib/features/kvm/views/**`; no WebView/protocol import, no production TLS weakening;
              `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-21 01:45 UTC: splits the display-only consumer half of the remaining
     cross-view console-source parity seam of the blocked #009/#021 epic (paired with EP-M4 in
     `queues/model.md`) into one unblocked, widget-level, dependency-free, TLS-safe dept slice. EP-U6/9/10
     and RU-2 pinned safe-source display and the two viewer disclosures, but nothing pins that the
     capability card's "KVM supported"/"KVM not supported" + "Service enabled" chips and disabled
     helper agree with the per-console card's affordance/URI row for a manager exposing ONLY a
     RemoteConsole or one whose console is BMC-disabled. Audit first; fix only a genuine divergence
     via RED→GREEN; no churn. Human-gated WebView/TLS rendering stays gated and is NOT re-split. -->

- [x] EP-U11 LANDED 2026-11-21 — RemoteConsole-only / disabled-manager card cross-surface rendering guard (display-only
      consumer of EP-M4): build both KVM cards for a manager exposing only an enabled RemoteConsole
      and for one whose console is BMC-disabled, and pin that the capability card's support/enabled
      chips + disabled helper agree with the per-console card's launch affordance / URI row for the
      SAME manager — never "KVM not supported"/disabled helper on a card whose peer surfaces an
      enabled, launchable console. All merged `excludeSemantics` nodes keep visible text == announced
      label, 320/800/1300 px no-overflow. Display-only; no transport, dependency or TLS change; audit
      first, RED→GREEN on a genuine divergence, no churn.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_capability_card_test.dart test/features/kvm/kvm_widget_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof + 320 px no-overflow; writes limited to
              `lib/features/kvm/views/**`; no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-20 17:10 UTC: splits the machine-checkable half of the still-open
     fullscreen/input-forwarding rendering acceptance of #009/#021 into one unblocked, display-only,
     dependency-free, TLS-safe dept slice. EP-U9 pinned the two implemented disclosures, but nothing
     pins that NO viewer surface manufactures an "input is being forwarded" / "embedded console
     live" claim while the production flag-off route is external-browser + copy — the forbidden copy
     that would be a false operator assurance and a human-gate bypass. Audit first; fix only a genuine
     divergence via RED→GREEN; no copy churn. The blocked in-app embed/WebView adapter (EP-U2) stays
     human-gated and is NOT re-split. No code touched. -->

- [x] EP-U10 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-U10 flag-off viewer false-claim firewall + RED->GREEN widget tests`, analyze 0 / 1719 passed / 1 skipped). Flag-off viewer never claims live embedded rendering or input forwarding: audit every
      `KvmConsoleViewerPage` path (secure-HTTPS, external-client VNC/RFB/serial, no-URI) and assert
      its visible `Text` + merged `excludeSemantics` labels never assert that keyboard/mouse are
      being forwarded or that an in-app console is live while the platform flag is off — only the
      established status/disclosure + external-open/copy guidance is shown, with visible text ==
      announced label and no duplicate/stale copy. Fix the FIRST genuine divergence via RED→GREEN
      widget tests; do not manufacture copy churn where a surface already fails closed. 320/800/1300
      px no-overflow on every audited path. No WebView/url_launcher import in the product build, no
      URL opened, no dependency, no TLS change.
      Dept: rf-ui
      Verify: `flutter test test/features/kvm/kvm_widget_test.dart test/features/kvm/kvm_viewer_disclosure_contract_test.dart && flutter analyze`
              (0 issues), RED→GREEN widget proof for any fixed divergence; merged a11y + 320/800/1300
              no-overflow; writes limited to `lib/features/kvm/views/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 13:04 UTC: re-scopes the still-open fullscreen + input-forwarding
      disclosure portion of the #009 rendering epic (EP-U1 scaffold) as one unblocked, display-only,
      dependency-free, TLS-safe dept slice. EP-U4 wired session lifecycle, EP-U5/U7/U8 pinned launch
      status / notices / affordance; nothing pins that the viewer's "keyboard/mouse forwarded until
      disconnect" + "fullscreen / back = disconnect" guidance is one merged a11y node with visible ==
      announced on every surface. Audit first; fix only a genuine divergence via RED→GREEN; no copy
      churn. The blocked in-app embed / WebView adapter (EP-U2) stays human-gated and is NOT re-split.
      No code touched. -->

- [x] EP-U9 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-U9 KVM viewer cross-path disclosure a11y contract + RED→GREEN tests`, analyze 0 / 1646 passed / 1 skipped). Fullscreen + input-forwarding disclosure a11y contract for #009/#021: pin that
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

- [x] EP-U3 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-U3 launch-guidance contradiction fix (external-client HTML5) + RED->GREEN tests`, analyze 0 / 1662 passed / 1 skipped, DMTF emulator 85/85). FIXED a genuine defect: `KvmConsole.showHtml5WebUiHint` now also requires `!requiresExternalConsoleClient` — an HTML5 console with a VNC/RFB/KVMIP/SSH/Telnet/IPMI `ConnectUri` no longer shows BOTH "open via BMC web UI" and the external-client notice. +16 RED→GREEN tests in `test/features/kvm/kvm_webui_hint_external_client_test.dart` (pre-fix real-code RED `+5 -11`). Note: fix landed in the model getter (single source of truth) rather than the view; no WebView/protocol import, no TLS change.) Launch-guidance consistency for the final external-browser + copy route across the
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

- 2026-11-23 18:42 UTC — EP-U26-residual LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): console-card "Copied:" SnackBar fail-closed cross-surface agreement guard. AUDIT FIRST: the literal EP-U26 premise is wrong (capability card has NO copy affordance — only a SelectableText "Resolved URI" row), and EP-U12/EP-U14/EP-U18 already pin card↔viewer clipboard, viewer SnackBar and copy-only route — but the CONSOLE CARD's own copy-confirmation SnackBar text is asserted NOWHERE (repo-wide `grep 'Copied:' test/` returns only the viewer assertion). Added `test/features/kvm/kvm_card_copy_confirmation_snackbar_agreement_test.dart` (12 tests) over a 6-case hostile-authority matrix pinning card SnackBar == clipboard payload == `clipboardTargetUri` == model single source, never raw control / injected marker; clean-secure byte-exact `launchPlan.targetUri`; card↔viewer confirmation byte-identical; merged copy-affordance visible==announced; no overflow at 320/800/1300 px. Real-file RED: `kvm_view.dart:673` `Text('Copied: $targetUri')` → raw `console.launchUri` under a 600-perm backup → exactly 7 named failures (`+5 -7`), 5 controls GREEN; restored byte-clean (SHA `7359effb5ba6b963e6c2d0584bf507f1093c29ca408352cbd48a85100d7efabf`, 0 residue, empty `lib/` diff, backup shredded) → 12/12 targeted GREEN; sibling suites 40/40; analyze 0; full suite 2672 passed / 1 skipped (baseline 2660 +12); issues validate OK; diff --check clean; deps unchanged; emulator skipped (test-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. New guard NOT yet epoch-registered in `guard_suite_liveness_test.dart` — deferred to the next EP-T pass. Both issues stay OPEN — human-gated on platform WebView + BMC TLS validation.
- 2026-11-22 06:05 UTC — EP-U17 LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): EP-U17 no-WebView final-route affordance agreement guard for #009/#021 (test-only, dependency-free, TLS-safe): AUDIT found EP-P12 fully covered by EP-P8/EP-P6/EP-P7 (add nothing), but EP-U17 had a genuine unguarded NEGATIVE invariant — no existing test failed if an in-app render button or a self-signed-accept affordance was added to any of the three surfaces. Extended `test/features/kvm/kvm_open_affordance_gating_test.dart` (+4 tests): concept-based detector sensitivity + honest-copy exemption, and per-surface viewer / console-card / capability-card scans at 320/800/1300 px pinning copy + browser-open guidance, merged visible==announced affordances, and absence of render/TLS affordances. Real-file RED #1: added an `OutlinedButton` "Render console in-app" to the viewer -> exactly 1 new test failed (+) while 92 independent existing guard tests stayed GREEN; restored byte-clean (SHA f088a86d..., empty lib diff). Real-file RED #2: added a Switch + "Accept self-signed certificate" Text to the capability card -> exactly 1 new test failed; restored byte-clean (SHA c6c4b09a...). Both 600-perm backups shredded. analyze 0 / full suite 2087 passed / 1 skipped; issues validate OK; diff --check clean; deps unchanged; lib diff empty; emulator skipped (test-only, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. Both issues stay OPEN — human-gated on platform WebView + BMC TLS validation.
- 2026-11-21 16:28 — EP-U14 viewer URI-surface agreement guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart` (16 tests) pinning that the viewer's merged "Console URI: …" a11y row, visible `SelectableText`, `Clipboard.setData` payload and "Copied: …" `SnackBar` all carry the SAME fail-closed `launchPlan.targetUri` over secure-HTTPS / padded-HTTPS / external-VNC / plaintext-HTTP (target present, all four byte-identical, control/injection-free) and CRLF / NUL (target null → no URI row / no copy affordance), at 800 px plus 320/1300 px no-overflow with visible==announced. EP-U12 only pinned CARD↔VIEWER clipboard agreement, not the viewer's own four renderings. Real-file RED proof: SnackBar `Text('Copied: $uri')` → raw `console.connectUri ?? ''` → exactly the padded-HTTPS SnackBar agreement test failed (`+15 -1`); source restored byte-clean (SHA `f088a86d…` unchanged, empty lib diff), 600-perm backup shredded → 16/16 GREEN. analyze 0; full `flutter test --coverage --concurrency=2` 1930 passed / 1 skipped (preflight 1910 +16 mine +4 concurrent rf-platform); deps unchanged; emulator skipped (test-only, <7 days since last green 85/85); no TLS weakening.
- 2026-11-21 09:24 — In-list stale-data refresh-failure warning LANDED (agent:redfish-automation, FEATURE #009/#021): FIXED a genuine defect — a failed reload with consoles already displayed rendered the stale list with NO warning (the early error return requires `consoles.isEmpty`). Added one merged `excludeSemantics` warning node in the populated `ListView` of `kvm_view.dart` (`'Unable to refresh KVM consoles. <error>'`, visible text inside the announced node), keeping the stale list visible/copyable. Added `test/features/kvm/kvm_view_stale_error_banner_test.dart` (5 tests) at 320/800/1300 px + idle + in-flight controls. Pre-fix RED `+1 -4`; mutation RED (`excludeSemantics: true` -> `false`) `+1 -4`, `kvm_view.dart` restored byte-clean (SHA `60be27a4…`), backup shredded -> 5/5 GREEN. Test-only change to the guard plus a display-only lib banner; analyze 0 / 1851 passed / 1 skipped; issues validate OK; diff --check clean; emulator skipped (<7 days, no wire/fixture/tool-runtime change). No TLS/dependency change, no URL opened.
- 2026-11-21 08:42 — In-list reload-indicator merged-Semantics guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_view_reload_indicator_test.dart` (4 tests) pinning `KvmView.build`'s populated-`ListView` reload branch (`loading: true` with consoles already shown) — ONE merged `excludeSemantics` 'Loading KVM consoles' node wrapping the spinner (visible == announced), header still present (distinct from the already-pinned early empty-list loading return), idle control (`loading: false` → card, no node), no overflow at 320/800/1300 px. Genuinely untested branch (execution- + assertion-uncovered), not churn. RED proof: in-list `label:` → 'Refreshing consoles' → 3 width tests failed (`+1 -3`), restored byte-clean (SHA `b58bf2f1…`, empty lib diff, backup shredded) → 4/4 GREEN. Test-only; analyze 0 / 1846 passed / 1 skipped; issues validate OK; diff --check clean; emulator skipped (<7 days). No lib/TLS/dependency change, no URL opened.
- 2026-11-21 08:00 — EP-U12 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_clipboard_cross_surface_agreement_test.dart` (16 tests) pinning that the per-console card's "Copy connect info" and the viewer's "Copy console URI", built from the SAME KvmConsole over a 6-case hostile-authority matrix (CRLF / NUL / raw-space / malformed-% ConnectUri, hostile @odata.id, valid padded URI), place the SAME fail-closed clipboard target — byte-identical when both offer copy, never a raw control-bearing value, viewer affordance present iff a safe target, 320/800/1300 px no-overflow. Audit found no live divergence (CB-1/EP-U8/model already pin each surface) — regression guard, not churn. TWO real-file RED proofs (card→raw launchUri: 4 hostile cases failed; viewer→raw connectUri: 5 failed); both sources restored byte-clean (SHAs `b58bf2f1…` / `f088a86d…`, empty lib diff), 600-perm backups shredded → 16/16 GREEN. Test-only; analyze 0 / 1837 passed / 1 skipped; issues validate OK; diff --check clean; emulator skipped (<7 days). No lib/TLS/dependency change; no URL opened.
- 2026-11-21 02:27 — EP-U11 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_card_cross_surface_agreement_test.dart` (6 widget tests = 2 shapes x 320/800/1300 px) building both KVM operator cards in ONE real `KvmView` tree from the same manager body (only upstream providers overridden). Enabled RemoteConsole-only manager: capability card Supported/Enabled + "KVM supported" + no disabled helper, peer card one "Open console" + matching Connect URI, both resolve the same endpoint. BMC-disabled manager with URI: capability card no Supported chip + disabled helper + "KVM not supported", peer card no launch affordance + shared enable-on-BMC status (visible == announced). Audit: model-level agreement already pinned, rendered cards were not — regression guard, not churn. RED proof: dropped `_ConsoleCard`'s `canOpenConsole` gate → all 3 enabled cases failed (`+3 -3`); restored byte-clean (SHA `b58bf2f153a7ea49…`, empty lib diff, backup shredded) → 6/6 GREEN. Test-only; analyze 0 / 1754 passed / 1 skipped; issues validate OK; diff --check clean; emulator skipped (<7 days). No lib/TLS/dependency change.
- 2026-11-21 00:04 — EP-U4 closeout limit-wiring guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_viewer_session_limit_wiring_test.dart` (3 widget tests) opening real viewers via the Navigator to pin that `KvmConsoleViewerPage` forwards its console's exact `maxConcurrentSessions` to `KvmSessionController.connect` — a second single-session viewer (limit 1) evicts the first (log records the eviction, shared session -> B), a multi-session viewer (limit 4) does NOT log a spurious eviction, plus a start-a-session context test. The pass-through was untested: all prior eviction tests called `connect` directly. RED proofs both directions (drop arg -> eviction test `+2 -1`; hardcode 1 -> multi-session test `+2 -1`), restored byte-clean SHA `f088a86d…`, 3/3 GREEN. Test-only; analyze 0 / 1726 passed / 1 skipped; issues validate OK; diff --check clean; emulator skipped (<7 days). No lib/TLS/dependency change.
- 2026-11-20 16:00 — EP-U9 LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_viewer_disclosure_contract_test.dart` (13 tests) — the cross-path × cross-width a11y contract for `KvmConsoleViewerPage`: the active-session / fullscreen-back = disconnect notice and the session-persistence notice each render as ONE merged `excludeSemantics` node with visible `Text` == announced label, exactly once each with no third/duplicate disconnect disclosure, on the secure-HTTPS, external-client VNC and URI-less viewer paths at 320/800/1300 px with no overflow. Audited all three paths first: no genuine divergence (the disclosures are unconditional and already single-sourced), so a regression guard against dropped/duplicated/split/one-path-only rendering — not copy churn. The keyboard/mouse input-forwarding half stays human-gated on platform WebView + BMC TLS validation; no false "keys are forwarded" string manufactured. RED proof: temporarily split the merged `label: sessionNotice` from its visible `Text` → 10/13 guard tests failed (`+3 -10`); restored byte-clean (SHA `f088a86d…` unchanged, 0 probe occurrences, empty lib diff), backup shredded → 13/13 GREEN. Test-only: no lib/view, dependency, wire or TLS change; no URL opened. analyze 0 / 1646 passed / 1 skipped (baseline 1633 +13); issues validate OK; diff --check clean.
- 2026-11-20 04:06 — RU-2 single-source guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/tool/notice_single_source_guard_test.dart` (6 tests) that parses the six canonical notices from `kvm_transport_notice.dart` at test time and fails closed if any other product KVM view hardcodes a notice literal (cross-surface screen-reader copy drift) or redefines a canonical constant name. 2 RED + 2 GREEN proofs, real-repo view scan clean; analyze 0 / 1445 passed / 1 skipped. Test-only; no lib/TLS/dependency change. RU-2 stays open: the mechanical single-source invariant is now pinned, the full merged-Semantics surface audit (both notices on both surfaces) remains.


- 2026-11-19 22:49 — EP-U5 LANDED (agent:redfish-automation, FEATURE #009/#021): the first real divergence was the `disabled` strategy — the viewer showed the shared actionable `kvmLaunchStatusText(disabled)` "enable KVM on BMC" message, but the per-console card gave only a bare "Disabled" chip and no next step. `_ConsoleCard` now renders that same shared string as one merged `excludeSemantics` node (visible text == announced label), error-styled, gated only on `disabled`. The `insecureHttp` path was already covered on the card by the distinct, documented `kvmInsecureTransportNotice` ("configure HTTPS first", no in-app render, no TLS weakening), so per "do not manufacture copy churn where the surfaces already agree" it was left as is. +1 RED→GREEN widget test (no overflow at 320/800/1300 px), analyze 0 / 1350 passed / 1 skipped, DMTF emulator 85/85 (lib changed). No dependency, no wire/TLS change.
- 2026-11-19 20:07 — EP-U4 closeout LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsoleViewerPage` no longer caches a local `_sessionActive` flag; it watches `kvmSessionProvider` and derives active/idle disclosure + Disconnect enablement from shared session ownership (`isConnected && activeManagerId == console.managerId.trim()`), re-checking ownership in the button and `PopScope` callbacks so an evicted viewer cannot end a newer console's session. +3 RED→GREEN widget tests (all confirmed RED pre-fix), 320 px no-overflow; analyze 0 / 1316 passed / 1 skipped; DMTF emulator 85/85 (lib changed). No dependency, no wire/transport change, no production TLS weakening.
- 2026-11-19 16:31 — EP-U3 (external-client protocol-guidance portion) LANDED (agent:redfish-automation, FEATURE #009/#021): added pure `kvmExternalClientNoticeFor(protocol)` in `kvm_transport_notice.dart` (blank/unknown → generic fallback) as the single source of truth and wired both the per-console card (`kvm_view.dart`) and capability card (`kvm_capability_card.dart`) external-client rows to it, so all three surfaces (viewer + both cards) name the specific external client from the shared `externalClientProtocolLabel`. +9 RED→GREEN widget tests (VNC/RFB + SSH + IPMI; 320/800/1300 px), analyze 0 / 1257 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 15:35 — EP-U3 (capability-card portion) LANDED (agent:redfish-automation, FEATURE #009/#021): the capability card now renders the shared `kvmExternalClientNotice` for a resolved VNC/RFB/KVMIP/serial endpoint (merged a11y, visible text == announced label, no overflow at 320/800/1300 px); +1 RED→GREEN widget test, analyze 0 / 1248 passed / 1 skipped, emulator 85/85. Full EP-U3 viewer↔capability string unification remains for a future slice.
- 2026-11-19 14:11 — EP-U4 LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsoleViewerPage` now owns the pure-UI session lifecycle — `ConsumerStatefulWidget` connects on enter (with `maxConcurrentSessions` eviction), a merged-a11y active/idle disclosure + "Disconnect console" button end it on demand, and `PopScope.onPopInvokedWithResult` ends it on back/pop. +5 RED→GREEN viewer widget tests, 320 px no-overflow; analyze 0 / 1231 passed / 1 skipped, emulator 85/85. No WebView/protocol dependency, no TLS change.
