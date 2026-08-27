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
  ///
  /// Redfish error bodies use the capital-cased `Message` / `Code` /
  /// `@Message.ExtendedInfo` keys; we fall back to the lowercase variants
  /// for lenient interop with non-conformant services.
  factory RedfishError.fromJson(Map<String, dynamic> json) {
    final String? code = (json['Code'] ?? json['code']) as String?;
    final String? message = (json['Message'] ?? json['message']) as String?;
    final List<dynamic>? rawExt =
        (json['@Message.ExtendedInfo'] ?? json['extendedInfo'])
            as List<dynamic>?;
    return RedfishError(
      code: code ?? 'Unknown',
      message: message ?? 'Unknown error',
      extendedInfo: rawExt?.map((e) => e.toString()).toList(),
    );
  }

  /// Machine-readable error code (e.g. `Base.1.0.GeneralError`).
  final String code;

  /// Human-readable error message.
  final String message;

  /// Optional extended info entries from `@Message.ExtendedInfo`.
  final List<String>? extendedInfo;
}
