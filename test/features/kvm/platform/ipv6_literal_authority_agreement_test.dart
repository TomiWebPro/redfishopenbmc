/// EP-P21 (issue #009/#021) — IPv6-literal / zone-id authority cross-layer
/// fail-closed agreement.
///
/// A BMC-supplied HTTPS `ConnectUri` may carry an IPv6-literal authority. Dart's
/// `Uri.tryParse` normalises these to an opaque host string that a browser /
/// WebView (WHATWG URL) parser does not always resolve the same way: an IPv4-
/// mapped literal (`[::ffff:127.0.0.1]`, `[::ffff:7f00:1]`) is resolved to an
/// embedded IPv4 address, a pct-encoded zone id (`[fe80::1%25eth0]`) stays
/// encoded, while pure-hex special-use literals (loopback `::1`, unique-local
/// `fd00::1`, unspecified `::`) are reported verbatim and are deliberately kept
/// launchable as real test-profile / legitimate IPv6 targets.
///
/// Two independent decision families consume the same raw URI:
///   * the **platform layer** — [isSecureHttpsConsoleUri], [isHttpConsoleUri],
///     [planConsoleLaunch] (render route + control-safe copy target + self-
///     signed flag) and [allowsInAppNavigation] (RP-1 origin confinement), and
///   * the **model layer** — `KvmConsole.hasSecureLaunchUri` / `canOpenConsole` /
///     `launchStrategy` / `launchPlan`, which the console card and viewer gate on.
///
/// They are meant to share one fail-closed core, but they are separate call
/// sites. A future edit that reimplements a bare `Uri.tryParse` scheme/host check
/// in one of them (the exact divergence class documented in `launch_plan.dart`)
/// could classify an IPv6 shape differently on one surface while every existing
/// single-surface suite stays GREEN. This guard drives the whole special-use
/// IPv6-literal family through ALL layers at once and pins, per shape, both the
/// expected classification (the AUDIT-FIRST characterization below) and
/// cross-layer agreement, recording the `Uri.tryParse` host for each case.
///
/// AUDIT FIRST: the shared whole-URI fail-closed core already classifies the
/// whole matrix identically on every layer (no live divergence), so this is a
/// read-only characterization guard of a previously unguarded cross-layer seam —
/// the loopback / mapped-loopback / unique-local / unspecified / zone-id family
/// is not swept through all four layers plus the model in any existing test.
/// No production behaviour is changed; no WebView/protocol import, no URL
/// opened, no dependency, no production TLS weakening (issues #009 / #021).
/// Complements EP-P18 (canonical-tricky spellings) and EP-P9 (generic hostile
/// authorities) with the special-use IPv6-literal family.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// One special-use IPv6 authority and its AUDITED secure classification under
/// the shared fail-closed core.
class _Case {
  const _Case(this.family, this.uri, this.secure, this.parsedHost);

  final String family;
  final String uri;
  final bool secure;
  final String parsedHost; // Uri.tryParse(uri).host characterization.
}

// Classifications are CHARACTERIZATIONS of the current shared core, verified
// with isSecureHttpsConsoleUri across all four layers. IPv4-mapped and
// pct-encoded-zone-id literals fail closed; pure-hex loopback / unique-local /
// unspecified literals stay secure by design (real test-profile / legitimate
// IPv6 targets). URIs are otherwise clean (no control chars), so the matrix
// isolates the IPv6-AUTHORITY axis from the control/delimiter axis.
const List<_Case> kIpv6Matrix = <_Case>[
  _Case('clean-control', 'https://bmc.example/console', true, 'bmc.example'),
  _Case('ipv6-loopback', 'https://[::1]/console', true, '::1'),
  _Case('ipv6-loopback-port', 'https://[::1]:443/console', true, '::1'),
  _Case('ipv6-mapped-loopback-quad', 'https://[::ffff:127.0.0.1]/console',
      false, '::ffff:127.0.0.1'),
  _Case('ipv6-mapped-loopback-hex', 'https://[::ffff:7f00:1]/console', false,
      '::ffff:7f00:1'),
  _Case('ipv6-linklocal-zone-id', 'https://[fe80::1%25eth0]/console', false,
      'fe80::1%25eth0'),
  _Case('ipv6-unique-local', 'https://[fd00::1]/console', true, 'fd00::1'),
  _Case('ipv6-unspecified', 'https://[::]/console', true, '::'),
  _Case('ipv6-global-uppercase-hex', 'https://[2001:DB8::1]/console', true,
      '2001:db8::1'),
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

  group('EP-P21 IPv6-literal authority cross-layer agreement', () {
    test('matrix is non-trivial, spans both classes and names every family',
        () {
      expect(kIpv6Matrix.length, 9);
      expect(kIpv6Matrix.where((_Case c) => c.secure).length, 6);
      expect(kIpv6Matrix.where((_Case c) => !c.secure).length, 3);
      expect(kIpv6Matrix.map((_Case c) => c.family).toSet().length,
          kIpv6Matrix.length);
      expect(
          kIpv6Matrix
              .singleWhere((_Case c) => c.family == 'clean-control')
              .secure,
          isTrue);
      expect(kIpv6Matrix.every((_Case c) => c.uri.startsWith('https')), isTrue);
      expect(
        kIpv6Matrix.map((_Case c) => c.family).toSet(),
        containsAll(<String>[
          'ipv6-loopback',
          'ipv6-mapped-loopback-quad',
          'ipv6-mapped-loopback-hex',
          'ipv6-linklocal-zone-id',
          'ipv6-unique-local',
          'ipv6-unspecified',
        ]),
      );
      // Every parsedHost is a non-empty, recorded characterization.
      expect(kIpv6Matrix.every((_Case c) => c.parsedHost.isNotEmpty), isTrue);
    });

    test('per-shape host normalization is pinned and every layer agrees', () {
      for (final _Case c in kIpv6Matrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // Record the Uri.tryParse host normalization (the parser-differential
        // axis): a mapped literal is reported opaque, a zone id keeps its %25,
        // pure-hex literals are lower-cased/verbatim.
        expect(Uri.tryParse(c.uri)!.host, c.parsedHost,
            reason: 'parsed-host characterization drift — $why');

        final bool platformSecure = isSecureHttpsConsoleUri(c.uri);
        expect(platformSecure, c.secure, reason: 'classifier drift — $why');
        // The browser-launchable HTTP(S) family classifier agrees with the
        // secure classifier on this all-HTTPS matrix.
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

        // The policy-independent origin-confinement gate agrees per shape.
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
      for (final _Case c in kIpv6Matrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // A stale/lying secure flag must still fail closed on a mapped/zone-id
        // shape, and must never enable self-signed acceptance under production.
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

        // Secure shapes go to the external browser under production; mapped /
        // zone-id shapes degrade to copy-only (never an in-app launch target).
        expect(
            platform.route,
            c.secure
                ? KvmConsoleRenderRoute.externalBrowser
                : KvmConsoleRenderRoute.copyOnly,
            reason: 'production route classification drift — $why');
      }
    });

    test('test-only opt-in eligibility is uniform per shape', () {
      for (final _Case c in kIpv6Matrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        final KvmConsoleLaunchPlan plan = _plan(optIn, c.uri);
        if (c.secure) {
          expect(plan.route, KvmConsoleRenderRoute.inAppWebView,
              reason: 'genuine IPv6 shape not opt-in eligible — $why');
          expect(plan.acceptSelfSigned, isTrue,
              reason: 'opt-in self-signed not granted to IPv6 shape — $why');
        } else {
          expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
              reason:
                  'mapped/zone-id shape reached in-app under opt-in — $why');
          expect(plan.acceptSelfSigned, isFalse,
              reason: 'mapped/zone-id shape accepted self-signed — $why');
        }
      }
    });

    test(
        'navigation gate fails closed on cross-origin and on mapped/zone-id '
        'targets from a secure IPv6 console', () {
      for (final _Case c in kIpv6Matrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        // A different origin is never navigable in-app, independent of spelling.
        expect(
          allowsInAppNavigation(
            consoleUri: c.uri,
            targetUri: 'https://other.example/console',
          ),
          isFalse,
          reason: 'cross-origin target navigable in-app — $why',
        );
      }
      const String secureConsole = 'https://[::1]/console';
      for (final String hostileTarget in <String>[
        'https://[::ffff:127.0.0.1]/console',
        'https://[::ffff:7f00:1]/console',
        'https://[fe80::1%25eth0]/console',
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
      // The clean control remains self-navigable (sanity / non-vacuity).
      expect(
        allowsInAppNavigation(
          consoleUri: secureConsole,
          targetUri: 'https://[::1]/other',
        ),
        isTrue,
      );
    });

    test('equivalent IPv6 spellings agree with each other on every layer', () {
      // Pure-hex loopback with/without an explicit port stays secure.
      const List<String> loopback = <String>[
        'https://[::1]/console',
        'https://[::1]:443/console',
      ];
      for (final String uri in loopback) {
        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: uri);
        expect(_console(uri).hasSecureLaunchUri, isTrue, reason: uri);
        expect(_plan(optIn, uri).route, KvmConsoleRenderRoute.inAppWebView,
            reason: uri);
        expect(
            _plan(production, uri).route, KvmConsoleRenderRoute.externalBrowser,
            reason: uri);
      }
      // IPv4-mapped loopback in dotted-quad and hex-group spelling both fail
      // closed uniformly (the parser differential that one raw URI can name two
      // authorities must never become in-app-eligible).
      const List<String> mapped = <String>[
        'https://[::ffff:127.0.0.1]/console',
        'https://[::ffff:7f00:1]/console',
      ];
      for (final String uri in mapped) {
        expect(isSecureHttpsConsoleUri(uri), isFalse, reason: uri);
        expect(_console(uri).hasSecureLaunchUri, isFalse, reason: uri);
        expect(
            _plan(optIn, uri).route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: uri);
        expect(_plan(production, uri).route, KvmConsoleRenderRoute.copyOnly,
            reason: uri);
      }
    });
  });
}
