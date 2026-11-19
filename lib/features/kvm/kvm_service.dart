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
  /// normalises transport errors. A member that cannot be read is skipped when
  /// its failure is not fatal to the session — a stale/removed link (404) or a
  /// transient, retryable failure (429, 5xx except 501, timeout / connection
  /// error) — so one dead or flapping manager cannot blank the whole gated KVM
  /// screen while the other managers still expose usable consoles (RS-2).
  /// Auth errors (401/403), TLS certificate failures and every other
  /// non-retryable failure still propagate so they are never masked as a
  /// missing optional sub-resource (issue #009/#021). A malformed (non-list)
  /// `Members` collection is treated as no managers rather than blanking the
  /// screen with a cast error (issue #009).
  ///
  /// Members are deduplicated by their normalized member URI (first occurrence
  /// wins), so a BMC that repeats a manager link — verbatim, padded or in a
  /// different member shape — yields exactly one console/capability card rather
  /// than duplicate cards. Blank/malformed links are already rejected by
  /// [_memberUri] before this point (RS-4).
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
      // Deduplicate by normalized member URI (already trimmed + blank-rejected
      // by `_memberUri`), first occurrence wins. A repeated manager link would
      // otherwise be walked twice and render duplicate console/capability cards
      // for the same physical manager (RS-4).
      final Set<String> seenUris = <String>{};
      for (final dynamic entry in members) {
        final String? managerUri = _memberUri(entry);
        if (managerUri == null || managerUri.isEmpty) continue;
        if (!seenUris.add(managerUri)) continue;

        final Map<String, dynamic> body;
        try {
          body = await c.getJson(managerUri);
        } on RedfishException catch (e) {
          // A per-member failure is not a failure of discovery when it is a
          // stale/deleted link (404) or a transient, retryable condition (429,
          // 5xx except 501, timeout / connection error — see
          // RedfishException.retryable). Skipping it keeps both KVM views
          // populated from the healthy managers instead of blanking the gated
          // screen on one dead or flapping member (RS-2). Auth failures
          // (401/403), TLS certificate failures and all other non-retryable
          // errors are rethrown so they are never masked as a missing optional
          // sub-resource: the session must be re-authenticated on 401/403 and
          // a bad certificate must never be silently tolerated (issue #009).
          if (e.statusCode == 404 || e.retryable) continue;
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
  /// target, so it must be one the user can actually open — and, because the
  /// final render route is an external browser + copy (no embedded WebView),
  /// it should be one that is *safe* to open externally. Selection order:
  /// first openable secure-HTTPS graphical console, then first openable
  /// secure-HTTPS console of any type, then first openable graphical, then
  /// first openable of any type, then first graphical, then first overall.
  /// The secure-HTTPS tiers prefer a control-safe TLS endpoint (the only
  /// target safe to recommend for the external-browser route) over a
  /// plaintext-HTTP or external-client-only console when one exists — a
  /// plaintext / VNC / SSH console is never badged "Primary" while a secure
  /// browser-openable console is available (issue #021, never weaken TLS).
  /// The later tiers keep a sensible badge when a BMC exposes only disabled /
  /// URI-less / insecure consoles (which are still the best available choice).
  /// Returns `null` when [consoles] is empty (issue #009).
  static KvmConsole? pickPrimary(List<KvmConsole> consoles) {
    if (consoles.isEmpty) return null;

    KvmConsole? firstSecureGraphical;
    KvmConsole? firstSecure;
    KvmConsole? firstOpenable;
    KvmConsole? firstOpenableGraphical;
    KvmConsole? firstGraphical;
    for (final KvmConsole console in consoles) {
      final bool graphical = console.type == KvmConsoleType.graphical;
      if (graphical) firstGraphical ??= console;
      if (!console.canOpenConsole) continue;
      firstOpenable ??= console;
      if (graphical) firstOpenableGraphical ??= console;

      // A control-safe HTTPS URI is the only target safe to recommend for the
      // final external-browser + copy route. Prefer it over a plaintext-HTTP
      // or external-client console so the "Primary" badge never advertises an
      // unsafe / non-browser target when a secure console exists. Disabled and
      // URI-less consoles are already excluded by canOpenConsole above, and
      // hasSecureLaunchUri uses the same fail-closed classifier as the launch
      // plan (a CRLF/spoofed target never counts as secure). A secure graphical
      // console is the best possible target, so stop as soon as one is found.
      if (console.hasSecureLaunchUri) {
        firstSecure ??= console;
        if (graphical) {
          firstSecureGraphical ??= console;
          break;
        }
      }
    }
    return firstSecureGraphical ??
        firstSecure ??
        firstOpenableGraphical ??
        firstOpenable ??
        firstGraphical ??
        consoles.first;
  }

  /// Resolves the `@odata.id` of a collection member (string or link map).
  ///
  /// A Redfish `Members` entry is either a string URI or a link object carrying
  /// `@odata.id`. Both forms are normalized through [String.trim] and a blank
  /// (empty or whitespace-only) value is treated as absent: a BMC may emit a
  /// padded-but-valid link (`'  /redfish/v1/Managers/BMC  '`), which `Uri.tryParse`
  /// / Dio would reject as a malformed target and drop the manager (and all of
  /// its consoles) from the gated KVM screen, while a whitespace-only link must
  /// never be fetched at all. Mirrors the malformed-payload tolerance applied to
  /// every other KVM URI source (`KvmConsole._uriString`,
  /// `KvmCapability._nonEmptyString`, issue #009).
  String? _memberUri(dynamic entry) {
    final dynamic value;
    if (entry is Map<dynamic, dynamic>) {
      value = entry['@odata.id'];
    } else if (entry is String) {
      value = entry;
    } else {
      return null;
    }
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Derives a stable manager id from its body `Id` or trailing URI segment.
  ///
  /// Every source is trimmed and a blank value rejected so a malformed BMC
  /// payload cannot key a console/capability under a padded id (which would
  /// show stray whitespace on the cards and make `fetchCapability(realId)` miss
  /// it). This applies to the canonical `Id`, the body `@odata.id` fallback and
  /// the member-URI fallback alike (issue #009).
  String _managerId(Map<String, dynamic> body, String managerUri) {
    final dynamic id = body['Id'];
    if (id is String) {
      final String trimmed = id.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    // A manager may omit `Id`; fall back to the body `@odata.id` last segment.
    // Normalize BOTH the whole URI and the derived segment: a padded URI can
    // still yield a padded segment, and a whitespace-only `@odata.id` is not a
    // usable id at all — in that case fall through to the member URI. This
    // mirrors the `Id` normalization and every other KVM URI source (issue
    // #009).
    final String? odataId = _trimmedNonBlank(ODataResource(body).id);
    if (odataId != null) {
      final String? last = _trimmedNonBlank(_lastSegment(odataId));
      if (last != null) return last;
    }
    return _trimmedNonBlank(_lastSegment(managerUri)) ?? managerUri;
  }

  /// Returns [value] trimmed, or `null` when it is null or blank.
  ///
  /// Shared by the manager-id fallbacks so a padded/blank `@odata.id` or member
  /// URI segment can never leak stray whitespace into a card or key a manager
  /// under an id the operator cannot look up (issue #009).
  String? _trimmedNonBlank(String? value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Returns the last non-empty path segment of [uri], or `null`.
  String? _lastSegment(String uri) {
    final List<String> segments =
        uri.split('/').where((String s) => s.isNotEmpty).toList();
    return segments.isEmpty ? null : segments.last;
  }
}
