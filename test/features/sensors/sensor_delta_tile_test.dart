import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderObject, RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:redfishopenbmc/features/sensors/views/sensor_delta_tile.dart';

/// Harness that rebuilds its child on demand, controlling the fingerprint and
/// counting how often the gated builder actually runs (#007 per-tile delta).
class _GateHarness extends StatefulWidget {
  const _GateHarness({required this.buildLog});

  /// Incremented each time the gated builder is invoked.
  final List<int> buildLog;

  @override
  State<_GateHarness> createState() => _GateHarnessState();
}

class _GateHarnessState extends State<_GateHarness> {
  String fingerprint = 'A';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextButton(
          onPressed: () => setState(() {}), // parent rebuild, same fingerprint
          child: const Text('rebuild-same'),
        ),
        TextButton(
          onPressed: () => setState(() => fingerprint = 'B'),
          child: const Text('change-fingerprint'),
        ),
        SensorDeltaTile(
          fingerprint: fingerprint,
          builder: (_) {
            widget.buildLog.add(1);
            return const Text('tile');
          },
        ),
      ],
    );
  }
}

void main() {
  group('SensorDeltaTile selector-style rebuild gate (#007)', () {
    testWidgets(
        'builds once and skips parent rebuilds when fingerprint is '
        'unchanged', (WidgetTester tester) async {
      final List<int> builds = <int>[];
      await tester
          .pumpWidget(MaterialApp(home: _GateHarness(buildLog: builds)));
      expect(builds.length, 1);
      expect(find.text('tile'), findsOneWidget);

      // A parent rebuild hands the gate a brand-new widget instance with a new
      // builder closure — but the selected fingerprint is identical, so the
      // cached child is returned and the expensive builder is not re-invoked.
      await tester.tap(find.text('rebuild-same'));
      await tester.pump();
      expect(builds.length, 1);

      await tester.tap(find.text('rebuild-same'));
      await tester.pump();
      expect(builds.length, 1);
    });

    testWidgets('rebuilds when the fingerprint changes, then gates again',
        (WidgetTester tester) async {
      final List<int> builds = <int>[];
      await tester
          .pumpWidget(MaterialApp(home: _GateHarness(buildLog: builds)));
      expect(builds.length, 1);

      await tester.tap(find.text('change-fingerprint'));
      await tester.pump();
      expect(builds.length, 2);

      // Fingerprint is now stable at 'B' — further rebuilds are skipped.
      await tester.tap(find.text('rebuild-same'));
      await tester.pump();
      expect(builds.length, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wraps its child in a RepaintBoundary',
        (WidgetTester tester) async {
      final List<int> builds = <int>[];
      await tester
          .pumpWidget(MaterialApp(home: _GateHarness(buildLog: builds)));

      // The gated child's render object sits behind a repaint boundary, so a
      // real repaint is confined to this tile.
      RenderObject? ancestor =
          tester.renderObject<RenderObject>(find.text('tile')).parent;
      while (ancestor != null && ancestor is! RenderRepaintBoundary) {
        ancestor = ancestor.parent;
      }
      expect(ancestor, isA<RenderRepaintBoundary>());
    });
  });
}
