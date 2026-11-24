// EP-T12 (epic #009/#021): machine-checkable closeout of the "who guards the
// guards" remainder. The repo now relies on a family of KVM safety guard tests
// (RU-2/EP-T9 copy, EP-T11 URI-parse, EP-T8 source-display, EP-P5 imports,
// EP-P6/P7/P8 policy/doc, EP-T7 doctor, LA-1 assets, EP-T6 unattended) — but
// nothing failed closed if one of those guard files was later deleted, emptied,
// stripped of its test cases, or silently de-invoked from the standard CI run.
// This pure-Dart guard enumerates the established guard files and fails closed
// on any such drift, so a future edit cannot silently disable a safety net.
//
// EP-T14 (epic #009/#021) extends this canonical set with the safety guards that
// landed AFTER EP-T12 (queue-item schema, production-opt-in construction,
// cross-layer authority agreement, flag-off false-claim, viewer disclosure,
// real-provider wiring and session audit/identity invariants). Without this
// extension, deleting / emptying / test-stripping one of those newer guards (or
// de-invoking it from CI) would stay GREEN. A dedicated test pins the extension
// itself so a future edit cannot quietly drop a guard back out of the set.
//
// EP-T15 (epic #009/#021) extends the set once more with the six behavioral
// regression guards that landed AFTER EP-T14 (direct-construction KVMIP
// fallback, manager-source precedence, multi-vendor enablement, controller
// dispose-after-async-gap, service manager-identity and card cross-surface
// agreement). All six are live, checked-in test files reachable from the
// whole-tree CI run, but none was liveness-checked: deleting / emptying /
// test-stripping one of them would stay GREEN. A dedicated pinned subset makes
// the extension itself fail closed against a future silent drop.
//
// EP-T16 (epic #009/#021) extends the set once more with the three widget-level
// regression guards that landed AFTER EP-T15 (cross-surface clipboard-target
// agreement, in-list reload indicator, in-list stale-data refresh warning).
// Each is a live, checked-in test file reachable from the whole-tree CI run, but
// none was liveness-checked: deleting / emptying / test-stripping one of them
// would stay GREEN. A dedicated pinned subset (disjoint from EP-T14/EP-T15) makes
// the extension itself fail closed against a future silent drop.
//
// EP-T17 (epic #009/#021) extends the set once more with the four safety guards
// that landed AFTER EP-T16 (service lookup-key normalization, OEM depth-bound
// agreement, populated-ListView four-state agreement, validation-evidence
// checklist). Each is a live, checked-in test file reachable from the whole-tree
// CI run, but none was liveness-checked: deleting / emptying / test-stripping
// one of them would stay GREEN. A dedicated pinned subset (disjoint from
// EP-T14/EP-T15/EP-T16) makes the extension itself fail closed against a future
// silent drop.
//
// EP-T18 (epic #009/#021) extends the set once more with the three safety guards
// that landed AFTER EP-T17 (service capability↔primary agreement, viewer
// URI-surface agreement, capability↔primary secure-URI agreement). Each is a
// live, checked-in test file reachable from the whole-tree CI run, but none was
// liveness-checked: deleting / emptying / test-stripping one of them would stay
// GREEN. A dedicated pinned subset (disjoint from EP-T14/EP-T15/EP-T16/EP-T17)
// makes the extension itself fail closed against a future silent drop.
//
// EP-T19 (epic #009/#021) extends the set once more with the three safety guards
// that landed AFTER EP-T18 (security-first × enabled-block tri-state agreement,
// navigation-gate ↔ launch-route fail-closed agreement, three-surface launch
// target agreement). Each is a live, checked-in test file reachable from the
// whole-tree CI run, but none was liveness-checked: deleting / emptying /
// test-stripping one of them would stay GREEN. A dedicated pinned subset
// (disjoint from EP-T14/EP-T15/EP-T16/EP-T17/EP-T18) makes the extension itself
// fail closed against a future silent drop.
//
// EP-T20 (epic #009/#021) closes a CONFIRMED "who guards the guards" registry
// gap: EP-T19 pinned canonicalGuardFiles to 34, but EP-M6 later added
// `kvm_oem_uri_shadow_agreement_test.dart` DIRECTLY to the set with no pinned
// epoch subset, and three genuine safety guards audited live and reachable from
// the whole-tree CI run (`kvm_lifecycle_parity_test.dart`,
// `kvm_notice_surface_audit_test.dart`, `platform/webview_policy_test.dart`)
// were absent from the set entirely — so dropping / emptying / test-stripping
// / CI-de-invoking any of them stayed GREEN. EP-T20 adds a pinned `epT20AddedGuards`
// subset (disjoint from EP-T14/15/16/17/18/19), AND a registry-completeness
// invariant requiring canonicalGuardFiles to equal the union of the EP-T12
// initial set and every pinned epoch subset in BOTH directions, so no guard can
// be silently dropped or sit unpinned in a future run.
//
// EP-M5 (epic #009/#021) extends the set with the hostile `ConnectTypesSupported`
// cross-factory agreement guard. The two model normalizers already agree over a
// small single-block matrix, but nothing pinned agreement over the full hostile
// matrix (nested list/map entries, control-bearing values) or over the
// multi-block enabled-preference / all-disabled fallback — deleting / emptying /
// test-stripping that guard would otherwise stay GREEN. A pinned `epM5AddedGuards`
// subset (disjoint from every earlier epoch) makes the extension fail closed.
//
// EP-S2 (epic #009/#021) extends the set with the `pickPrimary` secure-HTTPS tier
// precedence guard. Existing selection tests pin secure-vs-plaintext graphical
// and secure-vs-external-client, but none pins that a secure-HTTPS console of
// ANY type outranks an OPENABLE plaintext graphical — swapping tiers 2/3 of the
// return expression would pass every existing test while badging a plaintext
// console Primary while a secure one exists (issue #021). Deleting / emptying /
// test-stripping that guard would otherwise stay GREEN; a pinned
// `epS2AddedGuards` subset (disjoint from every earlier epoch) fails closed.
//
// EP-T21 (epic #009/#021) closes a CONFIRMED "who guards the guards" gap: the
// RM-12 `kvm_external_client_from_manager_parity_test.dart` safety guard (both
// KVM factories classify the full hostile URI matrix identically through the
// real `fromManager` pipeline) landed after EP-T20 with 5 live cases reachable
// from the whole-tree CI run, but was never added to `canonicalGuardFiles` or
// any pinned epoch set — so deleting / emptying / test-stripping that guard
// stayed GREEN. EP-T21 adds it to the canonical set under a pinned
// `epT21AddedGuards` epoch (disjoint from every earlier designation) with a pin
// test and a temp-root RED→GREEN proof, keeping the EP-T20 registry-completeness
// invariant green.
//
// EP-T22 (epic #009/#021) closes a CONFIRMED "who guards the guards" gap for the
// three cross-cutting safety guards that the EP-T12 header already names as part
// of the family (LA-1 assets, EP-T6 unattended) plus the #010 credential-leak
// audit: `test/tool/asset_guard_test.dart` (15 cases),
// `test/tool/unattended_guard_test.dart` (16 cases) and
// `test/security/credential_leak_audit_test.dart` (3 cases) are live, checked-in
// test files reachable from verify.yml's whole-tree `flutter test --coverage`,
// yet NONE was ever added to `canonicalGuardFiles` or any pinned epoch set — so
// deleting / emptying / test-stripping one of them stayed GREEN. (verify.yml
// runs the `asset_guard.dart` / `unattended_guard.dart` TOOLS directly, but that
// does not detect removal or neutering of their TEST files.) EP-T22 adds all
// three to the canonical set under a pinned `epT22AddedGuards` epoch (disjoint
// from every earlier designation) with a pin test and a temp-root RED→GREEN
// proof, keeping the EP-T20 registry-completeness invariant green.
//
// RM-14 (epic #009/#021) registers the OEM console-block documented
// direct-key-precedence guard. `kvmOemConsoleBlock`'s two-pass search order
// (direct `kvm`/`console`/`webconsole` key before a recursive walk into nested
// vendor blocks) was documented but had no test that carried BOTH a direct and
// a nested console in one payload, so a reversed-order refactor re-pointed both
// views' OEM endpoint and enablement flag with every existing single-console
// OEM test GREEN. Registering it under a pinned `rm14AddedGuards` subset makes
// deleting / emptying / test-stripping it fail closed.
//
// RM-13 (epic #009/#021) registers the enablement-regime decision-boundary
// guard. The mixed-regime divergence (flag-absent secure console vs an
// explicitly-enabled insecure block: capability keeps the secure URI while
// pickPrimary badges the insecure console) is a deferred human decision (RM-11)
// recorded as a stable baseline; an "enabled-first" refactor silently erased
// that record with every pre-existing RM-10 / EP-S7 guard GREEN. Registering
// this guard under a pinned `rm13AddedGuards` subset makes deleting / emptying /
// test-stripping it fail closed.
//
// EP-S9 (epic #009/#021) registers the credential-bearing Primary ↔ navigation
// decision-boundary guard. A userinfo-bearing secure-HTTPS console can be
// badged "Primary" by `pickPrimary` (the shared secure classifier accepts
// userinfo) while `allowsInAppNavigation` refuses that same URI in-session —
// a deferred human decision (EP-S8) recorded as a stable baseline. A refactor
// that silently resolves the divergence (e.g. skipping credential-bearing
// consoles in the Primary tier) erased the record with every EP-P11 / EP-S2
// guard GREEN. Registering this guard under a pinned `epS9AddedGuards` subset
// makes deleting / emptying / test-stripping it fail closed.
//
// EP-T23 (epic #009/#021) closes a CONFIRMED "who guards the guards" gap: the
// EP-U8/EP-U17 no-WebView final-route affordance guard
// (`test/features/kvm/kvm_open_affordance_gating_test.dart`) landed with live
// cases reachable from the whole-tree CI run, but was never added to
// `canonicalGuardFiles` or any pinned epoch set — so deleting / emptying /
// test-stripping that guard stayed GREEN. EP-T23 adds it to the canonical set
// under a pinned `epT23AddedGuards` epoch (disjoint from every earlier
// designation) with a pin test and a temp-root RED→GREEN proof, keeping the
// EP-T20 registry-completeness invariant green.
//
// RM-15 (epic #009/#021) registers the bidi/confusable manager-source
// cross-factory agreement guard
// (`test/features/kvm/kvm_manager_source_bidi_agreement_test.dart`). The
// existing hostile-`@odata.id` tests pin CRLF/NUL/namespace separators but not
// the bidi format family (RLO/LRO, isolates, direction marks, BOM) on the
// manager-source PATH, nor confusable-host agreement across both `fromManager`
// factories. Without registering it, deleting / emptying / test-stripping that
// guard would stay GREEN. A pinned `rm15AddedGuards` epoch (disjoint from every
// earlier designation), a pin test and a temp-root RED→GREEN proof keep the
// EP-T20 registry-completeness invariant green.
//
// EP-P13 (epic #009/#021) registers the authority-confusion cross-layer
// fail-closed agreement guard
// (`test/features/kvm/platform/navigation_launch_authority_confusion_agreement_test.dart`).
// That guard landed with EP-P13 but was left unpinned: it is live and reachable
// from verify.yml's whole-tree `flutter test --coverage`, yet deleting /
// emptying / test-stripping it stayed GREEN because it was absent from
// `canonicalGuardFiles` and every pinned epoch. A pinned `epP13AddedGuards`
// epoch (disjoint from every earlier designation), a pin test and a temp-root
// RED→GREEN proof keep the EP-T20 registry-completeness invariant green.
//
// SEC-010 (issues #009/#021 guard-suite closeout; #010 security hardening)
// registers the four cross-cutting security guards that were live + reachable
// from verify.yml's whole-tree `flutter test --coverage` but never added to
// `canonicalGuardFiles` or any pinned epoch: TLS self-signed enforcement,
// `https → http` TLS-downgrade rejection, auth-token isolation and the
// no-plaintext-persistence structural guard. The sibling
// `test/security/credential_leak_audit_test.dart` was registered by EP-T22 —
// these four were missed. Without registration, deleting / emptying /
// test-stripping e.g. `tls_downgrade_test.dart` stayed GREEN even though it
// guards production TLS (which is never weakened). A pinned `sec010AddedGuards`
// epoch (disjoint from every earlier designation), a pin test and a temp-root
// RED→GREEN proof keep the EP-T20 registry-completeness invariant green.
//
// EP-T26 (issues #009/#021 guard-suite closeout) closes the same CONFIRMED
// "who guards the guards" gap for the three agreement guards that landed after
// SEC-010 and were never registered: the EP-P14 launch-plan scheme-spelling
// fail-closed matrix (`launch_plan_scheme_spelling_matrix_test.dart`), the EP-U19
// cross-surface rendered chip + session-limit agreement guard
// (`kvm_card_chip_session_agreement_test.dart`) and the RM-16 hostile
// enablement-flag encoding agreement guard
// (`kvm_enablement_encoding_agreement_test.dart`). All three are live and
// reachable from verify.yml's whole-tree `flutter test --coverage`, yet each was
// absent from `canonicalGuardFiles` and every pinned epoch — deleting /
// emptying / test-stripping one of them stayed GREEN. A pinned `epT26AddedGuards`
// epoch (length 3, disjoint from every earlier designation), a pin test, a
// temp-root RED→GREEN proof and the updated EP-T20 completeness arithmetic keep
// the registry fail-closed against a future silent drop.
//
// EP-T28 (issues #009/#021 guard-suite closeout) closes the same CONFIRMED
// "who guards the guards" gap for the EP-U20 extreme-content cross-card
// rendered agreement guard (`kvm_card_extreme_content_agreement_test.dart`).
// That guard landed with EP-U20 and is live + reachable from verify.yml's
// whole-tree `flutter test --coverage`, yet it was never added to
// `canonicalGuardFiles` or any pinned epoch — so deleting / emptying /
// test-stripping it stayed GREEN.
// EP-T28 adds it to the canonical set under a pinned `epT28AddedGuards` epoch
// (length 1, disjoint from every earlier designation) with a pin test, a
// temp-root RED→GREEN proof and the updated EP-T20 completeness arithmetic,
// keeping the registry fail-closed against a future silent drop.
//
// EP-T29 (issues #009/#021 guard-suite closeout) closes the same CONFIRMED
// "who guards the guards" gap for the RM-17 duplicate / case-variant console-
// block key-collision agreement guard
// (`kvm_key_collision_agreement_test.dart`). That guard landed with RM-17 and is
// live + reachable from verify.yml's whole-tree `flutter test --coverage`, yet it
// was never added to `canonicalGuardFiles` or any pinned epoch — so deleting /
// emptying / test-stripping it stayed GREEN. EP-T29 adds it to the canonical set
// under a pinned `epT29AddedGuards` epoch (length 1, disjoint from every earlier
// designation) with a pin test, a temp-root RED→GREEN proof and the updated
// EP-T20 completeness arithmetic, keeping the registry fail-closed against a
// future silent drop.
//
// EP-T30 (issues #009/#021 guard-suite closeout) closes the same CONFIRMED
// "who guards the guards" gap for the EP-M4 RemoteConsole-only + explicit-
// disable cross-view parity guard (`kvm_remote_console_disable_parity_test.dart`).
// That guard landed with EP-M4 and is live + reachable from verify.yml's
// whole-tree `flutter test --coverage`, yet it was never added to
// `canonicalGuardFiles` or any pinned epoch — so deleting / emptying /
// test-stripping it stayed GREEN. EP-T30 adds it to the canonical set under a
// pinned `epT30AddedGuards` epoch (length 1, disjoint from every earlier
// designation) with a pin test, a temp-root RED→GREEN proof and the updated
// EP-T20 completeness arithmetic, keeping the registry fail-closed against a
// future silent drop.
//
// EP-T32 (epic #009/#021) closes a CONFIRMED "who guards the guards" gap: the
// EP-P16 nonstandard-port authority fail-closed cross-layer agreement guard
// (`port_authority_fail_closed_agreement_test.dart`, 9 live cases) landed with
// EP-P16 but was never added to `canonicalGuardFiles` or any pinned epoch — so
// deleting / emptying / test-stripping it stays GREEN. It is live + reachable
// from the whole-tree CI run. EP-T32 adds it to the canonical set under a pinned
// `epT32AddedGuards` epoch (disjoint from every earlier designation) with a pin
// test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, keeping the registry fail-closed against a future silent drop.
//
// EP-T33 (epic #009/#021) closes the same CONFIRMED gap for the EP-U21
// large-accessibility-font no-overflow + merged-a11y cross-surface guard
// (`kvm_large_font_cross_surface_a11y_test.dart`, 2 live testWidgets cases)
// that landed with EP-U21 but was never added to `canonicalGuardFiles` or any
// pinned epoch — so deleting / emptying / test-stripping it stays GREEN. It is
// live + reachable from the whole-tree CI run. EP-T33 adds it to the canonical
// set under a pinned `epT33AddedGuards` epoch (disjoint from every earlier
// designation) with a pin test, a temp-root RED→GREEN proof and the updated
// EP-T20 completeness arithmetic, keeping the registry fail-closed against a
// future silent drop.
//
// EP-T35 (epic #009/#021) closes the same CONFIRMED gap for the THREE newest
// agreement guards that landed after EP-T33: EP-M7
// `kvm_manager_body_path_normalization_agreement_test.dart`, EP-S12
// `kvm_service_malformed_members_agreement_test.dart` and EP-P17
// `userinfo_authority_fail_closed_agreement_test.dart`. All three are live +
// reachable from the whole-tree CI run yet were absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping any of them stayed GREEN. EP-T35 registers all three under a
// fresh pinned `epT35AddedGuards` epoch (disjoint from every earlier
// designation) with a pin test, a temp-root RED→GREEN proof and the updated
// EP-T20 completeness arithmetic, keeping the registry fail-closed.
//
// EP-T36 (epic #009/#021) closes the same CONFIRMED gap for the FOUR newest
// agreement guards that landed after EP-T35: EP-U23
// `kvm_card_full_name_announcement_agreement_test.dart`, EP-S10
// `kvm_service_all_unsafe_primary_agreement_test.dart`, EP-S16
// `kvm_service_unicode_id_distinctness_test.dart` and EP-P18
// `canonical_tricky_authority_agreement_test.dart`. All four are live +
// reachable from the whole-tree CI run yet were absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping any of them stayed GREEN. EP-T36 registers all four under a
// fresh pinned `epT36AddedGuards` epoch (disjoint from every earlier
// designation) with a pin test, a temp-root RED→GREEN proof and the updated
// EP-T20 completeness arithmetic, keeping the registry fail-closed.
//
// EP-T37 (epic #009/#021) closes the same CONFIRMED gap for the FOUR newest
// agreement guards that landed after EP-T36: EP-P19
// `query_fragment_control_fail_closed_agreement_test.dart`, RM-21
// `kvm_manager_body_query_fragment_userinfo_agreement_test.dart`, EP-S17
// `kvm_service_malformed_body_transport_agreement_test.dart` and EP-U24
// `kvm_card_unbreakable_chip_agreement_test.dart`. All four are live +
// reachable from the whole-tree CI run yet were absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping any of them stayed GREEN. EP-T37 registers all four under a
// fresh pinned `epT37AddedGuards` epoch (disjoint from every earlier
// designation) with a pin test, a temp-root RED→GREEN proof and the updated
// EP-T20 completeness arithmetic, keeping the registry fail-closed.
//
// EP-T39 (epic #009/#021) closes the same CONFIRMED gap for the FIVE newest
// agreement guards that landed after EP-T37: EP-P20 (backslash / mixed
// separator), RM-22 (confusable connect-type), EP-S18 (same-tier Primary),
// EP-U25 (Primary badge single merged a11y) and EP-U22 (bidi display text).
// All five are live + CI-reachable (verify.yml whole-tree `flutter test
// --coverage`) yet absent from BOTH `canonicalGuardFiles` and every pinned
// epoch, so deleting / emptying / test-stripping any of them stayed GREEN.
// EP-T39 registers all five under a fresh pinned `epT39AddedGuards` epoch
// (disjoint from every earlier designation) with a pin test, a temp-root
// RED→GREEN proof and the updated EP-T20 completeness arithmetic, keeping the
// registry fail-closed.
//
// EP-T40 (epic #009/#021) closes the same CONFIRMED gap for the THREE newest
// agreement guards that landed after EP-T39: EP-U18 (copy-only vs browser-open
// route agreement), RM-23 (hostile ConnectUri raw-preservation cross-factory
// agreement) and EP-P21 (IPv6-literal / zone-id authority cross-layer
// agreement). All three are live + CI-reachable (verify.yml whole-tree
// `flutter test --coverage`) yet absent from BOTH `canonicalGuardFiles` and
// every pinned epoch, so deleting / emptying / test-stripping any of them
// stayed GREEN. EP-T40 registers all three under a fresh pinned
// `epT40AddedGuards` epoch (disjoint from every earlier designation) with a
// pin test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, keeping the registry fail-closed.
//
// EP-T41 (epic #009/#021) closes the same CONFIRMED gap for FOUR more live
// agreement guards that landed unpinned: RM-18 (derived-fallback manager-id
// control-safety cross-factory agreement), RM-20 (registered-OEM hostile
// enrichment normalization cross-factory agreement), EP-S13 (cross-surface
// manager-skip agreement under a 404/retryable matrix) and EP-S14 (cross-surface
// zero-usable-console surfacing agreement). All four are live + CI-reachable
// (verify.yml whole-tree `flutter test --coverage`) yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping any of them stayed GREEN. EP-T41 registers all four under a
// fresh pinned `epT41AddedGuards` epoch (disjoint from every earlier
// designation) with a pin test, a temp-root RED→GREEN proof and the updated
// EP-T20 completeness arithmetic, keeping the registry fail-closed.
//
// EP-T42 (epic #009/#021) closes the same CONFIRMED gap for the one agreement
// guard that landed after EP-T41: EP-U26-residual (console-card "Copied:"
// SnackBar fail-closed cross-surface agreement). It is live + CI-reachable
// (verify.yml whole-tree `flutter test --coverage`) yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping it stayed GREEN. A registry audit confirmed it is the ONLY
// post-EP-T41 #009/#021 guard in that state (the one other unregistered
// `*_test.dart` candidate, sensors `polling_policy_test.dart`, belongs to the
// closed #007 domain and is not part of this epic's guard family). EP-T42
// registers it under a fresh pinned `epT42AddedGuards` epoch (length 1,
// disjoint from every earlier designation) with a pin test, a temp-root
// RED→GREEN proof and the updated EP-T20 completeness arithmetic, keeping the
// registry fail-closed.
//
// EP-T43 (epic #009/#021) closes the same CONFIRMED gap for the one agreement
// guard that landed after EP-T42: RM-24 (non-boolean enablement-scalar coercion
// agreement across both `fromManager` factories + the shared OEM enablement
// helper). It is live + CI-reachable (verify.yml whole-tree `flutter test
// --coverage`) yet absent from BOTH `canonicalGuardFiles` and every pinned
// epoch, so deleting / emptying / test-stripping it stayed GREEN. A registry
// audit confirmed it is the ONLY post-EP-T42 #009/#021 guard in that state.
// EP-T43 registers it under a fresh pinned `epT43AddedGuards` epoch (length 1,
// disjoint from every earlier designation) with a pin test, a temp-root
// RED→GREEN proof and the updated EP-T20 completeness arithmetic, keeping the
// registry fail-closed.
//
// EP-T44 (epic #009/#021) closes the same CONFIRMED gap for the one agreement
// guard that landed after EP-T43: EP-S20 (top-level `/Managers` document-shape
// cross-surface agreement across `fetchConsoles()` / `fetchCapabilities()` /
// `fetchCapability(id)`). It is live + CI-reachable (verify.yml whole-tree
// `flutter test --coverage`) yet absent from BOTH `canonicalGuardFiles` and
// every pinned epoch, so deleting / emptying / test-stripping it stayed GREEN.
// A registry audit confirmed it is the ONLY post-EP-T43 #009/#021 guard in that
// state. EP-T44 registers it under a fresh pinned `epT44AddedGuards` epoch
// (length 1, disjoint from every earlier designation) with a pin test, a
// temp-root RED→GREEN proof and the updated EP-T20 completeness arithmetic,
// keeping the registry fail-closed.
//
// EP-T45 (epic #009/#021) closes the same CONFIRMED gap for the one agreement
// guard that landed after EP-T44: EP-P22 (degenerate userinfo-edge authority
// fail-closed cross-layer agreement — empty credential pairs `https://:@host`
// / `https://user:@host` and uppercase-hex escapes across classifier, launch
// plan, navigation gate and model). It is live + CI-reachable (verify.yml
// whole-tree `flutter test --coverage`) yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping it stayed GREEN. A registry audit confirmed it is the ONLY
// post-EP-T44 #009/#021 guard in that state. EP-T45 registers it under a fresh
// pinned `epT45AddedGuards` epoch (length 1, disjoint from every earlier
// designation incl. EP-T44) with a pin test, a temp-root RED→GREEN proof and
// the updated EP-T20 completeness arithmetic, keeping the registry fail-closed.
//
// EP-T46 (epic #009/#021) closes the same CONFIRMED gap for the two agreement
// guards that landed after EP-T45 unpinned: RM-25 (non-integer
// `MaxConcurrentSessions` scalar coercion field-for-field agreement across both
// `fromManager` factories and the shared `kvmSessionLimit` helper) and EP-P23
// (degenerate hierarchical-URI form fail-closed cross-layer agreement — opaque /
// single-slash / empty-authority / scheme-only HTTPS forms across classifier,
// HTTP family, launch plan, navigation gate and model). Both are live +
// CI-reachable (verify.yml whole-tree `flutter test --coverage`) yet absent from
// BOTH `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping either stayed GREEN. A registry audit confirmed these are the
// ONLY post-EP-T45 #009/#021 guards in that state. EP-T46 registers both under a
// fresh pinned `epT46AddedGuards` epoch (length 2, pairwise-disjoint from every
// earlier designation incl. EP-T45) with a pin test, a temp-root RED→GREEN proof
// and the updated EP-T20 completeness arithmetic, keeping the registry
// fail-closed.
//
// EP-T47 (epic #009/#021) closes the same CONFIRMED gap for the one agreement
// guard that landed after EP-T46 unpinned: EP-U28 (RTL-locale rendering
// agreement — byte-identical chip sequences + merged `excludeSemantics`
// announcement sets across both operator cards and the viewer under LTR and
// RTL at 320/800/1300 px). It is live + CI-reachable (verify.yml whole-tree
// `flutter test --coverage`) yet absent from BOTH `canonicalGuardFiles` and
// every pinned epoch, so deleting / emptying / test-stripping it stayed GREEN.
// A registry audit confirmed it is the ONLY post-EP-T46 #009/#021 guard in that
// state. EP-T47 registers it under a fresh pinned `epT47AddedGuards` epoch
// (length 1, pairwise-disjoint from every earlier designation incl. EP-T46)
// with a pin test, a temp-root RED→GREEN proof and the updated EP-T20
// completeness arithmetic, keeping the registry fail-closed.
//
// EP-T48 (epic #009/#021) closes the next CONFIRMED "who guards the guards"
// gap: the EP-S21 hostile OEM console-shape cross-surface agreement guard
// (`kvm_service_hostile_oem_shape_agreement_test.dart`, mixed-case / nested /
// duplicate / empty OEM keys, non-map / list / numeric / bool leaves, explicit
// disable + byte-exact control, agreement across both real `/Managers` walk
// surfaces) landed after EP-T47 unpinned. It is live + CI-reachable
// (verify.yml whole-tree `flutter test --coverage`) yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping it stayed GREEN. A registry audit confirmed it is the ONLY
// post-EP-T47 #009/#021 guard in that state (the sensors `polling_policy_test`
// belongs to the closed #007 domain and this file is the registry itself).
// EP-T48 registers it under a fresh pinned `epT48AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T47) with a pin
// test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, keeping the registry fail-closed.
//
// EP-T49 (epic #009/#021) closes the next CONFIRMED "who guards the guards"
// gap: the RM-26 hostile `ConnectTypesSupported` container-shape cross-factory
// agreement guard (`kvm_connect_type_container_shape_agreement_test.dart`,
// bare-string / numeric / bool / map / null containers fail closed identically
// on both `fromManager` normalizers, never flip `supportsHtml5` / `supportsKvmIp`
// / `supported` on one surface, valid-list control byte-exact, mixed-container
// agreement) landed after EP-T48 unpinned. It is live + CI-reachable
// (verify.yml whole-tree `flutter test --coverage`) yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping it stayed GREEN. A registry audit confirmed it is the ONLY
// post-EP-T48 #009/#021 guard in that state. EP-T49 registers it under a fresh
// pinned `epT49AddedGuards` epoch (length 1, pairwise-disjoint from every
// earlier designation incl. EP-T48) with a pin test, a temp-root RED→GREEN
// proof and the updated EP-T20 completeness arithmetic, keeping the registry
// fail-closed.
//
// EP-T50 (epic #009/#021) closes the next CONFIRMED "who guards the guards"
// gap: the EP-U29 degenerate-empty connect-type / blank-label render agreement
// guard (`kvm_degenerate_empty_connect_type_render_agreement_test.dart`, blank /
// whitespace / malformed `ConnectTypesSupported` tokens collapse to an empty
// chip set identically on both model projections; at 320/800/1300 px both
// operator cards emit no connect-type node / empty announcement / blank chip
// while a populated control keeps byte-identical chip rows and the viewer adds
// no empty node) landed after EP-T49 unpinned. It is live + CI-reachable
// (verify.yml whole-tree `flutter test --coverage`) yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch, so deleting / emptying /
// test-stripping it stayed GREEN. A registry audit confirmed it is the ONLY
// post-EP-T49 #009/#021 guard in that state. EP-T50 registers it under a fresh
// pinned `epT50AddedGuards` epoch (length 1, pairwise-disjoint from every
// earlier designation incl. EP-T49) with a pin test, a temp-root RED→GREEN
// proof and the updated EP-T20 completeness arithmetic, keeping the registry
// fail-closed.
//
// EP-T51 (epic #009/#021) registers the next CONFIRMED gap: the EP-U30
// C0-control / Unicode line/paragraph-separator display-text a11y agreement
// guard (`kvm_card_control_separator_display_text_a11y_agreement_test.dart`,
// CR/LF/TAB/NUL/DEL/ESC + U+2028/U+2029/U+00A0 in the manager DISPLAY NAME
// byte-exact on both operator cards + the viewer at 320/800/1300 px, no split /
// duplicate / screen-reader-only node, no overflow) landed after EP-T50
// unpinned. It is live + CI-reachable (verify.yml whole-tree
// `flutter test --coverage`) yet absent from BOTH `canonicalGuardFiles` and
// every pinned epoch, so deleting / emptying / test-stripping it stayed GREEN;
// a registry audit confirmed it is the ONLY post-EP-T50 #009/#021 guard in that
// state. EP-T51 registers it under a fresh pinned `epT51AddedGuards` epoch
// (length 1, pairwise-disjoint from every earlier designation incl. EP-T50)
// with a pin test, a temp-root RED→GREEN proof and the updated EP-T20
// completeness arithmetic, keeping the registry fail-closed.
//
// EP-T52 registers the one agreement guard landed this run (EP-U31 compound
// unbreakable-chip x RTL x 2.0x text-scaler a11y agreement across both operator
// cards, `kvm_compound_extreme_a11y_agreement_test.dart`, 7 live tests) under a
// fresh pinned `epT52AddedGuards` epoch (length 1, pairwise-disjoint from every
// earlier designation incl. EP-T51) with a pin test, a temp-root RED→GREEN
// proof and the updated EP-T20 completeness arithmetic, so deleting / emptying
// / test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T53 registers the one agreement guard landed this run (EP-U32 compound
// bidi-display-name x RTL x 2.0x text-scaler a11y agreement across both operator
// cards AND the viewer, `kvm_bidi_name_rtl_scale_a11y_agreement_test.dart`, 10
// live tests) under a fresh pinned `epT53AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T52) with a pin
// test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, so deleting / emptying / test-stripping it fails closed (issues
// #009/#021 closeout).
//
// EP-T54 registers the one agreement guard landed this run (EP-U33 compound
// C0-control / Unicode line-paragraph-SEPARATOR display-name x RTL x 2.0x
// text-scaler a11y agreement across both operator cards AND the viewer,
// `kvm_control_separator_rtl_scale_a11y_agreement_test.dart`, 13 live tests)
// under a fresh pinned `epT54AddedGuards` epoch (length 1, pairwise-disjoint
// from every earlier designation incl. EP-T53) with a pin test, a temp-root
// RED→GREEN proof and the updated EP-T20 completeness arithmetic, so deleting
// / emptying / test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T55 registers the one agreement guard landed this run (EP-U34 compound
// long-unbreakable-display-name x RTL x 2.0x text-scaler a11y agreement across
// both operator cards AND the viewer, `kvm_long_unbreakable_name_rtl_scale_a11y_agreement_test.dart`,
// 10 live tests) under a fresh pinned `epT55AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T54) with a pin
// test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, so deleting / emptying / test-stripping it fails closed (issues
// #009/#021 closeout).
//
// EP-T56 registers the one agreement guard landed this run (EP-U35 compound
// control/bidi-bearing CONNECT-TYPE chip a11y agreement across both operator
// cards, `kvm_connect_type_control_rtl_scale_a11y_agreement_test.dart`,
// 7 live tests) under a fresh pinned `epT56AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T55) with a pin
// test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, so deleting / emptying / test-stripping it fails closed (issues
// #009/#021 closeout).
//
// EP-T57 registers the one agreement guard landed this run (EP-U36 compound
// RTL x 2.0x shared-notice a11y agreement across both operator cards + the
// viewer, `kvm_notice_rtl_scale_a11y_agreement_test.dart`, 10 live tests) under
// a fresh pinned `epT57AddedGuards` epoch (length 1, pairwise-disjoint from
// every earlier designation incl. EP-T56) with a pin test, a temp-root
// RED→GREEN proof and the updated EP-T20 completeness arithmetic, so deleting
// / emptying / test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T58 registers the one agreement guard landed this run (EP-U37 compound
// RTL x 2.0x RAW resolved/connect-URI display a11y agreement across both
// operator cards, `kvm_uri_display_rtl_scale_a11y_agreement_test.dart`,
// 12 live tests, with the viewer pinned fail-closed) under a fresh pinned
// `epT58AddedGuards` epoch (length 1, pairwise-disjoint from every earlier
// designation incl. EP-T57) with a pin test, a temp-root RED→GREEN proof and
// the updated EP-T20 completeness arithmetic, so deleting / emptying /
// test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T59 registers the one agreement guard landed this run (EP-U38 compound
// RTL x 2.0x session-limit row a11y agreement across both operator cards,
// `kvm_session_limit_rtl_scale_a11y_agreement_test.dart`, 7 live tests — the
// two cards' byte-exact session NUMBER in one merged visible==announced node
// each at 320/800/1300 px under RTL AND a 2.0x scaler, boundary encodings,
// LTR/1.0x control) under a fresh pinned `epT59AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T58) with a pin
// test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, so deleting / emptying / test-stripping it fails closed (issues
// #009/#021 closeout).
//
// EP-T60 registers the one agreement guard landed this run (EP-U39 compound
// RTL x 2.0x "Primary" badge single-merged a11y agreement across the KVM
// operator surfaces, `kvm_primary_badge_rtl_scale_a11y_agreement_test.dart`,
// 6 live tests — exactly one visible Primary marker on the pickPrimary winner,
// inside one merged header node, no split/screen-reader-only announcement, no
// peer/capability/viewer duplicate and no overflow at 320/800/1300 px under RTL
// AND a 2.0x scaler, with an LTR/1.0x control) under a fresh pinned
// `epT60AddedGuards` epoch (length 1, pairwise-disjoint from every earlier
// designation incl. EP-T59) with a pin test, a temp-root RED→GREEN proof and
// the updated EP-T20 completeness arithmetic, so deleting / emptying /
// test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T61 registers the one agreement guard that landed immediately after
// EP-T60 but was left deliberately unpinned (its Verify write scope was
// limited to `test/features/kvm/platform/**`): EP-P25 control-at-URI-
// structural-boundary cross-layer fail-closed agreement,
// `test/features/kvm/platform/structural_boundary_control_agreement_test.dart`,
// 3 live tests — a 12-case hostile matrix wedging raw C0/C1/DEL controls at
// every URI structural boundary (scheme↔`://`, userinfo `@`, port `:`, IPv6
// `[...]`, trailing authority) plus 3 clean spellings, pinned field-for-field
// across the classifier / control-safety core, `planConsoleLaunch` (incl. the
// stale-flag test-only opt-in TLS boundary), `allowsInAppNavigation` (both
// directions) and the `KvmConsole` model — with the same-origin userinfo-NUL
// case pinning the `Uri.tryParse` origin differential. It was live + CI-
// reachable via verify.yml whole-tree `flutter test --coverage` yet absent from
// BOTH `canonicalGuardFiles` and every pinned epoch (0 registry references),
// so deleting / emptying / test-stripping it stayed GREEN — a genuine "who
// guards the guards" gap, no live divergence, no behaviour change, not churn.
// Registered under a fresh pinned `epT61AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T60) with a pin
// test, a temp-root RED→GREEN proof and the updated EP-T20 completeness
// arithmetic, so deleting / emptying / test-stripping it fails closed (issues
// #009/#021 closeout).
//
// EP-T62 (queued audit-first head) registers the one compound a11y agreement
// guard landed this run: `kvm_nonpopulated_state_rtl_scale_a11y_agreement_test.dart`
// (EP-U40, 21 live tests — the five non-populated KvmView states each pinned to
// ONE merged `excludeSemantics` node with visible==announced, no duplicate /
// screen-reader-only node, no overflow at 320/800/1300 px under RTL + a 2.0x
// scaler, LTR/1.0x + populated controls). It landed live + CI-reachable via
// verify.yml whole-tree `flutter test --coverage` yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch (0 registry references), so
// deleting / emptying / test-stripping it stayed GREEN — a genuine "who guards
// the guards" gap, no live divergence, no behaviour change, not churn (the
// guard's Verify write scope is limited to `test/features/kvm/**`). Registered
// under a fresh pinned `epT62AddedGuards` epoch (length 1, pairwise-disjoint
// from every earlier designation incl. EP-T61) with a pin test, a temp-root
// RED→GREEN proof and the updated EP-T20 completeness arithmetic, so deleting /
// emptying / test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T63 (queued audit-first head) registers the one cross-layer fail-closed
// agreement guard landed this run:
// `ipv6_zone_id_malformed_authority_agreement_test.dart` (EP-P27, 6 live tests —
// a scoped-IPv6 zone id (`%25` / bare `%`), a zone carrying a control / bidi /
// separator byte, a malformed bracket / percent spelling and IPv4-mapped forms
// pinned field-for-field across the classifier, HTTP-family classifier,
// `planConsoleLaunch`, `allowsInAppNavigation` and the `KvmConsole` model, with
// clean IPv6 / IPv4 controls). It landed live + CI-reachable via verify.yml
// whole-tree `flutter test --coverage` yet absent from BOTH `canonicalGuardFiles`
// and every pinned epoch (0 registry references), so deleting / emptying /
// test-stripping it stayed GREEN — a genuine "who guards the guards" gap, no
// live divergence, no behaviour change, not churn (the guard's Verify write
// scope is limited to `test/features/kvm/platform/**`). Registered under a fresh
// pinned `epT63AddedGuards` epoch (length 1, pairwise-disjoint from every earlier
// designation incl. EP-T62) with a pin test, a temp-root RED→GREEN proof and the
// updated EP-T20 completeness arithmetic, so deleting / emptying /
// test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T65 (queued audit-first head) registers the one cross-layer navigation
// asymmetry guard landed this run:
// `platform/console_userinfo_navigation_asymmetry_agreement_test.dart` (EP-P28,
// 8 live tests — a credentialed console is a legal initial secure-HTTPS load
// whose userinfo must NOT be rejected as an in-session navigation source, so a
// credential-free same-origin target stays navigable while a credentialed
// target still fails closed; pinned across path/query variants, default-port
// normalization, origin confinement, non-HTTPS fail-closed and the launch-plan
// initial-load exception). It landed live + CI-reachable via verify.yml
// whole-tree `flutter test --coverage` yet absent from BOTH `canonicalGuardFiles`
// and every pinned epoch (0 registry references), so deleting / emptying /
// test-stripping it stayed GREEN — a genuine "who guards the guards" gap, no
// live divergence, no behaviour change, not churn (the guard's Verify write
// scope is limited to `test/features/kvm/platform/**`). Registered under a fresh
// pinned `epT65AddedGuards` epoch (length 1, pairwise-disjoint from every earlier
// designation incl. EP-T64) with a pin test, a temp-root RED→GREEN proof and the
// updated EP-T20 completeness arithmetic, so deleting / emptying /
// test-stripping it fails closed (issues #009/#021 closeout).
//
// EP-T66 (queued audit-first head EP-S23) registers the `@odata.nextLink`
// collection-page cross-surface agreement guard landed this run:
// `test/features/kvm/kvm_service_nextlink_page_agreement_test.dart` (8 live
// tests — the root nextLink VALUE FAMILY (absolute/query/relative/scheme-
// relative/blank/non-string, plus a second page repeating a member) pinned
// across `fetchConsoles()` / `fetchCapabilities()` / `fetchCapability(id)` /
// controller Primary: both surfaces adopt the same single page set, no ghost
// lookup, no double-count). AUDIT FIRST: both surfaces share one stateless
// `_fetchManagerBodies()` walk that never reads nextLink, so agreement holds by
// construction — but NO existing guard drove a nextLink root through both
// surfaces, so a one-sided page-adoption edit could ghost the capability card
// while the console list stayed GREEN (REAL RED: 5 named failures, 3 controls
// GREEN; 67 existing service tests GREEN under the mutation). It landed live +
// CI-reachable via verify.yml whole-tree `flutter test --coverage` yet absent
// from BOTH `canonicalGuardFiles` and every pinned epoch (0 registry
// references), so deleting / emptying / test-stripping it stayed GREEN.
// Registered under a fresh pinned `epT66AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T65) with a pin
// test, a temp-root RED->GREEN proof and the updated EP-T20 completeness
// arithmetic, so deleting / emptying / test-stripping it fails closed
// (issues #009/#021 closeout).
//
// EP-T67 (issues #009/#021): "who guards the guards" AUDIT FIRST closeout of
// two genuine regression guards that were live + CI-reachable but absent from
// BOTH `canonicalGuardFiles` and every pinned epoch (0 registry references):
// `test/features/kvm/kvm_service_member_order_tie_test.dart` (EP-S11 — the
// first-in-BMC-order tie winner pinned field-for-field across fetchConsoles /
// fetchPrimaryConsole / fetchCapabilities / fetchCapability) and
// `test/features/kvm/kvm_viewer_session_limit_wiring_test.dart` (EP-U4 — the
// real-viewer -> KvmSessionController maxConcurrentSessions pass-through that
// makes a single-session BMC evict on a second console). Deleting / emptying /
// test-stripping either stayed GREEN. Registered under a fresh pinned
// `epT67AddedGuards` epoch (length 2, pairwise-disjoint from every earlier
// designation incl. EP-T66) with a pin test + updated EP-T20 completeness
// arithmetic, so each now fails closed. No product code, no dependency, no
// WebView/protocol import, no URL opened, no production TLS weakening.
//
// EP-T68 (issues #009/#021) closes the next CONFIRMED "who guards the guards"
// gap: the EP-U41 compound a11y agreement guard
// (`test/features/kvm/kvm_copy_affordance_rtl_scale_a11y_agreement_test.dart`,
// 8 live tests — the fail-closed "Copy connect info" console-card button and
// "Copy console URI" viewer button each pinned to exactly one merged
// `excludeSemantics` node whose announced label equals its visible Text, no
// split / reworded screen-reader-only node, no overflow at 320/800/1300 px under
// RTL AND a 2.0x scaler, plus an LTR/1.0x control). It landed live +
// CI-reachable via verify.yml whole-tree `flutter test --coverage` yet absent
// from BOTH `canonicalGuardFiles` and every pinned epoch (0 registry
// references), so deleting / emptying / test-stripping it stayed GREEN. A
// registry audit confirmed it is the only post-EP-T67 #009/#021 guard in that
// state. Registered under a fresh pinned `epT68AddedGuards` epoch (length 1,
// pairwise-disjoint from every earlier designation incl. EP-T67) with a pin
// test + updated EP-T20 completeness arithmetic, so it now fails closed. No
// product code, no dependency, no WebView/protocol import, no URL opened, no
// production TLS weakening.
//
// EP-T69 (issues #009/#021) closes the next CONFIRMED "who guards the guards"
// gap: the EP-U42 manager-source fallback-row RTL x 2.0x a11y agreement guard
// (`test/features/kvm/kvm_manager_source_row_rtl_scale_a11y_agreement_test.dart`,
// live tests — each no-URI manager-source fallback row on the per-console card,
// the capability card and the viewer pinned to one merged `excludeSemantics`
// node with visible text == the full byte-exact `safeManagerUri`, no split /
// duplicate / screen-reader-only node, no overflow at 320/800/1300 px under RTL
// AND a 2.0x scaler, plus an LTR/1.0x control). It landed live + CI-reachable
// via verify.yml whole-tree `flutter test --coverage` yet absent from BOTH
// `canonicalGuardFiles` and every pinned epoch (0 registry references), so
// deleting / emptying / test-stripping it stayed GREEN. A registry audit
// confirmed it is the only post-EP-T68 #009/#021 guard in that state. Registered
// under a fresh pinned `epT69AddedGuards` epoch (length 1, pairwise-disjoint
// from every earlier designation incl. EP-T68) with a pin test + updated
// EP-T20 completeness arithmetic, so it now fails closed. No product code, no
// dependency, no WebView/protocol import, no URL opened, no production TLS
// weakening.
//
// EP-T70 registers the post-EP-T69 newly-landed EP-U27 dense connect-type
// chip-set a11y agreement guard (`kvm_dense_connect_type_chip_set_a11y_agreement_test.dart`
// — 13 distinct hostile / fullwidth / confusable `ConnectTypesSupported`
// tokens byte-exact on both `fromManager` factories and on both real operator
// cards at 320/800/1300 px, one merged `excludeSemantics` chip-row node each,
// visible == model chips, no screen-reader-only split chip, no RenderFlex
// overflow, small clean control). A programmatic audit of every KVM
// agreement/guard test file against the registry confirmed it was the sole
// guard live + CI-reachable via verify.yml whole-tree `flutter test --coverage`
// yet absent from BOTH `canonicalGuardFiles` and every pinned epoch (0 registry
// references), so deleting / emptying / test-stripping it stayed GREEN — a
// genuine "who guards the guards" gap deferred by its owner run's
// `test/features/kvm/**` write scope. Registered under a fresh pinned
// `epT70AddedGuards` epoch (length 1, pairwise-disjoint from every earlier
// designation incl. EP-T69) with a pin test + updated EP-T20 completeness
// arithmetic, so it now fails closed. No product code, no dependency, no
// WebView/protocol import, no URL opened, no production TLS weakening.
//
// The evaluator lives in this TEST-only file so it never scans or touches
// product code. It is dependency-free, opens no network, uses no credentials,
// and never weakens production TLS. The RED→GREEN proof uses a temporary scan
// root; the real-repo invariant pins the checked-in guard suite + CI invocation.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The established KVM safety guard test files, stored as repo-relative,
/// forward-slash paths for cross-platform stability. This is the minimum set
/// named by EP-T12; adding a new guard to this list is cheap and intentional.
const List<String> canonicalGuardFiles = <String>[
  // EP-T12 initial set.
  'test/tool/notice_single_source_guard_test.dart',
  'test/tool/launch_status_single_source_guard_test.dart',
  'test/tool/uri_parse_single_source_guard_test.dart',
  'test/tool/manager_source_display_guard_test.dart',
  'test/features/kvm/platform/product_import_policy_test.dart',
  'test/features/kvm/platform/production_route_invariant_test.dart',
  'test/features/kvm/platform/human_gate_doc_guard_test.dart',
  'test/features/kvm/platform/decision_doc_route_guard_test.dart',
  // EP-T14 extension: safety guards that landed after EP-T12.
  'test/tool/queue_item_schema_guard_test.dart',
  'test/features/kvm/platform/production_optin_construction_guard_test.dart',
  'test/features/kvm/platform/cross_layer_authority_agreement_test.dart',
  'test/features/kvm/kvm_viewer_flagoff_false_claim_guard_test.dart',
  'test/features/kvm/kvm_viewer_disclosure_contract_test.dart',
  'test/features/kvm/kvm_providers_test.dart',
  'test/features/kvm/kvm_session_audit_invariants_test.dart',
  // EP-T15 extension: behavioral regression guards that landed after EP-T14.
  'test/features/kvm/kvm_capability_kvmip_fallback_test.dart',
  'test/features/kvm/kvm_manager_source_precedence_test.dart',
  'test/features/kvm/kvm_oem_multi_vendor_enablement_test.dart',
  'test/features/kvm/kvm_controller_dispose_guard_test.dart',
  'test/features/kvm/kvm_service_manager_identity_test.dart',
  'test/features/kvm/kvm_card_cross_surface_agreement_test.dart',
  // EP-T16 extension: widget-level regression guards that landed after EP-T15.
  'test/features/kvm/kvm_clipboard_cross_surface_agreement_test.dart',
  'test/features/kvm/kvm_view_reload_indicator_test.dart',
  'test/features/kvm/kvm_view_stale_error_banner_test.dart',
  // EP-T17 extension: safety guards that landed after EP-T16.
  'test/features/kvm/kvm_service_lookup_key_test.dart',
  'test/features/kvm/kvm_oem_depth_bound_agreement_test.dart',
  'test/features/kvm/kvm_view_state_agreement_test.dart',
  'test/features/kvm/platform/validation_evidence_checklist_guard_test.dart',
  // EP-T18 extension: safety guards that landed after EP-T17.
  'test/features/kvm/kvm_service_capability_primary_agreement_test.dart',
  'test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart',
  'test/features/kvm/kvm_capability_primary_uri_agreement_test.dart',
  // EP-T19 extension: safety guards that landed after EP-T18.
  'test/features/kvm/kvm_capability_security_tristate_agreement_test.dart',
  'test/features/kvm/platform/navigation_launch_route_agreement_test.dart',
  'test/features/kvm/kvm_three_surface_launch_target_agreement_test.dart',
  // EP-M6 extension: OEM-console URI shadow agreement across both views.
  'test/features/kvm/kvm_oem_uri_shadow_agreement_test.dart',
  // EP-T20 extension: post-EP-T19 safety guards audited live + reachable.
  'test/features/kvm/kvm_lifecycle_parity_test.dart',
  'test/features/kvm/kvm_notice_surface_audit_test.dart',
  'test/features/kvm/platform/webview_policy_test.dart',
  // EP-U16 extension: cross-card protocol-notice rendered agreement.
  'test/features/kvm/kvm_external_notice_cross_surface_agreement_test.dart',
  // EP-M5 extension: hostile ConnectTypesSupported cross-factory agreement.
  'test/features/kvm/kvm_connect_types_hostile_agreement_test.dart',
  // EP-S2 extension: secure-HTTPS tier precedence in pickPrimary.
  'test/features/kvm/kvm_service_primary_secure_tier_test.dart',
  // EP-T21 extension: RM-12 fromManager classifier/label/openability parity.
  'test/features/kvm/kvm_external_client_from_manager_parity_test.dart',
  // EP-T22 extension: cross-cutting safety guards named by EP-T12 but never
  // registered (asset policy, unattended-safety policy, credential-leak audit).
  'test/tool/asset_guard_test.dart',
  'test/tool/unattended_guard_test.dart',
  'test/security/credential_leak_audit_test.dart',
  // RM-14 extension: OEM console-block documented direct-key precedence.
  'test/features/kvm/kvm_oem_block_precedence_test.dart',
  // RM-13 extension: enablement-regime decision-boundary characterization
  // (agreeing-regime byte-for-byte agreement + deferred RM-11 divergence record).
  'test/features/kvm/kvm_enablement_regime_boundary_test.dart',
  // EP-S9 extension: credential-bearing Primary ↔ navigation decision
  // boundary (agreeing invariants + deferred EP-S8 divergence record).
  'test/features/kvm/kvm_credential_primary_navigation_boundary_test.dart',
  // EP-T23 extension: the EP-U8/EP-U17 no-WebView final-route affordance
  // agreement guard (no in-app render / self-signed-accept affordance).
  'test/features/kvm/kvm_open_affordance_gating_test.dart',
  // RM-15 extension: bidi/confusable manager-source cross-factory agreement
  // (bidi format marks + confusable hosts fail closed identically on both
  // fromManager factories).
  'test/features/kvm/kvm_manager_source_bidi_agreement_test.dart',
  // EP-P13 extension: the scheme-relative / network-path / encoded-authority
  // cross-layer fail-closed agreement guard (landed with EP-P13, left unpinned
  // until this run).
  'test/features/kvm/platform/navigation_launch_authority_confusion_agreement_test.dart',
  // SEC-010 extension: the four cross-cutting #010 security-hardening guards
  // (TLS self-signed enforcement, TLS-downgrade rejection, auth-token isolation,
  // no-plaintext persistence) that were live + CI-reachable but never
  // registered — siblings of the EP-T22 credential-leak guard.
  'test/security/tls_enforcement_test.dart',
  'test/security/tls_downgrade_test.dart',
  'test/security/token_isolation_test.dart',
  'test/security/no_plaintext_test.dart',
  // EP-T26 extension: the three agreement guards that landed after SEC-010
  // unpinned (launch-plan scheme-spelling matrix, cross-surface chip/session
  // agreement, enablement-flag encoding agreement) — live + CI-reachable but
  // absent from the registry until this run.
  'test/features/kvm/platform/launch_plan_scheme_spelling_matrix_test.dart',
  'test/features/kvm/kvm_card_chip_session_agreement_test.dart',
  'test/features/kvm/kvm_enablement_encoding_agreement_test.dart',
  // EP-T28 extension: the EP-U20 extreme-content cross-card rendered agreement guard
  // (20+ chips / 1e9 sessions / long control-safe URI on both real cards,
  // no overflow at 320/800/1300 px) — live + CI-reachable but unpinned until
  // this run.
  'test/features/kvm/kvm_card_extreme_content_agreement_test.dart',
  // EP-T29 extension: the RM-17 duplicate / case-variant console-block
  // key-collision cross-factory agreement guard (canonical exact-case keys
  // authoritative, colliding spellings ignored) — live + CI-reachable but
  // unpinned until this run.
  'test/features/kvm/kvm_key_collision_agreement_test.dart',
  // EP-T30 extension: the EP-M4 RemoteConsole-only + explicit-disable
  // cross-view parity guard (detection / resolved URI / aggregated types /
  // session limit / per-console launch strategy agree across both fromManager
  // factories) — live + CI-reachable but unpinned until this run.
  'test/features/kvm/kvm_remote_console_disable_parity_test.dart',
  // EP-T32 extension: the EP-P16 nonstandard-port authority fail-closed
  // cross-layer agreement guard (legitimate/malformed ports agree across the
  // classifier, launch plan, nav gate and stale-flag TLS boundary) — live +
  // CI-reachable but unpinned until this run.
  'test/features/kvm/platform/port_authority_fail_closed_agreement_test.dart',
  // EP-T33 extension: the EP-U21 large-accessibility-font no-overflow +
  // merged-a11y cross-surface guard (both real cards + the viewer at 1.0/1.3/
  // 2.0 text scale on 320 px, one merged node per signal, no RenderFlex
  // overflow) — live + CI-reachable but unpinned until this run.
  'test/features/kvm/kvm_large_font_cross_surface_a11y_test.dart',
  // EP-T35 extension: the three newest agreement guards that landed after
  // EP-T33 unpinned (EP-M7 body-path normalization, EP-S12 malformed Members,
  // EP-P17 encoded userinfo fail-closed) — all live + CI-reachable but absent
  // from the registry until this run.
  'test/features/kvm/kvm_manager_body_path_normalization_agreement_test.dart',
  'test/features/kvm/kvm_service_malformed_members_agreement_test.dart',
  'test/features/kvm/platform/userinfo_authority_fail_closed_agreement_test.dart',
  // EP-T36 extension: the four newest agreement guards that landed after
  // EP-T35 unpinned (EP-U23 full-name announcement, EP-S10 all-unsafe primary,
  // EP-S16 Unicode-id distinctness, EP-P18 canonical-tricky authority) — all
  // live + CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_card_full_name_announcement_agreement_test.dart',
  'test/features/kvm/kvm_service_all_unsafe_primary_agreement_test.dart',
  'test/features/kvm/kvm_service_unicode_id_distinctness_test.dart',
  'test/features/kvm/platform/canonical_tricky_authority_agreement_test.dart',
  // EP-T37 extension: the four newest agreement guards that landed after
  // EP-T36 unpinned (EP-P19 query/fragment control fail-closed cross-layer,
  // RM-21 body-id query/fragment/userinfo agreement, EP-S17 malformed-body /
  // transport skip-vs-propagate, EP-U24 unbreakable chip no-overflow) — all
  // live + CI-reachable but absent from the registry until this run.
  'test/features/kvm/platform/query_fragment_control_fail_closed_agreement_test.dart',
  'test/features/kvm/kvm_manager_body_query_fragment_userinfo_agreement_test.dart',
  'test/features/kvm/kvm_service_malformed_body_transport_agreement_test.dart',
  'test/features/kvm/kvm_card_unbreakable_chip_agreement_test.dart',
  // EP-T39 extension: the five newest agreement guards that landed after
  // EP-T37 unpinned (EP-P20 backslash / mixed separator, RM-22 confusable
  // connect-type, EP-S18 same-tier Primary, EP-U25 Primary badge single merged
  // a11y, EP-U22 bidi display text) — all live + CI-reachable but absent from
  // the registry until this run.
  'test/features/kvm/platform/backslash_mixed_separator_agreement_test.dart',
  'test/features/kvm/kvm_connect_type_confusable_agreement_test.dart',
  'test/features/kvm/kvm_service_same_tier_primary_agreement_test.dart',
  'test/features/kvm/kvm_card_primary_badge_single_merged_a11y_test.dart',
  'test/features/kvm/kvm_card_bidi_display_text_a11y_agreement_test.dart',
  // EP-T40 extension: the three newest agreement guards that landed after
  // EP-T39 unpinned (EP-U18 copy-only vs browser-open route agreement, RM-23
  // hostile ConnectUri raw-preservation cross-factory agreement, EP-P21
  // IPv6-literal / zone-id authority cross-layer agreement) — all live +
  // CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_copy_only_browser_open_route_agreement_test.dart',
  'test/features/kvm/kvm_connect_uri_raw_preservation_agreement_test.dart',
  'test/features/kvm/platform/ipv6_literal_authority_agreement_test.dart',
  // EP-T41 extension: four more agreement guards that landed after EP-T40
  // unpinned (RM-18 derived-fallback manager-id control-safety, RM-20
  // registered-OEM hostile-enrichment normalization, EP-S13 cross-surface
  // manager-skip, EP-S14 zero-usable-console surfacing) — all live +
  // CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_manager_id_control_safety_agreement_test.dart',
  'test/features/kvm/kvm_oem_hostile_enrichment_agreement_test.dart',
  'test/features/kvm/kvm_service_manager_skip_agreement_test.dart',
  'test/features/kvm/kvm_service_zero_usable_console_agreement_test.dart',
  // EP-T42 extension: the one agreement guard that landed after EP-T41
  // unpinned (EP-U26-residual console-card "Copied:" SnackBar fail-closed
  // cross-surface agreement) — live + CI-reachable but absent from the
  // registry until this run.
  'test/features/kvm/kvm_card_copy_confirmation_snackbar_agreement_test.dart',
  // EP-T43 extension: the one agreement guard that landed after EP-T42
  // unpinned (RM-24 non-boolean enablement-scalar coercion agreement across
  // both `fromManager` factories + the shared OEM enablement helper) — live +
  // CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_enablement_scalar_coercion_agreement_test.dart',
  // EP-T44 extension: the one agreement guard that landed after EP-T43
  // unpinned (EP-S20 top-level `/Managers` document-shape cross-surface
  // agreement across `fetchConsoles()` / `fetchCapabilities()` /
  // `fetchCapability(id)`) — live + CI-reachable but absent from the registry
  // until this run.
  'test/features/kvm/kvm_service_top_level_shape_agreement_test.dart',
  // EP-T45 extension: the one agreement guard that landed after EP-T44
  // unpinned (EP-P22 degenerate userinfo-edge authority fail-closed cross-layer
  // agreement — empty credential pairs + uppercase-hex escapes across
  // classifier / launch plan / navigation gate / model) — live + CI-reachable
  // but absent from the registry until this run.
  'test/features/kvm/platform/userinfo_edge_authority_agreement_test.dart',
  // EP-T46 extension: the two agreement guards that landed after EP-T45
  // unpinned (RM-25 non-integer session-limit scalar coercion field-for-field
  // cross-factory agreement + EP-P23 degenerate hierarchical-URI form
  // fail-closed cross-layer agreement) — both live + CI-reachable but absent
  // from the registry until this run.
  'test/features/kvm/kvm_session_limit_coercion_agreement_test.dart',
  'test/features/kvm/platform/degenerate_hierarchical_uri_agreement_test.dart',
  // EP-T47 extension: the one agreement guard that landed after EP-T46
  // unpinned (EP-U28 RTL-locale rendering agreement — byte-identical chip
  // sequences + merged announcement sets across both operator cards and the
  // viewer under LTR/RTL at 320/800/1300 px) — live + CI-reachable but absent
  // from the registry until this run.
  'test/features/kvm/kvm_rtl_rendering_agreement_test.dart',
  // EP-T48 extension: the one agreement guard that landed after EP-T47
  // unpinned (EP-S21 hostile OEM console-shape cross-surface agreement —
  // mixed-case / nested / duplicate / empty OEM keys, non-map / list / numeric
  // / bool leaves, explicit disable + byte-exact control, survivor-set /
  // manager-id / URI / enablement / limit agreement across both real
  // `/Managers` walk surfaces) — live + CI-reachable but absent from the
  // registry until this run.
  'test/features/kvm/kvm_service_hostile_oem_shape_agreement_test.dart',
  // EP-T49 extension: the one agreement guard that landed after EP-T48
  // unpinned (RM-26 hostile `ConnectTypesSupported` container-shape cross-factory
  // agreement — bare string / numeric / bool / map / null containers fail closed
  // identically on both `fromManager` normalizers, no one-sided flag flip,
  // valid-list control byte-exact, mixed-container agreement) — live +
  // CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_connect_type_container_shape_agreement_test.dart',
  // EP-T50 extension: the one agreement guard that landed after EP-T49
  // unpinned (EP-U29 degenerate-empty connect-type / blank-label render
  // agreement — blank / whitespace / malformed `ConnectTypesSupported` tokens
  // collapse to an empty chip set identically on both model projections, both
  // operator cards + the viewer emit no empty node / announcement / blank chip
  // at 320/800/1300 px, populated control byte-exact) — live + CI-reachable but
  // absent from the registry until this run.
  'test/features/kvm/kvm_degenerate_empty_connect_type_render_agreement_test.dart',
  // EP-T51 extension: the one agreement guard that landed after EP-T50
  // unpinned (EP-U30 C0-control / Unicode line/paragraph-separator display-text
  // a11y agreement — CR/LF/TAB/NUL/DEL/ESC + U+2028/U+2029/U+00A0 in the
  // manager DISPLAY NAME byte-exact on both operator cards + the viewer at
  // 320/800/1300 px, no split / duplicate / screen-reader-only node, no
  // overflow) — live + CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_card_control_separator_display_text_a11y_agreement_test.dart',
  // EP-T52 extension: the compound-extreme a11y agreement guard landed this
  // run (EP-U31 — one long unbreakable control-bearing connect-type token
  // rendered under RTL AND a 2.0x accessibility text scaler on both operator
  // cards at 320/800/1300 px, one merged visible==announced chip node, no
  // overflow), live + CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_compound_extreme_a11y_agreement_test.dart',
  // EP-T53 extension: the compound bidi-display-name a11y agreement guard
  // landed this run (EP-U32 — a bidi/RTL-control-bearing manager DISPLAY NAME
  // under RTL AND a 2.0x text scaler on both operator cards + the viewer at
  // 320/800/1300 px, full byte-exact name announced + visible in one merged
  // node, no duplicate, no overflow), live + CI-reachable but absent from the
  // registry until this run.
  'test/features/kvm/kvm_bidi_name_rtl_scale_a11y_agreement_test.dart',
  // EP-T54 extension: the compound C0/separator display-name a11y agreement
  // guard landed this run (EP-U33 — a Cc/Zl/Zp/Zs-bearing manager DISPLAY NAME
  // under RTL AND a 2.0x text scaler on both operator cards + the viewer at
  // 320/800/1300 px, full byte-exact name announced + visible in one merged
  // node, no duplicate, no overflow), live + CI-reachable but absent from the
  // registry until this run.
  'test/features/kvm/kvm_control_separator_rtl_scale_a11y_agreement_test.dart',
  // EP-T55 extension: the compound long-unbreakable-name a11y agreement guard
  // landed this run (EP-U34 — a 180-char control-safe unbreakable manager
  // DISPLAY NAME under RTL AND a 2.0x text scaler on both operator cards + the
  // viewer at 320/800/1300 px, full byte-exact name announced + visible in one
  // merged node, no duplicate, no overflow), live + CI-reachable but absent
  // from the registry until this run.
  'test/features/kvm/kvm_long_unbreakable_name_rtl_scale_a11y_agreement_test.dart',
  // EP-T56 extension: the compound control/bidi-bearing connect-type a11y
  // agreement guard landed this run (EP-U35 — bidi Cf / C0 Cc / Zl-bearing
  // CONNECT-TYPE tokens under RTL AND a 2.0x text scaler on both operator cards
  // at 320/800/1300 px, full byte-exact chip sequence + one merged announced
  // connection-types node per card, no duplicate, no overflow), live +
  // CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_connect_type_control_rtl_scale_a11y_agreement_test.dart',
  // EP-T57 extension: the compound RTL x 2.0x shared-notice a11y agreement
  // guard landed this run (EP-U36 — the two shared notices on both operator
  // cards + the viewer at 320/800/1300 px under RTL AND a 2.0x text scaler,
  // full byte-exact copy in one merged node per surface, no duplicate, no
  // overflow), live + CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_notice_rtl_scale_a11y_agreement_test.dart',
  // EP-T58 extension: the compound RTL x 2.0x RAW resolved/connect-URI display
  // a11y agreement guard landed this run (EP-U37 — a control/bidi-bearing raw
  // URI byte-exact in one merged node per operator card at 320/800/1300 px under
  // RTL AND a 2.0x text scaler, viewer pinned fail-closed, no duplicate, no
  // overflow), live + CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_uri_display_rtl_scale_a11y_agreement_test.dart',
  // EP-T59 extension: the compound RTL x 2.0x session-limit row a11y
  // agreement guard landed this run (EP-U38 — the two cards' byte-exact
  // session NUMBER in one merged node each at 320/800/1300 px under RTL AND
  // a 2.0x scaler, boundary encodings, LTR/1.0x control), live + CI-reachable
  // but absent from the registry until this run.
  'test/features/kvm/kvm_session_limit_rtl_scale_a11y_agreement_test.dart',
  // EP-T60 extension: the compound RTL x 2.0x "Primary" badge single-merged a11y
  // agreement guard landed this run (EP-U39 — exactly one visible Primary marker
  // on the pickPrimary winner, inside one merged header node, no
  // split/screen-reader-only announcement, no peer/capability/viewer duplicate,
  // no overflow at 320/800/1300 px under RTL AND a 2.0x scaler, LTR/1.0x
  // control), live + CI-reachable but absent from the registry until this run.
  'test/features/kvm/kvm_primary_badge_rtl_scale_a11y_agreement_test.dart',
  // EP-T61 extension: the control-at-URI-structural-boundary cross-layer
  // fail-closed agreement guard (EP-P25), landed immediately after EP-T60 but
  // deliberately left unpinned; live + CI-reachable but absent from the
  // registry until this run. Registering it makes deleting / emptying /
  // test-stripping it fail closed.
  'test/features/kvm/platform/structural_boundary_control_agreement_test.dart',
  // EP-T62 extension: the non-populated-state RTL x 2.0x a11y agreement guard
  // (EP-U40), landed this run; live + CI-reachable but absent from the registry
  // until now. Registering it makes deleting / emptying / test-stripping it
  // fail closed.
  'test/features/kvm/kvm_nonpopulated_state_rtl_scale_a11y_agreement_test.dart',
  // EP-T63 extension: the IPv6 zone-id / malformed-authority cross-layer
  // fail-closed agreement guard (EP-P27), landed this run; live + CI-reachable
  // but absent from the registry until now. Registering it makes deleting /
  // emptying / test-stripping it fail closed.
  'test/features/kvm/platform/ipv6_zone_id_malformed_authority_agreement_test.dart',
  // EP-T64 extension: the relative / opaque console `ConnectUri`
  // cross-factory fail-closed agreement guard (RM-29), landed this run; live +
  // CI-reachable but absent from the registry until now. Registering it makes
  // deleting / emptying / test-stripping it fail closed.
  'test/features/kvm/kvm_relative_opaque_connect_uri_agreement_test.dart',
  // EP-T65 extension: the console-side userinfo ↔ navigation-target asymmetry
  // agreement guard (EP-P28), landed this run; live + CI-reachable but absent
  // from the registry until now. Registering it makes deleting / emptying /
  // test-stripping it fail closed.
  'test/features/kvm/platform/console_userinfo_navigation_asymmetry_agreement_test.dart',
  // EP-T66 extension: the @odata.nextLink collection-page cross-surface
  // agreement guard (EP-S23), landed this run; live + CI-reachable but absent
  // from the registry until now. Registering it makes deleting / emptying /
  // test-stripping it fail closed.
  'test/features/kvm/kvm_service_nextlink_page_agreement_test.dart',
  // EP-T67 extension: two pre-existing regression guards audited live +
  // CI-reachable but absent from the registry until now. Registering them
  // makes deleting / emptying / test-stripping either fail closed.
  'test/features/kvm/kvm_service_member_order_tie_test.dart',
  'test/features/kvm/kvm_viewer_session_limit_wiring_test.dart',
  // EP-T68 extension: the EP-U41 copy-affordance RTL x 2.0x single-merged a11y
  // agreement guard, landed immediately before this run; live + CI-reachable
  // but absent from the registry until now. Registering it makes deleting /
  // emptying / test-stripping it fail closed.
  'test/features/kvm/kvm_copy_affordance_rtl_scale_a11y_agreement_test.dart',
  // EP-T69 extension: the EP-U42 manager-source fallback-row RTL x 2.0x single-
  // merged a11y agreement guard, landed immediately before this run; live +
  // CI-reachable but absent from the registry until now. Registering it makes
  // deleting / emptying / test-stripping it fail closed.
  'test/features/kvm/kvm_manager_source_row_rtl_scale_a11y_agreement_test.dart',
  // EP-T70 extension: the EP-U27 dense connect-type chip-set single-merged a11y
  // agreement guard, landed immediately before this run; live + CI-reachable
  // but absent from the registry until now. Registering it makes deleting /
  // emptying / test-stripping it fail closed.
  'test/features/kvm/kvm_dense_connect_type_chip_set_a11y_agreement_test.dart',
];

/// The eight guard files named by EP-T12 (the initial canonical set). Pinned so
/// the EP-T20 registry-completeness invariant can account for every entry in
/// [canonicalGuardFiles] without treating the initial set as unpinned churn.
const Set<String> epT12InitialGuards = <String>{
  'test/tool/notice_single_source_guard_test.dart',
  'test/tool/launch_status_single_source_guard_test.dart',
  'test/tool/uri_parse_single_source_guard_test.dart',
  'test/tool/manager_source_display_guard_test.dart',
  'test/features/kvm/platform/product_import_policy_test.dart',
  'test/features/kvm/platform/production_route_invariant_test.dart',
  'test/features/kvm/platform/human_gate_doc_guard_test.dart',
  'test/features/kvm/platform/decision_doc_route_guard_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T14. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping a newer guard
/// back out of the canonical set (issue #009/#021).
const Set<String> epT14AddedGuards = <String>{
  'test/tool/queue_item_schema_guard_test.dart',
  'test/features/kvm/platform/production_optin_construction_guard_test.dart',
  'test/features/kvm/platform/cross_layer_authority_agreement_test.dart',
  'test/features/kvm/kvm_viewer_flagoff_false_claim_guard_test.dart',
  'test/features/kvm/kvm_viewer_disclosure_contract_test.dart',
  'test/features/kvm/kvm_providers_test.dart',
  'test/features/kvm/kvm_session_audit_invariants_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T15. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// behavioral regression guards back out of the canonical set (issue #009/#021).
const Set<String> epT15AddedGuards = <String>{
  'test/features/kvm/kvm_capability_kvmip_fallback_test.dart',
  'test/features/kvm/kvm_manager_source_precedence_test.dart',
  'test/features/kvm/kvm_oem_multi_vendor_enablement_test.dart',
  'test/features/kvm/kvm_controller_dispose_guard_test.dart',
  'test/features/kvm/kvm_service_manager_identity_test.dart',
  'test/features/kvm/kvm_card_cross_surface_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T16. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// widget-level regression guards back out of the canonical set (issue #009/#021).
const Set<String> epT16AddedGuards = <String>{
  'test/features/kvm/kvm_clipboard_cross_surface_agreement_test.dart',
  'test/features/kvm/kvm_view_reload_indicator_test.dart',
  'test/features/kvm/kvm_view_stale_error_banner_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T17. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// post-EP-T16 safety guards back out of the canonical set (issue #009/#021).
const Set<String> epT17AddedGuards = <String>{
  'test/features/kvm/kvm_service_lookup_key_test.dart',
  'test/features/kvm/kvm_oem_depth_bound_agreement_test.dart',
  'test/features/kvm/kvm_view_state_agreement_test.dart',
  'test/features/kvm/platform/validation_evidence_checklist_guard_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T18. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// post-EP-T17 safety guards back out of the canonical set (issue #009/#021).
const Set<String> epT18AddedGuards = <String>{
  'test/features/kvm/kvm_service_capability_primary_agreement_test.dart',
  'test/features/kvm/kvm_viewer_uri_surface_agreement_test.dart',
  'test/features/kvm/kvm_capability_primary_uri_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T19. Pinned separately so a
/// future edit cannot silence a liveness violation by dropping one of the newer
/// post-EP-T18 safety guards back out of the canonical set (issue #009/#021).
const Set<String> epT19AddedGuards = <String>{
  'test/features/kvm/kvm_capability_security_tristate_agreement_test.dart',
  'test/features/kvm/platform/navigation_launch_route_agreement_test.dart',
  'test/features/kvm/kvm_three_surface_launch_target_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added/audited by EP-T20. Pinned
/// separately so a future edit cannot silence a liveness violation by dropping
/// one of these newer guards back out of the canonical set. Note the EP-M6 OEM
/// shadow guard was added directly to the list earlier; it is designated here
/// so the registry-completeness invariant can account for it.
const Set<String> epT20AddedGuards = <String>{
  'test/features/kvm/kvm_oem_uri_shadow_agreement_test.dart',
  'test/features/kvm/kvm_lifecycle_parity_test.dart',
  'test/features/kvm/kvm_notice_surface_audit_test.dart',
  'test/features/kvm/platform/webview_policy_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-U16: the cross-card
/// protocol-specific external-client notice rendered-agreement guard. Pinned
/// separately so a future edit cannot drop it out of the canonical set
/// (issue #009/#021).
const Set<String> epU16AddedGuards = <String>{
  'test/features/kvm/kvm_external_notice_cross_surface_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-M5: the hostile
/// `ConnectTypesSupported` cross-factory agreement guard. Pinned separately so
/// a future edit cannot drop it out of the canonical set (issue #009/#021).
const Set<String> epM5AddedGuards = <String>{
  'test/features/kvm/kvm_connect_types_hostile_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-S2: the `pickPrimary`
/// secure-HTTPS tier-precedence guard. Pinned separately so a future edit
/// cannot drop it out of the canonical set (issue #009/#021).
const Set<String> epS2AddedGuards = <String>{
  'test/features/kvm/kvm_service_primary_secure_tier_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T21: the RM-12
/// `fromManager` cross-factory classifier/label/openability parity guard, which
/// landed after EP-T20 unpinned. Pinned separately so a future edit cannot drop
/// it out of the canonical set (issue #009/#021).
const Set<String> epT21AddedGuards = <String>{
  'test/features/kvm/kvm_external_client_from_manager_parity_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T22: three cross-cutting
/// safety guards (asset policy, unattended-safety policy, credential-leak audit)
/// that were named as part of the guard family by EP-T12 but never registered,
/// so removing / emptying / test-stripping them stayed GREEN. Pinned separately
/// so a future edit cannot drop them back out of the canonical set
/// (issue #009/#021).
const Set<String> epT22AddedGuards = <String>{
  'test/tool/asset_guard_test.dart',
  'test/tool/unattended_guard_test.dart',
  'test/security/credential_leak_audit_test.dart',
};

/// The subset of [canonicalGuardFiles] added by RM-14: the OEM console-block
/// documented direct-key precedence guard. `kvmOemConsoleBlock`'s two-pass
/// search order (direct console-like key before nested vendor block) was
/// documented but unpinned; a reversed-order refactor would re-point both KVM
/// views' OEM endpoint and source the enablement flag from a different node,
/// with every pre-existing single-console OEM test staying GREEN. Pinned
/// separately so a future edit cannot drop it back out of the canonical set
/// (issue #009/#021).
const Set<String> rm14AddedGuards = <String>{
  'test/features/kvm/kvm_oem_block_precedence_test.dart',
};

/// The subset of [canonicalGuardFiles] added by RM-13: the enablement-regime
/// decision-boundary characterization guard (agreeing-regime byte-for-byte
/// agreement plus the deferred RM-11 mixed-regime divergence record). Pinned
/// separately so a future edit cannot drop it back out of the canonical set
/// (issue #009/#021).
const Set<String> rm13AddedGuards = <String>{
  'test/features/kvm/kvm_enablement_regime_boundary_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-S9: the credential-bearing
/// Primary ↔ navigation-gate decision-boundary characterization guard. Pinned
/// separately so a future edit cannot drop it out of the canonical set
/// (issue #009/#021).
const Set<String> epS9AddedGuards = <String>{
  'test/features/kvm/kvm_credential_primary_navigation_boundary_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T23: the EP-U8/EP-U17
/// no-WebView final-route affordance agreement guard, which landed after
/// EP-S9 unpinned. Pinned separately so a future edit cannot drop it out of
/// the canonical set (issue #009/#021).
const Set<String> epT23AddedGuards = <String>{
  'test/features/kvm/kvm_open_affordance_gating_test.dart',
};

/// The subset of [canonicalGuardFiles] added by RM-15: the bidi/confusable
/// manager-source cross-factory agreement guard. The two `fromManager`
/// factories already agree and fail closed over the bidi format family and
/// confusable-host matrix, but nothing pinned that agreement — a one-sided gate
/// edit could leak a bidi marker onto one card's source row / clipboard while
/// the other card stayed GREEN. Pinned separately so a future edit cannot drop
/// it out of the canonical set (issue #009/#021).
const Set<String> rm15AddedGuards = <String>{
  'test/features/kvm/kvm_manager_source_bidi_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-P13: the scheme-relative /
/// network-path / encoded-authority cross-layer fail-closed agreement guard,
/// which landed with EP-P13 but stayed unpinned (absent from the canonical set
/// and every epoch), so deleting / emptying / test-stripping it stayed GREEN.
/// Pinned separately so a future edit cannot drop it back out of the canonical
/// set (issue #009/#021).
const Set<String> epP13AddedGuards = <String>{
  'test/features/kvm/platform/navigation_launch_authority_confusion_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by SEC-010: the four cross-cutting
/// `#010` security-hardening guards (TLS self-signed enforcement, `https → http`
/// TLS-downgrade rejection, auth-token isolation and no-plaintext persistence).
/// They were live + reachable from verify.yml's whole-tree coverage but never
/// registered, so deleting / emptying / test-stripping one stayed GREEN even
/// though it guards production TLS (never weakened). Pinned separately so a
/// future edit cannot drop them back out of the canonical set (issues
/// #009/#021 guard-suite closeout).
const Set<String> sec010AddedGuards = <String>{
  'test/security/tls_enforcement_test.dart',
  'test/security/tls_downgrade_test.dart',
  'test/security/token_isolation_test.dart',
  'test/security/no_plaintext_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T26: the three agreement
/// guards that landed after SEC-010 unpinned (EP-P14 launch-plan scheme-spelling
/// matrix, EP-U19 cross-surface chip + session-limit agreement, RM-16 hostile
/// enablement-flag encoding agreement). Each is live + CI-reachable but was
/// absent from the registry, so deleting / emptying / test-stripping one stayed
/// GREEN. Pinned separately so a future edit cannot drop them back out of the
/// canonical set (issues #009/#021 guard-suite closeout).
const Set<String> epT26AddedGuards = <String>{
  'test/features/kvm/platform/launch_plan_scheme_spelling_matrix_test.dart',
  'test/features/kvm/kvm_card_chip_session_agreement_test.dart',
  'test/features/kvm/kvm_enablement_encoding_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T28: the EP-U20
/// extreme-content cross-card rendered agreement guard, which landed after
/// EP-T26 unpinned.
/// It is live + CI-reachable but was absent from the registry, so deleting /
/// emptying / test-stripping it stayed GREEN. Pinned separately so a future edit
/// cannot drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT28AddedGuards = <String>{
  'test/features/kvm/kvm_card_extreme_content_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T29: the RM-17
/// duplicate / case-variant console-block key-collision cross-factory agreement
/// guard, which landed after EP-T28 unpinned. It is live + CI-reachable but was
/// absent from the registry, so deleting / emptying / test-stripping it stayed
/// GREEN. Pinned separately so a future edit cannot drop it back out of the
/// canonical set (issues #009/#021 closeout).
const Set<String> epT29AddedGuards = <String>{
  'test/features/kvm/kvm_key_collision_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T30: the EP-M4
/// RemoteConsole-only + explicit-disable cross-view parity guard, which landed
/// after EP-T29 unpinned. It is live + CI-reachable but was absent from the
/// registry, so deleting / emptying / test-stripping it stayed GREEN. Pinned
/// separately so a future edit cannot drop it back out of the canonical set
/// (issues #009/#021 closeout).
const Set<String> epT30AddedGuards = <String>{
  'test/features/kvm/kvm_remote_console_disable_parity_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T32: the EP-P16
/// nonstandard-port authority fail-closed cross-layer agreement guard, which
/// landed with EP-P16 unpinned. It is live + CI-reachable but was absent from
/// the registry, so deleting / emptying / test-stripping it stayed GREEN.
/// Pinned separately so a future edit cannot drop it back out of the canonical
/// set (issues #009/#021 closeout).
const Set<String> epT32AddedGuards = <String>{
  'test/features/kvm/platform/port_authority_fail_closed_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T33: the EP-U21
/// large-accessibility-font no-overflow + merged-a11y cross-surface guard,
/// which landed with EP-U21 unpinned. It is live + CI-reachable but was absent
/// from the registry, so deleting / emptying / test-stripping it stayed GREEN.
/// Pinned separately so a future edit cannot drop it back out of the canonical
/// set (issues #009/#021 closeout).
const Set<String> epT33AddedGuards = <String>{
  'test/features/kvm/kvm_large_font_cross_surface_a11y_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T35: the three newest
/// agreement guards (EP-M7 body-path normalization, EP-S12 malformed Members,
/// EP-P17 encoded userinfo fail-closed). All three landed unpinned, live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping any of them stayed GREEN. Pinned separately so a future edit
/// cannot drop them back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT35AddedGuards = <String>{
  'test/features/kvm/kvm_manager_body_path_normalization_agreement_test.dart',
  'test/features/kvm/kvm_service_malformed_members_agreement_test.dart',
  'test/features/kvm/platform/userinfo_authority_fail_closed_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T36: the four newest
/// agreement guards (EP-U23 full-name announcement, EP-S10 all-unsafe primary,
/// EP-S16 Unicode-id distinctness, EP-P18 canonical-tricky authority). All four
/// landed unpinned, live + CI-reachable but absent from the registry, so
/// deleting / emptying / test-stripping any of them stayed GREEN. Pinned
/// separately so a future edit cannot drop them back out of the canonical set
/// (issues #009/#021 closeout).
const Set<String> epT36AddedGuards = <String>{
  'test/features/kvm/kvm_card_full_name_announcement_agreement_test.dart',
  'test/features/kvm/kvm_service_all_unsafe_primary_agreement_test.dart',
  'test/features/kvm/kvm_service_unicode_id_distinctness_test.dart',
  'test/features/kvm/platform/canonical_tricky_authority_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T37: the four newest
/// agreement guards (EP-P19 query/fragment control fail-closed cross-layer,
/// RM-21 body-id query/fragment/userinfo agreement, EP-S17 malformed-body /
/// transport skip-vs-propagate, EP-U24 unbreakable chip no-overflow). All four
/// landed unpinned, live + CI-reachable but absent from the registry, so
/// deleting / emptying / test-stripping any of them stayed GREEN. Pinned
/// separately so a future edit cannot drop them back out of the canonical set
/// (issues #009/#021 closeout).
const Set<String> epT37AddedGuards = <String>{
  'test/features/kvm/platform/query_fragment_control_fail_closed_agreement_test.dart',
  'test/features/kvm/kvm_manager_body_query_fragment_userinfo_agreement_test.dart',
  'test/features/kvm/kvm_service_malformed_body_transport_agreement_test.dart',
  'test/features/kvm/kvm_card_unbreakable_chip_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T39: the five newest
/// agreement guards (EP-P20 backslash / mixed separator, RM-22 confusable
/// connect-type, EP-S18 same-tier Primary, EP-U25 Primary badge single merged
/// a11y, EP-U22 bidi display text). All five landed unpinned, live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping any of them stayed GREEN. Pinned separately so a future edit
/// cannot drop them back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT39AddedGuards = <String>{
  'test/features/kvm/platform/backslash_mixed_separator_agreement_test.dart',
  'test/features/kvm/kvm_connect_type_confusable_agreement_test.dart',
  'test/features/kvm/kvm_service_same_tier_primary_agreement_test.dart',
  'test/features/kvm/kvm_card_primary_badge_single_merged_a11y_test.dart',
  'test/features/kvm/kvm_card_bidi_display_text_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T40: the three newest
/// agreement guards (EP-U18 copy-only vs browser-open route agreement, RM-23
/// hostile ConnectUri raw-preservation cross-factory agreement, EP-P21
/// IPv6-literal / zone-id authority cross-layer agreement). All three landed
/// unpinned, live + CI-reachable but absent from the registry, so deleting /
/// emptying / test-stripping any of them stayed GREEN. Pinned separately so a
/// future edit cannot drop them back out of the canonical set (issues #009/#021
/// closeout).
const Set<String> epT40AddedGuards = <String>{
  'test/features/kvm/kvm_copy_only_browser_open_route_agreement_test.dart',
  'test/features/kvm/kvm_connect_uri_raw_preservation_agreement_test.dart',
  'test/features/kvm/platform/ipv6_literal_authority_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T41: four more agreement
/// guards that landed unpinned (RM-18 derived-fallback manager-id control-safety,
/// RM-20 registered-OEM hostile-enrichment normalization, EP-S13 cross-surface
/// manager-skip, EP-S14 zero-usable-console surfacing). All four landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping any of them stayed GREEN. Pinned separately so a future edit
/// cannot drop them back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT41AddedGuards = <String>{
  'test/features/kvm/kvm_manager_id_control_safety_agreement_test.dart',
  'test/features/kvm/kvm_oem_hostile_enrichment_agreement_test.dart',
  'test/features/kvm/kvm_service_manager_skip_agreement_test.dart',
  'test/features/kvm/kvm_service_zero_usable_console_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T42: the one agreement
/// guard that landed after EP-T41 unpinned (EP-U26-residual console-card
/// "Copied:" SnackBar fail-closed cross-surface agreement). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT42AddedGuards = <String>{
  'test/features/kvm/kvm_card_copy_confirmation_snackbar_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T43: the one agreement
/// guard that landed after EP-T42 unpinned (RM-24 non-boolean enablement-scalar
/// coercion agreement across both `fromManager` factories + the shared OEM
/// enablement helper). It landed live + CI-reachable but absent from the
/// registry, so deleting / emptying / test-stripping it stayed GREEN. Pinned
/// separately so a future edit cannot drop it back out of the canonical set
/// (issues #009/#021 closeout).
const Set<String> epT43AddedGuards = <String>{
  'test/features/kvm/kvm_enablement_scalar_coercion_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T44: the one agreement
/// guard that landed after EP-T43 unpinned (EP-S20 top-level `/Managers`
/// document-shape cross-surface agreement across `fetchConsoles()` /
/// `fetchCapabilities()` / `fetchCapability(id)`). It landed live + CI-reachable
/// but absent from the registry, so deleting / emptying / test-stripping it
/// stayed GREEN. Pinned separately so a future edit cannot drop it back out of
/// the canonical set (issues #009/#021 closeout).
const Set<String> epT44AddedGuards = <String>{
  'test/features/kvm/kvm_service_top_level_shape_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T45: the one agreement
/// guard that landed after EP-T44 unpinned (EP-P22 degenerate userinfo-edge
/// authority fail-closed cross-layer agreement — empty credential pairs
/// `https://:@host` / `https://user:@host` and uppercase-hex escapes across
/// classifier / launch plan / navigation gate / model). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT45AddedGuards = <String>{
  'test/features/kvm/platform/userinfo_edge_authority_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T46: the two agreement
/// guards that landed after EP-T45 unpinned (RM-25 non-integer
/// `MaxConcurrentSessions` scalar coercion field-for-field agreement across both
/// `fromManager` factories + the shared `kvmSessionLimit` helper, and EP-P23
/// degenerate hierarchical-URI form fail-closed cross-layer agreement — opaque /
/// single-slash / empty-authority / scheme-only HTTPS forms across classifier /
/// HTTP family / launch plan / navigation gate / model). Both landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping either stayed GREEN. Pinned separately so a future edit cannot
/// drop them back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT46AddedGuards = <String>{
  'test/features/kvm/kvm_session_limit_coercion_agreement_test.dart',
  'test/features/kvm/platform/degenerate_hierarchical_uri_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T47: the one agreement
/// guard that landed after EP-T46 unpinned (EP-U28 RTL-locale rendering
/// agreement — byte-identical chip sequences + merged `excludeSemantics`
/// announcement sets across both operator cards and the viewer under LTR and
/// RTL at 320/800/1300 px). It landed live + CI-reachable but absent from the
/// registry, so deleting / emptying / test-stripping it stayed GREEN. Pinned
/// separately so a future edit cannot drop it back out of the canonical set
/// (issues #009/#021 closeout).
const Set<String> epT47AddedGuards = <String>{
  'test/features/kvm/kvm_rtl_rendering_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T48: the one agreement
/// guard that landed after EP-T47 unpinned (EP-S21 hostile OEM console-shape
/// cross-surface agreement — survivor-set / manager-id / URI / enablement /
/// limit agreement across both real `/Managers` walk surfaces under a hostile
/// OEM-shape matrix, with never-throw and `fetchCapability(id)` agreement). It
/// landed live + CI-reachable but absent from the registry, so deleting /
/// emptying / test-stripping it stayed GREEN. Pinned separately so a future
/// edit cannot drop it back out of the canonical set (issues #009/#021
/// closeout).
const Set<String> epT48AddedGuards = <String>{
  'test/features/kvm/kvm_service_hostile_oem_shape_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T49: the one agreement
/// guard that landed after EP-T48 unpinned (RM-26 hostile `ConnectTypesSupported`
/// container-shape cross-factory agreement — bare string / numeric / bool / map
/// / null containers fail closed identically on both `fromManager` normalizers,
/// never flip `supportsHtml5` / `supportsKvmIp` / `supported` on one surface,
/// valid-list control byte-exact, mixed-container agreement). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT49AddedGuards = <String>{
  'test/features/kvm/kvm_connect_type_container_shape_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T50: the one agreement guard
/// that landed after EP-T49 unpinned (EP-U29 degenerate-empty connect-type /
/// blank-label render agreement — blank / whitespace / malformed
/// `ConnectTypesSupported` tokens collapse to an empty chip set identically on
/// both model projections; at 320/800/1300 px both operator cards + the viewer
/// emit no empty node / announcement / blank chip, populated control
/// byte-exact). It landed live + CI-reachable but absent from the registry, so
/// deleting / emptying / test-stripping it stayed GREEN. Pinned separately so a
/// future edit cannot drop it back out of the canonical set (issues #009/#021
/// closeout).
const Set<String> epT50AddedGuards = <String>{
  'test/features/kvm/kvm_degenerate_empty_connect_type_render_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T51: the one agreement guard
/// that landed after EP-T50 unpinned (EP-U30 C0-control / Unicode
/// line/paragraph-separator display-text a11y agreement — CR/LF/TAB/NUL/DEL/ESC
/// + U+2028/U+2029/U+00A0 in the manager DISPLAY NAME byte-exact on both
/// operator cards + the viewer at 320/800/1300 px, no split / duplicate /
/// screen-reader-only node, no overflow). It landed live + CI-reachable but
/// absent from the registry, so deleting / emptying / test-stripping it stayed
/// GREEN. Pinned separately so a future edit cannot drop it back out of the
/// canonical set (issues #009/#021 closeout).
const Set<String> epT51AddedGuards = <String>{
  'test/features/kvm/kvm_card_control_separator_display_text_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T52: the one agreement guard
/// landed this run after EP-T51 (EP-U31 compound-extreme a11y agreement — a
/// 400-char unbreakable connect-type token under RTL AND 2.0x text scale on
/// both operator cards at 320/800/1300 px, byte-exact chip sequence, one merged
/// visible==announced node, no overflow). It is pinned separately so a future
/// edit cannot drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT52AddedGuards = <String>{
  'test/features/kvm/kvm_compound_extreme_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T53: the one agreement guard
/// landed this run after EP-T52 (EP-U32 compound bidi-display-name x RTL x 2.0x
/// text-scaler a11y agreement — a bidi/RTL-control-bearing manager DISPLAY NAME
/// under RTL AND a 2.0x text scaler on both operator cards + the viewer at
/// 320/800/1300 px, full byte-exact name announced + visible in one merged
/// node, no duplicate, no overflow). Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT53AddedGuards = <String>{
  'test/features/kvm/kvm_bidi_name_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T54: the one agreement guard
/// landed this run after EP-T53 (EP-U33 compound C0-control / Unicode
/// line-paragraph-SEPARATOR display-name x RTL x 2.0x text-scaler a11y
/// agreement — a Cc/Zl/Zp/Zs-bearing manager DISPLAY NAME under RTL AND a 2.0x
/// text scaler on both operator cards + the viewer at 320/800/1300 px, full
/// byte-exact name announced + visible in one merged node, no duplicate, no
/// overflow). Pinned separately so a future edit cannot drop it back out of
/// the canonical set (issues #009/#021 closeout).
const Set<String> epT54AddedGuards = <String>{
  'test/features/kvm/kvm_control_separator_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T55: the one agreement guard
/// landed this run after EP-T54 (EP-U34 compound long-unbreakable-display-name
/// x RTL x 2.0x text-scaler a11y agreement — a 180-char control-safe unbreakable
/// manager DISPLAY NAME under RTL AND a 2.0x text scaler on both operator cards
/// + the viewer at 320/800/1300 px, full byte-exact name announced + visible in
/// one merged node per surface, no duplicate, no overflow). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT55AddedGuards = <String>{
  'test/features/kvm/kvm_long_unbreakable_name_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T56: the one agreement guard
/// landed this run after EP-T55 (EP-U35 compound control/bidi-bearing
/// connect-type a11y agreement — bidi Cf / C0 Cc / Zl-bearing CONNECT-TYPE
/// tokens under RTL AND a 2.0x text scaler on both operator cards at
/// 320/800/1300 px, full byte-exact chip sequence + one merged announced
/// connection-types node per card, no duplicate, no overflow). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT56AddedGuards = <String>{
  'test/features/kvm/kvm_connect_type_control_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T57: the one agreement guard
/// landed this run after EP-T56 (EP-U36 compound RTL x 2.0x shared-notice a11y
/// agreement — the two shared notices on both operator cards + the viewer at
/// 320/800/1300 px under RTL AND a 2.0x text scaler, full byte-exact copy in one
/// merged node per surface, no duplicate, no overflow). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT57AddedGuards = <String>{
  'test/features/kvm/kvm_notice_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T58: the one agreement guard
/// landed this run after EP-T57 (EP-U37 compound RTL x 2.0x RAW resolved/connect
/// URI display a11y agreement — the two operator cards' byte-exact raw URI in
/// one merged node per card at 320/800/1300 px under RTL AND a 2.0x text scaler,
/// the viewer pinned fail-closed, no duplicate, no overflow). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT58AddedGuards = <String>{
  'test/features/kvm/kvm_uri_display_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T59: the one agreement guard
/// landed this run after EP-T58 (EP-U38 compound RTL x 2.0x session-limit row
/// a11y agreement — the two cards' byte-exact session NUMBER in one merged
/// visible==announced node each at 320/800/1300 px under RTL AND a 2.0x scaler,
/// boundary encodings, LTR/1.0x control). It landed live + CI-reachable but
/// absent from the registry, so deleting / emptying / test-stripping it stayed
/// GREEN. Pinned separately so a future edit cannot drop it back out of the
/// canonical set (issues #009/#021 closeout).
const Set<String> epT59AddedGuards = <String>{
  'test/features/kvm/kvm_session_limit_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T60: the one agreement guard
/// landed this run after EP-T59 (EP-U39 compound RTL x 2.0x "Primary" badge
/// single-merged a11y agreement — exactly one visible marker on the pickPrimary
/// winner, inside one merged header node, no split/screen-reader-only
/// announcement, no peer/capability/viewer duplicate, no overflow at
/// 320/800/1300 px under RTL AND a 2.0x scaler, LTR/1.0x control). It landed
/// live + CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT60AddedGuards = <String>{
  'test/features/kvm/kvm_primary_badge_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T61: the one agreement guard
/// landed immediately after EP-T60 but deliberately left unpinned (EP-P25
/// control-at-URI-structural-boundary cross-layer fail-closed agreement — a
/// 12-case hostile control-at-boundary matrix plus 3 clean spellings pinned
/// field-for-field across the classifier / control-safety core,
/// `planConsoleLaunch` (incl. the stale-flag test-only opt-in TLS boundary),
/// `allowsInAppNavigation` (both directions) and the `KvmConsole` model, with
/// the same-origin userinfo-NUL case pinning the `Uri.tryParse` origin
/// differential). It landed live + CI-reachable but absent from the registry,
/// so deleting / emptying / test-stripping it stayed GREEN. Pinned separately
/// so a future edit cannot drop it back out of the canonical set (issues
/// #009/#021 closeout).
const Set<String> epT61AddedGuards = <String>{
  'test/features/kvm/platform/structural_boundary_control_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T62: the one compound a11y
/// agreement guard landed this run (EP-U40 non-populated-state RTL x 2.0x a11y
/// agreement — the five non-populated KvmView states each pinned to ONE merged
/// `excludeSemantics` node with visible==announced, no duplicate /
/// screen-reader-only node, no overflow at 320/800/1300 px under RTL + a 2.0x
/// scaler, LTR/1.0x + populated controls). It landed live + CI-reachable but
/// absent from the registry, so deleting / emptying / test-stripping it stayed
/// GREEN. Pinned separately so a future edit cannot drop it back out of the
/// canonical set (issues #009/#021 closeout).
const Set<String> epT62AddedGuards = <String>{
  'test/features/kvm/kvm_nonpopulated_state_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T63: the one cross-layer
/// fail-closed agreement guard landed this run (EP-P27 IPv6 zone-id /
/// malformed-authority — a scoped zone id, a control / bidi / separator-bearing
/// zone, a malformed bracket / percent spelling and IPv4-mapped forms pinned
/// field-for-field across the classifier / launch plan / navigation gate / model
/// with clean IPv6 / IPv4 controls). It landed live + CI-reachable but absent
/// from the registry, so deleting / emptying / test-stripping it stayed GREEN.
/// Pinned separately so a future edit cannot drop it back out of the canonical
/// set (issues #009/#021 closeout).
const Set<String> epT63AddedGuards = <String>{
  'test/features/kvm/platform/ipv6_zone_id_malformed_authority_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T64: the one cross-factory
/// fail-closed agreement guard landed this run (RM-29 relative / opaque console
/// `ConnectUri` — relative paths, scheme-relative / opaque / query-only forms,
/// control-bearing relatives and a clean HTTPS control pinned field-for-field
/// across both `fromManager` factories, the transport classifiers, the fail-
/// closed launch plan, the copyable target and never-throw on non-string). It
/// landed live + CI-reachable but absent from the registry, so deleting /
/// emptying / test-stripping it stayed GREEN. Pinned separately so a future edit
/// cannot drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT64AddedGuards = <String>{
  'test/features/kvm/kvm_relative_opaque_connect_uri_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T65: the one cross-layer
/// navigation asymmetry guard landed this run (EP-P28 console-side userinfo —
/// the credentialed-initial-load vs navigation-target asymmetry pinned across
/// path / query variants, default-port normalization, origin confinement,
/// non-HTTPS fail-closed and the launch-plan in-app exception). It landed live +
/// CI-reachable but absent from the registry, so deleting / emptying /
/// test-stripping it stayed GREEN. Pinned separately so a future edit cannot
/// drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT65AddedGuards = <String>{
  'test/features/kvm/platform/console_userinfo_navigation_asymmetry_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T66: the one cross-surface
/// `@odata.nextLink` collection-page agreement guard landed this run (EP-S23 —
/// both `/Managers` discovery surfaces adopt the same page set with no ghost
/// `fetchCapability(id)` lookup and no double-count of a repeated member, over
/// absolute/query/relative/scheme-relative/blank/non-string link roots). It
/// landed live + CI-reachable but absent from the registry, so deleting /
/// emptying / test-stripping it stayed GREEN. Pinned separately so a future edit
/// cannot drop it back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT66AddedGuards = <String>{
  'test/features/kvm/kvm_service_nextlink_page_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T67: two pre-existing
/// regression guards audited live + CI-reachable but absent from every earlier
/// designation (a confirmed "who guards the guards" gap). EP-S11 pins
/// first-in-BMC-order tie determinism across all four service surfaces; EP-U4
/// pins the real-viewer maxConcurrentSessions pass-through to the shared
/// session controller. Pinned separately so a future edit cannot drop either
/// back out of the canonical set (issues #009/#021 closeout).
const Set<String> epT67AddedGuards = <String>{
  'test/features/kvm/kvm_service_member_order_tie_test.dart',
  'test/features/kvm/kvm_viewer_session_limit_wiring_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T68: the one compound a11y
/// agreement guard that landed immediately before this run but was left
/// unpinned (EP-U41 — the fail-closed copy affordances on both the console card
/// and the viewer each pinned to exactly one merged visible==announced
/// `excludeSemantics` node, no split / reworded screen-reader-only node, no
/// overflow at 320/800/1300 px under RTL AND a 2.0x scaler, LTR/1.0x control).
/// It landed live + CI-reachable but absent from the registry, so deleting /
/// emptying / test-stripping it stayed GREEN. Pinned separately so a future
/// edit cannot drop it back out of the canonical set (issues #009/#021
/// closeout).
const Set<String> epT68AddedGuards = <String>{
  'test/features/kvm/kvm_copy_affordance_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T69: the one compound a11y
/// agreement guard that landed immediately before this run but was left
/// unpinned (EP-U42 — each no-URI manager-source fallback row on both operator
/// cards + the viewer pinned to one merged visible==announced
/// `excludeSemantics` node with the full byte-exact `safeManagerUri`, no split /
/// reworded screen-reader-only node, no overflow at 320/800/1300 px under RTL
/// AND a 2.0x scaler, LTR/1.0x control). It landed live + CI-reachable but
/// absent from the registry, so deleting / emptying / test-stripping it stayed
/// GREEN. Pinned separately so a future edit cannot drop it back out of the
/// canonical set (issues #009/#021 closeout).
const Set<String> epT69AddedGuards = <String>{
  'test/features/kvm/kvm_manager_source_row_rtl_scale_a11y_agreement_test.dart',
};

/// The subset of [canonicalGuardFiles] added by EP-T70: the one compound a11y
/// agreement guard that landed immediately before this run but was left
/// unpinned (EP-U27 — a 13-token dense hostile / fullwidth / confusable
/// `ConnectTypesSupported` set byte-exact on both `fromManager` factories and
/// on both real operator cards at 320/800/1300 px, one merged
/// `excludeSemantics` chip-row node each, visible == model chips, no
/// screen-reader-only split chip, no RenderFlex overflow, small clean control).
/// It landed live + CI-reachable but absent from the registry, so deleting /
/// emptying / test-stripping it stayed GREEN. Pinned separately so a future
/// edit cannot drop it back out of the canonical set (issues #009/#021
/// closeout).
const Set<String> epT70AddedGuards = <String>{
  'test/features/kvm/kvm_dense_connect_type_chip_set_a11y_agreement_test.dart',
};

/// Every epoch-designated guard: the EP-T12 initial set plus every pinned
/// epT*AddedGuards extension. EP-T20 requires this to equal
/// [canonicalGuardFiles] in both directions, so a guard added directly to the
/// registry without a pinned designation fails closed (issue #009/#021).
const Set<String> allDesignatedGuards = <String>{
  ...epT12InitialGuards,
  ...epT14AddedGuards,
  ...epT15AddedGuards,
  ...epT16AddedGuards,
  ...epT17AddedGuards,
  ...epT18AddedGuards,
  ...epT19AddedGuards,
  ...epT20AddedGuards,
  ...epU16AddedGuards,
  ...epM5AddedGuards,
  ...epS2AddedGuards,
  ...epT21AddedGuards,
  ...epT22AddedGuards,
  ...rm14AddedGuards,
  ...rm13AddedGuards,
  ...epS9AddedGuards,
  ...epT23AddedGuards,
  ...rm15AddedGuards,
  ...epP13AddedGuards,
  ...sec010AddedGuards,
  ...epT26AddedGuards,
  ...epT28AddedGuards,
  ...epT29AddedGuards,
  ...epT30AddedGuards,
  ...epT32AddedGuards,
  ...epT33AddedGuards,
  ...epT35AddedGuards,
  ...epT36AddedGuards,
  ...epT37AddedGuards,
  ...epT39AddedGuards,
  ...epT40AddedGuards,
  ...epT41AddedGuards,
  ...epT42AddedGuards,
  ...epT43AddedGuards,
  ...epT44AddedGuards,
  ...epT45AddedGuards,
  ...epT46AddedGuards,
  ...epT47AddedGuards,
  ...epT48AddedGuards,
  ...epT49AddedGuards,
  ...epT50AddedGuards,
  ...epT51AddedGuards,
  ...epT52AddedGuards,
  ...epT53AddedGuards,
  ...epT54AddedGuards,
  ...epT55AddedGuards,
  ...epT56AddedGuards,
  ...epT57AddedGuards,
  ...epT58AddedGuards,
  ...epT59AddedGuards,
  ...epT60AddedGuards,
  ...epT61AddedGuards,
  ...epT62AddedGuards,
  ...epT63AddedGuards,
  ...epT64AddedGuards,
  ...epT65AddedGuards,
  ...epT66AddedGuards,
  ...epT67AddedGuards,
  ...epT68AddedGuards,
  ...epT69AddedGuards,
  ...epT70AddedGuards,
};

/// Normalizes a path for comparison (Windows separators + a leading `./`).
String normalizePath(String path) =>
    path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

bool _isWordChar(String c) {
  final int u = c.codeUnitAt(0);
  return (u >= 48 && u <= 57) ||
      (u >= 65 && u <= 90) ||
      (u >= 97 && u <= 122) ||
      c == '_';
}

/// Removes `//` line comments, `/* */` block comments and string-literal
/// contents, keeping newlines. A guard file whose only "test(" appears in a
/// comment or string is NOT a live test case; scanning code tokens only keeps
/// this liveness guard honest (a commented-out guard cannot fake GREEN).
/// Raw strings (`r'...'`) are handled: a backslash is literal there, so `r'\'`
/// closes at the following quote instead of swallowing the rest of the file.
String stripCommentsAndStrings(String source) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  final int n = source.length;
  while (i < n) {
    final String c = source[i];
    if (c == '/' && i + 1 < n && source[i + 1] == '/') {
      while (i < n && source[i] != '\n') {
        i++;
      }
      out.write(' ');
      continue;
    }
    if (c == '/' && i + 1 < n && source[i + 1] == '*') {
      i += 2;
      while (i + 1 < n && !(source[i] == '*' && source[i + 1] == '/')) {
        i++;
      }
      i = i + 2 < n ? i + 2 : n;
      out.write(' ');
      continue;
    }
    if (c == "'" || c == '"') {
      final bool raw = i >= 1 &&
          (source[i - 1] == 'r' || source[i - 1] == 'R') &&
          (i < 2 || !_isWordChar(source[i - 2]));
      final String quote = c;
      final bool triple =
          i + 2 < n && source[i + 1] == quote && source[i + 2] == quote;
      i += triple ? 3 : 1;
      out.write(' ');
      while (i < n) {
        if (!raw && source[i] == r'\') {
          i += 2;
          continue;
        }
        if (triple) {
          if (i + 2 < n &&
              source[i] == quote &&
              source[i + 1] == quote &&
              source[i + 2] == quote) {
            i += 3;
            break;
          }
        } else if (source[i] == quote) {
          i += 1;
          break;
        }
        if (source[i] == '\n') {
          out.write('\n');
        }
        i++;
      }
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Number of live `test(...)` / `testWidgets(...)` cases in [source].
int countTestCases(String source) => RegExp(r'\btest(?:Widgets)?\s*\(')
    .allMatches(stripCommentsAndStrings(source))
    .length;

/// Evaluates a guard suite given a map of normalized path → file content and
/// the CI workflow source. Returns a list of fail-closed violations (empty means
/// the suite is intact). A missing path in [sources] is reported as MISSING.
List<String> evaluateGuardSuite(
  Map<String, String> sources,
  String verifySource,
) {
  final List<String> violations = <String>[];
  for (final String path in canonicalGuardFiles) {
    final String? source = sources[normalizePath(path)];
    if (source == null) {
      violations.add('MISSING: $path');
      continue;
    }
    if (source.trim().isEmpty) {
      violations.add('EMPTY: $path');
      continue;
    }
    if (countTestCases(source) == 0) {
      violations.add('NO_TEST_CASES: $path');
    }
  }
  // Reachable by the standard CI run: verify.yml must still invoke the
  // whole-tree `flutter test --coverage` (no path filter that could skip a
  // guard directory). Preserve the exact machine-checkable contract.
  final bool standardRun = RegExp(
    r'flutter\s+test\b[^\n]*--coverage',
  ).hasMatch(verifySource.replaceAll('\r', ''));
  if (!standardRun) {
    violations.add(
      'UNREACHABLE: verify.yml no longer runs "flutter test --coverage"',
    );
  }
  return violations;
}

/// Reads the canonical guard files present under [root] into a path → content
/// map. Missing files are omitted so [evaluateGuardSuite] reports MISSING.
Map<String, String> readSuite(Directory root) {
  final Map<String, String> sources = <String, String>{};
  for (final String path in canonicalGuardFiles) {
    final String rel = path.replaceAll('/', Platform.pathSeparator);
    final File file = File(
      '${root.path}${Platform.pathSeparator}$rel',
    );
    if (file.existsSync()) {
      sources[normalizePath(path)] = file.readAsStringSync();
    }
  }
  return sources;
}

/// Minimal but genuine synthetic guard source for the temp-root proof: one live
/// `test(...)` case, so it passes the liveness evaluator when intact.
const String syntheticGuardSource = '''
// synthetic guard
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('liveness', () {});
}
''';

void main() {
  group('EP-T12 guard-suite liveness evaluator (pure)', () {
    test('canonical inventory is non-empty and all files end in _test.dart',
        () {
      expect(canonicalGuardFiles, isNotEmpty);
      for (final String path in canonicalGuardFiles) {
        expect(path, endsWith('_test.dart'), reason: path);
        expect(path.startsWith('test/'), isTrue, reason: path);
      }
      // No duplicate entries that would mask a missing guard.
      expect(canonicalGuardFiles.toSet().length, canonicalGuardFiles.length);
    });

    test('intact synthetic suite + standard CI run is clean', () {
      final Map<String, String> sources = <String, String>{
        for (final String path in canonicalGuardFiles)
          normalizePath(path): syntheticGuardSource,
      };
      expect(
        evaluateGuardSuite(sources, '  run: flutter test --coverage\n'),
        isEmpty,
      );
    });

    test('commented-out test does not count as a live case', () {
      final String commented = stripCommentsAndStrings(
        "// test('fake', () {});\nvoid main() {}\n",
      );
      expect(RegExp(r'\btest\s*\(').hasMatch(commented), isFalse);
    });

    test('string-literal test( does not count as a live case', () {
      final String inString = stripCommentsAndStrings(
        "const String s = 'test( fake';\nvoid main() {}\n",
      );
      expect(RegExp(r'\btest\s*\(').hasMatch(inString), isFalse);
    });

    test('EP-T14: every post-EP-T12 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer guard out of the set to
      // silence an otherwise-failing liveness run is detected here.
      expect(epT14AddedGuards, isNotEmpty);
      for (final String path in epT14AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T14 guard dropped from canonical set: $path',
        );
      }
    });

    test('EP-T15: every post-EP-T14 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer behavioral guard out of the
      // set to silence an otherwise-failing liveness run is detected here.
      expect(epT15AddedGuards, isNotEmpty);
      for (final String path in epT15AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T15 guard dropped from canonical set: $path',
        );
      }
      // The two extension subsets must stay distinct — no guard may be counted
      // toward both EP-T14 and EP-T15 liveness coverage.
      expect(epT15AddedGuards.intersection(epT14AddedGuards), isEmpty);
    });

    test('EP-T16: every post-EP-T15 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer widget guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT16AddedGuards, isNotEmpty);
      for (final String path in epT16AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T16 guard dropped from canonical set: $path',
        );
      }
      // All three extension subsets must stay pairwise distinct — no guard may
      // be counted toward more than one of EP-T14 / EP-T15 / EP-T16 coverage.
      expect(epT16AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT16AddedGuards.intersection(epT15AddedGuards), isEmpty);
    });

    test('EP-T17: every post-EP-T16 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer safety guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT17AddedGuards, isNotEmpty);
      expect(epT17AddedGuards.length, 4);
      for (final String path in epT17AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T17 guard dropped from canonical set: $path',
        );
      }
      // All four extension subsets must stay pairwise distinct — no guard may
      // be counted toward more than one of EP-T14/EP-T15/EP-T16/EP-T17.
      expect(epT17AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT17AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT17AddedGuards.intersection(epT16AddedGuards), isEmpty);
    });

    test('EP-T18: every post-EP-T17 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer safety guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT18AddedGuards, isNotEmpty);
      expect(epT18AddedGuards.length, 3);
      for (final String path in epT18AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T18 guard dropped from canonical set: $path',
        );
      }
      // All five extension subsets must stay pairwise distinct — no guard may
      // be counted toward more than one of EP-T14/15/16/17/18.
      expect(epT18AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT18AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT18AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT18AddedGuards.intersection(epT17AddedGuards), isEmpty);
    });

    test('EP-T19: every post-EP-T18 guard is in the canonical liveness set',
        () {
      // Pins the extension itself: dropping a newer safety guard out of the set
      // to silence an otherwise-failing liveness run is detected here.
      expect(epT19AddedGuards, isNotEmpty);
      expect(epT19AddedGuards.length, 3);
      for (final String path in epT19AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T19 guard dropped from canonical set: $path',
        );
      }
      // All six extension subsets must stay pairwise distinct — no guard may be
      // counted toward more than one of EP-T14/15/16/17/18/19.
      expect(epT19AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT19AddedGuards.intersection(epT18AddedGuards), isEmpty);
    });

    test('EP-T20: every post-EP-T19 guard is in the canonical liveness set',
        () {
      expect(epT20AddedGuards, isNotEmpty);
      expect(epT20AddedGuards.length, 4);
      for (final String path in epT20AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T20 guard dropped from canonical set: $path',
        );
      }
      // All extension subsets + the initial set must stay pairwise
      // distinct — no guard may be counted toward more than one epoch.
      expect(epT20AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT20AddedGuards.intersection(epT19AddedGuards), isEmpty);
    });

    test('EP-U16: the cross-card notice guard is in the canonical liveness set',
        () {
      expect(epU16AddedGuards, isNotEmpty);
      expect(epU16AddedGuards.length, 1);
      for (final String path in epU16AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-U16 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epU16AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epU16AddedGuards.intersection(epT20AddedGuards), isEmpty);
    });

    test(
        'EP-M5: the hostile connect-types guard is in the canonical liveness set',
        () {
      expect(epM5AddedGuards, isNotEmpty);
      expect(epM5AddedGuards.length, 1);
      for (final String path in epM5AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-M5 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epM5AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epM5AddedGuards.intersection(epU16AddedGuards), isEmpty);
    });

    test(
        'EP-S2: the pickPrimary secure-tier guard is in the canonical liveness set',
        () {
      expect(epS2AddedGuards, isNotEmpty);
      expect(epS2AddedGuards.length, 1);
      for (final String path in epS2AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-S2 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epS2AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epS2AddedGuards.intersection(epM5AddedGuards), isEmpty);
    });

    test(
        'EP-T21: the RM-12 fromManager parity guard is in the canonical liveness set',
        () {
      expect(epT21AddedGuards, isNotEmpty);
      expect(epT21AddedGuards.length, 1);
      for (final String path in epT21AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T21 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT21AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT21AddedGuards.intersection(epS2AddedGuards), isEmpty);
    });

    test(
        'EP-T22: cross-cutting safety guards are in the canonical liveness set',
        () {
      expect(epT22AddedGuards, isNotEmpty);
      expect(epT22AddedGuards.length, 3);
      for (final String path in epT22AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T22 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT22AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT22AddedGuards.intersection(epT21AddedGuards), isEmpty);
    });

    test(
        'RM-14: the OEM block-precedence guard is in the canonical liveness set',
        () {
      expect(rm14AddedGuards, isNotEmpty);
      expect(rm14AddedGuards.length, 1);
      for (final String path in rm14AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'RM-14 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(rm14AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(rm14AddedGuards.intersection(epT22AddedGuards), isEmpty);
    });

    test(
        'RM-13: the enablement-regime boundary guard is in the canonical '
        'liveness set', () {
      expect(rm13AddedGuards, isNotEmpty);
      expect(rm13AddedGuards.length, 1);
      for (final String path in rm13AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'RM-13 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(rm13AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(rm13AddedGuards.intersection(rm14AddedGuards), isEmpty);
    });

    test(
        'EP-S9: the credential-primary boundary guard is in the canonical '
        'liveness set', () {
      expect(epS9AddedGuards, isNotEmpty);
      expect(epS9AddedGuards.length, 1);
      for (final String path in epS9AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-S9 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epS9AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epS9AddedGuards.intersection(rm13AddedGuards), isEmpty);
    });

    test(
        'EP-T23: the no-WebView affordance guard is in the canonical '
        'liveness set', () {
      expect(epT23AddedGuards, isNotEmpty);
      expect(epT23AddedGuards.length, 1);
      for (final String path in epT23AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T23 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT23AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT23AddedGuards.intersection(epS9AddedGuards), isEmpty);
    });

    test(
        'RM-15: the bidi/confusable manager-source guard is in the canonical '
        'liveness set', () {
      expect(rm15AddedGuards, isNotEmpty);
      expect(rm15AddedGuards.length, 1);
      for (final String path in rm15AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'RM-15 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(rm15AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(rm15AddedGuards.intersection(epT23AddedGuards), isEmpty);
    });

    test(
        'EP-P13: the authority-confusion guard is in the canonical '
        'liveness set', () {
      expect(epP13AddedGuards, isNotEmpty);
      expect(epP13AddedGuards.length, 1);
      for (final String path in epP13AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-P13 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epP13AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epP13AddedGuards.intersection(rm15AddedGuards), isEmpty);
    });

    test(
        'SEC-010: the cross-cutting security guards are in the canonical '
        'liveness set', () {
      expect(sec010AddedGuards, isNotEmpty);
      expect(sec010AddedGuards.length, 4);
      for (final String path in sec010AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'SEC-010 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(sec010AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(sec010AddedGuards.intersection(epP13AddedGuards), isEmpty);
    });

    test(
        'EP-T26: the newly-landed agreement guards are in the canonical '
        'liveness set', () {
      expect(epT26AddedGuards, isNotEmpty);
      expect(epT26AddedGuards.length, 3);
      for (final String path in epT26AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T26 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT26AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT26AddedGuards.intersection(sec010AddedGuards), isEmpty);
    });

    test(
        'EP-T28: the EP-U20 extreme-content guard is in the canonical '
        'liveness set', () {
      expect(epT28AddedGuards, isNotEmpty);
      expect(epT28AddedGuards.length, 1);
      for (final String path in epT28AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T28 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT28AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT28AddedGuards.intersection(epT26AddedGuards), isEmpty);
    });

    test(
        'EP-T29: the RM-17 key-collision guard is in the canonical '
        'liveness set', () {
      expect(epT29AddedGuards, isNotEmpty);
      expect(epT29AddedGuards.length, 1);
      for (final String path in epT29AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T29 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT29AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT29AddedGuards.intersection(epT28AddedGuards), isEmpty);
    });

    test(
        'EP-T30: the EP-M4 remote-console-disable parity guard is in the '
        'canonical liveness set', () {
      expect(epT30AddedGuards, isNotEmpty);
      expect(epT30AddedGuards.length, 1);
      for (final String path in epT30AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T30 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT30AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT30AddedGuards.intersection(epT29AddedGuards), isEmpty);
    });

    test(
        'EP-T32: the EP-P16 nonstandard-port authority guard is in the '
        'canonical liveness set', () {
      expect(epT32AddedGuards, isNotEmpty);
      expect(epT32AddedGuards.length, 1);
      for (final String path in epT32AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T32 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT32AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT32AddedGuards.intersection(epT30AddedGuards), isEmpty);
    });

    test(
        'EP-T33: the EP-U21 large-font cross-surface a11y guard is in the '
        'canonical liveness set', () {
      expect(epT33AddedGuards, isNotEmpty);
      expect(epT33AddedGuards.length, 1);
      for (final String path in epT33AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T33 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT33AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT33AddedGuards.intersection(epT32AddedGuards), isEmpty);
    });

    test(
        'EP-T35: the three newest agreement guards are in the canonical '
        'liveness set', () {
      expect(epT35AddedGuards, isNotEmpty);
      expect(epT35AddedGuards.length, 3);
      for (final String path in epT35AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T35 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT35AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT35AddedGuards.intersection(epT33AddedGuards), isEmpty);
    });

    test(
        'EP-T36: the four newest agreement guards are in the canonical '
        'liveness set', () {
      expect(epT36AddedGuards, isNotEmpty);
      expect(epT36AddedGuards.length, 4);
      for (final String path in epT36AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T36 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT36AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT36AddedGuards.intersection(epT35AddedGuards), isEmpty);
    });

    test(
        'EP-T37: the four newest agreement guards are in the canonical '
        'liveness set', () {
      expect(epT37AddedGuards, isNotEmpty);
      expect(epT37AddedGuards.length, 4);
      for (final String path in epT37AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T37 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT37AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT37AddedGuards.intersection(epT36AddedGuards), isEmpty);
    });

    test(
        'EP-T39: the five newest agreement guards are in the canonical '
        'liveness set', () {
      expect(epT39AddedGuards, isNotEmpty);
      expect(epT39AddedGuards.length, 5);
      for (final String path in epT39AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T39 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT39AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT39AddedGuards.intersection(epT37AddedGuards), isEmpty);
    });

    test(
        'EP-T40: the three newest agreement guards are in the canonical '
        'liveness set', () {
      expect(epT40AddedGuards, isNotEmpty);
      expect(epT40AddedGuards.length, 3);
      for (final String path in epT40AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T40 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT40AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT40AddedGuards.intersection(epT39AddedGuards), isEmpty);
    });

    test(
        'EP-T41: the four newer agreement guards are in the canonical '
        'liveness set', () {
      expect(epT41AddedGuards, isNotEmpty);
      expect(epT41AddedGuards.length, 4);
      for (final String path in epT41AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T41 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT41AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT41AddedGuards.intersection(epT40AddedGuards), isEmpty);
    });

    test(
        'EP-T42: the post-EP-T41 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT42AddedGuards, isNotEmpty);
      expect(epT42AddedGuards.length, 1);
      for (final String path in epT42AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T42 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT42AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT42AddedGuards.intersection(epT41AddedGuards), isEmpty);
    });

    test(
        'EP-T43: the post-EP-T42 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT43AddedGuards, isNotEmpty);
      expect(epT43AddedGuards.length, 1);
      for (final String path in epT43AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T43 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT43AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT43AddedGuards.intersection(epT42AddedGuards), isEmpty);
    });

    test(
        'EP-T44: the post-EP-T43 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT44AddedGuards, isNotEmpty);
      expect(epT44AddedGuards.length, 1);
      for (final String path in epT44AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T44 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT44AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT44AddedGuards.intersection(epT43AddedGuards), isEmpty);
    });

    test(
        'EP-T45: the post-EP-T44 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT45AddedGuards, isNotEmpty);
      expect(epT45AddedGuards.length, 1);
      for (final String path in epT45AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T45 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT45AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT45AddedGuards.intersection(epT44AddedGuards), isEmpty);
    });

    test(
        'EP-T46: the post-EP-T45 agreement guards are in the canonical '
        'liveness set', () {
      expect(epT46AddedGuards, isNotEmpty);
      expect(epT46AddedGuards.length, 2);
      for (final String path in epT46AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T46 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT46AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT46AddedGuards.intersection(epT45AddedGuards), isEmpty);
    });

    test(
        'EP-T47: the post-EP-T46 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT47AddedGuards, isNotEmpty);
      expect(epT47AddedGuards.length, 1);
      for (final String path in epT47AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T47 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT47AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT47AddedGuards.intersection(epT46AddedGuards), isEmpty);
    });

    test(
        'EP-T48: the post-EP-T47 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT48AddedGuards, isNotEmpty);
      expect(epT48AddedGuards.length, 1);
      for (final String path in epT48AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T48 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT48AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT48AddedGuards.intersection(epT47AddedGuards), isEmpty);
    });

    test(
        'EP-T49: the post-EP-T48 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT49AddedGuards, isNotEmpty);
      expect(epT49AddedGuards.length, 1);
      for (final String path in epT49AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T49 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT49AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT49AddedGuards.intersection(epT48AddedGuards), isEmpty);
    });

    test(
        'EP-T50: the post-EP-T49 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT50AddedGuards, isNotEmpty);
      expect(epT50AddedGuards.length, 1);
      for (final String path in epT50AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T50 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT50AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT50AddedGuards.intersection(epT49AddedGuards), isEmpty);
    });

    test(
        'EP-T51: the post-EP-T50 agreement guard is in the canonical '
        'liveness set', () {
      expect(epT51AddedGuards, isNotEmpty);
      expect(epT51AddedGuards.length, 1);
      for (final String path in epT51AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T51 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT51AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT51AddedGuards.intersection(epT50AddedGuards), isEmpty);
    });

    test(
        'EP-T52: the compound-extreme a11y agreement guard is in the canonical '
        'liveness set', () {
      expect(epT52AddedGuards, isNotEmpty);
      expect(epT52AddedGuards.length, 1);
      for (final String path in epT52AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T52 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT52AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT52AddedGuards.intersection(epT51AddedGuards), isEmpty);
    });

    test(
        'EP-T53: the compound bidi-name a11y agreement guard is in the canonical '
        'liveness set', () {
      expect(epT53AddedGuards, isNotEmpty);
      expect(epT53AddedGuards.length, 1);
      for (final String path in epT53AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T53 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT53AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT53AddedGuards.intersection(epT52AddedGuards), isEmpty);
    });

    test(
        'EP-T54: the compound C0/separator-name a11y agreement guard is in the '
        'canonical liveness set', () {
      expect(epT54AddedGuards, isNotEmpty);
      expect(epT54AddedGuards.length, 1);
      for (final String path in epT54AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T54 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT54AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT54AddedGuards.intersection(epT53AddedGuards), isEmpty);
    });

    test(
        'EP-T55: the compound long-unbreakable-name a11y agreement guard is in '
        'the canonical liveness set', () {
      expect(epT55AddedGuards, isNotEmpty);
      expect(epT55AddedGuards.length, 1);
      for (final String path in epT55AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T55 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT55AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT55AddedGuards.intersection(epT54AddedGuards), isEmpty);
    });

    test(
        'EP-T56: the compound control/bidi connect-type a11y agreement guard '
        'is in the canonical liveness set', () {
      expect(epT56AddedGuards, isNotEmpty);
      expect(epT56AddedGuards.length, 1);
      for (final String path in epT56AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T56 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT56AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT56AddedGuards.intersection(epT55AddedGuards), isEmpty);
    });
    test(
        'EP-T57: the compound RTL x 2.0x shared-notice a11y agreement guard '
        'is in the canonical liveness set', () {
      expect(epT57AddedGuards, isNotEmpty);
      expect(epT57AddedGuards.length, 1);
      for (final String path in epT57AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T57 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT57AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT57AddedGuards.intersection(epT55AddedGuards), isEmpty);
    });

    test(
        'EP-T58: the compound RTL x 2.0x raw-URI display a11y agreement guard '
        'is in the canonical liveness set', () {
      expect(epT58AddedGuards, isNotEmpty);
      expect(epT58AddedGuards.length, 1);
      for (final String path in epT58AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T58 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT58AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT58AddedGuards.intersection(epT57AddedGuards), isEmpty);
    });

    test(
        'EP-T59: the compound RTL x 2.0x session-limit row a11y agreement guard '
        'is in the canonical liveness set', () {
      expect(epT59AddedGuards, isNotEmpty);
      expect(epT59AddedGuards.length, 1);
      for (final String path in epT59AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T59 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT59AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT59AddedGuards.intersection(epT58AddedGuards), isEmpty);
    });

    test(
        'EP-T60: the compound RTL x 2.0x Primary-badge single-merged a11y '
        'agreement guard is in the canonical liveness set', () {
      expect(epT60AddedGuards, isNotEmpty);
      expect(epT60AddedGuards.length, 1);
      for (final String path in epT60AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T60 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT60AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT60AddedGuards.intersection(epT59AddedGuards), isEmpty);
    });

    test(
        'EP-T61: the control-at-URI-structural-boundary cross-layer '
        'fail-closed agreement guard is in the canonical liveness set', () {
      expect(epT61AddedGuards, isNotEmpty);
      expect(epT61AddedGuards.length, 1);
      for (final String path in epT61AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T61 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT61AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT61AddedGuards.intersection(epT60AddedGuards), isEmpty);
    });

    test(
        'EP-T62: the non-populated-state RTL x 2.0x a11y agreement guard is in '
        'the canonical liveness set', () {
      expect(epT62AddedGuards, isNotEmpty);
      expect(epT62AddedGuards.length, 1);
      for (final String path in epT62AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T62 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT62AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT62AddedGuards.intersection(epT61AddedGuards), isEmpty);
    });

    test(
        'EP-T63: the IPv6 zone-id / malformed-authority cross-layer agreement '
        'guard is in the canonical liveness set', () {
      expect(epT63AddedGuards, isNotEmpty);
      expect(epT63AddedGuards.length, 1);
      for (final String path in epT63AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T63 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT63AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT63AddedGuards.intersection(epT62AddedGuards), isEmpty);
    });

    test(
        'EP-T64: the relative / opaque ConnectUri cross-factory agreement '
        'guard is in the canonical liveness set', () {
      expect(epT64AddedGuards, isNotEmpty);
      expect(epT64AddedGuards.length, 1);
      for (final String path in epT64AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T64 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT64AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT62AddedGuards), isEmpty);
      expect(epT64AddedGuards.intersection(epT63AddedGuards), isEmpty);
    });

    test(
        'EP-T65: the console-side userinfo ↔ navigation-target asymmetry '
        'agreement guard is in the canonical liveness set', () {
      expect(epT65AddedGuards, isNotEmpty);
      expect(epT65AddedGuards.length, 1);
      for (final String path in epT65AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T65 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT65AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT62AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT63AddedGuards), isEmpty);
      expect(epT65AddedGuards.intersection(epT64AddedGuards), isEmpty);
    });

    test(
        'EP-T66: the @odata.nextLink collection-page cross-surface agreement '
        'guard is in the canonical liveness set', () {
      expect(epT66AddedGuards, isNotEmpty);
      expect(epT66AddedGuards.length, 1);
      for (final String path in epT66AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T66 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT66AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT62AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT63AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT64AddedGuards), isEmpty);
      expect(epT66AddedGuards.intersection(epT65AddedGuards), isEmpty);
    });

    test(
        'EP-T67: two pre-existing regression guards are in the canonical '
        'liveness set (EP-S11 tie determinism + EP-U4 session-limit wiring)',
        () {
      expect(epT67AddedGuards, isNotEmpty);
      expect(epT67AddedGuards.length, 2);
      for (final String path in epT67AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T67 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT67AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT62AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT63AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT64AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT65AddedGuards), isEmpty);
      expect(epT67AddedGuards.intersection(epT66AddedGuards), isEmpty);
    });

    test(
        'EP-T68: the EP-U41 copy-affordance a11y guard is in the canonical '
        'liveness set', () {
      expect(epT68AddedGuards, isNotEmpty);
      expect(epT68AddedGuards.length, 1);
      for (final String path in epT68AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T68 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT68AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT62AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT63AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT64AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT65AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT66AddedGuards), isEmpty);
      expect(epT68AddedGuards.intersection(epT67AddedGuards), isEmpty);
    });

    test(
        'EP-T69: the EP-U42 manager-source-row a11y guard is in the canonical '
        'liveness set', () {
      expect(epT69AddedGuards, isNotEmpty);
      expect(epT69AddedGuards.length, 1);
      for (final String path in epT69AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T69 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT69AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT62AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT63AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT64AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT65AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT66AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT67AddedGuards), isEmpty);
      expect(epT69AddedGuards.intersection(epT68AddedGuards), isEmpty);
    });

    test(
        'EP-T70: the EP-U27 dense connect-type chip-set a11y guard is in '
        'the canonical liveness set', () {
      expect(epT70AddedGuards, isNotEmpty);
      expect(epT70AddedGuards.length, 1);
      for (final String path in epT70AddedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'EP-T70 guard dropped from canonical set: $path',
        );
      }
      // The new epoch set stays disjoint from every earlier designation so a
      // single guard cannot satisfy the completeness invariant twice.
      expect(epT70AddedGuards.intersection(epT12InitialGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT14AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT15AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT16AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT17AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT18AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT19AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT20AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epU16AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epM5AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epS2AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT21AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT22AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(rm14AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(rm13AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epS9AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT23AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(rm15AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epP13AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(sec010AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT26AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT28AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT29AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT30AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT32AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT33AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT35AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT36AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT37AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT39AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT40AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT41AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT42AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT43AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT44AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT45AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT46AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT47AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT48AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT49AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT50AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT51AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT52AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT53AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT54AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT55AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT56AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT57AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT58AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT59AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT60AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT61AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT62AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT63AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT64AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT65AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT66AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT67AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT68AddedGuards), isEmpty);
      expect(epT70AddedGuards.intersection(epT69AddedGuards), isEmpty);
    });

    test('EP-T20: canonical registry is exactly the union of designated guards',
        () {
      // (a) Every designated guard must remain in the canonical set — a guard
      // dropped from canonicalGuardFiles fails closed here.
      for (final String path in allDesignatedGuards) {
        expect(
          canonicalGuardFiles,
          contains(path),
          reason: 'designated guard dropped from canonical set: $path',
        );
      }
      // (b) Every canonical entry must be epoch-designated — a guard added
      // directly to canonicalGuardFiles with no pinned set fails closed here.
      for (final String path in canonicalGuardFiles) {
        expect(
          allDesignatedGuards,
          contains(path),
          reason: 'unpinned guard added to canonical set: $path',
        );
      }
      expect(allDesignatedGuards.length, canonicalGuardFiles.length);
      // The epoch sets themselves must stay pairwise disjoint so a single
      // guard cannot satisfy the completeness invariant twice.
      expect(epT12InitialGuards.length, 8);
      expect(
        allDesignatedGuards.length,
        epT12InitialGuards.length +
            epT14AddedGuards.length +
            epT15AddedGuards.length +
            epT16AddedGuards.length +
            epT17AddedGuards.length +
            epT18AddedGuards.length +
            epT19AddedGuards.length +
            epT20AddedGuards.length +
            epU16AddedGuards.length +
            epM5AddedGuards.length +
            epS2AddedGuards.length +
            epT21AddedGuards.length +
            epT22AddedGuards.length +
            rm14AddedGuards.length +
            rm13AddedGuards.length +
            epS9AddedGuards.length +
            epT23AddedGuards.length +
            rm15AddedGuards.length +
            epP13AddedGuards.length +
            sec010AddedGuards.length +
            epT26AddedGuards.length +
            epT28AddedGuards.length +
            epT29AddedGuards.length +
            epT30AddedGuards.length +
            epT32AddedGuards.length +
            epT33AddedGuards.length +
            epT35AddedGuards.length +
            epT36AddedGuards.length +
            epT37AddedGuards.length +
            epT39AddedGuards.length +
            epT40AddedGuards.length +
            epT41AddedGuards.length +
            epT42AddedGuards.length +
            epT43AddedGuards.length +
            epT44AddedGuards.length +
            epT45AddedGuards.length +
            epT46AddedGuards.length +
            epT47AddedGuards.length +
            epT48AddedGuards.length +
            epT49AddedGuards.length +
            epT50AddedGuards.length +
            epT51AddedGuards.length +
            epT52AddedGuards.length +
            epT53AddedGuards.length +
            epT54AddedGuards.length +
            epT55AddedGuards.length +
            epT56AddedGuards.length +
            epT57AddedGuards.length +
            epT58AddedGuards.length +
            epT59AddedGuards.length +
            epT60AddedGuards.length +
            epT61AddedGuards.length +
            epT62AddedGuards.length +
            epT63AddedGuards.length +
            epT64AddedGuards.length +
            epT65AddedGuards.length +
            epT66AddedGuards.length +
            epT67AddedGuards.length +
            epT68AddedGuards.length +
            epT69AddedGuards.length +
            epT70AddedGuards.length,
      );
    });
  });

  group('EP-T12 RED→GREEN guard proof (temporary scan root)', () {
    test('missing / emptied / test-less / unreachable all fail closed', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t12_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync('  run: flutter test --coverage\n');

        // GREEN: everything intact.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: a guard file is deleted.
        File(p(canonicalGuardFiles[0])).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('MISSING:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[0])).writeAsStringSync(syntheticGuardSource);

        // RED 2: a guard file is emptied.
        File(p(canonicalGuardFiles[1])).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('EMPTY:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[1])).writeAsStringSync(syntheticGuardSource);

        // RED 3: a guard keeps prose but loses every test case.
        File(p(canonicalGuardFiles[2])).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('NO_TEST_CASES:')),
          isTrue,
        );
        File(p(canonicalGuardFiles[2])).writeAsStringSync(syntheticGuardSource);

        // RED 4: CI no longer runs the whole-tree coverage suite.
        verify.writeAsStringSync('  run: echo nothing-to-see\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v.startsWith('UNREACHABLE:')),
          isTrue,
        );

        // GREEN again once the CI invocation is restored.
        verify.writeAsStringSync('  run: flutter test --coverage\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T14: a newly-added guard is liveness-checked (missing/emptied)',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t14_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T14 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12 initial set.
      final String addedGuard = epT14AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the newly-added guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );

        // GREEN again once the guard is restored.
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T15: newly-added behavioral guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t15_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T15 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/EP-T14 sets.
      final String addedGuard = epT15AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added behavioral guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T16: newly-added widget guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t16_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T16 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15 sets.
      final String addedGuard = epT16AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added widget guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T17: newly-added post-EP-T16 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t17_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T17 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16 sets.
      final String addedGuard = epT17AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T18: newly-added post-EP-T17 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t18_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T18 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16/17 sets.
      final String addedGuard = epT18AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T19: newly-added post-EP-T18 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t19_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T19 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16/17/18 sets.
      final String addedGuard = epT19AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T20: newly-added post-EP-T19 guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t20_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick a path from the EP-T20 extension specifically, so this proves the
      // NEW entries are evaluated and not just the EP-T12/14/15/16/17/18/19 sets.
      final String addedGuard = epT20AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added safety guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T21: newly-added RM-12 parity guard is liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t21_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      // Pick the EP-T21 entry specifically, so this proves the NEW guard is
      // evaluated and not just the earlier canonical entries.
      final String addedGuard = epT21AddedGuards.first;
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: keeps prose but loses every test case → NO_TEST_CASES.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T22: newly-added cross-cutting guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t22_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each of the three newly-registered guards must individually fail
        // closed when deleted, emptied or stripped of its test cases.
        for (final String addedGuard in epT22AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('RM-14: newly-added OEM block-precedence guard is liveness-checked',
        () {
      final Directory temp = Directory.systemTemp.createTempSync('rm14_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        final String addedGuard = rm14AddedGuards.single;
        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when deleted',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the guard is emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when emptied',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: the guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when test-stripped',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('RM-13: newly-added enablement-boundary guard is liveness-checked',
        () {
      final Directory temp = Directory.systemTemp.createTempSync('rm13_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        final String addedGuard = rm13AddedGuards.single;
        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when deleted',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the guard is emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when emptied',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: the guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when test-stripped',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-S9: newly-added credential-boundary guard is liveness-checked',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_s9_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        final String addedGuard = epS9AddedGuards.single;
        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when deleted',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the guard is emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when emptied',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: the guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when test-stripped',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T23: newly-added affordance guard is liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t23_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        final String addedGuard = epT23AddedGuards.single;
        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when deleted',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the guard is emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when emptied',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: the guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when test-stripped',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('RM-15: newly-added bidi/confusable guard is liveness-checked', () {
      final Directory temp = Directory.systemTemp.createTempSync('rm15_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        final String addedGuard = rm15AddedGuards.single;
        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when deleted',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the guard is emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when emptied',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: the guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when test-stripped',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-P13: newly-added authority-confusion guard is liveness-checked',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_p13_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        final String addedGuard = epP13AddedGuards.single;
        // RED 1: the newly-added guard is deleted → MISSING.
        File(p(addedGuard)).deleteSync();
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'MISSING: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when deleted',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 2: the guard is emptied → EMPTY.
        File(p(addedGuard)).writeAsStringSync('  \n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'EMPTY: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when emptied',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // RED 3: the guard keeps prose but loses every test case.
        File(p(addedGuard)).writeAsStringSync('void main() {}\n');
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
              .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
          isTrue,
          reason: '$addedGuard not liveness-checked when test-stripped',
        );
        File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

        // GREEN again once the guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
    test('SEC-010: newly-registered security guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('sec010_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each of the four newly-registered security guards must individually
        // fail closed when deleted, emptied or stripped of its test cases —
        // including `tls_downgrade_test.dart`, which guards production TLS.
        for (final String addedGuard in sec010AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T26: newly-registered agreement guards are liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t26_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each of the three newly-registered agreement guards must individually
        // fail closed when deleted, emptied or stripped of its test cases.
        for (final String addedGuard in epT26AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T28: newly-registered extreme-content guard is liveness-checked',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_u20_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered extreme-content agreement guard must fail closed
        // when deleted, emptied or stripped of its test cases.
        for (final String addedGuard in epT28AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T29: newly-registered key-collision guard is liveness-checked',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('rm17_key_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered RM-17 key-collision agreement guard must fail
        // closed when deleted, emptied or stripped of its test cases.
        for (final String addedGuard in epT29AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('EP-T30: newly-registered EP-M4 parity guard is liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_m4_parity_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered EP-M4 RemoteConsole-disable parity guard must
        // fail closed when deleted, emptied or stripped of its test cases.
        for (final String addedGuard in epT30AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T32: newly-registered EP-P16 port-authority guard is liveness-checked',
        () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_p16_port_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered EP-P16 nonstandard-port authority agreement
        // guard must fail closed when deleted, emptied or stripped of tests.
        for (final String addedGuard in epT32AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T33: newly-registered EP-U21 large-font a11y guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_u21_large_font_guard_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered EP-U21 large-font cross-surface a11y guard
        // must fail closed when deleted, emptied or stripped of tests.
        for (final String addedGuard in epT33AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T35: newly-registered newest agreement guards are '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t35_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-M7 body-path, EP-S12 malformed-members,
        // EP-P17 encoded-userinfo).
        for (final String addedGuard in epT35AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T36: newly-registered newest agreement guards are '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t36_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U23 full-name announcement, EP-S10
        // all-unsafe primary, EP-S16 Unicode-id distinctness, EP-P18
        // canonical-tricky authority).
        for (final String addedGuard in epT36AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T37: newly-registered newest agreement guards are '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t37_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-P19 query/fragment control fail-closed,
        // RM-21 body-id query/fragment/userinfo, EP-S17 malformed-body /
        // transport, EP-U24 unbreakable chip no-overflow).
        for (final String addedGuard in epT37AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T39: newly-registered newest agreement guards are '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t39_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-P20 backslash / mixed separator, RM-22
        // confusable connect-type, EP-S18 same-tier Primary, EP-U25 Primary
        // badge single merged a11y, EP-U22 bidi display text).
        for (final String addedGuard in epT39AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T40: newly-registered newest agreement guards are '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t40_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U18 copy-only vs browser-open route, RM-23
        // hostile ConnectUri raw-preservation, EP-P21 IPv6-literal / zone-id
        // authority cross-layer agreement).
        for (final String addedGuard in epT40AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T41: newly-registered newer agreement guards are '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t41_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (RM-18 derived-fallback manager-id control-safety,
        // RM-20 registered-OEM hostile-enrichment normalization, EP-S13
        // cross-surface manager-skip, EP-S14 zero-usable-console surfacing).
        for (final String addedGuard in epT41AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T42: newly-registered post-EP-T41 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t42_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U26-residual console-card "Copied:"
        // SnackBar fail-closed cross-surface agreement).
        for (final String addedGuard in epT42AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T43: newly-registered post-EP-T42 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t43_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (RM-24 non-boolean enablement-scalar coercion
        // agreement across both `fromManager` factories + the shared OEM
        // enablement helper).
        for (final String addedGuard in epT43AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T44: newly-registered post-EP-T43 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t44_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-S20 top-level `/Managers` document-shape
        // cross-surface agreement across `fetchConsoles()` /
        // `fetchCapabilities()` / `fetchCapability(id)`).
        for (final String addedGuard in epT44AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T45: newly-registered post-EP-T44 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t45_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-P22 degenerate userinfo-edge authority
        // fail-closed cross-layer agreement — empty credential pairs and
        // uppercase-hex escapes across classifier / launch plan / navigation
        // gate / model).
        for (final String addedGuard in epT45AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T46: newly-registered post-EP-T45 agreement guards are '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t46_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // Each newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (RM-25 non-integer session-limit scalar coercion
        // cross-factory agreement + EP-P23 degenerate hierarchical-URI form
        // fail-closed cross-layer agreement).
        for (final String addedGuard in epT46AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T47: newly-registered post-EP-T46 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t47_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U28 RTL-locale rendering agreement across
        // both operator cards and the viewer).
        for (final String addedGuard in epT47AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T48: newly-registered post-EP-T47 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t48_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-S21 hostile OEM console-shape cross-surface
        // agreement across both real `/Managers` walk surfaces).
        for (final String addedGuard in epT48AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T49: newly-registered post-EP-T48 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t49_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (RM-26 hostile `ConnectTypesSupported`
        // container-shape cross-factory agreement — non-list containers fail
        // closed identically on both `fromManager` normalizers).
        for (final String addedGuard in epT49AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T50: newly-registered post-EP-T49 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t50_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U29 degenerate-empty connect-type / blank
        // label render agreement — blank / whitespace / malformed
        // `ConnectTypesSupported` tokens collapse to an empty chip set
        // identically on both cards + the viewer at 320/800/1300 px).
        for (final String addedGuard in epT50AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
        'EP-T51: newly-registered post-EP-T50 agreement guard is '
        'liveness-checked', () {
      final Directory temp =
          Directory.systemTemp.createTempSync('ep_t51_guards_');
      String p(String rel) => '${temp.path}${Platform.pathSeparator}'
          '${rel.replaceAll('/', Platform.pathSeparator)}';
      final String verifyLine = '  run: flutter test --coverage\n';
      try {
        // Populate every canonical guard with a live synthetic case.
        for (final String path in canonicalGuardFiles) {
          final File file = File(p(path));
          file.parent.createSync(recursive: true);
          file.writeAsStringSync(syntheticGuardSource);
        }
        final File verify = File(p('.github/workflows/verify.yml'));
        verify.parent.createSync(recursive: true);
        verify.writeAsStringSync(verifyLine);

        // GREEN: all guards present + live.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U30 C0-control / Unicode line/paragraph-
        // separator display-text a11y agreement — CR/LF/TAB/NUL/DEL/ESC +
        // U+2028/U+2029/U+00A0 in the manager DISPLAY NAME byte-exact on both
        // cards + the viewer at 320/800/1300 px, no split / duplicate /
        // screen-reader-only node, no overflow).
        for (final String addedGuard in epT51AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U31 compound-extreme a11y agreement — a
        // 400-char unbreakable connect-type token under RTL AND 2.0x text scale
        // on both operator cards at 320/800/1300 px, one merged visible==
        // announced chip node per card, no overflow).
        for (final String addedGuard in epT52AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U32 compound bidi-display-name x RTL x 2.0x
        // a11y agreement — a bidi/RTL-control-bearing manager DISPLAY NAME under
        // RTL AND a 2.0x text scaler on both operator cards + the viewer at
        // 320/800/1300 px, full byte-exact name announced + visible in one
        // merged node per surface, no duplicate, no overflow).
        for (final String addedGuard in epT53AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U33 compound C0/separator display-name x
        // RTL x 2.0x a11y agreement — a Cc/Zl/Zp/Zs-bearing manager DISPLAY
        // NAME under RTL AND a 2.0x text scaler on both operator cards + the
        // viewer at 320/800/1300 px, full byte-exact name announced + visible
        // in one merged node per surface, no duplicate, no overflow).
        for (final String addedGuard in epT54AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U34 compound long-unbreakable-display-name x
        // RTL x 2.0x a11y agreement — a 180-char unbreakable manager DISPLAY
        // NAME under RTL AND a 2.0x text scaler on both operator cards + the
        // viewer at 320/800/1300 px, full byte-exact name announced + visible
        // in one merged node per surface, no duplicate, no overflow).
        for (final String addedGuard in epT55AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U35 compound control/bidi-bearing
        // connect-type a11y agreement — bidi Cf / C0 Cc / Zl-bearing
        // CONNECT-TYPE tokens under RTL AND a 2.0x text scaler on both operator
        // cards at 320/800/1300 px, full byte-exact chip sequence + one merged
        // announced connection-types node per card, no duplicate, no overflow).
        for (final String addedGuard in epT56AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }
        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U36 compound RTL x 2.0x shared-notice a11y
        // agreement — the two shared notices on both operator cards + the
        // viewer at 320/800/1300 px, full byte-exact copy in one merged node
        // per surface, no duplicate, no overflow).
        for (final String addedGuard in epT57AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }
        // The newly-registered guard must fail closed when deleted, emptied
        // or stripped of tests (EP-U37 compound RTL x 2.0x raw-URI display a11y
        // agreement — a control/bidi-bearing raw URI byte-exact in one merged
        // node per operator card at 320/800/1300 px, viewer fail-closed, no
        // duplicate, no overflow).
        for (final String addedGuard in epT58AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // or stripped of tests (EP-U38 compound RTL x 2.0x session-limit row
        // a11y agreement — the two cards' byte-exact session NUMBER in one
        // merged visible==announced node each at 320/800/1300 px under RTL
        // AND a 2.0x scaler, boundary encodings, LTR/1.0x control).
        for (final String addedGuard in epT59AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // or stripped of tests (EP-U39 compound RTL x 2.0x "Primary" badge
        // single-merged a11y agreement — exactly one visible marker on the
        // pickPrimary winner inside one merged header node, no
        // split/screen-reader-only announcement, no peer/capability/viewer
        // duplicate, no overflow at 320/800/1300 px under RTL AND a 2.0x
        // scaler, LTR/1.0x control).
        for (final String addedGuard in epT60AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // or stripped of tests (EP-P25 control-at-URI-structural-boundary
        // cross-layer fail-closed agreement — a 12-case hostile matrix wedging
        // raw C0/C1/DEL controls at every URI structural boundary plus 3 clean
        // spellings, pinned field-for-field across classifier / launch plan /
        // navigation gate / model, with the same-origin userinfo-NUL case
        // pinning the `Uri.tryParse` origin differential).
        for (final String addedGuard in epT61AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // EP-T62: non-populated-state RTL x 2.0x a11y agreement guard (EP-U40
        // — the five non-populated KvmView states, each pinned to one merged
        // `excludeSemantics` node with visible==announced and no duplicate /
        // overflow at 320/800/1300 px under RTL + 2.0x, LTR/1.0x + populated
        // controls).
        for (final String addedGuard in epT62AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // EP-T63: IPv6 zone-id / malformed-authority cross-layer fail-closed
        // agreement guard (EP-P27 — a scoped zone id, a control / bidi /
        // separator-bearing zone, a malformed bracket / percent spelling and
        // IPv4-mapped forms pinned field-for-field across the classifier / plan /
        // navigation gate / model, with clean IPv6 / IPv4 controls).
        for (final String addedGuard in epT63AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // EP-T64: relative / opaque console ConnectUri cross-factory
        // fail-closed agreement guard (RM-29 — relative paths, scheme-relative
        // / opaque / query-only forms, control-bearing relatives and a clean
        // HTTPS control pinned across both factories, classifiers, launch plan,
        // copyable target and never-throw on non-string).
        for (final String addedGuard in epT64AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // EP-T65: console-side userinfo ↔ navigation-target asymmetry guard
        // (EP-P28 — a credentialed console is a legal initial secure-HTTPS load
        // whose userinfo must not be rejected as an in-session navigation
        // source, so a credential-free same-origin target stays navigable while
        // a credentialed target still fails closed; pinned across path / query
        // variants, default-port normalization, origin confinement, non-HTTPS
        // fail-closed and the launch-plan initial-load exception).
        for (final String addedGuard in epT65AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // EP-T66: @odata.nextLink collection-page cross-surface agreement
        // guard (EP-S23 — both discovery surfaces adopt the same single page
        // set with no ghost lookup / double-count over the full nextLink root
        // value family).
        for (final String addedGuard in epT66AddedGuards) {
          File(p(addedGuard)).deleteSync();
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'MISSING: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when deleted',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('  \n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'EMPTY: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when emptied',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);

          File(p(addedGuard)).writeAsStringSync('void main() {}\n');
          expect(
            evaluateGuardSuite(readSuite(temp), verify.readAsStringSync())
                .any((String v) => v == 'NO_TEST_CASES: $addedGuard'),
            isTrue,
            reason: '$addedGuard not liveness-checked when test-stripped',
          );
          File(p(addedGuard)).writeAsStringSync(syntheticGuardSource);
        }

        // GREEN again once every guard is restored.
        expect(
          evaluateGuardSuite(readSuite(temp), verify.readAsStringSync()),
          isEmpty,
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('EP-T12 real repository invariant', () {
    test('every established KVM safety guard is present, live and reachable',
        () {
      final File verify = File('.github/workflows/verify.yml');
      expect(verify.existsSync(), isTrue);
      final List<String> violations = evaluateGuardSuite(
          readSuite(Directory('.')), verify.readAsStringSync());
      expect(
        violations,
        isEmpty,
        reason: 'guard-suite drift: ${violations.join(", ")}',
      );
    });
  });
}
