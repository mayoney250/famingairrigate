import 'package:flutter/material.dart';
class FieldCard extends StatelessWidget {
  final Map<String, String> field;
  const FieldCard({super.key, required this.field});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(field['name'] ?? '', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
