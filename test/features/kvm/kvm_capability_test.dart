import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/redfish/discovery/feature_rules.dart';

void main() {
  group('KvmCapability.fromManager — detection', () {
    test('enabled graphical console with KVMIP is supported', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
            'MaxConcurrentSessions': 2,
            '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
          },
        },
        managerId: 'BMC',
      );

      expect(capability.managerId, 'BMC');
      expect(capability.supported, isTrue);
      expect(capability.serviceEnabled, isTrue);
      expect(capability.supportsKvmIp, isTrue);
      expect(capability.connectTypes, contains('KVMIP'));
      expect(capability.connectTypes, contains('HTML5'));
      expect(capability.maxSessions, 2);
      expect(capability.uri, '/redfish/v1/Managers/BMC/GraphicalConsole');
      expect(capability.hasUri, isTrue);
      expect(
        capability.sourceManagerUri,
        '/redfish/v1/Managers/BMC',
      );
    });

    test('disabled graphical console with KVMIP is not supported', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
      expect(capability.supportsKvmIp, isTrue);
    });

    test('enabled console without KVMIP is not supported', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isTrue);
      expect(capability.supportsKvmIp, isFalse);
    });

    test('KVMIP matching is case-insensitive and trimmed', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>[' kvmip '],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isTrue);
      expect(capability.supportsKvmIp, isTrue);
    });

    test('legacy Enabled field counts as enabled', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'Enabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isTrue);
      expect(capability.serviceEnabled, isTrue);
    });

    test('OEM console makes the manager supported', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{
              'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
            },
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isTrue);
      expect(capability.serviceEnabled, isTrue);
      expect(capability.connectTypes, contains('Oem'));
      expect(capability.uri, 'https://bmc.example/kvm');
    });

    test('bare vendor metadata Oem block is not a console', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{'Model': 'AST2500'},
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
      expect(capability.connectTypes, isEmpty);
      expect(capability.uri, isNull);
      expect(capability.hasUri, isFalse);
    });

    test('manager with no console blocks yields empty defaults', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC'},
        managerId: 'BMC',
      );

      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
      expect(capability.connectTypes, isEmpty);
      expect(capability.maxSessions, isNull);
      expect(capability.uri, isNull);
      expect(
        capability.sourceManagerUri,
        '/redfish/v1/Managers/BMC',
      );
    });

    test('sourceManagerUri defaults from manager id when absent', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{},
        managerId: 'BMC',
      );

      expect(capability.sourceManagerUri, '/redfish/v1/Managers/BMC');
    });

    test('explicit sourceManagerUri override is honoured', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{'@odata.id': '/ignored'},
        managerId: 'BMC',
        sourceManagerUri: '/custom/managers/BMC',
      );

      expect(capability.sourceManagerUri, '/custom/managers/BMC');
    });

    test('connect types are deduped and ordered graphical, serial, Oem', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          },
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5', 'SSH'],
          },
          'Oem': <String, dynamic>{
            'Vendor': <String, dynamic>{
              'WebConsole': <String, dynamic>{'URI': 'https://bmc/web'},
            },
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['KVMIP', 'HTML5', 'SSH', 'Oem']);
    });

    test('maxSessions falls back to serial when graphical omits it', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'SerialConsole': <String, dynamic>{
            'MaxConcurrentSessions': '4',
          },
        },
        managerId: 'BMC',
      );

      expect(capability.maxSessions, 4);
    });

    test('non-map console blocks are ignored without throwing', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': 'not-a-map',
          'SerialConsole': 42,
          'Oem': 'vendor',
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
      expect(capability.connectTypes, isEmpty);
      expect(capability.uri, isNull);
    });

    test('connectTypes list is unmodifiable', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
        },
        managerId: 'BMC',
      );

      expect(
        () => capability.connectTypes.add('HTML5'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('KvmCapability detection-field consistency (#009)', () {
    test('supportsKvmIp reflects the graphical console, not aggregate types',
        () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
          },
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', 'SSH'],
          },
        },
        managerId: 'BMC',
      );

      // KVMIP is advertised only on the serial block, so detection (which
      // keys off the graphical console) must not claim KVMIP support. The
      // value is still listed in connectTypes — it just is not the flag
      // `supported` / `supportsKvmIp` are defined against.
      expect(capability.supported, isFalse);
      expect(capability.supportsKvmIp, isFalse);
      expect(capability.connectTypes, contains('KVMIP'));
    });

    test('supportsKvmIp is true when the graphical console advertises KVMIP',
        () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['SSH'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isTrue);
      expect(capability.supportsKvmIp, isTrue);
    });

    test('connectTypes dedups case-insensitively, keeping first-seen casing',
        () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          },
          'SerialConsole': <String, dynamic>{
            'ConnectTypesSupported': <dynamic>['kvmip', ' SSH ', ' html5 '],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['KVMIP', 'HTML5', 'SSH']);
    });
  });

  group('KvmCapability connect-type tolerance (#009)', () {
    test('null and non-string ConnectTypesSupported entries are ignored', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>[
              'KVMIP',
              null,
              42,
              false,
              'HTML5',
            ],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['KVMIP', 'HTML5']);
      expect(capability.supported, isTrue);
      expect(capability.supportsKvmIp, isTrue);
    });

    test('a null-only ConnectTypesSupported list yields no chips', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>[
              null,
              1,
              <String>[],
            ],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, isEmpty);
    });
  });

  group('KvmCapability.resolveLaunchUri', () {
    test('prefers GraphicalConsole.@odata.id over an OEM KVM Uri', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
        },
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
      });

      expect(uri, '/redfish/v1/Managers/BMC/GraphicalConsole');
    });

    test('empty GraphicalConsole.@odata.id falls through to OEM', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{'@odata.id': ''},
        'Oem': <String, dynamic>{
          'Vendor': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
      });

      expect(uri, 'https://bmc.example/kvm');
    });

    test('finds a nested OEM WebConsole URI case-insensitively', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'Oem': <String, dynamic>{
          'Vendor': <String, dynamic>{
            'WebConsole': <String, dynamic>{'URI': 'https://bmc.example/web'},
          },
        },
      });

      expect(uri, 'https://bmc.example/web');
    });

    test('returns null when no graphical link or OEM URI is present', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{'ServiceEnabled': true},
        'Oem': <String, dynamic>{
          'Vendor': <String, dynamic>{'Model': 'AST2500'},
        },
      });

      expect(uri, isNull);
    });

    test('does not search deeper than the bounded depth', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'Oem': <String, dynamic>{
          'a': <String, dynamic>{
            'b': <String, dynamic>{
              'c': <String, dynamic>{
                'd': <String, dynamic>{
                  'KVM': <String, dynamic>{'Uri': 'https://too.deep/kvm'},
                },
              },
            },
          },
        },
      });

      expect(uri, isNull);
    });

    // #009: the per-manager capability card must surface the same launchable
    // console endpoint the per-console card already reads via
    // `KvmConsole._fromBlock` (`ConnectUri`). Prior to this fix the capability
    // only looked at `GraphicalConsole.@odata.id` (a Redfish API link, not a
    // console URL) and OEM `Uri`, so a manager exposing a real `ConnectUri`
    // rendered "No console URI resolved" — inconsistent with the console card.
    test('prefers GraphicalConsole.ConnectUri over its @odata.id link', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
          'ConnectUri': 'https://bmc.example/kvm',
        },
      });

      expect(uri, 'https://bmc.example/kvm');
    });

    test('resolves GraphicalConsole.ConnectUri when no @odata.id present', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example:443/kvm',
        },
      });

      expect(uri, 'https://bmc.example:443/kvm');
    });

    test('falls back to SerialConsole.ConnectUri', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{'ServiceEnabled': true},
        'SerialConsole': <String, dynamic>{
          'ConnectUri': 'ssh://bmc.example:22',
        },
      });

      expect(uri, 'ssh://bmc.example:22');
    });

    test('falls back to RemoteConsole.ConnectUri', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'RemoteConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/html5',
        },
      });

      expect(uri, 'https://bmc.example/html5');
    });

    test('a standard ConnectUri is preferred over an OEM KVM Uri', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/kvm',
        },
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/oem-kvm'},
          },
        },
      });

      expect(uri, 'https://bmc.example/kvm');
    });

    test('empty or non-string ConnectUri falls through to the next source', () {
      final String? empty = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': '',
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
        },
      });
      expect(empty, '/redfish/v1/Managers/BMC/GraphicalConsole');

      final String? nonString =
          KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{'ConnectUri': 42},
        'SerialConsole': <String, dynamic>{'ConnectUri': 'ssh://bmc'},
      });
      expect(nonString, 'ssh://bmc');
    });
  });

  group('KvmCapability.fromManager — ConnectUri consistency (#009)', () {
    test('a manager ConnectUri is surfaced as the resolved capability URI', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
            'ConnectUri': 'https://bmc.example/kvm',
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isTrue);
      expect(capability.hasUri, isTrue);
      expect(capability.uri, 'https://bmc.example/kvm');
    });
  });

  group('KvmCapability session-limit tolerance (#009)', () {
    test('out-of-spec negative graphical MaxConcurrentSessions is unreported',
        () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': -1,
          },
        },
        managerId: 'BMC',
      );
      // DMTF Manager schema: MaxConcurrentSessions minimum is 0. The
      // capability card must not render "Max sessions: -1".
      expect(capability.maxSessions, isNull);
    });

    test('negative graphical limit falls back to a spec-valid serial limit',
        () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': -1,
          },
          'SerialConsole': <String, dynamic>{
            'MaxConcurrentSessions': 3,
          },
        },
        managerId: 'BMC',
      );
      expect(capability.maxSessions, 3);
    });

    test('negative numeric-string limit is treated as unreported', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': '-9',
          },
          'SerialConsole': <String, dynamic>{
            'MaxConcurrentSessions': '-2',
          },
        },
        managerId: 'BMC',
      );
      expect(capability.maxSessions, isNull);
    });

    test('spec-valid zero session limit is preserved', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': 0,
          },
        },
        managerId: 'BMC',
      );
      expect(capability.maxSessions, 0);
    });
  });

  group('KvmCapability maxSessions skips disabled blocks (#009)', () {
    // The aggregate "Max sessions" must come from a console the operator can
    // actually launch, mirroring the enabled-preference already applied to the
    // resolved URI. Before this fix the limit was aggregated graphical-first
    // with no enablement check, so a disabled graphical console's limit won
    // over an enabled remote console's.

    test('disabled graphical limit is skipped for an enabled remote limit', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'ConnectUri': 'https://bmc.example/disabled-kvm',
            'MaxConcurrentSessions': 1,
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
            'ConnectUri': 'https://bmc.example/html5',
            'MaxConcurrentSessions': 4,
          },
        },
        managerId: 'BMC',
      );

      expect(capability.maxSessions, 4);
      // Both the limit and the resolved URI point at the launchable console.
      expect(capability.uri, 'https://bmc.example/html5');
    });

    test('legacy Enabled: false graphical limit is skipped', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'Enabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': 1,
          },
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['Serial'],
            'MaxConcurrentSessions': 2,
          },
        },
        managerId: 'BMC',
      );

      expect(capability.maxSessions, 2);
    });

    test('capability maxSessions agrees with the openable console card', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': 'https://bmc.example/disabled-kvm',
          'MaxConcurrentSessions': 1,
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/html5',
          'MaxConcurrentSessions': 4,
        },
      };
      final KvmConsole console = KvmConsole.fromManager(
        body,
        managerId: 'BMC',
      ).firstWhere((KvmConsole c) => c.canOpenConsole);
      final KvmCapability capability = KvmCapability.fromManager(
        body,
        managerId: 'BMC',
      );

      expect(capability.maxSessions, console.maxConcurrentSessions);
      expect(capability.maxSessions, 4);
    });

    test('sole disabled limit is still surfaced as the fallback', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': 1,
          },
        },
        managerId: 'BMC',
      );

      expect(capability.maxSessions, 1);
    });

    test('unknown-enablement block keeps its limit', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': 3,
          },
        },
        managerId: 'BMC',
      );

      expect(capability.maxSessions, 3);
    });
  });

  group('KvmCapability connectTypes skips disabled blocks (#009)', () {
    // The capability card's "Connection types" chips must describe a console
    // the operator can actually open, mirroring the enabled-preference already
    // applied to the resolved URI and the aggregate maxSessions. Before this
    // fix _appendTypes aggregated every console block unconditionally, so an
    // explicitly disabled graphical console's KVMIP chip sat beside (and won
    // ahead of) the launchable remote console's HTML5 chip.

    test('disabled graphical types are skipped for an enabled remote console',
        () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'ConnectUri': 'https://bmc.example/disabled-kvm',
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
            'ConnectUri': 'https://bmc.example/html5',
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['HTML5']);
      // The other capability fields already point at the launchable console.
      expect(capability.uri, 'https://bmc.example/html5');
    });

    test(
        'legacy Enabled: false graphical types are skipped for a serial '
        'console', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'Enabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['SSH'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['SSH']);
    });

    test('capability connectTypes agree with the openable console card', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': 'https://bmc.example/disabled-kvm',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/html5',
        },
      };
      final KvmConsole console = KvmConsole.fromManager(
        body,
        managerId: 'BMC',
      ).firstWhere((KvmConsole c) => c.canOpenConsole);
      final KvmCapability capability = KvmCapability.fromManager(
        body,
        managerId: 'BMC',
      );

      expect(console.connectTypesSupported, <String>['HTML5']);
      expect(capability.connectTypes, console.connectTypesSupported);
    });

    test('the Oem marker stays when a disabled graphical block is skipped', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
          },
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{
              'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
            },
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['HTML5', 'Oem']);
    });

    test('a sole disabled console still surfaces its types (fallback)', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['KVMIP']);
    });

    test('unknown-enablement blocks keep their types', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'RemoteConsole': <String, dynamic>{
            'ConnectTypesSupported': <dynamic>['HTML5'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['KVMIP', 'HTML5']);
    });
  });

  group('KvmCapability blank ConnectUri tolerance (#009)', () {
    test('blank graphical ConnectUri falls back to its @odata.id link', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC',
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'ConnectUri': '   ',
            '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
          },
        },
        managerId: 'BMC',
      );
      // A blank ConnectUri must not shadow the valid Redfish resource link.
      expect(capability.uri, '/redfish/v1/Managers/BMC/GraphicalConsole');
      expect(capability.hasUri, isTrue);
    });

    test('blank ConnectUri across all standard blocks resolves to no URI', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'ConnectUri': '  ',
          },
          'SerialConsole': <String, dynamic>{'ConnectUri': '\t\n'},
          'RemoteConsole': <String, dynamic>{'ConnectUri': ''},
        },
        managerId: 'BMC',
      );
      expect(capability.uri, isNull);
      expect(capability.hasUri, isFalse);
    });

    test('resolveLaunchUri skips a blank ConnectUri to the OEM KVM Uri', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{'ConnectUri': '   '},
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://oem.example/kvm'},
          },
        },
        managerId: 'BMC',
      );
      expect(capability.uri, 'https://oem.example/kvm');
    });

    test('a blank OEM Uri is ignored', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'Oem': <String, dynamic>{
          'KVM': <String, dynamic>{'Uri': '  \t '},
        },
      });
      expect(uri, isNull);
    });

    test('a valid ConnectUri is still preferred and preserved', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/kvm',
        },
      });
      expect(uri, 'https://bmc.example/kvm');
    });

    test('hasUri is false for a directly constructed blank uri', () {
      const KvmCapability capability = KvmCapability(
        managerId: 'BMC',
        supported: true,
        connectTypes: <String>['KVMIP'],
        serviceEnabled: true,
        uri: '   ',
      );
      expect(capability.uri, '   ');
      // The UI uses hasUri to decide whether to show a URI row; a blank uri
      // must take the "no URI" branch instead of rendering an empty value.
      expect(capability.hasUri, isFalse);
    });
  });

  group('KvmCapability padded URI normalization (#009)', () {
    test('resolveLaunchUri trims a whitespace-padded ConnectUri', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': '  https://bmc.example/kvm  ',
        },
      });
      expect(uri, 'https://bmc.example/kvm');
    });

    test('fromManager surfaces a trimmed resolved URI', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'ConnectUri': '\thttps://bmc.example/kvm\n',
          },
        },
        managerId: 'BMC',
      );
      expect(capability.hasUri, isTrue);
      expect(capability.uri, 'https://bmc.example/kvm');
    });

    test('a padded @odata.id graphical link is trimmed', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          '@odata.id': '  /redfish/v1/Managers/BMC/GraphicalConsole  ',
        },
      });
      expect(uri, '/redfish/v1/Managers/BMC/GraphicalConsole');
    });

    test('a padded OEM KVM Uri is trimmed', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'Oem': <String, dynamic>{
          'KVM': <String, dynamic>{'Uri': '  https://oem.example/kvm  '},
        },
      });
      expect(uri, 'https://oem.example/kvm');
    });

    test('launchUri trims a directly constructed padded uri', () {
      const KvmCapability capability = KvmCapability(
        managerId: 'BMC',
        supported: true,
        connectTypes: <String>['KVMIP'],
        serviceEnabled: true,
        uri: '  https://bmc.example/kvm  ',
      );
      // The normalized accessor must trim for any construction path (widget
      // fixtures, future call sites), keeping the card consistent with the
      // per-console card's launchUri.
      expect(capability.launchUri, 'https://bmc.example/kvm');
      expect(capability.hasUri, isTrue);
    });
  });

  group('KvmCapability.fromManager — RemoteConsole consistency (#009)', () {
    // `RemoteConsole` is treated as a standard console block everywhere else in
    // the KVM feature (KvmConsole.fromManager parses it; resolveLaunchUri reads
    // its ConnectUri), but fromManager's aggregate detection used to ignore it —
    // so a manager exposing only a RemoteConsole yielded an *enabled* console
    // card next to a "KVM not supported / disabled" capability card. These tests
    // pin the two views to the same detection.
    test('enabled RemoteConsole is supported, enabled, typed and limited', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
            'MaxConcurrentSessions': 3,
            'ConnectUri': 'https://bmc.example/html5',
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isTrue);
      expect(capability.serviceEnabled, isTrue);
      expect(capability.connectTypes, <String>['HTML5']);
      expect(capability.maxSessions, 3);
      expect(capability.uri, 'https://bmc.example/html5');
      // HTML5 is not KVMIP: supportsKvmIp stays false, detection is honest.
      expect(capability.supportsKvmIp, isFalse);
    });

    test(
        'console card and capability card agree on a RemoteConsole-only '
        'manager', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'MaxConcurrentSessions': 2,
          'ConnectUri': 'https://bmc.example/html5',
        },
      };
      final KvmConsole console = KvmConsole.fromManager(
        body,
        managerId: 'BMC',
      ).single;
      final KvmCapability capability = KvmCapability.fromManager(
        body,
        managerId: 'BMC',
      );

      expect(capability.serviceEnabled, console.serviceEnabled);
      expect(capability.connectTypes, console.connectTypesSupported);
      expect(capability.maxSessions, console.maxConcurrentSessions);
      expect(capability.launchUri, console.launchUri);
    });

    test(
        'RemoteConsole maxSessions is the fallback when graphical and '
        'serial report none', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['HTML5'],
            'MaxConcurrentSessions': 4,
          },
        },
        managerId: 'BMC',
      );

      expect(capability.maxSessions, 4);
    });

    test(
        'RemoteConsole connect types dedup case-insensitively with '
        'graphical types', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>[' kvmip ', 'HTML5'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['KVMIP', 'HTML5']);
    });

    test('disabled RemoteConsole does not report KVM support', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'RemoteConsole': <String, dynamic>{
            'ServiceEnabled': false,
            'ConnectTypesSupported': <dynamic>['HTML5'],
          },
        },
        managerId: 'BMC',
      );

      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
    });
  });

  group('RemoteConsole discovery-gate agreement (#009)', () {
    test(
        'RemoteConsole-only manager: discovery gate agrees with both KVM '
        'models', () {
      // A manager exposing only an enabled RemoteConsole is parsed by
      // KvmConsole.fromManager and reported supported by KvmCapability, but
      // FeatureRules.kvm (which gates the KVM tab) historically ignored it —
      // the last read path out of sync. All three must agree.
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.id': '/redfish/v1/Managers/BMC',
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/kvm',
        },
      };

      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');

      expect(capability.supported, isTrue);
      expect(consoles, isNotEmpty);
      expect(FeatureRules.kvm(<Map<String, dynamic>>[body]), isTrue);
      expect(
          FeatureRules.kvmType(<Map<String, dynamic>>[body]), 'RemoteConsole');
    });
  });

  group('KvmCapability malformed @odata.id tolerance (#009)', () {
    KvmCapability capabilityFrom(Object? odataId) => KvmCapability.fromManager(
          <String, dynamic>{
            '@odata.id': odataId,
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'ConnectTypesSupported': <dynamic>['KVMIP'],
            },
          },
          managerId: 'BMC',
        );

    // RED proof: `as String?` on a non-string @odata.id throws a TypeError,
    // aborting KvmCapability.fromManager and blanking the capability card.
    test('a non-string @odata.id does not throw and uses the derived URI', () {
      expect(capabilityFrom(42).sourceManagerUri, '/redfish/v1/Managers/BMC');
      expect(
        capabilityFrom(<String, dynamic>{'@odata.id': '/nested'})
            .sourceManagerUri,
        '/redfish/v1/Managers/BMC',
      );
    });

    test('a non-string explicit sourceManagerUri is ignored (#009)', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{'@odata.id': '/redfish/v1/Managers/BMC'},
        managerId: 'BMC',
        sourceManagerUri: null,
      );
      // With no override and a malformed body id, the derived URI is used.
      expect(capability.sourceManagerUri, '/redfish/v1/Managers/BMC');
    });

    test('a blank @odata.id falls back to the derived manager URI', () {
      expect(
          capabilityFrom('   ').sourceManagerUri, '/redfish/v1/Managers/BMC');
    });

    test('console and capability cards agree on a malformed @odata.id', () {
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.id': 42,
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.sourceManagerUri, '/redfish/v1/Managers/BMC');
      expect(capability.sourceManagerUri, console.sourceManagerUri);
    });
  });

  group('KvmCapability resolved URI — skip disabled blocks (#009)', () {
    // A disabled console's ConnectUri cannot be launched (KvmConsole's
    // launchStrategy == disabled and canOpenConsole == false). The capability
    // card is the per-manager summary of the console a user would actually
    // open, so it must not recommend a disabled console's URI while an enabled
    // one is available — the same cross-view contract pickPrimary now honours.
    test('a disabled graphical ConnectUri does not shadow an enabled remote',
        () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'https://bmc.example/disabled-kvm',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'https://bmc.example/html5',
        },
      });

      expect(uri, 'https://bmc.example/html5');
    });

    test('a legacy Enabled:false block is also skipped', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'Enabled': false,
          'ConnectUri': 'https://bmc.example/disabled-kvm',
        },
        'SerialConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectUri': 'ssh://bmc.example:22',
        },
      });

      expect(uri, 'ssh://bmc.example:22');
    });

    test('fromManager surfaces the openable console URI (cross-view agreement)',
        () {
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.id': '/redfish/v1/Managers/BMC',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'ConnectUri': 'https://bmc.example/disabled-kvm',
        },
        'RemoteConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['HTML5'],
          'ConnectUri': 'https://bmc.example/html5',
        },
      };
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(capability.uri, 'https://bmc.example/html5');

      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final KvmConsole openable =
          consoles.firstWhere((KvmConsole c) => c.canOpenConsole);
      expect(openable.launchUri, capability.uri);
      expect(consoles.where((KvmConsole c) => c.canOpenConsole).length, 1);
    });

    test('a sole disabled console URI is still surfaced (no over-skipping)',
        () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectUri': 'https://bmc.example/only-kvm',
        },
      });

      expect(uri, 'https://bmc.example/only-kvm');
    });

    test('an unknown-enablement ConnectUri is still preferred', () {
      // Most mockups omit the enablement flag; a URI from such a block keeps
      // its priority so this fix never regresses the established behaviour.
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ConnectUri': 'https://bmc.example/unknown-kvm',
        },
      });

      expect(uri, 'https://bmc.example/unknown-kvm');
    });
  });

  group('KvmCapability resolved URI — disabled graphical @odata.id (#009)', () {
    test('a disabled graphical @odata.id does not shadow an OEM KVM Uri', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
        },
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
      });

      expect(uri, 'https://bmc.example/kvm');
    });

    test('a legacy Enabled:false graphical @odata.id is also skipped', () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'Enabled': false,
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
        },
        'Oem': <String, dynamic>{
          'Vendor': <String, dynamic>{
            'WebConsole': <String, dynamic>{'Uri': 'https://bmc.example/web'},
          },
        },
      });

      expect(uri, 'https://bmc.example/web');
    });

    test('fromManager agrees with the openable per-console card', () {
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.id': '/redfish/v1/Managers/BMC',
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
        },
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
      };
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(capability.uri, 'https://bmc.example/kvm');

      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final KvmConsole openable =
          consoles.firstWhere((KvmConsole c) => c.canOpenConsole);
      expect(openable.launchUri, capability.uri);
    });

    test('a sole disabled graphical @odata.id is still surfaced (fallback)',
        () {
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': false,
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
        },
      });

      expect(uri, '/redfish/v1/Managers/BMC/GraphicalConsole');
    });

    test('unknown-enablement graphical @odata.id keeps its priority', () {
      // Mockups that omit the enablement flag keep the established behaviour.
      final String? uri = KvmCapability.resolveLaunchUri(<String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/BMC/GraphicalConsole',
        },
        'Oem': <String, dynamic>{
          'Vendor': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
      });

      expect(uri, '/redfish/v1/Managers/BMC/GraphicalConsole');
    });
  });

  group('KvmCapability OEM console enablement (#009)', () {
    KvmCapability capabilityFrom(Object? oem) => KvmCapability.fromManager(
          <String, dynamic>{'Oem': oem},
          managerId: 'BMC',
        );

    // RED proof: oemConsole (key presence) alone made the capability supported
    // + enabled regardless of the OEM block's own enablement flags, so the
    // capability card showed "Supported / Enabled" for a BMC-disabled KVM.
    test(
        'an explicitly disabled OEM console is neither supported nor '
        'enabled (#009)', () {
      final KvmCapability capability = capabilityFrom(<String, dynamic>{
        'KVM': <String, dynamic>{
          'Uri': 'https://bmc.example/kvm',
          'ServiceEnabled': false,
        },
      });
      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
    });

    test(
        'the legacy Enabled:false marker also disables an OEM capability '
        '(#009)', () {
      final KvmCapability capability = capabilityFrom(<String, dynamic>{
        'KVM': <String, dynamic>{
          'Uri': 'https://bmc.example/kvm',
          'Enabled': false,
        },
      });
      expect(capability.supported, isFalse);
      expect(capability.serviceEnabled, isFalse);
    });

    test(
        'a disabled OEM console does not suppress an enabled graphical '
        'KVM (#009)', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': 'https://oem.example/kvm',
              'ServiceEnabled': false,
            },
          },
        },
        managerId: 'BMC',
      );
      expect(capability.supported, isTrue);
      expect(capability.serviceEnabled, isTrue);
    });

    test('an OEM console with no enablement flag stays supported (guard)', () {
      final KvmCapability capability = capabilityFrom(<String, dynamic>{
        'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
      });
      expect(capability.supported, isTrue);
      expect(capability.serviceEnabled, isTrue);
    });
  });

  group('KvmCapability connectTypes Oem marker dedup (#009)', () {
    test('a literal OEM connect type is not duplicated by the Oem marker', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            // 'OEM' is a valid Redfish ConnectType; the capability card must
            // not also render its own case-different 'Oem' marker chip.
            'ConnectTypesSupported': <dynamic>['OEM'],
          },
          'Oem': <String, dynamic>{
            'Vendor': <String, dynamic>{
              'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
            },
          },
        },
        managerId: 'BMC',
      );

      expect(
        capability.connectTypes,
        <String>['OEM'],
        reason: 'the BMC-provided "OEM" spelling is kept once; the capability '
            'marker must not render a second, case-different chip',
      );
    });

    test('Oem marker dedup is case-insensitive (lower-case oem)', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['oem', 'HTML5'],
          },
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['oem', 'HTML5']);
    });

    test('Oem marker is still appended when no block advertises OEM', () {
      final KvmCapability capability = KvmCapability.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
          'Oem': <String, dynamic>{
            'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
          },
        },
        managerId: 'BMC',
      );

      expect(capability.connectTypes, <String>['KVMIP', 'Oem']);
    });

    test('per-console cards agree with the capability Oem dedup', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['OEM'],
        },
        'Oem': <String, dynamic>{
          'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
        },
      };
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final List<String> consoleTypes =
          consoles.expand((KvmConsole c) => c.connectTypesSupported).toList();

      // The graphical console card shows the single "OEM" type and the generic
      // OEM console card advertises no types, so the capability card must show
      // exactly the same set rather than a second case-different chip.
      expect(consoleTypes, <String>['OEM']);
      expect(capability.connectTypes, consoleTypes);
    });
  });

  group('KvmCapability resolved URI transport classification (#021)', () {
    KvmCapability cap(String? uri) => KvmCapability(
          managerId: 'BMC',
          supported: true,
          connectTypes: const <String>['HTML5'],
          serviceEnabled: true,
          uri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    test('a plaintext-HTTP resolved URI is flagged as insecure', () {
      final KvmCapability capability = cap('http://bmc.example/kvm');
      expect(capability.usesInsecureHttpLaunchUri, isTrue);
      expect(capability.hasSecureLaunchUri, isFalse);
    });

    test('an HTTPS resolved URI is secure and never flagged', () {
      final KvmCapability capability = cap('https://bmc.example/kvm');
      expect(capability.hasSecureLaunchUri, isTrue);
      expect(capability.usesInsecureHttpLaunchUri, isFalse);
    });

    test('a Redfish @odata.id path is neither secure nor insecure HTTP', () {
      final KvmCapability capability =
          cap('/redfish/v1/Managers/BMC/GraphicalConsole');
      expect(capability.hasSecureLaunchUri, isFalse);
      expect(capability.usesInsecureHttpLaunchUri, isFalse);
    });

    test('a padded plaintext-HTTP URI is trimmed then classified', () {
      final KvmCapability capability = cap('  http://bmc.example/kvm\t');
      expect(capability.launchUri, 'http://bmc.example/kvm');
      expect(capability.usesInsecureHttpLaunchUri, isTrue);
    });

    test('null / blank / non-HTTP-scheme URIs are never flagged insecure', () {
      for (final String? uri in <String?>[
        null,
        '   ',
        'vnc://bmc.example:5900',
        'file:///etc/passwd',
      ]) {
        expect(cap(uri).usesInsecureHttpLaunchUri, isFalse, reason: 'uri=$uri');
      }
    });
  });

  group(
      'KvmCapability control-character URI is never classified as secure '
      '(#009/#021)', () {
    KvmCapability cap(String? uri) => KvmCapability(
          managerId: 'BMC',
          supported: true,
          connectTypes: const <String>['HTML5'],
          serviceEnabled: true,
          uri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    // The capability card and the console card must agree on what a "secure"
    // resolved endpoint is. `Uri.tryParse` percent-encodes C0/DEL control chars
    // and still reports HTTPS + a host, so without the shared classifier this
    // getter called a CRLF/NUL-bearing endpoint secure while the fail-closed
    // launch plan refused it.
    test('a control-char-bearing HTTPS URI is not classified as secure', () {
      for (final String uri in <String>[
        'https://bmc.example/con\r\nsol',
        'https://bmc.example/con\u0000sol',
        'https://bmc.example/con\tsol',
        'https://bmc.exa\nmple/console',
      ]) {
        expect(cap(uri).hasSecureLaunchUri, isFalse, reason: uri);
      }
    });

    test('a clean HTTPS URI is still classified as secure (guard)', () {
      expect(cap('https://bmc.example/kvm').hasSecureLaunchUri, isTrue);
      expect(cap('https://bmc.example:8443/kvm').hasSecureLaunchUri, isTrue);
    });
  });

  group(
      'KvmCapability plaintext-HTTP classification is control-char-safe '
      '(#009/#021)', () {
    KvmCapability cap(String? uri) => KvmCapability(
          managerId: 'BMC',
          supported: true,
          connectTypes: const <String>['HTML5'],
          serviceEnabled: true,
          uri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    // Mirrors the console-view hardening: a raw-space/C0/DEL HTTP authority
    // must not be presented as a genuine unencrypted endpoint on the
    // capability card either. `Uri.tryParse` alone percent-encodes them.
    test('a control-char/raw-space HTTP URI is not flagged insecure', () {
      for (final String uri in <String>[
        'http://bmc.exa mple/console',
        'http://bmc.example/con\nsol',
        'http://bmc.example/con\u0000sol',
        'http://bmc.example/con\u007Fsol',
      ]) {
        expect(cap(uri).usesInsecureHttpLaunchUri, isFalse, reason: uri);
      }
    });

    test('a clean HTTP URI is still flagged insecure (guard)', () {
      expect(cap('http://bmc.example/kvm').usesInsecureHttpLaunchUri, isTrue);
    });

    test('console and capability views agree on HTTP-family classification',
        () {
      for (final String uri in <String>[
        'http://bmc.example/kvm',
        'https://bmc.example/kvm',
        'http://bmc.exa mple/console',
        'http://bmc.example/con\r\nsol',
        'vnc://bmc.example:5900',
      ]) {
        final KvmConsole console = KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: const <String>['HTML5'],
          serviceEnabled: true,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );
        expect(cap(uri).hasHttpLaunchUri, console.hasHttpLaunchUri,
            reason: uri);
        expect(cap(uri).usesInsecureHttpLaunchUri,
            console.usesInsecureHttpLaunchUri,
            reason: uri);
      }
    });
  });
}
