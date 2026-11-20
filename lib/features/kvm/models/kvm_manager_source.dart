/// Shared normalization of the BMC-supplied manager source URI (`@odata.id`).
///
/// Both KVM views read the *same* `@odata.id` from a Redfish manager body: the
/// per-console card via `KvmConsole.fromManager` and the per-manager capability
/// card via `KvmCapability.fromManager`. A whitespace-padded value must be
/// trimmed, and a blank / non-string value must fall back to the stable
/// `/redfish/v1/Managers/<managerId>` path, on BOTH views. If the two paths
/// disagreed, the two cards would show a different source identity for the same
/// physical manager (RS-5, issue #009). Keeping the rule in one pure,
/// widget-free helper makes drift impossible.
///
/// Read-only: inspects a JSON value only, never opens a connection and never
/// changes transport security.
library;

/// Returns a trimmed, non-blank string from [value], or `null`.
///
/// A Redfish `@odata.id` should be a string URI; a numeric / boolean / list
/// value is malformed BMC data rather than a usable source, so it is ignored
/// (never stringified into a stray "42" / "null" source disclosure). A padded
/// but valid URI is trimmed so it stays consistent with every other KVM URI
/// source and no stray whitespace leaks onto either card.
String? kvmManagerSourceTrimmed(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Resolves the manager source URI from [value] (the preferred source), then
/// [fallback], then the stable manager-id path.
///
/// [KvmConsole.fromManager] passes the manager body's `@odata.id` as [value]
/// with no fallback. `KvmCapability.fromManager` passes an explicit override as
/// [value] (with the body's `@odata.id` as [fallback]) so a caller-supplied
/// source wins but a blank / malformed override cannot shadow the body's value.
/// Both converge on the same trimmed value or the same
/// `/redfish/v1/Managers/<managerId>` fallback, so the console card and the
/// capability card can never disagree about a manager's source identity
/// (RS-5, issue #009).
String kvmManagerSourceUri(
  Object? value,
  String managerId, [
  Object? fallback,
]) {
  return kvmManagerSourceTrimmed(value) ??
      kvmManagerSourceTrimmed(fallback) ??
      '/redfish/v1/Managers/$managerId';
}
