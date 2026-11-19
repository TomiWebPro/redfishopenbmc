/// Shared, tolerant parser for the Redfish `MaxConcurrentSessions` field
/// (issue #009).
///
/// Both KVM views render this count: `KvmConsole.maxConcurrentSessions` on the
/// per-console card and `KvmCapability.maxSessions` on the per-manager
/// capability card. They previously carried two near-identical private parsers
/// whose doc comments promised they "mirror" each other — a drift hazard that
/// already cost several cross-view fixes in this feature. This single pure
/// helper is now the source of truth, so the two cards can never disagree about
/// the same BMC value.
///
/// Tolerates an integer-valued JSON number encoded as a `double` (e.g. `4.0`):
/// `dart:convert`'s `jsonDecode` decodes a JSON number with a decimal point to
/// a `double`, and some BMC serializers emit that form for integer-valued
/// schema fields. The old int-only parser silently dropped it, losing the
/// session limit on both cards. Non-integral / non-finite / negative values are
/// out of spec (DMTF `Manager` defines a minimum of 0) and are surfaced as
/// unreported rather than rendering a bogus "Max sessions: -1" / "2.5" chip.
///
/// Pure, widget-free and dependency-free: it parses a value and opens no URL,
/// performs no I/O and never changes transport security (no TLS weakening).
library;

/// Largest integer that a `double` can represent exactly (2^53). Beyond this
/// an integral double loses low bits, so converting it to `int` could silently
/// change the reported limit — treat it as unreported instead.
const double _kMaxExactIntegerDouble = 9007199254740992.0;

/// Returns [value] as a spec-valid `MaxConcurrentSessions` limit, or `null`
/// when it is absent, malformed, non-integral or negative.
///
/// Accepted: an `int`, an integral `double` (finite, exact, within 2^53) or a
/// numeric `String` (trimmed) in any of those forms. Rejected: fractional or
/// non-finite doubles, negative values, blank/non-numeric strings and any other
/// type. The result is always a non-negative `int` or `null`.
int? kvmSessionLimit(Object? value) {
  final num? numeric;
  if (value is num) {
    numeric = value;
  } else if (value is String) {
    numeric = num.tryParse(value.trim());
  } else {
    numeric = null;
  }
  if (numeric == null) return null;
  if (numeric is double &&
      (!numeric.isFinite ||
          numeric != numeric.roundToDouble() ||
          numeric.abs() > _kMaxExactIntegerDouble)) {
    return null;
  }
  final int parsed = numeric.toInt();
  return parsed < 0 ? null : parsed;
}
