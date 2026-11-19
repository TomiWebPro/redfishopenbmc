/// Shared, bounded OEM-console resolution for the two KVM views (issue
/// #009).
///
/// A Redfish manager may expose its console only under `Oem` (for example
/// `Oem.OpenBMC.KVM.Uri`). Both [KvmConsole.fromManager] (the per-console card)
/// and `KvmCapability.resolveLaunchUri` (the per-manager capability card) must
/// surface that same endpoint for the same manager, otherwise the two views
/// disagree about where the operator should open the console. Keeping the
/// search in one pure, widget-free helper guarantees they never drift.
///
/// The same block is also inspected for enablement so a BMC that reports an
/// OEM console as explicitly disabled is not advertised as launchable — the
/// OEM path is the one console source that previously ignored enablement
/// (issue #009).
///
/// Resolution is read-only: it returns a trimmed URI string / enablement flag
/// to the caller and never opens a connection, spawns IPC, or changes transport
/// security.
library;

/// Returns the OEM console-like block in [node] that carries a usable `Uri`,
/// or `null`.
///
/// Search order (bounded to [maxDepth] levels): first a direct console-like key
/// (`kvm` / `console` / `webconsole`, case-insensitive) whose map carries a
/// usable `Uri` or canonical Redfish `ConnectUri` member, then a recursive walk
/// of nested vendor blocks. A blank or non-string member is ignored, so it
/// cannot shadow a later valid fallback.
///
/// Returning the whole block (not just the URI) lets both callers inspect the
/// *same* console node for its enablement flags, so the URI and the enabled
/// state can never come from two different blocks.
Map<dynamic, dynamic>? kvmOemConsoleBlock(dynamic node, {int maxDepth = 3}) =>
    _findBlock(node, 0, maxDepth);

Map<dynamic, dynamic>? _findBlock(dynamic node, int depth, int maxDepth) {
  if (depth > maxDepth || node is! Map<dynamic, dynamic>) return null;

  // Prefer a direct console-like key whose map carries a `Uri` member.
  for (final dynamic entry in node.entries) {
    final String key = entry.key.toString().toLowerCase();
    if ((key.contains('kvm') ||
            key.contains('console') ||
            key.contains('webconsole')) &&
        entry.value is Map<dynamic, dynamic>) {
      final Map<dynamic, dynamic> block = entry.value as Map<dynamic, dynamic>;
      if (_uriFromMap(block) != null) return block;
    }
  }
  // Otherwise search nested vendor blocks.
  for (final dynamic value in node.values) {
    final Map<dynamic, dynamic>? block = _findBlock(value, depth + 1, maxDepth);
    if (block != null) return block;
  }
  return null;
}

/// Returns a usable, trimmed OEM console endpoint found in [node], or `null`.
///
/// Recognizes both the short `Uri` and the canonical Redfish `ConnectUri`
/// member (preferring `Uri` when both are present), so an unregistered vendor
/// that publishes the schema-correct `ConnectUri` resolves identically on both
/// KVM views. Delegates to [kvmOemConsoleBlock] so the URI always comes from
/// the exact console block the enablement check inspects (issue #009).
String? kvmOemConsoleUri(dynamic node, {int maxDepth = 3}) {
  final Map<dynamic, dynamic>? block =
      kvmOemConsoleBlock(node, maxDepth: maxDepth);
  return block == null ? null : _uriFromMap(block);
}

/// True when the OEM console block in [node] is enabled on the BMC.
///
/// Mirrors the standard console rule: a truthy `ServiceEnabled` or legacy
/// `Enabled` member means enabled. A block that omits both members is
/// "unknown" (the common mockup case) and stays enabled, preserving all
/// existing OEM payloads that carry only a `Uri`. Only an *explicit* disable
/// (an enablement member present but none truthy) reports the console as
/// disabled — so a BMC publishing `ServiceEnabled: false` can no longer be
/// advertised as a launchable KVM (issue #009). A truthy enablement member
/// wins over a false one, exactly as for the standard console blocks.
///
/// Read-only: inspects JSON members only, never opens a connection and never
/// changes transport security.
bool kvmOemConsoleEnabled(dynamic node, {int maxDepth = 3}) {
  // The URI-bearing block stays authoritative so the URI and its enablement
  // always come from the same console node (the invariant above). But a BMC
  // may publish a console-like block that explicitly disables itself without
  // a usable `Uri` (e.g. an OEM KVM placeholder with `ServiceEnabled: false`).
  // kvmOemConsoleBlock cannot see that block because it filters on `Uri`, so
  // without this fallback the disable flag was silently ignored and a
  // BMC-disabled OEM console was wrongly reported supported + enabled on both
  // KVM views — breaking the #009 "KVM disabled on BMC" contract that every
  // standard console block honors. When no URI-bearing console exists there
  // is no URI to disagree with, so fall back to the console-like block picked
  // by the same key rule FeatureRules.oemHasConsole uses and read its flags.
  final Map<dynamic, dynamic>? block =
      kvmOemConsoleBlock(node, maxDepth: maxDepth) ??
          _consoleLikeBlock(node, 0, maxDepth);
  if (block == null) return true;
  if (block['ServiceEnabled'] == true || block['Enabled'] == true) return true;
  return !block.containsKey('ServiceEnabled') && !block.containsKey('Enabled');
}

/// Returns the first console-like map in [node] (a key containing `kvm` or
/// `console`, matching `FeatureRules.oemHasConsole`), bounded to [maxDepth],
/// regardless of whether it carries a usable `Uri`.
///
/// Used only as the enablement fallback in [kvmOemConsoleEnabled] when no
/// URI-bearing console block exists: it lets an explicit `ServiceEnabled:
/// false` / `Enabled: false` on a URI-less OEM console be honored. Prefers a
/// console-like block that actually carries an enablement member so vendor
/// metadata with no such flag cannot mask the real console's explicit state;
/// otherwise the first console-like block is used, keeping detection aligned
/// with `FeatureRules.oemHasConsole`.
Map<dynamic, dynamic>? _consoleLikeBlock(
    dynamic node, int depth, int maxDepth) {
  if (depth > maxDepth || node is! Map<dynamic, dynamic>) return null;

  Map<dynamic, dynamic>? first;
  for (final dynamic entry in node.entries) {
    final String key = entry.key.toString().toLowerCase();
    if ((key.contains('kvm') ||
            key.contains('console') ||
            key.contains('webconsole')) &&
        entry.value is Map<dynamic, dynamic>) {
      final Map<dynamic, dynamic> block = entry.value as Map<dynamic, dynamic>;
      if (block.containsKey('ServiceEnabled') || block.containsKey('Enabled')) {
        return block;
      }
      first ??= block;
    }
  }
  // Prefer a nested console-like block that carries an explicit enablement
  // member over one that does not, so a flag-less metadata block cannot mask a
  // real console's explicit disabled state in a multi-vendor `Oem` payload.
  for (final dynamic value in node.values) {
    final Map<dynamic, dynamic>? block =
        _consoleLikeBlock(value, depth + 1, maxDepth);
    if (block == null) continue;
    if (block.containsKey('ServiceEnabled') || block.containsKey('Enabled')) {
      return block;
    }
    first ??= block;
  }
  return first;
}

/// Returns a usable console endpoint member from [map], or `null`.
///
/// Vendors publish the OEM console endpoint under two spellings: the short
/// `Uri` (e.g. `Oem.OpenBMC.KVM.Uri`) and the canonical Redfish member
/// `ConnectUri` (e.g. `Oem.<Vendor>.KVM.ConnectUri`, which the registered
/// vendor-parser path already reads). The generic fallback previously only
/// recognized `Uri`, so a vendor that used the schema-correct `ConnectUri`
/// without a registered parser had no resolvable endpoint on either KVM view —
/// the per-console card hid its URI row and the capability card showed no
/// resolved URI. Accept both, preferring `Uri` when a block carries both so an
/// existing OEM payload is never re-pointed (issue #009 / #021).
///
/// Keys and values are trimmed and keys matched case-insensitively, consistent
/// with every other URI/key source in the KVM models. A blank or non-string
/// value is ignored so it cannot shadow a later valid fallback.
String? _uriFromMap(Map<dynamic, dynamic> map) {
  String? connectUri;
  for (final dynamic entry in map.entries) {
    final dynamic value = entry.value;
    if (value is! String) continue;
    final String trimmed = value.trim();
    if (trimmed.isEmpty) continue;
    final String key = entry.key.toString().trim().toLowerCase();
    if (key == 'uri') return trimmed; // canonical OEM spelling wins
    if (key == 'connecturi') connectUri ??= trimmed; // Redfish schema member
  }
  return connectUri;
}
