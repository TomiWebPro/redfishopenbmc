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
      // UI-2: the not-implemented placeholder renders the established
      // surface pattern — icon + visible text inside one merged
      // `Semantics(container + excludeSemantics)` node (one
      // self-describing announcement; no Retry — the discovery engine is
      // a planned feature (#003), not an error).
      body: Center(
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: 'Discovery engine — schema-driven capability map (#003)',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.map_outlined, size: 40),
              SizedBox(height: 8),
              Text('Discovery engine — schema-driven capability map (#003)'),
            ],
          ),
        ),
      ),
    );
  }
}
