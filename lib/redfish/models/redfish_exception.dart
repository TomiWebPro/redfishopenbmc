import 'package:dio/dio.dart';
import 'package:redfishopenbmc/redfish/models/redfish_error.dart';

/// Normalized error type for all Redfish transport failures.
///
/// Every [DioException] or non-2xx [Response] is mapped into this single
/// type so feature code never branches on raw HTTP plumbing. The
/// [retryable] flag lets callers decide whether a request can be safely
/// re-issued (timeouts, 429, 5xx) versus fatal (401, 403, cert).
class RedfishException implements Exception {
  /// Creates a [RedfishException].
  const RedfishException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.retryable = false,
    this.raw,
    this.uri,
    this.details,
  });

  /// Human-readable error message.
  final String message;

  /// HTTP status code when available, otherwise `null`.
  final int? statusCode;

  /// Machine-readable Redfish/base error code when available.
  final String? errorCode;

  /// Whether the request can be safely retried.
  final bool retryable;

  /// Raw response/error body when available.
  final String? raw;

  /// Request URI that produced the error, when known.
  final Uri? uri;

  /// Structured Redfish error envelope parsed from the response body, when
  /// present (carries `@Message.ExtendedInfo` etc.).
  final RedfishError? details;

  @override
  String toString() => 'RedfishException(status=$statusCode, code=$errorCode, '
      'retryable=$retryable): $message';

  /// Whether a structured [RedfishError] envelope was parsed from the body.
  bool get hasDetails => details != null;

  /// Network-level failure (timeout / connection error). Retryable.
  factory RedfishException.network(String message) => RedfishException(
        message: message,
        retryable: true,
      );

  /// TLS certificate validation failure. Fatal.
  factory RedfishException.certificate(String message) => RedfishException(
        errorCode: 'CertificateError',
        message: message,
      );

  /// Build from a [DioException], classifying timeout / connection /
  /// certificate / bad-response cases.
  factory RedfishException.fromDioException(
    DioException error, {
    Uri? uri,
  }) {
    final response = error.response;
    final resolvedUri = uri ?? response?.realUri;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RedfishException(
          statusCode: response?.statusCode,
          message: 'Network timeout: ${error.message ?? 'unknown'}',
          retryable: true,
          uri: resolvedUri,
        );
      case DioExceptionType.badCertificate:
        return RedfishException.certificate(
          'TLS certificate validation failed: ${error.message ?? 'unknown'}',
        );
      case DioExceptionType.connectionError:
        return RedfishException.network(
          'Connection error: ${error.message ?? 'unknown'}',
        );
      case DioExceptionType.badResponse:
        return RedfishException.fromResponse(response!, uri: resolvedUri);
      case DioExceptionType.cancel:
        return RedfishException(
          statusCode: response?.statusCode,
          message: 'Request cancelled: ${error.message ?? 'unknown'}',
          uri: resolvedUri,
        );
      case DioExceptionType.unknown:
      default:
        return RedfishException(
          statusCode: response?.statusCode,
          message: error.message ?? 'Unknown transport error',
          uri: resolvedUri,
        );
    }
  }

  /// Build from a non-2xx [Response], extracting the Redfish
  /// `@Message.ExtendedInfo` / `Message` / `Code` fields when present.
  factory RedfishException.fromResponse(
    Response<dynamic> response, {
    Uri? uri,
  }) {
    final statusCode = response.statusCode ?? 0;
    var message = 'HTTP $statusCode';
    String? errorCode;

    final data = response.data;
    RedfishError? details;
    if (data is Map) {
      // Normalize any map-shaped body (String-keyed or dynamic-keyed) and let
      // RedfishError handle the DSP0266 `error` envelope (self-descends).
      final Map<String, dynamic> body = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{
              for (final MapEntry<dynamic, dynamic> e in data.entries)
                e.key.toString(): e.value,
            };
      final RedfishError? parsed = RedfishError.tryParse(body);
      details = parsed;
      if (parsed != null) {
        if (parsed.message != 'Unknown error') {
          message = parsed.message;
        }
        if (parsed.code != 'Unknown') {
          errorCode = parsed.code;
        }
      }
    }

    // 429 (rate limit) and 5xx are generally retryable.
    final retryable =
        statusCode == 429 || (statusCode >= 500 && statusCode < 600);

    return RedfishException(
      statusCode: statusCode,
      errorCode: errorCode,
      message: message,
      retryable: retryable,
      raw: data?.toString(),
      uri: uri ?? response.realUri,
      details: details,
    );
  }
}
