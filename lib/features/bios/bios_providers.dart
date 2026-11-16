import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/bios/bios_controller.dart';
import 'package:redfishopenbmc/features/bios/bios_service.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

/// Provides a [BiosService] bound to the connected [RedfishClient] for
/// [systemId] (issue #028).
///
/// Reads the live [SystemHandle] so the service carries the authenticated
/// client plus discovered [SystemFeatures] / resource URI. When the system is
/// not yet connected the service is still returned with a `null` client so the
/// controller can surface a friendly "not connected" error.
final ProviderFamily<BiosService, String> biosServiceProvider =
    Provider.family<BiosService, String>((ref, String systemId) {
  final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
  return BiosService(
    client: handle?.client,
    systemId: systemId,
    features: handle?.features,
    systemResourceUri: handle?.snapshot?.resourceUri,
  );
});

/// Provides the [BiosController] driving the BIOS screen for [systemId].
///
/// Data is loaded lazily by the view (see [BiosController.load]).
final StateNotifierProviderFamily<BiosController, BiosUiState, String>
    biosControllerProvider =
    StateNotifierProvider.family<BiosController, BiosUiState, String>(
  (ref, String systemId) {
    final BiosService service = ref.watch(biosServiceProvider(systemId));
    return BiosController(service: service);
  },
);
