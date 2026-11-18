import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
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

    test('pickPrimary prefers graphical, else first, else null', () {
      const KvmConsole serial = KvmConsole(
        type: KvmConsoleType.serial,
        managerId: 'BMC',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      const KvmConsole graphical = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(KvmService.pickPrimary(const <KvmConsole>[]), isNull);
      expect(KvmService.pickPrimary(const <KvmConsole>[serial]), same(serial));
      expect(
        KvmService.pickPrimary(const <KvmConsole>[serial, graphical]),
        same(graphical),
      );
    });

    test('throws a RedfishException when not connected', () async {
      final KvmService svc = KvmService(client: null, systemId: 'bmc1');
      expect(() => svc.fetchConsoles(), throwsA(isA<RedfishException>()));
    });
  });

  group('KvmService capability detection (#009)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/dmtf_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    test('fetchCapabilities returns one capability per manager', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(capabilities, isNotEmpty);
      final KvmCapability bmc = capabilities.firstWhere(
        (KvmCapability c) => c.managerId == 'BMC',
      );
      expect(bmc.supported, isTrue);
      expect(bmc.serviceEnabled, isTrue);
      expect(bmc.supportsKvmIp, isTrue);
      expect(bmc.connectTypes, contains('KVMIP'));
      expect(bmc.connectTypes, contains('SSH'));
      expect(bmc.maxSessions, 2);
      expect(
        bmc.sourceManagerUri,
        '/redfish/v1/Managers/BMC',
      );
    });

    test('fetchCapability resolves a manager by id', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final KvmCapability? bmc = await svc.fetchCapability('BMC');
      expect(bmc, isNotNull);
      expect(bmc!.managerId, 'BMC');
      expect(bmc.supported, isTrue);

      expect(await svc.fetchCapability('does-not-exist'), isNull);
    });

    test('capability methods throw when not connected', () async {
      final KvmService svc = KvmService(client: null, systemId: 'bmc1');
      expect(
        () => svc.fetchCapabilities(),
        throwsA(isA<RedfishException>()),
      );
      expect(
        () => svc.fetchCapability('BMC'),
        throwsA(isA<RedfishException>()),
      );
    });
  });

  group('KvmService capability ConnectUri surfacing (#009)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_connecturi_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    test('fetchCapability surfaces a graphical console ConnectUri end-to-end',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final KvmCapability? bmc = await svc.fetchCapability('BMC');
      expect(bmc, isNotNull);
      expect(bmc!.supported, isTrue);
      expect(bmc.serviceEnabled, isTrue);
      expect(bmc.hasUri, isTrue);
      // The actual launchable endpoint (already read by the per-console card)
      // must now be the resolved capability URI, not the manager API link.
      expect(bmc.uri, 'https://bmc.example/kvm');
    });

    test('fetchConsoles and fetchCapabilities agree on the ConnectUri',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmCapability? bmc = await svc.fetchCapability('BMC');
      final KvmConsole graphical = consoles.firstWhere(
        (KvmConsole c) => c.type == KvmConsoleType.graphical,
      );
      expect(graphical.connectUri, 'https://bmc.example/kvm');
      expect(bmc!.uri, graphical.connectUri);
    });
  });

  group('KvmService malformed @odata.id tolerance (#009)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_malformed_odata_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    // RED proof: a manager body with a numeric @odata.id made both the
    // per-console path (KvmConsole.fromManager) and the per-manager path
    // (sourceManagerUri cast in fetchCapabilities) throw a TypeError, blanking
    // the whole KVM screen on a single malformed payload.
    test('fetchConsoles tolerates a non-string manager @odata.id', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      expect(consoles, isNotEmpty);
      expect(
        consoles.every(
          (KvmConsole c) => c.sourceManagerUri == '/redfish/v1/Managers/BMC',
        ),
        isTrue,
      );
    });

    test('fetchCapabilities tolerates a non-string manager @odata.id',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );
      final KvmCapability? bmc = await svc.fetchCapability('BMC');
      expect(bmc, isNotNull);
      expect(bmc!.supported, isTrue);
      expect(bmc.uri, 'https://bmc.example/kvm');
      expect(bmc.sourceManagerUri, '/redfish/v1/Managers/BMC');
    });
  });
}
