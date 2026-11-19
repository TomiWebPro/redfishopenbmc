import 'package:dio/dio.dart';

import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
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
    final List<({String managerId, Map<String, dynamic> body})> managers =
        await _fetchManagerBodies();
    final List<KvmConsole> consoles = <KvmConsole>[];
    for (final ({String managerId, Map<String, dynamic> body}) manager
        in managers) {
      consoles.addAll(
        KvmConsole.fromManager(manager.body, managerId: manager.managerId),
      );
    }
    return consoles;
  }

  /// Fetches a per-manager [KvmCapability] summary for every manager.
  ///
  /// Walks the same `/redfish/v1/Managers` tree as [fetchConsoles], but returns
  /// one aggregated capability card per manager (detection + resolved URI)
  /// instead of one entry per console block (issue #009).
  Future<List<KvmCapability>> fetchCapabilities() async {
    final List<({String managerId, Map<String, dynamic> body})> managers =
        await _fetchManagerBodies();
    final List<KvmCapability> capabilities = <KvmCapability>[];
    for (final ({String managerId, Map<String, dynamic> body}) manager
        in managers) {
      capabilities.add(
        KvmCapability.fromManager(
          manager.body,
          managerId: manager.managerId,
          // ODataResource.id safely ignores a non-string `@odata.id` instead of
          // throwing a TypeError that would blank the capability card (#009).
          sourceManagerUri: ODataResource(manager.body).id,
        ),
      );
    }
    return capabilities;
  }

  /// Fetches the [KvmCapability] for a single manager by its `Id`.
  ///
  /// Returns `null` when no manager with that id is exposed. This is the
  /// read-only URI-resolution entry point (no IPC): callers receive a
  /// capability with a resolved [KvmCapability.uri] to open externally.
  Future<KvmCapability?> fetchCapability(String managerId) async {
    final List<KvmCapability> capabilities = await fetchCapabilities();
    for (final KvmCapability capability in capabilities) {
      if (capability.managerId == managerId) return capability;
    }
    return null;
  }

  /// Walks `/redfish/v1/Managers`, GETting each member body.
  ///
  /// Shared by [fetchConsoles] and [fetchCapabilities] so both views stay in
  /// sync. Surfaces a friendly [RedfishException] when not connected and
  /// normalises transport errors. A single member that answers 404 (a stale /
  /// removed manager link, common on hot-swap or transient BMC states) is
  /// skipped so one dead link cannot blank the whole KVM screen; auth errors
  /// (401/403) and every other failure still propagate. A malformed (non-list)
  /// `Members` collection is treated as no managers rather than blanking the
  /// screen with a cast error (issue #009).
  Future<List<({String managerId, Map<String, dynamic> body})>>
      _fetchManagerBodies() async {
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
      // A malformed BMC payload can advertise `Members` as a non-list value.
      // A bare `as List<dynamic>?` cast throws a TypeError here; the generic
      // catch below turns it into a RedfishException and blanks the whole gated
      // KVM screen. Treat a non-list `Members` as "no managers discovered",
      // matching the malformed-payload tolerance used by every other KVM parser
      // (`_memberUri`, `KvmCapability._advertises`, etc., issue #009).
      final dynamic membersValue = root['Members'];
      final List<dynamic> members =
          membersValue is List<dynamic> ? membersValue : <dynamic>[];

      final List<({String managerId, Map<String, dynamic> body})> managers =
          <({String managerId, Map<String, dynamic> body})>[];
      for (final dynamic entry in members) {
        final String? managerUri = _memberUri(entry);
        if (managerUri == null || managerUri.isEmpty) continue;

        final Map<String, dynamic> body;
        try {
          body = await c.getJson(managerUri);
        } on RedfishException catch (e) {
          // A stale/deleted member (404) is not a failure of discovery — the
          // other, healthy managers still expose consoles the operator can use.
          // Skipping it keeps both KVM views populated instead of blanking the
          // gated screen on one dead link (issue #009). Auth failures (401/403)
          // and all other errors are rethrown so they are never masked as a
          // missing optional sub-resource.
          if (e.statusCode == 404) continue;
          rethrow;
        }
        final String managerId = _managerId(body, managerUri);
        managers.add((managerId: managerId, body: body));
      }
      return managers;
    } on RedfishException {
      rethrow;
    } on DioException catch (e) {
      throw RedfishException.fromDioException(e);
    } catch (e) {
      throw RedfishException(message: 'Failed to read KVM managers: $e');
    }
  }

  /// Returns the preferred [KvmConsole] for launching a session.
  ///
  /// Prefers the first [KvmConsoleType.graphical] console (the most capable
  /// remote-desktop style console); falls back to the first console in the list,
  /// or `null` when the system exposes no consoles at all.
  Future<KvmConsole?> fetchPrimaryConsole() async {
    final List<KvmConsole> consoles = await fetchConsoles();
    return pickPrimary(consoles);
  }

  /// Picks the preferred [KvmConsole] from [consoles] without fetching.
  ///
  /// The primary console is badged "Primary" and is the recommended launch
  /// target, so it must be one the user can actually open. Selection order:
  /// first openable graphical console, then first openable console of any type,
  /// then first graphical, then first overall. The last two tiers keep a
  /// sensible badge when a BMC exposes only disabled or URI-less consoles
  /// (which cannot be opened but are still the best available choice).
  /// Returns `null` when [consoles] is empty (issue #009).
  static KvmConsole? pickPrimary(List<KvmConsole> consoles) {
    if (consoles.isEmpty) return null;

    KvmConsole? firstOpenable;
    KvmConsole? firstOpenableGraphical;
    KvmConsole? firstGraphical;
    for (final KvmConsole console in consoles) {
      final bool graphical = console.type == KvmConsoleType.graphical;
      if (graphical) firstGraphical ??= console;
      if (!console.canOpenConsole) continue;
      firstOpenable ??= console;
      if (graphical) {
        firstOpenableGraphical ??= console;
        break;
      }
    }
    return firstOpenableGraphical ??
        firstOpenable ??
        firstGraphical ??
        consoles.first;
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
