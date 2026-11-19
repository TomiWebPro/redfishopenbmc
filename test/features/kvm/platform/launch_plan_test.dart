import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

void main() {
  group('planConsoleLaunch — flag OFF keeps the production fallback', () {
    test('secure HTTPS HTML5 routes to the external browser with its URI', () {
      const KvmWebViewPolicy policy = KvmWebViewPolicy.productionDefault;
      const String uri = 'https://bmc.example/console';

      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: policy,
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.isExternalBrowser, isTrue);
      expect(plan.isInApp, isFalse);
      expect(plan.targetUri, uri);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('plaintext HTTP falls back to copy-only, never self-signed', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'http://bmc.example/console',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isCopyOnly, isTrue);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a missing URI yields a null target and copy-only route', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: null,
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.targetUri, isNull);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a blank URI is never handed to a launcher as a target', () {
      // Inconsistent input (secure flag set but no real URI) must still fail
      // closed: downgrade to copy-only instead of launching whitespace.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: '   ',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.acceptSelfSigned, isFalse);
    });
  });

  group('planConsoleLaunch — opt-in is reversible and TLS-safe', () {
    test('test opt-in on HTTPS selects in-app and allows self-signed', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.inAppWebView);
      expect(plan.isInApp, isTrue);
      expect(plan.targetUri, 'https://bmc.example/console');
      expect(plan.acceptSelfSigned, isTrue);
    });

    test('opt-in with strict TLS never accepts self-signed', () {
      const KvmWebViewPolicy enabledStrict = KvmWebViewPolicy(enabled: true);
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: enabledStrict,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.inAppWebView);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('opt-in still refuses plaintext HTTP entirely', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'http://bmc.example/console',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('opt-in refuses disabled and non-HTML5 consoles in-app', () {
      final KvmConsoleLaunchPlan disabled = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: false,
      );
      final KvmConsoleLaunchPlan nonHtml5 = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: false,
        isEnabled: true,
      );

      expect(disabled.isInApp, isFalse);
      expect(disabled.acceptSelfSigned, isFalse);
      expect(nonHtml5.isInApp, isFalse);
      expect(nonHtml5.acceptSelfSigned, isFalse);
    });

    test('target URI is trimmed for every launchable route', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: '  https://bmc.example/console\t',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example/console');
    });
  });

  group('planConsoleLaunch — defense in depth: URI scheme re-validation', () {
    test(
        'a stale secure flag on a plaintext URI cannot enable in-app TLS weakening',
        () {
      // The caller-supplied hasSecureUri may be stale or wrong. Defense in
      // depth: the actual URI string must also be HTTPS, otherwise plaintext
      // HTTP could be rendered in-app with a self-signed cert under the opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'http://bmc.example/console',
        hasSecureUri: true, // inconsistent signal
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a non-HTTPS scheme cannot be rendered in-app even with a secure flag',
        () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'file:///etc/passwd',
        hasSecureUri: true, // inconsistent signal
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('uppercase HTTPS scheme is still recognised as secure', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'HTTPS://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'HTTPS://bmc.example/console');
    });

    test('an HTTPS URI with an empty host fails closed', () {
      // `hasSecureLaunchUri` means "HTTPS with a non-empty host". Re-validating
      // only the scheme leaves a gap: a stale secure flag paired with a
      // host-less `https:///` URI would still reach in-app rendering and
      // self-signed acceptance even though there is no BMC to talk to.
      for (final String uri in <String>[
        'https:///console',
        'https://?q=console',
        'https://#console',
        'https://user@/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('a host-bearing HTTPS URI with userinfo or port stays secure', () {
      // Guard: requiring a non-empty host must not reject legitimate targets
      // that carry userinfo or an explicit port.
      for (final String uri in <String>[
        'https://bmc.example:8443/console',
        'https://user@bmc.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.externalBrowser, reason: uri);
        expect(plan.targetUri, uri, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — fail closed for an unopenable console', () {
    test('a disabled HTTPS console gets a copy-only plan, never a launch route',
        () {
      // A disabled console is not openable (KvmConsole.canOpenConsole ==
      // false). Even under the test opt-in the plan must not hand its URI to
      // an external browser or an in-app WebView, and must never grant
      // self-signed acceptance.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: 'https://bmc.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: false,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.isInApp, isFalse);
      expect(plan.isExternalBrowser, isFalse);
      expect(plan.isCopyOnly, isTrue);
      expect(plan.acceptSelfSigned, isFalse);
      expect(plan.targetUri, 'https://bmc.example/console');
    });

    test('a copy-only plan still hands back a trimmed, usable URI', () {
      // The copy path is the only route for an insecure/disabled console, so
      // it must never surface a whitespace-padded target (which would break a
      // clipboard paste or an external client). Trimming applies to every
      // route, not just the launchable ones.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: '  http://bmc.example/console  ',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.targetUri, 'http://bmc.example/console');
    });

    test('a disabled console with no URI fails closed with a null target', () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: null,
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: false,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.targetUri, isNull);
      expect(plan.acceptSelfSigned, isFalse);
    });
  });

  group('planConsoleLaunch — defense in depth: malformed authority parity', () {
    test('a malformed authority with a stale secure flag fails closed', () {
      // The re-validator mirrors `hasSecureLaunchUri`, which uses Uri.tryParse.
      // A hand-rolled authority check can be fooled into calling a malformed
      // target "secure" (e.g. a non-numeric or duplicated port). With a stale
      // secure flag under the test opt-in that false positive would enable
      // in-app rendering and self-signed acceptance — so it must fail closed.
      for (final String uri in <String>[
        'https://bmc.example:notaport/console',
        'https://bmc.example::443/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — defense in depth: control-character rejection',
      () {
    test(
        'embedded control characters fail closed even with a stale secure flag',
        () {
      // `Uri.tryParse` silently percent-encodes C0/DEL control characters into
      // the host/path instead of rejecting them, so a purely syntactic
      // `scheme == 'https' && host.isNotEmpty` re-check calls these "secure".
      // Handing a CRLF/NUL-bearing URI to a launcher risks header/URI injection,
      // and under a stale secure flag + test opt-in it would also grant
      // self-signed acceptance. All control chars must fail closed.
      for (final String uri in <String>[
        'https://bmc.example/con\nsol', // LF
        'https://bmc.example/con\r\nsol', // CRLF
        'https://bmc.example/con\u0000sol', // NUL
        'https://bmc.example/con\tsol', // TAB
        'https://bmc.example/con\u007Fsol', // DEL
        'https://bmc.exa\nmple/console', // control char in host
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('a control-char URI never reaches in-app even with a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a malformed URI must not
      // be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example/con\u0001sol',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a clean HTTPS URI is still accepted (guard against over-rejection)',
        () {
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://bmc.example:8443/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example:8443/console');
    });
  });

  group('planConsoleLaunch — defense in depth: raw-space rejection', () {
    test('a raw space that Uri.tryParse encodes into the host fails closed',
        () {
      // `Uri.tryParse` percent-encodes a raw space instead of rejecting it
      // (e.g. `https://bmc.exa mple/console` -> host `bmc.exa%20mple`, still
      // non-empty), so a purely syntactic re-check calls it "secure". With a
      // stale secure flag + test opt-in it would reach in-app rendering and
      // self-signed acceptance on a malformed host. A raw space is never valid
      // in a URI (it must be %20), so every raw space must fail closed — just
      // like the C0/DEL control characters already rejected.
      for (final String uri in <String>[
        'https://bmc.exa mple/console', // space in host
        'https://user name@bmc.example/console', // space in userinfo
        'https://bmc.example/con sole', // space in path
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('a percent-encoded space is legitimate and stays launchable', () {
      // Guard against over-rejection: %20 is the correct encoding of a space
      // and contains no raw space code unit, so it must remain launchable and
      // keep the external-browser fallback (no TLS weakening).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://bmc.example/console%20one',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example/console%20one');
      expect(plan.acceptSelfSigned, isFalse);
    });
  });

  group('HTTP transport classifiers share the control-char hardening', () {
    test('plaintext/HTTP-family classifiers reject raw spaces and C0/DEL', () {
      for (final String uri in <String>[
        'http://bmc.exa mple/console', // raw space in host
        'http://bmc.example/con sol', // raw space in path
        'http://bmc.example/con\nsol', // LF
        'http://bmc.example/con\r\nsol', // CRLF
        'http://bmc.example/con\u0000sol', // NUL
        'http://bmc.example/con\tsol', // TAB
        'http://bmc.example/con\u007Fsol', // DEL
      ]) {
        expect(isPlaintextHttpConsoleUri(uri), isFalse, reason: uri);
        expect(isHttpConsoleUri(uri), isFalse, reason: uri);
      }
    });

    test('clean HTTP(S) URIs are classified correctly (guards)', () {
      expect(isPlaintextHttpConsoleUri('http://bmc.example/kvm'), isTrue);
      expect(isPlaintextHttpConsoleUri('  http://bmc.example/kvm  '), isTrue);
      expect(isPlaintextHttpConsoleUri('https://bmc.example/kvm'), isFalse);
      expect(isHttpConsoleUri('http://bmc.example/kvm'), isTrue);
      expect(isHttpConsoleUri('  https://bmc.example/kvm  '), isTrue);
      expect(isHttpConsoleUri('https://bmc.example/console%20one'), isTrue);
    });

    test('non-HTTP, host-less and malformed URIs fail closed', () {
      for (final String? uri in <String?>[
        null,
        '',
        '   ',
        'vnc://bmc.example:5900',
        'file:///etc/passwd',
        '/redfish/v1/Managers/BMC',
        'http:///console',
        'http://bmc.example:notaport/kvm',
      ]) {
        expect(isHttpConsoleUri(uri), isFalse, reason: 'uri=$uri');
        expect(isPlaintextHttpConsoleUri(uri), isFalse, reason: 'uri=$uri');
      }
    });

    test('all three classifiers agree on hardened control-char rejection', () {
      for (final String uri in <String>[
        'https://bmc.exa mple/console',
        'https://bmc.example/con\r\nsol',
        'http://bmc.exa mple/console',
        'http://bmc.example/con\u0000sol',
      ]) {
        expect(isSecureHttpsConsoleUri(uri), isFalse, reason: uri);
        expect(isPlaintextHttpConsoleUri(uri), isFalse, reason: uri);
        expect(isHttpConsoleUri(uri), isFalse, reason: uri);
      }
      expect(isSecureHttpsConsoleUri('https://bmc.example/kvm'), isTrue);
      expect(isHttpConsoleUri('https://bmc.example/kvm'), isTrue);
      expect(isPlaintextHttpConsoleUri('http://bmc.example/kvm'), isTrue);
    });
  });

  group(
      'planConsoleLaunch — defense in depth: Unicode whitespace/invisible rejection',
      () {
    test(
        'invisible/whitespace Unicode that Uri.tryParse encodes into the host fails closed',
        () {
      // The ASCII-only raw-space/control rejection is not enough: Uri.tryParse
      // also silently percent-encodes Unicode separators and format/invisible
      // characters (NBSP, zero-width space, line separator, ideographic space)
      // into the host/path rather than rejecting them, so a purely ASCII
      // syntactic re-check still calls these "secure". None of these are valid
      // raw in a URI (they must be percent-encoded), and an embedded one is not
      // removed by String.trim(); under a stale secure flag + test opt-in it
      // would reach in-app rendering and self-signed acceptance on a malformed
      // or spoofed host. All such characters must fail closed.
      for (final String uri in <String>[
        'https://bmc\u00A0.example/console', // NBSP in host
        'https://bmc\u200B.example/console', // zero-width space in host
        'https://bmc\u2028.example/console', // line separator in host
        'https://bmc\u3000.example/console', // ideographic space in host
        'https://bmc.example/con\u00A0sole', // NBSP in path
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true, // stale/inconsistent signal
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('a non-ASCII but non-whitespace path char is not over-rejected', () {
      // Guard: the rule targets Unicode separator/control/format categories,
      // not all non-ASCII. A legitimate non-ASCII path character remains
      // launchable via the external-browser fallback (no TLS weakening).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://bmc.example/\u{1F600}',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.acceptSelfSigned, isFalse);
    });
  });
}
