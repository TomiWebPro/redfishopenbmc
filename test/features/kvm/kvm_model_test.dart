import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

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

  group('KvmConsole.showHtml5WebUiHint (#009)', () {
    KvmConsole build({
      List<String> types = const <String>['HTML5'],
      String? uri,
      bool enabled = true,
    }) =>
        KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: types,
          serviceEnabled: enabled,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    // The card shows this hint beside the unencrypted-transport warning for a
    // plaintext-HTTP HTML5 console — two contradictory launch messages. The
    // hint must be suppressed for that case.
    test('plaintext-HTTP HTML5 console suppresses the normal-open hint', () {
      final KvmConsole console = build(uri: 'http://bmc.example.com/kvm');
      expect(console.supportsHtml5, isTrue);
      expect(console.usesInsecureHttpLaunchUri, isTrue);
      expect(console.showHtml5WebUiHint, isFalse,
          reason:
              'an unencrypted endpoint must not advertise a normal open path');
    });

    test('secure HTTPS HTML5 console keeps the normal-open hint', () {
      expect(
          build(uri: 'https://bmc.example.com/kvm').showHtml5WebUiHint, isTrue);
    });

    test('URI-less HTML5 console keeps the BMC web UI hint', () {
      // No direct ConnectUri means the console is opened from the BMC web UI —
      // there is no insecure endpoint for the hint to contradict.
      expect(build(uri: null).showHtml5WebUiHint, isTrue);
    });

    test('non-HTML5 console never shows the HTML5 hint', () {
      expect(
        build(types: const <String>['KVMIP'], uri: 'https://bmc/kvm')
            .showHtml5WebUiHint,
        isFalse,
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
    });

    test(
        'plaintext HTTP non-HTML5 resolves to insecureHttp, not noUri '
        '(#009/#021)', () {
      // A plaintext HTTP endpoint still carries a real, copyable URI — it must
      // not be collapsed into `noUri` (whose guidance says "use the URI if
      // provided" and gives NO unencrypted warning). It gets its own explicit
      // status that warns about the cleartext transport WITHOUT ever suggesting
      // an unencrypted browser console — the original safety intent is kept.
      final KvmConsole console = build(
        types: const <String>['KVMIP'],
        uri: 'http://bmc.example.com/kvm',
      );
      expect(console.hasHttpLaunchUri, isTrue);
      expect(console.usesInsecureHttpLaunchUri, isTrue);
      expect(console.launchStrategy, KvmLaunchStrategy.insecureHttp,
          reason: 'a plain HTTP endpoint is insecureHttp, not noUri');
      expect(console.canOpenConsole, isTrue,
          reason:
              'its URI is copyable/openable externally, like insecureHtml5');
      expect(kvmLaunchStatusText(console.launchStrategy),
          isNot(kvmLaunchStatusText(KvmLaunchStrategy.noUri)),
          reason: 'must not reuse the generic no-URI guidance');
    });

    test(
        'insecureHttp status warns about cleartext without suggesting a '
        'browser console (#021)', () {
      final String text = kvmLaunchStatusText(KvmLaunchStrategy.insecureHttp);
      expect(text, contains('unencrypted HTTP connection'));
      expect(text, contains('Configure the BMC console to use HTTPS'));
      expect(text, isNot(contains('secure HTTPS connection')));
      expect(text, isNot(contains('Open the URI in a secure')));
      expect(text, isNot(contains('HTML5 console')),
          reason: 'a non-HTML5 console must not be labelled HTML5');
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

    test('null and non-string ConnectTypesSupported entries are ignored (#009)',
        () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>[
              'KVMIP',
              null,
              42,
              true,
              'HTML5',
            ],
          },
        },
        managerId: 'BMC',
      );
      expect(consoles, hasLength(1));
      // A malformed BMC payload must not surface literal "null"/"42"/"true"
      // connection-type strings on the console card — only real Redfish
      // ConnectType enum string values are kept.
      expect(consoles.single.connectTypesSupported, <String>['KVMIP', 'HTML5']);
    });

    test('console and capability cards agree on malformed connect types (#009)',
        () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP', null, 7, 'HTML5'],
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.connectTypesSupported, <String>['KVMIP', 'HTML5']);
      expect(capability.connectTypes, <String>['KVMIP', 'HTML5']);
      expect(console.connectTypesSupported, capability.connectTypes);
    });
  });

  group('KvmConsole session-limit tolerance (#009)', () {
    test('out-of-spec negative MaxConcurrentSessions is treated as unreported',
        () {
      final KvmConsole console = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': -1,
          },
        },
        managerId: 'BMC',
      ).single;
      // DMTF Manager schema: MaxConcurrentSessions has minimum 0. A negative
      // value is out of spec (or a sentinel for "unlimited") — surface it as
      // unreported rather than rendering "Max concurrent sessions: -1".
      expect(console.maxConcurrentSessions, isNull);
    });

    test(
        'negative numeric-string MaxConcurrentSessions is treated as unreported',
        () {
      final KvmConsole console = KvmConsole.fromManager(
        <String, dynamic>{
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'MaxConcurrentSessions': '-5',
          },
        },
        managerId: 'BMC',
      ).single;
      expect(console.maxConcurrentSessions, isNull);
    });

    test('spec-valid zero and positive session limits are preserved', () {
      final List<KvmConsole> consoles = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'MaxConcurrentSessions': 0,
          },
          'SerialConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'MaxConcurrentSessions': '4',
          },
        },
        managerId: 'BMC',
      );
      expect(consoles[0].maxConcurrentSessions, 0);
      expect(consoles[1].maxConcurrentSessions, 4);
    });

    test('integral JSON double MaxConcurrentSessions is preserved (#009)', () {
      // Some BMC serializers emit integer-valued schema fields as JSON doubles
      // (e.g. nlohmann/jsona style "4.0"). dart:convert decodes that to a
      // `double`, which the old int-only parser silently dropped — losing the
      // session limit on the console card. It is a spec-valid count, so it must
      // be tolerated exactly like an `int` 4 (issues #009/#021).
      final KvmConsole console = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': 4.0,
          },
        },
        managerId: 'BMC',
      ).single;
      expect(console.maxConcurrentSessions, 4);
    });

    test('non-integral JSON double session limit is unreported (#009)', () {
      // A fractional count is out of spec (MaxConcurrentSessions is an integer
      // with minimum 0). Tolerating integral doubles must NOT admit 2.5.
      final KvmConsole console = KvmConsole.fromManager(
        <String, dynamic>{
          'GraphicalConsole': <String, dynamic>{
            'ServiceEnabled': true,
            'ConnectTypesSupported': <dynamic>['KVMIP'],
            'MaxConcurrentSessions': 2.5,
          },
        },
        managerId: 'BMC',
      ).single;
      expect(console.maxConcurrentSessions, isNull);
    });

    test('both KVM views agree on an integral double session limit (#009)', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'MaxConcurrentSessions': 3.0,
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.maxConcurrentSessions, 3);
      expect(capability.maxSessions, 3);
      expect(console.maxConcurrentSessions, capability.maxSessions);
    });

    test(
        'console card and capability card agree on rejecting a negative limit '
        '(#009)', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP'],
          'MaxConcurrentSessions': -1,
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.maxConcurrentSessions, capability.maxSessions);
      expect(capability.maxSessions, isNull);
    });
  });

  group('KvmConsole blank ConnectUri tolerance (#009)', () {
    KvmConsole consoleWithUri(Object? value) => KvmConsole.fromManager(
          <String, dynamic>{
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
              'ConnectUri': value,
            },
          },
          managerId: 'BMC',
        ).single;

    test('whitespace-only ConnectUri is treated as no URI', () {
      final KvmConsole console = consoleWithUri('   ');
      // A blank string is not a usable endpoint: the console card must not
      // render "Connect URI:   " and the viewer must fall back to the manager
      // URI rather than trying to open a blank target.
      expect(console.connectUri, isNull);
      expect(console.launchUri, isNull);
      expect(console.hasHttpLaunchUri, isFalse);
      expect(console.launchStrategy, KvmLaunchStrategy.noUri);
    });

    test('empty and tab/newline ConnectUri values are treated as no URI', () {
      expect(consoleWithUri('').connectUri, isNull);
      expect(consoleWithUri('\t\n ').connectUri, isNull);
    });

    test('non-string ConnectUri is treated as no URI', () {
      expect(consoleWithUri(42).connectUri, isNull);
    });

    test('a valid ConnectUri is preserved unchanged', () {
      final KvmConsole console = consoleWithUri('https://bmc.example/kvm');
      expect(console.connectUri, 'https://bmc.example/kvm');
      expect(console.launchUri, 'https://bmc.example/kvm');
      expect(console.launchStrategy, KvmLaunchStrategy.inAppHtml5);
    });

    test('a directly constructed blank connectUri has no launchUri', () {
      const KvmConsole console = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP', 'HTML5'],
        serviceEnabled: true,
        connectUri: '   ',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      expect(console.connectUri, '   ');
      // The normalized accessor must hide a blank URI even when a console is
      // constructed directly (widget-test fixtures, future call sites).
      expect(console.launchUri, isNull);
      expect(console.launchStrategy, KvmLaunchStrategy.noUri);
    });

    test('console and capability cards agree a blank ConnectUri is no URI', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'GraphicalConsole': <String, dynamic>{
          'ServiceEnabled': true,
          'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
          'ConnectUri': '   ',
        },
      };
      final KvmConsole console =
          KvmConsole.fromManager(body, managerId: 'BMC').single;
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.launchUri, isNull);
      expect(capability.uri, isNull);
      expect(capability.hasUri, isFalse);
    });
  });

  group('KvmConsole padded ConnectUri normalization (#009)', () {
    KvmConsole consoleWithUri(Object? value) => KvmConsole.fromManager(
          <String, dynamic>{
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'ConnectTypesSupported': <dynamic>['KVMIP', 'HTML5'],
              'ConnectUri': value,
            },
          },
          managerId: 'BMC',
        ).single;

    test('a whitespace-padded ConnectUri is stored trimmed and launchable', () {
      final KvmConsole console = consoleWithUri('  https://bmc.example/kvm  ');
      // Uri.tryParse rejects leading/trailing whitespace, so a padded endpoint
      // stored verbatim makes every launch decision fall back to "no URI".
      expect(console.connectUri, 'https://bmc.example/kvm');
      expect(console.launchUri, 'https://bmc.example/kvm');
      expect(console.hasSecureLaunchUri, isTrue);
      expect(console.launchStrategy, KvmLaunchStrategy.inAppHtml5);
    });

    test('a padded tab/newline ConnectUri is trimmed to a valid endpoint', () {
      final KvmConsole console = consoleWithUri('\thttps://bmc.example/kvm\n');
      expect(console.launchUri, 'https://bmc.example/kvm');
      expect(console.hasHttpLaunchUri, isTrue);
    });

    test('a padded external-protocol URI is classified correctly', () {
      final KvmConsole console = consoleWithUri('  ssh://bmc.example:22  ');
      expect(console.launchUri, 'ssh://bmc.example:22');
      expect(console.requiresExternalConsoleClient, isTrue);
      expect(console.externalClientProtocolLabel, 'SSH');
    });

    test('launchUri trims a directly constructed padded connectUri', () {
      const KvmConsole console = KvmConsole(
        type: KvmConsoleType.graphical,
        managerId: 'BMC',
        connectTypesSupported: <String>['KVMIP', 'HTML5'],
        serviceEnabled: true,
        connectUri: '  https://bmc.example/kvm  ',
        sourceManagerUri: '/redfish/v1/Managers/BMC',
      );
      // The normalized accessor must trim for any construction path (widget
      // fixtures, OEM registry parsers, future call sites), not just the
      // fromManager parser.
      expect(console.launchUri, 'https://bmc.example/kvm');
      expect(console.hasSecureLaunchUri, isTrue);
    });
  });

  group('KvmConsole OEM console URI agreement (#009)', () {
    KvmConsole oemConsoleFrom(Object? oem) => KvmConsole.fromManager(
          <String, dynamic>{
            '@odata.id': '/redfish/v1/Managers/BMC',
            'Oem': oem,
          },
          managerId: 'BMC',
        ).firstWhere((KvmConsole c) => c.type == KvmConsoleType.oem);

    // RED proof: the per-manager capability card resolves an OEM KVM `Uri`
    // (KvmCapability.resolveLaunchUri), but KvmConsole.fromManager built the
    // matching OEM console with connectUri == null — so the console card said
    // "No console connect URI available" while the capability card showed the
    // real endpoint. Both views must surface the same OEM URI.
    test(
        'OEM KVM Uri is surfaced on the OEM console and agrees with the '
        'capability card (#009)', () {
      final Map<String, dynamic> body = <String, dynamic>{
        '@odata.id': '/redfish/v1/Managers/BMC',
        'Oem': <String, dynamic>{
          'KVM': <String, dynamic>{'Uri': 'https://oem.example/kvm'},
        },
      };
      final KvmConsole console = KvmConsole.fromManager(body, managerId: 'BMC')
          .firstWhere((KvmConsole c) => c.type == KvmConsoleType.oem);
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: 'BMC');
      expect(console.launchUri, 'https://oem.example/kvm');
      expect(console.hasSecureLaunchUri, isTrue);
      expect(console.launchStrategy, KvmLaunchStrategy.secureBrowser);
      expect(capability.uri, 'https://oem.example/kvm');
      expect(console.launchUri, capability.launchUri);
    });

    test('case-insensitive, nested OEM WebConsole Uri is resolved (#009)', () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'Vendor': <String, dynamic>{
          'webconsole': <String, dynamic>{'uri': 'https://oem.example/web'},
        },
      });
      expect(console.launchUri, 'https://oem.example/web');
    });

    test('a padded OEM Uri is trimmed like every other URI source (#009)', () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'KVM': <String, dynamic>{'Uri': '  https://oem.example/kvm  '},
      });
      expect(console.launchUri, 'https://oem.example/kvm');
    });

    test('blank or non-string OEM Uri is not surfaced (#009)', () {
      expect(
        oemConsoleFrom(<String, dynamic>{
          'KVM': <String, dynamic>{'Uri': '   '},
        }).launchUri,
        isNull,
      );
      expect(
        oemConsoleFrom(<String, dynamic>{
          'KVM': <String, dynamic>{'Uri': 42},
        }).launchUri,
        isNull,
      );
    });
  });

  group('OEM console enablement (#009)', () {
    KvmConsole oemConsoleFrom(Object? oem) => KvmConsole.fromManager(
          <String, dynamic>{
            '@odata.id': '/redfish/v1/Managers/BMC',
            'Oem': oem,
          },
          managerId: 'BMC',
        ).firstWhere((KvmConsole c) => c.type == KvmConsoleType.oem);

    // RED proof: the generic OEM path hard-coded serviceEnabled: true, so a
    // BMC that explicitly disables its OEM console was still reported enabled
    // and launchable (secureBrowser / canOpenConsole == true) — the console card
    // offered "Open console" for a service the BMC said was off. Every other
    // console source (graphical/serial/remote) honors enablement.
    test(
        'an OEM console with ServiceEnabled:false is disabled and not '
        'openable (#009)', () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'KVM': <String, dynamic>{
          'Uri': 'https://bmc.example/kvm',
          'ServiceEnabled': false,
        },
      });
      expect(console.serviceEnabled, isFalse);
      expect(console.launchStrategy, KvmLaunchStrategy.disabled);
      expect(console.canOpenConsole, isFalse);
      expect(console.launchPlan.isCopyOnly, isTrue);
    });

    test(
        'the legacy Enabled:false marker also disables an OEM console '
        '(#009)', () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'KVM': <String, dynamic>{
          'Uri': 'https://bmc.example/kvm',
          'Enabled': false,
        },
      });
      expect(console.serviceEnabled, isFalse);
      expect(console.canOpenConsole, isFalse);
    });

    // Guards: no enablement member (the common mockup) and an explicit true
    // preserve the prior enabled behaviour; a truthy member wins over a false
    // one, exactly as for the standard console blocks.
    test('an OEM console with no enablement flag stays enabled (#009)', () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'KVM': <String, dynamic>{'Uri': 'https://bmc.example/kvm'},
      });
      expect(console.serviceEnabled, isTrue);
      expect(console.canOpenConsole, isTrue);
      expect(console.launchStrategy, KvmLaunchStrategy.secureBrowser);
    });

    test('an OEM console with ServiceEnabled:true stays enabled (#009)', () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'KVM': <String, dynamic>{
          'Uri': 'https://bmc.example/kvm',
          'ServiceEnabled': true,
        },
      });
      expect(console.serviceEnabled, isTrue);
      expect(console.canOpenConsole, isTrue);
    });

    test('a truthy legacy Enabled overrides ServiceEnabled:false (#009)', () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'KVM': <String, dynamic>{
          'Uri': 'https://bmc.example/kvm',
          'ServiceEnabled': false,
          'Enabled': true,
        },
      });
      expect(console.serviceEnabled, isTrue);
      expect(console.canOpenConsole, isTrue);
    });

    // RED proof (RM-1 / #009): a URI-less OEM console block that explicitly
    // reports ServiceEnabled:false is a disabled console exactly like a
    // standard block carrying the same flag. kvmOemConsoleEnabled previously
    // read enablement only from a Uri-bearing block, so a URI-less disabled
    // OEM console was wrongly reported enabled on the console card.
    test('a URI-less OEM console with ServiceEnabled:false is disabled (#009)',
        () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'OpenBMC': <String, dynamic>{
          'KVM': <String, dynamic>{'ServiceEnabled': false},
        },
      });
      expect(console.serviceEnabled, isFalse);
      expect(console.canOpenConsole, isFalse);
      expect(console.launchStrategy, KvmLaunchStrategy.noUri);
    });

    test('a URI-less OEM console with legacy Enabled:false is disabled (#009)',
        () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'OpenBMC': <String, dynamic>{
          'KVM': <String, dynamic>{'Enabled': false},
        },
      });
      expect(console.serviceEnabled, isFalse);
      expect(console.canOpenConsole, isFalse);
    });

    // Guard: a URI-less OEM console with no enablement flag stays enabled,
    // preserving all existing URI-less OEM mockups.
    test('a URI-less OEM console with no enablement flag stays enabled (#009)',
        () {
      final KvmConsole console = oemConsoleFrom(<String, dynamic>{
        'OpenBMC': <String, dynamic>{
          'KVM': <String, dynamic>{'Description': 'placeholder'},
        },
      });
      expect(console.serviceEnabled, isTrue);
    });
  });

  group('KvmConsole malformed @odata.id tolerance (#009)', () {
    KvmConsole consoleFrom(Object? odataId) => KvmConsole.fromManager(
          <String, dynamic>{
            '@odata.id': odataId,
            'GraphicalConsole': <String, dynamic>{
              'ServiceEnabled': true,
              'ConnectTypesSupported': <dynamic>['KVMIP'],
            },
          },
          managerId: 'BMC',
        ).single;

    // RED proof: `as String?` on a non-string @odata.id throws a TypeError,
    // aborting KvmConsole.fromManager and blanking every console on the card.
    test(
        'a non-string @odata.id does not throw and uses the derived manager URI',
        () {
      expect(consoleFrom(42).sourceManagerUri, '/redfish/v1/Managers/BMC');
      expect(
        consoleFrom(<String, dynamic>{'@odata.id': '/nested'}).sourceManagerUri,
        '/redfish/v1/Managers/BMC',
      );
    });

    test('a blank @odata.id falls back to the derived manager URI', () {
      expect(consoleFrom('   ').sourceManagerUri, '/redfish/v1/Managers/BMC');
    });

    test('a padded valid @odata.id is trimmed like other URI sources (#009)',
        () {
      expect(
        consoleFrom('  /redfish/v1/Managers/Custom  ').sourceManagerUri,
        '/redfish/v1/Managers/Custom',
      );
    });
  });

  group('KvmConsole.canOpenConsole (#009)', () {
    KvmConsole make({
      bool enabled = true,
      String? uri,
      List<String> types = const <String>[],
    }) =>
        KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: types,
          serviceEnabled: enabled,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    test('true for an enabled console with a usable HTTPS URI', () {
      expect(make(uri: 'https://bmc.example/kvm').canOpenConsole, isTrue);
    });

    test('true for an enabled external-protocol console', () {
      expect(make(uri: 'vnc://bmc.example:5900').canOpenConsole, isTrue);
    });

    test('true for an enabled insecure-HTML5 console (copyable URI)', () {
      expect(
        make(
          uri: 'http://bmc.example/kvm',
          types: const <String>['HTML5'],
        ).canOpenConsole,
        isTrue,
      );
    });

    test('false for a disabled console even with a URI', () {
      expect(
        make(enabled: false, uri: 'https://bmc.example/kvm').canOpenConsole,
        isFalse,
      );
    });

    test('false for an enabled console without a URI', () {
      expect(make().canOpenConsole, isFalse);
    });

    test('false for a blank URI', () {
      expect(make(uri: '   ').canOpenConsole, isFalse);
    });
  });

  group('KvmConsole.launchPlan — fail-closed production decision (#009/#021)',
      () {
    KvmConsole make({
      bool enabled = true,
      String? uri,
      List<String> types = const <String>[],
    }) =>
        KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: types,
          serviceEnabled: enabled,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    test('an enabled HTTPS HTML5 console routes to the external browser', () {
      final plan = make(
        uri: 'https://bmc.example/console',
        types: const <String>['HTML5'],
      ).launchPlan;

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example/console');
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a disabled console with an HTTPS URI fails closed to copy-only', () {
      // Mirrors canOpenConsole: a BMC may publish a ConnectUri while reporting
      // ServiceEnabled: false — the fail-closed plan must never hand it to a
      // browser (nor grant self-signed acceptance) even though it is HTTPS.
      final console = make(
        enabled: false,
        uri: 'https://bmc.example/console',
        types: const <String>['HTML5'],
      );
      expect(console.canOpenConsole, isFalse);
      expect(console.launchPlan.route, KvmConsoleRenderRoute.copyOnly);
      expect(console.launchPlan.isExternalBrowser, isFalse);
      expect(console.launchPlan.acceptSelfSigned, isFalse);
      expect(console.launchPlan.targetUri, 'https://bmc.example/console');
    });

    test('an insecure HTML5 console routes to copy-only', () {
      final plan = make(
        uri: 'http://bmc.example/console',
        types: const <String>['HTML5'],
      ).launchPlan;

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a padded URI is trimmed in the copy-only target', () {
      final plan = make(uri: '  http://bmc.example/console\n').launchPlan;

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.targetUri, 'http://bmc.example/console');
    });

    test(
        'clipboardTargetUri fails closed to the manager source for a '
        'control-char URI (#009/#021)', () {
      // The card's "Copy connect info" action must agree with the viewer: a
      // CRLF-bearing URI that the fail-closed launch plan refuses as a target
      // must never be placed on the clipboard (header/clipboard injection risk
      // when pasted). The raw endpoint stays visible; only the copy target
      // degrades to the safe manager source.
      for (final String uri in <String>[
        'https://bmc.example/kvm\r\nX-Injected: 1',
        'https://bmc.example/kvm\u0000evil',
        'https://bmc.exa mple/kvm',
        'https://bmc.example/kvm\\@evil.com',
        'https://bmc.example/kvm%/console',
      ]) {
        final KvmConsole console = make(uri: uri);
        expect(console.launchPlan.targetUri, isNull, reason: uri);
        expect(console.clipboardTargetUri, '/redfish/v1/Managers/BMC',
            reason: uri);
      }
    });

    test('clipboardTargetUri copies a valid URI byte-for-byte (guard)', () {
      // No regression for valid/control-safe targets: the trimmed endpoint is
      // copied, and a URI-less console still copies the manager source.
      expect(
        make(uri: '  https://bmc.example/console  ').clipboardTargetUri,
        'https://bmc.example/console',
      );
      expect(make().clipboardTargetUri, '/redfish/v1/Managers/BMC');
      // A plaintext HTTP (copy-only) endpoint keeps its trimmed URI.
      expect(
        make(uri: '  http://bmc.example/console\n').clipboardTargetUri,
        'http://bmc.example/console',
      );
      // Properly percent-encoded targets contain no raw forbidden chars and
      // remain copyable.
      expect(
        make(uri: 'https://bmc.example/console%20one').clipboardTargetUri,
        'https://bmc.example/console%20one',
      );
    });

    test('production can never render in-app or accept self-signed', () {
      // Even a fully-qualified, enabled, HTTPS HTML5 console stays on the
      // external-browser fallback under the production default policy, and no
      // console ever reaches inAppWebView or self-signed acceptance here.
      for (final KvmConsole console in <KvmConsole>[
        make(
            uri: 'https://bmc.example/console', types: const <String>['HTML5']),
        make(enabled: false, uri: 'https://bmc.example/console'),
        make(uri: 'http://bmc.example/console', types: const <String>['HTML5']),
      ]) {
        expect(console.launchPlan.isInApp, isFalse, reason: console.toString());
        expect(
          console.launchPlan.acceptSelfSigned,
          isFalse,
          reason: console.toString(),
        );
      }
    });
  });

  group(
      'KvmConsole control-character URI is never a secure launch target '
      '(#009/#021)', () {
    KvmConsole consoleWith(String uri) => KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: const <String>['HTML5'],
          serviceEnabled: true,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    // C0/DEL control characters inside a URI are malformed BMC data.
    // `Uri.tryParse` silently percent-encodes them and still reports
    // scheme=https + a non-empty host, so the model used to classify such a
    // target as secure and offer "Open console" — while the fail-closed launch
    // plan already refused to launch it. A CRLF/NUL-bearing target also risks
    // header/URI injection. The model and the decision layer must agree.
    test('a control-char-bearing HTTPS URI is never secure or openable', () {
      for (final String uri in <String>[
        'https://bmc.example/con\nsol', // LF
        'https://bmc.example/con\r\nsol', // CRLF
        'https://bmc.example/con\u0000sol', // NUL
        'https://bmc.example/con\tsol', // TAB
        'https://bmc.example/con\u007Fsol', // DEL
        'https://bmc.exa\nmple/console', // control char in host
      ]) {
        final KvmConsole console = consoleWith(uri);
        expect(console.hasSecureLaunchUri, isFalse, reason: uri);
        expect(console.canLaunchInAppHtml5, isFalse, reason: uri);
        expect(console.launchStrategy, KvmLaunchStrategy.noUri, reason: uri);
        expect(console.canOpenConsole, isFalse, reason: uri);
        // The fail-closed decision layer already agrees: no launchable route.
        expect(console.launchPlan.route, KvmConsoleRenderRoute.copyOnly,
            reason: uri);
      }
    });

    test('a clean HTTPS URI is still a secure, openable target (guard)', () {
      final KvmConsole console = consoleWith('https://bmc.example/kvm');
      expect(console.hasSecureLaunchUri, isTrue);
      expect(console.canLaunchInAppHtml5, isTrue);
      expect(console.canOpenConsole, isTrue);
      expect(console.launchStrategy, KvmLaunchStrategy.inAppHtml5);
    });
  });

  group(
      'KvmConsole plaintext-HTTP classification is control-char-safe '
      '(#009/#021)', () {
    KvmConsole consoleWith(String uri) => KvmConsole(
          type: KvmConsoleType.remote,
          managerId: 'BMC',
          connectTypesSupported: const <String>['HTML5'],
          serviceEnabled: true,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    // `isSecureHttpsConsoleUri` already rejects raw spaces / C0 / DEL, but the
    // plaintext-HTTP classifiers used a bare `Uri.tryParse`, which silently
    // percent-encodes those code units into the host/path and still reports a
    // valid `http` scheme + non-empty host. A malformed HTTP target must be
    // classified exactly like a malformed HTTPS one (fail closed), on both
    // the console and capability views — otherwise a CRLF/NUL-bearing URI can
    // drive the "Unencrypted HTTP console URI" warning as if it were real.
    test('a control-char/raw-space HTTP URI is not an HTTP/insecure target',
        () {
      for (final String uri in <String>[
        'http://bmc.exa mple/console', // raw space in host
        'http://bmc.example/con sol', // raw space in path
        'http://bmc.example/con\nsol', // LF
        'http://bmc.example/con\r\nsol', // CRLF
        'http://bmc.example/con\u0000sol', // NUL
        'http://bmc.example/con\tsol', // TAB
        'http://bmc.example/con\u007Fsol', // DEL
      ]) {
        final KvmConsole console = consoleWith(uri);
        expect(console.hasHttpLaunchUri, isFalse, reason: uri);
        expect(console.usesInsecureHttpLaunchUri, isFalse, reason: uri);
      }
    });

    test('a clean HTTP URI is still flagged insecure (guard)', () {
      final KvmConsole console = consoleWith('http://bmc.example/kvm');
      expect(console.hasHttpLaunchUri, isTrue);
      expect(console.usesInsecureHttpLaunchUri, isTrue);
      expect(console.launchStrategy, KvmLaunchStrategy.insecureHtml5);
    });
  });

  group('external-client classifiers share control-char hardening (#009/#021)',
      () {
    KvmConsole externalConsoleWith(String uri) => KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'BMC',
          connectTypesSupported: const <String>['KVMIP'],
          serviceEnabled: true,
          connectUri: uri,
          sourceManagerUri: '/redfish/v1/Managers/BMC',
        );

    // The HTTP(S) families share the _controlSafeTrimmedUri hardening, but the
    // non-HTTP external-client classifiers still used a bare Uri.tryParse that
    // silently percent-encodes raw spaces / C0 / DEL / Unicode separators into
    // a spoofed host. Because requiresExternalConsoleClient only checked the
    // scheme, such a malformed URI was still presented to the operator as a
    // legitimate external client ("requires an external VNC/RFB client") with
    // a copy affordance — disagreeing with how an equivalent malformed HTTPS or
    // HTTP URI is refused. It must fail closed to `noUri` on every surface.
    test('a control-char/raw-space external URI is not an external client', () {
      for (final String uri in <String>[
        'vnc://bmc.exa mple:5900', // raw space in host
        'vnc://bmc.example/con sol', // raw space in path
        'vnc://bmc.example/con\nsol', // LF
        'rfb://bmc.example/con\r\nsol', // CRLF
        'kvmip://bmc.example/con\u0000sol', // NUL
        'ssh://bmc.example/con\tsol', // TAB
        'telnet://bmc.example/con\u007Fsol', // DEL
        'rfb://bmc\u00A0.example:5900', // NBSP (Unicode separator)
        'vnc://bmc.example/\u200Bx', // zero-width space (invisible)
      ]) {
        final KvmConsole console = externalConsoleWith(uri);
        expect(console.requiresExternalConsoleClient, isFalse, reason: uri);
        expect(console.externalClientProtocolLabel, isNull, reason: uri);
        expect(console.launchStrategy, KvmLaunchStrategy.noUri, reason: uri);
        expect(console.canOpenConsole, isFalse, reason: uri);
      }
    });

    test('clean external URIs are still classified (guards)', () {
      final KvmConsole vnc = externalConsoleWith('vnc://bmc.example:5900');
      expect(vnc.requiresExternalConsoleClient, isTrue);
      expect(vnc.externalClientProtocolLabel, 'VNC/RFB');
      expect(vnc.launchStrategy, KvmLaunchStrategy.externalClient);
      expect(vnc.canOpenConsole, isTrue);

      final KvmConsole ssh = externalConsoleWith('ssh://bmc.example:22');
      expect(ssh.requiresExternalConsoleClient, isTrue);
      expect(ssh.externalClientProtocolLabel, 'SSH');

      // A properly percent-encoded target contains no raw forbidden chars and
      // stays a legitimate external client.
      final KvmConsole encoded =
          externalConsoleWith('vnc://bmc.example/console%20one');
      expect(encoded.requiresExternalConsoleClient, isTrue);
      expect(encoded.externalClientProtocolLabel, 'VNC/RFB');
    });
  });
}
