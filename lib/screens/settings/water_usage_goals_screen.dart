import 'package:flutter/material.dart';

class WaterUsageGoalsScreen extends StatelessWidget {
  const WaterUsageGoalsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water Usage Goals')),
      body: const Center(child: Text('This is the Water Usage Goals page. Manage your water consumption targets here.')),
    );
  }
}


