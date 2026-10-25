import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Fetches the per-system [SystemOverview] (issue #006).
///
/// Hydration walks the Redfish service the same way discovery does — never
/// hardcoding beyond the entry collection:
///
///  1. `GET /redfish/v1/Systems` → first `Members[*].@odata.id`
///  2. `GET {systemUri}` → ComputerSystem identity/health/power/summaries
///  3. (best-effort) `GET {Links.Chassis[0]}/Thermal` → leading temperature
///
/// The temperature fetch is best-effort: any failure (missing chassis link,
/// missing `Thermal`, transport error) degrades to "no temperature" rather than
/// failing the whole overview, in keeping with the "nothing is assumed" rule.
class OverviewService {
  /// Creates an [OverviewService] bound to an authenticated [RedfishClient].
  const OverviewService(this.client);

  /// Authenticated Redfish client (must be non-null and connected).
  final RedfishClient client;

  /// Fetches and assembles the [SystemOverview] for the connected system.
  ///
  /// Throws [RedfishException] when no ComputerSystem is reported (404-style) or
  /// when the root collection call itself fails.
  Future<SystemOverview> fetchOverview() async {
    final Map<String, dynamic> root =
        await client.getJson('/redfish/v1/Systems');
    final List<dynamic> members =
        (root['Members'] as List<dynamic>?) ?? const <dynamic>[];
    if (members.isEmpty) {
      throw RedfishException(
        message: 'This BMC reported no ComputerSystems to summarize.',
        errorCode: 'Base.1.0.ResourceMissing',
        statusCode: 404,
        uri: Uri.tryParse('${client.profile.baseUrl}/redfish/v1/Systems'),
      );
    }

    final dynamic first = members.first;
    final String systemUri;
    if (first is Map<dynamic, dynamic>) {
      final dynamic id = first['@odata.id'];
      systemUri = id is String && id.isNotEmpty ? id : '/redfish/v1/Systems/1';
    } else {
      systemUri = '/redfish/v1/Systems/1';
    }

    final Map<String, dynamic> systemJson = await client.getJson(systemUri);

    Map<String, dynamic>? thermalJson;
    final dynamic links = systemJson['Links'];
    final Map<String, dynamic> linksMap =
        links is Map<String, dynamic> ? links : const <String, dynamic>{};
    final dynamic chassisList = linksMap['Chassis'];
    final String? chassisUri;
    if (chassisList is List<dynamic> && chassisList.isNotEmpty) {
      final dynamic firstChassis = chassisList.first;
      if (firstChassis is Map<dynamic, dynamic>) {
        final dynamic cid = firstChassis['@odata.id'];
        chassisUri = cid is String && cid.isNotEmpty ? cid : null;
      } else {
        chassisUri = null;
      }
    } else {
      chassisUri = null;
    }

    if (chassisUri != null) {
      try {
        final Map<String, dynamic> thermal =
            await client.getJson('$chassisUri/Thermal');
        thermalJson = thermal;
      } on RedfishException {
        // Best-effort only — fall back to no temperature preview.
        thermalJson = null;
      } catch (_) {
        thermalJson = null;
      }
    }

    return SystemOverview.fromSystemJson(
      systemJson,
      thermalJson: thermalJson,
      resourceUri: systemUri,
    );
  }
}
