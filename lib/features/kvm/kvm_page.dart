import 'package:flutter/material.dart';

class KvmPage extends StatelessWidget {
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
