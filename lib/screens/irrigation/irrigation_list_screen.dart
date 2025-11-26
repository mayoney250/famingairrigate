import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/irrigation_schedule_model.dart';
import '../../widgets/shimmer/shimmer_widgets.dart';
import '../../services/irrigation_service.dart';
import '../../services/irrigation_status_service.dart';
import '../../routes/app_routes.dart';
import '../../services/field_service.dart';
import '../../utils/l10n_extensions.dart';
import '../../providers/language_provider.dart';

class IrrigationListScreen extends StatefulWidget {
  const IrrigationListScreen({super.key});

  @override
  State<IrrigationListScreen> createState() => _IrrigationListScreenState();
}

class _IrrigationListScreenState extends State<IrrigationListScreen> {
  final IrrigationService _irrigationService = IrrigationService();
  final IrrigationStatusService _statusService = IrrigationStatusService();
  int _selectedIndex = 1;
  Timer? _statusTick;
  final Set<String> _deletedIds = <String>{};

  Future<List<Map<String, String>>> _fetchFieldOptions(BuildContext context) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser == null) {
        print('[SCHEDULE] No authenticated user found');
        return [];
      }
      
      final svc = FieldService();
      final list = await svc.getUserFields(auth.currentUser!.userId).first;
      print('[SCHEDULE] Fetched ${list.length} fields');
      
      if (list.isEmpty) {
        print('[SCHEDULE] No fields available for user');
        return [];
      }
      
      return list.map((f) => {'id': f.id, 'name': f.label}).toList();
    } catch (e) {
      print('[SCHEDULE] Error fetching field options: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    // Run once on open
    _statusService.startDueSchedules();
    _statusService.markDueIrrigationsCompleted();
    // Poll every 60s to auto-complete any overdue cycles
    _statusTick = Timer.periodic(const Duration(seconds: 60), (_) {
      _statusService.startDueSchedules();
      _statusService.markDueIrrigationsCompleted();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusTick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.userId;

    if (!authProvider.hasAuthChecked) {
      return Scaffold(
          appBar: AppBar(title: Text(context.l10n.irrigationSchedulesTitle)),
        body: const Center(
          child: CircularProgressIndicator(
            color: FamingaBrandColors.primaryOrange,
          ),
        ),
      );
    }

    if (userId == null) {
      return Scaffold(
          appBar: AppBar(title: Text(context.l10n.irrigationSchedulesTitle)),
        body: Center(
            child: Text(context.l10n.pleaseLoginToViewSchedules),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
          title: Text(context.l10n.irrigationSchedulesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openCreateSchedule(context, userId),
          ),
        ],
      ),
      body: StreamBuilder<List<IrrigationScheduleModel>>(
        stream: _irrigationService.getUserSchedules(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const ShimmerIrrigationCard(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: FamingaBrandColors.statusWarning,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading schedules',
                    style: TextStyle(
                      color: FamingaBrandColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      color: FamingaBrandColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final schedules = snapshot.data ?? [];

          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: FamingaBrandColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                      context.l10n.noIrrigationSchedules,
                    style: TextStyle(
                      color: FamingaBrandColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      context.l10n.createFirstSchedule,
                    style: TextStyle(
                      color: FamingaBrandColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateSchedule(context, userId),
                    icon: const Icon(Icons.add),
                      label: Text(context.l10n.createScheduleButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FamingaBrandColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.where((s) => !_deletedIds.contains(s.id)).length,
              itemBuilder: (context, index) {
                final visible = schedules.where((s) => !_deletedIds.contains(s.id)).toList();
                final schedule = visible[index];
                return _buildScheduleCard(schedule);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildScheduleCard(IrrigationScheduleModel schedule) {
    // Determine status and styling based on schedule status
    Color statusColor;
    IconData statusIcon;
    
    switch (schedule.status) {
      case 'running':
        statusColor = FamingaBrandColors.statusSuccess;
        statusIcon = Icons.play_circle;
        break;
      case 'stopped':
        statusColor = FamingaBrandColors.statusWarning;
        statusIcon = Icons.stop_circle;
        break;
      case 'completed':
        statusColor = FamingaBrandColors.textSecondary;
        statusIcon = Icons.check_circle;
        break;
      case 'scheduled':
      default:
        statusColor = FamingaBrandColors.primaryOrange;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showScheduleDetails(schedule);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.name,
                          style: const TextStyle(
                            color: FamingaBrandColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          schedule.zoneName,
                          style: const TextStyle(
                            color: FamingaBrandColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(schedule.startTime),
                          style: const TextStyle(
                            color: FamingaBrandColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schedule.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(
                    Icons.access_time,
                    schedule.formattedTime,
                  ),
                  const SizedBox(width: 24),
                  _buildInfoItem(
                    Icons.timer,
                    schedule.formattedDuration,
                  ),
                  if (schedule.repeatDays.isNotEmpty) ...[
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      Icons.repeat,
                      '${schedule.repeatDays.length} days',
                    ),
                  ],
                ],
              ),
              // Show action buttons based on status
              if (schedule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _stopIrrigation(schedule),
                    icon: const Icon(Icons.stop, size: 18),
                      label: Text(context.l10n.stopIrrigationButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FamingaBrandColors.statusWarning,
                      foregroundColor: FamingaBrandColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              // Show start button for scheduled cycles
              if (schedule.status == 'scheduled' && !schedule.isManual) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startScheduledCycleNow(schedule),
                    icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(context.l10n.startNowButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FamingaBrandColors.statusSuccess,
                      foregroundColor: FamingaBrandColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Update button (hide when running to avoid ambiguity)
                  if (schedule.status != 'running')
                    TextButton.icon(
                      onPressed: () => _openEditSchedule(context, schedule),
                      icon: const Icon(Icons.edit_outlined),
                        label: Text(context.l10n.updateButton),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      if (schedule.status == 'running') {
                          Get.snackbar(context.l10n.notAllowed, context.l10n.stopCycleBeforeDeleting);
                        return;
                      }
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: Text(context.l10n.deleteSchedule),
                          content: Text(context.l10n.areYouSureDelete),
                          actions: [
                              TextButton(onPressed: () => Get.back(result: false), child: Text(context.l10n.cancelButton)),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                                child: Text(context.l10n.deleteButton),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        if (schedule.id.isEmpty) {
                            Get.snackbar(context.l10n.error, context.l10n.invalidScheduleId);
                          return;
                        }
                        final ok = await _irrigationService.deleteSchedule(schedule.id);
                        if (ok) {
                          // Optimistic UI remove
                          setState(() {
                            _deletedIds.add(schedule.id);
                          });
                          Get.snackbar(
                              context.l10n.success,
                              context.l10n.scheduleDeletedSuccessfully,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            colorText: Theme.of(context).colorScheme.onSurface,
                          );
                        } else {
                            Get.snackbar(context.l10n.error, context.l10n.failedDeleteSchedule);
                        }
                      } catch (e) {
                          Get.snackbar(context.l10n.error, 'Delete failed: $e');
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    icon: const Icon(Icons.delete_outline),
                      label: Text(context.l10n.deleteButton),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: FamingaBrandColors.iconColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: FamingaBrandColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _stopIrrigation(IrrigationScheduleModel schedule) {
    Get.dialog(
      AlertDialog(
        title: const Text('Stop Irrigation'),
        content: Text(
          'Are you sure you want to stop irrigation for ${schedule.zoneName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // Show loading
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(
                    color: FamingaBrandColors.primaryOrange,
                  ),
                ),
                barrierDismissible: false,
              );
              
              final success = await _irrigationService.stopIrrigationManually(
                schedule.id,
              );
              
              Get.back(); // Close loading
              
              if (success) {
                Get.snackbar(
                  'Success',
                  'Irrigation stopped successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusSuccess,
                  colorText: FamingaBrandColors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to stop irrigation. Please try again.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusWarning,
                  colorText: FamingaBrandColors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FamingaBrandColors.statusWarning,
            ),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  /// Start a scheduled cycle immediately (manual trigger)
  void _startScheduledCycleNow(IrrigationScheduleModel schedule) {
    Get.dialog(
      AlertDialog(
        title: const Text('Start Irrigation Now'),
        content: Text(
          'Start irrigation for ${schedule.zoneName} immediately?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // Show loading
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(
                    color: FamingaBrandColors.primaryOrange,
                  ),
                ),
                barrierDismissible: false,
              );
              
              final success = await _statusService.startScheduledNow(schedule.id);
              
              Get.back(); // Close loading
              
              if (success) {
                Get.snackbar(
                  'Success',
                  'Irrigation started successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusSuccess,
                  colorText: FamingaBrandColors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to start irrigation. Please try again.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusWarning,
                  colorText: FamingaBrandColors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FamingaBrandColors.statusSuccess,
            ),
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDetails(IrrigationScheduleModel schedule) {
    final repeatDaysText = schedule.repeatDays.isEmpty 
        ? 'One-time' 
        : schedule.repeatDays.map((day) {
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            return days[day - 1];
          }).join(', ');
    
    Get.dialog(
      AlertDialog(
        title: Text(schedule.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Zone', schedule.zoneName),
            _buildDetailRow('Start Time', schedule.formattedTime),
            _buildDetailRow('Duration', schedule.formattedDuration),
            _buildDetailRow('Repeat', repeatDaysText),
            _buildDetailRow('Status', schedule.status.toUpperCase()),
            if (schedule.lastRun != null)
              _buildDetailRow('Last Run', DateFormat('MMM dd, yyyy hh:mm a').format(schedule.lastRun!)),
            if (schedule.nextRun != null)
              _buildDetailRow('Next Run', DateFormat('MMM dd, yyyy hh:mm a').format(schedule.nextRun!)),
            if (schedule.stoppedAt != null)
              _buildDetailRow('Stopped At', DateFormat('MMM dd, yyyy hh:mm a').format(schedule.stoppedAt!)),
            if (schedule.stoppedBy != null)
              _buildDetailRow('Stopped By', schedule.stoppedBy!),
          ],
        ),
        actions: [
          if (schedule.status == 'running')
            TextButton(
              onPressed: () {
                Get.back();
                _stopIrrigation(schedule);
              },
              style: TextButton.styleFrom(
                foregroundColor: FamingaBrandColors.statusWarning,
              ),
              child: const Text('Stop'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateSchedule(BuildContext context, String userId) async {
    // First check if user has any fields
    final fields = await _fetchFieldOptions(context);
    
    if (fields.isEmpty) {
      _showNoFieldsModal(context, userId);
      return;
    }

    // User has fields, proceed with schedule creation
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    DateTime selectedStart = DateTime.now().add(const Duration(minutes: 5));

    final dash = Provider.of<DashboardProvider>(context, listen: false);
    String selectedFieldId = dash.selectedFarmId;
    final scheme = Theme.of(context).colorScheme;
    final fieldsFuture = Future.value(fields); // Use already fetched fields

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            // Use FutureBuilder so we fetch fields dynamically once per open
            // The rest of the form stays the same
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(context.l10n.createScheduleName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                      decoration: InputDecoration(labelText: context.l10n.scheduleName, border: const OutlineInputBorder()),
                  ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String,String>>>(
                      future: fieldsFuture,
                      builder: (context, snap) {
                        final options = snap.data ?? <Map<String,String>>[];
                        if (options.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: Text(context.l10n.noFieldsAvailableMessage),
                          );
                        }
                        if (!options.any((f) => f['id'] == selectedFieldId)) {
                          selectedFieldId = options.first['id']!;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedFieldId,
                              icon: const Icon(Icons.arrow_drop_down),
                              isExpanded: true,
                              items: options
                                  .map((f) => DropdownMenuItem<String>(
                                        value: f['id'],
                                        child: Text(f['name'] ?? f['id']!),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => selectedFieldId = val ?? selectedFieldId),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                      decoration: InputDecoration(labelText: context.l10n.durationMinutes, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                        Text('${context.l10n.startTimeLabel}: ', style: Theme.of(context).textTheme.bodyMedium),
                      Text(DateFormat('MMM dd, yyyy hh:mm a').format(selectedStart)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final firstDate = now.subtract(const Duration(minutes: 1));
                          final initialDate = selectedStart.isBefore(firstDate) ? now : selectedStart;

                          final date = await showDatePicker(
                            context: context,
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                            initialDate: initialDate,
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedStart),
                          );
                          if (time == null) return;
                          setState(() {
                              selectedStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          });
                        },
                        child: Text(context.l10n.pickButton),
                      ),
                    ],
                  ),
                    const SizedBox(height: 16),
                    Row(
                    children: [
                        TextButton(onPressed: () => Get.back(), child: Text(context.l10n.cancelButton)),
                        const Spacer(),
          ElevatedButton(
           onPressed: () async {
             try {
               print('[SCHEDULE] Creating new schedule...');
               
               final name = nameController.text.trim().isEmpty ? 'Scheduled Cycle' : nameController.text.trim();
               final duration = int.tryParse(durationController.text.trim()) ?? 60;
               
               if (duration <= 0) {
                 Get.snackbar('Invalid', 'Duration must be greater than 0');
                 return;
               }
               
               List<Map<String,String>> options = await fieldsFuture;
               if (options.isEmpty) {
                 Get.snackbar('Error', 'No fields available. Please create a field first.');
                 return;
               }
               
               final field = options.firstWhere(
                 (f) => f['id'] == selectedFieldId, 
                 orElse: () => options.first
               );
               
               print('[SCHEDULE] Selected field: ${field['name']} (${field['id']})');
               
               final schedule = IrrigationScheduleModel(
                 id: '',
                 userId: userId,
                 name: name,
                 zoneId: field['id']!,
                 zoneName: field['name'] ?? field['id']!,
                 startTime: selectedStart,
                 durationMinutes: duration,
                 repeatDays: const <int>[],
                 isActive: true,
                 status: 'scheduled',
                 createdAt: DateTime.now(),
               );
               
               print('[SCHEDULE] Saving schedule: ${schedule.name}');
               final ok = await _irrigationService.createSchedule(schedule);
               
               if (ok) {
                 print('[SCHEDULE] Schedule created successfully');
                 Get.back();
                 Get.snackbar(
                   'Success', 
                   'Schedule created successfully',
                   snackPosition: SnackPosition.BOTTOM,
                 );
               } else {
                 print('[SCHEDULE] Failed to create schedule');
                 Get.snackbar(
                   'Error', 
                   'Failed to save schedule. Please try again.',
                   snackPosition: SnackPosition.BOTTOM,
                 );
               }
             } catch (e) {
               print('[SCHEDULE] Error creating schedule: $e');
               Get.snackbar(
                 'Error', 
                 'An error occurred: $e',
                 snackPosition: SnackPosition.BOTTOM,
               );
             }
                         },
                         style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                         child: const Text('Save'),
                       )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditSchedule(BuildContext context, IrrigationScheduleModel schedule) {
    final nameController = TextEditingController(text: schedule.name);
    final durationController = TextEditingController(text: schedule.durationMinutes.toString());
    DateTime selectedStart = schedule.startTime;

    final dash = Provider.of<DashboardProvider>(context, listen: false);
    String selectedFieldId = schedule.zoneId.isNotEmpty ? schedule.zoneId : dash.selectedFarmId;
    final scheme = Theme.of(context).colorScheme;
    final fieldsFuture = _fetchFieldOptions(context);

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            final fieldOptionsAsync = fieldsFuture;
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update Irrigation Schedule', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Schedule Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String,String>>>(
                      future: fieldOptionsAsync,
                      builder: (context, snap) {
                        final options = snap.data ?? <Map<String,String>>[];
                        if (options.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),
                            child: const Text('No fields available'),
                          );
              }
                        if (!options.any((f) => f['id'] == selectedFieldId)) {
                          selectedFieldId = options.first['id']!;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedFieldId,
                              icon: const Icon(Icons.arrow_drop_down),
                              isExpanded: true,
                              items: options
                                  .map((f) => DropdownMenuItem<String>(
                                        value: f['id'],
                                        child: Text(f['name'] ?? f['id']!),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => selectedFieldId = val ?? selectedFieldId),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Start Time: ', style: Theme.of(context).textTheme.bodyMedium),
                        Text(DateFormat('MMM dd, yyyy hh:mm a').format(selectedStart)),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final firstDate = now.subtract(const Duration(minutes: 1)); // Allow slight buffer
                            final initialDate = selectedStart.isBefore(firstDate) ? now : selectedStart;

                            final date = await showDatePicker(
                              context: context,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                              initialDate: initialDate,
                            );
                            if (date == null) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedStart),
                            );
                            if (time == null) return;
                            setState(() {
                              selectedStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          },
                          child: const Text('Pick'),
          ),
        ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              print('[SCHEDULE] Updating schedule: ${schedule.id}');
                              
                              final nameText = nameController.text.trim();
                              if (nameText.isEmpty) {
                                Get.snackbar('Invalid', 'Please enter a schedule name');
                                return;
                              }
                              
                              final parsed = int.tryParse(durationController.text.trim());
                              if (parsed == null || parsed <= 0) {
                                Get.snackbar('Invalid', 'Duration must be a positive number');
                                return;
                              }
                              final duration = parsed;
                              
                              List<Map<String,String>> options = await fieldOptionsAsync;
                              if (options.isEmpty) {
                                Get.snackbar('Error', 'No fields available');
                                return;
                              }
                              
                              final field = options.firstWhere(
                                (f) => f['id'] == selectedFieldId, 
                                orElse: () => options.first
                              );

                              print('[SCHEDULE] Selected field: ${field['name']} (${field['id']})');

                              final now = DateTime.now();
                              // Calculate nextRun based on whether it's a recurring schedule
                              DateTime? nextRunTime;
                              if (schedule.repeatDays.isNotEmpty) {
                                // For recurring schedules, find next occurrence
                                for (int i = 0; i < 7; i++) {
                                  final candidateDay = selectedStart.add(Duration(days: i));
                                  if (schedule.repeatDays.contains(candidateDay.weekday)) {
                                    nextRunTime = DateTime(
                                      candidateDay.year,
                                      candidateDay.month,
                                      candidateDay.day,
                                      selectedStart.hour,
                                      selectedStart.minute,
                                    );
                                    if (nextRunTime.isAfter(now)) break;
                                  }
                                }
                              }

                              final updateData = {
                                'name': nameText,
                                'zoneId': field['id'],
                                'zoneName': field['name'] ?? field['id'],
                                'startTime': Timestamp.fromDate(selectedStart),
                                'nextRun': nextRunTime != null ? Timestamp.fromDate(nextRunTime) : null,
                                'durationMinutes': duration,
                                'status': 'scheduled',
                                'updatedAt': Timestamp.fromDate(now),
                              };

                              print('[SCHEDULE] Updating with data: $updateData');

                              await FirebaseFirestore.instance
                                  .collection('irrigationSchedules')
                                  .doc(schedule.id)
                                  .update(updateData);
                              
                              print('[SCHEDULE] Schedule updated successfully');
                              Get.back();
                              Get.snackbar(
                                'Updated', 
                                'Schedule updated successfully',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } catch (e) {
                              print('[SCHEDULE] Error updating schedule: $e');
                              Get.snackbar(
                                'Error', 
                                'Failed to update schedule: $e',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                          child: const Text('Save'),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: FamingaBrandColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (index == _selectedIndex) return;

        setState(() => _selectedIndex = index);

        switch (index) {
          case 0:
            Get.offAllNamed(AppRoutes.dashboard);
            break;
          case 1:
            // Already on Irrigation
            break;
          case 2:
            Get.offAllNamed(AppRoutes.fields);
            break;
          case 3:
            Get.offAllNamed(AppRoutes.sensors);
            break;
          case 4:
            Get.offAllNamed(AppRoutes.profile);
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: FamingaBrandColors.primaryOrange,
      unselectedItemColor: FamingaBrandColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: 'Irrigation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.landscape),
          label: 'Fields',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sensors),
          label: 'Sensors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _showNoFieldsModal(BuildContext context, String userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.landscape_outlined,
                  size: 40,
                  color: FamingaBrandColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'No Fields Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                'You don\'t have any fields registered. Please create a field first to add an irrigation schedule.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark 
                              ? Colors.white.withOpacity(0.3)
                              : FamingaBrandColors.darkGreen.withOpacity(0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.offAllNamed(AppRoutes.fields);
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Go to Fields'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FamingaBrandColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
