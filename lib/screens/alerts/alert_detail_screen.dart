import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alert = Get.arguments as AlertModel;
    final color = _severityColor(alert.severity);
    final service = AlertService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert'),
        actions: [
          if (!alert.read)
            TextButton(
              onPressed: () async {
                await service.markAsRead(alert.id);
                Get.back();
              },
              child: const Text('Mark read'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_severityIcon(alert.severity), color: color),
                const SizedBox(width: 8),
                Text(
                  alert.severity.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              alert.message,
              style: const TextStyle(color: FamingaBrandColors.textPrimary, fontSize: 14),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                alert.createdAt.toString(),
                style: const TextStyle(color: FamingaBrandColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return FamingaBrandColors.statusWarning;
      case 'warn':
        return FamingaBrandColors.primaryOrange;
      default:
        return FamingaBrandColors.iconColor;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'warn':
        return Icons.warning;
      default:
        return Icons.info_outline;
    }
  }
}


