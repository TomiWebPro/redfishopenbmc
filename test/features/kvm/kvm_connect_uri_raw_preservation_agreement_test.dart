/// RM-23 (issue #009/#021): hostile `ConnectUri` raw-value preservation
/// agreement across BOTH `fromManager` factories.
///
/// A Redfish manager publishes one console endpoint in two shapes: the
/// per-console card reads `KvmConsole.fromManager(...).connectUri`, while the
/// per-manager capability card reads `KvmCapability.fromManager(...).uri`
/// (resolved through `resolveLaunchUri`). Both are subsequently fed to the
/// SAME fail-closed launch classifier / plan. If one factory trimmed, escaped,
/// percent-normalised or sanitised a hostile raw value while the other kept it
/// byte-for-byte, the two cards would hand DIFFERENT strings to the classifier
/// — a one-sided desync that could re-open a clipboard/authority-injection
/// vector while every single-factory suite stayed GREEN.
///
/// Both factories currently route the raw value through a mirrored
/// trim-only helper (`KvmConsole._uriString` / `KvmCapability._nonEmptyString`)
/// that strips leading/trailing whitespace but preserves EMBEDDED C0/DEL
/// controls, bidi/format marks and hostile scheme spellings verbatim; their
/// derived transport classifiers share one hardened core. This guard pins that
/// contract over a hostile matrix at the model layer (raw byte equality +
/// derived-flag agreement + fail-closed launch plan), so a one-sided
/// "sanitise the display string" refactor fails closed.
///
/// Read-only, dependency-free and TLS-safe: no URL is opened, no WebView or
/// protocol dependency imported, production TLS untouched, no behaviour
/// decision folded in.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// One hostile / control-bearing / spoofed `ConnectUri` case.
class _Case {
  const _Case(this.name, this.raw, {this.secure = false});

  final String name;
  final String raw;

  /// Whether the trimmed value is a genuinely secure HTTPS endpoint that both
  /// factories must classify as secure (the clean controls).
  final bool secure;
}

const List<_Case> kCases = <_Case>[
  // Embedded C0 / DEL controls: a plain trim must NOT remove them.
  _Case('lf', 'https://bmc.example/con\nsol'),
  _Case('crlf', 'https://bmc.example/con\r\nsol'),
  _Case('nul', 'https://bmc.example/con\u0000sol'),
  _Case('tab', 'https://bmc.example/con\tsol'),
  _Case('del', 'https://bmc.example/con\u007Fsol'),
  // Unicode format / bidi marks are not whitespace — trim leaves them intact.
  _Case('rlo', 'https://bmc.example/\u202Evm'),
  _Case('lro', 'https://bmc.example/\u202Dvm'),
  _Case('word-joiner', 'https://bmc\u2060.example/vm'),
  // Hostile scheme / authority spellings survive the raw-value pass-through.
  _Case('scheme-relative', '//bmc.example/kvm'),
  _Case('data-scheme', 'data:text/html,<script>x</script>'),
  _Case('javascript-scheme', 'javascript:alert(1)'),
  _Case('file-scheme', 'file:///etc/passwd'),
  // Clean controls: both factories trim padding and keep a valid endpoint.
  _Case('padded-secure', '  https://bmc.example/kvm  ', secure: true),
  _Case('clean-secure', 'https://bmc.example/kvm', secure: true),
];

Map<String, dynamic> _body(String connectUri) => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectUri': connectUri,
        'ConnectTypesSupported': <dynamic>['HTML5', 'KVMIP'],
      },
    };

void main() {
  group('RM-23 raw ConnectUri preservation — fixture liveness (#009/#021)', () {
    test('hostile bytes are actually present in the fixture inputs', () {
      // Guards against a future "sanitise the fixture" edit making the
      // preservation assertions vacuous.
      expect('https://bmc.example/con\r\nsol'.codeUnits, contains(0x0D));
      expect('https://bmc.example/con\r\nsol'.codeUnits, contains(0x0A));
      expect('https://bmc.example/con\u0000sol'.codeUnits, contains(0x00));
      expect('https://bmc.example/con\u007Fsol'.codeUnits, contains(0x7F));
      expect('https://bmc.example/\u202Evm'.codeUnits, contains(0x202E));
      expect('https://bmc\u2060.example/vm'.codeUnits, contains(0x2060));
      // trim() strips only the edges of the padded control — the embedded
      // controls above survive it.
      expect('  https://bmc.example/kvm  '.trim(), 'https://bmc.example/kvm');
    });
  });

  group('RM-23 cross-factory raw-value agreement (#009/#021)', () {
    for (final _Case item in kCases) {
      test('${item.name}: both factories surface the same raw bytes', () {
        final Map<String, dynamic> body = _body(item.raw);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').first;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        // The core RM-23 invariant: the raw value each card hands downstream
        // is byte-identical (no one-sided trim/escape/percent-normalise).
        expect(console.connectUri, isNotNull, reason: item.name);
        expect(capability.uri, isNotNull, reason: item.name);
        expect(console.connectUri!.codeUnits, capability.uri!.codeUnits,
            reason: '${item.name}: raw code units must agree');

        // Derived values built from that raw string also agree.
        expect(console.launchUri, capability.launchUri, reason: item.name);
        expect(console.hasSecureLaunchUri, capability.hasSecureLaunchUri,
            reason: item.name);
        expect(console.hasHttpLaunchUri, capability.hasHttpLaunchUri,
            reason: item.name);
        expect(capability.hasUri, console.launchUri != null, reason: item.name);
      });
    }
  });

  group('RM-23 embedded hostile bytes survive both factories (#009/#021)', () {
    const List<_Case> embedded = <_Case>[
      _Case('crlf', 'https://bmc.example/con\r\nsol'),
      _Case('nul', 'https://bmc.example/con\u0000sol'),
      _Case('bidi-rlo', 'https://bmc.example/\u202Evm'),
      _Case('word-joiner', 'https://bmc\u2060.example/vm'),
    ];
    for (final _Case item in embedded) {
      test('${item.name}: neither factory sanitises the embedded bytes', () {
        final Map<String, dynamic> body = _body(item.raw);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').first;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        for (final int unit in item.raw.codeUnits) {
          // The raw control/format byte is still present in BOTH stored values.
          expect(console.connectUri!.codeUnits, contains(unit),
              reason:
                  'console lost U+${unit.toRadixString(16)} (${item.name})');
          expect(capability.uri!.codeUnits, contains(unit),
              reason:
                  'capability lost U+${unit.toRadixString(16)} (${item.name})');
        }
        // A control-bearing target is never secure on either surface.
        expect(console.hasSecureLaunchUri, isFalse, reason: item.name);
        expect(capability.hasSecureLaunchUri, isFalse, reason: item.name);
      });
    }
  });

  group('RM-23 fail-closed launch plan agrees (#009/#021)', () {
    test(
        'hostile / non-secure targets never reach an in-app certificate '
        'acceptance route', () {
      for (final _Case item in kCases.where((_Case c) => !c.secure)) {
        final Map<String, dynamic> body = _body(item.raw);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').first;
        final plan = console.launchPlan;
        expect(plan.isInApp, isFalse, reason: item.name);
        expect(plan.acceptSelfSigned, isFalse, reason: item.name);
        expect(plan.isCopyOnly, isTrue, reason: item.name);
      }
    });

    test('clean secure controls agree byte-for-byte across both factories', () {
      for (final _Case item in kCases.where((_Case c) => c.secure)) {
        final Map<String, dynamic> body = _body(item.raw);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').first;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        expect(console.connectUri, 'https://bmc.example/kvm',
            reason: item.name);
        expect(capability.uri, 'https://bmc.example/kvm', reason: item.name);
        expect(console.hasSecureLaunchUri, isTrue, reason: item.name);
        expect(capability.hasSecureLaunchUri, isTrue, reason: item.name);
        expect(console.launchPlan.isExternalBrowser, isTrue, reason: item.name);
        expect(console.launchPlan.targetUri, 'https://bmc.example/kvm',
            reason: item.name);
        expect(console.launchPlan.acceptSelfSigned, isFalse, reason: item.name);
      }
    });
  });
}
