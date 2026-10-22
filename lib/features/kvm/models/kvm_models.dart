/// Remote KVM / console models (issue #009).
///
/// Mirrors the Redfish `Manager` console services (`GraphicalConsole`,
/// `SerialConsole`, `RemoteConsole`). A BMC may expose several console types
/// at once; [KvmConsole.fromManager] extracts each into its own immutable
/// [KvmConsole] so the UI can list them uniformly.
library;

import 'package:redfishopenbmc/redfish/discovery/feature_rules.dart';

/// The kind of Redfish console a [KvmConsole] represents.
enum KvmConsoleType {
  /// A `GraphicalConsole` (KVM-over-IP / remote desktop style console).
  graphical,

  /// A `SerialConsole` (SSH / Telnet / IPMI serial-over-LAN).
  serial,

  /// A `RemoteConsole` (typically an HTML5 web console).
  remote,

  /// An OEM-specific console not covered by the standard Redfish types.
  oem;

  /// Maps a Redfish console block name (e.g. `'GraphicalConsole'`) to a
  /// [KvmConsoleType], or [KvmConsoleType.oem] when [value] is `null` or
  /// unrecognized.
  static KvmConsoleType fromRedfish(String? value) {
    switch (value?.toLowerCase()) {
      case 'graphicalconsole':
        return KvmConsoleType.graphical;
      case 'serialconsole':
        return KvmConsoleType.serial;
      case 'remoteconsole':
        return KvmConsoleType.remote;
      default:
        return KvmConsoleType.oem;
    }
  }

  /// Human-readable label for the console type.
  String get label {
    switch (this) {
      case KvmConsoleType.graphical:
        return 'Graphical Console';
      case KvmConsoleType.serial:
        return 'Serial Console';
      case KvmConsoleType.remote:
        return 'Remote Console';
      case KvmConsoleType.oem:
        return 'OEM Console';
    }
  }

  /// The Redfish property name backing this console type, when standard.
  String? get redfishName {
    switch (this) {
      case KvmConsoleType.graphical:
        return 'GraphicalConsole';
      case KvmConsoleType.serial:
        return 'SerialConsole';
      case KvmConsoleType.remote:
        return 'RemoteConsole';
      case KvmConsoleType.oem:
        return null;
    }
  }
}

/// An immutable view of a single Redfish console service found on a [Manager].
///
/// A manager body may carry a `GraphicalConsole`, `SerialConsole` and/or
/// `RemoteConsole` block; [fromManager] produces one [KvmConsole] per detected
/// block. Null-safe: any absent field yields a sensible default so the UI can
/// render a console even when the BMC omits metadata.
class KvmConsole {
  /// Creates a [KvmConsole].
  const KvmConsole({
    required this.type,
    required this.managerId,
    this.connectTypesSupported = const <String>[],
    this.serviceEnabled = false,
    this.maxConcurrentSessions,
    this.connectUri,
    required this.sourceManagerUri,
    this.oem,
  });

  /// The kind of console (graphical / serial / remote / oem).
  final KvmConsoleType type;

  /// The `Id` of the manager that exposes this console (e.g. `'BMC'`).
  final String managerId;

  /// The connection types advertised by `ConnectTypesSupported`, e.g.
  /// `['KVMIP']`, `['VNC','HTML5']`, or `['SSH','Telnet']`.
  final List<String> connectTypesSupported;

  /// Whether the console service is enabled (`ServiceEnabled`).
  final bool serviceEnabled;

  /// The maximum number of concurrent sessions (`MaxConcurrentSessions`),
  /// or `null` when the BMC does not report it.
  final int? maxConcurrentSessions;

  /// The connection URI to reach the console (`ConnectUri`), or `null` when the
  /// BMC does not embed one (most mockups omit it; the manager URI is used).
  final String? connectUri;

  /// The `@odata.id` of the manager resource this console was read from.
  final String sourceManagerUri;

  /// OEM-specific console extensions, populated only when the console block
  /// carries an `Oem` member; otherwise `null`.
  final Map<String, dynamic>? oem;

  /// Whether this console advertises an HTML5 web client (`ConnectTypesSupported`
  /// contains `'HTML5'`). HTML5 consoles are typically launched from the BMC
  /// web UI rather than a native client.
  bool get supportsHtml5 => connectTypesSupported.contains('HTML5');

  /// Builds the list of [KvmConsole]s detected in a Redfish [managerBody].
  ///
  /// [managerId] is the manager's `Id` (used for display). Each standard
  /// console block present in the body (`GraphicalConsole`, `SerialConsole`,
  /// `RemoteConsole`) yields one [KvmConsole]; an `Oem` console member, when
  /// present, yields an OEM console. Managers without any console block return
  /// an empty list.
  static List<KvmConsole> fromManager(
    Map<String, dynamic> managerBody, {
    required String managerId,
  }) {
    final String sourceManagerUri = (managerBody['@odata.id'] as String?) ??
        '/redfish/v1/Managers/$managerId';

    final List<KvmConsole> consoles = <KvmConsole>[];

    for (final KvmConsoleType type in <KvmConsoleType>[
      KvmConsoleType.graphical,
      KvmConsoleType.serial,
      KvmConsoleType.remote,
    ]) {
      final String? name = type.redfishName;
      if (name == null) continue;
      final dynamic block = managerBody[name];
      if (block is! Map<String, dynamic>) continue;
      consoles.add(
        _fromBlock(
          block,
          type: type,
          managerId: managerId,
          sourceManagerUri: sourceManagerUri,
        ),
      );
    }

    // OEM console, if the manager exposes one under `Oem`. Strict check: a
    // bare vendor-metadata `Oem` block (present on every OpenBMC bmcweb
    // Manager) must not be reported as a console — only blocks that actually
    // contain a console-like structure count (DOCS-4, 2026-10-22).
    final dynamic oem = managerBody['Oem'];
    if (oem is Map<String, dynamic> && FeatureRules.oemHasConsole(oem)) {
      consoles.add(
        KvmConsole(
          type: KvmConsoleType.oem,
          managerId: managerId,
          connectTypesSupported: const <String>[],
          serviceEnabled: true,
          sourceManagerUri: sourceManagerUri,
          oem: oem,
        ),
      );
    }

    return consoles;
  }

  /// Parses a single console [block] into a [KvmConsole].
  static KvmConsole _fromBlock(
    Map<String, dynamic> block, {
    required KvmConsoleType type,
    required String managerId,
    required String sourceManagerUri,
  }) {
    final List<String> types = _asStringList(block['ConnectTypesSupported']);
    final int? maxSessions = _asInt(block['MaxConcurrentSessions']);
    final String? connectUri = _asString(block['ConnectUri']);
    final bool enabled = block['ServiceEnabled'] as bool? ?? false;
    final dynamic oem = block['Oem'];
    return KvmConsole(
      type: type,
      managerId: managerId,
      connectTypesSupported: types,
      serviceEnabled: enabled,
      maxConcurrentSessions: maxSessions,
      connectUri: connectUri,
      sourceManagerUri: sourceManagerUri,
      oem: oem is Map<String, dynamic> ? oem : null,
    );
  }

  @override
  String toString() => 'KvmConsole(type=$type, manager=$managerId, '
      'types=$connectTypesSupported, enabled=$serviceEnabled)';
}

/// Returns [value] as a [String] or `null` when it is not a string.
String? _asString(Object? value) => value is String ? value : null;

/// Returns [value] as an [int] or `null` when it cannot be parsed.
int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// Builds a [List<String>] from a JSON list value, stringifying each element.
List<String> _asStringList(dynamic value) {
  if (value is List<dynamic>) {
    return value.map((dynamic e) => e.toString()).toList();
  }
  return const <String>[];
}
