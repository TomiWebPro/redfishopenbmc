import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Provider-level guards for the KVM Riverpod wiring (issue #009).
///
/// Every existing KVM widget test overrides `kvmServiceProvider` /
/// `kvmCapabilitiesProvider` with a fake, so the REAL provider bodies — the
/// service binding and the "capability cards are a supplementary summary"
/// error-degradation contract — were never exercised. These tests drive the
/// actual provider graph (only the upstream `systemHandleProvider` is
/// overridden) so a refactor that drops the service binding or the
/// `fetchCapabilities` error swallow is caught rather than slipping green.
///
/// All paths here use a NOT-CONNECTED handle (null client): no URL is opened,
/// no transport is started, no self-signed cert is accepted and production TLS
/// is never touched. Pure provider wiring + error degradation only.
SystemHandle _handle({bool withFeatures = true}) => SystemHandle(
      profile: const ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: withFeatures
          ? const SystemFeatures(systemId: 'bmc1', kvm: true)
          : null,
    );

ProviderContainer _containerWith(SystemHandle? handle) => ProviderContainer(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(handle),
      ],
    );

void main() {
  test('kvmServiceProvider binds a KvmService to the live handle', () {
    final ProviderContainer container = _containerWith(_handle());
    addTearDown(container.dispose);

    final KvmService service = container.read(kvmServiceProvider('bmc1'));
    expect(service, isA<KvmService>());
    expect(service.systemId, 'bmc1');
    // The handle carries no client in this offline test — the binding must
    // still carry that null through so the controller surfaces the friendly
    // "not connected" error rather than crashing on a null receiver.
    expect(service.client, isNull);
    expect(service.features?.kvm, isTrue);
  });

  test('kvmServiceProvider still returns a service for an unknown system', () {
    final ProviderContainer container = _containerWith(null);
    addTearDown(container.dispose);

    final KvmService service = container.read(kvmServiceProvider('bmc1'));
    expect(service, isA<KvmService>());
    expect(service.systemId, 'bmc1');
    expect(service.client, isNull);
    expect(service.features, isNull);
  });

  test('kvmCapabilitiesProvider degrades a failed discovery to an empty list',
      () async {
    // With a null client, KvmService.fetchCapabilities() throws a
    // RedfishException("Not connected"). Capability cards are a supplementary
    // summary: that failure must be swallowed into an empty list so the
    // controller's console list stays the single source of the surfaced error
    // (see kvmCapabilitiesProvider doc). Removing the try/catch makes the
    // returned future complete with the error — this test fails closed.
    final ProviderContainer container = _containerWith(_handle());
    addTearDown(container.dispose);

    await expectLater(
      container.read(kvmCapabilitiesProvider('bmc1').future),
      completion(isEmpty),
    );
  });

  test('kvmCapabilitiesProvider also swallows a non-Redfish failure', () async {
    // The degradation is intentionally broad: a transport/Dio error is
    // normalised by the service into a RedfishException, and any other
    // unexpected error must likewise degrade to an empty list rather than
    // surface an unhandled error on the supplementary capability section.
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmServiceProvider.overrideWith(
          (ref, id) => _ThrowingKvmService(systemId: id),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(kvmCapabilitiesProvider('bmc1').future),
      completion(isEmpty),
    );
  });
}

/// A [KvmService] whose capability fetch throws an unexpected (non-Redfish)
/// error, exercising the broad branch of the provider's degradation contract.
class _ThrowingKvmService extends KvmService {
  _ThrowingKvmService({required String systemId})
      : super(client: null, systemId: systemId);

  @override
  Future<List<Never>> fetchCapabilities() async {
    throw StateError('unexpected capability failure');
  }
}
