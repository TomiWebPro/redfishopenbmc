/// EP-P19 (issue #009/#021) — query/fragment control fail-closed agreement
/// across every decision layer.
///
/// A BMC-supplied console URI can carry raw C0/C1 controls, CRLF, a raw space,
/// or a *percent-encoded* control octet (`%0A` / `%0D` / `%00` / `%1F` / `%7F`)
/// in its QUERY (`?x=…`) or FRAGMENT (`#…`). `Uri.tryParse` keeps a valid `%XX`
/// escape and still reports a secure HTTPS host, so a layer that checks only the
/// authority (where most of the encoded-delimiter rules are intentionally
/// scoped) would silently accept a query/fragment injection vector that the
/// shared whole-URI fail-closed core refuses.
///
/// This guard pins that ALL FOUR decision layers agree over one shared query/
/// fragment matrix:
///   * [isSecureHttpsConsoleUri] — the fail-closed HTTPS classifier,
///   * [planConsoleLaunch] — the render-route / target decision (including the
///     stale-flag TLS boundary under the test-only opt-in),
///   * [allowsInAppNavigation] — the RP-1 origin-confinement gate, and
///   * `KvmConsole.launchPlan` / `hasSecureLaunchUri` — the model layer the
///     console card and viewer gate on.
///
/// Every hostile query/fragment target must be uniformly fail-closed (never an
/// in-app route, never self-signed, no usable target, never navigable) while a
/// clean control — including a LEGAL encoded delimiter/space/percent in the
/// query (`%3A`/`%20`/`%25`), which cannot change the authority — stays secure
/// and external-browser launchable on every layer. Encoded controls are a
/// whole-URI rule (not authority-scoped like the encoded-*delimiter* rules), so
/// scoping that check to the authority — a plausible "consistency" refactor —
/// is the exact divergence class this guard makes RED.
///
/// Pure Dart + flutter_test: no WebView/protocol import, no live BMC, no
/// dependency, no production TLS behaviour change (issue #009/#021).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// The console every hostile target is compared against for the origin gate.
/// Same origin (host + default port) as every matrix URI, so an origin-only
/// check would accept the control-bearing targets — only the shared fail-closed
/// classifier can refuse them.
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

void main() {
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
  const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;

  // Raw C0/C1 controls, CRLF and raw space in the QUERY / FRAGMENT.
  const List<String> rawControlCases = <String>[
    'https://bmc.example/console?x=\x00', // raw NUL in query
    'https://bmc.example/console?x=\r\nX: 1', // CRLF header injection in query
    'https://bmc.example/console?x=\x1F', // raw unit separator in query
    'https://bmc.example/console?x=a b', // raw space in query
    'https://bmc.example/console#\x00', // raw NUL in fragment
    'https://bmc.example/console#a\r\nb', // CRLF in fragment
    'https://bmc.example/console#a b', // raw space in fragment
    'https://bmc.example/console?x=\x00#y=\r\n', // both query and fragment
  ];

  // Percent-encoded C0/DEL octets in the QUERY / FRAGMENT. These are valid
  // %XX escapes (so the malformed-percent rule does not catch them) and carry
  // no raw forbidden character — only the whole-URI encoded-control rule
  // refuses them. Scoping that rule to the authority lets them slip through.
  const List<String> encodedControlCases = <String>[
    'https://bmc.example/console?x=%00',
    'https://bmc.example/console?x=%0A',
    'https://bmc.example/console?x=%0D',
    'https://bmc.example/console?x=%1F',
    'https://bmc.example/console?x=%7F',
    'https://bmc.example/console#%00',
    'https://bmc.example/console#%0A',
    'https://bmc.example/console#x=%0D%0A',
  ];

  const List<String> hostileCases = <String>[
    ...rawControlCases,
    ...encodedControlCases,
  ];

  // Clean controls: no authority differential, no control code point. Legal
  // encoded delimiters in the query cannot change which host is contacted, so
  // they stay launchable — the fail-closed gate must not over-reject them.
  const List<String> cleanCases = <String>[
    'https://bmc.example/console?x=clean',
    'https://bmc.example/console#frag',
    'https://bmc.example/console?x=a%20b', // encoded space (legal in query)
    'https://bmc.example/console?x=100%25', // encoded percent (legal in query)
    'https://bmc.example/console?x=a%3Ab', // encoded delimiter (legal in query)
  ];

  group('EP-P19 query/fragment control fail-closed cross-layer agreement', () {
    test('matrix is non-trivial and spans raw + encoded + clean controls', () {
      expect(rawControlCases.length, 8);
      expect(encodedControlCases.length, 8);
      expect(cleanCases.length, 5);
      expect(hostileCases.every((String u) => u.startsWith('https')), isTrue);
      expect(
          encodedControlCases
              .every((String u) => u.contains('?') || u.contains('#')),
          isTrue);
    });

    test('every hostile query/fragment target fails closed on ALL layers', () {
      for (final String uri in hostileCases) {
        final String reason = 'uri=${uri.codeUnits}';

        // The Uri.tryParse parser differential is real: a valid %XX escape in
        // the query still parses to the SAME origin as the console. So an
        // origin-only navigation check cannot save us — only the shared
        // fail-closed classifier can.
        expect(Uri.tryParse(uri)?.origin, Uri.parse(_console).origin,
            reason: 'not same-origin per Uri.tryParse — $reason');

        // (1) classifier + control-safety core.
        expect(isSecureHttpsConsoleUri(uri), isFalse, reason: reason);
        expect(isControlSafeConsoleUri(uri), isFalse, reason: reason);

        // (2) production launch plan: copy-only, no usable target, never
        // in-app, never self-signed.
        final KvmConsoleLaunchPlan prod = _platformPlan(uri, production);
        expect(prod.route, KvmConsoleRenderRoute.copyOnly, reason: reason);
        expect(prod.targetUri, isNull, reason: reason);
        expect(prod.acceptSelfSigned, isFalse, reason: reason);

        // (3) stale-flag TLS boundary: even under the test-only opt-in with a
        // lying `hasSecureUri: true`, a hostile query must never route in-app
        // or accept a self-signed certificate.
        final KvmConsoleLaunchPlan stale = planConsoleLaunch(
          policy: optIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );
        expect(stale.route, isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: reason);
        expect(stale.acceptSelfSigned, isFalse, reason: reason);

        // (4) navigation gate: never navigable in either direction.
        expect(
          allowsInAppNavigation(consoleUri: _console, targetUri: uri),
          isFalse,
          reason: 'hostile target was navigable — $reason',
        );
        expect(
          allowsInAppNavigation(consoleUri: uri, targetUri: _console),
          isFalse,
          reason: 'hostile console origin was trusted — $reason',
        );

        // (5) model layer agrees with the platform decision field-for-field.
        final KvmConsole model = _model(uri);
        expect(model.hasSecureLaunchUri, isFalse, reason: reason);
        expect(model.launchPlan.route, prod.route, reason: reason);
        expect(model.launchPlan.targetUri, prod.targetUri, reason: reason);
        expect(model.launchPlan.acceptSelfSigned, prod.acceptSelfSigned,
            reason: reason);
      }
    });

    test(
        'clean query/fragment controls stay secure and launchable on ALL layers',
        () {
      for (final String uri in cleanCases) {
        final String reason = 'uri=$uri';

        expect(isSecureHttpsConsoleUri(uri), isTrue, reason: reason);
        expect(isControlSafeConsoleUri(uri), isTrue, reason: reason);

        final KvmConsoleLaunchPlan prod = _platformPlan(uri, production);
        expect(prod.route, KvmConsoleRenderRoute.externalBrowser,
            reason: reason);
        expect(prod.targetUri, uri, reason: reason);
        expect(prod.acceptSelfSigned, isFalse, reason: reason);

        // Same-origin self-navigation of a clean query/fragment is allowed.
        expect(
          allowsInAppNavigation(consoleUri: uri, targetUri: uri),
          isTrue,
          reason: reason,
        );

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
