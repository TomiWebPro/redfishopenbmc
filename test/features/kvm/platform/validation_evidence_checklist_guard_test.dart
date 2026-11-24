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
// no-print/save-to-PDF exfiltration (hard configuration-independent invariant;
// the opt-in never exposes a print adapter nor honours a scripted window.print()
// so the privileged console DOM cannot be rendered to a durable print/PDF copy),
// no-pointer-lock/keyboard-lock/fullscreen input capture (hard configuration-
// independent invariant; the opt-in never lets attacker-influenced console
// content seize pointer/keyboard focus or hide the app chrome to trap input or
// spoof a credential prompt),
// no-picture-in-picture / floating secondary-window escape (hard configuration-
// independent invariant; the opt-in never lets attacker-influenced console
// content open a browser-native PiP window that renders outside the secure
// console frame, floats above other apps or outlives the console session),
// no-web-share / remote-cast / external-display exfiltration (hard config-
// uration-independent invariant; the opt-in never lets attacker-influenced
// console content hand privileged data out via a share sheet or cast receiver),
// no-cross-origin web-messaging exfiltration (postMessage / BroadcastChannel /
// MessageChannel; hard configuration-independent invariant; the opt-in never
// lets attacker-influenced console content post privileged session data to a
// foreign-origin context — an in-process channel distinct from a native bridge,
// network egress, form POST or the system clipboard),
// no-screen/window-capture exfiltration (getDisplayMedia / MediaRecorder / canvas
// captureStream / toDataURL; hard configuration-independent invariant; the opt-in
// never grants attacker-influenced console content a display-capture or
// frame-snapshot capability to scrape privileged KVM frames / session tokens /
// credentials off the rendered display — an active page-script capture surface
// distinct from camera/mic device permissions, the passive OS background
// snapshot at rest, picture-in-picture and outbound egress),
// no-hyperlink-auditing / <a ping> exfiltration (browser-generated background
// POST on link activation, governed by the CSP ping directive not connect-src;
// hard configuration-independent invariant; the opt-in never lets attacker-
// influenced console content smuggle privileged session data to a non-approved
// origin via the ping attribute, a channel distinct from programmatic egress,
// form POST, top-level navigation, private-network egress and subresource CSP),
// no-credential-management / WebAuthn credential harvesting
// (navigator.credentials password reads / WebAuthn publicKey assertions; hard
// configuration-independent invariant; the opt-in never lets attacker-
// influenced console content read saved credentials or coerce an authenticator
// prompt — distinct from form autofill and the native HTTP-auth challenge),
// no-speculative-prefetch/prerender exfiltration (Speculation Rules API /
// <link rel=prefetch/prerender>; a browser-generated speculative request
// governed by CSP prefetch-src not connect-src; hard configuration-independent
// invariant; the opt-in never lets attacker-influenced console content leak a
// session token via a speculative fetch — distinct from <a ping> auditing,
// programmatic egress, form POST and top-level navigation),
// no-notification / notification-permission spoofing exfiltration (Notifications
// API: Notification.requestPermission / new Notification / showNotification; hard
// configuration-independent invariant; the opt-in never lets attacker-influenced
// console content render privileged session data in an OS notification shown in the
// shade / lock screen outside the secure frame, nor coerce a permission prompt —
// a content-output channel distinct from generic device-permission prompts, in-page
// JS dialogs, PiP windows and screen capture),
// no-webrtc peer-to-peer / data-channel exfiltration (RTCPeerConnection /
// RTCDataChannel / ICE candidates / STUN / TURN; a peer-to-peer UDP channel that
// evades the HTTP(S) connect-src egress allowlist and leaks private/public IPs;
// hard configuration-independent invariant; the opt-in never lets attacker-
// influenced console content open a peer connection or data channel — distinct
// from programmatic HTTP egress and getUserMedia camera/mic capture),
// no-file-system-access API read/write exfiltration (showOpenFilePicker /
// showSaveFilePicker / showDirectoryPicker / createWritable / OPFS; a script-
// driven local-file read/write channel, hard configuration-independent
// invariant; the opt-in never lets attacker-influenced console content obtain a
// file handle to read local files into the frame or write a durable file —
// distinct from the <input type=file> chooser, direct file:// reads, the
// WebView's own cache/storage and a network-response download),
// no-webtransport / QUIC datagram exfiltration (new WebTransport / datagrams /
// createBidirectionalStream; a client/server QUIC datagram-stream channel, hard
// configuration-independent invariant; the opt-in never lets attacker-influenced
// console content open a WebTransport session — distinct from peer-to-peer
// WebRTC and from programmatic HTTP egress),
// no-peripheral-I/O exfiltration (WebUSB / WebSerial / WebHID; a script-driven
// local-hardware byte-stream channel that bypasses network egress; hard
// configuration-independent invariant; the opt-in never lets attacker-influenced
// console content open a USB/serial/HID stream to smuggle or relay privileged
// session data — distinct from generic device-permission grants, filesystem
// handles and the network egress allowlist),
// no-CSS-driven-subresource exfiltration (@import / background-image:url() /
// @font-face / attribute-selector CSS injection; a declarative network-request
// channel governed by CSP style-src / img-src / font-src, not connect-src; hard
// configuration-independent invariant; the opt-in never lets attacker-influenced
// console content emit a stylesheet-driven request carrying privileged session
// data to a non-approved origin — distinct from programmatic HTTP egress,
// speculation-rule prefetch and <a ping> hyperlink auditing),
// no-HTML-driven/markup subresource exfiltration (<img src> / <iframe src> /
// <script src> / <object data> / <embed src> / <source src> beacons; a markup-
// driven declarative request channel governed by CSP frame-src / object-src /
// media-src / img-src / script-src, not CSS rules or connect-src; hard config-
// uration-independent invariant; the opt-in never lets attacker-influenced
// console content emit a markup-driven subresource beacon carrying privileged
// session data to a non-approved origin — distinct from CSS-driven stylesheet
// requests, programmatic egress, speculation rules and <a ping> auditing),
// no-worker-script exfiltration (new Worker / SharedWorker / module worker /
// importScripts; a distinct off-main-thread script/module-loading channel
// governed by CSP worker-src / child-src / script-src, NOT connect-src; hard
// configuration-independent invariant; the opt-in never lets attacker-influenced
// console content spawn a worker or import a cross-origin script to smuggle
// privileged session data — distinct from service-worker registration, HTML
// <script src> markup, CSS subresources and programmatic egress),
// no-base-uri-hijacking / relative-URL resolution exfiltration (<base href>
// retargets every relative subresource / form / link URL to a non-approved
// origin; a declarative URL-resolution channel governed by CSP base-uri, not
// connect-src; hard configuration-independent invariant; the opt-in never lets
// attacker-influenced console content inject a base element — distinct from
// HTML subresource beacons, CSS rules, programmatic egress, form POST and
// navigation confinement),
// no-drag-and-drop exfiltration (HTML5 dragstart / dataTransfer.setData / drop
// on a cross-origin target, or dragging a privileged link / credential out of
// the secure frame; a user-interaction-driven data-transfer channel that needs
// no socket, form POST or navigation; hard configuration-independent invariant;
// the opt-in never lets attacker-influenced console content drag session data
// out — distinct from clipboard, web-messaging, egress and navigation surfaces),
// no-window.name / reverse-tabnabbing exfiltration (a persistent browsing-context
// name / window.opener back-reference that survives navigation and is readable
// cross-origin; a cross-context state channel needing no socket, postMessage,
// clipboard write or native bridge; hard configuration-independent invariant;
// the opt-in never lets attacker-influenced console content place privileged
// session data in window.name or keep a tabnabbing opener — distinct from
// cross-origin web messaging and navigation surfaces),
// no-DNS/hostname-encoding exfiltration (encoding privileged session data into
// DNS hostname labels / subdomains of an attacker-controlled host, recovered at
// the authoritative resolver even with no HTTP response and an intact
// connect-src allowlist, including DNS-prefetch; a resolution-time data channel
// distinct from HTTP egress, element/style beacons, speculative prefetch,
// subresource address class and top-level origin binding),
// no-SVG-external-resource / image-href exfiltration (<image href> / xlink:href,
// <use href>, <feImage href>, external <pattern>/<mask>/<clipPath>,
// <font-face-uri>, <script href>/<style href>, <foreignObject>; a declarative
// SVG-namespace subresource-request channel governed by CSP img-src /
// style-src / font-src / script-src / child-src, not connect-src; hard
// configuration-independent invariant; the opt-in never lets attacker-
// influenced console content emit an SVG-driven subresource beacon to a
// non-approved origin — distinct from HTML-element src/href beacons, CSS
// @import/url() rules, worker scripts and programmatic egress),
// no-Web-Speech-API / speech-synthesis audio exfiltration (speechSynthesis.speak
// / SpeechSynthesisUtterance / SpeechRecognition; an out-of-frame audio output
// channel that reads privileged console DOM aloud through the device speaker,
// with no socket, form POST, navigation, clipboard write, screen capture or
// subresource request; hard configuration-independent invariant; the opt-in
// never lets attacker-influenced console content speak session data — distinct
// from pixel capture, OS notifications, share/cast, clipboard and device
// capability grants),
// no-dynamic-import/cross-origin ES-module import exfiltration (the ES-module
// dynamic import() operator loads a module whose URL carries privileged console
// DOM from a non-approved origin; a main-thread script/module-loading channel
// governed by CSP script-src, not connect-src egress and not worker-src Worker
// loads; hard configuration-independent invariant; the opt-in never lets
// attacker-influenced console content import a cross-origin module — distinct
// from worker scripts, HTML <script src> beacons, CSS subresources and
// programmatic egress),
// no-Web-MIDI-API local-hardware exfiltration (navigator.requestMIDIAccess /
// MIDIOutput.send / onmidimessage; a script-driven local MIDI byte stream to a
// physically attached device that bypasses network egress; hard configuration-
// independent invariant; the opt-in never lets attacker-influenced console
// content open a MIDI stream — distinct from the WebUSB/WebSerial/WebHID
// peripheral-I/O box, generic device-permission prompts and programmatic
// egress),
// no-short-range-radio (Web Bluetooth / Web NFC) exfiltration
// (navigator.bluetooth.requestDevice / GATT writeValue / NDEFReader.write; a
// script-driven proximity-wireless local-hardware byte stream to a physically
// nearby device that bypasses network egress; hard configuration-independent
// invariant; the opt-in never lets attacker-influenced console content open a
// short-range radio stream — distinct from the wired USB/serial/HID peripheral
// I/O box, the MIDI byte-stream box, generic device-permission prompts and
// programmatic egress),
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
  (name: 'no-print-exfiltration', marker: 'print / save-to-pdf'),
  (name: 'no-print-window-print', marker: 'window.print'),
  (name: 'no-print-spooler', marker: 'printmanager'),
  (name: 'no-print-adapter', marker: 'createprintdocumentadapter'),
  (
    name: 'print-never-bypassed',
    marker: 'never bypasses print / save-to-pdf exfiltration'
  ),
  (name: 'print-policy-getter', marker: 'bypassprintexfiltration'),
  (
    name: 'print-distinct-from-download',
    marker: 'distinct from arbitrary / drive-by file download'
  ),
  (name: 'opt-in-keeps-print-denied', marker: 'never enable printing'),
  (
    name: 'no-input-capture',
    marker: 'pointer-lock / keyboard-lock / fullscreen input capture'
  ),
  (name: 'no-pointer-lock', marker: 'requestpointerlock'),
  (name: 'no-keyboard-lock', marker: 'requestkeyboardlock'),
  (
    name: 'input-capture-never-bypassed',
    marker: 'never bypasses input-capture protection'
  ),
  (name: 'input-capture-policy-getter', marker: 'bypassinputcaptureprotection'),
  (
    name: 'input-capture-distinct-from-js-dialog',
    marker: 'distinct from javascript dialog / modal spoofing'
  ),
  (
    name: 'opt-in-keeps-input-capture-denied',
    marker: 'never grant an input-capture'
  ),
  (name: 'no-picture-in-picture', marker: 'picture-in-picture'),
  (name: 'no-pip-request', marker: 'requestpictureinpicture'),
  (name: 'pip-never-bypassed', marker: 'never bypasses picture-in-picture'),
  (name: 'pip-policy-getter', marker: 'bypasspictureinpictureescape'),
  (name: 'pip-distinct-from-fullscreen', marker: 'distinct from fullscreen'),
  (name: 'opt-in-keeps-pip-denied', marker: 'never grant a picture-in-picture'),
  (name: 'pip-outlives-session', marker: 'outlives the console'),
  (
    name: 'no-share-cast-exfil',
    marker: 'web share / remote-cast / external-display exfiltration'
  ),
  (name: 'no-web-share-api', marker: 'navigator.share'),
  (name: 'no-presentation-api', marker: 'presentation api'),
  (name: 'no-remote-playback', marker: 'remote playback'),
  (name: 'no-airplay-cast', marker: 'airplay'),
  (
    name: 'share-cast-never-bypassed',
    marker: 'never bypasses web share / remote-cast exfiltration'
  ),
  (name: 'share-cast-policy-getter', marker: 'bypasssharecastexfiltration'),
  (
    name: 'share-cast-distinct-from-egress',
    marker: 'distinct from outbound egress'
  ),
  (
    name: 'opt-in-keeps-share-cast-denied',
    marker: 'never grant a share / cast request'
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
  // No clipboard read / write exfiltration (system-clipboard isolation): a
  // distinct cross-app data channel, not the host permission-prompt surface.
  (name: 'no-clipboard-exfil', marker: 'clipboard read / write exfiltration'),
  (name: 'no-clipboard-writetext', marker: 'navigator.clipboard.writetext'),
  (name: 'no-clipboard-readtext', marker: 'navigator.clipboard.readtext'),
  (name: 'clipboard-cross-app', marker: 'cross-app clipboard data channel'),
  (
    name: 'clipboard-never-bypassed',
    marker: 'never bypasses clipboard isolation'
  ),
  (name: 'clipboard-policy-getter', marker: 'bypassclipboardisolation'),
  (
    name: 'clipboard-distinct-from-device-perms',
    marker: 'not the clipboard permission-prompt surface'
  ),
  (name: 'opt-in-keeps-clipboard-denied', marker: 'never grant a clipboard'),
  // No cross-origin web-messaging exfiltration (postMessage/BroadcastChannel):
  // an in-process cross-origin data channel, not a network request, clipboard
  // write or app-injected native bridge.
  (
    name: 'no-cross-origin-messaging',
    marker: 'cross-origin web-messaging exfiltration'
  ),
  (name: 'no-postmessage', marker: 'postmessage'),
  (name: 'no-broadcast-channel', marker: 'broadcastchannel'),
  (
    name: 'cross-origin-messaging-never-bypassed',
    marker: 'never bypasses cross-origin web-messaging isolation'
  ),
  (
    name: 'cross-origin-messaging-policy-getter',
    marker: 'bypasscrossoriginmessagingisolation'
  ),
  (
    name: 'cross-origin-messaging-distinct-from-native-bridge',
    marker: 'distinct from native bridge isolation'
  ),
  (
    name: 'opt-in-keeps-messaging-denied',
    marker: 'never grant a cross-origin messaging'
  ),
  // No screen/window-capture exfiltration (getDisplayMedia / MediaRecorder /
  // canvas captureStream / toDataURL): an active, page-script-driven scrape of
  // the rendered privileged display, not a camera/mic grant, an OS snapshot, a
  // floating window, a clipboard write or a network destination.
  (
    name: 'no-screen-capture-exfil',
    marker: 'screen / window capture exfiltration'
  ),
  (name: 'no-get-display-media', marker: 'getdisplaymedia'),
  (name: 'no-media-recorder', marker: 'mediarecorder'),
  (name: 'no-canvas-capture-stream', marker: 'capturestream'),
  (name: 'no-canvas-snapshot', marker: 'todataurl'),
  (
    name: 'screen-capture-never-bypassed',
    marker: 'never bypasses screen/window-capture protection'
  ),
  (
    name: 'screen-capture-policy-getter',
    marker: 'bypassscreencaptureprotection'
  ),
  (
    name: 'screen-capture-distinct-from-device-perms',
    marker: 'display-capture grant is not a camera/mic grant'
  ),
  (
    name: 'screen-capture-distinct-from-snapshot',
    marker: 'a passive os capture, not an active page-script scrape'
  ),
  (
    name: 'opt-in-keeps-capture-denied',
    marker: 'never grants a capture capability'
  ),
  // No hyperlink auditing / <a ping> exfiltration: a browser-generated
  // background POST on link activation (CSP ping directive, not connect-src),
  // not a programmatic connection, form POST, navigation or subresource load.
  (name: 'no-hyperlink-auditing-exfil', marker: 'hyperlink auditing'),
  (name: 'no-ping-attribute', marker: 'ping attribute'),
  (name: 'no-ping-post', marker: 'ping-from'),
  (name: 'no-ping-csp-directive', marker: 'ping directive'),
  (
    name: 'hyperlink-auditing-never-bypassed',
    marker: 'never bypasses hyperlink-auditing exfiltration'
  ),
  (
    name: 'hyperlink-auditing-policy-getter',
    marker: 'bypasshyperlinkauditingexfiltration'
  ),
  (
    name: 'hyperlink-auditing-distinct-surface',
    marker: 'link-activation request channel'
  ),
  (
    name: 'opt-in-keeps-hyperlink-auditing-denied',
    marker: 'never allow hyperlink auditing'
  ),
  // No credential-management / WebAuthn credential harvesting: a JS API that
  // reads saved passwords or coerces an authenticator assertion — a credential-
  // theft surface distinct from form autofill and the native HTTP-auth prompt.
  (
    name: 'no-credential-management-harvest',
    marker: 'credential management api'
  ),
  (name: 'no-webauthn-harvest', marker: 'webauthn'),
  (name: 'no-navigator-credentials', marker: 'navigator.credentials'),
  (
    name: 'credential-harvest-never-bypassed',
    marker: 'never bypasses credential management api access'
  ),
  (
    name: 'credential-harvest-policy-getter',
    marker: 'bypasscredentialmanagementapiaccess'
  ),
  (
    name: 'credential-harvest-distinct-from-autofill',
    marker: 'distinct from autofill'
  ),
  (
    name: 'opt-in-keeps-credential-api-denied',
    marker: 'never grant credential-management access'
  ),
  // No speculative prefetch / prerender (Speculation Rules API) exfiltration:
  // a browser-generated speculative request (CSP prefetch-src, not connect-src),
  // not a programmatic connection, an <a ping> activation POST or a navigation.
  (name: 'no-speculation-rules-exfil', marker: 'speculation rules'),
  (name: 'no-prefetch', marker: 'prefetch'),
  (name: 'no-prerender', marker: 'prerender'),
  (name: 'prefetch-src-csp-directive', marker: 'prefetch-src'),
  (
    name: 'browser-generated-speculative',
    marker: 'browser-generated speculative'
  ),
  (
    name: 'speculation-never-bypassed',
    marker: 'never bypasses speculative prefetch'
  ),
  (name: 'speculation-policy-getter', marker: 'bypassspeculationrulesegress'),
  (
    name: 'speculation-distinct-from-ping',
    marker: 'distinct from hyperlink auditing'
  ),
  (
    name: 'opt-in-keeps-speculation-denied',
    marker: 'never grant a speculative'
  ),
  // No notification / notification-permission spoofing exfiltration (Notifications
  // API): a notification renders attacker-chosen console DOM in the OS shade / lock
  // screen, outside the secure frame; a channel distinct from device-permission
  // prompts, in-page JS dialogs, PiP windows and pixel capture.
  (name: 'no-notification-exfil', marker: 'notification api'),
  (
    name: 'no-notification-request-permission',
    marker: 'notification.requestpermission()'
  ),
  (name: 'no-notification-show', marker: 'new notification('),
  (name: 'no-notification-shownotification', marker: 'shownotification()'),
  (name: 'notification-outside-secure-frame', marker: 'notification shade'),
  (name: 'notification-lock-screen', marker: 'lock screen'),
  (
    name: 'notification-never-bypassed',
    marker: 'never bypasses notification api access'
  ),
  (name: 'notification-policy-getter', marker: 'bypassnotificationapiaccess'),
  (
    name: 'notification-distinct-from-device-perms',
    marker: 'distinct from device-capability / permission access'
  ),
  (
    name: 'notification-distinct-from-js-dialog',
    marker: 'distinct from javascript dialog'
  ),
  (
    name: 'opt-in-keeps-notification-denied',
    marker: 'never grant a notification'
  ),
  // No WebRTC peer-to-peer / data-channel exfiltration: a peer-to-peer UDP
  // channel (RTCPeerConnection / RTCDataChannel / ICE / STUN / TURN) that evades
  // the HTTP(S) connect-src egress allowlist and leaks private/public IPs —
  // distinct from programmatic HTTP egress and from getUserMedia capture.
  (name: 'no-webrtc-exfil', marker: 'webrtc peer-to-peer'),
  (name: 'no-rtc-peer-connection', marker: 'rtcpeerconnection'),
  (name: 'no-rtc-data-channel', marker: 'rtcdatachannel'),
  (name: 'no-ice-candidate-leak', marker: 'ice candidate'),
  (name: 'no-stun-turn', marker: 'stun / turn'),
  (name: 'webrtc-never-bypassed', marker: 'never bypasses webrtc'),
  (name: 'webrtc-policy-getter', marker: 'bypasswebrtcdatachannelexfiltration'),
  (
    name: 'webrtc-distinct-from-egress',
    marker: 'not a peer-to-peer udp data channel'
  ),
  (name: 'opt-in-keeps-webrtc-denied', marker: 'never grant a webrtc'),
  // No File System Access API exfiltration: a script-driven local-file read /
  // write channel (showOpenFilePicker / showSaveFilePicker / OPFS), distinct
  // from the operator-mediated <input type=file> chooser, direct file:// reads,
  // the WebView's own cache/storage and a network-response download.
  (name: 'no-file-system-access-api', marker: 'file system access api'),
  (name: 'no-show-open-file-picker', marker: 'showopenfilepicker'),
  (name: 'no-show-save-file-picker', marker: 'showsavefilepicker'),
  (name: 'no-show-directory-picker', marker: 'showdirectorypicker'),
  (name: 'no-fs-create-writable', marker: 'createwritable'),
  (name: 'no-opfs', marker: 'origin private file system'),
  (
    name: 'file-system-never-bypassed',
    marker: 'never bypasses file system access api'
  ),
  (name: 'file-system-policy-getter', marker: 'bypassfilesystemaccessapi'),
  (
    name: 'file-system-distinct-from-file-chooser',
    marker: 'distinct from the file chooser'
  ),
  (
    name: 'file-system-distinct-from-data-at-rest',
    marker: 'distinct from sensitive data at rest'
  ),
  (
    name: 'opt-in-keeps-file-system-denied',
    marker: 'never grant a file system'
  ),
  // No WebTransport / QUIC exfiltration: a client/server QUIC datagram / stream
  // channel (new WebTransport / transport.datagrams), distinct from the
  // peer-to-peer WebRTC channel and from the fetch/WebSocket connect-src
  // egress allowlist.
  (name: 'no-webtransport-exfil', marker: 'webtransport / quic'),
  (name: 'no-webtransport-api', marker: 'new webtransport('),
  (name: 'no-webtransport-datagrams', marker: 'datagrams'),
  (name: 'no-webtransport-streams', marker: 'createbidirectionalstream'),
  (name: 'webtransport-never-bypassed', marker: 'never bypasses webtransport'),
  (
    name: 'webtransport-policy-getter',
    marker: 'bypasswebtransportexfiltration'
  ),
  (name: 'webtransport-distinct-from-webrtc', marker: 'distinct from webrtc'),
  (
    name: 'webtransport-distinct-from-egress',
    marker: 'distinct from programmatic http egress'
  ),
  (
    name: 'opt-in-keeps-webtransport-denied',
    marker: 'never grant a webtransport'
  ),
  // No WebUSB / WebSerial / WebHID peripheral I/O exfiltration: a script-driven
  // local-hardware byte-stream channel (navigator.usb / serial / hid) that
  // bypasses network egress — distinct from generic device-permission grants,
  // filesystem handles and the HTTP(S) outbound egress allowlist.
  (name: 'no-peripheral-io-exfil', marker: 'peripheral i/o'),
  (name: 'no-webusb', marker: 'webusb'),
  (name: 'no-webserial', marker: 'webserial'),
  (name: 'no-webhid', marker: 'webhid'),
  (
    name: 'peripheral-io-never-bypassed',
    marker: 'never bypasses peripheral i/o'
  ),
  (
    name: 'peripheral-io-policy-getter',
    marker: 'bypassperipheralioexfiltration'
  ),
  (
    name: 'peripheral-io-distinct-from-device-perms',
    marker: 'distinct from device-permission controls'
  ),
  (
    name: 'peripheral-io-distinct-from-egress',
    marker: 'distinct from the outbound egress allowlist'
  ),
  (
    name: 'opt-in-keeps-peripheral-io-denied',
    marker: 'never grant a peripheral i/o'
  ),
  // No CSS-driven subresource exfiltration (CSS exfiltration via @import /
  // url() / @font-face / attribute selectors): a declarative network-request
  // channel governed by CSP style-src / img-src / font-src, NOT connect-src —
  // distinct from programmatic egress, speculation rules and <a ping> auditing.
  (name: 'no-css-exfil', marker: 'css-driven subresource exfiltration'),
  (name: 'no-css-import', marker: '@import'),
  (name: 'no-css-url', marker: 'background-image'),
  (name: 'no-css-font-face', marker: '@font-face'),
  (name: 'no-css-attribute-selector', marker: 'attribute selector'),
  (name: 'css-src-csp-directives', marker: 'style-src'),
  (name: 'css-img-src-csp', marker: 'img-src'),
  (name: 'css-font-src-csp', marker: 'font-src'),
  (
    name: 'css-never-bypassed',
    marker: 'never bypasses css-driven subresource exfiltration'
  ),
  (name: 'css-policy-getter', marker: 'bypasscssexfiltration'),
  (name: 'css-distinct-from-connect-src', marker: 'not connect-src'),
  (name: 'opt-in-keeps-css-denied', marker: 'never grant a css'),
  // No HTML-driven (markup) cross-origin subresource exfiltration: plain HTML
  // element src/href beacons (<img>, <iframe>, <script src>, <object>, media),
  // a declarative markup-driven request channel governed by frame-src /
  // object-src / media-src / img-src / script-src, NOT CSS rules or connect-src
  // programmatic egress — distinct from stylesheet requests, speculation rules
  // and <a ping> auditing.
  (
    name: 'no-html-subresource-exfil',
    marker: 'html-driven subresource exfiltration'
  ),
  (name: 'html-subresource-markup-driven', marker: 'markup-driven'),
  (name: 'no-html-img-src-beacon', marker: 'img src'),
  (name: 'no-html-frame-src-beacon', marker: 'frame-src'),
  (name: 'no-html-script-src-beacon', marker: 'script src'),
  (name: 'no-html-object-src-beacon', marker: 'object-src'),
  (name: 'no-html-media-src-beacon', marker: 'media-src'),
  (
    name: 'html-subresource-never-bypassed',
    marker: 'never bypasses html-driven subresource exfiltration'
  ),
  (
    name: 'html-subresource-policy-getter',
    marker: 'bypasshtmlsubresourceexfiltration'
  ),
  (
    name: 'html-subresource-distinct-from-css',
    marker: 'distinct from css-driven'
  ),
  (
    name: 'opt-in-keeps-html-subresource-denied',
    marker: 'never grant an html-driven'
  ),
  // No worker-script exfiltration: dedicated / shared / module Worker and
  // importScripts(), an off-main-thread script/module-loading channel governed
  // by worker-src / child-src / script-src, NOT connect-src programmatic egress
  // — distinct from service-worker registration, HTML <script src>, CSS and
  // markup subresource beacons.
  (name: 'no-worker-script-exfil', marker: 'worker-script exfiltration'),
  (name: 'worker-new-worker', marker: 'new worker('),
  (name: 'worker-shared-worker', marker: 'sharedworker'),
  (name: 'worker-import-scripts', marker: 'importscripts'),
  (name: 'worker-module', marker: 'module worker'),
  (name: 'worker-src-csp-directive', marker: 'worker-src'),
  (
    name: 'worker-script-never-bypassed',
    marker: 'never bypasses worker-script exfiltration'
  ),
  (
    name: 'worker-script-policy-getter',
    marker: 'bypassworkerscriptexfiltration'
  ),
  (
    name: 'worker-script-distinct-from-service-worker',
    marker: 'distinct from service worker'
  ),
  (
    name: 'opt-in-keeps-worker-script-denied',
    marker: 'never grant a worker'
  ),
  // No base-URI hijacking / relative-URL resolution exfiltration: injecting a
  // <base href> element retargets every relative subresource / form / link URL
  // to a non-approved origin — a declarative URL-resolution channel governed by
  // the CSP base-uri directive, NOT connect-src — distinct from HTML subresource
  // beacons, programmatic egress, form submission and navigation confinement.
  (name: 'no-base-uri-hijacking', marker: 'base-uri hijacking'),
  (name: 'no-base-href-element', marker: '<base href'),
  (name: 'base-uri-csp-directive', marker: 'base-uri directive'),
  (name: 'relative-url-retargeting', marker: 'relative url'),
  (name: 'base-uri-never-bypassed', marker: 'never bypasses base-uri hijacking'),
  (name: 'base-uri-policy-getter', marker: 'bypassbaseurihijacking'),
  (
    name: 'base-uri-distinct-from-subresource',
    marker: 'distinct from html-driven subresource'
  ),
  (name: 'opt-in-keeps-base-uri-denied', marker: 'never grant a base uri'),
  // No drag-and-drop exfiltration: a user-interaction-driven data-transfer
  // channel (dragstart / dataTransfer.setData / drop on a cross-origin target,
  // or dragging a privileged link / credential out of the secure frame) that
  // carries session data out without a socket, form POST or navigation —
  // distinct from clipboard, web-messaging, egress and navigation surfaces.
  (name: 'no-drag-and-drop-exfil', marker: 'drag-and-drop exfiltration'),
  (name: 'no-dragstart-datatransfer', marker: 'datatransfer.setdata'),
  (name: 'no-cross-origin-drop-target', marker: 'cross-origin drop target'),
  (name: 'drag-out-of-secure-frame', marker: 'dragged out of the secure frame'),
  (name: 'drag-and-drop-never-bypassed', marker: 'never bypasses drag-and-drop'),
  (name: 'drag-and-drop-policy-getter', marker: 'bypassdraganddrop'),
  (
    name: 'drag-and-drop-distinct-from-clipboard',
    marker: 'distinct from clipboard'
  ),
  (name: 'opt-in-keeps-drag-and-drop-denied', marker: 'never grant a drag'),
  // No window.name / reverse-tabnabbing / window.opener exfiltration: a
  // persistent browsing-context name / opener back-reference readable across
  // origins after navigation — a cross-context state channel needing no socket,
  // postMessage, clipboard write or native bridge, distinct from cross-origin
  // web messaging (a message API) and navigation confinement (where the frame
  // goes, not the data carried in window.name).
  (name: 'no-window-name-exfil', marker: 'window.name exfiltration'),
  (name: 'no-window-opener', marker: 'window.opener'),
  (name: 'reverse-tabnabbing', marker: 'reverse tabnabbing'),
  (name: 'browsing-context-name', marker: 'browsing context name'),
  (name: 'window-name-never-bypassed', marker: 'never bypasses window.name'),
  (name: 'window-name-policy-getter', marker: 'bypasswindownameexfiltration'),
  (
    name: 'window-name-distinct-from-messaging',
    marker: 'distinct from cross-origin web messaging'
  ),
  (name: 'opt-in-keeps-window-name-denied', marker: 'never grant a window.name'),
  // No DNS-based / hostname-encoding exfiltration: encoding privileged session
  // data into DNS hostname labels / subdomains of an attacker-controlled host
  // (recoverable at the authoritative resolver even with no HTTP response and
  // an intact connect-src allowlist), including DNS-prefetch. A resolution-time
  // data channel distinct from HTTP egress, element/style subresource beacons,
  // speculative prefetch, subresource address class and top-level origin
  // binding.
  (name: 'no-dns-exfil', marker: 'dns exfiltration'),
  (name: 'no-dns-prefetch', marker: 'dns-prefetch'),
  (name: 'dns-subdomain-encoding', marker: 'subdomain'),
  (name: 'dns-authoritative-resolver', marker: 'authoritative'),
  (name: 'dns-hostname-label', marker: 'hostname label'),
  (name: 'dns-never-bypassed', marker: 'never bypasses dns exfiltration'),
  (name: 'dns-policy-getter', marker: 'bypassdnsexfiltration'),
  (name: 'dns-distinct-surface', marker: 'dns resolution channel itself'),
  (name: 'opt-in-keeps-dns-denied', marker: 'never grant a dns lookup'),
  // No SVG external-resource / image-href exfiltration: SVG-namespace
  // declarative subresource references (<image href>, <use href>, <feImage>,
  // <font-face-uri>, <foreignObject>), governed by CSP img-src / style-src /
  // font-src / script-src / child-src, NOT connect-src programmatic egress —
  // distinct from HTML src/href beacons, CSS url()/@import rules and workers.
  (name: 'no-svg-external-resource-exfil', marker: 'svg external-resource'),
  (name: 'no-svg-image-href', marker: 'image href'),
  (name: 'no-svg-use-href', marker: 'use href'),
  (name: 'no-svg-feimage', marker: 'feimage'),
  (name: 'no-svg-font-face-uri', marker: 'font-face-uri'),
  (name: 'no-svg-foreign-object', marker: 'foreignobject'),
  (name: 'svg-src-csp-directives', marker: 'child-src'),
  (
    name: 'svg-exfil-never-bypassed',
    marker: 'never bypasses svg external-resource exfiltration'
  ),
  (
    name: 'svg-exfil-policy-getter',
    marker: 'bypasssvgexternalresourceexfiltration'
  ),
  (name: 'svg-exfil-distinct-surface', marker: 'svg-namespace declarative'),
  (
    name: 'opt-in-keeps-svg-exfil-denied',
    marker: 'never grant an svg external-resource'
  ),
  // No Web Speech API / speech-synthesis audio exfiltration: an out-of-frame
  // audio output channel (speechSynthesis.speak / SpeechSynthesisUtterance /
  // SpeechRecognition) that reads privileged console DOM aloud through the
  // device speaker, with no socket, form POST, navigation, clipboard write,
  // screen capture or subresource request — distinct from pixel capture, OS
  // notifications, share/cast, clipboard and device-capability grants.
  (name: 'no-speech-synthesis-exfil', marker: 'speech synthesis'),
  (name: 'no-speech-synthesis-speak', marker: 'speechsynthesis.speak'),
  (name: 'no-speech-utterance', marker: 'speechsynthesisutterance'),
  (name: 'no-speech-recognition', marker: 'speechrecognition'),
  (name: 'speech-out-of-frame-audio', marker: 'device speaker'),
  (
    name: 'speech-never-bypassed',
    marker: 'never bypasses speech synthesis exfiltration'
  ),
  (
    name: 'speech-policy-getter',
    marker: 'bypassspeechsynthesisexfiltration'
  ),
  (name: 'speech-distinct-from-capture', marker: 'audio output channel'),
  (name: 'opt-in-keeps-speech-denied', marker: 'never grant a speech'),
  // No dynamic import() / cross-origin ES-module import exfiltration: a
  // main-thread script/module-loading channel governed by CSP script-src (not
  // connect-src egress, not worker-src Worker loads); an out-of-allowlist way
  // for attacker-influenced console content to pull a non-approved origin in.
  (name: 'no-dynamic-import-exfil', marker: 'dynamic module import'),
  (name: 'no-dynamic-import-operator', marker: 'import()'),
  (name: 'no-cross-origin-es-module', marker: 'cross-origin es module'),
  (name: 'dynamic-import-module-graph', marker: 'module-graph'),
  (name: 'dynamic-import-csp-surface', marker: 'es-module loading'),
  (
    name: 'dynamic-import-never-bypassed',
    marker: 'never bypasses dynamic module import exfiltration'
  ),
  (
    name: 'dynamic-import-policy-getter',
    marker: 'bypassdynamicmoduleimportexfiltration'
  ),
  (
    name: 'dynamic-import-distinct-from-worker',
    marker: 'distinct from worker-script exfiltration'
  ),
  (
    name: 'opt-in-keeps-dynamic-import-denied',
    marker: 'never grant a dynamic module import'
  ),
  // No Web MIDI API local-hardware exfiltration: a script-driven MIDI byte
  // stream to a physically attached device (navigator.requestMIDIAccess /
  // MIDIOutput.send / onmidimessage), distinct from the enumerated WebUSB /
  // WebSerial / WebHID peripheral I/O box, generic device-permission prompts
  // and the HTTP(S) outbound egress allowlist.
  (name: 'no-web-midi-exfil', marker: 'web midi api'),
  (name: 'no-request-midi-access', marker: 'requestmidiaccess'),
  (name: 'no-midi-output-send', marker: 'midioutput.send'),
  (name: 'midi-local-hardware', marker: 'midi byte stream'),
  (name: 'midi-never-bypassed', marker: 'never bypasses web midi'),
  (name: 'midi-policy-getter', marker: 'bypasswebmidiexfiltration'),
  (name: 'midi-distinct-from-peripheral-io', marker: 'distinct from webusb'),
  (
    name: 'midi-distinct-from-device-perms',
    marker: 'distinct from device-permission controls'
  ),
  (name: 'opt-in-keeps-midi-denied', marker: 'never grant a web midi'),
  // No short-range radio (Web Bluetooth / Web NFC) exfiltration: a script-
  // driven proximity-wireless local-hardware byte stream to a physically nearby
  // device (navigator.bluetooth.requestDevice / GATT characteristic writeValue /
  // NDEFReader.write), distinct from the wired USB/serial/HID and MIDI boxes,
  // generic device-permission prompts and the HTTP(S) outbound egress allowlist.
  (name: 'no-short-range-radio-exfil', marker: 'short-range radio'),
  (name: 'no-web-bluetooth-device', marker: 'requestdevice'),
  (name: 'no-web-nfc-write', marker: 'ndefreader'),
  (name: 'short-range-gatt-write', marker: 'gatt characteristic'),
  (name: 'short-range-nearby-hardware', marker: 'physically nearby'),
  (name: 'short-range-never-bypassed', marker: 'never bypasses short-range radio'),
  (
    name: 'short-range-policy-getter',
    marker: 'bypassshortrangeradioexfiltration'
  ),
  (
    name: 'short-range-distinct-from-peripheral-io',
    marker: 'wired usb/serial/hid'
  ),
  (
    name: 'opt-in-keeps-short-range-denied',
    marker: 'never grant a short-range radio'
  ),
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

    test(
        'RED: dropping the no-JavaScript-dialog hard-invariant box fails '
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
      expect(
          missing, contains('service-worker-distinct-from-debug-and-at-rest'));
      expect(missing, contains('opt-in-keeps-service-workers-denied'));
    });

    test('RED: dropping the no-print/save-to-PDF exfiltration box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPrint = section
          .split('\n')
          .where((String line) => !line
              .toLowerCase()
              .contains(RegExp(r'print|distinct from arbitrary')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutPrint);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-print-exfiltration'));
      expect(missing, contains('no-print-window-print'));
      expect(missing, contains('no-print-spooler'));
      expect(missing, contains('no-print-adapter'));
      expect(missing, contains('print-never-bypassed'));
      expect(missing, contains('print-policy-getter'));
      expect(missing, contains('print-distinct-from-download'));
      expect(missing, contains('opt-in-keeps-print-denied'));
    });

    test('RED: dropping the no-input-capture box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutInputCapture = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'input.capture|requestpointerlock|requestkeyboardlock|bypassinputcaptureprotection|distinct from javascript dialog')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutInputCapture);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-input-capture'));
      expect(missing, contains('no-pointer-lock'));
      expect(missing, contains('no-keyboard-lock'));
      expect(missing, contains('input-capture-never-bypassed'));
      expect(missing, contains('input-capture-policy-getter'));
      expect(missing, contains('input-capture-distinct-from-js-dialog'));
      expect(missing, contains('opt-in-keeps-input-capture-denied'));
    });

    test('RED: dropping the no-picture-in-picture box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPip = section
          .split('\n')
          .where((String line) => !line
              .toLowerCase()
              .contains(RegExp(r'picture-in-picture|requestpictureinpicture|'
                  r'bypasspictureinpictureescape|distinct from fullscreen|'
                  r'never grant a picture-in-picture|outlives the console')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutPip);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-picture-in-picture'));
      expect(missing, contains('no-pip-request'));
      expect(missing, contains('pip-never-bypassed'));
      expect(missing, contains('pip-policy-getter'));
      expect(missing, contains('pip-distinct-from-fullscreen'));
      expect(missing, contains('opt-in-keeps-pip-denied'));
      expect(missing, contains('pip-outlives-session'));
    });

    test('RED: dropping the no-web-share / remote-cast box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutShareCast = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'web share / remote-cast|navigator\.share|presentation api|'
              r'remote playback|airplay|never bypasses web share|'
              r'bypasssharecastexfiltration|distinct from outbound egress|'
              r'never grant a share / cast')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutShareCast);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-share-cast-exfil'));
      expect(missing, contains('no-web-share-api'));
      expect(missing, contains('no-presentation-api'));
      expect(missing, contains('no-remote-playback'));
      expect(missing, contains('no-airplay-cast'));
      expect(missing, contains('share-cast-never-bypassed'));
      expect(missing, contains('share-cast-policy-getter'));
      expect(missing, contains('share-cast-distinct-from-egress'));
      expect(missing, contains('opt-in-keeps-share-cast-denied'));
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

    test(
        'RED: dropping the no-clipboard read/write exfiltration box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutClipboard = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains('clipboard'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutClipboard);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-clipboard-exfil'));
      expect(missing, contains('no-clipboard-writetext'));
      expect(missing, contains('no-clipboard-readtext'));
      expect(missing, contains('clipboard-cross-app'));
      expect(missing, contains('clipboard-never-bypassed'));
      expect(missing, contains('clipboard-policy-getter'));
      expect(missing, contains('clipboard-distinct-from-device-perms'));
      expect(missing, contains('opt-in-keeps-clipboard-denied'));
    });

    test(
        'RED: dropping the no-cross-origin web-messaging exfiltration box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutMessaging = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'cross-origin web-messaging|bypasscrossoriginmessagingisolation|postmessage|broadcastchannel|distinct from native bridge isolation|never grant a cross-origin messaging')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutMessaging);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-cross-origin-messaging'));
      expect(missing, contains('no-postmessage'));
      expect(missing, contains('no-broadcast-channel'));
      expect(missing, contains('cross-origin-messaging-never-bypassed'));
      expect(missing, contains('cross-origin-messaging-policy-getter'));
      expect(missing,
          contains('cross-origin-messaging-distinct-from-native-bridge'));
      expect(missing, contains('opt-in-keeps-messaging-denied'));
    });

    test(
        'RED: dropping the no-screen/window-capture exfiltration box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCapture = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'screen / window capture exfiltration|getdisplaymedia|mediarecorder|capturestream|todataurl|never bypasses screen/window-capture protection|bypassscreencaptureprotection|display-capture grant is not a camera/mic grant|passive os capture|never grants a capture capability')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutCapture);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-screen-capture-exfil'));
      expect(missing, contains('no-get-display-media'));
      expect(missing, contains('no-media-recorder'));
      expect(missing, contains('no-canvas-capture-stream'));
      expect(missing, contains('no-canvas-snapshot'));
      expect(missing, contains('screen-capture-never-bypassed'));
      expect(missing, contains('screen-capture-policy-getter'));
      expect(missing, contains('screen-capture-distinct-from-device-perms'));
      expect(missing, contains('screen-capture-distinct-from-snapshot'));
      expect(missing, contains('opt-in-keeps-capture-denied'));
    });

    test('RED: dropping the no-hyperlink-auditing / <a ping> box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPing = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'hyperlink auditing|ping attribute|ping-from|ping directive|never bypasses hyperlink-auditing|bypasshyperlinkauditingexfiltration|link-activation request channel|never allow hyperlink auditing')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutPing);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-hyperlink-auditing-exfil'));
      expect(missing, contains('no-ping-attribute'));
      expect(missing, contains('no-ping-post'));
      expect(missing, contains('no-ping-csp-directive'));
      expect(missing, contains('hyperlink-auditing-never-bypassed'));
      expect(missing, contains('hyperlink-auditing-policy-getter'));
      expect(missing, contains('hyperlink-auditing-distinct-surface'));
      expect(missing, contains('opt-in-keeps-hyperlink-auditing-denied'));
    });

    test(
        'RED: dropping the no-credential-management / WebAuthn harvesting box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCredentialApi = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'credential management api|webauthn|navigator\.credentials|never bypasses credential management api access|bypasscredentialmanagementapiaccess|distinct from autofill|never grant credential-management access')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutCredentialApi);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-credential-management-harvest'));
      expect(missing, contains('no-webauthn-harvest'));
      expect(missing, contains('no-navigator-credentials'));
      expect(missing, contains('credential-harvest-never-bypassed'));
      expect(missing, contains('credential-harvest-policy-getter'));
      expect(missing, contains('credential-harvest-distinct-from-autofill'));
      expect(missing, contains('opt-in-keeps-credential-api-denied'));
    });

    test('RED: dropping the no-speculative-prefetch/prerender box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutSpeculation = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'speculation rules|prefetch|prerender|prefetch-src|browser-generated speculative|never bypasses speculative prefetch|bypassspeculationrulesegress|distinct from hyperlink auditing|never grant a speculative')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutSpeculation);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-speculation-rules-exfil'));
      expect(missing, contains('no-prefetch'));
      expect(missing, contains('no-prerender'));
      expect(missing, contains('prefetch-src-csp-directive'));
      expect(missing, contains('browser-generated-speculative'));
      expect(missing, contains('speculation-never-bypassed'));
      expect(missing, contains('speculation-policy-getter'));
      expect(missing, contains('speculation-distinct-from-ping'));
      expect(missing, contains('opt-in-keeps-speculation-denied'));
    });

    test('RED: dropping the no-notification exfiltration box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutNotification = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'notification api|notification.requestpermission|new notification\(|shownotification|notification shade|lock screen|never bypasses notification|bypassnotificationapiaccess|distinct from device-capability|distinct from javascript dialog|never grant a notification')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutNotification);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-notification-exfil'));
      expect(missing, contains('no-notification-request-permission'));
      expect(missing, contains('no-notification-show'));
      expect(missing, contains('no-notification-shownotification'));
      expect(missing, contains('notification-outside-secure-frame'));
      expect(missing, contains('notification-lock-screen'));
      expect(missing, contains('notification-never-bypassed'));
      expect(missing, contains('notification-policy-getter'));
      expect(missing, contains('notification-distinct-from-device-perms'));
      expect(missing, contains('notification-distinct-from-js-dialog'));
      expect(missing, contains('opt-in-keeps-notification-denied'));
    });

    test(
        'RED: dropping the no-WebRTC peer-to-peer/data-channel box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutWebRtc = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'webrtc|rtcpeerconnection|rtcdatachannel|createchannel|ice candidate|onicecandidate|stun / turn|stun/turn|never bypasses webrtc|bypasswebrtcdatachannelexfiltration|peer-to-peer|never grant a webrtc')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutWebRtc);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-webrtc-exfil'));
      expect(missing, contains('no-rtc-peer-connection'));
      expect(missing, contains('no-rtc-data-channel'));
      expect(missing, contains('no-ice-candidate-leak'));
      expect(missing, contains('no-stun-turn'));
      expect(missing, contains('webrtc-never-bypassed'));
      expect(missing, contains('webrtc-policy-getter'));
      expect(missing, contains('webrtc-distinct-from-egress'));
      expect(missing, contains('opt-in-keeps-webrtc-denied'));
    });

    test('RED: dropping the no-File-System-Access-API box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutFileSystem = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'file system access api|showopenfilepicker|showsavefilepicker|'
              r'showdirectorypicker|createwritable|origin private file system|'
              r'never bypasses file system access api|'
              r'bypassfilesystemaccessapi|distinct from the file chooser|'
              r'distinct from sensitive data at rest|never grant a file system')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutFileSystem);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-file-system-access-api'));
      expect(missing, contains('no-show-open-file-picker'));
      expect(missing, contains('no-show-save-file-picker'));
      expect(missing, contains('no-show-directory-picker'));
      expect(missing, contains('no-fs-create-writable'));
      expect(missing, contains('no-opfs'));
      expect(missing, contains('file-system-never-bypassed'));
      expect(missing, contains('file-system-policy-getter'));
      expect(missing, contains('file-system-distinct-from-file-chooser'));
      expect(missing, contains('file-system-distinct-from-data-at-rest'));
      expect(missing, contains('opt-in-keeps-file-system-denied'));
    });

    test('RED: dropping the no-WebTransport/QUIC box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutWebTransport = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(
              RegExp(r'webtransport / quic|new webtransport\(|datagrams|'
                  r'createbidirectionalstream|never bypasses webtransport|'
                  r'bypasswebtransportexfiltration|distinct from webrtc|'
                  r'distinct from programmatic http egress|'
                  r'never grant a webtransport')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutWebTransport);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-webtransport-exfil'));
      expect(missing, contains('no-webtransport-api'));
      expect(missing, contains('no-webtransport-datagrams'));
      expect(missing, contains('no-webtransport-streams'));
      expect(missing, contains('webtransport-never-bypassed'));
      expect(missing, contains('webtransport-policy-getter'));
      expect(missing, contains('webtransport-distinct-from-webrtc'));
      expect(missing, contains('webtransport-distinct-from-egress'));
      expect(missing, contains('opt-in-keeps-webtransport-denied'));
    });

    test(
        'RED: dropping the no-WebUSB/WebSerial/WebHID peripheral-I/O box '
        'fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutPeripheralIo = section
          .split('\n')
          .where((String line) => !line
              .toLowerCase()
              .contains(RegExp(r'peripheral i/o|webusb|webserial|webhid|'
                  r'bypassperipheralioexfiltration|device-permission controls|'
                  r'outbound egress allowlist')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutPeripheralIo);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-peripheral-io-exfil'));
      expect(missing, contains('no-webusb'));
      expect(missing, contains('no-webserial'));
      expect(missing, contains('no-webhid'));
      expect(missing, contains('peripheral-io-never-bypassed'));
      expect(missing, contains('peripheral-io-policy-getter'));
      expect(missing, contains('peripheral-io-distinct-from-device-perms'));
      expect(missing, contains('peripheral-io-distinct-from-egress'));
      expect(missing, contains('opt-in-keeps-peripheral-io-denied'));
    });

    test('RED: dropping the no-CSS-driven-subresource-exfiltration box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutCss = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'css-driven subresource exfiltration|@import|background-image|'
              r'@font-face|attribute selector|style-src|img-src|font-src|'
              r'never bypasses css-driven subresource exfiltration|'
              r'bypasscssexfiltration|not connect-src|never grant a css')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutCss);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-css-exfil'));
      expect(missing, contains('no-css-import'));
      expect(missing, contains('no-css-url'));
      expect(missing, contains('no-css-font-face'));
      expect(missing, contains('no-css-attribute-selector'));
      expect(missing, contains('css-src-csp-directives'));
      expect(missing, contains('css-img-src-csp'));
      expect(missing, contains('css-font-src-csp'));
      expect(missing, contains('css-never-bypassed'));
      expect(missing, contains('css-policy-getter'));
      expect(missing, contains('css-distinct-from-connect-src'));
      expect(missing, contains('opt-in-keeps-css-denied'));
    });

    test('RED: dropping the no-HTML-driven-subresource-exfiltration box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutHtmlSubresource = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'html-driven subresource exfiltration|markup-driven|img src|'
              r'frame-src|script src|object-src|media-src|distinct from css-driven|'
              r'never bypasses html-driven subresource exfiltration|'
              r'bypasshtmlsubresourceexfiltration|never grant an html-driven')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutHtmlSubresource);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-html-subresource-exfil'));
      expect(missing, contains('html-subresource-markup-driven'));
      expect(missing, contains('no-html-img-src-beacon'));
      expect(missing, contains('no-html-frame-src-beacon'));
      expect(missing, contains('no-html-script-src-beacon'));
      expect(missing, contains('no-html-object-src-beacon'));
      expect(missing, contains('no-html-media-src-beacon'));
      expect(missing, contains('html-subresource-never-bypassed'));
      expect(missing, contains('html-subresource-policy-getter'));
      expect(missing, contains('html-subresource-distinct-from-css'));
      expect(missing, contains('opt-in-keeps-html-subresource-denied'));
    });

    test('RED: dropping the no-worker-script-exfiltration box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutWorkerScript = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'worker-script exfiltration|new worker\(|sharedworker|'
              r'importscripts|module worker|worker-src|'
              r'never bypasses worker-script exfiltration|'
              r'bypassworkerscriptexfiltration|distinct from service worker|'
              r'never grant a worker')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutWorkerScript);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-worker-script-exfil'));
      expect(missing, contains('worker-new-worker'));
      expect(missing, contains('worker-shared-worker'));
      expect(missing, contains('worker-import-scripts'));
      expect(missing, contains('worker-module'));
      expect(missing, contains('worker-src-csp-directive'));
      expect(missing, contains('worker-script-never-bypassed'));
      expect(missing, contains('worker-script-policy-getter'));
      expect(missing, contains('worker-script-distinct-from-service-worker'));
      expect(missing, contains('opt-in-keeps-worker-script-denied'));
    });

    test('RED: dropping the no-base-URI-hijacking box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutBaseUri = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'base-uri hijacking|<base href|base-uri directive|'
              r'relative url|never bypasses base-uri|bypassbaseurihijacking|'
              r'distinct from html-driven subresource|never grant a base uri')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutBaseUri);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-base-uri-hijacking'));
      expect(missing, contains('no-base-href-element'));
      expect(missing, contains('base-uri-csp-directive'));
      expect(missing, contains('relative-url-retargeting'));
      expect(missing, contains('base-uri-never-bypassed'));
      expect(missing, contains('base-uri-policy-getter'));
      expect(missing, contains('base-uri-distinct-from-subresource'));
      expect(missing, contains('opt-in-keeps-base-uri-denied'));
    });

    test('RED: dropping the no-drag-and-drop-exfiltration box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDragAndDrop = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'drag|datatransfer|drop target')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutDragAndDrop);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-drag-and-drop-exfil'));
      expect(missing, contains('no-dragstart-datatransfer'));
      expect(missing, contains('no-cross-origin-drop-target'));
      expect(missing, contains('drag-out-of-secure-frame'));
      expect(missing, contains('drag-and-drop-never-bypassed'));
      expect(missing, contains('drag-and-drop-policy-getter'));
      expect(missing, contains('drag-and-drop-distinct-from-clipboard'));
      expect(missing, contains('opt-in-keeps-drag-and-drop-denied'));
    });

    test('RED: dropping the no-window.name/tabnabbing box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutWindowName = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'window\.name|window\.opener|reverse tabnabbing|'
              r'browsing context name|bypasswindownameexfiltration|'
              r'bypasscrossoriginmessagingisolation')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutWindowName);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-window-name-exfil'));
      expect(missing, contains('no-window-opener'));
      expect(missing, contains('reverse-tabnabbing'));
      expect(missing, contains('browsing-context-name'));
      expect(missing, contains('window-name-never-bypassed'));
      expect(missing, contains('window-name-policy-getter'));
      expect(missing, contains('window-name-distinct-from-messaging'));
      expect(missing, contains('opt-in-keeps-window-name-denied'));
    });

    test('RED: dropping the no-DNS/hostname-encoding exfiltration box fails '
        'closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDns = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'dns-based|dns exfiltration|dns-prefetch|subdomain|'
              r'authoritative|hostname label|dns lookup|'
              r'dns resolution channel|bypassdnsexfiltration')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutDns);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-dns-exfil'));
      expect(missing, contains('no-dns-prefetch'));
      expect(missing, contains('dns-subdomain-encoding'));
      expect(missing, contains('dns-authoritative-resolver'));
      expect(missing, contains('dns-hostname-label'));
      expect(missing, contains('dns-never-bypassed'));
      expect(missing, contains('dns-policy-getter'));
      expect(missing, contains('dns-distinct-surface'));
      expect(missing, contains('opt-in-keeps-dns-denied'));
    });

    test('RED: dropping the no-SVG-external-resource box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutSvg = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'svg external-resource|image href|use href|feimage|'
              r'font-face-uri|foreignobject|child-src|img-src|'
              r'bypasssvgexternalresourceexfiltration|'
              r'never grant an svg|svg-namespace declarative|'
              r'never bypasses svg')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutSvg);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-svg-external-resource-exfil'));
      expect(missing, contains('no-svg-image-href'));
      expect(missing, contains('no-svg-use-href'));
      expect(missing, contains('no-svg-feimage'));
      expect(missing, contains('no-svg-font-face-uri'));
      expect(missing, contains('no-svg-foreign-object'));
      expect(missing, contains('svg-src-csp-directives'));
      expect(missing, contains('svg-exfil-never-bypassed'));
      expect(missing, contains('svg-exfil-policy-getter'));
      expect(missing, contains('svg-exfil-distinct-surface'));
      expect(missing, contains('opt-in-keeps-svg-exfil-denied'));
    });

    test('RED: dropping the no-Web-Speech/speech-synthesis box fails closed',
        () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutSpeech = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'speech synthesis|speechsynthesis\.speak|'
              r'speechsynthesisutterance|speechrecognition|'
              r'device speaker|audio output channel|'
              r'bypassspeechsynthesisexfiltration|never grant a speech')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutSpeech);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-speech-synthesis-exfil'));
      expect(missing, contains('no-speech-synthesis-speak'));
      expect(missing, contains('no-speech-utterance'));
      expect(missing, contains('no-speech-recognition'));
      expect(missing, contains('speech-out-of-frame-audio'));
      expect(missing, contains('speech-never-bypassed'));
      expect(missing, contains('speech-policy-getter'));
      expect(missing, contains('speech-distinct-from-capture'));
      expect(missing, contains('opt-in-keeps-speech-denied'));
    });

    test('RED: dropping the no-dynamic-import/ES-module box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutDynamicImport = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'dynamic|import\(|cross-origin es module|module-graph|'
              r'es-module loading|worker-script exfiltration|'
              r'bypassdynamicmoduleimportexfiltration')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutDynamicImport);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-dynamic-import-exfil'));
      expect(missing, contains('no-dynamic-import-operator'));
      expect(missing, contains('no-cross-origin-es-module'));
      expect(missing, contains('dynamic-import-module-graph'));
      expect(missing, contains('dynamic-import-csp-surface'));
      expect(missing, contains('dynamic-import-never-bypassed'));
      expect(missing, contains('dynamic-import-policy-getter'));
      expect(missing, contains('dynamic-import-distinct-from-worker'));
      expect(missing, contains('opt-in-keeps-dynamic-import-denied'));
    });

    test('RED: dropping the no-Web-MIDI-API box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutMidi = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'web midi|requestmidiaccess|midioutput|midi byte stream|'
              r'never bypasses web midi|bypasswebmidiexfiltration|'
              r'distinct from webusb|distinct from device-permission|'
              r'never grant a web midi')))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutMidi);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-web-midi-exfil'));
      expect(missing, contains('no-request-midi-access'));
      expect(missing, contains('no-midi-output-send'));
      expect(missing, contains('midi-local-hardware'));
      expect(missing, contains('midi-never-bypassed'));
      expect(missing, contains('midi-policy-getter'));
      expect(missing, contains('midi-distinct-from-peripheral-io'));
      expect(missing, contains('midi-distinct-from-device-perms'));
      expect(missing, contains('opt-in-keeps-midi-denied'));
    });

    test('RED: dropping the no-short-range-radio box fails closed', () {
      final String section = rawEvidenceSection(realMatrix);
      final String withoutShortRange = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains(RegExp(
              r'short-range radio|requestdevice|ndefreader|'
              r'gatt characteristic|physically nearby|'
              r'never bypasses short-range radio|'
              r'bypassshortrangeradioexfiltration|wired usb/serial/hid|'
              r'never grant a short-range radio')))
          .join('\n');
      final String neutered =
          matrixWithSection(realMatrix, withoutShortRange);
      final List<String> missing = missingEvidenceMarkers(neutered);
      expect(missing, contains('no-short-range-radio-exfil'));
      expect(missing, contains('no-web-bluetooth-device'));
      expect(missing, contains('no-web-nfc-write'));
      expect(missing, contains('short-range-gatt-write'));
      expect(missing, contains('short-range-nearby-hardware'));
      expect(missing, contains('short-range-never-bypassed'));
      expect(missing, contains('short-range-policy-getter'));
      expect(missing, contains('short-range-distinct-from-peripheral-io'));
      expect(missing, contains('opt-in-keeps-short-range-denied'));
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
