import 'package:uuid/uuid.dart';

/// Authentication strategy used when connecting to a BMC.
///
/// Mirrors [ConnectionProfile.preferSessionAuth] (kept for #002 compatibility)
/// but is the app-level source of truth: `session` prefers the
/// `SessionService` token flow, `basic` uses HTTP Basic auth.
enum AuthMethod {
  /// HTTP Basic auth (`Authorization: Basic <b64>`), no server-side session.
  basic,

  /// Redfish `SessionService` token auth (`X-Auth-Token`).
  session,
}

/// Connection profile for a single Redfish/BMC target.
///
/// This is the canonical, app-level profile model (issue #004). It is defined
/// here and re-exported from `redfish/models/connection_profile.dart` so the
/// low-level client layer (#002) keeps compiling unchanged.
///
/// Security contract:
///  * Passwords are held **in memory only** for the duration of a login and
///    are never written to secure storage by the profile itself. The
///    [ProfileRepository] strips the password before persisting the profile
///    list; only when [rememberPassword] is `true` is the password stored in
///    the platform keystore (under `redfish.pw.<id>`), never in the profile
///    blob. For session auth the resulting token is persisted instead (see
///    `auth_manager.dart`).
///  * [useTls] is derived from [scheme]; TLS-first is the only supported
///    transport (`http` is rejected by callers).
class ConnectionProfile {
  /// Creates a [ConnectionProfile] for a BMC endpoint.
  const ConnectionProfile({
    required this.host,
    this.id = '',
    this.name,
    this.port = 443,
    this.scheme = 'https',
    this.allowSelfSigned = false,
    this.preferSessionAuth = true,
    this.authMethod = AuthMethod.session,
    this.username,
    this.password,
    this.rememberPassword = false,
    this.createdAt,
  });

  /// Stable unique identifier (UUIDv4) for this profile.
  ///
  /// Empty until assigned; [generateId] / `SystemManager.addProfile` fills it.
  final String id;

  /// Human-friendly display name shown on the dashboard card.
  final String? name;

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

  /// Prefer `SessionService` token auth over Basic auth. Kept for #002
  /// compatibility; [authMethod] is the authoritative value and should be
  /// kept in sync by the UI.
  final bool preferSessionAuth;

  /// Authoritative authentication strategy for this profile.
  final AuthMethod authMethod;

  /// Username for Basic or Session login. Never persisted in the profile blob.
  final String? username;

  /// Password for Basic or Session login. Never persisted in the profile blob;
  /// only used to mint a session or build the Basic header in memory.
  final String? password;

  /// Whether the password should be persisted (encrypted) in the platform
  /// keystore. False means the password lives only in memory for the session.
  final bool rememberPassword;

  /// When the profile was first created.
  final DateTime? createdAt;

  /// Whether TLS is used (derived from [scheme] == `https`).
  bool get useTls => scheme == 'https';

  /// Base URL `scheme://host:port` used as the Dio base URL.
  String get baseUrl => '$scheme://$host:$port';

  /// Generates a fresh UUIDv4 suitable for [id].
  static String generateId() => const Uuid().v4();

  /// Returns a copy with the provided fields overridden.
  ConnectionProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? scheme,
    bool? allowSelfSigned,
    bool? preferSessionAuth,
    AuthMethod? authMethod,
    String? username,
    String? password,
    bool? rememberPassword,
    DateTime? createdAt,
  }) =>
      ConnectionProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
        scheme: scheme ?? this.scheme,
        allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
        preferSessionAuth: preferSessionAuth ?? this.preferSessionAuth,
        authMethod: authMethod ?? this.authMethod,
        username: username ?? this.username,
        password: password ?? this.password,
        rememberPassword: rememberPassword ?? this.rememberPassword,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Serializes the profile to JSON for persistence.
  ///
  /// The [password] is intentionally **included** so that callers (the
  /// [ProfileRepository]) can decide whether to strip it before writing. The
  /// in-memory model never logs this field.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'scheme': scheme,
        'allowSelfSigned': allowSelfSigned,
        'preferSessionAuth': preferSessionAuth,
        'authMethod': authMethod.name,
        'username': username,
        'password': password,
        'rememberPassword': rememberPassword,
        'createdAt': createdAt?.toIso8601String(),
      };

  /// Parses a [ConnectionProfile] from [toJson].
  factory ConnectionProfile.fromJson(Map<String, dynamic> json) {
    final String rawAuth = json['authMethod'] as String? ?? 'session';
    final AuthMethod method = AuthMethod.values.firstWhere(
      (AuthMethod e) => e.name == rawAuth,
      orElse: () => AuthMethod.session,
    );
    final String? created = json['createdAt'] as String?;
    return ConnectionProfile(
      id: (json['id'] as String?) ?? '',
      name: json['name'] as String?,
      host: (json['host'] as String?) ?? '',
      port: (json['port'] as int?) ?? 443,
      scheme: (json['scheme'] as String?) ?? 'https',
      allowSelfSigned: (json['allowSelfSigned'] as bool?) ?? false,
      preferSessionAuth: (json['preferSessionAuth'] as bool?) ?? true,
      authMethod: method,
      username: json['username'] as String?,
      password: json['password'] as String?,
      rememberPassword: (json['rememberPassword'] as bool?) ?? false,
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }

  @override
  String toString() =>
      'ConnectionProfile(${name ?? id}: $scheme://$host:$port, '
      'auth=$authMethod, tls=$useTls)';
}
