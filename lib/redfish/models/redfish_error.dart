/// Represents a Redfish error payload returned by a BMC.
///
/// Redfish services return errors in a structured envelope containing a
/// machine-readable [code], a human-readable [message], and optionally
/// extended info entries ([extendedInfo]).
class RedfishError {
  /// Creates a [RedfishError].
  const RedfishError({
    required this.code,
    required this.message,
    this.extendedInfo,
  });

  /// Creates a [RedfishError] from a decoded JSON envelope.
  factory RedfishError.fromJson(Map<String, dynamic> json) {
    return RedfishError(
      code: json['code'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? 'Unknown error',
      extendedInfo: (json['@Message.ExtendedInfo'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Machine-readable error code (e.g. `Base.1.0.GeneralError`).
  final String code;

  /// Human-readable error message.
  final String message;

  /// Optional extended info entries from `@Message.ExtendedInfo`.
  final List<String>? extendedInfo;
}
