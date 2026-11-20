/// Fixture-drive tests for the canonical OpenBMC console Manager payload
/// (EP-T10, issues #009 / #021).
///
/// The KVM per-console and per-manager views previously relied on ad-hoc
/// in-temp mockups for selection / guidance tests. This file drives the shared
/// factories (`KvmConsole.fromManager` / `KvmCapability.fromManager`) from ONE
/// committed, valid Redfish `Manager` fixture — an HTML5-over-HTTPS graphical
/// console, a disabled serial console, an HTML5 remote console and an OEM
/// `Oem.OpenBMC.KVM.Uri` console — and pins the resulting selection, launch
/// guidance and cross-view agreement. Pure model work: no network, no live BMC,
/// no WebView / protocol plugin, no TLS weakening.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

const String _fixturePath =
    'test/fixtures/redfish/openbmc_console_manager.json';

Map<String, dynamic> _loadFixture() =>
    jsonDecode(File(_fixturePath).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('canonical OpenBMC console fixture (EP-T10 / #009/#021)', () {
    test('fixture is present and a valid Redfish Manager shape', () {
      final Map<String, dynamic> body = _loadFixture();
      expect(body['@odata.id'], '/redfish/v1/Managers/bmc');
      expect(body['@odata.type'], '#Manager.v1_19_0.Manager');
      expect(body['Id'], 'bmc');
      expect(body['GraphicalConsole'], isA<Map<String, dynamic>>());
      final Map<String, dynamic> graphical =
          body['GraphicalConsole'] as Map<String, dynamic>;
      expect(graphical['ServiceEnabled'], isA<bool>());
      expect(graphical['ConnectTypesSupported'], isA<List<dynamic>>());
      expect(graphical['ConnectUri'], isA<String>());
      expect(body['Oem'], isA<Map<String, dynamic>>());
    });

    group('KvmConsole.fromManager drives the fixture', () {
      late List<KvmConsole> consoles;
      setUp(() =>
          consoles = KvmConsole.fromManager(_loadFixture(), managerId: 'bmc'));

      test('yields one console per standard block plus the OEM console', () {
        expect(
          consoles.map((KvmConsole c) => c.type),
          <KvmConsoleType>[
            KvmConsoleType.graphical,
            KvmConsoleType.serial,
            KvmConsoleType.remote,
            KvmConsoleType.oem,
          ],
        );
        expect(
          consoles.every(
            (KvmConsole c) =>
                c.managerId == 'bmc' &&
                c.sourceManagerUri == '/redfish/v1/Managers/bmc',
          ),
          isTrue,
        );
      });

      test(
          'graphical HTML5-over-HTTPS console is launchable + in-app classified',
          () {
        final KvmConsole graphical = consoles.first;
        expect(graphical.serviceEnabled, isTrue);
        expect(graphical.connectTypesSupported, <String>['KVMIP', 'HTML5']);
        expect(graphical.maxConcurrentSessions, 2);
        expect(graphical.launchUri, 'https://bmc.example/kvm');
        expect(graphical.supportsHtml5, isTrue);
        expect(graphical.hasSecureLaunchUri, isTrue);
        expect(graphical.usesInsecureHttpLaunchUri, isFalse);
        expect(graphical.canLaunchInAppHtml5, isTrue);
        expect(graphical.launchStrategy, KvmLaunchStrategy.inAppHtml5);
        expect(graphical.canOpenConsole, isTrue);
      });

      test('graphical console resolves a safe production launch plan', () {
        final plan = consoles.first.launchPlan;
        // Production policy (WebView flag OFF): never in-app, never self-signed.
        expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
        expect(plan.targetUri, 'https://bmc.example/kvm');
        expect(plan.acceptSelfSigned, isFalse);
      });

      test('serial console is disabled; remote console is HTML5-over-HTTPS',
          () {
        final KvmConsole serial = consoles[1];
        expect(serial.type, KvmConsoleType.serial);
        expect(serial.serviceEnabled, isFalse);
        expect(serial.connectTypesSupported, <String>['SSH', 'Telnet']);
        expect(serial.launchStrategy, KvmLaunchStrategy.disabled);
        expect(serial.canOpenConsole, isFalse);

        final KvmConsole remote = consoles[2];
        expect(remote.type, KvmConsoleType.remote);
        expect(remote.serviceEnabled, isTrue);
        expect(remote.supportsHtml5, isTrue);
        expect(remote.launchUri, 'https://bmc.example/remote');
        expect(remote.launchStrategy, KvmLaunchStrategy.inAppHtml5);
        expect(remote.canOpenConsole, isTrue);
      });

      test('OEM console surfaces the vendor KVM URI via the generic path', () {
        final KvmConsole oem = consoles.last;
        expect(oem.type, KvmConsoleType.oem);
        expect(oem.serviceEnabled, isTrue);
        expect(oem.launchUri, 'https://bmc.example/oem-kvm');
        expect(oem.hasSecureLaunchUri, isTrue);
        expect(oem.launchStrategy, KvmLaunchStrategy.secureBrowser);
        expect(oem.canOpenConsole, isTrue);
      });
    });

    group('KvmCapability.fromManager drives the fixture', () {
      late KvmCapability capability;
      setUp(() => capability =
          KvmCapability.fromManager(_loadFixture(), managerId: 'bmc'));

      test('reports KVM support and aggregated console metadata', () {
        expect(capability.managerId, 'bmc');
        expect(capability.supported, isTrue);
        expect(capability.serviceEnabled, isTrue);
        expect(capability.supportsKvmIp, isTrue);
        // The explicitly disabled serial block's SSH/Telnet chips are skipped
        // while an enabled block advertises types; the OEM marker is appended.
        expect(capability.connectTypes, <String>['KVMIP', 'HTML5', 'Oem']);
        expect(capability.maxSessions, 2);
      });

      test('resolves the launchable graphical ConnectUri, not a resource link',
          () {
        expect(capability.uri, 'https://bmc.example/kvm');
        expect(capability.launchUri, 'https://bmc.example/kvm');
        expect(capability.hasUri, isTrue);
        expect(capability.hasSecureLaunchUri, isTrue);
        expect(capability.hasHttpLaunchUri, isTrue);
        expect(capability.usesInsecureHttpLaunchUri, isFalse);
        expect(capability.requiresExternalConsoleClient, isFalse);
        expect(capability.sourceManagerUri, '/redfish/v1/Managers/bmc');
        expect(capability.safeManagerUri, '/redfish/v1/Managers/bmc');
      });

      test('agrees with the console view on source, URI and enablement', () {
        final List<KvmConsole> consoles =
            KvmConsole.fromManager(_loadFixture(), managerId: 'bmc');
        final KvmConsole graphical = consoles.first;
        expect(capability.sourceManagerUri, graphical.sourceManagerUri);
        expect(capability.uri, graphical.launchUri);
        expect(
          capability.serviceEnabled,
          consoles.any((KvmConsole c) => c.serviceEnabled),
        );
      });
    });

    group('mutation sensitivity (drive logic is fixture-content driven)', () {
      test('removing the graphical ConnectUri flips both views off the target',
          () {
        final Map<String, dynamic> body = _loadFixture();
        (body['GraphicalConsole'] as Map<String, dynamic>).remove('ConnectUri');

        final KvmConsole graphical =
            KvmConsole.fromManager(body, managerId: 'bmc').first;
        expect(graphical.launchUri, isNull);
        expect(graphical.launchStrategy, KvmLaunchStrategy.noUri);
        expect(graphical.canOpenConsole, isFalse);

        // With the graphical link gone, the capability falls back to the next
        // enabled block's ConnectUri (the remote console), never a disabled one.
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'bmc');
        expect(capability.uri, 'https://bmc.example/remote');
      });
    });
  });
}
