import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard/ai_recommendation_badge.dart';
import '../../widgets/shimmer/shimmer_widgets.dart';
import '../../providers/language_provider.dart';
import '../../routes/app_routes.dart';
// Removed temporary DB test screen import
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/alert_local_service.dart';
import '../../models/alert_model.dart';
import '../../utils/l10n_extensions.dart';
import '../../models/forecast_day_model.dart';
import '../../models/sensor_data_model.dart';
import '../../models/ai_recommendation_model.dart';
import '../../models/weather_model.dart';
import '../../models/irrigation_schedule_model.dart';
import '../../services/sensor_discovery_service.dart';
import '../../widgets/sensors/new_sensor_dialog.dart';


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
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _manualStartButtonKey = GlobalKey();
  bool _isManualStartHighlighted = false;
  Timer? _highlightTimer;
  bool _isWeatherCardExpanded = false;
  
  // Dashboard view state
  String _dashboardView = 'Both'; // Options: 'Cloud Data', 'USB Sensor', 'Both'

  StreamSubscription? _discoverySubscription;
  final Set<String> _ignoredSensors = {};

  @override
  void initState() {
    super.initState();
    // Check verification status first - redirect if pending/not verified
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // If user is authenticated, verify their verificationStatus in Firestore
      if (authProvider.isAuthenticated) {
        try {
          final uid = authProvider.currentUser?.userId;
          if (uid != null && uid.isNotEmpty) {
            final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
            final data = doc.data();
            final verificationStatus = data != null && data.containsKey('verificationStatus')
                ? (data['verificationStatus'] as String?)
                : null;

            if (verificationStatus != null && verificationStatus.toLowerCase() == 'pending') {
              Get.offAllNamed('/verification-pending');
              return;
            }
          }
        } catch (e) {
          // If Firestore lookup fails, continue to load dashboard to avoid blocking UX
        }
      }

      // Load dashboard data when screen loads
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        dashboardProvider.loadDashboardData(authProvider.currentUser!.userId);
        _initSensorDiscovery();
      }
      _loadAlerts();
      _startAutoRefresh();
    });
  }

  void _initSensorDiscovery() {
    // Listen for new sensors (Plug-and-Play)
    _discoverySubscription = SensorDiscoveryService().unassignedSensorsStream.listen((sensors) {
      if (!mounted) return;
      
      for (final sensor in sensors) {
        if (!_ignoredSensors.contains(sensor.hardwareId)) {
          _ignoredSensors.add(sensor.hardwareId); // Prevent multiple popups
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => NewSensorDialog(hardwareId: sensor.hardwareId),
          ).then((_) {
            // If dialog closed without claiming (e.g. ignored), keep it ignored for this session
            // or remove from ignore list to show again later? 
            // For now, keep ignored to avoid spam.
          });
          break; // Show one at a time
        }
      }
    });
  }

  void _startAutoRefresh() {
    // Refresh dashboard every 5 seconds to ensure UI stays in sync
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _highlightTimer?.cancel();
    _discoverySubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
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
            Builder(
              builder: (context) => Text(
                'Faminga Irrigation System',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : FamingaBrandColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Removed field dropdown from dashboard per request
            const SizedBox.shrink(),
          ],
        ),
        actions: [
          _buildCompactLanguageSelector(),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: context.l10n.alerts,
                onPressed: _openAlertCenter,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
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
      body: Selector<DashboardProvider, bool>(
        selector: (_, provider) => provider.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 16),
                  ShimmerDashboardStats(),
                  SizedBox(height: 24),
                  ShimmerFieldCard(),
                  ShimmerFieldCard(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
              if (authProvider.currentUser != null) {
                await dashboardProvider.refresh(authProvider.currentUser!.userId);
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                final isLargeScreen = constraints.maxWidth > 900;
                final double padding = isSmallScreen ? 12.0 : 24.0;

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLargeScreen)
                        _buildLargeScreenLayout()
                      else
                        _buildMobileLayout(isSmallScreen),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMobileLayout(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Insight Card - Farm Overview (with RepaintBoundary)
        RepaintBoundary(
          child: Selector<DashboardProvider, ({List<Map<String, String>> fields, Map<String, SensorDataModel?> sensors, Map<String, AIRecommendation> aiRecs, double dailyWater})>(
            selector: (_, provider) => (
              fields: provider.fields,
              sensors: provider.latestSensorDataPerField,
              aiRecs: provider.aiRecommendations,
              dailyWater: provider.dailyWaterUsage,
            ),
            builder: (_, data, __) => _buildUserInsightCard(
              data.fields, 
              data.sensors, 
              data.aiRecs, 
              data.dailyWater,
              _dashboardView,
              (val) => setState(() => _dashboardView = val ?? 'Both'),
              isSmallScreen,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Sensor Offline Error Banner
        Selector<DashboardProvider, String?>(
          selector: (_, provider) => provider.sensorOfflineError,
          builder: (_, error, __) {
            if (_dashboardView == 'USB Sensor') return const SizedBox.shrink();
            return _buildSensorOfflineBanner(error);
          },
        ),
        
        RepaintBoundary(
          child: Selector<DashboardProvider, ({Map<String, dynamic>? usbData, AIRecommendation? usbAi})>(
            selector: (_, provider) {
              // Get first sensor's data for backward compatibility
              final firstSensor = provider.usbSensorsData.values.isNotEmpty 
                  ? provider.usbSensorsData.values.first 
                  : null;
              final firstAi = provider.usbAiRecommendations.values.isNotEmpty
                  ? provider.usbAiRecommendations.values.first
                  : null;
              return (usbData: firstSensor, usbAi: firstAi);
            },
            builder: (_, data, __) => (_dashboardView == 'USB Sensor' || _dashboardView == 'Both') 
                    ? _buildUsbSensorCard(data.usbData, data.usbAi)
                    : const SizedBox.shrink(),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Quick Actions (const title)
        const _SectionTitle(titleKey: 'quickActions'),
        const SizedBox(height: 12),
        _buildQuickActions(),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Weather + compact soil gauge (with RepaintBoundary)
        RepaintBoundary(
          child: Selector<DashboardProvider, ({double? avgMoisture, double dailyWater})>(
            selector: (_, provider) => (avgMoisture: provider.avgSoilMoisture, dailyWater: provider.dailyWaterUsage),
            builder: (_, data, __) => _buildFullWidthSoilCard(data.avgMoisture, data.dailyWater),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        RepaintBoundary(
          child: Selector<DashboardProvider, ({WeatherData? weather, List<Map<String, dynamic>> forecast})>(
            selector: (_, provider) => (weather: provider.weatherData, forecast: provider.forecast5Day),
            builder: (_, data, __) => _buildWeatherCard(data.weather, data.forecast),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Next Schedule Cycle (const title)
        const _SectionTitle(titleKey: 'nextScheduleCycle'),
        const SizedBox(height: 12),
        Selector<DashboardProvider, List<IrrigationScheduleModel>>(
          selector: (_, provider) => provider.upcomingSchedules,
          builder: (_, schedules, __) => _buildNextScheduleCard(schedules),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),

        // Weekly Performance (const title)
        const _SectionTitle(titleKey: 'weeklyPerformance'),
        const SizedBox(height: 12),
        RepaintBoundary(
          child: Selector<DashboardProvider, ({double weekly, double daily, double savings})>(
            selector: (_, provider) => (weekly: provider.weeklyWaterUsage, daily: provider.dailyWaterUsage, savings: provider.weeklySavings),
            builder: (_, data, __) => _buildWeeklyPerformance(data.weekly, data.daily, data.savings),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeScreenLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  RepaintBoundary(
                    child: Selector<DashboardProvider, ({List<Map<String, String>> fields, Map<String, SensorDataModel?> sensors, Map<String, AIRecommendation> aiRecs, double dailyWater})>(
                      selector: (_, provider) => (
                        fields: provider.fields,
                        sensors: provider.latestSensorDataPerField,
                        aiRecs: provider.aiRecommendations,
                        dailyWater: provider.dailyWaterUsage,
                      ),
                      builder: (_, data, __) => _buildUserInsightCard(
                        data.fields, 
                        data.sensors, 
                        data.aiRecs, 
                        data.dailyWater,
                         _dashboardView,
                        (val) => setState(() => _dashboardView = val ?? 'Both'),
                        false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Selector<DashboardProvider, String?>(
                    selector: (_, provider) => provider.sensorOfflineError,
                    builder: (_, error, __) {
                      if (_dashboardView == 'USB Sensor') return const SizedBox.shrink();
                      return _buildSensorOfflineBanner(error);
                    },
                  ),
                  
                  // USB Sensor Card
                  RepaintBoundary(
                    child: Selector<DashboardProvider, ({Map<String, dynamic>? usbData, AIRecommendation? usbAi})>(
                      selector: (_, provider) {
                        // Get first sensor's data for backward compatibility
                        final firstSensor = provider.usbSensorsData.values.isNotEmpty 
                            ? provider.usbSensorsData.values.first 
                            : null;
                        final firstAi = provider.usbAiRecommendations.values.isNotEmpty
                            ? provider.usbAiRecommendations.values.first
                            : null;
                        return (usbData: firstSensor, usbAi: firstAi);
                      },
                      builder: (_, data, __) => (_dashboardView == 'USB Sensor' || _dashboardView == 'Both')
                          ? _buildUsbSensorCard(data.usbData, data.usbAi)
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const _SectionTitle(titleKey: 'quickActions'),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Selector<DashboardProvider, ({double? avgMoisture, double dailyWater, WeatherData? weather, List<Map<String, dynamic>> forecast})>(
                    selector: (_, provider) => (
                      avgMoisture: provider.avgSoilMoisture,
                      dailyWater: provider.dailyWaterUsage,
                      weather: provider.weatherData,
                      forecast: provider.forecast5Day,
                    ),
                    builder: (_, data, __) => _buildWeatherAndGauge(data.avgMoisture, data.dailyWater, data.weather, data.forecast, true),
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle(titleKey: 'nextScheduleCycle'),
                  const SizedBox(height: 12),
                  Selector<DashboardProvider, List<IrrigationScheduleModel>>(
                    selector: (_, provider) => provider.upcomingSchedules,
                    builder: (_, schedules, __) => _buildNextScheduleCard(schedules),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionTitle(titleKey: 'weeklyPerformance'),
        const SizedBox(height: 12),
        RepaintBoundary(
          child: Selector<DashboardProvider, ({double weekly, double daily, double savings})>(
            selector: (_, provider) => (weekly: provider.weeklyWaterUsage, daily: provider.dailyWaterUsage, savings: provider.weeklySavings),
            builder: (_, data, __) => _buildWeeklyPerformance(data.weekly, data.daily, data.savings),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorOfflineBanner(String? sensorOfflineError) {
    if (sensorOfflineError == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.sensors_off, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.sensorNotLoggingData,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sensorOfflineError ?? context.l10n.sensorDataNotAvailable,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherAndGauge(double? avgMoisture, double dailyWater, WeatherData? weatherData, List<Map<String, dynamic>> forecast5Day, bool isWideScreen) {
    final avg = avgMoisture;
    final daily = dailyWater;

    // Soil Moisture Card
    Widget moistureCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: avg != null ? (avg / 100).clamp(0.0, 1.0) : 0.0,
                  strokeWidth: 8,
                  backgroundColor: FamingaBrandColors.borderColor.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(FamingaBrandColors.primaryOrange),
                ),
                Text(
                  avg != null ? '${avg.round()}%' : '--',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.soilMoisture,
            style: const TextStyle(
              color: FamingaBrandColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    // Water Usage Card
    Widget waterCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop,
            size: 40,
            color: FamingaBrandColors.primaryOrange,
          ),
          const SizedBox(height: 12),
          Text(
            daily > 0 ? '${daily.toStringAsFixed(1)} L' : '--',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : FamingaBrandColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Water Usage',
            style: const TextStyle(
              color: FamingaBrandColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (isWideScreen) {
      // Large screen: Show moisture and water side by side, then weather below
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: moistureCard),
              const SizedBox(width: 16),
              Expanded(child: waterCard),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeatherCard(weatherData, forecast5Day),
        ],
      );
    } else {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: moistureCard),
                  const SizedBox(width: 16),
                  Expanded(child: waterCard),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeatherCard(weatherData, forecast5Day),
            ],
          );
        }
        // Mobile: Use the full width card
        return Column(
          children: [
            _buildFullWidthSoilCard(avg, daily),
            const SizedBox(height: 16),
            _buildWeatherCard(weatherData, forecast5Day),
          ],
        );
      });
    }
  }

  Widget _buildFullWidthSoilCard(double? avgMoisture, double dailyWater) {
    final avg = avgMoisture;
    final daily = dailyWater;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: avg != null ? (avg / 100).clamp(0.0, 1.0) : 0.0,
                      strokeWidth: 10,
                      backgroundColor: FamingaBrandColors.borderColor.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(FamingaBrandColors.primaryOrange),
                    ),
                    Text(
                      avg != null ? '${avg.round()}%' : '--',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : FamingaBrandColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.soilMoisture,
                style: const TextStyle(color: FamingaBrandColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Usage',
                style: TextStyle(
                  color: FamingaBrandColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                daily > 0 ? '${daily.toStringAsFixed(1)} L' : '--',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : FamingaBrandColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Status: ${avg != null && avg < 40 ? "Dry" : (avg != null && avg > 80 ? "Wet" : "Optimal")}',
                  style: const TextStyle(
                    color: FamingaBrandColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Color _getRecColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'irrigate':
        return Colors.green;
      case 'hold':
        return Colors.amber;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUserInsightCard(
    List<Map<String, String>> fields, 
    Map<String, SensorDataModel?> sensors, 
    Map<String, AIRecommendation> aiRecs, 
    double dailyWater,
    String selectedView,
    ValueChanged<String?> onViewChanged,
    bool isSmallScreen,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final name = user?.firstName ?? user?.email?.split('@').first ?? 'Farmer';
    
    // View options
    final viewOptions = {
      'Cloud Data': context.l10n.cloudData,
      'USB Sensor': context.l10n.usbSoilSensor, 
      'Both': context.l10n.bothView,
    };

    // Build field status items
    final fieldItems = fields.map((field) {
      final fieldId = field['id']!;
      final sensor = sensors[fieldId];
      final aiRec = aiRecs[fieldId];
      return _FieldStatusItem(
        field: field,
        sensor: sensor,
        aiRec: aiRec,
      );
    }).toList();
    
    // Check for issues for overall status
    bool hasAnyIssues = false;
    for (final field in fields) {
      final fieldId = field['id']!;
      final sensor = sensors[fieldId];
      bool isHealthy = sensor != null && sensor.soilMoisture != null;
      bool hasDrainage = sensor?.soilMoisture != null && sensor!.soilMoisture >= 100;
      if (!isHealthy || hasDrainage) {
        hasAnyIssues = true;
        break;
      }
    }

    // Get AI recommendation for display - prioritize AI advice
    // Get AI recommendation for display - prioritize AI advice
    String waterText = dailyWater > 0 ? '${dailyWater.toStringAsFixed(0)} ${context.l10n.litersSuffix}' : context.l10n.noData;
    
    // Always show AI advice if available
    String overallAdvice = '';
    for (final field in fields) {
      final fieldId = field['id']!;
      final aiRec = aiRecs[fieldId];
      
      if (aiRec != null) {
        final cropType = field['crop'] ?? 'crops';
        
        // Build advice from AI data
        if (aiRec.reasoning.isNotEmpty) {
          // Use AI's reasoning if available
          overallAdvice = '${cropType.toUpperCase()}: ${aiRec.reasoning}';
        } else {
          // Fallback to recommendation if no reasoning
          overallAdvice = '${cropType.toUpperCase()}: ${aiRec.recommendation}';
        }
        break; // Use first field with AI recommendation
      }
    }
    
    // Only use generic fallback if absolutely no AI data
    if (overallAdvice.isEmpty) {
      overallAdvice = hasAnyIssues 
          ? context.l10n.checkSensorsAndFields
          : context.l10n.continueMonitoring;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamingaBrandColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Dropdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  context.l10n.userInsightGreeting(name),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // View Selection Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FamingaBrandColors.borderColor),
                ),
                child: DropdownButton<String>(
                  value: selectedView,
                  isDense: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.tune, size: 18),
                  items: viewOptions.entries.map((e) => DropdownMenuItem(
                    value: e.key, 
                    child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                  )).toList(),
                  onChanged: onViewChanged,
                ),
              ),
            ],
          ),
          
          // Conditions to show Cloud Data
          if (selectedView == 'Cloud Data' || selectedView == 'Both') ...[
            const SizedBox(height: 16),
            
            // Section title
            Text(
              context.l10n.todaysFarmStatus,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : FamingaBrandColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: FamingaBrandColors.borderColor),
            const SizedBox(height: 16),
            
            // Field items
            if (fieldItems.isNotEmpty) ...fieldItems,
            if (fieldItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  context.l10n.noFieldsConfiguredAction,
                  style: const TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            
            // Divider
            Divider(color: FamingaBrandColors.borderColor),
            const SizedBox(height: 12),
            
            // Water usage
            Row(
              children: [
                Text(
                  '${context.l10n.waterUsage}:',
                  style: TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  waterText,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            
            // Overall advice
            Row(
              children: [
                Text(
                  '${context.l10n.advice}:',
                  style: TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    overallAdvice,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : FamingaBrandColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ], // End Cloud Data block
        ],
      ),
    );
  }

  Widget _buildAiRecommendationDetail(DashboardProvider dashboardProvider) {
    final selectedFieldId = dashboardProvider.selectedFarmId;
    final aiRec = dashboardProvider.aiRecommendations[selectedFieldId];
    if (aiRec == null) {
      return const SizedBox.shrink();
    }

    final fieldMeta = dashboardProvider.fields.firstWhere(
      (f) => f['id'] == selectedFieldId,
      orElse: () => {'id': selectedFieldId, 'name': selectedFieldId, 'crop': 'unknown'},
    );

    final cropName = fieldMeta['crop']?.isNotEmpty == true ? fieldMeta['crop']! : 'unknown';
    final decision = (aiRec.metadata?['decision'] ?? aiRec.recommendation).toString();
    final reasoning = aiRec.reasoning.isNotEmpty
        ? aiRec.reasoning
        : 'AI did not include additional reasoning for this field.';
    final color = _getRecColor(decision);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI advice for ${cropName != 'unknown' ? cropName : (fieldMeta['name'] ?? selectedFieldId)}',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Decision: ${decision.toUpperCase()}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommendation: ${aiRec.recommendation}',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : FamingaBrandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: $reasoning',
            style: TextStyle(
              color: FamingaBrandColors.textSecondary.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${(aiRec.confidence * 100).toStringAsFixed(0)}% • Crop: ${cropName.toUpperCase()}',
            style: const TextStyle(
              color: FamingaBrandColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToManualStartButton() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _manualStartButtonKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        
        setState(() {
          _isManualStartHighlighted = true;
        });
        
        _highlightTimer?.cancel();
        _highlightTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isManualStartHighlighted = false;
            });
          }
        });
      }
    });
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            Icons.play_circle_outline,
            context.l10n.manualStart,
            FamingaBrandColors.primaryOrange,
            _scrollToManualStartButton,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            Icons.info_outline,
            context.l10n.farmInfo,
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
            context.l10n.scheduled,
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
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : FamingaBrandColors.textPrimary,
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
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.water_drop,
                color: FamingaBrandColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.soilMoisture,
                style: const TextStyle(
                  color: FamingaBrandColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: avg != null ? moisturePercent : 0.0,
                  strokeWidth: 8,
                  backgroundColor: FamingaBrandColors.borderColor.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    FamingaBrandColors.primaryOrange,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    moistureText,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : FamingaBrandColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.averageToday,
            style: const TextStyle(
              color: FamingaBrandColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData? weatherData, List<Map<String, dynamic>> forecast5Day) {
    final forecast = forecast5Day;
    
    if (forecast.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: FamingaBrandColors.primaryOrange,
                strokeWidth: 2,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.loading,
                style: const TextStyle(
                  color: FamingaBrandColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    final forecastDays = forecast.map((f) => ForecastDay.fromMap(f)).toList();
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isWeatherCardExpanded = true),
      onExit: (_) => setState(() => _isWeatherCardExpanded = false),
      child: GestureDetector(
        onTap: () => setState(() => _isWeatherCardExpanded = !_isWeatherCardExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny,
                        color: FamingaBrandColors.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.weatherForecast,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : FamingaBrandColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (forecastDays.length > 1)
                    AnimatedRotation(
                      turns: _isWeatherCardExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: FamingaBrandColors.textSecondary,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (forecastDays.isNotEmpty) _buildTodayForecastHighlight(forecastDays.first),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isWeatherCardExpanded && forecastDays.length > 1
                    ? Column(
                        children: [
                          const SizedBox(height: 12),
                          const Divider(
                            color: FamingaBrandColors.borderColor,
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          ...forecastDays.skip(1).take(4).map((day) => _buildForecastDayRow(day)),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayForecastHighlight(ForecastDay today) {
    final weatherIcon = _getWeatherIconForStatus(today.status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FamingaBrandColors.primaryOrange.withOpacity(0.1),
            FamingaBrandColors.primaryOrange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            weatherIcon,
            color: FamingaBrandColors.primaryOrange,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedDayLabel(today.date),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizedWeatherStatus(today.status),
                  style: const TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.thermostat,
                      size: 16,
                      color: FamingaBrandColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${today.tempMaxString} / ${today.tempMinString}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : FamingaBrandColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.water_drop_outlined,
                      size: 14,
                      color: FamingaBrandColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      today.humidityString,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : FamingaBrandColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }

  String _localizedDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return context.l10n.today;
    if (d == tomorrow) return context.l10n.tomorrow;

    // Prefer explicit weekday translations from generated l10n (monday..sunday).
    try {
      final l10n = context.l10n;
      switch (date.weekday) {
        case DateTime.monday:
          return l10n.monday;
        case DateTime.tuesday:
          return l10n.tuesday;
        case DateTime.wednesday:
          return l10n.wednesday;
        case DateTime.thursday:
          return l10n.thursday;
        case DateTime.friday:
          return l10n.friday;
        case DateTime.saturday:
          return l10n.saturday;
        case DateTime.sunday:
          return l10n.sunday;
      }
    } catch (_) {
      // ignore and fallback below
    }

    // Fallback to a locale-aware short weekday (e.g. Mon) then to model's English dayName.
    try {
      final locale = Localizations.localeOf(context).toString();
      return DateFormat.E(locale).format(date);
    } catch (_) {
      return ForecastDay(date: date, tempMin: 0, tempMax: 0, windSpeed: 0, rainMm: 0, pop: 0, status: 'Clear').dayName;
    }
  }

  String _localizedWeatherStatus(String status) {
    switch (status.toLowerCase()) {
      case 'clear':
        return context.l10n.weatherClear;
      case 'clouds':
        return context.l10n.weatherClouds;
      case 'rain':
        return context.l10n.weatherRain;
      case 'thunderstorm':
        return context.l10n.weatherThunderstorm;
      case 'snow':
        return context.l10n.weatherSnow;
      default:
        return status;
    }
  }
  
  Widget _buildForecastDayRow(ForecastDay day) {
    IconData weatherIcon;
    switch (day.status.toLowerCase()) {
      case 'clear':
        weatherIcon = Icons.wb_sunny;
        break;
      case 'clouds':
        weatherIcon = Icons.cloud;
        break;
      case 'rain':
        weatherIcon = Icons.water_drop;
        break;
      case 'thunderstorm':
        weatherIcon = Icons.thunderstorm;
        break;
      case 'snow':
        weatherIcon = Icons.ac_unit;
        break;
      default:
        weatherIcon = Icons.wb_cloudy;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: FamingaBrandColors.borderColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              _localizedDayLabel(day.date),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : FamingaBrandColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            weatherIcon,
            color: FamingaBrandColors.primaryOrange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thermostat, size: 14, color: FamingaBrandColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${day.tempMaxString}/${day.tempMinString}',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : FamingaBrandColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.water_drop_outlined, size: 13, color: FamingaBrandColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          day.humidityString,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : FamingaBrandColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.umbrella, size: 13, color: FamingaBrandColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          day.popPercentage,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : FamingaBrandColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.air, size: 12, color: FamingaBrandColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          day.windSpeedString,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : FamingaBrandColors.textPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    if (day.rainMm > 0)
                      Row(
                        children: [
                          const Icon(Icons.water, size: 12, color: FamingaBrandColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            day.rainAmountString,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : FamingaBrandColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
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

  Widget _buildCompactLanguageSelector() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    final languages = [
      {'code': 'English', 'flag': '🇬🇧'},
      {'code': 'Kinyarwanda', 'flag': '🇷🇼'},
      {'code': 'French', 'flag': '🇫🇷'},
      {'code': 'Swahili', 'flag': '🇹🇿'},
    ];

    final currentLang = languages.firstWhere(
      (lang) => lang['code'] == languageProvider.currentLanguageName,
      orElse: () => languages[0],
    );

    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: FamingaBrandColors.primaryOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FamingaBrandColors.primaryOrange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLang['flag']!,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: FamingaBrandColors.primaryOrange,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => languages.map((lang) {
        return PopupMenuItem<String>(
          value: lang['code'],
          child: Row(
            children: [
              Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Text(
                lang['code']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (value) {
        languageProvider.setLanguage(value);
      },
    );
  }

  Widget _buildLanguageSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    final languages = [
      {'code': 'English', 'flag': '🇬🇧', 'name': 'English'},
      {'code': 'Kinyarwanda', 'flag': '🇷🇼', 'name': 'Kinyarwanda'},
      {'code': 'French', 'flag': '🇫🇷', 'name': 'Français'},
      {'code': 'Swahili', 'flag': '🇹🇿', 'name': 'Kiswahili'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? scheme.outline.withOpacity(0.2) : FamingaBrandColors.primaryOrange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? scheme.primary : FamingaBrandColors.primaryOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.language,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: languageProvider.currentLanguageName,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark ? scheme.onSurface : FamingaBrandColors.textPrimary,
              ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? scheme.onSurface : FamingaBrandColors.textPrimary,
              ),
              dropdownColor: isDark ? scheme.surface : Colors.white,
              menuMaxHeight: 300,
              items: languages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Row(
                    children: [
                      Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? scheme.onSurface : FamingaBrandColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  languageProvider.setLanguage(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextScheduleCard(List<IrrigationScheduleModel> upcomingSchedules) {
    final upcoming = upcomingSchedules;
    final schedule = upcomingSchedules.isNotEmpty ? upcomingSchedules.first : null;
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
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : FamingaBrandColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.duration,
                      style: const TextStyle(
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
            Column(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 48,
                  color: FamingaBrandColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.noScheduledIrrigations,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.startIrrigationManually,
                  style: const TextStyle(
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
                      context.l10n.upcomingIrrigations,
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
                          final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                          final ok = await dashboardProvider.startScheduledCycleNow(sched.id, uid);
                          if (!ok) {
                            Get.snackbar(context.l10n.error, context.l10n.failedStartIrrigation);
                          }
                        },
                        child: Text(context.l10n.startNowButton),
                      ),
                      const SizedBox(width: 8),
                          if (sched.status == 'running')
                      OutlinedButton(
                        onPressed: () async {
                          final uid = authProvider.currentUser!.userId;
                          final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                          final ok = await dashboardProvider.stopCycle(sched.id, uid);
                          if (!ok) {
                            Get.snackbar(context.l10n.error, context.l10n.failedStopIrrigation);
                          }
                        },
                        child: Text(context.l10n.stopButton),
                            ),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          const SizedBox(height: 16),
          AnimatedContainer(
            key: _manualStartButtonKey,
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: _isManualStartHighlighted
                  ? [
                      BoxShadow(
                        color: FamingaBrandColors.primaryOrange.withOpacity(0.7),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                  // Check if fields exist before opening manual irrigation
                  if (dashboardProvider.fields.isEmpty) {
                    _showNoFieldsModal(context, authProvider.currentUser!.userId);
                  } else {
                    _showManualStartDialog(dashboardProvider, authProvider);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isManualStartHighlighted 
                      ? FamingaBrandColors.primaryOrange 
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primaryContainer
                          : FamingaBrandColors.darkGreen),
                  foregroundColor: _isManualStartHighlighted
                      ? Colors.white
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Icon(
                Icons.play_arrow,
                color: FamingaBrandColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.startCycleManually,
                  style: const TextStyle(
                  color: FamingaBrandColors.white,
                  fontWeight: FontWeight.bold,
                fontSize: 13,
                ),
                ),
                ],
                ),
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
        title: Text(context.l10n.startIrrigationManually),
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
                  decoration: InputDecoration(labelText: context.l10n.field),
            ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(labelText: context.l10n.durationMinutes),
                  keyboardType: TextInputType.number,
              ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.l10n.cancelButton),
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
                  context.l10n.success,
                  context.l10n.irrigationStartedSuccessfully,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusSuccess,
                  colorText: FamingaBrandColors.white,
                );
              } else {
                Get.snackbar(
                  context.l10n.error,
                  context.l10n.failedStartIrrigation,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: FamingaBrandColors.statusWarning,
                  colorText: FamingaBrandColors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primaryContainer
                  : FamingaBrandColors.darkGreen,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.white,
            ),
            child: Text(context.l10n.startNowButton),
          ),
        ],
      ),
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
              
              Text(
              context.l10n.noFieldsTitle,
              style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              ),
              const SizedBox(height: 12),
              
              Text(
              context.l10n.noFieldsMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
              height: 1.4,
              ),
              ),
              const SizedBox(height: 28),
              
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
                      context.l10n.cancelButton,
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
                      label: Text(context.l10n.goToFields),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FamingaBrandColors.primaryOrange,
                        foregroundColor: FamingaBrandColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPerformance(double weeklyWaterUsage, double dailyWaterUsage, double weeklySavings) {
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
                Row(
                children: [
                const Icon(
                Icons.water_drop,
                color: FamingaBrandColors.primaryOrange,
                size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                context.l10n.waterUsage,
                style: const TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 12,
                ),
                ),
                ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${weeklyWaterUsage.round()}',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                context.l10n.litersThisWeek,
                style: const TextStyle(
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
                Row(
                  children: [
                    Icon(
                      Icons.savings,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : FamingaBrandColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                    context.l10n.kshSaved,
                    style: const TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 12,
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  weeklySavings.round().toStringAsFixed(0),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                context.l10n.thisWeek,
                style: const TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 11,
                ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : FamingaBrandColors.primaryOrange)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.trending_up,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : FamingaBrandColors.primaryOrange,
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
      items: [
      BottomNavigationBarItem(
      icon: const Icon(Icons.dashboard),
      label: context.l10n.dashboard,
      ),
      BottomNavigationBarItem(
      icon: const Icon(Icons.water_drop),
      label: context.l10n.irrigation,
      ),
      BottomNavigationBarItem(
      icon: const Icon(Icons.landscape),
      label: context.l10n.fields,
      ),
      BottomNavigationBarItem(
      icon: const Icon(Icons.sensors),
      label: context.l10n.sensors,
      ),
      BottomNavigationBarItem(
      icon: const Icon(Icons.person),
      label: context.l10n.profile,
      ),
      ],
    );
  }

  Widget _buildUsbSensorCard(Map<String, dynamic>? usbSensorData, AIRecommendation? usbAiRecommendation) {
    final usbData = usbSensorData;
    final aiRec = usbAiRecommendation;
    
    // Always show if data exists (provider handles offline flag)
    if (usbData == null) {
      return const SizedBox.shrink();
    }

    final moisture = (usbData['moisture'] as num?)?.toDouble() ?? 0.0;
    final temperature = (usbData['temperature'] as num?)?.toDouble() ?? 0.0;
    final moistureStatus = usbData['moisture_status'] as String? ?? 'Unknown';
    final tempStatus = usbData['temp_status'] as String? ?? 'Unknown';
    final timestamp = usbData['timestamp'] as Timestamp?;
    
    // Use provider's offline status if available, fallback to local check (60 secs)
    bool isOffline = usbData['isOffline'] == true;
    final minutesSince = usbData['minutesSinceUpdate'] as int?;
    
    if (!usbData.containsKey('isOffline') && timestamp != null) {
       isOffline = DateTime.now().difference(timestamp.toDate()).inSeconds > 60;
    }

    // Determine visual state
    final statusColor = isOffline ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamingaBrandColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.usb,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.usbSoilSensor,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : FamingaBrandColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        isOffline 
                            ? '${context.l10n.lastUpdate}: ${minutesSince != null ? context.l10n.minutesAgo(minutesSince) : DateFormat('HH:mm').format(timestamp.toDate())}'
                            : '${context.l10n.lastUpdate}: ${DateFormat('HH:mm:ss').format(timestamp.toDate())}',
                        style: TextStyle(
                          color: FamingaBrandColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (isOffline) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.sensorDisconnectedCheckUsb,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Sensor Readings
          Row(
            children: [
              Expanded(
                child: _buildUsbMetricCard(
                  'Moisture',
                  moisture.toStringAsFixed(0),
                  '%',
                  Icons.water_drop,
                  Colors.blue,
                  moistureStatus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUsbMetricCard(
                  'Temperature',
                  temperature.toStringAsFixed(0),
                  '°C',
                  Icons.thermostat,
                  Colors.orange,
                  tempStatus,
                ),
              ),
            ],
          ),
          
          // AI Recommendation
          if (aiRec != null) ...[
            const SizedBox(height: 16),
            const Divider(color: FamingaBrandColors.borderColor),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: FamingaBrandColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.aiRecommendation,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${aiRec.recommendation}',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : FamingaBrandColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              aiRec.reasoning,
              style: TextStyle(
                color: FamingaBrandColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsbMetricCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: FamingaBrandColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : FamingaBrandColors.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: FamingaBrandColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: FamingaBrandColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Per-field summary removed from dashboard; keep per-field view in Fields/Sensors pages.
}

class AlertCenterBottomSheet extends StatelessWidget {
  final List<AlertModel> alerts;
  final Future<void> Function(String id) onMarkRead;
  const AlertCenterBottomSheet({required this.alerts, required this.onMarkRead});
  
  void _showAlertDetails(BuildContext context, AlertModel alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconForType(alert.type),
              color: _getColorForSeverity(alert.severity, context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alert.type.toUpperCase(),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alert.message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Severity', alert.severity.toUpperCase()),
              _buildDetailRow('Time', DateFormat('MMM dd, yyyy hh:mm a').format(alert.ts)),
              _buildDetailRow('Status', alert.read ? 'Read' : 'Unread'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!alert.read)
            ElevatedButton.icon(
              onPressed: () {
                onMarkRead(alert.id);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Mark as Read'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FamingaBrandColors.darkGreen,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: FamingaBrandColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: FamingaBrandColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForSeverity(String severity, BuildContext context) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : FamingaBrandColors.primaryOrange;
    }
  }

  IconData _getIconForType(String type) {
    if (type.contains('irrigation') || type.contains('VALVE')) {
      return Icons.water_drop;
    } else if (type.contains('sensor') || type.contains('OFFLINE')) {
      return Icons.sensors;
    } else if (type.contains('water')) {
      return Icons.water;
    } else {
      return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.6;
    if (alerts.isEmpty) {
    return SizedBox(
    height: maxHeight,
    child: Padding(
    padding: const EdgeInsets.all(32),
    child: Center(child: Text(context.l10n.noAlertsYet)),),
    );
    }
    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final a = alerts[i];
            Color iconColor = _getColorForSeverity(a.severity, context);
            IconData icon = _getIconForType(a.type);
            
            return Dismissible(
              key: Key(a.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Alert'),
                    content: const Text('Are you sure you want to delete this alert?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                await AlertLocalService.removeAlert(a.id);
              },
              child: ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(a.message,
                    style: TextStyle(fontWeight: a.read ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text('${a.type} • ${a.severity} • ${timeAgo(a.ts, context)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!a.read)
                      IconButton(
                        icon: Icon(
                          Icons.check,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : FamingaBrandColors.primaryOrange,
                        ),
                        tooltip: context.l10n.markAsRead,
                        onPressed: () => onMarkRead(a.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Alert'),
                            content: const Text('Are you sure you want to delete this alert?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await AlertLocalService.removeAlert(a.id);
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => _showAlertDetails(context, a),
              ),
            );
          },
        ),
      ),
    );
  }

  String timeAgo(DateTime dt, BuildContext context) {
  final d = DateTime.now().difference(dt);
  if (d.inMinutes < 1) return context.l10n.justNow;
  if (d.inHours < 1) return context.l10n.minutesAgo(d.inMinutes);
  if (d.inDays < 1) return context.l10n.hoursAgo(d.inHours);
  return context.l10n.daysAgo(d.inDays);
  }
}

class _FieldStatusItem extends StatelessWidget {
  final Map<String, dynamic> field;
  final SensorDataModel? sensor;
  final AIRecommendation? aiRec;

  const _FieldStatusItem({
    Key? key,
    required this.field,
    this.sensor,
    this.aiRec,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fieldName = field['name']!;
    
    bool isHealthy = sensor != null && sensor!.soilMoisture != null;
    bool hasDrainage = sensor?.soilMoisture != null && sensor!.soilMoisture >= 100;
    
    // Status icon and color
    IconData statusIcon = isHealthy ? Icons.check_circle : Icons.warning_amber_rounded;
    Color statusColor = isHealthy ? Colors.green : Colors.orange;
    String statusText = isHealthy ? context.l10n.isHealthy : context.l10n.needsAttention;
    
    // Build status description
    String description = '';
    String action = '';
    
    if (sensor == null) {
      description = 'Sensor is not responding';
      action = 'Please check the sensor connection';
    } else if (hasDrainage) {
      description = 'Soil is waterlogged';
      action = 'Stop watering and check drainage';
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Colors.red;
      statusText = context.l10n.needsUrgentAttention;
    } else {
      // Build natural language description
      final moisture = sensor!.soilMoisture?.round() ?? 0;
      final temp = sensor!.temperature?.round() ?? 0;
      
      String moistureDesc = moisture < 40 ? 'dry' : (moisture > 80 ? 'very wet' : 'moist');
      String tempDesc = temp < 20 ? 'cool' : (temp > 30 ? 'hot' : 'good');
      
      description = 'Soil is $moistureDesc, temperature is $tempDesc';
      
      // Get detailed action from AI or default
      if (aiRec != null) {
        final cropType = field['crop'] ?? 'crops';
        final decision = aiRec!.recommendation.toUpperCase();
        
        // Build detailed recommendation
        String actionVerb = '';
        if (decision.contains('IRRIGATE') || decision.contains('WATER')) {
          actionVerb = 'Water your $cropType now';
        } else if (decision.contains('HOLD') || decision.contains('WAIT')) {
          actionVerb = 'Hold off watering';
        } else {
          actionVerb = 'Monitor your $cropType';
        }
        
        // Add reasoning if available
        String reasoning = aiRec!.reasoning.isNotEmpty 
            ? aiRec!.reasoning 
            : 'Based on current soil moisture levels';
        
        action = '$actionVerb. $reasoning';
      } else {
        action = moisture < 40 ? 'Consider watering soon' : 'Keep watering as usual';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$fieldName $statusText',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : FamingaBrandColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    color: FamingaBrandColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.9)
                        : FamingaBrandColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for section titles (const for performance)
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.titleKey});
  
  final String titleKey;
  
  @override
  Widget build(BuildContext context) {
    String title;
    switch (titleKey) {
      case 'quickActions':
        title = context.l10n.quickActions;
        break;
      case 'nextScheduleCycle':
        title = context.l10n.nextScheduleCycle;
        break;
      case 'weeklyPerformance':
        title = context.l10n.weeklyPerformance;
        break;
      default:
        title = titleKey;
    }
    
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : FamingaBrandColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
