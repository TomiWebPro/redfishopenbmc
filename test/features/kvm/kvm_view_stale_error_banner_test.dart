// #009 / #021: in-list stale-data error banner for `KvmView`.
//
// `KvmUiState.error` is set on a failed load while a previously successful load
// may have left `consoles` populated (KvmController.load clears the primary on
// error but keeps the last-known console list). KvmView's early error return is
// gated on `ui.error != null && ui.consoles.isEmpty`, so a failed RELOAD with
// consoles already on screen fell through to the populated `ListView` with NO
// error indication at all — the operator saw stale consoles as if they were
// fresh, with no warning and no hint that the refresh failed.
//
// This suite pins the in-list stale-data warning: when the populated list is
// rendered with an error, exactly ONE merged `excludeSemantics` node announces
// the refresh failure, with the visible text inside the announced node
// (visible == announced), the console cards still present (fail closed, not
// hidden), no duplicate of the early empty-list error node, and no overflow at
// 320 / 800 / 1300 px. Display-only, dependency-free, TLS-safe: no URL opened,
// no WebView / protocol import, no production TLS change.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_controller.dart';
import 'package:redfishopenbmc/features/kvm/kvm_providers.dart';
import 'package:redfishopenbmc/features/kvm/kvm_service.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_capability.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/connection_profile.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [KvmController] whose [load] is a no-op so the seeded state stays put.
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

KvmConsole _console() => const KvmConsole(
      type: KvmConsoleType.graphical,
      managerId: 'BMC',
      connectTypesSupported: <String>['KVMIP'],
      serviceEnabled: true,
      connectUri: 'https://bmc.example/kvm',
      sourceManagerUri: '/redfish/v1/Managers/BMC',
    );

const String _kStubError = 'HTTP 401: session expired';

/// The announced label of the in-list stale-data warning.
const String _kBannerLabel = 'Unable to refresh KVM consoles. $_kStubError';

/// The single merged `excludeSemantics` node announcing the stale-data warning.
Finder _mergedBanner() => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics &&
          widget.container &&
          widget.excludeSemantics &&
          widget.properties.label == _kBannerLabel,
    );

Future<void> _pumpView(
  WidgetTester tester, {
  required bool hasError,
  required bool loading,
  double? width,
}) async {
  if (width != null) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  final KvmController controller = _StubController()
    ..state = KvmUiState(
      loading: loading,
      consoles: <KvmConsole>[_console()],
      error: hasError ? _kStubError : null,
    );
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        systemHandleProvider('bmc1').overrideWithValue(_handle()),
        kvmControllerProvider.overrideWith((ref, id) => controller),
        kvmCapabilitiesProvider.overrideWith(
          (ref, id) => Future<List<KvmCapability>>.value(<KvmCapability>[]),
        ),
      ],
      child: const MaterialApp(home: KvmView(systemId: 'bmc1')),
    ),
  );
  await tester.pump();
}

void main() {
  for (final double width in <double>[320, 800, 1300]) {
    testWidgets(
        'failed reload with consoles shown warns in-list at '
        '${width.round()}px', (WidgetTester tester) async {
      await _pumpView(tester, hasError: true, loading: false, width: width);

      // The stale console list is still rendered (fail closed, not hidden) —
      // the header proves we are in the in-list branch, not the early error
      // return (which would drop the list entirely).
      expect(
        find.bySemanticsLabel('Remote KVM / Consoles, consoles exposed by the '
            'system managers'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Manager: BMC'), findsOneWidget);

      // Exactly ONE merged warning node announces the refresh failure, with the
      // visible error text inside it (visible == announced).
      expect(find.bySemanticsLabel(_kBannerLabel), findsOneWidget);
      expect(_mergedBanner(), findsOneWidget);
      expect(find.text(_kStubError), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(_kStubError),
          matching: _mergedBanner(),
        ),
        findsOneWidget,
        reason: 'the visible error text must sit inside its merged a11y node',
      );

      // The early empty-list error node must NOT also appear.
      expect(
        find.bySemanticsLabel('Unable to load KVM consoles. $_kStubError'),
        findsNothing,
        reason: 'the early empty-list error state must not duplicate the '
            'in-list warning',
      );

      expect(tester.takeException(), isNull,
          reason: 'no overflow at ${width}px');
    });
  }

  testWidgets('a settled successful load shows no stale-data warning',
      (WidgetTester tester) async {
    await _pumpView(tester, hasError: false, loading: false, width: 800);

    expect(_mergedBanner(), findsNothing);
    expect(find.bySemanticsLabel(_kBannerLabel), findsNothing);
    expect(find.bySemanticsLabel('Manager: BMC'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow at 800px');
  });

  testWidgets('an in-flight reload keeps the warning and the stale list',
      (WidgetTester tester) async {
    await _pumpView(tester, hasError: true, loading: true, width: 800);

    // Both the refresh failure and the in-flight indicator are honest signals:
    // the last refresh failed AND a new one is underway. The stale cards are
    // replaced by the established in-list spinner during a reload, but the
    // refresh-failure warning must remain visible alongside it.
    expect(_mergedBanner(), findsOneWidget);
    expect(find.bySemanticsLabel('Loading KVM consoles'), findsOneWidget);
    expect(find.bySemanticsLabel('Manager: BMC'), findsNothing);
    expect(tester.takeException(), isNull, reason: 'no overflow at 800px');
  });
}
