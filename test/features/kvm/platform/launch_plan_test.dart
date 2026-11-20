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

  group('planConsoleLaunch — defense in depth: raw-backslash rejection', () {
    test('a raw backslash that Uri.tryParse treats as a slash fails closed',
        () {
      // A raw backslash is not a legal URI character (it must be percent-encoded
      // as %5C), yet `Uri.tryParse` treats it as a path/authority separator and
      // can still call the result an HTTPS URI with a non-empty host. E.g.
      // `https://bmc.example\@evil.com/console` parses with host `bmc.example`
      // while a launcher that does not fold backslashes to slashes may resolve
      // a different authority — a parser-differential/host-confusion risk. With
      // a stale secure flag + test opt-in that would reach in-app rendering and
      // self-signed acceptance on a malformed/spoofed authority, so every raw
      // backslash must fail closed.
      for (final String uri in <String>[
        r'https:\\bmc.example\console', // backslashes as authority separators
        r'https://bmc.example\console', // backslash as path separator
        r'https://bmc.example\@evil.com/console', // host confusion
        r'https://trusted.example\@evil.example/console', // host confusion
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

    test('a raw-backslash URI never reaches in-app under a strict opt-in', () {
      // Even without granting self-signed acceptance, a backslash-delimited URI
      // must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: r'https:\bmc.example\console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('a percent-encoded backslash is legitimate and stays launchable', () {
      // Guard against over-rejection: %5C is the correct encoding of a backslash
      // and contains no raw backslash, so it must remain launchable via the
      // external-browser fallback (no TLS weakening, no valid target lost).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://bmc.example/console%5Cpath',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, 'https://bmc.example/console%5Cpath');
      expect(plan.acceptSelfSigned, isFalse);
    });
  });

  group('planConsoleLaunch — defense in depth: RFC-3986 unwise-char rejection',
      () {
    test(
        'raw unwise ASCII that Uri.tryParse encodes into the host fails closed',
        () {
      // Uri.tryParse silently percent-encodes the RFC-3986 "unwise" ASCII
      // characters (", <, >, ^, `, {, |, }) instead of rejecting them, so e.g.
      // `https://bmc<example/console` parses with scheme https and a non-empty
      // host `bmc%3Cexample`, passing a purely syntactic re-check. None are
      // legal raw in a URI (they must be pct-encoded); under a stale secure
      // flag + test opt-in they would reach in-app rendering and self-signed
      // acceptance on a malformed/spoofed authority (a parser differential).
      // Every raw unwise char must therefore fail closed.
      for (final String uri in <String>[
        'https://bmc<example/console', // <
        'https://bmc>example/console', // >
        'https://bmc"example/console', // "
        'https://bmc^example/console', // ^
        'https://bmc`example/console', // `
        'https://bmc{example/console', // {
        'https://bmc|example/console', // |
        'https://bmc}example/console', // }
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

    test('raw unwise chars in path/query fail closed too', () {
      for (final String uri in <String>[
        'https://bmc.example/con"sole', // " in path
        'https://bmc.example/console?<x>', // < > in query
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

    test('a raw-unwise URI never reaches in-app under a strict opt-in', () {
      // Even without granting self-signed acceptance, a malformed URI must not
      // be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc<example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('percent-encoded unwise chars and legal delimiters stay launchable',
        () {
      // Guard against over-rejection: %3C/%22 are correct encodings (no raw
      // unwise char), and sub-delims/gen-delims (& = [ ]) are legal raw in a
      // URI, so none may be dropped from the fallback path (no TLS weakening).
      for (final String uri in <String>[
        'https://bmc.example/console%3Cone', // %3C = <
        'https://bmc.example/console%22one', // %22 = "
        'https://bmc.example/console?a=1&b=2', // & = are legal sub-delims
        'https://[::1]:8443/console', // [ ] are legal gen-delims (IPv6 host)
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: malformed percent-encoding rejection',
      () {
    test('a raw percent that is not a valid %XX escape fails closed', () {
      // `Uri.tryParse` silently percent-encodes a malformed `%` (one not
      // followed by exactly two hex digits) into the host instead of rejecting
      // it: `https://bmc.example%/console` -> host `bmc.example%25`, and
      // `...%ZZ` -> host `bmc.example%25zz`. None of these contain a raw
      // forbidden char (a bare `%` is not in the forbidden set, since valid
      // `%XX` escapes must stay launchable), so a purely syntactic re-check
      // calls them "secure". Under a stale secure flag + test opt-in they
      // would reach in-app rendering and self-signed acceptance on a malformed
      // host. A `%` must always begin a valid `%XX` escape (RFC 3986
      // `pct-encoded = "%" HEXDIG HEXDIG`), so every malformed occurrence fails
      // closed — stricter than the model, never more permissive.
      for (final String uri in <String>[
        'https://bmc.example%/console', // bare percent before path
        'https://bmc.example%ZZ/console', // non-hex after percent
        'https://bmc.example%2/console', // only one hex digit
        'https://bmc.exa%mple/console', // malformed percent in host
        'https://bmc.example/console%', // trailing bare percent
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

    test('a malformed percent URI never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a malformed escape must
      // not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%ZZ/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('valid %XX escapes (uppercase and lowercase hex) stay launchable', () {
      // Guard against over-rejection: correctly formed percent escapes are the
      // only legal way to carry reserved/unsafe bytes in a URI and must remain
      // launchable via the external-browser fallback (no TLS weakening, no
      // valid target lost). Both hex cases and multiple escapes are accepted.
      for (final String uri in <String>[
        'https://bmc.example/console%2fone', // lowercase hex
        'https://bmc.example/console%2FONE', // uppercase hex
        'https://bmc.example/console%41%42', // multiple escapes
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: raw non-ASCII authority rejection',
      () {
    test(
        'a raw non-ASCII character in the authority fails closed with a stale flag',
        () {
      // RFC 3986 URIs are ASCII-only: a raw non-ASCII character (an IDN
      // homograph, accented letter, or emoji) must be pct-encoded / punycode
      // encoded before it can appear in a host. `Uri.tryParse` does NOT reject
      // a raw non-ASCII authority — it silently pct-encodes it into the host
      // (e.g. Cyrillic 'a' U+0430 -> host `bmc%D0%B0.example`), which still has
      // a non-empty host and passes a purely syntactic re-check. A raw Unicode
      // authority is a host-spoofing risk (confusable/homograph labels): under
      // a stale secure flag + test opt-in it would reach in-app rendering and
      // self-signed acceptance on a malformed/spoofed host. The rule is scoped
      // to the authority so legitimate non-ASCII path/query text stays
      // launchable (no valid target lost).
      for (final String uri in <String>[
        'https://bmc\u0430.example/console', // Cyrillic 'a' homograph in host
        'https://bmc\u00E9.example/console', // e-acute in host
        'https://bmc\u{1F600}.example/console', // emoji in host
        'https://user\u00E9@bmc.example/console', // non-ASCII in userinfo
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

    test('a raw non-ASCII authority never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a raw Unicode authority
      // must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc\u0430.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('ASCII punycode host and non-ASCII path/query stay launchable', () {
      // Guard against over-rejection: an ASCII-only pct-encoded/punycode host
      // is a valid encoding, and non-ASCII text in the path/query does not
      // affect the TLS-sensitive authority decision, so both stay launchable
      // via the external-browser fallback (no TLS weakening, no target lost).
      for (final String uri in <String>[
        'https://xn--bmc-esab.example/console', // ASCII punycode host
        'https://bmc.example/console\u00E9', // non-ASCII in path
        'https://bmc.example/caf\u00E9?q=\u{1F600}', // non-ASCII path + query
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: encoded authority-delimiter rejection',
      () {
    test('a percent-encoded authority delimiter fails closed with a stale flag',
        () {
      // RFC 3986 gen-delims (`: / ? # [ ] @`) and the backslash are structural:
      // they decide where the authority ends and which host is contacted.
      // Percent-encoding one in the authority is a host-confusion vector because
      // consumers disagree on decode order: `Uri.tryParse` keeps `%40` in the
      // host (`bmc.example%40evil.com`) while a launcher that decodes before
      // splitting the authority reads `@evil.com` as userinfo/host. Under a
      // stale secure flag + test opt-in that parser differential would grant
      // in-app rendering and self-signed acceptance on a spoofed authority.
      // Every encoded structural char in the authority must fail closed.
      for (final String uri in <String>[
        'https://bmc.example%40evil.com/console', // %40 @ (userinfo delimiter)
        'https://bmc.example%2F.evil.com/console', // %2F / (authority terminator)
        'https://bmc.example%5C.evil.com/console', // %5C backslash (folded by parsers)
        'https://bmc.example%3F.evil.com/console', // %3F ? (query delimiter)
        'https://bmc.example%23.evil.com/console', // %23 # (fragment delimiter)
        'https://bmc.example%3A8443/console', // %3A : (port delimiter)
        'https://bmc.example%5Bevil%5D/console', // %5B %5D [] (IPv6 literal)
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

    test('lowercase percent-encoded delimiters also fail closed', () {
      // Percent-encoding hex is case-insensitive (RFC 3986), so the lowercase
      // spellings must be rejected just like their uppercase counterparts.
      for (final String uri in <String>[
        'https://bmc.example%2fevil.com/console', // %2F
        'https://bmc.example%5c.evil.com/console', // %5C
        'https://bmc.example%3a8443/console', // %3A
        'https://bmc.example%5bevil%5d/console', // %5B %5D
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

    test(
        'an encoded authority delimiter never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host-confused authority
      // must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%40evil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('encoded delimiters in path/query stay launchable (authority-scoped)',
        () {
      // Guard against over-rejection: path/query bytes do not decide which host
      // is contacted, so a pct-encoded delimiter there stays launchable via the
      // external-browser fallback (no TLS weakening, no valid target lost).
      for (final String uri in <String>[
        'https://bmc.example/console%40note', // %40 in path
        'https://bmc.example/console%2Fone', // %2F in path
        'https://bmc.example/console?a%3Ab', // %3A in query
        'https://bmc.example/caf%C3%A9', // encoded non-ASCII in path
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test(
        'a pct-encoded non-delimiter host stays launchable (no over-rejection)',
        () {
      // Guard: the rule targets structural delimiters only. A percent-encoded
      // non-ASCII byte in the host (a valid RFC 3986 pct-encoded IDN form) is
      // not a delimiter and must remain launchable via the fallback.
      const String uri = 'https://bmc%C3%A9.example/console';
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.externalBrowser);
      expect(plan.targetUri, uri);
      expect(plan.acceptSelfSigned, isFalse);
    });
  });

  group('planConsoleLaunch — defense in depth: encoded control-octet rejection',
      () {
    test('a percent-encoded C0/DEL octet fails closed with a stale flag', () {
      // A percent-encoded control octet is a *valid* %XX escape, so the
      // malformed-percent rule does not catch it, and it contains no raw
      // forbidden char. `Uri.tryParse` keeps it encoded and still reports an
      // https URI with a non-empty host, so a purely syntactic re-check calls
      // these "secure" — yet they are classic parser-differential vectors:
      // a NUL (%00) truncates the host in many consumers (`bmc.example%00.evil`
      // reads as `bmc.example`), CRLF (%0D%0A) enables header/URI injection,
      // and tab/unit-separator bytes confuse authority splitting. Under a
      // stale secure flag + test opt-in any could reach in-app rendering and
      // self-signed acceptance on a spoofed/malformed host. Every pct-encoded
      // C0 (0x00-0x1F) or DEL (0x7F) octet must fail closed.
      for (final String uri in <String>[
        'https://bmc.example%00.evil.com/console', // NUL host truncation
        'https://bmc.example/con%00sol', // NUL in path
        'https://bmc.example%0D%0Aevil:80/console', // CRLF injection
        'https://bmc.example%09.example/console', // TAB
        'https://bmc.example%1F/console', // unit separator (C0)
        'https://bmc.example%7F/console', // DEL
        'https://bmc.example%7f/console', // DEL, lowercase hex
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

    test('an encoded control octet never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a control-octet-bearing
      // URI must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%00.evil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('non-control pct-encoded octets stay launchable (no over-rejection)',
        () {
      // Guard: only C0/DEL octets are rejected. Other valid %XX escapes —
      // including the space (%20), which is 0x20 and not a C0 control — remain
      // launchable via the external-browser fallback (no TLS weakening, no
      // valid target lost). Both hex cases are covered.
      for (final String uri in <String>[
        'https://bmc.example/console%20one', // %20 space (0x20)
        'https://bmc.example/console%2fone', // %2F slash
        'https://bmc.example/console%7Eone', // %7E tilde (just above DEL)
        'https://bmc.example/caf%C3%A9', // %C3%A9 = UTF-8 e-acute
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: encoded Unicode separator/invisible rejection',
      () {
    test(
        'a percent-encoded Unicode separator/invisible fails closed with a stale flag',
        () {
      // A percent-encoded multi-byte UTF-8 character that decodes to a Unicode
      // Separator (Z) or Other (C) code point is still a *valid* %XX escape
      // (so the malformed-percent rule does not catch it), is not a single-byte
      // C0/DEL octet (so the encoded-control-octet rule does not catch it), and
      // contains no raw non-ASCII (so the raw-authority rule does not catch
      // it). `Uri.tryParse` keeps it encoded and still reports an HTTPS URI
      // with a non-empty host, so a purely syntactic re-check calls these
      // "secure" — yet a launcher that percent-decodes first turns e.g. %C2%A0
      // (NBSP, Zs) into an invisible separator in the host, and %E2%80%8B
      // (zero-width space, Cf) / %C2%85 (NEL, Cc) into an invisible control:
      // classic parser-differential / host-spoofing vectors. Under a stale
      // secure flag + test opt-in any could reach in-app rendering and
      // self-signed acceptance on a malformed/spoofed host, so every such
      // escaped character must fail closed.
      for (final String uri in <String>[
        'https://bmc%C2%A0.example/console', // NBSP (Zs) in host
        'https://bmc.example/con%E2%80%8Bsol', // zero-width space (Cf) in path
        'https://bmc%C2%85.example/console', // NEL (Cc) in host
        'https://bmc.example/con%E2%80%A8sol', // line separator (Zl) in path
        'https://bmc%E3%80%80.example/console', // ideographic space (Zs) in host
        'https://bmc.example/con%EF%BB%BFsol', // BOM (Cf) in path
        'https://user%E2%80%8B@bmc.example/console', // ZWSP (Cf) in userinfo
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

    test(
        'an encoded Unicode separator never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a URI carrying an encoded
      // invisible/control character must not be rendered in-app by an
      // enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc%C2%A0.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('encoded non-C/Z characters and ASCII escapes stay launchable', () {
      // Guard against over-rejection: only decoded non-ASCII code points in
      // the Unicode Separator/Other categories are rejected. Encoded letters
      // (%C3%A9 e-acute, a Letter), encoded emoji (%F0%9F%98%80, Symbol) and
      // ASCII escapes such as %20 (space) stay launchable via the
      // external-browser fallback — no TLS weakening, no valid target lost.
      for (final String uri in <String>[
        'https://bmc.example/caf%C3%A9', // %C3%A9 = e-acute (Letter)
        'https://bmc.example/%F0%9F%98%80', // emoji (Symbol)
        'https://bmc.example/console%20one', // %20 = ASCII space (exempt)
        'https://bmc.example/console%2Fone', // %2F = ASCII slash
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: encoded confusable-delimiter rejection',
      () {
    test(
        'a percent-encoded compatibility-confusable delimiter fails closed with a stale flag',
        () {
      // A percent-encoded non-ASCII code point whose Unicode NFKC
      // normalisation is an ASCII structural delimiter (gen-delims `:/?#[]@`,
      // backslash, or the domain-label dot) is an IDNA/compatibility-confusable
      // host-spoofing vector. `Uri.tryParse` keeps such an escape encoded and
      // reports an HTTPS URI with a non-empty host, so a purely syntactic
      // re-check calls it "secure" — yet a launcher that applies IDNA/NFKC to
      // an internationalised host (as browsers do) resolves a *different*
      // authority: `%EF%BC%8F` (fullwidth solidus) becomes `/`,
      // `%EF%BC%8E` (fullwidth full stop) becomes `.`, etc. This is the
      // percent-encoded analogue of the raw non-ASCII authority rule. Under a
      // stale secure flag + test opt-in it would reach in-app rendering and
      // self-signed acceptance on a spoofed/mismatched authority, so it fails
      // closed — stricter than the model, never more permissive.
      for (final String uri in <String>[
        'https://bmc.example%EF%BC%8Fconsole', // fullwidth solidus -> /
        'https://bmc.example%EF%BC%9A8443/console', // fullwidth colon -> :
        'https://bmc.example%EF%BC%8Eevil.com/console', // fullwidth dot -> .
        'https://bmc.example%EF%BC%9Fq/console', // fullwidth ? -> ?
        'https://bmc.example%EF%BC%BBevil%EF%BC%BD/console', // fullwidth []
        'https://bmc.example%E2%88%95evil/console', // division slash -> /
        'https://bmc.example%E2%81%84evil/console', // fraction slash -> /
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

    test(
        'an encoded confusable delimiter never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host-confused authority
      // must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%EF%BC%8Fconsole',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('encoded non-delimiters and path confusables stay launchable', () {
      // Guard against over-rejection: the rule targets only code points that
      // NFKC-normalise to a structural delimiter in the authority (the
      // TLS-sensitive part). Encoded non-delimiter non-ASCII (e-acute, euro,
      // emoji) stays launchable, and compat-confusable bytes in the path/query
      // do not affect which host is contacted, so they stay launchable too —
      // no valid target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/caf%C3%A9', // e-acute (Letter)
        'https://bmc.example/con%E2%82%AC', // euro sign (not a delimiter)
        'https://bmc.example/%F0%9F%98%80', // emoji (Symbol)
        'https://bmc.example/console%EF%BC%8Fone', // fullwidth solidus in path
        'https://bmc.example/console%E2%88%95one', // division slash in path
        'https://xn--bmc-esab.example/console', // punycode ASCII host
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: extended compatibility-confusable delimiter rejection',
      () {
    test(
        'small/vertical/dot-leader confusables that IDNA maps to delimiters fail closed',
        () {
      // The compatibility-confusable set must cover more than the fullwidth
      // forms. A launcher applying IDNA/NFKC to an internationalised host
      // resolves many more non-ASCII code points to ASCII structural delimiters:
      // SMALL FULL STOP (U+FE52 -> '.'), SMALL COLON (U+FE55 -> ':'), SMALL
      // REVERSE SOLIDUS (U+FE68 -> '\'), SMALL COMMERCIAL AT (U+FE6B -> '@'),
      // the vertical presentation forms (e.g. U+FE13 -> ':', U+FE47 -> '['),
      // and the dot leaders (U+2024 -> '.', U+2025 -> '..'). `Uri.tryParse`
      // keeps each escape encoded and reports an HTTPS host with a non-empty
      // host, so a purely syntactic re-check calls these "secure" — yet a
      // decode+IDNA launcher resolves a different/forged authority. Under a
      // stale secure flag + test opt-in any could reach in-app rendering and
      // self-signed acceptance on a spoofed host, so they must fail closed.
      for (final String uri in <String>[
        'https://bmc.example%EF%B9%92evil.com/console', // U+FE52 SMALL FULL STOP -> '.'
        'https://bmc.example%EF%B9%958443/console', // U+FE55 SMALL COLON -> ':'
        'https://bmc.example%EF%B9%A8evil.com/console', // U+FE68 SMALL REVERSE SOLIDUS -> '\'
        'https://bmc.example%EF%B9%ABevil.com/console', // U+FE6B SMALL COMMERCIAL AT -> '@'
        'https://bmc.example%EF%B8%93.evil/console', // U+FE13 VERTICAL COLON -> ':'
        'https://bmc%EF%B9%87evil.example/console', // U+FE47 VERTICAL LEFT SQUARE BRACKET -> '['
        'https://bmc%E2%80%A4example/console', // U+2024 ONE DOT LEADER -> '.'
        'https://bmc.example%EF%B9%9Fq/console', // U+FE5F SMALL NUMBER SIGN -> '#'
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

    test('an extended confusable never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host carrying an
      // IDNA-confusable delimiter must not be rendered in-app by an
      // enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%EF%B9%92evil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('extended confusables in the path stay launchable (authority-scoped)',
        () {
      // Guard against over-rejection: the rule targets only code points in the
      // authority (the TLS-sensitive part). An IDNA confusable in the path/query
      // cannot change which host is contacted, so it stays launchable via the
      // external-browser fallback — no valid target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console%EF%B9%92one', // SMALL FULL STOP in path
        'https://bmc.example/console%EF%B9%ABone', // SMALL COMMERCIAL AT in path
        'https://bmc.example/caf%C3%A9', // e-acute (Letter, not a confusable)
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — defense in depth: IDNA dot-confusable rejection',
      () {
    test(
        'percent-encoded CJK/halfwidth dot confusables fail closed with a stale flag',
        () {
      // The compatibility-confusable set must also cover the classic IDNA
      // dot confusables that a launcher applying UTS-46 IDNA to an
      // internationalised host resolves to the domain-label dot ('.'):
      //   U+3002 IDEOGRAPHIC FULL STOP
      //   U+FF61 HALFWIDTH IDEOGRAPHIC FULL STOP
      //   U+2E3C TWO DOT LEADER (NFKC -> two U+2024 -> '..')
      // `Uri.tryParse` keeps each escape encoded and reports an HTTPS URI with
      // a non-empty host, so a purely syntactic re-check calls these "secure"
      // — yet a decode+IDNA launcher resolves a *different* authority
      // (`bmc.example%E3%80%82evil.com` -> `bmc.example.evil.com`). None are
      // Unicode Separator/Other (so the encoded C/Z rule misses them) and none
      // were in the confusable set, so under a stale secure flag + test opt-in
      // they could reach in-app rendering and self-signed acceptance on a
      // spoofed/mismatched host. They must fail closed.
      for (final String uri in <String>[
        'https://bmc.example%E3%80%82evil.com/console', // U+3002 -> .
        'https://bmc.example%EF%BD%A1evil.com/console', // U+FF61 -> .
        'https://bmc.example%E2%B8%BCevil.com/console', // U+2E3C -> ..
        'https://bmc%e3%80%82example.com/console', // lowercase hex
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

    test('an IDNA dot confusable never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host carrying an IDNA
      // dot confusable must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%E3%80%82evil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('IDNA dot confusables in the path stay launchable (authority-scoped)',
        () {
      // Guard against over-rejection: the rule targets only the authority (the
      // TLS-sensitive part). A dot confusable in the path/query cannot change
      // which host is contacted, so it stays launchable via the fallback — no
      // valid target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console%E3%80%82one', // U+3002 in path
        'https://bmc.example/console%EF%BD%A1one', // U+FF61 in path
        'https://bmc.example/caf%C3%A9', // e-acute (Letter)
        'https://bmc.example/%F0%9F%98%80', // emoji (Symbol)
        'https://xn--bmc-esab.example/console', // punycode ASCII host
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: IDNA middle-dot confusable rejection',
      () {
    test(
        'percent-encoded middle-dot dot confusables fail closed with a stale flag',
        () {
      // U+00B7 MIDDLE DOT and U+0387 GREEK ANO TELEIA are classic IDNA dot
      // confusables: nameprep / IDNA2003 maps them to the domain-label dot
      // ('.'), so a decode+IDNA launcher resolves a DIFFERENT authority —
      // `bmc.example%C2%B7evil.com` -> `bmc.example.evil.com`. They are Unicode
      // category Po (punctuation), so neither the Separator/Other rule nor the
      // existing confusable set caught them. `Uri.tryParse` keeps each escape
      // encoded and reports a non-empty HTTPS host, so a purely syntactic
      // re-check calls such a target "secure"; under a stale secure flag +
      // test opt-in it would reach in-app rendering and self-signed acceptance
      // on a spoofed/mismatched host. They must fail closed.
      for (final String uri in <String>[
        'https://bmc.example%C2%B7evil.com/console', // U+00B7 MIDDLE DOT -> .
        'https://bmc.example%c2%b7evil.com/console', // lowercase hex
        'https://bmc.example%CE%87evil.com/console', // U+0387 GREEK ANO TELEIA -> .
        'https://bmc%CE%87example.com/console', // ano teleia mid-host
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

    test('a middle-dot confusable never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host carrying an IDNA
      // middle-dot confusable must not be rendered in-app by an enabled+strict
      // opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%C2%B7evil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test(
        'middle-dot confusables in the path stay launchable (authority-scoped)',
        () {
      // Guard against over-rejection: the rule is scoped to the authority (the
      // TLS-sensitive part). A middle dot in the path/query cannot change which
      // host is contacted, so it stays launchable via the external-browser
      // fallback — no valid target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console%C2%B7one', // U+00B7 in path
        'https://bmc.example/console%CE%87one', // U+0387 in path
        'https://bmc.example/caf%C3%A9', // e-acute (Letter, not a confusable)
        'https://xn--bmc-esab.example/console', // punycode ASCII host
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — defense in depth: degenerate dot-host rejection',
      () {
    test('an authority whose host is only dots fails closed with a stale flag',
        () {
      // `Uri.tryParse` reports a dot-only authority (e.g. `https://./`,
      // `https://../`) as an HTTPS URI with a NON-EMPTY host, so the existing
      // `scheme == 'https' && host.isNotEmpty` re-check calls it "secure".
      // `Uri.tryParse` also decodes a percent-encoded dot (`%2E`) in the host
      // into a literal '.', so `https://%2E%2E/console` reports host `..`.
      // There is no real BMC host to talk to (no label at all); a launcher may
      // resolve `..` as a relative/traversal path rather than a host. Under a
      // stale secure flag + test opt-in such a target would otherwise reach
      // in-app rendering and self-signed acceptance on a bogus host. Every
      // dot-only / no-label host must fail closed.
      for (final String uri in <String>[
        'https://./console', // single dot
        'https://../console', // double dot
        'https://.../console', // triple dot
        'https://./', // dot-only authority, no path
        'https://%2E%2E/console', // percent-encoded dot -> '..'
        'https://.%2E/console', // mixed encoded dot -> '..'
        'https://%2e/console', // lowercase hex encoded dot
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

    test('a dot-only host never reaches in-app under a strict opt-in', () {
      // Even without granting self-signed acceptance, a dot-only / no-label
      // authority must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://../console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('real hosts (incl. trailing-dot FQDN) stay launchable', () {
      // Guard against over-rejection: a host with at least one real label is
      // valid, including the legitimate fully-qualified trailing-dot form and
      // IPv6 literals (which contain no '.'). None may be dropped from the
      // external-browser fallback (no valid target lost, no TLS weakening).
      for (final String uri in <String>[
        'https://bmc.example/console', // normal host
        'https://bmc.example./console', // absolute FQDN trailing dot
        'https://bmc.example:8443/console', // with port
        'https://[::1]:8443/console', // IPv6 literal (no '.')
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: double-encoded authority delimiter rejection',
      () {
    test(
        'a percent-encoded percent in the authority fails closed with a stale flag',
        () {
      // The single-encoded-delimiter rule rejects `%2F`/`%40`/`%2E` in the
      // authority, but a DOUBLE-encoded form bypasses it: `%252F` decodes once
      // to the literal characters `%2F`, which a launcher that decodes twice
      // turns into `/`; `%2540` -> `%40` -> '@'; `%252E` -> `%2E` -> '.'.
      // `Uri.tryParse` keeps `%25` encoded and reports a non-empty HTTPS host,
      // so a purely syntactic re-check calls these "secure". A literal `%` is
      // never valid in a host, and double-decoding is a parser-differential /
      // host-spoofing vector: under a stale secure flag + test opt-in any of
      // these could reach in-app rendering and self-signed acceptance on a
      // spoofed authority. A pct-encoded percent in the authority must fail
      // closed, in either hex case.
      for (final String uri in <String>[
        'https://bmc.example%252Fevil.com/console', // %252F -> %2F -> /
        'https://bmc.example%252fevil.com/console', // lowercase hex
        'https://bmc.example%2540evil.com/console', // %2540 -> %40 -> @
        'https://bmc.example%252Eevil.com/console', // %252E -> %2E -> .
        'https://bmc%252Fexample.com/console', // double-encoded slash mid-host
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

    test(
        'a double-encoded authority delimiter never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a double-encoded
      // authority must not be rendered in-app by an enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%252Fevil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test(
        'encoded percent in path/query and valid pct-encoded hosts stay launchable',
        () {
      // Guard against over-rejection: the rule is scoped to the authority (the
      // TLS-sensitive part). `%25` in the path/query cannot change which host
      // is contacted and stays launchable, as do valid pct-encoded UTF-8 host
      // bytes (`%C3%A9`) that are not an encoded percent — no valid target lost,
      // no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console%252Fone', // %25 in path
        'https://bmc.example/console?q=100%25', // %25 in query
        'https://bmc%C3%A9.example/console', // valid pct-encoded host byte
        'https://bmc.example/caf%C3%A9', // valid pct-encoded path byte
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — defense in depth: encoded authority-dot rejection',
      () {
    test(
        'a single percent-encoded dot in the authority fails closed with a stale flag',
        () {
      // The encoded-delimiter rule blocks gen-delims (`%2F`, `%40`, ...) but
      // not the percent-encoded ASCII domain-label dot (`%2E`). `Uri.tryParse`
      // does NOT keep `%2E` encoded: it decodes it into a literal '.', silently
      // changing the reported host (e.g. `bmc.example%2Eevil.com` -> host
      // `bmc.example.evil.com`). A launcher that does not decode the host
      // percent-encodings resolves a DIFFERENT authority, so the same raw URI
      // can be read as two different hosts — a parser-differential /
      // host-spoofing vector. Under a stale secure flag + test opt-in it could
      // grant in-app rendering and self-signed acceptance on a mismatched
      // host. A percent-encoded dot in the authority must fail closed, in
      // either hex case, including in userinfo and leading/trailing positions.
      for (final String uri in <String>[
        'https://bmc.example%2Eevil.com/console', // %2E mid-host (uppercase)
        'https://bmc.example%2eevil.com/console', // lowercase hex
        'https://bmc%2Eexample/console', // encoded dot inside the host
        'https://%2Eevil.com/console', // leading encoded dot
        'https://bmc.example%2E/console', // trailing encoded dot
        'https://user%2Ename@bmc.example/console', // encoded dot in userinfo
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

    test(
        'a single-encoded authority dot never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, an authority whose host
      // relies on a percent-encoded dot must not be rendered in-app by an
      // enabled+strict opt-in (no TLS weakening, no host-confusion render).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%2Eevil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test(
        'encoded dot in path/query and valid pct-encoded hosts stay launchable (authority-scoped)',
        () {
      // Guard against over-rejection: the rule is scoped to the authority (the
      // TLS-sensitive part). `%2E` in the path/query cannot change which host
      // is contacted and stays launchable, as do valid pct-encoded UTF-8 host
      // bytes (`%C3%A9`, which contain no `%2E`) — no valid target lost.
      for (final String uri in <String>[
        'https://bmc.example/console%2Ehtml', // %2E in path
        'https://bmc.example/console?q=a%2Eb', // %2E in query
        'https://bmc%C3%A9.example/console', // valid pct-encoded host byte
        'https://bmc.example/caf%C3%A9', // valid pct-encoded path byte
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: malformed UTF-8 authority rejection',
      () {
    test(
        'a percent-encoded malformed UTF-8 sequence in the authority fails closed with a stale flag',
        () {
      // The encoded-control-octet rule catches pct-encoded C0/DEL (0x00-0x1F,
      // 0x7F) and the encoded C/Z rule catches *well-formed* multi-byte UTF-8
      // controls, but an INVALID UTF-8 byte sequence slips through both:
      // `utf8.decode(allowMalformed: true)` turns each bad byte into U+FFFD
      // (category So), which neither the C/Z rule nor the confusable set
      // rejects. `Uri.tryParse` keeps such escapes encoded and still reports a
      // non-empty HTTPS host, so a purely syntactic re-check calls them
      // "secure" — yet a launcher that decodes percent-encoded host bytes as
      // Latin-1 (or otherwise does not validate UTF-8) sees different, possibly
      // invisible/control bytes in the host: a lone 0x80/0x9F is a C1 control,
      // `%C0%80` is an overlong NUL, `%E2%82` a truncated sequence. Under a
      // stale secure flag + test opt-in that decode differential could grant
      // in-app rendering and self-signed acceptance on a malformed/spoofed
      // authority. A valid URI percent-encodes well-formed UTF-8 (or ASCII), so
      // rejecting malformed UTF-8 in the authority loses no valid target.
      for (final String uri in <String>[
        'https://bmc.example%80.evil.com/console', // lone C1 control (0x80)
        'https://bmc%9F.example/console', // C1 control (0x9F)
        'https://bmc.example%FF.evil.com/console', // invalid UTF-8 start byte
        'https://bmc.example%C0%80.evil.com/console', // overlong NUL
        'https://bmc.example%E2%82/console', // truncated 3-byte sequence
        'https://bmc.example%80/console', // stray continuation byte in host
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

    test(
        'a malformed UTF-8 authority never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host whose percent
      // escapes are not well-formed UTF-8 must not be rendered in-app by an
      // enabled+strict opt-in.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%80.evil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('well-formed pct-encoded UTF-8 stays launchable (authority-scoped)',
        () {
      // Guard against over-rejection: valid multi-byte UTF-8 — whose trailing
      // continuation bytes (e.g. 0x82 in the euro sign) fall in the 0x80-0xBF
      // range — must stay launchable, including in the authority. Malformed
      // UTF-8 in the path/query cannot change which host is contacted, so it
      // stays launchable too (the rule is scoped to the authority). No valid
      // target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/caf%C3%A9?q=%E2%82%AC', // e-acute + euro (valid)
        'https://bmc%C3%A9.example/console', // valid UTF-8 in authority
        'https://bmc.example/%F0%9F%98%80', // emoji (valid 4-byte)
        'https://bmc.example/console%80', // malformed UTF-8 in path (scoped out)
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: encoded ASCII space in authority rejection',
      () {
    test(
        'a percent-encoded space in the authority fails closed with a stale flag',
        () {
      // The raw-space rule rejects a literal U+0020, and the encoded-control /
      // encoded-C/Z rules reject pct-encoded C0/DEL and non-ASCII separators —
      // but a pct-encoded ASCII space (%20) escapes all three: 0x20 is above
      // the C0/DEL range, it is ASCII (so the non-ASCII C/Z rule skips it), and
      // it contains no raw forbidden character. `Uri.tryParse` keeps %20 encoded
      // and reports a non-empty HTTPS host, so a purely syntactic re-check calls
      // it "secure" — yet a launcher/browser that decodes the host first sees an
      // embedded space, which is a FORBIDDEN domain code point (WHATWG URL /
      // IDNA): the browser rejects or renormalises the host, resolving a
      // different authority than `Uri.tryParse` reported. Under a stale secure
      // flag + test opt-in that parser differential could grant in-app
      // rendering and self-signed acceptance on a malformed/spoofed host. A
      // space is never valid in a host, so every %20 in the authority fails
      // closed — including in userinfo and leading/trailing positions.
      for (final String uri in <String>[
        'https://bmc.example%20.evil.com/console', // %20 mid-host
        'https://bmc%20example/console', // %20 inside a host label
        'https://%20evil.com/console', // leading %20 in host
        'https://bmc.example%20/console', // trailing %20 in host
        'https://user%20name@bmc.example/console', // %20 in userinfo
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

    test(
        'an encoded-space authority never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host whose authority
      // relies on a pct-encoded space must not be rendered in-app by an
      // enabled+strict opt-in (no TLS weakening, no host-confusion render).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc.example%20.evil.com/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('encoded space in path/query stays launchable (authority-scoped)', () {
      // Guard against over-rejection: %20 is the correct encoding of a space
      // and is legitimate in the path/query, where it cannot affect which host
      // is contacted. It must stay launchable via the external-browser
      // fallback, as must valid pct-encoded UTF-8 host bytes — no valid target
      // lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console%20one', // %20 in path
        'https://bmc.example/?q=a%20b', // %20 in query
        'https://bmc%C3%A9.example/console', // valid pct-encoded host byte
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: fullwidth ASCII host confusable rejection',
      () {
    test(
        'a percent-encoded fullwidth ASCII host fails closed with a stale flag',
        () {
      // The compatibility-confusable rule covers code points that NFKC-normalise
      // to an ASCII *structural delimiter*, but a launcher applying IDNA/NFKC to
      // an internationalised host also folds fullwidth letters, digits and
      // punctuation to plain ASCII look-alikes. `Uri.tryParse` keeps each escape
      // encoded and reports a non-empty HTTPS host, so a purely syntactic
      // re-check calls these "secure" — yet a decode+IDNA launcher resolves a
      // DIFFERENT ASCII authority:
      //   `%EF%BD%82%EF%BD%8D%EF%BD%83.example` (fullwidth "bmc") -> bmc.example
      //   `bmc%EF%BC%91%EF%BC%92.example` (fullwidth "12") -> bmc12.example
      // Under a stale secure flag + test opt-in that parser differential could
      // grant in-app rendering and self-signed acceptance on a spoofed host.
      // A real ASCII host is written in ASCII (or punycode), never fullwidth
      // look-alikes, so rejecting them loses no valid target.
      for (final String uri in <String>[
        'https://%EF%BD%82%EF%BD%8D%EF%BD%83.example/console', // ｂｍｃ -> bmc
        'https://bmc%EF%BC%91%EF%BC%92.example/console', // fullwidth 1 2
        'https://bmc%EF%BD%81%EF%BD%82.example/console', // fullwidth a b
        'https://%EF%BC%A2.example/console', // fullwidth capital B
        'https://%ef%bd%82.example/console', // lowercase hex
        'https://%EF%BC%81evil.example/console', // fullwidth ! -> sub-delim
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

    test(
        'a fullwidth-ASCII confusable never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host relying on a
      // fullwidth ASCII look-alike must not be rendered in-app by an
      // enabled+strict opt-in (no TLS weakening, no host-confusion render).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://%EF%BD%82%EF%BD%8D%EF%BD%83.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('fullwidth ASCII confusables outside the authority stay launchable',
        () {
      // Guard against over-rejection: the rule is scoped to the authority (the
      // TLS-sensitive part). A fullwidth look-alike in the path/query cannot
      // change which host is contacted, so it stays launchable via the
      // external-browser fallback. Percent-encoded non-ASCII that NFKC-folds
      // to a non-ASCII character (e-acute) is a legitimate encoded IDN host and
      // stays launchable too — no valid target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console%EF%BD%82one', // fullwidth b in path
        'https://bmc.example/?q=%EF%BC%91', // fullwidth 1 in query
        'https://bmc.example/caf%C3%A9', // e-acute in path (NFKC stays non-ASCII)
        'https://bmc%C3%A9.example/console', // encoded e-acute in authority
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: NFKC-to-ASCII confusable rejection',
      () {
    test(
        'a percent-encoded NFKC-to-ASCII letter host fails closed with a stale flag',
        () {
      // The fullwidth-ASCII rule covers the U+FF01..U+FF5E block and the
      // explicit delimiters, but a launcher applying IDNA/NFKC to an
      // internationalised host ALSO folds other compatibility characters to
      // plain ASCII letters/digits. `Uri.tryParse` keeps each escape encoded
      // and reports a non-empty HTTPS host, so a purely syntactic re-check
      // calls these "secure" — yet a decode+IDNA launcher resolves a DIFFERENT
      // ASCII authority:
      //   `%E2%84%AA` (U+212A KELVIN SIGN)        -> K
      //   `%C5%BF`    (U+017F LATIN SMALL LONG S) -> s
      //   `%E2%92%B6` (U+24B6 CIRCLED LATIN A)    -> A
      //   `%E2%91%A0` (U+2460 CIRCLED DIGIT ONE)  -> 1
      //   `%E2%85%A0` (U+2160 ROMAN NUMERAL ONE)  -> I
      // Under a stale secure flag + test opt-in that parser differential could
      // grant in-app rendering and self-signed acceptance on a spoofed host.
      // A real ASCII host is written in ASCII (or punycode), never with these
      // compatibility look-alikes, so rejecting them loses no valid target.
      for (final String uri in <String>[
        'https://%E2%84%AA.example/console', // KELVIN SIGN -> K
        'https://bmc%C5%BF.example/console', // LONG S -> s
        'https://%E2%92%B6.example/console', // CIRCLED LATIN CAPITAL A -> A
        'https://bmc%E2%93%90.example/console', // CIRCLED LATIN SMALL A -> a
        'https://%E2%91%A0.example/console', // CIRCLED DIGIT ONE -> 1
        'https://bmc%E2%81%B0.example/console', // SUPERSCRIPT ZERO -> 0
        'https://bmc%E2%85%A0.example/console', // ROMAN NUMERAL ONE -> I
        'https://bmc%E2%85%B0.example/console', // SMALL ROMAN NUMERAL ONE -> i
        'https://bmc%F0%9F%84%B0.example/console', // SQUARED LATIN CAP A -> A
        'https://%e2%84%aa.example/console', // lowercase hex
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

    test(
        'an NFKC-to-ASCII confusable never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host relying on a
      // compatibility look-alike must not be rendered in-app by an
      // enabled+strict opt-in (no TLS weakening, no host-confusion render).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://%E2%84%AA.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('NFKC confusables outside the authority stay launchable', () {
      // Guard against over-rejection: the rule is scoped to the authority (the
      // TLS-sensitive part). A compatibility look-alike in the path/query
      // cannot change which host is contacted, so it stays launchable via the
      // external-browser fallback. Percent-encoded non-ASCII that NFKC-folds
      // to a non-ASCII character (e-acute) is a legitimate encoded IDN host and
      // stays launchable too — no valid target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console%E2%84%AA', // Kelvin sign in path
        'https://bmc.example/?q=%E2%85%A0', // Roman numeral in query
        'https://bmc.example/caf%C3%A9', // e-acute in path (NFKC stays non-ASCII)
        'https://bmc%C3%A9.example/console', // encoded e-acute in authority
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: encoded unreserved-ASCII rejection',
      () {
    test(
        'a percent-encoded unreserved ASCII host fails closed with a stale flag',
        () {
      // RFC 3986 unreserved characters (ALPHA / DIGIT / "-" / "." / "_" / "~")
      // never need percent-encoding, so writing one as %XX in the authority is
      // non-canonical and creates a decode-order differential: `Uri.tryParse`
      // DECODES these escapes into a different host string, while a launcher
      // that does not percent-decode the host resolves a DIFFERENT authority.
      //   `%62%6D%63` -> `bmc`, `%2D` -> `-`, `%5F` -> `_`, `%7E` -> `~`.
      // The `%2E` (dot) case is already rejected by a dedicated rule; this
      // closes the rest of the unreserved set. `Uri.tryParse` still reports a
      // non-empty HTTPS host, so a purely syntactic re-check calls these
      // "secure" — under a stale secure flag + test opt-in that parser
      // differential could grant in-app rendering and self-signed acceptance
      // on a mismatched/spoofed authority. A real BMC host writes these
      // characters literally, so rejecting them loses no valid target.
      for (final String uri in <String>[
        'https://%62%6D%63.example/console', // pct-encoded "bmc"
        'https://bmc.example%41/console', // pct-encoded 'A' suffix
        'https://bmc%2Dhost.example/console', // pct-encoded '-'
        'https://bmc%5Fconsole.example/console', // pct-encoded '_'
        'https://bmc%7Eexample.com/console', // pct-encoded '~'
        'https://%42mc.example/console', // uppercase hex digits
        'https://bmc%2dexample.com/console', // lowercase hex for '-'
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

    test(
        'a pct-encoded unreserved ASCII host never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host relying on an
      // encoded unreserved character must not be rendered in-app by an
      // enabled+strict opt-in (no TLS weakening, no host-confusion render).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://%62%6D%63.example/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('encoded unreserved ASCII outside the authority stays launchable', () {
      // Guard against over-rejection: the rule is scoped to the authority (the
      // TLS-sensitive part). Encoded unreserved ASCII in the path/query cannot
      // change which host is contacted, so it stays launchable via the
      // external-browser fallback. Non-ASCII UTF-8 host bytes (`%C3%A9`) are
      // legitimately percent-encoded and stay launchable too, as do literal
      // (raw) unreserved characters and punycode hosts — no valid target lost.
      for (final String uri in <String>[
        'https://bmc.example/console%41', // encoded 'A' in path
        'https://bmc.example/console?a=%7E', // encoded '~' in query
        'https://bmc.example/caf%C3%A9', // encoded non-ASCII in path
        'https://bmc%C3%A9.example/console', // encoded UTF-8 host bytes
        'https://bmc-host_01.example/console', // literal unreserved chars
        'https://xn--bmc-esab.example/console', // punycode host
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: non-canonical numeric-host rejection',
      () {
    test('a non-canonical numeric IP host fails closed with a stale flag', () {
      // A legacy/WHATWG URL parser (browser / WebView) resolves these numeric
      // host forms to an IP literal (often loopback/internal), while Dart's
      // `Uri.tryParse` reports them as opaque DNS names with a non-empty host.
      // Under a stale secure flag + test opt-in that parser differential could
      // grant in-app rendering and self-signed acceptance on a host that
      // resolves somewhere DIFFERENT from the authority Uri reported. A real
      // BMC host is a DNS name or a canonical dotted-quad/IPv6 literal, so
      // rejecting these loses no valid target.
      for (final String uri in <String>[
        'https://0x7f000001/console', // hex integer -> 127.0.0.1
        'https://0X7F000001/console', // uppercase hex prefix/digits
        'https://0x7f.1/console', // mixed hex IP form
        'https://2130706433/console', // bare decimal integer -> 127.0.0.1
        'https://0/console', // single-digit integer -> 0.0.0.0
        'https://127.1/console', // abbreviated dotted decimal -> 127.0.0.1
        'https://127.0.1/console', // 3-part abbreviated form
        'https://0177.0.0.1/console', // leading-zero (octal) -> 127.0.0.1
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

    test(
        'a non-canonical numeric host never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a numeric host that a
      // launcher resolves differently must not be rendered in-app by an
      // enabled+strict opt-in (no host-confusion render, no TLS weakening).
      for (final String uri in <String>[
        'https://0x7f000001/console',
        'https://2130706433/console',
        'https://127.1/console',
        'https://0177.0.0.1/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: const KvmWebViewPolicy(enabled: true),
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('canonical IP and DNS hosts stay launchable (no over-rejection)', () {
      // Guard against over-rejection: a canonical dotted-quad IPv4, an IPv6
      // literal, and ordinary DNS names/punycode are legitimate BMC targets and
      // must still route to the external-browser fallback unchanged.
      for (final String uri in <String>[
        'https://192.168.1.10/console', // canonical dotted-quad IPv4
        'https://10.0.0.1/console',
        'https://127.0.0.1/console',
        'https://0.0.0.0/console',
        'https://[::1]/console', // IPv6 literal
        'https://[fe80::1]/console',
        'https://bmc.example/console', // FQDN
        'https://bmc/console', // single-label DNS name
        'https://bmc2.example.com/console', // letters + digits in a label
        'https://xn--bmc-esab.example/console', // punycode host
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: trailing-dot numeric-host rejection',
      () {
    test('a numeric host with a single trailing dot fails closed with a stale flag',
        () {
      // One trailing dot is normally the legitimate absolute-FQDN form, but a
      // WHATWG/browser parser's "ends in a number" check skips a single trailing
      // dot and then resolves these numeric spellings to an IP literal (often
      // loopback/internal), while Dart's `Uri.tryParse` reports them as opaque
      // DNS names with a non-empty host. Under a stale secure flag + test opt-in
      // that parser differential could grant in-app rendering and self-signed
      // acceptance on a host that resolves somewhere DIFFERENT from the
      // authority Uri reported. A real BMC host is never a trailing-dot numeric
      // spelling, so rejecting these loses no valid target.
      for (final String uri in <String>[
        'https://2130706433./console', // bare decimal integer + trailing dot
        'https://0x7f000001./console', // hex integer + trailing dot
        'https://0X7F000001./console', // uppercase hex + trailing dot
        'https://127.1./console', // abbreviated dotted + trailing dot
        'https://127.0.1./console', // 3-part abbreviated + trailing dot
        'https://0177.0.0.1./console', // leading-zero (octal) + trailing dot
        'https://0./console', // single-digit integer + trailing dot
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

    test(
        'a trailing-dot numeric host never reaches in-app under a strict opt-in',
        () {
      for (final String uri in <String>[
        'https://2130706433./console',
        'https://0x7f000001./console',
        'https://127.1./console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: const KvmWebViewPolicy(enabled: true),
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test(
        'absolute-FQDN and canonical hosts with one trailing dot stay launchable',
        () {
      // Guard against over-rejection: exactly one trailing dot on a real DNS
      // name or canonical dotted-quad IPv4 is the absolute-FQDN form and must
      // stay on the external-browser fallback unchanged.
      for (final String uri in <String>[
        'https://bmc.example./console', // absolute FQDN
        'https://bmc./console', // single-label absolute FQDN
        'https://192.168.1.10./console', // canonical IPv4 + trailing dot
        'https://xn--bmc-esab.example./console', // punycode absolute FQDN
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group('planConsoleLaunch — defense in depth: empty DNS-label rejection', () {
    test('a host with an empty DNS label fails closed with a stale flag', () {
      // A leading dot (`.bmc.example`), consecutive dots (`bmc..example`) or a
      // double trailing dot (`bmc.example..`) leaves an empty DNS label. Such
      // a host is not a real BMC target, and a launcher may normalise/collapse
      // the empty label (or treat it as a relative/traversal reference) so it
      // contacts a DIFFERENT authority than Uri.tryParse reported. Under a
      // stale secure flag + test opt-in that parser differential could grant
      // in-app rendering and self-signed acceptance on a spoofed host. A real
      // BMC host never has an empty label, so rejecting these loses nothing.
      for (final String uri in <String>[
        'https://.bmc.example/console', // leading empty label
        'https://..bmc.example/console', // double leading dot
        'https://bmc..example/console', // consecutive dots / empty label
        'https://bmc.example../console', // double trailing dot
        'https://.bmc/console', // leading dot on a single label
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

    test('an empty-label host never reaches in-app under a strict opt-in', () {
      // Even without granting self-signed acceptance, a host with an empty
      // label must not be rendered in-app by an enabled+strict opt-in (no
      // host-confusion render, no TLS weakening).
      for (final String uri in <String>[
        'https://.bmc.example/console',
        'https://bmc..example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: const KvmWebViewPolicy(enabled: true),
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('single trailing dot and other valid hosts stay launchable', () {
      // Guard against over-rejection: exactly one trailing dot is the legitimate
      // absolute-FQDN form and must stay launchable, as must single-label hosts,
      // canonical IPv4/IPv6 literals, punycode and userinfo authorities — none
      // contain an empty DNS label.
      for (final String uri in <String>[
        'https://bmc.example/console', // plain FQDN
        'https://bmc.example./console', // absolute FQDN: single trailing dot
        'https://bmc/console', // single-label DNS name
        'https://192.168.1.10/console', // canonical dotted-quad IPv4
        'https://[::1]/console', // IPv6 literal
        'https://xn--bmc-esab.example/console', // punycode host
        'https://user@bmc.example/console', // userinfo, no empty label
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
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: NFKC vulgar-fraction confusable rejection',
      () {
    // A percent-encoded "vulgar fraction" (Unicode category No) NFKC-normalises
    // to a decimal digit + U+2044 FRACTION SLASH + a digit (e.g. U+00BD `½` ->
    // `1⁄2`). IDNA/UTS-46 maps U+2044 to the ASCII '/' structural delimiter, so
    // a decode+IDNA launcher resolves a DIFFERENT authority than Uri.tryParse
    // reports (which keeps the escape verbatim in the host). Under a stale
    // secure flag + test opt-in that parser differential could grant in-app
    // rendering and self-signed acceptance on a spoofed/mismatched host.
    test(
        'a percent-encoded vulgar fraction in the authority fails closed with a stale flag',
        () {
      for (final String uri in <String>[
        'https://bmc%C2%BC.example/console', // U+00BC 1/4
        'https://bmc%C2%BD.example/console', // U+00BD 1/2
        'https://bmc%C2%BE.example/console', // U+00BE 3/4
        'https://bmc%E2%85%93.example/console', // U+2153 1/3
        'https://bmc%E2%86%89.example/console', // U+2189 0/3
        'https://bmc%c2%bd.example/console', // lower-case hex escape
        'https://user@bmc%C2%BD.example/console', // fraction in userinfo
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

    test(
        'a vulgar-fraction host never reaches in-app under a strict opt-in or the production default',
        () {
      const String uri = 'https://bmc%C2%BD.example/console';

      final KvmConsoleLaunchPlan strict = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(strict.isInApp, isFalse);
      expect(strict.acceptSelfSigned, isFalse);

      final KvmConsoleLaunchPlan production = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(production.route, KvmConsoleRenderRoute.copyOnly);
      expect(production.isInApp, isFalse);
      expect(production.acceptSelfSigned, isFalse);
    });

    test('legitimate hosts and fractions outside the authority stay launchable',
        () {
      // Guard against over-rejection: the rule is scoped to the authority, so
      // the same escape in path/query/fragment is harmless, and genuinely valid
      // hosts (ASCII, punycode, IPv6, properly encoded non-ASCII UTF-8) must
      // keep working.
      for (final String uri in <String>[
        'https://bmc.example/console', // plain FQDN
        'https://bmc.example/%C2%BD', // fraction in path
        'https://bmc.example/console?q=%C2%BD', // fraction in query
        'https://bmc.example/console#%C2%BD', // fraction in fragment
        'https://xn--bmc-esab.example/console', // punycode
        'https://bmc%C3%A9.example/console', // encoded e-acute (valid UTF-8)
        'https://[::1]/console', // IPv6 literal
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.inAppWebView, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: out-of-range port rejection', () {
    // Uri.tryParse accepts a port above the 16-bit TCP range (e.g. :99999) and
    // still reports an HTTPS URI with a non-empty host, so a purely syntactic
    // re-check calls it "secure". Browser/WebView (WHATWG URL) parsers reject an
    // out-of-range port outright, or wrap it modulo 65536 to a different service
    // — a parser differential that under a stale flag + test opt-in could grant
    // in-app rendering and self-signed acceptance on a malformed/mismatched
    // authority. A real BMC console port is always 0..65535.
    test('an out-of-range port fails closed with a stale flag', () {
      for (final String uri in <String>[
        'https://bmc.example:65536/console', // just past the 16-bit max
        'https://bmc.example:99999/console',
        'https://bmc.example:70000/path?q=1#f',
        'https://user:pass@bmc.example:99999/console', // with userinfo
        'https://[::1]:99999/console', // IPv6 literal host
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

    test(
        'an out-of-range port never reaches in-app under a strict opt-in or the production default',
        () {
      const String uri = 'https://bmc.example:99999/console';

      final KvmConsoleLaunchPlan strict = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(strict.isInApp, isFalse);
      expect(strict.acceptSelfSigned, isFalse);

      final KvmConsoleLaunchPlan production = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(production.route, KvmConsoleRenderRoute.copyOnly);
      expect(production.isInApp, isFalse);
      expect(production.acceptSelfSigned, isFalse);
    });

    test('valid ports and port-less hosts stay launchable (no over-rejection)',
        () {
      // Guard against over-rejection: a default/absent port, a nonstandard but
      // in-range port, the 16-bit maximum, userinfo, IPv6 and punycode hosts
      // must all keep working.
      for (final String uri in <String>[
        'https://bmc.example/console', // default https port
        'https://bmc.example:/console', // empty port -> default
        'https://bmc.example:443/console',
        'https://bmc.example:8443/console', // nonstandard but in range
        'https://bmc.example:65535/console', // max valid port
        'https://user:pass@bmc.example:8443/console',
        'https://[::1]:8443/console', // IPv6 literal
        'https://xn--bmc-esab.example/console', // punycode
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.inAppWebView, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  });

  group(
      'planConsoleLaunch — defense in depth: signed and overflow port rejection',
      () {
    // Uri.tryParse reports a *negative* port (e.g. :-1) as an HTTPS URI with a
    // non-empty host, and silently ignores a signed port (e.g. :+443 reports
    // the default port). Browser/WebView (WHATWG URL) parsers reject a signed
    // or negative port outright — a parser differential that under a stale flag
    // + test opt-in could grant in-app rendering and self-signed acceptance on
    // a malformed authority. A real BMC console port is canonical digits only.
    test('a signed or negative port fails closed with a stale flag', () {
      for (final String uri in <String>[
        'https://bmc.example:-1/console', // negative port (Uri.port == -1)
        'https://bmc.example:+443/console', // signed port (Uri ignores it)
        'https://bmc.example:-443/console',
        'https://user:pass@bmc.example:-1/console', // with userinfo
        'https://[::1]:-1/console', // IPv6 literal host
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

    test(
        'a signed or negative port never reaches in-app under a strict opt-in or the production default',
        () {
      const String uri = 'https://bmc.example:-1/console';

      final KvmConsoleLaunchPlan strict = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(strict.isInApp, isFalse);
      expect(strict.acceptSelfSigned, isFalse);

      final KvmConsoleLaunchPlan production = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(production.route, KvmConsoleRenderRoute.copyOnly);
      expect(production.isInApp, isFalse);
      expect(production.acceptSelfSigned, isFalse);
    });

    test('an overflow port fails closed without throwing', () {
      // Uri.tryParse accepts an arbitrarily long decimal port, but reading
      // Uri.port throws FormatException when the value overflows a 64-bit int.
      // A malformed launch URI must fail closed, never crash the caller.
      for (final String uri in <String>[
        'https://bmc.example:99999999999999999999/console',
        'https://bmc.example:18446744073709551616/console', // 2^64
        'https://user:pass@bmc.example:99999999999999999999/console',
        'https://[::1]:99999999999999999999/console',
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

    test('canonical ports stay launchable (no over-rejection)', () {
      // Guard against over-rejection: an empty port, canonical digits, the
      // 16-bit maximum, and leading-zero ports (which WHATWG URL also parses
      // as the same in-range value) must all keep working.
      for (final String uri in <String>[
        'https://bmc.example:/console', // empty port -> default
        'https://bmc.example:0/console',
        'https://bmc.example:443/console',
        'https://bmc.example:000443/console', // leading zeros -> 443
        'https://bmc.example:65535/console', // max valid port
        'https://user:pass@bmc.example:8443/console',
        'https://[::1]:8443/console', // IPv6 literal
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.inAppWebView, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  });
}
