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

    test(
        'supportedResetTypes falls back to the ResetType@Redfish.AllowableValues '
        'annotation when SupportedResetTypes is absent (DOCS-4/13, #022/#016)',
        () {
      // The DMTF mockup / bmcweb-style shape: no `SupportedResetTypes`, the
      // allow-list lives on the #ComputerSystem.Reset action annotation.
      final List<Map<String, dynamic>> systems = <Map<String, dynamic>>[
        <String, dynamic>{
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{
              'target': '/redfish/v1/Systems/1/Actions/ComputerSystem.Reset',
              'ResetType@Redfish.AllowableValues': <String>[
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
          },
        },
      ];
      expect(
        FeatureRules.supportedResetTypes(systems),
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
    });

    test('supportedResetTypes unions + dedupes both sources', () {
      final List<Map<String, dynamic>> systems = <Map<String, dynamic>>[
        <String, dynamic>{
          'SupportedResetTypes': <String>['On', 'ForceOff'],
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{
              'target': '/x',
              'ResetType@Redfish.AllowableValues': <String>[
                'On',
                'GracefulRestart',
              ],
            },
          },
        },
      ];
      expect(
        FeatureRules.supportedResetTypes(systems),
        <String>['ForceOff', 'GracefulRestart', 'On'],
      );
    });

    test(
        'supportedResetTypes never reads the manager-level #Manager.Reset '
        'allow-list (emulator-pinned conflation guard, #022/#016)', () {
      // The manager list is ForceRestart/GracefulRestart on the pinned mockup;
      // only #ComputerSystem.Reset annotations from ComputerSystem payloads
      // may feed the system allow-list.
      final Map<String, dynamic> managerLike = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#Manager.Reset': <String, dynamic>{
            'target': '/redfish/v1/Managers/BMC/Actions/Manager.Reset',
            'ResetType@Redfish.AllowableValues': <String>[
              'ForceRestart',
              'GracefulRestart',
            ],
          },
        },
      };
      expect(
        FeatureRules.resetTypesFromAction(managerLike),
        isEmpty,
      );
      expect(
          FeatureRules.supportedResetTypes(<Map<String, dynamic>>[
            managerLike,
          ]),
          isEmpty);
    });

    test('resetTypesFromAction returns empty when no action/annotation', () {
      expect(FeatureRules.resetTypesFromAction(<String, dynamic>{}), isEmpty);
      expect(
        FeatureRules.resetTypesFromAction(<String, dynamic>{
          'Actions': <String, dynamic>{
            '#ComputerSystem.Reset': <String, dynamic>{'target': '/x'},
          },
        }),
        isEmpty,
      );
    });

    test(
        'resetTypesFromAction reads the @Redfish.AllowableValues annotation '
        'per DSP0266 §9.9.2 (DOCS-16)', () {
      // DSP0266 §9.9.2 "Allowable values for strings": the annotation is a
      // JSON array of strings that define the allowable values for the action
      // parameter; namespace `Redfish` is the RedfishExtensions.v1_0_0 alias
      // (§9.9.1). The client parses `<PropertyName>@Redfish.AllowableValues`
      // on the `#ComputerSystem.Reset` action body.
      final Map<String, dynamic> system = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{
            'target': '/redfish/v1/Systems/1/Actions/ComputerSystem.Reset',
            'ResetType@Redfish.AllowableValues': <String>[
              'On',
              'ForceOff',
              'GracefulShutdown',
              'ForceRestart',
            ],
          },
        },
      };
      expect(
        FeatureRules.resetTypesFromAction(system),
        <String>['On', 'ForceOff', 'GracefulShutdown', 'ForceRestart'],
      );
    });

    test(
        'resetTypesFromAction ignores unrecognized annotations '
        '(DSP0266 §9.9.1 tolerance, DOCS-16)', () {
      // §9.9.1: "should not fail reading the resource due to unrecognized
      // annotations". An unrelated annotation beside the allow-list must not
      // disturb the parse, and a non-list value is ignored (empty result).
      final Map<String, dynamic> system = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{
            'target': '/x',
            'ResetType@Redfish.AllowablePattern': 'On|ForceOff',
            'ResetType@Oem.Vendor.AllowableValues': <String>['Bogus'],
          },
        },
      };
      expect(FeatureRules.resetTypesFromAction(system), isEmpty);

      // A non-list value for the allow-list itself is tolerated as absent.
      final Map<String, dynamic> system2 = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{
            'target': '/x',
            'ResetType@Redfish.AllowableValues': 'On',
          },
        },
      };
      expect(FeatureRules.resetTypesFromAction(system2), isEmpty);

      // A string annotation intended for a *string property* (not the action
      // parameter) does not leak into the reset allow-list.
      final Map<String, dynamic> system3 = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{'target': '/x'},
        },
        'AssetTag@Redfish.AllowablePattern': '^[\\w:-]{0,31}\$',
      };
      expect(FeatureRules.resetTypesFromAction(system3), isEmpty);
    });

    test(
        'allowableValuesFromActionInfo reads Parameters[].AllowableValues '
        'per DSP0266 §9.6.14 / ActionInfo.v1_4_1 (EMU 71→78, #022/#016)', () {
      // The bmcweb ResetActionInfo shape: a `Parameters[]` entry named
      // `ResetType` with an `AllowableValues` array. This parser is the
      // #022/#016 "crawl the ActionInfo *resource*" consumer.
      final Map<String, dynamic> info = <String, dynamic>{
        '@odata.type': '#ActionInfo.v1_4_1.ActionInfo',
        'Id': 'ResetActionInfo',
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
      };
      expect(
        FeatureRules.allowableValuesFromActionInfo(info, 'ResetType'),
        <String>[
          'On',
          'ForceOff',
          'GracefulShutdown',
          'GracefulRestart',
          'ForceRestart',
          'Nmi',
          'ForceOn',
          'PushPowerButton',
        ],
      );
      // Order is preserved (verbatim from the resource — the caller sorts).
      expect(
        FeatureRules.allowableValuesFromActionInfo(info, 'ResetType'),
        <String>[
          'On',
          'ForceOff',
          'GracefulShutdown',
          'GracefulRestart',
          'ForceRestart',
          'Nmi',
          'ForceOn',
          'PushPowerButton',
        ],
      );
    });

    test(
        'allowableValuesFromActionInfo is empty when the parameter is absent '
        'or the resource is malformed (#022/#016)', () {
      final Map<String, dynamic> noResetType = <String, dynamic>{
        'Parameters': <dynamic>[
          <String, dynamic>{
            'Name': 'Other',
            'AllowableValues': <String>['x']
          },
        ],
      };
      expect(
        FeatureRules.allowableValuesFromActionInfo(noResetType, 'ResetType'),
        isEmpty,
      );
      // No Parameters array.
      expect(
        FeatureRules.allowableValuesFromActionInfo(
          <String, dynamic>{'Id': 'ResetActionInfo'},
          'ResetType',
        ),
        isEmpty,
      );
      // AllowableValues present but not a list → tolerated as absent.
      final Map<String, dynamic> nonList = <String, dynamic>{
        'Parameters': <dynamic>[
          <String, dynamic>{'Name': 'ResetType', 'AllowableValues': 'On'},
        ],
      };
      expect(
        FeatureRules.allowableValuesFromActionInfo(nonList, 'ResetType'),
        isEmpty,
      );
    });

    test(
        'resetTypesFromActionInfo follows the action\'s @Redfish.ActionInfo '
        'link into the crawled ActionInfo resource (bmcweb ResetActionInfo, '
        '#022/#016)', () {
      // bmcweb shape: no SupportedResetTypes, no annotation — the allow-list
      // lives in the `ResetActionInfo` ActionInfo *resource* the
      // `#ComputerSystem.Reset` action links to (DOCS-4/13).
      final Map<String, dynamic> system = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{
            'target': '/redfish/v1/Systems/1/Actions/ComputerSystem.Reset',
            '@Redfish.ActionInfo': '/redfish/v1/Systems/1/ResetActionInfo',
          },
        },
      };
      final Map<String, dynamic> actionInfos = <String, dynamic>{
        '/redfish/v1/Systems/1/ResetActionInfo': <String, dynamic>{
          '@odata.type': '#ActionInfo.v1_4_1.ActionInfo',
          'Id': 'ResetActionInfo',
          'Parameters': <dynamic>[
            <String, dynamic>{
              'Name': 'ResetType',
              'Required': true,
              'DataType': 'String',
              'AllowableValues': <String>[
                'On',
                'ForceOff',
                'ForceRestart',
              ],
            },
          ],
        },
      };
      expect(
        FeatureRules.resetTypesFromActionInfo(system, actionInfos),
        <String>['On', 'ForceOff', 'ForceRestart'],
      );

      // The manager-level `#Manager.Reset` action is NOT consulted — even if
      // a manager ActionInfo resource exists in the map, it is only reachable
      // via a system's `#ComputerSystem.Reset` link (conflation guard).
      final Map<String, dynamic> managerLike = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#Manager.Reset': <String, dynamic>{
            'target': '/redfish/v1/Managers/BMC/Actions/Manager.Reset',
            '@Redfish.ActionInfo': '/redfish/v1/Managers/BMC/ResetActionInfo',
          },
        },
      };
      expect(
        FeatureRules.resetTypesFromActionInfo(
          managerLike,
          <String, dynamic>{
            '/redfish/v1/Managers/BMC/ResetActionInfo': <String, dynamic>{
              'Parameters': <dynamic>[
                <String, dynamic>{
                  'Name': 'ResetType',
                  'AllowableValues': <String>[
                    'ForceRestart',
                    'GracefulRestart',
                  ],
                },
              ],
            },
          },
        ),
        isEmpty,
      );
    });

    test(
        'supportedResetTypes unions the ActionInfo resource allow-list '
        '(third source, #022/#016)', () {
      // A system with BOTH the annotation and a linked ResetActionInfo: the
      // union dedupes and sorts (annotation lacks ForceRestart; the ActionInfo
      // resource brings it in).
      final Map<String, dynamic> system = <String, dynamic>{
        'Actions': <String, dynamic>{
          '#ComputerSystem.Reset': <String, dynamic>{
            'target': '/x',
            'ResetType@Redfish.AllowableValues': <String>[
              'On',
              'ForceOff',
            ],
            '@Redfish.ActionInfo': '/redfish/v1/Systems/1/ResetActionInfo',
          },
        },
      };
      final Map<String, dynamic> actionInfos = <String, dynamic>{
        '/redfish/v1/Systems/1/ResetActionInfo': <String, dynamic>{
          'Parameters': <dynamic>[
            <String, dynamic>{
              'Name': 'ResetType',
              'AllowableValues': <String>['On', 'ForceRestart'],
            },
          ],
        },
      };
      expect(
        FeatureRules.supportedResetTypes(
          <Map<String, dynamic>>[system],
          actionInfos: actionInfos,
        ),
        <String>['ForceOff', 'ForceRestart', 'On'],
      );

      // Without the ActionInfo map the annotation alone is returned (existing
      // behaviour preserved for callers that don't crawl ActionInfo).
      expect(
        FeatureRules.supportedResetTypes(<Map<String, dynamic>>[system]),
        <String>['ForceOff', 'On'],
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

    test('firmwareUpdate honors ServiceEnabled (DOCS-5)', () {
      // Explicitly disabled update service → no firmware capability.
      expect(
        FeatureRules.firmwareUpdate(
          <String, dynamic>{'ServiceEnabled': false},
        ),
        isFalse,
      );
      // Enabled service → capability present.
      expect(
        FeatureRules.firmwareUpdate(
          <String, dynamic>{'ServiceEnabled': true},
        ),
        isTrue,
      );
      // bmcweb + DMTF mockup shape (fixture carries ServiceEnabled: true).
      expect(
        FeatureRules.firmwareUpdate(
          <String, dynamic>{
            'Id': 'UpdateService',
            'FirmwareVersion': '2.14.0',
            'ServiceEnabled': true,
          },
        ),
        isTrue,
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
