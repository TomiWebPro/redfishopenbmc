/// EP-P9 (issue #009/#021) — cross-layer authority fail-closed agreement.
///
/// Two layers decide whether a BMC-supplied console URI is a trustworthy TLS
/// target:
///   * the **platform decision layer** — [isSecureHttpsConsoleUri] +
///     [planConsoleLaunch] (the dependency-free, fail-closed authority
///     classifier), and
///   * the **model layer** — `KvmConsole.hasSecureLaunchUri` /
///     `KvmConsole.launchPlan` / `KvmConsole.canOpenConsole`, which the console
///     card and viewer gate on.
///
/// They are meant to share one hardening core, but they are separate call
/// sites: a future edit that reimplements a bare `Uri.tryParse` check in one of
/// them could silently agree with the other while both accepting a spoofed
/// authority. This guard pins the agreement over a hostile-authority matrix
/// (numeric / encoded-delimiter / empty-DNS-label / control-char / confusable
/// hosts) under a *stale/lying* `hasSecureUri` signal, and pins that neither
/// layer can route in-app or accept a self-signed certificate under the
/// production policy. Legitimate canonical HTTPS targets stay launchable on
/// both layers.
///
/// Pure Dart + flutter_test: no WebView import, no live BMC, no dependency, no
/// production TLS behaviour change (issue #009/#021). Complements EP-P6 (which
/// pins the platform route alone) by adding the model-layer agreement axis.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// Builds the model-layer console a BMC `ConnectUri` would produce, enabled and
/// HTML5 so a secure target exercises the strongest (in-app-eligible) signals.
KvmConsole _console(String? uri) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

void main() {
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;

  // Every entry is an HTTPS URI whose authority a browser/WebView (WHATWG URL)
  // resolves differently from `Uri.tryParse`, or which carries a control /
  // delimiter code point. All must fail closed on BOTH layers. Each shape is
  // already individually refused by the platform classifier (launch_plan_test
  // groups), but nothing previously pinned that the model layer agrees.
  const List<String> hostileSecureUris = <String>[
    'https://bmc.exa mple/console', // raw space in host
    'https://bmc.example/a\r\nX-Injected: 1', // CRLF header injection
    'https://bmc.example/a\x00b', // raw NUL
    'https://bmc.example%00.evil.com/console', // pct-encoded NUL truncation
    'https://bmc.example%2Eevil.com/console', // pct-encoded dot -> host change
    'https://bmc.example%252Fevil.com/console', // double-encoded delimiter
    'https://./console', // degenerate dot-only authority
    'https://bmc..example/console', // empty DNS label
    'https://2130706433/console', // non-canonical numeric host
    'https://0x7f000001/console', // hex integer host
    'https://bmc.example/a%zz', // malformed percent escape
    'https://\uFF42\uFF4D\uFF43.example/console', // fullwidth "bmc" authority
  ];

  // Canonical HTTPS targets: no authority differential, no control chars. Both
  // layers must keep them secure and (flag off) hand them to the external
  // browser — the fail-closed gate must not over-reject valid endpoints.
  const List<String> legitimateSecureUris = <String>[
    'https://bmc.example/console',
    '  https://bmc.example/console  ', // padded -> trimmed by both layers
    'https://bmc.example./console', // absolute FQDN (one trailing dot)
    'https://[::1]:8443/console', // pure-hex IPv6 loopback
    'https://bmc.example/console%20one', // %20 in path (encoded space)
  ];

  group('EP-P9 cross-layer authority fail-closed agreement', () {
    test('matrix is non-trivial and covers both secure and hostile authorities',
        () {
      expect(hostileSecureUris.length, 12);
      expect(legitimateSecureUris.length, 5);
      expect(
          hostileSecureUris.every((String u) => u.startsWith('https')), isTrue);
    });

    test('hostile authority fails closed on BOTH layers and the two agree', () {
      for (final String uri in hostileSecureUris) {
        final String reason = 'uri=${uri.codeUnits}';

        // Platform layer: the classifier refuses the authority, and a stale /
        // lying `hasSecureUri: true` signal still cannot reach an in-app route
        // or self-signed acceptance.
        expect(
          isSecureHttpsConsoleUri(uri),
          isFalse,
          reason: 'platform classifier accepted hostile authority — $reason',
        );
        final KvmConsoleLaunchPlan platformPlan = planConsoleLaunch(
          policy: production,
          uri: uri,
          hasSecureUri: true, // stale/lying signal
          isHtml5: true,
          isEnabled: true,
        );
        expect(platformPlan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'platform in-app route on hostile authority — $reason');
        expect(platformPlan.acceptSelfSigned, isFalse,
            reason: 'platform self-signed on hostile authority — $reason');

        // Model layer: same refusal, and the model's plan agrees field-for-field
        // with the platform plan built from the same raw URI.
        final KvmConsole console = _console(uri);
        expect(console.hasSecureLaunchUri, isFalse,
            reason: 'model classifier accepted hostile authority — $reason');
        expect(console.hasSecureLaunchUri, isSecureHttpsConsoleUri(uri),
            reason: 'cross-layer classifier disagreement — $reason');

        final KvmConsoleLaunchPlan modelPlan = console.launchPlan;
        expect(modelPlan.route, platformPlan.route,
            reason: 'cross-layer route disagreement — $reason');
        expect(modelPlan.targetUri, platformPlan.targetUri,
            reason: 'cross-layer target disagreement — $reason');
        expect(modelPlan.acceptSelfSigned, platformPlan.acceptSelfSigned,
            reason: 'cross-layer self-signed disagreement — $reason');
        expect(modelPlan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'model in-app route on hostile authority — $reason');
        expect(modelPlan.acceptSelfSigned, isFalse,
            reason: 'model self-signed on hostile authority — $reason');

        // Any target either layer would hand out must still be control-safe.
        final String? target = platformPlan.targetUri;
        if (target != null) {
          expect(isControlSafeConsoleUri(target), isTrue,
              reason: 'non-control-safe target — $reason');
        }
      }
    });

    test('legitimate HTTPS stays secure and launchable on BOTH layers', () {
      for (final String uri in legitimateSecureUris) {
        final String reason = 'uri=$uri';
        expect(isSecureHttpsConsoleUri(uri), isTrue,
            reason: 'platform refused a canonical HTTPS target — $reason');

        final KvmConsole console = _console(uri);
        expect(console.hasSecureLaunchUri, isTrue,
            reason: 'model refused a canonical HTTPS target — $reason');
        expect(console.hasSecureLaunchUri, isSecureHttpsConsoleUri(uri),
            reason: 'cross-layer classifier disagreement — $reason');
        expect(console.canOpenConsole, isTrue,
            reason: 'canonical secure console not openable — $reason');

        final KvmConsoleLaunchPlan platformPlan = planConsoleLaunch(
          policy: production,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );
        expect(platformPlan.route, KvmConsoleRenderRoute.externalBrowser,
            reason: 'canonical HTTPS not routed externally — $reason');
        expect(platformPlan.acceptSelfSigned, isFalse,
            reason: 'self-signed under production — $reason');
        expect(isControlSafeConsoleUri(platformPlan.targetUri), isTrue,
            reason: 'target not control-safe — $reason');

        final KvmConsoleLaunchPlan modelPlan = console.launchPlan;
        expect(modelPlan.route, platformPlan.route,
            reason: 'cross-layer route disagreement — $reason');
        expect(modelPlan.targetUri, platformPlan.targetUri,
            reason: 'cross-layer target disagreement — $reason');
        expect(modelPlan.acceptSelfSigned, platformPlan.acceptSelfSigned,
            reason: 'cross-layer self-signed disagreement — $reason');
      }
    });

    test('agreement holds over the full URI family (external/plaintext/blank)',
        () {
      const List<String?> allUris = <String?>[
        ...hostileSecureUris,
        ...legitimateSecureUris,
        'http://bmc.example/console', // plaintext HTTP
        'vnc://bmc.example:5900', // external client
        'ssh://bmc.example', // serial external client
        '',
        '   ',
        null,
      ];

      for (final String? uri in allUris) {
        final KvmConsole console = _console(uri);
        final bool platformSecure = isSecureHttpsConsoleUri(uri);
        expect(console.hasSecureLaunchUri, platformSecure,
            reason: 'classifier disagreement for ${uri?.codeUnits}');

        final KvmConsoleLaunchPlan modelPlan = console.launchPlan;
        final KvmConsoleLaunchPlan directPlan = planConsoleLaunch(
          policy: production,
          uri: uri,
          hasSecureUri: platformSecure,
          isHtml5: console.supportsHtml5,
          isEnabled: console.serviceEnabled,
        );
        expect(modelPlan.route, directPlan.route,
            reason: 'plan route disagreement for ${uri?.codeUnits}');
        expect(modelPlan.targetUri, directPlan.targetUri,
            reason: 'plan target disagreement for ${uri?.codeUnits}');
        expect(modelPlan.acceptSelfSigned, directPlan.acceptSelfSigned,
            reason: 'plan self-signed disagreement for ${uri?.codeUnits}');

        // Production invariants hold for every form, on the model side too.
        expect(modelPlan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'in-app route under production for ${uri?.codeUnits}');
        expect(modelPlan.acceptSelfSigned, isFalse,
            reason: 'self-signed under production for ${uri?.codeUnits}');
      }
    });
  });
}
