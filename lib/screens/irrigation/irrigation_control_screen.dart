import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/irrigation_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/irrigation_log_service.dart';
import '../../services/irrigation_service.dart';
import '../../widgets/shimmer/shimmer_widgets.dart';

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
                        // Start a manual irrigation cycle with placeholder field/zone
                        final ok = await irrigationService.startIrrigationManually(
                          userId: userId,
                          farmId: 'defaultFarm',
                          fieldId: 'manual-zone',
                          fieldName: 'Manual Zone',
                          durationMinutes: 30,
                        );
                        _toast(ok, 'Valve opened (manual start)', 'Failed to open valve');
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
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () => _confirmAction(
                      context,
                      title: 'Close Valve',
                      note: 'Confirm that manual irrigation should stop now.',
                      onConfirm: () async {
                        // Without a schedule id context, log a stop entry for UX feedback
                        final logId = await logsService.logIrrigationStop(
                          userId,
                          'manual-zone',
                          'Manual Zone',
                          0,
                          0,
                        );
                        final ok = logId.isNotEmpty;
                        _toast(ok, 'Valve closed (logged stop)', 'Failed to close valve');
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
              stream: logsService.streamUserLogs(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
              child: ShimmerCenter(size: 48),
            );
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
                    final success = l.action != IrrigationAction.failed;
                    final scheme = Theme.of(context).colorScheme;
                    return ListTile(
                      leading: Icon(
                        (l.action == IrrigationAction.started || l.action == IrrigationAction.scheduled)
                            ? Icons.play_arrow
                            : (l.action == IrrigationAction.stopped ? Icons.stop : Icons.check),
                        color: scheme.primary,
                      ),
                      title: Text('${l.actionDisplay} - ${l.zoneName}'),
                      subtitle: Text(l.timestamp.toString()),
                      trailing: Icon(
                        success ? Icons.check_circle : Icons.error,
                        color: success
                            ? scheme.secondary
                            : scheme.error,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(title, style: textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Safety Note', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              note,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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


