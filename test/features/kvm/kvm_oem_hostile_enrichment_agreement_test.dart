/// RM-20 (issue #009/#021) — registered-OEM hostile-enrichment normalization
/// agreement across both `fromManager` factories.
///
/// A registered [KvmOemConsoleParser] is third-party data, not a trusted
/// shortcut. RM-7 pins the launch-URI / classification agreement over a scheme
/// matrix, EP-M3 pins parser fault isolation and RM-9 pins the depth bound —
/// but nothing drives the *hostile enrichment* family (control/CRLF-bearing
/// URI, non-canonical / duplicate / blank connect types, padded manager id,
/// enablement flips) through BOTH `KvmConsole.fromManager` and
/// `KvmCapability.fromManager` while pinning the normalized STORED fields.
/// A one-sided "just store the vendor's raw values" edit could leak a padded or
/// control-bearing value onto the console card, or desync the two cards, while
/// every single-surface suite stayed GREEN.
///
/// This guard pins the documented contract:
///   * both factories normalize a vendor URI identically (trim, blank -> null),
///     agree on `launchUri` / transport classification and never badge a
///     control-bearing target as secure;
///   * the console card normalizes vendor connect types through the SAME shared
///     rule as every other source (trim, case-insensitive dedup keeping the
///     first spelling, drop blank entries) — no garbled/duplicate chip leaks;
///   * parsed enablement drives `supported` / `serviceEnabled` identically on
///     both cards, and a clean parser keeps its documented enrichment
///     byte-for-byte;
///   * a padded `managerId` stays byte-exact on both surfaces.
///
/// Pure Dart + flutter_test: no WebView/protocol import, no URL opened, no live
/// BMC, no dependency and no production TLS weakening (issues #009/#021).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm.dart';

/// A registered parser whose `Oem.AMI.Mgmt.EmbeddedUrl` shape is deliberately
/// NOT console-like, so it is discoverable ONLY through the registry (the generic
/// `FeatureRules.oemHasConsole` fallback cannot produce a console here). It
/// returns the configured, unnormalized enrichment verbatim.
class _EnrichmentVendorParser extends KvmOemConsoleParser {
  const _EnrichmentVendorParser({
    this.uri = 'https://custom.example/kvm',
    this.types = const <String>['HTML5'],
    this.enabled = true,
    this.displayName,
  });

  @override
  String get vendorKey => 'AMI';

  final String? uri;
  final List<String> types;
  final bool enabled;
  final String? displayName;

  @override
  KvmOemConsoleInfo? parse(Map<String, dynamic> block) {
    final dynamic mgmt = block['Mgmt'];
    if (mgmt is! Map<String, dynamic>) return null;
    final dynamic url = mgmt['EmbeddedUrl'];
    if (url is! String || url.trim().isEmpty) return null;
    return KvmOemConsoleInfo(
      vendor: vendorKey,
      connectUri: uri,
      connectTypesSupported: types,
      serviceEnabled: enabled,
      displayName: displayName,
    );
  }
}

void main() {
  Map<String, dynamic> vendorManager() => <String, dynamic>{
        '@odata.id': '/redfish/v1/Managers/BMC',
        'Oem': <String, dynamic>{
          'AMI': <String, dynamic>{
            'Mgmt': <String, dynamic>{
              'EmbeddedUrl': 'https://trigger.example/kvm',
            },
          },
        },
      };

  KvmOemRegistry registryFor(_EnrichmentVendorParser parser) =>
      KvmOemRegistry(parsers: <KvmOemConsoleParser>[parser]);

  KvmConsole? oemOf(List<KvmConsole> consoles) =>
      consoles.cast<KvmConsole?>().firstWhere(
            (KvmConsole? c) => c?.type == KvmConsoleType.oem,
            orElse: () => null,
          );

  // (raw vendor URI, expected normalized STORED uri on both factories).
  const List<(String, String?)> uriMatrix = <(String, String?)>[
    ('https://secure.example/kvm', 'https://secure.example/kvm'),
    ('  https://padded.example/kvm  ', 'https://padded.example/kvm'),
    (
      'https://bad.example\r\nX-Injected: 1',
      'https://bad.example\r\nX-Injected: 1'
    ),
    ('   ', null),
  ];

  group('RM-20 hostile-enrichment URI normalization agreement', () {
    test('matrix is non-trivial and every row is an HTTPS spell', () {
      expect(uriMatrix.length, 4);
      expect(uriMatrix.map((e) => e.$1).toSet().length, 4);
      expect(uriMatrix.take(3).every((e) => e.$1.trim().startsWith('https')),
          isTrue);
      expect(uriMatrix.last.$1.trim(), isEmpty);
      expect(uriMatrix.last.$2, isNull);
    });

    test('both factories store the same normalized vendor URI and classify '
        'identically over the hostile matrix', () {
      for (final (String raw, String? expected) in uriMatrix) {
        final String reason = 'raw=${raw.codeUnits}';
        final KvmOemRegistry registry =
            registryFor(_EnrichmentVendorParser(uri: raw));
        final Map<String, dynamic> body = vendorManager();

        final KvmConsole? oem = oemOf(
          KvmConsole.fromManager(body, managerId: 'BMC', oemRegistry: registry),
        );
        final KvmCapability capability = KvmCapability.fromManager(
          body,
          managerId: 'BMC',
          oemRegistry: registry,
        );

        expect(oem, isNotNull, reason: reason);
        // The STORED field (what the console card renders) is normalized exactly
        // as the capability card's resolved URI — no raw padding leaks through.
        expect(oem!.connectUri, expected, reason: reason);
        expect(capability.uri, expected, reason: reason);
        expect(oem.launchUri, capability.launchUri, reason: reason);
        expect(oem.launchUri != null, capability.hasUri, reason: reason);
        expect(oem.hasSecureLaunchUri, capability.hasSecureLaunchUri,
            reason: reason);
        expect(oem.hasHttpLaunchUri, capability.hasHttpLaunchUri,
            reason: reason);
        expect(oem.usesInsecureHttpLaunchUri,
            capability.usesInsecureHttpLaunchUri,
            reason: reason);
        expect(oem.requiresExternalConsoleClient,
            capability.requiresExternalConsoleClient,
            reason: reason);
        expect(oem.externalClientProtocolLabel,
            capability.externalClientProtocolLabel,
            reason: reason);
        // A control/CRLF-bearing vendor URI is stored verbatim (no silent
        // rewrite) but must never be badged as a genuine secure HTTPS target.
        if (raw.contains('\r') || raw.contains('\n')) {
          expect(oem.hasSecureLaunchUri, isFalse, reason: reason);
        }
      }
    });
  });

  group('RM-20 hostile-enrichment connect-type normalization', () {
    test('console card trims / drops blank / case-insensitive dedups vendor '
        'types, keeping the first BMC spelling', () {
      final KvmOemRegistry registry = registryFor(
        const _EnrichmentVendorParser(
          types: <String>[
            '  HTML5 ',
            'html5',
            '',
            '   ',
            'KVMIP',
            'kvmip',
            ' HTML5',
          ],
        ),
      );
      final KvmConsole? oem = oemOf(
        KvmConsole.fromManager(
          vendorManager(),
          managerId: 'BMC',
          oemRegistry: registry,
        ),
      );
      expect(oem, isNotNull);
      expect(oem!.connectTypesSupported, <String>['HTML5', 'KVMIP']);
      // No blank, control-bearing or case-duplicate chip can leak onto the card.
      expect(
        oem.connectTypesSupported
            .every((String t) => t.trim() == t && t.isNotEmpty),
        isTrue,
      );
    });

    test('a blank-only vendor type list normalizes to no chips on the card',
        () {
      final KvmOemRegistry registry = registryFor(
        const _EnrichmentVendorParser(types: <String>['', '  ', '\t']),
      );
      final KvmConsole? oem = oemOf(
        KvmConsole.fromManager(
          vendorManager(),
          managerId: 'BMC',
          oemRegistry: registry,
        ),
      );
      expect(oem, isNotNull);
      expect(oem!.connectTypesSupported, isEmpty);
    });
  });

  group('RM-20 hostile-enrichment enablement / clean-parser agreement', () {
    for (final bool enabled in <bool>[true, false]) {
      test('parsed serviceEnabled=$enabled drives both cards identically', () {
        final KvmOemRegistry registry =
            registryFor(_EnrichmentVendorParser(enabled: enabled));
        final Map<String, dynamic> body = vendorManager();
        final KvmConsole? oem = oemOf(
          KvmConsole.fromManager(body, managerId: 'BMC', oemRegistry: registry),
        );
        final KvmCapability capability = KvmCapability.fromManager(
          body,
          managerId: 'BMC',
          oemRegistry: registry,
        );
        expect(oem, isNotNull);
        expect(oem!.serviceEnabled, enabled);
        expect(oem.canOpenConsole, enabled);
        expect(capability.serviceEnabled, enabled);
        expect(capability.supported, enabled);
      });
    }

    test('a clean parser keeps its documented enrichment byte-for-byte', () {
      const String cleanUri = 'https://clean.example/kvm';
      const List<String> cleanTypes = <String>['HTML5', 'KVMIP'];
      final KvmOemRegistry registry = registryFor(
        const _EnrichmentVendorParser(
          uri: cleanUri,
          types: cleanTypes,
          displayName: 'Clean Vendor KVM',
        ),
      );
      final Map<String, dynamic> body = vendorManager();
      final KvmConsole? oem = oemOf(
        KvmConsole.fromManager(body, managerId: 'BMC', oemRegistry: registry),
      );
      final KvmCapability capability = KvmCapability.fromManager(
        body,
        managerId: 'BMC',
        oemRegistry: registry,
      );
      expect(oem, isNotNull);
      expect(oem!.connectUri, cleanUri);
      expect(oem.connectTypesSupported, cleanTypes);
      expect(capability.uri, cleanUri);
      expect(oem.canLaunchInAppHtml5, isTrue);
    });

    test('a padded managerId stays byte-exact on both factories', () {
      const String paddedId = '  BMC  ';
      final KvmOemRegistry registry =
          registryFor(const _EnrichmentVendorParser());
      final Map<String, dynamic> body = vendorManager();
      final KvmConsole? oem = oemOf(
        KvmConsole.fromManager(
          body,
          managerId: paddedId,
          oemRegistry: registry,
        ),
      );
      final KvmCapability capability = KvmCapability.fromManager(
        body,
        managerId: paddedId,
        oemRegistry: registry,
      );
      expect(oem, isNotNull);
      expect(oem!.managerId, paddedId);
      expect(capability.managerId, paddedId);
      expect(oem.sourceManagerUri, capability.sourceManagerUri);
    });
  });
}
