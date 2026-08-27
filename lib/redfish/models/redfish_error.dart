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
    final List<String>? extendedInfo = rawExt == null
        ? null
        : rawExt.map((e) {
            if (e is Map<dynamic, dynamic>) {
              // Extended-info entries are themselves envelopes; the actionable
              // text lives in their `Message` / `message` field.
              final dynamic msg = e['Message'] ?? e['message'];
              return msg?.toString() ?? e.toString();
            }
            return e.toString();
          }).toList();
    return RedfishError(
      code: code ?? 'Unknown',
      message: message ?? 'Unknown error',
      extendedInfo: extendedInfo,
    );
  }

  /// Machine-readable error code (e.g. `Base.1.0.GeneralError`).
  final String code;

  /// Human-readable error message.
  final String message;

  /// Optional extended info entries from `@Message.ExtendedInfo`.
  final List<String>? extendedInfo;

  /// The first extended-info message, when present, else [message].
  ///
  /// BMCs frequently encode the actionable detail inside
  /// `@Message.ExtendedInfo[0].Message`; this prefers that over the coarse
  /// top-level [message].
  String get firstMessage {
    final List<String>? info = extendedInfo;
    if (info != null && info.isNotEmpty) return info.first;
    return message;
  }

  /// Parses a [RedfishError] from an arbitrary response body, returning `null`
  /// when [data] is not a decodable error envelope (e.g. an empty 204 body).
  static RedfishError? tryParse(dynamic data) {
    if (data is Map<String, dynamic>) return RedfishError.fromJson(data);
    if (data is Map) {
      return RedfishError.fromJson(
        <String, dynamic>{
          for (final MapEntry<dynamic, dynamic> e in data.entries)
            e.key.toString(): e.value,
        },
      );
    }
    return null;
  }
}
