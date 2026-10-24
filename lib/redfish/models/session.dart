/// Authenticated session for a single Redfish system.
///
/// The `token` is what is sent on every subsequent request (as
/// `X-Auth-Token` for session auth). It is the only secret persisted to
/// secure storage; the password is never stored.
class Session {
  /// Creates a [Session] for [systemId].
  const Session({
    required this.systemId,
    required this.token,
    required this.location,
    required this.username,
    this.createdAt,
    this.expiresAt,
  });

  /// Logical id of the owning system (e.g. `bmc1`). Used as the isolation
  /// key in the auth manager.
  final String systemId;

  /// `X-Auth-Token` value (session auth) or the Basic credential string
  /// (Basic auth). Never a plaintext password.
  final String token;

  /// `@odata.id` / `Location` of the session resource, used to `DELETE` on
  /// logout. Empty for Basic auth (no server-side session).
  final String location;

  /// Username the session belongs to (display only; not sent as secret).
  final String username;

  /// When the session was minted.
  final DateTime? createdAt;

  /// Expiry derived from `SessionService.SessionTimeout`. `null` means
  /// "no known TTL" and the session is treated as long-lived until a 401.
  final DateTime? expiresAt;

  /// Whether the session has passed its [expiresAt] deadline.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Computes the session expiry deadline from a discovered `SessionService`
  /// resource body, per DSP0266 §13.3.4.3 "Session lifetime" and the mirrored
  /// `SessionService.v1_2_0.json` (DOCS-12/17).
  ///
  /// Contract:
  /// * `SessionTimeout` — seconds of *inactivity* before the service closes
  ///   the session (30–86400 in the schema).
  /// * `AbsoluteSessionTimeout` (added v1_2_0) — maximum seconds a session is
  ///   open **regardless of activity**; it only applies when
  ///   `AbsoluteSessionTimeoutEnabled` is `true`.
  ///
  /// Returns the conservative *earlier* deadline so the client re-authenticates
  /// before the server can kill the session: `createdAt + min(SessionTimeout,
  /// AbsoluteSessionTimeout)` when the absolute timeout is enabled, otherwise
  /// `createdAt + SessionTimeout`. Returns `null` (no known TTL) when the body
  /// is missing or carries no usable timeout values.
  static DateTime? expiryFromService(
    Map<String, dynamic>? sessionService, {
    required DateTime createdAt,
  }) {
    if (sessionService == null) return null;

    final int? sessionTimeout = _readSeconds(sessionService['SessionTimeout']);
    final bool absoluteEnabled =
        sessionService['AbsoluteSessionTimeoutEnabled'] == true;
    final int? absoluteTimeout = absoluteEnabled
        ? _readSeconds(sessionService['AbsoluteSessionTimeout'])
        : null;

    final int? ttl;
    if (sessionTimeout == null) {
      ttl = absoluteTimeout; // absolute-only services still get a deadline
    } else if (absoluteTimeout == null) {
      ttl = sessionTimeout;
    } else {
      ttl = sessionTimeout < absoluteTimeout
          ? sessionTimeout
          : absoluteTimeout; // earlier deadline wins
    }
    return ttl == null ? null : createdAt.add(Duration(seconds: ttl));
  }

  /// Parses an integer-seconds value, tolerating malformed/null input.
  static int? _readSeconds(dynamic value) =>
      value is int ? value : (value is num ? value.toInt() : null);

  /// Returns a copy of this session with the given fields overridden.
  Session copyWith({
    String? token,
    String? location,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) =>
      Session(
        systemId: systemId,
        token: token ?? this.token,
        location: location ?? this.location,
        username: username,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}
