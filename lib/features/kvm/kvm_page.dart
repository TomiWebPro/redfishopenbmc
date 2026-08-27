import 'package:flutter/material.dart';

/// Remote KVM screen.
///
/// Placeholder shell for remote KVM / GraphicalConsole (#009). Rendered inside
/// [SystemShell] (which supplies the tab/AppBar), so it returns only its body.
class KvmPage extends StatelessWidget {
  /// Creates a [KvmPage].
  const KvmPage({this.systemId, super.key});

  /// Logical id of the system this page is scoped to, if any.
  final String? systemId;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Remote KVM — GraphicalConsole (#009)'),
    );
  }
}
