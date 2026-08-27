import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Fetches a [SystemSnapshot] for the system behind [client].
///
/// Walks `GET /redfish/v1/Systems` → first member `@odata.id` → reads
/// `Status.Health`, `PowerState`, `Manufacturer`, `Model`, `SerialNumber`.
/// Failures degrade gracefully to a snapshot with [Health.unknown] and a
/// populated [SystemSnapshot.error] rather than throwing.
Future<SystemSnapshot> fetchSystemSnapshot(RedfishClient client) async {
  try {
    final Map<String, dynamic> root =
        await client.getJson('/redfish/v1/Systems');
    final List<dynamic> members =
        (root['Members'] as List<dynamic>?) ?? <dynamic>[];
    if (members.isEmpty) {
      return const SystemSnapshot(error: 'No ComputerSystems reported');
    }
    final Map<String, dynamic> first = members.first as Map<String, dynamic>;
    final String odataId =
        (first['@odata.id'] as String?) ?? '/redfish/v1/Systems/1';
    final Map<String, dynamic> system = await client.getJson(odataId);
    return SystemSnapshot.fromSystemJson(system);
  } on RedfishException catch (e) {
    return SystemSnapshot(health: Health.unknown, error: e.message);
  } catch (e) {
    return SystemSnapshot(health: Health.unknown, error: e.toString());
  }
}
