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
      kvmManagerDerivedSource(managerId);
}

/// Builds the fail-closed `/redfish/v1/Managers/<managerId>` fallback used when
/// neither the `@odata.id` nor an explicit source override is usable (RM-18,
/// issue #009/#021).
///
/// The manager id is BMC-supplied, so it must be trimmed and percent-encoded
/// before it is embedded in a path that both KVM cards disclose (source row and
/// clipboard fallback). Without the encoding a padded / blank / control-bearing
/// / non-ASCII id would leak raw whitespace or a control code point into the
/// derived path: `_controlSafeTrimmedUri` trims the *whole* URI before its
/// character scan, so a trailing-space-only id such as `'   '` was reported
/// control-safe while `safeManagerUri` returned the untrimmed
/// `/redfish/v1/Managers/   ` verbatim. Encoding here makes the derived source
/// itself safe on BOTH views (which share this helper) and keeps the
/// `safeManagerUri` getters' own encoding as defence-in-depth for directly
/// constructed models. A blank id degrades to the non-empty `manager` segment,
/// matching the existing getter fallback. For an ordinary id (`BMC`, `bmc`, …)
/// `Uri.encodeComponent` is the identity, so no valid source is lost.
String kvmManagerDerivedSource(String managerId) {
  final String encodedId = Uri.encodeComponent(managerId.trim());
  return '/redfish/v1/Managers/${encodedId.isEmpty ? 'manager' : encodedId}';
}
