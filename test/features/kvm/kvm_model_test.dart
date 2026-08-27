import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// Reads and decodes the real DMTF `public-rackmount1` BMC manager fixture.
Map<String, dynamic> _loadBmc() {
  final String path = 'test/fixtures/redfish/dmtf_mockup/Managers/BMC/index.json';
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

    test('detects a graphical console backed by the real GraphicalConsole block',
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
  });
}
