import 'package:redfishopenbmc/redfish/models/odata.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// The raw material produced by a single discovery pass, grouped by resource
/// kind. The [FeatureRules] turn this into a [SystemFeatures] map.
///
/// Everything here is the verbatim (or near-verbatim) Redfish payload; no
/// feature judgement has been applied yet. Keeping it separate from
/// [SystemFeatures] makes the normalization rules unit-testable in isolation.
class DiscoveryContext {
  /// Creates a [DiscoveryContext].
  const DiscoveryContext({
    required this.serviceRoot,
    this.systems = const <Map<String, dynamic>>[],
    this.managers = const <Map<String, dynamic>>[],
    this.chassis = const <Map<String, dynamic>>[],
    this.thermals = const <Map<String, dynamic>>[],
    this.sensors = const <Map<String, dynamic>>[],
    this.updateService,
    this.sessionService,
    this.rawTree = const <String, dynamic>{},
  });

  /// The ServiceRoot payload (`/redfish/v1/`).
  final Map<String, dynamic> serviceRoot;

  /// ComputerSystem member resources.
  final List<Map<String, dynamic>> systems;

  /// Manager member resources.
  final List<Map<String, dynamic>> managers;

  /// Chassis member resources.
  final List<Map<String, dynamic>> chassis;

  /// Thermal sub-resources discovered under chassis.
  final List<Map<String, dynamic>> thermals;

  /// Sensor collection / sensor resources discovered under chassis.
  final List<Map<String, dynamic>> sensors;

  /// The UpdateService resource, or `null` if the BMC exposes none.
  final Map<String, dynamic>? updateService;

  /// The SessionService resource, or `null` if the BMC exposes none.
  final Map<String, dynamic>? sessionService;

  /// Every URI → body fetched during the crawl (the raw explorer tree).
  final Map<String, dynamic> rawTree;
}

/// Table-driven normalization from a [DiscoveryContext] to a [SystemFeatures].
///
/// Each `static` detector encodes exactly one normalization rule (documented
/// inline), so the "capability map" contract is auditable rule-by-rule. The
/// [build] method composes them. This is the single source of truth for which
/// Redfish signals map to which UI features.
class FeatureRules {
  /// Private constructor — this class is a namespace of pure functions.
  const FeatureRules._();

  /// Action name for power/reset control on a ComputerSystem.
  static const String computerSystemReset = '#ComputerSystem.Reset';

  /// Action name for power/reset control on a Manager.
  static const String managerReset = '#Manager.Reset';

  /// Action name for firmware upload on UpdateService.
  static const String simpleUpdate = '#UpdateService.SimpleUpdate';

  // ---------------------------------------------------------------------------
  // Rule: power_control
  //   power_control = Systems[*].Actions.#ComputerSystem.Reset != null
  // ---------------------------------------------------------------------------

  /// True when any computer system exposes the `#ComputerSystem.Reset` action.
  static bool powerControl(List<Map<String, dynamic>> systems) =>
      systems.any(
        (Map<String, dynamic> s) =>
            ODataResource(s).actionTarget(computerSystemReset) != null,
      );

  /// Union of every `SupportedResetTypes` value across all systems.
  static List<String> supportedResetTypes(
    List<Map<String, dynamic>> systems,
  ) {
    final Set<String> types = <String>{};
    for (final Map<String, dynamic> s in systems) {
      final dynamic raw = s['SupportedResetTypes'];
      if (raw is List<dynamic>) {
        for (final dynamic e in raw) {
          types.add(e.toString());
        }
      }
    }
    return types.toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // Rule: kvm
  //   kvm = Managers[*].(GraphicalConsole.Enabled || SerialConsole.Enabled
  //                       || Oem console)
  // ---------------------------------------------------------------------------

  /// True when any manager exposes an enabled graphical / serial / OEM console.
  static bool kvm(List<Map<String, dynamic>> managers) => managers.any(
        (Map<String, dynamic> m) => _managerConsoleType(m) != null,
      );

  /// The first detected console type (`GraphicalConsole`, `SerialConsole`,
  /// `Oem`), or `null` when no console is enabled.
  static String? kvmType(List<Map<String, dynamic>> managers) {
    for (final Map<String, dynamic> m in managers) {
      final String? type = _managerConsoleType(m);
      if (type != null) return type;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Rule: sensor_monitoring
  //   sensor_monitoring = Chassis[*].(Thermal || Sensors || Power) present
  // ---------------------------------------------------------------------------

  /// True when any chassis advertises a `Thermal`, `Sensors`, or `Power`
  /// sub-resource (proof of sensor telemetry).
  static bool sensorMonitoring(List<Map<String, dynamic>> chassis) =>
      chassis.any(
        (Map<String, dynamic> c) =>
            c.containsKey('Thermal') ||
            c.containsKey('Sensors') ||
            c.containsKey('Power'),
      );

  /// Approximate total readable sensor count: temperatures + fans + voltages
  /// across thermals, plus sensor members / standalone sensors.
  static int sensorCount(
    List<Map<String, dynamic>> thermals,
    List<Map<String, dynamic>> sensors,
  ) {
    var total = 0;
    for (final Map<String, dynamic> t in thermals) {
      final dynamic temps = t['Temperatures'];
      final dynamic fans = t['Fans'];
      final dynamic volts = t['Voltages'];
      if (temps is List<dynamic>) total += temps.length;
      if (fans is List<dynamic>) total += fans.length;
      if (volts is List<dynamic>) total += volts.length;
    }
    for (final Map<String, dynamic> s in sensors) {
      final dynamic members = s['Members'];
      if (members is List<dynamic>) {
        total += members.length;
      } else if (s.containsKey('Reading') ||
          s.containsKey('ReadingRangeMax')) {
        total += 1;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Rule: firmware_update
  //   firmware_update = UpdateService link present
  // ---------------------------------------------------------------------------

  /// True when an UpdateService resource was discovered.
  static bool firmwareUpdate(Map<String, dynamic>? updateService) =>
      updateService != null;

  /// The firmware / UpdateService version string, preferring `FirmwareVersion`
  /// then `Id`.
  static String? updateServiceVersion(Map<String, dynamic>? updateService) {
    if (updateService == null) return null;
    final dynamic version = updateService['FirmwareVersion'];
    if (version is String) return version;
    final dynamic id = updateService['Id'];
    return id is String ? id : null;
  }

  /// Composes a [SystemFeatures] for [systemId] from the raw [ctx].
  ///
  /// This is the single composition point: every rule above is invoked here so
  /// the UI contract is generated deterministically and testably.
  static SystemFeatures build(String systemId, DiscoveryContext ctx) {
    return SystemFeatures(
      systemId: systemId,
      powerControl: powerControl(ctx.systems),
      supportedResetTypes: supportedResetTypes(ctx.systems),
      kvm: kvm(ctx.managers),
      kvmType: kvmType(ctx.managers),
      sensorMonitoring: sensorMonitoring(ctx.chassis),
      sensorCount: sensorCount(ctx.thermals, ctx.sensors),
      firmwareUpdate: firmwareUpdate(ctx.updateService),
      updateServiceVersion: updateServiceVersion(ctx.updateService),
      managers: ctx.managers.length,
      chassis: ctx.chassis.length,
      raw: ctx.rawTree,
    );
  }

  /// Returns the enabled console type for a manager, or `null`.
  ///
  /// Honors the real Redfish schema field `ServiceEnabled` (used by the DMTF
  /// mockup and shipping BMCs) and falls back to the older `Enabled` key for
  /// backwards compatibility.
  static String? _managerConsoleType(Map<String, dynamic> manager) {
    final dynamic graphical = manager['GraphicalConsole'];
    if (graphical is Map<dynamic, dynamic> &&
        _consoleEnabled(graphical)) {
      return 'GraphicalConsole';
    }
    final dynamic serial = manager['SerialConsole'];
    if (serial is Map<dynamic, dynamic> && _consoleEnabled(serial)) {
      return 'SerialConsole';
    }
    if (manager['Oem'] is Map<dynamic, dynamic>) return 'Oem';
    return null;
  }

  /// True when a console block reports itself as enabled, checking both the
  /// schema-correct `ServiceEnabled` and the legacy `Enabled` fields.
  static bool _consoleEnabled(dynamic console) {
    if (console is! Map<dynamic, dynamic>) return false;
    return console['ServiceEnabled'] == true || console['Enabled'] == true;
  }
}
