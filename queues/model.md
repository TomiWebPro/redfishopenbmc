# Queue rf-model (enabled in phase 2, after the epic split has ≥2 unblocked items)

Owns: `lib/features/kvm/models/**`, `lib/redfish/discovery/**`. Verify: scoped `flutter test` + RED→GREEN proof.

## Backlog (head first)

<!-- rf-ideate split 2026-11-22 02:06 UTC: splits the BLOCKED behaviour-change head RM-11 (mixed-regime
     enablement tri-state) of the #009/#021 epic into its unattended-doable half. RM-10 pinned the
     all-unknown "unknown keeps URI" fallback and EP-S7 pinned the both-flagged security-first
     preference, and both agree across KvmCapability/KvmConsole/pickPrimary; only the MIXED regime
     (flag-absent secure-HTTPS Graphical alongside an explicitly-enabled insecure SSH/plaintext HTTP
     block) diverges, and fixing it redefines a documented core semantic (a deliberate human
     decision — stays blocked). This slice only pins the two agreeing regimes byte-for-byte and
     RECORDS the mixed-regime divergence as a stable baseline for that decision; it never asserts
     the divergent value as expected and never changes semantics. AUDIT FIRST: if RM-10/EP-S7 already
     pin both regimes, record the audit and add nothing; RED→GREEN only on a genuine divergence, never
     churn. Human-gated WebView/TLS rendering stays gated and is NOT re-split. No code touched. -->

- [ ] RM-13 Mixed-regime enablement tri-state — decision-boundary characterization guard (unblocked
      half of the blocked RM-11): over one manager matrix spanning the all-unknown regime and the
      both-flagged regime (contradictory ServiceEnabled/Enabled, secure-HTTPS Graphical + SSH/HTTP
      blocks), pin that `KvmCapability.fromManager` (`resolveLaunchUri` / `connectTypes` /
      `maxSessions`) and `KvmConsole.fromManager` / `KvmService.pickPrimary` still AGREE byte-for-byte
      — the RM-10 all-unknown fallback and the EP-S7 security-first preference stay unchanged. For
      the probe-confirmed MIXED regime (flag-absent secure-HTTPS Graphical + explicitly-enabled
      insecure block), RECORD the divergence in the test/progress doc as a deferred human decision
      (RM-11) without asserting either side as the expected value. AUDIT FIRST; do NOT change any
      semantics, do NOT fold the behaviour decision in; RED→GREEN only on a genuine divergence in
      the agreeing regimes. Read-only model work; no wire/transport/TLS change, no dependency, no
      WebView/protocol import.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_capability_security_tristate_agreement_test.dart test/features/kvm/kvm_capability_primary_uri_agreement_test.dart test/features/kvm/kvm_model_test.dart && flutter analyze`
              (0 issues), RED→GREEN only on a genuine divergence in the agreeing regimes; writes
              limited to `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no wire/TLS change, no WebView/protocol import, no production TLS weakening.

- [x] RM-14 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 RM-14 OEM console-block direct-key precedence + RED->GREEN tests`, analyze 0 / full suite green) — `kvmOemConsoleBlock` documented search-order guard: added `test/features/kvm/kvm_oem_block_precedence_test.dart` (9 tests) pinning that a direct console-like key (`kvm`/`console`/`webconsole`, case-insensitive, `Uri` or `ConnectUri`) outranks a nested vendor `KVM` block carrying a usable endpoint, a blank/non-string direct member cannot shadow the valid nested fallback, enablement comes from the winning direct block (direct enabled vs nested disabled), and BOTH `KvmConsole.fromManager` / `KvmCapability.fromManager` resolve the same direct endpoint through a dual-console `Oem` payload. AUDIT: every pre-existing OEM test carried exactly one console source, so the documented two-pass order (direct before recursive) was unguarded; no live divergence — regression guard, not churn. Real-file RED: swapped the two passes in `_findBlock` → 7/9 new tests failed (`+2 -7`, full suite showed NO other failure); source restored byte-clean (SHA `0bea1a6f…` unchanged, empty lib diff), 600-perm backup shredded → 9/9 GREEN. Registered in `canonicalGuardFiles` (45→46) + pinned `rm14AddedGuards` epoch (length 1, disjoint from all earlier designations) in `test/tool/guard_suite_liveness_test.dart` (+1 pin test, completeness arithmetic, temp-root RED; real-file RED dropped canonical entry → 3 failures, restored byte-clean → 30/30 GREEN). Test/tool-only, no lib/, no dependency, no WebView/protocol import, no production TLS weakening.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_oem_block_precedence_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof (reversed passes → 7/9 failures; restored → 9/9); writes
              limited to `test/features/kvm/**` + `test/tool/guard_suite_liveness_test.dart`;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change, no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-21 22:03 UTC: splits a residual pure-model classifier-parity seam of the
     blocked #009/#021 launch-target epic into one unblocked, dependency-free, TLS-safe dept slice.
     EP-M2 pinned external-client classifier parity at the model surface and RM-9 pinned OEM depth
     bounds, but `isExternalClientConsoleUri` / `externalClientConsoleProtocol` (the single shared
     classifier + protocol label in `launch_plan.dart`, owned by rf-platform but consumed by BOTH
     models) are referenced by only one model-facing suite; nothing here pins that `KvmConsole` and
     `KvmCapability` delegate to them identically over the FULL external scheme set
     (vnc/rfb/kvmip/kvm/ssh/telnet/ipmi) under mixed-case schemes, padded/control-bearing URIs and
     degenerate (`.` / `..`) authorities. A one-sided model edit could badge a console as an
     external-client target on one card while the other reports no usable target — the #009
     divergence class. AUDIT FIRST: if both cards are already exhaustively pinned, record the audit
     and do NOT manufacture a test; RED→GREEN only on a genuine divergence, never churn. Do NOT
     edit rf-platform's `launch_plan.dart` (request via `_lib-requests.md` if a real gap needs it).
     Human-gated WebView/TLS rendering stays gated and is NOT re-split. No code touched. -->

- [x] RM-12 LANDED 2026-11-21 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / 1998 passed / 1 skipped) — added `test/features/kvm/kvm_external_client_from_manager_parity_test.dart` (5 tests) pinning that `KvmConsole.fromManager` and `KvmCapability.fromManager` agree on external-client classification, protocol label, launch-URI and `canOpenConsole`/launch-strategy over the FULL scheme set (vnc/rfb/kvmip/kvm/ssh/telnet/ipmi), uppercase/mixed-case, padded and opaque `vnc:host=…` forms, control/CRLF/NUL/TAB/DEL/NBSP/ZWSP-bearing targets and degenerate `.`/`..` authorities, plus identical protocol-specific external-open guidance via `kvmExternalClientNoticeFor`. AUDIT: both factories already agree (they delegate to the one shared classifier on the same trimmed launch URI) — genuine unguarded `fromManager`-pipeline seam (existing parity tests use direct constructors), regression guard not churn. Real-file RED: mutated `KvmCapability.externalClientProtocolLabel` to a fixed VNC label → 4/5 failed (`+1 -4`, capability leaked 'VNC/RFB' for SSH/KVMIP/null); source restored byte-clean (SHA `533ed545…` unchanged, empty lib diff), 600-perm backup shredded → 5/5 GREEN. Test-only, no `lib/`, no dependency, no WebView/protocol import, no production TLS weakening. Original item: feed
      feed one matrix of external-console URIs (`vnc:` / `rfb:` / `kvmip:` / `kvm:` / `ssh:` / `telnet:`
      / `ipmi:`, uppercase and mixed-case schemes, padded and control/CRLF-bearing values, opaque
      `vnc:host=…` forms and degenerate `.` / `..` authorities) through `KvmConsole.fromManager`
      and `KvmCapability.fromManager` and pin that both models delegate to the shared
      `isExternalClientConsoleUri` / `externalClientConsoleProtocol` classifier: identical
      `requiresExternalConsoleClient` / `externalClientProtocolLabel` / `canOpenConsole` results,
      identical protocol-specific external-open guidance, and fail-closed (no copy/open affordance)
      on control-bearing or degenerate-authority targets. AUDIT FIRST; fix only a genuine divergence
      via RED→GREEN pure-model tests, no churn. Read-only model work; no wire/transport/TLS change,
      no dependency, no WebView/protocol import.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_oem_registry_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/models/**` + those named test files; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-21 17:59 UTC: splits a residual intersection of the blocked #009/#021
     capability-aggregation epic into one unblocked, pure-model, dependency-free, TLS-safe dept slice.
     RM-8 pins the enabled-block preference tri-state (flag-absent "unknown" / explicit disable /
     contradictory `ServiceEnabled`+`Enabled`) for URI/types/session aggregates, and EP-S7 (18:52) adds a
     security-first secure-HTTPS pass to `_standardConnectUri` so the capability summary agrees with
     `pickPrimary`. But nothing pins that the NEW security-first pass still honours the RM-8 preference
     contract — i.e. that a disabled or explicitly-disabled block never wins the secure pass, that the
     all-disabled fallback is unchanged, and that `KvmConsole.fromManager` agrees for the same manager.
     A one-sided edit to the security pass could resurrect the EP-S7 divergence only for disabled/contradictory
     blocks while every single-helper test stayed GREEN. Audit first; RED→GREEN only on a genuine
     divergence; no churn. Human-gated WebView/TLS rendering stays gated and is NOT re-split. No code
     touched. -->

- [x] RM-10 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 RM-10 security-first x enabled-block tri-state agreement guard + RED->GREEN tests`, analyze 0 / 1956 passed / 1 skipped) — added `test/features/kvm/kvm_capability_security_tristate_agreement_test.dart` (4 tests) pinning the currently-correct tri-state invariants of the EP-S7 security-first pass: it never selects an explicitly-disabled block's secure URI / types / session limit while a launchable block exists, the RM-8 all-disabled fallback is preserved byte-for-byte after EP-S7, contradictory `ServiceEnabled`/`Enabled` truthy-wins agrees across all three aggregates AND `pickPrimary`, and a flag-absent secure console keeps its URI in the all-unknown regime (agreeing with pickPrimary's graphical fallback). Real-file RED proof: dropped `_explicitlyDisabled` from the security-first pass → the disabled-secure-URI test failed (`+3 -1`, `cap.uri` leaked `https://bmc.example/disabled-secure`); source restored byte-clean (SHA `533ed545ee344726ceb84de5e131cfc3bfb2aa7f56bb3a2c74bde08e22a2f559` unchanged, empty lib diff), 600-perm backup shredded → 4/4 GREEN. Test-only, no `lib/`, no dependency, no WebView/protocol import, no production TLS weakening. The MIXED-regime divergence found during the audit is recorded as a NEW deferred item below (behaviour-change candidate, NOT auto-fixed). Original item: feed `KvmCapability.fromManager` one matrix of manager bodies mixing flag-absent
      ("unknown"), explicitly-enabled and explicitly-disabled Graphical / Serial / Remote blocks with
      secure-HTTPS, plaintext-HTTP and serial-SSH URIs (plus contradictory `ServiceEnabled` / `Enabled`
      flags), and pin that the EP-S7 security-first pass in `_standardConnectUri` never selects a
      disabled or explicitly-disabled block, keeps the RM-8 all-disabled fallback byte-for-byte, and that
      `resolveLaunchUri`, `connectTypes` and `maxSessions` still prefer the same winning block as
      `KvmConsole.fromManager` for each body. Read-only model work; no transport/wire/TLS change, no
      dependency, no WebView/protocol import.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_primary_uri_agreement_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/models/**` + those named test files; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no wire/TLS change, no WebView/protocol import.

<!-- Discovered 2026-11-21 during the RM-10 audit via a probe (NOT fixed unattended, NOT asserted as
     expected in the RM-10 guard): a GENUINE mixed-regime divergence between the capability summary
     and pickPrimary. When a manager exposes a flag-absent ("unknown") secure-HTTPS GraphicalConsole
     alongside an EXPLICITLY-ENABLED but insecure/external block (serial SSH or plaintext HTTP remote):
     `_standardConnectUri`'s security-first pass treats the unknown graphical block as non-disabled
     and resolves its secure URI (`https://bmc.example/graphical`), while `pickPrimary` treats that
     console as non-openable (`KvmConsole.serviceEnabled == false` for a flag-absent block), skips its
     secure tier and badges the enabled SSH/HTTP block (`ssh://bmc.example/serial` / `http://…/remote`).
     Probe output: `cap.uri=https://bmc.example/graphical primary=ssh://bmc.example/serial canOpen=true`.
     Root cause: the two layers interpret the enablement tri-state differently — `KvmCapability._explicitlyDisabled`
     treats flag-absent as "unknown (usable)", while `KvmConsole.serviceEnabled` treats it as false
     (not openable). Both the all-unknown regime and the both-flagged regime already AGREE (pinned by
     the RM-10 guard + EP-S7); only the mixed regime diverges. Fixing it means redefining a documented
     core semantic ("unknown keeps URI") and touches `connectTypes` / `maxSessions` too, so DECIDE THE
     AUTHORITATIVE RULE DELIBERATELY (do NOT fold into a guard-only run, do NOT do unattended). Read-only
     model work; no transport/wire/TLS change, no dependency, no WebView/protocol import. -->

- [x] EP-M6 OEM-console URI blank/non-string `Uri` shadow agreement across both views (LANDED 2026-11-21, agent:redfish-automation, FEATURE #009/#021, test/tool-only): added `test/features/kvm/kvm_oem_uri_shadow_agreement_test.dart` (8 tests) pinning that the shared `kvmOemConsoleUri` resolver prefers a usable `Uri` and never lets a blank/empty/non-string `Uri` shadow a valid `ConnectUri`, with per-console↔capability cross-view parity; registered the guard in `canonicalGuardFiles`. Audit-first: the inverse (blank `ConnectUri` cannot shadow a valid `Uri`) was already pinned in `kvm_oem_uri_test.dart`, but the blank-`Uri` direction was not — genuine unguarded seam, no churn. Real-file RED: moved `Uri` return above blank-skip → 5/8 failed; restored byte-clean (SHA `0bea1a6f…`), 8/8 GREEN.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_oem_uri_shadow_agreement_test.dart && flutter analyze` (0 issues), RED→GREEN proof on the blank-`Uri` case; writes limited to `test/features/kvm/**` + `test/tool/guard_suite_liveness_test.dart`; no `lib/`/wire/TLS change, no WebView/protocol import.

- [ ] RM-11 Mixed-regime enablement tri-state agreement (unknown secure block + explicitly-enabled
      insecure block): decide the authoritative rule for the probe-confirmed divergence above and make
      `KvmCapability.resolveLaunchUri` / `connectTypes` / `maxSessions` agree with
      `KvmConsole.fromManager` / `KvmService.pickPrimary` for one manager mixing flag-absent and
      explicitly-enabled console blocks. Keep the all-unknown "unknown keeps URI" fallback (RM-10)
      and the both-flagged EP-S7 security-first preference byte-for-byte; RED→GREEN only once the
      authoritative rule is chosen. No wire/TLS change, no dependency, no WebView/protocol import.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_capability_primary_uri_agreement_test.dart test/features/kvm/kvm_capability_security_tristate_agreement_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof on the genuine mixed-regime case; writes limited to
              `lib/features/kvm/models/**` + those named test files; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no wire/TLS change, no WebView/protocol import.

<!-- rf-ideate split 2026-11-21 14:10 UTC: splits a residual hostile-payload normalization seam of the
     blocked #009/#021 capability aggregation into one unblocked, pure-model, dependency-free,
     TLS-safe dept slice. Per-console `ConnectTypesSupported` normalization (trim / drop-empty /
     case-insensitive dedup) is pinned by `kvm_model_test.dart`, and RM-5 pins an aggregate⊇console
     subset over mostly-well-formed payloads — but nothing pins that the CAPABILITY aggregate
     `connectTypes` applies the SAME normalization to hostile `ConnectTypesSupported` entries
     (duplicate with mixed case/padding, whitespace-only, non-string bool/num/list/map, embedded
     control chars) as the per-console `connectTypesSupported` getter, nor that RM-8's
     enabled-block preference still selects the same winning block. A divergent normalization would
     desync the capability card's connect-type chips from the per-console card while every
     single-getter test stayed GREEN. Audit first; RED→GREEN only on a genuine divergence; no churn.
     Human-gated WebView/TLS rendering stays gated and is NOT re-split. No code touched. -->

- [x] EP-M5 LANDED 2026-11-22 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / 2037 passed / 1 skipped) — added `test/features/kvm/kvm_connect_types_hostile_agreement_test.dart` (8 tests) pinning cross-factory agreement over a hostile `ConnectTypesSupported` matrix (nested list/map + null/int/double/bool entries dropped, blanks dropped, padded mixed-case dedup keeping first spelling, control-bearing values byte-identical) AND the multi-block enabled-block-preference (RM-8) / all-disabled / flag-absent aggregate equalling the union of the preferred per-console type lists. AUDIT: the existing single-block agreement group in `kvm_model_test.dart` uses a modest null/int/bool matrix only — nested collections, control-bearing values and multi-block enablement preference across both factories were unguarded; regression guard, no live divergence. Real-file RED: `KvmCapability._appendTypes` stringifying non-string entries → 5/8 failed (`+3 -5`); source restored byte-clean (SHA `533ed545…` unchanged, empty lib diff), backup shredded → 8/8 GREEN. Registered in `canonicalGuardFiles` + pinned `epM5AddedGuards` (length 1, disjoint) in the liveness suite (+1 pin, 23/23). Test/tool-only, no `lib/`, no dependency, no wire/TLS change. Original item: feed
      `KvmConsole.fromManager` and `KvmCapability.fromManager` the same manager whose enabled
      console block carries a hostile connect-types matrix (mixed-case/padded duplicates, blank /
      whitespace-only tokens, non-string bool/num/list/map entries, control-bearing values) and pin
      that the per-console `connectTypesSupported` and the capability aggregate `connectTypes`
      normalize identically — trimmed, blanks/non-strings dropped, case-insensitive dedup, no raw
      control code point — with the enabled-block preference (RM-8) and the all-disabled fallback
      unchanged. Read-only model work; no transport/wire/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/models/**` + those two named test files;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change.

<!-- rf-ideate split 2026-11-21 09:53 UTC: splits a residual internal-consistency seam of the blocked
     #009/#021 OEM-console detection into one unblocked, pure-model, dependency-free, TLS-safe dept
     slice. RM-1..RM-8 and EP-M1/M2/M4 pin enablement precedence, non-map tolerance, cross-view
     registry agreement, session-limit parsing and URI/type aggregation, but nothing pins that the
     SAME OEM console is visible at the shared recursion-depth bound (3) to every entry point:
     `FeatureRules.oemHasConsole`, `kvmOemConsoleBlock` / `kvmOemConsoleUri` / `kvmOemConsoleEnabled`,
     `KvmOemRegistry._findAt` and both `fromManager` factories. A bound off-by-one would let the
     capability card advertise "supported" while the console card resolves no URI (or vice versa).
     Audit first; RED→GREEN only on a genuine divergence; no churn. Human-gated WebView/TLS rendering
     stays gated and is NOT re-split. No code touched. -->

- [x] RM-9 LANDED 2026-11-21 — OEM-console detection/resolution depth-bound agreement across all shared entry points:
      over an in-memory matrix of `Oem` payloads with a console nested at each depth from 0 to just
      beyond the shared bound (plus a padded/mixed-case vendor key and a non-map console value), pin
      that `FeatureRules.oemHasConsole`, `kvmOemConsoleBlock` / `kvmOemConsoleUri` /
      `kvmOemConsoleEnabled`, `KvmOemRegistry._findAt` and both `KvmConsole.fromManager` and
      `KvmCapability.fromManager` agree on which payloads expose a console and its URI/enablement —
      in particular that no payload is "supported" on one card while the peer resolves no URI, and
      that a hostile deep/blob value cannot cause unbounded recursion. Read-only model work; no
      transport/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_oem_uri_test.dart test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/models/**` + `lib/redfish/discovery/**` + those named tests;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change.

<!-- rf-ideate split 2026-11-21 05:49 UTC: splits the last unguarded internal-consistency seam of the
     blocked #009/#021 capability aggregation into one unblocked, pure-model, dependency-free, TLS-safe
     dept slice. EP-M4/RM-1..RM-7 and the per-helper tests (unknown-enablement limit / types / URI /
     graphical-@odata.id fallback) each pin one aggregation helper in isolation, but nothing pins that
     the THREE enabled-preference helpers (`resolveLaunchUri` via `_standardConnectUri`,
     `_aggregateConnectTypes`, `_aggregateMaxSessions`) all select the SAME winning block for ONE mixed
     payload, nor the exact tri-state resolution (flag-absent "unknown" keeps priority like enabled vs
     an explicit `ServiceEnabled:false` / `Enabled:false` block being deprioritized, with the all-disabled
     fallback) and contradictory-flag (`ServiceEnabled:false` + `Enabled:true`) handling. Audit first;
     RED→GREEN only on a genuine divergence; no churn. Human-gated WebView/TLS rendering stays gated and
     is NOT re-split. No code touched. -->

- [x] RM-8 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 RM-8 enabled-block aggregation agreement guard + RED->GREEN tests`, analyze 0 / 1821 passed / 1 skipped [baseline 1817 +4], test-only) — KvmCapability enabled-block aggregation agreement across URI / connect-types / session-limit:
      feed `KvmCapability.fromManager` one matrix of manager bodies mixing flag-absent ("unknown"),
      explicitly-enabled and explicitly-disabled Graphical / Serial / Remote blocks (plus contradictory
      `ServiceEnabled` / `Enabled` flags) and pin that `resolveLaunchUri`, `connectTypes` and `maxSessions`
      all prefer the same non-disabled winning block with a consistent all-disabled fallback, and that
      `KvmConsole.fromManager` agrees for the same manager. Read-only model work; no transport/TLS
      change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_model_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof only on a genuine divergence; writes limited to
              `lib/features/kvm/models/**` + those two named test files;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change.
      LANDED: audit found no live divergence — regression guard, not churn. The three aggregates
      (`_standardConnectUri` / `_aggregateConnectTypes` / `_aggregateMaxSessions`) each apply the
      `_explicitlyDisabled` predicate in their own preference pass; no single test pinned their AGREEMENT
      over one matrix. Added `KvmCapability enabled-block aggregation agreement (RM-8 / #009/#021)` group
      (4 tests) to `test/features/kvm/kvm_capability_test.dart`: (1) disabled graphical vs enabled remote —
      uri/types/limit all come from the remote block and `KvmConsole.fromManager`'s openable console agrees;
      (2) contradictory `ServiceEnabled`/`Enabled` flags — a truthy flag wins on all three aggregates and in
      `KvmConsole.serviceEnabled`; (3) all-disabled fallback is graphical-first across all three with no
      openable console; (4) a flag-absent (unknown) block is retained identically by all three. RED #1:
      dropped the disable-skip in `_aggregateMaxSessions` first pass → "prefer one enabled block" test failed
      (`+3 -1`, maxSessions `Expected 4 / Actual 1`, i.e. the limit leaked from the disabled graphical block);
      RED #2: `ServiceEnabled:false` forced-disabled even with truthy `Enabled` → contradictory-flag test failed
      (`+3 -1`, uri `Expected .../graph / Actual .../remote`, desyncing the aggregates from the openable console);
      `kvm_capability.dart` restored byte-clean (SHA `652a5038fa8ff0d…` unchanged, empty lib diff), 600-perm
      backup shredded → 4/4 GREEN. Test-only, deps unchanged.

<!-- rf-ideate split 2026-11-21 01:45 UTC: splits the remaining cross-view console-source parity seam
     of the blocked #009/#021 epic (RemoteConsole + explicit-disable parity) into one unblocked,
     pure-model, dependency-free, TLS-safe dept slice. EP-M1/M2 and RM-1..RM-7 pinned OEM enablement,
     session-limit, connect-type, source-identity and parser-fault isolation, but a manager exposing
     only a `RemoteConsole` (no Graphical/Serial/OEM), or one whose standard console block is
     explicitly `ServiceEnabled:false` / legacy `Enabled:false`, has no dedicated cross-view test
     proving that BOTH `KvmConsole.fromManager` and `KvmCapability.fromManager` detect, enable and
     resolve its URI identically (graphical→serial→remote precedence included). Audit first; fix only
     a genuine divergence via RED→GREEN; no churn. The human-gated WebView/TLS rendering stays gated
     and is NOT re-split. No code touched. -->

- [ ] EP-M4 RemoteConsole-only + explicit-disable cross-view detection/enablement/URI parity: feed
      both `KvmConsole.fromManager` and `KvmCapability.fromManager` one matrix of manager bodies
      (RemoteConsole-only enabled/disabled, Graphical+Remote precedence, explicitly disabled
      SerialConsole / RemoteConsole, OEM-vs-standard disable) and pin that `supported` /
      `serviceEnabled`, the resolved launch URI (graphical→serial→remote), aggregated connect types
      and launch strategy agree across the two views; a BMC-disabled standard block must fail closed
      on BOTH. Audit first, RED→GREEN only on a genuine divergence, no churn; read-only model work,
      no transport/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/models/**`;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change.

<!-- rf-ideate split 2026-11-20 17:10 UTC: splits the remaining OEM-extensibility robustness seam
     of the #009 epic (vendor parser hook) into one unblocked, pure-model, dependency-free, TLS-safe
     dept slice. `KvmOemRegistry.parse` calls a registered `KvmOemConsoleParser.parse` with no
     exception isolation, so a throwing/third-party vendor parser propagates into BOTH
     `KvmConsole.fromManager` and `KvmCapability.fromManager` and can blank/crash the KVM screen;
     RM-1..RM-7 and EP-M1/M2 pinned classification/agreement but not parser fault isolation. Audit
     first; fix only a genuine divergence via RED→GREEN; no churn. The blocked rendering/dependency/
     TLS acceptance (EP-U2/EP-P2/EP-T2/EP-P4) stays human-gated and is NOT re-split. No code touched. -->

- [x] EP-M3 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-M3 vendor-parser fault isolation + RED→GREEN tests`, analyze 0 / 1673 passed / 1 skipped, DMTF emulator 85/85) — FIXED a genuine robustness defect: `KvmOemRegistry.parse` invoked a registered third-party `KvmOemConsoleParser.parse` with no exception isolation, so a throwing parser propagated out of both `KvmConsole.fromManager` and `KvmCapability.fromManager` (and `resolveLaunchUri`) and could blank/crash the gated KVM screen. Wrapped the call in a try/catch that treats any exception as "not a console" and tries the next parser, preserving first-match order + healthy-parser enrichment + generic fallback. +5 RED→GREEN tests in `kvm_oem_registry_test.dart` (all 5 failed `+25 -5` against pre-fix code, 30/30 GREEN after). Pure model, no wire/transport/dependency/TLS change. Original item: pin that a
      registered `KvmOemConsoleParser` which throws (or returns a malformed block) is treated as
      "not a console" and skipped, so `KvmConsole.fromManager` / `KvmCapability.fromManager` fall
      back to strict generic OEM detection and never throw; a healthy parser still enriches both
      views byte-for-byte and the first-match registration order is unchanged. Audit first; fix the
      FIRST genuine divergence via RED→GREEN pure-model tests; do not manufacture churn where a
      parser already fails closed. No new helper owned by another dept (request via
      `_lib-requests.md` if unavoidable). Read-only model work; no wire/transport/TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_oem_registry_test.dart test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/models/**` + those three named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 13:04 UTC: re-scopes the still-open model URI-scheme / OEM-registry
      remainder of the #009/#021 epic (FUTUREWORK head-first candidate EP-M1) as one unblocked,
      dependency-free, TLS-safe dept slice. RM-5/RM-6 pinned enablement/session/hostile-source
      agreement and EP-M1/M2 classifier parity already landed; nothing pins that a registered custom
      `KvmOemConsoleParser` and generic vendor `Oem.*.KVM.{Uri,ConnectUri}` scheme classification agree
      across BOTH models and never bypass the shared control-safe gate. Audit first; fix only a genuine
      divergence via RED→GREEN; no churn. The genuinely blocked rendering/dependency/TLS acceptance
      (EP-U2 / EP-P2 / EP-T2 / EP-P4) stays human-gated and is NOT re-split here. No code touched. -->

- [x] RM-7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-7 cross-view OEM-registry agreement fix + RED→GREEN tests`, analyze 0 / 1617 passed / 1 skipped, DMTF emulator 85/85) — FIXED a genuine cross-view divergence: `KvmConsole.fromManager` honored a registered `KvmOemRegistry` parser but `KvmCapability.fromManager` had no registry param, so a vendor-only console (`Oem.AMI.Mgmt.EmbeddedUrl`, non-console-like key) was launchable on the card yet "not supported / no URI" on the capability card. Added optional `oemRegistry` to the capability factory + `resolveLaunchUri` (registry-authoritative OEM detection/enablement/URI, generic fallback, standard ConnectUri precedence intact) and +4 RED→GREEN tests in `kvm_oem_registry_test.dart` (agreement + 6-shape scheme matrix + disabled guard + precedence guard). RED proof: generic-only URI failed the 2 core tests (`+21 -2`), restored byte-clean (SHA `652a5038…`, 0 probes) → 24/24 GREEN. No dependency/wire/transport/fixture change, no TLS weakening. Cross-view URI-scheme + OEM-registry agreement property for #009/#021: over a matrix of
      console URI schemes (secure HTTPS, plaintext HTTP, external-client VNC/RFB/KVMIP + serial, blank,
      control-unsafe) and OEM console shapes (registered `KvmOemConsoleParser` custom vendor, generic
      `Oem.<Vendor>.KVM.Uri` / `ConnectUri`, enabled/disabled, no-URI), assert `KvmConsole.fromManager`
      and `KvmCapability.fromManager` ALWAYS agree on external-vs-HTTPS classification, protocol label
      and launch strategy, and that both route the URI through the shared control-safe gates. Fix the
      FIRST real divergence via RED→GREEN pure-model tests; do not manufacture churn where the two
      models already agree. No new helper owned by another dept (request via `_lib-requests.md` if
      unavoidable). Read-only model work; no transport/wire/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_oem_registry_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/models/**` + those three named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 09:00 UTC: splits the still-open hostile/numeric-payload remainder of
     the #009/#021 model surface. RM-5 pinned enablement + connect-type cross-view agreement; RM-2
     extracted `kvmSessionLimit` with helper-only tests — but no test pins that BOTH models resolve
     `maxConcurrentSessions` identically over a hostile numeric matrix. Pure model, dependency-free,
     TLS-safe; distinct from RM-1..RM-5 (all narrower/different contracts). -->

- [x] RM-6 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-6 session-limit cross-view agreement property + RED→GREEN tests`, analyze 0 / 1570 passed / 1 skipped) — 28-test group in `test/features/kvm/kvm_model_test.dart`: a 26-shape hostile numeric matrix (`MaxConcurrentSessions` int/integral-double/numeric-string/padded/fractional/non-finite/>2^53/negative/blank/bool/list/map/null/absent) parsed through both `KvmConsole.fromManager` and `KvmCapability.fromManager`, asserting identical resolved `maxConcurrentSessions`/`maxSessions` and spec-expected values, plus a single-session-encoding test (1 / 1.0 / '1' / '  1  ' all resolve to exactly 1 — the eviction precondition) and a disable-preference aggregation-agrees-with-openable-console test. No divergence found (both models already share the `kvmSessionLimit` parser); the group is a regression guard against future drift. RED proof: temporarily bypassing the helper in `KvmConsole._fromBlock` (int-only cast) failed 10 RM-6 tests incl. cross-view agreement; restored byte-clean (SHA `a3308faf…` unchanged, 0 probe occurrences) → 28/28 GREEN. Test-only, no `lib/` diff, no dependency/wire/TLS change; emulator skipped (<7 days). Session-limit cross-view agreement property test: over a generated matrix of
      `MaxConcurrentSessions` shapes (integer, integral double `4.0`, numeric string, padded string,
      fractional / non-finite / `>2^53` double, negative, blank, bool/list/map, absent) in both
      GraphicalConsole and capability aggregation, assert `KvmConsole.fromManager` and
      `KvmCapability.fromManager` ALWAYS report the SAME resolved `maxConcurrentSessions`, and that
      the single-session eviction contract still holds. Fix the FIRST real divergence via RED→GREEN
      pure-model tests; do not manufacture churn where the two models already agree. No new helper
      owned by another dept (request via `_lib-requests.md` if unavoidable). Read-only, no wire /
      transport / TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_session_limit_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof for any fixed divergence; writes limited to
              `lib/features/kvm/models/**` + those three named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 04:56 UTC: splits the still-open cross-view-agreement remainder of
     the #009/#021 epic into one unblocked, dependency-free, TLS-safe pure-model invariant slice.
     Every prior divergence (RM-1 enablement, RM-2/RM-3 non-map payloads, RM-4/CB-1 source identity,
     EP-M1/M2 classifier parity) was fixed one at a time; this pins the WHOLE console↔capability
     agreement contract over the payload matrix so a future edit cannot silently desynchronise the
     three KVM surfaces. Distinct from EP-M1/M2 and RM-1/RM-2 (all narrower single fixes). -->

- [x] RM-5 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-5 cross-view agreement property test + RED→GREEN tests`, analyze 0 / 1476 passed / 1 skipped) — 18-test property group in `test/features/kvm/kvm_model_test.dart` pinning manager identity, identical control-safe `safeManagerUri`, enablement agreement and enabled-console connect-type subset across both models over a 18-shape payload matrix (incl. hostile @odata.id); no divergence found, 5 hostile-source cases RED-proven by temporarily un-sanitizing `KvmCapability.safeManagerUri` (restored byte-clean). No `lib/`, dependency, wire/TLS change.
      Cross-view agreement property test for manager console payload normalization: over a
      generated matrix of Manager payload shapes — standard GraphicalConsole/SerialConsole blocks,
      OEM blocks (Uri / ConnectUri, registered + generic), enabled/disabled flags, padded/blank/
      non-string @odata.id, non-map console values, duplicate/blank ConnectTypes — assert
      `KvmConsole.fromManager` and `KvmCapability.fromManager` ALWAYS agree for the same manager on
      enablement (`supported`/`serviceEnabled`), normalized connect types, control-safe source
      identity, and launch classification (`launchStrategy`/`canOpenConsole`). Fix the FIRST real
      divergence found via RED→GREEN pure-model tests; do not manufacture churn where the surfaces
      already agree. Read-only model work, no wire shape change, no transport/TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof for at least one fixed divergence; writes limited to
              `lib/features/kvm/models/**` + the two named test files; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the remaining cross-surface "control-safe manager
     source" portion of the open #009/#021 epic. CB-1 added `KvmConsole.safeManagerUri` for the CARD
     clipboard path, but `KvmCapability` still has no equivalent, so the capability card has no
     model-side single source of truth for a control-safe source display. Pure model, dependency-free,
     TLS-safe; distinct from EP-M1 / RM-2 (still open) and from CB-1 (already landed on KvmConsole). -->

- [x] RM-4 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 RM-4 capability-side control-safe manager-source getter + RED→GREEN tests`, analyze 0 / 1408 passed / 1 skipped). Control-safe manager-source getter on `KvmCapability` (model half of the cross-surface
      source-display split): mirror `KvmConsole.safeManagerUri` — route the BMC-supplied
      `sourceManagerUri` (a `@odata.id`) through the shared `isControlSafeConsoleUri` gate. A
      control-safe source passes byte-for-byte (no valid source lost); a control-unsafe one
      (CRLF / NUL / raw space / backslash / Unicode separator / malformed-or-encoded control) degrades
      to a deterministic pct-encoded `/redfish/v1/Managers/<managerId>` path, blank/null id → `manager`.
      Keep the raw `sourceManagerUri` field itself unchanged (read-only model, no wire shape change);
      RED→GREEN pure-model tests covering safe/unsafe/null sources + hostile-id encoding + the
      capability↔console agreement for the same manager. No dependency, no transport/TLS change.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_capability_test.dart && flutter analyze` (0 issues),
              with RED→GREEN proof (compile-RED: getter absent pre-fix); writes limited to
              `lib/features/kvm/models/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-19 20:47 UTC: splits the still-open non-map-payload remainder of
     RM-2 (its session-limit portion LANDED 18:01) into a fresh, unblocked, dependency-free
     model slice of #009/#021. No transport/TLS change, no dependency. -->

- [x] RM-3 LANDED 2026-11-19 (run `auto: FEATURE #009/#021 RM-3 non-map OEM console value fail-closed + tests`). Non-map payload tolerance across the KVM model read path (the open remainder of RM-2):
      `Members` entries and `GraphicalConsole` / `SerialConsole` / `RemoteConsole` / `Oem` values
      that decode to a non-map (String / num / bool / List / null) must fail closed — treated as
      absent/disabled — in `KvmConsole.fromManager`, `KvmCapability.fromManager` and any shared
      walk, never throwing a cast/NoSuchMethodError or reporting a bogus enabled/launchable
      console. Keep the already-covered per-block non-map behaviour green; add cross-view
      agreement tests so the console card and capability card never disagree for the same
      malformed manager. If a fixture is needed, request it via rf-tooling (do not write
      `test/fixtures/**`).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/models/**`.

<!-- rf-ideate re-split 2026-11-19 08:34 UTC: EP-P1 (platform WebView/TLS matrix) is RESOLVED —
     no embedded WebView on the available target; external-browser + copy is the final render route.
     New head-first, unblocked, dependency-free, TLS-safe dept slices of #009/#021. -->

- [ ] EP-M2 Cross-surface external-client classifier parity: ensure `KvmConsole.requiresExternalConsoleClient`
      / `externalClientProtocolLabel` (VNC/RFB/KVMIP/serial) and all `KvmCapability` transport getters
      route through the shared fail-closed gates (`isControlSafeConsoleUri` + the HTTP(S) classifiers),
      then find and fix the next ad-hoc `Uri.tryParse` with RED→GREEN tests. Read-only model work.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
              (0 issues), with RED→GREEN proof; writes limited to `lib/features/kvm/models/**`.

<!-- Epic split of #009/#021 (rf-ideate, 2026-11-19 04:31 UTC): dept-sized, unblocked model
     slices, head-first. Every item carries the mandatory Dept:/Verify: fields (MULTI_DEPT
     hard rule #4). Pure-model work only; no transport/TLS change, no dependency. -->

- [ ] EP-M1 Pure-model classification for the launch path: KVMIP/RFB/VNC + serial SSH/Telnet/IPMI
      external-client classification, HTTPS in-app eligibility and URI-scheme edge cases, with
      RED→GREEN tests. Read-only; no transport/TLS change, no dependency.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart` (incl. RED→GREEN proof) `&& flutter analyze`
              (0 issues); writes limited to `lib/features/kvm/models/**`.

- [ ] RM-1 Audit the enabled-state contract for the two views not yet audited: per-console
      `maxConcurrentSessions` chips + connection-type chips (cf. FUTUREWORK 2026-11-19 note:
      all four aggregate capability fields now skip disabled blocks; these two per-console
      views are the remainder).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart && flutter analyze` (0 issues);
              writes limited to `lib/features/kvm/models/**`.

- [ ] RM-2 Next malformed-payload tolerance gap in the KVM read path (non-map manager/console
      payloads in the capability card / manager walk), with RED→GREEN tests. If a fixture is
      needed, request it via rf-tooling (do not write `test/fixtures/**`).
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart && flutter analyze` (0 issues);
              writes limited to `lib/features/kvm/models/**`.

## Log
- 2026-11-21 12:18 — RM-9 OEM depth-bound agreement guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_oem_depth_bound_agreement_test.dart` (21 tests). The shared OEM console recursion bound `3` is duplicated across four entry points (two hardcoded): `FeatureRules.oemHasConsole` (`depth > 3`), the `kvmOemConsoleBlock`/`Uri`/`Enabled` helpers (`maxDepth = 3`), `KvmOemRegistry._findAt` (`depth > 3`) and both `fromManager` factories. Nothing pinned that they flip at the SAME depth — a one-level drift could let the capability card advertise "supported" while the console card resolves no URI. Pins a URI-bearing console nested at depths 0..5 (detection ⟺ URI resolution; both factories agree on URI/enablement/launch), the registered-vendor registry bound, padded/mixed-case keys, non-map fail-closed and a 12-level hostile blob (bounded, no overflow). Audit found no live divergence — regression guard, not churn. Real-file RED proof: `FeatureRules._oemHasConsoleAt` `depth > 3` → `> 4` → exactly the two depth-4 agreement tests failed (`+19 -2`); source restored byte-clean (SHA `0070f6146f93…` unchanged, empty lib diff), 600-perm backup shredded → 21/21 GREEN. analyze 0; deps unchanged; test-only, emulator skipped (<7 days since last green 85/85); no TLS weakening.
- 2026-11-21 07:23 — RM-8 enabled-block aggregation agreement guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `KvmCapability enabled-block aggregation agreement (RM-8 / #009/#021)` group (4 tests) to `test/features/kvm/kvm_capability_test.dart`. The capability summary's three independent enabled-block preference passes (`_standardConnectUri` / `_aggregateConnectTypes` / `_aggregateMaxSessions`) were each pinned in isolation but never for AGREEMENT over one matrix or with `KvmConsole.fromManager`; a refactor with divergent predicates could desync the capability card from the launchable console while every single-aggregate test stayed GREEN. Pins (1) disabled graphical vs enabled remote → uri/types/limit all from remote + openable console agrees, (2) contradictory `ServiceEnabled`/`Enabled` truthy-wins on all three + `KvmConsole.serviceEnabled`, (3) all-disabled fallback graphical-first on all three with no openable console, (4) flag-absent (unknown) block retained identically by all three. Audit found no live divergence — regression guard, not churn. RED #1: dropped disable-skip in `_aggregateMaxSessions` first pass → "prefer one enabled block" failed (`+3 -1`, maxSessions `4`→`1`); RED #2: `ServiceEnabled:false` forced-disabled despite truthy `Enabled` → contradictory test failed (`+3 -1`, uri graph→remote); `kvm_capability.dart` restored byte-clean (SHA `652a5038fa8ff0d…` unchanged, empty lib diff), 600-perm backup shredded → 4/4 GREEN. analyze 0 / full `flutter test` 1821 passed / 1 skipped (baseline 1817 +4); issues validate OK; diff --check clean; deps unchanged; test-only, emulator skipped (<7 days since last green 85/85), no TLS weakening.

- 2026-11-21 05:39 — EP-M1 residual direct-construction `supportsKvmIp` fallback guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_capability_kvmip_fallback_test.dart` (9 tests). The documented `KvmCapability.supportsKvmIp` fallback (graphical-only bit `graphicalKvmIp == null` → scan aggregate `connectTypes` for an exact, trimmed, case-insensitive `KVMIP`) had ZERO coverage — every prior assertion went through `fromManager` where the bit is always non-null — so a `?? false` regression or dropped trim/case would stay GREEN while breaking directly constructed widget fixtures. Pins canonical/lowercase/padded-mixed-case KVMIP, among-other-types, no-KVMIP, empty list, substring near-misses + authoritative-bit precedence. Audit found no live divergence — regression guard, not churn; EP-M1 checkbox stays open (residual fallback seam). RED #1 `?? false` → 4 failed (`+5 -4`); RED #2 removed trim/case → 3 failed (`+6 -3`); restored byte-clean (SHA `652a5038…` unchanged, empty lib diff), backup shredded → 9/9 GREEN. analyze 0 / full `flutter test` 1801 passed / 1 skipped (baseline 1792 +9); issues validate OK; diff --check clean; test-only, deps unchanged, emulator skipped (<7 days since last green 85/85), no TLS weakening.

- 2026-11-21 05:00 — RS-5 residual manager-source 3-level precedence guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_manager_source_precedence_test.dart` (13 tests). The documented `kvmManagerSourceUri` contract — usable override wins, a blank/non-string override must not shadow the body's `@odata.id` fallback, both converge on the derived manager-id path — had no test at the override→fallback hand-off with a body id DISTINCT from the derived path (the lone "non-string override ignored" test used a body id equal to the derived path, so it could not tell "body fallback" from "derived fallback"), and no blank-string-override test at all. Pins all 3 levels through the pure helper and `KvmCapability.fromManager`, plus cross-view agreement. Audit found no live divergence — regression guard, not churn; RS-5 checkbox stays landed (this is a residual precedence seam). RED proof: dropped the `fallback` term in `kvmManagerSourceUri` → 6 tests failed (`+7 -6`, source identity regressed to `/redfish/v1/Managers/BMC` instead of the body id); restored byte-clean (SHA `3ade1b21…` unchanged, empty lib diff), 600-perm backup shredded → 13/13 GREEN. analyze 0 / full `flutter test` 1787 passed / 1 skipped (baseline 1774 +13); issues validate OK; diff --check clean; test-only, deps unchanged, emulator skipped (<7 days since last green 85/85), no TLS weakening.
- 2026-11-21 03:47 — RM-1 residual multi-vendor `Oem` enablement precedence guard LANDED (agent:redfish-automation, FEATURE #009/#021): added `test/features/kvm/kvm_oem_multi_vendor_enablement_test.dart` (5 tests). `_consoleLikeBlock`'s documented rule that a flag-less metadata console-like block must not mask a real console's explicit `ServiceEnabled`/`Enabled` in a multi-vendor `Oem` payload was untested; a "return first console-like block" regression would reopen the #009 "KVM disabled on BMC" break. Pins flag-less nested/direct metadata before an explicit disable → disabled, explicit enable still wins, and both models agree on the same payload. Audit found no live divergence — regression guard, not churn; RM-1 checkbox stays open (this is the residual enablement-precedence seam, not the per-console chips item). RED proof: removed the enablement-member preference from `_consoleLikeBlock` → 3 tests failed (`+2 -3`); restored byte-clean (SHA `0bea1a6f…` unchanged, empty lib diff), 600-perm backup shredded → 5/5 GREEN. analyze 0 / full `flutter test` 1766 passed / 1 skipped (baseline 1761 +5); issues validate OK; diff --check clean; test-only, deps unchanged, emulator skipped (<7 days since last green 85/85), no TLS weakening.

- 2026-11-19 22:09 — RM-3 LANDED (agent:redfish-automation, FEATURE #009/#021): shared `FeatureRules.oemHasConsole` walk now requires a console-like key's value to be a JSON object — a `KVM`/`Console` key with a scalar/list/null value no longer fakes an OEM console on the discovery gate or either KVM model. +11 RED→GREEN tests (shared walk, both models, cross-view agreement + capability-card widget at 320/800/1300 px), analyze 0 / 1346 passed / 1 skipped, emulator 85/85. No dependency, no wire/transport change, no TLS weakening. `FeatureRules` is the shared walk all three surfaces call, so the central fix keeps them in agreement (the queue's model-only write hint was deliberately widened to this one shared helper).
- 2026-11-19 20:48 — OEM `ConnectUri` alias gap (agent:redfish-automation, FEATURE #009/#021): the shared `kvm_oem_uri.dart` helper (generic fallback for both KVM views) now recognizes the canonical Redfish `ConnectUri` member in addition to `Uri` (preferring `Uri`), so an unregistered vendor's `Oem.<Vendor>.KVM.ConnectUri` resolves on both the per-console card and capability card instead of showing no URI; enablement is read from the same block. +10 pure/parity tests + 1 card widget test (320 px), 2 outdated registry tests updated; analyze 0 / 1330 passed / 1 skipped; emulator 85/85; no dependency, no wire/transport change, no TLS weakening. Adjacent to EP-M2/RM-2 (neither acceptance box fully covered — no item checked off).
- 2026-11-19 15:35 — EP-M2 LANDED (agent:redfish-automation, FEATURE #009/#021): extracted shared pure `isExternalClientConsoleUri` / `externalClientConsoleProtocol` in `launch_plan.dart` on the fail-closed `_controlSafeTrimmedUri` gate; `KvmConsole` delegates (ad-hoc parse removed) and `KvmCapability` gains mirroring `requiresExternalConsoleClient` / `externalClientProtocolLabel` getters — both KVM views now classify/label VNC/RFB/KVMIP/serial endpoints identically. +7 helper/model/parity tests, analyze 0 / 1248 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 14:56 — RM-1 LANDED (agent:redfish-automation, FEATURE #009/#021): `kvmOemConsoleEnabled` now honors an explicit disable on a URI-less OEM console block (fallback to the console-like block only when no URI-bearing console exists); +6 tests, analyze 0 / 1237 passed / 1 skipped, emulator 85/85. No dependency, no TLS change.
- 2026-11-19 18:01 — RM-2-adjacent LANDED (agent:redfish-automation, FEATURE #009/#021): extracted pure `kvmSessionLimit(Object?)` in new `lib/features/kvm/models/kvm_session_limit.dart` (exported from the barrel) as the single source of truth for both KVM views' `MaxConcurrentSessions`; the two duplicated private parsers silently dropped an integer-valued JSON double (`4.0`) on both cards. Tolerates integral/finite/≤2^53 doubles + numeric strings, rejects fractional/non-finite/negative/blank/wrong types. 4 RED→GREEN behavioral assertions + 6 pure helper tests (+11 total); analyze 0 / 1289 passed / 1 skipped, emulator 85/85. No dependency, no TLS change. RM-2's non-map-payload portion remains open.
- 2026-11-20 00:43 — CB-1 LANDED (agent:redfish-automation, FEATURE #009/#021): `KvmConsole.clipboardTargetUri` no longer degrades to the raw BMC `@odata.id` when the fail-closed launch plan has no safe target. Added public `safeManagerUri` routing `sourceManagerUri` through the shared `isControlSafeConsoleUri` gate; unsafe sources become a pct-encoded `/redfish/v1/Managers/<managerId>` path (blank id → `manager`), so a hostile CRLF/NUL/separator/malformed-`%` @odata.id cannot reach the clipboard. +5 model +1 widget RED→GREEN tests, analyze 0 / 1399 passed / 1 skipped, emulator 85/85 (lib changed — §1.4 gate met). No dependency, no wire/transport change, no TLS weakening. Distinct from EP-M2/RM-2 (both still open); write widened to the per-console model + its widget test.
- 2026-11-20 05:19 — RM-5 LANDED (agent:redfish-automation, FEATURE #009/#021): 18-test cross-view agreement property group in `test/features/kvm/kvm_model_test.dart` over a 18-shape manager payload matrix (enabled/disabled graphical, mixed blocks, serial-only, generic OEM Uri/ConnectUri, padded/blank/non-string/hostile @odata.id, non-map values, messy connect types, double session limit, omitted flags). Pins manager identity, identical control-safe `safeManagerUri`, `serviceEnabled` agreement and enabled-console connect-type subset of the capability aggregate. No divergence found (surfaces already agree); 5 hostile-source cases confirmed RED by temporarily returning the raw source from `KvmCapability.safeManagerUri`, restored byte-clean. Analyze 0 / 1476 passed / 1 skipped; issues validate OK. Test-only; no lib/dependency/wire/fixture/TLS change, no URL opened. Emulator skipped (<7 days since last green 85/85).
