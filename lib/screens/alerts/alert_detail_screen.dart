import 'package:flutter/material.dart';
import 'package:get/get.dart';
<<<<<<< HEAD
=======
import '../../generated/app_localizations.dart';
>>>>>>> hyacinthe
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
<<<<<<< HEAD
        title: const Text('Alert'),
=======
  title: Text(AppLocalizations.of(context)?.alerts ?? 'Alert'),
>>>>>>> hyacinthe
        actions: [
          if (!alert.read)
            TextButton(
              onPressed: () async {
                await service.markAsRead(alert.id);
                Get.back();
              },
<<<<<<< HEAD
              child: const Text('Mark read'),
=======
              child: Text(AppLocalizations.of(context)?.markAsRead ?? 'Mark read'),
>>>>>>> hyacinthe
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
              alert.message,
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
                alert.ts.toString(),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(BuildContext context, String severity) {
    switch (severity) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      case 'info':
      default:
<<<<<<< HEAD
        return Colors.green;
=======
        return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.green;
>>>>>>> hyacinthe
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'high':
      case 'critical':
        return Icons.warning;
      case 'medium':
        return Icons.warning_amber;
      case 'low':
      case 'info':
      default:
        return Icons.info;
    }
  }
}


