import 'package:redfishopenbmc/features/bios/models/bios_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/odata.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Service for reading and mutating the Redfish Bios / `@Redfish.Settings`
/// surface (issue #028, foundational slice).
///
/// Discovery is URI-driven: the Bios URI is resolved from the ComputerSystem
/// resource's `Bios.@odata.id` link when present, with a conservative fallback.
/// Pending settings are read from the `SettingsObject.@odata.id` advertised by
/// the Bios `@Redfish.Settings` annotation. Mutations use
/// [RedfishClient.patchJson] with the settings-object ETag as `If-Match`.
class BiosService {
  /// Creates a [BiosService].
  BiosService({
    required this.client,
    required this.systemId,
    this.features,
    this.systemResourceUri,
  });

  /// Authenticated Redfish client, or `null` when not connected.
  final RedfishClient? client;

  /// The connection profile id.
  final String systemId;

  /// Discovered capability map (used for ComputerSystem URI resolution).
  final SystemFeatures? features;

  /// Canonical `@odata.id` of the ComputerSystem resource, when known.
  final String? systemResourceUri;

  /// Fetches the current [BiosResource].
  ///
  /// Throws [RedfishException] when not connected or when the resource cannot
  /// be read.
  Future<BiosResource> fetchBios() async {
    final RedfishClient c = _requireClient('read BIOS settings');
    final String uri = await resolveBiosUri();
    try {
      final Map<String, dynamic> body = await c.getJson(uri);
      return BiosResource.fromJson(body);
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to read BIOS settings: $e');
    }
  }

  /// Fetches the pending settings resource for [bios].
  ///
  /// Returns `null` when [bios] does not advertise a settings object URI.
  Future<BiosPendingSettings?> fetchPendingSettings(BiosResource bios) async {
    final String? uri = bios.pendingSettingsUri;
    if (uri == null || uri.isEmpty) return null;
    final RedfishClient c = _requireClient('read pending BIOS settings');
    try {
      final Map<String, dynamic> body = await c.getJson(uri);
      return BiosPendingSettings.fromJson(body);
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(
        message: 'Failed to read pending BIOS settings: $e',
      );
    }
  }

  /// Convenience: fetches current Bios and, when available, its pending
  /// settings in one call.
  Future<({BiosResource current, BiosPendingSettings? pending})>
      fetchBiosWithPending() async {
    final BiosResource current = await fetchBios();
    final BiosPendingSettings? pending = await fetchPendingSettings(current);
    return (current: current, pending: pending);
  }

  /// PATCHes [attributes] to the pending settings resource using the
  /// settings-object ETag from [bios] as `If-Match` when available.
  ///
  /// [attributes] is sent as `{"Attributes": attributes}` (Redfish partial
  /// update). Throws [RedfishException] when no pending settings URI is
  /// advertised or on transport/service errors (including 412 precondition
  /// failures surfaced by [RedfishClient]).
  Future<Map<String, dynamic>> patchPendingAttributes(
    BiosResource bios,
    Map<String, dynamic> attributes,
  ) async {
    final String? uri = bios.pendingSettingsUri;
    if (uri == null || uri.isEmpty) {
      throw const RedfishException(
        message:
            'This BMC does not advertise a BIOS pending settings resource.',
        statusCode: 400,
        errorCode: 'Base.1.0.PropertyNotWritable',
      );
    }
    final RedfishClient c = _requireClient('update BIOS settings');
    try {
      return await c.patchJson(
        uri,
        body: <String, dynamic>{
          'Attributes': Map<String, dynamic>.from(attributes),
        },
        etag: bios.settingsEtag,
      );
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to update BIOS settings: $e');
    }
  }

  /// POSTs to the `#Bios.ResetBios` action when advertised.
  ///
  /// Returns the response body (usually empty for 204). Throws
  /// [RedfishException] when the action is not available or on failure.
  Future<Map<String, dynamic>> resetBios(BiosResource bios) async {
    final String? target = bios.actions.resetBiosTarget;
    if (target == null || target.isEmpty) {
      throw const RedfishException(
        message: 'BIOS reset action is not available on this system.',
        statusCode: 400,
        errorCode: 'Base.1.0.ActionNotSupported',
      );
    }
    final RedfishClient c = _requireClient('reset BIOS settings');
    try {
      return await c.postJson(target, body: const <String, dynamic>{});
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to reset BIOS settings: $e');
    }
  }

  /// Resolves the Bios resource URI.
  ///
  /// Preference order: `ComputerSystem.Bios.@odata.id` (from discovery raw
  /// tree) → `ComputerSystem.Bios.@odata.id` (live GET) →
  /// `{systemUri}/Bios` fallback.
  Future<String> resolveBiosUri() async {
    final String? fromRaw = _biosUriFromRaw();
    if (fromRaw != null && fromRaw.isNotEmpty) return fromRaw;

    final RedfishClient? c = client;
    if (c != null) {
      final String systemUri = await _resolveSystemUri();
      try {
        final Map<String, dynamic> system = await c.getJson(systemUri);
        final String? fromSystem = _biosLink(system);
        if (fromSystem != null && fromSystem.isNotEmpty) return fromSystem;
      } on RedfishException {
        // Fall through to conservative fallback.
      } catch (_) {
        // Fall through to conservative fallback.
      }
      final String normalized = systemUri.endsWith('/')
          ? systemUri.substring(0, systemUri.length - 1)
          : systemUri;
      return '$normalized/Bios';
    }

    final String? uri = systemResourceUri;
    if (uri != null && uri.isNotEmpty) {
      final String normalized =
          uri.endsWith('/') ? uri.substring(0, uri.length - 1) : uri;
      return '$normalized/Bios';
    }
    return '/redfish/v1/Systems/$systemId/Bios';
  }

  RedfishClient _requireClient(String action) {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; cannot $action.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }
    return c;
  }

  Future<String> _resolveSystemUri() async {
    final String? cached = _computerSystemIdFromRaw();
    if (cached != null && cached.isNotEmpty) return cached;
    if (systemResourceUri != null && systemResourceUri!.isNotEmpty) {
      return systemResourceUri!;
    }
    final String? live = await _liveSystemUri();
    if (live != null && live.isNotEmpty) return live;
    return '/redfish/v1/Systems/$systemId';
  }

  String? _computerSystemIdFromRaw() {
    final Map<String, dynamic> raw = features?.raw ?? <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final dynamic value = entry.value;
      if (value is Map<String, dynamic>) {
        final ODataResource res = ODataResource(value);
        if (res.isType('computersystem')) {
          final String? id = res.id;
          if (id != null && id.isNotEmpty) return id;
        }
      }
    }
    return null;
  }

  String? _biosUriFromRaw() {
    final Map<String, dynamic> raw = features?.raw ?? <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final dynamic value = entry.value;
      if (value is Map<String, dynamic>) {
        final ODataResource res = ODataResource(value);
        if (res.isType('computersystem')) {
          final String? link = _biosLink(value);
          if (link != null && link.isNotEmpty) return link;
        }
      }
    }
    return null;
  }

  String? _biosLink(Map<String, dynamic> system) {
    final dynamic bios = system['Bios'];
    if (bios is Map<String, dynamic>) {
      final dynamic id = bios['@odata.id'];
      return id is String ? id : null;
    }
    return null;
  }

  Future<String?> _liveSystemUri() async {
    final RedfishClient? c = client;
    if (c == null) return null;
    try {
      final Map<String, dynamic> root = await c.getJson('/redfish/v1/Systems');
      final List<dynamic> members =
          (root['Members'] as List<dynamic>?) ?? <dynamic>[];
      if (members.isEmpty) return null;
      final dynamic first = members.first;
      if (first is Map<String, dynamic>) {
        final dynamic id = first['@odata.id'];
        if (id is String && id.isNotEmpty) return id;
      }
      return null;
    } on RedfishException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
