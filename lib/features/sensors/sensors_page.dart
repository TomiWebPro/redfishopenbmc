import 'package:flutter/material.dart';

/// Sensor monitoring screen.
///
/// Placeholder shell for realtime sensor graphs (#007). Rendered inside
/// [SystemShell] (which supplies the tab/AppBar), so it returns only its body.
class SensorsPage extends StatelessWidget {
  /// Creates a [SensorsPage].
  const SensorsPage({this.systemId, super.key});

  /// Logical id of the system this page is scoped to, if any.
  final String? systemId;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Sensor monitoring — realtime graphs (#007)'),
    );
  }
}
