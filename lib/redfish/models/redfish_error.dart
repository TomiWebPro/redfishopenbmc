// Placeholder for #002 — Redfish error model.
// Kept minimal for #001 scaffold; full impl in #002.
class RedfishError {
  const RedfishError({required this.code, required this.message, this.extendedInfo});

  final String code;
  final String message;
  final List<String>? extendedInfo;

  factory RedfishError.fromJson(Map<String, dynamic> json) {
    return RedfishError(
      code: json['code'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? 'Unknown error',
      extendedInfo: (json['@Message.ExtendedInfo'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
