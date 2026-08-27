import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

import '../../helpers/mock_redfish_server.dart';

void main() {
  group('KvmService against the DMTF mock server', () {
    late MockRedfishServer server;

    setUpAll(() async {
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/dmtf_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    test('fetchConsoles returns consoles discovered from /redfish/v1/Managers',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
        features: const SystemFeatures(systemId: 'bmc1', kvm: true),
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();

      expect(consoles, isNotEmpty);
      expect(
        consoles.any((KvmConsole c) => c.type == KvmConsoleType.graphical),
        isTrue,
      );
      final KvmConsole graphical = consoles.firstWhere(
        (KvmConsole c) => c.type == KvmConsoleType.graphical,
      );
      expect(graphical.connectTypesSupported, contains('KVMIP'));
      expect(graphical.managerId, 'BMC');
    });

    test('fetchPrimaryConsole prefers the graphical console', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final KvmConsole? primary = await svc.fetchPrimaryConsole();
      expect(primary, isNotNull);
      expect(primary!.type, KvmConsoleType.graphical);
    });

    test('throws a RedfishException when not connected', () async {
      final KvmService svc = KvmService(client: null, systemId: 'bmc1');
      expect(() => svc.fetchConsoles(), throwsA(isA<RedfishException>()));
    });
  });
}
