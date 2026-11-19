# Queue rf-platform (enable FIRST — the unblocking dept)

Owns: new `lib/features/kvm/platform/**` only. Verify: `flutter analyze` 0 + targeted tests.
Hard rule: no production TLS weakening, ever. No WebView/protocol dependency without
platform validation evidence.

## Backlog (head first)

<!-- rf-ideate split 2026-11-19 12:37 UTC: slices the remaining blocked/epic work in issues
     #009/#021 and the FUTUREWORK "Blocked / needs a human" section into unblocked dept items.
     EP-P1/EP-P3 are now DONE in-tree (WEBVIEW_TLS_MATRIX.md + LAUNCH_FALLBACK.md exist); this is
     the human-gate / validation-evidence closeout of the "[!] KVM webview/native console" blocker.
     No dependency, no production TLS change, no WebView import. -->

- [ ] EP-P4 Human-gated validation-evidence checklist for revisiting in-app rendering (closeout of
      FUTUREWORK "[!] KVM webview/native console — may require a platform plugin and manual device
      validation; document the decision before adding dependencies"). The no-embedded-WebView
      decision is already recorded in `WEBVIEW_TLS_MATRIX.md` / `LAUNCH_FALLBACK.md`; extend the
      platform docs with a concrete per-target (Linux/desktop/mobile) evidence checklist that must be
      satisfied BEFORE any `webview_flutter` / `url_launcher` dependency or test-only TLS opt-in is
      added (WebView availability, self-signed BMC cert handling without weakening production TLS,
      CSP/mixed-content, fullscreen + input forwarding) plus an explicit human-approval gate. Add a
      pure-Dart guard test asserting product `lib/` imports no WebView/protocol plugin. No dependency,
      no production TLS behaviour change.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml` (no dependency bump); writes limited to
              `lib/features/kvm/platform/**`.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 (this dept's unblocker) is RESOLVED — the
     WEBVIEW_TLS_MATRIX decision is no embedded WebView on the available target; external-browser +
     copy is the final route. EP-P2 is therefore DEFERRED pending manual per-target validation
     evidence — do NOT proceed unattended. New head-first closeout slice. -->

- [ ] EP-P3 Finalize the no-WebView fallback contract (EP-P1 closeout): pin a production-default
      route-table test in the existing pure helpers — disabled → copyOnly, plaintext HTTP → copyOnly
      (never external open), secure HTTPS → externalBrowser, flag-off copy fallback byte-for-byte, no
      plaintext downgrade — and record the resolved decision in `LAUNCH_FALLBACK.md`. No dependency,
      no production TLS change.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml`; writes limited to `lib/features/kvm/platform/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): in-app console rendering.
     EP-P1 is THE unblocker and gates EP-P2 / EP-U2 / EP-T2. Every item carries the mandatory
     Dept:/Verify: fields (MULTI_DEPT hard rule #4). Legacy RP-1/RP-2 are refined by EP-P1/EP-P2. -->

- [ ] EP-P1 (UNBLOCKER) WebView/TLS validation matrix for in-app BMC console rendering — decide
      whether a platform WebView can render an HTTPS BMC console on each available target
      (Linux/desktop/mobile) and how self-signed BMC certs are handled **without weakening
      production TLS** (reversible per-profile / test-only opt-in flag only). Output: the matrix
      doc + the opt-in design; this decision unblocks EP-P2, EP-U2 and EP-T2.
      Dept: rf-platform
      Verify: `test -f lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml` (no dependency bump); no production TLS behaviour change.

- [ ] EP-P2 (after EP-P1) Implement the EP-P1 opt-in platform WebView adapter under
      `lib/features/kvm/platform/**` (conditional import + test-only flag) with tests. The
      external-browser + copy fallback must keep working byte-for-byte with the flag off.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/ && flutter analyze` (0 issues); changed paths limited to
              `lib/features/kvm/platform/`; no `pubspec.yaml` change; no production TLS weakening.

## Log (one line per completed item: date + commit + note)
