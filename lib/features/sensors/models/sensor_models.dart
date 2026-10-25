import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';

/// Immutable health/state pair from a Redfish `Status` object (issue #007).
///
/// Wraps the `State` and `Health` strings returned by every Redfish resource
/// and exposes a typed [healthEnum] the UI uses to pick a color (no new charting
/// dependency — just a status tint).
class StatusInfo {
  /// Creates a [StatusInfo].
  const StatusInfo({this.state, this.health});

  /// Redfish `Status.State` (e.g. `Enabled`, `Disabled`, `Absent`).
  final String? state;

  /// Redfish `Status.Health` (e.g. `OK`, `Warning`, `Critical`).
  final String? health;

  /// Parses a `Status` sub-object, tolerating its absence.
  factory StatusInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StatusInfo();
    return StatusInfo(
      state: _asString(json['State']),
      health: _asString(json['Health']),
    );
  }

  /// Typed health for the UI, mapping the Redfish string to [Health].
  ///
  /// Unknown / missing values fall back to [Health.unknown].
  Health get healthEnum {
    switch (health?.toLowerCase()) {
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

  @override
  String toString() => 'StatusInfo(state=$state, health=$health)';
}

/// A single temperature reading from a Redfish `Thermal` resource (issue #007).
class ThermalReading {
  /// Creates a [ThermalReading].
  const ThermalReading({
    required this.name,
    this.readingCelsius,
    this.status = const StatusInfo(),
    this.physicalContext,
    this.upperCritical,
    this.upperCaution,
    this.lowerCritical,
    this.lowerCaution,
    this.sourceUri,
  });

  /// Sensor display name (Redfish `Name`).
  final String name;

  /// Current temperature in °C, or `null` when the sensor reports no reading.
  final double? readingCelsius;

  /// Health/state of the sensor.
  final StatusInfo status;

  /// What the reading physically measures (Redfish `PhysicalContext`).
  final String? physicalContext;

  /// Upper critical trip threshold (°C).
  final double? upperCritical;

  /// Upper caution (warning) threshold (°C).
  final double? upperCaution;

  /// Lower critical trip threshold (°C).
  final double? lowerCritical;

  /// Lower caution (warning) threshold (°C).
  final double? lowerCaution;

  /// Canonical `@odata.id` of the source thermal resource.
  final String? sourceUri;

  /// Parses one entry of a `Thermal.Temperatures` array.
  factory ThermalReading.fromJson(
    Map<String, dynamic> json, {
    String? sourceUri,
  }) {
    return ThermalReading(
      name: _asString(json['Name']) ?? 'Temperature',
      readingCelsius: _toDouble(json['ReadingCelsius']),
      status: StatusInfo.fromJson(json['Status'] as Map<String, dynamic>?),
      physicalContext: _asString(json['PhysicalContext']),
      upperCritical: _toDouble(json['UpperThresholdCritical']),
      upperCaution: _toDouble(json['UpperThresholdNonCritical']),
      lowerCritical: _toDouble(json['LowerThresholdCritical']),
      lowerCaution: _toDouble(json['LowerThresholdNonCritical']),
      sourceUri: sourceUri ?? _asString(json['@odata.id']),
    );
  }
}

/// A single fan / airflow reading from a Redfish `Thermal` resource (issue #007).
class FanReading {
  /// Creates a [FanReading].
  const FanReading({
    required this.name,
    this.reading,
    this.status = const StatusInfo(),
    this.physicalContext,
    this.upperCritical,
    this.sourceUri,
  });

  /// Fan display name (Redfish `Name`).
  final String name;

  /// Current rotational speed, typically RPM (Redfish `Reading`).
  final double? reading;

  /// Health/state of the fan.
  final StatusInfo status;

  /// What the fan cools (Redfish `PhysicalContext`).
  final String? physicalContext;

  /// Upper critical speed threshold (same units as [reading]).
  final double? upperCritical;

  /// Canonical `@odata.id` of the source thermal resource.
  final String? sourceUri;

  /// Parses one entry of a `Thermal.Fans` array.
  factory FanReading.fromJson(
    Map<String, dynamic> json, {
    String? sourceUri,
  }) {
    return FanReading(
      name: _asString(json['Name']) ?? 'Fan',
      reading: _toDouble(json['Reading']),
      status: StatusInfo.fromJson(json['Status'] as Map<String, dynamic>?),
      physicalContext: _asString(json['PhysicalContext']),
      upperCritical: _toDouble(json['UpperThresholdCritical']),
      sourceUri: sourceUri ?? _asString(json['@odata.id']),
    );
  }
}

/// A single generic sensor from a Redfish `Sensor` resource (issue #007).
class SensorReading {
  /// Creates a [SensorReading].
  const SensorReading({
    required this.name,
    this.readingType,
    this.readingUnits,
    this.reading,
    this.status = const StatusInfo(),
    this.thresholds = const <String, double>{},
    this.sourceUri,
  });

  /// Sensor display name (Redfish `Name`).
  final String name;

  /// Kind of quantity measured (Redfish `ReadingType`: `Temperature`, `Fan`,
  /// `Voltage`, `Current`, `Power`, `Percent`, …).
  final String? readingType;

  /// Unit of [reading] (Redfish `ReadingUnits`: `C`, `%`, `W`, `A`, `RPM`, …).
  final String? readingUnits;

  /// Current numeric reading.
  final double? reading;

  /// Health/state of the sensor.
  final StatusInfo status;

  /// Threshold map keyed by level (`UpperCritical`, `UpperCaution`,
  /// `LowerCritical`, `LowerCaution`) with the trip reading as the value.
  final Map<String, double> thresholds;

  /// Canonical `@odata.id` of the sensor resource.
  final String? sourceUri;

  /// Parses a `Sensor` resource body.
  factory SensorReading.fromJson(
    Map<String, dynamic> json, {
    String? sourceUri,
  }) {
    final Map<String, double> thresholds = <String, double>{};
    final dynamic rawThresholds = json['Thresholds'];
    if (rawThresholds is Map<dynamic, dynamic>) {
      for (final MapEntry<dynamic, dynamic> entry in rawThresholds.entries) {
        final String level = entry.key.toString();
        final double? value = _toDouble(
          entry.value is Map<dynamic, dynamic>
              ? (entry.value as Map<dynamic, dynamic>)['Reading']
              : null,
        );
        if (value != null) thresholds[level] = value;
      }
    }
    return SensorReading(
      name: _asString(json['Name']) ?? 'Sensor',
      readingType: _asString(json['ReadingType']),
      readingUnits: _asString(json['ReadingUnits']),
      reading: _toDouble(json['Reading']),
      status: StatusInfo.fromJson(json['Status'] as Map<String, dynamic>?),
      thresholds: thresholds,
      sourceUri: sourceUri ?? _asString(json['@odata.id']),
    );
  }
}

/// Aggregated sensor telemetry for one chassis (issue #007).
///
/// Built from the chassis `Thermal` resource (temperatures + fans) and the
/// `Sensors` collection (arbitrary typed sensors). Every list is nullable-safe
/// and defaults to empty so a partial fetch still yields a usable snapshot.
class ChassisSensors {
  /// Creates a [ChassisSensors].
  const ChassisSensors({
    required this.chassisId,
    this.chassisName,
    this.thermal = const <ThermalReading>[],
    this.fans = const <FanReading>[],
    this.sensors = const <SensorReading>[],
  });

  /// Chassis id (e.g. `1U`) — the segment of its `@odata.id`.
  final String chassisId;

  /// Chassis display name (Redfish `Chassis.Name`), when resolvable.
  final String? chassisName;

  /// Temperature readings from the `Thermal` resource.
  final List<ThermalReading> thermal;

  /// Fan readings from the `Thermal` resource.
  final List<FanReading> fans;

  /// Generic sensor readings from the `Sensors` collection.
  final List<SensorReading> sensors;

  /// Builds a [ChassisSensors] from a `Thermal` resource body.
  ///
  /// [chassisName] and [sensors] are optional and merged in so callers can
  /// assemble the full picture in steps (e.g. the unit tests).
  factory ChassisSensors.fromThermalJson(
    String chassisId,
    Map<String, dynamic> json, {
    String? chassisName,
    List<SensorReading>? sensors,
  }) {
    final String base = _asString(json['@odata.id']) ??
        '/redfish/v1/Chassis/$chassisId/Thermal';
    final List<dynamic> temps = json['Temperatures'] is List<dynamic>
        ? json['Temperatures'] as List<dynamic>
        : const <dynamic>[];
    final List<dynamic> fans = json['Fans'] is List<dynamic>
        ? json['Fans'] as List<dynamic>
        : const <dynamic>[];
    return ChassisSensors(
      chassisId: chassisId,
      chassisName: chassisName,
      thermal: temps
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> e) =>
              ThermalReading.fromJson(e, sourceUri: base))
          .toList(),
      fans: fans
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> e) =>
              FanReading.fromJson(e, sourceUri: base))
          .toList(),
      sensors: sensors ?? const <SensorReading>[],
    );
  }

  /// Builds a [ChassisSensors] from a `Thermal` body plus an already-fetched
  /// [sensors] list (used by the service which resolves both in one pass).
  factory ChassisSensors.merge({
    required String chassisId,
    String? chassisName,
    required Map<String, dynamic> thermalJson,
    required List<SensorReading> sensors,
  }) =>
      ChassisSensors.fromThermalJson(
        chassisId,
        thermalJson,
        chassisName: chassisName,
        sensors: sensors,
      );

  @override
  String toString() => 'ChassisSensors($chassisId: ${thermal.length} temps, '
      '${fans.length} fans, ${sensors.length} sensors)';
}

/// Returns [value] as a [String] or `null` when it is not a string.
String? _asString(Object? value) => value is String ? value : null;

/// Coerces a numeric [value] (int/double) to [double], or `null`.
double? _toDouble(Object? value) => value is num ? value.toDouble() : null;
