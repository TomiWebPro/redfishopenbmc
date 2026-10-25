import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/overview/settings_controller.dart';
import 'package:redfishopenbmc/features/overview/settings_service.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

/// Provides a [SystemSettingsService] bound to the connected [RedfishClient]
/// for [systemId].
///
/// Reads the live [SystemHandle] so the service carries the authenticated
/// client plus the discovered [SystemFeatures] (URI resolution) and the
/// snapshot's ComputerSystem `@odata.id`. When the system is not yet connected
/// the service is still returned with a `null` client so the controller can
/// surface a friendly "not connected" error instead of crashing.
final ProviderFamily<SystemSettingsService, String>
    systemSettingsServiceProvider =
    Provider.family<SystemSettingsService, String>((ref, String systemId) {
  final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
  return SystemSettingsService(
    client: handle?.client,
    systemId: systemId,
    features: handle?.features,
    systemResourceUri: handle?.snapshot?.resourceUri,
  );
});

/// Provides the [SystemSettingsController] driving the Boot / IndicatorLED
/// controls for [systemId].
final StateNotifierProviderFamily<SystemSettingsController,
        SystemSettingsUiState, String> systemSettingsControllerProvider =
    StateNotifierProvider.family<SystemSettingsController,
        SystemSettingsUiState, String>(
  (ref, String systemId) {
    final SystemSettingsService service =
        ref.watch(systemSettingsServiceProvider(systemId));
    return SystemSettingsController(service: service);
  },
);
