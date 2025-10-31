import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class AlertsListScreen extends StatelessWidget {
  const AlertsListScreen({super.key});

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
        return Colors.green;
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

  @override
  Widget build(BuildContext context) {
    final service = AlertService();
    final dash = Provider.of<DashboardProvider>(context, listen: false);
    final farmId = dash.selectedFarmId;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: StreamBuilder<List<AlertModel>>(
        stream: service.streamFarmAlerts(farmId),
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
                  title: Text(a.message, style: TextStyle(color: textColor)),
                  subtitle: Text(a.message, style: TextStyle(color: scheme.onSurfaceVariant)),
                  trailing: a.read
                      ? Icon(Icons.check, color: scheme.primary)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            a.severity.toUpperCase(),
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


