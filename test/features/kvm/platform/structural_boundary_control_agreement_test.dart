/// EP-P25 (issue #009/#021) — control code points wedged at URI STRUCTURAL
/// BOUNDARIES fail closed uniformly across every decision layer.
///
/// Authority spellings, scheme spellings, userinfo, ports, separators, IPv6
/// literals, alternate IPv4 notation and path/query/fragment controls are
/// heavily pinned by sibling guards (EP-P9/P11/P13/P19/P21/P22/P24/P26). What
/// none of them sweeps is a raw C0/C1 control / DEL wedged at a URI *structural
/// boundary*: between scheme and `://`, inside or around the userinfo `@`, at
/// the port `:` separator, inside or after an IPv6 `[...]` literal, or trailing
/// the authority before `/`. Dart's `Uri.tryParse` reacts differently per
/// boundary — some forms fail to parse (`origin == null`), some silently
/// percent-encode the control into the host (a DIFFERENT, spoofed-looking
/// authority), and one (a NUL inside userinfo) still reports the SAME origin as
/// a clean console. A layer that leaned on the parser, or on an origin-only
/// navigation check, could therefore accept a control-bearing boundary form
/// that the shared whole-URI fail-closed core refuses.
///
/// This guard pins that ALL FOUR decision layers agree over one shared matrix:
///   * [isSecureHttpsConsoleUri] / [isControlSafeConsoleUri] — the shared core,
///   * [planConsoleLaunch] — the render-route / target / self-signed decision
///     (including the stale-flag TLS boundary under the test-only opt-in),
///   * [allowsInAppNavigation] — the RP-1 origin-confinement gate, and
///   * `KvmConsole.hasSecureLaunchUri` / `launchPlan` — the model layer the
///     console card and viewer gate on.
///
/// AUDIT FIRST: the shared `_controlSafeTrimmedUri` core rejects a raw control
/// anywhere in the URI, so all layers agree BY CONSTRUCTION today — there is
/// no live divergence and no production change. Genuinely unguarded seam: no
/// test drove this boundary family through every layer at once, and the gate
/// is a single load-bearing check (`_rawUriForbiddenChars`). Deleting that one
/// check flips the whole family to control-SAFE (and flips the same-origin
/// userinfo case to SECURE / in-app-eligible) while every single-layer sibling
/// suite that only exercises query/fragment or authority-*spelling* controls
/// stays GREEN. This is a read-only characterization guard of that seam.
///
/// No WebView/protocol import, no URL opened, no dependency, no production TLS
/// weakening (issues #009 / #021). Complements EP-P19 (query/fragment controls)
/// with the structural-boundary family.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// Same origin (host + default port) as the same-origin hostile case and the
/// clean controls, so an origin-only navigation gate cannot be the defence.
const String _console = 'https://bmc.example/console';

KvmConsole _model(String? uri) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: const <String>['HTML5'],
      serviceEnabled: true,
      connectUri: uri,
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

KvmConsoleLaunchPlan _platformPlan(String uri, KvmWebViewPolicy policy) =>
    planConsoleLaunch(
      policy: policy,
      uri: uri,
      hasSecureUri: isSecureHttpsConsoleUri(uri),
      isHtml5: true,
      isEnabled: true,
    );

class _Case {
  const _Case(this.family, this.uri, this.sameOrigin);

  final String family;
  final String uri;
  final bool
      sameOrigin; // Uri.tryParse(uri).origin == Uri.parse(_console).origin
}

// Verified CHARACTERIZATIONS of the current shared core. Every value below is
// fail-closed on all four layers with the controls intact (the GREEN baseline);
// removing the single `_rawUriForbiddenChars` gate in `_controlSafeTrimmedUri`
// makes every value control-safe and flips the same-origin userinfo case to
// secure (the RED proof).
const List<_Case> kHostileCases = <_Case>[
  _Case('scheme-NUL', 'https\x00://bmc.example/x', false),
  _Case('scheme-CRLF', 'https\r\n://bmc.example/x', false),
  _Case('scheme-US', 'https\x1F://bmc.example/x', false),
  _Case('userinfo-NUL', 'https://u\x00ser@bmc.example/x', true),
  _Case('after-at-NUL', 'https://user@\x00bmc.example/x', false),
  _Case('before-port-NUL', 'https://bmc.example\x00:443/x', false),
  _Case('after-port-NUL', 'https://bmc.example:\x00443/x', false),
  _Case('ipv6-open-NUL', 'https://[\x00::1]/x', false),
  _Case('ipv6-close-NUL', 'https://[::1]\x00/x', false),
  _Case('authority-tail-NUL', 'https://bmc.example\x00/x', false),
  _Case('authority-head-NUL', 'https://\x00bmc.example/x', false),
  _Case('authority-tail-DEL', 'https://bmc.example\x7F/x', false),
];

// Clean boundary forms: canonical port, IPv6 literal, no stray control. They
// must stay secure and external-browser launchable — the fail-closed gate must
// not over-reject a legitimate authority spelling.
const List<String> kCleanCases = <String>[
  'https://bmc.example/x',
  'https://bmc.example:443/x',
  'https://[::1]/x',
];

void main() {
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  group('EP-P25 structural-boundary control fail-closed cross-layer agreement',
      () {
    test('matrix spans scheme / userinfo / port / IPv6 / authority boundaries',
        () {
      expect(kHostileCases.length, 12);
      expect(kCleanCases.length, 3);
      expect(
        kHostileCases.map((_Case c) => c.family).toSet().length,
        kHostileCases.length,
      );
      expect(
          kHostileCases.every((_Case c) => c.uri.startsWith('https')), isTrue);
      expect(kHostileCases.where((_Case c) => c.sameOrigin), hasLength(1));
      expect(
        kHostileCases.any((_Case c) => c.uri.codeUnits.contains(0x0A)),
        isTrue,
      );
      expect(
        kHostileCases.any((_Case c) => c.uri.codeUnits.contains(0x7F)),
        isTrue,
      );
    });

    test('every hostile boundary control fails closed on ALL layers', () {
      for (final _Case c in kHostileCases) {
        final String reason = 'family=${c.family} codeUnits=${c.uri.codeUnits}';

        // For the same-origin case, pin the parser differential explicitly:
        // Uri.tryParse keeps the console's origin, so only the shared
        // fail-closed classifier can refuse it.
        if (c.sameOrigin) {
          expect(Uri.tryParse(c.uri)?.origin, Uri.parse(_console).origin,
              reason: 'not same-origin per Uri.tryParse — $reason');
        }

        // (1) shared classifier + control-safety core.
        expect(isSecureHttpsConsoleUri(c.uri), isFalse, reason: reason);
        expect(isControlSafeConsoleUri(c.uri), isFalse, reason: reason);

        // (2) production plan: copy-only, no usable target, never in-app, never
        // self-signed.
        final KvmConsoleLaunchPlan prod = _platformPlan(c.uri, production);
        expect(prod.route, KvmConsoleRenderRoute.copyOnly, reason: reason);
        expect(prod.targetUri, isNull, reason: reason);
        expect(prod.acceptSelfSigned, isFalse, reason: reason);

        // (3) stale-flag TLS boundary: even under the test-only opt-in with a
        // lying `hasSecureUri: true`, a boundary control must never route in-app
        // or accept a self-signed certificate.
        final KvmConsoleLaunchPlan stale = planConsoleLaunch(
          policy: optIn,
          uri: c.uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );
        expect(stale.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: reason);
        expect(stale.acceptSelfSigned, isFalse, reason: reason);

        // (4) navigation gate: never navigable in either direction.
        expect(
          allowsInAppNavigation(consoleUri: _console, targetUri: c.uri),
          isFalse,
          reason: 'hostile target was navigable — $reason',
        );
        expect(
          allowsInAppNavigation(consoleUri: c.uri, targetUri: _console),
          isFalse,
          reason: 'hostile console origin was trusted — $reason',
        );

        // (5) model layer agrees with the platform decision field-for-field.
        final KvmConsole model = _model(c.uri);
        expect(model.hasSecureLaunchUri, isFalse, reason: reason);
        expect(model.launchPlan.route, prod.route, reason: reason);
        expect(model.launchPlan.targetUri, prod.targetUri, reason: reason);
        expect(model.launchPlan.acceptSelfSigned, prod.acceptSelfSigned,
            reason: reason);
      }
    });

    test('clean boundary controls stay secure and launchable on ALL layers',
        () {
      for (final String uri in kCleanCases) {
        final String reason = 'uri=$uri';

        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: reason);
        expect(isControlSafeConsoleUri(uri), isTrue, reason: reason);

        final KvmConsoleLaunchPlan prod = _platformPlan(uri, production);
        expect(prod.route, KvmConsoleRenderRoute.externalBrowser,
            reason: reason);
        expect(prod.targetUri, uri, reason: reason);
        expect(prod.acceptSelfSigned, isFalse, reason: reason);

        expect(allowsInAppNavigation(consoleUri: uri, targetUri: uri), isTrue,
            reason: reason);

        final KvmConsole model = _model(uri);
        expect(model.hasSecureLaunchUri, isTrue, reason: reason);
        expect(model.launchPlan.route, prod.route, reason: reason);
        expect(model.launchPlan.targetUri, prod.targetUri, reason: reason);
        expect(model.launchPlan.acceptSelfSigned, prod.acceptSelfSigned,
            reason: reason);
      }
    });
  });
}
