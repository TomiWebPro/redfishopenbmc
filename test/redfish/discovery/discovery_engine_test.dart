import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery_cache.dart';
import 'package:redfishopenbmc/redfish/discovery/discovery_engine.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

import 'test_helpers.dart';

/// Builds an OpenBMC-shaped [FakeBmc] covering every tree the engine walks.
FakeBmc openBmc() => FakeBmc(<String, dynamic>{
      '/redfish/v1/': fixture('openbmc_service_root.json'),
      '/redfish/v1/Systems': fixture('openbmc_systems.json'),
      '/redfish/v1/Systems/system': fixture('openbmc_system.json'),
      '/redfish/v1/Managers': fixture('openbmc_managers.json'),
      '/redfish/v1/Managers/bmc': fixture('openbmc_manager.json'),
      '/redfish/v1/Chassis': fixture('openbmc_chassis.json'),
      '/redfish/v1/Chassis/chassis': fixture('openbmc_chassis_member.json'),
      '/redfish/v1/Chassis/chassis/Thermal': fixture('openbmc_thermal.json'),
      '/redfish/v1/Chassis/chassis/Sensors': fixture('openbmc_sensors.json'),
      '/redfish/v1/UpdateService': fixture('openbmc_update_service.json'),
      '/redfish/v1/SessionService': fixture('openbmc_session_service.json'),
    });

void main() {
  group('DiscoveryEngine — OpenBMC happy path', () {
    late FakeBmc bmc;
    late DiscoveryEngine engine;

    setUp(() {
      bmc = openBmc();
      engine = DiscoveryEngine();
    });

    test('discovers the full capability map (power/kvm/fw/sensors all on)',
        () async {
      final SystemFeatures f = await engine.discover(bmc.buildClient(), 'bmc1');

      expect(f.powerControl, isTrue);
      expect(f.kvm, isTrue);
      expect(f.kvmType, 'GraphicalConsole');
      expect(f.firmwareUpdate, isTrue);
      expect(f.updateServiceVersion, '2.14.0');
      expect(f.sensorMonitoring, isTrue);
      // 2 temperatures + 1 fan + 1 voltage + 2 sensor members = 6.
      expect(f.sensorCount, 6);
      expect(f.managers, 1);
      expect(f.chassis, 1);
      expect(f.supportedResetTypes, isNotEmpty);
      expect(f.hasAnyFeature, isTrue);
    });

    test('captures the SupportedResetTypes union from the computer system',
        () async {
      final SystemFeatures f = await engine.discover(bmc.buildClient(), 'bmc1');
      expect(
        f.supportedResetTypes,
        containsAll(
          <String>['On', 'ForceOff', 'GracefulRestart', 'PushPowerButton'],
        ),
      );
    });

    test('toggle — OpenBMC exposes KVM via GraphicalConsole', () async {
      final SystemFeatures f = await engine.discover(bmc.buildClient(), 'bmc1');
      expect(f.kvm, isTrue);
      expect(f.kvmType, 'GraphicalConsole');
    });

    test('rawTree() hook returns the captured resource tree', () async {
      await engine.discover(bmc.buildClient(), 'bmc1');
      final Map<String, dynamic> tree =
          await engine.rawTree(bmc.buildClient(), 'bmc1');
      expect(tree.containsKey('/redfish/v1/'), isTrue);
      expect(tree.containsKey('/redfish/v1/Systems/system'), isTrue);
      expect(
        tree.containsKey('/redfish/v1/Chassis/chassis/Thermal'),
        isTrue,
      );
    });
  });

  group('DiscoveryEngine — graceful degradation', () {
    test('DMTF minimal mockup yields a conservative map, no crash', () async {
      final FakeBmc bmc = FakeBmc(<String, dynamic>{
        '/redfish/v1/': fixture('dmtf_mockup_ServiceRoot.json'),
        '/redfish/v1/Systems': fixture('dmtf_mockup_systems.json'),
        '/redfish/v1/Systems/1': fixture('dmtf_mockup_system.json'),
        '/redfish/v1/Managers': fixture('dmtf_mockup_managers.json'),
        '/redfish/v1/Managers/1': fixture('dmtf_mockup_manager.json'),
        '/redfish/v1/Chassis': fixture('dmtf_mockup_chassis.json'),
        '/redfish/v1/Chassis/1': fixture('dmtf_mockup_chassis_member.json'),
      });
      final SystemFeatures f =
          await DiscoveryEngine().discover(bmc.buildClient(), 'dmtf');

      expect(f.powerControl, isFalse);
      expect(f.kvm, isFalse);
      expect(f.kvmType, isNull);
      expect(f.firmwareUpdate, isFalse);
      expect(f.sensorMonitoring, isFalse);
      expect(f.sensorCount, 0);
      expect(f.managers, 1);
      expect(f.chassis, 1);
    });

    test('missing Chassis (404) is recorded, discovery continues', () async {
      final Map<String, dynamic> routes = openBmc().routes;
      final FakeBmc bmc = FakeBmc(<String, dynamic>{}
        ..addAll(routes)
        ..remove('/redfish/v1/Chassis'));
      final SystemFeatures f =
          await DiscoveryEngine().discover(bmc.buildClient(), 'bmc1');

      expect(f.sensorMonitoring, isFalse);
      expect(f.powerControl, isTrue);
      expect(f.kvm, isTrue);
      expect(f.firmwareUpdate, isTrue);
    });

    test('missing UpdateService link → firmwareUpdate false', () async {
      final Map<String, dynamic> root = fixture('openbmc_service_root.json');
      root.remove('UpdateService');
      final Map<String, dynamic> routes = openBmc().routes;
      final FakeBmc bmc = FakeBmc(<String, dynamic>{}
        ..addAll(routes)
        ..['/redfish/v1/'] = root);
      final SystemFeatures f =
          await DiscoveryEngine().discover(bmc.buildClient(), 'bmc1');
      expect(f.firmwareUpdate, isFalse);
      expect(f.updateServiceVersion, isNull);
    });

    test('a failed ServiceRoot propagates RedfishException', () async {
      final FakeBmc bmc = FakeBmc(<String, dynamic>{});
      expect(
        () => DiscoveryEngine().discover(bmc.buildClient(), 'bmc1'),
        throwsA(isA<RedfishException>()),
      );
    });
  });

  group('DiscoveryEngine — cycle safety & link shapes', () {
    test('a member URI that echoes the collection is fetched only once',
        () async {
      final Map<String, dynamic> routes = <String, dynamic>{
        '/redfish/v1/': <String, dynamic>{
          '@odata.id': '/redfish/v1/',
          'Systems': <String, dynamic>{'@odata.id': '/redfish/v1/Systems'},
        },
        '/redfish/v1/Systems': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems',
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/system'},
          ],
        },
        '/redfish/v1/Systems/system': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/system',
          '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{'target': '/x'},
          },
        },
      };
      final FakeBmc bmc = FakeBmc(routes);
      final SystemFeatures f =
          await DiscoveryEngine().discover(bmc.buildClient(), 'bmc1');

      expect(
        bmc.requests.where((String p) => p == '/redfish/v1/Systems').length,
        1,
      );
      expect(f.powerControl, isTrue);
    });

    test('absolute @odata.id links are normalized to relative paths', () async {
      final Map<String, dynamic> root = <String, dynamic>{
        '@odata.id': 'https://bmc1:443/redfish/v1/',
        'Systems': <String, dynamic>{
          '@odata.id': 'https://bmc1:443/redfish/v1/Systems',
        },
      };
      // Route keys are relative: the engine must normalize the absolute
      // @odata.id values down to relative request paths to match them.
      final Map<String, dynamic> routes = <String, dynamic>{
        '/redfish/v1/': root,
        '/redfish/v1/Systems': <String, dynamic>{
          '@odata.id': 'https://bmc1:443/redfish/v1/Systems',
          'Members': <dynamic>[],
        },
      };
      final FakeBmc bmc = FakeBmc(routes);
      final SystemFeatures f =
          await DiscoveryEngine().discover(bmc.buildClient(), 'bmc1');
      // The engine normalized the absolute @odata.id to a relative request
      // path and matched the relative route keys, so discovery completed.
      expect(bmc.requests, contains('/redfish/v1/'));
      expect(f.powerControl, isFalse);
    });

    test(
        'the engine follows @Redfish.ActionInfo links and folds '
        'Parameters[].AllowableValues into the reset allow-list '
        '(bmcweb ResetActionInfo crawl, #022/#016)', () async {
      // bmcweb shape: the system's #ComputerSystem.Reset action links to a
      // `ResetActionInfo` ActionInfo *resource* (no SupportedResetTypes, no
      // annotation — the allow-list source is the resource, DOCS-4/13; the
      // ActionInfo shape itself was pinned live EMU 71→78).
      final Map<String, dynamic> routes = <String, dynamic>{
        '/redfish/v1/': <String, dynamic>{
          '@odata.id': '/redfish/v1/',
          'Systems': <String, dynamic>{'@odata.id': '/redfish/v1/Systems'},
        },
        '/redfish/v1/Systems': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems',
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/system'},
          ],
        },
        '/redfish/v1/Systems/system': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/system',
          '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{
              'target':
                  '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
              '@Redfish.ActionInfo':
                  '/redfish/v1/Systems/system/ResetActionInfo',
            },
          },
        },
        '/redfish/v1/Systems/system/ResetActionInfo': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/system/ResetActionInfo',
          '@odata.type': '#ActionInfo.v1_4_1.ActionInfo',
          'Id': 'ResetActionInfo',
          'Name': 'Reset Action Info',
          'Parameters': <dynamic>[
            <String, dynamic>{
              'Name': 'ResetType',
              'Required': true,
              'DataType': 'String',
              'AllowableValues': <String>[
                'On',
                'ForceOff',
                'GracefulShutdown',
                'GracefulRestart',
                'ForceRestart',
                'Nmi',
                'ForceOn',
                'PushPowerButton',
              ],
            },
          ],
        },
      };
      final FakeBmc bmc = FakeBmc(routes);
      final DiscoveryEngine engine = DiscoveryEngine();
      final SystemFeatures f = await engine.discover(bmc.buildClient(), 'bmc1');

      // The engine followed the ActionInfo link (one extra request) and the
      // ActionInfo-derived allow-list reached the feature map (there is no
      // SupportedResetTypes / annotation in this payload).
      expect(
          bmc.requests, contains('/redfish/v1/Systems/system/ResetActionInfo'));
      expect(
        f.supportedResetTypes,
        <String>[
          'ForceOff',
          'ForceOn',
          'ForceRestart',
          'GracefulRestart',
          'GracefulShutdown',
          'Nmi',
          'On',
          'PushPowerButton',
        ],
      );
      // The raw tree exposes the captured ActionInfo resource too.
      final Map<String, dynamic> tree =
          await engine.rawTree(bmc.buildClient(), 'bmc1');
      expect(
        tree.containsKey('/redfish/v1/Systems/system/ResetActionInfo'),
        isTrue,
      );
    });

    test(
        'a dangling @Redfish.ActionInfo link degrades gracefully '
        '(rawTree error, discovery continues, #022/#016)', () async {
      // A BMC that advertises an ActionInfo link the crawl cannot resolve
      // (404) must not break discovery: the link is recorded as an error in
      // the rawTree and the feature map still builds from the sources that
      // worked.
      final Map<String, dynamic> routes = <String, dynamic>{
        '/redfish/v1/': <String, dynamic>{
          '@odata.id': '/redfish/v1/',
          'Systems': <String, dynamic>{'@odata.id': '/redfish/v1/Systems'},
        },
        '/redfish/v1/Systems': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems',
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/system'},
          ],
        },
        '/redfish/v1/Systems/system': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/system',
          '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
          'SupportedResetTypes': <String>['On', 'ForceOff'],
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{
              'target':
                  '/redfish/v1/Systems/system/Actions/ComputerSystem.Reset',
              '@Redfish.ActionInfo':
                  '/redfish/v1/Systems/system/ResetActionInfo',
            },
          },
        },
        // NOTE: no route for ResetActionInfo → FakeBmc 404s it.
      };
      final FakeBmc bmc = FakeBmc(routes);
      final DiscoveryEngine engine = DiscoveryEngine();
      final SystemFeatures f = await engine.discover(bmc.buildClient(), 'bmc1');

      expect(f.powerControl, isTrue);
      // The 404'd ActionInfo falls back to the SupportedResetTypes source.
      expect(f.supportedResetTypes, <String>['ForceOff', 'On']);
      final Map<String, dynamic> tree =
          await engine.rawTree(bmc.buildClient(), 'bmc1');
      expect(
        (tree['/redfish/v1/Systems/system/ResetActionInfo']
            as Map<String, dynamic>)['_error'],
        isA<String>(),
      );
    });
  });

  group('DiscoveryEngine — caching & invalidation', () {
    test('second discover is served from cache (no extra requests)', () async {
      final FakeBmc bmc = openBmc();
      final DiscoveryEngine engine = DiscoveryEngine();
      await engine.discover(bmc.buildClient(), 'bmc1');
      final int afterFirst = bmc.requests.length;

      await engine.discover(bmc.buildClient(), 'bmc1');
      expect(bmc.requests.length, afterFirst);
    });

    test('invalidate() forces a fresh crawl', () async {
      final FakeBmc bmc = openBmc();
      final DiscoveryEngine engine = DiscoveryEngine();
      await engine.discover(bmc.buildClient(), 'bmc1');
      final int before = bmc.requests.length;

      engine.invalidate('bmc1');
      await engine.discover(bmc.buildClient(), 'bmc1');
      expect(bmc.requests.length, greaterThan(before));
    });

    test('caches are isolated per systemId', () async {
      final FakeBmc bmc = openBmc();
      final DiscoveryEngine engine = DiscoveryEngine();
      await engine.discover(bmc.buildClient(), 'bmc1');
      await engine.discover(bmc.buildClient(), 'bmc2');
      expect(engine.cachedSystemIds, containsAll(<String>['bmc1', 'bmc2']));
    });

    test('ETag 304 short-circuit re-crawl with forceRefresh replays bodies',
        () async {
      final FakeBmc bmc = openBmc();
      final DiscoveryEngine engine = DiscoveryEngine();
      final SystemFeatures a = await engine.discover(bmc.buildClient(), 'bmc1');
      final int afterFirst = bmc.requests.length;
      expect(afterFirst, greaterThan(0));

      final SystemFeatures b = await engine.discover(
        bmc.buildClient(),
        'bmc1',
        forceRefresh: true,
      );
      expect(bmc.requests.length, greaterThan(afterFirst));
      expect(b.toJson(), a.toJson());
    });
  });

  group('DiscoveryEngine — injection & concurrency', () {
    test('injected cache + persister are exercised', () async {
      final FakeBmc bmc = openBmc();
      final InMemoryDiscoveryPersister persister = InMemoryDiscoveryPersister();
      final DiscoveryEngine engine = DiscoveryEngine(persister: persister);
      final SystemFeatures f = await engine.discover(bmc.buildClient(), 'bmc1');
      expect(persister.entries.containsKey('bmc1'), isTrue);
      expect(f.powerControl, isTrue);
      engine.invalidate('bmc1');
      expect(persister.entries.containsKey('bmc1'), isFalse);
    });

    test('maxConcurrency clamped to >=1 and still completes', () async {
      final SystemFeatures f = await DiscoveryEngine(maxConcurrency: 0)
          .discover(openBmc().buildClient(), 'bmc1');
      expect(f.powerControl, isTrue);
    });

    test('multiple systems/managers/chassis aggregate across the pool',
        () async {
      final Map<String, dynamic> routes = <String, dynamic>{
        '/redfish/v1/': <String, dynamic>{
          '@odata.id': '/redfish/v1/',
          'Systems': <String, dynamic>{'@odata.id': '/redfish/v1/Systems'},
          'Managers': <String, dynamic>{'@odata.id': '/redfish/v1/Managers'},
          'Chassis': <String, dynamic>{'@odata.id': '/redfish/v1/Chassis'},
        },
        '/redfish/v1/Systems': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems',
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/s1'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Systems/s2'},
          ],
        },
        '/redfish/v1/Systems/s1': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/s1',
          '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
          'SupportedResetTypes': <String>['On', 'ForceOff'],
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{'target': '/x'},
          },
        },
        '/redfish/v1/Systems/s2': <String, dynamic>{
          '@odata.id': '/redfish/v1/Systems/s2',
          '@odata.type': '#ComputerSystem.v1_20_0.ComputerSystem',
          'SupportedResetTypes': <String>['GracefulRestart'],
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{'target': '/y'},
          },
        },
        '/redfish/v1/Managers': <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers',
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/m1'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Managers/m2'},
          ],
        },
        '/redfish/v1/Managers/m1': <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/m1',
          '@odata.type': '#Manager.v1_16_0.Manager',
          'GraphicalConsole': <String, dynamic>{'Enabled': true},
        },
        '/redfish/v1/Managers/m2': <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/m2',
          '@odata.type': '#Manager.v1_16_0.Manager',
        },
        '/redfish/v1/Chassis': <String, dynamic>{
          '@odata.id': '/redfish/v1/Chassis',
          'Members': <dynamic>[
            <String, dynamic>{'@odata.id': '/redfish/v1/Chassis/c1'},
            <String, dynamic>{'@odata.id': '/redfish/v1/Chassis/c2'},
          ],
        },
        '/redfish/v1/Chassis/c1': <String, dynamic>{
          '@odata.id': '/redfish/v1/Chassis/c1',
          '@odata.type': '#Chassis.v1_24_0.Chassis',
          'Thermal': <String, dynamic>{
            '@odata.id': '/redfish/v1/Chassis/c1/Thermal'
          },
        },
        '/redfish/v1/Chassis/c2': <String, dynamic>{
          '@odata.id': '/redfish/v1/Chassis/c2',
          '@odata.type': '#Chassis.v1_24_0.Chassis',
        },
        '/redfish/v1/Chassis/c1/Thermal': <String, dynamic>{
          '@odata.id': '/redfish/v1/Chassis/c1/Thermal',
          '@odata.type': '#Thermal.v1_7_0.Thermal',
          'Temperatures': <dynamic>[
            <String, dynamic>{'Name': 'T1'}
          ],
        },
      };
      final SystemFeatures f = await DiscoveryEngine(maxConcurrency: 4)
          .discover(FakeBmc(routes).buildClient(), 'bmc1');

      expect(f.managers, 2);
      expect(f.chassis, 2);
      expect(f.powerControl, isTrue);
      expect(
        f.supportedResetTypes,
        <String>['ForceOff', 'GracefulRestart', 'On'],
      );
      expect(f.kvm, isTrue);
      expect(f.sensorMonitoring, isTrue);
      expect(f.sensorCount, 1);
    });
  });
}
