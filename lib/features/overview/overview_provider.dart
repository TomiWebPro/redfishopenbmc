import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_service.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/client/redfish_client.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';

/// Per-system overview data, schema-driven and always available (issue #006).
///
/// Hydrates from the live [SystemHandle] via [OverviewService], which walks
/// `GET /redfish/v1/Systems` → ComputerSystem → (best-effort) chassis thermal.
///
/// Caching: Riverpod keeps the resolved value in memory until [ref.refresh] is
/// called (pull-to-refresh, auto-poll every 30s, or a power-state change in the
/// shell). Every refresh re-fetches, so there is no stale-data hazard.
final FutureProviderFamily<SystemOverview, String> overviewProvider =
    FutureProvider.family<SystemOverview, String>((ref, String systemId) async {
  final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
  final RedfishClient? client = handle?.client;
  if (client == null) {
    throw RedfishException(
      message: 'No active session for "$systemId"; connect first.',
      errorCode: 'Base.1.0.NotConnected',
    );
  }
  try {
    return await OverviewService(client).fetchOverview();
  } on RedfishException {
    rethrow;
  } catch (e) {
    throw RedfishException(message: 'Overview fetch failed: $e');
  }
});
