# Queue rf-model (enabled in phase 2, after the epic split has ≥2 unblocked items)

Owns: `lib/features/kvm/models/**`, `lib/redfish/discovery/**`. Verify: scoped `flutter test` + RED→GREEN proof.

## Backlog (head first)

<!-- rf-ideate split 2026-11-24 02:50 UTC: carves a fresh, machine-checkable, unblocked slice of
     the still-open #009/#021 model epic (never-empty-well malformed-payload tolerance, MULTI_DEPT
     hard rule 10). RM-5/RM-22 pin VALID connect-type token lists (trim/dedup/confusables) and RM-24/
     RM-25 pin non-boolean / non-integer enablement and session scalars, but nothing drives a HOSTILE
     CONTAINER SHAPE for `ConnectTypesSupported` itself (bare string, numeric, bool, map, null, or a
     list mixing non-string members) through BOTH `fromManager` factories at once: a one-sided
     "string -> single token" coercion could populate one card's chip list while the other stays
     empty, or throw on a map/list member, with every single-factory suite GREEN. Read-only model
     characterization; the two deliberate behaviour decisions (RM-11 mixed regime, EP-S8 credentialed
     Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence,
     never churn. No code touched. -->

- [ ] RM-26 Hostile `ConnectTypesSupported` container-shape cross-factory agreement:
       over a matrix of `Manager` bodies whose Graphical/Serial/Remote console blocks carry
       `ConnectTypesSupported` as hostile non-list JSON values (scalar string `"KVMIP"`, numeric, bool,
       map, null) AND as lists mixing non-string members (int, bool, null, nested list/map) alongside a
       valid `["KVMIP", "HTML5"]` control, pin that `KvmConsole.fromManager` and
       `KvmCapability.fromManager` derive the identical fail-closed connect-type set, never throw on a
       non-list / non-string member, agree field-for-field on the rendered chip tokens / `connectTypes`
       / `supported` flags for the same body, and leave the valid control byte-exact. AUDIT FIRST: if
       both factories already route every read through one shared normalizer and derive the same set by
       construction, record the audit and add nothing; RED->GREEN only on a genuine divergence, never
       churn. Read-only model work; no wire/transport/TLS change, no dependency, no WebView/protocol
       import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no wire/TLS change, no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 22:45 UTC: carves another fresh, machine-checkable, unblocked slice of
     the still-open #009/#021 model epic (never-empty-well hostile-payload tolerance, MULTI_DEPT hard
     rule 10). RM-24 pins hostile non-boolean SERVICE ENABLED scalars and RS-10/EP-U19 pin the session
     limit at the service/render layers, but nothing drives a NON-INTEGER `MaxConcurrentSessions` scalar
     (numeric string "3"/" 3 "/"3.0"/"-1"/"1e3"/huge, double 2.5/5.0, null, list, map) through BOTH
     `fromManager` factories at once: a one-sided `kvmSessionLimit` coercion could flip
     `maxConcurrentSessions`/`maxSessions` on one card while the other stays GREEN. Read-only model
     characterization; the two deliberate behaviour decisions (RM-11 mixed regime, EP-S8 credentialed
     Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence,
     never churn. No code touched. -->

- [x] RM-25 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 RM-25 non-integer session-limit scalar coercion agreement across both fromManager factories + RED->GREEN tests`, test-only) — AUDIT FIRST confirmed `kvmSessionLimit` is the single source of truth (both `KvmConsole.fromManager` `_fromBlock` and `KvmCapability.fromManager` `_aggregateMaxSessions` delegate to it) and is pinned in isolation (`kvm_session_limit_test.dart`), while the two render cards' agreement is pinned only for VALID encodings (`kvm_card_chip_session_agreement_test.dart`: 2 / 5.0 / ' 3 '); NO existing test drove a hostile NON-INTEGER / out-of-spec `MaxConcurrentSessions` matrix through BOTH `fromManager` factories at once, so a one-sided coercion in either factory could emit a bogus negative/fractional/overflow limit on one card while the other stayed GREEN — a genuine unguarded cross-factory regression seam, no live divergence, no behaviour change, not churn. Added `test/features/kvm/kvm_session_limit_coercion_agreement_test.dart` (30 tests): a 24-case scalar matrix (valid ints 2/0, integral doubles 4.0, padded/exponent numeric strings " 3 "/"5.0"/"1e3"/" 4.0 ", plus hostile fractional 2.5, negatives -1/-1.0, nan/±infinity, >2^53 double, "1e300", "-1"/"2.5"/"abc"/blank strings, null, bool, list, map) pinning helper == console `maxConcurrentSessions` == capability `maxSessions` field-for-field with no negative/fractional/overflow emitted and no throw; the same matrix across Graphical/Serial/RemoteConsole blocks; a three-block coexisting-limit control; and a source-liveness pin that both factories keep delegating to the shared helper with no one-sided raw coercion. REAL RED: added a one-sided numeric coercion to `kvm_models.dart` `_fromBlock` (`?? (value is num && isFinite ? value.round().toInt() : null)`) under a 600-perm backup → exactly 8 named failures (`+22 -8`: fractional 2.5→3, negative -1→-1, >2^53 double→9007199254740994 cross-factory desync, three block-type loops, and the source-liveness pin), 22 GREEN; source restored byte-clean (SHA `63e441141f07cf12f01b7412b198c0a2f296ab7dea632c2fc910af118196557f` unchanged, 0 residue, empty `lib/` diff, backup shredded) → 30/30 targeted GREEN. Analyze 0; full suite 2743 passed / 1 skipped (baseline 2743 +30 new minus concurrent — see automation-tracking for the exact final count); issues validate OK; diff --check clean; deps unchanged; empty `lib/` diff; emulator skipped (test-only, no wire/transport/fixture/tool-runtime change, <7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. Original item: RM-25 Non-integer MaxConcurrentSessions scalar coercion agreement across both `fromManager` factories:
       over a matrix of `Manager` bodies whose Graphical/Remote/Serial console blocks carry
       `MaxConcurrentSessions` as hostile non-integer JSON scalars (numeric strings "3"/" 3 "/"3.0"/
       "-1"/"1e3"/huge, doubles 2.5/5.0, null, list, map) plus a valid-integer `2`/`0` control, pin
       that `KvmConsole.fromManager` and `KvmCapability.fromManager` (and the shared `kvmSessionLimit`
       helper) resolve the identical fail-closed boundary value — never throw on a non-map/list value,
       agree field-for-field on `maxConcurrentSessions`/`maxSessions` for the same body, and never emit
       a negative/fractional/overflow session limit while the valid controls stay byte-exact.
       AUDIT FIRST: if both factories already route every limit read through one shared helper and
       derive the same value, record the audit and add nothing; RED->GREEN only on a genuine divergence,
       never churn. Read-only model work; no wire/transport/TLS change, no dependency, no WebView/protocol
       import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no wire/TLS change, no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 18:43 UTC: carves another fresh, machine-checkable, unblocked slice of
     the still-open #009/#021 model epic (never-empty-well malformed-payload tolerance, MULTI_DEPT hard
     rule 10). RM-4/RM-5/RM-15/RM-18/RM-19/RM-20/RM-21/RM-22/RM-23 pin control-safety, query/fragment,
     confusables and raw `ConnectUri` preservation, but nothing drives a NON-BOOLEAN `ServiceEnabled` /
     `Enabled` JSON scalar (string "true"/"false"/"1"/"0"/"yes"/"no", numeric 1/0/2, null, list, map)
     alongside a valid-boolean control through BOTH `fromManager` factories: a one-sided coercion could
     flip `supported`/`serviceEnabled`/`canOpenConsole` on one card while the other stays GREEN. Read-only
     model characterization; the two deliberate behaviour decisions (RM-11 mixed regime, EP-S8
     credentialed Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine
     divergence, never churn. No code touched. -->

- [x] RM-24 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 RM-24 non-boolean enablement-scalar coercion agreement across both `fromManager` factories + RED->GREEN tests`, test/tool-only) — AUDIT FIRST confirmed the three enablement readers (`kvm_models.dart` `_fromBlock`, `kvm_capability.dart` `_blockEnabled`, `kvm_oem_uri.dart` `kvmOemConsoleEnabled`) are independent strict `== true` checks with no shared helper but NO existing test swept a hostile non-boolean scalar matrix through both factories + the OEM helper at once. Added `test/features/kvm/kvm_enablement_scalar_coercion_agreement_test.dart` (35 tests): 15-value scalar matrix × both `ServiceEnabled` / legacy `Enabled` keys, both `fromManager` factories + OEM helper, absent-member control, no-throw on non-map/list, source liveness pin. REAL RED: `== 1` coercion in `kvm_capability.dart` `_blockEnabled` under 600-perm backup → exactly `+32 -3` (numeric-1 via both keys + source pin), 32 GREEN; restored byte-clean (SHA `53ab173201fb430fa47f73fb29b4b7e33622ca28cde0e5516c0e43407ca5195d` unchanged, 0 residue, backup shredded) → 35/35 targeted GREEN; analyze 0; full suite 2717 passed / 1 skipped; deps unchanged; empty `lib/` diff; emulator skipped (test-only, <7 days since last green 85/85). No WebView/protocol import, no URL opened, no production TLS weakening. Original item:
       over a matrix of `Manager` bodies whose Graphical/Remote/Serial console blocks carry
       `ServiceEnabled`/`Enabled` as hostile non-boolean JSON scalars (string "true"/"false"/"1"/"0"/
       "yes"/"no", numeric 1/0/2, null, list, map, padded variants) plus a valid-boolean `true`/`false`
       control, pin that `KvmConsole.fromManager` and `KvmCapability.fromManager` coerce them
       identically (no one-sided truthiness flip), never throw on a non-map/list value, agree on
       `serviceEnabled` / `supported` / `canOpenConsole` / `supported` connect-type chips for the same
       body, and fail closed (never "enabled") on an unrecognized encoding while the valid controls
       stay byte-exact. AUDIT FIRST: if both factories already route every enablement read through one
       shared helper and derive the same flags, record the audit and add nothing; RED->GREEN only on a
       genuine divergence, never churn. Read-only model work; no wire/transport/TLS change, no
       dependency, no WebView/protocol import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no wire/TLS change, no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 14:39 UTC: carves another fresh, machine-checkable, unblocked slice of
     the still-open #009/#021 model epic (never-empty-well hostile-payload tolerance, MULTI_DEPT hard
     rule 10). RM-4/RM-5/RM-18/RM-21/EP-M7 pin the body `@odata.id` manager-source normalization and
     RM-22/EP-M5 pin connect-type token handling, but nothing pins the raw `ConnectUri` VALUE through
     BOTH `fromManager` factories: a one-sided trim/unescape/percent-normalization of a hostile
     Graphical/Remote `ConnectUri` (CRLF/NUL/raw controls/padding, bidi marks, scheme-relative
     `//host/x`, `data:`/`javascript:`/`file:` schemes) could hand a different raw string to the
     downstream fail-closed launch classifier from each card while both model suites stay GREEN.
     Read-only model characterization; the two deliberate behaviour decisions (RM-11 mixed regime,
     EP-S8 credentialed Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a
     genuine divergence, never churn. No code touched. -->

- [x] RM-23 LANDED 2026-11-23 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / full suite green) — Hostile `ConnectUri` raw-preservation cross-factory agreement:
       over a matrix of `Manager` bodies whose GraphicalConsole/RemoteConsole `ConnectUri` carries
       CRLF/NUL/raw-control and padding, bidi format marks, scheme-relative (`//host/x`) and
       non-HTTPS schemes (`data:`, `javascript:`, `file:`) plus a clean secure-HTTPS control, pin that
       `KvmConsole.fromManager` and `KvmCapability.fromManager` preserve the raw value byte-identically
       in their `connectUri`/`uri` field (no one-sided trim/unescape/percent-normalization divergence),
       agree on `hasUri`/`launchUri`/`hasSecureLaunchUri`/`launchPlan` derived from it, and leave the
       clean control unchanged — so the platform fail-closed classifier sees the same raw input
       regardless of which card produced it. AUDIT FIRST: if both factories route the raw string
       through one shared helper and derive the same launch fields, record the audit and add nothing;
       RED->GREEN only on a genuine divergence, never churn. Read-only model work; no wire/transport/TLS
       change, no dependency, no WebView/protocol import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no wire/TLS change, no WebView/protocol import, no production TLS weakening.
      LANDED: AUDIT FIRST confirmed both factories route the raw value through mirrored trim-only
              helpers (`KvmConsole._uriString` / `KvmCapability._nonEmptyString`) and shared transport
              classifiers, but NO existing test swept a hostile raw matrix (embedded C0/DEL, bidi/format
              marks, scheme-relative / data: / javascript: / file:) through BOTH factories pinning byte
              equality + derived-flag agreement — a genuine unguarded desync seam, no live divergence.
              Added `test/features/kvm/kvm_connect_uri_raw_preservation_agreement_test.dart` (21 tests).
              Real-file RED: stripped only bidi RLO in the capability `_nonEmptyString` under a 600-perm
              backup -> exactly `+19 -2` (RLO raw-agreement + bidi-rlo embedded-preservation), other 19
              GREEN; source restored byte-clean (SHA `53ab173201fb430fa47f73fb29b4b7e33622ca28cde0e5516c0e43407ca5195d`
              unchanged, 0 residue, empty `lib/` diff, backup shredded) -> 21/21 targeted GREEN. Empty deps
              diff; no WebView/protocol import, no URL opened, no production TLS weakening. This guard is
              NOT yet epoch-registered in `guard_suite_liveness_test.dart` — deferred to a future EP-T pass.

<!-- rf-ideate split 2026-11-23 10:35 UTC: carves a fresh, machine-checkable, unblocked slice of the
     still-open #009/#021 model epic (never-empty-well hostile-payload tolerance, MULTI_DEPT hard rule 10).
     RM-21 pins body-id query/fragment/userinfo, RM-20 hostile OEM enrichment and RM-15 bidi in the
     resource path, and ASCII connect-type dedup is pinned — but nothing pins mixed-case plus Unicode
     confusable / fullwidth `ConnectTypesSupported` tokens (dotted/dotless I, Kelvin sign, fullwidth
     K/V/M/I) through BOTH `fromManager` factories: a case-fold that accidentally normalized a
     confusable into a real `KVMIP`/`HTML5` token could flip `supported` on one card only. Read-only
     model characterization; the two behaviour decisions (RM-11 mixed regime, EP-S8 credentialed
     Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence,
     never churn. No code touched. -->

- [x] RM-22 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 RM-22 connect-type Unicode-confusable collapse fix + cross-factory agreement guard`, analyze 0 / full suite 2576 passed / 1 skipped / emulator 85/85; +12 new tests, lib+test) — Mixed-case + Unicode-confusable connect-type normalization agreement across both factories:
       over a matrix of `Manager` bodies whose `ConnectTypesSupported` carries mixed-case ASCII plus
       Unicode confusables and fullwidth forms (dotted/dotless I, Kelvin sign, fullwidth K/V/M/I)
       alongside a real `KVMIP`/`HTML5`, pin that `KvmConsole.fromManager` and
       `KvmCapability.fromManager` resolve byte-identical normalized connect-type lists, that neither a
       confusable nor a fullwidth token ever collapses into a real `KVMIP`/`HTML5` token to flip
       `supported`/`hasUri`, and that a padded/mixed-case real token is trimmed and case-insensitively
       deduped identically on both views. AUDIT FIRST: if the shared ASCII-`toLowerCase` dedup already
       keeps confusables distinct and both factories share it, record the audit and add nothing;
       RED->GREEN only on a genuine divergence, never churn. Read-only model work; no wire/transport/TLS
       change, no dependency, no WebView/protocol import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml
               pubspec.lock`; no wire/TLS change, no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-23 06:31 UTC: carves another fresh, machine-checkable, unblocked slice of the
     still-open #009/#021 model epic (never-empty-well hostile-payload tolerance, MULTI_DEPT hard rule 10).
     EP-M7 pins the body `@odata.id` RESOURCE PATH (dot-segments / encoded separators / repeated slashes), RM-15
     pins bidi in that resource path, and RM-18/RM-19 pin the DERIVED fallback — but nothing pins a body
     `@odata.id` carrying a QUERY (`?…`), FRAGMENT (`#…`) or embedded USERINFO (`https://u:p@host/…`), including
     control/CRLF-bearing variants: a one-sided normalization edit could strip/escape these differently in the two
     `fromManager` factories, leaking a credential or raw control code point to one card while the other fails
     closed. Read-only model characterization; the two deliberate behaviour decisions (RM-11 mixed regime,
     EP-S8 credentialed Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED→GREEN only on a genuine
     divergence, never churn. No code touched. -->

- [x] RM-21 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 RM-21 body @odata.id query/fragment/userinfo normalization agreement + RED->GREEN tests`, analyze 0 / full suite 2521 passed / 1 skipped; +19 new tests) — Body `@odata.id` query / fragment / userinfo normalization agreement across both `fromManager`
       factories: over an in-temp matrix of `Manager` bodies whose `@odata.id` carries a query string, a fragment,
       embedded userinfo, and control/CRLF-bearing variants of each (plus a clean canonical control), pin that
       `KvmConsole.fromManager` and `KvmCapability.fromManager` resolve the SAME control-safe `safeManagerUri` and
       manager identity, never leak a credential, raw control code point or delimiter into either card's source
       row, and agree with the shared `kvmManagerSourceUri` helper's normalization. A clean canonical source stays
       byte-for-byte on both views. AUDIT FIRST: if the shared helper already strips/escapes the whole URI
       identically and the safe getter gates both factories, record the audit and add nothing; RED→GREEN only on a
       genuine divergence, never churn. Read-only model work; no wire/transport/TLS change, no dependency, no
       WebView/protocol import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_manager_source_precedence_test.dart && flutter analyze`
               (0 issues), RED→GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
               no wire/TLS change, no WebView/protocol import, no production TLS weakening.

      **LANDED**: AUDIT FIRST — both factories already route the body `@odata.id` through the shared
      trims-only `kvmManagerSourceUri` helper and both expose a control-safe `safeManagerUri` gated by
      `isControlSafeConsoleUri`, so the query/fragment/userinfo matrix is normalized and classified
      uniformly by construction — no live divergence, no behaviour change. Genuine unguarded seam: no
      test drove a body `@odata.id` carrying a query, fragment or embedded userinfo (plus CRLF/NUL/
      encoded-control/encoded-`@` variants) through BOTH factories at once (EP-M7 pins the resource
      path, RM-15 bidi, RM-18/19 derived fallback; EP-P17/EP-P19 pin userinfo/query on the CONNECT-URI
      layers only). Added `test/features/kvm/kvm_manager_body_query_fragment_userinfo_agreement_test.dart`
      (19 tests): 18-case matrix (12 path query/fragment + 6 userinfo) pinning identical trimmed source,
      manager identity, control-safe source, clipboard fallback and agreement with the shared helper +
      load-bearing classifier on both views; legal encoded space/percent query controls stay
      byte-for-byte; hostile CRLF/NUL/encoded-control/encoded-delimiter userinfo variants fail closed
      to the derived path with no credential-shaped substring in either safe source. Real-file RED:
      stripped query+fragment from the capability factory's body fallback only (plausible 'OData source
      is just the resource path' refactor) under a 600-perm backup → exactly 13 named failures (all
      query/fragment cases), 6 userinfo-only + classifier tests GREEN; source restored byte-clean (SHA
      `533ed545ee344726ceb84de5e131cfc3bfb2aa7f56bb3a2c74bde08e22a2f559` unchanged, 0 residue, empty
      `lib/` diff, backup shredded) → 19/19 targeted + 230/230 sibling model suites GREEN. Test-only;
      no `lib/`, dependency, wire/TLS change, no WebView/protocol import, no URL opened, no production
      TLS weakening.


<!-- rf-ideate split 2026-11-23 02:27 UTC: carves another fresh, machine-checkable, unblocked slice of
     the still-open #009/#021 model epic (never-empty-well OEM-enrichment agreement, MULTI_DEPT hard
     rule 10). RM-3 pins registered-parser FAULT isolation (a throwing parser is skipped) and RM-7 pins
     registered-parser URI agreement across both factories, but neither drives a registered
     `KvmOemConsoleParser` that RETURNS hostile enrichment (control/CRLF-bearing URI, non-canonical /
     duplicate connect types, non-bool `enabled`, padded id) through BOTH `fromManager` factories at
     once: a one-sided "trust the parser output" edit could make the per-console card advertise a
     launchable/secure target while the capability card fails closed (the exact #009 divergence the
     shared helpers exist to prevent), with every throw/URI-agreement suite staying GREEN. Read-only
     model characterization; the two deliberate behaviour decisions (RM-11 mixed regime, EP-S8
     credentialed Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine
     divergence, never churn. No code touched. -->

- [x] RM-20 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 RM-20 registered-OEM hostile-enrichment normalization agreement + RED->GREEN tests`, analyze 0 / targeted 8/8 / full 2462 passed / 1 skipped, test-only) — Registered-OEM-parser hostile-enrichment normalization agreement across both `fromManager`
       factories: over a registered `KvmOemConsoleParser` whose `parse` returns hostile enrichment
       (control/CRLF-bearing URI, non-canonical / duplicate connect types, non-bool enabled, padded id),
       pin that `KvmConsole.fromManager` and `KvmCapability.fromManager` normalize the vendor output
       through the SAME shared control-safe URI / connect-type / enablement helpers, so both cards
       agree on supported / serviceEnabled / resolved launch URI / chips / session limit and never let
       a registered vendor leak a raw control code point or badge an unsafe/secure-mismatched target.
       A clean parser keeps its documented enrichment byte-for-byte. AUDIT FIRST: if both factories
       already route vendor enrichment through one shared normalizer over the whole matrix, record the
       audit and add nothing; RED->GREEN only on a genuine divergence, never churn. No WebView/protocol
       import, no dependency, no production TLS weakening.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_oem_registry_test.dart test/features/kvm/kvm_model_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
               no wire/TLS change, no WebView/protocol import, no production TLS weakening.
       **LANDED** 2026-11-23: AUDIT FIRST — both factories already normalize parsed vendor enrichment through the same
       shared helpers (`_uriString` / `_nonEmptyString` trim, `_normalizedConnectTypes` / `_appendTypes` dedup), and
       RM-7 already pins launch-URI/classification agreement over a scheme matrix while `_MessyVendorParser` pins
       console-side normalization — so there is no live divergence. Genuine unguarded seam: nothing drove the full
       hostile-enrichment matrix (padded / blank / CRLF-bearing URI, duplicate / blank / mixed-case vendor types,
       enablement flips, padded manager id) through BOTH factories while pinning the normalized STORED fields.
       Added `test/features/kvm/kvm_oem_hostile_enrichment_agreement_test.dart` (8 tests): both factories store the
       same normalized vendor URI and agree on `launchUri` / `hasUri` / all transport classifiers (a CRLF target is
       stored verbatim yet never badged secure); the console card trims/drops-blank/case-insensitive-dedups vendor
       connect types keeping the first spelling, with a blank-only list yielding no chips; parsed `serviceEnabled`
       drives `supported` / `serviceEnabled` / `canOpenConsole` identically on both cards; a clean parser keeps its
       enrichment byte-for-byte; and a padded `managerId` stays byte-exact on both surfaces.
       Real-file RED: dropped `_normalizedConnectTypes(...)` on the parsed vendor path in `kvm_models.dart` under a
       600-perm backup → exactly the 2 new connect-type tests failed (6 others GREEN), plus the 2 pre-existing sibling
       OEM normalization tests in `kvm_oem_registry_test.dart` failed — proving the guard is live and non-vacuous;
       source restored byte-clean (SHA `85af8a1c…` unchanged, empty `lib/` diff, backup shredded) → 8/8 GREEN.
       `dart format` clean; analyze 0; full suite 2462 passed / 1 skipped (baseline 2454 +8 mine); issues validate OK;
       diff --check clean; deps unchanged; empty `lib/` diff; emulator skipped (test-only, <7 days since last green
       85/85); no WebView/protocol import, no URL opened, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 22:24 UTC: carves a fresh, machine-checkable, unblocked slice of the
     still-open #009/#021 model epic (never-empty-well malformed-payload tolerance, MULTI_DEPT hard
     rule 10). RM-15 pins bidi/control in the `@odata.id` RESOURCE PATH and EP-M5 pins `ConnectTypesSupported`
     normalization, while RM-18/RM-19 pin the RAW DERIVED source fallback when the MANAGER ID itself is
     hostile — but nothing pins the BODY `@odata.id` RESOURCE-PATH side of the shared `kvmManagerSourceUri`
     helper when it is present yet structurally hostile (dot-segments `.` / `..`, percent-encoded separators
     `%2F` / `%5C`, repeated `//`, trailing control/whitespace, non-string), as consumed by BOTH
     `KvmConsole.fromManager` and `KvmCapability.fromManager`. A one-sided normalization edit could make the
     per-console and per-manager cards advertise different manager identities or leak a raw traversal / control
     code point while every value-agreement suite stays GREEN. Read-only model characterization; the two
     deliberate behaviour decisions (RM-11 mixed regime, EP-S8 credentialed Primary) stay blocked and are NOT
     re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] EP-M7 LANDED 2026-11-23 (run `auto: FEATURE #009/#021 EP-M7 body @odata.id resource-path normalization agreement + RED->GREEN tests`, analyze 0 / 2417 passed / 1 skipped) — Body `@odata.id` resource-path normalization agreement across both `fromManager` factories:
       over an in-temp matrix of `Manager` bodies whose `@odata.id` is present but structurally hostile
       (dot-segments `.` / `..`, percent-encoded separators `%2F` / `%5C`, repeated `//`, trailing
       control/whitespace, non-string), pin that `KvmConsole.fromManager` and `KvmCapability.fromManager`
       resolve the SAME control-safe `safeManagerUri` and manager identity, never emit a raw traversal or
       control code point, and agree with the shared source helper's normalization. AUDIT FIRST: if both
       factories already share one normalizer over the whole matrix, record the audit and add nothing;
       RED->GREEN only on a genuine divergence, never churn. This is the BODY-path side; the DERIVED fallback
       (RM-18/RM-19) is already covered — no behaviour change folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart && flutter analyze` (0 issues),
               RED->GREEN proof only on a genuine divergence.

<!-- rf-ideate split 2026-11-22 14:17 UTC: carves a fresh, machine-checkable, unblocked slice of the
      still-open #009/#021 epic. RM-16 pins hostile VALUE encodings of `ServiceEnabled`/`Enabled`
      (string/num/null/list/map/control) and RM-8/RM-13 pin the canonical tri-state across both
      `fromManager` factories, but nothing pins DUPLICATE / case-variant KEY collisions inside one
      console block (`ServiceEnabled` vs `serviceenabled`, `Enabled` vs `enabled`,
      `MaxConcurrentSessions` vs `maxconcurrentsessions`) with conflicting values — a hostile BMC (or a
      parser that lowercases keys late) could make `KvmConsole.fromManager` and `KvmCapability.fromManager`
      resolve different enablement/URI/session aggregates from the SAME payload. Read-only
      characterization; the two deliberate behaviour decisions (RM-11 mixed regime, EP-S8 credentialed
      Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence,
      never churn. No code touched. -->

<!-- rf-ideate split 2026-11-22 18:21 UTC: carves a fresh, machine-checkable, unblocked slice of the
      still-open #009/#021 epic. RM-4 / RS-5 pin the control-safe source getter (`safeManagerUri`) and
      the three-level source precedence (caller override -> body @odata.id -> derived
      /redfish/v1/Managers/<id>), including hostile-id pct-encoding on the safe getter — but nothing
      pins the RAW derived fallback in the shared `kvmManagerSourceUri` helper and the two `fromManager`
      factories that call it when the manager ID itself is hostile (padded, CRLF/NUL/control-bearing,
      non-ASCII or blank) and the body @odata.id is absent / blank / non-string. A one-sided normalization
      edit could make the per-console and per-manager cards show different source identities or leak a raw
      control code point into a derived path while every value-agreement suite stays GREEN. Read-only model
      characterization; the two deliberate behaviour decisions (RM-11 mixed regime, EP-S8 credentialed
      Primary) stay blocked and are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence,
      never churn. No code touched. -->

- [x] RM-18 LANDED 2026-11-22 (auto: FEATURE — derived-fallback manager-id control-safety agreement + live gap fix, analyze 0 / 2364 passed / 1 skipped) — AUDIT FIRST: both `fromManager` factories share `kvmManagerSourceUri` + the `safeManagerUri` gate, so cross-factory AGREEMENT holds by construction, but no existing test swept a hostile `managerId` through the DERIVED fallback (`@odata.id` absent / blank / non-string) on both views (`kvm_model_test.dart` uses the direct constructor with an explicitly hostile source; `kvm_manager_source_bidi_agreement_test.dart` always uses clean `managerId: 'BMC'`). Added `test/features/kvm/kvm_manager_id_control_safety_agreement_test.dart` (77 tests): 9 hostile-id values (padded / CRLF / NUL / tab / bidi RLO / ZWSP / NBSP / non-ASCII / blank) × 8 unusable-`@odata.id` shapes (7 value cases + truly absent key), pinning byte-identical derived `sourceManagerUri` + control-safe `safeManagerUri` on both views and zero raw C/Z code points, plus 4 byte-exact fallback literals and a load-bearing gate case. GENUINE LIVE DEFECT found: a blank `managerId` with unusable `@odata.id` disclosed `/redfish/v1/Managers/   ` (raw trailing spaces) on both cards because `_controlSafeTrimmedUri` trims the whole URI before its char scan so the gate passed while the getter returned the untrimmed path. Fixed the shared helper `kvmManagerSourceUri` to build the derived fallback via a new `kvmManagerDerivedSource()` that trims + `Uri.encodeComponent`s the id with an empty→`manager` guard (identity for ordinary ids), so both views are safe by construction and the getters' own encoding stays defence-in-depth. Real-file RED: temporarily reverted the fix under a 600-perm backup → exactly 9 named failures (all blank-id cases), 68 others GREEN; restored byte-clean (SHA `fe7cb773…` unchanged, backup shredded) → 77/77 GREEN. `lib/` change ⇒ full DMTF emulator re-run 85/85 GREEN (pinned 23d21f9). No dependency, no WebView/protocol import, no URL opened, no production TLS weakening, no behaviour decision folded in. Original item: Manager-ID control-safety in the derived source fallback, cross-factory agreement: over
       one manager matrix whose `@odata.id` is absent / blank / non-string and whose `managerId` is
       padded, CRLF/NUL/control-bearing, non-ASCII or blank, pin that `KvmConsole.fromManager` and
       `KvmCapability.fromManager` derive the SAME trimmed, control-free source identity (fail-closed
       `/redfish/v1/Managers/<id>` fallback with the id safely encoded), that no raw control code point
       or stray whitespace leaks into either card's source, and that each card's `safeManagerUri` agrees
       with the other for the same payload. AUDIT FIRST: if the shared helper already normalizes and the
       safe getter already gates the derived path identically on both factories, record the audit and add
       nothing; RED->GREEN only on a genuine divergence, never churn. Read-only model work; no wire/
       transport/TLS change, no dependency, no WebView/protocol import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_manager_source_precedence_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
               no wire/TLS change, no WebView/protocol import, no production TLS weakening.

- [x] RM-17 LANDED 2026-11-22 (auto: FEATURE — key-collision guard, analyze 0 / 2239 passed / 1 skipped) — AUDIT FIRST: both `fromManager` factories read `ServiceEnabled` / `Enabled` / `MaxConcurrentSessions` with exact-case keys, so they already agree for every key variant; the only prior agreement guards fed hostile VALUES through canonical keys, so nothing pinned collision KEY agreement (genuine unguarded seam, no live drift). Added `test/features/kvm/kvm_key_collision_agreement_test.dart` (7 tests): canonical control + four conflicting collision spellings (lower/upper/mixed-case/padded) + non-canonical-only fail-closed + multi-block aggregate, each pinning byte-identical `serviceEnabled` / `supported` / launch URI / chips / `maxSessions` on both views, canonical keys authoritative and no raw key text leaking. Real-file RED: mutated `_fromBlock` to lowercase keys late (`block.map(k.toLowerCase())`) under a 600-perm backup — exactly 5 named cases failed (`+2 -5`: 3 collision sets 5→99, non-canonical-only false→true, multi-block true→false), canonical control + padded-key set GREEN; restored byte-clean (SHA `85af8a1c…`, 0 residue, empty `lib/` diff, backup shredded) → 7/7 GREEN. Original item: Duplicate / case-variant console-block key collision agreement across both `fromManager`
       factories: over one manager whose Graphical/Serial/Remote blocks carry duplicate and case-variant
       `ServiceEnabled` / `Enabled` / `MaxConcurrentSessions` keys with conflicting values (plus a canonical
       single-key control), pin that `KvmConsole.fromManager` and `KvmCapability.fromManager` resolve the
       SAME `supported` / `serviceEnabled`, launch URI, connect-type chips and `maxSessions`, with no raw
       key leaking into a rendered payload and non-canonical/colliding encodings failing closed rather than
       one factory winning a different value. AUDIT FIRST: if the shared helpers already normalize keys
       identically across both factories, record the audit and add nothing; RED->GREEN only on a genuine
       divergence, never churn. Read-only model work; no wire/transport/TLS change, no dependency, no
       WebView/protocol import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_enablement_encoding_agreement_test.dart && flutter analyze`
               (0 issues), RED->GREEN proof only on a genuine divergence; writes limited to
               `lib/features/kvm/models/**` + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml pubspec.lock`;
               no wire/TLS change, no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 10:12 UTC: carves a fresh, machine-checkable, unblocked slice of the
     still-open #009/#021 epic. RM-8/RM-13 pin the canonical enablement tri-state (bool flags, truthy-wins)
     across both factories, but nothing pins the NON-BOOL encoding seam at the model surface: string / numeric
     / null / list / map / control-bearing `ServiceEnabled` / `Enabled` / legacy enablement values could make
     the two `fromManager` factories disagree on enablement, URI and aggregates. Read-only characterization;
     the two deliberate behaviour decisions (RM-11 mixed regime, EP-S8 credentialed Primary) stay blocked and
     are NOT re-split. AUDIT FIRST; RED->GREEN only on a genuine divergence, never churn. No code touched. -->

- [x] RM-16 LANDED 2026-11-22 (run, agent:redfish-automation — FEATURE #009/#021, analyze 0 / targeted 34/34 / full suite green (count in automation-tracking), test-only) — Hostile enablement-flag encoding agreement across both `fromManager` factories: feed
       `KvmConsole.fromManager` and `KvmCapability.fromManager` one manager matrix whose Graphical/Serial/
       Remote blocks carry non-canonical `ServiceEnabled` / `Enabled` / legacy enablement values (`"true"`,
       `"false"`, `"TRUE"`, padded booleans, `1`/`0`, null, list/map, control-bearing strings) plus a
       canonical-bool control, and pin that both factories agree byte-for-byte on `supported` /
       `serviceEnabled`, the resolved launch URI, aggregated connect types and session limit — treating
       non-canonical encodings as unknown/disabled (fail closed), never as truthy, while preserving the
       documented truthy-wins behaviour for canonical bools (RM-8/RM-13 unchanged). AUDIT FIRST: if the
       shared helper already normalizes every hostile encoding identically across both factories, record the
       audit and add nothing; RED->GREEN only on a genuine divergence, never churn. Read-only model work; no
       wire/transport/TLS change, no dependency, no WebView/protocol import, no behaviour decision folded in.
       Dept: rf-model
       Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart && flutter analyze`
               (0 issues), RED->GREEN only on a genuine divergence; writes limited to `lib/features/kvm/models/**`
               + `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no wire/TLS change,
               no WebView/protocol import, no production TLS weakening.

<!-- rf-ideate split 2026-11-22 06:09 UTC: carves a fresh, machine-checkable, unblocked slice of the
     blocked #009/#021 epic. The control-safe classifier family is heavily guarded for CRLF/NUL/TAB/
     NBSP/ZWSP and degenerate authorities (RM-5/RM-12), but nothing pins the BIDI / RTL-override and
     homoglyph-host corner of the same fail-closed contract at the model surface across BOTH
     `fromManager` factories. This is a read-only characterization/regression guard; the two
     deliberate behaviour decisions (RM-11 mixed regime, EP-S8 credentialed Primary) stay blocked and
     are NOT re-split. AUDIT FIRST; RED→GREEN only on a genuine divergence, never churn. No code
     touched. -->

- [x] RM-15 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 RM-15 bidi/confusable manager-source cross-factory agreement guard + RED->GREEN tests`, analyze 0 / full suite green (count in automation-tracking)) — Unicode bidi / RTL-override and confusable-host fail-closed agreement across both
      `fromManager` factories: over one manager matrix whose `ConnectUri` and `@odata.id` authorities
      carry U+202E/U+202D (RLO/LRO), U+2066..U+2069 isolates, U+200E/U+200F direction marks, homoglyph
      Cyrillic/Greek host labels and fullwidth digits, pin that `KvmConsole.fromManager` and
      `KvmCapability.fromManager` resolve the SAME fail-closed classification (no launchable primary,
      no secure-HTTPS badge, no external-client copy affordance) and that `safeManagerUri` /
      `clipboardTargetUri` never emit a bidi/invisible control marker onto a rendered row or a
      clipboard payload. AUDIT FIRST: if the shared control-safe classifier already rejects every
      Unicode Cf / confusable across these surfaces and both factories agree byte-for-byte, record
      the audit and add nothing; RED→GREEN only on a genuine divergence, never churn. Read-only model
      work; no transport/wire/TLS change, no dependency, no WebView/protocol import, no behaviour
      decision folded in.
      Dept: rf-model
      Verify: `flutter test test/features/kvm/kvm_model_test.dart test/features/kvm/kvm_capability_test.dart test/features/kvm/kvm_manager_source_precedence_test.dart && flutter analyze`
              (0 issues), RED→GREEN only on a genuine divergence; writes limited to
              `test/features/kvm/**`; `git diff --exit-code -- pubspec.yaml pubspec.lock`; no
              wire/TLS change, no WebView/protocol import, no production TLS weakening.
      **LANDED** 2026-11-22: AUDIT first — the shared `isControlSafeConsoleUri` gate already rejects
      every Unicode `C`/`Z` bidi format mark (RLO/LRO, isolates, direction marks, WJ, BOM) via
      `_rawUriForbiddenChars`, and `_authorityHasNonAscii` rejects confusable hosts, so both
      `fromManager` factories already agree and fail closed — no live divergence. Genuine unguarded
      seam: no test fed the bidi FORMAT family through an `@odata.id` RESOURCE PATH (where the
      authority-scoped non-ASCII rule does not apply) across both factories, nor pinned
      confusable-host cross-factory agreement. Added
      `test/features/kvm/kvm_manager_source_bidi_agreement_test.dart` (30 tests): bidi marks in
      `@odata.id` sanitize to the same clean fallback on both views, bidi/confusable authorities get
      no secure badge / copyable target on both, confusable resource paths stay byte-identical, a
      combined-hostile manager fully agrees, and the load-bearing classifier rejects the bidi path.
      Real-file RED: dropped `\p{C}` from `_rawUriForbiddenChars` → exactly 12 new tests failed
      (`+18 -12`: all 10 bidi `@odata.id` cases + combined + classifier; confusable authority/path
      cases stayed GREEN because the authority-non-ASCII rule and category-`L` confusables are
      unaffected); source restored byte-clean (SHA `74887e61…` unchanged, empty `lib/` diff),
      600-perm backup shredded → 30/30 GREEN. Registered under a pinned `rm15AddedGuards` epoch in
      `test/tool/guard_suite_liveness_test.dart` (+1 pin test +1 temp-root RED test; 68/68 targeted).
      Test/tool-only, dependency-free, no WebView/protocol import, no URL opened, no TLS weakening.

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

- [x] RM-13 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 RM-13 enablement-regime decision-boundary guard + RED->GREEN tests`, analyze 0 / 2072 passed / 1 skipped) — Mixed-regime enablement tri-state — decision-boundary characterization guard (unblocked
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
      **LANDED** 2026-11-22: `test/features/kvm/kvm_enablement_regime_boundary_test.dart` (8 tests) — 4 agreeing-regime byte-for-byte agreement cases (all-unknown / disabled-vs-enabled / contradictory truthy-wins / integral-double limit) + 4 RECORD-only mixed-regime divergence cases (SSH serial / plaintext HTTP / flag-absent secure remote / legacy Enabled:true) that assert the divergence + direction but never bless either side as expected (RM-11 stays a deferred human decision). AUDIT: agreeing regimes already pinned by RM-10/EP-S7, but the mixed-regime divergence was prose-only — an enabled-first refactor erased it with every RM-10/EP-S7 guard GREEN. Real-file RED: inserted an enabled-first pass in `_standardConnectUri` → exactly `+4 -4` (only the 4 mixed tests), restored byte-clean (SHA `533ed545…`, empty lib diff), 600-perm backup shredded → 8/8 GREEN. Registered in `canonicalGuardFiles` (46→47) + pinned `rm13AddedGuards` (length 1, disjoint from all earlier epochs) in `test/tool/guard_suite_liveness_test.dart` (+1 pin test, completeness arithmetic, temp-root RED; real-file RED dropped canonical entry → 3 failures, restored byte-clean SHA `8014e306…`, backup shredded → 32/32 GREEN). Test/tool-only, no lib/, no dependency, no WebView/protocol import, no production TLS weakening; emulator skipped.

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

- [x] EP-M4 LANDED 2026-11-22 (run `auto: FEATURE #009/#021 EP-M4 RemoteConsole-only + explicit-disable cross-view parity guard + RED->GREEN tests`, test-only) — RemoteConsole-only + explicit-disable cross-view detection/enablement/URI/limit/strategy parity: feed
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
- 2026-11-23 00:20 UTC — EP-M7 LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_manager_body_path_normalization_agreement_test.dart` (16 tests). AUDIT FIRST: both `KvmConsole.fromManager` and `KvmCapability.fromManager` already route the body `@odata.id` through the shared `kvmManagerSourceUri` and expose the same control-safe `safeManagerUri`, so agreement holds BY CONSTRUCTION — no live divergence, no behaviour change. Genuine unguarded seam: RM-15 (bidi/format/confusable), RM-18/RM-19 (hostile managerId DERIVED fallback), RS-5 (3-level precedence) and `launch_plan_test` (CONNECT-URI authorities) each cover a corner, but nothing drove the structurally hostile BODY RESOURCE-PATH family (`.`/`..`, `%2F`/`%5C`, repeated `//`, trailing control/whitespace, non-string) through BOTH factories pinning identical trimmed source, identical control-safe `safeManagerUri`, identical manager identity and agreement with the shared normalizer. Real-file RED: a one-sided dot-segment collapse in `KvmCapability.fromManager` → exactly 3 named failures (`+13 -3`: single/parent dot-segment + leading traversal; the other 13 GREEN); source restored byte-clean (SHA `533ed545…` unchanged, 0 residue, empty `lib/` diff, 600-perm backup shredded) → 16/16 GREEN. analyze 0; full suite 2417 passed / 1 skipped (baseline 2401 +16); issues validate OK; diff --check clean; deps unchanged; test-only, emulator skipped (<7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening.
- 2026-11-22 — EP-M4 RemoteConsole-only + explicit-disable cross-view parity guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_remote_console_disable_parity_test.dart` (9 tests). AUDIT FIRST: each field was pinned in isolation (RM-8/RM-10/RM-16 tri-state; EP-S7/RM-10 capability.uri↔pickPrimary; one capability-only "disabled RemoteConsole not supported" case), but no test drove RemoteConsole-focused bodies through BOTH `KvmConsole.fromManager` and `KvmCapability.fromManager` at once pinning `supported`/`serviceEnabled`/resolved URI/aggregated types/session limit AND per-console `launchStrategy`/openability together. No live divergence — regression guard, not churn. Pins enabled-only, `ServiceEnabled:false`, legacy `Enabled:false`, contradictory truthy-wins, Graphical↔Remote both precedence orders, disabled Serial+Remote, OEM-disabled+Remote, and the all-disabled graphical-first fallback; a BMC-disabled standard block fails closed on BOTH views. Real-file RED: dropped `remoteEnabled` from `KvmCapability.fromManager`'s `supported` → exactly 5 named agreement tests failed (`+4 -5`), the 4 disable/control cases stayed GREEN; source restored byte-clean (SHA `533ed545ee344726ceb84de5e131cfc3bfb2aa7f56bb3a2c74bde08e22a2f559` unchanged, 0 residue, empty `lib/` diff, 600-perm backup shredded) → 9/9 GREEN. `dart format` clean; analyze 0; deps unchanged; test-only, emulator skipped (<7 days since last green 85/85); no WebView/protocol import, no URL opened, no production TLS weakening. New guard NOT yet in `test/tool/guard_suite_liveness_test.dart` — next tooling head EP-T30.
- 2026-11-22 — RM-16 hostile enablement-flag encoding agreement guard LANDED (agent:redfish-automation, FEATURE #009/#021, test-only): added `test/features/kvm/kvm_enablement_encoding_agreement_test.dart` (34 tests). AUDIT FIRST: both `KvmConsole.fromManager` (`_fromBlock`) and `KvmCapability.fromManager` (`_blockEnabled`/`_explicitlyDisabled`) derive enablement from the identical `member == true` rule, and the OEM path uses the shared `kvmOemConsoleEnabled` — so every non-canonical encoding (string "true"/"TRUE", padded, int 1/0, double 1.0, null, list, map, control-bearing) fails closed to "not enabled" on BOTH views while canonical-bool truthy-wins (RM-8/RM-13) is preserved. No live divergence — regression guard, not churn. The only prior coverage was one single-view `ServiceEnabled: 'true'` case in `kvm_model_test.dart`; nothing pinned cross-factory agreement over the full encoding matrix, so a one-sided "coerce string/number to bool" refactor could desync the capability card from the console card while every single-surface suite stayed GREEN. Pins the hostile matrix on `ServiceEnabled`, on legacy `Enabled`, on the OEM console block, canonical true/false controls and truthy-wins — byte-for-byte agreement of `serviceEnabled` / `supported` / openability / connect types / session limit and canonical-URI agreement. Real-file RED: mutated `KvmCapability._blockEnabled` to accept `== 'true'` on one side → exactly the 2 string-"true" cross-factory cases failed (`+32 -2`), all 32 others GREEN; source restored byte-clean (SHA `533ed545…` unchanged, 0 residue, empty lib diff), 600-perm backup shredded → 34/34 GREEN. Test-only, no `lib/`, no dependency, no wire/TLS change, no WebView/protocol import, no URL opened, no production TLS weakening.
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
