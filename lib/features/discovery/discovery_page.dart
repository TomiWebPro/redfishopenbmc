import 'package:flutter/material.dart';

/// Discovery screen.
///
/// Placeholder shell for the schema-driven capability map (#003). Renders a
/// static scaffold in #001; the real discovery engine lands in #003.
class DiscoveryPage extends StatelessWidget {
  /// Creates a [DiscoveryPage].
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery')),
      body: const Center(
        child: Text('Discovery engine — schema-driven capability map (#003)'),
      ),
    );
  }
}
