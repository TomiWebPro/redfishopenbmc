import 'package:dio/dio.dart';
import 'package:redfishopenbmc/redfish/models/redfish_error.dart';

/// Removes any URL userinfo (`username:password@`) component from [uri].
///
/// A BMC address or a redirect `Location` can embed credentials in a URI's
/// userinfo (e.g. `https://root:s3cret@bmc/redfish/v1/`). [RedfishException]
/// objects flow into error UI, debug logs and diagnostics, so carrying the raw
/// URI would leak a plaintext password/token. Every transport URI captured by
/// the exception factories is passed through this helper first (issue #010
/// credential-leak audit). URIs without userinfo are returned unchanged; a
/// `null` URI stays `null`. Scheme, host, port, path, query and fragment are
/// preserved — only the userinfo is dropped.
Uri? redactUriCredentials(Uri? uri) =>
    (uri == null || uri.userInfo.isEmpty) ? uri : uri.replace(userInfo: '');

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

  /// Whether this failure is a 412 Precondition Failed — the service rejected
  /// the request's `If-Match`/`If-None-Match` precondition.
  ///
  /// DSP0266 §6.5 (RFC7232): a stale optimistic-concurrency token makes a
  /// PATCH answer 412 instead of overwriting. Callers should re-fetch the
  /// resource for the current `@odata.etag` and retry, not blindly re-issue
  /// the identical request (which cannot succeed against the same stale tag).
  bool get isPreconditionFailed => statusCode == 412;

  /// Whether this is an authentication/authorization failure (401 or 403).
  ///
  /// DSP0266 §8.2: an expired/invalid session yields 401 and an insufficiently
  /// privileged one yields 403. Both are fatal for the current request and must
  /// bubble to the auth manager rather than being treated as a missing optional
  /// sub-resource — feature services use this to keep graceful 404 degradation
  /// without masking a surfaced auth failure (issue #007).
  bool get isAuthError => statusCode == 401 || statusCode == 403;

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
    // A transport-level guard (e.g. the TLS downgrade interceptor) may attach
    // an already-normalized exception to the DioException. Preserve it as-is
    // instead of reclassifying into a generic "Unknown transport error".
    final Object? underlying = error.error;
    if (underlying is RedfishException) return underlying;
    final response = error.response;
    // #010 credential-leak audit: a redirect's final URI can carry
    // `user:password@` userinfo — never let it reach the exception's public
    // `uri` (which error UI / debug logs render).
    final Uri? resolvedUri = redactUriCredentials(uri ?? response?.realUri);
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

    // 429 (rate limit) and transient 5xx are generally retryable. 501 is NOT:
    // DSP0266 §7.3.1 uses 501 for unsupported `$`-prefixed query parameters —
    // a permanent capability signal ("service does not implement this query
    // parameter"), not a transient server failure, so re-issuing the identical
    // request cannot succeed (and the #018 discovery pass must gate the query
    // instead of retrying it).
    final retryable = statusCode == 429 ||
        (statusCode >= 500 && statusCode < 600 && statusCode != 501);

    return RedfishException(
      statusCode: statusCode,
      errorCode: errorCode,
      message: message,
      retryable: retryable,
      raw: data?.toString(),
      uri: redactUriCredentials(uri ?? response.realUri),
      details: details,
    );
  }
}
