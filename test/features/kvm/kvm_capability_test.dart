import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';

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
}
