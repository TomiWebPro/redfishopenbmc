import 'dart:io';

import 'package:dio/dio.dart';

import 'package:redfishopenbmc/features/firmware/models/firmware_models.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/odata.dart';
import 'package:redfishopenbmc/redfish/models/redfish_error.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/redfish_task.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Service implementing Redfish firmware update control (issue #008).
///
/// Wraps the `UpdateService` resource:
///   * `fetchUpdateService()` reads `ServiceEnabled` / `Version` / `HttpPushUri`
///     and walks the `FirmwareInventory` collection into a flat list of
///     [FirmwareInventoryItem]s.
///   * `startSimpleUpdate()` POSTs to the `#UpdateService.SimpleUpdate` action
///     target and returns the 202 `Location` task URI so the UI can surface a
///     "queued" handle.
///
/// Action-target resolution prefers the discovered [SystemFeatures.raw] tree,
/// then the live `UpdateService` body, then a known URI built from
/// [updateServiceUri]. Network failures are normalized into [RedfishException]
/// using the issue #005 error taxonomy (403 privilege, 409 busy, 400 extended
/// info).
class FirmwareService {
  /// Creates a [FirmwareService] bound to an authenticated [RedfishClient].
  ///
  /// [client] may be `null` for a not-yet-connected system; calls then surface a
  /// friendly [RedfishException] rather than throwing on a `null` receiver.
  /// [features] and [updateServiceUri] help resolve the `UpdateService` URI and
  /// the `#UpdateService.SimpleUpdate` action target.
  FirmwareService({
    required this.client,
    required this.systemId,
    this.features,
    this.updateServiceUri,
  });

  /// Authenticated Redfish client, or `null` when not connected.
  final RedfishClient? client;

  /// The connection profile id (used only as a last-resort URI fallback).
  final String systemId;

  /// Discovered capability map (used to resolve the UpdateService URI).
  final SystemFeatures? features;

  /// Canonical `@odata.id` of the UpdateService resource, when known.
  final String? updateServiceUri;

  /// Default UpdateService path when nothing else is known.
  static const String _defaultServiceUri = '/redfish/v1/UpdateService';

  /// Cached `UpdateService` body so [startSimpleUpdate] avoids a second GET when
  /// [fetchUpdateService] already ran.
  Map<String, dynamic>? _cachedServiceBody;

  /// Reads the [UpdateServiceInfo] plus the fully-resolved firmware inventory.
  ///
  /// GETs the `UpdateService` resource, then walks its `FirmwareInventory`
  /// link: GET the collection, GET each member `SoftwareInventory`, and parse it
  /// into [FirmwareInventoryItem]. Missing inventory is tolerated gracefully
  /// (the returned info simply has an empty [UpdateServiceInfo.inventory]).
  /// Throws [RedfishException] when the system is not connected or when the
  /// `UpdateService` itself cannot be read.
  Future<UpdateServiceInfo> fetchUpdateService() async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; connect before reading '
            'firmware state.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }

    final String uri = await _resolveServiceUri();
    final Map<String, dynamic> body;
    try {
      body = await c.getJson(uri);
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to read UpdateService: $e');
    }
    _cachedServiceBody = body;

    final UpdateServiceInfo base = UpdateServiceInfo.fromJson(body);

    final List<String> inventoryLinks =
        ODataResource(body).linkUris(<String>['FirmwareInventory']);
    if (inventoryLinks.isEmpty) {
      return base;
    }

    final List<FirmwareInventoryItem> items = <FirmwareInventoryItem>[];
    try {
      final Map<String, dynamic> collection =
          await c.getJson(inventoryLinks.first);
      for (final String memberId in ODataResource(collection).memberIds()) {
        try {
          final Map<String, dynamic> member = await c.getJson(memberId);
          items.add(FirmwareInventoryItem.fromJson(member,
              id: _lastSegment(memberId)));
        } on RedfishException {
          // Skip members that cannot be read rather than failing the whole list.
        }
      }
    } on RedfishException {
      // Inventory is optional; return the service info without it.
    }

    return base.copyWithInventory(items);
  }

  /// Convenience accessor returning just the firmware inventory.
  ///
  /// Equivalent to `fetchUpdateService().then((i) => i.inventory)`; useful for
  /// callers that only need the component list.
  Future<List<FirmwareInventoryItem>> fetchInventory() async =>
      (await fetchUpdateService()).inventory;

  /// Starts a firmware update via the `#UpdateService.SimpleUpdate` action.
  ///
  /// Resolves the action target (discovery cache → live body → known URI),
  /// POSTs [req.toJson()], and on a 202 response returns an [UpdateTask]
  /// carrying the `Location` task URI and the optional `Retry-After` seconds
  /// (DSP0266 §12.2 — the delay the service wants the client to wait before
  /// polling the task monitor). Throws [RedfishException] when not connected
  /// or when the BMC rejects the request (403 / 409 / 400 etc.).
  Future<UpdateTask> startSimpleUpdate(SimpleUpdateRequest req) async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; connect before starting a '
            'firmware update.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }

    final String target = await _resolveSimpleUpdateTarget();
    try {
      final Response<dynamic> response = await c.dio.post<dynamic>(
        target,
        data: req.toJson(),
      );
      return UpdateTask(
        taskUri: _headerValue(response.headers, 'location'),
        retryAfterSeconds: _retryAfterSeconds(response.headers),
      );
    } on DioException catch (e) {
      throw _toFriendly(e);
    }
  }

  /// Returns the first value of a response header (case-insensitive), trimmed,
  /// or `null` when the header is absent.
  static String? _headerValue(Headers headers, String name) {
    final String? value = headers.value(name);
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Polls the task monitor a 202 async action returned, until the task
  /// reaches a terminal state or the poll budget is exhausted (issue #022
  /// criterion 1 — 202 task-monitor polling, folding into #008/#020).
  ///
  /// Every [UpdateTask] from [startSimpleUpdate] may carry a `Location` task
  /// monitor URI (DSP0266 §12.2). This method GETs that monitor, parses the
  /// `Task` resource ([RedfishTask]), and returns the final task once
  /// [RedfishTask.isTerminal] is true:
  ///   * [RedfishTask.isSuccess] → returns the finished task;
  ///   * terminal failure → throws [RedfishException] with the task's
  ///     [RedfishTask.failureReason] (first `Message.Message`, then
  ///     `MessageId`, then the bare `TaskState`).
  ///
  /// The first wait honors the `Retry-After` hint the 202 carried
  /// ([UpdateTask.retryAfterSeconds]); subsequent polls wait [interval].
  /// A task that never reaches a terminal state within [maxPolls] polls
  /// throws [RedfishException] (retryable — the caller may poll again).
  /// A task whose [UpdateTask.taskUri] is null/empty has no monitor to poll
  /// (204-no-Location services — the pinned DMTF mockup never returns one);
  /// an explicit [RedfishException] documents that the caller must not treat
  /// a missing monitor as pollable.
  Future<RedfishTask> pollTask(
    UpdateTask task, {
    Duration interval = const Duration(seconds: 2),
    int maxPolls = 30,
  }) async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; cannot poll the task '
            'monitor.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }
    final String? monitorUri = task.taskUri;
    if (monitorUri == null || monitorUri.isEmpty) {
      throw const RedfishException(
        message: 'The BMC returned no task monitor URI (the action '
            'completed synchronously or the service does not publish a '
            'monitor); nothing to poll.',
        errorCode: 'Base.1.0.NoTaskMonitor',
      );
    }

    final Duration firstWait = task.retryAfterSeconds != null
        ? Duration(seconds: task.retryAfterSeconds!)
        : interval;

    for (int i = 0; i < maxPolls; i++) {
      if (i == 0) {
        await Future<void>.delayed(firstWait);
      } else {
        await Future<void>.delayed(interval);
      }

      final Map<String, dynamic> body;
      try {
        body = await c.getJson(monitorUri);
      } on RedfishException catch (e) {
        throw RedfishException(
          message: 'Failed to read the task monitor $monitorUri: '
              '${e.message}',
          statusCode: e.statusCode,
          errorCode: e.errorCode,
          retryable: e.retryable,
          uri: e.uri,
          details: e.details,
        );
      }

      final RedfishTask taskState = RedfishTask.fromJson(body);
      if (taskState.isTerminal) {
        if (taskState.isSuccess) return taskState;
        throw RedfishException(
          message: 'Firmware update task ${taskState.id} failed: '
              '${taskState.failureReason ?? taskState.state}',
          errorCode: 'Update.1.0.UpdateFailed',
          details: RedfishError.tryParse(body),
          raw: body.toString(),
        );
      }
    }

    throw RedfishException(
      message: 'Firmware update task did not complete within $maxPolls '
          'polls; it may still be running. Poll again later.',
      errorCode: 'Update.1.0.TaskMonitorTimeout',
      retryable: true,
    );
  }

  ///
  /// Accepts either a decimal number of seconds or an HTTP-date (converted to
  /// a whole number of seconds from now, clamped to `>= 0`). Returns `null`
  /// when the header is absent or unparseable.
  static int? _retryAfterSeconds(Headers headers) {
    final String? raw = _headerValue(headers, 'retry-after');
    if (raw == null) return null;
    final int? seconds = int.tryParse(raw);
    if (seconds != null) {
      return seconds >= 0 ? seconds : 0;
    }
    final DateTime date;
    try {
      date = HttpDate.parse(raw);
    } catch (_) {
      return null;
    }
    final int diff = date.difference(DateTime.now()).inSeconds;
    return diff >= 0 ? diff : 0;
  }

  /// Resolves the `UpdateService` resource URI.
  Future<String> _resolveServiceUri() async {
    if (updateServiceUri != null && updateServiceUri!.isNotEmpty) {
      return updateServiceUri!;
    }
    final String? fromRaw = _serviceUriFromRaw();
    if (fromRaw != null && fromRaw.isNotEmpty) return fromRaw;
    return _defaultServiceUri;
  }

  /// Resolves the `#UpdateService.SimpleUpdate` action target URI.
  ///
  /// Preference: discovery cache → live `UpdateService` body →
  /// `<serviceUri>/Actions/UpdateService.SimpleUpdate`.
  Future<String> _resolveSimpleUpdateTarget() async {
    final String? fromRaw = _actionTargetFromRaw();
    if (fromRaw != null && fromRaw.isNotEmpty) return fromRaw;

    final String serviceUri = await _resolveServiceUri();
    late Map<String, dynamic> body;
    if (_cachedServiceBody != null) {
      body = _cachedServiceBody!;
    } else {
      try {
        body = await client!.getJson(serviceUri);
        _cachedServiceBody = body;
      } on RedfishException {
        return '$serviceUri/Actions/UpdateService.SimpleUpdate';
      } catch (_) {
        return '$serviceUri/Actions/UpdateService.SimpleUpdate';
      }
    }

    final String? fromBody =
        ODataResource(body).actionTarget('#UpdateService.SimpleUpdate');
    if (fromBody != null && fromBody.isNotEmpty) return fromBody;
    return '$serviceUri/Actions/UpdateService.SimpleUpdate';
  }

  /// Returns the first `UpdateService` `@odata.id` found in the discovery raw
  /// tree, or `null` when absent.
  String? _serviceUriFromRaw() {
    final Map<String, dynamic> raw = features?.raw ?? <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final dynamic value = entry.value;
      if (value is Map<String, dynamic>) {
        final ODataResource res = ODataResource(value);
        if (res.isType('updateservice') &&
            res.id != null &&
            res.id!.isNotEmpty) {
          return res.id;
        }
      }
    }
    return null;
  }

  /// Returns the first `#UpdateService.SimpleUpdate` action target found in the
  /// discovery raw tree, or `null` when absent.
  String? _actionTargetFromRaw() {
    final Map<String, dynamic> raw = features?.raw ?? <String, dynamic>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final dynamic value = entry.value;
      if (value is Map<String, dynamic>) {
        final String? target =
            ODataResource(value).actionTarget('#UpdateService.SimpleUpdate');
        if (target != null && target.isNotEmpty) return target;
      }
    }
    return null;
  }

  /// Extracts the last non-empty path segment of [uri].
  static String _lastSegment(String uri) {
    final List<String> parts =
        uri.split('/').where((String s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : uri;
  }

  /// Translates a [DioException] into a friendly [RedfishException], applying
  /// the issue #008 error taxonomy (403 privilege, 409 busy, 400 extended info).
  RedfishException _toFriendly(DioException e) {
    final Response<dynamic>? response = e.response;
    if (response == null) {
      return RedfishException.fromDioException(e);
    }
    final int? status = response.statusCode;
    if (status == 403) {
      return RedfishException(
        message: 'Insufficient privilege to perform this firmware update.',
        statusCode: 403,
        errorCode: 'Base.1.0.InsufficientPrivilege',
        details: RedfishError.tryParse(response.data),
        raw: response.data?.toString(),
      );
    }
    if (status == 409) {
      return RedfishException(
        message: 'Update service is busy; please retry the update shortly.',
        statusCode: 409,
        errorCode: 'Base.1.0.ResourceInUse',
        details: RedfishError.tryParse(response.data),
        raw: response.data?.toString(),
      );
    }
    if (status == 400) {
      final RedfishError? details = RedfishError.tryParse(response.data);
      final String message = details?.firstMessage ??
          'Invalid update request'
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
