// EP-U7 / #009 / #021: RU-2 full merged-Semantics SURFACE audit for the two
// shared notices (`kvmSessionPersistenceNotice`, `kvmDisabledOnBmcNotice`).
//
// The copy itself is already single-sourced by `kvm_transport_notice.dart` and
// mechanically pinned by `test/tool/notice_single_source_guard_test.dart`
// (constants) + `kvm_openbmc_fixture_test.dart`/widget spot tests. What was
// never pinned is the RENDERING contract across all four KVM surfaces:
//
//   * `kvmSessionPersistenceNotice` belongs on the gated list `KvmView` and on
//     the `KvmConsoleViewerPage` — once each, never duplicated by the per-console
//     cards or the capability cards.
//   * `kvmDisabledOnBmcNotice` belongs on each disabled `KvmCapabilityCard` —
//     exactly once per disabled card, never on an enabled one or on the other
//     surfaces.
//   * On every surface the visible `Text` and the announced (merged
//     `excludeSemantics`) label must be the SAME shared string, on ONE node.
//
// A future edit that drops a notice, renders it twice, or splits the visible
// text from the a11y label would silently regress screen-reader parity; this
// suite fails closed on all three. Display-only, dependency-free, TLS-safe:
// no URL opened, no WebView/protocol import, no production TLS change.

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
import 'package:redfishopenbmc/features/kvm/views/kvm_transport_notice.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op so the gated view can be seeded
/// without touching the network (mirrors the established widget-test stub).
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

KvmConsole _console(String managerId) => KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: managerId,
      connectTypesSupported: const <String>['KVMIP'],
      serviceEnabled: true,
      connectUri: 'https://bmc.example/kvm',
      sourceManagerUri: '/redfish/v1/Managers/$managerId',
    );

KvmCapability _capability(String managerId, {required bool enabled}) =>
    KvmCapability(
      managerId: managerId,
      supported: true,
      connectTypes: const <String>['KVMIP', 'HTML5'],
      serviceEnabled: enabled,
      uri: 'https://bmc.example/kvm',
      sourceManagerUri: '/redfish/v1/Managers/$managerId',
    );

/// The single merged `excludeSemantics` node whose label is exactly [notice].
Finder _mergedNotice(String notice) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == notice,
    );

/// Asserts one merged node announces exactly [notice] AND the single visible
/// `Text` with that wording sits inside that same node (visible == announced).
void _expectOneMergedNotice(WidgetTester tester, String notice) {
  expect(find.text(notice), findsOneWidget,
      reason: 'exactly one visible "$notice"');
  expect(_mergedNotice(notice), findsOneWidget,
      reason: 'exactly one merged a11y node for "$notice"');
  expect(
    find.ancestor(
      of: find.text(notice),
      matching: _mergedNotice(notice),
    ),
    findsOneWidget,
    reason: 'visible "$notice" must be inside its merged a11y node',
  );
}

Future<void> _pumpView(
  WidgetTester tester, {
  required List<KvmConsole> consoles,
  required List<KvmCapability> capabilities,
  double? width,
}) async {
  if (width != null) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final KvmController controller = _StubController()
    ..state = KvmUiState(consoles: consoles);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(capabilities),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpViewer(
  WidgetTester tester, {
  required KvmConsole console,
  double? width,
}) async {
  if (width != null) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: KvmConsoleViewerPage(console: console)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpCapabilityCard(
  WidgetTester tester, {
  required KvmCapability capability,
  double? width,
}) async {
  if (width != null) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    MaterialApp(home: KvmCapabilityCard(capability: capability)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EP-U7 shared-notice surface audit (#009 / #021 / RU-2)', () {
    testWidgets(
        'gated list shows the session notice once, merged, across multiple '
        'consoles and capability cards', (WidgetTester tester) async {
      await _pumpView(
        tester,
        consoles: <KvmConsole>[_console('A'), _console('B')],
        capabilities: <KvmCapability>[
          _capability('A', enabled: true),
          _capability('B', enabled: true),
        ],
      );

      _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
      // The disabled notice belongs on a capability card only — an enabled
      // capability set must not render it anywhere on the list view.
      expect(find.text(kvmDisabledOnBmcNotice), findsNothing);
      expect(_mergedNotice(kvmDisabledOnBmcNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'gated list shows exactly one merged disabled notice per disabled '
        'capability, without duplicating the session notice',
        (WidgetTester tester) async {
      await _pumpView(
        tester,
        consoles: <KvmConsole>[_console('A'), _console('B')],
        capabilities: <KvmCapability>[
          _capability('A', enabled: false),
          _capability('B', enabled: false),
        ],
      );

      // Session guidance is a single view-level notice, not one per card.
      _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
      // One disabled card → one notice; two disabled cards → exactly two,
      // each a merged node with visible text inside it.
      expect(find.text(kvmDisabledOnBmcNotice), findsNWidgets(2));
      expect(_mergedNotice(kvmDisabledOnBmcNotice), findsNWidgets(2));
      expect(
        find.ancestor(
          of: find.text(kvmDisabledOnBmcNotice),
          matching: _mergedNotice(kvmDisabledOnBmcNotice),
        ),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'viewer repeats the session notice once, merged, and never the '
        'disabled notice', (WidgetTester tester) async {
      for (final KvmConsole console in <KvmConsole>[
        _console('secure'),
        const KvmConsole(
          type: KvmConsoleType.graphical,
          managerId: 'nouri',
          connectTypesSupported: const <String>['KVMIP'],
          serviceEnabled: true,
          sourceManagerUri: '/redfish/v1/Managers/nouri',
        ),
      ]) {
        await _pumpViewer(tester, console: console);

        _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
        expect(find.text(kvmDisabledOnBmcNotice), findsNothing);
        expect(_mergedNotice(kvmDisabledOnBmcNotice), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
        'capability card shows the disabled notice only when disabled, once, '
        'merged', (WidgetTester tester) async {
      await _pumpCapabilityCard(
        tester,
        capability: _capability('on', enabled: true),
      );
      expect(find.text(kvmDisabledOnBmcNotice), findsNothing);
      expect(_mergedNotice(kvmDisabledOnBmcNotice), findsNothing);
      expect(find.text(kvmSessionPersistenceNotice), findsNothing);

      await _pumpCapabilityCard(
        tester,
        capability: _capability('off', enabled: false),
      );
      _expectOneMergedNotice(tester, kvmDisabledOnBmcNotice);
      // Session guidance does not belong on the capability card.
      expect(find.text(kvmSessionPersistenceNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets(
          'gated list notices render without overflow at '
          '${width.toInt()} px', (WidgetTester tester) async {
        await _pumpView(
          tester,
          consoles: <KvmConsole>[_console('A'), _console('B')],
          capabilities: <KvmCapability>[
            _capability('A', enabled: false),
            _capability('B', enabled: true),
          ],
          width: width,
        );
        _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
        expect(find.text(kvmDisabledOnBmcNotice), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'viewer session notice renders without overflow at '
          '${width.toInt()} px', (WidgetTester tester) async {
        await _pumpViewer(tester, console: _console('secure'), width: width);
        _expectOneMergedNotice(tester, kvmSessionPersistenceNotice);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'capability disabled notice renders without overflow at '
          '${width.toInt()} px', (WidgetTester tester) async {
        await _pumpCapabilityCard(
          tester,
          capability: _capability('off', enabled: false),
          width: width,
        );
        _expectOneMergedNotice(tester, kvmDisabledOnBmcNotice);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
