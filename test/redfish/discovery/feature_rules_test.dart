import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery_cache.dart';
import 'package:redfishopenbmc/redfish/discovery/feature_rules.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

void main() {
  group('FeatureRules — power', () {
    test('powerControl true when a system exposes #ComputerSystem.Reset', () {
      final Map<String, dynamic> system = <String, dynamic>{
        '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{'target': '/x'},
        },
      };
      expect(FeatureRules.powerControl(<Map<String, dynamic>>[system]), isTrue);
    });

    test('powerControl false when no reset action', () {
      final Map<String, dynamic> system = <String, dynamic>{
        '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
      };
      expect(
          FeatureRules.powerControl(<Map<String, dynamic>>[system]), isFalse);
    });

    test('supportedResetTypes unions across systems and sorts', () {
      final List<Map<String, dynamic>> systems = <Map<String, dynamic>>[
        <String, dynamic>{
          'SupportedResetTypes': <String>['GracefulRestart', 'On'],
        },
        <String, dynamic>{
          'SupportedResetTypes': <String>['ForceOff', 'On'],
        },
      ];
      expect(
        FeatureRules.supportedResetTypes(systems),
        <String>['ForceOff', 'GracefulRestart', 'On'],
      );
    });
  });

  group('FeatureRules — kvm', () {
    test('detects GraphicalConsole', () {
      final Map<String, dynamic> m = <String, dynamic>{
        '@odata.type': '#Manager.v1_16_0.Manager',
        'GraphicalConsole': <String, dynamic>{'Enabled': true},
      };
      expect(FeatureRules.kvm(<Map<String, dynamic>>[m]), isTrue);
      expect(
          FeatureRules.kvmType(<Map<String, dynamic>>[m]), 'GraphicalConsole');
    });

    test('ignores disabled consoles', () {
      final Map<String, dynamic> m = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{'Enabled': false},
        'SerialConsole': <String, dynamic>{'Enabled': false},
      };
      expect(FeatureRules.kvm(<Map<String, dynamic>>[m]), isFalse);
      expect(FeatureRules.kvmType(<Map<String, dynamic>>[m]), isNull);
    });

    test('prefers OEM console when no graphical/serial', () {
      final Map<String, dynamic> m = <String, dynamic>{
        'Oem': <String, dynamic>{
          'Vendor': <String, dynamic>{'GraphicalConsole': <String, dynamic>{}},
        },
      };
      expect(FeatureRules.kvmType(<Map<String, dynamic>>[m]), 'Oem');
    });

    test('ignores bare Oem vendor metadata (bmcweb-style)', () {
      // bmcweb Managers always carry an `Oem` block for vendor data; a bare
      // map must not report KVM as available (DOCS-4).
      final Map<String, dynamic> m = <String, dynamic>{
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{'FirmwareVersion': '1.0'},
        },
      };
      expect(FeatureRules.kvm(<Map<String, dynamic>>[m]), isFalse);
      expect(FeatureRules.kvmType(<Map<String, dynamic>>[m]), isNull);
    });

    test('Oem Kvm marker enables the OEM console path', () {
      final Map<String, dynamic> m = <String, dynamic>{
        'Oem': <String, dynamic>{
          'Vendor': <String, dynamic>{'Kvm': <String, dynamic>{}},
        },
      };
      expect(FeatureRules.kvmType(<Map<String, dynamic>>[m]), 'Oem');
    });
  });

  group('FeatureRules — sensors & firmware', () {
    test('sensorMonitoring true via Thermal link', () {
      final Map<String, dynamic> c = <String, dynamic>{
        '@odata.type': '#Chassis.v1_24_0.Chassis',
        'Thermal': <String, dynamic>{'@odata.id': '/t'},
      };
      expect(FeatureRules.sensorMonitoring(<Map<String, dynamic>>[c]), isTrue);
    });

    test('sensorCount sums temperatures + fans + voltages + sensor members',
        () {
      final List<Map<String, dynamic>> thermals = <Map<String, dynamic>>[
        <String, dynamic>{
          'Temperatures': <dynamic>[
            <String, dynamic>{},
            <String, dynamic>{},
          ],
          'Fans': <dynamic>[<String, dynamic>{}],
          'Voltages': <dynamic>[<String, dynamic>{}],
        },
      ];
      final List<Map<String, dynamic>> sensors = <Map<String, dynamic>>[
        <String, dynamic>{
          'Members': <dynamic>[
            <String, dynamic>{},
            <String, dynamic>{},
            <String, dynamic>{},
          ],
        },
      ];
      // 2 temps + 1 fan + 1 volt + 3 sensor members = 7.
      expect(FeatureRules.sensorCount(thermals, sensors), 7);
    });

    test('firmware_update presence and version preference', () {
      expect(FeatureRules.firmwareUpdate(null), isFalse);
      expect(FeatureRules.firmwareUpdate(<String, dynamic>{}), isTrue);
      expect(
        FeatureRules.updateServiceVersion(
          <String, dynamic>{'FirmwareVersion': '1.2.3'},
        ),
        '1.2.3',
      );
      expect(
        FeatureRules.updateServiceVersion(<String, dynamic>{'Id': 'US'}),
        'US',
      );
    });
  });

  group('FeatureRules — build composes everything', () {
    test('build produces a SystemFeatures from a context', () {
      const DiscoveryContext ctx = DiscoveryContext(
        serviceRoot: <String, dynamic>{'@odata.id': '/redfish/v1/'},
        systems: <Map<String, dynamic>>[
          <String, dynamic>{
            '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
            'SupportedResetTypes': <String>['On'],
            'Actions': <String, dynamic>{
              '#ComputerSystem.Reset': <String, dynamic>{'target': '/x'},
            },
          },
        ],
        managers: <Map<String, dynamic>>[
          <String, dynamic>{
            '@odata.type': '#Manager.v1_16_0.Manager',
            'GraphicalConsole': <String, dynamic>{'Enabled': true},
          },
        ],
        chassis: <Map<String, dynamic>>[
          <String, dynamic>{
            '@odata.type': '#Chassis.v1_24_0.Chassis',
            'Thermal': <String, dynamic>{'@odata.id': '/t'},
          },
        ],
        thermals: <Map<String, dynamic>>[
          <String, dynamic>{
            'Temperatures': <dynamic>[<String, dynamic>{}],
          },
        ],
        updateService: <String, dynamic>{'FirmwareVersion': '9.9'},
        rawTree: <String, dynamic>{'/redfish/v1/': <String, dynamic>{}},
      );
      final SystemFeatures f = FeatureRules.build('bmc1', ctx);
      expect(f.powerControl, isTrue);
      expect(f.kvm, isTrue);
      expect(f.kvmType, 'GraphicalConsole');
      expect(f.sensorMonitoring, isTrue);
      expect(f.sensorCount, 1);
      expect(f.firmwareUpdate, isTrue);
      expect(f.updateServiceVersion, '9.9');
      expect(f.managers, 1);
      expect(f.chassis, 1);
      expect(f.systemId, 'bmc1');
    });
  });

  group('DiscoveryCache', () {
    test('get returns fresh entry and drops expired ones', () {
      final DiscoveryCache cache =
          DiscoveryCache(ttl: const Duration(hours: 1));
      final SystemFeatures f = const SystemFeatures(systemId: 'bmc1');
      cache.put(
        DiscoveryCacheEntry(
          systemId: 'bmc1',
          features: f,
          rawTree: const <String, dynamic>{},
          etags: const <String, String>{},
          fetchedAt: DateTime.now(),
        ),
      );
      expect(cache.get('bmc1'), isNotNull);
      expect(cache.peek('bmc1'), isNotNull);
      expect(cache.peekAllIds(), contains('bmc1'));

      cache.put(
        DiscoveryCacheEntry(
          systemId: 'bmc1',
          features: f,
          rawTree: const <String, dynamic>{},
          etags: const <String, String>{},
          fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );
      expect(cache.get('bmc1'), isNull);
      expect(cache.peekAllIds(), isNot(contains('bmc1')));
    });

    test('remove and clear behave', () {
      final DiscoveryCache cache = DiscoveryCache();
      final SystemFeatures f = const SystemFeatures(systemId: 'x');
      cache.put(
        DiscoveryCacheEntry(
          systemId: 'x',
          features: f,
          rawTree: const <String, dynamic>{},
          etags: const <String, String>{},
          fetchedAt: DateTime.now(),
        ),
      );
      cache.remove('x');
      expect(cache.peek('x'), isNull);
    });
  });

  group('InMemoryDiscoveryPersister', () {
    test('save/load/clear round-trips an entry', () async {
      final InMemoryDiscoveryPersister p = InMemoryDiscoveryPersister();
      final SystemFeatures f = const SystemFeatures(systemId: 'bmc1');
      final DiscoveryCacheEntry e = DiscoveryCacheEntry(
        systemId: 'bmc1',
        features: f,
        rawTree: const <String, dynamic>{},
        etags: const <String, String>{'a': 'b'},
        fetchedAt: DateTime.now(),
      );
      await p.save(e);
      expect((await p.load('bmc1'))?.etags['a'], 'b');
      await p.clear('bmc1');
      expect(await p.load('bmc1'), isNull);
    });
  });
}
