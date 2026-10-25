/// A Redfish `Control` resource (`#Control.v1_5_0.Control`).
///
/// The modern chassis control surface the DMTF mockup serves under
/// `Chassis/*/Controls` — a power-limit SetPoint (PowerLimit) or a
/// frequency control (CPU1Freq). Mirrors the fields a control surface
/// consumes: the current `SetPoint`, its units, the `AllowableMin` /
/// `AllowableMax` bounds the client MUST pre-validate a PATCH against, and
/// the optional `Sensor` excerpt linking real telemetry.
///
/// Reference: `Control.v1_5_0.json` (mirrored as DOCS-26) —
/// * `SetPoint` — "If the DefaultSetPoint property is not supported and if a
///   user-defined set point is not configured, the property may contain
///   `null` in responses."
/// * `AllowableMax` — "Services shall not accept values for SetPoint ...
///   above this value."
/// * `AllowableMin` — "Services shall not accept values for SetPoint ...
///   below this value."
///
/// The pre-validation rule ([validateSetPoint]) exists because the DMTF
/// mockup and bmcweb apply a PATCH body value unvalidated: the emulator
/// proves `SetPoint: 9999` answers 204 AND persists (EMU 60→63 pin), so a
/// mutation flow MUST reject out-of-bounds SetPoints client-side before
/// sending (issue #022/#016; DSP0266 §9.6.14 / `Control.v1_5_0.json`).
class ControlResource {
  /// Creates a parsed [ControlResource].
  const ControlResource({
    required this.id,
    this.controlType,
    this.controlMode,
    this.setPoint,
    this.setPointUnits,
    this.allowableMin,
    this.allowableMax,
    this.sensorDataSourceUri,
  });

  /// Parses a `Control` resource body, tolerating missing/unknown fields.
  factory ControlResource.fromJson(Map<String, dynamic> json) {
    final Map<dynamic, dynamic>? sensor =
        json['Sensor'] is Map ? json['Sensor'] as Map<dynamic, dynamic> : null;
    return ControlResource(
      id: json['Id'] is String ? json['Id'] as String : '',
      controlType: _asString(json['ControlType']),
      controlMode: _asString(json['ControlMode']),
      setPoint: _asNum(json['SetPoint']),
      setPointUnits: _asString(json['SetPointUnits']),
      allowableMin: _asNum(json['AllowableMin']),
      allowableMax: _asNum(json['AllowableMax']),
      sensorDataSourceUri: sensor == null
          ? null
          : (sensor['DataSourceUri'] is String
              ? sensor['DataSourceUri'] as String
              : null),
    );
  }

  /// Resource `Id` (e.g. `PowerLimit`).
  final String id;

  /// `ControlType` — `Power`, `Frequency`, etc. (`null` when absent).
  final String? controlType;

  /// `ControlMode` — `Automatic`, `Manual`, etc. (`null` when absent).
  final String? controlMode;

  /// Current `SetPoint` (`null` when the service reports none — the schema
  /// explicitly allows a null SetPoint when no user-defined point is set).
  final num? setPoint;

  /// `SetPointUnits` (e.g. `W`, `Hz`).
  final String? setPointUnits;

  /// `AllowableMin` — the minimum SetPoint the service accepts.
  final num? allowableMin;

  /// `AllowableMax` — the maximum SetPoint the service accepts.
  final num? allowableMax;

  /// `Sensor.DataSourceUri` — link to the telemetry sensor behind this
  /// control (e.g. `Sensors/TotalPower`).
  final String? sensorDataSourceUri;

  /// Whether the resource advertises an enforceable [allowableMin]/
  /// [allowableMax] pair.
  bool get hasAllowableBounds => allowableMin != null && allowableMax != null;

  /// Pre-validates a prospective [value] for a `SetPoint` PATCH against the
  /// advertised [allowableMin]/[allowableMax] bounds.
  ///
  /// Returns a [SetPointValidation]: invalid when [value] is null or outside
  /// the advertised range; valid (with an informational message) when no
  /// bounds are advertised and the client can only do a best-effort PATCH.
  SetPointValidation validateSetPoint(num? value) {
    if (value == null) {
      return const SetPointValidation.invalid(
        'A SetPoint value is required.',
      );
    }
    final num? min = allowableMin;
    final num? max = allowableMax;
    if (min == null || max == null) {
      return const SetPointValidation.valid(
        'No AllowableMin/Max advertised — the SetPoint cannot be '
        'pre-validated against bounds.',
      );
    }
    if (value < min || value > max) {
      return SetPointValidation.invalid(
        'SetPoint $value is outside the advertised Allowable range '
        '[$min, $max].',
      );
    }
    return const SetPointValidation.valid();
  }

  static String? _asString(dynamic value) => value is String ? value : null;

  static num? _asNum(dynamic value) =>
      value is num ? value : (value is String ? num.tryParse(value) : null);
}

/// Result of a [ControlResource.validateSetPoint] check.
class SetPointValidation {
  /// A valid SetPoint (in range, or no bounds to check against).
  const SetPointValidation.valid([this.message]) : valid = true;

  /// An invalid SetPoint for a [reason].
  const SetPointValidation.invalid(this.message) : valid = false;

  /// Whether the SetPoint may be PATCHed.
  final bool valid;

  /// `null` for a plain in-range value; otherwise the reason (out-of-range
  /// message, or the informational no-bounds notice).
  final String? message;
}
