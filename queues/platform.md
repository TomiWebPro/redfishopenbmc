# Queue rf-platform (enable FIRST — the unblocking dept)

Owns: new `lib/features/kvm/platform/**` only. Verify: `flutter analyze` 0 + targeted tests.
Hard rule: no production TLS weakening, ever. No WebView/protocol dependency without
platform validation evidence.

## Backlog (head first)

<!-- rf-ideate split 2026-11-22 10:12 UTC: carves a fresh, machine-checkable, unblocked slice of the
     still-open (human-gated) WebView/TLS render closeout of #009/#021. EP-P9/EP-P13 pin the platform
     launch plan and navigation gate over hostile AUTHORITIES (confusables, scheme-relative, encoded
     delimiters), but nothing pins the SCHEMEPS themselves: case-folded / padded / percent-encoded
     scheme spellings (`HTTPS:`, `hTtPs:`, ` https:`, `https%3A//host`, a scheme-relative form) can shift
     a URI from "secure HTTPS -> externalBrowser" to "degrade -> copyOnly" or be misrouted. Test/doc-only;
     the human WebView/TLS validation (EP-P1/P2/P4) stays gated and is NOT re-split. AUDIT FIRST;
     RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [ ] EP-P14 Launch-plan scheme-spelling fail-closed matrix: over a matrix of HTTP(S) scheme spellings
      (canonical `https:`, mixed-case `HTTPS:` / `HtTpS:`, leading/trailing whitespace around the
      `ConnectUri`, a percent-encoded scheme colon `https%3A//host`, a scheme-relative form and a
      control-bearing scheme), feed each through `planConsoleLaunch` under `KvmWebViewPolicy.productionDefault`
      and pin that the route is NEVER `inAppWebView`, `acceptSelfSigned` is NEVER true, and every URI that
      is not a canonical secure-HTTPS target degrades to `copyOnly` with a control-safe / null target —
      while a canonical secure-HTTPS URI stays `externalBrowser`. Record any drift from the documented
      `LAUNCH_FALLBACK.md` route table as a RED->GREEN fix, never a doc-only edit. AUDIT FIRST: if EP-P6/P9/P13
      already pin the full scheme matrix, record the audit and add nothing; RED->GREEN only on a genuine
      divergence, never churn. Test/doc-only; no WebView/protocol import, no URL opened, no dependency,
      no production TLS weakening.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), RED->GREEN proof
              only on a genuine divergence; writes limited to `test/features/kvm/platform/**` + the decision
              docs; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no WebView/protocol dependency,
              no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 06:09 UTC: carves a fresh, machine-checkable half of the still-open
     (human-gated) WebView/TLS closeout of #009/#021. EP-P11/EP-P9 pin the navigation gate and launch
     plan over control/CRLF/NUL/cross-origin/userinfo authorities, but not over scheme-relative,
     network-path and percent/backslash-confused authorities — an area where `Uri` parsing is chronic
     authority confusion and a one-sided gate edit could navigate the trusted frame off-origin while
     both single-gate suites stay GREEN. Test/doc-only; the human validation (EP-P1/P2/P4) stays gated
     and is NOT re-split. AUDIT FIRST; RED→GREEN only on a genuine divergence, never churn. No code
     touched. -->

- [x] EP-P13 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-P13 scheme-relative / network-path / encoded-authority cross-layer fail-closed agreement guard + RED->GREEN tests`, analyze 0 / 2103 passed / 1 skipped) — Navigation-gate ↔ launch-route fail-closed agreement on scheme-relative / network-path
      and encoded-authority tricks: feed the SAME authority matrix (scheme-relative `//bmc/console`,
      `https:///bmc/console`, `https://evil.example\@bmc/console`, backslash-confused authorities,
      `https:%2f%2fbmc`, userinfo-bearing and control-bearing hosts) through `allowsInAppNavigation`
      and `planConsoleLaunch`, pinning that the navigation gate refuses in-app exactly when the launch
      plan routes to copyOnly / externalBrowser, and that `KvmWebViewPolicy.productionDefault` never
      navigates in-app or accepts self-signed. AUDIT FIRST: if EP-P11 / EP-P9 already pin the whole
      matrix, record the audit and add nothing; RED→GREEN only on a genuine divergence, never churn.
      Test/doc-only; no WebView/protocol dependency, no URL opened, no production TLS weakening.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/navigation_launch_route_agreement_test.dart test/features/kvm/platform/launch_plan_test.dart && flutter analyze`
              (0 issues), RED→GREEN proof only on a genuine divergence; writes limited to
              `test/features/kvm/platform/**` + the decision docs; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              no WebView/protocol dependency, no URL opened, no production TLS weakening.
      **LANDED** 2026-11-22: AUDIT first — `isSecureHttpsConsoleUri` already fails closed on the whole
      authority matrix (scheme-relative has no scheme, `https:///host` has no host, encoded delimiters /
      backslash-userinfo / bidi marks are rejected by the shared classifier), and `launch_plan_test.dart`
      / EP-P11 pin the individual layers — but NO test pinned the CROSS-LAYER agreement for the
      authority-confusion shapes (only path/fragment control chars in EP-P11). Genuine unguarded seam,
      not a live divergence: added `test/features/kvm/platform/navigation_launch_authority_confusion_agreement_test.dart`
      (4 tests) pinning both layers fail closed on the 10-target matrix, nav-agrees-with-plan one-for-one
      (EP-P11's userinfo exception excluded), and productionDefault never in-app/self-signed. Real-file
      RED: relaxed `_isHttpUriWithSchemes` to accept scheme-relative `//host` → exactly 2 new tests failed
      (`+2 -2`: classifier accepted `//bmc.example:8443/console`, opt-in plan routed it in-app while the
      nav gate refused); source restored byte-clean (SHA `74887e61…` unchanged, empty `lib/` diff),
      600-perm backup shredded → 4/4 GREEN, 247/247 targeted. Test-only, deps unchanged, TLS untouched.
      **GUARD REGISTERED** 2026-11-22 (run `auto: FEATURE #009/#021 EP-P13 guard-suite liveness registration ...`):
      the guard above was live + reachable from verify.yml's whole-tree `flutter test --coverage` but was
      absent from `canonicalGuardFiles` and every pinned epoch, so deleting / emptying / test-stripping it
      stayed GREEN. Registered under a pinned `epP13AddedGuards` epoch (length 1, disjoint from all earlier
      designations) in `test/tool/guard_suite_liveness_test.dart` (+1 pin test +1 temp-root RED→GREEN),
      included in `allDesignatedGuards` + EP-T20 completeness arithmetic. Real-file RED: dropped the
      canonical entry → exactly 3 failures (`+37 -3`: EP-P13 pin + EP-T20 completeness + EP-P13 temp-root
      liveness); source restored byte-clean (SHA `56018be5…` unchanged, empty `lib/` diff), 600-perm backup
      shredded → 40/40 GREEN. Test/tool-only, deps unchanged, TLS untouched.

<!-- rf-ideate split 2026-11-22 02:06 UTC: splits the machine-checkable half of the human-gated
     WebView/TLS rendering closeout (EP-P1/P2/P4, blocked on platform validation) of #009/#021 into
     one unblocked, test/doc-only, dependency-free, TLS-safe dept slice. EP-P8 already pins the 8-row
     Decision contract table in LAUNCH_FALLBACK.md and cross-doc final-route agreement with
     WEBVIEW_TLS_MATRIX.md; this slice re-checks that the recorded authoritative final route
     (external-browser + copy, no in-app WebView, no self-signed under productionDefault) still
     agrees with planConsoleLaunch after the latest guards, and records the outstanding human
     validation as a stable baseline. AUDIT FIRST: if the decision docs and the validation-evidence
     checklist already agree with code, record the audit and add nothing — do NOT add a WebView or
     protocol dependency, do NOT open a URL, do NOT weaken production TLS. The human validation
     remains gated and is NOT re-split. No code touched. -->

- [ ] EP-P12 Final-route decision-record ↔ code agreement guard (machine-checkable half of the
      human-gated WebView/TLS closeout): pin that the documented authoritative final render route
      (external-browser + copy, never in-app WebView, never self-signed under productionDefault) in
      `LAUNCH_FALLBACK.md` / `WEBVIEW_TLS_MATRIX.md` still agrees with `planConsoleLaunch` over the
      full flag-off signal matrix (secure HTTPS, plaintext HTTP, external-client, disabled), failing
      closed if any doc row drifts to an in-app route or if opt-in ever documents plaintext/disabled/
      non-HTML5 in-app. Record the still-outstanding human WebView/TLS validation (EP-P1/P2/P4) as a
      deferred baseline. AUDIT FIRST: if EP-P8 already pins all of this, record the audit and add
      nothing; RED→GREEN only on a genuine divergence, never churn. Test/doc-only; no WebView/
      protocol dependency, no URL opened, no production TLS weakening.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), RED→GREEN
              proof only on a genuine divergence; writes limited to `test/features/kvm/platform/**`
              + the decision docs; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no WebView/
              protocol dependency, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-21 17:59 UTC: splits the freshly-landed RP-1 in-app navigation-confinement
     contract of the blocked #009/#021 WebView closeout into one unblocked, test-only, dependency-free,
     TLS-safe dept slice. RP-1 added `allowsInAppNavigation` (secure-HTTPS + same-origin + no-userinfo
     navigation gate) to `launch_plan.dart` (merged 17:31 / 18:34); it is pinned only in isolation by
     `launch_plan_test.dart`, and EP-P9's cross-layer agreement matrix predates it (no userinfo /
     cross-origin / cross-port navigation cases). Nothing pins that the navigation gate FAILS CLOSED on
     the same hostile matrix that `planConsoleLaunch` routes to copyOnly/externalBrowser, so a one-sided
     edit could let the trusted console frame navigate to a foreign origin/port or a credential-bearing
     URL while both single-gate suites stay GREEN. Audit first; RED→GREEN only on a genuine divergence;
     no churn. The human-gated WebView adapter / TLS validation (EP-P1/P2/P4) stays human-gated and is
     NOT re-split. No code touched. -->

- [x] EP-P11 LANDED 2026-11-21 (run `auto: FEATURE #009/#021 EP-P11 navigation-gate x launch-route fail-closed agreement + RED->GREEN tests`, analyze 0 / 1964 passed / 1 skipped, test-only) — added `test/features/kvm/platform/navigation_launch_route_agreement_test.dart` (7 tests). Genuine unguarded contract found by audit: `Uri.tryParse` reports the SAME origin as the console for 8 control/separator/invisible/malformed targets (trailing ZWSP, NBSP, TAB, `%zz`, NUL-in-fragment, CRLF, NUL-in-path, raw space) — `allowsInAppNavigation` fails closed on them ONLY via the load-bearing target-side `isSecureHttpsConsoleUri` check; an origin-only gate would navigate the trusted frame to a control-bearing URL. Existing navigation isolation tests cannot catch this (their hostile targets parse to a different/null origin, so the origin check alone rejects them). Pins: same-origin control-bearing matrix fail-closed on the navigation gate; authority-hostile targets fail closed on BOTH layers; navigable ⇒ in-app-eligible under test opt-in (one-directional bridge); legitimate same-origin targets navigable + in-app on both; userinfo is navigation-only (documented initial-load exception preserved); production default never in-app / self-signed. Real-file RED proof: dropped the target-side `isSecureHttpsConsoleUri(targetUri)` check in `allowsInAppNavigation` → 3 named tests failed (`+4 -3`, ZWSP target leaked `nav=true` while the plan refused in-app); source restored byte-clean (SHA `74887e619129209ef622400a3396edc2ef76bfc8694ddaf96574e4126962ee01` unchanged, empty lib diff), 600-perm backup shredded → 7/7 GREEN, targeted platform suites 40/40. No divergence in current code — regression guard, not churn. Test-only, no `lib/`, no dependency, no WebView/protocol import, no URL opened, no production TLS weakening. Originally: feed the SAME authority matrix through `allowsInAppNavigation` and `planConsoleLaunch` and
      pin that the navigation gate returns false exactly when the launch plan refuses an in-app route
      (copyOnly / externalBrowser) — userinfo-bearing `user:pass@host` secure-HTTPS target, cross-origin
      host, cross-port target, plaintext-HTTP downgrade, CRLF/NUL/control-bearing authority — while a
      legitimate same-origin credential-free HTTPS target stays navigable in-app on both. `acceptSelfSigned`
      must never become true under `KvmWebViewPolicy.productionDefault`. Test-only, dependency-free, no
      WebView/protocol import, no URL opened, no production TLS weakening.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), RED→GREEN proof
              (temporarily weaken one navigation-gate condition → named matrix case fails; restore → clean);
              writes limited to `test/features/kvm/platform/**` (+ `lib/features/kvm/platform/**` only if a
              genuine divergence is found); `git diff --exit-code -- pubspec.yaml pubspec.lock`; no
              WebView/protocol dependency, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-20 17:10 UTC: splits the remaining production-opt-in seam of the blocked
     WebView/TLS closeout (#009/#021) into one unblocked, test-only dept slice. EP-P5 guards product
     imports/channels and EP-P6/P7/P8 the policy/doc route, but nothing fails closed if production
     code starts selecting `KvmWebViewPolicy.testOptIn` (or an opt-in with in-app/self-signed enabled)
     instead of `productionDefault`. Audit first; fix only a genuine divergence via RED→GREEN; no
     churn. The human-gated WebView adapter / TLS validation (EP-P1/P2/P4) stays human-gated and is
     NOT re-split. No code touched. -->

- [x] EP-P10 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-P10 production-opt-in-policy construction guard + RED→GREEN tests`, analyze 0 / 1699 passed / 1 skipped) — added `test/features/kvm/platform/production_optin_construction_guard_test.dart` (12 tests): a comment/string-aware pure-Dart scan of every product `lib/features/kvm/**.dart` (excluding the policy definition authority) that fails closed on any `KvmWebViewPolicy.testOptIn` / `KvmWebViewTlsMode.testOptInSelfSigned` reference or any `KvmWebViewPolicy(...)` construction with `enabled: true` / self-signed TLS, plus a real-repo pin that every production `planConsoleLaunch` call passes only `KvmWebViewPolicy.productionDefault`. Temp-root RED→GREEN (opt-in ref / enabled ctor → violation, productionDefault → clean) + real-file RED proof (planted an opt-in ref under `lib/features/kvm/views/` → real-repo invariant failed named offender `+10 -1`; removed → 12/12 GREEN, 0 artifacts). Audit found no live divergence — regression guard protecting the human WebView/TLS gate against a production opt-in bypass. Test-only, no dependency, no WebView/protocol import, no production TLS weakening. Original item: add a test-only, dependency-free guard that
      scans product `lib/features/kvm/**.dart` (comment/string-aware) and fails closed if any file
      constructs or references `KvmWebViewPolicy.testOptIn`, or builds a `KvmWebViewPolicy` with the
      in-app-WebView or self-signed-accepting flags enabled, so only `productionDefault` (flag OFF,
      strict TLS, self-signed refused) can ever reach `planConsoleLaunch` in production; legitimate
      opt-in construction confined to `test/` stays clean. RED→GREEN proof by planting an opt-in
      construction in a temp product file (opt-in → violation; productionDefault → clean) plus the
      real-repo invariant. No dependency, no WebView/protocol import, no production TLS weakening.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), RED→GREEN
              guard proof (opt-in → violation; productionDefault → clean); writes limited to
              `lib/features/kvm/platform/**` + `test/features/kvm/platform/**`; `git diff --exit-code -- pubspec.yaml`.

<!-- rf-ideate split 2026-11-20 13:04 UTC: splits the remaining machine-checkable cross-layer seam of
      the human-gated WebView closeout (#009/#021) into one unblocked, test-only dept slice. EP-P5 pins
      product imports, EP-P6 the production-route invariants, EP-P7 the human-gate docs and EP-P8
      doc↔route agreement; the platform launch-plan classifier and the model-side control-safe gate
      are two separate authority implementations, and nothing pins that they FAIL CLOSED on the same
      hostile-authority matrix. Test-only, dependency-free, no WebView import, no production TLS change;
      distinct from EP-P4/P5/P6/P7/P8 and EP-P2 (deferred human gate). No code touched. -->

- [x] EP-P9 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-P9 cross-layer authority fail-closed agreement guard + RED→GREEN tests`, analyze 0 / 1624 passed / 1 skipped) — added `test/features/kvm/platform/cross_layer_authority_agreement_test.dart` (4 tests): a 12-shape hostile-authority matrix asserted fail-closed on BOTH the platform classifier/`planConsoleLaunch` and the model layer (`KvmConsole.hasSecureLaunchUri` / `launchPlan` / `canOpenConsole`) with field-for-field agreement (route/target/acceptSelfSigned) under a stale/lying `hasSecureUri: true` signal; a 5-shape legitimate-HTTPS matrix (canonical, padded, absolute-FQDN, pure-hex IPv6 loopback, %20-in-path) staying secure + external-browser on both; and a 25-form full-URI-family agreement property. No divergence found (both layers share the fail-closed core) — regression guard against a future bare-`Uri.tryParse` reimplementation. RED proof: temporarily weakened `isSecureHttpsConsoleUri` to a bare HTTPS/host check → hostile-authority test failed (`Expected: false / Actual: true`, raw-space HTTPS host accepted); restored byte-clean (SHA `1fbda667…` unchanged, 0 probes), backup shredded → 4/4 GREEN. Test-only, no product-lib/wire/transport/fixture/dependency change, no production TLS weakening. Cross-layer authority fail-closed agreement guard for #009/#021: add a pure-Dart test
      under `test/features/kvm/platform/` that feeds one hostile-authority matrix (numeric/hex hosts,
      IPv4-mapped/IPvFuture IPv6, percent-encoded unwise/sub-delim/combining-mark/confusable, empty DNS
      label, signed/out-of-range port, CRLF/NUL/raw space, trailing-dot) through BOTH the platform
      decision layer (`planConsoleLaunch` / the fail-closed authority classifier) and the model-side
      control-safe gate, failing closed if either accepts an authority the other rejects, or if
      `acceptSelfSigned` ever becomes true under `KvmWebViewPolicy.productionDefault`. Legitimate
      canonical HTTPS targets must stay launchable on both. Prove RED by temporarily weakening one
      guard in a local copy, then GREEN. No human approval granted, no dependency, no WebView import,
      no production TLS behaviour change; the external-browser + copy fallback stays byte-for-byte.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), RED→GREEN proof;
              `git diff --exit-code -- pubspec.yaml pubspec.lock`; writes limited to
              `lib/features/kvm/platform/**` + `test/features/kvm/platform/**`; no production TLS
              behaviour change.

<!-- rf-ideate split 2026-11-20 09:00 UTC: splits the last unguarded seam of the human-gated WebView
     closeout — EP-P7 pins that both decision DOCS record the no-WebView decision/human gate, EP-P6
     pins the production ROUTE invariants in code, but nothing pins the two AGREE. This slice checks
     the doc↔code final-route contract without activating the gate. Pure test-only, dependency-free,
     no WebView import, no production TLS change; distinct from EP-P4/P5/P6/P7. -->

- [x] EP-P8 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-P8 decision-doc↔production-route consistency guard + RED→GREEN tests`, analyze 0 / 1536 passed / 1 skipped) — Decision-doc ↔ production-route consistency guard: add a pure-Dart test under
      `test/features/kvm/platform/` that derives the final route from `KvmWebViewPolicy.productionDefault`
      over the documented signal combos in `LAUNCH_FALLBACK.md` (secure HTTPS → `externalBrowser`,
      plaintext HTTP / no URI / disabled / control-unsafe → `copyOnly`, NEVER `inAppWebView`, never
      self-signed) and fails closed if the doc's route table no longer matches the code, or if
      `WEBVIEW_TLS_MATRIX.md` and `LAUNCH_FALLBACK.md` disagree on the recorded final route. No human
      approval granted, no dependency, no WebView import, no production TLS behaviour change.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), RED→GREEN proof
              (temporarily flip one doc route cell); `git diff --exit-code -- pubspec.yaml pubspec.lock`;
              writes limited to `lib/features/kvm/platform/**` + `test/features/kvm/platform/**`; no
              production TLS behaviour change.

<!-- rf-ideate split 2026-11-20 04:56 UTC: splits the human-gated WebView closeout (EP-P4) into the
     one machine-checkable, unattended-doable piece that was never carved out — a guard pinning the
     RECORDED decision docs and the no-WebView production default. It pins the human gate's contract
     WITHOUT activating it: no dependency, no WebView import, no production TLS change. Distinct
     from EP-P4 (human-written per-target evidence) and EP-P6 (runtime route invariant). -->

- [x] EP-P7 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-P7 human-gate documentation invariant guard + RED→GREEN tests`, analyze 0 / 1500 passed / 1 skipped) — Human-gate documentation invariant guard (pins the human-gated decision without
      activating it): add a pure-Dart test under `test/features/kvm/platform/` that fails closed if
      `WEBVIEW_TLS_MATRIX.md` / `LAUNCH_FALLBACK.md` no longer record (a) the resolved no-embedded-
      WebView decision (external-browser + copy final route) and (b) an explicit human-approval gate
      listing the per-target (Linux/desktop/mobile) evidence required BEFORE any `webview_flutter` /
      `url_launcher` dependency or test-only TLS opt-in — add the missing checklist/approval section
      if absent — and assert `KvmWebViewPolicy.productionDefault` keeps the WebView flag OFF. No
      human approval is granted, no dependency, no WebView import, no production TLS behaviour
      change; the external-browser + copy fallback stays byte-for-byte.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), with RED→GREEN
              proof (temporarily neuter one doc assertion); `git diff --exit-code -- pubspec.yaml pubspec.lock`
              (no dependency bump); writes limited to `lib/features/kvm/platform/**` (incl. the two
              decision docs); no production TLS behaviour change.

<!-- rf-ideate split 2026-11-20 00:52 UTC: splits the last unguarded invariant of the resolved
     no-embedded-WebView final route (external-browser + copy) into a machine-checkable property
     test. EP-P5 guards the import surface; this guards the DECISION surface so a future edit
     cannot silently re-open an in-app/WebView route or grant self-signed TLS on a fallback.
     Test-only, dependency-free, no production TLS change; distinct from EP-P4 (human-gated) and
     EP-P2 (deferred WebView adapter — do NOT pick up unattended). -->

- [x] EP-P6 LANDED 2026-11-20 (run `auto: FEATURE #009/#021 EP-P6 production-policy final-route invariant test + RED→GREEN tests`) — Production-policy final-route invariant test (closeout of the resolved no-WebView
      decision): add a pure-Dart property-style test under `test/features/kvm/platform/` that, over
      the cross-product of console signals (secure/insecure, html5/non-html5, enabled/disabled) ×
      URI forms (valid HTTPS, plaintext HTTP, external-client scheme, blank, CRLF/NUL, raw space,
      fullwidth confusable authority), asserts under the production policy (WebView flag OFF): the
      route is NEVER `inAppWebView`, `acceptSelfSigned` is NEVER true, every non-null `targetUri`
      is control-safe (`isControlSafeConsoleUri`), and any blank/control-unsafe URI degrades to
      `copyOnly` with a null target. Prove RED by temporarily weakening one guard in a local copy,
      then GREEN. This pins the human-gated decision mechanically without adding a dependency or
      a WebView import; the external-browser + copy fallback stays byte-for-byte.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues), with RED→GREEN
              proof; `git diff --exit-code -- pubspec.yaml pubspec.lock` (no dependency bump); no
              production TLS behaviour change; writes limited to `test/features/kvm/platform/**`.

<!-- rf-ideate split 2026-11-19 20:47 UTC: unblocks the unattended-doable half of the blocked
     EP-P4 WebView closeout. EP-P4 stays human-gated (per-target validation evidence); this is
     its machine-checkable guard clause, split out so a platform builder can land a genuine
     invariant without the human gate. No dependency, no production TLS change, no WebView import. -->

- [x] EP-P5 LANDED 2026-11-19 (run `auto: FEATURE #009/#021 EP-P5 no-WebView product-import policy guard + RED→GREEN tests`) — Enforce the resolved no-embedded-WebView decision with a pure-Dart product-import
      policy guard (the unattended slice of EP-P4's guard clause): a test under
      `test/features/kvm/platform/` scans every product `lib/**.dart` and fails closed if any
      imports `webview_flutter*`, `flutter_inappwebview*`, `url_launcher*` or opens a raw
      `MethodChannel`/`EventChannel` for console rendering, and pins that `pubspec.yaml` /
      `pubspec.lock` carry no such dependency. Must not flag the existing pure
      `webview_policy.dart` / `launch_plan.dart` filenames or test-only files. The resolved
      route stays external-browser + copy with the flag OFF in production.
      Dept: rf-platform
      Verify: `flutter test test/features/kvm/platform/ && flutter analyze` (0 issues);
              `git diff --exit-code -- pubspec.yaml pubspec.lock` (no dependency bump); no
              production TLS behaviour change; writes limited to `lib/features/kvm/platform/**`
              and `test/features/kvm/platform/**`.

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

- 2026-11-19 23:25 — EP-P5 LANDED (agent:redfish-automation, FEATURE #009/#021): new test-only `test/features/kvm/platform/product_import_policy_test.dart` enforces the resolved no-embedded-WebView decision — 19 tests scan every product `lib/**.dart` for `webview_flutter` / `flutter_inappwebview` / `url_launcher` imports and raw `MethodChannel` / `EventChannel` console channels, plus `pubspec.yaml` / `pubspec.lock` for forbidden deps, with comment/string/filename immunity guards. 6 assertions confirmed RED pre-fix by temporarily neutering the scanner (`Expected: non-empty / Actual: []`) → GREEN after. analyze 0 / new full-suite count; no `lib/`, no dependency, no wire/transport change, no production TLS weakening. CI already runs all tests via `flutter test --coverage`.
- 2026-11-19 19:27 — EP-M1/M2 cross-surface classifier parity (agent:redfish-automation, FEATURE #009/#021): `lib/features/kvm/platform/launch_plan.dart` now fails `isExternalClientConsoleUri` closed on a degenerate label-less authority (`vnc://./`, `ssh://../`, `ipmi://%2E%2E/`) via a shared `_hasDegenerateAuthorityHost(Uri)` helper also used by the HTTP(S) classifier family; opaque authority-less URIs and the `@odata.id` clipboard fallback unaffected. +3 RED→GREEN tests (pure classifier + KvmConsole model + KvmCapability parity). analyze 0 / 1313 passed / 1 skipped; DMTF emulator 85/85 (lib changed). No dependency, no wire/transport change, no production TLS weakening.
