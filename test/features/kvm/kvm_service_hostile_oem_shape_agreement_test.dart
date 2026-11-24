import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

/// Hostile OEM console-shape agreement across the real `/Managers` walk for
/// `KvmService.fetchConsoles()` / `fetchCapabilities()` /
/// `fetchCapability(id)` (EP-S21, issues #009/#021).
///
/// AUDIT FIRST: `KvmConsole.fromManager` and `KvmCapability.fromManager` both
/// resolve the generic OEM console through the SAME shared helpers
/// (`FeatureRules.oemHasConsole`, `kvmOemConsoleEnabled`, `kvmOemConsoleUri`),
/// so detection / enablement / URI agree BY CONSTRUCTION — there is no live
/// divergence and no production change here. What NO existing guard pinned:
/// the full hostile OEM-shape matrix driven through BOTH surfaces in ONE walk.
/// Every OEM hostile-shape matrix today is model-layer only (RM-20, RM-9,
/// RM-14, EP-M6, EP-M5, RM-23) calling the `fromManager` factories directly;
/// the only service-level OEM cases are a benign `ServiceEnabled: true` block
/// and a single non-map `'Oem': 'garbage'`. A one-sided service-level refactor
/// (e.g. an OEM enablement assumption that only one surface applies, or a walk
/// that skips a nested-only console on one side) could desync the capability
/// card from the console card while every single-surface suite stayed GREEN —
/// the exact #009 divergence class. This guard pins the shared contract over
/// mixed-case / nested / duplicate / empty OEM keys, non-map / list / numeric /
/// bool leaves and an explicit-disable case plus a byte-exact valid control:
/// both surfaces agree on the survivor set, manager id, resolved URI,
/// enablement and limit, never throw on a malformed OEM value, and
/// `fetchCapability(id)` agrees field-for-field with the aggregate.
///
/// Test-only, dependency-free, TLS-safe: no WebView / protocol import, no URL
/// opened, no production TLS weakening, no behaviour decision folded in.
void main() {
  group(
      'KvmService hostile OEM console-shape cross-surface agreement '
      '(EP-S21)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    // Managers that expose a console-like OEM block (both surfaces must carry
    // them) and one that is pure vendor metadata (no console on either side).
    const List<String> consoleManagers = <String>[
      'OemValid',
      'OemDisable',
      'OemNested',
      'OemDup',
    ];
    const List<String> allManagers = <String>[
      'OemValid',
      'OemDisable',
      'OemNested',
      'OemDup',
      'OemMetadata',
    ];

    const String validUri = 'https://bmc-valid.example/console';
    const String disableUri = 'https://bmc-dis.example/console';
    const String nestedUri = 'https://bmc-nested.example/kmv';
    const String dupUri = 'https://bmc-dup.example/console';

    List<String> sortedIds(Iterable<String> ids) => ids.toList()..sort();

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s21_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);

      final Map<String, Map<String, dynamic>> bodies =
          <String, Map<String, dynamic>>{
        // Byte-exact valid control: nested mixed-case Oem.OpenBMC.KVM.Uri.
        'OemValid': <String, dynamic>{
          'Id': 'OemValid',
          '@odata.id': '/redfish/v1/Managers/OemValid',
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{
              'KVM': <String, dynamic>{
                'Uri': validUri,
                'ServiceEnabled': true,
              },
            },
          },
        },
        // Explicit disable among hostile leaves: padded ConnectUri, non-bool
        // enablement leaf, list value, non-map console-like key, empty key.
        'OemDisable': <String, dynamic>{
          'Id': 'OemDisable',
          '@odata.id': '/redfish/v1/Managers/OemDisable',
          'Oem': <String, dynamic>{
            'Contoso': <String, dynamic>{
              'WebConsole': <String, dynamic>{
                'ConnectUri': '  $disableUri  ',
                'ServiceEnabled': false,
                'Enabled': 0, // numeric (non-bool) leaf -> not a truthy enable
                'Junk': <dynamic>[
                  1,
                  2,
                  <String, dynamic>{'KVM': 3}
                ],
              },
              'BadKVM': 42, // console-like key but a non-map scalar
              '': <String, dynamic>{'uri': 'https://empty-key.example'},
            },
          },
        },
        // Deeply nested mixed-case console key with non-map/list siblings that
        // must not shadow the URI-bearing block.
        'OemNested': <String, dynamic>{
          'Id': 'OemNested',
          '@odata.id': '/redfish/v1/Managers/OemNested',
          'Oem': <String, dynamic>{
            'VendorA': <String, dynamic>{
              'WebConsole': 'not-a-map',
              'nested': <String, dynamic>{
                'KvmRedirect': <dynamic>[1, 2],
                'KVMIP': <String, dynamic>{
                  'uri': nestedUri,
                  'Enabled': true,
                },
              },
            },
          },
        },
        // Duplicate / case-variant / empty keys and numeric/bool leaves: the
        // blank-URl KVM is skipped and the case-variant kvm wins on both sides.
        'OemDup': <String, dynamic>{
          'Id': 'OemDup',
          '@odata.id': '/redfish/v1/Managers/OemDup',
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': '   ',
              'ServiceEnabled': false,
            },
            'kvm': <String, dynamic>{
              'Uri': dupUri,
              'ServiceEnabled': true,
            },
            '': <String, dynamic>{'KVM': 7},
            'Flag': true,
            'Count': 5,
          },
        },
        // Pure vendor metadata: a console-like key with a non-map value, no
        // console structure anywhere. No console on either surface.
        'OemMetadata': <String, dynamic>{
          'Id': 'OemMetadata',
          '@odata.id': '/redfish/v1/Managers/OemMetadata',
          'Oem': <String, dynamic>{
            'Vendor': <String, dynamic>{
              'Model': 'X',
              'Count': 5,
              'Flag': true,
              'ConsoleAlias': 123,
            },
          },
        },
      };

      for (final String segment in allManagers) {
        final Directory dir = Directory('${managersDir.path}/$segment')
          ..createSync(recursive: true);
        File('${dir.path}/index.json').writeAsStringSync(
          jsonEncode(bodies[segment]),
        );
      }
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'Members': <dynamic>[
            for (final String segment in allManagers)
              <String, dynamic>{
                '@odata.id': '/redfish/v1/Managers/$segment',
              },
          ],
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

    List<KvmConsole> oemConsoles(List<KvmConsole> consoles) =>
        consoles.where((KvmConsole c) => c.type == KvmConsoleType.oem).toList();

    KvmConsole consoleFor(List<KvmConsole> consoles, String id) =>
        oemConsoles(consoles).firstWhere((KvmConsole c) => c.managerId == id);

    KvmCapability capFor(List<KvmCapability> caps, String id) =>
        caps.firstWhere((KvmCapability c) => c.managerId == id);

    test(
        'full hostile OEM matrix: both surfaces agree on the survivor set, '
        'manager ids, and fetchCapability(id) field-for-field; never throw',
        () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> caps = await svc.fetchCapabilities();

      final List<String> consoleIds = sortedIds(oemConsoles(consoles).map(
        (KvmConsole c) => c.managerId,
      ));
      final List<String> capIds = sortedIds(caps.map(
        (KvmCapability c) => c.managerId,
      ));

      expect(consoleIds, sortedIds(consoleManagers),
          reason: 'console surface: every console-like OEM manager once');
      expect(capIds, sortedIds(allManagers),
          reason: 'capability surface: every walked manager gets a card');
      for (final String id in consoleIds) {
        expect(capIds, contains(id),
            reason: 'every console survivor also has a capability card');
      }
      for (final List<String> ids in <List<String>>[consoleIds, capIds]) {
        expect(ids.length, ids.toSet().length, reason: 'no duplicate id');
        for (final String id in ids) {
          expect(id, id.trim(), reason: 'id must be trimmed');
          expect(id.contains(RegExp(r'[\r\n\t\x00-\x1f\x7f]')), isFalse,
              reason: 'no control code point in id "$id"');
        }
      }

      // fetchCapability(id) pins the exact same aggregate every time.
      for (final String id in allManagers) {
        final KvmCapability? resolved = await svc.fetchCapability(id);
        final KvmCapability aggregate = capFor(caps, id);
        expect(resolved, isNotNull, reason: 'fetchCapability("$id") resolves');
        expect(resolved!.managerId, aggregate.managerId);
        expect(resolved.supported, aggregate.supported);
        expect(resolved.serviceEnabled, aggregate.serviceEnabled);
        expect(resolved.hasUri, aggregate.hasUri);
        expect(resolved.uri, aggregate.uri);
        expect(resolved.connectTypes, aggregate.connectTypes);
        expect(resolved.maxSessions, aggregate.maxSessions);
      }
    });

    test(
        'valid OEM control stays byte-exact on both surfaces (URI, '
        'enablement, limit)', () async {
      final KvmService svc = newService();
      final KvmConsole c = consoleFor(await svc.fetchConsoles(), 'OemValid');
      final KvmCapability cap =
          capFor(await svc.fetchCapabilities(), 'OemValid');

      expect(c.connectUri, validUri, reason: 'console URI byte-exact');
      expect(cap.uri, validUri, reason: 'capability URI byte-exact');
      expect(c.connectUri, cap.uri,
          reason: 'both surfaces resolve the same URI');
      expect(c.serviceEnabled, isTrue, reason: 'console enabled');
      expect(cap.serviceEnabled, isTrue, reason: 'capability enabled');
      expect(cap.supported, isTrue);
      expect(c.serviceEnabled, cap.serviceEnabled,
          reason: 'enablement agrees across surfaces');
      // OEM-only manager: no standard console block carries a limit, so both
      // surfaces must report the same (null) limit rather than invent one.
      expect(c.maxConcurrentSessions, isNull);
      expect(cap.maxSessions, isNull);
      expect(c.maxConcurrentSessions, cap.maxSessions,
          reason: 'limit agrees across surfaces');
    });

    test(
        'explicit-disable OEM console among hostile leaves: enablement and '
        'URI agree across both surfaces', () async {
      final KvmService svc = newService();
      final KvmConsole c = consoleFor(await svc.fetchConsoles(), 'OemDisable');
      final KvmCapability cap =
          capFor(await svc.fetchCapabilities(), 'OemDisable');

      // Padded ConnectUri is trimmed identically by the shared resolver.
      expect(c.connectUri, disableUri);
      expect(cap.uri, disableUri);
      expect(c.connectUri, cap.uri);
      // The explicit ServiceEnabled: false (with a non-bool Enabled leaf) is
      // honored on BOTH surfaces: a one-sided enablement assumption here is
      // the exact #009 divergence this guard exists to catch.
      expect(c.serviceEnabled, isFalse, reason: 'console honors explicit off');
      expect(cap.serviceEnabled, isFalse,
          reason: 'capability honors explicit off');
      expect(cap.supported, isFalse);
      expect(c.serviceEnabled, cap.serviceEnabled,
          reason: 'explicit-disable agreement across surfaces');
    });

    test(
        'deeply nested mixed-case OEM key resolves identically and is not '
        'shadowed by non-map/list console-like siblings', () async {
      final KvmService svc = newService();
      final KvmConsole c = consoleFor(await svc.fetchConsoles(), 'OemNested');
      final KvmCapability cap =
          capFor(await svc.fetchCapabilities(), 'OemNested');

      expect(c.connectUri, nestedUri);
      expect(cap.uri, nestedUri);
      expect(c.connectUri, cap.uri);
      expect(c.serviceEnabled, isTrue);
      expect(cap.serviceEnabled, isTrue);
      expect(c.serviceEnabled, cap.serviceEnabled);
      expect(cap.supported, isTrue);
    });

    test(
        'duplicate / case-variant / empty keys and numeric/bool leaves agree '
        'across both surfaces with no phantom or throw', () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> caps = await svc.fetchCapabilities();
      final KvmConsole c = consoleFor(consoles, 'OemDup');
      final KvmCapability cap = capFor(caps, 'OemDup');

      // The blank-URI KVM is skipped; the case-variant kvm with a real URI wins
      // on both surfaces, byte-identically.
      expect(c.connectUri, dupUri);
      expect(cap.uri, dupUri);
      expect(c.connectUri, cap.uri);
      expect(c.serviceEnabled, isTrue);
      expect(cap.serviceEnabled, isTrue);
      expect(c.serviceEnabled, cap.serviceEnabled);
      expect(cap.supported, isTrue);
      // No phantom console/capability from the empty key or numeric/bool leaves.
      expect(oemConsoles(consoles).length, consoleManagers.length);
      expect(caps.length, allManagers.length);
    });

    test(
        'pure vendor-metadata Oem yields no console but an unsupported '
        'capability on both surfaces, with no throw', () async {
      final KvmService svc = newService();
      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> caps = await svc.fetchCapabilities();

      expect(oemConsoles(consoles).map((KvmConsole c) => c.managerId),
          isNot(contains('OemMetadata')),
          reason: 'vendor metadata alone is not a console');
      final KvmCapability cap = capFor(caps, 'OemMetadata');
      expect(cap.supported, isFalse);
      expect(cap.hasUri, isFalse);
      expect(cap.connectTypes, isEmpty);
      expect(await svc.fetchCapability('OemMetadata'), isNotNull);
    });
  });
}
