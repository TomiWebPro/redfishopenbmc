import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';

/// Discrete indicator LED states reported by a Redfish ComputerSystem.
enum IndicatorLed {
  /// The LED is lit (illuminated).
  lit,

  /// The LED is off.
  off,

  /// The LED is blinking.
  blinking,

  /// The LED state could not be determined.
  unknown;

  /// Maps a Redfish `IndicatorLED` string to [IndicatorLed].
  static IndicatorLed fromRedfish(String? value) {
    switch (value?.toLowerCase()) {
      case 'lit':
        return IndicatorLed.lit;
      case 'off':
        return IndicatorLed.off;
      case 'blinking':
        return IndicatorLed.blinking;
      default:
        return IndicatorLed.unknown;
    }
  }

  /// The Redfish `IndicatorLED` enum value this state maps to, or `null` for
  /// [IndicatorLed.unknown] (which is not a writable PATCH value — the schema
  /// marks `Unknown` deprecated in favor of a missing/`null` property).
  ///
  /// Per the served `ComputerSystem.v1_22_0` schema, the writable enum is
  /// `Lit` / `Blinking` / `Off` (#016 PATCH flow; the client pre-validates
  /// PATCH bodies against the schema enum before sending — the DMTF mockup
  /// applies ANY body unvalidated, so this guard is the only enforcement).
  String? get toRedfish {
    switch (this) {
      case IndicatorLed.lit:
        return 'Lit';
      case IndicatorLed.off:
        return 'Off';
      case IndicatorLed.blinking:
        return 'Blinking';
      case IndicatorLed.unknown:
        return null;
    }
  }

  /// The schema-valid writable values for a PATCH (`IndicatorLED` enum of
  /// `ComputerSystem.v1_22_0`, excluding the deprecated `Unknown`).
  static const List<String> writableValues = <String>['Lit', 'Blinking', 'Off'];

  /// Human-readable label.
  String get label {
    switch (this) {
      case IndicatorLed.lit:
        return 'Lit';
      case IndicatorLed.off:
        return 'Off';
      case IndicatorLed.blinking:
        return 'Blinking';
      case IndicatorLed.unknown:
        return 'Unknown';
    }
  }
}

/// Processor summary block of a ComputerSystem (`ProcessorSummary`).
///
/// Tolerant: any missing / mistyped field degrades to `null` rather than
/// throwing, so OpenBMC QEMU (which omits this block) yields an empty summary.
class ProcessorSummary {
  /// Creates a [ProcessorSummary].
  const ProcessorSummary({this.count, this.model});

  /// Number of processors, when reported.
  final int? count;

  /// Descriptive model of the processor(s), when reported.
  final String? model;

  /// Builds a [ProcessorSummary] from a Redfish `ProcessorSummary` object.
  factory ProcessorSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProcessorSummary();
    int? parsedCount;
    final dynamic count = json['Count'];
    if (count is int) {
      parsedCount = count;
    } else if (count is String) {
      parsedCount = int.tryParse(count);
    }
    return ProcessorSummary(
      count: parsedCount,
      model: json['Model'] as String?,
    );
  }
}

/// Memory summary block of a ComputerSystem (`MemorySummary`).
class MemorySummary {
  /// Creates a [MemorySummary].
  const MemorySummary({this.totalGiB});

  /// Total system memory in gibibytes, when reported.
  final double? totalGiB;

  /// Builds a [MemorySummary] from a Redfish `MemorySummary` object.
  factory MemorySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MemorySummary();
    final dynamic total = json['TotalSystemMemoryGiB'];
    if (total is num) return MemorySummary(totalGiB: total.toDouble());
    if (total is String) {
      final double? parsed = double.tryParse(total);
      if (parsed != null) return MemorySummary(totalGiB: parsed);
    }
    return const MemorySummary();
  }
}

/// Schema-driven, fully-nullable per-system overview.
///
/// Derived primarily from `GET /redfish/v1/Systems/{id}` plus an optional
/// leading chassis thermal reading. Every field is nullable and the
/// [fromRedfish] factory never throws on missing / mistyped data — OpenBMC
/// QEMU, which exposes almost nothing, yields an overview where every card is
/// either omitted or shows "Not exposed by this BMC".
class SystemOverview {
  /// Creates a [SystemOverview].
  const SystemOverview({
    this.manufacturer,
    this.model,
    this.sku,
    this.serialNumber,
    this.partNumber,
    this.biosVersion,
    this.powerState = PowerState.unknown,
    this.health = Health.unknown,
    this.healthRollup = Health.unknown,
    this.processorSummary = const ProcessorSummary(),
    this.memorySummary = const MemorySummary(),
    this.indicatorLed = IndicatorLed.unknown,
    this.leadingTemperatureCelsius,
    this.resourceUri,
    this.lastUpdated,
  });

  /// System manufacturer (`Manufacturer`).
  final String? manufacturer;

  /// System model (`Model`).
  final String? model;

  /// Stock-keeping unit (`SKU`).
  final String? sku;

  /// System serial number (`SerialNumber`).
  final String? serialNumber;

  /// Part number (`PartNumber`).
  final String? partNumber;

  /// BIOS / firmware version string (`BiosVersion`).
  final String? biosVersion;

  /// Current power state (`PowerState`).
  final PowerState powerState;

  /// Primary health (`Status.Health`, falling back to `Status.HealthRollup`).
  final Health health;

  /// Rollup health (`Status.HealthRollup`).
  final Health healthRollup;

  /// Processor summary (`ProcessorSummary`).
  final ProcessorSummary processorSummary;

  /// Memory summary (`MemorySummary`).
  final MemorySummary memorySummary;

  /// Indicator LED state (`IndicatorLED`).
  final IndicatorLed indicatorLed;

  /// Leading temperature in °C from the first chassis thermal reading, when a
  /// thermal resource is discoverable; `null` otherwise (card omitted).
  final double? leadingTemperatureCelsius;

  /// Canonical `@odata.id` of the ComputerSystem resource this overview came
  /// from (used to resolve action targets / re-fetches).
  final String? resourceUri;

  /// When this overview was captured.
  final DateTime? lastUpdated;

  /// Whether a temperature reading was successfully discovered.
  bool get hasTemperature => leadingTemperatureCelsius != null;

  /// Whether the (optional) processor summary is populated.
  bool get hasProcessors =>
      processorSummary.count != null || processorSummary.model != null;

  /// Whether the (optional) memory summary is populated.
  bool get hasMemory => memorySummary.totalGiB != null;

  /// Builds a [SystemOverview] from a Redfish ComputerSystem JSON body.
  ///
  /// [leadingTemperatureCelsius] and [resourceUri] are injected because they
  /// are sourced from companion resources (chassis thermal) or context rather
  /// than the system body itself.
  factory SystemOverview.fromRedfish(
    Map<String, dynamic> json, {
    double? leadingTemperatureCelsius,
    String? resourceUri,
  }) {
    final dynamic status = json['Status'];
    final Map<String, dynamic> statusMap =
        status is Map<String, dynamic> ? status : <String, dynamic>{};
    final Health raw = HealthX.fromStatus(statusMap['Health'] as String?);
    final Health rollup =
        HealthX.fromStatus(statusMap['HealthRollup'] as String?);
    // Primary health, falling back to the rollup, then to Unknown.
    final Health health = raw == Health.unknown ? rollup : raw;

    return SystemOverview(
      manufacturer: json['Manufacturer'] as String?,
      model: json['Model'] as String?,
      sku: json['SKU'] as String?,
      serialNumber: json['SerialNumber'] as String?,
      partNumber: json['PartNumber'] as String?,
      biosVersion: json['BiosVersion'] as String?,
      powerState: PowerStateX.fromRedfish(json['PowerState'] as String?),
      health: health,
      healthRollup: rollup,
      processorSummary: ProcessorSummary.fromJson(
        json['ProcessorSummary'] as Map<String, dynamic>?,
      ),
      memorySummary: MemorySummary.fromJson(
        json['MemorySummary'] as Map<String, dynamic>?,
      ),
      indicatorLed: IndicatorLed.fromRedfish(json['IndicatorLED'] as String?),
      leadingTemperatureCelsius: leadingTemperatureCelsius,
      resourceUri: resourceUri ?? json['@odata.id'] as String?,
      lastUpdated: DateTime.now(),
    );
  }

  /// Builds a [SystemOverview] from a ComputerSystem body plus an optional raw
  /// `Thermal` body, as produced by [OverviewService].
  ///
  /// [thermalJson] is the chassis thermal resource; its first `Temperatures`
  /// entry supplies the leading `ReadingCelsius` value (when present).
  factory SystemOverview.fromSystemJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? thermalJson,
    String? resourceUri,
  }) {
    double? temp;
    final List<dynamic>? temps = thermalJson?['Temperatures'] as List<dynamic>?;
    if (temps != null && temps.isNotEmpty) {
      final dynamic first = temps.first;
      if (first is Map<String, dynamic>) {
        final dynamic reading = first['ReadingCelsius'];
        if (reading is num) temp = reading.toDouble();
      }
    }
    return SystemOverview.fromRedfish(
      json,
      leadingTemperatureCelsius: temp,
      resourceUri: resourceUri,
    );
  }

  /// Returns a copy with the provided fields overridden.
  SystemOverview copyWith({
    String? manufacturer,
    String? model,
    String? sku,
    String? serialNumber,
    String? partNumber,
    String? biosVersion,
    PowerState? powerState,
    Health? health,
    Health? healthRollup,
    ProcessorSummary? processorSummary,
    MemorySummary? memorySummary,
    IndicatorLed? indicatorLed,
    double? leadingTemperatureCelsius,
    String? resourceUri,
    DateTime? lastUpdated,
  }) =>
      SystemOverview(
        manufacturer: manufacturer ?? this.manufacturer,
        model: model ?? this.model,
        sku: sku ?? this.sku,
        serialNumber: serialNumber ?? this.serialNumber,
        partNumber: partNumber ?? this.partNumber,
        biosVersion: biosVersion ?? this.biosVersion,
        powerState: powerState ?? this.powerState,
        health: health ?? this.health,
        healthRollup: healthRollup ?? this.healthRollup,
        processorSummary: processorSummary ?? this.processorSummary,
        memorySummary: memorySummary ?? this.memorySummary,
        indicatorLed: indicatorLed ?? this.indicatorLed,
        leadingTemperatureCelsius:
            leadingTemperatureCelsius ?? this.leadingTemperatureCelsius,
        resourceUri: resourceUri ?? this.resourceUri,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  /// Serializes the overview for caching / persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'manufacturer': manufacturer,
        'model': model,
        'sku': sku,
        'serial_number': serialNumber,
        'part_number': partNumber,
        'bios_version': biosVersion,
        'power_state': powerState.name,
        'health': health.name,
        'health_rollup': healthRollup.name,
        'processor_count': processorSummary.count,
        'processor_model': processorSummary.model,
        'memory_gib': memorySummary.totalGiB,
        'indicator_led': indicatorLed.name,
        'leading_temperature_celsius': leadingTemperatureCelsius,
        'resource_uri': resourceUri,
        'last_updated': lastUpdated?.toIso8601String(),
      };
}

/// Resolves the adaptive column count for the overview card grid (issue #006).
///
/// Breakpoints intentionally differ from the app-wide shell breakpoints:
/// mobile `< 600` → 1 column, tablet `≥ 600` → 2, desktop `≥ 1024` → 3.
int overviewColumnsForWidth(double width) {
  if (width >= 1024) return 3;
  if (width >= 600) return 2;
  return 1;
}
