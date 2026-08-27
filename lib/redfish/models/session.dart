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
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

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
