import 'package:dio/dio.dart';

import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/odata.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Service implementing remote KVM / console discovery (issue #009).
///
/// Walks `/redfish/v1/Managers`, fetches each manager body, and extracts the
/// console services (`GraphicalConsole`, `SerialConsole`, `RemoteConsole`) via
/// [KvmConsole.fromManager]. The flattening keeps the UI simple: it renders one
/// card per [KvmConsole] regardless of which manager exposed it.
///
/// A manager without any console block is skipped silently; a not-connected
/// service (`client == null`) surfaces a friendly [RedfishException]; any
/// transport failure is normalized into a [RedfishException].
class KvmService {
  /// Creates a [KvmService] bound to an authenticated [RedfishClient] for the
  /// system identified by [systemId].
  ///
  /// [client] may be `null` for a not-yet-connected system; calls then surface a
  /// friendly [RedfishException] rather than throwing on a `null` receiver.
  /// [features] is the discovered capability map (its [SystemFeatures.kvm]
  /// flag gates the UI, not the service itself).
  KvmService({
    required this.client,
    required this.systemId,
    this.features,
  });

  /// Authenticated Redfish client, or `null` when not connected.
  final RedfishClient? client;

  /// The connection profile id (used only for error messaging).
  final String systemId;

  /// Discovered capability map for the system (KVM availability + type).
  final SystemFeatures? features;

  /// Fetches every console exposed by the system's managers.
  ///
  /// GETs `/redfish/v1/Managers`, iterates the collection `Members`, GETs each
  /// manager body, and returns the flattened [KvmConsole] list. Managers with no
  /// console blocks are skipped. Throws [RedfishException] when not connected or
  /// on a transport error.
  Future<List<KvmConsole>> fetchConsoles() async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; connect before reading KVM '
            'consoles.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }

    try {
      final Map<String, dynamic> root = await c.getJson('/redfish/v1/Managers');
      final List<dynamic> members =
          (root['Members'] as List<dynamic>?) ?? <dynamic>[];

      final List<KvmConsole> consoles = <KvmConsole>[];
      for (final dynamic entry in members) {
        final String? managerUri = _memberUri(entry);
        if (managerUri == null || managerUri.isEmpty) continue;
        final Map<String, dynamic> body = await c.getJson(managerUri);
        final String managerId = _managerId(body, managerUri);
        final List<KvmConsole> found =
            KvmConsole.fromManager(body, managerId: managerId);
        consoles.addAll(found);
      }
      return consoles;
    } on RedfishException {
      rethrow;
    } on DioException catch (e) {
      throw RedfishException.fromDioException(e);
    } catch (e) {
      throw RedfishException(message: 'Failed to read KVM consoles: $e');
    }
  }

  /// Returns the preferred [KvmConsole] for launching a session.
  ///
  /// Prefers the first [KvmConsoleType.graphical] console (the most capable
  /// remote-desktop style console); falls back to the first console in the list,
  /// or `null` when the system exposes no consoles at all.
  Future<KvmConsole?> fetchPrimaryConsole() async {
    final List<KvmConsole> consoles = await fetchConsoles();
    if (consoles.isEmpty) return null;
    for (final KvmConsole console in consoles) {
      if (console.type == KvmConsoleType.graphical) return console;
    }
    return consoles.first;
  }

  /// Resolves the `@odata.id` of a collection member (string or link map).
  String? _memberUri(dynamic entry) {
    if (entry is Map<dynamic, dynamic>) {
      final dynamic id = entry['@odata.id'];
      if (id is String && id.isNotEmpty) return id;
    } else if (entry is String && entry.isNotEmpty) {
      return entry;
    }
    return null;
  }

  /// Derives a stable manager id from its body `Id` or trailing URI segment.
  String _managerId(Map<String, dynamic> body, String managerUri) {
    final dynamic id = body['Id'];
    if (id is String && id.isNotEmpty) return id;
    final String? odataId = ODataResource(body).id;
    if (odataId != null && odataId.isNotEmpty) {
      final String? last = _lastSegment(odataId);
      if (last != null) return last;
    }
    return _lastSegment(managerUri) ?? managerUri;
  }

  /// Returns the last non-empty path segment of [uri], or `null`.
  String? _lastSegment(String uri) {
    final List<String> segments =
        uri.split('/').where((String s) => s.isNotEmpty).toList();
    return segments.isEmpty ? null : segments.last;
  }
}
