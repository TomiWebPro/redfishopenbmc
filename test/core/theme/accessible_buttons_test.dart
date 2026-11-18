import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/core/theme/accessible_buttons.dart';

/// Pumps [child] under a desktop-style [MaterialTapTargetSize.shrinkWrap]
/// theme. The test host defaults to Android/`padded`, so this reproduces the
/// 40dp touch-target gap deterministically: a button without its own 48x48
/// minimum stays short, while one carrying [accessibleTouchTargetStyle] does
/// not (issue #010, a11y / touch targets).
Widget desktopHarness(Widget child) => MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('accessibleTouchTargetStyle', () {
    test('minimum touch target is 48x48dp', () {
      expect(kMinimumTouchTarget, const Size(48, 48));
    });

    testWidgets(
        'TextButton keeps a 48x48 hit area and one enabled button node '
        'under a desktop shrinkWrap theme', (tester) async {
      await tester.pumpWidget(desktopHarness(
        TextButton(
          style: accessibleTouchTargetStyle(),
          onPressed: () {},
          child: const Text('Retry'),
        ),
      ));

      final Finder button = find.byType(TextButton);
      final Size size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48),
          reason: 'touch target width must be >= 48');
      expect(size.height, greaterThanOrEqualTo(48),
          reason: 'touch target height must be >= 48');

      final Finder byLabel = find.bySemanticsLabel('Retry');
      expect(byLabel, findsOneWidget,
          reason: 'exactly one node is announced as Retry');
      final SemanticsNode node = tester.getSemantics(byLabel);
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        node.getSemanticsData().flagsCollection.isEnabled.toBoolOrNull(),
        isTrue,
      );
    });

    testWidgets(
        'FilledButton.icon keeps a 48x48 hit area and one enabled '
        'button node under a desktop shrinkWrap theme', (tester) async {
      await tester.pumpWidget(desktopHarness(
        FilledButton.icon(
          style: accessibleTouchTargetStyle(),
          onPressed: () {},
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ));

      final Finder button = find.byType(FilledButton);
      final Size size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48),
          reason: 'touch target width must be >= 48');
      expect(size.height, greaterThanOrEqualTo(48),
          reason: 'touch target height must be >= 48');

      final Finder byLabel = find.bySemanticsLabel(RegExp('^Retry'));
      expect(byLabel, findsOneWidget,
          reason: 'exactly one node is announced as Retry');
      final SemanticsNode node = tester.getSemantics(byLabel);
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        node.getSemanticsData().flagsCollection.isEnabled.toBoolOrNull(),
        isTrue,
      );
    });

    testWidgets(
        'a plain button shrinks below 48dp without the helper '
        '(regression guard documenting the desktop gap)', (tester) async {
      await tester.pumpWidget(desktopHarness(
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ));

      final Size plain = tester.getSize(find.byType(FilledButton));
      expect(plain.height, lessThan(48),
          reason: 'without the helper the desktop button is below the '
              '48dp minimum — this is the gap the main-view Retry controls '
              'fix');
    });
  });
}
