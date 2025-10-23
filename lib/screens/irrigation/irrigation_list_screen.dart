import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId;

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
            onPressed: () {
              Get.snackbar(
                'Coming Soon',
                'Schedule creation feature coming soon!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<IrrigationSchedule>>(
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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: FamingaBrandColors.statusWarning,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading schedules',
                    style: TextStyle(
                      color: FamingaBrandColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
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
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: FamingaBrandColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Irrigation Schedules',
                    style: TextStyle(
                      color: FamingaBrandColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first irrigation schedule',
                    style: TextStyle(
                      color: FamingaBrandColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        'Coming Soon',
                        'Schedule creation feature coming soon!',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
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

  Widget _buildScheduleCard(IrrigationSchedule schedule) {
    Color statusColor;
    IconData statusIcon;
    
    switch (schedule.status) {
      case 'scheduled':
        statusColor = FamingaBrandColors.primaryOrange;
        statusIcon = Icons.schedule;
        break;
      case 'running':
        statusColor = FamingaBrandColors.statusSuccess;
        statusIcon = Icons.play_circle;
        break;
      case 'completed':
        statusColor = FamingaBrandColors.textSecondary;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = FamingaBrandColors.statusWarning;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = FamingaBrandColors.textSecondary;
        statusIcon = Icons.help_outline;
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
                          schedule.fieldName,
                          style: TextStyle(
                            color: FamingaBrandColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(schedule.startTime),
                          style: TextStyle(
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
                    DateFormat('hh:mm a').format(schedule.startTime),
                  ),
                  const SizedBox(width: 24),
                  _buildInfoItem(
                    Icons.timer,
                    schedule.formattedDuration,
                  ),
                  if (schedule.waterUsed != null) ...[
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      Icons.water_drop,
                      '${schedule.waterUsed!.round()} L',
                    ),
                  ],
                ],
              ),
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
          style: TextStyle(
            color: FamingaBrandColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showScheduleDetails(IrrigationSchedule schedule) {
    Get.dialog(
      AlertDialog(
        title: Text(schedule.fieldName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(schedule.startTime)),
            _buildDetailRow('Time', DateFormat('hh:mm a').format(schedule.startTime)),
            _buildDetailRow('Duration', schedule.formattedDuration),
            _buildDetailRow('Status', schedule.status),
            if (schedule.waterUsed != null)
              _buildDetailRow('Water Used', '${schedule.waterUsed!.round()} liters'),
            if (schedule.notes != null && schedule.notes!.isNotEmpty)
              _buildDetailRow('Notes', schedule.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
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
              style: TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
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
