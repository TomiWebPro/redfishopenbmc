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
            epT26AddedGuards.length,
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
