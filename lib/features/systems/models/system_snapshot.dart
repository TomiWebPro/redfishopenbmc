/// Overall health of a system as derived from Redfish `Status.Health`.
enum Health {
  /// System is healthy (`OK`).
  ok,

  /// Degraded but operational (`Warning`).
  warning,

  /// Faulted (`Critical`).
  critical,

  /// Health could not be determined (no data / error).
  unknown,
}

/// Power state of a computer system.
enum PowerState {
  /// Powered on.
  on,

  /// Powered off.
  off,

  /// Power state could not be determined.
  unknown,
}

/// Live, polled snapshot of a single Redfish system.
///
/// Produced by the per-system snapshot fetcher (#004) from
/// `GET /redfish/v1/Systems/{id}` (`Status.Health`, `PowerState`,
/// `Manufacturer`, `Model`, `SerialNumber`). A failed fetch yields a snapshot
/// with [Health.unknown] and a populated [error].
class SystemSnapshot {
  /// Creates a [SystemSnapshot].
  const SystemSnapshot({
    this.health = Health.unknown,
    this.powerState = PowerState.unknown,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.lastUpdated,
    this.error,
  });

  /// Derived health of the system.
  final Health health;

  /// Current power state.
  final PowerState powerState;

  /// System manufacturer, when discovered.
  final String? manufacturer;

  /// System model, when discovered.
  final String? model;

  /// System serial number, when discovered.
  final String? serialNumber;

  /// When this snapshot was captured.
  final DateTime? lastUpdated;

  /// Error message when the snapshot could not be fetched.
  final String? error;

  /// Whether the snapshot represents a successfully fetched reading.
  bool get isHealthy => health == Health.ok;

  /// Whether the snapshot represents a failed fetch.
  bool get hasError => error != null && error!.isNotEmpty;

  /// Returns a copy with the provided fields overridden.
  SystemSnapshot copyWith({
    Health? health,
    PowerState? powerState,
    String? manufacturer,
    String? model,
    String? serialNumber,
    DateTime? lastUpdated,
    String? error,
  }) =>
      SystemSnapshot(
        health: health ?? this.health,
        powerState: powerState ?? this.powerState,
        manufacturer: manufacturer ?? this.manufacturer,
        model: model ?? this.model,
        serialNumber: serialNumber ?? this.serialNumber,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        error: error ?? this.error,
      );

  /// Builds a [SystemSnapshot] from a Redfish ComputerSystem JSON body.
  ///
  /// Tolerates missing/non-map fields by defaulting to [Health.unknown] /
  /// [PowerState.unknown].
  factory SystemSnapshot.fromSystemJson(Map<String, dynamic> json) {
    final dynamic status = json['Status'];
    final Map<String, dynamic> statusMap =
        status is Map<String, dynamic> ? status : <String, dynamic>{};
    final String? healthStr = statusMap['Health'] as String?;
    final String? powerStr = json['PowerState'] as String?;
    return SystemSnapshot(
      health: HealthX.fromStatus(healthStr),
      powerState: PowerStateX.fromStatus(powerStr),
      manufacturer: json['Manufacturer'] as String?,
      model: json['Model'] as String?,
      serialNumber: json['SerialNumber'] as String?,
      lastUpdated: DateTime.now(),
    );
  }

  /// Serializes the snapshot for caching / persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'health': health.name,
        'power_state': powerState.name,
        'manufacturer': manufacturer,
        'model': model,
        'serial_number': serialNumber,
        'last_updated': lastUpdated?.toIso8601String(),
        'error': error,
      };

  /// Parses a [SystemSnapshot] from [toJson].
  factory SystemSnapshot.fromJson(Map<String, dynamic> json) {
    final String? healthStr = json['health'] as String?;
    final String? powerStr = json['power_state'] as String?;
    final String? updated = json['last_updated'] as String?;
    return SystemSnapshot(
      health: HealthX.fromStatus(healthStr),
      powerState: PowerStateX.fromStatus(powerStr),
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      lastUpdated: updated == null ? null : DateTime.tryParse(updated),
      error: json['error'] as String?,
    );
  }
}

/// Helpers for mapping Redfish status strings to [Health].
extension HealthX on Health {
  /// Maps a Redfish `Status.Health` string (or an enum `name`) to [Health].
  static Health fromStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'ok':
        return Health.ok;
      case 'warning':
        return Health.warning;
      case 'critical':
        return Health.critical;
      default:
        return Health.unknown;
    }
  }

  /// Human-readable label for the health value.
  String get label {
    switch (this) {
      case Health.ok:
        return 'OK';
      case Health.warning:
        return 'Warning';
      case Health.critical:
        return 'Critical';
      case Health.unknown:
        return 'Unknown';
    }
  }
}

/// Helpers for mapping Redfish power strings to [PowerState].
extension PowerStateX on PowerState {
  /// Maps a Redfish `PowerState` string (or an enum `name`) to [PowerState].
  static PowerState fromStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'on':
        return PowerState.on;
      case 'off':
        return PowerState.off;
      default:
        return PowerState.unknown;
    }
  }

  /// Human-readable label for the power state.
  String get label {
    switch (this) {
      case PowerState.on:
        return 'On';
      case PowerState.off:
        return 'Off';
      case PowerState.unknown:
        return 'Unknown';
    }
  }
}
