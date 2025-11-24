import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/irrigation_log_model.dart';
import '../../providers/auth_provider.dart';
<<<<<<< HEAD
import '../../services/irrigation_log_service.dart';
import '../../services/irrigation_service.dart';
=======
import '../../providers/language_provider.dart';
import '../../services/irrigation_log_service.dart';
import '../../services/irrigation_service.dart';
import '../../widgets/shimmer/shimmer_widgets.dart';
import '../../utils/l10n_extensions.dart';
>>>>>>> hyacinthe

class IrrigationControlScreen extends StatelessWidget {
  const IrrigationControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.userId ?? '';
=======
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId ?? '';
>>>>>>> hyacinthe
    final logsService = IrrigationLogService();
    final irrigationService = IrrigationService();

    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: const Text('Irrigation Control')),
=======
      appBar: AppBar(title: Text(context.l10n.irrigationControlTitle)),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      title: 'Open Valve',
                      note: 'Ensure personnel and equipment are clear of active irrigation paths.',
=======
                      title: context.l10n.openValve,
                      note: context.l10n.ensurePersonnel,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                    label: const Text('OPEN'),
=======
                    label: Text(context.l10n.openValve),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                      title: 'Close Valve',
                      note: 'Confirm that manual irrigation should stop now.',
=======
                      title: context.l10n.closeValve,
                      note: context.l10n.confirmStopIrrigation,
>>>>>>> hyacinthe
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
<<<<<<< HEAD
                    label: const Text('CLOSE'),
=======
                    label: Text(context.l10n.closeValve),
>>>>>>> hyacinthe
                  ),
                ),
              ],
            ),
          ),
<<<<<<< HEAD
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Action Log',
                style: TextStyle(fontWeight: FontWeight.bold),
=======
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.actionLog,
                style: const TextStyle(fontWeight: FontWeight.bold),
>>>>>>> hyacinthe
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<IrrigationLogModel>>(
              stream: logsService.streamUserLogs(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
<<<<<<< HEAD
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = snapshot.data ?? const <IrrigationLogModel>[];
                if (logs.isEmpty) {
                  return const Center(child: Text('No actions yet'));
=======
                  return const Center(
              child: ShimmerCenter(size: 48),
            );
                }
                final logs = snapshot.data ?? const <IrrigationLogModel>[];
                if (logs.isEmpty) {
                  return Center(child: Text(context.l10n.noActionsYet));
>>>>>>> hyacinthe
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
<<<<<<< HEAD
            Text('Safety Note', style: textTheme.titleMedium),
=======
            Text(context.l10n.safetyNoteTitle, style: textTheme.titleMedium),
>>>>>>> hyacinthe
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
<<<<<<< HEAD
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
=======
          TextButton(onPressed: () => Get.back(), child: Text(context.l10n.cancelButton)),
>>>>>>> hyacinthe
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await onConfirm();
            },
<<<<<<< HEAD
            child: const Text('Confirm'),
=======
            child: Text(context.l10n.ok),
>>>>>>> hyacinthe
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


