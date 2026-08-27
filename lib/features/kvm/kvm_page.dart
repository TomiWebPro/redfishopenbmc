import 'package:flutter/material.dart';

/// Remote KVM screen.
///
/// Placeholder shell for remote KVM / GraphicalConsole (#009). Renders a
/// static scaffold in #001; real console lands in #009.
class KvmPage extends StatelessWidget {
  /// Creates a [KvmPage].
  const KvmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KVM')),
      body: const Center(
        child: Text('Remote KVM — GraphicalConsole (#009)'),
      ),
    );
  }
}
