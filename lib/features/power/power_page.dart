import 'package:flutter/material.dart';

class PowerPage extends StatelessWidget {
  const PowerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Power')),
      body: const Center(
        child: Text('Power management — Reset actions (#005)'),
      ),
    );
  }
}
