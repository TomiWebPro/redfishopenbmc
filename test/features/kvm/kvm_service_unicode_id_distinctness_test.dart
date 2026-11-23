import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

import '../../helpers/mock_redfish_server.dart';

/// Unicode / case-variant manager-id distinctness across the service surfaces
/// (EP-S16, issues #009/#021).
///
/// RS-6 / RS-8 / RS-9 and EP-S5 pin manager-set identity, dedup, collision
/// determinism and hostile-`Id` resolution — but all over EXACT-CASE ASCII ids.
/// Nothing pins that two manager ids differing only by UNICODE NORMALIZATION
/// FORM (NFC vs NFD), dotted-vs-dotless-I (`İ` / `I` / `ı`), Kelvin sign (`K`
/// vs `K`) or plain ASCII case stay DISTINCT physical managers. A `toLowerCase()`
/// or Unicode-normalizing key in the manager walk / lookup could silently merge
/// two real BMCs into one card (or resolve a lookup to the wrong BMC) while every
/// ASCII identity / collision suite stays GREEN.
///
/// AUDIT: the current walk keys ids byte-exactly (`_managerId` trims only) and
/// `fetchCapability` compares with `==` after the same trim, so distinctness
/// holds by construction — this is a characterization / regression lock over a
/// genuinely unguarded matrix, not a live behaviour change. No WebView, no
/// protocol import, no dependency, no production TLS weakening.
void main() {
  // Every id below is a DISTINCT Dart string. Member-URI segments are plain
  // ASCII so the in-temp fixture paths stay filesystem-safe; the variants live
  // only in the body `Id` (the key under test).
  const List<({String segment, String id})> kVariants =
      <({String segment, String id})>[
    (segment: 'm0', id: 'BMC'), // base uppercase ASCII
    (segment: 'm1', id: 'bmc'), // case variant of the base
    (segment: 'm2', id: '\u00C5ngstrom'), // NFC precomposed A-with-ring
    (segment: 'm3', id: 'A\u030Angstrom'), // NFD decomposed A + combining ring
    (segment: 'm4', id: 'Istanbul'), // ASCII I
    (segment: 'm5', id: '\u0130stanbul'), // dotted capital I (U+0130)
    (segment: 'm6', id: '\u0131stanbul'), // dotless small i (U+0131)
    (segment: 'm7', id: '\u212Aelvin'), // Kelvin sign (U+212A)
    (segment: 'm8', id: 'Kelvin'), // ASCII K
  ];

  group('KvmService Unicode/case-variant manager-id distinctness (EP-S16)', () {
    late Directory fixtureDir;
    late MockRedfishServer server;

    Map<String, dynamic> bodyFor(String segment, String id) =>
        <String, dynamic>{
          '@odata.type': '#Manager.v1_19_0.Manager',
          'Id': id,
          '@odata.id': '/redfish/v1/Managers/$segment',
          'Name': 'manager $segment',
          'ManagerType': 'BMC',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'MaxConcurrentSessions': 4,
            'ConnectTypesSupported': <String>['KVMIP', 'HTML5'],
            'ConnectUri': 'https://bmc.example/$segment/console',
          },
        };

    setUpAll(() async {
      fixtureDir = await Directory.systemTemp.createTemp('kvm_ep_s16_fixture_');
      final Directory managersDir = Directory('${fixtureDir.path}/Managers')
        ..createSync(recursive: true);

      final List<dynamic> members = <dynamic>[];
      for (final ({String segment, String id}) v in kVariants) {
        members.add(<String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/${v.segment}',
        });
      }
      File('${managersDir.path}/index.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{'Members': members}),
      );

      for (final ({String segment, String id}) v in kVariants) {
        final Directory dir = Directory('${managersDir.path}/${v.segment}')
          ..createSync(recursive: true);
        File('${dir.path}/index.json')
            .writeAsStringSync(jsonEncode(bodyFor(v.segment, v.id)));
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
        'each Unicode/case variant is a DISTINCT card on both surfaces '
        '(no case-fold / NFC merge)', () async {
      final KvmService svc = newService();

      final List<KvmConsole> consoles = await svc.fetchConsoles();
      final List<KvmCapability> capabilities = await svc.fetchCapabilities();

      final Set<String> expected = kVariants.map((v) => v.id).toSet();
      expect(expected, hasLength(kVariants.length),
          reason: 'the fixture variants are all distinct strings');

      expect(consoles, hasLength(kVariants.length),
          reason: 'one console card per physical manager, none merged away');
      expect(capabilities, hasLength(kVariants.length),
          reason: 'one capability card per physical manager, none merged away');
      expect(consoles.map((KvmConsole c) => c.managerId).toSet(), expected,
          reason: 'console keys are byte-exact — no case fold / NFC rewrite');
      expect(
          capabilities.map((KvmCapability c) => c.managerId).toSet(), expected,
          reason:
              'capability keys are byte-exact — no case fold / NFC rewrite');

      for (final ({String segment, String id}) v in kVariants) {
        expect(
            consoles.where((KvmConsole c) => c.managerId == v.id), hasLength(1),
            reason: 'exactly one console card for ${jsonEncode(v.id)}');
        expect(capabilities.where((KvmCapability c) => c.managerId == v.id),
            hasLength(1),
            reason: 'exactly one capability card for ${jsonEncode(v.id)}');
      }
    });

    test(
        'fetchCapability resolves each variant by its EXACT byte key '
        '(no normalized-away lookup)', () async {
      final KvmService svc = newService();

      for (final ({String segment, String id}) v in kVariants) {
        final KvmCapability? resolved = await svc.fetchCapability(v.id);
        expect(resolved, isNotNull,
            reason: 'exact lookup ${jsonEncode(v.id)} resolves');
        expect(resolved!.managerId, v.id,
            reason: 'lookup of ${jsonEncode(v.id)} returns THAT exact manager, '
                'not a case-folded / normalized sibling');
      }

      // A lookup that folds case or NFC would bleed a variant onto its twin.
      final KvmCapability upper = (await svc.fetchCapability('BMC'))!;
      final KvmCapability lower = (await svc.fetchCapability('bmc'))!;
      expect(upper.managerId, 'BMC');
      expect(lower.managerId, 'bmc');
      expect(upper.managerId, isNot(lower.managerId),
          reason: 'case-variant lookups resolve different physical managers');

      final KvmCapability nfc = (await svc.fetchCapability('\u00C5ngstrom'))!;
      final KvmCapability nfd = (await svc.fetchCapability('A\u030Angstrom'))!;
      expect(nfc.managerId, isNot(nfd.managerId),
          reason: 'NFC vs NFD lookups resolve different physical managers');
    });

    test('no normalized / case-folded code point becomes a manager key',
        () async {
      final KvmService svc = newService();
      final Set<String> keys = (await svc.fetchCapabilities())
          .map((KvmCapability c) => c.managerId)
          .toSet();

      // A case-folding or NFC-normalizing walk would replace these exact keys
      // with their folded forms; none of those may appear.
      for (final String forbidden in <String>[
        'bmc', // folded from 'BMC' only if the exact 'bmc' manager were absent
        'angstrom', // a normalize-and-strip-mark regression
        'istanbul', // a normalize-and-strip-mark regression
        'kelvin', // a lowercase / NFKC fold of the Kelvin-sign manager
      ]) {
        // Only assert a fold is absent when it is NOT itself an exact fixture
        // id; 'bmc' and 'kelvin' ARE exact ids, so check the ones that are not.
        if (!kVariants.any((v) => v.id == forbidden)) {
          expect(keys, isNot(contains(forbidden)),
              reason: 'normalized-away key "$forbidden" must not appear');
        }
      }

      // The Kelvin-sign manager must keep its real code point, never an ASCII K.
      expect(keys, contains('\u212Aelvin'));
    });
  });
}
