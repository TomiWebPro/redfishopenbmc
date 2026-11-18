/// Shared, bounded OEM-console URI resolution for the two KVM views (issue
/// #009).
///
/// A Redfish manager may expose its console only under `Oem` (for example
/// `Oem.OpenBMC.KVM.Uri`). Both [KvmConsole.fromManager] (the per-console card)
/// and `KvmCapability.resolveLaunchUri` (the per-manager capability card) must
/// surface that same endpoint for the same manager, otherwise the two views
/// disagree about where the operator should open the console. Keeping the
/// search in one pure, widget-free helper guarantees they never drift.
///
/// Resolution is read-only: it returns a trimmed URI string to the caller and
/// never opens a connection, spawns IPC, or changes transport security.
library;

/// Returns a usable, trimmed OEM console `Uri` found in [node], or `null`.
///
/// Search order (bounded to [maxDepth] levels): first a direct console-like key
/// (`kvm` / `console` / `webconsole`, case-insensitive) whose map carries a
/// `Uri` member, then a recursive walk of nested vendor blocks. A blank or
/// non-string `Uri` is ignored, so it cannot shadow a later valid fallback.
String? kvmOemConsoleUri(dynamic node, {int maxDepth = 3}) =>
    _findAt(node, 0, maxDepth);

String? _findAt(dynamic node, int depth, int maxDepth) {
  if (depth > maxDepth || node is! Map<dynamic, dynamic>) return null;

  // Prefer a direct console-like key whose map carries a `Uri` member.
  for (final dynamic entry in node.entries) {
    final String key = entry.key.toString().toLowerCase();
    if ((key.contains('kvm') ||
            key.contains('console') ||
            key.contains('webconsole')) &&
        entry.value is Map<dynamic, dynamic>) {
      final String? uri = _uriFromMap(entry.value as Map<dynamic, dynamic>);
      if (uri != null) return uri;
    }
  }
  // Otherwise search nested vendor blocks.
  for (final dynamic value in node.values) {
    final String? uri = _findAt(value, depth + 1, maxDepth);
    if (uri != null) return uri;
  }
  return null;
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
