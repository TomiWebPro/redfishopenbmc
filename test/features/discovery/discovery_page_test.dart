import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/discovery/discovery_page.dart';

void main() {
  testWidgets(
      'DiscoveryPage placeholder announces one merged semantics node '
      '— icon + text (UI-2)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryPage()),
    );

    // One self-describing merged node carries the full label.
    expect(
      find.bySemanticsLabel(
          'Discovery engine — schema-driven capability map (#003)'),
      findsOneWidget,
      reason: 'expected one merged placeholder node (icon + text)',
    );
    // Visible text preserved for sighted users.
    expect(
      find.text('Discovery engine — schema-driven capability map (#003)'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    // No overflow exception (UI-3) at the default test surface.
    expect(tester.takeException(), isNull);
  });

  testWidgets('DiscoveryPage placeholder has no overflow at 320 px (UI-3)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryPage()),
    );

    expect(
      find.bySemanticsLabel(
          'Discovery engine — schema-driven capability map (#003)'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull,
        reason: 'the 320 px viewport must not overflow');
  });
}
