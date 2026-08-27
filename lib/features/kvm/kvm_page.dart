import 'package:flutter/material.dart';

import 'package:redfishopenbmc/features/kvm/views/kvm_view.dart';

/// Remote KVM screen.
///
/// Rendered inside [SystemShell] (which supplies the tab/AppBar), so it returns
/// only its body. Mirrors [PowerPage].
class KvmPage extends StatelessWidget {
  /// Creates a [KvmPage].
  const KvmPage({required this.systemId, super.key});

  /// Logical id of the system this page is scoped to.
  final String systemId;

  @override
  Widget build(BuildContext context) => KvmView(systemId: systemId);
}
