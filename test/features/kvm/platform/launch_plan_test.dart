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
}
