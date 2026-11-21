// EP-P4 / RP-1 — guard for the detailed per-target validation-evidence
// acceptance checklist in WEBVIEW_TLS_MATRIX.md.
//
// The resolved decision is: production never embeds a WebView, never accepts a
// self-signed certificate, and keeps the external-browser + copy fallback
// byte-for-byte. Flipping the flag, adding a rendering dependency or enabling a
// test-only TLS opt-in is HUMAN-gated on recorded per-target evidence. This
// test pins the *detailed* acceptance checklist (CSP / mixed-content,
// fullscreen, input forwarding, no-native-bridge, no-local-file-access,
// no-device-permissions, flag-off fallback, human sign-off) so a future edit
// cannot silently erase the evidence boxes that gate that decision.
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
  (
    name: 'origin-navigation-confinement',
    marker: 'origin / navigation confinement'
  ),
  (name: 'no-cross-origin-nav', marker: 'same origin'),
  (name: 'no-nav-downgrade', marker: 'plaintext / non-https scheme'),
  (name: 'test-profile-only-opt-in', marker: 'test-profile-only'),
  (name: 'csp', marker: 'content-security-policy'),
  (name: 'mixed-content', marker: 'mixed-content'),
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
