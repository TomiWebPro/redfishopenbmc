import 'package:file_selector/file_selector.dart';
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

/// The local-image picker for the push-upload flow (#008/#020).
///
/// Returns the picked image file, or `null` when the user cancels the dialog.
typedef FirmwareImagePicker = Future<XFile?> Function();

/// Provides the [FirmwareImagePicker] the firmware view drives the
/// `HttpPushUri` / `MultipartHttpPushUri` push-upload flow with (#008/#020).
///
/// The default opens the system file dialog (`file_selector.openFile`,
/// desktop + web) filtered to common firmware-image extensions; the view never
/// assumes an apply time or any other parameter of the picked file.
///
/// Widget tests override this provider so `flutter test` never opens a real
/// dialog — the factory is only invoked on press.
final Provider<FirmwareImagePicker> firmwareImagePickerProvider =
    Provider<FirmwareImagePicker>((ref) {
  return () => openFile(acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(
          label: 'Firmware image',
          extensions: <String>['bin', 'rom', 'img', 'iso', 'tar', 'gz'],
        ),
      ]);
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
