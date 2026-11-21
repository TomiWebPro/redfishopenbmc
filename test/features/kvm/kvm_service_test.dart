import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_manager_source.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';
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

  group('KvmService manager member dedup (RS-4)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    setUpAll(() async {
      // A minimal in-temp mockup (no committed fixture) whose Managers
      // collection repeats the same manager URI in several shapes, plus one
      // genuinely distinct manager. `_memberUri` normalizes each entry (trim +
      // reject blank/non-string) BEFORE the walk, so all BMC spellings must
      // collapse to a single manager while BMC2 stays separate.
      fixtureDir = await Directory.systemTemp.createTemp('kvm_dedup_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC'},
            <String, dynamic>{'@odata.id': '  /redfish/v1/Managers/BMC  '},
            '/redfish/v1/Managers/BMC',
            <String, dynamic>{'@odata.id': '   '},
            <String, dynamic>{'@odata.id': 42},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC2'},
          ],
        }),
      );
      for (final String id in <String>['BMC', 'BMC2']) {
        final Directory managerDir = Directory('${managersDir.path}/$id')
          ..createSync(recursive: true);
        File('${managerDir.path}/index.json').writeAsStringSync(
          jsonEncode(<String, dynamic>{
            'Id': id,
            '@odata.id': '/redfish/v1/Managers/$id',
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'ConnectTypesSupported': <String>['KVMIP'],
            },
          }),
        );
      }
      server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
    });

    tearDownAll(() async {
      await server.close();
      fixtureDir.deleteSync(recursive: true);
    });

    test('fetchConsoles emits one console per distinct manager (RS-4)',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();

      expect(consoles, hasLength(2));
      expect(
        consoles.map((KvmConsole c) => c.managerId).toSet(),
        <String>{'BMC', 'BMC2'},
      );
    });

    test('fetchCapabilities emits one capability per distinct manager (RS-4)',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(capabilities, hasLength(2));
      expect(
        capabilities.map((KvmCapability c) => c.managerId).toSet(),
        <String>{'BMC', 'BMC2'},
      );
      expect((await svc.fetchCapability('BMC'))!.supported, isTrue);
    });
  });

  group('KvmService manager-set identity + cardinality (RS-6)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    // One physical manager per console shape so each manager must yield
    // exactly one console card AND one capability card. The Members collection
    // deliberately repeats MgrGraph (verbatim + padded + plain-string),
    // carries one padded plain-string link, and includes blank/non-string
    // entries that must be ignored. Both fetch methods walk the same deduped
    // manager set, so their managerId sets must be byte-for-byte identical.
    const Set<String> expectedManagers = <String>{
      'MgrGraph',
      'MgrSerial',
      'MgrOemNoUri',
      'MgrDisabled',
    };

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_rs6_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': <dynamic>[
            // The first manager is deliberately NOT the secure graphical one,
            // so a naive "return consoles.first" primary would be wrong.
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrDisabled'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrOemNoUri'},
            '  /redfish/v1/Managers/MgrSerial  ',
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGraph'},
            '/redfish/v1/Managers/MgrGraph', // exact duplicate (string form)
            <String, dynamic>{
              '@odata.id': '  /redfish/v1/Managers/MgrGraph  ',
            }, // padded duplicate
            <String, dynamic>{'@odata.id': '   '},
            <String, dynamic>{'@odata.id': 42},
            '   ',
          ],
        }),
      );

      // Each body exposes exactly ONE console block (no Oem console on the
      // graphical/serial managers) so per-manager console cardinality is 1.
      final Map<String, Map<String, dynamic>> bodies =
          <String, Map<String, dynamic>>{
        'MgrGraph': <String, dynamic>{
          'Id': 'MgrGraph',
          '@odata.id': '/redfish/v1/Managers/MgrGraph',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
            'ConnectUri': 'https://bmc.example/console',
          },
        },
        'MgrSerial': <String, dynamic>{
          'Id': 'MgrSerial',
          '@odata.id': '/redfish/v1/Managers/MgrSerial',
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['SSH'],
            'ConnectUri': 'ssh://bmc.example/serial',
          },
        },
        'MgrOemNoUri': <String, dynamic>{
          'Id': 'MgrOemNoUri',
          '@odata.id': '/redfish/v1/Managers/MgrOemNoUri',
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{
              'KVM': <String, dynamic>{'ServiceEnabled': true},
            },
          },
        },
        'MgrDisabled': <String, dynamic>{
          'Id': 'MgrDisabled',
          '@odata.id': '/redfish/v1/Managers/MgrDisabled',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <String>['KVMIP'],
            'ConnectUri': 'https://bmc.example/disabled',
          },
        },
      };
      for (final MapEntry<String, Map<String, dynamic>> entry
          in bodies.entries) {
        final Directory managerDir =
            Directory('${managersDir.path}/${entry.key}')
              ..createSync(recursive: true);
        File('${managerDir.path}/index.json')
            .writeAsStringSync(jsonEncode(entry.value));
      }
      server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
    });

    tearDownAll(() async {
      await server.close();
      fixtureDir.deleteSync(recursive: true);
    });

    test('both fetch methods see the same physical manager set (RS-6)',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(
        consoles.map((KvmConsole c) => c.managerId).toSet(),
        expectedManagers,
      );
      expect(
        capabilities.map((KvmCapability c) => c.managerId).toSet(),
        expectedManagers,
      );
    });

    test('each manager yields exactly one console and one capability (RS-6)',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(consoles, hasLength(expectedManagers.length));
      expect(capabilities, hasLength(expectedManagers.length));
      for (final String managerId in expectedManagers) {
        expect(
          consoles.where((KvmConsole c) => c.managerId == managerId),
          hasLength(1),
          reason: 'exactly one console card for $managerId',
        );
        expect(
          capabilities.where((KvmCapability c) => c.managerId == managerId),
          hasLength(1),
          reason: 'exactly one capability card for $managerId',
        );
      }
    });

    test('primary is deterministic, in the set and launch-safe (RS-6)',
        () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmConsole? primary = await svc.fetchPrimaryConsole();

      expect(primary, isNotNull);
      expect(
        KvmService.pickPrimary(consoles)?.managerId,
        primary!.managerId,
        reason: 'both primary entry points must agree deterministically',
      );
      expect(expectedManagers, contains(primary.managerId));
      // MgrGraph is the only enabled secure-HTTPS graphical console, so the
      // primary must be it — never the first (disabled) manager in the list.
      expect(primary.managerId, 'MgrGraph');
      expect(primary.canOpenConsole, isTrue);
      // The final production route must be the safe external-browser + copy
      // path: never in-app WebView, never self-signed, with the exact target
      // the fail-closed launch plan accepts (not a refused console).
      expect(primary.launchPlan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(primary.launchPlan.isInApp, isFalse);
      expect(primary.launchPlan.acceptSelfSigned, isFalse);
      expect(primary.launchPlan.targetUri, 'https://bmc.example/console');
    });
  });

  group('shared manager source normalizer (RS-5)', () {
    test('trims a padded @odata.id and rejects blank/non-string values', () {
      expect(
        kvmManagerSourceTrimmed('  /redfish/v1/Managers/BMC  '),
        '/redfish/v1/Managers/BMC',
      );
      expect(kvmManagerSourceTrimmed('   '), isNull);
      expect(kvmManagerSourceTrimmed(42), isNull);
      expect(kvmManagerSourceTrimmed(null), isNull);
    });

    test('falls back to the manager-id path on blank/non-string sources', () {
      expect(
        kvmManagerSourceUri('  /redfish/v1/Managers/BMC  ', 'BMC'),
        '/redfish/v1/Managers/BMC',
      );
      expect(kvmManagerSourceUri('   ', 'BMC'), '/redfish/v1/Managers/BMC');
      expect(kvmManagerSourceUri(42, 'BMC'), '/redfish/v1/Managers/BMC');
    });

    test('a usable override wins; a blank one falls through to the body', () {
      expect(
        kvmManagerSourceUri(
          '  /override  ',
          'BMC',
          '/redfish/v1/Managers/BODY',
        ),
        '/override',
      );
      expect(
        kvmManagerSourceUri('   ', 'BMC', '  /redfish/v1/Managers/BODY  '),
        '/redfish/v1/Managers/BODY',
      );
      expect(
        kvmManagerSourceUri(null, 'BMC', '   '),
        '/redfish/v1/Managers/BMC',
      );
    });
  });

  group('KvmService console↔capability source agreement (RS-5)', () {
    late MockRedfishServer server;

    setUpAll(() async {
      // One manager with a whitespace-padded @odata.id and one with a
      // whitespace-only @odata.id, both without `Id` (identity falls back to
      // the member-URI last segment). Both KVM views read the SAME @odata.id,
      // so their normalized source identity must be byte-identical.
      server = await MockRedfishServer(
        fixturesDir: 'test/fixtures/redfish/kvm_blank_odata_id_mockup',
      ).start();
    });

    tearDownAll(() async {
      await server.close();
    });

    KvmService newService() => KvmService(
          client: server.buildClient(),
          systemId: 'bmc1',
        );

    test('padded @odata.id yields one trimmed source on both views', () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      final KvmConsole console =
          consoles.firstWhere((KvmConsole c) => c.managerId == 'PADDED');
      final KvmCapability capability = capabilities.firstWhere(
        (KvmCapability c) => c.managerId == 'PADDED',
      );

      // Exact expected value pins the trim — a raw padded value would fail.
      expect(console.sourceManagerUri, '/redfish/v1/Managers/PADDED');
      expect(capability.sourceManagerUri, '/redfish/v1/Managers/PADDED');
      expect(capability.sourceManagerUri, console.sourceManagerUri);
      expect(capability.safeManagerUri, console.safeManagerUri);
    });

    test('blank @odata.id uses the same manager-id fallback on both views',
        () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      final KvmConsole console =
          consoles.firstWhere((KvmConsole c) => c.managerId == 'BLANK');
      final KvmCapability capability = capabilities.firstWhere(
        (KvmCapability c) => c.managerId == 'BLANK',
      );

      expect(console.sourceManagerUri, '/redfish/v1/Managers/BLANK');
      expect(capability.sourceManagerUri, '/redfish/v1/Managers/BLANK');
      expect(capability.sourceManagerUri, console.sourceManagerUri);
      expect(capability.safeManagerUri, console.safeManagerUri);
    });

    test('fetchCapability(id) agrees with every console source (RS-5)',
        () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(capabilities, isNotEmpty);
      for (final KvmCapability capability in capabilities) {
        final KvmCapability? byId =
            await svc.fetchCapability(capability.managerId);
        expect(
          byId,
          isNotNull,
          reason: 'fetchCapability must resolve ${capability.managerId}',
        );
        expect(byId!.sourceManagerUri, capability.sourceManagerUri);

        final Iterable<KvmConsole> matching = consoles.where(
          (KvmConsole c) => c.managerId == capability.managerId,
        );
        expect(matching, isNotEmpty);
        for (final KvmConsole console in matching) {
          expect(console.sourceManagerUri, capability.sourceManagerUri);
        }
      }
    });
  });

  group('KvmService manager-walk per-member hostile-body tolerance (RS-7)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    // An in-temp minimal mockup (no committed fixture) with two healthy
    // managers (one secure-HTTPS graphical, one SSH serial) alongside:
    //  * MgrNonMap   — a manager URI whose JSON body is a LIST, not an object;
    //  * MgrMalformed— an object whose GraphicalConsole/SerialConsole/Oem
    //                  blocks are all non-map scalars/lists;
    //  * hostile Members entries (blank / numeric / non-string / missing-link
    //    objects / padded duplicates) that must never blank the gated screen.
    // Both fetch methods must stay populated from the healthy managers and
    // skip ONLY the offending member (RS-2 skip semantics unchanged).
    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_rs7_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrGraph'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrNonMap'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrMalformed'},
            '/redfish/v1/Managers/MgrSerial',
            // Hostile / non-member entries that _memberUri must ignore.
            <String, dynamic>{'@odata.id': '   '},
            <String, dynamic>{'@odata.id': 42},
            <String, dynamic>{'NoOdata': 'not-a-link'},
            12345,
            '',
            // Padded duplicate of a healthy manager — trimmed + deduped.
            '  /redfish/v1/Managers/MgrGraph  ',
          ],
        }),
      );

      // A healthy, launch-safe graphical console (the expected primary).
      Directory('${managersDir.path}/MgrGraph').createSync(recursive: true);
      File('${managersDir.path}/MgrGraph/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Id': 'MgrGraph',
          '@odata.id': '/redfish/v1/Managers/MgrGraph',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
            'ConnectUri': 'https://bmc.example/console',
          },
        }),
      );

      // A non-map manager body: a JSON list, which RedfishClient.getJson wraps
      // into {'value': [...]} rather than throwing a TypeError.
      Directory('${managersDir.path}/MgrNonMap').createSync(recursive: true);
      File('${managersDir.path}/MgrNonMap/index.json')
          .writeAsStringSync(jsonEncode(<dynamic>[1, 2, 3]));

      // An object with all-malformed console blocks: no usable console may be
      // emitted, but the manager must not throw or blank the other cards.
      Directory('${managersDir.path}/MgrMalformed').createSync(recursive: true);
      File('${managersDir.path}/MgrMalformed/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Id': 'MgrMalformed',
          '@odata.id': '/redfish/v1/Managers/MgrMalformed',
          'GraphicalConsole': 'not-a-map',
          'SerialConsole': <dynamic>[1, 2],
          'RemoteConsole': 42,
          'Oem': 'garbage',
        }),
      );

      // A healthy serial-only manager (proves non-graphical survivors too).
      Directory('${managersDir.path}/MgrSerial').createSync(recursive: true);
      File('${managersDir.path}/MgrSerial/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Id': 'MgrSerial',
          '@odata.id': '/redfish/v1/Managers/MgrSerial',
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['SSH'],
            'ConnectUri': 'ssh://bmc.example/serial',
          },
        }),
      );

      server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
    });

    tearDownAll(() async {
      await server.close();
      fixtureDir.deleteSync(recursive: true);
    });

    KvmService newService() => KvmService(
          client: server.buildClient(),
          systemId: 'bmc1',
        );

    test(
        'hostile members + non-map/malformed bodies do not blank the screen '
        '(RS-7)', () async {
      final List<KvmConsole> consoles = await newService().fetchConsoles();

      expect(consoles, isNotEmpty);
      expect(
        consoles.map((KvmConsole c) => c.managerId).toSet(),
        <String>{'MgrGraph', 'MgrSerial'},
        reason: 'only the two healthy managers may emit console cards',
      );
    });

    test('malformed console blocks are skipped per-manager, not fatal (RS-7)',
        () async {
      final List<KvmConsole> consoles = await newService().fetchConsoles();

      expect(
        consoles.where((KvmConsole c) => c.managerId == 'MgrMalformed'),
        isEmpty,
      );
      expect(
        consoles.where((KvmConsole c) => c.managerId == 'MgrNonMap'),
        isEmpty,
      );
      expect(
        consoles.where((KvmConsole c) => c.managerId == 'MgrGraph'),
        hasLength(1),
      );
      expect(
        consoles.where((KvmConsole c) => c.managerId == 'MgrSerial'),
        hasLength(1),
      );
    });

    test('both KVM views stay populated and agree on healthy managers (RS-7)',
        () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      final Set<String> consoleManagers =
          consoles.map((KvmConsole c) => c.managerId).toSet();
      final Set<String> capabilityManagers =
          capabilities.map((KvmCapability c) => c.managerId).toSet();
      expect(consoleManagers, <String>{'MgrGraph', 'MgrSerial'});
      expect(
        capabilityManagers,
        containsAll(<String>[
          'MgrGraph',
          'MgrSerial',
          'MgrNonMap',
          'MgrMalformed',
        ]),
      );
      // One capability per walked manager (even a body-less/malformed one),
      // and each healthy console manager also has a capability (RS-6 contract).
      expect(capabilities, hasLength(4));
      for (final String managerId in consoleManagers) {
        expect(capabilityManagers, contains(managerId));
      }
    });

    test(
        'primary is deterministic and launch-safe despite hostile managers '
        '(RS-7)', () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final KvmConsole? primary = await svc.fetchPrimaryConsole();

      expect(primary, isNotNull);
      expect(
        KvmService.pickPrimary(consoles)?.managerId,
        primary!.managerId,
        reason: 'both primary entry points must agree deterministically',
      );
      expect(primary.managerId, 'MgrGraph');
      expect(primary.canOpenConsole, isTrue);
      expect(primary.launchPlan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(primary.launchPlan.isInApp, isFalse);
      expect(primary.launchPlan.acceptSelfSigned, isFalse);
      expect(primary.launchPlan.targetUri, 'https://bmc.example/console');
    });

    test(
        'fetchCapability resolves survivors; hostile managers never throw '
        '(RS-7)', () async {
      final KvmService svc = newService();

      expect((await svc.fetchCapability('MgrGraph'))!.supported, isTrue);
      expect((await svc.fetchCapability('MgrSerial'))!.supported, isFalse);
      // A malformed/non-map manager still yields a stable (unsupported)
      // capability from its member-URI id — never an exception that blanks UI.
      final KvmCapability? nonMap = await svc.fetchCapability('MgrNonMap');
      final KvmCapability? malformed =
          await svc.fetchCapability('MgrMalformed');
      expect(nonMap, isNotNull);
      expect(nonMap!.supported, isFalse);
      expect(malformed, isNotNull);
      expect(malformed!.supported, isFalse);
    });
  });

  group(
      'KvmService.pickPrimary launch-path selection contract (EP-S3, '
      '#009/#021)', () {
    KvmConsole console(
      KvmConsoleType type, {
      required String id,
      required bool enabled,
      String? uri,
      bool html5 = false,
    }) =>
        KvmConsole(
          type: type,
          managerId: id,
          serviceEnabled: enabled,
          connectTypesSupported:
              html5 ? const <String>['HTML5'] : const <String>[],
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/$id',
        );

    // One representative console per launch-strategy tier.
    KvmConsole secureGraphical(String id) => console(
          KvmConsoleType.graphical,
          id: id,
          enabled: true,
          uri: 'https://bmc.example/$id/kvm',
        );
    KvmConsole secureRemote(String id) => console(
          KvmConsoleType.remote,
          id: id,
          enabled: true,
          uri: 'https://bmc.example/$id/kvm',
        );
    KvmConsole plaintextGraphical(String id) => console(
          KvmConsoleType.graphical,
          id: id,
          enabled: true,
          uri: 'http://bmc.example/$id/kvm',
        );
    KvmConsole externalSerial(String id) => console(
          KvmConsoleType.serial,
          id: id,
          enabled: true,
          uri: 'ssh://bmc.example/$id',
        );
    KvmConsole uriLessGraphical(String id) => console(
          KvmConsoleType.graphical,
          id: id,
          enabled: true,
        );
    KvmConsole disabledGraphical(String id) => console(
          KvmConsoleType.graphical,
          id: id,
          enabled: false,
          uri: 'https://bmc.example/$id/kvm',
        );
    KvmConsole disabledSerial(String id) => console(
          KvmConsoleType.serial,
          id: id,
          enabled: false,
        );

    test(
        'the Primary badge never lands on an unopenable console while any '
        'openable console exists (EP-S3)', () {
      // A matrix of mixed lists where at least one member is openable.
      final List<List<KvmConsole>> lists = <List<KvmConsole>>[
        <KvmConsole>[disabledGraphical('d'), externalSerial('e')],
        <KvmConsole>[uriLessGraphical('u'), externalSerial('e')],
        <KvmConsole>[disabledSerial('d'), secureRemote('s')],
        <KvmConsole>[
          disabledGraphical('d'),
          uriLessGraphical('u'),
          externalSerial('e'),
        ],
        <KvmConsole>[disabledSerial('d'), plaintextGraphical('p')],
      ];
      for (final List<KvmConsole> list in lists) {
        final KvmConsole? primary = KvmService.pickPrimary(list);
        expect(primary, isNotNull, reason: 'list has an openable console');
        expect(
          primary!.canOpenConsole,
          isTrue,
          reason: 'an unopenable console must not be badged Primary while an '
              'openable one is available: ${list.map((c) => c.managerId)}',
        );
      }
    });

    test(
        'tier order is secure-graphical > secure-any > openable-graphical > '
        'openable-any > graphical > first (EP-S3)', () {
      final List<({List<KvmConsole> list, String expected})> cases =
          <({List<KvmConsole> list, String expected})>[
        (
          list: <KvmConsole>[
            plaintextGraphical('plain'),
            secureGraphical('secure-g'),
          ],
          expected: 'secure-g',
        ),
        (
          list: <KvmConsole>[secureRemote('secure-r'), secureGraphical('g')],
          expected: 'g',
        ),
        (
          list: <KvmConsole>[externalSerial('ext'), secureRemote('secure-r')],
          expected: 'secure-r',
        ),
        (
          // A secure non-graphical outranks an openable plaintext graphical:
          // the external-browser route prefers a safe TLS target.
          list: <KvmConsole>[
            secureRemote('secure-r'),
            plaintextGraphical('plain'),
          ],
          expected: 'secure-r',
        ),
        (
          list: <KvmConsole>[
            disabledGraphical('disabled-secure'),
            plaintextGraphical('plain'),
          ],
          expected: 'plain',
        ),
        (
          list: <KvmConsole>[
            uriLessGraphical('uri-less'),
            externalSerial('ext'),
          ],
          expected: 'ext',
        ),
        (
          // No openable console: fall back to the first graphical.
          list: <KvmConsole>[disabledSerial('d'), uriLessGraphical('uri-less')],
          expected: 'uri-less',
        ),
        (
          // No openable, no graphical: fall back to the first overall.
          list: <KvmConsole>[disabledSerial('d')],
          expected: 'd',
        ),
      ];
      for (final ({List<KvmConsole> list, String expected}) c in cases) {
        expect(
          KvmService.pickPrimary(c.list)?.managerId,
          c.expected,
          reason: 'tier order for ${c.list.map((e) => e.managerId)}',
        );
      }
    });

    test(
        'a control-unsafe HTTPS graphical is not treated as a secure primary '
        '(EP-S3)', () {
      // A CRLF-bearing authority is NOT a secure target; the fail-closed
      // classifier must not badge it Primary over a genuinely openable console.
      final KvmConsole spoofed = console(
        KvmConsoleType.graphical,
        id: 'spoofed',
        enabled: true,
        uri: 'https://bmc.exa\r\nmple/kvm',
      );
      expect(spoofed.hasSecureLaunchUri, isFalse);
      expect(spoofed.canOpenConsole, isFalse);
      final KvmConsole external = externalSerial('ext');
      expect(KvmService.pickPrimary(<KvmConsole>[spoofed, external]),
          same(external));
    });

    test(
        'pickPrimary is deterministic and order-stable for a fixed list '
        '(EP-S3)', () {
      final List<KvmConsole> list = <KvmConsole>[
        externalSerial('ext'),
        secureRemote('secure-r'),
        plaintextGraphical('plain'),
        secureGraphical('secure-g'),
      ];
      final KvmConsole? first = KvmService.pickPrimary(list);
      expect(first?.managerId, 'secure-g');
      expect(KvmService.pickPrimary(list), same(first));
      // Selection must not mutate or reorder the source list.
      expect(list.map((KvmConsole c) => c.managerId).toList(),
          <String>['ext', 'secure-r', 'plain', 'secure-g']);
    });
  });

  group('KvmService manager-Id collision determinism (RS-8)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    // RS-4 dedups manager MEMBERS by URI: two DISTINCT member URIs whose bodies
    // report the SAME trimmed `Id` are not collapsed. This in-temp mockup walks
    // two such managers (BMC-A / BMC-B, both `Id: "Shared"`, distinct source
    // URIs + console endpoints) plus a manager whose `Id` is blank whitespace
    // (which must fall back to its `@odata.id` last segment for a usable key).
    // Both fetch methods must surface all three PHYSICAL managers; the single
    // `fetchCapability(id)` lookup must deterministically return one stable
    // capability (first member wins) and never resolve a blank/whitespace key.
    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_rs8_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC-A'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC-B'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/MgrBlank'},
          ],
        }),
      );

      final Map<String, Map<String, dynamic>> bodies =
          <String, Map<String, dynamic>>{
        'BMC-A': <String, dynamic>{
          'Id': 'Shared',
          '@odata.id': '/redfish/v1/Managers/BMC-A',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP'],
            'ConnectUri': 'https://a.example/console',
          },
        },
        'BMC-B': <String, dynamic>{
          'Id': 'Shared',
          '@odata.id': '/redfish/v1/Managers/BMC-B',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP'],
            'ConnectUri': 'https://b.example/console',
          },
        },
        'MgrBlank': <String, dynamic>{
          'Id': '   ',
          '@odata.id': '/redfish/v1/Managers/MgrBlank',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP'],
            'ConnectUri': 'https://blank.example/console',
          },
        },
      };
      for (final MapEntry<String, Map<String, dynamic>> entry
          in bodies.entries) {
        final Directory managerDir =
            Directory('${managersDir.path}/${entry.key}')
              ..createSync(recursive: true);
        File('${managerDir.path}/index.json')
            .writeAsStringSync(jsonEncode(entry.value));
      }
      server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
    });

    tearDownAll(() async {
      await server.close();
      fixtureDir.deleteSync(recursive: true);
    });

    test(
        'fetchConsoles surfaces every physical manager under an Id collision '
        '(RS-8)', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmConsole> consoles = await svc.fetchConsoles();

      expect(consoles, hasLength(3));
      expect(
        consoles.map((KvmConsole c) => c.managerId).toList(),
        <String>['Shared', 'Shared', 'MgrBlank'],
        reason: 'both Id-colliding members surface + blank Id falls back',
      );
    });

    test(
        'fetchCapabilities surfaces every physical manager under an Id '
        'collision (RS-8)', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      expect(capabilities, hasLength(3));
      expect(
        capabilities.map((KvmCapability c) => c.managerId).toList(),
        <String>['Shared', 'Shared', 'MgrBlank'],
      );
      expect(
        capabilities.map((KvmCapability c) => c.sourceManagerUri).toSet(),
        <String>{
          '/redfish/v1/Managers/BMC-A',
          '/redfish/v1/Managers/BMC-B',
          '/redfish/v1/Managers/MgrBlank',
        },
        reason: 'both colliding managers stay individually distinguishable',
      );
    });

    test(
        'fetchCapability(id) deterministically returns one stable capability '
        '(RS-8)', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      final KvmCapability? first = await svc.fetchCapability('Shared');
      final KvmCapability? again = await svc.fetchCapability('Shared');

      expect(first, isNotNull);
      expect(first!.managerId, 'Shared');
      // First member (BMC-A) wins deterministically — never the colliding
      // BMC-B's endpoint. A Map-keyed or last-wins lookup would flip this.
      expect(first.sourceManagerUri, '/redfish/v1/Managers/BMC-A');
      expect(first.uri, 'https://a.example/console');
      expect(again!.sourceManagerUri, first.sourceManagerUri);
      expect(again.uri, first.uri);
      // The single looked-up capability must agree with the one both fetch
      // methods surface first for that id.
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(
        capabilities
            .firstWhere((KvmCapability c) => c.managerId == 'Shared')
            .sourceManagerUri,
        first.sourceManagerUri,
      );
    });

    test('a blank/whitespace Id is never a resolvable key (RS-8)', () async {
      final KvmService svc = KvmService(
        client: server.buildClient(),
        systemId: 'bmc1',
      );

      expect(await svc.fetchCapability(''), isNull);
      expect(await svc.fetchCapability('   '), isNull);

      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      expect(
        capabilities.any((KvmCapability c) => c.managerId.trim().isEmpty),
        isFalse,
        reason: 'no capability keyed under a blank/whitespace id',
      );
      // The blank-Id manager is still reachable via its @odata.id fallback.
      final KvmCapability? blankFallback =
          await svc.fetchCapability('MgrBlank');
      expect(blankFallback, isNotNull);
      expect(blankFallback!.managerId, 'MgrBlank');
    });
  });

  group('KvmService session-limit / enablement aggregate agreement (RS-10)',
      () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    // One physical manager per boundary shape for MaxConcurrentSessions and
    // enablement. The service builds each KvmCapability via
    // KvmCapability.fromManager, so its resolved maxSessions / serviceEnabled
    // must match the model built from the SAME body, and fetchCapability(id)
    // must agree with the matching fetchCapabilities() entry. Out-of-spec
    // limits (negative / fractional / beyond 2^53) fail closed to an
    // unreported limit, and an explicitly-disabled block's limit must not win
    // over an enabled block's (RM-8/RM-10 enabled-preference aggregated here).
    Map<String, dynamic> graphical(Object? limit, {bool enabled = true}) =>
        <String, dynamic>{
          'ServiceEnabled': enabled,
          'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
          'ConnectUri': 'https://bmc.example/console',
          'MaxConcurrentSessions': limit,
        };

    final Map<String, Map<String, dynamic>> bodies =
        <String, Map<String, dynamic>>{
      'MgrInt': <String, dynamic>{
        'Id': 'MgrInt',
        '@odata.id': '/redfish/v1/Managers/MgrInt',
        'GraphicalConsole': graphical(4),
      },
      'MgrDouble': <String, dynamic>{
        'Id': 'MgrDouble',
        '@odata.id': '/redfish/v1/Managers/MgrDouble',
        'GraphicalConsole': graphical(4.0),
      },
      'MgrString': <String, dynamic>{
        'Id': 'MgrString',
        '@odata.id': '/redfish/v1/Managers/MgrString',
        'GraphicalConsole': graphical('  4  '),
      },
      'MgrNeg': <String, dynamic>{
        'Id': 'MgrNeg',
        '@odata.id': '/redfish/v1/Managers/MgrNeg',
        'GraphicalConsole': graphical(-1),
      },
      'MgrFrac': <String, dynamic>{
        'Id': 'MgrFrac',
        '@odata.id': '/redfish/v1/Managers/MgrFrac',
        'GraphicalConsole': graphical(2.5),
      },
      'MgrHuge': <String, dynamic>{
        'Id': 'MgrHuge',
        '@odata.id': '/redfish/v1/Managers/MgrHuge',
        'GraphicalConsole': graphical(9007199254740994.0),
      },
      'MgrMixed': <String, dynamic>{
        'Id': 'MgrMixed',
        '@odata.id': '/redfish/v1/Managers/MgrMixed',
        // Disabled graphical carries a higher limit; the enabled serial block
        // must win so the capability card does not advertise a stale limit.
        'GraphicalConsole': graphical(7, enabled: false),
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <String>['SSH'],
          'ConnectUri': 'ssh://bmc.example/serial',
          'MaxConcurrentSessions': 3,
        },
      },
    };

    final Map<String, int?> expectedLimits = <String, int?>{
      'MgrInt': 4,
      'MgrDouble': 4,
      'MgrString': 4,
      'MgrNeg': null,
      'MgrFrac': null,
      'MgrHuge': null,
      'MgrMixed': 3,
    };

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_rs10_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': <dynamic>[
            for (final String id in bodies.keys)
              <String, dynamic>{'@odata.id': '/redfish/v1/Managers/$id'},
          ],
        }),
      );
      for (final MapEntry<String, Map<String, dynamic>> entry
          in bodies.entries) {
        final Directory managerDir =
            Directory('${managersDir.path}/${entry.key}')
              ..createSync(recursive: true);
        File('${managerDir.path}/index.json')
            .writeAsStringSync(jsonEncode(entry.value));
      }
      server = await MockRedfishServer(fixturesDir: fixtureDir.path).start();
    });

    tearDownAll(() async {
      await server.close();
      fixtureDir.deleteSync(recursive: true);
    });

    KvmService newService() => KvmService(
          client: server.buildClient(),
          systemId: 'bmc1',
        );

    test(
        'fetchCapabilities resolves the boundary session-limit matrix '
        '(RS-10)', () async {
      final List<KvmCapability> capabilities =
          await newService().fetchCapabilities();

      expect(capabilities, hasLength(bodies.length));
      final Map<String, KvmCapability> byId = <String, KvmCapability>{
        for (final KvmCapability c in capabilities) c.managerId: c,
      };
      for (final MapEntry<String, int?> expected in expectedLimits.entries) {
        expect(byId[expected.key], isNotNull, reason: expected.key);
        expect(
          byId[expected.key]!.maxSessions,
          expected.value,
          reason: '${expected.key} MaxConcurrentSessions',
        );
      }
    });

    test(
        'fetchCapability(id) agrees with fetchCapabilities over the boundary '
        'matrix (RS-10)', () async {
      final KvmService svc = newService();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();
      final Map<String, KvmCapability> byId = <String, KvmCapability>{
        for (final KvmCapability c in capabilities) c.managerId: c,
      };

      for (final String id in expectedLimits.keys) {
        final KvmCapability? single = await svc.fetchCapability(id);
        expect(single, isNotNull, reason: id);
        expect(single!.maxSessions, byId[id]!.maxSessions, reason: id);
        expect(single.serviceEnabled, byId[id]!.serviceEnabled, reason: id);
        expect(single.uri, byId[id]!.uri, reason: id);
      }
      // Out-of-spec limits are unreported but must never drop a physical
      // manager or fabricate a launchable limit.
      for (final String id in <String>['MgrNeg', 'MgrFrac', 'MgrHuge']) {
        expect(byId[id]!.maxSessions, isNull, reason: id);
      }
      // The enabled serial block's limit wins over the disabled graphical one.
      expect(byId['MgrMixed']!.maxSessions, 3,
          reason: 'enabled block limit wins over disabled block');
    });

    test(
        'service capability agrees with the model built from the same body '
        '(RS-10)', () async {
      final List<KvmCapability> capabilities =
          await newService().fetchCapabilities();
      final Map<String, KvmCapability> byId = <String, KvmCapability>{
        for (final KvmCapability c in capabilities) c.managerId: c,
      };

      for (final MapEntry<String, Map<String, dynamic>> entry
          in bodies.entries) {
        final KvmCapability model = KvmCapability.fromManager(
          entry.value,
          managerId: entry.key,
          sourceManagerUri: '/redfish/v1/Managers/${entry.key}',
        );
        expect(byId[entry.key]!.maxSessions, model.maxSessions,
            reason: '${entry.key} maxSessions agreement');
        expect(byId[entry.key]!.serviceEnabled, model.serviceEnabled,
            reason: '${entry.key} serviceEnabled agreement');
      }
    });
  });
}
