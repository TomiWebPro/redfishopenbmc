import 'package:redfishopenbmc/features/overview/models/boot_settings.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/odata.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// The DSP0266 `BootSourceOverrideEnabled` values a PATCH accepts (the schema
/// `BootSourceOverrideEnabled` enum of `ComputerSystem.v1_22_0`).
const List<String> kBootOverrideEnabledValues = <String>[
  'Once',
  'Continuous',
  'Disabled',
];

/// Applies safe, spec-compliant PATCH mutations to the ComputerSystem resource
/// (issue #016 — the concrete Boot/IndicatorLED mutation feature).
///
/// The DSP0266 §6.5.2 partial-update transport, the If-Match / `@odata.etag`
/// precondition wiring, and the pre-validation corollary are all in place on
/// [RedfishClient.patchJson]; this service is the first production consumer:
///
///  * [setIndicatorLed] PATCHes `IndicatorLED` — pre-validated against the
///    schema enum (`Lit` / `Blinking` / `Off`, the writable values of
///    `ComputerSystem.v1_22_0`; `Unknown` is deprecated and not writable);
///  * [setBootOverride] PATCHes `Boot.BootSourceOverrideTarget` +
///    `BootSourceOverrideEnabled` — the target pre-validated against the
///    advertised `@Redfish.AllowableValues` annotation, and the enabled state
///    against the schema enum. When the BMC publishes no target allow-list the
///    mutation is refused locally (never guess targets — the DMTF mockup
///    applies ANY PATCH body unvalidated, so the client-side rule is the only
///    enforcement).
///
/// The ComputerSystem resource URI is resolved with the established
/// preference: discovery raw tree → known [systemResourceUri] → live
/// `/redfish/v1/Systems` crawl → canonical fallback (see [PowerService]).
class SystemSettingsService {
  /// Creates a [SystemSettingsService] for the system identified by
  /// [systemId].
  SystemSettingsService({
    required this.client,
    required this.systemId,
    this.features,
    this.systemResourceUri,
  });

  /// Authenticated Redfish client, or `null` when not connected.
  final RedfishClient? client;

  /// The connection profile id (used only as a last-resort URI fallback).
  final String systemId;

  /// Discovered capability map (used to resolve the ComputerSystem URI from
  /// the raw tree).
  final SystemFeatures? features;

  /// Canonical `@odata.id` of the ComputerSystem resource, when known.
  final String? systemResourceUri;

  /// Fetches the current [BootSettings] by reading the ComputerSystem resource.
  ///
  /// Throws [RedfishException] when not connected or the resource is
  /// unreachable; a missing `Boot` block yields an all-null [BootSettings]
  /// (never a throw) so the caller can render "not exposed".
  Future<BootSettings> fetchBootSettings() async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; cannot read boot settings.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }
    final String uri = await _resolveSystemUri();
    try {
      final Map<String, dynamic> body = await c.getJson(uri);
      return BootSettings.fromRedfish(body);
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to read boot settings: $e');
    }
  }

  /// PATCHes the ComputerSystem `IndicatorLED` property to [value].
  ///
  /// Pre-validates [value] against the schema enum (only [IndicatorLed.lit],
  /// [IndicatorLed.off], [IndicatorLed.blinking] are writable); [value] of
  /// [IndicatorLed.unknown] (or any future non-writable state) is rejected
  /// locally with a 400-style [RedfishException] — never sent to the BMC (the
  /// mockup applies ANY body unvalidated, so this guard is the enforcement).
  ///
  /// Returns the response body (usually empty for 204). When the read-back
  /// resource carried an `@odata.etag`, it is sent as the `If-Match`
  /// precondition so a stale write is answered 412 instead of overwriting.
  Future<Map<String, dynamic>> setIndicatorLed(IndicatorLed value) async {
    final String? redfishValue = value.toRedfish;
    if (redfishValue == null) {
      throw RedfishException(
        message: 'IndicatorLED state "${value.label}" is not a writable PATCH '
            'value. Writable: ${IndicatorLed.writableValues.join(", ")}.',
        statusCode: 400,
        errorCode: 'Base.1.0.PropertyValueNotInList',
      );
    }
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; cannot set IndicatorLED.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }
    final String uri = await _resolveSystemUri();
    try {
      final Map<String, dynamic> current = await c.getJson(uri);
      final String? etag = ODataResource(current).etag;
      return await c.patchJson(
        uri,
        body: <String, dynamic>{'IndicatorLED': redfishValue},
        etag: etag,
      );
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to set IndicatorLED: $e');
    }
  }

  /// PATCHes the ComputerSystem `Boot` override to boot [target] with
  /// [enabled] state.
  ///
  /// Pre-validates:
  ///  * [target] against the advertised
  ///    `BootSourceOverrideTarget@Redfish.AllowableValues` annotation — when
  ///    the BMC publishes none, the mutation is refused locally (never guess
  ///    targets; the DMTF mockup applies any value unvalidated);
  ///  * [enabled] against the schema enum (`Once` / `Continuous` /
  ///    `Disabled`), defaulting to `Once` (a one-time override — the schema
  ///    default behaviour).
  ///
  /// Returns the response body (usually empty for 204). When the read-back
  /// resource carried an `@odata.etag`, it is sent as the `If-Match`
  /// precondition.
  Future<Map<String, dynamic>> setBootOverride({
    required String target,
    String enabled = 'Once',
  }) async {
    final RedfishClient? c = client;
    if (c == null) {
      throw RedfishException(
        message: 'Not connected to "$systemId"; cannot set boot override.',
        errorCode: 'Base.1.0.NotConnected',
      );
    }
    if (!kBootOverrideEnabledValues.contains(enabled)) {
      throw RedfishException(
        message: 'Boot override state "$enabled" is not a valid '
            'BootSourceOverrideEnabled value. Valid: '
            '${kBootOverrideEnabledValues.join(", ")}.',
        statusCode: 400,
        errorCode: 'Base.1.0.PropertyValueNotInList',
      );
    }

    final String uri = await _resolveSystemUri();
    final Map<String, dynamic> current;
    try {
      current = await c.getJson(uri);
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to read boot settings: $e');
    }

    final BootSettings settings = BootSettings.fromRedfish(current);
    if (!settings.hasAllowableTargets) {
      throw const RedfishException(
        message: 'This BMC published no BootSourceOverrideTarget '
            'AllowableValues; a boot override cannot be applied safely.',
        statusCode: 400,
        errorCode: 'Base.1.0.PropertyNotWritable',
      );
    }
    if (!settings.allows(target)) {
      throw RedfishException(
        message: 'Boot target "$target" is not supported by this system. '
            'Supported: ${settings.allowableTargets.join(", ")}.',
        statusCode: 400,
        errorCode: 'Base.1.0.PropertyValueNotInList',
      );
    }

    final String? etag = ODataResource(current).etag;
    try {
      return await c.patchJson(
        uri,
        body: <String, dynamic>{
          'Boot': <String, dynamic>{
            'BootSourceOverrideTarget': target,
            'BootSourceOverrideEnabled': enabled,
          },
        },
        etag: etag,
      );
    } on RedfishException {
      rethrow;
    } catch (e) {
      throw RedfishException(message: 'Failed to set boot override: $e');
    }
  }

  /// Resolves the ComputerSystem resource URI.
  ///
  /// Preference: discovery raw tree → known [systemResourceUri] → live
  /// `/redfish/v1/Systems` crawl → canonical fallback built from [systemId].
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

  /// Crawls `/redfish/v1/Systems` and returns the first ComputerSystem
  /// `@odata.id`, or `null` when the collection is empty / unreachable.
  Future<String?> _liveSystemUri() async {
    final RedfishClient? c = client;
    if (c == null) return null;
    try {
      final Map<String, dynamic> root = await c.getJson('/redfish/v1/Systems');
      final List<dynamic> members =
          (root['Members'] as List<dynamic>?) ?? <dynamic>[];
      if (members.isEmpty) return null;
      final dynamic first = members.first;
      if (first is Map<dynamic, dynamic>) {
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
