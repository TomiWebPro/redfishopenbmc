import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/firmware/views/firmware_view.dart';

/// Firmware & update management screen (issue #008).
///
/// Rendered inside [SystemShell] (which supplies the tab/AppBar), so it returns
/// only its body [FirmwareView].
class FirmwarePage extends StatelessWidget {
  /// Creates a [FirmwarePage].
  const FirmwarePage({required this.systemId, super.key});

  /// Logical id of the system this page is scoped to.
  final String systemId;

  @override
  Widget build(BuildContext context) => FirmwareView(systemId: systemId);
}
