import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
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

    test('legacy Enabled field counts as enabled for a console (#009)', () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'Enabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
            'ConnectUri': 'https://bmc.example.com/kvm',
          },
        },
        managerId: 'BMC',
      );
      expect(consoles, hasLength(1));
      expect(consoles.single.serviceEnabled, isTrue);
      // With the legacy `Enabled` honored consistently with FeatureRules and
      // KvmCapability, the HTTPS HTML5 console is in-app launchable instead of
      // being mislabelled "disabled" on the console card / viewer.
      expect(consoles.single.launchStrategy, KvmLaunchStrategy.inAppHtml5);
    });

    test('non-bool ServiceEnabled does not throw and reads as disabled (#009)',
        () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': 'true',
            'ConnectTypesSupported': <dynamic>['KVMIP'],
          },
        },
        managerId: 'BMC',
      );
      expect(consoles, hasLength(1));
      expect(consoles.single.serviceEnabled, isFalse);
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

  group('KvmConsole secure-transport gating (#021)', () {
    // RED proof: today `canLaunchInAppHtml5` accepts a plaintext HTTP URI,
    // which would let the app treat an unencrypted BMC console as an in-app
    // render candidate. The app must never weaken TLS — HTTPS only.
    test('plain-HTTP HTML5 console is NOT in-app render eligible (#021)', () {
      const KvmConsole http = KvmConsole(
        type: KvmConsoleType.remote,
        managerId: 'BMC',
        connectTypesSupported: <String>['HTML5'],
        serviceEnabled: true,
        connectUri: 'http://bmc.example.com/kvm',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(http.hasHttpLaunchUri, isTrue,
          reason: 'plain HTTP is still an HTTP(S) launch URI');
      expect(http.canLaunchInAppHtml5, isFalse,
          reason: 'in-app console rendering must require HTTPS, never '
              'downgrade to plaintext HTTP');
    });

    test(
        'HTTPS HTML5 console is in-app eligible and not flagged insecure '
        '(#021)', () {
      const KvmConsole https = KvmConsole(
        type: KvmConsoleType.remote,
        managerId: 'BMC',
        connectTypesSupported: <String>['HTML5'],
        serviceEnabled: true,
        connectUri: 'https://bmc.example.com/kvm',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(https.hasSecureLaunchUri, isTrue);
      expect(https.usesInsecureHttpLaunchUri, isFalse);
      expect(https.canLaunchInAppHtml5, isTrue);
    });

    test(
        'secure/insecure transport getters classify schemes precisely '
        '(#021)', () {
      const KvmConsole plain = KvmConsole(
        type: KvmConsoleType.remote,
        managerId: 'BMC',
        connectTypesSupported: <String>['HTML5'],
        serviceEnabled: true,
        connectUri: 'http://bmc.example.com/kvm',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      const KvmConsole vnc = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP'],
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
      // Plaintext HTTP is an HTTP URI and is flagged insecure; never secure.
      expect(plain.hasHttpLaunchUri, isTrue);
      expect(plain.hasSecureLaunchUri, isFalse);
      expect(plain.usesInsecureHttpLaunchUri, isTrue);
      // Non-HTTP schemes and missing URIs are neither secure nor insecure HTTP.
      expect(vnc.hasSecureLaunchUri, isFalse);
      expect(vnc.usesInsecureHttpLaunchUri, isFalse);
      expect(noUri.hasSecureLaunchUri, isFalse);
      expect(noUri.usesInsecureHttpLaunchUri, isFalse);
    });
  });

  group('KvmConsole HTML5 connect-type matching (#021)', () {
    KvmConsole consoleWithTypes(
      List<String> types, {
      String uri = 'https://bmc.example.com/kvm',
    }) =>
        KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: types,
          serviceEnabled: true,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    // RED proof: before the case-insensitive/trimmed fix, a BMC emitting
    // 'html5' (lowercase) or ' HTML5 ' never matched `supportsHtml5`, so its
    // HTTPS console silently skipped the in-app HTML5 launch path.
    test('HTML5 connect type is matched case-insensitively and trimmed (#021)',
        () {
      expect(consoleWithTypes(<String>['HTML5']).supportsHtml5, isTrue);
      expect(consoleWithTypes(<String>['html5']).supportsHtml5, isTrue);
      expect(consoleWithTypes(<String>[' HTML5 ']).supportsHtml5, isTrue);
      expect(consoleWithTypes(<String>['html5']).canLaunchInAppHtml5, isTrue);
      // Case-insensitive matching must NOT bypass the HTTPS-only gate.
      expect(
        consoleWithTypes(
          <String>['html5'],
          uri: 'http://bmc.example.com/kvm',
        ).canLaunchInAppHtml5,
        isFalse,
        reason: 'looser HTML5 matching must still reject plaintext HTTP',
      );
    });
  });

  group('KvmConsole.launchStrategy (#021)', () {
    KvmConsole build({
      List<String> types = const <String>['HTML5'],
      bool enabled = true,
      String? uri = 'https://bmc.example.com/kvm',
    }) =>
        KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: types,
          serviceEnabled: enabled,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    test('no connect URI resolves to noUri', () {
      expect(build(uri: null).launchStrategy, KvmLaunchStrategy.noUri);
    });

    test('disabled service resolves to disabled ahead of transport', () {
      expect(build(enabled: false).launchStrategy, KvmLaunchStrategy.disabled);
      expect(
        build(
          enabled: false,
          uri: 'http://bmc.example.com/kvm',
        ).launchStrategy,
        KvmLaunchStrategy.disabled,
        reason: 'a disabled service is decided before transport classification',
      );
    });

    test('plaintext HTTP HTML5 resolves to insecureHtml5', () {
      expect(
        build(uri: 'http://bmc.example.com/kvm').launchStrategy,
        KvmLaunchStrategy.insecureHtml5,
      );
    });

    test('HTTPS HTML5 resolves to inAppHtml5', () {
      expect(build().launchStrategy, KvmLaunchStrategy.inAppHtml5);
    });

    test('external protocol resolves to externalClient', () {
      expect(
        build(
          types: const <String>['KVMIP'],
          uri: 'vnc://bmc.example.com:5900',
        ).launchStrategy,
        KvmLaunchStrategy.externalClient,
      );
    });

    test('HTTPS non-HTML5 resolves to secureBrowser (#021)', () {
      expect(
        build(types: const <String>['KVMIP']).launchStrategy,
        KvmLaunchStrategy.secureBrowser,
      );
      // A secure-browser suggestion is never offered for plaintext HTTP.
      expect(
        build(
          types: const <String>['KVMIP'],
          uri: 'http://bmc.example.com/kvm',
        ).launchStrategy,
        KvmLaunchStrategy.noUri,
        reason: 'the app must never suggest an unencrypted browser console',
      );
    });
  });

  group('kvmLaunchStatusText (#021)', () {
    test('every strategy has distinct, actionable, jargon-free guidance', () {
      final Set<String> texts = KvmLaunchStrategy.values
          .map(
            (KvmLaunchStrategy s) => kvmLaunchStatusText(
              s,
              externalProtocol: 'VNC/RFB',
            ),
          )
          .toSet();
      expect(texts.length, KvmLaunchStrategy.values.length,
          reason: 'no two strategies should read the same');
      for (final String text in texts) {
        expect(text, isNotEmpty);
        expect(text, isNot(contains('#')));
        expect(text, isNot(contains('issue')));
      }
      expect(
        kvmLaunchStatusText(
          KvmLaunchStrategy.externalClient,
          externalProtocol: 'VNC/RFB',
        ),
        contains('VNC/RFB client'),
      );
    });

    test('new guidance names the real blocker for disabled/secure consoles',
        () {
      final String disabled = kvmLaunchStatusText(KvmLaunchStrategy.disabled);
      expect(disabled, contains('disabled on the BMC'));
      expect(disabled, contains('Enable it'));
      final String secure =
          kvmLaunchStatusText(KvmLaunchStrategy.secureBrowser);
      expect(secure, contains('HTTPS'));
      expect(secure, contains('secure web browser'));
    });

    test('existing guidance is preserved verbatim for the original branches',
        () {
      expect(
        kvmLaunchStatusText(KvmLaunchStrategy.inAppHtml5),
        'In-app HTML5 console path available for this URI. '
        'Embedded rendering requires a WebView dependency. '
        'You can open this URI in a web browser if your BMC allows it.',
      );
      expect(
        kvmLaunchStatusText(KvmLaunchStrategy.insecureHtml5),
        'This HTML5 console uses an unencrypted HTTP connection. '
        'In-app rendering is disabled to keep console video and input '
        'encrypted. Configure the BMC console to use HTTPS before '
        'opening it in a browser.',
      );
      expect(
        kvmLaunchStatusText(
          KvmLaunchStrategy.externalClient,
          externalProtocol: 'VNC/RFB',
        ),
        'This console URI uses a protocol that requires an external '
        'VNC/RFB client. Embedded rendering is not available in-app. '
        'Copy the URI and open it with a compatible client.',
      );
      expect(
        kvmLaunchStatusText(KvmLaunchStrategy.noUri),
        'In-app embedded rendering is not available for this console. '
        'Use the URI externally if provided.',
      );
    });
  });

  group('KvmConsole connect-type normalization consistency (#009)', () {
    // RED proof: before normalization, KvmConsole stored the raw
    // ConnectTypesSupported list while KvmCapability trimmed + deduped the very
    // same console blocks. A BMC mixing casing / whitespace therefore rendered
    // duplicate, garbled chips on the console card while the capability card
    // showed one clean chip per type — two views disagreeing on the same data.
    test(
        'mixed-case and whitespace duplicates are collapsed, first casing kept',
        () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>[
              'KVMIP',
              ' kvmip ',
              'HTML5',
              'HTML5',
              ' KVMIP ',
            ],
          },
        },
        managerId: 'BMC',
      );
      expect(consoles, hasLength(1));
      expect(consoles.single.connectTypesSupported, <String>['KVMIP', 'HTML5']);
    });

    test('empty and whitespace-only entries are dropped (#009)', () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>[
              'KVMIP',
              '',
              '   ',
              'HTML5',
            ],
          },
        },
        managerId: 'BMC',
      );
      expect(consoles, hasLength(1));
      expect(consoles.single.connectTypesSupported, <String>['KVMIP', 'HTML5']);
    });

    test(
        'console card and capability card agree on the same console types (#009)',
        () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>[
            'KVMIP',
            ' kvmip ',
            ' HTML5 ',
            'html5',
          ],
          'ConnectUri': 'https://bmc.example.com/kvm',
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      // Both views read the same GraphicalConsole block; they must surface the
      // same clean, deduped, first-seen-casing list of connection types.
      expect(console.connectTypesSupported, capability.connectTypes);
      expect(console.connectTypesSupported, <String>['KVMIP', 'HTML5']);
    });
  });
}
