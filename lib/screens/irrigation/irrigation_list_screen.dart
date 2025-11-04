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
import '../../services/irrigation_service.dart';
import '../../services/irrigation_status_service.dart';
import '../../routes/app_routes.dart';
import '../../services/field_service.dart';

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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final svc = FieldService();
    final list = await svc.getUserFields(auth.currentUser!.userId).first;
    return list.map((f) => {'id': f.id, 'name': f.label}).toList();
  }

  @override
  void initState() {
    super.initState();
    // Run once on open
    _statusService.markDueIrrigationsCompleted();
    // Poll every 60s to auto-complete any overdue cycles
    _statusTick = Timer.periodic(const Duration(seconds: 60), (_) {
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
        appBar: AppBar(title: const Text('Irrigation Schedules')),
        body: const Center(
          child: CircularProgressIndicator(
            color: FamingaBrandColors.primaryOrange,
          ),
        ),
      );
    }

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Irrigation Schedules')),
        body: const Center(
          child: Text('Please log in to view schedules'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Irrigation Schedules'),
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
            return const Center(
              child: CircularProgressIndicator(
                color: FamingaBrandColors.primaryOrange,
              ),
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
                  const Text(
                    'No Irrigation Schedules',
                    style: TextStyle(
                      color: FamingaBrandColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first irrigation schedule',
                    style: TextStyle(
                      color: FamingaBrandColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateSchedule(context, userId),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Schedule'),
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
              // Show stop button if irrigation is running
              if (schedule.status == 'running') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _stopIrrigation(schedule),
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Stop Irrigation'),
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
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Update button (hide when running to avoid ambiguity)
                  if (schedule.status != 'running')
                    TextButton.icon(
                      onPressed: () => _openEditSchedule(context, schedule),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Update'),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      if (schedule.status == 'running') {
                        Get.snackbar('Not allowed', 'Stop the cycle before deleting');
                        return;
                      }
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Delete Schedule'),
                          content: const Text('Are you sure you want to delete this irrigation schedule?'),
                          actions: [
                            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        if (schedule.id.isEmpty) {
                          Get.snackbar('Error', 'Invalid schedule id');
                          return;
                        }
                        final ok = await _irrigationService.deleteSchedule(schedule.id);
                        if (ok) {
                          // Optimistic UI remove
                          setState(() {
                            _deletedIds.add(schedule.id);
                          });
                          Get.snackbar(
                            'Success',
                            'Schedule deleted successfully.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            colorText: Theme.of(context).colorScheme.onSurface,
                          );
                        } else {
                          Get.snackbar('Error', 'Failed to delete schedule');
                        }
                      } catch (e) {
                        Get.snackbar('Error', 'Delete failed: $e');
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
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

  void _openCreateSchedule(BuildContext context, String userId) {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    DateTime selectedStart = DateTime.now().add(const Duration(minutes: 5));

    final dash = Provider.of<DashboardProvider>(context, listen: false);
    String selectedFieldId = dash.selectedFarmId;
    final scheme = Theme.of(context).colorScheme;
    final fieldsFuture = _fetchFieldOptions(context); // fetch once when modal opens

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
                    Text('Create Irrigation Schedule', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Schedule Name', border: OutlineInputBorder()),
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
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              initialDate: selectedStart,
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
                            final name = nameController.text.trim().isEmpty ? 'Scheduled Cycle' : nameController.text.trim();
                            final duration = int.tryParse(durationController.text.trim()) ?? 60;
                            List<Map<String,String>> options = await fieldsFuture;
                            final field = options.firstWhere((f) => f['id'] == selectedFieldId, orElse: () => {'id': selectedFieldId, 'name': selectedFieldId});
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
                            final ok = await _irrigationService.createSchedule(schedule);
                            if (ok) {
                              Get.back();
                              Get.snackbar('Success', 'Schedule saved');
                            } else {
                              Get.snackbar('Error', 'Failed to save schedule');
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
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              initialDate: selectedStart,
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
                            final field = options.firstWhere((f) => f['id'] == selectedFieldId, orElse: () => {'id': selectedFieldId, 'name': selectedFieldId});

                            await FirebaseFirestore.instance
                                .collection('irrigationSchedules')
                                .doc(schedule.id)
                                .update({
                              'name': nameText,
                              'zoneId': field['id'],
                              'zoneName': field['name'] ?? field['id'],
                              'startTime': Timestamp.fromDate(selectedStart),
                              'durationMinutes': duration,
                              'updatedAt': Timestamp.fromDate(DateTime.now()),
                            });
                            Get.back();
                            Get.snackbar('Updated', 'Schedule updated');
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
}
