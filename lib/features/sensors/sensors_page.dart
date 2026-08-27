import 'package:flutter/material.dart';

/// Sensor monitoring screen.
///
/// Placeholder shell for realtime sensor graphs (#007). Renders a static
/// scaffold in #001; real telemetry lands in #007.
class SensorsPage extends StatelessWidget {
  /// Creates a [SensorsPage].
  const SensorsPage({this.systemId, super.key});

  /// Logical id of the system this page is scoped to, if any.
  final String? systemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensors')),
      body: const Center(
        child: Text('Sensor monitoring — realtime graphs (#007)'),
      ),
    );
  }
}
