/// RM-9 (#009/#021): OEM-console detection/resolution depth-bound agreement.
///
/// The shared recursion bound that decides "does this `Oem` payload expose a
/// console?" is duplicated across four entry points, two of them hardcoded:
///   - `FeatureRules.oemHasConsole` (the discovery/enablement gate, `depth > 3`),
///   - `kvmOemConsoleBlock` / `kvmOemConsoleUri` / `kvmOemConsoleEnabled`
///     (the two KVM cards' URI + enablement resolution, `maxDepth = 3`),
///   - `KvmOemRegistry._findAt` (registered-vendor block lookup, `depth > 3`),
///   - `KvmConsole.fromManager` / `KvmCapability.fromManager` (which combine the
///     detection gate with the URI/enablement helpers).
///
/// No single test pinned that they agree at the bound. A one-level change to any
/// one bound could make the capability card advertise "supported" while the
/// per-console card resolves no URI (or vice versa) — the exact #009 divergence
/// the shared helpers exist to prevent — and a deep hostile blob could recurse
/// without bound if the guards drifted apart.
///
/// This suite pins the agreement over a console nested at every depth from 0 to
/// beyond the bound (padded/mixed-case vendor key + non-map console value too),
/// plus the bounded-recursion guarantee for a deep blob. Audit found no live
/// divergence — this is a regression guard, not churn. Read-only, pure model,
/// dependency-free, TLS-safe: no URI opened, no WebView/protocol import.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_registry.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_oem_uri.dart';
import 'package:redfishopenbmc/redfish/discovery/feature_rules.dart';

const String _kConsoleUri = 'https://bmc.example/kvm';

/// Builds an `Oem` payload whose URI-bearing, enabled console-like `KVM` key sits
/// at recursion depth [keyDepth] (0 = directly under `Oem`).
Map<String, dynamic> _oemConsoleAtDepth(int keyDepth) {
  final Map<String, dynamic> console = <String, dynamic>{
    'Uri': _kConsoleUri,
    'ServiceEnabled': true,
  };
  Map<String, dynamic> node = <String, dynamic>{'KVM': console};
  for (int i = 0; i < keyDepth; i++) {
    node = <String, dynamic>{'N$i': node};
  }
  return node;
}

/// Builds a manager body carrying [oem] and a canonical manager id.
Map<String, dynamic> _managerWithOem(Map<String, dynamic> oem) =>
    <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'Oem': oem,
    };

/// The per-console card's OEM console for [body], or `null`.
KvmConsole? _oemConsole(Map<String, dynamic> body) {
  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: 'BMC');
  for (final KvmConsole console in consoles) {
    if (console.type == KvmConsoleType.oem) return console;
  }
  return null;
}

void main() {
  group('RM-9 detection/resolution agreement at the OEM depth bound', () {
    for (int depth = 0; depth <= 5; depth++) {
      final bool withinBound = depth <= 3;
      test('console at depth $depth: detection and URI resolution agree', () {
        final Map<String, dynamic> oem = _oemConsoleAtDepth(depth);

        final bool detected = FeatureRules.oemHasConsole(oem);
        final String? uri = kvmOemConsoleUri(oem);
        final Map<dynamic, dynamic>? block = kvmOemConsoleBlock(oem);
        final bool enabled = kvmOemConsoleEnabled(oem);

        if (withinBound) {
          expect(detected, isTrue, reason: 'depth $depth is within the bound');
          expect(uri, _kConsoleUri);
          expect(block, isNotNull);
          expect(enabled, isTrue);
        } else {
          expect(detected, isFalse, reason: 'depth $depth is beyond the bound');
          expect(uri, isNull);
          expect(block, isNull);
        }

        // The core invariant: a URI-bearing console is never "detected" by one
        // entry point while the resolution helpers find no URI (or vice versa).
        expect(detected, uri != null,
            reason: 'detection and URI resolution must flip at the SAME depth');
      });
    }
  });

  group('RM-9 both KVM model factories agree at the OEM depth bound', () {
    for (int depth = 0; depth <= 5; depth++) {
      final bool withinBound = depth <= 3;
      test('console at depth $depth: console card == capability card', () {
        final Map<String, dynamic> body =
            _managerWithOem(_oemConsoleAtDepth(depth));

        final KvmConsole? console = _oemConsole(body);
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        if (withinBound) {
          expect(console, isNotNull, reason: 'depth $depth within the bound');
          expect(console!.connectUri, _kConsoleUri);
          expect(console.serviceEnabled, isTrue);
          expect(console.canOpenConsole, isTrue);

          expect(capability.supported, isTrue);
          expect(capability.serviceEnabled, isTrue);
          expect(capability.uri, _kConsoleUri);
          expect(capability.hasSecureLaunchUri, isTrue);

          // Both surfaces must agree on the exact resolved endpoint.
          expect(console.launchUri, capability.launchUri);
          expect(console.hasSecureLaunchUri, capability.hasSecureLaunchUri);
        } else {
          expect(console, isNull, reason: 'depth $depth beyond the bound');
          expect(capability.supported, isFalse);
          expect(capability.uri, isNull);
        }
      });
    }
  });

  group('RM-9 registry vendor-block lookup honors the same bound', () {
    // A registered-vendor parser whose block sits at a controlled depth.
    final KvmOemRegistry registry = KvmOemRegistry(
      parsers: <KvmOemConsoleParser>[const _VendorXParser()],
    );

    Map<String, dynamic> oemVendorAtDepth(int depth) {
      Map<String, dynamic> node = <String, dynamic>{
        'VendorX': <String, dynamic>{
          'KVM': <String, dynamic>{'Uri': _kConsoleUri},
        },
      };
      for (int i = 0; i < depth; i++) {
        node = <String, dynamic>{'N$i': node};
      }
      return node;
    }

    for (int depth = 0; depth <= 5; depth++) {
      final bool withinBound = depth <= 3;
      test('vendor block at depth $depth resolves iff within the bound', () {
        final KvmOemConsoleInfo? info = registry.parse(oemVendorAtDepth(depth));
        if (withinBound) {
          expect(info, isNotNull, reason: 'depth $depth within the bound');
          expect(info!.connectUri, _kConsoleUri);
        } else {
          expect(info, isNull, reason: 'depth $depth beyond the bound');
        }
      });
    }
  });

  group('RM-9 hostile / edge payloads stay bounded and in agreement', () {
    test('padded, mixed-case vendor + console keys resolve on every surface',
        () {
      final Map<String, dynamic> oem = <String, dynamic>{
        '  VENDORX  ': <String, dynamic>{
          'KVM': <String, dynamic>{
            'Uri': _kConsoleUri,
          },
        },
      };
      expect(FeatureRules.oemHasConsole(oem), isTrue);
      expect(kvmOemConsoleUri(oem), _kConsoleUri);

      final Map<String, dynamic> body = _managerWithOem(oem);
      expect(_oemConsole(body), isNotNull);
      expect(
          KvmCapability.fromManager(body, managerId: 'BMC').uri, _kConsoleUri);
    });

    test('non-map console value fails closed on every surface', () {
      final Map<String, dynamic> oem = <String, dynamic>{
        'KVM': 'not a console map',
      };
      expect(FeatureRules.oemHasConsole(oem), isFalse);
      expect(kvmOemConsoleUri(oem), isNull);
      expect(kvmOemConsoleBlock(oem), isNull);

      final Map<String, dynamic> body = _managerWithOem(oem);
      expect(_oemConsole(body), isNull);
      expect(
          KvmCapability.fromManager(body, managerId: 'BMC').supported, isFalse);
    });

    test('deep hostile blob beyond the bound returns null, no overflow', () {
      // A 12-level nesting of scalar/blob siblings: resolution must stop at the
      // bound and return null rather than recurse without limit.
      dynamic node = <String, dynamic>{
        'KVM': <String, dynamic>{'Uri': _kConsoleUri},
      };
      for (int i = 0; i < 12; i++) {
        node = <String, dynamic>{
          'blob$i': <String, dynamic>{'data': 'x' * 64},
          'N$i': node,
        };
      }
      final Map<String, dynamic> oem = node as Map<String, dynamic>;

      expect(FeatureRules.oemHasConsole(oem), isFalse);
      expect(kvmOemConsoleUri(oem), isNull);
      expect(kvmOemConsoleBlock(oem), isNull);
    });
  });
}

/// A minimal registered-vendor parser used only to pin the registry bound.
class _VendorXParser extends KvmOemConsoleParser {
  const _VendorXParser();

  @override
  String get vendorKey => 'VendorX';

  @override
  KvmOemConsoleInfo? parse(Map<String, dynamic> block) {
    final Object? uri =
        block['KVM'] is Map ? (block['KVM'] as Map)['Uri'] : block['Uri'];
    if (uri is! String || uri.trim().isEmpty) return null;
    return KvmOemConsoleInfo(vendor: vendorKey, connectUri: uri.trim());
  }
}
