import 'package:redfishopenbmc/features/sensors/models/sensor_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Sensor telemetry service (issue #007).
///
/// Pulls chassis thermal and sensor data from a connected BMC:
///   * `GET /redfish/v1/Chassis` enumerates chassis,
///   * for each chassis `GET {id}/Thermal` yields temperatures + fans,
///   * for each chassis `GET {id}/Sensors` (a collection) yields the typed
///     sensor members, each fetched individually.
///
/// Missing `Thermal`/`Sensors` sub-resources (404 or empty) are tolerated
/// gracefully — the chassis is returned with whatever data was available rather
/// than failing the whole poll. A `null` client surfaces a friendly
/// [RedfishException] (mirrors [PowerService] not-connected behavior).
class SensorsService {
  /// Creates a [SensorsService] bound to an authenticated [RedfishClient] for
  /// the system identified by [systemId].
  ///
  /// [client] may be `null` for a not-yet-connected system; calls then surface a
  /// friendly [RedfishException] rather than throwing on a `null` receiver.
  /// [features] is the discovered capability map (kept for symmetry with the
  /// other feature services and future gating).
  SensorsService({
    required this.client,
    required this.systemId,
    this.features,
  });

  /// Authenticated Redfish client, or `null` when not connected.
  final RedfishClient? client;

  /// The connection profile id (used only for error messages).
  final String systemId;

  /// Discovered capability map for the system.
  final SystemFeatures? features;

  /// Fetches sensor telemetry for every chassis in the system.
  ///
  /// Throws [RedfishException] when not connected or when the `Chassis`
  /// collection itself is unreachable. Individual chassis/resource failures are
  /// tolerated (the affected chassis is skipped), so a single bad chassis never
  /// blanks the whole screen.
  Future<List<ChassisSensors>> fetchAll() async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; connect before reading sensors.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }

    final Map<String, dynamic> root = await c.getJson('/redfish/v1/Chassis');
    final List<dynamic> members =
        (root['Members'] as List<dynamic>?) ?? <dynamic>[];

    final List<ChassisSensors> out = <ChassisSensors>[];
    for (final dynamic member in members) {
      final String? uri = _memberId(member);
      if (uri == null || uri.isEmpty) continue;
      try {
        out.add(await fetchChassis(uri));
      } on RedfishException {
        // Skip a chassis that fails entirely; keep the rest.
      }
    }
    return out;
  }

  /// Fetches sensor telemetry for a single chassis.
  ///
  /// [chassisIdOrUri] may be a bare id (`1U`) or a full `@odata.id`
  /// (`/redfish/v1/Chassis/1U`). Missing `Thermal`/`Sensors` sub-resources are
  /// tolerated; the returned [ChassisSensors] simply has empty lists for the
  /// parts that were absent.
  Future<ChassisSensors> fetchChassis(String chassisIdOrUri) async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; cannot read chassis sensors.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }

    final String base = _chassisBase(chassisIdOrUri);
    final String id = _chassisId(base);

    String? name = id;
    try {
      final Map<String, dynamic> chassisJson = await c.getJson(base);
      name = _asString(chassisJson['Name']) ?? id;
    } on RedfishException {
      // Keep the id-derived name when the chassis body is unavailable.
    }

    List<ThermalReading> temps = const <ThermalReading>[];
    List<FanReading> fans = const <FanReading>[];
    try {
      final Map<String, dynamic> thermalJson =
          await c.getJson('$base/Thermal');
      temps = _parseThermal(thermalJson, '$base/Thermal');
      fans = _parseFans(thermalJson, '$base/Thermal');
    } on RedfishException {
      // No thermal telemetry for this chassis.
    }

    List<SensorReading> sensors = const <SensorReading>[];
    try {
      final Map<String, dynamic> sensorColl =
          await c.getJson('$base/Sensors');
      sensors = await _parseSensors(c, sensorColl);
    } on RedfishException {
      // No sensor collection for this chassis.
    }

    return ChassisSensors(
      chassisId: id,
      chassisName: name,
      thermal: temps,
      fans: fans,
      sensors: sensors,
    );
  }

  /// Parses a `Thermal` resource body into temperature readings.
  List<ThermalReading> _parseThermal(
    Map<String, dynamic> json,
    String sourceUri,
  ) {
    final List<dynamic> temps =
        (json['Temperatures'] as List<dynamic>?) ?? <dynamic>[];
    return temps.whereType<Map<String, dynamic>>().map(
      (Map<String, dynamic> e) => ThermalReading.fromJson(e, sourceUri: sourceUri),
    ).toList();
  }

  /// Parses a `Thermal` resource body into fan readings.
  List<FanReading> _parseFans(Map<String, dynamic> json, String sourceUri) {
    final List<dynamic> fans =
        (json['Fans'] as List<dynamic>?) ?? <dynamic>[];
    return fans.whereType<Map<String, dynamic>>().map(
      (Map<String, dynamic> e) => FanReading.fromJson(e, sourceUri: sourceUri),
    ).toList();
  }

  /// Fetches and parses every member of a `Sensors` collection.
  ///
  /// Individual sensor fetch failures are tolerated (the sensor is skipped).
  Future<List<SensorReading>> _parseSensors(
    RedfishClient client,
    Map<String, dynamic> collection,
  ) async {
    final List<dynamic> members =
        (collection['Members'] as List<dynamic>?) ?? <dynamic>[];
    final List<SensorReading> out = <SensorReading>[];
    for (final dynamic member in members) {
      final String? uri = _memberId(member);
      if (uri == null || uri.isEmpty) continue;
      try {
        final Map<String, dynamic> body = await client.getJson(uri);
        out.add(SensorReading.fromJson(body, sourceUri: uri));
      } on RedfishException {
        // Skip sensors that fail to load.
      }
    }
    return out;
  }

  /// Normalizes a chassis id or `@odata.id` to the resource base path.
  String _chassisBase(String chassisIdOrUri) {
    final String v = chassisIdOrUri.trim();
    if (v.startsWith('/redfish/v1')) {
      return v.endsWith('/') ? v.substring(0, v.length - 1) : v;
    }
    final String id = v.startsWith('/') ? v.substring(1) : v;
    return '/redfish/v1/Chassis/$id';
  }

  /// Extracts the trailing chassis id from a base path.
  String _chassisId(String base) {
    final String withoutTrailing =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final int slash = withoutTrailing.lastIndexOf('/');
    return slash >= 0 ? withoutTrailing.substring(slash + 1) : withoutTrailing;
  }

  /// Resolves a collection member's `@odata.id` (or treats a bare string as a
  /// URI directly).
  String? _memberId(dynamic member) {
    if (member is Map<dynamic, dynamic>) {
      final dynamic id = member['@odata.id'];
      return id is String ? id : null;
    }
    if (member is String) return member;
    return null;
  }
}

/// Returns [value] as a [String] or `null` when it is not a string.
String? _asString(Object? value) => value is String ? value : null;
