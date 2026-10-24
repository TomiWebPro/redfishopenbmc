// ignore_for_file: prefer_const_constructors
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:redfishopenbmc/core/storage/secure_storage.dart';
import 'package:redfishopenbmc/core/theme/app_theme.dart';
import 'package:redfishopenbmc/features/overview/models/system_overview.dart';
import 'package:redfishopenbmc/features/overview/overview_provider.dart';
import 'package:redfishopenbmc/features/overview/views/overview_view.dart';
import 'package:redfishopenbmc/features/overview/widgets/health_banner.dart';
import 'package:redfishopenbmc/features/overview/widgets/info_card.dart';
import 'package:redfishopenbmc/features/overview/widgets/skeleton_card.dart';
import 'package:redfishopenbmc/features/systems/models/connection_profile.dart';
import 'package:redfishopenbmc/features/systems/models/system_snapshot.dart';
import 'package:redfishopenbmc/features/systems/providers/profile_repository.dart';
import 'package:redfishopenbmc/features/systems/providers/system_manager.dart';
import 'package:redfishopenbmc/redfish/models/redfish_exception.dart';
import 'package:redfishopenbmc/redfish/models/session.dart';
import 'package:redfishopenbmc/redfish/models/system_features.dart';

/// A [SystemOverview] with every field populated — exercises all cards.
SystemOverview fullSample() => SystemOverview(
      manufacturer: 'Acme',
      model: 'Server-9',
      serialNumber: 'SN1',
      sku: 'SKU1',
      partNumber: 'PN1',
      biosVersion: '1.0',
      powerState: PowerState.on,
      health: Health.ok,
      healthRollup: Health.ok,
      processorSummary: const ProcessorSummary(count: 2, model: 'P9'),
      memorySummary: const MemorySummary(totalGiB: 32),
      indicatorLed: IndicatorLed.lit,
      leadingTemperatureCelsius: 42.0,
      resourceUri: '/redfish/v1/Systems/system',
    );

/// A [SystemOverview] with nothing exposed — exercises "Not exposed" paths.
SystemOverview emptySample() => const SystemOverview(
      health: Health.unknown,
      powerState: PowerState.unknown,
    );

SystemManager seededManager() {
  final SystemManager m = SystemManager(
    repository: InMemoryProfileRepository(),
    storage: InMemoryStorage(),
  );
  m.state = SystemState(
    systems: <String, SystemHandle>{
      'bmc1': SystemHandle(
        profile: const ConnectionProfile(id: 'bmc1', host: 'h'),
        status: ConnectionStatus.connected,
        session: Session(
          systemId: 'bmc1',
          token: 't',
          location: '',
          username: '',
        ),
        features: const SystemFeatures(systemId: 'bmc1'),
        snapshot: SystemSnapshot(
          powerState: PowerState.on,
          resourceUri: '/redfish/v1/Systems/system',
        ),
      ),
    },
    selectedId: 'bmc1',
  );
  return m;
}

/// Builds a [ProviderScope] that feeds [overviewProvider] a fixed [sample]
/// (or an error when [error] is true) and provides a seeded manager.
ProviderScope scopeWith({
  required SystemOverview sample,
  bool error = false,
}) {
  return ProviderScope(
    overrides: <Override>[
      systemManagerProvider.overrideWith((ref) => seededManager()),
      overviewProvider.overrideWith(
        (ref, id) => error
            ? Future<SystemOverview>.error(
                const RedfishException(message: 'boom', errorCode: 'X'),
              )
            : Future<SystemOverview>.value(sample),
      ),
    ],
    child: MaterialApp(
      home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
    ),
  );
}

void main() {
  group('OverviewView — loading', () {
    testWidgets('shows skeleton cards while the provider loads',
        (tester) async {
      // A never-completed completer keeps the provider in the loading state
      // without scheduling a real Timer (which would leak past the test).
      final Completer<SystemOverview> completer = Completer<SystemOverview>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith((ref, id) => completer.future),
          ],
          child: MaterialApp(
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SkeletonCard), findsWidgets);
      expect(find.byType(HealthBanner), findsOneWidget);
    });
  });

  group('OverviewView — data', () {
    testWidgets('renders all cards with populated values (light mode)',
        (tester) async {
      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('Processors'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Temperatures'), findsOneWidget);
      expect(find.text('Indicator LED'), findsOneWidget);
      expect(find.text('SN1'), findsOneWidget);
      expect(find.text('32 GiB'), findsOneWidget);
      expect(find.text('42.0 °C'), findsOneWidget);
      expect(find.text('Lit'), findsOneWidget);
      expect(find.text('2 processor(s)'), findsOneWidget);
      // Nothing should be flagged "not exposed" when data is present.
      expect(find.text('Not exposed by this BMC'), findsNothing);
      // UI-2: each InfoCard header announces one merged semantics label
      // (icon + title) instead of separate unlabeled nodes.
      expect(find.bySemanticsLabel('Identity'), findsOneWidget);
      expect(find.bySemanticsLabel('Processors'), findsOneWidget);
      expect(find.bySemanticsLabel('Memory'), findsOneWidget);
      expect(find.bySemanticsLabel('Temperatures'), findsOneWidget);
      expect(find.bySemanticsLabel('Indicator LED'), findsOneWidget);
    });

    testWidgets('renders without errors in dark mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemManagerProvider.overrideWith((ref) => seededManager()),
            overviewProvider.overrideWith(
              (ref, id) => Future<SystemOverview>.value(fullSample()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: OverviewView(systemId: 'bmc1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.byType(InfoCard), findsWidgets);
    });

    testWidgets(
        'identity card key/value rows announce as one merged semantics node '
        'each (UI-2)', (tester) async {
      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
      // Each _kv row merges its label + value into one self-describing node:
      // "Manufacturer: Acme", "Model: Server-9", "Serial: SN1", "BIOS: 1.0".
      expect(
        find.bySemanticsLabel('Manufacturer: Acme'),
        findsOneWidget,
        reason: 'the label + value must announce as a single merged node',
      );
      expect(find.bySemanticsLabel('Model: Server-9'), findsOneWidget);
      expect(find.bySemanticsLabel('Serial: SN1'), findsOneWidget);
      expect(find.bySemanticsLabel('BIOS: 1.0'), findsOneWidget);
      // The visible texts are still present for sighted users.
      expect(find.text('Manufacturer'), findsOneWidget);
      expect(find.text('Acme'), findsOneWidget);
      expect(find.text('BIOS'), findsOneWidget);
    });

    testWidgets(
        'identity card missing-value rows merge label + "Not exposed" (UI-2)',
        (tester) async {
      await tester.pumpWidget(scopeWith(sample: emptySample()));
      await tester.pumpAndSettle();
      // With nothing exposed the rows still announce as one merged node each,
      // carrying the field label plus the visible "Not exposed" text.
      expect(
        find.bySemanticsLabel('Manufacturer: Not exposed by this BMC'),
        findsOneWidget,
        reason: 'the label + "Not exposed" must announce as a single node',
      );
      expect(
        find.bySemanticsLabel('Model: Not exposed by this BMC'),
        findsOneWidget,
      );
      expect(find.text('Not exposed by this BMC'), findsWidgets);
    });

    testWidgets(
        'processors card count + model announce as one merged semantics node '
        '(UI-2)', (tester) async {
      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
      // The count and model previously announced as two detached nodes under
      // the merged "Processors" header; they now announce as ONE node
      // carrying both facts: "2 processor(s), P9".
      expect(
        find.bySemanticsLabel('2 processor(s), P9'),
        findsOneWidget,
        reason: 'the processor count + model must announce as a single node',
      );
      // The visible texts stay for sighted users.
      expect(find.text('2 processor(s)'), findsOneWidget);
      expect(find.text('P9'), findsOneWidget);
    });

    testWidgets(
        'health banner announces one merged semantics node incl. the state '
        '(UI-2)', (tester) async {
      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
      // The banner (icon + label) is one merged node: "Health: Healthy" —
      // same pattern as the InfoCard/SystemCard/PowerView header labels.
      expect(
        find.bySemanticsLabel(RegExp('^Health: Healthy')),
        findsOneWidget,
        reason: 'the health banner must announce as a single merged node',
      );
      // The visible label text is still present for sighted users.
      expect(find.text('Healthy'), findsOneWidget);
    });

    testWidgets(
        'omits the temperature card and shows "not exposed" for missing fields',
        (tester) async {
      await tester.pumpWidget(scopeWith(sample: emptySample()));
      await tester.pumpAndSettle();
      expect(find.text('Temperatures'), findsNothing);
      expect(find.text('Not exposed by this BMC'), findsWidgets);
      // 'Unknown' appears in both the health banner and the power badge.
      expect(find.text('Unknown'), findsWidgets);
    });
  });

  group('OverviewView — adaptive grid', () {
    testWidgets('lays out the card grid at desktop width', (tester) async {
      // Desktop width → 3 columns.
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(InfoCard), findsNWidgets(5));
    });
  });

  group('OverviewView — responsive layout (UI-3)', () {
    Future<void> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(scopeWith(sample: fullSample()));
      await tester.pumpAndSettle();
    }

    for (final double width in <double>[320, 800, 1300]) {
      testWidgets('renders without overflow at ${width.toInt()} px',
          (tester) async {
        await pumpAtWidth(tester, width);
        expect(
          tester.takeException(),
          isNull,
          reason: 'OverviewView must not overflow at $width px',
        );
        // Health banner + every data card render at every breakpoint.
        expect(find.text('Healthy'), findsOneWidget);
        expect(find.byType(InfoCard), findsNWidgets(5));
      });
    }
  });

  group('OverviewView — error', () {
    testWidgets('shows an error state with a retry affordance', (tester) async {
      await tester.pumpWidget(scopeWith(sample: emptySample(), error: true));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load overview'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

      // Tapping retry must not crash (re-runs the failing provider).
      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load overview'), findsOneWidget);
    });

    testWidgets('error state announces as one merged semantics node (UI-2)',
        (tester) async {
      await tester.pumpWidget(scopeWith(sample: emptySample(), error: true));
      await tester.pumpAndSettle();

      // The icon + title + detail merge into one node carrying both strings;
      // the Retry button keeps its own semantics (it is a control).
      final Finder merged = find.bySemanticsLabel(
        'Unable to load overview. boom',
      );
      expect(merged, findsOneWidget);
      final SemanticsNode? node = tester.getSemantics(merged);
      expect(node?.label, contains('Unable to load overview'));
      expect(node?.label, contains('boom'));

      // The Retry control is still separately focusable/announced.
      expect(
        find.bySemanticsLabel(RegExp('^Retry')),
        findsWidgets,
      );
    });
  });
}
