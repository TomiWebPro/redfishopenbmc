/// RM-29 (issue #009/#021): relative / opaque console `ConnectUri`
/// cross-factory fail-closed agreement.
///
/// A Redfish manager publishes one console endpoint in two shapes: the
/// per-console card reads `KvmConsole.fromManager(...).connectUri`, while the
/// per-manager capability card reads `KvmCapability.fromManager(...).uri`
/// (resolved through `resolveLaunchUri`). Both are subsequently fed to the SAME
/// fail-closed launch classifier / plan. If one factory "helpfully" resolved a
/// relative `/kvm` against the manager base, or normalised an opaque
/// `mailto:` / scheme-relative `//host/kvm` form, while the other kept it
/// byte-for-byte, the two cards would hand DIFFERENT strings to the classifier
/// — a one-sided desync that could turn a relative path into a different,
/// possibly cross-origin, target on one card while the other fails closed, with
/// every single-surface suite GREEN.
///
/// RM-23 already pins hostile EMBEDDED-CONTROL / absolute hostile-scheme raw
/// preservation across both factories. This guard extends that contract to the
/// RELATIVE-PATH / SCHEME-RELATIVE / OPAQUE / QUERY-ONLY family (which RM-23's
/// matrix does not sweep), and adds the fields RM-23 does not pin: derived
/// transport classifier agreement, fail-closed launch plan, control-safe
/// clipboard fallback, and never-throw on a non-string `ConnectUri`.
///
/// Both factories currently route the raw value through mirrored trim-only
/// helpers (`KvmConsole._uriString` / `KvmCapability._nonEmptyString`) and share
/// one hardened classifier core, so agreement holds BY CONSTRUCTION; this is a
/// read-only characterization that fails closed against a one-sided resolve /
/// normalise refactor. No URL is opened, no WebView / protocol dependency is
/// imported, no behaviour decision is folded in, production TLS is untouched.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';

/// One relative / opaque / control-bearing `ConnectUri` case.
class _Case {
  const _Case(this.name, this.raw, {this.secure = false, this.control = false});

  final String name;
  final String raw;

  /// A genuinely secure HTTPS endpoint: both factories classify it secure and
  /// the production launch plan offers the external-browser route.
  final bool secure;

  /// Whether the value carries a raw C0/DEL/bidi control byte that the shared
  /// control-safety gate must keep off the copyable target.
  final bool control;
}

const List<_Case> kCases = <_Case>[
  // Relative paths: a one-sided "resolve against manager base" edit would turn
  // these into full URLs on one card while the other keeps the relative form.
  _Case('rel-bare', 'kvm'),
  _Case('rel-root', '/kvm'),
  _Case('rel-dot', './kvm'),
  _Case('rel-dotdot', '../kvm'),
  _Case('rel-nested', 'redfish/v1/console'),
  // Scheme-relative: no scheme, but a hostile authority when made absolute.
  _Case('scheme-relative', '//bmc.example/kvm'),
  // Opaque / non-hierarchical forms: no authority to resolve against.
  _Case('opaque-https', 'https:opaque'),
  _Case('opaque-mailto', 'mailto:admin@bmc.example'),
  _Case('opaque-javascript', 'javascript:alert(1)'),
  _Case('opaque-data', 'data:text/plain,x'),
  // Query / fragment only: not an endpoint at all.
  _Case('query-only', '?redirect=/kvm'),
  _Case('fragment-only', '#console'),
  // Relative-shaped values carrying a control / bidi byte: raw-preserved by
  // both factories like RM-23, but the copyable target must fail closed.
  _Case('rel-crlf', '/kvm\r\nX-Admin: true', control: true),
  _Case('rel-nul', './kvm\u0000sol', control: true),
  _Case('rel-bidi', '/kvm\u202Evm', control: true),
  // Clean control: byte-exact, secure, external-browser on both surfaces.
  _Case('clean-secure', 'https://bmc.example/kvm', secure: true),
];

Map<String, dynamic> _body(Object? connectUri) => <String, dynamic>{
      // Deliberately no per-block '@odata.id': it must not mask a null
      // ConnectUri in the capability factory's resource-link fallback.
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectUri': connectUri,
        'ConnectTypesSupported': <dynamic>['HTML5'],
      },
    };

void main() {
  group('RM-29 fixture liveness (#009/#021)', () {
    test('matrix actually contains the relative / opaque / control family', () {
      expect(kCases.any((_Case c) => c.raw.startsWith('/kvm')), isTrue);
      expect(kCases.any((_Case c) => c.raw.startsWith('//')), isTrue);
      expect(kCases.any((_Case c) => c.raw.startsWith('mailto:')), isTrue);
      expect(kCases.any((_Case c) => c.raw.startsWith('?')), isTrue);
      expect(kCases.any((_Case c) => c.raw.startsWith('#')), isTrue);
      expect(kCases.any((_Case c) => c.control), isTrue);
      expect(kCases.any((_Case c) => c.secure), isTrue);
      // A plain trim does NOT remove an embedded control byte.
      expect('/kvm\r\nX-Admin: true'.codeUnits, contains(0x0D));
    });
  });

  group('RM-29 cross-factory raw + classifier agreement (#009/#021)', () {
    for (final _Case item in kCases) {
      test('${item.name}: both factories agree field-for-field', () {
        final Map<String, dynamic> body = _body(item.raw);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').single;
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');

        // Neither factory resolves / normalises the raw value.
        expect(console.connectUri, isNotNull, reason: item.name);
        expect(capability.uri, isNotNull, reason: item.name);
        expect(console.connectUri!.codeUnits, capability.uri!.codeUnits,
            reason: '${item.name}: raw code units must be identical');
        expect(console.launchUri, capability.launchUri, reason: item.name);
        expect(capability.hasUri, console.launchUri != null, reason: item.name);

        // Derived transport classifiers share one hardened core.
        expect(console.hasSecureLaunchUri, capability.hasSecureLaunchUri,
            reason: item.name);
        expect(console.hasHttpLaunchUri, capability.hasHttpLaunchUri,
            reason: item.name);
        expect(console.usesInsecureHttpLaunchUri,
            capability.usesInsecureHttpLaunchUri,
            reason: item.name);
        expect(console.requiresExternalConsoleClient,
            capability.requiresExternalConsoleClient,
            reason: item.name);

        // Only a real HTTPS endpoint is secure; relative / opaque forms are
        // never offered as an in-app or browser launch target.
        expect(console.hasSecureLaunchUri, item.secure, reason: item.name);
        expect(capability.hasSecureLaunchUri, item.secure, reason: item.name);
      });
    }
  });

  group('RM-29 fail-closed launch plan + clipboard (#009/#021)', () {
    for (final _Case item in kCases) {
      test('${item.name}: no in-app route, no self-signed, safe copy target',
          () {
        final Map<String, dynamic> body = _body(item.raw);
        final KvmConsole console =
            KvmConsole.fromManager(body, managerId: 'BMC').single;
        final plan = console.launchPlan;

        expect(plan.isInApp, isFalse, reason: item.name);
        expect(plan.acceptSelfSigned, isFalse, reason: item.name);
        if (item.secure) {
          expect(plan.isExternalBrowser, isTrue, reason: item.name);
          expect(plan.targetUri, 'https://bmc.example/kvm', reason: item.name);
          expect(console.canOpenConsole, isTrue, reason: item.name);
        } else {
          expect(plan.isCopyOnly, isTrue, reason: item.name);
          expect(console.canOpenConsole, isFalse, reason: item.name);
        }

        // The copyable target is exactly the plan's fail-closed target, with
        // the control-safe manager path as the fallback. A control-bearing
        // value can never leak a raw C0/DEL/bidi byte onto the clipboard.
        expect(console.clipboardTargetUri,
            plan.targetUri ?? console.safeManagerUri,
            reason: item.name);
        for (final int unit in console.clipboardTargetUri.codeUnits) {
          if (unit < 0x20 ||
              unit == 0x7F ||
              (unit >= 0x202A && unit <= 0x202E)) {
            fail('${item.name}: control byte U+${unit.toRadixString(16)} '
                'escaped into the copyable target');
          }
        }
      });
    }
  });

  group('RM-29 non-string ConnectUri never throws (#009/#021)', () {
    for (final Object? value in <Object?>[
      42,
      true,
      <dynamic>['kvm'],
      <String, dynamic>{'uri': 'kvm'},
    ]) {
      test('${value.runtimeType}: both factories stay fail-closed', () {
        final Map<String, dynamic> body = _body(value);
        final List<KvmConsole> consoles =
            KvmConsole.fromManager(body, managerId: 'BMC');
        final KvmCapability capability =
            KvmCapability.fromManager(body, managerId: 'BMC');
        expect(consoles, hasLength(1));
        expect(consoles.single.connectUri, isNull);
        expect(capability.uri, isNull);
        expect(consoles.single.launchPlan.isCopyOnly, isTrue);
        expect(consoles.single.launchPlan.targetUri, isNull);
        expect(
            consoles.single.clipboardTargetUri, consoles.single.safeManagerUri);
      });
    }
  });
}
