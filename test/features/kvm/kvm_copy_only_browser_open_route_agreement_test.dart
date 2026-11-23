// EP-U18 (issues #009 / #021): copy-only vs browser-open route agreement
// across the THREE KVM operator surfaces.
//
// The final route is external-browser + copy under productionDefault (no
// in-app WebView, no self-signed acceptance). Two dept guards already cover
// adjacent halves: EP-U8 pins that the gated-list card's "Open console"
// affordance tracks `canOpenConsole` (including one CRLF console), and EP-U17
// pins the absence of render/TLS affordances plus generic copy/browser
// guidance on all three surfaces — but only for CLEAN (secure / external-client)
// targets. Nothing drove ONE manager whose graphical ConnectUri is
// control-bearing (so `planConsoleLaunch` degrades to copyOnly) through the
// per-console card, the capability card AND the viewer together, pinning that
// the copy-only route never surfaces a browser-open / render affordance on any
// surface while a clean secure-HTTPS target keeps its copy + browser guidance.
// A one-sided view edit could add a browser-open button/guidance to a
// control-unsafe target and still pass every single-surface suite.
//
// AUDIT (2026-11-23): the capability card is display-only and, by design, does
// not print browser guidance for a clean secure-HTTPS target (it shows the
// merged "Resolved URI" row plus transport warnings for insecure/external
// endpoints only). Per the EP-U16 precedent the positive route half is
// therefore narrowed to what genuinely exists on each surface: the viewer's
// single-source `kvmLaunchStatusText` and the console card's
// "open via BMC web UI" hint carry the browser-open guidance; the capability
// card keeps its merged copy/resolved-URI row. The NEGATIVE invariant (no
// browser-open / render affordance for a control-unsafe target) is pinned
// across all three. Display-only, dependency-free and TLS-safe: no URL opened,
// no WebView/protocol import, production TLS untouched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_capability_card.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A CRLF-bearing "HTTPS" graphical URI: `Uri.tryParse` silently folds the
/// control chars into the target, so the fail-closed plan degrades to copyOnly.
const String _unsafeUri = 'https://bmc.example/remote\r\nX-Injected: 1';

/// A genuine secure-HTTPS graphical URI: copy + browser-open route.
const String _safeUri = 'https://bmc.example/remote';

/// An imperative instruction to open THE RESOLVED URI in a browser now — the
/// affordance the copy-only route must never offer. Deliberately does NOT match
/// the honest "HTML5 console — open via BMC web UI." hint (a separate trusted
/// path, `via` not `in ... browser`) nor "before opening it in a browser"
/// (configure-HTTPS guidance, `opening` not the bare imperative `open`).
final RegExp _browserOpenAffordance = RegExp(
  r'\bopen\b.{0,48}\b(?:in|with|using)\b.{0,16}\b(?:web\s*)?browser\b',
  caseSensitive: false,
);

/// A short imperative render/in-app affordance (the human-gated render route).
final RegExp _renderAffordance = RegExp(
  r'^\s*(?:render|open|view|launch|embed|display|show|connect|start|stream)\b'
  r'.{0,64}\b(?:in[\s-]?app|embedded|webview|inside the app)\b',
  caseSensitive: false,
);

class _StubController extends KvmController {
  _StubController()
      : super(service: KvmService(client: null, systemId: 'bmc1'));

  @override
  Future<void> load() async {}
}

SystemHandle _handle() => const SystemHandle(
      profile: ConnectionProfile(id: 'bmc1', host: 'localhost'),
      features: SystemFeatures(systemId: 'bmc1', kvm: true),
    );

/// One manager with a single enabled graphical HTML5 console whose ConnectUri
/// is [uri]. Both KVM projections are built from the SAME body so the three
/// surfaces cannot disagree about the resolved target.
Map<String, dynamic> _managerBody(String uri) => <String, dynamic>{
      '@odata.id': '/redfish/v1/Managers/BMC',
      'GraphicalConsole': <String, dynamic>{
        'ServiceEnabled': true,
        'ConnectTypesSupported': <dynamic>['HTML5'],
        'ConnectUri': uri,
      },
    };

KvmConsole _console(Map<String, dynamic> body) =>
    KvmConsole.fromManager(body, managerId: 'BMC').single;

KvmCapability _capability(Map<String, dynamic> body) =>
    KvmCapability.fromManager(body, managerId: 'BMC');

/// Pumps the real `KvmView` (capability card + every per-console card) from one
/// manager body. A tall viewport keeps the lazy console list built.
Future<void> _pumpKvmView(
  WidgetTester tester, {
  required Map<String, dynamic> body,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<KvmConsole> consoles =
      KvmConsole.fromManager(body, managerId: 'BMC');
  final KvmCapability capability =
      KvmCapability.fromManager(body, managerId: 'BMC');
  final KvmController controller = _StubController()
    ..state = KvmUiState(
      consoles: consoles,
      primaryConsole: KvmService.pickPrimary(consoles),
    );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) =>
              Future<List<KvmCapability>>.value(<KvmCapability>[capability]),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(WidgetTester tester, KvmConsole console) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: <KvmConsole>[console]);
  await tester.pumpWidget(
    ProviderScope(
      // Keep the override count at 3 (matching _pumpKvmView): Riverpod asserts
      // a stable overrides length across ProviderScope pumps in one test.
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(<KvmCapability>[]),
        ),
      ],
      child: MaterialApp(home: KvmConsoleViewerPage(console: console)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every visible Text/SelectableText string in the pumped tree — an affordance
/// may be a bare Text child, so scanning rendered copy (not only Button widgets)
/// is the fail-closed surface. Announced copy is checked separately.
Set<String> _renderedLabels(WidgetTester tester) {
  final Set<String> labels = <String>{};
  for (final Widget w in tester
      .widgetList<Widget>(find.byWidgetPredicate((Widget _) => true))) {
    if (w is Text && w.data != null) labels.add(w.data!);
    if (w is SelectableText && w.data != null) labels.add(w.data!);
  }
  return labels;
}

void _expectNoBrowserOpenOrRenderAffordance(
  WidgetTester tester,
  String surface,
) {
  for (final String label in _renderedLabels(tester)) {
    expect(_browserOpenAffordance.hasMatch(label), isFalse,
        reason: '$surface must never offer browser-open guidance "$label" '
            'for a copy-only / control-unsafe target');
    expect(_renderAffordance.hasMatch(label), isFalse,
        reason: '$surface must never offer render affordance "$label"');
  }
  for (final RegExp pattern in <RegExp>[
    _browserOpenAffordance,
    _renderAffordance
  ]) {
    expect(find.bySemanticsLabel(pattern), findsNothing,
        reason: '$surface must not announce a browser-open/render affordance '
            'matching ${pattern.pattern}');
  }
}

void main() {
  group('EP-U18 model route agreement (#009/#021)', () {
    test('control-unsafe graphical target is copyOnly on console + capability',
        () {
      final Map<String, dynamic> body = _managerBody(_unsafeUri);
      final KvmConsole console = _console(body);
      final KvmCapability capability = _capability(body);

      expect(console.launchPlan.isCopyOnly, isTrue,
          reason: 'a control-bearing target must degrade to copyOnly');
      expect(console.launchPlan.targetUri, isNull);
      expect(console.hasSecureLaunchUri, isFalse);
      expect(console.canOpenConsole, isFalse);
      // Both projections resolve the same byte-exact (unsafe) URI; the plan,
      // not the display value, is what fails closed.
      expect(console.launchUri, capability.launchUri);
      expect(capability.hasUri, isTrue);
      expect(capability.hasSecureLaunchUri, isFalse);
    });

    test('clean secure-HTTPS target is browser-open + openable on console', () {
      final Map<String, dynamic> body = _managerBody(_safeUri);
      final KvmConsole console = _console(body);
      final KvmCapability capability = _capability(body);

      expect(console.canOpenConsole, isTrue);
      expect(console.launchPlan.isCopyOnly, isFalse);
      expect(console.launchPlan.targetUri, _safeUri);
      expect(console.hasSecureLaunchUri, isTrue);
      expect(capability.launchUri, _safeUri);
      expect(capability.hasSecureLaunchUri, isTrue);
    });
  });

  group('EP-U18 three-surface rendered agreement (#009/#021)', () {
    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'control-unsafe target: copy-only on all three surfaces, no '
          'browser-open/render affordance at ${width.toStringAsFixed(0)} px',
          (WidgetTester tester) async {
        final Map<String, dynamic> body = _managerBody(_unsafeUri);
        final KvmConsole console = _console(body);
        final KvmCapability capability = _capability(body);
        final String uriLabel = 'Connect URI: ${console.launchUri}';

        await _pumpKvmView(tester, body: body, width: width);

        // Per-console card: no launch affordance, copy row + merged URI node.
        expect(find.text('Open console'), findsNothing,
            reason:
                'copy-only route must not offer "Open console" at $width px');
        expect(find.text('Copy connect info'), findsOneWidget);
        expect(find.bySemanticsLabel(uriLabel), findsOneWidget,
            reason: 'console card keeps its merged control-safe copy row');
        _expectNoBrowserOpenOrRenderAffordance(tester, 'console-card');

        // Capability card: merged "Resolved URI" copy row, no browser/render.
        final Finder card = find.byType(KvmCapabilityCard);
        expect(card, findsOneWidget);
        expect(
          find.descendant(
            of: card,
            matching:
                find.bySemanticsLabel('Resolved URI: ${capability.launchUri}'),
          ),
          findsOneWidget,
          reason: 'capability card keeps its merged copy row at $width px',
        );
        _expectNoBrowserOpenOrRenderAffordance(tester, 'capability-card');
        expect(tester.takeException(), isNull,
            reason: 'no overflow at $width px');

        // Viewer: fail-closed target — no copy affordance, single merged
        // "No direct console URI" node, no browser/render affordance.
        await _pumpViewer(tester, console);
        expect(find.text('Copy console URI'), findsNothing,
            reason: 'viewer has no copy affordance for a copy-only target');
        expect(
          find.bySemanticsLabel(RegExp(r'^No direct console URI\.')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(kvmLaunchStatusText(KvmLaunchStrategy.noUri)),
          findsOneWidget,
          reason: 'viewer status is the single-source fail-closed guidance',
        );
        _expectNoBrowserOpenOrRenderAffordance(tester, 'viewer');
        expect(tester.takeException(), isNull,
            reason: 'no overflow at $width px');
      });

      testWidgets(
          'clean secure target: merged copy + browser guidance preserved at '
          '${width.toStringAsFixed(0)} px', (WidgetTester tester) async {
        final Map<String, dynamic> body = _managerBody(_safeUri);
        final KvmConsole console = _console(body);
        final KvmCapability capability = _capability(body);

        await _pumpKvmView(tester, body: body, width: width);

        // Console card: openable + copy, both announced with their visible
        // labels; the HTML5 web-UI hint is the browser-open guidance here.
        expect(find.text('Open console'), findsOneWidget);
        expect(find.bySemanticsLabel('Open console'), findsOneWidget);
        expect(find.text('Copy connect info'), findsOneWidget);
        expect(find.bySemanticsLabel('Copy connect info'), findsOneWidget);
        expect(
          find.bySemanticsLabel('HTML5 console — open via BMC web UI.'),
          findsOneWidget,
          reason: 'console card keeps its browser-open hint at $width px',
        );
        expect(
          find.bySemanticsLabel('Connect URI: $_safeUri'),
          findsOneWidget,
        );

        // Capability card keeps its merged resolved-URI copy row (display-only
        // by design: no browser button on this surface).
        final Finder card = find.byType(KvmCapabilityCard);
        expect(
          find.descendant(
            of: card,
            matching:
                find.bySemanticsLabel('Resolved URI: ${capability.launchUri}'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull,
            reason: 'no overflow at $width px');

        // Viewer: single-source browser-open status + copy affordance, merged.
        await _pumpViewer(tester, console);
        final String status = kvmLaunchStatusText(console.launchStrategy);
        expect(status, contains('browser'),
            reason: 'secure target status carries browser-open guidance');
        expect(find.bySemanticsLabel(status), findsOneWidget);
        expect(find.text('Copy console URI'), findsOneWidget);
        expect(find.bySemanticsLabel('Copy console URI'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Console URI: $_safeUri'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull,
            reason: 'no overflow at $width px');
      });
    }
  });
}
