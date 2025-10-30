import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/irrigation_schedule_model.dart';
import '../../services/irrigation_service.dart';
import '../../services/irrigation_status_service.dart';
import '../../routes/app_routes.dart';

class IrrigationListScreen extends StatefulWidget {
  const IrrigationListScreen({super.key});

  @override
  State<IrrigationListScreen> createState() => _IrrigationListScreenState();
}

class _IrrigationListScreenState extends State<IrrigationListScreen> {
  final IrrigationService _irrigationService = IrrigationService();
  final IrrigationStatusService _statusService = IrrigationStatusService();
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _patchOverdue();
  }

  Future<void> _patchOverdue() async {
    await _statusService.markDueIrrigationsCompleted();
    setState(() {}); // Force refresh after patch
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
      backgroundColor: FamingaBrandColors.backgroundLight,
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
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
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
              
              final success = await _statusService.stopIrrigationManually(
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
    final zoneController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    DateTime selectedStart = DateTime.now().add(const Duration(minutes: 5));

    Get.dialog(
      AlertDialog(
        title: const Text('Create Irrigation Schedule'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Schedule Name'),
                  ),
                  TextField(
                    controller: zoneController,
                    decoration: const InputDecoration(labelText: 'Zone Name'),
                  ),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Start Time: '),
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
                            selectedStart = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        child: const Text('Pick'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim().isEmpty ? 'Scheduled Cycle' : nameController.text.trim();
              final zoneName = zoneController.text.trim().isEmpty ? 'Field' : zoneController.text.trim();
              final duration = int.tryParse(durationController.text.trim()) ?? 60;

              final dash = Provider.of<DashboardProvider>(context, listen: false);
              final schedule = IrrigationScheduleModel(
                id: '',
                userId: userId,
                name: name,
                // Save the selected field/farm id as zoneId so dashboard can scope by it
                zoneId: dash.selectedFarmId,
                zoneName: zoneName,
                startTime: selectedStart,
                durationMinutes: duration,
                repeatDays: const <int>[],
                isActive: true,
                status: 'scheduled',
                createdAt: DateTime.now(),
              );

              final ok = await _statusService.createSchedule(schedule);
              if (ok) {
                Get.back();
                Get.snackbar('Success', 'Schedule created');
                setState(() {});
                // trigger dashboard refresh so "Next Schedule" updates
                final dash = Provider.of<DashboardProvider>(context, listen: false);
                await dash.refresh(userId);
              } else {
                Get.snackbar('Error', 'Failed to create schedule');
              }
            },
            child: const Text('Create'),
          ),
        ],
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
