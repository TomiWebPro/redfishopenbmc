import 'package:flutter/material.dart';

/// Firmware & update management screen.
///
/// Placeholder shell for firmware update jobs (#008). Renders a static
/// scaffold in #001; real update flow lands in #008.
class FirmwarePage extends StatelessWidget {
  /// Creates a [FirmwarePage].
  const FirmwarePage({this.systemId, super.key});

  /// Logical id of the system this page is scoped to, if any.
  final String? systemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmware')),
      body: const Center(
        child: Text('Firmware & update management (#008)'),
      ),
    );
  }
}
