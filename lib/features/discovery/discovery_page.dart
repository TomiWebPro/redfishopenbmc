import 'package:flutter/material.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery')),
      body: const Center(
        child: Text('Discovery engine — schema-driven capability map (#003)'),
      ),
    );
  }
}
