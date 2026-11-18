// Tests for the #009 OEM console parser registry (interface + deterministic
// resolution + integration with `KvmConsole.fromManager`).
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm.dart';

/// A canned parser used to exercise registration / resolution rules.
class _StubParser extends KvmOemConsoleParser {
  const _StubParser(this.vendorKey, {this.info, this.seenBlocks});

  @override
  final String vendorKey;
  final KvmOemConsoleInfo? info;
  final List<Map<String, dynamic>>? seenBlocks;

  @override
  KvmOemConsoleInfo? parse(Map<String, dynamic> block) {
    seenBlocks?.add(block);
    return info;
  }
}

/// A realistic AMI parser: finds `Oem.AMI.KVM.ConnectUri`.
class _AmiKvmParser extends KvmOemConsoleParser {
  const _AmiKvmParser();

  @override
  String get vendorKey => 'AMI';

  @override
  KvmOemConsoleInfo? parse(Map<String, dynamic> block) {
    final dynamic kvm = block['KVM'];
    if (kvm is! Map<String, dynamic>) return null;
    final dynamic uri = kvm['ConnectUri'];
    if (uri is! String || uri.isEmpty) return null;
    return KvmOemConsoleInfo(
      vendor: vendorKey,
      connectUri: uri,
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      displayName: 'AMI HTML5 KVM',
    );
  }
}

void main() {
  group('KvmOemConsoleInfo', () {
    test('has sensible defaults', () {
      const KvmOemConsoleInfo info = KvmOemConsoleInfo(vendor: 'AMI');
      expect(info.vendor, 'AMI');
      expect(info.connectUri, isNull);
      expect(info.connectTypesSupported, isEmpty);
      expect(info.serviceEnabled, isTrue);
      expect(info.displayName, isNull);
    });

    test('retains supplied values', () {
      const KvmOemConsoleInfo info = KvmOemConsoleInfo(
        vendor: 'HPE',
        connectUri: 'https://bmc.example/kvm',
        connectTypesSupported: <String>['HTML5', 'KVMIP'],
        serviceEnabled: false,
        displayName: 'iLO KVM',
      );
      expect(info.connectUri, 'https://bmc.example/kvm');
      expect(info.connectTypesSupported, <String>['HTML5', 'KVMIP']);
      expect(info.serviceEnabled, isFalse);
      expect(info.displayName, 'iLO KVM');
    });
  });

  group('KvmOemRegistry registration', () {
    test('starts empty and parses nothing', () {
      final KvmOemRegistry registry = KvmOemRegistry();
      expect(registry.parsers, isEmpty);
      expect(registry.parse(<String, dynamic>{'AMI': <String, dynamic>{}}),
          isNull);
    });

    test('registers parsers and preserves resolution order', () {
      final KvmOemRegistry registry = KvmOemRegistry();
      final KvmOemConsoleParser ami = const _StubParser('AMI');
      final KvmOemConsoleParser hpe = const _StubParser('HPE');
      expect(registry.register(ami), isTrue);
      expect(registry.register(hpe), isTrue);
      expect(registry.parsers, <KvmOemConsoleParser>[ami, hpe]);
    });

    test('rejects duplicate vendor keys case-insensitively and trimmed', () {
      final KvmOemRegistry registry = KvmOemRegistry();
      expect(registry.register(const _StubParser('AMI')), isTrue);
      expect(registry.register(const _StubParser(' ami ')), isFalse);
      expect(registry.register(const _StubParser('AMi')), isFalse);
      expect(registry.parsers, hasLength(1));
    });

    test('accepts distinct vendor keys and preloads constructor parsers', () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[
          const _StubParser('AMI'),
          const _StubParser('HPE'),
        ],
      );
      expect(registry.parsers, hasLength(2));
      expect(registry.register(const _StubParser('OpenBMC')), isTrue);
      expect(registry.parsers, hasLength(3));
    });

    test('parsers snapshot is unmodifiable', () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[const _StubParser('AMI')],
      );
      expect(
        () => registry.parsers.add(const _StubParser('HPE')),
        throwsUnsupportedError,
      );
    });
  });

  group('KvmOemRegistry parse', () {
    test('matches vendor keys case-insensitively', () {
      const KvmOemConsoleInfo info = KvmOemConsoleInfo(vendor: 'AMI');
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[const _StubParser('AMI', info: info)],
      );
      final KvmOemConsoleInfo? result = registry.parse(
        <String, dynamic>{
          'aMi': <String, dynamic>{'KVM': <String, dynamic>{}}
        },
      );
      expect(result, info);
    });

    test('passes the vendor sub-block to the parser', () {
      final List<Map<String, dynamic>> seen = <Map<String, dynamic>>[];
      final Map<String, dynamic> block = <String, dynamic>{
        'KVM': <String, dynamic>{'ConnectUri': 'https://bmc/kvm'},
      };
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[
          _StubParser(
            'AMI',
            info: const KvmOemConsoleInfo(vendor: 'AMI'),
            seenBlocks: seen,
          ),
        ],
      );
      registry.parse(<String, dynamic>{'AMI': block});
      expect(seen, hasLength(1));
      expect(seen.single, same(block));
    });

    test('returns null when no registered vendor key is present', () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[
          const _StubParser('AMI', info: KvmOemConsoleInfo(vendor: 'AMI')),
        ],
      );
      expect(
        registry.parse(<String, dynamic>{
          'HPE': <String, dynamic>{'KVM': <String, dynamic>{}},
        }),
        isNull,
      );
    });

    test('skips a parser that returns null and tries the next one', () {
      const KvmOemConsoleInfo hpeInfo = KvmOemConsoleInfo(vendor: 'HPE');
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[
          const _StubParser('AMI'), // returns null -> not a console
          const _StubParser('HPE', info: hpeInfo),
        ],
      );
      expect(
        registry.parse(<String, dynamic>{
          'AMI': <String, dynamic>{},
          'HPE': <String, dynamic>{'KVM': <String, dynamic>{}},
        }),
        hpeInfo,
      );
    });

    test('first matching parser wins (registration order is deterministic)',
        () {
      const KvmOemConsoleInfo first = KvmOemConsoleInfo(vendor: 'first');
      const KvmOemConsoleInfo second = KvmOemConsoleInfo(vendor: 'second');
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[
          const _StubParser('AMI', info: first),
          const _StubParser('HPE', info: second),
        ],
      );
      expect(
        registry.parse(<String, dynamic>{
          'AMI': <String, dynamic>{},
          'HPE': <String, dynamic>{},
        }),
        first,
      );
    });

    test('finds a nested vendor block within the bounded depth', () {
      const KvmOemConsoleInfo info = KvmOemConsoleInfo(vendor: 'HPE');
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[const _StubParser('HPE', info: info)],
      );
      expect(
        registry.parse(<String, dynamic>{
          'VendorRoot': <String, dynamic>{
            'Nested': <String, dynamic>{
              'HPE': <String, dynamic>{'KVM': <String, dynamic>{}},
            },
          },
        }),
        info,
      );
    });

    test('ignores a vendor block whose value is not a map', () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[
          const _StubParser('AMI', info: KvmOemConsoleInfo(vendor: 'AMI')),
        ],
      );
      expect(registry.parse(<String, dynamic>{'AMI': 'not-a-map'}), isNull);
    });
  });

  group('KvmConsole.fromManager OEM registry integration', () {
    Map<String, dynamic> vendorManager() => <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'Oem': <String, dynamic>{
            'AMI': <String, dynamic>{
              'KVM': <String, dynamic>{
                'ConnectUri': 'https://bmc.example/kvm',
              },
            },
          },
        };

    KvmConsole? oemOf(List<KvmConsole> consoles) =>
        consoles.cast<KvmConsole?>().firstWhere(
              (KvmConsole? c) => c?.type == KvmConsoleType.oem,
              orElse: () => null,
            );

    test('RED proof: without a registry the OEM console has no connect URI',
        () {
      final KvmConsole? oem = oemOf(
        KvmConsole.fromManager(vendorManager(), managerId: 'BMC'),
      );
      expect(oem, isNotNull);
      // Pre-wiring behaviour: strict detection sees the 'KVM' key but cannot
      // parse the vendor-specific ConnectUri, so no launch URI is available.
      expect(oem!.connectUri, isNull);
      expect(oem.canLaunchInAppHtml5, isFalse);
    });

    test('GREEN: a registered vendor parser enriches the OEM console', () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: const <KvmOemConsoleParser>[_AmiKvmParser()],
      );
      final KvmConsole? oem = oemOf(
        KvmConsole.fromManager(
          vendorManager(),
          managerId: 'BMC',
          oemRegistry: registry,
        ),
      );
      expect(oem, isNotNull);
      expect(oem!.connectUri, 'https://bmc.example/kvm');
      expect(oem.connectTypesSupported, contains('HTML5'));
      expect(oem.serviceEnabled, isTrue);
      // The vendor URI flows through the existing secure launch gating.
      expect(oem.canLaunchInAppHtml5, isTrue);
      expect(oem.launchStrategy, KvmLaunchStrategy.inAppHtml5);
    });

    test('an unmatched registry falls back to strict OEM detection', () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[const _StubParser('HPE')],
      );
      final KvmConsole? oem = oemOf(
        KvmConsole.fromManager(
          vendorManager(),
          managerId: 'BMC',
          oemRegistry: registry,
        ),
      );
      expect(oem, isNotNull);
      expect(oem!.connectUri, isNull);
    });

    test(
        'bare vendor metadata is not reported as a console even with a registry',
        () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: <KvmOemConsoleParser>[const _StubParser('AMI')],
      );
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'Oem': <String, dynamic>{
            'AMI': <String, dynamic>{'Manufacturer': 'ACME'},
          },
        },
        managerId: 'BMC',
        oemRegistry: registry,
      );
      expect(consoles, isEmpty);
    });

    test('standard consoles are unaffected by a registry', () {
      final KvmOemRegistry registry = KvmOemRegistry(
        parsers: const <KvmOemConsoleParser>[_AmiKvmParser()],
      );
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <String>['KVMIP'],
            'MaxConcurrentSessions': 2,
          },
        },
        managerId: 'BMC',
        oemRegistry: registry,
      );
      expect(consoles, hasLength(1));
      expect(consoles.single.type, KvmConsoleType.graphical);
    });
  });
}
