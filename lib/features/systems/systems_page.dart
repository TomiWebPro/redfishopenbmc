import 'package:flutter/material.dart';

class SystemsPage extends StatelessWidget {
  const SystemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Systems')),
      body: const Center(
        child: Text('Systems dashboard — multi-system manager (#004)'),
      ),
    );
  }
}
