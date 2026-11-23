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
// no-service-worker/persistent-background-script (session-scoped execution;
// hard configuration-independent invariant; the opt-in never permits console
// content to register a Service Worker or persistent background script),
// no-js-dialog/modal spoofing (alert/confirm/prompt/beforeunload; hard
// configuration-independent invariant; the opt-in never permits an unlabelled
// JavaScript dialog or a blocking beforeunload for attacker-influenced content),
// no-cross-origin-form-submission (form action POST / auto-submit / post body
// exfiltration), no-arbitrary/drive-by file download (APK / executable /
// auto-open / content-disposition; hard configuration-independent invariant;
// the opt-in never permits a console-controlled download or drive-by install to
// land a runnable file on the device), no-file-chooser/file-upload exfiltration
// (native file picker / <input type=file> local-file selection; hard
// configuration-independent invariant; the opt-in never opens a file chooser
// for attacker-influenced console content), no-cross-site-cookie/session-leak (SameSite /
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
// cleartext socket), certificate revocation checking (CRL / OCSP; opt-in never
// disables revocation, so a revoked BMC certificate cannot resume the session),
// validated-origin binding / no-DNS-rebinding (hard configuration-independent
// invariant; the opt-in never bypasses binding to the validated origin, so the
// console connects only to the address that passed the fail-closed check),
// platform trust-store integrity / no-CA-trust-anchor addition (hard
// configuration-independent invariant; the opt-in never mutates the platform
// trust store, so self-signed acceptance never becomes a global TLS weakening),
// strict Referrer-Policy / no URL-token leakage (hard configuration-independent
// invariant; the opt-in never relaxes the referrer policy, so the console's
// privileged URL / session token is never emitted in a cross-origin Referer
// header), CSP / mixed-content blocking never bypassed (hard configuration-
// independent invariant; the opt-in never relaxes Content-Security-Policy or
// permits an HTTPS console to load cleartext HTTP subresources), sensitive
// console URL / session-token log redaction never bypassed (hard configuration-
// independent invariant; the opt-in never emits the privileged console URL or
// any token derived from it to logs / telemetry / crash reports, CWE-532),
// sensitive data-at-rest protection never bypassed (hard configuration-
// independent invariant; the opt-in never persists console cache/storage or
// exposes an unprotected background snapshot, so the privileged session is not
// left on disk), native bridge isolation never bypassed (hard configuration-
// independent invariant; the opt-in never injects a native JS bridge / message
// handler or exposes an app-controlled window.* object to attacker-influenced
// console content, so no RCE path into the host app is opened), private-network
// / loopback subresource egress protection (no SSRF / link-local-metadata /
// private-LAN pivot; hard configuration-independent invariant; the opt-in never
// lets console subresource requests reach loopback, link-local or private
// addresses other than the approved console origin), cross-site cookie /
// session-token isolation (hard configuration-independent invariant; the opt-in
// never relaxes Secure/HttpOnly/SameSite cookie scoping, never permits
// third-party cookies and never shares the console cookie jar with the system
// browser — no session-theft / account-takeover path), no-remote-debugging /
// WebView-inspectability (hard configuration-independent invariant; the opt-in
// never enables web-contents debugging or exposes a DevTools/inspect endpoint in
// production — no CWE-489 active-debug-code / DOM-and-token-theft path),
// no-dangerous-device-capability / permission access (hard configuration-
// independent invariant; the opt-in never grants geolocation / camera /
// microphone / clipboard / notification / Bluetooth / NFC / download capability
// or auto-answers a permission prompt for attacker-influenced console content),
// no-http-auth / login-form credential-prompt spoofing (hard configuration-
// independent invariant; the opt-in never presents a spoofed native auth prompt
// nor auto-answers an HTTP-auth / login challenge with stored credentials),
// no-local-file / content-provider access (hard configuration-independent
// invariant; the opt-in never enables file:// / content:// local file access),
// no-covert-outbound-egress / cross-origin data-exfiltration (hard
// configuration-independent invariant; the opt-in never relaxes the CSP
// connect-src allowlist, so attacker-influenced console content cannot open a
// programmatic fetch / WebSocket / WebRTC / sendBeacon connection to a
// non-approved origin), no-cross-origin-form-submission (hard configuration-
// independent invariant; the opt-in never permits an HTML form GET/POST,
// auto-submit or scripted form.submit() to send console DOM data / session
// tokens / KVM frames to a non-approved origin), no-certificate-error-blanket-
// acceptance (hard configuration-independent invariant; the WebView's TLS
// certificate-error callback rejects by default on every SSL error — expired,
// untrusted, hostname mismatch, revoked — never a blanket proceed() /
// badCertificateCallback => true that would silently defeat all the other
// certificate checks), no-top-level-navigation-confinement-bypass (hard
// configuration-independent invariant; the WebView's top-level frame must never
// navigate off the approved same-origin HTTPS console to a different origin,
// plaintext page, non-http(s) scheme or spoofed/phishing page — attacker-
// influenced console content cannot redirect the privileged session),
// flag-off fallback, human
// sign-off) so a future edit cannot silently erase the
// evidence boxes that gate that decision.
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
  (
    name: 'form-submission-never-bypassed',
    marker: 'never bypasses cross-origin form submission'
  ),
  (
    name: 'form-submission-policy-getter',
    marker: 'bypasscrossoriginformsubmission'
  ),
  (
    name: 'ssl-error-rejection-never-bypassed',
    marker: 'never bypasses ssl certificate-error rejection'
  ),
  (
    name: 'ssl-error-rejection-policy-getter',
    marker: 'bypasssslerrorrejection'
  ),
  (
    name: 'top-level-navigation-never-bypassed',
    marker: 'never bypasses top-level navigation confinement'
  ),
  (
    name: 'top-level-navigation-policy-getter',
    marker: 'bypasstoplevelnavigationconfinement'
  ),
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
  (
    name: 'tapjacking-never-bypassed',
    marker: 'never bypasses tapjacking / ui-overlay / clickjacking protection'
  ),
  (name: 'tapjacking-policy-getter', marker: 'bypasstapjackingprotection'),
  (
    name: 'tapjacking-distinct-from-js-dialog',
    marker: 'distinct from javascript dialog'
  ),
  (
    name: 'opt-in-keeps-tapjacking-denied',
    marker: 'never accept an obscured-window touch'
  ),
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
  (
    name: 'arbitrary-download-never-bypassed',
    marker: 'never bypasses arbitrary / drive-by file download'
  ),
  (
    name: 'arbitrary-download-policy-getter',
    marker: 'bypassarbitraryfiledownload'
  ),
  (
    name: 'no-autofill-credential-capture',
    marker: 'password-manager credential capture'
  ),
  (name: 'autofill-denied-by-default', marker: 'autofill is denied by default'),
  (name: 'no-autofill-save', marker: 'no password manager saving'),
  (name: 'no-autofill-injection', marker: 'never pre-seed'),
  (
    name: 'autofill-never-bypassed',
    marker: 'never bypasses autofill / password-manager credential capture'
  ),
  (name: 'autofill-policy-getter', marker: 'bypassautofillcredentialcapture'),
  (
    name: 'autofill-distinct-from-http-auth',
    marker: 'distinct from http-auth stored credentials'
  ),
  (
    name: 'opt-in-keeps-autofill-denied',
    marker: 'opt-in never enables autofill'
  ),
  (name: 'no-file-chooser-upload', marker: 'file chooser'),
  (name: 'no-file-input-exfil', marker: 'file input'),
  (name: 'no-native-file-picker', marker: 'onshowfilechooser'),
  (name: 'no-file-upload-exfil', marker: 'file upload'),
  (name: 'file-chooser-never-bypassed', marker: 'never bypasses file chooser'),
  (name: 'file-chooser-policy-getter', marker: 'bypassfilechooseraccess'),
  (
    name: 'file-chooser-distinct-from-local-file',
    marker: 'distinct from local file access'
  ),
  (
    name: 'opt-in-keeps-file-chooser-denied',
    marker: 'never enable the file chooser'
  ),
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
  (
    name: 'js-dialog-never-bypassed',
    marker: 'never bypasses javascript dialog'
  ),
  (name: 'js-dialog-policy-getter', marker: 'bypassjavascriptdialogdenial'),
  (
    name: 'js-dialog-distinct-from-tapjacking',
    marker: 'distinct from tapjacking'
  ),
  (
    name: 'opt-in-keeps-js-dialog-denied',
    marker: 'never allow an unlabelled javascript dialog'
  ),
  (
    name: 'service-worker-never-bypassed',
    marker: 'never bypasses service worker registration'
  ),
  (
    name: 'service-worker-policy-getter',
    marker: 'bypassserviceworkerregistration'
  ),
  (
    name: 'service-worker-distinct-from-debug-and-at-rest',
    marker: 'distinct from webview remote debugging'
  ),
  (
    name: 'opt-in-keeps-service-workers-denied',
    marker: 'never allow a service worker'
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
    name: 'local-file-never-bypassed',
    marker: 'never bypasses local file / content-provider access'
  ),
  (name: 'local-file-policy-getter', marker: 'bypasslocalfileaccess'),
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
  (
    name: 'certificate-revocation-checking',
    marker: 'certificate revocation checking'
  ),
  (name: 'crl-ocsp-revocation', marker: 'crl / ocsp'),
  (name: 'revoked-cert-rejected', marker: 'revoked'),
  (name: 'ssl-error-revoked', marker: 'ssl_error_revoked'),
  (
    name: 'revocation-distinct-from-hostname',
    marker: 'distinct from hostname verification'
  ),
  (name: 'opt-in-keeps-revocation', marker: 'never disable revocation'),
  (name: 'revocation-never-skipped', marker: 'never skips revocation'),
  (
    name: 'revocation-config-invariant',
    marker: 'configuration-independent invariant'
  ),
  (
    name: 'revocation-policy-getter',
    marker: 'bypasscertificaterevocationcheck'
  ),
  (
    name: 'origin-binding-config-invariant',
    marker: 'configuration-independent invariant'
  ),
  (
    name: 'origin-binding-never-bypassed',
    marker: 'never bypasses binding to the validated origin'
  ),
  (
    name: 'origin-binding-policy-getter',
    marker: 'bypassvalidatedoriginbinding'
  ),
  (name: 'trust-store-integrity', marker: 'trust-store integrity'),
  (name: 'no-ca-trust-anchor-addition', marker: 'trust anchor'),
  (name: 'android-user-ca-anchors', marker: 'networksecurityconfig'),
  (name: 'android-keystore-mutation', marker: 'keystore'),
  (name: 'ios-custom-ca-anchor', marker: 'sectrust'),
  (name: 'global-trust-weakening', marker: 'global weakening'),
  (
    name: 'scoped-per-connection-verifier',
    marker: 'per-connection certificate'
  ),
  (
    name: 'trust-store-never-mutated',
    marker: 'never mutates the platform trust store'
  ),
  (
    name: 'trust-store-config-invariant',
    marker: 'configuration-independent invariant'
  ),
  (
    name: 'trust-store-policy-getter',
    marker: 'bypassplatformtruststoreintegrity'
  ),
  (name: 'client-cert-validation', marker: 'client-certificate validation'),
  (name: 'mutual-tls-client-cert', marker: 'mutual tls'),
  (
    name: 'client-private-key-protection',
    marker: 'private key must remain protected'
  ),
  (
    name: 'opt-in-keeps-client-cert',
    marker: 'never disable client-certificate validation'
  ),
  (
    name: 'client-cert-config-invariant',
    marker: 'configuration-independent invariant'
  ),
  (
    name: 'client-cert-policy-getter',
    marker: 'bypassclientcertificatevalidation'
  ),
  (
    name: 'referrer-never-bypassed',
    marker: 'never bypasses the strict referrer policy'
  ),
  (name: 'referrer-policy-getter', marker: 'bypassstrictreferrerpolicy'),
  (
    name: 'mixed-content-never-bypassed',
    marker: 'never bypasses mixed-content blocking'
  ),
  (name: 'mixed-content-policy-getter', marker: 'bypassmixedcontentblocking'),
  (
    name: 'log-redaction-never-bypassed',
    marker: 'never bypasses sensitive console url / session-token log redaction'
  ),
  (name: 'log-redaction-policy-getter', marker: 'bypasslogredaction'),
  (
    name: 'data-at-rest-never-bypassed',
    marker: 'never bypasses sensitive data at rest protection'
  ),
  (
    name: 'data-at-rest-policy-getter',
    marker: 'bypasssensitivedataatrestprotection'
  ),
  (
    name: 'native-bridge-never-bypassed',
    marker: 'never bypasses native bridge isolation'
  ),
  (name: 'native-bridge-policy-getter', marker: 'bypassnativebridgeisolation'),
  (
    name: 'private-egress-never-bypassed',
    marker: 'never bypasses private-network egress protection'
  ),
  (
    name: 'private-egress-policy-getter',
    marker: 'bypassprivatenetworkegressprotection'
  ),
  (
    name: 'cookie-never-bypassed',
    marker: 'never bypasses cross-site cookie / session-token isolation'
  ),
  (name: 'cookie-policy-getter', marker: 'bypasscookieisolation'),
  (
    name: 'remote-debugging-never-bypassed',
    marker: 'never bypasses webview remote debugging'
  ),
  (
    name: 'remote-debugging-policy-getter',
    marker: 'bypasswebviewremotedebugging'
  ),
  (
    name: 'device-permissions-never-bypassed',
    marker: 'never bypasses device-capability / permission access'
  ),
  (
    name: 'device-permissions-policy-getter',
    marker: 'bypassdevicepermissioncontrols'
  ),
  (
    name: 'http-auth-never-bypassed',
    marker: 'never bypasses http-auth / login-form challenge denial'
  ),
  (name: 'http-auth-policy-getter', marker: 'bypasshttpauthchallengedenial'),
  (name: 'no-covert-outbound-egress', marker: 'covert outbound egress'),
  (name: 'connect-src-allowlist', marker: 'connect-src'),
  (name: 'no-cross-origin-exfil', marker: 'cross-origin data exfiltration'),
  (name: 'no-websocket-beacon-exfil', marker: 'sendbeacon'),
  (
    name: 'outbound-egress-never-bypassed',
    marker: 'never bypasses the outbound egress allowlist'
  ),
  (
    name: 'outbound-egress-policy-getter',
    marker: 'bypassoutboundegressallowlist'
  ),
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

    test(
        'RED: dropping the cross-origin form-submission hard-invariant box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutFormInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses cross-origin form submission|bypasscrossoriginformsubmission')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutFormInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('form-submission-never-bypassed'));
      expect(missing, contains('form-submission-policy-getter'));
    });

    test(
        'RED: dropping the certificate-error rejection hard-invariant box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutSslError = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses ssl certificate-error rejection|bypasssslerrorrejection')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutSslError);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('ssl-error-rejection-never-bypassed'));
      expect(missing, contains('ssl-error-rejection-policy-getter'));
    });

    test(
        'RED: dropping the top-level navigation confinement hard-invariant '
        'box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutNav = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses top-level navigation confinement|bypasstoplevelnavigationconfinement')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutNav);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('top-level-navigation-never-bypassed'));
      expect(missing, contains('top-level-navigation-policy-getter'));
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

    test(
        'RED: dropping the arbitrary-download hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDownloadInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses arbitrary / drive-by file download|bypassarbitraryfiledownload')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutDownloadInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('arbitrary-download-never-bypassed'));
      expect(missing, contains('arbitrary-download-policy-getter'));
    });

    test('RED: dropping the no-autofill/password-manager box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutAutofill = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'password-manager credential capture|autofill is denied by default|no password manager saving|never pre-seed')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutAutofill);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-autofill-credential-capture'));
      expect(missing, contains('autofill-denied-by-default'));
      expect(missing, contains('no-autofill-save'));
      expect(missing, contains('no-autofill-injection'));
    });

    test('RED: dropping the autofill-capture hard-invariant box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutAutofillInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses autofill / password-manager credential capture|bypassautofillcredentialcapture')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutAutofillInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('autofill-never-bypassed'));
      expect(missing, contains('autofill-policy-getter'));
    });

    test('RED: dropping the autofill distinctness / opt-in box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutAutofillDistinct = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'distinct from http-auth stored credentials|opt-in never enables autofill')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutAutofillDistinct);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('autofill-distinct-from-http-auth'));
      expect(missing, contains('opt-in-keeps-autofill-denied'));
    });

    test('RED: dropping the no-file-chooser/upload box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutFileChooser = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'file chooser|file input|onshowfilechooser|file upload|never bypasses file chooser|bypassfilechooseraccess|distinct from local file access|never enable the file chooser')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutFileChooser);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-file-chooser-upload'));
      expect(missing, contains('no-file-input-exfil'));
      expect(missing, contains('no-native-file-picker'));
      expect(missing, contains('no-file-upload-exfil'));
      expect(missing, contains('file-chooser-never-bypassed'));
      expect(missing, contains('file-chooser-policy-getter'));
      expect(missing, contains('file-chooser-distinct-from-local-file'));
      expect(missing, contains('opt-in-keeps-file-chooser-denied'));
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

    test('RED: dropping the tapjacking hard-invariant box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutTapjackingInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses tapjacking|bypasstapjackingprotection|distinct from javascript dialog|never accept an obscured-window touch')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutTapjackingInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('tapjacking-never-bypassed'));
      expect(missing, contains('tapjacking-policy-getter'));
      expect(missing, contains('tapjacking-distinct-from-js-dialog'));
      expect(missing, contains('opt-in-keeps-tapjacking-denied'));
    });

    test('RED: dropping the no-JavaScript-dialog hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutJsDialogInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses javascript dialog|bypassjavascriptdialogdenial|distinct from tapjacking|never allow an unlabelled javascript dialog')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutJsDialogInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('js-dialog-never-bypassed'));
      expect(missing, contains('js-dialog-policy-getter'));
      expect(missing, contains('js-dialog-distinct-from-tapjacking'));
      expect(missing, contains('opt-in-keeps-js-dialog-denied'));
    });

    test('RED: dropping the no-service-worker hard-invariant box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutServiceWorkerInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses service worker registration|bypassserviceworkerregistration|distinct from webview remote debugging|never allow a service worker')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutServiceWorkerInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('service-worker-never-bypassed'));
      expect(missing, contains('service-worker-policy-getter'));
      expect(missing, contains('service-worker-distinct-from-debug-and-at-rest'));
      expect(missing, contains('opt-in-keeps-service-workers-denied'));
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

    test(
        'RED: dropping the no-local-file-access hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutLocalFile = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses local file / content-provider access|bypasslocalfileaccess')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutLocalFile);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('local-file-never-bypassed'));
      expect(missing, contains('local-file-policy-getter'));
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

    test('RED: dropping the certificate-revocation-checking box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutRevocation = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'certificate revocation checking|crl / ocsp|revoked|ssl_error_revoked|never disable revocation|never skips revocation|bypasscertificaterevocationcheck')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutRevocation);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('certificate-revocation-checking'));
      expect(missing, contains('crl-ocsp-revocation'));
      expect(missing, contains('revoked-cert-rejected'));
      expect(missing, contains('ssl-error-revoked'));
      expect(missing, contains('opt-in-keeps-revocation'));
      expect(missing, contains('revocation-never-skipped'));
      expect(missing, contains('revocation-policy-getter'));
    });

    test(
        'RED: dropping the validated-origin-binding hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutOriginBinding = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses binding to the validated origin|bypassvalidatedoriginbinding')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutOriginBinding);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('origin-binding-never-bypassed'));
      expect(missing, contains('origin-binding-policy-getter'));
    });

    test(
        'RED: dropping the platform-trust-store-integrity hard-invariant box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutTrustStoreIntegrity = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'trust-store integrity|trust anchor|networksecurityconfig|keystore|sectrust|global weakening|per-connection certificate|never mutates the platform trust store|bypassplatformtruststoreintegrity')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutTrustStoreIntegrity);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('trust-store-integrity'));
      expect(missing, contains('no-ca-trust-anchor-addition'));
      expect(missing, contains('android-user-ca-anchors'));
      expect(missing, contains('android-keystore-mutation'));
      expect(missing, contains('ios-custom-ca-anchor'));
      expect(missing, contains('global-trust-weakening'));
      expect(missing, contains('scoped-per-connection-verifier'));
      expect(missing, contains('trust-store-never-mutated'));
      expect(missing, contains('trust-store-policy-getter'));
    });

    test(
        'RED: dropping the client-certificate/mTLS validation box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutClientCert = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'client-certificate validation|mutual tls|private key must remain protected|never disable client-certificate validation|bypassclientcertificatevalidation')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutClientCert);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('client-cert-validation'));
      expect(missing, contains('mutual-tls-client-cert'));
      expect(missing, contains('client-private-key-protection'));
      expect(missing, contains('opt-in-keeps-client-cert'));
      expect(missing, contains('client-cert-policy-getter'));
    });

    test(
        'RED: dropping the strict-referrer-policy hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutReferrerInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses the strict referrer policy|bypassstrictreferrerpolicy')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutReferrerInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('referrer-never-bypassed'));
      expect(missing, contains('referrer-policy-getter'));
    });

    test(
        'RED: dropping the CSP/mixed-content-blocking hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutMixedContentInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses mixed-content blocking|bypassmixedcontentblocking')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutMixedContentInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('mixed-content-never-bypassed'));
      expect(missing, contains('mixed-content-policy-getter'));
    });

    test(
        'RED: dropping the sensitive console URL log-redaction hard-invariant '
        'box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutLogRedaction = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses sensitive console url|bypasslogredaction')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutLogRedaction);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('log-redaction-never-bypassed'));
      expect(missing, contains('log-redaction-policy-getter'));
    });

    test(
        'RED: dropping the sensitive data-at-rest hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDataAtRest = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses sensitive data at rest protection|bypasssensitivedataatrestprotection')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutDataAtRest);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('data-at-rest-never-bypassed'));
      expect(missing, contains('data-at-rest-policy-getter'));
    });

    test('RED: dropping the no-native-bridge hard-invariant box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutNativeBridgeInvariant = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses native bridge isolation|bypassnativebridgeisolation')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutNativeBridgeInvariant);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('native-bridge-never-bypassed'));
      expect(missing, contains('native-bridge-policy-getter'));
    });

    test(
        'RED: dropping the private-network egress protection hard-invariant '
        'box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPrivateEgress = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses private-network egress protection|bypassprivatenetworkegressprotection')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutPrivateEgress);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('private-egress-never-bypassed'));
      expect(missing, contains('private-egress-policy-getter'));
    });

    test(
        'RED: dropping the cross-site cookie / session-token isolation '
        'hard-invariant box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCookieIsolation = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses cross-site cookie|bypasscookieisolation')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutCookieIsolation);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('cookie-never-bypassed'));
      expect(missing, contains('cookie-policy-getter'));
    });

    test(
        'RED: dropping the no-remote-debugging/inspectability hard-invariant '
        'box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutRemoteDebugging = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses webview remote debugging|bypasswebviewremotedebugging')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutRemoteDebugging);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('remote-debugging-never-bypassed'));
      expect(missing, contains('remote-debugging-policy-getter'));
    });

    test(
        'RED: dropping the no-device-permission hard-invariant box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDevicePermissions = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses device-capability / permission access|bypassdevicepermissioncontrols')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutDevicePermissions);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('device-permissions-never-bypassed'));
      expect(missing, contains('device-permissions-policy-getter'));
    });

    test(
        'RED: dropping the no-http-auth prompt-spoofing hard-invariant box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutHttpAuth = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses http-auth / login-form challenge denial|bypasshttpauthchallengedenial')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutHttpAuth);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('http-auth-never-bypassed'));
      expect(missing, contains('http-auth-policy-getter'));
    });

    test(
        'RED: dropping the no-covert-outbound-egress hard-invariant box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutOutboundEgress = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'never bypasses the outbound egress allowlist|bypassoutboundegressallowlist')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutOutboundEgress);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('outbound-egress-never-bypassed'));
      expect(missing, contains('outbound-egress-policy-getter'));
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
