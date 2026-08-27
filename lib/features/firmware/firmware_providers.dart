import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/firmware/firmware_controller.dart';
import 'package:redfishopenbmc/features/firmware/firmware_service.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

/// Provides a [FirmwareService] bound to the connected [RedfishClient] for
/// [systemId].
///
/// Reads the live [SystemHandle] so the service carries the authenticated client
/// plus the discovered [SystemFeatures] (action-target resolution). When the
/// system is not yet connected the service is still returned with a `null`
/// client so the controller can surface a friendly "not connected" error
/// instead of crashing.
final ProviderFamily<FirmwareService, String> firmwareServiceProvider =
    Provider.family<FirmwareService, String>((ref, String id) {
  final SystemHandle? handle = ref.watch(systemHandleProvider(id));
  return FirmwareService(
    client: handle?.client,
    systemId: id,
    features: handle?.features,
  );
});

/// Provides the [FirmwareController] driving the firmware screen for [systemId].
///
/// The initial state is empty; the controller's [FirmwareController.load] is
/// invoked by the view on first build to populate the [UpdateServiceInfo].
final StateNotifierProviderFamily<FirmwareController, FirmwareUiState, String>
    firmwareControllerProvider =
    StateNotifierProvider.family<FirmwareController, FirmwareUiState, String>(
  (ref, String id) {
    final FirmwareService service = ref.watch(firmwareServiceProvider(id));
    final SystemHandle? handle = ref.watch(systemHandleProvider(id));
    return FirmwareController(
      service: service,
      features: handle?.features,
    );
  },
);
