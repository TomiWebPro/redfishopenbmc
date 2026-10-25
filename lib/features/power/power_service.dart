import 'package:dio/dio.dart';

import 'package:redfishopenbmc/features/power/models/power_state.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/odata.dart';
import 'package:redfishopenbmc/redfish/models/redfish_error.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Service implementing Redfish power / reset control (issue #005).
///
/// Wraps `POST /redfish/v1/Systems/{id}/Actions/ComputerSystem.Reset`. The
/// target URI is resolved, in order of preference, from:
///   1. the discovered [SystemFeatures.raw] tree (`#ComputerSystem.Reset`
///      action target),
///   2. the known ComputerSystem [systemResourceUri] (read from the snapshot),
///   3. a live crawl of `/redfish/v1/Systems` when nothing is cached.
///
/// Reset types not advertised by [SystemFeatures.supportedResetTypes] are
/// rejected locally before any request is issued, so the BMC never sees an
/// invalid `ResetType`. A `202` response carrying a `Location` task monitor is
/// treated as success — full task polling is deferred to issue #008.
class PowerService {
  /// Creates a [PowerService] bound to an authenticated [RedfishClient] for the
  /// system identified by [systemId].
  ///
  /// [client] may be `null` for a not-yet-connected system; calls then surface a
  /// friendly [RedfishException] rather than throwing on a `null` receiver.
  /// [features] and [systemResourceUri] are snapshots captured by the caller
  /// (the connected [SystemHandle]) and are used to resolve action targets and
  /// to gate unsupported reset types.
  PowerService({
    required this.client,
    required this.systemId,
    this.features,
    this.systemResourceUri,
  });

  /// Authenticated Redfish client, or `null` when not connected.
  final RedfishClient? client;

  /// The connection profile id (used only as a last-resort URI fallback).
  final String systemId;

  /// Discovered capability map for the system (power control + supported types).
  final SystemFeatures? features;

  /// Canonical `@odata.id` of the ComputerSystem resource, when known.
  final String? systemResourceUri;

  /// Issues a power reset of [type] for the system.
  ///
  /// Throws [RedfishException] when [type] is not in
  /// [SystemFeatures.supportedResetTypes] (when that list is non-empty), when
  /// the service is not connected, or when the BMC rejects the request
  /// (403 / 409 / 400 etc.).
  Future<void> reset(ResetType type) async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; connect before issuing a '
            'power action.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }

    final List<String> allowed = features?.supportedResetTypes ?? <String>[];
    if (allowed.isNotEmpty && !allowed.contains(type.toRedfish())) {
      throw RedfishException(
        message: 'Reset type "${type.toRedfish()}" is not supported by this '
            'system. Supported: ${allowed.join(", ")}.',
        statusCode: 400,
        errorCode: 'Base.1.0.ResetTypeInvalid',
      );
    }

    final String target = await _resolveResetTarget();
    try {
      final Response<dynamic> response = await c.dio.post<dynamic>(
        target,
        data: <String, String>{'ResetType': type.toRedfish()},
      );
      // 202 + Location means the BMC queued a task; we log but do not poll it.
      if (response.statusCode == 202) {
        final String? task = response.headers.value('location');
        if (task != null && task.isNotEmpty) {
          // Intentionally not awaited — task polling belongs to #008.
        }
      }
    } on DioException catch (e) {
      throw _toFriendly(e);
    }
  }

  /// Fetches the current [PowerState] by polling the ComputerSystem resource.
  ///
  /// Used by the post-reset polling loop. Network failures are surfaced as
  /// [RedfishException]; callers typically ignore transient errors while the
  /// optimistic state is still being displayed.
  Future<PowerState> fetchPowerState() async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; cannot read power state.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }
    final String uri = await _resolveSystemUri();
    try {
      final Map<String, dynamic> body = await c.getJson(uri);
      return PowerStateX.fromRedfish(body['PowerState'] as String?);
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to read power state: $e');
    }
  }

  /// Resolves the `#ComputerSystem.Reset` action target URI.
  ///
  /// Preference: discovery cache → known resource URI → live `/redfish/v1/Systems`
  /// crawl. As a final fallback returns the canonical Redfish path built from
  /// [systemId] (may be wrong for non-default ComputerSystem ids, which is why
  /// the earlier resolutions are preferred).
  Future<String> _resolveResetTarget() async {
    final String? cached = _actionTargetFromRaw();
    if (cached != null && cached.isNotEmpty) return cached;

    if (systemResourceUri != null && systemResourceUri!.isNotEmpty) {
      final Map<String, dynamic> body = await _safeGet(systemResourceUri!);
      final String? fromBody =
          ODataResource(body).actionTarget('#ComputerSystem.Reset');
      if (fromBody != null && fromBody.isNotEmpty) return fromBody;
      return '$systemResourceUri/Actions/ComputerSystem.Reset';
    }

    final String? live = await _liveSystemUri();
    if (live != null) {
      final Map<String, dynamic> body = await _safeGet(live);
      final String? fromBody =
          ODataResource(body).actionTarget('#ComputerSystem.Reset');
      if (fromBody != null && fromBody.isNotEmpty) return fromBody;
      return '$live/Actions/ComputerSystem.Reset';
    }

    // Final fallback: prefer the BMC ComputerSystem id discovered in the raw
    // tree over the profile id (which may not equal the BMC resource id and
    // would produce a malformed reset URI — issue #022). Mirrors
    // [_resolveSystemUri].
    final String? bmcId = _computerSystemIdFromRaw();
    if (bmcId != null && bmcId.isNotEmpty) {
      return '$bmcId/Actions/ComputerSystem.Reset';
    }
    return '/redfish/v1/Systems/$systemId/Actions/ComputerSystem.Reset';
  }

  /// Resolves the ComputerSystem resource URI used to poll power state.
  Future<String> _resolveSystemUri() async {
    if (systemResourceUri != null && systemResourceUri!.isNotEmpty) {
      return systemResourceUri!;
    }
    final String? cached = _computerSystemIdFromRaw();
    if (cached != null && cached.isNotEmpty) return cached;
    final String? live = await _liveSystemUri();
    if (live != null) return live;
    return '/redfish/v1/Systems/$systemId';
  }

  /// Crawls `/redfish/v1/Systems` and returns the first ComputerSystem
  /// `@odata.id`, or `null` when the collection is empty / unreachable.
  Future<String?> _liveSystemUri() async {
    final RedfishClient? c = client;
    if (c == null) return null;
    final Map<String, dynamic> root = await _safeGet('/redfish/v1/Systems');
    final List<dynamic> members =
        (root['Members'] as List<dynamic>?) ?? <dynamic>[];
    if (members.isEmpty) return null;
    final dynamic first = members.first;
    if (first is Map<dynamic, dynamic>) {
      final dynamic id = first['@odata.id'];
      if (id is String && id.isNotEmpty) return id;
    }
    return null;
  }

  /// Returns the first `#ComputerSystem.Reset` action target found in the
  /// discovery raw tree, or `null` when absent.
  String? _actionTargetFromRaw() {
    final Map<String, dynamic> raw = features?.raw ?? <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final dynamic value = entry.value;
      if (value is Map<String, dynamic>) {
        final String? target =
            ODataResource(value).actionTarget('#ComputerSystem.Reset');
        if (target != null && target.isNotEmpty) return target;
      }
    }
    return null;
  }

  /// Returns the first ComputerSystem `@odata.id` found in the discovery raw
  /// tree, or `null` when absent.
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

  /// Safe GET that never throws: returns an empty map on any failure so the
  /// resolution logic can gracefully fall through to the next strategy.
  Future<Map<String, dynamic>> _safeGet(String uri) async {
    final RedfishClient? c = client;
    if (c == null) return <String, dynamic>{};
    try {
      return await c.getJson(uri);
    } on RedfishException {
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Translates a [DioException] into a friendly [RedfishException], applying
  /// the issue #005 error taxonomy (403 privilege, 409 busy, 400 extended info).
  RedfishException _toFriendly(DioException e) {
    final Response<dynamic>? response = e.response;
    if (response == null) {
      return RedfishException.fromDioException(e);
    }
    final int? status = response.statusCode;
    if (status == 403) {
      return RedfishException(
        message: 'Insufficient privilege to perform this power action.',
        statusCode: 403,
        errorCode: 'Base.1.0.InsufficientPrivilege',
        details: RedfishError.tryParse(response.data),
        raw: response.data?.toString(),
      );
    }
    if (status == 409) {
      return RedfishException(
        message: 'System is busy; please try the power action again shortly.',
        statusCode: 409,
        errorCode: 'Base.1.0.ResourceInUse',
        details: RedfishError.tryParse(response.data),
        raw: response.data?.toString(),
      );
    }
    if (status == 400) {
      final RedfishError? details = RedfishError.tryParse(response.data);
      final String message = details?.firstMessage ??
          'Invalid reset request'
              "${details?.code != null ? ' (${details!.code})' : ''}.";
      return RedfishException(
        message: message,
        statusCode: 400,
        errorCode: details?.code,
        details: details,
        raw: response.data?.toString(),
      );
    }
    return RedfishException.fromDioException(e);
  }
}
