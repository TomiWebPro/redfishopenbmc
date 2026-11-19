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

  group('KvmService.pickPrimary launchability (#009)', () {
    KvmConsole console(
      KvmConsoleType type, {
      required bool enabled,
      String? uri,
      String id = 'A',
    }) =>
        KvmConsole(
          type: type,
          managerId: id,
          serviceEnabled: enabled,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/$id',
        );

    test('prefers an enabled graphical console over a disabled one', () {
      final KvmConsole disabled = console(
        KvmConsoleType.graphical,
        enabled: false,
        uri: 'https://bmc.example/kvm-disabled',
        id: 'disabled',
      );
      final KvmConsole enabled = console(
        KvmConsoleType.graphical,
        enabled: true,
        uri: 'https://bmc.example/kvm',
        id: 'enabled',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[disabled, enabled]),
        same(enabled),
      );
    });

    test('prefers an enabled URI-bearing serial over a URI-less graphical', () {
      final KvmConsole uriLessGraphical = console(
        KvmConsoleType.graphical,
        enabled: true,
        id: 'uri-less',
      );
      final KvmConsole launchableSerial = console(
        KvmConsoleType.serial,
        enabled: true,
        uri: 'ssh://bmc.example',
        id: 'serial',
      );
      expect(
        KvmService.pickPrimary(
          <KvmConsole>[uriLessGraphical, launchableSerial],
        ),
        same(launchableSerial),
      );
    });

    test('prefers a launchable serial over a non-launchable graphical', () {
      final KvmConsole disabledGraphical = console(
        KvmConsoleType.graphical,
        enabled: false,
        uri: 'https://bmc.example/kvm-disabled',
        id: 'graphical',
      );
      final KvmConsole launchableSerial = console(
        KvmConsoleType.serial,
        enabled: true,
        uri: 'ssh://bmc.example',
        id: 'serial',
      );
      expect(
        KvmService.pickPrimary(
          <KvmConsole>[disabledGraphical, launchableSerial],
        ),
        same(launchableSerial),
      );
    });

    test('prefers the first enabled URI-bearing graphical console', () {
      final KvmConsole serial = console(
        KvmConsoleType.serial,
        enabled: true,
        uri: 'ssh://bmc.example',
        id: 'serial',
      );
      final KvmConsole graphical = console(
        KvmConsoleType.graphical,
        enabled: true,
        uri: 'https://bmc.example/kvm',
        id: 'graphical',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[serial, graphical]),
        same(graphical),
      );
    });

    test('falls back to the first graphical when none is launchable', () {
      final KvmConsole serial = console(
        KvmConsoleType.serial,
        enabled: false,
        id: 'serial',
      );
      final KvmConsole graphical = console(
        KvmConsoleType.graphical,
        enabled: false,
        id: 'graphical',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[serial, graphical]),
        same(graphical),
      );
    });

    test('returns null for an empty list', () {
      expect(KvmService.pickPrimary(const <KvmConsole>[]), isNull);
    });
  });

  group('KvmService.pickPrimary prefers a safe external-browser target (#021)',
      () {
    KvmConsole console(
      KvmConsoleType type, {
      required bool enabled,
      String? uri,
      String id = 'A',
    }) =>
        KvmConsole(
          type: type,
          managerId: id,
          serviceEnabled: enabled,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/$id',
        );

    test(
        'prefers a secure-HTTPS graphical over a plaintext-HTTP graphical '
        'listed first', () {
      final KvmConsole plaintext = console(
        KvmConsoleType.graphical,
        enabled: true,
        uri: 'http://bmc.example/kvm',
        id: 'plaintext',
      );
      final KvmConsole secure = console(
        KvmConsoleType.graphical,
        enabled: true,
        uri: 'https://bmc.example/kvm',
        id: 'secure',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[plaintext, secure]),
        same(secure),
      );
    });

    test('prefers a secure-HTTPS console over an external-client (SSH) console',
        () {
      final KvmConsole external = console(
        KvmConsoleType.serial,
        enabled: true,
        uri: 'ssh://bmc.example',
        id: 'external',
      );
      final KvmConsole secure = console(
        KvmConsoleType.remote,
        enabled: true,
        uri: 'https://bmc.example/kvm',
        id: 'secure',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[external, secure]),
        same(secure),
      );
    });

    test('prefers a secure-HTTPS graphical over a secure non-graphical', () {
      final KvmConsole secureRemote = console(
        KvmConsoleType.remote,
        enabled: true,
        uri: 'https://bmc.example/kvm',
        id: 'secure-remote',
      );
      final KvmConsole secureGraphical = console(
        KvmConsoleType.graphical,
        enabled: true,
        uri: 'https://bmc.example/kvm-ip',
        id: 'secure-graphical',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[secureRemote, secureGraphical]),
        same(secureGraphical),
      );
    });

    test(
        'guard: with no secure console, keeps the first openable graphical '
        '(plaintext preserved)', () {
      final KvmConsole plaintextGraphical = console(
        KvmConsoleType.graphical,
        enabled: true,
        uri: 'http://bmc.example/kvm',
        id: 'plaintext',
      );
      final KvmConsole externalSerial = console(
        KvmConsoleType.serial,
        enabled: true,
        uri: 'ssh://bmc.example',
        id: 'external',
      );
      expect(
        KvmService.pickPrimary(
          <KvmConsole>[plaintextGraphical, externalSerial],
        ),
        same(plaintextGraphical),
      );
    });

    test(
        'guard: a disabled secure-HTTPS console is not preferred over an '
        'enabled plaintext one', () {
      final KvmConsole disabledSecure = console(
        KvmConsoleType.graphical,
        enabled: false,
        uri: 'https://bmc.example/kvm-disabled',
        id: 'disabled-secure',
      );
      final KvmConsole enabledPlaintext = console(
        KvmConsoleType.graphical,
        enabled: true,
        uri: 'http://bmc.example/kvm',
        id: 'enabled-plaintext',
      );
      expect(
        KvmService.pickPrimary(<KvmConsole>[disabledSecure, enabledPlaintext]),
        same(enabledPlaintext),
      );
    });
  });

  group('KvmService stale manager member resilience (#009)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      // The Managers collection has one healthy manager (BMC) and one stale
      // member (STALE) whose body file is intentionally absent — the mock
      // server answers 404 for it, as a real BMC does for a removed manager.
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_stale_manager_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    // RED proof: a single 404 manager member aborted the whole walk, so both
    // fetchConsoles and fetchCapabilities threw and the gated KVM screen was
    // blanked even though the healthy manager exposed a launchable console.
    test('fetchConsoles skips a 404 manager member and keeps healthy consoles',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();

      expect(consoles, isNotEmpty);
      expect(consoles.every((KvmConsole c) => c.managerId == 'BMC'), isTrue);
      expect(
        consoles.any((KvmConsole c) =>
            c.type == KvmConsoleType.graphical && c.canOpenConsole),
        isTrue,
      );
    });

    test(
        'fetchCapabilities skips a 404 manager member and keeps the healthy capability',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(capabilities, hasLength(1));
      expect(capabilities.single.managerId, 'BMC');
      expect(capabilities.single.supported, isTrue);
      expect(capabilities.single.hasUri, isTrue);
    });
  });

  group('KvmService malformed Members tolerance (#009)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      // The Managers collection advertises a non-list `Members` member (a
      // malformed but not-unseen BMC payload). It must be treated as "no
      // managers discovered" rather than throwing a TypeError that blanks the
      // whole gated KVM screen (issue #009).
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_malformed_members_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    // RED proof: a bare `root['Members'] as List<dynamic>?` cast throws a
    // TypeError on the non-list value; the generic catch turns it into a
    // RedfishException, so both KVM views are blanked by one malformed payload.
    test('fetchConsoles tolerates a non-list Members collection', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      expect(consoles, isEmpty);
    });

    test('fetchCapabilities tolerates a non-list Members collection', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(capabilities, isEmpty);
    });
  });

  group('KvmService padded member URI tolerance (#009)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      // The Managers collection exposes one healthy manager whose `@odata.id`
      // is surrounded by whitespace (a malformed-but-seen BMC payload) plus a
      // whitespace-only plain-string member. The padded link must be trimmed so
      // the manager (and its console) is still discovered; the blank member must
      // be skipped rather than fetched. Mirrors the malformed-payload tolerance
      // already applied to every other KVM URI source (issue #009).
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_padded_member_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    // RED proof: `_memberUri` returned the raw padded `@odata.id` (only checking
    // `isNotEmpty`), so the GET 404'd and the manager was silently dropped — no
    // consoles shown even though KVM was fully available on the BMC.
    test('fetchConsoles trims a padded member @odata.id and keeps its console',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();

      expect(consoles, hasLength(1));
      expect(consoles.single.managerId, 'BMC');
      expect(consoles.single.type, KvmConsoleType.graphical);
      expect(consoles.single.canOpenConsole, isTrue);
    });

    test(
        'fetchCapabilities trims a padded member @odata.id and skips a blank member',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(capabilities, hasLength(1));
      expect(capabilities.single.managerId, 'BMC');
      expect(capabilities.single.supported, isTrue);
    });

    // A padded manager `Id` must be normalized too, otherwise the capability
    // is keyed under '  BMC  ' and a lookup by the real id ('BMC') misses it.
    test('fetchCapability resolves a manager whose Id is padded', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final KvmCapability? capability = await svc.fetchCapability('BMC');

      expect(capability, isNotNull);
      expect(capability!.managerId, 'BMC');
      expect(capability.supported, isTrue);
    });
  });

  group('KvmService malformed manager @odata.id fallback tolerance (#009)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      // Two managers, each with NO `Id`, whose identity must fall back to the
      // manager body's `@odata.id` (then the member URI) last segment:
      //  * PADDED has a whitespace-padded `@odata.id`;
      //  * BLANK has a whitespace-only `@odata.id`.
      // A BMC emitting either malformed value must not key a console/capability
      // under a stray-whitespace id, and a lookup by the real id must still work
      // (mirrors the `Id` normalization, issue #009).
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_blank_odata_id_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    // RED proof: `_managerId` derived the fallback id from the raw body
    // `@odata.id` via `ODataResource(body).id` without trimming or rejecting a
    // blank value, so PADDED was keyed as 'PADDED  ' and BLANK as '   ' — stray
    // whitespace on the cards and fetchCapability('PADDED'/'BLANK') missed.
    test('fetchConsoles trims a padded @odata.id fallback id', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();

      expect(consoles.map((KvmConsole c) => c.managerId), <String>[
        'PADDED',
        'BLANK',
      ]);
    });

    test('fetchCapability resolves both managers by their real ids', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final KvmCapability? padded = await svc.fetchCapability('PADDED');
      final KvmCapability? blank = await svc.fetchCapability('BLANK');

      expect(padded, isNotNull);
      expect(padded!.managerId, 'PADDED');
      expect(padded.supported, isTrue);
      expect(blank, isNotNull);
      expect(blank!.managerId, 'BLANK');
      expect(blank.supported, isTrue);
    });
  });

  group('KvmService transient manager member resilience (RS-2)', () {
    // The stale-manager fixture has one healthy manager (BMC) and one member
    // (STALE) whose GET is fault-injected to a chosen status. A transient,
    // per-member failure must not blank the gated KVM screen, while an auth /
    // non-retryable failure must still surface so it is never masked.
    Future<void> withStaleStatus(
      int status,
      Future<void> Function(KvmService svc) body,
    ) async {
      final MockRedfishServer server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_stale_manager_mockup',
        statusByPath: <String, int>{
          '/redfish/v1/Managers/STALE': status,
        },
      ).start();
      try {
        await body(
          KvmService(client: server.buildClient(), systemId: 'bmc1'),
        );
      } finally {
        await server.close();
      }
    }

    // RED proof: a per-member 503 rethrew out of `_fetchManagerBodies`, so both
    // views were blanked even though the healthy manager exposed a console.
    test(
        'fetchConsoles skips a transient 5xx member and keeps healthy consoles',
        () async {
      await withStaleStatus(503, (KvmService svc) async {
        final List<KvmConsole> consoles = await svc.fetchConsoles();

        expect(consoles, isNotEmpty);
        expect(consoles.every((KvmConsole c) => c.managerId == 'BMC'), isTrue);
        expect(
          consoles.any((KvmConsole c) =>
              c.type == KvmConsoleType.graphical && c.canOpenConsole),
          isTrue,
        );
      });
    });

    test(
        'fetchCapabilities skips a transient 5xx member and keeps the healthy capability',
        () async {
      await withStaleStatus(503, (KvmService svc) async {
        final List<KvmCapability> capabilities = await svc.fetchCapabilities();

        expect(capabilities, hasLength(1));
        expect(capabilities.single.managerId, 'BMC');
        expect(capabilities.single.supported, isTrue);
        expect(capabilities.single.hasUri, isTrue);
      });
    });

    // Guard: an expired session must never be silently degraded to a partial
    // console list — the auth manager needs to see it and re-authenticate.
    test('fetchConsoles still surfaces a per-member auth failure', () async {
      await withStaleStatus(401, (KvmService svc) async {
        await expectLater(
          svc.fetchConsoles(),
          throwsA(
            isA<RedfishException>().having(
              (RedfishException e) => e.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
      });
    });

    // Guard: only transient/retryable failures are skipped; a permanent (non-
    // retryable) response is a real signal and must keep propagating.
    test('fetchConsoles still surfaces a non-retryable per-member failure',
        () async {
      await withStaleStatus(501, (KvmService svc) async {
        await expectLater(
          svc.fetchConsoles(),
          throwsA(
            isA<RedfishException>().having(
              (RedfishException e) => e.statusCode,
              'statusCode',
              501,
            ),
          ),
        );
      });
    });
  });
}
