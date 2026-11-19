# Queue rf-platform (enable FIRST — the unblocking dept)

Owns: new `lib/features/kvm/platform/**` only. Verify: `flutter analyze` 0 + targeted tests.
Hard rule: no production TLS weakening, ever. No WebView/protocol dependency without
platform validation evidence.

## Backlog (head first)

- [ ] RP-1 WebView/TLS validation matrix: can `webview_flutter` (or platform WebView) render an
      HTTPS BMC console on the available Linux/desktop target? How are self-signed BMC certs
      handled **without weakening production TLS**? Output: a doc matrix + reversible opt-in
      design (per-profile/test-only flag), NOT a forced dependency bump.
      Verify: matrix doc + `flutter analyze` 0; no `pubspec.yaml` change required in this item.
- [ ] RP-2 (after RP-1): implement the RP-1 opt-in behind the flag with tests; document fallback
      (external browser + copy path) which must keep working with the flag off.

## Log (one line per completed item: date + commit + note)
