import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';

/// Provides a [KvmService] bound to the connected [RedfishClient] for
/// [systemId].
///
/// Reads the live [SystemHandle] so the service carries the authenticated client
/// plus the discovered [SystemFeatures] (KVM gating). When the system is not yet
/// connected the service is still returned with a `null` client so that the
/// controller can surface a friendly "not connected" error instead of crashing.
final ProviderFamily<KvmService, String> kvmServiceProvider =
    Provider.family<KvmService, String>((ref, String systemId) {
  final SystemHandle? handle = ref.watch(systemHandleProvider(systemId));
  return KvmService(
    client: handle?.client,
    systemId: systemId,
    features: handle?.features,
  );
});

/// Provides the [KvmController] driving the KVM screen for [systemId].
///
/// The controller is seeded with the [KvmService] resolved from the live
/// [SystemHandle]; console data is loaded lazily by the view (see [KvmView]).
final StateNotifierProviderFamily<KvmController, KvmUiState, String>
    kvmControllerProvider =
    StateNotifierProvider.family<KvmController, KvmUiState, String>(
  (ref, String systemId) {
    final KvmService service = ref.watch(kvmServiceProvider(systemId));
    return KvmController(service: service);
  },
);

/// Per-manager KVM capability summaries for [systemId] (issue #009).
///
/// Walks `/redfish/v1/Managers` once via [KvmService.fetchCapabilities] and
/// returns one [KvmCapability] per manager. Capability cards are a supplementary
/// summary — a discovery/transport failure degrades to an empty list so the
/// controller's console list remains the single source of the surfaced error.
/// Read-only: no URL is opened, no IPC is performed and no transport security is
/// changed.
final FutureProviderFamily<List<KvmCapability>, String>
    kvmCapabilitiesProvider =
    FutureProvider.family<List<KvmCapability>, String>(
  (ref, String systemId) async {
    final KvmService service = ref.watch(kvmServiceProvider(systemId));
    try {
      return await service.fetchCapabilities();
    } catch (_) {
      return <KvmCapability>[];
    }
  },
);
