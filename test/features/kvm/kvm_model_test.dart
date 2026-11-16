import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// Reads and decodes the real DMTF `public-rackmount1` BMC manager fixture.
Map<String, dynamic> _loadBmc() {
  final String path =
      'test/fixtures/redfish/dmtf_mockup/Managers/BMC/index.json';
  final String contents = File(path).readAsStringSync();
  return jsonDecode(contents) as Map<String, dynamic>;
}

void main() {
  group('KvmConsole.fromManager', () {
    late Map<String, dynamic> body;

    setUp(() => body = _loadBmc());

    test('extracts at least one console from the DMTF BMC manager', () {
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      expect(consoles, isNotEmpty);
    });

    test(
        'detects a graphical console backed by the real GraphicalConsole block',
        () {
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final KvmConsole? graphical = consoles.cast<KvmConsole?>().firstWhere(
            (KvmConsole? c) => c?.type == KvmConsoleType.graphical,
            orElse: () => null,
          );
      expect(graphical, isNotNull);
      expect(graphical!.managerId, 'BMC');
      // The DMTF mockup advertises KVMIP for its GraphicalConsole.
      expect(graphical.connectTypesSupported, contains('KVMIP'));
      expect(graphical.serviceEnabled, isTrue);
      expect(graphical.maxConcurrentSessions, 2);
      // The mockup has no ConnectUri; the manager URI is the fallback source.
      expect(graphical.connectUri, isNull);
      expect(graphical.sourceManagerUri, '/redfish/v1/Managers/BMC');
    });

    test('also exposes the serial console with its own connect types', () {
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final KvmConsole? serial = consoles.cast<KvmConsole?>().firstWhere(
            (KvmConsole? c) => c?.type == KvmConsoleType.serial,
            orElse: () => null,
          );
      expect(serial, isNotNull);
      expect(serial!.connectTypesSupported, contains('SSH'));
      expect(serial.connectTypesSupported, contains('Telnet'));
    });

    test('supportsHtml5 is false for the KVMIP-only mockup console', () {
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: 'BMC');
      final KvmConsole graphical = consoles.firstWhere(
        (KvmConsole c) => c.type == KvmConsoleType.graphical,
      );
      expect(graphical.supportsHtml5, isFalse);
    });

    test('HTML5 HTTP(S) connect URI is marked as in-app launchable (#021)', () {
      const KvmConsole console = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP', 'HTML5'],
        serviceEnabled: true,
        connectUri: 'https://bmc.example.com/kvm',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(console.launchUri, 'https://bmc.example.com/kvm');
      expect(console.hasHttpLaunchUri, isTrue);
      expect(console.canLaunchInAppHtml5, isTrue);
    });

    test('non-HTML5 or non-HTTP URI is not in-app HTML5 launchable (#021)', () {
      const KvmConsole noHtml5 = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: true,
        connectUri: 'https://bmc.example.com/kvm',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      const KvmConsole nonHttp = KvmConsole(
        type: KvmConsoleType.remote,
        managerId: 'BMC',
        connectTypesSupported: <String>['HTML5'],
        serviceEnabled: true,
        connectUri: 'vnc://bmc.example.com:5900',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      const KvmConsole noUri = KvmConsole(
        type: KvmConsoleType.oem,
        managerId: 'BMC',
        serviceEnabled: true,
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(noHtml5.canLaunchInAppHtml5, isFalse);
      expect(noHtml5.requiresExternalConsoleClient, isFalse);
      expect(nonHttp.hasHttpLaunchUri, isFalse);
      expect(nonHttp.canLaunchInAppHtml5, isFalse);
      expect(nonHttp.requiresExternalConsoleClient, isTrue);
      expect(noUri.launchUri, isNull);
      expect(noUri.canLaunchInAppHtml5, isFalse);
      expect(noUri.requiresExternalConsoleClient, isFalse);
    });

    test('KVMIP/RFB URI schemes require external console client (#021)', () {
      const KvmConsole kvmip = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: true,
        connectUri: 'kvmip://bmc.example.com:5900',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      const KvmConsole rfb = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP'],
        serviceEnabled: true,
        connectUri: 'rfb://bmc.example.com:5901',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(kvmip.requiresExternalConsoleClient, isTrue);
      expect(kvmip.externalClientProtocolLabel, 'KVMIP');
      expect(kvmip.canLaunchInAppHtml5, isFalse);
      expect(rfb.requiresExternalConsoleClient, isTrue);
      expect(rfb.externalClientProtocolLabel, 'VNC/RFB');
      expect(rfb.canLaunchInAppHtml5, isFalse);
    });

    test('serial console URI schemes require external client (#021)', () {
      const KvmConsole ssh = KvmConsole(
        type: KvmConsoleType.serial,
        managerId: 'BMC',
        connectTypesSupported: <String>['SSH'],
        serviceEnabled: true,
        connectUri: 'ssh://bmc.example.com:22',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      const KvmConsole telnet = KvmConsole(
        type: KvmConsoleType.serial,
        managerId: 'BMC',
        connectTypesSupported: <String>['Telnet'],
        serviceEnabled: true,
        connectUri: 'telnet://bmc.example.com:23',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(ssh.requiresExternalConsoleClient, isTrue);
      expect(ssh.externalClientProtocolLabel, 'SSH');
      expect(telnet.requiresExternalConsoleClient, isTrue);
      expect(telnet.externalClientProtocolLabel, 'Telnet');
    });

    test('KvmConsoleType.fromRedfish maps the standard block names', () {
      expect(
        KvmConsoleType.fromRedfish('GraphicalConsole'),
        KvmConsoleType.graphical,
      );
      expect(
        KvmConsoleType.fromRedfish('SerialConsole'),
        KvmConsoleType.serial,
      );
      expect(
        KvmConsoleType.fromRedfish('RemoteConsole'),
        KvmConsoleType.remote,
      );
      expect(KvmConsoleType.fromRedfish(null), KvmConsoleType.oem);
      expect(KvmConsoleType.graphical.label, 'Graphical Console');
    });

    test(
        'bare Oem vendor metadata is not reported as an OEM console '
        '(bmcweb-style, DOCS-4)', () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/bmc',
          'Oem': <String, dynamic>{
            'OpenBMC': <String, dynamic>{'FirmwareVersion': '1.0'},
          },
        },
        managerId: 'bmc',
      );
      expect(
        consoles.where((KvmConsole c) => c.type == KvmConsoleType.oem),
        isEmpty,
      );
    });

    test('Oem block with a console marker yields an OEM console', () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          '@odata.id': '/redfish/v1/Managers/bmc',
          'Oem': <String, dynamic>{
            'Vendor': <String, dynamic>{'Kvm': <String, dynamic>{}},
          },
        },
        managerId: 'bmc',
      );
      expect(
        consoles.where((KvmConsole c) => c.type == KvmConsoleType.oem),
        hasLength(1),
      );
    });
  });
}
