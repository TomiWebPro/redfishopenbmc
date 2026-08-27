import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/sensors/sensors_controller.dart';
import 'package:redfishopenbmc/features/sensors/sensors_service.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

/// Provides a [SensorsService] bound to the connected [RedfishClient] for
/// [systemId].
///
/// Reads the live [SystemHandle] so the service carries the authenticated client
/// plus the discovered [SystemFeatures] (capability gating). When the system is
/// not yet connected the service is still returned with a `null` client so the
/// controller can surface a friendly "not connected" error instead of crashing.
final ProviderFamily<SensorsService, String> sensorsServiceProvider =
    Provider.family<SensorsService, String>((ref, String systemId) {
  final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
  return SensorsService(
    client: handle?.client,
    systemId: systemId,
    features: handle?.features,
  );
});

/// Provides the [SensorsController] driving the sensor screen for [systemId].
///
/// The controller starts from an empty [SensorsUiState]; the view triggers the
/// initial [SensorsController.load] once the capability gate passes.
final StateNotifierProviderFamily<SensorsController, SensorsUiState, String>
    sensorsControllerProvider =
    StateNotifierProvider.family<SensorsController, SensorsUiState, String>(
  (ref, String systemId) {
    final SensorsService service = ref.watch(sensorsServiceProvider(systemId));
    return SensorsController(service: service);
  },
);
