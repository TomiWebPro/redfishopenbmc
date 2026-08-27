import 'package:flutter/material.dart';

/// Systems management screen.
///
/// Placeholder shell for the multi-system manager (#004). Renders a static
/// scaffold in #001; the real system list arrives with discovery + profiles.
class SystemsPage extends StatelessWidget {
  /// Creates a [SystemsPage].
  const SystemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Systems')),
      body: const Center(
        child: Text('Systems dashboard — multi-system manager (#004)'),
      ),
    );
  }
}
