import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/colors.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';

class AlertsListScreen extends StatelessWidget {
  const AlertsListScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final service = AlertService();

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: StreamBuilder<List<AlertModel>>(
        stream: service.getAlertsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final alerts = snapshot.data ?? const <AlertModel>[];
          if (alerts.isEmpty) {
            return const Center(child: Text('No alerts'));
          }
          return ListView.separated(
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = alerts[index];
              final color = _severityColor(a.severity);
              return ListTile(
                leading: Icon(_severityIcon(a.severity), color: color),
                title: Text(a.title),
                subtitle: Text(a.message),
                trailing: a.read
                    ? const Icon(Icons.check, color: FamingaBrandColors.iconColor)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          a.severity.toUpperCase(),
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                onTap: () => Get.toNamed('/alert-detail', arguments: a),
              );
            },
          );
        },
      ),
    );
  }
}


