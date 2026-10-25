import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/power/models/power_state.dart';
import 'package:redfishopenbmc/features/power/power_controller.dart';
import 'package:redfishopenbmc/features/power/power_service.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

/// Provides a [PowerService] bound to the connected [RedfishClient] for
/// [systemId].
///
/// Reads the live [SystemHandle] so the service carries the authenticated client
/// plus the discovered [SystemFeatures] (reset-type gating) and the snapshot's
/// ComputerSystem `@odata.id` (action-target resolution). When the system is not
/// yet connected the service is still returned with a `null` client so that the
/// controller can surface a friendly "not connected" error instead of crashing.
final ProviderFamily<PowerService, String> powerServiceProvider =
    Provider.family<PowerService, String>((ref, String systemId) {
  final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
  return PowerService(
    client: handle?.client,
    systemId: systemId,
    features: handle?.features,
    systemResourceUri: handle?.snapshot?.resourceUri,
  );
});

/// Provides the [PowerController] driving the power screen for [systemId].
///
/// The initial [PowerUiState.powerState] is projected from the live snapshot so
/// the badge reflects reality on first paint; subsequent updates come from the
/// controller's polling loop after a reset.
final StateNotifierProviderFamily<PowerController, PowerUiState, String>
    powerControllerProvider =
    StateNotifierProvider.family<PowerController, PowerUiState, String>(
  (ref, String systemId) {
    final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
    final PowerService service = ref.watch(powerServiceProvider(systemId));
    final PowerState initial =
        handle?.snapshot?.powerState ?? PowerState.unknown;
    return PowerController(
      service: service,
      features: handle?.features,
      initialState: PowerUiState(powerState: initial),
    );
  },
);
