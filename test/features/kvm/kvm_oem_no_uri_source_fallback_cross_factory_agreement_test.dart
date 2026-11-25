// RM-31 (epic #009 / #021): the per-console card (`KvmConsole.fromManager`)
// and the per-manager capability card (`KvmCapability.fromManager`) read the
// SAME BMC-supplied manager body. When the OEM console carries no usable
// `ConnectUri`, both cards degrade to the manager SOURCE identity
// (`safeManagerUri`) as the last-resort "open externally" guidance and
// clipboard fallback — so the two factories must derive that control-safe
// source, the launch verdict and the manager id identically.
//
// AUDIT (before adding this guard): EP-M7 pins the body `@odata.id` RESOURCE
// PATH family, RM-15 pins bidi `@odata.id`, RM-21 / EP-M6 pin body
// query/fragment/userinfo and the derived-fallback precedence, RM-18/RM-19 pin
// the hostile-managerId DERIVED source, and EP-U42 pins the DISPLAY of the
// no-URI source fallback rows. Nothing, however, drives a matrix of OEM
// no-URI leaves (`Oem.*.KVM.Uri` / `Oem.*.WebConsole.Uri` absent, blank,
// non-string, control / bidi-bearing, relative or scheme-relative) through
// BOTH `fromManager` factories at once. A one-sided edit (e.g. an OEM
// "default launch endpoint" fallback added only to the per-console factory,
// or a source row that reflects the OEM URI on one card) could make the two
// cards disagree about the launch target / source identity or leak a raw
// control / bidi code point to one card while the other fails closed, and
// every single-surface suite stayed GREEN.
//
// Regression guard at a genuinely unguarded seam, not churn: today both
// factories resolve the manager source through the one shared
// `kvmManagerSourceUri` normalizer and both resolve the OEM endpoint through
// the one shared `kvmOemConsoleUri` helper, so they agree byte-for-byte.
// Pure-model, display-only, dependency-free and TLS-safe: no URL is opened,
// no WebView / protocol dependency is imported, and production TLS is
// untouched. No behaviour decision is folded in.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_manager_source.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';

/// One OEM no-URI body case: the `Uri` leaf under `Oem.OpenBMC.KVM`, an
/// optional hostile body `@odata.id`, and the launch URI both factories must
/// derive from that leaf.
class _OemCase {
  const _OemCase(this.name, this.uriLeaf, this.expectedLaunch,
      [this.odataId = _kCleanOdata]);

  final String name;
  final Object? uriLeaf;
  final String? expectedLaunch;
  final Object? odataId;
}

const String _kCleanOdata = '/redfish/v1/Managers/BMC';

void main() {
  const String managerId = 'BMC';
  const String derived = '/redfish/v1/Managers/BMC';
  const String cleanHttps = 'https://bmc.example/kvm';

  // Raw control / bidi / separator and structural bytes that must never reach
  // either card's source row or clipboard fallback (mirrors the shared gate).
  final RegExp rawControl = RegExp(r'[\\"<>{|}`^\p{C}\p{Z}]', unicode: true);

  const List<_OemCase> cases = <_OemCase>[
    // --- no usable OEM ConnectUri: both cards must fail closed to the source ---
    _OemCase('absent Uri leaf', null, null),
    _OemCase('blank Uri leaf', '', null),
    _OemCase('whitespace-only Uri leaf', '   ', null),
    _OemCase('non-string int Uri leaf', 42, null),
    _OemCase('non-string bool Uri leaf', true, null),
    _OemCase('non-string list Uri leaf', <dynamic>['x'], null),
    _OemCase('non-string map Uri leaf', <String, dynamic>{'x': 1}, null),
    _OemCase('CRLF-bearing Uri leaf', 'https://bmc.example/kvm\r\nX: 1',
        'https://bmc.example/kvm\r\nX: 1'),
    _OemCase('NUL-bearing Uri leaf', '/redfish/v1/Managers/BMC\x00',
        '/redfish/v1/Managers/BMC\x00'),
    _OemCase('bidi-control Uri leaf', '\u202Eevil/kvm', '\u202Eevil/kvm'),
    _OemCase('relative Uri leaf', '/kvm', '/kvm'),
    _OemCase(
        'scheme-relative Uri leaf', '//bmc.example/kvm', '//bmc.example/kvm'),
    // --- clean controls stay byte-exact on both views ---
    _OemCase('clean absolute HTTPS control', cleanHttps, cleanHttps),
    _OemCase('clean no-URI control', null, null),
    // --- hostile manager source leaves exercise the source fallback itself ---
    _OemCase(
        'non-string @odata.id falls back to manager-id source', null, null, 42),
    _OemCase('CRLF @odata.id fails closed to manager-id source', null, null,
        '/redfish/v1/Managers/BMC\r\nX: 1'),
  ];

  Map<String, dynamic> managerBody(_OemCase c) => <String, dynamic>{
        '@odata.id': c.odataId,
        'Oem': <String, dynamic>{
          'OpenBMC': <String, dynamic>{
            'KVM': <String, dynamic>{
              'Uri': c.uriLeaf,
              'ServiceEnabled': true,
            },
          },
        },
      };

  for (final _OemCase c in cases) {
    test(
        '${c.name}: both fromManager factories agree fail-closed on the '
        'source fallback and launch verdict (#009/#021)', () {
      final Map<String, dynamic> body = managerBody(c);
      final List<KvmConsole> consoles =
          KvmConsole.fromManager(body, managerId: managerId);
      final KvmCapability capability =
          KvmCapability.fromManager(body, managerId: managerId);

      // Exactly the one OEM console is surfaced, with no throw on the
      // non-map / non-string leaf variants.
      expect(consoles.length, 1, reason: c.name);
      final KvmConsole console = consoles.single;

      // Both factories resolve the SAME manager source through the shared
      // normalizer (single source of truth) and carry the same identity.
      final String expectedSource = kvmManagerSourceUri(c.odataId, managerId);
      expect(console.managerId, managerId, reason: c.name);
      expect(capability.managerId, managerId, reason: c.name);
      expect(console.sourceManagerUri, expectedSource, reason: c.name);
      expect(capability.sourceManagerUri, expectedSource, reason: c.name);
      expect(console.sourceManagerUri, capability.sourceManagerUri,
          reason: c.name);

      // Both expose the SAME control-safe source: no raw control / bidi /
      // separator byte may reach either card's source row or clipboard
      // fallback, and the two cards can never disagree on it.
      final String expectedSafe =
          isControlSafeConsoleUri(expectedSource) ? expectedSource : derived;
      expect(console.safeManagerUri, expectedSafe, reason: c.name);
      expect(capability.safeManagerUri, expectedSafe, reason: c.name);
      expect(console.safeManagerUri, capability.safeManagerUri, reason: c.name);
      expect(isControlSafeConsoleUri(console.safeManagerUri), isTrue,
          reason: c.name);
      expect(isControlSafeConsoleUri(capability.safeManagerUri), isTrue,
          reason: c.name);
      expect(rawControl.hasMatch(console.safeManagerUri), isFalse,
          reason: c.name);
      expect(rawControl.hasMatch(capability.safeManagerUri), isFalse,
          reason: c.name);

      // Both factories agree field-for-field on the OEM launch endpoint — a
      // one-sided "default launch URI" fallback on the per-console factory
      // breaks this for every no-URI leaf while the clean controls still pass.
      expect(console.launchUri, c.expectedLaunch, reason: c.name);
      expect(capability.launchUri, c.expectedLaunch, reason: c.name);
      expect(console.launchUri, capability.launchUri, reason: c.name);
      expect(console.hasSecureLaunchUri, capability.hasSecureLaunchUri,
          reason: c.name);

      // The explicit copy affordance degrades to a control-safe source on the
      // console card, never a raw control / bidi byte from the OEM leaf or the
      // manager source.
      expect(isControlSafeConsoleUri(console.clipboardTargetUri), isTrue,
          reason: c.name);
      expect(rawControl.hasMatch(console.clipboardTargetUri), isFalse,
          reason: c.name);
    });
  }

  test(
      'RM-31 clean controls stay byte-exact and no-URI controls fail closed '
      'on both views (#009/#021)', () {
    final KvmConsole cleanHttpsConsole =
        KvmConsole.fromManager(managerBody(cases[12]), managerId: managerId)
            .single;
    final KvmCapability cleanHttpsCapability =
        KvmCapability.fromManager(managerBody(cases[12]), managerId: managerId);
    expect(cleanHttpsConsole.launchUri, cleanHttps);
    expect(cleanHttpsCapability.launchUri, cleanHttps);
    expect(cleanHttpsConsole.hasSecureLaunchUri, isTrue);
    expect(cleanHttpsCapability.hasSecureLaunchUri, isTrue);

    final KvmConsole noUriConsole =
        KvmConsole.fromManager(managerBody(cases[13]), managerId: managerId)
            .single;
    final KvmCapability noUriCapability =
        KvmCapability.fromManager(managerBody(cases[13]), managerId: managerId);
    expect(noUriConsole.launchUri, isNull);
    expect(noUriCapability.launchUri, isNull);
    expect(noUriConsole.safeManagerUri, derived);
    expect(noUriCapability.safeManagerUri, derived);
    expect(noUriConsole.clipboardTargetUri, derived);
  });
}
