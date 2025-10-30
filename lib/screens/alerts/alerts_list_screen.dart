import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import '../../providers/auth_provider.dart';

class AlertsListScreen extends StatelessWidget {
  const AlertsListScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final service = AlertService();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.userId ?? '';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: StreamBuilder<List<AlertModel>>(
        stream: service.streamUserAlerts(userId),
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
            separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.3)),
            itemBuilder: (context, index) {
              final a = alerts[index];
              final color = _severityColor(context, a.severity);
              final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? scheme.onSurface;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: scheme.surface,
                  leading: Icon(_severityIcon(a.severity), color: color),
                  title: Text(a.title, style: TextStyle(color: textColor)),
                  subtitle: Text(a.message, style: TextStyle(color: scheme.onSurfaceVariant)),
                  trailing: a.isRead
                      ? Icon(Icons.check, color: scheme.primary)
                      : Container
                          (
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              a.severity.name.toUpperCase(),
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                  onTap: () => Get.toNamed('/alert-detail', arguments: a),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


