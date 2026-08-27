import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/main.dart';

void main() {
  testWidgets('RedfishApp renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const RedfishApp());
    // Root MaterialApp.router is present exactly once.
    expect(find.byType(MaterialApp), findsOneWidget);
    // The Systems destination is exposed in navigation (label present).
    expect(find.text('Systems'), findsAtLeastNWidgets(1));
  });

  testWidgets('AdaptiveShellPreview reflects mobile breakpoint',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const AdaptiveShellPreview());
    // Body text is unique per breakpoint; appBar text also contains it.
    expect(find.text('Width: 400.0 → mobile'), findsOneWidget);
  });

  testWidgets('AdaptiveShellPreview reflects tablet breakpoint',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const AdaptiveShellPreview());
    expect(find.text('Width: 800.0 → tablet'), findsOneWidget);
  });

  testWidgets('AdaptiveShellPreview reflects desktop breakpoint',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1300, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(const AdaptiveShellPreview());
    expect(find.text('Width: 1300.0 → desktop'), findsOneWidget);
  });
}
