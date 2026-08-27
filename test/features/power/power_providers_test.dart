import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/features/power/power_controller.dart';
import 'package:redfishopenbmc/features/power/power_providers.dart';
import 'package:redfishopenbmc/features/power/power_service.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// Builds a [SystemManager] pre-wired with deterministic login/discovery/
/// snapshot doubles so the power providers can be exercised without network.
SystemManager connectedManager() => SystemManager(
      repository: InMemoryProfileRepository(),
      storage: InMemoryStorage(),
      loginOverride: (id, p) async => Session(
        systemId: id,
        token: 'tok',
        location: '',
        username: p.username ?? '',
        createdAt: DateTime.now(),
      ),
      discoverOverride: (c, id) async => SystemFeatures(
        systemId: id,
        powerControl: true,
        supportedResetTypes: const <String>[
          'On',
          'ForceOff',
          'GracefulRestart',
          'ForceRestart',
        ],
      ),
      snapshotOverride: (c, id) async => const SystemSnapshot(
        health: Health.ok,
        powerState: PowerState.off,
        resourceUri: '/redfish/v1/Systems/system',
      ),
    );

void main() {
  test('powerServiceProvider binds a PowerService to the connected handle',
      () async {
    final SystemManager manager = connectedManager();
    await manager.addProfile(
      const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
    );
    await manager.connect('bmc1');

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        systemManagerProvider.overrideWith((ref) => manager),
      ],
    );
    addTearDown(container.dispose);

    final PowerService svc = container.read(powerServiceProvider('bmc1'));
    expect(svc, isA<PowerService>());
    expect(svc.client, isNotNull);
    expect(svc.features?.powerControl, isTrue);
    expect(svc.systemResourceUri, '/redfish/v1/Systems/system');
  });

  test('powerControllerProvider seeds UI state from the snapshot', () async {
    final SystemManager manager = connectedManager();
    await manager.addProfile(
      const ConnectionProfile(id: 'bmc1', host: 'h', name: 'A'),
    );
    await manager.connect('bmc1');

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        systemManagerProvider.overrideWith((ref) => manager),
      ],
    );
    addTearDown(container.dispose);

    final PowerController controller =
        container.read(powerControllerProvider('bmc1').notifier);
    expect(controller.state.powerState, PowerState.off);
  });

  test('providers degrade gracefully for an unknown system', () {
    final SystemManager manager = connectedManager();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        systemManagerProvider.overrideWith((ref) => manager),
      ],
    );
    addTearDown(container.dispose);

    final PowerService svc = container.read(powerServiceProvider('ghost'));
    expect(svc.client, isNull);
    expect(svc.features, isNull);

    final PowerController controller =
        container.read(powerControllerProvider('ghost').notifier);
    expect(controller, isA<PowerController>());
    expect(controller.state.powerState, PowerState.unknown);
  });
}
