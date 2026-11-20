# FUTUREWORK

Living queue for the **`redfish-automation`** job (every 5 hours).

> Read this file first. Pick **one primary workstream** per run, finish it, verify
> it, then update this file. Detailed acceptance criteria live in `issues/open/`;
> reference the issue ID instead of duplicating it. New gaps discovered from
> official docs go here with a source URL.

- **Last updated: 2026-11-20 08:33 UTC (run, agent:redfish-automation — FEATURE — EP-T3 dedicated KVM decision-layer coverage gate for #009/#021: added `kKvmPlatformScopePrefixes` (`lib/features/kvm/platform/`) + pure `evaluateKvmPlatformGate()` (`GateResult` named `'kvm-platform'`, 75% threshold, reuses `CoverageSummary.scope()` path normalization) to `tool/coverage_gate.dart`, folded into `evaluateAllGates()` as a 4th enforced gate so a newly-uncovered classifier/adapter file cannot be diluted by the wide KVM aggregate; +6 tests in `test/tool/coverage_gate_test.dart` (29/29): platform-only 75% scoping, a fully-covered KVM aggregate cannot mask a 0% platform file, custom threshold/prefix, absolute+Windows paths, empty-scope fails closed, and the 4-gate `evaluateAllGates`/CI-JSON shape; 6-assertion RED proof (temporarily scoping to all KVM → `linesFound Expected: <100> / Actual: <400>`), restored byte-clean SHA unchanged; gate CLI on real lcov PASS overall 90.1% / scoped 90.4% / kvm 96.8% / kvm-platform 99.6%; analyze 0 / 1519 passed / 1 skipped (baseline 1510 +6 mine +3 concurrent rf-gate merge); issues validate OK; diff --check clean; no dependency/wire/fixture/product-lib change, no production TLS weakening; emulator skipped (tool/test-only, <7 days since last green 85/85); docs DEVELOPMENT.md/MULTI_DEPT.md/verify.yml updated to four gates.) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority; both issues' substantive acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended). Next unblocked slices in `queues/*.md`: EP-M1 (URI-scheme edges), EP-S1 (launch-path edges); EP-T3/RS-5/RS-6/RS-4/EP-T10/EP-P7 already landed.**
- **Prior: 2026-11-20 07:55 UTC (run, agent:redfish-automation — FEATURE — RS-5 console↔capability manager-source agreement for #009/#021: extracted one shared pure source-URI normalizer (`kvmManagerSource*` in new `lib/features/kvm/models/kvm_manager_source.dart`, exported from the `kvm.dart` barrel) used by both `KvmConsole.fromManager` and `KvmCapability.fromManager`, replacing duplicated private trim/fallback helpers — a padded `@odata.id` is trimmed, a blank/non-string one falls back to `/redfish/v1/Managers/<id>`, and the capability override still wins without a malformed value shadowing the body; both KVM views now converge on one source identity. +6 RED→GREEN tests in `test/features/kvm/kvm_service_test.dart` (3 pure-helper + 3 service-level, exact trimmed sources + cross-view/`fetchCapability(id)` agreement); RED proof: neutering the helper's trim failed 5 tests (`Expected: '/redfish/v1/Managers/PADDED' / Actual: '  /redfish/v1/Managers/PADDED  '`), restored byte-clean SHA unchanged. analyze 0 / 1510 passed / 1 skipped (baseline 1504 +6); issues validate OK; diff --check clean; no dependency/wire/transport/fixture change, no production TLS weakening; emulator skipped (pure model normalization, no wire change, <7 days since last green 85/85).) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority; both issues' substantive acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended). Next unblocked slices in `queues/*.md`: EP-T3 (coverage-gate scope), EP-M1 (URI-scheme edges), EP-S1 (launch-path edges); RS-5/RS-6/RS-4/EP-T10/EP-P7 already landed.**)
- **Prior: 2026-11-20 07:13 UTC (run, agent:redfish-automation — FEATURE — EP-P7 human-gate documentation invariant guard for #009/#021: added the missing "Human approval gate" section to `lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md` — an explicit, human-only approval gate requiring per-target (Linux/desktop, mobile Android/iOS, other desktop) validation evidence BEFORE any `webview_flutter` / `url_launcher` dependency bump or test-only TLS opt-in, with the flag-off external-browser + copy route and strict production TLS left byte-for-byte — plus `test/features/kvm/platform/human_gate_doc_guard_test.dart` (8 tests): a pure-Dart guard that fails closed if either decision doc stops recording the no-embedded-WebView decision / external-browser + copy final route, if the human approval gate section or any of its per-target evidence markers (Linux, mobile, webview_flutter, url_launcher, test-only TLS opt-in, human sign-off) disappear, and asserts `KvmWebViewPolicy.productionDefault` keeps the WebView flag OFF, TLS strict, self-signed refused across all 8 signal combos while only the test-only opt-in may accept self-signed on HTTPS. 3 in-test RED proofs + 1 real-file RED proof (temporarily removing the gate heading → 3 failures; restored byte-clean, SHA `27801b15…` unchanged → 8/8 GREEN); no product Dart, wire, dependency, fixture or emulator change, no URL opened, no production TLS weakening, no human approval granted; analyze 0 / 1500 passed / 1 skipped (baseline 1492 +8); issues validate OK; diff --check clean; emulator skipped (doc + test-only, <7 days since last green 85/85).) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority. Both issues' substantive acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended). Next slices in `queues/*.md`: EP-U7 (full merged-Semantics audit), EP-T4 (fixture/CI guard), RS-5 (service manager-source agreement); EP-P7/EP-T10/RS-6/RM-5 already landed.**
- **Prior: 2026-11-20 06:33 UTC (run, agent:redfish-automation — FEATURE — EP-T10 canonical OpenBMC console fixture + fixture-drive tests for #009/#021: added `test/fixtures/redfish/openbmc_console_manager.json` — a committed, valid Redfish `Manager.v1_19_0` BMC with HTML5-over-HTTPS GraphicalConsole (ServiceEnabled true, [KVMIP, HTML5], MaxConcurrentSessions 2, ConnectUri `https://bmc.example/kvm`), a disabled SSH/Telnet SerialConsole, an HTML5 RemoteConsole and `Oem.OpenBMC.KVM.Uri` — plus `test/features/kvm/kvm_openbmc_fixture_test.dart` (10 tests) driving both shared factories over it: console enumeration, launch-safe in-app-classified graphical console with a safe production `externalBrowser` / self-signed-false plan, disabled-serial + remote-HTML5 + OEM-secure-browser paths, capability support/aggregation/resolved-URI and cross-view agreement, plus a mutation-sensitivity test. RED proof: corrupting the fixture's graphical ConnectUri to plaintext HTTP failed 3 drive tests (`Expected: https… / Actual: http…`); restored byte-clean. No `lib/`, dependency, wire/TLS change, no URL opened; analyze 0 / 1492 passed / 1 skipped; issues validate OK; emulator skipped (test-only, <7 days).) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority. Both issues' substantive acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended). Next slices in `queues/*.md`: EP-U7 (full merged-Semantics audit), EP-P7 (human-gate doc invariant guard); RM-5/RS-6/EP-T10 already landed.**
- **Prior: 2026-11-20 05:55 UTC (run, agent:redfish-automation — FEATURE — RS-6 manager-set identity/cardinality invariant for #009/#021: appended 3 tests to `test/features/kvm/kvm_service_test.dart` over an in-temp 4-manager mockup (duplicate/padded/plain-string member links, blank/non-string members; enabled secure-HTTPS graphical + SSH serial + no-URI OEM + disabled graphical consoles), pinning (1) identical manager-id sets across `fetchConsoles()` / `fetchCapabilities()`, (2) exactly one console + one capability card per manager, and (3) deterministic launch-safe primary (`fetchPrimaryConsole()` == `pickPrimary()`, member of the set, `route == externalBrowser`, never in-app/self-signed, exact trimmed target). RED proof: temporarily `pickPrimary → consoles.first` made the primary test fail `Expected: MgrGraph / Actual: MgrDisabled`; lib restored byte-clean (hash unchanged, empty lib diff), all 3 GREEN. No lib/dependency/wire/TLS change, no URL opened; analyze 0 / 1479 passed / 1 skipped; issues validate OK; diff --check clean; emulator skipped (test-only, <7 days).) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority. Both issues' substantive acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended). Next slices in `queues/*.md`: EP-U7 (full merged-Semantics audit), EP-P7 (human-gate doc invariant guard), EP-T10 (canonical OpenBMC console fixture).**
- **Prior: 2026-11-20 05:19 UTC (run, agent:redfish-automation — FEATURE — RM-5 cross-view agreement property test for #009/#021: appended 18 tests to `test/features/kvm/kvm_model_test.dart` — a matrix of 18 manager payload shapes (enabled/disabled graphical, mixed graphical+serial+remote, serial-only, generic OEM Uri/ConnectUri enabled+disabled, padded/blank/non-string @odata.id, five hostile @odata.id values with CRLF/NUL/U+2028/NBSP/malformed-%, non-map console values, duplicate/blank/non-string types, double session limit, omitted enablement) parsed through BOTH models, pinning manager identity, identical control-safe `safeManagerUri` (incl. hostile sources), enablement agreement and enabled-console connect-type subset of the capability aggregate. No divergence found — surfaces already agree; 5 hostile-source cases confirmed RED by temporarily un-sanitizing `KvmCapability.safeManagerUri` (restored byte-clean). analyze 0 / 1476 passed / 1 skipped (baseline 1457 +18, +1 from concurrent gate chore 252b944); issues validate OK; diff --check clean; no lib/dependency/wire/fixture/tool change, no production TLS weakening; emulator skipped (test-only, <7 days).) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority. Both issues' remaining acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended). Next slices in `queues/*.md`: RS-6 (service manager-set identity/cardinality), EP-U7 (full merged-Semantics audit), EP-P7 (human-gate doc invariant guard), EP-T4 (fixture/CI guard).**
- **Prior: 2026-11-20 04:50 UTC (run, agent:redfish-automation — FEATURE — EP-T9 launch-status single-source guard for #009/#021: added `test/tool/launch_status_single_source_guard_test.dart` (6 tests) — a dependency-free, comment/string-aware pure-Dart guard that derives the seven long `kvmLaunchStatusText` launch-status a11y messages FROM `kvm_models.dart` at test time (multi-line adjacent literals + `${externalProtocol}` interpolation pieces → distinctive fingerprints; the RU-2 notice authority excluded as another copy authority), asserts all 7 `case KvmLaunchStrategy.` branches + ≥12 fingerprints remain, and fails closed if any other product `lib/features/kvm/**.dart` hardcodes one of those fragments (card↔viewer visible-text/announced-label copy drift) or redefines the shared function; also pins both launch surfaces call the shared function. 2 RED proofs (planted copy + redefinition → violation), real-repo scan clean; analyze 0 / 1454 passed / 1 skipped (baseline 1448 +6); issues validate OK; git diff --check clean; no `lib/`, dependency, wire/fixture/product-tool change, no production TLS weakening; DMTF emulator skipped (test-only, <7 days since last green 85/85). Complements the RU-2 notice guard, which pins only the six shorter notice constants.) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority. Remaining acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended); the unblocked small-slice queue is exhausted, so only genuine tested invariant guards remain. Next slices in `queues/*.md`: RU-2 full merged-Semantics audit, EP-T4 fixture/CI guard, EP-T3 coverage gate.**
- **Prior: 2026-11-20 04:06 UTC (run, agent:redfish-automation — FEATURE — RU-2 cross-surface notice single-source guard for #009/#021: added `test/tool/notice_single_source_guard_test.dart` (6 tests) — a dependency-free, comment/string-aware guard that parses the six canonical `kvm_transport_notice.dart` constants at test time (incl. multi-line adjacent literals) and fails closed if any other product KVM view hardcodes a notice literal (cross-surface screen-reader copy drift) or redefines a canonical constant name. 2 RED proofs (planted hardcoded copy + redefinition → flagged), 2 GREEN proofs (identifier reference + comments/`https://` clean), real-repo view scan clean; analyze 0 / 1445 passed / 1 skipped (baseline 1439 +6); issues validate OK; git diff --check clean; no `lib/`, dependency, wire/fixture/tool change, no production TLS weakening; DMTF emulator skipped (test-only, <7 days since last green 85/85). RS-5/EP-S2/EP-U6 and RU-2's core shared strings were already implemented, so this pins the remaining single-source invariant instead of verification-only churn.) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority. Remaining acceptance is human-gated (platform WebView + BMC TLS validation — do NOT do unattended); the unblocked small-slice queue is exhausted, so only genuine tested invariant guards remain. Next slices in `queues/*.md`: RU-2 full merged-Semantics audit, EP-T4/T3, EP-P4 (human-gated).**
- **Prior: 2026-11-20 03:27 UTC (run, agent:redfish-automation — FEATURE — EP-P6 production-policy final-route invariant test for #009/#021: added `test/features/kvm/platform/production_route_invariant_test.dart` (3 tests) — a pure-Dart cross-product property test over 8 console-signal combos × 12 URI forms (96 cases) under `KvmWebViewPolicy.productionDefault` that pins the four machine-checkable invariants of the human-gated no-WebView decision: route NEVER `inAppWebView`, `acceptSelfSigned` NEVER true, every non-null `targetUri` control-safe (`isControlSafeConsoleUri`) and trimmed, and any blank/control-unsafe URI always degrades to `copyOnly` with a null target even under a stale/lying `hasSecureUri` signal. 2 tests confirmed RED by temporarily weakening the flag-off guard in `webview_policy.dart` (`Expected: not inAppWebView / Actual: inAppWebView`), file restored byte-clean (0 TEMP occurrences) → all 3 GREEN; analyze 0 / 1439 passed / 1 skipped (baseline 1436 +3, re-verified on post-gate HEAD `4aad49a` after a concurrent rf-gate PASS merge landed mid-run); no dependency, no lib/wire/fixture/tool change, no production TLS weakening; DMTF emulator skipped (<7 days since last green 85/85, no lib/wire change); issues validate OK. RS-5's model contract was already satisfied in commit `555eff40` (2026-11-18), so EP-P6 was the genuine next unblocked slice.) **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority; next unblocked slices are RS-5 (rf-service — console↔capability agreement test; model half already normalized), EP-S2 (rf-service — safe-primary selection), EP-M2 (rf-model — external-client classifier parity).** Next slices in `queues/*.md`: RS-5, EP-S2, EP-M2.)**
- **Prior: 2026-11-20 02:42 UTC (run, agent:redfish-automation — FEATURE — EP-T8 control-safe manager-source display guard for #009/#021: added the test-only pure-Dart guard `test/tool/manager_source_display_guard_test.dart` (10 tests) that scans every product `lib/**.dart` with a comment/string-aware state machine (doc mentions and `https://` URLs stay clean, filename is never immunity) and fails closed if a raw BMC `@odata.id`-derived `sourceManagerUri` is interpolated into a `Text` / `SelectableText` / `Semantics` string literal or handed straight to a `Clipboard.setData` / `ClipboardData` payload without routing through `safeManagerUri` / `clipboardTargetUri` / `isControlSafeConsoleUri`. 8 assertions confirmed RED by planting raw-source interpolations/sink args in a temp scan root (raw → violation, gated → clean) → all 10 GREEN after; fixed 2 redundant-`!` analyzer lints. analyze 0 / 1433 passed / 1 skipped (baseline 1423 +10); no `lib/`, dependency, wire/fixture change, no production TLS weakening; CI already runs it via `flutter test --coverage`. DMTF emulator skipped (test-only guard, no lib/wire/tool change, <7 days since last green 85/85). **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority; next unblocked slices are RS-5 (rf-service — console↔capability manager-source agreement) and EP-P6 (rf-platform — production-policy final-route invariant test).** Next slices in `queues/*.md`: RS-5, EP-P6.)**
- **Gate: 2026-11-20 08:34 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `14bf890` into `main` via `--no-ff` (merge `901db9d`) after `rf-platform-check` run#9688 returned an explicit `CHECK: PASS` for that exact tip (exit 0, 83.5 s; analyze 0, targeted `launch_plan_test.dart` 101/101 on the branch incl. 3 new trailing-dot numeric-host RED-GREEN tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch tip cross-checked unchanged post-check (HEAD `14bf890`), exactly one unique commit past merge-base `fa2121d` (already in main via merge `12ca641`), closing another parser-differential host-spoofing gap in the dependency-free launch-plan authority classifier: `Uri.tryParse` reports `https://2130706433./` / `https://0x7f000001./` as a non-empty HTTPS DNS host, but the WHATWG "ends in a number" check skips one trailing dot and a browser/WebView still resolves them to IP literals (127.0.0.1), so under a stale secure flag + test opt-in a purely syntactic re-check could grant in-app rendering + self-signed acceptance on a loopback/internal host. `_isNonCanonicalNumericHost` now strips one trailing absolute-FQDN root dot before the hex/decimal/abbreviated/leading-zero numeric checks; a real trailing-dot DNS name (`bmc.example.`) and canonical IPv4/IPv6 stay launchable — no valid target lost, no dependency, no production TLS weakened. Auto-merged cleanly (no conflicts). Post-merge verify in-tree at `901db9d`: `flutter analyze` 0; full `flutter test --coverage` 1513 passed / 1 skipped; three coverage gates PASS overall 90.1% (5780/6413) / scoped 90.4% (2119/2345) / kvm 96.8% (1057/1092); `python3 issues/issues.py validate` OK; `git diff --check` clean; staged-diff secret scan clean; first-parent diff = 3 allowlisted files; targeted `launch_plan_test.dart` 117/117, platform suite 159/159. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision-helper only; <7 days since last green 85/85). No issue closed. Concurrent `redfish-automation` WIP in the shared worktree (`tool/coverage_gate.dart` 4th kvm-platform gate + `DEVELOPMENT.md`) left unstaged/untouched.**
- **Gate: 2026-11-20 07:23 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `fa2121d` into `main` via `--no-ff` (merge `12ca641`) after `rf-platform-check` run#9612 returned an explicit `CHECK: PASS` for that exact tip (exit 0, 67.1 s; analyze 0, targeted `launch_plan_test.dart` 114/114 on the merged tree incl. 4 new signed/overflow-port tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch tip cross-checked unchanged post-check (`fa2121de1ff3`), exactly one unique commit past merge-base `188a6b1` (already in main via merge `46d8804`), closing another parser-differential host-spoofing/crash gap in the dependency-free launch-plan authority classifier: `Uri.tryParse` accepts a signed port (`:-1` → negative `Uri.port`; `:+443` silently ignores the sign) and an arbitrarily long decimal port whose `Uri.port` getter THROWS `FormatException` on overflow, all still reported as an HTTPS URI with a non-empty host, so a purely syntactic re-check calls them "secure" or crashes the caller — while browser/WebView (WHATWG URL) parsers reject signed/negative and >16-bit ports. Under a stale secure flag + test opt-in that differential could grant in-app rendering + self-signed acceptance on a malformed/mismatched authority or crash the caller. Added `_hasNonCanonicalPort` (raw-authority port-token check: reject non-digits, negative/signed, >5 significant digits, >65535 before `Uri.port` is read) folded into the shared `_isHttpUriWithSchemes` fail-closed gate, plus a guarded `Uri.port` read (`try` / `on FormatException → false`) with an explicit `<0 || >65535` range check as defense in depth. A real BMC console port is canonical digits 0..65535, so absent/empty ports, leading zeros, userinfo and IPv6 hosts stay launchable — no valid target lost, no dependency, no production TLS weakened. Two merge conflicts: `launch_plan.dart` (branch authored against the old bool `_uriHasSecureHttpsTarget`, main uses the shared `String?`-returning `_controlSafeTrimmedUri` + `_isHttpUriWithSchemes`) resolved by keeping main's shared-gate structure, prepending the branch's `_hasNonCanonicalPort` helper and folding its check into `_isHttpUriWithSchemes`; `LAUNCH_FALLBACK.md` (stale test counts) resolved with measured merged values 114 targeted / 156 platform (new rationale paragraph + test-group label auto-merged); `launch_plan_test.dart` auto-merged with all 4 RED→GREEN tests preserved. Post-merge verify in-tree at `12ca641` (clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1504 passed / 1 skipped (baseline 1500 +4 merged tests); three coverage gates PASS overall 90.1% (5773/6406) / scoped 90.4% (2119/2345) / kvm 96.8% (1050/1085); `python3 issues/issues.py validate` OK; `git diff --check` clean; staged-diff secret scan clean; first-parent diff = 3 allowlisted files; targeted 114/114, platform suite 156/156. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision-helper only; <7 days since last green 85/85). No issue closed.**
- **Gate: 2026-11-20 06:17 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `188a6b1` into `main` via `--no-ff` (merge `46d8804`) after `rf-platform-check` run#9534 returned an explicit `CHECK: PASS` for that exact tip (exit 0, 57.5 s; analyze 0, targeted `launch_plan_test.dart` 94/94 on the branch incl. 3 new out-of-range-port tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch tip cross-checked unchanged post-check (HEAD `188a6b1`), exactly one unique commit past merge-base `23b5cb2` (already in main via merge `fbbef10`), closing another parser-differential host-spoofing gap in the dependency-free launch-plan authority classifier: `Uri.tryParse` accepts any non-negative decimal port and still reports a non-empty HTTPS host (`https://bmc.example:99999/console` → port `99999`), so a purely syntactic re-check calls it "secure", while browser/WebView (WHATWG URL) parsers reject a port above the 16-bit maximum 65535 and other launchers may wrap it modulo 65536 to a DIFFERENT service. Under a stale secure flag + test opt-in that parser differential could grant in-app rendering + self-signed acceptance on a malformed/mismatched authority. Added a fail-closed `if (parsed.hasPort && parsed.port > 65535) return false;` in the shared `_uriHasSecureHttpsTarget` classification; a real BMC console port is always 0..65535, so absent/empty (default) and in-range ports, userinfo and IPv6 hosts stay launchable — no valid target lost, no dependency, no production TLS weakened. One merge conflict: `LAUNCH_FALLBACK.md` stale test counts → measured merged values 110 targeted / 144 platform (new rationale paragraph + test-group label auto-merged); `launch_plan.dart` + `launch_plan_test.dart` auto-merged cleanly with all 3 RED→GREEN tests preserved. Post-merge verify in-tree at `46d8804` (clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1482 passed / 1 skipped (baseline 1479 +3 merged tests); three coverage gates PASS overall 90.1% (5750/6382) / scoped 90.4% (2119/2345) / kvm 96.8% (1027/1061); `python3 issues/issues.py validate` OK; `git diff --check` clean; first-parent diff = 3 allowlisted files; targeted post-merge 110/110, platform suite 144/144. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision-helper only; <7 days since last green 85/85). No issue closed.**
- **Gate: 2026-11-20 05:13 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `23b5cb2` into `main` via `--no-ff` (merge `fbbef10`) after `rf-platform-check` run#9446 returned an explicit `CHECK: PASS` for that exact tip (exit 0, 59.0 s; analyze 0, targeted `launch_plan_test.dart` 91/91 on the branch incl. 3 new NFKC vulgar-fraction tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch has exactly one unique commit past merge-base `1ea3694` (already in main via merge `6362e53`), closing another parser-differential host-spoofing gap in the dependency-free launch-plan authority classifier: a percent-encoded vulgar fraction (Unicode `No`, e.g. U+00BD `1/2`) NFKC-expands to digit + U+2044 FRACTION SLASH + digit, and IDNA/UTS-46 maps U+2044 to ASCII `/`, so a decode+IDNA launcher resolves a different authority than `Uri.tryParse` reports (which keeps the escape encoded in the host); under a stale secure flag + test opt-in that could grant in-app rendering + self-signed acceptance on a spoofed host. Added `_nfkcFractionSlashCodePoints` (U+00BC..BE, U+2150..5F, U+2189), folded into the shared fail-closed `_authorityHasAsciiCompatibilityConfusable`; authority-scoped only (same escape in path/query and legitimate pct-encoded UTF-8 hosts stay launchable), no valid target lost, no dependency, no production TLS weakened. One merge conflict: `LAUNCH_FALLBACK.md` stale test counts → measured merged values 107 targeted / 141 platform (new rationale paragraph + test-group label auto-merged); `launch_plan.dart` + `launch_plan_test.dart` auto-merged cleanly with all 3 RED→GREEN tests preserved. Post-merge verify in-tree at `fbbef10` (clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1457 passed / 1 skipped (baseline 1454 +3 merged tests; one transient parallel-load flake in `power_view_test.dart` — isolated 26/26, clean on full re-run); three coverage gates PASS overall 90.1% (5749/6381) / scoped 90.4% (2119/2345) / kvm 96.8% (1026/1060); `python3 issues/issues.py validate` OK; `git diff --check` clean; first-parent diff = 3 allowlisted files; targeted post-merge 107/107, platform suite 141/141. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision-helper only; <7 days since last green 85/85). No issue closed.**
- **Gate: 2026-11-20 04:25 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `1ea3694` into `main` via `--no-ff` (merge `6362e53`) after `rf-platform-check` run#9378 returned an explicit `CHECK: PASS` for that exact tip (exit 0, started 05:20:14 UTC, 49.5 s; analyze 0, targeted `launch_plan_test.dart` 88/88 on the branch incl. 3 new empty-DNS-label tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch has exactly one unique commit past merge-base `4fe08db` (already in main via merge `66e6adb`), adding authority-scoped fail-closed rejection of empty DNS labels in the launch-plan URI host: a leading dot (`.bmc.example`), consecutive dots (`bmc..example`) or a double trailing dot (`bmc.example..`) leaves an empty label; `Uri.tryParse` reports such a host as a non-empty HTTPS host while a launcher may collapse the empty label / treat the leading dot as a relative reference and contact a different authority — a parser-differential host-spoofing vector that under a stale flag + test opt-in could grant in-app rendering + self-signed acceptance on a mismatched host. Added `_hasEmptyDnsLabel` (IPv6 literals / degenerate all-dot host unaffected; exactly one trailing dot = legitimate absolute FQDN kept); folded its check into the shared `_isHttpUriWithSchemes` fail-closed gate next to main's `_hasDegenerateAuthorityHost(parsed)`. No valid target lost, no dependency, no production TLS weakened. Two merge conflicts: `launch_plan.dart` (branch's helper was authored against the old bool `_uriHasSecureHttpsTarget`, main uses the shared `String?`-returning `_controlSafeTrimmedUri`) resolved by keeping main's shared-gate structure and prepending the branch's helper + fold-in check; `LAUNCH_FALLBACK.md` (both sides' stale test counts) resolved with measured merged counts 104 targeted / 138 platform (new rationale paragraph + test-group label auto-merged); `launch_plan_test.dart` auto-merged with all 3 RED→GREEN tests preserved. Post-merge verify in-tree at `6362e53` (clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1448 passed / 1 skipped (baseline 1445 +3 merged tests); three coverage gates PASS overall 90.1% (5748/6380) / scoped 90.4% (2119/2345) / kvm 96.8% (1025/1059); `python3 issues/issues.py validate` OK; `git diff --check` clean; first-parent diff = 3 allowlisted files. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision helper only; <7 days since last green 85/85). No issue closed.**
- **Gate: 2026-11-20 03:24 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `4fe08db` into `main` via `--no-ff` (merge `66e6adb`) after `rf-platform-check` run#9287 returned an explicit `CHECK: PASS` for that exact tip (exit 0, started 04:14:39 UTC, ~62.6 s; analyze 0, targeted `launch_plan_test.dart` 85/85 green on the branch incl. 3 new non-canonical numeric-host tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch has exactly one unique commit past merge-base `ae93bdf` (already in main via merge `93806d0`), closing the parser-differential numeric-host host-spoofing gap in the dependency-free launch plan: legacy/WHATWG URL parsers resolve `0x7f000001` (hex), `2130706433` / `0` (decimal integer), `127.1` / `127.0.1` (abbreviated dotted) and `0177.0.0.1` (leading-zero/octal) hosts to IP literals (often loopback/internal), while `Uri.tryParse` reports them as opaque DNS names with a non-empty HTTPS host — under a stale secure flag + test opt-in that differential could grant in-app rendering and self-signed acceptance on a mismatched/spoofed host. Added `_isAllDigits` + `_isCanonicalIpv4Octet` + `_isNonCanonicalNumericHost`; the call site auto-merged into the shared `_isHttpUriWithSchemes` gate as `if (_isNonCanonicalNumericHost(parsed.host)) return false;`. Only canonical dotted-quad IPv4 / IPv6 / DNS/punycode hosts stay launchable — no valid target lost, no dependency, no production TLS weakened. Two merge conflicts: `launch_plan.dart` (branch's new helper block was authored against the old bool `_uriHasSecureHttpsTarget`, main uses the `String?`-returning `_controlSafeTrimmedUri`) resolved by keeping main's shared-gate structure and folding the three helpers in before it; `LAUNCH_FALLBACK.md` (both sides' stale test counts) resolved with the measured merged counts 101 targeted / 132 platform (new rationale paragraph + test-group list append auto-merged); `launch_plan_test.dart` auto-merged with all 3 RED→GREEN tests preserved. Post-merge verify in-tree at `66e6adb` (clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1436 passed / 1 skipped (baseline 1433 +3 merged tests; two transient parallel-load flakes on earlier coverage runs, clean on re-run); three coverage gates PASS overall 90.1% (5741/6373) / scoped 90.4% (2119/2345) / kvm 96.8% (1018/1052); `python3 issues/issues.py validate` OK; `git diff --check` clean; staged-diff secret scan clean; first-parent diff = 3 allowlisted files. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision helper only; <7 days since last green 85/85). No issue closed.**

- **Prior: 2026-11-20 02:03 UTC (run, agent:redfish-automation — FEATURE — EP-U6 control-safe manager-source display on all three KVM surfaces for #009/#021: routed the viewer's "No direct console URI. Manager source: …" row, the per-console card's "No console connect URI available. Open externally: …" row and the capability card's "No console URI resolved. Source: …" row through the shared fail-closed `KvmConsole.safeManagerUri` / `KvmCapability.safeManagerUri` getters, so a hostile BMC `@odata.id` can no longer render CRLF / a fake header / NUL / separators into visible Text or the merged `excludeSemantics` label (a control-safe source stays byte-for-byte; the sanitized endpoint stays visible — fail closed, not hidden; visible text == announced label on every surface). +12 RED→GREEN widget tests (10 RED pre-fix; 320/800/1300 px no-overflow on all three surfaces); analyze 0 / 1420 passed / 1 skipped (baseline 1408 +12); DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK. Display-only slice limited to `lib/features/kvm/views/**`; no dependency, no wire/fixture change, no production TLS weakening. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority; next unblocked slice is EP-T8 (rf-tooling — control-safe manager-source display guard closing the CB-1 class across all surfaces).** Next slices in `queues/*.md`: EP-T8, RS-5 service manager-source agreement, EP-P6 production-policy invariant test.)**
- **Gate: 2026-11-20 02:15 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `ae93bdf` into `main` via `--no-ff` (merge `93806d0`) after `rf-platform-check` run#9204 returned an explicit `CHECK: PASS` for that exact tip (exit 0, started 02:09:48 UTC ~1 min after the builder produced branch HEAD `ae93bdf`, ~60 s duration; analyze 0, targeted `launch_plan_test.dart` 82/82 green on the branch incl. 3 new encoded unreserved-ASCII rejection tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch has exactly one unique commit past merge-base `a226449` (already in main via merge `f64af05`), closing the final RFC 3986 unreserved-ASCII decode-order gap in the launch plan's fail-closed authority classifier: `Uri.tryParse` DECODES percent-encoded unreserved bytes (`%62%6D%63`→`bmc`, `%2D`→`-`, `%5F`→`_`, `%7E`→`~`) into a different host than a non-decoding launcher, so one raw URI names two authorities — under a stale secure flag + test opt-in that parser differential could grant in-app rendering and self-signed acceptance on a spoofed host. Added `_isUnreservedAsciiOctet` + `_authorityHasEncodedUnreservedAscii`, folded into the single shared `String?`-returning `_controlSafeTrimmedUri` gate as `return null` (the `%2E` dot case already had a dedicated rule; encoded unreserved text in path/query and legitimate pct-encoded non-ASCII UTF-8 host bytes stay launchable). One merge conflict in `launch_plan.dart` (branch's older bool `return false` structure predated main's shared `String?`/`return null` gate) resolved by keeping main's shared-gate structure and folding in the branch's new helper + check as `return null`; `LAUNCH_FALLBACK.md` conflict (both sides' encoded-C0/DEL prose) resolved keeping main's fuller paragraph + appending the new unreserved-ASCII paragraph, with measured merged counts 98 targeted / 129 platform; `launch_plan_test.dart` auto-merged with all 3 new RED→GREEN tests preserved. Post-merge verify in-tree at `93806d0` (clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1423 passed / 1 skipped (baseline 1420 +3 merged tests); three coverage gates PASS overall 90.1% (5721/6353) / scoped 90.4% (2119/2345) / kvm 96.7% (998/1032); `python3 issues/issues.py validate` OK; `git diff --check` clean; staged-diff secret scan clean. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision helper only; <7 days since last green 85/85). No issue closed.**
- **Prior: 2026-11-20 01:20 UTC (run, agent:redfish-automation — FEATURE — RM-4 capability-side control-safe manager-source getter for #009/#021: added `KvmCapability.safeManagerUri` mirroring `KvmConsole.safeManagerUri` — a control-safe BMC-supplied `@odata.id` passes byte-for-byte through the shared `isControlSafeConsoleUri` gate, an unsafe/null one degrades to a deterministic pct-encoded `/redfish/v1/Managers/<managerId>` path (blank → `manager`), giving the capability card a model-side single source of truth; raw source field unchanged, no wire shape change. +6 RED→GREEN pure-model tests (compile-RED pre-fix); analyze 0 / 1408 passed / 1 skipped (baseline 1402 +6); DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK. Model-only slice (rf-model dept); the UI display consumer is the separate EP-U6 slice. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority; next unblocked slice is EP-U6 (rf-ui — three-surface safe-source display consumer).** Next slices in `queues/*.md`: EP-U6, EP-S1 service launch edges, EP-U1 fullscreen scaffold, EP-M1 remaining URI-scheme edges.)**
- **Prior: 2026-11-20 00:43 UTC (run, agent:redfish-automation — FEATURE — CB-1 control-safe clipboard manager-source fallback for #009/#021: `KvmConsole.clipboardTargetUri` now degrades to a shared-gate-validated `safeManagerUri` instead of the raw BMC-supplied `@odata.id`, closing a CRLF/NUL header/clipboard-injection gap in the card's "Copy connect info" action; a hostile source is replaced by a pct-encoded `/redfish/v1/Managers/<managerId>` path that cannot carry the code point back onto the clipboard. +5 pure-model +1 widget RED→GREEN tests; analyze 0 / 1399 passed / 1 skipped (baseline 1393 +6); DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK; no dependency/wire/fixture change, no production TLS weakening. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next slices in `queues/*.md`: EP-S1 service launch edges, EP-U1 fullscreen scaffold, EP-M1 remaining URI-scheme edges.)**
- **Gate: 2026-11-20 01:07 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `a226449` into `main` via `--no-ff` (merge `f64af05`) after `rf-platform-check` run#9124 returned PASS for that exact tip (exit 0, started ~01:03 UTC ~3 s after builder run#9115 produced branch HEAD `a226449`, ~58 s duration; analyze 0, targeted platform tests green on the branch, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch has exactly one unique commit past merge-base `2275723` (already in main via merge `59ca015`), extending the authority-scoped NFKC/IDNA fail-closed confusable set in the launch plan to compatibility characters that Unicode NFKC folds to plain ASCII letters/digits (U+212A KELVIN SIGN→K, U+017F LONG S→s, circled Latin U+24B6..U+24E9, circled digits U+2460..U+2473, superscript/subscript digits, Roman numerals U+2160..U+217F, squared/negative circled capitals U+1F130..U+1F189): `Uri.tryParse` keeps each escape encoded and reports a "secure" host while a decode+IDNA launcher resolves a different ASCII authority — a parser-differential host-spoofing vector that under a stale flag + test opt-in could grant in-app rendering and self-signed acceptance on a spoofed host. Each fails closed, authority-scoped (encoded forms in path/query and non-ASCII that NFKC-folds to non-ASCII — e-acute/euro/emoji — stay launchable); no valid target lost, no dependency, no production TLS weakened. One merge conflict in `LAUNCH_FALLBACK.md` (stale test-count prose on both sides) resolved with the measured merged counts 95 targeted / 121 platform; `launch_plan.dart` + `launch_plan_test.dart` auto-merged cleanly with all 3 new RED→GREEN tests preserved. Post-merge verify in-tree at `f64af05` (clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1402 passed / 1 skipped (baseline 1399 +3 merged tests); three coverage gates PASS overall 90.0% (5701/6333) / scoped 90.4% (2119/2345) / kvm 96.6% (978/1012); `python3 issues/issues.py validate` OK; `git diff --check` clean; staged-diff secret scan clean. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision helper only; <7 days since last green 85/85). No issue closed.**
- **Prior: 2026-11-20 00:02 UTC (run, agent:redfish-automation — FEATURE — EP-T7 emulator prerequisite doctor for #009/#021: added `tool/emulator_doctor.dart` + `test/tool/emulator_doctor_test.dart` (18 tests) — a pure-Dart, dependency-free, check-only prerequisite doctor that fails closed with actionable diagnostics when `docker`/`curl`/`jq`/`redfishtool` is missing on PATH or the repo-relative fixture `test/fixtures/redfish/dmtf_mockup` is absent (never a container-internal DSP2043 path); `--check` never starts containers/network/credentials. 4 assertions confirmed RED pre-fix by temporarily neutering the evaluator (`Expected: length <1>/<4> / Actual: []`) → GREEN 18/18; real-repo `--check` names missing `redfishtool` + exit 1 (correct here). `dart format` + analyze 0 / 1390 passed / 1 skipped (baseline 1372 +18); issues validate OK; git diff --check clean. No `lib/`, dependency, wire/transport/fixture change, no production TLS weakening; `tool/emulator/run_tests.sh` remains the standard suite, `testing/run_emulator_harness.sh` optional. DMTF emulator skipped (no lib/wire/fixture change, <7 days since last green 85/85). **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next slices in `queues/*.md`: EP-S1 service launch edges, EP-U1 fullscreen scaffold.)**
- **Gate: 2026-11-20 00:18 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `2275723` into `main` via `--no-ff` (merge `59ca015`) after `rf-platform-check` run#9056 returned an explicit `CHECK: PASS` for that exact tip (exit 0, ~60 s; analyze 0, targeted `launch_plan_test.dart` 76/76 on the branch incl. 3 new fullwidth-ASCII-confusable tests +73/+74/+75, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch has exactly one unique commit past merge-base `fc3c648` (already in main via merge `b87a33a`), extending the authority-scoped fail-closed IDNA/NFKC confusable set in the platform launch plan from structural delimiters to the full fullwidth ASCII look-alike block (U+FF01..U+FF5E): a decode+IDNA launcher folds `%EF%BD%82%EF%BD%8D%EF%BD%83.example` (fullwidth "bmc") to `bmc.example` while `Uri.tryParse` reports the encoded form as a "secure" host — a parser-differential host-spoofing vector that under a stale flag + test opt-in could grant in-app rendering and self-signed acceptance on a spoofed host. Renamed `_authorityHasCompatibilityDelimiter` → `_authorityHasAsciiCompatibilityConfusable`, added the fullwidth range check, authority-scoped only (encoded confusables in path/query and encoded non-ASCII folding to non-ASCII — e-acute/euro/emoji — stay launchable), no valid target lost. One merge conflict in `launch_plan.dart` (branch's old bool structure predated main's shared `String?`-returning `_controlSafeTrimmedUri` gate): resolved by keeping main's shared-gate `return null` structure and folding in the branch's renamed helper + doc intent; `launch_plan_test.dart` auto-merged with all 3 new tests. Post-merge verify at `59ca015` (tree clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1393 passed / 1 skipped (baseline 1390 +3 merged tests); three coverage gates PASS overall 90.0% / scoped 90.4% / kvm 96.6%; `python3 issues/issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped (no wire/transport/fixture/tool change — dependency-free decision helper only; <7 days since last green 85/85). No issue closed.**
- **Prior: 2026-11-19 23:25 UTC (run, agent:redfish-automation — FEATURE — EP-P5 no-WebView product-import policy guard for #009/#021: added the test-only pure-Dart guard `test/features/kvm/platform/product_import_policy_test.dart` (19 tests) that machine-checks the resolved no-embedded-WebView / external-browser + copy decision — every product `lib/**.dart` is scanned (comment/string/filename aware) for `webview_flutter` / `flutter_inappwebview` / `url_launcher` imports and raw `MethodChannel` / `EventChannel` console channels, and `pubspec.yaml` / `pubspec.lock` for forbidden dependencies. 6 assertions confirmed RED pre-fix by temporarily neutering the scanner (`Expected: non-empty / Actual: []`) → GREEN after; `dart format` + analyze 0 / 1372 passed / 1 skipped (baseline 1353 +19); issues validate OK; git diff --check clean. No `lib/`, no dependency, no wire/transport/fixture change, no production TLS weakening; CI already runs it via `flutter test --coverage`. DMTF emulator skipped (no lib/wire/fixture/tool change, <7 days since last green 85/85). Only #009 (P3) / #021 (P2) remain open; both issues' progress logs updated. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next slices in `queues/*.md`: EP-T7 emulator prerequisite doctor, EP-S1 service launch edges, EP-U1 fullscreen scaffold.)**
- **Prior: 2026-11-19 22:49 UTC (run, agent:redfish-automation — FEATURE — EP-U5 launch-status parity for #009/#021: the per-console card (`KvmView._ConsoleCard`) now shows the same actionable "enable KVM on BMC" guidance as the viewer for a BMC-disabled console, both derived from the single `kvmLaunchStatusText` source of truth (visible text == merged `excludeSemantics` label, error-styled, gated only on the disabled strategy so the insecure-HTTP / external-client rows are untouched and "Open console" stays gated on `canOpenConsole`). +1 RED→GREEN widget test (no overflow at 320/800/1300 px), analyze 0 / 1350 passed / 1 skipped (baseline 1349 +1), DMTF emulator 85/85 (lib changed — §1.4 gate met), issues validate OK, no dependency/wire/TLS change. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next slices in `queues/*.md`: EP-P5 no-WebView import guard, EP-S1 service launch edges, EP-T7 emulator prerequisite doctor.)**
- **Prior: 2026-11-19 22:09 UTC (run, agent:redfish-automation — FEATURE — RM-3 non-map OEM console value fail-closed: the shared `FeatureRules.oemHasConsole` walk now requires a console-like key (`KVM` / `Console`) to map to a JSON object, so a malformed BMC publishing a scalar/list/null under such a key no longer fakes an OEM console on the discovery gate, the per-console card or the capability card; a valid map console elsewhere in `Oem` still wins. +11 RED→GREEN tests (shared walk + both models + three-surface cross-view agreement + 1 capability-card widget with 320/800/1300 px no-overflow), analyze 0 / 1346 passed / 1 skipped (baseline 1335 +11), DMTF emulator 85/85 (lib changed — §1.4 gate met), issues validate OK, no dependency/wire/TLS change. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next slices in `queues/*.md`: EP-U5 launch-status parity, EP-P5 no-WebView import guard, EP-S1 service launch edges, EP-T7 emulator prerequisite doctor.)**
- **Prior: 2026-11-19 21:26 UTC (run, agent:redfish-automation — FEATURE — RS-4 manager-member dedup in `KvmService`: duplicate/whitespace-padded/string-form `@odata.id` Members links now collapse to one console/capability card per physical manager via a normalized-member-URI set (first occurrence wins); blank/non-string links were already rejected, the RS-2 404/retryable/auth skip semantics and wire shape are unchanged, and distinct managers are never collapsed; +2 RED→GREEN in-temp-fixture service tests (no committed fixture), analyze 0 / 1335 passed / 1 skipped, DMTF emulator 85/85, issues validate OK, no dependency/wire/TLS change. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next slices in `queues/*.md`: RM-3 non-map console payload tolerance, EP-U5 launch-status parity, EP-P5 no-WebView import guard, EP-S1 service launch edges.)**
- **Prior: 2026-11-19 20:48 UTC (run, agent:redfish-automation — FEATURE — OEM `ConnectUri` alias gap for #009/#021: the shared `kvm_oem_uri.dart` generic fallback now recognizes the canonical Redfish `ConnectUri` member (preferring `Uri`), so a BMC publishing its console endpoint under an unregistered vendor's `Oem.<Vendor>.KVM.ConnectUri` no longer resolves to "no URI" on either KVM view. Previously only registered vendor parsers read `ConnectUri`; the generic path (used by `KvmConsole.fromManager` + `KvmCapability.resolveLaunchUri`) recognized only `Uri`, so the per-console card hid its URI row / routed to `noUri` and the capability card showed no resolved URI despite a real endpoint. Both views now surface the same launchable endpoint and read enablement from the same block. +10 RED→GREEN pure/parity tests (5 confirmed RED pre-fix) + 1 per-console-card widget test (Connect URI row + Open console + 320 px no-overflow); 2 outdated registry tests that documented the old "no URI without a parser" gap updated to the corrected behavior. analyze 0 / 1330 passed / 1 skipped (baseline 1319 +11); DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK. No dependency, no wire/transport change, no production TLS weakening. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next unblocked dept slices in `queues/*.md`: EP-M1 remaining URI-scheme edges, RM-2 non-map payload tolerance, EP-S1 service launch edges, EP-U1 fullscreen scaffold, EP-T3 coverage gate — genuine tested increments only, never verification-only churn.)**

- **Gate: 2026-11-19 23:11 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `fc3c648` into `main` via `--no-ff` (merge `b87a33a`) after `rf-platform-check` run#8965 returned an explicit `CHECK: PASS` for that exact tip (exit 0, ~55 s duration; analyze 0, targeted `launch_plan_test.dart` 73/73 on the branch incl. 3 new `%20` authority tests, no production-TLS weakening, allowlisted paths only — `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch has exactly one unique commit past merge-base `57e10fd` (already in main via `314a10e`), adding authority-scoped fail-closed rejection of a percent-encoded ASCII space (`%20`) in the console-launch URI authority: a decode-first launcher sees a FORBIDDEN space code point in the host and resolves/rejects a different authority than `Uri.tryParse` reports (which keeps `%20` encoded and reports a "secure" host), a parser-differential host-spoofing vector that under a stale flag + test opt-in could grant in-app rendering and self-signed acceptance on a spoofed host. Scoped to the authority, so `%20` in path/query (its correct encoding) and valid pct-encoded UTF-8 host bytes stay launchable. The new `_authorityHasEncodedSpace` helper + `_encodedAsciiSpace` regex fold into the single shared `String?`-returning `_controlSafeTrimmedUri` gate (as `return null`, matching the other checks) so every HTTP(S) classifier AND the launch-plan target refuse such an authority identically; no valid target lost, no dependency, no production TLS weakened. One merge conflict in `launch_plan.dart` (the branch's old `bool`-returning `return false` checks predated main's refactor to the shared `String?` gate): resolved by keeping main's `_authorityHasEncodedDot` check + shared-gate structure and folding the `%20` check in as `return null`; `launch_plan_test.dart` auto-merged cleanly with all 3 new tests preserved. Post-merge verify in-tree at merge commit `b87a33a` (tree clean apart from pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1353 passed / 1 skipped (baseline 1350 +3 merged tests); three coverage gates PASS overall 90.0% (5683/6315) / scoped 90.4% (2119/2345) / kvm 96.6% (960/994); `issues.py validate` OK; `git diff --check` clean; targeted post-merge 89/89. DMTF emulator skipped (no wire/transport, fixture or tool change — `launch_plan.dart` is the dependency-free, channel-free decision layer). No issue closed.**
- **Gate: 2026-11-19 22:09 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `57e10fd` into `main` via `--no-ff` (merge `314a10e`) after `rf-platform-check` run#8869 returned an explicit `CHECK: PASS` for that exact tip (started 22:00:31 UTC ~1 min after the builder produced `57e10fd` at 21:59:19 UTC, ~64 s duration; analyze 0, targeted `launch_plan_test.dart` 70/70 incl. 3 new malformed-UTF-8 authority tests, no production-TLS weakening, allowlisted paths only, no dependency changes). Branch adds authority-scoped fail-closed rejection of a percent-encoded octet sequence that is not well-formed UTF-8 (lone 0x80/0x9F C1 byte, overlong NUL `%C0%80`, truncated `%E2%82`): `utf8.decode(allowMalformed: true)` turns bad bytes into U+FFFD (So, not C/Z) so the existing encoded-control/compatibility-delimiter rules miss them, while `Uri.tryParse` keeps them encoded and reports a "secure" host — a decode-order differential that under a stale flag + test opt-in could reach in-app rendering and self-signed acceptance on a malformed/spoofed host. New `_authorityHasMalformedUtf8` helper folds into the single shared `_controlSafeTrimmedUri` gate (returning `null`, like the other checks), authority-scoped (malformed UTF-8 in path/query + valid pct-encoded UTF-8 e-acute/euro/emoji stay launchable); no valid target lost, no dependency, no production TLS weakened. Two merge conflicts (main had refactored the old `bool _uriHasSecureHttpsTarget` into the shared `String?`-returning `_controlSafeTrimmedUri` gate) resolved by keeping that shared gate + main's `_hasDegenerateAuthorityHost`/`_isHttpUriWithSchemes` structure and folding the new helper/check in as `return null`; `launch_plan_test.dart` auto-merged cleanly with all 3 new tests preserved. Post-merge verify in a clean isolated worktree at merge commit `314a10e` (a concurrent `redfish-automation` run#8864 held unrelated unstaged WIP in the shared tree — left untouched, hash-verified unchanged across the merge): `flutter analyze` 0; full `flutter test --coverage` **1338 passed / 1 skipped** (baseline 1335 +3 merged tests); three coverage gates PASS overall 90.0% (5669/6301) / scoped 90.4% (2118/2344) / kvm 96.5% (947/981); `issues.py validate` OK; `git diff --check` clean; staged diff secret scan clean. DMTF emulator skipped (no wire/transport, fixture or tool change — `launch_plan.dart` is the dependency-free, channel-free decision layer). No issue closed.**
- **Gate: 2026-11-19 21:02 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` tip `77d8818` into `main` via `--no-ff` (merge `862756e`) after `rf-platform-check` run#8779 returned an explicit `CHECK: PASS` for that exact tip (analyze 0, targeted `launch_plan_test.dart` 67/67 incl. 3 new `%2E` host-spoofing tests, no production-TLS weakening, allowlisted paths only, no dependency changes). Branch adds fail-closed rejection of a percent-encoded ASCII domain-label dot (`%2E`) in the console-launch URI authority — `Uri.tryParse` decodes it to a literal '.' (`bmc.example%2Eevil.com` → host `bmc.example.evil.com`) while a non-decoding launcher resolves a different authority, a decode-order host-spoofing vector under a stale flag + test opt-in; folded into the single shared fail-closed gate, authority-scoped (`%2E` in path/query + valid pct-encoded UTF-8 host bytes stay launchable), no valid target lost. Two merge conflicts (main had refactored the authority checks into the shared `String?`-returning `_controlSafeTrimmedUri`) resolved by keeping that shared gate and folding the `%2E` check in as `return null`; one stale test assertion (`ipmi://%2E%2E/` expected control-safe) reconciled to the stricter merged behavior while preserving the test's security intent. Post-merge verify: analyze 0; full suite **1333 passed / 1 skipped** (baseline 1330 +3 merged tests); three coverage gates PASS overall 89.9% / scoped 90.4% / kvm 96.5%; issues validate OK; targeted 83/83 + platform 95/95. DMTF emulator skipped (no wire/transport, fixture or tool change — `launch_plan.dart` is the dependency-free, channel-free decision layer). No issue closed.**

- **Prior: 2026-11-19 20:07 UTC (run, agent:redfish-automation — FEATURE — EP-U4 closeout for #009/#021: the KVM viewer now follows the shared session state instead of a stale local flag, so an evicted console can no longer advertise an active session or end a newer console's session).** `KvmConsoleViewerPage` previously set a local `_sessionActive = true` once in its post-frame connect callback, but the app-wide `kvmSessionProvider` can evict that console when a newer single-session console connects — leaving a stale "session active" disclosure and an enabled Disconnect button whose tap (or a back-pop) ended the *other* manager's session. The viewer now watches `kvmSessionProvider` in `build`, derives active state from `session.isConnected && activeManagerId == console.managerId.trim()`, and re-checks that ownership inside both the Disconnect callback and `PopScope.onPopInvokedWithResult` before ending a session. Visible text == merged a11y label on both active/idle disclosures. +3 RED→GREEN widget tests (all confirmed RED pre-fix), 320 px no-overflow; analyze 0 / 1316 passed / 1 skipped (baseline 1313 +3); DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK. No dependency, no wire/transport change, no production TLS weakening. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next unblocked dept slices in `queues/*.md`: EP-M1 remaining URI-scheme edges, RM-2 non-map payload tolerance, EP-S1 service launch edges, EP-U1 fullscreen scaffold, EP-T3 coverage gate — genuine tested increments only, never verification-only churn.

- **Prior: 2026-11-19 20:18 UTC (rf-gate — sole merger to main).** Merged `build/rf-platform` tip `770b3a5` into `main` with `--no-ff` after `rf-platform-check` run#8720 returned an explicit `CHECK: PASS` for that exact tip (analyze 0, 64/64 targeted tests, no TLS weakening, allowlisted paths only). The branch adds fail-closed rejection of a percent-encoded percent (`%25`) in the console-launch URI authority — a double-decoding host-spoofing vector (`%252F`→`%2F`→`/`) — scoped so `%25` in path/query and valid pct-encoded UTF-8 host bytes stay launchable; no production TLS change. Two merge conflicts (main had meanwhile refactored the authority checks into the shared `_controlSafeTrimmedUri` returning `String?`) were resolved by folding the new `%25` check into that single shared gate as `return null`, preserving both main's classifier refactor and the branch's hardening; LAUNCH_FALLBACK.md counts updated to the measured 80 targeted / 92 platform. Post-merge verification: analyze 0; full suite 1319 passed / 1 skipped; coverage gates PASS overall 89.9% / scoped 90.4% / kvm 96.5%; issues validate OK; targeted 80/80 + platform 92/92 green. DMTF emulator suite skipped (no wire/transport, fixture or tool change — `launch_plan.dart` is the dependency-free, channel-free decision layer). No issue closed.

- **Prior: 2026-11-19 19:27 UTC (run, agent:redfish-automation — FEATURE — EP-M1/M2 cross-surface classifier-parity slice for #009/#021: degenerate label-less external-client hosts fail closed).** `isExternalClientConsoleUri` (single source of truth for `KvmConsole` / `KvmCapability`) previously accepted `vnc://./`, `ssh://../`, `ipmi://%2E%2E/` as trustworthy external-client endpoints while the HTTP(S) classifier family already failed closed on the same dot-only authority. Factored the dot-only-host rule into one shared `_hasDegenerateAuthorityHost(Uri)` helper used by both families; opaque authority-less URIs and `@odata.id` clipboard fallbacks unaffected. Such endpoints now degrade to `noUri` / `canOpenConsole == false` / no external-client notice on every surface. +3 RED→GREEN tests (pure classifier + model + capability parity). analyze 0 / 1313 passed / 1 skipped (baseline 1310 +3); DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK. No dependency, no wire/transport change, no production TLS weakening. **Current focus: next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next unblocked dept slices in `queues/*.md`: EP-M1 remaining URI-scheme edges, RM-2 non-map payload tolerance, EP-S1 service launch edges, EP-U1 fullscreen scaffold — genuine tested increments only, never verification-only churn.

- **Prior: 2026-11-19 18:41 UTC (run, agent:redfish-automation — FEATURE — EP-T6 closeout of the FUTUREWORK "[!] Live BMC integration" blocker for #009/#021: `tool/unattended_guard.dart` + CI gate + tests).** Added a pure-Dart unattended-safety guard that fails closed on: (1) an ungated `test_integration/**.dart` lacking both the `String.fromEnvironment('REDFISH_EMULATOR_URL')` gate and `markTestSkipped`; (2) a plain `test/**.dart` referencing the emulator env var (`test/tool/` guard self-tests exempt); (3) production `lib/**.dart` hard-enabling `allowSelfSigned: true`. +15 RED→GREEN tests (`test/tool/unattended_guard_test.dart`), CLI RED proof (ungated temp-dir file → violation + exit 1), real-repo scan green (286 Dart sources). Wired into `.github/workflows/verify.yml`; live-BMC human opt-in documented in `DEVELOPMENT.md`. No `lib/` change, no dependency, no wire/transport change, no production TLS weakening. analyze 0 / 1304 passed / 1 skipped (baseline 1289 +15); DMTF emulator 85/85 (tool changed — §1.4 gate met); issues validate OK. **Current focus: next smallest open issue is #009 (P3); #021 (P2) is higher priority.** Next unblocked dept slices in `queues/*.md`: EP-M1, RM-2 (non-map payloads), EP-S1, EP-U1, EP-T1/EP-T3, EP-P4 — genuine tested increments only, never verification-only churn.

- **Prior: 2026-11-19 18:01 UTC (run, agent:redfish-automation — FEATURE — RM-2-adjacent dept slice for #009/#021: shared tolerant `MaxConcurrentSessions` parsing).** Both KVM views carried two near-identical private parsers that silently dropped an integer-valued JSON number emitted as a double (`4.0`) from BOTH the per-console card and the per-manager capability card. Extracted a single pure `kvmSessionLimit(Object?)` helper in new `lib/features/kvm/models/kvm_session_limit.dart` (exported from the barrel) and pointed both views at it — tolerates integral/finite/exactly-representable doubles (and numeric-string forms) while rejecting fractional, non-finite, >2^53 doubles, negatives, blank/non-numeric strings and wrong types. 4 new behavioral assertions confirmed RED pre-fix (`Expected: 4 / Actual: <null>`) → GREEN; +11 tests total. analyze 0 / 1289 passed / 1 skipped (baseline 1278 +11); DMTF emulator 85/85 (`lib/` changed — §1.4 gate met); issues validate OK; git diff --check clean. No dependency, no wire/transport change, no production TLS weakening. **Next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next unblocked dept slices in `queues/*.md`: EP-M1, RM-2 (non-map payloads), EP-S1, EP-U1, EP-T4/EP-T6 — genuine tested increments only, never verification-only churn.

- **Prior: 2026-11-19 17:19 UTC (run, agent:redfish-automation — FEATURE — LA-1 closeout of the FUTUREWORK "[!] Large spec/binary assets" blocker from the #009/#021 epic tooling split).** Added `tool/asset_guard.dart` (pure-Dart large/binary asset policy evaluator + CLI) + `tool/asset_manifest.json` (path/size/SHA-256/source URL for the mirrored DSP0266 PDF + schema index, hashes verified) + `test/tool/asset_guard_test.dart` (+15 RED→GREEN tests, temp-dir RED proof), wired into `.github/workflows/verify.yml` and documented the "ask a human before committing large assets" gate in `DEVELOPMENT.md`. Any binary >1 MiB that is unlisted/size-drifted/hash-drifted fails closed; malformed manifest fails closed; text files not flagged. analyze 0 / 1278 passed / 1 skipped (baseline 1263 +15); DMTF emulator 85/85 (tool changed — §1.4 gate met); issues validate OK. No `lib/` change, no dependency, no production TLS weakening. **Next smallest open issue remains #009 (P3); #021 (P2) is higher priority.** Next unblocked dept slices in `queues/*.md`: EP-M1, RM-2, EP-S1, EP-U1, EP-T4/EP-T6 — genuine tested increments only, never verification-only churn; never add a WebView/url_launcher dependency unattended.

- **Gate: 2026-11-19 19:18 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` HEAD `fefb8f9` into `main` via `--no-ff` (this merge commit) after `rf-platform-check` run#8635 PASS (exit 0, started 19:08:08 UTC ~10 min earlier, ~65 s duration; verdict line `CHECK: PASS`; analyze 0, targeted `launch_plan_test.dart` 61/61 on the branch, no production-TLS weakening, path allowlist `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Branch HEAD `fefb8f9` verified unchanged since the check; 2 unmerged commits vs merge-base `ceb9008` (already in main via merge `3752113`): `dffa04b` + `fefb8f9`, adding (1) degenerate dot-only / no-label host fail-closed re-validation (`https://./`, `https://../`, `https://%2E%2E/` → host `..`) and (2) IDNA middle-dot confusables (U+00B7 MIDDLE DOT `%C2%B7`, U+0387 GREEK ANO TELEIA `%CE%87`) to the authority-scoped fail-closed set in the platform launch plan, +6 RED→GREEN tests. Both are parser-differential host-spoofing vectors that `Uri.tryParse` reports as a "secure" non-empty HTTPS host, which under a stale flag + test opt-in could reach in-app rendering and self-signed acceptance on a bogus/spoofed host; both now fail closed, authority-scoped only (encoded forms in path/query, punycode ASCII hosts, real-label/trailing-dot FQDN and IPv6 hosts stay launchable), no valid target lost, no dependency added, no production TLS weakened. The merge conflicted in `launch_plan.dart` + `LAUNCH_FALLBACK.md` because main had refactored the branch's old `bool _uriHasSecureHttpsTarget` into the shared `String?`-returning `_controlSafeTrimmedUri` gate with `_isHttpUriWithSchemes(String?, Set<String>)` + public `isSecureHttpsConsoleUri` / `isPlaintextHttpConsoleUri` / `isHttpConsoleUri`. Conflict resolution preserved BOTH main's generalized-scheme classifier refactor AND the branch's degenerate-dot-host hardening — kept `schemes.contains(parsed.scheme.toLowerCase())` and added `if (parsed.host.replaceAll('.', '').isEmpty) return false;` after the null/scheme/host guards in `_isHttpUriWithSchemes`, so every HTTP(S) classifier AND the launch-plan target refuse a label-less dot host identically (stricter than the model, never more permissive). `launch_plan_test.dart` auto-merged cleanly with all six new tests preserved; `LAUNCH_FALLBACK.md` kept both new rationale paragraphs (middle-dot + degenerate dot-host) and the expanded coverage group, doc counts updated to 76 targeted / 88 platform. Post-merge verify in-tree at the merge commit (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1310 passed / 1 skipped (one transient parallel-load flake in `power_view_test.dart` failed on the first run then passed isolated 4/4 and on the full-suite re-run); all three coverage gates PASS overall 89.9% / scoped 90.4% / kvm 96.4%; `issues.py validate` OK; `git diff --check` clean; staged diff secret scan clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**

- **Gate: 2026-11-19 16:58 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `ceb9008` into `main` via `--no-ff` (merge `b208ed7`, this merge commit) after `rf-platform-check` run#8444 PASS (exit 0, started 16:53:11 UTC, ~2 min after builder produced branch HEAD `ceb9008` at 16:51 UTC; verdict `CHECK: PASS`; analyze 0, targeted `launch_plan_test.dart` 55/55 on the branch incl. 3 new IDNA dot-confusable cases, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The branch was based on merge-base `603768f` (already in main via merge `c98e855`) with exactly 1 unmerged commit adding the classic CJK/halfwidth IDNA dot confusables to the authority-scoped fail-closed `_compatibilityDelimiterCodePoints` set in the platform launch plan — U+3002 IDEOGRAPHIC FULL STOP / U+FF61 HALFWIDTH IDEOGRAPHIC FULL STOP (IDNA -> '.') and U+2E3C TWO DOT LEADER (NFKC -> '..'), +3 RED→GREEN tests. These are neither Unicode Separator/Other nor NFKC-mapped to a literal ASCII delimiter, so the encoded C/Z rule misses them; a decode+IDNA launcher resolves `bmc.example%E3%80%82evil.com` as `bmc.example.evil.com` (parser-differential host spoofing) while `Uri.tryParse` reports a "secure" host — under a stale flag + test opt-in that could reach in-app rendering and self-signed acceptance on a spoofed/mismatched host. All now fail closed; authority-scoped only (encoded forms in path/query and punycode ASCII hosts stay launchable), no valid target lost, no dependency added, no production TLS weakened. The merge conflicted only in `LAUNCH_FALLBACK.md` (both sides edited the test-count prose + rationale); kept main's up-to-date counts (67 targeted / 79 platform) and "folded into the shared gate" text, folded in the branch's IDNA dot-confusable paragraph and "+ IDNA dot-confusable rejection" coverage-group label; `launch_plan.dart` and `launch_plan_test.dart` auto-merged cleanly with all branch additions preserved. Post-merge verify in-tree at merge commit `b208ed7` (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1263 passed / 1 skipped (baseline 1260 +3 merged tests); all three coverage gates PASS overall 89.9% / scoped 90.4% / kvm 96.4%; `issues.py validate` OK; `git diff --check` clean; staged diff secret scan clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Gate: 2026-11-19 16:43 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `603768f` into `main` via `--no-ff` (this merge commit) after `rf-platform-check` run#8426 PASS (exit 0, started 16:31:31 UTC, ~7 min after builder run#8408 produced branch HEAD `603768f` at 16:24 UTC; analyze 0, targeted `launch_plan_test.dart` green, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The branch was based on merge-base `7f9b9a4` (already in main via merge `d88e683`) with exactly 1 unmerged commit extending the authority-scoped percent-decoded NFKC compatibility-confusable delimiter fail-closed set (`_compatibilityDelimiterCodePoints`) from the fullwidth/fraction forms to the full IDNA/NFKC confusable family — small forms (U+FE52/`.`, U+FE55/`:`, U+FE68/`\`, U+FE6B/`@` ...), vertical presentation forms (U+FE13/`:`, U+FE47/U+FE48/`[`/`]` ...), dot leaders/ellipses (U+2024/U+2025/U+2026), numeric full-stop forms (U+2488..U+249B, U+1F100) and squared/fractional forms whose NFKC expansion embeds a delimiter (U+2100 `a/c`, U+33C2 `a.m.`), +3 RED→GREEN tests). Strictly tightens the fail-closed gate: only decoded authority code points that normalise to a structural delimiter fail closed; non-delimiter non-ASCII (e-acute, euro, emoji), ASCII escapes and confusables in path/query stay launchable; no valid target lost, no dependency added, no production TLS weakened. The merge conflicted in `LAUNCH_FALLBACK.md` (both sides updated the test-count prose; kept main's up-to-date structure and reconciled the extended-confusable rationale + new coverage group, counts 67 targeted / 79 platform) and `launch_plan_test.dart` (both added a test group at EOF; kept BOTH groups); `launch_plan.dart` auto-merged cleanly. Post-merge verify in a clean isolated worktree at the merge commit (a concurrent `redfish-automation` run#8416 had held unrelated WIP in the shared tree but committed `0298499` before this merge): `flutter analyze` 0; targeted platform suite 79/79; full `flutter test --coverage` 1260 passed / 1 skipped (+3 merged tests); all three coverage gates PASS overall 89.9% / scoped 90.4% / kvm 96.4%; `issues.py validate` OK; `git diff --check` clean; staged diff secret scan clean. DMTF emulator skipped — merged `lib/` change only extends the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Gate: 2026-11-19 15:06 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `7f9b9a4` into `main` via `--no-ff` after `rf-platform-check` run#8331 PASS (exit 0, started 15:00:10 UTC ~3 min after builder run#8312 produced branch HEAD `7f9b9a4` at 14:57 UTC; final line `CHECK: PASS`; check reported 49/49 targeted on the branch and its prose stale-named `6eaecd5`, but its +46/+47/+48 encoded-confusable-delimiter tests matched the current branch content). The branch was based on merge-base `6eaecd5` (already in main via merge `1341f63`) with exactly 1 unmerged commit adding authority-scoped percent-decoded NFKC compatibility-confusable delimiter fail-closed rejection in the platform launch plan (`_compatibilityDelimiterCodePoints` + `_authorityHasCompatibilityDelimiter`, `dart:convert` utf8 decode, +3 RED→GREEN tests). It conflicted in `launch_plan.dart` + `LAUNCH_FALLBACK.md` because main had refactored the branch's `bool _uriHasSecureHttpsTarget` into the shared `String?`-returning `_controlSafeTrimmedUri` gate with sibling public HTTP(S) classifiers. Conflict resolution preserved BOTH main's shared public-classifier refactor AND the branch's encoded-confusable-delimiter hardening — folded the new set/helper into main's file and added `if (_authorityHasCompatibilityDelimiter(trimmed)) return null;` as the final check in `_controlSafeTrimmedUri` (returning `null`, matching the other gates) so every HTTP(S) classifier AND the launch-plan target refuse an encoded compatibility confusable identically; encoded non-delimiter non-ASCII (e-acute, euro, emoji) and ASCII escapes stay launchable. All test groups and both doc intents retained; `LAUNCH_FALLBACK.md` doc count updated to 61 targeted / 73 platform with the new rejection rationale. Post-merge verify in-tree at the merge commit (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1240 passed / 1 skipped (+3 merged tests); coverage gates PASS overall 89.8% / scoped 90.4% / kvm 96.2%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Gate: 2026-11-19 13:55 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `6eaecd5` into `main` via `--no-ff` (this merge commit) after `rf-platform-check` run#8248 PASS (exit 0, started 13:47:44 UTC ~1 min after builder run#8240 produced branch HEAD `6eaecd5` at 13:46:36 UTC; verdict line `CHECK: PASS`; analyze 0, targeted `launch_plan_test.dart` 46/46 on the branch, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The branch was based on `cab0449` (already in main via `811214b`) with exactly 1 unmerged commit adding percent-encoded multi-byte UTF-8 → Unicode Separator/Other (C/Z) reject-revalidation in the platform launch plan (`_hasEncodedUnicodeControlOrSeparator` + `_hexDigit` helpers, `dart:convert` utf8 decode, +3 RED→GREEN tests). The merge conflicted in `launch_plan.dart` + `LAUNCH_FALLBACK.md` because main had since refactored the branch's `bool _uriHasSecureHttpsTarget` into the shared `String?`-returning `_controlSafeTrimmedUri` gate with sibling public HTTP(S) classifiers. Conflict resolution preserved BOTH main's shared public-classifier refactor AND the branch's encoded-Unicode-C/Z hardening — folded `_hexDigit`, `_hasEncodedUnicodeControlOrSeparator`, the `_unicodeOtherOrSeparator` RegExp and the `import 'dart:convert'` into main's file, and added `if (_hasEncodedUnicodeControlOrSeparator(trimmed)) return null;` as the final check in `_controlSafeTrimmedUri` (returning `null`, matching the other gates) so every HTTP(S) classifier AND the launch-plan target refuse an encoded Unicode separator/invisible identically; encoded non-C/Z escapes (`%C3%A9`, emoji) and ASCII escapes (`%20`) stay launchable. All test groups and both doc intents retained; `LAUNCH_FALLBACK.md` doc counts updated to 58 targeted / 70 platform with the new rejection rationale. Post-merge verify in-tree at the merge commit (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1226 passed / 1 skipped (baseline 1223 +3 merged tests; one transient parallel-load flake in `power_view_test.dart` failed once then passed on isolated 3/3 + two full-suite re-runs); coverage gates PASS overall 89.8% / scoped 90.4% / kvm 95.9%; `issues.py validate` OK; `git diff --check` clean; staged diff secret scan clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Prior Gate: 2026-11-19 12:50 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `cab0449` into `main` via `--no-ff` (merge `811214b`) after `rf-platform-check` run#8144 PASS (exit 0; check started 12:42:49 UTC, ~2 s after builder run#8138 produced branch HEAD `cab0449` and ~74 s after its 12:41:35 UTC author time; analyze 0, targeted platform suite 67/67 incl. 3 new percent-encoded C0/DEL control-octet cases, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The branch was based on `8afa0b4` (already in main via `a1a2367`) and main had since advanced with the FEATURE #009/#021 vendor-parser normalization (`c1db981`) + the rf-ideate queue split (`481c72d`); the merge conflicted in `launch_plan.dart` because main had refactored the branch's `bool _uriHasSecureHttpsTarget` into the shared `String?`-returning `_controlSafeTrimmedUri` gate. Conflict resolution preserved BOTH main's shared public-classifier refactor AND the branch's encoded-control-octet hardening — folded its `_encodedControlOctet` regex (pct-encoded C0 0x00-0x1F / DEL 0x7F, hex case-insensitive, anywhere in the URI) into `_controlSafeTrimmedUri` (returns `null`, matching the other checks) so every HTTP(S) classifier AND the launch-plan target refuse a pct-encoded control octet identically; non-control escapes (`%20`/`%2F`/UTF-8) stay launchable. All test groups and both doc intents retained; `LAUNCH_FALLBACK.md` doc counts updated to 55 targeted / 67 platform with the new rejection rationale. Post-merge verify in a clean isolated worktree at merge commit `811214b` (a concurrent `redfish-automation` FEATURE run held unrelated WIP in the shared main tree): `flutter analyze` 0; full `flutter test --coverage` 1212 passed / 1 skipped (+3 merged tests); coverage gates PASS overall 89.7% / scoped 90.4% / kvm 95.7%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Gate: 2026-11-19 12:03 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `8afa0b4` into `main` via `--no-ff` (merge `a1a2367`) after `rf-platform-check` run#8075 PASS (exit 0; check started 11:57:31 UTC, ~95 s after builder produced branch HEAD `8afa0b4` at 11:55:56 UTC; analyze 0, targeted `launch_plan_test.dart` 52/52 incl. 5 new percent-encoded authority-delimiter cases, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The branch was based on `0966397` (already in main via `ee6faab`) and main had since advanced with the FEATURE #009/#021 OEM-console-enablement + fail-closed-launch work (`f0e73b9`); the merge conflicted in `launch_plan.dart` + `LAUNCH_FALLBACK.md` + `launch_plan_test.dart`. Conflict resolution preserved BOTH main's shared public-classifier refactor (single `_controlSafeTrimmedUri` gate + `_isHttpUriWithSchemes` + public `isSecureHttpsConsoleUri` / `isPlaintextHttpConsoleUri` / `isHttpConsoleUri` + the launcher/copy-target control-safety test group) AND the branch's percent-encoded authority-delimiter hardening — folded its `_encodedAuthorityDelimiter` regex + `_authorityHasEncodedDelimiter` helper (raw authority between `://` and first `/`/`?`/`#`, hex case-insensitive) into the shared `_controlSafeTrimmedUri` gate (returns `null`, matching the other checks) so every HTTP(S) classifier AND the launch-plan target refuse an encoded structural delimiter identically; encoded delimiters in path/query and valid pct-encoded non-delimiter host bytes stay launchable. All test groups and both doc intents retained, doc test counts updated to 52/64. Post-merge verify in-tree at merge commit `a1a2367` (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1207 passed / 1 skipped (+5 merged tests); coverage gates PASS overall 89.7% / scoped 90.4% / kvm 95.7%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Gate: 2026-11-19 11:55 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `0966397` into `main` via `--no-ff` (merge `ee6faab`) after `rf-platform-check` run#7956 PASS (exit 0; check started 11:50:47 UTC; analyze 0, targeted `launch_plan_test.dart` 35/35 incl. 3 new raw non-ASCII authority / IDN-homograph cases, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The branch was based on the stale `97ba24c` (39 commits behind main) and conflicted in `launch_plan.dart` + `LAUNCH_FALLBACK.md`: main had refactored the target into the shared `_controlSafeTrimmedUri` gate, so the branch's old `_uriHasSecureHttpsTarget` no longer existed. Conflict resolution preserved BOTH main's shared public-classifier refactor AND the branch's raw non-ASCII authority hardening — folded the new `_nonAscii` regex + `_authorityHasNonAscii` helper (raw authority between `://` and first `/`/`?`/`#`, so ASCII punycode hosts and non-ASCII path/query stay launchable) into the shared `_controlSafeTrimmedUri` so every HTTP(S) classifier AND the launch-plan target refuse a raw non-ASCII authority identically (returns `null`, matching the other gates); all test groups and both doc intents retained, doc test counts updated to 47/59. Post-merge verify in-tree at merge commit `ee6faab` (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1191 passed / 1 skipped (+3 merged tests); coverage gates PASS overall 89.7% / scoped 90.4% / kvm 95.6%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Gate: 2026-11-19 09:52 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `97ba24c` into `main` via `--no-ff` (merge `2a727a1`) after `rf-platform-check` run#7839 PASS (exit 0; check started 09:46:46 UTC, ~120 s after builder produced branch HEAD `97ba24c` at 09:44:38 UTC; analyze 0, targeted `launch_plan_test.dart` 32/32 incl. 3 new malformed-percent-encoding cases, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The merge required conflict resolution preserving BOTH main's shared public-classifier refactor (the single `_controlSafeTrimmedUri` control-safety gate + `_isHttpUriWithSchemes` + public `isSecureHttpsConsoleUri` / `isPlaintextHttpConsoleUri` / `isHttpConsoleUri` classifiers, plus the launcher/copy-target control-safety test group) AND the branch's malformed-percent-encoding fail-closed hardening (a new `_malformedPercentEncoding` regex rejecting any `%` not followed by exactly two hex digits — `Uri.tryParse` otherwise silently encodes `...%` / `...%ZZ` into the host); because main had removed the branch's old `_uriHasSecureHttpsTarget`, the new gate was folded into the shared `_controlSafeTrimmedUri` so every HTTP(S) classifier AND the launch-plan target refuse malformed escapes identically, and all test groups (malformed-percent-encoding + RFC-3986 unwise-char + launcher/copy-target control-safety) and both doc intents were retained. Post-merge verify in-tree at merge commit `2a727a1` (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1183 passed / 1 skipped (+3 merged tests); coverage gates PASS overall 89.6% / scoped 90.4% / kvm 94.9%; `issues.py validate` OK; `git diff --check` clean. Pushed `main` 805830b..2a727a1. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision gate (no wire/transport/fixture/tool change).**
- **Prior Gate: 2026-11-19 08:42 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `c939597` into `main` via `--no-ff` (merge `5c99995`) after `rf-platform-check` run#7695 PASS (exit 0; check started 08:40:41 UTC, ~85 s after builder produced branch HEAD `c939597` at 08:39:19 UTC; analyze 0, targeted `launch_plan_test.dart` 41/41 incl. 4 new RFC-3986 unwise-char cases, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The merge required conflict resolution preserving BOTH main's shared public-classifier refactor (`String?`-returning `_controlSafeTrimmedUri` / `_isHttpUriWithSchemes` + the 3-test launcher/copy-target control-safety group) AND the branch's RFC-3986 unwise-char superset in `_rawUriForbiddenChars` (raw double-quote/angle-brackets/caret/braces/pipe plus backtick now rejected alongside backslash/C0/Unicode-separators; `Uri.tryParse` otherwise percent-encodes them into a spoofed host); both test groups (RFC-3986 unwise-char + launcher/copy-target control-safety) and both doc intents were retained. Post-merge verify in-tree at merge commit `5c99995` (clean except pre-existing untracked `testing/`): `flutter analyze` 0; full `flutter test --coverage` 1174 passed / 1 skipped; coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; `issues.py validate` OK; `git diff --check` clean. Pushed `main` 268fd30..5c99995. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan fail-closed decision regex (no wire/transport/fixture/tool change).**
- **Prior Gate: 2026-11-19 07:55 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `005c985` into `main` via `--no-ff` (merge `7043579`) after `rf-platform-check` run#7664 PASS (exit 0; check started 07:51:38 UTC, ~75 s after builder produced branch HEAD `005c985` at 07:50:23 UTC; analyze 0, targeted `launch_plan_test.dart` 25/25 incl. 3 new raw-backslash cases, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The merge required conflict resolution preserving BOTH main's shared public-classifier refactor (`isSecureHttpsConsoleUri` / `isPlaintextHttpConsoleUri` / `isHttpConsoleUri` + `String?`-returning `_controlSafeTrimmedUri` / `_isHttpUriWithSchemes`) AND the branch's raw-backslash fail-closed hardening in `_rawUriForbiddenChars` (rejecting a raw `\` that `Uri.tryParse` folds to `/`, closing a parser-differential host-confusion/spoofing gap); both test groups (raw-backslash + Unicode-whitespace/invisible + HTTP-family classifier agreement) and both doc intents were retained. Post-merge verify (run in a clean isolated worktree at merge commit `7043579` because a concurrent `redfish-automation` FEATURE run held unrelated WIP in `lib/features/kvm/models/**` + `test/**`; that WIP's transient `String?`/`Uri.tryParse` compile error + 2 failing tests were NOT present at the merge commit): `flutter analyze` 0; full `flutter test --coverage` 1161 passed / 1 skipped; coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; `issues.py validate` OK; `git diff --check` clean. Pushed `main` 7e7bb5a..7043579. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan regex gate (fail-closed decision helper, no wire/transport/fixture/tool change).**
- **Prior Gate: 2026-11-19 06:50 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `d42db09` into `main` via `--no-ff` (merge `f59a052`) after `rf-platform-check` run#7612 PASS (exit 0; check started 06:46 UTC, immediately after builder produced branch HEAD `d42db09` at 06:44 UTC; analyze 0, targeted 22/22, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The merge required conflict resolution preserving BOTH main's shared public-classifier refactor (`isSecureHttpsConsoleUri` / `isPlaintextHttpConsoleUri` / `isHttpConsoleUri` + `_controlSafeTrimmedUri` / `_isHttpUriWithSchemes`, the single source of truth for the `KvmConsole`/`KvmCapability` transport classifiers) AND the branch's Unicode-category fail-closed hardening (`RegExp(r'[\p{C}\p{Z}]', unicode: true)` rejecting NBSP / zero-width / separator / invisible code points that `Uri.tryParse` would otherwise percent-encode into host/path); the unified file uses the shared-classifier structure with the Unicode RegExp as its single control-safe gate, so all three HTTP(S) classifiers apply identical hardening. Both test groups (HTTP-family classifier agreement + Unicode whitespace/invisible rejection) and both doc intents were retained. Post-merge verify: `flutter analyze` 0; full `flutter test --coverage` 1153 passed / 1 skipped (+2 merged Unicode tests); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change only tightens the dependency-free platform launch-plan classifier (fail-closed decision helper, no wire/transport/fixture/tool change).**
- **Prior Gate: 2026-11-19 05:44 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `7e727bf` into `main` via `--no-ff` (merge `24f2d27`) after `rf-platform-check` run#7574 PASS (exit 0; check started 05:40:52 UTC, immediately after builder produced branch HEAD `7e727bf` at 05:38:59 UTC; analyze 0, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). The merge required conflict resolution preserving BOTH main's `ceb96f2` rename of `_uriHasSecureHttpsTarget` → shared public `isSecureHttpsConsoleUri` (single source of truth used by the `KvmConsole`/`KvmCapability` classifiers) AND the branch's raw-space fail-closed hardening (`codeUnit <= 0x20`, rejecting raw ASCII space alongside C0/DEL); both test groups (control-character + raw-space) and both doc intents retained. Post-merge verify: `flutter analyze` 0; full `flutter test --coverage` 1138 passed / 1 skipped (+2 merged raw-space tests); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change tightens the dependency-free platform launch-plan classifier to reject raw spaces, a fail-closed decision helper with no wire/transport/fixture/tool change.**
- **Prior Gate: 2026-11-19 04:40 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `c5618a0` into `main` via `--no-ff` (merge `9045c43`) after `rf-platform-check` run#7529 PASS (check started 04:36:34 UTC, immediately after builder produced branch HEAD `c5618a0` at 04:35:23 UTC; analyze 0, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Post-merge verify (run in a clean isolated worktree at the merge commit because a concurrent `redfish-automation` build job held unrelated unstaged WIP in `lib/features/kvm/views/**` + `test/features/kvm/kvm_widget_test.dart`): `flutter analyze` 0; full `flutter test --coverage` 1126 passed / 1 skipped (+3 merged control-character re-validation tests); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change adds a C0/DEL control-character rejection to the dependency-free platform launch-plan re-validator (`_uriHasSecureHttpsTarget`), a fail-closed decision helper with no wire/transport/fixture/tool change.**
- **Prior Gate: 2026-11-19 03:53 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commits `83e9819`+`e1c6c4b` (HEAD `e1c6c4b`) into `main` via `--no-ff` (merge `19cea3d`) after `rf-platform-check` run#7498 PASS (check ran after builder #7495 that produced HEAD `e1c6c4b`; analyze 0, targeted tests green, no production-TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Post-merge verify: `flutter analyze` 0; `flutter test` 1114 passed / 1 skipped (+3 merged host/malformed-authority re-validation tests; one transient parallel-load flake in `power_view_test.dart` passed on isolated + full-suite re-run); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.4%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change tightens the platform launch-plan re-validator to `Uri.tryParse` + non-empty host (fails closed on host-less/malformed-authority URIs), a dependency-free defense-in-depth decision helper with no wire/transport/fixture/tool change.**
- **Prior Gate: 2026-11-19 02:42 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `036dd98` into `main` via `--no-ff` (merge `56aef27`) after `rf-platform-check` run#7454 PASS (HEAD `036dd98`, analyze 0, targeted tests green, no TLS weakening, path-contained under `lib/features/kvm/platform/**` + `test/**`, no dependency changes). Post-merge verify: `flutter analyze` 0; `flutter test --coverage` 1102 passed / 1 skipped (+3 merged scheme re-validation tests; concurrent FEATURE commit `48d53bd` was already present in tree); coverage gates PASS overall 89.4% / scoped 90.4% / kvm 94.2%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` change is a dependency-free, defense-in-depth URI-scheme re-validation in the platform launch-plan helper (no wire/transport/fixture/tool change).**
- **Prior Gate: 2026-11-19 01:38 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `3665c1d` into `main` via `--no-ff` (merge `d8d3ccc`) after `rf-platform-check` run#7409 PASS (HEAD `3665c1d`, clean tree, analyze 0, targeted 20/20, no TLS weakening, path-contained, no dependency changes). Post-merge verify: `flutter analyze` 0; `flutter test --coverage` 1096 passed / 1 skipped (+9 merged launch-plan tests); coverage gates PASS overall 89.3% / scoped 90.4% / kvm 93.2%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` file is a design-only, dependency-free flag-gated launch-plan decision module (no wire/transport/fixture/tool change).**
- **Prior Gate: 2026-11-19 00:35 UTC (rf-gate, sole merger) — MERGED `build/rf-platform` commit `2fbe889` into `main` via `--no-ff` (merge `38dc688`) after `rf-platform-check` run#7370 PASS (HEAD `2fbe889`, clean tree, analyze 0, targeted 11/11, no TLS weakening, path-contained, no dependency changes). Post-merge verify: `flutter analyze` 0; `flutter test` 1082 passed / 1 skipped (+11 merged policy tests); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.9%; `issues.py validate` OK; `git diff --check` clean. DMTF emulator skipped — merged `lib/` file is a design-only, dependency-free WebView/TLS policy module (no wire/transport/fixture/tool change).**
- **Last updated: 2026-11-19 16:31 (run, agent:redfish-automation — FEATURE #009/#021 — EP-U3 cross-surface external-client launch-guidance parity: added pure `kvmExternalClientNoticeFor(protocol)` in `kvm_transport_notice.dart` (single source of truth; blank/unknown → generic fallback) and wired both the per-console card (`kvm_view.dart`) and capability card (`kvm_capability_card.dart`) external-client rows to it, so all three surfaces (viewer + both cards) name the specific client from the shared `externalClientProtocolLabel` with visible text == merged a11y label; +9 RED→GREEN widget tests (VNC/RFB + SSH + IPMI at 320/800/1300 px), analyze 0 / 1257 passed / 1 skipped, emulator 85/85, issues validate OK. Only #009 (P3) / #021 (P2) remain open; next slices in `queues/*.md.)** Prior (2026-11-19 15:35 run, agent:redfish-automation — FEATURE #009/#021 — EP-M2/EP-U3 cross-surface external-client classifier parity: extracted shared pure `isExternalClientConsoleUri` / `externalClientConsoleProtocol` helpers in `launch_plan.dart` (built on the fail-closed `_controlSafeTrimmedUri` transport gate); `KvmConsole` now delegates to them (ad-hoc parse removed) and `KvmCapability` gains mirroring `requiresExternalConsoleClient` / `externalClientProtocolLabel` getters, so both KVM views classify and label the same endpoint identically. The capability card now renders a shared `kvmExternalClientNotice` for a resolved VNC/RFB/KVMIP/serial endpoint (merged a11y, visible text == announced label), matching the plaintext-HTTP warning pattern. +8 tests (1 widget RED→GREEN confirmed pre-fix), analyze 0 / 1248 passed / 1 skipped, emulator 85/85 (lib changed), issues validate OK. Only #009 (P3) / #021 (P2) remain open; next slices in `queues/*.md`.)** Prior (2026-11-19 14:56 run, agent:redfish-automation — FEATURE #009/#021 — RM-1 URI-less disabled OEM console enablement (dept slice from `queues/model.md`): `kvmOemConsoleEnabled` now falls back to the console-like block when no URI-bearing OEM console exists, so a `ServiceEnabled: false` / legacy `Enabled: false` OEM block with a blank/absent `Uri` is honored on the console card, capability card and discovery gate — closing a URI-less corner of the #009 "KVM disabled on BMC" contract; launchable consoles still read URI + enablement from the same block, all existing behavior unchanged. +6 tests (5 RED→GREEN confirmed pre-fix), analyze 0 / 1237 passed / 1 skipped, emulator 85/85 (lib changed), issues validate OK. Only #009 (P3) / #021 (P2) remain open; next slices in `queues/*.md`.)** Prior (2026-11-19 14:11 run, agent:redfish-automation — FEATURE #009/#021 — EP-U4 viewer session lifecycle (dept slice from `queues/ui.md`): the pure-UI `KvmSessionController` was never wired into the console viewer despite "go fullscreen"/"back = disconnect" being open #009 acceptance criteria. `KvmConsoleViewerPage` is now a `ConsumerStatefulWidget` — entering starts a session for the manager (passing `maxConcurrentSessions` so a single-session BMC logs eviction), a merged-a11y session-active/idle disclosure + explicit "Disconnect console" button end it on demand, and `PopScope.onPopInvokedWithResult` ends it on back/pop. Provider writes kept out of widget lifecycle methods (post-frame connect + pop/button callbacks only); no WebView/protocol dependency, no wire call, no TLS change. +5 RED→GREEN viewer widget tests (all confirmed RED pre-fix), analyze 0 / 1231 passed / 1 skipped, emulator 85/85 (lib changed — §1.4 gate met), issues validate OK. Only #009 (P3) / #021 (P2) remain open; next slices in `queues/*.md`.)** Prior (13:28 run, agent:redfish-automation — FEATURE #009/#021 — discovery-gate OEM-enablement parity: the KVM-tab discovery gate (`FeatureRules._managerConsoleType`) now honors an explicitly disabled OEM console via the shared `kvmOemConsoleEnabled` helper, fixing a cross-view regression from the 12:05 OEM-enablement fix where the capability/console cards said disabled but the tab still opened; +7 RED→GREEN tests (3 confirmed RED pre-fix incl. a FeatureRules↔KvmCapability↔KvmConsole agreement test), analyze 0 / 1223 passed / 1 skipped, emulator 85/85, coverage kvm 95.8%, issues validate OK. Only #009 (P3) / #021 (P2) remain open; next slices in `queues/*.md`.)** Prior (12:48 run, agent:redfish-automation — FEATURE #009/#021 — RS-2 manager-walk robustness: `_fetchManagerBodies` now skips a per-member transient/retryable failure (429, 5xx except 501, timeout / connection error) in addition to the existing stale 404, so one flapping manager no longer blanks the gated KVM screen while healthy managers' consoles/capabilities still render; auth 401/403, TLS certificate and all other non-retryable failures still propagate (never masked). +4 RED→GREEN service tests (2 confirmed RED pre-fix with an injected 503) + opt-in test-only fault injection in the mock server helper; baseline analyze 0 / 1209 passed / 1 skipped → verify analyze 0 / 1216 passed / 1 skipped (a concurrent rf-platform merge `811214b` added +3 tests mid-run, included in the verified total), DMTF emulator 85/85 (lib changed — §1.4 gate met), coverage kvm 95.8%, issues validate OK. Only #009 (P3) / #021 (P2) remain open; next slices in `queues/*.md`.)** Prior (12:09 run) — FEATURE #009/#021 — vendor-parser cross-view normalization: `KvmConsole.fromManager`'s registered-vendor-parser branch now routes `connectUri` / `connectTypesSupported` through the shared `_uriString` + `_normalizedConnectTypes` helpers, so a padded URI or duplicate/blank/garbled types can no longer disagree between the OEM console card and the capability card / launch plan for the same manager (+2 RED→GREEN tests with messy + blank-URI fixtures, 1 confirmed RED pre-fix; baseline analyze 0 / 1207 passed / 1 skipped → verify analyze 0 / 1209 passed / 1 skipped, emulator 85/85 after rebase onto the concurrent rf-gate merge `c68dba3`, coverage kvm 95.7%). Only #009 (P3) / #021 (P2) remain open; next slices in `queues/*.md`.)** Prior (12:05 run) — FEATURE #009 (smallest open ID) / #021 — genuine OEM-console enablement fix. The generic OEM path in `KvmConsole.fromManager` hard-coded `serviceEnabled: true` and `KvmCapability.fromManager` treated any console-like `Oem` key as supported+enabled, so a BMC publishing `ServiceEnabled: false` / `Enabled: false` on `Oem.OpenBMC.KVM` was still offered as a launchable "Open console" with a Supported/Enabled capability card — the last console source that ignored enablement. Added shared pure `kvmOemConsoleBlock` / `kvmOemConsoleEnabled` in `kvm_oem_uri.dart` (reads the exact block the URI comes from; omitted flag stays enabled so existing mockups are unchanged) and wired both models; a disabled OEM console now fails closed to `disabled`/`copyOnly` and its capability card shows the "KVM disabled on BMC" helper. +11 RED→GREEN tests (6 confirmed RED pre-fix); baseline analyze 0 / 1191 passed / 1 skipped → verify analyze 0 / 1202 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK; git diff --check clean. No dependency, no wire/transport change, no production TLS weakening. Only #009 (P3, smallest) / #021 (P2) remain open; next concrete slices in `queues/*.md`.)** Prior (10:43 run) — FEATURE #009/#021 — cross-surface clipboard-safety fix. The 08:38 fail-closed target change hardened the viewer's copy target via `launchPlan.targetUri`, but the per-console card's "Copy connect info" still copied the raw `launchUri`, so a CRLF/NUL/raw-space/backslash/malformed-% `ConnectUri` that the launch plan refused as a clipboard target was still placed on the clipboard by the card — a header/clipboard-injection risk and a cross-surface disagreement. Added the pure `KvmConsole.clipboardTargetUri` (`launchPlan.targetUri ?? sourceManagerUri`) single source of truth and switched the card's copy action to it; the raw endpoint stays visible (fail closed, not hidden) and valid/percent-encoded targets copy byte-for-byte as before. +3 RED→GREEN tests (1 behavioral widget test tapping "Copy connect info" with a platform-channel clipboard mock — confirmed RED pre-fix `Expected: '/redfish/v1/Managers/BMC' / Actual: 'https://bmc.example/kvm\r\nX-Injected: 1'`; 2 pure model tests); baseline analyze 0 / 1185 passed / 1 skipped → verify analyze 0 / 1188 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK; git diff --check clean. No dependency, no wire/transport change, no production TLS weakening. Only #009 (P3, smallest) / #021 (P2) remain open; remaining work tracked as unblocked dept slices in `queues/*.md`.)**
- **Prior (2026-11-19 10:02 UTC) (run, agent:redfish-automation — FEATURE #009 (smallest open ID) / #021 — RU-2 dept slice: dependency-free, TLS-safe cross-surface a11y notice consistency. The "Console persists until manager timeout — close tab to disconnect" session notice existed only on the gated list view (a screen-reader user drilling into a console lost it); the "KVM disabled on BMC..." helper was a duplicated literal. Both are now single shared constants in `kvm_transport_notice.dart`, and the session notice is rendered on the deepest `KvmConsoleViewerPage` as one merged `excludeSemantics` node (visible text == announced label), so list view / capability card / viewer announce identical wording. +2 viewer widget tests (behavioral RED pre-fix proven by a temporary probe substitution + 320 px no-overflow); baseline analyze 0 / 1183 passed / 1 skipped → verify analyze 0 / 1185 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK; git diff --check clean. No dependency, no wire/transport change, no production TLS weakening. Only #009/#021 remain open; remaining work tracked as unblocked dept slices in `queues/*.md`.)** Prior (2026-11-19 09:16 UTC) — FEATURE #021 (P2) / #009 — EP-S2 service slice from the rf-ideate dept re-split. With EP-P1 RESOLVED (external-browser + copy is the final render route, no embedded WebView), `KvmService.pickPrimary` — which badges the "Primary" / recommended launch target — still picked the first openable graphical console, so a plaintext-HTTP or external-client-only (VNC/SSH) console could be badged "Primary" over an available control-safe HTTPS console. It now prefers a secure-HTTPS graphical console, then any secure-HTTPS console, before the existing openable/graphical/fallback tiers, so the recommended external-open target is always safe to open in a browser; all fallback behaviour preserved. No dependency, no wire/transport change, no production TLS weakening. +6 RED→GREEN tests (2 service confirmed RED pre-fix `Actual: manager=plaintext` / `Actual: manager=external` + 3 service guards + 1 widget "Primary" badge guard); baseline analyze 0 / 1174 passed / 1 skipped → verify analyze 0 / 1180 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK. Only #009/#021 remain open; all remaining work is tracked as unblocked dept slices in `queues/*.md` (EP-M2/RM-1 model, EP-P3 platform, EP-S2 done/EP-S1 service, EP-U3/EP-U1 UI, EP-T4 tooling).**
- **Prior (2026-11-19 08:38 UTC) (run, agent:redfish-automation — FEATURE #009 (smallest open ID) / #021 — genuine, dependency-free, TLS-safe fail-closed copy/launcher-target fix. `planConsoleLaunch` now derives its returned `targetUri` from the shared `_controlSafeTrimmedUri` control-safety gate instead of a plain `uri.trim()`, so a control-char / raw-space / Unicode-separator / backslash / spoofed-authority URI on the copy-only route is no longer handed to the launcher/clipboard (viewer falls back to the manager source), closing a header/clipboard-injection and authority-confusion gap; valid and percent-encoded (`%20`/`%5C`) targets unchanged. Also removed a stray duplicated doc line on `KvmCapability.hasHttpLaunchUri`. +4 RED→GREEN tests (3 pure + 1 viewer widget, confirmed RED pre-fix); baseline analyze 0 / 1166 passed / 1 skipped → verify analyze 0 / 1170 passed / 1 skipped; DMTF emulator 85/85 (lib changed — gate met); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; issues validate OK. Prior (07:56 run) classifier-parity fix. The HTTPS / plaintext-HTTP / HTTP-family transport classifiers all share the `_controlSafeTrimmedUri` raw-space/C0/DEL/Unicode-separator hardening, but the non-HTTP external-client classifiers (`KvmConsole.requiresExternalConsoleClient` / `externalClientProtocolLabel`: VNC/RFB/KVMIP/serial) still used bare `Uri.tryParse`, which silently percent-encodes those characters into a spoofed host while reporting a valid scheme — so a CRLF/NUL/NBSP-bearing `vnc://`/`rfb://` URI was announced as a trustworthy "requires an external VNC/RFB client" endpoint (with a copy affordance) while an equivalent malformed HTTPS/HTTP URI was correctly refused. Added the scheme-agnostic shared `isControlSafeConsoleUri` gate in `launch_plan.dart` (same core) and applied it before parsing in `requiresExternalConsoleClient`, so such a target fails closed to `noUri` on every surface, agreeing with the fail-closed launch plan and both HTTP(S) families. No URL opened, no WebView/protocol dependency, no production TLS weakening. +6 RED→GREEN tests (2 model + 1 viewer widget confirmed RED pre-fix; 2 pure classifier + guards); baseline analyze 0 / 1158 passed / 1 skipped → verify analyze 0 / 1166 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; issues validate OK.)**
- **Prior (2026-11-19 07:19 UTC) (run, agent:redfish-automation — FEATURE #009 (smallest open ID) / #021 — genuine, dependency-free, TLS-safe launch-guidance consistency fix. For an enabled plaintext-HTTP HTML5 console the per-console card showed TWO contradictory messages: the unconditional "HTML5 console — open via BMC web UI." hint AND the unencrypted-transport warning. Added the pure `KvmConsole.showHtml5WebUiHint` getter (`supportsHtml5 && !usesInsecureHttpLaunchUri`) as the single source of truth and gated the card's HTML5 info row on it, so the unsafe endpoint gets only the honest "configure HTTPS first" warning; URI-less and secure HTTPS HTML5 consoles keep the hint. +5 RED→GREEN tests (1 widget confirmed RED pre-fix + 4 pure model); baseline analyze 0 / 1153 passed / 1 skipped → verify analyze 0 / 1158 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; issues validate OK.)**
- **Prior (2026-11-19 06:41 UTC) (run, agent:redfish-automation — FEATURE #009 (smallest open ID) / #021 — genuine, dependency-free, TLS-safe launch-classification fix. `KvmConsole.launchStrategy` collapsed an enabled plaintext-HTTP non-HTML5 console (e.g. KVMIP over `http://`) into `noUri` despite carrying a real copyable URI, so the viewer said "Use the URI externally if provided" with no unencrypted warning and the card withheld "Open console", while both cards already flag `usesInsecureHttpLaunchUri`. Added dedicated `KvmLaunchStrategy.insecureHttp` + cleartext status text + viewer error styling; still never an in-app/browser render target, so no unencrypted browser console is suggested and TLS is never weakened. +4 RED→GREEN tests (3 confirmed RED pre-fix). Baseline analyze 0 / 1147 passed / 1 skipped → verify analyze 0 / 1151 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; issues validate OK.)**
- **Prior (2026-11-19 05:23 UTC) (run, agent:redfish-automation — FEATURE #009 (smallest open ID) / #021 — genuine, dependency-free, TLS-safe cross-view secure-URI classification fix. The fail-closed `launch_plan.dart` already rejected C0/DEL control-character-bearing URIs (CRLF/NUL/TAB/DEL — `Uri.tryParse` silently percent-encodes them), but `KvmConsole.hasSecureLaunchUri` / `KvmCapability.hasSecureLaunchUri` used bare `Uri.tryParse` + https + host, so a CRLF/NUL-bearing HTTPS `ConnectUri` was classified "secure" → `canOpenConsole == true` ("Open console" offered) while `launchPlan` failed closed to `copyOnly`. Extracted one shared public pure classifier `isSecureHttpsConsoleUri` and pointed both model getters at it, so the UI can never disagree with the fail-closed plan; strictly tightens classification, no valid HTTPS endpoint lost. +5 RED→GREEN tests (2 model confirmed RED pre-fix + 2 capability + 1 widget). Baseline analyze 0 / 1131 passed / 1 skipped → verify analyze 0 / 1136 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.5% / scoped 90.4% / kvm 94.8%; issues validate OK.)**
- **Prior (2026-11-19 04:44 UTC): (run, agent:redfish-automation — FEATURE #009/#021 (still OPEN) dependency-free, TLS-safe cross-view transport-safety fix: the per-console card was the only KVM surface with no plaintext-HTTP warning, so it now shows the error-styled, merged-a11y unencrypted-HTTP notice using one shared constant (`kvm_transport_notice.dart`) also reused by the capability card. +5 RED→GREEN widget tests (1 confirmed RED pre-fix). Baseline analyze 0 / HEAD re-measure 1126 passed / 1 skipped → verify analyze 0 / 1131 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.6% / scoped 90.4% / kvm 94.9%; issues validate OK.)**
- **Prior (2026-11-19 02:41 UTC): FEATURE #009/#021 (still OPEN) dependency-free, TLS-safe cross-view launch-affordance fix: the console card's "Open console" action was gated only on `launchUri != null`, but a BMC may publish a `ConnectUri` while reporting `ServiceEnabled: false` — for such a console the model's `canOpenConsole` is already false (`launchStrategy == disabled`) and the viewer refuses to launch it, so the card offered a dead-end "Open console" action. `_ConsoleCard` now gates the launch button on `console.canOpenConsole` (single source of truth shared with `KvmService.pickPrimary`); the URI stays visible/copyable and the `canOpenConsole` doc now states both consumers gate on it. +1 widget RED→GREEN test (RED pre-fix: found 1 "Open console" on a disabled console with a URI). Baseline analyze 0 / 1098 passed / 1 skipped → verify analyze 0 / 1099 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.4% / scoped 90.4% / kvm 94.2%; issues validate OK.)**
- **Prior: 2026-11-19 02:03 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe manager-id normalization in the KVM manager walk. `KvmService._managerId`'s `@odata.id` fallback used the raw untrimmed Redfish string (its docstring claimed otherwise), so a manager with a missing/blank `Id` plus a padded `@odata.id` was keyed as `'PADDED  '` and a whitespace-only `@odata.id` as `'   '` — stray whitespace on the console/capability cards and `fetchCapability(realId)` misses. A new `_trimmedNonBlank` helper now normalizes the whole `@odata.id`, its derived last segment and the member-URI fallback segment, so all three identity sources share the trim+reject-blank contract. +2 service RED→GREEN tests + new `kvm_blank_odata_id_mockup` fixture (both RED pre-fix: `Actual: ['PADDED  ', '   ']` / `Actual: <null>`). Baseline analyze 0 / 1096 passed / 1 skipped → verify analyze 0 / 1098 passed / 1 skipped; DMTF emulator 85/85 (lib + fixture changed — §1.4 gate met); coverage gates PASS overall 89.4% / scoped 90.4% / kvm 94.2%; issues validate OK.)**
- **Prior: 2026-11-19 01:26 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe malformed-manager-metadata tolerance in the KVM manager walk. `KvmService._memberUri` was the last KVM URI parser returning the raw Redfish value: a whitespace-padded `Members[].@odata.id` was fetched verbatim, 404'd and — via the stale-member skip — silently dropped the manager and all its consoles/capabilities; a whitespace-only string member was fetched instead of ignored. It now trims both link-object + string member forms and treats blank as absent (mirroring `KvmConsole._uriString` / `KvmCapability._nonEmptyString`); the companion `_managerId` now trims + rejects a blank body `Id` so a padded Id no longer shows stray whitespace or breaks `fetchCapability(realId)`. +3 service RED→GREEN tests + new `kvm_padded_member_mockup` fixture (all 3 confirmed RED pre-fix). Baseline analyze 0 / 1084 passed / 1 skipped → verify analyze 0 / 1087 passed / 1 skipped; DMTF emulator 85/85 (lib + fixture changed — §1.4 gate met); coverage gates PASS overall 89.3% / scoped 90.4% / kvm 93.1%; issues validate OK.)**
- **Prior: 2026-11-19 00:47 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe malformed-payload crash fix — a malformed (non-list) `Members` collection in `/redfish/v1/Managers` no longer throws a `TypeError` that blanks the gated KVM screen; `KvmService._fetchManagerBodies` now type-checks `Members` (non-list → no managers discovered), closing the last bare cast in the KVM read path. +2 service RED→GREEN tests + a new `kvm_malformed_members_mockup` fixture. Baseline analyze 0 / 1082 passed / 1 skipped → verify analyze 0 / 1084 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.9%; issues validate OK.)**
- **Prior: 2026-11-19 00:10 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe correctness fixes — (1) case-insensitive `Oem` connect-type marker dedup on the capability card (a BMC advertising canonical `OEM` now gets one chip, matching the per-console card); (2) a stale 404 manager member no longer aborts the whole Managers walk and blanks the gated KVM screen (auth 401/403 still rethrown). 3 model + 1 widget + 2 service RED→GREEN tests (4 confirmed RED pre-fix) + 1 new stale-manager mockup fixture. Baseline analyze 0 / 1064 passed / 1 skipped → verify analyze 0 / 1071 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.8%; issues validate OK.)**
- **Prior: 2026-11-18 23:29 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe enabled-state consistency fix — `connectTypes` now skips explicitly disabled console blocks. `KvmCapability.fromManager` aggregated `ConnectTypesSupported` from graphical/serial/remote unconditionally, so a disabled graphical console's `KVMIP` chip sat beside the launchable remote console's `HTML5` chip — advertising an unopenable connection path — while the resolved URI / maxSessions already preferred enabled blocks. New `_aggregateConnectTypes` applies the same two-pass rule (prefer non-disabled, fallback preserved, `Oem` marker appended after) as `_standardConnectUri` / `_aggregateMaxSessions`; unknown-enablement fixtures unchanged. +7 RED→GREEN tests (6 model incl. console↔capability agreement + Oem-marker interaction + 2 green guards, 1 capability-card widget; 4 of 5 new assertions confirmed RED pre-fix). Baseline analyze 0 / 1057 passed / 1 skipped → verify analyze 0 / 1064 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.8%; issues validate OK.)**
- **Prior: 2026-11-18 22:53 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe resolved-URI enabled-state fix — the `@odata.id` fallback. `KvmCapability.resolveLaunchUri` returned `GraphicalConsole.@odata.id` regardless of enablement, so an explicitly disabled graphical console's Redfish API resource link was surfaced as the capability card's "Resolved URI" over a launchable OEM KVM URI (shown by the per-console card). It now prefers the OEM URI when the graphical block is explicitly disabled and an OEM URI exists; unknown-enablement blocks keep their link's priority and a sole disabled link is still surfaced when no OEM URI exists (all prior behaviour preserved). +6 RED→GREEN tests (5 model incl. a `fromManager` cross-view agreement vs the openable `KvmConsole`, 1 capability-card widget; 3 confirmed RED pre-fix). Baseline analyze 0 / 1051 passed / 1 skipped → verify analyze 0 / 1057 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.7%; issues validate OK.)**
- **Prior: 2026-11-18 22:16 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe aggregate `maxSessions` fix: `KvmCapability.fromManager` aggregated the capability card's "Max sessions" as `_maxSessions(graphical) ?? _maxSessions(serial) ?? _maxSessions(remote)` with no enablement check, so a disabled graphical console's limit (e.g. 1) won over an enabled RemoteConsole's launchable limit (e.g. 4) — the same enabled-state gap just fixed for the resolved URI. New `_aggregateMaxSessions(body)` mirrors `_standardConnectUri`: first pass prefers a not-explicitly-disabled block's limit (graphical→serial→remote), with a fallback to any block so an all-disabled fixture still shows its limit (prior behaviour preserved); a block with no enablement flag is "unknown" and keeps its limit. +6 RED→GREEN tests (5 model incl. a console↔capability agreement vs the openable console, 1 capability-card widget; 4 confirmed RED pre-fix, 2 fallback/unknown guards green pre-fix). Baseline analyze 0 / 1045 passed / 1 skipped → verify analyze 0 / 1051 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.7%; issues validate OK.)**
- **Prior: 2026-11-18 21:02 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe `pickPrimary` launchability fix: `KvmService.pickPrimary` — which sets `KvmUiState.primaryConsole` (badged "Primary" on the console card, recommended launch target) — returned the first graphical console regardless of enabled/launchable state, so a BMC exposing a disabled/URI-less graphical console first badged an unopenable console as "Primary". Added `KvmConsole.canOpenConsole` (derived from the single-source-of-truth `launchStrategy`; openable = usable URI + enabled, `insecureHtml5` still counts since its URI is copyable — no TLS weakening) and made `pickPrimary` select in tiers: first openable graphical → first openable any-type → first graphical → first overall (last two preserve a sensible badge when nothing is openable). +13 RED→GREEN tests (6 service — 3 confirmed RED pre-fix; 6 model `canOpenConsole`; 1 KvmView widget: "Primary" badge sits on the card with "Open console"). Baseline analyze 0 / 1026 passed / 1 skipped → verify analyze 0 / 1039 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.6%; issues validate OK.)**
- **Prior: 2026-11-18 20:24 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe malformed-`@odata.id` crash fix across all three KVM manager read paths: a non-string/blank `@odata.id` (e.g. numeric `42` or a nested map) hit bare `as String?` casts in `KvmConsole.fromManager`, `KvmCapability.fromManager` and `KvmService.fetchCapabilities`, throwing a `TypeError` that aborted discovery and blanked the gated KVM screen. All three now normalize via existing safe helpers (`_uriString` / `_nonEmptyString` / `ODataResource.id`), falling back to `/redfish/v1/Managers/{managerId}`; padded values trimmed, blank/non-string treated as absent, both views agree. +10 RED→GREEN tests (9 confirmed RED pre-fix: `TypeError` + blank/padded URI) in model/capability/service + 1 new malformed-@odata.id mockup fixture + 1 widget test (capability card still renders usable source notice). Baseline analyze 0 / 1016 passed / 1 skipped → verify analyze 0 / 1026 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.5%; issues validate OK.)**
- **Prior: 2026-11-18 19:40 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe `RemoteConsole` discovery-gate fix — the last read path out of sync: `KvmConsole.fromManager` parses `RemoteConsole` and `KvmCapability.fromManager` reports it `supported`, but the discovery-level `FeatureRules._managerConsoleType` (→ `SystemFeatures.kvm`/`kvmType`, which gates the KVM tab in `system_shell.dart`) checked only `GraphicalConsole`/`SerialConsole`/`Oem`, so a RemoteConsole-only manager got no KVM tab while both KVM views showed a live console. `_managerConsoleType` now recognizes an enabled `RemoteConsole` between serial and OEM (matching `KvmConsole.fromManager`'s block order) via the shared `_consoleEnabled` rule; `kvm`/`kvmType`/rule doc comments updated. +6 RED→GREEN tests (4 `feature_rules_test.dart`: ServiceEnabled + legacy-Enabled detection, disabled guard, graphical/serial/remote/oem ranking; 1 cross-view agreement `kvm_capability_test.dart`: RemoteConsole-only manager is capability-supported + has consoles + `FeatureRules.kvm == true`/`kvmType == 'RemoteConsole'`; 1 end-to-end widget `ui_widget_test.dart`: `FeatureRules.build` over a RemoteConsole-only manager opens the "KVM" tab — 5 confirmed RED pre-fix). Baseline analyze 0 / 1010 passed / 1 skipped → verify analyze 0 / 1016 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.4% / kvm 92.5%; issues validate OK.)**
- **Prior: 2026-11-18 19:01 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe `RemoteConsole` detection fix: `KvmConsole.fromManager` parses the standard `RemoteConsole` block and `resolveLaunchUri` reads its `ConnectUri`, but `KvmCapability.fromManager` ignored it for detection — a manager exposing only a `RemoteConsole` rendered an enabled, launchable per-console card next to a "KVM not supported / disabled" capability card. fromManager now aggregates `RemoteConsole` into `connectTypes`, `serviceEnabled`, `maxSessions` and `supported` (an enabled remote console is supported by definition), so both KVM views agree. +6 RED→GREEN tests (5 model — enabled RemoteConsole supported/enabled/typed/limited, console↔capability agreement, maxSessions fallback, case-insensitive type dedup, disabled guard; 1 widget — RemoteConsole-only card shows supported/enabled + HTML5 chip, no "KVM disabled on BMC" helper; 5 confirmed RED pre-fix). KVM suite 186; baseline analyze 0 / 1004 passed / 1 skipped → verify analyze 0 / 1010 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.3% / kvm 92.5%; issues validate OK.)**
- **Prior: 2026-11-18 18:24 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe malformed-`ConnectTypesSupported` tolerance fix: both KVM models stringified non-string Redfish `ConnectTypesSupported` entries (`null` / numeric / boolean) into literal "null"/"42" connection-type chips — the per-console card (`KvmConsole._normalizedConnectTypes`) and the per-manager capability card (`KvmCapability._appendTypes`) now ignore non-string entries, and `_advertises` only matches real string values, so detection and display agree across both views. +5 RED→GREEN tests (2 model + 2 capability + 1 widget; all confirmed RED pre-fix): null/numeric/boolean entries ignored, null-only list yields no chips, console↔capability agreement on malformed data, capability card renders no bogus chips + merged a11y label. KVM suite 180; baseline analyze 0 / 999 passed / 1 skipped → verify analyze 0 / 1004 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.3% / kvm 92.5%; issues validate OK.)**
- **Prior: 2026-11-18 17:47 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe cross-view OEM console URI fix: an OEM-only console (`Oem.KVM.Uri` / `Oem.Vendor.WebConsole.Uri`) was resolved to a real endpoint by the per-manager capability card, but `KvmConsole.fromManager` built the matching OEM console with `connectUri == null`, so the console card showed "No console connect URI available" with no "Open console" action while the capability card showed the actual OEM KVM URI. Extracted the bounded, case-insensitive OEM `Uri` search into a shared pure helper `lib/features/kvm/models/kvm_oem_uri.dart` (`kvmOemConsoleUri`) used by both `KvmCapability.resolveLaunchUri` and the generic OEM console branch of `KvmConsole.fromManager` (vendor-parser path stays authoritative/unchanged); blank/non-string ignored, padded trimmed as before. +4 RED→GREEN model tests (3 confirmed RED pre-fix) +1 widget test (OEM card shows resolved URI + Open console). KVM suite 175; baseline analyze 0 / 994 passed / 1 skipped → verify analyze 0 / 999 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.2% / scoped 90.3% / kvm 92.5%; issues validate OK.)**
- **Prior: 2026-11-18 (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, TLS-safe blank-`ConnectUri` tolerance fix across #009's two KVM models + the console card: a BMC emitting a whitespace-only `ConnectUri` (`'   '`, `'\t\n'`) was stored by both models as a real endpoint — `KvmConsole._fromBlock` used a generic `_asString`, `KvmCapability._nonEmptyString` only checked `isNotEmpty` — so the console card rendered "Connect URI:   ", the capability card rendered an empty "Resolved URI:" row (`hasUri == true`), a blank value shadowed a valid `@odata.id`/OEM URI fallback, and `kvm_view.dart`'s clipboard target / launch button used the blank string instead of the manager URI. Both parsers now reject blank strings (`KvmConsole._uriString`, `KvmCapability._nonEmptyString`), the normalized accessors (`KvmConsole.launchUri`, `KvmCapability.hasUri`) hide a blank URI for any construction path, and the console card uses `launchUri` for its URI row / launch button / clipboard target. +13 RED→GREEN tests (6 model + 6 capability + 1 capability-card widget; 10 new assertions confirmed RED pre-fix): blank/empty/tab-newline/non-string → null, valid preserved, @odata.id + OEM fallbacks, console ↔ capability agreement, blank resolved URI shows source notice. KVM suite 160; baseline analyze 0 / 971 passed / 1 skipped → verify analyze 0 / 984 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.1% / scoped 90.3% / kvm 92.3%; issues validate OK.)**
- **Prior: 2026-11-18 15:49 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free, spec-anchored session-limit tolerance fix across #009's two KVM models: the mirrored DMTF `Manager.v1_19_0.json` defines `MaxConcurrentSessions` with `minimum: 0`, but both `KvmConsole._fromBlock` (`_asInt`) and `KvmCapability._maxSessions` accepted negative values verbatim — a BMC emitting `-1` (common "unlimited" sentinel) or `-5` rendered "Max concurrent sessions: -1" / "Max sessions: -1" on the console and capability cards, and a negative graphical value blocked the capability model's fallback to a valid serial limit. Both parsers now treat negative int/string values as unreported (`null`), keeping both views consistent with the mirrored spec; +8 RED→GREEN pure-Dart tests (4 in `kvm_model_test.dart`, 4 in `kvm_capability_test.dart`: negative int/string → null, negative graphical → serial fallback, spec-valid 0/positive preserved, console ↔ capability agreement). KVM suite 147; baseline analyze 0 / 963 passed / 1 skipped → verify analyze 0 / 971 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.1% / scoped 90.3% / kvm 92.3%; issues validate OK.)**
- **Prior: 2026-11-18 15:12 UTC (run, agent:redfish-automation — FEATURE #009 (P3, still OPEN) dependency-free cross-view connect-type consistency fix: replaced `KvmConsole._fromBlock`'s raw `_asStringList` with `_normalizedConnectTypes` (trim + drop-empty + case-insensitive dedup, first-seen casing), so the per-console card no longer renders duplicate/garbled ` kvmip `/`HTML5` chips while the per-manager capability card shows clean ones — both KVM views now read the same manager's `ConnectTypesSupported` identically. +3 RED→GREEN pure-Dart tests in `test/features/kvm/kvm_model_test.dart` (+26 → +29: mixed-case/whitespace collapse, empty-entry removal, console-card ↔ capability-card agreement); KVM suite 139; baseline analyze 0 / 960 passed / 1 skipped → verify analyze 0 / 963 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.1% / scoped 90.3% / kvm 92.2%; issues validate OK.)**
- **Prior (2026-11-18 14:34 UTC): FEATURE #009 (P3, still OPEN) dependency-free detection-field consistency fix: aligned the capability model's two derived fields with their documented contracts. `supportsKvmIp` now reads an authoritative graphical-only `KVMIP` bit (`graphicalKvmIp`) computed by `KvmCapability.fromManager` from the same source `supported` uses, so a manager advertising KVMIP only on a serial/OEM block no longer reports `supportsKvmIp == true` while `supported == false` (falls back to aggregate scan for directly constructed widget-test fixtures); `connectTypes` dedup is now case-insensitive (first graphical-first spelling kept), so mixed-case BMC payloads no longer render duplicate connection-type chips. +3 RED→GREEN pure-Dart tests in `test/features/kvm/kvm_capability_test.dart` (+26 → +29); KVM suite 136; baseline analyze 0 / 957 passed / 1 skipped → verify analyze 0 / 960 passed / 1 skipped; DMTF emulator 85/85 (lib changed — §1.4 gate met); coverage gates PASS overall 89.1% / scoped 90.3% / kvm 92.1%; issues validate OK.)**
- **Prior (2026-11-18 13:56 UTC): FEATURE #009 (P3, still OPEN) non-dependency, TLS-safe cross-view detection-consistency fix: closed a real contradiction between the per-manager capability card and the per-console card/viewer. `KvmConsole._fromBlock` read enablement via `block['ServiceEnabled'] as bool? ?? false`, which ignored the legacy `Enabled` member honored by both `FeatureRules._consoleEnabled` and `KvmCapability._blockEnabled` AND threw a `TypeError` on a non-bool `ServiceEnabled`. The checked-in OpenBMC fixture uses `"Enabled": true`, so discovery + capability card reported KVM enabled while the console card showed "Disabled" and the #021 viewer falsely said "disabled on BMC"; a non-bool value aborted all of `fetchConsoles()`. Now uses `block['ServiceEnabled'] == true || block['Enabled'] == true` — identical to the other two parsers — so enablement is consistent across all three read paths and non-bool values degrade to disabled. +2 RED→GREEN pure-Dart model tests (legacy `Enabled` → enabled + `inAppHtml5`; non-bool → no throw + disabled). baseline analyze 0 / 955 passed / 1 skipped → verify analyze 0 / 957 passed / 1 skipped; KVM suite 133; DMTF emulator 85/85 (lib changed — §1.4 gate met); issues validate OK.)**
- **Prior (2026-11-18 13:17 UTC): FEATURE #009 (P3, still OPEN) non-dependency, TLS-safe genuine correctness fix on the URI-resolution item: closed a real consistency gap between the two KVM views. `KvmConsole._fromBlock` reads the launchable standard-console `ConnectUri`, but `KvmCapability.resolveLaunchUri` (per-manager capability card) ignored it and only looked at `GraphicalConsole.@odata.id` (a Redfish API link, not a browser URL) and OEM `Uri` — a manager exposing a real `ConnectUri` showed "No console URI resolved" on the card while the console card showed the endpoint. `resolveLaunchUri` now prefers the first standard console `ConnectUri` (graphical→serial→remote), then `@odata.id`, then the bounded OEM `Uri` search; read-only, no IPC, no transport change. +7 pure-Dart RED→GREEN tests (`test/features/kvm/kvm_capability_test.dart`, +19 → +26) +2 end-to-end service tests (`kvm_service_test.dart`) over a new focused fixture (`test/fixtures/redfish/kvm_connecturi_mockup`) proving `fetchCapability()` surfaces the endpoint and agrees with `fetchConsoles()`. Issue stays OPEN (embedded HTML5 rendering, fullscreen, input forwarding, Launch-Console strategy + WebView dependency remain — externally blocked on platform WebView + BMC TLS validation). No WebView/protocol dependency; no production TLS weakened. baseline analyze 0 / 946 passed / 1 skipped → verify analyze 0 / 955 passed / 1 skipped; DMTF emulator 85/85; coverage gates PASS overall 89.1% / scoped 90.3% / kvm 92.2%; issues validate OK.)**
- **Prior (2026-11-18 12:38 UTC): FEATURE #009 (P3, still OPEN) non-dependency, TLS-safe slice: closed the remaining **"Coverage ≥75%"** acceptance item by enforcing a dedicated remote-KVM coverage gate. `tool/coverage_gate.dart` gained `kKvmScopePrefixes` (`lib/features/kvm/`), `kKvmThreshold` (0.75), a pure `evaluateKvmGate()` (`GateResult` named `'kvm'`, reusing `CoverageSummary.scope()` normalization) and `evaluateAllGates()` (the #010 overall + scoped gates plus the #009 KVM gate); CLI `main` + `.github/workflows/verify.yml` now enforce all three. +7 pure-Dart tests in `test/tool/coverage_gate_test.dart` (+16 → +23: scoping at/above/below 75%, custom threshold/prefix, absolute+Windows paths, `evaluateAllGates` pass/fail, JSON serialization of the KVM gate), `DEVELOPMENT.md` thresholds + measured numbers updated. End-to-end full-suite `flutter test --coverage` → gate PASS overall 89.1% (5318/5968), PASS redfish+power+sensors 90.3% (2115/2341), PASS kvm 92.2% (600/651), exit 0. #009 coverage box checked; issue stays OPEN (embedded HTML5 rendering, fullscreen, input forwarding, Launch-Console strategy + WebView dependency remain — externally blocked on platform WebView + BMC TLS validation). No WebView/protocol dependency added; no production TLS weakened. baseline analyze 0 / 939 passed / 1 skipped → verify analyze 0 / 946 passed / 1 skipped; issues validate OK.)**
- **Prior (2026-11-18 12:15 UTC): FEATURE #009 (P3, still OPEN) non-dependency, TLS-safe slice: landed the **gated per-manager capability card + session note**. New `lib/features/kvm/views/kvm_capability_card.dart` (`KvmCapabilityCard`) renders one aggregated `KvmCapability` (manager / ServiceEnabled / ConnectTypes / MaxSessions / resolved URI or source notice) with an explicit "KVM disabled on BMC" helper, every row a single merged Semantics node; new `kvmCapabilitiesProvider(systemId)` FutureProvider walks the managers once and degrades to empty on discovery failure; wired into the gated `KvmView` above the console cards with a persistent top-of-list session note (visible text == announced label). Fixed a real 320 px card-header overflow (Row+Expanded squeezed the title to ~0 width with two status chips → Column + Wrap). +8 widget tests in new `test/features/kvm/kvm_capability_card_test.dart` (RED by absence → GREEN: all fields + merged a11y labels, disabled helper + source notice, section shown/hidden by capability presence, hidden when `kvm false`, 320/800/1300 no-overflow). Capability-card / session-note / disabled-helper acceptance sub-items checked; issue stays OPEN (embedded HTML5 rendering, fullscreen, input forwarding, Launch-Console strategy + WebView dependency, coverage gate — embed/fullscreen/input externally blocked on platform WebView + BMC TLS validation). No WebView/protocol dependency; no production TLS weakened. baseline analyze 0 / 931 passed / 1 skipped → verify analyze 0 / 939 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Prior (2026-11-18 11:30 UTC): FEATURE #009 (P3, still OPEN) genuinely-unimplemented slice: landed the **capability-card model + detection/URI-resolution**. New `lib/features/kvm/models/kvm_capability.dart`: immutable `KvmCapability` (`managerId`/`supported`/`connectTypes`/`serviceEnabled`/`maxSessions`/`uri`/`sourceManagerUri`, plus `hasUri`/`supportsKvmIp`) with a `fromManager` detection factory — `supported = (graphical enabled && KVMIP advertised) || OEM console` (case-insensitive KVMIP + strict shared `FeatureRules.oemHasConsole`), deterministic deduped connect types (graphical→serial→`Oem` marker), serial `maxSessions` fallback — and `resolveLaunchUri` (prefer `GraphicalConsole.@odata.id`, bounded case-insensitive fallback to OEM `KVM`/`WebConsole` `Uri`; read-only, no IPC, no TLS weakening). Exported from `kvm.dart`. `KvmService.fetchCapabilities()` / `fetchCapability(managerId)` added over a shared `_fetchManagerBodies()` walk (`fetchConsoles()` refactored onto it, behaviour unchanged). +19 model tests (`test/features/kvm/kvm_capability_test.dart`) +3 service detection tests (`kvm_service_test.dart`). #009 capability-model/detection/URI-resolution acceptance boxes checked; still OPEN (HTML5 embed/fullscreen/input forwarding + coverage-gate remain — embed/fullscreen/input externally blocked on platform WebView + BMC TLS validation). No WebView/protocol dependency; no production TLS weakened. baseline analyze 0 / 909 passed / 1 skipped → verify analyze 0 / 931 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Prior (2026-11-18 10:44 UTC): FEATURE #009 (P3, still OPEN) genuine unimplemented slice: landed the **vendor extensibility `KvmOemRegistry` interface**. New `lib/features/kvm/models/kvm_oem_registry.dart`: `KvmOemConsoleParser` pluggable interface (`vendorKey` + `parse`), immutable `KvmOemConsoleInfo`, deterministic `KvmOemRegistry` (registration-order resolution, case-insensitive/trimmed vendor-key match, bounded nested-block search, duplicate rejection, unmodifiable snapshot). No vendor parser ships in v1 (registry empty by default), exactly the acceptance item's "interface only in v1". Wired into `KvmConsole.fromManager(..., oemRegistry:)` as an OPTIONAL hook: a registered parser's info enriches the OEM console with connect URI / types / enabled flag, flowing through existing HTTPS/in-app gating; no registry or no match = strict `oemHasConsole` behaviour byte-for-byte unchanged. Exported from `kvm.dart`. +19 tests in new `test/features/kvm/kvm_oem_registry_test.dart` (RED proof: vendor KVM URI yields no launch URI without a registry; GREEN: parser enriches it to `KvmLaunchStrategy.inAppHtml5`; plus registration/nesting/fallback/no-regression). No WebView/protocol dependency; no production TLS weakened. #009 vendor-extensibility box checked; HTML5 embed/fullscreen/input-forwarding remain open (blocked on WebView + BMC TLS). baseline analyze 0 / 890 passed / 1 skipped → verify analyze 0 / 909 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Prior (2026-11-18 10:07 UTC): FEATURE #009 (P3, still OPEN) non-dependency, TLS-safe slice: landed the pure-UI console session lifecycle — `KvmSessionState` + `KvmSessionController` + `kvmSessionProvider` (+ injectable clock) in new `lib/features/kvm/kvm_session.dart`, exported from the `kvm.dart` barrel. Tracks `activeManagerId`/`connectedSince`; app `paused`/`hidden`/`detached` sets a `backgrounded` flag but deliberately keeps the session alive (BMC console persists until its own timeout); ends only on explicit `disconnect()` (pure UI, no RedfishClient → no wire call) or single-session (`MaxConcurrentSessions == 1`) eviction; bounded audit log. +17 tests in `test/features/kvm/kvm_session_test.dart` (written RED by absence, GREEN after impl). The `#009` lifecycle acceptance box is now checked; HTML5 embed / fullscreen / input forwarding / OEM registry remain open (externally blocked on platform WebView + BMC TLS validation). No WebView/protocol dependency; no production TLS weakened. baseline analyze 0 / 873 passed / 1 skipped → verify analyze 0 / 890 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Prior (2026-11-18 09:31 UTC): FEATURE #021 (P2, still OPEN) non-dependency launch-strategy slice: deterministic `KvmLaunchStrategy` + `KvmConsole.launchStrategy` + a single pure `kvmLaunchStatusText()` resolver wired into the viewer (visible text == announced label). Fills two previously-missing branches — disabled-console guidance and secure-HTTPS non-HTML5 browser guidance (never offered for plaintext HTTP). Fixed a real matching bug: `supportsHtml5` is now case-insensitive + trimmed so a BMC emitting `html5` / ` HTML5 ` reaches the in-app HTML5 path (confirmed RED against the pre-fix getter, GREEN after). +12 tests (10 model + 2 widget). No WebView/protocol dependency added; no production TLS weakened; full in-app rendering + dependency acceptance remain open. baseline analyze 0 / 861 passed / 1 skipped → verify analyze 0 / 873 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Prior (2026-11-18 08:52 UTC): FEATURE #021 (P2, still OPEN) TLS-safe slice: in-app KVM HTML5 rendering is now HTTPS-only. `KvmConsole.canLaunchInAppHtml5` no longer accepts plaintext HTTP — added `hasSecureLaunchUri` + `usesInsecureHttpLaunchUri`; `KvmConsoleViewerPage` shows an explicit error-styled secure-transport warning for plaintext-HTTP HTML5 consoles (visible text == announced Semantics label, no internal issue refs). RED→GREEN model + widget tests (+4). No WebView/protocol dependency added; no production TLS weakened; full in-app rendering + dependency acceptance remain open. baseline analyze 0 / 857 passed / 1 skipped → verify analyze 0 / 861 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Prior (2026-11-18 08:18 UTC): FEATURE #010 CLOSED. Landed the final theming/a11y acceptance slice — deterministic light/dark verification for Overview + Dashboard at mobile/tablet/desktop (`test/a11y/light_dark_theme_test.dart`, +15 tests: active-theme brightness, theme-derived render colours, content parity, no-overflow in both brightnesses at all three breakpoints; pixel goldens avoided as platform-fragile). Fixed the real theming defect it exposed: the Dashboard empty-state icon was hardcoded `Colors.grey` — now theme-aware `colorScheme.onSurfaceVariant` (two RED→GREEN tests). With all eight acceptance criteria backed by implemented/tested code, closed #010 via `issues.py close`. baseline analyze 0 / 842 passed / 1 skipped → verify analyze 0 / 857 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Previous: 2026-11-18 07:40 UTC (run, agent:redfish-automation — FEATURE #010 a11y: 48x48 touch target on the Sensors Tiles/Charts view-mode `SegmentedButton`. Probed the 40dp desktop gap (below WCAG 2.5.5), applied the shared `accessibleTouchTargetStyle()` via `style:` to take segments to 48dp, and added `test/features/sensors/sensors_touch_target_test.dart` (+2 tests: ≥48dp switch — RED pre-fix, GREEN after; single stably-named enabled node per segment). baseline analyze 0 / 840 passed / 1 skipped → verify analyze 0 / 842 passed / 1 skipped; DMTF emulator 85/85; issues validate OK.)**
- **Current focus:** **FEATURE — smallest open issue first.** Just landed (this run, 2026-11-20 00:02 UTC, EP-T7 emulator prerequisite doctor): `tool/emulator_doctor.dart` + 18 tests fail closed on missing emulator prerequisites (docker/curl/jq/redfishtool on PATH, repo-relative DMTF mockup fixture), check-only with no container/network/credential use; 4 assertions RED pre-fix → GREEN, analyze 0 / 1390 passed / 1 skipped, no lib/dependency/wire/TLS change. Next unblocked slices: EP-S1 (service launch edges), EP-U1 (fullscreen scaffold). Open: **#009** (P3, smallest open ID), **#021** (P2, highest priority). Next smallest open issue is **#009** (P3); **#021** (P2) is higher priority. Previously landed (2026-11-19 23:25 UTC, EP-P5 no-WebView product-import policy guard): a new test-only pure-Dart guard (`test/features/kvm/platform/product_import_policy_test.dart`, 19 tests) machine-checks the resolved no-embedded-WebView decision — product `lib/**.dart` imports no `webview_flutter` / `flutter_inappwebview` / `url_launcher` and opens no raw `MethodChannel` / `EventChannel` console channel, and `pubspec.yaml` / `pubspec.lock` carry no such dependency (comment/string/filename mentions exempt); 6 assertions confirmed RED pre-fix (`Expected: non-empty / Actual: []`) → GREEN, analyze 0, full suite green, no `lib/`/dependency/wire/TLS change, CI already runs it via `flutter test --coverage`. Next unblocked slices: EP-T7 (emulator prerequisite doctor), EP-S1 (service launch edges), EP-U1 (fullscreen scaffold). Open: **#009** (P3, smallest open ID), **#021** (P2, highest priority). Previously landed (22:09 UTC, RM-3 non-map OEM console value fail-closed): `FeatureRules.oemHasConsole` now requires a console-like key's value to be a map, so a scalar/list/null under `KVM`/`Console` cannot fake an OEM console on the discovery gate or either KVM card; +11 tests (incl. three-surface cross-view agreement + capability-card widget), analyze 0 / 1346 passed / 1 skipped, emulator 85/85, no dependency/wire/TLS change. Next unblocked slices: EP-U5 (launch-status parity), EP-P5 (no-WebView import guard), EP-S1 (service launch edges), EP-T7 (emulator prerequisite doctor). Open: **#009** (P3, smallest open ID), **#021** (P2, highest priority). Next smallest open issue is **#009** (P3); **#021** (P2) is higher priority. Previously landed (21:26 UTC, RS-4 manager-member dedup): `KvmService` dedups repeated/padded/string-form manager `Members` links by normalized URI (first wins) so each physical manager yields one console/capability card; blank/non-string links already rejected; +2 RED→GREEN tests, analyze 0 / 1335 passed / 1 skipped, emulator 85/85, no dependency/wire/TLS change. Next unblocked slices: RM-3 (non-map console payload tolerance), EP-U5 (launch-status parity), EP-P5 (no-WebView import guard), EP-S1 (service launch edges). Open: **#009** (P3, smallest open ID), **#021** (P2, highest priority). Next smallest open issue is **#009** (P3); **#021** (P2) is higher priority. Just landed (this run, 18:41 UTC, EP-T6 live-BMC unattended-safety guard): `tool/unattended_guard.dart` + CI gate + 15 tests fail closed on ungated `test_integration/**.dart`, plain-test emulator-env references, and production `lib/**.dart` hard-enabling self-signed TLS; analyze 0 / 1304 passed / 1 skipped, emulator 85/85. Next concrete slices: EP-M1 (URI-scheme edges), RM-2 (non-map payload tolerance), EP-S1 (service launch edges), EP-U1 (fullscreen scaffold), EP-T1/EP-T3 (fixtures/coverage). Prior fixed (18:01 UTC, RM-2-adjacent session-limit tolerance): shared pure `kvmSessionLimit(Object?)` helper replaces the two duplicated private parsers so both KVM views tolerate an integer-valued JSON double (`4.0`) for `MaxConcurrentSessions` and can never drift; +11 tests (4 RED→GREEN behavioral), analyze 0 / 1289 passed / 1 skipped, emulator 85/85. Next concrete slices: EP-M1 (URI-scheme edges), RM-2 (non-map payload tolerance), EP-S1 (service launch edges), EP-U1 (fullscreen scaffold), EP-T4/EP-T6 tooling. Just fixed (this run, 16:31 UTC, EP-U3 external-client protocol-guidance parity): pure `kvmExternalClientNoticeFor(protocol)` is the single source of truth that now names the specific external client (VNC/RFB / SSH / Telnet / IPMI / KVMIP) on the per-console card, capability card and viewer alike (visible text == merged a11y label, 320/800/1300 px no-overflow); +9 RED→GREEN widget tests, analyze 0 / 1257 passed / 1 skipped, emulator 85/85. Next concrete slices: EP-M1 (URI-scheme edge cases), RM-2 (malformed-payload tolerance), EP-S1 (service launch-path edges), EP-U1 (fullscreen scaffold), EP-T4 (fixture+CI guard). Prior (15:35 UTC, EP-M2/EP-U3 cross-surface external-client classifier parity): shared `isExternalClientConsoleUri` / `externalClientConsoleProtocol` helpers in `launch_plan.dart` (fail-closed transport gate) now back both `KvmConsole` (ad-hoc parse removed) and new `KvmCapability.requiresExternalConsoleClient` / `externalClientProtocolLabel` getters, so both views classify/label the same endpoint identically; the capability card renders a shared `kvmExternalClientNotice` for a resolved VNC/RFB/KVMIP/serial endpoint with merged a11y (+8 tests, 1 widget RED→GREEN confirmed pre-fix; analyze 0 / 1248 passed / 1 skipped; emulator 85/85). Next concrete slices: EP-M1 (URI-scheme edge cases), RM-2 (malformed-payload tolerance), EP-S1 (service launch-path edges), EP-U1 (fullscreen scaffold), EP-T4 (fixture+CI guard). Just fixed (14:56 run, RM-1 URI-less OEM console enablement): the shared `kvmOemConsoleEnabled` now honors an explicit `ServiceEnabled:false` / legacy `Enabled:false` on a URI-less OEM console block (falls back to the console-like block only when no URI-bearing console exists), so the console/capability cards and discovery gate no longer advertise a BMC-disabled OEM console as enabled; launchable consoles still read URI + enablement from the same block (+6 tests, 5 RED→GREEN confirmed pre-fix; analyze 0 / 1237 passed / 1 skipped; emulator 85/85). Just fixed (this run, 14:11 UTC, EP-U4 viewer session lifecycle): the console viewer now owns the pure-UI KVM session — connect on enter (with `maxConcurrentSessions` eviction), a merged-a11y active/idle disclosure + "Disconnect console" button, and disconnect on back/pop via `PopScope`; all provider writes outside widget lifecycle methods (+5 RED→GREEN viewer widget tests, analyze 0 / 1231 passed / 1 skipped, emulator 85/85). Prior fixed (13:28 run, discovery-gate OEM-enablement parity): the KVM-tab gate `FeatureRules._managerConsoleType` now calls the shared `kvmOemConsoleEnabled` helper for the OEM branch too, so an explicitly disabled `Oem.KVM` (ServiceEnabled/legacy Enabled false) no longer opens a "KVM" tab that the capability card reports not-supported/disabled and the console card refuses to launch — closing a cross-view regression from the 12:05 fix; flag-less/enabled/truthy-wins OEM consoles are unchanged (+7 RED→GREEN tests, 3 confirmed RED pre-fix incl. a three-surface agreement test; analyze 0 / 1223 passed / 1 skipped, emulator 85/85, coverage kvm 95.8%). Prior fixed (12:48 run, RS-2 manager-walk robustness): a transient per-member 503 / 429 / timeout no longer blanks the whole KVM screen — `_fetchManagerBodies` skips 404 + `RedfishException.retryable` failures while rethrowing auth/cert/non-retryable ones; +4 RED→GREEN service tests (2 confirmed RED pre-fix), analyze 0 / 1216 passed / 1 skipped, emulator 85/85, coverage kvm 95.8%. Prior fixed (12:09 run, vendor-parser normalization): the registered-vendor-parser branch of `KvmConsole.fromManager` now applies the same `_uriString` / `_normalizedConnectTypes` helpers as every other console source, so a padded URI / duplicate/blank/garbled connect types can no longer render inconsistently between the OEM console card and the capability card / launch plan (+2 RED→GREEN tests, 1 confirmed RED pre-fix; analyze 0 / 1209 passed / 1 skipped, emulator 85/85, coverage kvm 95.7%; rebased onto concurrent rf-gate merge `c68dba3`). Prior fixed (12:05 run, OEM console enablement): the generic OEM console path now honors the block's own `ServiceEnabled` / `Enabled` flags via the shared `kvmOemConsoleEnabled` helper, so a BMC-disabled OEM KVM no longer shows an "Open console" action or a Supported/Enabled capability card and instead fails closed to `disabled`/`copyOnly` with the "KVM disabled on BMC" helper (+11 RED→GREEN tests, 6 confirmed RED pre-fix; analyze 0 / 1202 passed / 1 skipped, emulator 85/85). Prior fixed (10:43 run, cross-surface clipboard safety): the per-console card's "Copy connect info" now uses the new fail-closed `KvmConsole.clipboardTargetUri` (`launchPlan.targetUri ?? sourceManagerUri`), matching the viewer — a control-char/spoofed-authority URI is no longer placed on the clipboard by the card (+3 RED→GREEN tests, analyze 0 / 1188 passed / 1 skipped, emulator 85/85). Just fixed (10:02 run, RU-2): the two cross-surface a11y notices (session-persistence + disabled-helper) now come from single shared constants and the session notice is shown on the deepest viewer surface with visible==label merged Semantics (+2 RED→GREEN viewer widget tests; analyze 0 / 1185 passed / 1 skipped; emulator 85/85). Prior fixed (09:16 run, EP-S2): `KvmService.pickPrimary` now prefers a control-safe secure-HTTPS console as the recommended "Primary" / external-browser target, never badging a plaintext-HTTP or external-client-only console when a safe HTTPS one exists (fallback tiers preserved). Next concrete slices (all unblocked, #009/#021 still open): EP-S1 (service launch-path edge cases), EP-P3 (platform final no-WebView route-table test), RM-2/EP-M1 (malformed-payload tolerance + URI-scheme edges), EP-U1 (fullscreen scaffold), EP-T4 (fixture + CI guard). Landed: EP-M2 + capability-card external-client guidance (this run), RM-1 (14:56), EP-U4 (14:11). Do NOT add a WebView/url_launcher dependency unattended (EP-P2/EP-T2/E-U2 deferred on manual per-target validation evidence); never weaken production TLS. Just fixed (08:38 run): `planConsoleLaunch` now derives its `targetUri` from the shared `_controlSafeTrimmedUri` control-safety gate, so a malformed URI on the copy-only route is never handed to a launcher/clipboard (the viewer falls back to the manager source) — +4 RED→GREEN tests; all gates green. Both issues' remaining substantive acceptance boxes (embedded HTML5 rendering, fullscreen, input forwarding, Launch-Console strategy + WebView dependency) are externally blocked on platform WebView support + BMC self-signed/TLS validation that cannot be done unattended — do NOT weaken production TLS and do NOT skip FEATURE for DOCS/EMULATOR. Just fixed (07:56 run): the non-HTTP external-client classifiers (`KvmConsole.requiresExternalConsoleClient` / `externalClientProtocolLabel`, VNC/RFB/KVMIP/serial) now share the `isControlSafeConsoleUri` gate with the HTTP(S) families, so a raw-space/C0/DEL/Unicode-separator-bearing external URI fails closed to `noUri` instead of being announced as a trustworthy external client. Prior fix (07:19 run): an enabled plaintext-HTTP HTML5 console card no longer shows both the "HTML5 console — open via BMC web UI." hint AND the unencrypted warning — the pure `KvmConsole.showHtml5WebUiHint` getter (`supportsHtml5 && !usesInsecureHttpLaunchUri`) gates the hint so the unsafe endpoint gets only the honest "configure HTTPS first" guidance, while URI-less and secure HTTPS HTML5 consoles keep the hint. Prior fix (06:41 run): an enabled plaintext-HTTP **non-HTML5** console (e.g. KVMIP over `http://`) is now classified `KvmLaunchStrategy.insecureHttp` instead of the misleading `noUri` — it keeps a copyable "Open console" action and surfaces an error-styled, merged-a11y unencrypted-HTTP warning in the viewer, agreeing with both cards; still never an in-app/browser render target. Prior KVM fixes (all still green): hardened plaintext-HTTP/secure-URI classifiers shared across models + launch plan; fail-closed launch decision layer; console/capability plaintext-HTTP warnings; `canOpenConsole` card gate; manager-walk member-URI / manager-`Id` / `@odata.id` normalization and malformed-payload tolerance; RemoteConsole detection + discovery-gate; capability connectTypes/maxSessions/resolved-URI skip disabled blocks. Remaining genuine candidates: a cross-view disabled-helper / session-note copy consistency gap, or epic-triage/split the WebView-blocked rendering work into an unblocked testable plan. Never verification-only churn while an issue is open.
- **Run cadence:** `@every 30m` in scheduler (runbook originally `0 */5 * * *`; restore 5h once the small-issue backlog is empty, or keep 30m ONLY for FEATURE runs — never schedule verification-only churn at 30m).
- **Model:** `opencode-go/iceman-contributor-free` (scheduler actual; runbook header was `opencode/deepseek-v4.1-flash-free` — updated 2026-11-16)
- **Status keys:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked

## Selection rules — CODE FIRST (verification-only runs are failures)

1. **P0 first.** If `flutter analyze` or `flutter test` is red, repair that before
   any new work. Never start a feature on a red baseline.
2. **FEATURE second, always.** On a green baseline, pick the smallest open
   issue from `issues/open/` (currently open: `#021` P2, `#009` P3 — priority
   then oldest; completed: `#008`, `#024`, `#019`, `#028`, `#026`, `#013`,
   `#011`, `#017`, `#018`, `#023`, `#025`, `#007`, `#010`) and land it with tests. Every green run
   MUST change `lib/` / `test/` / `test_integration/` / `tool/`. A run with
   zero code changes is a failed run while any issue is open.
3. **DOCS is a cheap gate, never the primary.** Check anchors
   (`git ls-remote` + `curl -sSIL`); if unchanged and mirror queue EMPTY,
   touch only timestamp lines and return to rule 2. No full re-downloads,
   no manifest rewrites on unchanged anchors.
4. **EMULATOR only on change.** Full `tool/emulator/run_tests.sh` re-run ONLY
   if `lib/` / `test_integration/` / `tool/` / fixtures changed since the
   last EMULATOR run, or >7 days since the last green run. Never re-run the
   full 85-test suite just for alternation.
5. One primary workstream per run. Prefer a finished, tested increment over a
   broad half-finished refactor — but a finished SMALL issue always beats a
   verification-only re-run.

## P0 — keep `main` green

- [ ] Keep `flutter analyze` at **0 issues** and the full `flutter test` suite green.
- [ ] Keep `python3 issues/issues.py validate` green whenever `issues/` changes.
- [ ] Never leave the working tree dirty at the end of a run: commit intended work
      or stash it with a clear label; never discard user work.
- [ ] Never force-push, rewrite history, print credentials, or commit secrets.
- [ ] If a change cannot be made green, revert only that change and record why.

## P1 — official docs and compliance

- [x] **DOCS-1** Establish `documentations/external/` as the official-docs mirror:
      DMTF Redfish spec, schema index, mockup, and OpenBMC bmcweb docs. Add a
      manifest with URL, fetch time, SHA-256, size, and license/notes.
      Start at `https://redfish.dmtf.org/`, `https://redfish.dmtf.org/schemas/v1/`,
      `https://github.com/DMTF/Redfish-Mockup-Server`, and
      `https://github.com/openbmc/bmcweb/tree/master/docs`.
      (run 2026-10-22, commit c8dc7e1 — mirror + manifest + REQUIREMENTS.md live;
      re-fetch on upstream change only; DOCS-8 23:55 run re-verified pins, moved
      bmcweb to `27e0930b`, added CLIENTS.md)
- [x] **DOCS-2** Refresh the DMTF schema/mockup snapshot used by
      `documentations/redfish_reference/` and `test/fixtures/redfish/`; verify the
      provenance section in `documentations/redfish_reference/README.md` is current.
      (run 2026-10-22 — 6 versioned DMTF schemas refreshed to current upstream:
      ComputerSystem/Chassis v1_29_0, Sensor v1_14_0, AccountService v1_19_0,
      EthernetInterface v1_12_6, SoftwareInventory v1_15_0; superseded files kept;
      mockup payload still matches pinned upstream `23d21f9a`, no refresh needed;
      provenance updated in both READMEs + REQUIREMENTS.md DOCS-2 section)
- [x] **DOCS-3** Audit the latest Redfish specification (DSP0266, currently linked
      from `https://redfish.dmtf.org/`) against the client's discovery, auth,
      error, PATCH/ETag, task, and subscription behaviour. Record gaps with
      section numbers and source URLs.
      (run 2026-10-22 — audit complete against DSP0266 1.25.0; corrected the
      Eventing citation to §12.1 and Tasks to §12.2 "Asynchronous operations" in
      REQUIREMENTS.md; added task-monitor polling + event-subscription + SSE +
      bmcweb vendor rows; remaining gaps are code issues #016/#008/#020/#022 + the
      DOCS-7 events decision; DOCS-8 23:55 run re-verified 1.25.0 is still the
      latest published PDF)
- [x] **DOCS-4** Audit OpenBMC bmcweb's `docs/Redfish.md`,
      `docs/REDFISH_CHECKLIST.md`, and `docs/OEM_SCHEMAS.md`; document where our
      feature detection differs from bmcweb's actual behaviour.
      (run 2026-10-22 — full feature-detection diff audit complete: KVM Oem
      false-positive fixed in `FeatureRules` + `KvmConsole.fromManager`;
      bmcweb firmware update is HTTP-push not SimpleUpdate (→ #008/#020);
      ResetActionInfo vs SupportedResetTypes (→ #022/#016); SerialConsole lives
      on ComputerSystem not Manager (→ #009/#021); AuthMethods + TelemetryService
      vendor rows recorded. Cited `Redfish.md`/`OEM_SCHEMAS.md` @ `0128851e`.
      REDFISH_CHECKLIST.md is contributor-process only — no client-facing fields)
- [x] **DOCS-5** Map every `SystemFeatures` flag to a spec citation and a test.
      Add a table under `documentations/redfish_reference/` or
      `documentations/external/redfish/REQUIREMENTS.md`.
      (run 2026-10-22 — full per-flag table added under REQUIREMENTS.md
      "DOCS-5 — SystemFeatures flag → spec citation → test map" for all 10
      flags; surfaced + fixed the `firmwareUpdate` `ServiceEnabled` gap)
- [ ] **DOCS-6** Keep the downloaded corpus bounded: max 25 MB per file and 50 MB
      of new downloads per run. For larger artifacts store the URL + hash +
      extracted notes instead of the binary.
- [x] **DOCS-30-a** Optional `LocationIndicatorActive` boolean setter (the
      current-bmcweb successor surface to the deprecated `IndicatorLED` that
      #016's LED flow already handles by absence). Source: bmcweb
      `Redfish.md` @ `ade964e7` — upstream commit `522e6b7e` (2026-10-19,
      "IndicatorLED: Remove deprecated property"; a `IndicatorLED` PATCH now
      answers `Base.1.19.PropertyUnknown` while a
      `LocationIndicatorActive` PATCH 200s) —
      https://github.com/openbmc/bmcweb/commit/522e6b7e94163565f4644d19f4a7703823d1a8a2
      and the mirror `documentations/external/redfish/openbmc/Redfish.md`
      (refreshed 2026-11-04, SHA `07e770c9…`); DMTF side:
      `ComputerSystem.v1_29_0.json` `LocationIndicatorActive` (boolean,
      writable; the newest mirrored def). **Done (run 2026-11-04):**
      capability-gated in model/UI/controller/service — prefers
      `LocationIndicatorActive` when served (On/Inactive ChoiceChips),
      otherwise falls back to `IndicatorLED`; `SystemSettingsService.setLocationIndicatorActive`
      PATCHes with `If-Match` via `patchJson etag:`; unit + widget tests added;
      REQUIREMENTS.md trace updated; no emulator live pin needed (mockup
      does not serve the property).
- [x] **DOCS-7** Event subscription support: client has no EventService /
      Subscriptions implementation yet; DSP0266 §12.1 "Eventing" +
      `EventService.json` are mirrored. **Decision (2026-10-22): out-of-scope
      this milestone** — no event consumer (telemetry/firmware tasks are
      poll-based), no SSE transport in `pubspec.yaml`, no test bed that can push
      events. Rationale + spec citations recorded in REQUIREMENTS.md
      "DOCS-7 decision". Revisit when telemetry (#007/#019) or task monitoring
      (#008/#020/#022) lands.
- [x] **DOCS-10** Mirror the official DMTF `Task` schemas (`Task.json`
      aggregator, `Task.v1_7_4.json`, `TaskService.v1_2_1.json` — fetched
      2026-10-23, 32,950 bytes total, inside the DOCS-6 budget) and audit
      DSP0266 §12.2 "Asynchronous operations" against the client's async
      handling; fold the optional 202 `Retry-After` into `UpdateTask`.
      (run 2026-10-23 — manifest rows + audit table in REQUIREMENTS.md
      "DOCS-10"; `FirmwareService.startSimpleUpdate` now returns `UpdateTask`
      with `taskUri` + `retryAfterSeconds`; task *polling* stays #008/#020
      (firmware) + #022 (power))
- [x] **DOCS-11** Mirror the missing DMTF `LogEntry` schema corpus
      (`LogEntry.json` aggregator, `LogEntry.v1_22_0.json` newest, plus
      `LogEntry.v1_16_0.json` — the version the pinned mockup serves — and
      `LogEntryCollection.json`), and add the newest `LogService.v1_9_0.json`
      (external corpus only had the aggregator).
      (run 2026-10-23 — 171,095 bytes total, inside the DOCS-6 budget;
      manifest rows + SHA-256s verified; also mirrored LogEntry
      aggregator/v1_16_0/collection into `test/fixtures/redfish/schemas/`;
      REQUIREMENTS.md log row source cites now resolve to real mirror files;
      upstream anchors re-verified: bmcweb `27e0930b`, mockup `23d21f9a`,
      DSP0266 1.25.0, schema index current — no version advanced for the
      other tracked families)
- [x] **DOCS-12** Mirror the missing **versioned** definitions for the six
      aggregator-only families the client maps — `UpdateService`,
      `EventService`, `SessionService`, `Manager`, `Power`, `Thermal` — newest
      versioned file (what each aggregator `$ref`s) **plus** the version the
      pinned DMTF mockup serves (`UpdateService.v1_13_0`,
      `EventService.v1_10_1`, `SessionService.v1_1_8`, `Manager.v1_19_0`,
      `Power.v1_7_2`, `Thermal.v1_7_2`), the DOCS-11 LogEntry precedent.
      (run 2026-10-23 — 12 files, 553,772 bytes total, inside the DOCS-6
      budget; manifest rows + SHA-256s verified; the six mockup-served versions
      also copied into `test/fixtures/redfish/schemas/` so every `@odata.type`
      the mockup publishes has a versioned schema in the fixture; the six
      newest versions were already in the fixture and verified byte-identical
      to upstream; REQUIREMENTS.md rows + trace note now cite the real mirror
      files; audited deltas — `SessionService.v1_2_0` adds
      `AbsoluteSessionTimeout*` (note for #015), `UpdateService.v1_17_1` adds
      `LocalImageStore*`/`Stage`/`Activate` (note for #008/#020), `Manager
      v1_25_0` adds `SecurityMode`/`ReadyToRemove`, Power/Thermal no deltas —
      no client code change this run)
- [x] **DOCS-13** Mirror the versioned definitions for the six remaining
      client-relevant resources the pinned mockup serves / the emulator pins but
      the external corpus had no versioned defs for: `Session`
      (`v1_9_0` newest + `v1_7_1` mockup-served — auth surface #015/#017/#026),
      `ManagerAccount` (`v1_14_2` + `v1_12_0`), `Role` (`v1_3_3` + `v1_3_1`),
      `ManagerNetworkProtocol` (`v1_14_0` + `v1_10_0` — KVMIP/HTTPS/SSH console
      endpoints for #009/#021), `ActionInfo` (`v1_6_0` + `v1_4_1` — bmcweb
      `ResetActionInfo` allow-list source for #022/#016), `ServiceRoot`
      (`v1_22_0` + `v1_16_1` — discovery contract for #018), plus the
      mockup-served `Task.v1_7_3`/`TaskService.v1_2_0` (DOCS-10 had mirrored
      only the newest). (run 2026-10-23 — 19 files, 397,572 bytes total,
      inside the DOCS-6 budget; manifest rows + SHA-256s verified; the eight
      mockup-served versions also copied into `test/fixtures/redfish/schemas/`
      so every `@odata.type` the mockup publishes for these families has a
      versioned schema in the fixture; REQUIREMENTS.md DOCS-13 audit table +
      Trace-notes count 16 → 21; audited newest-vs-served deltas — no client
      code change needed; upstream anchors re-verified: bmcweb `27e0930b`,
      mockup `23d21f9a`, DSP0266 1.25.0, schema index 200 OK)

- [x] **DOCS-14** Mirror the OData base vocabulary (`odata.4.0.0.json` —
      the canonical lowercase file; bare `Odata.json` 404s upstream) so the
      last un-mirrored REQUIREMENTS.md source citation (row 65,
      `@odata.id` link traversal) resolves to a real mirror file; byte-verify
      against `test/fixtures/redfish/schemas/Odata.json`; re-verify all corpus
      anchors (bmcweb HEAD, mockup pin, DSP0266 version, schema index).
      (run 2026-10-23 — 1,834 bytes, inside the DOCS-6 budget; byte-identical
      to the fixture copy (fixture proven current); bmcweb advanced
      `27e0930b` → `fbb307a` with all four mirrored docs byte-identical (no
      refresh needed, anchors updated); mockup still `23d21f9a`; DSP0266 still
      1.25.0; schema index 200 OK; manifest row + REQUIREMENTS.md DOCS-14
      audit section added)

- [x] **DOCS-15** Audit DSP0266 §7.3 "Query parameters" (§7.3.1–7.3.5:
      processing order, `$expand` options `*`/`$levels` default 1/`.`/`~` +
      `MaxLevels` + 507 oversized-payload, `$select`, `$filter` built-in
      operators + precedence, `clientcontext` incremental retrieval, 400/501/
      QueryNotSupportedOnResource) against the client's query transport and
      the emulator-pinned query contract; fold the bottom line into #018
      (gate `$expand` on `ProtocolFeaturesSupported`, filter/project
      client-side) and pin the `getJson(path, query:)` forwarding contract
      with a unit test.
      (run 2026-10-23 — REQUIREMENTS.md "DOCS-15" audit table (9 rows) +
      manifest anchors note updated to 19:20 UTC; anchors re-verified:
      bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200;
      +1 transport unit test; no corpus refresh needed — corpus complete for
      all 16 client-mapped families)

- [x] **DOCS-17** Audit the DSP0266 §13.3.4.3 "Session lifetime" clause
      against the client's session expiry handling, using the mirrored
      `SessionService.json` + `SessionService.v1_2_0.json` (DOCS-12); pin the
      timeout contract with unit tests (`SessionTimeout` inactivity TTL;
      `AbsoluteSessionTimeout`/`AbsoluteSessionTimeoutEnabled` added v1_2_0 —
      maximum seconds open regardless of activity, applied only when enabled;
      the effective deadline is the *earlier* of the two so the client
      re-authenticates before the service kills the session).
      (run 2026-10-24 — REQUIREMENTS.md DOCS-17 trace table + the
      session-timeout row corrected from overstated OK to Partial (model-level
      pinned; AuthManager wiring stays #015); `Session.expiryFromService`
      helper + 6 unit tests in `models_test.dart`; no corpus refresh —
      anchors re-verified 01:07 UTC all unchanged: bmcweb `fbb307a`, mockup
      `23d21f9a`, DSP0266 1.25.0, schema index 200; UI-2 increment:
      FirmwareView error state merged semantics label + separate Retry control,
      +1 widget test)

- [x] **DOCS-18** Mirror the DMTF **message-registry payload** the pinned
      mockup serves (`Base.1.5.0.json` — the file behind
      `MessageRegistryFile.Location[0].Uri`, pinned live by the EMU-2
      MessageRegistry contract 2026-10-24: 60 Base.* templates with
      Message/Severity/NumberOfArgs behind `RedfishError.code`/`firstMessage`)
      so the §8.6 error-response / §11.4 message-registry rows in
      REQUIREMENTS.md cite a real mirror file. Registry JSONs live on the DMTF
      registries path (verify with `curl -sSIL`; the `redfish/schemas/v1/`
      index carries only the `MessageRegistry.json` aggregator + versions —
      the payloads are separate). Keep inside the DOCS-6 budget (Base registry
      is ~50 KB). Also consider the newest `Base.*` published version for the
      "newest vs mockup-served" delta note. Source:
      <https://redfish.dmtf.org/registries/> (+ the mockup-served path
      `/redfish/v1/Registries/Base.1.5.0.json` in the fixture).
      (run 2026-10-24 — `redfish/registries/Base.1.5.0.json` mirrored,
      **byte-identical** to `test/fixtures/redfish/dmtf_mockup/Registries/
      Base.1.5.0.json` (SHA-256 `c10263417a076402a992f099db4e019c9d91f674d256d
      f32a390b86a2c46492c`, 31,984 bytes — proven authentic) + newest
      `redfish/registries/Base.1.24.0.json` (138,295 bytes; 125 templates;
      1.5.0 → 1.24.0 adds 65 + rewords 39 shared Message strings with
      **NumberOfArgs stable** — the emulator-pinned contract holds across the
      newest registry too); §8.6 error-envelope row + the trace-note
      MessageRegistry pin now cite the real mirror files; registries path +
      both files 200; 170,279 new bytes total, inside the DOCS-6 budget;
      UI-2 Dashboard `_ErrorSummary` merged semantics + separate Retry control,
      +2 widget tests)

- [x] **DOCS-19** Mirror the **mockup-served** versioned schemas for the eight
      client-mapped families DOCS-2 refreshed to **newest-only**: the pinned
      `23d21f9a` mockup serves older `@odata.type` versions —
      `Sensor.v1_8_1` (42/42 sensors), `ComputerSystem.v1_22_0`,
      `Chassis.v1_25_0`, `AccountService.v1_15_0`,
      `SoftwareInventory.v1_10_1`, `LogService.v1_6_0`,
      `EthernetInterface.v1_12_0`, `MessageRegistry.v1_0_0` — plus the newest
      `MessageRegistry.v1_9_0` (the `@odata.type` behind the newest
      `Base.1.24.0` registry payload, DOCS-18), into
      `documentations/external/redfish/schemas/v1/` **and**
      `test/fixtures/redfish/schemas/` so every `@odata.type` the mockup
      publishes for a client-mapped family has a versioned schema in the
      fixture (the DOCS-11/12/13 invariant). Source:
      `https://redfish.dmtf.org/schemas/v1/<Name>.json`.
      (run 2026-10-24 — 9 files, 560,665 bytes total, inside the DOCS-6
      budget; manifest rows + SHA-256s verified; property-delta audit: every
      client-read field present in the served versions (`Sensor` Reading/
      ReadingType/ReadingUnits/Thresholds, `ComputerSystem` identity/
      PowerState/Summaries, `AccountService` lockout surface, `LogService`
      ServiceEnabled/OverWritePolicy/Entries, `EthernetInterface` MAC/IP/VLAN)
      — **no client code change needed**; trace rows updated to cite served
      files; anchors re-verified: bmcweb `fbb307a`, mockup `23d21f9a`,
      DSP0266 1.25.0, schema index 200)

- [x] **DOCS-20** Mirror the newly pinned chassis-metrics/subsystem families
      (emulator 45 → 48, 2026-10-24) into
      `documentations/external/redfish/schemas/v1/` **and**
      `test/fixtures/redfish/schemas/`: `EnvironmentMetrics.v1_3_1`,
      `ThermalSubsystem.v1_3_1`, `ThermalMetrics.v1_3_1`,
      `PowerSubsystem.v1_1_1`, `PowerSupply.v1_5_3`, `FanCollection`,
      `PowerSupplyCollection`, plus the mockup-served `Fan.v1_5_1`,
      `PowerSupplyMetrics.v1_1_1`, and the `Redundancy.json` →
      `Redundancy.v1_7_1` citation chain. **Done (run 2026-10-24,
      11 files / 160,101 bytes; SHA-256s + manifest rows verified; property
      audit complete; commit 963366e).**

- [x] **DOCS-21** Mirror the versioned schemas for the **Battery surface** the
      emulator pinned live (48 → 50, 2026-10-24): `Battery.v1_2_2.json`
      (mockup-served `#Battery.v1_2_2.Battery` — Module1 detail:
      Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+
      ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent +
      `#Battery.SelfTest`/`#Battery.Calibrate` action targets),
      `BatteryMetrics.v1_0_3.json` (mockup-served `#BatteryMetrics.v1_0_3.
      BatteryMetrics` — InputVoltage/OutputVoltages/InputCurrentAmps/
      OutputCurrentAmps/StoredEnergyWattHours/TemperatureCelsius/ChargePercent/
      CellVoltages with `DataSourceUri` links), plus the aggregator +
      `BatteryCollection.json`, into `documentations/external/redfish/schemas/
      v1/` **and** `test/fixtures/redfish/schemas/` so every `@odata.type` the
      pinned mockup publishes for the battery family has a versioned schema in
      the fixture (the DOCS-19/20 invariant). Source:
      `https://redfish.dmtf.org/schemas/v1/Battery.v1_2_2.json` (+ newest
      version for the delta note, following the DOCS-12/13 precedent). Keep
      inside the DOCS-6 budget.
      **Done (run 2026-10-24, 7 files / 95,718 bytes; SHA-256s + manifest
      rows verified; property-delta audit complete — newest versions
      (Battery.v1_5_0 / BatteryMetrics.v1_1_0) additive only
      (BatteryChemistryType/EnergyStorageType/NominalOutputVoltage/
      ServicedDate; CRate/ERate), emulator-pinned contract holds, no code
      change; bmcweb anchor advanced `fbb307a` → `63a18f4` with all four
      mirrored docs byte-identical).**

- [x] **DOCS-22** Freshness-audit the mirrored **newest** schema versions
      against the live DMTF schema index for every client-mapped family, and
      mirror any that advanced upstream (the "newest + served" pair precedent,
      DOCS-11/12/13/19/20/21) — keep the corpus current so the properties the
      client reads are checkable against the newest definitions, not just the
      mockup-served ones. (run 2026-10-24 — **8 of 33 families had advanced**:
      EnvironmentMetrics v1_3_1→v1_7_0, Fan v1_5_1→v1_6_0, PowerSubsystem
      v1_1_1→v1_2_0, PowerSupply v1_5_3→v1_8_0, PowerSupplyMetrics v1_1_1→
      v1_3_0, TaskService v1_2_1→v1_3_0, ThermalMetrics v1_3_1→v1_3_3
      (structural no-op), ThermalSubsystem v1_3_1→v1_5_0; 8 files / 189,768
      bytes mirrored into the external corpus only (fixture keeps
      mockup-served versions), manifest rows + SHA-256s verified; deltas
      **additive-only** — no client code change; TaskService v1_3_0 adds a
      `#TaskService.DeleteAllCompletedTasks` action + `TaskMonitorAutoExpirySeconds`
      (note for #008/#020 poller); stale bmcweb anchor `fbb307a` →
      `63a18f4` in manifest + REQUIREMENTS.md Sources fixed + re-verified
      live byte-identical; remaining 25 families unchanged; all anchors
      re-verified: bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0,
      schema index 200)

- [x] **DOCS-23** Mirror the two published types the EMU-2 Bios
      `@Redfish.Settings` pin (EMU 52→53) reads — `#Bios.v1_2_2.Bios` and
      `#Settings.v1_3_5.Settings` — into the external corpus (served + newest
      pair, the DOCS-12/13/19/20/21 precedent). Source:
      `https://redfish.dmtf.org/schemas/v1/Bios.v1_2_2.json` (+ `Bios.v1_3_0`
      newest), `Settings.v1_3_5.json` (+ `Settings.v1_5_0` newest).
      **Done (run 2026-10-24, 4 files / 67,020 bytes, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit additive-only — Bios
      v1_3_0 adds `Passwords` (a #015/#026 input: the password-management
      resource superseding action-based ChangePassword), Settings v1_5_0 is a
      property no-op (6→6); client-mapped decision: Bios/Settings stay NOT
      client-mapped — the client reads only `ComputerSystem.BiosVersion` (the
      overview firmware line), no BIOS-config editor exists; if one lands it is
      **#028** and the served versions must move into
      `test/fixtures/redfish/schemas/` + the emulator corpus-invariant family
      list; anchors re-verified: bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266
      1.25.0, schema index 200).**

- [x] **DOCS-24** Mirror the two **EMU-2-pinned non-client-mapped** families
      the 18:40 EMU run reads but the external corpus had no schemas for:
      `EventDestination` (the four `Subscriptions` members —
      `#EventDestination.v1_14_0.EventDestination`, Redfish/SNMPv3/SMTP-OEM/
      SyslogTCP transports — the DOCS-7 bed for #019) and `VirtualMedia` (the
      system boot-media read surface — `#VirtualMedia.v1_6_3.VirtualMedia`,
      CD1 Applet + Floppy1 URI — the #028 boot-media UX input). Mirror the
      **mockup-served** versions plus the **newest** published versions plus
      the collection types (the DOCS-12/13/19/20/21/23 "newest + served" pair
      precedent). Source: `https://redfish.dmtf.org/schemas/v1/<Name>.json`.
      **Done (run 2026-10-24, 8 files / 194,278 bytes total, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit additive-only —
      `EventDestination.v1_14_0`→`v1_17_1` adds BackupDestinations/
      Certificates/ClientCertificates/EventFormatType/HeartbeatIntervalMinutes/
      HttpHeaders/OEM*/OriginResources/SendHeartbeat/Severities/
      SubordinateResources/SyslogFilters/VerifyCertificate (+Actions),
      `VirtualMedia.v1_6_3`→`v1_7_0` adds Certificates/EjectPolicy/
      EjectTimeout/HTTPHeaders/Password/Status/TransferMethod/
      TransferProtocolType/UserName (+Actions) — the `Password`/`UserName`
      additions are a #028 boot-media security note (never read back); every
      EMU-2-pinned field present in the served versions — **no client code
      change**; both families stay NOT client-mapped — no fixture duty,
      corpus-invariant list untouched; REQUIREMENTS.md rows that cited the EMU
      pins now cite real mirror files; anchors re-verified: bmcweb `63a18f4`
      (API HEAD), mockup `23d21f9a` (API HEAD of main), DSP0266 1.25.0,
      schema index 200).**

- [x] **DOCS-25** Mirror the **SecureBoot** family the EMU run pinned live
      (EMU 57→60, 2026-10-24) — the external corpus has no schema for
      `#SecureBoot.v1_1_1.SecureBoot` (the system boot-integrity read surface:
      SecureBootEnable/CurrentBoot/Mode + `#SecureBoot.ResetKeys` with
      `ResetKeysType@Redfish.AllowableValues`) or for the
      `#SecureBootDatabaseCollection` / `#SecureBootDatabase.v1_0_2` types
      (the 8-member PK/KEK/db/dbx + defaults database surface). Mirror the
      **mockup-served** versions plus the **newest** published versions plus
      the collection type (the DOCS-12/13/19/20/21/23/24 "newest + served"
      pair precedent) into `documentations/external/redfish/schemas/v1/`
      only — SecureBoot stays NOT client-mapped (no fixture duty; the
      corpus-invariant family list unchanged; the REQUIREMENTS.md trace rows
      for the EMU pins cite the live pin + DOCS-25 until then). Source:
      `https://redfish.dmtf.org/schemas/v1/SecureBoot.json` (+
      `SecureBootDatabase.json`). Keep inside the DOCS-6 budget.
      **Done (run 2026-10-24, 7 files / 52,544 bytes, inside DOCS-6; SHA-256s
      + manifest rows verified; served `SecureBoot.v1_1_1` + newest
      `SecureBoot.v1_2_1` (adds only `SecureBootDesiredMode`, additive),
      served `SecureBootDatabase.v1_0_2` + newest `SecureBootDatabase.v1_0_3`
      (property no-op), both aggregators + `SecureBootDatabaseCollection`;
      served-version `ResetKeysType` enums verified to match the EMU pin
      exactly (SecureBoot: ResetAllKeysToDefault/DeleteAllKeys/DeletePK; PK
      database: no DeletePK — the per-resource nuance is a schema fact, not a
      mockup quirk); REQUIREMENTS.md SecureBoot rows now cite real mirror
      files; both families stay NOT client-mapped — no fixture duty, the
      corpus-invariant family list unchanged; anchors re-verified: bmcweb
      `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200).**

- [x] **DOCS-26** Mirror the **Control** family the EMU run pinned live
      (EMU 60→63, 2026-10-24) — the external corpus has no schema for
      `#Control.v1_5_0.Control` (the modern chassis control surface:
      PowerLimit SetPoint/AllowableMax/Min + `Sensor` DataSourceUri wiring
      into the Sensors collection + CPU1Freq frequency range — the #006/#019/
      #022 power-capping read + the second live PATCH pin on SetPoint with
      the AllowableMin/Max pre-validation rule). Mirror the **mockup-served**
      `Control.v1_5_0.json` plus the **newest** `Control.v1_8_1.json` plus
      the aggregator + `ControlCollection.json` (the DOCS-12/13/19/20/21/23/24
      "newest + served" pair precedent) into
      `documentations/external/redfish/schemas/v1/` only — Control stays NOT
      client-mapped (no fixture duty; the corpus-invariant family list
      unchanged). Source: `https://redfish.dmtf.org/schemas/v1/Control.json`
      (+ `ControlCollection.json`). Keep inside the DOCS-6 budget.
      **Done (run 2026-10-24, 4 files / 129,851 bytes, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit additive-only —
      `Control.v1_5_0`→`v1_8_1` adds `SetPointError` (readonly, v1_7_0); every
      EMU-2-pinned field present in the served version — **no client code
      change**; Control stays NOT client-mapped — no fixture duty,
      corpus-invariant list untouched; REQUIREMENTS.md Control rows now cite
      real mirror files; anchors re-verified: bmcweb `63a18f4`, mockup
      `23d21f9a`, DSP0266 1.25.0, schema index 200 — the corpus mirror queue
      is now EMPTY)**;
      **UPDATED 2026-10-25 (EMULATOR run): Control became client-mapped** —
      the #022/#016 SetPoint pre-validation rule is now code
      (`ControlResource.validateSetPoint`), so the served `Control.v1_5_0.json`
      was copied into `test/fixtures/redfish/schemas/` (byte-identical SHA-256
      `de1614b0…`, 47,414 B) and `Control` was added to the emulator
      corpus-invariant family list (the DOCS-19/20/21 fixture invariant now
      covers it); the external corpus pair (served + newest) already existed
      from DOCS-26 — no new downloads this run.

- [x] **DOCS-27** Corpus freshness audit (the DOCS-22 precedent, now covering
      **38 families**): extract the newest published version per family from
      the live DMTF schema index and byte-verify every mirrored schema file,
      registry, index page, and PDF; fix any provenance drift so every
      manifest SHA is truthful. (run 2026-10-25 — **ZERO version advances**:
      all 7,167 index entries compared, newest per family unchanged for all 38
      mirrored families; **120/120 mirrored schema files byte-identical** to
      re-downloaded live copies; registries (`Base.1.5.0` +
      `Base.1.24.0`), index page, and the DSP0266 1.25.0 PDF all
      byte-identical; **no new downloads, no corpus refresh, no client code
      change**; anchors re-verified: bmcweb `63a18f4` (still HEAD), mockup
      `23d21f9a` (still HEAD), DSP0266 1.25.0 (200), schema index 200; **one
      provenance fix** — the manifest row for `redfish/mockup/
      README-mockup-server.md` recorded the upstream SHA-256 (`b3af2ff3…`,
      7,318 B) but the committed blob is the DOCS-1 normalised copy
      (trailing whitespace stripped on the `cert = ` / `key = ` lines, 2
      bytes; on-disk `0d79a165…`, 7,316 B) — the manifest claimed a hash the
      repo did not contain; the row now records the actual committed SHA with
      an explicit byte-identical-apart-from-whitespace note (restoring the
      trailing whitespace would fail `git diff --check`); the 33-family
      emulator corpus-invariant list untouched — no family became
      client-mapped)

- [x] **DOCS-28** Mirror the **Heater** family pair the EMU run pinned live
      (EMU 64→66, 2026-10-25) — the external corpus has no schema for
      `#Heater.v1_0_1.Heater` (the modern thermal-heater read surface:
      PhysicalContext/Manufacturer/Model/SerialNumber/HotPluggable/
      LocationIndicatorActive/Status + `Links.Processors` + `Metrics` link)
      or for `#HeaterMetrics.v1_0_1.HeaterMetrics` (pre-power-on/runtime
      heating seconds, PowerWatts.Reading, TemperatureReadingsCelsius +
      the advertised `#HeaterMetrics.ResetMetrics` action — a no-`/Actions/`-
      segment candidate, never a contract). Mirror the **mockup-served**
      versions (`Heater.v1_0_1` + `HeaterMetrics.v1_0_1`) plus the **newest**
      published versions (`Heater.v1_0_2` + `HeaterMetrics.v1_0_2`, verified
      on the live schema index 2026-10-25) plus the aggregators +
      `HeaterCollection.json` (the DOCS-12/13/19/20/21/23/24/25/26 "newest +
      served" pair precedent) into `documentations/external/redfish/schemas/
      v1/` only — Heaters stays NOT client-mapped (no fixture duty; the
      corpus-invariant family list unchanged). Source:
      `https://redfish.dmtf.org/schemas/v1/Heater.json` (+
      `HeaterMetrics.json`, `HeaterCollection.json`). Keep inside the DOCS-6
      budget. (run 2026-10-25, 7 files / 60,045 bytes, inside DOCS-6;
      SHA-256s + manifest rows verified; delta audit: **v1_0_1 → v1_0_2 is a
      property no-op for both families** (26 diff lines each — `$id`/
      copyright/backtick-quoted descriptions/`language`/title only), the
      emulator-pinned contract holds — no client code change; both families
      stay NOT client-mapped — no fixture duty, corpus-invariant list
      untouched; `v1_0_3` probes 404 — v1_0_2 is current; REQUIREMENTS.md
      DOCS-28 trace table cites the real mirror files; anchors re-verified:
      bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200;
      **the corpus mirror queue is now EMPTY**)

- [x] **DOCS-29** Fold the EMU 66→68 (2026-10-25) query pins into the
      DOCS-15 §7.3.2 audit table so the #018 design decisions have real trace
      rows: (1) the `$expand=.($levels=1)` shape is now pinned on **all
      three** top-level collections the #018 pass walks (Systems + Chassis +
      Managers inline full member bodies via the map-form
      `getJson(path, query:)`, incl. the manager-level reset allow-list
      `[ForceRestart, GracefulRestart]` visible through the expanded Manager
      payload — the #022/#016 conflation guard on the inlined shape); (2) the
      **`$levels=2` depth bound is pinned** — the mockup does NOT recurse,
      nested `Links` stay bare `@odata.id` refs, so the pass must follow
      cross-resource URIs explicitly for deeper hops (DSP0266 §7.3.2
      depth-cap behaviour). Also re-verified every upstream anchor this run:
      bmcweb `63a18f4` (still HEAD via GitHub API), mockup `23d21f9a` (still
      HEAD via GitHub API), DSP0266 1.25.0 (200 on the working
      `www.dmtf.org` URL), schema index 200 and **byte-identical** to the
      mirrored `v1-index.html` (SHA-256 `e5a2979727a7fc030fce29b8d7d2be2301f4
      507df03ed76e2aef48f8dc9c0b86`, 3,448,133 B) → **no corpus refresh
      needed, DOCS-27's ZERO version advances still hold**. (run
      2026-10-25, REQUIREMENTS.md DOCS-15 table + bottom line + Last-audited
      header updated; UI-2 increment landed separately — firmware
      `_ServiceSummary` merged semantics + no dangling loading label, +2
      widget tests)

- [x] **DOCS-30** Mirror the **EMU 71→75 branch-pinned families** the
      corpus-invariant crawl visits but the external corpus had **no schema
      at all** for: `CertificateService` (`v1_0_4` served + `v1_2_2` newest —
      the GenerateCSR/ReplaceCertificate action targets + the
      CertificateLocations link behind the EMU 71 ActionInfo pins),
      `CertificateLocations` (`v1_0_3` served + `v1_0_4` newest — the
      three-certificate-store `Links.Certificates` pin list),
      `Certificate` (`v1_8_1` served + `v1_11_0` newest — the store members
      the Rekey/GenerateCSR pins type; `v1_11_0` adds `Password`/`Status` —
      a #015/#026 never-read-back note),
      `KeyService` (`v1_0_0` served + `v1_0_1` newest — the NVMeoFSecrets +
      NVMeoFKeyPolicies links), `KeyPolicy` (`v1_0_0` served + `v1_0_1`
      newest — the NVMeoF allow-list surface, the #022-style read-only shape),
      `Key` (`v1_4_0` served + `v1_4_1` newest — the NVMeoFSecrets members;
      the suite pins collection-metadata only, never the `KeyString` body),
      `ComponentIntegrity` (`v1_2_2` served + `v1_5_0` newest — the
      SPDM/TPM/USB member shapes incl. the disabled USB member). Mirror the
      **mockup-served** versions plus the **newest** published versions plus
      the aggregators + collection types where they exist
      (`CertificateCollection`, `KeyPolicyCollection`, `KeyCollection`,
      `ComponentIntegrityCollection`) into
      `documentations/external/redfish/schemas/v1/` only — all seven families
      stay **NOT client-mapped** (no fixture duty; the corpus-invariant family
      list unchanged; the DOCS-24/25/26/28 "newest + served" pair precedent).
      Source: `https://redfish.dmtf.org/schemas/v1/<Name>.json`. Keep inside
      the DOCS-6 budget. (run 2026-10-25, 25 files / 446,257 bytes, inside
      DOCS-6; SHA-256s + manifest rows verified; delta audit **additive-only**
      — CertificateService.v1_2_2 adds readonly certificate-enrollment
      surface, Certificate.v1_11_0 adds `Password`/`Status` (#015/#026 note),
      the other five newest versions are property no-ops — **no client code
      change**; all seven families stay NOT client-mapped — no fixture duty,
      corpus-invariant list untouched; REQUIREMENTS.md DOCS-30 trace table
      cites the real mirror files; every `@odata.type` the pinned mockup
      publishes now has a served-version schema in the external corpus;
      anchors re-verified: bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266
      1.25.0, schema index 200; **the corpus mirror queue is now EMPTY**)

- [x] **DOCS-31** Close the corpus gap the extended invariant exposed: the
      corpus-invariant **live crawl now asserts EVERY published versioned
      `@odata.type` has a served-version schema in the external corpus** — not
      only the client-mapped families (the DOCS-19/20/21 fixture invariant
      stays, and every type now also checks
      `documentations/external/redfish/schemas/v1/`). The extension
      immediately proved DOCS-30's "corpus mirror queue EMPTY" was
      **overstated**: 17 families the pinned mockup publishes had NO schema at
      all in the external corpus — `AccelerationFunction` (served v1_0_4 +
      newest v1_0_5, no-op), `Assembly` (v1_5_0 + v1_6_1, no-op), `Memory`
      (v1_19_0 + v1_24_0, +4 props), `Processor` (v1_19_0 + v1_24_0, +4),
      `Port` (v1_11_0 + v1_20_0, +13), `ExternalAccountProvider`
      (v1_7_1 + v1_9_0, no-op), `GraphicsController` (v1_0_1 + v1_0_2,
      no-op), `HostInterface` (v1_3_1 + v1_4_0, no-op),
      `MessageRegistryFile` (v1_1_4 + v1_1_5, no-op), `OutboundConnection`
      (v1_0_1 + v1_0_3, no-op), `ProcessorMetrics` (v1_6_3 + v1_7_1, +1),
      `SecurityPolicy` (v1_0_1 + v1_1_0, +1), `SerialInterface`
      (v1_2_0 + v1_3_0, +1), `Signature` (v1_0_2 + v1_0_3, no-op),
      `SimpleStorage` (v1_3_1 + v1_3_2, no-op), `TrustedComponent`
      (v1_3_0 + v1_5_0, +1), `USBController` (v1_0_0 + v1_0_1, no-op) —
      mirrored the "newest + served" pair + aggregators + the 14 collection
      types that exist (**65 files / 1,403,838 bytes, inside DOCS-6**) into
      `documentations/external/redfish/schemas/v1/` only; all 17 stay **NOT
      client-mapped** (no fixture duty, corpus-invariant family list
      unchanged); property-delta audit **additive-only** across all 17 — **no
      client code change**; the extended invariant is a runnable emulator
      check (78-test suite green on `23d21f9a`); REQUIREMENTS.md header +
      DOCS-31 trace table cite the real mirror files; anchors re-verified:
      bmcweb `63a18f4`, mockup `23d21f9a`, DSP0266 1.25.0, schema index 200;
      **corpus mirror queue EMPTY for every published type**)

- [x] **DOCS-16** Audit the DSP0266 clause citations in `REQUIREMENTS.md`
      against the **mirrored `DSP0266_1.25.0.pdf`** (the rows added across
      DOCS-3/4/5/10/13 cited an older spec layout) and correct every stale
      clause; pin the §9.9 "Payload annotations" contract with unit tests.
      (run 2026-10-23 23:40 — stale→correct map in REQUIREMENTS.md
      "DOCS-16": `§8.3 Service Root` → `§7.2.3`; `§8.4 ComputerSystem` /
      `§8.10 Thermal` / `§8.14 Software inventory` → versioned schemas +
      `§9` data model (DSP0266 does not enumerate per-resource property
      lists); `§9.2 HTTP protocol` (ETag) → `§6.5`+`§7.2`; `§12.2 Actions`
      → `§9.6.14`+`§7.11`; `§12.3 Basic auth` → `§13.3.3`; `§12.4 Sessions`
      /timeout → `§13.3.4`/`§13.3.4.3`; `§12.7 Error responses` → `§8.6`;
      `§9.7 Firmware update` → `§12.7`; clauses already correct left
      unchanged (`§12.1` Eventing, `§12.2` async ops, `§7.3` queries,
      `§9.6.11/12`, `§9.6.2`, `§9.1`); `feature_rules.dart` doc comment
      fixed (`§9.3` → `§9.9`); +2 unit tests pin the §9.9.2
      `@Redfish.AllowableValues` list parse and the §9.9.1
      unrecognized-annotation tolerance; anchors re-verified 23:32 UTC
      (bmcweb `fbb307a`, mockup `23d21f9a`, DSP0266 1.25.0 — the
      `redfish.dmtf.org` PDF path 404s, hub links `www.dmtf.org`; schema
      index 200); no corpus refresh needed)

## P1 — emulator and integration tests

- [x] **EMU-1** Stand up the official DMTF Redfish-Mockup-Server over HTTPS using
      `test/fixtures/redfish/dmtf_mockup` (public-rackmount1) and a generated
      self-signed cert. Health-check `GET /redfish/v1/` before tests.
      (run 2026-10-22, commit 81dfb8f — pin `23d21f9a`, script
      `tool/emulator/run_tests.sh`, port 8443)
- [x] **EMU-2** Add end-to-end tests under `test_integration/emulator/` (outside
      `test/` so plain `flutter test` never needs the emulator). Cover discovery,
      service-root traversal, systems, sensors, firmware inventory, and KVM
      capability detection.
      (run 2026-10-22, commit 81dfb8f — 11 tests in
      `test_integration/emulator/emulator_suite_test.dart`; skips without
      `REDFISH_EMULATOR_URL`; extended 2026-10-22 → 13 tests (systems detail +
      HttpPushUri) → 16 tests (SessionService URI, Manager detail + allow-list,
      Chassis detail) → 21 tests (session lifecycle #015/#017, SessionTimeout,
      TaskService, EventService contracts) → 24 tests (ProtocolFeaturesSupported
      #018, Accounts #015/#026, push apply-time #008/#020 — 2026-10-23) → 27
      tests (Sensors collection #007/#019, system Reset allow-list #022/#016,
      SimpleUpdateActionInfo #008/#020 — 2026-10-23 03:02) → **30 tests
      (OverviewService end-to-end hydration #006 + LogService/LogEntry
      collection contract incl. ClearLog + `@odata.nextLink` pagination —
      2026-10-23 06:10) → 32 tests (Task resource contract: TaskState/
      TaskStatus/Start-EndTime/Messages incl. absent PercentComplete, + TaskService
      CompletedTaskOverWritePolicy/LifeCycle fields — 2026-10-23 09:14) → **34
      tests (Manager NetworkProtocol + EthernetInterfaces surface: KVMIP/SSH/
      HTTPS endpoints for the #009/#021 console renderer + NIC MAC/IP/VLAN —
      2026-10-23 11:39) → **36 tests (account-service auth surface #015/#026:
      AccountService lockout/password-policy + Roles link, Roles collection +
      AssignedPrivileges/OemPrivileges, ManagerAccount detail incl.
      AccountTypes/PasswordChangeRequired/Locked/Links.Role/ChangePassword +
      Password masked on the wire — 2026-10-23 13:58) → **37 tests (live
      `$expand=.($levels=1)` round-trip pin: Systems collection inlines full
      member bodies — Model/PowerState/Actions.Reset allow-list incl. Nmi +
      Processor/MemorySummary — the N+1-avoiding discovery shape #018 can
      rely on — 2026-10-23 17:07** → **39 tests (query-behavior contract
      pinned 2026-10-23 18:36: `$expand=*` (ExpandAll) also serves inlined
      full member bodies — same fields as `$levels=1` — while `$filter`/
      `$select` are advertised but NOT applied (Roles collection unfiltered
      for `$filter=Id eq 'NOPE'`, full system body for `$select=Model`) — the
      #018 discovery pass must filter/select client-side and rely only on
      `$expand` for payload shaping)** → **40 tests (map-form
      `getJson(path, query:)` `$expand` round-trip pinned 2026-10-23 22:45:
      the 19:25 unit test proved the query map forwards to the wire; the live
      emulator now proves the map-form `$expand=.($levels=1)` on the Systems
      collection returns the SAME inlined full member bodies as the URL-string
      pins — Model/PowerState/Reset allow-list incl. Nmi/ProcessorSummary —
      the exact call shape a #018 discovery pass will make)** → **41 tests
      (MessageRegistry contract pinned 2026-10-24 02:15: service root
      advertises `Registries` -> `MessageRegistryFileCollection`
      (Base.1.5.0) -> `Location[0].Uri` resolves to the `#MessageRegistry`
      JSON defining the 60 Base.* message templates (Message/Severity/
      NumberOfArgs) behind `RedfishError.code`/`firstMessage` — the DSP0266
      §8.6/§11.4 error surface for the #014 model; also re-verified the reset
      action returns 204 No Content with NO task-monitor Location header and
      the 404 path closes the connection without a body — the
      GET-on-monitor/error-envelope seams stay unit-level)** → **43 tests
      (Sessions collection + Session resource contract pinned 2026-10-24 04:01:
      the collection is enumerable from the discovered SessionService URI —
      members are session resources, never the collection; the pre-seeded
      `#Session.v1_7_1` (Administrator) carries Id/Name/Description/UserName
      and NO Password, while a POST-created session body ECHOES the login
      Password and lacks @odata.type/SessionType — the #015/#026 security rule:
      AuthManager persists the token/location from the create RESPONSE HEADERS,
      never reads session-resource bodies for secrets (DSP0266 §13.3.4 Session
      has no Password property); also pinned: POST Reset with an invalid
      `ResetType` returns 204 exactly like a valid one — the mockup does not
      validate the body, so the `ResetTypeInvalid` 400 path stays unit-level
      (#014/#022)**) → **45 tests (UpdateService action surface
      (#008/#020) pinned 2026-10-24: `FirmwareService.startSimpleUpdate`
      live round-trip — the mockup accepts ANY SimpleUpdate body and answers
      204 with NO task-monitor `Location`, so `UpdateTask` carries null
      taskUri/retryAfterSeconds (the 202-with-Location monitor path stays
      unit-level); negative pin — the advertised `HttpPushUri` (`/FWUpdate`)
      is NOT implemented: POSTing a binary upload body fails with 400 and an
      EMPTY body (no `@Message.ExtendedInfo` envelope; connection closed;
      GET /FWUpdate 404s), so the #020 binary-push flow stays unit-level and
      the client normalizes it as `RedfishException` HTTP 400 with no error
      code)** → **48 tests (chassis metrics + subsystem contracts pinned
      2026-10-24: `EnvironmentMetrics.v1_3_1` aggregate telemetry —
      TemperatureCelsius.Reading 39 + PowerWatts.Reading 374 +
      PowerLimitWatts.SetPoint 500 + FanSpeedsPercent[2] all with
      `DataSourceUri` links resolving into the Sensors collection; the
      `ThermalSubsystem.v1_3_1` surface — Fans collection (4 members) +
      FanRedundancy NPlusM (MinNeededInGroup 1 / MaxSupportedInGroup 2) +
      `ThermalMetrics.v1_3_1` TemperatureSummaryCelsius
      (Intake/Exhaust/Internal/Ambient with DataSourceUri → Sensors); the
      `PowerSubsystem.v1_1_1` surface — PowerSupplies collection (2) +
      `PowerSupply.v1_5_3` Bay1 detail (Model RKS-440DC /
      FirmwareVersion 1.00 / LineInputStatus Normal / `#PowerSupply.Reset`
      target / Metrics link) + legacy `/Chassis/1U/Power` embedded PSU
      documenting `Status.Health == 'Warning'` vs the overview rollup
      reading ComputerSystem/Chassis Status (#006/#019))** → **50 tests
      (Batteries + action round-trips pinned 2026-10-24: the
      `#BatteryCollection` → `#Battery.v1_2_2` Module1 detail —
      Model/Manufacturer/FirmwareVersion/Status/ChargeState/CapacityRated+
      ActualWattHours/MaxDischargeRateAmps/StateOfHealthPercent with
      `DataSourceUri` → Sensors/Battery1StateOfHealth resolving live, plus
      the `#Battery.SelfTest`/`#Battery.Calibrate` action targets — and the
      `#BatteryMetrics.v1_0_3` electrical telemetry: InputVoltage/
      OutputVoltages/InputCurrentAmps/OutputCurrentAmps/StoredEnergyWattHours/
      TemperatureCelsius/ChargePercent/CellVoltages[8] with `DataSourceUri`
      links into the Sensors collection (the wired-surface shape #007/#019
      can follow battery telemetry to raw sensors); action round-trip
      contract: `#Battery.SelfTest`/`#Battery.Calibrate` POST → 204 (the
      mockup's `/Actions/` framework serves them) while the **advertised
      `#PowerSupply.Reset` target is NOT implemented** — its URI has no
      `/Actions/` segment, so POST returns 404 with an empty body (the
      #022/#006 rule: treat advertised action targets as candidates, never
      contracts, on this fixture)** → **52 tests
      (corpus invariant + EventDestination detail pinned 2026-10-24: (1) a
      live published-types crawl from the service root follows every relative
      `@odata.id` + `@Redfish.ActionInfo` link (excluding `/Actions/` POST
      targets) and asserts **every published `@odata.type` for a client-mapped
      family has its served-version schema in `test/fixtures/redfish/schemas/`**
      — the DOCS-19/20/21 invariant as a runnable check (33 client-mapped
      families; crawl reaches >50 published types; green because the mirror
      work closed every served-version gap); (2) the four
      `EventService/Subscriptions` members pin the `#EventDestination.v1_14_0`
      detail — Redfish / SNMPv3 (HMAC_SHA96 + CFB128_AES128, key material
      null) / SMTP-OEM / SyslogTCP (SyslogFilters LogFacilities +
      LowestSeverity) — the DOCS-7 bed for #019)** → **53 tests
      (Bios `@Redfish.Settings` ETag surface pinned live 2026-10-24 16:30:
      `/Systems/437XR1138R2/Bios` carries the DSP0266 §9.9 `@Redfish.Settings`
      payload annotation with a real settings-object **ETag**
      (`9234ac83b9700123cc32` — the only ETag-ish token this fixture serves;
      header-level `@odata.etag`/HTTP ETags are absent, so the optimistic-
      concurrency token a #016 PATCH/If-Match flow sends is the settings-
      object ETag); pending-settings resource (`Bios/Settings`,
      `#Bios.v1_2_2.Bios`, attribute diff EmbeddedSata Raid→Ahci +
      ProcTurboMode Enabled→Disabled), `Messages[0]`
      `Base.1.0.SettingsFailed` + RelatedProperties,
      `#Bios.ResetBios` POST → 204 (mockup `/Actions/` framework),
      `#Bios.ChangePassword` advertised-only (never round-tripped with
      secrets))** → **57 tests
      (Boot override + live PATCH round-trip + discovery Links graph +
      VirtualMedia pinned 2026-10-24 18:xx: (1) `#ComputerSystem.Boot`
      publishes `BootSourceOverrideEnabled/Mode/Target` +
      `BootSourceOverrideTarget@Redfish.AllowableValues` (10 values) +
      `UefiTargetBootSourceOverride` — the annotation-form allow-list rule
      (#022/#016) applies to boot control; (2) the **FIRST live PATCH pin** —
      `RedfishClient.patchJson` (new #016 transport, 3 unit tests) PATCHes
      `Boot.BootSourceOverrideEnabled: Disabled` → 204 and the change
      **persists** (GET confirms; in-memory only — on-disk fixture
      byte-identical); negative: the mockup applies ANY PATCH body value
      unvalidated (`IndicatorLED: "Bogus"` 204s AND persists) so the client
      must pre-validate against AllowableValues and the 400 +
      `@Message.ExtendedInfo` validation-failure path stays unit-level;
      (3) discovery graph — Systems→Chassis→Manager `Links` traversal
      resolves all three hops (System.Links.Chassis/ManagedBy,
      Chassis.Links.ComputerSystems/ManagedBy/ManagersInChassis,
      Manager.Links.ManagerForServers/ManagerForChassis/ManagerInChassis +
      ManagerType/FirmwareVersion/Model) for #018/#006; (4) VirtualMedia
      read surface (`#VirtualMedia.v1_6_3`, 2 members, Inserted/
      WriteProtected/MediaTypes/ConnectedVia) — boot-media UX input for
      #028/#022; fixture publishes NO InsertMedia/EjectMedia action targets
      (advertised-as-candidate rule); VirtualMedia stays NOT client-mapped —
      no fixture-schema duty)** → **60 tests
      (SecureBoot boot-integrity surface + database + If-Match boundary
      pinned 2026-10-24 20:xx: (1) `#SecureBoot.v1_1_1.SecureBoot` — the
      system secure-boot read state (SecureBootEnable false /
      SecureBootCurrentBoot Disabled / SecureBootMode UserMode) + the
      `#SecureBoot.ResetKeys` action with `ResetKeysType@Redfish.
      AllowableValues` (ResetAllKeysToDefault/DeleteAllKeys/DeletePK — the
      annotation-form allow-list rule #022/#016 applied to a SECOND system
      action family; POST → 204 via the `/Actions/` framework; a bogus
      ResetKeysType ALSO 204s — the mockup never validates action bodies, so
      the 400 path stays unit-level); (2) the `#SecureBootDatabaseCollection`
      enumerates 8 databases (PK/KEK/db/dbx + defaults) and each
      `#SecureBootDatabase.v1_0_2` resource carries its OWN
      `#SecureBootDatabase.ResetKeys` with a *smaller* per-resource
      allow-list (PK: ResetAllKeysToDefault/DeleteAllKeys — no DeletePK) +
      a Certificates link — a key-reset UI must read the database-level
      list; (3) **If-Match boundary closed (#016)**: a PATCH with a stale
      `If-Match: "bogus-stale-etag"` header is answered 204 AND persists —
      the mockup never evaluates preconditions (no resource-level
      `@odata.etag`/HTTP ETag; only the settings-object ETag
      `9234ac83b9700123cc32` exists), so 412 enforcement stays unit-level and
      the client must send the settings-object ETag itself; SecureBoot /
      SecureBootDatabase stay NOT client-mapped — corpus mirror duty recorded
      as DOCS-25)** → **63 tests
      (chassis Controls surface pinned live 2026-10-24 22:xx:
      `#ControlCollection` enumerates PowerLimit + CPU1Freq; each
      `#Control.v1_5_0.Control` publishes ControlType/ControlMode/
      AllowableMax/Min (PowerLimit: SetPoint 500 W + Allowable 1000/150 +
      `Sensor` excerpt Reading 374 + DataSourceUri → Sensors/TotalPower — the
      wiring a #006/#019 power-capping flow follows; CPU1Freq: Frequency,
      SettingMin/Max 2000/2400 Hz + Allowable 1500/3700); the **second live
      PATCH pin (#016)** — PATCHing `SetPoint: 600` on PowerLimit answers 204
      AND persists (in-memory; on-disk fixture byte-identical), while
      `SetPoint: 9999` is ALSO applied unvalidated — the #022/#016 rule: the
      client must pre-validate Control SetPoints against AllowableMin/Max;
      Control stays NOT client-mapped — no fixture-schema duty, corpus mirror
      duty recorded as DOCS-26)** → **64 tests
      (Bios/Settings PATCH round-trip pinned live 2026-10-24 23:xx — the
      THIRD live PATCH pin (#016) and the first against the pending-settings
      object (#028 input): PATCH `/Bios/Settings` (the `@Redfish.Settings`
      SettingsObject carrying the only ETag the mockup serves —
      `9234ac83b9700123cc32`, EMU 53) with an `Attributes` subset
      (EmbeddedSata Uefi) answers 204 AND persists (in-memory; on-disk
      fixture byte-identical); the mockup IGNORES the If-Match precondition
      on the settings object too — a stale etag still 204s AND persists, so
      412 enforcement stays unit-level and the #016/#028 client must send the
      settings-object ETag itself; restored in `finally`)** → **66 tests
      (ThermalSubsystem Heaters surface + Manager.Reset live round-trip
      pinned 2026-10-25: (1) `#HeaterCollection` → `#Heater.v1_0_1.Heater`
      CPU1Heater detail — PhysicalContext CPU / Manufacturer Contoso Heaters /
      Model CPUHeater / SerialNumber SNDHM0123456789 / HotPluggable /
      LocationIndicatorActive / Status OK + `Links.Processors[0]` resolving
      live to `#Processor.v1_19_0` CPU1 + Metrics link → `#HeaterMetrics.
      v1_0_1.HeaterMetrics` — PrePowerOnHeatingTimeSeconds 600 /
      RuntimeHeatingTimeSeconds 3600 / PowerWatts.Reading 200.3 /
      TemperatureReadingsCelsius[1] (DeviceName 'Heater Average Temperature',
      Reading 2.5) — the thermal-UI surface next to the fan subsystem; the
      advertised `#HeaterMetrics.ResetMetrics` target has NO `/Actions/`
      segment → POST **404 with an empty body** (probed live; the
      PowerSupply.Reset advertised-as-candidate rule, #022/#006 — never a
      contract on this fixture; corpus mirror duty recorded as DOCS-28);
      (2) `#Manager.Reset` **live POST round-trip** — the target IS under
      `/Actions/` so the framework serves it: POST GracefulRestart → 204
      (empty body, no task-monitor Location) AND a bogus `ResetType` also
      204s — the mockup never validates action bodies, so the 400
      `ResetTypeInvalid` path stays unit-level and the #022/#016 client must
      pre-validate against the manager's OWN allow-list
      (ForceRestart/GracefulRestart, never the system list))** → **68 tests
      (generalized `$expand` pins for #018 2026-10-25: (1) the SAME
      `$expand=.($levels=1)` map-form query, applied to `/redfish/v1/Chassis`
      AND `/redfish/v1/Managers`, inlines FULL member bodies — Chassis
      identity/ChassisType/Status/IndicatorLED/Links.ComputerSystems/
      ManagedBy and Manager ManagerType/FirmwareVersion/Model/Links.
      ManagerForServers/ManagerInChassis + the **manager-level reset
      allow-list (`#Manager.Reset` == exactly `[ForceRestart,
      GracefulRestart]`) visible through the expanded payload** — the #022/
      #016 rule that the gate never conflates the manager list with the
      system list now also enforced on the inlined shape; (2) `$levels=2` on
      Systems does NOT recurse beyond one level — the member's own
      `Links.Chassis` stays a bare `@odata.id` ref (no inlined
      ChassisType/Status), so the #018 discovery pass must follow
      cross-resource URIs explicitly for deeper hops (DSP0266 §7.3.2
      depth-cap behaviour pinned live))** → **69 tests
      (two remaining negative facts pinned as live tests 2026-10-25: (1)
      **bad login still mints a session** — the run_tests.sh profile starts
      the mockup WITHOUT `-u` (no auth enforcement, a fact recorded since
      2026-10-23 but never pinned), so POST `Sessions` with a wrong password
      returns 204 + X-Auth-Token + Location naming a session resource (never
      the collection) — the client's 401 bad-login error mapping is provably
      unit-level (#015/#026) and token presence proves nothing about credential
      validity on this fixture; (2) **`MultipartHttpPushUri` is absent** — the
      DMTF fixture serves only `HttpPushUri` (`/FWUpdate`), unlike bmcweb which
      adds the multipart variant (DOCS-4/9), so
      `UpdateServiceInfo.multipartHttpPushUri` is null on this fixture and the
      #008/#020 upload flow must pick the single-push URI when that is all the
      service advertises))** → **71 tests
      (ActionInfo resource contract pinned live 2026-10-25: the two
      `CertificateService` actions (`#CertificateService.GenerateCSR` +
      `#CertificateService.ReplaceCertificate`) each advertise an
      `@Redfish.ActionInfo` link that resolves to a GET-able
      `#ActionInfo.v1_4_1.ActionInfo` resource — `GenerateCSRActionInfo`
      publishes 13 `Parameters[]` entries each with `Name`/`Required`/`DataType`
      and per-parameter `AllowableValues` on `KeyPairAlgorithm`
      (`TPM_ALG_RSA`/`TPM_ALG_ECDSA`), `KeyCurveId` (3 curves), `KeyUsage`
      (14 values); `ReplaceCertificateActionInfo` publishes `CertificateType`
      `AllowableValues ['PEM']` — the exact `Parameters[].AllowableValues`
      shape a bmcweb `ResetActionInfo`-style crawl produces on OpenBMC (#022/
      #016; DOCS-4/13); the `ResetActionInfo` resource itself is still absent
      on this fixture, so the OpenBMC allow-list-source crawl stays a code
      task; REQUIREMENTS.md ActionInfo row updated; EMU 69→71)**
      → **75 tests
      (last un-pinned service-root branches pinned live 2026-10-25: the read
      surfaces of the final three branches the corpus crawl visits —
      `CertificateService.CertificateLocations`
      (`#CertificateLocations.v1_0_3`) links the three certificate stores
      (HTTPS server cert / UpdateService client cert / VirtualMedia cert);
      `KeyService` (`#KeyService.v1_0_0`) — `NVMeoFKeyPolicies/0`
      (`#KeyPolicy.v1_0_0`) NVMeoF allow-lists
      (SecurityTransportAllowList/CipherSuiteAllowList/
      SecurityProtocolAllowList/DHGroupAllowList/SecureHashAllowList, the
      #022-style read-only allow-list shape) and `NVMeoFSecrets`
      (`#KeyCollection.KeyCollection`, 2 members) pinned **collection-
      metadata only** — the members carry real `KeyString` key material, so
      the suite asserts the surface exists + member `@odata.id` list + count
      WITHOUT fetching a member body (the #015/#026 never-read-secrets-back
      rule stated as a scope boundary in the test); `ComponentIntegrity`
      collection (4 members: SS-SPDM-0/1, USB-Integrity, TPM-0) +
      `#ComponentIntegrity.v1_2_2` SPDM (enabled, DMTF MeasurementSet with
      non-empty digest Measurements), TPM (PCR measurement set), and the
      **disabled** USB member (enabled-state read per member, never assumed)).
      All three families remain NOT client-mapped → no fixture schema duty
      (corpus-invariant unchanged); EMU 71→75)** → **78 tests
      (the last un-pinned ActionInfo families on the fixture pinned live
      2026-10-25, EMU 75→78: (1) `EventService.SubmitTestEventActionInfo`
      — the recurring #022/#016 ActionInfo-*resource* crawl contract applied
      to the #019/DOCS-7 test-event action: `@Redfish.ActionInfo` resolves to
      `#ActionInfo.v1_4_1` with 9 `Parameters[]`, `MessageId` the one
      REQUIRED parameter, `EventType` AllowableValues
      [StatusChange/ResourceUpdated/ResourceAdded/ResourceRemoved/Alert/Other],
      `MessageArgs` DataType StringArray, `EventGroupId` DataType Number; (2)
      `#Certificate.Rekey` `RekeyActionInfo` on the manager HTTPS certificate
      — `KeyPairAlgorithm` REQUIRED + AllowableValues (TPM_ALG_RSA/
      TPM_ALG_ECDSA), `KeyBitLength` optional Number, `KeyCurveId`
      AllowableValues (3 NIST curves) — the fourth ActionInfo family; (3) the
      SAME RekeyActionInfo contract verified consistent across the other two
      certificate stores the CertificateLocations pin lists
      (`UpdateService/ClientCertificates/1`,
      `AccountService/OutboundConnections/1/Certificates/1`) — a
      #022/#016-style crawler can rely on the identical
      Parameters/AllowableValues shape on every store; `ResetActionInfo`
      itself is still absent on this fixture, the OpenBMC
      allow-list-source crawl stays a code task)**
- [~] **EMU-3** Cover auth and power actions where the emulator supports them.
      If an action is unsupported, assert the client's error mapping instead of
      skipping silently.
      (session + basic auth, reset action, 404 mapping done 2026-10-22;
      systems-detail + HttpPushUri tests added 2026-10-22 → 13 emulator tests;
      session lifecycle + logout-target (DELETE session 204 / collection 405) +
      SessionTimeout added 2026-10-22 → 21 tests;
      system-level Reset allow-list (incl. `Nmi`, distinct from the manager
      list) added 2026-10-23 → 27 tests;
      remaining: 403/409/400 extended info paths need a richer emulator — see
      EMU-5: decision is to keep covering error mapping with spec-conformant
      unit fixtures, so EMU-3 is effectively complete; **probed 2026-10-23
      18:36: the mockup without `-u` accepts ANY credentials — `POST Sessions`
      with a wrong password returns 204, so the 401 bad-login error-mapping
      path also stays unit-level (consistent with EMU-5)**;
      **probed 2026-10-24 04:01: the mockup accepts ANY `ResetType` body value
      — `ResetType: "Bogus"` returns 204 like a valid one, so the 400
      `ResetTypeInvalid` path stays unit-level too; the UI must pre-validate
      against the advertised allow-list (it does)**)
- [x] **EMU-4** Add `tool/emulator/run_tests.sh` that starts the server, waits for
      health, runs the integration tests, and always stops the server via `trap`.
      Pin the emulator commit and document it.
      (run 2026-10-22, commit 81dfb8f — verified end-to-end; trap cleanup
      confirmed; pin `23d21f9a` in the script + docs README)
- [x] **EMU-5** Evaluate `DMTF/Redfish-Interface-Emulator` only if the mockup
      server cannot exercise the required dynamic actions. Record the decision.
      (run 2026-10-22 — evaluated `5f51d8a`; **decision: stay on
      Redfish-Mockup-Server**. The richer emulator serves dynamic 400s but its
      error bodies are non-conformant — `{"error":"msg"}` with no `error`
      envelope / `@Message.ExtendedInfo`, and its SessionService 404s. Error
      mapping is covered with spec-conformant unit fixtures instead; rationale
      in REQUIREMENTS.md "EMU-5 decision")
- [x] **EMU-6** Do not loosen production TLS. Use `allowSelfSigned: true` only in
      the test profile; never add an HTTP/plaintext production path.
      (run 2026-10-22 — self-signed cert is `/tmp`-generated test-only;
      `allowSelfSigned` used only in `test_integration/emulator/` profile)

## P1 — confirmed code defects

- [x] **#014** Fix `RedfishError` `@Message.ExtendedInfo` parsing.
      (run 2026-10-22 — `fromJson` self-descends into the DSP0266 `error`
      envelope; `fromResponse` normalizes map bodies; compliant-envelope unit
      tests in `models_test.dart` + `auth_manager_test.dart`; closed)
- [x] **#015** AuthManager base (closed — see `issues/closed/015-auth-manager-fixes.md`).
      **REMAINING FOLLOW-UP (do this as FEATURE work):** wire
      `Session.expiryFromService` into the login/re-auth flow (model helper
      landed DOCS-17; AuthManager wiring still open) + #008 resilience
      (cancel task DELETE /TaskService/Tasks/{id}, 413/401, low-bandwidth
      backoff).
      (bmcweb `AccountService.Oem.OpenBMC.AuthMethods.*` vendor row recorded in
      REQUIREMENTS.md — DOCS-4; emulator asserts the service root advertises a
      discoverable SessionService URI — run 2026-10-22 #017 contract; emulator
      now also pins the full session lifecycle: POST via discovered Sessions
      URI returns X-Auth-Token + Location (session resource, not collection),
      DELETE session 204 vs DELETE collection 405, SessionTimeout=30 published —
      run 2026-10-22; emulator AccountService test added 2026-10-23: Accounts
      collection discoverable + readable with UserName/RoleId, MinPasswordLength
      published — the auth-surface contract #015/#026 reason about; **full
      account-service auth surface pinned 2026-10-23 13:58**: AccountService
      lockout/password-policy fields + Roles link, Roles collection (3
      predefined roles with AssignedPrivileges/OemPrivileges), ManagerAccount
      detail (AccountTypes/PasswordChangeRequired/Locked/Enabled/Links.Role/
      ChangePassword target + Password masked on the wire);
      **Sessions collection + Session resource contract pinned live 2026-10-24
      04:01** — collection enumerable (members = session resources), pre-seeded
      `#Session.v1_7_1` (Administrator, no Password); **security rule pinned:
      POST-created session bodies echo the login `Password` and lack
      `@odata.type`/SessionType — AuthManager persists token/location from the
      create RESPONSE HEADERS and never reads secrets back from session
      resources**)
- [x] **#027** Verify the Flutter toolchain issue is stale; close it with evidence
      if `flutter analyze`/`flutter test` work, otherwise fix it.
      (run 2026-10-22 — closed with evidence: `~/flutter/bin/flutter` on PATH,
      analyze 0 / tests 242 green every run, no orphaned flutter_tester from
      this repo; DEVELOPMENT.md Toolchain documents the setup)
- [x] **#016** PATCH / `If-Match` / `@odata.etag` support.
      (**COMPLETE 2026-10-25 EMU run — closed.** The full chain landed:
      the DSP0266 §6.5.2 `patchJson` partial-update transport (2026-10-24,
      EMU 57→59 first live pin); the If-Match/`@odata.etag` wiring (2026-10-25
      DOCS run — `patchJson(..., etag:)` quotes per RFC7232, `ODataResource.
      etag`, `RedfishException.isPreconditionFailed` 412 classification); the
      `ResetActionInfo` ActionInfo-*resource* crawl (c) + the Control SetPoint
      pre-validation corollary (d) (2026-10-25 EMU runs; `ControlResource.
      validateSetPoint`, fixture + corpus-invariant list); and finally **(b)
      the Boot/IndicatorLED PATCH flow in a service + UI** — `SystemSettings
      Service.setIndicatorLed` (schema-enum pre-validation `Lit`/`Blinking`/
      `Off`, `Unknown` refused) + `setBootOverride` (annotation allow-list +
      `Once`/`Continuous`/`Disabled` pre-validation, never-guess refusal when no
      allow-list advertised) + `BootSettings` model + Controller/providers +
      Overview-view LED ChoiceChips + Boot-override card (capability-gated,
      320/800/1300 no-overflow). +34 unit/widget tests (392 → 426 passed /
      1 skipped); +2 live emulator pins (80 → 82/82: service-level round-trips
      persist through the mockup, unlisted target rejected before the wire).
      REQUIREMENTS.md PATCH row flipped **OK**. The settings-object ETag
      `9234ac83b9700123cc32` remains the only pinable concurrency token on the
      DMTF fixture, so 412 enforcement stays unit-level (documented).)
      (prior progress preserved below:)
      (**PATCH transport landed 2026-10-24 18:xx + live pin**: `RedfishClient.
      patchJson(path, body:, headers:)` — the DSP0266 §6.5.2 partial-update
      transport (204/200 normalized, non-2xx → `RedfishException`) — 3 unit
      tests in `auth_manager_test.dart`; the emulator proves a PATCH on
      `/Systems/437XR1138R2` (`Boot.BootSourceOverrideEnabled: Disabled`)
      round-trips 204 AND persists (in-memory; on-disk fixture
      byte-identical), while the mockup applies ANY body value unvalidated
      (`IndicatorLED: "Bogus"` persists) — the client must pre-validate
      against advertised `AllowableValues` (Boot-override + Reset list now
      both pinned);
      **the If-Match/`@odata.etag` *wiring* landed 2026-10-25 (DOCS run)** —
      the transport-level acceptance criteria are done: `patchJson(..., etag:)`
      sends a properly-quoted `If-Match` (RFC7232 entity-tag grammar; the
      settings-object ETag `9234ac83b9700123cc32` is the only pinable token on
      the fixture, header-level ETags stay unit-level), `ODataResource.etag`
      reads `@odata.etag`, and `RedfishException.isPreconditionFailed`
      classifies 412 (non-retryable — the caller re-fetches instead of
      blind-retrying); +6 unit tests; the 412 negative pin stays unit-level
      because the DMTF mockup IGNORES If-Match (pinned 2026-10-24); remaining:
      **(b) Boot/IndicatorLED PATCH actions in a service + UI** — the
      transport + precondition wiring are in place, a mutation feature (boot
      override / BIOS editor #028) consumes them;
      **(d) the Control SetPoint pre-validation corollary landed 2026-10-25
      (EMU run)** — `ControlResource.validateSetPoint` rejects out-of-bounds
      SetPoints before any PATCH (the EMU 60→63 negative pin: the mockup
      applies `SetPoint: 9999` unvalidated), boundaries inclusive, per-resource
      bounds never leak across controls; Control became client-mapped (served
      schema in the fixture + corpus-invariant list) — +11 unit tests, +1 live
      emulator pin (79 → 80/80);
      **If-Match boundary pinned live 2026-10-24 20:xx (EMU
      59→60)**: a PATCH with a stale `If-Match: "bogus-stale-etag"` header is
      answered 204 AND persists — the mockup never evaluates preconditions
      (no resource-level `@odata.etag`/HTTP ETag; the settings-object ETag
      `9234ac83b9700123cc32` is the only concurrency token it serves), so 412
      enforcement stays unit-level and the #016 client must send the
      settings-object ETag itself;
      (c) ~~the `ResetActionInfo` ActionInfo *resource* crawl~~ **landed
      2026-10-25 (EMU run)** — the engine follows `@Redfish.ActionInfo` links,
      `FeatureRules.supportedResetTypes` unions `Parameters[].AllowableValues`
      on `ResetType` (third allow-list source; unit + engine tests + live
      emulator pin of a served ActionInfo resource via a normal crawl);
      bmcweb
      ResetActionInfo → supportedResetTypes fallback also folds here —
      DOCS-4; **annotation-form allow-list fallback landed 2026-10-23 16:05** —
      `supportedResetTypes` now unions `SupportedResetTypes` +
      `ResetType@Redfish.AllowableValues` on `#ComputerSystem.Reset` (the
      bmcweb/mockup shape), conflation-guarded. Emulator notes: the DMTF mockup
      serves no `@odata.etag` on resources — etag behaviour cannot be pinned on
      this fixture, keep it in unit tests — 2026-10-23; the system-level
      `#ComputerSystem.Reset` `ResetType@Redfish.AllowableValues`
      (On/ForceOff/GracefulShutdown/GracefulRestart/ForceRestart/Nmi/ForceOn/
      PushPowerButton) is pinned — the allow-list fallback must read the system
      list, never the manager list — 2026-10-23 03:02;
      **third live PATCH pin + first pending-settings round-trip landed
      2026-10-24 (EMU 63→64)**: PATCH `/Bios/Settings` with an `Attributes`
      subset answers 204 + persists, and a stale `If-Match` is IGNORED (the
      settings-object ETag `9234ac83b9700123cc32` is the only concurrency
      token; the #028 BIOS editor must send it itself) — the #016 If-Match
      wiring input for the Boot/IndicatorLED flow + the 412 unit tests)
- [ ] **#017** Discover the SessionService URI instead of assuming it.
      (emulator test asserts `SessionService.@odata.id` is discoverable from the
      service root and serves a conformant SessionService — run 2026-10-22)
- [ ] **#018** Fix discovery-cache stale replay/leak.
      (**discovery-graph Links traversal pinned live 2026-10-24 18:xx**:
      Systems→Chassis→Manager `Links` (System.Links.Chassis/ManagedBy,
      Chassis.Links.ComputerSystems/ManagedBy/ManagersInChassis,
      Manager.Links.ManagerForServers/ManagerForChassis/ManagerInChassis)
      resolves all three hops — the #018 lightweight pass can walk the graph
      from any seed without hardcoded URIs)
      (emulator test added 2026-10-23: service root `ProtocolFeaturesSupported`
      advertises `ExcerptQuery` + `ExpandQuery{ExpandAll,Levels}` and publishes
      `FilterQuery`/`SelectQuery` — the query-capability surface a lightweight
      discovery pass must use; the client currently ignores it; **live
      `$expand` round-trip pin added 2026-10-23 17:07** —
      `$expand=.($levels=1)` on the Systems collection inlines full member
      bodies (Model/PowerState/Actions.Reset allow-list incl. Nmi +
      Processor/MemorySummary) in one round trip — the N+1-avoiding discovery
      shape the #018 pass can build on; **query-behavior contract pinned
      2026-10-23 18:36**: `$expand=*` (ExpandAll) serves the same inlined
      bodies, but `$filter`/`$select` are **advertised but NOT applied** by
      the pinned mockup (Roles collection unfiltered for `$filter=Id eq
      'NOPE'`, full system body for `$select=Model`) — the pass must filter/
      select client-side and rely only on `$expand` for payload shaping;
      **DOCS-15 spec audit folded 2026-10-23 19:25** — DSP0266 §7.3.1–7.3.5
      now traced in REQUIREMENTS.md: the pass must (a) gate `$expand` on the
      advertised `ExpandQuery.Levels`/`ExpandAll` (`*`/`$levels` default 1
      are the pinned forms; `MaxLevels` caps depth), (b) filter/project
      client-side (`$select`/`$filter` are GET-only subset semantics the
      mockup ignores), (c) map 501 (unsupported `$`-params) + 507 (oversized
      expanded payload) + `QueryNotSupportedOnResource`; the
      `RedfishClient.getJson(path, query:)` transport contract is now pinned
      by unit test — the pass can fetch collections with
      `query: {'\$expand': '.($levels=1)'}` without touching the ETag/304
      machinery; **map-form round-trip pinned live 2026-10-23 22:45** —
      `getJson('/redfish/v1/Systems', query: {'\$expand': '.($levels=1)'})`
      against the live mockup returns the same inlined full member bodies as
      the URL-string form — the exact call shape the #018 pass will make,
      end-to-end verified; **generalized across all three top-level
      collections 2026-10-25 (EMU 66→68)**: the same map-form `$expand` on
      `/redfish/v1/Chassis` + `/redfish/v1/Managers` inlines FULL member
      bodies (Chassis identity/Status/Links, Manager FirmwareVersion/Model/
      Links + the manager-level reset allow-list), and **`$levels=2` does
      NOT recurse — the member's own `Links.Chassis` stays a bare
      `@odata.id` ref** (DSP0266 §7.3.2 depth-cap pinned), so the pass gets
      one full inlined hop per collection and must follow cross-resource
      URIs explicitly for the graph)
- [x] **#022** Power: task polling, races, and error fixes.
      (**COMPLETE 2026-10-26 — closed.** All five acceptance criteria checked.
      The final one — **202 task-monitor polling** — landed via the shared
      #008/#020 poller: `RedfishTask`/`TaskMessage`
      (`lib/redfish/models/redfish_task.dart`) parse the served
      `#Task.v1_7_3.Task` shape (13 TaskStates per `Task.v1_7_4.json`,
      TaskStatus, optional PercentComplete, RFC3339 Start/EndTime,
      `Messages[]`) and `FirmwareService.pollTask` follows the 202
      `Location` monitor URI (first wait honors `Retry-After`, then polls at
      `interval` up to `maxPolls`; Completed/OK → success, terminal failure →
      `RedfishException` with the task's failure reason, budget exhaustion →
      retryable `TaskMonitorTimeout`, missing monitor → `NoTaskMonitor`).
      `FirmwareController.pollLastTask` + the firmware-view task banner
      (queued → polling spinner → final state) surface it. +25 model / +8
      service / +4 controller / +5 widget tests; unit suite 438 → **478
      passed / 1 skipped**; emulator 82 → **84/84** (2 new live pins: poller
      resolves fixture Task 545 end-to-end; stale monitor → normalized 404).
      Power-side 202 invocation stays unit-level on the DMTF fixture — the
      mockup answers 204 for reset with no monitor (pinned live);
      `PowerService` already captures the Location and reuses the same poller.
      (prior progress preserved below:)
      **the ActionInfo-*resource* crawl is now WIRED (2026-10-25 EMU run)**:
      the discovery engine follows `@Redfish.ActionInfo` links and captures the
      resources (live emulator pin — 79th test captures `SimpleUpdateActionInfo`
      through a normal crawl), and `FeatureRules.supportedResetTypes` unions
      `Parameters[].AllowableValues` on the `ResetType` parameter as the third
      source — bmcweb's `ResetActionInfo` shape parsed from the real resource
      (unit + engine tests; REQUIREMENTS.md row updated; `ResetActionInfo`
      itself is still absent on the DMTF fixture, so the live crawl pin uses
      the fixture's served ActionInfo resources). **Control SetPoint
      pre-validation landed 2026-10-25 (EMU run)**: `ControlResource.
      validateSetPoint` rejects out-of-bounds SetPoints before any PATCH
      (PowerLimit [150,1000], CPU1Freq [1500,3700]; boundaries inclusive;
      per-resource bounds never leak across controls — the SecureBoot
      allow-list precedent applied to numeric bounds); Control became
      client-mapped (served `Control.v1_5_0.json` in the fixture +
      corpus-invariant list) — +11 unit tests, +1 live emulator pin (79 →
      80/80). **The four power-action correctness fixes landed 2026-10-25
      (EMU run)** — per-action poll handle (`_pollGeneration`; a rapid second
      action supersedes the first poll loop — no optimistic-state clobbering),
      NMI keeps the current known state (interrupt, not a transition),
      failure shown once (inline error card only; snackbar success-only), and
      the final reset-URI fallback prefers the BMC ComputerSystem id — 4 of 5
      acceptance criteria checked; the remaining criterion (**202 task-monitor
      polling**) folds into #008/#020. **Emulator negative finding
      2026-10-23 17:07**: the DMTF mockup fixture ships NO `ResetActionInfo`
      ActionInfo resource for `#ComputerSystem.Reset` — it serves only the
      annotation form (= the 16:05 fallback); the ActionInfo-resource crawl is
      bmcweb-style (OpenBMC), now implemented + tested at unit/engine level and
      pinable live only via the served ActionInfo resources. Emulator asserts
      the DMTF mockup's
      `#Manager.Reset` carries its own `ResetType@Redfish.AllowableValues` —
      the fallback must not conflate manager- vs system-level Reset actions —
      run 2026-10-22; system-level allow-list pinned incl. `Nmi` (NMI-stabilize)
      + `ForceOn` + `PushPowerButton`, and the mockup does NOT advertise
      `PowerCycle` — the gate must use exactly the advertised values — run
      2026-10-23 03:02; the annotation-form rule is now also pinned on a
      SECOND system action family — `#SecureBoot.ResetKeys` +
      `ResetKeysType@Redfish.AllowableValues` (EMU 57→60, 2026-10-24), with
      the per-resource nuance that `#SecureBootDatabase.ResetKeys` carries a
      *smaller* allow-list than the SecureBoot-level one (PK omits DeletePK)
      — allow-list sources are per-resource, never shared)
- [x] **#024** `profile_repository.clear()` orphaned passwords. (run 2026-11-16 06:01 UTC, commit 1d3e0ef)
- [x] **#026** Resolve duplicate auth fields. (run 2026-11-16 06:27 UTC, commit this run)

## P2 — feature completeness

- [x] **#006** System overview adaptive cards.
      (run 2026-11-16 — triage verified acceptance satisfied: schema-driven
      overview model/provider/service/view, adaptive 1/2/3-column layout with
      breakpoints, `Health`/`HealthRollup` fallback, missing-field tolerant
      rendering (omit/“Not exposed” — no disabled placeholders), skeleton/
      loading/error states, 30s auto-refresh + pull-to-refresh + power-state
      refresh, and 320/800/1300 + semantics widget/provider coverage. Added
      rendering-rules doc `lib/features/overview/README.md`; closed
      `issues/closed/006-system-overview-dashboard.md`. Detailed sensor graphs
      remain #007.)
- [x] **#007 / #019** Sensor monitoring, real-time telemetry, retry.
      (both CLOSED: emulator pins the 41-member Sensors collection end-to-end —
      typed readings (Cel/V …) + thresholds parse through
      `SensorsService.fetchAll()` — and the real-time poll/backoff/delta layer,
      alert banner, threshold coloring, pull-to-refresh, 401 resilience and
      `fl_chart` LineChart with a 20x60 no-jank bed all landed; 94.3% sensor
      coverage. #007 closed run 2026-11-17; EventService/SSE remains a separate
      DOCS-7 "Events" item below.)
- [ ] **Events** Event subscription + SSE client — DOCS-7 decided out-of-scope this
      milestone (see P1 docs section); revisit when telemetry (#007/#019) or task
      monitoring (#008/#020/#022) creates a receiver. Spec: DSP0266 §12.1,
      bmcweb field set audited in REQUIREMENTS.md "bmcweb field notes".
- [~] **#008** Firmware update management resilience + polish (**#020 split
      off, now CLOSED** — commit pending on 2026-11-04).
      (bmcweb: update is HTTP-push via `HttpPushUri`/`MultipartHttpPushUri`, no
      `SimpleUpdate` — our `startSimpleUpdate` would 405 on OpenBMC; add push
      path — DOCS-4, REQUIREMENTS.md; emulator asserts `UpdateServiceInfo.
      httpPushUri == '/FWUpdate'` on the DMTF mockup — run 2026-10-22;
      **both push URIs are now surfaced**: `multipartHttpPushUri` added to
      `UpdateServiceInfo` (DOCS-9, run 2026-10-23) — the upload flow must pick
      the right URI (multipart for bmcweb); emulator test added 2026-10-23:
      `HttpPushUriOptions.HttpPushUriApplyTime` publishes
      `ApplyTime == 'Immediate'` + AllowableValues (Immediate/OnReset/
      AtMaintenanceWindowStart/InMaintenanceWindowOnReset) + MaintenanceWindow
      start time; `UpdateServiceInfo` now parses both — the push-upload flow
      must offer apply-time selection instead of assuming Immediate;
      `SimpleUpdateActionInfo` pinned 2026-10-23 03:02: `ImageURI` Required +
      `TransferProtocol` AllowableValues (HTTP/HTTPS/SFTP…) — the parameter
      contract for `startSimpleUpdate` on BMCs that DO expose SimpleUpdate;
      `startSimpleUpdate` now returns an `UpdateTask` handle with the 202
      `Location` task-monitor URI + optional `Retry-After` seconds (DSP0266
      §12.2; `Task.v1_7_4.json` mirrored as DOCS-10); **Task resource contract
      pinned 2026-10-23 09:14**: GET `/TaskService/Tasks/545` returns
      `TaskState Completed`/`TaskStatus OK`/RFC3339 Start-EndTime/`Messages[]`
      and **no `PercentComplete`** (poller must treat it as unknown), and
      TaskService publishes `CompletedTaskOverWritePolicy=Manual` +
      `LifeCycleEventOnTaskStateChange=true` — the poller only lacks
      GET-on-monitor + TaskState parsing;
      **TASK-MONITOR POLLING LANDED 2026-10-26 (#022 closed on it)** —
      `RedfishTask`/`TaskMessage` models + `FirmwareService.pollTask`
      (GET-on-monitor, Retry-After first-wait, terminal detection, bounded
      polls) + `FirmwareController.pollLastTask` + the firmware-view task
      banner; unit 478/1 skipped, emulator 84/84 with 2 new live pins;
      **PUSH UPLOAD TRANSPORT LANDED 2026-10-26 (EMU)** —
      `FirmwareService.pushImage(PushImageRequest)` uploads raw bytes
      single-push on `HttpPushUri` or multipart `FormData` (`UpdateFile` +
      optional `UpdateParameters` JSON for targets/apply-time) on
      `MultipartHttpPushUri`, resolves the push URI against the UpdateService
      resource URI (DSP0266 relative-reference rule), normalizes non-2xx to
      friendly `RedfishException`s (400/413/5xx surfaces the served body, no
      masking; missing push URI → `NoPushUri`; disconnected →
      `NotConnected`), reports byte progress via dio `onSendProgress`, and
      hands a 202 + `Location` to `pollTask`; `FirmwareController.pushImage`
      (uploading/uploadProgress) + the firmware-view upload banner (merged
      semantics label + byte-count progress) drive the flow; +16 unit tests,
      +1 live emulator pin — unit 496/1 skipped, emulator 85/85.
      **FILE-PICKER Landed 2026-10-28 (recovered WIP commits 297b6bf–4ac306d)** —
      the push-upload card (`Choose image…` picker + Upload/auto-poll seam,
      5 picker widget tests, fake-async-safe via `XFile.fromData(path:)`).
      **TASK-TIMELINE PROGRESS LANDED 2026-10-29 (EMU)** — `pollTask`
      `onInterim` → `FirmwareUiState.pollProgress` → determinate bar +
      `N% complete` while polling (absent `PercentComplete` tolerated).
      **APPLY-TIME SELECTOR LANDED 2026-11-04 (EMU — #020 CLOSED)** — the
      capability-gated "Apply time" dropdown in the push-upload card built
      ONLY from `info.httpPushApplyTimes` (the served
      `ApplyTime@Redfish.AllowableValues`); default **"Service default"**
      (`null`) omits `@Redfish.OperationApplyTime` on the wire entirely —
      never an assumed Immediate; +4 widget tests; unit 511/1 skipped,
      EMU 85/85; #020 closed.)
- [ ] **#009 / #021** Remote KVM capability detection and console rendering.
      (emulator now pins the manager network surface the console renderer
      needs: `Manager.NetworkProtocol.KVMIP` ProtocolEnabled + port 5288, plus
      HTTPS/SSH endpoints, and EthernetInterfaces MAC/IP/VLAN — run
      2026-10-23 11:39; #009 must resolve the console endpoint from the
      advertised KVMIP port, never hardcode ports; #021 viewer path landed with
      protocol-specific external-client guidance incl. SSH/Telnet/IPMI and
      HTML5 browser-open hint — embedded WebView/protocol rendering remains
      blocked on platform/TLS validation, 2026-11-16)
- [ ] **#028** BIOS configuration editor — Bios/Settings surface (candidate
      feature, DOCS-23 2026-10-24). The EMU-2 Bios `@Redfish.Settings` pin +
      the DOCS-23 corpus mirror give the full served/newest pair; a BIOS-config
      editor makes `Bios`/`Settings` client-mapped, which pulls them into the
      DOCS-19/20/21 fixture invariant (copy served `Bios.v1_2_2.json` +
      `Settings.v1_3_5.json` into `test/fixtures/redfish/schemas/` and add both
      families to the emulator corpus-invariant list). PATCH/If-Match with the
      settings-object ETag folds #016; **the pending-settings PATCH round-trip
      seam is now pinned live (EMU 63→64, 2026-10-24): PATCH `/Bios/Settings`
      with an `Attributes` subset 204s + persists, stale If-Match ignored —
      the exact mutation shape a BIOS editor sends**; `Bios.v1_3_0` `Passwords`
      + the `ChangePassword` action are a #015/#026 password-management input.
      See `issues/open/028-*` for acceptance criteria.
- [ ] **#010** Hardening: secure storage, theming, accessibility, coverage.

## P2 — UI improvements (one small, tested increment per green run)

- [x] **UI-1** Empty / loading / error states for dashboard, sensors, firmware, KVM.
      (FirmwareView error state upgraded to an errorContainer card with a
      working Retry action — done 2026-10-22; KVM/Sensors/Overview views already
      covered; **dashboard error summary + one-tap Retry via
      `SystemManager.retryFailed()` done 2026-10-22 (DOCS-8 run, commit
      b9dcd31)** — all views covered, **UI-1 done**)
- [ ] **UI-2** Accessibility: semantics labels, contrast, touch targets, focus order.
      (Health/Power badges semantic labels done 2026-10-22 — commit c8dc7e1;
      destructive power dialog label done 2026-10-22 — commit 81dfb8f; firmware
      inventory cards merged a11y label done 2026-10-23 — Semantics container
      with concise summary (component, version, health, updateable/locked) +
      widget test; sensors temperature/fan/generic tiles merged a11y labels
      done 2026-10-23 — Semantics container + excludeSemantics, one concise
      summary per tile (name, value, health) + widget test; chassis card header
      merged summary label (`Chassis 1U, 1 temperatures, 1 fans, 1 sensors`)
      done 2026-10-23 03:02 — Semantics container on the title, tile labels
      preserved + widget test; overview InfoCard header merged semantics label
      (`Identity`/`Processors`/`Memory`/`Temperatures`/`Indicator LED` as one
      node via `Semantics(container: true, excludeSemantics: true, label:
      title)` + widget test) done 2026-10-23 06:10; SystemCard header merged
      semantics label (`<name>, connected|connecting|connection error|
      disconnected`) done 2026-10-23 07:xx — Semantics on the title+status-icon
      row only, PopupMenuButton keeps its own semantics, +widget test across all
      four connection states; KvmConsole card header merged semantics label
      (`<type>, enabled|disabled`) done 2026-10-23 09:14 — Semantics on the
      title+Enabled/Disabled-chip row, widget tests for both states; PowerView
      card header merged semantics label (`<name>, power <state>`) done
      2026-10-23 — Semantics on the title+PowerBadge row, widget test for the
      merged node; OverviewView HealthBanner merged semantics label
      (`Health: <state>`) done 2026-10-23 11:39 — Semantics(container +
      excludeSemantics) wraps the icon+label row, widget test asserts the
      merged node + visible text; FirmwareView header row merged semantics
      label (`Firmware and update management[, loading]`) done 2026-10-23 —
      Semantics wraps the title+in-flight-spinner row, widget tests for both
      the loading and idle states; DashboardView aggregated banner merged
      semantics label (`Health: <summary>`, incl. the "No systems" empty
      state) done 2026-10-23 13:58 — Semantics(container + excludeSemantics)
      wraps the icon+summary row, widget tests assert the merged node +
      visible text; **dialog action buttons explicit 48×48px touch targets done
      2026-10-23 16:05 — `ConfirmResetDialog` Cancel/Confirm get
      `minimumSize: Size(48,48)` + padded tap target, widget test asserts both
      buttons render ≥48px tall; **SystemProfileForm self-signed certificate
      warning banner merged semantics label (`Warning: self-signed
      certificates disable TLS verification. Only enable for trusted, isolated
      management networks.`) done 2026-10-23 17:30 — Semantics(container +
      excludeSemantics) wraps the icon+text row revealed by the "Allow
      self-signed certificate" switch, widget test asserts the merged node +
      visible text — remaining UI-2: focus order, remaining
      non-card labels); **SystemOverviewPage connection header (name + URL)
      merged semantics label (`<name>, <scheme>://<host>:<port>`) done
      2026-10-23 19:25 — Semantics(container + excludeSemantics) wraps the
      title+URL column, conditional connection-error text keeps its own node,
      widget test asserts the merged label + both visible texts;
      `connectedHandle` helper gained a `port` param; **KVM console card
      connect-URI row merged semantics label (`Connect URI: <uri>`) done
      2026-10-23 22:45 — Semantics(container + excludeSemantics) wraps the
      label + SelectableText in a row, widget test asserts the merged node +
      both visible texts; **OverviewView error state merged semantics label
      (`Unable to load overview. <message>`) done 2026-10-23 23:40 —
      Semantics(container + excludeSemantics) wraps the icon + title +
      detail column, Retry button keeps its own control node, widget test
      asserts the merged label + visible texts + separately-announced Retry;
      **SensorsView error state merged semantics label (`Unable to load
      sensors. <message>`) done 2026-10-24 — Semantics(container +
      excludeSemantics) wraps the icon + title + detail column (the
      established error-state pattern), the new Retry button reloads via the
      controller (re-runs the failing service in tests), widget tests assert
      the merged label + visible texts + separately-announced Retry;
      **PowerView inline error state merged semantics label (`Power control
      failed. <message>`) + separate Retry `TextButton.icon` done 2026-10-24 —
      Semantics(container + excludeSemantics) wraps the visible error text,
      Retry re-reads the power state via the existing
      `PowerController.refresh()` (clears the error on success), widget tests
      assert the merged node + visible text + separately-announced Retry +
      Retry re-runs the failing fetch;
      **KvmView hard-load error state merged semantics label (`Unable to load
      KVM consoles. <message>`) + Retry `FilledButton.icon` done 2026-10-24 —
      the full icon + title + detail error state (the SensorsView pattern),
      Retry reloads via `KvmController.load()`, and an error with zero
      consoles now renders the error state instead of the bare error line
      above 'No consoles found.', widget tests assert the merged node +
      visible texts + separately-announced Retry + Retry re-runs the failing
      service;
      **DashboardView error summary card merged semantics label (`Unable to
      reach N systems. Retry available.`) done 2026-10-24 — Semantics(container
      + excludeSemantics) wraps the icon + visible text row, the Retry
      TextButton keeps its own control node outside the container, widget
      tests assert the merged node + visible text + separately-announced Retry
      + the singular (`Unable to reach 1 system…`) form;
      **FirmwareView Start-update button busy state done 2026-10-24 —
      `FirmwareUiState.starting` distinguishes a SimpleUpdate POST in flight
      from screen-level loading; while starting the FilledButton shows a
      spinner + 'Starting…' and is disabled, re-enabling on success/failure
      (the UI-5 power-dialog busy-state precedent) — +3 controller tests +
      2 widget tests (busy state + failure re-enable);
      **DashboardView empty state ("No systems yet. Tap + to add a BMC.")
      done 2026-10-24 — the last bare-`Text` empty surface on the dashboard
      now renders the established pattern: icon (`Icons.dns_outlined`) +
      visible text inside a `Semantics(container + excludeSemantics)`
      merged node (one self-describing announcement; no Retry — the empty
      list is not an error), +1 widget test asserts the merged label +
      visible text + icon; existing 320/800/1300 no-overflow tests unchanged
      (the empty state is a `Center` + `mainAxisSize.min` column);
      **FirmwareView empty state ("No firmware inventory reported.") done
      2026-10-24 — the last bare-`Text` empty surface on the firmware view
      now renders the established pattern: icon (`Icons.inventory_2_outlined`)
      + visible text inside a `Semantics(container + excludeSemantics)`
      merged node (one self-describing announcement; no Retry — a successful
      load with zero inventory is not an error), +1 widget test asserts the
      merged label + visible text + icon + no overflow at 320/800 px;
      **FirmwareView inventory-loading state merged semantics label
      (`Loading firmware inventory`) done 2026-10-24 — the in-flight
      inventory load previously announced a bare detached `Text('Loading
      inventory…')` next to the header; it now renders inside a
      `Semantics(container + excludeSemantics)` node (one self-describing
      announcement for the specific surface still loading, visible text
      preserved), +1 widget test asserts the merged label + visible text;
      **SystemOverviewPage `System not found` fallback merged semantics node
      (`System not found`) done 2026-10-24 — the last bare `Text` fallback on
      the overview page now renders the established pattern: icon
      (`Icons.search_off_outlined`) + visible text inside a
      `Semantics(container + excludeSemantics)` merged node (one
      self-describing announcement; no Retry — a nonexistent system id is not
      an error), +1 widget test asserts the merged label + visible text +
      icon + no overflow at 320 px (via the `addTearDown` restore pattern);
      **AppRouter route-not-found fallback merged semantics node (`Route not
      found: <uri>`) done 2026-10-24 — the last bare-`Text` fallback surface
      in the app (GoRouter `errorBuilder`) now renders the established
      pattern: icon (`Icons.search_off_outlined`) + visible text inside a
      `Semantics(container + excludeSemantics)` merged node; the URI is
      dynamic so the label mirrors the visible text; no Retry — an unknown
      route is not an error; +2 widget tests in `test/core/router_test.dart`
      (merged `bySemanticsLabel` node + visible text + icon, and no overflow
      at 320 px);
      the FirmwareView no-overflow test's manual `setSurfaceSize` restore was
      also converted to the established `addTearDown` (the 12:30 journal
      noted it for this run);
      **SystemCard header merges name + state + endpoint URL (`<name>,
      <state>, <scheme>://<host>:<port>`) done 2026-10-24 — the URL subtitle
      line (the last remaining non-card label on the dashboard card) is now
      part of the merged header semantics node (the SystemOverviewPage
      connection-header precedent) and the standalone subtitle Text is
      `ExcludeSemantics`'d so it does not double-announce (visible text
      preserved); the existing 4-state header test updated to expect the
      merged name + state + URL label, +1 widget test asserts the merged node
      + the URL appears exactly once in the semantics tree;
      **SystemCard detail line (Manufacturer · Model) merged semantics node
      done 2026-10-24 — the last remaining non-card label on the dashboard
      card body now renders inside a `Semantics(container +
      excludeSemantics)` node (one self-describing announcement, visible
      text preserved — the established card-row pattern), +1 widget test
      asserts the merged label + visible text;
      **OverviewView Identity card key/value rows merged semantics node done
      2026-10-25 — each `_kv` row (label + value) now announces as ONE node
      (`Manufacturer: Acme`, `Model: Server-9`, `Serial: SN1`, `BIOS: 1.0`;
      a missing value merges as `<label>: Not exposed by this BMC`) —
      a screen reader hears the field and its value together instead of a
      detached label next to a detached value text, +2 widget tests assert
      the merged labels + visible texts + the missing-value form;
      **OverviewView Processors card body merged semantics node done
      2026-10-25 — the count + model texts (`2 processor(s)`, `P9`)
      previously announced as two detached nodes under the merged
      "Processors" header; they now render inside ONE
      `Semantics(container + excludeSemantics)` node (`2 processor(s), P9`)
      — one self-describing card-body announcement, visible texts preserved
      (the established card-row pattern), +1 widget test asserts the merged
      label + both visible texts;
      **HealthBadge/PowerBadge merged node fixed (added `excludeSemantics`)
      done 2026-10-25 — both badges wrapped their `Chip` in
      `Semantics(label: ..., container: true)` WITHOUT `excludeSemantics`,
      so the chip's inner Text still announced separately (a screen reader
      heard "Health Warning" then "Warning" / "Power Off" then "Off" — the
      double-announcement pattern merged everywhere else in the app). Both
      badges now add `excludeSemantics: true` so the merged label is the
      ONLY announcement; visible text preserved for sighted users; the a11y
      label test extended to pin the single-node behavior
      (`bySemanticsLabel('Warning')`/`('Off')` now findsNothing while the
      merged labels still find one widget and the visible texts remain);
      **FirmwareView inventory card merged node fixed (added
      `excludeSemantics`) done 2026-10-25 — the per-item firmware card
      wrapped its `ListTile` in `Semantics(container: true, label: ...)`
      WITHOUT `excludeSemantics: true`, so the inner title/subtitle/chip
      `Text`s still announced separately (a screen reader heard the merged
      summary `Firmware BMC Firmware, 3.2.1, OK, updateable` AND then `BMC
      Firmware`, `BMC · 3.2.1 · OK`, `Updateable` — the double-announcement
      pattern merged everywhere else in the app). The card now adds
      `excludeSemantics: true` so the merged label is the ONLY announcement;
      visible text preserved for sighted users; the a11y label test extended
      to pin the single-node behavior (`bySemanticsLabel('BMC Firmware')`/
      `('Updateable')` now findsNothing while the merged label still finds
      one widget and the visible texts remain); audit: no other
      `Semantics(container: true)` node in `lib/` lacks `excludeSemantics`;
      **firmware start-update form transfer-protocol selector labelled done
      2026-10-25 — the bare `DropdownButton<String>` (protocol picker) had NO
      visible label (unlike the Image URI TextField's `labelText`) and no
      a11y context — it now renders a `Transfer protocol` Text above the
      select (the Image URI labelText pattern, labelLarge + outline color);
      the card column merges sibling plain Texts so a screen reader hears
      `Start update, Transfer protocol` in the section node before the
      protocol value while the dropdown keeps its own button node (`HTTP`);
      +1 widget test (visible label + announced label + dropdown control node
      + protocol selection still works), firmware 18→19;
      **KVM console card body rows merged semantics nodes done 2026-10-25 —
      the three remaining bare body labels in `_ConsoleCard` (`Manager: BMC`,
      `Max concurrent sessions: 4`, `HTML5 console — open via BMC web UI.`)
      each announced as detached `Text` rows (the last "non-card label"
      class in the KVM view); each now renders inside a
      `Semantics(container + excludeSemantics)` node (the established
      card-row pattern, one self-describing announcement, visible texts
      preserved), +1 widget test asserts the three merged labels + visible
      texts, KVM 11→12;
      **sensor tile merged labels now carry the visible subtitle context done
      2026-10-25 — the three tiles wrapped their inner title/subtitle/chip in
      `Semantics(container + excludeSemantics)` (the 2026-10-23 merge) but the
      `excludeSemantics` dropped the SUBTITLE: temperature tiles hid the
      threshold hints (`caution 45 / crit 55`), fan tiles hid the physical
      context (`CPU`), generic sensor tiles hid the reading type + thresholds
      (`Voltage · UpperCritical 13.0 / LowerCritical 11.0`) that sighted
      users see; each merged label now appends that visible subtitle context
      (`Temperature CPU1 Temp, 41.0°C, Unknown, caution 45 / crit 55`, `Fan
      Fan0, 5400 RPM, Unknown, CPU`, `Sensor PSU1, 12.50 V, Unknown, Voltage,
      UpperCritical 13.0 / LowerCritical 11.0`) — one self-describing
      announcement that mirrors the visible text, +1 widget test asserts the
      detail-aware labels + visible subtitles stay, sensors 13→14;
      **OverviewView Memory card body merged semantics node done 2026-10-25 —
      the card capacity (`32 GiB`) sat under the merged "Memory" header as a
      bare detached `Text` (a screen reader heard a naked number); it now
      renders inside the established `Semantics(container + excludeSemantics)`
      card-body pattern (the Processors-card precedent): one self-describing
      announcement (`32 GiB`) that mirrors the visible text, visible text
      preserved for sighted users, +1 widget test asserts the merged label +
      visible text, overview 14→15;
      **PowerView card header merges the "Power control" subtitle into the
      header node done 2026-10-25 — the merged header previously announced
      `<name>, power <state>` with the `Power control` subtitle below it as a
      bare detached Text (the same list-header class the KVM header merged
      title+subtitle for); the whole card header (display name + PowerBadge +
      subtitle) now announces as ONE node `<name>, power <state>, Power
      control`; visible texts preserved for sighted users; +1 widget test
      asserts the merged label incl. the subtitle + visible text preserved +
      the bare "Power control" node no longer announces separately;
      **unlabeled loading spinners merge into self-describing nodes done
      2026-10-25 — the last bare `CircularProgressIndicator` announcements in
      the feature views: SensorsView's full-screen spinner (the only node on
      screen) now announces ONE merged `Loading sensors` node, and KvmView's
      first-load spinner now announces ONE merged `Loading KVM consoles` node
      (both via the established `Semantics(container + excludeSemantics)`
      loading pattern, visible spinners preserved; the KVM change also
      reordered the state branches so a first load no longer flashes the
      misleading `No consoles found.` empty state — `loading && consoles.
      isEmpty` renders the merged loading node before the empty branch, while
      refreshes with existing consoles keep the inline spinner under the
      header); +2 widget tests (sensors 14→15, kvm 12→13);
      **FirmwareView discovery-pending state merged semantics node
      (`Loading firmware`) done 2026-11-08 — capability-gate/discovery-pending
      path (`handle == null || features == null`) now announces ONE merged
      `Loading firmware` node (container+excludeSemantics, established
      pattern) instead of a bare unlabeled progress indicator; +1 widget test
      (firmware 40→41);
      **Add-system dialog focus entry + keyboard Tab order pinned done
      2026-10-25 — `SystemProfileForm` gained `autofocusFirstField` (the
      Add-system dialog sets it, so keyboard and screen-reader users land
      inside the form the moment it opens — WAI-ARIA dialog pattern: focus
      moves into the dialog; the edit page leaves it off so it does not
      scroll on load); two widget tests pin (1) the dialog opening with
      keyboard focus on the first field and (2) the full Tab traversal order
      Name → Host → Port → Use TLS switch → auth-method dropdown → Username →
      Password → Remember password → Allow self-signed → Add system button —
      a regression (autofocus removed or a field inserted out of visual
      order) now fails loudly, systems 31→32;
      **#016 writable IndicatorLED setter + Boot-override card done 2026-10-25
      — the Overview view's "Indicator LED" card gained the three
      schema-writable ChoiceChips (Lit/Blinking/Off; capability-gated on a
      known state; busy spinner + merged inline error) and a capability-gated
      Boot-override card (dropdown of the advertised
      `BootSourceOverrideTarget@Redfish.AllowableValues` + Once/Continuous +
      Apply; hidden entirely when no allow-list is advertised — never a
      placeholder); the LED state text + chips both announce (the selected
      chip is its own control node); +8 widget tests incl. 320/800/1300
      no-overflow (service-level assertions live in settings_service_test.dart);
      **ConfirmResetDialog focus entry + Tab order pinned done 2026-10-25 —
      the power reset-confirmation dialog now opens with keyboard focus
      INSIDE it on the least-destructive action (Cancel) — WAI-ARIA dialog
      pattern, the Add-system dialog precedent — via an explicit
      `_cancelFocus` FocusNode requested after the first frame (an Enter/Tab
      user cannot accidentally trigger a destructive reset), Tab walks
      Cancel → Force and wraps; +2 widget tests (destructive + non-destructive
      dialog focus entry + the Tab order), power 51→53;
      **remove-system confirmation dialog landed done 2026-10-25 — the
      dashboard `Remove` menu action previously deleted a profile (and its
      stored credentials) on a single tap with NO confirmation; it now opens
      `ConfirmRemoveSystemDialog` (`lib/features/systems/views/
      confirm_remove_system_dialog.dart`): focus lands inside the dialog on
      the least-destructive action (Cancel), Tab walks Cancel → Remove and
      wraps, both actions expose explicit ≥48 px touch targets, the confirm
      button uses the error color + destructive semantics label, and the copy
      makes the permanence explicit ("stored connection profile and its saved
      credentials will be deleted permanently"); +4 dashboard-integration
      widget tests (dialog copy, focus entry + Tab order, cancel keeps the
      system, confirm removes it); the dialog test exposed a small real
      defect — `removeProfile` tried to clear `selectedId` via
      `copyWith(selectedId: null)` but `SystemState.copyWith` treats null as
      "keep current", so the id of a removed system stayed selected; removal
      now builds the state directly and +2 `system_manager_test.dart` unit
      tests pin the clear-on-last-removal + fallback-to-first-remaining
      behaviour; systems 32→36 (widget) + manager CRUD 3→5;
      all dialogs now have focus/tab tests (Add-system, reset-confirm,
      remove-confirm);
      **edit-system dialog focus entry pinned done 2026-10-26 — the last
      dialog without focus entry: `showEditSystemDialog` now sets
      `autofocusFirstField: true` (keyboard/screen-reader users land on the
      first field the moment the dialog opens — WAI-ARIA dialog pattern, the
      Add-system dialog precedent); the full-page `EditSystemPage` keeps the
      flag off so it does not scroll on load (the documented reason for the
      flag); +2 widget tests pin the dialog focus entry + the full Tab order
      to the Save button (Name → Host → Port → TLS → auth-method → Username →
      Password → Remember → self-signed → Save, the edit-mode button label
      asserted so a regression to 'Add system' fails loudly), systems 36→38;
      extend to
      remaining cards, dialogs, tables)
- [ ] **UI-3** Responsive layout: no overflow at 320 / 800 / 1300 px widths; add
      widget tests for each breakpoint.
      (PowerView no-overflow tests added 2026-10-22; SensorsView no-overflow
      tests added 2026-10-22; FirmwareView no-overflow tests added 2026-10-22;
      KvmView no-overflow tests added 2026-10-22; DashboardView + OverviewView
      no-overflow tests added 2026-10-22 — fixes: DashboardView 1-col grid
      aspect ratio 1.25, OverviewView 1-col natural-height card stack) —
      **all views covered, UI-3 done**
- [ ] **UI-4** Visual consistency for cards, badges, health/power colors, spacing.
- [ ] **UI-5** Power confirmation dialog: clearer destructive-action copy and
      disabled/busy states.
      (destructive copy + a11y label done 2026-10-22 — commit 81dfb8f; reset
      buttons announce the in-flight state + disable while busy — done
      2026-10-22; dialog confirm button busy state (spinner + disabled, Cancel
      disabled, barrier non-dismissible while in flight, busy semantics)
      completed 2026-10-22 — 2 new widget tests) — **UI-5 done**
- [ ] **UI-6** Sensor table: sorting/filtering, threshold highlighting, stale data.
- [ ] **UI-7** Firmware upload: progress, cancel, task status timeline.
- [ ] **UI-8** KVM: launch/placeholder UX when the console is unsupported.
- [ ] **UI-9** Dashboard: multi-system aggregation, offline/error summaries.
- [ ] **UI-10** Consider stable golden/screenshot smoke tests once layouts settle.

## P2 — refactor and quality

- [x] **#011** Relocate `ConnectionProfile` to `core`. (run 2026-11-16, commit 221d510 — canonical model moved to `lib/redfish/models/connection_profile.dart` with compatibility re-export; closed `issues/closed/011-relocate-connection-profile-to-core.md`)
- [ ] **#012** Consolidate DI providers.
- [x] **#013** Remove dead `app_breakpoints.dart`. (run 2026-11-16, commit 13594e0 — deleted dead `lib/core/theme/app_breakpoints.dart` and reconciled to canonical `lib/core/theme/breakpoints.dart`; closed `issues/closed/013-remove-dead-breakpoints.md`)
- [x] **#023** Overview: `listenManual` leak and async errors. (run 2026-11-16 09:39 UTC, commit 7e0967f — stored/closed overview power-state subscription, handled refresh failures safely, preserved snapshot on transient refresh errors; closed `issues/closed/023-overview-leak-async.md`)
- [x] **#025** Harden unsafe `.first` / `as` casts. (run 2026-11-16 — guarded listed `.first` accesses and null-safe collection casts in KVM/firmware/power/overview/snapshot/sensor paths; added empty/missing collection regression tests; closed `issues/closed/025-harden-unsafe-collection-access.md`)
- [ ] Keep coverage **≥ 80%** for every feature touched by a run.
- [ ] Run `dart format` on Dart sources; keep `flutter analyze` at zero.
      (note 2026-10-25 DOCS run: the Flutter 3.47.6 `dart format` reflows 26
      Dart files committed under an older formatter (line-join width drift in
      lib/redfish/{client,discovery,models}/*, lib/features/{kvm,overview,
      power,sensors,systems}/*, test/**) — the DOCS run restored them rather
      than commit unrelated churn; a future run should absorb the drift as a
      dedicated `chore: dart format` commit after verifying analyze+test
      stay green)
- [ ] Remove generated/build artifacts from git; keep `.gitignore` current.

## Blocked / needs a human

- [!] **Live BMC integration** — requires real credentials/network; never attempt
      in the unattended job. Keep the live-BMC test skipped.
- [!] **KVM webview/native console** — may require a platform plugin and manual
      device validation; document the decision before adding dependencies.
- [!] **Large spec/binary assets** — if over the download budget, ask a human
      before committing; store links and hashes meanwhile.
- [!] **Environment quota blocking verification (2026-11-08 05:47Z)** — `flutter test` failed with "Disk quota exceeded" (errno 122) writing test listener temp files (default TMP and `TMPDIR=/tmp/opencode`); baseline was green at run start. Re-run `flutter analyze` + `flutter test` before committing. Untracked `testing/` (harness/results) went missing and was partially restored locally (`run_emulator_harness.sh` needs correct DMTF mockup path + robust PATH/redfishtool handling); commit once verified. `redfishtool` not found in PATH during run.

---

## Run history pointers

- `automation-tracking.md` — one section per automation run.
- `progress/journal.md` — project daily journal (append-only).
- `progress/progress_summary.md` — weekly rollup.
- `issues/issues.py list --all` — detailed issue queue.

## Automation notes (updated 2026-11-16 20:07 UTC)
- Last run 2026-11-16 20:07 UTC (FEATURE #010): added TLS-disabled HTTP warning banner + merged semantics in system profile form and widget/a11y regression test. Baseline analyze 0, tests 574 passed / 1 skipped; verify analyze 0, tests 575 passed / 1 skipped, issues validate OK. DOCS anchor gate not re-run (no manifest/corpus change); EMULATOR skipped (no lib/test_integration/tool/fixture contract change, <7 days since last green run). Next: continue #010 hardening or split/advance #007/#008/#009 with a tested slice.
