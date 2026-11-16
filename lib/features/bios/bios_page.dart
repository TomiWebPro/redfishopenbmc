import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/bios/views/bios_view.dart';

/// BIOS configuration screen (issue #028, read-only slice).
///
/// Rendered inside [SystemShell] (which supplies the tab/AppBar), so it returns
/// only its body [BiosView].
class BiosPage extends StatelessWidget {
  /// Creates a [BiosPage].
  const BiosPage({required this.systemId, super.key});

  /// Logical id of the system this page is scoped to.
  final String systemId;

  @override
  Widget build(BuildContext context) => BiosView(systemId: systemId);
}
