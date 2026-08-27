import 'package:flutter/material.dart';

/// Power management screen.
///
/// Placeholder shell for power control / reset actions (#005). Renders a
/// static scaffold in #001; real controls land in #005.
class PowerPage extends StatelessWidget {
  /// Creates a [PowerPage].
  const PowerPage({this.systemId, super.key});

  /// Logical id of the system this page is scoped to, if any.
  final String? systemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Power')),
      body: const Center(
        child: Text('Power management — Reset actions (#005)'),
      ),
    );
  }
}
