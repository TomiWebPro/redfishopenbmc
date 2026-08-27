import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/power/views/power_view.dart';

class PowerPage extends StatelessWidget {
  const PowerPage({required this.systemId, super.key});

  final String systemId;

  @override
  Widget build(BuildContext context) => PowerView(systemId: systemId);
}
