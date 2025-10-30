import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alert = Get.arguments as AlertModel;
    final color = _severityColor(context, alert.severity);
    final service = AlertService();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert'),
        actions: [
          if (!alert.isRead)
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
                  alert.severity.name.toUpperCase(),
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
              style: TextStyle(color: scheme.onSurface, fontSize: 14),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                alert.timestamp.toString(),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(BuildContext context, AlertSeverity severity) {
    final scheme = Theme.of(context).colorScheme;
    switch (severity) {
      case AlertSeverity.critical:
        return scheme.error;
      case AlertSeverity.warning:
        return scheme.tertiary;
      case AlertSeverity.info:
      default:
        return scheme.primary;
    }
  }

  IconData _severityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.info:
      default:
        return Icons.info_outline;
    }
  }
}


