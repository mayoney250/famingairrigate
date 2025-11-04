import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/app_routes.dart';
// Removed temporary DB test screen import
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/alert_local_service.dart';
import '../../models/alert_model.dart';
// dev-only simulation imports removed

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int unreadCount = 0;
  List<AlertModel> allAlerts = [];

  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        dashboardProvider.loadDashboardData(authProvider.currentUser!.userId);
      }
      _loadAlerts();
    });
  }

  Future<void> _loadAlerts() async {
    final alerts = await AlertLocalService.getAlerts();
    setState(() {
      allAlerts = alerts..sort((a, b) => b.ts.compareTo(a.ts));
      unreadCount = alerts.where((a) => !a.read).length;
    });
    // Watch for alert box changes
    final box = await Hive.openBox<AlertModel>('alertsBox');
    box.listenable().addListener(() async {
      final current = await AlertLocalService.getAlerts();
      setState(() {
        allAlerts = current..sort((a, b) => b.ts.compareTo(a.ts));
        unreadCount = current.where((a) => !a.read).length;
      });
    });
  }

  void _openAlertCenter() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AlertCenterBottomSheet(alerts: allAlerts, onMarkRead: (id) async {
        await AlertLocalService.markRead(id);
        _loadAlerts();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'FamingaView',
              style: TextStyle(
                color: FamingaBrandColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            // Removed field dropdown from dashboard per request
            const SizedBox.shrink(),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Alerts',
                onPressed: _openAlertCenter,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              return CircleAvatar(
                backgroundColor: FamingaBrandColors.primaryOrange,
                radius: 18,
                child: Text(
                  user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: FamingaBrandColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, _) {
          if (dashboardProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: FamingaBrandColors.primaryOrange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(color: FamingaBrandColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.currentUser != null) {
                await dashboardProvider.refresh(authProvider.currentUser!.userId);
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Status Card
                  _buildSystemStatusCard(dashboardProvider),
                  const SizedBox(height: 20),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: FamingaBrandColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 20),

                  // Soil Moisture and Weather Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSoilMoistureCard(dashboardProvider)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildWeatherCard(dashboardProvider)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLiveFieldSensorSummaries(dashboardProvider),
                  const SizedBox(height: 20),
                  // simulation buttons removed

                  // Next Schedule Cycle
                  Text(
                    'Next Schedule Cycle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: FamingaBrandColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildNextScheduleCard(dashboardProvider),
                  const SizedBox(height: 20),

                  // Weekly Performance
                  Text(
                    'Weekly Performance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: FamingaBrandColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyPerformance(dashboardProvider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
      // Removed notification simulator FAB for production
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSystemStatusCard(DashboardProvider dashboardProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FamingaBrandColors.darkGreen,
            FamingaBrandColors.darkGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FamingaBrandColors.darkGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: FamingaBrandColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: FamingaBrandColors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'System Status',
                      style: TextStyle(
                        color: FamingaBrandColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dashboardProvider.systemStatus,
                  style: const TextStyle(
                    color: FamingaBrandColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dashboardProvider.systemStatusMessage,
                  style: TextStyle(
                    color: FamingaBrandColors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FamingaBrandColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: FamingaBrandColors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            Icons.play_circle_outline,
            'Manual Start',
            FamingaBrandColors.primaryOrange,
            () {
              Get.snackbar(
                'Manual Start',
                'Start irrigation manually',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            Icons.info_outline,
            'Farm Info',
            FamingaBrandColors.primaryOrange,
            () {
              Get.toNamed(AppRoutes.fields);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            Icons.calendar_today,
            'Scheduled',
            FamingaBrandColors.primaryOrange,
            () {
              Get.toNamed(AppRoutes.irrigationList);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FamingaBrandColors.borderColor),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: FamingaBrandColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMoistureCard(DashboardProvider dashboardProvider) {
    final avg = dashboardProvider.avgSoilMoisture;
    final moisturePercent = avg != null ? (avg / 100).clamp(0.0, 1.0) : 0.0;
    final moistureText = avg != null ? '${avg.round()}%' : '--';
    final moistureStatus = avg != null
        ? (avg < 40 ? 'Low' : avg < 60 ? 'Moderate' : 'Optimal')
        : 'No Data';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Column(
        children: [
          const Text(
            'Soil Moisture',
            style: TextStyle(
              color: FamingaBrandColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: moisturePercent,
                  strokeWidth: 10,
                  backgroundColor: FamingaBrandColors.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    FamingaBrandColors.darkGreen,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moistureText,
                    style: const TextStyle(
                      color: FamingaBrandColors.darkGreen,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Calculate Average',
            style: TextStyle(
              color: FamingaBrandColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            moistureStatus,
            style: const TextStyle(
              color: FamingaBrandColors.textPrimary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(DashboardProvider dashboardProvider) {
    final weather = dashboardProvider.weatherData;
    
    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FamingaBrandColors.borderColor),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CircularProgressIndicator(
                color: FamingaBrandColors.primaryOrange,
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
              Text(
                'Loading weather...',
                style: TextStyle(
                  color: FamingaBrandColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    // Get weather icon based on condition
    IconData weatherIcon;
    switch (weather.condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        weatherIcon = Icons.wb_sunny;
        break;
      case 'cloudy':
        weatherIcon = Icons.cloud;
        break;
      case 'rainy':
        weatherIcon = Icons.water_drop;
        break;
      case 'stormy':
        weatherIcon = Icons.thunderstorm;
        break;
      default:
        weatherIcon = Icons.wb_cloudy;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Column(
        children: [
          const Text(
            'Local Weather',
            style: TextStyle(
              color: FamingaBrandColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            weatherIcon,
            color: FamingaBrandColors.primaryOrange,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            weather.temperatureString,
            style: const TextStyle(
              color: FamingaBrandColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weather.description.capitalize ?? weather.description,
            style: const TextStyle(
              color: FamingaBrandColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail('Feels Like', weather.feelsLikeString),
              _buildWeatherDetail('Humidity', weather.humidityString),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FamingaBrandColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: FamingaBrandColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNextScheduleCard(DashboardProvider dashboardProvider) {
    final upcoming = dashboardProvider.upcomingSchedules;
    final schedule = dashboardProvider.nextSchedule;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Column(
        children: [
          if (schedule != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(schedule.startTime),
                      style: const TextStyle(
                        color: FamingaBrandColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Duration',
                      style: TextStyle(
                        color: FamingaBrandColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      schedule.formattedDuration,
                      style: const TextStyle(
                        color: FamingaBrandColors.primaryOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: FamingaBrandColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.zoneName,
                  style: const TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else ...[
            const Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 48,
                  color: FamingaBrandColors.textSecondary,
                ),
                SizedBox(height: 12),
                Text(
                  'No Scheduled Irrigation',
                  style: TextStyle(
                    color: FamingaBrandColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start irrigation manually or create a schedule',
                  style: TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
          // Show a compact list of ALL upcoming scheduled cycles if more than 1
          if (upcoming.isNotEmpty)
            Column(
              children: [
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Upcoming irrigations:",
                      style: TextStyle(
                        fontSize: 13,
                        color: FamingaBrandColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                ...upcoming.map((sched) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: FamingaBrandColors.primaryOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sched.name, style: const TextStyle(fontSize: 14)),
                            Text(
                              DateFormat('E, MMM dd, yyyy – hh:mm a').format(sched.startTime),
                              style: const TextStyle(fontSize: 12, color: FamingaBrandColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(sched.formattedDuration),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          if (!(sched.name.toLowerCase().startsWith('manual irrigation') || sched.status == 'running'))
                            ElevatedButton(
                              onPressed: () async {
                                final uid = authProvider.currentUser!.userId;
                                final ok = await dashboardProvider.startScheduledCycleNow(sched.id, uid);
                                if (!ok) {
                                  Get.snackbar('Error', 'Failed to start cycle');
                                }
                              },
                              child: const Text('Start'),
                            ),
                          const SizedBox(width: 8),
                          if (sched.status == 'running')
                            OutlinedButton(
                              onPressed: () async {
                                final uid = authProvider.currentUser!.userId;
                                final ok = await dashboardProvider.stopCycle(sched.id, uid);
                                if (!ok) {
                                  Get.snackbar('Error', 'Failed to stop cycle');
                                }
                              },
                              child: const Text('Stop'),
                            ),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                _showManualStartDialog(dashboardProvider, authProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FamingaBrandColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, color: FamingaBrandColors.white),
                  SizedBox(width: 8),
                  Text(
                    'START CYCLE MANUALLY',
                    style: TextStyle(
                      color: FamingaBrandColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualStartDialog(
    DashboardProvider dashboardProvider,
    AuthProvider authProvider,
  ) {
    final durationController = TextEditingController(text: '60');
    String selectedFieldId = dashboardProvider.selectedFarmId;

    Get.dialog(
      AlertDialog(
        title: const Text('Start Irrigation Manually'),
        content: StatefulBuilder(
          builder: (context, setState) {
            final fields = dashboardProvider.fields; // [{id,name}]
            if (fields.isNotEmpty && !fields.any((f) => f['id'] == selectedFieldId)) {
              selectedFieldId = fields.first['id']!;
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedFieldId,
                  items: fields
                      .map((f) => DropdownMenuItem<String>(
                            value: f['id'],
                            child: Text(f['name'] ?? f['id']!),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedFieldId = val ?? selectedFieldId),
                  decoration: const InputDecoration(labelText: 'Field'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
              ],
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
              Get.back();

              // Show loading
              Get.dialog(
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: FamingaBrandColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const CircularProgressIndicator(
                      color: FamingaBrandColors.primaryOrange,
                    ),
                  ),
                ),
                barrierDismissible: false,
              );

              final field = dashboardProvider.fields.firstWhere(
                (f) => f['id'] == selectedFieldId,
                orElse: () => {'id': selectedFieldId, 'name': selectedFieldId},
              );
              final duration = int.tryParse(durationController.text.trim()) ?? 60;

              final success = await dashboardProvider.startManualIrrigation(
                userId: authProvider.currentUser!.userId,
                fieldId: field['id']!,
                fieldName: field['name'] ?? field['id']!,
                durationMinutes: duration,
              );

              Get.back(); // Close loading

              if (success) {
                Get.snackbar(
                  'Success',
                  'Irrigation cycle started successfully!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusSuccess,
                  colorText: FamingaBrandColors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to start irrigation cycle',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusWarning,
                  colorText: FamingaBrandColors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FamingaBrandColors.darkGreen,
            ),
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformance(DashboardProvider dashboardProvider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FamingaBrandColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: FamingaBrandColors.primaryOrange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Water Usage',
                      style: TextStyle(
                        color: FamingaBrandColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${dashboardProvider.weeklyWaterUsage.round()}',
                  style: const TextStyle(
                    color: FamingaBrandColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Liters this week',
                  style: TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.show_chart,
                      color: FamingaBrandColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FamingaBrandColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.savings,
                      color: FamingaBrandColors.darkGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'KSh Saved',
                      style: TextStyle(
                        color: FamingaBrandColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  dashboardProvider.weeklySavings.round().toStringAsFixed(0),
                  style: const TextStyle(
                    color: FamingaBrandColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This week',
                  style: TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: FamingaBrandColors.darkGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.trending_up,
                      color: FamingaBrandColors.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            // Already on Dashboard
            break;
          case 1:
            Get.offAllNamed(AppRoutes.irrigationList);
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

  Widget _buildLiveFieldSensorSummaries(DashboardProvider dashboardProvider) {
    final fields = dashboardProvider.fields;
    final sensors = dashboardProvider.latestSensorDataPerField;
    final flows = dashboardProvider.latestFlowDataPerField;
    if (fields.isEmpty) {
      return const Text('No fields found.', style: TextStyle(color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.map((f) {
        final sid = f['id']!;
        final sensor = sensors[sid];
        final flow = flows[sid];
        String waterMsg = '';
        String soilMsg = '';
        if (sensor != null) {
          if (sensor.soilMoisture < 50) {
            soilMsg = "Soil is dry – it's time to irrigate.";
          } else if (sensor.soilMoisture > 100) {
            soilMsg = "Soil is too wet – check drainage.";
          } else {
            soilMsg = "Soil conditions are optimal – no action needed.";
          }
        }
        // (Add more logic here if you want to flag abnormal water usage)

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FamingaBrandColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f['name'] ?? sid,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (kDebugMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final firebaseUid = fb.FirebaseAuth.instance.currentUser?.uid;
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final ok = await dashboardProvider.addTestFlowUsage(
                        userId: firebaseUid ?? auth.currentUser!.userId,
                        fieldId: sid,
                      );
                      if (ok) {
                        Get.snackbar('Flow Test', 'Test water usage added', snackPosition: SnackPosition.BOTTOM);
                      } else {
                        final msg = dashboardProvider.lastActionError ?? 'Failed to add test usage';
                        Get.snackbar('Flow Test', msg, snackPosition: SnackPosition.BOTTOM);
                      }
                    },
                    icon: const Icon(Icons.science, size: 16),
                    label: const Text('Add Test Water'),
                    style: TextButton.styleFrom(
                      foregroundColor: FamingaBrandColors.primaryOrange,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('Soil Water: ' + (sensor != null ? '${sensor.soilMoisture.toStringAsFixed(1)}%' : '--'))),
                  Expanded(child: Text('Temp: ' + (sensor != null ? '${sensor.temperature.toStringAsFixed(1)}°C' : '--'))),
                  Expanded(child: Text('Water Used: ' + (flow != null ? '${flow.liters.toStringAsFixed(2)} L' : '--'))),
                ],
              ),
              if (soilMsg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    soilMsg,
                    style: TextStyle(
                      color: soilMsg.contains('optimal')
                        ? Colors.green
                        : (soilMsg.contains('dry') ? Colors.orange : Colors.blue),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class AlertCenterBottomSheet extends StatelessWidget {
  final List<AlertModel> alerts;
  final Future<void> Function(String id) onMarkRead;
  const AlertCenterBottomSheet({required this.alerts, required this.onMarkRead});
  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No alerts yet')),);
    }
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final a = alerts[i];
          Color iconColor = a.severity == 'high'
              ? Colors.red
              : a.severity == 'medium' ? Colors.orange : Colors.green;
          IconData icon = a.type == 'OFFLINE'
              ? Icons.sensor_door
              : a.type == 'VALVE'
                  ? Icons.water_drop
                  : Icons.warning;
          return ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(a.message,
                style: TextStyle(fontWeight: a.read ? FontWeight.normal : FontWeight.bold)),
            subtitle: Text('${a.type} • ${a.severity} • ${timeAgo(a.ts)}'),
            trailing: a.read
                ? null
                : IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    tooltip: 'Mark as read',
                    onPressed: () => onMarkRead(a.id),
                  ),
          );
        },
      ),
    );
  }

  String timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}min ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
