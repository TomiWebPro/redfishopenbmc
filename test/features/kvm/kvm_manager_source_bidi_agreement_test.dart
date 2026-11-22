// RM-15 (epic #009 / #021): the per-console card (`KvmConsole.fromManager`) and
// the per-manager capability card (`KvmCapability.fromManager`) read the SAME
// BMC-supplied manager body. Both route the `@odata.id` through
// `kvmManagerSourceUri` and expose a control-safe `safeManagerUri` (the single
// source for the rendered source row and the clipboard fallback), and both
// classify the resolved `ConnectUri` through the shared fail-closed classifier.
//
// AUDIT (before adding this guard): `kvm_model_test.dart` /
// `kvm_capability_test.dart` pin CRLF / NUL / raw-space / backslash / `%` /
// ZWSP / NBSP / U+2028 line-separator hostile `@odata.id` values and the
// `launch_plan_test.dart` suite pins bidi / confusable AUTHORITIES. Nothing,
// however, feeds the bidi FORMAT family (RLO/LRO, bidi isolates, direction
// marks, word-joiner, BOM) through BOTH `fromManager` factories over an
// `@odata.id` RESOURCE PATH (where the authority-scoped non-ASCII rule does not
// apply), nor pins the cross-factory agreement for confusable hosts. A one-sided
// gate edit could let a bidi marker leak onto one card's source row / clipboard
// while the other card and every single-surface suite stayed GREEN.
//
// Regression guard at a genuinely unguarded seam, not churn: today both
// factories agree byte-for-byte and fail closed. Pure-model, display-only,
// dependency-free and TLS-safe: no URL is opened, no WebView/protocol dependency
// is imported, and production TLS is untouched.

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/platform/launch_plan.dart';
import 'package:redfishopenbmc/features/kvm/platform/webview_policy.dart';

/// Unicode bidi / format / invisible marks (general category `C` = "Other").
/// These are the RM-15 family that the existing tests do NOT cover on the
/// manager-source path (ZWSP/U+2028 are already covered elsewhere).
const List<String> kBidiFormatMarks = <String>[
  '\u202E', // RLO — right-to-left override
  '\u202D', // LRO — left-to-right override
  '\u2066', // LRI — left-to-right isolate
  '\u2067', // RLI — right-to-left isolate
  '\u2068', // FSI — first-strong isolate
  '\u2069', // PDI — pop directional formatting
  '\u200E', // LRM — left-to-right mark
  '\u200F', // RLM — right-to-left mark
  '\u2060', // WJ — word joiner
  '\uFEFF', // BOM — zero-width no-break space
];

/// Compatibility confusables (general category `L` = letter / `N` = number) —
/// an IDN homograph or a fullwidth digit. Category `C`/`Z` rules do not catch
/// these; only the authority-scoped non-ASCII rule does.
const List<String> kConfusables = <String>[
  '\u0430', // Cyrillic small letter a
  '\u0441', // Cyrillic small letter es
  '\u03BF', // Greek small letter omicron
  '\uFF18', // fullwidth digit eight
];

final RegExp _formatMark = RegExp(r'\p{C}', unicode: true);

Map<String, dynamic> _manager({
  required String source,
  required String connectUri,
}) {
  return <String, dynamic>{
    '@odata.id': source,
    'GraphicalConsole': <String, dynamic>{
      'ServiceEnabled': true,
      'ConnectTypesSupported': <dynamic>['HTML5'],
      'ConnectUri': connectUri,
    },
  };
}

void main() {
  group(
      'RM-15 bidi/format @odata.id — both fromManager factories sanitize '
      'identically (#009/#021)', () {
    for (final String mark in kBidiFormatMarks) {
      test(
          'RLO/format U+${mark.codeUnitAt(0).toRadixString(16).toUpperCase()} '
          'in @odata.id fails closed on both views', () {
        const String safeSource = '/redfish/v1/Managers/BMC';
        final Map<String, dynamic> body = _manager(
          source: '/redfish/v1/Managers/BMC${mark}evil',
          connectUri: 'https://bmc.example/console',
        );
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        // The shared control-safety gate rejects the format mark, so both
        // factories synthesize the same clean manager-id fallback path.
        expect(console.safeManagerUri, safeSource);
        expect(capability.safeManagerUri, safeSource);
        expect(console.safeManagerUri, capability.safeManagerUri);
        expect(_formatMark.hasMatch(console.safeManagerUri), isFalse);
        expect(_formatMark.hasMatch(capability.safeManagerUri), isFalse);
      });
    }
  });

  group(
      'RM-15 bidi/confusable ConnectUri authority — both factories fail '
      'closed (#009/#021)', () {
    for (final String mark in <String>[...kBidiFormatMarks, ...kConfusables]) {
      test(
          'hostile authority U+'
          '${mark.codeUnitAt(0).toRadixString(16).toUpperCase()} never gets a '
          'secure badge or a copyable unsafe target', () {
        final Map<String, dynamic> body = _manager(
          source: '/redfish/v1/Managers/BMC',
          connectUri: 'https://bmc${mark}.example/console',
        );
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        // Both models classify through the same fail-closed shared gate.
        expect(console.hasSecureLaunchUri, isFalse);
        expect(capability.hasSecureLaunchUri, isFalse);
        expect(console.canOpenConsole, isFalse);
        expect(console.launchPlan.isExternalBrowser, isFalse);
        expect(console.launchPlan.targetUri, isNull);
        // The copy affordance degrades to the control-safe manager source and
        // never carries the bidi/confusable marker onto a row or a clipboard.
        expect(console.clipboardTargetUri, '/redfish/v1/Managers/BMC');
        expect(_formatMark.hasMatch(console.clipboardTargetUri), isFalse);
        expect(console.clipboardTargetUri, capability.safeManagerUri);
      });
    }
  });

  group(
      'RM-15 confusable @odata.id path — both factories agree byte-for-byte '
      '(no format marker) (#009/#021)', () {
    for (final String confusable in kConfusables) {
      test(
          'homograph U+'
          '${confusable.codeUnitAt(0).toRadixString(16).toUpperCase()} stays '
          'identical on both views', () {
        final String source = '/redfish/v1/Managers/BMC${confusable}';
        final Map<String, dynamic> body = _manager(
          source: source,
          connectUri: 'https://bmc.example/console',
        );
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        // Non-ASCII letters in a resource PATH are valid text (no authority
        // to spoof, no TLS decision): both factories keep it byte-for-byte —
        // the invariant is that they AGREE and emit no format/control marker.
        expect(console.safeManagerUri, source);
        expect(capability.safeManagerUri, source);
        expect(console.safeManagerUri, capability.safeManagerUri);
        expect(_formatMark.hasMatch(console.safeManagerUri), isFalse);
        expect(_formatMark.hasMatch(capability.safeManagerUri), isFalse);
      });
    }
  });

  test(
      'RM-15 combined bidi @odata.id + bidi ConnectUri — full cross-factory '
      'agreement (#009/#021)', () {
    final Map<String, dynamic> body = _manager(
      source: '/redfish/v1/Managers/\u202EBMC\u2069evil',
      connectUri: 'https://bmc\u202E.example/console',
    );
    final KvmConsole console =
        KvmConsole.fromManager(body, managerId: 'BMC').single;
    final KvmCapability capability =
        KvmCapability.fromManager(body, managerId: 'BMC');

    expect(console.safeManagerUri, '/redfish/v1/Managers/BMC');
    expect(capability.safeManagerUri, console.safeManagerUri);
    expect(console.hasSecureLaunchUri, isFalse);
    expect(capability.hasSecureLaunchUri, isFalse);
    expect(console.launchPlan.route, KvmConsoleRenderRoute.copyOnly);
    expect(console.clipboardTargetUri, '/redfish/v1/Managers/BMC');
    // The RM-15 render/clipboard contract is the manager-source disclosure
    // (`safeManagerUri`) and the copy fallback (`clipboardTargetUri`) — the two
    // strings both factories derive from the hostile `@odata.id`. The raw
    // `launchUri` is intentionally kept verbatim (trimmed only) and is made
    // safe by the fail-closed plan, not by sanitising the string itself.
    for (final String rendered in <String>[
      console.safeManagerUri,
      capability.safeManagerUri,
      console.clipboardTargetUri,
    ]) {
      expect(_formatMark.hasMatch(rendered), isFalse, reason: rendered);
    }
  });

  test(
      'RM-15 shared classifier rejects the bidi @odata.id path directly '
      '(the load-bearing gate both factories use) (#009/#021)', () {
    for (final String mark in kBidiFormatMarks) {
      expect(
        isControlSafeConsoleUri('/redfish/v1/Managers/BMC${mark}evil'),
        isFalse,
        reason: 'U+${mark.codeUnitAt(0).toRadixString(16).toUpperCase()}',
      );
    }
    // A legitimate, percent-encoded path stays usable — no valid target lost.
    expect(
      isControlSafeConsoleUri('/redfish/v1/Managers/BMC%20one'),
      isTrue,
    );
  });
}
