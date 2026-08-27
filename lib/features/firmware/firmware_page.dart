import 'package:flutter/material.dart';

/// Firmware & update management screen.
///
/// Placeholder shell for firmware update jobs (#008). Rendered inside
/// [SystemShell] (which supplies the tab/AppBar), so it returns only its body.
class FirmwarePage extends StatelessWidget {
  /// Creates a [FirmwarePage].
  const FirmwarePage({this.systemId, super.key});

  /// Logical id of the system this page is scoped to, if any.
  final String? systemId;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Firmware & update management (#008)'),
    );
  }
}
