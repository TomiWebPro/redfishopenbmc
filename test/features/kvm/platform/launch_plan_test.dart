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
      'planConsoleLaunch — defense in depth: encoded unwise-char authority rejection',
      () {
    test(
        'a percent-encoded unwise char in the authority fails closed with a stale flag',
        () {
      // Raw RFC-3986 "unwise" ASCII chars (" < > ^ ` { | }) are rejected by the
      // raw-forbidden-char rule, but a pct-encoded one escapes every earlier
      // rule: it is not a gen-delim (so the encoded-delimiter rule misses it),
      // not unreserved/sub-delim, not a C0 control, and is ASCII (so the
      // encoded-C/Z rule skips it). `Uri.tryParse` keeps %XX encoded and reports
      // a non-empty HTTPS host, so a purely syntactic re-check calls it "secure"
      // — yet a launcher/browser that decodes the host first sees a forbidden /
      // non-canonical character and may reject or resolve a different authority,
      // a parser differential that under a stale secure flag + test opt-in could
      // grant in-app rendering and self-signed acceptance on a malformed/spoofed
      // host. A real BMC host never contains these chars, so every encoded form
      // fails closed, including in userinfo and leading/trailing positions.
      for (final String uri in <String>[
        'https://bmc%22example/console', // %22  "
        'https://bmc%3Cexample/console', // %3C  <
        'https://bmc%3Eexample/console', // %3E  >
        'https://bmc%5Eexample/console', // %5E  ^
        'https://bmc%60example/console', // %60  `
        'https://bmc%7Bexample/console', // %7B  {
        'https://bmc%7Cexample/console', // %7C  |
        'https://bmc%7Dexample/console', // %7D  }
        'https://bmc%3cexample/console', // lowercase hex
        'https://bmc%7cexample/console', // lowercase hex
        'https://%3Cevil.com/console', // leading encoded unwise in host
        'https://bmc.example%7C/console', // trailing encoded unwise in host
        'https://user%3Cname@bmc.example/console', // in userinfo
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
        'an encoded-unwise authority never reaches in-app under a strict opt-in',
        () {
      // Even without granting self-signed acceptance, a host whose authority
      // relies on a pct-encoded unwise char must not be rendered in-app by an
      // enabled+strict opt-in (no TLS weakening, no host-confusion render).
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: const KvmWebViewPolicy(enabled: true),
        uri: 'https://bmc%3Cexample/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isFalse);
      expect(plan.acceptSelfSigned, isFalse);
    });

    test('encoded unwise chars in path/query stay launchable (authority-scoped)',
        () {
      // Guard against over-rejection: the unwise chars are forbidden/non-canonical
      // only in a host; in the path/query their %XX forms are legitimate and
      // cannot affect which host is contacted. They must stay launchable via the
      // external-browser fallback, as must valid pct-encoded UTF-8 host bytes —
      // no valid target lost, no TLS weakening.
      for (final String uri in <String>[
        'https://bmc.example/console?q=%3Cscript%3E', // encoded < > in query
        'https://bmc.example/a%7Cb', // encoded | in path
        'https://bmc.example/console?q=%22quoted%22', // encoded " in query
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
    test(
        'a numeric host with a single trailing dot fails closed with a stale flag',
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

  group(
      'planConsoleLaunch — defense in depth: bare hex-prefix host rejection',
      () {
    test('a bare 0x/0X host fails closed with a stale flag', () {
      // A WHATWG/browser URL parser applies its IPv4 "ends in a number" number
      // parser to the label "0x"/"0X": it strips the hex prefix, parses the
      // (empty) remaining hex digits as 0 and resolves the host to 0.0.0.0.
      // Dart's Uri.tryParse instead reports a non-empty opaque host "0x", so a
      // purely syntactic secure re-check calls it "secure" — an authority
      // differential. Under a stale secure flag + test opt-in that differential
      // could grant in-app rendering and self-signed acceptance on a host the
      // browser resolves to the unspecified address. The existing hex-IP rule
      // required label.length > 2, so a bare prefix slipped through.
      for (final String uri in <String>[
        'https://0x/console', // browser -> 0.0.0.0
        'https://0X/console', // uppercase prefix -> 0.0.0.0
        'https://0x./console', // absolute-FQDN spelling -> 0.0.0.0
        'https://0X./console',
        'https://u@0x/console', // userinfo-bearing authority
        'https://0x:443/console', // with an explicit port
        'https://bmc.0x/console', // mixed host with a bare hex final label
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

    test('a bare hex-prefix host never reaches in-app under a strict opt-in', () {
      // Even without granting self-signed acceptance, a host a launcher resolves
      // to a different address must not be rendered in-app (no host confusion).
      for (final String uri in <String>[
        'https://0x/console',
        'https://0X/console',
        'https://0x./console',
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

    test('ordinary hex-looking DNS names stay launchable (no over-rejection)',
        () {
      // Only a label that is exactly a bare hex prefix is rejected. Real DNS
      // names — including ones that merely start with a digit or contain hex
      // letters — a browser resolves to the same authority and stay launchable.
      for (final String uri in <String>[
        'https://0a.example/console',
        'https://hex.example/console',
        'https://x0.example/console',
        'https://bmc0x.example/console',
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
  },
);

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

  group('planConsoleLaunch — defense in depth: out-of-range port rejection',
      () {
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

  group(
      'planConsoleLaunch — defense in depth: encoded sub-delimiter authority rejection',
      () {
    test(
        'a percent-encoded sub-delimiter in the authority fails closed with a stale flag',
        () {
      // RFC 3986 sub-delims (! $ & ' ( ) * + , ; =) are legal unescaped in a
      // reg-name, so a literal form always exists and pct-encoding one is
      // non-canonical. Uri.tryParse keeps %21 in the host (bmc.example%21evil.com)
      // while a decode-first launcher resolves bmc.example!evil.com — one raw
      // URI naming two different hosts. Under a stale secure flag + test opt-in
      // that differential could grant in-app rendering and self-signed
      // acceptance on a mismatched authority. Both hex cases are covered.
      for (final String uri in <String>[
        'https://bmc.example%21evil.com/console', // %21 '!'
        'https://bmc.example%24evil.com/console', // %24 '$'
        'https://bmc.example%26evil.com/console', // %26 '&'
        'https://bmc.example%27evil.com/console', // %27 "'"
        'https://bmc.example%28evil%29.com/console', // %28/%29 '(' ')'
        'https://bmc.example%2Aevil.com/console', // %2A '*'
        'https://bmc.example%2Bevil.com/console', // %2B '+'
        'https://bmc.example%2cevil.com/console', // lowercase %2c ','
        'https://bmc.example%3Bevil.com/console', // %3B ';'
        'https://bmc.example%3Devil.com/console', // %3D '='
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.targetUri, uri, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('an encoded sub-delimiter never reaches in-app under any policy', () {
      for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
        KvmWebViewPolicy.testOptIn,
        KvmWebViewPolicy.productionDefault,
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: policy,
          uri: 'https://bmc.example%21evil.com/console',
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: policy.toString());
        expect(plan.acceptSelfSigned, isFalse, reason: policy.toString());
      }
    });

    test(
        'encoded sub-delims in path/query and UTF-8 host bytes stay launchable',
        () {
      // Guard against over-rejection: the rule is scoped to the authority.
      // Sub-delims percent-encoded in the path/query (their correct encoding),
      // a literal sub-delim in the host (no decode-order differential), and
      // legitimate percent-encoded UTF-8 host bytes (e-acute) stay launchable.
      for (final String uri in <String>[
        'https://bmc.example/console%21one', // %21 in path
        'https://bmc.example/console?q=%26%3D', // sub-delims in query
        'https://bmc.example!evil/console', // raw sub-delim literal (no differential)
        'https://bmc%C3%A9.example/console', // UTF-8 e-acute host byte
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
      'planConsoleLaunch — defense in depth: encoded combining-mark authority rejection',
      () {
    test(
        'a percent-encoded combining mark in the authority fails closed with a stale flag',
        () {
      // A percent-encoded Unicode Mark (category M) is kept encoded by
      // Uri.tryParse, which still reports a "secure" HTTPS host. But a
      // launcher applying NFC/IDNA to the host (as browsers do) recomposes a
      // base letter + combining mark into a DIFFERENT precomposed character
      // (e.g. "e" + U+0301 -> U+00E9), resolving a different authority — one
      // raw URI naming two hosts. Under a stale secure flag + test opt-in that
      // parser differential could grant in-app rendering and self-signed
      // acceptance on a mismatched/spoofed host. Marks are non-canonical in a
      // real BMC authority (hosts are ASCII/punycode), so each fails closed.
      // Both hex cases and marks in userinfo / between labels are covered.
      for (final String uri in <String>[
        'https://bmc%CC%81.example/console', // U+0301 COMBINING ACUTE, upper hex
        'https://bmc%cc%81.example/console', // U+0301, lower hex
        'https://bmc%CC%80.example/console', // U+0300 COMBINING GRAVE
        'https://bmc%CC%88.example/console', // U+0308 COMBINING DIAERESIS
        'https://bmc%CC%A7.example/console', // U+0327 COMBINING CEDILLA
        'https://bmc%E0%A4%BC.example/console', // U+093C DEVANAGARI NUKTA (3-byte Mn)
        'https://bmc.example%CC%81evil.com/console', // mark between labels
        'https://user%CC%81@bmc.example/console', // mark in userinfo
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.targetUri, uri, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('an encoded combining mark never reaches in-app under any policy', () {
      for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
        KvmWebViewPolicy.testOptIn,
        KvmWebViewPolicy.productionDefault,
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: policy,
          uri: 'https://bmc%CC%81.example/console',
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: policy.toString());
        expect(plan.acceptSelfSigned, isFalse, reason: policy.toString());
      }
    });

    test(
        'precomposed UTF-8 host bytes and marks in path/query stay launchable',
        () {
      // Guard against over-rejection: a precomposed e-acute (a Letter, not a
      // Mark) and an emoji (a Symbol) encoded in the authority stay launchable,
      // and marks in the path/query (the wrong place to forge a host) are
      // unaffected — the rule is scoped to the authority.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // precomposed e-acute (Letter)
        'https://bmc%F0%9F%98%80.example/console', // emoji (Symbol)
        'https://bmc.example/console?q=a%CC%81', // mark in query
        'https://bmc.example/caf%C3%A9%CC%81', // mark in path
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

  group('planConsoleLaunch — defense in depth: IPv6 authority rejection', () {
    test('an IPv4-mapped or IPvFuture IPv6 host fails closed with a stale flag',
        () {
      // The non-canonical numeric-host rule skips hosts containing ':', so
      // Uri.tryParse reports these as non-empty HTTPS hosts while a browser /
      // WebView (WHATWG URL) resolves ::ffff:a.b.c.d to an embedded IPv4
      // address or rejects IPvFuture [v...] outright. Under a stale secure flag
      // + test opt-in that parser differential could grant in-app rendering and
      // self-signed acceptance on a malformed/mismatched authority. No real
      // remote BMC uses a mapped or IPvFuture literal, so each fails closed.
      // Dotted and hex embedded-IPv4 spellings are covered.
      for (final String uri in <String>[
        'https://[::ffff:127.0.0.1]/console', // mapped loopback (dotted quad)
        'https://[::ffff:7f00:1]/console', // mapped loopback (hex groups)
        'https://[::ffff:192.168.1.1]/console', // mapped private (dotted quad)
        'https://[::ffff:c0a8:101]/console', // mapped private (hex groups)
        'https://[v1.bmc.example]/console', // IPvFuture (unsupported by WHATWG)
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.targetUri, uri, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('a mapped/IPvFuture IPv6 host never reaches in-app under any policy',
        () {
      for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
        KvmWebViewPolicy.testOptIn,
        KvmWebViewPolicy.productionDefault,
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: policy,
          uri: 'https://[::ffff:127.0.0.1]/console',
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: policy.toString());
        expect(plan.acceptSelfSigned, isFalse, reason: policy.toString());
      }
    });

    test('legitimate IPv6 hosts stay launchable (no over-rejection)', () {
      // Link-local, unique-local, global-unicast/documentation and plain
      // loopback IPv6 literals are real/test-profile BMC targets and must keep
      // working; a valid port and userinfo are unaffected. The rule targets
      // only IPv4-mapped and IPvFuture forms, so no valid target is lost.
      for (final String uri in <String>[
        'https://[fe80::1]/console', // link-local
        'https://[fd00::1]/console', // unique-local
        'https://[2001:db8::1]/console', // global/documentation
        'https://[2001:db8::1]:8443/console', // with explicit port
        'https://user@[fd00::1]/console', // with userinfo
        'https://[::1]/console', // plain loopback: real test-profile target
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

  group('planConsoleLaunch — defense in depth: IPv4-embedded IPv6 rejection', () {
    test('a non-mapped IPv4-embedded IPv6 host fails closed with a stale flag',
        () {
      // The IPv4-mapped rule (groups[5] == 0xffff) only rejects ::ffff:a.b.c.d,
      // but Uri.tryParse reports ANY dotted-quad-embedded IPv6 literal as an
      // opaque, non-empty HTTPS host while a browser / WebView (WHATWG URL)
      // resolves the embedded IPv4 address (or a different IPv6 literal). That
      // is the same parser differential as the mapped form: one raw URI naming
      // two authorities, which under a stale secure flag + test opt-in could
      // grant in-app rendering and self-signed acceptance on a mismatched /
      // internal host. No real remote BMC uses a dotted-quad-embedded IPv6
      // literal, so each fails closed. Dotted mapped/translated forms are
      // included here; the pure-hex mapped form is covered by the IPv6 group.
      for (final String uri in <String>[
        'https://[::192.168.1.1]/console', // IPv4-compatible private
        'https://[::127.0.0.1]/console', // IPv4-compatible loopback
        'https://[2001:db8::192.168.1.1]/console', // embedded in a real prefix
        'https://[::ffff:0:192.168.1.1]/console', // translated mapped form
        'https://[::ffff:127.0.0.1]:8443/console', // dotted mapped + port
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
        expect(plan.targetUri, uri, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('an IPv4-embedded IPv6 host never reaches in-app under any policy', () {
      for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
        KvmWebViewPolicy.testOptIn,
        KvmWebViewPolicy.productionDefault,
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: policy,
          uri: 'https://[::192.168.1.1]/console',
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: policy.toString());
        expect(plan.acceptSelfSigned, isFalse, reason: policy.toString());
      }
    });

    test('pure-hex IPv6 hosts stay launchable (no over-rejection)', () {
      // A real IPv6 literal is written in pure hex groups (no dotted quad).
      // The rule targets only embedded dotted-quad forms, so legitimate
      // link-local / unique-local / global / loopback / pure-hex-mapped hosts
      // and their valid ports/userinfo keep working.
      for (final String uri in <String>[
        'https://[fe80::1]/console',
        'https://[fd00::1]/console',
        'https://[2001:db8::1]/console',
        'https://[2001:db8::1]:8443/console',
        'https://user@[fd00::1]/console',
        'https://[::1]/console',
        'https://[::ffff:7f00:1]/console', // pure-hex mapped: still rejected
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        if (uri.contains('ffff:7f00:1')) {
          expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        } else {
          expect(plan.route, KvmConsoleRenderRoute.externalBrowser, reason: uri);
          expect(plan.targetUri, uri, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      }
    });
  });

  group(
    'planConsoleLaunch — defense in depth: ends-in-number host rejection',
    () {
      test(
          'a mixed host ending in a numeric label fails closed with a stale flag',
          () {
        // WHATWG URL's "ends in a number" check inspects ONLY the last label:
        // `bmc.2130706433` is resolved as an IPv4 literal by browsers/WebViews
        // (or rejected outright when an earlier label is non-numeric), while
        // Uri.tryParse reports it as an opaque, non-empty HTTPS host. The
        // existing all-digit numeric-host rule misses every mixed host. Under a
        // stale secure flag + test opt-in that parser differential could grant
        // in-app rendering and self-signed acceptance on a mismatched/internal
        // host, so each must fail closed.
        for (final String uri in <String>[
          'https://bmc.2130706433/console', // decimal integer as last label
          'https://bmc.127.1/console', // abbreviated dotted tail
          'https://bmc.example.1/console', // single numeric last label
          'https://router.0/console', // numeric zero last label
          'https://bmc.example.0177.0.0.1/console', // leading-zero tail
          'https://bmc.2130706433.:8443/console', // trailing-dot numeric tail
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: KvmWebViewPolicy.testOptIn,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
          expect(plan.targetUri, uri, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      });

      test('an ends-in-number host never reaches in-app under any policy', () {
        for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
          KvmWebViewPolicy.testOptIn,
          KvmWebViewPolicy.productionDefault,
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: policy,
            uri: 'https://bmc.2130706433/console',
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.isInApp, isFalse, reason: policy.toString());
          expect(plan.acceptSelfSigned, isFalse, reason: policy.toString());
        }
      });

      test('legitimate hosts stay launchable (no over-rejection)', () {
        // The rule targets only a purely numeric LAST label. A real BMC host
        // has an alphabetic/punycode final label; numeric leading labels, a
        // canonical dotted-quad IPv4, a real trailing-dot FQDN, an IPv6 literal
        // and a final label that merely ends in digits (not purely numeric) all
        // keep working.
        for (final String uri in <String>[
          'https://bmc.example/console',
          'https://bmc123/console', // single alphabetic-ending label
          'https://123.bmc.example/console', // numeric FIRST label is fine
          'https://bmc.example./console', // absolute FQDN (alpha TLD)
          'https://192.168.1.1/console', // canonical dotted-quad IPv4
          'https://foo.123bar/console', // last label ends in digits, not numeric
          'https://[::1]/console', // IPv6 literal
          'https://xn--fsqu00a.example/console', // punycode host
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: KvmWebViewPolicy.productionDefault,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.externalBrowser,
              reason: uri);
          expect(plan.targetUri, uri, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      });
    },
  );

  group(
    'planConsoleLaunch — defense in depth: mathematical alphanumeric rejection',
    () {
      test(
          'a percent-encoded mathematical alphanumeric host fails closed with a stale flag',
          () {
        // Unicode's Mathematical Alphanumeric Symbols block (U+1D400..U+1D7FF)
        // holds styled (bold/italic/script/fraktur/double-struck/monospace)
        // Latin letters and digits that NFKC-normalise to plain ASCII
        // (e.g. U+1D400 MATHEMATICAL BOLD CAPITAL A -> 'A', U+1D7CE MATHEMATICAL
        // BOLD DIGIT ZERO -> '0'). None are Unicode Separator/Other or marks,
        // and none NFKC-fold to a delimiter or are in the fullwidth/circled/
        // Roman-numeral sets the existing confusable rule knows, so every
        // existing rule misses them: Uri.tryParse keeps the escape encoded and
        // reports a non-empty HTTPS host, while a decode+IDNA launcher resolves
        // a DIFFERENT ASCII authority. Under a stale secure flag + test opt-in
        // that parser differential could grant in-app rendering and self-signed
        // acceptance on a spoofed host, so each must fail closed.
        for (final String uri in <String>[
          'https://%F0%9D%90%80.example/console', // U+1D400 bold A -> A
          'https://bmc%F0%9D%90%82c.example/console', // U+1D402 bold C -> C
          'https://%F0%9D%9F%8E.example/console', // U+1D7CE bold 0 -> 0
          'https://%f0%9d%90%9a.example/console', // U+1D41A bold a, lowercase hex
          'https://%F0%9D%9F%98.example/console', // U+1D7D8 double-struck 0
          'https://%F0%9D%9A%A8.example/console', // U+1D6A8 bold Greek alpha
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: KvmWebViewPolicy.testOptIn,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
          expect(plan.targetUri, uri, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      });

      test('a mathematical alphanumeric host never reaches in-app under any policy',
          () {
        for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
          KvmWebViewPolicy.testOptIn,
          KvmWebViewPolicy.productionDefault,
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: policy,
            uri: 'https://bmc%F0%9D%90%82c.example/console',
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.isInApp, isFalse, reason: policy.toString());
          expect(plan.acceptSelfSigned, isFalse, reason: policy.toString());
        }
      });

      test('legitimate UTF-8 hosts and path escapes stay launchable', () {
        // The rule targets only the Mathematical Alphanumeric Symbols block in
        // the authority. Legitimate pct-encoded UTF-8 host text (e-acute, a
        // Letter; euro, a Symbol), punycode hosts, and the same styled-code-point
        // escapes in the path/query (which cannot forge a host) all keep working.
        for (final String uri in <String>[
          'https://bmc.example/console',
          'https://%C3%A9.example/console', // pct-encoded e-acute host
          'https://%E2%82%AC.example/console', // pct-encoded euro host
          'https://xn--fsqu00a.example/console', // punycode host
          'https://bmc.example/console?x=%F0%9D%90%80', // styled escape in query
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: KvmWebViewPolicy.productionDefault,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.externalBrowser,
              reason: uri);
          expect(plan.targetUri, uri, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      });
    },
  );

  group(
    'planConsoleLaunch — defense in depth: NFKC-to-ASCII compatibility rejection',
    () {
      test(
          'a percent-encoded NFKC-to-ASCII compatibility host fails closed with a stale flag',
          () {
        // Each escape is a NON-ASCII compatibility character whose Unicode
        // NFKC normalisation is plain ASCII, yet it lies outside the hand-
        // maintained fullwidth / circled 1-20 / Roman-numeral / math / vulgar-
        // fraction ranges the earlier confusable rules know. Uri.tryParse keeps
        // the escape encoded (non-empty HTTPS host), so a syntactic re-check
        // calls it "secure", while a browser/WebView applying IDNA/NFKC resolves
        // a DIFFERENT ASCII authority:
        //   %F0%9F%AF%B7 U+1FBF7 SEGMENTED DIGIT SEVEN   -> bmc7.example
        //   %E3%89%91    U+3251  CIRCLED NUMBER TWENTY ONE -> bmc21.example
        //   %EF%AC%81    U+FB01  LATIN SMALL LIGATURE FI    -> bmcfi.example
        //   %CA%B0       U+02B0  MODIFIER LETTER SMALL H    -> bmch.example
        //   %C2%AA       U+00AA  FEMININE ORDINAL INDICATOR -> bmca.example
        //   %E2%84%82    U+2102  DOUBLE-STRUCK CAPITAL C    -> bmcc.example
        // Under a stale secure flag + test opt-in that parser differential
        // could grant in-app rendering and self-signed acceptance on a
        // spoofed/mismatched host, so each must fail closed.
        for (final String uri in <String>[
          'https://bmc%F0%9F%AF%B7.example/console',
          'https://bmc%E3%89%91.example/console',
          'https://bmc%EF%AC%81.example/console',
          'https://bmc%CA%B0.example/console',
          'https://bmc%C2%AA.example/console',
          'https://bmc%E2%84%82.example/console',
          'https://bmc%f0%9f%af%b7.example/console', // lowercase hex
          'https://%C2%AA.example/console', // leading label
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: KvmWebViewPolicy.testOptIn,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
          expect(plan.targetUri, uri, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      });

      test('an NFKC-to-ASCII compatibility host never reaches in-app under any policy',
          () {
        for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
          KvmWebViewPolicy.testOptIn,
          KvmWebViewPolicy.productionDefault,
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: policy,
            uri: 'https://bmc%F0%9F%AF%B7.example/console',
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.isInApp, isFalse, reason: policy.toString());
          expect(plan.acceptSelfSigned, isFalse, reason: policy.toString());
        }
      });

      test('legitimate UTF-8 hosts, punycode and path escapes stay launchable', () {
        // The rule targets only compatibility code points that NFKC-fold to
        // ASCII in the authority. Legitimate pct-encoded UTF-8 host text that
        // folds to NON-ASCII (e-acute, euro, emoji), punycode hosts, and the
        // same escapes in the path/query (which cannot forge a host) keep
        // working — no valid target is lost.
        for (final String uri in <String>[
          'https://bmc.example/console',
          'https://%C3%A9.example/console', // pct-encoded e-acute host
          'https://%E2%82%AC.example/console', // pct-encoded euro host
          'https://%F0%9F%98%80.example/console', // pct-encoded emoji host
          'https://xn--fsqu00a.example/console', // punycode host
          'https://bmc.example/console?x=%F0%9F%AF%B7', // escape in query
        ]) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: KvmWebViewPolicy.productionDefault,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.externalBrowser,
              reason: uri);
          expect(plan.targetUri, uri, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      });
    },
  );

  group(
      'planConsoleLaunch — defense in depth: NFKC mark-introducing authority rejection',
      () {
    // Non-mark code points whose Unicode NFKC normalisation INTRODUCES a
    // combining mark (spacing diacritics, halfwidth sound marks, Indic
    // base+mark compositions, musical symbols, ...). They are not category M
    // (so the encoded-combining-mark rule misses them) and their NFKC is not
    // entirely ASCII (so the compatibility-to-ASCII rule misses them), yet a
    // decode+IDNA launcher recomposes them with a preceding base letter into a
    // DIFFERENT host. The URI reports a non-empty HTTPS host, so under a stale
    // secure flag + test opt-in they could reach in-app rendering and
    // self-signed acceptance on a spoofed authority.
    const List<String> markIntroducingUris = <String>[
      'https://bmce%C2%B4.example/console', // U+00B4 ACUTE ACCENT (Sk)
      'https://bmce%CB%98.example/console', // U+02D8 BREVE (Sk)
      'https://bmce%CE%84.example/console', // U+0384 GREEK TONOS (Sk)
      'https://bmce%EF%BE%9E.example/console', // U+FF9E HALFWIDTH VOICED MARK
      'https://bmce%E0%A5%98.example/console', // U+0958 DEVANAGARI QA (Lo)
      'https://bmce%F0%9D%85%9E.example/console', // U+1D15E MUSICAL SYMBOL
      'https://bmce%E2%80%97.example/console', // U+2017 DOUBLE LOW LINE (Po)
    ];

    test('an NFKC mark-introducing authority never reaches in-app', () {
      for (final String uri in markIntroducingUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an NFKC mark-introducing authority stays off under production', () {
      for (final String uri in markIntroducingUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('legitimate non-ASCII hosts that fold to non-ASCII stay launchable', () {
      // No valid target is lost: pct-encoded UTF-8 host text whose NFKC does
      // NOT introduce a combining mark (e-acute, euro, emoji) keeps working.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // e-acute
        'https://bmc%E2%82%AC.example/console', // euro
        'https://bmc%F0%9F%98%80.example/console', // emoji
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group('planConsoleLaunch — IDNA-ignored Hangul filler authority fails closed', () {
    // U+115F HANGUL CHOSEONG FILLER, U+1160 HANGUL JUNGSEONG FILLER,
    // U+3164 HANGUL FILLER and U+FFA0 HALFWIDTH HANGUL FILLER are category Lo
    // (not C/Z, not a combining mark) and NFKC-normalise to non-ASCII, so they
    // evade every earlier confusable rule. UTS-46 IDNA nevertheless maps each
    // to NOTHING: a decode+IDNA launcher resolves
    // `https://bmc%E3%85%A4.example/` as `bmc.example`, a DIFFERENT authority
    // than Uri.tryParse reports (`bmc%E3%85%A4.example`). Under a stale secure
    // flag + test opt-in that parser differential could grant in-app rendering
    // and self-signed acceptance on a mismatched/spoofed host.
    const List<String> fillerUris = <String>[
      'https://bmc%E1%85%9F.example/console', // U+115F CHOSEONG FILLER
      'https://bmc%E1%85%A0.example/console', // U+1160 JUNGSEONG FILLER
      'https://bmc%E3%85%A4.example/console', // U+3164 HANGUL FILLER
      'https://bmc%EF%BE%A0.example/console', // U+FFA0 HALFWIDTH HANGUL FILLER
    ];

    test('an IDNA-ignored filler authority never reaches in-app', () {
      for (final String uri in fillerUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an IDNA-ignored filler authority stays off under production', () {
      for (final String uri in fillerUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%e3%85%a4.example/console',
        'https://bmc%ef%be%a0.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  },
);

  group('planConsoleLaunch — blank/unusable URI never yields a target', () {
    // KvmConsoleLaunchPlan documents targetUri as null "when there is no
    // usable target". A whitespace-only URI fails closed to the copy-only
    // route, so the copy path must not surface a whitespace string as a
    // target: a launcher/copy action must never be handed a blank target,
    // under any policy (including the test-only opt-in).
    const List<String> blankUris = <String>[
      '   ',
      '\t',
      ' \t\r\n ',
    ];

    for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
      KvmWebViewPolicy.productionDefault,
      KvmWebViewPolicy.testOptIn,
    ]) {
      test('blank URI yields a null target under ${policy.tlsMode}', () {
        for (final String uri in blankUris) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: policy,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
          expect(plan.targetUri, isNull, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      });
    }

    test('an all-invisible Unicode value yields a null target', () {
      // String.trim() strips Unicode whitespace (Zs, incl. NBSP/BOM) but NOT
      // other invisible Unicode Other/format characters (Cf) such as ZWSP,
      // ZWJ and ZWNJ. Such a value is not a launchable URI, yet without an
      // explicit "no usable target" check it survives as a non-null targetUri
      // and a launcher/copy action would surface an invisible string. It must
      // fail closed to null just like whitespace, under every policy.
      const List<String> invisibleUris = <String>[
        '\u200B', // ZERO WIDTH SPACE (Cf)
        '\u200C', // ZERO WIDTH NON-JOINER (Cf)
        '\u200D', // ZERO WIDTH JOINER (Cf)
        '\u2060', // WORD JOINER (Cf)
        '\u200B\u200D', // combined invisible format characters
      ];
      for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
        KvmWebViewPolicy.productionDefault,
        KvmWebViewPolicy.testOptIn,
      ]) {
        for (final String uri in invisibleUris) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: policy,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
          expect(plan.targetUri, isNull, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      }
    });

    test('all default-ignorable (invisible) values yield a null target', () {
      // Unicode Default_Ignorable_Code_Point includes code points OUTSIDE the
      // Separator (Z) / Other (C) categories: variation selectors (Mn,
      // U+FE00..U+FE0F), COMBINING GRAPHEME JOINER (U+034F), the Mongolian free
      // variation selectors (U+180B..U+180D) and the IDNA-ignored Hangul
      // fillers (Lo, U+115F/U+1160/U+3164/U+FFA0). They are invisible, yet the
      // C/Z-only "no usable target" check does not catch them and String.trim()
      // does not strip them (they are not Zs). Without this guard a value made
      // solely of them survives as a non-null copy target and a launcher/copy
      // action would surface an invisible string. Fail closed to null under
      // every policy, exactly like whitespace and ZWSP.
      const List<String> invisibleUris = <String>[
        '\uFE00', // VARIATION SELECTOR-1 (Mn)
        '\uFE0F', // VARIATION SELECTOR-16 (Mn)
        '\u034F', // COMBINING GRAPHEME JOINER (Mn)
        '\u180B', // MONGOLIAN FREE VARIATION SELECTOR ONE (Mn)
        '\u115F', // HANGUL CHOSEONG FILLER (Lo, IDNA-ignored)
        '\u3164', // HANGUL FILLER (Lo, IDNA-ignored)
        '\uFE00\u034F\uFE0F', // combined default-ignorables
      ];
      for (final KvmWebViewPolicy policy in <KvmWebViewPolicy>[
        KvmWebViewPolicy.productionDefault,
        KvmWebViewPolicy.testOptIn,
      ]) {
        for (final String uri in invisibleUris) {
          final KvmConsoleLaunchPlan plan = planConsoleLaunch(
            policy: policy,
            uri: uri,
            hasSecureUri: true,
            isHtml5: true,
            isEnabled: true,
          );

          expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
          expect(plan.targetUri, isNull, reason: uri);
          expect(plan.acceptSelfSigned, isFalse, reason: uri);
        }
      }
    });

    test('a real insecure URI still keeps its copy target', () {
      // Regression guard: only an unusable/blank target is normalised away;
      // a non-blank URI that merely fails the secure check is still handed
      // to the copy path unchanged so the flag-off fallback keeps working.
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'http://bmc.example/console',
        hasSecureUri: false,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.route, KvmConsoleRenderRoute.copyOnly);
      expect(plan.targetUri, 'http://bmc.example/console');
      expect(plan.acceptSelfSigned, isFalse);
    });
  },
);

  group('planConsoleLaunch — NFKC superscript-letter authority fails closed', () {
    // U+2071 SUPERSCRIPT LATIN SMALL LETTER I (category Lm) NFKC-normalises to
    // ASCII 'i', so a decode+IDNA launcher resolves
    // `https://bmc%E2%81%B1.example/console` as `bmci.example` — a DIFFERENT
    // authority than Uri.tryParse reports (`bmc%E2%81%B1.example`). It evades
    // every earlier confusable rule: it is outside the fullwidth block, is not
    // in the delimiter/fraction/mark/C-Z sets, and the neighbouring
    // superscript-digit rule covers U+2070/U+2074..U+2079 but NOT U+2071.
    // Under a stale secure flag + test opt-in that parser differential could
    // grant in-app rendering and self-signed acceptance on a spoofed host.
    const List<String> superscriptIUris = <String>[
      'https://bmc%E2%81%B1.example/console', // U+2071, uppercase hex
      'https://bmc%e2%81%b1.example/console', // lowercase hex
      'https://u%E2%81%B1@bmc.example/console', // in userinfo
    ];

    test('an NFKC superscript-letter authority never reaches in-app', () {
      for (final String uri in superscriptIUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an NFKC superscript-letter authority stays off under production', () {
      for (final String uri in superscriptIUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('legitimate percent-encoded UTF-8 host bytes stay launchable', () {
      // Regression guard: e-acute NFKC-folds to non-ASCII (it is a real letter,
      // not a compatibility look-alike), so it must remain renderable — this
      // rule must reject only code points that fold to plain ASCII.
      const String uri = 'https://bmc%C3%A9.example/console';
      final KvmConsoleLaunchPlan plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.testOptIn,
        uri: uri,
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );

      expect(plan.isInApp, isTrue, reason: uri);
      expect(plan.acceptSelfSigned, isTrue, reason: uri);
      expect(plan.targetUri, uri);
    });
  },
);

  group('planConsoleLaunch — NFKC delimiter-introducing authority fails closed', () {
    // A non-ASCII code point whose NFKC normalisation *introduces* a structural
    // delimiter confusable evades every earlier rule: the decoded code point is
    // not itself a delimiter, is not a Unicode Separator/Other or mark, and its
    // NFKC is non-ASCII (so the complete NFKC-to-ASCII compatibility table does
    // not match it). Yet a launcher applying IDNA/NFKC resolves a DIFFERENT
    // authority than Uri.tryParse reports, which keeps the percent-encoded
    // escape verbatim in a non-empty HTTPS host:
    //  * U+013F / U+0140 (L/l WITH MIDDLE DOT) NFKC -> `L`/`l` + U+00B7 MIDDLE
    //    DOT, which nameprep/IDNA2003 maps to the domain-label dot '.';
    //  * U+33A7 / U+33A8 / U+33AE / U+33AF / U+33C6 / U+33DE / U+33DF
    //    (SQUARE units "M OVER S", "RAD OVER S", "C OVER KG", ...) NFKC embeds
    //    U+2215 DIVISION SLASH, which IDNA maps to '/';
    //  * U+FE12 PRESENTATION FORM FOR VERTICAL IDEOGRAPHIC FULL STOP NFKC ->
    //    U+3002 IDEOGRAPHIC FULL STOP, which IDNA maps to '.' (Node's WHATWG
    //    URL parser rejects the host outright).
    // Under a stale secure flag + test opt-in that parser differential could
    // grant in-app rendering and self-signed acceptance on a spoofed/invalid
    // host. This is the delimiter analogue of the NFKC-mark-introducing rule.
    const List<String> delimiterIntroducingUris = <String>[
      'https://bmc%C4%BF.example/console', // U+013F -> 'L' + U+00B7
      'https://bmc%c4%bf.example/console', // lowercase hex
      'https://bmc%C5%80.example/console', // U+0140 -> 'l' + U+00B7
      'https://bmc%E3%8E%A7.example/console', // U+33A7 -> 'm' + U+2215 + 's'
      'https://bmc%E3%8E%A8.example/console', // U+33A8
      'https://bmc%E3%8E%AE.example/console', // U+33AE
      'https://bmc%E3%8E%AF.example/console', // U+33AF
      'https://bmc%E3%8F%86.example/console', // U+33C6
      'https://bmc%E3%8F%9E.example/console', // U+33DE
      'https://bmc%E3%8F%9F.example/console', // U+33DF
      'https://bmc%EF%B8%92evil.com/console', // U+FE12 -> U+3002
      'https://u%EF%B8%92@bmc.example/console', // U+FE12 in userinfo
    ];

    test('an NFKC delimiter-introducing authority never reaches in-app', () {
      for (final String uri in delimiterIntroducingUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an NFKC delimiter-introducing authority stays off under production', () {
      for (final String uri in delimiterIntroducingUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path stay launchable (authority-scoped)', () {
      const List<String> pathUris = <String>[
        'https://bmc.example/console%EF%B8%92',
        'https://bmc.example/console%E3%8E%A7',
        'https://bmc.example/console%C4%BF',
      ];
      for (final String uri in pathUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
        expect(plan.targetUri, uri, reason: uri);
      }
    });

    test('ordinary percent-encoded UTF-8 host bytes stay launchable', () {
      // Guard against over-rejection: e-acute and euro are real letters/symbols
      // whose NFKC is non-ASCII and introduces no delimiter, so they remain
      // renderable — this rule must reject only delimiter-introducing families.
      const List<String> safeUris = <String>[
        'https://bmc%C3%A9.example/console', // e-acute
        'https://bmc%E2%82%AC.example/console', // euro
      ];
      for (final String uri in safeUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group('planConsoleLaunch — Unicode-17 NFKC ASCII-fold additions fail closed', () {
    // U+A7F1 was UNASSIGNED in Unicode 16.0.0 (the data basis of the
    // NFKC-to-ASCII authority table) and is assigned in Unicode 17.0 as a
    // modifier letter whose NFKC folds to plain ASCII `S`. A launcher applying
    // IDNA/NFKC with Unicode 17 data therefore resolves
    //   https://bmc%EA%9F%B1.example/console  ->  bmcS.example
    // — a DIFFERENT authority than Uri.tryParse reports, which keeps the
    // percent-encoded escape verbatim in a non-empty HTTPS host. The explicit
    // table pin keeps this fail-closed independent of the Dart runtime's
    // Unicode version: on Unicode <=16 the encoded C/Z rule also rejects it
    // (unassigned => category Cn), but on Unicode 17 only the table entry does.
    const List<String> unicode17AsciiFoldUris = <String>[
      'https://bmc%EA%9F%B1.example/console', // U+A7F1 -> ASCII 'S'
      'https://bmc%ea%9f%b1.example/console', // lowercase hex
      'https://u%EA%9F%B1@bmc.example/console', // U+A7F1 in userinfo
    ];

    test('a Unicode-17 NFKC ASCII-fold authority never reaches in-app', () {
      for (final String uri in unicode17AsciiFoldUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('the forward pin also holds under the production default', () {
      for (final String uri in unicode17AsciiFoldUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('ordinary encoded UTF-8 host bytes stay launchable (no over-rejection)',
        () {
      const List<String> safeUris = <String>[
        'https://bmc%C3%A9.example/console', // e-acute (Letter)
        'https://bmc%E2%82%AC.example/console', // euro (Symbol)
      ];
      for (final String uri in safeUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group('planConsoleLaunch — IDNA-disallowed modifier-letter authority fails closed', () {
    // These Modifier-Letter (Lm) code points have a non-ASCII, NFKC-STABLE
    // decomposition (so they evade the C/Z, combining-mark, NFKC-to-ASCII
    // compatibility and mark-introducing rules), yet UTS-46 IDNA disallows
    // them: a browser / WebView (WHATWG URL) REJECTS the host outright while
    // Uri.tryParse reports it as an opaque, non-empty HTTPS host. Under a
    // stale secure flag + test opt-in that parser differential could grant
    // in-app rendering and self-signed acceptance on a host the browser cannot
    // navigate. Verified against Node 24 (WHATWG URL): each throws; against
    // this module before the fix: each passed. U+037A is deliberately absent:
    // it is already rejected by the NFKC mark-introducing rule.
    const List<String> disallowedLmUris = <String>[
      'https://bmc%D9%80.example/console', // U+0640 ARABIC TATWEEL
      'https://bmc%DB%A5.example/console', // U+06E5 ARABIC SMALL WAW + HAMZA
      'https://bmc%DB%A6.example/console', // U+06E6 ARABIC SMALL YEH + HAMZA
      'https://bmc%DF%B4.example/console', // U+07F4 NKO HIGH TONE A
      'https://bmc%DF%B5.example/console', // U+07F5 NKO HIGH TONE AA
      'https://bmc%DF%BA.example/console', // U+07FA NKO LAJANYALAN
      'https://bmc%E0%A0%9A.example/console', // U+081A SAMARITAN MARK IN
      'https://bmc%E0%A0%A4.example/console', // U+0824 SAMARITAN MARK DAGESH
      'https://bmc%E0%A0%A8.example/console', // U+0828 SAMARITAN MARK RAFE
      'https://bmc%F0%9E%A5%8B.example/console', // U+1E94B ADLAM NASALIZATION MARK
    ];

    test('an IDNA-disallowed modifier-letter authority never reaches in-app', () {
      for (final String uri in disallowedLmUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an IDNA-disallowed modifier-letter authority stays off under production',
        () {
      for (final String uri in disallowedLmUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%d9%80.example/console',
        'https://bmc%df%ba.example/console',
        'https://bmc%e0%a0%9a.example/console',
        'https://bmc%f0%9e%a5%8b.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path stay launchable (authority-scoped)', () {
      for (final String uri in <String>[
        'https://bmc.example/%D9%80/console',
        'https://bmc.example/%E0%A0%9A/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('valid non-ASCII IDNA hosts stay launchable (no over-rejection)', () {
      // U+3031 VERTICAL KANA REPEAT MARK is also category Lm but a browser
      // punycodes it (a valid international host), so rejecting *all* Lm would
      // over-reject. Only the IDNA-disallowed set above fails closed.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // e-acute (Letter)
        'https://bmc%E2%82%AC.example/console', // euro (Symbol)
        'https://bmc%E3%80%B1.example/console', // U+3031 vertical kana (valid IDNA)
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group(
      'planConsoleLaunch — IDNA-disallowed ideographic-description authority fails closed',
      () {
    // The Ideographic Description Characters block (U+2FF0..U+2FFB, category
    // So) is DISALLOWED by UTS-46 IDNA: a browser / WebView (WHATWG URL) rejects
    // such a host outright (verified against Node 24: each throws), while
    // Uri.tryParse reports it as an opaque, non-empty HTTPS host. They are not
    // Separator/Other (so the encoded C/Z rule misses them), not marks, and
    // do not NFKC-fold to ASCII, so every earlier authority rule misses them.
    // Under a stale secure flag + test opt-in that parser differential could
    // grant in-app rendering and self-signed acceptance on a host the browser
    // cannot navigate. No real BMC host uses an ideographic description
    // character (hosts are ASCII/punycode), so each fails closed with no valid
    // target lost.
    const List<String> ideographicDescriptionUris = <String>[
      'https://bmc%E2%BF%B0.example/console', // U+2FF0 LEFT TO RIGHT
      'https://bmc%E2%BF%B9.example/console', // U+2FF9 SURROUND FROM UPPER RIGHT
      'https://bmc%E2%BF%BB.example/console', // U+2FFB SURROUND FROM LOWER RIGHT
      'https://u%E2%BF%B0@bmc.example/console', // in userinfo
      'https://bmc%E2%BF%B0.example:8443/console', // with an explicit port
    ];

    test('an ideographic-description authority never reaches in-app', () {
      for (final String uri in ideographicDescriptionUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an ideographic-description authority stays off under production', () {
      for (final String uri in ideographicDescriptionUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%e2%bf%b0.example/console',
        'https://bmc%e2%bf%bb.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path stay launchable (authority-scoped)', () {
      for (final String uri in <String>[
        'https://bmc.example/%E2%BF%B0/console',
        'https://bmc.example/console?q=%E2%BF%BB',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('valid IDNA non-ASCII hosts stay launchable (no over-rejection)', () {
      // Guard: the rule targets only the IDNA-disallowed ideographic-description
      // block in the authority. Real letters/symbols that IDNA accepts (e-acute,
      // euro, emoji) and the same escape in the path keep working.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // e-acute (Letter)
        'https://bmc%E2%82%AC.example/console', // euro (Symbol, IDNA-valid)
        'https://bmc%F0%9F%98%80.example/console', // emoji (Symbol, IDNA-valid)
        'https://xn--bmc-esab.example/console', // punycode host
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group(
      'planConsoleLaunch — Unicode-17 ideographic-description additions fail closed',
      () {
    // The Ideographic Description Characters block was U+2FF0..U+2FFB in
    // Unicode 16.0.0 (covered by the previous group). Unicode 17.0 extended it
    // with U+2FFC SURROUND FROM RIGHT, U+2FFD SURROUND FROM LOWER RIGHT,
    // U+2FFE HORIZONTAL REFLECTION and U+2FFF ROTATION — all NFKC-stable
    // `So` symbols that UTS-46 IDNA disallows, so a browser / WebView (WHATWG
    // URL) rejects such a host outright (verified against Node 24, ICU 78.3 /
    // Unicode 17: all four throw), while Uri.tryParse reports an opaque,
    // non-empty HTTPS host. The hardcoded Unicode-16 `<= 0x2FFB` range let
    // these four slip through: on a Unicode-16 Dart runtime they were caught
    // only incidentally (unassigned => category Cn => encoded C/Z rule), and
    // that incidental cover disappears once the runtime's Unicode data is
    // upgraded to 17.0. Pinning them explicitly keeps fail-closed independent
    // of the Dart runtime's Unicode version (same idiom as the U+A7F1 pin).
    // No real BMC host uses an ideographic description character, so each
    // fails closed with no valid target lost.
    const List<String> unicode17IdeographicDescriptionUris = <String>[
      'https://bmc%E2%BF%BC.example/console', // U+2FFC SURROUND FROM RIGHT
      'https://bmc%E2%BF%BD.example/console', // U+2FFD SURROUND FROM LOWER RIGHT
      'https://bmc%E2%BF%BE.example/console', // U+2FFE HORIZONTAL REFLECTION
      'https://bmc%E2%BF%BF.example/console', // U+2FFF ROTATION
      'https://u%E2%BF%BC@bmc.example/console', // in userinfo
      'https://bmc%E2%BF%BF.example:8443/console', // with an explicit port
    ];

    test('a Unicode-17 ideographic-description authority never reaches in-app',
        () {
      for (final String uri in unicode17IdeographicDescriptionUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('a Unicode-17 ideographic-description authority stays off under production',
        () {
      for (final String uri in unicode17IdeographicDescriptionUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%e2%bf%bc.example/console',
        'https://bmc%e2%bf%bf.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path stay launchable (authority-scoped)', () {
      for (final String uri in <String>[
        'https://bmc.example/%E2%BF%BC/console',
        'https://bmc.example/console?q=%E2%BF%BF',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('valid IDNA non-ASCII hosts stay launchable (no over-rejection)', () {
      // Guard: only the IDNA-disallowed ideographic-description block is
      // rejected. Letters/symbols IDNA punycodes (e-acute, euro, emoji, the
      // vertical kana repeat mark) and a punycode host keep working.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // e-acute (Letter)
        'https://bmc%E2%82%AC.example/console', // euro (Symbol, IDNA-valid)
        'https://bmc%F0%9F%98%80.example/console', // emoji (Symbol, IDNA-valid)
        'https://bmc%E3%80%B1.example/console', // U+3031 vertical kana repeat
        'https://xn--bmc-esab.example/console', // punycode host
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group(
      'planConsoleLaunch — IDNA-disallowed replacement-character authority fails closed',
      () {
    // U+FFFD REPLACEMENT CHARACTER (category So, NFKC-stable) is DISALLOWED
    // by UTS-46 IDNA: it marks the replacement of invalid/unrepresentable
    // input, so a browser / WebView (WHATWG URL + IDNA) REJECTS a host that
    // contains it (verified against Node 24: `domainToASCII` returns the
    // empty string for every authority below). `Uri.tryParse` instead keeps
    // the escape encoded and reports an opaque, non-empty HTTPS host, so a
    // purely syntactic re-check calls it "secure". It evades every earlier
    // authority rule: it is not Separator/Other (encoded C/Z misses it), not
    // a combining mark, does not NFKC-fold to ASCII (the compatibility
    // confusable rules miss it), and — crucially — a VALID `%EF%BF%BD`
    // sequence decodes cleanly, so the malformed-UTF-8 rule misses it too.
    // Under a stale secure flag + test opt-in that parser differential could
    // grant in-app rendering and self-signed acceptance on a host the browser
    // cannot navigate. No real BMC host uses a replacement character, so each
    // fails closed with no valid target lost.
    const List<String> replacementCharacterUris = <String>[
      'https://bmc%EF%BF%BD.example/console', // in a host label
      'https://%EF%BF%BD.example/console', // as the first label
      'https://bmc.example%EF%BF%BD/console', // trailing the host
      'https://u%EF%BF%BD@bmc.example/console', // in userinfo
      'https://bmc%EF%BF%BD.example:8443/console', // with an explicit port
    ];

    test('an IDNA-disallowed replacement-character authority never reaches in-app',
        () {
      for (final String uri in replacementCharacterUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an IDNA-disallowed replacement-character authority stays off under production',
        () {
      for (final String uri in replacementCharacterUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%ef%bf%bd.example/console',
        'https://u%ef%bf%bd@bmc.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path/query stay launchable (authority-scoped)',
        () {
      for (final String uri in <String>[
        'https://bmc.example/%EF%BF%BD/console',
        'https://bmc.example/console?q=%EF%BF%BD',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('valid IDNA non-ASCII hosts stay launchable (no over-rejection)', () {
      // Guard: only the IDNA-disallowed replacement character fails closed.
      // Letters/symbols IDNA punycodes (e-acute, euro, emoji, U+3031) and a
      // punycode host keep working.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // e-acute (Letter)
        'https://bmc%E2%82%AC.example/console', // euro (Symbol, IDNA-valid)
        'https://bmc%F0%9F%98%80.example/console', // emoji (Symbol, IDNA-valid)
        'https://bmc%E3%80%B1.example/console', // U+3031 vertical kana repeat
        'https://xn--bmc-esab.example/console', // punycode host
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group(
      'planConsoleLaunch — IDNA-disallowed object-replacement-character authority fails closed',
      () {
    // U+FFFC OBJECT REPLACEMENT CHARACTER (category So, NFKC-stable,
    // permanently assigned) is DISALLOWED by UTS-46 IDNA just like U+FFFD: it
    // marks an unrepresentable object, so a browser / WebView (WHATWG URL +
    // IDNA) REJECTS a host that contains it (verified against Node 24:
    // `domainToASCII` returns the empty string for every authority below).
    // `Uri.tryParse` instead keeps the escape encoded and reports an opaque,
    // non-empty HTTPS host, so a purely syntactic re-check calls it "secure".
    // It evades every earlier authority rule: category So is not Separator/
    // Other (encoded C/Z misses it), not a combining mark, does not NFKC-fold
    // to ASCII (the compatibility confusable rules miss it), and — crucially —
    // a VALID `%EF%BF%BC` sequence decodes cleanly, so the malformed-UTF-8
    // rule and the U+FFFD-only replacement-character rule both miss it. Under
    // a stale secure flag + test opt-in that parser differential could grant
    // in-app rendering and self-signed acceptance on a host the browser cannot
    // navigate. No real BMC host uses a replacement character, so each fails
    // closed with no valid target lost.
    const List<String> objectReplacementCharacterUris = <String>[
      'https://bmc%EF%BF%BC.example/console', // in a host label
      'https://%EF%BF%BC.example/console', // as the first label
      'https://bmc.example%EF%BF%BC/console', // trailing the host
      'https://u%EF%BF%BC@bmc.example/console', // in userinfo
      'https://bmc%EF%BF%BC.example:8443/console', // with an explicit port
    ];

    test('an IDNA-disallowed object-replacement-character authority never reaches in-app',
        () {
      for (final String uri in objectReplacementCharacterUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an IDNA-disallowed object-replacement-character authority stays off under production',
        () {
      for (final String uri in objectReplacementCharacterUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%ef%bf%bc.example/console',
        'https://u%ef%bf%bc@bmc.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path/query stay launchable (authority-scoped)',
        () {
      for (final String uri in <String>[
        'https://bmc.example/%EF%BF%BC/console',
        'https://bmc.example/console?q=%EF%BF%BC',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('U+FFFD is still rejected alongside U+FFFC', () {
      for (final String uri in <String>[
        'https://bmc%EF%BF%BD.example/console',
        'https://bmc%EF%BF%BC.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });
  },
);

  group('planConsoleLaunch — IDNA bidi mixed-direction authority fails closed',
      () {
    // UTS-46 IDNA applies the Bidi rule (RFC 5893): a label that mixes a
    // right-to-left script letter (Hebrew, Arabic, ...) with a left-to-right
    // letter or with European digits *before* the RTL letter is DISALLOWED.
    // A browser / WebView (WHATWG URL) rejects such a host outright — verified
    // against Node 24: `new URL(uri).hostname` THROWS for every authority below
    // (and `domainToASCII` returns the empty string). `Uri.tryParse` instead
    // keeps the pct-encoded escape and reports an opaque, non-empty HTTPS host,
    // so a purely syntactic re-check calls it "secure". These code points are
    // Unicode letters (category L) that are NFKC-stable and neither Separator/
    // Other nor marks, so every earlier authority rule misses them. Under a
    // stale secure flag + test opt-in that parser differential could grant
    // in-app rendering and self-signed acceptance on a host the browser cannot
    // navigate. No real BMC host mixes scripts in one label, so each fails
    // closed with no valid target lost.
    const List<String> bidiMixedUris = <String>[
      'https://bmc%D7%90.example/console', // Latin + Hebrew alef
      'https://a%D7%90a.example/console', // RTL letter between Latin letters
      'https://bmc%D8%A7.example/console', // Latin + Arabic alef
      'https://123%D7%90.example/console', // European digits then RTL letter
      'https://u%D7%90@bmc.example/console', // in userinfo
      'https://bmc%D7%90.example:8443/console', // with an explicit port
    ];

    test('a mixed-direction authority never reaches in-app', () {
      for (final String uri in bidiMixedUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('a mixed-direction authority stays off under production', () {
      for (final String uri in bidiMixedUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%d7%90.example/console',
        'https://u%d7%90@bmc.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path/query stay launchable (authority-scoped)',
        () {
      for (final String uri in <String>[
        'https://bmc.example/%D7%90/console',
        'https://bmc.example/console?q=%D7%90',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('valid IDNA hosts stay launchable (no over-rejection)', () {
      // Node 24 accepts each of these hosts (`domainToASCII` returns a
      // punycode host): a pure-RTL label, an RTL label with trailing digits,
      // and LTR/non-letter non-ASCII text. The bidi rule must not reject them.
      for (final String uri in <String>[
        'https://%D7%90%D7%91%D7%92.example/console', // pure Hebrew label
        'https://%D7%90%D7%91123.example/console', // Hebrew then digits
        'https://bmc%C3%A9.example/console', // e-acute (LTR letter)
        'https://bmc%E2%82%AC.example/console', // euro (symbol)
        'https://bmc%F0%9F%98%80.example/console', // emoji
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group('planConsoleLaunch — NFKC-stable IDNA-disallowed authority fails closed',
      () {
    // These code points are NFKC-stable (so the NFKC-to-ASCII compatibility
    // rule misses them), are NOT Unicode Separator/Other or marks (so the C/Z
    // and combining-mark rules miss them), and are not a modifier letter,
    // ideographic-description (U+2FF0..U+2FFF), replacement character or bidi
    // mixed-label — yet UTS-46 IDNA disallows them and a browser / WebView
    // rejects a host containing one outright (verified against Node 24:
    // `new URL(uri).hostname` THROWS for every authority below). `Uri.tryParse`
    // instead keeps the pct-encoded escape and reports an opaque, non-empty
    // HTTPS host, so a purely syntactic re-check calls it "secure". Under a
    // stale secure flag + test opt-in that parser differential could grant
    // in-app rendering and self-signed acceptance on a host the browser cannot
    // navigate. No real BMC host uses these scripts (hosts are ASCII or
    // punycode), so each fails closed with no valid target lost.
    const List<String> idnaDisallowedStableUris = <String>[
      'https://bmc%D9%A0.example/console', // U+0660 ARABIC-INDIC DIGIT ZERO
      'https://bmc%D9%A9.example/console', // U+0669 ARABIC-INDIC DIGIT NINE
      'https://bmc%D9%AB.example/console', // U+066B ARABIC DECIMAL SEPARATOR
      'https://bmc%D9%AC.example/console', // U+066C ARABIC THOUSANDS SEPARATOR
      'https://bmc%E3%87%AF.example/console', // U+31EF IDEOGRAPHIC DESCRIPTION CHARACTER SUBTRACTION
      'https://bmc%F0%90%B4%B0.example/console', // U+10D30 HANIFI ROHINGYA DIGIT ZERO
      'https://bmc%F0%90%B4%B9.example/console', // U+10D39 HANIFI ROHINGYA DIGIT NINE
      'https://bmc%F0%90%B9%A0.example/console', // U+10E60 RUMI DIGIT ONE
      'https://bmc%F0%90%B9%BE.example/console', // U+10E7E RUMI FRACTION TWO THIRDS
    ];

    test('an NFKC-stable IDNA-disallowed authority never reaches in-app', () {
      for (final String uri in idnaDisallowedStableUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an NFKC-stable IDNA-disallowed authority stays off under production',
        () {
      for (final String uri in idnaDisallowedStableUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('lowercase hex escapes are rejected too', () {
      for (final String uri in <String>[
        'https://bmc%d9%ab.example/console',
        'https://bmc%e3%87%af.example/console',
        'https://bmc%f0%90%b9%be.example/console',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path/query stay launchable (authority-scoped)',
        () {
      for (final String uri in <String>[
        'https://bmc.example/%D9%AB/console',
        'https://bmc.example/console?q=%F0%90%B9%BE',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('valid IDNA hosts stay launchable (no over-rejection)', () {
      // Node 24 accepts each of these hosts (`domainToASCII` returns a
      // punycode host); none is in the disallowed set.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // e-acute (LTR letter)
        'https://bmc%E2%82%AC.example/console', // euro (symbol)
        'https://bmc%F0%9F%98%80.example/console', // emoji
        'https://xn--bmc-dma.example/console', // ASCII punycode
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group('planConsoleLaunch — IDNA-disallowed stable symbol authority fails closed',
      () {
    // These code points are NFKC-stable (or, for U+FDFA..U+FDFC, NFKC-fold only
    // to non-ASCII text plus an ASCII space), are NOT Unicode Separator/Other or
    // marks (so the C/Z and combining-mark rules miss them), and are not a
    // modifier letter, ideographic description, replacement character, bidi
    // RTL letter or NFKC-to-ASCII confusable — yet UTS-46 IDNA disallows them
    // and a browser / WebView rejects a host containing one outright (verified
    // against Node 24's WHATWG URL / IDNA parser: `new URL(uri).hostname`
    // THROWS for every authority below). `Uri.tryParse` instead keeps the
    // pct-encoded escape and reports an opaque, non-empty HTTPS host, so a
    // purely syntactic re-check calls it "secure". Under a stale secure flag +
    // test opt-in that parser differential could grant in-app rendering and
    // self-signed acceptance on a host the browser cannot navigate. No real
    // BMC host uses these scripts (hosts are ASCII or punycode), so each fails
    // closed with no valid target lost.
    const List<String> idnaDisallowedStableSymbolUris = <String>[
      'https://bmc%D6%BE.example/console', // U+05BE HEBREW MAQAF (Pd)
      'https://bmc%D7%80.example/console', // U+05C0 HEBREW PASEQ (Po)
      'https://bmc%D7%83.example/console', // U+05C3 HEBREW SOF PASUQ (Po)
      'https://bmc%D7%B3.example/console', // U+05F3 HEBREW GERESH (Po)
      'https://bmc%D8%88.example/console', // U+0608 ARABIC RAY (Sm)
      'https://bmc%D8%8B.example/console', // U+060B AFGHANI SIGN (Sc)
      'https://bmc%D8%9B.example/console', // U+061B ARABIC SEMICOLON (Po)
      'https://bmc%D9%AD.example/console', // U+066D ARABIC FIVE POINTED STAR
      'https://bmc%DB%BD.example/console', // U+06FD ARABIC SINDHI AMPERSAND (So)
      'https://bmc%DC%80.example/console', // U+0700 SYRIAC END OF PARAGRAPH
      'https://bmc%DC%8D.example/console', // U+070D SYRIAC HARKLEAN ASTERISCUS
      'https://bmc%DF%80.example/console', // U+07C0 NKO DIGIT ZERO (Nd)
      'https://bmc%DF%BF.example/console', // U+07FF NKO TAMAN SIGN (Sc)
      'https://bmc%E0%A0%B0.example/console', // U+0830 SAMARITAN NEQUDAA
      'https://bmc%E0%A0%BE.example/console', // U+083E SAMARITAN ANNAAU
      'https://bmc%E0%A1%9E.example/console', // U+085E MANDAIC PUNCTUATION
      'https://bmc%EF%AE%B2.example/console', // U+FBB2 ARABIC SYMBOL DOT ABOVE
      'https://bmc%EF%AF%81.example/console', // U+FBC1 ARABIC SYMBOL SMALL TAH
      'https://bmc%EF%B7%BA.example/console', // U+FDFA ARABIC LIGATURE (Lo)
      'https://bmc%EF%B7%BC.example/console', // U+FDFC RIAL SIGN (Sc)
      'https://bmc%F0%90%A1%97.example/console', // U+10857 IMPERIAL ARAMAIC SECTION
      'https://bmc%F0%90%A1%B7.example/console', // U+10877 PALMYRENE FLEURON (So)
      'https://bmc%F0%90%A9%80.example/console', // U+10A40 (No)
      'https://bmc%F0%90%AB%B6.example/console', // U+10AF6 (No)
      'https://bmc%F0%9E%A3%87.example/console', // U+1E8C7 (No)
      'https://bmc%F0%9E%A5%90.example/console', // U+1E950 (No)
      'https://bmc%F0%9E%B1%B1.example/console', // U+1EC71 INDIC SIYAQ NUMBER
      'https://bmc%F0%9E%B4%81.example/console', // U+1ED01 OTTOMAN SIYAQ NUMBER
      'https://bmc%F0%9E%B4%BD.example/console', // U+1ED3D OTTOMAN SIYAQ FRACTION
    ];

    test('an IDNA-disallowed stable-symbol authority never reaches in-app', () {
      for (final String uri in idnaDisallowedStableSymbolUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
        expect(plan.route, KvmConsoleRenderRoute.copyOnly, reason: uri);
      }
    });

    test('an IDNA-disallowed stable-symbol authority stays off under production',
        () {
      for (final String uri in idnaDisallowedStableSymbolUris) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.productionDefault,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the code point is also rejected in userinfo and lowercase hex', () {
      for (final String uri in <String>[
        'https://u%D6%BE@bmc.example/console', // U+05BE in userinfo
        'https://bmc%d6%be.example/console', // lowercase hex
        'https://bmc%f0%9e%b4%bd.example/console', // lowercase hex (SMP)
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isFalse, reason: uri);
        expect(plan.acceptSelfSigned, isFalse, reason: uri);
      }
    });

    test('the same escapes in the path/query stay launchable (authority-scoped)',
        () {
      for (final String uri in <String>[
        'https://bmc.example/%D6%BE/console',
        'https://bmc.example/console?q=%F0%9E%B4%BD',
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });

    test('valid IDNA hosts stay launchable (no over-rejection)', () {
      // Node 24 accepts each of these hosts (`domainToASCII` returns a
      // punycode host); none is in the disallowed set.
      for (final String uri in <String>[
        'https://bmc%C3%A9.example/console', // e-acute (LTR letter)
        'https://bmc%E2%82%AC.example/console', // euro (symbol)
        'https://bmc%F0%9F%98%80.example/console', // emoji
        'https://bmc%E3%80%B1.example/console', // U+3031 vertical kana
        'https://xn--bmc-dma.example/console', // ASCII punycode
      ]) {
        final KvmConsoleLaunchPlan plan = planConsoleLaunch(
          policy: KvmWebViewPolicy.testOptIn,
          uri: uri,
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        );

        expect(plan.isInApp, isTrue, reason: uri);
        expect(plan.acceptSelfSigned, isTrue, reason: uri);
      }
    });
  },
);

  group('allowsInAppNavigation — WebView stays confined to the console origin', () {
    // RP-1: an embedded console WebView must never be navigated by a redirect,
    // a clicked link, window.open or JS away from the BMC console's own origin
    // (a different host/port or a plaintext/non-HTTPS scheme would put an
    // attacker-controlled or downgraded page inside the trusted console frame).
    // The decision fails closed and reuses planConsoleLaunch's validator, so a
    // spoofed/malformed authority can never count as the "same origin".
    const String console = 'https://bmc.example:8443/console';

    test('same-origin navigation (path/query/fragment changes) is allowed', () {
      for (final String target in <String>[
        'https://bmc.example:8443/console',
        'https://bmc.example:8443/console?tab=1',
        'https://bmc.example:8443/other#frag',
        'https://bmc.example:8443/',
      ]) {
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isTrue,
          reason: target,
        );
      }
    });

    test('default and explicit HTTPS port are the same origin', () {
      expect(
          allowsInAppNavigation(
            consoleUri: 'https://bmc.example/console',
            targetUri: 'https://bmc.example:443/console',
          ),
          isTrue);
    });

    test('a different host, port or scheme fails closed', () {
      for (final String target in <String>[
        'https://evil.example:8443/console', // different host
        'https://bmc.example:9443/console', // different port
        'http://bmc.example:8443/console', // TLS downgrade
        'ftp://bmc.example/console', // non-HTTPS scheme
      ]) {
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isFalse,
          reason: target,
        );
      }
    });

    // RP-1: a navigation to a non-HTTP(S) scheme — script/data URLs, app deep
    // links (intent:/market:/custom) and OS schemes (tel:/mailto:) — must fail
    // closed. The WebView's navigation callback may only follow same-origin
    // HTTPS in-app and hand every other scheme to the external browser; passing
    // such a target to another app, the OS, or the page's script context is an
    // app-launch / script-injection abuse surface. The fail-closed secure-target
    // validator already rejects every non-HTTPS scheme; this characterization
    // test pins that invariant behind the WEBVIEW_TLS_MATRIX.md no-arbitrary-
    // scheme / deep-link acceptance box.
    test('a non-HTTP(S) scheme / deep-link target fails closed', () {
      for (final String target in <String>[
        'javascript:alert(1)',
        'data:text/html,<script>alert(1)</script>',
        'blob:https://bmc.example:8443/uuid',
        'intent://bmc.example/#Intent;scheme=https;end',
        'market://details?id=com.example',
        'tel:+15551234567',
        'mailto:admin@bmc.example',
        'myapp://open?url=https://bmc.example:8443/console',
      ]) {
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isFalse,
          reason: target,
        );
      }
    });

    test('a relative, blank or invisible target fails closed', () {
      for (final String? target in <String?>[
        null,
        '',
        '   ',
        '/relative/path',
        '\u200B', // zero-width space
      ]) {
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isFalse,
          reason: 'target=$target',
        );
      }
    });

    test('an insecure or malformed console origin fails closed', () {
      for (final String? badConsole in <String?>[
        null,
        'http://bmc.example/console',
        'https:///console',
        'https://bmc.example%2F.evil/console', // encoded delimiter spoof
      ]) {
        expect(
          allowsInAppNavigation(
            consoleUri: badConsole,
            targetUri: console,
          ),
          isFalse,
          reason: 'console=$badConsole',
        );
      }
    });

    test('a spoofed/malformed authority is never treated as the same origin', () {
      for (final String target in <String>[
        'https://bmc.example:8443%40evil.example/console', // encoded @
        'https://bmc.example:8443%2F.evil.example/console', // encoded /
        'https://bmc.example:8443/console?q=%00', // encoded NUL
      ]) {
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isFalse,
          reason: target,
        );
      }
    });

    test('a valid same-origin IPv6 console navigates within itself', () {
      expect(
        allowsInAppNavigation(
          consoleUri: 'https://[::1]:8443/console',
          targetUri: 'https://[::1]:8443/other',
        ),
        isTrue,
      );
    });

    // RP-1: a navigation must not INTRODUCE embedded credentials into the
    // trusted console frame. A same-origin target carrying userinfo
    // (`https://user:pass@bmc.example/...`) is a login-CSRF / credential-
    // injection and URL-display-confusion vector: the WebView would follow it
    // and dispatch a Basic-auth header with attacker-chosen credentials to the
    // console origin. It is an anomalous navigation, so the guard fails closed
    // (the external-browser + copy fallback still surfaces it with the flag
    // off); the initial credentialed console load is a separate path and is
    // unaffected (planConsoleLaunch still accepts a userinfo URI).
    test('a navigation target carrying userinfo/credentials fails closed', () {
      for (final String target in <String>[
        'https://user@bmc.example:8443/console',
        'https://user:pass@bmc.example:8443/console',
        'https://user:pw@bmc.example:8443/other#frag',
        'https://user@bmc.example:8443/console?tab=1',
      ]) {
        expect(
          allowsInAppNavigation(consoleUri: console, targetUri: target),
          isFalse,
          reason: target,
        );
      }
    });

    test('a credentialed same-origin load is still a valid console plan', () {
      // Guard against over-rejection: the *initial* load may carry userinfo and
      // stays a secure external-browser target under the production default.
      // Only in-session navigation targets are restricted to credential-free.
      final plan = planConsoleLaunch(
        policy: KvmWebViewPolicy.productionDefault,
        uri: 'https://user@bmc.example:8443/console',
        hasSecureUri: true,
        isHtml5: true,
        isEnabled: true,
      );
      expect(plan.isExternalBrowser, isTrue);
    });
  });

}
