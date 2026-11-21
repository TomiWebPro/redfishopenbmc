// Viewer -> KvmSessionController single-session limit wiring (EP-U4 / #009).
//
// `KvmConsoleViewerPage.initState` opens the pure-UI console session with
// `_session.connect(widget.console.managerId,
// maxConcurrentSessions: widget.console.maxConcurrentSessions)`. The
// `maxConcurrentSessions` argument is what lets a single-session BMC (limit 1)
// log an eviction when another console is opened, and what keeps a
// multi-session BMC (limit > 1 / null) from logging a spurious eviction.
//
// Existing session tests drive `KvmSessionController.connect` DIRECTLY with an
// explicit limit, and the viewer-widget tests assert the eviction DISCLOSURE
// after a direct controller call — none of them open a second viewer, so a
// future edit that drops (or hardcodes) the pass-through argument would
// silently break single-session eviction for real operators and stay GREEN.
// This guard opens real viewers through the Navigator and pins that the
// viewer forwards its console's exact limit to the shared controller.
//
// Pure UI: no WebView/protocol dependency, no URL opened, no Redfish call and
// no production TLS weakening.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/kvm/kvm_session.dart';
import 'package:redfishopenbmc/features/kvm/models/kvm_models.dart';
import 'package:redfishopenbmc/features/kvm/views/kvm_console_viewer_page.dart';

void main() {
  final DateTime t0 = DateTime.utc(2026, 11, 21, 9);

  KvmConsole consoleFor(String id, {int? maxConcurrentSessions}) => KvmConsole(
        type: KvmConsoleType.remote,
        managerId: id,
        connectTypesSupported: const <String>['HTML5'],
        serviceEnabled: true,
        connectUri: 'https://bmc.example/$id/kvm',
        sourceManagerUri: '/redfish/v1/Managers/$id',
        maxConcurrentSessions: maxConcurrentSessions,
      );

  Future<ProviderContainer> pumpHost(WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        kvmSessionClockProvider.overrideWithValue(() => t0),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox.expand())),
      ),
    );
    return container;
  }

  Future<void> openViewer(WidgetTester tester, KvmConsole console) async {
    final NavigatorState navigator =
        tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => KvmConsoleViewerPage(console: console),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opening a viewer starts a session for its console manager',
      (WidgetTester tester) async {
    final ProviderContainer container = await pumpHost(tester);
    await openViewer(tester, consoleFor('A', maxConcurrentSessions: 1));

    final KvmSessionState session = container.read(kvmSessionProvider);
    expect(session.activeManagerId, 'A');
    expect(session.connectedSince, t0);
    expect(session.isConnected, isTrue);
  });

  testWidgets(
      'a second single-session viewer evicts the first (viewer forwards the '
      'console limit of 1)', (WidgetTester tester) async {
    final ProviderContainer container = await pumpHost(tester);
    await openViewer(tester, consoleFor('A', maxConcurrentSessions: 1));
    expect(container.read(kvmSessionProvider).activeManagerId, 'A');

    await openViewer(tester, consoleFor('B', maxConcurrentSessions: 1));

    final KvmSessionState session = container.read(kvmSessionProvider);
    expect(session.activeManagerId, 'B');
    expect(session.isConnected, isTrue);
    expect(
      session.log,
      contains(contains('Evicted console session for manager "A"')),
      reason: 'the viewer must pass the console maximum to connect so a '
          'single-session BMC eviction is recorded',
    );
  });

  testWidgets(
      'a multi-session viewer replaces the manager without an eviction log '
      '(viewer does not hardcode a limit of 1)', (WidgetTester tester) async {
    final ProviderContainer container = await pumpHost(tester);
    await openViewer(tester, consoleFor('A', maxConcurrentSessions: 1));
    final int logBefore = container.read(kvmSessionProvider).log.length;

    await openViewer(tester, consoleFor('B', maxConcurrentSessions: 4));

    final KvmSessionState session = container.read(kvmSessionProvider);
    expect(session.activeManagerId, 'B');
    expect(session.isConnected, isTrue);
    expect(
      session.log.any((String line) => line.contains('Evicted')),
      isFalse,
      reason: 'a console reporting multiple concurrent sessions must not '
          'produce a spurious eviction — the viewer forwards the real limit',
    );
    expect(session.log.length, greaterThan(logBefore));
  });
}
