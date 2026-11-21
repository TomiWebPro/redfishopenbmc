// EP-P7 (epic #009/#021) — machine-checkable guard for the human-gated KVM
// WebView decision recorded in WEBVIEW_TLS_MATRIX.md / LAUNCH_FALLBACK.md.
//
// The resolved decision is: production never embeds a WebView, never accepts a
// self-signed certificate, and keeps the external-browser + copy fallback
// byte-for-byte. Flipping the flag, adding a `webview_flutter` / `url_launcher`
// dependency or enabling a test-only TLS opt-in is HUMAN-gated on per-target
// validation evidence. EP-P5 pins the import surface and EP-P6 pins the runtime
// route surface; this test pins the DOCUMENTED decision + approval gate so a
// future edit cannot silently erase the recorded gate or the decision it
// guards, and asserts the production policy still keeps the flag OFF.
//
// Deliberately TEST-only, dependency-free, opens no network, grants no human
// approval, imports no plugin, and never touches production TLS (issue #009/#021).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// The two decision docs that must keep recording the gate.
const String matrixDocPath = 'lib/features/kvm/platform/WEBVIEW_TLS_MATRIX.md';
const String fallbackDocPath = 'lib/features/kvm/platform/LAUNCH_FALLBACK.md';

/// The canonical heading of the human approval gate section in the matrix doc.
const String gateHeading = '## human approval gate';

/// Lowercase + collapse all whitespace (incl. newlines). Hyphens are kept so
/// markers such as `self-signed` and `test-only` stay intact.
String normalize(String raw) =>
    raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Decision markers that must remain somewhere in the two decision docs.
const List<({String name, bool inMatrix, String marker})> wholeDocChecks =
    <({String name, bool inMatrix, String marker})>[
  (
    name: 'matrix:no-embedded-webview',
    inMatrix: true,
    marker: 'no embedded webview'
  ),
  (
    name: 'matrix:external-browser-copy',
    inMatrix: true,
    marker: 'external browser + copy'
  ),
  (name: 'matrix:human-approval-gate', inMatrix: true, marker: gateHeading),
  (
    name: 'fallback:external-browser-copy',
    inMatrix: false,
    marker: 'external browser + copy'
  ),
  (name: 'fallback:flag-off', inMatrix: false, marker: 'flag off'),
  (
    name: 'fallback:self-signed-gated',
    inMatrix: false,
    marker: 'self-signed acceptance is gated'
  ),
];

/// Requirements that must remain INSIDE the human approval gate section.
const List<({String name, String marker})> gateSectionChecks =
    <({String name, String marker})>[
  (name: 'gate:linux-evidence', marker: 'linux'),
  (name: 'gate:mobile-evidence', marker: 'mobile'),
  (name: 'gate:webview-dependency-named', marker: 'webview_flutter'),
  (name: 'gate:url-launcher-dependency-named', marker: 'url_launcher'),
  (name: 'gate:test-only-tls-opt-in', marker: 'test-only tls opt-in'),
  (name: 'gate:human-sign-off', marker: 'sign-off'),
];

/// Returns the raw human approval gate section (from its heading to the next
/// same-level heading), or '' when the heading is absent.
String rawHumanGateSection(String rawMatrix) {
  final String lower = rawMatrix.toLowerCase();
  final int start = lower.indexOf(gateHeading);
  if (start < 0) return '';
  final int bodyStart = start + gateHeading.length;
  final int next = lower.substring(bodyStart).indexOf(RegExp(r'\n## '));
  final String body = next < 0
      ? rawMatrix.substring(bodyStart)
      : rawMatrix.substring(bodyStart, bodyStart + next);
  return body.trim();
}

/// Rebuilds a matrix doc whose gate section is replaced by [section].
String matrixWithSection(String realMatrix, String section) {
  final int start = realMatrix.toLowerCase().indexOf(gateHeading);
  if (start < 0) return realMatrix;
  return '${realMatrix.substring(0, start)}$section\n';
}

/// Returns the NAMES of every missing human-gate requirement. Empty == green.
List<String> missingHumanGateMarkers(String matrixRaw, String fallbackRaw) {
  final String matrix = normalize(matrixRaw);
  final String fallback = normalize(fallbackRaw);
  final String section = normalize(rawHumanGateSection(matrixRaw));
  final List<String> missing = <String>[];

  for (final ({String name, bool inMatrix, String marker}) check
      in wholeDocChecks) {
    final String doc = check.inMatrix ? matrix : fallback;
    if (!doc.contains(check.marker)) missing.add(check.name);
  }
  for (final ({String name, String marker}) check in gateSectionChecks) {
    if (!section.contains(check.marker)) missing.add(check.name);
  }
  return missing;
}

void main() {
  // flutter test runs from the repo root, so these relative paths resolve.
  final String realMatrix = File(matrixDocPath).readAsStringSync();
  final String realFallback = File(fallbackDocPath).readAsStringSync();
  const KvmWebViewPolicy production = KvmWebViewPolicy.productionDefault;

  group('EP-P7 human-gate decision-doc guard', () {
    test('gate is non-trivial and the real docs contain its section', () {
      expect(wholeDocChecks.length + gateSectionChecks.length,
          greaterThanOrEqualTo(12));
      expect(rawHumanGateSection(realMatrix), isNotEmpty);
    });

    test('real decision docs record the no-WebView decision + human gate', () {
      expect(missingHumanGateMarkers(realMatrix, realFallback), isEmpty);
    });

    test('RED: removing the gate section fails closed', () {
      final String cut = realMatrix.substring(
        0,
        realMatrix.toLowerCase().indexOf(gateHeading),
      );
      final List<String> missing = missingHumanGateMarkers(cut, realFallback);
      expect(missing, isNotEmpty);
      expect(missing, contains('matrix:human-approval-gate'));
      // The section-scoped evidence requirements also vanish with it.
      expect(missing, contains('gate:mobile-evidence'));
    });

    test('RED: erasing the fallback final-route marker fails closed', () {
      final String neutered = realFallback.replaceAll(
          RegExp(r'external browser \+ copy', caseSensitive: false),
          'the in-app WebView route');
      expect(missingHumanGateMarkers(realMatrix, neutered),
          contains('fallback:external-browser-copy'));
    });

    test('RED: dropping a per-target evidence box fails closed', () {
      final String section = rawHumanGateSection(realMatrix);
      final String withoutMobile = section
          .split('\n')
          .where((String line) => !line.toLowerCase().contains('mobile'))
          .join('\n');
      final String neutered = matrixWithSection(realMatrix, withoutMobile);
      expect(missingHumanGateMarkers(neutered, realFallback),
          contains('gate:mobile-evidence'));
    });
  });

  group('EP-P7 production policy keeps the WebView flag OFF', () {
    test('productionDefault is disabled with strict TLS and no self-signed',
        () {
      expect(production.enabled, isFalse);
      expect(production.tlsMode, KvmWebViewTlsMode.strict);
      expect(production.acceptsSelfSigned, isFalse);
    });

    test('productionDefault never permits in-app rendering or self-signed', () {
      for (final bool hasSecureUri in <bool>[true, false]) {
        for (final bool isHtml5 in <bool>[true, false]) {
          for (final bool isEnabled in <bool>[true, false]) {
            expect(
              production.permitsInAppRendering(
                hasSecureUri: hasSecureUri,
                isHtml5: isHtml5,
                isEnabled: isEnabled,
              ),
              isFalse,
            );
            expect(
              production.mayAcceptSelfSigned(
                hasSecureUri: hasSecureUri,
                isHtml5: isHtml5,
                isEnabled: isEnabled,
              ),
              isFalse,
            );
          }
        }
      }
    });

    test('only the test-only opt-in may accept self-signed, HTTPS only', () {
      const KvmWebViewPolicy optIn = KvmWebViewPolicy.testOptIn;
      expect(optIn.enabled, isTrue);
      expect(optIn.acceptsSelfSigned, isTrue);
      expect(
        optIn.mayAcceptSelfSigned(
          hasSecureUri: true,
          isHtml5: true,
          isEnabled: true,
        ),
        isTrue,
      );
      expect(
        optIn.mayAcceptSelfSigned(
          hasSecureUri: false,
          isHtml5: true,
          isEnabled: true,
        ),
        isFalse,
      );
    });
  });
}
