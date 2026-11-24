/// EP-P27 (issue #009/#021) — IPv6 zone-id / malformed-authority cross-layer
/// fail-closed agreement.
///
/// A BMC-supplied HTTPS `ConnectUri` may carry a scoped IPv6 zone id
/// (`[fe80::1%25eth0]` / `[fe80::1%eth0]`), a malformed bracket / percent
/// spelling, a zone id bearing a raw control / bidi / separator code point, or
/// an IPv4-mapped literal. Dart's `Uri.tryParse` normalises these into an opaque
/// host string that a browser / WebView (WHATWG URL) parser does not resolve the
/// same way: `Uri.tryParse` silently pct-encodes C0/DEL/Unicode-separator bytes
/// into the host, keeps a bare `%` verbatim and accepts a bracket-less literal —
/// so a naive `scheme == 'https' && host.isNotEmpty` check (the exact divergence
/// class documented in `launch_plan.dart`) would call such a target "secure".
///
/// Two independent decision families consume the same raw URI:
///   * the **platform layer** — [isSecureHttpsConsoleUri], [isHttpConsoleUri],
///     [planConsoleLaunch] (render route + control-safe copy target + self-
///     signed flag) and [allowsInAppNavigation] (RP-1 origin confinement), and
///   * the **model layer** — `KvmConsole.hasSecureLaunchUri` / `canOpenConsole` /
///     `launchStrategy` / `launchPlan`, which the console card and viewer gate on.
///
/// A future edit that reimplements a bare `Uri.tryParse` scheme/host check in one
/// of them could classify one of these shapes differently on one surface while
/// every existing single-surface suite stays GREEN. This guard drives the whole
/// zone-id / malformed-authority family through ALL layers at once and pins, per
/// value, both the expected classification (the AUDIT-FIRST characterization
/// below — verified against the shared fail-closed core) and cross-layer
/// agreement, recording the `Uri.tryParse` host for each case.
///
/// AUDIT FIRST: the shared whole-URI fail-closed core already classifies the
/// whole matrix identically on every layer (no live divergence, no behaviour
/// change), so this is a read-only characterization guard of a previously
/// unguarded cross-layer seam. EP-P21 pins the special-use IPv6 family (mapped
/// loopback, unique-local, unspecified, a single `%25` zone id) but never drives
/// a raw-`%` zone, a malformed bracket / percent spelling, or a control / bidi /
/// separator-bearing zone through all four layers plus the model. No production
/// behaviour is changed; no WebView/protocol import, no URL opened, no
/// dependency, no production TLS weakening (issues #009 / #021).
/// Complements EP-P9 / EP-P18 / EP-P21 with the zone-id + malformed-authority
/// family.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// One zone-id / malformed authority and its AUDITED secure classification under
/// the shared fail-closed core.
class _Case {
  const _Case(this.family, this.uri, this.secure, this.parsedHost);

  final String family;
  final String uri;
  final bool secure;
  final String? parsedHost; // Uri.tryParse(uri)?.host characterization.
}

// Classifications are CHARACTERIZATIONS of the current shared core, verified
// with isSecureHttpsConsoleUri across all four layers. Zone-id / malformed /
// control-bearing / IPv4-mapped authorities fail closed; pure-hex IPv6 and a
// clean IPv4 literal stay secure by design (real test-profile / legitimate
// targets). No control bytes leak into the three clean controls, so the matrix
// isolates the zone-id / malformed-AUTHORITY axis from the clean path axis.
const List<_Case> kZoneIdMatrix = <_Case>[
  _Case('clean-control', 'https://bmc.example/console', true, 'bmc.example'),
  _Case('clean-ipv6', 'https://[2001:db8::1]/console', true, '2001:db8::1'),
  _Case('clean-ipv4', 'https://192.0.2.1/console', true, '192.0.2.1'),
  // A percent-encoded zone separator (`%25`) or a bare `%` in the authority is
  // refused by the shared fail-closed gate (double-decoding / authority
  // confusion), even though Uri.tryParse keeps a non-empty host.
  _Case('zone-pct25', 'https://[fe80::1%25eth0]/console', false,
      'fe80::1%25eth0'),
  _Case('zone-raw-pct', 'https://[fe80::1%eth0]/console', false,
      'fe80::1%25eth0'),
  // A zone id carrying a raw control / bidi format / separator byte is
  // pct-encoded into the host by Uri.tryParse; the shared control-safety gate
  // refuses it identically on every layer.
  _Case('zone-nul', 'https://[fe80::1%25eth\u0000]/console', false,
      'fe80::1%25eth%00'),
  _Case('zone-bidi', 'https://[fe80::1%25eth\u202E]/console', false,
      'fe80::1%25eth%E2%80%AE'),
  _Case('zone-tab', 'https://[fe80::1%25eth\t]/console', false,
      'fe80::1%25eth%09'),
  _Case('zone-nbsp', 'https://[fe80::1%25eth\u00A0]/console', false,
      'fe80::1%25eth%C2%A0'),
  // Malformed bracket (Uri.tryParse returns null) and a bare %ZZ (not HEXDIG
  // HEXDIG) both fail closed rather than being normalised into a host.
  _Case('malformed-bracket', 'https://[fe80::1/console', false, null),
  _Case('malformed-percent', 'https://[fe80::1%ZZ]/console', false,
      'fe80::1%25ZZ'),
  // IPv4-mapped literals (dotted-quad and hex-group spelling) resolve to an
  // embedded IPv4 address in a browser while Uri.tryParse reports an opaque
  // host — one raw URI naming two authorities; both fail closed.
  _Case('mapped-v4', 'https://[::ffff:192.0.2.1]/console', false,
      '::ffff:192.0.2.1'),
  _Case('mapped-hex', 'https://[::ffff:c000:201]/console', false,
      '::ffff:c000:201'),
];

KvmConsole _console(String? uri) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

KvmConsoleLaunchPlan _plan(KvmWebViewPolicy policy, String uri) =>
    planConsoleLaunch(
      policy: policy,
      uri: uri,
      hasSecureUri: isSecureHttpsConsoleUri(uri),
      isHtml5: true,
      isEnabled: true,
    );

void main() {
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  group('EP-P27 IPv6 zone-id / malformed-authority cross-layer agreement', () {
    test('matrix is non-trivial, spans both classes and names every family',
        () {
      expect(kZoneIdMatrix.length, 13);
      expect(kZoneIdMatrix.where((_Case c) => c.secure).length, 3);
      expect(kZoneIdMatrix.where((_Case c) => !c.secure).length, 10);
      expect(kZoneIdMatrix.map((_Case c) => c.family).toSet().length,
          kZoneIdMatrix.length);
      expect(
          kZoneIdMatrix.every((_Case c) => c.uri.startsWith('https')), isTrue);
      expect(
        kZoneIdMatrix.map((_Case c) => c.family).toSet(),
        containsAll(<String>[
          'zone-pct25',
          'zone-raw-pct',
          'zone-nul',
          'zone-bidi',
          'zone-tab',
          'zone-nbsp',
          'malformed-bracket',
          'malformed-percent',
          'mapped-v4',
          'mapped-hex',
        ]),
      );
      for (final String family in <String>[
        'clean-control',
        'clean-ipv6',
        'clean-ipv4'
      ]) {
        expect(
          kZoneIdMatrix.singleWhere((_Case c) => c.family == family).secure,
          isTrue,
          reason: 'clean control must stay secure: $family',
        );
      }
    });

    test('per-value host normalization is pinned and every layer agrees', () {
      for (final _Case c in kZoneIdMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // Record the Uri.tryParse host normalization (the parser-differential
        // axis): a bare %/zone id keeps/rewrites its %25, a control byte gets
        // pct-encoded, a bracket-less literal yields no host at all.
        expect(Uri.tryParse(c.uri)?.host, c.parsedHost,
            reason: 'parsed-host characterization drift — $why');

        final bool platformSecure = isSecureHttpsConsoleUri(c.uri);
        expect(platformSecure, c.secure, reason: 'classifier drift — $why');
        expect(isHttpConsoleUri(c.uri), c.secure,
            reason: 'http-family classifier disagreement — $why');

        final KvmConsole console = _console(c.uri);
        expect(console.hasSecureLaunchUri, c.secure,
            reason: 'model classification drift — $why');
        expect(console.hasSecureLaunchUri, platformSecure,
            reason: 'cross-layer classifier disagreement — $why');
        expect(console.canOpenConsole, c.secure,
            reason: 'model openability disagrees with classification — $why');
        expect(
          console.launchStrategy,
          c.secure ? KvmLaunchStrategy.inAppHtml5 : KvmLaunchStrategy.noUri,
          reason: 'model launch strategy disagrees with classification — $why',
        );

        // The policy-independent origin-confinement gate agrees per value.
        expect(
          allowsInAppNavigation(consoleUri: c.uri, targetUri: c.uri),
          c.secure,
          reason: 'navigation gate disagrees with classifier — $why',
        );
      }
    });

    test(
        'production plan never routes in-app or accepts self-signed, even '
        'under a stale secure flag; model plan agrees field-for-field', () {
      for (final _Case c in kZoneIdMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // A stale/lying secure flag must still fail closed on a zone-id /
        // malformed / mapped shape, and must never enable self-signed under
        // production.
        final KvmConsoleLaunchPlan stale = planConsoleLaunch(
          policy: production,
          uri: c.uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );
        expect(stale.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'in-app route under production — $why');
        expect(stale.acceptSelfSigned, isFalse,
            reason: 'self-signed under production — $why');
        if (stale.targetUri != null) {
          expect(isControlSafeConsoleUri(stale.targetUri), isTrue,
              reason: 'non-control-safe copy target — $why');
        }

        final KvmConsoleLaunchPlan platform = _plan(production, c.uri);
        final KvmConsoleLaunchPlan model = _console(c.uri).launchPlan;
        expect(model.route, platform.route,
            reason: 'cross-layer route disagreement — $why');
        expect(model.targetUri, platform.targetUri,
            reason: 'cross-layer target disagreement — $why');
        expect(model.acceptSelfSigned, platform.acceptSelfSigned,
            reason: 'cross-layer self-signed disagreement — $why');
        expect(model.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'model in-app route under production — $why');
        expect(model.acceptSelfSigned, isFalse,
            reason: 'model self-signed under production — $why');

        // Secure values go to the external browser under production; zone-id /
        // malformed / mapped values degrade to copy-only (never an in-app or
        // external-browser launch target).
        expect(
            platform.route,
            c.secure
                ? KvmConsoleRenderRoute.externalBrowser
                : KvmConsoleRenderRoute.copyOnly,
            reason: 'production route classification drift — $why');
      }
    });

    test('test-only opt-in eligibility is uniform per value', () {
      for (final _Case c in kZoneIdMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        final KvmConsoleLaunchPlan plan = _plan(optIn, c.uri);
        if (c.secure) {
          expect(plan.route, KvmConsoleRenderRoute.inAppWebView,
              reason: 'genuine HTTPS shape not opt-in eligible — $why');
          expect(plan.acceptSelfSigned, isTrue,
              reason: 'opt-in self-signed not granted to HTTPS shape — $why');
        } else {
          expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
              reason:
                  'zone-id/malformed shape reached in-app under opt-in — $why');
          expect(plan.acceptSelfSigned, isFalse,
              reason: 'zone-id/malformed shape accepted self-signed — $why');
        }
      }
    });

    test(
        'navigation gate fails closed on cross-origin and on zone-id/mapped '
        'targets from a secure console', () {
      for (final _Case c in kZoneIdMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        expect(
          allowsInAppNavigation(
            consoleUri: c.uri,
            targetUri: 'https://other.example/console',
          ),
          isFalse,
          reason: 'cross-origin target navigable in-app — $why',
        );
      }
      const String secureConsole = 'https://[2001:db8::1]/console';
      for (final String hostileTarget in <String>[
        'https://[fe80::1%25eth0]/console',
        'https://[fe80::1%eth0]/console',
        'https://[::ffff:192.0.2.1]/console',
        'https://[fe80::1/console',
        'https://other.example/console',
      ]) {
        expect(
          allowsInAppNavigation(
            consoleUri: secureConsole,
            targetUri: hostileTarget,
          ),
          isFalse,
          reason:
              'spoofed/cross-origin navigation target allowed — $hostileTarget',
        );
      }
      // The clean IPv6 control remains self-navigable (sanity / non-vacuity).
      expect(
        allowsInAppNavigation(
          consoleUri: secureConsole,
          targetUri: 'https://[2001:db8::1]/other',
        ),
        isTrue,
      );
    });

    test(
        'equivalent malformed zone spellings agree on every layer, and clean '
        'controls stay byte-exact', () {
      // A pct-encoded (%25) and a bare (%) zone separator both fail closed
      // uniformly — no spelling of the zone id may become in-app-eligible.
      const List<String> zones = <String>[
        'https://[fe80::1%25eth0]/console',
        'https://[fe80::1%eth0]/console',
        'https://[fe80::1%25eth\u202E]/console',
        'https://[fe80::1%25eth\u0000]/console',
      ];
      for (final String uri in zones) {
        expect(isSecureHttpsConsoleUri(uri), isFalse, reason: uri);
        expect(_console(uri).hasSecureLaunchUri, isFalse, reason: uri);
        expect(
            _plan(optIn, uri).route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: uri);
        expect(_plan(production, uri).route, KvmConsoleRenderRoute.copyOnly,
            reason: uri);
      }
      // The three clean controls keep a byte-exact control-safe copy target and
      // are secure on every layer — the fail-closed gate loses no valid endpoint.
      for (final String family in <String>[
        'clean-control',
        'clean-ipv6',
        'clean-ipv4'
      ]) {
        final _Case c =
            kZoneIdMatrix.singleWhere((_Case x) => x.family == family);
        expect(isControlSafeConsoleUri(c.uri), isTrue, reason: family);
        expect(_plan(production, c.uri).targetUri, c.uri, reason: family);
        expect(_console(c.uri).launchUri, c.uri, reason: family);
      }
    });
  });
}
