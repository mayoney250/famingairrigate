import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/colors.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import '../../services/alert_local_service.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/shimmer/shimmer_widgets.dart';
import '../../generated/app_localizations.dart';

class AlertsListScreen extends StatefulWidget {
  const AlertsListScreen({super.key});

  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  final AlertService _remote = AlertService();
  List<AlertModel> _alerts = <AlertModel>[];
  bool _loading = true;

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
        return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.green;
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadLocal();
      await _refreshRemote();
      // live updates from local box
      final box = await Hive.openBox<AlertModel>('alertsBox');
      box.listenable().addListener(_loadLocal);
    });
  }

  Future<void> _loadLocal() async {
    final farmId = Provider.of<DashboardProvider>(context, listen: false).selectedFarmId;
    final local = await AlertLocalService.getAlerts();
    local.sort((a, b) => b.ts.compareTo(a.ts));
    final filtered = local.where((a) => a.farmId == farmId).toList();
    if (!mounted) return;
    setState(() {
      _alerts = filtered;
      _loading = false;
    });
  }

  Future<void> _refreshRemote() async {
    try {
      final farmId = Provider.of<DashboardProvider>(context, listen: false).selectedFarmId;
      final remote = await _remote.getFarmAlerts(farmId);
      // cache into Hive
      for (final a in remote) {
        await AlertLocalService.addAlert(a);
      }
      await _loadLocal();
    } catch (_) {
      // stay with local data when offline
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.alerts ?? 'Alerts')),
      body: _loading
          ? ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerListTile(
                hasLeading: true,
                hasTrailing: false,
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshRemote,
              child: _alerts.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text(AppLocalizations.of(context)?.noAlertsYet ?? 'No alerts')),
                        const SizedBox(height: 400),
                      ],
                    )
          : ListView.separated(
              itemCount: _alerts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.3)),
              itemBuilder: (context, index) {
                return _AlertListItem(alert: _alerts[index]);
              },
            ),
      ),
    );
  }
}

class _AlertListItem extends StatelessWidget {
  final AlertModel alert;

  const _AlertListItem({Key? key, required this.alert}) : super(key: key);

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
        return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.green;
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
    final scheme = Theme.of(context).colorScheme;
    final color = _severityColor(context, alert.severity);
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: scheme.surface,
        leading: Icon(_severityIcon(alert.severity), color: color),
        title: Text(alert.message, style: TextStyle(color: textColor)),
        subtitle: Text(alert.type, style: TextStyle(color: scheme.onSurfaceVariant)),
        trailing: alert.read
            ? Icon(Icons.check, color: scheme.primary)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert.severity.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
        onTap: () => Get.toNamed('/alert-detail', arguments: alert),
      ),
    );
  }
}



