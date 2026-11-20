/// EP-P6 (issue #009/#021) — machine-checkable closeout of the resolved
/// no-embedded-WebView final route.
///
/// The human-gated decision in `WEBVIEW_TLS_MATRIX.md` / `LAUNCH_FALLBACK.md`
/// is: production never embeds a WebView, never accepts a self-signed
/// certificate, and keeps the external-browser + copy fallback byte-for-byte.
/// `product_import_policy_test.dart` (EP-P5) pins the *import* surface; this
/// test pins the *decision* surface so a future edit cannot silently re-open an
/// in-app route or grant self-signed TLS on a fallback.
///
/// Over the full cross-product of console signals x URI forms, under the
/// production default policy (WebView flag OFF), it asserts:
///   1. the route is NEVER `inAppWebView`;
///   2. `acceptSelfSigned` is NEVER true;
///   3. every non-null `targetUri` is control-safe (`isControlSafeConsoleUri`)
///      and already trimmed;
///   4. any blank / control-unsafe URI degrades to `copyOnly` with a null target
///      (a stale/lying `hasSecureUri` signal must not change that).
///
/// Pure Dart + flutter_test: no dependency, no WebView import, no live BMC, no
/// production TLS behaviour change (issue #009/#021).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// One console-signal combination. `hasSecureUri` is deliberately independent
/// of the URI form: a stale/lying signal must still fail closed.
({bool hasSecureUri, bool isHtml5, bool isEnabled}) _signal({
  required bool hasSecureUri,
  required bool isHtml5,
  required bool isEnabled,
}) =>
    (hasSecureUri: hasSecureUri, isHtml5: isHtml5, isEnabled: isEnabled);

void main() {
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;

  // 8 signal combinations x 12 URI forms = 96 cross-product cases.
  final List<({bool hasSecureUri, bool isHtml5, bool isEnabled})> signals =
      <({bool hasSecureUri, bool isHtml5, bool isEnabled})>[
    for (final bool hasSecureUri in <bool>[true, false])
      for (final bool isHtml5 in <bool>[true, false])
        for (final bool isEnabled in <bool>[true, false])
          _signal(
            hasSecureUri: hasSecureUri,
            isHtml5: isHtml5,
            isEnabled: isEnabled,
          ),
  ];

  // Covers valid HTTPS, padded HTTPS, plaintext HTTP, an external-client
  // scheme, blank/whitespace, CRLF/NUL/raw-space, a fullwidth NFKC/IDNA
  // confusable authority, a malformed percent escape and null.
  const List<String?> uriForms = <String?>[
    'https://bmc.example/console',
    '  https://bmc.example/console  ',
    'http://bmc.example/console',
    'vnc://bmc.example:5900',
    '',
    '   ',
    'https://bmc.example/a\r\nX-Injected: 1',
    'https://bmc.example/a\x00b',
    'https://bmc.example/a b',
    'https://\uFF42\uFF4D\uFF43.example/console', // fullwidth ｂｍｃ host
    'https://bmc.example/a%zz',
    null,
  ];

  group('EP-P6 production final-route invariant (cross-product)', () {
    test('cross-product is non-trivial and covers both safe and unsafe URIs',
        () {
      expect(signals.length, 8);
      expect(uriForms.length, 12);
      expect(signals.length * uriForms.length, 96);
      // At least one control-safe and one control-unsafe/blank form, otherwise
      // the invariant assertions below could pass vacuously.
      expect(uriForms.any(isControlSafeConsoleUri), isTrue);
      expect(uriForms.any((String? u) => !isControlSafeConsoleUri(u)), isTrue);
    });

    test(
        'production NEVER routes in-app, NEVER self-signed, target always '
        'control-safe, unsafe URI always degrades to copy-only', () {
      int cases = 0;
      for (final ({bool hasSecureUri, bool isHtml5, bool isEnabled}) s
          in signals) {
        for (final String? uri in uriForms) {
          cases++;
          final String reason =
              'signal=($s), uri=${uri == null ? 'null' : '${uri.codeUnits}'}';
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: production,
            uri: uri,
            hasSecureUri: s.hasSecureUri,
            isHtml5: s.isHtml5,
            isEnabled: s.isEnabled,
          );

          // 1. No embedded WebView under the production default, ever.
          expect(
            plan.route,
            isNot(KvmConsoleRenderRoute.inAppWebView),
            reason: 'I1 in-app route under production — $reason',
          );
          expect(plan.isInApp, isFalse, reason: 'I1 isInApp — $reason');

          // 2. Self-signed acceptance is never granted on a fallback route
          //    (and the production policy cannot grant it at all).
          expect(
            plan.acceptSelfSigned,
            isFalse,
            reason: 'I2 self-signed accepted under production — $reason',
          );

          // 3. Any handed-back target is itself control-safe and trimmed.
          final String? target = plan.targetUri;
          if (target != null) {
            expect(
              isControlSafeConsoleUri(target),
              isTrue,
              reason: 'I3 non-control-safe target — $reason',
            );
            expect(target, target.trim(),
                reason: 'I3 untrimmed target — $reason');
          }

          // 4. A blank/control-unsafe input fails closed: copy-only + no target.
          if (!isControlSafeConsoleUri(uri)) {
            expect(
              plan.route,
              KvmConsoleRenderRoute.copyOnly,
              reason: 'I4 unsafe URI not copy-only — $reason',
            );
            expect(
              plan.targetUri,
              isNull,
              reason: 'I4 unsafe URI leaked a target — $reason',
            );
          }
        }
      }
      expect(cases, 96);
    });

    test(
        'a secure HTML5 enabled console still routes to the external browser '
        '(not in-app) under production', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: production,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example/console');
      expect(plan.acceptSelfSigned, isFalse);
    });
  });
}
