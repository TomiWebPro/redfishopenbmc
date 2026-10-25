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
    this.actionInfos = const <String, dynamic>{},
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

  /// Every `@Redfish.ActionInfo` resource (URI → body) discovered during the
  /// crawl, keyed by its relative path. ActionInfo resources document the
  /// parameters of an action (`Parameters[].AllowableValues`) — the bmcweb
  /// `ResetActionInfo`-style allow-list source (#022/#016; DOCS-4/13). Empty
  /// when the service advertises no ActionInfo links.
  final Map<String, dynamic> actionInfos;

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
  static bool powerControl(List<Map<String, dynamic>> systems) => systems.any(
        (Map<String, dynamic> s) =>
            ODataResource(s).actionTarget(computerSystemReset) != null,
      );

  /// Union of every reset-type value across all systems.
  ///
  /// Reads all documented allow-list sources, so the list is surfaced even on
  /// BMCs that omit `SupportedResetTypes`:
  ///  1. `SupportedResetTypes` (DSP0266 `ComputerSystem.json`);
  ///  2. the `ResetType@Redfish.AllowableValues` annotation on the
  ///     `#ComputerSystem.Reset` action (the form the DMTF mockup and
  ///     bmcweb-style ActionInfo BMCs publish — DOCS-4/13, #022/#016);
  ///  3. the bmcweb-style `@Redfish.ActionInfo` *resource* the action links
  ///     to (`Parameters[].AllowableValues` on the `ResetType` parameter) —
  ///     [actionInfos] keys are the ActionInfo relative paths, the exact map
  ///     the discovery engine captures (EMU 71→78 pinned the resource shape
  ///     live; #022/#016).
  ///
  /// The annotation and ActionInfo resource are read **only from
  /// ComputerSystem payloads** (`systems`) and only the ActionInfo resources
  /// the system's own `#ComputerSystem.Reset` action links to — never from
  /// Manager payloads — the system-level allow-list includes `Nmi` /
  /// `ForceOn` / `PushPowerButton` and must not be conflated with the
  /// manager-level `#Manager.Reset` list (`ForceRestart`/`GracefulRestart`),
  /// per the emulator-pinned contract.
  static List<String> supportedResetTypes(
    List<Map<String, dynamic>> systems, {
    Map<String, dynamic> actionInfos = const <String, dynamic>{},
  }) {
    final Set<String> types = <String>{};
    for (final Map<String, dynamic> s in systems) {
      final dynamic raw = s['SupportedResetTypes'];
      if (raw is List<dynamic>) {
        for (final dynamic e in raw) {
          types.add(e.toString());
        }
      }
      final List<String> annotated = resetTypesFromAction(s);
      types.addAll(annotated);
      final List<String> fromInfo = resetTypesFromActionInfo(s, actionInfos);
      types.addAll(fromInfo);
    }
    return types.toList()..sort();
  }

  /// Extracts the `ResetType` allow-list from the `@Redfish.ActionInfo`
  /// resource [system]'s `#ComputerSystem.Reset` action links to, or an empty
  /// list when the link or resource is absent.
  ///
  /// bmcweb (OpenBMC) publishes the reset allow-list as a `ResetActionInfo`
  /// ActionInfo resource whose `Parameters[]` contains a `ResetType` entry
  /// with `AllowableValues` (DOCS-4/13); it serves no system-level
  /// `SupportedResetTypes` and no annotation on the action. Following the
  /// action's `@Redfish.ActionInfo` link and reading that parameter is the
  /// #022/#016 "crawl the ActionInfo *resource*" step (EMU 71→78 pinned the
  /// `Parameters[].AllowableValues` shape live on CertificateService/
  /// EventService/UpdateService ActionInfo resources).
  static List<String> resetTypesFromActionInfo(
    Map<String, dynamic> system,
    Map<String, dynamic> actionInfos,
  ) {
    final dynamic action = ODataResource(system).actions[computerSystemReset];
    if (action is! Map<dynamic, dynamic>) return const <String>[];
    final dynamic infoUri = action['@Redfish.ActionInfo'];
    if (infoUri is! String) return const <String>[];
    final dynamic info = actionInfos[infoUri];
    if (info is! Map<String, dynamic> && info is! Map<dynamic, dynamic>) {
      return const <String>[];
    }
    final Map<String, dynamic> infoMap = info is Map<String, dynamic>
        ? info
        : Map<String, dynamic>.fromEntries(
            (info as Map<dynamic, dynamic>).entries.map(
                  (MapEntry<dynamic, dynamic> e) =>
                      MapEntry<String, dynamic>(e.key.toString(), e.value),
                ),
          );
    return allowableValuesFromActionInfo(infoMap, 'ResetType');
  }

  /// Returns the `AllowableValues` of the [parameterName] entry in an
  /// ActionInfo resource's `Parameters[]`, or an empty list when absent.
  ///
  /// Shape per DSP0266 §9.6.14 / `ActionInfo.v1_4_1` (pinned live EMU 71→78):
  /// `Parameters[].{Name, Required, DataType, AllowableValues?}`.
  static List<String> allowableValuesFromActionInfo(
    Map<String, dynamic> actionInfo,
    String parameterName,
  ) {
    final dynamic raw = actionInfo['Parameters'];
    if (raw is! List<dynamic>) return const <String>[];
    for (final dynamic p in raw) {
      if (p is Map<String, dynamic> && p['Name'] == parameterName) {
        final dynamic allowed = p['AllowableValues'];
        if (allowed is List<dynamic>) {
          return allowed.map((dynamic e) => e.toString()).toList();
        }
        return const <String>[];
      }
    }
    return const <String>[];
  }

  /// Extracts the `ResetType@Redfish.AllowableValues` annotation from a
  /// system's `#ComputerSystem.Reset` action, or an empty list when absent.
  ///
  /// The OData annotation (per DSP0266 §9.9 "Payload annotations",
  /// §9.9.2 "Allowable values for strings" — annotation names follow
  /// `PropertyName`@`Namespace`.`TermName`, where `Redfish` is the
  /// `RedfishExtensions.v1_0_0` namespace alias) enumerates
  /// exactly the `ResetType` values the BMC accepts for that action. bmcweb
  /// documents its allow-list as a `ResetActionInfo` ActionInfo resource
  /// (`Parameters/AllowableValues`) and serves no system-level
  /// `SupportedResetTypes`; the mockup publishes the annotation directly on
  /// the action. Both are captured by this fallback.
  static List<String> resetTypesFromAction(Map<String, dynamic> system) {
    final dynamic action = ODataResource(system).actions[computerSystemReset];
    if (action is! Map<dynamic, dynamic>) return const <String>[];
    final dynamic allowed = action['ResetType@Redfish.AllowableValues'];
    if (allowed is! List<dynamic>) return const <String>[];
    return allowed.map((dynamic e) => e.toString()).toList();
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
      } else if (s.containsKey('Reading') || s.containsKey('ReadingRangeMax')) {
        total += 1;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Rule: firmware_update
  //   firmware_update = UpdateService link present
  //                     && ServiceEnabled != false (explicitly disabled)
  // ---------------------------------------------------------------------------

  /// True when an UpdateService resource was discovered and not explicitly
  /// disabled.
  ///
  /// Per the DMTF `UpdateService` schema, `ServiceEnabled` "shall indicate
  /// whether this service is enabled", and OpenBMC bmcweb advertises
  /// `ServiceEnabled` on its UpdateService (`Redfish.md` §UpdateService). A
  /// missing or `null` flag is treated as enabled (capability present) so
  /// conformant services that omit the flag still surface the feature; an
  /// explicit `false` gates the feature off (DOCS-5, 2026-10-22).
  static bool firmwareUpdate(Map<String, dynamic>? updateService) {
    if (updateService == null) return false;
    return updateService['ServiceEnabled'] != false;
  }

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
      supportedResetTypes:
          supportedResetTypes(ctx.systems, actionInfos: ctx.actionInfos),
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
  ///
  /// The `Oem` fallback is deliberate but strict: it only fires when the OEM
  /// block actually contains a console-like structure (`GraphicalConsole`,
  /// `SerialConsole`, or a `Kvm`/`Console` marker). OpenBMC bmcweb Managers
  /// always carry an `Oem` block for vendor metadata (see `Redfish.md` Manager
  /// field list), so a bare `Oem` map must **not** be treated as a console —
  /// otherwise KVM would report available on every OpenBMC system (DOCS-4,
  /// 2026-10-22).
  static String? _managerConsoleType(Map<String, dynamic> manager) {
    final dynamic graphical = manager['GraphicalConsole'];
    if (graphical is Map<dynamic, dynamic> && _consoleEnabled(graphical)) {
      return 'GraphicalConsole';
    }
    final dynamic serial = manager['SerialConsole'];
    if (serial is Map<dynamic, dynamic> && _consoleEnabled(serial)) {
      return 'SerialConsole';
    }
    if (FeatureRules.oemHasConsole(manager['Oem'])) return 'Oem';
    return null;
  }

  /// True when an `Oem` block advertises a console rather than mere vendor
  /// metadata. Recurses a bounded depth looking for console-like keys
  /// (`console`, `kvm`) — the shape used by vendor OEM consoles.
  ///
  /// Public so feature parsers (e.g. `KvmConsole.fromManager`) share the same
  /// strict contract instead of treating any `Oem` map as a console (DOCS-4).
  static bool oemHasConsole(dynamic oem) {
    return _oemHasConsoleAt(oem, 0);
  }

  static bool _oemHasConsoleAt(dynamic oem, int depth) {
    if (depth > 3 || oem is! Map<dynamic, dynamic>) return false;
    for (final dynamic key in oem.keys) {
      final String k = key.toString().toLowerCase();
      if (k.contains('console') || k.contains('kvm')) return true;
    }
    for (final dynamic value in oem.values) {
      if (_oemHasConsoleAt(value, depth + 1)) return true;
    }
    return false;
  }

  /// True when a console block reports itself as enabled, checking both the
  /// schema-correct `ServiceEnabled` and the legacy `Enabled` fields.
  static bool _consoleEnabled(dynamic console) {
    if (console is! Map<dynamic, dynamic>) return false;
    return console['ServiceEnabled'] == true || console['Enabled'] == true;
  }
}
