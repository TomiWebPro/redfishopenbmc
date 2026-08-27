/// Discovered capability map for a single Redfish system.
///
/// Produced by the discovery engine (#003). Captures which optional
/// Redfish features a given BMC exposes so the UI can render only
/// supported controls ("nothing is assumed").
class SystemFeatures {
  /// Creates a [SystemFeatures] capability map for [systemId].
  const SystemFeatures({
    required this.systemId,
    this.powerControl = false,
    this.kvm = false,
    this.firmwareUpdate = false,
    this.sensorMonitoring = false,
  });

  /// Unique identifier for the system (typically the `@odata.id` leaf).
  final String systemId;

  /// Whether power control / reset actions are available.
  final bool powerControl;

  /// Whether remote KVM / GraphicalConsole is available.
  final bool kvm;

  /// Whether firmware update management is available.
  final bool firmwareUpdate;

  /// Whether sensor monitoring telemetry is available.
  final bool sensorMonitoring;

  /// Serializes the capability map to a JSON envelope.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'system_id': systemId,
        'features': <String, dynamic>{
          'power_control': powerControl,
          'kvm': kvm,
          'firmware_update': firmwareUpdate,
          'sensor_monitoring': sensorMonitoring,
        },
      };
}
