/// Discovered capability map for a single Redfish system.
///
/// Produced by the discovery engine (#003). Captures which optional Redfish
/// features a given BMC exposes so the UI can render only supported controls
/// ("nothing is assumed"). The UI contract is the `features` envelope emitted
/// by [toJson].
class SystemFeatures {
  /// Creates a [SystemFeatures] capability map for [systemId].
  ///
  /// Every feature defaults to `false` / empty so a partial or failing
  /// discovery still yields a usable (conservative) map.
  const SystemFeatures({
    required this.systemId,
    this.powerControl = false,
    this.supportedResetTypes = const <String>[],
    this.kvm = false,
    this.kvmType,
    this.sensorMonitoring = false,
    this.sensorCount = 0,
    this.firmwareUpdate = false,
    this.updateServiceVersion,
    this.managers = 0,
    this.chassis = 0,
    this.raw = const <String, dynamic>{},
  });

  /// Unique identifier for the system (typically the connection profile id,
  /// e.g. `bmc1`). Used as the cache / isolation key.
  final String systemId;

  /// Whether power control / reset actions are available
  /// (`Systems[*].Actions.#ComputerSystem.Reset`).
  final bool powerControl;

  /// Reset types advertised by the computer system(s), e.g.
  /// `On`, `GracefulRestart`, `ForceOff`.
  final List<String> supportedResetTypes;

  /// Whether remote KVM / GraphicalConsole (or SerialConsole / OEM) is
  /// available on a manager.
  final bool kvm;

  /// The kind of console detected (`GraphicalConsole`, `SerialConsole`,
  /// `Oem`), or `null` when KVM is unavailable.
  final String? kvmType;

  /// Whether sensor monitoring telemetry is available
  /// (`Chassis[*].Thermal` / `Chassis[*].Sensors`).
  final bool sensorMonitoring;

  /// Approximate number of readable sensors (temperatures + fans + voltages +
  /// sensor members).
  final int sensorCount;

  /// Whether firmware update management is available (`UpdateService`).
  final bool firmwareUpdate;

  /// Firmware / UpdateService version string when available.
  final String? updateServiceVersion;

  /// Number of manager resources discovered.
  final int managers;

  /// Number of chassis resources discovered.
  final int chassis;

  /// Raw resource tree (URI → body) captured during discovery. Used by the
  /// developer "raw explorer" hook; not required for the UI.
  final Map<String, dynamic> raw;

  /// Whether the system exposes *any* of the optional management features.
  bool get hasAnyFeature =>
      powerControl || kvm || firmwareUpdate || sensorMonitoring;

  /// Returns a copy of this map with the given fields overridden.
  SystemFeatures copyWith({
    String? systemId,
    bool? powerControl,
    List<String>? supportedResetTypes,
    bool? kvm,
    String? kvmType,
    bool? sensorMonitoring,
    int? sensorCount,
    bool? firmwareUpdate,
    String? updateServiceVersion,
    int? managers,
    int? chassis,
    Map<String, dynamic>? raw,
  }) =>
      SystemFeatures(
        systemId: systemId ?? this.systemId,
        powerControl: powerControl ?? this.powerControl,
        supportedResetTypes: supportedResetTypes ?? this.supportedResetTypes,
        kvm: kvm ?? this.kvm,
        kvmType: kvmType ?? this.kvmType,
        sensorMonitoring: sensorMonitoring ?? this.sensorMonitoring,
        sensorCount: sensorCount ?? this.sensorCount,
        firmwareUpdate: firmwareUpdate ?? this.firmwareUpdate,
        updateServiceVersion:
            updateServiceVersion ?? this.updateServiceVersion,
        managers: managers ?? this.managers,
        chassis: chassis ?? this.chassis,
        raw: raw ?? this.raw,
      );

  /// Serializes the capability map to the UI contract envelope.
  ///
  /// Example:
  /// ```json
  /// {
  ///   "system_id": "bmc1",
  ///   "features": {
  ///     "power_control": true,
  ///     "kvm": false,
  ///     "firmware_update": true,
  ///     "sensor_monitoring": true
  ///   }
  /// }
  /// ```
  Map<String, dynamic> toJson() => <String, dynamic>{
        'system_id': systemId,
        'features': <String, dynamic>{
          'power_control': powerControl,
          'kvm': kvm,
          'firmware_update': firmwareUpdate,
          'sensor_monitoring': sensorMonitoring,
          'supported_reset_types': supportedResetTypes,
          'kvm_type': kvmType,
          'sensor_count': sensorCount,
          'firmware_update_version': updateServiceVersion,
          'managers': managers,
          'chassis': chassis,
        },
      };

  /// Parses a [SystemFeatures] from the [toJson] envelope (round-trips the
  /// `system_id` + `features.*` keys).
  factory SystemFeatures.fromJson(Map<String, dynamic> json) {
    final dynamic rawFeatures = json['features'];
    final Map<String, dynamic> features = rawFeatures is Map<String, dynamic>
        ? rawFeatures
        : <String, dynamic>{};
    final dynamic rawMap = json['raw'];
    return SystemFeatures(
      systemId: json['system_id'] as String? ?? '',
      powerControl: features['power_control'] as bool? ?? false,
      supportedResetTypes: _asStringList(features['supported_reset_types']),
      kvm: features['kvm'] as bool? ?? false,
      kvmType: features['kvm_type'] as String?,
      sensorMonitoring: features['sensor_monitoring'] as bool? ?? false,
      sensorCount: features['sensor_count'] as int? ?? 0,
      firmwareUpdate: features['firmware_update'] as bool? ?? false,
      updateServiceVersion: features['firmware_update_version'] as String?,
      managers: features['managers'] as int? ?? 0,
      chassis: features['chassis'] as int? ?? 0,
      raw: rawMap is Map<String, dynamic>
          ? rawMap
          : <String, dynamic>{},
    );
  }

  @override
  String toString() =>
      'SystemFeatures($systemId: power=$powerControl, kvm=$kvm($kvmType), '
      'fw=$firmwareUpdate, sensors=$sensorMonitoring($sensorCount), '
      'managers=$managers, chassis=$chassis)';
}

/// Builds a [List<String>] from a JSON value that may be a list of strings or
/// a list of arbitrary items (stringified).
List<String> _asStringList(dynamic value) {
  if (value is List<dynamic>) {
    return value.map((dynamic e) => e.toString()).toList();
  }
  return const <String>[];
}
