import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/irrigation_schedule_model.dart';
import '../../services/irrigation_service.dart';
import '../../routes/app_routes.dart';

class IrrigationListScreen extends StatefulWidget {
  const IrrigationListScreen({super.key});

  @override
  State<IrrigationListScreen> createState() => _IrrigationListScreenState();
}

class _IrrigationListScreenState extends State<IrrigationListScreen> {
  final IrrigationService _irrigationService = IrrigationService();
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.userId;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!authProvider.hasAuthChecked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Irrigation Schedules')),
        body: Center(child: CircularProgressIndicator(color: scheme.primary)),
      );
    }

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Irrigation Schedules')),
        body: const Center(child: Text('Please log in to view schedules')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Irrigation Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Schedule',
            onPressed: () => _openCreateOrEditSchedule(context, userId),
          ),
        ],
      ),
      body: StreamBuilder<List<IrrigationScheduleModel>>(
        stream: _irrigationService.getUserSchedules(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: scheme.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: scheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading schedules', style: textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
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
                  Icon(Icons.calendar_today, size: 64, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No Irrigation Schedules',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Create your first irrigation schedule',
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateOrEditSchedule(context, userId),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ScheduleCard(
                  key: ValueKey(schedules[index].id),
                  schedule: schedules[index],
                  onEdit: () => _openCreateOrEditSchedule(context, userId, edit: schedules[index]),
                  onDelete: () => _deleteSchedule(context, schedules[index]),
                  onToggle: () async => await _toggleSchedule(context, schedules[index], userId),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final scheme = Theme.of(context).colorScheme;
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
            break; // Already here
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
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      backgroundColor: scheme.surface,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Irrigation'),
        BottomNavigationBarItem(icon: Icon(Icons.landscape), label: 'Fields'),
        BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  void _openCreateOrEditSchedule(BuildContext context, String userId,
      {IrrigationScheduleModel? edit}) async {
    final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
    final fieldList = dashProvider.fields;
    final isEditing = edit != null;
    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    String? zoneId = edit?.zoneId.isNotEmpty == true
        ? edit!.zoneId
        : (fieldList.isNotEmpty ? fieldList.first['id'] : null);
    int duration = edit?.durationMinutes ?? 60;
    DateTime start =
        edit?.startTime ?? DateTime.now().add(const Duration(minutes: 5));
    List<int> selected = List<int>.from(edit?.repeatDays ?? []);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape:
          const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: StatefulBuilder(
          builder: (context, refreshModal) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(isEditing ? 'Edit Schedule' : 'New Schedule',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Schedule Name',
                        prefixIcon: Icon(Icons.label, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: zoneId,
                      decoration: InputDecoration(
                        labelText: 'Zone/Field',
                        prefixIcon: Icon(Icons.landscape, color: Theme.of(context).colorScheme.secondary),
                      ),
                      items: dashProvider.fields
                          .map((f) => DropdownMenuItem(
                                value: f['id'],
                                child: Text(f['name']!),
                              ))
                          .toList(),
                      onChanged: (value) => refreshModal(() => zoneId = value),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                      title: Text('Start Time'),
                      subtitle: Text(DateFormat('yMMMd hh:mm a').format(start)),
                      trailing: OutlinedButton(
                        child: const Text('Pick'),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: start,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate == null) return;
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(start),
                          );
                          if (pickedTime == null) return;
                          refreshModal(() {
                            start = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                      title: Text('Duration (minutes)'),
                      trailing: SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) {
                            final val = int.tryParse(v);
                            if (val != null && val > 0) refreshModal(() => duration = val);
                          },
                          controller: TextEditingController(text: duration.toString()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Repeat Days', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 7,
                      children: List.generate(7, (i) {
                        final dayInt = i + 1;
                        final dayName = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i];
                        return FilterChip(
                          label: Text(dayName),
                          selected: selected.contains(dayInt),
                          onSelected: (checked) {
                            refreshModal(() {
                              if (checked) selected.add(dayInt);
                              else selected.remove(dayInt);
                              selected.sort();
                            });
                          },
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty || zoneId == null) {
                                Get.snackbar('Error', 'Fill all fields',
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    colorText: Theme.of(context).colorScheme.onError);
                                return;
                              }
                              try {
                                if (isEditing) {
                                  await FirebaseFirestore.instance
                                      .collection('irrigationSchedules')
                                      .doc(edit!.id)
                                      .update({
                                    'name': nameCtrl.text.trim(),
                                    'zoneId': zoneId,
                                    'zoneName': dashProvider.fields
                                        .firstWhere((f) => f['id'] == zoneId)['name']
                                        ?.toString() ??
                                        '',
                                    'startTime': Timestamp.fromDate(start),
                                    'durationMinutes': duration,
                                    'repeatDays': selected,
                                    'updatedAt': Timestamp.now(),
                                  });
                                  Get.back();
                                  Get.snackbar('Updated', 'Schedule updated successfully.',
                                      icon: Icon(Icons.check_circle_outline,
                                          color: Theme.of(context).colorScheme.secondary),
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      colorText: Theme.of(context).colorScheme.onSurface);
                                } else {
                                  final schedule = IrrigationScheduleModel(
                                    id: '',
                                    userId: userId,
                                    name: nameCtrl.text.trim(),
                                    zoneId: zoneId!,
                                    zoneName: dashProvider.fields
                                        .firstWhere((f) => f['id'] == zoneId)['name']
                                        ?.toString() ??
                                        '',
                                    startTime: start,
                                    durationMinutes: duration,
                                    repeatDays: selected,
                                    isActive: true,
                                    status: 'scheduled',
                                    createdAt: DateTime.now(),
                                  );
                                  await _irrigationService.createSchedule(schedule);
                                  Get.back();
                                  Get.snackbar('Created', 'Schedule saved',
                                      icon: Icon(Icons.check_circle_outline,
                                          color: Theme.of(context).colorScheme.secondary),
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      colorText: Theme.of(context).colorScheme.onSurface);
                                }
                                setState(() {});
                              } catch (e) {
                                Get.snackbar('Error', "Failed: $e",
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    colorText: Theme.of(context).colorScheme.onError);
                              }
                            },
                            child: Text(isEditing ? 'Save' : 'Create'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _deleteSchedule(BuildContext context, IrrigationScheduleModel schedule) async {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.error),
                const SizedBox(width: 8),
                Text('Delete Schedule?', style: Theme.of(ctx).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 18),
            Text("Are you sure you want to delete '${schedule.name}'?",
                textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final ok = await _irrigationService.deleteSchedule(schedule.id);
                        Get.back();
                        if (ok) {
                          Get.snackbar('Deleted', 'Schedule deleted',
                              icon: Icon(Icons.check_circle_outline, color: scheme.secondary),
                              backgroundColor: scheme.surface,
                              colorText: scheme.onSurface);
                          setState(() {});
                        } else {
                          Get.snackbar('Error', 'Could not delete schedule',
                              backgroundColor: scheme.error, colorText: scheme.onError);
                        }
                      } catch (e) {
                        Get.back();
                        Get.snackbar('Error', e.toString(),
                            backgroundColor: scheme.error, colorText: scheme.onError);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSchedule(BuildContext context, IrrigationScheduleModel schedule, String userId) async {
    final scheme = Theme.of(context).colorScheme;
    bool isOn = schedule.status == 'running';
    final ok = await _irrigationService.toggleSchedule(schedule.id, isOn);
    if (ok) {
      Get.snackbar(isOn ? 'Stopped' : 'Started', isOn ? 'Irrigation stopped' : 'Irrigation started',
        icon: Icon(Icons.check_circle_outline, color: scheme.secondary),
        backgroundColor: scheme.surface,
        colorText: scheme.onSurface);
      setState(() {});
    } else {
      Get.snackbar('Error', 'Action failed', backgroundColor: scheme.error, colorText: scheme.onError);
    }
  }
}

// ------------------- Schedule Card -------------------
class _ScheduleCard extends StatefulWidget {
  final IrrigationScheduleModel schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function() onToggle;

  const _ScheduleCard({Key? key, required this.schedule, required this.onEdit, required this.onDelete, required this.onToggle}) : super(key: key);

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> with SingleTickerProviderStateMixin {
  late bool isRunning;
  Duration? _remaining;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _completedSnackbarShown = false;
  late final scheduleStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  StreamSubscription? _countdownSub;
  @override
  void initState() {
    super.initState();
    _initStateWithCountdown();
  }
  void _initStateWithCountdown() {
    isRunning = widget.schedule.status == 'running';
    _remaining = isRunning
        ? widget.schedule.startTime.add(Duration(minutes: widget.schedule.durationMinutes)).difference(DateTime.now())
        : null;
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _completedSnackbarShown = false;  // reset on card creation
    _countdownSub?.cancel();
    _countdownSub = scheduleStream.listen((_) => _handleCountdownTick());
  }

  void _handleCountdownTick() {
    if (!mounted) return;
    final now = DateTime.now();
    final start = widget.schedule.startTime;
    final end = start.add(Duration(minutes: widget.schedule.durationMinutes));
    bool justBecameRunning = !isRunning && now.isAfter(start) && now.isBefore(end) && widget.schedule.status != 'completed';
    if (justBecameRunning) {
      setState(() {
        isRunning = true;
      });
    }
    if (isRunning) {
      final remaining = end.difference(now);
      setState(() => _remaining = remaining);
      if (remaining <= Duration.zero && !_completedSnackbarShown) {
        setState(() { isRunning = false; });
        _completedSnackbarShown = true;
        // Stop irrigation (auto complete)
        final irrigationService = IrrigationService();
        irrigationService.stopIrrigation(widget.schedule.id);
        Future.microtask(() =>
            Get.snackbar('Completed', 'Irrigation completed',
                icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.secondary),
                backgroundColor: Theme.of(context).colorScheme.surface,
                colorText: Theme.of(context).colorScheme.onSurface));
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final schedule = widget.schedule;
    final endTime = schedule.startTime.add(Duration(minutes: schedule.durationMinutes));
    // Calculate seconds left for better mm:ss formatting
    final secondsLeft = _remaining != null && _remaining!.inSeconds > 0 ? _remaining!.inSeconds : 0;
    return ScaleTransition(
      scale: isRunning ? _pulseAnim : const AlwaysStoppedAnimation(1),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: scheme.primary.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(schedule.name, style: Theme.of(context).textTheme.titleMedium)),
                  PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') widget.onEdit();
                      else if (v == 'delete') widget.onDelete();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(schedule.zoneName, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              if (isRunning && secondsLeft > 0)
                Row(
                  children: [
                    Icon(Icons.timer, color: scheme.primary, size: 18),
                    const SizedBox(width: 7),
                    Text(
                        'Time left: ${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.primary)),
                  ],
                ),
              if (!isRunning && (_remaining == null || secondsLeft == 0))
                Text('Status: ${schedule.status == 'completed' ? 'Completed' : 'Scheduled'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: schedule.status == 'completed' ? null : widget.onToggle,
                    icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(isRunning ? 'Stop' : 'Start'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
