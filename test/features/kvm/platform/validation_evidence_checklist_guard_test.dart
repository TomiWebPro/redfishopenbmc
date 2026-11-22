// EP-P4 / RP-1 — guard for the detailed per-target validation-evidence
// acceptance checklist in WEBVIEW_TLS_MATRIX.md.
//
// The resolved decision is: production never embeds a WebView, never accepts a
// self-signed certificate, and keeps the external-browser + copy fallback
// byte-for-byte. Flipping the flag, adding a rendering dependency or enabling a
// test-only TLS opt-in is HUMAN-gated on recorded per-target evidence. This
// test pins the *detailed* acceptance checklist (CSP / mixed-content,
// fullscreen, input forwarding, no-native-bridge, no-local-file-access,
// no-device-permissions, no-sensitive-data-at-rest (WebView cache/storage +
// background snapshot), no-referrer/URL-token-leak (Referrer-Policy),
// no-popup/secondary-window/iframe navigation bypass,
// no-private-network/loopback subresource egress (SSRF pivot),
// no-remote-debugging/WebView-inspectability (active debug code),
// no-service-worker/persistent-background-script (session-scoped execution),
// no-js-dialog/modal spoofing (alert/confirm/prompt/beforeunload),
// no-cross-origin-form-submission (form action POST / auto-submit / post body
// exfiltration), no-arbitrary/drive-by file download (APK / executable /
// auto-open / content-disposition), no-cross-site-cookie/session-leak (SameSite /
// third-party-cookie / HttpOnly), no-tapjacking/UI-overlay/clickjacking
// (CWE-1021 obscured-window touch), no-TLS-version/cipher-suite downgrade
// (TLS 1.2+ floor, no weak/export suites, no silent fallback),
// no-cleartext/HTTPS-only platform transport (no cleartextTrafficPermitted,
// no NSAllowsArbitraryLoads; opt-in relaxes leaf trust only, never cleartext),
// no-DNS-rebinding/stale-resolution (connect to the validated origin, TOCTOU-
// free resolution), no-external/attacker-controlled initial console URL (trusted
// entry path, no exported activity / Intent-seeded first load),
// no-sensitive-console-URL/session-token in logs/telemetry/crash reports
// (CWE-532), operator-session auto-lock / session timeout / backgrounding +
// re-auth (no unattended privileged console), no-HTTP-auth / login-form
// credential-prompt spoofing (native authentication-challenge dialog, no
// auto-submitted stored credentials), certificate / public-key pinning (no
// trust-all / accept-any-certificate; opt-in never relaxes the pin),
// TLS protocol-version / cipher-suite floor (hard configuration-independent
// invariant; the test-only opt-in never bypasses the TLS floor), HTTPS-only
// transport (hard configuration-independent invariant; the opt-in never opens a
// cleartext socket), flag-off fallback, human sign-off) so a future edit cannot
// silently erase the evidence boxes that gate that decision.
//
// Deliberately TEST-only, dependency-free, opens no network, grants no human
// approval, imports no plugin, and never touches production TLS (#009/#021).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// The matrix doc that must keep recording the detailed evidence checklist.
const String matrixDocPath = 'lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md';

/// Canonical heading of the detailed acceptance-criteria section.
const String sectionHeading =
    '## validation evidence — detailed acceptance criteria';

/// Lowercase + collapse all whitespace (incl. newlines). Hyphens and the
/// em-dash are kept so markers such as `mixed-content` and the heading match.
String normalize(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Evidence markers that must remain INSIDE the detailed acceptance section.
const List<({String name, String marker})> evidenceChecks =
    <({String name, String marker})>[
  (name: 'heading', marker: sectionHeading),
  (name: 'per-target', marker: 'per target'),
  (name: 'webview-availability', marker: 'webview availability'),
  (name: 'no-production-tls-weakening', marker: 'no production weakening'),
  (name: 'hostname-verification', marker: 'hostname verification'),
  (name: 'certificate-pinning', marker: 'certificate pinning'),
  (name: 'public-key-pinning', marker: 'public-key pinning'),
  (name: 'pin-expected-bmc-identity', marker: 'expected bmc certificate'),
  (name: 'no-trust-all', marker: 'trust-all'),
  (name: 'no-accept-any-cert', marker: 'accept any certificate'),
  (
    name: 'pinning-distinct-from-hostname',
    marker: 'distinct from hostname verification'
  ),
  (name: 'opt-in-keeps-pinning', marker: 'never relax the pin'),
  (
    name: 'origin-navigation-confinement',
    marker: 'origin / navigation confinement'
  ),
  (name: 'no-cross-origin-nav', marker: 'same origin'),
  (name: 'no-nav-downgrade', marker: 'plaintext / non-https scheme'),
  (name: 'no-arbitrary-scheme-nav', marker: 'non-http(s) scheme'),
  (name: 'no-deep-link-nav', marker: 'deep-link'),
  (name: 'no-script-url-nav', marker: 'javascript:'),
  (name: 'no-popup-secondary-window', marker: 'pop-up / secondary window'),
  (name: 'no-multiple-windows', marker: 'multiple windows'),
  (name: 'no-iframe-bypass', marker: 'iframe'),
  (name: 'no-private-network-egress', marker: 'private network'),
  (name: 'no-loopback-egress', marker: 'loopback'),
  (name: 'no-link-local-metadata', marker: 'link-local'),
  (name: 'no-cloud-metadata-endpoint', marker: '169.254.169.254'),
  (name: 'no-webrtc-ip-leak', marker: 'webrtc'),
  (name: 'no-ssrf-pivot', marker: 'ssrf'),
  (name: 'subresource-egress-gate', marker: 'subresource request'),
  (name: 'no-cross-origin-form-submission', marker: 'form submission'),
  (name: 'no-form-action-exfil', marker: 'form action'),
  (name: 'no-form-auto-submit', marker: 'auto-submit'),
  (name: 'no-form-post-body-exfil', marker: 'post body'),
  (name: 'no-cross-site-cookie-leak', marker: 'cross-site cookie'),
  (name: 'samesite-scoping', marker: 'samesite'),
  (name: 'third-party-cookie-blocking', marker: 'third-party cookie'),
  (name: 'secure-httponly-cookie', marker: 'httponly'),
  (name: 'no-cookie-script-read', marker: 'document.cookie'),
  (name: 'no-tapjacking', marker: 'tapjacking'),
  (name: 'no-ui-overlay', marker: 'ui-overlay'),
  (name: 'no-clickjacking', marker: 'clickjacking'),
  (name: 'obscured-window-touch', marker: 'flag_window_is_obscured'),
  (name: 'cwe-1021', marker: 'cwe-1021'),
  (name: 'filter-touches-obscured', marker: 'filtertoucheswhenobscured'),
  (name: 'tls-protocol-floor', marker: 'tls 1.2'),
  (name: 'tls-modern-version', marker: 'tls 1.3'),
  (name: 'no-legacy-tls', marker: 'tls 1.0'),
  (name: 'no-weak-cipher-suite', marker: 'cipher suite'),
  (name: 'no-export-cipher', marker: 'export'),
  (name: 'no-tls-downgrade', marker: 'tls_fallback_scsv'),
  (name: 'opt-in-keeps-tls-floor', marker: 'must never relax'),
  (
    name: 'tls-floor-config-invariant',
    marker: 'configuration-independent invariant'
  ),
  (name: 'tls-floor-never-bypassed', marker: 'never bypasses the tls floor'),
  (name: 'tls-floor-policy-getter', marker: 'bypasstlsprotocolfloor'),
  (
    name: 'cleartext-never-bypassed',
    marker: 'never bypasses the https-only floor'
  ),
  (name: 'cleartext-policy-getter', marker: 'bypasshttpsonlytransport'),
  (name: 'no-cleartext-transport', marker: 'no cleartext'),
  (name: 'https-only-platform', marker: 'https-only transport'),
  (name: 'android-cleartext-permitted', marker: 'cleartexttrafficpermitted'),
  (name: 'android-uses-cleartext', marker: 'usescleartexttraffic'),
  (name: 'ios-ats-no-arbitrary-loads', marker: 'nsallowsarbitraryloads'),
  (
    name: 'no-insecure-load-exception',
    marker: 'nsexceptionallowsinsecurehttploads'
  ),
  (name: 'cleartext-distinct-control-surface', marker: 'control surface'),
  (name: 'cleartext-on-path-observer', marker: 'on-path'),
  (
    name: 'opt-in-no-cleartext-exception',
    marker: 'never add a cleartext exception'
  ),
  (name: 'no-dns-rebinding', marker: 'dns rebinding'),
  (name: 'no-stale-resolution', marker: 'stale-resolution'),
  (name: 'no-re-resolution', marker: 're-resolv'),
  (name: 'validate-at-connect-time', marker: 'connect time'),
  (name: 'toctou-check', marker: 'time-of-check'),
  (name: 'toctou', marker: 'toctou'),
  (name: 'pinned-resolved-address', marker: 'resolved address'),
  (name: 'no-external-initial-url', marker: 'initial console url'),
  (name: 'profile-derived-entry-url', marker: 'user-configured bmc profile'),
  (name: 'no-exported-activity-launch', marker: 'exported activity'),
  (name: 'no-external-intent-seed', marker: 'external intent'),
  (name: 'no-outside-actor-entry', marker: 'outside actor'),
  (name: 'trusted-entry-path', marker: 'trusted entry url'),
  (name: 'no-arbitrary-file-download', marker: 'arbitrary file download'),
  (name: 'no-driveby-download', marker: 'drive-by download'),
  (name: 'no-content-disposition-download', marker: 'content-disposition'),
  (name: 'no-download-listener-open', marker: 'setdownloadlistener'),
  (name: 'no-malicious-apk-executable', marker: 'apk'),
  (name: 'no-auto-open-download', marker: 'auto-open'),
  (name: 'no-remote-debugging', marker: 'remote debugging'),
  (name: 'no-webcontents-debugging', marker: 'webcontentsdebuggingenabled'),
  (name: 'no-webview-inspectable', marker: 'inspectable'),
  (name: 'no-devtools-endpoint', marker: 'devtools'),
  (name: 'no-web-inspector', marker: 'web-inspector'),
  (name: 'no-active-debug-code', marker: 'cwe-489'),
  (name: 'no-service-worker', marker: 'service worker'),
  (name: 'no-sw-register', marker: 'navigator.serviceworker'),
  (name: 'no-bg-sync', marker: 'background sync'),
  (name: 'no-push-subscription', marker: 'push subscription'),
  (name: 'no-cache-storage', marker: 'cache storage'),
  (name: 'session-scoped-execution', marker: 'session-scoped'),
  (name: 'unregister-at-teardown', marker: 'unregister'),
  (
    name: 'no-persistent-background-script',
    marker: 'persistent background script'
  ),
  (name: 'no-js-dialog-spoofing', marker: 'javascript dialog'),
  (name: 'no-js-alert', marker: 'onjsalert'),
  (name: 'no-js-confirm', marker: 'onjsconfirm'),
  (name: 'no-js-prompt', marker: 'onjsprompt'),
  (name: 'no-beforeunload-trap', marker: 'beforeunload'),
  (name: 'js-dialog-ui-spoofing', marker: 'ui-spoofing'),
  (
    name: 'js-dialog-suppressed-or-labelled',
    marker: 'suppressed or clearly attributed'
  ),
  (name: 'test-profile-only-opt-in', marker: 'test-profile-only'),
  (name: 'csp', marker: 'content-security-policy'),
  (name: 'mixed-content', marker: 'mixed-content'),
  (name: 'no-referrer-leak', marker: 'referrer'),
  (name: 'strict-referrer-policy', marker: 'no-referrer'),
  (name: 'no-referrer-token-leak', marker: 'session token'),
  (name: 'fullscreen', marker: 'fullscreen'),
  (name: 'keyboard-input', marker: 'keyboard'),
  (name: 'pointer-input', marker: 'pointer'),
  (name: 'no-native-js-bridge', marker: 'native bridge'),
  (
    name: 'no-local-file-access',
    marker: 'local file / content-provider access'
  ),
  (
    name: 'no-device-permissions',
    marker: 'device-capability / permission access'
  ),
  (name: 'no-geolocation', marker: 'geolocation'),
  (name: 'no-camera-mic', marker: 'camera / microphone'),
  (name: 'permissions-deny-by-default', marker: 'denied by default'),
  (name: 'no-sensitive-data-at-rest', marker: 'data at rest'),
  (name: 'no-webview-cache-storage', marker: 'webview cache'),
  (name: 'no-background-snapshot', marker: 'background snapshot'),
  (name: 'no-sensitive-url-in-logs', marker: 'cwe-532'),
  (name: 'no-logcat-leak', marker: 'logcat'),
  (name: 'no-nslog-leak', marker: 'nslog'),
  (name: 'no-debugprint-leak', marker: 'debugprint'),
  (name: 'no-crash-report-leak', marker: 'crash report'),
  (name: 'no-analytics-token-leak', marker: 'analytics'),
  (name: 'no-telemetry-token-leak', marker: 'telemetry'),
  (name: 'session-timeout', marker: 'session timeout'),
  (name: 'idle-auto-lock', marker: 'auto-lock'),
  (name: 'lock-on-backgrounding', marker: 'backgrounding'),
  (name: 'reauth-on-resume', marker: 're-authentication'),
  (name: 'no-unattended-console', marker: 'unattended'),
  (name: 'no-http-auth-spoof', marker: 'http-auth'),
  (name: 'no-login-form-spoof', marker: 'login-form'),
  (name: 'no-http-auth-callback', marker: 'onreceivedhttpauthrequest'),
  (name: 'no-login-request-callback', marker: 'onreceivedloginrequest'),
  (
    name: 'no-http-auth-stored-credentials',
    marker: 'sethttpauthusernamepassword'
  ),
  (name: 'no-http-auth-webstorage-autocomplete', marker: 'webstorage'),
  (name: 'http-auth-credential-phishing', marker: 'credential-phishing'),
  (name: 'http-auth-auto-answer', marker: 'auto-answered'),
  (name: 'http-auth-distinct-surface', marker: 'authentication-challenge'),
  (name: 'flag-off-fallback', marker: 'flag-off fallback'),
  (name: 'human-sign-off', marker: 'sign-off'),
  (name: 'no-approval-granted', marker: 'no approval'),
];

/// Returns the raw detailed-acceptance section (from its heading to the next
/// heading of the same or higher level), or '' when the heading is absent.
String rawEvidenceSection(String rawMatrix) {
  final int start = rawMatrix.toLowerCase().indexOf(sectionHeading);
  if (start < 0) return '';
  final int bodyStart = start + sectionHeading.length;
  final int next = rawMatrix.substring(bodyStart).indexOf(RegExp(r'\n#{1,2} '));
  final String body = next < 0
      ? rawMatrix.substring(bodyStart)
      : rawMatrix.substring(bodyStart, bodyStart + next);
  return body.trim();
}

/// Rebuilds a matrix doc whose detailed section is replaced by [section].
String matrixWithSection(String realMatrix, String section) {
  final int start = realMatrix.toLowerCase().indexOf(sectionHeading);
  if (start < 0) return realMatrix;
  return '${realMatrix.substring(0, start)}$section\n';
}

/// Returns the NAMES of every missing evidence marker. Empty == green.
List<String> missingEvidenceMarkers(String rawMatrix) {
  final String wholeDoc = normalize(rawMatrix);
  final String section = normalize(rawEvidenceSection(rawMatrix));
  final List<String> missing = <String>[];
  for (final ({String name, String marker}) check in evidenceChecks) {
    // The heading lives in the whole doc; every other marker lives inside the
    // detailed acceptance section.
    final String haystack = check.name == 'heading' ? wholeDoc : section;
    if (!haystack.contains(check.marker)) missing.add(check.name);
  }
  return missing;
}

void main() {
  final String realMatrix = File(matrixDocPath).readAsStringSync();

  group('EP-P4 detailed validation-evidence checklist guard', () {
    test('checklist is non-trivial and the real doc contains its section', () {
      expect(evidenceChecks.length, greaterThanOrEqualTo(12));
      expect(rawEvidenceSection(realMatrix), isNotEmpty);
    });

    test('real matrix records every required evidence box + human sign-off',
        () {
      expect(missingEvidenceMarkers(realMatrix), isEmpty);
    });

    test('RED: removing the detailed section fails closed', () {
      final List<String> missing = missingEvidenceMarkers('');
      expect(missing, isNotEmpty);
      expect(missing, contains('heading'));
      expect(missing, contains('csp'));
      expect(missing, contains('human-sign-off'));
    });

    test('RED: dropping the CSP/mixed-content box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCsp = section
          .split('\n')
          .where((String line) =>
              !line.toLowerCase().contains('content-security-policy'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutCsp);
      expect(missingEvidenceMarkers(neutered), contains('csp'));
    });

    test('RED: dropping the no-referrer/token-leak box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutReferrer = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains('referrer'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutReferrer);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-referrer-leak'));
      expect(missing, contains('strict-referrer-policy'));
      expect(missing, contains('no-referrer-token-leak'));
    });

    test('RED: dropping the hostname-verification box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutHostname = section
          .split('\n')
          .where((String line) =>
              !line.toLowerCase().contains('hostname verification'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutHostname);
      expect(
          missingEvidenceMarkers(neutered), contains('hostname-verification'));
    });

    test('RED: dropping the certificate/public-key-pinning box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPinning = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'certificate pinning|public-key pinning|expected bmc certificate|trust-all|accept any certificate|distinct from hostname verification|never relax the pin')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutPinning);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('certificate-pinning'));
      expect(missing, contains('public-key-pinning'));
      expect(missing, contains('pin-expected-bmc-identity'));
      expect(missing, contains('no-trust-all'));
      expect(missing, contains('no-accept-any-cert'));
      expect(missing, contains('pinning-distinct-from-hostname'));
      expect(missing, contains('opt-in-keeps-pinning'));
    });

    test('RED: dropping the origin/navigation-confinement box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutOrigin = section
          .split('\n')
          .where((String line) =>
              !line.toLowerCase().contains('origin / navigation confinement'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutOrigin);
      expect(missingEvidenceMarkers(neutered),
          contains('origin-navigation-confinement'));
    });

    test('RED: dropping the no-arbitrary-scheme/deep-link box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutScheme = section
          .split('\n')
          .where((String line) =>
              !line.toLowerCase().contains('non-http(s) scheme'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutScheme);
      expect(missingEvidenceMarkers(neutered),
          contains('no-arbitrary-scheme-nav'));
    });

    test('RED: dropping the no-popup/secondary-window/iframe box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPopupBypass = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(
              RegExp(r'pop-up / secondary window|multiple windows|iframe')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutPopupBypass);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-popup-secondary-window'));
      expect(missing, contains('no-multiple-windows'));
      expect(missing, contains('no-iframe-bypass'));
    });

    test(
        'RED: dropping the no-private-network/loopback egress box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutEgress = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'private network|loopback|link-local|169.254.169.254|webrtc|ssrf|subresource request')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutEgress);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-private-network-egress'));
      expect(missing, contains('no-loopback-egress'));
      expect(missing, contains('no-link-local-metadata'));
      expect(missing, contains('no-cloud-metadata-endpoint'));
      expect(missing, contains('no-webrtc-ip-leak'));
      expect(missing, contains('no-ssrf-pivot'));
      expect(missing, contains('subresource-egress-gate'));
    });

    test(
        'RED: dropping the no-remote-debugging/inspectability box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDebug = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'remote debugging|webcontentsdebuggingenabled|inspectable|devtools|web-inspector|cwe-489')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutDebug);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-remote-debugging'));
      expect(missing, contains('no-webcontents-debugging'));
      expect(missing, contains('no-webview-inspectable'));
      expect(missing, contains('no-devtools-endpoint'));
      expect(missing, contains('no-web-inspector'));
      expect(missing, contains('no-active-debug-code'));
    });

    test(
        'RED: dropping the no-service-worker/persistent-background-script box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutServiceWorker = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'service worker|navigator\.serviceworker|background sync|push subscription|cache storage|session-scoped|unregister|persistent background script')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutServiceWorker);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-service-worker'));
      expect(missing, contains('no-sw-register'));
      expect(missing, contains('no-bg-sync'));
      expect(missing, contains('no-push-subscription'));
      expect(missing, contains('no-cache-storage'));
      expect(missing, contains('session-scoped-execution'));
      expect(missing, contains('unregister-at-teardown'));
      expect(missing, contains('no-persistent-background-script'));
    });

    test('RED: dropping the no-js-dialog/modal-spoofing box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutJsDialog = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'javascript dialog|onjsalert|onjsconfirm|onjsprompt|beforeunload|ui-spoofing|suppressed or clearly attributed')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutJsDialog);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-js-dialog-spoofing'));
      expect(missing, contains('no-js-alert'));
      expect(missing, contains('no-js-confirm'));
      expect(missing, contains('no-js-prompt'));
      expect(missing, contains('no-beforeunload-trap'));
      expect(missing, contains('js-dialog-ui-spoofing'));
      expect(missing, contains('js-dialog-suppressed-or-labelled'));
    });

    test('RED: dropping the no-cross-origin-form-submission box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutFormExfil = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(
              RegExp(r'form submission|form action|auto-submit|post body')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutFormExfil);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-cross-origin-form-submission'));
      expect(missing, contains('no-form-action-exfil'));
      expect(missing, contains('no-form-auto-submit'));
      expect(missing, contains('no-form-post-body-exfil'));
    });

    test('RED: dropping the no-arbitrary/drive-by download box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDownload = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'arbitrary file download|drive-by download|content-disposition|setdownloadlistener|apk|auto-open')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutDownload);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-arbitrary-file-download'));
      expect(missing, contains('no-driveby-download'));
      expect(missing, contains('no-content-disposition-download'));
      expect(missing, contains('no-download-listener-open'));
      expect(missing, contains('no-malicious-apk-executable'));
      expect(missing, contains('no-auto-open-download'));
    });

    test('RED: dropping the no-cross-site-cookie/session-leak box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCookieLeak = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'cross-site cookie|samesite|third-party cookie|httponly|document\.cookie')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutCookieLeak);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-cross-site-cookie-leak'));
      expect(missing, contains('samesite-scoping'));
      expect(missing, contains('third-party-cookie-blocking'));
      expect(missing, contains('secure-httponly-cookie'));
      expect(missing, contains('no-cookie-script-read'));
    });

    test(
        'RED: dropping the no-tapjacking/UI-overlay/clickjacking box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutTapjacking = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'tapjacking|ui-overlay|clickjacking|flag_window_is_obscured|cwe-1021|filtertoucheswhenobscured')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutTapjacking);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-tapjacking'));
      expect(missing, contains('no-ui-overlay'));
      expect(missing, contains('no-clickjacking'));
      expect(missing, contains('obscured-window-touch'));
      expect(missing, contains('cwe-1021'));
      expect(missing, contains('filter-touches-obscured'));
    });

    test(
        'RED: dropping the no-TLS-version/cipher-suite downgrade box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutTlsFloor = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'tls 1\.2|tls 1\.3|tls 1\.0|cipher suite|export|tls_fallback_scsv|must never relax')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutTlsFloor);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('tls-protocol-floor'));
      expect(missing, contains('tls-modern-version'));
      expect(missing, contains('no-legacy-tls'));
      expect(missing, contains('no-weak-cipher-suite'));
      expect(missing, contains('no-export-cipher'));
      expect(missing, contains('no-tls-downgrade'));
      expect(missing, contains('opt-in-keeps-tls-floor'));
    });

    test('RED: dropping the TLS-floor hard-invariant box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutTlsFloorInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'configuration-independent invariant|never bypasses the tls floor|bypasstlsprotocolfloor')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutTlsFloorInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('tls-floor-config-invariant'));
      expect(missing, contains('tls-floor-never-bypassed'));
      expect(missing, contains('tls-floor-policy-getter'));
    });

    test('RED: dropping the HTTPS-only hard-invariant box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCleartextInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses the https-only floor|bypasshttpsonlytransport')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutCleartextInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('cleartext-never-bypassed'));
      expect(missing, contains('cleartext-policy-getter'));
    });

    test('RED: dropping the no-cleartext/HTTPS-only transport box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCleartext = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'cleartext|https-only|nsallowsarbitraryloads|nsexceptionallowsinsecurehttploads|on-path|control surface')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutCleartext);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-cleartext-transport'));
      expect(missing, contains('https-only-platform'));
      expect(missing, contains('android-cleartext-permitted'));
      expect(missing, contains('android-uses-cleartext'));
      expect(missing, contains('ios-ats-no-arbitrary-loads'));
      expect(missing, contains('no-insecure-load-exception'));
      expect(missing, contains('cleartext-distinct-control-surface'));
      expect(missing, contains('cleartext-on-path-observer'));
      expect(missing, contains('opt-in-no-cleartext-exception'));
    });

    test('RED: dropping the no-DNS-rebinding/stale-resolution box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutRebinding = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'dns rebinding|stale-resolution|re-resolv|connect time|time-of-check|toctou|resolved address')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutRebinding);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-dns-rebinding'));
      expect(missing, contains('no-stale-resolution'));
      expect(missing, contains('no-re-resolution'));
      expect(missing, contains('validate-at-connect-time'));
      expect(missing, contains('toctou-check'));
      expect(missing, contains('toctou'));
      expect(missing, contains('pinned-resolved-address'));
    });

    test('RED: dropping the trusted-initial-console-URL box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutEntryGate = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'initial console url|user-configured bmc profile|exported activity|external intent|outside actor|trusted entry url')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutEntryGate);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-external-initial-url'));
      expect(missing, contains('profile-derived-entry-url'));
      expect(missing, contains('no-exported-activity-launch'));
      expect(missing, contains('no-external-intent-seed'));
      expect(missing, contains('no-outside-actor-entry'));
      expect(missing, contains('trusted-entry-path'));
    });

    test('RED: dropping the no-native-bridge box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutBridge = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains('native bridge'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutBridge);
      expect(missingEvidenceMarkers(neutered), contains('no-native-js-bridge'));
    });

    test('RED: dropping the no-local-file-access box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutFileAccess = section
          .split('\n')
          .where((String line) =>
              !line.toLowerCase().contains('local file / content-provider'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutFileAccess);
      expect(
          missingEvidenceMarkers(neutered), contains('no-local-file-access'));
    });

    test('RED: dropping the no-device-permissions box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPermissions = section
          .split('\n')
          .where((String line) => !line
              .toLowerCase()
              .contains('device-capability / permission access'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutPermissions);
      expect(
          missingEvidenceMarkers(neutered), contains('no-device-permissions'));
    });

    test('RED: dropping the no-sensitive-data-at-rest box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDataAtRest = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains('data at rest'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutDataAtRest);
      expect(missingEvidenceMarkers(neutered),
          contains('no-sensitive-data-at-rest'));
    });

    test(
        'RED: dropping the no-sensitive-URL-in-logs/telemetry/CWE-532 box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutLogLeak = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'cwe-532|logcat|nslog|debugprint|crash report|analytics|telemetry')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutLogLeak);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-sensitive-url-in-logs'));
      expect(missing, contains('no-logcat-leak'));
      expect(missing, contains('no-nslog-leak'));
      expect(missing, contains('no-debugprint-leak'));
      expect(missing, contains('no-crash-report-leak'));
      expect(missing, contains('no-analytics-token-leak'));
      expect(missing, contains('no-telemetry-token-leak'));
    });

    test(
        'RED: dropping the operator-session auto-lock / session-timeout box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutSessionLock = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'session timeout|auto-lock|backgrounding|re-authentication|unattended')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutSessionLock);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('session-timeout'));
      expect(missing, contains('idle-auto-lock'));
      expect(missing, contains('lock-on-backgrounding'));
      expect(missing, contains('reauth-on-resume'));
      expect(missing, contains('no-unattended-console'));
    });

    test(
        'RED: dropping the no-HTTP-auth / credential-prompt-spoofing box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutHttpAuth = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'http-auth|login-form|onreceivedhttpauthrequest|onreceivedloginrequest|sethttpauthusernamepassword|webstorage|credential-phishing|auto-answered|authentication-challenge')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutHttpAuth);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-http-auth-spoof'));
      expect(missing, contains('no-login-form-spoof'));
      expect(missing, contains('no-http-auth-callback'));
      expect(missing, contains('no-login-request-callback'));
      expect(missing, contains('no-http-auth-stored-credentials'));
      expect(missing, contains('no-http-auth-webstorage-autocomplete'));
      expect(missing, contains('http-auth-credential-phishing'));
      expect(missing, contains('http-auth-auto-answer'));
      expect(missing, contains('http-auth-distinct-surface'));
    });

    test('RED: erasing the human sign-off fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String noSignOff = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains('sign-off'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, noSignOff);
      expect(missingEvidenceMarkers(neutered), contains('human-sign-off'));
    });
  });

  group('EP-P4 evidence checklist grants no approval (production stays safe)',
      () {
    test('productionDefault keeps the flag OFF and TLS strict', () {
      const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;
      expect(production.enabled, isFalse);
      expect(production.tlsMode, KvmWebViewTlsMode.strict);
      expect(production.acceptsSelfSigned, isFalse);
    });
  });
}
