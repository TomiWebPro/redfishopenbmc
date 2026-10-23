import 'dart:convert';

/// One firmware/software inventory entry reported by the UpdateService
/// `FirmwareInventory` (or `SoftwareInventory`) collection (issue #008).
///
/// Mirrors a Redfish `SoftwareInventory` member: a device or component's current
/// version, whether the update service can reflash it, and where it applies.
class FirmwareInventoryItem {
  /// Creates a [FirmwareInventoryItem].
  const FirmwareInventoryItem({
    required this.id,
    this.name,
    this.version,
    this.updateable = false,
    this.softwareId,
    this.health,
    this.relatedItems = const <String>[],
  });

  /// Stable identifier: the last path segment of `@odata.id` (e.g. `BMC`),
  /// falling back to [name] when the link is absent.
  final String id;

  /// Human-readable component name (e.g. "Contoso BMC Firmware").
  final String? name;

  /// Installed version string (e.g. "1.45.455b66-rev4").
  final String? version;

  /// Whether the update service can reflash this component.
  final bool updateable;

  /// Implementation-specific label identifying the software (`SoftwareId`).
  final String? softwareId;

  /// Health reported under `Status.Health`, or `null` when absent.
  final String? health;

  /// `@odata.id` links to resources this inventory applies to (`RelatedItem`).
  final List<String> relatedItems;

  /// Builds a [FirmwareInventoryItem] from a Redfish `SoftwareInventory` body.
  ///
  /// [id] may be supplied (e.g. when the caller already has the `@odata.id`);
  /// otherwise it is derived from the body's `@odata.id` last segment or [name].
  factory FirmwareInventoryItem.fromJson(
    Map<String, dynamic> body, {
    String? id,
  }) {
    final String? odataId = _asString(body['@odata.id']);
    final String derivedId = id ??
        odataId?.split('/').where((String s) => s.isNotEmpty).last ??
        _asString(body['Name']) ??
        _asString(body['Id']) ??
        '';

    final Map<String, dynamic> status = body['Status'] is Map<String, dynamic>
        ? body['Status'] as Map<String, dynamic>
        : <String, dynamic>{};

    final List<String> related = <String>[];
    final dynamic relatedRaw = body['RelatedItem'];
    if (relatedRaw is List<dynamic>) {
      for (final dynamic entry in relatedRaw) {
        if (entry is Map<dynamic, dynamic> && entry['@odata.id'] is String) {
          related.add(entry['@odata.id'] as String);
        } else if (entry is String) {
          related.add(entry);
        }
      }
    }

    return FirmwareInventoryItem(
      id: derivedId,
      name: _asString(body['Name']),
      version: _asString(body['Version']),
      updateable: body['Updateable'] as bool? ?? false,
      softwareId: _asString(body['SoftwareId']),
      health: _asString(status['Health']),
      relatedItems: related,
    );
  }

  @override
  String toString() =>
      'FirmwareInventoryItem($id: name=$name, version=$version, '
      'updateable=$updateable)';

  /// Convenience JSON decode + parse used by the model tests.
  static FirmwareInventoryItem fromJsonString(String source, {String? id}) =>
      FirmwareInventoryItem.fromJson(
        jsonDecode(source) as Map<String, dynamic>,
        id: id,
      );
}

/// Aggregate firmware/update-service state for a single system (issue #008).
///
/// Combines the `UpdateService` properties (`ServiceEnabled`, `HttpPushUri`,
/// `Version`) with the fully-resolved [inventory] collection. Redfish does not
/// enumerate supported transfer protocols, so [transferProtocols] is the fixed
/// standard set ([CIFS], [NFS], [HTTP], [HTTPS], [SFTP], [TFTP]).
class UpdateServiceInfo {
  /// Creates an [UpdateServiceInfo].
  const UpdateServiceInfo({
    this.serviceEnabled = false,
    this.version,
    this.httpPushUri,
    this.multipartHttpPushUri,
    this.httpPushApplyTime,
    this.httpPushApplyTimes = const <String>[],
    this.inventory = const <FirmwareInventoryItem>[],
    this.transferProtocols = _kDefaultProtocols,
  });

  /// The standard Redfish transfer-protocol set, in display order.
  static const List<String> _kDefaultProtocols = <String>[
    'CIFS',
    'NFS',
    'HTTP',
    'HTTPS',
    'SFTP',
    'TFTP',
  ];

  /// Whether the UpdateService is currently enabled.
  final bool serviceEnabled;

  /// UpdateService version string (`Version`, falling back to `Id`).
  final String? version;

  /// URI used for an HTTP/HTTPS push update (`HttpPushUri`, e.g. `/FWUpdate`).
  final String? httpPushUri;

  /// URI used for a Redfish-defined multipart HTTP/HTTPS push update
  /// (`MultipartHttpPushUri`, e.g. `/upload/image`). bmcweb publishes this in
  /// addition to [httpPushUri] (bmcweb `Redfish.md` §UpdateService;
  /// `UpdateService.v1_17_1.json` `MultipartHttpPushUri` — DOCS-4, #008/#020).
  final String? multipartHttpPushUri;

  /// Current push-apply-time mode (`HttpPushUriOptions.HttpPushUriApplyTime.
  /// ApplyTime`, e.g. `Immediate`), or `null` when the service does not
  /// publish push options (issue #008/#020).
  final String? httpPushApplyTime;

  /// Allowable push-apply-time modes (`ApplyTime@Redfish.AllowableValues`),
  /// e.g. `Immediate` / `OnReset` / `AtMaintenanceWindowStart`.
  final List<String> httpPushApplyTimes;

  /// Fully-resolved firmware inventory (one entry per collection member).
  final List<FirmwareInventoryItem> inventory;

  /// Supported SimpleUpdate transfer protocols (hardcoded standard set).
  final List<String> transferProtocols;

  /// Builds an [UpdateServiceInfo] from an `UpdateService` [body].
  ///
  /// [inventory] is supplied separately because it requires additional round
  /// trips to resolve the `FirmwareInventory` collection (see
  /// [FirmwareService.fetchUpdateService]); the service attaches it after the
  /// fact. [transferProtocols] defaults to the standard Redfish set.
  factory UpdateServiceInfo.fromJson(
    Map<String, dynamic> body, {
    List<FirmwareInventoryItem>? inventory,
    List<String>? transferProtocols,
  }) {
    return UpdateServiceInfo(
      serviceEnabled: body['ServiceEnabled'] as bool? ?? false,
      version: _asString(body['Version']) ?? _asString(body['Id']),
      httpPushUri: _asString(body['HttpPushUri']),
      multipartHttpPushUri: _asString(body['MultipartHttpPushUri']),
      httpPushApplyTime: _applyTime(body),
      httpPushApplyTimes: _applyTimes(body),
      inventory: inventory ?? const <FirmwareInventoryItem>[],
      transferProtocols: transferProtocols ?? _kDefaultProtocols,
    );
  }

  /// Returns a copy with [inventory] replaced (used to attach the resolved
  /// collection without rebuilding the whole info).
  UpdateServiceInfo copyWithInventory(List<FirmwareInventoryItem> inventory) =>
      UpdateServiceInfo(
        serviceEnabled: serviceEnabled,
        version: version,
        httpPushUri: httpPushUri,
        multipartHttpPushUri: multipartHttpPushUri,
        httpPushApplyTime: httpPushApplyTime,
        httpPushApplyTimes: httpPushApplyTimes,
        inventory: inventory,
        transferProtocols: transferProtocols,
      );
}

/// Request payload for the `#UpdateService.SimpleUpdate` action (issue #008).
///
/// Encodes exactly the Redfish body: `ImageURI` (the source image),
/// `TransferProtocol` (how to fetch it), and `Targets` (the components/URIs to
/// apply it to).
class SimpleUpdateRequest {
  /// Creates a [SimpleUpdateRequest].
  const SimpleUpdateRequest({
    required this.imageUri,
    this.transferProtocol = 'HTTP',
    this.targets = const <String>[],
  });

  /// The URI of the firmware image to apply (`ImageURI`).
  final String imageUri;

  /// Transfer protocol used to fetch [imageUri] (`TransferProtocol`).
  final String transferProtocol;

  /// Target resource URIs to apply the image to (`Targets`).
  final List<String> targets;

  /// Serializes to the Redfish SimpleUpdate body.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'ImageURI': imageUri,
        'TransferProtocol': transferProtocol,
        'Targets': targets,
      };
}

/// A SimpleUpdate task monitor handle returned after a queued update (issue #008).
///
/// A real BMC responds 202 `Location: <task URI>`; [taskUri] captures that and
/// [statusText] carries any human-readable message from the response.
class UpdateTask {
  /// Creates an [UpdateTask].
  const UpdateTask({this.taskUri, this.statusText});

  /// The task monitor URI returned in the 202 `Location` header, or `null`
  /// when the BMC did not provide one.
  final String? taskUri;

  /// Optional human-readable status / message.
  final String? statusText;

  @override
  String toString() => 'UpdateTask(taskUri=$taskUri, statusText=$statusText)';
}

/// Returns [value] as a [String] or `null` when it is not a string.
String? _asString(Object? value) => value is String ? value : null;

/// Reads `HttpPushUriOptions.HttpPushUriApplyTime.ApplyTime` (the current
/// push-apply-time mode) from an `UpdateService` [body].
String? _applyTime(Map<String, dynamic> body) {
  final Map<String, dynamic> options =
      body['HttpPushUriOptions'] is Map<String, dynamic>
          ? body['HttpPushUriOptions'] as Map<String, dynamic>
          : const <String, dynamic>{};
  final Map<String, dynamic> applyTime =
      options['HttpPushUriApplyTime'] is Map<String, dynamic>
          ? options['HttpPushUriApplyTime'] as Map<String, dynamic>
          : const <String, dynamic>{};
  return _asString(applyTime['ApplyTime']);
}

/// Reads `HttpPushUriOptions.HttpPushUriApplyTime.
/// ApplyTime@Redfish.AllowableValues` (the allow-list of push-apply-time modes)
/// from an `UpdateService` [body]. Returns an empty list when absent.
List<String> _applyTimes(Map<String, dynamic> body) {
  final Map<String, dynamic> options =
      body['HttpPushUriOptions'] is Map<String, dynamic>
          ? body['HttpPushUriOptions'] as Map<String, dynamic>
          : const <String, dynamic>{};
  final Map<String, dynamic> applyTime =
      options['HttpPushUriApplyTime'] is Map<String, dynamic>
          ? options['HttpPushUriApplyTime'] as Map<String, dynamic>
          : const <String, dynamic>{};
  final Object? allowed = applyTime['ApplyTime@Redfish.AllowableValues'];
  if (allowed is List<dynamic>) {
    return allowed.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}
