/// Connection profile for a single Redfish/BMC target.
///
/// Passwords are held **in memory only** for the duration of a login and
/// are never written to secure storage. For session auth the resulting
/// token is persisted instead (see `auth_manager.dart`).
class ConnectionProfile {
  /// Creates a [ConnectionProfile] for a BMC endpoint.
  const ConnectionProfile({
    required this.host,
    this.port = 443,
    this.scheme = 'https',
    this.allowSelfSigned = false,
    this.preferSessionAuth = true,
    this.username,
    this.password,
  });

  /// Hostname or IP of the BMC.
  final String host;

  /// TCP port the Redfish HTTPS service listens on.
  final int port;

  /// Only `https` is supported by design (TLS-first). `http` is rejected
  /// at construction time by callers; kept as a field for completeness.
  final String scheme;

  /// Opt-in toggle to accept a self-signed / untrusted certificate.
  ///
  /// This is a deliberate security downgrade and must be per-profile and
  /// user-acknowledged (see #010 hardening).
  final bool allowSelfSigned;

  /// Prefer `SessionService` token auth over Basic auth. OpenBMC's bmcweb
  /// and most DMTF implementations prefer sessions.
  final bool preferSessionAuth;

  /// Username for Basic or Session login. Never persisted.
  final String? username;

  /// Password for Basic or Session login. Never persisted; only used to
  /// mint a session or build the Basic header in memory.
  final String? password;

  /// Base URL `scheme://host:port` used as the Dio base URL.
  String get baseUrl => '$scheme://$host:$port';

  /// Returns a copy with the provided fields overridden.
  ConnectionProfile copyWith({
    String? host,
    int? port,
    String? scheme,
    bool? allowSelfSigned,
    bool? preferSessionAuth,
    String? username,
    String? password,
  }) =>
      ConnectionProfile(
        host: host ?? this.host,
        port: port ?? this.port,
        scheme: scheme ?? this.scheme,
        allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
        preferSessionAuth: preferSessionAuth ?? this.preferSessionAuth,
        username: username ?? this.username,
        password: password ?? this.password,
      );
}
