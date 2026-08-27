import 'package:flutter/material.dart';

class SensorsPage extends StatelessWidget {
  const SensorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensors')),
      body: const Center(
        child: Text('Sensor monitoring — realtime graphs (#007)'),
      ),
    );
  }
}
