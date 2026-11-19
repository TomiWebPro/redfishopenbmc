# Queue rf-platform (enable FIRST — the unblocking dept)

Owns: new `lib/features/kvm/platform/**` only. Verify: `flutter analyze` 0 + targeted tests.
Hard rule: no production TLS weakening, ever. No WebView/protocol dependency without
platform validation evidence.

## Backlog (head first)

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19): in-app console rendering. EP-P1 is THE unblocker. Refines RP-1/RP-2. -->

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

- [ ] RP-1 WebView/TLS validation matrix: can `webview_flutter` (or platform WebView) render an
      HTTPS BMC console on the available Linux/desktop target? How are self-signed BMC certs
      handled **without weakening production TLS**? Output: a doc matrix + reversible opt-in
      design (per-profile/test-only flag), NOT a forced dependency bump.
      Verify: matrix doc + `flutter analyze` 0; no `pubspec.yaml` change required in this item.
- [ ] RP-2 (after RP-1): implement the RP-1 opt-in behind the flag with tests; document fallback
      (external browser + copy path) which must keep working with the flag off.

## Log (one line per completed item: date + commit + note)
