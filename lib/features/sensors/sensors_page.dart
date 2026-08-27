import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/sensors/views/sensors_view.dart';

/// Sensor monitoring screen.
///
/// Rendered inside [SystemShell] (which supplies the tab/AppBar), so it returns
/// only its body. Scoped to a single system via [systemId].
class SensorsPage extends StatelessWidget {
  /// Creates a [SensorsPage] for [systemId].
  const SensorsPage({required this.systemId, super.key});

  /// Logical id of the system this page is scoped to.
  final String systemId;

  @override
  Widget build(BuildContext context) => SensorsView(systemId: systemId);
}
