/// RM-22 (issue #009/#021): mixed-case + Unicode-confusable `ConnectType`
/// normalization agreement across both `fromManager` factories.
///
/// Redfish canonical connect types (`KVMIP`, `HTML5`, `OEM`) are ASCII, but
/// `String.toUpperCase()` folds *confusable* code points onto ASCII letters:
/// the dotless i (`ı`, U+0131) uppercases to `I`, so `KVMıP` used to satisfy a
/// case-insensitive `KVMIP` check and silently flip a capability's `supported`
/// bit even though the chip rendered a different, confusable token. Fullwidth
/// forms, the Kelvin sign and dotted I survive `toUpperCase()` unchanged but
/// are still distinguishable from a real canonical token only if the fold is
/// ASCII-only.
///
/// Both factories now share [kvmConnectTypeEquals], so the normalized lists
/// and every canonical-token classification are byte-identical by construction
/// and no confusable can ever collapse onto a real `KVMIP` / `HTML5` / `OEM`.
/// This guard pins that contract at the pure-helper layer, at both factories,
/// and at the source layer (so a later regression to `toUpperCase()` fails
/// closed).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_connect_type.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// Confusables / compatibility forms that must NEVER be treated as a canonical
/// ASCII `KVMIP` or `HTML5` token. The first two are the real attack:
/// `toUpperCase()` folds their dotless i onto ASCII `I` (=> `KVMIP`).
const List<String> kConfusableTokens = <String>[
  'KVM\u0131P', // dotless small i -> ASCII I under toUpperCase()
  'kvm\u0131p', // dotless small i, lowercase
  'KVM\u212AP', // Kelvin sign (stays non-ASCII under toUpperCase())
  '\uFF2B\uFF56\uFF2D\uFF29\uFF15', // fullwidth ＫＶＭＩ５
  'K\u0130MIP', // dotted capital I
  'HTML\u0131', // dotless i near-miss for HTML5
  '\uFF28TML5', // fullwidth Ｈ + TML5
];

Map<String, dynamic> _body(List<dynamic> types) => <String, dynamic>{
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectUri': 'https://bmc.example/kvm',
        'ConnectTypesSupported': types,
      },
    };

void main() {
  group('kvmConnectTypeKey / kvmConnectTypeEquals — ASCII-only fold', () {
    test('ASCII case and surrounding whitespace fold exactly like before', () {
      expect(kvmConnectTypeKey('kvmip'), 'KVMIP');
      expect(kvmConnectTypeKey('KvMiP'), 'KVMIP');
      expect(kvmConnectTypeEquals('kvmip', 'KVMIP'), isTrue);
      expect(kvmConnectTypeEquals(' KVMIP ', 'KVMIP'), isTrue);
      expect(kvmConnectTypeEquals(' \tKvMiP\n ', 'KVMIP'), isTrue);
      expect(kvmConnectTypeEquals(' html5 ', 'HTML5'), isTrue);
    });

    test('non-ASCII confusables survive the key and never become canonical',
        () {
      for (final String token in kConfusableTokens) {
        final List<int> keyUnits = kvmConnectTypeKey(token).codeUnits;
        for (final int unit in token.codeUnits.where((int u) => u > 0x7F)) {
          expect(
            keyUnits,
            contains(unit),
            reason: 'ASCII-only fold must preserve U+${unit.toRadixString(16)} '
                'of $token byte-for-byte',
          );
        }
        expect(
          <String>['KVMIP', 'HTML5', 'OEM'],
          isNot(contains(kvmConnectTypeKey(token))),
          reason: 'a confusable must never key onto a canonical token',
        );
      }
      expect(kvmConnectTypeEquals('KVM\u0131P', 'KVMIP'), isFalse);
      expect(kvmConnectTypeEquals('KVM\u212AP', 'KVMIP'), isFalse);
      expect(kvmConnectTypeEquals('\uFF2BVMIP', 'KVMIP'), isFalse);
    });
  });

  group('confusable token never collapses onto a canonical token', () {
    for (final String token in kConfusableTokens) {
      test('"$token" fails closed on both factories and stays byte-equal', () {
        final Map<String, dynamic> body = _body(<dynamic>[token]);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        // Byte-identical normalized lists across the two views.
        expect(console.connectTypesSupported, <String>[token]);
        expect(capability.connectTypes, console.connectTypesSupported);

        // No confusable may flip the KVM/HTML5 classification on either view.
        expect(capability.supported, isFalse,
            reason: 'a confusable must not advertise KVM support');
        expect(capability.supportsKvmIp, isFalse);
        expect(console.supportsHtml5, isFalse);
        // The rendered chip stays the exact BMC token, never the canonical one.
        expect(capability.connectTypes, isNot(contains('KVMIP')));
        expect(capability.connectTypes, isNot(contains('HTML5')));
        // URI resolution is independent of connect type and agrees on both.
        expect(console.launchUri, 'https://bmc.example/kvm');
        expect(capability.launchUri, console.launchUri);
        expect(capability.hasUri, isTrue);
      });
    }
  });

  test('padded/mixed-case real tokens trim and dedup identically on both views',
      () {
    final Map<String, dynamic> body = _body(<dynamic>[
      ' KVMIP ',
      'kvmip',
      'KvMiP',
      ' HTML5 ',
      'html5',
    ]);
    final KvmConsole console =
        KvmConsole.fromManager(body, managerId: 'BMC').single;
    final KvmCapability capability =
        KvmCapability.fromManager(body, managerId: 'BMC');

    expect(console.connectTypesSupported, <String>['KVMIP', 'HTML5']);
    expect(capability.connectTypes, console.connectTypesSupported);
    expect(capability.supported, isTrue);
    expect(capability.supportsKvmIp, isTrue);
    expect(console.supportsHtml5, isTrue);
  });

  test('a confusable alongside a real KVMIP does not hide or merge the chip',
      () {
    final Map<String, dynamic> body = _body(<dynamic>['KVM\u0131P', ' KVMIP ']);
    final KvmConsole console =
        KvmConsole.fromManager(body, managerId: 'BMC').single;
    final KvmCapability capability =
        KvmCapability.fromManager(body, managerId: 'BMC');

    // The dotless-i token stays distinct from the canonical one (no collapse),
    // and both views keep the two chips byte-for-byte in first-seen order.
    expect(console.connectTypesSupported, <String>['KVM\u0131P', 'KVMIP']);
    expect(capability.connectTypes, console.connectTypesSupported);
    // Only the real KVMIP drives `supported`, identically on both views.
    expect(capability.supported, isTrue);
    expect(capability.supportsKvmIp, isTrue);
  });

  test('source keeps canonical comparisons on the ASCII-only helper', () {
    // Liveness: a future "simplification" back to `toUpperCase() == 'KVMIP'`
    // would reintroduce the dotless-i collapse while leaving every behavioral
    // test above passing on ASCII fixtures only if the fixtures were dropped.
    const List<String> paths = <String>[
      'lib/features/kvm/models/kvm_models.dart',
      'lib/features/kvm/models/kvm_capability.dart',
    ];
    for (final String path in paths) {
      final String source = File(path).readAsStringSync();
      expect(source, contains('kvmConnectTypeEquals'),
          reason: '$path must use the shared ASCII-only connect-type helper');
      for (final String canonical in <String>['KVMIP', 'HTML5', 'OEM']) {
        expect(
          source.contains("toUpperCase() == '$canonical'"),
          isFalse,
          reason: '$path must not compare $canonical with toUpperCase()',
        );
      }
    }
  });
}
