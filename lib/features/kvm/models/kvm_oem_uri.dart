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
/// `Uri` member, then a recursive walk of nested vendor blocks. A blank or
/// non-string `Uri` is ignored, so it cannot shadow a later valid fallback.
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

/// Returns a usable, trimmed OEM console `Uri` found in [node], or `null`.
///
/// Delegates to [kvmOemConsoleBlock] so the URI always comes from the exact
/// console block the enablement check inspects (issue #009).
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
  final Map<dynamic, dynamic>? block =
      kvmOemConsoleBlock(node, maxDepth: maxDepth);
  if (block == null) return true;
  if (block['ServiceEnabled'] == true || block['Enabled'] == true) return true;
  return !block.containsKey('ServiceEnabled') && !block.containsKey('Enabled');
}

String? _uriFromMap(Map<dynamic, dynamic> map) {
  for (final dynamic entry in map.entries) {
    if (entry.key.toString().toLowerCase() == 'uri') {
      final dynamic value = entry.value;
      if (value is! String) continue;
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
  }
  return null;
}
