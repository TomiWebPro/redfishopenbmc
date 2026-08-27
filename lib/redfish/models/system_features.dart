// Placeholder feature map for discovery engine (#003).
// Full model moves to lib/features/discovery/ in #003.

class SystemFeatures {
  const SystemFeatures({
    required this.systemId,
    this.powerControl = false,
    this.kvm = false,
    this.firmwareUpdate = false,
    this.sensorMonitoring = false,
  });

  final String systemId;
  final bool powerControl;
  final bool kvm;
  final bool firmwareUpdate;
  final bool sensorMonitoring;

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
