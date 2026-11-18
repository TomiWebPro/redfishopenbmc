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
  });
}
