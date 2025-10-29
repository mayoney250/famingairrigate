import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/irrigation_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/irrigation_log_service.dart';
import '../../services/irrigation_service.dart';

class IrrigationControlScreen extends StatelessWidget {
  const IrrigationControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.userId ?? '';
    final logsService = IrrigationLogService();
    final irrigationService = IrrigationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Irrigation Control')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAction(
                      context,
                      title: 'Open Valve',
                      note: 'Ensure personnel and equipment are clear of active irrigation paths.',
                      onConfirm: () async {
                        final ok = await irrigationService.manualOpenValve(userId: userId);
                        _toast(ok, 'Valve opened', 'Failed to open valve');
                      },
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('OPEN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FamingaBrandColors.statusWarning,
                      foregroundColor: FamingaBrandColors.white,
                    ),
                    onPressed: () => _confirmAction(
                      context,
                      title: 'Close Valve',
                      note: 'Confirm that manual irrigation should stop now.',
                      onConfirm: () async {
                        final ok = await irrigationService.manualCloseValve(userId: userId);
                        _toast(ok, 'Valve closed', 'Failed to close valve');
                      },
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text('CLOSE'),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Action Log',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<IrrigationLogModel>>(
              stream: logsService.getRecentLogs(userId: userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = snapshot.data ?? const <IrrigationLogModel>[];
                if (logs.isEmpty) {
                  return const Center(child: Text('No actions yet'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final l = logs[index];
                    final success = l.result?.toLowerCase() == 'success';
                    return ListTile(
                      leading: Icon(
                        l.action?.toLowerCase() == 'open' ? Icons.play_arrow : Icons.stop,
                        color: FamingaBrandColors.iconColor,
                      ),
                      title: Text('${l.action?.toUpperCase()} - ${l.zoneName ?? 'Zone'}'),
                      subtitle: Text(l.timestamp?.toString() ?? ''),
                      trailing: Icon(
                        success ? Icons.check_circle : Icons.error,
                        color: success
                            ? FamingaBrandColors.statusSuccess
                            : FamingaBrandColors.statusWarning,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String note,
    required Future<void> Function() onConfirm,
  }) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Safety Note'),
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(color: FamingaBrandColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _toast(bool ok, String okMsg, String errMsg) {
    if (ok) {
      Get.snackbar('Success', okMsg, snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', errMsg, snackPosition: SnackPosition.BOTTOM);
    }
  }
}


