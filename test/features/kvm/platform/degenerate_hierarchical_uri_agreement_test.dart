/// EP-P23 (issue #009/#021) — degenerate hierarchical-URI form cross-layer
/// fail-closed agreement.
///
/// A BMC-supplied HTTPS `ConnectUri` is normally a hierarchical URI with a real
/// authority (`https://host/x`). Dart's `Uri.tryParse` also accepts a family of
/// DEGENERATE hierarchical forms that carry the `https` scheme but no usable
/// host: an opaque `https:opaque`, a single-slash `https:/x`, a triple-slash
/// `https:///x`, an empty-authority-with-query `https://?q`, an empty-authority-
/// with-fragment `https://#f` and the bare scheme `https:`. These have an empty
/// `[Uri.host]` — there is no BMC to contact — yet a naive
/// `scheme == 'https'` re-check (the exact divergence class documented in
/// `launch_plan.dart`) could call them secure, reaching in-app rendering and
/// self-signed acceptance under a stale secure flag + test opt-in.
///
/// Two independent decision families consume the same raw URI:
///   * the **platform layer** — [isSecureHttpsConsoleUri], [isHttpConsoleUri],
///     [planConsoleLaunch] (render route + control-safe copy target + self-
///     signed flag) and [allowsInAppNavigation] (RP-1 origin confinement), and
///   * the **model layer** — `KvmConsole.hasSecureLaunchUri` / `canOpenConsole` /
///     `launchStrategy` / `launchPlan`, which the console card and viewer gate on.
///
/// AUDIT FIRST: the shared whole-URI fail-closed core already classifies the
/// whole family identically on every layer (empty `Uri.host` is rejected in
/// `_isHttpUriWithSchemes`; the `://` forms are doubly protected by
/// `_hasDegenerateAuthorityHost`), so there is NO live divergence. But nothing
/// sweeps these six degenerate forms through ALL four platform layers plus the
/// model at once — an opaque `https:opaque` and a scheme-only `https:` rely on
/// the single `parsed.host.isEmpty` check, so a plausible "the parser already
/// rejects malformed URIs" refactor that drops that check would flip exactly
/// those no-authority forms to secure on EVERY layer while each existing
/// single-surface suite stayed green. This is a read-only characterization
/// guard of that previously unguarded cross-layer seam.
///
/// No production behaviour is changed; no WebView/protocol import, no URL
/// opened, no dependency, no production TLS weakening (issues #009 / #021).
/// Complements EP-P9 (hostile authorities), EP-P13 (authority confusion) and
/// EP-P21 (IPv6 literals) with the degenerate hierarchical-form family.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// One degenerate hierarchical form (or the clean control) and its AUDITED
/// classification under the shared fail-closed core.
class _Case {
  const _Case(
    this.family,
    this.uri,
    this.parsedHost,
    this.hasAuthority,
    this.secure,
  );

  final String family;
  final String uri;
  final String parsedHost; // Uri.tryParse(uri).host characterization.
  final bool hasAuthority; // Uri.tryParse(uri).hasAuthority characterization.
  final bool secure; // false for every degenerate form; true for the control.
}

// Classifications are CHARACTERIZATIONS of the current shared core, verified
// with isSecureHttpsConsoleUri across all four platform layers plus the model.
// Every degenerate form has an empty Uri.host; the `://` forms additionally
// report hasAuthority=true (caught by _hasDegenerateAuthorityHost), while the
// opaque / single-slash / scheme-only forms rely solely on `host.isEmpty`.
// The clean control is the non-vacuous, secure, in-app-eligible sanity case.
const List<_Case> kDegenerateMatrix = <_Case>[
  _Case('opaque', 'https:opaque', '', false, false),
  _Case('single-slash', 'https:/x', '', false, false),
  _Case('triple-slash', 'https:///x', '', true, false),
  _Case('empty-authority-query', 'https://?q', '', true, false),
  _Case('empty-authority-fragment', 'https://#f', '', true, false),
  _Case('scheme-only', 'https:', '', false, false),
  _Case('clean-control', 'https://host/x', 'host', true, true),
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

  group('EP-P23 degenerate hierarchical-URI cross-layer agreement', () {
    test('matrix is non-trivial, spans both classes and names every form', () {
      expect(kDegenerateMatrix.length, 7);
      expect(kDegenerateMatrix.where((_Case c) => c.secure).length, 1);
      expect(kDegenerateMatrix.where((_Case c) => !c.secure).length, 6);
      expect(kDegenerateMatrix.map((_Case c) => c.family).toSet().length,
          kDegenerateMatrix.length);
      expect(
        kDegenerateMatrix
            .singleWhere((_Case c) => c.family == 'clean-control')
            .secure,
        isTrue,
      );
      expect(
        kDegenerateMatrix.every((_Case c) => c.uri.startsWith('https')),
        isTrue,
      );
      // Every degenerate form has an empty parsed host; the clean control does
      // not. At least one no-authority form and one `://` empty-authority form
      // must be present so both fail-closed branches are exercised.
      expect(
        kDegenerateMatrix
            .where((_Case c) => !c.secure)
            .every((_Case c) => c.parsedHost.isEmpty),
        isTrue,
      );
      expect(
        kDegenerateMatrix
            .where((_Case c) => !c.secure && !c.hasAuthority)
            .length,
        3,
      );
      expect(
        kDegenerateMatrix
            .where((_Case c) => !c.secure && c.hasAuthority)
            .length,
        3,
      );
    });

    test('per-form parse is pinned and every layer agrees', () {
      for (final _Case c in kDegenerateMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // Record the Uri.tryParse host/authority characterization (the parser
        // axis this guard isolates): every degenerate form carries the https
        // scheme but an empty host — the value a naive scheme-only check would
        // wrongly call secure.
        final Uri? parsed = Uri.tryParse(c.uri);
        expect(parsed, isNotNull, reason: 'unparseable probe — $why');
        expect(parsed!.scheme, 'https', reason: 'scheme drift — $why');
        expect(parsed.host, c.parsedHost,
            reason: 'parsed-host characterization drift — $why');
        expect(parsed.hasAuthority, c.hasAuthority,
            reason: 'authority characterization drift — $why');

        // The shared fail-closed classifier and its HTTP(S) family sibling
        // agree per form: only the control is secure/launchable.
        final bool platformSecure = isSecureHttpsConsoleUri(c.uri);
        expect(platformSecure, c.secure, reason: 'classifier drift — $why');
        expect(isHttpConsoleUri(c.uri), c.secure,
            reason: 'http-family classifier disagreement — $why');

        // The model layer agrees field-for-field with the platform classifier.
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

        // The policy-independent origin-confinement gate agrees per form: a
        // degenerate console can never navigate in-app, even to itself.
        expect(
          allowsInAppNavigation(consoleUri: c.uri, targetUri: c.uri),
          c.secure,
          reason: 'navigation gate disagrees with classifier — $why',
        );

        // Degenerate forms stay control-safe to COPY (no forbidden bytes), but
        // are never an in-app launch target; that decision is the route below.
        expect(isControlSafeConsoleUri(c.uri), isTrue,
            reason: 'clean form lost control-safety — $why');
      }
    });

    test(
        'production plan never routes in-app or accepts self-signed, even '
        'under a stale secure flag; model plan agrees field-for-field', () {
      for (final _Case c in kDegenerateMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';

        // A stale/lying secure flag must still fail closed under production and
        // must never enable self-signed acceptance on a degenerate form.
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

        // Secure control goes to the external browser; every degenerate form
        // degrades to copy-only — never an in-app launch target.
        expect(
          platform.route,
          c.secure
              ? KvmConsoleRenderRoute.externalBrowser
              : KvmConsoleRenderRoute.copyOnly,
          reason: 'production route classification drift — $why',
        );
      }
    });

    test('test-only opt-in eligibility is uniform per form', () {
      for (final _Case c in kDegenerateMatrix) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        final KvmConsoleLaunchPlan plan = _plan(optIn, c.uri);
        if (c.secure) {
          expect(plan.route, KvmConsoleRenderRoute.inAppWebView,
              reason: 'genuine secure control not opt-in eligible — $why');
          expect(plan.acceptSelfSigned, isTrue,
              reason: 'opt-in self-signed not granted to control — $why');
        } else {
          expect(plan.route, isNot(KvmConsoleRenderRoute.inAppWebView),
              reason: 'degenerate form reached in-app under opt-in — $why');
          expect(plan.acceptSelfSigned, isFalse,
              reason: 'degenerate form accepted self-signed — $why');
        }
      }
    });

    test(
        'navigation gate fails closed with a degenerate console or a '
        'degenerate target', () {
      const String secureConsole = 'https://host/console';
      for (final _Case c in kDegenerateMatrix.where((_Case c) => !c.secure)) {
        final String why = 'family=${c.family} uri=${c.uri.codeUnits}';
        // Degenerate console on either side of the gate is never navigable.
        expect(
          allowsInAppNavigation(consoleUri: c.uri, targetUri: c.uri),
          isFalse,
          reason: 'degenerate console navigable to itself — $why',
        );
        expect(
          allowsInAppNavigation(
            consoleUri: c.uri,
            targetUri: secureConsole,
          ),
          isFalse,
          reason: 'degenerate console navigable to secure target — $why',
        );
        // A degenerate navigation target from a real secure console is blocked
        // (origin confinement), independent of the console being openable.
        expect(
          allowsInAppNavigation(
            consoleUri: secureConsole,
            targetUri: c.uri,
          ),
          isFalse,
          reason: 'degenerate target navigable from secure console — $why',
        );
      }
      // The clean control remains self-navigable (sanity / non-vacuity).
      expect(
        allowsInAppNavigation(
          consoleUri: secureConsole,
          targetUri: 'https://host/other',
        ),
        isTrue,
      );
    });
  });
}
